#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/Library/Application Support/mawaqit-notify"
CACHE_DIR="$HOME/Library/Caches/mawaqit-notify"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOGS_DIR="$HOME/Library/Logs"
MOSQUE_URL="${1:-https://mawaqit.net/en/islamic-culture-centre-thiruvananthapuram-695016-india}"

echo "=== Installing Mawaqit Notify for macOS ==="

if ! command -v python3 >/dev/null; then
    echo "Error: python3 not found. Please install Python 3 (e.g., brew install python3 or from python.org)." >&2
    exit 1
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$CACHE_DIR" "$LAUNCH_AGENTS_DIR" "$LOGS_DIR"

# Copy python scripts
cp "$SCRIPT_DIR/mawaqit_fetch.py" "$SCRIPT_DIR/prayer_notify.py" "$SCRIPT_DIR/mawaqit_gui.py" "$BIN_DIR/"
chmod +x "$BIN_DIR/mawaqit_fetch.py" "$BIN_DIR/prayer_notify.py" "$BIN_DIR/mawaqit_gui.py"
chmod +x "$SCRIPT_DIR/Mawaqit Settings.command"

# Create default configuration if not present
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

# Prepare and copy LaunchAgent plists with current $HOME expanded
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/launchd/com.mawaqit.fetch.plist" > "$LAUNCH_AGENTS_DIR/com.mawaqit.fetch.plist"
sed "s|__HOME__|$HOME|g" "$SCRIPT_DIR/launchd/com.mawaqit.notify.plist" > "$LAUNCH_AGENTS_DIR/com.mawaqit.notify.plist"

# Unload old instances if present, then load new ones
launchctl unload "$LAUNCH_AGENTS_DIR/com.mawaqit.fetch.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.mawaqit.notify.plist" 2>/dev/null || true

launchctl load "$LAUNCH_AGENTS_DIR/com.mawaqit.fetch.plist"
launchctl load "$LAUNCH_AGENTS_DIR/com.mawaqit.notify.plist"

echo "Running initial prayer time fetch..."
python3 "$BIN_DIR/mawaqit_fetch.py" || {
    echo "Initial fetch encountered an issue. Checking offline cache..." >&2
}

# Trigger a test notification so macOS prompts for notification permissions if needed
osascript -e 'display notification "Mawaqit Notify successfully installed on macOS!" with title "Mawaqit Notify" sound name "default"'

echo ""
echo "=== Installation Complete (macOS) ==="
echo "• Scripts installed to: $BIN_DIR"
echo "• Config file:          $CONFIG_DIR/config.json"
echo "• Cache directory:      $CACHE_DIR"
echo "• LaunchAgents:         ~/Library/LaunchAgents/com.mawaqit.*.plist (Active)"
echo "• Logs:                 ~/Library/Logs/mawaqit-*.log"
echo "• Settings UI:          Double click '$SCRIPT_DIR/Mawaqit Settings.command' or run '$BIN_DIR/mawaqit_gui.py'"
