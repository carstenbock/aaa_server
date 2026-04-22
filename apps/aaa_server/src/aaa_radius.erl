%%%-------------------------------------------------------------------
%%% @doc Optional RADIUS frontend for Hotspot 2.0 / Passpoint WLAN
%%% controllers that cannot speak Diameter STa directly.
%%%
%%% Implements a minimal RFC 2865 / RFC 3579 RADIUS server that
%%% funnels EAP-Message attributes into the same aaa_eap_relay engine
%%% as the Diameter STa path and returns:
%%%   * MS-MPPE-Recv-Key (RFC 2548, VSA vendor=311, type=17)
%%%   * MS-MPPE-Send-Key (RFC 2548, VSA vendor=311, type=16)
%%% on success, encrypted with the shared secret per RFC 2548 §2.4.2.
%%% These are installed by the WLAN AP as the PMK for the 802.11i
%%% 4-way handshake.
%%%
%%% This module is started only when AAA_RADIUS_ENABLED=true.
%%%
%%% Supported attributes:
%%%   User-Name           (1)   UTF8 NAI
%%%   NAS-IP-Address      (4)
%%%   Service-Type        (6)
%%%   Framed-MTU          (12)
%%%   State               (24)  opaque session correlation cookie
%%%   Called-Station-Id   (30)  MAC/SSID of AP
%%%   Calling-Station-Id  (31)  UE MAC
%%%   NAS-Identifier      (32)
%%%   EAP-Message         (79)  RFC 3579 §3.1 — concatenated if split
%%%   Message-Authenticator (80) HMAC-MD5 over the packet (RFC 3579 §3.2)
%%%
%%% Responses:
%%%   Access-Challenge    (11) — with EAP-Message + Message-Authenticator
%%%   Access-Accept       (2)  — with EAP-Message(EAP-Success) + MS-MPPE
%%%   Access-Reject       (3)
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_radius).

-behaviour(gen_server).

-include("aaa_session.hrl").

