-ifndef(A_HRL).
-define(A_HRL, true).

-record(state_data, {b_pid :: pid() | undefined, c_pid :: pid() | undefined, round = 1 :: pos_integer()}).

-endif.
