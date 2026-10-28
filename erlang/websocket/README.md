# websocket

RFC 6455's closing handshake, from `protocols/websocket/WebSocketClose.scr`: the `gen_`
modules the checker generates for it, and the two roles filled in by hand.

| | |
|---|---|
| `gen_client.erl`, `gen_server.erl` | generated, not edited: they hold each role to the protocol |
| `client.erl`, `server.erl` | the roles: what each says, and when |
| `websocket_util.erl` | finding a role by its name |
| `websocket_sup.erl`, `websocket_app.erl`, `websocket.app.src` | start one of each role |

Client pauses for `PAUSE_MS` before it sends its frame; Server closes an idle connection
after `IDLE_MS`. With 200 and 1000 ms the frame comes in time, and Client closes:

```
client: sending a frame
server: frame received
client: frame acknowledged, closing
server: Client closes, answering
client: closed
```

With `PAUSE_MS` above `IDLE_MS`, Server closes first. The frame Client sends after that is
stale: `gen_server` purges it while Server waits for Client's `close_ack`.

```
server: no frame after 1000 ms, closing
client: sending a frame
gen_server[s3]: Purging stale event {frame}
client: Server closed the connection, answering
server: closed
```

The role Server makes `gen_server.erl`, a name OTP uses: the playground renames it for a run.
