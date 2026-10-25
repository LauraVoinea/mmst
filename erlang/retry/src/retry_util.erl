%%%-------------------------------------------------------------------
%%% retry_util.erl: what Retry's three roles share.
%%%-------------------------------------------------------------------
-module(retry_util).

-export([whereis/1]).

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
