#!/usr/bin/env bash
set -euo pipefail

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|kubuntu)
                echo "debian"
                ;;
            arch|garuda)
                echo "arch"
                ;;
            *)
                echo "unsupported OS"
                exit 1
                ;;
        esac
    else
        echo "unsupported OS"
        exit 1
    fi
}
