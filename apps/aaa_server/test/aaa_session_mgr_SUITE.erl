%%%-------------------------------------------------------------------
%%% @doc CT suite for aaa_session_mgr — exercises the dual IMSI ↔
%%% Session-Id index and NAI binding used to correlate HSS-initiated
%%% RTR/PPR (SWx) to active SWm/S6b sessions.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_session_mgr_SUITE).

-include_lib("common_test/include/ct.hrl").
-include("../include/aaa_session.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1,
         init_per_testcase/2, end_per_testcase/2]).
-export([
    create_and_lookup/1,
    dual_index/1,
    multiple_sessions_per_imsi/1,
    nai_binding/1,
    remove_by_imsi/1,
    count_by_interface/1
]).

all() ->
    [create_and_lookup,
     dual_index,
     multiple_sessions_per_imsi,
     nai_binding,
     remove_by_imsi,
     count_by_interface].

init_per_suite(Config) ->
    ok = aaa_metrics:init(),
    Config.
end_per_suite(_Config) -> ok.

init_per_testcase(_TC, Config) ->
    {ok, Pid} = aaa_session_mgr:start_link(),
    [{mgr, Pid} | Config].

end_per_testcase(_TC, Config) ->
    Pid = ?config(mgr, Config),
    case is_process_alive(Pid) of
        true  -> gen_server:stop(Pid);
        false -> ok
    end,
    ok.

%%====================================================================
%% Tests
%%====================================================================

create_and_lookup(_Config) ->
    S = #aaa_session{session_id = <<"sess-1">>, imsi = <<"001010000000001">>,
                     interface = swm, origin_host = <<"epdg.example.com">>},
    ok = aaa_session_mgr:create_session(S),
    {ok, Got} = aaa_session_mgr:get_session(<<"sess-1">>),
    <<"001010000000001">> = Got#aaa_session.imsi,
    swm = Got#aaa_session.interface,
    ok.

dual_index(_Config) ->
    IMSI = <<"001010000000002">>,
    Sid  = <<"sess-2">>,
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = Sid, imsi = IMSI, interface = swm}),
    [Got] = aaa_session_mgr:get_sessions_for_imsi(IMSI),
    Sid  = Got#aaa_session.session_id,
    ok.

multiple_sessions_per_imsi(_Config) ->
    IMSI = <<"001010000000003">>,
    Sid1 = <<"sess-3a">>, Sid2 = <<"sess-3b">>,
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = Sid1, imsi = IMSI, interface = swm}),
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = Sid2, imsi = IMSI, interface = s6b}),
    List = aaa_session_mgr:get_sessions_for_imsi(IMSI),
    2 = length(List),
    ok = aaa_session_mgr:remove_session(Sid1),
    [Remaining] = aaa_session_mgr:get_sessions_for_imsi(IMSI),
    Sid2 = Remaining#aaa_session.session_id,
    ok.

nai_binding(_Config) ->
    NAI  = <<"7pseudo-abc@nai.epc.mnc001.mcc262.3gppnetwork.org">>,
    IMSI = <<"262010000000004">>,
    ok = aaa_session_mgr:bind_nai(NAI, IMSI),
    {ok, IMSI} = aaa_session_mgr:resolve_nai(NAI),
    error = aaa_session_mgr:resolve_nai(<<"no-such-nai">>),
    ok.

remove_by_imsi(_Config) ->
    IMSI = <<"001010000000005">>,
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = <<"x1">>, imsi = IMSI, interface = swm}),
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = <<"x2">>, imsi = IMSI, interface = s6b}),
    ok = aaa_session_mgr:remove_sessions_for_imsi(IMSI),
    [] = aaa_session_mgr:get_sessions_for_imsi(IMSI),
    error = aaa_session_mgr:get_session(<<"x1">>),
    error = aaa_session_mgr:get_session(<<"x2">>),
    ok.

count_by_interface(_Config) ->
    Initial = aaa_session_mgr:count(swm),
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = <<"c1">>, imsi = <<"1">>, interface = swm}),
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = <<"c2">>, imsi = <<"2">>, interface = swm}),
    ok = aaa_session_mgr:create_session(
            #aaa_session{session_id = <<"c3">>, imsi = <<"3">>, interface = s6b}),
    After = aaa_session_mgr:count(swm),
    true = (After - Initial) >= 2,
    ok.
