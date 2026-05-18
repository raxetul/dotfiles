---
nix-file: home/modules/eza.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# eza

## Purpose

Modern `ls`. Catppuccin Mocha palette is exposed via the
`EZA_COLORS` env variable (eza reads it on every run). The YML
file under `configurations/themes/eza/` is the human-readable
reference; the actual value lives in the module so it's in the
session environment without a sourced shell script.

## My preferences (why it's configured this way)

- **`--group-directories-first`.** Dirs at the top of the listing,
  always. Default ordering interleaves dirs and files and forces
  visual scanning.
- **`--icons=auto`.** Glyphs from JetBrains Mono Nerd Font show
  up automatically in a Nerd Font-capable terminal (Ghostty), and
  are skipped in non-Nerd terminals (CI pipes, tmux pipe panes).
- **Palette in the module, not env-sourced.** Putting
  `EZA_COLORS` in `home.sessionVariables` means it's set by HM
  for every new shell without an extra source step. The YML in
  `configurations/themes/eza/` is documentation; if you change a
  color, update both.
- **Both zsh and bash integrations on.** Makes `ls` an alias to
  eza in both shells.

## Options enabled

- `programs.eza.enable = true`.
- `enableZshIntegration = true`, `enableBashIntegration = true`.
- `extraOptions = [ "--group-directories-first" "--icons=auto" ]`.
- `home.sessionVariables.EZA_COLORS` — Catppuccin Mocha codes
  for: regular files, dirs, exec, symlinks, broken links,
  pipes/sockets, block/char devices, dim entries.

## Related

- [configurations/themes/eza/catppuccin-mocha.yml](../configurations/themes/eza/catppuccin-mocha.yml)
  — human-readable mapping that mirrors `EZA_COLORS`.
- [doc/theming.md](theming.md).
