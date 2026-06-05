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
            {"/api/status", aaa_http_handler, #{action => status}},
            %% Read-only session query. Optional ?imsi=<imsi> filters by
            %% subscriber; otherwise all active sessions are listed. Used
            %% by the HSS-GUI to surface the UE's outer (local) IP that
            %% the ePDG reported via the SWm UE-Local-IP-Address AVP.
            {"/api/sessions", aaa_http_handler, #{action => sessions}}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(aaa_http_listener,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}),
    logger:info("AAA HTTP API on port ~p", [Port]),
    ignore.
