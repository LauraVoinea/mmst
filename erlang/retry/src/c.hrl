-ifndef(C_HRL).
-define(C_HRL, true).

-record(state_data, {a_pid :: pid() | undefined, b_pid :: pid() | undefined, round = 1 :: pos_integer()}).

-endif.
