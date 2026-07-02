@echo off
REM Any arguments are forwarded to FullBuild.ps1, e.g.:
REM   utils\build.cmd -VerboseCompile   (show all dcc32 hints/warnings)
powershell.exe -ExecutionPolicy Bypass -File tr4w\FullBuild.ps1 %*