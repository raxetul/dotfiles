---
source: .claude/commands/apply.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /apply

## Purpose

This command runs `./setup.sh`. Before it runs, the agent shows the user what each step does.
This is the bootstrap command. It does these tasks:

- It installs Homebrew on macOS if Homebrew is not present.
- It installs packages with the native package manager (`brew bundle` on macOS; `apt`/`pacman`/`dnf` on Linux).
- It bootstraps the user-scope plugin managers.
- It creates symlinks with `scripts/symlinks.sh`.
- It changes the login shell to zsh.
- It installs the lefthook git hooks.

## Flags

`/apply` takes no arguments. The agent forwards the flags that the user gives in the chat:

| Flag        | Effect                                                       |
| ----------- | ------------------------------------------------------------ |
| `--desktop` | Linux only — adds the desktop bucket (sway, waybar, GUI apps + Wayland symlinks). |
| `--server`  | Linux only — baseline only (default).                        |
| `--update`  | Upgrade already-installed packages (`brew upgrade` / `apt upgrade` / `pacman -Syu` / `dnf upgrade`). |

## Behavior

1. The agent reads `./setup.sh` from start to end. It quotes each numbered "Step N" header, so the user can check
   the steps before the run.
2. The agent finds the profile from the user input. The default is the baseline (the Linux server profile, or
   macOS, where the flag has no effect).
3. The agent prints which steps run and which steps skip on this OS. It marks each step that needs `sudo`
   (chsh, `/etc/shells`, native install, optional `snap install`).
4. The agent waits for confirmation. After the user approves, the agent runs `./setup.sh` with the flags.
5. The agent shows the output as it comes. If the exit code is not zero, the agent shows the step that failed.

## Hard rules

- Do not run `setup.sh --update` unless the user asks for it. A default run installs the missing packages.
  It does not upgrade the packages that have an older version.
- Do not edit the repo. This command works at runtime only.

## Related

- [setup.sh](../../setup.sh)
- [.claude/commands/apply.md](../../.claude/commands/apply.md)
- [doc/commands/update.md](update.md) — the sibling command that refreshes a host. It does not bootstrap it.
