%%%-------------------------------------------------------------------
%%% @doc CT suite for the Diameter EAP application (RFC 4072,
%%% Application-Id 5; aaa_eap_server, ADR-0030).
%%%
%%% Why these tests exist: the application authenticates subscribers
%%% for the TS.43 entitlement server while the same subscribers have
%%% VoWiFi sessions on SWm. An authentication must not register at the
%%% HSS and must not touch a SWm session, and its result codes must be
%%% the ones GSMA TS.43 §2.8.1 Table 7 maps.
%%%
%%% The `store' group needs Redis (as aaa_session_mgr_SUITE) and is
%%% skipped without it unless AAA_REDIS_REQUIRED=1.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_server_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("diameter/include/diameter.hrl").
-include("../include/aaa_session.hrl").
-include("../include/aaa_eap.hrl").

-export([all/0, groups/0, suite/0,
         init_per_suite/1, end_per_suite/1,
         init_per_group/2, end_per_group/2,
         init_per_testcase/2, end_per_testcase/2]).
-export([
    dictionary_is_rfc4072_application_5/1,
    der_without_eap_payload_is_a_missing_avp/1,
    only_authenticate_only_is_accepted/1,
    outcome_codes_are_the_ones_ts43_table7_maps/1,
    success_names_the_user_and_carries_no_key/1,
    eap_application_does_not_register_at_the_hss/1,
    eap_start_keeps_state_outside_the_session_store/1,
    success_leaves_the_vowifi_session_alone/1,
    other_auth_request_types_are_rejected/1
]).

-define(EAP_APP_ID, 5).
-define(TEST_PREFIX, <<"aaa_test:">>).
-define(IMSI, <<"001019999000001">>).
-define(NAI, <<"0001019999000001@nai.epc.mnc001.mcc001.3gppnetwork.org">>).

suite() -> [{timetrap, {seconds, 60}}].

all() -> [{group, pure}, {group, store}].

groups() ->
    [{pure, [], [dictionary_is_rfc4072_application_5,
                 der_without_eap_payload_is_a_missing_avp,
                 only_authenticate_only_is_accepted,
                 outcome_codes_are_the_ones_ts43_table7_maps,
                 success_names_the_user_and_carries_no_key,
                 eap_application_does_not_register_at_the_hss]},
     {store, [], [eap_start_keeps_state_outside_the_session_store,
                  success_leaves_the_vowifi_session_alone,
                  other_auth_request_types_are_rejected]}].

init_per_suite(Config) ->
    ok = aaa_metrics:init(),
    application:load(aaa_server),
    application:set_env(aaa_server, origin_host, "aaa-0.test"),
    application:set_env(aaa_server, origin_realm, "test"),
    {ok, _} = application:ensure_all_started(diameter),
    Config.

end_per_suite(_Config) -> ok.

init_per_group(store, Config) ->
    Host = os:getenv("AAA_REDIS_HOST", "127.0.0.1"),
    Port = list_to_integer(os:getenv("AAA_REDIS_PORT", "6379")),
    case gen_tcp:connect(Host, Port, [binary, {active, false}], 1000) of
        {ok, Sock} ->
            gen_tcp:close(Sock),
            application:set_env(aaa_server, redis_host, Host),
            application:set_env(aaa_server, redis_port, Port),
            application:set_env(aaa_server, redis_db,
                list_to_integer(os:getenv("AAA_REDIS_TEST_DB", "15"))),
            application:set_env(aaa_server, redis_password, ""),
            application:set_env(aaa_server, redis_pool_size, 2),
            application:set_env(aaa_server, redis_connect_timeout, 3000),
            application:set_env(aaa_server, redis_reconnect_sleep, 250),
            application:set_env(aaa_server, redis_key_prefix, ?TEST_PREFIX),
            application:set_env(aaa_server, session_timeout, 300),
            application:ensure_all_started(eredis),
            Config;
        {error, Reason} ->
            case os:getenv("AAA_REDIS_REQUIRED", "0") of
                "1" -> ct:fail({redis_unavailable, Reason});
                _   -> {skip, {"Redis unreachable", Reason}}
            end
    end;
init_per_group(_, Config) -> Config.

end_per_group(_, _Config) -> ok.

init_per_testcase(TC, Config) ->
    case lists:member(TC, [eap_start_keeps_state_outside_the_session_store,
                           success_leaves_the_vowifi_session_alone,
                           other_auth_request_types_are_rejected]) of
        true ->
            process_flag(trap_exit, true),
            {ok, Sup} = aaa_redis:start_link(),
            ok = wait_for_redis(20),
            flush(),
            {ok, Mgr} = aaa_session_mgr:start_link(),
            [{redis_sup, Sup}, {mgr, Mgr} | Config];
        false ->
            Config
    end.

end_per_testcase(_TC, Config) ->
    case ?config(mgr, Config) of
        undefined -> ok;
        Mgr ->
            flush(),
            catch gen_server:stop(Mgr),
            exit(?config(redis_sup, Config), shutdown),
            timer:sleep(100)
    end,
    ok.

%%====================================================================
%% pure
%%====================================================================

dictionary_is_rfc4072_application_5(_Config) ->
    ?EAP_APP_ID = diameter_gen_eap:id(),
    %% A DER as the access-proxy sends it must decode without errors
    %% under strict M-bit checking.
    #diameter_packet{msg = ['DER' | Avps], errors = []} = recode(der(1, <<2, 1, 0, 4>>)),
    [<<2, 1, 0, 4>>] = wrap(proplists:get_value('EAP-Payload', Avps)),
    ok.

%% RFC 4072 §3.1: the DER MUST contain one EAP-Payload. Without this the
%% AAA would treat a broken request as an EAP-Start.
der_without_eap_payload_is_a_missing_avp(_Config) ->
    Msg = [A || A <- der(1, <<>>), element(1, A) =/= 'EAP-Payload'],
    try recode(Msg) of
        #diameter_packet{errors = Errors} ->
            true = lists:any(fun({5005, _}) -> true; (5005) -> true; (_) -> false end,
                             Errors)
    catch
        %% The encoder already refuses the message.
        _:_ -> ok
    end.

%% ADR-0030: the application authenticates and never authorizes. A
%% DIAMETER_SUCCESS to AUTHORIZE_AUTHENTICATE would be an authorization.
only_authenticate_only_is_accepted(_Config) ->
    ok = aaa_eap_server:check_request([{'Auth-Request-Type', 1}]),
    ok = aaa_eap_server:check_request([{'Auth-Request-Type', [1]}]),
    [{error, 5004, _} = aaa_eap_server:check_request(A)
     || A <- [[{'Auth-Request-Type', 2}], [{'Auth-Request-Type', 3}], []]],
    ok.

%% GSMA TS.43 §2.8.1 Table 7: 1001 and 2001 continue or finish the
%% dialog, 4001/5001/5003 are permanent (HTTP 403), 3001-3010, 5002 and
%% 5004-5017 are temporary (HTTP 503). A code outside the table (the
%% 4181 of the SWm path, KI-204) would leave the relay without a rule.
outcome_codes_are_the_ones_ts43_table7_maps(_Config) ->
    S = #aaa_session{session_id = <<"s">>, imsi = ?IMSI, interface = eap,
                     eap_id = 7, nai = ?NAI, created_ts = 0, updated_ts = 0},
    {continue, #{eap_id := 8}, [{'EAP-Payload', <<"req">>}]} =
        aaa_eap_server:outcome({challenge, <<"req">>, #{eap_id => 8}}, S),
    Permanent = [{failure, <<"notif">>, res_mismatch},
                 {failure, <<"notif">>, bad_at_mac},
                 {failure, <<"notif">>, auth_reject},
                 {error, {client_error, 0}},
                 {error, {swx_mar, {diameter_error, 5001}}},
                 {error, unexpected_eap},
                 {error, eap_decode}],
    [{final, 4001, _} = aaa_eap_server:outcome(R, S) || R <- Permanent],
    Temporary = [{error, {swx_mar, timeout}},
                 {error, {swx_mar, {diameter_error, 3002}}},
                 {error, no_auth_vectors},
                 {error, {resync_failed, timeout}}],
    [{final, 5012, _} = aaa_eap_server:outcome(R, S) || R <- Temporary],
    {final, 5002, _} =
        aaa_eap_server:outcome({error, challenge_without_session_state}, S),
    %% RFC 4187 §6.3.3: EAP-Failure only after a rejection by the peer or
    %% a client error; a wrong RES gets the AKA-Notification.
    {final, 4001, Rej} = aaa_eap_server:outcome({failure, <<"notif">>, auth_reject}, S),
    <<?EAP_CODE_FAILURE, 7, 4:16>> = proplists:get_value('EAP-Payload', Rej),
    {final, 4001, Bad} = aaa_eap_server:outcome({failure, <<"notif">>, res_mismatch}, S),
    <<"notif">> = proplists:get_value('EAP-Payload', Bad),
    ok.

%% RFC 4072 §2.8.1: the relay learns the verified identity from the
%% User-Name of the successful answer. The MSK protects the SWu tunnel
%% on SWm; a client that only authenticates must not get key material.
success_names_the_user_and_carries_no_key(_Config) ->
    S = #aaa_session{session_id = <<"s">>, imsi = ?IMSI, interface = eap,
                     eap_id = 7, nai = ?NAI, created_ts = 0, updated_ts = 0},
    {final, 2001, Extra} =
        aaa_eap_server:outcome({success, <<3, 7, 0, 4>>, <<0:512>>, #{}}, S),
    ?NAI = proplists:get_value('User-Name', Extra),
    undefined = proplists:get_value('EAP-Master-Session-Key', Extra),
    Dea = aaa_eap_server:dea(<<"s">>, 1, 2001, Extra),
    #diameter_packet{msg = ['DEA' | Avps], errors = []} = recode(Dea),
    [?EAP_APP_ID] = wrap(proplists:get_value('Auth-Application-Id', Avps)),
    [1] = wrap(proplists:get_value('Auth-Request-Type', Avps)),
    %% NO_STATE_MAINTAINED: the client sends no STR (RFC 6733 §8.11).
    [1] = wrap(proplists:get_value('Auth-Session-State', Avps)),
    ok.

%% A SWx SAR for a TS.43 authentication would rewrite the HSS's AAA
%% binding of the subscriber's VoWiFi session. The SAR counter is the
%% observable: it rises on SWm (the control) and must not on `eap'.
eap_application_does_not_register_at_the_hss(_Config) ->
    false = aaa_eap_relay:registers_on_success(eap),
    true  = aaa_eap_relay:registers_on_success(swm),
    {S, Response} = challenged_session(<<"sid-sar">>),
    Before = aaa_metrics:get(swx_sar_total),
    {success, <<?EAP_CODE_SUCCESS, _/binary>>, _, _} =
        aaa_eap_relay:process(eap, Response, S),
    Before = aaa_metrics:get(swx_sar_total),
    {success, _, _, _} = aaa_eap_relay:process(swm, Response, S),
    true = aaa_metrics:get(swx_sar_total) =:= Before + 1,
    ok.

