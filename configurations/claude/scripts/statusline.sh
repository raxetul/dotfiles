#!/usr/bin/env bash
# statusline.sh — Claude Code status line, rendered as 3 columns × 3 lines.
#
#   ┌ LEFT (workspace) ──┐ ┌ MIDDLE (context-mode) ┐ ┌ RIGHT (agentic phases) ┐
#   │ 📁 cwd             │ │ ⚡ context  12%        │ │ ✓ <completed phase>    │
#   │  branch* (git)     │ │ 121k / 1.0M            │ │ ▶ <current phase>      │
#   │  model · vX.Y      │ │ [████░░░░░░░░░░░]      │ │ ○ <next phase>         │
#   └────────────────────┘ └───────────────────────┘ └────────────────────────┘
#
# Reads the status-line JSON payload from stdin. The left pane is intentionally
# extensible — add rows under "LEFT PANE" below.
#
# Context window can be overridden with CLAUDE_CONTEXT_WINDOW (tokens).

set -uo pipefail
export LC_ALL="${LC_ALL:-C.UTF-8}" 2>/dev/null || true

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASES="$SELF_DIR/agentic-phases.sh"

# ---------------------------------------------------------------------------
# read payload
# ---------------------------------------------------------------------------
payload="$(cat 2>/dev/null || true)"
jqr() { printf '%s' "$payload" | jq -r "$1" 2>/dev/null; }

cwd="$(jqr '.workspace.current_dir // .cwd // "."')"
[ -z "$cwd" ] || [ "$cwd" = "null" ] && cwd="$PWD"
model="$(jqr '.model.display_name // .model.id // "?"')"
model_id="$(jqr '.model.id // ""')"
version="$(jqr '.version // ""')"
transcript="$(jqr '.transcript_path // ""')"
exceeds200k="$(jqr '.exceeds_200k_tokens // false')"

# ---------------------------------------------------------------------------
# colors
# ---------------------------------------------------------------------------
RST=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYN=$'\033[36m'; BLU=$'\033[34m'

