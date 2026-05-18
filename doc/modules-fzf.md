---
nix-file: home/modules/fzf.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# fzf

## Purpose

Fuzzy finder. Wired into zsh and bash for Ctrl-T / Alt-C / Ctrl-R-ish
keybindings (Ctrl-R is owned by atuin). Catppuccin Mocha palette is
sourced from `configurations/themes/fzf/catppuccin-mocha.sh` in both
shells.

## My preferences (why it's configured this way)

- **`rg` for files, `fd` for dirs.** Both are in
  `packages/common.nix`. ripgrep walks .gitignore and respects
  hidden-by-default; fd is faster than `find` for dir trees.
- **Hidden files included.** `--hidden --follow` plus an explicit
  `--glob '!.git/*'` exclusion. The point of fzf is to find what's
  there, not what isn't.
- **Palette sourced from a shared shell script**, not declared
  inline. Same file is loaded by zsh, bash, fzf-vim, and fzf-tab,
  so they can't drift.

## Options enabled

- `programs.fzf.enable = true`.
- `enableZshIntegration = true`, `enableBashIntegration = true`.
- `defaultCommand = "rg --files --hidden --follow --glob '!.git/*'"`.
- `fileWidgetCommand = "rg --files --hidden --follow --glob '!.git/*'"`.
- `changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git"`.

## Related

- [configurations/themes/fzf/catppuccin-mocha.sh](../configurations/themes/fzf/catppuccin-mocha.sh)
  — palette sourced by zsh + bash.
- [home/modules/packages/common.nix](../home/modules/packages/common.nix)
  — provides `ripgrep` and `fd`.
- [doc/theming.md](theming.md).
