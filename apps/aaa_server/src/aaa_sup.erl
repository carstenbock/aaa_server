%%%-------------------------------------------------------------------
%%% @doc 3GPP AAA Server top-level supervisor.
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

        #{id => aaa_swx_client,
          start => {aaa_swx_client, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},

        #{id => aaa_swm_server,
          start => {aaa_swm_server, start_link, []},
          restart => permanent, shutdown => 5000, type => worker},

        #{id => aaa_s6b_server,
          start => {aaa_s6b_server, start_link, []},
          restart => permanent, shutdown => 5000, type => worker}
    ],

    %% STa interface for trusted WLAN (Hotspot 2.0 / Passpoint)
    %% Starts only when AAA_STA_ENABLED=true
    StaChildren = case aaa_config:get(sta_enabled, false) of
        true ->
            [#{id => aaa_sta_server,
               start => {aaa_sta_server, start_link, []},
               restart => permanent, shutdown => 5000, type => worker}];
        _ ->
            []
    end,

    InfraChildren = [
        #{id => aaa_http,
          start => {aaa_http, start_link, []},
          restart => permanent, shutdown => 5000, type => worker}
    ],

    {ok, {SupFlags, CoreChildren ++ StaChildren ++ InfraChildren}}.
