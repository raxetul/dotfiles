---
description: Audit a requirements catalog for atomicity, design detail (solution leakage), redundancy and contradiction — reports each class in its own table. Read-only; never edits the requirements.
argument-hint: "[path/glob to the requirements file(s), or a phase/ID filter]"
allowed-tools: Read, Glob, Grep, Bash(ls*), Bash(cat*), Bash(wc*), Bash(git log*), Bash(git show*)
---

Audit the requirements in this project and report quality issues. Target (if given): $ARGUMENTS

**This command is read-only.** It never edits, renumbers, splits, or deletes a
requirement. Requirements are a controlled artifact — every finding is a
*proposal* for their owner to accept or reject. Output is a report, nothing else.

## 1. Locate the source

In order, first hit wins — unless `$ARGUMENTS` names a path/glob, which always wins:
`REQUIREMENTS.md` → `docs/requirements*.md` → `doc/requirements*.md` →
`docs/**/requirements*.md` → `PHASES.md`.

If nothing matches, say exactly which paths you tried and stop. Don't invent a
catalog and don't analyze prose that isn't a requirements list.

If `$ARGUMENTS` is a phase tag or ID prefix (`Phase 5`, `TR-05`, `FR-`), analyze
only matching requirements and say so in the header.

## 2. Set the bar for this project

Read the project's `./CLAUDE.md` for its **type**:

- **work** → the Büyütech bar applies. Judge against ASPICE requirement
  attributes (uniquely identified, atomic, verifiable, unambiguous, free of
  design detail, traceable both ways) and, where a requirement is
  safety-related, ISO 26262 wording discipline. Name the criterion you applied.
- **personal** → same four checks, no ASPICE/ISO framing, no "customer"
  assumptions.
- **unknown** → run the analysis, and say which bar you used.

## 3. Report — four separate tables, always all four

Open with a count summary, then one table per class **in this order**. A class
with no findings still gets its table, holding a single `— none found —` row;
never drop a table and never merge two classes into one.

Rules for every table:

- **Excerpts are verbatim.** Quote the requirement's own words, trimmed with `…`.
  Never paraphrase into something that looks like a quote.
- **Only real IDs.** If a requirement has no ID, refer to it by file:line. Never
  invent, guess, or renumber an ID.
- **Severity**: `🔴 Critical` (ships a defect / blocks verification) ·
  `🟡 Major` (real ambiguity, needs a decision) · `🔵 Minor` (wording).
- Uncertain findings are labelled as such rather than stated as fact.

### Summary

| Class | Findings | 🔴 | 🟡 | 🔵 |
| --- | --- | --- | --- | --- |
| Atomicity | | | | |
| Design detail | | | | |
| Redundancy | | | | |
| Contradiction | | | | |

Follow it with: requirements analyzed, IDs skipped (and why), and the bar used.

### Table 1 — Atomicity

One requirement, one independently verifiable statement. Flag: two or more
`shall`s; verifiable predicates joined by *and / or / as well as / plus*;
`and/or`; a bulleted list of distinct behaviors under one ID; a single ID mixing
unrelated trigger→action pairs. Do **not** flag a compound *condition* guarding
one action — that is still atomic.

| ID | Excerpt (verbatim) | Why not atomic | Proposed split | Severity |
| --- | --- | --- | --- | --- |

### Table 2 — Design detail (solution leakage)

The requirement states **how** instead of **what**. Flag named libraries,
algorithms, data structures, class/table/column names, pin or register numbers,
protocols, or file formats where the actual need is behavioral.

Guard against the classic false positive: a mechanism that is genuinely
**imposed** — a mandated bus, a customer or standard-fixed interface, a legal
format — is a *constraint*, not leakage. Give such rows the verdict
`constraint, not leakage` and leave them unflagged in the counts.

| ID | Excerpt (verbatim) | Leaked mechanism | WHAT-level restatement | Verdict | Severity |
| --- | --- | --- | --- | --- | --- |

### Table 3 — Redundancy

Group the overlapping IDs on one row — never one row per member. Types:
`exact duplicate` · `subsumption` (one fully implies the other) ·
`partial overlap` (shared clause, each has unique content).

| IDs in group | Overlap type | Shared content | Recommended action | Severity |
| --- | --- | --- | --- | --- |

### Table 4 — Contradiction

Pairwise, most severe first. Types: `direct negation` · `threshold conflict`
(different numbers, same property) · `unit mismatch` · `timing conflict` ·
`conditional overlap` (same trigger, different mandated outcome).

Both excerpts must be quoted — a contradiction claim is worthless without the
two texts side by side.

| ID A | Excerpt A | ID B | Excerpt B | Conflict type | Severity |
| --- | --- | --- | --- | --- | --- |

## 4. Close

End with **Top 3 to fix first** — a short ordered list, each with its ID and a
one-line reason. If a finding depends on an assumption you had to make, state
the assumption. If the catalog is clean, say so plainly rather than padding the
tables with weak findings.

Do not offer to apply the fixes unless asked; if the user then wants them,
`/next-phase-requirements` is the command that writes requirements.
