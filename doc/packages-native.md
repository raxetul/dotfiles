---
status: source-of-truth
branch: main
maintainer: raxetul@gmail.com
claude-rule: "Every package added to packages/Brewfile or packages/*.list MUST get a row here in the same change. See CLAUDE.md §6."
---

# Packages — native install reference

This doc is the single lookup table for each package that this repo installs, for each OS.
It is next to the `.list` files that it documents.

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
├── snap.list              # Debian + Fedora fallback (skipped on Arch)
├── script-install.list    # Upstream `curl … | sh` tools, no native pkg anywhere
└── custom-install/        # Per-package before.sh/after.sh hooks (rustup, …)
```

`packages/` is at the repo root next to `configurations/`. The
separation is on purpose. `configurations/` holds the app config files
that the user edits live. `packages/` holds the inventory of what the
setup installs.

setup.sh does six package-related steps:

1. `custom-install/*/before.sh` — register third-party repos, accept
   upstream keys, and create config dirs.
2. native install — the `*.list` pair that matches the detected distro (`*-desktop.list`
   only with `--desktop`), or `brew bundle` on macOS. The script strips inline `# …`
   comments first. On apt, some packages have no install
   candidate on the running release (version-gated entries like `mold`
   on Debian before 12 or Ubuntu before 22.04). The script removes these packages and logs a skip,
   so one missing name does not stop the whole batch.
3. fallbacks — `aur.list` on Arch, `snap.list` on the other distros.
4. `custom-install/*/after.sh` — provision toolchains
   (`rustup default stable`), install release-binary fallbacks when
   the native repo does not have the tool (starship/atuin/claude/lefthook),
   and set the PATH of each tool with a `.path` segment.
5. `script-install.list` — tools that only an upstream
   `curl … | sh` installer ships, and that no package manager has. This step runs
   after the lanes above. `scripts/run-script-installers` probes
   `command -v <bin>` and runs each installer only when the tool is
   still missing (see the section below).
6. plugin bootstrap (vim-plug, TPM, zsh plugins, bash-preexec) +
   symlinks (these are independent of the packages).

For the hook contract, see [`packages/custom-install/README.md`](../packages/custom-install/README.md).

## Install policy (locked)

1. **Native pkg manager first.** macOS → `brew`. Linux → `apt` /
   `pacman` / `dnf` (driven by distro detection in `setup.sh`).
2. **Fallback by distro family** (use it only if the native repo does not have the
   package):

   | Distro family | Primary | Fallback 1 | Fallback 2 |
   |---|---|---|---|
   | Arch (Arch, Manjaro, EndeavourOS, Artix) | pacman | AUR (yay/paru) | Snap |
   | Debian/Ubuntu/Mint | apt | Snap | release `.deb` / PPA |
   | Fedora/RHEL/Rocky/Alma | dnf | Snap | release `.rpm` / COPR / RPM Fusion |
   | openSUSE | zypper | Snap | OBS / release `.rpm` |
   | macOS | brew formula | brew cask | upstream `.dmg` |

   AUR is **Arch-only**. `makepkg`/`yay`/`paru` make `.pkg.tar.zst`
   files that only `pacman` can install. Flatpak is intentionally
   out of scope.

3. **User-scoped footprint.** The only system-wide writes are the writes that the
   package manager does for its normal work. Everything the repo plants is
   under `$HOME` (symlinks, scripts, plugin checkouts).

## How to read the tables

- `—` = not in the default repos of this manager. Read the *Fallback* column.
- `(name)` = the installed binary has a name that is different from the upstream name
  (the script makes an alias for it; see the notes column).
- Use the *Fallback* lines only when the column for your distro is `—`.

---

## Shell + prompt

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| zsh | zsh | zsh | zsh | zsh | — |
| bash | bash | bash | bash | bash | preinstalled everywhere |
| starship | starship | starship | starship | starship | apt fallback via `custom-install/starship/after.sh`: `curl -sS https://starship.rs/install.sh \| sh -s -- --bin-dir ~/.local/bin --yes` |
| atuin | atuin | atuin (23.10+) | atuin | atuin | apt fallback via `custom-install/atuin/after.sh`: upstream installer → `~/.atuin/bin` (NOT `~/.local/bin`); PATH added via the `atuin` segment in `.path` |
| zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | zsh-autosuggestions | git clone → `~/.config/zsh-plugins/` |
| zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | zsh-syntax-highlighting | git clone |
| zsh-history-substring-search | zsh-history-substring-search | zsh-syntax-highlighting (split) | zsh-history-substring-search | zsh-history-substring-search | git clone |
| you-should-use (zsh plugin) | — | — | — | — | git clone `MichaelAquilina/zsh-you-should-use` → `~/.config/zsh-plugins/`; **AUR**: `zsh-you-should-use` |
| bash-preexec | — | — | — | — | single-file dependency for atuin's bash integration; `setup.sh` Step 4 fetches `rcaloras/bash-preexec` → `~/.bash-preexec.sh`, sourced by `.load` before `atuin init bash` |

