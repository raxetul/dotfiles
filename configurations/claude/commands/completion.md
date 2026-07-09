---
description: List all project phases with their completion status in a table
allowed-tools: Read, Glob, Bash(grep:*)
---

Show the project's phases with completion status as a Markdown table.

Steps:
1. Read `PHASES.md` at the repo root (the source of truth for phase order and
   completion — `- [x]` = complete, `- [ ]` = pending; the first `- [ ]` is the
   current phase). If it is not at the root, locate it with Glob (`**/PHASES.md`).
2. If `REQUIREMENTS.md` exists, also read its **Phase ↔ Requirement Mapping**
   table so you can show requirement coverage per phase.
3. Emit a single Markdown table, one row per phase, with these columns:
   - **#** — phase number/index in listed order (P1, P2, …).
   - **Phase** — the phase title from `PHASES.md`.
   - **Status** — `✅ Done` for `- [x]`, `⬜ Pending` for `- [ ]`, and append
     `(current)` to the first pending phase.
   - **Requirements** — the requirement IDs mapped to that phase (from
     `REQUIREMENTS.md`), or `—` if unavailable.
4. Below the table, add a one-line summary: `N of M phases complete` and name the
   current phase.

Keep the output to just the table plus that one summary line — no extra prose.
Do not modify any files; this command is read-only.