-export([start_link/0, stop/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%% RADIUS packet codes
-define(RAD_ACCESS_REQUEST,   1).
-define(RAD_ACCESS_ACCEPT,    2).
-define(RAD_ACCESS_REJECT,    3).
-define(RAD_ACCESS_CHALLENGE, 11).

%% Attribute types
-define(ATTR_USER_NAME,            1).
-define(ATTR_USER_PASSWORD,        2).
-define(ATTR_NAS_IP_ADDRESS,       4).
-define(ATTR_NAS_PORT,             5).
-define(ATTR_FRAMED_MTU,          12).
-define(ATTR_STATE,               24).
-define(ATTR_VENDOR_SPECIFIC,     26).
-define(ATTR_CALLED_STATION_ID,   30).
-define(ATTR_CALLING_STATION_ID,  31).
-define(ATTR_NAS_IDENTIFIER,      32).
-define(ATTR_SESSION_TIMEOUT,     27).
-define(ATTR_EAP_MESSAGE,         79).
-define(ATTR_MESSAGE_AUTHENTICATOR, 80).
-define(ATTR_NAS_PORT_TYPE,       61).

-define(MS_VENDOR_ID, 311).
-define(MS_MPPE_SEND_KEY, 16).
-define(MS_MPPE_RECV_KEY, 17).

-record(state, {
    socket :: gen_udp:socket() | undefined,
    port   :: non_neg_integer(),
    secret :: binary(),
    %% State (24) → {SessionId, IMSI, last_eap_id}
    sessions = #{} :: #{binary() => {binary(), binary(), 0..255}}
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:stop(?SERVER).

%%====================================================================
%% gen_server
%%====================================================================

init([]) ->
    Port   = aaa_config:get(radius_port, 1812),
    Secret = to_bin(aaa_config:get(radius_secret, "change-me")),
    case gen_udp:open(Port, [binary, {active, true}, {reuseaddr, true}]) of
        {ok, Socket} ->
            logger:notice("RADIUS server listening on UDP/~B", [Port]),
            {ok, #state{socket = Socket, port = Port, secret = Secret}};
        {error, R} ->
            logger:error("RADIUS bind UDP/~B failed: ~p", [Port, R]),
            {ok, #state{port = Port, secret = Secret}}
    end.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_, State)           -> {noreply, State}.

handle_info({udp, _Sock, IP, SrcPort, Packet}, State) ->
    NewState = handle_packet(IP, SrcPort, Packet, State),
    {noreply, NewState};
handle_info(_, State) -> {noreply, State}.

terminate(_R, #state{socket = S}) when is_port(S) ->
    gen_udp:close(S), ok;
terminate(_, _) -> ok.

code_change(_, S, _) -> {ok, S}.

%%====================================================================
%% RADIUS packet handling
%%====================================================================

handle_packet(IP, Port, <<Code, Id, Len:16/big, Authenticator:16/binary,
                          _/binary>> = Packet, State)
  when byte_size(Packet) >= Len, Code =:= ?RAD_ACCESS_REQUEST ->
    aaa_metrics:inc(radius_access_request_total),
    <<Hdr:20/binary, AttrsBin:(Len - 20)/binary, _/binary>> = Packet,
    Attrs = decode_attrs(AttrsBin),
    case verify_message_authenticator(Packet, Attrs, State#state.secret) of
        true ->
            process_access_request(IP, Port, Id, Authenticator, Hdr,
                                   Attrs, State);
        false ->
            logger:warning("RADIUS Access-Request from ~p dropped: "
                           "bad Message-Authenticator", [IP]),
            aaa_metrics:inc(radius_bad_mac_total),
            State
    end;
handle_packet(_IP, _Port, _Packet, State) ->
    State.

process_access_request(IP, Port, Id, Authenticator, _Hdr, Attrs, State) ->
    EAPPayload = collect_eap(Attrs),
    StateCookie = get_attr(?ATTR_STATE, Attrs),
    UserName = get_attr(?ATTR_USER_NAME, Attrs),
    CalledId = get_attr(?ATTR_CALLED_STATION_ID, Attrs, <<>>),
    CallingId = get_attr(?ATTR_CALLING_STATION_ID, Attrs, <<>>),

    {SessionId, IMSI} = session_for(StateCookie, UserName, State),
    Session = ensure_session(SessionId, IMSI, CalledId, CallingId),

    case aaa_eap_relay:process(sta, EAPPayload, Session) of
        {challenge, Resp, Updates} ->
            aaa_session_mgr:update_session(SessionId, Updates),
            Cookie = new_cookie(SessionId),
            NewState = bind_cookie(Cookie, SessionId, IMSI, State),
            send_challenge(IP, Port, Id, Authenticator, Resp, Cookie, NewState);
        {success, Resp, MSK, Updates} ->
            aaa_session_mgr:update_session(SessionId, Updates),
            send_accept(IP, Port, Id, Authenticator, Resp, MSK, State);
        {failure, Resp, _} ->
            send_reject(IP, Port, Id, Authenticator, Resp, State);
        {error, _} ->
            send_reject(IP, Port, Id, Authenticator, <<>>, State)
    end.

session_for(undefined, UserName, _State) when is_binary(UserName) ->
    SessionId = <<"radius-", (generate_id())/binary>>,
    IMSI = case aaa_eap_relay:resolve_identity(UserName) of
        {ok, I} -> I;
        error   -> <<>>
    end,
    {SessionId, IMSI};
session_for(Cookie, _UserName, #state{sessions = M}) ->
    case maps:find(Cookie, M) of
        {ok, {Sid, IMSI, _}} -> {Sid, IMSI};
        error                -> session_for(undefined, <<>>, undefined)
    end.

ensure_session(SessionId, IMSI, _CalledId, _CallingId) ->
    case aaa_session_mgr:get_session(SessionId) of
        {ok, S} -> S;
        error   ->
            Rec = #aaa_session{
                session_id = SessionId,
                imsi = IMSI,
                interface = sta,
                an_trusted = 0,
                created_ts = 0, updated_ts = 0},
            ok = aaa_session_mgr:create_session(Rec),
            Rec
    end.

bind_cookie(Cookie, SessionId, IMSI, #state{sessions = M} = State) ->
    State#state{sessions = M#{Cookie => {SessionId, IMSI, 0}}}.

%%====================================================================
%% Response senders
%%====================================================================

send_challenge(IP, Port, Id, ReqAuth, EAP, Cookie,
               #state{socket = S, secret = Secret} = State) ->
    Attrs0 = eap_as_attrs(EAP) ++ [{?ATTR_STATE, Cookie}],
    Attrs = attrs_with_mac_placeholder(Attrs0),
    Pkt = build_packet(?RAD_ACCESS_CHALLENGE, Id, ReqAuth, Attrs, Secret),
    gen_udp:send(S, IP, Port, Pkt),
    aaa_metrics:inc(radius_access_challenge_total),
    State.

send_accept(IP, Port, Id, ReqAuth, EAP, MSK,
            #state{socket = S, secret = Secret} = State) ->
    <<RecvKey:32/binary, SendKey:32/binary, _/binary>> = pad_msk(MSK),
    MsVsa = [
        mppe_vsa(?MS_MPPE_RECV_KEY, encrypt_mppe_key(RecvKey, Secret, ReqAuth)),
        mppe_vsa(?MS_MPPE_SEND_KEY, encrypt_mppe_key(SendKey, Secret, ReqAuth))
    ],
    Attrs0 = eap_as_attrs(EAP)
        ++ MsVsa
        ++ [{?ATTR_SESSION_TIMEOUT, <<(session_timeout()):32/big>>}],
    Attrs = attrs_with_mac_placeholder(Attrs0),
    Pkt = build_packet(?RAD_ACCESS_ACCEPT, Id, ReqAuth, Attrs, Secret),
    gen_udp:send(S, IP, Port, Pkt),
    aaa_metrics:inc(radius_access_accept_total),
    State.

send_reject(IP, Port, Id, ReqAuth, EAP,
            #state{socket = S, secret = Secret} = State) ->
    Attrs0 = case EAP of
        <<>> -> [];
        _    -> eap_as_attrs(EAP)
    end,
    Attrs = attrs_with_mac_placeholder(Attrs0),
    Pkt = build_packet(?RAD_ACCESS_REJECT, Id, ReqAuth, Attrs, Secret),
    gen_udp:send(S, IP, Port, Pkt),
    aaa_metrics:inc(radius_access_reject_total),
    State.

%%====================================================================
%% Packet builders
%%====================================================================

build_packet(Code, Id, ReqAuth, Attrs, Secret) ->
    AttrBin = encode_attrs(Attrs),
    Len = 20 + byte_size(AttrBin),
    %% Compute Message-Authenticator first (placeholder zeros are in AttrBin).
    Hdr0 = <<Code, Id, Len:16/big, ReqAuth/binary>>,
    Raw0 = <<Hdr0/binary, AttrBin/binary>>,
    MAC = crypto:mac(hmac, md5, Secret, Raw0),
    Raw1 = patch_msg_auth(Raw0, MAC),
    %% Response-Authenticator = MD5(Code+Id+Len+RequestAuth+Attrs+Secret)
    <<_:20/binary, FinalAttrs/binary>> = Raw1,
    RespAuth = crypto:hash(md5,
        <<Code, Id, Len:16/big, ReqAuth/binary,
          FinalAttrs/binary, Secret/binary>>),
    <<Code, Id, Len:16/big, RespAuth/binary, FinalAttrs/binary>>.

attrs_with_mac_placeholder(Attrs) ->
    Attrs ++ [{?ATTR_MESSAGE_AUTHENTICATOR, <<0:128>>}].

patch_msg_auth(<<Hdr:20/binary, AttrsBin/binary>>, MAC) ->
    %% Find the placeholder and replace.
    NewAttrs = replace_mac_placeholder(AttrsBin, MAC, <<>>),
    <<Hdr/binary, NewAttrs/binary>>.

replace_mac_placeholder(<<?ATTR_MESSAGE_AUTHENTICATOR, 18, _:16/binary, Rest/binary>>,
                        MAC, Acc) ->
    <<Acc/binary, ?ATTR_MESSAGE_AUTHENTICATOR, 18, MAC/binary, Rest/binary>>;
replace_mac_placeholder(<<Type, Len, Rest/binary>>, MAC, Acc)
  when Len >= 2 ->
    BodyLen = Len - 2,
    <<Body:BodyLen/binary, More/binary>> = Rest,
    replace_mac_placeholder(More, MAC,
        <<Acc/binary, Type, Len, Body/binary>>);
replace_mac_placeholder(<<>>, _, Acc) ->
    Acc.

%%====================================================================
%% EAP-Message fragmentation (RFC 3579 §3.1 — 253-byte chunks)
%%====================================================================

eap_as_attrs(EAP) ->
    chunk_eap(EAP, []).

chunk_eap(<<>>, Acc) ->
    lists:reverse(Acc);
chunk_eap(Bin, Acc) when byte_size(Bin) =< 253 ->
    lists:reverse([{?ATTR_EAP_MESSAGE, Bin} | Acc]);
chunk_eap(<<Chunk:253/binary, Rest/binary>>, Acc) ->
    chunk_eap(Rest, [{?ATTR_EAP_MESSAGE, Chunk} | Acc]).

collect_eap(Attrs) ->
    iolist_to_binary([V || {?ATTR_EAP_MESSAGE, V} <- Attrs]).

%%====================================================================
%% MPPE key encryption (RFC 2548 §2.4.2)
%%====================================================================

mppe_vsa(SubType, EncKey) ->
    Vsa = <<?MS_VENDOR_ID:32/big, SubType, (byte_size(EncKey) + 2),
            EncKey/binary>>,
    {?ATTR_VENDOR_SPECIFIC, Vsa}.

encrypt_mppe_key(Key, Secret, RequestAuth) ->
    Salt = <<16#80, (rand:uniform(256) - 1)>>,
    Plaintext = <<(byte_size(Key)), Key/binary>>,
    Padded = pad_block(Plaintext, 16),
    mppe_enc(Padded, Secret, RequestAuth, Salt, <<>>, <<Salt/binary>>).

mppe_enc(<<>>, _Secret, _Prev, _Salt, _B, Acc) ->
    Acc;
mppe_enc(<<P:16/binary, Rest/binary>>, Secret, Prev, Salt, _B, Acc) ->
    BInput = case Prev of
        <<_:16/binary>> when Acc =:= <<Salt/binary>> ->
            <<Secret/binary, Prev/binary, Salt/binary>>;
        _ ->
            <<Secret/binary, Prev/binary>>
    end,
    B = crypto:hash(md5, BInput),
    C = crypto:exor(P, B),
    mppe_enc(Rest, Secret, C, Salt, B, <<Acc/binary, C/binary>>).

pad_block(Bin, N) ->
    Pad = (N - (byte_size(Bin) rem N)) rem N,
    <<Bin/binary, 0:(Pad*8)>>.

pad_msk(MSK) when byte_size(MSK) >= 64 -> MSK;
pad_msk(MSK) ->
    Need = 64 - byte_size(MSK),
    <<MSK/binary, 0:(Need*8)>>.

%%====================================================================
%% Message-Authenticator verification
%%====================================================================

verify_message_authenticator(Packet, Attrs, Secret) ->
    case lists:keyfind(?ATTR_MESSAGE_AUTHENTICATOR, 1, Attrs) of
        {_, Mac} when byte_size(Mac) =:= 16 ->
            Zeroed = zero_mac_in_packet(Packet),
            Expected = crypto:mac(hmac, md5, Secret, Zeroed),
            crypto:hash_equals(Expected, Mac);
        _ ->
            %% Message-Authenticator MUST be present in Access-Request
            %% carrying EAP per RFC 3579 §3.2; if absent, reject.
            not contains_eap(Attrs)
    end.

contains_eap(Attrs) ->
    lists:keyfind(?ATTR_EAP_MESSAGE, 1, Attrs) =/= false.

zero_mac_in_packet(<<Hdr:20/binary, Attrs/binary>>) ->
    <<Hdr/binary, (replace_mac_placeholder(Attrs, <<0:128>>, <<>>))/binary>>.

%%====================================================================
%% Attribute codecs
%%====================================================================

decode_attrs(<<>>) -> [];
decode_attrs(<<Type, Len, Rest/binary>>) when Len >= 2 ->
    BodyLen = Len - 2,
    <<Body:BodyLen/binary, More/binary>> = Rest,
    [{Type, Body} | decode_attrs(More)];
decode_attrs(_) -> [].

encode_attrs(Attrs) ->
    iolist_to_binary([<<T, (byte_size(V) + 2), V/binary>>
                      || {T, V} <- Attrs]).

get_attr(Type, Attrs) -> get_attr(Type, Attrs, undefined).
get_attr(Type, Attrs, Default) ->
    case lists:keyfind(Type, 1, Attrs) of
        {_, V} -> V;
        false  -> Default
    end.

%%====================================================================
%% Helpers
%%====================================================================

new_cookie(SessionId) ->
    <<SessionId/binary, ";",
      (integer_to_binary(erlang:unique_integer([positive])))/binary>>.

generate_id() ->
    T = erlang:system_time(microsecond),
    integer_to_binary(T).

to_bin(B) when is_binary(B) -> B;
to_bin(L) when is_list(L)   -> list_to_binary(L).

session_timeout() -> aaa_config:get(session_timeout, 3600).
