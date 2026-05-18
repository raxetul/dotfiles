---
nix-file: home/modules/zoxide.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# zoxide

## Purpose

`cd` replacement with frecency-based jumps. `z foo` lands in the
directory I've visited most that matches "foo"; `zi foo` does the
fuzzy-interactive variant.

## My preferences (why it's configured this way)

- **zsh integration only.** Bash is non-interactive in this repo;
  bumping into `z` from a script would be a surprise. Daily-driver
  shell only.
- **No extra config.** Zoxide's defaults are good; opinions live in
  how often I actually use `z` vs `cd`.

## Options enabled

- `programs.zoxide.enable = true`.
- `enableZshIntegration = true`.

## Related

- [home/modules/zsh.nix](../home/modules/zsh.nix) — the shell that
  picks up the `z`/`zi` aliases.
