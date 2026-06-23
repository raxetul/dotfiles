#!/usr/bin/env bash
# packages/custom-install/lefthook/after.sh — runs AFTER the package
# manager step (+ AUR/Snap fallback).
#
# lefthook ships via brew (macOS) and AUR `lefthook-bin` (Arch, in
# packages/aur.list, installed by the linux-fallback stage that runs
# before this hook), but is absent from apt and dnf repos. On
# Debian/Ubuntu/Mint/Fedora we fall back to the GitHub release binary,
# dropping it in ~/.local/bin — already on PATH via .load's bootstrap,
# so lefthook needs NO .path segment.
#
# GitHub asset names embed the version (lefthook_<ver>_Linux_<arch>.gz),
# so /releases/latest/download/<name> 404s — we resolve the tag via the
# API first. A bare `command -v` returns true for any file on PATH, even
# a 0-byte or non-executable leftover from a previous failed install, so
# we treat lefthook as "missing" unless the resolved path is a real,
# non-empty executable.
#
# Idempotent. Honors DRY_RUN=1.
set -euo pipefail

[ "$(uname)" = "Linux" ] || exit 0

lh_path="$(command -v lefthook 2>/dev/null || true)"
if [ -n "${lh_path}" ] && [ -x "${lh_path}" ] && [ -s "${lh_path}" ]; then
    exit 0
fi

echo "==> installing lefthook into ~/.local/bin"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: resolve latest lefthook release + download → ~/.local/bin/lefthook"
    exit 0
fi

# Remove a broken leftover (0-byte / non-executable) before reinstalling.
[ -n "${lh_path}" ] && rm -f "${lh_path}"
mkdir -p "${HOME}/.local/bin"

arch="$(uname -m)"
case "${arch}" in
    x86_64) arch_tag="x86_64" ;;
    aarch64|arm64) arch_tag="arm64" ;;
    *) arch_tag="${arch}" ;;
esac

lh_ver="$(curl -fsSL https://api.github.com/repos/evilmartians/lefthook/releases/latest \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')"
if [ -z "${lh_ver}" ]; then
    echo "WARN: could not resolve latest lefthook version from GitHub API"
    exit 0
fi

lh_url="https://github.com/evilmartians/lefthook/releases/download/v${lh_ver}/lefthook_${lh_ver}_Linux_${arch_tag}.gz"
tmp="$(mktemp)"
if curl -fsSL "${lh_url}" | gunzip > "${tmp}" && [ -s "${tmp}" ]; then
    install -m 0755 "${tmp}" "${HOME}/.local/bin/lefthook"
else
    echo "WARN: lefthook download failed (${lh_url})"
fi
rm -f "${tmp}"
