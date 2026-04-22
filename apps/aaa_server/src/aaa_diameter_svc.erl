%%%-------------------------------------------------------------------
%%% @doc Unified Diameter service — owns the single Diameter service
%%% instance that advertises all four 3GPP auth applications
%%% (SWm / SWx / S6b / STa) on a single CER/CEA peer exchange.
%%%
%%% Per TS 29.273, a DRA / HSS peer may relay traffic for multiple
%%% applications (SWx + S6b, say) across one transport connection, so
%%% the base Diameter service must advertise every Auth-Application-Id
%%% that we support on a given peer.
%%%
%%% Transports:
%%%   * SWm listener  (port AAA_SWM_PORT) — ePDG connects
%%%   * STa listener  (port AAA_STA_PORT) — trusted WLAN AN connects
%%%   * S6b listener  (port AAA_S6B_PORT) — PGW connects
%%%   * SWx connect   (to each DRA_HOSTS, port DRA_PORT) — AAA ↔ HSS
%%%
%%% Each listener configures its `capabilities` such that only the
%%% relevant Auth-Application-Id is advertised on the corresponding
%%% transport, while the service itself carries all applications.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_diameter_svc).

-behaviour(gen_server).

-include_lib("diameter/include/diameter.hrl").
-include_lib("diameter/include/diameter_gen_base_rfc6733.hrl").

