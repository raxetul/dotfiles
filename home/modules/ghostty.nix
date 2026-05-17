{ config, ... }:

# Ghostty config — symlinks ~/.config/ghostty/config into this repo. The
# package install is platform-specific:
#   * Linux desktop: home/modules/packages/linux-desktop.nix (Nix).
#   * macOS:         configurations/brew/Brewfile (Phase 10) — nixpkgs'
#                    ghostty derivation excludes Darwin.
# This module only handles the config file, so it's safe to import on any
# host; if Ghostty isn't installed the symlink is harmless.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  xdg.configFile."ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/configurations/ghostty/config";
}
