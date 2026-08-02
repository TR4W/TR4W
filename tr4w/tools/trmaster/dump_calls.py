#!/usr/bin/env python3
"""
Dump the unique callsigns from a TRMASTER/MASTER .dta file, one per line,
sorted, for eyeball spot-checking.

Reuses the validated parser in trmaster_codec.py so this stays in lock-step
with the real format (never re-decodes the binary itself).

Usage:
    python dump_calls.py [TRMASTER.DTA] [output.txt]

Defaults: reads TRMASTER.DTA in this folder, writes calls.txt beside it.
"""

import sys

from trmaster_codec import read_dta

src = sys.argv[1] if len(sys.argv) > 1 else "TRMASTER.DTA"
out = sys.argv[2] if len(sys.argv) > 2 else "calls.txt"

data = read_dta(src)
calls = sorted(data["calls"])

with open(out, "w", encoding="ascii") as f:
    for call in calls:
        f.write(call + "\n")

print(f"{src}: {len(calls)} unique calls -> {out}")
