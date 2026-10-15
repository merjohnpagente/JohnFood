# Load and performance

## The hard limit: this is a free Spark project

Firestore on the Spark plan gives you, per day:

| Operation | Free quota |
|---|---|
| Document reads | 50,000 |
| Document writes | 20,000 |
| Storage | 1 GiB |

A read is charged **per document returned**, not per query. Loading the menu
for 200 users means 200 x (number of menu documents) reads. This number, not
your server, is what decides how many simultaneous users the app can serve.

## What each screen costs now

| Action | Reads |
|---|---|
| First app open (categories + full menu) | ~200, once per session |
| Switching category tab | 0 |
| Typing a search | 0 |
| Opening notifications | 30, once per session |
| Tracking one order | 1, plus one OSRM route request |
| Admin dashboard | ~5 aggregation reads + 200 for top sellers |

The menu is cached in memory for the session (`MenuService` +
`StreamCache`), so the ~200 reads are paid once, not on every rebuild. Before
this change, every `StreamBuilder` that built its Firestore stream inline
resubscribed on each rebuild, and the dashboard read up to 5,000 order
documents per load.

## Why inline streams were so expensive

```dart
// Bad: a new Stream object on every build, so StreamBuilder resubscribes
// and Firestore runs the query again.
StreamBuilder(stream: db.collection('orders').snapshots(), ...)
```

`StreamBuilder` compares `widget.stream != oldWidget.stream`, and Dart
streams do not override `==`, so the comparison is always false. Every
rebuild meant a fresh subscription and a fresh bill. `StreamCache.of(key,
factory)` returns the same instance for the same key, which fixes it.

## Realistic numbers on the free plan

With the caching above, one active session costs roughly:

* first open: ~200 reads
* each order placed: ~3 writes (order, notification, promo count)
* tracking: ~1 read per 15s per customer watching

So a single user browsing for 20 minutes is about 250 reads. The 50,000 read
budget therefore supports roughly **150 to 200 daily active users** on the
free plan, as long as they are spread across the day rather than all hitting
at once.

Concurrency is not really the problem: Firestore reads are served from a
distributed backend and do not lock per collection the way a single SQLite
file would. What breaks is the daily quota and, if it is ever reached, the
service returning permission-denied for the rest of the day.

## Writes are the tighter constraint

20,000 writes per day. Each order costs:

* 1 order document
* 1 customer notification
* 1 promo usage increment, if a code was used
* plus 1 per status change: assigned, preparing, on the way, delivered

A normal delivered order is roughly 8 writes. Rider GPS updates are the
expensive part: the rider app writes position every 15 seconds while auto
tracking is on. That is 240 writes per hour per rider, or about 2,000 per
working day for one rider doing an 8 hour shift with tracking on the whole
time. That alone eats 10% of the daily write budget.

The fix already in place is that the client only writes when the rider has
actually moved more than 20 m, and throttles to one write per 15 seconds. If
you need more headroom, raise the throttle or turn auto tracking off when no
order is in progress.

## What the Blaze plan would fix

Upgrading is not about speed, it is about removing the ceiling:

* **50k reads and 20k writes become millions** with pay per operation, so the
  user count stops being the constraint.
* **Cloud Functions** become available, which is the only way to verify order
  prices server side. Today the price is computed on the device and Firestore
  rules can only check that the subtotal matches the client's own item list.
* **Firestore scheduled backups** for order history.
* **A higher rate of Cloud Firestore operations** if you ever batch writes.

## If you outgrow the free plan

The cheapest next step is not Blaze. It is:

1. **Serve the menu as a static asset.** The catalogue barely changes, so a
   JSON file in the web bundle plus a version check removes the biggest read
   cost entirely.
2. **Write GPS less often.** 30 to 60 seconds instead of 15 cuts rider writes
   by more than half, at the cost of a slightly jumpier marker.
3. **Paginate order history** rather than watching the 30 most recent orders
   for every customer on every rebuild.

Those three changes buy several times the headroom for no money.