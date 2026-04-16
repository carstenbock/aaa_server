%%%-------------------------------------------------------------------
%%% @doc SWm Diameter server — terminates requests from ePDG.
%%% Application-ID 16777264 (TS 29.273).
%%% Handles DER/DEA (EAP relay) and AAR/AAA (authorization).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_swm_server).

-behaviour(gen_server).

-include_lib("diameter/include/diameter.hrl").

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% Diameter application callbacks
-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

-define(SERVER, ?MODULE).
-define(SVC_NAME, aaa_swm_svc).
-define(SWM_APP_ID, 16777264).
-define(VENDOR_3GPP, 10415).

-record(state, {
    service_started :: boolean()
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    OriginHost  = aaa_config:get(origin_host, "aaa.localdomain"),
    OriginRealm = aaa_config:get(origin_realm, "localdomain"),
    SwmPort     = aaa_config:get(swm_port, 3868),
    Transport   = aaa_config:get(swm_transport, "tcp"),

    diameter:start(),

    SvcOpts = [
        {'Origin-Host',  list_to_binary(OriginHost)},
        {'Origin-Realm', list_to_binary(OriginRealm)},
        {'Vendor-Id', ?VENDOR_3GPP},
        {'Product-Name', "volte.io AAA Server"},
        {'Auth-Application-Id', [?SWM_APP_ID]},
        {'Supported-Vendor-Id', [?VENDOR_3GPP]},
        {string_decode, false},
        {application, [{alias, swm},
                       {dictionary, diameter_dict_swm},
                       {module, ?MODULE}]}
    ],

    case diameter:start_service(?SVC_NAME, SvcOpts) of
        ok ->
            TransMod = transport_module(Transport),
            diameter:add_transport(?SVC_NAME, {listen, [
                {transport_module, TransMod},
                {transport_config, [{reuseaddr, true},
                                    {ip, {0,0,0,0}},
                                    {port, SwmPort}]}
            ]}),
            logger:notice("SWm server listening on port ~B (~s)", [SwmPort, Transport]),
            {ok, #state{service_started = true}};
        {error, Reason} ->
            logger:error("Failed to start SWm service: ~p", [Reason]),
            {ok, #state{service_started = false}}
    end.

handle_call(_Req, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #state{service_started = true}) ->
    diameter:stop_service(?SVC_NAME), ok;
terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%% Diameter callbacks
%%====================================================================

peer_up(_SvcName, {_PeerRef, Caps}, State) ->
    RemoteHost = case Caps of
        #diameter_caps{origin_host = {_, RH}} -> RH;
        _ -> <<"unknown">>
    end,
    logger:notice("SWm peer up: ~s (ePDG connected)", [RemoteHost]),
    aaa_metrics:gauge_inc(swm_peers),
    State.

peer_down(_SvcName, {_PeerRef, Caps}, State) ->
    RemoteHost = case Caps of
        #diameter_caps{origin_host = {_, RH}} -> RH;
        _ -> <<"unknown">>
    end,
    logger:notice("SWm peer down: ~s", [RemoteHost]),
    aaa_metrics:gauge_dec(swm_peers),
    State.

pick_peer([Peer | _], _, _SvcName, _State) ->
    {ok, Peer}.

prepare_request(Pkt, _SvcName, _Peer) ->
    {send, Pkt}.

prepare_retransmit(Pkt, SvcName, Peer) ->
    prepare_request(Pkt, SvcName, Peer).

handle_answer(#diameter_packet{msg = Msg}, _Req, _SvcName, _Peer) ->
    {ok, Msg}.

handle_error(Reason, _Req, _SvcName, _Peer) ->
    {error, Reason}.

%% Handle incoming DER (Diameter-EAP-Request) from ePDG
handle_request(#diameter_packet{msg = Msg}, _SvcName, _Peer) ->
    aaa_metrics:inc(swm_requests_total),
    case Msg of
        [_CmdName | AVPs] ->
            handle_swm_request(AVPs);
        _ ->
            discard
    end.

%%====================================================================
%% Request handling
%%====================================================================

handle_swm_request(AVPs) ->
    IMSI = proplists:get_value('User-Name', AVPs, <<>>),
    AuthType = proplists:get_value('Auth-Request-Type', AVPs, 0),

    case AuthType of
        3 -> handle_der(IMSI, AVPs);
        1 -> handle_aar(IMSI, AVPs);
        _ -> discard
    end.

%% DER: relay EAP to HSS via SWx MAR
handle_der(IMSI, AVPs) ->
    EAPPayload = proplists:get_value('EAP-Payload', AVPs, <<>>),

    case aaa_eap_relay:process_eap(IMSI, EAPPayload) of
        {ok, #{eap_payload := ResponseEAP, result := success}} ->
            aaa_metrics:inc(swm_auth_success_total),
            {reply, ['DEA' | [{'Result-Code', 2001},
                               {'EAP-Payload', ResponseEAP}]]};
        {ok, #{eap_payload := ChallengeEAP, result := challenge}} ->
            {reply, ['DEA' | [{'Result-Code', 1001},
                               {'EAP-Payload', ChallengeEAP}]]};
        {error, _Reason} ->
            aaa_metrics:inc(swm_auth_failure_total),
            {reply, ['DEA' | [{'Result-Code', 4181}]]}
    end.

%% AAR: authorize session
handle_aar(IMSI, _AVPs) ->
    case aaa_swx_client:server_assignment_request(IMSI,
            #{assignment_type => 1}) of
        {ok, #{non_3gpp_user_data := UserData}} ->
            {reply, ['AAA' | [{'Result-Code', 2001} | UserData]]};
        {error, _} ->
            {reply, ['AAA' | [{'Result-Code', 5012}]]}
    end.

%%====================================================================
%% Internal
%%====================================================================

transport_module("sctp") -> diameter_sctp;
transport_module("tcp")  -> diameter_tcp;
transport_module(_)      -> diameter_tcp.
