
%%%-------------------------------------------------------------------
%%% gen_customer.erl — generated generic behaviour module (gen_statem)
%%%-------------------------------------------------------------------
-module(gen_customer).
-behaviour(gen_statem).

%% Public API
-export([start_link/2, callback_mode/0]).

%% gen_statem callbacks
-export([init/1, code_change/4, terminate/3,
  s4/3,
  s5/3,
  s6/3,
  s7/3,
  send_s4_order/2,
  send_s4_order/4,
  send_s5_address/2,
  send_s5_address/3]).

%% Types & records
-include("customer.hrl").
-export_type([state_data/0]).
-type state_data() :: #state_data{}.

-callback init(Args :: list()) -> {ok, s4, state_data(), [{next_event, internal, {order}}]}.
-callback s4(internal | cast, {order} | {pid(), {expired}}, state_data()) -> {next_state, s5, state_data()} | {next_state, s5, state_data(), [{next_event, internal, {order}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s5(internal | cast, {address} | {pid(), {expired}}, state_data()) -> {next_state, s6, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {address}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s6(cast, {pid(), {expired}} | {pid(), {price, {term()}}}, state_data()) -> {next_state, s7, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
-callback s7(cast, {pid(), {delivery, {term(), term()}}}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.

%% ===== API =====
-spec start_link(CallbackModule :: module(), Args :: list()) ->
    {ok, pid()} | {error, term()}.
start_link(CallbackModule, Args) ->
    case code:ensure_loaded(CallbackModule) of
        {module, CallbackModule} ->
            gen_statem:start_link({local, CallbackModule}, gen_customer, {CallbackModule, Args}, [{debug, [trace, {log_to_file, "customer_debug.log"}]}]);
        {error, Reason} ->
            {error, Reason}
    end.

-spec callback_mode() -> state_functions.
callback_mode() -> state_functions.

%% ===== gen_statem =====
-spec init({module(), list()}) ->
    {ok, s4, state_data(), [{next_event, internal, {order}}]}.
init({CallbackModule, _Args}) ->
    io:format("customer: Initializing with callback module ~p~n", [CallbackModule]),
    put(callback_module, CallbackModule),
    init_context(),
    enter_mc(mc1),
    CallbackModule:init([]).

%% ---------- State functions----------
%% Mixed-choice entry state
-spec s4(internal | cast, {order} | {pid(), {expired}, list()}, state_data()) -> {next_state, s5, state_data()} | {next_state, s5, state_data(), [{next_event, internal, {order}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s4(cast, {ShopPid, {expired}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_customer[s4]: Purging stale event ~p~n", [{expired}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s4(cast, {ShopPid, {expired}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s4]: Callback had no clause for ~p, postponing~n", [{expired}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {stop, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_customer[s4]: Postponing not-ready event ~p~n", [{expired}]),
        {keep_state, Data, [postpone]}
    end;
s4(internal, {order}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s4(internal, {order}, Data),
    after_transition(Next);
s4(cast, {_ShopPid, {price, {Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s4]: Purging stale event ~p~n", [{price, {Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s4]: Postponing event ~p~n", [{price, {Pence}}]),
        {keep_state, Data, [postpone]}
    end;
s4(cast, {_WarehousePid, {delivery, {Days, Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s4]: Purging stale event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s4]: Postponing event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data, [postpone]}
    end.

-spec s5(internal | cast, {address} | {pid(), {expired}, list()}, state_data()) -> {next_state, s6, state_data()} | {next_state, s6, state_data(), [{next_event, internal, {address}}] } | {keep_state, state_data()} | {stop, normal, state_data()}.
s5(internal, {address}, Data) ->
    CallbackModule = get(callback_module),
    Next = CallbackModule:s5(internal, {address}, Data),
    after_transition(Next);
s5(cast, {ShopPid, {expired}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_customer[s5]: Purging stale event ~p~n", [{expired}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s5(cast, {ShopPid, {expired}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s5]: Callback had no clause for ~p, postponing~n", [{expired}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {stop, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_customer[s5]: Postponing not-ready event ~p~n", [{expired}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_ShopPid, {price, {Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s5]: Purging stale event ~p~n", [{price, {Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s5]: Postponing event ~p~n", [{price, {Pence}}]),
        {keep_state, Data, [postpone]}
    end;
s5(cast, {_WarehousePid, {delivery, {Days, Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s5]: Purging stale event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s5]: Postponing event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data, [postpone]}
    end.

-spec s6(cast, {pid(), {price, {term()}}, list()} | {pid(), {expired}, list()}, state_data()) -> {next_state, s7, state_data()} | {keep_state, state_data()} | {stop, normal, state_data()}.
s6(cast, {ShopPid, {price, {Pence}}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_customer[s6]: Purging stale event ~p~n", [{price, {Pence}}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s6(cast, {ShopPid, {price, {Pence}}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s6]: Callback had no clause for ~p, postponing~n", [{price, {Pence}}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {next_state, s7, _} -> after_transition(commit_if_taken(Next, mc1, left));
          {next_state, s7, _, _} -> after_transition(commit_if_taken(Next, mc1, left));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_customer[s6]: Postponing not-ready event ~p~n", [{price, {Pence}}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {ShopPid, {expired}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_customer[s6]: Purging stale event ~p~n", [{expired}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s6(cast, {ShopPid, {expired}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s6]: Callback had no clause for ~p, postponing~n", [{expired}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          {stop, _, _} -> after_transition(commit_if_taken(Next, mc1, right));
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_customer[s6]: Postponing not-ready event ~p~n", [{expired}]),
        {keep_state, Data, [postpone]}
    end;
s6(cast, {_WarehousePid, {delivery, {Days, Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s6]: Purging stale event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s6]: Postponing event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data, [postpone]}
    end.

-spec s7(cast, {pid(), {delivery, {term(), term()}}, list()}, state_data()) -> {keep_state, state_data()} | {stop, normal, state_data()}.
s7(cast, {WarehousePid, {delivery, {Days, Pence}}, Path}, Data) ->
    case message_status(Path, current_path()) of
      stale ->
        io:format("gen_customer[s7]: Purging stale event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s7(cast, {WarehousePid, {delivery, {Days, Pence}}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s7]: Callback had no clause for ~p, postponing~n", [{delivery, {Days, Pence}}]),
                 {keep_state, Data, [postpone]}
               end,
        case Next of
          _ -> after_transition(Next)
        end;
      not_ready ->
        io:format("gen_customer[s7]: Postponing not-ready event ~p~n", [{delivery, {Days, Pence}}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {ShopPid, {expired}, Path}, Data) ->
    case message_status(Path, branch_path(mc1, right)) of
      stale ->
        io:format("gen_customer[s7]: Purging stale interrupt ~p~n", [{expired}]),
        {keep_state, Data};
      ready ->
        CallbackModule = get(callback_module),
        Next = try CallbackModule:s4(cast, {ShopPid, {expired}}, Data)
               catch error:function_clause ->
                 io:format("gen_customer[s7]: Callback had no interrupt clause for ~p, postponing~n", [{expired}]),
                 {keep_state, Data, [postpone]}
               end,
        after_transition(commit_if_taken(Next, mc1, right));
      not_ready ->
        io:format("gen_customer[s7]: Postponing not-ready interrupt ~p~n", [{expired}]),
        {keep_state, Data, [postpone]}
    end;
s7(cast, {_ShopPid, {price, {Pence}}, Path}, Data) ->
    case stale(Path) of
      true ->
        io:format("gen_customer[s7]: Purging stale event ~p~n", [{price, {Pence}}]),
        {keep_state, Data};
      false ->
        io:format("gen_customer[s7]: Postponing event ~p~n", [{price, {Pence}}]),
        {keep_state, Data, [postpone]}
    end.


%% ---------- Send helpers----------

-spec send_s4_order(ShopPid :: pid(), _Data :: state_data()) -> ok.
send_s4_order(ShopPid, _Data) ->
    Path = branch_path(mc1, left),
    set_current_path(Path),
    gen_statem:cast(ShopPid, {self(), {order}, Path}).


-spec send_s4_order(ShopPid :: pid(), term(), term(), _Data :: state_data()) -> ok.
send_s4_order(ShopPid, Item, Qty, _Data) ->
    Path = branch_path(mc1, left),
    set_current_path(Path),
    gen_statem:cast(ShopPid, {self(), {order, {Item, Qty}}, Path}).


-spec send_s5_address(WarehousePid :: pid(), _Data :: state_data()) -> ok.
send_s5_address(WarehousePid, _Data) ->
    Path = current_path(),
    gen_statem:cast(WarehousePid, {self(), {address}, Path}).


-spec send_s5_address(WarehousePid :: pid(), term(), _Data :: state_data()) -> ok.
send_s5_address(WarehousePid, Postcode, _Data) ->
    Path = current_path(),
    gen_statem:cast(WarehousePid, {self(), {address, {Postcode}}, Path}).


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

