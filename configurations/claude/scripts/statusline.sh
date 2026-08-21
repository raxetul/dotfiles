#!/usr/bin/env bash
# statusline.sh — Claude Code status line, rendered as 3 columns × 3 lines.
#
#   ┌ LEFT (workspace) ──┐ ┌ MIDDLE (context meter) ┐ ┌ RIGHT (agentic phases) ┐
#   │ 💻 host 📁 cwd     │ │ ⚡ context  12%        │ │ ✓ <completed phase>    │
#   │  branch* (git)     │ │ 121k / 1.0M            │ │ ▶ <current phase>      │
#   │  model · vX.Y      │ │ [████░░░░░░░░░░░]      │ │ ○ <next phase>         │
#   └────────────────────┘ └───────────────────────┘ └────────────────────────┘
#
# On a vertical / narrow terminal (mobile SSH, e.g. ConnectBot) it collapses to
# ONE compact line — the model name, plus the current phase when the project
# defines phases (the phase segment is hidden when it doesn't):
#
#   🤖 Opus 4.8  ▶ Module loader     (phases defined → current phase shown)
#   🤖 Opus 4.8                      (no phases → phase segment hidden)
#
# Compact auto-engages when the terminal is portrait (LINES > COLUMNS) or under
# 60 columns; force it with CLAUDE_STATUSLINE_COMPACT=1, disable with =0. The
# size is re-read live every render (herdr pane rect → /dev/tty → COLUMNS/LINES),
# so it flips back to full-size when a mobile client closes and the pane grows.
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
account_email="$(jq -r '.oauthAccount.emailAddress // ""' "${HOME}/.claude.json" 2>/dev/null)"

# ---------------------------------------------------------------------------
# colors
# ---------------------------------------------------------------------------
RST=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYN=$'\033[36m'; BLU=$'\033[34m'; MAG=$'\033[35m'

