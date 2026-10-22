#!/usr/bin/env bash
# scripts/migrate-to-opt.sh — move an existing per-user dotfiles checkout
# to the shared /opt/dotfiles layout. Idempotent; safe to re-run.
#
# What it does, in order:
#   1. Detect the current repo (default ~/gel-ort/dotfiles, or
#      $DOTFILES_DIR) and refuse if it has uncommitted changes.
#   2. Move $HOME/.load and $HOME/.path — the legacy in-repo per-host
#      files — out to $HOME/.dotfiles/{load,path} FIRST, before the
#      repo itself moves, so they land in per-user state either way.
#   3. Relocate the repo to /opt/dotfiles: a same-device `mv` when
#      that's safe (needs root to create /opt/dotfiles the first
#      time), or a fresh `git clone` from the old checkout — keeping
#      the old directory in place — when a move isn't safe (an empty
#      /opt/dotfiles already exists, cross-device, or not root).
#      States which one it did. After a clone it points `origin` at
#      the old checkout's origin URL and warns about local-only
#      branches and ignored files left behind. Then it checks that
#      /opt/dotfiles has group `dotfiles`; if not, it exits non-zero
#      with the provision-shared-group.sh command to run.
#   4. Re-run scripts/symlinks.sh install so every symlink repoints at
#      the new location. Verifies zero dangling links afterward and
#      reports the count.
#   5. NEVER deletes the old directory — that's for the user to do,
#      once they've confirmed the new location works.
#
# Usage:
#   scripts/migrate-to-opt.sh [--yes] [--dry-run]
#   DRY_RUN=1 scripts/migrate-to-opt.sh
#
# --yes / YES=1 skips the confirmation prompt before each destructive
# step (the repo relocation, and the .load/.path move). Read-only
# checks (dirty-check, dangling-link verify) never prompt.
set -euo pipefail

# shellcheck source=scripts/dotfiles-dir.sh
. "$(dirname "${BASH_SOURCE[0]:-$0}")/dotfiles-dir.sh"

DRY_RUN="${DRY_RUN:-0}"
YES="${YES:-0}"
for arg in "$@"; do
    case "${arg}" in
        --dry-run) DRY_RUN=1 ;;
        --yes)     YES=1 ;;
        -h|--help) sed -n '2,31p' "$0"; exit 0 ;;
        *) printf 'ERR: unknown argument: %s\n' "${arg}" >&2; exit 1 ;;
    esac
done

say() { printf '==> %s\n' "$*"; }
confirm() {
    # $1 = prompt. Returns 0 (proceed) if --yes/YES=1 or DRY_RUN, else
    # asks. DRY_RUN never needs a real answer since nothing runs.
    [ "${DRY_RUN}" = "1" ] && return 0
    [ "${YES}" = "1" ] && return 0
    printf '%s [y/N] ' "$1"
    read -r reply
    case "${reply}" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}
