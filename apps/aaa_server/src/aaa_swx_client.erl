%%%-------------------------------------------------------------------
%%% @doc SWx Diameter client — AAA Server → HSS via DRA.
%%% Application-ID 16777265 (TS 29.273).
%%% Sends MAR/MAA, SAR/SAA; handles incoming RTR, PPR from HSS.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_swx_client).

-behaviour(gen_server).

-include_lib("diameter/include/diameter.hrl").

-export([start_link/0,
         multimedia_auth_request/2,
         server_assignment_request/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% Diameter application callbacks
-export([peer_up/3, peer_down/3, pick_peer/4,
         prepare_request/3, prepare_retransmit/3,
         handle_answer/4, handle_error/4, handle_request/3]).

-define(SERVER, ?MODULE).
-define(SVC_NAME, aaa_swx_svc).
-define(SWX_APP_ID, 16777265).
-define(VENDOR_3GPP, 10415).

-record(state, {
    service_started :: boolean()
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% @doc Send MAR to HSS to retrieve EAP-AKA' auth vectors.
-spec multimedia_auth_request(binary(), map()) -> {ok, map()} | {error, term()}.
multimedia_auth_request(IMSI, Opts) ->
    gen_server:call(?SERVER, {mar, IMSI, Opts}, 15000).

%% @doc Send SAR to HSS for server assignment / user data retrieval.
-spec server_assignment_request(binary(), map()) -> {ok, map()} | {error, term()}.
server_assignment_request(IMSI, Opts) ->
    gen_server:call(?SERVER, {sar, IMSI, Opts}, 15000).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    OriginHost  = aaa_config:get(origin_host, "aaa.localdomain"),
    OriginRealm = aaa_config:get(origin_realm, "localdomain"),
    DRAHost     = aaa_config:get(dra_host, "dra-diameter"),
    DRAPort     = aaa_config:get(dra_port, 3868),
    Transport   = aaa_config:get(dra_transport, "tcp"),

    diameter:start(),

    SvcOpts = [
        {'Origin-Host',  list_to_binary(OriginHost)},
        {'Origin-Realm', list_to_binary(OriginRealm)},
        {'Vendor-Id', ?VENDOR_3GPP},
        {'Product-Name', "volte.io AAA Server"},
        {'Auth-Application-Id', [?SWX_APP_ID]},
        {'Supported-Vendor-Id', [?VENDOR_3GPP]},
        {string_decode, false},
        {application, [{alias, swx},
                       {dictionary, diameter_gen_base_rfc6733},
                       {module, ?MODULE}]}
    ],

    case diameter:start_service(?SVC_NAME, SvcOpts) of
        ok ->
            TransMod = transport_module(Transport),
            case resolve_host(DRAHost) of
                {ok, DRAIP} ->
                    diameter:add_transport(?SVC_NAME, {connect, [
                        {transport_module, TransMod},
                        {transport_config, [{raddr, DRAIP},
                                            {rport, DRAPort},
                                            {ip, {0,0,0,0}}]},
                        {reconnect_timer, 5000}
                    ]}),
                    logger:info("SWx client → DRA ~s:~p", [DRAHost, DRAPort]);
                {error, _} ->
                    logger:warning("Cannot resolve DRA host ~s", [DRAHost])
            end,
            {ok, #state{service_started = true}};
        {error, Reason} ->
            logger:error("Failed to start SWx service: ~p", [Reason]),
            {ok, #state{service_started = false}}
    end.

handle_call({mar, IMSI, Opts}, _From, #state{service_started = true} = State) ->
    NumVectors = maps:get(num_vectors, Opts, 1),
    SessionId = generate_session_id(),

    Msg = ['MAR',
           {'Session-Id', SessionId},
           {'User-Name', IMSI},
           {'SIP-Number-Auth-Items', NumVectors},
           {'Auth-Session-State', 0}],

    Result = case diameter:call(?SVC_NAME, swx, Msg, []) of
        {ok, Answer} ->
            aaa_metrics:inc(swx_mar_total),
            parse_maa(Answer);
        {error, R} ->
            aaa_metrics:inc(swx_errors_total),
            {error, R}
    end,
    {reply, Result, State};

handle_call({sar, IMSI, Opts}, _From, #state{service_started = true} = State) ->
    AssignmentType = maps:get(assignment_type, Opts, 1),
    SessionId = generate_session_id(),

    Msg = ['SAR',
           {'Session-Id', SessionId},
           {'User-Name', IMSI},
           {'Server-Assignment-Type', AssignmentType},
           {'Auth-Session-State', 0}],

    Result = case diameter:call(?SVC_NAME, swx, Msg, []) of
        {ok, Answer} ->
            aaa_metrics:inc(swx_sar_total),
            parse_saa(Answer);
        {error, R} ->
            aaa_metrics:inc(swx_errors_total),
            {error, R}
    end,
    {reply, Result, State};

handle_call(_, _From, #state{service_started = false} = State) ->
    {reply, {error, diameter_not_started}, State};

handle_call(_Req, _From, State) ->
    {reply, {error, unknown}, State}.

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
    logger:info("SWx peer up (DRA/HSS reachable)"),
    aaa_metrics:gauge_inc(swx_peers),
    State.

peer_down(_SvcName, _Peer, State) ->
    logger:warning("SWx peer down"),
    aaa_metrics:gauge_dec(swx_peers),
    State.

pick_peer([Peer | _], _, _SvcName, _State) ->
    {ok, Peer}.

prepare_request(#diameter_packet{msg = Msg} = Pkt, _SvcName, {_, Caps}) ->
    #diameter_caps{origin_host = {OH, _}, origin_realm = {OR, _}} = Caps,
    NewMsg = setelement(2, Msg, [{'Origin-Host', OH}, {'Origin-Realm', OR}
                                  | element(2, Msg)]),
    {send, Pkt#diameter_packet{msg = NewMsg}}.

prepare_retransmit(Pkt, SvcName, Peer) ->
    prepare_request(Pkt, SvcName, Peer).

handle_answer(#diameter_packet{msg = Msg}, _Req, _SvcName, _Peer) ->
    {ok, Msg}.

handle_error(Reason, _Req, _SvcName, _Peer) ->
    {error, Reason}.

%% Handle incoming RTR/PPR from HSS
handle_request(#diameter_packet{msg = Msg}, _SvcName, _Peer) ->
    case Msg of
        ['RTR' | AVPs] ->
            IMSI = proplists:get_value('User-Name', AVPs, <<>>),
            logger:info("SWx RTR received for IMSI ~s", [IMSI]),
            aaa_session_mgr:handle_deregistration(IMSI),
            {reply, ['RTA' | [{'Result-Code', 2001}]]};
        ['PPR' | AVPs] ->
            IMSI = proplists:get_value('User-Name', AVPs, <<>>),
            logger:info("SWx PPR received for IMSI ~s", [IMSI]),
            aaa_session_mgr:handle_profile_push(IMSI, AVPs),
            {reply, ['PPA' | [{'Result-Code', 2001}]]};
        _ ->
            discard
    end.

%%====================================================================
%% Internal
%%====================================================================

parse_maa(Answer) when is_list(Answer) ->
    ResultCode = proplists:get_value('Result-Code', tl(Answer), 0),
    case ResultCode of
        2001 ->
            AuthItems = proplists:get_all_values('SIP-Auth-Data-Item', tl(Answer)),
            Vectors = [parse_auth_item(I) || I <- AuthItems],
            {ok, #{result_code => 2001, auth_vectors => Vectors}};
        Code ->
            {error, {diameter_error, Code}}
    end;
parse_maa(_) ->
    {error, invalid_answer}.

parse_saa(Answer) when is_list(Answer) ->
    ResultCode = proplists:get_value('Result-Code', tl(Answer), 0),
    case ResultCode of
        2001 ->
            UserData = proplists:get_value('Non-3GPP-User-Data', tl(Answer), []),
            {ok, #{result_code => 2001, non_3gpp_user_data => UserData}};
        Code ->
            {error, {diameter_error, Code}}
    end;
parse_saa(_) ->
    {error, invalid_answer}.

parse_auth_item(Item) when is_list(Item) ->
    #{rand => proplists:get_value('SIP-Authenticate', Item, <<>>),
      autn => proplists:get_value('SIP-Authorization', Item, <<>>),
      xres => proplists:get_value('SIP-Authentication-Info', Item, <<>>),
      ck   => proplists:get_value('Confidentiality-Key', Item, <<>>),
      ik   => proplists:get_value('Integrity-Key', Item, <<>>)};
parse_auth_item(_) ->
    #{}.

generate_session_id() ->
    TS = erlang:system_time(microsecond),
    Host = aaa_config:get(origin_host, "aaa"),
    list_to_binary(io_lib:format("~s;~B;swx", [Host, TS])).

transport_module("sctp") -> diameter_sctp;
transport_module("tcp")  -> diameter_tcp;
transport_module(_)      -> diameter_tcp.

resolve_host(Host) ->
    case inet:getaddr(Host, inet) of
        {ok, IP} -> {ok, IP};
        {error, _} ->
            case inet:getaddr(list_to_atom(Host), inet) of
                {ok, IP} -> {ok, IP};
                Err -> Err
            end
    end.
