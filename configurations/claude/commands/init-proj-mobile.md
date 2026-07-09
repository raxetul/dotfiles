---
description: Initialize a mobile-application project — runs the common baseline, then pins an MVVM/MVI boundary, off-main-thread work, offline-first data, and injectable network/storage seams into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **mobile application** project (iOS / Android /
cross-platform) in the **current directory**. Follow the pre-CLI-brief +
confirm-destructive contract, and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package).

2. **Mobile rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Mobile app architecture

   - **Never work on the main/UI thread**: network, disk, and heavy
     compute run on background dispatchers and post results back.
   - **Presentation boundary**: MVVM / MVI / equivalent — screen logic
     is unit-testable without the UI framework or a device.
   - **Network and local storage sit behind repository interfaces**
     injected into view-models (the DI seam from the common baseline),
     tested against in-memory fakes.
   - **Offline-first**: define the source of truth and the
     sync/conflict strategy; the UI reads from the local store.
   - **Lifecycle & permissions** handled explicitly; no leaked
     contexts/observers.
   ```

3. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
