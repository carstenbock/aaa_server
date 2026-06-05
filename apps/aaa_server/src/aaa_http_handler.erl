%%%-------------------------------------------------------------------
%%% @doc Cowboy handler for AAA Server HTTP endpoints.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_http_handler).

-include("aaa_session.hrl").

-export([init/2]).

%% Hard cap on the unfiltered listing so a large keyspace can never
%% blow up the response (the IMSI-filtered path is naturally bounded).
-define(SESSION_LIST_LIMIT, 500).

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
    {ok, Reply, State};

init(Req, #{action := sessions} = State) ->
    Qs = cowboy_req:parse_qs(Req),
    Sessions = case lists:keyfind(<<"imsi">>, 1, Qs) of
        {<<"imsi">>, IMSI} when is_binary(IMSI), IMSI =/= <<>> ->
            aaa_session_mgr:get_sessions_for_imsi(IMSI);
        _ ->
            lists:sublist(aaa_session_mgr:list_all(), ?SESSION_LIST_LIMIT)
    end,
    Body = jsx:encode([session_to_map(S) || S <- Sessions]),
    Reply = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>},
        Body, Req),
    {ok, Reply, State}.

%% =======================================================
%% Internal
%% =======================================================

%% Project a session record onto a JSON-friendly map. Deliberately
%% omits EAP keying material (CK/IK/MSK/EMSK/K_*) — this endpoint is for
%% operational visibility, not key escrow.
session_to_map(#aaa_session{} = S) ->
    #{session_id   => nullable(S#aaa_session.session_id),
      imsi         => nullable(S#aaa_session.imsi),
      nai          => nullable(S#aaa_session.nai),
      interface    => nullable(S#aaa_session.interface),
      origin_host  => nullable(S#aaa_session.origin_host),
      origin_realm => nullable(S#aaa_session.origin_realm),
      apn          => nullable(S#aaa_session.apn),
      rat_type     => nullable(S#aaa_session.rat_type),
      visited_plmn => nullable(S#aaa_session.visited_plmn),
      ue_local_ip  => nullable(S#aaa_session.ue_local_ip),
      eap_state    => nullable(S#aaa_session.eap_state),
      method       => nullable(S#aaa_session.method),
      pgw_id       => nullable(S#aaa_session.pgw_id),
      created_ts   => nullable(S#aaa_session.created_ts),
      updated_ts   => nullable(S#aaa_session.updated_ts),
      expiry_ts    => nullable(S#aaa_session.expiry_ts)}.

%% jsx encodes `null' but not `undefined'; atoms become strings.
nullable(undefined)            -> null;
nullable(V) when is_atom(V)    -> atom_to_binary(V, utf8);
nullable(V)                    -> V.

readiness_checks() ->
    [
        {session_mgr,
            case is_session_mgr_alive() of
                true  -> ok;
                false -> {error, not_alive}
            end},
        {redis,
            %% Session state is only durable across pods if Redis is
            %% reachable. Fail readiness if PING fails so K8s stops
            %% routing SWm traffic to this pod and the DRA picks a
            %% healthy peer.
            aaa_redis:ping()},
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
