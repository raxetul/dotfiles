---
nix-file: home/modules/packages/darwin.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# packages/darwin

## Purpose

macOS-only packages. Loaded by `home/darwin.nix`. Since macOS is
essentially always graphical, there's no server vs. desktop split
here — anything Mac-specific goes in this one file.

## My preferences (why it's configured this way)

- **No Ghostty here.** Nixpkgs' `ghostty` derivation excludes
  Darwin in `meta.platforms`. On macOS, Ghostty is installed via
  the Brewfile cask (`configurations/brew/Brewfile`); HM owns
  only the config file.
- **`colima` + `lima` for Docker.** `pkgs.docker` on Darwin is
  CLI-only — no daemon. Colima fronts a Lima VM that runs the
  Docker daemon. Run `colima start` once after install; the daemon
  persists across reboots if configured.
- **Everything GUI goes in the Brewfile**, not here. The split is:
  CLI / dev tooling → Nix; GUI apps → Homebrew casks. See
  `doc/packages-common.md` for the rationale (Phase 10 decision
  A2).

## Packages

- `colima` — Docker daemon front-end for macOS.
- `lima` — VM backend that colima drives.

## Related

- [configurations/brew/Brewfile](../configurations/brew/Brewfile)
  — GUI apps + `pinentry-mac`.
- [home/darwin.nix](../home/darwin.nix) — imports this file + the
  Brewfile activation step.
- [home/modules/packages/common.nix](../home/modules/packages/common.nix)
  — installs `docker` (CLI) on both platforms.
