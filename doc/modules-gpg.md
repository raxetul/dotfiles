---
nix-file: home/modules/gpg.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# gpg

## Purpose

Declarative GPG agent + profile so any key generated later inherits
a modern crypto setup (SHA-512, AES-256, long key-IDs). Runtime key
material is created by `scripts/gpg-setup.sh` and lives in
`~/.gnupg/` — that's deliberately outside the repo.

## My preferences (why it's configured this way)

- **Declarative profile, runtime key material.** Keys are
  per-host, secret, and shouldn't live in a flake. The module
  fixes the *crypto profile* so newly generated keys can never
  be born weak; the wizard does the generation itself.
- **OS-aware pinentry, inline.** `gpg-agent.conf` is small enough
  that templating it in the module beats symlinking. On macOS the
  module appends `pinentry-program /opt/homebrew/bin/pinentry-mac`
  (formula declared in `configurations/brew/Brewfile`); on Linux
  the agent picks up `pinentry-curses` from PATH (installed via
  `home.packages` below).
- **Long pinentry cache TTL (24h).** Commits are not a
  passphrase-prompt ritual; the cache is reset on logout / reboot
  anyway.
- **OS detection via `system` arg.** Per the locked roadmap
  convention: derive `isDarwin` / `isLinux` from
  `lib.hasSuffix "darwin" system` — never from
  `pkgs.stdenv.isDarwin`.
- **Signing isn't declared in git.nix.** Decoupling means a fresh
  host that hasn't run the wizard still commits cleanly
  (unsigned). See [modules-git.md](modules-git.md) for the
  include-based wiring.

## Options enabled

- `programs.gpg.enable = true` with hardened `settings`:
  - `no-greeting`, `keyid-format = "long"`,
    `with-fingerprint = true`, `use-agent = true`.
  - `personal-cipher-preferences = "AES256 AES192 AES"`.
  - `personal-digest-preferences = "SHA512 SHA384 SHA256"`.
  - `personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed"`.
  - `cert-digest-algo = "SHA512"`, `s2k-digest-algo = "SHA512"`,
    `s2k-cipher-algo = "AES256"`, `charset = "utf-8"`.
- `home.file.".gnupg/gpg-agent.conf".text`:
  - `default-cache-ttl 86400`, `max-cache-ttl 86400`,
    `allow-loopback-pinentry`.
  - macOS only: `pinentry-program /opt/homebrew/bin/pinentry-mac`.
- `home.packages = lib.optional isLinux pkgs.pinentry-curses`.

## Related

- [scripts/gpg-setup.sh](../scripts/gpg-setup.sh) — generates the
  key + writes `~/.config/git/signing.gitconfig`.
- [home/modules/git.nix](../home/modules/git.nix) — includes the
  wizard-written signing file.
- [configurations/brew/Brewfile](../configurations/brew/Brewfile)
  — `brew "pinentry-mac"` on macOS.
