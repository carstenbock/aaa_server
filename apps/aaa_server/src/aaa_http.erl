%%%-------------------------------------------------------------------
%%% @doc HTTP server for health checks and Prometheus metrics.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_http).

-export([start_link/0]).

start_link() ->
    Port = aaa_config:get(api_port, 8080),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/healthz",    aaa_http_handler, #{action => health}},
            {"/readyz",     aaa_http_handler, #{action => ready}},
            {"/metrics",    aaa_http_handler, #{action => metrics}},
            {"/api/status", aaa_http_handler, #{action => status}}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(aaa_http_listener,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}),
    logger:info("AAA HTTP API on port ~p", [Port]),
    ignore.
