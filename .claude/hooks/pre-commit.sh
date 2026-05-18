#!/usr/bin/env bash
# .claude/hooks/pre-commit.sh — thin shim around `lefthook run pre-commit`.
#
# Invoked from the /commit slash command before the agent actually runs
# `git commit`. Surfaces lefthook's verdict so the agent can decide
# whether to keep going or fix something first.
#
# Exit codes:
#   0   lefthook accepted the staged tree
#   1   lefthook rejected (formatting / shellcheck / etc.)
#   2   lefthook not installed (NOT a hard failure: the agent decides)
set -euo pipefail

if ! command -v lefthook >/dev/null 2>&1; then
    echo "lefthook not on PATH" >&2
    exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "${REPO_ROOT}" ] || {
    echo "not inside a git repo" >&2
    exit 1
}

cd "${REPO_ROOT}"
exec lefthook run pre-commit
