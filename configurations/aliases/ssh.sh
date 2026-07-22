# ssh.sh — clean up terminal state left behind when an SSH session dies.
#
# ─── The problem ────────────────────────────────────────────────────────────
# A remote full-screen app (nvim, tmux, a modern TUI) turns on extra INPUT
# reporting modes on THIS terminal for the duration of the session — it sends
# the "enable" sequences down the pipe to Ghostty on your laptop, and Ghostty
# then reports keys/scrolls/etc. back up the pipe so the remote app can act on
# them. The two that bite here:
#   • Kitty keyboard protocol (CSI-u): progressive key reporting, incl. key
#     PRESS *and* RELEASE events — enabled with `ESC[>{flags}u` (a stack push).
#   • Mouse tracking + bracketed paste: `ESC[?1000h`/`?1002h`/`?1006h`, `?2004h`.
#
# On a clean exit the app sends the matching "disable" (pop `ESC[<u`, `ESC[?…l`)
# and the terminal returns to normal. But if the link drops abruptly — network
# roam, VPN flap, laptop sleep, lost Wi-Fi — the pipe is already dead, so those
# disables never arrive. ssh drops you back at your LOCAL shell while Ghostty is
# still in the enhanced mode.
#
# The local shell never asked for these reports, so it echoes them as garbage.
# With the keyboard protocol on, every keystroke emits a key-event report and
# you see `s15;1:3u…`-style codes as you type (`:3` = key release). With mouse
# on, every scroll emits `ESC[<35;93;56M`; zsh eats the `ESC[<` and echoes the
# leftover `35;93;56M…`.
#
# ─── The fix ────────────────────────────────────────────────────────────────
# Two parts:
#  1. Wrap `ssh` so that after EVERY invocation (clean exit or dropped link) we
#     re-send the "disable" sequences ourselves. The remote is gone, so cleanup
#     has to happen here on the client. Re-disabling a mode that's already off
#     is a harmless no-op, so it's safe to run unconditionally after ssh.
#  2. Expose the same cleanup as a standalone `reset-term` command. The wrapper
#     only fires once `ssh` RETURNS — but an abruptly dropped link can leave ssh
#     hung for a while (up to ServerAliveInterval * CountMax; see ~/.ssh/config),
#     or you may hit a *different* pane whose shell never ran the wrapper. In
#     those cases type `reset-term` to clean the current terminal immediately.
#     (Ghostty's cmd+shift+r does a FULL reset, but that also wipes scrollback;
#     this is the surgical, scrollback-preserving version.)
#
# Modes/state reset:
#   CSI<u kitty keyboard protocol: pop enhancement level(s) — the key-event
#         (`13;1:3u`) strand; sent 3× to unwind nested pushes (herdr + app)
#   1000  mouse: report button press/release only
#   1002  mouse: also report motion while a button is held (drag)
#   1003  mouse: report ALL motion, even with no button down
#   1004  focus: report terminal focus in/out (ESC[I / ESC[O)
#   1005  mouse: UTF-8 extended coordinate encoding (legacy)
#   1006  mouse: SGR extended coordinate encoding (what tmux uses today)
#   1015  mouse: urxvt extended coordinate encoding (legacy)
#   2004  bracketed paste — another mode a dying remote app can strand
#   ESC(B invoke ASCII into G0 — undo a stranded DEC line-drawing charset
#   SI    shift-in (0x0F) — reselect G0 after a stray Shift-Out to G1
#   ESC>  normal keypad — undo application-keypad mode
__ssh_term_reset() {
    # Only touch the terminal when stdout is a real tty, so redirected/piped
    # output (`ssh host cmd > file`) stays clean — no control bytes leak.
    [ -t 1 ] || return 0
    # Kitty keyboard protocol (CSI-u): pop any enhancement level a dropped
    # remote app (nvim / tmux / a modern TUI) left pushed. THIS is the mode
    # that echoes `13;1:3u`-style key-event codes (`:3` = key release) at the
    # prompt. `CSI < u` pops one level; popping an empty stack is a no-op, so
    # several pops safely undo nested pushes (e.g. a multiplexer such as herdr
    # plus a full-screen app inside the session).
    printf '\033[<u\033[<u\033[<u'
    # mouse (1000/1002/1003), focus (1004), coord encodings (1005/1006/1015),
    # bracketed paste (2004):
    printf '\033[?1000l\033[?1002l\033[?1003l\033[?1004l\033[?1005l\033[?1006l\033[?1015l\033[?2004l'
    # charset G0 → ASCII, shift-in, keypad → normal:
    printf '\033(B\017\033>'
}

# Manual recovery: run `reset-term` in any pane the terminal got stranded in.
reset_term() { __ssh_term_reset; }
alias reset-term='reset_term'

ssh() {
    # Run the real ssh (bypass this function) with all args passed through.
    command ssh "$@"
    # Capture ssh's exit status immediately, before the cleanup clobbers $?.
    local rc=$?
    __ssh_term_reset
    # Preserve ssh's own exit code so scripts and `$?` checks still work.
    return "${rc}"
}
