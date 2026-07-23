---
description: Initialize a monorepo — asks which project kinds to include (backend, frontend, embedded, cli, …), lays down one shared root baseline, then gives each package its own nested CLAUDE.md via the matching /init-proj-<type> command.
allowed-tools: Read, Write, Edit, Skill, AskUserQuestion, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **monorepo** in the **current directory**: one repository
holding several projects, with a single shared baseline at the root and
**per-package rules** so each session only loads the `CLAUDE.md` of the
package being worked on (small-context aim). Follow the pre-CLI-brief +
confirm-destructive contract, and keep every step idempotent.

Procedure:

1. **Ask what goes in** — use `AskUserQuestion`:
   - **Which project kinds** to include (multi-select): `backend`,
     `frontend`, `embedded-firmware`, `kernel-driver`, `cli`,
     `desktop`, `mobile`. Allow more than one of the same kind (ask for
     a package name each).
   - **Package layout directory**: `apps/` vs `packages/` (or a custom
     name). Default `packages/`.
   Confirm the resulting plan (root + the list of `<layout>/<name>`
   packages and their kinds) before writing anything.

2. **Root baseline (once)** — invoke `/init-proj-common` at the repo
   root. Git and lefthook (conventional commits) live here, at the root,
   for the whole monorepo. Then append a root section:

   ```
   ## Monorepo layout

   This is a monorepo. Git and the lefthook conventional-commit hooks
   live at the **root** and cover every package. Each package under
   `<layout>/` owns a nested `CLAUDE.md` with its type-specific rules;
   those load only when working inside that package. Root-level rules
   (DI, unit testing, logging, diagram layout, pre-CLI briefs, conventional
   commits) apply everywhere and are not repeated per package.
   ```

3. **Each package** — for every selected `<layout>/<name>` + kind:
   - `mkdir -p <layout>/<name>`.
   - Run the matching `/init-proj-<kind>` **scoped to that package
     directory**. Because `/init-proj-common` is idempotent, its
     per-package run finds the root git + lefthook already present and
     **skips them**, writing only the package's own `./CLAUDE.md` (type
     rules) and scaffolding. Do **not** create nested git repos or
     per-package lefthook installs.

4. **Report** the tree created (root baseline + each package and its
   kind), all files written, and CLI steps run; suggest committing with
   the Conventional Commit convention.
