{ pkgs, lib, ... }:

{
  imports = [
    ./modules/packages.nix
    ./modules/zsh.nix
    ./modules/starship.nix
    ./modules/git.nix
    ./modules/vim.nix
    ./modules/tmux.nix
    ./modules/fzf.nix
    ./modules/zoxide.nix
  ] ++ lib.optional pkgs.stdenv.isDarwin ./modules/darwin.nix
    ++ lib.optional pkgs.stdenv.isLinux ./modules/linux.nix;

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "tr_TR.UTF-8";
    LC_COLLATE = "C";
  };
}
