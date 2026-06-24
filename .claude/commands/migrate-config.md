---
description: Migrate a live ~/.config/<app> config into the dotfiles repo — probe, move, symlink back, wire COMMON_LINKS, verify.
argument-hint: <app> [path …]
allowed-tools: Bash(ls*), Bash(find*), Bash(readlink*), Bash(file*), Bash(stat*), Bash(grep*), Bash(diff*), Bash(mkdir*), Bash(mv*), Bash(ln*), Bash(xxd*), Read, Edit
---

Bring an app's existing live configuration under dotfiles management,
exactly as hard rule #12 in `CLAUDE.md` prescribes. Target: `$ARGUMENTS`
(an app name such as `ghostty`, optionally followed by specific paths;
default scope is everything under `~/.config/<app>/`).

Never run destructive steps blindly — confirm the plan before moving
files. The home dir is always referenced as `${HOME}`, the repo root as
`${DOTFILES_DIR}` (default `${HOME}/gel-ort/dotfiles`).

Procedure:

1. **Resolve scope.** From `$ARGUMENTS`, determine the app and the live
   path(s). Default to `~/.config/<app>/`; also handle dotfiles at
   `${HOME}` root (e.g. `~/.tmux.conf`). List them with `find` and note
   the layout — a nested `~/.config/<app>/sub/foo` must keep its
   relative shape as `configurations/<app>/sub/foo`.

2. **Skip what's already managed.** For each target, `readlink` it: if
   it already points into `${DOTFILES_DIR}`, report "already managed"
   and drop it from the work list. (Ghostty, for instance, is already
   linked — re-running must be a no-op.)

3. **Probe for secrets and runtime state — STOP and ask if unsure.**
   Move only files the user hand-edits. Exclude credential, token,
   cache, history, session, and backup artifacts (the `claude`
   migration deliberately left `.credentials.json`, `history.jsonl`,
   `projects/`, `sessions/`, `backups/` behind). Grep candidates for
   obvious secrets (`token`, `secret`, `api[_-]?key`, `password`,
   `BEGIN .*PRIVATE KEY`) and for hardcoded `/home/…` / `/Users/…`
   paths that violate rule #11. Present the keep/skip list and any
   secret/path findings, then **wait for confirmation**.

4. **Move (don't copy)** each kept file into `configurations/<app>/`,
   preserving its relative layout: `mkdir -p` the destination dir, then
   `mv` the live file into the repo.

5. **Symlink it back** so live edits keep working:
   `ln -sfn "${DOTFILES_DIR}/configurations/<app>/<rel>" "${HOME}/<rel>"`.
   A whole directory may be linked as a single entry when that's
   cleaner (cf. `scripts::.scripts` / `configurations/claude/scripts`).

6. **Register the mapping** in `scripts/symlinks.sh`: add
   `"configurations/<app>/<rel>::<dst-relative-to-HOME>"` to
   `COMMON_LINKS` (or `DARWIN_LINKS` / `LINUX_LINKS` /
   `LINUX_DESKTOP_LINKS` when the config is platform-specific). The
   `dst` is relative to `${HOME}` and must not contain a literal home
   path (rules #1, #11).

7. **Preserve Nerd Font / PUA glyphs** (rule #5). If the moved file is
   a terminal config (starship, tmux, ghostty, waybar, vim status
   lines), `xxd`-check any line that looks empty before "tidying" — the
   edit channel may be hiding live glyph bytes.

8. **Verify**:
   - `scripts/symlinks.sh list` includes the new entry.
   - `readlink "${HOME}/<rel>"` resolves into `${DOTFILES_DIR}`.
   - For a still-present original, `diff` repo-vs-live is empty.

9. **Report** the result and suggest `/commit` (a `feat(<app>):` change
   touching `configurations/<app>/` + `scripts/symlinks.sh`). Do not
   commit automatically unless asked.
