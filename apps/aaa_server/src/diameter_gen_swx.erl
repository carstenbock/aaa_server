%% -------------------------------------------------------------------
%% This is a generated file.
%% -------------------------------------------------------------------

-module(diameter_gen_swx).

-moduledoc(false).

-compile({parse_transform, diameter_exprecs}).

-compile(nowarn_unused_function).

-dialyzer(no_return).

-export_records([diameter_swx_MAR,
                 diameter_swx_MAA,
                 diameter_swx_SAR,
                 diameter_swx_SAA,
                 diameter_swx_RTR,
                 diameter_swx_RTA,
                 diameter_swx_PPR,
                 diameter_swx_PPA,
                 'diameter_swx_SIP-Auth-Data-Item',
                 'diameter_swx_Deregistration-Reason',
                 'diameter_swx_APN-Configuration',
                 diameter_swx_AMBR,
                 'diameter_swx_Non-3GPP-User-Data',
                 'diameter_swx_Terminal-Information',
                 'diameter_swx_Proxy-Info',
                 'diameter_swx_Failed-AVP',
                 'diameter_swx_Experimental-Result',
                 'diameter_swx_Vendor-Specific-Application-Id']).

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

-record('diameter_swx_Proxy-Info',
        {'Proxy-Host', 'Proxy-State', 'AVP' = []}).

-record('diameter_swx_Failed-AVP', {'AVP' = []}).

-record('diameter_swx_Experimental-Result',
        {'Vendor-Id', 'Experimental-Result-Code'}).

