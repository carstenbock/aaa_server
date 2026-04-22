%%%-------------------------------------------------------------------
%%% @doc SWm Diameter application — terminates requests from the ePDG.
%%%
%%% Application-ID 16777264, Vendor 10415 (3GPP TS 29.273 clause 7).
%%%
%%% The module is a pure `diameter' application callback (no gen_server)
%%% registered on the shared service owned by `aaa_diameter_svc'. It
%%% dispatches on the actual Diameter command code — not on
%%% Auth-Request-Type — so STR/ASR/RAR are also routed, and emits
%%% server-initiated ASR/RAR toward the ePDG when the HSS drives a
%%% user deregistration or profile update (TS 29.273 §7.1.2.4).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_swm_server).

-include_lib("diameter/include/diameter.hrl").
-include("aaa_session.hrl").

%% Diameter application callbacks
-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

%% Server-initiated requests (called by SWx RTR/PPR handler)
-export([emit_abort_session/1, emit_reauth/1]).

-define(SVC,        aaa_svc).
-define(APP_ALIAS,  swm).
-define(SWM_APP_ID, 16777264).
-define(VENDOR_3GPP, 10415).

%%====================================================================
%% Diameter peer lifecycle
%%====================================================================

peer_up(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("SWm peer up: ~s (ePDG connected)", [origin_host(Caps)]),
    aaa_metrics:gauge_inc(swm_peers),
    State.

peer_down(_Svc, {_PeerRef, Caps}, State) ->
    logger:notice("SWm peer down: ~s", [origin_host(Caps)]),
    aaa_metrics:gauge_dec(swm_peers),
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

%% Incoming request dispatcher.
handle_request(#diameter_packet{msg = Msg, header = Hdr, errors = Errors,
                                avps = Avps} = _Pkt, _Svc,
               {_PeerRef, Caps}) ->
    Start = erlang:monotonic_time(millisecond),
    aaa_metrics:inc(swm_requests_total),
    %% #region agent log
    logger:notice("SWm handle_request: hdr=~P errors=~P msg=~P "
                  "avps_count=~p",
                  [Hdr, 10, Errors, 12, Msg, 10,
                   case Avps of L when is_list(L) -> length(L); _ -> 0 end]),
    %% #endregion
    try
        Reply = dispatch(Msg, Hdr, Caps),
        aaa_metrics:observe_latency(swm_latency,
            erlang:monotonic_time(millisecond) - Start),
        Reply
    catch Class:R:St ->
        logger:error("SWm handle_request crash ~p:~p ~p", [Class, R, St]),
        {answer_message, 5012}
    end.

%%====================================================================
%% Command dispatch (per Diameter command code, not Auth-Request-Type)
%%====================================================================

%% DER (Diameter-EAP-Request, code 268)
dispatch(['DER' | AVPs], _Hdr, Caps) ->
    handle_der(AVPs, Caps);
dispatch(['AAR' | AVPs], _Hdr, Caps) ->
    handle_aar(AVPs, Caps);
dispatch(['STR' | AVPs], _Hdr, Caps) ->
    handle_str(AVPs, Caps);
dispatch(['ASA' | _], _Hdr, _Caps) ->
    %% Answer to server-initiated ASR — just drop.
    discard;
dispatch(['RAA' | _], _Hdr, _Caps) ->
    discard;
dispatch(_Other, _Hdr, _Caps) ->
    {answer_message, 3001}.  % DIAMETER_COMMAND_UNSUPPORTED

%%====================================================================
%% DER — EAP relay
%%====================================================================

