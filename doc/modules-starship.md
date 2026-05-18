---
nix-file: home/modules/starship.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# starship

## Purpose

Shell prompt. The module is intentionally thin — it just enables
Starship in zsh + bash and symlinks
`configurations/starship/starship.toml` into `~/.config/`. The
prompt configuration lives in the toml so edits take effect on the
next prompt without a rebuild.

## My preferences (why it's configured this way)

- **Externalize the toml.** HM's `programs.starship.settings` would
  generate a Nix-store-owned file and force a rebuild on every
  segment tweak. The symlink layer wins here.
- **No `settings = …` in the module.** If `settings` is set, HM
  writes its own `starship.toml` that wins over the symlink, so
  leave it empty.
- **Catppuccin Mocha only.** Phase 4 dropped the other three
  flavours; one palette to debug.
- **Transient prompt on.** Old prompts collapse to a single `❯` in
  scrollback so scrolling back through a long session stays
  readable.

## Options enabled

- `programs.starship.enable = true`.
- `enableZshIntegration = true`, `enableBashIntegration = true`.
- `xdg.configFile."starship.toml"` — `mkOutOfStoreSymlink` to
  `configurations/starship/starship.toml`.

## Related

- [configurations/starship/starship.toml](../configurations/starship/starship.toml)
  — the prompt configuration.
- [doc/theming.md](theming.md) — Catppuccin Mocha palette table.
