%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

-module(diameter_gen_s6b).

-moduledoc(false).

-compile({parse_transform, diameter_exprecs}).

-compile(nowarn_unused_function).

-dialyzer(no_return).

-export_records([diameter_s6b_AAR,
                 diameter_s6b_AAA,
                 diameter_s6b_STR,
                 diameter_s6b_STA,
                 diameter_s6b_ASR,
                 diameter_s6b_ASA,
                 diameter_s6b_RAR,
                 diameter_s6b_RAA,
                 'diameter_s6b_MIP6-Agent-Info',
                 'diameter_s6b_MIP-Home-Agent-Host',
                 'diameter_s6b_APN-Configuration',
                 diameter_s6b_AMBR,
                 'diameter_s6b_Terminal-Information',
                 'diameter_s6b_Proxy-Info',
                 'diameter_s6b_Failed-AVP',
                 'diameter_s6b_Experimental-Result',
                 'diameter_s6b_Vendor-Specific-Application-Id']).

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

-record('diameter_s6b_Proxy-Info',
        {'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_s6b_Failed-AVP', {'AVP' = []}).

-record('diameter_s6b_Experimental-Result',
        {'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_s6b_Vendor-Specific-Application-Id',
        {'Vendor-Id',
         'Auth-Application-Id' = [],
         'Acct-Application-Id' = []}).

-export([name/0,
         id/0,
         vendor_id/0,
         vendor_name/0,
         decode_avps/3,
         encode_avps/3,
         grouped_avp/4,
         msg_name/2,
         msg_header/1,
         rec2msg/1,
         msg2rec/1,
         name2rec/1,
         avp_name/2,
         avp_arity/1,
         avp_arity/2,
         avp_header/1,
         avp/4,
         enumerated_avp/3,
         empty_value/2,
         dict/0]).

-include_lib("diameter/include/diameter.hrl").

-include_lib("diameter/include/diameter_gen.hrl").

name() -> diameter_gen_s6b.

id() -> 16777272.

vendor_id() -> 10415.

vendor_name() -> '3GPP'.

msg_name(275, true) -> 'STR';
msg_name(275, false) -> 'STA';
msg_name(265, true) -> 'AAR';
msg_name(265, false) -> 'AAA';
msg_name(258, true) -> 'RAR';
msg_name(258, false) -> 'RAA';
msg_name(274, true) -> 'ASR';
msg_name(274, false) -> 'ASA';
msg_name(_, _) -> ''.

msg_header('AAR') -> {265, 192, 16777272};
msg_header('AAA') -> {265, 64, 16777272};
msg_header('STR') -> {275, 192, 16777272};
msg_header('STA') -> {275, 64, 16777272};
msg_header('ASR') -> {274, 192, 16777272};
msg_header('ASA') -> {274, 64, 16777272};
msg_header('RAR') -> {258, 192, 16777272};
msg_header('RAA') -> {258, 64, 16777272};
msg_header(_) -> erlang:error(badarg).

rec2msg(diameter_s6b_AAR) -> 'AAR';
rec2msg(diameter_s6b_AAA) -> 'AAA';
rec2msg(diameter_s6b_STR) -> 'STR';
rec2msg(diameter_s6b_STA) -> 'STA';
rec2msg(diameter_s6b_ASR) -> 'ASR';
rec2msg(diameter_s6b_ASA) -> 'ASA';
rec2msg(diameter_s6b_RAR) -> 'RAR';
rec2msg(diameter_s6b_RAA) -> 'RAA';
rec2msg(_) -> erlang:error(badarg).

msg2rec('AAR') -> diameter_s6b_AAR;
msg2rec('AAA') -> diameter_s6b_AAA;
msg2rec('STR') -> diameter_s6b_STR;
msg2rec('STA') -> diameter_s6b_STA;
msg2rec('ASR') -> diameter_s6b_ASR;
msg2rec('ASA') -> diameter_s6b_ASA;
msg2rec('RAR') -> diameter_s6b_RAR;
msg2rec('RAA') -> diameter_s6b_RAA;
msg2rec(_) -> erlang:error(badarg).

name2rec('MIP6-Agent-Info') ->
    'diameter_s6b_MIP6-Agent-Info';
name2rec('MIP-Home-Agent-Host') ->
    'diameter_s6b_MIP-Home-Agent-Host';
name2rec('APN-Configuration') ->
    'diameter_s6b_APN-Configuration';
name2rec('AMBR') -> diameter_s6b_AMBR;
name2rec('Terminal-Information') ->
    'diameter_s6b_Terminal-Information';
name2rec('Proxy-Info') -> 'diameter_s6b_Proxy-Info';
name2rec('Failed-AVP') -> 'diameter_s6b_Failed-AVP';
name2rec('Experimental-Result') ->
    'diameter_s6b_Experimental-Result';
name2rec('Vendor-Specific-Application-Id') ->
    'diameter_s6b_Vendor-Specific-Application-Id';
name2rec(T) -> msg2rec(T).

avp_name(318, 10415) ->
    {'3GPP-AAA-Server-Name', 'DiameterIdentity'};
avp_name(1435, 10415) -> {'AMBR', 'Grouped'};
avp_name(1430, 10415) ->
    {'APN-Configuration', 'Grouped'};
avp_name(1423, 10415) ->
    {'Context-Identifier', 'Unsigned32'};
avp_name(1402, 10415) -> {'IMEI', 'UTF8String'};
avp_name(334, undefined) ->
    {'MIP-Home-Agent-Address', 'Address'};
avp_name(348, undefined) ->
    {'MIP-Home-Agent-Host', 'Grouped'};
avp_name(486, undefined) ->
    {'MIP6-Agent-Info', 'Grouped'};
avp_name(124, undefined) ->
    {'MIP6-Feature-Vector', 'Unsigned64'};
avp_name(125, undefined) ->
    {'MIP6-Home-Link-Prefix', 'OctetString'};
avp_name(515, undefined) ->
    {'Max-Requested-Bandwidth-DL', 'Unsigned32'};
avp_name(516, undefined) ->
    {'Max-Requested-Bandwidth-UL', 'Unsigned32'};
avp_name(1456, 10415) -> {'PDN-Type', 'Enumerated'};
avp_name(1032, 10415) -> {'RAT-Type', 'Enumerated'};
avp_name(848, 10415) ->
    {'Served-Party-IP-Address', 'Address'};
avp_name(493, undefined) ->
    {'Service-Selection', 'UTF8String'};
avp_name(1403, 10415) ->
    {'Software-Version', 'UTF8String'};
avp_name(1401, 10415) ->
    {'Terminal-Information', 'Grouped'};
avp_name(2805, 10415) ->
    {'UE-Local-IP-Address', 'Address'};
avp_name(600, 10415) ->
    {'Visited-Network-Identifier', 'OctetString'};
avp_name(483, undefined) ->
    {'Accounting-Realtime-Required', 'Enumerated'};
avp_name(485, undefined) ->
    {'Accounting-Record-Number', 'Unsigned32'};
avp_name(480, undefined) ->
    {'Accounting-Record-Type', 'Enumerated'};
avp_name(287, undefined) ->
    {'Accounting-Sub-Session-Id', 'Unsigned64'};
avp_name(259, undefined) ->
    {'Acct-Application-Id', 'Unsigned32'};
avp_name(85, undefined) ->
    {'Acct-Interim-Interval', 'Unsigned32'};
avp_name(50, undefined) ->
    {'Acct-Multi-Session-Id', 'UTF8String'};
avp_name(44, undefined) ->
    {'Acct-Session-Id', 'OctetString'};
avp_name(258, undefined) ->
    {'Auth-Application-Id', 'Unsigned32'};
avp_name(276, undefined) ->
    {'Auth-Grace-Period', 'Unsigned32'};
avp_name(274, undefined) ->
    {'Auth-Request-Type', 'Enumerated'};
avp_name(277, undefined) ->
    {'Auth-Session-State', 'Enumerated'};
avp_name(291, undefined) ->
    {'Authorization-Lifetime', 'Unsigned32'};
avp_name(25, undefined) -> {'Class', 'OctetString'};
avp_name(293, undefined) ->
    {'Destination-Host', 'DiameterIdentity'};
avp_name(283, undefined) ->
    {'Destination-Realm', 'DiameterIdentity'};
avp_name(273, undefined) ->
    {'Disconnect-Cause', 'Enumerated'};
avp_name(281, undefined) ->
    {'Error-Message', 'UTF8String'};
avp_name(294, undefined) ->
    {'Error-Reporting-Host', 'DiameterIdentity'};
avp_name(55, undefined) -> {'Event-Timestamp', 'Time'};
avp_name(297, undefined) ->
    {'Experimental-Result', 'Grouped'};
avp_name(298, undefined) ->
    {'Experimental-Result-Code', 'Unsigned32'};
avp_name(279, undefined) -> {'Failed-AVP', 'Grouped'};
avp_name(267, undefined) ->
    {'Firmware-Revision', 'Unsigned32'};
avp_name(257, undefined) ->
    {'Host-IP-Address', 'Address'};
avp_name(299, undefined) ->
    {'Inband-Security-Id', 'Unsigned32'};
avp_name(272, undefined) ->
    {'Multi-Round-Time-Out', 'Unsigned32'};
avp_name(264, undefined) ->
    {'Origin-Host', 'DiameterIdentity'};
avp_name(296, undefined) ->
    {'Origin-Realm', 'DiameterIdentity'};
avp_name(278, undefined) ->
    {'Origin-State-Id', 'Unsigned32'};
avp_name(269, undefined) ->
    {'Product-Name', 'UTF8String'};
avp_name(280, undefined) ->
    {'Proxy-Host', 'DiameterIdentity'};
avp_name(284, undefined) -> {'Proxy-Info', 'Grouped'};
avp_name(33, undefined) ->
    {'Proxy-State', 'OctetString'};
avp_name(285, undefined) ->
    {'Re-Auth-Request-Type', 'Enumerated'};
avp_name(292, undefined) ->
    {'Redirect-Host', 'DiameterURI'};
avp_name(261, undefined) ->
    {'Redirect-Host-Usage', 'Enumerated'};
avp_name(262, undefined) ->
    {'Redirect-Max-Cache-Time', 'Unsigned32'};
avp_name(268, undefined) ->
    {'Result-Code', 'Unsigned32'};
avp_name(282, undefined) ->
    {'Route-Record', 'DiameterIdentity'};
avp_name(270, undefined) ->
    {'Session-Binding', 'Unsigned32'};
avp_name(263, undefined) ->
    {'Session-Id', 'UTF8String'};
avp_name(271, undefined) ->
    {'Session-Server-Failover', 'Enumerated'};
avp_name(27, undefined) ->
    {'Session-Timeout', 'Unsigned32'};
avp_name(265, undefined) ->
    {'Supported-Vendor-Id', 'Unsigned32'};
avp_name(295, undefined) ->
    {'Termination-Cause', 'Enumerated'};
avp_name(1, undefined) -> {'User-Name', 'UTF8String'};
avp_name(266, undefined) -> {'Vendor-Id', 'Unsigned32'};
avp_name(260, undefined) ->
    {'Vendor-Specific-Application-Id', 'Grouped'};
avp_name(_, _) -> 'AVP'.

avp_arity('AAR') ->
    [{'Session-Id', 1},
     {'Auth-Application-Id', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'Auth-Request-Type', 1},
     {'Destination-Host', {0, 1}},
     {'User-Name', {0, 1}},
     {'Service-Selection', {0, 1}},
     {'MIP6-Agent-Info', {0, 1}},
     {'MIP6-Feature-Vector', {0, 1}},
     {'Visited-Network-Identifier', {0, 1}},
     {'Auth-Session-State', {0, 1}},
     {'RAT-Type', {0, 1}},
     {'UE-Local-IP-Address', {0, 1}},
     {'Terminal-Information', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('AAA') ->
    [{'Session-Id', 1},
     {'Auth-Application-Id', 1},
     {'Result-Code', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Auth-Request-Type', 1},
     {'User-Name', {0, 1}},
     {'Session-Timeout', {0, 1}},
     {'MIP6-Feature-Vector', {0, 1}},
     {'APN-Configuration', {0, 1}},
     {'AMBR', {0, 1}},
     {'3GPP-AAA-Server-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('STR') ->
    [{'Session-Id', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'Auth-Application-Id', 1},
     {'Termination-Cause', 1},
     {'Destination-Host', {0, 1}},
     {'User-Name', {0, 1}},
     {'Auth-Session-State', {0, 1}},
     {'Class', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('STA') ->
    [{'Session-Id', 1},
     {'Result-Code', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'User-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('ASR') ->
    [{'Session-Id', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'Destination-Host', 1},
     {'Auth-Application-Id', 1},
     {'User-Name', {0, 1}},
     {'Auth-Session-State', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('ASA') ->
    [{'Session-Id', 1},
     {'Result-Code', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'User-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('RAR') ->
    [{'Session-Id', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'Destination-Host', 1},
     {'Auth-Application-Id', 1},
     {'Re-Auth-Request-Type', 1},
     {'User-Name', {0, 1}},
     {'Auth-Session-State', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('RAA') ->
    [{'Session-Id', 1},
     {'Result-Code', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'User-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('MIP6-Agent-Info') ->
    [{'MIP-Home-Agent-Address', {0, '*'}},
     {'MIP-Home-Agent-Host', {0, 1}},
     {'MIP6-Home-Link-Prefix', {0, 1}}];
avp_arity('MIP-Home-Agent-Host') ->
    [{'Destination-Realm', 1}, {'Destination-Host', 1}];
avp_arity('APN-Configuration') ->
    [{'Context-Identifier', 1},
     {'PDN-Type', 1},
     {'Service-Selection', 1},
     {'AMBR', {0, 1}},
     {'Served-Party-IP-Address', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('AMBR') ->
    [{'Max-Requested-Bandwidth-UL', 1},
     {'Max-Requested-Bandwidth-DL', 1}];
avp_arity('Terminal-Information') ->
    [{'IMEI', {0, 1}}, {'Software-Version', {0, 1}}];
avp_arity('Proxy-Info') ->
    [{'Proxy-Host', 1},
     {'Proxy-State', 1},
     {'AVP', {0, '*'}}];
avp_arity('Failed-AVP') -> [{'AVP', {1, '*'}}];
avp_arity('Experimental-Result') ->
    [{'Vendor-Id', 1}, {'Experimental-Result-Code', 1}];
avp_arity('Vendor-Specific-Application-Id') ->
    [{'Vendor-Id', 1},
     {'Auth-Application-Id', {0, 1}},
     {'Acct-Application-Id', {0, 1}}];
avp_arity(_) -> erlang:error(badarg).

avp_arity('AAR', 'Session-Id') -> 1;
avp_arity('AAR', 'Auth-Application-Id') -> 1;
avp_arity('AAR', 'Origin-Host') -> 1;
avp_arity('AAR', 'Origin-Realm') -> 1;
avp_arity('AAR', 'Destination-Realm') -> 1;
avp_arity('AAR', 'Auth-Request-Type') -> 1;
avp_arity('AAR', 'Destination-Host') -> {0, 1};
avp_arity('AAR', 'User-Name') -> {0, 1};
avp_arity('AAR', 'Service-Selection') -> {0, 1};
avp_arity('AAR', 'MIP6-Agent-Info') -> {0, 1};
avp_arity('AAR', 'MIP6-Feature-Vector') -> {0, 1};
avp_arity('AAR', 'Visited-Network-Identifier') ->
    {0, 1};
avp_arity('AAR', 'Auth-Session-State') -> {0, 1};
avp_arity('AAR', 'RAT-Type') -> {0, 1};
avp_arity('AAR', 'UE-Local-IP-Address') -> {0, 1};
avp_arity('AAR', 'Terminal-Information') -> {0, 1};
avp_arity('AAR', 'Proxy-Info') -> {0, '*'};
avp_arity('AAR', 'Route-Record') -> {0, '*'};
avp_arity('AAR', 'AVP') -> {0, '*'};
avp_arity('AAA', 'Session-Id') -> 1;
avp_arity('AAA', 'Auth-Application-Id') -> 1;
avp_arity('AAA', 'Result-Code') -> 1;
avp_arity('AAA', 'Origin-Host') -> 1;
avp_arity('AAA', 'Origin-Realm') -> 1;
avp_arity('AAA', 'Auth-Request-Type') -> 1;
avp_arity('AAA', 'User-Name') -> {0, 1};
avp_arity('AAA', 'Session-Timeout') -> {0, 1};
avp_arity('AAA', 'MIP6-Feature-Vector') -> {0, 1};
avp_arity('AAA', 'APN-Configuration') -> {0, 1};
avp_arity('AAA', 'AMBR') -> {0, 1};
avp_arity('AAA', '3GPP-AAA-Server-Name') -> {0, 1};
avp_arity('AAA', 'Error-Message') -> {0, 1};
avp_arity('AAA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('AAA', 'Failed-AVP') -> {0, 1};
avp_arity('AAA', 'Redirect-Host') -> {0, '*'};
avp_arity('AAA', 'Proxy-Info') -> {0, '*'};
avp_arity('AAA', 'AVP') -> {0, '*'};
avp_arity('STR', 'Session-Id') -> 1;
avp_arity('STR', 'Origin-Host') -> 1;
avp_arity('STR', 'Origin-Realm') -> 1;
avp_arity('STR', 'Destination-Realm') -> 1;
avp_arity('STR', 'Auth-Application-Id') -> 1;
avp_arity('STR', 'Termination-Cause') -> 1;
avp_arity('STR', 'Destination-Host') -> {0, 1};
avp_arity('STR', 'User-Name') -> {0, 1};
avp_arity('STR', 'Auth-Session-State') -> {0, 1};
avp_arity('STR', 'Class') -> {0, '*'};
avp_arity('STR', 'Proxy-Info') -> {0, '*'};
avp_arity('STR', 'Route-Record') -> {0, '*'};
avp_arity('STR', 'AVP') -> {0, '*'};
avp_arity('STA', 'Session-Id') -> 1;
avp_arity('STA', 'Result-Code') -> 1;
avp_arity('STA', 'Origin-Host') -> 1;
avp_arity('STA', 'Origin-Realm') -> 1;
avp_arity('STA', 'User-Name') -> {0, 1};
avp_arity('STA', 'Error-Message') -> {0, 1};
avp_arity('STA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('STA', 'Failed-AVP') -> {0, 1};
avp_arity('STA', 'Redirect-Host') -> {0, '*'};
avp_arity('STA', 'Proxy-Info') -> {0, '*'};
avp_arity('STA', 'AVP') -> {0, '*'};
avp_arity('ASR', 'Session-Id') -> 1;
avp_arity('ASR', 'Origin-Host') -> 1;
avp_arity('ASR', 'Origin-Realm') -> 1;
avp_arity('ASR', 'Destination-Realm') -> 1;
avp_arity('ASR', 'Destination-Host') -> 1;
avp_arity('ASR', 'Auth-Application-Id') -> 1;
avp_arity('ASR', 'User-Name') -> {0, 1};
avp_arity('ASR', 'Auth-Session-State') -> {0, 1};
avp_arity('ASR', 'Proxy-Info') -> {0, '*'};
avp_arity('ASR', 'Route-Record') -> {0, '*'};
avp_arity('ASR', 'AVP') -> {0, '*'};
avp_arity('ASA', 'Session-Id') -> 1;
avp_arity('ASA', 'Result-Code') -> 1;
avp_arity('ASA', 'Origin-Host') -> 1;
avp_arity('ASA', 'Origin-Realm') -> 1;
avp_arity('ASA', 'User-Name') -> {0, 1};
avp_arity('ASA', 'Error-Message') -> {0, 1};
avp_arity('ASA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('ASA', 'Failed-AVP') -> {0, 1};
avp_arity('ASA', 'Proxy-Info') -> {0, '*'};
avp_arity('ASA', 'AVP') -> {0, '*'};
avp_arity('RAR', 'Session-Id') -> 1;
avp_arity('RAR', 'Origin-Host') -> 1;
avp_arity('RAR', 'Origin-Realm') -> 1;
avp_arity('RAR', 'Destination-Realm') -> 1;
avp_arity('RAR', 'Destination-Host') -> 1;
avp_arity('RAR', 'Auth-Application-Id') -> 1;
avp_arity('RAR', 'Re-Auth-Request-Type') -> 1;
avp_arity('RAR', 'User-Name') -> {0, 1};
avp_arity('RAR', 'Auth-Session-State') -> {0, 1};
avp_arity('RAR', 'Proxy-Info') -> {0, '*'};
avp_arity('RAR', 'Route-Record') -> {0, '*'};
avp_arity('RAR', 'AVP') -> {0, '*'};
avp_arity('RAA', 'Session-Id') -> 1;
avp_arity('RAA', 'Result-Code') -> 1;
avp_arity('RAA', 'Origin-Host') -> 1;
avp_arity('RAA', 'Origin-Realm') -> 1;
avp_arity('RAA', 'User-Name') -> {0, 1};
avp_arity('RAA', 'Error-Message') -> {0, 1};
avp_arity('RAA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('RAA', 'Failed-AVP') -> {0, 1};
avp_arity('RAA', 'Proxy-Info') -> {0, '*'};
avp_arity('RAA', 'AVP') -> {0, '*'};
avp_arity('MIP6-Agent-Info',
          'MIP-Home-Agent-Address') ->
    {0, '*'};
avp_arity('MIP6-Agent-Info', 'MIP-Home-Agent-Host') ->
    {0, 1};
avp_arity('MIP6-Agent-Info', 'MIP6-Home-Link-Prefix') ->
    {0, 1};
avp_arity('MIP-Home-Agent-Host', 'Destination-Realm') ->
    1;
avp_arity('MIP-Home-Agent-Host', 'Destination-Host') ->
    1;
avp_arity('APN-Configuration', 'Context-Identifier') ->
    1;
avp_arity('APN-Configuration', 'PDN-Type') -> 1;
avp_arity('APN-Configuration', 'Service-Selection') ->
    1;
avp_arity('APN-Configuration', 'AMBR') -> {0, 1};
avp_arity('APN-Configuration',
          'Served-Party-IP-Address') ->
    {0, '*'};
avp_arity('APN-Configuration', 'AVP') -> {0, '*'};
avp_arity('AMBR', 'Max-Requested-Bandwidth-UL') -> 1;
avp_arity('AMBR', 'Max-Requested-Bandwidth-DL') -> 1;
avp_arity('Terminal-Information', 'IMEI') -> {0, 1};
avp_arity('Terminal-Information', 'Software-Version') ->
    {0, 1};
avp_arity('Proxy-Info', 'Proxy-Host') -> 1;
avp_arity('Proxy-Info', 'Proxy-State') -> 1;
avp_arity('Proxy-Info', 'AVP') -> {0, '*'};
avp_arity('Failed-AVP', 'AVP') -> {1, '*'};
avp_arity('Experimental-Result', 'Vendor-Id') -> 1;
avp_arity('Experimental-Result',
          'Experimental-Result-Code') ->
    1;
avp_arity('Vendor-Specific-Application-Id',
          'Vendor-Id') ->
    1;
avp_arity('Vendor-Specific-Application-Id',
          'Auth-Application-Id') ->
    {0, 1};
avp_arity('Vendor-Specific-Application-Id',
          'Acct-Application-Id') ->
    {0, 1};
avp_arity(_, _) -> 0.

avp_header('3GPP-AAA-Server-Name') -> {318, 192, 10415};
avp_header('AMBR') -> {1435, 192, 10415};
avp_header('APN-Configuration') -> {1430, 192, 10415};
avp_header('Context-Identifier') -> {1423, 192, 10415};
avp_header('IMEI') -> {1402, 192, 10415};
avp_header('MIP-Home-Agent-Address') ->
    {334, 64, undefined};
avp_header('MIP-Home-Agent-Host') ->
    {348, 64, undefined};
avp_header('MIP6-Agent-Info') -> {486, 64, undefined};
avp_header('MIP6-Feature-Vector') ->
    {124, 64, undefined};
avp_header('MIP6-Home-Link-Prefix') ->
    {125, 64, undefined};
avp_header('Max-Requested-Bandwidth-DL') ->
    {515, 64, undefined};
avp_header('Max-Requested-Bandwidth-UL') ->
    {516, 64, undefined};
avp_header('PDN-Type') -> {1456, 192, 10415};
avp_header('RAT-Type') -> {1032, 192, 10415};
avp_header('Served-Party-IP-Address') ->
    {848, 192, 10415};
avp_header('Service-Selection') -> {493, 64, undefined};
avp_header('Software-Version') -> {1403, 192, 10415};
avp_header('Terminal-Information') ->
    {1401, 192, 10415};
avp_header('UE-Local-IP-Address') -> {2805, 128, 10415};
avp_header('Visited-Network-Identifier') ->
    {600, 192, 10415};
avp_header('Accounting-Realtime-Required') ->
    diameter_gen_base_rfc6733:avp_header('Accounting-Realtime-Required');
avp_header('Accounting-Record-Number') ->
    diameter_gen_base_rfc6733:avp_header('Accounting-Record-Number');
avp_header('Accounting-Record-Type') ->
    diameter_gen_base_rfc6733:avp_header('Accounting-Record-Type');
avp_header('Accounting-Sub-Session-Id') ->
    diameter_gen_base_rfc6733:avp_header('Accounting-Sub-Session-Id');
avp_header('Acct-Application-Id') ->
    diameter_gen_base_rfc6733:avp_header('Acct-Application-Id');
avp_header('Acct-Interim-Interval') ->
    diameter_gen_base_rfc6733:avp_header('Acct-Interim-Interval');
avp_header('Acct-Multi-Session-Id') ->
    diameter_gen_base_rfc6733:avp_header('Acct-Multi-Session-Id');
avp_header('Acct-Session-Id') ->
    diameter_gen_base_rfc6733:avp_header('Acct-Session-Id');
avp_header('Auth-Application-Id') ->
    diameter_gen_base_rfc6733:avp_header('Auth-Application-Id');
avp_header('Auth-Grace-Period') ->
    diameter_gen_base_rfc6733:avp_header('Auth-Grace-Period');
avp_header('Auth-Request-Type') ->
    diameter_gen_base_rfc6733:avp_header('Auth-Request-Type');
avp_header('Auth-Session-State') ->
    diameter_gen_base_rfc6733:avp_header('Auth-Session-State');
avp_header('Authorization-Lifetime') ->
    diameter_gen_base_rfc6733:avp_header('Authorization-Lifetime');
avp_header('Class') ->
    diameter_gen_base_rfc6733:avp_header('Class');
avp_header('Destination-Host') ->
    diameter_gen_base_rfc6733:avp_header('Destination-Host');
avp_header('Destination-Realm') ->
    diameter_gen_base_rfc6733:avp_header('Destination-Realm');
avp_header('Disconnect-Cause') ->
    diameter_gen_base_rfc6733:avp_header('Disconnect-Cause');
avp_header('Error-Message') ->
    diameter_gen_base_rfc6733:avp_header('Error-Message');
avp_header('Error-Reporting-Host') ->
    diameter_gen_base_rfc6733:avp_header('Error-Reporting-Host');
avp_header('Event-Timestamp') ->
    diameter_gen_base_rfc6733:avp_header('Event-Timestamp');
avp_header('Experimental-Result') ->
    diameter_gen_base_rfc6733:avp_header('Experimental-Result');
avp_header('Experimental-Result-Code') ->
    diameter_gen_base_rfc6733:avp_header('Experimental-Result-Code');
avp_header('Failed-AVP') ->
    diameter_gen_base_rfc6733:avp_header('Failed-AVP');
avp_header('Firmware-Revision') ->
    diameter_gen_base_rfc6733:avp_header('Firmware-Revision');
avp_header('Host-IP-Address') ->
    diameter_gen_base_rfc6733:avp_header('Host-IP-Address');
avp_header('Inband-Security-Id') ->
    diameter_gen_base_rfc6733:avp_header('Inband-Security-Id');
avp_header('Multi-Round-Time-Out') ->
    diameter_gen_base_rfc6733:avp_header('Multi-Round-Time-Out');
avp_header('Origin-Host') ->
    diameter_gen_base_rfc6733:avp_header('Origin-Host');
avp_header('Origin-Realm') ->
    diameter_gen_base_rfc6733:avp_header('Origin-Realm');
avp_header('Origin-State-Id') ->
    diameter_gen_base_rfc6733:avp_header('Origin-State-Id');
avp_header('Product-Name') ->
    diameter_gen_base_rfc6733:avp_header('Product-Name');
avp_header('Proxy-Host') ->
    diameter_gen_base_rfc6733:avp_header('Proxy-Host');
avp_header('Proxy-Info') ->
    diameter_gen_base_rfc6733:avp_header('Proxy-Info');
avp_header('Proxy-State') ->
    diameter_gen_base_rfc6733:avp_header('Proxy-State');
avp_header('Re-Auth-Request-Type') ->
    diameter_gen_base_rfc6733:avp_header('Re-Auth-Request-Type');
avp_header('Redirect-Host') ->
    diameter_gen_base_rfc6733:avp_header('Redirect-Host');
avp_header('Redirect-Host-Usage') ->
    diameter_gen_base_rfc6733:avp_header('Redirect-Host-Usage');
avp_header('Redirect-Max-Cache-Time') ->
    diameter_gen_base_rfc6733:avp_header('Redirect-Max-Cache-Time');
avp_header('Result-Code') ->
    diameter_gen_base_rfc6733:avp_header('Result-Code');
avp_header('Route-Record') ->
    diameter_gen_base_rfc6733:avp_header('Route-Record');
avp_header('Session-Binding') ->
    diameter_gen_base_rfc6733:avp_header('Session-Binding');
avp_header('Session-Id') ->
    diameter_gen_base_rfc6733:avp_header('Session-Id');
avp_header('Session-Server-Failover') ->
    diameter_gen_base_rfc6733:avp_header('Session-Server-Failover');
avp_header('Session-Timeout') ->
    diameter_gen_base_rfc6733:avp_header('Session-Timeout');
avp_header('Supported-Vendor-Id') ->
    diameter_gen_base_rfc6733:avp_header('Supported-Vendor-Id');
avp_header('Termination-Cause') ->
    diameter_gen_base_rfc6733:avp_header('Termination-Cause');
avp_header('User-Name') ->
    diameter_gen_base_rfc6733:avp_header('User-Name');
avp_header('Vendor-Id') ->
    diameter_gen_base_rfc6733:avp_header('Vendor-Id');
avp_header('Vendor-Specific-Application-Id') ->
    diameter_gen_base_rfc6733:avp_header('Vendor-Specific-Application-Id');
avp_header(_) -> erlang:error(badarg).

avp(T, Data, '3GPP-AAA-Server-Name', Opts) ->
    diameter_types:'DiameterIdentity'(T, Data, Opts);
avp(T, Data, 'AMBR', Opts) ->
    grouped_avp(T, 'AMBR', Data, Opts);
avp(T, Data, 'APN-Configuration', Opts) ->
    grouped_avp(T, 'APN-Configuration', Data, Opts);
avp(T, Data, 'Context-Identifier', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'IMEI', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'MIP-Home-Agent-Address', Opts) ->
    diameter_types:'Address'(T, Data, Opts);
avp(T, Data, 'MIP-Home-Agent-Host', Opts) ->
    grouped_avp(T, 'MIP-Home-Agent-Host', Data, Opts);
avp(T, Data, 'MIP6-Agent-Info', Opts) ->
    grouped_avp(T, 'MIP6-Agent-Info', Data, Opts);
avp(T, Data, 'MIP6-Feature-Vector', Opts) ->
    diameter_types:'Unsigned64'(T, Data, Opts);
avp(T, Data, 'MIP6-Home-Link-Prefix', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'Max-Requested-Bandwidth-DL', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'Max-Requested-Bandwidth-UL', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'PDN-Type', _) ->
    enumerated_avp(T, 'PDN-Type', Data);
avp(T, Data, 'RAT-Type', _) ->
    enumerated_avp(T, 'RAT-Type', Data);
avp(T, Data, 'Served-Party-IP-Address', Opts) ->
    diameter_types:'Address'(T, Data, Opts);
avp(T, Data, 'Service-Selection', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'Software-Version', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'Terminal-Information', Opts) ->
    grouped_avp(T, 'Terminal-Information', Data, Opts);
avp(T, Data, 'UE-Local-IP-Address', Opts) ->
    diameter_types:'Address'(T, Data, Opts);
avp(T, Data, 'Visited-Network-Identifier', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'Accounting-Realtime-Required', Opts) ->
    avp(T,
        Data,
        'Accounting-Realtime-Required',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Accounting-Record-Number', Opts) ->
    avp(T,
        Data,
        'Accounting-Record-Number',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Accounting-Record-Type', Opts) ->
    avp(T,
        Data,
        'Accounting-Record-Type',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Accounting-Sub-Session-Id', Opts) ->
    avp(T,
        Data,
        'Accounting-Sub-Session-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Acct-Application-Id', Opts) ->
    avp(T,
        Data,
        'Acct-Application-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Acct-Interim-Interval', Opts) ->
    avp(T,
        Data,
        'Acct-Interim-Interval',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Acct-Multi-Session-Id', Opts) ->
    avp(T,
        Data,
        'Acct-Multi-Session-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Acct-Session-Id', Opts) ->
    avp(T,
        Data,
        'Acct-Session-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Auth-Application-Id', Opts) ->
    avp(T,
        Data,
        'Auth-Application-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Auth-Grace-Period', Opts) ->
    avp(T,
        Data,
        'Auth-Grace-Period',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Auth-Request-Type', Opts) ->
    avp(T,
        Data,
        'Auth-Request-Type',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Auth-Session-State', Opts) ->
    avp(T,
        Data,
        'Auth-Session-State',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Authorization-Lifetime', Opts) ->
    avp(T,
        Data,
        'Authorization-Lifetime',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Class', Opts) ->
    avp(T, Data, 'Class', Opts, diameter_gen_base_rfc6733);
avp(T, Data, 'Destination-Host', Opts) ->
    avp(T,
        Data,
        'Destination-Host',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Destination-Realm', Opts) ->
    avp(T,
        Data,
        'Destination-Realm',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Disconnect-Cause', Opts) ->
    avp(T,
        Data,
        'Disconnect-Cause',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Error-Message', Opts) ->
    avp(T,
        Data,
        'Error-Message',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Error-Reporting-Host', Opts) ->
    avp(T,
        Data,
        'Error-Reporting-Host',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Event-Timestamp', Opts) ->
    avp(T,
        Data,
        'Event-Timestamp',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Experimental-Result', Opts) ->
    grouped_avp(T, 'Experimental-Result', Data, Opts);
avp(T, Data, 'Experimental-Result-Code', Opts) ->
    avp(T,
        Data,
        'Experimental-Result-Code',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Failed-AVP', Opts) ->
    grouped_avp(T, 'Failed-AVP', Data, Opts);
avp(T, Data, 'Firmware-Revision', Opts) ->
    avp(T,
        Data,
        'Firmware-Revision',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Host-IP-Address', Opts) ->
    avp(T,
        Data,
        'Host-IP-Address',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Inband-Security-Id', Opts) ->
    avp(T,
        Data,
        'Inband-Security-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Multi-Round-Time-Out', Opts) ->
    avp(T,
        Data,
        'Multi-Round-Time-Out',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Origin-Host', Opts) ->
    avp(T,
        Data,
        'Origin-Host',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Origin-Realm', Opts) ->
    avp(T,
        Data,
        'Origin-Realm',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Origin-State-Id', Opts) ->
    avp(T,
        Data,
        'Origin-State-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Product-Name', Opts) ->
    avp(T,
        Data,
        'Product-Name',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Proxy-Host', Opts) ->
    avp(T,
        Data,
        'Proxy-Host',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Proxy-Info', Opts) ->
    grouped_avp(T, 'Proxy-Info', Data, Opts);
avp(T, Data, 'Proxy-State', Opts) ->
    avp(T,
        Data,
        'Proxy-State',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Re-Auth-Request-Type', Opts) ->
    avp(T,
        Data,
        'Re-Auth-Request-Type',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Redirect-Host', Opts) ->
    avp(T,
        Data,
        'Redirect-Host',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Redirect-Host-Usage', Opts) ->
    avp(T,
        Data,
        'Redirect-Host-Usage',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Redirect-Max-Cache-Time', Opts) ->
    avp(T,
        Data,
        'Redirect-Max-Cache-Time',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Result-Code', Opts) ->
    avp(T,
        Data,
        'Result-Code',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Route-Record', Opts) ->
    avp(T,
        Data,
        'Route-Record',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Session-Binding', Opts) ->
    avp(T,
        Data,
        'Session-Binding',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Session-Id', Opts) ->
    avp(T,
        Data,
        'Session-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Session-Server-Failover', Opts) ->
    avp(T,
        Data,
        'Session-Server-Failover',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Session-Timeout', Opts) ->
    avp(T,
        Data,
        'Session-Timeout',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Supported-Vendor-Id', Opts) ->
    avp(T,
        Data,
        'Supported-Vendor-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Termination-Cause', Opts) ->
    avp(T,
        Data,
        'Termination-Cause',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'User-Name', Opts) ->
    avp(T,
        Data,
        'User-Name',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Vendor-Id', Opts) ->
    avp(T,
        Data,
        'Vendor-Id',
        Opts,
        diameter_gen_base_rfc6733);
avp(T, Data, 'Vendor-Specific-Application-Id', Opts) ->
    grouped_avp(T,
                'Vendor-Specific-Application-Id',
                Data,
                Opts);
avp(_, _, _, _) -> erlang:error(badarg).

enumerated_avp(decode, 'RAT-Type', <<0, 0, 0, 0>>) -> 0;
enumerated_avp(encode, 'RAT-Type', 0) -> <<0, 0, 0, 0>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 0, 1>>) -> 1;
enumerated_avp(encode, 'RAT-Type', 1) -> <<0, 0, 0, 1>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 3, 236>>) ->
    1004;
enumerated_avp(encode, 'RAT-Type', 1004) ->
    <<0, 0, 3, 236>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 7, 209>>) ->
    2001;
enumerated_avp(encode, 'RAT-Type', 2001) ->
    <<0, 0, 7, 209>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 7, 211>>) ->
    2003;
enumerated_avp(encode, 'RAT-Type', 2003) ->
    <<0, 0, 7, 211>>;
enumerated_avp(decode, 'PDN-Type', <<0, 0, 0, 0>>) -> 0;
enumerated_avp(encode, 'PDN-Type', 0) -> <<0, 0, 0, 0>>;
enumerated_avp(decode, 'PDN-Type', <<0, 0, 0, 1>>) -> 1;
enumerated_avp(encode, 'PDN-Type', 1) -> <<0, 0, 0, 1>>;
enumerated_avp(decode, 'PDN-Type', <<0, 0, 0, 2>>) -> 2;
enumerated_avp(encode, 'PDN-Type', 2) -> <<0, 0, 0, 2>>;
enumerated_avp(decode, 'PDN-Type', <<0, 0, 0, 3>>) -> 3;
enumerated_avp(encode, 'PDN-Type', 3) -> <<0, 0, 0, 3>>;
enumerated_avp(decode, 'PDN-Type', <<0, 0, 0, 4>>) -> 4;
enumerated_avp(encode, 'PDN-Type', 4) -> <<0, 0, 0, 4>>;
enumerated_avp(_, _, _) -> erlang:error(badarg).

empty_value('MIP6-Agent-Info', Opts) ->
    empty_group('MIP6-Agent-Info', Opts);
empty_value('MIP-Home-Agent-Host', Opts) ->
    empty_group('MIP-Home-Agent-Host', Opts);
empty_value('APN-Configuration', Opts) ->
    empty_group('APN-Configuration', Opts);
empty_value('AMBR', Opts) -> empty_group('AMBR', Opts);
empty_value('Terminal-Information', Opts) ->
    empty_group('Terminal-Information', Opts);
empty_value('Proxy-Info', Opts) ->
    empty_group('Proxy-Info', Opts);
empty_value('Failed-AVP', Opts) ->
    empty_group('Failed-AVP', Opts);
empty_value('Experimental-Result', Opts) ->
    empty_group('Experimental-Result', Opts);
empty_value('Vendor-Specific-Application-Id', Opts) ->
    empty_group('Vendor-Specific-Application-Id', Opts);
empty_value('RAT-Type', _) -> <<0, 0, 0, 0>>;
empty_value('PDN-Type', _) -> <<0, 0, 0, 0>>;
empty_value('Disconnect-Cause', _) -> <<0, 0, 0, 0>>;
empty_value('Redirect-Host-Usage', _) -> <<0, 0, 0, 0>>;
empty_value('Auth-Request-Type', _) -> <<0, 0, 0, 0>>;
empty_value('Auth-Session-State', _) -> <<0, 0, 0, 0>>;
empty_value('Re-Auth-Request-Type', _) ->
    <<0, 0, 0, 0>>;
empty_value('Termination-Cause', _) -> <<0, 0, 0, 0>>;
empty_value('Session-Server-Failover', _) ->
    <<0, 0, 0, 0>>;
empty_value('Accounting-Record-Type', _) ->
    <<0, 0, 0, 0>>;
empty_value('Accounting-Realtime-Required', _) ->
    <<0, 0, 0, 0>>;
empty_value(Name, Opts) -> empty(Name, Opts).

dict() ->
    [1,
     {avp_types,
      [{"3GPP-AAA-Server-Name",
        318,
        "DiameterIdentity",
        "MV"},
       {"AMBR", 1435, "Grouped", "MV"},
       {"APN-Configuration", 1430, "Grouped", "MV"},
       {"Context-Identifier", 1423, "Unsigned32", "MV"},
       {"IMEI", 1402, "UTF8String", "MV"},
       {"MIP-Home-Agent-Address", 334, "Address", "M"},
       {"MIP-Home-Agent-Host", 348, "Grouped", "M"},
       {"MIP6-Agent-Info", 486, "Grouped", "M"},
       {"MIP6-Feature-Vector", 124, "Unsigned64", "M"},
       {"MIP6-Home-Link-Prefix", 125, "OctetString", "M"},
       {"Max-Requested-Bandwidth-DL", 515, "Unsigned32", "M"},
       {"Max-Requested-Bandwidth-UL", 516, "Unsigned32", "M"},
       {"PDN-Type", 1456, "Enumerated", "MV"},
       {"RAT-Type", 1032, "Enumerated", "MV"},
       {"Served-Party-IP-Address", 848, "Address", "MV"},
       {"Service-Selection", 493, "UTF8String", "M"},
       {"Software-Version", 1403, "UTF8String", "MV"},
       {"Terminal-Information", 1401, "Grouped", "MV"},
       {"UE-Local-IP-Address", 2805, "Address", "V"},
       {"Visited-Network-Identifier",
        600,
        "OctetString",
        "MV"}]},
     {avp_vendor_id, []},
     {codecs, []},
     {command_codes,
      [{275, "STR", "STA"},
       {265, "AAR", "AAA"},
       {258, "RAR", "RAA"},
       {274, "ASR", "ASA"}]},
     {custom_types, []},
     {define,
      [{"Result-Code",
        [{"DIAMETER_ERROR_USER_UNKNOWN", 5001},
         {"DIAMETER_ERROR_UNKNOWN_EPS_SUBSCRIPTION", 5420},
         {"DIAMETER_ERROR_RAT_NOT_ALLOWED", 5421},
         {"DIAMETER_ERROR_ROAMING_NOT_ALLOWED", 5004},
         {"DIAMETER_ERROR_USER_NO_APN_SUBSCRIPTION", 5451}]}]},
     {enum,
      [{"RAT-Type",
        [{"WLAN", 0},
         {"VIRTUAL", 1},
         {"EUTRAN", 1004},
         {"HRPD", 2001},
         {"EHRPD", 2003}]},
       {"PDN-Type",
        [{"IPv4", 0},
         {"IPv6", 1},
         {"IPv4v6", 2},
         {"IPv4_OR_IPv6", 3},
         {"NON_IP", 4}]}]},
     {grouped,
      [{"MIP6-Agent-Info",
        486,
        [],
        [{'*', ["MIP-Home-Agent-Address"]},
         ["MIP-Home-Agent-Host"],
         ["MIP6-Home-Link-Prefix"]]},
       {"MIP-Home-Agent-Host",
        348,
        [],
        [{"Destination-Realm"}, {"Destination-Host"}]},
       {"APN-Configuration",
        1430,
        [10415],
        [{"Context-Identifier"},
         {"PDN-Type"},
         {"Service-Selection"},
         ["AMBR"],
         {'*', ["Served-Party-IP-Address"]},
         {'*', ["AVP"]}]},
       {"AMBR",
        1435,
        [10415],
        [{"Max-Requested-Bandwidth-UL"},
         {"Max-Requested-Bandwidth-DL"}]},
       {"Terminal-Information",
        1401,
        [10415],
        [["IMEI"], ["Software-Version"]]}]},
     {id, 16777272},
     {import_avps,
      [{diameter_gen_base_rfc6733,
        [{"Accounting-Realtime-Required",
          483,
          "Enumerated",
          "M"},
         {"Accounting-Record-Number", 485, "Unsigned32", "M"},
         {"Accounting-Record-Type", 480, "Enumerated", "M"},
         {"Accounting-Sub-Session-Id", 287, "Unsigned64", "M"},
         {"Acct-Application-Id", 259, "Unsigned32", "M"},
         {"Acct-Interim-Interval", 85, "Unsigned32", "M"},
         {"Acct-Multi-Session-Id", 50, "UTF8String", "M"},
         {"Acct-Session-Id", 44, "OctetString", "M"},
         {"Auth-Application-Id", 258, "Unsigned32", "M"},
         {"Auth-Grace-Period", 276, "Unsigned32", "M"},
         {"Auth-Request-Type", 274, "Enumerated", "M"},
         {"Auth-Session-State", 277, "Enumerated", "M"},
         {"Authorization-Lifetime", 291, "Unsigned32", "M"},
         {"Class", 25, "OctetString", "M"},
         {"Destination-Host", 293, "DiameterIdentity", "M"},
         {"Destination-Realm", 283, "DiameterIdentity", "M"},
         {"Disconnect-Cause", 273, "Enumerated", "M"},
         {"Error-Message", 281, "UTF8String", []},
         {"Error-Reporting-Host", 294, "DiameterIdentity", []},
         {"Event-Timestamp", 55, "Time", "M"},
         {"Experimental-Result", 297, "Grouped", "M"},
         {"Experimental-Result-Code", 298, "Unsigned32", "M"},
         {"Failed-AVP", 279, "Grouped", "M"},
         {"Firmware-Revision", 267, "Unsigned32", []},
         {"Host-IP-Address", 257, "Address", "M"},
         {"Inband-Security-Id", 299, "Unsigned32", "M"},
         {"Multi-Round-Time-Out", 272, "Unsigned32", "M"},
         {"Origin-Host", 264, "DiameterIdentity", "M"},
         {"Origin-Realm", 296, "DiameterIdentity", "M"},
         {"Origin-State-Id", 278, "Unsigned32", "M"},
         {"Product-Name", 269, "UTF8String", []},
         {"Proxy-Host", 280, "DiameterIdentity", "M"},
         {"Proxy-Info", 284, "Grouped", "M"},
         {"Proxy-State", 33, "OctetString", "M"},
         {"Re-Auth-Request-Type", 285, "Enumerated", "M"},
         {"Redirect-Host", 292, "DiameterURI", "M"},
         {"Redirect-Host-Usage", 261, "Enumerated", "M"},
         {"Redirect-Max-Cache-Time", 262, "Unsigned32", "M"},
         {"Result-Code", 268, "Unsigned32", "M"},
         {"Route-Record", 282, "DiameterIdentity", "M"},
         {"Session-Binding", 270, "Unsigned32", "M"},
         {"Session-Id", 263, "UTF8String", "M"},
         {"Session-Server-Failover", 271, "Enumerated", "M"},
         {"Session-Timeout", 27, "Unsigned32", "M"},
         {"Supported-Vendor-Id", 265, "Unsigned32", "M"},
         {"Termination-Cause", 295, "Enumerated", "M"},
         {"User-Name", 1, "UTF8String", "M"},
         {"Vendor-Id", 266, "Unsigned32", "M"},
         {"Vendor-Specific-Application-Id",
          260,
          "Grouped",
          "M"}]}]},
     {import_enums,
      [{diameter_gen_base_rfc6733,
        [{"Disconnect-Cause",
          [{"REBOOTING", 0},
           {"BUSY", 1},
           {"DO_NOT_WANT_TO_TALK_TO_YOU", 2}]},
         {"Redirect-Host-Usage",
          [{"DONT_CACHE", 0},
           {"ALL_SESSION", 1},
           {"ALL_REALM", 2},
           {"REALM_AND_APPLICATION", 3},
           {"ALL_APPLICATION", 4},
           {"ALL_HOST", 5},
           {"ALL_USER", 6}]},
         {"Auth-Request-Type",
          [{"AUTHENTICATE_ONLY", 1},
           {"AUTHORIZE_ONLY", 2},
           {"AUTHORIZE_AUTHENTICATE", 3}]},
         {"Auth-Session-State",
          [{"STATE_MAINTAINED", 0}, {"NO_STATE_MAINTAINED", 1}]},
         {"Re-Auth-Request-Type",
          [{"AUTHORIZE_ONLY", 0}, {"AUTHORIZE_AUTHENTICATE", 1}]},
         {"Termination-Cause",
          [{"LOGOUT", 1},
           {"SERVICE_NOT_PROVIDED", 2},
           {"BAD_ANSWER", 3},
           {"ADMINISTRATIVE", 4},
           {"LINK_BROKEN", 5},
           {"AUTH_EXPIRED", 6},
           {"USER_MOVED", 7},
           {"SESSION_TIMEOUT", 8}]},
         {"Session-Server-Failover",
          [{"REFUSE_SERVICE", 0},
           {"TRY_AGAIN", 1},
           {"ALLOW_SERVICE", 2},
           {"TRY_AGAIN_ALLOW_SERVICE", 3}]},
         {"Accounting-Record-Type",
          [{"EVENT_RECORD", 1},
           {"START_RECORD", 2},
           {"INTERIM_RECORD", 3},
           {"STOP_RECORD", 4}]},
         {"Accounting-Realtime-Required",
          [{"DELIVER_AND_GRANT", 1},
           {"GRANT_AND_STORE", 2},
           {"GRANT_AND_LOSE", 3}]}]}]},
     {import_groups,
      [{diameter_gen_base_rfc6733,
        [{"Proxy-Info",
          284,
          [],
          [{"Proxy-Host"}, {"Proxy-State"}, {'*', ["AVP"]}]},
         {"Failed-AVP", 279, [], [{'*', {"AVP"}}]},
         {"Experimental-Result",
          297,
          [],
          [{"Vendor-Id"}, {"Experimental-Result-Code"}]},
         {"Vendor-Specific-Application-Id",
          260,
          [],
          [{"Vendor-Id"},
           ["Auth-Application-Id"],
           ["Acct-Application-Id"]]}]}]},
     {inherits, [{"diameter_gen_base_rfc6733", []}]},
     {messages,
      [{"AAR",
        265,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Auth-Application-Id"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"Auth-Request-Type"},
         ["Destination-Host"],
         ["User-Name"],
         ["Service-Selection"],
         ["MIP6-Agent-Info"],
         ["MIP6-Feature-Vector"],
         ["Visited-Network-Identifier"],
         ["Auth-Session-State"],
         ["RAT-Type"],
         ["UE-Local-IP-Address"],
         ["Terminal-Information"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"AAA",
        265,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Auth-Application-Id"},
         {"Result-Code"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Auth-Request-Type"},
         ["User-Name"],
         ["Session-Timeout"],
         ["MIP6-Feature-Vector"],
         ["APN-Configuration"],
         ["AMBR"],
         ["3GPP-AAA-Server-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"STR",
        275,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"Auth-Application-Id"},
         {"Termination-Cause"},
         ["Destination-Host"],
         ["User-Name"],
         ["Auth-Session-State"],
         {'*', ["Class"]},
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"STA",
        275,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Result-Code"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["User-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"ASR",
        274,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"Destination-Host"},
         {"Auth-Application-Id"},
         ["User-Name"],
         ["Auth-Session-State"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"ASA",
        274,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Result-Code"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["User-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"RAR",
        258,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"Destination-Host"},
         {"Auth-Application-Id"},
         {"Re-Auth-Request-Type"},
         ["User-Name"],
         ["Auth-Session-State"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"RAA",
        258,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Result-Code"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["User-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]}]},
     {name, "diameter_gen_s6b"},
     {prefix, "diameter_s6b"},
     {vendor, {10415, "3GPP"}}].


