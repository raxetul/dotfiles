#!/usr/bin/env bash
# Install / re-apply / update this repo's user environment.
#
# What this script will and will not do:
#   - WILL install Nix the first time, then never touches it again.
#   - WILL (re)apply packages and configuration on every run — this is
#     how you reinstall or reconfigure.
#   - WILL bump upstream package versions ONLY when --update is passed
#     (otherwise flake.lock pins everything, so re-runs are reproducible).
#
# Profile selection (Linux only — macOS always installs darwin.nix):
#   ./setup.sh             → server profile (CLI + dev only)
#   ./setup.sh --desktop   → desktop profile (also installs sway + GUI apps)
#
# Bumping packages to newer upstream versions:
#   ./setup.sh --update            → nix flake update (all inputs), then switch
#   ./setup.sh --update --desktop  → same, with desktop bucket
#
# Every step is idempotent: re-running this script is safe and only does
# the work that's actually missing.
set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)

PROFILE="server"
UPDATE=0
for arg in "$@"; do
    case "${arg}" in
        --desktop) PROFILE="desktop" ;;
        --server)  PROFILE="server"  ;;
        --update)  UPDATE=1 ;;
        -h|--help)
            sed -n '2,20p' "$0"
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

# Step 2b — install Homebrew on macOS (idempotent).
#
# Nixpkgs' ghostty derivation excludes Darwin, and several GUI casks
# (karabiner-elements, rectangle, …) ship only through Homebrew. We
# install brew here so the home-manager activation can replay
# configurations/brew/Brewfile in step 4.
if [ "$(uname)" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "==> installing Homebrew (multi-user; will prompt for sudo)"
        /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "==> homebrew already installed, skipping installer"
    fi

    # Apple-silicon brew lives under /opt/homebrew; Intel under /usr/local.
    # `brew shellenv` exports the right paths for the current shell.
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# Step 3 — (optional) bump flake inputs to their latest upstream versions.
#
# Without --update, re-runs are reproducible: every package is pinned by
# flake.lock and rebuilds give identical store paths. Passing --update
# rewrites flake.lock to track the latest nixpkgs / home-manager, which
# is how you actually pull in newer versions of installed packages.
if [ "${UPDATE}" -eq 1 ]; then
    echo "==> nix flake update (bumping nixpkgs, home-manager, …)"
    nix flake update --flake "${DIR}"
fi

# Step 4 — home-manager switch.
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

# Step 5 — make zsh the login shell (idempotent).
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

# Step 5b — install distro-native packages on Linux (idempotent).
#
# Anything declared in configurations/native/<pkgmgr>.list is installed
# via the host's package manager. Reserved for things Nix shouldn't own:
# kernel modules, distro GUI tooling, NVIDIA drivers, etc.
if [ "$(uname)" = "Linux" ] && [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    NATIVE_LIST=""
    INSTALL_CMD=""
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            NATIVE_LIST="${DIR}/configurations/native/apt.list"
            INSTALL_CMD="sudo apt-get install -y"
            ;;
        arch|manjaro|endeavouros)
            NATIVE_LIST="${DIR}/configurations/native/pacman.list"
            INSTALL_CMD="sudo pacman -S --needed --noconfirm"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            NATIVE_LIST="${DIR}/configurations/native/dnf.list"
            INSTALL_CMD="sudo dnf install -y"
            ;;
        *)
            echo "==> distro ${ID:-unknown} not mapped; skipping native install"
            ;;
    esac

    if [ -n "${NATIVE_LIST}" ] && [ -f "${NATIVE_LIST}" ]; then
        # Skip blank lines and comments; collapse multi-line list into args.
        pkgs="$(grep -vE '^\s*(#|$)' "${NATIVE_LIST}" | tr '\n' ' ')"
        if [ -n "${pkgs}" ]; then
            echo "==> installing native packages from ${NATIVE_LIST##*/}: ${pkgs}"
            # shellcheck disable=SC2086
            ${INSTALL_CMD} ${pkgs}
        else
            echo "==> ${NATIVE_LIST##*/} empty, no native packages to install"
        fi
    fi
fi

# Step 6 — install lefthook hooks for this repo.
#
# home-manager has just installed `lefthook` into ~/.nix-profile/bin, so
# it's on PATH for the rest of this script. `lefthook install` writes
# .git/hooks/{pre-commit,commit-msg,…} pointed at the lefthook binary;
# safe to re-run on every setup.sh invocation.
if command -v lefthook >/dev/null 2>&1; then
    echo "==> installing lefthook git hooks"
    (cd "${DIR}" && lefthook install)
else
    echo "WARN: lefthook not on PATH; skipping hook install" >&2
fi
