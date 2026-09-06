---
status: source-of-truth
maintainer: raxetul@gmail.com
claude-rule: "configurations/claude/settings.json is the tracked, host-agnostic file — symlinked to ~/.claude/settings.json. It must never carry autoMode or any other project-scoped/volatile block; those belong in a settings.local.json (project- or user-level, gitignored). Before editing configurations/claude/settings.json, check `jq -e 'has(\"autoMode\")' configurations/claude/settings.json` is false."
---

# Claude settings — tracked vs. local

## Why this split exists

`configurations/claude/settings.json` is git-tracked and symlinked to `~/.claude/settings.json`
(hard rule #1). Claude Code's **auto mode** classifier can write an `autoMode` block into whatever
settings file is active — and once, it wrote one scoped to a *different* project (`noturi`:
absolute paths, repo name, project-specific CLI rules) straight into this tracked, host-agnostic
file. That block doesn't belong in a repo shared across hosts and read by every project — it's
volatile, machine/project-local state, not a dotfiles config value.

## Which key goes where

| Location | Scope | Git | Holds |
| --- | --- | --- | --- |
| `configurations/claude/settings.json` (→ `~/.claude/settings.json`) | Host-agnostic, all projects | **Tracked** | `model`, `hooks`, `theme`, `tui`, `statusLine`, `enabledPlugins`, `permissions.defaultMode` |
| `~/.claude/settings.local.json` | User-local, all projects on this machine | Gitignored | `autoMode` when no single project owns it |
| `<project>/.claude/settings.local.json` | Project-local (e.g. `noturi`) | Gitignored (repo `.gitignore` or a global `**/.claude/settings.local.json` pattern) | `autoMode` scoped to that project's environment/soft_deny rules |

Settings load order is user → project → local (later wins), so a project-local
`settings.local.json` layers cleanly on top of the tracked file without touching it.

```mermaid
flowchart LR
    CLASS[Auto mode classifier] -->|writes autoMode block| TARGET{Which file?}
    TARGET -->|host-agnostic keys only| TRACKED["configurations/claude/settings.json\n(tracked, symlinked)"]
    TARGET -->|project-scoped autoMode| PLOCAL["<project>/.claude/settings.local.json\n(gitignored)"]
    TARGET -->|no owning project| ULOCAL["~/.claude/settings.local.json\n(gitignored)"]
    TRACKED -.->|must never contain| BAD[autoMode / project-scoped soft_deny]
```

## Exception to hard rule #13

Hard rule #13 ("Centralized Claude commands and rules are always tracked") governs **commands and
rules** (`.claude/commands/`, the global `CLAUDE.md`) — content meant to be portable across hosts.
`autoMode` is neither: it's a live classifier state block scoped to one project's environment, and
belongs with the other volatile/local overrides in a gitignored `settings.local.json`, not in the
tracked file rule #13 protects.

## `/auto-mode-setup` reproduces this churn — it's not a one-off

This is not a one-time accident: **every** `/auto-mode-setup` run writes a fresh
`autoMode` block into whatever settings file is currently active for that
project, scoped to that project's own environment/allow/soft_deny rules. It
happened once for `noturi` and, on 2026-08-20, again for this repo
(`raxetul/dotfiles`) — same failure class, different project. Treat it as
**the command's normal behavior**, not a fluke: after every
`/auto-mode-setup` run, expect the tracked `configurations/claude/settings.json`
to need the same cleanup pass again.

| Step | Action |
| --- | --- |
| 1 | `jq -e 'has("autoMode")' configurations/claude/settings.json` — if `true`, the block landed in the tracked file. |
| 2 | Merge the `autoMode` block into `.claude/settings.local.json` (project-local, gitignored) — preserve any existing keys there (e.g. `permissions.allow`), don't overwrite. |
| 3 | `git checkout -- configurations/claude/settings.json` to drop the block from the tracked file. |
| 4 | Re-verify `jq -e 'has("autoMode")' configurations/claude/settings.json` → `false`. |

For this repo specifically, the target is `.claude/settings.local.json` at
the repo root (not `~/.claude/settings.local.json`) — it's already covered
by the global gitignore pattern `**/.claude/settings.local.json`
(`~/.gitignore_global:4`), confirmed with `git check-ignore -v`, and this
repo's own `.gitignore` carries no matching line of its own (the global
pattern alone is what protects it).

```mermaid
flowchart LR
    RUN["/auto-mode-setup run"] -->|writes autoMode| TRACKED2["configurations/claude/settings.json\n(tracked — wrong spot, again)"]
    TRACKED2 -->|merge| LOCAL2[".claude/settings.local.json\n(gitignored — right spot)"]
    TRACKED2 -->|git checkout --| CLEAN["tracked file restored"]
```

## The atomic-save / symlink-break failure mode

Claude Code's settings writer does an atomic save (write temp file, rename over target). When the
target is a symlink (`~/.claude/settings.json` → repo file), some code paths rename the temp file
**onto the symlink path**, replacing the symlink itself with a plain file — silently breaking the
link back to the repo. Recurs on any in-app write to settings (theme change, model switch,
permission edit), not just the `autoMode` capture. Splitting volatile/write-prone keys into
`settings.local.json` reduces how often the tracked file gets touched by the app, but does not
fix the underlying symlink-clobbering behavior — check periodically:

```sh
readlink ~/.claude/settings.json   # should resolve into the dotfiles repo checkout
```

If it no longer resolves into the repo, the symlink was clobbered — re-run
`scripts/symlinks.sh install` to restore it (after reconciling any content the plain file gained).
