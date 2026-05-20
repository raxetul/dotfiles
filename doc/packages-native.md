---
status: source-of-truth
branch: refactor/v3-native
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Every package added to packages/Brewfile or packages/*.list MUST get a row here in the same change. See CLAUDE.md §6."
---

# Packages — native install reference

Single lookup table for every package this repo installs, per OS.
Lives next to the `.list` files it documents.

## File layout (the install lists this doc indexes)

```
packages/
├── Brewfile               # macOS: every formula + cask
├── apt.list               # Debian/Ubuntu baseline (server + CLI)
├── apt-desktop.list       # Debian/Ubuntu desktop additions
├── pacman.list            # Arch baseline
├── pacman-desktop.list    # Arch desktop additions
├── dnf.list               # Fedora baseline
├── dnf-desktop.list       # Fedora desktop additions
├── aur.list               # Arch fallback (only pacman-family)
└── snap.list              # Debian + Fedora fallback (skipped on Arch)
```

`packages/` sits at the repo root next to `configurations/`. The
separation is intentional: `configurations/` holds app config files
the user edits live; `packages/` holds the inventory of what's
installed.

setup.sh detects the distro and runs the matching pair (`*.list` always;
`*-desktop.list` only with `--desktop`), then layers fallbacks
(`aur.list` on Arch, `snap.list` elsewhere).

## Install policy (locked)

1. **Native pkg manager first.** macOS → `brew`. Linux → `apt` /
   `pacman` / `dnf` (driven by distro detection in `setup.sh`).
2. **Fallback by distro family** (only if the native repo lacks the
   package):

   | Distro family | Primary | Fallback 1 | Fallback 2 |
   |---|---|---|---|
   | Arch (Arch, Manjaro, EndeavourOS, Artix) | pacman | AUR (yay/paru) | Snap |
   | Debian/Ubuntu/Mint | apt | Snap | release `.deb` / PPA |
   | Fedora/RHEL/Rocky/Alma | dnf | Snap | release `.rpm` / COPR / RPM Fusion |
   | openSUSE | zypper | Snap | OBS / release `.rpm` |
   | macOS | brew formula | brew cask | upstream `.dmg` |

   AUR is **Arch-only** — `makepkg`/`yay`/`paru` output `.pkg.tar.zst`
   files that only `pacman` can install. Flatpak is intentionally
   out of scope.

3. **User-scoped footprint.** The only system-wide writes are the
   package manager doing its job. Everything the repo plants lives
   under `$HOME` (symlinks, scripts, plugin checkouts).

## How to read the tables

- `—` = not in this manager's default repos; check the *Fallback* column.
- `(name)` = installed binary has a different name than upstream
  (script aliases it; see notes column).
- *Fallback* lines only matter when the column for your distro is `—`.

---

## Shell + prompt

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| zsh | zsh | zsh | zsh | zsh | — |
| bash | bash | bash | bash | bash | preinstalled everywhere |
| starship | starship | starship | starship | starship | release binary `curl -sS https://starship.rs/install.sh \| sh` |
| atuin | atuin | atuin (23.10+) | atuin | atuin | release binary `~/.local/bin/atuin` |
| zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | git clone → `~/.config/zsh-plugins/` |
| zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | git clone |
| zsh-history-substring-search | zsh-history-substring-search | zsh-syntax-highlighting (split) | zsh-history-substring-search | zsh-history-substring-search | git clone |
| you-should-use (zsh plugin) | — | — | — | — | git clone `MichaelAquilina/zsh-you-should-use` → `~/.config/zsh-plugins/`; **AUR**: `zsh-you-should-use` |

## File / search tools

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| eza | eza | eza (23.10+) | eza | eza | cargo install eza |
| bat | bat | bat — installed binary is `batcat` on Debian | bat | bat | shell alias `bat=batcat` on Debian/Ubuntu |
| fzf | fzf | fzf | fzf | fzf | — |
| ripgrep | ripgrep | ripgrep | ripgrep | ripgrep | — |
| fd | fd | fd-find — installed binary is `fdfind` on Debian | fd | fd-find | shell alias `fd=fdfind` on Debian/Ubuntu |
| zoxide | zoxide | zoxide (22.04+) | zoxide | zoxide | release binary |
| tldr (tealdeer) | tealdeer | tldr | tealdeer | tldr | cargo install tealdeer |
| jq | jq | jq | jq | jq | — |

## Editor stack

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| vim | vim | vim | vim | vim | — |
| neovim | neovim | neovim | neovim | neovim | — |
| tmux | tmux | tmux | tmux | tmux | — |
| vim-plug | — | — | — | — | bootstrap script `curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim` |
| TPM (tmux plugin manager) | — | — | — | — | `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm` |

Vim plugins themselves are declared via `Plug` directives in
`configurations/vim/vimrc`; `:PlugInstall` materializes them.

## Git + dev tooling

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| git | git | git | git | git | — |
| git-delta | git-delta | git-delta (22.04+) | git-delta | git-delta | release binary |
| gnupg | gnupg | gnupg | gnupg | gnupg | — |
| pinentry-mac | pinentry-mac | n/a | n/a | n/a | macOS-only — sourced via `packages/Brewfile` |
| pinentry-curses | n/a | pinentry-curses | pinentry | pinentry | — |
| lefthook | lefthook | — | — | — | release binary `~/.local/bin/lefthook`, or `go install github.com/evilmartians/lefthook@latest`; **AUR**: `lefthook-bin` |
| shellcheck | shellcheck | shellcheck | shellcheck | ShellCheck | — |

## Language toolchains

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| go | go | golang-go | go | golang | — |
| rustup | rustup-init | rustup (23.10+) | rustup | rustup | `curl https://sh.rustup.rs -sSf \| sh` |
| nodejs (LTS, 24.x today) | node | nodejs (NodeSource repo) | nodejs | nodejs | NodeSource / volta / nvm |
| llvm | llvm | llvm | llvm | llvm | — |
| clang-format / clang-tidy | clang-format | clang-format clang-tidy | clang | clang-tools-extra | — |

## Networking / sysadmin

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| arp-scan | arp-scan | arp-scan | arp-scan | arp-scan | — |
| bandwhich | bandwhich | bandwhich (23.04+) | bandwhich | bandwhich | cargo install bandwhich; **AUR**: `bandwhich-bin` |
| bind dnsutils (dig/host/nslookup) | bind | dnsutils | bind | bind-utils | — |
| wget | wget | wget | wget | wget | — |
| curl | curl | curl | curl | curl | — |

## Containers / virtualization

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| docker CLI | docker | docker.io | docker | moby-engine | Docker official repo (`docker-ce`) |
| docker-compose v2 | docker-compose | docker-compose-plugin (requires Docker's official APT repo on Debian; Universe on Ubuntu 24.04+) | docker-compose | docker-compose-plugin | — |
| colima (mac docker daemon) | colima | n/a | n/a | n/a | macOS-only |
| lima (colima backend) | lima | n/a | n/a | n/a | macOS-only |
| libvirt (Linux server) | n/a | libvirt-daemon-system | libvirt | libvirt | — |
| qemu (Linux server) | n/a | qemu-kvm | qemu-base | qemu-kvm | — |

## Filesystem / misc

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| sqlite (interactive REPL) | sqlite | sqlite3 | sqlite | sqlite | — |
| coreutils (GNU) | coreutils | preinstalled (GNU) | preinstalled (GNU) | preinstalled (GNU) | macOS-only need |
| zip | zip | zip | zip | zip | — |
| unzip | unzip | unzip | unzip | unzip | — |
| asciinema | asciinema | asciinema | asciinema | asciinema | — |

## Fonts

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| Font Awesome | font-fontawesome | fonts-font-awesome | ttf-font-awesome | fontawesome-fonts | — |
| JetBrains Mono | font-jetbrains-mono | fonts-jetbrains-mono | ttf-jetbrains-mono | jetbrains-mono-fonts | — |
| JetBrains Mono Nerd Font | font-jetbrains-mono-nerd-font | — | ttf-jetbrains-mono-nerd | — | release zip from `nerdfonts.com` → `~/.local/share/fonts/`, then `fc-cache -fv`; **AUR**: `nerd-fonts-jetbrains-mono` |

## Linux desktop — Wayland / window stack

(Only installed when profile = desktop.)

| Package | apt | pacman | dnf | Fallback |
|---|---|---|---|---|
| sway | sway | sway | sway | — |
| swaybg | swaybg | swaybg | swaybg | — |
| swayidle | swayidle | swayidle | swayidle | — |
| swaylock | swaylock | swaylock | swaylock | — |
| waybar | waybar | waybar | waybar | — |
| wofi | wofi | wofi | wofi | — |
| dunst | dunst | dunst | dunst | — |
| xdotool | xdotool | xdotool | xdotool | — |

## Linux desktop — GUI apps

| Package | apt | pacman | dnf | Fallback |
|---|---|---|---|---|
| ghostty (terminal) | — | ghostty (extra) | — | Debian/Ubuntu: official `.deb` from GitHub releases; Fedora: COPR `pgdev/ghostty` |
| flameshot | flameshot | flameshot | flameshot | — |
| kdiff3 | kdiff3 | kdiff3 | kdiff3 | — |
| nautilus | nautilus | nautilus | nautilus | — |
| obs-studio | obs-studio | obs-studio | obs-studio | — |
| smplayer | smplayer | smplayer | smplayer | — |
| telegram-desktop | telegram-desktop | telegram-desktop | telegram-desktop | Snap `telegram-desktop` |
| discord | — | — | — (RPM Fusion: `discord`) | **AUR**: `discord`; Debian/Ubuntu: Snap `discord` or `.deb` from discord.com; Fedora: enable RPM Fusion |
| veracrypt | — (PPA `unit193/encryption`) | — | — | **AUR**: `veracrypt`; Debian: PPA or release `.deb` from veracrypt.fr; Fedora: RPM Fusion or release `.rpm` |
| qtcreator | qtcreator | qtcreator | qt-creator | — |

## macOS GUI bridge (`packages/Brewfile`)

These ship only as Cocoa bundles — Homebrew casks are the only sane
install path. The Brewfile is replayed by `setup.sh` on every run.

| Cask | Purpose |
|---|---|
| ghostty | Terminal (official Darwin build via cask) |
| karabiner-elements | Key remapping |
| rectangle | Window manager |
| discord | Communications |
| telegram | Communications |
| obs | Recording / streaming |
| flameshot | Screenshot tool |
| qt-creator | IDE |
| kdiff3 | Three-way diff GUI |
| veracrypt | Encryption volumes |

Formulas (non-cask, CLI-only on mac):

| Formula | Purpose |
|---|---|
| pinentry-mac | Cocoa GPG pinentry dialog — wired into `gpg-agent.conf` on macOS |

---

## Updating this document

**Hard rule** (see [`CLAUDE.md`](../CLAUDE.md) §7): adding a package
to `packages/Brewfile` or any `packages/*.list`
**must** add a row in the matching section above in the same commit.
For each new row, fill all four manager columns (or `—` + a *Fallback*
note). The `post-tool-use.sh` hook flags edits to those files that
didn't also touch this doc.

When you can't find a native package for a Linux distro:

1. Check AUR first (Arch only) — `https://aur.archlinux.org/packages?K=<name>`.
2. Check Snap — `snap find <name>`.
3. Check upstream releases — most projects ship a `.deb` + `.rpm` + tarball.
4. Last resort: language-specific installer (`cargo install`,
   `go install`, `pipx install`) — note in the *Fallback* column.

Never use Flatpak — out of scope by policy.
