#!/usr/bin/env python3
"""
Offline TRMASTER.DTA builder.

Unions a fresh callsign list (supercheckpartial MASTER.DTA, or optionally the
richer SCP.DB sqlite) with the membership/name layer (CWops roster CSV, FOC,
HSC) and any previously-accumulated names from the existing TRMASTER.DTA, then
writes a single K1EA .dta that TR4W's existing reader consumes unchanged.

Pipeline (Name precedence shown, high -> low):  CWops > FOC > history > seed > QRZ
  call universe  = MASTER.DTA calls  (+ every roster/existing call)
  per call fields:
    1. existing TRMASTER.DTA            (preserve accumulated Name + memberships)
    2. callsign-history files          -> Name (curated on-air names; override the
       (ICWC-MST / K1USN SST / VE2FK)      accumulated seed/QRZ name, but the
                                           authoritative CWops/FOC rosters below
                                           still win)
    3. CWops CSV   -> User1 (CWops #) + Name (overrides; roster is current)
    4. FOC         -> FOC #            + Name (roster name wins)
    5. HSC         -> User2 (HSC #)
    6. name resolver (optional --names-csv from your FCC/QRZ script) fills any
       call still missing a Name

Nothing here runs inside TR4W. Run it before the monthly build.

  python trmaster_build.py --out TRMASTER.DTA \
      --existing ../../target/TRMASTER.DTA \
      --download-master --cwops-url <google-csv-export-url> \
      [--scp-db _work/SCP.DB] [--names-csv names.csv] [--foc-csv foc.csv]

See README.md in this directory for source URLs and the FCC/QRZ hook.
"""

import argparse
import csv
import glob as globmod
import os
import re
import sqlite3
import sys
import urllib.request

import trmaster_codec as tc

CALL_RE = re.compile(r"^[A-Z0-9/]{3,}$")

# Prefixes where QRZ / licensing coverage is comprehensive enough that
# "not QRZ-verified" reliably means lapsed/invalid: US (K/N/W/AA-AL),
# UK (G/M/2E/2I/2M/2U/2W), Canada (VA/VE/VO/VY). Everywhere else is DX, where
# QRZ is NOT a definitive source, so those calls are never pruned.
US_UK_CA_RE = re.compile(r"^([KNW]|A[A-L]|G|M|2[EIMUW]|V[AEOY])")


def is_qrz_reliable_region(call):
    return bool(US_UK_CA_RE.match(call))
MASTER_DTA_URL = "https://supercheckpartial.com/downloads/MASTER.DTA"
SCP_DB_URL = "https://supercheckpartial.com/downloads/SCP.DB"


def log(msg):
    print(msg, flush=True)


def download(url, dest, force=False):
    if os.path.exists(dest) and not force:
        log(f"  cached: {dest} ({os.path.getsize(dest)} bytes)")
        return dest
    log(f"  downloading {url} -> {dest}")
    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "tr4w-trmaster-build"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        f.write(r.read())
    log(f"  saved {os.path.getsize(dest)} bytes")
    return dest


def valid_call(c):
    return bool(c) and bool(CALL_RE.match(c))


# --- source loaders ---------------------------------------------------------

def load_calls_from_dta(path):
    """Just the callsign universe from a .dta (e.g. supercheckpartial MASTER.DTA)."""
    return set(tc.read_dta(path)["calls"].keys())


def load_calls_from_scpdb(path, min_annual_rate=0):
    """Callsign universe from SCP.DB; optional activity floor via annual_rate."""
    out = set()
    c = sqlite3.connect(path)
    for call, rate in c.execute("select callsign, annual_rate from callsigns"):
        if call and valid_call(call.upper()):
            if min_annual_rate and (rate or 0) < min_annual_rate:
                continue
            out.add(call.upper())
    c.close()
    return out


def load_scpdb_verified(path):
    """From SCP.DB return (all_calls, qrz_verified_calls).
    QRZ-verified = bit 4 of the `verified` bitmask."""
    allc, ver = set(), set()
    c = sqlite3.connect(path)
    for call, v in c.execute("select callsign, verified from callsigns"):
        if not call:
            continue
        cu = call.upper()
        allc.add(cu)
        if (v or 0) & (1 << 4):
            ver.add(cu)
    c.close()
    return allc, ver


def load_existing(path):
    """Existing TRMASTER fields, to preserve accumulated names + memberships."""
    if not path or not os.path.exists(path):
        return {}
    return tc.read_dta(path)["calls"]


