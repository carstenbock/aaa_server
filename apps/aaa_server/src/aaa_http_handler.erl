%%%-------------------------------------------------------------------
%%% @doc Cowboy handler for AAA Server HTTP endpoints.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_http_handler).

-export([init/2]).

init(Req, #{action := health} = State) ->
    %% Liveness: process is alive if session manager is responsive.
    Alive = is_session_mgr_alive(),
    {Code, Body} = case Alive of
        true  -> {200, <<"ok">>};
        false -> {503, <<"session manager down">>}
    end,
    Reply = cowboy_req:reply(Code,
        #{<<"content-type">> => <<"text/plain">>},
        Body, Req),
    {ok, Reply, State};

init(Req, #{action := ready} = State) ->
    Checks = readiness_checks(),
    Failed = lists:filtermap(
        fun({_Name, ok}) -> false;
           ({Name, {error, Reason}}) ->
               logger:warning("Readiness: ~p failed: ~p", [Name, Reason]),
               {true, Name}
        end, Checks),
    case Failed of
        [] ->
            Reply = cowboy_req:reply(200,
                #{<<"content-type">> => <<"text/plain">>},
                <<"ready">>, Req),
            {ok, Reply, State};
        _ ->
            Body = iolist_to_binary(io_lib:format("not ready: ~p", [Failed])),
            Reply = cowboy_req:reply(503,
                #{<<"content-type">> => <<"text/plain">>},
                Body, Req),
            {ok, Reply, State}
    end;

init(Req, #{action := metrics} = State) ->
    Body = iolist_to_binary(aaa_metrics:format_prometheus()),
    Reply = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain; version=0.0.4">>},
        Body, Req),
    {ok, Reply, State};

init(Req, #{action := status} = State) ->
    Status = #{
        active_sessions => aaa_session_mgr:count(),
        swm_peers       => aaa_metrics:get(swm_peers),
        swx_peers       => aaa_metrics:get(swx_peers),
        s6b_peers       => aaa_metrics:get(s6b_peers),
        sta_peers       => aaa_metrics:get(sta_peers),
        diameter_service=> diameter_service_info()
    },
    Reply = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>},
        jsx:encode(Status), Req),
    {ok, Reply, State}.

%% =======================================================
%% Internal
%% =======================================================

readiness_checks() ->
    [
        {session_mgr,
            case is_session_mgr_alive() of
                true  -> ok;
                false -> {error, not_alive}
            end},
        {diameter_service,
            case is_diameter_svc_alive() of
                true  -> ok;
                false -> {error, not_alive}
            end},
        {diameter_listeners,
            case diameter_listeners_bound() of
                true  -> ok;
                false -> {error, not_bound}
            end},
        {swx_peer,
            case aaa_metrics:get(swx_peers) of
                N when is_integer(N), N > 0 -> ok;
                _ -> {error, no_peers}
            end}
    ].

is_session_mgr_alive() ->
    case whereis(aaa_session_mgr) of
        undefined -> false;
        Pid when is_pid(Pid) -> is_process_alive(Pid)
    end.

is_diameter_svc_alive() ->
    case whereis(aaa_diameter_svc) of
        undefined -> false;
        Pid when is_pid(Pid) -> is_process_alive(Pid)
    end.

diameter_listeners_bound() ->
    try
        Services = diameter:services(),
        case lists:member(aaa_svc, Services) of
            true ->
                %% Any transport_ref present means at least one listener
                %% was configured; we treat the service being up as
                %% evidence the listeners have been requested. A stricter
                %% check could inspect diameter:service_info/2 for
                %% transport state.
                Info = diameter:service_info(aaa_svc, transport),
                is_list(Info) andalso Info =/= [];
            false ->
                false
        end
    catch
        _:_ -> false
    end.

diameter_service_info() ->
    try
        case lists:member(aaa_svc, diameter:services()) of
            true ->
                Apps = diameter:service_info(aaa_svc, applications),
                #{service => <<"aaa_svc">>,
                  applications => length(Apps)};
            false ->
                #{service => null}
        end
    catch
        _:_ -> #{service => error}
    end.
