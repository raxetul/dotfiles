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
    bind.dnsutils   # dig, nslookup, host (client tools only — not the BIND server)
    wget
    curl

    # Build toolchain
    clang-tools # includes clang-format
    llvm
    go
    rustup
    nodejs_24
    sqlite-interactive  # provides the `sqlite3` CLI, with readline support

    # Containers — CLI on both OSes; on macOS the daemon comes from
    # colima/lima in darwin.nix.
    docker
    docker-compose

    # Misc CLI
    jq
    tldr
    coreutils-full  # GNU coreutils incl. arch, realpath, prefixed variants
    zip
    unzip

    # Search + view CLI — used by both fzf.vim (:Rg) and day-to-day shell.
    ripgrep
    fd
    bat

    # Commit hooks + linters — driven by configurations/lefthook.yml.
    lefthook
    nixpkgs-fmt
    shellcheck

    # Fonts (terminals on either OS pick them up).
    font-awesome
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
