#!/usr/bin/env python3
"""
QRZ name resolver — produce a CALL,NAME CSV for trmaster_build.py --names-csv.

Self-contained (no dependency on any other project), but credential- and
cache-compatible with the ContestLoggerStats QRZ tooling:

  credentials : ~/qrz_settings.cfg   ([qrz] username=... password=...)
  name cache  : ~/.publicLogProcessor/qrz_name_cache.json   (separate from
                that project's qrz_cache.json, which stores grid not names)

For each candidate call it looks up QRZ and emits the on-air name, preferring
the **nickname** field (e.g. "Tom") over the formal first name `fname`
("Thomas") — nickname is what gets sent in CW exchanges.  Misses are cached so
they are not retried.

QRZ is optional.  If the credentials file / [qrz] section is missing (e.g. a
future maintainer without a QRZ subscription), this prints a notice and exits 0
without producing names — the merge step then simply leaves those calls bare.

Typical use (resolve the still-nameless calls in a built .dta, in bounded
batches so the cache accumulates across runs):

  python trmaster_names_qrz.py --dta _work/TRMASTER_new.DTA \
      --out _work/qrz_names.csv --limit 2000
  python trmaster_build.py ... --names-csv _work/qrz_names.csv
"""

import argparse
import configparser
import csv
import json
import os
import socket
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

import trmaster_codec as tc


def ascii_fold(s):
    """Transliterate to ASCII (José -> JOSE, Björn -> BJORN). The .dta is
    single-byte and CW is ASCII, so contest names are folded to plain ASCII."""
    if not s:
        return ""
    nfkd = unicodedata.normalize("NFKD", s)
    return "".join(c for c in nfkd if not unicodedata.combining(c)) \
        .encode("ascii", "ignore").decode("ascii")


# Words that mark a QRZ `name` field as a club/org rather than a person, used
# by the name-field fallback so we recover individuals (e.g. 9M2OCX -> SHAHRUL)
# without picking up "NC CONTESTERS" or "ARRL HQ OPERATORS CLUB".
CLUB_WORDS = {
    "CLUB", "CONTEST", "CONTESTERS", "RADIO", "ASSOCIATION", "ASSN", "ASSOC",
    "SOCIETY", "GROUP", "TEAM", "ARC", "FRATERNITY", "OPERATORS", "DX",
    "UNIVERSITY", "COLLEGE", "SCHOOL", "MILITARY", "GUARD", "AMATEUR",
    "STATION", "FOUNDATION", "ROAMERS", "ALUMNI", "KLUB", "REPEATER",
    "EMERGENCY", "ARES", "RACES", "SCOUT", "MEMORIAL", "EXPEDITION",
}

DEFAULT_CFG = os.path.expanduser("~/qrz_settings.cfg")
DEFAULT_CACHE = os.path.expanduser("~/.publicLogProcessor/qrz_name_cache.json")
QRZ_API_URL = "https://xmldata.qrz.com/xml/current/"


def log(m):
    print(m, flush=True)


def read_credentials(cfg_path):
    """Return (user, pass) or None if unavailable -> caller skips QRZ gracefully."""
    if not os.path.isfile(os.path.expanduser(cfg_path)):
        return None
    cfg = configparser.ConfigParser()
    cfg.read(os.path.expanduser(cfg_path))
    if not cfg.has_section("qrz"):
        return None
    u = cfg.get("qrz", "username", fallback="").strip()
    p = cfg.get("qrz", "password", fallback="").strip()
    return (u, p) if u and p else None


