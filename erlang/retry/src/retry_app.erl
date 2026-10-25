%%%-------------------------------------------------------------------
%%% retry_app.erl: starts retry_sup, which starts the three roles.
%%%-------------------------------------------------------------------
-module(retry_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    retry_sup:start_link().

stop(_State) ->
    ok.
