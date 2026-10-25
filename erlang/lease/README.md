# lease

Figure 1's Timeout as a lease, from `protocols/lease/Lease.scr`: the `gen_` modules the
checker generates for it, and the three roles filled in by hand.

| | |
|---|---|
| `gen_client.erl`, `gen_lockservice.erl`, `gen_storage.erl` | generated, not edited: they hold each role to the protocol |
| `client.erl`, `lockservice.erl`, `storage.erl` | the roles: what each says, and when |
| `lease_util.erl` | finding a role by its name |
| `lease_sup.erl`, `lease_app.erl`, `lease.app.src` | start one of each role |

| Figure 1 | here |
|---|---|
| A, B, C | Client, LockService, Storage |
| `a1`, `a2`, `a3`, `a4`, `a5` | `renew`, `write`, `valid`, `renewed`, `written` |
| `TOa`, `TOc` | `expired`, `fence` |

Client pauses for `PAUSE_MS` before it renews; the lease lasts `LEASE_MS`. With 300 and
1000 ms the renewal comes in time, and Storage applies the write:

```
client: renewing the lease and writing 42
storage: write 42 pending
lockservice: lease renewed
storage: write 42 applied
client: lease renewed
client: write 42 done
```

With `PAUSE_MS` above `LEASE_MS`, the lease expires first. LockService fences Storage, and
nobody applies the write Client sends after that:

```
lockservice: no renewal after 1000 ms, lease expired
storage: fenced, nothing pending
client: renewing the lease and writing 42
client: too late, the lease expired
```
