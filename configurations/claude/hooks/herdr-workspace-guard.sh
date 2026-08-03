#!/usr/bin/env bash
# herdr-workspace-guard.sh — PreToolUse (Bash) guard against cross-workspace
# team contamination.
#
# Two confirmed leak vectors, both DENIED (not just warned) here:
#
#   1. SPAWN leak: `herdr agent start` without --workspace/--tab places the new
#      pane relative to GLOBAL focus, not the pane that launched it. A lead
#      spawning a member while focus sits in another project drops that member
#      into the WRONG workspace.
#   2. TARGETING leak: `herdr agent send|read|get|focus|wait|attach|rename` and
#      the equivalent `herdr pane …` commands accept ANY "unique agent name" or
#      pane/tab id as target, and that resolution is GLOBAL — it does not stop
#      at a workspace boundary. A follow-up meant for a member in your own
#      workspace can silently land on a same-named/ambiguous-looking pane that
#      turns out to live in someone else's workspace. Two independent leads can
#      have the exact same project checked out (same cwd) in two different
#      workspaces — cwd is never proof of team membership.
#
# The fix in both cases: every spawn AND every targeted send/read/focus/etc.
# must be pinned to the caller's OWN workspace, which herdr exports into this
# shell as HERDR_WORKSPACE_ID (HERDR_PANE_ID for the pane). Concretely:
#
#   A. `herdr agent start` — requires --workspace "$HERDR_WORKSPACE_ID" (or a
#      --tab value prefixed "$HERDR_WORKSPACE_ID:"). A --workspace pointed at
#      ANY other id is now denied too — previously any value passed.
#   B. `herdr agent send|read|get|focus|wait|attach|rename` and
#      `herdr pane send-text|send-keys|run|read|close|zoom|rename|get|split|
#      move|swap|resize|focus` — the target must resolve to the caller's own
#      workspace. herdr ids are workspace-prefixed ("w3:p1", "w3:t1"), so a
#      prefixed target is checked with a pure string compare (no subprocess);
#      a bare agent name is resolved with `herdr agent get` (falling back to
#      `herdr pane get` for pane/tab ids passed bare) and its workspace_id
#      compared. Unresolvable → DENY (fail closed), never allow-by-default.
#   C. Focus-relative pane commands (`split`, `zoom`, `swap --direction`,
#      `resize`, `focus --direction`) can omit a target entirely, which
#      resolves against GLOBAL focus, not the caller's pane — same class of
#      bug as `agent start`'s missing --workspace. An explicit `--current`
#      is just as unsafe (it means "whatever pane has global focus", not "my
#      pane"), so it is treated the same as omission: DENY, asking for
#      `--pane "$HERDR_PANE_ID"`. Read-only reconnaissance (`pane list`,
#      `pane layout`, `pane current`) is never policed here — it can't move
#      anything into the wrong workspace, so it's out of scope for both A/B/C.
#   D. `herdr pane move <pane> --new-workspace` unconditionally ejects a pane
#      from its workspace — always DENY. `herdr tab create` must always carry
#      --workspace "$HERDR_WORKSPACE_ID" — missing or foreign → DENY.
#   E. No HERDR_ENV, or `herdr`/`jq` missing → exit 0 immediately, before any
#      of the above — this guard must never wedge a shell that isn't actually
#      inside a herdr-managed pane.
#   F. The member's prompt tail (everything after the first ` -- `, e.g.
#      `-- claude "<prompt>"`) is stripped before any scanning, and every verb
#      is only recognized at a real command position (start of the command, or
#      right after a shell separator ; & | && ||, allowing optional leading
#      VAR=val assignments / the `command` builtin) — so free text in commit
#      messages, echoed JSON, or a member's own prompt can never be mistaken
#      for a genuine herdr invocation.
#
# Registered as a PreToolUse hook (matcher: Bash) in settings.json. Every
# command that doesn't mention "herdr " at all passes through untouched.
set -euo pipefail

input="$(cat)"

# The command the Bash tool is about to run (raw, pre-expansion). Any parse
# problem → allow, so the guard can never wedge unrelated commands.
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"

# Cheap reject: herdr isn't mentioned at all → nothing to police.
case "$cmd" in
  *"herdr "*) ;;
  *) exit 0 ;;
esac

own_ws="${HERDR_WORKSPACE_ID:-}"
own_pane="${HERDR_PANE_ID:-}"

# Fail-open outside a herdr-managed shell, or without the tooling to resolve
# targets — this guard must never be the thing that locks up a session.
if [ -z "$own_ws" ] || ! command -v herdr >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Drop the member's prompt tail (everything from the first ` -- ` on) so free
# text passed to `-- claude "<prompt>"` — which may itself mention any of the
# phrases below — can never be mistaken for a shell command.
head="${cmd%% -- *}"

deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Resolve a target (workspace-prefixed pane/tab id, or a bare agent name) to
# its workspace id. Prints the workspace id and returns 0, or prints nothing
# and returns nonzero if it can't be resolved.
resolve_ws() {
  local target="$1" ws
  case "$target" in
    *:*) printf '%s' "${target%%:*}"; return 0 ;;
  esac
  ws="$(herdr agent get "$target" 2>/dev/null | jq -r '.result.agent.workspace_id // empty' 2>/dev/null || true)"
  if [ -z "$ws" ]; then
    ws="$(herdr pane get "$target" 2>/dev/null | jq -r '.result.pane.workspace_id // empty' 2>/dev/null || true)"
  fi
  [ -n "$ws" ] || return 1
  printf '%s' "$ws"
}

# DENY unless $1 resolves to our own workspace. $2 is the clause, for the message.
check_target() {
  local target="$1" clause="$2" ws
  if ! ws="$(resolve_ws "$target")"; then
    deny "herdr-workspace-guard: couldn't resolve target '$target' in '$clause' to a workspace — failing closed rather than risk a cross-workspace leak. Use a workspace-prefixed id (e.g. \"\${HERDR_WORKSPACE_ID}:p1\") or scripts/herdr-team, which only ever sees panes in your own workspace (${own_ws})."
  fi
  if [ "$ws" != "$own_ws" ]; then
    deny "herdr-workspace-guard: target '$target' in '$clause' belongs to workspace '$ws', not yours ('$own_ws') — a bare agent name/pane id resolves globally, so this could silently act on another lead's team member. Re-target a pane inside your own workspace, or use scripts/herdr-team."
  fi
}

# Command position: start of command, or right after a shell separator,
# allowing optional leading VAR=val assignments and/or the `command` builtin.
# (Matches the existing spawn-detection convention, extended to every verb.)
prefix_re='(^|[;&|]|&&|\|\|)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*(command[[:space:]]+)?herdr[[:space:]]+'

