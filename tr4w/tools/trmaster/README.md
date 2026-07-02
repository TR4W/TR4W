# TRMASTER.DTA offline builder

Offline tooling to (re)generate `TRMASTER.DTA` without depending on an external
maintainer's pipeline. **Nothing here runs inside TR4W** — run it before a build.

It unions a fresh callsign list (supercheckpartial) with the membership/name
layer (CWops, FOC, HSC), a curated name seed, and curated callsign-history name
files (ICWC-MST, K1USN SST, VE2FK Names) whose on-air names are more precise than
QRZ, optionally prunes lapsed US/UK/CA calls, backfills the rest from QRZ, and
writes the same **K1EA "CT / TRlog" `.dta`** TR4W already reads (no program
changes).

## Files

- **`build_trmaster.cmd`** — the monthly one-command runner. Downloads sources,
  builds, QRZ-fills names, prunes, and deploys to `tr4w\target\TRMASTER.DTA`
  (previous file → `.bak`). Edit the variables at the top. **Start here.**
- **`trmaster_build.py`** — downloads sources, merges, prunes, writes, validates.
- **`trmaster_codec.py`** — reader/writer for the `.dta` format + a self-test.
  `python trmaster_codec.py ../../target/TRMASTER.DTA` reports a field census and
  a read→write→read round-trip (PASS = writer reproduces the same calls, fields,
  and bucket placement the reader sees).
- **`trmaster_names_qrz.py`** — QRZ name resolver. Looks up still-nameless calls
  in a built `.dta` and emits a `CALL,NAME` CSV for `--names-csv`. Name priority:
  **nickname** ("Tom") → `fname` ("Thomas") → the `name` field **if it looks like
  a person, not a club** (recovers DX individuals like `9M2OCX→SHAHRUL`). Names
  are ASCII-folded (José→JOSE) for CW. Creds from `~/qrz_settings.cfg`; its own
  UTF-8 JSON cache with **atomic incremental saves** (kill-safe) and a **180-day
  TTL for names / 30-day for no-name results**. `--cache-only` regenerates the
  CSV from cache with no API calls. **Skips cleanly** (empty CSV, exit 0) with no
  QRZ subscription, so a future maintainer without QRZ can still build.

## Quick start (monthly)

```
build_trmaster.cmd
```

On first run it seeds `seed\TRMASTER_seed.DTA` from the current
`target\TRMASTER.DTA`, then: downloads SCP.DB (+ MASTER.DTA + CWops), builds,
runs QRZ, builds again with names, and deploys. Re-run `trmaster_names_qrz.py`
(step 3) a few times the first month to backfill the ~44k bare calls; the cache
makes later runs fast.

## Format (documented in `trmaster_codec.py`)

- 37×37 = 1,369 buckets (`A–Z 0–9 /`); 5,480-byte offset table (1,369 starts +
  1 end-offset = file size); then null-terminated `call + ^tag fields` records.
- A call is stored in the bucket of **each distinct adjacent char pair**, **except
  `JA`** (deliberately skipped — too common; matches `LogSCP.BestTwoLetters`).
- Field tags (verified against `N4AF`): `=N`/^N = first name (UPPERCASE),
  `=U`/^U = **CWops number**, `=F`/^F = **FOC number**, `=V`/^V = **HSC number**,
  plus Section/CQZone/Grid/ITUZone/Check/QTH/Hits/Speed/etc.

## Sources

- **supercheckpartial MASTER.DTA** — `https://supercheckpartial.com/downloads/MASTER.DTA`
  (calls only; the SCP coverage layer, ~50k). Read directly by the codec.
- **supercheckpartial SCP.DB** — `https://supercheckpartial.com/downloads/SCP.DB`
  (SQLite; `callsigns` ~69k with `verified` bitmask). Used for the QRZ-verified
  prune. Note: its `annual_rate` is **lifetime QSOs ÷ years active** — a lifetime
  average with **no recency**, so it can't tell active-now from long-lapsed.
- **CWops roster CSV** — Google Sheets `…/export?format=csv`. Positional columns
  (no header): `[2]=call, [3]=CWops#, [4]=first name`. Refreshed every run.
- **FOC / HSC** — seeded from the curated seed file (no live feed: the FOC page is
  a Cloudflare/AJAX wall). Override with `--foc-csv` / `--hsc-csv CALL,NUM[,NAME]`.
