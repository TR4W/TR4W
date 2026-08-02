@echo off
REM ===========================================================================
REM  build_trmaster.cmd  --  monthly TRMASTER.DTA build for TR4W
REM
REM  Produces  tools\trmaster\TRMASTER.DTA  and STOPS.  It never touches
REM  tr4w\target\ -- copying the result into place is YOUR deploy step.
REM
REM  Pipeline:
REM    1. download supercheckpartial SCP.DB (MASTER.DTA + CWops auto-download)
REM    2. build pass 1: MASTER universe + curated seed/rosters + callsign-history
REM       name files, US/UK/CA QRZ-verified prune  ->  identifies the calls that
REM       STILL need names (history already names ~24k, so QRZ has far fewer)
REM    3. QRZ name resolver fills the still-bare calls (cached; cheap on re-runs)
REM    4. build pass 2: same inputs + the QRZ names  ->  TRMASTER.DTA
REM
REM  Inputs that carry history (back these up; see README):
REM    seed\TRMASTER_seed.DTA                  curated names / FOC / HSC / orphans
REM    seed\*.txt (ICWC-MST / K1USN / VE2FK)   curated on-air name files (drop
REM                                            updated copies here monthly)
REM    %USERPROFILE%\.publicLogProcessor\qrz_name_cache.json   accumulated QRZ names
REM ===========================================================================

setlocal
cd /d "%~dp0"

set "PYTHON=python"
set "WORK=_work"
set "SEED=seed\TRMASTER_seed.DTA"
set "OUT=TRMASTER.DTA"
set "SCPDB=%WORK%\SCP.DB"
set "NAMES=%WORK%\qrz_names.csv"
set "QRZ_LIMIT=5000"
set "CWOPS_URL=https://docs.google.com/spreadsheets/d/1Ew8b1WAorFRCixGRsr031atxmS0SsycvmOczS_fDqzc/export?format=csv"

REM --- callsign-history name files (drop updated copies into seed\ monthly). --
REM  Pattern order = priority (ICWC > K1USN > VE2FK); each pattern resolves to
REM  its single newest match, so a fresh drop supersedes the prior month.
set "HISTORY=--history-glob seed\ICWC-MST-*.txt --history-glob seed\K1USNSST-*.txt --history-glob seed\Names_VE2FK-*.txt"

REM --- force-include list: legitimate calls QRZ does not list (Ofcom WRTC -------
REM  special-event calls). Added to the universe AFTER the prune so they survive.
REM  Same file the slideshow reads. Empty it after the event to stop including.
set "INCLUDE=--include-file wrtc2026.txt"

if not exist "%WORK%" mkdir "%WORK%"

REM --- the curated seed is a required, one-time input (never read from target) -
if not exist "%SEED%" (
    echo ERROR: missing curated seed "%SEED%".
    echo One-time setup: copy your curated TRMASTER.DTA there, e.g.
    echo     mkdir seed ^&^& copy "your_curated_TRMASTER.DTA" "%SEED%"
    goto :error
)

REM --- 1. refresh SCP.DB (used for the QRZ-verified prune) --------------------
echo [1/4] downloading SCP.DB ...
curl -sL --fail -o "%SCPDB%" https://supercheckpartial.com/downloads/SCP.DB || goto :error

REM --- 2. first build (downloads MASTER.DTA + CWops; --force = fresh) ---------
echo [2/4] build pass 1 (universe + rosters + prune) ...
"%PYTHON%" trmaster_build.py --out "%OUT%" --existing "%SEED%" ^
    --download-master --force --cwops-url "%CWOPS_URL%" %HISTORY% %INCLUDE% ^
    --prune-qrz-unverified "%SCPDB%" || goto :error

REM --- 3. QRZ name resolution for the bare calls (skips cleanly if no creds) --
echo [3/4] QRZ name lookups (limit %QRZ_LIMIT%) ...
"%PYTHON%" trmaster_names_qrz.py --dta "%OUT%" --out "%NAMES%" ^
    --limit %QRZ_LIMIT% --sleep 0.2 || goto :error

REM --- 4. final build with names --------------------------------------------
echo [4/4] build pass 2 (with QRZ names) ...
"%PYTHON%" trmaster_build.py --out "%OUT%" --existing "%SEED%" ^
    --download-master --cwops-url "%CWOPS_URL%" %HISTORY% %INCLUDE% ^
    --prune-qrz-unverified "%SCPDB%" --names-csv "%NAMES%" || goto :error

echo.
echo Done.  Built:  %~dp0%OUT%
echo Deploy step (yours):  copy "%~dp0%OUT%"  to  tr4w\target\TRMASTER.DTA
echo (First month: re-run step 3 a few times to backfill the ~44k bare names.)
endlocal
exit /b 0

:error
echo.
echo *** build_trmaster FAILED (errorlevel %errorlevel%). ***
endlocal
exit /b 1
