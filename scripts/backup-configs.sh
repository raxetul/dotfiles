#!/usr/bin/env bash
# scripts/backup-configs.sh — scoped pre-symlink backup.
#
# Walks every directory under configurations/ in this repo and, for each
# one, backs up the corresponding live config in $HOME *if* it's a real
# file or a foreign symlink (i.e. not already pointing into this repo).
#
# Scope is intentionally narrow: only paths this repo manages are
# touched. Anything else under ~/.config/ (Slack, Code, Firefox, …) is
# ignored — by design.
#
# Defaults to dry-run. Pass --apply to actually move files. A MANIFEST.txt
# is written into the backup directory listing every move.
#
# Usage:
#   scripts/backup-configs.sh           # dry-run
#   scripts/backup-configs.sh --apply
#
# Exit codes:
#   0  success (including the "nothing to move" case)
#   1  bad CLI arg, repo layout missing, or move failed
set -euo pipefail

APPLY=0
for arg in "$@"; do
    case "${arg}" in
        --apply) APPLY=1 ;;
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

# Scripts run from ~/.scripts (PATH-installed), so $0/.. is $HOME, not
# the repo. Trust $DOTFILES_DIR (exported by configurations/{zsh,bash}/rc);
# fall back to the documented default for non-interactive contexts.
REPO_ROOT="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
[ -d "${REPO_ROOT}" ] || { printf 'ERR: repo not found at %s — set DOTFILES_DIR.\n' "${REPO_ROOT}" >&2; exit 1; }
CONFIG_ROOT="${REPO_ROOT}/configurations"
TS="$(date +%Y-%m-%dT%H-%M-%S)"
BACKUP_DIR="${HOME}/.dotfiles-backup-${TS}"

if [ ! -d "${CONFIG_ROOT}" ]; then
    echo "ERROR: ${CONFIG_ROOT} not found — run this from the dotfiles repo." >&2
    exit 1
fi

# Map a configurations/<app> directory to the live paths in $HOME that
# would clash with it. Most apps follow ~/.config/<app>/, but a few
# legacy paths (Vim, Git, tmux) live directly under $HOME.
live_paths_for() {
    case "$1" in
        vim)      printf '%s\n' ".vimrc" ".vim" ;;
        nvim)     printf '%s\n' ".config/nvim" ;;
        tmux)     printf '%s\n' ".tmux.conf" ".config/tmux" ;;
        git)      printf '%s\n' ".gitconfig" ".config/git" ;;
        starship) printf '%s\n' ".config/starship.toml" ;;
        ghostty)  printf '%s\n' ".config/ghostty" ;;
        atuin)    printf '%s\n' ".config/atuin" ;;
        bat)      printf '%s\n' ".config/bat" ;;
        fzf)      printf '%s\n' ".config/fzf" ;;
        aliases)  ;;  # sourced from rc files, no live path of its own
        themes)   ;;  # palette files; consumed by individual app configs
        zsh)      printf '%s\n' ".zshrc" ".zshenv" ;;
        bash)     printf '%s\n' ".bashrc" ".bash_profile" ;;
        waybar)   printf '%s\n' ".config/waybar" ;;
        sway)     printf '%s\n' ".config/sway" ;;
        dunst)    printf '%s\n' ".config/dunst" ;;
        brew)     ;;  # Brewfile, not symlinked into $HOME
        lefthook) ;;  # invoked from inside the repo, not symlinked
        *)        printf '%s\n' ".config/$1" ;;  # sensible default
    esac
}

note() { printf '%s\n' "$*"; }
do_or_say() {
    if [ "${APPLY}" -eq 1 ]; then
        "$@"
    else
        printf '   [dry-run] would: %s\n' "$*"
    fi
}

is_managed_link() {
    # Returns 0 if $1 is a symlink pointing into this repo, meaning
    # scripts/symlinks.sh already owns it and we should leave it alone.
    local link="$1"
    [ -L "${link}" ] || return 1
    local target
    target="$(readlink "${link}" 2>/dev/null || true)"
    case "${target}" in
        "${REPO_ROOT}"/*) return 0 ;;
        *) return 1 ;;
    esac
}

note "==> backup-configs.sh"
note "    repo:    ${REPO_ROOT}"
note "    configs: ${CONFIG_ROOT}"
note "    home:    ${HOME}"
note "    backup:  ${BACKUP_DIR}"
if [ "${APPLY}" -eq 0 ]; then
    note "    mode:    DRY-RUN (pass --apply to actually move files)"
else
    note "    mode:    APPLY"
fi
note ""

MANIFEST="${BACKUP_DIR}/MANIFEST.txt"
moved_count=0
skipped_count=0
managed_count=0

if [ "${APPLY}" -eq 1 ]; then
    mkdir -p "${BACKUP_DIR}"
    {
        printf 'dotfiles backup-configs manifest\n'
        printf 'timestamp: %s\n' "${TS}"
        printf 'repo:      %s\n' "${REPO_ROOT}"
        printf 'home:      %s\n\n' "${HOME}"
    } > "${MANIFEST}"
fi

# Iterate over every immediate child of configurations/ that's a directory.
for app_path in "${CONFIG_ROOT}"/*/; do
    app="$(basename "${app_path}")"
    note "-- ${app}"

    # Collect live paths, skip apps with none defined.
    mapfile -t paths < <(live_paths_for "${app}")
    if [ "${#paths[@]}" -eq 0 ]; then
        note "   (no live paths in \$HOME for this group — skipping)"
        continue
    fi

    for rel in "${paths[@]}"; do
        src="${HOME}/${rel}"
        if [ ! -e "${src}" ] && [ ! -L "${src}" ]; then
            note "   absent:  ~/${rel}"
            skipped_count=$(( skipped_count + 1 ))
            continue
        fi

        if is_managed_link "${src}"; then
            note "   managed: ~/${rel} -> $(readlink "${src}")"
            managed_count=$(( managed_count + 1 ))
            continue
        fi

        dst="${BACKUP_DIR}/${rel}"
        note "   move:    ~/${rel}  ->  ${dst}"
        do_or_say mkdir -p "$(dirname "${dst}")"
        do_or_say mv "${src}" "${dst}"
        if [ "${APPLY}" -eq 1 ]; then
            printf '%s\t%s\n' "${rel}" "${dst}" >> "${MANIFEST}"
        fi
        moved_count=$(( moved_count + 1 ))
    done
done

note ""
note "==> summary"
note "    moved:       ${moved_count}"
note "    already ok:  ${managed_count}"
note "    skipped:     ${skipped_count}"
if [ "${APPLY}" -eq 1 ] && [ "${moved_count}" -gt 0 ]; then
    note "    manifest:    ${MANIFEST}"
fi
if [ "${APPLY}" -eq 0 ]; then
    note ""
    note "    (dry-run — re-run with --apply to perform the moves)"
fi
