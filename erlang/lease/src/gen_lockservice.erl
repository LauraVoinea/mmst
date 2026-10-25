
%%%-------------------------------------------------------------------
%%% gen_lockservice.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_lockservice).
-behaviour(gen_statem).

%% Public API
-export([start_link/2, callback_mode/0]).

%% gen_statem callbacks
-export([init/1, code_change/4, terminate/3,
  s3/3,
  s5/3,
  s6/3,
  s7/3,
  send_s3_fence/2,
  send_s5_expired/2,
  send_s6_valid/2,
  send_s7_renewed/2]).

%% Types & records
-include("lockservice.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s5, state_data(), [{next_event, internal, {expired}}]}.
-callback s3(internal, {fence}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s5(internal | cast, {expired} | {pid(), {renew}}, state_data()) -> {next_state, s3, state_data()} | {next_state, s6, state_data()} | {next_state, s3, state_data(), [{next_event, internal, {expired}}] } | {next_state, s6, state_data(), [{next_event, internal, {expired}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s6(internal, {valid}, state_data()) -> {next_state, s7, state_data()} | {next_state, s7, state_data(), [{next_event, internal, {valid}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s7(internal, {renewed}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_lockservice, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "lockservice_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s5, state_data(), [{next_event, internal, {expired}}]}.
init({CallbackModule, _Args}) ->
    io:format("lockservice: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    enter_mc(mc1),
    CallbackModule:init([]).

%% ---------- State functions----------
-spec s3(internal, {fence}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s3(internal, {fence}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s3(internal, {fence}, Data),
    after_transition(Next);
s3(cast, {_ClientPid, {renew}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_lockservice[s3]: Purging stale event ~p~n", [{renew}]),
        {keep_state, Data};
      false ->
        io:format("gen_lockservice[s3]: Postponing event ~p~n", [{renew}]),
        {keep_state, Data, [postpone]}
    end.

%% Mixed-choice entry state
-spec s5(internal | cast, {expired} | {pid(), {renew}, list()}, state_data()) -> {next_state, s3, state_data()} | {next_state, s6, state_data()} | {next_state, s3, state_data(), [{next_event, internal, {expired}}] } | {next_state, s6, state_data(), [{next_event, internal, {expired}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s5(cast, {ClientPid, {renew}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, left)) of
      stale ->
        io:format("gen_lockservice[s5]: Purging stale event ~p~n", [{renew}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s5(cast, {ClientPid, {renew}}, Data)
               catch error:function_clause ->
                 io:format("gen_lockservice[s5]: Callback had no clause for ~p, postponing~n", [{renew}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s3, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s3, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s6, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s6, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_lockservice[s5]: Postponing not-ready event ~p~n", [{renew}]),
        {keep_state, Data, [postpone]}
    end;
s5(internal, {expired}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s5(internal, {expired}, Data),
    after_transition(Next).

-spec s6(internal, {valid}, state_data()) -> {next_state, s7, state_data()} | {next_state, s7, state_data(), [{next_event, internal, {valid}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s6(internal, {valid}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s6(internal, {valid}, Data),
    after_transition(Next);
s6(cast, {_ClientPid, {renew}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_lockservice[s6]: Purging stale event ~p~n", [{renew}]),
        {keep_state, Data};
      false ->
        io:format("gen_lockservice[s6]: Postponing event ~p~n", [{renew}]),
        {keep_state, Data, [postpone]}
    end.

-spec s7(internal, {renewed}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s7(internal, {renewed}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s7(internal, {renewed}, Data),
    after_transition(Next);
s7(cast, {_ClientPid, {renew}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_lockservice[s7]: Purging stale event ~p~n", [{renew}]),
        {keep_state, Data};
      false ->
        io:format("gen_lockservice[s7]: Postponing event ~p~n", [{renew}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s3_fence(StoragePid :: pid(), _Data :: state_data()) -> ok.
send_s3_fence(StoragePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(StoragePid, {self(), {fence}, Path}).


-spec send_s5_expired(ClientPid :: pid(), _Data :: state_data()) -> ok.
send_s5_expired(ClientPid, _Data) ->
    Path = branch_path(mc1, right),
    commit_current(mc1, right),
    gen_statem:cast(ClientPid, {self(), {expired}, Path}).


-spec send_s6_valid(StoragePid :: pid(), _Data :: state_data()) -> ok.
send_s6_valid(StoragePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(StoragePid, {self(), {valid}, Path}).


-spec send_s7_renewed(ClientPid :: pid(), _Data :: state_data()) -> ok.
send_s7_renewed(ClientPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(ClientPid, {self(), {renewed}, Path}).


%% ===== misc OTP =====
-spec code_change(OldVsn :: term(), StateName :: atom(), StateData :: state_data(), Extra :: term()) ->
    {ok, state_data()}.
code_change(_Vsn, _StateName, StateData, _Extra) ->
    {ok, StateData}.

-spec terminate(Reason :: term(), State :: atom(), Data :: state_data()) -> ok.
terminate(_Reason, _State, _StateData) ->
    ok.


get_commit() -> case get(commit_map) of undefined -> #{}; M -> M end.
set_commit(M) -> put(commit_map, M), M.

init_context() ->
    set_current_path([]),
    set_commit(#{}),
    ok.

-spec current_path() -> [left | right].
current_path() -> case get(mc_path) of undefined -> []; Path -> Path end.

set_current_path(Path) -> put(mc_path, Path), Path.

enter_mc(McId) ->
    Prefix = current_path(),
    set_commit(maps:put(Prefix, {McId, none}, get_commit())),
    ok.

active_prefix(McId) ->
    Current = current_path(),
    Candidates = lists:filtermap(
      fun({Prefix, {FrameMc, _Side}}) ->
        case FrameMc =:= McId andalso lists:prefix(Prefix, Current) of
          true -> {true, {length(Prefix), Prefix}};
          false -> false
        end
      end, maps:to_list(get_commit())),
    case Candidates of
      [] -> error({missing_mixed_choice, McId, Current});
      _ -> element(2, lists:max(Candidates))
    end.

branch_path(McId, Side) when Side =:= left; Side =:= right ->
    active_prefix(McId) ++ [Side].

commit_current(McId, Side) when Side =:= left; Side =:= right ->
    Prefix = active_prefix(McId),
    set_commit(maps:put(Prefix, {McId, Side}, get_commit())),
    set_current_path(Prefix ++ [Side]),
    ok.


commit_if_taken(Next, McId, Side) ->
    case Next of
      {keep_state, _} -> Next;
      {keep_state, _, _} -> Next;
      _ -> commit_current(McId, Side), Next
    end.

after_transition({next_state, s5, _} = Next) -> enter_mc(mc1), Next;
after_transition({next_state, s5, _, _} = Next) -> enter_mc(mc1), Next;
after_transition(Next) -> Next.

message_status(Path, Expected) ->
    case stale(Path) of
      true -> stale;
      false when Path =:= Expected -> ready;
      false -> not_ready
    end.

-spec stale([left | right]) -> boolean().
stale(Path) when is_list(Path) -> stale(Path, [], get_commit()).

stale([], _Prefix, _Frames) -> false;
stale([Side | Rest], Prefix, Frames) ->
    case maps:find(Prefix, Frames) of
      {ok, {_McId, Commit}} when Commit =/= none, Commit =/= Side -> true;
      _ -> stale(Rest, Prefix ++ [Side], Frames)
    end.

