---
description: Measure how much of the requirements catalog is actually covered by tests — per requirement, per phase, and overall. Read-only; reports coverage, never edits requirements or writes tests.
argument-hint: "[path to requirements file, or a phase/ID filter]"
allowed-tools: Read, Glob, Grep, Bash(ls*), Bash(cat*), Bash(rg*), Bash(wc*), Bash(git log*), Bash(git grep*)
---

Report requirements-to-test coverage for this project. Target (if given): $ARGUMENTS

**Read-only.** Never write a test, never edit a requirement, never change a
config. The output is a report.

This measures **requirements coverage** — how many requirements have a test that
demonstrably exercises them. That is not line coverage. A repo at 95% lines can
have requirements with no test at all, and that gap is the point of this command.

## 1. Locate the requirements

In order, first hit wins — unless `$ARGUMENTS` names a path/glob, which always
wins: `REQUIREMENTS.md` → `docs/requirements*.md` → `doc/requirements*.md` →
`docs/**/requirements*.md` → `PHASES.md`.

Nothing matched → say which paths you tried and stop. Don't invent a catalog.

`$ARGUMENTS` may instead be a filter (`Phase 5`, `TR-05`, `FR-`): report only
matching requirements and say so in the header.

## 2. Locate the tests

Find the test files first, and say what you found before using it. Look for the
project's own runner and layout rather than assuming one:

- config: `package.json` (`scripts.test`, `jest`/`vitest` keys), `jest.config.*`,
  `vitest.config.*`, `pytest.ini`, `pyproject.toml`, `Cargo.toml`, `go.mod`,
  `CMakeLists.txt`, `.github/workflows/*`
- files: `**/*.test.*`, `**/*.spec.*`, `**/test_*.py`, `**/*_test.go`,
  `tests/**`, `test/**`, `src/**/tests/**`, `#[cfg(test)]` blocks in Rust

No tests at all → report 0% with the paths you searched, and stop. That is a
valid, useful answer; do not pad it.

## 3. Match requirements to tests — evidence, in this order

A requirement counts as covered only on evidence you can cite as `file:line`.
Record which rung the evidence came from, because the rungs differ in strength:

| Rung | Evidence | Strength |
| --- | --- | --- |
| 1 | Test names or cites the requirement ID (`it('… (FR-05-004)')`, a comment) | explicit — the author asserted the link |
| 2 | The requirement's **Accept** criterion maps onto a concrete assertion | strong — verify the assertion really tests that criterion |
| 3 | The test exercises the named symbol/module/behaviour, no ID or Accept link | weak — mark it, never silently promote it |

Rung 3 is `⚠ inferred`, not covered. Keep it in its own column; do not fold it
into the covered count. Inflated coverage is the failure mode this command
exists to prevent, so when the evidence is thin, say thin.

**A requirement with no `Accept` line cannot reach rung 2.** Report it as
`unverifiable` rather than uncovered — the defect is in the requirement, and the
fix is `/analyze-requirements`, not a new test.

## 4. Report

Open with one line: the number covered out of the total, and the percentage.
Then, in this order:

### Summary

| Metric | Count | % |
| --- | --- | --- |
| Requirements total | | |
| 🟢 Covered (rung 1–2) | | |
| 🟡 Inferred only (rung 3) | | |
| 🔴 Uncovered | | |
| ⚫ Unverifiable (no Accept) | | |

State the requirements file, the test files scanned, and the filter if any.

### Per phase

| Phase | Total | 🟢 | 🟡 | 🔴 | ⚫ | Coverage |
| --- | --- | --- | --- | --- | --- | --- |

Skip this table when the catalog has no phase structure — don't fabricate one.

### Uncovered and inferred — the actionable list

| ID | Requirement (short) | Status | Why | Suggested test |
| --- | --- | --- | --- | --- |

Covered requirements do **not** get a row here. List them separately, one line
each, `ID → test file:line (rung)`, only if the catalog is small enough that the
list stays readable; otherwise give the count and move on.

## 5. Close

**Top 3 gaps to close first**, ordered by risk, each one line with its ID and
why it matters — a MUST-priority requirement with no test outranks a COULD with
a weak one. Then stop.

Do not offer to write the tests unless asked. If asked, the tests go through
whatever TDD workflow the project already uses, not this command.

## Honesty rules

- Cite `file:line` for every covered claim. No citation → not covered.
- Never infer coverage from a filename alone (`storage.test.ts` existing does
  not cover `STR-2`).
- A skipped/`.skip`/`#[ignore]`/`xit` test is **not** coverage. Flag it — a
  disabled test is worse than a missing one, because it reads as covered.
- If the project type makes a rung-2 match genuinely hard (embedded HIL, manual
  QA steps), say so rather than guessing; report those requirements as
  `unverifiable by static inspection` with the reason.
