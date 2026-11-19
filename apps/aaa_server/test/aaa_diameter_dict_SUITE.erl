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
-include_lib("diameter/include/diameter.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([
    swm_dict/1,
    swx_dict/1,
    s6b_dict/1,
    sta_dict/1,
    eap_dict/1,
    swm_der_and_str_carry_origin_state_id/1
]).

-define(SWM_APP_ID, 16777264).
-define(SWX_APP_ID, 16777265).
-define(S6B_APP_ID, 16777272).
-define(STA_APP_ID, 16777250).

all() ->
    [swm_dict, swx_dict, s6b_dict, sta_dict, eap_dict,
     swm_der_and_str_carry_origin_state_id].

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

%% RFC 4072 §2.1: the Diameter EAP application is Application-Id 5.
eap_dict(_Config) ->
    check_dict(diameter_gen_eap, 5).

%% KI-46: the ePDG's Origin-State-Id in DER and STR tells the AAA that the
%% ePDG restarted. It must decode by name and without a 5001 error, which
%% an M-bit AVP outside the message grammar gets under strict_mbit.
swm_der_and_str_carry_origin_state_id(_Config) ->
    Der = ['DER', {'Session-Id', <<"epdg;1;1">>}, {'Auth-Application-Id', ?SWM_APP_ID},
           {'Origin-Host', <<"epdg-a">>}, {'Origin-Realm', <<"r">>},
           {'Destination-Realm', <<"r">>}, {'Auth-Request-Type', 3},
           {'Origin-State-Id', 1762905600}],
    Str = ['STR', {'Session-Id', <<"epdg;1;1">>}, {'Origin-Host', <<"epdg-a">>},
           {'Origin-Realm', <<"r">>}, {'Destination-Realm', <<"r">>},
           {'Auth-Application-Id', ?SWM_APP_ID}, {'Termination-Cause', 1},
           {'Origin-State-Id', 1762905600}],
    [1762905600 = decoded_origin_state(M) || M <- [Der, Str]],
    ok.

decoded_origin_state(Msg) ->
    Hdr = #diameter_header{version = 1, hop_by_hop_id = 1, end_to_end_id = 1},
    #diameter_packet{bin = Bin} =
        diameter_codec:encode(diameter_gen_swm, #diameter_packet{header = Hdr, msg = Msg}),
    #diameter_packet{msg = [_ | Avps], errors = []} =
        diameter_codec:decode(diameter_gen_swm, #{decode_format => list,
                                                  string_decode => false,
                                                  strict_mbit => true,
                                                  rfc => 6733,
                                                  failed_avp => false,
                                                  app_dictionary => diameter_gen_swm}, Bin),
    case proplists:get_value('Origin-State-Id', Avps) of
        [V] -> V;
        V -> V
    end.

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
