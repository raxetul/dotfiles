#!/usr/bin/env bash
# Install / re-apply / update this repo's user environment.
#
# What this script does:
#   1. installs Homebrew on macOS (idempotent)
#   2. installs packages from packages/Brewfile (macOS) or
#      packages/<pkgmgr>.list (+ -desktop.list on --desktop) on Linux
#   3. layers Linux fallbacks — AUR on pacman-family, Snap elsewhere
#   4. bootstraps user-scope plugin managers (vim-plug, TPM, zsh plugins)
#   5. plants symlinks from configurations/ into $HOME via
#      scripts/symlinks.sh
#   6. makes zsh the login shell
#   7. installs lefthook git hooks for this repo
#
# Usage:
#   ./setup.sh                # baseline (CLI + dev only)
#   ./setup.sh --desktop      # baseline + Linux desktop GUI stack
#   ./setup.sh --update       # upgrade already-installed packages
#
# Every step is idempotent: re-running this script is safe.
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
            sed -n '2,21p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}" >&2
            exit 1
            ;;
    esac
done

OS="$(uname)"
say() { printf '==> %s\n' "$*"; }

# ------------------------------------------------------------------
# Step 1 — Homebrew on macOS (idempotent).
# ------------------------------------------------------------------
if [ "${OS}" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        say "installing Homebrew (will prompt for sudo)"
        /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        say "Homebrew already installed"
    fi

    # Make brew visible in this shell — Apple-silicon under /opt/homebrew,
    # Intel under /usr/local.
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

# ------------------------------------------------------------------
# Step 2 — install packages.
# ------------------------------------------------------------------
if [ "${OS}" = "Darwin" ]; then
    [ "${UPDATE}" -eq 1 ] && { say "brew update"; brew update; }
    say "brew bundle (packages/Brewfile)"
    brew bundle --file="${DIR}/packages/Brewfile"
    [ "${UPDATE}" -eq 1 ] && { say "brew upgrade"; brew upgrade; }

elif [ "${OS}" = "Linux" ] && [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    INSTALL_CMD=""
    UPDATE_CMD=""
    UPGRADE_CMD=""
    BASELINE=""
    DESKTOP=""
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            UPDATE_CMD="sudo apt-get update"
            INSTALL_CMD="sudo apt-get install -y"
            UPGRADE_CMD="sudo apt-get upgrade -y"
            BASELINE="${DIR}/packages/apt.list"
            DESKTOP="${DIR}/packages/apt-desktop.list"
            ;;
        arch|manjaro|endeavouros|artix)
            UPDATE_CMD="sudo pacman -Syy --noconfirm"
            INSTALL_CMD="sudo pacman -S --needed --noconfirm"
            UPGRADE_CMD="sudo pacman -Syu --noconfirm"
            BASELINE="${DIR}/packages/pacman.list"
            DESKTOP="${DIR}/packages/pacman-desktop.list"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            UPDATE_CMD="sudo dnf check-update || true"
            INSTALL_CMD="sudo dnf install -y"
            UPGRADE_CMD="sudo dnf upgrade -y"
            BASELINE="${DIR}/packages/dnf.list"
            DESKTOP="${DIR}/packages/dnf-desktop.list"
            ;;
        *)
            say "distro ${ID:-unknown} not mapped; skipping native package install"
            ;;
    esac

    if [ -n "${INSTALL_CMD}" ]; then
        eval "${UPDATE_CMD}"
        [ "${UPDATE}" -eq 1 ] && eval "${UPGRADE_CMD}"

        LISTS=("${BASELINE}")
        [ "${PROFILE}" = "desktop" ] && LISTS+=("${DESKTOP}")
        for list in "${LISTS[@]}"; do
            [ -f "${list}" ] || continue
            pkgs="$(grep -vE '^\s*(#|$)' "${list}" | tr '\n' ' ')"
            if [ -n "${pkgs}" ]; then
                say "installing from ${list##*/}"
                # shellcheck disable=SC2086
                ${INSTALL_CMD} ${pkgs}
            fi
        done
    fi
fi

