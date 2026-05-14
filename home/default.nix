{ lib, system, profile ? "server", ... }:

# Five-bucket package layout:
#   common.nix         — every host (CLI + dev toolchain + fonts)
#   linux.nix          — every Linux host (env + baseline shared by both profiles)
#   linux-server.nix   — Linux hosts when profile == "server"  (qemu, libvirt, …)
#   linux-desktop.nix  — Linux hosts when profile == "desktop" (sway, GUI apps, …)
#   darwin.nix         — every macOS host (CLI + GUI; macOS is always graphical)
#
# The `profile` arg is wired up from setup.sh (--desktop flag).
assert lib.elem profile [ "server" "desktop" ];

{
  imports = [

    ./modules/packages/common.nix
    ./modules/scripts.nix
    ./modules/zsh/zsh.nix
    ./modules/zsh/starship.nix
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/tmux.nix
    ./modules/fzf.nix
    ./modules/zoxide.nix
  ] ++ lib.optional (lib.hasSuffix "darwin" system) ./modules/packages/darwin.nix
    ++ lib.optional (lib.hasSuffix "linux"  system) ./modules/packages/linux.nix
    ++ lib.optional (profile == "server"  && lib.hasSuffix "linux" system) ./modules/packages/linux-server.nix
    ++ lib.optional (profile == "desktop" && lib.hasSuffix "linux" system) ./modules/packages/linux-desktop.nix;

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "tr_TR.UTF-8";
    LC_COLLATE = "C";
  };
}
