---
nix-file: home/modules/packages/common.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# packages/common

## Purpose

Cross-platform packages — installed on every host (Linux or macOS,
server or desktop). Anything OS-specific lives in
`packages/linux.nix`, `packages/linux-desktop.nix`,
`packages/linux-server.nix`, or `packages/darwin.nix`.

## My preferences (why it's configured this way)

- **`fonts.fontconfig.enable = true` at module level.** Fonts
  installed via `home.packages` (JetBrains Mono, Nerd Font variant,
  font-awesome) need the fontconfig DB updated to be discoverable;
  this is the HM toggle that wires that up.
- **`bind.dnsutils`, not the full BIND server.** I want
  `dig`/`nslookup`/`host`; I don't want a DNS server.
- **`sqlite-interactive`, not `sqlite`.** The interactive variant
  ships with readline support — line editing in the REPL.
- **`coreutils-full`.** GNU coreutils on macOS where the system
  ones are BSD; prefixed variants (`gdate`, `gsed`, etc.) coexist.
- **`docker` + `docker-compose` everywhere.** The CLI is fine on
  both platforms; the macOS *daemon* is colima/lima in
  `packages/darwin.nix`.
- **`ripgrep` + `fd` + `bat`.** Required by fzf-vim's `:Rg`,
  zoxide-like dir search, and the bat module's `MANPAGER`.
- **`lefthook` + `nixpkgs-fmt` + `shellcheck`.** Linters declared
  in `configurations/lefthook.yml` need to actually be on PATH.

## Packages

### Networking / sysadmin
- `arp-scan`, `bandwhich`, `bind.dnsutils`, `wget`, `curl`.

### Build toolchain
- `clang-tools` (incl. clang-format), `llvm`.
- `go`, `rustup`, `nodejs_24`.
- `sqlite-interactive`.

### Containers
- `docker`, `docker-compose`. Daemon via colima/lima on macOS
  (see `packages/darwin.nix`).

### Misc CLI
- `jq`, `tldr`, `coreutils-full`, `zip`, `unzip`.

### Search + view
- `ripgrep`, `fd`, `bat`.

### Commit hooks + linters
- `lefthook`, `nixpkgs-fmt`, `shellcheck`.

### Fonts (with `fonts.fontconfig.enable = true`)
- `font-awesome`, `jetbrains-mono`,
  `nerd-fonts.jetbrains-mono`.

## Related

- [home/modules/packages/darwin.nix](../home/modules/packages/darwin.nix).
- [home/modules/packages/linux.nix](../home/modules/packages/linux.nix).
- [home/modules/packages/linux-server.nix](../home/modules/packages/linux-server.nix).
- [home/modules/packages/linux-desktop.nix](../home/modules/packages/linux-desktop.nix).
- [configurations/lefthook.yml](../configurations/lefthook.yml) —
  consumes `nixpkgs-fmt` + `shellcheck`.
