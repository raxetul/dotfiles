#!/usr/bin/env bash
# herdr-team-teardown.sh — when a team LEAD exits, close its member panes first.
#
# THE PROBLEM
#   A lead spawns members with `herdr agent start` (via scripts/claude-worktree).
#   When the lead's own Claude session exits, its pane closes but the member
#   panes stay behind: live Claude processes with nobody orchestrating them,
#   occupying the workspace layout. Nothing tears them down, because herdr has
#   no parent/child relationship between panes — the team structure lives only
#   in the leader-left / members-right geometry.
#
# WHAT THIS DOES
#   Registered as a Claude Code `SessionEnd` hook. On a real exit, and ONLY
#   when the exiting session is the lead of its own workspace, it closes every
#   member pane in that workspace before the lead's own pane goes away.
#
# WHY THE LEAD CHECK IS THE WHOLE DESIGN
#   This hook fires in EVERY Claude session, members included. A member running
#   the teardown would close its lead and its siblings — catastrophic. So two
#   INDEPENDENT signals must both agree that this session is the lead:
#
#     1. NAME. A member is started as `herdr agent start <label>`, so it has an
#        agent name. A lead is a pane someone ran `claude` in by hand, so its
#        `herdr agent list` entry has `name: null`. Verified on herdr's live
#        output: leads show name=null, members show name=<role>.
#     2. GEOMETRY. The lead is the LEFTMOST pane of its tab (min rect.x), which
#        is exactly how scripts/claude-worktree itself identifies the leader
#        when placing a new member. Members always sit at x > leader.x.
#
#   Either signal failing means "do nothing" — this fails safe in the direction
#   of leaving panes open, never in the direction of closing someone else's.
#
# WHICH PANES COUNT AS MEMBERS
#   Agents in MY workspace, with a pane id other than mine, that HAVE a name.
#   The name requirement is deliberate: a pane a human opened and ran `claude`
#   in has no name, so it is left alone. Only properly spawned members (via
#   `claude-worktree` / `herdr-team spawn`) are torn down. Plain shell panes
#   never appear in `herdr agent list` at all.
#
# WHICH SessionEnd REASONS COUNT AS AN EXIT
#   Claude Code's reason enum is clear|resume|logout|prompt_input_exit|other
#   (read out of the 2.1.x binary). `clear` (/clear) and `resume` end the
#   SESSION while the PROCESS and its pane live on — tearing the team down there
#   would be plain wrong. Everything else means the process is going away.
#
# ENV
#   HERDR_TEAM_TEARDOWN=all   close every member (DEFAULT)
#                       idle   close only members that are not `working`
#                       off    do nothing
#   DRY_RUN=1                  log what would happen, close nothing
#
# Exit is ALWAYS 0. A cleanup hook must never be the reason a session cannot
# quit.
set -uo pipefail

LOG_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
LOG_FILE="${LOG_DIR}/herdr-team-teardown.log"

log() {
    mkdir -p "${LOG_DIR}" 2>/dev/null || return 0
    printf '%s  %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >>"${LOG_FILE}" 2>/dev/null || true
}

payload=""
if [ ! -t 0 ]; then
    payload="$(cat 2>/dev/null || true)"
fi

mode="${HERDR_TEAM_TEARDOWN:-all}"
case "${mode}" in
    off) exit 0 ;;
    all|idle) ;;
    *) log "unknown HERDR_TEAM_TEARDOWN='${mode}' — treating as 'all'"; mode="all" ;;
esac

# Not inside a herdr-managed pane, or missing the tools to resolve anything:
# there is no team to tear down. Silence is correct here, not a warning.
[ "${HERDR_ENV:-}" = "1" ] || exit 0
[ -n "${HERDR_PANE_ID:-}" ] || exit 0
[ -n "${HERDR_WORKSPACE_ID:-}" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

own_pane="${HERDR_PANE_ID}"
own_ws="${HERDR_WORKSPACE_ID}"

reason=""
if [ -n "${payload}" ]; then
    reason="$(printf '%s' "${payload}" | jq -r '.reason // empty' 2>/dev/null || true)"
fi

case "${reason}" in
    clear|resume)
        # Session ended, process did not. Nothing to tear down.
        exit 0 ;;
esac

agents="$(herdr agent list 2>/dev/null || true)"
[ -n "${agents}" ] || exit 0

# --- Lead check, signal 1: I must be an UNNAMED agent in my own workspace ----
own_name="$(printf '%s' "${agents}" \
    | jq -r --arg ws "${own_ws}" --arg p "${own_pane}" '
        .result.agents[]? | select(.workspace_id == $ws and .pane_id == $p)
        | (.name // "") ' 2>/dev/null | head -n1)"
if [ -n "${own_name}" ]; then
    # I have an agent name, so I was spawned as a member. Members never tear down.
    exit 0
fi

# --- Lead check, signal 2: I must be the leftmost pane of my tab -------------
leftmost="$(herdr pane layout --pane "${own_pane}" 2>/dev/null \
    | jq -r '.result.layout.panes | sort_by(.rect.x, .rect.y) | .[0].pane_id // empty' \
      2>/dev/null || true)"
if [ -z "${leftmost}" ] || [ "${leftmost}" != "${own_pane}" ]; then
    log "not the leftmost pane of my tab (leftmost='${leftmost}', me='${own_pane}') — no teardown"
    exit 0
fi

# --- Collect members ---------------------------------------------------------
members="$(printf '%s' "${agents}" \
    | jq -r --arg ws "${own_ws}" --arg p "${own_pane}" '
        .result.agents[]?
        | select(.workspace_id == $ws)
        | select(.pane_id != $p)
        | select((.name // "") != "")
        | "\(.pane_id)\t\(.name)\t\(.agent_status // "unknown")" ' 2>/dev/null || true)"

if [ -z "${members}" ]; then
    exit 0
fi

log "lead ${own_pane} exiting (reason='${reason:-unknown}', mode=${mode}) — tearing down members"

closed=0
skipped=0
while IFS=$'\t' read -r pane name status; do
    [ -n "${pane}" ] || continue

    # Belt and braces: never act on a pane id outside my own workspace, even
    # though the jq filter already scoped it. herdr ids are workspace-prefixed.
    case "${pane}" in
        "${own_ws}:"*) ;;
        *) log "  SKIP ${pane} (${name}) — id not prefixed with my workspace ${own_ws}"
           skipped=$((skipped + 1)); continue ;;
    esac

    if [ "${mode}" = "idle" ] && [ "${status}" = "working" ]; then
        log "  SKIP ${pane} (${name}) — still working, mode=idle"
        skipped=$((skipped + 1)); continue
    fi

    if [ "${DRY_RUN:-0}" = "1" ]; then
        log "  DRY_RUN would close ${pane} (${name}, status=${status})"
        continue
    fi

    if herdr pane close "${pane}" >/dev/null 2>&1; then
        log "  closed ${pane} (${name}, status=${status})"
        closed=$((closed + 1))
    else
        log "  FAILED to close ${pane} (${name}) — already gone?"
        skipped=$((skipped + 1))
    fi
done <<EOF
${members}
EOF

log "teardown done: ${closed} closed, ${skipped} skipped"
exit 0
