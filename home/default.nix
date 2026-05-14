{ lib, system, profile ? "server", ... }:

# Four-bucket package layout:
#   common.nix         — every host (CLI + dev toolchain + fonts)
#   linux.nix          — every Linux host (CLI + system tools)
#   linux-desktop.nix  — Linux hosts when profile == "desktop"
#   darwin.nix         — every macOS host (CLI + GUI; macOS is always graphical)
#
# The `profile` arg only gates the Linux desktop bucket and is wired up
# from setup.sh (--desktop flag).
assert lib.elem profile [ "server" "desktop" ];

{
  imports = [

    ./modules/common.nix
    ./modules/scripts.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/tmux.nix
    ./modules/fzf.nix
    ./modules/zoxide.nix
  ] ++ lib.optional (lib.hasSuffix "darwin" system) ./modules/packages/darwin.nix
    ++ lib.optional (lib.hasSuffix "linux"  system) ./modules/packages/linux.nix
    ++ lib.optional (profile == "desktop" && lib.hasSuffix "linux" system) ./modules/packages/linux-desktop.nix;

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "tr_TR.UTF-8";
    LC_COLLATE = "C";
  };
}
