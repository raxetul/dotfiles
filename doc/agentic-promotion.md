---
source: .claude/
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this guide when the .claude/ tree or the rules in CLAUDE.md change shape."
---
# Promoting agentic config from repo-local to global

This repo keeps `.claude/` local — `~/.claude/` is untouched (Q5 of
the original v2 roadmap). If you later want some of these rules to
apply across **all** your projects, here is how to promote them
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

1. **Identify what's truly cross-project.** Anything path-specific
   (modules, packages, configurations) stays local. Anything
   stylistic (commit style, line length, response tone) is a
   candidate.
2. **Copy, don't move, the first time.** Keep the repo-local copy
   until you've used the global one for a week without surprises:

    ```bash
    mkdir -p ~/.claude/commands ~/.claude/hooks ~/.claude/skills
    cp .claude/commands/commit.md ~/.claude/commands/commit.md
    cp .claude/hooks/commit-msg.sh ~/.claude/hooks/commit-msg.sh
    ```

3. **Merge `settings.json`, don't overwrite.** Global
   `~/.claude/settings.json` is loaded first, repo-local overrides
   on top. Keep the global one minimal — just permissions and
   shared hooks. Don't put repo-specific allowlists in it.
4. **Delete the local copies** of anything you promoted, **only
   after** the global ones have proven themselves. Stale duplicates
   are worse than missing rules.
5. **Symlink for parity (optional).** If you actively edit a
   command in both places and want them to stay in lockstep:

    ```bash
    ln -sf ~/.claude/commands/commit.md .claude/commands/commit.md
    ```

    Then the repo just inherits the global version. Avoid this for
    `settings.json` — merging is more flexible than symlinking.

## Best-case scenarios for going global

- **You wrote a Conventional Commits hook and use it on five
  repos.** Promote `commit-msg.sh` to `~/.claude/hooks/`, delete
  the per-repo copies, done.
- **Your style preferences (line length, no trailing summaries,
  no emojis) are stable.** Put them in `~/.claude/CLAUDE.md` once;
  every project inherits.
- **A slash command became repo-agnostic.** `/commit` for example:
  it only needs `git diff --cached`, no project knowledge.

## When to keep things local

- The rule references a path inside the repo (`packages/*.list`,
  `configurations/<app>/`, `scripts/symlinks.sh`).
- The permission allowlist needs to be narrower than global (e.g.
  allowing `Bash(sudo apt-get install*)` everywhere would let the
  agent install distro packages from any cloned repo — usually not
  what you want).
- Skills that document this repo's architecture — they're useless
  outside it and would only confuse the agent if loaded globally.

## Audit checklist before promoting

- [ ] Does it reference a path outside `~`? → keep local.
- [ ] Does it grant elevated permissions? → keep local, scope tightly.
- [ ] Would a future-you working in a totally different language/stack still want this rule? → safe to promote.
- [ ] Is it stylistic and stable? → safe to promote.

## Related

- [CLAUDE.md](../CLAUDE.md) — the repo-local rules this guide
  reasons about promoting.
- [.claude/settings.json](../.claude/settings.json) — the
  permissions allowlist + hook wiring.
