{ config, ... }:

# Bash is not the daily-driver shell — it exists so non-interactive
# scripts and CI runs hit the same aliases zsh sees. Source the shared
# configurations/aliases/ folder so the two shells can never drift.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      for f in ${dotfilesDir}/configurations/aliases/*.sh; do
        [ -r "$f" ] && . "$f"
      done

      if [ -r ${dotfilesDir}/configurations/themes/fzf/catppuccin-mocha.sh ]; then
        . ${dotfilesDir}/configurations/themes/fzf/catppuccin-mocha.sh
      fi
    '';
  };
}
