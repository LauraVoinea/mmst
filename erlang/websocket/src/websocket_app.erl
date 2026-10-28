%%%-------------------------------------------------------------------
%%% websocket_app.erl: starts websocket_sup, which starts the two roles.
%%%-------------------------------------------------------------------
-module(websocket_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    websocket_sup:start_link().

stop(_State) ->
    ok.
