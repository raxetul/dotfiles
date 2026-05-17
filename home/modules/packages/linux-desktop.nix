{ config, pkgs, ... }:

# Linux desktop / GUI stack. Only imported when profile = "desktop".
# Everything here assumes a graphical session.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  home.packages = with pkgs; [
    # Terminal — Ghostty is the default. (Phase 8 dropped alacritty and
    # wezterm; Phase 9 trims the bar/launcher stack.)
    ghostty

    # Wayland / sway stack — Waybar replaces polybar; wofi replaces dmenu.
    sway
    swaybg
    swayidle
    swaylock
    waybar
    wofi
    dunst
    xdotool

    # Apps
    flameshot
    kdiff3
    nautilus
    obs-studio
    smplayer
    telegram-desktop
    discord
    veracrypt
    qtcreator

    # Recording / misc
    asciinema
  ];

  programs.waybar.enable = true;

  # Catppuccin Mocha notification daemon — edits to dunstrc take effect on
  # the next `dunst --reload` without a home-manager switch.
  xdg.configFile."dunst/dunstrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/dunst/dunstrc";

  # Waybar config + style — same edit-without-rebuild pattern.
  xdg.configFile."waybar/config.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/waybar/style.css";
}
