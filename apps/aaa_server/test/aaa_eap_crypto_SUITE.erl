%%%-------------------------------------------------------------------
%%% @doc CT suite for aaa_eap_crypto.
%%%
%%% Exercises:
%%%   * PRF' / key hierarchy determinism (RFC 5448 §3.3 / §3.4)
%%%   * CK'/IK' derivation from CK/IK (TS 33.402 §6.2 / Annex A)
%%%   * AT_MAC compute / patch / verify round trip (RFC 5448 §3.5)
%%%
%%% Where possible, known-answer vectors from RFC 5448 Appendix C are
%%% used. Otherwise we cross-check via self-consistency: derive keys,
%%% produce MAC, verify MAC.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_crypto_SUITE).

-include_lib("common_test/include/ct.hrl").
-include("../include/aaa_eap.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1]).
-export([
    ckik_prime_output_length/1,
    derive_keys_lengths/1,
    derive_keys_determinism/1,
    derive_keys_rfc5448_case1/1,
    ckik_prime_rfc5448_case1/1,
    prf_prime_known_length/1,
    at_mac_roundtrip/1,
    at_mac_verify_constant_time/1
]).

all() ->
    [ckik_prime_output_length,
     derive_keys_lengths,
     derive_keys_determinism,
     derive_keys_rfc5448_case1,
     ckik_prime_rfc5448_case1,
     prf_prime_known_length,
     at_mac_roundtrip,
     at_mac_verify_constant_time].

init_per_suite(Config) ->
    _ = application:ensure_all_started(crypto),
    Config.
end_per_suite(_Config) ->
    ok.

%%====================================================================
%% Tests
%%====================================================================

ckik_prime_output_length(_Config) ->
    CK   = <<1:128>>,
    IK   = <<2:128>>,
    Anid = <<"WLAN">>,
    Sqa  = <<0, 0, 0, 0, 0, 1>>,
    {CKp, IKp} = aaa_eap_crypto:ckik_prime(CK, IK, Anid, Sqa),
    16 = byte_size(CKp),
    16 = byte_size(IKp),
    %% Same inputs → same outputs.
    {CKp, IKp} = aaa_eap_crypto:ckik_prime(CK, IK, Anid, Sqa),
    %% Different ANID → different output.
    {CKp2, _}   = aaa_eap_crypto:ckik_prime(CK, IK, <<"HRPD">>, Sqa),
    true = (CKp =/= CKp2),
    ok.

derive_keys_lengths(_Config) ->
    CKp  = <<3:128>>,
    IKp  = <<4:128>>,
    Id   = <<"6001010123456789@nai.epc.mnc001.mcc001.3gppnetwork.org">>,
    Keys = aaa_eap_crypto:derive_keys(CKp, IKp, Id),
    #{k_encr := KEncr, k_aut := KAut, k_re := KRe,
      msk    := MSK,   emsk  := EMSK} = Keys,
    16 = byte_size(KEncr),
    32 = byte_size(KAut),
    32 = byte_size(KRe),
    64 = byte_size(MSK),
    64 = byte_size(EMSK),
    ok.

derive_keys_determinism(_Config) ->
    CKp = <<5:128>>,
    IKp = <<6:128>>,
    Id  = <<"alice@example.org">>,
    K1  = aaa_eap_crypto:derive_keys(CKp, IKp, Id),
    %% derive_keys/2 takes the PRF' key itself: IK' | CK' (RFC 5448 §3.3)
    K2  = aaa_eap_crypto:derive_keys(<<IKp/binary, CKp/binary>>, Id),
    K1  = K2,
    %% Changing identity changes all keys.
    K3  = aaa_eap_crypto:derive_keys(CKp, IKp, <<"bob@example.org">>),
    true = (maps:get(msk, K1) =/= maps:get(msk, K3)),
    ok.

