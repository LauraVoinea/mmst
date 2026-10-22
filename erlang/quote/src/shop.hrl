-ifndef(SHOP_HRL).
-define(SHOP_HRL, true).

-record(state_data, {customer_pid :: pid() | undefined, warehouse_pid :: pid() | undefined,
                     item :: string() | undefined, qty :: pos_integer() | undefined}).

-endif.
