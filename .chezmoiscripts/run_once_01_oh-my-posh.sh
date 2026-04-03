#!/usr/bin/env bash
set -euo pipefail

install_oh_my_posh() {
    if command -v oh-my-posh &>/dev/null; then
        echo "Oh My Posh already installed, skipping."
        return
    fi

    distro=$(~/.local/share/chezmoi/.chezmoscripts/.detect_distro.sh | tail -n1)

    case "$distro" in
        debian)
            sudo apt install -y wget unzip
            ;;
        arch)
            sudo pacman -S --noconfirm wget unzip
            ;;
    esac

    # Install latest Oh My Posh binary
    OMP_VERSION=$(curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest | \
                  grep -Po '"tag_name": "\K.*?(?=")')
    OMP_BIN="$HOME/.local/bin/oh-my-posh"

    mkdir -p "$HOME/.local/bin"
    curl -Lo "$OMP_BIN" "https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/$OMP_VERSION/posh-linux-amd64"
    chmod +x "$OMP_BIN"

    echo "Oh My Posh installed to $OMP_BIN"
}

install_oh_my_posh
