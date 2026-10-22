%%%-------------------------------------------------------------------
%%% customer.erl: Quote's Customer, written by hand; gen_customer is generated.
%%%
%%% Orders a few notebooks from Shop and gives Warehouse the postcode, then waits
%%% for the price and the delivery. Shop may give up first: then the quote expired.
%%%-------------------------------------------------------------------
-module(customer).
-behaviour(gen_customer).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s4/3, s5/3, s6/3, s7/3]).

-include("customer.hrl").

%% How long Customer thinks before ordering. Shop waits PATIENCE_MS, in shop.erl:
%% set this above it, say 1500, and Run again.
-define(THINK_MS, 300).
-define(ITEM, "notebook").
-define(QTY, 3).
-define(POSTCODE, "G12 8QQ").

start_link() ->
    gen_customer:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    io:setopts([{encoding, unicode}]),                   % for the £ in prices
    {ok, s4, #state_data{}, [{next_event, internal, {order}}]}.

%% The mixed choice. Left: order from Shop, address to Warehouse, then the price and
%% the delivery. Right: Shop says the quote expired, whenever that comes.
s4(internal, {order}, Data0) ->
    Data = connect(Data0),
    timer:sleep(?THINK_MS),
    io:format("customer: ~b x ~s, please, to ~s~n", [?QTY, ?ITEM, ?POSTCODE]),
    gen_customer:send_s4_order(Data#state_data.shop_pid, ?ITEM, ?QTY, Data),
    {next_state, s5, Data, [{next_event, internal, {address}}]};
s4(cast, {_Shop, {expired}}, Data) ->
    expired(Data).

s5(internal, {address}, Data) ->
    gen_customer:send_s5_address(Data#state_data.warehouse_pid, ?POSTCODE, Data),
    {next_state, s6, Data};
s5(cast, {_Shop, {expired}}, Data) ->
    expired(Data).

s6(cast, {_Shop, {price, {Pence}}}, Data) ->
    io:format("customer: the shop says ~ts~n", [quote_util:format(Pence)]),
    {next_state, s7, Data#state_data{price = Pence}};
s6(cast, {_Shop, {expired}}, Data) ->
    expired(Data).

s7(cast, {_Warehouse, {delivery, {Days, Charge}}}, #state_data{price = Price} = Data) ->
    io:format("customer: ~ts in all, here in ~b day~s~n",
              [quote_util:format(Price + Charge), Days, plural(Days)]),
    {stop, normal, Data}.

expired(Data) ->
    io:format("customer: too late, the quote expired~n", []),
    {stop, normal, Data}.

plural(1) -> "";
plural(_) -> "s".

%% Shop and Warehouse by their registered names, waiting up to 2 s for them to start.
connect(Data) ->
    Data#state_data{shop_pid = quote_util:whereis(shop), warehouse_pid = quote_util:whereis(warehouse)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
