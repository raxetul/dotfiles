#!/usr/bin/env bash
# Install / re-apply / update this repo's user environment.
#
# What this script does:
#   1. installs Homebrew on macOS (idempotent)
#   2. runs packages/custom-install/*/before.sh (third-party repos, …)
#   3. installs packages from packages/Brewfile (macOS) or
#      packages/<pkgmgr>.list (+ -desktop.list on --desktop) on Linux
#   4. layers Linux fallbacks — AUR on pacman-family, Snap elsewhere
#   5. runs packages/custom-install/*/after.sh (rustup toolchain, plus
#      starship/atuin/claude/lefthook release-binary fallbacks where the
#      native package manager lacks them)
#   6. bootstraps user-scope plugin managers (vim-plug, TPM, zsh plugins)
#   6.5. ensures the claude-skills repo exists and is mirrored to its
#        required PRIVATE GitHub repo (<owner>/claude-skills, asking
#        first — a human is present here)
#   7. plants symlinks from configurations/ into $HOME via
#      scripts/symlinks.sh (skills symlinked from the claude-skills repo)
#   8. makes zsh the login shell
#   9. installs lefthook git hooks for this repo
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
            sed -n '2,27p' "$0"
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

# Realized-state ledger. state_begin_run exports DOTFILES_STATE_RUN so the
# child scripts we invoke (symlinks.sh, run-custom-install-hook) group their
# records under this one run. See scripts/dotfiles-state.sh.
# shellcheck source=scripts/dotfiles-state.sh
. "${DIR}/scripts/dotfiles-state.sh"
state_begin_run >/dev/null

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
# Ensure the gitignored .load file exists. It's sourced by
# configurations/{zsh,bash}/rc and in turn sources .path (managed by
# custom-install after.sh hooks). Creating it early so later steps
# can rely on it.
# ------------------------------------------------------------------
DOTFILES_DIR="${DIR}" "${DIR}/scripts/init-load"

