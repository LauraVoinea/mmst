%%%-------------------------------------------------------------------
%%% quote_sup.erl: one of each role, each run once.
%%%-------------------------------------------------------------------
-module(quote_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Role = fun(M) -> #{id => M, start => {M, start_link, []}, restart => temporary,
                       shutdown => 5000, type => worker} end,
    {ok, {#{strategy => one_for_one, intensity => 5, period => 10},
          [Role(warehouse), Role(shop), Role(customer)]}}.
