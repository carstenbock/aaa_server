%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

-hrl_name('diameter_gen_s6b.hrl').


%%% -------------------------------------------------------
%%% Message records:
%%% -------------------------------------------------------

-record(diameter_s6b_AAR,
        {'Session-Id',
         'Auth-Application-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Auth-Request-Type',
         'Destination-Host' = [],
         'User-Name' = [],
         'Service-Selection' = [],
         'MIP6-Agent-Info' = [],
         'MIP6-Feature-Vector' = [],
         'Visited-Network-Identifier' = [],
         'Auth-Session-State' = [],
         'RAT-Type' = [],
         'UE-Local-IP-Address' = [],
         'Terminal-Information' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_s6b_AAA,
        {'Session-Id',
         'Auth-Application-Id',
         'Result-Code',
         'Origin-Host',
         'Origin-Realm',
         'Auth-Request-Type',
         'User-Name' = [],
         'Session-Timeout' = [],
         'MIP6-Feature-Vector' = [],
         'APN-Configuration' = [],
         'AMBR' = [],
         '3GPP-AAA-Server-Name' = [],
         'Error-Message' = [],
         'Error-Reporting-Host' = [],
         'Failed-AVP' = [],
         'Redirect-Host' = [],
         'Proxy-Info' = [],
         'AVP' = []}).

-record(diameter_s6b_STR,
        {'Session-Id',
         'Origin-Host',
         'Origin-Realm',
         'Destination-Realm',
         'Auth-Application-Id',
         'Termination-Cause',
         'Destination-Host' = [],
         'User-Name' = [],
         'Auth-Session-State' = [],
         'Class' = [],
         'Proxy-Info' = [],
         'Route-Record' = [],
         'AVP' = []}).

-record(diameter_s6b_STA,
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

-record(diameter_s6b_ASR,
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

-record(diameter_s6b_ASA,
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

-record(diameter_s6b_RAR,
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

-record(diameter_s6b_RAA,
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

-record('diameter_s6b_MIP6-Agent-Info',
        {'MIP-Home-Agent-Address' = [],
         'MIP-Home-Agent-Host' = [],
         'MIP6-Home-Link-Prefix' = []}).

-record('diameter_s6b_MIP-Home-Agent-Host',
        {'Destination-Realm', 'Destination-Host'}).

-record('diameter_s6b_APN-Configuration',
        {'Context-Identifier',
         'PDN-Type',
         'Service-Selection',
         'AMBR' = [],
         'Served-Party-IP-Address' = [],
         'AVP' = []}).

-record(diameter_s6b_AMBR,
        {'Max-Requested-Bandwidth-UL',
         'Max-Requested-Bandwidth-DL'}).

-record('diameter_s6b_Terminal-Information',
        {'IMEI' = [], 'Software-Version' = []}).


%%% -------------------------------------------------------
%%% Grouped AVP records from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-record('diameter_s6b_Proxy-Info',
        {'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_s6b_Failed-AVP', {'AVP' = []}).

-record('diameter_s6b_Experimental-Result',
        {'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_s6b_Vendor-Specific-Application-Id',
        {'Vendor-Id',
         'Auth-Application-Id' = [],
         'Acct-Application-Id' = []}).


%%% -------------------------------------------------------
%%% ENUM Macros:
%%% -------------------------------------------------------

-define('DIAMETER_S6B_RAT-TYPE_WLAN', 0).
-define('DIAMETER_S6B_RAT-TYPE_VIRTUAL', 1).
-define('DIAMETER_S6B_RAT-TYPE_EUTRAN', 1004).
-define('DIAMETER_S6B_RAT-TYPE_HRPD', 2001).
-define('DIAMETER_S6B_RAT-TYPE_EHRPD', 2003).
-define('DIAMETER_S6B_PDN-TYPE_IPV4', 0).
-define('DIAMETER_S6B_PDN-TYPE_IPV6', 1).
-define('DIAMETER_S6B_PDN-TYPE_IPV4V6', 2).
-define('DIAMETER_S6B_PDN-TYPE_IPV4_OR_IPV6', 3).
-define('DIAMETER_S6B_PDN-TYPE_NON_IP', 4).



%%% -------------------------------------------------------
%%% DEFINE Macros:
%%% -------------------------------------------------------

-define('DIAMETER_S6B_RESULT-CODE_DIAMETER_ERROR_USER_UNKNOWN', 5001).
-define('DIAMETER_S6B_RESULT-CODE_DIAMETER_ERROR_UNKNOWN_EPS_SUBSCRIPTION', 5420).
-define('DIAMETER_S6B_RESULT-CODE_DIAMETER_ERROR_RAT_NOT_ALLOWED', 5421).
-define('DIAMETER_S6B_RESULT-CODE_DIAMETER_ERROR_ROAMING_NOT_ALLOWED', 5004).
-define('DIAMETER_S6B_RESULT-CODE_DIAMETER_ERROR_USER_NO_APN_SUBSCRIPTION', 5451).



%%% -------------------------------------------------------
%%% ENUM Macros from diameter_gen_base_rfc6733:
%%% -------------------------------------------------------

-ifndef('DIAMETER_S6B_DISCONNECT-CAUSE_REBOOTING').
-define('DIAMETER_S6B_DISCONNECT-CAUSE_REBOOTING', 0).
-endif.
-ifndef('DIAMETER_S6B_DISCONNECT-CAUSE_BUSY').
-define('DIAMETER_S6B_DISCONNECT-CAUSE_BUSY', 1).
-endif.
-ifndef('DIAMETER_S6B_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU').
-define('DIAMETER_S6B_DISCONNECT-CAUSE_DO_NOT_WANT_TO_TALK_TO_YOU', 2).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_DONT_CACHE').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_DONT_CACHE', 0).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_SESSION').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_SESSION', 1).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_REALM').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_REALM', 2).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_REALM_AND_APPLICATION', 3).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_APPLICATION').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_APPLICATION', 4).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_HOST').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_HOST', 5).
-endif.
-ifndef('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_USER').
-define('DIAMETER_S6B_REDIRECT-HOST-USAGE_ALL_USER', 6).
-endif.
-ifndef('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY').
-define('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHENTICATE_ONLY', 1).
-endif.
-ifndef('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 2).
-endif.
-ifndef('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_S6B_AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 3).
-endif.
-ifndef('DIAMETER_S6B_AUTH-SESSION-STATE_STATE_MAINTAINED').
-define('DIAMETER_S6B_AUTH-SESSION-STATE_STATE_MAINTAINED', 0).
-endif.
-ifndef('DIAMETER_S6B_AUTH-SESSION-STATE_NO_STATE_MAINTAINED').
-define('DIAMETER_S6B_AUTH-SESSION-STATE_NO_STATE_MAINTAINED', 1).
-endif.
-ifndef('DIAMETER_S6B_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY').
-define('DIAMETER_S6B_RE-AUTH-REQUEST-TYPE_AUTHORIZE_ONLY', 0).
-endif.
-ifndef('DIAMETER_S6B_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE').
-define('DIAMETER_S6B_RE-AUTH-REQUEST-TYPE_AUTHORIZE_AUTHENTICATE', 1).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_LOGOUT').
-define('DIAMETER_S6B_TERMINATION-CAUSE_LOGOUT', 1).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED').
-define('DIAMETER_S6B_TERMINATION-CAUSE_SERVICE_NOT_PROVIDED', 2).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_BAD_ANSWER').
-define('DIAMETER_S6B_TERMINATION-CAUSE_BAD_ANSWER', 3).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_ADMINISTRATIVE').
-define('DIAMETER_S6B_TERMINATION-CAUSE_ADMINISTRATIVE', 4).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_LINK_BROKEN').
-define('DIAMETER_S6B_TERMINATION-CAUSE_LINK_BROKEN', 5).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_AUTH_EXPIRED').
-define('DIAMETER_S6B_TERMINATION-CAUSE_AUTH_EXPIRED', 6).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_USER_MOVED').
-define('DIAMETER_S6B_TERMINATION-CAUSE_USER_MOVED', 7).
-endif.
-ifndef('DIAMETER_S6B_TERMINATION-CAUSE_SESSION_TIMEOUT').
-define('DIAMETER_S6B_TERMINATION-CAUSE_SESSION_TIMEOUT', 8).
-endif.
-ifndef('DIAMETER_S6B_SESSION-SERVER-FAILOVER_REFUSE_SERVICE').
-define('DIAMETER_S6B_SESSION-SERVER-FAILOVER_REFUSE_SERVICE', 0).
-endif.
-ifndef('DIAMETER_S6B_SESSION-SERVER-FAILOVER_TRY_AGAIN').
-define('DIAMETER_S6B_SESSION-SERVER-FAILOVER_TRY_AGAIN', 1).
-endif.
-ifndef('DIAMETER_S6B_SESSION-SERVER-FAILOVER_ALLOW_SERVICE').
-define('DIAMETER_S6B_SESSION-SERVER-FAILOVER_ALLOW_SERVICE', 2).
-endif.
-ifndef('DIAMETER_S6B_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE').
-define('DIAMETER_S6B_SESSION-SERVER-FAILOVER_TRY_AGAIN_ALLOW_SERVICE', 3).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_EVENT_RECORD').
-define('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_EVENT_RECORD', 1).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_START_RECORD').
-define('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_START_RECORD', 2).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD').
-define('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_INTERIM_RECORD', 3).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_STOP_RECORD').
-define('DIAMETER_S6B_ACCOUNTING-RECORD-TYPE_STOP_RECORD', 4).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT').
-define('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_DELIVER_AND_GRANT', 1).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE').
-define('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_STORE', 2).
-endif.
-ifndef('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE').
-define('DIAMETER_S6B_ACCOUNTING-REALTIME-REQUIRED_GRANT_AND_LOSE', 3).
-endif.

