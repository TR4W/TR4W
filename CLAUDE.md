# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

TR4W is a free amateur radio contest logging application for Windows, written in Delphi 7 (Object Pascal). It's a feature-rich logging program supporting 120+ contests with multi-user networking, extensive radio control, and digital mode integration. The codebase is approximately 109,000 lines across 117 units.

**Website:** https://tr4w.net

## Build System

### Requirements
- **Borland Delphi 7** (32-bit compiler) - Required for compilation
- Windows development environment
- Delphi command-line compiler (DCC32.EXE) or Delphi 7 IDE

### Compilation

Build with `tr4w\FullBuild.ps1` (runs unit tests, builds ENG via DCC32 into `tr4w\target\`). Always invoke as:
```
powershell.exe -ExecutionPolicy Bypass -File tr4w\FullBuild.ps1
```
Useful switches: `-AllLanguages` (the other 8 langs; POL/CHN excluded, #925), `-ParallelLanguages`, `-BuildInstallers` (NSIS; UPX only with `-UseUpx`), `-VerboseCompile` (hints/warnings + full rebuild).
Tool paths come from `-Delphi7Bin`/`$env:DELPHI7_BIN`, `-NSISBin`/`$env:NSIS_BIN`, `-IndyRoot`/`$env:INDY_ROOT` (bundled Indy default).

Quick compile only (no tests/langs): from `tr4w\`, run `dcc32.exe tr4w.dpr` -- `tr4w.cfg` supplies unit paths and `-E target`; `tr4w\BatchCompile.cmd` does the same but hardcodes `C:\tr4w`. CI is the self-hosted `win-ci` runner running `FullBuild.ps1` (`.github/workflows/release.yml`). More: `docs/WINDOWS_BUILD_RUNNER.md` (compiler config, ssh/scp workflow), `docs/RELEASE_WORKFLOW.md`.

Monthly release: `utils\MonthlyBuild.cmd <version>` wraps `tr4w\build\Invoke-Release.ps1` (refresh CTY/TRMASTER, bump Version.pas, local FullBuild, commit, push master, tag `v<version>-all` -> CI installers). Add `-DryRun` to rehearse. Interim CI tag: `utils\TagIt.cmd <version>`.

### Language Support
The application supports 11 languages via conditional compilation. Language is selected by the `LANG` constant in `src/VC.pas`:
```pascal
const LANG = 'ENG';  // Options: ENG, RUS, SER, ESP, MNG, POL, CZE, ROM, CHN, GER, UKR
```

Each language has a corresponding resource file in `res/` (e.g., `tr4w_eng.res`).

## Architecture Overview

### Hybrid Architecture: Legacy Core + Modern Windows

TR4W uses a **two-layer architecture**:

1. **TRDOS Layer** (`src/trdos/`) - Legacy DOS-based contest logging engine ported to Windows
2. **Windows Layer** (`src/`) - Modern Windows UI and integration features

This design preserves battle-tested contest logic while enabling modern features.

### No Traditional Framework
- **Direct Win32 API** - No VCL (Visual Component Library) framework
- **Event-driven** message loop architecture
- Heavy use of **global variables** for state management
- Pascal **records** instead of classes for data structures
- Manual memory and resource management

### Key Entry Points

**tr4w.dpr** (Main program, 865 lines)
- Program entry point with main message loop (lines 658-856)
- Window procedure `WindowProc()` (lines 136-295)
- Initialization of all subsystems
- Message dispatching and event handling

**MainUnit.pas** (Core application controller)
- Main window creation and management
- Keyboard/mouse input processing
- UI updates and display coordination
- Integration point between trdos and modern features

### Debugging

**Enable debug logging:**
In `settings/tr4w.ini`:
```ini
[COMMANDS]
DEBUG LOG LEVEL = DEBUG  # Options: NONE, FATAL, ERROR, WARN, INFO, DEBUG, TRACE
```

**Log file:** `tr4w.log` in program directory

**Debug mode compilation:**
Set in `VC.pas`:
```pascal
const tDebugMode = True;
```

## Critical Notes for AI Assistants

1. **Respect the TRDOS boundary:** Files in `src/trdos/` are stable, battle-tested contest logic. Avoid modifications unless absolutely necessary. Prefer creating new units in `src/` for new features.

2. **Global state is everywhere:** Unlike modern applications, TR4W uses extensive global variables shared across units. Changes to global state can have wide-ranging effects.

3. **No modern OOP framework:** Don't expect classes, inheritance, or design patterns common in modern Delphi/C++/Java. This is procedural Pascal with Win32 API calls.

4. **Circular dependencies:** The `uses` clauses create circular dependencies between units. The compiler handles this via `interface` and `implementation` sections. Be aware when adding new cross-unit references.

5. **VC.pas is the source of truth:** When in doubt about types, constants, or enums, check `VC.pas`. It's the central type definition unit.

6. **Version management:** Update `Version.pas` when making releases:
   ```pascal
   TR4W_CURRENTVERSION_NUMBER = '4.xxx.x';
   TR4W_CURRENTVERSIONDATE = 'Month, Year';
   ```

7. **Testing:** No automated test framework exists. Testing is manual and typically done during actual contests. Be especially careful with changes to scoring, multiplier tracking, and exchange parsing.

8. **Multi-language support:** When adding UI strings, add entries to ALL language resource files in `res/`, not just English.

## License

TR4W is licensed under GPL v2 or later. See copyright headers in source files.
