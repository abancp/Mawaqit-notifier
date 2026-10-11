# mawaqit-notify

Automated prayer time (Adhan) and Iqamah desktop notifications from [Mawaqit](https://mawaqit.net) for **Linux**, **macOS**, and **Windows**.

Fetches your mosque's daily timetable, sends clean native desktop notifications for both **Adhan (Azan)** and **Iqamah (Iqamat)** at custom reminder intervals, plays a standard system notification chime (no harsh alarms or extra audio files needed), and includes an automatic **offline fallback to yesterday's cached times** if internet is unavailable.

---

## Features

- 🕌 **Adhan & Iqamah Notifications**: Configurable alerts for both Adhan and Iqamah with independent reminder timings (e.g., at Adhan time, 5 minutes before Iqamah).
- 🔔 **Standard Notification Sound**: Clean, platform-native notification chimes (Linux system sound / canberra chime, macOS native alert, Windows 10/11 default Toast chime). Harsh alarms and heavy audio files are eliminated.
- 📴 **Offline Fallback**: If internet connection is unavailable on any day, the system automatically detects this and loads yesterday's prayer times for today with an offline status alert. You never miss prayers due to network outages.
- ⚙️ **Cross-Platform Settings UI**: Includes a graphical settings panel (`mawaqit_gui.py`) built with Python Tkinter (zero third-party pip dependencies required).
- 🕒 **Native System Schedulers**:
  - **Linux**: `systemd` user services & timers.
  - **macOS**: `launchd` LaunchAgents.
  - **Windows**: Windows Task Scheduler (`schtasks`).

---

## Directory Structure

```text
mawaqit-notify/
├── linux/                  # Linux scripts, systemd units, installer & GUI
│   ├── install.sh
│   ├── uninstall.sh
│   ├── mawaqit_fetch.py
│   ├── prayer_notify.py
│   ├── mawaqit_gui.py
│   └── systemd/
├── mac/                    # macOS scripts, launchd plists, installer & GUI
│   ├── install.sh
│   ├── uninstall.sh
│   ├── mawaqit_fetch.py
│   ├── prayer_notify.py
│   ├── mawaqit_gui.py
│   ├── Mawaqit Settings.command
│   └── launchd/
├── windows/                # Windows scripts, PowerShell toast, installer & GUI
│   ├── install.bat
│   ├── install.ps1
│   ├── uninstall.bat
│   ├── uninstall.ps1
│   ├── mawaqit_fetch.py
│   ├── prayer_notify.py
│   ├── mawaqit_gui.py
│   ├── notify_toast.ps1
│   └── Mawaqit Settings.vbs
└── README.md
```

---

## 🐧 Linux Installation Guide

### 1. Prerequisites

Ensure Python 3, `libnotify` (for `notify-send`), and Tkinter (for the Settings UI) are installed:

- **Arch Linux / Manjaro**:
  ```bash
  sudo pacman -S python python-notify2 libnotify tk sound-theme-freedesktop
  ```
  *If using Hyprland or Sway, ensure a notification daemon like `mako` or `dunst` is installed:*
  ```bash
  sudo pacman -S mako
  ```

- **Ubuntu / Debian / Mint**:
  ```bash
  sudo apt update
  sudo apt install python3 python3-tk libnotify-bin
  ```

- **Fedora / RHEL**:
  ```bash
  sudo dnf install python3 python3-tkinter libnotify
  ```

### 2. Install

Navigate to the `linux` folder and run `install.sh` with your mosque's Mawaqit URL:

```bash
cd linux
chmod +x install.sh uninstall.sh
./install.sh "https://mawaqit.net/en/your-mosque-url"
```

*What the installer does:*
1. Installs scripts to `~/.local/bin/`.
2. Creates config file at `~/.config/mawaqit-notify/config.json`.
3. Sets up and enables systemd user timers:
   - `mawaqit-fetch.timer`: Runs daily at 00:10 to cache today's times to `~/.cache/mawaqit-notify/today.json`.
   - `mawaqit-notify.timer`: Runs every 1 minute to check prayer times and fire notifications.
4. Registers `Mawaqit Prayer Settings` in your desktop application launcher (`~/.local/share/applications/mawaqit-settings.desktop`).

### 3. Wayland / Hyprland Note

If systemd user services do not trigger notifications under Wayland/Hyprland, ensure DBus and Wayland environment variables are imported. Add this near the top of your `hyprland.conf`:

```ini
exec-once = systemctl --user import-environment WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE
exec-once = hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR
```

### 4. Open Settings UI

Launch the settings UI anytime from your terminal or app menu:

```bash
~/.local/bin/mawaqit_gui.py
```

### 5. Verification & Troubleshooting

Check systemd timer statuses:
```bash
systemctl --user status mawaqit-fetch.timer mawaqit-notify.timer
```

View live logs:
```bash
journalctl --user -u mawaqit-fetch.service -u mawaqit-notify.service -f
```

Test notifications manually:
```bash
~/.local/bin/prayer_notify.py --test-azan
~/.local/bin/prayer_notify.py --test-iqama
```

### 6. Uninstall

```bash
cd linux && ./uninstall.sh
```

---

## 🍎 macOS Installation Guide

### 1. Prerequisites

macOS includes AppleScript notifications out-of-the-box. You only need **Python 3**:

```bash
# Check if python3 is available:
python3 --version

# If not installed, install via Homebrew:
brew install python3
```

### 2. Install

Open Terminal, navigate to the `mac` folder, and run `install.sh`:

```bash
cd mac
chmod +x install.sh uninstall.sh "Mawaqit Settings.command"
./install.sh "https://mawaqit.net/en/your-mosque-url"
```

*What the installer does:*
1. Installs scripts to `~/.local/bin/`.
2. Creates configuration at `~/Library/Application Support/mawaqit-notify/config.json`.
3. Configures and activates `launchd` LaunchAgents:
   - `~/Library/LaunchAgents/com.mawaqit.fetch.plist` (daily at 00:10).
   - `~/Library/LaunchAgents/com.mawaqit.notify.plist` (repeats every 60 seconds).
4. Sends a test notification to ensure macOS notification center permissions are initialized.

### 3. Open Settings UI

Double-click `mac/Mawaqit Settings.command` in Finder or run in Terminal:

```bash
python3 ~/.local/bin/mawaqit_gui.py
```

### 4. Verification & Logs

Check loaded LaunchAgents:
```bash
launchctl list | grep mawaqit
```

View logs:
```bash
tail -f ~/Library/Logs/mawaqit-notify.log
tail -f ~/Library/Logs/mawaqit-fetch.log
```

Test alerts:
```bash
~/.local/bin/prayer_notify.py --test-azan
~/.local/bin/prayer_notify.py --test-iqama
```

### 5. Uninstall

```bash
cd mac && ./uninstall.sh
```

---

## 🪟 Windows Installation Guide

### 1. Prerequisites

1. Install **Python 3** from [python.org/downloads](https://www.python.org/downloads/) or the Microsoft Store.
2. ⚠️ **Important during installation**: Check the box **"Add python.exe to PATH"**.

### 2. Install

#### Option A (One-Click Batch Installer):
1. Open the `windows` folder in File Explorer.
2. Double-click `install.bat`.

#### Option B (PowerShell):
Open PowerShell and run:
```powershell
cd windows
powershell -ExecutionPolicy Bypass -File .\install.ps1 -MosqueUrl "https://mawaqit.net/en/your-mosque-url"
```

*What the installer does:*
1. Installs scripts and helpers to `%APPDATA%\mawaqit-notify`.
2. Creates config file `%APPDATA%\mawaqit-notify\config.json`.
3. Registers two tasks in **Windows Task Scheduler**:
   - `MawaqitDailyFetch`: Runs daily at 00:10 to fetch and cache today's prayer times.
   - `MawaqitMinuteNotify`: Runs every 1 minute in the background without opening command prompt windows.
4. Generates a desktop shortcut: `Mawaqit Prayer Settings.lnk`.
5. Sends an initial Windows Toast notification with standard chime.

### 3. Open Settings UI

Double-click the **Mawaqit Prayer Settings** shortcut on your Desktop, or run:

```cmd
pythonw "%APPDATA%\mawaqit-notify\mawaqit_gui.py"
```

### 4. Verification & Troubleshooting

Check scheduled tasks in PowerShell:
```powershell
Get-ScheduledTask -TaskName "Mawaqit*"
```

Test Toast alerts:
```cmd
python "%APPDATA%\mawaqit-notify\prayer_notify.py" --test-azan
python "%APPDATA%\mawaqit-notify\prayer_notify.py" --test-iqama
```

### 5. Uninstall

Double-click `windows\uninstall.bat` or run:
```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```

---

## Configuration Options

Settings can be changed anytime via the **Graphical Settings UI** or by directly editing `config.json`:

- **Linux**: `~/.config/mawaqit-notify/config.json`
- **macOS**: `~/Library/Application Support/mawaqit-notify/config.json`
- **Windows**: `%APPDATA%\mawaqit-notify\config.json`

```json
{
  "mosque_url": "https://mawaqit.net/en/islamic-culture-centre-thiruvananthapuram-695016-india",
  "notify_azan": true,
  "notify_azan_before_minutes": 0,
  "notify_iqama": true,
  "notify_iqama_before_minutes": 5,
  "sound_enabled": true
}
```

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `mosque_url` | string | default | Mawaqit mosque page URL |
| `notify_azan` | boolean | `true` | Enable or disable notifications for Adhan |
| `notify_azan_before_minutes` | integer | `0` | Minutes before Adhan to notify (`0` = at exact Adhan time) |
| `notify_iqama` | boolean | `true` | Enable or disable notifications for Iqamah |
| `notify_iqama_before_minutes` | integer | `5` | Minutes before Iqamah to notify (e.g. `5` min before) |
| `sound_enabled` | boolean | `true` | Plays the standard system notification chime (`false` for silent) |

---

## How Offline Fallback Works

1. **Daily Fetch**: Whenever `mawaqit_fetch.py` executes successfully, it archives the previous day's timetable into `yesterday.json` before writing `today.json`.
2. **Offline Detection**: If internet connection drops, DNS fails, or Mawaqit is temporarily unreachable:
   - The fetch script locates `yesterday.json` (or the previous valid cache).
   - It updates the schedule for today's date and sets `"offline_fallback": true`.
   - Sends a desktop notification informing you: *"Internet unavailable today. Using yesterday's prayer times."*
3. **Continuous Operation**: `prayer_notify.py` seamlessly proceeds with yesterday's times so you are notified on time even without an active internet connection.
