@echo off
SETLOCAL
set SCRIPT_DIR=%~dp0
set POWERSHELL_EXE=powershell

echo Als Smart App Control dit bestand blokkeert, voer in PowerShell uit: Unblock-File .\build.cmd, .\build.ps1
%POWERSHELL_EXE% -ExecutionPolicy Bypass -File "%SCRIPT_DIR%build.ps1"
ENDLOCAL
