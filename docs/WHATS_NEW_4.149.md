# What's New in TR4W 4.149

### Current as of release 4.149.00 (2026-07-02)

*Consolidated by feature across all 4.149.x releases. Generated from RELEASE_NOTES.md — do not edit by hand; re-run the `monthly-changes` skill to refresh.*

## Radio Control

- **A powered-off network Icom is now shown as disconnected.** If a network-connected Icom (CI-V over IP, such as the IC-7760) is switched off, the frequency display turns red within a few seconds and TR4W reports the radio as disconnected to other apps — instead of appearing connected indefinitely. It reconnects automatically when you power the radio back on. (#1062)
- **A K4 on a serial connection now shows the correct band when you change bands on the radio.** Previously, turning to a new band updated the frequency but left the band label stuck on the old band (for example, 21.278 MHz still showing as 20m). The band now follows the frequency. (#1067)

## External Logging

- **Editing a logged QSO now reaches DXKeeper reliably.** When you edit a QSO (for example, correcting the mode), TR4W deletes the old record in DXKeeper and re-logs the corrected one. That re-log was sometimes silently dropped, so the edit never made it across. Edits now apply reliably, and the program no longer briefly freezes when you save an edit. (#957)

## Contests

- **IARU HQ multipliers updated.** Twelve HQ station abbreviations that stations actually send on the air were added, and two conflicting spellings were removed so each country counts as a single multiplier. (#1066)
