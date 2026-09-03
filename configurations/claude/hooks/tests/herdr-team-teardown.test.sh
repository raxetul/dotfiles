#!/usr/bin/env bash
# Regression suite for herdr-team-teardown.sh.
#
# The hook fires in EVERY Claude session, so the expensive failure is not
# "forgot to close a member" — it is a MEMBER deciding it is the lead and
# closing its lead plus its siblings. Both halves are therefore asserted: the
# lead must close its members, and everyone else must close nothing.
#
# herdr is stubbed, because the real thing would need a live workspace with
# spawned members. The stub answers `agent list` / `pane layout` from fixtures
# and records every `pane close` to a file, which is what the assertions read.
#
# Run: configurations/claude/hooks/tests/herdr-team-teardown.test.sh
# Override the hook under test with HOOK=/path/to/hook.
set -uo pipefail

HOOK="${HOOK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/herdr-team-teardown.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
CLOSED="${TMP}/closed"
pass=0; fail=0

# --- herdr stub --------------------------------------------------------------
# Reads ${TMP}/agents.json and ${TMP}/leftmost, appends closed panes to CLOSED.
mkdir -p "${TMP}/bin"
cat >"${TMP}/bin/herdr" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
    "agent list")  cat "${TMP}/agents.json" ;;
    "pane layout") printf '{"result":{"layout":{"panes":[{"pane_id":"%s","rect":{"x":0,"y":0}}]}}}' \
                       "$(cat "${TMP}/leftmost")" ;;
    "pane close")  printf '%s\n' "$3" >>"${TMP}/closed" ;;
    *)             exit 0 ;;
esac
STUB
chmod +x "${TMP}/bin/herdr"
export PATH="${TMP}/bin:${PATH}" TMP

# agents <json-array-of-agents>
agents() { printf '{"result":{"agents":%s}}' "$1" >"${TMP}/agents.json"; }
leftmost() { printf '%s' "$1" >"${TMP}/leftmost"; }

# run <expected-closed-csv|-> <label> [reason] [mode]
run() {
    local want="$1" label="$2" reason="${3:-prompt_input_exit}" mode="${4:-all}" got
    : >"${CLOSED}"
    printf '{"hook_event_name":"SessionEnd","reason":"%s"}' "${reason}" \
        | HERDR_TEAM_TEARDOWN="${mode}" bash "${HOOK}" >/dev/null 2>&1
    got="$(paste -sd, "${CLOSED}" 2>/dev/null)"
    [ -n "${got}" ] || got="-"
    if [ "${got}" = "${want}" ]; then
        pass=$((pass + 1)); printf '  🟢 %-52s closed=%s\n' "${label}" "${got}"
    else
        fail=$((fail + 1)); printf '  🔴 %-52s got=%s want=%s\n' "${label}" "${got}" "${want}"
    fi
}

# A lead (name null) plus two named members, all in w3.
LEAD_AND_TWO='[
 {"pane_id":"w3:p1","name":null,"agent_status":"working","workspace_id":"w3"},
 {"pane_id":"w3:p2","name":"frontend","agent_status":"idle","workspace_id":"w3"},
 {"pane_id":"w3:p3","name":"backend","agent_status":"working","workspace_id":"w3"}]'

export HERDR_ENV=1 HERDR_WORKSPACE_ID=w3 HERDR_PANE_ID=w3:p1

echo "── the lead MUST tear its members down ───────────────────────────"
agents "${LEAD_AND_TWO}"; leftmost w3:p1
run "w3:p2,w3:p3" "lead exits (prompt_input_exit)"
run "w3:p2,w3:p3" "lead exits (logout)"                 logout
run "w3:p2,w3:p3" "lead exits (other)"                  other
run "w3:p2"       "mode=idle skips the working member"  prompt_input_exit idle

echo
echo "── sessions that MUST close nothing ──────────────────────────────"
run "-" "reason=clear (process lives on)"     clear
run "-" "reason=resume (process lives on)"    resume
run "-" "mode=off"                            prompt_input_exit off

# NOTE: no subshells below. `( export X=y; run ... )` would run `run` in a
# subshell, so its pass/fail increments would never reach this shell — a FAILING
# case would leave ${fail} at 0 and the suite would exit 0 while printing red.
# Overrides are therefore assigned and restored in place.

# A MEMBER exiting: same workspace, but its own entry HAS a name.
agents "${LEAD_AND_TWO}"; leftmost w3:p1
HERDR_PANE_ID=w3:p2
run "-" "a MEMBER exits — never tears anything down"
HERDR_PANE_ID=w3:p1

# Lead-ish (unnamed) but not the leftmost pane of its tab.
leftmost w3:p9
run "-" "unnamed pane that is NOT leftmost"
leftmost w3:p1

# Members in another workspace must be invisible.
agents '[
 {"pane_id":"w3:p1","name":null,"agent_status":"idle","workspace_id":"w3"},
 {"pane_id":"w9:p2","name":"infra","agent_status":"idle","workspace_id":"w9"}]'
run "-" "member in ANOTHER workspace is untouched"

# An unnamed sibling is someone's hand-started claude, not a spawned member.
agents '[
 {"pane_id":"w3:p1","name":null,"agent_status":"idle","workspace_id":"w3"},
 {"pane_id":"w3:p2","name":null,"agent_status":"idle","workspace_id":"w3"}]'
run "-" "unnamed sibling pane is left alone"

echo
echo "── environment guards ────────────────────────────────────────────"
agents "${LEAD_AND_TWO}"; leftmost w3:p1
unset HERDR_ENV
run "-" "no HERDR_ENV — not inside herdr"
export HERDR_ENV=1

HERDR_WORKSPACE_ID=""
run "-" "empty HERDR_WORKSPACE_ID"
HERDR_WORKSPACE_ID=w3

echo
printf '%s passed, %s failed\n' "${pass}" "${fail}"
[ "${fail}" -eq 0 ]
