%%%-------------------------------------------------------------------
%%% @doc CT suite for aaa_nai — NAI parsing and building per
%%% 3GPP TS 23.003 §19.3 and §14.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_nai_SUITE).

-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([
    parse_eap_aka_prime_permanent/1,
    parse_pseudonym/1,
    parse_fast_reauth/1,
    parse_eap_aka_permanent/1,
    parse_malformed/1,
    build_permanent/1,
    identity_type_table/1
]).

all() ->
    [parse_eap_aka_prime_permanent,
     parse_pseudonym,
     parse_fast_reauth,
     parse_eap_aka_permanent,
     parse_malformed,
     build_permanent,
     identity_type_table].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

%%====================================================================
%% Tests
%%====================================================================

parse_eap_aka_prime_permanent(_Config) ->
    NAI = <<"6001010000000001@nai.epc.mnc001.mcc001.3gppnetwork.org">>,
    {ok, Parsed} = aaa_nai:parse(NAI),
    eap_aka_prime_permanent = maps:get(type, Parsed),
    <<"001010000000001">> = maps:get(imsi, Parsed),
    <<"001">> = maps:get(mcc, Parsed),
    <<"001">> = maps:get(mnc, Parsed),
    ok.

parse_pseudonym(_Config) ->
    NAI = <<"7abcdef12345@nai.epc.mnc01.mcc262.3gppnetwork.org">>,
    {ok, Parsed} = aaa_nai:parse(NAI),
    eap_aka_prime_pseudonym = maps:get(type, Parsed),
    false = maps:is_key(imsi, Parsed),
    <<"262">> = maps:get(mcc, Parsed),
    <<"01">>  = maps:get(mnc, Parsed),
    ok.

parse_fast_reauth(_Config) ->
    NAI = <<"8reauth-0001@nai.epc.mnc01.mcc262.3gppnetwork.org">>,
    {ok, Parsed} = aaa_nai:parse(NAI),
    eap_aka_prime_reauth = maps:get(type, Parsed),
    ok.

parse_eap_aka_permanent(_Config) ->
    NAI = <<"1001010000000002@nai.epc.mnc001.mcc001.3gppnetwork.org">>,
    {ok, Parsed} = aaa_nai:parse(NAI),
    eap_aka_permanent = maps:get(type, Parsed),
    <<"001010000000002">> = maps:get(imsi, Parsed),
    ok.

parse_malformed(_Config) ->
    {error, empty_nai}       = aaa_nai:parse(<<>>),
    {error, empty_username}  = aaa_nai:parse(<<"@realm">>),
    ok.

build_permanent(_Config) ->
    B = aaa_nai:build_permanent(<<"001010123456789">>, <<"001">>, <<"01">>),
    <<"6001010123456789@nai.epc.mnc001.mcc001.3gppnetwork.org">> = B,
    ok.

identity_type_table(_Config) ->
    eap_sim_permanent        = aaa_nai:identity_type($0),
    eap_aka_permanent        = aaa_nai:identity_type($1),
    eap_sim_pseudonym        = aaa_nai:identity_type($2),
    eap_aka_pseudonym        = aaa_nai:identity_type($3),
    eap_sim_reauth           = aaa_nai:identity_type($4),
    eap_aka_reauth           = aaa_nai:identity_type($5),
    eap_aka_prime_permanent  = aaa_nai:identity_type($6),
    eap_aka_prime_pseudonym  = aaa_nai:identity_type($7),
    eap_aka_prime_reauth     = aaa_nai:identity_type($8),
    unknown                  = aaa_nai:identity_type($X),
    ok.
