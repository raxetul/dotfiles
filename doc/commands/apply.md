---
source: .claude/commands/apply.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /apply

## Purpose

Run `./setup.sh` after the agent has shown the user exactly what
each step does. This is the bootstrap command — installs Nix if
missing, enables flakes, runs `home-manager switch`, swaps the
login shell to zsh, installs Homebrew on macOS, and installs
distro-native packages on Linux.

## Flags

`/apply` itself takes no arguments. The agent forwards what the
user specifies inside the chat:

| Flag         | Effect                                                       |
| ------------ | ------------------------------------------------------------ |
| `--desktop`  | Linux only — adds the desktop bucket (sway, waybar, GUI apps). |
| `--server`   | Linux only — server bucket (default).                        |
| `--update`   | Bumps `flake.lock` before switching (calls `nix flake update`). |

## Behavior

1. Reads `./setup.sh` end-to-end and quotes each numbered "Step N"
   header so the user can audit before invoking.
2. Detects active profile from `$DOTFILES_PROFILE`, defaults to
   `server`. User-supplied `--desktop` overrides.
3. Prints which steps will run / skip on this OS. Calls out anything
   that needs `sudo` (chsh, `/etc/shells`, distro-native install).
4. Waits for confirmation. On approval, invokes `./setup.sh` with
   the flags.
5. Streams output; on non-zero exit, surfaces the failing step.

## Hard rules

- Never runs `setup.sh --update` unless the user explicitly asks.
  Default invocations stay reproducible against `flake.lock`.
- Never edits the repo. This command is runtime-only.

## Related

- [setup.sh](../../setup.sh)
- [.claude/commands/apply.md](../../.claude/commands/apply.md)
- [doc/commands/update.md](update.md) — the "refresh, don't
  bootstrap" sibling.
