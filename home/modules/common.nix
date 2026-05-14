{ pkgs, ... }:

# Cross-platform packages — installed on every host (Linux or macOS,
# server or desktop). Anything platform-specific lives in linux.nix,
# linux-desktop.nix, or darwin.nix.
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
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
    nodejs_24

    # Containers — CLI on both OSes; on macOS the daemon comes from
    # colima/lima in darwin.nix.
    docker
    docker-compose

    # Misc CLI
    jq
    tldr
    coreutils
    zip
    unzip

    # Fonts (terminals on either OS pick them up).
    font-awesome
    jetbrains-mono
  ];
}
