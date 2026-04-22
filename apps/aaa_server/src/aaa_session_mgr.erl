%%%-------------------------------------------------------------------
%%% @doc AAA session state manager (Redis-backed).
%%%
%%% Keeps the IMSI ↔ Session-Id dual index required by TS 29.273 so
%%% that HSS-initiated RTR/PPR (SWx) can be correlated to the active
%%% ePDG/PGW Diameter sessions and propagated as SWm ASR/RAR toward
%%% the access gateway.
%%%
%%% Storage layout in Redis (prefix `aaa:' — configurable via
%%% AAA_REDIS_KEY_PREFIX):
%%%
%%%   * aaa:sess:&lt;SessionId&gt;    STRING   term_to_binary(#aaa_session{})
%%%   * aaa:imsi:&lt;IMSI&gt;         SET      of SessionIds for that IMSI
%%%   * aaa:nai:&lt;NAI&gt;           STRING   permanent IMSI bound to NAI
%%%   * aaa:iface:&lt;swm|sta|s6b&gt; SET      of SessionIds on that interface
%%%
%%% All writes that touch multiple keys are wrapped in MULTI/EXEC to
%%% keep the indexes consistent. TTL is set on the session blob from
%%% `expiry_ts' (or the configured default) and re-armed on every
%%% update; the cleanup loop scrubs stale SET members whose session
%%% key has already expired.
%%%
%%% A running gen_server process is retained only so the cleanup
%%% timer and the readiness probe have a well-known pid to target
%%% (existing callers `whereis(aaa_session_mgr)' and
%%% `gen_server:stop/1' keep working).
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
-define(CLEANUP_INTERVAL_MS, 60 * 1000).
-define(DEFAULT_TTL_SEC, 3600).

%% Cap on how long the IMSI / NAI / iface index SETs are allowed to
%% live without being refreshed. Individual sessions carry their own
%% TTL; the index TTL is a safety-net so orphaned sets don't pile up.
-define(INDEX_TTL_MARGIN_SEC, 600).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% @doc Create a fresh session record. The caller fills in imsi,
%% session_id, interface, and any available fields.
-spec create_session(#aaa_session{}) -> ok | {error, term()}.
create_session(#aaa_session{session_id = SessionId,
                            imsi       = IMSI,
                            interface  = Iface} = S0) ->
    Now  = erlang:system_time(second),
    S1   = S0#aaa_session{created_ts = Now, updated_ts = Now},
    Ttl  = ttl_for(S1),
    Blob = term_to_binary(S1, [{compressed, 3}]),

    SKey = sess_key(SessionId),
    ICmds = iface_cmds(Iface, SessionId, Ttl),
    MCmds = imsi_cmds(IMSI, SessionId, Ttl),

    case aaa_redis:multi([ [<<"SETEX">>, SKey, integer_to_binary(Ttl), Blob]
                           | ICmds ++ MCmds ]) of
        {ok, _} ->
            aaa_metrics:inc(sessions_created_total),
            ok;
        {error, Reason} = E ->
            logger:warning("aaa_session_mgr:create_session failed sid=~s reason=~p",
                           [SessionId, Reason]),
            E
    end.

%% @doc Partial update. Updates is a map of field_name => value.
-spec update_session(binary(), map()) -> ok | {error, not_found | term()}.
update_session(SessionId, Updates) when is_map(Updates) ->
    case get_session(SessionId) of
        {ok, S0} ->
            Now = erlang:system_time(second),
            S1  = apply_updates(S0, Updates),
            S2  = S1#aaa_session{updated_ts = Now},
            Ttl = ttl_for(S2),
            Blob = term_to_binary(S2, [{compressed, 3}]),
            SKey = sess_key(SessionId),
            ExtraCmds =
                %% Rebuild the IMSI index entry if the IMSI was
                %% attached for the first time (e.g. DER arrived
                %% without User-Name, IMSI learned later from the
                %% HSS MAA).
                case {S0#aaa_session.imsi, S2#aaa_session.imsi} of
                    {Same, Same} -> [];
                    {undefined, NewI} when NewI =/= undefined ->
                        imsi_cmds(NewI, SessionId, Ttl);
                    _ -> []
                end ++
                %% Same for interface.
                case {S0#aaa_session.interface, S2#aaa_session.interface} of
                    {Same2, Same2} -> [];
                    _ -> iface_cmds(S2#aaa_session.interface, SessionId, Ttl)
                end,
            case aaa_redis:multi([
                    [<<"SETEX">>, SKey, integer_to_binary(Ttl), Blob]
                    | ExtraCmds ]) of
                {ok, _} -> ok;
                {error, _} = E -> E
            end;
        error ->
            {error, not_found}
    end.

-spec get_session(binary()) -> {ok, #aaa_session{}} | error.
get_session(SessionId) ->
    case aaa_redis:get(sess_key(SessionId)) of
        {ok, undefined} -> error;
        {ok, Bin} when is_binary(Bin) ->
            try
                {ok, binary_to_term(Bin, [safe])}
            catch
                _:_ -> error
            end;
        {error, Reason} ->
            logger:warning("aaa_session_mgr:get_session redis error sid=~s reason=~p",
                           [SessionId, Reason]),
            error
    end.

-spec get_sessions_for_imsi(binary()) -> [#aaa_session{}].
get_sessions_for_imsi(IMSI) when is_binary(IMSI) ->
    case aaa_redis:smembers(imsi_key(IMSI)) of
        {ok, Ids} when is_list(Ids) ->
            mget_sessions(Ids);
        _ -> []
    end;
get_sessions_for_imsi(_) -> [].

-spec sessions_by_interface(swm | sta | s6b) -> [#aaa_session{}].
sessions_by_interface(Iface) ->
    case aaa_redis:smembers(iface_key(Iface)) of
        {ok, Ids} when is_list(Ids) ->
            mget_sessions(Ids);
        _ -> []
    end.

-spec remove_session(binary()) -> ok.
remove_session(SessionId) ->
    case get_session(SessionId) of
        {ok, #aaa_session{imsi = IMSI, interface = Iface}} ->
            %% NB: lists:append/1 (one-level flatten) — lists:flatten/1
            %% would dissolve each command list into its binaries and
            %% break the MULTI pipeline.
            Cmds = lists:append([
                [[<<"DEL">>, sess_key(SessionId)]],
                case IMSI of
                    undefined -> [];
                    _ -> [[<<"SREM">>, imsi_key(IMSI), SessionId]]
                end,
                case Iface of
                    undefined -> [];
                    _ -> [[<<"SREM">>, iface_key(Iface), SessionId]]
                end
            ]),
            _ = aaa_redis:multi(Cmds),
            ok;
        error ->
            _ = aaa_redis:del(sess_key(SessionId)),
            ok
    end.

%% @doc Remove every session for an IMSI and return the list that was
%% removed (callers in `aaa_swx_client' use the list to emit SWm ASR
%% toward the ePDG / PGW).
-spec remove_sessions_for_imsi(binary()) -> [#aaa_session{}].
remove_sessions_for_imsi(IMSI) when is_binary(IMSI) ->
    Sessions = get_sessions_for_imsi(IMSI),
    DelKeys  = [sess_key(S#aaa_session.session_id) || S <- Sessions],
    Ifaces   = lists:usort([S#aaa_session.interface ||
                            S <- Sessions,
                            S#aaa_session.interface =/= undefined]),
    %% Remove per-interface set entries too. lists:append/1 flattens
    %% exactly one level so each command stays a list of binaries.
    Cmds = lists:append([
        case DelKeys of
            [] -> [];
            _  -> [[<<"DEL">> | DelKeys]]
        end,
        [[<<"DEL">>, imsi_key(IMSI)]],
        [[<<"SREM">>, iface_key(I)] ++ [S#aaa_session.session_id
                                          || S <- Sessions,
                                             S#aaa_session.interface =:= I]
         || I <- Ifaces, Sessions =/= []]
    ]),
    case Cmds of
        [] -> ok;
        _  -> _ = aaa_redis:multi(Cmds), ok
    end,
    Sessions;
remove_sessions_for_imsi(_) -> [].

%% @doc Bind a pseudonym / fast-reauth NAI to an IMSI so future
%% authentication attempts starting from that NAI can look up the
%% underlying permanent identity.
-spec bind_nai(binary(), binary()) -> ok.
bind_nai(NAI, IMSI) when is_binary(NAI), is_binary(IMSI) ->
    Ttl = default_ttl(),
    case aaa_redis:setex(nai_key(NAI), Ttl, IMSI) of
        ok             -> ok;
        {error, _} = E ->
            logger:warning("aaa_session_mgr:bind_nai redis error: ~p", [E]),
            ok
    end.

-spec resolve_nai(binary()) -> {ok, binary()} | error.
resolve_nai(NAI) when is_binary(NAI) ->
    case aaa_redis:get(nai_key(NAI)) of
        {ok, undefined}              -> error;
        {ok, IMSI} when is_binary(IMSI) -> {ok, IMSI};
        _                            -> error
    end;
resolve_nai(_) -> error.

-spec count() -> non_neg_integer().
count() ->
    count(swm) + count(sta) + count(s6b).

-spec count(swm | sta | s6b) -> non_neg_integer().
count(Iface) ->
    case aaa_redis:scard(iface_key(Iface)) of
        {ok, Bin} when is_binary(Bin) -> binary_to_integer(Bin);
        {ok, N} when is_integer(N)    -> N;
        _                             -> 0
    end.

%% @doc Full listing — intended for debugging and the HTTP /status
%% endpoint. SCANs through the session keyspace; not used on the hot
%% Diameter path.
-spec list_all() -> [#aaa_session{}].
list_all() ->
    Pattern = iolist_to_binary([aaa_redis:key_prefix(), <<"sess:*">>]),
    Ids = scan_keys(Pattern),
    [S || K <- Ids,
          Sid <- [strip_sess_prefix(K)],
          {ok, S} <- [get_session(Sid)]].

%%====================================================================
%% gen_server
%%====================================================================

init([]) ->
    erlang:send_after(?CLEANUP_INTERVAL_MS, self(), cleanup),
    {ok, #{}}.

handle_call(_Req, _From, State) -> {reply, ok, State}.
handle_cast(_Msg, State)        -> {noreply, State}.

handle_info(cleanup, State) ->
    try
        prune_interface_sets()
    catch
        Class:Reason:Stack ->
            logger:warning("aaa_session_mgr cleanup failed ~p:~p ~P",
                           [Class, Reason, Stack, 10])
    end,
    refresh_active_gauge(),
    erlang:send_after(?CLEANUP_INTERVAL_MS, self(), cleanup),
    {noreply, State};
handle_info(_Info, State) -> {noreply, State}.

terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.

%%====================================================================
%% Key helpers
%%====================================================================

sess_key(Sid)            -> aaa_redis:key([<<"sess:">>, Sid]).
imsi_key(IMSI)           -> aaa_redis:key([<<"imsi:">>, IMSI]).
nai_key(NAI)             -> aaa_redis:key([<<"nai:">>, NAI]).
iface_key(I) when is_atom(I) ->
    aaa_redis:key([<<"iface:">>, atom_to_binary(I, utf8)]).

strip_sess_prefix(K) when is_binary(K) ->
    Prefix = iolist_to_binary([aaa_redis:key_prefix(), <<"sess:">>]),
    PSize  = byte_size(Prefix),
    case K of
        <<Prefix:PSize/binary, Rest/binary>> -> Rest;
        _ -> K
    end.

%%====================================================================
%% Internal
%%====================================================================

ttl_for(#aaa_session{expiry_ts = T}) when is_integer(T), T > 0 ->
    Now = erlang:system_time(second),
    case T - Now of
        N when N > 0 -> N;
        _            -> default_ttl()
    end;
ttl_for(_) ->
    default_ttl().

default_ttl() ->
    case aaa_config:get(session_timeout, ?DEFAULT_TTL_SEC) of
        N when is_integer(N), N > 0 -> N;
        _                           -> ?DEFAULT_TTL_SEC
    end.

imsi_cmds(undefined, _Sid, _Ttl) -> [];
imsi_cmds(IMSI, Sid, Ttl) ->
    K = imsi_key(IMSI),
    [ [<<"SADD">>, K, Sid],
      [<<"EXPIRE">>, K, integer_to_binary(Ttl + ?INDEX_TTL_MARGIN_SEC)] ].

iface_cmds(undefined, _Sid, _Ttl) -> [];
iface_cmds(Iface, Sid, Ttl) ->
    K = iface_key(Iface),
    [ [<<"SADD">>, K, Sid],
      [<<"EXPIRE">>, K, integer_to_binary(Ttl + ?INDEX_TTL_MARGIN_SEC)] ].

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

%% @doc Pipelined GET of every SessionId referenced by an index set.
%% Uses MGET so fetching all sessions for one IMSI or one interface
%% is a single Redis round-trip. Skips members whose blob has already
%% expired (the index set is scrubbed lazily by the cleanup timer).
mget_sessions([]) -> [];
mget_sessions(Ids) ->
    case aaa_redis:q([<<"MGET">> | [sess_key(Id) || Id <- Ids]]) of
        {ok, Blobs} when is_list(Blobs), length(Blobs) =:= length(Ids) ->
            [S || {_Id, Blob} <- lists:zip(Ids, Blobs),
                  is_binary(Blob),
                  {ok, S} <- [safe_binary_to_session(Blob)]];
        _ ->
            %% Fallback: issue individual GETs so the API remains
            %% robust if MGET is unavailable for some reason.
            lists:foldr(
                fun(Id, Acc) ->
                    case get_session(Id) of
                        {ok, S} -> [S | Acc];
                        error   -> Acc
                    end
                end, [], Ids)
    end.

safe_binary_to_session(Blob) ->
    try
        {ok, binary_to_term(Blob, [safe])}
    catch
        _:_ -> error
    end.

%% @doc Iterate SCAN cursors for a match pattern and return the
%% collected keys. Bounded at 10k keys to avoid pathological runtimes.
scan_keys(Pattern) ->
    scan_keys(<<"0">>, Pattern, [], 0).

scan_keys(_Cursor, _Pattern, Acc, N) when N >= 10000 ->
    lists:append(lists:reverse(Acc));
scan_keys(Cursor, Pattern, Acc, N) ->
    case aaa_redis:q([<<"SCAN">>, Cursor,
                      <<"MATCH">>, Pattern,
                      <<"COUNT">>, <<"200">>]) of
        {ok, [NextCursor, Keys]} when is_list(Keys) ->
            case NextCursor of
                <<"0">> ->
                    lists:append(lists:reverse([Keys | Acc]));
                _ ->
                    scan_keys(NextCursor, Pattern,
                              [Keys | Acc], N + length(Keys))
            end;
        _ ->
            lists:append(lists:reverse(Acc))
    end.

%% Periodic lightweight GC: walk each interface set, drop SessionIds
%% whose blob has already expired so SCARD-based metrics stay honest.
prune_interface_sets() ->
    lists:foreach(fun prune_iface/1, [swm, sta, s6b]).

prune_iface(Iface) ->
    case aaa_redis:smembers(iface_key(Iface)) of
        {ok, []}   -> ok;
        {ok, Ids}  -> prune_iface_ids(Iface, Ids);
        _          -> ok
    end.

prune_iface_ids(Iface, Ids) ->
    case aaa_redis:q([<<"MGET">> | [sess_key(Id) || Id <- Ids]]) of
        {ok, Blobs} when is_list(Blobs), length(Blobs) =:= length(Ids) ->
            Dead = [Id || {Id, undefined} <- lists:zip(Ids, Blobs)],
            remove_dead_members(Iface, Dead);
        _ -> ok
    end.

remove_dead_members(_Iface, []) -> ok;
remove_dead_members(Iface, Dead) ->
    IKey = iface_key(Iface),
    _ = aaa_redis:q([<<"SREM">>, IKey | Dead]),
    ok.

refresh_active_gauge() ->
    Total = count(),
    aaa_metrics:gauge_set(active_sessions, Total),
    ok.