# ---------------------------------------------------------------------------
# width helpers (each wide emoji we emit counts as 2 cols, not 1)
# ---------------------------------------------------------------------------
WIDE_GLYPHS=(📁 💻 ⚡ 📧 🌿 🤖 🔖 📊)
count_occ() { local h="$1" n="$2" t="${1//$2/}"; echo $(( ${#h} - ${#t} )); }
vislen() {                       # visible columns of a plain (uncolored) string
  local s="$1" extra=0 g
  for g in "${WIDE_GLYPHS[@]}"; do extra=$(( extra + $(count_occ "$s" "$g") )); done
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
seg() { printf '%b%s%b' "$2" "$1" "$RST"; }   # $1 text, $2 color -> colored, no padding
mcell() {                        # $1 plaintext, $2 pre-colored, $3 fallback color
  local plain="$1" colored="$2" fb="$3" vl   # multi-color line padded to COLW;
  vl="$(vislen "$plain")"                     # falls back to a truncated cell when too wide
  if [ "$vl" -gt "$COLW" ]; then cell "$plain" "$fb"
  else printf '%s%*s' "$colored" "$(( COLW - vl ))" ''; fi
}

# ---------------------------------------------------------------------------
# geometry — pick the AUTHORITATIVE live terminal size, most-reliable first:
#   1. herdr's current pane rect — correct even when a persistent session is
#      reattached from a wider client and Claude's exported COLUMNS/LINES lag;
#   2. the kernel pty winsize via /dev/tty;
#   3. the COLUMNS/LINES Claude Code exports (v2.1.153+);  4. a sane default.
# Re-read on every render, so compact flips back to full-size when a mobile
# client closes and the pane grows again.
# ---------------------------------------------------------------------------
herdr_size() {                        # echo "COLS ROWS" from herdr's live layout
  [ -n "${HERDR_ENV:-}" ] && [ -n "${HERDR_PANE_ID:-}" ] || return 1
  command -v herdr >/dev/null 2>&1 || return 1
  herdr pane layout --pane "$HERDR_PANE_ID" 2>/dev/null | jq -r --arg id "$HERDR_PANE_ID" '
    .result.layout as $L
    | ( ($L.panes[]? | select(.pane_id==$id) | .rect) // $L.area )
    | "\(.width) \(.height)"' 2>/dev/null
}

W=0; ROWS=0
_sz="$(herdr_size || true)"                          # 1. herdr pane rect
[ -n "$_sz" ] && { W="${_sz%% *}"; ROWS="${_sz##* }"; }
if ! [ "$W" -gt 0 ] 2>/dev/null; then                # 2. live pty winsize
  _sz="$( (stty size </dev/tty) 2>/dev/null )"       #    ("ROWS COLS"); the
  [ -n "$_sz" ] && { ROWS="${_sz%% *}"; W="${_sz##* }"; }  # subshell hides a
fi                                                   # /dev/tty open failure
[ "$W" -gt 0 ]    2>/dev/null || W="${COLUMNS:-0}"    # 3. Claude-exported
[ "$ROWS" -gt 0 ] 2>/dev/null || ROWS="${LINES:-0}"
[ "$W" -gt 0 ]    2>/dev/null || W=120               # 4. default
[ "$ROWS" -gt 0 ] 2>/dev/null || ROWS=0

SEP=" ${DIM}│${RST} "                 # 3 visible cols
COLW=$(( (W - 6) / 3 ))
[ "$COLW" -lt 12 ] && COLW=12

# ---------------------------------------------------------------------------
# compact mode — vertical / narrow terminals (mobile SSH, e.g. ConnectBot).
# Emits ONE line: model, plus the current phase when the project defines phases
# (hidden otherwise), then exits before the full 3-column layout runs.
# ---------------------------------------------------------------------------
compact=0
case "${CLAUDE_STATUSLINE_COMPACT:-auto}" in
  1|on|yes|true)  compact=1 ;;
  0|off|no|false) compact=0 ;;
  *) { [ "$ROWS" -gt 0 ] && [ "$ROWS" -gt "$W" ]; } && compact=1
     [ "$W" -lt 60 ] && compact=1 ;;
esac

if [ "$compact" = 1 ]; then
  c_plain="🤖 ${model}"
  c_col="$(seg "🤖 ${model}" "$B$MAG")"
  if [ -x "$PHASES" ] && "$PHASES" detect "$cwd" >/dev/null 2>&1; then
    mapfile -t _pc < <("$PHASES" cells "$cwd" 2>/dev/null)
    for _c in "${_pc[@]}"; do
      if [ "${_c%%$'\t'*}" = current ]; then
        _ct="${_c#*$'\t'}"
        c_plain="${c_plain}  ▶ ${_ct}"
        c_col="${c_col}  $(seg "▶ ${_ct}" "$B$YEL")"
        break
      fi
    done
  fi
  if [ "$(vislen "$c_plain")" -le "$W" ]; then printf '%b' "$c_col"
  else printf '%b' "$(seg "$(trunc "$c_plain" "$W")" "$B$MAG")"; fi
  exit 0
fi

# ---------------------------------------------------------------------------
# LEFT PANE — workspace (extend here: add a row -> L4, etc.)
# ---------------------------------------------------------------------------
# Each row carries two items, each with its own icon + color, separated by 2 spaces.
host="$(hostname -s 2>/dev/null || printf '%s' "${HOSTNAME%%.*}")"
cwd_disp="${cwd/#$HOME/\~}"

# L1 — host (💻 cyan) · cwd (📁 blue)
L1_PLAIN="💻 ${host} 📁 ${cwd_disp}"
L1_COL="$(seg "💻 ${host}" "$B$CYN") $(seg "📁 ${cwd_disp}" "$B$BLU")"

# L2 — account email (📧 yellow) · git branch (🌿 green, red when no repo)
branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
            || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)"
  if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then branch="${branch}*"; fi
  git_item="🌿 ${branch}"; git_col="$GRN"
else
  git_item="🌿 (no git)"; git_col="$RED"
fi
if [ -n "$account_email" ]; then
  L2_PLAIN="📧 ${account_email} ${git_item}"
  L2_COL="$(seg "📧 ${account_email}" "$YEL") $(seg "${git_item}" "$git_col")"
else
  L2_PLAIN="${git_item}"
  L2_COL="$(seg "${git_item}" "$git_col")"
fi

# L3 — model (🤖 magenta) · version (🔖 dim)
L3_PLAIN="🤖 ${model}"
L3_COL="$(seg "🤖 ${model}" "$MAG")"
if [ -n "$version" ]; then
  L3_PLAIN="${L3_PLAIN} 🔖 v${version}"
  L3_COL="${L3_COL} $(seg "🔖 v${version}" "$DIM")"
fi

L1="$(mcell "$L1_PLAIN" "$L1_COL" "$B$CYN")"
L2="$(mcell "$L2_PLAIN" "$L2_COL" "$GRN")"
L3="$(mcell "$L3_PLAIN" "$L3_COL" "$DIM")"

# ---------------------------------------------------------------------------
# MIDDLE PANE — context-window meter
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
  # used tokens take the fill color, the window total stays dim
  M2_PLAIN="📊 $(human "$used") / $(human "$win")"
  M2_COL="$(seg "📊 $(human "$used")" "$MC")$(seg " / $(human "$win")" "$DIM")"
  M2="$(mcell "$M2_PLAIN" "$M2_COL" "$DIM")"
  # bar built to an exact known width, then padded manually
  bartxt="[${bar_fill}${bar_empty}]"
  barpad=$(( COLW - (barw + 2) )); [ "$barpad" -lt 0 ] && barpad=0
  M3="$(printf '%b[%b%s%b%s%b]%b%*s' "$DIM" "$MC" "$bar_fill" "$DIM" "$bar_empty" "$DIM" "$RST" "$barpad" '')"
else
  M1="$(cell "⚡ context" "$B$BLU")"
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
