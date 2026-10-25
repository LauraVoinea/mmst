-ifndef(B_HRL).
-define(B_HRL, true).

-record(state_data, {a_pid :: pid() | undefined, c_pid :: pid() | undefined, round = 1 :: pos_integer()}).

-endif.
