# TR4W Change Log

**This is a developer-level document with far more technical detail than is needed for most users of TR4W.** While you are welcome to read it for the internals of how it all works, if you are just interested in the changes that may affect how you use TR4W, the RELEASE NOTES may be of more value to you. You can find those [here](/RELEASE_NOTES.md).

> TRLOG 4 Windows — Free Amateur Radio Contest Logging Application  
> Repository: [github.com/TR4W/TR4W](https://github.com/TR4W/TR4W)  
> Generated: 2026-03-19

## Contributors

| Call | GitHub | Commits |
|--------|--------|---------|
| NY4I — Tom Schaefer | [@ny4i](https://github.com/ny4i) | 732 |
| N4AF — Howie Hoyt | [@n4af](https://github.com/n4af) | 346 |
| GM0GAV — Gavin Taylor | [@gm0gav](https://github.com/gm0gav) | 12 |
| K0TI — Dan | [@Dan-K0TI](https://github.com/Dan-K0TI) | 10 |
| Vojtěch Šádek | [@vksadek](https://github.com/vksadek) | 1 |
| Dmitriy Gulyaev UA4WLI | | (Original Author of Win32 Port / Pre-GitHub)|
| N6TR - Tree | [@n6tr](https://github.com/n6tr) | (Original TRLOG (DOS) Author) |

Various contributors along the way

---

## Unreleased

<!--
In-arrears versioning: new developer-facing entries accumulate here as commits/PRs
land; the version number is assigned later, when a release is cut. To cut a release:
rename this "## Unreleased" to "### X.X.X (YYYY-MM-DD) — HANDLE", move it under the
appropriate "## 4.147.x" month group below, and bump tr4w/src/Version.pas to match.
-->

### Window position restore is monitor-aware (`src/MainUnit.pas`) — Issue #739 (PR #1058, #1059)

- **Saved window positions are validated against the current monitor layout at startup.** New `EnsureRectOnScreen` tests each restored rect (`MonitorFromRect` + `GetMonitorInfo`, imported from `user32` since Delphi 7's `Windows` unit doesn't surface the multi-monitor API) against the nearest monitor's work area. A window saved on a monitor that's no longer present (laptop undocked, external display removed, resolution lowered) is clamped back on-screen, cascaded so several recovered windows fan out rather than stack.
- **Non-destructive to the saved layout.** A relocated window's original rect is remembered (`RelocState`); `FindAndSaveRectOfAllWindows` writes the original back on exit if the user didn't move it — so reconnecting the display restores the layout. A rescued window the user moves adopts its new position.
- **Windows on a monitor left of / above the primary now save.** The old `if temprect.Left >= 0` save guard silently dropped negative-coordinate positions; replaced with `not IsIconic(...)` so only minimized windows (the `-32000` sentinel) are skipped.
- **Diagnostics:** per-window `[SaveRect]`/`[EnsureRect]` logging with a window-name lookup — `RELOCATED` at INFO, the rest at TRACE, each gated by the matching `IsXEnabled` check.

---

## 4.148.x — June 2026

### 4.148.16 (2026-06-19) — NY4I

#### Radio Control: K3/KX3/K4 CW-by-CAT short messages (`src/trdos/LOGRADIO.PAS`, `src/uRadioPolling.pas`) — PR #1057

- **Short CW-by-CAT messages (`?`, `AGN`) now key reliably on the K3/KX3/K4 over serial.** The radio accepts a short `KY` on its own, so the failure was poll/CW contention on the shared serial port — the `pKenwood2` `IF;` poll flood could step on the `KY` write. Added a per-radio serial critical section so a poll cycle and a CW write can't overlap, plus a poll-pause while a CW-by-CAT message is keying (`CWByCAT_Sending`); both gated on `CWByCAT` so non-CWByCAT / WinKeyer radios run the unchanged path. Short K3/KX3/K4 `KY` text is padded to `maxLen` (the radio trims trailing fill under P1=space) so a short message survives the keyer-abort, and CW elements are counted on the unpadded text so `tmrCWByCAT` isn't inflated. Added a hex dump in `WriteToCATPort` for the non-Icom path so control bytes (e.g. the K3 `Chr(4)` keyer-abort) are visible in traces.

#### WinKeyer: byte-level logging moved to TRACE (`src/uWinKey.pas`) — PR #1057

- **Per-byte WinKeyer data-exchange logs no longer flood DEBUG.** `wkSendByte`, `wkSendTwoBytes`, `wkSendAdminCommand`, `wkAddCharToHostBuffer`, and `wkSendNextByteFromHostBuffer` moved to TRACE; higher-level events (`[wkSend]` byte count, the message string, PTT status) stay at DEBUG.

#### Radio Control: serial-radio liveness indicator — PR #1055

- **The main-window frequency display turns red when a serial radio stops answering CAT** (~3 s timeout), and returns to normal when polling resumes — so a silent/disconnected serial rig is visible at a glance.

#### Dev tooling: Pascal begin/end linter (`tr4w/build/Lint-PascalBeginEnd.ps1`)

- **Added a dependency-free PowerShell linter** for the project `begin`/`end` standard (flags an `if`/`for`/`while` body missing its `begin`/`end`, and inline `then begin` / `do begin`). Exit 0 clean / 1 on violations; no effect on the application.

---

### 4.148.15 (2026-06-18) — NY4I

#### CW: resend key moved to Ctrl+= (`src/trdos/LOGSUBS1.PAS`, `src/MainUnit.pas`) — PR #1054

- **The "resend last CW message" key moved from `=` to `Ctrl+=`.** `=` collided with Quick QSL Key 2; resend is now `Ctrl+=` (`WM_KEYDOWN`, `VK_OEM_PLUS`), gated to CW mode in the call/exchange windows. Added diagnostic logging around the resend path.

---

### 4.148.14 (2026-06-14) — NY4I

#### ADIF Export (`src/trdos/PostUnit.PAS`, `src/uADIF.pas`) — Issue #1050

- **Duplicate `STX_STRING` on Field Day / Winter Field Day removed**: the export tail emitted `STX_STRING` twice for FD/WFD — once from the general `GetMyExchangeForExport` path and again from an explicit `MyFDClass + ' ' + MySection` line. Both contests use `AE = ClassDomesticOrDXQTHExchange`, so the general emitter already produces the identical `"<class> <section>"`; the explicit copy was only meaningful while the general emitter returned its `'Error generating my exchange'` default (pre-#1049). Dropped the explicit emission; `ARRL_SECT` and `CLASS` retained.
- **`STATE` is now contest-dependent, not inferred from `QTHString`**: `uADIF.EmitADIFRecord` no longer emits `STATE` from a bare 2-char `QTHString` (which mislabeled section-based contests, e.g. ARRL section `EB` → `STATE=EB`). The body emits `STATE` only for single-state QSO parties via `GetStateForContest`; FD/WFD derive `STATE` from the section (`GetStateFromSection`) and emit `DXCC` (291 US / 1 VE) in the tail; POTA emits `DXCC` when the worked exchange is a US state. ARRL-section contests other than FD/WFD (Sweepstakes, ARRL-160) emit `ARRL_SECT` only (no `STATE`) pending the canonical-section fix in #1052.

---

### 4.148.13 (2026-06-14) — NY4I

#### ADIF Export (`src/trdos/PostUnit.PAS`) — Issue #1049

- **`STX_STRING` was `"Error generating my exchange"` on every exported record.** The array-based `ExportToADIF` first reads every QSO into the `records` array via `ReadLogFile`, which overwrites the global `TempRXData` each iteration — so the loop leaves `TempRXData` pointing at the *last* record read (typically a deleted QSO at end of log). `ExportADIFToString` then calls the tail emitter `EmitContestSpecificTailForExport(rec)` per record, but the legacy `GetMyExchangeForExport` and its `GoodLookingQSO` guard read the global `TempRXData`, not `rec`. `GoodLookingQSO` therefore saw `ceQSO_Deleted = True` for every record, the `case ActiveExchange` was skipped, and `Result` stayed at its `'Error generating my exchange'` default. The same staleness would have made serial-number contests reuse the last QSO's sent serial. Fixed by assigning `TempRXData := rec` at the top of `EmitContestSpecificTailForExport`, restoring the "`TempRXData` is the current record" invariant the legacy helpers rely on. Deeper fix (passing `rec` into `GetMyExchangeForExport`) deferred to the Delphi-12 Cabrillo/exchange-formatter capstone.

#### Documentation (`docs/WHATS_NEW_4.148.md`, `RELEASE_NOTES.md`)

- **By-feature "What's New" view.** Added `docs/WHATS_NEW_4.148.md` — a consolidated view of the 4.148.x user-facing notes re-grouped by function (Radio Control, CW, Band Map, …), bullets copied verbatim from `RELEASE_NOTES.md`. Generated by a new local `monthly-changes` skill (lives in `.claude/`, gitignored, not tracked). Cross-linked from the 4.148.x header in `RELEASE_NOTES.md`.

---

### 4.148.12 (2026-06-14) — NY4I

#### Inline-asm removal: TF / radios / utils / server (`src/TF.pas`, `src/uStrSearch.pas`, `src/utils/utils_math.pas`, `src/utils/networkmessageutils.pas`, `src/uIntercom.pas`, `src/uCallsigns.pas`, `src/uCFG.pas`, `src/trdos/LOGRADIO.PAS`, `src/MainUnit.pas`, `src/tr4wserverUnit.pas`) — Issue #997 (PR #1045)

- **Continued the inline-asm sweep beyond PostUnit.** Extracted TF's PChar search/upcase helpers into a dependency-light `uStrSearch` (`StrPos`/`StrComp` → `SysUtils`; the `?`-wildcard `StrPosPartial` and ASCII `strU` as pure Pascal) with 38 golden tests; `utils_math` `Tan`/`ArcTan2` → `Math`; `networkmessageutils` `SwapEndian32/16` and the `LOGRADIO` Yaesu BCD byte-swap → portable bit ops; `uIntercom` `wsprintf` → `TF.Format`; `uCFG` untyped-`Pointer` AdditionalProc call → typed call; the memory-mapped-log pointer arithmetic in `MainUnit`/`tr4wserverUnit` → explicit `Pointer(Cardinal(MapBase)+offset)`; removed the last live `asm nop`. `TF.ValExt`/`_Pow10` (RTL-internal float parse) flagged for the mirror clone. `docs/PHASE_INVENTORIES.md` Phase-3 table status-marked.

#### Cabrillo: fail loudly on an unhandled exchange (`src/uCabrilloExchange.pas`, `test/unit/uTestCabrilloExchange.pas`) — Issue #1043 (PR #1045)

- **`FormatCabrilloExchange` no longer writes a blank exchange silently.** Any `ActiveExchange` not in the `case` now logs (Log4D) and writes an `ERROR EXCHANGE NOT HANDLED` marker into both columns (returns `False`). Golden test added (`UnknownExchange`).

#### Contest defs: ARRL VHF exchange (`src/VC.pas`) — (PR #1045)

- **ARRL January/June/September VHF set to `RSTandorGridExchange`** so the Cabrillo exchange carries RST + grid.

#### CW enable/disable state desync (`src/trdos/LogCfg.pas`, `src/trdos/LOGWIND.PAS`) — (PR #1047)

- **`CW ENABLE` and the runtime CW gate are now kept in step.** Config wrote only `CWEnable`, while the transmit gate/toggle used `CWEnabled` and the speed display OR'd the two — so `CW ENABLE = FALSE` showed "WPM" yet sent nothing until two Alt-K toggles. `ReadInConfigFile` now mirrors `CWEnabled := CWEnable` after each config read; `DisplayCodeSpeed` reads the real gate.

#### Editable-log window: last row clipped (`src/MainUnit.pas`) — (PR #1046)

- **`CheckEditableWindowHeight` shrink-then-grow sizing.** The old shrink-only loop left the last loaded row clipped; it now grows to the smallest height where all `LinesInEditableLog` rows are fully visible (clean bottom border at every row count).

#### CW keyed in digital mode (`src/trdos/LogSend.pas`) — Issue #1040 (PR #1046)

- **`SendCrypticCWString` keys CW only for a real CW send (`ActiveMode = CW` and `CWEnabled`) or an MMTTY/RTTY send (`DigitalModeEnable = True`).** A digital mode with `DIGITAL MODE ENABLE = FALSE` (e.g. FT8/WSJT-X) no longer keys CW on DE/exchange/function keys.

#### Network connect-retry log spam (`src/uNet.pas`, `src/TF.pas`) — Issue #1041 (PR #1046)

- **Fixed the `nclsTrying`/`nclsFailed` ping-pong** that re-logged both lines every 5 s; the try/fail pair now logs once, then goes silent until the state changes. `tCreateThread` gained an optional `Quiet` flag; thread create/destroy log symmetrically.

#### Band map double-click vs AUTO S&P (`src/trdos/LOGRADIO.PAS`, `src/uRadioPolling.pas`) — Issue #1048 / #795 (PR #1048)

- **A bandmap-commanded QSY no longer trips the #795 "tune the VFO → clear the entry" logic.** `SetRadioFreq` records the commanded VFO-A freq (`tCommandedQSYFreq`); the auto-S&P clear fires only when the radio lands far from it (a genuine manual dial turn). Latent since #795; only bit with `AUTO S&P ENABLE = TRUE`.

#### Build & docs — Issue #1031

- **`utils/TagIt.ps1` validates the committed `Version.pas` the tag will capture** (dirty / unpushed / `HEAD ≠ origin/master` guards). Added `docs/FORK_PROCESS.md` (Delphi-7 → TR4W-2026 mirror-clone runbook).

---

### 4.148.11 (2026-06-12) — NY4I

#### Radio factory: network port + discoverability (`src/uRadioFactory.pas`, `src/uCAT.pas`, `src/trdos/LOGRADIO.PAS`) — Issue #1028 (PR #1030)

- **`uRadioFactory` is now the single source of truth for is-network-radio, default network port, and discoverability** (`ModelForInterfacedType`, `DefaultNetworkPort`, `IsNetworkModel`, `IsDiscoverable`; added `rmKenwoodTS990` reusing the TS-890 class). `uCAT` delegates port/discovery decisions to it; `ApplyDefaultNetworkPort` now replaces a stale different-model default (fixes IC-7760 :50001 → K4 :9200). `LOGRADIO.MapRadioModelToFactory` delegates to the factory.

#### Search & Pounce F1 caption (`src/trdos/CFGDEF.PAS`, `tr4w.dpr`) — Issue #1012

- **The S&P F1 ("send call") caption is recomputed after config load** (it was computed once in `SetConfigurationDefaultValues`, before config), so it shows "Call" instead of "DE+Call" when `DE ENABLE = FALSE`.

#### CW: replay the last-sent message (`src/trdos/LogCW.pas`, `src/trdos/LOGSUBS1.PAS`)

- **Capture the actually-sent (expanded) CW characters; `=` in the call window replays exactly what was last sent** (so post-log `@`/`#` macros don't re-expand to blanks).

#### QuickDisplay: clear stale exchange-error text (`src/MainUnit.pas`) — Issue #1030

- **A failed exchange validation (e.g. `TC_IMPROPERARRLFIELDDAYCLASS`) no longer keeps flashing after the QSO is corrected and logged.** `TryLogContact`'s successful-log path now calls `ClearQuickDisplayText`.

---

### 4.148.10 (2026-06-12) — NY4I

#### Cabrillo log writer: full inline-asm removal (`src/trdos/PostUnit.PAS`) — Issue #998 (PRs #1013–#1025)

- **PostUnit.PAS taken from ~170 inline x86 `asm` blocks to zero.** The dominant idiom (manual cdecl `wsprintf` varargs push + `asm add esp,N` cleanup) and the custom `Format(CABRILLO_*)` external-`wsprintfA` overloads were replaced with standard `SysUtils.Format`; the PChar exchange buffers (`CABRILLO_FIRST_PART`, `CABRILLO_BUFFER`, `CABRILLO_MYEX`/`CABRILLO_HISEX`) became Delphi strings. Done in 10 output-diff-validated sub-batches (report/export routines → Cabrillo header/assembly → all ~33 `case ActiveExchange` arms → QTC block → buffer→string cleanup). 64-bit / Delphi-12 prerequisite.
- **Two latent bugs fixed.** (a) *EDI export negative serial* — C `%03d` counts the sign in the field width (`-1`→`-01`) whereas Delphi `%.3d` pads digits (`-1`→`-001`); reproduced C semantics with `%.*d` + precision `3-Ord(v<0)`. (b) *CSV export out-of-guard write* — the per-QSO `sWriteFile` sat outside the `GoodLookingQSO` guard, re-emitting the stale buffer for skipped/deleted/non-QSO records; moved inside the guard.
- Removed a benign 8-byte stack over-pop in the EDI per-QSO block.

#### Capstone: testable exchange formatter (`src/uCabrilloExchange.pas`, `test/unit/uTestCabrilloExchange.pas`, `tr4w.dpr`) — Issue #998 (PR #1027)

- **Extracted the ~415-line `case ActiveExchange of` (MY-EXCH/HIS-EXCH column builder) out of `tGenerateLogPortionOfCabrilloFile`** into a dependency-light `uCabrilloExchange.FormatCabrilloExchange` (`VC` + `SysUtils` only), taking a `ContestExchange` + `TMyStationExchange` record + the derived RST/QTH strings + `var pnr`. PostUnit builds the record and calls it.
- **39 golden-line unit tests** pin every exchange arm + branch (894 tests total). Replaces per-contest manual Cabrillo diffing with the test harness.
- Added `uCabrilloExchange` + `uCabrilloFormat` to `tr4w.dpr` (IDE Project Manager + Find-in-Files coverage).

#### Inline-asm removal: small units (`src/uDistance.pas`, `uSpots.pas`, `uLogSearch.pas`, `uNewContest.pas`, `uEditQSO.pas`, `src/trdos/LOGWIND.PAS`) — Issue #997 (PR #1026)

- **Converted the clean `wsprintf`-push idiom to `Format` in 6 units** (every real asm block in each). `LOGWIND.DisplayTotalScore`'s `push eax` had relied on `Score := TotalScore` leaving the value in EAX — a fragile Delphi-7 codegen assumption 64-bit would break.

#### CW: single enable/disable state owner (`src/trdos/LogCW.pas`) — Issue #380 (PR #1000)

- **Routed `scENABLECW` / `scDISABLECW` / `ToggleCW` through one `SetCWState` owner** of both the `CWEnable` / `CWEnabled` flags.

#### Function keys: right-click to edit (`src/uFunctionKeys.pas`, `tr4w.dpr`) — Issues #1001, #1007 (PRs #1005, #1008)

- **Right-click a function key to edit that key's message** via a context menu (mode-aware CQ vs S&P). (#1001)
- **Ignore the function-key right-click while Alt or Ctrl is held** (avoids the spurious menu/flash). (#1007)

#### Send-from-keyboard dialog (`src/uSendKeyboard.pas`, `src/MainUnit.pas`) — Issue #1006 (PR #1009)

- **Fixed the duplicate / unclosable Send Keyboard Input dialog**; added an idle-close optimization (skip `FlushCWBuffer` when CW isn't being sent).

#### Exchange parse errors: cursor positioning (`src/trdos/LOGSTUFF.PAS`, `src/MainUnit.pas`) — Issue #1010 (PR #1011)

- **On an exchange parse error, place the entry cursor after the offending token** (general pattern; FD class/section first).

#### Release: refresh TRCLUSTER.DAT (`tr4w/build/Invoke-Release.ps1`) — Issue #391 (PR #1002)

- **Monthly build downloads a fresh TRCLUSTER.DAT** from dxcluster.info and refreshes the repo copy; a fresh copy ships now.

#### Docs

- New Contest Dialog design investigation; Delphi-12 I18N (Translation Manager) migration notes.

---

### 4.148.7 (2026-06-08) — NY4I

#### Config: restore UPDATE RESTART FILE ENABLE (`src/uCFG.pas`, `src/trdos/LOGSUBS2.PAS`, `src/trdos/CFGDEF.PAS`) — Issue #950 (PR #996)

- **The command was a silent no-op in two independent layers, both fixed**: (1) the `CFGCA` entry was marked `crS: csRem` (retired tombstone), so `CheckCommand` (`uCFG.pas`) recognized it — no "invalid statement" warning — but `Exit`ed before applying it, leaving `UpdateRestartFileEnable` untouched; changed to `csOld`. (2) The per-QSO `if UpdateRestartFileEnable then Sheet.SaveRestartFile;` in `LogContact` (`LOGSUBS2.PAS`) was commented out; re-enabled. (The original live calls were lost in the 596-line accidental deletion in `43ce836`, 2020.)
- **Default restored to True**: `SetConfigurationDefaultValues` (`CFGDEF.PAS`) had `UpdateRestartFileEnable := True` commented out. The per-QSO restart-file save is now on by default; `UPDATE RESTART FILE ENABLE = FALSE` disables it. The save runs on the main thread via the single centralized `DupeAndMultSheet.SaveRestartFile`, so it cannot collide with itself and needs no write queue.
- **Documented `crS` / `CFGStatus`** above the `CFGCA` array: `csNew`/`csOld` = active (applied), `csRem` = retired (recognized but not applied + hidden from the Options dialog); flip `csRem→csOld` to re-activate.

#### Build: parallel language compile (`tr4w/FullBuild.ps1`) — PR #995

- **`-ParallelLanguages` switch**: compiles the per-language builds concurrently in isolated git worktrees instead of serially, reducing full-build wall-clock time.

#### CI: Claude review workflows (`.github/workflows/claude-code-review.yml`) — PR #993

- **Added the Claude GitHub Actions (#993), then removed the automatic on-every-PR review** (`claude-code-review.yml`) to keep it opt-in.

#### Docs: VCL-in-Win32 coexistence (`docs/VCL_WIN32_COEXISTENCE.md`) — PR #994

- **Captured the technique** for running Delphi VCL forms alongside the legacy raw-Win32 message loop (`Application.ShowMainForm := False`, `TForm.Create(nil)`, `IsDialogMessage` hook) as a reference for the Delphi 12/13 migration.

#### i18n: Spanish (`src/lang/TR4W_CONSTS_ESP.PAS`) — PR #992

- **Spanish translation refinements** to `TC_`/`RC_` constants.

---

### 4.148.6 (2026-06-08) — NY4I

#### DX Cluster: clipboard keys, I/O threading rework, crash fix (`src/uTelnet.pas`, `tr4w.dpr`, `src/MainUnit.pas`, `src/utils/utils_net.pas`, `src/VC.pas`, `src/uCFG.pas`) — Issue #23 (PR #991)

- **Ctrl-V / clipboard keys in the command field**: the global accelerator table (Ctrl-V = Execute Config File, Ctrl-C = Clear Mult Sheet) consumed the standard clipboard/edit keys before the focused field saw them. New `TelnetWantsClipboardKey` (`MainUnit`) returns True for Ctrl-C/V/X/A/Z while focus is inside the telnet window; the main message loop (`tr4w.dpr`) skips `TranslateAccelerator` for those so the keystroke reaches the combobox edit via `DispatchMessage`. Scoped to the telnet window only.
- **All blocking network I/O moved to a dedicated thread**: `TelnetThreadProc` does connect + blocking `recv` and posts `WM_TELNET_MSG` (CONNECTED/CONNECT_FAILED/DATA/CLOSED) to the window; the main thread does all UI and `ProcessTelnetString` spot/bandmap work. Replaces the old inverted model (connect on a throwaway worker that touched UI; recv on the main thread via `WSAAsyncSelect`/`WM_SOCK`). Received bytes are marshaled as heap chunks (`New`/`Dispose`, `IsMultiThread` set). Thread joined (`WaitForSingleObject`+`CloseHandle`) on teardown; `TelnetStopRequested` bails a still-connecting thread on window close. Sustained ~32 spots/sec in testing with no UI stalls.
- **Stack-overrun crash fixed**: `WM_DRAWITEM` read each list item via `LB_GETTEXT` into a 128-byte `InfoBuffer`; a long line (a ~230-char WinSock error) overran the stack and corrupted an adjacent `AnsiString`, faulting in `_LStrClr`. `InfoBuffer` enlarged to 1024 and `AddStringToTelnetConsole` caps each item via `lstrcpyn`, bounding every `LB_GETTEXT` reader (also fixes a latent overrun in `SaveTelnetWindowSpots`). Restored the `TelnetBuffer[Len] := #0` terminator the refactor dropped.
- **`GetConnection` hardening** (`utils_net.pas`): sets the socket to `INVALID_SOCKET` on every failure path (no stale/double-closed handle for the 6 callers), checks `WSAStartup`/`socket()`, and preserves the real connect error across `closesocket` via `WSASetLastError` (a failed connect previously surfaced "The operation completed successfully").
- **`TELNET DEBUG` flag + connect UX**: new `TELNET DEBUG` config command (`uCFG`, `TR4W_TELNET_DEBUG` in `VC`) gating INFO logging of RX/TX/window writes and connect/disconnect; `TelnetConnectionError` always logs the WinSock code to the error log. Immediate Connect feedback (status line + Connect grays/Disconnect enables); connect/connected/disconnected/failed messages reuse `TC_CONNECTINGTO`/`TC_CONNECTEDTO`/`TC_DISCONNECTEDFROM`/`TC_FAILEDTOCONNECTTO`; `tstTR4W` status text recolored green→black; Freeze resets per connection. ENG consts: `TC_YOURNOTCONNECTEDTOTHEINTERNET` typo + translator email.

#### Rotator control: PSTRotator, long-path turn, TRACE logging (`src/trdos/LOGSTUFF.PAS`, `src/trdos/LOGWIND.PAS`, `src/uCFG.pas`, `src/MainUnit.pas`) — Issues #732, #20, #989 (PR #990)

- **PSTRotator UDP rotator type** (#732): new `PSTRotator` value in `RotatorType`/`RotatorTypeSA` (`LOGWIND`). `RotorControl` routes `ActiveRotatorType = PSTRotator` to new `SendPSTRotorCommand`, which sends `<PST><AZIMUTH>nnn</AZIMUTH></PST>` over UDP via the shared Indy `udp` client to `PSTRotatorIPAddress`:`PSTRotatorUDPPort` (defaults 127.0.0.1:12000). N1MM broadcast and serial paths untouched. New config commands `PSTROTATOR IP ADDRESS` / `PSTROTATOR UDP PORT` (`CommandsArraySize` +2). Selecting the type is the enable; `ROTATOR TYPE = NONE` disables.
- **Alt-Ctrl-P long-path turn** (#20): Ctrl-P body extracted into `RedoPossibleCallsAndTurnRotor(longPath)` (`MainUnit`); Ctrl-P → `False` (short), new `menu_alt_ctrl_redoposscalls` (10428) → `True` ((heading + 180) mod 360). Accelerator added to all language `.res`.
- **TRACE logging of rotor commands** (#989): `logger.Trace` of the datagram/command + target in `SendPSTRotorCommand`, `SendUDPRotorCommand`, and the serial path of `RotorControl`.

#### Radio configuration dialog: real Reset, explicit Cancel (`src/uCAT.pas`) — PR #987

- **Reset is now a true form-only reset**: also clears IP ADDRESS, sets TCP PORT to 0 (in-range default; blank tripped the #968 "has no value" warning), sets KEYER RTS/DTR to OFF, and restores NAME to the per-radio default (Rig 1/Rig 2). OK stays enabled to commit the reset.
- **Close → Cancel + unapplied-change guard**: the Close button is relabeled "Cancel" at runtime via `CANCEL_WORD` (all languages, no resource edit). The title-bar X now prompts (`TC_SAVECHANGES`, Yes/No/Cancel) when the OK button is enabled (the dirty flag); Cancel/Escape discard immediately.

#### File preview: open in the default text editor (`src/MainUnit.pas`, `src/uFileView.pas`, `src/uMenu.pas`) — Issue #986 (PR #988)

- **Open previewed files in the system default `.txt` editor instead of Notepad**: new `OpenInDefaultTextEditor` resolves the executable registered for `.txt` via `AssocQueryStringA(ASSOCSTR_EXECUTABLE)` and launches it with `ShellExecute` (quoted path, `SW_SHOWNORMAL`), falling back to Notepad if no association resolves. Routes the file-preview window and the `history.txt` menu through it. Menu label `Open with &Notepad` → `Open in text &editor`.

#### CI: release job tag fetch (`.github/workflows/release.yml`) — PR #985

- **`fetch tags-only` in the release job**: the release checkout's `fetch-depth: 0` fetched every `refs/heads/*`; on the case-insensitive Windows runner, two branches differing only in case aborted the fetch and killed the release job (first hit on the v4.148.5 tag). Switched to the default shallow checkout plus an explicit `git fetch +refs/tags/*` with a large `--depth` — the notes step only needs tags + history for `git describe`, so no `refs/heads/*` are fetched and a case-only collision can't break a release again.

---

### 4.148.5 (2026-06-07) — NY4I

#### Cabrillo category compliance & dialog/export fixes (`src/VC.pas`, `src/trdos/PostUnit.PAS`, `src/uCbrSum.pas`, `src/uNewContest.pas`) — Issue #976 (PR #982)

- **Category lists brought into spec**: `CATEGORY-TRANSMITTER` `'M/S'` → `'TWO'`; `CATEGORY-MODE` adds `FM` (`cmFM`/`'FM'`); `CATEGORY-TIME` adds `8-HOURS` (`NumberTimeCategories` 3→4); `CATEGORY-OVERLAY` drops `OVER-50`, adds `YOUTH`+`YL` (`NumberOverlayCategories` 5→6); `CATEGORY-STATION` adds `DISTRIBUTED / ROVER-LIMITED / ROVER-UNLIMITED / EXPLORER` → 11 types (`NumberStationCategories` 7→11). Each array's matching `Number*Categories` constant bumped in the same edit. The `cmDIGITAL`↔`'RTTY'` string swap and the Russian `ErmakOverlayCategory` list are deliberately left untouched (audited follow-up / gated behind `ErmakSpecification`).
- **Cabrillo Summary dialog** (`uCbrSum.pas`): `CATEGORY-STATION` is now a drop-down (`ctrList: True`) populated from the corrected `StationCategory`, with a string-based saved-value restore (`GetPrivateProfileString` → `CB_SELECTSTRING`) for `ctrSave` drop-downs outside the index-based restore range. `CATEGORY-TIME` and `CATEGORY-OVERLAY` now persist (`ctrSave: True`) — they previously had no program-variable backing, so their selection was never saved. **OK now auto-closes after export** (`goto ExitAndClose` after the callback), so a successful export no longer requires clicking Cancel; standalone "Edit Cabrillo Summary" behaviour is unchanged.
- **New Contest dialog** (`uNewContest.pas`): removed the dangling `CATEGORY-OVERLAY` label (`InitialCommandsSA2[3]` → `nil`) — it had a label but no control was ever created.
- **Safety**: categories persist by string value (`GetDlgItemText` → `WritePrivateProfileString`), not array index, so reordering/removing entries does not mis-map existing `.cfg` files.

#### WSJT-X dial-frequency band follow with no radio defined (`src/trdos/LOGEDIT.PAS`, `src/uWSJTX.pas`) — Issue #978 (PR #980)

- **Follow WSJT-X band when no rig is interfaced**: in the `WSJTX_MESSAGETYPE_STATUSV` handler, when `ActiveRadioPtr.RadioModel = NoInterfacedRadio` **and** `ActiveRadioPtr.tNetObject = nil`, TR4W derives the band from the dial frequency (`GetBandMapBandModeFromFrequency`) and calls the new `GoToBand` on an actual band change. Same multi-band gate as Alt-B (`MULTIPLE BANDS` enabled or no QSOs yet); band only, mode unchanged. With any radio defined it does nothing.
- **Refactor (pure extraction)**: the Alt-B refresh sequence (dupe sheet, multipliers, band map, spot info, next-QSO-number) is extracted into `RefreshAfterBandChange`; new `GoToBand(NewBand)` jumps to a band then `DisplayBandMode(ActiveBand, ActiveMode, False)` (`UpdateRadio=False`, no rig to tune) + `RefreshAfterBandChange`. `BandDownOrUp` reuses `RefreshAfterBandChange` — Alt-B behaviour is unchanged. Runs on the WSJT-X UDP worker thread, consistent with the rest of that handler.

#### Contest rename: TESLA → HF-TESLA (`src/VC.pas`) — Issue #745 (PR #984)

- **`TESLA` contest renamed `HF-TESLA`** across `QSOPointMethodSA`, `ContestTypeSA`, and the `ContestInfo` table; populated `WA7BNM: 566`, `CABName: 'HF-TESLA'`, and `FriendlyName: 'TESLA Memorial HF CW Contest'`. Scoring (`TeslaQSOPointMethod`) and contest flags are unchanged.

#### Domestic-QTH exchange error message (`src/trdos/LOGSTUFF.PAS`)

- **Clearer rejection text**: a failed domestic-QTH lookup in `ProcessClassAndDomesticOrDXQTHExchange` now shows `'Invalid ARRL Section'` instead of the generic (and misspelled) `TC_IMPROPERDOMESITCQTH` constant. Note: this hardcodes the English string, bypassing the i18n constant — to be folded back into the localized constant set during the i18n pass.

#### Release workflow (`.github/workflows/release.yml`) — PR #979

- **Auto-generated release notes scoped to the real previous tag**: the draft-release step no longer relies on `generate_release_notes: true` (which auto-detects the baseline via semver and skips `-all` prerelease-style tags, so `v4.148.4` diffed against `v4.148.2` and re-listed shipped work). It now resolves the previous tag by git ancestry (`git describe --tags --abbrev=0 <tag>^`), calls `releases/generate-notes` with an explicit `previous_tag_name`, and feeds the result via `body_path`. Requires `fetch-depth: 0`; PowerShell 5.1-safe (curl.exe + `ConvertFrom-Json` + BOM-less writes). Full end-to-end path exercises only on the next real tag push.

---

### 4.148.4 (2026-06-06) — NY4I

#### DX cluster command field substitution (`src/uTelnet.pas`) — Issue #973 (PR #974)

- **`{TOKEN}` substitution in `cluster_commands.txt`**: cluster command lines may embed `{TOKEN}` placeholders that expand to live program values when a command is chosen from the cluster window **Commands** popup. New `ExpandClusterTokens` / `ClusterTokenValue` / `NormalizeClusterToken` form one case-insensitive brace expander used by both the send path and the hover preview. Doubled braces are literal escapes (`{{` → `{`, `}}` → `}`); an unrecognized token is left verbatim so a typo is visible. Tokens: `MY_CALL`, `MY_STATE`, `MY_SECTION`, `MY_NAME`, `MY_GRID`, `MY_ZONE`, `MY_CHECK`, `MY_PREC`, `MY_CLASS`, `MY_PARK`, `MY_POSTALCODE`, `CALL` (current call-window entry), `DATE`, `TIME`, `BAND`, `FREQ`.
- **Expansion at send time**, not menu-build time: the popup stores the raw template, so values are evaluated fresh per send. The expanded string is capped at 250 chars so `SendViaTelnetSocket`'s CRLF append cannot overflow its 256-byte `wsprintfBuffer`.
- **Hover preview**: `TrackPopupMenu` has no native tooltips, so a create-once `TTF_TRACK` tracking tooltip is driven from a new `WM_MENUSELECT` handler in `TelnetWndDlgProc`; it previews the highlighted command's expanded value, re-asserting `HWND_TOPMOST` after each activation so it draws above the top-most menu, and hides on `WM_EXITMENULOOP`.

#### WSJT-X ADIF logging (`src/uADIF.pas`, `src/uWSJTX.pas`, `tr4w/test/unit/uTestADIF.pas`) — Issues #975, #977

- **`<EOH>` regression fix** (`uADIF.pas`): the single-record lexer `ParseADIFFieldsList` terminated on the first `<EOR>` **or** `<EOH>`, so a full ADI document (WSJT-X's "Logged ADIF" UDP message is `<adif_ver><programid><EOH><call…><EOR>`) parsed only the header and dropped the record — every WSJT-X-logged QSO silently failed to log. `<EOH>` now only ends the optional header and is skipped; only `<EOR>` (or end of input) terminates a record. Restores the pre-Issue-#887 behaviour and keeps `programid` (so `FromWSJTX` is set). Regression introduced 2026-05-11 by `dd471f2` + `417eada`. Replaced `Test_EOHTreatedSameAsEOR` with `Test_EOHSkipped_HeaderThenRecord` and `Test_EOHAlone_NotARecordTerminator` (817/817 unit tests pass).
- **Computer ID / S&P flag on logged QSOs** (`uWSJTX.pas`): the `LOGGEDADIFV` handler logs `TempRXData` but set `ceComputerID` / `ceSearchAndPounce` on `ReceivedData`, so WSJT-X QSOs logged with a blank `Id` column and an unset S&P flag; both are now set on `TempRXData` (the record actually logged).
- **Operator-mismatch warning** (`uWSJTX.pas`): when a WSJT-X record's `<operator>` differs from `CurrentOperator`, a non-modal `QuickDisplayError` banner + beep flags it (the QSO still logs as-is). Runs before the `ParametersOkay` gate so it fires for every parsed record; operators are trimmed and compared case-insensitively, so a blank or whitespace-only operator (`<operator:1> `) never false-flags.

---

### 4.148.3 (2026-06-05) — NY4I

#### Single/Two Radio Mode consolidation (`src/uCFG.pas`, `src/trdos/LogCfg.pas`, `src/trdos/LOGSUBS1.PAS`, `LOGSUBS2.PAS`, `LOGSTUFF.PAS`, `LOGWIND.PAS`, `src/uBandmap.pas`, `src/trdos/JCtrl1.pas`, `JCTRL2.PAS`) — Issue #965 (PR #971)

- **`TWO RADIO MODE` is now the sole radio-mode setting** (TRUE = two-radio/SO2R, FALSE = single radio, the default); `SINGLE RADIO MODE` is retained only as a deprecated parse-alias so existing `.cfg` files still load. Removed the duplicate `SingleRadioMode` globals (declared in both `LOGSTUFF.PAS` and `LOGWIND.PAS` — two separate variables, a latent write-vs-read mismatch) and re-pointed every reader to `not TwoRadioMode`.
- **`TWO RADIO MODE` wins per config file**: a new per-file `TwoRadioModeWasSet` flag (uCFG, reset in `LogCfg.ReadInConfigFile`) makes a trailing/leftover `SINGLE RADIO MODE` line inert; because the flag resets per file, a contest `.cfg` can still override the mode set by `tr4w.ini`. Added INFO logging of the per-file decision (a `[Config] Loading <file>` banner plus an applied/ignored `[RadioMode]` line) to make a user's mode conflict diagnosable from `tr4w.log`.
- **`#` accepted as a config comment character**: `EnmuCFGFile` and `RestoreCFGPasswordCase` now skip a column-1 `#` alongside `;` `[` `_` (both passes kept in sync); a `#` in column 1 previously produced an "invalid statement in config file" error.
- **i18n**: `TC_ALTRCOMMANDDISABLED` / `TC_ALTDCOMMANDDISABLED` reworded to reference `TWO RADIO MODE = TRUE` across all 11 language const files (config keyword kept English; edited byte-safely per codepage).

#### Network Radio Discovery — Elecraft K4 & Icom (`src/uK4Discovery.pas`, `src/uIcomNetworkDiscovery.pas`, `src/uIcomNetworkTypes.pas`, `src/uCAT.pas`, `src/uRadioPolling.pas`) — Issues #853, #968 (PRs #969, #970)

- **K4 network discovery**: new `uK4Discovery.pas` broadcasts `findk4` on UDP 9100 out every local interface (per-interface `BoundIP`), parses `k4:<call>:<ip>:<serial>` replies; an inline "Discover" button in the RADIO ONE/TWO dialog (`uCAT.pas`) fills the IP from the radio found.
- **Icom network discovery**: `uIcomNetworkDiscovery.DiscoverRadios` rewritten to broadcast the "Are You There" packet out every local interface (per-NIC bind via `GStack`, `IncUsage`/`DecUsage`, IP de-dup) so an Icom on any subnet is found, not just the default route; `uIcomNetworkTypes` adds `PDiscoveredRadio`; `uCAT.DiscoverNetworkRadios` dispatches the right engine. Tested on IC-7760.
- **Per-model default TCP ports**: `DefaultNetworkPortForRadio` is keyed per model, not CAT family (K4=9200, FLEX=4992, TS890=60000, TS990=50000, Icom=50001); `ApplyDefaultNetworkPort` fills the port field only when empty/0. `uRadioPolling` skips the connect attempt (logging once) when the IP is empty or the port is 0, ending the per-second "port = 0. result = -1" log flood.
- **Config parser blank-value tolerance**: `CheckCommand` leaves the variable at its default for a blank integer value (e.g. `RADIO ONE TCP PORT=`) with a clear non-fatal notice (new `TC_PARAMETERHASNOVALUE`, all 11 languages) instead of "Invalid statement"; a non-numeric value still fails validation.
- **Discover button polish**: bitmap resource 853 (magnifier) via `BS_BITMAP`/`BM_SETIMAGE` with `?` fallback; hover tooltip (`TC_TOOLTIP_DISCOVERY`) via the `CreateToolTip` helper (fixed `TTM_ADDTOOL` to the ANSI `$0400+4` variant — `+50` rendered the ANSI PChar as CJK); three discovery dialogs now i18n + radio-type-parameterized (`TC_DISCOVER_NOT_AVAILABLE` / `_NONE_FOUND` / `_MULTI_FOUND`).

#### Contest friendly names (`src/VC.pas`, `src/trdos/PostUnit.PAS`) — PR #967

- **`TContestInfo.FriendlyName`**: new compiled-in human-friendly contest name (blank → fall back to `ContestTypeSA[ct]`); ~130 of 185 live entries filled via an offline WA7BNM cabnames join + hand-fill. Corrected 5 mis-shared WA7BNM ids (ARRL-VHF-JAN, YBDX, OK-OM SSB, BCQP, SST). `PostUnit.ContestFriendlyParens` shows it in parentheses on the summary-sheet `CONTEST:` line and the centered score-report title.
- **De-asm**: `WriteTitleBlockToSummarySheet`'s two inline-asm `wsprintf` arg-push blocks converted to plain Pascal; footer run/search counts now use the named `riQSOByOpMode[...]` fields instead of raw `[tRestartInfo+$4]` / `[+$8]` offsets.

#### Bandmap SO2R highlighting (`src/uBandmap.pas`) — Issue #960 — N4AF

- **Inactive-radio band highlight in two-radio mode**: when `TWO RADIO MODE = TRUE`, the bandmap highlights the *inactive* (S&P) radio's band and grays the run radio's band, restoring the pre-4.147 SO2R paradigm.

#### Test coverage & refactor (`src/uGridDistance.pas`, `src/uTestGridDistance.pas`, `src/uTestUtilsFile.pas`, `src/uTestADIFRegression.pas`) — PR #966

- **`uGridDistance.pas` (NEW)**: `RTCGridDistance`'s Haversine (Issue #902) extracted from trdos `LOGGRID` so it is unit-testable; `LOGGRID.RTCGridDistance` delegates (no duplicated math). New regression suites: grid-distance fixture (FN36→DM18 = 3664.72 km + symmetry/zero/short/case), `sWriteFileFromString` 255/256/257-byte round-trip (v4.147.04 overflow fix), and ADIF (CQZ import, MODE-less stays NoMode, `CONTEST_ID` fallback). 809 tests pass.

#### Build & repo hygiene (`tr4w/tr4w.dsm`, `.gitignore`, `tr4w/build/full.nsi`, docs, CI) — PR #964

- **Untrack `tr4w.dsm`**: the 9.7 MB Delphi IDE symbol file (swept into the issue-960 merge via `commit -a`) is `git rm --cached` with `*.dsm` added to `.gitignore`; `full.nsi`'s local-build `TR4WVERSION` fallback `4.148.beta` → `4.148.1` (CI passes `/DTR4WVERSION`, so installers are unaffected).
- **Repo URL update**: `n4af/TR4W` → `TR4W/TR4W` across docs, changelogs, and CI comments after the org transfer; fixed a `n4af/TR4QT` → `ny4i/TR4QT` typo.

---

### 4.148.1 (2026-06-02) — NY4I

#### Stop bundling inpout32.dll to clear AV false positive (`tr4w/build/full.nsi`, `tr4w/src/uIO.pas`, `tr4w/target/inpout32.dll`) — PR #963

- **Removed `inpout32.dll` from the installer and the repo**: its kernel port-I/O driver was the installer's only true-positive VirusTotal flag (`hacktool`/`vulndriver`, e.g. DrWeb `Tool.VulnDriver.32`) and the cause of Chrome Safe Browsing / SmartScreen download blocks on the unsigned installer. `inpout32` is used only for direct parallel-port (LPT) keying / relay / footswitch / paddle / band-output — never for serial/USB/network keying or CAT — and is loaded on demand in `uIO.DriverCreate` via `OpenLPT`, gated by `tGetPortType = ParallelInterface`, so non-LPT users never touch it. LPT users now supply `inpout32.dll` themselves (next to `tr4w.exe`).
- **`uIO` fail-safe when the DLL is absent**: `NoInpOut32Message` no longer `halt`s — it warns (with download + placement guidance) and returns, so a stale LPT port left in a config can't crash startup. `DriverCreate` attempts the load at most once (`inpout32LoadAttempted`) to avoid re-warning across the multiple `OpenLPT` calls. `GetPortByte`/`SetPortByte` are now nil-safe no-ops when the DLL is absent, protecting the LPT paths (stereo pin, band output, footswitch/paddle) that don't pre-check `DriverIsLoaded()`.

---

### 4.148.0 (2026-06-01) — NY4I

#### TS-890 LAN follow-ups: band/mode display, RIT/XIT offset, operating-VFO tracking, CW KY, VPN connect (`src/uRadioKenwoodTS890.pas`, `src/uNetRadioBase.pas`, `src/uRadioPolling.pas`, `tr4w.dpr`) — Issue #959

- **Band/mode now follow the radio**: `ParseFAOrFBResponse` derives `vfo[].band` from the reported frequency. Without it `FilteredStatus.Band` stayed `NoBand` and `ProcessFilteredStatus` skipped the `ActiveBand`/`ActiveMode`/`DisplayBandMode` update, so only the frequency tracked the radio (band-above-freq, band table, and mode did not; startup showed `NONSSB`).
- **RIT/XIT offset displayed**: new `ParseRFResponse` parses the offset from the unsolicited `RF` push (direction + 4-digit Hz) into `vfo[].RITOffset`, surfaced as `CurrentStatus.RITFreq` (on/off via `RT`/`XT` already worked).
- **Operating-VFO tracking**: new base `FActiveVFO` + `GetActiveVFO`/`SetActiveVFO` (default `nrVFOA`, default-preserving so K4/Icom/Flex/HamLib are unchanged); `pNetworkRadio`'s aggregate status and `VFOStatus` follow `GetActiveVFO` instead of a hardcoded `nrVFOA`. TS-890 drives it from `FR` (FR0=A, FR1=B), fixing the operating-relative `OM` mode mapping (A/B no longer swap per-VFO modes), the main window following the RX VFO, and the Radio 1 window active-VFO highlight.
- **CW `KY` pad-off**: split `TS890` out of the padded-Kenwood arm — variable-length `KY <space><text>;` instead of fixed 24-byte padding; corrects the 890 CW timer (it had counted the never-keyed padding). Other Kenwoods (480/570/590/950/990/2000) keep the fixed 24-byte P2.
- **VPN connect timeout**: `uNetRadioBase` `ConnectTimeout` 10 ms → 5000 ms; 10 ms only worked same-subnet and tripped "Connect timed out" on a VPN handshake (~95 ms). Runs on the reconnect thread, no UI block.
- **Project files**: added `uRadioKenwoodTS890` and `uBandLookup` to `tr4w.dpr`'s `uses`.

#### QSO Number popup typo (`src/MainUnit.pas`) — Issue #962

- **"QSO nuber" → "QSO number"**: corrected the hardcoded literal at `MainUnit.pas:3420` (Ctrl-/ → Additional Information → QSO Number popup; English literal, not a `TC_` resource).

#### Super Check Partial database refresh (`tr4w/target/TRMASTER.DTA`)

- **Regenerated `TRMASTER.DTA`** from the offline builder (SCP sources + CWops/FOC + QRZ name backfill).

#### Build & release tooling (`tr4w/build/Invoke-Release.ps1`, `utils/`, `tr4w/tools/trmaster/`)

- **`Invoke-Release.ps1` infinite-recursion fix**: the `function Git { & git … }` helper recursed into itself — PowerShell command resolution is case-insensitive and functions outrank executables, so a bare `& git` resolved back to the function → call-depth overflow that pegged a core and ballooned RSS before aborting. All call sites now invoke `git.exe`; a guard comment documents why.
- **Monthly-release wrapper + docs** (`utils/MonthlyBuild.cmd`, `docs/RELEASE_WORKFLOW.md`): `MonthlyBuild.cmd` wraps `Invoke-Release.ps1`; the workflow doc gained a TL;DR distinguishing the interim (`TagIt`) vs monthly (`MonthlyBuild`) paths.
- **`TagIt` hardening**: fast-forwards local master to origin and verifies the tag matches `Version.pas` before tagging/pushing, so an interim tag can't land on a stale pre-bump commit.
- **`utils/` reorg**: moved the build/tag helper scripts and added `BuildEnglishInstaller.cmd` under `utils/`.
- **TRMASTER builder progress** (#958): `build_trmaster.cmd` reports the QRZ name-cache size during backfill.

---

## 4.147.x — May 2026

### 4.147.25 (2026-05-31) — NY4I

#### Serial number derived from highest serial sent, not QSO count (`src/trdos/LOGEDIT.PAS`, `LOGDUPE.PAS`, `LOGWIND.PAS`, `LOGSUBS1.PAS`, `LOGSUBS2.PAS`, `LogSend.pas`, `src/MainUnit.pas`, `src/uEditQSO.pas`) — Issues #954, #949

- **Serial no longer rolls backward on X-QSO / mid-log delete** (#954): the next serial was `TotalContacts + 1`, a count of *scoring* QSOs, so marking a QSO X-QSO (or deleting a mid-log QSO) dropped the count — the next serial reverted, was re-sent on the air via the `#` macro, and was re-stamped into `NumberSent` (a duplicate serial). New per-band high-water mark `MaxSerialSent` (`LOGDUPE`) tracks the largest `NumberSent` over non-deleted records **including X-QSO** (they consumed a number); new `NextSerialToSend` / `UpdateMaxSerialSent` (`LOGEDIT`) return `max + 1`, which only ever advances (`UpdateMaxSerialSent` ignores the `$FFFF` ADIF import sentinel and non-positive values). `LoadinLog` and the live add feed the mark; the next-number display (`DisplayNextQSONumber`), the `#` macro (CW + voice), the `NumberSent` stamp, and the CQ-spot labels all moved from `TotalContacts + 1` to `NextSerialToSend`. `TotalContacts`/`QSOTotals` are untouched, so the #750 score grid, status display, every-10 beep, and `AUTO QSO NUMBER DECREMENT` (F2 repeat) are unchanged; networked mode still uses `ServerSerialNumber`.
- **X-QSO no longer deletes the contact from the external log** (#949): `uEditQSO` marks X-QSO by sending a `contactdelete` to the score feeds (UDP + HamScore) while leaving the external logger (DXKeeper) alone — the contact stays logged externally but drops out of the contest score.

#### Kenwood TS-890 LAN handshake + CR/LF transport, band/RIT/XIT/TX fixes (`src/uRadioKenwoodTS890.pas`, `src/uNetRadioBase.pas`, `src/trdos/LOGRADIO.PAS`, `src/trdos/LOGWIND.PAS`) — PR #951

- **Handshake**: the TS-890 LAN login does not send `##TI;`; the old path waited for it and hung after `##ID1;`. It now proceeds straight to authenticated (post-login `##VP;`/`##KN2;`/`##KN0;` + `AI2` init). The 5 s `PS;` keepalive is retained (the radio drops an idle LAN link after ~10 s).
- **CR/LF transport**: `TNetRadioBase.SendToRadio` appended CR/LF via `WriteLn`; the TS-890's CAT parser rejects the trailing bytes with `?;` once authenticated (the K4 tolerates them, which is why it never surfaced). New `bAddTermination` flag (default `True`; `TKenwoodTS890Radio` sets it `False` → bare `Write`), so every other radio's wire output stays byte-identical.
- **Band/mode**: `ModeTypeToNetMode` (`LOGRADIO`) had no `else`, so `Both`/`NoMode` produced an uninitialized result → intermittent `OM0D;` (USB-DATA) on band change; added `else Result := Low(TRadioMode)`. `SetRadioFreq` now guards freq ≤ 0, and `EffectiveBandFreq` (`LOGWIND`) falls back to `DefaultFreqMemory` for un-visited bands (was sending `FA00000000000;`).
- **RIT/XIT/Split/TX display**: per-radio parse handlers now call base setters `SetRITOn`/`SetXITOn`/`SetSplitOn`/`SetTransmitting` on `TNetRadioBase`, so toggles made on the radio (pushed via AI2) reach the main window.

#### Offline TRMASTER.DTA builder toolset + regenerated database (`tr4w/tools/trmaster/`, `tr4w/target/TRMASTER.DTA`) — PR #948

- **New offline toolset** (`tr4w/tools/trmaster`, Python) rebuilds the Super Check Partial database from public sources; `build_trmaster.cmd` orchestrates the seed + CWops + FOC + QRZ-name passes (a bare `trmaster_build.py` run yields 0 CWops/FOC).
- **Regenerated `TRMASTER.DTA`**: 53,281 calls.
- **QRZ name-lookup robustness**: a malformed QRZ XML response no longer aborts the whole name pass (treated as a cacheable miss); network/HTTP/timeout errors are separated from XML parse errors so only the latter are swallowed; added a progress heartbeat every 100 lookups.

#### Help INI: prune, document, and fill config-command descriptions (`tr4w/target/commands_help_eng.ini`) — PRs #952, #955

- **Prune + document** (#952): removed 90 dead `[SECTION]` blocks (nil-address, not-in-array, commented-out, unused-legacy) validated against the live CFGCA tables; kept 5 marked "PENDING RE-IMPLEMENTATION".
- **Description fills** (#955): filled 30 of the remaining 55 `TO BE COMPLETED` `DESCRIPTION`/`DEFAULT` placeholders.

#### CI: run VirusTotal scan under Windows PowerShell 5.1, not pwsh (`.github/workflows/release.yml`, `.github/scripts/Invoke-VirusTotalScan.ps1`) — PR #947

- The self-hosted `win-ci` runner (LocalSystem) only has Windows PowerShell 5.1 machine-wide; `shell: pwsh` failed with "pwsh: command not found". The VT scan step and script are now 5.1-safe (`curl.exe` upload, `ConvertFrom-Json`, BOM-less .NET writes).

#### Release tooling (`tr4w/build/Invoke-Release.ps1` — NEW)

- **New release orchestrator** (PowerShell 5.1): regenerate TRMASTER, download CTY.DAT (URL/UA/validation pulled from the app's Alt-O fetch path), bump `Version.pas`, local build, commit, and tag `v<ver>` to trigger CI. It *calls* `build_trmaster.cmd` rather than duplicating it.

---

### 4.147.24 (2026-05-29) — NY4I

#### Indy library layout cleanup (`tr4w/include/Indy`, `tr4w/tr4w.cfg`, `tr4w/tr4w.dof`, `tr4w/tr4wserver/tr4wserver.cfg`, `tr4w/tr4wserver/tr4wserver.dof`, `tr4w/BatchCompile.cmd`, `tr4w/test/CompileTest.{cmd,ps1}`, `tr4w/test/CompileRadioTester.{cmd,ps1}`, `tr4w/tr4wserver/BuildServer.ps1`, `tr4w/FullBuild.ps1`, `CLAUDE.md`) — PRs #943, #944, #945

- **Stray submodule gitlinks removed** (#943 + follow-up): three accidental gitlinks (mode `160000`) with no `.gitmodules` and target commits absent from the repo — `tr4w/include/Indy` (→ `c8220089`), `tr4w/src/rekor-cli` (→ `5ed77ae`), and `tr4w/src/root-signing` (→ `9f63f63`) — caused `actions/checkout` post-job cleanup (`git submodule foreach`) to fail with `fatal: No url found for submodule path …` (exit 128) on every tag build. The command aborts on the first offending path (`include/Indy` sorts first), so all three had to go. #943 removed `include/Indy`; the two leftover sigstore tool directories under `src/` were removed as a direct follow-up. None were referenced by the build (Indy resolves from `include\Core`, `include\System`, `include\Protocols`).
- **Stale IDE search paths fixed** (#944): `tr4w.cfg`/`.dof` and `tr4wserver.cfg`/`.dof` listed `-U/-O/-I/-R` and `SearchPath` entries under `include\Indy` (plus `\D7`, `\Lib`, and corrupt `include\Indy]\Lib\*` entries) that no longer exist. Repointed to the bundled Indy 10.6.3.3 tree at `include\Core; include\System; include\Protocols`. CI was unaffected (`FullBuild.ps1`/`BuildServer.ps1` pass correct paths via `/U /I`, overriding the `.cfg`), but Delphi-IDE builds read these files. The `.dof` `[HistoryLists]` MRU entries were intentionally left untouched.
- **Dev/test scripts depend on bundled Indy** (#945): `BatchCompile.cmd`, `test/CompileTest.{cmd,ps1}`, and `test/CompileRadioTester.{cmd,ps1}` hardcoded an external `C:\Indy\Lib\*` install; repointed to `C:\tr4w\tr4w\include\*`. `BuildServer.ps1`'s `$IndyRoot` default changed from `C:\Indy\Indy\Lib` to the bundled `…\tr4w\include` (derived from `$ProjectRoot`), matching `FullBuild.ps1` and the script's own header comment, so standalone server builds no longer need an external Indy. A stale `C:\Indy\Indy\Lib` path in a `FullBuild.ps1` comment was corrected.
- **Verified**: Delphi 7 IDE build of `tr4w.dpr` against the corrected paths compiles and links.

#### ESP VERSIONINFO LANGID (`tr4w/FullBuild.ps1`) — Issue #941, PR #946

- **ESP added to the VERSIONINFO `$langMap`**: `LangId = 0x0C0A` (Spanish — Spain, International/Modern sort, es-ES), `CodePage = 1252`. The 2026-05-28 ESP backfill added ESP to the build matrix (`$otherLangs`) but not the VERSIONINFO table, so per-language ESP builds printed `No VERSIONINFO LANGID mapping for 'ESP' -- defaulting to ENG` and tagged the exe's embedded version info as English (`0x0409`). Cosmetic metadata only — the UI was already Spanish via `-DLANG_ESP` + the ESP `.res`. Stale param-doc comment updated to list ESP.

---

### 4.147.23 (2026-05-29) — NY4I

#### CI: entire release pipeline on the self-hosted runner (`.github/workflows/release.yml`, `.github/scripts/Invoke-VirusTotalScan.ps1` (NEW), `.github/workflows/version-guard.yml` (NEW), `tr4w/FullBuild.ps1`) — PR #942

- **Whole pipeline self-hosted**: the `virustotal-scan` and `release` jobs (previously `ubuntu-latest`) now run on the `[self-hosted, win-ci]` runner alongside `build`. GitHub-hosted runners can't host Delphi 7, and keeping all jobs on one machine removes the cross-OS artifact hand-off. `release.yml` trimmed ~259 lines.
- **VT scan extracted** to `.github/scripts/Invoke-VirusTotalScan.ps1` (curl-based upload + poll), now shared by CI and the local `FullBuild.ps1` pre-flight — single source of truth.
- **New `version-guard.yml`**: a "Verify Version.pas is present and parseable" check on pushes/PRs, so a malformed or missing `TR4W_CURRENTVERSION_NUMBER` can't reach a release tag.

---

### 4.147.22 (2026-05-29) — NY4I / N4AF

#### Spanish (ESP) + cross-language CFG portability (`tr4w/src/lang/TR4W_CONSTS_ESP.PAS`, `tr4w/target/commands_help_esp.ini` (NEW), `tr4w/src/VC.pas`, `tr4w/src/uCFG.pas`, `tr4w/src/MainUnit.pas`) — Issues #925, #937, #938, PR #939

- **ESP enabled end to end**: filled `TR4W_CONSTS_ESP.PAS` and added the full `commands_help_esp.ini`, putting Spanish on par with the other shipped languages.
- **`ColumnCanonicalName` (`VC.pas`)**: language-neutral column names (`BAND`/`DATE`/`UTC`/…) for persisting `COLUMN WIDTH` settings in CFG files. CFGs were previously language-locked — one saved by an English build failed to load in a Spanish/Russian/etc. build because `ColumnsArray[].Text` is translated at compile time. The canonical names match the historical English values so existing CFGs keep parsing.
- **Missing language constants filled** across `tr4w_consts_*.pas` (issue #925), using per-codepage byte-level edits to preserve each file's ANSI encoding and CRLF endings.

---

### 4.147.21 (2026-05-29) — NY4I

#### HamScore RTC 3.0 (`src/uHamScore.pas`, `src/uCabrillo.pas` (NEW), `src/uGetScores.pas`, `src/VC.pas`, `src/uCFG.pas`, `src/uExchangeBuilder.pas`, `src/trdos/LOGSUBS2.PAS`, `test/hamscore_mock.py`) — Issues #920, #930, #931, #932, PR #935

- **RTC 3.0 protocol** (#920): payload wrapped in `<rtc>...</rtc>` with `<dynamicresults>` as a child; `<contactinfo>` blocks use the 3.0 schema (`<ID>` + `<CabrilloString>` + `<timestamp>`). `ExtractDescription` parses the new `Description` JSON field for CFM-with-warning and Error responses. Default `HamScoreURL` set to `http://scoredistributor.net/`.
- **`dynamicresults` payload completion** (#930): added `<ops>`, `<club>`, `<qth>` blocks (state/section/grid4/grid6/country/continent/zone), assisted/overlay category fields, and `<soft>` / `<version>` split. `ReadCabrilloSummaryField` pulls missing values from `tr4w.ini` `[REPORT]` so no new CFG entries needed for Club/Section/State. `cqzone` always uses `ctyGetCQZone(MyCall)` (`MyZone` global is contest-zone-mode dependent and unsafe here). New `MyITUZone` global + `MY ITU ZONE` CFG, because large countries span multiple ITU zones.
- **Per-contest gating** (#931): new `HAMSCORE SEND CONTACT INFO` CFG (Boolean) and `RTC_CAPABLE_BIT = 8` flag in `ContestsBooleanArray` (bumped from `Byte` to `Word` for bit 8). `ContactInfoUploadAllowed` gates uploads on both. 12 contests marked RTC-capable.
- **SST ADIF/CAB names** (#932): SST entry now `ADIFName:'K1USN-SST'; CABName:'K1USNSST'`.
- **`uCabrillo.pas` (NEW)**: single source of truth for single-QSO Cabrillo line rendering (`BuildSingleQsoCabrilloLine`). Eliminates the prior split between `PostUnit`'s final-log writer and `uExchangeBuilder`'s score-XML fallback that caused "edit didn't reach HamScore" bugs.
- **`uExchangeBuilder.pas`**: SST/NAQP family arm added so exchange edits flow to HamScore (previously fell through to raw `ExchString`).
- **`trdos/LOGSUBS2.PAS`**: `DeleteLastContact` (ALT-Y handler) now calls `HamScoreOnDelete`/`HamScoreOnLog` on the delete/restore branches — was silently skipping the hook.
- **`test/hamscore_mock.py`**: `--description` CLI flag for the 3.0 Description field; pretty-printer + highlights updated; checks for `<rtc>` wrapper presence; banner reminds operator to set `HAMSCORE SEND CONTACT INFO = TRUE`.

#### Build & Release Pipeline (`tr4w/FullBuild.ps1`, `.github/workflows/release.yml`, `tr4w/include/`)

- **UPX opt-in** (`-UseUpx` switch, default off): UPX compression removed from the default build. Prior VirusTotal scans flagged the SER installer with 8 detections (including Microsoft Defender); a no-UPX rebuild dropped this to 3. Trade-off: ~2.4 MB larger installer / ~1 MB larger on-disk EXE, in exchange for fewer AV false positives and one less third-party supply-chain dependency. CI does not pass `-UseUpx`; build locally with `-UseUpx` to restore.
- **VERSIONINFO PE resource** (`-DVERSIONINFO_RES`): per-language `tr4w_<LANG>.exe` now embeds a Win32 VERSIONINFO block (FileVersion / ProductVersion / language code) generated from `Version.pas` at build time. Right-click → Properties → Details shows language + version.
- **Indy bundled by default**: `FullBuild.ps1` defaults `IndyRoot` to in-repo `tr4w/include` (Indy 10.6.3.3) instead of requiring an external `C:\Indy` install. `INDY_ROOT` env var still honored.
- **NSIS pre-flight check**: verifies all required NSIS source files exist before installer build; clearer error than failing mid-package.
- **`release.yml` english-only path**: routed through `FullBuild.ps1 -BuildInstallers` instead of an ad-hoc inline build, so CI and local share one code path.
- **Post-build zip step removed**: NSIS installer is the only release artifact; the redundant `.zip` was unused downstream.
- **VT scan local skip**: when running in CI, the local pre-flight VirusTotal check now emits a single terse skip line.

#### Documentation (`docs/UPDATING_RUNTIME_DLLS.md`)

- **New `UPDATING_RUNTIME_DLLS.md`**: process for refreshing the bundled HamLib, OpenSSL, `inpout32.dll`, and `rigctld.exe` binaries.

---

### 4.147.19 (2026-05-26) — NY4I / N4AF

#### CI release-build workflow (`.github/workflows/release.yml`, `tr4w/FullBuild.ps1`, `tr4w/build/full.nsi`, `docs/RELEASE_WORKFLOW.md`) — PRs #923, #926, #927

- **New `.github/workflows/release.yml`**: self-hosted Windows runner builds on tag push (`v4.*.*`) or manual `workflow_dispatch`. Three-job pipeline: `build` → `virustotal-scan` (Ubuntu) → `release` (Ubuntu, tag-push only). Validates the tag matches `Version.pas` (strips trailing `-all`), verifies Delphi 7 / Indy / NSIS / UPX present, runs `FullBuild.ps1`, uploads installer artifact, scans via VirusTotal API v3 with `VT_MALICIOUS_THRESHOLD = 8`, creates a draft GitHub Release with installer + `virustotal-report.md` attached.
- **Tag suffix `-all`** (e.g. `v4.147.19-all`) and the `workflow_dispatch` `all_languages` checkbox switch to `FullBuild.ps1 -AllLanguages -BuildInstallers`, producing 8 installers (ENG + RUS/SER/MNG/CZE/ROM/GER/UKR).
- **`FullBuild.ps1` parameterized**: `-ProjectRoot`, `-Delphi7Bin`, `-IndyRoot`, `-NSISBin`, `-UpxBin`, `-AllLanguages`, `-BuildInstallers`. `$ProjectRoot` auto-derives from `$PSScriptRoot` so any clone path works (default `C:\TR4W` or `D:\newsrc\TR4W` -- zero config). Each toolchain param defaults via the corresponding env var.
- **Per-language DCU caching** (`tr4w\target\dcu-cache\<lang>\`): each `-DLANG_xxx` build writes `.dcu`s into a private cache via DCC32's `/N` flag so language iterations don't trample `src\*.dcu`. Canonical ENG DCUs live in `src\` (Delphi 7 IDE-compatible). First build of a given language uses `-B` so DCC32 doesn't read ENG DCUs from `src\`; subsequent iterations are ~5-10 sec incremental.
- **Marker file `tr4w\target\.dcu-managed-by-fullbuild`** distinguishes first run (clears `src\*.dcu` to migrate from prior script versions) from steady state (incremental compile, ~30 sec).
- **`Build.cmd`, `BuildAll.cmd`, `BuildAllInstallers.cmd`** thin wrappers added at repo root for the three common modes.
- **`build/full.nsi` `TR4WVERSION` macro** drives the full version string; CI passes `/DTR4WVERSION=<version>`.
- **`docs/RELEASE_WORKFLOW.md`** new end-to-end guide; supersedes `docs/LOCAL_BUILD.md` (removed).

#### VirusTotal scanning (`.github/workflows/release.yml`, `tr4w/FullBuild.ps1`, `tr4w/build/release/.gitignore`)

- **CI VirusTotal job**: scans each `tr4w_setup_*.exe` via VT API v3, uploads `virustotal-report.md` as a workflow artifact, blocks the release job if any installer hits `VT_MALICIOUS_THRESHOLD = 8` (raised from initial 4 to absorb the ~7 heuristic false positives the unsigned NSIS+UPX+`inpout32.dll` combination consistently trips). Secret name: `VIRUS_TOTAL_API_KEY`. `workflow_dispatch` input `skip_virustotal` available for emergencies.
- **Local pre-flight scan in `FullBuild.ps1`**: when `$env:VIRUS_TOTAL_API_KEY` is set and `-BuildInstallers` produced installers, `Invoke-VirusTotalScan` uploads each via `curl.exe` (PS 5.1 `Invoke-RestMethod` lacks `-Form`), polls `/analyses/{id}` up to 10 minutes, prints CLEAN/WARN/BLOCKED verdict + permalink. Informational only -- never fails the local build.
- **Three stale `tr4w_setup_4_32.*.exe` installers** from March 2025 removed from `tr4w/build/release/`; `tr4w_setup_*.exe` added to that directory's `.gitignore`.

#### RTC HamScore canonical exchange follow-up (`src/uExchangeBuilder.pas`, `tr4w/test/hamscore_mock.py`) — PR #929

- **`BuildSentExchangeText` RTC special case**: ignores the on-air `CQExchange` template and builds the canonical SentExchange directly from `RXData.NumberSent + MyGrid` (no RST). Per HamScore RTC organizer email 2026-05, the signal report is intentionally skipped in BOTH `SentExchange` and `RxExchange`. Operators whose `CQExchange` template included `5NN`/`599` for on-air keying previously leaked RST into the upload; this commit isolates the upload path from the template.
- **`BuildRxExchangeText` RTC case** reaffirmed at `serial + ' ' + qth` (no RST), with a comment noting the canonical form is intentionally RST-less.
- **`tr4w/test/hamscore_mock.py`**: pure-stdlib Python local stand-in for HamScore RTC server. Listens on `127.0.0.1:8765`, decodes Basic auth, pretty-prints XML (wraps TR4W's multi-element bodies in a synthetic root for `xml.dom.minidom`), URL-decodes N1MM-style form-encoded bodies, inline-highlights `SentExchange`/`RxExchange`/`Call`/etc., returns `{"Status":"CFM"}` (overridable via `--response CFM|OK|ResyncLog|Error`).

#### TS-890 LAN protocol + radio bug fixes (`src/uRadioKenwood.pas`, `src/uBandmap.pas`, `src/trdos/LOGRADIO.PAS`) — PR #922

- **TS-890 LAN keepalive** every 5 seconds, wait for `##TI;` before init commands, parsing of `TB`/`FT`/`RT`/`XT` status responses. Fixes intermittent disconnects and missing band/mode updates over LAN.
- **`RadioObject.SendCW` uninitialized-locals fix**: `charProcessed` and `sendNow` were read before assignment; under Delphi 7 codegen this surfaced as silent failure to send CW via CAT on Kenwood and Elecraft radios (CW-by-CAT mode). Both initialized to `False` at function entry. Latent since CW-by-CAT was introduced.
- **`uBandmap.pas` `CurrentCursorPos` uninitialized fix**: variable was conditionally assigned then unconditionally read in the bandmap repaint path; initialized to `-1` so the no-cursor branch is taken deterministically.

#### `FullBuild.ps1` output zip step (`tr4w/FullBuild.ps1`) — PR #922

- After a successful build, `tr4w.exe` is zipped to `tr4w/target/dist/tr4w-<version>-<branch>-<timestamp>.zip` for off-site tester distribution. Branch name from `git rev-parse --abbrev-ref HEAD` (slash-safe). Disambiguates "two `tr4w.exe` attachments in the inbox" scenarios during whack-a-mole testing.

#### LANG constant derived from compiler flags (`src/VC.pas`, language constants files) — PR #924

- **`{$IFDEF LANG_RUS}` ... `{$ENDIF}`** dispatch in `src/VC.pas` derives the `LANG` const from the `-DLANG_xxx` compiler flag passed by `FullBuild.ps1` (or the IDE). Previously `LANG` was a hand-edited string constant requiring a manual swap before each per-language build; the factored form lets the same source tree compile every language from CI by varying only the compiler flag.
- **Per-language constants files**: missing translation strings restored where the Russian / Ukrainian files had commented-out or absent definitions (`TC_UPLOADEDSUCCESSFULLY`). Cyrillic strings preserved through byte-level edits to avoid CP1251 → UTF-8 round-trip corruption.
- **English-fallback strings** in non-English `*_consts_*.pas` files translated to their respective languages.

#### Submodule cleanup

- **Orphan submodule pointers** to `rekor-cli` and `root-signing` removed from the working tree. Eliminates `git status` noise on fresh clones.

#### Online-scoring spec gap analysis (issue tracker only)

- **Issue #930 opened**: catalogues gaps between TR4W's HamScore `dynamicresults` XML and the spec at <https://blog.contestonlinescore.com/online-scoring-xml-specification/>. Missing: `<ops>`, `<club>`, full `<qth>` block, `<class>` `assisted`/`overlay` attributes, per-band `<point>` totals, separate `<soft>`/`<version>` elements. Plus a Phase 3 plan to support ContestOnlineScore.com as a sibling endpoint. No code changes in this version; tracking only. Kept separate from issue #920 (RTC 3.0 protocol, effective 2026-06-01) so #930's incremental fixes can ship before the next RTC contest.

---

### 4.147.15 (2026-05-21) — NY4I

#### HamScore RTC payload TRACE log + canonical sent/rx exchanges (`src/uHamScore.pas`, `src/uExchangeBuilder.pas`, `src/trdos/LOGSUBS2.PAS`, `src/MainUnit.pas`, `tr4w.dpr`) — Issue #921 / PR #921

- **TRACE-level log of outgoing HamScore RTC POST** (URL, effective username, full XML payload) added in `THamScoreUploader.PostToServer`, guarded by `FLogger.IsTraceEnabled` so the payload is only stringified when trace logging is active.
- **New shared unit `src/uExchangeBuilder.pas`** exporting two plain-text builders (`BuildSentExchangeText`, `BuildRxExchangeText`) consumed by both the HamScore RTC POST and the N1MM-style UDP `ContactInfo` broadcast in `LOGSUBS2.PAS`. Eliminates the prior duplication where `<SentExchange>` echoed `RXData.ExchString` in both code paths.
- **`BuildSentExchangeText` rebuilds from the contest's `CQExchange` template** set in `LogCfg.pas` at contest start. Substitutes `#` → `NumberSent` and the CW shorthand `5NN` → `599` so scoring consumers see canonical numeric RST. Whitespace collapsed and trimmed. Empty template falls back to `RXData.ExchString`. Future work: per-contest "RTC exchange template" in the radio/contest factory.
- **`BuildRxExchangeText` dispatches on `RXData.ceContest`** and rebuilds from parsed `ContestExchange` fields in scoring-canonical order so the operator-typed order ("EL88 1234" vs "1234 EL88") no longer leaks into RTC/UDP submissions. Contests covered: `CQWPXCW`/`CQWPXSSB`/`DARCWAEDCCW` (`RST + serial`), `CQWWCW`/`CQWWSSB`/`IARU` (`RST + zone`), `CQ160CW` (`RST + QTHString`), `ARRLDXCW`/`ARRLDXSSB` (`RST + QTHString` US side or `RST + Power` DX side), `ALLASIANCW`/`ALLASIANSSB` (`RST + Age`), `CWOPS` / CWT (`Name + QTHString`), `CWOPEN` (`serial + Name`), `RTC` (`serial + QTHString` — no RST on air), `ARRLFIELDDAY`/`WINTERFIELDDAY` (`ceClass + QTHString`). Unknown contests fall back to `RXData.ExchString` (no regression).
- **Default RST inference**: `RSTReceivedString` returns `599` on `CW`/`Digital`, `59` on Phone/FM when `RXData.RSTReceived = 0` (operator accepted parser default).
- **`LOGSUBS2.PAS` UDP `BuildUDPContact`**: both `<SentExchange>` (previously `Trim(RxData.ExchString)`) and `<exchange1>` (previously a 2-case `ActiveExchange` switch falling back to `ExchString`) now route through the shared builders so HamScore RTC and N1MM-style UDP consumers see identical canonical strings.
- **`uHamScore.pas`** retains thin `BuildSentExchange` / `BuildRxExchange` wrappers that XML-escape the shared text helpers' output.

#### X-QSO "All" column regression in score grid (`src/MainUnit.pas`) — Issue #750 follow-up

- **`LoadinLog` was double-counting X-QSO records in `QSOTotals[AllBands, Both]`**. Every per-band/per-mode counter (`QSOTotals[Band, Mode]`, `QSOTotals[Band, Both]`, `QSOTotals[AllBands, Mode]`, `ContinentQSOCount`, `TimeSpentByBand`) was inside the `(ceQSO_Deleted = False) and (ceXQSO = False)` guard at lines 5498-5499, but the `inc(QSOTotals[AllBands, Both])` at line 5529 was outside it. Result: the score grid's "All" column counted X-QSO records while every per-band column correctly excluded them (e.g. 13 on 20m, 14 under "All" with one X-QSO). Increment moved inside the guard.

---

### 4.147.13 (2026-05-18) — NY4I

#### TR4WSERVER auto-sync log on reconnect (`src/uNet.pas`, `src/uCFG.pas`, `src/uGetServerLog.pas`, `tr4w.dpr`, `src/lang/*`) — Issue #912

- **New `SERVER AUTO SYNCHRONIZE LOG ON CONNECT` config flag** (Boolean, default `FALSE`). When `TRUE`, the "Difference in logs" modal that fires on every client reconnect during a multi-op contest is skipped and the server log is downloaded silently via the existing `RunSyncThread` worker.
- **Headless sync path**: `ProcessServerLogInfo` in `uNet.pas` dispatches to a new `HeadlessSyncMode` branch in `uGetServerLog.pas`. UI updates (status labels, progress bar, dialog close) are gated on `not HeadlessSyncMode` so the worker can run without a dialog HWND.
- **Thread-affinity fix for log replace**: `LoadinLog` touches ListView controls and must run on the thread that created them. Worker `PostMessage`s `WM_USER_HEADLESS_SYNC_REPLACE` to the main HWND; new handler in `tr4w.dpr`'s `WindowProc` invokes `LoadinLog` on the UI thread.
- **Safety gate**: auto-sync only triggers when the server's contest matches the client's (or server reports `DUMMYCONTEST`). Contest mismatch still falls through to the existing dialog so the wrong-server case warns the operator.
- **Operator feedback**: INFO log line plus transient `QuickDisplay` toast via new `TC_AUTOSYNCHRONIZINGLOG` constant, added to all 11 language files via byte-level insertion to preserve ANSI codepages + CRLF.
- **Design doc** committed as `docs/NETWORK_LOG_AUTO_SYNC.md`.

#### 3830 Score report + standalone Cabrillo Summary edit (`src/trdos/PostUnit.PAS`, `src/uCbrSum.pas`, `src/uMenu.pas`, `src/MainUnit.pas`, `src/VC.pas`) — Issue #914

- **`ExportTo3830Scores` in `PostUnit.PAS`** writes `<logname>_3830Score.txt` matching the 3830scores.com submission-form layout, then auto-previews in the default text editor. New menu entry `menu_3830scores = 10021` under File → Reports.
- **Adaptive table layout**: per-band rows always emit all 8 HF/VHF rows (160/80/40/20/15/10/6/2), with additional VHF/UHF rows appended only when non-zero. Mode columns (`CW Qs` / `Ph Qs` / `Dig Qs`) appear only for modes that have logged QSOs. `Ph` reads from `RawQSOTotals[band, Phone]`, which already folds FM via `LoadTotalCount`.
- **Mults columns adapt to contest type**: per-band Mults column appended iff `MultByBand = TRUE` (CQ-WW, CQ-160). Bottom summary emits per-mode lines (`CW Mults` / `Ph Mults` / `Dig Mults`) + total iff `MultByMode = TRUE` (FQP, NAQP); single `Mults: N` otherwise (CQ-WPX).
- **Metadata header silently reads `tr4w.ini [REPORT]` keys** (`_OPERATORS`, `_CATEGORY-OPERATOR`, `_CATEGORY-POWER`) — the same keys the Cabrillo Summary dialog writes. `Call Used` reads from `MyCall`. No dialog popup at report time.
- **New Tools → Edit Cabrillo Summary…** entry (`menu_edit_cabrillo_summary = 10022`) opens the existing Cabrillo Summary dialog standalone. Implementation reuses `OpenStationInformationWindow` with `lParam=0` so `CabrilloSummaryProc` is nil; `WM_COMMAND` case 1 in `uCbrSum.pas` handles the nil-callback branch by saving all `ctrSave=True` fields to `tr4w.ini [REPORT]` then closing (same path as ExitAndClose). Cabrillo file generation flow (`Ctrl+Alt+B`, non-nil callback → `CreateCabrilloFile`) unchanged. Surfaced because the 3830 report depends on those `[REPORT]` values and prior UI only let the operator set them at contest creation or next Cabrillo build.

#### New Contest / Open Config dialog label widths (`src/uNewContest.pas`) — Issue #915

- **CATEGORY-* labels were clipped**: `CATEGORY-OPERATOR` rendered as `ATEGORY-OPERATOR` (missing leading `C`), `CATEGORY-TRANSMITTER` as `EGORY-TRANSMITTER`. Fix: shrink left column (caption / contest listbox / Latest config button) from 280 → 250 px and reclaim 30 px for the right-side labels (`x: 300 → 270`, width `~148 → ~178` px). Right edge of label area (`x=448`) and dropdown/edit controls (`x=455`) unchanged. Listbox at 250 px still fits typical 25–30 char contest folder entries.

#### ADIF `CONTEST_ID` regression (`src/uADIF.pas`) — Issue #887 follow-up

- **`CONTEST_ID` emission was empty for 156 of TR4W's contests** (including all CQ-WW, CQ-WPX, ARRL-DX, etc.). Issue #887 extracted ADIF export from `PostUnit`/`MainUnit` into `uADIF.pas` but dropped the `ContestTypeSA[]` fallback that `LOGSUBS2.PAS:2782`, `uGetScores.pas:435`, and `uGetScores.pas:564` all still use: when `ContestsArray[ceContest].ADIFName` is empty, fall back to the parallel `ContestTypeSA[]` string (which IS the standard ADIF Contest_ID for the majors — `CQ-WPX-SSB`, `CQ-WW-CW`, `ARRL-DX-CW`, etc.). `EmitADIFField` silently suppresses empty values, so the field was missing entirely from exports. Single-line restore at `uADIF.pas:1294-1297` covers all 156 contests without per-contest data entry.

#### Build hygiene: `cty.dat` no longer re-included via gitignore negation (`.gitignore`)

- **Removed `!tr4w/target/cty.dat` negation** that re-included the file under the `tr4w/target/*` blanket ignore. `cty.dat` is rewritten by TR4W at runtime, so it always showed as modified in `git status` and `git add` was willing to stage those runtime edits. The file remains tracked in master (fresh clones still get a working country database); `git add tr4w/target/cty.dat` is now blocked, with `git add -f` as the documented escape if the master copy genuinely needs updating. Recommendation: `git update-index --skip-worktree tr4w/target/cty.dat` once per clone to silence `git status` noise.

---

### 4.147.12 (2026-05-16) — NY4I

#### TR4WSERVER disconnect UX (`src/uNet.pas`, `src/lang/*`) — Issue #910

- **Modal dialog replaced with non-blocking toast**: when the TR4WSERVER connection drops, `uNet.pas:252-260` no longer pops a `MessageBox` ("Connection to TR4WSERVER lost.") that blocked the call/exchange windows mid-contest. The notification is now a `QuickDisplay` toast in the status row. `showwarning(wsprintfBuffer)` → `QuickDisplay(wsprintfBuffer)`.
- **Network window title bar reflects state**: added `ShowConnectionStatus(TC_DISCONNECTEDFROM)` call alongside the toast so the title bar reads `Network : ** DISCONNECTED from LOCALHOST:1061` until reconnect. On reconnect, `ConnectThread` already calls `ShowConnectionStatus(TC_CONNECTEDTO)` which restores the normal title automatically.
- **Auto-reconnect was already in place** (`uNet.pas:229-246` WM_TIMER handler calls `TryConnectToNetwork` every `tNetStatusUpdateInterval` ms while `NetSocket = 0`); only the notification UX needed fixing.
- **New language constant `TC_DISCONNECTEDFROM`** added to all 11 language files (`tr4w_consts_*.pas`) via byte-level insertion to preserve original ANSI codepages and CRLF line endings. English: `'** DISCONNECTED from '`; conservative Latin-script translations for ger/pol/cze/ser/esp/rom; English fallback for rus/ukr/mng/chn (translations to follow).
- **Title-bar color limitation noted**: standard Win32 title bars cannot be colored without custom-painting the non-client area; ASCII `**` prefix + caps used as the visual cue instead. A colored status banner inside the dialog deferred as a future enhancement.

---

### 4.147.11 (2026-05-16) — NY4I

#### Bandmap inactive-radio guards (`uRadioPolling.pas`, `trdos/LOGWIND.PAS`, `uSpots.pas`) — Issue #908

- **SO2R gate at inactive-radio polling path (`uRadioPolling.pas:3138`)**: Gav-added "follow inactive radio when tuned" code was missing the `TwoRadioMode` gate that the older `LOGWIND.PAS:4933` legacy path already had. With `TWO RADIO MODE = FALSE`, an inactive radio's polling thread could still mutate `BandMapBand`/`BandMapMode`. Now gated on `TwoRadioMode`.
- **Sentinel-value guard at three sites**: `FilteredStatus.Band = NoBand` and `FilteredStatus.Mode = NoMode` are "haven't received from radio yet" sentinels. Three sites propagated them unconditionally into globals (`ActiveBand`/`ActiveMode`/`BandMapBand`/`BandMapMode`), blanking the bandmap on startup when an inactive Icom polling thread fired before its handshake completed. Guard added at `uRadioPolling.pas:3088` (active-radio polling), `uRadioPolling.pas:3138` (inactive-radio polling — confirmed culprit), and `LOGWIND.PAS:4933` (legacy LogWind path).
- **Diagnostic TRACE logging**: `[DisplayBandMap]` entry state, `[SpotsList.Display]` per-filter rejection breakdown (NextDup/Band/Mode/DupeFlag/CQ/WARC/MultsOnly/VHF) + listbox populate stats, `[ProcessFilteredStatus]` polling-thread state on each active-radio poll, `[BMWriter LOGWIND:4933 inactive-FS]` when the legacy LogWind path fires. TRACE-only — no behavior change at default log levels.

---

### 4.147.10 (2026-05-15) — NY4I

#### Icom network disconnect color, recovery, and detection speed (`uRadioIcomBase.pas`, `uNetRadioBase.pas`, `uRadioPolling.pas`, `uIcomNetworkTypes.pas`) — Issue #907

Three compounding defects in Icom network disconnect handling. Surfaced during IC-7760 testing: turn the radio off → ~15 s before magenta "radio lost" indicator appeared → ~1 s later the indicator switched back to normal color → never actually recovered when the radio was turned back on.

- **Alert color flashed back to normal during reconnect**: `TIcomRadio` did not override `GetIsOperational`, so it inherited the base default `True`. When the polling thread fired its 1-second-after-disconnect reconnect, the transport went `Disconnected → WaitingForHere`, the polling thread took the "connected" branch, and `uRadioPolling.pas:781` unconditionally cleared the alert. **Fix**: `TIcomRadio.GetIsOperational` now returns `True` only when `FNetworkTransport.State = icsConnected`; `uRadioPolling.pas:781` changed to `SetRadioAlertState(not ro.IsOperational)`.
- **No recovery from stuck handshake**: transport sends one `$0003` AYH packet on `Connect()` and sits in `WaitingForHere` forever if no `$0004` reply arrives — exactly what happens when `Connect()` fires while the radio is off. **Fix**: new stuck-handshake detector at top of `pNetworkRadio`'s connected branch — when `IsConnected = True && IsOperational = False` persists >8000 ms, force `Disconnect` so the next iteration re-fires `Connect()` with a fresh AYH. Gated on new virtual `TNetRadioBase.GetCanRecycleOnStuckHandshake` (default `False`); `TIcomRadio` overrides to `True` for network path. Flex (whose `IsOperational` tracks slice validity, not handshake state) and K4 / HamLib Direct (TCP-based) keep the default.
- **Disconnect detection took 15 seconds**: `ICOM_PING_DEAD_TIMEOUT_MS` was `15000` (150 missed 100 ms pings). **Fix**: lowered to `3000` (30 missed pings).

---

### 4.147.09 (2026-05-14) — NY4I / N4AF

#### HamScore RTC Realtime Upload (new `src/uHamScore.pas`, hooks across `LOGSUBS2.PAS`, `uEditQSO.pas`, `uCFG.pas`, `MainUnit.pas`, `tr4w.dpr`) — Issue #783

Worker-thread uploader that POSTs contest log data to hamscore.com every 2 minutes per the RTC v2.3.3-xml specification: `<dynamicresults>` plus zero or more `<contactinfo>` / `<contactreplace>` / `<contactdelete>` / `<deletelog>` containers per POST. HTTP Basic auth, callsign as username.

- **`THamScoreUploader` (TThread)**: waits on stop event + cycle event via `WaitForMultipleObjects(120000)`. Stop event terminates on shutdown; cycle event lets the UI's "Push Now" trigger an early cycle.
- **`TRTCContact`**: pre-renders the XML body on the main thread at enqueue time so the worker holds no live `ContestExchange` references.
- **Reliability per spec section 2.2**: snapshot of pending list taken under `TCriticalSection`; not-CFM responses (network error, HTTP non-2xx, server error, ResyncLog, unexpected) restore the snapshot to the head of the pending list for the next cycle. Only explicit `"Status":"CFM"` frees the contacts.
- **HTTP transport**: `TIdHTTP` + `TIdSSLIOHandlerSocketOpenSSL` (TLS 1.2). Connect 15s, read 30s.
- **Status parser**: `Pos()` lookup; recognises `CFM`/`OK`/`Error`/`ResyncLog`. No JSON dependency.
- **`<dynamicresults>` reuse**: extracted public `BuildDynamicResultsXml: AnsiString` from `uGetScores`; mirrors `MakePOSTRequestNew`'s schema but returns AnsiString without the `xml=` prefix or shared `GetScoresBuffer`. Existing 5-min scoreboard poster unchanged.
- **Hooks**: `LogContact` → `HamScoreOnLog`; `uEditQSO` → `HamScoreOnEdit` / `HamScoreOnDelete`. Cheap no-ops when uploader is nil.
- **Config**: `HAMSCORE ENABLE` (Boolean), `HAMSCORE URL` (default `https://hamscore.com/postxml/index.php`), `HAMSCORE USERNAME` (empty → MyCall), `HAMSCORE PASSWORD` (`ctPassword`).

#### HamScore Status Window (`src/uHamScore.pas` `HamScoreDlgProc`, `MainUnit.pas`, `uMenu.pas`, `VC.pas`) — Issue #783 Phase 4

- **`tw_HAMSCOREWINDOW_INDEX`** (slot 20, was `tw_Dummy10`). Menu id `menu_windows_hamscore = 10219` lines up with `OpenTR4WWindow`'s `CheckMenuItem(10199 + Ord(ID))` so the menu auto-checkmarks while open. Auto-mapper bound in `WM_COMMAND` extended from `menu_windows_dupesheet2` to `menu_windows_hamscore`.
- **Layout**: anchor-based via `HamScoreLayoutControls`. Top labels stretch full client width; status field is a multi-line read-only edit (`ES_MULTILINE | ES_READONLY | ES_AUTOVSCROLL | WS_VSCROLL`) that fills remaining space; buttons anchor bottom-left.
- **Anti-flicker resize**: suspends repainting (`WM_SETREDRAW=0`), moves all controls with `bRepaint=False`, then one `RedrawWindow(RDW_INVALIDATE | RDW_ERASE | RDW_ALLCHILDREN)`. Eliminates the ghost-text artifacts left by per-`MoveWindow` partial invalidation.
- **Min drag size**: `WM_GETMINMAXINFO` caps `ptMinTrackSize` at 410×270.
- **Diff-aware refresh**: `SetTextIfChanged` keeps the 1 Hz timer from resetting scroll position or text selection.
- **Push Now**: signals `FCycleEvent` so the worker wakes before the 2-min timer.
- **Visibility persists across restart**: `OpenOtherWindows` restore loop and `WndRect` default-init loop both extended from `tw_DUPESHEETWINDOW2_INDEX` to `tw_HAMSCOREWINDOW_INDEX`.

#### Resync Flow (`MainUnit.pas`, `src/trdos/LOGSUBS2.PAS`, `uMenu.pas`) — Issue #783 Phase 3

- New Tools-menu item `menu_hamscore_resync` (10609): enqueues `<deletelog>` via `HamScoreResyncFromScratch`, then iterates the binary log via new `SendFullLogToHamScore` (mirrors `SendFullLogToUDP`'s `OpenLogFile` / `ReadVersionBlock` / `ReadLogFile` / `GoodLookingQSO` pattern). Spec sections 1.7 + 2.4.

#### Password Masking in Settings Dialog (`src/uOption.pas`, `src/uInputQuery.pas`, `src/VC.pas`, `src/uCFG.pas`) — Issue #783

The Ctrl+J Settings listview was displaying every `ctPassword` field in the clear.

- **`ctPassword` rows mask as `'********'`** in the listview by default. Fixed length so the actual password length doesn't leak.
- **"Show passwords" checkbox** (`BS_AUTOCHECKBOX`) at x=560, y=472 — on the dialog itself, not the listview, so it stays visible regardless of scroll position. Per-session state, resets unchecked at every open.
- **`RefreshPasswordRows`** iterates the listview, finds `ctPassword` rows via `IndexArray + CFGCA[].crType`, rewrites each row's value-column text via `ListView_SetItemText`.
- **Edit dialog (double-click) honors the toggle**: when off, pre-fill is the mask AND the input edit gets `EM_SETPASSWORDCHAR(Ord('*'))` so new typing appears as `*`. OK with text equal to the mask → no change (the real password is preserved). Empty field → pre-fill empty regardless. New `tInputDialogPassword` flag in `VC.pas` joins the existing input-dialog flags.
- **After successful edit**: `ctPassword` rows refresh through `RefreshPasswordRows` so the row stays masked when the toggle is off (previously bypassed the mask via direct `ListView_SetItemText`).
- **`SERVER PASSWORD`** type fix in `uCFG.pas`: was `crType: ctString` instead of `ctPassword` — corrected so the masking applies. No other code touched the type.

---

### 4.147.08 (2026-05-14) — NY4I / N4AF

#### Generic Network Credentials (`src/uCFG.pas`, `src/uCAT.pas`, `src/trdos/LOGRADIO.PAS`) — Issue #904

The Icom-prefixed network-credential config statements rebadged because the Kenwood TS-890 (Issue #436) also needs LAN credentials.

- **Storage rename**: `Radio*.IcomNetworkUsername` / `IcomNetworkPassword` → `Radio*.NetworkUsername` / `NetworkPassword` in `LOGRADIO.PAS`. Three internal call sites in `SetUpRadioInterface` updated.
- **CFGCA**: new canonical `RADIO ONE/TWO NETWORK USERNAME/PASSWORD` statements; existing `RADIO ONE/TWO ICOM NETWORK USERNAME/PASSWORD` retained as backward-compat aliases at the same storage. `CommandsArraySize` delta bumped +4 → +8.
- **CAT dialog** (`uCAT.pas`): `UpdateIcomCredentialsVisibility` → `UpdateNetworkCredentialsVisibility`; labels "ICOM USERNAME/PASSWORD" → "NETWORK USERNAME/PASSWORD". On Save, writes the canonical name and deletes the legacy `ICOM NETWORK ...` key (`WritePrivateProfileString` with nil) so the .ini doesn't accumulate stale duplicates.

#### Kenwood TS-890 Native Control (new `src/uRadioKenwoodTS890.pas`, `src/trdos/LOGRADIO.PAS`, `src/uRadioFactory.pas`, `src/uCAT.pas`) — Issue #436

The TS-890S was previously HamLib-only. Now native serial CAT and direct TCP/IP LAN control.

- **Native serial** (`LOGRADIO.PAS`): `RadioParametersArray[TS890]` → `rt: rtKenwood`; default `BR4800`; `P:0` → `P:1` for polling. Dropped from `HamLibONLYRadios`; added to `KenwoodRadios`, `RadioSupportsCWByCAT`, `RadioSupportsCWSpeedSync`, `RadioSupportsPlayDVK`. Added to every Kenwood case statement that previously listed TS990 (~12 sites: RIT clear/bump, VFO up/down, CW send / KS / KY, memory keyer with `hiMem := 6`, AI/IF parsing in the polling code).
- **Native network** (new `TKenwoodTS890Radio` extending `TNetRadioBase`): Speaks Kenwood ASCII CAT over a TCP socket after a 3-step LAN auth handshake: `##CN;` → `##CN1;`, `##ID0<idLen:2><pwLen:2><id><pw>;` → `##ID1;`. Default port 60000.
- **Auth state machine**: `ksNone` → `ksWaitingForCN` → `ksWaitingForID` → `ksAuthenticated` (or `ksAuthFailed`). All CAT operations are no-ops until authenticated.
- **Post-auth init**: `AI2; FA; FB; OM0; OM1; KS; TB; FT; RT; XT; ID;`. `ID;` must return `ID024;` for TS-890S.
- **AI2 push** handles freq/mode updates; `requiresPolling := False`.
- **TS-890 OM mode map** per Kenwood PC Command Reference Rev 1: `1=LSB 2=USB 3=CW 4=FM 5=AM 6=FSK 7=CW-R 9=FSK-R A=PSK B=PSK-R C/D/E/F=LSB/USB/FM/AM-DATA`.
- **CW speed**: 4–60 wpm via `KSnnn;`.
- **RIT/XIT**: `RC;` clears, `RU<nnnnn>;` / `RD<nnnnn>;` sets a specific offset (silently capped at 9999). RIT and XIT share one offset.
- **Filter slots A/B/C** via `FL00/01/02`. `SetFilterHz` no-op (no Hz-based bandwidth-set CAT command picked).
- **Memory keyer** PB1..PB6.
- **`SetMode(mode, nrVFOB)` known limitation**: TS-890 OM SET ignores its P1 (VFO) byte per spec, so cross-VFO mode-set isn't possible with one command.
- **Factory wiring** (`uRadioFactory.pas`): new `rmKenwoodTS890`; `CreateRadioNetwork` case; `ModelToString`, `IsModelSupported`, `GetSupportedModels` updated. `MapRadioModelToFactory` (`LOGRADIO.PAS`) routes `TS890` → `rmKenwoodTS890`. `SetUpRadioInterface` sets credentials before `Connect`.
- **CAT dialog** shows credential fields when the operator picks TS890 + TCP/IP port.

#### Dropdown Alphabetization (`src/VC.pas`, `src/trdos/LOGRADIO.PAS`)

TS890, IC905, IC7300MK2 were each appended at the end of `InterfacedRadioType` — operators couldn't find TS890 in the Radio Type combo because it sat below the HamLib-only block. Pascal `case` matches enum members by name not ordinal, so moves don't break case statements.

- Moved `TS890` between `TS870` and `TS940` in the enum + parallel `InterfacedRadioTypeSA` and `RadioParametersArray`.
- Moved `IC905` between `IC781` and `IC910`.
- Moved `IC7300MK2` right after `IC7300`.
- **Cleanup**: removed `, IC905, IC7300MK2` tails from 12 sites that listed `IC78..IC9700, IC905, IC7300MK2` patterns. Now that the two members fall WITHIN the `IC78..IC9700` ordinal range, the explicit tails became "duplicate case label" compile errors.
- **Positive side effect**: `[IC78..IC9700, OMNI6]` patterns in `uProcessCommand.pas` and `uRadioPolling.pas` (which never had the tail) now correctly include IC905 and IC7300MK2.

#### Version.pas Build Unbreak (`src/Version.pas`)

- Closed an unterminated string literal introduced in commit `a334faa` (the "Issue #903 4.147.07" version bump): `'4.147.07+++…+++ ;` had an opening quote, a run of `+` characters, no closing quote before the semicolon. `FullBuild.ps1` failed at the unit-tests pre-gate. No version-number change.

---

### 4.147.07 (2026-05-14) — NY4I / N4AF

#### RTC Contest (`src/VC.pas`, `src/trdos/LOGGRID.PAS`, `src/trdos/LOGSTUFF.PAS`, `src/trdos/FCONTEST.PAS`, `src/uNewContest.pas`) — Issue #902, PR #903

Real-Time Contest (RTC, contestonlinescore.com) — 4-hour mixed-mode (CW + SSB) HF event. Exchange: serial number + 4-character Maidenhead grid. Distance-based scoring via Haversine between grid centers.

- **Reuse over new infrastructure**: existing `RSTQSONumberAndGridSquareExchange` handles parsing, dupes, Cabrillo, and ADIF. Only contest definition and scoring needed code.
- **`VC.pas`**: `ContestType.RTC`, `RTCQSOPointMethod`, plus `ContestsArray` / `ContestTypeSA` / `ContestsBooleanArray` / `QSOPointMethodSA` rows. `AE: RSTQSONumberAndGridSquareExchange`, `DM: GridSquares`, `AIE: GridInitialExchange`, `CABName: 'RTC'`, `WA7BNM: 782`, `ciQB1 + ciQM0 + ciMB1 + ciMM0` (per-band dupes, per-band mults, mode-agnostic).
- **`LOGGRID.PAS`**: new `RTCGridDistance` — pure Haversine between 4-char grid centers, R=6371 km. Verified against rules fixture `FN36 → DM18 = 3664.72 km` (exact). Existing `GetDistanceBetweenGrids` is Vincenty-style and `'LL'`-padded; numerically different, would push borderline QSOs into the wrong scoring tier.
- **`LOGSTUFF.PAS`**: `RTCQSOPointMethod` case in `CalculateQSOPoints`. Tiers 1/2/3/4 points at <2000 / <4000 / <8000 / ≥8000 km. Out-of-rules QSOs (bands outside 40/20/15/10 or modes other than CW/Phone) score 0 and set `InhibitMults := True`.
- **`FCONTEST.PAS`**: `RTC` init — `WARCBandsEnabled := False` (kills 30/17/12 at the band-switch level). CW function-key memories: `F3 = '# ' + MyGrid`, `F4 EX = 'NR # ' + MyGrid`, `F5 EX = '@ DE \ # ' + MyGrid`. RST is optional per rules and not transmitted by default. `MyGrid` substituted at FCONTEST init time (same idiom as `MyZone`).
- **`uNewContest.pas`**: RTC added to the 4-character-grid prompt branch.
- **Rule enforcement caveat**: TR4W has no per-band toggle (no `Band160Enable` etc.) and no per-mode disable. WARC is killed via the group toggle. 160 / 80 / digital modes are enforced only in the scoring branch — the operator can still tune and log there, but the QSO scores 0 and is excluded from mults.

#### UDP Wire-Format Bug Fixes (`src/trdos/LOGSUBS2.PAS`) — PR #903

- **`BandTypeToUDPContactBand[]` WARC labels were meter-band, not MHz**: other entries are MHz strings (`'1.8'`, `'3.5'`, `'7'`, `'14'`, `'21'`, `'28'`, `'50'`, ...), but the WARC slots had `'30'` / `'17'` / `'12'`. Consumers expecting `<band>18</band>` on 17m were silently dropping every WARC QSO. Fixed to `'10'` / `'18'` / `'24'`.
- **`<IsClaimedQso>` closing tag case-mismatch**: PR #901's X-QSO work emitted `<IsClaimedQso>...</IsClaimedQSO>` — strict XML parsers reject as malformed. Fixed to `</IsClaimedQso>` to match the opening tag.

#### `cMyGrid` Uninitialized-Memory Bug (`src/trdos/PostUnit.PAS`) — PR #903

- **Cabrillo and ADIF writers leaked stack bytes after short grids**. Line 2349 had `TempGrid[7] := #0;` and line 4051 had `TempGrid[5] := #0;` — both assumed a fixed grid length. For a 4-char grid (e.g. `EL88`), line 2349 left bytes 5–6 holding uninitialized stack memory, which `wsprintf %-7s` then printed as non-printable characters. The mirror at line 4051 silently truncated 6-char grids.
- Fix: both sites now use `TempGrid[Length(MyGrid) + 1] := #0;` — terminator tracks the actual grid length. Works for 4-, 5-, and 6-char grids.
- **Latent for years**: every existing contest using `RSTQSONumberAndGridSquareExchange` (EUROPEAN VHF, TESLA, RF-VHF-FD, OZHCR-VHF) prompts for 6-char grids via `uNewContest.pas`. RTC is the first 4-char-grid consumer of that exchange type.

#### Developer Docs (`docs/ADDING_A_NEW_CONTEST.md`, `tr4w/test/udp_listen.py`) — PR #903

- New ~330-line guide distilled from the RTC work covering parallel-array alignment between `ContestsArray` / `ContestTypeSA` / etc., reusable exchange / scoring / multiplier types, the `cMyGrid` trap, the `GetDistanceBetweenGrids`-vs-Haversine trap, FCONTEST function-key idioms, and an end-to-end checklist.
- `tr4w/test/udp_listen.py` — 38-line port-12060 listener used during testing of the UDP wire-format fixes.

---

### 4.147.06 (2026-05-13) — NY4I / N4AF

#### X-QSO Support (`src/VC.pas`, `src/uEditQSO.pas`, `src/MainUnit.pas`, `src/trdos/LOGSUBS2.PAS`, `src/uADIF.pas`, `res/`) — Issue #750, PR #901

X-QSO records stay in the log for NIL protection of the worked station but contribute nothing to the score — no QSO count, no multipliers, no points, no presence in the dupe sheet.

- **Storage**: `ceXQSO: Boolean` in `ContestExchange`, freed from `sReserved` (record size unchanged; legacy logs read as `ceXQSO=False`).
- **Edit dialog**: X-QSO checkbox after S&P. `FLD_XQSO = 170` with Set/GetCheck handlers in `uEditQSO.pas`.
- **Visual indicator**: full row grayed in editable log view (mid-gray text via `NM_CUSTOMDRAW`).
- **Score/dupe/mult exclusion**: enforced at both rebuild paths — `tUpdateLog(actRescore)` and `LoadinLog`. X-QSO records have `QSOPoints` zeroed at rescore (DXLog.net convention — consistent visual `0` in Pts column). Toggle X-QSO off and a normal rescore restores points based on contest rules.
- **ADIF emit**: `APP_TR4W_CLAIMEDQSO` field (`1` normal, `0` X-QSO); TR4W-namespaced.
- **ADIF import**: recognizes `APP_TR4W_CLAIMEDQSO`, `APP_N1MM_CLAIMEDQSO`, `APP_DXLOG_XQSO` for cross-tool round-trip.
- **Cabrillo**: leading tag becomes `X-QSO:` instead of `QSO:`.
- **UDP**: `LogContactToUDP` reports `<IsClaimedQso>0</IsClaimedQso>` for X-QSO and skipped records.
- **Resource files**: X-QSO checkbox (resource ID 170) added to all 10 remaining language `.RES` files (`tr4w_rus`, `tr4w_ser`, `tr4w_esp`, `tr4w_mng`, `tr4w_pol`, `tr4w_cze`, `tr4w_rom`, `tr4w_chn`, `tr4w_ger`, `tr4w_ukr`).
- Tests: 632 unit tests pass; added `Test_RoundTrip_XQSO_Field`, `Test_Import_XQSO_N1MM_Convention`, `Test_Import_XQSO_DXLog_Convention`.

#### Column Auto-Fit Padding (`tr4w.dpr` `WindowProc`) — Issue #900, PR #901

- **Double-click column-divider auto-fit now pads width so content survives restart**: at the just-fits threshold the Win32 Header control picked a width a few pixels narrower than the cell-content area (the ListView cell layout adds an internal margin). Value displayed correctly in the current session but applying the same pixel value on restart triggered ellipsis truncation (e.g. `14046.00` → `14046...`).
- Second issue uncovered during testing: the OS's internal auto-fit during `HDN_DIVIDERDBLCLICK` does **not** generate an `HDN_ENDTRACK`, so a flag-based "set in DBLCLICK, save in ENDTRACK" approach silently dropped the save on double-click.
- Fix: intercept `HDN_DIVIDERDBLCLICK` directly in `WindowProc`. Run auto-fit via `LVSCW_AUTOSIZE_USEHEADER`, read resulting width, add `COLUMN_DOUBLECLICK_PAD_PX` (12 px), apply, `SaveColumnWidthToConfig`, return `Result := 1; Exit;` to suppress the OS's default auto-fit. Manual drag unchanged — `HDN_ENDTRACK` still saves dragged width exactly.

#### WSJT-X Mult-Check Gate (`src/uWSJTX.pas`) — PR #901

- **Skip multiplier lookups for QSO-count-only contests**: CQ-decode handler was calling `DetermineIfNewMult` / `DetermineIfNewDomesticMult` on every decode regardless of whether the active contest had any multiplier dimension. For ARRL-DIGI / CQ-WPX-DIGI / similar contests every `Doing*Mults` global is False so these lookups always returned False but produced confusing log lines like `[uWSJTX] Checking if grid FN is a multiplier`. Gate behind `DoingDomesticMults or DoingDXMults or DoingPrefixMults or DoingZoneMults`. Dupe handling unchanged.

---

### 4.147.05 (2026-05-12) — NY4I / N4AF

#### K4 Network Keep-Alive (`src/uRadioElecraftK4.pas`) — Issue #897, PR #899

- **PING/PONG keep-alive in network mode**: K4 servers (`k4remote.elecraft.com`, K4 in host mode) drop a client that sends nothing for 10 seconds. TR4W's K4 network mode uses AI5 — state changes pushed from radio to client — but the client itself sent nothing during operator idle periods. An operator who tuned once and then sat quietly for >10 s silently lost the connection.
- Fix: in network mode `Connect` sets `requiresPolling := True; pollingInterval := 1000`. `PollRadioState` branches on `serialPort` — serial sends `IF;FB;` (current behaviour, AI disabled), network sends `PING;`. `ProcessMessage` adds `'PO'` to its `AnsiIndexText` list with an explicit case 17 that logs the PONG response (rather than fall-through, so a future reader sees PONG is handled). PONG refreshes the inbound watchdog via the existing `UpdateLastValidResponse` at the top of `ProcessMessage`.

#### ADIF Export Bug Fixes (`src/uADIF.pas`, `src/trdos/PostUnit.PAS`) — Issue #898, PR #899

- **`<SRX_STRING>` no longer prepends `59` for non-RST contests**: `ResolveSRXString` (added in PR #896) normalized `<SRX_STRING>` with an implied RST prefix so it would be symmetric with `<STX_STRING>` for state QSO parties. That assumption breaks for any contest whose exchange has no RST — ARRL Field Day, Winter Field Day, Sweepstakes (CW/SSB). FD export was emitting `<SRX_STRING:9>59 1D WCF` (bogus leading `59`). Fix: move `<SRX_STRING>` emission out of `uADIF.EmitADIFRecord` and into `PostUnit.EmitContestSpecificTailForExport` (the tail-emitter callback). Tail emitter decides shape: POTA → park-ref (existing branch unchanged); `ExchangeInformation.RST = True` → `ResolveSRXString` (state QPs / zone contests); `ExchangeInformation.RST = False` → `ExchString` as-is (FD, SS, Winter FD). `ResolveSRXString` promoted from private helper to public function in `uADIF`'s interface.
- **`<SRX>` / `<STX>` guard against unset-serial sentinels**: two "unset" sentinels were in use — `$FFFF` (65535, from `uADIF.InitContestExchangeForParse`) and `-1` (live-entry / binary-log paths). Prior guard was `<> $FFFF` only, dating from when these fields were `Word`. Fields are now signed `Integer`, so `-1` stays `-1`. For Field Day where SRX is unused and stays `-1`, `EmitADIFRecord` was producing `<SRX:5>000-1` (`IntToStr(-1) = '-1'` zero-padded to width 5). Fix: require value to be positive AND not the parse sentinel. Applied symmetrically to STX.

---

### 4.147.04 (2026-05-12) — NY4I / N4AF

#### ADIF Parser/Emitter Refactor (`src/uADIF.pas`, `src/MainUnit.pas`, `src/trdos/PostUnit.PAS`) — Issue #887, PR #896

- **Extract ADIF code into `uADIF.pas`**: focused, dependency-light unit (deps: `SysUtils`, `StrUtils`, `Log4D`, `VC`, `utils_text`) with pure string-in / string-out entry points so the ADIF format logic can be exercised by unit tests without linking `MainUnit`.
- **Part 1 — field-list lexer**: `ParseADIFFieldsList` extracted with unit tests.
- **Part 2 — move `TADIF_Fields` enum and helpers** from `MainUnit`: `GetADIFBand`/`Mode`/`SubMode`, `ADIFDate`/`Time`, `GetContestByADIFName`, `IsValidGUID`, `InitContestExchangeForParse`.
- **Part 3 — field mapping + multi-record import**: `ApplyADIFFieldsToExchange`, `TADIFRecordTemps`, `ImportADIFFromString`.
- **Part 4a — export side + differential round-trip tests**: `EmitADIFField`, `EmitADIFHeader`, `EmitADIFRecord`, `ExportADIFToString`, `GetStateForContest`, `ResolveADIFModeSubmode`, `ResolveRoverCall`, `ResolveSRXString`, `FormatADIFFreq`, `PadInt`. 21 fixture tests + 6 differential round-trip tests.
- **Part 4b — refactor `PostUnit.ExportToADIF`**: reduces the function from ~600 lines to ~30 lines that builds an in-memory record array and hands it to `uADIF.ExportADIFToString` with a `TContestTailEmitter` callback for the contest-specific fields that require `MainUnit`/`trdos` globals (STX_STRING, CNTY, CQZ/ITUZ, STATION_CALLSIGN, MY_POTA_REF/SIG/SIG_INFO, ARRL_SECT, CLASS, GRIDSQUARE, IOTA, DOK, APP_TR4W_HQ).

#### Latent Bug Fixes Surfaced by ADIF Work

- **Stack-buffer overflow in `sWriteFileFromString`** (`src/utils/utils_file.pas`): the function copied its input into a fixed 256-byte stack buffer via `StrLCopy(buffer, ..., 255)` and then asked `WriteFile` to write `Length(sBuffer)` bytes from that buffer. Any input ≥ 256 chars caused `WriteFile` to read uninitialized stack data past the end of the local array. Latent for years because every legacy caller passed short fragments; the Part 4b refactor writes the whole ADIF document in one call and immediately tripped it. Fix: write the string contents directly with `WriteFile(hFile, PChar(sBuffer)^, Length(sBuffer), ...)` — no intermediate buffer, no truncation. Empty-string guard added to avoid dereferencing a nil PChar.
- **`ADIF_FIELD_NAMES` had `'CQ_Z'` instead of `'CQZ'`** (`src/uADIF.pas`): TR4W's own export emits `<CQZ:N>...` but the import-side lookup table used `'CQ_Z'`, so imported ADIF files silently never populated the CQ zone field for any QSO — silent data loss on import for every contest that uses CQ zones.
- **`ImportADIFFromString` left Mode = CW for parse-time-defaulted records** (`src/uADIF.pas`): `FillChar(rec, SizeOf(rec), 0)` zero-initialized the `ContestExchange` before parsing, which set `Mode := CW` (first enum value). Any imported QSO whose source ADIF lacked a `MODE` field silently became CW instead of being flagged. Fix: `InitContestExchangeForParse` helper sets `Mode := NoMode`, `ExtMode := eNoMode`, etc. explicitly.

#### ADIF Export Verifier — Test Infrastructure (`tr4w/test/logdump/`, `tr4w/test/python/`)

End-to-end test harness that cross-checks the `.ADI` produced by `File -> Export to ADIF` against the canonical binary log (`.TRW`).

- **`logdump.exe`** (`tr4w/test/logdump/logdump.dpr`): Delphi 7 console tool that reuses the canonical `ContestExchange` record from `VC.pas` and emits JSONL — no risk of layout drift between Pascal and a separate consumer. Applies the same `GoodLookingQSO` filter as `ExportToADIF`. Detects non-aligned `.TRW` files up front (`(fileSize - headerSize) mod recordSize` must be zero) and halts with a clear diagnostic before reading garbage. Matches the legacy `MainUnit.ReadLogFile` behaviour of treating a short trailing read as silent EOF.
- **`verify_adif_export.py`** (`tr4w/test/python/`): Python cross-checker. Runs `logdump.exe` to get canonical record values, parses the `.ADI` output, asserts per-record equivalence on `ContestExchange`-driven fields (CALL, BAND, MODE/SUBMODE, dates, RST, SRX/STX, FREQ, CONTEST_ID, APP_TR4W_ROVERCALL, OPERATOR, APP_TR4W_ID, NAME, RX_PWR, CHECK, TEN_TEN, QTH, STATE). Also runs a structural-cleanliness pass over the whole `.ADI` that catches non-printable bytes anywhere in the file — the check that would have caught the `sWriteFileFromString` overflow instantly, with byte offset and context window.
- **Phase 1 scope** deliberately excludes the contest-specific tail fields because they depend on `MainUnit`/`trdos` globals.

---

### 4.147.02 (2026-05-10) — NY4I / N4AF

#### State QSO Party Rover — Slash-in-Call (`src/MainUnit.pas`, `src/trdos/PostUnit.PAS`, `src/trdos/LOGSUBS2.PAS`)

- **Rover call format (KG1S/MON)**: a state-QP rover call with a `/COUNTY` suffix is kept literally in the log (so Cabrillo and the on-screen log preserve it end-to-end); the county is pre-filled into the exchange at submit time.
- **Country lookup**: the slash-suffix is stripped before `ctyLocateCall` in import, live submit, and rescore paths so `/M` no longer mislabels a US rover as country=G.
- **ADIF round-trip**: export emits the bare call in `<CALL>` plus the full rover form in a TR4W-specific `<APP_TR4W_ROVERCALL>` field; import recognizes that field and restores the full form.
- **ADIF STATE**: contest→state map for 13 state QSO parties (CA/FL/MI/MN/MO/NC/OH/TX/WI/TN/CO/PA/IN); emits the contest's postal code when QTHString is a county, the 2-letter QTH otherwise, otherwise skipped. Replaces the prior MO-only special case.
- **ADIF CNTY**: emitted as `<CNTY:N>state,long-name` when `mo.DomList.FAltName` is populated for the worked county (CA, MO, OH, PA, WI, IL, TX, MI). FL/TN `_cty.dom` files lack `^Long` second fields, so CNTY is silently skipped for those.
- **County-line ops**: follow-up county records (multi-county Nfer Enter) are no longer flagged as dupes, do not emit the "is a dupe and will be logged with zero QSO points" banner / three-harmonic beep, and share the single transmitted serial number per CQ Magazine guidance for CQP. Implemented via `ceClearDupeSheet` honored at both `LogContact` and `tUpdateLog(actRescore)`.
- **ADIF SRX_STRING normalization**: `<SRX_STRING>` is normalized to include the implied RST (e.g. `599 HIL`) so it is symmetric with `STX_STRING` regardless of whether the operator typed the RST.

#### Multi-County / Multi-Park Nfer (`src/MainUnit.pas`) — Issues #885, #889

- **Single Enter = N QSOs**: one Enter press logs N QSOs for multi-county and multi-park entries.
- **Per-QSO SRX_STRING**: each follow-up record carries its own ADIF `<SRX_STRING>` (one ref per record), not the combined operator input.

#### ADIF Multiplier Repopulation (`src/MainUnit.pas`) — Issue #884

- **Import ADIF for state QPs**: after an import, multipliers (counties) are correctly repopulated for state QPs using the `RSTDomesticOrDXQTHExchange` style. Verified with CA QP and FL QP.

#### WinKeyer (`src/uWinKey.pas`)

- **WK3 hardware detection** — Issue #891: status field now reads `WK3 v31` for K1EL WinKeyer3. The binary `WK2 := version >= 20` check labeled anything ≥20 as "WK2"; now classified by K1EL firmware version (v<20 → WK1, v20-29 → WK2, v≥30 → WK3). Inline-asm `wsprintf` replaced with `Format`/`PChar`.
- **Port-open error fix**: `Winkeyer port COM5: xlk ,ÿñ"nS` garbage replaced with a readable Windows error message. Delphi 7 ABI mismatch — `SysErrorMessage(GetLastError)` returned its AnsiString via a hidden var-parameter (not eax), so the asm push'd random bytes into wsprintf. Now uses `SysUtils.Format`/`PChar`.

#### Networking

- **Active operator in network window** (`src/uNet.pas`, `src/VC.pas`, `src/MainUnit.pas`) — Issue #770: the network window shows the active operator name for each connected station.
- **uGetScores HTTPS** (`src/uGetScores.pas`) — Issue #26: raw WinSock2 POST replaced with `TIdHTTP` + TLS so secure score-site submissions work.
- **Connect-retry log filter** (`src/uNet.pas`): repeated retry messages are logged once per state change rather than once per retry.

#### Programmable Messages — Cmd Insert (`src/uMessagesList.pas`, `src/uEditMessage.pas`) — Issue #47

- **Double-click to insert at cursor**: in the message editor, double-clicking a command in the command list inserts the command text at the cursor position rather than replacing the field.

#### New Contest — Clean .TRW Overwrite (`src/uNewContest.pas`) — Issue #674

- **Delete .TRW on overwrite**: when creating a new contest that overwrites an existing one, the old `.TRW` file is deleted as part of the overwrite so stale log records do not bleed in.

#### Tests (`tr4w/test/unit/`)

- **utils_text unit tests**: tests for `StringIsAll*` and `StringWithFirstWordDeleted` added to `tr4w_unit_tests.dpr`.

#### Diagnostic Logging (`src/MainUnit.pas`)

- **`ctyLocateCallStripRover` trace**: ENTER/QP/suffix/EXIT lines at INFO so the country lookup behaviour for slashed calls is visible.
- **`actRescore` changed-record trace**: one INFO line per record when any of `CountryID`, `Prefix`, `DXQTH`, mult flags, `QSOPoints`, or `Dupe` changes during a rescore.

#### Known Follow-Ups

- **Issue #892** (next-station serial jumps by N after a multi-county / Nfer entry): TR4W conflates "log record count" with "next serial to transmit". Architectural fix needs a separate `NextSerialCounter`, out of scope for this release.

---

## 4.146.x — April 2026

### 4.146.14 (2026-04-17) — NY4I

#### POTA Exchange Parser — Free-Form with State/Section/Name Recognition (`src/trdos/LOGSTUFF.PAS`, `src/trdos/LOGSCP.PAS`, `src/trdos/FCONTEST.PAS`, `src/trdos/tree.pas`) — Issue #877

- **Free-form exchange**: POTA exchange is now always accepted — blocked saves are gone. Tokens are classified as US state/province (→ DomesticQTH), ARRL section, operator name (→ Name), or free-form notes (→ ExchString).
- **OperatorNameSet**: sorted list of ~1,300 operator names built from TRMASTER.DTA at contest load; binary search replaces the prior all-alpha character heuristic for name detection.
- **IsValidPOTAPark regex fix**: updated to require exactly a 2-letter prefix and 4–5 digit park number (e.g. `US-1234`, `K-0001`); rejects RST values and malformed refs.
- **LooksLikeAPOTAPark**: new helper in `tree.pas`; POTA added to `LooksLikeAGrid` exchange list so grid squares in POTA exchanges are recognised.

#### POTA ADIF Import/Export (`src/MainUnit.pas`, `src/trdos/PostUnit.PAS`) — Issue #877

- **ADIF import**: new fields `SIG`, `SIG_INFO`, `POTA_REF`, `APP_N1MM_ID`, `APP_TR4W_ID` parsed on import. POTA import tries `POTA_REF` → `SIG_INFO` (when `SIG=POTA`) → `STATE` fallback.
- **ADIF export**: writes `MY_POTA_REF` alongside existing `MY_SIG`/`MY_SIG_INFO` for backward compatibility; conditionally writes `SIG`/`SIG_INFO`/`POTA_REF` only when QTHString is a valid park ref; writes `STATE` or `GRIDSQUARE` from ExchString when applicable; adds `APP_TR4W_ID` (QSO GUID) to all records.
- **IsValidGUID**: new function validates GUID format for APP_TR4W_ID/APP_N1MM_ID fields on import.

---

### 4.146.13 (2026-04-17) — NY4I

#### Yaesu FTX-1F/FTX-1R Radio Support (`src/trdos/LOGRADIO.PAS`) — Issue #817

- **FTX-1F/FTX-1R serial CAT**: new polling procedure `pFTX1F` and parser `GetVFOInfoForYaesuFTX1` using the `rtYaesu4` protocol family. The FTX-1 IF response is 30 bytes (vs FTDX10's 28) due to a 5-byte P1 field, shifting all subsequent field positions. C4FM voice modes map to `Phone`/`eC4FM`. HamLib model 1051.

#### Log Version Guard (`src/MainUnit.pas`)

- **Newer-than-program log detection**: opening a log file whose version exceeds the program's `LOGVERSION` now shows a clear error dialog and halts cleanly, rather than offering a meaningless downgrade conversion.

---

### 4.146.12 (2026-04-16) — NY4I

#### Log Format v1.7 (`src/VC.pas`, `src/MainUnit.pas`, `src/TF.pas`, `src/trdos/LOGSUBS2.PAS`, `src/uEditQSO.pas`) — Issue #674, closes #768

- **QSO GUID field**: `ContestExchange` gains an `id` field (GUID string via `TF.GetGUID`) giving each QSO a unique identifier; `sReserved` adds expansion space and freezes the v1.6 layout as `ContestExchangev1_6`.
- **Log conversion**: `AskConvertLog` handles v1.5→v1.7 and v1.6→v1.7 with correct typed record reads and a prompt showing the source version. A read-only backup is created before any conversion begins.
- **UDP broadcast fix**: `uEditQSO` correctly sends delete-then-add when editing a QSO; `LogEditedContactToUDP` added to `LOGSUBS2.PAS`.

#### TR4WServer — Standalone Logging, Dependency Cleanup (`tr4wserver/src/tr4wserverUnit.pas`, `tr4wserver/tr4wserver.dpr`, `src/MainUnit.pas`)

- **Removed TF/MainUnit dependency**: TR4WServer no longer pulls in the full TR4W application via `TF → MainUnit`; replaced with a standalone `InitServerLogger` using Log4D directly.
- **Improved server logging**: received `ContestExchange` fields logged on each client message; bind/accept errors include the system error string.
- **BuildServer.ps1**: new PowerShell build script for TR4WServer, matching the `FullBuild.ps1` pattern.
- **Stale duplicate removed**: `tr4w/src/tr4wserverUnit.pas` caused the Delphi IDE to resolve the wrong unit via `.dof` SearchPath; removed to prevent build errors.
- **`{$DEFINE TR4WSERVER}` workaround removed**: the conditional guard in `MainUnit.pas` around `AskConvertLog` is no longer needed.

#### Windows Version Logging (`src/GetWinVersionInfo.pas`)

- **Windows 11 detection fix**: corrected `dwBuildNumber >= 22000` threshold; reads registry `DisplayVersion`/`UBR` so the debug log shows the full friendly string, e.g. `Windows 11 25H2 (Build 26200.5074)`.

#### Network Thread Observability (`src/uNet.pas`) — closes #768

- **Server address in log**: `TryConnectToNetwork` logs `host:port` on each connection attempt.
- **Thread exit confirmation**: `ConnectThread` logs its thread ID on exit, confirming cleanup and making thread lifecycle visible in the debug log.

---

### 4.146.11 (2026-04-14) — NY4I

#### CTY.DAT Auto-Update (`src/uCTYUpdate.pas`, `tr4w.dpr`, `src/uCFG.pas`, `src/MainUnit.pas`) — Issue #779

- **Background version check on startup**: TR4W fetches the country-files.com RSS feed on a background thread, extracts the latest `VER\d{8}` date from the first item description, and compares it to the installed file. A QuickDisplay hint appears when an update is available.
- **In-band version detection**: `GetInstalledCTYVersion` scans CTY.DAT line-by-line for the embedded `=VER\d{8}` marker so the comparison is always accurate against the actual installed file.
- **Alt+O download**: pressing Alt+O triggers an async download of the latest `cty.dat` directly to the program directory; the country table reloads automatically on completion without restarting.
- **Startup check toggle**: the version check can be disabled with `CTY UPDATE CHECK ON STARTUP = FALSE` in the config file.
- **Accelerator fix**: the Alt+O accelerator ID in all language `.RES` files was corrected from stale ID 10311 (`menu_alt_transfreq`) to 10603 (`menu_download_latest_cty_dat`).

---

### 4.146.10 (2026-04-14) — NY4I

#### WinKeyer — Trace Logging (`src/uWinKey.pas`, `src/trdos/LogCW.pas`) — Issue #871

- **Per-character trace logging**: added trace-level log lines to `wkSend`, `wkSendAdminCommand`, `wkSendByte`, `wkSendTwoBytes`, `wkAddCharToHostBuffer`, `wkAddCWMessageToInternalBuffer`, and `wkSendNextByteFromHostBuffer`. Each entry shows the printable character, decimal ordinal, and hex value to help pinpoint the source of an extra space in sent CW.

#### Band Map — Alt-D Residue Fix (`src/uBandmap.pas`) — Issue #872

- **Stale callsign bytes on double-click**: with QSY INACTIVE RADIO enabled, `DupeInfoCall` was assigned without zeroing the buffer first. `wsprintf` then read stale bytes from a previously longer callsign (e.g. DF9II displayed as DF9IIA3CNO). Fixed by calling `tClearDupeInfoCall` + `ClearAltD` before assignment, matching the established pattern in `uSpots.pas`.

---

### 4.146.7 / 4.146.8 (2026-04-13) — NY4I

#### Band Map Flicker (`src/uBandmap.pas`, `src/trdos/LOGSUBS2.PAS`, `src/trdos/LOGWIND.PAS`) — Issue #688

- **Coalesced refresh timer**: rapid spot arrivals and VFO changes now coalesce into a single `DisplayBandMap` call via a 250 ms `BandMapNeedsRefresh` flag instead of redrawing on every event.
- **WS_EX_COMPOSITED**: applied to the band map dialog so all children paint through DWM's back buffer, eliminating the top-to-bottom repaint sweep.
- **ValidateRect + RDW_NOERASE**: cancels the pending erase flash after `WM_SETREDRAW(True)` before owner-draw items fill their own backgrounds.
- **Spot deletion**: `DeleteSpotFromBandmap` now calls `DisplayBandMap` immediately after removing a spot; previously the deleted item stayed visible until the next spot arrival triggered a refresh.

#### Radio — K4 Serial Rate, K3 Shutdown, Icom VFO B (`src/uRadioPolling.pas`, `src/uRadioElecraftK4.pas`, `src/trdos/LOGSUBS2.PAS`, `src/uRadioIcomBase.pas`)

- **K4 serial poll rate**: `pollingInterval` now reads from `FreqPollRate` (`FREQUENCY POLL RATE` config, default 10 ms) instead of being hardcoded at 1000 ms — VFO update responsiveness now matches the K3.
- **K3/K4 clean shutdown**: `pKenwood2`/`pKenwoodNew` polling threads now check `PollingStopRequested` at the outer loop and inner byte-wait loop, exiting in ~20 ms on quit instead of timing out after 3000 ms.
- **Icom VFO B mode write**: replaced the old `$07 $01` / `$06` / `$07 $00` sequence with the `$26 $01` extended command on radios that support `FSupportsExtendedVFOBCommands` (e.g. IC-7760), matching the serial path in `LOGRADIO.PAS`.

#### Cluster — False Split Fix (`src/uTelnet.pas`)

- **False split on UP substring**: tightened the `UP <n>` parser so it only fires when a space precedes `U` and a digit immediately follows `UP `, preventing spot comments like "Pup Emma" from being misread as a split frequency.

---

### 4.146.6 (2026-04-12) — NY4I

#### Column Width Fix on Startup (`src/MainUnit.pas`, `src/uCommctrl.pas`, `src/VC.pas`, `tr4w/tr4w.dpr`) — Issue #866

- **QTH/exchange columns too narrow on startup**: `EnsureListViewColumnVisible` was using `LVSCW_AUTOSIZE_USEHEADER`, which sizes to the header text width only (e.g. "QTH" = 3 chars), ignoring data. Changed to `LVSCW_AUTOSIZE` so columns fit their widest data value.
- **User-adjusted column widths**: added `ColumnAutoSize` flag and `ColumnWidthOverride` array to persist user-adjusted widths across sessions.

#### HamLib Direct Improvements (`src/uRadioHamLibDirect.pas`, `src/uHamLibDirect.pas`, `src/uRadioPolling.pas`, `src/uCAT.pas`, `src/uCFG.pas`)

- **WSJT-X minimal poll set**: adopted the 6-command poll cycle WSJT-X uses (VFO A freq/mode, PTT, split, VFO B) with no RIT/XIT in the fast heartbeat. RIT/XIT moved to a 5-second slow poll (`SendRITXITPoll`), eliminating `$07 $D0` front-panel menu interference on IC-7610/7760.
- **Async transceive callbacks**: registered via `rig_set_trn(RIG_TRN_RIG)` for fast front-panel response; heartbeat polling remains primary for serial backends.
- **Accurate RIT/XIT on/off state**: uses `rig_get_func(RIG_FUNC_RIT/XIT)` separately from offset values; fixes false "RIT active" display when IC-7610 stores a non-zero offset with RIT disabled.
- **HamLib trace logging**: `HAMLIB TRACE = TRUE` in config redirects HamLib internal debug to `hamlib_trace.log`.
- **HamLib warning in CAT dialog**: warns when HamLib is selected for a radio with native TR4W support, explaining the RIT/XIT limitation.

#### Added **KX3 support**: added KX3 between K3 and K4 (`LOGRADIO.PAS`, `VC.pas`) — Kenwood protocol, 38400 baud, HamLib ID 2045.

---

### 4.146.5 (2026-04-11) — NY4I

#### POTA — Parks on the Air Full Feature Set (`src/trdos/FCONTEST.PAS`, `src/trdos/LOGSTUFF.PAS`, `src/MainUnit.pas`, `src/trdos/LOGSUBS2.PAS`) — Issue #864

- **Park name lookup**: downloads park name from the POTA API on exchange entry; name is displayed alongside the park reference in the QSO window.
- **Exchange normalization**: park references are normalized to canonical form (e.g. `K-1234`) before logging and export.
- **ADIF export**: normalized park reference written to `SRX_STRING` field.
- **QTH/RST fix**: QTH field was incorrectly showing RST value; now correctly populated from exchange.
- **Exchange acceptance fix**: exchange was not being accepted under certain conditions; also moved POTA menu to the Tools menu.
- **2fer/3fer/Nfer auto-log**: multiple park references can be entered in a single exchange; TR4W auto-logs one QSO per park.
- **Nfer label fix**: QuickDisplay now shows "3fer", "4fer" etc. dynamically based on actual park count — was always "2fer".
- **2nd operator repeat (Ctrl+T)**: new Commands menu item pre-fills the exchange with the last logged park references so a second operator can work the same activation without re-typing parks. Ctrl+T accelerator added to the resource table.
- **Stealth menu**: POTA menu items are hidden entirely (not just grayed) when the active contest is not POTA.

#### Radio — RIT and SO2R Fixes (`src/trdos/LOGRADIO.PAS`, `src/uFlexRadio6000.pas`)

- **SO2R RIT routing**: `RITBumpUp`/`RITBumpDown` always routed to `Radio1.tNetObject` regardless of which radio was active; now correctly routes to the active radio.
- **FlexRadio RIT accumulation**: RIT offset was stuck after the first bump because Flex does not reliably echo `rit_freq` back; local offset now updated optimistically before sending the CAT command.

#### Miscellaneous

- **SaveLogFileToFloppy**: removed bogus `lstrcat` call, replaced inline assembly with clean Delphi.

---

### 4.146.4 (2026-04-09) — NY4I

#### Band Map — CTRL-END Focus Fix (`src/uBandmap.pas`, `src/MainUnit.pas`, `src/uMenu.pas`) — Issue #861

- **Fixed CTRL-END not moving cursor to band map on the second press.** Root cause: when the band map dialog is re-activated after losing focus, Win32's `DefDlgProc` fires a nested `SetFocus(BandMapListBox)` synchronously *inside* the outer `SetFocus` call from the CTRL-END handler. The outer `SetFocus` then sends `WM_KILLFOCUS` to the now-focused listbox, triggering `LBN_KILLFOCUS` → `KillFocus()` → `SetFocus(wh[mweCall])`, leaving focus on the call window. Fixed with a `BandMapSettingFocus` flag that causes `KillFocus` to exit early while CTRL-END is directing focus to the band map.
- **Restored Ctrl+End shortcut to move cursor to band map.** The `RC_CURSORINBM_HK` hotkey and its `menu_ctrl_cursorinbandmap` menu entry had been commented out since at least the initial 2014 commit with no documented reason. Re-enabled both. `T_MENU_ARRAY_SIZE` bumped from 175 to 176 to match.

#### POTA — Default CW Memories (`src/trdos/FCONTEST.PAS`)

- Added default F1 (`CQ POTA \ \`) and F2 (`CQ POTA CQ POTA \ \ FD`) CW memories and a default QSL message (`73 \ EE`) for the POTA contest type.

---

### 4.146.3 (2026-04-08) — N4AF

#### Michigan QSO Party — DC Added as Multiplier (`target/dom/michigan.dom`, `target/dom/dc.dom`, `target/dom/s51.dom`) — Issue #862

- **Added District of Columbia (DC) as a multiplier for Michigan stations** in the Michigan QSO Party, effective for the April 18, 2026 event. `michigan.dom` updated to reference `S51.DOM`; `dc.dom` and `s51.dom` added to the installer.

#### YCCC SO2R — CW Speed (`src/trdos/LogCW.pas`)

- Disabled `YCCCSetSpeed` call in the CW speed change handler to prevent speed commands from being sent to the YCCC SO2R box during keyer operation.

---

### 4.146.2 (2026-04-07) — NY4I

#### YCCC SO2R Box — OTRSP RX Control and Overlapped I/O (`src/uYCCCSO2R.pas`, `src/trdos/LOGSUBS2.PAS`, `src/uProcessCommand.pas`) — Issue #61

- **Rewrote serial I/O to use overlapped (`FILE_FLAG_OVERLAPPED`) mode** so `WriteFile` never blocks the main UI thread. A dedicated write thread drains the command queue via `WaitForMultipleObjects`.
- **Added `YCCCSetStereo()` and `YCCCSetRxMode()`** for independent RX antenna control per the OTRSP protocol.
- **Hooked `ToggleStereoPin`** to call `YCCCSetStereo` for stereo/mono RX switching.
- **Added `OTRSPCommand` procedure** in `LOGSUBS2.PAS` handling the `OTRSP=RX1`, `RX2`, `RXA`, `RXI`, and `STEREO` function key messages.
- **Registered `OTRSP` command** and five display-only help entries in `uProcessCommand.pas` commands list.

---

### 4.146.1 (2026-04-06) — NY4I

#### FlexRadio 6000 — Split, Alert Color, and UI Fixes (`uFlexRadio6000.pas`, `uNetRadioBase.pas`, `uRadioPolling.pas`, `MainUnit.pas`, `VC.pas`, `uCFG.pas`, `uOption.pas`, `LOGRADIO.PAS`, `tr4w.dpr`) — Issue #855

- **Fixed split indicator not clearing when SmartSDR closes slice 1.** Root cause: `in_use=0` push for slice 1 was not handled. Now clears split state and zeros VFO B frequency/band when slice 1 is deallocated.
- **Fixed VFO B showing VFO A's frequency when split is disabled.** When split was enabled externally from SmartSDR (`slice 0 tx=0` push), `FSlice0TX` was set to False. On subsequent split disable (`slice 1 tx=0`), only `FSlice1TX` was updated — leaving `FSlice0TX` stale and routing the `transmit freq=` push to VFO B. Fixed: when slice 1 loses TX, `FSlice0TX` is forced True (TX must be returning to slice 0).
- **Fixed VFO B frequency not preserved across split enable/disable.** `SetFrequency` for VFO B now always updates the internal VFO object first; if slice 1 doesn't exist yet, it exits early without sending. `Split(True)` applies the stored VFO B frequency when creating the new slice.
- **Added alert color when radio is disconnected or not operational.** The frequency and radio name windows change to the alert color when the radio is disconnected or when TCP is connected but no slices exist (SmartSDR running but no RX slice). `IsOperational` virtual property on `TNetRadioBase` allows `TFlexRadio6000` to distinguish these states. `RadioDisconnected` flag on `RadioObject` is set/cleared by the polling thread on state transitions only, avoiding redundant repaints.
- **Added ALERT COLOR to the colors configuration dialog** (`uOption.pas`, `uCFG.pas`, `VC.pas`). Defaults to red. Configurable via `ALERT COLOR = <color name>` in the `.cfg` file.
- **Fixed `-` key leaving a `-` in the call window after toggling split.** The `-` handler in `CallWindowKeyDownProc` fires on `WM_CHAR`. After the handler clears the call window, the same `WM_CHAR` event delivered the `-` to `KeyboardCallsignChar` which re-inserted it. Fixed with a `CallWindowCharConsumed` flag that causes `tr4w.dpr` to skip `KeyboardCallsignChar` for that message.
- **Fixed split warning (QuickDisplay) showing/hiding based on stale polling value.** `CallWindowChange` fired before `CurrentStatus.Split` was updated by the polling thread, causing the split warning to appear when turning split off and not appear when turning split on. Moved split warning display to `DisplayCurrentStatus` (`uRadioPolling.pas`), driven by confirmed state transitions (`PreviousStatus.Split` → `CurrentStatus.Split`). Removed the racy QD calls from `CallWindowChange`.

---

## 4.145.x — March 2026

### 4.145.5 (2026-03-22) — NY4I

#### Icom Network — VFO A/B Independent Display (`uRadioIcomBase.pas`, `uRadioPolling.pas`, `uNetRadioBase.pas`) — Issue #849

- **Fixed both VFOs showing wrong mode (DATA when plain USB/LSB was set).** Root cause: the `$26` (VFO B mode-only) response handler was reading `data[4]` (the filter byte, FIL1 = `$01`) as the data-mode flag instead of `data[3]` (the actual data-mode byte). The IC-7760 `$26` frame layout is `subCmd + mode + dataMode + filter`, not `subCmd + mode + filter + dataMode`. A filter value of FIL1 (`$01`) was being treated as "data mode D1 active", causing every mode on VFO B to display as DATA.
- **Fixed inactive VFO always queried as VFO B.** The `$01` (mode push) and `$04` (mode query) handlers always called `QueryVFOBMode` for the inactive VFO. When VFO B is the active/main VFO, the *inactive* VFO is A — the handler now picks `QueryVFOAMode` or `QueryVFOBMode` based on `FActiveVFO`.
- **Fixed `dataMode` field never updated in `$26` handler.** Handler set `vfo.Mode` but left `vfo.dataMode` stale, causing data-mode state to diverge from display mode. Now both fields are always updated together.
- **Added `FSupportsActiveVFOQuery` flag** to gate all `$07 $D2` (Main/Sub band selection) logic. Set `True` for IC-7600, IC-7610, IC-7760, IC-7850 (confirmed Main/Sub support); left `False` for IC-7300, IC-7300MK2, IC-705, IC-905, IC-7100 (VFO A/B only — no `$07 $D2`). IC-9700 deferred pending firmware polling workaround (issue #850).
- **`QueryVFOAMode` / `QueryVFOBMode` / `QueryActiveVFO`** virtual stubs added to `TNetRadioBase` (`uNetRadioBase.pas`) so the polling thread can call them without a concrete type reference.
- **Startup query order** in `uRadioPolling.pas`: `QueryActiveVFO` is now called first so `FActiveVFO` is known before VFO freq/mode queries begin.

#### Bug Fix — Obsolete HAMLIB Config Commands No Longer Show Blocking Dialog (`src/trdos/LogCfg.pas`)

Users who had `HAMLIB RIGCTLD PORT`, `HAMLIB RIGCTLD IP ADDRESS`, or `HAMLIB RIGCTLD RUN AT STARTUP` in their `.cfg` file (left over from when those parameters existed) were shown a blocking warning dialog at startup after those commands were removed in 4.145.4. These three commands are now silently ignored with a `WARN`-level log entry instead of a dialog.

---

### 4.145.4 (2026-03-21) — NY4I

#### Icom Network — Initial Frequency Display (`uRadioPolling.pas`, `uRadioIcomBase.pas`, `uIcomNetworkTransport.pas`, `uIcomNetworkTypes.pas`)

- Fixed frequency/mode display staying blank after connect. Root cause: the `OnInitialPollSeeding` WM_TIMER callback was registered on a thread that never pumps a Win32 message queue (the polling thread uses `Sleep()`), so it never fired. Replaced with direct queries (`QueryVFOAFrequency`, `QueryVFOBFrequency`, `QueryMode`, `PollRadioState`) issued by the polling thread the moment `IsConnected` first becomes true. The timer mechanism (`ICOM_TIMER_INITIAL_POLL`, `OnInitialPollSeeding`, `FOnInitialPoll`/`OnInitialPoll`) has been removed entirely.
- Frequency display is now blanked when the radio disconnects, so stale data is never shown.

#### HamLib — Remove Obsolete rigctld Configuration (`uCFG.pas`, `VC.pas`, `CFGDEF.PAS`, `tr4w.dpr`) — Issue #846

- Deleted `uRadioHamLib.pas` (the old rigctld-based `THamLib` class). All HamLib radio control now goes through `uRadioHamLibDirect.pas` (`THamLibDirect`) which links directly to `libhamlib-4.dll`. The file was already unreferenced — no factory, no polling thread, no `uses` clause pointed to it.
- Removed four obsolete config parameters: `HAMLIB PATH`, `HAMLIB RIGCTLD PORT`, `HAMLIB RIGCTLD IP ADDRESS`, `HAMLIB RIGCTLD RUN AT STARTUP`, along with their backing variables (`TR4W_HAMLIBPATH`, `TR4W_HAMLIBPORT`, `TR4W_HAMLIBIPADDRESS`, `TR4W_HAMLIBRUNRIGCTLD`) and defaults. `HAMLIB DEBUG` is retained as it applies to the DLL-based path.

---

### 4.145.3 (2026-03-19) — NY4I

#### Icom Network — CI-V Send Queue (`uRadioIcomBase.pas`)

- Introduced `TCIVSendThread` to serialize all outbound CI-V commands through a single thread with a 25 ms minimum inter-command delay. Prevents poll bursts and user actions from flooding the radio's CI-V input buffer (dropped commands, response corruption under load).
- Urgent queue (PTT, CW stop) is drained before normal queue entries.
- Normal queue depth capped at 50 entries as a safety backstop.

#### Icom Network — Dead-Radio Detection (`uIcomNetworkTransport.pas`, `uIcomNetworkTypes.pas`)

- Track timestamp of last inbound ping from the radio (`FLastPingReceived`).
- If fully connected and no ping received for 15 seconds, log a warning and disconnect; the polling thread then attempts to reconnect. This is the only reliable signal that a WiFi/network link has gone away (UDP is connectionless).

#### Bug Fixes

- **CW stop command for Icom network** — Was sending `$17 $01`; corrected to `$17 $FF` (closes issue on CWByCAT-ESC-fix branch). Updated in `uRadioIcomBase.pas` and all three Icom protocol docs.
- **GridFields multiplier tracking** (`uMults.pas`, `LOGDUPE.PAS`, `LOGSTUFF.PAS`) — `IsDmMult` now accepts a `DomMultType` parameter. For GridFields contests the comparison truncates the query to the 2-char field prefix and prefix-matches against stored 4-char grid keys, so any grid in the same field is correctly recognized as already worked. Full 4-char key retained in storage for Cabrillo export.
- **WSJT-X band/freq logging** (`uWSJTX.pas`, `MainUnit.pas`, `VC.pas`) — Use band and frequency from the WSJT-X ADIF record when TR4W has no radio connected; fall back to radio frequency only when WSJT-X omits them (closes issue #822). `GENERALQSO` now uses grid square from any ADIF source (WSJT-X does not always include `PROGRAMID`). `ExchString` falls back to `QTHString` when ADIF leaves it empty. MO QSO Party: fixed `ciMM` multi-mode flag.
- **Missouri QSO Party dom files** — `missouri.dom` and `missouri_cty.dom` were on disk but excluded by a `.gitignore` rule for `tr4w/target/`; fixed rule so `dom/` negation takes effect.

#### Repository / Build

- Added missing `arizona.dom`, `arizona_cty.dom`, and `brazil.dom` to `target/dom/` (were present in installer but not in git; exposed by prior `.gitignore` fix for `target/dom`).
- Added `PerlRegEx.pas`, `pcre.pas`, and precompiled `pcre/*.obj` files to `include/` so the build is fully self-contained.
- Moved `RadioFactoryTester.dpr` and compile scripts into `tr4w/test/` alongside the unit-test sources.
- Suppressed `.claude/` dirs and `*.pcap`/`*.pcapng` captures from git status noise.

---

### 4.145.2 (2026-03-16) — IcomNetwork branch — NY4I

#### Icom Network Radio Control (Ethernet / WiFi)

Full CI-V over Ethernet/WiFi support for Icom radios using the Icom Remote Utility protocol. This replaces the previous HamLib/rigctld approach for network-connected Icom radios with a native Delphi implementation that matches the wfview reference.

**Supported radios:** IC-705, IC-7100, IC-7300, IC-7300 MK2, IC-7600, IC-7610, IC-7760, IC-7850, IC-905, IC-9700

**Protocol implementation (`uIcomNetworkTransport.pas`):**
- 7-state machine: Disconnected → WaitingForHere → WaitingForReady → WaitingForLogin → Authenticated → StreamRequested → Connected
- Authenticated session management with login retry on stale sessions
- TX buffer + retransmit response (responds to radio's retransmit requests)
- Idle keepalive on control socket every 100 ms (matches wfview)
- Local IP auto-detection via WinSock UDP connect + getsockname
- Auth failure detection with immediate feedback (red "AUTH FAILED" on radio status line, beep)
- Shutdown hang fix: `SafeFreeSocket` runs Indy `.Free` on background thread with 500 ms timeout to avoid Indy destructor deadlock

**CI-V state management (`uRadioIcomBase.pas`):**
- Startup query sequence after `$19` response: frequency, mode, TX status, RIT, XIT, split, VFO B
- Transceive push handling: `$00` (VFO A freq), `$01` (mode), `$1A $06` (data mode queried after mode push)
- Polling only for states the radio does not push: RIT/XIT (`$21`), split (`$0F`), TX status (`$1C $00`) — 1 s interval
- CW speed encode/decode: 6–48 WPM ↔ 0–255 linear ↔ 2-byte BCD
- CW watchdog: 2 s timeout triggers CivOpen re-handshake

**IC-7760 specifics (`uRadioIcom7760.pas`):**
- CI-V address `$B2`, controller address `$E1`
- VFO B via extended `$25`/`$26` commands with sub-command byte `$01`
- Shared RIT/XIT offset; `$21 $01`/`$21 $02` sub-commands for RIT/XIT on/off

**SO2R fixes:**
- Per-instance timer dispatch via `GWL_USERDATA` (replaced dangerous `GTransportInstance` global)
- Radio label (`"Rig 1 IC-7760"`) in all transport log messages

#### Bug Fixes

- **IC-705 BandUp skips 4m band** — IC-705 has no 70 MHz band; sending that frequency causes the radio to reject it and revert to 6m. `TIcom705Radio.ToggleBand` now cycles 6m → 2m directly.
- **Radio/CAT dialog (ID 66) — HamLib checkbox hidden** — When TCP/IP + Icom is selected, USERNAME/PASSWORD fields were dynamically inserted over the "Use HamLib" checkbox, making it impossible to disable HamLib. Fix: expand the CAT group box height and shift the HamLib checkbox, CW/PTT group box, and all controls below down 56 px at `WM_INITDIALOG`.
- **Data mode flicker** — Polling `$04` (mode) every second was overwriting the DIGI sub-mode state. Fix: mode arrives via `$01` transceive push only; `$1A $06` is queried after each `$01` push.
- **Log4D level inheritance** — Removed explicit `logger.Level := All` from all 12 Icom units; debug level now flows from root logger via `UpdateDebugLogLevel` in `uCFG.pas`.

#### New Units & Tests

- `uIcomCIV.pas` — BCD encode/decode helpers for CI-V frequency/value conversion
- `uRadioBand.pas` — `TRadioBand` enumeration and band-edge frequency constants
- `uRadioIcom7100.pas` — IC-7100 implementation (CI-V address `$88`)
- `test/unit/uTestIcomCIV.pas` — 32 CI-V BCD unit tests
- `test/unit/uTestRadioBand.pas` — band/frequency mapping tests
- `test/unit/uTR4WTestFramework.pas` — lightweight DUnit-compatible test framework

#### Documentation

- `docs/ICOM_NETWORK_PROTOCOL_GUIDE.md` — Icom remote utility protocol internals
- `docs/ICOM_NEW_RADIO_IMPLEMENTATION.md` — how to add a new Icom network radio
- `docs/tr4w-migration-strategy.md` — phased Delphi 7 → Delphi 12 migration plan with testing strategy and dialog migration tracks

---

### 4.145.1 (2026-03-04)
- **UI:** Main window rounded corners (issue #834) — N4AF

### Contest Support
- **Colorado QSO Party** rules and scoring (issue #831) — N4AF
- **Indiana QSO Party (INQP)** support (issue #832) — N4AF

### Build & Installer
- **Fix missing `libgcc_s_dw2-1.dll` runtime error** on clean Windows installs — NY4I  
  HamLib 4.7.0 was built with MinGW DWARF-2 exception handling but the installer shipped the SJLJ variant from an older HamLib version. Replaced `libgcc_s_sjlj-1.dll` with `libgcc_s_dw2-1.dll` from official HamLib 4.7.0 w32 release.
- **Add NSIS installer script** with HamLib DLLs included — NY4I

### Bug Fixes (issues #827, #828, #830)
- Various fixes merged by N4AF

---

## Radio Factory & Icom Support — January–February 2026

This was a major development effort (primarily NY4I) introducing a modern factory pattern for radio control, Icom CI-V support, HamLib Direct DLL integration, and comprehensive reconnection logic.

### Radio Factory Pattern (PR #827, December 2025 – February 2026)

**Architecture — Factory Pattern for Radio Creation**
- New `uRadioFactory.pas` — centralized factory class for creating radio instances by model type
- New `uRadioManager.pas` — manager class for multiple simultaneous radio instances (SO2R / multi-op)
- New `TestRadioFactory.pas` — test/demo program
- Support for Elecraft K4 (network and serial), Icom (CI-V), HamLib Generic, and HamLib Direct
- Documentation: `NETWORK_RADIO_FACTORY_ANALYSIS.md`, `RADIO_FACTORY_README.md`

**Icom Radio Support — IC-7300, IC-7610, IC-9700 (2026-01-05 through 2026-01-08)**
- New `TIcomRadioBase` with full CI-V protocol implementation
- Radio-specific classes for IC-7300, IC-7610, and IC-9700 with correct CI-V addresses
- Icom radios enabled in factory pattern for both network and serial connections
- **IC-9700 startup optimization:** reduced frequency display delay from 17 seconds to ~1.6 seconds (38400 baud) or essentially immediate (115200 baud) by sending an immediate poll on connection
- **Serial reconnection after power cycle:** keeps serial port open during reconnection, polls during disconnected state to wake Icom radios. IC-9700 reconnects ~16 seconds after power cycle

**HamLib Direct DLL Integration (2025-12-29 through 2026-02-23)**
- New `uHamLibDirect.pas` — complete HamLib 4.x DLL wrapper with direct `GetProcAddress` calls
- New `uRadioHamLibDirect.pas` — `THamLibDirect` radio class using direct DLL communication
- Replaces rigctld-based HamLib approach for better performance and reliability
- Supports 200+ radio models via direct DLL without requiring rigctld daemon
- HamLib version logged at startup
- **HamLib updated from 4.6.5 to 4.7.0** (32-bit DLLs for Delphi 7 compatibility)

**Serial Port Support for K4 via Factory (2026-01-05)**
- New `uSerialPort.pas` — Win32 serial port wrapper (`CreateFile`/`ReadFile`/`WriteFile`)
- Configurable baud rate, data bits, parity, stop bits; non-blocking 10ms timeouts
- `TNetRadioBase` extended with dual-mode (serial + network) support
- K4 serial connections now use the same modern code path as network connections

**Radio Class Refactoring (2026-01-05)**
- Eliminated K4-suffixed methods (`SetModeK4` → `SetMode`) by adding default VFO parameters to base class
- New `uRadioInterfaces.pas` with interface definitions (`IRadioBasic`, `IRadioFrequency`, `IRadioMode`, `IRadioDualVFO`, etc.) for future capability-based architecture
- Fixed `EAbstractError` crashes when connecting K4 via native TCP

**Crash Fix & Automatic Reconnection (2025-12-29 through 2026-02-23)**
- Prevent crash when radio disconnects by removing blocking locks from I/O operations
- Exponential backoff reconnection (1s initial → 30s max, 2x multiplier)
- Connection state tracking (`wasConnected`, `consecutiveFailures`)
- Exception handling for `EIdNotConnected`, `EIdConnClosedGracefully`, `EIdConnectTimeout`, `EIdSocketError`
- Threads persist through failures, auto-reconnect when radio/logger returns
- **Reset Radio Ports fix:** clean thread teardown and K4 reconnect state — serial disconnect now terminates reading thread before `Free`, releasing COM port

### External Logger Factory (2025-12-29)
- New `uExternalLoggerFactory.pas` — factory class for logger creation (DXKeeper, ACLog, HRD)
- New `uExternalLoggerManager.pas` — manages multiple logger instances with `ConnectAll`, `LogQSOToAll`, `DeleteQSOFromAll`
- Same reconnection logic applied to external loggers for consistency

### Repository Cleanup (February 2026)
- Moved documentation to `docs/` folder
- Removed tracked `.dcu` build artifacts from `bin/` and `res/bin/`
- Updated `.gitignore` for build logs, rotated log files, and build output
- Added missing `uDXLabPathfinder.pas` source file (was causing build failures)
- Removed duplicate HamLib DLLs from `lib/hamlib` (already tracked in `target/`)
- Untracked `tr4wserver.dsk`
- Updated `CLAUDE.md` project documentation

---

## 4.141.x — January–October 2025

### 4.141.1 (2025-02-04)
- Added `uSuperCheckPartial` source to the project (PR #812) — NY4I

### 4.141.0 (2025-01-03)
- Master release — N4AF

### Contest Online Scoreboard (COSB)
- **Fix COSB integration** — local `tr4w.ini` configuration per COSB docs (issue #825) — N4AF
- **Online scoreboard** support (issue #823) — N4AF

### Radio Info Fix (2025-03-11)
- Fixed `EntryWindow` handle in RadioInfo UDP message — was not set to a number, causing downstream issues for external programs (PR #815) — NY4I

### Bug Fixes
- **Ensure at least one space after MyCall** for consistent output formatting (issue #813, PR #814) — Vojtěch Šádek
- Radio polling improvements (issue #815) — N4AF

---

## 4.140.x — December 2024

### 4.140.7 (2024-12-30)
- Bug fixes (issue #811) — N4AF

### 4.140.6 (2024-12-26)
- Bug fix (issue #809) — N4AF

### 4.140.5 (2024-12-23)
- Fixes (minus issue #800) — N4AF

### 4.140.1 (2024-12-21)
- **9A DX** contest support (issue #805) — N4AF

### 4.140.0 (2024-12-04)
- December build — N4AF

### Changes
- **Added IC-7760** radio support, based on IC-7610 (PR #809) — NY4I
- **Changed DI mode to DG** for Winter Field Day — WFD team changed their parser to conform to standard Cabrillo mode for digital contacts (PR #811) — NY4I
- **Fixed CW speed** following Kenwoods and Elecraft (PR #804) — NY4I
- **Added IC-7760 code** and RegEx maintenance — moved code into includes to ensure TPerlRegEx compiles with same version as pcre library (PR #796) — NY4I

---

## 4.139.x — November 2024

### 4.139.1 (2024-11-25)
- **Removed autofill of zones via `cty.dat`** — N4AF
- QSY now properly deletes call + exchange windows (issue #795) — N4AF
- Entered frequency fails to clear on QSY — fix — N4AF

---

## 4.138.x — October–November 2024

### 4.138.5 (2024-11-01)
- New `trmaster` and `cty.dat` data files — N4AF

### 4.138.4 (2024-10-31)
- Fixes for issues #786, #787, #788 — N4AF

### Contest Support
- **WAG IE** (issue #785) — N4AF

---

## 4.137.x — August 2024

### 4.137.2 (2024-08-29)
- Updated `uSuperCheckPartialFileUpload.dcu` compiled with new Indy version (PR #782) — NY4I
- Added Indy10 library — NY4I

### 4.137.1 (2024-08-15)
- **Arizona QSO Party** Cabrillo name update — N4AF

### 4.137 (2024-08-11)
- August 2024 release — N4AF

---

## 4.136.x — June–August 2024

### 4.136.3 (2024-08-06)
- Fix for issue #458 — N4AF

### 4.136.2 (2024-07-23)
- **LABRE-DX** contest support — N4AF
- **Arizona QSO Party** updates — N4AF

### 4.136.1 (2024-07-23)
- **LABRE** contest support — N4AF

### 4.136.0 (2024-06-05)
- June release — N4AF

---

## 4.135.x — April–May 2024

### 4.135.4 (2024-05-16)
- Fix for issue #765 — N4AF
- **Fix ADIF SUBMODE** — `SUBMODE` could incorrectly be set where not applicable due to stale temporary strings in `PostUnit` `ExportADIF` (PR #764) — NY4I
- `uSpots.pas` update (PR #765) — NY4I

### 4.135.3 (2024-05-10)
- ADIF submode fix (issue #763) — N4AF

### 4.135.2 (2024-05-05)
- Update `IN7QPNE_CTY` — N4AF

### 4.135.1 (2024-05-02–03)
- Fix for issue #762 — N4AF

### 4.134.2 (2024-04-29)
- Fix for issue #761 — N4AF
- **Updates for FQP and other QSO Parties** — DX multipliers for FQP, added Cabrillo names where different from string name, fixed `PostScore` bug (PR #761) — NY4I

---

## 4.133.x — April 2024

### 4.133.2 (2024-04-09)
- Fix for issue #757 — N4AF

### 4.133.1 (2024-04-07)
- **SO2R display** fix (issue #754) — N4AF

---

## 4.132.x — March–April 2024

### 4.132.4 (2024-04-03)
- New `trmaster` + `cty.dat` — N4AF

### 4.132.3 (2024-04-03)
- Fix for issue #753 — N4AF
- **Properly filled out `ismultiplier` fields** — were previously set to 0 (PR #753) — NY4I

### 4.132.2 (2024-03-30)
- Fix for issue #746 — N4AF

### 4.132.1 (2024-03-13)
- **Allow two-letter POTA codes** (issue #744) — N4AF
- Updated RegEx to support two-letter park codes (PR #744) — NY4I

---

## 4.131.x — January–March 2024

### 4.131.13 (2024-03-06)
- Fix for issue #742 — N4AF
- **Fixed Reset Ports** for networked K4 — also other items (PR #742) — NY4I

### 4.131.11 (2024-02-26)
- **Implemented commands to delete a contact** — sends `DeleteQSO` record on delete, delete-then-re-add on change (issue #738, PR #738) — NY4I

### 4.131.10 (2024-02-24)
- **Make external logger selectable** — framework for DXKeeper, ACLog, HRD; DXKeeper working, others stubbed (issue #734, PR #734) — NY4I

### 4.131.9 (2024-02-21)
- Fix for issue #733 — N4AF

### 4.131.5 (2024-02-06)
- **DARC-10M** contest changes (issue #712) — N4AF
- **OKOM** contest changes (issue #711) — N4AF

### 4.131.4 (2024-02-06)
- **ADIF export of myexchange** — code was missing in `PostUnit` (issue #725, PR #725) — NY4I

### 4.131.3 (2024-02-05)
- Fix for issue #702 — N4AF
- **Fix score posted to online scoreboard and UDP** (PR #724) — NY4I

### 4.131.1 (2024-02-03)
- FOC Marathon import `foc_num` fails — fix — N4AF

### Bug Fixes
- **Fix UDP port binding conflicts** — port was bound even when `WSJTXEnabled` was `false`, conflicting with JTAlert (PR #729) — NY4I
- **Fix VFOBumpUp/Down for Flex** — Flex doesn't support `UP;`/`DN;` commands; now adds/subtracts 20 Hz directly (issue #727, PR #728) — NY4I
- **FOC and WFL N1MM import** fix (PR #723) — NY4I
- **Added X-EXCHANGE for Winter Field Day** (closes #698, PR #721) — NY4I
- **Fix UDP contact port** — copy-paste error where `BroadcastPortLookup` was overwriting `ContactPort` (fixes #715, PR #720) — NY4I
- **External logger start and UDP fix for Node-RED dashboard** (closes #707, PR #714) — NY4I
- **SO2R BM only loads ALT-D** (issue #733) — N4AF

---

## 4.130.x — January 2024

### 4.130.1 (2024-01-06)
- `uSpots` — stop dupe check on match — N4AF

### 4.130 (2024-01-03)
- January 2024 master release — N4AF

---

## 4.129.x — December 2023

### 4.129.2 (2023-12-17)
- **9ADX** multipliers set wrong — fix — N4AF

### 4.129.1 (2023-12-12)
- Added `croat.dom` to build — N4AF

---

## 4.127.x — September–October 2023

### 4.127.5 (2023-10-28)
- Fix for issue #704 — N4AF

### 4.127.3 (2023-10-15)
- Fix for issue #688 — N4AF
- **Fixed UDP band issue** — NY4I

### 4.127.2 (2023-10-09)
- **PA QSO Party** rules added — N4AF

### 4.127.1 (2023-10-08)
- Fix for issue #700 — N4AF

---

## 4.126.x — August–September 2023

### 4.126.8 (2023-09-23–29)
- Fix `uSpots` (issue #697) — N4AF
- Fix hesitation calling station — N4AF

### 4.126.7 (2023-09-21)
- Fix for issue #696 — N4AF

### 4.126.6 (2023-09-16)
- Fix for issue #695 — N4AF

### 4.126.5 (2023-09-15)
- Fix for issue #694 — N4AF

### 4.126.4 (2023-09-14)
- Fix for issue #693 — N4AF
- **Add Icom address to rigctld parameters** — CIV address was missing (PR #693) — NY4I

### 4.126.3 (2023-09-12)
- Fix for issue #690 — N4AF

### 4.126.2 (2023-09-08–12)
- Fix BWQP — N4AF
- Fix for issue #690 — N4AF

### 4.126.1 (2023-09-06)
- Fix for issue #689 — N4AF

---

## 4.125.x — August 2023

### HamLib Support (PR #684 — Major Feature)

This was a significant upgrade adding HamLib support to TR4W. HamLib is the ham radio control library used by WSJT-X and many other programs, enabling automatic support for radios that HamLib supports.

### 4.125.4 (2023-08-26)
- Fix for issue #259 — N4AF

### 4.125.3 (2023-08-25)
- HamLib pass 3 — handle debug log level better (PR #686) — NY4I
- Add required HamLib DLLs — NY4I

### 4.125.2 (2023-08-23)
- HamLib pass 2 — fixed radio enumeration, rigctld starts minimized (PR #684) — NY4I
- Add Ctrl-J HamLib English helps — N4AF

### 4.125.1 (2023-08-22)
- **HamLib support initial release** — N4AF, NY4I
- Install HamLib files in target directory — NY4I
- Added 5 HamLib-related CFG parameters — NY4I
- Full HamLib commands and `get_vfo_info` processing — NY4I
- Changes to close rigctld at shutdown — NY4I
- Fix Orion frequency and mode — NY4I
- Fix exception in `SendToRadio` — NY4I

### Bug Fix
- **Fix ALT-M on Yaesu radios** (PR #682) — NY4I
- **Fix Yaesu serial CW** (issue #678, PR #679) — NY4I

### 4.125 (2023-08) — YO-DX-HF
- **YO-DX-HF** contest support (issue #687) — N4AF

---

## 4.124.x — July 2023

### Fixes after Field Day
- Fix WSJT-X mode logged as Data/RTTY instead of FT8/FT4 (issue #658) — NY4I
- Fix PlayMessage issue — NY4I
- Network parameter send safeguards — prevent disrupting remote config (PR #672) — NY4I
- Added OPERATOR field to edit dialog — all language resource files updated (closes #601, PR #669) — NY4I
- Fixed format statement `%` → `%s` in `ExchangeWindowChange` (fixes #657, PR #665) — NY4I
- TCP server for WSJT-X radio control can be turned off — NY4I
- NAQP-RTTY import now sets STATE properly — NY4I
- Importing N1MM logs for various contest types — NY4I

---

## 4.123.x — May 2023

### POTA Support (PR #647)
- Fixed ADIF file for POTA — NY4I
- New `TF` format for 5 `PChar` parameters — NY4I
- Allow blank exchange for POTA (default RST, no park) — NY4I
- Changed directory name for POTA log — NY4I

### Czech Dialog Fix
- Restored missing TCP/IP options in Czech radio dialog (PR #650) — NY4I

---

## 4.122.x — March 2023

- Added Kenwood and Yaesu radio commands — NY4I
- Added commands to stop playing message on ESC (closes #640, #639, PR #642) — NY4I
- **Fixed WFD import** and SRS commands for network (closes #635, #637, PR #638) — NY4I

---

## 4.121.x — January 2023

- **Fix:** Close logfile after UDP command — was preventing subsequent contacts from saving (PR #634) — NY4I

---

## 4.120.x — December 2022

- Added M class and MX section for Mexico (PR #630) — NY4I
- Changed ADIF name to WFD — NY4I
- Fixed `LooksLikeAGrid` in TREE — NY4I

---

## 4.114.x — August 2022

- Fix for issue #614 (PR #615) — N4AF

---

## 4.111.x — May–June 2022

### UDP Port Improvements (PR #591)
- **Separate UDP ports** for App, Contact, Radio, and Score — NY4I

### Bug Fixes
- **Added grid-locator to Cabrillo header** (closes #599, PR #600) — NY4I
- Cleared Cabrillo exchange fields before each contact write — random data was appearing — NY4I
- Fixed ADIF parser for gridsquare in `MainUnit` (PR #598) — NY4I
- Added confirmation dialog after Cabrillo upload or on error (fixes #592, PR #593) — NY4I
- June `cty.dat` and `trmaster` update — N4AF

---

## Earlier History (2014–2022)

The repository was first committed on April 25, 2014 at version 4.30.3 by Howard Hoyt (N4AF). The project has been continuously developed since then, with NY4I (Tom Schaefer) joining as a major contributor. Over the project's life, it has grown from a basic contest logger to a full-featured application supporting dozens of contests, multiple radio protocols, HamLib integration, external loggers, WSJT-X digital mode integration, online scoreboards, and POTA/QSO Party support.

---

*This changelog was generated from the Git commit history of the [TR4W/TR4W](https://github.com/TR4W/TR4W) repository on March 19, 2026.*

---

## Pre-GitHub History (2009–2012) — UA4WLI

> The following release history predates the GitHub repository. It was recorded by
> Dmitriy Gulyaev (UA4WLI), the original author of TR4W, in `src/uHistory.pas`.
> Versions span 4.162 through 4.247, covering September 2009 through December 2012.

### 2012

#### 4.247 (December 8, 2012) — UA4WLI

- **Revised:** Corrected ARRLSECT.DOM file
- **Revised:** New rules of RADIO-160 contest
- **Added:** Support of YAESU FTDX3000 transceiver

#### 4.246 (July 21, 2012) — UA4WLI

- **Revised:** New ARRL Section for Canada in Sweepstakes and other ARRL contests
- **Fixed:** Problem with NAQP Cabrillo file

#### 4.245 (May 9, 2012) — UA4WLI

- **Added:** M (Multiplier) column in log show actual mults for QSO: x(DXCC), d(Domestic), z(Zone), p(Prefix)
- **Revised:** MMAA contest renamed to CQMM. Corrected score calculation
- **Added:** If LATEST CONFIG FILE is empty or file is not exist - button "Latest config file..." in "Open configuration file..." is not visible
- **Revised:** Updated ARI.DOM file
- **Added:** Support of ICOM IC7410 transceiver
- **Added:** After program startup: if value of MY GRID is empty then the program will ask to enter your grid locator
- **Added:** Prefill of exchange number in RDAC contest
- **Revised:** "DVP" function renamed to "DVK" (Digital Voice Keyer).
- **Added:** Added new command DVK LOCALIZED MESSAGES ENABLE.

#### 4.244 (February 25, 2012) — UA4WLI

- **Revised:** Corrected PMC.DOM file
- **Fixed:** Corrected UI of "New contest" window
- **Added:** Processing of RX_PWR ADIF tag
- **Added:** Import of frequency in kHz from ADIF file
- **Fixed:** Value of EXCHANGE RECEIVED for DARC-10M contest changed to RST QSO NUMBER AND POSSIBLE DOMESTIC QTH
- **Added:** Support of CQIR contest
- **Added:** Support of WWIH (WORLD WIDE IRON HAM) contest

#### 4.243 (January 4, 2012) — UA4WLI

- **Fixed:** Added HI identifier in HAWAII.DOM file
- **Fixed:** Added EWA identifier in ARRLSECT.DOM file
- **Fixed:** Truncating frequency in bandmap
- **Added:** Check of filling of LOCATION field in ARRL-10 contest
- **Fixed:** Exchange parsing in ARRL-FD contest
- **Revised:** Command BANDMAP ITEM HEIGHT renamed to BAND MAP ITEM HEIGHT
- **Revised:** Command BANDMAP ITEM WIDTH renamed to BAND MAP ITEM WIDTH
- **Revised:** Window "SP COUNTER" renamed to "S&P COUNTER""
- **Revised:** Default value of POSSIBLE CALL MODE changed to ALL
- **Added:** Support of ARRL-RTTY contest

### 2011

#### 4.241 (December 7, 2011) — UA4WLI

- **Fixed:** EXCHANGERADIOS function key command
- **Fixed:** MP3 PLAYER command
- **Revised:** "0" value in total window don`t displayed
- **Added:** New command MAIN CALLSIGN
- **Added:** Import from ADIF: handling of PRECEDENCE, CHECK, ARRL_SECT tags
- **Revised:** Values of SCORE POSTING URL and SCORE READING URL commands changed to http://cqcontest.ru
- **Fixed:** QSOB4.WAV message in phone mode
- **Fixed:** INITIAL EXCHANGE CURSOR POS = AT END. If INITIAL EXCHANGE OVERWRITE = TRUE then cursor always will be placed at the end of exchange window
- **Revised:** Changed windows names: "TEN MINUTS" > "TEN MINUTES", "LOCATOR" > "GRID LOCATOR"

#### 4.239 (October 9, 2011) — UA4WLI

- **Added:** Initial exchange in OZCHR-TEAMS contest
- **Fixed:** LEAVE CURSOR IN CALL WINDOW
- **Revised:** Support of RSGB-ROPOCO-CW and RSGB-ROPOCO-SSB contests (revision)
- **Fixed:** Drop-down commands list in "DX-cluster window"
- **Fixed:** "Tools" -> "Synchronize PC time" -> "Synchronize clock" : display error if program does not running with Administrator Privileges"
- **Fixed:** Country determination for RI1FJ and RI1MV callsigns
- **Fixed:** Score calculation in DARC-WAEDC
- **Fixed:** Drop-down list with addresses in "DX-Cluster" window
- **Added:** New menu item in bandmap popup-menu - "BAND MAP MULTS ONLY"
- **Fixed:** Multipliers calculation in CQ-M and OZCHR-TEAMS contests. Corrected r150s.dat file
- **Revised:** Renamed ARI contest to ARI-DX. Added MB multiplier to ari.dom
- **Revised:** ARRL-FD contest: corrected score calculation, score calculated without power multipliers; added export to cabrillo
- **Revised:** Support of MAKROTHEN-RTTY contest
- **Added:** QSO NUMBER BY BAND command

#### 4.236 (July 4, 2011) — UA4WLI

- **Added:** Added support of CWOPEN contest
- **Revised:** Corrected ARRLSECT.DOM file

#### 4.221 (May 24, 2011) — UA4WLI

- **Fixed:** Garbage in Alt-D callsign
- **Added:** Determination of new mult if MULT BY BAND = FALSE
- **Added:** Default value of INITIAL EXCHANGE for CWOPS contest is set to NAME QTH
- **Fixed:** BAND MAP CALL WINDOW ENABLE = TRUE will not work if callsign in CALLSIGN WINDOW is typed by operator or if spot`s callsign = MY CALL

#### 4.234 (March 8, 2011) — UA4WLI

- **Added:** New command QZB RANDOM OFFSET ENABLE ( default value = FALSE)
- **Fixed:** "Send spot" - sending spots only for "my log"
- **Added:** Support of NAQP-RTTY contest (MMTTY version)
- **Fixed:** No program interruption if RELAY CONTROL PORT = PADDLE PORT
- **Fixed:** Fixes for NAQP-RTTY
- **Added:** New command `MM_CLEAR_THE_TX_BUFFER`
- **Added:** New command `MM_SWITCH_TO_TX`
- **Added:** New command `MM_SWITCH_TO_RX_IMMEDIATELY`
- **Added:** New command `MM_SWITCH_TO_RX_ AFTER_THE_TRANSMISSION_IS_COMPLETED`
- **Fixed:** Alt+P->O in phone mode
- **Fixed:** Identification of russian oblast by callsign
- **Added:** Support of NA-SPRINT-RTTY (MMTTY version)
- **Added:** Auto CQ in RTTY mode

#### 4.233 (February 3, 2011) — UA4WLI

- **Fixed:** Fixes
- **Added:** Support of CQ-WPX-RTTY
- **Added:** Support of NAQP-RTTY contest (MMTTY version)
- **Fixed:** Corrected S48.DOM file
- **Fixed:** New multipliers determination in NAQP
- **Added:** Updated PMC.DOM file
- **Added:** Removed "VER" as an alias for Vermont in S48.DOM file
- **Added:** Identification of Guantanamo Bay (KG4) callsigns

### 2010

#### 4.231 (December 4, 2010) — UA4WLI

- **Fixed:** Default value of CALLSIGN UPDATE ENABLE for ARRL-SS-CW and ARRL-SS-SSB is set to TRUE
- **Added:** Enter a 2 or 3 digit number in the Call Window followed by a CTRL-P would cause the rotator to point in the direction in degrees indicated by the numbers
- **Added:** New multipliers file - ARRL10.DOM
- **Fixed:** Export to ADIF format for WAG and ARRL-SS contests
- **Fixed:** Support of "EXCHANGERADIOS" special command (`EXCHANGERADIOS`)
- **Added:** QSK keying if KEYER OUTPUT PORT = PARALLEL and PTT ENABLE = FALSE
- **Added:** Forming exchange string for contests with EXCHANGE RECEIVED=RST ZONE
- **Added:** Country definition of R*2 callsigns
- **Added:** DX Clutser: support of OL5Q skimmer (217.75.211.40:7300) spots format
- **Added:** Contests with EXCHANGE RECEIVED = QSO NUMBER NAME DOMESTIC OR DX QTH (US QSO parties): parsing of exchange strings like 222VE3
- **Added:** Export to ADIF in NAQP contest
- **Added:** Two radio dupe sheet windows
- **Added:** Improved manual input of frequency in callsign window
- **Added:** Changed polling logic for Kenwood`s rigs

#### 4.229 (August 24, 2010) — UA4WLI

- **Fixed:** DARC-WAEDC - corrected multipliers calculation for EU stations
- **Added:** RDAC and YODX contests - determination of domestic multiplier by callsign. Determination based on previous Qs data and initial.ex
- **Added:** Determination of domestic multiplier on the basis of exchange number
- **Fixed:** START SENDING NOW KEY function for callsigns with slash
- **Fixed:** Telnet/Bandmap window - reject of spots with frequency > 430 MHz
- **Added:** "Possible calls" function with using of (tr)master.dta
- **Added:** Support of ICOM IC-7200 transceiver
- **Added:** TR-LOG style of dupesheet window. Command COLUMN DUPESHEET ENABLE not processed
- **Added:** Display of multipliers in "Remaining mults" window in European HF Championship
- **Added:** Processing of MY ZONE command
- **Added:** Common (for all contests) function keys messages may be stored in ../TR4W/COMMONMESSAGES.INI file
- **Added:** Logging of BP100 callsign
- **Added:** usage of ADD DOMESTIC COUNTRY = CLEAR
- **Added:** ICOM RESPONSE TIMEOUT command not processed. Value of ICOM RESPONSE TIMEOUT determined by the program based on the value of RADIO ONE/TWO BAUD RATE
- **Added:** Support of OZHCR-VHF
- **Added:** Support of RAC CANADA DAY
- **Added:** MESSAGE ENABLE command
- **Added:** EUROPEAN VHF contest: for 9A paricipants points calculate according with Croatien VHF contest rules
- **Added:** PTT signal in FM mode
- **Added:** Updated IARUHQ.DOM file
- **Added:** defination of grid for UA/UA9 stations
- **Added:** "Initial exchange" function (initial.ex) enabled for WRTC contest
- **Added:** New special command - WK_RESET - resets the Winkeyer2 processor to the power up state. Example - CQ CW MEMORY CONTROLF4=`WK_RESET`
- **Added:** New special command - WK_SWAPTUNE - swap Winkeyer2 tune function
- **Added:** Default value of CUSTOM CARET changed to TRUE
- **Added:** Default value of DISTANCE MODE changed to KM

#### 4.220 (May 19, 2010) — UA4WLI

- **Fixed:** Definition of country for /MM callsigns
- **Fixed:** Logging of Sicily callsigns in ARI contest
- **Fixed:** MMAA contest - callsign overwrite if CALLSIGN UPDATE ENABLE=TRUE
- **Fixed:** Overwrite of user function keys messages by defaults
- **Fixed:** Points/multipliers calculation, default exchange number in WRTC contest
- **Fixed:** Default value of ICOM RESPONSE TIMEOUT increased to 60 ms
- **Revised:** Updated QSO POINT METHOD, MINNESOTA_CTY.DOM and MINNESOTA.DOM files for MINNESOTA QSO PARTY in accordance with new rules
- **Revised:** Usage of old "Tools" -> "Synchronize PC time" dialog window
- **Added:** Support of CWOPS contest

#### 4.219 (April 28, 2010) — UA4WLI

- **Fixed:** Crash on MP3 RECORDER SAMPLERATE command
- **Added:** Support of skimmers spots

#### 4.218 (April 19, 2010) — UA4WLI

- **Fixed:** Quality of the recorded MP3 files
- **Fixed:** Alt-K in phone mode
- **Fixed:** WK AUTOSPACE, WK CT SPACING, WK KEYER MODE, WK PADDLE SWAP
- **Fixed:** Usage of CQ SSB EXCHANGE and QUICK QSL SSB MESSAGE comands
- **Fixed:** IC781 mode polling
- **Fixed:** Orion polling
- **Fixed:** FT857, FT897 frequency setting
- **Revised:** GAGARIN CUP QSO points calculation
- **Added:** Support of "CI-V transcieve" mode
- **Added:** New special command - SENDMESSAGE. Equivalent of "Net" -> "Send message" menu item
- **Revised:** If SERIAL NUMBER LOCKOUT=1 in tr4wserver.exe settings then locked numbers will be displayed with the "L" suffix in "QSO NUMBER" window
- **Added:** New command - RADIO ONE/TWO ICOM FILTER BYTE. Values: 0 - disable filter width control; 1,2,3 - Wide, Normal, Narrow filters. Applicable only for ICOM`s rigs

#### 4.208 (March 14, 2010) — UA4WLI

- **Fixed:** Time synchronize
- **Fixed:** "Stations" window
- **Added:** Support of IC78 rig
- **Revised:** For ICOM`s users: If necessary program will ask to "Disable "CI-V Transceive" mode in your ICOM rig." (in most cases via rig menu). Refer to rig user manual for details

#### 4.207 (March 12, 2010) — UA4WLI

- **Fixed:** QSO edit
- **Fixed:** SHOW DOMESTIC MULTIPLIER NAME
- **Added:** New menu item - "Help" -> "Send bug report"
- **Added:** New special commands: CLEARDUPESHEET, CLEARMULTSHEET, BOOLSWAP=CTRL-J_BOOLEAN_COMMAND where CTRL-J_BOOLEAN_COMMAND - Ctrl-J boolean type command (i.e. BOOLSWAP=SHOW DOMESTIC MULTIPLIER NAME)

#### 4.206 (March 5, 2010) — UA4WLI

- **Fixed:** Creating new CFG file
- **Added:** New menu item - Tools -> WA7BNM
- **Added:** Auto CQ in phone mode
- **Added:** AUTO QSL INTERVAL in phone mode
- **Fixed:** Installation error
- **Fixed:** Cleaning of exchange window

#### 4.200 (February 27, 2010) — UA4WLI

- **Fixed:** Two radio mode with Winkeyer
- **Fixed:** Split mode in FT1000MP
- **Fixed:** FREQUENCY MEMORY for 160m
- **Fixed:** IC735 polling
- **Fixed:** Orion polling
- **Added:** Editable color/background of exchange window

#### 4.198 (February 14, 2010) — UA4WLI

- **Fixed:** Rewritted routines of determining of countries and multipliers

#### 4.197 (February 10, 2010) — UA4WLI

- **Added:** Editable BAND MAP CUTOFF FREQUENCY and FREQUENCY MEMORY commands

#### 4.196 (February 7, 2010) — UA4WLI

- **Added:** Use of own driver tr4wio.sys for access to parallel ports. DLPORTIO driver is no longer used
- **Fixed:** Missed STROBE signal (pin 1) at keying with parralel port
- **Added:** For observation of status of parallel port you may use tr4wlptmonitor.exe v.1.02 which is included in this release

#### 4.195 (February 2, 2010) — UA4WLI

- **Added:** Code optimization
- **Added:** New menus:
- **Added:** Usage of WK PTT line in phone mode
- **Added:** Support of K3 rig
- **Removed:** Command SERIAL PORT DEBUG is no longer supported. Use instead Portmon program.
- **Added:** Winkeyer settings stored as configuration commands in tr4w.ini file
- **Removed:** INPUT CONFIG FILE command is no longer processed
- **Fixed:** Import from ADIF file with tags in mixed case
- **Added:** Menu bar in file preview window

#### 4.192 (January 13, 2010) — UA4WLI

- **Fixed:** NO POLL DURING PTT usage
- **Removed:** Removed JST245 rig
- **Added:** New compressing method of executable file

#### 4.191 (January 11, 2010) — UA4WLI

- **Fixed:** AUTO QSO NUMBER DECREMENT usage
- **Fixed:** Multipliers calculation in BLACK SEA CUP
- **Fixed:** Truncation of the first character in CW mode
- **Added:** "Latest config file" button in start window
- **Added:** Added S48P14DC.DOM file in DOM directory
- **Fixed:** Display of TEN MINUTE RULE counter
- **Revised:** Off-time for calculation of "Operating Time" changed to 30 minutes
- **Revised:** Enabled "Help" -> "Check the latest version" menu item
- **Revised:** New appearance of "Summary" report
- **Revised:** Changed "CT1BOH info screen" window
- **Added:** Export of log to EDI format

### 2009

#### 4.187 (December 21, 2009) — UA4WLI

- **Fixed:** Loss of focus in callsign and exchange windows
- **Fixed:** Polling of FT450
- **Added:** Support of BLACK SEA CUP contest
- **Added:** Login function in networked mode - "Net" -> "Log in". Callsign of current operator displayed in log and in right bottom part of the main window

#### 4.186 (December 6, 2009) — UA4WLI

- **Added:** Support of TUNE ALT-D ENABLE command
- **Added:** "Send inactive rig to the frequency" in bandmap popup menu will tune the inactive radio to spot frequency and load the callsign into the Alt-D buffer
- **Added:** Support of DARC-10M, RADIO-MEMORY, REF-CW and REF-SSB contests
- **Added:** Support of IC-910H rig

#### 4.183 (December 4, 2009) — UA4WLI

- **Added:** Support of EXECUTE, LASTSPFREQ and LASTCQFREQ special commands
- **Added:** New menu item - Ctrl- -> Execute configuration file
- **Added:** Support of TAC (TOPS Activity Contest) contest
- **Added:** Colored spots in DX CLuster window: red color - new mult, gray color - dupe

#### 4.182 (November 26, 2009) — UA4WLI

- **Fixed:** BAND MAP CUTOFF FREQUENCY for 40m
- **Fixed:** PTT LOCKOUT with Winkeyer

#### 4.181 (November 24, 2009) — UA4WLI

- **Revised:** Network PTT lockout will work only for stations with PTT LOCKOUT=TRUE. Stations with PTT LOCKOUT=FALSE will not interfere to stations with PTT LOCKOUT=TRUE
- **Revised:** Corrected points calculation for LZLZ Qs in LZ DX contest
- **Added:** New command - DVP RECOREDER - defines a program that will be used for editing and playing audio files

#### 4.179 (November 11, 2009) — UA4WLI

- **Fixed:** Azimuth display
- **Fixed:** Dupes display in bandmap for spots coming from telnet cluster
- **Revised:** Default value of QSO BY MODE in ARRL-SS set to FALSE

#### 4.178 (November 8, 2009) — UA4WLI

- **Revised:** Leading zero for checks in Cabrillo file for ARRL-SS
- **Added:** Processing of WEIGHT command

#### 4.177 (November 3, 2009) — UA4WLI

- **Fixed:** Filling Exchange Window with previous exchanges in Ukrainian DX Contest
- **Fixed:** Serial number lockout when all client staions are in S&P mode
- **Revised:** Changed method of mode setting for Icom rigs (to fix problem with IC718)

#### 4.175 (October 31, 2009) — UA4WLI

- **Fixed:** Usage of CALLSIGN UPDATE ENABLE with more then one callsign in exchange window
- **Added:** Additional way to load in remaining mults list - use REMAININGMULTS.TXT in log path

#### 4.173 (October 29, 2009) — UA4WLI

- **Fixed:** Display of "MULT" indicator
- **Fixed:** Usage of "REMAINING MULTS" reserved keyword in cty.dat
- **Fixed:** Exhange parser in ARRL-SS contest
- **Fixed:** Zones definition for Asiatic Russia

#### 4.172 (October 29, 2009) — UA4WLI

- **Fixed:** Usage of SINGLE BAND SCORE command
- **Fixed:** Import from ADIF v.2

#### 4.169 (October 12, 2009) — UA4WLI

- **Fixed:** Winkeyer usage with old firmware

#### 4.168 (October 11, 2009) — UA4WLI

- **Fixed:** lame_enc.dll usage
- **Fixed:** Winkeyer - silence after sending n messages
- **Revised:** Changed appearance and location of new tour window in multi tours contests

#### 4.167 (October 2, 2009) — UA4WLI

- **Added:** New commands: RADIO ONE WIDE CW FILTER RADIO TWO WIDE CW FILTER Actuals for FT747GX, FT840, FT890, FT900, FT990, FT1000 rigs. Set width of CW filter

#### 4.162 (September 24, 2009) — UA4WLI

- **Revised:** Code optimization: cty.dat processing
- **Added:** Support of R9W-UW9WK-MEMORIAL contest
