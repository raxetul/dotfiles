{ config, pkgs, lib, ... }:

# Both Vim and Neovim, sharing a single rc (configurations/vim/vimrc).
# Neovim's ~/.config/nvim/init.vim is a tiny stub that sources ~/.vimrc and
# adds Neovim-only extras. Plugins are managed declaratively on both editors;
# the same set works on both because everything below is plain vimscript.
#
# vimAlias/viAlias are OFF so `vim` stays Vim and `nvim` stays Neovim.
# defaultEditor=true on Neovim sets EDITOR=nvim — keep home/default.nix from
# declaring EDITOR or HM will complain about the duplicate.

let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";

  sharedPlugins = with pkgs.vimPlugins; [
    # file tree
    nerdtree
    vim-nerdtree-syntax-highlight
    vim-devicons

    # fuzzy
    fzf-vim

    # git
    vim-fugitive
    vim-gitgutter
    vim-rhubarb

    # editing
    vim-surround
    vim-commentary
    vim-repeat
    auto-pairs
    vim-multiple-cursors
    tabular
    vim-easymotion

    # UI
    vim-airline
    vim-airline-themes
    catppuccin-vim
    indentLine

    # syntax + lint
    vim-polyglot
    ale

    # snippets
    ultisnips
    vim-snippets

    # buffer mgmt
    bufexplorer

    # QoL
    vim-sensible
  ];

  mkLink = path:
    config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
in
{
  programs.vim = {
    enable = true;
    plugins = sharedPlugins;
  };

  programs.neovim = {
    enable = true;
    vimAlias = false;
    viAlias = false;
    defaultEditor = true;
    plugins = sharedPlugins;
  };

  home.file = {
    ".vimrc".source = mkLink "configurations/vim/vimrc";
    ".vim/ftplugin/nix.vim".source    = mkLink "configurations/vim/ftplugin/nix.vim";
    ".vim/ftplugin/go.vim".source     = mkLink "configurations/vim/ftplugin/go.vim";
    ".vim/ftplugin/yaml.vim".source   = mkLink "configurations/vim/ftplugin/yaml.vim";
    ".vim/ftplugin/python.vim".source = mkLink "configurations/vim/ftplugin/python.vim";
  };

  xdg.configFile."nvim/init.vim".source = mkLink "configurations/nvim/init.vim";
}
