---
description: Scaffold the shared baseline for the current project — git init, lefthook + conventional commits, and the common rules (dependency injection, unit testing, logging, pre-CLI briefs) written into the project's own ./CLAUDE.md.
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

Procedure:

1. **Locate the project root** (current directory, or the enclosing git
   root if one exists). Report it and confirm before writing.

2. **git** — if there is no `.git`, run `git init`. Skip if already a
   repository (the monorepo case: git lives at the root).

3. **lefthook + conventional commits** — if `lefthook.yml` is absent,
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
   missing sections; never duplicate an existing one):

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

   ## Pre-CLI-command briefs

   Before running CLI commands (shell / Bash), first print a table
   summarizing what will run — one row per command — then run them.
   Columns: **#**, **Command**, **Action brief**, **Effect**
   (read-only / writes / network / destructive). This makes intent
   reviewable before anything executes; it does not replace explicit
   confirmation for destructive or outward-facing actions.
   ```

5. **Logging** — invoke the `/logging` building block so the centralized
   multi-writer logging rule is pinned (defined in exactly one place,
   not duplicated here).

6. **Project-local commands → `./.claude/commands/`** — add thin,
   project-aware `/commit` (build a Conventional Commit from the staged
   diff, honoring the lefthook regex) and `/check` (run the project's
   lint + tests) commands.

7. **Unit-test skeleton** — create the conventional test directory for
   the detected language with one placeholder test, so the `pre-commit`
   test step has something to run.

8. **Report** every file created/edited and CLI step run, and suggest
   committing with the project's own Conventional Commit convention —
   do not commit automatically.
