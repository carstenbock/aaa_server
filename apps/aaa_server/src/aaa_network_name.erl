%%%-------------------------------------------------------------------
%%% @doc Access Network Identity (ANID) / Network Name construction
%%% for EAP-AKA' per 3GPP TS 24.302 §8.1.1.2 and §8.1.1.3.
%%%
%%% The Network Name is carried in the AT_KDF_INPUT attribute of the
%%% EAP-AKA' Challenge (RFC 5448 §3.1) and also in SIP-Authorization
%%% of the SWx MAR so that the HSS can derive CK'/IK' bound to this
%%% access network.
%%%
%%% Standard ANIDs (TS 24.302 Annex A):
%%%   WLAN        - Untrusted WLAN (SWu/SWm) and trusted WLAN (STa)
%%%   HRPD        - 3GPP2 HRPD trusted non-3GPP access
%%%   WIMAX       - WiMAX trusted non-3GPP access
%%%   ETHERNET    - Fixed trusted Ethernet access
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_network_name).

-export([
    for_swm/0,
    for_sta/0, for_sta/1,
    for_anid/1, for_anid/2,
    anid_from_rat_type/1
]).

%% @doc Network Name for untrusted non-3GPP access via ePDG (SWm/SWu).
%% Always "WLAN" per TS 24.302 §8.1.1.2.
-spec for_swm() -> binary().
for_swm() ->
    <<"WLAN">>.

%% @doc Network Name for trusted WLAN access (STa).
%% Default "WLAN"; callers may pass a specific AN identity (e.g. the
%% trusted WLAN access network identifier).
-spec for_sta() -> binary().
for_sta() ->
    <<"WLAN">>.

-spec for_sta(binary() | undefined) -> binary().
for_sta(undefined) -> for_sta();
for_sta(<<>>)      -> for_sta();
for_sta(Id)        -> Id.

%% @doc Build Network Name from a generic ANID plus an optional
%% extension (e.g. WLAN access identity). Per TS 24.302 §8.1.1.3.
-spec for_anid(binary()) -> binary().
for_anid(Anid) ->
    Anid.

-spec for_anid(binary(), binary() | undefined) -> binary().
for_anid(Anid, undefined) -> Anid;
for_anid(Anid, <<>>)      -> Anid;
for_anid(Anid, Extension) -> <<Anid/binary, ":", Extension/binary>>.

%% @doc Map Diameter RAT-Type enum to canonical Access Network Identity.
-spec anid_from_rat_type(integer()) -> binary().
anid_from_rat_type(0)    -> <<"WLAN">>;    % WLAN
anid_from_rat_type(2001) -> <<"HRPD">>;    % HRPD
anid_from_rat_type(2003) -> <<"HRPD">>;    % eHRPD
anid_from_rat_type(_)    -> <<"WLAN">>.
