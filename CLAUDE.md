# Dotfiles — agent ground rules

Scope: this file applies to any work an agent does inside this repo
(`raxetul/dotfiles`). Repo-local; nothing here is promoted to
`~/.claude/`. If you want to lift a rule out of this repo into a
global one, see [doc/agentic-promotion.md](doc/agentic-promotion.md).

## Hard rules

1. **Any new app config goes under `configurations/<app>/`** and is
   symlinked into the live tree by `scripts/symlinks.sh`. Add the
   mapping to the `COMMON_LINKS` (or platform-specific) array in that
   script — never duplicate config content inline in setup code.
   Edits in `configurations/` take effect immediately, no re-run needed.
2. **Commit messages follow Conventional Commits.** Types: `feat`,
   `fix`, `refactor`, `chore`, `docs`, `style`, `perf`, `build`,
   `ci`, `test`, `revert`. Scope is optional but encouraged
   (`feat(gpg): …`, `docs(roadmap): …`). The `commit-msg` lefthook
   rejects anything that doesn't match `^(<type>)(\(<scope>\))?!?: <subject>`.
3. **Line length is 120 columns.** Never collapse a multi-line
   construct (shell heredoc, YAML loop, JSON dict) into one line just
   because it would fit — preserve the user's line breaks. This rule
   is repeated in the user's global `~/.claude/CLAUDE.md`; it's loud
   here because most of this repo is heavily multi-line by design.
4. **Keep `doc/packages-native.md` in lockstep with the install
   lists.** Adding a package to `packages/Brewfile` or any
   `packages/*.list` (`apt.list`, `apt-desktop.list`, `pacman.list`,
   `pacman-desktop.list`, `dnf.list`, `dnf-desktop.list`, `aur.list`,
   `snap.list`) requires a matching row in the right section of
   [`doc/packages-native.md`](doc/packages-native.md) in the same
   change. Fill every manager column (brew / apt / pacman / dnf)
   — `—` is fine when the package isn't in that repo, but then the
   *Fallback* column must say how it gets installed there. The
   `post-tool-use.sh` hook will flag a `Write`/`Edit` to a list
   that didn't touch the doc in the same turn.
5. **Preserve Nerd Font / PUA glyphs in `configurations/starship/starship.toml`
   (and any other terminal config that uses them: tmux, ghostty,
   waybar, vim status lines).** The prompt string, `[os.symbols]`,
   `[directory.substitutions]`, every `symbol = "…"`, the powerline
   separators `       ` (U+E0B0 / U+E0B4 / U+E0B6), the prompt
   chevrons `❯` `❮` (U+276F / U+276E), the clock glyph in
   `cmd_duration`, and the time-icon glyph in `[time].format` are
   load-bearing — stripping them produces a broken prompt with
   visible empty `[]` boxes.
   - Some agent input/output channels silently normalize Private Use
     Area codepoints (U+E000–U+F8FF, plus most U+F000–U+FFFF Nerd
     Font ranges) to empty strings. **If you can't see a glyph in
     the diff view of this conversation, assume it's there in the
     file and don't "tidy" it.** Hex-check with `xxd` before
     concluding a line is empty.
     ```sh
     sed -n '78p' configurations/starship/starship.toml | xxd
     # if bytes between the quotes are `ee 9c 98` etc., the glyph is live
     ```
   - When you need to edit such a file and the `Write`/`Edit`
     channel is dropping glyphs, **don't retype them by hand**.
     Slice the glyph-bearing chunks out of the existing file (or
     out of git history via `git show <ref>:<path>`) with `sed -n
     'A,Bp'`, and only construct the non-glyph structural lines via
     `printf` or here-docs. The byte-exact copy is the source of
     truth.
   - If you must add a brand-new glyph the file doesn't already
     contain, fetch the literal UTF-8 byte sequence from the
     upstream Nerd Font cheat sheet (`https://www.nerdfonts.com/cheat-sheet`)
     or from another file in this repo that uses it. Never substitute
     a "close enough" ASCII fallback — the whole point of the
     Catppuccin Mocha terminal stack is that those glyphs render.
