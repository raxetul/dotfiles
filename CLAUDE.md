# Dotfiles — agent ground rules

Scope: this file applies to any work an agent does inside this repo
(`raxetul/dotfiles`). Repo-local; nothing here is promoted to
`~/.claude/`. If you want to lift a rule out of this repo into a
global one, see [doc/agentic-promotion.md](doc/agentic-promotion.md).

## Hard rules

1. **Never edit `flake.lock` by hand.** Bump it with `nix flake update`
   (or `setup.sh --update` / `scripts/update.sh`). Hand-editing the
   lock breaks reproducibility for every other host that pulls.
2. **Any new app config goes under `configurations/<app>/`** and is
   linked into the live tree via `xdg.configFile."<app>/<file>".source
   = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/configurations/<app>/<file>";`
   — never inline as a string inside a `.nix` file. Edits in
   `configurations/` take effect without a `home-manager switch`,
   which is the whole point of the symlink layer.
3. **Every new `.nix` file in `home/modules/`** needs a matching
   `doc/modules-<name>.md` (see
   [`.claude/skills/doc-author/SKILL.md`](.claude/skills/doc-author/SKILL.md)
   for the frontmatter template). The `post-tool-use.sh` hook will
   flag a `Write`/`Edit` to a module that didn't touch its doc in
   the same turn.
4. **Commit messages follow Conventional Commits.** Types: `feat`,
   `fix`, `refactor`, `chore`, `docs`, `style`, `perf`, `build`,
   `ci`, `test`, `revert`. Scope is optional but encouraged
   (`feat(gpg): …`, `docs(roadmap): …`). The `commit-msg` lefthook
   rejects anything that doesn't match `^(<type>)(\(<scope>\))?!?: <subject>`.
5. **Line length is 120 columns.** Never collapse a multi-line
   construct (Nix attribute set, shell heredoc, YAML loop) into one
   line just because it would fit — preserve the user's line breaks.
   This rule is repeated in the user's global `~/.claude/CLAUDE.md`;
   it's loud here because most of this repo is heavily multi-line by
   design.

## Soft conventions

- OS detection: derive `isDarwin`/`isLinux` from the `system`
  specialArg via `lib.hasSuffix "darwin" system` — never use
  `pkgs.stdenv.isDarwin`. The dispatcher in `home/default.nix` is the
  reference implementation.
- Backup scope: only configs **this repo manages**. Anything else
  under `~/.config/` is left alone. `scripts/backup-configs.sh`
  is the authority on what's in scope.
- Theming: every terminal app uses Catppuccin Mocha (see
  `doc/theming.md` once Phase 13 lands). When adding a new app,
  source its palette from `configurations/themes/` if a palette file
  is needed, not from inline hexes.
- Aliases: cross-shell via portable `alias name='cmd'` syntax in
  `configurations/aliases/*.sh`, sourced from both zsh and bash. No
  third-party multi-shell alias manager.

## Slash commands

See `.claude/commands/` for the full set. Quick map:

| Command          | What it does                                                                    |
| ---------------- | ------------------------------------------------------------------------------- |
| `/apply`         | Runs `setup.sh` in dry-run mode, then asks before doing it for real.            |
| `/update`        | Runs `scripts/update.sh`. Forwards `--dry-run` / `--only=…` when asked.         |
| `/new-module <name>` | Scaffolds `home/modules/<name>.nix` + `doc/modules-<name>.md` + adds the import to `home/common.nix` and a row to `README.md`. |
| `/commit`        | Builds a Conventional Commit message from `git diff --cached`.                  |
| `/check`         | Runs `nix flake check`, `nixpkgs-fmt --check`, `shellcheck scripts/*`, `commitlint --from origin/main`. |

## Skills

- `nix-module-author` — the right way to add a Home Manager module
  in this repo. Read before authoring any new `home/modules/*.nix`.
- `doc-author` — keeps `doc/*.md` and `.nix` files in lockstep. Read
  when you change a nix file and need to update its companion doc.

## Hooks

- `pre-commit.sh` — wraps `lefthook run pre-commit`. The lefthook
  pre-commit pipeline already runs `nixpkgs-fmt --check` and
  `shellcheck`, so this is a thin shim invoked from `/commit`.
- `commit-msg.sh` — validates a candidate commit message against the
  same regex `lefthook.yml` uses, before the agent actually runs
  `git commit`. Lets `/commit` reject its own draft and retry.
- `post-tool-use.sh` — registered as a `PostToolUse` Claude Code
  hook in `.claude/settings.json`, filtered to `Write`/`Edit`. If
  the touched file matches `home/modules/<name>.nix` and the same
  edit didn't also touch `doc/modules-<name>.md`, it prints a
  warning (non-blocking) so the doc doesn't silently rot.
