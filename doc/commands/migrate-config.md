---
source: .claude/commands/migrate-config.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /migrate-config

## Purpose

Bring an app's existing live configuration under dotfiles
management — the automated form of hard rule #12 in `CLAUDE.md`.
Probes the live tree, moves the hand-edited files into
`configurations/<app>/`, symlinks them back so edits keep taking
effect, wires the mapping into `scripts/symlinks.sh`, and
verifies. The same procedure was used to bring `claude` and
`ghostty` under management.

## Arguments

`<app> [path …]` — an app name such as `ghostty`, optionally
followed by specific paths. Default scope is everything under
`~/.config/<app>/`; dotfiles at `${HOME}` root (e.g.
`~/.tmux.conf`) are handled too. Relative layout is preserved:
a nested `~/.config/<app>/sub/foo` lands as
`configurations/<app>/sub/foo`.

## Behavior

1. **Resolve scope** — list the target live files and note the
   layout.
2. **Skip what's already managed** — `readlink` each target;
   anything already pointing into `${DOTFILES_DIR}` is reported
   and dropped from the work list (re-running is a no-op).
3. **Probe for secrets and runtime state** — keep only files
   the user hand-edits; exclude credential, token, cache,
   history, session, and backup artifacts (the `claude` migration
   deliberately left `.credentials.json`, `history.jsonl`,
   `projects/`, `sessions/`, `backups/` behind). Grep candidates
   for secret patterns and hardcoded `/home/…` / `/Users/…`
   paths, present the keep/skip list, then **wait for
   confirmation**.
4. **Move (don't copy)** the kept files into
   `configurations/<app>/`, preserving relative layout.
5. **Symlink back** with `ln -sfn` so live edits keep working;
   a whole directory may be linked as one entry when that's
   cleaner (cf. `scripts::.scripts`).
6. **Register the mapping** in `scripts/symlinks.sh` —
   `COMMON_LINKS`, or `DARWIN_LINKS` / `LINUX_LINKS` /
   `LINUX_DESKTOP_LINKS` when the config is platform-specific.
   The `dst` is `${HOME}`-relative (rules #1, #11).
7. **Preserve glyphs** — `xxd`-check any seemingly-empty line in
   a moved terminal config before tidying (rule #5).
8. **Verify** — `scripts/symlinks.sh list` includes the new
   entry, `readlink` on the live path resolves into the repo,
   and `diff` of the still-present original against the repo
   copy is empty.
9. **Report** the result and suggest `/commit` — a
   `feat(<app>):` change touching `configurations/<app>/` +
   `scripts/symlinks.sh`. Never commits automatically.

## Hard rules

- Never moves a file whose sensitivity is unclear — stops and
  asks first.
- Never moves credential, cache, history, or session
  artifacts.
- Move, don't copy: the live tree ends up pointing into the
  repo, never a duplicate of it.
- References home as `${HOME}` and the repo as
  `${DOTFILES_DIR}` — no literal home paths anywhere,
  including the registered `dst` (rule #11).

## Related

- [.claude/commands/migrate-config.md](../../.claude/commands/migrate-config.md)
  — the source this doc mirrors.
- [CLAUDE.md](../../CLAUDE.md) — hard rule #12, the procedure
  this command automates.
- [scripts/symlinks.sh](../../scripts/symlinks.sh) — where the
  new mapping is registered.
- [doc/commands/commit.md](commit.md) — the suggested follow-up
  once the migration is verified.
