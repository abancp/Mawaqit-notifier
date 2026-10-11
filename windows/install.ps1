param(
    [string]$MosqueUrl = "https://mawaqit.net/en/islamic-culture-centre-thiruvananthapuram-695016-india"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Installing Mawaqit Notify for Windows ===" -ForegroundColor Cyan

# 1. Detect Python
$pythonCmd = Get-Command "python.exe" -ErrorAction SilentlyContinue
$pythonPath = if ($pythonCmd) { $pythonCmd.Source } else { $null }

$pythonwCmd = Get-Command "pythonw.exe" -ErrorAction SilentlyContinue
$pythonwPath = if ($pythonwCmd) { $pythonwCmd.Source } else { $null }

if (-not $pythonPath) {
    Write-Host "Error: Python 3 not found in PATH." -ForegroundColor Red
    Write-Host "Please install Python from https://www.python.org/downloads/ and ensure 'Add python.exe to PATH' is checked during installation." -ForegroundColor Yellow
    exit 1
}

if (-not $pythonwPath) {
    $pythonwPath = $pythonPath
}

# 2. Destination directories
$appDataDir = Join-Path $env:APPDATA "mawaqit-notify"
$localCacheDir = Join-Path $env:LOCALAPPDATA "mawaqit-notify\cache"

New-Item -ItemType Directory -Force -Path $appDataDir | Out-Null
New-Item -ItemType Directory -Force -Path $localCacheDir | Out-Null

$scriptDir = $PSScriptRoot

# Copy files
Copy-Item "$scriptDir\mawaqit_fetch.py" -Destination $appDataDir -Force
Copy-Item "$scriptDir\prayer_notify.py" -Destination $appDataDir -Force
Copy-Item "$scriptDir\mawaqit_gui.py" -Destination $appDataDir -Force
Copy-Item "$scriptDir\notify_toast.ps1" -Destination $appDataDir -Force
Copy-Item "$scriptDir\Mawaqit Settings.vbs" -Destination $appDataDir -Force

# 3. Create initial config.json if not present
$configFile = Join-Path $appDataDir "config.json"
if (-not (Test-Path $configFile)) {
    $defaultConfig = @{
        mosque_url = $MosqueUrl
        notify_azan = $true
        notify_azan_before_minutes = 0
        notify_iqama = $true
        notify_iqama_before_minutes = 5
        sound_enabled = $true
    } | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($configFile, $defaultConfig, [System.Text.Encoding]::UTF8)
}

# 4. Register Scheduled Tasks
$fetchScript = Join-Path $appDataDir "mawaqit_fetch.py"
$notifyScript = Join-Path $appDataDir "prayer_notify.py"

Unregister-ScheduledTask -TaskName "MawaqitDailyFetch" -Confirm:$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "MawaqitMinuteNotify" -Confirm:$false -ErrorAction SilentlyContinue

# Task 1: Daily fetch at 00:10
$fetchAction = New-ScheduledTaskAction -Execute $pythonwPath -Argument "`"$fetchScript`""
$fetchTrigger = New-ScheduledTaskTrigger -Daily -At "00:10"
$fetchSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "MawaqitDailyFetch" -Action $fetchAction -Trigger $fetchTrigger -Settings $fetchSettings -Description "Fetches daily prayer times from Mawaqit" | Out-Null

# Task 2: Minute notify running every 1 minute
$notifyAction = New-ScheduledTaskAction -Execute $pythonwPath -Argument "`"$notifyScript`""
$notifyTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration ([TimeSpan]::MaxValue)
$notifySettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName "MawaqitMinuteNotify" -Action $notifyAction -Trigger $notifyTrigger -Settings $notifySettings -Description "Runs Mawaqit prayer check every minute" | Out-Null

# 5. Create Desktop Shortcut for Settings GUI
try {
    $wsh = New-Object -ComObject WScript.Shell
    $desktop = [System.Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop "Mawaqit Prayer Settings.lnk"
    $vbsPath = Join-Path $appDataDir "Mawaqit Settings.vbs"

    $shortcut = $wsh.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "wscript.exe"
    $shortcut.Arguments = "`"$vbsPath`""
    $shortcut.WorkingDirectory = $appDataDir
    $shortcut.Description = "Configure Mawaqit Prayer Notifications"
    $shortcut.Save()
} catch {
    Write-Host "Could not create desktop shortcut automatically. You can launch $appDataDir\mawaqit_gui.py" -ForegroundColor Yellow
}

Write-Host "Running initial prayer time fetch..." -ForegroundColor Yellow
& $pythonPath $fetchScript

# Test Toast
try {
    & powershell -ExecutionPolicy Bypass -File "$appDataDir\notify_toast.ps1" -Title "Mawaqit Notify Installed" -Message "Mawaqit Notify is now running on Windows!" -PlaySound $true
} catch {}

Write-Host ""
Write-Host "=== Installation Complete (Windows) ===" -ForegroundColor Green
Write-Host "• Installed to:       $appDataDir"
Write-Host "• Cache directory:    $localCacheDir"
Write-Host "• Scheduled Tasks:    MawaqitDailyFetch, MawaqitMinuteNotify (Active)"
Write-Host "• Desktop Shortcut:   'Mawaqit Prayer Settings.lnk'"
Write-Host "• Launch settings:    Run 'pythonw `"$appDataDir\mawaqit_gui.py`"' or click the Desktop shortcut"