class QRZNameClient:
    """Minimal QRZ XML client that keeps nickname/fname; JSON name cache."""

    def __init__(self, username, password, cache_path,
                 hit_max_age_days=180, miss_max_age_days=30):
        self._user = username
        self._pass = password
        self._cache_path = cache_path
        self._key = None
        self._cache = {}
        self._dirty = False
        self._now = int(time.time())
        # Names are stable -> long TTL; "no name" results re-checked sooner in
        # case a call gets licensed or its QRZ profile gains a name. 0 = never.
        self._hit_max_secs = int(hit_max_age_days) * 86400
        self._miss_max_secs = int(miss_max_age_days) * 86400
        if os.path.isfile(cache_path):
            try:
                with open(cache_path, encoding="utf-8") as f:   # must match save()
                    self._cache = json.load(f)
            except (OSError, ValueError) as e:
                print(f"  WARNING: cache load failed ({cache_path}): {e}; "
                      f"starting empty", file=sys.stderr)
                self._cache = {}

    def save(self):
        """Atomic write (tmp + os.replace) so a kill never corrupts the cache."""
        if not self._dirty:
            return
        os.makedirs(os.path.dirname(self._cache_path) or ".", exist_ok=True)
        tmp = self._cache_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(self._cache, f, indent=1, ensure_ascii=False)
        os.replace(tmp, self._cache_path)   # atomic on same filesystem
        self._dirty = False

    @staticmethod
    def _entry_is_org(entry):
        """A 'no name' entry that QRZ shows is a club/org: its `name` field
        (stored as `qname`) contains a club word and there is no personal
        nickname/fname. A club call never becomes a person, so its miss is
        permanent and must NOT be re-queried on the short miss TTL.

        Derived from the already-stored `qname`, so it applies retroactively to
        entries cached before this logic existed — no re-lookup, no migration.
        Conservative on purpose: only a definite club-word match qualifies, so a
        real person is never mistaken for a club (a club we miss just keeps the
        30-day recheck — a wasted lookup, not a wrong name).
        """
        q = (entry.get("qname") or "").strip().upper()
        if not q:
            return False
        if entry.get("nickname") or entry.get("fname"):
            return False
        return bool(set(q.split()) & CLUB_WORDS)

    def _fresh(self, entry):
        # Named entries use the long (hit) TTL. "No name" entries use the short
        # (miss) TTL so a call that later gains a name gets rechecked — EXCEPT
        # confirmed clubs/orgs, which never become a person and so never expire.
        if entry.get("name"):
            ttl = self._hit_max_secs
        elif self._entry_is_org(entry):
            ttl = 0                       # confirmed club -> never re-query
        else:
            ttl = self._miss_max_secs
        if ttl <= 0:
            return True   # 0 = never expire
        return (self._now - int(entry.get("ts", 0))) <= ttl

    def needs_lookup(self, call):
        """True if this call is not cached, or its cache entry is stale."""
        e = self._cache.get(call.upper().strip())
        return e is None or not self._fresh(e)

    @staticmethod
    def _ns(root):
        return root.tag.split("}")[0] + "}" if "}" in root.tag else ""

    def _session(self):
        url = QRZ_API_URL + "?" + urllib.parse.urlencode(
            {"username": self._user, "password": self._pass})
        with urllib.request.urlopen(url, timeout=15) as r:
            root = ET.fromstring(r.read())
        ns = self._ns(root)
        s = root.find(f"{ns}Session")
        err = s.findtext(f"{ns}Error") if s is not None else "no Session"
        if err:
            raise RuntimeError(f"QRZ session error: {err}")
        self._key = s.findtext(f"{ns}Key")
        if not self._key:
            raise RuntimeError("QRZ: no session key")

    def _api(self, call, retry=True):
        """Return dict of QRZ <Callsign> fields, or None if not found."""
        if self._key is None:
            self._session()
        url = QRZ_API_URL + "?" + urllib.parse.urlencode(
            {"s": self._key, "callsign": call})
        # Network / HTTP layer: a failure here is a real outage -- let it
        # propagate so the caller's loop stops the pass (don't hammer a failing
        # API). Caught per-type so each could be handled differently later
        # (e.g. back off on timeout / 5xx) instead of being treated as a miss.
        try:
            with urllib.request.urlopen(url, timeout=15) as r:
                raw = r.read()
        except urllib.error.HTTPError:      # server returned 4xx/5xx
            raise
        except urllib.error.URLError:       # DNS / refused / unreachable (reason may wrap socket.timeout)
            raise
        except socket.timeout:              # connect / read timed out
            raise

        # Parse layer: a malformed / non-XML body is a per-call problem (HTML
        # error page or bad encoding -- seen on some DX calls like BD3PZF), not
        # an outage. Treat it as a cacheable miss so the call is skipped and the
        # pass continues rather than aborting on one bad response.
        try:
            root = ET.fromstring(raw)
        except ET.ParseError:
            return None
        ns = self._ns(root)
        s = root.find(f"{ns}Session")
        if s is not None:
            err = s.findtext(f"{ns}Error")
            if err:
                if retry and ("Timeout" in err or "session" in err.lower()):
                    self._key = None
                    return self._api(call, retry=False)
                if "not found" in err.lower():
                    return None
                raise RuntimeError(f"QRZ lookup error: {err}")
        cs = root.find(f"{ns}Callsign")
        if cs is None:
            return None
        out = {}
        for child in cs:
            tag = child.tag.split("}")[-1]
            if child.text:
                out[tag] = child.text
        return out

    @staticmethod
    def _name_from(fields):
        """On-air name: nickname > fname > the `name` field if it looks like a
        person (not a club). All uppercased."""
        nick = (fields.get("nickname") or "").strip()
        if nick:
            return nick.split()[0].upper()
        fn = (fields.get("fname") or "").strip()
        if fn:
            return fn.split()[0].upper()
        # Fallback: some ops (esp. DX) put their name in QRZ's `name` field with
        # no fname. Use it only when it looks like an individual, not a club/org.
        nm = (fields.get("name") or "").strip()
        if nm:
            toks = nm.upper().split()
            if len(toks) <= 2 and not (set(toks) & CLUB_WORDS):
                return toks[0]
        return ""

    def name(self, call):
        """Return on-air name for call ('' if none), using/refreshing the cache.

        A cached entry is reused unless it is stale (older than max-age-days).
        Both hits and misses are stamped with 'ts' so the TTL applies uniformly.
        """
        key = call.upper().strip()
        e = self._cache.get(key)
        if e is not None and self._fresh(e):
            return e.get("name", "")
        fields = self._api(key)
        if fields is None:
            entry = {"name": "", "ts": self._now}          # cached miss
        else:
            entry = {
                "name": self._name_from(fields),
                "nickname": fields.get("nickname", ""),
                "fname": fields.get("fname", ""),
                "qname": fields.get("name", ""),   # QRZ entity/last/org field
                "country": fields.get("country", ""),
                "ts": self._now,
            }
        self._cache[key] = entry
        self._dirty = True
        return entry.get("name", "")


