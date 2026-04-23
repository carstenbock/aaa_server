%%%-------------------------------------------------------------------
%%% @doc S6b Diameter application — terminates requests from the PGW
%%% (or SMF in 5G) to authorize a non-3GPP PDN session.
%%%
%%% Application-ID 16777272, Vendor 10415 (3GPP TS 29.273 clause 9).
%%%
%%% AAR from PGW looks up the cached subscriber profile keyed by IMSI
%%% and returns APN-Configuration, AMBR, MIP6-Agent-Info. If the AAA
%%% has no cached profile yet (PGW arrived before ePDG or the AAA was
%%% restarted) we issue a SWx SAR with Server-Assignment-Type = 13
%%% (PGW_UPDATE) so the HSS sends us the user profile.
%%%
%%% STR from PGW triggers SWx SAR type 5 (USER_DEREGISTRATION) when
%%% this was the last binding for the IMSI.
%%%
%%% AAA-initiated ASR/RAR are exposed for the SWx RTR/PPR handler.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_s6b_server).

-include_lib("diameter/include/diameter.hrl").
-include("aaa_session.hrl").

%% Diameter callbacks
-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

%% Server-initiated requests
-export([emit_abort_session/1, emit_reauth/1]).

-define(SVC,        aaa_svc).
-define(APP_ALIAS,  s6b).
-define(S6B_APP_ID, 16777272).

%%====================================================================
%% Peer lifecycle
%%====================================================================

