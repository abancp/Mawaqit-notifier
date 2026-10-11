@echo off
setlocal
cd /d "%~dp0"
echo Starting Mawaqit Notify Windows Installer...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Installation encountered an error.
    pause
    exit /b %ERRORLEVEL%
)
echo.
echo Press any key to close this window...
pause >nul
