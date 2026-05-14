#!/usr/bin/env bash
# 1. Install Nix in multi-user (daemon) mode if it isn't already present.
# 2. Activate Home Manager for the current $USER / $HOME / system.
#
# Profile selection (Linux only — macOS always installs darwin.nix):
#   ./setup.sh             → server profile (CLI + dev only)
#   ./setup.sh --desktop   → desktop profile (also installs sway + GUI apps)
#
# Every step is idempotent: re-running this script is safe and only does
# the work that's actually missing.
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)

PROFILE="server"
for arg in "$@"; do
    case "${arg}" in
        --desktop) PROFILE="desktop" ;;
        --server)  PROFILE="server"  ;;
        -h|--help)
            sed -n '2,11p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}" >&2
            exit 1
            ;;
    esac
done
export DOTFILES_PROFILE="${PROFILE}"

# Step 1 — Nix (skip if already installed).
if ! command -v nix >/dev/null 2>&1; then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
fi

if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Step 2 — enable flakes (idempotent: only appends if missing).
mkdir -p "${HOME}/.config/nix"
grep -qs 'experimental-features.*flakes' "${HOME}/.config/nix/nix.conf" 2>/dev/null \
    || echo "experimental-features = nix-command flakes" >> "${HOME}/.config/nix/nix.conf"

# Step 3 — home-manager switch.
#
# home-manager backs up clashing dotfiles (e.g. ~/.zshrc, ~/.bashrc,
# ~/.config/...) by appending the suffix passed via -b. A static suffix
# collides on the second run, so we generate a fresh per-day, per-run
# suffix instead: backup-YYYY-MM-DD---N, where N restarts at 1 every day
# and increments for further runs on the same day. Detection scans $HOME
# for any pre-existing backup matching that exact shape — so .zshrc
# backups, .bashrc backups, and anything else home-manager has written
# all share the same counter for the day.
DATE="$(date +%Y-%m-%d)"
LAST_N="$(find "${HOME}" -maxdepth 4 -name "*.backup-${DATE}---*" 2>/dev/null \
    | sed -nE "s/.*\\.backup-${DATE}---([0-9]+)\$/\\1/p" \
    | sort -n | tail -1)"
BACKUP_SUFFIX="backup-${DATE}---$(( ${LAST_N:-0} + 1 ))"

echo "==> profile=${DOTFILES_PROFILE}"
echo "==> backup suffix=${BACKUP_SUFFIX}"
nix run --impure home-manager/master -- \
    switch --impure --flake "${DIR}#default" -b "${BACKUP_SUFFIX}"
