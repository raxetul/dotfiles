---
nix-file: home/modules/bash.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# bash

## Purpose

Bash isn't the daily-driver shell — it exists so non-interactive
scripts, CI runs, and the occasional `bash` invocation hit the same
aliases zsh sees. `bashrcExtra` sources the shared
`configurations/aliases/` folder and the fzf Catppuccin Mocha
palette so the two shells can never drift.

## My preferences (why it's configured this way)

- **No autosuggest / syntax-highlight in bash.** They exist for
  bash, but the daily driver is zsh; carrying duplicate config for
  interactive bash sessions is dead weight.
- **Aliases via folder, not declarative.** Putting alias rules in
  `programs.bash.shellAliases` would force a rebuild on every
  alias change. The shared folder loads at runtime — edit and
  re-source.

## Options enabled

- `programs.bash.enable = true`.
- `programs.bash.bashrcExtra`:
  - loops over `configurations/aliases/*.sh` and sources each.
  - sources `configurations/themes/fzf/catppuccin-mocha.sh`
    if present (palette env vars).

## Related

- [home/modules/zsh.nix](../home/modules/zsh.nix) — sources the
  same aliases folder.
- [configurations/aliases/](../configurations/aliases/) — the
  shared alias source of truth.