## File / search tools

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| eza | eza | eza (23.10+) | eza | eza | cargo install eza |
| bat | bat | bat — installed binary is `batcat` on Debian | bat | bat | shell alias `bat=batcat` on Debian/Ubuntu |
| fzf | fzf | fzf | fzf | fzf | — |
| ripgrep | ripgrep | ripgrep | ripgrep | ripgrep | — |
| fd | fd | fd-find — installed binary is `fdfind` on Debian | fd | fd-find | shell alias `fd=fdfind` on Debian/Ubuntu |
| zoxide | zoxide | zoxide (22.04+) | zoxide | zoxide | release binary |
| tldr (tealdeer) | tealdeer | tealdeer | tealdeer | tldr | cargo install tealdeer |
| jq | jq | jq | jq | jq | — |

## Editor stack

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| vim | vim | vim | vim | vim | — |
| neovim | neovim | neovim | neovim | neovim | — |
| tmux | tmux | tmux | tmux | tmux | — |
| vim-plug | — | — | — | — | bootstrap script `curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim` |
| TPM (tmux plugin manager) | — | — | — | — | `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm` |

The `Plug` directives in `configurations/vim/vimrc` declare the vim plugins.
The `@plugin` lines in `configurations/tmux/tmux.conf` declare the tmux plugins.
These configs are the declarative source of truth. On each run,
`scripts/update-dotfiles` reconciles each manager. It installs the declared plugins **and** removes the checkouts
that the config no longer declares (`vim +PlugInstall +PlugClean!`, TPM
`install_plugins` + `clean_plugins`). See CLAUDE.md §13.

## Git + dev tooling

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| git | git | git | git | git | — |
| git-delta | git-delta | git-delta (22.04+) | git-delta | git-delta | release binary |
| gnupg | gnupg | gnupg | gnupg | gnupg | — |
| pinentry-mac | pinentry-mac | n/a | n/a | n/a | macOS-only — sourced via `packages/Brewfile` |
| pinentry-curses | n/a | pinentry-curses | pinentry | pinentry | — |
| lefthook | lefthook | — | — | — | apt/dnf fallback via `custom-install/lefthook/after.sh`: GitHub release binary → `~/.local/bin/lefthook`; **AUR**: `lefthook-bin` |
| shellcheck | shellcheck | shellcheck | shellcheck | ShellCheck | — |
| gh (GitHub CLI) | gh | gh (Ubuntu 22.04+) | github-cli | gh | Debian / RHEL / Rocky / Alma, or to guarantee the latest build: GitHub's official apt/dnf repo at `cli.github.com`; **AUR**: `github-cli` |
| claude (Claude Code) | — | — | — | — | every platform via `custom-install/claude/after.sh`: upstream installer `curl -fsSL https://claude.ai/install.sh \| bash` → `~/.local/bin/claude`; handles platform/arch detection, idempotent on re-run |

