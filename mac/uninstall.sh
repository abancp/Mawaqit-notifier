#!/usr/bin/env bash
set -euo pipefail

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo "Unloading macOS LaunchAgents..."
launchctl unload "$LAUNCH_AGENTS_DIR/com.mawaqit.fetch.plist" 2>/dev/null || true
launchctl unload "$LAUNCH_AGENTS_DIR/com.mawaqit.notify.plist" 2>/dev/null || true

echo "Removing LaunchAgent plists..."
rm -f "$LAUNCH_AGENTS_DIR/com.mawaqit.fetch.plist" \
      "$LAUNCH_AGENTS_DIR/com.mawaqit.notify.plist"

echo "Removing installed binaries..."
rm -f "$HOME/.local/bin/mawaqit_fetch.py" \
      "$HOME/.local/bin/prayer_notify.py" \
      "$HOME/.local/bin/mawaqit_gui.py"

read -p "Do you also want to remove configuration and cache files? (y/N): " -r answer
if [[ "${answer:-n}" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/Library/Application Support/mawaqit-notify" \
           "$HOME/Library/Caches/mawaqit-notify"
    echo "Configuration and cache removed."
fi

echo "macOS uninstall complete."
