%%%-------------------------------------------------------------------
%%% @doc CT suite for aaa_eap_codec — exercises encoder / decoder round
%%% trips and the EAP-AKA' message builders per RFC 4187 / RFC 5448.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_codec_SUITE).

-include_lib("common_test/include/ct.hrl").
-include("../include/aaa_eap.hrl").

-export([all/0, groups/0, init_per_suite/1, end_per_suite/1]).
-export([
    identity_request_roundtrip/1,
    success_failure_roundtrip/1,
    aka_challenge_structure/1,
    attribute_padding/1,
    notification_message/1,
    decode_truncated/1
]).

all() ->
    [identity_request_roundtrip,
     success_failure_roundtrip,
     aka_challenge_structure,
     attribute_padding,
     notification_message,
     decode_truncated].

groups() -> [].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

%%====================================================================
%% Tests
%%====================================================================

identity_request_roundtrip(_Config) ->
    Bin = aaa_eap_codec:build_request_identity(42),
    {ok, #{code := ?EAP_CODE_REQUEST, id := 42, type := ?EAP_TYPE_IDENTITY}} =
        aaa_eap_codec:decode(Bin),
    %% Length in wire header must equal byte size.
    <<_Code, _Id, Len:16/big, _/binary>> = Bin,
    Len = byte_size(Bin),
    ok.

success_failure_roundtrip(_Config) ->
    S = aaa_eap_codec:build_success(7),
    F = aaa_eap_codec:build_failure(7),
    {ok, #{code := ?EAP_CODE_SUCCESS, id := 7}} = aaa_eap_codec:decode(S),
    {ok, #{code := ?EAP_CODE_FAILURE, id := 7}} = aaa_eap_codec:decode(F),
    %% Both are exactly 4 bytes on the wire.
    4 = byte_size(S),
    4 = byte_size(F),
    ok.

aka_challenge_structure(_Config) ->
    Rand    = crypto:strong_rand_bytes(16),
    Autn    = crypto:strong_rand_bytes(16),
    KdfIn   = <<"WLAN">>,
    Bin     = aaa_eap_codec:build_aka_prime_challenge(1, Rand, Autn, KdfIn, []),
    {ok, #{code := ?EAP_CODE_REQUEST,
           type := ?EAP_TYPE_AKA_PRIME,
           subtype := ?AKA_CHALLENGE,
           attrs := Attrs}} = aaa_eap_codec:decode(Bin),
    {ok, <<0:16, R/binary>>} = aaa_eap_codec:find_attr(?AT_RAND, Attrs),
    R = Rand,
    {ok, <<0:16, A/binary>>} = aaa_eap_codec:find_attr(?AT_AUTN, Attrs),
    A = Autn,
    {ok, <<KdfId:16/big>>} = aaa_eap_codec:find_attr(?AT_KDF, Attrs),
    KdfId = ?AT_KDF_AKA_PRIME_1,
    {ok, <<KdfLen:16/big, KdfInputBytes/binary>>} =
        aaa_eap_codec:find_attr(?AT_KDF_INPUT, Attrs),
    KdfLen = byte_size(KdfIn),
    <<KdfIn:KdfLen/binary, _/binary>> = KdfInputBytes,
    {ok, <<0:16, _Zeros:16/binary>>} =
        aaa_eap_codec:find_attr(?AT_MAC, Attrs),
    ok.

attribute_padding(_Config) ->
    %% Non-multiple-of-4 value must be padded.
    Attrs = [{?AT_IDENTITY, <<"abc">>}],
    Bin   = aaa_eap_codec:encode_attributes(Attrs),
    0     = byte_size(Bin) rem 4,
    {ok, [{?AT_IDENTITY, Decoded}]} = aaa_eap_codec:decode_attributes(Bin),
    %% Decoded is the 4-octet-aligned full value (including padding).
    <<"abc", _/binary>> = Decoded,
    ok.

notification_message(_Config) ->
    Bin = aaa_eap_codec:build_aka_prime_notification(9, 16384, false),
    {ok, #{type := ?EAP_TYPE_AKA_PRIME,
           subtype := ?AKA_NOTIFICATION,
           attrs := Attrs}} = aaa_eap_codec:decode(Bin),
    {ok, <<16384:16/big>>} = aaa_eap_codec:find_attr(?AT_NOTIFICATION, Attrs),
    ok.

decode_truncated(_Config) ->
    {error, truncated_eap} = aaa_eap_codec:decode(<<1,1>>),
    ok.
