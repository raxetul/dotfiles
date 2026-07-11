#!/usr/bin/env bash
# scripts/clean-package-cache.sh — reclaim disk by cleaning package-manager
# caches, removing orphaned packages, and pruning language-tool caches.
#
# On-demand ONLY — never wired into the default update run. Invoke directly
# or via `update-dotfiles --only=cache-clean`.
#
# Three tiers run in one pass; each command is guarded by tool presence:
#   1. caches   — downloaded package archives / manager caches. Safe and
#                 reversible (re-downloaded on next install); removes no
#                 installed package. Runs without a prompt.
#   2. orphans  — dependency packages nothing needs anymore. UNINSTALLS
#                 them; prompts once unless --yes.
#   3. lang     — language-toolchain caches (npm, yarn, pnpm, node-gyp,
#                 pip, cargo, go, maven, gradle, composer, gem, cocoapods).
#                 Forces re-download; prompts once unless --yes.
#
# Native managers, distro-detected: brew (macOS); apt / pacman / dnf
# (Linux) + AUR helper (yay/paru) + snap where present.
#
# Usage:
#   scripts/clean-package-cache.sh                 # all three tiers
#   scripts/clean-package-cache.sh --dry-run       # print commands, run none
#   scripts/clean-package-cache.sh --yes           # skip confirmations
#   scripts/clean-package-cache.sh --only=caches   # one tier: caches|orphans|lang
#
# Env (also settable as flags): DRY_RUN=1, YES=1. Output streams live to the
# terminal AND to ${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/clean-package-cache.log.
#
# Exit codes: 0 success · 1 bad CLI arg
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
YES="${YES:-0}"
ONLY_TIER=""

for arg in "$@"; do
    case "${arg}" in
        --dry-run)        DRY_RUN=1 ;;
        --yes|-y)         YES=1 ;;
        --only=caches)    ONLY_TIER="caches" ;;
        --only=orphans)   ONLY_TIER="orphans" ;;
        --only=lang)      ONLY_TIER="lang" ;;
        --only=*)         echo "Unknown --only value: ${arg#--only=}" >&2; exit 1 ;;
        -h|--help)        sed -n '2,29p' "$0"; exit 0 ;;
        *)                echo "Unknown argument: ${arg}" >&2; exit 1 ;;
    esac
done

LOG_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/dotfiles"
LOG_FILE="${LOG_DIR}/clean-package-cache.log"
mkdir -p "${LOG_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1
printf '\n==== %s clean-package-cache  only=%s dry-run=%s yes=%s ====\n' \
    "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "${ONLY_TIER:-all}" "${DRY_RUN}" "${YES}"
_end() {
    local rc=$?
    printf '==== %s clean-package-cache end rc=%d ====\n\n' \
        "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "${rc}"
}
trap _end EXIT

note() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# run <cmd...> — execute, or print a "[dry-run]" preview.
run() {
    if [ "${DRY_RUN}" -eq 1 ]; then
        printf '   [dry-run] would: %s\n' "$*"
    else
        "$@"
    fi
}

# runsh '<snippet>' — like run but for a snippet needing shell syntax
# (pipes/globs/redirects). One logical step to the dry-run printer.
runsh() {
    if [ "${DRY_RUN}" -eq 1 ]; then
        printf '   [dry-run] would (sh): %s\n' "$*"
    else
        sh -c "$*"
    fi
}

# confirm "<prompt>" — return 0 to proceed. --yes and --dry-run always
# proceed (dry-run so the previews still print); otherwise ask on the tty.
confirm() {
    [ "${YES}" -eq 1 ] && return 0
    [ "${DRY_RUN}" -eq 1 ] && return 0
    printf '   %s [y/N] ' "$1"
    local ans
    read -r ans || ans=""
    case "${ans}" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

# ----------------------------------------------------------------------
# Tier 1 — caches (safe: reclaims disk, re-downloaded on next install)
# ----------------------------------------------------------------------
tier_caches() {
    note "tier: caches (downloaded package archives / manager caches)"
    if [ "$(uname)" = "Darwin" ]; then
        if have brew; then
            note "brew: scrub download cache"
            run brew cleanup -s
        fi
    elif [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            debian|ubuntu|pop|linuxmint)
                have apt-get && { note "apt: clean archive cache"; run sudo apt-get clean; }
                ;;
            arch|manjaro|endeavouros|artix)
                if have paccache; then
                    note "pacman: keep last 1 cached version, drop uninstalled"
                    run sudo paccache -rk1
                    run sudo paccache -ruk0
                elif have pacman; then
                    note "pacman: clean cache (install pacman-contrib for paccache)"
                    run sudo pacman -Sc --noconfirm
                fi
                ;;
            fedora|rhel|centos|almalinux|rocky)
                have dnf && { note "dnf: clean packages cache"; run sudo dnf clean packages; }
                ;;
        esac
        # AUR helper build + package cache (Arch family).
        if have yay; then
            note "yay: clean AUR + pacman cache"; run yay -Sc --noconfirm
        elif have paru; then
            note "paru: clean AUR + pacman cache"; run paru -Sc --noconfirm
        fi
        # Snap: drop disabled (superseded) revisions.
        if have snap; then
            note "snap: remove disabled old revisions"
            # Single quotes are intentional: the inner `sh -c`/awk must do the
            # field + $n/$r expansion at run time, not this outer bash.
            # shellcheck disable=SC2016
            runsh 'snap list --all 2>/dev/null | awk "/disabled/{print \$1, \$3}" \
                   | while read -r n r; do sudo snap remove "$n" --revision="$r"; done'
        fi
    fi
}