run() {
    if [ "${DRY_RUN}" = "1" ]; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

SHARED_ROOT="/opt/dotfiles"
SRC="${DOTFILES_DIR}"

say "source repo: ${SRC}"
if [ "${SRC}" = "${SHARED_ROOT}" ]; then
    printf 'ERR: DOTFILES_DIR already resolves to %s — nothing to migrate.\n' "${SHARED_ROOT}" >&2
    exit 1
fi
[ -d "${SRC}/.git" ] || { printf 'ERR: %s is not a git repo — nothing to migrate.\n' "${SRC}" >&2; exit 1; }

# === Step 1 — refuse if dirty =======================================
say "checking for uncommitted changes"
DIRTY="$(git -C "${SRC}" status --porcelain)"
if [ -n "${DIRTY}" ]; then
    printf 'ERR: %s has uncommitted changes — commit or stash first:\n' "${SRC}" >&2
    printf '%s\n' "${DIRTY}" >&2
    exit 1
fi
printf '  clean\n'

# === Step 2 — move .load/.path to $HOME/.dotfiles/ FIRST ===========
# Done before the repo relocation so a same-device `mv` of the repo
# directory (step 3) can't drag these gitignored, per-host files along
# with it into the shared tree.
say "per-user state: \$HOME/.load, \$HOME/.path -> \$HOME/.dotfiles/"
PER_USER_DIR="${HOME}/.dotfiles"
migrate_one() {
    # $1 = legacy src (repo-relative file), $2 = new dst under PER_USER_DIR
    local src="$1" dst="$2"
    if [ ! -e "${src}" ]; then
        printf '  skip (absent): %s\n' "${src}"
        return 0
    fi
    if [ -e "${dst}" ]; then
        printf '  skip (already exists, not overwriting): %s\n' "${dst}"
        return 0
    fi
    if ! confirm "  move ${src} -> ${dst}?"; then
        printf '  skipped by user: %s\n' "${src}"
        return 0
    fi
    run mkdir -p "${PER_USER_DIR}"
    run mv "${src}" "${dst}"
    printf '  moved: %s -> %s\n' "${src}" "${dst}"
}
migrate_one "${SRC}/.load" "${PER_USER_DIR}/load"
migrate_one "${SRC}/.path" "${PER_USER_DIR}/path"

# === Step 3 — relocate the repo to /opt/dotfiles ====================
# /opt/dotfiles must ALWAYS end up with group `dotfiles` (setgid). The
# printed hint creates the dir that way, and the check after this step
# enforces it. Owner may be root or the admin user.
# shellcheck disable=SC2016  # literal command for the user to run, not for expansion here
HINT_GROUP='sudo groupadd -f dotfiles && sudo install -d -o "$(id -un)" -g dotfiles -m 2775 /opt/dotfiles'

post_clone_notes() {
    # After a clone from the local checkout: undo what a local clone gets
    # wrong and list what a clone cannot carry over. DRY_RUN prints only.
    local origin_url local_only ignored_left f
    if origin_url="$(git -C "${SRC}" remote get-url origin 2>/dev/null)"; then
        run git -C "${SHARED_ROOT}" remote set-url origin "${origin_url}"
        printf '  origin of the new repo: %s (was the local path)\n' "${origin_url}"
    else
        printf '  WARN: %s has no origin remote — the new repo keeps the local path as origin.\n' "${SRC}"
    fi
    local_only="$(comm -23 \
        <(git -C "${SRC}" for-each-ref --format='%(refname:short)' refs/heads | sort) \
        <(git -C "${SRC}" for-each-ref --format='%(refname:short)' refs/remotes/origin | sed 's|^origin/||' | sort))"
    if [ -n "${local_only}" ]; then
        printf '  WARN: local branches that are NOT on origin (they stay only in %s):\n' "${SRC}"
        while IFS= read -r f; do printf '    %s\n' "${f}"; done <<< "${local_only}"
    fi
    ignored_left=""
    for f in .leak-guard-patterns .claude/settings.local.json; do
        [ -e "${SRC}/${f}" ] && ignored_left="${ignored_left} ${f}"
    done
    if [ -n "${ignored_left}" ]; then
        printf '  WARN: ignored files NOT copied to the new checkout:%s\n' "${ignored_left}"
    fi
    # shellcheck disable=SC2016  # literal commands for the user to run
    printf '  TODO in the new checkout: run `lefthook install` (git hooks are not cloned),\n'
    # shellcheck disable=SC2016  # literal commands for the user to run
    printf '        and `git fetch origin` (remote branches are stale until then).\n'
}

clone_into_shared() {
    # git clone into an existing EMPTY dir is fine. `mv` onto an existing
    # dir is not, and rmdir + mv would drop the group + setgid the hint set.
    if confirm "  git clone ${SRC} -> ${SHARED_ROOT}?"; then
        run git clone --quiet "${SRC}" "${SHARED_ROOT}"
        printf '  cloned fresh: %s -> %s (old checkout left in place)\n' "${SRC}" "${SHARED_ROOT}"
        post_clone_notes
    else
        printf '  skipped by user — nothing cloned.\n'
    fi
}

say "repo relocation: ${SRC} -> ${SHARED_ROOT}"
if [ -d "${SHARED_ROOT}/.git" ]; then
    printf '  %s already exists — leaving %s in place, untouched.\n' "${SHARED_ROOT}" "${SRC}"
    printf '  (nothing to relocate: this host already has the shared repo;\n'
    printf '   %s is now a redundant checkout you may remove by hand.)\n' "${SRC}"
elif [ -d "${SHARED_ROOT}" ] && [ -n "$(ls -A "${SHARED_ROOT}" 2>/dev/null)" ]; then
    printf 'ERR: %s exists, is not empty, and is not a git repo — not touching it.\n' "${SHARED_ROOT}" >&2
    exit 1
elif [ -d "${SHARED_ROOT}" ]; then
    # Empty dir (made by the hint). Needs write access: root, or the owner/group.
    if [ "$(id -u)" != "0" ] && [ ! -w "${SHARED_ROOT}" ]; then
        printf '  %s exists but you cannot write to it. Run:\n' "${SHARED_ROOT}"
        # shellcheck disable=SC2016  # literal command for the user to run
        printf '    sudo chown "$(id -un)" %s && sudo chgrp dotfiles %s && sudo chmod 2775 %s\n' \
            "${SHARED_ROOT}" "${SHARED_ROOT}" "${SHARED_ROOT}"
        printf '  then re-run this script. Left %s in place — nothing moved.\n' "${SRC}"
    else
        printf '  %s exists, is empty and is writable — cloning into it.\n' "${SHARED_ROOT}"
        clone_into_shared
    fi
elif [ "$(id -u)" != "0" ] && [ ! -w "$(dirname "${SHARED_ROOT}")" ]; then
    printf '  cannot create %s without root — run:\n' "${SHARED_ROOT}"
    printf '    %s\n' "${HINT_GROUP}"
    printf '  then re-run this script (it will pick up the now-writable dir).\n'
    printf '  Left %s in place — nothing moved.\n' "${SRC}"
else
    SAME_DEVICE=0
    if [ -d "$(dirname "${SHARED_ROOT}")" ]; then
        src_dev="$(df -P "${SRC}" 2>/dev/null | awk 'NR==2{print $1}')"
        dst_dev="$(df -P "$(dirname "${SHARED_ROOT}")" 2>/dev/null | awk 'NR==2{print $1}')"
        [ -n "${src_dev}" ] && [ "${src_dev}" = "${dst_dev}" ] && SAME_DEVICE=1
    fi
    if [ "${SAME_DEVICE}" = "1" ]; then
        if confirm "  mv ${SRC} -> ${SHARED_ROOT}?"; then
            run mv "${SRC}" "${SHARED_ROOT}"
            printf '  moved (same filesystem): %s -> %s\n' "${SRC}" "${SHARED_ROOT}"
        else
            printf '  skipped by user — nothing moved.\n'
        fi
    else
        printf '  cross-device (mv unsafe) — cloning fresh from %s instead.\n' "${SRC}"
        clone_into_shared
    fi
fi

# === Step 3b — the group of /opt/dotfiles must be `dotfiles` ========
if [ -d "${SHARED_ROOT}/.git" ] && [ "$(uname)" = "Linux" ]; then
    say "checking group of ${SHARED_ROOT}"
    if [ "${DRY_RUN}" = "1" ]; then
        printf '  [dry-run] stat -c %%G %s  (must print: dotfiles)\n' "${SHARED_ROOT}"
    else
        group="$(stat -c %G "${SHARED_ROOT}")"
        if [ "${group}" != "dotfiles" ]; then
            printf 'ERR: %s has group "%s", not "dotfiles". Run:\n' "${SHARED_ROOT}" "${group}" >&2
            printf '  sudo %s/scripts/provision-shared-group.sh %s\n' "${SHARED_ROOT}" "$(id -un)" >&2
            exit 1
        fi
        printf '  group is dotfiles\n'
    fi
fi

# === Step 4 — repoint every symlink + verify ========================
NEW_ROOT="${SHARED_ROOT}"
[ -d "${NEW_ROOT}/.git" ] || NEW_ROOT="${SRC}"   # relocation skipped/refused above

say "repointing symlinks (DOTFILES_DIR=${NEW_ROOT})"
if [ "${DRY_RUN}" = "1" ]; then
    printf '  [dry-run] DOTFILES_DIR=%s %s/scripts/symlinks.sh install\n' "${NEW_ROOT}" "${NEW_ROOT}"
else
    DOTFILES_DIR="${NEW_ROOT}" "${NEW_ROOT}/scripts/symlinks.sh" install
fi

say "verifying zero dangling links"
dangling=0
total=0
while IFS= read -r entry; do
    [ -z "${entry}" ] && continue
    total=$((total + 1))
    dst="${entry##*::}"
    if [ -L "${HOME}/${dst}" ] && [ ! -e "${HOME}/${dst}" ]; then
        dangling=$((dangling + 1))
        printf '  DANGLING: ~/%s\n' "${dst}"
    fi
done < <(DOTFILES_DIR="${NEW_ROOT}" "${NEW_ROOT}/scripts/symlinks.sh" list)
printf '  %s/%s links resolve; %s dangling\n' "$((total - dangling))" "${total}" "${dangling}"

say "done. Old checkout left at ${SRC} — remove it yourself once you've verified the new location."
