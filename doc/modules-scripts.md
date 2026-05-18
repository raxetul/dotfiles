---
nix-file: home/modules/scripts.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# scripts

## Purpose

Installs every file under `scripts/` into `~/.scripts/<name>` and
adds `~/.scripts` to `PATH`. Drop a new file in the repo's
`scripts/` folder and re-run `setup.sh` (or `scripts/update.sh`)
— Home Manager picks it up automatically.

## My preferences (why it's configured this way)

- **No per-script declaration.** `builtins.readDir` walks the
  folder; adding a new script doesn't touch `scripts.nix`.
- **Hidden files and `README*` skipped.** Lets the folder have
  `.gitignore`, `README.md`, etc. without polluting `~/.scripts`.
- **Flat folder.** No recursion into subdirectories — keeps the
  rule "one filename = one PATH entry" easy to reason about.
- **`executable = true` on every entry.** Forgetting `chmod +x`
  on a fresh script is a common foot-gun; HM sets it for us.
- **`home.sessionPath` over PATH munging in zshrc.** HM owns
  PATH composition; manual injection in `initContent` would have
  to run before the autosuggest/syntax-hl init.

## Options enabled

- `home.file = { ".scripts/<name>" = { source; executable=true } }`
  for every regular file in `scripts/` (excluding dotfiles +
  `README*`).
- `home.sessionPath = [ "$HOME/.scripts" ]`.

## Related

- [scripts/](../scripts/) — the source of truth.
- [scripts/update.sh](../scripts/update.sh) — installed at
  `~/.scripts/update.sh`.
- [scripts/gpg-setup.sh](../scripts/gpg-setup.sh) — installed at
  `~/.scripts/gpg-setup.sh`.
