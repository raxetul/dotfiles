---
source: .claude/commands/migrate-config.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /migrate-config

## Purpose

This command puts the live configuration of an app under dotfiles management. It is the automated form of
hard rule #11 in `CLAUDE.md`. The command does these tasks:

1. It checks the live tree.
2. It moves the files that the user edits by hand into `configurations/<app>/`.
3. It makes symlinks back to the live paths, so the edits stay active.
4. It adds the mapping to `scripts/symlinks.sh`.
5. It verifies the result.

The same procedure put `claude` and `ghostty` under management.

## Arguments

`<app> [path …]` — an app name such as `ghostty`, and optional specific paths. The default scope is everything
under `~/.config/<app>/`. The command also handles dotfiles in the `${HOME}` root (for example `~/.tmux.conf`).
The command keeps the relative layout. A nested `~/.config/<app>/sub/foo` becomes
`configurations/<app>/sub/foo`.

## Behavior

1. **Resolve scope** — list the live files that are the target. Note the layout.
2. **Skip what is already managed** — run `readlink` on each target. If a target already points into
   `${DOTFILES_DIR}`, report it and remove it from the work list. A second run does nothing.
3. **Probe for secrets and runtime state** — keep only the files that the user edits by hand.
   Exclude credential, token, cache, history, session, and backup files. The `claude` migration left
   `.credentials.json`, `history.jsonl`, `projects/`, `sessions/`, and `backups/` in place. Grep the candidates
   for secret patterns and for hardcoded `/home/…` and `/Users/…` paths. Show the keep/skip list.
   Then **wait for confirmation**.
4. **Move (do not copy)** the kept files into `configurations/<app>/`. Keep the relative layout.
5. **Symlink back** with `ln -sfn`, so the live edits keep working. You can link a whole directory as one
   entry when this is simpler (see `scripts::.scripts`).
6. **Register the mapping** in `scripts/symlinks.sh`. Use `COMMON_LINKS`. If the config is for one platform,
   use `DARWIN_LINKS`, `LINUX_LINKS`, or `LINUX_DESKTOP_LINKS`. The `dst` is relative to `${HOME}`
   (rules #1, #11).
7. **Preserve glyphs** — if a line in a moved terminal config looks empty, check it with `xxd` before you
   tidy it (rule #5).
8. **Verify** — make sure these three statements are true:
   - `scripts/symlinks.sh list` shows the new entry.
   - `readlink` on the live path resolves into the repo.
   - `diff` of the original that is still present and the repo copy is empty.
9. **Report** the result and suggest `/commit`. The commit is a `feat(<app>):` change. It touches
   `configurations/<app>/` and `scripts/symlinks.sh`. The command never commits by itself.

## Hard rules

- Do not move a file when you are not sure about its sensitivity. Stop and ask first.
- Do not move credential, cache, history, or session files.
- Move the files. Do not copy them. The live tree must point into the repo. It must not hold a duplicate.
- Write the home directory as `${HOME}` and the repo as `${DOTFILES_DIR}`. Do not write a literal home path
  anywhere. This includes the registered `dst` (rule #10).

## Related

- [.claude/commands/migrate-config.md](../../.claude/commands/migrate-config.md)
  — the source that this doc mirrors.
- [CLAUDE.md](../../CLAUDE.md) — hard rule #11, the procedure that this command automates.
- [scripts/symlinks.sh](../../scripts/symlinks.sh) — the file where you register the new mapping.
- [doc/commands/commit.md](commit.md) — the follow-up command after you verify the migration.
