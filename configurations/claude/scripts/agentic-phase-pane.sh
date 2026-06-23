#!/usr/bin/env bash
# agentic-phase-pane.sh — SessionStart hook: open a mini bottom tmux pane showing
# the project's agentic phase status, but only when:
#   * we're running inside tmux, and
#   * the project (the session cwd) actually defines phases, and
#   * such a pane isn't already open.
#
# Reads the hook's JSON payload from stdin to learn the session cwd.

set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASES="$SELF_DIR/agentic-phases.sh"
MARKER="agentic-phases"            # pane title used to dedupe
PANE_HEIGHT="${AGENTIC_PHASES_PANE_HEIGHT:-5}"

# Never let this hook break a session.
exit_ok() { exit 0; }
trap exit_ok ERR

# Only act inside tmux.
[ -n "${TMUX:-}" ] || exit_ok

# Read cwd from the hook payload (fall back to $PWD).
dir="$PWD"
if command -v jq >/dev/null 2>&1; then
  payload="$(cat 2>/dev/null || true)"
  d="$(printf '%s' "$payload" | jq -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)"
  [ -n "$d" ] && dir="$d"
fi
[ -d "$dir" ] || exit_ok

# Only when this project defines phases.
"$PHASES" detect "$dir" >/dev/null 2>&1 || exit_ok

# Don't open a second pane if one already exists (any window in this session).
if tmux list-panes -s -F '#{pane_title}' 2>/dev/null | grep -qx "$MARKER"; then
  exit_ok
fi

# Open a small pane at the bottom running the live status strip.
# -d keeps focus in the Claude pane; -P -F captures the new pane id so we can title it.
pane_id="$(tmux split-window -d -v -l "$PANE_HEIGHT" -P -F '#{pane_id}' \
  "exec '$PHASES' watch '$dir'" 2>/dev/null || true)"
[ -n "$pane_id" ] && tmux select-pane -t "$pane_id" -T "$MARKER" 2>/dev/null || true

exit_ok
