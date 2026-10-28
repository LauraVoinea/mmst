%%%-------------------------------------------------------------------
%%% sip_util.erl: what SipCancel's two roles share.
%%%-------------------------------------------------------------------
-module(sip_util).

-export([whereis/1, network/0, wait_for/2]).

%% How long a message takes to cross the network. Each role waits this long before each
%% send, so a CANCEL and an answer sent less than NETWORK_MS apart cross on the way.
-define(NETWORK_MS, 100).

%% A role's pid by its registered name, waiting up to 2 s for it to start.
whereis(Name) ->
    whereis(Name, 200).

whereis(Name, 0) ->
    erlang:whereis(Name);
whereis(Name, Tries) ->
    case erlang:whereis(Name) of
        undefined -> timer:sleep(10), whereis(Name, Tries - 1);
        Pid -> Pid
    end.

%% The time a message takes on the network, before each send.
network() ->
    timer:sleep(?NETWORK_MS).

%% arrived as soon as a message labelled Label is in the mailbox, gave_up after Ms. Looks
%% every 10 ms and takes nothing out: the gen_ module reads the message itself, path and
%% all.
wait_for(Label, Ms) ->
    wait_until(Label, erlang:monotonic_time(millisecond) + Ms).

wait_until(Label, Deadline) ->
    {messages, Queue} = erlang:process_info(self(), messages),
    case lists:any(fun(M) -> labelled(Label, M) end, Queue) of
        true -> arrived;
        false ->
            case Deadline - erlang:monotonic_time(millisecond) of
                Left when Left =< 0 -> gave_up;
                Left -> timer:sleep(min(10, Left)), wait_until(Label, Deadline)
            end
    end.

labelled(Label, {'$gen_cast', {_From, {Label}, _Path}}) -> true;
labelled(_Label, _) -> false.
