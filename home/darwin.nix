{ config, lib, ... }:

# macOS-only bucket. macOS is always graphical, so there is no server vs.
# desktop split here — the GUI/native bridge (Homebrew casks) is layered
# in via later phases (see ROADMAP.md, Phase 10).
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
}
