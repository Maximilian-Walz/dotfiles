#!/usr/bin/env bash
set -euo pipefail

set_fish_default() {
    FISH_BIN=$(command -v fish)
    if [ "$SHELL" = "$FISH_BIN" ]; then
        echo "Fish is already the default shell."
        return
    fi

    # Add fish to /etc/shells if missing
    if ! grep -Fxq "$FISH_BIN" /etc/shells; then
        echo "$FISH_BIN" | sudo tee -a /etc/shells
    fi

    # Change default shell for current user
    chsh -s "$FISH_BIN"
    echo "Default shell changed to fish."
}

set_fish_default
