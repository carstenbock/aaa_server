%%%-------------------------------------------------------------------
%%% @doc EAP-AKA / EAP-AKA' authentication engine.
%%%
%%% Drives the EAP state machine between the ePDG/WLAN AN (over SWm/STa
%%% Diameter DER) and the HSS (over SWx MAR/SAR). The peer method is
%%% chosen from the UE-declared NAI leading digit (TS 23.003 §19.3.2,
%%% RFC 4187/5448 §4.1.1.6):
%%%   leading "0"/"2"/"4"   → EAP-AKA   (RFC 4187, type 23)
%%%   leading "6"/"7"/"8"   → EAP-AKA'  (RFC 5448, type 50)
%%%
%%% Implements:
%%%
%%%   identity    — parse NAI and (optionally) send AT_PERMANENT_ID_REQ
%%%   challenge   — send EAP-Req/AKA-Challenge with AT_RAND, AT_AUTN,
%%%                 AT_MAC (EAP-AKA' additionally carries AT_KDF=1 and
%%%                 AT_KDF_INPUT=NetworkName)
%%%   verify      — parse AT_RES + AT_MAC, match against XRES
%%%   success     — issue EAP-Success and deliver MSK via
%%%                 EAP-Master-Session-Key AVP (343)
%%%   sync-fail   — resend MAR with RAND || AUTS via SIP-Authorization
%%%   failure     — issue AKA Notification (code 16384) + EAP-Failure
%%%
%%% The engine is session-scoped: per {Session-Id}. All state lives in
%%% the #aaa_session record managed by aaa_session_mgr.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_relay).

-include("aaa_eap.hrl").
-include("aaa_session.hrl").

-export([
    process/3,
    resolve_identity/1
]).

-type iface() :: swm | sta.
-type process_result() ::
    {challenge, EapPayload :: binary(), Updates :: map()} |
    {success, EapPayload :: binary(), MSK :: binary(), Updates :: map()} |
    {failure, EapPayload :: binary(), Reason :: atom()} |
    {notification, EapPayload :: binary()} |
    {error, atom()}.

%%====================================================================
%% API
%%====================================================================

