#!/usr/bin/env bash
# 1. Install Nix in multi-user (daemon) mode if it isn't already present.
# 2. Activate Home Manager for the current $USER / $HOME / system.
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)

if ! command -v nix >/dev/null 2>&1; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
fi

if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

mkdir -p "${HOME}/.config/nix"
grep -qs 'experimental-features.*flakes' "${HOME}/.config/nix/nix.conf" 2>/dev/null \
    || echo "experimental-features = nix-command flakes" >> "${HOME}/.config/nix/nix.conf"

nix run --impure home-manager/master -- \
    switch --impure --flake "${DIR}#default" -b backup
