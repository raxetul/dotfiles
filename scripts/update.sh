#!/usr/bin/env bash
# scripts/update.sh — refresh everything this repo manages.
#
# Two layers, both idempotent and runnable independently:
#
#   packages       — git pull, nix flake update, home-manager switch,
#                    brew bundle on macOS, distro install on Linux.
#   configurations — verify scoped backup state, lefthook hooks, bat
#                    cache, tmux/nvim/atuin reloads where applicable.
#
# Defaults to running both layers in order. Each step prints its own
# "==> stage" banner; on failure the script exits non-zero and tells
# you which stage failed.
#
# Usage:
#   scripts/update.sh                          # both layers
#   scripts/update.sh --dry-run                # print every command, run none
#   scripts/update.sh --yes                    # skip the git-pull confirmation
#   scripts/update.sh --no-flake               # skip `nix flake update`
#   scripts/update.sh --only=packages          # packages layer only
#   scripts/update.sh --only=configurations    # configurations layer only
#
# Exit codes:
#   0   success
#   1   bad CLI arg, missing dependency, or a stage failed
set -euo pipefail

DRY_RUN=0
YES=0
NO_FLAKE=0
ONLY=""

for arg in "$@"; do
    case "${arg}" in
        --dry-run)          DRY_RUN=1 ;;
        --yes|-y)           YES=1 ;;
        --no-flake)         NO_FLAKE=1 ;;
        --only=packages)    ONLY="packages" ;;
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

# Run a stage and bail loudly if it fails. The trap unwinds with the
# stage name so users see "stage X failed" even if the actual error was
# 5 levels down inside a sub-shell.
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

stage_packages_flake_update() {
    if [ "${NO_FLAKE}" -eq 1 ]; then
        note "nix flake update — skipped (--no-flake)"
        return 0
    fi
    note "nix flake update"
    do_or_say nix flake update
}

stage_packages_hm_switch() {
    # Reuses the per-day, per-run backup-suffix scheme that setup.sh
    # established so home-manager's clash-handling stays consistent
    # whether the user came in via setup or update.
    local date_str last_n suffix
    date_str="$(date +%Y-%m-%d)"
    last_n="$(find "${HOME}" -maxdepth 4 -name "*.backup-${date_str}---*" 2>/dev/null \
        | sed -nE "s/.*\\.backup-${date_str}---([0-9]+)\$/\\1/p" \
        | sort -n | tail -1)"
    suffix="backup-${date_str}---$(( ${last_n:-0} + 1 ))"
    note "home-manager switch  (backup suffix: ${suffix})"
    do_or_say nix run --impure home-manager/master -- \
        switch --impure --flake "${REPO_ROOT}#default" -b "${suffix}"
}

stage_packages_brew() {
    if [ "$(uname)" != "Darwin" ]; then
        return 0
    fi
    if ! command -v brew >/dev/null 2>&1; then
        warn "brew not on PATH; skipping Brewfile replay"
        return 0
    fi
    note "brew update / bundle / cleanup"
    do_or_say brew update
    do_or_say brew bundle --file "${REPO_ROOT}/configurations/brew/Brewfile"
    do_or_say brew cleanup
}

stage_packages_native_linux() {
    if [ "$(uname)" != "Linux" ] || [ ! -f /etc/os-release ]; then
        return 0
    fi
    # shellcheck source=/dev/null
    . /etc/os-release
    local list cmd
    case "${ID:-}" in
        debian|ubuntu|pop|linuxmint)
            list="${REPO_ROOT}/configurations/native/apt.list"
            cmd="sudo apt-get install -y"
            ;;
        arch|manjaro|endeavouros)
            list="${REPO_ROOT}/configurations/native/pacman.list"
            cmd="sudo pacman -S --needed --noconfirm"
            ;;
        fedora|rhel|centos|almalinux|rocky)
            list="${REPO_ROOT}/configurations/native/dnf.list"
            cmd="sudo dnf install -y"
            ;;
        *)
            note "distro ${ID:-unknown} not mapped; skipping native install"
            return 0
            ;;
    esac
    if [ ! -f "${list}" ]; then
        return 0
    fi
    local pkgs
    pkgs="$(grep -vE '^\s*(#|$)' "${list}" | tr '\n' ' ')"
    if [ -z "${pkgs}" ]; then
        note "${list##*/} empty; nothing to install"
        return 0
    fi
    note "native install from ${list##*/}: ${pkgs}"
    # shellcheck disable=SC2086
    do_or_say ${cmd} ${pkgs}
}