-record('diameter_swx_Vendor-Specific-Application-Id',
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

name() -> diameter_gen_swx.

id() -> 16777265.

vendor_id() -> 10415.

vendor_name() -> '3GPP'.

msg_name(301, true) -> 'SAR';
msg_name(301, false) -> 'SAA';
msg_name(303, true) -> 'MAR';
msg_name(303, false) -> 'MAA';
msg_name(304, true) -> 'RTR';
msg_name(304, false) -> 'RTA';
msg_name(305, true) -> 'PPR';
msg_name(305, false) -> 'PPA';
msg_name(_, _) -> ''.

msg_header('MAR') -> {303, 192, 16777265};
msg_header('MAA') -> {303, 64, 16777265};
msg_header('SAR') -> {301, 192, 16777265};
msg_header('SAA') -> {301, 64, 16777265};
msg_header('RTR') -> {304, 192, 16777265};
msg_header('RTA') -> {304, 64, 16777265};
msg_header('PPR') -> {305, 192, 16777265};
msg_header('PPA') -> {305, 64, 16777265};
msg_header(_) -> erlang:error(badarg).

rec2msg(diameter_swx_MAR) -> 'MAR';
rec2msg(diameter_swx_MAA) -> 'MAA';
rec2msg(diameter_swx_SAR) -> 'SAR';
rec2msg(diameter_swx_SAA) -> 'SAA';
rec2msg(diameter_swx_RTR) -> 'RTR';
rec2msg(diameter_swx_RTA) -> 'RTA';
rec2msg(diameter_swx_PPR) -> 'PPR';
rec2msg(diameter_swx_PPA) -> 'PPA';
rec2msg(_) -> erlang:error(badarg).

msg2rec('MAR') -> diameter_swx_MAR;
msg2rec('MAA') -> diameter_swx_MAA;
msg2rec('SAR') -> diameter_swx_SAR;
msg2rec('SAA') -> diameter_swx_SAA;
msg2rec('RTR') -> diameter_swx_RTR;
msg2rec('RTA') -> diameter_swx_RTA;
msg2rec('PPR') -> diameter_swx_PPR;
msg2rec('PPA') -> diameter_swx_PPA;
msg2rec(_) -> erlang:error(badarg).

name2rec('SIP-Auth-Data-Item') ->
    'diameter_swx_SIP-Auth-Data-Item';
name2rec('Deregistration-Reason') ->
    'diameter_swx_Deregistration-Reason';
name2rec('APN-Configuration') ->
    'diameter_swx_APN-Configuration';
name2rec('AMBR') -> diameter_swx_AMBR;
name2rec('Non-3GPP-User-Data') ->
    'diameter_swx_Non-3GPP-User-Data';
name2rec('Terminal-Information') ->
    'diameter_swx_Terminal-Information';
name2rec('Proxy-Info') -> 'diameter_swx_Proxy-Info';
name2rec('Failed-AVP') -> 'diameter_swx_Failed-AVP';
name2rec('Experimental-Result') ->
    'diameter_swx_Experimental-Result';
name2rec('Vendor-Specific-Application-Id') ->
    'diameter_swx_Vendor-Specific-Application-Id';
name2rec(T) -> msg2rec(T).

avp_name(318, 10415) ->
    {'3GPP-AAA-Server-Name', 'DiameterIdentity'};
avp_name(1435, 10415) -> {'AMBR', 'Grouped'};
avp_name(1503, 10415) -> {'AN-Trusted', 'Enumerated'};
avp_name(1430, 10415) ->
    {'APN-Configuration', 'Grouped'};
avp_name(1263, 10415) ->
    {'Access-Network-Identifier', 'OctetString'};
avp_name(625, 10415) ->
    {'Confidentiality-Key', 'OctetString'};
avp_name(1423, 10415) ->
    {'Context-Identifier', 'Unsigned32'};
avp_name(615, 10415) ->
    {'Deregistration-Reason', 'Grouped'};
avp_name(1402, 10415) -> {'IMEI', 'UTF8String'};
avp_name(626, 10415) ->
    {'Integrity-Key', 'OctetString'};
avp_name(515, undefined) ->
    {'Max-Requested-Bandwidth-DL', 'Unsigned32'};
avp_name(516, undefined) ->
    {'Max-Requested-Bandwidth-UL', 'Unsigned32'};
avp_name(1501, 10415) ->
    {'Non-3GPP-IP-Access', 'Enumerated'};
avp_name(1502, 10415) ->
    {'Non-3GPP-IP-Access-APN', 'Enumerated'};
avp_name(1500, 10415) ->
    {'Non-3GPP-User-Data', 'Grouped'};
avp_name(1456, 10415) -> {'PDN-Type', 'Enumerated'};
avp_name(1032, 10415) -> {'RAT-Type', 'Enumerated'};
avp_name(616, 10415) -> {'Reason-Code', 'Enumerated'};
avp_name(617, 10415) -> {'Reason-Info', 'UTF8String'};
avp_name(612, 10415) ->
    {'SIP-Auth-Data-Item', 'Grouped'};
avp_name(609, 10415) ->
    {'SIP-Authenticate', 'OctetString'};
avp_name(611, 10415) ->
    {'SIP-Authentication-Context', 'OctetString'};
avp_name(608, 10415) ->
    {'SIP-Authentication-Scheme', 'UTF8String'};
avp_name(610, 10415) ->
    {'SIP-Authorization', 'OctetString'};
avp_name(613, 10415) ->
    {'SIP-Item-Number', 'Unsigned32'};
avp_name(607, 10415) ->
    {'SIP-Number-Auth-Items', 'Unsigned32'};
avp_name(848, 10415) ->
    {'Served-Party-IP-Address', 'Address'};
avp_name(614, 10415) ->
    {'Server-Assignment-Type', 'Enumerated'};
avp_name(493, undefined) ->
    {'Service-Selection', 'UTF8String'};
avp_name(1403, 10415) ->
    {'Software-Version', 'UTF8String'};
avp_name(1401, 10415) ->
    {'Terminal-Information', 'Grouped'};
avp_name(606, 10415) -> {'User-Data', 'OctetString'};
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

avp_arity('MAR') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'User-Name', 1},
     {'SIP-Auth-Data-Item', 1},
     {'SIP-Number-Auth-Items', 1},
     {'Destination-Host', {0, 1}},
     {'3GPP-AAA-Server-Name', {0, 1}},
     {'RAT-Type', {0, 1}},
     {'AN-Trusted', {0, 1}},
     {'Access-Network-Identifier', {0, 1}},
     {'Terminal-Information', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('MAA') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Result-Code', {0, 1}},
     {'Experimental-Result', {0, 1}},
     {'User-Name', {0, 1}},
     {'SIP-Number-Auth-Items', {0, 1}},
     {'SIP-Auth-Data-Item', {0, '*'}},
     {'3GPP-AAA-Server-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('SAR') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Realm', 1},
     {'User-Name', 1},
     {'Server-Assignment-Type', 1},
     {'Destination-Host', {0, 1}},
     {'3GPP-AAA-Server-Name', {0, 1}},
     {'Service-Selection', {0, 1}},
     {'Context-Identifier', {0, 1}},
     {'RAT-Type', {0, 1}},
     {'Visited-Network-Identifier', {0, 1}},
     {'Terminal-Information', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('SAA') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Result-Code', {0, 1}},
     {'Experimental-Result', {0, 1}},
     {'User-Name', {0, 1}},
     {'User-Data', {0, 1}},
     {'Non-3GPP-User-Data', {0, 1}},
     {'3GPP-AAA-Server-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('RTR') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Host', 1},
     {'Destination-Realm', 1},
     {'User-Name', 1},
     {'Deregistration-Reason', 1},
     {'Service-Selection', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('RTA') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Result-Code', {0, 1}},
     {'Experimental-Result', {0, 1}},
     {'User-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('PPR') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Destination-Host', 1},
     {'Destination-Realm', 1},
     {'User-Name', 1},
     {'User-Data', {0, 1}},
     {'Non-3GPP-User-Data', {0, 1}},
     {'Proxy-Info', {0, '*'}},
     {'Route-Record', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('PPA') ->
    [{'Session-Id', 1},
     {'Vendor-Specific-Application-Id', 1},
     {'Auth-Session-State', 1},
     {'Origin-Host', 1},
     {'Origin-Realm', 1},
     {'Result-Code', {0, 1}},
     {'Experimental-Result', {0, 1}},
     {'User-Name', {0, 1}},
     {'Error-Message', {0, 1}},
     {'Error-Reporting-Host', {0, 1}},
     {'Failed-AVP', {0, 1}},
     {'Redirect-Host', {0, '*'}},
     {'Proxy-Info', {0, '*'}},
     {'AVP', {0, '*'}}];
avp_arity('SIP-Auth-Data-Item') ->
    [{'SIP-Item-Number', {0, 1}},
     {'SIP-Authentication-Scheme', {0, 1}},
     {'SIP-Authenticate', {0, 1}},
     {'SIP-Authorization', {0, 1}},
     {'SIP-Authentication-Context', {0, 1}},
     {'Confidentiality-Key', {0, 1}},
     {'Integrity-Key', {0, 1}},
     {'AVP', {0, '*'}}];
avp_arity('Deregistration-Reason') ->
    [{'Reason-Code', 1}, {'Reason-Info', {0, 1}}];
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
avp_arity('Non-3GPP-User-Data') ->
    [{'Non-3GPP-IP-Access', {0, 1}},
     {'Non-3GPP-IP-Access-APN', {0, 1}},
     {'RAT-Type', {0, 1}},
     {'Session-Timeout', {0, 1}},
     {'AMBR', {0, 1}},
     {'APN-Configuration', {0, '*'}},
     {'AVP', {0, '*'}}];
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

avp_arity('MAR', 'Session-Id') -> 1;
avp_arity('MAR', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('MAR', 'Auth-Session-State') -> 1;
avp_arity('MAR', 'Origin-Host') -> 1;
avp_arity('MAR', 'Origin-Realm') -> 1;
avp_arity('MAR', 'Destination-Realm') -> 1;
avp_arity('MAR', 'User-Name') -> 1;
avp_arity('MAR', 'SIP-Auth-Data-Item') -> 1;
avp_arity('MAR', 'SIP-Number-Auth-Items') -> 1;
avp_arity('MAR', 'Destination-Host') -> {0, 1};
avp_arity('MAR', '3GPP-AAA-Server-Name') -> {0, 1};
avp_arity('MAR', 'RAT-Type') -> {0, 1};
avp_arity('MAR', 'AN-Trusted') -> {0, 1};
avp_arity('MAR', 'Access-Network-Identifier') -> {0, 1};
avp_arity('MAR', 'Terminal-Information') -> {0, 1};
avp_arity('MAR', 'Proxy-Info') -> {0, '*'};
avp_arity('MAR', 'Route-Record') -> {0, '*'};
avp_arity('MAR', 'AVP') -> {0, '*'};
avp_arity('MAA', 'Session-Id') -> 1;
avp_arity('MAA', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('MAA', 'Auth-Session-State') -> 1;
avp_arity('MAA', 'Origin-Host') -> 1;
avp_arity('MAA', 'Origin-Realm') -> 1;
avp_arity('MAA', 'Result-Code') -> {0, 1};
avp_arity('MAA', 'Experimental-Result') -> {0, 1};
avp_arity('MAA', 'User-Name') -> {0, 1};
avp_arity('MAA', 'SIP-Number-Auth-Items') -> {0, 1};
avp_arity('MAA', 'SIP-Auth-Data-Item') -> {0, '*'};
avp_arity('MAA', '3GPP-AAA-Server-Name') -> {0, 1};
avp_arity('MAA', 'Error-Message') -> {0, 1};
avp_arity('MAA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('MAA', 'Failed-AVP') -> {0, 1};
avp_arity('MAA', 'Redirect-Host') -> {0, '*'};
avp_arity('MAA', 'Proxy-Info') -> {0, '*'};
avp_arity('MAA', 'AVP') -> {0, '*'};
avp_arity('SAR', 'Session-Id') -> 1;
avp_arity('SAR', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('SAR', 'Auth-Session-State') -> 1;
avp_arity('SAR', 'Origin-Host') -> 1;
avp_arity('SAR', 'Origin-Realm') -> 1;
avp_arity('SAR', 'Destination-Realm') -> 1;
avp_arity('SAR', 'User-Name') -> 1;
avp_arity('SAR', 'Server-Assignment-Type') -> 1;
avp_arity('SAR', 'Destination-Host') -> {0, 1};
avp_arity('SAR', '3GPP-AAA-Server-Name') -> {0, 1};
avp_arity('SAR', 'Service-Selection') -> {0, 1};
avp_arity('SAR', 'Context-Identifier') -> {0, 1};
avp_arity('SAR', 'RAT-Type') -> {0, 1};
avp_arity('SAR', 'Visited-Network-Identifier') ->
    {0, 1};
avp_arity('SAR', 'Terminal-Information') -> {0, 1};
avp_arity('SAR', 'Proxy-Info') -> {0, '*'};
avp_arity('SAR', 'Route-Record') -> {0, '*'};
avp_arity('SAR', 'AVP') -> {0, '*'};
avp_arity('SAA', 'Session-Id') -> 1;
avp_arity('SAA', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('SAA', 'Auth-Session-State') -> 1;
avp_arity('SAA', 'Origin-Host') -> 1;
avp_arity('SAA', 'Origin-Realm') -> 1;
avp_arity('SAA', 'Result-Code') -> {0, 1};
avp_arity('SAA', 'Experimental-Result') -> {0, 1};
avp_arity('SAA', 'User-Name') -> {0, 1};
avp_arity('SAA', 'User-Data') -> {0, 1};
avp_arity('SAA', 'Non-3GPP-User-Data') -> {0, 1};
avp_arity('SAA', '3GPP-AAA-Server-Name') -> {0, 1};
avp_arity('SAA', 'Error-Message') -> {0, 1};
avp_arity('SAA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('SAA', 'Failed-AVP') -> {0, 1};
avp_arity('SAA', 'Redirect-Host') -> {0, '*'};
avp_arity('SAA', 'Proxy-Info') -> {0, '*'};
avp_arity('SAA', 'AVP') -> {0, '*'};
avp_arity('RTR', 'Session-Id') -> 1;
avp_arity('RTR', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('RTR', 'Auth-Session-State') -> 1;
avp_arity('RTR', 'Origin-Host') -> 1;
avp_arity('RTR', 'Origin-Realm') -> 1;
avp_arity('RTR', 'Destination-Host') -> 1;
avp_arity('RTR', 'Destination-Realm') -> 1;
avp_arity('RTR', 'User-Name') -> 1;
avp_arity('RTR', 'Deregistration-Reason') -> 1;
avp_arity('RTR', 'Service-Selection') -> {0, 1};
avp_arity('RTR', 'Proxy-Info') -> {0, '*'};
avp_arity('RTR', 'Route-Record') -> {0, '*'};
avp_arity('RTR', 'AVP') -> {0, '*'};
avp_arity('RTA', 'Session-Id') -> 1;
avp_arity('RTA', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('RTA', 'Auth-Session-State') -> 1;
avp_arity('RTA', 'Origin-Host') -> 1;
avp_arity('RTA', 'Origin-Realm') -> 1;
avp_arity('RTA', 'Result-Code') -> {0, 1};
avp_arity('RTA', 'Experimental-Result') -> {0, 1};
avp_arity('RTA', 'User-Name') -> {0, 1};
avp_arity('RTA', 'Error-Message') -> {0, 1};
avp_arity('RTA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('RTA', 'Failed-AVP') -> {0, 1};
avp_arity('RTA', 'Redirect-Host') -> {0, '*'};
avp_arity('RTA', 'Proxy-Info') -> {0, '*'};
avp_arity('RTA', 'AVP') -> {0, '*'};
avp_arity('PPR', 'Session-Id') -> 1;
avp_arity('PPR', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('PPR', 'Auth-Session-State') -> 1;
avp_arity('PPR', 'Origin-Host') -> 1;
avp_arity('PPR', 'Origin-Realm') -> 1;
avp_arity('PPR', 'Destination-Host') -> 1;
avp_arity('PPR', 'Destination-Realm') -> 1;
avp_arity('PPR', 'User-Name') -> 1;
avp_arity('PPR', 'User-Data') -> {0, 1};
avp_arity('PPR', 'Non-3GPP-User-Data') -> {0, 1};
avp_arity('PPR', 'Proxy-Info') -> {0, '*'};
avp_arity('PPR', 'Route-Record') -> {0, '*'};
avp_arity('PPR', 'AVP') -> {0, '*'};
avp_arity('PPA', 'Session-Id') -> 1;
avp_arity('PPA', 'Vendor-Specific-Application-Id') -> 1;
avp_arity('PPA', 'Auth-Session-State') -> 1;
avp_arity('PPA', 'Origin-Host') -> 1;
avp_arity('PPA', 'Origin-Realm') -> 1;
avp_arity('PPA', 'Result-Code') -> {0, 1};
avp_arity('PPA', 'Experimental-Result') -> {0, 1};
avp_arity('PPA', 'User-Name') -> {0, 1};
avp_arity('PPA', 'Error-Message') -> {0, 1};
avp_arity('PPA', 'Error-Reporting-Host') -> {0, 1};
avp_arity('PPA', 'Failed-AVP') -> {0, 1};
avp_arity('PPA', 'Redirect-Host') -> {0, '*'};
avp_arity('PPA', 'Proxy-Info') -> {0, '*'};
avp_arity('PPA', 'AVP') -> {0, '*'};
avp_arity('SIP-Auth-Data-Item', 'SIP-Item-Number') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item',
          'SIP-Authentication-Scheme') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item', 'SIP-Authenticate') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item', 'SIP-Authorization') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item',
          'SIP-Authentication-Context') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item',
          'Confidentiality-Key') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item', 'Integrity-Key') ->
    {0, 1};
avp_arity('SIP-Auth-Data-Item', 'AVP') -> {0, '*'};
avp_arity('Deregistration-Reason', 'Reason-Code') -> 1;
avp_arity('Deregistration-Reason', 'Reason-Info') ->
    {0, 1};
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
avp_arity('Non-3GPP-User-Data', 'Non-3GPP-IP-Access') ->
    {0, 1};
avp_arity('Non-3GPP-User-Data',
          'Non-3GPP-IP-Access-APN') ->
    {0, 1};
avp_arity('Non-3GPP-User-Data', 'RAT-Type') -> {0, 1};
avp_arity('Non-3GPP-User-Data', 'Session-Timeout') ->
    {0, 1};
avp_arity('Non-3GPP-User-Data', 'AMBR') -> {0, 1};
avp_arity('Non-3GPP-User-Data', 'APN-Configuration') ->
    {0, '*'};
avp_arity('Non-3GPP-User-Data', 'AVP') -> {0, '*'};
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
avp_header('AN-Trusted') -> {1503, 128, 10415};
avp_header('APN-Configuration') -> {1430, 192, 10415};
avp_header('Access-Network-Identifier') ->
    {1263, 192, 10415};
avp_header('Confidentiality-Key') -> {625, 192, 10415};
avp_header('Context-Identifier') -> {1423, 192, 10415};
avp_header('Deregistration-Reason') ->
    {615, 192, 10415};
avp_header('IMEI') -> {1402, 192, 10415};
avp_header('Integrity-Key') -> {626, 192, 10415};
avp_header('Max-Requested-Bandwidth-DL') ->
    {515, 64, undefined};
avp_header('Max-Requested-Bandwidth-UL') ->
    {516, 64, undefined};
avp_header('Non-3GPP-IP-Access') -> {1501, 128, 10415};
avp_header('Non-3GPP-IP-Access-APN') ->
    {1502, 128, 10415};
avp_header('Non-3GPP-User-Data') -> {1500, 128, 10415};
avp_header('PDN-Type') -> {1456, 192, 10415};
avp_header('RAT-Type') -> {1032, 192, 10415};
avp_header('Reason-Code') -> {616, 192, 10415};
avp_header('Reason-Info') -> {617, 192, 10415};
avp_header('SIP-Auth-Data-Item') -> {612, 192, 10415};
avp_header('SIP-Authenticate') -> {609, 192, 10415};
avp_header('SIP-Authentication-Context') ->
    {611, 192, 10415};
avp_header('SIP-Authentication-Scheme') ->
    {608, 192, 10415};
avp_header('SIP-Authorization') -> {610, 192, 10415};
avp_header('SIP-Item-Number') -> {613, 192, 10415};
avp_header('SIP-Number-Auth-Items') ->
    {607, 192, 10415};
avp_header('Served-Party-IP-Address') ->
    {848, 192, 10415};
avp_header('Server-Assignment-Type') ->
    {614, 192, 10415};
avp_header('Service-Selection') -> {493, 64, undefined};
avp_header('Software-Version') -> {1403, 192, 10415};
avp_header('Terminal-Information') ->
    {1401, 192, 10415};
avp_header('User-Data') -> {606, 192, 10415};
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
avp(T, Data, 'AN-Trusted', _) ->
    enumerated_avp(T, 'AN-Trusted', Data);
avp(T, Data, 'APN-Configuration', Opts) ->
    grouped_avp(T, 'APN-Configuration', Data, Opts);
avp(T, Data, 'Access-Network-Identifier', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'Confidentiality-Key', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'Context-Identifier', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'Deregistration-Reason', Opts) ->
    grouped_avp(T, 'Deregistration-Reason', Data, Opts);
avp(T, Data, 'IMEI', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'Integrity-Key', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'Max-Requested-Bandwidth-DL', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'Max-Requested-Bandwidth-UL', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'Non-3GPP-IP-Access', _) ->
    enumerated_avp(T, 'Non-3GPP-IP-Access', Data);
avp(T, Data, 'Non-3GPP-IP-Access-APN', _) ->
    enumerated_avp(T, 'Non-3GPP-IP-Access-APN', Data);
avp(T, Data, 'Non-3GPP-User-Data', Opts) ->
    grouped_avp(T, 'Non-3GPP-User-Data', Data, Opts);
avp(T, Data, 'PDN-Type', _) ->
    enumerated_avp(T, 'PDN-Type', Data);
avp(T, Data, 'RAT-Type', _) ->
    enumerated_avp(T, 'RAT-Type', Data);
avp(T, Data, 'Reason-Code', _) ->
    enumerated_avp(T, 'Reason-Code', Data);
avp(T, Data, 'Reason-Info', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'SIP-Auth-Data-Item', Opts) ->
    grouped_avp(T, 'SIP-Auth-Data-Item', Data, Opts);
avp(T, Data, 'SIP-Authenticate', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'SIP-Authentication-Context', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'SIP-Authentication-Scheme', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'SIP-Authorization', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
avp(T, Data, 'SIP-Item-Number', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'SIP-Number-Auth-Items', Opts) ->
    diameter_types:'Unsigned32'(T, Data, Opts);
avp(T, Data, 'Served-Party-IP-Address', Opts) ->
    diameter_types:'Address'(T, Data, Opts);
avp(T, Data, 'Server-Assignment-Type', _) ->
    enumerated_avp(T, 'Server-Assignment-Type', Data);
avp(T, Data, 'Service-Selection', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'Software-Version', Opts) ->
    diameter_types:'UTF8String'(T, Data, Opts);
avp(T, Data, 'Terminal-Information', Opts) ->
    grouped_avp(T, 'Terminal-Information', Data, Opts);
avp(T, Data, 'User-Data', Opts) ->
    diameter_types:'OctetString'(T, Data, Opts);
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

enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Server-Assignment-Type', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Server-Assignment-Type', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Server-Assignment-Type', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Server-Assignment-Type', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 4>>) ->
    4;
enumerated_avp(encode, 'Server-Assignment-Type', 4) ->
    <<0, 0, 0, 4>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 5>>) ->
    5;
enumerated_avp(encode, 'Server-Assignment-Type', 5) ->
    <<0, 0, 0, 5>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 6>>) ->
    6;
enumerated_avp(encode, 'Server-Assignment-Type', 6) ->
    <<0, 0, 0, 6>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 7>>) ->
    7;
enumerated_avp(encode, 'Server-Assignment-Type', 7) ->
    <<0, 0, 0, 7>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 8>>) ->
    8;
enumerated_avp(encode, 'Server-Assignment-Type', 8) ->
    <<0, 0, 0, 8>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 9>>) ->
    9;
enumerated_avp(encode, 'Server-Assignment-Type', 9) ->
    <<0, 0, 0, 9>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 10>>) ->
    10;
enumerated_avp(encode, 'Server-Assignment-Type', 10) ->
    <<0, 0, 0, 10>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 11>>) ->
    11;
enumerated_avp(encode, 'Server-Assignment-Type', 11) ->
    <<0, 0, 0, 11>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 12>>) ->
    12;
enumerated_avp(encode, 'Server-Assignment-Type', 12) ->
    <<0, 0, 0, 12>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 13>>) ->
    13;
enumerated_avp(encode, 'Server-Assignment-Type', 13) ->
    <<0, 0, 0, 13>>;
enumerated_avp(decode, 'Server-Assignment-Type',
               <<0, 0, 0, 14>>) ->
    14;
enumerated_avp(encode, 'Server-Assignment-Type', 14) ->
    <<0, 0, 0, 14>>;
enumerated_avp(decode, 'Reason-Code', <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Reason-Code', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Reason-Code', <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Reason-Code', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Reason-Code', <<0, 0, 0, 2>>) ->
    2;
enumerated_avp(encode, 'Reason-Code', 2) ->
    <<0, 0, 0, 2>>;
enumerated_avp(decode, 'Reason-Code', <<0, 0, 0, 3>>) ->
    3;
enumerated_avp(encode, 'Reason-Code', 3) ->
    <<0, 0, 0, 3>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 0, 0>>) -> 0;
