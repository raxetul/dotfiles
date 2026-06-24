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
9. **Custom-install hooks live in `packages/custom-install/<pkg>/`,
   one folder per package, with REQUIRED `before.sh` and `after.sh`
   slots.** `before.sh` runs *before* the package install step
   (register a third-party APT/COPR repo, accept an upstream key,
   pre-create a config dir); `after.sh` runs *after* the install +
   AUR/Snap fallback (provision a toolchain — canonical example:
   `rustup default stable` to materialize `cargo`/`rustc` in
   `~/.cargo/bin/`, enable a service, run a self-test).
   - **Both files MUST exist** for every `<pkg>/` directory, even
     when one side has no work. The unused side is a stub:
     `#!/usr/bin/env bash` + `set -euo pipefail` + `exit 0`. This
     keeps the layout uniform and the log timeline linear (every
     package contributes one `before ----` and one `after ----`
     banner per run, with `(no-op stub)` output when the script
     just exits).
   - **PATH additions go through `${DOTFILES_DIR}/.path`.** When
     the package adds binaries to PATH (rustup → `~/.cargo/bin`,
     future tools likewise) or defines a `FOO_HOME`-style env var,
     the `after.sh` MUST write a segment into the gitignored
     `${DOTFILES_DIR}/.path` file, bracketed by markers so re-runs
     are idempotent:

     ```sh
     # >>> rustup begin
     [ -d "${HOME}/.cargo/bin" ] && case ":${PATH}:" in
         *":${HOME}/.cargo/bin:"*) ;;
         *) PATH="${HOME}/.cargo/bin:${PATH}"; export PATH ;;
     esac
     # >>> rustup end
     ```

     The hook strips any existing `# >>> <pkg> begin …  end`
     section before appending the fresh one — `sed -i.bak
     '/^# >>> <pkg> begin$/,/^# >>> <pkg> end$/d'`. `.path` is
     sourced from `.load`, which is sourced from
     `configurations/{zsh,bash}/rc`. Both `.load` and `.path` are
     gitignored (per-host); `scripts/init-load` ensures `.load`
     exists. Don't put one-off `PATH=…` lines in the shell rc
     files; they belong in `.path`.
   - Every script must be executable, idempotent (re-running with
     the work already done is a no-op), skip cleanly if the package
     isn't installed, honor `DRY_RUN=1`, and use `$DOTFILES_DIR` to
     find anything in the repo.

   `setup.sh` (Step 2 before-pass, Step 5 after-pass) and
   `scripts/update-dotfiles` (`stage_packages_custom_before` /
   `stage_packages_custom_after`, addressable via
   `--only=custom-install`, `--only=custom-install-before`, or
   `--only=custom-install-after`) iterate the directory in lexical
   order through `scripts/run-custom-install-hook`, which logs each
   hook to `~/.local/state/dotfiles/custom-install.log` and streams
   to the terminal. See
   [`packages/custom-install/README.md`](packages/custom-install/README.md)
   for the full contract. Anything that's *configuration* (lives in
   `~/.config/<app>/`) belongs in `configurations/<app>/`, not here.
