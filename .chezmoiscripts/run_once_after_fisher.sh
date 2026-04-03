#!/usr/bin/env bash
set -euo pipefail

install_fisher() {
    if ! command -v fish &>/dev/null; then
        echo "fish shell not installed."
        return
    fi

    fish -c 'if not type -q fisher; curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher; end'

    fish_plugins=(
        "jorgebucaran/fish-nvm"
        "jethrokuan/z"
        "PatrickF1/fzf.fish"
    )

    for plugin in "${fish_plugins[@]}"; do
        fish -c "fisher install $plugin || true"
    done
}

install_fisher