# ----------------------------------------------------------------------
# Tier 2 — orphans (UNINSTALLS dependency packages nothing needs)
# ----------------------------------------------------------------------
tier_orphans() {
    note "tier: orphans (uninstalls unused dependency packages)"
    if ! confirm "Remove orphaned / unused dependency packages?"; then
        note "   skipped orphan removal on user request"
        return 0
    fi
    if [ "$(uname)" = "Darwin" ]; then
        have brew && { note "brew: autoremove unused deps"; run brew autoremove; }
    elif [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            debian|ubuntu|pop|linuxmint)
                have apt-get && { note "apt: autoremove --purge"; run sudo apt-get autoremove --purge -y; }
                ;;
            arch|manjaro|endeavouros|artix)
                if have pacman; then
                    local orphans
                    orphans="$(pacman -Qdtq 2>/dev/null || true)"
                    if [ -n "${orphans}" ]; then
                        note "pacman: remove orphans"
                        # shellcheck disable=SC2086
                        run sudo pacman -Rns --noconfirm ${orphans}
                    else
                        note "pacman: no orphans"
                    fi
                fi
                ;;
            fedora|rhel|centos|almalinux|rocky)
                have dnf && { note "dnf: autoremove"; run sudo dnf autoremove -y; }
                ;;
        esac
    fi
}

# ----------------------------------------------------------------------
# Tier 3 — lang (language-toolchain caches; forces re-download)
# ----------------------------------------------------------------------
tier_lang() {
    note "tier: language-tool caches"
    if ! confirm "Prune language-tool caches (npm, yarn, pnpm, node-gyp, pip, cargo, go, maven, gradle, composer, gem, cocoapods)?"; then
        note "   skipped language-tool cleanup on user request"
        return 0
    fi
    have npm  && { note "npm cache clean";  run npm cache clean --force; }
    have yarn && { note "yarn cache clean"; run yarn cache clean; }
    have pnpm && { note "pnpm store prune"; run pnpm store prune; }
    if have node-gyp; then
        note "node-gyp: clear header / dev caches"
        for d in "${HOME}/.node-gyp" "${HOME}/.cache/node-gyp" \
                 "${HOME}/Library/Caches/node-gyp"; do
            [ -d "${d}" ] && run rm -rf "${d}"
        done
    fi
    if have pip; then
        note "pip cache purge"; run pip cache purge || true
    elif have pip3; then
        note "pip3 cache purge"; run pip3 cache purge || true
    fi
    if have cargo-cache; then
        note "cargo-cache: autoclean registry"; run cargo-cache --autoclean
    elif have cargo; then
        note "cargo: prune registry cache + git checkouts"
        for d in "${HOME}/.cargo/registry/cache" "${HOME}/.cargo/registry/src" \
                 "${HOME}/.cargo/git/checkouts"; do
            [ -d "${d}" ] && run rm -rf "${d}"
        done
    fi
    have go && { note "go clean -cache -modcache -fuzzcache"; run go clean -cache -modcache -fuzzcache; }
    if have mvn && [ -d "${HOME}/.m2/repository" ]; then
        note "maven: clear ~/.m2/repository"; run rm -rf "${HOME}/.m2/repository"
    fi
    if have gradle && [ -d "${HOME}/.gradle/caches" ]; then
        note "gradle: stop daemons + clear ~/.gradle/caches"
        run gradle --stop || true
        run rm -rf "${HOME}/.gradle/caches"
    fi
    have composer && { note "composer clear-cache"; run composer clear-cache; }
    have gem      && { note "gem cleanup (old versions)"; run gem cleanup; }
    have pod      && { note "cocoapods: pod cache clean --all"; run pod cache clean --all; }
}

note "clean-package-cache (dry-run=${DRY_RUN}, yes=${YES}, only=${ONLY_TIER:-all})"
echo

case "${ONLY_TIER}" in
    caches)  tier_caches ;;
    orphans) tier_orphans ;;
    lang)    tier_lang ;;
    "")      tier_caches; echo; tier_orphans; echo; tier_lang ;;
esac

echo
note "done."
