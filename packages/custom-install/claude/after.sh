#!/usr/bin/env bash
# packages/custom-install/claude/after.sh — runs AFTER the package
# manager step.
#
# Claude Code has no native package in any manager (brew/apt/pacman/dnf)
# and no Homebrew formula, so it's a custom install on every platform —
# which is also why it has no row on any packages/*.list. The upstream
# installer handles platform/arch detection and drops the binary in
# ~/.local/bin, already on PATH via .load's bootstrap, so claude needs
# NO .path segment.
#
# Idempotent — exits early when claude is already on PATH; the installer
# itself also no-ops when already current. Honors DRY_RUN=1.
set -euo pipefail

if command -v claude >/dev/null 2>&1; then
    exit 0
fi

echo "==> installing claude (Claude Code) into ~/.local/bin"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: curl -fsSL https://claude.ai/install.sh | bash"
    exit 0
fi
mkdir -p "${HOME}/.local/bin"
curl -fsSL https://claude.ai/install.sh | bash
