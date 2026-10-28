%%%-------------------------------------------------------------------
%%% callee.erl: SipCancel's Callee, written by hand; gen_callee is generated.
%%%
%%% Callee is the observer. It rings for ANSWER_MS: a CANCEL in that time ends the call,
%%% with 200 for the CANCEL and 487 for the INVITE (left); otherwise Callee answers with
%%% 200 for the INVITE (right). A CANCEL that crossed the answer on the way is stale:
%%% gen_callee purges it.
%%%-------------------------------------------------------------------
-module(callee).
-behaviour(gen_callee).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s1/3, s3/3, s5/3, s6/3, s7/3, s9/3, s10/3, s11/3, s12/3]).

-include("callee.hrl").

%% How long it rings before Callee answers. Caller cancels after RING_MS, in caller.erl.
-define(ANSWER_MS, 500).

start_link() ->
    gen_callee:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s1, #state_data{}}.

s1(cast, {_Caller, {invite}}, Data0) ->
    Data = connect(Data0),
    {next_state, s3, Data, [{next_event, internal, {ringing}}]}.

s3(internal, {ringing}, Data) ->
    io:format("callee: ringing~n", []),
    sip_util:network(),
    gen_callee:send_s3_ringing(Data#state_data.caller_pid, Data),
    {next_state, s9, Data, [{next_event, internal, {invite_ok}}]}.

%% The mixed choice. gen_callee passes only protocol events to this module, so the
%% ringing happens in the first one: until a CANCEL is in the mailbox, or not.
s9(internal, {invite_ok}, Data) ->
    case sip_util:wait_for(cancel, ?ANSWER_MS) of
        arrived ->
            {keep_state, Data};                          % gen_callee hands it over next
        gave_up ->
            io:format("callee: answering~n", []),
            sip_util:network(),
            gen_callee:send_s9_invite_ok(Data#state_data.caller_pid, Data),
            {next_state, s5, Data}
    end;
s9(cast, {_Caller, {cancel}}, Data) ->
    io:format("callee: cancelled before answering~n", []),
    {next_state, s10, Data, [{next_event, internal, {cancel_ok}}]}.

%% Left: 200 for the CANCEL, 487 for the INVITE, then Caller's ACK.
s10(internal, {cancel_ok}, Data) ->
    sip_util:network(),
    gen_callee:send_s10_cancel_ok(Data#state_data.caller_pid, Data),
    {next_state, s11, Data, [{next_event, internal, {terminated}}]}.

s11(internal, {terminated}, Data) ->
    sip_util:network(),
    gen_callee:send_s11_terminated(Data#state_data.caller_pid, Data),
    {next_state, s12, Data}.

s12(cast, {_Caller, {ack}}, Data) ->
    {stop, normal, Data}.

%% Right: Caller's ACK, then its BYE, answered with 200.
s5(cast, {_Caller, {ack}}, Data) ->
    {next_state, s6, Data}.

s6(cast, {_Caller, {bye}}, Data) ->
    io:format("callee: Caller hung up~n", []),
    {next_state, s7, Data, [{next_event, internal, {bye_ok}}]}.

s7(internal, {bye_ok}, Data) ->
    sip_util:network(),
    gen_callee:send_s7_bye_ok(Data#state_data.caller_pid, Data),
    {stop, normal, Data}.

%% Caller by its registered name, waiting up to 2 s for it to start.
connect(Data) ->
    Data#state_data{caller_pid = sip_util:whereis(caller)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
