---
source: .claude/commands/apply.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /apply

## Purpose

Run `./setup.sh` after the agent has shown the user exactly what
each step does. This is the bootstrap command — installs Homebrew
on macOS if missing, installs packages via the native package
manager (`brew bundle` on macOS; `apt`/`pacman`/`dnf` on Linux),
bootstraps user-scope plugin managers, plants symlinks via
`scripts/symlinks.sh`, swaps the login shell to zsh, installs
lefthook git hooks.

## Flags

`/apply` itself takes no arguments. The agent forwards what the
user specifies inside the chat:

| Flag        | Effect                                                       |
| ----------- | ------------------------------------------------------------ |
| `--desktop` | Linux only — adds the desktop bucket (sway, waybar, GUI apps + Wayland symlinks). |
| `--server`  | Linux only — baseline only (default).                        |
| `--update`  | Upgrade already-installed packages (`brew upgrade` / `apt upgrade` / `pacman -Syu` / `dnf upgrade`). |

## Behavior

1. Reads `./setup.sh` end-to-end and quotes each numbered "Step N"
   header so the user can audit before invoking.
2. Detects profile from user input. Defaults to baseline (Linux
   server profile, or macOS where the flag is irrelevant).
3. Prints which steps will run / skip on this OS. Calls out anything
   that needs `sudo` (chsh, `/etc/shells`, native install, optional
   `snap install`).
4. Waits for confirmation. On approval, invokes `./setup.sh` with
   the flags.
5. Streams output; on non-zero exit, surfaces the failing step.

## Hard rules

- Never runs `setup.sh --update` unless the user explicitly asks.
  Default invocations install missing packages but don't upgrade
  ones already at older versions.
- Never edits the repo. This command is runtime-only.

## Related

- [setup.sh](../../setup.sh)
- [.claude/commands/apply.md](../../.claude/commands/apply.md)
- [doc/commands/update.md](update.md) — the "refresh, don't
  bootstrap" sibling.
