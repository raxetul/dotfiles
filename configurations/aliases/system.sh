# system.sh — OS-aware shortcuts. Detected once per shell invocation;
# any alias that can't be resolved on the current OS is simply not
# defined (no errors, no fallbacks).
case "$(uname -s)" in
  Darwin)
    alias o='open'
    alias copy='pbcopy'
    alias paste='pbpaste'
    alias brewup='brew update && brew upgrade && brew cleanup'
    ;;
  Linux)
    alias o='xdg-open'

    if command -v systemctl >/dev/null 2>&1; then
      alias sc='systemctl'
      alias scu='systemctl --user'
      alias jc='journalctl'
      alias jcu='journalctl --user'
    fi

    if command -v wl-copy >/dev/null 2>&1; then
      alias copy='wl-copy'
      alias paste='wl-paste'
    elif command -v xclip >/dev/null 2>&1; then
      alias copy='xclip -selection clipboard'
      alias paste='xclip -selection clipboard -o'
    fi
    ;;
esac