-export([start_link/0,
         service_name/0,
         swx_peer_count/0,
         listener_status/0,
         trigger_reconnect_all/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SVC,        aaa_svc).
-define(VENDOR_3GPP, 10415).

-define(SWM_APP_ID, 16777264).
-define(SWX_APP_ID, 16777265).
-define(S6B_APP_ID, 16777272).
-define(STA_APP_ID, 16777250).

-define(FIRMWARE_REVISION, 11).

-define(HEALTH_INTERVAL, 30000).

-record(state, {
    started :: boolean(),
    origin_host :: binary(),
    origin_realm :: binary(),
    listeners = #{} :: #{atom() => term()},
    sta_enabled :: boolean(),
    dra_hosts = [] :: [string()],
    dra_port :: non_neg_integer() | undefined,
    dra_transport_mod :: module() | undefined,
    swx_transports = #{} :: #{string() => {term() | undefined, non_neg_integer()}}
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec service_name() -> atom().
service_name() -> ?SVC.

-spec swx_peer_count() -> non_neg_integer().
swx_peer_count() ->
    case catch diameter:service_info(?SVC, connections) of
        Conns when is_list(Conns) ->
            length([C || C <- Conns]);
        _ -> 0
    end.

-spec listener_status() -> #{atom() => ok | down}.
listener_status() ->
    gen_server:call(?MODULE, listener_status, 5000).

-spec trigger_reconnect_all() -> ok.
trigger_reconnect_all() ->
    gen_server:cast(?MODULE, reconnect_all).

%%====================================================================
%% gen_server
%%====================================================================

init([]) ->
    diameter:start(),
    %% Ensure the generated codec modules are loaded before diameter
    %% tries to resolve the application dictionary.
    lists:foreach(fun code:ensure_loaded/1,
        [diameter_gen_swm, diameter_gen_swx,
         diameter_gen_s6b, diameter_gen_sta]),

    OriginHost  = to_bin(aaa_config:get(origin_host, "aaa.localdomain")),
    OriginRealm = to_bin(aaa_config:get(origin_realm, "localdomain")),
    StaEnabled  = aaa_config:get(sta_enabled, false),

    SvcOpts = service_options(OriginHost, OriginRealm, StaEnabled),
    case diameter:start_service(?SVC, SvcOpts) of
        ok ->
            S0 = #state{started = true,
                        origin_host = OriginHost,
                        origin_realm = OriginRealm,
                        sta_enabled = StaEnabled},
            S1 = start_listeners(S0),
            S2 = start_swx_transports(S1),
            erlang:send_after(?HEALTH_INTERVAL, self(), health_check),
            {ok, S2};
        {error, Reason} ->
            logger:error("Failed to start Diameter service ~p: ~p",
                         [?SVC, Reason]),
            {ok, #state{started = false,
                        origin_host = OriginHost,
                        origin_realm = OriginRealm,
                        sta_enabled = StaEnabled}}
    end.

handle_call(listener_status, _From, #state{listeners = L} = State) ->
    {reply, L, State};
handle_call(_Req, _From, State) -> {reply, ok, State}.

handle_cast(reconnect_all, State) ->
    NewState = lists:foldl(fun(H, S) -> try_connect_swx(H, S) end,
                           State, State#state.dra_hosts),
    {noreply, NewState};
handle_cast(_Msg, State) -> {noreply, State}.

handle_info({retry_swx, Host}, State) ->
    {noreply, try_connect_swx(Host, State)};
handle_info(health_check, State) ->
    aaa_metrics:gauge_set(swx_peers, swx_peer_count()),
    erlang:send_after(?HEALTH_INTERVAL, self(), health_check),
    {noreply, State};
handle_info(_, State) -> {noreply, State}.

terminate(_Reason, #state{started = true}) ->
    diameter:stop_service(?SVC), ok;
terminate(_, _) -> ok.

code_change(_, S, _) -> {ok, S}.

%%====================================================================
%% Service / listeners / transports
%%====================================================================

service_options(OH, OR, StaEnabled) ->
    AuthIds = [?SWM_APP_ID, ?SWX_APP_ID, ?S6B_APP_ID]
        ++ case StaEnabled of true -> [?STA_APP_ID]; _ -> [] end,
    OriginStateId = erlang:system_time(second),
    [{'Origin-Host',  OH},
     {'Origin-Realm', OR},
     {'Vendor-Id', ?VENDOR_3GPP},
     {'Product-Name', "volte.io AAA Server"},
     {'Origin-State-Id', OriginStateId},
     {'Firmware-Revision', ?FIRMWARE_REVISION},
     {'Auth-Application-Id', AuthIds},
     {'Supported-Vendor-Id', [?VENDOR_3GPP]},
     {'Vendor-Specific-Application-Id',
        [#'diameter_base_Vendor-Specific-Application-Id'{
            'Vendor-Id' = ?VENDOR_3GPP,
            'Auth-Application-Id' = [Id]} || Id <- AuthIds]},
     {string_decode, false},
     {application, [{alias, swm},
                    {dictionary, diameter_gen_swm},
                    {module, aaa_swm_server},
                    {answer_errors, callback},
                    {request_errors, answer_3xxx}]},
     {application, [{alias, swx},
                    {dictionary, diameter_gen_swx},
                    {module, aaa_swx_client},
                    {answer_errors, callback},
                    {request_errors, answer_3xxx}]},
     {application, [{alias, s6b},
                    {dictionary, diameter_gen_s6b},
                    {module, aaa_s6b_server},
                    {answer_errors, callback},
                    {request_errors, answer_3xxx}]},
     {application, [{alias, sta},
                    {dictionary, diameter_gen_sta},
                    {module, aaa_sta_server},
                    {answer_errors, callback},
                    {request_errors, answer_3xxx}]}].

start_listeners(State) ->
    ListenerSpecs = [
        {swm, aaa_config:get(swm_port, 3868),  aaa_config:get(swm_transport, "tcp")},
        {s6b, aaa_config:get(s6b_port, 3869),  aaa_config:get(s6b_transport, "tcp")}
    ] ++ case State#state.sta_enabled of
        true  -> [{sta, aaa_config:get(sta_port, 3870),
                        aaa_config:get(sta_transport, "tcp")}];
        _     -> []
    end,
    lists:foldl(fun({Name, Port, TStr}, S) -> add_listener(Name, Port, TStr, S) end,
                State, ListenerSpecs).

add_listener(Name, Port, TStr, #state{listeners = L} = State) ->
    TMod = transport_module(TStr),
    Result = diameter:add_transport(?SVC, {listen, [
        {transport_module, TMod},
        {transport_config, [{reuseaddr, true},
                            {ip, {0,0,0,0}},
                            {port, Port}]}
    ]}),
    case Result of
        {ok, Ref} ->
            logger:notice("~s listener up on port ~B (~s)", [Name, Port, TStr]),
            State#state{listeners = L#{Name => Ref}};
        {error, Err} ->
            logger:error("~s listener failed on port ~B: ~p",
                         [Name, Port, Err]),
            State#state{listeners = L#{Name => {error, Err}}}
    end.

start_swx_transports(State) ->
    Hosts = aaa_config:get(dra_hosts, ["dra-diameter"]),
    Port  = aaa_config:get(dra_port, 3868),
    TStr  = aaa_config:get(dra_transport, "tcp"),
    TMod  = transport_module(TStr),
    Initial = maps:from_list([{H, {undefined, 0}} || H <- Hosts]),
    State1 = State#state{dra_hosts = Hosts,
                         dra_port = Port,
                         dra_transport_mod = TMod,
                         swx_transports = Initial},
    logger:notice("SWx: connecting to ~B DRA host(s): ~p",
                  [length(Hosts), Hosts]),
    lists:foldl(fun(H, S) -> try_connect_swx(H, S) end, State1, Hosts).

try_connect_swx(Host, #state{dra_port = Port, dra_transport_mod = TMod,
                             swx_transports = Ts} = State) ->
    {_OldRef, Retries} = maps:get(Host, Ts, {undefined, 0}),
    case resolve_host(Host) of
        {ok, IP} ->
            case diameter:add_transport(?SVC, {connect, [
                {transport_module, TMod},
                {transport_config, [{raddr, IP}, {rport, Port},
                                    {ip, {0,0,0,0}}]},
                {reconnect_timer, 5000},
                {capabilities,
                    [{'Auth-Application-Id', [?SWX_APP_ID]}]}
            ]}) of
                {ok, Ref} ->
                    logger:notice("SWx transport added -> DRA ~s:~B", [Host, Port]),
                    State#state{swx_transports = Ts#{Host => {Ref, 0}}};
                {error, Err} ->
                    logger:error("SWx transport to DRA ~s:~B failed: ~p",
                                 [Host, Port, Err]),
                    Delay = retry_delay(Retries),
                    erlang:send_after(Delay, self(), {retry_swx, Host}),
                    State#state{swx_transports =
                        Ts#{Host => {undefined, Retries + 1}}}
            end;
        {error, Rsn} ->
            Delay = retry_delay(Retries),
            logger:warning("DNS fail for DRA ~s: ~p, retry in ~Bms",
                           [Host, Rsn, Delay]),
            erlang:send_after(Delay, self(), {retry_swx, Host}),
            State#state{swx_transports = Ts#{Host => {undefined, Retries + 1}}}
    end.

%%====================================================================
%% Helpers
%%====================================================================

transport_module("sctp") -> diameter_sctp;
transport_module("tcp")  -> diameter_tcp;
transport_module(_)      -> diameter_tcp.

retry_delay(R) -> min(5000 bsl min(R, 4), 60000).

resolve_host(H) ->
    case inet:getaddr(H, inet) of
        {ok, IP} -> {ok, IP};
        {error, _} ->
            case inet:getaddr(list_to_atom(H), inet) of
                {ok, IP} -> {ok, IP};
                E -> E
            end
    end.

to_bin(B) when is_binary(B) -> B;
to_bin(L) when is_list(L)   -> list_to_binary(L).
