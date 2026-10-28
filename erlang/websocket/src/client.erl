%%%-------------------------------------------------------------------
%%% client.erl: WebSocketClose's Client, written by hand; gen_client is generated.
%%%
%%% Pauses, then sends a frame; once Server acknowledges it, Client starts the closing
%%% handshake: close, then Server's close_ack. Server may close first: then Client
%%% answers with close_ack.
%%%-------------------------------------------------------------------
-module(client).
-behaviour(gen_client).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s3/3, s5/3, s6/3, s7/3, s8/3]).

-include("client.hrl").

%% How long Client pauses before it sends its frame. Server closes an idle connection
%% after IDLE_MS, in server.erl: set this above it, say 1500, and Run again.
-define(PAUSE_MS, 200).

start_link() ->
    gen_client:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s5, #state_data{}, [{next_event, internal, {frame}}]}.

%% The mixed choice. Left: a frame, its ack, then the closing handshake. Right: Server's
%% close, whenever it comes.
s5(internal, {frame}, Data0) ->
    Data = connect(Data0),
    timer:sleep(?PAUSE_MS),
    io:format("client: sending a frame~n", []),
    gen_client:send_s5_frame(Data#state_data.server_pid, Data),
    {next_state, s6, Data};
s5(cast, {_Server, {close}}, Data) ->
    closed(connect(Data)).

s6(cast, {_Server, {ack}}, Data) ->
    io:format("client: frame acknowledged, closing~n", []),
    {next_state, s7, Data, [{next_event, internal, {close}}]};
s6(cast, {_Server, {close}}, Data) ->
    closed(Data).

s7(internal, {close}, Data) ->
    gen_client:send_s7_close(Data#state_data.server_pid, Data),
    {next_state, s8, Data}.

s8(cast, {_Server, {close_ack}}, Data) ->
    io:format("client: closed~n", []),
    {stop, normal, Data}.

%% Right: Server closed first, and Client answers.
closed(Data) ->
    io:format("client: Server closed the connection, answering~n", []),
    {next_state, s3, Data, [{next_event, internal, {close_ack}}]}.

s3(internal, {close_ack}, Data) ->
    gen_client:send_s3_close_ack(Data#state_data.server_pid, Data),
    {stop, normal, Data}.

%% Server by its registered name, waiting up to 2 s for it to start.
connect(Data) ->
    Data#state_data{server_pid = websocket_util:whereis(server)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
