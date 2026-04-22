%%%-------------------------------------------------------------------
%%% @doc EAP-AKA / EAP-AKA' packet encoder / decoder.
%%% RFC 3748 §4 (EAP header), RFC 4187 §8 (EAP-AKA), RFC 5448 §10
%%% (EAP-AKA' attributes). All TLVs are 4-byte aligned. Attribute
%%% `Length' is expressed in units of 4 octets (so L=5 means 20 bytes
%%% on the wire including type + length fields).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_eap_codec).

-include("aaa_eap.hrl").

-export([
    %% EAP packet
    decode/1, encode/1,
    %% Helpers to build common EAP messages
    build_request_identity/1,
    build_success/1, build_failure/1,
    build_aka_prime_challenge/5, build_aka_prime_challenge/6,
    build_aka_prime_notification/3,
    build_aka_prime_identity/3,
    %% RFC 4187 (non-prime) variants
    build_aka_challenge/4,
    build_aka_notification/3,
    build_aka_identity/3,
    %% Attribute list helpers
    decode_attributes/1, encode_attributes/1,
    find_attr/2
]).

-export_type([eap_packet/0, eap_attr/0]).

-type subtype()   :: ?AKA_CHALLENGE | ?AKA_AUTH_REJECT |
                     ?AKA_SYNC_FAILURE | ?AKA_IDENTITY |
                     ?AKA_NOTIFICATION | ?AKA_REAUTH | ?AKA_CLIENT_ERROR.
-type eap_type()  :: ?EAP_TYPE_IDENTITY | ?EAP_TYPE_AKA | ?EAP_TYPE_AKA_PRIME |
                     ?EAP_TYPE_NOTIFICATION | ?EAP_TYPE_NAK | integer().
-type eap_attr()  :: {integer(), binary()}.
-type eap_packet() :: #{
    code      := ?EAP_CODE_REQUEST | ?EAP_CODE_RESPONSE |
                 ?EAP_CODE_SUCCESS | ?EAP_CODE_FAILURE,
    id        := 0..255,
    type      => eap_type(),
    subtype   => subtype(),
    attrs     => [eap_attr()],
    data      => binary()
}.

%%====================================================================
%% EAP packet coder
%%====================================================================

-spec decode(binary()) -> {ok, eap_packet()} | {error, term()}.
decode(<<Code, Id, Len:16/big, Rest/binary>> = Full)
  when byte_size(Full) >= Len ->
    PayloadLen = Len - 4,
    case Rest of
        <<_/binary>> when PayloadLen =:= 0 ->
            {ok, #{code => Code, id => Id, data => <<>>}};
        <<Payload:PayloadLen/binary, _/binary>> ->
            decode_payload(Code, Id, Payload)
    end;
decode(_) ->
    {error, truncated_eap}.

decode_payload(Code, Id, <<>>) when Code =:= ?EAP_CODE_SUCCESS;
                                    Code =:= ?EAP_CODE_FAILURE ->
    {ok, #{code => Code, id => Id, data => <<>>}};
decode_payload(Code, Id, <<Type, Body/binary>>)
  when Type =:= ?EAP_TYPE_AKA;
       Type =:= ?EAP_TYPE_AKA_PRIME ->
    case Body of
        <<Subtype, _Reserved:16, AttrBin/binary>> ->
            case decode_attributes(AttrBin) of
                {ok, Attrs} ->
                    {ok, #{code => Code, id => Id, type => Type,
                           subtype => Subtype, attrs => Attrs}};
                {error, _} = E ->
                    E
            end;
        _ ->
            {error, truncated_aka_header}
    end;
decode_payload(Code, Id, <<Type, Rest/binary>>) ->
    %% Non-AKA EAP types (Identity, Notification, NAK) — keep raw.
    {ok, #{code => Code, id => Id, type => Type, data => Rest}}.

-spec encode(eap_packet()) -> binary().
encode(#{code := Code, id := Id} = Pkt) ->
    Body = encode_body(Pkt),
    Len  = 4 + byte_size(Body),
    <<Code, Id, Len:16/big, Body/binary>>.

encode_body(#{code := C}) when C =:= ?EAP_CODE_SUCCESS;
                               C =:= ?EAP_CODE_FAILURE ->
    <<>>;
encode_body(#{type := Type, subtype := Subtype, attrs := Attrs})
  when Type =:= ?EAP_TYPE_AKA; Type =:= ?EAP_TYPE_AKA_PRIME ->
    Encoded = encode_attributes(Attrs),
    <<Type, Subtype, 0:16, Encoded/binary>>;
encode_body(#{type := Type, data := D}) ->
    <<Type, D/binary>>;
encode_body(_) ->
    <<>>.

%%====================================================================
%% Attribute coder
%%====================================================================

-spec decode_attributes(binary()) -> {ok, [eap_attr()]} | {error, term()}.
decode_attributes(Bin) ->
    decode_attributes(Bin, []).

decode_attributes(<<>>, Acc) ->
    {ok, lists:reverse(Acc)};
decode_attributes(<<Type, LenUnits, Rest/binary>>, Acc) when LenUnits >= 1 ->
    ByteLen = LenUnits * 4,
    BodyLen = ByteLen - 2,
    case Rest of
        <<Body:BodyLen/binary, More/binary>> ->
            decode_attributes(More, [{Type, Body} | Acc]);
        _ ->
            {error, {truncated_attr, Type, LenUnits}}
    end;
decode_attributes(<<Type, 0, _/binary>>, _) ->
    {error, {zero_length_attr, Type}};
decode_attributes(<<_/binary>>, _) ->
    {error, truncated_attr_header}.

-spec encode_attributes([eap_attr()]) -> binary().
encode_attributes(Attrs) ->
    << <<(encode_attr(T, V))/binary>> || {T, V} <- Attrs >>.

encode_attr(Type, Value) ->
    Bin   = iolist_to_binary(Value),
    %% Total including Type(1) + Length(1) + Value padded to mod 4.
    TotalUnpadded = 2 + byte_size(Bin),
    Pad = case TotalUnpadded rem 4 of 0 -> 0; R -> 4 - R end,
    Total = TotalUnpadded + Pad,
    LenUnits = Total div 4,
    PadBin = <<0:(Pad*8)>>,
    <<Type, LenUnits, Bin/binary, PadBin/binary>>.

%%====================================================================
%% Attribute lookup
%%====================================================================

-spec find_attr(integer(), [eap_attr()]) -> {ok, binary()} | error.
find_attr(Type, Attrs) ->
    case lists:keyfind(Type, 1, Attrs) of
        {Type, V} -> {ok, V};
        false     -> error
    end.

%%====================================================================
%% Message builders
%%====================================================================

-spec build_request_identity(0..255) -> binary().
build_request_identity(Id) ->
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_IDENTITY, data => <<>>}).

-spec build_success(0..255) -> binary().
build_success(Id) ->
    encode(#{code => ?EAP_CODE_SUCCESS, id => Id}).

-spec build_failure(0..255) -> binary().
build_failure(Id) ->
    encode(#{code => ?EAP_CODE_FAILURE, id => Id}).

%% @doc Build an EAP-AKA' Challenge (RFC 5448 §3.1).
%% The AT_MAC is appended with a placeholder of 16 zero bytes; the
%% caller must then compute the HMAC-SHA-256-128 over the full packet
%% (with the AT_MAC value field zeroed) and patch it into place.
build_aka_prime_challenge(Id, Rand, Autn, KdfInput, Extras) ->
    build_aka_prime_challenge(Id, Rand, Autn, KdfInput, ?AT_KDF_AKA_PRIME_1, Extras).

build_aka_prime_challenge(Id, Rand, Autn, KdfInput, KdfId, Extras)
  when byte_size(Rand) =:= 16, byte_size(Autn) =:= 16 ->
    AtRand     = {?AT_RAND,      <<0:16, Rand/binary>>},
    AtAutn     = {?AT_AUTN,      <<0:16, Autn/binary>>},
    AtKdf      = {?AT_KDF,       <<KdfId:16/big>>},
    %% AT_KDF_INPUT: 2-byte actual length + value, padded.
    KdfLen     = byte_size(KdfInput),
    AtKdfInput = {?AT_KDF_INPUT, <<KdfLen:16/big, KdfInput/binary>>},
    AtMacPlace = {?AT_MAC,       <<0:16, 0:128>>},
    AllAttrs   = [AtKdf, AtKdfInput, AtRand, AtAutn] ++ Extras ++ [AtMacPlace],
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA_PRIME, subtype => ?AKA_CHALLENGE,
             attrs => AllAttrs}).

%% @doc Build an EAP-AKA' Notification request (RFC 4187 §6).
%% NotificationCode: 16384 = General failure after auth; 0 = general failure
%% before auth; 32768 = success; 1026/1031 = denied/not subscribed.
build_aka_prime_notification(Id, NotificationCode, IncludeMacPlaceholder) ->
    AtNot = {?AT_NOTIFICATION, <<NotificationCode:16/big>>},
    Base  = [AtNot],
    Attrs = case IncludeMacPlaceholder of
        true  -> Base ++ [{?AT_MAC, <<0:16, 0:128>>}];
        false -> Base
    end,
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA_PRIME, subtype => ?AKA_NOTIFICATION,
             attrs => Attrs}).

%% @doc Build an EAP-AKA' Identity request (RFC 4187 §4.1.2).
%% IdReqType: at_permanent_id_req | at_any_id_req | at_fullauth_id_req.
build_aka_prime_identity(Id, IdReqType, Extras) ->
    AtReq = id_req_attr(IdReqType),
    Attrs = [AtReq | Extras],
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA_PRIME, subtype => ?AKA_IDENTITY,
             attrs => Attrs}).

id_req_attr(at_permanent_id_req) -> {?AT_PERMANENT_ID_REQ, <<0:16>>};
id_req_attr(at_fullauth_id_req)  -> {?AT_FULLAUTH_ID_REQ,  <<0:16>>};
id_req_attr(at_any_id_req)       -> {?AT_ANY_ID_REQ,       <<0:16>>}.

%%====================================================================
%% EAP-AKA (RFC 4187) message builders — no AT_KDF / AT_KDF_INPUT,
%% EAP Type = 23 instead of 50.
%%====================================================================

%% @doc Build an EAP-AKA Challenge (RFC 4187 §9.2). The AT_MAC value
%% is filled with 16 zero bytes; the caller MUST compute
%% HMAC-SHA-1-128 over the complete packet and patch it with
%% aaa_eap_crypto:compute_mac_sha1/2 + patch_at_mac/2.
-spec build_aka_challenge(0..255, binary(), binary(), [eap_attr()]) -> binary().
build_aka_challenge(Id, Rand, Autn, Extras)
  when byte_size(Rand) =:= 16, byte_size(Autn) =:= 16 ->
    AtRand     = {?AT_RAND, <<0:16, Rand/binary>>},
    AtAutn     = {?AT_AUTN, <<0:16, Autn/binary>>},
    AtMacPlace = {?AT_MAC,  <<0:16, 0:128>>},
    AllAttrs   = [AtRand, AtAutn] ++ Extras ++ [AtMacPlace],
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA, subtype => ?AKA_CHALLENGE,
             attrs => AllAttrs}).

%% @doc Build an EAP-AKA Identity request (RFC 4187 §4.1.2).
build_aka_identity(Id, IdReqType, Extras) ->
    AtReq = id_req_attr(IdReqType),
    Attrs = [AtReq | Extras],
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA, subtype => ?AKA_IDENTITY,
             attrs => Attrs}).

%% @doc Build an EAP-AKA Notification (RFC 4187 §9.10).
build_aka_notification(Id, NotificationCode, IncludeMacPlaceholder) ->
    AtNot = {?AT_NOTIFICATION, <<NotificationCode:16/big>>},
    Base  = [AtNot],
    Attrs = case IncludeMacPlaceholder of
        true  -> Base ++ [{?AT_MAC, <<0:16, 0:128>>}];
        false -> Base
    end,
    encode(#{code => ?EAP_CODE_REQUEST, id => Id,
             type => ?EAP_TYPE_AKA, subtype => ?AKA_NOTIFICATION,
             attrs => Attrs}).
