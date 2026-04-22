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
    %% #region agent log
    %% Validate the pure-Erlang SHA-1 compression / FIPS 186-2 PRF
    %% implementation on startup so a broken build surfaces immediately
    %% (instead of appearing later as a silent EAP-AKA key-derivation
    %% bug that would manifest as AT_MAC mismatch).
    case aaa_eap_crypto:selftest() of
        ok ->
            logger:notice("aaa_eap_crypto selftest: ok");
        {error, Reason} ->
            logger:error("aaa_eap_crypto selftest FAILED: ~p", [Reason])
    end,
    %% #endregion
    aaa_config:init(),
    aaa_metrics:init(),
    aaa_sup:start_link().

stop(_State) ->
    logger:info("Stopping 3GPP AAA Server"),
    ok.
