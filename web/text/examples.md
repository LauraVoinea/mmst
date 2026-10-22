<!-- Descriptions for the examples page and the playground's menu, read by examples.js.
     # a group: its first paragraph introduces it.
     ## an example, by file name. A paragraph is its one-line description; a list sets fields:
       title (menu name), from (source), what, mixed choice, look, try and result, and
       erlang (the id of its Erlang set, for a button on its card).
     Order matters: the exercises and the other groups appear in this order, and the entries
     under # Examples are the examples page's cards, in this order. -->

# Exercise 1

Two valid protocols: check each, then read its local types, one per role.

## 1-Timeout

The paper's Figure 1. B observes: it goes along with A or times out.

## 1-WebSocketClose

RFC 6455's closing handshake: either endpoint may close first, or both at once. The two local types are dual.

# Exercise 2

Each of the first four is broken by one change: predict what fails, and for whom, before you press Check, then fix it. Complete the last two.

## 2-a

`Timeout` without `a3()`: question 5 of Exercise 1.

## 2-b

`Timeout` without `TOc()`.

## 2-c

`b()` from q to r on both sides of the mixed choice.

## 2-d

Not a mixed choice at all: an ordinary choice.

## 2-CancellableRPC

CT fails: on the left, Server never hears back. Add the messages that tell Server, and Auditor, which side was taken.

## 2-StreamCancel

Valid, but stops after one chunk. Make it recursive so Server streams until Client cancels, then try the two predictions in its comments.

# Exercise 4

Knowledge of choice, for those who finish early: three changes to `Calculator`, each one broken. Srv observes; Alice has to end up knowing how it went. Predict what fails, and for whom, before you press Check, then fix it.

## 4-a

On the right, Alice sends `note()` to Carol.

## 4-b

On the left, Alice only sends `note()` to Carol.

## 4-c

Both branches send Alice `done()`; only one expects her `ack()`.

# Savina

Four benchmarks from [Savina](https://doi.org/10.1145/2687357.2687368), Imam and Sarkar, AGERE! 2014, rewritten as mixed choice: in each, a role that would otherwise wait forever has a way to stop waiting. All four have the shape of Exercise 2's `CancellableRPC`, once fixed, with the roles and labels renamed.

## DiningPhilosophers

- title: Dining philosophers
- from: Savina

Philosopher, the observer, gives up waiting for a fork rather than deadlock; Neighbour learns whether it is eating.

## SleepingBarber

- title: Sleeping barber
- from: Savina

Customer, the observer, leaves when the waiting room is full rather than queue forever; Shop learns whether it made a sale.

## BankTransfer

- title: Bank transfer
- from: Savina

Teller, the observer, aborts a transfer held too long by a locked account; Ledger learns whether it was posted or reversed.

## MasterWorker

- title: Master and worker
- from: Savina

Master, the observer, cancels a worker once another has answered; Pool learns whether the result was stored.

# Examples

Quote first: Figure 1's Timeout as a small service, implemented in Erlang. Then the examples from `examples/scribble` in scribble-gt-scala, each with a change to try.

## Quote

- from: Figure 1
- erlang: apps/quote
- what: Timeout as a price quote. Customer orders notebooks from Shop and gives Warehouse the postcode; Shop quotes the price, and Warehouse the delivery.
- mixed choice: Shop is the observer: it waits `PATIENCE_MS` for the order, then gives up with `expired()` and tells Warehouse with `cancel()`.
- look: Its Erlang: the `gen_` modules the checker generates, and the three roles filled in by hand. Press Run.
- try: In `customer.erl`, set `THINK_MS` above `PATIENCE_MS`, which is in `shop.erl`, and Run again.
- result: Shop gives up first: the quote expired, and nothing is set aside.

## Calculator

- from: Table 1
- what: Carol asks Srv for a sum or a difference; the answer goes to Carol, then Alice. Exercise 3 runs its Erlang.
- mixed choice: Srv is the observer: it may overrule Carol's `sum()` or `diff()` with `timeout()`. Carol tells Alice with `cancel()`.
- look: Carol's EFSM: after `sum()` she must still take `timeout()`.
- try: Delete `cancel() from Carol to Alice;`
- result: **SD** and **BA** fail: nobody tells Alice.

## Interrupt

- from: In the paper
- what: P sends `Start()`, then streams `More()`, or sends `Stop()` and waits for `Ack()`.
- mixed choice: Q is the observer: it may overrule P with `Interrupt()`. A `More()` already in flight is stale, and purged.
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
- what: A mail session: `Ehlo()`, optional `StartTls()`, `Auth()`, then `Mail()`, `Rcpt()`, `Data()` repeatedly, `Quit()`. 31 states per role.
- mixed choice: S is the observer of two mixed choices, each a timeout: before the first command, and before `Data()`.
- look: The EFSM tab, and the `…Commit` labels, marked `!!!`.
- try: Rename `QuitCommit` to `Quit`.
- result: **WF** fails: `Quit` does two jobs. The `Commit` labels keep them apart.

# More examples

Also in `examples/scribble`.

## DiffTwoBuyer

TwoBuyer, but when the title is unavailable Seller tells Alice, and Alice tells Bob.

## DistributedLogging

- from: Table 1

A controller and a logger in a loop; the controller may time the logger out and restart it.

## Fibonacci

- from: Table 1

Fibonacci numbers back and forth until `a` stops; `b` may answer `error()`. Delete the commented `ack()`: **CT** fails.

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

Accept, reject or resubmit a quote, in a loop. The agency may adjust the price; then the client cancels with both.
