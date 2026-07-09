---
description: Initialize a desktop-application project — runs the common baseline, then pins UI/work-thread separation, an MVVM/MVC boundary, an injectable persistence seam, and packaging rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **desktop application** project in the **current
directory**. Follow the pre-CLI-brief + confirm-destructive contract,
and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package).

2. **Desktop rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Desktop app architecture

   - **Never block the UI thread**: long/IO work runs off the UI thread
     and marshals results back; the UI stays responsive.
   - **Presentation boundary**: MVVM / MVC / equivalent — view logic is
     separated from domain logic and is unit-testable without a running
     window.
   - **Persistence, filesystem, OS integration, and network sit behind
     interfaces** injected into the view-models/controllers (the DI seam
     from the common baseline), with in-memory fakes for tests.
   - **Packaging/distribution** and update strategy are defined up front
     for each target OS.
   ```

3. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
