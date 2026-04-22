%%%-------------------------------------------------------------------
%%% @doc EAP-AKA / EAP-AKA' protocol constants.
%%% RFC 3748 (EAP), RFC 4187 (EAP-AKA), RFC 5448 (EAP-AKA').
%%% @end
%%%-------------------------------------------------------------------

-ifndef(AAA_EAP_HRL).
-define(AAA_EAP_HRL, true).

%% EAP Codes (RFC 3748 §4)
-define(EAP_CODE_REQUEST,  1).
-define(EAP_CODE_RESPONSE, 2).
-define(EAP_CODE_SUCCESS,  3).
-define(EAP_CODE_FAILURE,  4).

%% EAP Type values
-define(EAP_TYPE_IDENTITY,   1).
-define(EAP_TYPE_NOTIFICATION, 2).
-define(EAP_TYPE_NAK,        3).
-define(EAP_TYPE_AKA,       23).  % RFC 4187
-define(EAP_TYPE_AKA_PRIME, 50).  % RFC 5448

%% EAP-AKA/AKA' Subtypes (RFC 4187 §11)
-define(AKA_CHALLENGE,                  1).
-define(AKA_AUTH_REJECT,                2).
-define(AKA_SYNC_FAILURE,               4).
-define(AKA_IDENTITY,                   5).
-define(AKA_NOTIFICATION,              12).
-define(AKA_REAUTH,                    13).
-define(AKA_CLIENT_ERROR,              14).

%% Attribute types (RFC 4187 §10, RFC 5448 §10)
-define(AT_RAND,                        1).
-define(AT_AUTN,                        2).
-define(AT_RES,                         3).
-define(AT_AUTS,                        4).
-define(AT_PADDING,                     6).
-define(AT_NONCE_MT,                    7).
-define(AT_PERMANENT_ID_REQ,           10).
-define(AT_MAC,                        11).
-define(AT_NOTIFICATION,               12).
-define(AT_ANY_ID_REQ,                 13).
-define(AT_IDENTITY,                   14).
-define(AT_VERSION_LIST,               15).
-define(AT_SELECTED_VERSION,           16).
-define(AT_FULLAUTH_ID_REQ,            17).
-define(AT_COUNTER,                    19).
-define(AT_COUNTER_TOO_SMALL,          20).
-define(AT_NONCE_S,                    21).
-define(AT_CLIENT_ERROR_CODE,          22).
-define(AT_KDF_INPUT,                  23).  % AKA' only
-define(AT_KDF,                        24).  % AKA' only
-define(AT_IV,                        129).
-define(AT_ENCR_DATA,                 130).
-define(AT_NEXT_PSEUDONYM,            132).
-define(AT_NEXT_REAUTH_ID,            133).
-define(AT_CHECKCODE,                 134).
-define(AT_RESULT_IND,                135).
-define(AT_BIDDING,                   136).

%% KDF identifiers (RFC 5448 §3.3)
-define(AT_KDF_AKA_PRIME_1,             1).

%% Notification codes (RFC 4187 §6)
-define(EAP_NOTIFY_GENERAL_FAILURE_AFTER,   0).
-define(EAP_NOTIFY_GENERAL_FAILURE_BEFORE, 16384).
-define(EAP_NOTIFY_SUCCESS,             32768).
-define(EAP_NOTIFY_TEMP_DENIED,          1026).
-define(EAP_NOTIFY_NOT_SUBSCRIBED,       1031).

-endif.
