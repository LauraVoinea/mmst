-ifndef(WAREHOUSE_HRL).
-define(WAREHOUSE_HRL, true).

-record(state_data, {customer_pid :: pid() | undefined, shop_pid :: pid() | undefined,
                     postcode :: string() | undefined, days :: pos_integer() | undefined,
                     charge :: non_neg_integer() | undefined}).

-endif.
