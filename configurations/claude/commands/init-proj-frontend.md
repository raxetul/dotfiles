---
description: Initialize a frontend/fullstack project — runs the common baseline, then pins component structure, centralized state, an injectable API-client seam, and accessibility rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **frontend / fullstack UI** project in the **current
directory**. Follow the pre-CLI-brief + confirm-destructive contract,
and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package).

2. **Frontend rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Frontend architecture

   - **Components** split into presentational (pure, prop-driven) and
     container (data/state) layers; no business logic or direct network
     calls inside presentational components.
   - **State** is managed centrally (store / context / signals) — not
     scattered ad-hoc; derive, don't duplicate.
   - **The API/data client sits behind an interface** injected into
     components/hooks (the DI seam from the common baseline), so views
     are unit-tested against an in-memory client — no live network.
   - **Styling** follows one convention project-wide; theme tokens over
     inline literals.
   - **Accessibility** is a requirement, not a nicety: semantic markup,
     keyboard paths, and labels are part of "done".
   ```

3. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
