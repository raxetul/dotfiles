#!/usr/bin/env bash
# herdr-workspace-guard.sh — PreToolUse (Bash) guard against cross-workspace
# member leaks.
#
# The bug it kills: `herdr agent start` without a workspace/tab pin places the
# new pane relative to GLOBAL focus, not the pane that launched it. So a lead
# spawning a member while focus sits in another project drops that member into
# the WRONG workspace — "a pane of one project opening in another's workspace".
#
# The rule: every member spawn must be scoped to the lead's OWN workspace, i.e.
# the command must carry `--workspace …` or `--tab …`. herdr exports the lead
# pane's identity into this shell as HERDR_WORKSPACE_ID / HERDR_TAB_ID, so the
# fix is always `--workspace "${HERDR_WORKSPACE_ID}"` (scripts/claude-worktree
# does this automatically). If a spawn omits both, we DENY it and tell the
# agent exactly how to re-run it — so an un-pinned spawn can never execute.
#
# Registered as a PreToolUse hook (matcher: Bash) in settings.json. Only
# `herdr agent start` is policed; every other Bash command passes through.
set -euo pipefail

input="$(cat)"

# The command the Bash tool is about to run (raw, pre-expansion). Any parse
# problem → allow, so the guard can never wedge unrelated commands.
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

# Cheap reject: the phrase isn't here at all → nothing to police.
case "$cmd" in
  *"herdr agent start"*) ;;
  *) exit 0 ;;
esac

# Drop the member's prompt tail (everything from the first ` -- ` on) so free
# text passed to `-- claude "<prompt>"` — which may itself mention the phrase —
# can never be mistaken for a shell command.
head="${cmd%% -- *}"

# Only police a REAL invocation: `herdr agent start` at a command position —
# line start or after a shell separator (; & | && ||), allowing an optional
# run of VAR=val env-assignments and/or the `command` builtin. This ignores
# incidental mentions inside quotes (commit messages, echoed JSON, docs).
spawn_re='(^|[;&|]|&&|\|\|)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(command[[:space:]]+)?herdr[[:space:]]+agent[[:space:]]+start([[:space:]]|$)'
printf '%s\n' "$head" | grep -Eq "$spawn_re" || exit 0

deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

ws="${HERDR_WORKSPACE_ID:-}"

# A member is workspace-scoped iff the spawn carries --workspace or --tab
# (herdr tab ids are workspace-prefixed, so --tab pins the workspace too).
if printf '%s' "$cmd" | grep -Eq -- '(^|[[:space:]])--(workspace|tab)([[:space:]]|=)'; then
  exit 0
fi

deny "herdr-workspace-guard: this 'herdr agent start' has no --workspace/--tab, so the member would land in whichever workspace currently has focus (the cross-workspace leak), not your own (${ws:-unknown}). Re-run it pinned to your workspace: add --workspace \"\${HERDR_WORKSPACE_ID}\" — or use scripts/claude-worktree, which pins it for you."
