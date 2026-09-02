#!/usr/bin/env bash
# packages/custom-install/ollama/before.sh — runs BEFORE the package
# manager step.
#
# macOS only: this machine originally ran ollama via the upstream
# Ollama.app installer (/usr/local/bin/ollama symlinked into
# /Applications/Ollama.app/...), not brew. The repo owner approved moving it
# to the brew formula on 2026-09-02, brew being their stated first lane.
# Both bind the same
# 127.0.0.1:11434 port, so the .app-managed server is quit here, BEFORE
# brew installs/starts the formula, to avoid a port conflict.
#
# This does NOT touch ~/.ollama (20GB of models) or delete Ollama.app —
# only the running process is stopped. macOS "Open at Login" for the app
# is NOT modified here (too fragile to automate reliably); if it's
# enabled, remove it by hand in System Settings > General > Login Items,
# or this hook will just quit it again on the next run.
#
# Idempotent — no-ops when the app isn't running. Honors DRY_RUN=1.
set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
    exit 0
fi

if ! pgrep -qx Ollama; then
    exit 0
fi

echo "==> quitting the upstream Ollama.app so brew's ollama can own the port"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: osascript -e 'quit app \"Ollama\"'"
    echo "DRY-RUN: pkill -x ollama (the 'ollama serve' child, if still running)"
    exit 0
fi
osascript -e 'quit app "Ollama"' >/dev/null 2>&1 || true
sleep 1
pkill -x ollama 2>/dev/null || true
