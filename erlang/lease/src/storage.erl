%%%-------------------------------------------------------------------
%%% storage.erl: Lease's Storage, written by hand; gen_storage is generated.
%%%
%%% Holds Client's write until LockService says the lease is valid, then applies it
%%% and tells Client; drops it if LockService fences Storage instead.
%%%-------------------------------------------------------------------
-module(storage).
-behaviour(gen_storage).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s4/3, s5/3, s6/3]).

-include("storage.hrl").

start_link() ->
    gen_storage:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s4, #state_data{}}.

%% The mixed choice: the write from Client (left), or fence from LockService (right).
s4(cast, {_Client, {write, {Value}}}, Data) ->
    io:format("storage: write ~b pending~n", [Value]),
    {next_state, s5, Data#state_data{pending = Value}};
s4(cast, {_LockService, {fence}}, Data) ->
    io:format("storage: fenced, nothing pending~n", []),
    {stop, normal, Data}.

s5(cast, {_LockService, {valid}}, #state_data{pending = Value} = Data) ->
    io:format("storage: write ~b applied~n", [Value]),
    {next_state, s6, Data, [{next_event, internal, {written}}]};
s5(cast, {_LockService, {fence}}, #state_data{pending = Value} = Data) ->
    io:format("storage: fenced, write ~b dropped~n", [Value]),
    {stop, normal, Data}.

s6(internal, {written}, Data0) ->
    Data = connect(Data0),
    gen_storage:send_s6_written(Data#state_data.client_pid, Data),
    {stop, normal, Data}.

connect(Data) ->
    Data#state_data{client_pid = lease_util:whereis(client), lockservice_pid = lease_util:whereis(lockservice)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
