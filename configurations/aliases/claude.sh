# shellcheck shell=bash
# claude.sh — mobile-friendly launch wrapper for Claude Code.
#
# ─── The problem ────────────────────────────────────────────────────────────
# The global setting is "tui": "fullscreen" (see configurations/claude/
# settings.json), which renders into the terminal's *alternate screen buffer*
# — like vim/htop. That's great on a desktop (no flicker, mouse support), but
# Android's ConnectBot (and other basic SSH clients) can't scroll back through
# the alternate buffer, so the Claude chat history becomes unreachable on a
# phone.
#
# ─── The fix ────────────────────────────────────────────────────────────────
# Launch mobile sessions with the classic renderer ("tui": "default"), which
# uses the terminal's OWN scrollback — so ConnectBot can scroll the chat again.
# This is a per-session override via `--settings`; the global fullscreen
# setting is untouched, so desktop sessions still get the fullscreen TUI.
#
# Auto-engages on a portrait terminal (lines > columns — the mobile case);
# force it anywhere with CLAUDE_MOBILE=1 (handy to set in ConnectBot's host
# settings). If you pass your own --settings, this wrapper stays out of the way.
#
# The statusline (configurations/claude/scripts/statusline.sh) independently
# collapses to its compact one-line layout on the same narrow/portrait screens.
claude() {
  local cols rows
  cols="$(tput cols 2>/dev/null || echo 0)"
  rows="$(tput lines 2>/dev/null || echo 0)"
  case " $* " in
    *" --settings "*)
      command claude "$@" ;;                       # caller controls settings
    *)
      if [ "${CLAUDE_MOBILE:-0}" = 1 ] || \
         { [ "$rows" -gt 0 ] && [ "$cols" -gt 0 ] && [ "$rows" -gt "$cols" ]; }; then
        command claude --settings '{"tui":"default"}' "$@"
      else
        command claude "$@"
      fi ;;
  esac
}
