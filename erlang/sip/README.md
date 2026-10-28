# sip

A SIP call, RFC 3261, that Caller may cancel while it rings, from
`protocols/sip/SipCancel.scr`: the `gen_` modules the checker generates for it, and the two
roles filled in by hand.

| | |
|---|---|
| `gen_caller.erl`, `gen_callee.erl` | generated, not edited: they hold each role to the protocol |
| `caller.erl`, `callee.erl` | the roles: what each says, and when |
| `sip_util.erl` | finding a role by its name, the network's delay, waiting for a message |
| `sip_sup.erl`, `sip_app.erl`, `sip.app.src` | start one of each role |

| SipCancel | SIP |
|---|---|
| `invite()`, `ringing()` | INVITE, 180 Ringing |
| `cancel()`, `cancel_ok()` | CANCEL, and its 200 OK |
| `terminated()` | 487 Request Terminated, for the INVITE |
| `invite_ok()` | 200 OK for the INVITE |
| `ack()` | ACK |
| `bye()`, `bye_ok()` | BYE, and its 200 OK |

Caller lets it ring for `RING_MS`, then cancels. Callee answers after `ANSWER_MS`. Each
message takes `NETWORK_MS` on the way, in `sip_util.erl`. With 1000, 500 and 100 ms, Callee
answers in time:

```
caller: calling
callee: ringing
callee: answering
caller: answered, talking
caller: hanging up
callee: Caller hung up
caller: call ended
```

With `ANSWER_MS` at 1500, the CANCEL comes first:

```
caller: calling
callee: ringing
caller: no answer after 1000 ms, cancelling
callee: cancelled before answering
caller: call cancelled
```

With `ANSWER_MS` less than `NETWORK_MS` away from `RING_MS`, say 1000, Callee answers while
the CANCEL is on its way, and the two cross. Caller gets the answer after it has cancelled:
it ACKs it and hangs up at once, as in RFC 5407, section 3.1.2. The CANCEL is stale:
`gen_callee` purges it. In SIP, Callee would still answer that CANCEL, and the answer would
change nothing; here it has no place in the protocol.

```
caller: calling
callee: ringing
callee: answering
caller: no answer after 1000 ms, cancelling
gen_callee[s5]: Purging stale event {cancel}
caller: answered after the CANCEL, hanging up
callee: Caller hung up
caller: call ended
```

Lines printed at the same moment can come in another order.
