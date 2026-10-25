# retry

Figure 1's Timeout, started again after each overrule, from `protocols/retry/Retry.scr`:
the `gen_` modules the checker generates for it, and the three roles filled in by hand.

| | |
|---|---|
| `gen_a.erl`, `gen_b.erl`, `gen_c.erl` | generated, not edited: they hold each role to the protocol |
| `a.erl`, `b.erl`, `c.erl` | the roles: what each says, and when |
| `retry_util.erl` | finding a role by its name |
| `retry_sup.erl`, `retry_app.erl`, `retry.app.src` | start one of each role |

B waits for `a1` for `WAIT_MS`, 100 ms, in the first round, and twice as long in each
next one. A takes `PAUSES_MS` before it sends `a1` and `a2`: 200 ms in the first round,
300 in the second, none in the third. So B overrules twice and goes along in the third
round. The `a1` and `a2` that A sends in the first two rounds arrive after B overruled:
they are stale, and `gen_b` and `gen_c` drop them.

```
B: round 1, no a1 after 100 ms: TOa to A, TOc to C
C: round 1, TOc: again
A: round 1, a1 to B and a2 to C, after 200 ms
gen_c[s6]: Purging stale event {a2}
A: round 1, TOa: again
B: round 2, no a1 after 200 ms: TOa to A, TOc to C
C: round 2, TOc: again
A: round 2, a1 to B and a2 to C, after 300 ms
gen_c[s6]: Purging stale event {a2}
A: round 2, TOa: again
A: round 3, a1 to B and a2 to C, after 0 ms
gen_b[s7]: Purging stale event {a1}
gen_b[s7]: Purging stale event {a1}
B: round 3, a1 in time: going along
C: round 3, a2 and a3: a5 to A
A: round 3, a4 and a5: done
```

B only reads its mailbox once it goes along, so it drops the two stale `a1` then.
