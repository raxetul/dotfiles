---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Every package added to packages/Brewfile or packages/*.list MUST get a row here AND in doc/packages-native.md in the same change. See CLAUDE.md §4."
---

# Packages — install summary

At-a-glance view of **every package this repo installs** and the
**install lane** used on each OS family. This is the summary; the
per-manager package names, version gates, and fallback details live in
[`packages-native.md`](packages-native.md).

- **Rows** — one package.
- **Description** — ≤ 5 words.
- **OS columns** — macOS, Debian/Ubuntu, Arch, Fedora.
- **Cells** — the *lane* that installs it there (not the package name;
  see [`packages-native.md`](packages-native.md) for exact names).

## Legend

| Token | Meaning |
|---|---|
| `brew` | Homebrew formula (macOS) |
| `cask` | Homebrew cask — GUI app (macOS) |
| `apt` | Debian/Ubuntu native repo |
| `arch` | Arch native repo (pacman, core/extra) |
| `dnf` | Fedora native repo |
| `aur` | Arch User Repository (yay/paru) |
| `snap` | Snap fallback |
| `copr` | Fedora COPR |
| `rpmf` | RPM Fusion (Fedora) |
| `ppa` | Debian/Ubuntu PPA |
| `deb` / `rpm` | Upstream release package |
| `custom` | `packages/custom-install/<pkg>/` hook (release binary / installer) |
| `script` | `packages/script-install.list` (`curl … \| sh`) |
| `src` | git clone / file fetch by `setup.sh` (plugins, bootstrappers) |
| `clt` | Xcode Command Line Tools (macOS) |
| `system` | Ships preinstalled with the OS |
| `—` | Not installed on this OS |

Markers on the package name:

- `†` — Linux: installed only with the **desktop** profile
  (`setup.sh --desktop`); macOS: the cask installs unconditionally.
- `‡` — **opt-in**, commented out by default (uncomment the variant you
  want; see the list's own Containers section).

## Shell + prompt

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| zsh | Z shell, interactive login | brew | apt | arch | dnf |
| bash | Bourne-again shell (preinstalled) | system | system | system | system |
| starship | Fast cross-shell prompt | brew | apt | arch | dnf |
| atuin | Shell history sync, search | brew | apt | arch | dnf |
| zsh-autosuggestions | Fish-like command autosuggestions | brew | apt | arch | dnf |
| zsh-syntax-highlighting | Command-line syntax highlighting | brew | apt | arch | dnf |
| zsh-history-substring-search | History substring search binding | brew | src | arch | dnf |
| you-should-use | Reminds you of aliases | src | src | aur | src |
| bash-preexec | Bash preexec/precmd hooks | src | src | src | src |

## File / search tools

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| eza | Modern ls replacement | brew | apt | arch | dnf |
| bat | cat with syntax highlighting | brew | apt | arch | dnf |
| fzf | Fuzzy finder for terminal | brew | apt | arch | dnf |
| ripgrep | Fast recursive regex search | brew | apt | arch | dnf |
| fd | Simple fast find alternative | brew | apt | arch | dnf |
| zoxide | Smarter cd, jump directories | brew | apt | arch | dnf |
| tldr (tealdeer) | Simplified community man pages | brew | apt | arch | dnf |
| jq | Command-line JSON processor | brew | apt | arch | dnf |

## Editor stack

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| vim | Vi improved text editor | brew | apt | arch | dnf |
| neovim | Modernized Vim fork editor | brew | apt | arch | dnf |
| tmux | Terminal multiplexer, session manager | brew | apt | arch | dnf |
| vim-plug | Vim plugin manager bootstrap | src | src | src | src |
| TPM | Tmux plugin manager bootstrap | src | src | src | src |

## Git + dev tooling

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| git | Distributed version control system | brew | apt | arch | dnf |
| git-delta | Syntax-highlighting diff pager | brew | apt | arch | dnf |
| gnupg | GNU Privacy Guard encryption | brew | apt | arch | dnf |
| pinentry-mac | macOS GPG passphrase dialog | brew | — | — | — |
| pinentry-curses | Terminal GPG passphrase prompt | — | apt | arch | dnf |
| lefthook | Fast Git hooks manager | brew | custom | aur | custom |
| shellcheck | Shell script static analysis | brew | apt | arch | dnf |
| gh | GitHub command-line interface | brew | apt | arch | dnf |
| claude | Claude Code agent CLI | custom | custom | custom | custom |

## Language toolchains

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| go | Go compiler and toolchain | brew | apt | arch | dnf |
| rustup | Rust toolchain installer | brew | apt | arch | dnf |
| mold | Fast ELF Rust linker | — | apt | arch | dnf |
| nodejs | Node.js JavaScript runtime (LTS) | brew | apt | arch | dnf |
| llvm | LLVM compiler infrastructure | brew | apt | arch | dnf |
| clang-format / clang-tidy | C/C++ formatter, linter | brew | apt | arch | dnf |

## Networking / sysadmin

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| arp-scan | ARP network host scanner | brew | apt | arch | dnf |
| bandwhich | Terminal bandwidth usage monitor | brew | apt | arch | dnf |
| bind dnsutils | dig/host/nslookup DNS tools | brew | apt | arch | dnf |
| wget | Non-interactive network downloader | brew | apt | arch | dnf |
| curl | URL data transfer tool | brew | apt | arch | dnf |

## Containers / virtualization

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| docker (engine + CLI) ‡ | Container runtime and CLI | brew | apt | arch | dnf |
| docker-compose ‡ | Multi-container orchestration tool | brew | apt | arch | dnf |
| colima | macOS container runtime (Lima) | brew | — | — | — |
| lima | Linux VMs on macOS | brew | — | — | — |
| libvirt | Linux virtualization management daemon | — | apt | arch | dnf |
| qemu | Machine emulator and virtualizer | — | apt | arch | dnf |

## Filesystem / misc

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| sqlite | Embedded SQL database CLI | brew | apt | arch | dnf |
| coreutils (GNU) | GNU core utilities | brew | system | system | system |
| zip | Create ZIP archives | brew | apt | arch | dnf |
| unzip | Extract ZIP archives | brew | apt | arch | dnf |
| asciinema | Terminal session recorder | brew | apt | arch | dnf |

## Fonts

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| Font Awesome | Icon glyph font | brew | apt | arch | dnf |
| JetBrains Mono | Developer monospace typeface | brew | apt | arch | dnf |
| JetBrains Mono Nerd Font | Glyph-patched monospace font | brew | custom | arch | custom |

## Linux desktop — Wayland / window stack

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| sway † | Wayland tiling compositor | — | apt | arch | dnf |
| swaybg † | Wayland wallpaper setter | — | apt | arch | dnf |
| swayidle † | Wayland idle daemon | — | apt | arch | dnf |
| swaylock † | Wayland screen locker | — | apt | arch | dnf |
| waybar † | Wayland status bar | — | apt | arch | dnf |
| wofi † | Wayland application launcher | — | apt | arch | dnf |
| dunst † | Desktop notification daemon | — | apt | arch | dnf |
| xdotool † | X11 automation input tool | — | apt | arch | dnf |

## Linux desktop — GUI apps

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| ghostty † | GPU-accelerated terminal emulator | cask | deb | arch | copr |
| flameshot † | Screenshot capture, annotation | cask | apt | arch | dnf |
| kdiff3 † | Three-way merge diff | cask | apt | arch | dnf |
| nautilus † | GNOME file manager | — | apt | arch | dnf |
| obs-studio † | Screen recording, streaming | cask | apt | arch | dnf |
| smplayer † | Qt media player frontend | — | apt | arch | dnf |
| telegram-desktop † | Telegram messaging desktop client | cask | snap | arch | snap |
| discord † | Voice chat community platform | cask | snap | aur | snap |
| veracrypt † | Disk encryption volume tool | cask | ppa | aur | rpmf |
| qtcreator † | Qt C++ IDE | cask | apt | arch | dnf |
| karabiner-elements | macOS keyboard remapper | cask | — | — | — |
| rectangle | macOS window snapping | cask | — | — | — |

## Linux desktop — Tauri / GTK build deps

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| build-essential / base-devel † | C/C++ build toolchain | clt | apt | arch | dnf |
| file † | File type detection | brew | apt | arch | dnf |
| webkit2gtk 4.1 dev † | WebKitGTK webview library | — | apt | arch | dnf |
| libxdo dev † | X11 input simulation | — | apt | arch | dnf |
| openssl dev † | OpenSSL development headers | — | apt | arch | dnf |
| libayatana-appindicator dev † | System tray indicator library | — | apt | arch | dnf |
| librsvg dev † | SVG rendering library | — | apt | arch | dnf |

## Script-installed tools

| Package | Description | macOS | Debian/Ubuntu | Arch | Fedora |
|---|---|---|---|---|---|
| herdr | Terminal agent session multiplexer | brew | script | script | script |

---

## Keeping this in lockstep

Per [`CLAUDE.md`](../CLAUDE.md) §4, any package added to
`packages/Brewfile` or a `packages/*.list` must add a row **both here and
in [`packages-native.md`](packages-native.md)** in the same change. The
`post-tool-use.sh` hook flags a list edit that didn't touch both docs.
