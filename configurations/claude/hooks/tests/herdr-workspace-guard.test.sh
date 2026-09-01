#!/usr/bin/env bash
# Regression suite for herdr-workspace-guard.sh.
#
# Drives the hook with synthetic PreToolUse payloads and asserts allow/deny.
# Two halves matter equally: the guard must keep DENYING real leaks, and must
# stop DENYING text that only mentions a policed call. A fail-closed bug trains
# the user to route around the guard, which is worse than the leak it prevents.
#
# Run: configurations/claude/hooks/tests/herdr-workspace-guard.test.sh
# Override the hook under test with GUARD=/path/to/hook.
#
# shellcheck disable=SC2016 # the fixtures must stay LITERAL text: `${HERDR_
# WORKSPACE_ID}` is exactly what the guard's normalize_val() resolves, so
# expanding it here would test nothing.
# Drive the guard with synthetic PreToolUse payloads.
export HERDR_ENV=1 HERDR_WORKSPACE_ID=wB HERDR_PANE_ID=wB:p1
G="${GUARD:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/herdr-workspace-guard.sh}"
pass=0; fail=0
run() { # <expect allow|deny> <label> <command>
  local expect="$1" label="$2" cmd="$3" out verdict
  out="$(printf '%s' "$cmd" | jq -Rs '{tool_input:{command:.}}' | bash "$G" 2>/dev/null)"
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then verdict=deny; else verdict=allow; fi
  if [ "$verdict" = "$expect" ]; then pass=$((pass+1)); printf '  🟢 %-58s %s\n' "$label" "$verdict"
  else fail=$((fail+1)); printf '  🔴 %-58s got=%s want=%s\n' "$label" "$verdict" "$expect"; fi
}

echo "── regressions that MUST still deny ──────────────────────────────"
run deny  "agent start, no --workspace"          'herdr agent start tooling -- claude'
run deny  "agent start, foreign workspace"       'herdr agent start x --workspace w9 -- claude'
run deny  "tab create, no --workspace"           'herdr tab create --label foo'
run deny  "tab create, foreign workspace"        'herdr tab create --workspace w7'
run deny  "pane split with no pane/--current"    'herdr pane split'
run deny  "pane split --current"                 'herdr pane split --current'
run deny  "pane move --new-workspace"            'herdr pane move wB:p2 --new-workspace'
run deny  "agent send to foreign pane"           'herdr agent send w9:p1 hello'
run deny  "cmd-substitution, unpinned"           'out=$(herdr agent start x -- claude)'

echo
echo "── correct usage that MUST allow ─────────────────────────────────"
run allow "agent start pinned (literal)"         'herdr agent start x --workspace wB -- claude'
run allow "agent start pinned (env var)"         'herdr agent start x --workspace "${HERDR_WORKSPACE_ID}" -- claude'
run allow "tab create pinned"                    'herdr tab create --workspace wB --label foo'
run allow "pane split --pane own"                'herdr pane split --pane "${HERDR_PANE_ID}"'
run allow "no herdr at all"                      'ls -la /tmp'

echo
echo "── BUG 1: heredoc body must not be policed ───────────────────────"
run allow "heredoc doc mentioning backticked verb" 'python3 - <<PY
s = "run `herdr tab create` pinned to the workspace"
PY'
run allow "quoted heredoc, unpinned agent start"   "cat <<'EOF' > doc.md
Never run \`herdr agent start x\` without --workspace.
EOF"
run allow "commit msg heredoc"                     'git commit -F - <<MSG
docs: explain `herdr tab create` pinning
MSG'
run deny  "real command AFTER a heredoc closes"    'cat <<EOF
just text
EOF
herdr tab create --label x'

echo
echo "── BUG 2: line-continuation must not fail closed ─────────────────"
run allow "pinned agent start across lines"      'herdr agent start tooling \
  --cwd /tmp \
  --workspace "${HERDR_WORKSPACE_ID}" \
  --split right -- claude'
run allow "pinned tab create across lines"       'herdr tab create \
  --workspace "${HERDR_WORKSPACE_ID}" \
  --label foo'
run deny  "UNpinned agent start across lines"    'herdr agent start tooling \
  --cwd /tmp \
  --split right -- claude'
run allow "cmd-subst + continuation, pinned"     'out=$(herdr agent start x \
  --workspace "${HERDR_WORKSPACE_ID}" -- claude)'

echo
printf '\nPASS %s   FAIL %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
