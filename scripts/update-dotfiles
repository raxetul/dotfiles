#!/usr/bin/env bash
# scripts/update.sh — refresh everything this repo manages.
#
# Two layers, both idempotent and runnable independently:
#
#   packages       — git pull, brew update + bundle + cleanup on macOS,
#                    distro install on Linux (apt/pacman/dnf + AUR/Snap).
#   configurations — symlink check, lefthook hooks, bat cache,
#                    tmux/nvim/atuin reloads where applicable.
#
# Defaults to running both layers in order. Each step prints its own
# "==> stage" banner; on failure the script exits non-zero.
#
# Usage:
#   scripts/update.sh                          # both layers
#   scripts/update.sh --dry-run                # print every command, run none
#   scripts/update.sh --yes                    # skip the git-pull confirmation
#   scripts/update.sh --desktop                # include Linux desktop list
#   scripts/update.sh --only=packages          # packages layer only
#   scripts/update.sh --only=configurations    # configurations layer only
#
# Exit codes:
#   0   success
#   1   bad CLI arg, missing dependency, or a stage failed
set -euo pipefail

DRY_RUN=0
YES=0
DESKTOP=0
ONLY=""

for arg in "$@"; do
    case "${arg}" in
        --dry-run)             DRY_RUN=1 ;;
        --yes|-y)              YES=1 ;;
        --desktop)             DESKTOP=1 ;;
        --only=packages)       ONLY="packages" ;;
        --only=configurations) ONLY="configurations" ;;
        --only=*)
            echo "Unknown --only value: ${arg#--only=}" >&2
            echo "Valid: packages, configurations" >&2
            exit 1
            ;;
        -h|--help)
            sed -n '2,26p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}" >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

note()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
fail()  { printf '\033[1;31mERR:\033[0m  %s\n' "$*" >&2; exit 1; }

# do_or_say <command...> — execute, or echo a "[dry-run]" preview.
do_or_say() {
    if [ "${DRY_RUN}" -eq 1 ]; then
        printf '   [dry-run] would: %s\n' "$*"
    else
        "$@"
    fi
}

# do_or_say_sh '<single shell snippet>' — like do_or_say but for snippets
# that depend on shell syntax (pipes, redirects). Treated as one logical
# step from the dry-run printer's perspective.
do_or_say_sh() {
    if [ "${DRY_RUN}" -eq 1 ]; then
        printf '   [dry-run] would (sh): %s\n' "$*"
    else
        sh -c "$*"
    fi
}

run_stage() {
    local name="$1"; shift
    note "stage: ${name}"
    if ! "$@"; then
        fail "stage ${name} failed"
    fi
}

# ----------------------------------------------------------------------
# Packages layer
# ----------------------------------------------------------------------

stage_packages_git_pull() {
    note "git pull --rebase"
    if [ "${YES}" -ne 1 ] && [ "${DRY_RUN}" -ne 1 ]; then
        # Confirm before pulling because pull can rewrite the working
        # tree (rebase, autostash). --yes bypasses for unattended runs.
        printf '   pull origin and rebase local commits? [y/N] '
        read -r ans
        case "${ans}" in
            y|Y|yes) ;;
            *) note "   skipped on user request"; return 0 ;;
        esac
    fi
    do_or_say git pull --rebase
}

stage_packages_brew() {
    if [ "$(uname)" != "Darwin" ]; then
        return 0
    fi
    if ! command -v brew >/dev/null 2>&1; then
        warn "brew not on PATH; skipping Brewfile replay"
        return 0
    fi
    note "brew update / upgrade / bundle / cleanup"
    do_or_say brew update
    do_or_say brew upgrade
    do_or_say brew bundle --file "${REPO_ROOT}/packages/Brewfile"
    do_or_say brew cleanup
}

stage_packages_native_linux() {
    if [ "$(uname)" != "Linux" ] || [ ! -f /etc/os-release ]; then
        return 0
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    local install_cmd update_cmd upgrade_cmd baseline desktop_list
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            update_cmd="sudo apt-get update"
            upgrade_cmd="sudo apt-get upgrade -y"
            install_cmd="sudo apt-get install -y"
            baseline="${REPO_ROOT}/packages/apt.list"
            desktop_list="${REPO_ROOT}/packages/apt-desktop.list"
            ;;
        arch|manjaro|endeavouros|artix)
            update_cmd="sudo pacman -Syy --noconfirm"
            upgrade_cmd="sudo pacman -Syu --noconfirm"
            install_cmd="sudo pacman -S --needed --noconfirm"
            baseline="${REPO_ROOT}/packages/pacman.list"
            desktop_list="${REPO_ROOT}/packages/pacman-desktop.list"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            update_cmd="sudo dnf check-update || true"
            upgrade_cmd="sudo dnf upgrade -y"
            install_cmd="sudo dnf install -y"
            baseline="${REPO_ROOT}/packages/dnf.list"
            desktop_list="${REPO_ROOT}/packages/dnf-desktop.list"
            ;;
        *)
            note "distro ${ID:-unknown} not mapped; skipping native update"
            return 0
            ;;
    esac

    do_or_say_sh "${update_cmd}"
    do_or_say_sh "${upgrade_cmd}"

    local lists=("${baseline}")
    [ "${DESKTOP}" -eq 1 ] && lists+=("${desktop_list}")
    for list in "${lists[@]}"; do
        [ -f "${list}" ] || continue
        local pkgs
        pkgs="$(grep -vE '^\s*(#|$)' "${list}" | tr '\n' ' ')"
        if [ -n "${pkgs}" ]; then
            note "installing from ${list##*/}"
            # shellcheck disable=SC2086
            do_or_say ${install_cmd} ${pkgs}
        fi
    done
}

