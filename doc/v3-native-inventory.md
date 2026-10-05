---
status: source-of-truth
branch: main
maintainer: raxetul@gmail.com
claude-rule: "Phase-1 inventory for the Nix-removal refactor. Update entries as packages get verified on each distro."
progress: |
  Phases 1-3 are done (inventory, native package lists, symlink loop in
  scripts/symlinks.sh). The Phase 5 deletions are done. These files are
  all gone: flake.nix, flake.lock, home/, .claude/skills/nix-module-author/,
  .claude/commands/new-module.md, doc/flake.md, doc/home-default.md,
  doc/modules-*.md, doc/packages-*.md. No .nix files remain in the tree.
  The plugin wiring that Home Manager generated is now native:
  tmux uses TPM (yank, catppuccin + theme) and
  vim uses vim-plug (~24 plugins). See configurations/tmux/tmux.conf
  and configurations/vim/vimrc.
  Phase 4 is done. scripts/dotfiles-state.sh records the realized
  footprint (see doc/state-management.md). scripts/uninstall.sh
  reverses it in one pass: symlinks, plugins and bootstraps that the
  ledger records, and .path segments. It has an optional --purge that the ledger
  controls (install-only, never present) and an optional --shell revert.
---

# v3-native — Phase 1 Inventory

This is a catalog of each Nix-managed surface in the current repo. It gives the
native equivalent for each supported package manager.

## Design constraints (locked)

1. **Native pkg manager first** — `brew` (macOS), `apt` (Debian/Ubuntu),
   `pacman` (Arch), `dnf`/`rpm` (Fedora/RHEL/openSUSE).
2. **Fallback only if absent from native** — AUR (Arch), Snap (cross-distro).
   Flatpak intentionally not in scope.
3. **User-scoped footprint** — the only system-wide writes are the writes that the package
   manager does for its normal work (sudo apt install …). Everything the
   repo plants is under `$HOME`:
   - dotfiles checkout: `~/gel-ort/dotfiles/`
   - symlinks: `~/.config/<app>/…`
   - shell rcs: `~/.zshrc`, `~/.bashrc`, `~/.vimrc`
   - scripts: `~/.scripts/` on PATH
   - third-party assets (tpm, zsh plugins, vim plugins): `~/.config/...`
     or `~/.local/share/...`
4. **Easy uninstall** — `scripts/uninstall.sh` removes each user-scope
   artifact in one pass. `--purge` removes only the `install` records
   of the ledger (never `present` ones) with the matching package
   manager.

---

## Package mapping

Legend: `—` = not in the primary repo of this manager. `(name)` = the package installs
with a binary name that is different from the upstream name (the caller must alias or rename
it in PATH).

### Cross-platform CLI (was `home/modules/packages/common.nix`)

| Upstream | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| arp-scan | arp-scan | arp-scan | arp-scan | arp-scan | — |
| bandwhich | bandwhich | bandwhich (23.04+) | bandwhich | bandwhich | cargo, AUR |
| bind dnsutils (dig/host/nslookup) | bind | dnsutils | bind | bind-utils | — |
| wget | wget | wget | wget | wget | — |
| curl | curl | curl | curl | curl | — |
| clang-format / clang-tidy | clang-format | clang-format clang-tidy | clang | clang-tools-extra | — |
| llvm | llvm | llvm | llvm | llvm | — |
| go | go | golang-go | go | golang | — |
| rustup | rustup-init | rustup (23.10+) | rustup | rustup | curl https://sh.rustup.rs |
| nodejs (24.x LTS) | node@22 / node | nodejs (NodeSource) | nodejs | nodejs | NodeSource / volta |
| sqlite (interactive) | sqlite | sqlite3 | sqlite | sqlite | — |
| docker (CLI) | docker | docker.io (or `docker-ce` via Docker repo) | docker | moby-engine | — |
| docker-compose | docker-compose | docker-compose-v2 | docker-compose | docker-compose-plugin | — |
| jq | jq | jq | jq | jq | — |
| tldr | tealdeer | tldr | tealdeer | tldr | cargo install tealdeer |
| coreutils (GNU) | coreutils | — (already GNU) | — (already GNU) | — (already GNU) | — |
| zip | zip | zip | zip | zip | — |
| unzip | unzip | unzip | unzip | unzip | — |
| ripgrep | ripgrep | ripgrep | ripgrep | ripgrep | — |
| fd | fd | fd-find ⚠️ binary is `fdfind` | fd | fd-find | alias `fd=fdfind` in apt path |
| bat | bat | bat ⚠️ binary is `batcat` on Debian | bat | bat | alias `bat=batcat` on Debian |
| lefthook | lefthook | — | — | — | release binary → `~/.local/bin/lefthook`, or `go install github.com/evilmartians/lefthook@latest` |
| shellcheck | shellcheck | shellcheck | shellcheck | ShellCheck | — |
| nixpkgs-fmt | **dropped** (no Nix in v3) | — | — | — | — |
| font-awesome | font-fontawesome | fonts-font-awesome | ttf-font-awesome | fontawesome-fonts | — |
| jetbrains-mono | font-jetbrains-mono | fonts-jetbrains-mono | ttf-jetbrains-mono | jetbrains-mono-fonts | — |
| jetbrains-mono Nerd Font | font-jetbrains-mono-nerd-font | — | ttf-jetbrains-mono-nerd | — | AUR `nerd-fonts-jetbrains-mono`, or release zip → `~/.local/share/fonts/`, then `fc-cache -fv` |

