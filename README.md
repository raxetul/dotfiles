# dotfiles

Portable user environment for macOS and Linux. One declarative
[Home Manager](https://github.com/nix-community/home-manager)
configuration under `home/` plus a runtime-editable
`configurations/` layer for everything that benefits from being
tweaked without a rebuild. macOS uses Homebrew for GUI apps; Linux
uses its native package manager for the same role. Catppuccin
Mocha across the terminal stack.

## Quick start

```sh
./setup.sh             # Linux server profile, or macOS
./setup.sh --desktop   # Linux desktop: also installs sway + GUI apps
./setup.sh --update    # bumps flake.lock (nixpkgs, home-manager)
```

What it does:

1. Installs Nix in multi-user (daemon) mode if missing.
2. Enables flakes.
3. On macOS, installs Homebrew if missing.
4. Runs `home-manager switch` for the current user.
5. Switches the login shell to zsh.
6. On Linux, installs distro-native packages from
   `configurations/native/<pkgmgr>.list`.
7. Installs lefthook git hooks for this repo.

Re-running is safe — every step is idempotent. Use
`scripts/update.sh` to refresh packages + configurations on an
already-set-up host.

## Layout

| Path                            | Purpose                                                                          |
| ------------------------------- | -------------------------------------------------------------------------------- |
| `flake.nix`                     | Builds `homeConfigurations.default` for the current `$USER` / system / profile.  |
| `home/default.nix`              | Pure dispatcher: imports common + linux/darwin by string-suffixing `system`.     |
| `home/common.nix`               | 14 modules imported on every host (zsh, bash, git, gpg, editor, tmux, …).        |
| `home/{linux,darwin}.nix`       | Per-OS imports; Linux further splits into server / desktop by `profile`.         |
| `home/modules/*.nix`            | One file per concern (atuin, bat, eza, fzf, ghostty, git, gpg, …).               |
| `home/modules/packages/*.nix`   | Package buckets: `common`, `darwin`, `linux`, `linux-server`, `linux-desktop`.   |
| `configurations/<app>/`         | Live-editable config files, symlinked into the live tree (no rebuild needed).    |
| `configurations/brew/Brewfile`  | macOS GUI bridge — replayed every `home-manager switch`.                         |
| `configurations/native/*.list`  | Linux distro-native package lists (`apt`, `pacman`, `dnf`).                      |
| `scripts/`                      | Installed into `~/.scripts/` and added to `PATH` (see `modules/scripts.nix`).    |
| `setup.sh`                      | Bootstrap; idempotent.                                                           |
| `scripts/update.sh`             | Refresh packages + configurations on an already-set-up host.                     |
| `scripts/gpg-setup.sh`          | Generate a signing key + wire it into git (one-shot, idempotent).                |
| `.claude/`                      | Repo-local agentic config: slash commands, skills, hooks, permissions.           |
| `CLAUDE.md`                     | Five ground rules for any agent working in this repo.                            |
| `doc/`                          | One doc per significant file — see the index in `doc/README.md`.                 |

## Documentation

Full index at [doc/README.md](doc/README.md). Highlights:

- [doc/flake.md](doc/flake.md) — inputs + impure binding.
- [doc/home-default.md](doc/home-default.md) — dispatcher view.
- [doc/modules-git.md](doc/modules-git.md) — gitdir-based
  identity selection.
- [doc/modules-editor.md](doc/modules-editor.md) — vim + neovim
  shared-rc flow.
- [doc/modules-zsh.md](doc/modules-zsh.md) — startup sequence.
- [doc/modules-gpg.md](doc/modules-gpg.md) — agent profile +
  wizard split.
- [doc/theming.md](doc/theming.md) — Catppuccin Mocha palette +
  per-app mapping.

## How the profile flag works

`setup.sh` exports `DOTFILES_PROFILE`, `flake.nix` reads it at
impure eval time, `home/linux.nix` asserts the value:

- No flag (or `--server`) → `DOTFILES_PROFILE=server`, Linux
  desktop bucket skipped.
- `--desktop` → `DOTFILES_PROFILE=desktop`, Linux desktop bucket
  imported.
- On macOS the flag is accepted but irrelevant — `darwin.nix` is
  always imported.

## Daemons & root-required setup on non-NixOS Linux

Home Manager installs the **binaries** for `docker`, `libvirt`,
`qemu`, etc., but their **daemons** and group memberships still
need root:

```sh
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
```

On NixOS, put this in `configuration.nix`. Sway/Wayland sessions
also need a working seat/login stack (`greetd` / `gdm` / …) — that
lives outside the user profile.

## Re-applying after editing `home/`

```sh
./setup.sh             # or --desktop on Linux
```

Each run uses a per-day, per-run backup suffix
(`backup-YYYY-MM-DD---N`), so home-manager never errors on
existing backups.

If you'd rather drive home-manager directly:

```sh
DOTFILES_PROFILE=desktop nix run --impure home-manager/master -- \
    switch --impure --flake .#default -b "$(date +%Y-%m-%d)---manual"
```

## Adding packages

- Cross-platform CLI tool → `home/modules/packages/common.nix`.
- Linux CLI / system tool → `home/modules/packages/linux.nix` (baseline)
  or `packages/linux-server.nix` (server-only).
- Linux GUI app → `home/modules/packages/linux-desktop.nix`.
- macOS CLI → `home/modules/packages/darwin.nix`.
- macOS GUI app → `configurations/brew/Brewfile` (cask).

## GPG signing

Optional and opt-in. Run once per host:

```sh
~/.scripts/gpg-setup.sh
```

The wizard generates an ed25519 + cv25519 keypair tied to your git
email, writes `~/.config/git/signing.gitconfig`, and prints the
public key to paste into GitHub. See
[doc/modules-gpg.md](doc/modules-gpg.md) for details.
