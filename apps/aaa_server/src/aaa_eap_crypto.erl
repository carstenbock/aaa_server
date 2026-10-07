%%%-------------------------------------------------------------------
%%% @doc EAP-AKA' cryptographic primitives per RFC 5448 / TS 33.402.
%%%
%%% Implements:
%%%   * PRF'           — RFC 5448 §3.4 (HMAC-SHA-256 based)
%%%   * MK / MSK / EMSK derivation — RFC 5448 §3.3
%%%   * CK'/IK' derivation from CK/IK — TS 33.402 §6.2 / Annex A
%%%   * AT_MAC compute & verify     — RFC 5448 §3.5
%%%   * AT_RES encoder              — RFC 4187 §10.8
%%%
%%% All values are carried as raw binaries. Identity must be the
%%% NAI actually sent to / received from the peer (permanent, pseudonym
%%% or fast-reauth NAI, in its exact on-the-wire bytes), per RFC 5448
%%% §3.3.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_crypto).

-include("aaa_eap.hrl").

-export([
    ckik_prime/4,
    derive_keys/2, derive_keys/3,
    derive_keys_aka/3,
    compute_mac/2,
    compute_mac_sha1/2,
    verify_mac/3,
    verify_mac_sha1/3,
    patch_at_mac/2,
    %% Exposed for unit tests and other RFC 4187/RFC 5448 consumers.
    fips186_2_prf/2,
    sha1_compress/2,
    selftest/0
]).

%%====================================================================
%% CK'/IK' derivation — TS 33.402 §6.2 / Annex A
%%====================================================================

%% @doc Derive CK'/IK' from CK/IK bound to Access Network Identity and
%% the current (SQN XOR AK). Output is <<CK':16, IK':16>>.
%%
%% S = FC || P0 || L0 || P1 || L1
%%   FC = 0x20
%%   P0 = ANID, L0 = byte_size(ANID)
%%   P1 = SQN_XOR_AK (6 octets), L1 = 0x0006
%% Key = CK || IK
%% Out = HMAC-SHA-256(Key, S)
-spec ckik_prime(binary(), binary(), binary(), binary()) ->
    {CKp :: binary(), IKp :: binary()}.
ckik_prime(CK, IK, Anid, SqnXorAk)
  when byte_size(CK) =:= 16, byte_size(IK) =:= 16,
       byte_size(SqnXorAk) =:= 6 ->
    L0 = byte_size(Anid),
    S  = <<16#20, Anid/binary, L0:16/big, SqnXorAk/binary, 6:16/big>>,
    Out = crypto:mac(hmac, sha256, <<CK/binary, IK/binary>>, S),
    <<CKp:16/binary, IKp:16/binary>> = Out,
    {CKp, IKp}.

%%====================================================================
%% Key hierarchy — RFC 5448 §3.3
%%====================================================================

%% @doc Derive the full EAP-AKA' key schedule from CK'/IK' and the
%% peer identity (NAI). Returns a map with K_encr (16), K_aut (32),
%% K_re (32), MSK (64), EMSK (64).
%%
%% The PRF' key is IK' followed by CK' (RFC 5448 §3.3). It used to be
%% CK'|IK': every key came out different from the peer's, so a conformant
%% UE could not verify AT_MAC of the challenge and no EAP-AKA' attach
%% ever completed.
%%
%% derive_keys/2 takes that key already concatenated, as IK'|CK'.
-spec derive_keys(binary(), binary()) -> map().
derive_keys(IKCKprime, Identity) when byte_size(IKCKprime) =:= 32 ->
    derive_keys_internal(IKCKprime, Identity).

-spec derive_keys(binary(), binary(), binary()) -> map().
derive_keys(CKp, IKp, Identity)
  when byte_size(CKp) =:= 16, byte_size(IKp) =:= 16 ->
    derive_keys_internal(<<IKp/binary, CKp/binary>>, Identity).

derive_keys_internal(Key, Identity) ->
    %% MK = PRF'(IK'|CK', "EAP-AKA'" | Identity)
    S = <<"EAP-AKA'", Identity/binary>>,
    MK = prf_prime(Key, S, 208),
    <<KEncr:16/binary, KAut:32/binary, KRe:32/binary,
      MSK:64/binary, EMSK:64/binary>> = MK,
    #{k_encr => KEncr, k_aut => KAut, k_re => KRe,
      msk => MSK, emsk => EMSK}.

