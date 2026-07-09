---
description: Pin dependency injection as this project's standard by writing a rule into its local ./CLAUDE.md — every module takes its collaborators via DI so tests inject in-memory mocks and production injects the real implementations.
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(test*), Bash(cat*)
---

Pin the **dependency-injection convention** for the **current project** by
adding a short rule to its local `./CLAUDE.md`. This is the reusable
mechanism for the standing preference "every module is testable by
injecting in-memory fakes" — run it once per code project. It is
intentionally **library- and language-agnostic**: it states the
requirement, each project picks whatever DI style fits (constructor
injection, an interface + factory, a DI container, function parameters).

Procedure:

1. **Locate the project file** at the repo root: `./CLAUDE.md`. If it
   doesn't exist yet, you'll create it.

2. **Idempotency / conflict check.** If a `## Dependency Injection`
   section already states the same rule, report "already set" and stop.
   If it names a *conflicting* convention (e.g. modules that hard-wire
   their own I/O, global singletons instantiated at point of use), show
   the existing line and confirm before replacing it.

3. **Write the rule** — append the section (or create the file with it):

   ```
   ## Dependency Injection

   Every module takes its external collaborators (I/O, clock, network,
   database, filesystem, randomness, other services) through
   **dependency injection** rather than constructing them internally or
   reaching for a global. A module depends on an **abstraction**
   (interface / protocol / trait / callable), and the concrete
   implementation is passed in by the caller.

   This exists to make modules testable in isolation:
   - **In tests**, inject **in-memory fakes/mocks** — no real network,
     disk, or clock — so tests are fast, deterministic, and hermetic.
   - **In production**, inject the **real implementations** through the
     same seam.

   Rules of thumb:
   - No `new`-ing a collaborator deep inside business logic; wire
     dependencies at a **composition root** (startup / main / DI
     container) and pass them down.
   - Every side-effecting dependency sits behind an interface the
     project can re-implement in memory for tests.
   - Pick any DI style that satisfies this (constructor injection,
     interface + factory, parameter passing, a container library);
     library- and language-agnostic — keep the seam, not a specific tool.
   ```

4. **Report** which file was created/edited, and suggest committing it
   using the project's own commit convention — do not commit automatically.

Note: this is intentionally a per-project command rather than an
always-loaded global rule, so it does not load into non-code projects
(dotfiles, docs, config repos) where it is irrelevant.
