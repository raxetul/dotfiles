---
status: source-of-truth
maintainer: raxetul@gmail.com
claude-rule: "The --light profile is documented here and MUST be kept in lockstep with LIGHT_LINKS in scripts/symlinks.sh and the PROFILE/WITH_SHELL gates in setup.sh. LIGHT_LINKS is a hand-picked subset, never a filter over COMMON_LINKS — adding an entry to COMMON_LINKS must not widen the light profile by accident."
---

# `--light` — a second account on an already-provisioned machine

This is **axis 2** of the two-axis install model. For axis 1 (the shared
repo itself, `/opt/dotfiles`, installed light or hard) and for the
`install.sh` one-liner that drives both, see
[opt-dotfiles-install.md](opt-dotfiles-install.md):

```
AXIS 1 — the shared repo at /opt/dotfiles, owned root:dotfiles
         installed "light" (config only) or "hard" (default: + packages)
AXIS 2 — each user attaches that repo to their own shell (this doc),
         again light or hard. Everything user-specific -> $HOME/.dotfiles/
```

Use this profile when the machine already runs these dotfiles under one account.
A **second user** on the same machine can then get the shell environment.
This user does not install anything again. The machine is typically a Linux server.

```
./setup.sh --light                 # config symlinks only
./setup.sh --light --with-shell    # …and switch the login shell to zsh
```

## What it does and does not do

| Step | Full install | `--light` | Why |
| --- | --- | --- | --- |
| 1 Homebrew | ✅ | 🔴 skip | the first account already installed the packages |
| 1.5 custom-install `before.sh` | ✅ | 🔴 skip | same |
| 2 native packages | ✅ | 🔴 skip | a second user without admin rights cannot use `sudo` for these steps |
| 3 AUR / Snap fallbacks | ✅ | 🔴 skip | same |
| 3.5 custom-install `after.sh` | ✅ | 🔴 skip | same |
| 3.6 script installers | ✅ | 🔴 skip | same |
| 4 vim-plug, bash-preexec | ✅ | 🟢 run | user-scope, and vim + atuin are in the light set |
| 4 TPM (tmux) | ✅ | 🔴 skip | `tmux.conf` is not linked, so TPM has nothing to read |
| 4.5 agent-skills mirror | ✅ | 🔴 skip | skills feed Claude and opencode, and neither is linked. The step also creates a private GitHub repo under the second user's account |
| 5 symlinks | all | 🟢 `LIGHT_LINKS` only | see below |
| 6 `chsh` to zsh | ✅ | 🔵 opt-in via `--with-shell` | needs root or the password of that account on a server, and the user can want to keep the current shell |
| 7 lefthook | ✅ | 🔴 skip | hooks for work on *this repo*, not for use of it |

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

Aliases do not need an entry of their own. The two rc files source
`configurations/aliases/*.sh`, so the aliases come with the rc files.

**Deliberately excluded:** `claude/*`, `opencode/*`, `nvim`, `tmux`, `ghostty`,
`gpg`, `cargo`, and the agent-skills symlinks.

## How the selection works

When `DOTFILES_LIGHT=1` is set, `_active_links()` in `scripts/symlinks.sh` returns
`LIGHT_LINKS` and returns early. It adds no OS-specific entries and no skill links.
`setup.sh` exports the variable when `PROFILE=light`. This is the same method as
`DOTFILES_DESKTOP=1` for `--desktop`.

🔴 `LIGHT_LINKS` is a **hand-picked subset, not a filter over `COMMON_LINKS`**.
This is on purpose. If the script derived the set, each new entry in `COMMON_LINKS`
would widen the light profile without notice. The profile must keep a small,
reviewed set of links. To add an entry to the light profile, edit `LIGHT_LINKS`
and this doc in the same change.

## Why not reuse `--server`

`PROFILE` already defaults to `"server"`, so `--server` today means "the normal
install". If you narrow `--server`, the primary user loses Claude and the other
tools without notice. `--light` is a new profile that adds to the existing ones.

## Verifying before you run it

```sh
DOTFILES_LIGHT=1 ./scripts/symlinks.sh list   # exactly what would be planted
DRY_RUN=1 ./setup.sh --light                  # which steps would run
```

The uninstall process does not change. `scripts/uninstall.sh` reads the realized-state ledger.
It removes the links that the account planted.
