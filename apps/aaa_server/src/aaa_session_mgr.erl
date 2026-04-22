%%%-------------------------------------------------------------------
%%% @doc AAA session state manager.
%%%
%%% Keeps the IMSI ↔ Session-Id dual index required by TS 29.273 so
%%% that HSS-initiated RTR/PPR (SWx) can be correlated to the active
%%% ePDG/PGW Diameter sessions and propagated as SWm ASR/RAR toward
%%% the access gateway.
%%%
%%% Three ETS tables:
%%%   * session_tab : Session-Id → #aaa_session
%%%   * imsi_index  : IMSI       → [Session-Id]
%%%   * nai_index   : NAI        → IMSI  (for pseudonym / fast-reauth)
%%%
%%% All stored binaries are kept as-is — no string conversion — to
%%% match the on-the-wire Diameter encoding.
%%% @end
%%%-------------------------------------------------------------------
-module(aaa_session_mgr).

-behaviour(gen_server).

-include("aaa_session.hrl").

-export([start_link/0,
         create_session/1, update_session/2, get_session/1,
         get_sessions_for_imsi/1, sessions_by_interface/1,
         remove_session/1, remove_sessions_for_imsi/1,
         bind_nai/2, resolve_nai/1,
         count/0, count/1,
         list_all/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE).
-define(TAB_SESS,  aaa_session_tab).
-define(TAB_IMSI,  aaa_imsi_idx_tab).
-define(TAB_NAI,   aaa_nai_idx_tab).
-define(CLEANUP_INTERVAL_MS, 60 * 1000).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% @doc Create a fresh session record. The caller fills in imsi,
%% session_id, interface, and any available fields.
-spec create_session(#aaa_session{}) -> ok.
create_session(#aaa_session{session_id = SessionId, imsi = IMSI} = S0) ->
    Now = erlang:system_time(second),
    S1  = S0#aaa_session{created_ts = Now, updated_ts = Now},
    ets:insert(?TAB_SESS, {SessionId, S1}),
    case IMSI of
        undefined -> ok;
        _         -> add_to_imsi_index(IMSI, SessionId)
    end,
    ok.

%% @doc Partial update. Updates is a map of field_name => value.
-spec update_session(binary(), map()) -> ok | {error, not_found}.
update_session(SessionId, Updates) when is_map(Updates) ->
    case ets:lookup(?TAB_SESS, SessionId) of
        [{_, S}] ->
            Now = erlang:system_time(second),
            S1  = apply_updates(S, Updates),
            S2  = S1#aaa_session{updated_ts = Now},
            ets:insert(?TAB_SESS, {SessionId, S2}),
            %% Keep IMSI index consistent if IMSI changed.
            case {S#aaa_session.imsi, S2#aaa_session.imsi} of
                {X, X} -> ok;
                {undefined, NewI} when NewI =/= undefined ->
                    add_to_imsi_index(NewI, SessionId);
                _ -> ok
            end,
            ok;
        [] ->
            {error, not_found}
    end.

-spec get_session(binary()) -> {ok, #aaa_session{}} | error.
get_session(SessionId) ->
    case ets:lookup(?TAB_SESS, SessionId) of
        [{_, S}] -> {ok, S};
        []       -> error
    end.

-spec get_sessions_for_imsi(binary()) -> [#aaa_session{}].
get_sessions_for_imsi(IMSI) ->
    case ets:lookup(?TAB_IMSI, IMSI) of
        [{_, Ids}] ->
            [S || Id <- Ids,
                  [{_, S}] <- [ets:lookup(?TAB_SESS, Id)]];
        [] -> []
    end.

-spec sessions_by_interface(swm | sta | s6b) -> [#aaa_session{}].
sessions_by_interface(Iface) ->
    ets:foldl(fun({_, #aaa_session{interface = I} = S}, Acc)
                    when I =:= Iface -> [S | Acc];
                 (_, Acc) -> Acc
              end, [], ?TAB_SESS).

-spec remove_session(binary()) -> ok.
remove_session(SessionId) ->
    case ets:lookup(?TAB_SESS, SessionId) of
        [{_, #aaa_session{imsi = IMSI}}] ->
            ets:delete(?TAB_SESS, SessionId),
            remove_from_imsi_index(IMSI, SessionId),
            ok;
        [] ->
            ok
    end.

-spec remove_sessions_for_imsi(binary()) -> [#aaa_session{}].
remove_sessions_for_imsi(IMSI) ->
    Sessions = get_sessions_for_imsi(IMSI),
    lists:foreach(fun(#aaa_session{session_id = Sid}) ->
                      ets:delete(?TAB_SESS, Sid)
                  end, Sessions),
    ets:delete(?TAB_IMSI, IMSI),
    %% Purge any NAI bindings pointing to this IMSI.
    ets:match_delete(?TAB_NAI, {'_', IMSI}),
    Sessions.

%% @doc Bind a pseudonym / fast-reauth NAI to an IMSI so future
%% authentication attempts starting from that NAI can look up the
%% underlying permanent identity.
-spec bind_nai(binary(), binary()) -> ok.
bind_nai(NAI, IMSI) ->
    ets:insert(?TAB_NAI, {NAI, IMSI}),
    ok.

-spec resolve_nai(binary()) -> {ok, binary()} | error.
resolve_nai(NAI) ->
    case ets:lookup(?TAB_NAI, NAI) of
        [{_, IMSI}] -> {ok, IMSI};
        []          -> error
    end.

-spec count() -> non_neg_integer().
count() ->
    safe_info_size(?TAB_SESS).

-spec count(swm | sta | s6b) -> non_neg_integer().
count(Iface) ->
    length(sessions_by_interface(Iface)).

-spec list_all() -> [#aaa_session{}].
list_all() ->
    [S || {_, S} <- ets:tab2list(?TAB_SESS)].

%%====================================================================
%% gen_server
%%====================================================================

init([]) ->
    ets:new(?TAB_SESS, [named_table, public, set, {write_concurrency, true},
                        {read_concurrency, true}]),
    ets:new(?TAB_IMSI, [named_table, public, set, {write_concurrency, true}]),
    ets:new(?TAB_NAI,  [named_table, public, set, {write_concurrency, true}]),
    erlang:send_after(?CLEANUP_INTERVAL_MS, self(), cleanup),
    {ok, #{}}.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State)        -> {noreply, State}.

handle_info(cleanup, State) ->
    Now = erlang:system_time(second),
    Expired = ets:foldl(
        fun({Sid, #aaa_session{expiry_ts = T}}, Acc)
                when is_integer(T), T =< Now ->
            [Sid | Acc];
           (_, Acc) -> Acc
        end, [], ?TAB_SESS),
    lists:foreach(fun remove_session/1, Expired),
    case Expired of
        [] -> ok;
        L  -> logger:info("AAA session cleanup: expired=~B", [length(L)])
    end,
    aaa_metrics:gauge_set(active_sessions, count()),
    erlang:send_after(?CLEANUP_INTERVAL_MS, self(), cleanup),
    {noreply, State};
handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%====================================================================
%% Internal
%%====================================================================

safe_info_size(Tab) ->
    case ets:info(Tab, size) of
        undefined -> 0;
        N         -> N
    end.

add_to_imsi_index(IMSI, SessionId) ->
    Cur = case ets:lookup(?TAB_IMSI, IMSI) of
        [{_, L}] -> L;
        []       -> []
    end,
    New = case lists:member(SessionId, Cur) of
        true  -> Cur;
        false -> [SessionId | Cur]
    end,
    ets:insert(?TAB_IMSI, {IMSI, New}).

remove_from_imsi_index(undefined, _) -> ok;
remove_from_imsi_index(IMSI, SessionId) ->
    case ets:lookup(?TAB_IMSI, IMSI) of
        [{_, L}] ->
            case [X || X <- L, X =/= SessionId] of
                []   -> ets:delete(?TAB_IMSI, IMSI);
                New  -> ets:insert(?TAB_IMSI, {IMSI, New})
            end;
        [] -> ok
    end.

apply_updates(S, Updates) ->
    maps:fold(fun set_field/3, S, Updates).

set_field(Key, Val, S) ->
    case field_index(Key) of
        undefined -> S;
        Ix        -> setelement(Ix, S, Val)
    end.

field_index(session_id)          -> #aaa_session.session_id;
field_index(imsi)                -> #aaa_session.imsi;
field_index(nai)                 -> #aaa_session.nai;
field_index(interface)           -> #aaa_session.interface;
field_index(origin_host)         -> #aaa_session.origin_host;
field_index(origin_realm)        -> #aaa_session.origin_realm;
field_index(apn)                 -> #aaa_session.apn;
field_index(rat_type)            -> #aaa_session.rat_type;
field_index(an_trusted)          -> #aaa_session.an_trusted;
field_index(visited_plmn)        -> #aaa_session.visited_plmn;
field_index(eap_id)              -> #aaa_session.eap_id;
field_index(eap_state)           -> #aaa_session.eap_state;
field_index(method)              -> #aaa_session.method;
field_index(rand)                -> #aaa_session.rand;
field_index(autn)                -> #aaa_session.autn;
field_index(xres)                -> #aaa_session.xres;
field_index(ck)                  -> #aaa_session.ck;
field_index(ik)                  -> #aaa_session.ik;
field_index(network_name)        -> #aaa_session.network_name;
field_index(k_encr)              -> #aaa_session.k_encr;
field_index(k_aut)               -> #aaa_session.k_aut;
field_index(k_re)                -> #aaa_session.k_re;
field_index(msk)                 -> #aaa_session.msk;
field_index(emsk)                -> #aaa_session.emsk;
field_index(pseudonym)           -> #aaa_session.pseudonym;
field_index(reauth_id)           -> #aaa_session.reauth_id;
field_index(non_3gpp_user_data)  -> #aaa_session.non_3gpp_user_data;
field_index(apn_configuration)   -> #aaa_session.apn_configuration;
field_index(ambr_ul)             -> #aaa_session.ambr_ul;
field_index(ambr_dl)             -> #aaa_session.ambr_dl;
field_index(pgw_id)              -> #aaa_session.pgw_id;
field_index(expiry_ts)           -> #aaa_session.expiry_ts;
field_index(_)                   -> undefined.