10. **`.path` is the single source of truth for per-package PATH and
    env. Centralized, clean, one bracketed segment per package.** Any
    package that installs binaries outside the bootstrap dirs, or that
    needs a `FOO_HOME`-style env var, gets exactly one segment in the
    gitignored `${DOTFILES_DIR}/.path`:

    ```sh
    # >>> <pkg> begin
    export FOO_HOME="${HOME}/.foo"
    [ -d "${FOO_HOME}/bin" ] && case ":${PATH}:" in
        *":${FOO_HOME}/bin:"*) ;;
        *) PATH="${FOO_HOME}/bin:${PATH}"; export PATH ;;
    esac
    # >>> <pkg> end
    ```

    - **The segment is written by that package's
      `custom-install/<pkg>/after.sh`** (rule #9), which strips the old
      segment (`sed -i.bak '/^# >>> <pkg> begin$/,/^# >>> <pkg> end$/d'`)
      and re-appends before adding the fresh one — idempotent. `.path`
      is sourced by `.load`, which is sourced by
      `configurations/{zsh,bash}/rc`.
    - **The `[ -d ]` and `case` guards are mandatory** — they keep the
      segment a no-op on hosts where the dir doesn't exist and
      idempotent across shell reloads. A segment may be written on
      every host even if only one platform needs it (the guards make
      the others harmless), so behavior doesn't fork per distro.
    - **The only non-package PATH entries** are the generic bootstrap
      dirs `~/.scripts` and `~/.local/bin`, set once in `.load` (via
      `scripts/init-load`). A tool that installs *into* `~/.local/bin`
      needs no segment; one that installs elsewhere (atuin →
      `~/.atuin/bin`, rustup → `~/.cargo/bin` + toolchain) does.
    - **Never** put `PATH=…` / `export FOO_HOME=…` lines in `setup.sh`,
      `scripts/*`, `configurations/{zsh,bash}/rc`, or any other shell
      file. If a tool needs a path, it gets a `.path` segment via its
      `after.sh`. No exceptions — that's what "centralized" buys us.
11. **Reference the home directory through `${HOME}`, never a static
    path.** Anywhere a path under the user's home is needed — in any
    `configurations/<app>/` file, in `.load`, in `.path`, and in the
    scripts/hooks that generate them — write `${HOME}/…` (or `$HOME/…`),
    never a hardcoded `/home/<user>/…` or `/Users/<user>/…`. The same
    config is symlinked across hosts and both OSes where the home root
    differs (`/home/emrah` vs `/Users/emrah`), so a baked-in absolute
    path breaks portability and the one-pass uninstall.
    - Prefer the braced `${HOME}` form for quoting safety; bare `~`
      only expands unquoted and at word start, so it silently fails
      inside quotes or mid-string — don't rely on it in config files.
    - For the repo root specifically, use the `${DOTFILES_DIR}`
      variable (which itself defaults to `${HOME}/gel-ort/dotfiles`),
      not a literal path — see `.load` / `scripts/init-load`.
12. **Migrating a live config into the repo follows one fixed
    procedure** — the same one used for `claude` and `ghostty`. To
    bring an app's existing config under management:
    1. **Probe for secrets and runtime state first.** Move only the
       files the user hand-edits; never the credential/cache/history
       artifacts (the `claude` migration deliberately left
       `.credentials.json`, `history.jsonl`, `projects/`, `sessions/`
       behind). If a file's sensitivity is unclear, ask before moving.
    2. **Move (don't copy)** the file into `configurations/<app>/`,
       preserving its path layout under `~/.config` (a nested
       `~/.config/<app>/sub/foo` → `configurations/<app>/sub/foo`).
    3. **Symlink it back** with `ln -sfn <repo-src> <live-dst>` so the
       user's edits keep taking effect live.
    4. **Register the mapping** in the `COMMON_LINKS` (or a
       platform-specific) array in `scripts/symlinks.sh`, with a
       `${HOME}`-relative `dst` (rule #1, #11). A whole directory may
       be linked as one entry (see `scripts::.scripts`).
    5. **Verify**: `scripts/symlinks.sh list` shows the new entry and
       `readlink` on the live path resolves into the repo.
    The `/migrate-config` command automates steps 2–5 (and prompts on
    step 1). Use it rather than doing the moves ad hoc.

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
| `/update` | Runs `scripts/update-dotfiles`. Forwards `--dry-run` / `--desktop` / `--only=…` when asked.        |
| `/commit` | Builds a Conventional Commit message from `git diff --cached`.                                     |
| `/check`  | Runs `shellcheck scripts/*.sh setup.sh`, validates `packages/*.list`, and `commitlint --from origin/main`. |
| `/migrate-config` | Brings a live `~/.config/<app>` config under the repo: probe → move → symlink back → wire `COMMON_LINKS` → verify (per hard rule #12). |

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
