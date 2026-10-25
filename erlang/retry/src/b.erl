%%%-------------------------------------------------------------------
%%% b.erl: Retry's B, written by hand; gen_b is generated.
%%%
%%% B is the observer. Each round it waits for a1: if a1 comes in time, B goes along
%%% (left); if not, B overrules with TOa and TOc, and the three start again (right).
%%% B waits WAIT_MS in the first round and twice as long in each next one: a retry
%%% with backoff. An a1 that A sent in a round B overruled arrives late, is stale, and
%%% gen_b drops it.
%%%-------------------------------------------------------------------
-module(b).
-behaviour(gen_b).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s4/3, s7/3, s8/3, s9/3]).

-include("b.hrl").

%% How long B waits for a1 in the first round; it doubles each round.
-define(WAIT_MS, 100).

start_link() ->
    gen_b:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s7, #state_data{}, [{next_event, internal, {'TOa'}}]}.

%% The mixed choice. gen_b passes only protocol events to this module, so the waiting
%% happens in the first one: until an a1 of this round is in the mailbox, or not.
s7(internal, {'TOa'}, Data0) ->
    Data = connect(Data0),
    Round = Data#state_data.round,
    Wait = ?WAIT_MS bsl (Round - 1),
    case wait_for_a1(Round, Wait) of
        arrived ->
            {keep_state, Data};                          % gen_b hands it over next
        gave_up ->
            io:format("B: round ~b, no a1 after ~b ms: TOa to A, TOc to C~n", [Round, Wait]),
            gen_b:send_s7_TOa(Data#state_data.a_pid, Data),
            {next_state, s4, Data, [{next_event, internal, {'TOc'}}]}
    end;
s7(cast, {_A, {a1}}, Data) ->
    io:format("B: round ~b, a1 in time: going along~n", [Data#state_data.round]),
    {next_state, s8, Data, [{next_event, internal, {a3}}]}.

%% Right: after TOa to A, TOc to C, and the next round.
s4(internal, {'TOc'}, Data) ->
    gen_b:send_s4_TOc(Data#state_data.c_pid, Data),
    {next_state, s7, Data#state_data{round = Data#state_data.round + 1}, [{next_event, internal, {'TOa'}}]}.

%% Left: a3 to C, then a4 to A.
s8(internal, {a3}, Data) ->
    gen_b:send_s8_a3(Data#state_data.c_pid, Data),
    {next_state, s9, Data, [{next_event, internal, {a4}}]}.

s9(internal, {a4}, Data) ->
    gen_b:send_s9_a4(Data#state_data.a_pid, Data),
    {stop, normal, Data}.

%% arrived as soon as an a1 of this round is in the mailbox, gave_up after Ms. Looks every
%% 10 ms and takes nothing out: gen_b reads a1 itself. An a1 carries the sides A was on,
%% one per round, so one from an earlier round is shorter: it is stale, gen_b drops it,
%% and it does not count.
wait_for_a1(Round, Ms) ->
    wait_until(Round, erlang:monotonic_time(millisecond) + Ms).

wait_until(Round, Deadline) ->
    {messages, Queue} = erlang:process_info(self(), messages),
    case lists:any(fun(M) -> is_a1(M, Round) end, Queue) of
        true -> arrived;
        false ->
            case Deadline - erlang:monotonic_time(millisecond) of
                Left when Left =< 0 -> gave_up;
                Left -> timer:sleep(min(10, Left)), wait_until(Round, Deadline)
            end
    end.

is_a1({'$gen_cast', {_From, {a1}, Path}}, Round) -> length(Path) =:= Round;
is_a1(_, _) -> false.

connect(Data) ->
    Data#state_data{a_pid = retry_util:whereis(a), c_pid = retry_util:whereis(c)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
