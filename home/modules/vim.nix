{ pkgs, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      onedark-vim
      vim-sensible
    ];
    extraConfig = ''
      syntax on
      set number
      set relativenumber
      set expandtab
      set shiftwidth=4
      set tabstop=4
      set softtabstop=4
      colorscheme onedark
    '';
  };
}
