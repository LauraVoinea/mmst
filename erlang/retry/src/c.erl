%%%-------------------------------------------------------------------
%%% c.erl: Retry's C, written by hand; gen_c is generated.
%%%
%%% Each round C waits for a2 from A and a3 from B, then sends a5 to A (left), or hears
%%% TOc from B, and then the next round (right). An a2 that A sent in a round B overruled
%%% arrives after TOc, is stale, and gen_c drops it.
%%%-------------------------------------------------------------------
-module(c).
-behaviour(gen_c).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s6/3, s7/3, s8/3]).

-include("c.hrl").

start_link() ->
    gen_c:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s6, #state_data{}}.

%% The mixed choice. Left: a2 from A and a3 from B, then a5 to A. Right: TOc from B.
s6(cast, {_A, {a2}}, Data) ->
    {next_state, s7, Data};
s6(cast, {_B, {'TOc'}}, Data) ->
    again(Data).

s7(cast, {_B, {a3}}, Data) ->
    io:format("C: round ~b, a2 and a3: a5 to A~n", [Data#state_data.round]),
    {next_state, s8, Data, [{next_event, internal, {a5}}]};
s7(cast, {_B, {'TOc'}}, Data) ->
    again(Data).

s8(internal, {a5}, Data0) ->
    Data = Data0#state_data{a_pid = retry_util:whereis(a)},   % only A: B may have finished
    gen_c:send_s8_a5(Data#state_data.a_pid, Data),
    {stop, normal, Data}.

again(Data) ->
    io:format("C: round ~b, TOc: again~n", [Data#state_data.round]),
    {next_state, s6, Data#state_data{round = Data#state_data.round + 1}}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
