#!/usr/bin/env bash
# agentic-phases.sh — detect & render the agentic-development phase status for a project.
#
# Usage:
#   agentic-phases.sh detect <dir>   # exit 0 if the project defines phases, else 1 (no output)
#   agentic-phases.sh render <dir>   # print the one-line status strip once
#   agentic-phases.sh watch  <dir>   # clear+render in a loop (for the tmux pane)
#
# A project "defines phases for agentic development" if one of these exists (first match wins):
#   1. $AGENTIC_PHASES_FILE (relative to <dir>), if that env var is set  — for dedicated files with a custom name
#   2. a dedicated file: PHASES.md, .agentic-phase, .agentic-phases, phases.md, PHASE.md
#   3. a "## Phases" (or "# Phase") section inside project.md / README.md
#
# Phase lines are GitHub-style task-list items, in order:
#   - [x] Foundation        (completed)
#   - [ ] Module loader      (pending; first pending = current)
#
# The strip shows the last 2 completed and the next 2 upcoming titles.

set -uo pipefail

DIR="${2:-$PWD}"
WATCH_INTERVAL="${AGENTIC_PHASES_INTERVAL:-5}"

# --- locate the phase source ------------------------------------------------
find_phase_file() {
  local dir="$1" f
  if [ -n "${AGENTIC_PHASES_FILE:-}" ] && [ -f "$dir/$AGENTIC_PHASES_FILE" ]; then
    printf '%s\n' "$dir/$AGENTIC_PHASES_FILE"; return 0
  fi
  for f in PHASES.md .agentic-phase .agentic-phases phases.md PHASE.md; do
    [ -f "$dir/$f" ] && { printf '%s\n' "$dir/$f"; return 0; }
  done
  for f in project.md README.md; do
    if [ -f "$dir/$f" ] && grep -qiE '^#{1,6}[[:space:]]+phases?([[:space:]]|$)' "$dir/$f"; then
      printf '%s\n' "$dir/$f"; return 0
    fi
  done
  return 1
}

# --- pull the relevant checklist lines out of the source --------------------
extract_lines() {
  local file="$1"
  case "$(basename "$file")" in
    project.md|README.md)
      # only the lines under the first "# Phases" heading, up to the next heading
      awk '
        /^#{1,6}[[:space:]]+[Pp]hases?([[:space:]]|$)/ { insec=1; next }
        insec && /^#{1,6}[[:space:]]/ { insec=0 }
        insec { print }
      ' "$file"
      ;;
    *) cat "$file" ;;
  esac
}

# --- parse into completed / pending title arrays (order preserved) ----------
done_titles=()
todo_titles=()
parse_phases() {
  local file="$1" line mark title
  done_titles=(); todo_titles=()
  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*[-*][[:space:]]+\[([ xX])\][[:space:]]*(.*)$ ]]; then
      mark="${BASH_REMATCH[1]}"
      title="${BASH_REMATCH[2]}"
      title="${title%"${title##*[![:space:]]}"}"   # rstrip
      [ -z "$title" ] && continue
      if [[ "$mark" == "x" || "$mark" == "X" ]]; then
        done_titles+=("$title")
      else
        todo_titles+=("$title")
      fi
    fi
  done < <(extract_lines "$file")
}

# --- detect -----------------------------------------------------------------
cmd_detect() {
  local file
  file="$(find_phase_file "$DIR")" || return 1
  parse_phases "$file"
  [ "${#done_titles[@]}" -gt 0 ] || [ "${#todo_titles[@]}" -gt 0 ]
}

# --- render one line --------------------------------------------------------
cmd_render() {
  local file
  if ! file="$(find_phase_file "$DIR")"; then
    printf 'agentic: no phases defined\n'; return 0
  fi
  parse_phases "$file"

  local nd=${#done_titles[@]} nt=${#todo_titles[@]} total
  total=$((nd + nt))

  # colors (only if stdout is a tty)
  local C_RST C_HDR C_DONE C_CUR C_NEXT C_DIM
  if [ -t 1 ]; then
    C_RST=$'\033[0m'; C_HDR=$'\033[1m'; C_DONE=$'\033[32m'
    C_CUR=$'\033[1;33m'; C_NEXT=$'\033[2m'; C_DIM=$'\033[2m'
  else
    C_RST=''; C_HDR=''; C_DONE=''; C_CUR=''; C_NEXT=''; C_DIM=''
  fi

  printf '%sagentic phases%s %s(%d/%d)%s  ' "$C_HDR" "$C_RST" "$C_DIM" "$nd" "$total" "$C_RST"

  # last 2 completed
  local start=$(( nd > 2 ? nd - 2 : 0 )) i
  [ "$start" -gt 0 ] && printf '%s…%s ' "$C_DIM" "$C_RST"
  for (( i=start; i<nd; i++ )); do
    printf '%s✓ %s%s  ' "$C_DONE" "${done_titles[$i]}" "$C_RST"
  done

  # next 2 upcoming (first pending = current ▶)
  local shown=0
  for (( i=0; i<nt && shown<2; i++ )); do
    if [ "$i" -eq 0 ]; then
      printf '%s▶ %s%s  ' "$C_CUR" "${todo_titles[$i]}" "$C_RST"
    else
      printf '%s○ %s%s  ' "$C_NEXT" "${todo_titles[$i]}" "$C_RST"
    fi
    shown=$((shown + 1))
  done
  [ "$nt" -gt 2 ] && printf '%s…%s' "$C_DIM" "$C_RST"
  printf '\n'
}

# --- 3 cells for the status-line right pane ---------------------------------
# Prints exactly 3 lines, each "STATE\tTITLE":
#   line 1  -> last completed phase   (state: done | none)
#   line 2  -> current phase          (state: current | none)
#   line 3  -> next upcoming phase    (state: next | none)
# No colors/markers — the status line decides how to render each state.
cmd_cells() {
  local file
  if ! file="$(find_phase_file "$DIR")"; then
    printf 'none\t\nnone\t\nnone\t\n'; return 0
  fi
  parse_phases "$file"
  local nd=${#done_titles[@]} nt=${#todo_titles[@]}

  # last completed
  if [ "$nd" -gt 0 ]; then
    printf 'done\t%s\n' "${done_titles[$((nd-1))]}"
  else
    printf 'none\t\n'
  fi
  # current (first pending)
  if [ "$nt" -gt 0 ]; then
    printf 'current\t%s\n' "${todo_titles[0]}"
  else
    printf 'none\t\n'
  fi
  # next (second pending)
  if [ "$nt" -gt 1 ]; then
    printf 'next\t%s\n' "${todo_titles[1]}"
  else
    printf 'none\t\n'
  fi
}

# --- watch loop -------------------------------------------------------------
cmd_watch() {
  # exit cleanly if the project stops defining phases
  while cmd_detect; do
    printf '\033[H\033[2J'          # home + clear
    cmd_render
    sleep "$WATCH_INTERVAL"
  done
  printf '\033[H\033[2Jagentic: phases no longer defined — closing\n'
  sleep 2
}

case "${1:-render}" in
  detect) cmd_detect ;;
  render) cmd_render ;;
  cells)  cmd_cells ;;
  watch)  cmd_watch ;;
  *) echo "usage: $0 {detect|render|cells|watch} <dir>" >&2; exit 2 ;;
esac
