%%%-------------------------------------------------------------------
%%% @doc AAA session record — per 3GPP TS 29.273 §4.
%%% @end
%%%-------------------------------------------------------------------

-ifndef(AAA_SESSION_HRL).
-define(AAA_SESSION_HRL, true).

-record(aaa_session, {
    session_id      :: binary(),               % Diameter Session-Id
    imsi            :: binary(),
    nai             :: binary() | undefined,   % full NAI as seen on wire
    interface       :: swm | sta | s6b,
    origin_host     :: binary() | undefined,   % peer Origin-Host (ePDG/PGW)
    origin_realm    :: binary() | undefined,
    apn             :: binary() | undefined,   % Service-Selection
    rat_type        :: integer() | undefined,
    an_trusted      :: integer() | undefined,
    visited_plmn    :: binary() | undefined,
    %% UE outer (local) IP on SWu as reported by the ePDG in the SWm
    %% UE-Local-IP-Address AVP (TS 29.273 §9.2.3.1.1) — the public/NAT'd
    %% source address the subscriber attached from over untrusted WiFi.
    %% Captured at authentication time; stored as a printable string.
    ue_local_ip     :: binary() | undefined,
    %% EAP state
    eap_id          :: 0..255 | undefined,
    eap_state       :: identity_req | challenge_sent | success | failed | undefined,
    %% EAP peer method per NAI prefix (TS 23.003 §19.3.2, RFC 4187/5448 §4.1.1.6):
    %%   aka       = EAP-AKA  (RFC 4187)  — leading "0"/"2"/"4"
    %%   aka_prime = EAP-AKA' (RFC 5448)  — leading "6"/"7"/"8"
    method          :: aka | aka_prime | undefined,
    rand            :: binary() | undefined,
    autn            :: binary() | undefined,
    xres            :: binary() | undefined,
    ck              :: binary() | undefined,
    ik              :: binary() | undefined,
    network_name    :: binary() | undefined,
    k_encr          :: binary() | undefined,
    k_aut           :: binary() | undefined,
    k_re            :: binary() | undefined,
    msk             :: binary() | undefined,
    emsk            :: binary() | undefined,
    pseudonym       :: binary() | undefined,
    reauth_id       :: binary() | undefined,
    %% Subscription data cached from HSS (SAA)
    non_3gpp_user_data :: list() | undefined,
    apn_configuration  :: list() | undefined,
    ambr_ul         :: non_neg_integer() | undefined,
    ambr_dl         :: non_neg_integer() | undefined,
    %% PGW binding (S6b path)
    pgw_id          :: binary() | undefined,
    %% Lifecycle
    created_ts      :: integer(),
    updated_ts      :: integer(),
    expiry_ts       :: integer() | undefined    % absolute, Session-Timeout
}).

-endif.
