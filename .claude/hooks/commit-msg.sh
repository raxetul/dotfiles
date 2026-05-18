#!/usr/bin/env bash
# .claude/hooks/commit-msg.sh — validate a proposed commit message
# against the same Conventional Commits regex used by lefthook.yml.
#
# Usage:
#   .claude/hooks/commit-msg.sh <path-to-message-file>
#   echo "feat(x): y" | .claude/hooks/commit-msg.sh -
#
# Used by the /commit slash command so the agent can sanity-check its
# own draft *before* invoking `git commit`. lefthook's commit-msg hook
# would catch the same mistake, but only after the commit machinery
# has already engaged.
#
# Exit codes:
#   0   subject line matches the Conventional Commits pattern
#   1   subject line does not match
#   2   bad CLI usage / unreadable input
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <message-file|->" >&2
    exit 2
fi

src="$1"
if [ "${src}" = "-" ]; then
    msg="$(cat)"
elif [ -r "${src}" ]; then
    msg="$(cat "${src}")"
else
    echo "ERR: cannot read ${src}" >&2
    exit 2
fi

# Subject = the first non-comment line.
first_line="$(printf '%s\n' "${msg}" | grep -v '^#' | head -n1)"

# Keep this regex in lockstep with configurations/lefthook.yml.
PATTERN='^(feat|fix|refactor|chore|docs|style|perf|build|ci|test|revert)(\([a-z0-9_/.-]+\))?!?: .+'

if printf '%s' "${first_line}" | grep -qE "${PATTERN}"; then
    exit 0
fi

cat >&2 <<EOF
ERR: not a Conventional Commit subject: '${first_line}'

Expected:  type(scope): subject     (scope optional)
Types:     feat fix refactor chore docs style perf build ci test revert
Examples:
  feat(gpg): signing wizard + HM module
  docs(roadmap): tick shipped phases
  refactor(home): split default.nix into platform dispatchers
EOF
exit 1
