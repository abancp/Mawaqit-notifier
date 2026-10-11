#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
CONFIG_DIR="$HOME/.config/mawaqit-notify"
APP_DIR="$HOME/.local/share/applications"
MOSQUE_URL="${1:-https://mawaqit.net/en/islamic-culture-centre-thiruvananthapuram-695016-india}"

if ! command -v python3 >/dev/null; then
    echo "Error: python3 not found. Please install Python 3." >&2
    exit 1
fi

if ! command -v notify-send >/dev/null; then
    echo "Warning: notify-send not found." >&2
    echo "  Arch:   sudo pacman -S libnotify" >&2
    echo "  Debian/Ubuntu: sudo apt install libnotify-bin" >&2
    echo "  Fedora: sudo dnf install libnotify" >&2
fi

mkdir -p "$BIN_DIR" "$SYSTEMD_DIR" "$CONFIG_DIR" "$APP_DIR"

# Copy executables
cp "$SCRIPT_DIR/mawaqit_fetch.py" "$SCRIPT_DIR/prayer_notify.py" "$SCRIPT_DIR/mawaqit_gui.py" "$BIN_DIR/"
chmod +x "$BIN_DIR/mawaqit_fetch.py" "$BIN_DIR/prayer_notify.py" "$BIN_DIR/mawaqit_gui.py"

# Write default config if not present
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    cat > "$CONFIG_DIR/config.json" << EOF
{
  "mosque_url": "$MOSQUE_URL",
  "notify_azan": true,
  "notify_azan_before_minutes": 0,
  "notify_iqama": true,
  "notify_iqama_before_minutes": 5,
  "sound_enabled": true
}
EOF
fi

# Install systemd service and timer files
cp "$SCRIPT_DIR"/systemd/*.service "$SCRIPT_DIR"/systemd/*.timer "$SYSTEMD_DIR/"

systemctl --user daemon-reload
systemctl --user enable --now mawaqit-fetch.timer
systemctl --user enable --now mawaqit-notify.timer

# Create Desktop Application Launcher
cat > "$APP_DIR/mawaqit-settings.desktop" << EOF
[Desktop Entry]
Name=Mawaqit Prayer Settings
Comment=Configure Mawaqit prayer notifications and view times
Exec=$BIN_DIR/mawaqit_gui.py
Icon=alarm-symbolic
Terminal=false
Type=Application
Categories=Utility;Clock;
EOF
chmod +x "$APP_DIR/mawaqit-settings.desktop"

echo "Running initial prayer time fetch..."
"$BIN_DIR/mawaqit_fetch.py" || {
    echo "Initial fetch encountered an issue. Checking offline cache..." >&2
}

echo ""
echo "=== Installation Complete (Linux) ==="
echo "• Cache directory: $HOME/.cache/mawaqit-notify/"
echo "• Config file:     $CONFIG_DIR/config.json"
echo "• Schedulers:      systemd user timers (mawaqit-fetch, mawaqit-notify)"
echo "• Settings UI:     Run '$BIN_DIR/mawaqit_gui.py' or open 'Mawaqit Prayer Settings' from your app menu"
