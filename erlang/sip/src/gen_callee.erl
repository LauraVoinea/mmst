
%%%-------------------------------------------------------------------
%%% gen_callee.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_callee).
-behaviour(gen_statem).

%% Public API
-export([start_link/2, callback_mode/0]).

%% gen_statem callbacks
-export([init/1, code_change/4, terminate/3,
  s1/3,
  s3/3,
  s5/3,
  s6/3,
  s7/3,
  s9/3,
  s10/3,
  s11/3,
  s12/3,
  send_s3_ringing/2,
  send_s7_bye_ok/2,
  send_s9_invite_ok/2,
  send_s10_cancel_ok/2,
  send_s11_terminated/2]).

%% Types & records
-include("callee.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s1, state_data()}.
-callback s1(cast, {pid(), {invite}}, state_data()) -> {next_state, s3, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s3(internal, {ringing}, state_data()) -> {next_state, s9, state_data()} | {next_state, s9, state_data(), [{next_event, internal, {ringing}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s5(cast, {pid(), {ack}}, state_data()) -> {next_state, s6, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s6(cast, {pid(), {bye}}, state_data()) -> {next_state, s7, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s7(internal, {bye_ok}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s9(internal | cast, {invite_ok} | {pid(), {cancel}}, state_data()) -> {next_state, s10, state_data()} | {next_state, s5, state_data()} | {next_state, s10, state_data(), [{next_event, internal, {invite_ok}}] } | {next_state, s5, state_data(), [{next_event, internal, {invite_ok}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s10(internal, {cancel_ok}, state_data()) -> {next_state, s11, state_data()} | {next_state, s11, state_data(), [{next_event, internal, {cancel_ok}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s11(internal, {terminated}, state_data()) -> {next_state, s12, state_data()} | {next_state, s12, state_data(), [{next_event, internal, {terminated}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s12(cast, {pid(), {ack}}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_callee, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "callee_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s1, state_data()}.
init({CallbackModule, _Args}) ->
    io:format("callee: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    CallbackModule:init([]).

%% ---------- State functions----------
-spec s1(cast, {pid(), {invite}}, state_data()) -> {next_state, s3, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s1(cast, {CallerPid, {invite}}, Data) ->
    CallbackModule = get(callback_module),
    Next = try CallbackModule:s1(cast, {CallerPid, {invite}}, Data)
           catch error:function_clause ->
             io:format("gen_callee[s1]: Callback had no clause for ~p, ignoring~n", [{invite}]),
             {keep_state, Data}
           end,
    after_transition(Next);
s1(cast, {_From, _Msg, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s1]: Purging stale early-path event ~p~n", [_Msg]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s1]: Postponing early-path event ~p~n", [_Msg]),
        {keep_state, Data, [postpone]}
    end.

-spec s3(internal, {ringing}, state_data()) -> {next_state, s9, state_data()} | {next_state, s9, state_data(), [{next_event, internal, {ringing}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s3(internal, {ringing}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s3(internal, {ringing}, Data),
    after_transition(Next);
s3(cast, {_From, _Msg, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s3]: Purging stale early-path event ~p~n", [_Msg]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s3]: Postponing early-path event ~p~n", [_Msg]),
        {keep_state, Data, [postpone]}
    end.

-spec s5(cast, {pid(), {ack}, list()}, state_data()) -> {next_state, s6, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s5(cast, {CallerPid, {ack}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_callee[s5]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s5(cast, {CallerPid, {ack}}, Data)
               catch error:function_clause ->
                 io:format("gen_callee[s5]: Callback had no clause for ~p, postponing~n", [{ack}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_callee[s5]: Postponing not-ready event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s5]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s5]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s5]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s5]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s5]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s5]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.

-spec s6(cast, {pid(), {bye}, list()}, state_data()) -> {next_state, s7, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s6(cast, {CallerPid, {bye}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_callee[s6]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s6(cast, {CallerPid, {bye}}, Data)
               catch error:function_clause ->
                 io:format("gen_callee[s6]: Callback had no clause for ~p, postponing~n", [{bye}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_callee[s6]: Postponing not-ready event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s6]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s6]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CallerPid, {ack}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s6]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s6]: Postponing event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s6]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s6]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.

-spec s7(internal, {bye_ok}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s7(internal, {bye_ok}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s7(internal, {bye_ok}, Data),
    after_transition(Next);
s7(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s7]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s7]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CallerPid, {ack}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s7]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s7]: Postponing event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s7]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s7]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s7]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s7]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.

%% Mixed-choice entry state
-spec s9(internal | cast, {invite_ok} | {pid(), {cancel}, list()}, state_data()) -> {next_state, s10, state_data()} | {next_state, s5, state_data()} | {next_state, s10, state_data(), [{next_event, internal, {invite_ok}}] } | {next_state, s5, state_data(), [{next_event, internal, {invite_ok}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s9(internal, {invite_ok}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s9(internal, {invite_ok}, Data),
    after_transition(Next);
s9(cast, {CallerPid, {cancel}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, left)) of
      stale ->
        io:format("gen_callee[s9]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CallerPid, {cancel}}, Data)
               catch error:function_clause ->
                 io:format("gen_callee[s9]: Callback had no clause for ~p, postponing~n", [{cancel}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s5, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s5, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s10, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s10, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_callee[s9]: Postponing not-ready event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s9]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s9]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CallerPid, {ack}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s9]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s9]: Postponing event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s9]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s9]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end.

-spec s10(internal, {cancel_ok}, state_data()) -> {next_state, s11, state_data()} | {next_state, s11, state_data(), [{next_event, internal, {cancel_ok}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s10(internal, {cancel_ok}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s10(internal, {cancel_ok}, Data),
    after_transition(Next);
s10(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s10]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s10]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CallerPid, {ack}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s10]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s10]: Postponing event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s10]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s10]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s10]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s10]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.

-spec s11(internal, {terminated}, state_data()) -> {next_state, s12, state_data()} | {next_state, s12, state_data(), [{next_event, internal, {terminated}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s11(internal, {terminated}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s11(internal, {terminated}, Data),
    after_transition(Next);
s11(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s11]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s11]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CallerPid, {ack}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s11]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s11]: Postponing event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s11]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s11]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s11]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s11]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.

-spec s12(cast, {pid(), {ack}, list()}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s12(cast, {CallerPid, {ack}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_callee[s12]: Purging stale event ~p~n", [{ack}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s12(cast, {CallerPid, {ack}}, Data)
               catch error:function_clause ->
                 io:format("gen_callee[s12]: Callback had no clause for ~p, postponing~n", [{ack}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_callee[s12]: Postponing not-ready event ~p~n", [{ack}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CallerPid, {invite}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s12]: Purging stale event ~p~n", [{invite}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s12]: Postponing event ~p~n", [{invite}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CallerPid, {bye}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s12]: Purging stale event ~p~n", [{bye}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s12]: Postponing event ~p~n", [{bye}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CallerPid, {cancel}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_callee[s12]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      false ->
        io:format("gen_callee[s12]: Postponing event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s3_ringing(CallerPid :: pid(), _Data :: state_data()) -> ok.
send_s3_ringing(CallerPid, _Data) ->
    gen_statem:cast(CallerPid, {self(), {ringing}}).


-spec send_s7_bye_ok(CallerPid :: pid(), _Data :: state_data()) -> ok.
send_s7_bye_ok(CallerPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CallerPid, {self(), {bye_ok}, Path}).


-spec send_s9_invite_ok(CallerPid :: pid(), _Data :: state_data()) -> ok.
send_s9_invite_ok(CallerPid, _Data) ->
    Path = branch_path(mc1, right),
    commit_current(mc1, right),
    gen_statem:cast(CallerPid, {self(), {invite_ok}, Path}).


-spec send_s10_cancel_ok(CallerPid :: pid(), _Data :: state_data()) -> ok.
send_s10_cancel_ok(CallerPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CallerPid, {self(), {cancel_ok}, Path}).


-spec send_s11_terminated(CallerPid :: pid(), _Data :: state_data()) -> ok.
send_s11_terminated(CallerPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CallerPid, {self(), {terminated}, Path}).


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

after_transition({next_state, s9, _} = Next) -> enter_mc(mc1), Next;
after_transition({next_state, s9, _, _} = Next) -> enter_mc(mc1), Next;
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

