# What's New in TR4W 4.148

### Current as of release 4.148.17 (2026-06-22)

*Consolidated by feature across all 4.148.x releases. Generated from RELEASE_NOTES.md — do not edit by hand; re-run the `monthly-changes` skill to refresh.*

## Radio Control

- Network radio setup is more reliable: each model now has the correct default network port and discovery behavior, and switching between models (e.g. IC-7760 → K4) no longer leaves a stale port. (#1028)
- **Find your radio on the network automatically**: a new "Discover" button in the Radio 1 / Radio 2 setup dialog scans your local network and fills in the radio's IP address for you. It works for the Elecraft K4 and Icom network radios, and now finds a radio on any subnet your PC is on. (#853)
- **Correct default network port per radio**: when you choose a network radio type, TR4W pre-fills the right TCP port for that model (K4, FlexRadio, Kenwood TS-890/TS-990, Icom) so you don't have to look it up. (#968)
- **Cleaner setup**: leaving a network port blank no longer throws a confusing "invalid statement" error, and a radio with no address set no longer floods the log with connection retries.
- **The radio configuration window's Reset button now fully resets the form** — clearing the IP address and TCP port, setting keyer RTS/DTR to OFF, and restoring the radio name to its default — the **Close button is now labeled Cancel**, and closing with the **X** asks before discarding unapplied changes.
- **CW-by-CAT now keys short messages reliably on the Elecraft K3/KX3/K4.** Sending a short CW message like `?` or `AGN` over CAT could silently fail to key on the K3; it now keys consistently. (#1057)
- **The frequency display turns red when a serial radio goes quiet.** If a serial-connected radio stops answering CAT polling (about 3 seconds), the main-window frequency shows in red so you can see at a glance that the rig isn't responding; it clears once it answers again. (#1055)

## Radio Control — Kenwood TS-890 over LAN

- The band and mode shown in TR4W now follow the radio. Previously only the frequency tracked the rig — the band display, band table, and mode wouldn't update when you changed bands on the radio (and startup could show NONSSB). (#959)
- The RIT/XIT offset (the actual amount of clarifier shift) is now displayed, not just the on/off state.
- When you switch the radio's operating VFO (A/B), TR4W now follows it correctly — per-VFO modes no longer appear swapped, the main window tracks the receive VFO's frequency/band/mode, and the Radio 1 window highlights the active VFO.
- CW sent to the TS-890 over CAT is no longer zero-padded, which also corrects the reported keying length.
- Connecting to a radio over a VPN no longer times out — the connection window was too short for a VPN's slightly longer handshake, so a rig that worked on the local network would report "Connect timed out" over VPN. (#959)

## SO2R / Radio Mode

- **One radio-mode setting**: the old, conflicting "Single Radio Mode" and "Two Radio Mode" options are now a single **TWO RADIO MODE** setting (TRUE = two radios / SO2R, FALSE = single radio). Existing configuration files still load — and if both old settings happen to be present, TWO RADIO MODE now wins, so a stray leftover line can't silently put you in the wrong mode. (#965)

## Band Map

- Double-clicking a spot no longer occasionally clears the callsign it just loaded into the call window. (This only showed up with "jump to S&P when you tune" / AUTO S&P enabled.) (#1048)
- **Two-radio bandmap highlight restored**: in two-radio mode the bandmap again highlights the inactive (search-and-pounce) radio's band and grays the running radio's band — the SO2R behavior from before 4.147. (#960)

## CW

- Setting **`CW ENABLE = FALSE` now actually keeps CW off** from startup — the display and keying agree, with no need to toggle CW off then on (Alt-K) twice. (#1047)
- CW enable / disable / toggle now behaves consistently (driven by a single internal switch). (#380)
- **The "resend last CW message" key is now Ctrl+= (was `=`).** The plain `=` key collided with Quick QSL Key 2; resend last message is now Ctrl+= while in CW mode in the call/exchange fields. (#1054)

## Digital / FT8 / WSJT-X

- In a digital mode (for example FT8 via WSJT-X), **typing a callsign no longer keys CW**. (#1040)
- **Band follows WSJT-X when you have no rig connected**: if no radio is set up in TR4W, switching bands in WSJT-X now moves TR4W to the matching band (band indicator, totals row, and band map all update). With a radio connected, nothing changes. (#978)
- **WSJT-X contacts log again**: a recent change had stopped WSJT-X-logged contacts (FT8/FT4, ARRL-DIGI, etc.) from being recorded in TR4W. They now log correctly. (#975)
- **Operator now recorded on WSJT-X contacts**: WSJT-X QSOs now fill in the operator / computer-ID column just like hand-logged contacts.
- **Operator-mismatch alert**: if the operator set in WSJT-X differs from the operator set in TR4W, you'll get a flashing on-screen warning and a beep when the contact logs, so you can fix whichever one is wrong. A blank operator in WSJT-X won't trigger it. (#977)

## DX Cluster

- **Copy/paste works in the command field**: Ctrl-V (paste), Ctrl-C (copy), and Ctrl-X (cut) now work while typing a cluster command — previously only right-click → Paste did. (#23)
- **Connecting no longer freezes TR4W**: the cluster connection runs in the background, so connecting to a slow or unreachable host no longer locks up the program. You get immediate feedback — "Connecting to host:port", the Connect button grays out and Disconnect enables — and a clear "Could not connect to host:port" if it fails (the full technical reason is saved to the log).
- **Fixed a crash** that could occur when a long connection-error message was displayed.
- **Polish**: status messages are no longer green, and Freeze turns off each time you connect so you always return to live spots. A new **TELNET DEBUG** setting logs cluster traffic for troubleshooting.
- **Insert your station info into cluster commands automatically**: lines in your `cluster_commands.txt` can now contain placeholders like `{MY_CALL}`, `{MY_STATE}`, `{MY_GRID}`, `{BAND}`, `{FREQ}`, `{DATE}` or `{TIME}` (and more). When you pick the command from the cluster window's **Commands** button, the placeholder is replaced with the current value before the command is sent — so one command file works no matter who's operating or what band you're on. Hover over a command to preview exactly what will be sent. To include a literal brace in a command, double it (`{{` or `}}`). (#973)

## Rotator Control

- **PSTRotator support**: a new rotator type, **PSTROTATOR**, points your antenna through PSTRotator over the network. Set ROTATOR TYPE = PSTROTATOR and the PSTROTATOR IP ADDRESS / UDP PORT (defaults 127.0.0.1 : 12000). (#732)
- **Long-path turn**: **Alt-Ctrl-P** turns the rotator to the long path; **Ctrl-P** still turns short path. (#20)
- With debug logging at TRACE, the exact commands sent to the rotator are now logged for troubleshooting. (#989)

## Function Keys

- You can now **right-click a function key to edit that key's message** directly — it picks the right CQ vs Search-and-Pounce message for your current mode. (#1001)
- Right-clicking a function key while holding **Alt or Ctrl** no longer pops up a spurious menu. (#1007)

## Send From Keyboard

- Fixed a **Send Keyboard Input dialog that could open duplicated or refuse to close**. (#1006)

## Search & Pounce

- The F1 send-call label shows **"Call" instead of "DE+Call" when DE is disabled** (`DE ENABLE = FALSE`). (#1012)

## Data Entry / Exchange

- When an exchange you type **can't be parsed, the cursor now lands right after the part it didn't understand**, so you can correct it without hunting for it. (#1010)
- **Clearer domestic-QTH error**: when an entered section/QTH isn't recognized for a domestic contest, the message now reads **"Invalid ARRL Section"** instead of a generic, misspelled prompt.

## Cabrillo & Log Export

- **Field Day ADIF records no longer carry a duplicate sent-exchange tag.** ARRL Field Day and Winter Field Day exports were writing the sent exchange twice per record; now it appears once. (#1050)
- **More accurate state in exported ADIF.** TR4W no longer guesses a station's state from a two-letter exchange, which previously mislabeled ARRL-section contests (a section like "EB" was wrongly written as state "EB"). Field Day and Winter Field Day now derive the correct state from the section (e.g. WCF → FL) and tag the country. Sweepstakes and ARRL 160 export the section only for now; their state will follow once a related section-naming fix lands (#1052).
- **ADIF export no longer writes "Error generating my exchange" in the sent-exchange field.** Exporting your log to ADIF had been putting that error text into the sent-exchange (`STX_STRING`) of every record. The sent exchange is now exported correctly for all contests. Re-export an affected log after upgrading to clean it up. (#1049)
- If a contest's exchange isn't handled by the Cabrillo generator, that line is now **flagged with an error marker (and logged) instead of written blank**, so it can't slip by unnoticed. (#1043)
- **CSV export no longer writes stray duplicate lines** for skipped, deleted, or non-QSO records.
- **Category choices match the current Cabrillo spec**: the contest category drop-downs are updated — Transmitter offers **TWO**, Mode adds **FM**, Time adds **8-HOURS**, Overlay drops OVER-50 and adds **YOUTH** and **YL**, and Station adds **DISTRIBUTED**, **ROVER-LIMITED**, **ROVER-UNLIMITED**, and **EXPLORER**. (#976)
- **Station, Time, and Overlay categories now stick**: Station Category is now a drop-down, and your Time and Overlay choices are remembered the next time you open the Cabrillo Summary — previously they weren't saved.
- **OK closes the export dialog**: clicking **OK** in the Cabrillo Summary now finishes the export and closes the dialog. Previously a successful export left the dialog open, so you had to click Cancel to get out.

## VHF

- ARRL January, June, and September VHF now produce the proper **RST + grid exchange** in the Cabrillo file.

## Reports & Scoring

- **Friendly contest names**: the summary sheet and score report now show a readable contest name in parentheses next to the contest, for roughly 130 contests. (#967)

## Contests

- **TESLA contest renamed HF-TESLA**: the TESLA Memorial HF CW Contest now appears as **HF-TESLA**, with the correct Cabrillo name. (#745)

## Log Window

- The **bottom row of the log window is no longer cut off** — it shows fully with a clean border, at every row-count setting. (#1046)

## Display

- A **stuck exchange-error message** (for example, an improper Field Day class) now clears once you log the corrected QSO. (#1030)
- **Windows saved on a monitor you've since disconnected now come back on-screen.** If TR4W starts and a window was on a monitor that's no longer there (laptop undocked, second display off, or resolution changed), it's brought back onto an available monitor instead of opening off-screen where you can't reach it. Several recovered windows fan out so they don't stack on top of each other. (#739)
- **Your multi-monitor layout is preserved.** If a window is auto-recovered but you don't move it, TR4W keeps its original spot saved — so when you reconnect that monitor, the window returns to where you had it. Move a recovered window and that new position sticks instead.
- **Windows on a monitor placed to the left of (or above) your main screen now save their position correctly** — previously those could revert to the primary monitor.
- **Plug or unplug a monitor while TR4W is running and your windows keep up.** If a monitor disappears mid-session, any window on it moves onto an active monitor immediately — no restart needed. Plug the monitor back in and an untouched window returns to where you had it on its own; if you'd already moved a recovered window, it stays where you put it. (#1060)

## Crash Recovery

- **The restart file is saved after each QSO again.** The **UPDATE RESTART FILE ENABLE** setting — which had quietly been doing nothing for years — now works and is **on by default**, so after an unexpected shutdown TR4W restores more of your latest operating state. Set `UPDATE RESTART FILE ENABLE = FALSE` if you'd rather it only save on operator change, log load, and exit. (#950)

## Configuration Files

- **`#` now works as a comment**: you can disable a line in a configuration file by starting it with `#` (in addition to the existing `;`). Previously a line beginning with `#` produced a "config file error."

## Multi-Op / Networking

- While the network server is unreachable, the log **no longer fills with repeated "trying / failed to connect" messages**. (#1041)

## Parallel-Port (LPT) Keying

- The installer no longer includes inpout32.dll — the component several antivirus engines flagged as a "vulnerable driver," which is what caused some browsers and antivirus tools to block the download. Serial, USB, and network keying and rig control are completely unaffected. If you use direct parallel-port (LPT) keying, footswitch, paddle, or band-data output, you now supply inpout32.dll yourself: download it from highrez.co.uk and place it in the same folder as tr4w.exe. If you have an LPT port configured but the file isn't present, TR4W now shows a reminder and keeps running, instead of failing to start.

## Super Check Partial

- The bundled callsign database (TRMASTER.DTA) has been refreshed again for better Super Check Partial suggestions as you type.

## Usability

- **Previewed files open in your default text editor**: log/summary/Cabrillo/ADIF previews (and the History file) now open in whatever editor you've set for .txt files — Notepad++, VS Code, etc. — instead of always Notepad. (#986)
- Fixed a typo in the QSO Number pop-up (Ctrl-/ → Additional Information): it read "QSO nuber" and now reads "QSO number." (#962)

## Translations

- **Spanish**: translation refinements. (#992)

## Bundled Data

- The **DX cluster list (TRCLUSTER.DAT) is refreshed each monthly build**, and a fresh copy ships with this release. (#391)

## Under the Hood / For Contributors

- Continued removal of legacy inline assembly across the radio, formatting, and utility code for the Delphi 12 / 64-bit migration — no on-air change. (#997)
- The monthly-release script is more robust: a one-step MonthlyBuild command, hardened tagging that can't tag a stale build, and a fix to an internal bug that made the release script hang.
