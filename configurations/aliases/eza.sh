# eza.sh — override ls/ll/la with eza when it's installed.
#
# Loaded after 00-general.sh (lexical order), so the eza versions
# take precedence on hosts that have eza on PATH; hosts without
# eza keep the plain `ls` aliases from 00-general.sh untouched.
#
# Flags mirror what programs.eza.extraOptions set in v2:
#   --group-directories-first  — dirs sorted above files in every listing
#   --icons=auto               — Nerd Font glyphs when stdout is a TTY
# Palette comes from $EZA_COLORS, exported in configurations/zsh/exports.sh.

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --group-directories-first --icons=auto'
    alias ll='eza -l --group-directories-first --icons=auto'
    alias la='eza -la --group-directories-first --icons=auto'
    alias lt='eza --tree --group-directories-first --icons=auto'
fi
