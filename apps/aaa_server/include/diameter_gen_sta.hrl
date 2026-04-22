%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

-hrl_name('diameter_gen_sta.hrl').


%%% -------------------------------------------------------
%%% Message records:
%%% -------------------------------------------------------

-record(diameter_sta_DER,
        {'Session-Id',
         'Auth-Application-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Auth-Request-Type',
         'Destination-Host' = [],
         'User-Name' = [],
         'EAP-Payload' = [],
         'RAT-Type' = [],
         'AN-Trusted' = [],
         'Service-Selection' = [],
         'MIP6-Feature-Vector' = [],
         'Visited-Network-Identifier' = [],
         'Terminal-Information' = [],
         'WLAN-Identifier' = [],
         'Calling-Station-Id' = [],
         'Called-Station-Id' = [],
         'UE-Local-IP-Address' = [],
         'Auth-Session-State' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_sta_DEA,
        {'Session-Id',
         'Auth-Application-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'Auth-Request-Type',
         'User-Name' = [],
         'EAP-Payload' = [],
         'EAP-Master-Session-Key' = [],
         'EAP-Key-Name' = [],
         'Session-Timeout' = [],
         'Auth-Grace-Period' = [],
         'MIP6-Feature-Vector' = [],
         'APN-Configuration' = [],
         'Non-3GPP-User-Data' = [],
         '3GPP-AAA-Server-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_sta_AAR,
        {'Session-Id',
         'Auth-Application-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Auth-Request-Type',
         'Destination-Host' = [],
         'User-Name' = [],
         'Service-Selection' = [],
         'RAT-Type' = [],
         'AN-Trusted' = [],
         'MIP6-Feature-Vector' = [],
         'Visited-Network-Identifier' = [],
         'Auth-Session-State' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_sta_AAA,
        {'Session-Id',
         'Auth-Application-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'Auth-Request-Type',
         'User-Name' = [],
         'Session-Timeout' = [],
         'APN-Configuration' = [],
         'Non-3GPP-User-Data' = [],
         '3GPP-AAA-Server-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_sta_STR,
        {'Session-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Auth-Application-Id',
         'Termination-Cause',
         'Destination-Host' = [],
         'User-Name' = [],
         'Auth-Session-State' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_sta_STA,
        {'Session-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'User-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_sta_ASR,
        {'Session-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Destination-Host',
         'Auth-Application-Id',
         'User-Name' = [],
         'Auth-Session-State' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_sta_ASA,
        {'Session-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'User-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_sta_RAR,
        {'Session-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Destination-Host',
         'Auth-Application-Id',
         'Re-Auth-Request-Type',
         'User-Name' = [],
         'Auth-Session-State' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_sta_RAA,
        {'Session-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'User-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Proxy-Info' = [],
         'AVP' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records:
%%% -------------------------------------------------------

-record('diameter_sta_Terminal-Information',
        {'IMEI' = [], 'Software-Version' = []}).

-record('diameter_sta_APN-Configuration',
        {'Context-Identifier',
         'PDN-Type',
         'Service-Selection',
         'AMBR' = [],
         'Served-Party-IP-Address' = [],
         'AVP' = []}).

-record(diameter_sta_AMBR,
        {'Max-Requested-Bandwidth-UL',
         'Max-Requested-Bandwidth-DL'}).

-record('diameter_sta_Non-3GPP-User-Data',
        {'Non-3GPP-IP-Access' = [],
         'Non-3GPP-IP-Access-APN' = [],
         'RAT-Type' = [],
         'Session-Timeout' = [],
         'MIP6-Feature-Vector' = [],
         'AMBR' = [],
         'APN-Configuration' = [],
         'AVP' = []}).

-record('diameter_sta_WLAN-Identifier',
        {'SSID' = [], 'HESSID' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-record('diameter_sta_Proxy-Info',
        {'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_sta_Failed-AVP', {'AVP' = []}).

-record('diameter_sta_Experimental-Result',
        {'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_sta_Vendor-Specific-Application-Id',
        {'Vendor-Id',
         'Auth-Application-Id' = [],
         'Acct-Application-Id' = []}).


%%% -------------------------------------------------------
%%% ENUM Macros:
%%% -------------------------------------------------------

-define('DIAMETER_STA_RAT-TYPE_WLAN', 0).
-define('DIAMETER_STA_RAT-TYPE_VIRTUAL', 1).
-define('DIAMETER_STA_RAT-TYPE_HRPD', 2001).
-define('DIAMETER_STA_RAT-TYPE_EHRPD', 2003).
-define('DIAMETER_STA_AN-TRUSTED_TRUSTED', 0).
-define('DIAMETER_STA_AN-TRUSTED_UNTRUSTED', 1).
-define('DIAMETER_STA_NON-3GPP-IP-ACCESS_NON_3GPP_SUBSCRIPTION_ALLOWED', 0).
-define('DIAMETER_STA_NON-3GPP-IP-ACCESS_NON_3GPP_SUBSCRIPTION_BARRED', 1).
-define('DIAMETER_STA_NON-3GPP-IP-ACCESS-APN_NON_3GPP_APNS_ENABLE', 0).
-define('DIAMETER_STA_NON-3GPP-IP-ACCESS-APN_NON_3GPP_APNS_DISABLE', 1).
-define('DIAMETER_STA_PDN-TYPE_IPV4', 0).
-define('DIAMETER_STA_PDN-TYPE_IPV6', 1).
-define('DIAMETER_STA_PDN-TYPE_IPV4V6', 2).
-define('DIAMETER_STA_PDN-TYPE_IPV4_OR_IPV6', 3).
-define('DIAMETER_STA_PDN-TYPE_NON_IP', 4).



%%% -------------------------------------------------------
%%% DEFINE Macros:
%%% -------------------------------------------------------

-define('DIAMETER_STA_RESULT-CODE_DIAMETER_ERROR_USER_UNKNOWN', 5001).
-define('DIAMETER_STA_RESULT-CODE_DIAMETER_ERROR_ROAMING_NOT_ALLOWED', 5004).
-define('DIAMETER_STA_RESULT-CODE_DIAMETER_AUTHENTICATION_DATA_UNAVAILABLE', 4181).
-define('DIAMETER_STA_RESULT-CODE_DIAMETER_ERROR_USER_NO_NON_3GPP_SUBSCRIPTION', 5450).
-define('DIAMETER_STA_RESULT-CODE_DIAMETER_ERROR_RAT_TYPE_NOT_ALLOWED', 5452).
-define('DIAMETER_STA_RESULT-CODE_DIAMETER_MULTI_ROUND_AUTH', 1001).



%%% -------------------------------------------------------
%%% ENUM Macros from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-ifndef('DIAMETER_STA_DISCONNECT-CAUSE_REBOOTING').
-define('DIAMETER_STA_DISCONNECT-CAUSE_REBOOTING', 0).
-endif.
-ifndef('DIAMETER_STA_DISCONNECT-CAUSE_BUSY').
-define('DIAMETER_STA_DISCONNECT-CAUSE_BUSY', 1).
-endif.
-ifndef('DIAMETER_STA_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU').
-define('DIAMETER_STA_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU', 2).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_DONT_CACHE').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_DONT_CACHE', 0).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_SESSION').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_SESSION', 1).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_REALM').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_REALM', 2).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION', 3).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_APPLICATION').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_APPLICATION', 4).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_HOST').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_HOST', 5).
-endif.
-ifndef('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_USER').
-define('DIAMETER_STA_REDIRECT-HOST-USAGE_ALL_USER', 6).
-endif.
-ifndef('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY').
-define('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY', 1).
-endif.
-ifndef('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 2).
-endif.
-ifndef('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_STA_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 3).
-endif.
-ifndef('DIAMETER_STA_AUTH-SESSION-STATE_STATE_MAINTAINED').
-define('DIAMETER_STA_AUTH-SESSION-STATE_STATE_MAINTAINED', 0).
-endif.
-ifndef('DIAMETER_STA_AUTH-SESSION-STATE_NO_STATE_MAINTAINED').
-define('DIAMETER_STA_AUTH-SESSION-STATE_NO_STATE_MAINTAINED', 1).
-endif.
-ifndef('DIAMETER_STA_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_STA_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 0).
-endif.
-ifndef('DIAMETER_STA_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_STA_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 1).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_LOGOUT').
-define('DIAMETER_STA_TERMINATION-CAUSE_LOGOUT', 1).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED').
-define('DIAMETER_STA_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED', 2).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_BAD_ANSWER').
-define('DIAMETER_STA_TERMINATION-CAUSE_BAD_ANSWER', 3).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_ADMINISTRATIVE').
-define('DIAMETER_STA_TERMINATION-CAUSE_ADMINISTRATIVE', 4).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_LINK_BROKEN').
-define('DIAMETER_STA_TERMINATION-CAUSE_LINK_BROKEN', 5).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_AUTH_EXPIRED').
-define('DIAMETER_STA_TERMINATION-CAUSE_AUTH_EXPIRED', 6).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_USER_MOVED').
-define('DIAMETER_STA_TERMINATION-CAUSE_USER_MOVED', 7).
-endif.
-ifndef('DIAMETER_STA_TERMINATION-CAUSE_SESSION_TIMEOUT').
-define('DIAMETER_STA_TERMINATION-CAUSE_SESSION_TIMEOUT', 8).
-endif.
-ifndef('DIAMETER_STA_SESSION-SERVER-FAILOVER_REFUSE_SERVICE').
-define('DIAMETER_STA_SESSION-SERVER-FAILOVER_REFUSE_SERVICE', 0).
-endif.
-ifndef('DIAMETER_STA_SESSION-SERVER-FAILOVER_TRY_AGAIN').
-define('DIAMETER_STA_SESSION-SERVER-FAILOVER_TRY_AGAIN', 1).
-endif.
-ifndef('DIAMETER_STA_SESSION-SERVER-FAILOVER_ALLOW_SERVICE').
-define('DIAMETER_STA_SESSION-SERVER-FAILOVER_ALLOW_SERVICE', 2).
-endif.
-ifndef('DIAMETER_STA_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE').
-define('DIAMETER_STA_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE', 3).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_EVENT_RECORD').
-define('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_EVENT_RECORD', 1).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_START_RECORD').
-define('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_START_RECORD', 2).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD').
-define('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD', 3).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_STOP_RECORD').
-define('DIAMETER_STA_ACCOUNTING-RECORD-TYPE_STOP_RECORD', 4).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT').
-define('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT', 1).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE').
-define('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE', 2).
-endif.
-ifndef('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE').
-define('DIAMETER_STA_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE', 3).
-endif.

