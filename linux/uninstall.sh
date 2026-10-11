#!/usr/bin/env bash
set -euo pipefail

echo "Stopping and disabling systemd timers..."
systemctl --user disable --now mawaqit-fetch.timer mawaqit-notify.timer 2>/dev/null || true

echo "Removing systemd service & timer files..."
rm -f "$HOME/.config/systemd/user/mawaqit-fetch.service" \
      "$HOME/.config/systemd/user/mawaqit-fetch.timer" \
      "$HOME/.config/systemd/user/mawaqit-notify.service" \
      "$HOME/.config/systemd/user/mawaqit-notify.timer"

systemctl --user daemon-reload

echo "Removing binaries..."
rm -f "$HOME/.local/bin/mawaqit_fetch.py" \
      "$HOME/.local/bin/prayer_notify.py" \
      "$HOME/.local/bin/mawaqit_gui.py" \
      "$HOME/.local/share/applications/mawaqit-settings.desktop"

read -p "Do you also want to delete configuration and cached prayer times? (y/N): " -r answer
if [[ "${answer:-n}" =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.config/mawaqit-notify" "$HOME/.cache/mawaqit-notify"
    echo "Configuration and cache removed."
fi

echo "Uninstalled successfully."
