-ifndef(CUSTOMER_HRL).
-define(CUSTOMER_HRL, true).

-record(state_data, {shop_pid :: pid() | undefined, warehouse_pid :: pid() | undefined,
                     price :: non_neg_integer() | undefined}).

-endif.
