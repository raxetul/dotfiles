#!/usr/bin/env bash
# scripts/claude-reset.sh — fully automatic ~/.claude cleanup, backup-first.
#
# Run --help for the full contract. In short: no arguments runs the entire
# pipeline (backup -> orphans -> credentials -> relink -> verify) with no
# prompts and no confirmation. --dry-run is the only way to preview without
# touching disk. The backup phase is mandatory and always runs first; if it
# fails, nothing else runs and nothing is deleted.
set -euo pipefail

: "${HOME:?claude-reset.sh: \$HOME is not set}"
if [ "${HOME}" = "/" ]; then
  printf 'claude-reset.sh: HOME resolves to /, refusing to run\n' >&2
  exit 2
fi

CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"

note() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { printf 'claude-reset.sh: %s\n' "$*" >&2; exit 1; }
die_running() { printf 'claude-reset.sh: %s\n' "$*" >&2; exit 3; }
have() { command -v "$1" >/dev/null 2>&1; }
require_cmd() { have "$1" || die "missing dependency: $1"; }

usage() {
  cat <<'EOF'
usage: claude-reset.sh [PHASE] [OPTIONS]

Fully automatic. With no PHASE, runs the entire pipeline in order and asks
no questions, ever (no confirmation prompts, no --apply flag, no
interactive `read`):

  backup -> orphans -> credentials -> [state, if --include-state] -> relink -> verify

--dry-run is the ONLY safety switch: it prints the plan and touches
nothing. Without it, the run is destructive by default — that is the
point of this script (the operator used to take the backup by hand; now
the script owns the entire safety net: mandatory backup, a hard
~/.claude/projects guard, and refusal while Claude Code is running).

PHASE (optional — runs just that one phase instead of the full pipeline):
  backup       Archive what this run would touch. Mandatory step of the
               default pipeline; can also be run standalone.
  orphans      Stray .DS_Store files, dated *.bak files left by earlier
               manual edits, the orphaned real ~/.claude/statusline.sh
               copy (the live one is a symlink into this repo), and any
               dangling symlink under ~/.claude. Safe while Claude Code
               is running. Never scans projects/.
  credentials  Requires Claude Code closed (see --force-running).
               Clears ~/.claude/backups/.claude.json.backup.* (each
               carries the oauthAccount block), ~/.claude/config.json
               (cached API-key fingerprint), daemon-auth-status.json +
               daemon-auth-cooldown, the macOS Keychain
               "Claude Code-credentials" entry, and — ONLY that field —
               the oauthAccount key inside ~/.claude.json. Everything
               else in ~/.claude.json (project entries,
               hasTrustDialogAccepted flags) is left untouched; wiping
               the whole file would re-trigger the "do you trust this
               folder" prompt everywhere, which needs a human at a
               keyboard to answer.
  state        Requires Claude Code closed. Reproducible caches only:
               plugins/, context-mode/, file-history/, cache/,
               paste-cache/, shell-snapshots/, telemetry/, jobs/,
               debug/, downloads/. Not part of the default pipeline —
               opt in with --include-state. Pass --include-history to
               ALSO target sessions/, tasks/, teams/, history.jsonl.
  relink       Re-run scripts/symlinks.sh install + scripts/claude-skills
               link to restore this repo's own symlinks under ~/.claude.
  verify       Read-only status table. Always safe.

OPTIONS:
  --dry-run            Print the plan, touch nothing. No archive is
                       written, no file is deleted or edited, the
                       Keychain is not touched.
  --include-state      Also run the state phase as part of the default
                       pipeline (between credentials and relink).
  --include-history    state phase only: also target sessions/, tasks/,
                       teams/, history.jsonl.
  --backup-transcripts Back up the ENTIRE projects/ tree, not just the
                       memory/ subdirectories. Much larger; off by
                       default.
  --backup-dir DIR     Directory the backup archive is written into.
                       Default: ${HOME}.
  --force-running      Let credentials/state run while Claude Code looks
                       running. Still prints a warning first.
  -h, --help           Show this text.

Backup: every run that isn't --dry-run writes
${BACKUP_DIR:-$HOME}/claude-reset-backup-<timestamp>.tgz plus a
<...>.manifest.txt next to it, containing every projects/**/memory/
directory (irreplaceable), ~/.claude.json (pre-edit), ~/.claude/history.jsonl,
and every file this run is about to delete. If the archive can't be
written, verified, or comes out empty, the script stops there with exit 1
— nothing is deleted. Restore with: tar xzf <archive> -C ${HOME}

~/.claude/projects is never deleted — only read and archived. The script
asserts its memory-file count hasn't shrunk both before and after every
run and aborts otherwise.

Credentials are not fully inside ~/.claude: the OAuth session itself
lives in the macOS Keychain ("Claude Code-credentials") and in the
oauthAccount field of ~/.claude.json — there is no ~/.claude/.credentials.json
on this setup. Prefer /logout from inside Claude Code first — it is the
documented way to end a session. Whether removing the Keychain item by
hand ALSO revokes the token server-side is UNVERIFIED; YOU SHOULD VERIFY
THIS before relying on manual Keychain deletion alone. This script warns
and suggests /logout, but does not block the automatic run on it.

Dependencies: jq (all phases but relink/verify's symlink checks), tar
(backup), git (relink, via scripts/claude-skills), and on macOS the
`security` CLI (credentials, for the Keychain entry). A missing
dependency fails only the phase that needs it.

Exit codes: 0 ok · 1 runtime/backup error · 2 usage error · 3 refused
because Claude Code is running (credentials/state without --force-running)
EOF
}

usage_error() {
  printf 'claude-reset.sh: %s\n\n' "$*" >&2
  usage >&2
  exit 2
}

# --- argument parsing -------------------------------------------------
PHASE=""
DRY_RUN=0
INCLUDE_STATE=0
INCLUDE_HISTORY=0
BACKUP_TRANSCRIPTS=0
FORCE_RUNNING=0
BACKUP_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    backup|orphans|credentials|state|relink|verify)
      [ -z "${PHASE}" ] || usage_error "multiple phases given: ${PHASE} and $1"
      PHASE="$1"
      ;;
    --dry-run) DRY_RUN=1 ;;
    --include-state) INCLUDE_STATE=1 ;;
    --include-history) INCLUDE_HISTORY=1 ;;
    --backup-transcripts) BACKUP_TRANSCRIPTS=1 ;;
    --backup-dir)
      shift
      [ $# -gt 0 ] || usage_error "--backup-dir requires a value"
      BACKUP_DIR="$1"
      ;;
    --backup-dir=*) BACKUP_DIR="${1#--backup-dir=}" ;;
    --force-running) FORCE_RUNNING=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage_error "unknown argument: $1" ;;
  esac
  shift
