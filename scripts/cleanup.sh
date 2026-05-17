#!/usr/bin/env bash
# scripts/cleanup.sh — Phase 0 safety net (temporary; deleted in Phase 14).
#
# Purpose: give you a clean rollback path before the v2 refactor starts.
# The script lists every dotfile this repo could be managing through Home
# Manager, snapshots the current state, optionally rolls Home Manager back
# one generation, then moves the live files into a timestamped backup
# directory so the next `home-manager switch` runs against a clean $HOME.
#
# Defaults to dry-run. Nothing is moved or deleted unless `--apply` is passed.
#
# Usage:
#   scripts/cleanup.sh             # dry-run report only (default)
#   scripts/cleanup.sh --apply     # actually move things
#   scripts/cleanup.sh --rollback  # also run `home-manager switch --rollback`
#   scripts/cleanup.sh --apply --rollback
#
# What it touches (scoped — leaves the rest of ~/.config alone):
#   ~/.zshrc
#   ~/.bashrc, ~/.bash_profile
#   ~/.tmux.conf
#   ~/.vimrc, ~/.vim/
#   ~/.gitconfig
#   ~/.config/starship.toml
#   ~/.config/nvim/
#   ~/.config/ghostty/
#   ~/.config/atuin/
#   ~/.config/bat/
#   ~/.config/fzf/
#   ~/.config/sway/
#   ~/.config/waybar/
#   ~/.config/dunst/
#
# Anything else under ~/.config/ (Slack, browsers, IDE state, …) is ignored.
set -euo pipefail

APPLY=0
ROLLBACK=0
for arg in "$@"; do
    case "${arg}" in
        --apply)    APPLY=1 ;;
        --rollback) ROLLBACK=1 ;;
        -h|--help)
            sed -n '2,32p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown argument: ${arg}" >&2
            exit 1
            ;;
    esac
done

TS="$(date +%Y-%m-%dT%H-%M-%S)"
BACKUP_DIR="${HOME}/.dotfiles-backup-${TS}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Items that may exist as real files / symlinks in $HOME and that this repo
# is about to (re)claim. Each entry is a path relative to $HOME.
SCOPED_PATHS=(
    ".zshrc"
    ".bashrc"
    ".bash_profile"
    ".tmux.conf"
    ".vimrc"
    ".vim"
    ".gitconfig"
    ".config/starship.toml"
    ".config/nvim"
    ".config/ghostty"
    ".config/atuin"
    ".config/bat"
    ".config/fzf"
    ".config/sway"
    ".config/waybar"
    ".config/dunst"
)

note()  { printf '%s\n' "$*"; }
do_or_say() {
    if [ "${APPLY}" -eq 1 ]; then
        "$@"
    else
        printf '   [dry-run] would: %s\n' "$*"
    fi
}

note "==> cleanup.sh — dotfiles v1 → v2 safety net"
note "    repo:    ${REPO_ROOT}"
note "    home:    ${HOME}"
note "    backup:  ${BACKUP_DIR}"
if [ "${APPLY}" -eq 0 ]; then
    note "    mode:    DRY-RUN (pass --apply to actually move files)"
else
    note "    mode:    APPLY"
fi
note ""

# ---------------------------------------------------------------------------
# Snapshot Home Manager state
# ---------------------------------------------------------------------------
note "==> home-manager generations"
if command -v home-manager >/dev/null 2>&1; then
    home-manager generations 2>/dev/null | sed 's/^/    /' || note "    (no generations listed)"
else
    note "    home-manager not on PATH — skipping generation listing"
fi
note ""

note "==> symlinks under \$HOME currently pointing into /nix/store"
find "${HOME}" -maxdepth 4 -type l 2>/dev/null \
    | while read -r link; do
        target="$(readlink "${link}" 2>/dev/null || true)"
        case "${target}" in
            /nix/store/*) printf '    %s -> %s\n' "${link}" "${target}" ;;
        esac
    done
note ""

# ---------------------------------------------------------------------------
# Optional rollback
# ---------------------------------------------------------------------------
if [ "${ROLLBACK}" -eq 1 ]; then
    note "==> rolling Home Manager back one generation"
    if command -v home-manager >/dev/null 2>&1; then
        do_or_say home-manager switch --rollback || note "    (rollback failed — continuing)"
    else
        note "    home-manager not on PATH — skipping rollback"
    fi
    note ""
fi

# ---------------------------------------------------------------------------
# Move scoped paths to the backup directory
# ---------------------------------------------------------------------------
note "==> moving scoped paths into backup directory"
do_or_say mkdir -p "${BACKUP_DIR}"

MANIFEST="${BACKUP_DIR}/MANIFEST.txt"
moved_count=0
skipped_count=0

if [ "${APPLY}" -eq 1 ]; then
    {
        printf 'dotfiles cleanup manifest\n'
        printf 'timestamp: %s\n' "${TS}"
        printf 'repo:      %s\n' "${REPO_ROOT}"
        printf 'home:      %s\n\n' "${HOME}"
    } > "${MANIFEST}"
fi

for rel in "${SCOPED_PATHS[@]}"; do
    src="${HOME}/${rel}"
    if [ ! -e "${src}" ] && [ ! -L "${src}" ]; then
        note "    skip (absent):   ~/${rel}"
        skipped_count=$(( skipped_count + 1 ))
        continue
    fi

    # If it's already a symlink into this repo, leave it — the next
    # home-manager switch will replace it cleanly anyway.
    if [ -L "${src}" ]; then
        target="$(readlink "${src}" 2>/dev/null || true)"
        case "${target}" in
            "${REPO_ROOT}"/*|/nix/store/*)
                note "    skip (managed):  ~/${rel} -> ${target}"
                skipped_count=$(( skipped_count + 1 ))
                continue
                ;;
        esac
    fi

    dst="${BACKUP_DIR}/${rel}"
    dst_dir="$(dirname "${dst}")"
    note "    move:            ~/${rel}  ->  ${dst}"
    do_or_say mkdir -p "${dst_dir}"
    do_or_say mv "${src}" "${dst}"
    if [ "${APPLY}" -eq 1 ]; then
        printf '%s\t%s\n' "${rel}" "${dst}" >> "${MANIFEST}"
    fi
    moved_count=$(( moved_count + 1 ))
done

note ""
note "==> summary"
note "    moved:    ${moved_count}"
note "    skipped:  ${skipped_count}"
if [ "${APPLY}" -eq 1 ]; then
    note "    manifest: ${MANIFEST}"
    note ""
    note "    Recover any file with:  mv \"${BACKUP_DIR}/<path>\" \"${HOME}/<path>\""
else
    note ""
    note "    (dry-run — re-run with --apply to perform the moves)"
fi
