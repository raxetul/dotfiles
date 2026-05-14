# dotfiles

Portable, fully Nix-managed user environment. One declarative configuration
under `home/` runs identically on macOS and every Linux distro. No
per-distro package lists, no Homebrew step — just
[Home Manager](https://github.com/nix-community/home-manager).

## Quick start

```sh
./setup.sh             # server profile: CLI + dev toolchain
./setup.sh --desktop   # Linux: also install sway + GUI apps
```

That does exactly two things:

1. Installs Nix in multi-user (daemon) mode if it isn't already present.
2. Enables flakes and runs `home-manager switch` for the current user.

Re-running is safe — every step is idempotent.

## Package buckets

Packages are split across four modules. Which ones get imported depends
on the platform and the `--desktop` flag:

| Module                          | When imported                              | Contains                                                                 |
|---------------------------------|--------------------------------------------|--------------------------------------------------------------------------|
| `home/modules/common.nix`       | always                                     | Cross-platform CLI: curl, wget, jq, go, rustup, node, llvm, docker CLI, fonts. |
| `home/modules/linux.nix`        | always on Linux                            | Linux CLI/system tools: qemu, libvirt, bridge-utils, hdparm, dstat.       |
| `home/modules/linux-desktop.nix`| Linux + `--desktop` flag                   | Linux GUI: sway stack, alacritty, wezterm, polybar, qtile, dunst, flameshot, telegram, discord, obs-studio, kdiff3, veracrypt, nautilus, qtcreator, asciinema, xdotool. |
| `home/modules/darwin.nix`       | always on macOS                            | macOS CLI + desktop: colima, lima (Docker daemon backend).               |

Shell (`zsh.nix`, `starship.nix`, `zoxide.nix`, `fzf.nix`) and editor
modules (`vim.nix`, `git.nix`, `tmux.nix`) are imported on every host.

## How the profile flag works

`setup.sh` exports `DOTFILES_PROFILE` and `flake.nix` reads it at impure
eval time:

- No flag (or `--server`) → `DOTFILES_PROFILE=server`, Linux desktop bucket skipped.
- `--desktop` → `DOTFILES_PROFILE=desktop`, Linux desktop bucket imported.
- On macOS the flag is accepted but irrelevant — `darwin.nix` is always imported.

## Layout

| Path                          | Purpose                                                                          |
|-------------------------------|----------------------------------------------------------------------------------|
| `flake.nix`                   | Builds `homeConfigurations.default` for the current `$USER` / system / profile.  |
| `home/default.nix`            | Imports the four buckets above plus the shared shell/editor modules.             |
| `home/modules/*.nix`          | One file per concern. The four package buckets + per-program config.             |
| `setup.sh`                    | Bootstrap: install Nix → enable flakes → home-manager switch.                    |

## Re-applying after editing `home/`

Re-run the bootstrap — it's safe and idempotent:

```sh
./setup.sh --desktop   # or omit --desktop for the server profile
```

Each run uses a fresh backup suffix of the form `backup-YYYY-MM-DD---N`
(N restarts at 1 every day and increments for further same-day runs), so
home-manager never errors out on existing backups. The suffix applies
to every file home-manager replaces (`.zshrc`, `.bashrc`, anything under
`~/.config/`, …). Example:

```text
~/.zshrc.backup-2026-05-15---1   ← from this morning's run
~/.zshrc.backup-2026-05-15---2   ← from the second run today
~/.zshrc.backup-2026-05-16---1   ← first run tomorrow
```

If you'd rather drive home-manager directly:

```sh
DOTFILES_PROFILE=desktop nix run --impure home-manager/master -- \
    switch --impure --flake .#default -b "$(date +%Y-%m-%d)---manual"
```

## Daemons & root-required setup on non-NixOS Linux

Home Manager installs the **binaries** for `docker`, `libvirt`, `qemu`,
etc., but their **daemons** and group memberships still need root. On a
regular distro:

```sh
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
```

(On NixOS, put this in `configuration.nix` instead.) Sway/Wayland
sessions also need a working seat/login stack (`greetd` / `gdm` / …) —
that lives outside the user profile.

## Third-party zsh plugins

`home/modules/zsh.nix` pulls `enhancd`, `zsh-histdb`, and `alias-tips`
from GitHub. The `sha256` for each is `lib.fakeSha256` until you build
once — Nix will print the correct hash; paste it in and rebuild.

## Adding packages

- Cross-platform CLI tool → `home/modules/common.nix`.
- Linux CLI / system tool → `home/modules/linux.nix`.
- Linux GUI app → `home/modules/linux-desktop.nix`.
- macOS-specific (CLI or GUI) → `home/modules/darwin.nix`.