def parse_cwops_csv(path):
    """CWops roster CSV -> {CALL: {'User1': cwops#, 'Name': FIRSTNAME}}.

    Positional columns (no usable header): [2]=call [3]=number [4]=first name.
    """
    out = {}
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if len(row) < 5:
                continue
            call = row[2].strip().upper()
            num = row[3].strip()
            name = row[4].strip().upper()
            if not valid_call(call) or not num.isdigit():
                continue
            rec = {"User1": num}
            if name:
                rec["Name"] = name
            out[call] = rec
    return out


def parse_simple_csv(path, field):
    """Generic 'CALL,NUMBER[,NAME]' loader for FOC/HSC exports.
    `field` is 'FOC' or 'User2'. Returns {CALL: {field: num, ['Name': NAME]}}.
    """
    out = {}
    if not path or not os.path.exists(path):
        return out
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if not row:
                continue
            call = row[0].strip().upper()
            if not valid_call(call):
                continue
            rec = {}
            if len(row) > 1 and row[1].strip():
                rec[field] = row[1].strip()
            if len(row) > 2 and row[2].strip():
                rec["Name"] = row[2].strip().upper()
            if rec:
                out[call] = rec
    return out


def load_names_csv(path):
    """Optional name source (e.g. produced by the user's FCC/QRZ scripts):
    'CALL,NAME' -> {CALL: NAME(upper)}.  This is the name-resolver hook.
    """
    out = {}
    if not path or not os.path.exists(path):
        return out
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if len(row) >= 2 and valid_call(row[0].strip().upper()) and row[1].strip():
                out[row[0].strip().upper()] = row[1].strip().upper()
    return out


def load_include_calls(paths):
    """Force-include callsigns that must survive the QRZ-verified prune.

    Some legitimate calls are simply not in QRZ -- e.g. Ofcom special-event
    callsigns issued for a single weekend (WRTC). SCP.DB marks them
    not-QRZ-verified, so --prune-qrz-unverified would drop them. Listing them
    here adds them back into the universe AFTER the prune, so they are never
    pruned. They also expand the universe (a listed call absent from every other
    source is still emitted).

    Format: one call per line; blank lines and '#' comments are ignored; only the
    first whitespace token on a line is used (trailing text discarded); case is
    folded and duplicates collapsed. Returns a set of uppercase calls. This is the
    same format the slideshow's wrtc2026.txt already uses, so one file serves both.
    """
    out = set()
    for path in paths or []:
        if not path or not os.path.exists(path):
            log(f"  include: no file matches {path}")
            continue
        n0 = len(out)
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                call = line.split()[0].upper()
                if valid_call(call):
                    out.add(call)
        log(f"  include {os.path.basename(path)}: +{len(out) - n0} calls "
            f"(total {len(out)})")
    return out


def resolve_history_files(patterns):
    """Resolve each --history-glob pattern to the single NEWEST matching file.

    The monthly workflow is to drop an updated copy (new version suffix, e.g.
    ICWC-MST-047.txt -> ICWC-MST-048.txt) into the seed dir. Picking only the
    newest per pattern means the fresh drop fully supersedes the prior month:
    a name corrected/removed there is not resurrected from a stale old copy left
    behind. `sorted(..., reverse=True)` puts the highest (zero-padded) version
    first; it also prefers 'ICWC-MST-047.txt' over the 'ICWC-MST-047 (1).txt'
    accidental download dup. Returns files in the given pattern order = priority.
    """
    files = []
    for pat in patterns or []:
        matches = sorted(globmod.glob(pat), reverse=True)
        if not matches:
            log(f"  history: no file matches {pat}")
            continue
        if len(matches) > 1:
            log(f"  history: {len(matches)} files match {pat}; using newest "
                f"{os.path.basename(matches[0])} "
                f"(ignoring {[os.path.basename(m) for m in matches[1:]]})")
        files.append(matches[0])
    return files


