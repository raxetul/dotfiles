---
description: Update an already-initialized project to the CURRENT /init-proj-* scaffolding — reconcile its ./CLAUDE.md with the latest rules and bring existing artifacts/files into compliance with any rule that is new or changed. Idempotent; plans and confirms before writing; never commits automatically.
allowed-tools: Read, Write, Edit, Skill, AskUserQuestion, Bash(git*), Bash(ls*), Bash(test*), Bash(cat*), Bash(mkdir*), Bash(lefthook*)
---

Re-apply the **current** `/init-proj-*` scaffolding to an **already
initialized** project. Use this after the scaffolding commands gain a new
rule (or an existing rule changes): it updates the project's `./CLAUDE.md`
to match the latest baseline **and** conforms the project's existing
artifacts/files to any rule that is new or changed — so a project scaffolded
weeks ago picks up today's standards without a manual redo.

This is the reconcile counterpart to the `/init-proj-*` family: those
initialize a fresh project; this one **re-applies** them to an existing one.
It follows the same family contract — **idempotent**, **pre-CLI brief before
any CLI step**, **confirm destructive / outward-facing steps**, all writes stay
in the project, and it **never commits automatically**.

Procedure:

1. **Identify the project.** Locate the project root, then read its
   `./CLAUDE.md` and layout to determine which scaffolding applies:
   - the **type** — backend / frontend / embedded-firmware / kernel-driver /
     cli / desktop / mobile — inferred from the project's own rules and stack,
     or asked with `AskUserQuestion` when ambiguous;
   - whether it is a **monorepo** (a root baseline plus nested package
     `CLAUDE.md`s); if so, treat the **root** and **each package** separately,
     using each package's own kind.
   Report the detected type(s) and confirm before continuing.

2. **Reconcile the rules (`./CLAUDE.md`).** Re-invoke the matching command(s)
   — `/init-proj-<type>` per project/package, `/init-proj-common` for a plain
   or root baseline — relying on their **idempotency**: existing sections are
   left untouched and any **missing** section (e.g. a newly added rule such as
   *Diagram layout*) is appended. Record the set of sections **added or
   changed** in this run — that set drives step 3.

3. **Conform existing artifacts to the new/changed rules.** For every rule
   added or changed in step 2, bring the project's existing files into
   compliance — this is what makes the command more than a re-scaffold:
   - Work out which artifacts the rule governs — e.g. a **diagram-layout** rule
     → the project's diagrams and their generator; an **error-format** rule →
     error responses / handlers; a **logging** rule → logger init; a
     **conventional-commits** rule → `lefthook.yml`.
   - Regenerate or edit those artifacts to satisfy the rule, preferring the
     project's **own** generator / build where one exists (invoke `/run` or the
     documented regen command), then **verify** the result — render a diagram,
     run the relevant tests — before treating it as done.
   - Present each remediation as a **change plan / pre-CLI brief** and
     **confirm** before writing. Leave already-compliant artifacts untouched.

4. **Keep docs & requirements in sync.** If the project tracks living docs or
   requirements (e.g. `docs/`, `REQUIREMENTS.md`, `PHASES.md`), update them in
   the same pass so they reflect every artifact this command changed —
   matching that project's own definition of done.

5. **Report** each `./CLAUDE.md` section reconciled, each artifact conformed,
   and each CLI step run; list anything skipped as already compliant; and
   suggest committing with the project's Conventional Commit convention — do
   **not** commit automatically.
