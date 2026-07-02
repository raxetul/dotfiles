# ssh.sh — clean up terminal state left behind when an SSH session dies.
#
# ─── The problem ────────────────────────────────────────────────────────────
# When you SSH somewhere and attach a remote tmux (which runs `set -g mouse
# on`), that remote tmux enables mouse-tracking on THIS terminal — it sends
# the DEC private-mode "enable" sequences (ESC[?1000h, ?1002h, ?1003h, ?1006h)
# down the pipe to Ghostty on your laptop. From then on Ghostty reports every
# scroll and click back up the pipe so tmux can act on them.
#
# On a clean exit, tmux sends the matching "disable" sequences (ESC[?1006l …)
# and the terminal goes back to normal. But if the connection drops abruptly
# — network roam, VPN flap, laptop sleep, lost Wi-Fi — the pipe is already
# dead, so those disable sequences never arrive. ssh exits and drops you back
# at your LOCAL shell, but Ghostty still has mouse reporting switched on.
#
# The local shell never asked for mouse events and doesn't consume them, so
# every scroll emits an SGR mouse report (ESC[<35;93;56M). The line editor
# eats the ESC[< prefix as a meta-escape and echoes the leftover payload —
# that's the `35;93;56M35;92;56M…` garbage you see at the prompt.
#
# ─── The fix ────────────────────────────────────────────────────────────────
# Wrap `ssh` so that after EVERY invocation (clean exit or dropped link) we
# re-send the "disable" sequences ourselves. The remote is gone, so cleanup
# has to happen here on the client. Re-disabling a mode that's already off is
# a harmless no-op, so it's safe to run unconditionally after ssh.
#
# Modes reset (each is `ESC [ ? <n> l`, the DEC private-mode reset form):
#   1000  mouse: report button press/release only
#   1002  mouse: also report motion while a button is held (drag)
#   1003  mouse: report ALL motion, even with no button down
#   1005  mouse: UTF-8 extended coordinate encoding (legacy)
#   1006  mouse: SGR extended coordinate encoding (what tmux uses today)
#   1015  mouse: urxvt extended coordinate encoding (legacy)
#   2004  bracketed paste — another mode a dying remote app can strand
ssh() {
    # Run the real ssh (bypass this function) with all args passed through.
    command ssh "$@"
    # Capture ssh's exit status immediately, before printf clobbers $?.
    local rc=$?
    # Only emit escapes when stdout is a real terminal. This keeps
    # `ssh host cmd > file` (or piped) output clean — no control bytes leak
    # into a redirected stream.
    [ -t 1 ] && printf '\033[?1000l\033[?1002l\033[?1003l\033[?1005l\033[?1006l\033[?1015l\033[?2004l'
    # Preserve ssh's own exit code so scripts and `$?` checks still work.
    return "${rc}"
}
