#!/usr/bin/env bash
# packages/custom-install/jetbrains-mono-nerd-font/after.sh — runs AFTER
# the package manager step (+ AUR/Snap fallback).
#
# JetBrainsMono Nerd Font is installed natively where a patched package
# exists:
#   * macOS — brew cask  font-jetbrains-mono-nerd-font
#   * Arch  — pacman     ttf-jetbrains-mono-nerd
# Debian/apt and Fedora/dnf ship no Nerd-Font-patched package (their
# fonts-jetbrains-mono / jetbrains-mono-fonts are the unpatched upstream),
# so on those hosts we fall back to the upstream release zip, unpacked
# into the user-scoped font dir ~/.local/share/fonts/ and registered with
# fontconfig — no root, easy to remove.
#
# Idempotent: if fontconfig already sees the family (native package or a
# previous run), the hook exits 0 without downloading. Honors DRY_RUN=1.
set -euo pipefail

FONT_DIR="${HOME}/.local/share/fonts/JetBrainsMonoNerdFont"
RELEASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

# 1. Already available (native package or earlier run)? Nothing to do.
if command -v fc-list >/dev/null 2>&1 \
   && fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    echo "JetBrainsMono Nerd Font already present — skip"
    exit 0
fi

# 2. macOS provides the font through the brew cask; if fontconfig isn't
#    around to confirm it, assume brew handled it rather than dropping
#    .ttf files into a Linux-style path.
if [ "$(uname)" = "Darwin" ]; then
    echo "macOS: JetBrainsMono Nerd Font comes from the brew cask — skip"
    exit 0
fi

# 3. Linux fallback: need a downloader + unzip to fetch the release.
_dl=""
if command -v curl >/dev/null 2>&1; then _dl="curl"
elif command -v wget >/dev/null 2>&1; then _dl="wget"
fi
if [ -z "${_dl}" ] || ! command -v unzip >/dev/null 2>&1; then
    echo "need curl/wget + unzip to fetch the Nerd Font — skip"
    exit 0
fi

echo "==> install JetBrainsMono Nerd Font -> ${FONT_DIR}"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: ${_dl} ${RELEASE_URL} -> unzip '*.ttf' into ${FONT_DIR}; fc-cache -f"
    exit 0
fi

_tmp="$(mktemp -d)"
trap 'rm -rf "${_tmp}"' EXIT

if [ "${_dl}" = "curl" ]; then
    curl -fsSL "${RELEASE_URL}" -o "${_tmp}/JetBrainsMono.zip"
else
    wget -qO "${_tmp}/JetBrainsMono.zip" "${RELEASE_URL}"
fi

mkdir -p "${FONT_DIR}"
# Only the .ttf faces; skip the bundled README/LICENSE noise.
unzip -o -q "${_tmp}/JetBrainsMono.zip" '*.ttf' -d "${FONT_DIR}"

if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "${FONT_DIR}" >/dev/null 2>&1 || fc-cache -f >/dev/null 2>&1 || true
fi

echo "==> JetBrainsMono Nerd Font installed"