%% PRF' per RFC 5448 §3.4:
%%   T1 = HMAC-SHA-256(K, S | 0x01)
%%   Ti = HMAC-SHA-256(K, T(i-1) | S | i)   for i >= 2
%%   PRF'(K,S) = T1 | T2 | T3 | ...  truncated to Nbytes.
prf_prime(Key, S, Nbytes) ->
    prf_prime(Key, S, Nbytes, 1, <<>>, <<>>).

prf_prime(_Key, _S, Nbytes, _I, _Prev, Acc) when byte_size(Acc) >= Nbytes ->
    <<Out:Nbytes/binary, _/binary>> = Acc,
    Out;
prf_prime(Key, S, Nbytes, I, Prev, Acc) ->
    T = crypto:mac(hmac, sha256, Key, <<Prev/binary, S/binary, I:8>>),
    prf_prime(Key, S, Nbytes, I + 1, T, <<Acc/binary, T/binary>>).

%%====================================================================
%% AT_MAC — RFC 5448 §3.5
%%====================================================================

%% @doc Compute the 16-byte AT_MAC value for the given complete EAP
%% packet. The AT_MAC value field MUST already be present (filled with
%% 16 zero bytes) at the time of the call. The returned MAC is the
%% first 128 bits of HMAC-SHA-256 over the whole packet.
-spec compute_mac(binary(), binary()) -> binary().
compute_mac(KAut, EapPacket) ->
    Full = crypto:mac(hmac, sha256, KAut, EapPacket),
    <<Mac:16/binary, _/binary>> = Full,
    Mac.

%% @doc Patch a 16-byte MAC into the AT_MAC value field of an EAP
%% packet. Returns the updated packet. Searches for an attribute with
%% type AT_MAC (11) and length 5 units (20 bytes total).
-spec patch_at_mac(binary(), binary()) -> binary().
patch_at_mac(EapPacket, Mac) when byte_size(Mac) =:= 16 ->
    <<Hdr:8/binary, Rest/binary>> = EapPacket,
    %% The EAP header is 8 bytes (code/id/len/type/subtype/reserved).
    %% Walk attributes looking for AT_MAC.
    NewRest = patch_attr_mac(Rest, Mac, <<>>),
    <<Hdr/binary, NewRest/binary>>.

patch_attr_mac(<<?AT_MAC, 5, _Reserved:16, _OldMac:16/binary, Rest/binary>>,
               Mac, Acc) ->
    %% Reserved field of AT_MAC MUST be zero (RFC 4187 §10.15).
    <<Acc/binary, ?AT_MAC, 5, 0:16, Mac/binary, Rest/binary>>;
patch_attr_mac(<<Type, LenUnits, Rest/binary>>, Mac, Acc) when LenUnits >= 1 ->
    BodyLen = LenUnits * 4 - 2,
    <<Body:BodyLen/binary, More/binary>> = Rest,
    patch_attr_mac(More, Mac, <<Acc/binary, Type, LenUnits, Body/binary>>);
patch_attr_mac(<<>>, _Mac, Acc) ->
    Acc.

%% @doc Verify AT_MAC in a received EAP packet. Zeros the AT_MAC value
%% field, recomputes the HMAC, and compares to the original.
%% Returns true / false. Uses constant-time compare.
-spec verify_mac(binary(), binary(), binary()) -> boolean().
verify_mac(KAut, EapPacket, ExpectedMac) when byte_size(ExpectedMac) =:= 16 ->
    Zeroed = patch_at_mac(EapPacket, <<0:128>>),
    Computed = compute_mac(KAut, Zeroed),
    crypto:hash_equals(Computed, ExpectedMac);
verify_mac(_, _, _) ->
    false.

%%====================================================================
%% RFC 4187 §7 — EAP-AKA (non-prime) key derivation
%%====================================================================
%%
%% Unlike EAP-AKA' which uses HMAC-SHA-256 throughout, RFC 4187 uses:
%%   MK    = SHA-1(Identity | IK | CK)                [20 bytes]
%%   PRF   = FIPS 186-2 + Change-Notice-1 PRNG seeded with MK
%%   Output = K_encr(16) | K_aut(16) | MSK(64) | EMSK(64) = 160 bytes
%%
%% K_aut is 16 bytes (not 32); AT_MAC is HMAC-SHA-1 truncated to 128 bits.

-spec derive_keys_aka(binary(), binary(), binary()) -> map().
derive_keys_aka(CK, IK, Identity)
  when byte_size(CK) =:= 16, byte_size(IK) =:= 16 ->
    MK = crypto:hash(sha, <<Identity/binary, IK/binary, CK/binary>>),
    Out = fips186_2_prf(MK, 160),
    <<KEncr:16/binary, KAut:16/binary, MSK:64/binary, EMSK:64/binary>> = Out,
    #{k_encr => KEncr, k_aut => KAut, msk => MSK, emsk => EMSK}.

