%%%-------------------------------------------------------------------
%%% quote_util.erl: what Quote's three roles share.
%%%-------------------------------------------------------------------
-module(quote_util).

-export([format/1, whereis/1]).

%% Pence as pounds: 1050 -> "£10.50".
format(Pence) ->
    unicode:characters_to_list(io_lib:format("£~b.~2..0b", [Pence div 100, Pence rem 100])).

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
