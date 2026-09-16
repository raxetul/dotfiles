#!/usr/bin/env bash
# packages/custom-install/herdr/after.sh — runs AFTER the package manager
# installs or upgrades herdr.
#
# Installing a new herdr binary does NOT upgrade the herdr server that is
# already running. The old process keeps serving every pane until it is
# restarted, so right after an update run the machine sits in a split state:
#
#     client 0.9.0  (the binary just installed)  ->  every `herdr` you type
#     server 0.7.1  (the process still running)  ->  every pane you are in
#
# Once the protocol generations diverge, socket-API commands start failing with
# `protocol_mismatch` — `herdr agent start`, `herdr pane send-text`, and so the
# whole scripts/herdr-team + claude-worktree path with them.
#
# This hook only WARNS. Restarting a session exits every process in its panes,
# which is never acceptable as a side effect of an update run — the user runs
# `herdr-upgrade` when they have saved their work and are ready.
#
# No $HOME/.dotfiles/path segment is needed: herdr lands in the Homebrew prefix
# on macOS and in ~/.local/bin on Linux, and both are already on PATH.
#
# Read-only, so DRY_RUN=1 changes nothing about its behaviour.
set -euo pipefail

if ! command -v herdr >/dev/null 2>&1; then
    echo "herdr not on PATH — skip"
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not on PATH — cannot check the running server, skip"
    exit 0
fi

status="$(herdr status --json 2>/dev/null || true)"
if [ -z "$status" ]; then
    echo "no herdr status available (no server running?) — skip"
    exit 0
fi

running="$(printf '%s' "$status" | jq -r '.server.running // false | tostring')"
if [ "$running" != "true" ]; then
    echo "no herdr server running — nothing to restart"
    exit 0
fi

stale="$(printf '%s' "$status" | jq -r '(.update.server_binary_stale // .update.restart_needed // false) | tostring')"
if [ "$stale" != "true" ]; then
    echo "herdr server is current — nothing to do"
    exit 0
fi

client_version="$(printf '%s' "$status" | jq -r '.client.version // "unknown"')"
server_version="$(printf '%s' "$status" | jq -r '.server.version // "unknown"')"

cat <<WARNING

  !! herdr was updated, but the RUNNING SERVER is still on the old binary.

       installed (client): ${client_version}
       running   (server): ${server_version}

     Panes keep working, but socket-API commands (herdr agent / pane, and so
     scripts/herdr-team and scripts/claude-worktree) may fail with
     'protocol_mismatch' until the server is restarted.

     Restart it when you are ready — this exits every process in every pane:

         herdr-upgrade            # see what would happen, then confirm
         herdr-upgrade --help     # options, including --dry-run

WARNING