### Linux baseline (was `home/modules/packages/linux.nix`)
This module is empty. The module body has no `home.packages`. There is nothing to map.

### Linux server (was `home/modules/packages/linux-server.nix`)

| Upstream | apt | pacman | dnf | Notes |
|---|---|---|---|---|
| docker daemon | docker.io / docker-ce | docker | moby-engine | `systemctl enable --now docker`; add user to `docker` group |
| libvirt | libvirt-daemon-system | libvirt | libvirt | enable `libvirtd.service` |
| qemu | qemu-kvm | qemu-base | qemu-kvm | — |

### Linux desktop (was `home/modules/packages/linux-desktop.nix`)

| Upstream | apt | pacman | dnf | Fallback |
|---|---|---|---|---|
| ghostty | — | ghostty (extra) | — | Arch: native; Debian/Ubuntu: official `.deb` from GitHub releases; Fedora: COPR `pgdev/ghostty` |
| sway | sway | sway | sway | — |
| swaybg | swaybg | swaybg | swaybg | — |
| swayidle | swayidle | swayidle | swayidle | — |
| swaylock | swaylock | swaylock | swaylock | — |
| waybar | waybar | waybar | waybar | — |
| wofi | wofi | wofi | wofi | — |
| dunst | dunst | dunst | dunst | — |
| xdotool | xdotool | xdotool | xdotool | — |
| flameshot | flameshot | flameshot | flameshot | — |
| kdiff3 | kdiff3 | kdiff3 | kdiff3 | — |
| nautilus | nautilus | nautilus | nautilus | — |
| obs-studio | obs-studio | obs-studio | obs-studio | — |
| smplayer | smplayer | smplayer | smplayer | — |
| telegram-desktop | telegram-desktop | telegram-desktop | telegram-desktop | Snap `telegram-desktop` |
| discord | — | — | — (RPM Fusion: `discord`) | AUR `discord`; Snap `discord`; or `.deb` from discord.com |
| veracrypt | — (PPA `unit193/encryption`) | — (AUR `veracrypt`) | — (RPM Fusion) | release `.deb`/`.rpm` from veracrypt.fr |
| qtcreator | qtcreator | qtcreator | qt-creator | — |
| asciinema | asciinema | asciinema | asciinema | — |

### macOS (was `home/modules/packages/darwin.nix`)

| Upstream | brew formula | Notes |
|---|---|---|
| colima | colima | `brew services start colima` for docker daemon |
| lima | lima | Backs colima |

### macOS GUI bridge (already lives in `packages/Brewfile`)

ghostty, karabiner-elements, rectangle, discord, telegram, obs,
flameshot, qt-creator, kdiff3, veracrypt, **pinentry-mac** (referenced by
`home/modules/gpg.nix` — needs to stay).

---

## Module catalog — config + binaries

Each row shows what Nix did, what stays, and what we must rebuild in v3.

