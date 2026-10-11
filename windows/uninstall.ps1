Write-Host "=== Uninstalling Mawaqit Notify for Windows ===" -ForegroundColor Cyan

# 1. Unregister Scheduled Tasks
Write-Host "Unregistering scheduled tasks..."
Unregister-ScheduledTask -TaskName "MawaqitDailyFetch" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MawaqitMinuteNotify" -Confirm:$false -ErrorAction SilentlyContinue

# 2. Remove Desktop Shortcut
$desktop = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop "Mawaqit Prayer Settings.lnk"
if (Test-Path $shortcutPath) {
    Remove-Item -Path $shortcutPath -Force -ErrorAction SilentlyContinue
}

# 3. Clean files
$appDataDir = Join-Path $env:APPDATA "mawaqit-notify"
$localCacheDir = Join-Path $env:LOCALAPPDATA "mawaqit-notify\cache"

$choice = Read-Host "Do you also want to remove configuration and prayer cache? (y/N)"
if ($choice -eq "y" -or $choice -eq "Y") {
    if (Test-Path $appDataDir) { Remove-Item -Path $appDataDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $localCacheDir) { Remove-Item -Path $localCacheDir -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "Configuration and cache removed." -ForegroundColor Green
} else {
    # Keep config but remove scripts
    Remove-Item -Path "$appDataDir\*.py" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$appDataDir\*.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$appDataDir\*.vbs" -Force -ErrorAction SilentlyContinue
}

Write-Host "Mawaqit Notify uninstalled successfully." -ForegroundColor Green
