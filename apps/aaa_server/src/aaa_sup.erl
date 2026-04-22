%%%-------------------------------------------------------------------
%%% @doc 3GPP AAA Server top-level supervisor.
%%%
%%% The Diameter stack is owned by `aaa_diameter_svc' — a single
%%% `diameter:start_service/2' advertising SWm, SWx, S6b and (optionally)
%%% STa Auth-Application-Ids. Per-interface logic lives in pure
%%% callback modules (aaa_swm_server, aaa_swx_client, aaa_s6b_server,
%%% aaa_sta_server) registered on that service.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 10, period => 60},

    CoreChildren = [
        #{id => aaa_session_mgr,
          start => {aaa_session_mgr, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},

        #{id => aaa_diameter_svc,
          start => {aaa_diameter_svc, start_link, []},
          restart => permanent, shutdown => 10000, type => worker},

        #{id => aaa_http,
          start => {aaa_http, start_link, []},
          restart => permanent, shutdown => 5000, type => worker}
    ],

    RadiusChildren = case aaa_config:get(radius_enabled, false) of
        true ->
            [#{id => aaa_radius,
               start => {aaa_radius, start_link, []},
               restart => permanent, shutdown => 5000, type => worker}];
        _ -> []
    end,

    {ok, {SupFlags, CoreChildren ++ RadiusChildren}}.