| Module | Binary needed | Config file (lives in repo) | What HM was doing extra |
|---|---|---|---|
| `atuin` | `atuin` | `configurations/atuin/config.toml` | `programs.atuin.enable` injected shell hooks → must add `eval "$(atuin init zsh)"` to `configurations/zsh/.zshrc` |
| `bash` | bash (always present) | `configurations/aliases/*.sh`, `configurations/bash/.bashrc` (TBD) | None beyond sourcing aliases |
| `bat` | `bat` | `configurations/themes/bat/Catppuccin-mocha.tmTheme` | Symlink theme into `~/.config/bat/themes/`; run `bat cache --build` on install (activation script → setup.sh step) |
| `editor` (vim + neovim) | `vim`, `neovim` | `configurations/vim/vimrc`, `configurations/vim/ftplugin/*.vim`, `configurations/nvim/init.vim` | Installed vim plugins via `pkgs.vimPlugins.*` — must replace with **vim-plug** (`Plug` directives in vimrc) so `:PlugInstall` handles them |
| `eza` | `eza` | `configurations/themes/eza/colors.yml` | Exports `EZA_COLORS` env — move to `configurations/zsh/exports.sh` |
| `fzf` | `fzf`, `ripgrep`, `fd` | `configurations/themes/fzf/catppuccin-mocha.sh` | `programs.fzf.enable` writes `~/.fzf.zsh` integration — must add `source <(fzf --zsh)` (or `eval "$(fzf --zsh)"`) to zshrc |
| `ghostty` | `ghostty` (platform-specific install) | `configurations/ghostty/config` | Just a symlink |
| `git` | `git`, `git-delta` | `configurations/git/gitconfig`, `commit-template`, `template/hooks/{commit-msg,pre-commit}` | 3 xdg symlinks (already covered by setup.sh's symlink loop) |
| `gpg` | `gnupg`, `pinentry-mac` (mac) / `pinentry-curses` (linux) | `configurations/gpg/gpg.conf` (TBD — extract from inline `text =`), `configurations/gpg/gpg-agent.conf.{darwin,linux}` | Currently written inline in nix — extract to two files (one per OS) and have setup.sh symlink the right one |
| `scripts` | n/a | `scripts/*` | HM was copying every file in `scripts/` to `~/.scripts/<name>` with +x and prepending PATH — setup.sh must do `mkdir -p ~/.scripts && ln -sf …` loop + ensure PATH in zshrc |
| `starship` | `starship` | `configurations/starship/starship.toml` | Symlink + shell init `eval "$(starship init zsh)"` |
| `tmux` | `tmux` | `configurations/tmux/tmux.conf` | Plugins via HM (`tmuxPlugins.*`) — replace with **TPM** (clone to `~/.config/tmux/plugins/tpm`, source from tmux.conf) |
| `zoxide` | `zoxide` | (no config file) | Shell init `eval "$(zoxide init zsh)"` |
| `zsh` | `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search` | `configurations/zsh/.zshrc` (TBD — currently HM-generated), `configurations/aliases/*.sh` | HM was generating `.zshrc` from `programs.zsh.{initContent,sessionVariables,shellAliases,plugins}` — must consolidate into a real `.zshrc` that sources plugin scripts from their package install paths (or `~/.config/zsh-plugins/` if cloned from git) |

### Notes per module

- **vim plugins**: The `pkgs.vimPlugins.*` set of Nix had 17 plugins. v3 uses
  vim-plug (one `.vim` file in `~/.vim/autoload/plug.vim`). This is the bootstrap
  command in setup.sh:
  ```sh
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ```
  Then `vim +PlugInstall +qa`.
- **tmux plugins**: TPM is the standard. This is the bootstrap:
  ```sh
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
  ```
  `tmux.conf` already has `run '~/.config/tmux/plugins/tpm/tpm'` (verify).
- **zsh plugins**: Use distro packages when possible. Each distro
  puts them in a different path. In zshrc, use
  `[ -f … ] && source …` guards for all the common paths.

---

## Activation hooks (was `home.activation.*`)

| Hook | Trigger | v3 equivalent |
|---|---|---|
| `bat.batCacheBuild` | After bat theme symlinked | `setup.sh` step: `bat cache --build` (idempotent, skip if hash matches) |
| `darwin.ghosttyMacosNotice` | macOS only | `setup.sh` step on macOS: print same warning if `~/Library/Application Support/com.mitchellh.ghostty/config` exists as non-symlink |
| `darwin.brewBundle` | macOS only | `setup.sh` already does `brew bundle --file=…/Brewfile` — promote from "Step 2b" to a proper step in v3 |

The repo has no `services.*` / `launchd.*` / `systemd.user.*` blocks. There are no
unit files to migrate.

---

## Symlinks (what HM's `xdg.configFile` / `home.file` was creating)

Each of these becomes a plain `ln -sf $REPO/configurations/<src> ~/<dst>`
call in setup.sh. The source paths are byte-identical to the paths today.

| Repo source | Symlink target |
|---|---|
| `configurations/starship/starship.toml` | `~/.config/starship.toml` |
| `configurations/atuin/config.toml` | `~/.config/atuin/config.toml` |
| `configurations/themes/bat/Catppuccin-mocha.tmTheme` | `~/.config/bat/themes/Catppuccin-mocha.tmTheme` |
| `configurations/git/commit-template` | `~/.config/git/commit-template` |
| `configurations/git/template/hooks/commit-msg` | `~/.config/git/template/hooks/commit-msg` |
| `configurations/git/template/hooks/pre-commit` | `~/.config/git/template/hooks/pre-commit` |
| `configurations/vim/vimrc` | `~/.vimrc` |
| `configurations/vim/ftplugin/nix.vim` | `~/.vim/ftplugin/nix.vim` |
| `configurations/vim/ftplugin/go.vim` | `~/.vim/ftplugin/go.vim` |
| `configurations/vim/ftplugin/yaml.vim` | `~/.vim/ftplugin/yaml.vim` |
| `configurations/vim/ftplugin/python.vim` | `~/.vim/ftplugin/python.vim` |
| `configurations/nvim/init.vim` | `~/.config/nvim/init.vim` |
| `configurations/ghostty/config` | `~/.config/ghostty/config` |
| `configurations/dunst/dunstrc` (linux desktop) | `~/.config/dunst/dunstrc` |
| `configurations/waybar/config.jsonc` (linux desktop) | `~/.config/waybar/config.jsonc` |
| `configurations/waybar/style.css` (linux desktop) | `~/.config/waybar/style.css` |
| `scripts/<each-file>` | `~/.scripts/<each-file>` (with +x) |

We must **create** these additional files. HM generates them now, and
the repo has no source file for them:

- `configurations/zsh/.zshrc` — build it from the current HM `programs.zsh`
  attrs (initContent, sessionVariables, shellAliases), the plugin source
  lines, and the tool init evals (`atuin`, `starship`, `zoxide`, `fzf`).
- `configurations/bash/.bashrc` — minimal, sources aliases.
- `configurations/zsh/exports.sh` — `EDITOR`, `EZA_COLORS`, etc.
- `configurations/gpg/gpg.conf` — extracted from `programs.gpg` inline.
- `configurations/gpg/gpg-agent.conf.darwin` and `.linux` — extracted
  from the inline content of `home/modules/gpg.nix`.

---

## setup.sh diff vs today

| Today's step | v3 |
|---|---|
| Step 1: install Nix | **delete** |
| Step 2: enable flakes | **delete** |
| Step 2b: install Homebrew (macOS) | keep, promote to Step 1 (macOS) |
| Step 3: `nix flake update` | **delete** |
| Step 4: `home-manager switch` | **replace** with: install packages from native lists, then run symlink loop |
| Step 5: chsh to zsh | keep |
| Step 5b: install distro-native lists | merge into the new "install packages" step |
| Step 6: `lefthook install` | keep (lefthook now comes from the package step) |

New script structure:

```text
setup.sh
├── detect OS (darwin | debian | arch | fedora | opensuse)
├── install package manager itself if missing (mac: brew; linux: assume present)
├── update local pkg DB (brew update / apt update / pacman -Syy / dnf check-update)
├── install primary list:
│   - macOS:   brew bundle --file=packages/Brewfile
│   - Debian:  sudo apt install -y $(grep -v ^# packages/apt.list)
│   - Arch:    sudo pacman -S --needed $(grep -v ^# packages/pacman.list)
│   - Fedora:  sudo dnf install -y $(grep -v ^# packages/dnf.list)
├── fallback list (Linux only):
│   - Arch:    yay -S --needed $(grep -v ^# packages/aur.list)
│   - others:  sudo snap install <pkg> for each line in snap.list
├── bootstrap zsh/vim/tmux plugin managers (vim-plug, TPM, zsh plugins)
├── symlink loop (see table above)
├── shell init: chsh to zsh if needed
├── lefthook install
└── (optional) gpg-setup.sh if --gpg
```

---

## Files to delete in Phase 5

```text
flake.nix
flake.lock
home/                    # entire dir
.claude/skills/nix-module-author/
.claude/commands/new-module.md    # (or rewrite to scaffold a native pkg list entry)
doc/flake.md
doc/home-default.md
doc/modules-*.md         # 14 files
doc/packages-*.md        # 4 files (will be replaced by 1 doc/packages-native.md)
```

---

## Uninstall path (the constraint that drove the design)

`scripts/uninstall.sh` reads the realized-state
ledger (`scripts/dotfiles-state.sh`, see
[state-management.md](state-management.md)). It does not derive the
footprint again. `--purge` therefore removes only the packages that we installed:

```sh
# 1. Remove symlinks the repo planted (scripts/symlinks.sh uninstall;
#    cross-check against `dotfiles-state.sh reduce symlink`).
# 2. rm -rf ~/.scripts
# 3. rm -rf ~/.config/{starship.toml,atuin,bat/themes/Catppuccin-mocha.tmTheme,git/{commit-template,template},nvim,ghostty,dunst,waybar,tmux/plugins,gpg}
# 4. rm -rf ~/.vim ~/.vimrc
# 5. (optional, --purge) `dotfiles-state.sh owned-packages` → apt purge /
#    brew uninstall / pacman -R / dnf remove (NEVER the `present` ones).
# 6. (optional, --shell) chsh back to the `from=` shell in the shell record.
# 7. Strip each package's bracketed segment from .path.
```

Worst-case "delete everything this repo planted":
```sh
./scripts/uninstall.sh --purge --shell && rm -rf ~/gel-ort/dotfiles
```

The repo does not write to `/etc/`, `/usr/local/`, or `/opt/`, except for the writes that the native pkg
manager does.
