#!/usr/bin/env bash
# git-worktree-autoprune.sh — delete dead/stale git worktrees immediately.
#
# A worktree is DEAD when its working directory is gone but git still keeps the
# administrative record under .git/worktrees/<name>/. Those records keep the
# branch marked "checked out elsewhere" (so it can't be checked out or deleted)
# and keep the worktree listed in `git worktree list` forever. `git worktree
# prune` removes exactly and only those records.
#
# This is deliberately the SAFE definition of "dead":
#   - it never touches a worktree whose directory still exists, however dirty;
#   - it never deletes a branch, a commit, or any file the user still has;
#   - the only thing removed is bookkeeping for a directory already gone.
# A worktree with uncommitted work is, by definition, not dead — its directory
# is right there — so no amount of pruning can lose it.
#
# Wired as a global SessionStart + WorktreeRemove hook in
# configurations/claude/settings.json. Reads the hook payload on stdin and uses
# its .cwd; falls back to $PWD when run by hand.
#
# Env:
#   DRY_RUN=1   report what would be pruned, change nothing
#
# Exit is always 0 — a cleanup hook must never block a session from starting.

set -uo pipefail

payload=""
if [ ! -t 0 ]; then
    payload="$(cat 2>/dev/null || true)"
fi

cwd=""
if [ -n "${payload}" ] && command -v jq >/dev/null 2>&1; then
    cwd="$(printf '%s' "${payload}" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi
[ -n "${cwd}" ] && [ -d "${cwd}" ] || cwd="${PWD}"

cd "${cwd}" 2>/dev/null || exit 0

# Only inside a real, non-bare repo with a worktree of its own.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
[ "$(git rev-parse --is-bare-repository 2>/dev/null)" = "false" ] || exit 0

# `prune --dry-run -v` lists the records it WOULD remove, one per line, without
# touching anything — so the report is computed before any mutation. Note the
# verbose listing goes to STDERR, not stdout, hence the 2>&1.
stale="$(git worktree prune --dry-run --verbose 2>&1 || true)"
[ -n "${stale}" ] || exit 0

count="$(printf '%s\n' "${stale}" | grep -c . || true)"

if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '{"systemMessage":"[worktree-autoprune] DRY_RUN: %s dead worktree record(s) would be pruned in %s"}\n' \
        "${count}" "$(basename "${cwd}")"
    exit 0
fi

git worktree prune >/dev/null 2>&1 || exit 0

# The sibling <repo>.worktrees/ parent is left behind empty once its last
# worktree is gone; rmdir removes it ONLY when empty, never recursively.
toplevel="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "${toplevel}" ]; then
    parent="${toplevel}.worktrees"
    if [ -d "${parent}" ]; then
        rmdir "${parent}" 2>/dev/null || true
    fi
fi

printf '{"systemMessage":"[worktree-autoprune] pruned %s dead worktree record(s) in %s"}\n' \
    "${count}" "$(basename "${cwd}")"
exit 0
