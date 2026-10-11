#!/usr/bin/env bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$HOME/.local/bin/mawaqit_gui.py" ]; then
    python3 "$HOME/.local/bin/mawaqit_gui.py"
else
    python3 "$DIR/mawaqit_gui.py"
fi
