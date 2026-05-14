{ pkgs, lib, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # ---- Cross-platform CLI ---------------------------------------------
    # Networking / sysadmin
    arp-scan
    bandwhich
    bind        # dig, nslookup, host
    wget
    curl

    # Build toolchain
    clang-tools # includes clang-format
    llvm
    go
    rustup
    nodejs_22

    # Containers — CLI works on both OSes; on macOS see darwin.nix for
    # the daemon (colima).
    docker
    docker-compose

    # Misc CLI
    jq
    tldr
    coreutils
    zip
    unzip

    # Fonts (used by sway / waybar / terminals)
    font-awesome
    jetbrains-mono
  ] ++ lib.optionals stdenv.isLinux [
    # ---- Linux-only system tools ----------------------------------------
    # Binaries only — `dockerd`, `libvirtd`, group membership still need
    # root via your distro on non-NixOS hosts.
    qemu
    libvirt
    bridge-utils
    hdparm
    dstat

    # ---- Linux desktop / GUI --------------------------------------------
    # Terminals
    alacritty
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
    qtile        # X11 tiling WM (alt to sway)
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
