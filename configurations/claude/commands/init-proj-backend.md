---
description: Initialize a backend/API project — runs the common baseline, then pins framework (via /backend-stack), RFC 9457 errors (via /rfc9457), and layered-architecture rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **backend / server / API** project in the **current
directory**. Follow the pre-CLI-brief + confirm-destructive contract,
and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`. It is
   idempotent, so in a monorepo package where the root already has
   git + lefthook it simply writes this package's `./CLAUDE.md` and
   skips the root-level steps.

2. **Pin the framework** — invoke `/backend-stack` so the backend
   framework is fixed by language (its rule text lives there, not here).

3. **Pin the error format** — invoke `/rfc9457` so error responses use
   RFC 9457 Problem Details.

4. **Backend rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Backend architecture

   - **Layered**: transport/handler → service/use-case → repository.
     Business logic never imports the web framework or the DB driver
     directly; both sit behind interfaces (the DI seam from the common
     baseline), so services are unit-tested against in-memory repos.
   - **Configuration** comes from the environment / a config object
     injected at the composition root — no reading env vars deep in
     handlers.
   - **API**: version the surface; validate every request at the edge;
     never leak internal errors — map them to RFC 9457 problems.
   - **Persistence** and outbound calls go through repository/client
     interfaces with in-memory fakes for tests.
   ```

5. **Report** files created/edited and building-block commands invoked;
   suggest committing with the Conventional Commit convention.

Note — two layers: this command (and its building blocks) scaffold the
**strict, enforced rules** into `./CLAUDE.md`. The matching **auto-loading
skills** carry the evolving implementation depth and load only when relevant:
`backend-stack-patterns`, `rfc9457-problem-details`, `logging-patterns`. Rules
are guaranteed and versioned in the repo; skills are maintained centrally and
never drift into each project.
