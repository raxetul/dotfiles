# 00-general.sh — POSIX aliases sourced by both bash and zsh.
# Loaded first (lexical order) so subsequent files can override anything here.
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Run a command without recording it in shell history (zsh + bash both
# treat a leading space this way once HISTCONTROL/HISTORY include it).
alias hide=' '

# Fast reload of the running shell's rc.
alias reload='exec "$SHELL" -l'
