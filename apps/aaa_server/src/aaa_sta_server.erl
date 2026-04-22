%%%-------------------------------------------------------------------
%%% @doc STa Diameter application — trusted non-3GPP access.
%%%
%%% Application-ID 16777250, Vendor 10415 (3GPP TS 29.273 clause 6).
%%%
%%% Mirrors the SWm flow but with `AN-Trusted = TRUSTED(0)' and
%%% WLAN-specific AVPs (WLAN-Identifier / SSID / HESSID). Used for
%%% Carrier-Wi-Fi and Hotspot 2.0 / Passpoint deployments where the
%%% WLAN access network speaks Diameter STa directly to the 3GPP AAA.
%%%
%%% For WLAN controllers that only speak RADIUS, see `aaa_radius'
%%% which funnels EAP payloads into the same aaa_eap_relay engine.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_sta_server).

-include_lib("diameter/include/diameter.hrl").
-include("aaa_session.hrl").

-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

-export([emit_abort_session/1, emit_reauth/1]).

-define(SVC,        aaa_svc).
-define(APP_ALIAS,  sta).
-define(STA_APP_ID, 16777250).

%%====================================================================
%% Peer lifecycle
%%====================================================================

peer_up(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("STa peer up: ~s (trusted WLAN AN connected)",
                  [origin_host(Caps)]),
    aaa_metrics:gauge_inc(sta_peers),
    State.

peer_down(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("STa peer down: ~s", [origin_host(Caps)]),
    aaa_metrics:gauge_dec(sta_peers),
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
    aaa_metrics:inc(sta_requests_total),
    try
        Reply = dispatch(Msg, Caps),
        aaa_metrics:observe_latency(sta_latency,
            erlang:monotonic_time(millisecond) - Start),
        Reply
    catch Class:R:St ->
        logger:error("STa handle_request crash ~p:~p ~p", [Class, R, St]),
        {answer_message, 5012}
    end.

%%====================================================================
%% Dispatch
%%====================================================================

dispatch(['DER' | AVPs], Caps) -> handle_der(AVPs, Caps);
dispatch(['AAR' | AVPs], Caps) -> handle_aar(AVPs, Caps);
dispatch(['STR' | AVPs], Caps) -> handle_str(AVPs, Caps);
dispatch(['ASA' | _], _Caps)   -> discard;
dispatch(['RAA' | _], _Caps)   -> discard;
dispatch(_Other, _Caps)        -> {answer_message, 3001}.

%%====================================================================
%% DER — EAP relay with AN-Trusted=TRUSTED
%%====================================================================

handle_der(AVPs, Caps) ->
    SessionId  = avp('Session-Id', AVPs, <<>>),
    EapPayload = avp('EAP-Payload', AVPs, <<>>),
    PeerHost   = origin_host(Caps),

    Session0 = load_or_create_session(SessionId, AVPs, PeerHost),
    case aaa_eap_relay:process(sta, EapPayload, Session0) of
        {challenge, Resp, Updates} ->
            aaa_session_mgr:update_session(SessionId, Updates),
            {reply, dea_multi_round(SessionId, Resp)};
        {success, Resp, MSK, Updates} ->
            aaa_metrics:inc(sta_auth_success_total),
            aaa_session_mgr:update_session(SessionId, Updates),
            {reply, dea_success(SessionId, Resp, MSK, Session0)};
        {failure, Resp, _} ->
            aaa_metrics:inc(sta_auth_failure_total),
            {reply, dea_failure(SessionId, Resp, 4181)};
        {notification, Resp} ->
            {reply, dea_multi_round(SessionId, Resp)};
        {error, _} ->
            aaa_metrics:inc(sta_auth_failure_total),
            {reply, dea_failure(SessionId, <<>>, 4181)}
    end.

handle_aar(AVPs, Caps) ->
    SessionId = avp('Session-Id', AVPs, <<>>),
    IMSI      = avp('User-Name', AVPs, <<>>),
    AuthReqType = avp('Auth-Request-Type', AVPs, 1),
    APN       = avp('Service-Selection', AVPs, undefined),
    PeerHost  = origin_host(Caps),

    _ = load_or_create_session(SessionId, AVPs, PeerHost),
    aaa_session_mgr:update_session(SessionId,
        #{imsi => IMSI, apn => APN, origin_host => PeerHost,
          interface => sta, an_trusted => 0}),

    case aaa_swx_client:server_assignment_request(IMSI, 1, APN, #{}) of
        {ok, #{non_3gpp_user_data := UD, apn_configurations := APNs}} ->
            aaa_session_mgr:update_session(SessionId,
                #{non_3gpp_user_data => UD, apn_configuration => APNs}),
            {reply, aaa_ok(SessionId, IMSI, AuthReqType, UD, APNs)};
        {error, _} ->
            {reply, aaa_fail(SessionId, IMSI, AuthReqType, 5012)}
    end.

handle_str(AVPs, _Caps) ->
    SessionId = avp('Session-Id', AVPs, <<>>),
    case aaa_session_mgr:get_session(SessionId) of
        {ok, #aaa_session{imsi = IMSI}} when is_binary(IMSI) ->
            _ = aaa_swx_client:server_assignment_request(IMSI, 5, undefined, #{}),
            aaa_session_mgr:remove_session(SessionId);
        _ -> ok
    end,
    {reply, sta_response(SessionId, 2001)}.

%%====================================================================
%% Server-initiated ASR / RAR
%%====================================================================

-spec emit_abort_session(#aaa_session{}) -> ok.
emit_abort_session(#aaa_session{session_id = Sid, origin_host = PeerHost,
                                origin_realm = PeerRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Msg = ['ASR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', default_realm(PeerRealm, OR)},
           {'Destination-Host', default_host(PeerHost, OH)},
           {'Auth-Application-Id', ?STA_APP_ID},
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(sta_asr_total),
    ok.

-spec emit_reauth(#aaa_session{}) -> ok.
emit_reauth(#aaa_session{session_id = Sid, origin_host = PeerHost,
                         origin_realm = PeerRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Msg = ['RAR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', default_realm(PeerRealm, OR)},
           {'Destination-Host', default_host(PeerHost, OH)},
           {'Auth-Application-Id', ?STA_APP_ID},
           {'Re-Auth-Request-Type', 0},
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(sta_rar_total),
    ok.

%%====================================================================
%% Message builders
%%====================================================================

dea_multi_round(Sid, EapPayload) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['DEA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?STA_APP_ID},
     {'Result-Code', 1001},
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Request-Type', 3},
     {'EAP-Payload', EapPayload}].

dea_success(Sid, EapPayload, MSK,
            #aaa_session{non_3gpp_user_data = UD,
                         apn_configuration = APNs}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['DEA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?STA_APP_ID},
            {'Result-Code', 2001},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', 3},
            {'EAP-Payload', EapPayload},
            {'EAP-Master-Session-Key', MSK},
            {'Session-Timeout', session_timeout()},
            {'Auth-Grace-Period', 60},
            {'3GPP-AAA-Server-Name', OH}],
    with_subscription(Base, UD, APNs).

dea_failure(Sid, EapPayload, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['DEA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?STA_APP_ID},
            {'Result-Code', ResultCode},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', 3}],
    case EapPayload of
        <<>> -> Base;
        _    -> Base ++ [{'EAP-Payload', EapPayload}]
    end.

aaa_ok(Sid, IMSI, AuthReqType, UD, APNs) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['AAA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?STA_APP_ID},
            {'Result-Code', 2001},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', AuthReqType},
            {'User-Name', IMSI},
            {'Session-Timeout', session_timeout()},
            {'3GPP-AAA-Server-Name', OH}],
    with_subscription(Base, UD, APNs).

aaa_fail(Sid, IMSI, AuthReqType, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['AAA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?STA_APP_ID},
     {'Result-Code', ResultCode},
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Request-Type', AuthReqType},
     {'User-Name', IMSI}].

sta_response(Sid, RC) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['STA',
     {'Session-Id', Sid},
     {'Result-Code', RC},
     {'Origin-Host', OH},
     {'Origin-Realm', OR}].

with_subscription(Msg, undefined, _) -> Msg;
with_subscription(Msg, UD, APNs) ->
    Ext = [{'Non-3GPP-User-Data', UD}],
    ApnExt = case APNs of
        [] -> [];
        _  -> [{'APN-Configuration', APNs}]
    end,
    Msg ++ Ext ++ ApnExt.

%%====================================================================
%% Session bootstrap
%%====================================================================

load_or_create_session(SessionId, AVPs, PeerHost) ->
    case aaa_session_mgr:get_session(SessionId) of
        {ok, S} -> S;
        error   ->
            IMSI = avp('User-Name', AVPs, undefined),
            Rec = #aaa_session{
                session_id = SessionId,
                imsi = IMSI,
                interface = sta,
                origin_host = PeerHost,
                origin_realm = avp('Origin-Realm', AVPs, undefined),
                apn = avp('Service-Selection', AVPs, undefined),
                rat_type = avp('RAT-Type', AVPs, 0),
                an_trusted = avp('AN-Trusted', AVPs, 0),
                created_ts = 0, updated_ts = 0},
            ok = aaa_session_mgr:create_session(Rec),
            Rec
    end.

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

session_timeout() -> aaa_config:get(session_timeout, 3600).
