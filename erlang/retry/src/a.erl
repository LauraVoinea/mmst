%%%-------------------------------------------------------------------
%%% a.erl: Retry's A, written by hand; gen_a is generated.
%%%
%%% Each round A goes along at once: it sends a1 to B and a2 to C, then waits for a4
%%% and a5 (left), or TOa (right), and then the next round. A takes a while before it
%%% sends, PAUSES_MS, round by round.
%%%-------------------------------------------------------------------
-module(a).
-behaviour(gen_a).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s6/3, s7/3, s8/3, s9/3]).

-include("a.hrl").

%% How long A takes before it sends a1 and a2, round by round: too long for B's first two
%% waits, 100 and 200 ms, in time for the third, 400 ms.
-define(PAUSES_MS, [200, 300, 0]).

start_link() ->
    gen_a:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s6, #state_data{}, [{next_event, internal, {a1}}]}.

%% The mixed choice. Left: a1 to B, a2 to C, then a4 and a5. Right: TOa, whenever it comes.
s6(internal, {a1}, Data0) ->
    Data = connect(Data0),
    Round = Data#state_data.round,
    Pause = pause(Round),
    timer:sleep(Pause),
    io:format("A: round ~b, a1 to B and a2 to C, after ~b ms~n", [Round, Pause]),
    gen_a:send_s6_a1(Data#state_data.b_pid, Data),
    {next_state, s7, Data, [{next_event, internal, {a2}}]};
s6(cast, {_B, {'TOa'}}, Data) ->
    again(Data).

s7(internal, {a2}, Data) ->
    gen_a:send_s7_a2(Data#state_data.c_pid, Data),
    {next_state, s8, Data};
s7(cast, {_B, {'TOa'}}, Data) ->
    again(Data).

s8(cast, {_B, {a4}}, Data) ->
    {next_state, s9, Data};
s8(cast, {_B, {'TOa'}}, Data) ->
    again(Data).

s9(cast, {_C, {a5}}, Data) ->
    io:format("A: round ~b, a4 and a5: done~n", [Data#state_data.round]),
    {stop, normal, Data}.

again(Data) ->
    io:format("A: round ~b, TOa: again~n", [Data#state_data.round]),
    {next_state, s6, Data#state_data{round = Data#state_data.round + 1}, [{next_event, internal, {a1}}]}.

pause(Round) ->
    lists:nth(min(Round, length(?PAUSES_MS)), ?PAUSES_MS).

connect(Data) ->
    Data#state_data{b_pid = retry_util:whereis(b), c_pid = retry_util:whereis(c)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