done

[ -n "${BACKUP_DIR}" ] || BACKUP_DIR="${HOME}"

require_cmd jq

RUN_TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# --- safety helpers (hard rule #3) -------------------------------------
is_safe_target() {
  local p="$1"
  case "${p}" in
    "") return 1 ;;
    "/"|".") return 1 ;;
  esac
  case "${p}" in
    "${CLAUDE_DIR}"|"${CLAUDE_DIR}"/*) return 0 ;;
    "${CLAUDE_JSON}") return 0 ;;
  esac
  return 1
}

# act_targets <path>...  — delete (or, under --dry-run, just print) each
# target; every path is re-validated by is_safe_target regardless of where
# it was computed, so a bad path can never reach rm.
act_targets() {
  local t
  for t in "$@"; do
    is_safe_target "${t}" || die "unsafe target rejected: ${t}"
    if [ -e "${t}" ] || [ -L "${t}" ]; then
      if [ "${DRY_RUN}" -eq 1 ]; then
        note "[dry-run] would remove: ${t}"
      else
        rm -rf -- "${t}"
        note "removed: ${t}"
      fi
    else
      note "absent, skipped: ${t}"
    fi
  done
}

# --- rule #2: refuse credentials/state while Claude Code is running ---
is_claude_running() {
  local lockfile="${CLAUDE_DIR}/daemon.lock" pid
  [ -f "${lockfile}" ] || return 1
  pid="$(jq -r '.pid // empty' "${lockfile}" 2>/dev/null)" || return 1
  case "${pid}" in ''|*[!0-9]*) return 1 ;; esac
  kill -0 "${pid}" 2>/dev/null
}

guard_not_running_or_force() {
  is_claude_running || return 0
  if [ "${FORCE_RUNNING}" -eq 1 ]; then
    warn "Claude Code looks running (pid in ${CLAUDE_DIR}/daemon.lock is alive) — continuing anyway due to --force-running"
    return 0
  fi
  die_running "Claude Code looks running (pid in ${CLAUDE_DIR}/daemon.lock is alive). It owns and instantly regenerates these files (observed backups/ go 5->6 while open); close it first or pass --force-running."
}

# --- rule #1: ~/.claude/projects must never shrink --------------------
count_memory_dirs()  { find "${CLAUDE_DIR}/projects" -type d -name memory 2>/dev/null | wc -l | tr -d ' '; }
count_memory_files() { find "${CLAUDE_DIR}/projects" -path '*/memory/*' -type f 2>/dev/null | wc -l | tr -d ' '; }

# ------------------------------------------------------------------
# target lists shared between backup and their own phases
# ------------------------------------------------------------------
ORPHAN_TARGETS=()
compute_orphan_targets() {
  ORPHAN_TARGETS=()
  local -a ds_stores=()
  mapfile -t ds_stores < <(find "${CLAUDE_DIR}" -maxdepth 3 \
    -path "${CLAUDE_DIR}/projects" -prune -o -name ".DS_Store" -type f -print 2>/dev/null)
  ORPHAN_TARGETS+=("${ds_stores[@]}")

  ORPHAN_TARGETS+=(
    "${CLAUDE_DIR}/CLAUDE.md.bak.20260629-155842"
    "${CLAUDE_DIR}/settings.json.bak"
    "${CLAUDE_DIR}/settings.json.bak.20260623-120218"
    "${CLAUDE_DIR}/hooks/context-mode-cache-heal.mjs.bak.20260629-155842"
  )

  # statusline.sh: only an orphan if it's a real file — the live one is a
  # symlink into this repo (configurations/claude/scripts/statusline.sh).
  if [ -e "${CLAUDE_DIR}/statusline.sh" ] && [ ! -L "${CLAUDE_DIR}/statusline.sh" ]; then
    ORPHAN_TARGETS+=("${CLAUDE_DIR}/statusline.sh")
  fi

  local -a dangling=()
  mapfile -t dangling < <(find "${CLAUDE_DIR}" -maxdepth 3 \
    -path "${CLAUDE_DIR}/projects" -prune -o -type l ! -exec test -e {} \; -print 2>/dev/null)
  ORPHAN_TARGETS+=("${dangling[@]}")
}

CREDENTIAL_TARGETS=()
compute_credential_targets() {
  CREDENTIAL_TARGETS=()
  local -a backups=()
  mapfile -t backups < <(find "${CLAUDE_DIR}/backups" -maxdepth 1 -name '.claude.json.backup.*' -type f 2>/dev/null)
  CREDENTIAL_TARGETS+=("${backups[@]}")
  CREDENTIAL_TARGETS+=(
    "${CLAUDE_DIR}/config.json"
    "${CLAUDE_DIR}/daemon-auth-status.json"
    "${CLAUDE_DIR}/daemon-auth-cooldown"
  )
}

# ------------------------------------------------------------------
# backup (mandatory, phase 1)
# ------------------------------------------------------------------
do_backup() {
  compute_orphan_targets
  compute_credential_targets

  local archive="${BACKUP_DIR}/claude-reset-backup-${RUN_TIMESTAMP}.tgz"
  local manifest="${archive%.tgz}.manifest.txt"

  local -a mem_dirs=()
  mapfile -t mem_dirs < <(find "${CLAUDE_DIR}/projects" -type d -name memory 2>/dev/null)
  local expected_mem_files
  expected_mem_files="$(count_memory_files)"

  local -a abs_paths=()
  if [ "${BACKUP_TRANSCRIPTS}" -eq 1 ] && [ -d "${CLAUDE_DIR}/projects" ]; then
    abs_paths+=("${CLAUDE_DIR}/projects")
  else
    abs_paths+=("${mem_dirs[@]}")
  fi

  if [ -f "${CLAUDE_JSON}" ]; then
    abs_paths+=("${CLAUDE_JSON}")
  fi
  if [ -f "${CLAUDE_DIR}/history.jsonl" ]; then
    abs_paths+=("${CLAUDE_DIR}/history.jsonl")
  fi

  local t
  for t in "${ORPHAN_TARGETS[@]}"; do
    if [ -e "${t}" ] || [ -L "${t}" ]; then
      abs_paths+=("${t}")
    fi
  done
  for t in "${CREDENTIAL_TARGETS[@]}"; do
    if [ -e "${t}" ]; then
      abs_paths+=("${t}")
    fi
  done

  if [ "${#abs_paths[@]}" -eq 0 ]; then
    note "backup: nothing found under ${CLAUDE_DIR} to archive, skipping"
    return 0
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    note "[dry-run] would write backup to: ${archive}"
    note "[dry-run] would write manifest to: ${manifest}"
    note "[dry-run] backup would include ${#abs_paths[@]} path(s) (memory dirs: ${#mem_dirs[@]}, memory files: ${expected_mem_files}):"
    for t in "${abs_paths[@]}"; do
      note "[dry-run]   ${t}"
    done
    local est
    est="$(du -ch "${abs_paths[@]}" 2>/dev/null | tail -1 | awk '{print $1}')"
    note "[dry-run] estimated size: ${est:-unknown}"
    return 0
  fi

  require_cmd tar
  mkdir -p "${BACKUP_DIR}"

  local -a rel_paths=()
  for t in "${abs_paths[@]}"; do
    rel_paths+=("${t#"${HOME}"/}")
  done

  if ! tar czf "${archive}" -C "${HOME}" "${rel_paths[@]}"; then
    rm -f "${archive}"
    die "backup archive creation failed — refusing to continue, nothing was deleted"
  fi

  if [ ! -s "${archive}" ]; then
    rm -f "${archive}"
    die "backup archive came out empty — refusing to continue, nothing was deleted"
  fi

  local archived_mem_files
  archived_mem_files="$(tar tzf "${archive}" 2>/dev/null | awk '/\/memory\// && !/\/$/' | wc -l | tr -d ' ')"
  if [ "${archived_mem_files}" -ne "${expected_mem_files}" ]; then
    rm -f "${archive}"
    die "backup verification failed: archive has ${archived_mem_files} memory file(s), expected ${expected_mem_files} — refusing to continue, nothing was deleted"
  fi

  local archive_size
  archive_size="$(du -h "${archive}" 2>/dev/null | awk '{print $1}')"

  {
    printf 'claude-reset.sh backup manifest\n'
    printf 'created:              %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'archive:              %s\n' "${archive}"
    printf 'archive size:         %s\n' "${archive_size:-unknown}"
    printf 'paths archived:       %d\n' "${#abs_paths[@]}"
    printf 'memory dirs:          %d\n' "${#mem_dirs[@]}"
    printf 'memory files:         %d\n' "${expected_mem_files}"
    printf 'transcripts included: %s\n' "$([ "${BACKUP_TRANSCRIPTS}" -eq 1 ] && echo yes || echo no)"
    printf '\ncontents:\n'
    for t in "${abs_paths[@]}"; do
      printf '  %s\n' "${t}"
    done
    printf '\nrestore:\n'
    printf '  tar xzf %s -C %s\n' "${archive}" "${HOME}"
  } > "${manifest}"

  note "backup written: ${archive} (${archive_size:-unknown}, verified ${archived_mem_files} memory file(s))"
  note "manifest written: ${manifest}"
}

# ------------------------------------------------------------------
# orphans
# ------------------------------------------------------------------
do_orphans() {
  compute_orphan_targets
  act_targets "${ORPHAN_TARGETS[@]}"
}

# ------------------------------------------------------------------
# credentials
# ------------------------------------------------------------------
keychain_step() {
  if [ "$(uname)" != "Darwin" ]; then
    note "not macOS, skipping Keychain step"
    return 0
  fi
  if ! have security; then
    warn "security CLI not found, skipping Keychain step"
    return 0
  fi
  if ! security find-generic-password -s "Claude Code-credentials" -a "${USER}" >/dev/null 2>&1; then
    note "already absent: Keychain entry 'Claude Code-credentials'"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    note "[dry-run] would remove: Keychain entry 'Claude Code-credentials'"
    return 0
  fi
  security delete-generic-password -s "Claude Code-credentials" -a "${USER}" >/dev/null
  note "removed: Keychain entry 'Claude Code-credentials'"
}

claude_json_surgery() {
  if [ ! -f "${CLAUDE_JSON}" ]; then
    note "absent, skipped: ${CLAUDE_JSON}"
    return 0
  fi
  if ! jq -e 'has("oauthAccount")' "${CLAUDE_JSON}" >/dev/null 2>&1; then
    note "absent, skipped: oauthAccount field in ${CLAUDE_JSON}"
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    note "[dry-run] would remove field: oauthAccount from ${CLAUDE_JSON} (rest of the file is left untouched)"
    return 0
  fi
  local tmp
  tmp="$(mktemp "${CLAUDE_JSON}.XXXXXX")"
  jq 'del(.oauthAccount)' "${CLAUDE_JSON}" > "${tmp}"
  mv -f "${tmp}" "${CLAUDE_JSON}"
  note "removed field: oauthAccount from ${CLAUDE_JSON} (project entries and hasTrustDialogAccepted flags left untouched)"
}

do_credentials() {
  compute_credential_targets
  warn "prefer /logout from inside Claude Code first — manually deleting the Keychain entry has NOT been verified to revoke the token server-side"
  guard_not_running_or_force

  act_targets "${CREDENTIAL_TARGETS[@]}"
  keychain_step
  claude_json_surgery
}

# ------------------------------------------------------------------
# state (opt-in)
# ------------------------------------------------------------------
do_state() {
  guard_not_running_or_force

  local -a reproducible=(plugins context-mode file-history cache paste-cache shell-snapshots telemetry jobs debug downloads)
  local -a targets=()
  local d
  for d in "${reproducible[@]}"; do
    targets+=("${CLAUDE_DIR}/${d}")
  done

  if [ "${INCLUDE_HISTORY}" -eq 1 ]; then
    targets+=("${CLAUDE_DIR}/sessions" "${CLAUDE_DIR}/tasks" "${CLAUDE_DIR}/teams" "${CLAUDE_DIR}/history.jsonl")
  else
    note "skipping sessions/, tasks/, teams/, history.jsonl — pass --include-history to also include prompt history / agent-team state"
  fi

  local t sz
  for t in "${targets[@]}"; do
    if [ -e "${t}" ]; then
      sz="$(du -sh -- "${t}" 2>/dev/null | awk '{print $1}')"
      note "size: ${sz:-?}  ${t}"
    fi
  done

  act_targets "${targets[@]}"
}

# ------------------------------------------------------------------
# relink
# ------------------------------------------------------------------
do_relink() {
  require_cmd git
  local repo_root="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
  [ -d "${repo_root}" ] || die "repo not found at ${repo_root} — set DOTFILES_DIR"

  if [ "${DRY_RUN}" -eq 1 ]; then
    note "[dry-run] would run: ${repo_root}/scripts/symlinks.sh install"
    note "[dry-run] would run: ${repo_root}/scripts/claude-skills link"
    return 0
  fi

  "${repo_root}/scripts/symlinks.sh" install
  "${repo_root}/scripts/claude-skills" link
  note "relink complete"
}

# ------------------------------------------------------------------
# verify (read-only)
# ------------------------------------------------------------------
check_symlink() {
  local label="$1" path="$2" status
  if [ -L "${path}" ] && [ -e "${path}" ]; then
    status="ok -> $(readlink "${path}")"
  elif [ -L "${path}" ]; then
    status="BROKEN symlink -> $(readlink "${path}")"
  elif [ -e "${path}" ]; then
    status="NOT a symlink (real file/dir)"
  else
    status="MISSING"
  fi
  printf '%-38s | %s\n' "${label}" "${status}"
}

do_verify() {
  printf '%-38s | %s\n' "check" "status"
  printf '%-38s-+-%s\n' "--------------------------------------" "----------------------------------------"

  check_symlink "root: settings.json" "${CLAUDE_DIR}/settings.json"
  check_symlink "root: CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"
  check_symlink "root: commands" "${CLAUDE_DIR}/commands"
  check_symlink "root: scripts" "${CLAUDE_DIR}/scripts"
  check_symlink "hook: context-mode-cache-heal.mjs" "${CLAUDE_DIR}/hooks/context-mode-cache-heal.mjs"
  check_symlink "hook: herdr-agent-state.sh" "${CLAUDE_DIR}/hooks/herdr-agent-state.sh"
  check_symlink "hook: herdr-workspace-guard.sh" "${CLAUDE_DIR}/hooks/herdr-workspace-guard.sh"

  local skills_total=0 skills_ok=0
  if [ -d "${CLAUDE_DIR}/skills" ]; then
    local -a skill_links=()
    mapfile -t skill_links < <(find "${CLAUDE_DIR}/skills" -maxdepth 1 -mindepth 1 -type l 2>/dev/null)
    skills_total="${#skill_links[@]}"
    local s
    for s in "${skill_links[@]}"; do
      [ -e "${s}" ] && skills_ok=$((skills_ok + 1))
    done
  fi
  printf '%-38s | %s\n' "skills symlinks resolving" "${skills_ok}/${skills_total}"

  printf '%-38s | %s\n' "projects/ present" "$([ -d "${CLAUDE_DIR}/projects" ] && echo yes || echo NO)"
  printf '%-38s | %s\n' "memory dirs" "$(count_memory_dirs)"
  printf '%-38s | %s\n' "memory files" "$(count_memory_files)"

  local oauth_status
  if [ -f "${CLAUDE_JSON}" ]; then
    if jq -e 'has("oauthAccount")' "${CLAUDE_JSON}" >/dev/null 2>&1; then
      oauth_status="present (not cleared)"
    else
      oauth_status="gone"
    fi
  else
    oauth_status="unknown (${CLAUDE_JSON} missing)"
  fi
  printf '%-38s | %s\n' "oauthAccount in ~/.claude.json" "${oauth_status}"

  local keychain_status
  if [ "$(uname)" = "Darwin" ] && have security; then
    if security find-generic-password -s "Claude Code-credentials" -a "${USER}" >/dev/null 2>&1; then
      keychain_status="present"
    else
      keychain_status="absent"
    fi
  else
    keychain_status="unknown (not macOS or security missing)"
  fi
  printf '%-38s | %s\n' "Keychain 'Claude Code-credentials'" "${keychain_status}"

  local dangling_count
  dangling_count="$(find "${CLAUDE_DIR}" -maxdepth 3 -path "${CLAUDE_DIR}/projects" -prune -o -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')"
  printf '%-38s | %s\n' "dangling symlinks (excl. projects/)" "${dangling_count}"

  local last_backup
  last_backup="$(find "${BACKUP_DIR}" -maxdepth 1 -name 'claude-reset-backup-*.tgz' 2>/dev/null | sort | tail -1)"
  printf '%-38s | %s\n' "last backup archive" "${last_backup:-none found in ${BACKUP_DIR}}"

  note ""
  note "next step: start Claude Code — you will need to log back in."
}

# ------------------------------------------------------------------
# main
# ------------------------------------------------------------------
BEFORE_MEMDIRS="$(count_memory_dirs)"
BEFORE_MEMFILES="$(count_memory_files)"

case "${PHASE}" in
  "")
    do_backup
    do_orphans
    do_credentials
    if [ "${INCLUDE_STATE}" -eq 1 ]; then
      do_state
    fi
    do_relink
    do_verify
    ;;
  backup)      do_backup ;;
  orphans)     do_orphans ;;
  credentials) do_credentials ;;
  state)       do_state ;;
  relink)      do_relink ;;
  verify)      do_verify ;;
esac

AFTER_MEMDIRS="$(count_memory_dirs)"
AFTER_MEMFILES="$(count_memory_files)"

if [ "${AFTER_MEMDIRS}" -lt "${BEFORE_MEMDIRS}" ] || [ "${AFTER_MEMFILES}" -lt "${BEFORE_MEMFILES}" ]; then
  die "projects/ memory integrity check failed: memory dirs ${BEFORE_MEMDIRS}->${AFTER_MEMDIRS}, memory files ${BEFORE_MEMFILES}->${AFTER_MEMFILES}"
fi