## Language toolchains

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| go | go | golang-go | go | golang | — |
| rustup | rustup-init | rustup (23.10+) | rustup | rustup | `curl https://sh.rustup.rs -sSf \| sh`. rust-analyzer is no longer a managed package — add it on demand with `rustup component add rust-analyzer`. |
| mold (Rust linker, Linux only) | — | mold (22.10+ / Debian 12+) | mold | mold (36+) | release tarball from `rui314/mold`; on macOS use system linker (mold links ELF only) |
| nodejs (LTS, 24.x today) | node | nodejs (NodeSource repo) | nodejs | nodejs | NodeSource / volta / nvm |
| python3 | python | python3 | python | python3 | — |
| python (unversioned command) | — | python-is-python3 | python (ships `/usr/bin/python`) | python-unversioned-command | macOS: alias `python=python3` in `configurations/aliases/python.sh` |
| pip | — | python3-pip (ships `pip` + `pip3`) | python-pip (ships `pip` + `pip3`) | python3-pip (VERIFY: ships `/usr/bin/pip`) | macOS: alias `pip=pip3` in `configurations/aliases/python.sh` |
| py (Python launcher) | python-launcher | — | — (AUR: `python-launcher`) | python-launcher (F43+) | apt: alias `py=python3` in `configurations/aliases/python.sh`; **AUR**: `python-launcher` |
| llvm | llvm | llvm | llvm | llvm | — |
| clang-format / clang-tidy | clang-format | clang-format clang-tidy | clang | clang-tools-extra | — |

## Networking / sysadmin

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| arp-scan | arp-scan | arp-scan | arp-scan | arp-scan | — |
| bandwhich | bandwhich | bandwhich (23.04+) | bandwhich | bandwhich | cargo install bandwhich; **AUR**: `bandwhich-bin` |
| bind dnsutils (dig/host/nslookup) | bind | bind9-dnsutils | bind | bind-utils | apt: `dnsutils` was a transitional pkg dropped in Debian 13/trixie — use `bind9-dnsutils` |
| wget | wget | wget | wget | wget | — |
| curl | curl | curl | curl | curl | — |

## Containers / virtualization

Docker on Linux is **commented out by default** in `apt.list`,
`pacman.list`, and `dnf.list`. Each user chooses between rooted, rootless, Docker-Desktop, and
podman. If you mix sources, dpkg and rpm report
file-conflict errors. The "Containers" section of each list shows the
candidate package sets. Uncomment the set that matches your install.

| Package | brew | apt (rooted, distro) | apt (rooted, Docker repo) | apt (rootless) | pacman | dnf (rooted, Fedora) | dnf (rooted, Docker repo) | dnf (rootless) |
|---|---|---|---|---|---|---|---|---|
| docker engine + CLI | docker (CLI only) | docker.io | docker-ce + docker-ce-cli | docker-ce-cli + docker-ce-rootless-extras | docker | moby-engine | docker-ce + docker-ce-cli | docker-ce-cli + docker-ce-rootless-extras |
| docker-buildx | (n/a; in CLI) | docker-buildx | docker-buildx-plugin | docker-buildx-plugin | docker-buildx | (n/a) | docker-buildx-plugin | docker-buildx-plugin |
| docker-compose v2 | docker-compose | (n/a) | docker-compose-plugin | docker-compose-plugin | docker-compose | docker-compose-plugin | docker-compose-plugin | docker-compose-plugin |
| colima (mac docker daemon) | colima | n/a | n/a | n/a | macOS-only |
| lima (colima backend) | lima | n/a | n/a | n/a | macOS-only |
| libvirt (Linux server) | n/a | libvirt-daemon-system | libvirt | libvirt | — |
| qemu (Linux server) | n/a | qemu-system | qemu-base | qemu-kvm | — |

