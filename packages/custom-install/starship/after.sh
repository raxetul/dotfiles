#!/usr/bin/env bash
# packages/custom-install/starship/after.sh — runs AFTER the package
# manager step.
#
# starship is in packages/Brewfile, pacman.list and dnf.list, so
# brew/pacman/dnf already installed it. Only apt (Debian/Ubuntu/Mint)
# lacks it — there we fall back to the upstream release-binary
# installer, dropping the binary into ~/.local/bin. That dir is already
# on PATH via .load's bootstrap, so starship needs NO .path segment.
#
# Idempotent — exits early when starship is already on PATH. Honors
# DRY_RUN=1.
set -euo pipefail

if command -v starship >/dev/null 2>&1; then
    exit 0
fi

echo "==> installing starship into ~/.local/bin"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin --yes"
    exit 0
fi
mkdir -p "${HOME}/.local/bin"
curl -sS https://starship.rs/install.sh \
    | sh -s -- --bin-dir "${HOME}/.local/bin" --yes
