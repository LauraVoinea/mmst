# quote

Figure 1's Timeout as a price quote, from `protocols/quote/Quote.scr`: the `gen_` modules the
checker generates for it, and the three roles filled in by hand.

| | |
|---|---|
| `gen_customer.erl`, `gen_shop.erl`, `gen_warehouse.erl` | generated, not edited: they hold each role to the protocol |
| `customer.erl`, `shop.erl`, `warehouse.erl` | the roles: what each says, and when |
| `quote_util.erl` | prices in pounds, and finding a role by its name |
| `quote_sup.erl`, `quote_app.erl`, `quote.app.src` | start one of each role |

Customer thinks for `THINK_MS` before ordering; Shop, the observer, waits `PATIENCE_MS` for the
order. With 300 and 1000 ms the order comes in time:

```
customer: 3 x notebook, please, to G12 8QQ
shop: 3 x notebook comes to £10.50
warehouse: 3 x notebook set aside; to G12 8QQ in 1 day, £0.00
customer: the shop says £10.50
customer: £10.50 in all, here in 1 day
```

With `THINK_MS` above `PATIENCE_MS`, Shop gives up first, and nobody reads the order or the
address Customer sends after that:

```
shop: no order after 1000 ms, quote withdrawn
warehouse: quote cancelled, nothing set aside
customer: 3 x notebook, please, to G12 8QQ
customer: too late, the quote expired
```
