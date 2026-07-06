---
description: Pin centralized, multi-writer logging as this project's standard by writing a rule into its local ./CLAUDE.md — one logger init at startup, pluggable + custom writers, library-agnostic.
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(test*), Bash(cat*)
---

Pin the **logging convention** for the **current project** by adding a
short rule to its local `./CLAUDE.md`. This is the reusable mechanism for
the standing preference "every project uses one centralized, extensible
logging system" — run it once per code project. It is intentionally
**library-agnostic**: it states the requirements, each project picks a
library that satisfies them.

Procedure:

1. **Locate the project file** at the repo root: `./CLAUDE.md`. If it
   doesn't exist yet, you'll create it.

2. **Idempotency / conflict check.** If a `## Logging` section already
   states the same centralized/multi-writer rule, report "already set"
   and stop. If it names a *conflicting* logging convention (e.g. "log
   with bare stdout" or a single hard-wired sink), show the existing line
   and confirm before replacing it.

3. **Write the rule** — append the section (or create the file with it):

   ```
   ## Logging

   This project uses a **centralized logging system**, initialized **once
   at startup** from a single place (one logger-init module/function).
   Application code logs through that shared logger — no ad-hoc
   `print` / `console.log` / `println!` / raw-stdout logging scattered
   through the code.

   The logging library MUST support:
   - **Multiple writers/sinks at once** — e.g. console + file + remote
     (syslog/HTTP/etc.), enabled and configured at the single init point.
   - **Custom writers** — a writer/sink/appender interface the project
     can implement to add platform-specific outputs without changing
     call sites.

   Pick any library that satisfies both (library-agnostic); if none
   fits the platform, wrap the platform logger behind a thin interface
   that provides the same multi-writer + custom-writer capability.
   ```

4. **Report** which file was created/edited, and suggest committing it
   using the project's own commit convention — do not commit automatically.

Note: this is intentionally a per-project command rather than an
always-loaded global rule, so it does not load into non-code projects
(dotfiles, docs, config repos) where it is irrelevant.
