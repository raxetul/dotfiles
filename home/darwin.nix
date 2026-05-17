{ config, lib, ... }:

# macOS-only bucket. macOS is always graphical, so there is no server vs.
# desktop split here. The GUI/native bridge runs through Homebrew: the
# Brewfile under configurations/brew/ is replayed on every switch, so
# GUI apps stay in lockstep with the rest of the repo.
let
  dotfilesDir = "${config.home.homeDirectory}/gel-ort/dotfiles";
in
{
  imports = [
    ./modules/packages/darwin.nix
    ./modules/ghostty.nix
  ];

  # If Ghostty's macOS-native config exists as a regular file, leave it
  # alone but tell the user the XDG copy now wins. Ghostty itself reads
  # ~/.config/ghostty/config first when both are present.
  home.activation.ghosttyMacosNotice =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      macos_cfg="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
      if [ -f "$macos_cfg" ] && [ ! -L "$macos_cfg" ]; then
        echo "NOTICE: $macos_cfg is now superseded by ~/.config/ghostty/config."
        echo "        The repo will not touch the Library path; delete it manually if you only want the XDG copy."
      fi
    '';

  # `brew bundle` replays the Brewfile every switch. Idempotent: already-
  # installed casks are no-ops. `|| true` so a missing brew binary on
  # first run (before setup.sh installs Homebrew) doesn't kill the
  # whole activation pass.
  home.activation.brewBundle =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if command -v brew >/dev/null 2>&1; then
        echo "==> brew bundle (configurations/brew/Brewfile)"
        $DRY_RUN_CMD brew bundle \
          --file=${dotfilesDir}/configurations/brew/Brewfile \
          --no-lock || true
      else
        echo "NOTE: brew not on PATH; skipping Brewfile replay. Run setup.sh to install Homebrew."
      fi
    '';
}
