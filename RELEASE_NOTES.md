# TR4W Release Notes

**TR4W (TRLOG 4 Windows)** is a free, open-source contest logging application for amateur radio operators running Windows. It supports CW, SSB, and digital modes; dozens of contests from ARRL events to QSO Parties and DX contests; rig control for a wide range of transceivers; POTA (Parks on the Air) activations; DX cluster/band map; WSJT-X/FT8 integration; SO2R; networked multi-op; and much more.

This is the user-facing changelog — it covers what changed, what was fixed, and what's new in each release. Technical implementation details have been trimmed so you can quickly find what matters to you on the air.

---

## Contributors

| Call | GitHub | Commits |
|--------|--------|---------|
| N4AF — Howie Hoyt | [@n4af](https://github.com/n4af) | 734 |
| NY4I — Tom Schaefer | [@ny4i](https://github.com/ny4i) | 394 |
| GM0GAV — Gavin Taylor | [@gm0gav](https://github.com/gm0gav) | 12 |
| K0TI — Dan | [@Dan-K0TI](https://github.com/Dan-K0TI) | 8 |
| Vojtěch Šádek | [@vksadek](https://github.com/vksadek) | 1 |
| Dmitriy Gulyaev UA4WLI | | (Original Author of Win32 Port / Pre-GitHub)|
| N6TR - Tree | [@n6tr](https://github.com/n6tr) | (Original TRLOG (DOS) Author) |

Various contributors along the way

---

## Unreleased

<!--
In-arrears versioning: new user-facing entries accumulate here as work lands; the
version number is assigned later, when a release is cut. To cut a release: rename this
"## Unreleased" to "### X.X.X (YYYY-MM-DD) — HANDLE", move it under the appropriate
"## 4.147.x" month group below, and bump tr4w/src/Version.pas to match. Keep entries
user-facing — no file paths or source-level jargon.
-->

#### Window Layout

- **Windows saved on a monitor you've since disconnected now come back on-screen.** If TR4W starts and a window was on a monitor that's no longer there (laptop undocked, second display off, or resolution changed), it's brought back onto an available monitor instead of opening off-screen where you can't reach it. Several recovered windows fan out so they don't stack on top of each other. (#739)
- **Your multi-monitor layout is preserved.** If a window is auto-recovered but you don't move it, TR4W keeps its original spot saved — so when you reconnect that monitor, the window returns to where you had it. Move a recovered window and that new position sticks instead.
- **Windows on a monitor placed to the left of (or above) your main screen now save their position correctly** — previously those could revert to the primary monitor.

---

## 4.148.x — June 2026

> 📋 **See [docs/WHATS_NEW_4.148.md](docs/WHATS_NEW_4.148.md) for a consolidated, by-feature view of everything new across the 4.148.x series.**

### 4.148.16 (2026-06-19) — NY4I

#### Radio Control

- **CW-by-CAT now keys short messages reliably on the Elecraft K3/KX3/K4.** Sending a short CW message like `?` or `AGN` over CAT could silently fail to key on the K3; it now keys consistently. (#1057)
- **The frequency display turns red when a serial radio goes quiet.** If a serial-connected radio stops answering CAT polling (about 3 seconds), the main-window frequency shows in red so you can see at a glance that the rig isn't responding; it clears once it answers again. (#1055)

---

### 4.148.15 (2026-06-18) — NY4I

#### CW

- **The "resend last CW message" key is now Ctrl+= (was `=`).** The plain `=` key collided with Quick QSL Key 2; resend last message is now Ctrl+= while in CW mode in the call/exchange fields. (#1054)

---

### 4.148.14 (2026-06-14) — NY4I

#### ADIF Export

- **Field Day ADIF records no longer carry a duplicate sent-exchange tag.** ARRL Field Day and Winter Field Day exports were writing the sent exchange twice per record; now it appears once. (#1050)
- **More accurate state in exported ADIF.** TR4W no longer guesses a station's state from a two-letter exchange, which previously mislabeled ARRL-section contests (a section like "EB" was wrongly written as state "EB"). Field Day and Winter Field Day now derive the correct state from the section (e.g. WCF → FL) and tag the country. Sweepstakes and ARRL 160 export the section only for now; their state will follow once a related section-naming fix lands (#1052).

---

### 4.148.13 (2026-06-14) — NY4I

#### ADIF Export

- **ADIF export no longer writes "Error generating my exchange" in the sent-exchange field.** Exporting your log to ADIF had been putting that error text into the sent-exchange (`STX_STRING`) of every record. The sent exchange is now exported correctly for all contests. Re-export an affected log after upgrading to clean it up. (#1049)

---

### 4.148.12 (2026-06-14) — NY4I

#### Band Map

- Double-clicking a spot no longer occasionally clears the callsign it just loaded into the call window. (This only showed up with "jump to S&P when you tune" / AUTO S&P enabled.) (#1048)

#### CW

- Setting **`CW ENABLE = FALSE` now actually keeps CW off** from startup — the display and keying agree, with no need to toggle CW off then on (Alt-K) twice. (#1047)

#### Digital / FT8

- In a digital mode (for example FT8 via WSJT-X), **typing a callsign no longer keys CW**. (#1040)

#### Log Window

- The **bottom row of the log window is no longer cut off** — it shows fully with a clean border, at every row-count setting. (#1046)

#### VHF

- ARRL January, June, and September VHF now produce the proper **RST + grid exchange** in the Cabrillo file.

#### Cabrillo

- If a contest's exchange isn't handled by the Cabrillo generator, that line is now **flagged with an error marker (and logged) instead of written blank**, so it can't slip by unnoticed. (#1043)

#### Multi-Op / Networking

- While the network server is unreachable, the log **no longer fills with repeated "trying / failed to connect" messages**. (#1041)

#### Under the Hood

- Continued removal of legacy inline assembly across the radio, formatting, and utility code for the Delphi 12 / 64-bit migration — no on-air change. (#997)

---

### 4.148.11 (2026-06-12) — NY4I

#### Radio Control

- Network radio setup is more reliable: each model now has the correct default network port and discovery behavior, and switching between models (e.g. IC-7760 → K4) no longer leaves a stale port. (#1028)

#### Search & Pounce

- The F1 send-call label shows **"Call" instead of "DE+Call" when DE is disabled** (`DE ENABLE = FALSE`). (#1012)

#### CW

- Press **`=` to resend exactly what you last sent** on CW.

#### Display

- A **stuck exchange-error message** (for example, an improper Field Day class) now clears once you log the corrected QSO. (#1030)

---

### 4.148.10 (2026-06-12) — NY4I

#### Function Keys

- You can now **right-click a function key to edit that key's message** directly — it picks the right CQ vs Search-and-Pounce message for your current mode. (#1001)
- Right-clicking a function key while holding **Alt or Ctrl** no longer pops up a spurious menu. (#1007)

#### Send From Keyboard

- Fixed a **Send Keyboard Input dialog that could open duplicated or refuse to close**. (#1006)

#### Data Entry

- When an exchange you type **can't be parsed, the cursor now lands right after the part it didn't understand**, so you can correct it without hunting for it. (#1010)

#### CW

- CW enable / disable / toggle now behaves consistently (driven by a single internal switch). (#380)

#### Cabrillo & Log Export (bug fixes)

- **CSV export no longer writes stray duplicate lines** for skipped, deleted, or non-QSO records.

#### Bundled Data

- The **DX cluster list (TRCLUSTER.DAT) is refreshed each monthly build**, and a fresh copy ships with this release. (#391)

---

### 4.148.7 (2026-06-08) — NY4I

#### Crash Recovery

- **The restart file is saved after each QSO again.** The **UPDATE RESTART FILE ENABLE** setting — which had quietly been doing nothing for years — now works and is **on by default**, so after an unexpected shutdown TR4W restores more of your latest operating state. Set `UPDATE RESTART FILE ENABLE = FALSE` if you'd rather it only save on operator change, log load, and exit. (#950)

#### Translations

- **Spanish**: translation refinements. (#992)

---

### 4.148.6 (2026-06-08) — NY4I

#### DX Cluster

- **Copy/paste works in the command field**: Ctrl-V (paste), Ctrl-C (copy), and Ctrl-X (cut) now work while typing a cluster command — previously only right-click → Paste did. (#23)
- **Connecting no longer freezes TR4W**: the cluster connection runs in the background, so connecting to a slow or unreachable host no longer locks up the program. You get immediate feedback — "Connecting to host:port", the Connect button grays out and Disconnect enables — and a clear "Could not connect to host:port" if it fails (the full technical reason is saved to the log).
- **Fixed a crash** that could occur when a long connection-error message was displayed.
- **Polish**: status messages are no longer green, and Freeze turns off each time you connect so you always return to live spots. A new **TELNET DEBUG** setting logs cluster traffic for troubleshooting.

#### Rotator Control

- **PSTRotator support**: a new rotator type, **PSTROTATOR**, points your antenna through PSTRotator over the network. Set ROTATOR TYPE = PSTROTATOR and the PSTROTATOR IP ADDRESS / UDP PORT (defaults 127.0.0.1 : 12000). (#732)
- **Long-path turn**: **Alt-Ctrl-P** turns the rotator to the long path; **Ctrl-P** still turns short path. (#20)
- With debug logging at TRACE, the exact commands sent to the rotator are now logged for troubleshooting. (#989)

#### Radio Setup

- **The radio configuration window's Reset button now fully resets the form** — clearing the IP address and TCP port, setting keyer RTS/DTR to OFF, and restoring the radio name to its default — the **Close button is now labeled Cancel**, and closing with the **X** asks before discarding unapplied changes.

#### Usability

- **Previewed files open in your default text editor**: log/summary/Cabrillo/ADIF previews (and the History file) now open in whatever editor you've set for .txt files — Notepad++, VS Code, etc. — instead of always Notepad. (#986)

---

### 4.148.5 (2026-06-07) — NY4I

#### Cabrillo Categories & Export

- **Category choices match the current Cabrillo spec**: the contest category drop-downs are updated — Transmitter offers **TWO**, Mode adds **FM**, Time adds **8-HOURS**, Overlay drops OVER-50 and adds **YOUTH** and **YL**, and Station adds **DISTRIBUTED**, **ROVER-LIMITED**, **ROVER-UNLIMITED**, and **EXPLORER**. (#976)
- **Station, Time, and Overlay categories now stick**: Station Category is now a drop-down, and your Time and Overlay choices are remembered the next time you open the Cabrillo Summary — previously they weren't saved.
- **OK closes the export dialog**: clicking **OK** in the Cabrillo Summary now finishes the export and closes the dialog. Previously a successful export left the dialog open, so you had to click Cancel to get out.

#### WSJT-X / Digital

- **Band follows WSJT-X when you have no rig connected**: if no radio is set up in TR4W, switching bands in WSJT-X now moves TR4W to the matching band (band indicator, totals row, and band map all update). With a radio connected, nothing changes. (#978)

#### Contests

- **TESLA contest renamed HF-TESLA**: the TESLA Memorial HF CW Contest now appears as **HF-TESLA**, with the correct Cabrillo name. (#745)

#### Exchange Entry

- **Clearer domestic-QTH error**: when an entered section/QTH isn't recognized for a domestic contest, the message now reads **"Invalid ARRL Section"** instead of a generic, misspelled prompt.

---

### 4.148.4 (2026-06-06) — NY4I

#### DX Cluster

- **Insert your station info into cluster commands automatically**: lines in your `cluster_commands.txt` can now contain placeholders like `{MY_CALL}`, `{MY_STATE}`, `{MY_GRID}`, `{BAND}`, `{FREQ}`, `{DATE}` or `{TIME}` (and more). When you pick the command from the cluster window's **Commands** button, the placeholder is replaced with the current value before the command is sent — so one command file works no matter who's operating or what band you're on. Hover over a command to preview exactly what will be sent. To include a literal brace in a command, double it (`{{` or `}}`). (#973)

#### WSJT-X / Digital

- **WSJT-X contacts log again**: a recent change had stopped WSJT-X-logged contacts (FT8/FT4, ARRL-DIGI, etc.) from being recorded in TR4W. They now log correctly. (#975)
- **Operator now recorded on WSJT-X contacts**: WSJT-X QSOs now fill in the operator / computer-ID column just like hand-logged contacts.
- **Operator-mismatch alert**: if the operator set in WSJT-X differs from the operator set in TR4W, you'll get a flashing on-screen warning and a beep when the contact logs, so you can fix whichever one is wrong. A blank operator in WSJT-X won't trigger it. (#977)

---

### 4.148.3 (2026-06-05) — NY4I

#### Radio Mode / SO2R

- **One radio-mode setting**: the old, conflicting "Single Radio Mode" and "Two Radio Mode" options are now a single **TWO RADIO MODE** setting (TRUE = two radios / SO2R, FALSE = single radio). Existing configuration files still load — and if both old settings happen to be present, TWO RADIO MODE now wins, so a stray leftover line can't silently put you in the wrong mode. (#965)
- **Two-radio bandmap highlight restored**: in two-radio mode the bandmap again highlights the inactive (search-and-pounce) radio's band and grays the running radio's band — the SO2R behavior from before 4.147. (#960)

#### Network Radio Setup

- **Find your radio on the network automatically**: a new "Discover" button in the Radio 1 / Radio 2 setup dialog scans your local network and fills in the radio's IP address for you. It works for the Elecraft K4 and Icom network radios, and now finds a radio on any subnet your PC is on. (#853)
- **Correct default network port per radio**: when you choose a network radio type, TR4W pre-fills the right TCP port for that model (K4, FlexRadio, Kenwood TS-890/TS-990, Icom) so you don't have to look it up. (#968)
- **Cleaner setup**: leaving a network port blank no longer throws a confusing "invalid statement" error, and a radio with no address set no longer floods the log with connection retries.

#### Configuration Files

- **`#` now works as a comment**: you can disable a line in a configuration file by starting it with `#` (in addition to the existing `;`). Previously a line beginning with `#` produced a "config file error."

#### Reports & Scoring

- **Friendly contest names**: the summary sheet and score report now show a readable contest name in parentheses next to the contest, for roughly 130 contests. (#967)

---

### 4.148.1 (2026-06-02) — NY4I

#### Parallel-Port (LPT) Keying

- The installer no longer includes inpout32.dll — the component several antivirus engines flagged as a "vulnerable driver," which is what caused some browsers and antivirus tools to block the download. Serial, USB, and network keying and rig control are completely unaffected. If you use direct parallel-port (LPT) keying, footswitch, paddle, or band-data output, you now supply inpout32.dll yourself: download it from highrez.co.uk and place it in the same folder as tr4w.exe. If you have an LPT port configured but the file isn't present, TR4W now shows a reminder and keeps running, instead of failing to start.

---

### 4.148.0 (2026-06-01) — NY4I

#### Radio Control — Kenwood TS-890 over LAN

- The band and mode shown in TR4W now follow the radio. Previously only the frequency tracked the rig — the band display, band table, and mode wouldn't update when you changed bands on the radio (and startup could show NONSSB). (#959)
- The RIT/XIT offset (the actual amount of clarifier shift) is now displayed, not just the on/off state.
- When you switch the radio's operating VFO (A/B), TR4W now follows it correctly — per-VFO modes no longer appear swapped, the main window tracks the receive VFO's frequency/band/mode, and the Radio 1 window highlights the active VFO.
- CW sent to the TS-890 over CAT is no longer zero-padded, which also corrects the reported keying length.
- Connecting to a radio over a VPN no longer times out — the connection window was too short for a VPN's slightly longer handshake, so a rig that worked on the local network would report "Connect timed out" over VPN. (#959)

#### Usability

- Fixed a typo in the QSO Number pop-up (Ctrl-/ → Additional Information): it read "QSO nuber" and now reads "QSO number." (#962)

#### Super Check Partial

- The bundled callsign database (TRMASTER.DTA) has been refreshed again for better Super Check Partial suggestions as you type.

#### For Contributors / Power Users

- The monthly-release script is more robust: a one-step MonthlyBuild command, hardened tagging that can't tag a stale build, and a fix to an internal bug that made the release script hang.

---

## 4.147.x — May 2026

### 4.147.25 (2026-05-31) — NY4I

#### Serial Numbers

- Marking a QSO as X-QSO no longer rolls your sent serial number backward. The next number you send is now based on the highest number you've actually sent, so it only ever moves forward — even after you X-QSO a contact or delete one from the middle of the log. (Previously the count-based number could revert and hand the same serial to two stations.) (#954)
- When you mark a contact X-QSO, it now stays in your external log (e.g. DXKeeper) — it's only removed from the contest score and the real-time score feeds. (#949)

#### Radio Control — Kenwood TS-890 over LAN

- The TS-890 now connects reliably over the network: the login no longer hangs waiting for a message the radio doesn't send, and commands are sent in the exact format its CAT parser expects (a stray line-ending was causing it to reject every command after login).
- Band changes no longer drop the radio into DATA mode or send an empty frequency, and RIT, XIT, Split, and transmit (TX/RX) state toggled on the radio now show correctly in TR4W.

#### Super Check Partial

- The bundled callsign database (TRMASTER.DTA) has been refreshed to 53,281 calls for better Super Check Partial suggestions while you type.

#### In-App Command Help

- The configuration-command help text has been cleaned up and filled in — entries for commands that no longer exist were removed, and descriptions were written for many that had been left blank.

#### For Contributors / Power Users

- New offline tool to rebuild the Super Check Partial database (TRMASTER.DTA) from public sources, plus a one-step release script. Build/CI fix so the release pipeline's malware scan runs correctly on the self-hosted Windows runner.

---

### 4.147.24 (2026-05-29) — NY4I

#### For Contributors / Source Builders

- Follow-up to the bundled-Indy change in 4.147.21: leftover references to a separate `C:\Indy` install have been cleaned out of the Delphi IDE project files and the helper build/test scripts. Opening `tr4w.dpr` in Delphi 7, or running the server/test build scripts, now uses the bundled `tr4w/include` copy with no external Indy install required. (Set `INDY_ROOT` to override.)
- Removed three stray Git submodule pointers (`tr4w/include/Indy`, `tr4w/src/rekor-cli`, `tr4w/src/root-signing`) that produced a harmless but noisy warning at the end of every automated release build.
- The Spanish installer's embedded version info (Properties → Details) is now correctly tagged Spanish (Spain) instead of English — cosmetic; the program UI was already fully Spanish.
- No change to the program itself — these are build/packaging fixes only.

---

### 4.147.23 (2026-05-29) — NY4I

#### Internal / Build

- Release-build infrastructure changes only (CI pipeline now runs entirely on the self-hosted Windows runner, plus a version-number sanity check). No effect on the program itself.

---

### 4.147.22 (2026-05-29) — NY4I / N4AF

#### Language Support

- **Spanish (ESP) is now fully supported**, including translated command help — on par with the other shipped languages.
- Column-width settings saved in a config file now load correctly regardless of the language the config was created in (previously a config saved by an English build wouldn't load in a Spanish/Russian/etc. build).

---

### 4.147.21 (2026-05-29) — NY4I

#### HamScore Score Posting

- TR4W now speaks the HamScore RTC 3.0 protocol. When the server returns a warning ("exchange mismatch") or error ("bad credentials"), that message appears on the Settings status line so you know why a contact wasn't accepted.
- Per-QSO contact uploads (the "moving log" feed on HamScore) are now gated by a new `HAMSCORE SEND CONTACT INFO = TRUE` setting plus a per-contest flag. If you run a contest HamScore doesn't track, TR4W no longer wastes time uploading contacts the server would just reject. The realtime score is still uploaded regardless.
- The score upload now sends your full station profile (club, section/state, grid, continent, country, zones). Most of this is read from the Cabrillo summary you've already filled in — only ITU zone needed a new setting (`MY ITU ZONE`), needed for large countries that span more than one ITU zone.
- Editing a logged QSO now correctly resubmits the corrected version to HamScore. SST and NAQP exchange edits in particular previously didn't reach HamScore, and ALT-Y deletes weren't sent at all.
- New `K1USN-SST` ADIF name and `K1USNSST` Cabrillo name for the K1USN SST.

#### Installer / Antivirus

- The TR4W installer is no longer UPX-compressed by default. UPX is a frequent trigger for false-positive antivirus detections — the prior release hit 8 detections including Microsoft Defender; the same build without UPX dropped to 3. The trade-off: about 2.4 MB larger installer download and ~1 MB more disk space per installed EXE. If you want UPX back, build from source with `FullBuild.ps1 -UseUpx`.
- The installed EXE now reports proper Windows version-info: right-click `tr4w.exe` → Properties → Details to see version and language.

#### For Contributors / Source Builders

- Building from source no longer requires a separate Indy install at `C:\Indy` — the bundled `tr4w/include` copy is used by default. Set `INDY_ROOT` to override.
- New `docs/UPDATING_RUNTIME_DLLS.md` covers refreshing the bundled HamLib / OpenSSL / inpout32 / rigctld binaries.

---

### 4.147.19 (2026-05-26) — NY4I / N4AF

#### Continuous Integration & Release Packaging

- **TR4W is now built automatically when a maintainer tags a release.** GitHub Actions compiles the program on a Windows runner, packages the NSIS installer, uploads it to a draft GitHub Release, and (when the tag carries the `-all` suffix) also builds the 7 non-English language installers. The English-only release path is the normal cadence; the all-languages path is for major releases. You'll find the installer on the project's Releases page once a release is published. (PRs #923, #927)
- **Every CI-built installer is scanned by VirusTotal before release.** The scan report is attached to each draft GitHub Release so you can see exactly which engines (if any) flagged the installer and what they called it. Most flags on unsigned NSIS+UPX-compressed installers are heuristic false positives; the report makes that easy to verify.

#### TS-890 LAN Operation

- **Kenwood TS-890 over LAN is more reliable.** TR4W now sends a keepalive every 5 seconds, waits for the radio's initial time-sync response before sending its setup commands, and parses additional status messages (transmitter band, fine-tune step, RIT, XIT). Reduces intermittent disconnects and fixes cases where band/mode changes on the radio weren't reflected in TR4W. (PR #922)

#### CW-by-CAT (Kenwood & Elecraft)

- **CW-by-CAT now actually sends.** When `RADIO ONE CWByCAT = True` was set and you started typing a callsign, the CW was supposed to be sent via the radio's KY command. A latent uninitialized-variable bug meant the first character was sometimes lost and downstream characters never queued — appearing as "CW just doesn't send." Fixed. (PR #922)

#### Bandmap

- **Bandmap repaint no longer occasionally paints a stray cursor.** A repaint path had an uninitialized variable that produced different cursor behavior across runs; pinned to the no-cursor default unless an active selection actually exists. (PR #922)

#### HamScore Real-Time Scoring — follow-up to 4.147.15

- **RTC `SentExchange` is now `<serial> <grid>`, no RST.** The 4.147.15 work shipped a canonical `RxExchange` that already excluded RST, but `SentExchange` still echoed the operator's CQ-Exchange template — so anyone who customized that template to include `5NN`/`599` for on-air keying was inadvertently sending RST in the HamScore upload too. The HamScore organizers confirmed in May 2026 that RST is intentionally skipped in both fields for RTC; TR4W now builds the canonical SentExchange from your serial number + grid directly, independent of the on-air template. Your on-air keying behavior is unchanged. (PR #929)

#### Language Files

- **Russian, Ukrainian, and other non-English builds compile again** after the constants framework was reworked to derive the language from a compiler flag instead of a hand-edited string. (PR #924)
- **Several leftover English strings in non-English UIs translated** to their respective languages.

#### Building TR4W Locally

- **New `Build.cmd`, `BuildAll.cmd`, and `BuildAllInstallers.cmd`** at the repo root let you build TR4W locally without touching Delphi 7 IDE settings. `Build.cmd` produces the English `tr4w.exe`; `BuildAll.cmd` adds per-language exes for spot-testing; `BuildAllInstallers.cmd` adds NSIS installers for every language. After the first build, subsequent runs are ~30 seconds.
- **The build script works from any clone path.** Whether you put TR4W in `C:\TR4W`, `D:\newsrc\TR4W`, or somewhere else, the script auto-detects the location.
- **New `docs/RELEASE_WORKFLOW.md`** walks through the full lifecycle: PR review → local build → smoke test → English release → all-languages release. Useful for contributors and self-builders.

---

### 4.147.15 (2026-05-21) — NY4I

#### HamScore Real-Time Scoring

- **Sent and received exchange strings posted to HamScore are now canonicalized.** Previously, both `<SentExchange>` and `<RxExchange>` in the RTC submission echoed whatever you typed in the exchange window, so an RTC grid contact you copied as "EL88 343" went to the scoreboard as "EL88 343" instead of the canonical "343 EL88". And `<SentExchange>` always showed the received exchange instead of what you actually sent. Both are now rebuilt: SentExchange comes from your contest's sent template with your real serial number; RxExchange is rebuilt from the parsed fields in the order the contest sponsor expects. Supported contests include CQ WPX (CW/SSB), CQ WW (CW/SSB), IARU, WAE CW, CQ 160 CW, ARRL DX (CW/SSB), All Asian (CW/SSB), CWT, CWOpen, ARRL Field Day, Winter Field Day, and the RTC grid contest itself. Other contests fall back to the operator-typed string (same as before — no regression). (Issue #921)
- **Same canonical exchanges are now emitted in the N1MM-style UDP ContactInfo broadcast.** If you have an external logger (DXKeeper, etc.) consuming TR4W's UDP broadcasts, it will see the same canonical SentExchange and exchange1 fields HamScore sees.
- **New TRACE-level logging of every HamScore POST.** Set `DEBUG LOG LEVEL = TRACE` in `settings/tr4w.ini` and the full XML payload (URL, username, contact bodies) is written to `tr4w.log` before each upload. Useful for diagnosing scoreboard discrepancies.

#### X-QSO

- **The "All" column on the score grid no longer counts X-QSO records.** When you marked a QSO as X-QSO, the per-band column correctly dropped to (e.g.) 13 but the "All" column still showed 14. The "All" total now matches the per-band totals.

---

### 4.147.13 (2026-05-18) — NY4I

#### Multi-Op / Networking

- **New option to skip the "Difference in logs" dialog on reconnect.** During a multi-op contest, every time a client reconnects to TR4WSERVER (server restart, network blip, laptop wake) the client's local log no longer matches the server's, so TR4W pops a "Difference in logs" modal and waits for you to click Synchronize. Most operators just always click Synchronize — the dialog is more obstacle than safeguard. Set `SERVER AUTO SYNCHRONIZE LOG ON CONNECT = TRUE` in your config to skip the dialog: TR4W will download the server log silently and show a brief status-row toast so you know it happened. Default is `FALSE` (existing behavior preserved). Safety net: if the server's contest doesn't match yours, the dialog still appears so you can catch a wrong-server connection. (Issue #912)

#### Reports

- **New File → Reports → 3830 Score report.** Generates a `<logname>_3830Score.txt` file laid out for the 3830scores.com submission form and opens it in your default text editor. The QSO table shows all 8 HF/VHF bands (160/80/40/20/15/10/6/2) with VHF/UHF bands appended when used; mode columns (CW / Ph / Dig) only appear for modes you actually worked. Mults columns adapt to the contest type — per-band columns for CQ-WW / CQ-160, per-mode summary for FQP / NAQP, single total for CQ-WPX. The header (Call Used / Operators / Class / Power) is filled in from your Cabrillo Summary values automatically, no dialog popup. (Issue #914)
- **New Tools → Edit Cabrillo Summary… menu item.** You can now edit your Cabrillo Summary (Operators, Category Operator, Category Power, etc.) any time — previously the only chances were when you created the contest or the next time you generated a Cabrillo file (Ctrl+Alt+B). Useful before running the new 3830 Score report, since the 3830 header reads from these same values.

#### New Contest / Open Config Dialog

- **CATEGORY-OPERATOR and CATEGORY-TRANSMITTER labels are no longer cut off** in the New Contest / Open Config dialog. They previously rendered as `ATEGORY-OPERATOR` (missing C) and `EGORY-TRANSMITTER` (missing CAT). The labels now fit cleanly. The contest folder list on the left is 30 px narrower but still fits typical contest folder names. (Issue #915)

#### ADIF Export

- **`<CONTEST_ID>` is now present in exported ADIF files for all contests.** A regression introduced when ADIF export was refactored into its own module had dropped the `CONTEST_ID` field entirely from 156 of TR4W's contests, including every CQ-WW, CQ-WPX, and ARRL-DX flavor. ADIF exports now correctly include `CQ-WW-CW`, `CQ-WPX-SSB`, `ARRL-DX-CW`, etc. as the contest ID. Re-export an affected log after upgrading to get the field included.

---

### 4.147.12 (2026-05-16) — NY4I

#### Multi-Op / Networking

- **Losing connection to the multi-op server no longer pops a modal dialog mid-contest.** Previously, if the TR4WSERVER connection dropped (server restart, network blip, etc.), TR4W would show a "Connection to TR4WSERVER lost." MessageBox that blocked the call window, exchange window, and every other input until you clicked OK. Now you get a transient status-row toast and the Network window title bar changes to "** DISCONNECTED from LOCALHOST:1061" — logging keeps working uninterrupted. The program auto-reconnects every ~5 seconds in the background and the title returns to "Connected to ..." once the server is back. (Issue #910)

---

### 4.147.11 (2026-05-16) — NY4I

#### Bandmap

- **The bandmap no longer blanks at startup when a second radio is configured.** If you had a second Icom (e.g. an IC-7760) configured but not in two-radio mode, the bandmap would briefly show your spots and then go blank — the second radio's first polling cycle was overwriting the bandmap with an uninitialized band. The bandmap now stays on your active radio and ignores the second radio entirely unless TWO RADIO MODE = TRUE. (Issue #908)
- **In two-radio (SO2R) mode, the bandmap still follows the S&P radio when you tune it** — that intentional behavior is preserved. Only the unintended single-radio side-effect was removed.

---

### 4.147.10 (2026-05-15) — NY4I

#### Icom Network Radios (IC-7610, IC-7760, IC-9700, etc.)

- **Power off your Icom and you'll see the magenta "radio lost" indicator within about 3 seconds** instead of 15. (Issue #907)
- **The magenta indicator no longer flickers off-and-on during reconnect attempts.** If the radio is unreachable, the indicator stays magenta until the radio is actually back up.
- **Recovery on radio power-up now works.** Previously, if the radio was off when TR4W first tried to connect, the program would sit silently forever — turning the radio on did nothing. Now the program retries the handshake every ~9 seconds while the radio is down, and reconnects within seconds once it comes back online.

---

### 4.147.09 (2026-05-14) — NY4I / N4AF

#### HamScore RTC Realtime Scoring

- **TR4W now uploads contacts to hamscore.com in near-realtime** during a contest. Every 2 minutes the program posts new QSOs, edited QSOs, and deleted QSOs to hamscore.com so the live scoreboard reflects your log within minutes. To enable: set HAMSCORE ENABLE = TRUE and HAMSCORE PASSWORD = (your hamscore password) in the configuration. The program logs in with your callsign as the username automatically. (Issue #783)
- **Tools menu → HamScore: Resync log from scratch** wipes the server's copy of your log and re-uploads every QSO. Use this if you started a contest with test QSOs to clear, recreated a lost log, or want to make sure the server is in sync with what's on your screen.
- **Windows menu → HamScore RTC Status** opens a status window showing the URL being posted to, your effective username, the queue depth, and the last cycle's outcome (CFM, server error, etc). A Push Now button triggers an immediate post instead of waiting for the next 2-minute cycle. The window is fully resizable; long server error messages wrap and can be selected/copied for support purposes. The window stays open across restarts if you had it open when you exited.

#### Settings Window (Ctrl+J)

- **Passwords are masked by default.** All password-typed config statements (HAMSCORE PASSWORD, RADIO ONE/TWO NETWORK PASSWORD, SERVER PASSWORD) now show as `********` in the Settings list instead of in the clear. Tick the new "Show passwords" checkbox at the bottom of the dialog to reveal them. The checkbox state resets to off every time you open Settings.
- **Editing a masked password is also masked.** Double-clicking a password field shows asterisks in the edit dialog with `*` characters appearing as you type. If you click OK without changing anything, the real password is preserved. Tick "Show passwords" first if you need to see what's there before editing.
- Note: passwords are still stored as plaintext in tr4w.ini on disk — the masking is a UI-layer hide. Encryption at rest is planned for a future release.

---

### 4.147.08 (2026-05-14) — NY4I / N4AF

#### New Radio Support

- **Kenwood TS-890S — native control over both serial and LAN.** Previously TR4W could only talk to a TS-890 through HamLib. Now select TS-890 from the radio dropdown for either serial CAT (default 4800 baud, raise it in your radio's menu if you want faster) or direct TCP/IP. For LAN control, set the IP address, port (defaults to 60000), and your Admin ID + Password from the radio's LAN menu in the new NETWORK USERNAME / NETWORK PASSWORD fields. RIT/XIT, CW keying, CW speed sync, memory keyer (PB1..PB6), filter slots A/B/C, and split all work natively. (Issue #436)

#### Configuration

- **NETWORK USERNAME / NETWORK PASSWORD** replace the older Icom-specific ICOM NETWORK USERNAME / PASSWORD config statements. The old names continue to work — your existing tr4w.ini files don't need any changes. When you save changes through the radio config dialog, the .ini is automatically migrated to the new names. (Issue #904)

#### Radio Type Dropdown

- **TS890, IC905, and IC7300MK2 now appear alphabetically.** Previously these were at the very bottom of the radio dropdown (below HAMLIB-ANY) so operators couldn't find them. They now sit alphabetically with the rest of the Kenwoods and Icoms.

---

### 4.147.07 (2026-05-14) — NY4I / N4AF

#### New Contest

- **RTC — Real-Time Contest**: a 4-hour mixed-mode (CW + SSB) HF event sponsored by contestonlinescore.com. Exchange is serial number + 4-character Maidenhead grid; scoring is distance-based between grid centers with tiers of 1, 2, 3, or 4 points. TR4W prompts for your 4-character grid when you start a new RTC contest, fills your function-key messages with the rules-spec format, and disables the WARC bands automatically. Note: 160 m, 80 m, and digital modes still let you tune and log, but score 0 and don't count as multipliers per RTC rules.

#### UDP Broadcasts (N1MM-compatible)

- **WARC bands now report the correct MHz label**: prior versions sent meter-band labels (`30` / `17` / `12`) for QSOs on 30 m, 17 m, and 12 m, while every other band reported MHz (`14`, `21`, `28`, etc.). Spotting and scoring tools (N1MM, DXLog, COS) that key off the MHz value were silently dropping every WARC QSO. WARC bands now correctly report `10`, `18`, `24`.
- **X-QSO tag is well-formed XML**: the `<IsClaimedQso>` UDP field's closing tag was case-mismatched in 4.147.06, which strict XML consumers reject. The tag is now correctly closed.

#### Cabrillo / ADIF Export

- **No more garbage characters after short grids**: when your `MY GRID` was 4 characters (e.g. `EL88`), the Cabrillo file and the ADIF `<MyGrid>` field could include random non-printable characters after the grid (uninitialized memory leaking into the output). Affects RTC and any other contest using a 4-character grid. Now correctly terminated; re-export an affected log after upgrading to clean it up.

---

### 4.147.06 (2026-05-13) — NY4I / N4AF

#### Logging — X-QSO Support

- **Mark a QSO as X-QSO**: an X-QSO record stays in your log for NIL-protection purposes (so the other station gets credit if their log is checked against yours) but contributes nothing to YOUR score — no QSO count, no multipliers, no points, no presence in the dupe sheet.
- **How to use**: open the QSO in the edit dialog, tick the X-QSO checkbox after the S&P checkbox. The row is grayed out in the log view so you can see at a glance which contacts are excluded.
- **What it does to exports**:
  - **Cabrillo**: emits `X-QSO:` instead of `QSO:` for that record (per Cabrillo spec).
  - **ADIF**: tags the record so other software knows it's not claimed. TR4W's ADIF import also recognizes the equivalent fields from N1MM+ and DXLog.net, so X-QSO survives round-trips between loggers.
- **Toggle off and rescore** restores the QSO's points based on the normal contest rules.
- **All 11 languages supported**.

#### Log View

- **Column auto-fit on double-click survives restart**: when you double-click the right edge of a column header in the editable log to auto-fit, TR4W now adds a small padding so the content stays fully visible across restarts. Previously, columns auto-fit just barely wide enough would lose a character or two on restart (e.g. `14046.00` becoming `14046...`).
- Manual drag is unchanged — whatever width you drag to is what gets saved.

#### WSJT-X / FT8

- **Cleaner debug log for no-multiplier contests**: ARRL Digital, CQ WPX Digital, and similar QSO-count-only contests no longer generate misleading "Checking if grid X is a multiplier" log lines in `tr4w.log`. No functional change; only the spurious log noise is gone.

---

### 4.147.05 (2026-05-12) — NY4I / N4AF

#### Radio Control

- **K4 over network — connection no longer drops during idle periods**: K4 radios in remote/host mode drops a client that sends nothing for 10 seconds. TR4W's K4 network mode used to sit silent during operator idle periods and would silently lose the connection. TR4W now sends a `PING;` once per second over the network connection to keep it alive. Serial mode is unchanged.

#### ADIF Import/Export

- **Field Day, Sweepstakes, and similar no-RST contests no longer get a bogus `59` in `<SRX_STRING>`**: an earlier fix to add implied RST to state QSO party exchanges was incorrectly applied to contests whose exchanges have no RST. Field Day export was emitting `<SRX_STRING:9>59 1D WCF` with a bogus leading `59`. Each contest now picks the right shape — RST contests still get the implied `599`, non-RST contests get just the exchange.
- **No more `<SRX:5>000-1` garbage in ADIF**: for contests where the received-serial field is unused (e.g. Field Day), the ADIF export was emitting `<SRX:5>000-1` — a malformed numeric field. Export now correctly skips SRX (and symmetrically STX) when no serial was received.

---

### 4.147.04 (2026-05-12) — NY4I / N4AF

#### ADIF Import/Export

- **CQ zone now imported correctly**: importing an ADIF that contained a `<CQZ>` field used to silently drop the CQ zone on every QSO. The CQ zone is now read correctly on import — fixes silent data loss for CQ WW and similar zone-based contests when round-tripping through ADIF.
- **Records without a mode are no longer marked as CW**: importing an ADIF whose records did not include a `<MODE>` field used to silently set every such record to CW. Those records are now imported with no mode set, so incomplete records show up as incomplete and can be reviewed and corrected rather than being misclassified.

---

### 4.147.02 (2026-05-10) — NY4I / N4AF

#### State QSO Party Rover Operations

- **Rover calls (e.g. `KG1S/MON`)**: when a rover sends their call with a `/county` suffix, TR4W now preserves the full callsign in the log and Cabrillo. The county is automatically pre-filled into the exchange when you press Enter so you don't have to retype it.
- **Country lookup**: rover calls like `AF4O/MON` are no longer mislabeled as Great Britain (the `/M` was being read as a GB prefix). This is fixed for entry, import, and rescore.
- **County-line QSOs**: when you log a county-line station (e.g. `PIN/HIL`), the second county is no longer flagged as a duplicate and no longer scores zero points. Both records also share the single transmitted serial number, matching CQ Magazine guidance for the California QSO Party.

#### ADIF Import/Export

- **ADIF STATE field**: for state QSO parties, the STATE field now correctly reports the contest's host state (e.g. `FL` for FQP) when the QTHString is a county code instead of incorrectly emitting the county as the state. Supported for CA, FL, MI, MN, MO, NC, OH, TX, WI, TN, CO, PA, IN.
- **ADIF CNTY field**: state-and-county is now emitted as `<state>,<long-name>` (e.g. `CA,Alameda`) when the long county name is available in the dom file. Currently emitted for CA, MO, OH, PA, WI, IL, TX, MI. FL and TN ship `_cty.dom` files without long names, so CNTY is skipped for those states.
- **Rover call round-trip**: ADIF export records the bare call (`KG1S`) in the standard `<CALL>` field plus the full rover form (`KG1S/MON`) in a TR4W-specific `<APP_TR4W_ROVERCALL>` field. ADIF import recognizes that field and restores the full call.
- **SRX_STRING consistency**: the received-exchange field now always includes the implied RST (e.g. `599 HIL`) regardless of whether you typed it, so it matches the sent-exchange field in CW contests where 599 is implied.
- **Import for state QPs**: importing an ADIF now correctly repopulates county multipliers — verified with California QSO Party and Florida QSO Party.

#### Multi-County / Multi-Park Entry

- **One Enter, N QSOs**: a single Enter press logs one QSO per ref for multi-county and multi-park exchanges.
- **Per-QSO exchange string**: each follow-up record in a multi-county or multi-park entry carries its own SRX_STRING with only its own ref, not the combined operator input.

#### WinKeyer

- **WK3 hardware**: the WinKeyer status field at the bottom of the screen now shows `WK3` for K1EL WinKeyer3 hardware (previously showed `WK2`).
- **COM port error message**: when the COM port for your WinKeyer can't be opened, the error dialog now shows a readable Windows error message instead of garbage characters.

#### Multi-Op / Networking

- **Operator visible in network window**: the network window now shows the active operator's name for each connected station.
- **Score posting over HTTPS**: TR4W can now post scores to score-tracking sites that require HTTPS (Issue #26).
- **Cleaner connect-retry log**: repeated connection retry messages are now logged once per state change instead of once per retry, making the log easier to read when a remote is briefly unavailable.

#### Programmable Messages

- **Double-click to insert at cursor**: in the message editor, double-clicking a command in the command list now inserts the command at the cursor position rather than replacing the whole field.

#### New Contest Setup

- **Clean overwrite**: creating a new contest with the same name as an existing one now removes the old log file as part of the overwrite, so stale records don't bleed into the new log.

---

## 4.146.x — April 2026

### 4.146.14 (2026-04-17) — NY4I

#### POTA Support

- POTA exchanges are now fully free-form — you can type a state, ARRL section, operator name, or any combination and TR4W will figure it out. Exchanges that previously couldn't be saved will now log correctly.
- TR4W now correctly identifies park references (e.g. US-1234 or K-0001), so RST values and other non-park text are no longer mistaken for park numbers.
- Operator name recognition now uses a database of about 1,300 known ham names, giving much more reliable name detection than before.
- Grid squares typed in a POTA exchange are now recognized correctly.

#### POTA ADIF Import/Export

- ADIF export now writes the standard POTA_REF field (in addition to SIG/SIG_INFO), improving compatibility with POTA upload tools and other logging software.
- ADIF import now reads POTA_REF, SIG/SIG_INFO, and several other POTA-related fields from files generated by N1MM+ and other loggers.
- Each QSO is now assigned a unique identifier in the ADIF, which helps with duplicate checking when importing logs from multiple sources.

---

### 4.146.13 (2026-04-17) — NY4I

#### Radio Control

- Added native support for the **Yaesu FTX-1F** transceiver, including C4FM voice modes.

#### Usability

- If you try to open a log file that was saved by a newer version of TR4W, you'll now get a clear error message explaining the situation, rather than a confusing offer to downgrade the log.

---

### 4.146.12 (2026-04-16) — NY4I

#### Log Format

- Each QSO now has a unique ID stored in the log. This improves duplicate detection when editing QSOs in networked or multi-op setups, and makes ADIF exports more compatible with tools like LOTW and Club Log.
- When editing a QSO in a networked session, the corrected QSO is now properly broadcast to other stations on the network.

#### Windows Compatibility

- TR4W now correctly identifies Windows 11 versions (including 24H2/25H2) in its debug log, which helps when reporting problems.

#### Network Logging

- Debug log now shows the server address and thread activity when connecting in multi-op mode, making it easier to diagnose connection issues.

---

### 4.146.11 (2026-04-14) — NY4I

#### CTY.DAT Auto-Update

- TR4W now checks for a newer version of the country data file (CTY.DAT) in the background when it starts up, and shows a hint if an update is available.
- Press **Alt+O** to download and install the latest CTY.DAT without restarting the program.
- You can disable the startup check by adding `CTY UPDATE CHECK ON STARTUP = FALSE` to your config file.

---

### 4.146.10 (2026-04-14) — NY4I

#### Bug Fixes

- Fixed a band map display bug where double-clicking a spot with "QSY Inactive Radio" enabled could show a garbled or combined callsign (e.g. DF9II appearing as DF9IIA3CNO). The callsign buffer is now properly cleared before loading the new call.
- Added detailed CW trace logging to help diagnose an intermittent extra space appearing in sent CW messages. (If you've been seeing this, enable trace logging and send the log to the developers.)

---

### 4.146.7 / 4.146.8 (2026-04-13) — NY4I

#### Band Map Improvements

- Eliminated the flickering/flashing that occurred in the band map when spots arrived rapidly or when tuning the VFO. The band map now redraws smoothly.
- Deleting a spot now removes it from the band map immediately, instead of leaving it visible until the next spot arrival.

#### Radio Control

- **Elecraft K4:** VFO frequency now updates at the configured poll rate (default 10 ms) instead of once per second — the display is now as responsive as the K3.
- **Elecraft K3/K4:** TR4W now shuts down the radio polling thread quickly on exit, instead of waiting up to 3 seconds.
- **Icom IC-7760 (and similar):** VFO B mode/frequency commands now use the correct extended command, matching the behavior of serial-connected radios.
- **DX Cluster:** Fixed a false "split" detection that was triggered by spot comments containing the word "up" as part of another word (e.g. "Pup Emma"). Split detection is now more precise.

---

### 4.146.6 (2026-04-12) — NY4I

#### UI Improvements

- Fixed the QTH/exchange column in the log view being too narrow at startup — columns now auto-size to fit the data, not just the column header.
- Column widths you manually adjust are now remembered across sessions.

#### HamLib / Radio Control

- Improved the HamLib polling cycle to match the approach used by WSJT-X: fewer commands are sent in the fast heartbeat, which prevents menu interference on Icom IC-7610 and IC-7760.
- RIT/XIT on/off state is now read accurately — TR4W no longer shows RIT as active when the IC-7610 has a stored offset but RIT is actually off.
- Added a `HAMLIB TRACE = TRUE` config option that redirects HamLib's internal debug output to `hamlib_trace.log` — useful for diagnosing rig control issues.
- The CAT setup dialog now warns you if you select HamLib for a radio that has native TR4W support, noting the RIT/XIT limitation.
- Added native **Elecraft KX3** support (Kenwood protocol, 38400 baud).

---

### 4.146.5 (2026-04-11) — NY4I

#### POTA — Full Feature Set

- Park names are now automatically fetched from the POTA API and displayed alongside the park reference as you log QSOs.
- Park references are normalized to standard format (e.g. K-1234) before saving and ADIF export.
- **Multi-park (2fer/3fer/Nfer) support:** enter multiple park references in one exchange and TR4W automatically logs a separate QSO for each park. The status display now correctly shows "3fer", "4fer", etc. based on the actual number of parks.
- **Ctrl+T (Repeat Parks):** new shortcut pre-fills the exchange with your last-logged park references, so a second operator can work the same activation without re-typing anything.
- The POTA menu is now hidden entirely when you're not in a POTA contest (no more grayed-out POTA items cluttering other contests).
- Fixed the QTH field incorrectly showing an RST value.
- Fixed exchange acceptance issues in certain conditions.

#### Radio Control

- Fixed SO2R RIT Up/Down commands — they now correctly go to the active radio instead of always going to Radio 1.
- Fixed FlexRadio RIT getting stuck after the first bump.

---

### 4.146.4 (2026-04-09) — NY4I

#### Bug Fixes

- Fixed **Ctrl+End** not reliably moving the cursor to the band map on the second press. You can now use Ctrl+End consistently to jump to the band map.
- Added default CW memories for POTA: F1 sends a CQ POTA call, F2 sends a full CQ message, and a default QSL message is included.

---

### 4.146.3 (2026-04-08) — N4AF

#### New Contests / Contest Updates

- **Michigan QSO Party:** the District of Columbia (DC) is now a valid multiplier for Michigan stations, effective for the April 2026 event.

#### Bug Fix

- Fixed a YCCC SO2R box issue where CW speed change commands were incorrectly being sent to the SO2R box.

---

### 4.146.2 (2026-04-07) — NY4I

#### YCCC SO2R Box

- Rewrote the serial communication with the YCCC SO2R box so commands no longer block the UI. Commands are now sent on a background thread.
- Added OTRSP support for independent RX antenna control: you can now control RX1/RX2/stereo switching via OTRSP function key commands.

---

### 4.146.1 (2026-04-06) — NY4I

#### FlexRadio 6000 / SmartSDR Improvements

- Fixed the split indicator not clearing when SmartSDR closes a slice.
- Fixed VFO B showing VFO A's frequency when split is disabled.
- Fixed VFO B frequency not being preserved when toggling split on and off.
- The frequency display and radio name now turn an alert color (red by default) when the radio is disconnected or when SmartSDR is running but no receive slice exists. The alert color is configurable via `ALERT COLOR` in your config file.
- Fixed the minus key leaving a stray dash in the call window after toggling split.
- Fixed the split warning in the status display appearing/disappearing at the wrong times.

---

## 4.145.x — March 2026

### 4.145.5 (2026-03-22) — NY4I

#### Icom Network Radio Control

- Fixed both VFOs displaying the wrong mode (showing DATA when plain USB/LSB was set) on the IC-7760 and similar radios.
- Fixed the inactive VFO always being queried as VFO B — now TR4W correctly determines which VFO is active and queries the right one.
- Added the IC-7600, IC-7610, IC-7760, and IC-7850 to the list of radios that support independent Main/Sub band selection queries. IC-7300, IC-705, IC-7100, IC-905 use standard VFO A/B queries only.

#### Bug Fix

- Fixed a blocking startup warning dialog that appeared for users who had old, now-removed HamLib config parameters left in their config file. These old settings are now silently ignored.

---

### 4.145.4 (2026-03-21) — NY4I

#### Icom Network Radio Control

- Fixed the frequency and mode display staying blank after connecting to an Icom radio over the network. Frequency and mode are now queried immediately on connection.
- The frequency display is now blanked when the radio disconnects, so you no longer see stale data.

#### HamLib

- Removed the old rigctld-based HamLib option. All HamLib radio control now goes through the direct DLL interface introduced in the January–February 2026 update, which is faster and more reliable.
- Removed four obsolete config parameters related to the old rigctld path.

---

### 4.145.3 (2026-03-19) — NY4I

#### Icom Network Radio Control

- Outbound CI-V commands are now sent through a queued thread with a minimum delay between commands. This prevents TR4W from flooding the radio's input buffer when polling and user actions overlap — eliminating dropped commands and garbled responses.
- PTT and CW-stop commands are prioritized in the queue so they always go out first.
- TR4W now detects when the network link to an Icom radio has gone silent (no ping for 15 seconds) and automatically disconnects and reconnects. This catches WiFi/network dropouts that UDP connections can't otherwise detect.
- Fixed the CW stop command sent over CI-V network — the wrong value was being sent.

#### Contest Support

- **GridFields contests:** multiplier tracking now correctly recognizes any grid in the same field as already worked, while still storing the full 4-character grid for Cabrillo export.

#### WSJT-X Integration

- When TR4W has no radio connected, it now uses the band and frequency from the WSJT-X ADIF record for logging, instead of leaving it blank. Falls back to the radio frequency only when WSJT-X omits it.
- Missouri QSO Party multi-mode flag fixed.

---

### 4.145.2 (2026-03-16) — NY4I

#### Icom Network Radio Control (Ethernet / WiFi)

This is a major new feature: full native CI-V over Ethernet/WiFi for Icom radios, replacing the previous HamLib/rigctld approach. TR4W now speaks the Icom Remote Utility protocol directly, giving you faster and more reliable rig control without needing any third-party software.

**Supported radios:** IC-705, IC-7100, IC-7300, IC-7300 MK2, IC-7600, IC-7610, IC-7760, IC-7850, IC-905, IC-9700

- Full authentication and session management with the radio.
- Automatic reconnection if the network link drops.
- Frequency, mode, TX, RIT/XIT, and split state are all tracked and displayed correctly.
- CW keying over the network, including speed control (6–48 WPM).
- SO2R supported with separate instances for Radio 1 and Radio 2.
- Alert shown immediately if authentication fails (wrong password, etc.).

**Bug fixes in this release:**
- IC-705: Band Up no longer incorrectly tries to step to 4 meters (not supported on IC-705) — it now steps directly from 6m to 2m.
- Fixed data-mode display flickering caused by polling overwriting the DIGI sub-mode state.
- Fixed the HamLib checkbox being hidden in the CAT dialog when Icom TCP/IP is selected.

---

### 4.145.1 (2026-03-04) — N4AF / NY4I

#### New Contests

- **Colorado QSO Party** — full rules and scoring added.
- **Indiana QSO Party (INQP)** — added.

#### Bug Fix

- Fixed a startup crash on clean Windows installs caused by a missing HamLib runtime file. The correct DLL is now included in the installer.

---

## Radio Factory & Icom Support — January–February 2026

This was a major development period (primarily NY4I) that laid the groundwork for the Icom network support above and made radio control significantly more robust overall.

**What changed for users:**

- **HamLib Direct:** TR4W now links directly to the HamLib DLL (updated to version 4.7.0), giving you access to 200+ radio models without needing to run the rigctld daemon separately. Just select your radio model in the CAT dialog and TR4W handles the rest.
- **Automatic reconnection:** If your radio or network logger disconnects, TR4W now automatically tries to reconnect with exponential backoff (starting at 1 second, up to 30 seconds maximum). You no longer need to restart TR4W after a radio power cycle.
- **Elecraft K4 serial support** uses the same modern code path as the network connection.
- **External logger support (DXKeeper, ACLog, HRD):** the same automatic reconnection logic now applies to external loggers.
- **HamLib updated from 4.6.5 to 4.7.0.**

---

## 4.141.x — January–October 2025

### Contest Online Scoreboard (COSB)

- Fixed COSB integration — TR4W now correctly reads the local `tr4w.ini` configuration for online scoreboard posting.
- Online scoreboard support added.

### Bug Fixes

- Fixed the RadioInfo UDP message so external programs (dashboards, network monitors) receive the correct entry window handle.
- Fixed a spacing issue in sent callsigns — at least one space now always follows your callsign in formatted output.
- Radio polling improvements.

---

## 4.140.x — December 2024

### New Contests

- **9A DX** contest support added.

### Radio Control

- Added native **IC-7760** support (based on IC-7610).
- Fixed CW speed tracking for Kenwood and Elecraft radios.

### Contest Updates

- **Winter Field Day:** changed digital mode logging from DI to DG in Cabrillo export, matching the WFD organizers' updated parser.

---

## 4.139.x — November 2024

### Bug Fixes

- Removed the automatic zone fill from callsign lookup via CTY.DAT (was causing incorrect zone entries in some exchanges).
- Fixed QSY not properly clearing the callsign and exchange windows.
- Fixed a manually entered frequency not clearing after a QSY.

---

## 4.138.x — October–November 2024

### New Contests

- **WAG IE** added.

### Data Updates

- Updated TRMASTER and CTY.DAT data files.

### Bug Fixes

- Several fixes for reported issues.

---

## 4.137.x — August 2024

- **Arizona QSO Party:** updated Cabrillo contest name.
- Updated Indy10 networking library used for SCP file uploads.

---

## 4.136.x — June–August 2024

### New Contests

- **LABRE-DX** contest support added.
- **LABRE** contest support added.
- **Arizona QSO Party** rules updated.

---

## 4.135.x — April–May 2024

### Bug Fixes

- Fixed ADIF export incorrectly setting the SUBMODE field in cases where it doesn't apply.
- Fixed QSO party DX multiplier handling for the Florida QSO Party (FQP) and others.
- Fixed a Cabrillo score posting bug affecting QSO parties.
- Various other reported fixes.

---

## 4.133.x — April 2024

### Bug Fixes

- Fixed the SO2R dual display.

---

## 4.132.x — March–April 2024

### POTA

- Added support for **two-letter POTA park code prefixes** (e.g. US-, VE-, DL-), previously only one-letter prefixes were accepted.

### Bug Fixes

- Fixed multiplier fields that were incorrectly set to zero in contest scoring.
- Fixed "Reset Radio Ports" for networked K4 connections.

---

## 4.131.x — January–March 2024

### New Features

- **Delete QSO over UDP:** TR4W now sends a proper delete notification when you remove a QSO, and a delete-then-re-add when you edit one — keeping external loggers and network partners in sync.
- **External logger selection:** you can now choose your external logger (DXKeeper, ACLog, HRD) from a menu. DXKeeper is fully working; others are in progress.

### Contest Updates

- **DARC-10M** and **OKOM** contest rule updates.

### Bug Fixes

- Fixed ADIF export missing the "my exchange" field.
- Fixed the online scoreboard and UDP score posting.
- Fixed UDP port binding conflict with JTAlert (the UDP port was bound even when WSJT-X integration was turned off).
- Fixed VFO bump up/down for FlexRadio (Flex doesn't support the standard UP/DN commands).
- Fixed UDP contact port — a copy-paste error was overwriting the contact port with the lookup port.
- Fixed FOC Marathon import of FOC number.
- Fixed various N1MM log import issues.

---

## 4.130.x — January 2024

- Band map: stopped dupe checking after a match is found (performance improvement for large spot lists).

---

## 4.129.x — December 2023

- Fixed **9ADX** contest multipliers being set incorrectly.
- Added Croatian DOM file to the installer.

---

## 4.127.x — September–October 2023

### New Contests

- **Pennsylvania QSO Party** rules added.

### Bug Fixes

- Fixed a UDP band reporting issue.
- Various other reported fixes.

---

## 4.126.x — August–September 2023

### Bug Fixes

- Fixed the Icom CI-V address missing from rigctld parameters (was preventing rigctld from connecting to Icom radios).
- Fixed a hesitation when calling a spotted station.
- Various spot display and band map fixes.

---

## 4.125.x — August 2023

### HamLib Support (Major New Feature)

TR4W gained initial HamLib support in this release. HamLib is the same radio control library used by WSJT-X and dozens of other ham radio programs, giving TR4W automatic support for a huge range of transceivers.

- HamLib radio selection added to the CAT dialog, with five new config parameters.
- rigctld launches minimized and closes automatically when TR4W exits.
- Added Ctrl+J help entries for HamLib configuration.

### New Contests

- **YO-DX-HF** contest support added.

### Bug Fixes

- Fixed Alt+M on Yaesu radios.
- Fixed Yaesu serial CW keying.

---

## 4.124.x — July 2023

### Bug Fixes

- Fixed WSJT-X contacts being logged with the wrong mode (showing Data/RTTY instead of FT8/FT4).
- Added an OPERATOR field to the QSO edit dialog (all language versions).
- Fixed a format error in the exchange window change handler.
- The TCP server for WSJT-X radio control can now be turned off in settings.
- Fixed NAQP-RTTY import not setting the STATE field correctly.
- Improved N1MM log import for various contest types.
- Network parameter send safeguards: TR4W won't accidentally overwrite a remote station's configuration.

---

## 4.123.x — May 2023

### POTA Support

- Fixed ADIF file generation for POTA activations.
- Allowed a blank exchange for POTA (uses default RST when no park reference is given).

### Bug Fix

- Restored missing TCP/IP options in the Czech-language radio dialog.

---

## 4.122.x — March 2023

- Added Kenwood and Yaesu radio commands for mode and frequency control.
- Fixed the ESC key to properly stop a playing CW or voice message.
- Fixed Winter Field Day log import and network sync commands.

---

## 4.121.x — January 2023

- Fixed a critical bug where the log file was not closed properly after a UDP command, causing subsequent QSOs not to be saved.

---

## 4.120.x — December 2022

- Added Mexico class M and section MX for contests with Mexican domestic exchanges.
- Fixed Winter Field Day ADIF file naming.
- Fixed grid square detection in certain exchange types.

---

## 4.114.x — August 2022

- Bug fix release.

---

## 4.111.x — May–June 2022

### Improvements

- **Separate UDP ports** for app, contact, radio, and score data — makes integration with Node-RED, dashboards, and external loggers much more flexible.
- Added grid locator to the Cabrillo header.
- Fixed random data appearing in Cabrillo exchange fields.
- Fixed ADIF grid square parsing.
- Added a confirmation dialog after Cabrillo upload (or on error), so you know whether the upload succeeded.
- Updated CTY.DAT and TRMASTER data files.

---

## Earlier History (2014–2022)

TR4W was first committed to GitHub on April 25, 2014 at version 4.30.3 by Howard Hoyt (N4AF). Over the following eight years, N4AF continuously expanded the application with new contests, radio support, and bug fixes. Tom Schaefer (NY4I) joined as a major contributor, bringing significant improvements to radio control, UDP/network integration, WSJT-X support, POTA, external logger connectivity, and code reliability. By 2022, TR4W had grown from a straightforward contest logger into a full-featured application supporting dozens of contests, CW/SSB/digital modes, HamLib, multiple radio protocols, online scoreboards, and POTA activations.

---

## Pre-GitHub History (2009–2012) — UA4WLI

> The following release history predates the GitHub repository. It was recorded by
> Dmitriy Gulyaev (UA4WLI), the original author of TR4W, in a history file bundled with the application.
> Versions span 4.162 through 4.247, covering September 2009 through December 2012.

This era established the foundation of TR4W as a Windows application. UA4WLI developed a rich set of features during these years, including:

- **Contest support** for dozens of events: ARRL Sweepstakes, ARRL RTTY, CQ WPX RTTY, NAQP RTTY, WAE DX, DARC-10M, LZ DX, Black Sea Cup, CW Ops, CWOPEN, YO-DX-HF, NA Sprint RTTY, and many others.
- **Radio control** for a wide range of transceivers: Icom IC-705, IC-781, IC-7200, IC-7410, IC-910H, IC-9700 (predecessor models); Yaesu FT-450, FT-857, FT-897, FT-1000MP, FTDX3000; Elecraft K3; Ten-Tec Orion; and more.
- **Winkeyer** support for CW keying, including speed control, PTT, and all major WK2 commands.
- **Band map and DX cluster**: telnet cluster, skimmer spot support, colored spots (new mult = red, dupe = gray), and a band map popup for tuning the inactive radio.
- **ADIF import/export** with support for many standard fields.
- **EDI format export.**
- **Cabrillo export** for all supported contests.
- **Auto-CQ** in both CW and phone modes.
- **SO2R** with a dual dupe sheet window.
- **Network/multi-op** logging with serial number lockout and operator login.
- **DVK (Digital Voice Keyer)** support.
- **MP3 recording** of audio.
- **PC time synchronization.**
- **Rotator control** via the call window (type a bearing and press Ctrl+P).
- Many UI improvements including custom window colors, grid locator prompting, and S&P counter display.

Key individual releases in this period include version 4.195 (February 2010), which introduced Elecraft K3 support and moved Winkeyer settings into the config file; version 4.229 (August 2010), which added "Possible Calls" lookup using TRMASTER.DTA; version 4.231 (December 2010), which added rotator control and ARRL-10 multipliers; and version 4.245 (May 2012), which renamed the DVP function to DVK and added IC-7410 support.

---

*This changelog was generated from the Git commit history of the [TR4W/TR4W](https://github.com/TR4W/TR4W) repository. Repository: [github.com/TR4W/TR4W](https://github.com/TR4W/TR4W)*
