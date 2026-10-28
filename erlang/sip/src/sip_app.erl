%%%-------------------------------------------------------------------
%%% sip_app.erl: starts sip_sup, which starts the two roles.
%%%-------------------------------------------------------------------
-module(sip_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    sip_sup:start_link().

stop(_State) ->
    ok.
