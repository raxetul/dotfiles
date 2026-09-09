#!/bin/sh
# install.sh — one-line installer for the dotfiles repo. Two entry points:
#
#   curl -fsSL <raw>/install.sh | sudo sh -s -- [--light]
#     MACHINE half (root). Clones or updates the shared repo at
#     /opt/dotfiles, then runs scripts/provision-shared-group.sh to set
#     up the root:dotfiles group + setgid ownership (Linux only — macOS
#     has no groupadd/usermod, see that script's own guard).
#     "hard" (default, no --light): also drops back to the invoking
#     user via `sudo -u "$SUDO_USER"` and runs THAT user's own
#     setup.sh — so a hard machine install also attaches the admin's
#     own shell, packages included.
#     "light" (--light): stops after the clone + group setup. No
#     packages, no attach, for anyone yet — re-run without --light
#     later to add packages (light -> hard is just re-running).
#
#   curl -fsSL <raw>/install.sh | sh -s -- --attach [--light]
#     PER-USER half. Never needs root. Attaches the CURRENT user's
#     shell to an already-provisioned /opt/dotfiles by running that
#     repo's own setup.sh --light (config symlinks only — works for
#     any account) or, without --light, plain setup.sh (full symlink
#     set + packages — only works if this account can itself sudo the
#     native package manager).
#
# Both halves are idempotent — re-running is safe.
#
# POSIX sh, not bash: this runs before anything is guaranteed to be on
# the machine, including bash itself.
#
# SECURITY: this file executes as root in the machine half. Per
# scripts/run-script-installers' own SECURITY note, a curl-pipe-to-shell
# lane must be pinned to a reviewed commit, never a moving branch — so
# the URL you curl this FROM must itself be pinned to a commit SHA
# (never .../main/install.sh):
#
#   https://raw.githubusercontent.com/raxetul/dotfiles/<SHA>/install.sh
#
# The SHA below is the second pin: once cloned, /opt/dotfiles is
# checked out at this SAME reviewed commit (not whatever main's HEAD
# happens to be at curl-time) before being fast-forwarded normally via
# git pull / `/update` from then on. Bump BOTH — the URL you tell
# people to curl, and this variable — together, after reviewing the
# diff at the new commit, on every release.
set -eu

# Bump on release, after reviewing the diff at the new commit.
INSTALL_PIN_SHA="0a3caea67fdee32ac2c7d6dfa974f8144c69863e"

REPO_URL="https://github.com/raxetul/dotfiles.git"
SHARED_ROOT="/opt/dotfiles"

ATTACH=0
LIGHT=0
for arg in "$@"; do
    case "${arg}" in
        --attach) ATTACH=1 ;;
        --light) LIGHT=1 ;;
        -h|--help)
            sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            printf 'install.sh: unknown argument: %s\n' "${arg}" >&2
            exit 1
            ;;
    esac
done

say() { printf '==> %s\n' "$*"; }

# ---------------------------------------------------------------------
# PER-USER half: --attach. Never touches /opt, never needs root.
# ---------------------------------------------------------------------
if [ "${ATTACH}" = "1" ]; then
    if [ "$(id -u)" = "0" ]; then
        printf 'install.sh: --attach must NOT run as root — it plants symlinks\n' >&2
        printf '            and (optionally) changes the login shell for the\n' >&2
        printf '            invoking user, not for root.\n' >&2
        exit 1
    fi

    if [ -d "${SHARED_ROOT}" ]; then
        DOTFILES_DIR="${SHARED_ROOT}"
    elif [ -d "${HOME}/gel-ort/dotfiles" ]; then
        DOTFILES_DIR="${HOME}/gel-ort/dotfiles"
    else
        printf 'install.sh: no dotfiles repo found at %s or %s/gel-ort/dotfiles.\n' \
            "${SHARED_ROOT}" "${HOME}" >&2
        printf '            Run the machine half first: curl ... | sudo sh -s --\n' >&2
        exit 1
    fi

    say "attaching to ${DOTFILES_DIR}"
    if [ "${LIGHT}" = "1" ]; then
        exec "${DOTFILES_DIR}/setup.sh" --light
    else
        exec "${DOTFILES_DIR}/setup.sh"
    fi
fi

# ---------------------------------------------------------------------
# MACHINE half (default): clone/update /opt/dotfiles + group setup.
# ---------------------------------------------------------------------
if [ "$(id -u)" != "0" ]; then
    printf 'install.sh: the machine half needs root (sudo) — it writes to %s\n' \
        "${SHARED_ROOT}" >&2
    printf '            and provisions the shared group. Use --attach for a\n' >&2
    printf '            no-root per-user attach instead.\n' >&2
    exit 1
fi

if [ "$(uname)" = "Darwin" ]; then
    printf 'install.sh: /opt/dotfiles + a shared group is a Linux-server\n' >&2
    printf '            pattern — macOS has no groupadd/usermod. Clone the repo\n' >&2
    printf '            yourself (e.g. to ~/gel-ort/dotfiles) and run ./setup.sh.\n' >&2
    exit 1
fi

if [ -d "${SHARED_ROOT}/.git" ]; then
    say "updating existing ${SHARED_ROOT}"
    git -C "${SHARED_ROOT}" fetch --quiet origin main
    git -C "${SHARED_ROOT}" merge --ff-only origin/main
else
    say "cloning ${REPO_URL} -> ${SHARED_ROOT}"
    git clone --quiet "${REPO_URL}" "${SHARED_ROOT}"
    say "pinning initial checkout to ${INSTALL_PIN_SHA}"
    git -C "${SHARED_ROOT}" checkout --quiet -B main "${INSTALL_PIN_SHA}"
    git -C "${SHARED_ROOT}" branch --quiet --set-upstream-to=origin/main main
fi

INVOKING_USER="${SUDO_USER:-}"

say "group + ownership setup"
if [ -n "${INVOKING_USER}" ] && [ "${INVOKING_USER}" != "root" ]; then
    "${SHARED_ROOT}/scripts/provision-shared-group.sh" "${INVOKING_USER}"
else
    printf 'WARN: no non-root SUDO_USER found — skipping group membership.\n' >&2
    printf '      Re-run scripts/provision-shared-group.sh <user> for each\n' >&2
    printf '      account that should attach to %s.\n' "${SHARED_ROOT}" >&2
    "${SHARED_ROOT}/scripts/provision-shared-group.sh"
fi

if [ "${LIGHT}" = "1" ]; then
    say "light machine install — no packages, no attach. Each user attaches with:"
    printf '  curl -fsSL <raw>/install.sh | sh -s -- --attach --light\n'
    exit 0
fi

if [ -z "${INVOKING_USER}" ] || [ "${INVOKING_USER}" = "root" ]; then
    say "hard machine install requested but no non-root invoking user to attach —"
    printf '  run the per-user half yourself as that account:\n'
    printf '  curl -fsSL <raw>/install.sh | sh -s -- --attach\n'
    exit 0
fi

say "hard machine install — attaching ${INVOKING_USER} (packages included)"
exec sudo -u "${INVOKING_USER}" -H "${SHARED_ROOT}/setup.sh"
