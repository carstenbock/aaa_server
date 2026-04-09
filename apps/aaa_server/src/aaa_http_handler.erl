%%%-------------------------------------------------------------------
%%% @doc Cowboy handler for AAA Server HTTP endpoints.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_http_handler).

-export([init/2]).

init(Req, #{action := health} = State) ->
    Reply = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        <<"ok">>, Req),
    {ok, Reply, State};

init(Req, #{action := ready} = State) ->
    SwxPeers = aaa_metrics:get(swx_peers),
    {Code, Body} = case SwxPeers > 0 of
        true  -> {200, <<"ready">>};
        false -> {503, <<"not ready: no SWx peers">>}
    end,
    Reply = cowboy_req:reply(Code,
        #{<<"content-type">> => <<"text/plain">>},
        Body, Req),
    {ok, Reply, State};

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
        s6b_peers       => aaa_metrics:get(s6b_peers)
    },
    Reply = cowboy_req:reply(200,
        #{<<"content-type">> => <<"application/json">>},
        jsx:encode(Status), Req),
    {ok, Reply, State}.