# ------------------------------------------------------------------
# Step 3 — Linux fallbacks: AUR on pacman-family, Snap elsewhere.
# ------------------------------------------------------------------
if [ "${OS}" = "Linux" ] && [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "${ID:-}" in
        arch|manjaro|endeavouros|artix)
            if [ -f "${DIR}/packages/aur.list" ]; then
                if command -v yay >/dev/null 2>&1; then
                    pkgs="$(grep -vE '^\s*(#|$)' "${DIR}/packages/aur.list" | tr '\n' ' ')"
                    if [ -n "${pkgs}" ]; then
                        say "installing AUR packages via yay"
                        # shellcheck disable=SC2086
                        yay -S --needed --noconfirm ${pkgs}
                    fi
                else
                    say "WARN: yay not on PATH; skipping aur.list (install yay or paru manually)"
                fi
            fi
            ;;
        debian|ubuntu|pop|linuxmint|fedora|rhel|centos|almalinux|rocky)
            if [ -f "${DIR}/packages/snap.list" ]; then
                if command -v snap >/dev/null 2>&1; then
                    while IFS= read -r line; do
                        case "${line}" in ""|"#"*) continue ;; esac
                        say "installing snap: ${line}"
                        # shellcheck disable=SC2086
                        sudo snap install ${line}
                    done < "${DIR}/packages/snap.list"
                else
                    say "WARN: snap not on PATH; skipping snap.list (apt-get install snapd / dnf install snapd)"
                fi
            fi
            ;;
    esac
fi

# ------------------------------------------------------------------
# Step 4 — bootstrap user-scope plugin managers (idempotent).
# ------------------------------------------------------------------
say "bootstrapping plugin managers"

# vim-plug
if [ ! -f "${HOME}/.vim/autoload/plug.vim" ]; then
    say "  installing vim-plug"
    curl -fsSLo "${HOME}/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# TPM (tmux plugin manager)
if [ ! -d "${HOME}/.config/tmux/plugins/tpm" ]; then
    say "  installing TPM"
    mkdir -p "${HOME}/.config/tmux/plugins"
    git clone --depth=1 https://github.com/tmux-plugins/tpm \
        "${HOME}/.config/tmux/plugins/tpm"
fi

# zsh-you-should-use — fall back to git clone if no native package on PATH.
if [ ! -d "${HOME}/.config/zsh-plugins/zsh-you-should-use" ] \
   && [ ! -f /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh ] \
   && [ ! -f /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh ]; then
    say "  installing zsh-you-should-use"
    mkdir -p "${HOME}/.config/zsh-plugins"
    git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use \
        "${HOME}/.config/zsh-plugins/zsh-you-should-use"
fi

# ------------------------------------------------------------------
# Step 5 — plant symlinks from configurations/ into $HOME.
# ------------------------------------------------------------------
say "planting symlinks (scripts/symlinks.sh)"
[ "${PROFILE}" = "desktop" ] && export DOTFILES_DESKTOP=1
"${DIR}/scripts/symlinks.sh" install

# ------------------------------------------------------------------
# Step 6 — make zsh the login shell (idempotent).
# ------------------------------------------------------------------
ZSH_BIN="$(command -v zsh || true)"
current_login_shell() {
    if command -v getent >/dev/null 2>&1; then
        getent passwd "${USER}" | awk -F: '{print $NF}'
    elif [ "${OS}" = "Darwin" ]; then
        dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}'
    else
        awk -F: -v u="${USER}" '$1==u {print $NF}' /etc/passwd
    fi
}

if [ -z "${ZSH_BIN}" ]; then
    say "WARN: zsh not on PATH; skipping shell change"
elif [ "$(current_login_shell)" = "${ZSH_BIN}" ]; then
    say "login shell already ${ZSH_BIN}"
else
    if ! grep -qxF "${ZSH_BIN}" /etc/shells 2>/dev/null; then
        say "registering ${ZSH_BIN} in /etc/shells (sudo)"
        echo "${ZSH_BIN}" | sudo tee -a /etc/shells >/dev/null
    fi
    say "setting login shell to ${ZSH_BIN} (sudo)"
    sudo chsh -s "${ZSH_BIN}" "${USER}"
    say "log out and back in for the shell change to take effect"
fi

# ------------------------------------------------------------------
# Step 7 — install lefthook git hooks for this repo.
# ------------------------------------------------------------------
if command -v lefthook >/dev/null 2>&1; then
    say "installing lefthook git hooks"
    (cd "${DIR}" && lefthook install)
else
    say "WARN: lefthook not on PATH; skipping hook install"
fi

say "done"
