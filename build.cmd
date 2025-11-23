@echo off
SETLOCAL
set SCRIPT_DIR=%~dp0
set POWERSHELL_EXE=powershell

%POWERSHELL_EXE% -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build.ps1"
ENDLOCAL
