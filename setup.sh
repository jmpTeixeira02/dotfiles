#!/usr/bin/env bash
TARGET_HOST="${1:-}"
TARGET_ADDR="${2:-localhost}"

if [ -n "$TARGET_HOST" ]; then
    read -p "This will FORMAT and ERASE all drives specified in your disko.nix config. Continue? [y/N]: " -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        exit 1
    fi

    echo "==> Paste your SOPS age private key for '${TARGET_HOST}', then press Enter two times to finish:"
    KEY=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        KEY="${KEY}${line}"$'\n'
    done
    echo # newline after silent input, since terminal won't have echoed one
    [ -n "$KEY" ] || {
        echo "==> No key entered, aborting."
        exit 1
    }

    temp=$(mktemp -d)
    cleanup() {
        rm -rf "$temp"
    }
    trap cleanup EXIT
    install -d -m700 "$temp/var/lib/sops-nix"
    printf '%s\n' "$KEY" >"$temp/var/lib/sops-nix/key.txt"
    chmod 600 "$temp/var/lib/sops-nix/key.txt"

    PHASES="disko,install,reboot"
    [ "$TARGET_ADDR" != "localhost" ] && PHASES="kexec,$PHASES"

    nix --extra-experimental-features "nix-command flakes" \
        run github:nix-community/nixos-anywhere -- \
        --extra-files "$temp" \
        --phases "$PHASES" \
        --flake "./nix#${TARGET_HOST}" \
        --generate-hardware-config nixos-generate-config ./nix/hosts/homelab/hardware-configuration.nix \
        --target-host "nixos@${TARGET_ADDR}"
else
    echo "==> Target is not 'homelab'. Installing Determinate Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
fi
