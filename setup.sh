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
#
# Idempotency: the official installer aborts if `/nix` exists, so we
# can't just retry `curl | sh` blindly. Detect Nix through several
# layers and only invoke the installer when it really is missing.
NIX_DAEMON_PROFILE=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Source the daemon script first so an already-installed Nix becomes
# visible in this shell (covers the "PATH not yet set" case after a
# fresh install or in a non-login shell).
if [ -e "${NIX_DAEMON_PROFILE}" ]; then
    # shellcheck source=/dev/null
    . "${NIX_DAEMON_PROFILE}"
fi

nix_present() {
    command -v nix >/dev/null 2>&1 \
        || [ -x /nix/var/nix/profiles/default/bin/nix ] \
        || [ -d /nix/store ]
}

if nix_present; then
    echo "==> nix already installed, skipping installer"
else
    echo "==> installing nix (multi-user / daemon)"
    curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
    # Re-source so this shell can see the freshly-installed nix.
    if [ -e "${NIX_DAEMON_PROFILE}" ]; then
        # shellcheck source=/dev/null
        . "${NIX_DAEMON_PROFILE}"
    fi
fi

command -v nix >/dev/null 2>&1 || {
    echo "ERROR: nix not on PATH after install. Source manually:" >&2
    echo "  . ${NIX_DAEMON_PROFILE}" >&2
    exit 1
}

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

# Step 4 — make zsh the login shell (idempotent).
#
# home-manager installs zsh into ~/.nix-profile but doesn't touch the
# system user record. chsh refuses shells that aren't listed in
# /etc/shells, so add it there first, then switch the login shell via
# sudo (avoids the interactive password prompt of plain `chsh`).
ZSH_BIN="$(command -v zsh || true)"
current_login_shell() {
    if command -v getent >/dev/null 2>&1; then
        getent passwd "${USER}" | awk -F: '{print $NF}'
    elif [ "$(uname)" = "Darwin" ]; then
        dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}'
    else
        awk -F: -v u="${USER}" '$1==u {print $NF}' /etc/passwd
    fi
}

if [ -z "${ZSH_BIN}" ]; then
    echo "WARN: zsh not found on PATH after home-manager switch; skipping shell change" >&2
elif [ "$(current_login_shell)" = "${ZSH_BIN}" ]; then
    echo "==> login shell already ${ZSH_BIN}, skipping"
else
    if ! grep -qxF "${ZSH_BIN}" /etc/shells 2>/dev/null; then
        echo "==> registering ${ZSH_BIN} in /etc/shells (sudo)"
        echo "${ZSH_BIN}" | sudo tee -a /etc/shells >/dev/null
    fi
    echo "==> setting login shell to ${ZSH_BIN} for ${USER} (sudo)"
    sudo chsh -s "${ZSH_BIN}" "${USER}"
    echo "==> log out and back in (or start a new login session) for the shell change to take effect"
fi