- **Callsign-history name files** — N1MM-style `CALL,NAME,...` text files kept in
  `seed\` (`ICWC-MST-*.txt`, `K1USNSST-*.txt`, `Names_VE2FK-*.txt`). Curated
  on-air CW names (nicknames), **more precise than QRZ**. Passed via `--history-glob
  PATTERN` (repeatable; pattern order = priority, ICWC > K1USN > VE2FK). Each
  pattern resolves to its **single newest** match, so **dropping an updated copy
  into `seed\` each month supersedes the prior one** — a name corrected/removed in
  the new file is not resurrected from a stale old copy. Like the CWops/FOC/HSC
  rosters, these calls **expand** the TRMASTER universe (curated → never pruned).

## Pruning lapsed calls (`--prune-qrz-unverified SCP.DB`)

Drops calls SCP.DB marks **not QRZ-verified** — but **only US/UK/CA** prefixes
(`K/N/W/AA-AL`, `G/M/2E/2I/2M/2U/2W`, `VA/VE/VO/VY`), where QRZ/licensing coverage
is comprehensive enough that "not QRZ-verified" means lapsed/invalid. **DX calls
are always kept** (QRZ is not a definitive source outside those regions), and
curated CWops/FOC/HSC/seed calls are never pruned. In practice this removes
~158 dead US/UK/CA calls while keeping ~1,822 valid DX without QRZ pages.

## Name augmentation

The bare SCP calls have no name. **QRZ** (`trmaster_names_qrz.py`) is the source:
it has the on-air **nickname** *and* covers **international** calls. Credentials in
`~/qrz_settings.cfg`. No subscription → it skips and calls stay bare (fine for SCP).
*(FCC ULS `en.first_name` is a US-only fallback if ever needed — gives the formal
name, not the nickname — exportable to a `--names-csv`.)*

## Merge precedence (per call)

Name precedence, highest → lowest: **CWops > FOC > history > seed > QRZ**.

1. curated **seed** (preserve accumulated Name + memberships + orphan names)
2. **callsign-history files** → Name (curated on-air names; **override** the
   accumulated seed/QRZ name, but the authoritative CWops/FOC rosters below still
   win). Within the history layer the first file to name a call wins (ICWC >
   K1USN > VE2FK). These calls also expand the universe.
3. CWops CSV → `User1` (CWops #) + Name (current roster wins)
4. FOC → `FOC` # + Name (roster name wins over history)
5. HSC → `User2` (HSC #)
6. `--names-csv` (QRZ) fills any remaining nameless call

Calls present only in the SCP source stay **bare** — still work for Super Check
Partial, just no prefill.

## Self-reference / what to back up

`build_trmaster.cmd` reads a **frozen** `seed\TRMASTER_seed.DTA` (created once) and
*writes* `target\TRMASTER.DTA`. There is **no read-from-and-write-to-`target`
loop**, so the monthly `target` output is fully regenerable and you do **not** need
to keep old copies (one `.bak` is kept for rollback). The files that carry
non-regenerable history — **back these up**:

- `seed\TRMASTER_seed.DTA` — frozen curated names / FOC / HSC / orphan names.
- `seed\ICWC-MST-*.txt`, `seed\K1USNSST-*.txt`, `seed\Names_VE2FK-*.txt` — the
  curated callsign-history name files (drop updated copies here monthly).
- `~\.publicLogProcessor\qrz_name_cache.json` — accumulated QRZ lookups (the
  expensive part; otherwise re-querying ~44k calls).

Caveat: FOC/HSC are frozen at the seed snapshot (no live roster feed); CWops is
refreshed live each run; QRZ names grow via the cache. Re-baseline the seed
(`copy target → seed`) only as a deliberate choice.

## `_work/`

Scratch dir for downloads + caches; git-ignored. Never commit downloaded data.

## Status / follow-ups

- Codec round-trip **proven** vs the shipped `TRMASTER.DTA` (6,354 calls); reads
  supercheckpartial's foreign `MASTER.DTA` (50,015 calls) cleanly.
- Current build: ~53k calls, ~8.6k named, US/UK/CA prune, validated.
- TODO: live FOC/HSC roster feeds; optional — measure live SCP lookup speed with
  the larger file before making it the default.
