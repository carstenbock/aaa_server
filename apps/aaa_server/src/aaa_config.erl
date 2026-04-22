%%%-------------------------------------------------------------------
%%% @doc AAA Server configuration from environment variables.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_config).

-export([init/0, get/1, get/2]).

-define(APP, aaa_server).

init() ->
    %% Diameter identity
    set_from_env("AAA_ORIGIN_HOST", origin_host, fun hostname_default/0),
    set_from_env("AAA_ORIGIN_REALM", origin_realm, "localdomain"),

    %% SWm server (toward ePDG)
    set_from_env_int("AAA_SWM_PORT", swm_port, 3868),
    set_from_env("AAA_SWM_TRANSPORT", swm_transport, "tcp"),

    %% SWx client (toward HSS via DRA)
    %% DRA_HOSTS takes precedence (comma-separated); falls back to DRA_HOST
    set_dra_hosts(),
    set_from_env_int("DRA_PORT", dra_port, 3868),
    set_from_env("DRA_TRANSPORT", dra_transport, "tcp"),

    %% S6b server (toward PGW)
    set_from_env_int("AAA_S6B_PORT", s6b_port, 3869),
    set_from_env("AAA_S6B_TRANSPORT", s6b_transport, "tcp"),

    %% PLMN
    set_from_env("MCC", mcc, "001"),
    set_from_env("MNC", mnc, "01"),

    %% HTTP API
    set_from_env_int("AAA_API_PORT", api_port, 8080),

    %% STa interface for trusted WLAN (Hotspot 2.0 / Passpoint)
    set_from_env_bool("AAA_STA_ENABLED", sta_enabled, false),
    set_from_env_int("AAA_STA_PORT", sta_port, 3870),
    set_from_env("AAA_STA_TRANSPORT", sta_transport, "tcp"),

    %% RADIUS frontend (optional, for WLAN controllers that do not
    %% speak Diameter STa — Hotspot 2.0 / Passpoint deployments)
    set_from_env_bool("AAA_RADIUS_ENABLED", radius_enabled, false),
    set_from_env_int("AAA_RADIUS_PORT", radius_port, 1812),
    set_from_env("AAA_RADIUS_SECRET", radius_secret, "change-me"),

    %% Session / authorization defaults
    set_from_env_int("AAA_SESSION_TIMEOUT", session_timeout, 3600),

    %% Redis-backed session store (HA across multiple AAA pods).
    %% Host defaults to the in-cluster Redis StatefulSet service
    %% shipped by aaa-server-chart; override with AAA_REDIS_HOST to
    %% point at an external Redis (e.g. managed service).
    set_from_env("AAA_REDIS_HOST", redis_host, "aaa-redis"),
    set_from_env_int("AAA_REDIS_PORT", redis_port, 6379),
    set_from_env_int("AAA_REDIS_DB", redis_db, 0),
    set_from_env("AAA_REDIS_PASSWORD", redis_password, ""),
    set_from_env_int("AAA_REDIS_POOL_SIZE", redis_pool_size, 8),
    set_from_env_int("AAA_REDIS_CONNECT_TIMEOUT", redis_connect_timeout, 5000),
    set_from_env_int("AAA_REDIS_RECONNECT_SLEEP", redis_reconnect_sleep, 500),
    set_from_env("AAA_REDIS_KEY_PREFIX", redis_key_prefix, "aaa:"),

    %% Log level
    set_from_env("AAA_LOG_LEVEL", log_level, "info"),

    ok.

-spec get(atom()) -> term().
get(Key) ->
    application:get_env(?APP, Key, undefined).

-spec get(atom(), term()) -> term().
get(Key, Default) ->
    application:get_env(?APP, Key, Default).

%%====================================================================
%% Internal
%%====================================================================

set_from_env(EnvVar, AppKey, Default) ->
    Value = case os:getenv(EnvVar) of
        false when is_function(Default) -> Default();
        false -> Default;
        Val -> Val
    end,
    application:set_env(?APP, AppKey, Value).

set_from_env_int(EnvVar, AppKey, Default) ->
    Value = case os:getenv(EnvVar) of
        false -> Default;
        Val -> list_to_integer(Val)
    end,
    application:set_env(?APP, AppKey, Value).

set_from_env_bool(EnvVar, AppKey, Default) ->
    Value = case os:getenv(EnvVar) of
        false -> Default;
        "true"  -> true;
        "1"     -> true;
        "yes"   -> true;
        _       -> false
    end,
    application:set_env(?APP, AppKey, Value).

set_dra_hosts() ->
    Hosts = case os:getenv("DRA_HOSTS") of
        false ->
            Single = case os:getenv("DRA_HOST") of
                false -> "dra-diameter";
                V     -> V
            end,
            [Single];
        Csv ->
            [string:trim(H) || H <- string:split(Csv, ",", all),
                                string:trim(H) =/= ""]
    end,
    application:set_env(?APP, dra_hosts, Hosts).

hostname_default() ->
    case os:getenv("HOSTNAME") of
        false -> "aaa.localdomain";
        H ->
            Realm = os:getenv("AAA_ORIGIN_REALM", "localdomain"),
            H ++ "." ++ Realm
    end.
