%%%-------------------------------------------------------------------
%%% @doc 3GPP AAA Server application module (TS 29.273).
%%% Interworks ePDG (SWm) ↔ HSS (SWx) and PGW (S6b) ↔ HSS (SWx).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    aaa_config:init(),
    apply_log_level(),
    logger:info("Starting 3GPP AAA Server"),
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
    aaa_metrics:init(),
    aaa_sup:start_link().

stop(_State) ->
    logger:info("Stopping 3GPP AAA Server"),
    ok.

%% Apply the configured primary log level to the Erlang `logger'.
%%
%% The level arrives as a string in `AAA_LOG_LEVEL' (chart value
%% `aaa.erlang.logLevel'). Without this call the BEAM keeps the OTP
%% default primary level `notice', so every per-request SWm/SWx/S6b line
%% (all emitted via `logger:notice/2') reaches the logs. Setting
%% `warning' (or `error') silences that chatter while still surfacing
%% genuine problems. An unrecognised value falls back to `notice' rather
%% than crashing the boot.
apply_log_level() ->
    Level = parse_log_level(aaa_config:get(log_level, "notice")),
    case logger:set_primary_config(level, Level) of
        ok -> ok;
        {error, Reason} ->
            logger:warning("Could not set log level to ~p: ~p", [Level, Reason])
    end,
    Level.

parse_log_level(L) when is_atom(L) -> parse_log_level(atom_to_list(L));
parse_log_level(L) when is_list(L) ->
    case string:lowercase(string:trim(L)) of
        "emergency" -> emergency;
        "alert"     -> alert;
        "critical"  -> critical;
        "error"     -> error;
        "warning"   -> warning;
        "notice"    -> notice;
        "info"      -> info;
        "debug"     -> debug;
        Other ->
            logger:warning("Unknown AAA_LOG_LEVEL ~p, defaulting to notice",
                           [Other]),
            notice
    end.
