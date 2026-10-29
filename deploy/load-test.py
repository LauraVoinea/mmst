#!/usr/bin/env python3
"""A room of pairs pressing Check, against a playground of yours, to see how it copes.

    python3 deploy/load-test.py https://play.example.org [pairs] [minutes] [--burst]

Each pair checks its own edit of Timeout every 15 to 45 s, so nothing comes from the cache;
--burst has every pair press Check at the same moment first. Meanwhile the page itself is
fetched every second. It reports how long Checks and the page took, and any busy answers.
Defaults: 30 pairs, 2 minutes. It loads the server like a room would: run it the day before,
not during a session.
"""
import json, random, statistics, sys, threading, time, urllib.request

PROTOCOL = """module Timeout;

global protocol Timeout(role A, role B, role C) {
    mixed {
        a1() from A to B;
        a2() from A to C;
        a4() from B to A;
        a5() from C to A;
    } or A -> B {
        TOa() from B to A;
        TOc() from B to C;
    }
}
"""

args = [a for a in sys.argv[1:] if not a.startswith("--")]
if not args:
    sys.exit(__doc__)
base = args[0].rstrip("/")
pairs = int(args[1]) if len(args) > 1 else 30
minutes = float(args[2]) if len(args) > 2 else 2
burst = "--burst" in sys.argv

checks, pages, lock, done = [], [], threading.Lock(), threading.Event()

def check(pair):
    source = PROTOCOL + "// pair %d, %f\n" % (pair, random.random())
    request = urllib.request.Request(base + "/api/validate", data=json.dumps({"source": source}).encode(),
                                     headers={"Content-Type": "application/json"})
    start = time.time()
    try:
        reply = json.load(urllib.request.urlopen(request, timeout=180))
        what = "busy" if reply.get("code") == "busy" else "checked" if "flags" in reply else reply.get("code") or "error"
    except Exception as e:
        what = "failed: " + type(e).__name__
    with lock:
        checks.append((time.time() - start, what))

def pair(n, end):
    if burst:
        check(n)
    time.sleep(random.uniform(0, 30))
    while time.time() < end:
        check(n)
        time.sleep(random.uniform(15, 45))

def page():
    while not done.is_set():
        start = time.time()
        try:
            urllib.request.urlopen(base + "/", timeout=60).read()
            pages.append(time.time() - start)
        except Exception:
            pages.append(float("inf"))
        time.sleep(1)

end = time.time() + 60 * minutes
watcher = threading.Thread(target=page)
watcher.start()
threads = [threading.Thread(target=pair, args=(n, end)) for n in range(pairs)]
print("%d pairs for %g minutes%s, against %s" % (pairs, minutes, ", starting with a burst" if burst else "", base))
for t in threads:
    t.start()
for t in threads:
    t.join()
done.set()
watcher.join()

took = sorted(s for s, what in checks if what == "checked")
others = [what for s, what in checks if what != "checked"]
def at(q):
    return took[min(len(took) - 1, int(q * len(took)))]
print("Checks: %d answered, %d not%s" % (len(took), len(others),
      (": " + ", ".join(sorted(set(others)))) if others else ""))
if took:
    print("  half within %.1f s, nine in ten within %.1f s, the slowest %.1f s" % (at(0.5), at(0.9), took[-1]))
print("The page: half within %.2f s, the slowest %.2f s" % (statistics.median(pages), max(pages)))
