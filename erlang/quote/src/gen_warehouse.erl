
%%%-------------------------------------------------------------------
%%% gen_warehouse.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_warehouse).
-behaviour(gen_statem).

%% Public API
-export([start_link/2, callback_mode/0]).

%% gen_statem callbacks
-export([init/1, code_change/4, terminate/3,
  s4/3,
  s5/3,
  s6/3,
  send_s6_delivery/4,
  send_s6_delivery/2]).

%% Types & records
-include("warehouse.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s4, state_data()}.
-callback s4(cast, {pid(), {address, {term()}}} | {pid(), {cancel}}, state_data()) -> {next_state, s5, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s5(cast, {pid(), {cancel}} | {pid(), {reserve, {term(), term()}}}, state_data()) -> {next_state, s6, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s6(internal, {delivery}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_warehouse, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "warehouse_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s4, state_data()}.
init({CallbackModule, _Args}) ->
    io:format("warehouse: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    enter_mc(mc1),
    CallbackModule:init([]).

%% ---------- State functions----------
%% Mixed-choice entry state
-spec s4(cast, {pid(), {address, {term()}}, list()} | {pid(), {cancel}, list()}, state_data()) -> {next_state, s5, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s4(cast, {CustomerPid, {address, {Postcode}}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, left)) of
      stale ->
        io:format("gen_warehouse[s4]: Purging stale event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s4(cast, {CustomerPid, {address, {Postcode}}}, Data)
               catch error:function_clause ->
                 io:format("gen_warehouse[s4]: Callback had no clause for ~p, postponing~n", [{address, {Postcode}}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s5, _} -> after_transition(speculate_if_taken(Next, mc1, left));
          {next_state, s5, _, _} -> after_transition(speculate_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_warehouse[s4]: Postponing not-ready event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data, [postpone]}
    end;
s4(cast, {ShopPid, {cancel}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_warehouse[s4]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s4(cast, {ShopPid, {cancel}}, Data)
               catch error:function_clause ->
                 io:format("gen_warehouse[s4]: Callback had no clause for ~p, postponing~n", [{cancel}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {stop, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_warehouse[s4]: Postponing not-ready event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end;
s4(cast, {_ShopPid, {reserve, {Item, Qty}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_warehouse[s4]: Purging stale event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data};
      false ->
        io:format("gen_warehouse[s4]: Postponing event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data, [postpone]}
    end.

-spec s5(cast, {pid(), {cancel}, list()} | {pid(), {reserve, {term(), term()}}, list()}, state_data()) -> {next_state, s6, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s5(cast, {ShopPid, {cancel}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_warehouse[s5]: Purging stale event ~p~n", [{cancel}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s5(cast, {ShopPid, {cancel}}, Data)
               catch error:function_clause ->
                 io:format("gen_warehouse[s5]: Callback had no clause for ~p, postponing~n", [{cancel}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {stop, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_warehouse[s5]: Postponing not-ready event ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {ShopPid, {reserve, {Item, Qty}}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_warehouse[s5]: Purging stale event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s5(cast, {ShopPid, {reserve, {Item, Qty}}}, Data)
               catch error:function_clause ->
                 io:format("gen_warehouse[s5]: Callback had no clause for ~p, postponing~n", [{reserve, {Item, Qty}}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s6, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s6, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_warehouse[s5]: Postponing not-ready event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_CustomerPid, {address, {Postcode}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_warehouse[s5]: Purging stale event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data};
      false ->
        io:format("gen_warehouse[s5]: Postponing event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data, [postpone]}
    end.

-spec s6(internal, {delivery}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s6(internal, {delivery}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s6(internal, {delivery}, Data),
    after_transition(Next);
s6(cast, {ShopPid, {cancel}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_warehouse[s6]: Purging stale interrupt ~p~n", [{cancel}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s4(cast, {ShopPid, {cancel}}, Data)
               catch error:function_clause ->
                 io:format("gen_warehouse[s6]: Callback had no interrupt clause for ~p, postponing~n", [{cancel}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_warehouse[s6]: Postponing not-ready interrupt ~p~n", [{cancel}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_CustomerPid, {address, {Postcode}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_warehouse[s6]: Purging stale event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data};
      false ->
        io:format("gen_warehouse[s6]: Postponing event ~p~n", [{address, {Postcode}}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_ShopPid, {reserve, {Item, Qty}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_warehouse[s6]: Purging stale event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data};
      false ->
        io:format("gen_warehouse[s6]: Postponing event ~p~n", [{reserve, {Item, Qty}}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s6_delivery(CustomerPid :: pid(), term(), term(), _Data :: state_data()) -> ok.
send_s6_delivery(CustomerPid, Days, Pence, _Data) ->
    Path = current_path(),
    gen_statem:cast(CustomerPid, {self(), {delivery, {Days, Pence}}, Path}).


-spec send_s6_delivery(CustomerPid :: pid(), _Data :: state_data()) -> ok.
send_s6_delivery(CustomerPid, _Data) ->
    Path = current_path(),
    gen_statem:cast(CustomerPid, {self(), {delivery}, Path}).


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

speculate_if_taken(Next, McId, Side) ->
    case Next of
      {keep_state, _} -> Next;
      {keep_state, _, _} -> Next;
      _ -> set_current_path(branch_path(McId, Side)), Next
    end.

after_transition({next_state, s4, _} = Next) -> enter_mc(mc1), Next;
after_transition({next_state, s4, _, _} = Next) -> enter_mc(mc1), Next;
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

