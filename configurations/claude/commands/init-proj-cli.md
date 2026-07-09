---
description: Initialize a CLI-tool project — runs the common baseline, then pins argument-parsing, exit-code, stdout/stderr, and config-precedence rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **command-line tool** project in the **current
directory**. Follow the pre-CLI-brief + confirm-destructive contract,
and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package).

2. **CLI rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## CLI conventions

   - **Arguments** are parsed with an established parser; every command
     has `--help` and the tool has `--version`.
   - **Exit codes**: `0` success, documented non-zero codes for failure
     classes; never exit `0` on error.
   - **Streams**: machine-readable output to **stdout**, diagnostics/logs
     to **stderr**. Support a `--json`/quiet mode where output is
     consumed by scripts.
   - **No interactive prompts when stdin is not a TTY** — fail with a
     clear message or read flags/env instead.
   - **Config precedence**: flags > environment > config file >
     built-in default; the resolver is injected (DI seam) so it is
     unit-tested without touching the real environment.
   - **Side effects** (filesystem, network, clock) sit behind interfaces
     with in-memory fakes for tests.
   ```

3. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
