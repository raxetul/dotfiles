---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "The /init-proj-* command family is documented here and MUST be kept in lockstep with configurations/claude/commands/init-proj-*.md. Per-project standards live in the project's own ./CLAUDE.md, never in the global config. See CLAUDE.md §15."
---

# Project initialization — the `/init-proj-*` command family

## Why this exists

The global Claude config (`~/.claude/CLAUDE.md`) loads into **every**
session, so anything put there costs context on **every** task,
including ones where it's irrelevant. To keep that footprint small,
per-project standards are **not** global. Instead, a family of slash
commands writes the right rules into each **project's own
`./CLAUDE.md`**, which Claude Code loads only when you work inside that
project.

One command scaffolds a project — git, hooks, conventional commits,
test skeleton — **and** pins its engineering rules, so a fresh checkout
on any machine is initialized the same way. The commands live in
`configurations/claude/commands/` and are symlinked into
`~/.claude/commands/`, so they travel with the dotfiles to every
computer.

## Layering

```
/init-proj-<type>          (backend, frontend, embedded-firmware,
        │                   kernel-driver, cli, desktop, mobile)
        │ runs first
        ▼
/init-proj-common          shared baseline (git, lefthook, common rules)
        │ invokes
        ▼
building blocks            /logging   /rfc9457   /backend-stack
```

- A **type** command always runs **`/init-proj-common`** first, then
  layers its type-specific rules and scaffolding.
- Rules that already have a standalone command (`/logging`,
  `/rfc9457`, `/backend-stack`) are **invoked** as building blocks, so
  each rule's text is defined in exactly one place.
- **`/init-proj-monorepo`** asks which types to include, lays the
  baseline once at the root, and runs each type command per package.

## Two layers: scaffolded rules + auto-loading skills

Each building block delivers its convention in **two layers**:

| Layer | Where it lives | Loads | Guarantee |
| --- | --- | --- | --- |
| **Strict rule** (the decision) | scaffolded into the project's `./CLAUDE.md` by the command | always, in that project | enforced + versioned in the repo |
| **Implementation depth** (the how) | an auto-loading **skill** under `configurations/claude/skills/<name>/` | only when the work is relevant | central, improving, never drifts per-project |

```
/logging        → rule in ./CLAUDE.md   +  logging-patterns          skill
/rfc9457        → rule in ./CLAUDE.md   +  rfc9457-problem-details    skill
/backend-stack  → rule in ./CLAUDE.md   +  backend-stack-patterns     skill
```

The **rule** is a strict decision that must always hold, so it's written down —
deterministic, and visible to humans and other tools. The **skill** carries the
evolving know-how (per-stack recipes, examples); it auto-loads when you write the
relevant code, is maintained in one place, and so never goes stale across
projects. Skills are symlinked **per-skill** into `~/.claude/skills/` by
`scripts/symlinks.sh` — that folder also holds third-party skills, so they are
linked individually, never as a whole directory.

## The common baseline — `/init-proj-common`

| Step | What it does |
| --- | --- |
| git | `git init` if not already a repo (skipped inside a monorepo) |
| lefthook | `lefthook.yml` with a conventional-commit `commit-msg` hook + a `pre-commit` lint/test hook, then `lefthook install` |
| rules → `./CLAUDE.md` | **Dependency injection**, **Unit testing**, **Conventional commits**, **Diagram layout**, **Pre-CLI-command briefs** |
| logging | invokes `/logging` (centralized multi-writer logging) |
| project commands | `./.claude/commands/` gets a lefthook-aware `/commit` and a `/check` |
| tests | a conventional test dir + one placeholder test |

The five common rules in one line each:

- **Dependency injection** — modules take collaborators through an
  abstraction wired at a composition root; tests inject in-memory
  fakes, production injects the real thing.
- **Unit testing** — fast, hermetic, deterministic tests through that
  DI seam; new behavior lands with tests.
- **Conventional commits** — enforced by the lefthook `commit-msg`
  regex.
- **Diagram layout** — in draw.io diagrams, edge labels sit only on
  non-overlapping vertical segments; two edges share a vertical only
  when they share an endpoint; keep ≥20px between parallel segments;
  avoid crossings.
- **Pre-CLI-command briefs** — before running shell commands, print a
  table (`# | Command | Action brief | Effect`) of what will run.

### Overridable features

