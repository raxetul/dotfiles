# dotfiles

Portable, fully Nix-managed user environment. One declarative configuration
under `home/` runs identically on macOS and every Linux distro. No
per-distro package lists, no Homebrew step, no shell-script setup — just
[Home Manager](https://github.com/nix-community/home-manager).

## Quick start

```sh
./setup.sh
```

That does exactly two things:

1. Installs Nix in multi-user (daemon) mode if it isn't already present.
2. Enables flakes and runs `home-manager switch` for the current user.

Open a new shell afterwards (or `exec zsh`).

## Layout

| Path                  | Purpose                                              |
|-----------------------|------------------------------------------------------|
| `flake.nix`           | Builds `homeConfigurations.default` for the current `$USER` on the current system (resolved via `--impure`). |
| `home/default.nix`    | Shared home-manager configuration; imports each module. |
| `home/modules/*.nix`  | One file per concern: `zsh`, `starship`, `git`, `vim`, `tmux`, `fzf`, `zoxide`, `packages`. Linux- vs. Darwin-specific bits live in `linux.nix` / `darwin.nix` and are imported conditionally. |
| `setup.sh`            | Two-step bootstrap: install Nix → run home-manager. |

## What's where

- **CLI tools** (curl, wget, jq, go, rustup, node, llvm, etc.) — `home/modules/packages.nix`, unconditional.
- **Containers** — `pkgs.docker` + `pkgs.docker-compose` on both OSes. On macOS, `home/modules/darwin.nix` adds `colima` + `lima` as the daemon backend (run `colima start` once).
- **Linux system tools** (qemu, libvirt, hdparm, dstat, bridge-utils) — `packages.nix` behind `stdenv.isLinux`.
- **Linux desktop** (sway, waybar, alacritty, wezterm, polybar, qtile, dunst, flameshot, telegram, discord, obs-studio, …) — `packages.nix` behind `stdenv.isLinux`.
- **Fonts** (font-awesome, jetbrains-mono) — `packages.nix`. `fonts.fontconfig.enable = true` lets them be picked up by GTK/Qt apps.
- **Shell** (zsh + plugins + starship + zoxide + fzf) — the corresponding modules under `home/modules/`.

## Re-applying after changes

```sh
nix run --impure home-manager/master -- \
    switch --impure --flake .#default -b backup
```

(`--impure` is required because the flake reads `$USER` and `$HOME` at
evaluation time.)

## Daemons & root-required setup on non-NixOS Linux

Home Manager installs the **binaries** for `docker`, `libvirt`, `qemu`,
etc., but their **daemons** and the group memberships they want still
need root. On a regular distro:

```sh
sudo systemctl enable --now docker libvirtd
sudo usermod -aG docker,kvm,libvirt "$USER"
```

(On NixOS, put this in `configuration.nix`.) Sway/Wayland sessions also
need a working seat/login stack (`greetd` / `gdm` / etc.) — those live
outside the user profile.

## Third-party zsh plugins

`home/modules/zsh.nix` pulls `enhancd`, `zsh-histdb`, and `alias-tips`
from GitHub. The `sha256` for each is `lib.fakeSha256` until you build
once — Nix will print the correct hash; paste it in and rebuild.

## Adding packages

Edit `home/modules/packages.nix`. Cross-platform packages go in the top
list. Linux-only ones go under `lib.optionals stdenv.isLinux`. Anything
gated to macOS lives in `home/modules/darwin.nix`.
