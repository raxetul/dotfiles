---
nix-file: home/modules/packages/linux.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# packages/linux

## Purpose

Linux baseline — imported on every Linux host, regardless of
profile. Server-specific tools live in `packages/linux-server.nix`;
GUI / desktop bits live in `packages/linux-desktop.nix`. This
module's only job today is one session-variable override.

## My preferences (why it's configured this way)

- **`XDG_DATA_DIRS` extension.** Prepending
  `$HOME/.nix-profile/share` lets desktop applications discover
  `.desktop` files, MIME info, and icons installed by Nix.
  Without this, GNOME / KDE / Sway launchers wouldn't see
  HM-installed apps.
- **Module is intentionally tiny.** Anything heavier (qemu,
  bridge-utils, etc.) belongs in the server or desktop bucket so
  hosts with the opposite profile don't pull them in.

## Options enabled

- `home.sessionVariables.XDG_DATA_DIRS = "$HOME/.nix-profile/share:$XDG_DATA_DIRS"`.

## Related

- [home/modules/packages/linux-server.nix](../home/modules/packages/linux-server.nix).
- [home/modules/packages/linux-desktop.nix](../home/modules/packages/linux-desktop.nix).
- [home/linux.nix](../home/linux.nix) — dispatcher that imports
  this baseline plus the profile-specific buckets.
