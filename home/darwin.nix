{ ... }:

# macOS-only bucket. macOS is always graphical, so there is no server vs.
# desktop split here — the GUI/native bridge (Homebrew casks) is layered
# in via later phases (see ROADMAP.md, Phase 10).
{
  imports = [
    ./modules/packages/darwin.nix
  ];
}
