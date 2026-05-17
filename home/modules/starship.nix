{ config, ... }:

# Starship prompt. The toml lives under configurations/starship/ so edits
# take effect immediately (no rebuild needed). HM's `programs.starship`
# only writes its own ~/.config/starship.toml when `settings` is set, so
# leaving `settings` empty here lets the mkOutOfStoreSymlink below win.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  xdg.configFile."starship.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/starship/starship.toml";
}
