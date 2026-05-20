#!/usr/bin/env sh
# exports.sh — env vars sourced from both .zshrc and .bashrc.
# Mirrors what `home.sessionVariables` + `programs.*.environment` were
# setting under Home Manager.

# Editors
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-${EDITOR}}"
export PAGER="${PAGER:-less}"

# eza Catppuccin Mocha palette. The yaml under configurations/themes/eza/
# is the human-readable reference for the same values.
export EZA_COLORS="uu=38;2;205;214;244:gu=38;2;205;214;244:da=38;2;180;190;254:sb=38;2;249;226;175:sn=38;2;205;214;244:di=38;2;137;180;250;1:ex=38;2;166;227;161;1:ln=38;2;245;194;231:lc=38;2;245;194;231:pi=38;2;249;226;175:so=38;2;249;226;175:bd=38;2;243;139;168:cd=38;2;243;139;168:or=38;2;243;139;168;1:xx=38;2;127;132;156"

# bat as the man pager.
export MANPAGER="sh -c 'col -bx | bat -l man -p 2>/dev/null || col -bx | batcat -l man -p'"
export MANROFFOPT="-c"

# fzf defaults — pick up the Catppuccin palette by sourcing
# configurations/themes/fzf/catppuccin-mocha.sh (done in zshrc/bashrc).
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git/*'"
export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git 2>/dev/null || fdfind --type d --hidden --follow --exclude .git"
