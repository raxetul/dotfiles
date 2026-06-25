---
description: Implement the current pending phase test-first — GATED: refuses unless EVERY phase already has its requirements authored (no TBD anywhere)
argument-hint: "[optional phase number, e.g. 3]"
---
Implement a phase of the project, **gated on full requirements coverage across the entire roadmap**.

**Gate — evaluate this FIRST, before reading anything else or touching code:**
1. Read the **Phase ↔ Requirement Mapping** table in `REQUIREMENTS.md`.
2. If **any** phase row is still `TBD` (no requirements mapped), **STOP. Do not implement anything.** Report every phase that is still unmapped and instruct the user to run `/next-phase-requirements` (repeatedly) until every phase has requirements. Implementing *any* phase is forbidden while even one phase remains unspecified — this is a hard rule, not a warning.

**Only when every phase has requirements (no TBD remains):**
3. Read `PHASES.md`. Target phase = the argument if given (`$ARGUMENTS`), otherwise the **first unchecked** `- [ ]` item (the current phase).
4. Collect every requirement mapped to that phase (from the mapping table), plus the cross-cutting requirements (e.g. TR-00-001 TDD).
5. Honor the locked project decisions documented in the repo (language, auth, stack, conventions).
6. Follow **TDD** (TR-00-001): for each requirement, write failing tests from its **Accept** criteria first (red), implement until green, then refactor. Add no behavior without a test in the same change.
7. When all of the phase's requirements pass their tests, mark the phase `- [x]` in `PHASES.md`.

Report which requirements you covered (by ID) and the tests proving each.
