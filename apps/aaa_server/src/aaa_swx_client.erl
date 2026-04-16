%%%-------------------------------------------------------------------
%%% @doc SWx Diameter client — AAA Server → HSS via DRA.
%%% Application-ID 16777265 (TS 29.273).
%%% Sends MAR/MAA, SAR/SAA; handles incoming RTR, PPR from HSS.
%%% Connects to all configured DRA replicas for redundancy.
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

-define(DNS_RETRY_INITIAL, 5000).
-define(DNS_RETRY_MAX,    60000).
-define(HEALTH_CHECK_INTERVAL, 30000).

-record(state, {
    service_started :: boolean(),
    dra_port        :: non_neg_integer() | undefined,
    transport_mod   :: module() | undefined,
    %% Per-host transport state: #{Host => {Ref | undefined, Retries}}
    transports      :: #{string() => {term() | undefined, non_neg_integer()}}
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
    DRAHosts    = aaa_config:get(dra_hosts, ["dra-diameter"]),
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
                       {dictionary, diameter_dict_swx},
                       {module, ?MODULE}]}
    ],

    case diameter:start_service(?SVC_NAME, SvcOpts) of
        ok ->
            TransMod = transport_module(Transport),
            InitTransports = maps:from_list(
                [{H, {undefined, 0}} || H <- DRAHosts]),
            State0 = #state{service_started = true,
                            dra_port        = DRAPort,
                            transport_mod   = TransMod,
                            transports      = InitTransports},
            logger:notice("SWx client: connecting to ~B DRA host(s): ~p",
                          [length(DRAHosts), DRAHosts]),
            erlang:send_after(?HEALTH_CHECK_INTERVAL, self(), health_check),
            {ok, connect_all(State0)};
        {error, Reason} ->
            logger:error("Failed to start SWx service: ~p", [Reason]),
            {ok, #state{service_started = false,
                        transports      = #{}}}
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

handle_info({retry_dra_dns, Host}, State) ->
    {noreply, try_connect_host(Host, State)};
handle_info({diameter_peer_down, PeerRef}, #state{transports = Ts} = State) ->
    Host = host_for_peer_ref(PeerRef, Ts),
    case Host of
        "unknown" ->
            logger:warning("SWx peer down: could not map PeerRef to host"),
            {noreply, State};
        _ ->
            erlang:send_after(15000, self(), {re_resolve_dra, Host}),
            {noreply, State}
    end;
handle_info({re_resolve_dra, Host}, #state{transports = Ts} = State) ->
    case maps:find(Host, Ts) of
        {ok, {OldRef, _}} when OldRef =/= undefined ->
            logger:notice("SWx: re-resolving DRA ~s after peer down", [Host]),
            catch diameter:remove_transport(?SVC_NAME, OldRef),
            NewTs = Ts#{Host => {undefined, 0}},
            {noreply, try_connect_host(Host, State#state{transports = NewTs})};
        _ ->
            {noreply, try_connect_host(Host, State)}
    end;
handle_info({force_reconnect, Host}, #state{transports = Ts} = State) ->
    case maps:find(Host, Ts) of
        {ok, {OldRef, _}} when OldRef =/= undefined ->
            logger:warning("SWx: forcing reconnect to DRA ~s (stale IP detected)", [Host]),
            catch diameter:remove_transport(?SVC_NAME, OldRef),
            NewTs = Ts#{Host => {undefined, 0}},
            {noreply, try_connect_host(Host, State#state{transports = NewTs})};
        _ ->
            {noreply, try_connect_host(Host, State)}
    end;
handle_info(health_check, #state{service_started = true} = State) ->
    check_transport_health(State),
    erlang:send_after(?HEALTH_CHECK_INTERVAL, self(), health_check),
    {noreply, State};
handle_info(health_check, State) ->
    erlang:send_after(?HEALTH_CHECK_INTERVAL, self(), health_check),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #state{service_started = true}) ->
    diameter:stop_service(?SVC_NAME), ok;
terminate(_Reason, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%====================================================================
%% Diameter callbacks
%%====================================================================

peer_up(_SvcName, {_PeerRef, Caps}, State) ->
    RemoteHost = case Caps of
        #diameter_caps{origin_host = {_, RH}} -> RH;
        _ -> <<"unknown">>
    end,
    logger:notice("SWx peer up: ~s (DRA/HSS reachable)", [RemoteHost]),
    aaa_metrics:gauge_inc(swx_peers),
    State.

peer_down(_SvcName, {PeerRef, _Caps}, State) ->
    logger:warning("SWx peer down"),
    aaa_metrics:gauge_dec(swx_peers),
    ?SERVER ! {diameter_peer_down, PeerRef},
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

connect_all(State) ->
    Hosts = maps:keys(State#state.transports),
    lists:foldl(fun(H, S) -> try_connect_host(H, S) end, State, Hosts).

%% Periodic health check: inspect diameter transport state and log
%% connection issues that the framework handles silently (e.g. CER
%% rejected with 4003 ELECTION_LOST due to Origin-Host collision).
check_transport_health(#state{transports = Ts}) ->
    case diameter:service_info(?SVC_NAME, transport) of
        TInfos when is_list(TInfos) ->
            lists:foreach(fun(I) -> check_single_transport(I, Ts) end, TInfos);
        _ ->
            ok
    end.

check_single_transport(Info, Transports) when is_list(Info) ->
    case proplists:get_value(type, Info) of
        connect ->
            Ref = proplists:get_value(ref, Info),
            Opts = proplists:get_value(options, Info, []),
            TC = proplists:get_value(transport_config, Opts, []),
            RAddr = proplists:get_value(raddr, TC, undefined),
            WD = proplists:get_value(watchdog, Info, undefined),
            Stats = proplists:get_value(statistics, Info, []),
            WDState = case WD of
                {_, _, S} -> S;
                _ -> unknown
            end,
            case WDState of
                okay -> ok;
                _ ->
                    check_cer_result(RAddr, WDState, Stats),
                    check_stale_ip(RAddr, Ref, Transports)
            end;
        _ ->
            ok
    end;
check_single_transport(_, _) ->
    ok.

check_cer_result(RAddr, WDState, Stats) ->
    ElectionLost = [N || {{{0, 257, 0}, recv, {'Result-Code', 4003}}, N} <- Stats],
    case ElectionLost of
        [Count] when Count > 0 ->
            logger:warning(
                "SWx transport to DRA ~s stuck: watchdog=~p, "
                "CER rejected ~B times with Result-Code 4003 "
                "(ELECTION_LOST). Probable cause: duplicate "
                "Origin-Host — verify AAA_ORIGIN_HOST is unique "
                "per pod (current: ~s)",
                [format_ip(RAddr), WDState, Count,
                 aaa_config:get(origin_host, "unknown")]);
        _ ->
            OtherErrors = [{RC, N} ||
                {{{0, 257, 0}, recv, {'Result-Code', RC}}, N} <- Stats,
                RC =/= 2001],
            case OtherErrors of
                [] when WDState =/= okay ->
                    logger:warning(
                        "SWx transport to DRA ~s: watchdog=~p, "
                        "no successful CER/CEA yet",
                        [format_ip(RAddr), WDState]);
                [{RC, N} | _] ->
                    logger:warning(
                        "SWx transport to DRA ~s: watchdog=~p, "
                        "CER rejected ~B times with Result-Code ~B",
                        [format_ip(RAddr), WDState, N, RC]);
                _ ->
                    ok
            end
    end.

check_stale_ip(undefined, _Ref, _Transports) -> ok;
check_stale_ip(RAddr, Ref, Transports) ->
    Host = host_for_ref(Ref, Transports),
    case Host of
        undefined -> ok;
        _ ->
            case resolve_host(Host) of
                {ok, CurrentIP} when CurrentIP =/= RAddr ->
                    logger:warning("SWx transport ~p: stale IP ~p for host ~s "
                                   "(current DNS: ~p), forcing reconnect",
                                   [Ref, RAddr, Host, CurrentIP]),
                    self() ! {force_reconnect, Host};
                _ -> ok
            end
    end.

host_for_ref(Ref, Transports) ->
    case [H || {H, {R, _}} <- maps:to_list(Transports), R =:= Ref] of
        [Host | _] -> Host;
        [] -> undefined
    end.

format_ip({A, B, C, D}) ->
    io_lib:format("~B.~B.~B.~B", [A, B, C, D]);
format_ip(Other) ->
    io_lib:format("~p", [Other]).

try_connect_host(Host, #state{dra_port = DRAPort, transport_mod = TransMod,
                               transports = Ts} = State) ->
    {_OldRef, Retries} = maps:get(Host, Ts, {undefined, 0}),
    case resolve_host(Host) of
        {ok, DRAIP} ->
            case diameter:add_transport(?SVC_NAME, {connect, [
                {transport_module, TransMod},
                {transport_config, [{raddr, DRAIP},
                                    {rport, DRAPort},
                                    {ip, {0,0,0,0}}]},
                {reconnect_timer, 5000}
            ]}) of
                {ok, Ref} ->
                    logger:notice("SWx transport added -> DRA ~s:~p", [Host, DRAPort]),
                    State#state{transports = Ts#{Host => {Ref, 0}}};
                {error, TErr} ->
                    Delay = retry_delay(Retries),
                    logger:error("SWx transport to DRA ~s:~p failed: ~p, "
                                 "retrying in ~Bms",
                                 [Host, DRAPort, TErr, Delay]),
                    erlang:send_after(Delay, self(), {retry_dra_dns, Host}),
                    State#state{transports = Ts#{Host => {undefined, Retries + 1}}}
            end;
        {error, _} ->
            Delay = retry_delay(Retries),
            logger:warning("Cannot resolve DRA host ~s, retrying in ~Bms "
                           "(attempt ~B)",
                           [Host, Delay, Retries + 1]),
            erlang:send_after(Delay, self(), {retry_dra_dns, Host}),
            State#state{transports = Ts#{Host => {undefined, Retries + 1}}}
    end.

%% Map a Diameter PeerRef (from peer_down callback) to the configured
%% DRA hostname via diameter:service_info transport introspection.
host_for_peer_ref(PeerRef, Transports) ->
    TInfos = diameter:service_info(?SVC_NAME, transport),
    case find_transport_ref(TInfos, PeerRef) of
        {ok, TransRef} ->
            case [H || {H, {R, _}} <- maps:to_list(Transports),
                       R =:= TransRef] of
                [Host | _] -> Host;
                [] -> "unknown"
            end;
        error -> "unknown"
    end.

find_transport_ref(TInfos, PeerRef) ->
    Matches = [proplists:get_value(ref, Info)
               || Info <- TInfos,
                  is_list(Info),
                  match_peer_ref(Info, PeerRef)],
    case Matches of
        [Ref | _] -> {ok, Ref};
        [] -> error
    end.

match_peer_ref(Info, PeerRef) ->
    case proplists:get_value(peer, Info) of
        {_, PRef} when PRef =:= PeerRef -> true;
        _ ->
            case proplists:get_value(accept, Info) of
                Accept when is_list(Accept) ->
                    lists:any(fun(A) ->
                        case proplists:get_value(peer, A) of
                            {_, PR} when PR =:= PeerRef -> true;
                            _ -> false
                        end
                    end, Accept);
                _ -> false
            end
    end.

retry_delay(Retries) ->
    min(?DNS_RETRY_INITIAL bsl min(Retries, 4), ?DNS_RETRY_MAX).

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