handle_der(AVPs, Caps) ->
    SessionId  = avp('Session-Id', AVPs, <<>>),
    EapPayload = avp('EAP-Payload', AVPs, <<>>),
    PeerHost   = origin_host(Caps),

    {Session0, SessionSource} =
        load_or_create_session_tagged(SessionId, AVPs, PeerHost),
    %% #region agent log
    logger:notice("SWm handle_der: session_id=~s source=~p eap_len=~p "
                  "imsi=~p eap_state=~p method=~p xres_len=~p k_aut_len=~p",
                  [SessionId, SessionSource,
                   case EapPayload of B when is_binary(B) -> byte_size(B);
                                       _ -> undefined end,
                   Session0#aaa_session.imsi,
                   Session0#aaa_session.eap_state,
                   Session0#aaa_session.method,
                   bin_len(Session0#aaa_session.xres),
                   bin_len(Session0#aaa_session.k_aut)]),
    %% #endregion
    Result = aaa_eap_relay:process(swm, EapPayload, Session0),
    %% #region agent log
    logger:notice("SWm handle_der: relay_result=~P",
                  [classify_relay(Result), 8]),
    %% #endregion
    case Result of
        {challenge, ResponseEAP, Updates} ->
            aaa_session_mgr:update_session(SessionId, Updates),
            {reply, dea_multi_round(SessionId, ResponseEAP)};
        {success, ResponseEAP, MSK, Updates} ->
            aaa_metrics:inc(swm_auth_success_total),
            aaa_session_mgr:update_session(SessionId, Updates),
            %% Issue SAR already-done inside aaa_eap_relay; fetch cached
            %% subscription to include in the DEA authorization half.
            {reply, dea_success(SessionId, ResponseEAP, MSK, Session0)};
        {failure, ResponseEAP, _Why} ->
            aaa_metrics:inc(swm_auth_failure_total),
            {reply, dea_failure(SessionId, ResponseEAP, 4181)};
        {notification, ResponseEAP} ->
            {reply, dea_multi_round(SessionId, ResponseEAP)};
        {error, _Reason} ->
            aaa_metrics:inc(swm_auth_failure_total),
            {reply, dea_failure(SessionId, <<>>, 4181)}
    end.

%% #region agent log
classify_relay({challenge, EAP, _U}) ->
    {challenge, eap_size(EAP)};
classify_relay({success, EAP, MSK, _U}) ->
    {success, eap_size(EAP),
     case MSK of M when is_binary(M) -> byte_size(M); _ -> 0 end};
classify_relay({failure, EAP, Why}) ->
    {failure, eap_size(EAP), Why};
classify_relay({notification, EAP}) ->
    {notification, eap_size(EAP)};
classify_relay({error, R}) ->
    {error, R};
classify_relay(Other) ->
    {other, Other}.

eap_size(B) when is_binary(B) -> byte_size(B);
eap_size(_) -> undefined.
%% #endregion

%%====================================================================
%% AAR — authorization
%%====================================================================

handle_aar(AVPs, Caps) ->
    SessionId = avp('Session-Id', AVPs, <<>>),
    IMSI      = avp('User-Name', AVPs, <<>>),
    AuthReqType = avp('Auth-Request-Type', AVPs, 1),
    PeerHost  = origin_host(Caps),
    APN       = avp('Service-Selection', AVPs, undefined),

    %% Ensure session exists with proper binding (IMSI ↔ SessionId).
    _ = load_or_create_session(SessionId, AVPs, PeerHost),
    aaa_session_mgr:update_session(SessionId,
        #{imsi => IMSI, apn => APN, origin_host => PeerHost,
          interface => swm}),

    AssignmentType = case AuthReqType of
        1 -> 1;    % AUTHORIZE_ONLY          → REGISTRATION
        2 -> 12;   % AUTHORIZE_AUTHENTICATE  → AAA_USER_DATA_REQUEST (refresh)
        3 -> 1;    % AUTHENTICATE_ONLY       → REGISTRATION
        _ -> 1
    end,
    case aaa_swx_client:server_assignment_request(IMSI, AssignmentType, APN, #{}) of
        {ok, #{non_3gpp_user_data := UserData, apn_configurations := APNs}} ->
            aaa_session_mgr:update_session(SessionId,
                #{non_3gpp_user_data => UserData,
                  apn_configuration => APNs}),
            {reply, aaa_success(SessionId, IMSI, AuthReqType, UserData, APNs)};
        {error, _R} ->
            {reply, aaa_failure(SessionId, IMSI, AuthReqType, 5012)}
    end.

%%====================================================================
%% STR — session termination
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
%% Server-initiated ASR / RAR toward ePDG (triggered by SWx RTR/PPR)
%%====================================================================

-spec emit_abort_session(#aaa_session{}) -> ok.
emit_abort_session(#aaa_session{session_id = Sid, origin_host = PeerHost,
                                origin_realm = PeerRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    DestRealm = case PeerRealm of
        undefined -> OR;
        V -> V
    end,
    DestHost = case PeerHost of
        undefined -> OH;
        H -> H
    end,
    Msg = ['ASR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', DestRealm},
           {'Destination-Host', DestHost},
           {'Auth-Application-Id', ?SWM_APP_ID},
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(swm_asr_total),
    ok.

-spec emit_reauth(#aaa_session{}) -> ok.
emit_reauth(#aaa_session{session_id = Sid, origin_host = PeerHost,
                         origin_realm = PeerRealm, imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    DestRealm = case PeerRealm of
        undefined -> OR;
        V -> V
    end,
    DestHost = case PeerHost of
        undefined -> OH;
        H -> H
    end,
    Msg = ['RAR',
           {'Session-Id', Sid},
           {'Origin-Host', OH},
           {'Origin-Realm', OR},
           {'Destination-Realm', DestRealm},
           {'Destination-Host', DestHost},
           {'Auth-Application-Id', ?SWM_APP_ID},
           {'Re-Auth-Request-Type', 0},   % AUTHORIZE_ONLY
           {'User-Name', IMSI},
           {'Auth-Session-State', 1}],
    _ = diameter:call(?SVC, ?APP_ALIAS, Msg, [detach]),
    aaa_metrics:inc(swm_rar_total),
    ok.

%%====================================================================
%% Message builders
%%====================================================================

dea_multi_round(Sid, EapPayload) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['DEA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?SWM_APP_ID},
     {'Result-Code', 1001},                % DIAMETER_MULTI_ROUND_AUTH
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Request-Type', 3},             % AUTHORIZE_AUTHENTICATE
     {'EAP-Payload', EapPayload}].

dea_success(Sid, EapPayload, MSK,
            #aaa_session{non_3gpp_user_data = UserData,
                         apn_configuration = APNs,
                         imsi = IMSI}) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['DEA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?SWM_APP_ID},
            {'Result-Code', 2001},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', 3},
            {'EAP-Payload', EapPayload},
            {'EAP-Master-Session-Key', MSK},
            {'Session-Timeout', session_timeout()},
            {'Auth-Grace-Period', 60},
            {'MIP6-Feature-Vector', mip6_feature_vector()},
            {'3GPP-AAA-Server-Name', OH}],
    with_subscription(Base, IMSI, UserData, APNs).

dea_failure(Sid, EapPayload, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['DEA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?SWM_APP_ID},
            {'Result-Code', ResultCode},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', 3}],
    case EapPayload of
        <<>> -> Base;
        _    -> Base ++ [{'EAP-Payload', EapPayload}]
    end.

aaa_success(Sid, IMSI, AuthReqType, UserData, APNs) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    Base = ['AAA',
            {'Session-Id', Sid},
            {'Auth-Application-Id', ?SWM_APP_ID},
            {'Result-Code', 2001},
            {'Origin-Host', OH},
            {'Origin-Realm', OR},
            {'Auth-Request-Type', AuthReqType},
            {'User-Name', IMSI},
            {'Session-Timeout', session_timeout()},
            {'MIP6-Feature-Vector', mip6_feature_vector()},
            {'3GPP-AAA-Server-Name', OH}],
    with_subscription(Base, IMSI, UserData, APNs).

aaa_failure(Sid, IMSI, AuthReqType, ResultCode) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['AAA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?SWM_APP_ID},
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

with_subscription(Msg, _IMSI, undefined, _) -> Msg;
with_subscription(Msg, _IMSI, UserData, APNs) ->
    Ext = case UserData of
        undefined -> [];
        UD        -> [{'Non-3GPP-User-Data', UD}]
    end,
    ApnExt = case APNs of
        [] -> [];
        _  -> [{'APN-Configuration', APNs}]
    end,
    Msg ++ Ext ++ ApnExt.

%%====================================================================
%% Session management
%%====================================================================

load_or_create_session(SessionId, AVPs, PeerHost) ->
    {S, _Src} = load_or_create_session_tagged(SessionId, AVPs, PeerHost),
    S.

load_or_create_session_tagged(SessionId, AVPs, PeerHost) ->
    case aaa_session_mgr:get_session(SessionId) of
        {ok, S} ->
            {S, existing};
        error ->
            IMSI = avp('User-Name', AVPs, undefined),
            Rec = #aaa_session{
                session_id = SessionId,
                imsi = IMSI,
                interface = swm,
                origin_host = PeerHost,
                origin_realm = avp('Origin-Realm', AVPs, undefined),
                apn = avp('Service-Selection', AVPs, undefined),
                rat_type = avp('RAT-Type', AVPs, 0),
                visited_plmn = avp('Visited-Network-Identifier', AVPs, undefined),
                created_ts = 0, updated_ts = 0},
            ok = aaa_session_mgr:create_session(Rec),
            {Rec, created}
    end.

%% #region agent log
bin_len(B) when is_binary(B) -> byte_size(B);
bin_len(_)                   -> 0.
%% #endregion

%%====================================================================
%% Helpers
%%====================================================================

%% The generated SWm dictionary declares User-Name, EAP-Payload, etc.
%% as `[AVP]` (0..1). With `decode_format=list`, OTP delivers these as a
%% one-element list `[Value]` when present. Unwrap to hand callers the
%% scalar value they expect (and match the `Default' shape).
avp(Key, List, Default) ->
    case proplists:get_value(Key, List, Default) of
        [V]   -> V;
        Other -> Other
    end.

origin_host(#diameter_caps{origin_host = {_, H}}) -> H;
origin_host(_) -> <<"unknown">>.

inject_origin(Msg, Caps) when is_list(Msg) ->
    #diameter_caps{origin_host = {OH, _}, origin_realm = {OR, _}} = Caps,
    Stripped = [AVP || AVP <- Msg,
                       not is_origin(AVP)],
    Cmd = hd(Stripped),
    [Cmd, {'Origin-Host', OH}, {'Origin-Realm', OR} | tl(Stripped)].

is_origin({'Origin-Host', _})  -> true;
is_origin({'Origin-Realm', _}) -> true;
is_origin(_)                   -> false.

to_bin(B) when is_binary(B) -> B;
to_bin(L) when is_list(L)   -> list_to_binary(L).

session_timeout() ->
    %% Default 1h; operator can override via AAA_SESSION_TIMEOUT in aaa_config.
    aaa_config:get(session_timeout, 3600).

%% MIP6-Feature-Vector bits (RFC 5447 §4.1):
%%   0x00000001 = MIP6_INTEGRATED
%%   0x00010000 = PMIP6_SUPPORTED
%%   0x00020000 = GTPv2_BASED
%%   0x00040000 = ASSIGN_HOME_LINK_LOCAL_PREFIX_IN_IPV4_HOA
%% Default: PMIP6_SUPPORTED | GTPv2_BASED, suitable for ePDG→PGW over
%% GTPv2 as deployed today.
mip6_feature_vector() ->
    aaa_config:get(mip6_feature_vector, 16#00030000).