def load_history_names(paths):
    """N1MM-style callsign-history files (ICWC-MST, K1USN SST, VE2FK Names, ...).

    Format: CSV, col0 = CALL, col1 = NAME; lines starting with '#' or '!!' are
    comment/header lines and are skipped. `paths` is in PRIORITY order: the first
    file to define a name for a call wins (later files only fill calls not yet
    seen). Returns {CALL: NAME(upper)}.
    """
    out = {}
    for path in paths:
        if not path or not os.path.exists(path):
            continue
        n0 = len(out)
        with open(path, newline="", encoding="utf-8", errors="replace") as f:
            for row in csv.reader(f):
                if not row:
                    continue
                c0 = row[0].strip()
                if not c0 or c0.startswith("#") or c0.startswith("!!"):
                    continue
                call = c0.upper()
                name = row[1].strip().upper() if len(row) > 1 else ""
                if valid_call(call) and name and call not in out:
                    out[call] = name
        log(f"  history {os.path.basename(path)}: +{len(out) - n0} new names "
            f"(total {len(out)})")
    return out


# --- merge ------------------------------------------------------------------

def merge(universe, existing, history, cwops, foc, hsc, names):
    """Build {CALL: fields} by the documented precedence.

    Name precedence (high -> low): CWops > FOC > history > seed(existing) > QRZ.

    History calls, like the CWops/FOC/HSC rosters, expand the call universe
    (curated active participants) and are therefore never pruned.
    """
    calls = (set(universe) | set(existing) | set(history)
             | set(cwops) | set(foc) | set(hsc))
    out = {}
    for call in calls:
        f = {}
        # 1. preserve accumulated data (seed Name + memberships)
        if call in existing:
            f.update(existing[call])
        # 2. callsign-history files override the accumulated seed/QRZ name
        #    (curated on-air names). Applied BEFORE CWops/FOC so those
        #    authoritative rosters still win over the history name.
        if call in history:
            f["Name"] = history[call]
        # 3. CWops (current roster wins for number + name)
        if call in cwops:
            f["User1"] = cwops[call]["User1"]
            if cwops[call].get("Name"):
                f["Name"] = cwops[call]["Name"]
        # 4. FOC (roster name wins over history)
        if call in foc:
            if foc[call].get("FOC"):
                f["FOC"] = foc[call]["FOC"]
            if foc[call].get("Name"):
                f["Name"] = foc[call]["Name"]
        # 5. HSC
        if call in hsc and hsc[call].get("User2"):
            f["User2"] = hsc[call]["User2"]
        # 6. name resolver (QRZ) fills any call still nameless
        if not f.get("Name") and call in names:
            f["Name"] = names[call]
        out[call] = f
    return out


