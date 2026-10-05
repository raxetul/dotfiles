# dotfiles

Portable user environment for macOS and Linux. Native package managers install the packages (brew on macOS; apt,
pacman, or dnf on Linux). A `configurations/` layer that you can edit at runtime holds every config file.
`scripts/symlinks.sh` connects the two. The terminal stack uses Catppuccin Mocha.

## Quick start

```sh
./setup.sh             # Linux server profile, or macOS
./setup.sh --desktop   # Linux desktop: also installs sway + GUI apps
./setup.sh --update    # upgrade already-installed packages
```

The script does these steps:

1. On macOS, install Homebrew if it is missing.
2. Install the packages from `packages/Brewfile` (macOS) or from `packages/<pkgmgr>.list` and the optional
   `-desktop.list` (Linux).
3. Add the Linux fallbacks: AUR (Arch family) or Snap (Debian/Fedora).
4. Bootstrap the plugin managers for the user: vim-plug, TPM, zsh-you-should-use.
5. Plant symlinks from `configurations/` into `$HOME` with `scripts/symlinks.sh`.
6. Switch the login shell to zsh.
7. Install the lefthook git hooks for this repo.

You can run the script again safely. Every step is idempotent. To refresh the packages and configurations on a host
that is already set up, run `scripts/update-dotfiles`.

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
| `scripts/update-dotfiles`       | Refresh packages + configurations on an already-set-up host.                     |
| `scripts/gpg-setup.sh`          | Generate a signing key + wire it into git (one-shot, idempotent).                |
| `scripts/nix-uninstall.sh`      | Remove a legacy multi-user Nix install (kept around for hosts still on v2).      |
| `.claude/`                      | Repo-local agentic config: slash commands, skills, hooks, permissions.           |
| `CLAUDE.md`                     | Ground rules for any agent working in this repo.                                 |
| `doc/`                          | One doc per significant file — see the index in `doc/README.md`.                 |

## Documentation

Full index at [doc/README.md](doc/README.md). Highlights:

- [doc/packages-native.md](doc/packages-native.md) — every package that this repo installs, for each OS, with
  fallback notes.
- [doc/theming.md](doc/theming.md) — the Catppuccin Mocha palette and the mapping for each app.

## How the profile flag works

`setup.sh --desktop` exports `DOTFILES_DESKTOP=1`:

- On Linux: the script installs the matching `<pkgmgr>-desktop.list` with the baseline. It also plants the symlinks
  for the Wayland stack (waybar, dunst).
- On macOS: the script accepts the flag, but the flag has no effect. `Brewfile` already has every GUI cask.

## Daemons & root-required setup on Linux

The package managers install the **binaries** for `docker`, `libvirt`, `qemu`, and other tools. The **daemons**
and the group memberships still need root:

```sh
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
```

Sway and Wayland sessions also need a working seat and login stack (`greetd`, `gdm`, and others). That stack is
outside the user profile.

## Re-applying after editing `configurations/`

```sh
./setup.sh             # or --desktop on Linux
```

Edits in `configurations/` take effect immediately. The live tree points at the repo through
`scripts/symlinks.sh`. You do not need to run the script again, unless you change which files exist. Run `setup.sh`
again when you add a new mapping. Run it also when you want to update a new host.

## Uninstall

```sh
./scripts/uninstall.sh            # remove every user-scope artifact:
                                   # symlinks, plugins, .path segments,
                                   # empty dirs left behind
./scripts/uninstall.sh --dry-run  # preview every action, execute none
./scripts/uninstall.sh --purge    # also remove the packages this repo
                                   # installed (never ones you had)
./scripts/uninstall.sh --shell    # also revert the login shell
```

The script prunes the directories that the removals leave empty (`rmdir` only). A directory that still has your
files stays unchanged. The ledger (`scripts/dotfiles-state.sh`) controls `--purge`. It removes only the packages
that the ledger records as *installed by this repo*. It does not remove packages that were already `present` on the
host. It uses the native package manager. For tools that a script installed, it removes the binary under
`~/.local/bin`. See [doc/state-management.md](doc/state-management.md). The ledger does not track AUR and Snap
fallbacks. The script flags them for manual removal.

## Adding packages

- macOS (any) → `packages/Brewfile`.
- Linux CLI (cross-distro) → `packages/apt.list` +
  `packages/pacman.list` + `packages/dnf.list`.
- Linux GUI app → the matching `<pkgmgr>-desktop.list`.
- Linux package absent from native repos → `packages/aur.list`
  (Arch) or `packages/snap.list` (Debian/Fedora).

Each package that you add to any of these files needs a matching row in
[`doc/packages-native.md`](doc/packages-native.md). See CLAUDE.md §4.

## GPG signing

This step is optional. Run it one time for each host:

```sh
~/.scripts/gpg-setup.sh
```

The wizard generates an ed25519 and cv25519 keypair for your git email. It writes `~/.config/git/signing.gitconfig`.
It prints the public key. Paste the public key into GitHub.