# Split into clauses on shell separators so each invocation is scanned in
# isolation (best-effort — doesn't parse quoting, same philosophy as the rest
# of this script: a misparse of an UNRELATED clause can't cause a false deny,
# because a policed verb only ever triggers on ITS OWN clause).
# shellcheck disable=SC2020 # intentional: each char (;, &, |) is its own
# separator, so translating the set char-by-char (not word-by-word) is correct.
while IFS= read -r raw_clause; do
  [ -n "$raw_clause" ] || continue
  printf '%s' "$raw_clause" | grep -Eq "$prefix_re" || continue

  # Strip everything up to and including the matched `herdr␠` so verb regexes
  # below can anchor at the start of the remaining text.
  clause="$(printf '%s' "$raw_clause" | sed -E "s/^.*${prefix_re}//")"

  # --- A: agent start -------------------------------------------------------
  if [[ $clause =~ ^agent[[:space:]]+start([[:space:]]|$) ]]; then
    ws_val=""
    if [[ $raw_clause =~ --workspace[[:space:]=]+([^[:space:]]+) ]]; then
      ws_val="${BASH_REMATCH[1]}"
      [ "$ws_val" = "$own_ws" ] && continue
      deny "herdr-workspace-guard: 'herdr agent start' is pinned to --workspace $ws_val, not yours ($own_ws) — the member would land in the wrong project. Re-run pinned to --workspace \"\${HERDR_WORKSPACE_ID}\", or use scripts/claude-worktree / scripts/herdr-team spawn."
    elif [[ $raw_clause =~ --tab[[:space:]=]+([^[:space:]]+) ]]; then
      tab_val="${BASH_REMATCH[1]}"
      case "$tab_val" in
        "${own_ws}:"*) continue ;;
        *) deny "herdr-workspace-guard: 'herdr agent start' is pinned to --tab $tab_val, which isn't in your workspace ($own_ws). Re-run with a tab id prefixed \"\${HERDR_WORKSPACE_ID}:\", or use scripts/claude-worktree / scripts/herdr-team spawn." ;;
      esac
    else
      deny "herdr-workspace-guard: this 'herdr agent start' has no --workspace/--tab, so the member would land in whichever workspace currently has focus (the cross-workspace leak), not your own ($own_ws). Re-run it pinned to your workspace: add --workspace \"\${HERDR_WORKSPACE_ID}\" — or use scripts/claude-worktree / scripts/herdr-team spawn, which pin it for you."
    fi
    continue
  fi

  # --- B: agent targeting verbs ---------------------------------------------
  if [[ $clause =~ ^agent[[:space:]]+(send|read|get|focus|wait|attach|rename)[[:space:]]+([^[:space:]]+) ]]; then
    check_target "${BASH_REMATCH[2]}" "$raw_clause"
    continue
  fi

  # --- B: pane verbs with a mandatory leading pane_id ------------------------
  if [[ $clause =~ ^pane[[:space:]]+(close|rename|send-text|send-keys|run|read|get)[[:space:]]+([^[:space:]]+) ]]; then
    check_target "${BASH_REMATCH[2]}" "$raw_clause"
    continue
  fi

  # --- D: pane move — mandatory leading pane_id, plus its own destination ----
  if [[ $clause =~ ^pane[[:space:]]+move[[:space:]]+([^[:space:]]+) ]]; then
    check_target "${BASH_REMATCH[1]}" "$raw_clause"
    if [[ $raw_clause =~ --new-workspace ]]; then
      deny "herdr-workspace-guard: 'pane move --new-workspace' ejects the pane from its workspace entirely — that's the leak this guard exists to stop. Not allowed."
    elif [[ $raw_clause =~ --new-tab ]]; then
      if [[ $raw_clause =~ --workspace[[:space:]=]+([^[:space:]]+) ]]; then
        ws_val="${BASH_REMATCH[1]}"
        [ "$ws_val" = "$own_ws" ] || deny "herdr-workspace-guard: 'pane move --new-tab' is pinned to --workspace $ws_val, not yours ($own_ws)."
      fi
    elif [[ $raw_clause =~ --tab[[:space:]=]+([^[:space:]]+) ]]; then
      check_target "${BASH_REMATCH[1]}" "$raw_clause"
    fi
    continue
  fi

  # --- C: focus-relative pane verbs (split/zoom/swap/resize/focus) ----------
  if [[ $clause =~ ^pane[[:space:]]+(split|zoom|swap|resize|focus)([[:space:]]|$)(.*)$ ]]; then
    verb="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[3]}"

    if [ "$verb" = "swap" ] && [[ $raw_clause =~ --source-pane[[:space:]=]+([^[:space:]]+) ]] \
       && [[ $raw_clause =~ --target-pane[[:space:]=]+([^[:space:]]+) ]]; then
      src="$(printf '%s' "$raw_clause" | sed -E 's/.*--source-pane[[:space:]=]+([^[:space:]]+).*/\1/')"
      tgt="$(printf '%s' "$raw_clause" | sed -E 's/.*--target-pane[[:space:]=]+([^[:space:]]+).*/\1/')"
      check_target "$src" "$raw_clause"
      check_target "$tgt" "$raw_clause"
      continue
    fi

    if [[ $raw_clause =~ --pane[[:space:]=]+([^[:space:]]+) ]]; then
      check_target "${BASH_REMATCH[1]}" "$raw_clause"
    elif [[ $raw_clause =~ (^|[[:space:]])--current([[:space:]]|$) ]]; then
      deny "herdr-workspace-guard: 'pane $verb --current' resolves against GLOBAL focus, not necessarily your own pane — if focus has drifted to another workspace this acts on someone else's pane. Re-run with --pane \"\${HERDR_PANE_ID}\" (yours: ${own_pane:-unknown})."
    elif [[ $rest =~ ^([^[:space:]-][^[:space:]]*) ]]; then
      check_target "${BASH_REMATCH[1]}" "$raw_clause"
    else
      deny "herdr-workspace-guard: 'pane $verb' has no pane_id/--pane/--current, so it implicitly targets GLOBAL focus, not necessarily your own pane — that's the same class of leak as an unpinned 'agent start'. Re-run with --pane \"\${HERDR_PANE_ID}\" (yours: ${own_pane:-unknown})."
    fi
    continue
  fi

  # --- D: tab create — always requires --workspace pinned to our own --------
  if [[ $clause =~ ^tab[[:space:]]+create([[:space:]]|$) ]]; then
    if [[ $raw_clause =~ --workspace[[:space:]=]+([^[:space:]]+) ]]; then
      ws_val="${BASH_REMATCH[1]}"
      [ "$ws_val" = "$own_ws" ] && continue
      deny "herdr-workspace-guard: 'herdr tab create' is pinned to --workspace $ws_val, not yours ($own_ws)."
    else
      deny "herdr-workspace-guard: 'herdr tab create' has no --workspace, so it would create the tab in whichever workspace currently has focus, not necessarily yours. Re-run with --workspace \"\${HERDR_WORKSPACE_ID}\"."
    fi
  fi
done < <(printf '%s\n' "$head" | tr ';&|' '\n\n\n')

exit 0
