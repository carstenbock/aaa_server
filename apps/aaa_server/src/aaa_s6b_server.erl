%%%-------------------------------------------------------------------
%%% @doc S6b Diameter server — terminates requests from PGW/SMF.
%%% Application-ID 16777272 (TS 29.273).
%%% Handles AAR/AAA (authorization) and STR/STA (session termination).
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_s6b_server).

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
-define(SVC_NAME, aaa_s6b_svc).
-define(S6B_APP_ID, 16777272).
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
    S6bPort     = aaa_config:get(s6b_port, 3869),
    Transport   = aaa_config:get(s6b_transport, "tcp"),

    diameter:start(),

    SvcOpts = [
        {'Origin-Host',  list_to_binary(OriginHost)},
        {'Origin-Realm', list_to_binary(OriginRealm)},
        {'Vendor-Id', ?VENDOR_3GPP},
        {'Product-Name', "volte.io AAA Server"},
        {'Auth-Application-Id', [?S6B_APP_ID]},
        {'Supported-Vendor-Id', [?VENDOR_3GPP]},
        {string_decode, false},
        {application, [{alias, s6b},
                       {dictionary, diameter_dict_s6b},
                       {module, ?MODULE}]}
    ],

    case diameter:start_service(?SVC_NAME, SvcOpts) of
        ok ->
            TransMod = transport_module(Transport),
            diameter:add_transport(?SVC_NAME, {listen, [
                {transport_module, TransMod},
                {transport_config, [{reuseaddr, true},
                                    {ip, {0,0,0,0}},
                                    {port, S6bPort}]}
            ]}),
            logger:info("S6b server listening on port ~p (~s)", [S6bPort, Transport]),
            {ok, #state{service_started = true}};
        {error, Reason} ->
            logger:error("Failed to start S6b service: ~p", [Reason]),
            {ok, #state{service_started = false}}
    end.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, #state{service_started = true}) ->
    diameter:stop_service(?SVC_NAME), ok;
terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%====================================================================
%% Diameter callbacks
%%====================================================================

peer_up(_SvcName, _Peer, State) ->
    logger:info("S6b peer up (PGW connected)"),
    aaa_metrics:gauge_inc(s6b_peers),
    State.

peer_down(_SvcName, _Peer, State) ->
    logger:warning("S6b peer down"),
    aaa_metrics:gauge_dec(s6b_peers),
    State.

pick_peer([Peer | _], _, _SvcName, _State) -> {ok, Peer}.
prepare_request(Pkt, _SvcName, _Peer) -> {send, Pkt}.
prepare_retransmit(Pkt, SvcName, Peer) -> prepare_request(Pkt, SvcName, Peer).
handle_answer(#diameter_packet{msg = Msg}, _Req, _SvcName, _Peer) -> {ok, Msg}.
handle_error(Reason, _Req, _SvcName, _Peer) -> {error, Reason}.

handle_request(#diameter_packet{msg = Msg}, _SvcName, _Peer) ->
    aaa_metrics:inc(s6b_requests_total),
    case Msg of
        ['AAR' | AVPs] -> handle_aar(AVPs);
        ['STR' | AVPs] -> handle_str(AVPs);
        ['RAR' | AVPs] -> handle_rar(AVPs);
        ['ASR' | AVPs] -> handle_asr(AVPs);
        _ -> discard
    end.

%%====================================================================
%% S6b request handlers
%%====================================================================

%% AAR: authorize PDN session from PGW
handle_aar(AVPs) ->
    IMSI = proplists:get_value('User-Name', AVPs, <<>>),
    APN  = proplists:get_value('Service-Selection', AVPs, <<"ims">>),
    logger:debug("S6b AAR: IMSI=~s APN=~s", [IMSI, APN]),

    case aaa_session_mgr:authorize_session(IMSI, APN) of
        ok ->
            aaa_metrics:inc(s6b_auth_success_total),
            {reply, ['AAA' | [{'Result-Code', 2001}]]};
        {error, _} ->
            aaa_metrics:inc(s6b_auth_failure_total),
            {reply, ['AAA' | [{'Result-Code', 5012}]]}
    end.

%% STR: terminate session from PGW
handle_str(AVPs) ->
    SessionId = proplists:get_value('Session-Id', AVPs, <<>>),
    logger:debug("S6b STR: session=~s", [SessionId]),
    aaa_session_mgr:terminate_session(SessionId),
    {reply, ['STA' | [{'Result-Code', 2001}]]}.

%% RAR: re-authorization (AAA-initiated)
handle_rar(_AVPs) ->
    {reply, ['RAA' | [{'Result-Code', 2001}]]}.

%% ASR: abort session (AAA-initiated)
handle_asr(_AVPs) ->
    {reply, ['ASA' | [{'Result-Code', 2001}]]}.

%%====================================================================
%% Internal
%%====================================================================

transport_module("sctp") -> diameter_sctp;
transport_module("tcp")  -> diameter_tcp;
transport_module(_)      -> diameter_tcp.
