%%%-------------------------------------------------------------------
%%% lease_app.erl: starts lease_sup, which starts the three roles.
%%%-------------------------------------------------------------------
-module(lease_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    lease_sup:start_link().

stop(_State) ->
    ok.