stage_packages_linux_fallback() {
    if [ "$(uname)" != "Linux" ] || [ ! -f /etc/os-release ]; then
        return 0
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    case "${ID:-}" in
        arch|manjaro|endeavouros|artix)
            local aur_list="${REPO_ROOT}/packages/aur.list"
            if [ -f "${aur_list}" ] && command -v yay >/dev/null 2>&1; then
                local pkgs
                pkgs="$(grep -vE '^\s*(#|$)' "${aur_list}" | tr '\n' ' ')"
                if [ -n "${pkgs}" ]; then
                    note "AUR install via yay"
                    # shellcheck disable=SC2086
                    do_or_say yay -S --needed --noconfirm ${pkgs}
                fi
            fi
            ;;
        debian|ubuntu|pop|linuxmint|fedora|rhel|centos|almalinux|rocky)
            local snap_list="${REPO_ROOT}/packages/snap.list"
            if [ -f "${snap_list}" ] && command -v snap >/dev/null 2>&1; then
                while IFS= read -r line; do
                    case "${line}" in ""|"#"*) continue ;; esac
                    note "snap install ${line}"
                    # shellcheck disable=SC2086
                    do_or_say sudo snap install ${line}
                done < "${snap_list}"
            fi
            ;;
    esac
}

run_packages() {
    run_stage "git-pull"        stage_packages_git_pull
    run_stage "brew"            stage_packages_brew
    run_stage "native-linux"    stage_packages_native_linux
    run_stage "linux-fallback"  stage_packages_linux_fallback
}

# ----------------------------------------------------------------------
# Configurations layer
# ----------------------------------------------------------------------

stage_configurations_symlinks() {
    note "scripts/symlinks.sh install"
    [ "${DESKTOP}" -eq 1 ] && export DOTFILES_DESKTOP=1
    do_or_say "${REPO_ROOT}/scripts/symlinks.sh" install
}

stage_configurations_lefthook() {
    if ! command -v lefthook >/dev/null 2>&1; then
        warn "lefthook not on PATH; skipping hook refresh"
        return 0
    fi
    note "lefthook install"
    do_or_say lefthook install
    note "lefthook run pre-commit --all-files"
    do_or_say lefthook run pre-commit --all-files
}

stage_configurations_bat_cache() {
    if ! command -v bat >/dev/null 2>&1; then
        return 0
    fi
    note "bat cache --build"
    do_or_say bat cache --build
}

stage_configurations_tmux_reload() {
    # Best-effort: only meaningful if a tmux server is actually running.
    if ! command -v tmux >/dev/null 2>&1; then
        return 0
    fi
    if ! tmux info >/dev/null 2>&1; then
        return 0
    fi
    note "tmux source-file ~/.config/tmux/tmux.conf"
    do_or_say tmux source-file "${HOME}/.config/tmux/tmux.conf" || \
        warn "tmux source-file failed (non-fatal)"
}

stage_configurations_tpm() {
    local tpm="${HOME}/.config/tmux/plugins/tpm/bin/install_plugins"
    if [ ! -x "${tpm}" ]; then
        return 0
    fi
    note "tpm install_plugins (headless)"
    do_or_say "${tpm}" || warn "tpm install_plugins failed (non-fatal)"
}

stage_configurations_vim_plug() {
    if ! command -v vim >/dev/null 2>&1; then
        return 0
    fi
    note "vim +PlugInstall +qa --headless"
    do_or_say_sh "vim +PlugInstall +qa --headless 2>/dev/null || true"
}

stage_configurations_atuin_daemon() {
    if ! command -v atuin >/dev/null 2>&1; then
        return 0
    fi
    if ! atuin --help 2>&1 | grep -q '^[[:space:]]*daemon'; then
        return 0
    fi
    note "atuin daemon restart"
    do_or_say_sh "atuin daemon restart >/dev/null 2>&1 || true"
}

run_configurations() {
    run_stage "symlinks"        stage_configurations_symlinks
    run_stage "lefthook"        stage_configurations_lefthook
    run_stage "bat-cache"       stage_configurations_bat_cache
    run_stage "tmux-reload"     stage_configurations_tmux_reload
    run_stage "tpm"             stage_configurations_tpm
    run_stage "vim-plug"        stage_configurations_vim_plug
    run_stage "atuin-daemon"    stage_configurations_atuin_daemon
}

# ----------------------------------------------------------------------
# Dispatch
# ----------------------------------------------------------------------

note "update.sh  (dry-run=${DRY_RUN}, yes=${YES}, desktop=${DESKTOP}, only=${ONLY:-both})"
note "repo: ${REPO_ROOT}"
echo

case "${ONLY}" in
    packages)        run_packages ;;
    configurations)  run_configurations ;;
    "")              run_packages; echo; run_configurations ;;
esac

echo
note "done."