enumerated_avp(encode, 'RAT-Type', 0) -> <<0, 0, 0, 0>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 0, 1>>) -> 1;
enumerated_avp(encode, 'RAT-Type', 1) -> <<0, 0, 0, 1>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 3, 232>>) ->
    1000;
enumerated_avp(encode, 'RAT-Type', 1000) ->
    <<0, 0, 3, 232>>;
enumerated_avp(decode, 'RAT-Type', <<0, 0, 3, 233>>) ->
    1001;
enumerated_avp(encode, 'RAT-Type', 1001) ->
    <<0, 0, 3, 233>>;
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
enumerated_avp(decode, 'AN-Trusted', <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'AN-Trusted', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'AN-Trusted', <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'AN-Trusted', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Non-3GPP-IP-Access',
               <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Non-3GPP-IP-Access', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Non-3GPP-IP-Access',
               <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Non-3GPP-IP-Access', 1) ->
    <<0, 0, 0, 1>>;
enumerated_avp(decode, 'Non-3GPP-IP-Access-APN',
               <<0, 0, 0, 0>>) ->
    0;
enumerated_avp(encode, 'Non-3GPP-IP-Access-APN', 0) ->
    <<0, 0, 0, 0>>;
enumerated_avp(decode, 'Non-3GPP-IP-Access-APN',
               <<0, 0, 0, 1>>) ->
    1;
enumerated_avp(encode, 'Non-3GPP-IP-Access-APN', 1) ->
    <<0, 0, 0, 1>>;
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

empty_value('SIP-Auth-Data-Item', Opts) ->
    empty_group('SIP-Auth-Data-Item', Opts);
empty_value('Deregistration-Reason', Opts) ->
    empty_group('Deregistration-Reason', Opts);
empty_value('APN-Configuration', Opts) ->
    empty_group('APN-Configuration', Opts);
empty_value('AMBR', Opts) -> empty_group('AMBR', Opts);
empty_value('Non-3GPP-User-Data', Opts) ->
    empty_group('Non-3GPP-User-Data', Opts);
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
empty_value('Server-Assignment-Type', _) ->
    <<0, 0, 0, 0>>;
empty_value('Reason-Code', _) -> <<0, 0, 0, 0>>;
empty_value('RAT-Type', _) -> <<0, 0, 0, 0>>;
empty_value('AN-Trusted', _) -> <<0, 0, 0, 0>>;
empty_value('Non-3GPP-IP-Access', _) -> <<0, 0, 0, 0>>;
empty_value('Non-3GPP-IP-Access-APN', _) ->
    <<0, 0, 0, 0>>;
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
       {"AN-Trusted", 1503, "Enumerated", "V"},
       {"APN-Configuration", 1430, "Grouped", "MV"},
       {"Access-Network-Identifier",
        1263,
        "OctetString",
        "MV"},
       {"Confidentiality-Key", 625, "OctetString", "MV"},
       {"Context-Identifier", 1423, "Unsigned32", "MV"},
       {"Deregistration-Reason", 615, "Grouped", "MV"},
       {"IMEI", 1402, "UTF8String", "MV"},
       {"Integrity-Key", 626, "OctetString", "MV"},
       {"Max-Requested-Bandwidth-DL", 515, "Unsigned32", "M"},
       {"Max-Requested-Bandwidth-UL", 516, "Unsigned32", "M"},
       {"Non-3GPP-IP-Access", 1501, "Enumerated", "V"},
       {"Non-3GPP-IP-Access-APN", 1502, "Enumerated", "V"},
       {"Non-3GPP-User-Data", 1500, "Grouped", "V"},
       {"PDN-Type", 1456, "Enumerated", "MV"},
       {"RAT-Type", 1032, "Enumerated", "MV"},
       {"Reason-Code", 616, "Enumerated", "MV"},
       {"Reason-Info", 617, "UTF8String", "MV"},
       {"SIP-Auth-Data-Item", 612, "Grouped", "MV"},
       {"SIP-Authenticate", 609, "OctetString", "MV"},
       {"SIP-Authentication-Context",
        611,
        "OctetString",
        "MV"},
       {"SIP-Authentication-Scheme", 608, "UTF8String", "MV"},
       {"SIP-Authorization", 610, "OctetString", "MV"},
       {"SIP-Item-Number", 613, "Unsigned32", "MV"},
       {"SIP-Number-Auth-Items", 607, "Unsigned32", "MV"},
       {"Served-Party-IP-Address", 848, "Address", "MV"},
       {"Server-Assignment-Type", 614, "Enumerated", "MV"},
       {"Service-Selection", 493, "UTF8String", "M"},
       {"Software-Version", 1403, "UTF8String", "MV"},
       {"Terminal-Information", 1401, "Grouped", "MV"},
       {"User-Data", 606, "OctetString", "MV"},
       {"Visited-Network-Identifier",
        600,
        "OctetString",
        "MV"}]},
     {avp_vendor_id, []},
     {codecs, []},
     {command_codes,
      [{301, "SAR", "SAA"},
       {303, "MAR", "MAA"},
       {304, "RTR", "RTA"},
       {305, "PPR", "PPA"}]},
     {custom_types, []},
     {define,
      [{"Result-Code",
        [{"DIAMETER_ERROR_USER_UNKNOWN", 5001},
         {"DIAMETER_ERROR_IDENTITIES_DONT_MATCH", 5002},
         {"DIAMETER_ERROR_IDENTITY_NOT_REGISTERED", 5003},
         {"DIAMETER_ERROR_ROAMING_NOT_ALLOWED", 5004},
         {"DIAMETER_ERROR_IDENTITY_ALREADY_REGISTERED", 5005},
         {"DIAMETER_ERROR_AUTH_SCHEME_NOT_SUPPORTED", 5006},
         {"DIAMETER_AUTHENTICATION_DATA_UNAVAILABLE", 4181},
         {"DIAMETER_ERROR_USER_NO_NON_3GPP_SUBSCRIPTION", 5450},
         {"DIAMETER_ERROR_USER_NO_APN_SUBSCRIPTION", 5451},
         {"DIAMETER_ERROR_RAT_TYPE_NOT_ALLOWED", 5452}]}]},
     {enum,
      [{"Server-Assignment-Type",
        [{"NO_ASSIGNMENT", 0},
         {"REGISTRATION", 1},
         {"RE_REGISTRATION", 2},
         {"UNREGISTERED_USER", 3},
         {"TIMEOUT_DEREGISTRATION", 4},
         {"USER_DEREGISTRATION", 5},
         {"TIMEOUT_DEREGISTRATION_STORE_SERVER_NAME", 6},
         {"USER_DEREGISTRATION_STORE_SERVER_NAME", 7},
         {"ADMINISTRATIVE_DEREGISTRATION", 8},
         {"AUTHENTICATION_FAILURE", 9},
         {"AUTHENTICATION_TIMEOUT", 10},
         {"DEREGISTRATION_TOO_MUCH_DATA", 11},
         {"AAA_USER_DATA_REQUEST", 12},
         {"PGW_UPDATE", 13},
         {"RESTORATION", 14}]},
       {"Reason-Code",
        [{"PERMANENT_TERMINATION", 0},
         {"NEW_SERVER_ASSIGNED", 1},
         {"SERVER_CHANGE", 2},
         {"REMOVE_S_CSCF", 3}]},
       {"RAT-Type",
        [{"WLAN", 0},
         {"VIRTUAL", 1},
         {"UTRAN", 1000},
         {"GERAN", 1001},
         {"EUTRAN", 1004},
         {"HRPD", 2001},
         {"EHRPD", 2003}]},
       {"AN-Trusted", [{"TRUSTED", 0}, {"UNTRUSTED", 1}]},
       {"Non-3GPP-IP-Access",
        [{"NON_3GPP_SUBSCRIPTION_ALLOWED", 0},
         {"NON_3GPP_SUBSCRIPTION_BARRED", 1}]},
       {"Non-3GPP-IP-Access-APN",
        [{"NON_3GPP_APNS_ENABLE", 0},
         {"NON_3GPP_APNS_DISABLE", 1}]},
       {"PDN-Type",
        [{"IPv4", 0},
         {"IPv6", 1},
         {"IPv4v6", 2},
         {"IPv4_OR_IPv6", 3},
         {"NON_IP", 4}]}]},
     {grouped,
      [{"SIP-Auth-Data-Item",
        612,
        [10415],
        [["SIP-Item-Number"],
         ["SIP-Authentication-Scheme"],
         ["SIP-Authenticate"],
         ["SIP-Authorization"],
         ["SIP-Authentication-Context"],
         ["Confidentiality-Key"],
         ["Integrity-Key"],
         {'*', ["AVP"]}]},
       {"Deregistration-Reason",
        615,
        [10415],
        [{"Reason-Code"}, ["Reason-Info"]]},
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
       {"Non-3GPP-User-Data",
        1500,
        [10415],
        [["Non-3GPP-IP-Access"],
         ["Non-3GPP-IP-Access-APN"],
         ["RAT-Type"],
         ["Session-Timeout"],
         ["AMBR"],
         {'*', ["APN-Configuration"]},
         {'*', ["AVP"]}]},
       {"Terminal-Information",
        1401,
        [10415],
        [["IMEI"], ["Software-Version"]]}]},
     {id, 16777265},
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
      [{"MAR",
        303,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"User-Name"},
         {"SIP-Auth-Data-Item"},
         {"SIP-Number-Auth-Items"},
         ["Destination-Host"],
         ["3GPP-AAA-Server-Name"],
         ["RAT-Type"],
         ["AN-Trusted"],
         ["Access-Network-Identifier"],
         ["Terminal-Information"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"MAA",
        303,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["Result-Code"],
         ["Experimental-Result"],
         ["User-Name"],
         ["SIP-Number-Auth-Items"],
         {'*', ["SIP-Auth-Data-Item"]},
         ["3GPP-AAA-Server-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"SAR",
        301,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Realm"},
         {"User-Name"},
         {"Server-Assignment-Type"},
         ["Destination-Host"],
         ["3GPP-AAA-Server-Name"],
         ["Service-Selection"],
         ["Context-Identifier"],
         ["RAT-Type"],
         ["Visited-Network-Identifier"],
         ["Terminal-Information"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"SAA",
        301,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["Result-Code"],
         ["Experimental-Result"],
         ["User-Name"],
         ["User-Data"],
         ["Non-3GPP-User-Data"],
         ["3GPP-AAA-Server-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"RTR",
        304,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Host"},
         {"Destination-Realm"},
         {"User-Name"},
         {"Deregistration-Reason"},
         ["Service-Selection"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"RTA",
        304,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["Result-Code"],
         ["Experimental-Result"],
         ["User-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]},
       {"PPR",
        305,
        ['REQ', 'PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         {"Destination-Host"},
         {"Destination-Realm"},
         {"User-Name"},
         ["User-Data"],
         ["Non-3GPP-User-Data"],
         {'*', ["Proxy-Info"]},
         {'*', ["Route-Record"]},
         {'*', ["AVP"]}]},
       {"PPA",
        305,
        ['PXY'],
        [],
        [{{"Session-Id"}},
         {"Vendor-Specific-Application-Id"},
         {"Auth-Session-State"},
         {"Origin-Host"},
         {"Origin-Realm"},
         ["Result-Code"],
         ["Experimental-Result"],
         ["User-Name"],
         ["Error-Message"],
         ["Error-Reporting-Host"],
         ["Failed-AVP"],
         {'*', ["Redirect-Host"]},
         {'*', ["Proxy-Info"]},
         {'*', ["AVP"]}]}]},
     {name, "diameter_gen_swx"},
     {prefix, "diameter_swx"},
     {vendor, {10415, "3GPP"}}].