def census(calls, label):
    def has(fld):
        return sum(1 for v in calls.values() if v.get(fld))
    log(f"=== {label}: {len(calls)} calls ===")
    for fld in ("Name", "User1", "FOC", "User2"):
        log(f"    {fld:6}: {has(fld)}")
    log(f"    bare (no name): {sum(1 for v in calls.values() if not v.get('Name'))}")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Offline TRMASTER.DTA builder")
    ap.add_argument("--out", default="TRMASTER.DTA")
    ap.add_argument("--existing", help="existing TRMASTER.DTA to preserve names from")
    ap.add_argument("--master-dta", help="local supercheckpartial MASTER.DTA")
    ap.add_argument("--download-master", action="store_true",
                    help="download the latest MASTER.DTA")
    ap.add_argument("--scp-db", help="SCP.DB sqlite as the call universe (instead of MASTER.DTA)")
    ap.add_argument("--min-annual-rate", type=int, default=0,
                    help="when using --scp-db, drop calls below this activity rate")
    ap.add_argument("--cwops-csv", help="local CWops roster CSV")
    ap.add_argument("--cwops-url", help="CWops roster CSV export URL")
    ap.add_argument("--foc-csv", help="FOC export CSV (CALL,NUM[,NAME])")
    ap.add_argument("--hsc-csv", help="HSC export CSV (CALL,NUM[,NAME])")
    ap.add_argument("--history-glob", action="append", default=[], metavar="PATTERN",
                    help="callsign-history file glob (repeatable; pattern order = "
                         "priority). Each pattern resolves to its single newest "
                         "match, e.g. \"seed/ICWC-MST-*.txt\".")
    ap.add_argument("--history-file", action="append", default=[], metavar="FILE",
                    help="explicit callsign-history file (repeatable; order = "
                         "priority; applied before --history-glob results).")
    ap.add_argument("--names-csv", help="name source CSV (CALL,NAME) from FCC/QRZ")
    ap.add_argument("--include-file", action="append", default=[], metavar="FILE",
                    help="force-include callsigns (repeatable); one call per line, "
                         "blank/'#' lines ignored, first token used. Added to the "
                         "universe AFTER the prune, so listed calls are never pruned "
                         "(e.g. Ofcom WRTC special-event calls QRZ has not listed).")
    ap.add_argument("--prune-qrz-unverified", metavar="SCP.DB",
                    help="drop universe calls that SCP.DB marks NOT QRZ-verified "
                         "(removes lapsed/unverifiable calls; curated CWops/FOC/"
                         "HSC/existing calls are never pruned)")
    ap.add_argument("--workdir", default="_work")
    ap.add_argument("--force", action="store_true", help="re-download even if cached")
    args = ap.parse_args(argv)

    # 1. call universe
    if args.scp_db:
        log("call universe: SCP.DB")
        universe = load_calls_from_scpdb(args.scp_db, args.min_annual_rate)
    else:
        mpath = args.master_dta
        if args.download_master or not mpath:
            mpath = download(MASTER_DTA_URL, os.path.join(args.workdir, "MASTER.DTA"),
                             force=args.force)
        log("call universe: MASTER.DTA")
        universe = load_calls_from_dta(mpath)
    log(f"  universe calls: {len(universe)}")

    # Optional prune: keep only QRZ-verified universe calls (SCP.DB bit 4).
    # Calls absent from SCP.DB are kept (can't judge); curated calls are added
    # later by merge() regardless, so they are never pruned here.
    if args.prune_qrz_unverified:
        allc, ver = load_scpdb_verified(args.prune_qrz_unverified)
        before = len(universe)
        # Prune ONLY US/UK/CA calls that SCP.DB knows are not QRZ-verified.
        # DX calls are kept regardless (QRZ is not definitive outside those
        # regions); curated CWops/FOC/HSC/existing calls are added by merge()
        # afterward, so they are never pruned here.
        universe = {c for c in universe
                    if not (is_qrz_reliable_region(c) and c in allc and c not in ver)}
        log(f"  QRZ-verified prune (US/UK/CA only): {before} -> {len(universe)} "
            f"(dropped {before - len(universe)}; DX kept)")

    # Force-include list: calls that must survive the prune (e.g. special-event
    # calls QRZ does not list). Applied AFTER the prune so listed calls are never
    # dropped, and unioned into the universe so a listed call missing from every
    # other source is still emitted.
    include = load_include_calls(args.include_file)
    if include:
        before = len(universe)
        universe |= include
        log(f"  force-include: {before} -> {len(universe)} "
            f"(+{len(universe) - before} of {len(include)} listed)")

    # 2. layers
    existing = load_existing(args.existing)
    log(f"  existing TRMASTER calls: {len(existing)}")

    cwops_path = args.cwops_csv
    if args.cwops_url and not cwops_path:
        cwops_path = download(args.cwops_url, os.path.join(args.workdir, "cwops.csv"),
                              force=args.force)
    cwops = parse_cwops_csv(cwops_path) if cwops_path else {}
    log(f"  CWops roster: {len(cwops)}")

    # FOC/HSC: seed from existing TRMASTER, override with explicit exports if given
    foc = {c: {"FOC": v["FOC"], "Name": v.get("Name")}
           for c, v in existing.items() if v.get("FOC")}
    foc.update(parse_simple_csv(args.foc_csv, "FOC"))
    hsc = {c: {"User2": v["User2"]} for c, v in existing.items() if v.get("User2")}
    hsc.update(parse_simple_csv(args.hsc_csv, "User2"))
    log(f"  FOC entries: {len(foc)}   HSC entries: {len(hsc)}")

    # callsign-history name layer (curated on-air names; override seed/QRZ,
    # below CWops/FOC). Priority = explicit --history-file first, then each
    # --history-glob's newest match, in the order given.
    history_paths = list(args.history_file) + resolve_history_files(args.history_glob)
    history = load_history_names(history_paths)
    log(f"  history names: {len(history)}")

    names = load_names_csv(args.names_csv)
    log(f"  name-resolver names: {len(names)}")

    # 3. merge + write
    merged = merge(universe, existing, history, cwops, foc, hsc, names)
    census(merged, "merged")
    size = tc.write_dta(args.out, merged)
    log(f"\nwrote {args.out}: {size} bytes")

    # 4. validate output is readable + self-consistent
    back = tc.read_dta(args.out)
    ok = (len(back["calls"]) == len(merged)
          and back["end_offset"] == back["file_size"])
    log(f"validate: re-read {len(back['calls'])} calls, "
        f"end-offset {'OK' if back['end_offset']==back['file_size'] else 'MISMATCH'} "
        f"-> {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
