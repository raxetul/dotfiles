---
source: .claude/commands/update.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /update

## Purpose

Run `scripts/update.sh`. "Make this host current with what's
checked in" — refreshes both flake-pinned packages and the
configurations layer (symlinks, hooks, theme caches).

## Flags

Forwarded as-is to `scripts/update.sh`:

| Flag                       | Effect                                                       |
| -------------------------- | ------------------------------------------------------------ |
| `--dry-run`                | Print every command, run none.                               |
| `--yes`                    | Skip the `git pull --rebase` confirmation prompt.            |
| `--no-flake`               | Skip `nix flake update`; replay against the current lock.    |
| `--only=packages`          | Packages layer only (git pull → HM switch → brew/native).    |
| `--only=configurations`    | Config layer only (backup-check → lefthook → reload caches). |

## Behavior

1. Reads `scripts/update.sh`'s head comment (lines 1-26) and
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

- [scripts/update.sh](../../scripts/update.sh)
- [.claude/commands/update.md](../../.claude/commands/update.md)
- [doc/commands/apply.md](apply.md) — bootstrap sibling.
