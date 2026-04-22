%%%-------------------------------------------------------------------
%%% @doc Redis connection worker.
%%%
%%% Wraps a single `eredis' connection so the pool can treat each
%%% worker as a serialising dispatcher. Each command goes through a
%%% `gen_server:call/3' so if the underlying TCP socket dies while a
%%% pipeline is in flight we do not leak the caller reference and we
%%% can retry transparently once eredis reconnects.
%%%
%%% Reconnect is delegated to eredis itself (reconnect_sleep /
%%% connect_timeout) — we just propagate the error to the caller when
%%% the socket is down so the upper layer can fail-fast rather than
%%% hang the Diameter stack.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_redis_worker).

-behaviour(gen_server).

-export([start_link/2, stop/1]).
-export([q/2, q/3, qp/2, qp/3, ping/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {
    opts            :: map(),
    conn            :: pid() | undefined,
    last_connect_ts :: integer()
}).

-define(DEFAULT_CALL_TIMEOUT, 5000).

%%====================================================================
%% API
%%====================================================================

start_link(Name, Opts) when is_atom(Name), is_map(Opts) ->
    gen_server:start_link({local, Name}, ?MODULE, Opts, []).

stop(Pid) ->
    gen_server:stop(Pid).

%% @doc Issue a single Redis command. `Cmd' is a list of binaries /
%% iodata understood by `eredis:q/3'.
-spec q(pid() | atom(), [iodata()]) ->
          {ok, binary() | [binary()] | undefined} | {error, term()}.
q(W, Cmd) -> q(W, Cmd, ?DEFAULT_CALL_TIMEOUT).

q(W, Cmd, Timeout) ->
    gen_server:call(W, {q, Cmd, Timeout}, Timeout + 1000).

%% @doc Issue a pipeline of Redis commands. Equivalent to `eredis:qp/3'.
-spec qp(pid() | atom(), [[iodata()]]) ->
          [{ok, term()} | {error, term()}] | {error, term()}.
qp(W, Cmds) -> qp(W, Cmds, ?DEFAULT_CALL_TIMEOUT).

qp(W, Cmds, Timeout) ->
    gen_server:call(W, {qp, Cmds, Timeout}, Timeout + 1000).

-spec ping(pid() | atom()) -> ok | {error, term()}.
ping(W) ->
    case q(W, [<<"PING">>]) of
        {ok, <<"PONG">>} -> ok;
        {ok, Other}      -> {error, {unexpected, Other}};
        {error, R}       -> {error, R}
    end.

%%====================================================================
%% gen_server
%%====================================================================

init(Opts) ->
    process_flag(trap_exit, true),
    self() ! connect,
    {ok, #state{opts = Opts, conn = undefined, last_connect_ts = 0}}.

handle_call(_Req, _From, #state{conn = undefined} = S) ->
    {reply, {error, redis_unavailable}, S};
handle_call({q, Cmd, Timeout}, _From, #state{conn = C} = S) ->
    T0 = erlang:monotonic_time(millisecond),
    Reply = safe_call(fun() -> eredis:q(C, Cmd, Timeout) end),
    T1 = erlang:monotonic_time(millisecond),
    aaa_metrics:observe_latency(redis_latency, T1 - T0),
    bump_metric(Reply),
    {reply, Reply, S};
handle_call({qp, Cmds, Timeout}, _From, #state{conn = C} = S) ->
    T0 = erlang:monotonic_time(millisecond),
    Reply = safe_call(fun() -> eredis:qp(C, Cmds, Timeout) end),
    T1 = erlang:monotonic_time(millisecond),
    aaa_metrics:observe_latency(redis_latency, T1 - T0),
    bump_metric(Reply),
    {reply, Reply, S};
handle_call(_Req, _From, S) ->
    {reply, {error, unknown_call}, S}.

handle_cast(_Msg, S) -> {noreply, S}.

handle_info(connect, #state{opts = Opts} = S0) ->
    Host     = maps:get(host, Opts, "127.0.0.1"),
    Port     = maps:get(port, Opts, 6379),
    Database = maps:get(database, Opts, 0),
    Password = maps:get(password, Opts, ""),
    Timeout  = maps:get(connect_timeout, Opts, 5000),
    ReconnMs = maps:get(reconnect_sleep, Opts, 500),
    StartArgs = [
        {host, Host},
        {port, Port},
        {database, Database},
        {password, Password},
        {connect_timeout, Timeout},
        {reconnect_sleep, ReconnMs}
    ],
    case eredis:start_link(StartArgs) of
        {ok, Pid} ->
            logger:info("aaa_redis: connected to ~s:~B db=~B", [Host, Port, Database]),
            aaa_metrics:inc(redis_connects_total),
            aaa_metrics:gauge_set(redis_connected, 1),
            {noreply, S0#state{conn = Pid,
                               last_connect_ts = erlang:system_time(second)}};
        {error, Reason} ->
            logger:warning("aaa_redis: connect failed host=~s port=~B reason=~p",
                           [Host, Port, Reason]),
            aaa_metrics:inc(redis_connect_errors_total),
            aaa_metrics:gauge_set(redis_connected, 0),
            erlang:send_after(1000, self(), connect),
            {noreply, S0}
    end;
handle_info({'EXIT', Pid, Reason}, #state{conn = Pid} = S) ->
    logger:warning("aaa_redis: connection died reason=~p — reconnecting", [Reason]),
    aaa_metrics:inc(redis_disconnects_total),
    aaa_metrics:gauge_set(redis_connected, 0),
    erlang:send_after(500, self(), connect),
    {noreply, S#state{conn = undefined}};
handle_info(_Info, S) ->
    {noreply, S}.

terminate(_Reason, #state{conn = undefined}) -> ok;
terminate(_Reason, #state{conn = C}) ->
    catch eredis:stop(C),
    ok.

code_change(_OldVsn, S, _Extra) -> {ok, S}.

%%====================================================================
%% Internal
%%====================================================================

safe_call(F) ->
    try
        F()
    catch
        Class:Reason:Stack ->
            logger:warning("aaa_redis: command crashed ~p:~p ~P",
                           [Class, Reason, Stack, 10]),
            {error, {exception, Class, Reason}}
    end.

bump_metric({ok, _})    -> aaa_metrics:inc(redis_ops_total);
bump_metric({error, _}) ->
    aaa_metrics:inc(redis_ops_total),
    aaa_metrics:inc(redis_errors_total);
bump_metric(L) when is_list(L) ->
    %% pipeline result: count one op plus errors
    aaa_metrics:inc(redis_ops_total),
    lists:foreach(fun({error, _}) -> aaa_metrics:inc(redis_errors_total);
                     (_) -> ok end, L);
bump_metric(_) -> ok.
