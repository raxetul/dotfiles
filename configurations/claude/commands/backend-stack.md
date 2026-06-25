---
description: Pin this project's backend framework by writing a rule into the local ./CLAUDE.md — Rust→Loco, Java→Spring Boot, JS/TS→NestJS.
argument-hint: "[language]  (rust | java | js | ts — default: rust)"
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(test*), Bash(cat*)
---

Pin the backend framework for the **current project** by adding a short
rule to its local `./CLAUDE.md`. Language to use: `$ARGUMENTS`
(default `rust` when no argument is given).

Procedure:

1. **Resolve language → framework** from `$ARGUMENTS`, case-insensitive,
   defaulting to `rust` when empty:
   - `rust` → **Loco** (`loco.rs`)
   - `java` → **Spring Boot**
   - `js` / `javascript` / `ts` / `typescript` / `node` → **NestJS**
   - anything else → stop and ask which framework to use for that
     language; do not guess.

2. **Locate the project file** at the repo root: `./CLAUDE.md`. If it
   doesn't exist yet, you'll create it.

3. **Idempotency / conflict check.** If a `## Backend framework` section
   already names the same framework, report "already set" and stop. If
   it names a *different* framework, show the existing line and confirm
   before replacing it.

4. **Write the rule** — append the section (or create the file with it):

   ```
   ## Backend framework

   This project's backend is built with <framework> (<language>). Use it
   for new backend services in this repo unless explicitly told otherwise.
   ```

5. **Report** which file was created/edited and the framework pinned.
   Suggest committing it using the project's own commit convention — do
   not commit automatically.
