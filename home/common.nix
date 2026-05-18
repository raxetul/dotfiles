{ ... }:

# Cross-platform user environment — imported on every host. Everything in
# here must work on both Linux and macOS without touching the OS-specific
# package buckets (those live in ./linux.nix and ./darwin.nix).
{
  imports = [
    ./modules/packages/common.nix
    ./modules/scripts.nix
    ./modules/zsh.nix
    ./modules/bash.nix
    ./modules/atuin.nix
    ./modules/starship.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/editor.nix
    ./modules/tmux.nix
    ./modules/fzf.nix
    ./modules/bat.nix
    ./modules/eza.nix
    ./modules/zoxide.nix
  ];

  programs.home-manager.enable = true;

  # EDITOR is set by programs.neovim.defaultEditor = true (see modules/editor.nix);
  # don't redeclare it here or Home Manager errors on the duplicate.
  home.sessionVariables = {
    LANG = "tr_TR.UTF-8";
    LC_COLLATE = "C";
  };
}