%% RFC 5448 Appendix C, Case 1. The UE derives K_aut and the MSK on its own:
%% unless ours are bit-identical it rejects AT_MAC of the challenge (or the
%% ePDG's IKE AUTH payload) and the attach fails. Determinism and length
%% checks cannot see a wrong but self-consistent derivation, such as the
%% CK'|IK' key order this module shipped with.
derive_keys_rfc5448_case1(_Config) ->
    CKp = binary:decode_hex(<<"0093962D0DD84AA5684B045C9EDFFA04">>),
    IKp = binary:decode_hex(<<"CCFC230CA74FCC96C0A5D61164F5A76C">>),
    #{k_encr := KEncr, k_aut := KAut, k_re := KRe, msk := MSK, emsk := EMSK} =
        aaa_eap_crypto:derive_keys(CKp, IKp, <<"0555444333222111">>),
    KEncr = binary:decode_hex(<<"766FA0A6C317174B812D52FBCD11A179">>),
    KAut  = binary:decode_hex(
              <<"0842EA722FF6835BFA2032499FC3EC23C2F0E388B4F07543FFC677F1696D71EA">>),
    KRe   = binary:decode_hex(
              <<"CF83AA8BC7E0ACED892ACC98E76A9B2095B558C7795C7094715CB3393AA7D17A">>),
    MSK   = binary:decode_hex(
              <<"67C42D9AA56C1B79E295E3459FC3D187D42BE0BF818D3070E362C5E967A4D544"
                "E8ECFE19358AB3039AFF03B7C930588C055BABEE58A02650B067EC4E9347C75A">>),
    EMSK  = binary:decode_hex(
              <<"F861703CD775590E16C7679EA3874ADA866311DE290764D760CF76DF647EA01C"
                "313F69924BDD7650CA9BAC141EA075C4EF9E8029C0E290CDBAD5638B63BC23FB">>),
    ok.

%% Same vector, one step earlier: CK'/IK' bind the keys to the access
%% network name ("WLAN"), which is what separates EAP-AKA' from EAP-AKA.
ckik_prime_rfc5448_case1(_Config) ->
    CK = binary:decode_hex(<<"5349FBE098649F948F5D2E973A81C00F">>),
    IK = binary:decode_hex(<<"9744871AD32BF9BBD1DD5CE54E3E2E5A">>),
    <<SqnXorAk:6/binary, _/binary>> =
        binary:decode_hex(<<"BB52E91C747AC3AB2A5C23D15EE351D5">>),
    {CKp, IKp} = aaa_eap_crypto:ckik_prime(CK, IK, <<"WLAN">>, SqnXorAk),
    CKp = binary:decode_hex(<<"0093962D0DD84AA5684B045C9EDFFA04">>),
    IKp = binary:decode_hex(<<"CCFC230CA74FCC96C0A5D61164F5A76C">>),
    ok.

prf_prime_known_length(_Config) ->
    %% PRF' must emit exactly 208 bytes of keying material for
    %% EAP-AKA' (16 + 32 + 32 + 64 + 64 = 208).
    CKp = <<0:128>>,
    IKp = <<0:128>>,
    #{k_encr := KE, k_aut := KA, k_re := KR, msk := MSK, emsk := EMSK} =
        aaa_eap_crypto:derive_keys(CKp, IKp, <<"id">>),
    Total = byte_size(KE) + byte_size(KA) + byte_size(KR)
            + byte_size(MSK) + byte_size(EMSK),
    208 = Total,
    ok.

at_mac_roundtrip(_Config) ->
    KAut = crypto:strong_rand_bytes(32),
    Rand = crypto:strong_rand_bytes(16),
    Autn = crypto:strong_rand_bytes(16),
    Pkt0 = aaa_eap_codec:build_aka_prime_challenge(3, Rand, Autn, <<"WLAN">>, []),
    Mac  = aaa_eap_crypto:compute_mac(KAut, Pkt0),
    16   = byte_size(Mac),
    Pkt1 = aaa_eap_crypto:patch_at_mac(Pkt0, Mac),
    true = aaa_eap_crypto:verify_mac(KAut, Pkt1, Mac),
    ok.

at_mac_verify_constant_time(_Config) ->
    KAut = crypto:strong_rand_bytes(32),
    Rand = crypto:strong_rand_bytes(16),
    Autn = crypto:strong_rand_bytes(16),
    Pkt0 = aaa_eap_codec:build_aka_prime_challenge(1, Rand, Autn, <<"WLAN">>, []),
    Good = aaa_eap_crypto:compute_mac(KAut, Pkt0),
    Bad  = <<0:128>>,
    Pkt1 = aaa_eap_crypto:patch_at_mac(Pkt0, Good),
    true  = aaa_eap_crypto:verify_mac(KAut, Pkt1, Good),
    false = aaa_eap_crypto:verify_mac(KAut, Pkt1, Bad),
    ok.
