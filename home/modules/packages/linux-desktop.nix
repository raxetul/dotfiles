{ config, pkgs, ... }:

# Linux desktop / GUI stack. Only imported when profile = "desktop".
# Everything here assumes a graphical session.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  home.packages = with pkgs; [
    # Terminals
    alacritty
    ghostty
    wezterm

    # Wayland / sway stack
    sway
    swaybg
    swayidle
    swaylock
    waybar
    dmenu
    dunst
    polybar
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

  # Catppuccin Mocha notification daemon — edits to dunstrc take effect on
  # the next `dunst --reload` without a home-manager switch.
  xdg.configFile."dunst/dunstrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/dunst/dunstrc";
}
