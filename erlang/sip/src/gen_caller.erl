
%%%-------------------------------------------------------------------
%%% gen_caller.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_caller).
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
  send_s1_invite/2,
  send_s5_ack/2,
  send_s6_bye/2,
  send_s9_cancel/2,
  send_s12_ack/2]).

%% Types & records
-include("caller.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s1, state_data(), [{next_event, internal, {invite}}]}.
-callback s1(internal, {invite}, state_data()) -> {next_state, s3, state_data()} | {next_state, s3, state_data(), [{next_event, internal, {invite}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s3(cast, {pid(), {ringing}}, state_data()) -> {next_state, s9, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s5(internal, {ack}, state_data()) -> {next_state, s6, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {ack}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s6(internal, {bye}, state_data()) -> {next_state, s7, state_data()} | {next_state, s7, state_data(), [{next_event, internal, {bye}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s7(cast, {pid(), {bye_ok}}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s9(internal | cast, {cancel} | {pid(), {invite_ok}}, state_data()) -> {next_state, s10, state_data()} | {next_state, s5, state_data()} | {next_state, s10, state_data(), [{next_event, internal, {cancel}}] } | {next_state, s5, state_data(), [{next_event, internal, {cancel}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s10(cast, {pid(), {cancel_ok}} | {pid(), {invite_ok}}, state_data()) -> {next_state, s11, state_data()} | {next_state, s5, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s11(cast, {pid(), {terminated}}, state_data()) -> {next_state, s12, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s12(internal, {ack}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_caller, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "caller_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s1, state_data(), [{next_event, internal, {invite}}]}.
init({CallbackModule, _Args}) ->
    io:format("caller: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    CallbackModule:init([]).

%% ---------- State functions----------
-spec s1(internal, {invite}, state_data()) -> {next_state, s3, state_data()} | {next_state, s3, state_data(), [{next_event, internal, {invite}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s1(internal, {invite}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s1(internal, {invite}, Data),
    after_transition(Next);
s1(cast, {_From, _Msg, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s1]: Purging stale early-path event ~p~n", [_Msg]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s1]: Postponing early-path event ~p~n", [_Msg]),
        {keep_state, Data, [postpone]}
    end.

-spec s3(cast, {pid(), {ringing}}, state_data()) -> {next_state, s9, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s3(cast, {CalleePid, {ringing}}, Data) ->
    CallbackModule = get(callback_module),
    Next = try CallbackModule:s3(cast, {CalleePid, {ringing}}, Data)
           catch error:function_clause ->
             io:format("gen_caller[s3]: Callback had no clause for ~p, ignoring~n", [{ringing}]),
             {keep_state, Data}
           end,
    after_transition(Next);
s3(cast, {_From, _Msg, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s3]: Purging stale early-path event ~p~n", [_Msg]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s3]: Postponing early-path event ~p~n", [_Msg]),
        {keep_state, Data, [postpone]}
    end.

-spec s5(internal, {ack}, state_data()) -> {next_state, s6, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {ack}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s5(internal, {ack}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s5(internal, {ack}, Data),
    after_transition(Next);
s5(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s5]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s5]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s5]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s5]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s5]: Purging stale interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s5]: Callback had no interrupt clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_caller[s5]: Postponing not-ready interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s5]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s5]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s5]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s5]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.

-spec s6(internal, {bye}, state_data()) -> {next_state, s7, state_data()} | {next_state, s7, state_data(), [{next_event, internal, {bye}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s6(internal, {bye}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s6(internal, {bye}, Data),
    after_transition(Next);
s6(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s6]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s6]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s6]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s6]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s6]: Purging stale interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s6]: Callback had no interrupt clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_caller[s6]: Postponing not-ready interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s6]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s6]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s6]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s6]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.

-spec s7(cast, {pid(), {bye_ok}, list()}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s7(cast, {CalleePid, {bye_ok}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_caller[s7]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s7(cast, {CalleePid, {bye_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s7]: Callback had no clause for ~p, postponing~n", [{bye_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_caller[s7]: Postponing not-ready event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s7]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s7]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s7]: Purging stale interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s7]: Callback had no interrupt clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_caller[s7]: Postponing not-ready interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s7]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s7]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s7]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s7]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.

%% Mixed-choice entry state
-spec s9(internal | cast, {cancel} | {pid(), {invite_ok}, list()}, state_data()) -> {next_state, s10, state_data()} | {next_state, s5, state_data()} | {next_state, s10, state_data(), [{next_event, internal, {cancel}}] } | {next_state, s5, state_data(), [{next_event, internal, {cancel}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s9(internal, {cancel}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s9(internal, {cancel}, Data),
    after_transition(Next);
s9(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s9]: Purging stale event ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s9]: Callback had no clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s5, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s5, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_caller[s9]: Postponing not-ready event ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s9]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s9]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s9]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s9]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s9]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s9]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s9(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s9]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s9]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.

-spec s10(cast, {pid(), {invite_ok}, list()} | {pid(), {cancel_ok}, list()}, state_data()) -> {next_state, s11, state_data()} | {next_state, s5, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s10(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s10]: Purging stale event ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s10(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s10]: Callback had no clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s5, _} -> after_transition(commit_if_taken(Next, mc1, right));
          {next_state, s5, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_caller[s10]: Postponing not-ready event ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {CalleePid, {cancel_ok}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_caller[s10]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s10(cast, {CalleePid, {cancel_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s10]: Callback had no clause for ~p, postponing~n", [{cancel_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s11, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s11, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_caller[s10]: Postponing not-ready event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s10]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s10]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s10]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s10]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s10(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s10]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s10]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.

-spec s11(cast, {pid(), {terminated}, list()}, state_data()) -> {next_state, s12, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s11(cast, {CalleePid, {terminated}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_caller[s11]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s11(cast, {CalleePid, {terminated}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s11]: Callback had no clause for ~p, postponing~n", [{terminated}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_caller[s11]: Postponing not-ready event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s11]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s11]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s11]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s11]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s11]: Purging stale interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s11]: Callback had no interrupt clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_caller[s11]: Postponing not-ready interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s11(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s11]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s11]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end.

-spec s12(internal, {ack}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s12(internal, {ack}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s12(internal, {ack}, Data),
    after_transition(Next);
s12(cast, {_CalleePid, {ringing}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s12]: Purging stale event ~p~n", [{ringing}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s12]: Postponing event ~p~n", [{ringing}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CalleePid, {bye_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s12]: Purging stale event ~p~n", [{bye_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s12]: Postponing event ~p~n", [{bye_ok}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {CalleePid, {invite_ok}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_caller[s12]: Purging stale interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s9(cast, {CalleePid, {invite_ok}}, Data)
               catch error:function_clause ->
                 io:format("gen_caller[s12]: Callback had no interrupt clause for ~p, postponing~n", [{invite_ok}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_caller[s12]: Postponing not-ready interrupt ~p~n", [{invite_ok}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CalleePid, {cancel_ok}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s12]: Purging stale event ~p~n", [{cancel_ok}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s12]: Postponing event ~p~n", [{cancel_ok}]),
        {keep_state, Data, [postpone]}
    end;
s12(cast, {_CalleePid, {terminated}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_caller[s12]: Purging stale event ~p~n", [{terminated}]),
        {keep_state, Data};
      false ->
        io:format("gen_caller[s12]: Postponing event ~p~n", [{terminated}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s1_invite(CalleePid :: pid(), _Data :: state_data()) -> ok.
send_s1_invite(CalleePid, _Data) ->
    gen_statem:cast(CalleePid, {self(), {invite}}).


-spec send_s5_ack(CalleePid :: pid(), _Data :: state_data()) -> ok.
send_s5_ack(CalleePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CalleePid, {self(), {ack}, Path}).


-spec send_s6_bye(CalleePid :: pid(), _Data :: state_data()) -> ok.
send_s6_bye(CalleePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CalleePid, {self(), {bye}, Path}).


-spec send_s9_cancel(CalleePid :: pid(), _Data :: state_data()) -> ok.
send_s9_cancel(CalleePid, _Data) ->
    Path = branch_path(mc1, left),
    set_current_path(Path),
    gen_statem:cast(CalleePid, {self(), {cancel}, Path}).


-spec send_s12_ack(CalleePid :: pid(), _Data :: state_data()) -> ok.
send_s12_ack(CalleePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CalleePid, {self(), {ack}, Path}).


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

