%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

-hrl_name('diameter_gen_swx.hrl').


%%% -------------------------------------------------------
%%% Message records:
%%% -------------------------------------------------------

-record(diameter_swx_MAR,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'User-Name',
         'SIP-Auth-Data-Item',
         'SIP-Number-Auth-Items',
         'Destination-Host' = [],
         '3GPP-AAA-Server-Name' = [],
         'RAT-Type' = [],
         'AN-Trusted' = [],
         'Access-Network-Identifier' = [],
         'Terminal-Information' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_swx_MAA,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Result-Code' = [],
         'Experimental-Result' = [],
         'User-Name' = [],
         'SIP-Number-Auth-Items' = [],
         'SIP-Auth-Data-Item' = [],
         '3GPP-AAA-Server-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_swx_SAR,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'User-Name',
         'Server-Assignment-Type',
         'Destination-Host' = [],
         '3GPP-AAA-Server-Name' = [],
         'Service-Selection' = [],
         'Context-Identifier' = [],
         'RAT-Type' = [],
         'Visited-Network-Identifier' = [],
         'Terminal-Information' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_swx_SAA,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Result-Code' = [],
         'Experimental-Result' = [],
         'User-Name' = [],
         'User-Data' = [],
         'Non-3GPP-User-Data' = [],
         '3GPP-AAA-Server-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_swx_RTR,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Host',
         'Destination-Realm',
         'User-Name',
         'Deregistration-Reason',
         'Service-Selection' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_swx_RTA,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Result-Code' = [],
         'Experimental-Result' = [],
         'User-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_swx_PPR,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Host',
         'Destination-Realm',
         'User-Name',
         'User-Data' = [],
         'Non-3GPP-User-Data' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_swx_PPA,
        {'Session-Id',
         'Vendor-Specific-Application-Id',
         'Auth-Session-State',
         'Origin-Host',
         'Origin-Realm',
         'Result-Code' = [],
         'Experimental-Result' = [],
         'User-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records:
%%% -------------------------------------------------------

-record('diameter_swx_SIP-Auth-Data-Item',
        {'SIP-Item-Number' = [],
         'SIP-Authentication-Scheme' = [],
         'SIP-Authenticate' = [],
         'SIP-Authorization' = [],
         'SIP-Authentication-Context' = [],
         'Confidentiality-Key' = [],
         'Integrity-Key' = [],
         'AVP' = []}).

-record('diameter_swx_Deregistration-Reason',
        {'Reason-Code', 'Reason-Info' = []}).

-record('diameter_swx_APN-Configuration',
        {'Context-Identifier',
         'PDN-Type',
         'Service-Selection',
         'AMBR' = [],
         'Served-Party-IP-Address' = [],
         'AVP' = []}).

-record(diameter_swx_AMBR,
        {'Max-Requested-Bandwidth-UL',
         'Max-Requested-Bandwidth-DL'}).

-record('diameter_swx_Non-3GPP-User-Data',
        {'Non-3GPP-IP-Access' = [],
         'Non-3GPP-IP-Access-APN' = [],
         'RAT-Type' = [],
         'Session-Timeout' = [],
         'AMBR' = [],
         'APN-Configuration' = [],
         'AVP' = []}).

-record('diameter_swx_Terminal-Information',
        {'IMEI' = [], 'Software-Version' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-record('diameter_swx_Proxy-Info',
        {'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_swx_Failed-AVP', {'AVP' = []}).

-record('diameter_swx_Experimental-Result',
        {'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_swx_Vendor-Specific-Application-Id',
        {'Vendor-Id',
         'Auth-Application-Id' = [],
         'Acct-Application-Id' = []}).


%%% -------------------------------------------------------
%%% ENUM Macros:
%%% -------------------------------------------------------

-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_NO_ASSIGNMENT', 0).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_REGISTRATION', 1).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_RE_REGISTRATION', 2).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_UNREGISTERED_USER', 3).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_TIMEOUT_DEREGISTRATION', 4).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_USER_DEREGISTRATION', 5).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_TIMEOUT_DEREGISTRATION_STORE_SERVER_NAME', 6).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_USER_DEREGISTRATION_STORE_SERVER_NAME', 7).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_ADMINISTRATIVE_DEREGISTRATION', 8).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_AUTHENTICATION_FAILURE', 9).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_AUTHENTICATION_TIMEOUT', 10).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_DEREGISTRATION_TOO_MUCH_DATA', 11).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_AAA_USER_DATA_REQUEST', 12).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_PGW_UPDATE', 13).
-define('DIAMETER_SWX_SERVER-ASSIGNMENT-TYPE_RESTORATION', 14).
-define('DIAMETER_SWX_REASON-CODE_PERMANENT_TERMINATION', 0).
-define('DIAMETER_SWX_REASON-CODE_NEW_SERVER_ASSIGNED', 1).
-define('DIAMETER_SWX_REASON-CODE_SERVER_CHANGE', 2).
-define('DIAMETER_SWX_REASON-CODE_REMOVE_S_CSCF', 3).
-define('DIAMETER_SWX_RAT-TYPE_WLAN', 0).
-define('DIAMETER_SWX_RAT-TYPE_VIRTUAL', 1).
-define('DIAMETER_SWX_RAT-TYPE_UTRAN', 1000).
-define('DIAMETER_SWX_RAT-TYPE_GERAN', 1001).
-define('DIAMETER_SWX_RAT-TYPE_EUTRAN', 1004).
-define('DIAMETER_SWX_RAT-TYPE_HRPD', 2001).
-define('DIAMETER_SWX_RAT-TYPE_EHRPD', 2003).
-define('DIAMETER_SWX_AN-TRUSTED_TRUSTED', 0).
-define('DIAMETER_SWX_AN-TRUSTED_UNTRUSTED', 1).
-define('DIAMETER_SWX_NON-3GPP-IP-ACCESS_NON_3GPP_SUBSCRIPTION_ALLOWED', 0).
-define('DIAMETER_SWX_NON-3GPP-IP-ACCESS_NON_3GPP_SUBSCRIPTION_BARRED', 1).
-define('DIAMETER_SWX_NON-3GPP-IP-ACCESS-APN_NON_3GPP_APNS_ENABLE', 0).
-define('DIAMETER_SWX_NON-3GPP-IP-ACCESS-APN_NON_3GPP_APNS_DISABLE', 1).
-define('DIAMETER_SWX_PDN-TYPE_IPV4', 0).
-define('DIAMETER_SWX_PDN-TYPE_IPV6', 1).
-define('DIAMETER_SWX_PDN-TYPE_IPV4V6', 2).
-define('DIAMETER_SWX_PDN-TYPE_IPV4_OR_IPV6', 3).
-define('DIAMETER_SWX_PDN-TYPE_NON_IP', 4).



