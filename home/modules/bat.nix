{ config, lib, ... }:

# bat — `cat` with syntax highlighting. The Catppuccin Mocha theme file
# lives under configurations/themes/bat/ so it survives a future bump of
# nixpkgs without needing to re-pin a hash. bat itself requires a one-time
# `bat cache --build` after the theme file appears, which we drive via an
# activation script.
#
# bat is also wired into man / less so the entire pager stack picks up
# the same palette.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin-mocha";
      style = "numbers,changes,header";
    };
  };

  xdg.configFile."bat/themes/Catppuccin-mocha.tmTheme".source =
    config.lib.file.mkOutOfStoreSymlink
      "${dotfilesDir}/configurations/themes/bat/Catppuccin-mocha.tmTheme";

  # bat caches compiled themes in $XDG_DATA_HOME/bat — must be rebuilt
  # whenever the theme list changes. `|| true` so the activation script
  # doesn't fail catastrophically on a host where bat is missing.
  home.activation.batCacheBuild =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v bat >/dev/null 2>&1; then
        $DRY_RUN_CMD bat cache --build >/dev/null 2>&1 || true
      fi
    '';

  # man / less use the same bat palette so the pager stack is consistent.
  home.sessionVariables = {
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
    LESS = "-R --use-color -Dd+r$Du+b";
  };
}