%%====================================================================
%% store (Redis)
%%====================================================================

%% The EAP state of a dialog must be invisible to everything that works
%% on sessions (indexes, list_all, clean-up) and must expire quickly.
eap_start_keeps_state_outside_the_session_store(_Config) ->
    Sid = <<"proxy-0;1;1">>,
    {reply, ['DEA' | Avps]} = request(der(1, <<>>, Sid)),
    1001 = proplists:get_value('Result-Code', Avps),
    <<?EAP_CODE_REQUEST, _, _:16, ?EAP_TYPE_IDENTITY>> =
        proplists:get_value('EAP-Payload', Avps),
    {ok, TtlBin} = aaa_redis:q([<<"TTL">>, aaa_eap_server:state_key(Sid)]),
    Ttl = binary_to_integer(TtlBin),
    true = Ttl > 0 andalso Ttl =< 60,
    error = aaa_session_mgr:get_session(Sid),
    [] = aaa_session_mgr:list_all(),
    [] = aaa_session_mgr:sessions_by_interface(swm),
    ok.

%% The core requirement of ADR-0030: a TS.43 authentication of a
%% subscriber with an active VoWiFi session (no APN in the request, the
%% case that supersedes every SWm session on the SWm path, KI-205)
%% leaves that session and the HSS registration untouched.
success_leaves_the_vowifi_session_alone(_Config) ->
    VoWiFi = #aaa_session{session_id = <<"epdg-0;7;7">>, imsi = ?IMSI,
                          interface = swm, apn = <<"ims">>,
                          origin_host = <<"epdg-0.test">>,
                          eap_state = success, created_ts = 0, updated_ts = 0},
    ok = aaa_session_mgr:create_session(VoWiFi),
    Sid = <<"proxy-0;2;2">>,
    {S, Response} = challenged_session(Sid),
    ok = aaa_redis:setex(aaa_eap_server:state_key(Sid), 60,
                         term_to_binary(S, [{compressed, 3}])),
    Sar = aaa_metrics:get(swx_sar_total),
    {reply, ['DEA' | Avps]} = request(der(1, Response, Sid)),
    2001 = proplists:get_value('Result-Code', Avps),
    ?NAI = proplists:get_value('User-Name', Avps),
    undefined = proplists:get_value('EAP-Master-Session-Key', Avps),
    Sar = aaa_metrics:get(swx_sar_total),
    %% The dialog's state is gone, the VoWiFi session is the only one.
    {ok, undefined} = aaa_redis:get(aaa_eap_server:state_key(Sid)),
    [#aaa_session{session_id = <<"epdg-0;7;7">>, apn = <<"ims">>}] =
        aaa_session_mgr:get_sessions_for_imsi(?IMSI),
    [<<"epdg-0;7;7">>] = [X#aaa_session.session_id
                          || X <- aaa_session_mgr:sessions_by_interface(swm)],
    ok.

other_auth_request_types_are_rejected(_Config) ->
    Sid = <<"proxy-0;3;3">>,
    {reply, ['DEA' | Avps]} = request(der(3, <<>>, Sid)),
    5004 = proplists:get_value('Result-Code', Avps),
    3 = proplists:get_value('Auth-Request-Type', Avps),
    {ok, undefined} = aaa_redis:get(aaa_eap_server:state_key(Sid)),
    ok.

%%====================================================================
%% Helpers
%%====================================================================

der(AuthRequestType, Eap) -> der(AuthRequestType, Eap, <<"proxy-0;0;0">>).

der(AuthRequestType, Eap, Sid) ->
    ['DER', {'Session-Id', Sid}, {'Auth-Application-Id', ?EAP_APP_ID},
     {'Origin-Host', <<"proxy-0.test">>}, {'Origin-Realm', <<"test">>},
     {'Destination-Realm', <<"test">>},
     {'Auth-Request-Type', AuthRequestType},
     {'EAP-Payload', Eap}].

request(Msg) ->
    aaa_eap_server:handle_request(#diameter_packet{msg = Msg, errors = []},
                                  aaa_svc, {make_ref(), #diameter_caps{}}).

%% Encode and decode with the EAP dictionary, as the service does.
recode(Msg) ->
    Hdr = #diameter_header{version = 1, hop_by_hop_id = 1, end_to_end_id = 1},
    #diameter_packet{bin = Bin} =
        diameter_codec:encode(diameter_gen_eap,
                              #diameter_packet{header = Hdr, msg = Msg}),
    diameter_codec:decode(diameter_gen_eap,
                          #{decode_format => list, string_decode => false,
                            strict_mbit => true, rfc => 6733, failed_avp => false,
                            app_dictionary => diameter_gen_eap}, Bin).

wrap(L) when is_list(L) -> L;
wrap(V)                 -> [V].

%% A session in the state after an EAP-AKA challenge (RFC 4187) and the
%% peer's correct response to it.
challenged_session(Sid) ->
    Xres = <<1, 2, 3, 4, 5, 6, 7, 8>>,
    #{k_aut := KAut, msk := Msk} =
        aaa_eap_crypto:derive_keys_aka(<<16#11:128>>, <<16#22:128>>, ?NAI),
    S = #aaa_session{session_id = Sid, imsi = ?IMSI, nai = ?NAI,
                     interface = eap, method = aka, eap_id = 5,
                     eap_state = challenge_sent, xres = Xres,
                     k_aut = KAut, msk = Msk,
                     created_ts = 0, updated_ts = 0},
    Unsigned = aaa_eap_codec:encode(
                 #{code => ?EAP_CODE_RESPONSE, id => 5, type => ?EAP_TYPE_AKA,
                   subtype => ?AKA_CHALLENGE,
                   attrs => [{?AT_RES, <<(bit_size(Xres)):16, Xres/binary>>},
                             {?AT_MAC, <<0:16, 0:128>>}]}),
    Mac = aaa_eap_crypto:compute_mac_sha1(KAut, Unsigned),
    {S, aaa_eap_crypto:patch_at_mac(Unsigned, Mac)}.

wait_for_redis(0) -> {error, timeout};
wait_for_redis(N) ->
    case aaa_redis:ping() of
        ok -> ok;
        _  -> timer:sleep(100), wait_for_redis(N - 1)
    end.

flush() ->
    case aaa_redis:q([<<"KEYS">>, <<?TEST_PREFIX/binary, "*">>]) of
        {ok, Keys} when is_list(Keys), Keys =/= [] ->
            _ = aaa_redis:q([<<"DEL">> | Keys]), ok;
        _ -> ok
    end.
