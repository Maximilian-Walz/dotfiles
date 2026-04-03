#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------
# Paths
# ------------------------------------------
PKG_ROOT="$HOME/.local/share/chezmoi/.chezmoidata/packages"
SELECTION_FILE="$HOME/.local/share/chezmoi/.chezmoidata/package_selections.yaml"

# ------------------------------------------
# Detect Linux distro
# ------------------------------------------
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu) echo "debian" ;;
            arch|manjaro|garuda) echo "arch" ;;
            *) echo "unsupported" ;;
        esac
    else
        echo "unsupported"
    fi
}

DISTRO=$(detect_distro)
[ "$DISTRO" != "unsupported" ] || { echo "Unsupported Linux distro"; exit 1; }
echo "Detected distro: $DISTRO"

# ------------------------------------------
# Install minimal tools if missing
# ------------------------------------------
install_if_missing() {
    local pkg="$1"
    case "$DISTRO" in
        debian) dpkg -s "$pkg" &>/dev/null || sudo apt install -y "$pkg" ;;
        arch) pacman -Qi "$pkg" &>/dev/null || sudo pacman -S --noconfirm "$pkg" ;;
    esac
}

echo "Installing minimal bootstrap tools..."
for pkg in git curl wget fish unzip tar; do
    install_if_missing "$pkg"
done

# ------------------------------------------
# Ensure Go yq is installed
# ------------------------------------------
install_yq() {
    if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -q "mikefarah"; then
        return
    fi

    case "$DISTRO" in
        debian)
            echo "Installing yq (Go version) for Debian..."
            sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
            sudo chmod +x /usr/local/bin/yq
            ;;
        arch)
            echo "Installing go-yq for Arch..."
            sudo pacman -S --noconfirm go-yq
            ;;
    esac
}

install_yq

# ------------------------------------------
# Ensure selection file exists
# ------------------------------------------
mkdir -p "$(dirname "$SELECTION_FILE")"
[ -s "$SELECTION_FILE" ] || echo '{}' > "$SELECTION_FILE"

# ------------------------------------------
# Stage 1: YAML-driven package installation
# ------------------------------------------
echo "Installing packages..."
for yaml_file in "$PKG_ROOT"/*.yaml; do
    [ -f "$yaml_file" ] || continue

    GROUP=$(basename "$yaml_file" .yaml)
    OPTIONAL=$(yq e '.optional // false' "$yaml_file")
    DESCRIPTION=$(yq e '.description // ""' "$yaml_file")
    INSTALL_GROUP="true"

    if [ "$OPTIONAL" = "true" ]; then
        STORED=$(yq e ".${GROUP} // \"unset\"" "$SELECTION_FILE")
        if [ "$STORED" = "unset" ]; then
            if [ "${CHEZMOI_FORCE:-}" != "true" ]; then
                if [ -n "$DESCRIPTION" ]; then
                    read -rp "Install optional group '$GROUP' ($DESCRIPTION)? [y/N]: " CONFIRM
                else
                    read -rp "Install optional group '$GROUP'? [y/N]: " CONFIRM
                fi
                INSTALL_GROUP="false"
                [[ "$CONFIRM" =~ ^[Yy]$ ]] && INSTALL_GROUP="true"
            fi
            yq e -i ".${GROUP} = ${INSTALL_GROUP}" "$SELECTION_FILE"
        else
            INSTALL_GROUP="$STORED"
        fi
    fi

    [ "$INSTALL_GROUP" = "true" ] || continue

    # Collect packages safely
    mapfile -t COMMON_PKGS < <(yq e '.common[]?' "$yaml_file" | sed '/^\s*$/d')
    mapfile -t OS_PKGS < <(yq e ".${DISTRO}[]?" "$yaml_file" | sed '/^\s*$/d')
    
    # Merge and deduplicate
    mapfile -t ALL_PKGS < <(printf "%s\n%s\n" "${COMMON_PKGS[@]}" "${OS_PKGS[@]}" | sed '/^\s*$/d' | sort -u)
    
    # Install packages safely
    for pkg in "${ALL_PKGS[@]}"; do
        [ -n "$pkg" ] || continue
        install_if_missing "$pkg"
    done
done

echo "Bootstrap complete!"