%% @doc Process an EAP payload arriving in a DER for Session.
%% Returns the next EAP payload to send back in a DEA, along with
%% session updates.
-spec process(iface(), EapPayload :: binary(), #aaa_session{}) ->
    process_result().
process(Iface, EapPayload, S0) when is_binary(EapPayload), byte_size(EapPayload) >= 4 ->
    aaa_metrics:inc(eap_relay_total),
    case aaa_eap_codec:decode(EapPayload) of
        {ok, Pkt}   -> dispatch(Iface, Pkt, EapPayload, S0);
        {error, R}  ->
            logger:warning("EAP decode error: ~p", [R]),
            aaa_metrics:inc(eap_relay_failure_total),
            {error, eap_decode}
    end;
process(_Iface, <<>>, S0) ->
    %% Empty EAP payload — treat as initial contact from ePDG.
    %% Ask the peer for its identity.
    NextId = next_id(S0),
    Req = aaa_eap_codec:build_request_identity(NextId),
    {challenge, Req, #{eap_state => identity_req, eap_id => NextId}};
process(_Iface, _Other, _S0) ->
    {error, invalid_eap}.

%% @doc Resolve an NAI to an IMSI. For permanent NAIs, returns the
%% embedded IMSI. For pseudonym / fast-reauth NAIs, consults the
%% session manager's NAI → IMSI binding.
-spec resolve_identity(binary()) -> {ok, binary()} | error.
resolve_identity(NAI) ->
    case aaa_nai:parse(NAI) of
        {ok, #{type := Type, imsi := IMSI}} when
              Type =:= eap_aka_permanent;
              Type =:= eap_aka_prime_permanent;
              Type =:= eap_sim_permanent ->
            {ok, IMSI};
        {ok, #{type := Type}} when
              Type =:= eap_aka_prime_pseudonym;
              Type =:= eap_aka_prime_reauth;
              Type =:= eap_aka_pseudonym;
              Type =:= eap_aka_reauth ->
            aaa_session_mgr:resolve_nai(NAI);
        _ ->
            error
    end.

%%====================================================================
%% Dispatch
%%====================================================================

%% Identity response from peer — start MAR.
dispatch(Iface, #{code := ?EAP_CODE_RESPONSE, type := ?EAP_TYPE_IDENTITY,
                  data := IdData, id := Id}, _Raw, S0) ->
    NAI = strip_null(IdData),
    %% #region agent log
    Parsed = (catch aaa_nai:parse(NAI)),
    logger:notice("EAP Identity received: nai=~s parsed=~p", [NAI, Parsed]),
    dbg_log(<<"aaa_eap_relay.erl:93">>,
            <<"EAP Identity received">>,
            #{nai => NAI, parsed => Parsed, iface => Iface}, <<"H2">>),
    %% #endregion
    case resolve_identity(NAI) of
        {ok, IMSI} ->
            Method = method_from_nai(NAI),
            %% #region agent log
            dbg_log(<<"aaa_eap_relay.erl:96">>,
                    <<"Identity resolved">>,
                    #{nai => NAI, imsi => IMSI, method => Method}, <<"H2">>),
            %% #endregion
            start_challenge(Iface, Method, IMSI, NAI, Id, S0);
        error ->
            %% Unknown NAI → ask for permanent id. Use AKA' by default;
            %% the peer will NAK-negotiate if it only supports plain AKA.
            Req = aaa_eap_codec:build_aka_prime_identity(
                    Id + 1, at_permanent_id_req, []),
            {challenge, Req,
             #{eap_state => identity_req, eap_id => Id + 1, nai => NAI}}
    end;

%% AKA' Challenge response from peer — verify MAC and RES.
dispatch(_Iface, #{code := ?EAP_CODE_RESPONSE, type := ?EAP_TYPE_AKA_PRIME,
                   subtype := ?AKA_CHALLENGE, attrs := Attrs},
         Raw, #aaa_session{xres = XRES, k_aut = KAut} = S0)
  when is_binary(XRES), is_binary(KAut), byte_size(KAut) > 0 ->
    case verify_challenge_response(aka_prime, Attrs, Raw, XRES, KAut) of
        ok ->
            finalize_success(S0);
        {error, Why} ->
            logger:warning("EAP-AKA' challenge verify failed: ~p", [Why]),
            aaa_metrics:inc(eap_relay_failure_total),
            NotifId = next_id(S0),
            Notif = aaa_eap_codec:build_aka_prime_notification(
                      NotifId, ?EAP_NOTIFY_GENERAL_FAILURE_AFTER, false),
            {failure, Notif, Why}
    end;

%% EAP-AKA (non-prime) Challenge response from peer.
dispatch(_Iface, #{code := ?EAP_CODE_RESPONSE, type := ?EAP_TYPE_AKA,
                   subtype := ?AKA_CHALLENGE, attrs := Attrs},
         Raw, #aaa_session{xres = XRES, k_aut = KAut} = S0)
  when is_binary(XRES), is_binary(KAut), byte_size(KAut) > 0 ->
    case verify_challenge_response(aka, Attrs, Raw, XRES, KAut) of
        ok ->
            finalize_success(S0);
        {error, Why} ->
            logger:warning("EAP-AKA challenge verify failed: ~p", [Why]),
            aaa_metrics:inc(eap_relay_failure_total),
            NotifId = next_id(S0),
            Notif = aaa_eap_codec:build_aka_notification(
                      NotifId, ?EAP_NOTIFY_GENERAL_FAILURE_AFTER, false),
            {failure, Notif, Why}
    end;

%% Synchronization failure — peer returns AT_AUTS (either method).
dispatch(Iface, #{code := ?EAP_CODE_RESPONSE, type := T,
                  subtype := ?AKA_SYNC_FAILURE, attrs := Attrs},
         _Raw, S0)
  when T =:= ?EAP_TYPE_AKA_PRIME; T =:= ?EAP_TYPE_AKA ->
    case aaa_eap_codec:find_attr(?AT_AUTS, Attrs) of
        {ok, Auts} when byte_size(Auts) >= 14 ->
            AutsVal = binary:part(Auts, 0, 14),
            resync(Iface, AutsVal, S0);
        _ ->
            {error, sync_failure_missing_auts}
    end;

%% Authentication rejection from peer (either method).
dispatch(_Iface, #{code := ?EAP_CODE_RESPONSE, type := T,
                   subtype := ?AKA_AUTH_REJECT}, _Raw, S0)
  when T =:= ?EAP_TYPE_AKA_PRIME; T =:= ?EAP_TYPE_AKA ->
    aaa_metrics:inc(eap_relay_failure_total),
    NotifId = 0,
    Notif = case T of
        ?EAP_TYPE_AKA -> aaa_eap_codec:build_aka_notification(
                           NotifId, ?EAP_NOTIFY_GENERAL_FAILURE_BEFORE, false);
        _             -> aaa_eap_codec:build_aka_prime_notification(
                           NotifId, ?EAP_NOTIFY_GENERAL_FAILURE_BEFORE, false)
    end,
    _ = S0,
    {failure, Notif, auth_reject};

%% Client error (either method).
dispatch(_Iface, #{code := ?EAP_CODE_RESPONSE, type := T,
                   subtype := ?AKA_CLIENT_ERROR, attrs := Attrs}, _Raw, _S0)
  when T =:= ?EAP_TYPE_AKA_PRIME; T =:= ?EAP_TYPE_AKA ->
    Code = case aaa_eap_codec:find_attr(?AT_CLIENT_ERROR_CODE, Attrs) of
        {ok, <<C:16/big>>} -> C;
        _                  -> unknown
    end,
    logger:warning("EAP-AKA client error (type ~p): ~p", [T, Code]),
    aaa_metrics:inc(eap_relay_failure_total),
    {error, {client_error, Code}};

%% AKA/AKA' Challenge response arrived but session is missing XRES/KAut.
%% This means either (a) the AAA never saw the EAP-Identity DER for this
%% Session-Id (cross-pod mis-routing, DRA picked a different peer for the
%% challenge round), (b) the session was evicted/expired, or (c) the SWx
%% MAR earlier failed to produce usable CK/IK so start_challenge never
%% stored keys. Return a failure rather than a generic catch-all so the
%% peer gets a deterministic DEA and the operator sees the real cause.
dispatch(_Iface, #{code := ?EAP_CODE_RESPONSE, type := T,
                   subtype := ?AKA_CHALLENGE} = Pkt,
         Raw, S0)
  when T =:= ?EAP_TYPE_AKA; T =:= ?EAP_TYPE_AKA_PRIME ->
    aaa_metrics:inc(eap_relay_failure_total),
    %% #region agent log
    logger:warning("EAP-AKA~s Challenge-Response on session without keys: "
                   "session_id=~s imsi=~p eap_state=~p method=~p "
                   "xres=~p k_aut_len=~p rand_len=~p autn_len=~p "
                   "raw_hex=~s len=~p pkt=~P",
                   [case T of
                        ?EAP_TYPE_AKA_PRIME -> "'";
                        _                   -> ""
                    end,
                    S0#aaa_session.session_id,
                    S0#aaa_session.imsi,
                    S0#aaa_session.eap_state,
                    S0#aaa_session.method,
                    type_tag(S0#aaa_session.xres),
                    bsize(S0#aaa_session.k_aut),
                    bsize(S0#aaa_session.rand),
                    bsize(S0#aaa_session.autn),
                    hex(Raw), byte_size(Raw), Pkt, 12]),
    %% #endregion
    {error, challenge_without_session_state};

dispatch(_Iface, Pkt, Raw, S0) ->
    %% #region agent log
    logger:notice("EAP dispatch unexpected: raw_hex=~s len=~p pkt=~P "
                  "session_id=~s imsi=~p eap_state=~p method=~p "
                  "xres=~p k_aut_len=~p",
                  [hex(Raw), byte_size(Raw), Pkt, 12,
                   S0#aaa_session.session_id,
                   S0#aaa_session.imsi,
                   S0#aaa_session.eap_state,
                   S0#aaa_session.method,
                   type_tag(S0#aaa_session.xres),
                   bsize(S0#aaa_session.k_aut)]),
    %% #endregion
    {error, unexpected_eap}.

%% #region agent log
type_tag(undefined)           -> undefined;
type_tag(B) when is_binary(B) -> {binary, byte_size(B)};
type_tag(Other)               -> {other, Other}.

bsize(undefined)              -> 0;
bsize(B) when is_binary(B)    -> byte_size(B);
bsize(_)                      -> 0.
%% #endregion

%%====================================================================
%% Method selection — TS 23.003 §19.3.2 / RFC 4187/5448 §4.1.1.6
%%====================================================================

%% @doc Choose EAP method from NAI leading digit.  aka  = RFC 4187
%% (type 23), aka_prime = RFC 5448 (type 50). Defaults to aka_prime
%% for unknown/weird NAIs (3GPP Rel-8+ TS 33.402 mandates AKA' for
%% non-3GPP access).
-spec method_from_nai(binary()) -> aka | aka_prime.
method_from_nai(NAI) ->
    case aaa_nai:parse(NAI) of
        {ok, #{type := T}} when T =:= eap_aka_permanent;
                                T =:= eap_aka_pseudonym;
                                T =:= eap_aka_reauth ->
            aka;
        {ok, #{type := T}} when T =:= eap_aka_prime_permanent;
                                T =:= eap_aka_prime_pseudonym;
                                T =:= eap_aka_prime_reauth ->
            aka_prime;
        _ ->
            aka_prime
    end.

%%====================================================================
%% Challenge start: MAR → build Challenge
%%====================================================================

start_challenge(Iface, Method, IMSI, NAI, Id, S0) ->
    NetworkName = network_name(Iface),
    %% #region agent log
    logger:notice("EAP start_challenge: method=~p imsi=~s nai=~s iface=~p "
                  "network_name=~s session_id=~s",
                  [Method, IMSI, NAI, Iface, NetworkName,
                   case S0 of
                       #aaa_session{session_id = Sid} -> Sid;
                       _ -> undefined
                   end]),
    %% #endregion
    %% TS 29.273 §8.1.2.1.1: SWx MAR User-Name carries the EAP NAI (not
    %% a bare IMSI) so that PyHSS (and any conformant HSS) can parse the
    %% RFC 4187/5448 §4.1.1.6 identity-type prefix.
    AuthScheme = case Method of
        aka       -> <<"EAP-AKA">>;
        aka_prime -> <<"EAP-AKA'">>
    end,
    Opts = #{destination_realm => aaa_config:get(origin_realm, "localdomain"),
             rat_type => 0,
             user_name => NAI,
             auth_scheme => AuthScheme},
    case aaa_swx_client:multimedia_auth_request(IMSI, NetworkName, 1, Opts) of
        {ok, #{auth_vectors := [AV | _]}} when is_map(AV) ->
            build_challenge(Method, IMSI, NAI, NetworkName, AV, Id, S0);
        {ok, #{auth_vectors := []}} ->
            aaa_metrics:inc(eap_relay_failure_total),
            {error, no_auth_vectors};
        {error, Reason} ->
            aaa_metrics:inc(eap_relay_failure_total),
            logger:warning("SWx MAR failed for IMSI=~s: ~p", [IMSI, Reason]),
            {error, {swx_mar, Reason}}
    end.

build_challenge(aka_prime, IMSI, NAI, NetworkName, AV, LastId, _S0) ->
    #{rand := Rand, autn := Autn, xres := XRES, ck := CK, ik := IK} = AV,
    %% TS 29.273 §8.2.2.1: HSS returns CK'/IK' already derived for
    %% EAP-AKA' when SIP-Authentication-Scheme="EAP-AKA'" and the
    %% top-level Access-Network-Identifier AVP was supplied. Trust it.
    {CKp, IKp} = {CK, IK},
    Keys = aaa_eap_crypto:derive_keys(CKp, IKp, NAI),
    #{k_aut := KAut, msk := MSK, emsk := EMSK,
      k_encr := KEncr, k_re := KRe} = Keys,
    NextId = (LastId + 1) band 16#ff,
    Packet0 = aaa_eap_codec:build_aka_prime_challenge(
                NextId, Rand, Autn, NetworkName, []),
    Mac = aaa_eap_crypto:compute_mac(KAut, Packet0),
    Packet = aaa_eap_crypto:patch_at_mac(Packet0, Mac),
    %% #region agent log
    logger:notice("EAP-AKA' Challenge built: len=~p type=~p pkt_hex=~s "
                  "rand_len=~p autn_len=~p kaut_len=~p netname=~s",
                  [byte_size(Packet),
                   case Packet of <<_:32, T, _/binary>> -> T; _ -> undefined end,
                   hex(Packet), byte_size(Rand), byte_size(Autn),
                   byte_size(KAut), NetworkName]),
    %% #endregion
    Updates = #{eap_state => challenge_sent,
                eap_id => NextId,
                method => aka_prime,
                imsi => IMSI,
                nai => NAI,
                rand => Rand, autn => Autn,
                xres => XRES,
                ck => CKp, ik => IKp,
                network_name => NetworkName,
                k_aut => KAut, k_encr => KEncr, k_re => KRe,
                msk => MSK, emsk => EMSK},
    {challenge, Packet, Updates};

build_challenge(aka, IMSI, NAI, NetworkName, AV, LastId, _S0) ->
    #{rand := Rand, autn := Autn, xres := XRES, ck := CK, ik := IK} = AV,
    %% RFC 4187 §7:
    %%   MK = SHA1(Identity | IK | CK)
    %%   FIPS186-2 PRF(MK) = K_encr(16)|K_aut(16)|MSK(64)|EMSK(64)
    Keys = aaa_eap_crypto:derive_keys_aka(CK, IK, NAI),
    #{k_aut := KAut, msk := MSK, emsk := EMSK, k_encr := KEncr} = Keys,
    NextId = (LastId + 1) band 16#ff,
    Packet0 = aaa_eap_codec:build_aka_challenge(NextId, Rand, Autn, []),
    Mac = aaa_eap_crypto:compute_mac_sha1(KAut, Packet0),
    Packet = aaa_eap_crypto:patch_at_mac(Packet0, Mac),
    %% #region agent log
    logger:notice("EAP-AKA Challenge built: len=~p type=~p pkt_hex=~s "
                  "rand_len=~p autn_len=~p kaut_len=~p",
                  [byte_size(Packet),
                   case Packet of <<_:32, T, _/binary>> -> T; _ -> undefined end,
                   hex(Packet), byte_size(Rand), byte_size(Autn),
                   byte_size(KAut)]),
    %% #endregion
    Updates = #{eap_state => challenge_sent,
                eap_id => NextId,
                method => aka,
                imsi => IMSI,
                nai => NAI,
                rand => Rand, autn => Autn,
                xres => XRES,
                ck => CK, ik => IK,
                network_name => NetworkName,
                k_aut => KAut, k_encr => KEncr,
                msk => MSK, emsk => EMSK},
    {challenge, Packet, Updates}.

%%====================================================================
%% Challenge verification
%%====================================================================

verify_challenge_response(Method, Attrs, Raw, XRES, KAut) ->
    case aaa_eap_codec:find_attr(?AT_MAC, Attrs) of
        {ok, <<_Reserved:16, Mac:16/binary>>} ->
            MacOk = case Method of
                aka       -> aaa_eap_crypto:verify_mac_sha1(KAut, Raw, Mac);
                aka_prime -> aaa_eap_crypto:verify_mac(KAut, Raw, Mac)
            end,
            case MacOk of
                true  -> verify_res(Attrs, XRES);
                false -> {error, bad_at_mac}
            end;
        _ ->
            {error, missing_at_mac}
    end.

verify_res(Attrs, XRES) ->
    case aaa_eap_codec:find_attr(?AT_RES, Attrs) of
        {ok, <<LenBits:16/big, Rest/binary>>} ->
            LenBytes = (LenBits + 7) div 8,
            case Rest of
                <<RES:LenBytes/binary, _Pad/binary>> when RES =:= XRES ->
                    ok;
                _ ->
                    {error, res_mismatch}
            end;
        _ ->
            {error, missing_at_res}
    end.

%%====================================================================
%% Resync on AT_AUTS
%%====================================================================

resync(Iface, Auts, #aaa_session{imsi = IMSI, rand = Rand, nai = NAI,
                                  method = Method0}) ->
    NetworkName = network_name(Iface),
    Method = case Method0 of
        undefined -> method_from_nai(NAI);
        M         -> M
    end,
    AuthScheme = case Method of
        aka       -> <<"EAP-AKA">>;
        aka_prime -> <<"EAP-AKA'">>
    end,
    Opts = #{destination_realm => aaa_config:get(origin_realm, "localdomain"),
             rat_type => 0,
             rand => Rand, auts => Auts,
             user_name => NAI,
             auth_scheme => AuthScheme},
    case aaa_swx_client:multimedia_auth_request(IMSI, NetworkName, 1, Opts) of
        {ok, #{auth_vectors := [AV | _]}} ->
            build_challenge(Method, IMSI, NAI, NetworkName, AV, 0, undefined);
        {error, Reason} ->
            {error, {resync_failed, Reason}}
    end.

%%====================================================================
%% Success / MSK delivery
%%====================================================================

finalize_success(#aaa_session{imsi = IMSI, msk = MSK, eap_id = Id, nai = NAI}) ->
    aaa_metrics:inc(eap_relay_success_total),
    SuccessPkt = aaa_eap_codec:build_success(Id),
    %% Issue SAR (REGISTRATION) to HSS so it records our AAA identity.
    %% Same User-Name (NAI) as the preceding MAR — TS 29.273 §8.1.2.2.1.
    SarOpts = case NAI of
                  N when is_binary(N), byte_size(N) > 0 -> #{user_name => N};
                  _ -> #{}
              end,
    _ = aaa_swx_client:server_assignment_request(IMSI, 1, undefined, SarOpts),
    {success, SuccessPkt, MSK, #{eap_state => success}}.

%%====================================================================
%% Helpers
%%====================================================================

network_name(swm) -> aaa_network_name:for_swm();
network_name(sta) -> aaa_network_name:for_sta().

next_id(#aaa_session{eap_id = undefined}) -> rand:uniform(256) - 1;
next_id(#aaa_session{eap_id = I})          -> (I + 1) band 16#ff;
next_id(_) -> 0.

strip_null(Bin) when is_binary(Bin) ->
    case binary:last(Bin) of
        0 -> binary:part(Bin, 0, byte_size(Bin) - 1);
        _ -> Bin
    end;
strip_null(Other) -> iolist_to_binary(Other).

%% #region agent log
hex(Bin) when is_binary(Bin) ->
    << <<(nybble(N))>> || <<N:4>> <= Bin >>;
hex(_) -> <<"">>.
nybble(N) when N < 10 -> $0 + N;
nybble(N)             -> $a + (N - 10).

dbg_log(Location, Message, Data, HypId) ->
    try
        Path = <<"/home/carsten/Schreibtisch/volte.io/helm/.cursor/debug-35d02f.log">>,
        Ts   = erlang:system_time(millisecond),
        Rec  = #{sessionId    => <<"35d02f">>,
                 hypothesisId => HypId,
                 timestamp    => Ts,
                 location     => Location,
                 message      => Message,
                 data         => sanitize(Data)},
        Line = [jsx:encode(Rec), $\n],
        _ = file:write_file(Path, Line, [append]),
        ok
    catch _:_ -> ok end.

sanitize(M) when is_map(M) ->
    maps:map(fun(_, V) -> to_json(V) end, M);
sanitize(V) -> to_json(V).

to_json(B) when is_binary(B)  -> B;
to_json(A) when is_atom(A)    -> atom_to_binary(A, utf8);
to_json(I) when is_integer(I) -> I;
to_json(L) when is_list(L) ->
    try iolist_to_binary(L)
    catch _:_ -> unicode:characters_to_binary(io_lib:format("~p", [L])) end;
to_json(T) ->
    unicode:characters_to_binary(io_lib:format("~p", [T])).
%% #endregion
