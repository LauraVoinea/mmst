%%%-------------------------------------------------------------------
%%% quote_app.erl: starts quote_sup, which starts the three roles.
%%%-------------------------------------------------------------------
-module(quote_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    quote_sup:start_link().

stop(_State) ->
    ok.