peer_up(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("S6b peer up: ~s (PGW/SMF connected)", [origin_host(Caps)]),
    aaa_metrics:gauge_inc(s6b_peers),
    State.

peer_down(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("S6b peer down: ~s", [origin_host(Caps)]),
    aaa_metrics:gauge_dec(s6b_peers),
    State.

pick_peer([P | _], _, _, _) -> {ok, P};
pick_peer([], _, _, _)       -> false.

prepare_request(#diameter_packet{msg = Msg} = Pkt, _Svc, {_, Caps}) ->
    {send, Pkt#diameter_packet{msg = inject_origin(Msg, Caps)}}.

prepare_retransmit(Pkt, Svc, Peer) ->
    prepare_request(Pkt, Svc, Peer).

handle_answer(#diameter_packet{msg = Msg}, _Req, _Svc, _Peer) ->
    {ok, Msg}.

handle_error(Reason, _Req, _Svc, _Peer) ->
    {error, Reason}.

handle_request(#diameter_packet{msg = Msg}, _Svc, {_PeerRef, Caps}) ->
    Start = erlang:monotonic_time(millisecond),
    aaa_metrics:inc(s6b_requests_total),
    try
        Reply = dispatch(Msg, Caps),
        aaa_metrics:observe_latency(s6b_latency,
            erlang:monotonic_time(millisecond) - Start),
        Reply
    catch Class:R:St ->
        logger:error("S6b handle_request crash ~p:~p ~p", [Class, R, St]),
        {answer_message, 5012}
    end.

%%====================================================================
%% Dispatch
%%====================================================================

dispatch(['AAR' | AVPs], Caps) -> handle_aar(AVPs, Caps);
dispatch(['STR' | AVPs], Caps) -> handle_str(AVPs, Caps);
dispatch(['ASA' | _], _Caps)   -> discard;
dispatch(['RAA' | _], _Caps)   -> discard;
dispatch(_Other, _Caps)        -> {answer_message, 3001}.

%%====================================================================
%% AAR
%%====================================================================

handle_aar(AVPs, Caps) ->
    SessionId = avp('Session-Id', AVPs, <<>>),
    IMSI      = avp('User-Name', AVPs, <<>>),
    APN       = avp('Service-Selection', AVPs, undefined),
    PGWHost   = origin_host(Caps),
    AuthReqType = avp('Auth-Request-Type', AVPs, 1),

    %% Create / update S6b session record.
    Rec = #aaa_session{
        session_id = SessionId,
        imsi = IMSI,
        interface = s6b,
        origin_host = PGWHost,
        origin_realm = avp('Origin-Realm', AVPs, undefined),
        apn = APN,
        pgw_id = PGWHost,
        created_ts = 0, updated_ts = 0},
    aaa_session_mgr:create_session(Rec),

    %% Fetch cached subscription, or pull fresh from HSS via SAR 13.
    CacheLookup = find_cached_profile(IMSI),
    {Non3gpp, APNs} =
        case CacheLookup of
            {ok, UD, A} -> {UD, A};
            none        -> fetch_from_hss(IMSI, APN)
        end,

    aaa_session_mgr:update_session(SessionId,
        #{non_3gpp_user_data => Non3gpp,
          apn_configuration => APNs}),

    SelectedAPN = select_apn(APN, APNs),
    case SelectedAPN of
        undefined ->
            aaa_metrics:inc(s6b_auth_failure_total),
            {reply, aaa_fail(SessionId, IMSI, AuthReqType, 5451)}; % NO_APN_SUBSCRIPTION
        _ ->
            aaa_metrics:inc(s6b_auth_success_total),
            {reply, aaa_ok(SessionId, IMSI, AuthReqType, SelectedAPN)}
    end.

%%====================================================================
%% STR
%%====================================================================

handle_str(AVPs, _Caps) ->
    SessionId = avp('Session-Id', AVPs, <<>>),
    case aaa_session_mgr:get_session(SessionId) of
        {ok, #aaa_session{imsi = IMSI}} when is_binary(IMSI) ->
            _ = aaa_swx_client:server_assignment_request(IMSI, 5, undefined, #{}),
            aaa_session_mgr:remove_session(SessionId);
        _ ->
            ok
    end,
    {reply, sta_response(SessionId, 2001)}.

%%====================================================================
%% Server-initiated ASR / RAR (AAA → PGW)
%%====================================================================

-spec emit_abort_session(#aaa_session{}) -> ok.
emit_abort_session(#aaa_session{session_id = Sid, origin_host = PGW,
                                origin_realm = PGWRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Msg = ['ASR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', default_realm(PGWRealm, OR)},
           {'Destination-Host', default_host(PGW, OH)},
           {'Auth-Application-Id', ?S6B_APP_ID},
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(s6b_asr_total),
    ok.

-spec emit_reauth(#aaa_session{}) -> ok.
emit_reauth(#aaa_session{session_id = Sid, origin_host = PGW,
                         origin_realm = PGWRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Msg = ['RAR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', default_realm(PGWRealm, OR)},
           {'Destination-Host', default_host(PGW, OH)},
           {'Auth-Application-Id', ?S6B_APP_ID},
           {'Re-Auth-Request-Type', 0},
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(s6b_rar_total),
    ok.

%%====================================================================
%% Subscription fetch
%%====================================================================

find_cached_profile(IMSI) ->
    Sessions = aaa_session_mgr:get_sessions_for_imsi(IMSI),
    case [{UD, APNs} ||
          #aaa_session{non_3gpp_user_data = UD, apn_configuration = APNs} <- Sessions,
          UD =/= undefined] of
        [{UD, APNs} | _] -> {ok, UD, APNs};
        _                -> none
    end.

fetch_from_hss(IMSI, APN) ->
    %% Server-Assignment-Type = 13 (PGW_UPDATE) per TS 29.273 §8.1.2.2.
    case aaa_swx_client:server_assignment_request(IMSI, 13, APN, #{}) of
        {ok, #{non_3gpp_user_data := UD, apn_configurations := APNs}} ->
            {UD, APNs};
        {error, _} ->
            {undefined, []}
    end.

select_apn(undefined, [First | _]) -> First;
select_apn(undefined, _)           -> undefined;
%% Erlang's diameter decoder wraps arity 0..1 AVPs in a one-element list,
%% so the 'Service-Selection' AVP from the PGW's S6b AAR arrives as
%% [<<"ims">>] while the Service-Selection stored inside each decoded
%% APN-Configuration proplist is the bare binary <<"ims">>. Unwrap.
select_apn([APN], APNs) -> select_apn(APN, APNs);
select_apn([], _)       -> undefined;
select_apn(APN, APNs) ->
    Match = [A || A <- APNs,
                  proplists:get_value('Service-Selection', A) =:= APN],
    case Match of
        [Sel | _] -> Sel;
        []        -> undefined
    end.

%%====================================================================
%% Response builders
%%====================================================================

aaa_ok(Sid, IMSI, AuthReqType, APNConfig) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    %% Build an APN-Configuration proplist that matches what the S6b
    %% dictionary (AVP 1430) knows about, and in the exact shape the
    %% Erlang diameter encoder expects:
    %%   - APN-Configuration (arity 0..1 in AAA) must be wrapped in a
    %%     one-element list → [Proplist].
    %%   - The grouped sub-AVP AMBR (arity 0..1 inside APN-Configuration)
    %%     must also be wrapped → {'AMBR', [Proplist]}.
    %%   - Everything the HSS sent us on SWx that isn't in s6b.dia
    %%     (EPS-Subscribed-QoS-Profile, MIP6-*, …) has to be stripped,
    %%     otherwise the encoder raises {badmatch,undefined} in
    %%     diameter_codec:enc/3, no bytes get on the wire, and the PGW
    %%     times out locally → freeDiameter surfaces 3002
    %%     DIAMETER_UNABLE_TO_DELIVER (this was the original symptom).
    SafeAPN = build_s6b_apn(APNConfig),
    BareIMSI = unwrap_user_name(IMSI),
    ['AAA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?S6B_APP_ID},
     {'Result-Code', 2001},
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Request-Type', AuthReqType},
     {'User-Name', BareIMSI},
     {'Session-Timeout', session_timeout()},
     {'MIP6-Feature-Vector', mip6_feature_vector()},
     {'3GPP-AAA-Server-Name', OH},
     {'APN-Configuration', [SafeAPN]}].

%% The SWx decoder delivers 'User-Name' from the AAR as a one-element
%% list ([<<"…">>]) because of its arity-0..1 declaration. For the
%% outgoing AAA we want the bare binary the s6b dict expects.
unwrap_user_name([B | _]) when is_binary(B) -> B;
unwrap_user_name(B) when is_binary(B)       -> B;
unwrap_user_name(_)                          -> <<>>.

%% Build a clean APN-Configuration proplist from what the HSS returned
%% on SWx. Only the four AVPs that s6b.dia lists under AVP 1430 survive
%% (Context-Identifier, PDN-Type, Service-Selection, AMBR) and the AMBR
%% sub-AVP is re-wrapped to match the encoder's 0..1 arity expectation.
build_s6b_apn(APNConfig) when is_list(APNConfig) ->
    CtxId  = proplists:get_value('Context-Identifier', APNConfig, 1),
    PdnT   = proplists:get_value('PDN-Type', APNConfig, 0),
    SvcSel = proplists:get_value('Service-Selection', APNConfig, <<>>),
    Base = [{'Context-Identifier', CtxId},
            {'PDN-Type', PdnT},
            {'Service-Selection', SvcSel}],
    case normalise_ambr(proplists:get_value('AMBR', APNConfig)) of
        undefined -> Base;
        Flat      -> Base ++ [{'AMBR', [Flat]}]
    end;
build_s6b_apn(_) ->
    [{'Context-Identifier', 1}, {'PDN-Type', 0}, {'Service-Selection', <<>>}].

%% The HSS-derived AMBR arrives double-list-wrapped — [[{UL,X},{DL,Y}]] —
%% from the SWx decoder (0..1 wrap of a grouped AVP). Peel the outer
%% list so the encoder sees a flat proplist; we re-wrap it in the caller.
normalise_ambr([Inner | _]) when is_list(Inner) -> Inner;
normalise_ambr(L) when is_list(L)               -> L;
normalise_ambr(_)                                -> undefined.

aaa_fail(Sid, IMSI, AuthReqType, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['AAA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?S6B_APP_ID},
     {'Result-Code', ResultCode},
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Request-Type', AuthReqType},
     {'User-Name', IMSI}].

sta_response(Sid, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['STA',
     {'Session-Id', Sid},
     {'Result-Code', ResultCode},
     {'Origin-Host', OH},
     {'Origin-Realm', OR}].

%%====================================================================
%% Helpers
%%====================================================================

avp(K, L, D) -> proplists:get_value(K, L, D).

origin_host(#diameter_caps{origin_host = {_, H}}) -> H;
origin_host(_) -> <<"unknown">>.

inject_origin(Msg, Caps) when is_list(Msg) ->
    #diameter_caps{origin_host = {OH, _}, origin_realm = {OR, _}} = Caps,
    Stripped = [A || A <- Msg, not is_origin(A)],
    Cmd = hd(Stripped),
    [Cmd, {'Origin-Host', OH}, {'Origin-Realm', OR} | tl(Stripped)].

is_origin({'Origin-Host', _})  -> true;
is_origin({'Origin-Realm', _}) -> true;
is_origin(_)                   -> false.

default_realm(undefined, Def) -> Def;
default_realm(V, _)           -> V.
default_host(undefined, Def)  -> Def;
default_host(V, _)            -> V.

to_bin(B) when is_binary(B) -> B;
to_bin(L) when is_list(L)   -> list_to_binary(L).

session_timeout()        -> aaa_config:get(session_timeout, 3600).
mip6_feature_vector()    -> aaa_config:get(mip6_feature_vector, 16#00030000).