# ------------------------------------------------------------------
# Step 1.5 — packages/custom-install/<pkg>/before.sh hooks.
# Run BEFORE the package install step so each script can register a
# third-party repo, pre-create config dirs, etc. Output goes through
# scripts/run-custom-install-hook which tees to
# ~/.local/state/dotfiles/custom-install.log.
# See packages/custom-install/README.md for the contract.
# ------------------------------------------------------------------
CUSTOM_INSTALL_DIR="${DIR}/packages/custom-install"
if [ -d "${CUSTOM_INSTALL_DIR}" ]; then
    custom_install_pkgs=()
    for pkg_dir in "${CUSTOM_INSTALL_DIR}"/*/; do
        [ -d "${pkg_dir}" ] || continue
        custom_install_pkgs+=("$(basename "${pkg_dir}")")
    done
    if [ "${#custom_install_pkgs[@]}" -gt 0 ]; then
        printf 'custom-install befores ---------------- start\n'
        printf '  %s\n' "${custom_install_pkgs[@]}"
        printf 'custom-install befores ---------------- end\n\n'
        for pkg in "${custom_install_pkgs[@]}"; do
            DOTFILES_DIR="${DIR}" "${DIR}/scripts/run-custom-install-hook" "${pkg}" before
        done
    fi
fi

# ------------------------------------------------------------------
# Step 2 — install packages.
# ------------------------------------------------------------------
if [ "${OS}" = "Darwin" ]; then
    [ "${UPDATE}" -eq 1 ] && { say "brew update"; brew update; }
    say "brew bundle (packages/Brewfile)"
    # Classify ownership BEFORE bundling: formulae/casks already present are
    # recorded `present` (so --purge never removes them); the rest we record
    # `install` once the post-bundle check confirms they landed.
    brew_names="$(awk -F'"' '/^[[:space:]]*(brew|cask)[[:space:]]+"/{print $2}' \
        "${DIR}/packages/Brewfile")"
    brew_new=()
    # shellcheck disable=SC2086
    for p in ${brew_names}; do
        if pkg_installed brew "${p}"; then
            state_record package present "${p}" "mgr=brew"
        else
            brew_new+=("${p}")
        fi
    done
    brew bundle --file="${DIR}/packages/Brewfile"
    if [ "${#brew_new[@]}" -gt 0 ]; then
        for p in "${brew_new[@]}"; do
            pkg_installed brew "${p}" && state_record package install "${p}" "mgr=brew"
        done
    fi
    [ "${UPDATE}" -eq 1 ] && { say "brew upgrade"; brew upgrade; }

elif [ "${OS}" = "Linux" ] && [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    INSTALL_CMD=""
    UPDATE_CMD=""
    UPGRADE_CMD=""
    BASELINE=""
    DESKTOP=""
    PKG_KIND=""
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            UPDATE_CMD="sudo apt-get update"
            INSTALL_CMD="sudo apt-get install -y"
            UPGRADE_CMD="sudo apt-get upgrade -y"
            BASELINE="${DIR}/packages/apt.list"
            DESKTOP="${DIR}/packages/apt-desktop.list"
            PKG_KIND="apt"
            ;;
        arch|manjaro|endeavouros|artix)
            UPDATE_CMD="sudo pacman -Syy --noconfirm"
            INSTALL_CMD="sudo pacman -S --needed --noconfirm"
            UPGRADE_CMD="sudo pacman -Syu --noconfirm"
            BASELINE="${DIR}/packages/pacman.list"
            DESKTOP="${DIR}/packages/pacman-desktop.list"
            PKG_KIND="pacman"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            UPDATE_CMD="sudo dnf check-update || true"
            INSTALL_CMD="sudo dnf install -y"
            UPGRADE_CMD="sudo dnf upgrade -y"
            BASELINE="${DIR}/packages/dnf.list"
            DESKTOP="${DIR}/packages/dnf-desktop.list"
            PKG_KIND="dnf"
            ;;
        *)
            say "distro ${ID:-unknown} not mapped; skipping native package install"
            ;;
    esac

    # Drop apt packages that have no install candidate on this release
    # (rust-analyzer, mold, … are version-gated to newer Debian/Ubuntu).
    # apt-get install is all-or-nothing: one unknown name aborts the whole
    # batch and installs nothing, so filter them out here — logging each
    # skip — rather than letting the run fail. Needs the apt cache, which
    # the UPDATE_CMD above has already refreshed.
    apt_keep_installable() {
        local p cand keep=()
        for p in "$@"; do
            cand="$(apt-cache policy "${p}" 2>/dev/null \
                    | awk -F': ' '/Candidate:/{print $2; exit}')"
            if [ -n "${cand}" ] && [ "${cand}" != "(none)" ]; then
                keep+=("${p}")
            else
                # stderr, not `say` (stdout): this function's stdout is
                # captured by `pkgs="$(apt_keep_installable …)"`, so a skip
                # line on stdout would be passed to `apt-get install` as
                # bogus package names ("Unable to locate package skip", …).
                printf '  skip (no apt candidate on this release): %s\n' "${p}" >&2
            fi
        done
        printf '%s ' "${keep[@]}"
    }

    if [ -n "${INSTALL_CMD}" ]; then
        eval "${UPDATE_CMD}"
        [ "${UPDATE}" -eq 1 ] && eval "${UPGRADE_CMD}"

        LISTS=("${BASELINE}")
        [ "${PROFILE}" = "desktop" ] && LISTS+=("${DESKTOP}")
        for list in "${LISTS[@]}"; do
            [ -f "${list}" ] || continue
            # Strip full-line AND inline `# …` comments, then blank lines.
            pkgs="$(sed -E 's/[[:space:]]*#.*$//' "${list}" \
                    | grep -vE '^\s*$' | tr '\n' ' ')"
            # On apt, prune entries with no candidate so the batch survives.
            if [ "${PKG_KIND}" = "apt" ] && [ -n "${pkgs}" ]; then
                # shellcheck disable=SC2086
                pkgs="$(apt_keep_installable ${pkgs})"
            fi
            if [ -n "${pkgs}" ]; then
                say "installing from ${list##*/}"
                # Classify ownership BEFORE installing: anything already
                # present is recorded `present` (so --purge never removes it);
                # the rest we attempt to install and, if the post-check
                # confirms it landed, record `install`.
                new_pkgs=()
                # shellcheck disable=SC2086
                for p in ${pkgs}; do
                    if pkg_installed "${PKG_KIND}" "${p}"; then
                        state_record package present "${p}" "mgr=${PKG_KIND}"
                    else
                        new_pkgs+=("${p}")
                    fi
                done
                # shellcheck disable=SC2086
                ${INSTALL_CMD} ${pkgs}
                if [ "${#new_pkgs[@]}" -gt 0 ]; then
                    for p in "${new_pkgs[@]}"; do
                        pkg_installed "${PKG_KIND}" "${p}" \
                            && state_record package install "${p}" "mgr=${PKG_KIND}"
                    done
                fi
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
# Step 3.5 — packages/custom-install/<pkg>/after.sh hooks.
# Run AFTER the package install step + AUR/Snap fallback so each
# script can provision toolchains (e.g. `rustup default stable`),
# enable services, etc. Output goes through
# scripts/run-custom-install-hook which tees to
# ~/.local/state/dotfiles/custom-install.log. CUSTOM_INSTALL_DIR was
# set above for the before-pass; we reuse it here.
# ------------------------------------------------------------------
if [ -d "${CUSTOM_INSTALL_DIR}" ] && [ "${#custom_install_pkgs[@]}" -gt 0 ]; then
    printf 'custom-install afters ----------------- start\n'
    printf '  %s\n' "${custom_install_pkgs[@]}"
    printf 'custom-install afters ----------------- end\n\n'
    for pkg in "${custom_install_pkgs[@]}"; do
        DOTFILES_DIR="${DIR}" "${DIR}/scripts/run-custom-install-hook" "${pkg}" after
    done
