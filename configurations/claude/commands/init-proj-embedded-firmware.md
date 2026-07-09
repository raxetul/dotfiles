---
description: Initialize an MCU/AUTOSAR firmware project — runs the common baseline, then pins MISRA C, ISO 26262 (ASIL-B) awareness, a mockable HAL seam, and no-dynamic-allocation rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize an **embedded / firmware (MCU, AUTOSAR)** project in the
**current directory**. This is Büyütech's automotive core, so the rules
carry the applicable-standards context. Follow the pre-CLI-brief +
confirm-destructive contract, and keep every step idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package). The
   HAL seam below *is* the DI seam the baseline asks for.

2. **Firmware rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Firmware / embedded rules

   - **Coding standard**: MISRA C:2012 (document any deviation with a
     rationale). Static analysis (cppcheck / clang-tidy / a MISRA
     checker) runs in `pre-commit`.
   - **Safety context**: written under ISO 26262 (target ASIL-B unless
     stated) and, where relevant, ISO 21448 / ISO 21434 and Classic
     AUTOSAR. State the assumption; don't bake customer specifics into
     code comments (TISAX).
   - **No dynamic allocation** after init; bounded, statically sized
     buffers; deterministic timing; feed the watchdog on the intended
     path only.
   - **Hardware behind a HAL**: every register/peripheral access goes
     through a Hardware Abstraction Layer interface. That HAL is the DI
     seam — provide an **in-memory mock HAL** so logic is unit-tested on
     the host with no target hardware.
   - **No hidden global state**; ISRs do minimal work and hand off via
     well-defined queues/flags.
   ```

3. **Host-test harness** — scaffold a host build that links the logic
   against the mock HAL, so unit tests run off-target in `pre-commit`.

4. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
