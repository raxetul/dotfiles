---
nix-file: home/modules/bat.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# bat

## Purpose

`cat` with syntax highlighting + a Catppuccin Mocha palette. bat is
also pulled into `man` and `less` so the entire pager stack picks
up the same colors.

## My preferences (why it's configured this way)

- **Theme file in the repo**, not pinned via nixpkgs hash. The
  `.tmTheme` lives under `configurations/themes/bat/` so a future
  nixpkgs bump doesn't require re-pinning.
- **One-time cache build via activation.** bat caches compiled
  themes under `$XDG_DATA_HOME/bat`; the cache must be rebuilt
  whenever the theme list changes. `home.activation.batCacheBuild`
  runs `bat cache --build` after `writeBoundary`. `|| true` so a
  missing bat on a half-installed host doesn't break the whole
  switch.
- **`MANPAGER` pipes through bat.** Every man page picks up the
  bat palette; the rest of the pager stack (`less`) gets
  `--use-color` flags so the colors survive.
- **Style includes line numbers + changes + header**, no grid.
  Grid is noise.

## Options enabled

- `programs.bat.enable = true`.
- `programs.bat.config`:
  - `theme = "Catppuccin-mocha"`.
  - `style = "numbers,changes,header"`.
- `xdg.configFile."bat/themes/Catppuccin-mocha.tmTheme"` —
  `mkOutOfStoreSymlink` to
  `configurations/themes/bat/Catppuccin-mocha.tmTheme`.
- `home.activation.batCacheBuild` — `bat cache --build` after
  writeBoundary.
- `home.sessionVariables`:
  - `MANPAGER = "sh -c 'col -bx | bat -l man -p'"`.
  - `MANROFFOPT = "-c"`.
  - `LESS = "-R --use-color -Dd+r$Du+b"`.

## Related

- [configurations/themes/bat/Catppuccin-mocha.tmTheme](../configurations/themes/bat/Catppuccin-mocha.tmTheme)
  — the palette file.
- [doc/theming.md](theming.md).
