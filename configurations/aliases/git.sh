# git.sh — replaces the oh-my-zsh `git` plugin. Names mirror that plugin
# closely enough that muscle memory carries over, but only the commands
# actually used in day-to-day work are included.
alias g='git'

alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'

alias gst='git status'
alias gss='git status -sb'

alias gco='git checkout'
alias gcb='git checkout -b'

alias gc='git commit'
alias gca='git commit -a'
alias gcmsg='git commit -m'
alias gcmsga='git commit -am'

alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'

alias glo='git log --oneline --decorate'
alias glg='git log --graph --oneline --decorate --all'

alias gd='git diff'
alias gds='git diff --staged'

alias gb='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'

alias gf='git fetch'
alias gfa='git fetch --all --prune'

alias gr='git rebase'
alias gri='git rebase -i'
alias grc='git rebase --continue'
alias gra='git rebase --abort'

alias gsta='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
