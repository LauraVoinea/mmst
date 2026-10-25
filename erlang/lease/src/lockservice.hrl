-ifndef(LOCKSERVICE_HRL).
-define(LOCKSERVICE_HRL, true).

-record(state_data, {client_pid :: pid() | undefined, storage_pid :: pid() | undefined}).

-endif.
