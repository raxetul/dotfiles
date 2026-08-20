---
description: Scaffold the shared baseline for the current project — git init, lefthook + conventional commits, and the common rules (dependency injection, unit testing, logging, diagram layout, pre-CLI briefs) written into the project's own ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize the **common baseline** for the **current project**. This is
the shared foundation every `/init-proj-<type>` command layers on top
of; run it directly for a plain project, or let a type / monorepo
command invoke it. Everything it writes lands in the **project's own
directory** (its `./CLAUDE.md`, its `./.claude/`, its `lefthook.yml`) —
never in the global Claude config — so the rules load only inside this
project and keep each session's context small.

**Contract for every step below:** it is **idempotent** (re-running
skips work already done — e.g. an existing `.git`, an existing lefthook
hook, a section already present in `./CLAUDE.md`), and before running
any CLI commands you **first print a pre-CLI brief table** (see the
rule of the same name) and **confirm destructive steps**.

## Overridable features

The baseline is a set of **named features**, each with a **default** and
an **overridable** flag. A command that invokes `/init-proj-common` may
pass an **override list** — e.g. *"run `/init-proj-common` with
overrides: `logging=off`, `dependency-injection=off`"*. When invoked
with overrides you **MUST honor them**: for any feature set to `off`,
**do nothing for it** — write no rule, run no step, create no file for
that feature. The calling command then supplies its own replacement (in
its own type rules) if the project needs one. Features marked not
overridable are always applied. With no override list, apply every
feature (all default on).