The baseline features are **named** and **overridable**: a command that
invokes `/init-proj-common` can pass an override list to **disable** the
parts that don't fit that project type, then supply its own replacement.
Defaults are all on, so a bare `/init-proj-common` applies everything.

| Key | Overridable | Disabled by |
| --- | --- | --- |
| `git` | yes (auto-off if already a repo) | monorepo packages |
| `conventional-commits` | yes | — |
| `dependency-injection` | yes | `kernel-driver` |
| `unit-testing` | yes | `kernel-driver` |
| `logging` | yes | `kernel-driver` |
| `project-commands` | yes | — |
| `test-skeleton` | yes | — |
| `diagram-layout` | yes | — |
| `pre-cli-briefs` | **no** (always applied) | — |

Example: `/init-proj-kernel-driver` runs `/init-proj-common` with
`logging=off, dependency-injection=off, unit-testing=off`, because
kernel space uses `pr_*` logging, `ops`-struct/function-pointer seams,
and KUnit — not the userland forms. It then writes those kernel-native
rules itself. `git` and conventional commits stay on.

## Type commands

| Command | Layers on top of common |
| --- | --- |
| `/init-proj-backend` | `/backend-stack` + `/rfc9457`; layered handler→service→repository, injected config, versioned+validated API; migrations-only schema with paired seed data (frozen once released) |
| `/init-proj-frontend` | presentational/container split, centralized state, injectable API-client seam, accessibility |
| `/init-proj-embedded-firmware` | MISRA C, ISO 26262 (ASIL-B) awareness, mockable HAL seam, no dynamic allocation, host test harness |
| `/init-proj-kernel-driver` | kernel coding style + checkpatch, Kbuild skeleton, GPL/SPDX, KUnit, mock at subsystem boundaries |
| `/init-proj-cli` | arg parsing + `--help`/`--version`, exit codes, stdout/stderr split, config precedence |
| `/init-proj-desktop` | off-UI-thread work, MVVM/MVC boundary, injectable persistence, packaging |
| `/init-proj-mobile` | MVVM/MVI, off-main-thread work, offline-first, injectable network/storage |

## Monorepo — `/init-proj-monorepo`

Asks (via a prompt) which project kinds to include and a layout dir
(`packages/` or `apps/`). Git + lefthook are installed **once at the
root**; each package gets its own nested `CLAUDE.md` from the matching
type command. Because `/init-proj-common` is idempotent, its
per-package run finds the root git/lefthook and skips them — no nested
repos, no duplicated hooks. Root rules apply everywhere; package rules
load only inside that package.

## Re-applying to an existing project — `/apply-updated-init`

The `/init-proj-*` commands **initialize** a fresh project. When the
scaffolding later gains a new rule (or an existing one changes),
`/apply-updated-init` **re-applies** the current scaffolding to an
**already-initialized** project so it catches up without a manual redo.

It (1) detects the project's type(s) — including monorepo root + each
package, (2) re-invokes the matching `/init-proj-*` command(s), whose
**idempotency** appends only the missing/changed `./CLAUDE.md` sections,
and (3) — the part a plain re-scaffold doesn't do — **conforms the
project's existing artifacts** to each new/changed rule (e.g. a new
*Diagram layout* rule → regenerate the diagrams via the project's own
generator and verify), keeping living docs/requirements in sync. Same
family contract: idempotent, pre-CLI briefs, confirm before writing,
never auto-commit.

```
/init-proj-*        initialize a new project
/apply-updated-init reconcile an existing project to the current rules
                    + bring its artifacts into compliance
```

## Contract shared by every command

- **Idempotent** — re-running skips work already done (existing
  `.git`, hook, or `CLAUDE.md` section).
- **Pre-CLI briefs** — CLI steps are previewed in a table before they
  run.
- **Confirm destructive/outward-facing steps** before executing.
- **Never commit automatically** — each command reports what it wrote
  and suggests a Conventional Commit.
- **Writes stay in the project** (`./CLAUDE.md`, `./.claude/`,
  `lefthook.yml`, test dirs) — nothing lands in the global config.

## Applying on another machine

Clone the dotfiles and run the setup so `configurations/claude/` is
symlinked into `~/.claude/`. Every `/init-proj-*` command is then
available in Claude Code, identically to this machine. Run the one that
matches the project you're starting.
