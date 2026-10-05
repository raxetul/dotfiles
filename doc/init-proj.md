---
status: source-of-truth
maintainer: raxetul@gmail.com
claude-rule: "The /init-proj-* command family is documented here and MUST be kept in lockstep with configurations/claude/commands/init-proj-*.md. Per-project standards live in the project's own ./CLAUDE.md, never in the global config. See CLAUDE.md §14."
---

# Project initialization — the `/init-proj-*` command family

## Why this exists

The global Claude config (`~/.claude/CLAUDE.md`) loads into **every**
session. Each rule in it uses context on **every** task, also when the
rule is not relevant. To keep this cost small, per-project standards are
**not** global. A family of slash commands writes the correct rules into
each **project's own `./CLAUDE.md`**. Claude Code loads that file only
when you work in that project.

One command sets up a project: git, hooks, conventional commits, and a
test skeleton. The same command **also** pins the engineering rules of
the project. A fresh checkout on any machine is therefore initialized in
the same way. The commands are in `configurations/claude/commands/`. The
setup links them into `~/.claude/commands/`, so they go with the
dotfiles to every computer.

## Layering

```
/init-proj-<type>          (backend, frontend, embedded-firmware,
        │                   kernel-driver, cli, desktop, mobile)
        │ runs first
        ▼
/init-proj-common          shared baseline (git, lefthook, common rules)
        │ invokes
        ▼
building blocks            /logging   /rfc9457   /backend-stack   /rust-config
```

- A **type** command always runs **`/init-proj-common`** first. Then it
  adds its type-specific rules and scaffolding.
- Some rules have a standalone command (`/logging`, `/rfc9457`,
  `/backend-stack`, `/rust-config`). The type commands **invoke** these
  commands as building blocks. Each rule text is therefore defined in
  one place only.
- **`/init-proj-monorepo`** asks which types to include. It applies the
  baseline one time at the root. Then it runs each type command for each
  package.

## Two layers: scaffolded rules + auto-loading skills

Each building block gives its convention in **two layers**:

| Layer | Where it lives | Loads | Guarantee |
| --- | --- | --- | --- |
| **Strict rule** (the decision) | scaffolded into the project's `./CLAUDE.md` by the command | always, in that project | enforced + versioned in the repo |
| **Implementation depth** (the how) | an auto-loading **skill** under `configurations/claude/skills/<name>/` | only when the work is relevant | central, improving, never drifts per-project |

```
/logging        → rule in ./CLAUDE.md   +  logging-patterns          skill
/rfc9457        → rule in ./CLAUDE.md   +  rfc9457-problem-details    skill
/backend-stack  → rule in ./CLAUDE.md   +  backend-stack-patterns     skill
/rust-config    → rule in ./CLAUDE.md   (rule only, no matching skill)
```

The **rule** is a strict decision that must always hold. It is written
down, so it is deterministic, and humans and other tools can see it. The
**skill** holds the know-how that changes (per-stack recipes, examples).
It loads automatically when you write the relevant code. It is kept in
one place, so it does not become old across projects. `scripts/symlinks.sh`
links the skills **one by one** into `~/.claude/skills/`. That folder also
holds third-party skills. Link each skill alone. Do not link the whole
directory.

## The common baseline — `/init-proj-common`

| Step | What it does |
| --- | --- |
| git | `git init` if the directory is not a repo yet (skipped inside a monorepo) |
| lefthook | `lefthook.yml` with a conventional-commit `commit-msg` hook + a `pre-commit` lint/test hook, then `lefthook install` |
| rules → `./CLAUDE.md` | **Dependency injection**, **Unit testing**, **Conventional commits**, **Diagram layout**, **Pre-CLI-command briefs** |
| logging | invokes `/logging` (centralized multi-writer logging) |
| project commands | `./.claude/commands/` gets a lefthook-aware `/commit` and a `/check` |
| tests | a conventional test dir + one placeholder test |

These are the five common rules, one line for each:

- **Dependency injection** — modules get their collaborators through an
  abstraction. A composition root connects them. Tests inject in-memory
  fakes. Production injects the real parts.
- **Unit testing** — fast, hermetic, deterministic tests that use that
  DI seam. New behavior comes with tests.
- **Conventional commits** — the lefthook `commit-msg` regex enforces
  them.
