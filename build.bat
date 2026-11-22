@echo off
setlocal
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0scripts\build-rbz.ps1"
exit /b %ERRORLEVEL%