6. **Package install lane policy.** Primary install vector is the
   native package manager: `brew` on macOS,
   `apt`/`pacman`/`dnf` on Linux (selected by distro detection).
   Fall back to **AUR** (Arch-only — `makepkg`/`yay`/`paru`
   builds, pacman-installable) or **Snap** (Debian/Fedora) only
   when the native repo lacks the package. Language-specific
   installers (`cargo install`, `go install`, `pipx`) and upstream
   release binaries are last-resort fallbacks, recorded in the
   *Fallback* column of [`doc/packages-native.md`](doc/packages-native.md).
   **Flatpak is intentionally out of scope** — don't propose it.
7. **Package install lists live in `packages/` at repo root, not
   under `configurations/`.** `configurations/<app>/` is for app
   config files the user edits live (symlinked into `~/.config/`).
   `packages/` is the inventory of what gets installed
   (`Brewfile` + `<pkgmgr>.list` files + `aur.list` / `snap.list`
   fallbacks). The separation is load-bearing: a glance at the
   tree should show "configure" vs "install" without opening
   files. Don't put install lists back under `configurations/` and
   don't put `.conf`/`.toml` config under `packages/`.
8. **Footprint policy — user-scoped, easy uninstall.** Every
   artifact the repo plants lives under `$HOME`: symlinks under
   `~/.config/` and `~/.vim*`, scripts under `~/.scripts/`,
   plugin checkouts under `~/.config/<tool>/plugins/` or
   `~/.local/share/`. The only writes outside `$HOME` are the
   native package manager doing its job (`sudo apt install …`,
   `brew install …`). Never plant files in `/etc`, `/usr/local`,
   `/opt`, or `/var` outside what the package manager owns.
   Corollary: the repo ships `scripts/symlinks.sh uninstall` that
   strips every user-scope artifact in one pass; future
   `scripts/uninstall.sh` (Phase 4 of v3-native) will wrap that with
   optional `apt purge` / `brew uninstall` driven by the `.list`
   files + optional `chsh` revert.

## Soft conventions

- OS detection in shell scripts: branch on `$(uname)` (`Darwin` vs
  `Linux`), then for Linux distros source `/etc/os-release` and case
  on `${ID}`. `scripts/symlinks.sh` and `setup.sh` are the reference
  implementations.
- Backup scope: only configs **this repo manages**. Anything else
  under `~/.config/` is left alone. `scripts/backup-configs.sh`
  is the authority on what's in scope.
- Theming: every terminal app uses Catppuccin Mocha. When adding a
  new app, source its palette from `configurations/themes/` if a
  palette file is needed, not from inline hexes.
- Aliases: cross-shell via portable `alias name='cmd'` syntax in
  `configurations/aliases/*.sh`, sourced from both zsh and bash. No
  third-party multi-shell alias manager.

## Slash commands

See `.claude/commands/` for the full set. Quick map:

| Command   | What it does                                                                                       |
| --------- | -------------------------------------------------------------------------------------------------- |
| `/apply`  | Runs `setup.sh`. Forwards `--desktop` / `--update` when asked.                                     |
| `/update` | Runs `scripts/update.sh`. Forwards `--dry-run` / `--desktop` / `--only=…` when asked.              |
| `/commit` | Builds a Conventional Commit message from `git diff --cached`.                                     |
| `/check`  | Runs `shellcheck scripts/*.sh setup.sh`, validates `packages/*.list`, and `commitlint --from origin/main`. |

## Skills

- `doc-author` — keeps `doc/*.md` files in lockstep with the scripts
  and configurations they document. Read when you change `setup.sh`,
  `scripts/*.sh`, or a `packages/*.list` and need to refresh its
  companion doc.

## Hooks

- `pre-commit.sh` — wraps `lefthook run pre-commit`. The lefthook
  pre-commit pipeline already runs `shellcheck`, so this is a thin
  shim invoked from `/commit`.
- `commit-msg.sh` — validates a candidate commit message against the
  same regex `lefthook.yml` uses, before the agent actually runs
  `git commit`. Lets `/commit` reject its own draft and retry.
- `post-tool-use.sh` — registered as a `PostToolUse` Claude Code
  hook in `.claude/settings.json`, filtered to `Write`/`Edit`. If
  the touched file is a `packages/*.list` or `packages/Brewfile`
  and the same edit didn't also touch `doc/packages-native.md`, it
  prints a warning (non-blocking) so the doc doesn't silently rot.
