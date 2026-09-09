#!/usr/bin/env bash
# scripts/uninstall.sh — one-pass, user-scoped uninstall of this repo's
# footprint. Phase 4 of v3-native (see doc/v3-native-inventory.md).
#
# Reverses what the realized-state ledger (scripts/dotfiles-state.sh)
# records THIS repo as having planted on THIS host — never anything
# that predates ./setup.sh:
#   1. every symlink scripts/symlinks.sh planted (the ledger is the
#      cross-check),
#   2. ledger-recorded plugin checkouts and bootstrap files (tpm,
#      zsh-you-should-use, vim-plug, bash-preexec) plus the manager-
#      owned plugin trees (~/.vim/plugged, ~/.config/tmux/plugins),
#   3. every `# >>> <pkg> begin … end` segment in $HOME/.dotfiles/path
#      (and the legacy in-repo .path, if this host never migrated),
#   4. directories the above left empty (rmdir only — a dir that still
#      holds user files survives untouched).
#
# Optional tiers (off by default):
#   --purge   remove the packages the ledger records `install` (NEVER
#             `present` ones — those predate this repo) via the manager
#             that installed them. AUR / Snap fallbacks are not
#             ledger-tracked; they are flagged for manual removal.
#   --shell   chsh back to the `from=` login shell recorded at setup
#             time (sudo, same as setup.sh).
#   --dry-run print every action, execute nothing (alias: DRY_RUN=1).
#
# Usage:
#   scripts/uninstall.sh [--dry-run] [--purge] [--shell]
#
# Never touched: user data and runtime state — ~/.claude credentials,
# history, projects; ~/.gnupg keys; atuin's history db; shell history.
# Everything removed is re-creatable with ./setup.sh.
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
PURGE=0
REVERT_SHELL=0
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=1 ;;
        --purge)   PURGE=1 ;;
        --shell)   REVERT_SHELL=1 ;;
        -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
        *) printf 'ERR: unknown argument: %s\n' "${arg}" >&2; exit 1 ;;
    esac
done

say() { printf '==> %s\n' "$*"; }

# shellcheck source=scripts/dotfiles-dir.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/dotfiles-dir.sh"
REPO_ROOT="${DOTFILES_DIR}"
if [ ! -d "${REPO_ROOT}" ]; then
    printf 'ERR: repo not found at %s — set DOTFILES_DIR.\n' "${REPO_ROOT}" >&2
    exit 1
fi
SYMLINKS="${REPO_ROOT}/scripts/symlinks.sh"

# shellcheck source=scripts/dotfiles-state.sh
. "${REPO_ROOT}/scripts/dotfiles-state.sh"
state_begin_run >/dev/null

# Desktop links must be caught regardless of the profile this host
# installed with (they only exist if setup ran with --desktop, and
# _uninstall_one skips non-matching links, so forcing the wider scope
# is a no-op elsewhere).
export DOTFILES_DESKTOP=1

run_cmd() {
    if [ "${DRY_RUN}" = "1" ]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

do_rm_rf() {
    if [ "${DRY_RUN}" = "1" ]; then
        printf '[dry-run] rm -rf %s\n' "$1"
    else
        rm -rf "$1"
        printf '  removed: %s\n' "$1"
    fi
}

current_login_shell() {
    if command -v getent >/dev/null 2>&1; then
        getent passwd "${USER}" | awk -F: '{print $NF}'
    elif [ "$(uname)" = "Darwin" ]; then
        dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}'
    else
        awk -F: -v u="${USER}" '$1==u {print $NF}' /etc/passwd
    fi
}

