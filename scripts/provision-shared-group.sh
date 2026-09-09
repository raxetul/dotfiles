#!/usr/bin/env bash
# scripts/provision-shared-group.sh — group + ownership setup for the
# shared /opt/dotfiles install. Linux only, requires root. NOT part of
# a normal user install (setup.sh never calls this) — it's the
# machine-half step `install.sh` runs once per machine, and it's safe
# to re-run (idempotent).
#
# What it does:
#   1. groupadd -f dotfiles
#   2. chgrp -R dotfiles /opt/dotfiles
#   3. chmod -R g+rX /opt/dotfiles
#   4. setgid every directory under /opt/dotfiles, so files created
#      later (by a git pull, by a user's own edits) inherit the group
#      instead of the creating user's primary group. NOT optional —
#      without it, a second user's `git pull` output would be
#      unreadable to the first.
#   5. usermod -aG dotfiles <user>  — for every user named on the
#      command line (a machine install adds the invoking user; an
#      attach can add additional users later by re-running with their
#      name).
#
# Usage:
#   sudo scripts/provision-shared-group.sh [<user> ...]
#   DRY_RUN=1 sudo scripts/provision-shared-group.sh <user>
#
# The group/ownership/setgid steps always run; naming no <user> just
# skips the usermod step (re-run later with a name to add someone).
#
# macOS has no groupadd/usermod (dseditgroup's semantics differ enough
# that guessing at a translation is worse than refusing) — this script
# detects Darwin and exits with a clear message instead of guessing.
set -euo pipefail

say() { printf '==> %s\n' "$*"; }
run() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

if [ "$(uname)" = "Darwin" ]; then
    printf 'ERR: macOS has no groupadd/usermod — dseditgroup differs enough that\n' >&2
    printf '     guessing a translation is worse than skipping. Set up the\n' >&2
    printf '     "dotfiles" group and membership by hand if you need a shared\n' >&2
    printf '     /opt/dotfiles on macOS, or use a per-user checkout instead.\n' >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ] && [ "${DRY_RUN:-0}" != "1" ]; then
    printf 'ERR: must run as root (sudo) — this changes ownership under /opt.\n' >&2
    exit 1
fi

REPO="/opt/dotfiles"
[ -d "${REPO}" ] || { printf 'ERR: %s does not exist — clone it first.\n' "${REPO}" >&2; exit 1; }

if [ $# -eq 0 ]; then
    printf 'no <user> given — group/ownership only, no membership added.\n'
fi

say "group: dotfiles"
run groupadd -f dotfiles

say "ownership + permissions: ${REPO}"
run chgrp -R dotfiles "${REPO}"
run chmod -R g+rX "${REPO}"

say "setgid on every directory under ${REPO} (new files inherit the group)"
if [ "${DRY_RUN:-0}" = "1" ]; then
    n="$(find "${REPO}" -type d | wc -l | tr -d ' ')"
    printf '[dry-run] find %s -type d -exec chmod g+s {} +   (%s dirs)\n' "${REPO}" "${n}"
else
    find "${REPO}" -type d -exec chmod g+s {} +
fi

for u in "$@"; do
    say "membership: ${u} -> dotfiles"
    run usermod -aG dotfiles "${u}"
done

say "done — members of 'dotfiles' may need to log out/in for the group to take effect"
