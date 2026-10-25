<!-- Descriptions for the examples page and the playground's menu, read by examples.js.
     # a group: the text up to its first entry introduces it, a ```local block being a local
       type as the checker prints it; a list item title sets its menu name.
     ## an example, by file name. A paragraph is its one-line description; a list sets fields:
       title (menu name), from (source), what, mixed choice, look, try and result, and
       erlang (the id of its Erlang set, for a button on its card).
     Order matters: the exercises and the other groups appear in this order, and the entries
     under # Examples are the examples page's cards, in this order. The playground's menu
     lists the exercises, then those cards. -->

# Exercise 1

- title: Exercise 1: knowledge of choice

Knowledge of choice: who learns which side B took, and from which message. Open [1-Timeout](./#ex=1-Timeout) and press Check: the four checks pass, and you get three local types, one per role. Read them, then answer these.

1. **A's type.**

   ```local
   [B⊕a1() . C⊕a2() . B&a4() . C&a5() . end ▷1_B B&TOa() . end]
   ```

   A sends `a1` and `a2` before it knows whether B went along. Where in its type does A first know which side was taken, and who tells it?
2. **B's type.**

   ```local
   [A&a1() . C⊕a3() . A⊕a4() . end ▷1_B A⊕TOa() . C⊕TOc() . end]
   ```

   `▷` separates the two sides of the mixed choice. B is the observer: the role that may overrule the other. Which of B's actions picks each side? Classical choice is directed: at each point a role either only sends or only receives. Why can a classical session type not describe B's first step?
3. **C's type.**

   ```local
   [A&a2() . B&a3() . A⊕a5() . end ▷1_B B&TOc() . end]
   ```

   C decides nothing. On the left, its first message is `a2`, from A. Does `a2` tell C which side was taken? If not, what does?
4. **[1-a](./#ex=1-a).** On the left, B now makes an ordinary choice between `a4()` and `b4()`, and C gets `a3()` either way. What fails, and why? Then press Check, compare, and fix it.
5. **[1-b](./#ex=1-b).** The same, with B choosing between `a3()` and `b3()`, and A getting `a4()` either way. What fails, and why? Check, compare, fix.
6. **Without `a3()`.** Suppose we delete `a3() from B to C` from Timeout. What fails, and why? It is [2-a](./#ex=2-a), in Exercise 2.

## 1-Timeout

The paper's Figure 1. B observes: it goes along with A or times out.

## 1-a

On the left, B chooses between `a4()` and `b4()`; C gets `a3()` either way.

## 1-b

On the left, B chooses between `a3()` and `b3()`; A gets `a4()` either way.

# Exercise 2

- title: Exercise 2: safety properties

Safety: the four checks. Each of the first four is Timeout broken by one change: work out which safety properties fail, and why, before you press Check, then fix it. Complete the last two.

## 2-a

`Timeout` without `a3()`.

## 2-b

`Timeout` without `TOc()`.

## 2-c

On the right, B sends C `a2()` instead of `TOc()`.

## 2-d

After `a3()`, B chooses between `a4()` and `b4()`; C answers A only after `a4()`.

## 2-CancellableRPC

CT fails. Add the messages that tell whoever is left out, and get all four checks to pass.

## 2-StreamCancel

Valid, but stops after one chunk. Make it recursive so Server streams until Client cancels, then try the two changes in its comments.

# Exercise 3

- title: Exercise 3: code generation

Code generation: from the correct Timeout to its state machines, then to running Erlang. Each step opens in the playground.

1. **The EFSM.** Open [B's EFSM](./#ex=3-Timeout&view=efsm&role=B). Click a transition: its action lights up in B's local type, above the diagram.
   - State 5, marked `▷1`, is where the mixed choice starts. `*` marks the switch to the right, and `internal` is B's own decision.
   - Which of B's transitions commit it to a side?
   - Now pick C. Which of its transitions commit it? Does `A?a2()`?
2. **The generated Erlang.** The same click shows the transition's code below the diagram, and each line number opens its file. Each role `r` has three files:

   | file | whose | what it is |
   |---|---|---|
   | `gen_r.erl` | the tool's | a `gen_statem` behaviour: the EFSM as code, never edited |
   | `r.erl` | yours | a template with one function per state, for the application logic |
   | `r.hrl` | the tool's | the state record |

   In `gen_b.erl`, state 5 is `s5/3`, after the comment `%% Mixed-choice entry state`. Click its transitions and look for four things:
   - a receive and a send in the same state function: mixed choice in code, which a classical session type cannot have;
   - `message_status(Path, …)`: every message carries the path of sides its sender was on. If the receiver has already committed to another side, the message is stale, and dropped: §4.1 of the paper, and `stale/1` at the bottom of the file;
   - `commit_if_taken/3`, where B commits to a side;
   - `postpone`: a message the state cannot take yet is put back, for a later state.
3. **Run it.** Open [the generated Erlang](./#ex=3-Timeout&view=erlang), then Edit and run, and Run: the three roles run to the end. As generated, B's callback overrules at once, so you see the right side.
4. **Stale message purging.** Open [Retry's Erlang](./#mode=erlang&erl=apps/retry) and Run. Retry is Timeout started again after each overrule, and B overrules twice. The `a1` and `a2` that A sends in those rounds are on the left, and arrive after B and C took the right: they are stale, and the output shows `Purging stale event` for each. Turn on trace to see the sides they carry, one per round. `PAUSES_MS`, in `a.erl`, sets how long A takes in each round: try others and Run again.

   <div class="sides-nocommit" data-start="rhs" data-include="parts/two-runs.html"></div>

   Running Timeout, you won't see `Purging stale event`: by the time `a1` or `a2` arrives, the role it was sent to has finished.
5. **Lease, Timeout filled in.** [Lease](./#mode=erlang&erl=apps/lease) is Timeout as a lease. Client renews its lease with LockService and, at the same time, sends a write to Storage. LockService observes: it renews the lease if the renewal comes in time, or lets it expire, tells Client, and fences Storage. Storage holds the write until it hears which.

   | Figure 1 | the lease |
   |---|---|
   | A, B, C | Client, LockService, Storage |
   | `a1` to `a5` | `renew`, `write`, `valid`, `renewed`, `written` |
   | `TOa`, `TOc` | `expired`, `fence` |

   Run it. Then in `client.erl` set `PAUSE_MS` above `LEASE_MS`, which is in `lockservice.erl`, say to 1500, and Run again. The lease expires before the renewal comes, so LockService fences Storage, and nobody applies the write Client sends after that: Storage never applies a write made under an expired lease. Compare `storage.erl` with C's template, `c.erl`: the same states, `s4` to `s6`, filled in.

## 3-Timeout

Figure 1 of the paper, for Exercise 3: its EFSMs, then its Erlang.

# More exercises

WebSocketClose is valid: read its two local types. Each of the others is broken by one change: work out what fails, and why, before you press Check, then fix it.

## WebSocketClose

- title: WebSocket close

RFC 6455's closing handshake: either endpoint may close first, or both at once. The two local types are dual.

## Overrule

`b()` from q to r on both sides of the mixed choice.

## Choice

Not a mixed choice at all: an ordinary choice.

## CalculatorNoteRight

- title: Calculator, note on the right

`Calculator`, sum only, with `note()` from Alice to Carol in place of `cancel()`.

## CalculatorNoteLeft

- title: Calculator, note on the left

`Calculator`, sum only, with `note()` from Alice to Carol in place of `sum_result()`.

## CalculatorDone

- title: Calculator, done twice

`Calculator` with `done()` to Alice in both branches, and `ack()` from Alice after `sum()` only.

# Examples

Lease and Retry first: Figure 1's Timeout, filled in, in Erlang. Then the examples from `examples/scribble` in scribble-gt-scala, each with a change to try.

## Lease

- from: Figure 1
- erlang: apps/lease
- what: Timeout as a lease. Client renews its lease with LockService and sends a write to Storage at the same time; Storage holds the write until LockService says the lease is valid.
- mixed choice: LockService is the observer: with no renewal within `LEASE_MS`, it lets the lease expire, tells Client with `expired()`, and fences Storage with `fence()`.
- look: Its Erlang: the `gen_` modules the checker generates, and the three roles filled in by hand. Press Run.
- try: In `client.erl`, set `PAUSE_MS` above `LEASE_MS`, which is in `lockservice.erl`, and Run again.
- result: The lease expires first: Storage is fenced, and the write is never applied.

## Retry

- from: Figure 1
- erlang: apps/retry
- what: Timeout, started again after each overrule. B waits for `a1` a little longer each round; A is slow in the first two.
- mixed choice: B is the observer, in every round: it goes along if `a1` comes in time, or overrules with `TOa()` and `TOc()`, and the three start again.
- look: Its Erlang: press Run. The `a1` and `a2` that A sends in the rounds B overrules are stale: `gen_b` and `gen_c` drop them.
- try: In `a.erl`, set `PAUSES_MS` to `[0]` and Run again.
- result: B goes along in the first round, and nothing is dropped.

## Calculator

- from: Table 1
- what: Carol asks Srv for a sum or a difference; the answer goes to Carol, then Alice.
- mixed choice: Srv is the observer: it may overrule Carol's `sum()` or `diff()` with `timeout()`. Carol tells Alice with `cancel()`.
- look: Carol's EFSM: after `sum()` she must still take `timeout()`.
- try: Delete `cancel() from Carol to Alice;`
- result: **SD** and **BA** fail: nobody tells Alice.

## Interrupt

- from: In the paper
- what: P sends `Start()`, then streams `More()`, or sends `Stop()` and waits for `Ack()`.
- mixed choice: Q is the observer: it may overrule P with `Interrupt()`. A `More()` already in flight is stale.
- look: Q's EFSM, then P's: `Interrupt()` can reach P in every left-hand state.
- try: Delete `Ack() from Q to P;`
- result: **CT** fails: after `Stop()`, P never hears from Q.

## FailureHandling

- from: In the paper
- what: Master M, worker W, failure detector FD. Each round: `HB()` to FD, `OK()` to M, `result()`, `more()`.
- mixed choice: FD is the observer: missing a heartbeat, it overrules W with `Timeout()` and tells M with `Crash()`. `@failed` marks the right side as W's failure.
- look: W's EFSM: `Timeout()` can arrive anywhere in its round.
- try: Delete `Crash() from FD to M;`
- result: **SD** and **BA** fail: M waits for a `result()` that never comes.

## TwoBuyer

- from: Table 1
- what: Alice asks Seller for a title, both buyers get a quote, Alice tells Bob her share, Bob accepts or rejects.
- mixed choice: Two nested mixed choices, both with Seller as observer: it may overrule with `not_available()` in the outer one and `response_timeout()` in the inner one. Both buyers are told.
- look: Seller's EFSM: an entry state per mixed choice.
- try: Delete `not_available() from Seller to Bob;`
- result: **SD** and **BA** fail: Bob waits for a quote.

## CircuitBreaker

- from: Table 1
- what: Usr calls an API, which asks a Controller: `service_operational()`, `error_notice()` or `shutdown_api()`. Storage follows.
- mixed choice: The API is the observer: it may overrule the Controller with `timeout()`; the Controller tells Storage, the API tells Usr, and the loop repeats.
- look: The comments: three acks for clear termination, `cancel_ack()` for projection onto Storage.
- try: Delete `shutdown_ack() from API to Controller;`
- result: **CT** fails: the Controller finishes without hearing from the API.

## amqp_selective_consumer

- title: AMQP selective consumer
- from: RabbitMQ case study
- what: From RabbitMQ's Erlang client: Consumer subscribes via Channel; Server delivers until someone cancels. The completed generated Erlang passes RabbitMQ's tests.
- mixed choice: Any of the three may cancel: Server by an ordinary choice, Channel as observer of the outer mixed choice (while Server decides), Consumer as observer of the inner one (while a delivery is in flight).
- look: Channel's EFSM: both mixed choices inside the loop.
- try: Delete `process_message() from Channel to Consumer;`
- result: Checks pass; projection onto Consumer fails: nothing tells it the Server's choice.

## SMTP

- from: Table 1
- what: A mail session: `Ehlo()`, optional `StartTls()`, `Auth()`, then `Mail()`, `Rcpt()`, `Data()` repeatedly, `Quit()`. 23 states per role.
- mixed choice: S is the observer of two mixed choices, each a timeout: before the first command, and before `Data()`.
- look: The EFSM tab, and the `…Commit` labels, marked `!!!`.
- try: Rename `QuitCommit` to `Quit`.
- result: **WF** fails: `Quit` does two jobs. The `Commit` labels keep them apart.

# More examples

Also in `examples/scribble`.

## DistributedLogging

- from: Table 1

A controller and a logger in a loop; the controller may time the logger out and restart it.

## Fibonacci

- from: Table 1

Fibonacci numbers back and forth until `a` stops; `b` may answer `error()`. Delete `ack() from b to a;`: **CT** fails.

## OnlineWallet

- from: Table 1

Log in, then pay or quit, in a loop. The server may time the client out, and tells the authenticator.

## SimpleVoting

Authenticate, then vote `Yes()` or `No()`; the server may answer `error()`. The mixed choice is in one branch of an ordinary choice.

## Timeout

- from: Figure 1

Figure 1 as in the artifact; `1-Timeout` is the same, with comments.

## TravelAgency

- from: Table 1

Accept, reject or resubmit a quote, in a loop. The agency may adjust the price; then the client cancels with the agency and the supplier.
