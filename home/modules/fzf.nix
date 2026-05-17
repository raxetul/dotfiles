{ ... }:

# fzf — fuzzy finder. The Catppuccin Mocha palette is sourced from the
# shared theme file under configurations/themes/fzf/, which both zsh
# and bash load (see modules/zsh.nix + modules/bash.nix).
#
# ripgrep and fd are required for `--type f`/`--type d` defaults; both
# live in modules/packages/common.nix.
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
    fileWidgetCommand = "rg --files --hidden --follow --glob '!.git/*'";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
  };
}
