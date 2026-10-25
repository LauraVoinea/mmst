
%%%-------------------------------------------------------------------
%%% gen_a.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_a).
-behaviour(gen_statem).

%% Public API
-export([start_link/2, callback_mode/0]).

%% gen_statem callbacks
-export([init/1, code_change/4, terminate/3,
  s6/3,
  s7/3,
  s8/3,
  s9/3,
  send_s6_a1/2,
  send_s7_a2/2]).

%% Types & records
-include("a.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s6, state_data(), [{next_event, internal, {a1}}]}.
-callback s6(internal | cast, {a1} | {pid(), {'TOa'}}, state_data()) -> {next_state, s6, state_data()} | {next_state, s7, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {a1}}] } | {next_state, s7, state_data(), [{next_event, internal, {a1}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s7(internal | cast, {a2} | {pid(), {'TOa'}}, state_data()) -> {next_state, s6, state_data()} | {next_state, s8, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {a2}}] } | {next_state, s8, state_data(), [{next_event, internal, {a2}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s8(cast, {pid(), {'TOa'}} | {pid(), {a4}}, state_data()) -> {next_state, s6, state_data()} | {next_state, s9, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s9(cast, {pid(), {a5}}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_a, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "a_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s6, state_data(), [{next_event, internal, {a1}}]}.
init({CallbackModule, _Args}) ->
    io:format("a: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    enter_mc(mc1),
    CallbackModule:init([]).

%% ---------- State functions----------
%% Mixed-choice entry state
-spec s6(internal | cast, {a1} | {pid(), {'TOa'}, list()}, state_data()) -> {next_state, s6, state_data()} | {next_state, s7, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {a1}}] } | {next_state, s7, state_data(), [{next_event, internal, {a1}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s6(cast, {BPid, {'TOa'}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_a[s6]: Purging stale event ~p~n", [{'TOa'}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s6(cast, {BPid, {'TOa'}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s6]: Callback had no clause for ~p, postponing~n", [{'TOa'}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s6, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s6, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_a[s6]: Postponing not-ready event ~p~n", [{'TOa'}]),
        {keep_state, Data, [postpone]}
    end;
s6(internal, {a1}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s6(internal, {a1}, Data),
    after_transition(Next);
s6(cast, {_BPid, {a4}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s6]: Purging stale event ~p~n", [{a4}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s6]: Postponing event ~p~n", [{a4}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CPid, {a5}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s6]: Purging stale event ~p~n", [{a5}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s6]: Postponing event ~p~n", [{a5}]),
        {keep_state, Data, [postpone]}
    end.

-spec s7(internal | cast, {a2} | {pid(), {'TOa'}, list()}, state_data()) -> {next_state, s6, state_data()} | {next_state, s8, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {a2}}] } | {next_state, s8, state_data(), [{next_event, internal, {a2}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s7(cast, {BPid, {'TOa'}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_a[s7]: Purging stale event ~p~n", [{'TOa'}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s7(cast, {BPid, {'TOa'}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s7]: Callback had no clause for ~p, postponing~n", [{'TOa'}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s6, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s6, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_a[s7]: Postponing not-ready event ~p~n", [{'TOa'}]),
        {keep_state, Data, [postpone]}
    end;
s7(internal, {a2}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s7(internal, {a2}, Data),
    after_transition(Next);
s7(cast, {_BPid, {a4}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s7]: Purging stale event ~p~n", [{a4}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s7]: Postponing event ~p~n", [{a4}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CPid, {a5}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s7]: Purging stale event ~p~n", [{a5}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s7]: Postponing event ~p~n", [{a5}]),
        {keep_state, Data, [postpone]}
    end.

-spec s8(cast, {pid(), {a4}, list()} | {pid(), {'TOa'}, list()}, state_data()) -> {next_state, s6, state_data()} | {next_state, s9, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s8(cast, {BPid, {'TOa'}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_a[s8]: Purging stale event ~p~n", [{'TOa'}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s8(cast, {BPid, {'TOa'}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s8]: Callback had no clause for ~p, postponing~n", [{'TOa'}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s6, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s6, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_a[s8]: Postponing not-ready event ~p~n", [{'TOa'}]),
        {keep_state, Data, [postpone]}
    end;
s8(cast, {BPid, {a4}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_a[s8]: Purging stale event ~p~n", [{a4}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s8(cast, {BPid, {a4}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s8]: Callback had no clause for ~p, postponing~n", [{a4}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s9, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s9, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_a[s8]: Postponing not-ready event ~p~n", [{a4}]),
        {keep_state, Data, [postpone]}
    end;
s8(cast, {_CPid, {a5}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s8]: Purging stale event ~p~n", [{a5}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s8]: Postponing event ~p~n", [{a5}]),
        {keep_state, Data, [postpone]}
    end.

-spec s9(cast, {pid(), {a5}, list()}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s9(cast, {CPid, {a5}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_a[s9]: Purging stale event ~p~n", [{a5}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CPid, {a5}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s9]: Callback had no clause for ~p, postponing~n", [{a5}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_a[s9]: Postponing not-ready event ~p~n", [{a5}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {BPid, {'TOa'}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_a[s9]: Purging stale interrupt ~p~n", [{'TOa'}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s6(cast, {BPid, {'TOa'}}, Data)
               catch error:function_clause ->
                 io:format("gen_a[s9]: Callback had no interrupt clause for ~p, postponing~n", [{'TOa'}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_a[s9]: Postponing not-ready interrupt ~p~n", [{'TOa'}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_BPid, {a4}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_a[s9]: Purging stale event ~p~n", [{a4}]),
        {keep_state, Data};
      false ->
        io:format("gen_a[s9]: Postponing event ~p~n", [{a4}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s6_a1(BPid :: pid(), _Data :: state_data()) -> ok.
send_s6_a1(BPid, _Data) ->
    Path = branch_path(mc1, left),
    set_current_path(Path),
    gen_statem:cast(BPid, {self(), {a1}, Path}).


-spec send_s7_a2(CPid :: pid(), _Data :: state_data()) -> ok.
send_s7_a2(CPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CPid, {self(), {a2}, Path}).


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

after_transition({next_state, s6, _} = Next) -> enter_mc(mc1), Next;
after_transition({next_state, s6, _, _} = Next) -> enter_mc(mc1), Next;
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