| Key | Default | Overridable | What it does (step #) |
| --- | --- | --- | --- |
| `git` | on | yes — auto-off if already a repo | `git init` (2) |
| `conventional-commits` | on | yes | lefthook `commit-msg` + `pre-commit` (3) and its rule (4) |
| `dependency-injection` | on | yes | the DI rule (4) |
| `unit-testing` | on | yes | the unit-testing rule (4) |
| `logging` | on | yes | invoke `/logging` (5) |
| `project-commands` | on | yes | `/commit` + `/check` in `./.claude/commands/` (6) |
| `test-skeleton` | on | yes | test dir + placeholder (7) |
| `diagram-layout` | on | yes | the draw.io diagram-layout rule (4) |
| `pre-cli-briefs` | on | **no** | the pre-CLI brief rule (4) — always written |

Procedure:

1. **Locate the project root** (current directory, or the enclosing git
   root if one exists). Report it and confirm before writing.

2. **git** *(key `git`)* — if there is no `.git`, run `git init`. Skip
   if already a repository (the monorepo case: git lives at the root)
   or if disabled by an override.

3. **lefthook + conventional commits** *(key `conventional-commits`)* —
   skip entirely if disabled by an override. Otherwise, if
   `lefthook.yml` is absent,
   create it with:
   - a **`commit-msg`** hook rejecting anything that doesn't match
     `^(feat|fix|refactor|chore|docs|style|perf|build|ci|test|revert)(\(.+\))?!?: .+`
   - a **`pre-commit`** hook running the project's formatter/linter/unit
     tests (fill in per detected language; leave a documented TODO if
     the toolchain isn't chosen yet).
   Then run `lefthook install`. If the `lefthook` binary is missing,
   note that it ships in the dotfiles package lists and stop short of
   guessing an install path.

4. **Common rules → `./CLAUDE.md`** — create the file (or append the
   missing sections; never duplicate an existing one). Write **only the
   subsections whose feature is enabled**: Dependency injection (key
   `dependency-injection`), Unit testing (key `unit-testing`),
   Conventional commits (key `conventional-commits`), Diagram layout (key
   `diagram-layout`); the Pre-CLI-command briefs subsection is always
   written. Omit any subsection whose key is `off`.

   ```
   ## Dependency injection

   Every module takes its external collaborators (I/O, clock, network,
   database, filesystem, randomness, other services) through
   **dependency injection** — depending on an **abstraction**
   (interface / protocol / trait / callable) whose concrete
   implementation is passed in by the caller and wired at a
   **composition root** (startup / `main` / container). Tests inject
   **in-memory fakes**; production injects the **real implementations**
   through the same seam. Never `new` a side-effecting collaborator deep
   inside business logic. Library- and language-agnostic — keep the
   seam, not a specific tool.

   ## Unit testing

   Every module ships **fast, hermetic unit tests** that run with no
   real network, disk, clock, or external service — collaborators are
   replaced with in-memory fakes injected through the DI seam above.
   Tests are deterministic and runnable offline with one command. New
   behavior lands with its tests; prefer test-first.

   ## Conventional commits (lefthook-enforced)

   Commit messages follow Conventional Commits — types: `feat`, `fix`,
   `refactor`, `chore`, `docs`, `style`, `perf`, `build`, `ci`, `test`,
   `revert`; scope optional. The `commit-msg` lefthook hook rejects
   anything not matching the regex above; `pre-commit` runs the
   project's formatters/linters/tests.

   ## Diagram layout (draw.io)

   Connector lines in draw.io diagrams are routed **orthogonally** and
   split into three parts: a **common** segment shared by sibling edges,
   the **vertical** legs that branch off it, and the **item-specific**
   horizontal leg that touches one box. Rules:
   - **No line over a box** — no segment passes on top of or beneath any
     item/box; route around it and avoid crossings.
   - **One-to-many (one source → many targets):** **prefer to route each
     edge as a completely separate line** — no shared or overlapping
     segments. Only when there isn't room to fully separate them, fall back
     to a **common horizontal trunk** shared by the sibling edges (those
     trunks may be merged into one line or lie on top of each other). Either
     way each edge branches off on its **own vertical**; verticals **never
     overlap** — keep a clear gap (≥20px). The final **item-specific
     horizontal leg** into each target is **vertically centered on that
     target box**, and the edge **label rides that leg, next to the box** —
     never on the shared trunk, never on another line.
   - **Many-to-one (many sources → one target):** the mirror image —
     **prefer fully separate lines**; only when space is tight do the edges
     share a single **common horizontal trunk** into the target. Each source
     leaves on its own **item-specific horizontal leg** (vertically centered
     on the source, its **label riding that leg next to the box**), and the
     **spaced verticals** converge. Same common-vs-specific split, reversed.
   - **Two-ended labels (both endpoints labeled — e.g. DB/ER
     cardinalities):** when an edge carries **two** texts, one per endpoint
     (ER one-to-many: `1` at one end, `*`/`N` at the other; many-to-many:
     `*` at both), draw that edge on its **own separate path** — never
     merged onto a shared trunk. Place each text on the **item-specific
     horizontal leg at its own end, next to that item**, and keep each label
     beside the **correct** item (the endpoint it describes).

   ~~~
   one-to-many                        many-to-one
    [S]──┬────┬────┬                   [S1]── L1 ───────────┐
         │    │    └─── L3 ──[T3]      [S2]── L2 ───────┐   │
         │    └──────── L2 ──[T2]      [S3]── L3 ───┐   │   │
         └───────────── L1 ──[T1]                   └───┴───┴──[T]
    common horizontal trunk;           item-specific legs carry the
    verticals spaced; label Ln         labels; verticals spaced;
    rides the leg next to each Tn      common trunk into T

   two-ended labels (ER; each edge on its own path)
    [Author]──1──┐                 [Student]──*──┐
                 └──*──[Book]                    └──*──[Course]
    one-to-many: "1"/"*" each       many-to-many: "*" on each leg,
    on the leg next to its entity   next to its own entity
   ~~~

   ## Pre-CLI-command briefs

   Before running CLI commands (shell / Bash), first print a table
   summarizing what will run — one row per command — then run them.
   Columns: **#**, **Command**, **Action brief**, **Effect**
   (read-only / writes / network / destructive). This makes intent
   reviewable before anything executes; it does not replace explicit
   confirmation for destructive or outward-facing actions.
   ```

5. **Logging** *(key `logging`)* — unless disabled by an override,
   invoke the `/logging` building block so the centralized multi-writer
   logging rule is pinned (defined in exactly one place, not duplicated
   here). Types that don't do userland logging (e.g. kernel drivers)
   disable this and state their own convention.

6. **Project-local commands → `./.claude/commands/`** *(key
   `project-commands`)* — unless disabled, add thin, project-aware
   `/commit` (build a Conventional Commit from the staged diff, honoring
   the lefthook regex) and `/check` (run the project's lint + tests)
   commands.

7. **Unit-test skeleton** *(key `test-skeleton`)* — unless disabled,
   create the conventional test directory for the detected language with
   one placeholder test, so the `pre-commit` test step has something to
   run.

8. **Report** every file created/edited and CLI step run, and suggest
   committing with the project's own Conventional Commit convention —
   do not commit automatically.