run_packages() {
    run_stage "git-pull"        stage_packages_git_pull
    run_stage "flake-update"    stage_packages_flake_update
    run_stage "hm-switch"       stage_packages_hm_switch
    run_stage "brew"            stage_packages_brew
    run_stage "native-linux"    stage_packages_native_linux
}

# ----------------------------------------------------------------------
# Configurations layer
# ----------------------------------------------------------------------

stage_configurations_backup_check() {
    # Run backup-configs.sh in dry-run mode purely as a probe: it prints
    # one "managed:" line per path that's correctly symlinked into this
    # repo, and one "move:" line per path that regressed to a real file.
    # We don't auto-fix here; surfacing a regression is enough.
    note "backup-configs.sh (check-only)"
    if [ ! -x "${REPO_ROOT}/scripts/backup-configs.sh" ]; then
        warn "scripts/backup-configs.sh missing or not executable; skipping"
        return 0
    fi
    do_or_say "${REPO_ROOT}/scripts/backup-configs.sh"
}

stage_configurations_lefthook() {
    if ! command -v lefthook >/dev/null 2>&1; then
        warn "lefthook not on PATH; skipping hook refresh"
        return 0
    fi
    note "lefthook install"
    do_or_say lefthook install
    note "lefthook run pre-commit --all-files"
    # pre-commit failures here mean the working tree has stuff the hooks
    # would have rejected — surface that as a hard failure so the user
    # fixes it before continuing.
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

stage_configurations_nvim_lazy() {
    if ! command -v nvim >/dev/null 2>&1; then
        return 0
    fi
    note "nvim --headless +Lazy! sync +qa"
    # Lazy may not be present (we use vim-plug via the shared rc), so
    # treat failure as non-fatal.
    do_or_say nvim --headless "+Lazy! sync" +qa 2>/dev/null || \
        warn "nvim Lazy sync skipped or failed (non-fatal)"
}

stage_configurations_atuin_daemon() {
    if ! command -v atuin >/dev/null 2>&1; then
        return 0
    fi
    # The daemon only exists for sync; restart is a no-op if sync is off.
    if ! atuin --help 2>&1 | grep -q '^[[:space:]]*daemon'; then
        return 0
    fi
    note "atuin daemon restart"
    do_or_say_sh "atuin daemon restart >/dev/null 2>&1 || true"
}

run_configurations() {
    run_stage "backup-check"    stage_configurations_backup_check
    run_stage "lefthook"        stage_configurations_lefthook
    run_stage "bat-cache"       stage_configurations_bat_cache
    run_stage "tmux-reload"     stage_configurations_tmux_reload
    run_stage "tpm"             stage_configurations_tpm
    run_stage "nvim-lazy"       stage_configurations_nvim_lazy
    run_stage "atuin-daemon"    stage_configurations_atuin_daemon
}

# ----------------------------------------------------------------------
# Dispatch
# ----------------------------------------------------------------------

note "update.sh  (dry-run=${DRY_RUN}, yes=${YES}, no-flake=${NO_FLAKE}, only=${ONLY:-both})"
note "repo: ${REPO_ROOT}"
echo

case "${ONLY}" in
    packages)        run_packages ;;
    configurations)  run_configurations ;;
    "")              run_packages; echo; run_configurations ;;
esac

echo
note "done."
