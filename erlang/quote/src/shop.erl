%%%-------------------------------------------------------------------
%%% shop.erl: Quote's Shop, written by hand; gen_shop is generated.
%%%
%%% Shop is the observer. It holds the quote open for PATIENCE_MS: an order in time
%%% gets a price and the stock set aside (left); otherwise Shop withdraws the quote
%%% and tells Warehouse (right). An order already on its way when Shop gives up is
%%% purged as stale by gen_shop.
%%%-------------------------------------------------------------------
-module(shop).
-behaviour(gen_shop).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s3/3, s5/3, s6/3, s7/3]).

-include("shop.hrl").

%% How long Shop waits for the order.
-define(PATIENCE_MS, 1000).

%% Prices in pence; ten or more of a thing, 10% off.
-define(PRICES, #{"notebook" => 350, "pen" => 120, "mug" => 650}).

start_link() ->
    gen_shop:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    io:setopts([{encoding, unicode}]),                   % for the £ in prices
    {ok, s5, #state_data{}, [{next_event, internal, {expired}}]}.

%% The mixed choice. gen_shop passes only protocol events to this module, so the
%% waiting happens in the first one: until the order is in the mailbox, or not.
s5(internal, {expired}, Data0) ->
    Data = connect(Data0),
    case wait_for_order(?PATIENCE_MS) of
        arrived ->
            {keep_state, Data};                          % gen_shop hands it over next
        gave_up ->
            io:format("shop: no order after ~b ms, quote withdrawn~n", [?PATIENCE_MS]),
            gen_shop:send_s5_expired(Data#state_data.customer_pid, Data),
            {next_state, s3, Data, [{next_event, internal, {cancel}}]}
    end;
s5(cast, {_Customer, {order, {Item, Qty}}}, Data) ->
    {next_state, s6, Data#state_data{item = Item, qty = Qty}, [{next_event, internal, {reserve}}]}.

%% Left: set the stock aside, then quote.
s6(internal, {reserve}, #state_data{item = Item, qty = Qty} = Data) ->
    gen_shop:send_s6_reserve(Data#state_data.warehouse_pid, Item, Qty, Data),
    {next_state, s7, Data, [{next_event, internal, {price}}]}.

s7(internal, {price}, #state_data{item = Item, qty = Qty} = Data) ->
    Pence = price(Item, Qty),
    io:format("shop: ~b x ~s comes to ~ts~n", [Qty, Item, quote_util:format(Pence)]),
    gen_shop:send_s7_price(Data#state_data.customer_pid, Pence, Data),
    {stop, normal, Data}.

%% Right: after expired to Customer, cancel to Warehouse.
s3(internal, {cancel}, Data) ->
    gen_shop:send_s3_cancel(Data#state_data.warehouse_pid, Data),
    {stop, normal, Data}.

price(Item, Qty) ->
    Total = maps:get(Item, ?PRICES, 500) * Qty,                 % anything else, 500 each
    case Qty >= 10 of
        true -> Total - Total div 10;
        false -> Total
    end.

%% arrived as soon as an order is in the mailbox, gave_up after Ms. Looks every 10 ms
%% and takes nothing out: gen_shop reads the order itself, path and all.
wait_for_order(Ms) ->
    wait_until(erlang:monotonic_time(millisecond) + Ms).

wait_until(Deadline) ->
    {messages, Queue} = erlang:process_info(self(), messages),
    case lists:any(fun is_order/1, Queue) of
        true -> arrived;
        false ->
            case Deadline - erlang:monotonic_time(millisecond) of
                Left when Left =< 0 -> gave_up;
                Left -> timer:sleep(min(10, Left)), wait_until(Deadline)
            end
    end.

is_order({'$gen_cast', {_From, {order, _}, _Path}}) -> true;
is_order(_) -> false.

connect(Data) ->
    Data#state_data{customer_pid = quote_util:whereis(customer), warehouse_pid = quote_util:whereis(warehouse)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
