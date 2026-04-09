%%%-------------------------------------------------------------------
%%% @doc Prometheus-style metrics for AAA Server.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_metrics).

-export([init/0, inc/1, inc/2,
         gauge_inc/1, gauge_dec/1, gauge_set/2,
         observe_latency/2,
         get/1, format_prometheus/0]).

-define(TAB, aaa_metrics_tab).

init() ->
    case ets:info(?TAB) of
        undefined -> ets:new(?TAB, [named_table, public, set, {write_concurrency, true}]);
        _ -> ok
    end,
    lists:foreach(fun(K) -> ets:insert_new(?TAB, {K, 0}) end, [
        swm_requests_total,
        swm_auth_success_total,
        swm_auth_failure_total,
        swm_latency_ms_sum,
        swm_latency_ms_count,
        swm_peers,
        swx_mar_total,
        swx_sar_total,
        swx_errors_total,
        swx_latency_ms_sum,
        swx_latency_ms_count,
        swx_peers,
        s6b_requests_total,
        s6b_auth_success_total,
        s6b_auth_failure_total,
        s6b_latency_ms_sum,
        s6b_latency_ms_count,
        s6b_peers,
        active_sessions,
        eap_relay_total,
        eap_relay_success_total,
        eap_relay_failure_total
    ]),
    ok.

-spec inc(atom()) -> ok.
inc(Key) -> inc(Key, 1).

-spec inc(atom(), integer()) -> ok.
inc(Key, N) ->
    try ets:update_counter(?TAB, Key, N)
    catch error:badarg -> ets:insert(?TAB, {Key, N})
    end, ok.

-spec gauge_inc(atom()) -> ok.
gauge_inc(Key) -> inc(Key, 1).

-spec gauge_dec(atom()) -> ok.
gauge_dec(Key) ->
    try ets:update_counter(?TAB, Key, -1) catch error:badarg -> ok end, ok.

-spec gauge_set(atom(), integer()) -> ok.
gauge_set(Key, Val) -> ets:insert(?TAB, {Key, Val}), ok.

-spec get(atom()) -> integer().
get(Key) ->
    case ets:lookup(?TAB, Key) of [{_, V}] -> V; [] -> 0 end.

-spec observe_latency(atom(), non_neg_integer()) -> ok.
observe_latency(Prefix, DurationMs) ->
    inc(list_to_atom(atom_to_list(Prefix) ++ "_ms_sum"), DurationMs),
    inc(list_to_atom(atom_to_list(Prefix) ++ "_ms_count")),
    ok.

-spec format_prometheus() -> iolist().
format_prometheus() ->
    [io_lib:format("aaa_~s ~B\n", [K, V]) || {K, V} <- lists:sort(ets:tab2list(?TAB))].
