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

      # Aliases live in the repo so bash and zsh share the same set.
      for f in ${dotfilesDir}/configurations/aliases/*.sh; do
        [ -r "$f" ] && source "$f"
      done
    '';
  };
}
