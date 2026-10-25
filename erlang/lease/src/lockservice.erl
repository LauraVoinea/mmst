%%%-------------------------------------------------------------------
%%% lockservice.erl: Lease's LockService, written by hand; gen_lockservice is generated.
%%%
%%% LockService is the observer. The lease lasts LEASE_MS: a renewal in time renews it
%%% and tells Storage the write is under a valid lease (left); otherwise the lease
%%% expires, and LockService tells Client and fences Storage (right). A renewal still
%%% on its way when the lease expires is stale: LockService finishes without reading it.
%%%-------------------------------------------------------------------
-module(lockservice).
-behaviour(gen_lockservice).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s3/3, s5/3, s6/3, s7/3]).

-include("lockservice.hrl").

%% How long the lease lasts without a renewal.
-define(LEASE_MS, 1000).

start_link() ->
    gen_lockservice:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s5, #state_data{}, [{next_event, internal, {expired}}]}.

%% The mixed choice. gen_lockservice passes only protocol events to this module, so the
%% waiting happens in the first one: until the renewal is in the mailbox, or not.
s5(internal, {expired}, Data0) ->
    Data = connect(Data0),
    case wait_for_renew(?LEASE_MS) of
        arrived ->
            {keep_state, Data};                          % gen_lockservice hands it over next
        gave_up ->
            io:format("lockservice: no renewal after ~b ms, lease expired~n", [?LEASE_MS]),
            gen_lockservice:send_s5_expired(Data#state_data.client_pid, Data),
            {next_state, s3, Data, [{next_event, internal, {fence}}]}
    end;
s5(cast, {_Client, {renew}}, Data) ->
    {next_state, s6, Data, [{next_event, internal, {valid}}]}.

%% Left: tell Storage the lease is valid, then tell Client.
s6(internal, {valid}, Data) ->
    io:format("lockservice: lease renewed~n", []),
    gen_lockservice:send_s6_valid(Data#state_data.storage_pid, Data),
    {next_state, s7, Data, [{next_event, internal, {renewed}}]}.

s7(internal, {renewed}, Data) ->
    gen_lockservice:send_s7_renewed(Data#state_data.client_pid, Data),
    {stop, normal, Data}.

%% Right: after expired to Client, fence Storage.
s3(internal, {fence}, Data) ->
    gen_lockservice:send_s3_fence(Data#state_data.storage_pid, Data),
    {stop, normal, Data}.

%% arrived as soon as a renewal is in the mailbox, gave_up after Ms. Looks every 10 ms
%% and takes nothing out: gen_lockservice reads the renewal itself, path and all.
wait_for_renew(Ms) ->
    wait_until(erlang:monotonic_time(millisecond) + Ms).

wait_until(Deadline) ->
    {messages, Queue} = erlang:process_info(self(), messages),
    case lists:any(fun is_renew/1, Queue) of
        true -> arrived;
        false ->
            case Deadline - erlang:monotonic_time(millisecond) of
                Left when Left =< 0 -> gave_up;
                Left -> timer:sleep(min(10, Left)), wait_until(Deadline)
            end
    end.

is_renew({'$gen_cast', {_From, {renew}, _Path}}) -> true;
is_renew(_) -> false.

connect(Data) ->
    Data#state_data{client_pid = lease_util:whereis(client), storage_pid = lease_util:whereis(storage)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
