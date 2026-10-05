---
source: .claude/
maintainer: raxetul@gmail.com
claude-rule: "Update this guide when the .claude/ tree or the rules in CLAUDE.md change shape."
---
# Promoting agentic config from repo-local to global

This repo keeps `.claude/` local. The setup does not change `~/.claude/`
(Q5 of the original v2 roadmap). Later, you can make some of these rules
apply to **all** your projects. This guide shows how to promote them
safely.

## Repo-local vs global responsibilities

| Concern                                          | Belongs in repo-local `.claude/` | Belongs in global `~/.claude/`        |
| ------------------------------------------------ | -------------------------------- | ------------------------------------- |
| "Edit `packages/*.list` only here"               | ✓ (path-specific)                | ✗ (would leak rules to other repos)   |
| Preserve Nerd Font glyphs (CLAUDE.md §5)         | ✓ (terminal stack only)          | ✓ if you maintain other Nerd-Font configs |
| Conventional Commits enforcement                 | ✓ for this repo                  | ✓ once you want it everywhere         |
| Line-length / formatting style                   | usually global                   | ✓                                     |
| Permissions allowlist for `brew`/`apt`/`pacman`  | ✓ (only matters here)            | optional, narrower scope better       |
| `/commit` slash command                          | ✓ (initial home)                 | ✓ once it works for any repo          |
| `/rulefy` slash command                          | optional                          | ✓ (project-agnostic by design)        |
| Hooks that lint `packages/*.list`                | ✓                                | ✗                                     |
| Hooks that lint commit messages                  | ✓                                | ✓                                     |

## Promotion procedure

1. **Identify what is truly cross-project.** Keep anything
   path-specific (modules, packages, configurations) local. Anything
   about style (commit style, line length, response tone) is a
   candidate.
2. **Copy the files. Do not move them the first time.** Keep the
   repo-local copy until you use the global one for a week without
   problems:

    ```bash
    mkdir -p ~/.claude/commands ~/.claude/hooks ~/.claude/skills
    cp .claude/commands/commit.md ~/.claude/commands/commit.md
    cp .claude/hooks/commit-msg.sh ~/.claude/hooks/commit-msg.sh
    ```

3. **Merge `settings.json`. Do not overwrite it.** Claude loads the
   global `~/.claude/settings.json` first. The repo-local file then
   overrides it. Keep the global file small: only permissions and
   shared hooks. Do not put repo-specific allowlists in it.
4. **Delete the local copies** of the files you promoted, **only
   after** the global files work well. Old duplicates are worse than
   missing rules.
5. **Symlink for parity (optional).** Do this if you edit a command in
   both places and want the two copies to stay the same:

    ```bash
    ln -sf ~/.claude/commands/commit.md .claude/commands/commit.md
    ```

    The repo then uses the global version. Do not do this for
    `settings.json`. A merge is more flexible than a symlink.

## Best-case scenarios for going global

- **You wrote a Conventional Commits hook and use it in five
  repos.** Promote `commit-msg.sh` to `~/.claude/hooks/`. Then delete
  the per-repo copies.
- **Your style preferences (line length, no trailing summaries,
  no emojis) are stable.** Put them in `~/.claude/CLAUDE.md` one time.
  Every project gets them.
- **A slash command is now repo-agnostic.** `/commit` is an example.
  It needs only `git diff --cached` and no project knowledge.

## When to keep things local

- The rule references a path inside the repo (`packages/*.list`,
  `configurations/<app>/`, `scripts/symlinks.sh`).
- The permission allowlist must be narrower than global. For example,
  if you allow `Bash(sudo apt-get install*)` everywhere, the agent can
  install distro packages from any cloned repo. You usually do not want
  this.
- Skills that document the architecture of this repo. They are not
  useful outside it. If the agent loads them globally, they only
  confuse it.

## Audit checklist before promoting

- [ ] Does it reference a path outside `~`? → keep local.
- [ ] Does it grant elevated permissions? → keep local, scope tightly.
- [ ] Would you want this rule in a totally different language or stack? → safe to promote.
- [ ] Is it about style and stable? → safe to promote.

## Related

- [CLAUDE.md](../CLAUDE.md) — the repo-local rules that this guide
  explains how to promote.
- [.claude/settings.json](../.claude/settings.json) — the
  permissions allowlist + hook wiring.
