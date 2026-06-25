---
description: Author requirements for the next phase that still lacks them (first phase whose mapping row is TBD); propose, confirm, then update the catalog
argument-hint: "[optional topic/notes]"
---
Author the requirements for the **next phase that has none yet** in `REQUIREMENTS.md`. Notes/topic (if any): $ARGUMENTS

1. Read `PHASES.md` and the **Phase ↔ Requirement Mapping** table in `REQUIREMENTS.md`. (If either file is missing, say so and stop — this command assumes the agentic phase/requirement layout.)
2. **Target phase** = the first phase in roadmap order whose mapping row is still `TBD` (no requirements mapped). If *every* phase already has requirements, report that the catalog is complete and stop — there is nothing to author.
3. Draft the requirements for that phase:
   - Two groups only: **Feature** (`FR-PP-NNN`, user/product-facing) and **Technical** (`TR-PP-NNN`, stack/infra/cross-cutting quality). Foundational/infra phases are typically all Technical.
   - **ID format** `TR-PP-NNN` / `FR-PP-NNN`: `PP` = the target phase number, zero-padded (`00` = cross-cutting/all-phases); `NNN` = the next free sequence **within that phase + group**, zero-padded, starting at `001`. Never renumber existing IDs.
   - Each requirement carries: a single **shall** statement, a `**Phase:**` tag (must match `PP`), a `**Priority:**` (MUST/SHOULD/COULD), and an **Accept** line written as concrete, testable done-criteria — this is the TDD test contract (TR-00-001).
   - Keep each requirement atomic and independently verifiable; split a requirement that bundles two behaviors.
4. Honor any locked project decisions documented in the repo (language, auth, stack, conventions) — never contradict them. Flag any assumption you had to make.
5. **Propose the draft requirements and wait for explicit confirmation before writing.** On approval: add each to the correct group section and replace that phase's `TBD` in the Phase ↔ Requirement Mapping table with the new IDs.

Report the phase targeted and the IDs added.
