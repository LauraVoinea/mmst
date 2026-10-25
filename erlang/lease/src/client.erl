%%%-------------------------------------------------------------------
%%% client.erl: Lease's Client, written by hand; gen_client is generated.
%%%
%%% Pauses, then renews its lease with LockService and sends a write to Storage,
%%% and waits to hear that both went through. LockService may let the lease expire
%%% first: then the write is fenced.
%%%-------------------------------------------------------------------
-module(client).
-behaviour(gen_client).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s4/3, s5/3, s6/3, s7/3]).

-include("client.hrl").

%% How long Client pauses before it renews. The lease lasts LEASE_MS, in
%% lockservice.erl: set this above it, say 1500, and Run again.
-define(PAUSE_MS, 300).
-define(VALUE, 42).

start_link() ->
    gen_client:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s4, #state_data{}, [{next_event, internal, {renew}}]}.

%% The mixed choice. Left: renew with LockService, write to Storage, then hear
%% renewed and written. Right: LockService says the lease expired, whenever that comes.
s4(internal, {renew}, Data0) ->
    Data = connect(Data0),
    timer:sleep(?PAUSE_MS),
    io:format("client: renewing the lease and writing ~b~n", [?VALUE]),
    gen_client:send_s4_renew(Data#state_data.lockservice_pid, Data),
    {next_state, s5, Data, [{next_event, internal, {write}}]};
s4(cast, {_LockService, {expired}}, Data) ->
    expired(Data).

s5(internal, {write}, Data) ->
    gen_client:send_s5_write(Data#state_data.storage_pid, ?VALUE, Data),
    {next_state, s6, Data};
s5(cast, {_LockService, {expired}}, Data) ->
    expired(Data).

s6(cast, {_LockService, {renewed}}, Data) ->
    io:format("client: lease renewed~n", []),
    {next_state, s7, Data};
s6(cast, {_LockService, {expired}}, Data) ->
    expired(Data).

s7(cast, {_Storage, {written}}, Data) ->
    io:format("client: write ~b done~n", [?VALUE]),
    {stop, normal, Data}.

expired(Data) ->
    io:format("client: too late, the lease expired~n", []),
    {stop, normal, Data}.

%% LockService and Storage by their registered names, waiting up to 2 s for them to start.
connect(Data) ->
    Data#state_data{lockservice_pid = lease_util:whereis(lockservice), storage_pid = lease_util:whereis(storage)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
