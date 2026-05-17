{ config, ... }:

# atuin — fuzzy, encrypted shell history. Replaces the old zsh-histdb
# plugin: same Ctrl-R UX but with proper search and an encrypted SQLite
# store. Sync is off by default (see configurations/atuin/config.toml);
# turn it on by hand if you want cross-host history.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # Externalize config so edits take effect without a home-manager switch.
  xdg.configFile."atuin/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/atuin/config.toml";
}
