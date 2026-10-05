---
source: .claude/commands/update.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /update

## Purpose

This command runs `scripts/update-dotfiles`. It makes this host current with the checked-in files. It refreshes
the native packages and the configurations layer (symlinks, hooks, theme caches).

## Flags

The command forwards the flags without change to `scripts/update-dotfiles`:

| Flag                       | Effect                                                       |
| -------------------------- | ------------------------------------------------------------ |
| `--dry-run`                | Print every command, run none.                               |
| `--yes`                    | Skip the `git pull --rebase` confirmation prompt.            |
| `--desktop`                | Include the Linux desktop list when refreshing packages.     |
| `--only=packages`          | Packages layer only (git pull → brew/native install + upgrade + AUR/Snap fallback). |
| `--only=configurations`    | Config layer only (symlinks → lefthook → reload caches).     |
| `--only=symlinks` (`--symlinks`) | Symlinks stage only — plant new `configurations/<app>/` links without touching packages or hooks. |
| `--only=cache-clean`       | On-demand disk reclaim via `scripts/clean-package-cache.sh`: package-manager caches + orphan removal + language-tool caches. Never runs in a normal `/update`. Honors `--dry-run` / `--yes`. |

## Behavior

1. The agent reads the head comment of `scripts/update-dotfiles` (lines 1-26). It reports which stages run.
2. If the user asks "what would change" and gives no flags, the agent uses `--dry-run --yes`. The agent asks
   before it does the real run.
3. The agent records the exit code of the real run. If the code is not zero, the agent shows the name of the
   failed stage. The name is in the `ERR: stage X failed` line of the script.

## Hard rules

- Do not skip the `git pull --rebase` confirmation. Skip it only when the user passes `--yes`.
- Do not push. The script only pulls.
- Do not edit any file in the repo.

## Related

- [scripts/update-dotfiles](../../scripts/update-dotfiles)
- [.claude/commands/update.md](../../.claude/commands/update.md)
- [doc/commands/apply.md](apply.md) — the bootstrap sibling.
