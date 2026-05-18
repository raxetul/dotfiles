---
nix-file: home/modules/ghostty.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# ghostty

## Purpose

Symlinks `~/.config/ghostty/config` into this repo. The Ghostty
binary itself is installed elsewhere — via Nix on Linux desktop,
via Homebrew cask on macOS — because nixpkgs' Ghostty derivation
excludes Darwin.

## My preferences (why it's configured this way)

- **XDG path only.** Ghostty reads `$XDG_CONFIG_HOME/ghostty/config`
  on every platform, including macOS. The legacy
  `~/Library/Application Support/com.mitchellh.ghostty/config`
  works too, but using two paths is invitation to drift. The
  `home/darwin.nix` activation step warns when a regular file
  exists at the Library path but never deletes it.
- **Module is safe to import on any host.** If Ghostty isn't
  installed the symlink is harmless. Used on Linux desktop +
  macOS; skipped on Linux server.

## Options enabled

- `xdg.configFile."ghostty/config"` —
  `mkOutOfStoreSymlink` to
  `configurations/ghostty/config`.

## Related

- [configurations/ghostty/config](../configurations/ghostty/config)
  — terminal settings: `theme = catppuccin-mocha`, JetBrains Mono
  Nerd Font, padding, cursor style, `macos-titlebar-style = tabs`.
- [home/darwin.nix](../home/darwin.nix) — Library-path notice
  activation step.
- [home/modules/packages/linux-desktop.nix](../home/modules/packages/linux-desktop.nix)
  — installs the Ghostty binary on Linux.
- [configurations/brew/Brewfile](../configurations/brew/Brewfile)
  — installs the Ghostty cask on macOS.
