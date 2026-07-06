---
description: Audit symlinked configs for drift — commit/push new files that already live in the repo, and surface live-folder files that could be migrated into dotfiles.
allowed-tools: Read, Bash(git*), Bash(scripts/symlinks.sh*), Bash(ls*), Bash(readlink*), Bash(find*), Bash(test*), Bash(cat*)
---

Reconcile the live `$HOME` config tree against what the dotfiles repo
manages. Two failure modes this catches:

- **Tracked-repo drift** — a directory symlink (e.g.
  `configurations/claude/commands`, `configurations/claude/scripts`,
  `scripts`) points a live dir *into* the repo, so files created through
  the live path land in the repo but stay **untracked in git**. These
  silently work on this host and vanish on a fresh clone (hard rule #13).
  → stage, commit (Conventional Commits), and push them.
- **Unmanaged siblings** — a *file* symlink (e.g.
  `configurations/ghostty/config`) links one file inside a live folder;
  any *other* file the app dropped next to it (`~/.config/ghostty/…`) is
  **not** in the repo. → surface it as a migration candidate and ask.

All git work targets `${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}`. Never
touch credential/cache/history/state artifacts (per hard rule #12 step 1).

Procedure:

1. **Resolve the repo root and mapping.** Set
   `REPO="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"`. Read the active
   symlink mapping with `scripts/symlinks.sh list` (one `src::dst` per
   line, `src` repo-relative, `dst` `$HOME`-relative). Confirm each live
   `dst` actually resolves into `$REPO` via `readlink`; note any that
   don't (broken/unmanaged) but don't fix them here.

2. **Case A — tracked-repo drift (commit + push).**
   - For every entry whose `src` is a **directory**, the live `dst` is a
     dir symlink into the repo, so new files appear inside `$REPO/<src>`.
     Run `git -C "$REPO" status --porcelain` to enumerate untracked and
     modified files (this is the authoritative view — it already includes
     those dir-symlink additions plus any other repo edits).
   - Show the changes grouped by area. If there are none, say the repo is
     in sync and skip to step 3.
   - **Enforce companion rules before committing:** if the change adds a
     `packages/*.list` / `Brewfile` entry, `doc/packages-native.md` must
     move too (hard rule #4); a new `configurations/claude/commands/*` or
     `CLAUDE.md` change is exactly the rule #13 case this command exists
     to fix — stage it. Flag, don't silently commit, anything that looks
     like a secret or runtime-state file.
   - Draft a **Conventional Commit** message (`feat`/`fix`/`chore`/
     `docs`/…, optional scope) summarizing the staged set. Show the
     files + message and **confirm with the user**.
   - On confirmation: `git -C "$REPO" add <paths>`, commit with the
     drafted message, then `git -C "$REPO" push`. Report the resulting
     commit and push status. (Push is outward-facing — never push without
     the confirmation above.)

3. **Case B — unmanaged siblings (ask to migrate).**
   - For every entry whose `src` is a **file**, take the live parent dir
     `dirname "$HOME/<dst>"` and list its contents. A candidate is any
     entry that is **not** the managed symlink itself, **not** another
     symlink already resolving into `$REPO`, and **not** an obvious
     secret/cache/state file (`*.bak.*`, `history*`, `*credentials*`,
     `sessions/`, `projects/`, sockets, lockfiles).
   - Collect the candidates across all file-symlink entries. If none,
     say the live folders are clean.
   - Present the list and **ask the user which (if any) to bring under
     management**. For each one they pick, run the `/migrate-config`
     procedure (probe → move into `configurations/<app>/` → symlink back
     → wire `COMMON_LINKS` in `scripts/symlinks.sh` → verify). Do **not**
     migrate anything without an explicit pick.

4. **Report.** Summarize: what was committed/pushed (commit hash), what
   migration candidates were found, and what the user chose to migrate or
   defer. Leave anything not confirmed untouched.
