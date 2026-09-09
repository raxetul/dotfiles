---
status: source-of-truth
maintainer: raxetul@gmail.com
claude-rule: "The --light profile is documented here and MUST be kept in lockstep with LIGHT_LINKS in scripts/symlinks.sh and the PROFILE/WITH_SHELL gates in setup.sh. LIGHT_LINKS is a hand-picked subset, never a filter over COMMON_LINKS — adding an entry to COMMON_LINKS must not widen the light profile by accident."
---

# `--light` — a second account on an already-provisioned machine

This is **axis 2** of the two-axis install model — see
[opt-dotfiles-install.md](opt-dotfiles-install.md) for axis 1 (the shared
repo itself, `/opt/dotfiles`, installed light or hard) and the
`install.sh` one-liner that drives both:

```
AXIS 1 — the shared repo at /opt/dotfiles, owned root:dotfiles
         installed "light" (config only) or "hard" (default: + packages)
AXIS 2 — each user attaches that repo to their own shell (this doc),
         again light or hard. Everything user-specific -> $HOME/.dotfiles/
```

For the case where the machine already runs these dotfiles under one account
and a **second user** on the same box wants the shell environment without
re-installing anything. Typically a Linux server.

```
./setup.sh --light                 # config symlinks only
./setup.sh --light --with-shell    # …and switch the login shell to zsh
```

## What it does and does not do

| Step | Full install | `--light` | Why |
| --- | --- | --- | --- |
| 1 Homebrew | ✅ | 🔴 skip | packages already installed by the first account |
| 1.5 custom-install `before.sh` | ✅ | 🔴 skip | same |
| 2 native packages | ✅ | 🔴 skip | a second, non-admin user cannot `sudo` these anyway |
| 3 AUR / Snap fallbacks | ✅ | 🔴 skip | same |
| 3.5 custom-install `after.sh` | ✅ | 🔴 skip | same |
| 3.6 script installers | ✅ | 🔴 skip | same |
| 4 vim-plug, bash-preexec | ✅ | 🟢 run | user-scope, and vim + atuin are in the light set |
| 4 TPM (tmux) | ✅ | 🔴 skip | `tmux.conf` is not linked, so TPM has nothing to read |
| 4.5 agent-skills mirror | ✅ | 🔴 skip | skills feed Claude/opencode, neither is linked — and it would create a private GitHub repo under the second user's account |
| 5 symlinks | all | 🟢 `LIGHT_LINKS` only | see below |
| 6 `chsh` to zsh | ✅ | 🔵 opt-in via `--with-shell` | needs root or that account's password on a server, and the user may want to keep their shell |
| 7 lefthook | ✅ | 🔴 skip | hooks for developing *this repo*, not for consuming it |

## The link set — 17 entries

```
zsh/zshrc            → ~/.zshrc          shell + sources configurations/aliases/*
bash/bashrc          → ~/.bashrc         same, for bash
starship.toml        → ~/.config/starship.toml
atuin/config.toml    → ~/.config/atuin/config.toml
themes/bat/…tmTheme  → ~/.config/bat/themes/…      the aliases use bat
git/  (5 files)      → ~/.config/git/…   config, workspace override, commit
                                          template, commit-msg + pre-commit hooks
vim/  (5 files)      → ~/.vimrc, ~/.vim/ftplugin/…
herdr/config.toml    → ~/.config/herdr/config.toml
scripts              → ~/.scripts        puts scripts/ on PATH
```

Aliases need no entry of their own: `configurations/aliases/*.sh` is sourced
from the two rc files, so it arrives with them.

**Deliberately excluded:** `claude/*`, `opencode/*`, `nvim`, `tmux`, `ghostty`,
`gpg`, `cargo`, and the agent-skills symlinks.

## How the selection works

`DOTFILES_LIGHT=1` makes `_active_links()` in `scripts/symlinks.sh` return
`LIGHT_LINKS` and return early — no OS-specific entries and no skill links.
`setup.sh` exports it when `PROFILE=light`, the same shape as
`DOTFILES_DESKTOP=1` for `--desktop`.

🔴 `LIGHT_LINKS` is a **hand-picked subset, not a filter over `COMMON_LINKS`**.
That is deliberate: if it were derived, every future addition to `COMMON_LINKS`
would silently widen the light profile, and the point of the profile is a small
reviewed surface. Adding something to light means editing `LIGHT_LINKS` and this
doc together.

## Why not reuse `--server`

`PROFILE` already defaults to `"server"`, so `--server` today means "the normal
install". Narrowing it would silently strip Claude and the rest from the primary
user's setup. `--light` is a new, additive profile.

## Verifying before you run it

```sh
DOTFILES_LIGHT=1 ./scripts/symlinks.sh list   # exactly what would be planted
DRY_RUN=1 ./setup.sh --light                  # which steps would run
```

Uninstall is unchanged: `scripts/uninstall.sh` walks the realized-state ledger,
so it removes whatever that account actually planted.