def candidate_calls(args):
    """Calls to resolve: explicit file, or the still-nameless calls in a .dta."""
    if args.calls_file:
        with open(args.calls_file) as f:
            return [ln.strip().upper() for ln in f if ln.strip()]
    data = tc.read_dta(args.dta)
    calls = data["calls"]
    if args.all:
        cand = list(calls.keys())
    else:
        cand = [c for c, v in calls.items() if not v.get("Name")]
    return sorted(cand)


def main(argv=None):
    ap = argparse.ArgumentParser(description="QRZ name resolver -> CALL,NAME CSV")
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--dta", help="built .dta; resolve its still-nameless calls")
    src.add_argument("--calls-file", help="explicit list, one call per line")
    ap.add_argument("--out", required=True, help="output CALL,NAME CSV")
    ap.add_argument("--qrz-cfg", default=DEFAULT_CFG, help="QRZ creds (default ~/qrz_settings.cfg)")
    ap.add_argument("--cache", default=DEFAULT_CACHE, help="name cache JSON")
    ap.add_argument("--all", action="store_true",
                    help="with --dta, resolve every call (not just nameless)")
    ap.add_argument("--limit", type=int, default=0,
                    help="max NEW (uncached/stale) lookups this run (0 = no cap)")
    ap.add_argument("--sleep", type=float, default=0.0,
                    help="seconds between live API calls (politeness)")
    ap.add_argument("--max-age-days", type=int, default=180,
                    help="re-look-up NAMED entries older than this (0 = never expire)")
    ap.add_argument("--miss-max-age-days", type=int, default=30,
                    help="re-look-up NO-NAME entries older than this (0 = never expire)")
    ap.add_argument("--save-every", type=int, default=50,
                    help="flush cache to disk every N new lookups (kill-safety)")
    ap.add_argument("--cache-only", action="store_true",
                    help="emit names only from cache; never query QRZ")
    args = ap.parse_args(argv)

    creds = read_credentials(args.qrz_cfg)
    if creds is None:
        log(f"QRZ skipped: no usable [qrz] credentials at {args.qrz_cfg}.")
        log("  (Add ~/qrz_settings.cfg with [qrz] username/password to enable, "
            "or proceed without QRZ — calls stay bare.)")
        # write an empty CSV so downstream --names-csv is happy
        open(args.out, "w").close()
        return 0

    cand = candidate_calls(args)
    log(f"candidates: {len(cand)} call(s)")
    client = QRZNameClient(creds[0], creds[1], os.path.expanduser(args.cache),
                           hit_max_age_days=args.max_age_days,
                           miss_max_age_days=args.miss_max_age_days)

    # Show the cumulative cache state up front -- this is the real "how far along
    # the backfill is" number (it grows across runs toward the candidate count),
    # unlike the per-run lookup counter below.
    cached = len(client._cache)
    named = sum(1 for v in client._cache.values() if isinstance(v, dict) and v.get("name"))
    log(f"  QRZ name cache: {cached} entries ({named} named, {cached - named} cached-misses)")
    log(f"  resolving up to {args.limit or 'all'} new QRZ lookup(s) "
        f"(sleep {args.sleep}s); status every 100 ...")
    rows = []
    new_lookups = 0
    try:
        for call in cand:
            will_query = client.needs_lookup(call)
            if will_query:
                if args.cache_only:
                    continue                       # cache-only: skip uncached
                if args.limit and new_lookups >= args.limit:
                    continue
                new_lookups += 1
            try:
                nm = client.name(call)
            except Exception as e:   # network/API hiccup: stop, keep what we have
                log(f"  stopping at {call}: {e}")
                break
            nm = ascii_fold(nm)
            if nm:
                rows.append((call, nm))
            if will_query:
                # heartbeat so a long silent run shows it's alive and progressing
                if new_lookups % 100 == 0:
                    log(f"  ... {new_lookups} new lookups this run, cache now {len(client._cache)} entries (at {call})")
                # periodic atomic flush so a kill loses at most --save-every lookups
                if args.save_every and new_lookups % args.save_every == 0:
                    client.save()
                if args.sleep:
                    time.sleep(args.sleep)
    finally:
        client.save()

    with open(args.out, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        for call, nm in rows:
            w.writerow([call, nm])

    log(f"resolved names: {len(rows)}   new QRZ lookups: {new_lookups}   "
        f"cache size: {len(client._cache)}")
    log(f"wrote {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
