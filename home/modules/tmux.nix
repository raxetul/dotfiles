{ config, pkgs, ... }:

# Tmux — plugin set, terminal, key mode, and prefix are declared here so
# Home Manager can wire the plugin store paths into the generated
# ~/.config/tmux/tmux.conf. Everything else (prefix bindings, splits,
# pane navigation, status-bar tuning) lives in configurations/tmux/tmux.conf
# and is sourced at the end via extraConfig.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    historyLimit = 50000;
    escapeTime = 10;
    terminal = "tmux-256color";
    focusEvents = true;

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      vim-tmux-navigator
      {
        # Per-plugin extraConfig runs BEFORE the plugin is sourced — the
        # flavour and layout selectors must be set before catppuccin loads.
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
          source-file ${dotfilesDir}/configurations/themes/tmux/catppuccin-mocha.conf
        '';
      }
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    extraConfig = ''
      source-file ${dotfilesDir}/configurations/tmux/tmux.conf
    '';
  };
}
