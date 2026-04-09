%%%-------------------------------------------------------------------
%%% @doc AAA session state manager.
%%% Tracks active non-3GPP access sessions (IMSI ↔ ePDG, PGW).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_session_mgr).

-behaviour(gen_server).

-export([start_link/0,
         store_auth_vector/2, get_auth_vector/1,
         authorize_session/2, terminate_session/1,
         handle_deregistration/1, handle_profile_push/2,
         count/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(TAB_AUTH,    aaa_auth_tab).
-define(TAB_SESSION, aaa_session_tab).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

-spec store_auth_vector(binary(), map()) -> ok.
store_auth_vector(IMSI, Vector) ->
    ets:insert(?TAB_AUTH, {IMSI, Vector, erlang:system_time(second)}),
    ok.

-spec get_auth_vector(binary()) -> {ok, map()} | error.
get_auth_vector(IMSI) ->
    case ets:lookup(?TAB_AUTH, IMSI) of
        [{_, Vector, _}] -> {ok, Vector};
        [] -> error
    end.

-spec authorize_session(binary(), binary()) -> ok | {error, term()}.
authorize_session(IMSI, APN) ->
    %% Check subscriber profile from HSS (cached from SAA)
    case ets:lookup(?TAB_SESSION, IMSI) of
        [{_, #{authorized := true}}] ->
            ok;
        _ ->
            %% Fetch from HSS via SWx SAR
            case aaa_swx_client:server_assignment_request(IMSI,
                    #{assignment_type => 7}) of
                {ok, _} ->
                    ets:insert(?TAB_SESSION, {IMSI, #{authorized => true,
                                                       apn => APN,
                                                       ts => erlang:system_time(second)}}),
                    ok;
                {error, R} ->
                    {error, R}
            end
    end.

-spec terminate_session(binary()) -> ok.
terminate_session(SessionId) ->
    logger:info("Session terminated: ~s", [SessionId]),
    ok.

-spec handle_deregistration(binary()) -> ok.
handle_deregistration(IMSI) ->
    ets:delete(?TAB_AUTH, IMSI),
    ets:delete(?TAB_SESSION, IMSI),
    logger:info("Deregistered IMSI ~s (HSS-initiated)", [IMSI]),
    ok.

-spec handle_profile_push(binary(), list()) -> ok.
handle_profile_push(IMSI, _AVPs) ->
    logger:info("Profile push for IMSI ~s", [IMSI]),
    ok.

-spec count() -> non_neg_integer().
count() ->
    ets:info(?TAB_SESSION, size).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    ets:new(?TAB_AUTH,    [named_table, public, set, {write_concurrency, true}]),
    ets:new(?TAB_SESSION, [named_table, public, set, {write_concurrency, true}]),
    erlang:send_after(60000, self(), cleanup),
    {ok, #{}}.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State) -> {noreply, State}.

handle_info(cleanup, State) ->
    %% Expire stale auth vectors older than 5 minutes
    Now = erlang:system_time(second),
    Expired = ets:select(?TAB_AUTH, [{{'$1', '_', '$3'}, [{'<', '$3', Now - 300}], ['$1']}]),
    lists:foreach(fun(K) -> ets:delete(?TAB_AUTH, K) end, Expired),
    erlang:send_after(60000, self(), cleanup),
    {noreply, State};

handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