# ---------------------------------------------------------------------------
# width helpers (account for the few wide glyphs we emit: 📁 ⚡)
# ---------------------------------------------------------------------------
count_occ() { local h="$1" n="$2" t="${1//$2/}"; echo $(( ${#h} - ${#t} )); }
vislen() {                       # visible columns of a plain (uncolored) string
  local s="$1" extra=0
  extra=$(( extra + $(count_occ "$s" "📁") ))
  extra=$(( extra + $(count_occ "$s" "⚡") ))
  echo $(( ${#s} + extra ))
}
trunc() {                        # $1 string, $2 max cols -> truncated with …
  local s="$1" max="$2"
  [ "$(vislen "$s")" -le "$max" ] && { printf '%s' "$s"; return; }
  while [ -n "$s" ] && [ "$(vislen "$s…")" -gt "$max" ]; do s="${s%?}"; done
  printf '%s…' "$s"
}
cell() {                         # $1 plaintext, $2 color -> exactly COLW cols, colored
  local s pad vl; s="$(trunc "$1" "$COLW")"; vl=$(vislen "$s")
  pad=$(( COLW - vl )); [ "$pad" -lt 0 ] && pad=0
  printf '%b%s%b%*s' "$2" "$s" "$RST" "$pad" ''
}

# ---------------------------------------------------------------------------
# geometry
# ---------------------------------------------------------------------------
W="${COLUMNS:-0}"
[ "$W" -gt 0 ] 2>/dev/null || W="$(tput cols 2>/dev/null || echo 120)"
[ "$W" -ge 60 ] 2>/dev/null || W=120
SEP=" ${DIM}│${RST} "                 # 3 visible cols
COLW=$(( (W - 6) / 3 ))
[ "$COLW" -lt 12 ] && COLW=12

# ---------------------------------------------------------------------------
# LEFT PANE — workspace (extend here: add a row -> L4, etc.)
# ---------------------------------------------------------------------------
disp_cwd="📁 ${cwd/#$HOME/\~}"
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
            || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"
  if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then branch="${branch}*"; fi
  L2_TXT=" ${branch}"
else
  L2_TXT=" (no git)"
fi
L3_TXT=" ${model}"
[ -n "$version" ] && L3_TXT="$L3_TXT · v${version}"

L1="$(cell "$disp_cwd" "$B$CYN")"
L2="$(cell "$L2_TXT" "$GRN")"
L3="$(cell "$L3_TXT" "$DIM")"

# ---------------------------------------------------------------------------
# MIDDLE PANE — context-mode (context-window meter)
# ---------------------------------------------------------------------------
human() {                        # tokens -> 1.0M / 121k / 850
  local n="$1"
  if [ "$n" -ge 1000000 ]; then awk -v n="$n" 'BEGIN{printf "%.1fM", n/1000000}'
  elif [ "$n" -ge 1000 ]; then echo "$(( n / 1000 ))k"
  else echo "$n"; fi
}

used=0
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  line="$(tac "$transcript" 2>/dev/null | grep -m1 '"input_tokens"' || true)"
  if [ -n "$line" ]; then
    read -r i cc cr < <(printf '%s' "$line" | jq -r \
      '.message.usage | "\(.input_tokens // 0) \(.cache_creation_input_tokens // 0) \(.cache_read_input_tokens // 0)"' 2>/dev/null)
    used=$(( ${i:-0} + ${cc:-0} + ${cr:-0} ))
  fi
fi

# window size
if [ -n "${CLAUDE_CONTEXT_WINDOW:-}" ]; then win="$CLAUDE_CONTEXT_WINDOW"
elif printf '%s' "$model_id" | grep -qi '1m'; then win=1000000
elif [ "$used" -gt 200000 ]; then win=1000000
else win=200000; fi

pct=0; [ "$win" -gt 0 ] && pct=$(( used * 100 / win ))
[ "$pct" -gt 100 ] && pct=100

# color by fill level
if   [ "$pct" -lt 60 ]; then MC="$GRN"
elif [ "$pct" -lt 85 ]; then MC="$YEL"
else MC="$RED"; fi

# bar fills the column width
barw=$(( COLW - 2 )); [ "$barw" -lt 4 ] && barw=4
fill=$(( pct * barw / 100 )); [ "$fill" -gt "$barw" ] && fill=barw
empty=$(( barw - fill ))
bar_fill=""; bar_empty=""
for ((x=0;x<fill;x++)); do bar_fill+="█"; done
for ((x=0;x<empty;x++)); do bar_empty+="░"; done

if [ "$used" -gt 0 ]; then
  M1="$(cell "⚡ context  ${pct}%" "$B$MC")"
  M2="$(cell " $(human "$used") / $(human "$win")" "$DIM")"
  # bar built to an exact known width, then padded manually
  bartxt="[${bar_fill}${bar_empty}]"
  barpad=$(( COLW - (barw + 2) )); [ "$barpad" -lt 0 ] && barpad=0
  M3="$(printf '%b[%b%s%b%s%b]%b%*s' "$DIM" "$MC" "$bar_fill" "$DIM" "$bar_empty" "$DIM" "$RST" "$barpad" '')"
else
  M1="$(cell "⚡ context-mode" "$B$BLU")"
  M2="$(cell " no usage yet" "$DIM")"
  M3="$(cell "" "$DIM")"
fi

# ---------------------------------------------------------------------------
# RIGHT PANE — agentic phases (completed / current / next)
# ---------------------------------------------------------------------------
R1_TXT=""; R2_TXT=""; R3_TXT=""; R1C="$DIM"; R2C="$DIM"; R3C="$DIM"
if [ -x "$PHASES" ]; then
  mapfile -t _cells < <("$PHASES" cells "$cwd" 2>/dev/null)
  parse_cell() {                 # $1 = "STATE\tTITLE" -> sets _state/_title
    _state="${1%%$'\t'*}"; _title="${1#*$'\t'}"
  }
  if [ "${#_cells[@]}" -ge 3 ]; then
    parse_cell "${_cells[0]}"; [ "$_state" = done ]    && { R1_TXT="✓ $_title"; R1C="$GRN"; }
    parse_cell "${_cells[1]}"; [ "$_state" = current ] && { R2_TXT="▶ $_title"; R2C="$B$YEL"; }
    parse_cell "${_cells[2]}"; [ "$_state" = next ]    && { R3_TXT="○ $_title"; R3C="$DIM"; }
  fi
fi
[ -z "$R1_TXT" ] && R1_TXT="✓ —"
[ -z "$R2_TXT" ] && R2_TXT="▶ no phases"
[ -z "$R3_TXT" ] && R3_TXT="○ —"
R1="$(cell "$R1_TXT" "$R1C")"
R2="$(cell "$R2_TXT" "$R2C")"
R3="$(cell "$R3_TXT" "$R3C")"

# ---------------------------------------------------------------------------
# emit 3 lines
# ---------------------------------------------------------------------------
printf '%s%s%s%s%s\n' "$L1" "$SEP" "$M1" "$SEP" "$R1"
printf '%s%s%s%s%s\n' "$L2" "$SEP" "$M2" "$SEP" "$R2"
printf '%s%s%s%s%s'   "$L3" "$SEP" "$M3" "$SEP" "$R3"
