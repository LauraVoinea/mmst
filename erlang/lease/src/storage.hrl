-ifndef(STORAGE_HRL).
-define(STORAGE_HRL, true).

-record(state_data, {client_pid :: pid() | undefined, lockservice_pid :: pid() | undefined,
                     pending :: integer() | undefined}).

-endif.
