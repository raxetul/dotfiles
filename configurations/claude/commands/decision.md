---
description: Record a technical decision as an ADR-style entry in docs/decisions.md — assigns the next TD-NNN id and cross-links the requirements it serves. Proposes first, writes on confirmation.
argument-hint: "[the decision, or a TD id to revisit]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls:*), Bash(git log:*), Bash(git diff:*)
---

Record a technical decision (pillar 2). Subject: $ARGUMENTS

A decision entry exists to answer **"why is it like this?"** a year from now,
when the person asking is you and the alternatives are no longer obvious. If an
entry doesn't survive that test, it isn't worth writing.

## 1. Locate the file

`docs/decisions.md` → else `doc/decisions.md` → else `docs/adr/`. None of them
exist → say so and offer to create `docs/decisions.md` per the six-pillar layout
(`/create-documentation` lays out the full tree).

`$ARGUMENTS` naming an existing id (`TD-004`) means **revisit**, not duplicate —
jump to §5.

## 2. Assign the id

`TD-NNN`, next free number, zero-padded, never reused. A superseded decision
keeps its id and its text; it is not edited into the new answer and it is not
deleted. The history of what was believed is the record's value.

## 3. Write the entry

```markdown
## TD-007 — <short imperative title>

**Status:** Accepted · **Date:** YYYY-MM-DD
**Serves:** FR-03-002, NFR-01-001
**Supersedes:** TD-004   <!-- omit when nothing is superseded -->

### Context
What forced a decision. The constraint, the pressure, the thing that broke.

### Options
| Option | Cost | Why not / why yes |
| --- | --- | --- |

### Decision
The choice, in one sentence, in the active voice.

### Consequences
What this makes easy, what it makes hard, and what it rules out later.
```

Status is one of `Proposed`, `Accepted`, `Superseded by TD-NNN`, `Deprecated`.

**The Options table is the part that matters.** A single-row table means no
decision was made — something was assumed. Either find the alternative that was
really weighed, or say plainly that none was, and record the assumption instead.
The Consequences section must include at least one cost; a decision with only
upsides was not a decision.

## 4. Cross-link, both directions

A one-way link rots. Both halves go in the **same change**:

- The entry's **Serves:** lists the requirement IDs it constrains.
- Each of those requirements gains a `per TD-NNN` reference in the requirements
  file.

Neither file restates the other's content — requirements say *what*, decisions
say *why*. When they start repeating each other, the link is being used as an
excuse to duplicate.

🔴 A requirement ID in **Serves:** that does not exist in the requirements file
is an error, not a note: name it and stop rather than writing a dangling link.

## 5. Revisiting an existing decision

Never edit an accepted entry's Context, Options or Decision. Instead:

1. Write a **new** entry with the next id, with `Supersedes: TD-NNN`.
2. Set the old entry's status to `Superseded by TD-<new>`. That one line is the
   only edit permitted to it.
3. Move the requirement cross-links to the new id.

## 6. Propose, then write

Show the drafted entry and the exact requirement-file edits, and **wait for
confirmation** before writing. On approval, write both halves and report the id,
the file, and the requirement IDs touched.

Do not commit automatically.
