@echo off
setlocal
cd /d "%~dp0"
echo Starting Mawaqit Notify Windows Uninstaller...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
pause
