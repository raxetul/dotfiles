{ config, pkgs, ... }:

# Zsh — no oh-my-zsh. Plugin coverage is provided by a much shorter list:
#   * autosuggestion / syntaxHighlighting / completion / historySubstringSearch
#     come from Home Manager's built-in zsh options.
#   * `you-should-use` reminds you when an alias would have saved keystrokes.
#   * History recall is delegated to atuin (see ./atuin.nix), which replaces
#     the old zsh-histdb plugin and the HISTORY_IGNORE regex.
#   * Day-to-day aliases (g/gst/k/d/…) live in configurations/aliases/ so
#     bash and zsh always see the same set.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      share = true;
    };

    plugins = [
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
    ];

    initContent = ''
      setopt prompt_subst
      zle_highlight=(bold)

      # Autosuggest highlight uses the terminal's bright-black slot (fg=8)
      # so it tracks the active palette (Catppuccin Mocha) instead of
      # being pinned to a hard-coded hex value.
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

      # zsh-syntax-highlighting palette overrides — Catppuccin Mocha hexes.
      typeset -gA ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[default]='fg=#cdd6f4'
      ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8'
      ZSH_HIGHLIGHT_STYLES[command]='fg=#a6e3a1'
      ZSH_HIGHLIGHT_STYLES[alias]='fg=#94e2d5'
      ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a6e3a1'
      ZSH_HIGHLIGHT_STYLES[function]='fg=#89b4fa'
      ZSH_HIGHLIGHT_STYLES[path]='fg=#cdd6f4'
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f9e2af'
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f9e2af'
      ZSH_HIGHLIGHT_STYLES[comment]='fg=#7f849c'

      # Aliases live in the repo so bash and zsh share the same set.
      for f in ${dotfilesDir}/configurations/aliases/*.sh; do
        [ -r "$f" ] && source "$f"
      done

      # FZF Catppuccin Mocha palette — sourced from a separate file so the
      # same colors apply to fzf-vim, fzf-tab, and anything else that reads
      # FZF_DEFAULT_OPTS.
      if [ -r ${dotfilesDir}/configurations/themes/fzf/catppuccin-mocha.sh ]; then
        source ${dotfilesDir}/configurations/themes/fzf/catppuccin-mocha.sh
      fi
    '';
  };
}
