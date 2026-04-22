%%%-------------------------------------------------------------------
%%% @doc Network Access Identifier (NAI) parser per 3GPP TS 23.003 §19.3
%%% and §14 (pseudonym / re-authentication formats).
%%%
%%% Leading digit encoding per TS 23.003 Table 19.3.2-1 and
%%% RFC 4187 §4.1.1.6 / RFC 5448 §4.1.1.6:
%%%   "0" = EAP-AKA  permanent identity (IMSI)       — RFC 4187
%%%   "1" = EAP-SIM  permanent identity (IMSI, deprecated)
%%%   "2" = EAP-AKA  pseudonym
%%%   "3" = EAP-SIM  pseudonym (deprecated)
%%%   "4" = EAP-AKA  fast re-authentication identity
%%%   "5" = EAP-SIM  fast re-authentication identity (deprecated)
%%%   "6" = EAP-AKA' permanent identity (IMSI)       — RFC 5448
%%%   "7" = EAP-AKA' pseudonym
%%%   "8" = EAP-AKA' fast re-authentication identity
%%%
%%% See TS 23.003 Table 19.3.2-1 (Leading digit → Identity type).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_nai).

-export([
    parse/1,
    build_permanent/3, build_permanent/4,
    build_pseudonym/3,
    build_fast_reauth/3,
    imsi_to_nai/3, imsi_to_nai/4,
    identity_type/1
]).

-type identity_type() :: eap_sim_permanent | eap_sim_pseudonym | eap_sim_reauth
                       | eap_aka_permanent | eap_aka_pseudonym | eap_aka_reauth
                       | eap_aka_prime_permanent | eap_aka_prime_pseudonym
                       | eap_aka_prime_reauth
                       | unknown.

-type parsed_nai() :: #{
    type      := identity_type(),
    leading   := char(),           % leading digit as char
    username  := binary(),         % raw opaque or IMSI digits without prefix
    imsi      => binary(),         % only present when type is permanent
    mcc       => binary(),
    mnc       => binary(),
    realm     => binary()
}.

-define(REALM_TEMPLATE, "wlan.mnc~s.mcc~s.3gppnetwork.org").

%%====================================================================
%% Parser
%%====================================================================

-spec parse(binary() | string()) -> {ok, parsed_nai()} | {error, term()}.
parse(Bin) when is_binary(Bin) ->
    parse_str(binary_to_list(Bin));
parse(Str) when is_list(Str) ->
    parse_str(Str).

parse_str([]) ->
    {error, empty_nai};
parse_str(Str) ->
    case string:split(Str, "@") of
        [User, Realm] ->
            parse_user(User, list_to_binary(Realm));
        [User] ->
            parse_user(User, <<>>);
        _ ->
            {error, malformed_nai}
    end.

parse_user([Lead | Rest], Realm) ->
    Type = identity_type(Lead),
    Base = #{type => Type, leading => Lead,
             username => list_to_binary(Rest),
             realm => Realm},
    WithPlmn = parse_realm(Base, Realm),
    case is_permanent(Type) of
        true ->
            {ok, WithPlmn#{imsi => list_to_binary(Rest)}};
        false ->
            {ok, WithPlmn}
    end;
parse_user([], _Realm) ->
    {error, empty_username}.

-spec identity_type(char()) -> identity_type().
identity_type($0) -> eap_aka_permanent;
identity_type($1) -> eap_sim_permanent;
identity_type($2) -> eap_aka_pseudonym;
identity_type($3) -> eap_sim_pseudonym;
identity_type($4) -> eap_aka_reauth;
identity_type($5) -> eap_sim_reauth;
identity_type($6) -> eap_aka_prime_permanent;
identity_type($7) -> eap_aka_prime_pseudonym;
identity_type($8) -> eap_aka_prime_reauth;
identity_type(_)  -> unknown.

is_permanent(eap_sim_permanent)       -> true;
is_permanent(eap_aka_permanent)       -> true;
is_permanent(eap_aka_prime_permanent) -> true;
is_permanent(_)                       -> false.

%%====================================================================
%% Extract MCC / MNC from realm (TS 23.003 §19.2)
%%====================================================================

parse_realm(Base, <<>>) -> Base;
parse_realm(Base, Realm) ->
    case re:run(Realm, "mnc(?<mnc>[0-9]{2,3})\\.mcc(?<mcc>[0-9]{3})",
                [{capture, [mnc, mcc], binary}]) of
        {match, [Mnc, Mcc]} ->
            Base#{mnc => Mnc, mcc => Mcc};
        _ ->
            Base
    end.

%%====================================================================
%% Builders
%%====================================================================

%% @doc Build permanent NAI "0<IMSI>@nai.epc.mnc<MNC>.mcc<MCC>.3gppnetwork.org"
%% (EAP-AKA) — Prefix controls which identity type (see identity_type/1).
-spec build_permanent(char(), binary(), binary(), binary()) -> binary().
build_permanent(Prefix, IMSI, MCC, MNC) ->
    iolist_to_binary(io_lib:format("~c~s@nai.epc.mnc~s.mcc~s.3gppnetwork.org",
                                   [Prefix, IMSI, pad_mnc(MNC), MCC])).

%% @doc Build permanent EAP-AKA' NAI (leading 6) per TS 23.003 §19.3.2.
-spec build_permanent(binary(), binary(), binary()) -> binary().
build_permanent(IMSI, MCC, MNC) ->
    build_permanent($6, IMSI, MCC, MNC).

-spec build_pseudonym(binary(), binary(), binary()) -> binary().
build_pseudonym(Opaque, MCC, MNC) ->
    iolist_to_binary(io_lib:format("7~s@nai.epc.mnc~s.mcc~s.3gppnetwork.org",
                                   [Opaque, pad_mnc(MNC), MCC])).

-spec build_fast_reauth(binary(), binary(), binary()) -> binary().
build_fast_reauth(Opaque, MCC, MNC) ->
    iolist_to_binary(io_lib:format("8~s@nai.epc.mnc~s.mcc~s.3gppnetwork.org",
                                   [Opaque, pad_mnc(MNC), MCC])).

%% @doc IMSI → generic wlan NAI (used by opensips/ePDG path).
-spec imsi_to_nai(binary(), binary(), binary()) -> binary().
imsi_to_nai(IMSI, MCC, MNC) ->
    imsi_to_nai(IMSI, MCC, MNC, $6).

-spec imsi_to_nai(binary(), binary(), binary(), char()) -> binary().
imsi_to_nai(IMSI, MCC, MNC, LeadingDigit) ->
    build_permanent(LeadingDigit, IMSI, MCC, MNC).

pad_mnc(<<A, B>>)          -> <<$0, A, B>>;
pad_mnc(<<A, B, C>>)       -> <<A, B, C>>;
pad_mnc(Bin) when is_binary(Bin) -> pad_mnc_list(binary_to_list(Bin));
pad_mnc(Str) when is_list(Str)   -> pad_mnc_list(Str).

pad_mnc_list([A, B])       -> list_to_binary([$0, A, B]);
pad_mnc_list([A, B, C])    -> list_to_binary([A, B, C]);
pad_mnc_list(Str)          -> list_to_binary(Str).
