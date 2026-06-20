---
source: .claude/commands/update.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /update

## Purpose

Run `scripts/update-dotfiles`. "Make this host current with what's
checked in" — refreshes both native packages and the
configurations layer (symlinks, hooks, theme caches).

## Flags

Forwarded as-is to `scripts/update-dotfiles`:

| Flag                       | Effect                                                       |
| -------------------------- | ------------------------------------------------------------ |
| `--dry-run`                | Print every command, run none.                               |
| `--yes`                    | Skip the `git pull --rebase` confirmation prompt.            |
| `--desktop`                | Include the Linux desktop list when refreshing packages.     |
| `--only=packages`          | Packages layer only (git pull → brew/native install + upgrade + AUR/Snap fallback). |
| `--only=configurations`    | Config layer only (symlinks → lefthook → reload caches).     |
| `--only=symlinks` (`--symlinks`) | Symlinks stage only — plant new `configurations/<app>/` links without touching packages or hooks. |

## Behavior

1. Reads `scripts/update-dotfiles`'s head comment (lines 1-26) and
   reports which stages will run.
2. If the user said "what would change" without specifying flags,
   defaults to `--dry-run --yes`. Asks before doing it for real.
3. On real run, captures exit code. Non-zero ⇒ surfaces the
   failing stage name from the script's
   `ERR: stage X failed` line.

## Hard rules

- Never bypasses the `git pull --rebase` confirmation unless the
  user explicitly passes `--yes`.
- Never pushes. The script only ever pulls.
- Doesn't edit any file in the repo.

## Related

- [scripts/update-dotfiles](../../scripts/update-dotfiles)
- [.claude/commands/update.md](../../.claude/commands/update.md)
- [doc/commands/apply.md](apply.md) — bootstrap sibling.