%%% -------------------------------------------------------
%%% DEFINE Macros:
%%% -------------------------------------------------------

-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_USER_UNKNOWN', 5001).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_IDENTITIES_DONT_MATCH', 5002).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_IDENTITY_NOT_REGISTERED', 5003).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_ROAMING_NOT_ALLOWED', 5004).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_IDENTITY_ALREADY_REGISTERED', 5005).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_AUTH_SCHEME_NOT_SUPPORTED', 5006).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_AUTHENTICATION_DATA_UNAVAILABLE', 4181).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_USER_NO_NON_3GPP_SUBSCRIPTION', 5450).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_USER_NO_APN_SUBSCRIPTION', 5451).
-define('DIAMETER_SWX_RESULT-CODE_DIAMETER_ERROR_RAT_TYPE_NOT_ALLOWED', 5452).



%%% -------------------------------------------------------
%%% ENUM Macros from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-ifndef('DIAMETER_SWX_DISCONNECT-CAUSE_REBOOTING').
-define('DIAMETER_SWX_DISCONNECT-CAUSE_REBOOTING', 0).
-endif.
-ifndef('DIAMETER_SWX_DISCONNECT-CAUSE_BUSY').
-define('DIAMETER_SWX_DISCONNECT-CAUSE_BUSY', 1).
-endif.
-ifndef('DIAMETER_SWX_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU').
-define('DIAMETER_SWX_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU', 2).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_DONT_CACHE').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_DONT_CACHE', 0).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_SESSION').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_SESSION', 1).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_REALM').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_REALM', 2).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION', 3).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_APPLICATION').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_APPLICATION', 4).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_HOST').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_HOST', 5).
-endif.
-ifndef('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_USER').
-define('DIAMETER_SWX_REDIRECT-HOST-USAGE_ALL_USER', 6).
-endif.
-ifndef('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY').
-define('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY', 1).
-endif.
-ifndef('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 2).
-endif.
-ifndef('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_SWX_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 3).
-endif.
-ifndef('DIAMETER_SWX_AUTH-SESSION-STATE_STATE_MAINTAINED').
-define('DIAMETER_SWX_AUTH-SESSION-STATE_STATE_MAINTAINED', 0).
-endif.
-ifndef('DIAMETER_SWX_AUTH-SESSION-STATE_NO_STATE_MAINTAINED').
-define('DIAMETER_SWX_AUTH-SESSION-STATE_NO_STATE_MAINTAINED', 1).
-endif.
-ifndef('DIAMETER_SWX_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_SWX_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 0).
-endif.
-ifndef('DIAMETER_SWX_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_SWX_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 1).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_LOGOUT').
-define('DIAMETER_SWX_TERMINATION-CAUSE_LOGOUT', 1).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED').
-define('DIAMETER_SWX_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED', 2).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_BAD_ANSWER').
-define('DIAMETER_SWX_TERMINATION-CAUSE_BAD_ANSWER', 3).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_ADMINISTRATIVE').
-define('DIAMETER_SWX_TERMINATION-CAUSE_ADMINISTRATIVE', 4).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_LINK_BROKEN').
-define('DIAMETER_SWX_TERMINATION-CAUSE_LINK_BROKEN', 5).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_AUTH_EXPIRED').
-define('DIAMETER_SWX_TERMINATION-CAUSE_AUTH_EXPIRED', 6).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_USER_MOVED').
-define('DIAMETER_SWX_TERMINATION-CAUSE_USER_MOVED', 7).
-endif.
-ifndef('DIAMETER_SWX_TERMINATION-CAUSE_SESSION_TIMEOUT').
-define('DIAMETER_SWX_TERMINATION-CAUSE_SESSION_TIMEOUT', 8).
-endif.
-ifndef('DIAMETER_SWX_SESSION-SERVER-FAILOVER_REFUSE_SERVICE').
-define('DIAMETER_SWX_SESSION-SERVER-FAILOVER_REFUSE_SERVICE', 0).
-endif.
-ifndef('DIAMETER_SWX_SESSION-SERVER-FAILOVER_TRY_AGAIN').
-define('DIAMETER_SWX_SESSION-SERVER-FAILOVER_TRY_AGAIN', 1).
-endif.
-ifndef('DIAMETER_SWX_SESSION-SERVER-FAILOVER_ALLOW_SERVICE').
-define('DIAMETER_SWX_SESSION-SERVER-FAILOVER_ALLOW_SERVICE', 2).
-endif.
-ifndef('DIAMETER_SWX_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE').
-define('DIAMETER_SWX_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE', 3).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_EVENT_RECORD').
-define('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_EVENT_RECORD', 1).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_START_RECORD').
-define('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_START_RECORD', 2).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD').
-define('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD', 3).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_STOP_RECORD').
-define('DIAMETER_SWX_ACCOUNTING-RECORD-TYPE_STOP_RECORD', 4).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT').
-define('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT', 1).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE').
-define('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE', 2).
-endif.
-ifndef('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE').
-define('DIAMETER_SWX_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE', 3).
-endif.

