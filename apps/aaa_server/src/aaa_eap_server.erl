%%%-------------------------------------------------------------------
%%% @doc Diameter EAP application (RFC 4072, Application-Id 5).
%%%
%%% Serves clients that need an EAP-AKA / EAP-AKA' authentication and
%%% nothing else: the access-proxy that relays the embedded EAP-AKA of
%%% GSMA TS.43 §2.8.1 (ADR-0030). Only
%%% `Auth-Request-Type = AUTHENTICATE_ONLY' is accepted.
%%%
%%% Such a request must never disturb a VoWiFi session of the same
%%% subscriber, so this module shares only the EAP engine
%%% (`aaa_eap_relay') with SWm:
%%%
%%%   * no SWx SAR (the subscriber does not attach),
%%%   * the EAP state is kept under its own Redis key (`eap:<Session-Id>')
%%%     with a short lifetime. It is not an `aaa_session_mgr' session:
%%%     it is in no IMSI or interface index and not under `sess:', so
%%%     supersede, STR follow-up, RTR, PPR, the SWm audit and the
%%%     clean-up cannot see it,
%%%   * no ePDG bookkeeping (Origin-Host list, Origin-State-Id),
%%%   * no key material in the answer.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_server).

-include_lib("diameter/include/diameter.hrl").
-include("aaa_session.hrl").

%% Diameter application callbacks
-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

%% Pure parts, exported for the test suite.
-export([check_request/1, outcome/2, dea/4, state_key/1]).

-define(EAP_APP_ID, 5).
%% RFC 6733 §8.7
-define(AUTHENTICATE_ONLY, 1).
%% RFC 6733 §8.11
-define(NO_STATE_MAINTAINED, 1).

-define(DEFAULT_STATE_TTL_SEC, 60).

%%====================================================================
%% Diameter callbacks
%%====================================================================

peer_up(_Svc, _Peer, State)   -> State.
peer_down(_Svc, _Peer, State) -> State.

%% The AAA never sends a request on this application.
pick_peer(_, _, _, _) -> false.

prepare_request(Pkt, _Svc, _Peer)    -> {send, Pkt}.
prepare_retransmit(Pkt, _Svc, _Peer) -> {send, Pkt}.

handle_answer(#diameter_packet{msg = Msg}, _Req, _Svc, _Peer) -> {ok, Msg}.
handle_error(Reason, _Req, _Svc, _Peer) -> {error, Reason}.

handle_request(#diameter_packet{errors = [E | _]}, _Svc, _Peer) ->
    %% A request that does not match RFC 4072 §3.1 (e.g. no EAP-Payload).
    {answer_message, error_code(E)};
handle_request(#diameter_packet{msg = ['DER' | AVPs]}, _Svc, _Peer) ->
    aaa_metrics:inc(eap_app_requests_total),
    try
        handle_der(AVPs)
    catch Class:R:St ->
        logger:error("EAP app handle_request crash ~p:~p ~p", [Class, R, St]),
        {answer_message, 5012}
    end;
handle_request(_Pkt, _Svc, _Peer) ->
    {answer_message, 3001}.  % DIAMETER_COMMAND_UNSUPPORTED

error_code({RC, _Avp}) when is_integer(RC) -> RC;
error_code(RC) when is_integer(RC)         -> RC;
error_code(_)                              -> 5012.

%%====================================================================
%% DER
%%====================================================================

handle_der(AVPs) ->
    Sid = avp('Session-Id', AVPs, <<>>),
    Art = avp('Auth-Request-Type', AVPs, undefined),
    case check_request(AVPs) of
        ok ->
            S0 = load_state(Sid, AVPs),
            Payload = avp('EAP-Payload', AVPs, <<>>),
            finish(Sid, S0, outcome(aaa_eap_relay:process(eap, Payload, S0), S0));
        {error, RC, Text} ->
            aaa_metrics:inc(eap_app_auth_failure_total),
            {reply, dea(Sid, Art, RC, [{'Error-Message', Text}])}
    end.

%% @doc Only an authentication can be asked for on this application.
%% An authorization would need the SWm procedures (SAR, APN check), and
%% answering DIAMETER_SUCCESS to AUTHORIZE_AUTHENTICATE would tell the
%% client that service is authorized (RFC 4072 §3.2). RFC 4072 names no
%% result code for this case; DIAMETER_INVALID_AVP_VALUE (RFC 6733
%% §7.1.5) is used.
-spec check_request(list()) -> ok | {error, pos_integer(), binary()}.
check_request(AVPs) ->
    case avp('Auth-Request-Type', AVPs, undefined) of
        ?AUTHENTICATE_ONLY -> ok;
        _ -> {error, 5004,
              <<"Auth-Request-Type: only AUTHENTICATE_ONLY is supported">>}
    end.

finish(Sid, S0, {continue, Updates, Extra}) ->
    case store_state(Sid, S0, Updates) of
        ok ->
            {reply, dea(Sid, ?AUTHENTICATE_ONLY, 1001, Extra)};
        {error, Reason} ->
            logger:error("EAP app sid=~s: cannot store EAP state: ~p",
                         [Sid, Reason]),
            aaa_metrics:inc(eap_app_auth_failure_total),
            {reply, dea(Sid, ?AUTHENTICATE_ONLY, 5012, [])}
    end;
finish(Sid, _S0, {final, RC, Extra}) ->
    _ = aaa_redis:del(state_key(Sid)),
    aaa_metrics:inc(case RC of
                        2001 -> eap_app_auth_success_total;
                        _    -> eap_app_auth_failure_total
                    end),
    {reply, dea(Sid, ?AUTHENTICATE_ONLY, RC, Extra)}.

%% @doc Map the result of the EAP engine to the answer.
%%
%% The result codes are chosen so that a TS.43 relay can apply
%% GSMA TS.43 §2.8.1 Table 7 (1001, 2001; 4001 = permanent failure;
%% 5002 and 5012 = retry). RFC 4072 §3.2 requires a base Result-Code in
%% every DEA, so an unknown user is DIAMETER_AUTHENTICATION_REJECTED
%% (RFC 6733 §7.1.4) and the cause is given in Error-Message.
-spec outcome(term(), #aaa_session{}) ->
    {continue, map(), list()} | {final, pos_integer(), list()}.
outcome({challenge, Eap, Updates}, _S) ->
    {continue, Updates, [{'EAP-Payload', Eap}]};
outcome({notification, Eap}, _S) ->
    {continue, #{}, [{'EAP-Payload', Eap}]};
outcome({success, Eap, _MSK, _Updates}, S) ->
    %% RFC 4072 §2.8.1: return the user's identity with DIAMETER_SUCCESS.
    %% No EAP-Master-Session-Key: the client asked for authentication
    %% only and protects no link with it.
    {final, 2001, [{'EAP-Payload', Eap} | user_name(S)]};
outcome({failure, _Notification, auth_reject}, S) ->
    %% The peer rejected the network: RFC 4187 §6.3.3 case 2, EAP-Failure.
    rejected(S, auth_reject);
outcome({failure, Notification, Why}, _S) ->
    %% RES or AT_MAC wrong. RFC 4187 §6.3.2: the server answers with an
    %% AKA-Notification that implies failure.
    %% SPEC-DEVIATION: RFC 4187 §6.3.3 case 3 -- the dialog ends with this
    %% answer; the peer's response to the notification and the EAP-Failure
    %% after it are not exchanged (as on SWm), because the result code
    %% already ends the HTTP relay (TS.43 §2.8.1 Table 7: 403).
    {final, 4001, [{'EAP-Payload', Notification}, error_message(Why)]};
outcome({error, {client_error, Code}}, S) ->
    %% RFC 4187 §6.3.3 case 1.
    rejected(S, {client_error, Code});
outcome({error, {swx_mar, {diameter_error, 5001}}}, S) ->
    rejected(S, user_unknown);
outcome({error, challenge_without_session_state}, _S) ->
    %% The EAP state expired or the request reached another AAA node
    %% than the first one: DIAMETER_UNKNOWN_SESSION_ID, the client
    %% starts again.
    {final, 5002, [{'Error-Message', <<"no EAP state for this Session-Id">>}]};
outcome({error, Reason}, S) when Reason =:= eap_decode;
                                 Reason =:= invalid_eap;
                                 Reason =:= unexpected_eap;
                                 Reason =:= sync_failure_missing_auts ->
    %% RFC 4072 §2.4: a fatal error in the EAP packet is answered with a
    %% failure Result-Code and an EAP-Failure.
    %% SPEC-DEVIATION: RFC 4187 §6.3.2 -- no AKA-Notification is sent for
    %% a response that cannot be parsed or is unexpected (KI-204).
    rejected(S, Reason);
outcome({error, Reason}, _S) ->
    %% The HSS did not deliver vectors (no answer, no route, an error
    %% other than "user unknown"): temporary, DIAMETER_UNABLE_TO_COMPLY.
    logger:warning("EAP app: authentication not possible: ~p", [Reason]),
    {final, 5012, [{'Error-Message', <<"authentication vectors unavailable">>}]}.

rejected(S, Why) ->
    {final, 4001,
     [{'EAP-Payload', aaa_eap_codec:build_failure(eap_id(S))},
      error_message(Why)]}.

error_message(Why) ->
    {'Error-Message', iolist_to_binary(io_lib:format("~0p", [Why]))}.

eap_id(#aaa_session{eap_id = Id}) when is_integer(Id) -> Id;
eap_id(_)                                             -> 0.

user_name(#aaa_session{nai = NAI}) when is_binary(NAI), NAI =/= <<>> ->
    [{'User-Name', NAI}];
user_name(_) ->
    [].

%% @doc Build a DEA (RFC 4072 §3.2). No state is kept after the final
%% answer, so the client is told not to send an STR (RFC 6733 §8.11).
-spec dea(binary(), term(), pos_integer(), list()) -> list().
dea(Sid, AuthRequestType, ResultCode, Extra) ->
    OH = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OR = to_bin(aaa_config:get(origin_realm, "localdomain")),
    ['DEA',
     {'Session-Id', Sid},
     {'Auth-Application-Id', ?EAP_APP_ID},
     {'Auth-Request-Type', case AuthRequestType of
                               N when is_integer(N) -> N;
                               _                    -> ?AUTHENTICATE_ONLY
                           end},
     {'Result-Code', ResultCode},
     {'Origin-Host', OH},
     {'Origin-Realm', OR},
     {'Auth-Session-State', ?NO_STATE_MAINTAINED}
     | Extra].

%%====================================================================
%% EAP state (not an aaa_session_mgr session, see module doc)
%%====================================================================

-spec state_key(binary()) -> binary().
state_key(Sid) -> aaa_redis:key([<<"eap:">>, Sid]).

load_state(Sid, AVPs) ->
    case aaa_redis:get(state_key(Sid)) of
        {ok, Bin} when is_binary(Bin) ->
            try binary_to_term(Bin, [safe]) of
                #aaa_session{} = S -> S;
                _                  -> new_state(Sid, AVPs)
            catch _:_ -> new_state(Sid, AVPs)
            end;
        _ ->
            new_state(Sid, AVPs)
    end.

new_state(Sid, AVPs) ->
    Now = erlang:system_time(second),
    #aaa_session{session_id = Sid,
                 imsi = undefined,
                 interface = eap,
                 origin_host = avp('Origin-Host', AVPs, undefined),
                 origin_realm = avp('Origin-Realm', AVPs, undefined),
                 created_ts = Now, updated_ts = Now}.

store_state(Sid, S0, Updates) ->
    S1 = aaa_session_mgr:apply_updates(S0, Updates),
    S2 = S1#aaa_session{updated_ts = erlang:system_time(second)},
    aaa_redis:setex(state_key(Sid), state_ttl(),
                    term_to_binary(S2, [{compressed, 3}])).

state_ttl() ->
    case aaa_config:get(eap_app_state_ttl, ?DEFAULT_STATE_TTL_SEC) of
        N when is_integer(N), N > 0 -> N;
        _                           -> ?DEFAULT_STATE_TTL_SEC
    end.

%%====================================================================
%% Helpers
%%====================================================================

%% decode_format=list delivers a 0..1 AVP as a one-element list.
avp(Key, List, Default) ->
    case proplists:get_value(Key, List, Default) of
        [V]   -> V;
        Other -> Other
    end.

to_bin(B) when is_binary(B) -> B;
to_bin(L) when is_list(L)   -> list_to_binary(L).
