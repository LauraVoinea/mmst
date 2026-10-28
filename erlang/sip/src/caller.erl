%%%-------------------------------------------------------------------
%%% caller.erl: SipCancel's Caller, written by hand; gen_caller is generated.
%%%
%%% Calls, then lets it ring for RING_MS. If Callee answers in that time, Caller ACKs the
%%% answer, talks, and hangs up with BYE. If not, Caller cancels: Callee confirms the
%%% CANCEL, ends the INVITE with 487, and Caller ACKs that. An answer can cross the
%%% CANCEL on the way: then Caller ACKs it and hangs up at once.
%%%-------------------------------------------------------------------
-module(caller).
-behaviour(gen_caller).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s1/3, s3/3, s5/3, s6/3, s7/3, s9/3, s10/3, s11/3, s12/3]).

-include("caller.hrl").

%% How long Caller lets it ring before it cancels. Callee answers after ANSWER_MS, in
%% callee.erl.
-define(RING_MS, 1000).

%% How long a call lasts once answered.
-define(TALK_MS, 300).

start_link() ->
    gen_caller:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s1, #state_data{}, [{next_event, internal, {invite}}]}.

s1(internal, {invite}, Data0) ->
    Data = connect(Data0),
    io:format("caller: calling~n", []),
    sip_util:network(),
    gen_caller:send_s1_invite(Data#state_data.callee_pid, Data),
    {next_state, s3, Data}.

s3(cast, {_Callee, {ringing}}, Data) ->
    {next_state, s9, Data, [{next_event, internal, {cancel}}]}.

%% The mixed choice. gen_caller passes only protocol events to this module, so the
%% ringing happens in the first one: until the answer is in the mailbox, or not.
s9(internal, {cancel}, Data) ->
    case sip_util:wait_for(invite_ok, ?RING_MS) of
        arrived ->
            {keep_state, Data};                          % gen_caller hands it over next
        gave_up ->
            io:format("caller: no answer after ~b ms, cancelling~n", [?RING_MS]),
            sip_util:network(),
            gen_caller:send_s9_cancel(Data#state_data.callee_pid, Data),
            {next_state, s10, Data#state_data{cancelled = true}}
    end;
s9(cast, {_Callee, {invite_ok}}, Data) ->
    answered(Data).

%% Left, after the CANCEL: Callee's 200 for it, then 487 for the INVITE, which Caller
%% ACKs. Or Callee's answer, if it crossed the CANCEL.
s10(cast, {_Callee, {cancel_ok}}, Data) ->
    {next_state, s11, Data};
s10(cast, {_Callee, {invite_ok}}, Data) ->
    answered(Data).

s11(cast, {_Callee, {terminated}}, Data) ->
    {next_state, s12, Data, [{next_event, internal, {ack}}]}.

s12(internal, {ack}, Data) ->
    sip_util:network(),
    gen_caller:send_s12_ack(Data#state_data.callee_pid, Data),
    io:format("caller: call cancelled~n", []),
    {stop, normal, Data}.

%% Right: Callee answered. Caller ACKs the answer, then hangs up with BYE: after talking,
%% or at once if the answer came after the CANCEL.
answered(#state_data{cancelled = true} = Data) ->
    io:format("caller: answered after the CANCEL, hanging up~n", []),
    {next_state, s5, Data, [{next_event, internal, {ack}}]};
answered(Data) ->
    io:format("caller: answered, talking~n", []),
    {next_state, s5, Data, [{next_event, internal, {ack}}]}.

s5(internal, {ack}, Data) ->
    sip_util:network(),
    gen_caller:send_s5_ack(Data#state_data.callee_pid, Data),
    {next_state, s6, Data, [{next_event, internal, {bye}}]}.

s6(internal, {bye}, Data) ->
    talk(Data),
    sip_util:network(),
    gen_caller:send_s6_bye(Data#state_data.callee_pid, Data),
    {next_state, s7, Data}.

s7(cast, {_Callee, {bye_ok}}, Data) ->
    io:format("caller: call ended~n", []),
    {stop, normal, Data}.

talk(#state_data{cancelled = true}) ->
    ok;
talk(_Data) ->
    timer:sleep(?TALK_MS),
    io:format("caller: hanging up~n", []).

%% Callee by its registered name, waiting up to 2 s for it to start.
connect(Data) ->
    Data#state_data{callee_pid = sip_util:whereis(callee)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