# Links that currently resolve into this repo — a mirror of symlinks.sh's
# own _uninstall_one test, pre-captured so the empty-dir walk (step 4)
# knows every dst involved even after the links (and their ledger
# records) are gone. The actual removal stays symlinks.sh's job.
matching_links() {
    local entry src dst full
    "${SYMLINKS}" list | while IFS= read -r entry; do
        [ -z "${entry}" ] && continue
        src="${entry%%::*}"
        dst="${entry##*::}"
        case "${src}" in /*) full="${src}" ;; *) full="${REPO_ROOT}/${src}" ;; esac
        if [ -L "${HOME}/${dst}" ] && [ "$(readlink "${HOME}/${dst}")" = "${full}" ]; then
            printf '%s\n' "${dst}"
        fi
    done
}

# rmdir upward while dirs are empty; first non-empty dir stops the walk.
# Never rm -rf: a dir that still holds user files survives untouched.
prune_parents() {
    local d
    d="$(dirname "$1")"
    while [ "${d}" != "${HOME}" ] && [ -d "${d}" ]; do
        rmdir "${d}" 2>/dev/null || return 0
        printf '  rmdir (empty): %s\n' "${d}"
        d="$(dirname "${d}")"
    done
}

# === Pre-capture the realized state (negation records below drop
# ledger entries, so everything is read BEFORE any mutation). ===
PLANTED_DSTS="$(matching_links)"
PLUGIN_PATHS="$(state_reduce plugin | awk -F'\t' '$4 == "clone" {print $5}')"
BOOTSTRAP_PATHS="$(state_reduce bootstrap | awk -F'\t' '$4 == "fetch" {print $5}')"
OWNED_PKGS="$(state_reduce package | awk -F'\t' '$4 == "install" {print $5 "\t" $6}' | sort -u)"
SHELL_REC="$(state_reduce shell | head -n 1)"

# === Step 1 — symlinks ==============================================
say "symlinks planted by this repo"
if [ "${DRY_RUN}" = "1" ]; then
    [ -n "${PLANTED_DSTS}" ] \
        && printf '%s\n' "${PLANTED_DSTS}" | sed 's|^|  [dry-run] remove link: ~|'
    [ -z "${PLANTED_DSTS}" ] && printf '  (none planted)\n'
else
    "${SYMLINKS}" uninstall
fi

# Ledger-recorded removal of one path (plugin checkout or bootstrap
# file); the matching negation record drops it from the realized set.
remove_ledger_paths() {
    # $1 = ledger domain, $2 = newline-separated path list
    local domain="$1"
    while IFS= read -r path; do
        [ -z "${path}" ] && continue
        case "${path}" in
            "${HOME}"/*) ;;
            *) printf '  skip (outside HOME): %s\n' "${path}"; continue ;;
        esac
        if [ -e "${path}" ]; then
            do_rm_rf "${path}"
        else
            printf '  skip (gone): %s\n' "${path}"
        fi
        state_record "${domain}" remove "${path}" "uninstalled=true"
    done <<< "$2"
}

# === Step 2 — plugin checkouts + bootstrap files (ledger) ===========
say "plugin checkouts and bootstrap files (ledger)"
remove_ledger_paths plugin "${PLUGIN_PATHS}"
remove_ledger_paths bootstrap "${BOOTSTRAP_PATHS}"

# Manager-owned plugin trees the ledger deliberately does not track
# (per-plugin checkouts, not the bootstrapped managers themselves):
# vim-plug's ~/.vim/plugged and everything TPM planted next to tpm.
say "manager-owned plugin trees"
for d in "${HOME}/.vim/plugged" "${HOME}/.config/tmux/plugins"; do
    [ -e "${d}" ] || continue
    do_rm_rf "${d}"
done

# === Step 3 — path segments ========================================
# $HOME/.dotfiles/path is current; ${REPO_ROOT}/.path is the legacy
# in-repo location — stripped too, in case this host never migrated.
say "path segments"
strip_path_segments() {
    local path_file="$1"
    if [ -f "${path_file}" ] && grep -q '^# >>> .* begin$' "${path_file}"; then
        local n_seg
        n_seg="$(grep -c '^# >>> .* begin$' "${path_file}")"
        if [ "${DRY_RUN}" = "1" ]; then
            printf '  [dry-run] strip %s segment(s) from %s\n' "${n_seg}" "${path_file}"
        else
            sed -i.bak '/^# >>> .* begin$/,/^# >>> .* end$/d' "${path_file}"
            printf '  stripped %s segment(s) from %s\n' "${n_seg}" "${path_file}"
        fi
    else
        printf '  (none to strip in %s)\n' "${path_file}"
    fi
}
strip_path_segments "${HOME}/.dotfiles/path"
strip_path_segments "${REPO_ROOT}/.path"

# === Step 4 — directories left empty ===============================
if [ "${DRY_RUN}" = "1" ]; then
    say "empty directories left behind"
    printf '  [dry-run] would rmdir now-empty parent dirs\n'
else
    say "empty directories left behind"
    printf '%s\n' "${PLANTED_DSTS}" | while IFS= read -r dst; do
        [ -z "${dst}" ] && continue
        prune_parents "${HOME}/${dst}"
    done
    for paths in "${PLUGIN_PATHS}" "${BOOTSTRAP_PATHS}"; do
        while IFS= read -r path; do
            [ -z "${path}" ] && continue
            prune_parents "${path}"
        done <<< "${paths}"
    done
    prune_parents "${HOME}/.vim/plugged"
    prune_parents "${HOME}/.config/tmux/plugins"
fi

# === Step 5 — --purge: ledger-owned packages ========================
if [ "${PURGE}" = "1" ]; then
    say "packages recorded install (never present ones)"
    while IFS=$'\t' read -r pkg detail; do
        [ -z "${pkg}" ] && continue
        mgr="${detail#mgr=}"
        case "${mgr}" in
            brew)
                if ! command -v brew >/dev/null 2>&1; then
                    printf '  skip (no brew): %s\n' "${pkg}"; continue
                fi
                if brew list --formula "${pkg}" >/dev/null 2>&1; then
                    run_cmd brew uninstall --formula "${pkg}"
                elif brew list --cask "${pkg}" >/dev/null 2>&1; then
                    run_cmd brew uninstall --cask "${pkg}"
                else
                    printf '  skip (not installed): %s\n' "${pkg}"; continue
                fi
                ;;
            apt)
                pkg_installed apt "${pkg}" || { printf '  skip (not installed): %s\n' "${pkg}"; continue; }
                run_cmd sudo apt-get purge -y "${pkg}"
                ;;
            pacman)
                pkg_installed pacman "${pkg}" || { printf '  skip (not installed): %s\n' "${pkg}"; continue; }
                run_cmd sudo pacman -R --noconfirm "${pkg}"
                ;;
            dnf)
                pkg_installed dnf "${pkg}" || { printf '  skip (not installed): %s\n' "${pkg}"; continue; }
                run_cmd sudo dnf remove -y "${pkg}"
                ;;
            script)
                bin="$(command -v "${pkg}" || true)"
                # The script lane installs into ~/.local/bin
                # (run-script-installers); probe the canonical location
                # too, in case this shell's PATH lacks it.
                if [ -z "${bin}" ] && [ -x "${HOME}/.local/bin/${pkg}" ]; then
                    bin="${HOME}/.local/bin/${pkg}"
                fi
                if [ -z "${bin}" ]; then
                    printf '  skip (not installed): %s\n' "${pkg}"; continue
                fi
                case "${bin}" in
                    "${HOME}"/*) ;;
                    *) printf '  skip (outside HOME): %s\n' "${bin}"; continue ;;
                esac
                do_rm_rf "${bin}"
                ;;
            *)
                printf '  skip (unknown mgr %s): %s\n' "${mgr}" "${pkg}"; continue
                ;;
        esac
        state_record package purge "${pkg}" "mgr=${mgr}"
    done <<< "${OWNED_PKGS}"
    printf '  note: AUR / Snap fallbacks are not ledger-tracked — see\n'
    printf '  packages/aur.list and packages/snap.list for manual removal.\n'
fi

# === Step 6 — --shell: revert the login shell ======================
if [ "${REVERT_SHELL}" = "1" ]; then
    say "login shell"
    if [ -z "${SHELL_REC}" ]; then
        printf '  (no shell change recorded — nothing to revert)\n'
    else
        new_shell="$(printf '%s' "${SHELL_REC}" | awk -F'\t' '{print $5}')"
        old_shell="$(printf '%s' "${SHELL_REC}" | awk -F'\t' '{sub(/^from=/, "", $6); print $6}')"
        cur="$(current_login_shell)"
        if [ "${cur}" = "${old_shell}" ]; then
            printf '  login shell already %s\n' "${old_shell}"
        else
            run_cmd sudo chsh -s "${old_shell}" "${USER}"
            state_record shell revert "${new_shell}" "to=${old_shell}"
            printf '  reverted login shell to %s (takes effect next login)\n' "${old_shell}"
        fi
    fi
fi

say "done — re-plant any time with ./setup.sh"
printf 'note: ~/.zshrc / ~/.bashrc symlinks are gone; your shell falls\n'
printf 'back to system defaults until you re-plant or write your own.\n'