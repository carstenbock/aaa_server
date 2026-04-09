%%%-------------------------------------------------------------------
%%% @doc 3GPP AAA Server application module (TS 29.273).
%%% Interworks ePDG (SWm) ↔ HSS (SWx) and PGW (S6b) ↔ HSS (SWx).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    logger:info("Starting 3GPP AAA Server"),
    aaa_config:init(),
    aaa_metrics:init(),
    aaa_sup:start_link().

stop(_State) ->
    logger:info("Stopping 3GPP AAA Server"),
    ok.
