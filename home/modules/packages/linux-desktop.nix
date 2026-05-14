{ pkgs, ... }:

# Linux desktop / GUI stack. Only imported when profile = "desktop".
# Everything here assumes a graphical session.
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
}