## Filesystem / misc

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| sqlite (interactive REPL) | sqlite | sqlite3 | sqlite | sqlite | — |
| coreutils (GNU) | coreutils | preinstalled (GNU) | preinstalled (GNU) | preinstalled (GNU) | macOS-only need |
| zip | zip | zip | zip | zip | — |
| unzip | unzip | unzip | unzip | unzip | — |
| asciinema | asciinema | asciinema | asciinema | asciinema | — |

## AI / LLM tooling

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| opencode | anomalyco/tap/opencode | — | — | — | No apt/pacman/dnf package anywhere. macOS: `custom-install/opencode/before.sh` taps + trusts `anomalyco/tap` (brew refuses to load ANY third-party tap's formula until trusted — a blanket policy, not a signal specific to this tap; confirmed `qmk/qmk` hits the identical gate. `sst/tap` exists and is still maintained but its formula points at the same `github.com/anomalyco/opencode` release artifacts and trips the same untrusted-tap gate via lineage tracking, so it buys nothing over tapping `anomalyco/tap` directly. Trust decision approved by the lead 2026-09-02). Linux: `custom-install/opencode/after.sh` runs the upstream installer `curl -fsSL https://opencode.ai/install \| bash -s -- --no-modify-path` → `~/.opencode/bin`; PATH added via the `opencode` segment in `.path` (Linux only — macOS gets it via brew's shellenv already on PATH) |
| ollama | ollama | — | ollama | ollama | apt/Debian has no package (only `python3-ollama`, a client library, not the server). Debian/Ubuntu fallback via `custom-install/ollama/after.sh`: `sudo snap install ollama` — NOT via `packages/snap.list`, since that list installs unconditionally on Fedora too, which already has a native `dnf` package, and would double-install there. The upstream `curl \| sh` installer was deliberately rejected as the Linux fallback: it installs system-wide (`/usr/local`), creates a system user, and writes a systemd unit to `/etc/systemd/system/` — the wrong footprint for a package binary regardless of where the dotfiles repo itself lives. macOS: `custom-install/ollama/{before,after}.sh` migrate this Mac off the upstream Ollama.app installer — before.sh quits the running `.app`-managed server, after.sh runs `brew services start ollama` (approved by the lead 2026-09-02). `~/.ollama` (20GB of models) is never touched by any of this — `OLLAMA_MODELS` defaults there regardless of which binary runs the server |

## Fonts

| Package | brew | apt | pacman | dnf | Fallback |
|---|---|---|---|---|---|
| Font Awesome | font-fontawesome | fonts-font-awesome | ttf-font-awesome | fontawesome-fonts | — |
| JetBrains Mono | font-jetbrains-mono | fonts-jetbrains-mono | ttf-jetbrains-mono | jetbrains-mono-fonts | — |
| JetBrains Mono Nerd Font | font-jetbrains-mono-nerd-font | — | ttf-jetbrains-mono-nerd | — | apt/dnf: `custom-install/jetbrains-mono-nerd-font/after.sh` fetches the upstream release zip into `~/.local/share/fonts/` + `fc-cache -f` (idempotent, user-scoped); **AUR**: `nerd-fonts-jetbrains-mono` |

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
| telegram-desktop | — | telegram-desktop | — | not in Debian apt (trixie) or Fedora default repos; **Arch**: pacman `telegram-desktop`; Debian/Ubuntu & Fedora: Snap `telegram-desktop` |
| discord | — | — | — (RPM Fusion: `discord`) | **AUR**: `discord`; Debian/Ubuntu: Snap `discord` or `.deb` from discord.com; Fedora: enable RPM Fusion |
| veracrypt | — (PPA `unit193/encryption`) | — | — | **AUR**: `veracrypt`; Debian: PPA or release `.deb` from veracrypt.fr; Fedora: RPM Fusion or release `.rpm` |
| qtcreator | qtcreator | qtcreator | qt-creator | — |

## Linux desktop — Tauri / GTK build dependencies

(The setup installs these only when profile = desktop.) These are the libraries that you need to
**build** a Tauri v2 (WebKitGTK-backed) desktop app on Linux. The apt row is
the official Debian prerequisite set of Tauri, word for word. `curl` and `wget` are already
in the baseline lists, so the `*-desktop.list` files do not repeat them.

