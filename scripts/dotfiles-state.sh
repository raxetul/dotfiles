#!/usr/bin/env bash
# scripts/dotfiles-state.sh — realized-state ledger for the dotfiles repo.
#
# Records WHAT this repo actually planted on THIS host: symlinks created,
# packages installed (vs. ones already present), plugins/bootstraps fetched,
# custom-install hooks run, and the login-shell change — so a future
# scripts/uninstall.sh can reverse them precisely and `--purge` removes ONLY
# the packages we installed, never ones you already had.
#
# This is deliberately NOT a version lockfile: it records presence, ownership
# and paths, never versions. The package lists in packages/ and the
# COMMON_LINKS array in scripts/symlinks.sh stay the source of truth for what
# SHOULD exist; this ledger records what DID get planted, per host.
#
# Storage: an append-only TSV at
#   ${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.tsv
# one record per line, six TAB-separated fields:
#   <iso8601-utc>  <run-id>  <domain>  <action>  <id>  <detail>
# It is reduced on read (last action per <domain,id> wins) into the current
# realized set; removal actions drop the entry. Re-runs are therefore safe —
# duplicates collapse — and `prune` compacts the file to that reduced set.
#
# Domains / actions in use:
#   symlink      create | remove        id = ~-relative dst, detail = src=<repo path>
#   package      install | present      id = pkg name,       detail = mgr=<apt|pacman|dnf|brew|script>
#   plugin       clone                  id = checkout path,  detail = name=<id>
#   bootstrap    fetch                  id = file path,      detail = name=<id>
#   custom-hook  run                    id = <pkg>/<hook>,   detail = rc=<code>
#   shell        chsh                   id = new shell,      detail = from=<old shell>
#
# Dual use:
#   * source it — exposes the state_* / pkg_installed functions to setup.sh,
#     symlinks.sh, run-custom-install-hook, and (later) uninstall.sh.
#   * run it    — CLI: record | list | reduce | owned-packages | prune | path.
#
# Env:
#   DOTFILES_STATE_RUN   shared run id; a parent (setup.sh) exports it so child
#                        scripts group their records under one run. Auto-set if
#                        unset.
#   DOTFILES_STATE_FILE  override the ledger path (handy for tests).
#   DRY_RUN              "1" → print the intended record to stderr, write nothing.

# === Ledger path ===
state_file() {
    if [ -n "${DOTFILES_STATE_FILE:-}" ]; then
        printf '%s\n' "${DOTFILES_STATE_FILE}"
    else
        printf '%s\n' "${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles/state.tsv"
    fi
}

# === Run id (shared across a single setup.sh invocation) ===
# Sets + exports DOTFILES_STATE_RUN once, then echoes it. Child processes
# inherit it from the environment so all their records share one run id.
state_begin_run() {
    if [ -z "${DOTFILES_STATE_RUN:-}" ]; then
        DOTFILES_STATE_RUN="r-$(date -u +%Y%m%d-%H%M%S)-$$"
        export DOTFILES_STATE_RUN
    fi
    printf '%s\n' "${DOTFILES_STATE_RUN}"
}

# === Append one record ===
# usage: state_record <domain> <action> <id> [detail]
state_record() {
    local domain="$1" action="$2" id="$3" detail="${4:-}"
    local run ts file dir

    if [ "${DRY_RUN:-0}" = "1" ]; then
        printf '[dry-run] state: %s %s %s %s\n' "${domain}" "${action}" "${id}" "${detail}" >&2
        return 0
    fi

    run="$(state_begin_run)"
    ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    file="$(state_file)"
    dir="$(dirname "${file}")"
    mkdir -p "${dir}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "${ts}" "${run}" "${domain}" "${action}" "${id}" "${detail}" >> "${file}"
}

# === Raw ledger dump (optionally filtered by domain) ===
state_list() {
    local want="${1:-}" file
    file="$(state_file)"
    [ -f "${file}" ] || return 0
    if [ -n "${want}" ]; then
        awk -F'\t' -v w="${want}" '$3 == w' "${file}"
    else
        cat "${file}"
    fi
}

# === Reduce to the current realized set ===
# Last action per (domain,id) wins; entries whose final action negates
# presence (remove/unlink/purge/uninstall/…) are dropped. Optional $1 filters
# by domain. Output keeps the original six TAB-separated fields, ordered by
# the record's position so the timeline reads naturally.
state_reduce() {
    local want="${1:-}" file
    file="$(state_file)"
    [ -f "${file}" ] || return 0
    awk -F'\t' '
        { key = $3 SUBSEP $5; last[key] = $0; seq[key] = NR }
        END { for (k in last) print seq[k] "\t" last[k] }
    ' "${file}" \
        | sort -n \
        | cut -f2- \
        | awk -F'\t' -v want="${want}" '
            $4 ~ /^(remove|unlink|purge|uninstall|delete|revert)$/ { next }
            want == "" || $3 == want { print }
        '
}

# === Packages we installed (not ones already present) ===
# The list that `uninstall.sh --purge` may safely remove.
state_owned_packages() {
    state_reduce package | awk -F'\t' '$4 == "install" { print $5 }'
}

# === Compact the ledger to its reduced current set ===
state_prune() {
    local file tmp
    file="$(state_file)"
    [ -f "${file}" ] || return 0
    tmp="$(mktemp)"
    state_reduce > "${tmp}"
    mv "${tmp}" "${file}"
}

# === Is <pkg> currently installed under <mgr>? ===
# Shared package-manager query used by setup.sh (classify before install) and
# uninstall.sh (confirm before purge). Returns 0 if installed.
pkg_installed() {
    local mgr="$1" pkg="$2"
    case "${mgr}" in
        apt)    dpkg -s "${pkg}" >/dev/null 2>&1 ;;
        pacman) pacman -Q "${pkg}" >/dev/null 2>&1 ;;
        dnf)    rpm -q "${pkg}" >/dev/null 2>&1 ;;
        brew)   brew list --formula "${pkg}" >/dev/null 2>&1 \
                    || brew list --cask "${pkg}" >/dev/null 2>&1 ;;
        *)      return 1 ;;
    esac
}

# === CLI dispatch (only when executed directly, not when sourced) ===
if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
    set -euo pipefail
    cmd="${1:-list}"
    shift || true
    case "${cmd}" in
        record)          state_record "$@" ;;
        list)            state_list "$@" ;;
        reduce)          state_reduce "$@" ;;
        owned-packages)  state_owned_packages ;;
        prune)           state_prune ;;
        path|file)       state_file ;;
        begin-run)       state_begin_run ;;
        -h|--help)       sed -n '2,46p' "$0" ;;
        *)
            printf 'usage: %s {record|list|reduce|owned-packages|prune|path|begin-run}\n' "$0" >&2
            exit 1
            ;;
    esac
fi
