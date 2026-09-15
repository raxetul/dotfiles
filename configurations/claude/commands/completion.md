---
description: Report project progress — the phase table with completion status, plus the Awaiting list of what the agent needs from the user. Read-only.
allowed-tools: Read, Glob, Bash(grep:*), Bash(ls:*)
---

Report where this project stands: phases, completion, and what it is waiting on
you for. Read-only — never modify a file.

## 1. Locate the sources

| Source | Holds | If missing |
| --- | --- | --- |
| `docs/progress.md` | phase table + the **Awaiting** section (pillar 3) | fall through to `PHASES.md` |
| `PHASES.md` (repo root, else Glob `**/PHASES.md`) | legacy phase list — `- [x]` done, `- [ ]` pending | say so and stop |
| `docs/requirements.md`, else `REQUIREMENTS.md` | the **Phase ↔ Requirement Mapping** table | requirements column shows `—` |

A project may carry either layout. Say which one you read; don't silently
prefer one and leave the reader guessing which file is authoritative.

## 2. Phase table

One row per phase:

| Column | Contents |
| --- | --- |
| **#** | P1, P2, … in listed order |
| **Phase** | the phase title |
| **Status** | `✅ Done` / `⬜ Pending`; append `(current)` to the **first** pending phase |
| **Requirements** | the requirement IDs mapped to that phase, or `—` |

Follow it with one line: `N of M phases complete`, naming the current phase.

## 3. Awaiting — what I need from you

Then the **Awaiting** list, from `progress.md`'s Awaiting section. This is the
half that makes the command worth running: a phase table says where the work is,
the awaiting list says what is stopping it.

| Column | Contents |
| --- | --- |
| **#** | A1, A2, … |
| **Needs** | what is being asked of the user — a decision, an approval, a credential, a file |
| **Blocks** | which phase or requirement ID it is holding up |
| **On answer** | what happens once it is supplied |

Rules:

- 🟢 Nothing awaiting → say `Awaiting: nothing` on one line. Do not print an
  empty table.
- 🔴 An item blocking the **current** phase is listed first and marked — that is
  the difference between "progressing" and "stalled", and a phase table alone
  cannot show it.
- Report items exactly as written. This command does not add, resolve or
  reword them; it reads state. Items are added when the agent hits the blocker
  and removed in the change that acts on the answer.
- An item with no **Blocks** value is still listed, flagged 🟡 — an entry that
  blocks nothing is either resolved and not removed, or was never a real
  blocker. Say which you think it is.

## 4. Close

Nothing beyond the two tables and the summary line. If both the phase source and
the awaiting section are missing, say the project has no progress tracking and
name the paths you tried — don't infer progress from git history.
