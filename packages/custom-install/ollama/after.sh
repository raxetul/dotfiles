#!/usr/bin/env bash
# packages/custom-install/ollama/after.sh — runs AFTER the package
# manager step.
#
# macOS: packages/Brewfile's `brew "ollama"` line installs the binary but
# does not start it — `brew services start` runs the formula's own launchd
# service (~/Library/LaunchAgents/homebrew.mxcl.ollama.plist), replacing
# the upstream Ollama.app server that before.sh just quit. Never touches
# ~/.ollama (20GB of models) — OLLAMA_MODELS defaults to ~/.ollama/models
# regardless of which binary runs the server.
#
# Linux: ollama IS in Arch's `extra` repo (pacman.list) and Fedora's repos
# (dnf.list) — nothing to do there. Debian/Ubuntu has no apt package, so
# this hook falls back to the `ollama` snap (NOT packages/snap.list, since
# that list installs unconditionally on Fedora too, which already has a
# native package — putting it there would double-install).
#
# Idempotent. Honors DRY_RUN=1.
set -euo pipefail

if [ "$(uname)" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1 || ! brew list --formula ollama >/dev/null 2>&1; then
        exit 0
    fi
    if brew services list 2>/dev/null | grep -qE '^ollama\s+started'; then
        exit 0
    fi
    echo "==> starting brew's ollama service"
    if [ "${DRY_RUN:-0}" = "1" ]; then
        echo "DRY-RUN: brew services start ollama"
    else
        brew services start ollama
    fi
    exit 0
fi

if command -v ollama >/dev/null 2>&1; then
    exit 0
fi

if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            if ! command -v snap >/dev/null 2>&1; then
                echo "WARN: snap not on PATH; install snapd to get ollama on this distro"
                exit 0
            fi
            echo "==> installing ollama (snap fallback — no apt package exists)"
            if [ "${DRY_RUN:-0}" = "1" ]; then
                echo "DRY-RUN: sudo snap install ollama"
            else
                sudo snap install ollama
            fi
            ;;
    esac
fi
