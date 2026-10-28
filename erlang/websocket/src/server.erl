%%%-------------------------------------------------------------------
%%% server.erl: WebSocketClose's Server, written by hand; gen_server is generated.
%%%
%%% Server is the observer. It waits IDLE_MS for a frame: if one comes, it acknowledges
%%% it and answers Client's close (left); if not, it closes the idle connection itself
%%% and waits for Client's close_ack (right). A frame Client sent before Server's close
%%% reached it is stale: gen_server purges it while Server waits.
%%%-------------------------------------------------------------------
-module(server).
-behaviour(gen_server).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s3/3, s5/3, s6/3, s7/3, s8/3]).

-include("server.hrl").

%% How long Server waits for a frame before it closes the connection.
-define(IDLE_MS, 1000).

start_link() ->
    gen_server:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    {ok, s5, #state_data{}, [{next_event, internal, {close}}]}.

%% The mixed choice. gen_server passes only protocol events to this module, so the
%% waiting happens in the first one: until a frame is in the mailbox, or not.
s5(internal, {close}, Data0) ->
    Data = connect(Data0),
    case wait_for_frame(?IDLE_MS) of
        arrived ->
            {keep_state, Data};                          % gen_server hands it over next
        gave_up ->
            io:format("server: no frame after ~b ms, closing~n", [?IDLE_MS]),
            gen_server:send_s5_close(Data#state_data.client_pid, Data),
            {next_state, s3, Data}
    end;
s5(cast, {_Client, {frame}}, Data) ->
    io:format("server: frame received~n", []),
    {next_state, s6, Data, [{next_event, internal, {ack}}]}.

%% Left: ack the frame, then answer Client's close.
s6(internal, {ack}, Data) ->
    gen_server:send_s6_ack(Data#state_data.client_pid, Data),
    {next_state, s7, Data}.

s7(cast, {_Client, {close}}, Data) ->
    io:format("server: Client closes, answering~n", []),
    {next_state, s8, Data, [{next_event, internal, {close_ack}}]}.

s8(internal, {close_ack}, Data) ->
    gen_server:send_s8_close_ack(Data#state_data.client_pid, Data),
    {stop, normal, Data}.

%% Right: after close, Client's close_ack.
s3(cast, {_Client, {close_ack}}, Data) ->
    io:format("server: closed~n", []),
    {stop, normal, Data}.

%% arrived as soon as a frame is in the mailbox, gave_up after Ms. Looks every 10 ms
%% and takes nothing out: gen_server reads the frame itself, path and all.
wait_for_frame(Ms) ->
    wait_until(erlang:monotonic_time(millisecond) + Ms).

wait_until(Deadline) ->
    {messages, Queue} = erlang:process_info(self(), messages),
    case lists:any(fun is_frame/1, Queue) of
        true -> arrived;
        false ->
            case Deadline - erlang:monotonic_time(millisecond) of
                Left when Left =< 0 -> gave_up;
                Left -> timer:sleep(min(10, Left)), wait_until(Deadline)
            end
    end.

is_frame({'$gen_cast', {_From, {frame}, _Path}}) -> true;
is_frame(_) -> false.

%% Client by its registered name, waiting up to 2 s for it to start.
connect(Data) ->
    Data#state_data{client_pid = websocket_util:whereis(client)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