%%====================================================================
%% AT_MAC — RFC 4187 §10.15 (HMAC-SHA-1-128 variant)
%%====================================================================

%% @doc Compute AT_MAC for EAP-AKA (RFC 4187): first 128 bits of
%% HMAC-SHA-1 over the whole packet (with AT_MAC value field zeroed).
-spec compute_mac_sha1(binary(), binary()) -> binary().
compute_mac_sha1(KAut, EapPacket) ->
    Full = crypto:mac(hmac, sha, KAut, EapPacket),
    <<Mac:16/binary, _/binary>> = Full,
    Mac.

-spec verify_mac_sha1(binary(), binary(), binary()) -> boolean().
verify_mac_sha1(KAut, EapPacket, ExpectedMac) when byte_size(ExpectedMac) =:= 16 ->
    Zeroed = patch_at_mac(EapPacket, <<0:128>>),
    Computed = compute_mac_sha1(KAut, Zeroed),
    crypto:hash_equals(Computed, ExpectedMac);
verify_mac_sha1(_, _, _) ->
    false.

%%====================================================================
%% FIPS 186-2 + Change Notice 1 — General Purpose PRNG used as PRF
%% by RFC 4187 §7 (b = 160 bits, XSEED = 0).
%%
%% For each 40-byte output iteration:
%%   w_0  = G(t, XKEY)                    where G is SHA-1 compression
%%   XKEY = (1 + XKEY + w_0)  mod 2^160
%%   w_1  = G(t, XKEY)
%%   XKEY = (1 + XKEY + w_1)  mod 2^160
%% Output block = w_0 || w_1
%%
%% G(t, c) = one SHA-1 compression round on 64-byte block `c'
%%           starting from intermediate state `t' (NO length padding).
%%           `t' is the SHA-1 default IV (H0..H4).
%%====================================================================

-spec fips186_2_prf(binary(), pos_integer()) -> binary().
fips186_2_prf(Seed, Nbytes)
  when is_binary(Seed), byte_size(Seed) =< 64, Nbytes > 0 ->
    SeedPadded = pad_right(Seed, 64),
    %% SHA-1 default IV (FIPS 180-4 §5.3.1).
    T = <<16#67452301:32/big, 16#EFCDAB89:32/big, 16#98BADCFE:32/big,
          16#10325476:32/big, 16#C3D2E1F0:32/big>>,
    fips186_loop(SeedPadded, T, <<>>, Nbytes).

fips186_loop(_XKey, _T, Acc, Nbytes) when byte_size(Acc) >= Nbytes ->
    <<Out:Nbytes/binary, _/binary>> = Acc,
    Out;
fips186_loop(XKey, T, Acc, Nbytes) ->
    W0    = sha1_compress(T, XKey),
    XKey1 = add160_hi(XKey, W0, 1),
    W1    = sha1_compress(T, XKey1),
    XKey2 = add160_hi(XKey1, W1, 1),
    fips186_loop(XKey2, T, <<Acc/binary, W0/binary, W1/binary>>, Nbytes).

%% Add B (20 bytes, big-endian) + Extra to the first 20 bytes of the
%% 64-byte XKey block (mod 2^160); low 44 bytes are preserved.
add160_hi(<<Hi:20/binary, Lo:44/binary>>, B, Extra) ->
    Sum = (binary:decode_unsigned(Hi) + binary:decode_unsigned(B) + Extra)
          band ((1 bsl 160) - 1),
    HiOut = pad_left(binary:encode_unsigned(Sum), 20),
    <<HiOut/binary, Lo/binary>>.

pad_right(B, N) when byte_size(B) =:= N -> B;
pad_right(B, N) when byte_size(B) < N ->
    <<B/binary, 0:((N - byte_size(B)) * 8)>>.

pad_left(B, N) when byte_size(B) =:= N -> B;
pad_left(B, N) when byte_size(B) < N ->
    <<0:((N - byte_size(B)) * 8), B/binary>>;
pad_left(B, N) when byte_size(B) > N ->
    binary:part(B, byte_size(B) - N, N).

%%====================================================================
%% Single-block SHA-1 compression (FIPS 180-4 §6.1.2 / FIPS 186-2
%% App 3.3 G(t,c)).
%%
%% Takes the 20-byte intermediate hash `State' and a 64-byte message
%% `Block' and returns the updated 20-byte hash AFTER processing one
%% block. No length suffix / no padding is applied; this is NOT a full
%% SHA-1 hash. Used exclusively by the FIPS 186-2 PRF above.
%%====================================================================

-spec sha1_compress(binary(), binary()) -> binary().
sha1_compress(<<A0:32/big, B0:32/big, C0:32/big, D0:32/big, E0:32/big>>,
              Block) when byte_size(Block) =:= 64 ->
    Ws = expand_ws(Block),
    {A, B, C, D, E} = sha1_rounds(Ws, A0, B0, C0, D0, E0, 0),
    <<((A0 + A) band 16#FFFFFFFF):32/big,
      ((B0 + B) band 16#FFFFFFFF):32/big,
      ((C0 + C) band 16#FFFFFFFF):32/big,
      ((D0 + D) band 16#FFFFFFFF):32/big,
      ((E0 + E) band 16#FFFFFFFF):32/big>>.

expand_ws(<<W0:32/big, W1:32/big, W2:32/big, W3:32/big,
            W4:32/big, W5:32/big, W6:32/big, W7:32/big,
            W8:32/big, W9:32/big, W10:32/big, W11:32/big,
            W12:32/big, W13:32/big, W14:32/big, W15:32/big>>) ->
    T0 = {W0, W1, W2, W3, W4, W5, W6, W7,
          W8, W9, W10, W11, W12, W13, W14, W15},
    expand_ws_loop(T0, 16).

expand_ws_loop(T, 80) -> T;
expand_ws_loop(T, I) ->
    Wi = rol32(
           element(I - 3 + 1, T) bxor
           element(I - 8 + 1, T) bxor
           element(I - 14 + 1, T) bxor
           element(I - 16 + 1, T),
           1),
    expand_ws_loop(erlang:append_element(T, Wi), I + 1).

sha1_rounds(_Ws, A, B, C, D, E, 80) ->
    {A, B, C, D, E};
sha1_rounds(Ws, A, B, C, D, E, I) ->
    W = element(I + 1, Ws),
    {F, K} = round_fk(I, B, C, D),
    Temp = (rol32(A, 5) + F + E + K + W) band 16#FFFFFFFF,
    sha1_rounds(Ws, Temp, A, rol32(B, 30), C, D, I + 1).

round_fk(I, B, C, D) when I < 20 ->
    NotB = (bnot B) band 16#FFFFFFFF,
    {(B band C) bor (NotB band D), 16#5A827999};
round_fk(I, B, C, D) when I < 40 ->
    {B bxor C bxor D, 16#6ED9EBA1};
round_fk(I, B, C, D) when I < 60 ->
    {(B band C) bor (B band D) bor (C band D), 16#8F1BBCDC};
round_fk(_I, B, C, D) ->
    {B bxor C bxor D, 16#CA62C1D6}.

rol32(X, 0) -> X band 16#FFFFFFFF;
rol32(X, N) when N > 0, N < 32 ->
    M = X band 16#FFFFFFFF,
    ((M bsl N) bor (M bsr (32 - N))) band 16#FFFFFFFF.

%%====================================================================
%% Self-test for sha1_compress / fips186_2_prf.
%%
%% Cross-checks our single-block SHA-1 compression against the OTP
%% crypto NIF by hashing messages that fit in exactly one 512-bit
%% block after standard SHA-1 padding (|M| ≤ 447 bits). For such M:
%%     SHA1(M) == sha1_compress(DEFAULT_IV, sha1_pad(M)).
%% If the compression function is wrong, every UE auth would fail in
%% ways that are hard to localise; this self-test catches it up-front.
%%====================================================================
-spec selftest() -> ok | {error, term()}.
selftest() ->
    Cases = [<<"abc">>,
             <<"">>,
             <<"The quick brown fox jumps over the lazy dog">>],
    try
        lists:foreach(fun selftest_one/1, Cases),
        ok
    catch
        throw:{sha1_mismatch, M, Got, Expected} ->
            {error, {sha1_compress_mismatch, M, Got, Expected}}
    end.

selftest_one(M) ->
    Padded   = sha1_pad_block(M),
    IV       = <<16#67452301:32/big, 16#EFCDAB89:32/big, 16#98BADCFE:32/big,
                 16#10325476:32/big, 16#C3D2E1F0:32/big>>,
    Got      = sha1_compress(IV, Padded),
    Expected = crypto:hash(sha, M),
    case Got =:= Expected of
        true  -> ok;
        false -> throw({sha1_mismatch, M, Got, Expected})
    end.

%% SHA-1 padding for a message that fits in one 512-bit block.
sha1_pad_block(M) when byte_size(M) =< 55 ->
    LenBits = byte_size(M) * 8,
    PadZeros = (55 - byte_size(M)) * 8,
    <<M/binary, 16#80, 0:PadZeros, LenBits:64/big>>.