On **macOS**, Tauri does not use any of these libraries. It renders through the system
WebKit (WKWebView) and needs only the Xcode Command Line Tools (`xcode-select
--install`). These tools are not a Homebrew formula. The `brew` column is therefore `n/a`
for the GTK-specific rows.

| Package (purpose) | apt | pacman | dnf | brew |
|---|---|---|---|---|
| C toolchain | build-essential | base-devel | (group: *Development Tools* / *C Development Tools and Libraries*) | Xcode CLT (`xcode-select --install`) |
| file (type detection) | file | file | file | file |
| WebKitGTK 4.1 dev | libwebkit2gtk-4.1-dev | webkit2gtk-4.1 | webkit2gtk4.1-devel | n/a (system WebKit) |
| libxdo dev (input sim) | libxdo-dev | xdotool (ships libxdo) | libxdo-devel | n/a |
| OpenSSL dev | libssl-dev | openssl | openssl-devel | (openssl@3, but Tauri on mac uses system TLS) |
| Ayatana AppIndicator dev (tray) | libayatana-appindicator3-dev | libayatana-appindicator ⚠️ | libayatana-appindicator-gtk3-devel ⚠️ | n/a |
| librsvg dev (SVG icons) | librsvg2-dev | librsvg | librsvg2-devel | n/a |

⚠️ **VERIFY the AppIndicator package name** on Arch/Fedora. The Tauri docs
have shown both the ayatana fork (`libayatana-appindicator*`) and the older
`libappindicator-gtk3*`. The apt name is confirmed against the install
command of the user. The pacman and dnf equivalents are best-effort names.
Check them against the current repos of your distro before you use them.

## macOS GUI bridge (`packages/Brewfile`)

These apps ship only as Cocoa bundles. Homebrew casks are the only practical
install path. `setup.sh` runs the Brewfile again on each run.

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

## Script-installed tools (`packages/script-install.list`)

This is the last-resort lane for tools that only an upstream shell
installer (`curl … | sh`) distributes, and that have no package in brew/apt/pacman/dnf/snap/
aur. `scripts/run-script-installers` runs the installer of an entry **only**
when the native lanes did not already provide the binary. It first probes
`command -v <bin>` and skips each tool that is already on PATH. A
**supported OS whose package manager ships the tool uses that package**,
not the remote script. For example, macOS installs `herdr` from the Brewfile and
this lane does nothing there. Only Linux (no native pkg) runs the installer.

This lane runs remote code as your user. The list pins and
reviews each entry. Use installers that put the tool in `~/.local/bin`
(already on PATH, user-scoped, easy to remove). The script writes the output of each run to
`~/.local/state/dotfiles/script-install.log` and to the terminal. The state ledger records each install
as `mgr=script`.

| Tool | Probe binary | brew | apt / pacman / dnf | Script installer |
|---|---|---|---|---|
| herdr (agent multiplexer) | `herdr` | herdr | — / — / — | `curl -fsSL https://herdr.dev/install.sh \| sh` |

---

## Updating this document

**Hard rule** (see [`CLAUDE.md`](../CLAUDE.md) §7): when you add a package
to `packages/Brewfile` or any `packages/*.list`, you
**must** add a row in the matching section above in the same commit.
Fill all four manager columns of each new row (or write `—` and add a *Fallback*
note). The `post-tool-use.sh` hook shows a warning when an edit to those files
did not also change this doc.

If you cannot find a native package for a Linux distro, do these steps:

1. Check AUR first (Arch only): `https://aur.archlinux.org/packages?K=<name>`.
2. Check Snap: `snap find <name>`.
3. Check the upstream releases. Most projects ship a `.deb`, a `.rpm`, and a tarball.
4. As a last resort, use a language-specific installer (`cargo install`,
   `go install`, `pipx install`). Write a note in the *Fallback* column.

Do not use Flatpak. The policy puts it out of scope.
