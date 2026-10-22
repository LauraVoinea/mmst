%%%-------------------------------------------------------------------
%%% warehouse.erl: Quote's Warehouse, written by hand; gen_warehouse is generated.
%%%
%%% Takes the postcode from Customer and the order from Shop, sets the stock aside and
%%% quotes the delivery; or hears from Shop that the quote is off.
%%%-------------------------------------------------------------------
-module(warehouse).
-behaviour(gen_warehouse).

-export([start_link/0, callback_mode/0]).
-export([init/1, code_change/4, terminate/3, s4/3, s5/3, s6/3]).

-include("warehouse.hrl").

%% On the shelf.
-define(STOCK, #{"notebook" => 40, "pen" => 200, "mug" => 6}).

start_link() ->
    gen_warehouse:start_link(?MODULE, []).

callback_mode() ->
    state_functions.

init([]) ->
    io:setopts([{encoding, unicode}]),                   % for the £ in prices
    {ok, s4, #state_data{}}.

%% The mixed choice: the address from Customer (left), or cancel from Shop (right).
s4(cast, {_Customer, {address, {Postcode}}}, Data) ->
    {next_state, s5, Data#state_data{postcode = Postcode}};
s4(cast, {_Shop, {cancel}}, Data) ->
    cancelled(Data).

s5(cast, {_Shop, {reserve, {Item, Qty}}}, #state_data{postcode = Postcode} = Data) ->
    InStock = Qty =< maps:get(Item, ?STOCK, 0),
    {Days, Charge} = delivery(Postcode, InStock),
    io:format("warehouse: ~b x ~s ~s; to ~s in ~b day~s, ~ts~n",
              [Qty, Item, case InStock of true -> "set aside"; false -> "ordered in" end,
               Postcode, Days, plural(Days), quote_util:format(Charge)]),
    {next_state, s6, Data#state_data{days = Days, charge = Charge}, [{next_event, internal, {delivery}}]};
s5(cast, {_Shop, {cancel}}, Data) ->
    cancelled(Data).

s6(internal, {delivery}, #state_data{days = Days, charge = Charge} = Data0) ->
    Data = connect(Data0),
    gen_warehouse:send_s6_delivery(Data#state_data.customer_pid, Days, Charge, Data),
    {stop, normal, Data}.

cancelled(Data) ->
    io:format("warehouse: quote cancelled, nothing set aside~n", []),
    {stop, normal, Data}.

%% Days and pence by postcode area; five more days when the stock has to come in.
delivery(Postcode, InStock) ->
    Area = lists:takewhile(fun(C) -> C >= $A andalso C =< $Z end, string:uppercase(Postcode)),
    {Days, Charge} = case Area of
        "G" -> {1, 0};
        "EH" -> {1, 250};
        A when A =:= "PA"; A =:= "KA"; A =:= "ML"; A =:= "FK"; A =:= "KY"; A =:= "DD"; A =:= "AB" -> {2, 350};
        _ -> {3, 499}
    end,
    {case InStock of true -> Days; false -> Days + 5 end, Charge}.

plural(1) -> "";
plural(_) -> "s".

connect(Data) ->
    Data#state_data{customer_pid = quote_util:whereis(customer), shop_pid = quote_util:whereis(shop)}.

code_change(_OldVsn, _State, Data, _Extra) ->
    {ok, Data}.

terminate(_Reason, _State, _Data) ->
    ok.
