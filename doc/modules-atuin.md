---
nix-file: home/modules/atuin.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# atuin

## Purpose

Fuzzy, encrypted shell history. Replaces the old `zsh-histdb`
plugin: same Ctrl-R UX but with proper fuzzy search and an
encrypted SQLite store. Sync is **off by default** — turn it on
by hand in `configurations/atuin/config.toml` if you want
cross-host history.

## My preferences (why it's configured this way)

- **Same Ctrl-R, not a new binding.** Migration cost from histdb
  is zero. Ctrl-R works, Up still scrolls (in prefix-search mode),
  the rest is invisible.
- **Sync disabled by default.** The encryption is solid, but
  syncing shell history is a meaningful trust decision; opt-in,
  not default. Edit `auto_sync = true` in the toml if you want it
  on a given host.
- **Filter rules live in the toml**, not in a `zshaddhistory`
  function. The old setup leaked `HISTORY_IGNORE` regex logic into
  zsh.nix; atuin keeps it data-side.
- **Both zsh and bash integrations on.** Same store, both shells.

## Options enabled

- `programs.atuin.enable = true`.
- `enableZshIntegration = true`, `enableBashIntegration = true`.
- `xdg.configFile."atuin/config.toml"` — `mkOutOfStoreSymlink` to
  `configurations/atuin/config.toml`.

## Related

- [home/modules/zsh.nix](../home/modules/zsh.nix) — Ctrl-R is
  rebound by atuin's zsh integration.
- [configurations/atuin/config.toml](../configurations/atuin/config.toml)
  — filter rules + sync settings.
