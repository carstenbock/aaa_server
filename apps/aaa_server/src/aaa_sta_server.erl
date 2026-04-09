%%%-------------------------------------------------------------------
%%% @doc Diameter STa server placeholder for trusted WLAN access.
%%% STa (App-ID 16777250) enables Hotspot 2.0 / Passpoint authentication
%%% for trusted non-3GPP access per 3GPP TS 29.273 section 6.
%%%
%%% This module is structurally ready for implementation but currently
%%% returns DIAMETER_UNABLE_TO_COMPLY for all requests. Enable via
%%% AAA_STA_ENABLED=true when a Passpoint/HS2.0 WLAN controller is deployed.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_sta_server).

-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(STA_APP_ID, 16777250).

-record(state, {
    service :: term() | undefined
}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    logger:info("STa server (trusted WLAN) starting on App-ID ~p", [?STA_APP_ID]),
    %% TODO: register Diameter service for STa (App-ID 16777250)
    %% with DER/DEA, AAR/AAA, STR/STA, ASR/ASA handlers
    %% similar to aaa_swm_server but for trusted access
    {ok, #state{}}.

handle_call({sta_der, _IMSI, _EAPPayload}, _From, State) ->
    %% Diameter-EAP-Request from trusted WLAN AN
    %% Same EAP relay pattern as SWm but with AN-Trusted=TRUSTED(0)
    {reply, {error, not_implemented}, State};

handle_call({sta_aar, _IMSI}, _From, State) ->
    %% AA-Request for trusted access authorization
    {reply, {error, not_implemented}, State};

handle_call(_Req, _From, State) ->
    {reply, {error, unknown_request}, State}.

handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
