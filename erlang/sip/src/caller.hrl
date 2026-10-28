-ifndef(CALLER_HRL).
-define(CALLER_HRL, true).

-record(state_data, {callee_pid :: pid() | undefined, cancelled = false :: boolean()}).

-endif.
