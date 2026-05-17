# Catppuccin Mocha palette for fzf. Sourced from zsh / bash and exposed
# via FZF_DEFAULT_OPTS so that any tool reading that env var (fzf-vim,
# fzf-tab, etc.) inherits the same palette.
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --color=border:#313244,label:#cdd6f4"
