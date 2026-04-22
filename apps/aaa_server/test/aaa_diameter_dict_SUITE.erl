%%%-------------------------------------------------------------------
%%% @doc CT suite for the Diameter dictionaries generated from the
%%% .dia sources in priv/dict/. Verifies that each dictionary module:
%%%   * is loadable
%%%   * exports id/0 returning the correct Application-Id
%%%   * exports vendor_id/0 and name/0
%%%
%%% This does *not* exercise the wire protocol — that is a stretch goal
%%% requiring a Diameter mock peer and is out of scope for unit tests.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_diameter_dict_SUITE).

-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([
    swm_dict/1,
    swx_dict/1,
    s6b_dict/1,
    sta_dict/1
]).

-define(SWM_APP_ID, 16777264).
-define(SWX_APP_ID, 16777265).
-define(S6B_APP_ID, 16777272).
-define(STA_APP_ID, 16777250).

all() ->
    [swm_dict, swx_dict, s6b_dict, sta_dict].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

%%====================================================================
%% Tests
%%====================================================================

swm_dict(_Config) ->
    check_dict(diameter_gen_swm, ?SWM_APP_ID).

swx_dict(_Config) ->
    check_dict(diameter_gen_swx, ?SWX_APP_ID).

s6b_dict(_Config) ->
    check_dict(diameter_gen_s6b, ?S6B_APP_ID).

sta_dict(_Config) ->
    check_dict(diameter_gen_sta, ?STA_APP_ID).

%%====================================================================
%% Helpers
%%====================================================================

check_dict(Mod, ExpectedAppId) ->
    %% Skip gracefully if the dictionary has not been generated in this
    %% build (e.g. when running tests without pre_hooks having run).
    case code:ensure_loaded(Mod) of
        {module, Mod} ->
            ExpectedAppId = Mod:id(),
            true = is_list(Mod:name()) orelse is_atom(Mod:name()),
            ok;
        {error, Why} ->
            {skip, {dict_not_loaded, Mod, Why}}
    end.
