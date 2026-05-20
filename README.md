# dotfiles

Portable user environment for macOS and Linux. Native package
managers do the install (brew on macOS; apt / pacman / dnf on Linux),
a runtime-editable `configurations/` layer holds every config file,
and `scripts/symlinks.sh` wires the two together. Catppuccin Mocha
across the terminal stack.

## Quick start

```sh
./setup.sh             # Linux server profile, or macOS
./setup.sh --desktop   # Linux desktop: also installs sway + GUI apps
./setup.sh --update    # upgrade already-installed packages
```

What it does:

1. On macOS, installs Homebrew if missing.
2. Installs packages from `packages/Brewfile` (macOS) or
   `packages/<pkgmgr>.list` plus optional `-desktop.list` (Linux).
3. Layers Linux fallbacks: AUR (Arch family) or Snap
   (Debian/Fedora).
4. Bootstraps user-scope plugin managers: vim-plug, TPM,
   zsh-you-should-use.
5. Plants symlinks from `configurations/` into `$HOME` via
   `scripts/symlinks.sh`.
6. Switches the login shell to zsh.
7. Installs lefthook git hooks for this repo.

Re-running is safe — every step is idempotent. Use
`scripts/update.sh` to refresh packages + configurations on an
already-set-up host.

## Layout

| Path                            | Purpose                                                                          |
| ------------------------------- | -------------------------------------------------------------------------------- |
| `configurations/<app>/`         | Live-editable config files, symlinked into `$HOME` by `scripts/symlinks.sh`.     |
| `packages/Brewfile`             | macOS install list (formulas + casks); replayed every `setup.sh` run.            |
| `packages/{apt,pacman,dnf}.list`            | Linux baseline package lists per distro family.                      |
| `packages/{apt,pacman,dnf}-desktop.list`    | Linux desktop GUI add-ons (installed only with `--desktop`).         |
| `packages/aur.list`             | Arch User Repository fallbacks (Arch-family only).                               |
| `packages/snap.list`            | Snap fallbacks for Debian/Fedora packages with no native entry.                  |
| `scripts/`                      | Installed into `~/.scripts/` and added to `PATH`.                                |
| `scripts/symlinks.sh`           | `install` / `uninstall` / `list` the symlinks the repo plants under `$HOME`.     |
| `setup.sh`                      | Bootstrap; idempotent.                                                           |
| `scripts/update.sh`             | Refresh packages + configurations on an already-set-up host.                     |
| `scripts/gpg-setup.sh`          | Generate a signing key + wire it into git (one-shot, idempotent).                |
| `scripts/nix-uninstall.sh`      | Remove a legacy multi-user Nix install (kept around for hosts still on v2).      |
| `.claude/`                      | Repo-local agentic config: slash commands, skills, hooks, permissions.           |
| `CLAUDE.md`                     | Ground rules for any agent working in this repo.                                 |
| `doc/`                          | One doc per significant file — see the index in `doc/README.md`.                 |

## Documentation

Full index at [doc/README.md](doc/README.md). Highlights:

- [doc/packages-native.md](doc/packages-native.md) — every package
  this repo installs, per OS, with fallback notes.
- [doc/theming.md](doc/theming.md) — Catppuccin Mocha palette +
  per-app mapping.

## How the profile flag works

`setup.sh --desktop` exports `DOTFILES_DESKTOP=1`:

- On Linux: the matching `<pkgmgr>-desktop.list` is installed
  alongside the baseline, and Wayland-stack symlinks (waybar,
  dunst) are planted.
- On macOS: the flag is accepted but irrelevant — `Brewfile`
  already carries every GUI cask.

## Daemons & root-required setup on Linux

The package managers install **binaries** for `docker`, `libvirt`,
`qemu`, etc., but their **daemons** and group memberships still
need root:

```sh
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
```

Sway/Wayland sessions also need a working seat/login stack
(`greetd` / `gdm` / …) — that lives outside the user profile.

## Re-applying after editing `configurations/`

```sh
./setup.sh             # or --desktop on Linux
```

Edits in `configurations/` take effect immediately — the live tree
points at the repo via `scripts/symlinks.sh`, so no re-run is
needed unless you've changed which files exist. Re-run `setup.sh`
when you add a new mapping or want to bring a fresh host up to date.

## Uninstall

```sh
./scripts/symlinks.sh uninstall   # remove every symlink this repo planted
```

System-level packages are not auto-removed — `brew uninstall`, `apt
purge`, `pacman -R`, or `dnf remove` driven against the `packages/`
lists is a manual step. Phase 4 of v3-native will ship a wrapping
`scripts/uninstall.sh` that does both.

## Adding packages

- macOS (any) → `packages/Brewfile`.
- Linux CLI (cross-distro) → `packages/apt.list` +
  `packages/pacman.list` + `packages/dnf.list`.
- Linux GUI app → the matching `<pkgmgr>-desktop.list`.
- Linux package absent from native repos → `packages/aur.list`
  (Arch) or `packages/snap.list` (Debian/Fedora).

Every package added to any of these files needs a matching row in
[`doc/packages-native.md`](doc/packages-native.md) — see CLAUDE.md §4.

## GPG signing

Optional and opt-in. Run once per host:

```sh
~/.scripts/gpg-setup.sh
```

The wizard generates an ed25519 + cv25519 keypair tied to your git
email, writes `~/.config/git/signing.gitconfig`, and prints the
public key to paste into GitHub.
