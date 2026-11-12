%%%-------------------------------------------------------------------
%%% @doc Audit of old SWm sessions (KI-46).
%%%
%%% A SWm session ends at the AAA only when the ePDG's STR arrives. An STR
%%% lost in an overload, or the sessions of an ePDG that crashed before it
%%% sent its Origin-State-Id (ePDG < 0.0.107), stay in the store for the
%%% established lifetime of 7 days. Every interval one AAA pod (Redis lock)
%%% asks the ePDG about each established SWm session not touched for
%%% `swm_audit_age' seconds, with a SWm RAR (AUTHORIZE_ONLY), paced at
%%% ?RATE per second. A 5002 answer ends the session as an STR would; a
%%% 2001 refreshes it, so a live session is asked again one age later.
%%% See aaa_swm_server:audit_session/1.
%%%
%%% AAA_SWM_AUDIT_AGE_SEC (default 21600, 0 = off) and
%%% AAA_SWM_AUDIT_INTERVAL_SEC (default 600).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_swm_audit).

-behaviour(gen_server).

-include("aaa_session.hrl").

-export([start_link/0, run_once/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% RARs per second. The HSS is not involved for a live session; a removed
%% one costs at most one SWx SAR.
-define(RATE, 20).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    case age() of
        0 ->
            ignore;
        _ ->
            erlang:send_after(interval() * 1000, self(), audit),
            {ok, #{}}
    end.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State)        -> {noreply, State}.

handle_info(audit, State) ->
    try
        run_once()
    catch
        Class:Reason:Stack ->
            logger:warning("SWm audit failed ~p:~p ~P",
                           [Class, Reason, Stack, 10])
    end,
    erlang:send_after(interval() * 1000, self(), audit),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%% @doc One audit pass, if this pod wins the lock. A pass sends at most as
%% many RARs as fit into one interval at ?RATE, so passes do not overlap.
-spec run_once() -> {ok, map()} | skipped.
run_once() ->
    Interval = interval(),
    case claim_lock(Interval) of
        false ->
            skipped;
        true ->
            Cutoff = erlang:system_time(second) - age(),
            Max = max(1, (Interval - 30) * ?RATE),
            Due = aaa_session_mgr:swm_sessions_due(Cutoff, Max),
            Counts = lists:foldl(fun audit_one/2,
                                 #{alive => 0, removed => 0, unknown => 0}, Due),
            case Due of
                [] -> ok;
                _  -> logger:notice("SWm audit: ~B session(s) older than ~B s "
                                    "asked: ~p", [length(Due), age(), Counts])
            end,
            {ok, Counts}
    end.

audit_one(#aaa_session{} = S, Acc) ->
    Outcome = aaa_swm_server:audit_session(S),
    aaa_metrics:inc(swm_audit_metric(Outcome)),
    timer:sleep(1000 div ?RATE),
    maps:update_with(Outcome, fun(N) -> N + 1 end, Acc).

swm_audit_metric(alive)   -> swm_audit_alive_total;
swm_audit_metric(removed) -> swm_audit_removed_total;
swm_audit_metric(unknown) -> swm_audit_unknown_total.

%% SET NX: one pod per interval. A failed Redis call counts as not
%% claimed, so no pod audits while the store is in trouble.
claim_lock(Interval) ->
    Key = aaa_redis:key([<<"swm_audit:lock">>]),
    Ttl = max(1, Interval - 5),
    case aaa_redis:q([<<"SET">>, Key, atom_to_binary(node(), utf8),
                      <<"NX">>, <<"EX">>, integer_to_binary(Ttl)]) of
        {ok, <<"OK">>} -> true;
        _              -> false
    end.

age() ->
    case aaa_config:get(swm_audit_age, 21600) of
        N when is_integer(N), N > 0 -> N;
        _                           -> 0
    end.

interval() ->
    case aaa_config:get(swm_audit_interval, 600) of
        N when is_integer(N), N >= 60 -> N;
        _                             -> 600
    end.
