#!/usr/bin/env bash
# .claude/hooks/post-tool-use.sh — PostToolUse hook for Write|Edit.
#
# Reads the Claude Code hook payload from stdin (JSON). When the tool
# call edited a file under home/modules/*.nix, this hook checks
# whether the matching doc/modules-<name>.md was also touched in the
# same turn. If not, it prints a warning to stderr — but the hook's
# exit code stays 0 (advisory, not blocking).
#
# Wired up in .claude/settings.json under hooks.PostToolUse.
#
# Payload shape (Claude Code PostToolUse, illustrative):
#   {
#     "tool_name": "Edit",
#     "tool_input": { "file_path": "/abs/path/home/modules/foo.nix", ... },
#     "tool_response": { ... },
#     "session_id": "...",
#     "cwd": "/Users/.../dotfiles"
#   }
set -euo pipefail

# Need `jq` for a robust read; degrade gracefully if it's missing
# (PostToolUse runs in whatever environment the user has set up, and
# we don't want a missing jq to be a noisy failure).
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

payload="$(cat || true)"
[ -n "${payload}" ] || exit 0

tool_name="$(printf '%s' "${payload}" | jq -r '.tool_name // empty')"
file_path="$(printf '%s' "${payload}" | jq -r '.tool_input.file_path // empty')"
cwd="$(printf '%s' "${payload}" | jq -r '.cwd // empty')"

[ -n "${file_path}" ] || exit 0
case "${tool_name}" in
    Write|Edit|MultiEdit) ;;
    *) exit 0 ;;
esac

# Only care about edits under home/modules/. The hook fires on every
# Write|Edit; this match narrows it to the one path family we want to
# guard. We match on the *suffix* so absolute and relative paths both
# resolve.
case "${file_path}" in
    *"/home/modules/"*.nix) ;;
    *) exit 0 ;;
esac

# Exclude the packages bucket — packages/ files have their own doc
# convention (doc/packages-*.md) and aren't 1:1 with module names.
case "${file_path}" in
    *"/home/modules/packages/"*) exit 0 ;;
esac

module_name="$(basename "${file_path}" .nix)"
doc_path_rel="doc/modules-${module_name}.md"

# Resolve doc path relative to repo root. Prefer cwd from the payload;
# fall back to walking up from the edited file.
if [ -d "${cwd}/.git" ] || [ -f "${cwd}/flake.nix" ]; then
    repo_root="${cwd}"
else
    repo_root="$(cd "$(dirname "${file_path}")/.." && git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -n "${repo_root}" ] || exit 0

doc_path_abs="${repo_root}/${doc_path_rel}"

if [ ! -f "${doc_path_abs}" ]; then
    printf '\033[1;33mWARN:\033[0m  edited %s but %s does not exist yet.\n' \
        "home/modules/${module_name}.nix" "${doc_path_rel}" >&2
    printf '        Add a doc: see .claude/skills/doc-author/SKILL.md\n' >&2
    exit 0
fi

# We can't reliably know whether the doc was touched *in the same
# turn* from a single PostToolUse invocation — Claude Code calls hooks
# per tool, not per turn. Heuristic: compare mtimes within the last
# 5 minutes. If the doc hasn't been touched recently, warn.
nix_mtime="$(stat -f '%m' "${file_path}" 2>/dev/null || stat -c '%Y' "${file_path}" 2>/dev/null || echo 0)"
doc_mtime="$(stat -f '%m' "${doc_path_abs}" 2>/dev/null || stat -c '%Y' "${doc_path_abs}" 2>/dev/null || echo 0)"
now="$(date +%s)"

# If the nix file was just touched (within the last 60s) and the doc
# hasn't been touched in the last 5 minutes, the doc is probably stale.
if [ "$(( now - nix_mtime ))" -le 60 ] && [ "$(( now - doc_mtime ))" -gt 300 ]; then
    printf '\033[1;33mWARN:\033[0m  edited home/modules/%s.nix; %s looks stale.\n' \
        "${module_name}" "${doc_path_rel}" >&2
    printf '        Update both in the same turn (see .claude/skills/doc-author/SKILL.md).\n' >&2
fi

exit 0