- **Diagram layout** — draw.io connectors use orthogonal routes. They
  are **preferably fully separate lines**. Use a shared **common
  horizontal trunk** only when space is tight. The **vertical** lines are
  **spaced** (never overlapping, ≥20px). Each box has an
  **item-specific horizontal leg** in its center, and the leg carries the
  edge label. A one-to-many edge fans out from the source. A many-to-one
  edge is the mirror image into the target. An edge that has labels at
  **both ends** (ER cardinalities — one-to-many, many-to-many) is drawn
  on its own separate path. Each label is on the leg next to its own
  entity.
- **Pre-CLI-command briefs** — before you run shell commands, print a
  table (`# | Command | Action brief | Effect`) of the commands that
  will run.

### Overridable features

The baseline features have **names** and you can **override** them. A
command that invokes `/init-proj-common` can pass an override list. The
list **disables** the parts that do not fit the project type. The
command then supplies its own replacement. All features are on by
default, so a bare `/init-proj-common` applies everything.

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
`logging=off, dependency-injection=off, unit-testing=off`. Kernel space
uses `pr_*` logging, `ops`-struct/function-pointer seams, and KUnit.
It does not use the userland forms. The command then writes these
kernel-native rules itself. `git` and conventional commits stay on.

## Type commands

| Command | Layers on top of common |
| --- | --- |
| `/init-proj-backend` | `/backend-stack` + `/rfc9457`; layered handler→service→repository, injected config, versioned+validated API; migrations-only schema with paired seed data (frozen once released); UTC+zone-id time storage with DST-safe future wall-clock times |
| `/init-proj-frontend` | presentational/container split, centralized state, injectable API-client seam, accessibility |
| `/init-proj-embedded-firmware` | MISRA C, ISO 26262 (ASIL-B) awareness, mockable HAL seam, no dynamic allocation, host test harness |
| `/init-proj-kernel-driver` | kernel coding style + checkpatch, Kbuild skeleton, GPL/SPDX, KUnit, mock at subsystem boundaries |
| `/init-proj-cli` | arg parsing + `--help`/`--version`, exit codes, stdout/stderr split, config precedence |
| `/init-proj-desktop` | off-UI-thread work, MVVM/MVC boundary, injectable persistence, packaging |
| `/init-proj-mobile` | MVVM/MVI, off-main-thread work, offline-first, injectable network/storage |

## Monorepo — `/init-proj-monorepo`

The command asks (with a prompt) which project kinds to include. It also
asks for a layout dir (`packages/` or `apps/`). It installs Git and
lefthook **one time at the root**. Each package gets its own nested
`CLAUDE.md` from the matching type command. `/init-proj-common` is
idempotent. When it runs for a package, it finds the root git and
lefthook and skips them. This gives no nested repos and no duplicated
hooks. Root rules apply everywhere. Package rules load only in that
package.

## Re-applying to an existing project — `/apply-updated-init`

The `/init-proj-*` commands **initialize** a fresh project. Sometimes the
scaffolding gets a new rule, or an existing rule changes. Then
`/apply-updated-init` **re-applies** the current scaffolding to an
**already-initialized** project. The project catches up and you do not
need to redo the work by hand.

The command does three things:

1. It detects the type(s) of the project, including the monorepo root
   and each package.
2. It runs the matching `/init-proj-*` command(s) again. These commands
   are **idempotent**, so they add only the `./CLAUDE.md` sections that
   are missing or changed.
3. It **conforms the existing artifacts** of the project to each new or
   changed rule. A plain re-scaffold does not do this. Example: for a
   new *Diagram layout* rule, regenerate the diagrams with the own
   generator of the project and verify them.

The command also keeps the living docs and requirements in sync. It
follows the same contract as the rest of the family: idempotent,
pre-CLI briefs, confirm before it writes, never commit automatically.

```
/init-proj-*        initialize a new project
/apply-updated-init reconcile an existing project to the current rules
                    + bring its artifacts into compliance
```

## Contract shared by every command

- **Idempotent** — when you run a command again, it skips the work that
  is done (existing `.git`, hook, or `CLAUDE.md` section).
- **Pre-CLI briefs** — a table shows the CLI steps before they run.
- **Confirm destructive and outward-facing steps** before the command
  runs them.
- **Never commit automatically** — each command reports what it wrote
  and suggests a Conventional Commit.
- **Writes stay in the project** (`./CLAUDE.md`, `./.claude/`,
  `lefthook.yml`, test dirs). Nothing goes into the global config.

## Applying on another machine

Clone the dotfiles. Run the setup, so that it links `configurations/claude/`
into `~/.claude/`. Then every `/init-proj-*` command is available in
Claude Code, the same as on this machine. Run the command that matches
the project you start.
