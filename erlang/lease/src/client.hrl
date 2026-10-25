-ifndef(CLIENT_HRL).
-define(CLIENT_HRL, true).

-record(state_data, {lockservice_pid :: pid() | undefined, storage_pid :: pid() | undefined}).

-endif.