fi

# ------------------------------------------------------------------
# Step 3.6 — generic script-based installers (packages/script-install.list).
# Tools shipped ONLY as an upstream `curl … | sh` installer, absent from
# brew/apt/pacman/dnf/snap/aur. Runs AFTER the native + fallback lanes so it
# fires only on hosts where none of them provided the tool — the runner
# probes `command -v <bin>` and skips anything already on PATH. Streams to
# ~/.local/state/dotfiles/script-install.log. See run-script-installers.
# ------------------------------------------------------------------
if [ -f "${DIR}/packages/script-install.list" ]; then
    say "script-based installers (packages/script-install.list)"
    DOTFILES_DIR="${DIR}" "${DIR}/scripts/run-script-installers"
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
    state_record bootstrap fetch "${HOME}/.vim/autoload/plug.vim" "name=vim-plug"
fi

# TPM (tmux plugin manager)
if [ ! -d "${HOME}/.config/tmux/plugins/tpm" ]; then
    say "  installing TPM"
    mkdir -p "${HOME}/.config/tmux/plugins"
    git clone --depth=1 https://github.com/tmux-plugins/tpm \
        "${HOME}/.config/tmux/plugins/tpm"
    state_record plugin clone "${HOME}/.config/tmux/plugins/tpm" "name=tpm"
fi

# zsh-you-should-use — fall back to git clone if no native package on PATH.
if [ ! -d "${HOME}/.config/zsh-plugins/zsh-you-should-use" ] \
   && [ ! -f /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh ] \
   && [ ! -f /usr/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh ]; then
    say "  installing zsh-you-should-use"
    mkdir -p "${HOME}/.config/zsh-plugins"
    git clone --depth=1 https://github.com/MichaelAquilina/zsh-you-should-use \
        "${HOME}/.config/zsh-plugins/zsh-you-should-use"
    state_record plugin clone "${HOME}/.config/zsh-plugins/zsh-you-should-use" "name=zsh-you-should-use"
fi

# bash-preexec — single-file shell dependency that gives bash the
# preexec/precmd hooks atuin's bash integration relies on. Dropped at
# ~/.bash-preexec.sh and sourced by .load's bash block before
# `atuin init bash`. Not in any package manager; fetched here like
# vim-plug.
if [ ! -f "${HOME}/.bash-preexec.sh" ]; then
    say "  installing bash-preexec"
    curl -fsSLo "${HOME}/.bash-preexec.sh" \
        https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh
    state_record bootstrap fetch "${HOME}/.bash-preexec.sh" "name=bash-preexec"
fi

# starship, atuin, claude and lefthook used to be installed inline here
# as Debian release-binary fallbacks. They now live as custom-install
# hooks (packages/custom-install/<pkg>/after.sh), run in Step 3.5 above:
# each falls back to the upstream binary only when the native package
# manager didn't provide the tool, and owns its PATH via .path. See
# CLAUDE.md §10 and packages/custom-install/README.md.

# ------------------------------------------------------------------
# Step 4.5 — ensure the claude-skills repo exists and has its private mirror.
#
# Skills are never vendored in this repo (see doc/claude-skills.md) — they
# live in a separate git repo that scripts/symlinks.sh links from. On a
# brand-new host that repo doesn't exist yet: `init` creates it empty via
# `git init`. `ensure-remote` then guarantees the required PRIVATE GitHub
# mirror, named after the dotfiles owner (<owner>/claude-skills, derived from
# this repo's own origin). It runs --interactive here specifically because a
# human is present: if the GitHub repo has to be created, setup.sh asks first
# (scripts/update-dotfiles, which may run unattended, creates it silently).
# Declining is non-fatal — it's re-checked on the next run. Bundles
# (`scripts/claude-skills bundle|restore`) remain the second, local-only
# backup layer.
# ------------------------------------------------------------------
"${DIR}/scripts/claude-skills" init
"${DIR}/scripts/claude-skills" ensure-remote --interactive

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

CURRENT_SHELL="$(current_login_shell)"
if [ -z "${ZSH_BIN}" ]; then
    say "WARN: zsh not on PATH; skipping shell change"
elif [ "${CURRENT_SHELL}" = "${ZSH_BIN}" ]; then
    say "login shell already ${ZSH_BIN}"
else
    if ! grep -qxF "${ZSH_BIN}" /etc/shells 2>/dev/null; then
        say "registering ${ZSH_BIN} in /etc/shells (sudo)"
        echo "${ZSH_BIN}" | sudo tee -a /etc/shells >/dev/null
    fi
    say "setting login shell to ${ZSH_BIN} (sudo)"
    sudo chsh -s "${ZSH_BIN}" "${USER}"
    # Record the prior shell so uninstall --shell can chsh back to it.
    state_record shell chsh "${ZSH_BIN}" "from=${CURRENT_SHELL}"
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
