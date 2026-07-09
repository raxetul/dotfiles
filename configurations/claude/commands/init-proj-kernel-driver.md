---
description: Initialize a Linux kernel module/driver project — runs the common baseline, then pins kernel coding style, a Kbuild skeleton, GPL licensing, KUnit testing, and no-libc rules into the project's ./CLAUDE.md.
allowed-tools: Read, Write, Edit, Skill, Bash(git*), Bash(lefthook*), Bash(mkdir*), Bash(ls*), Bash(test*), Bash(cat*)
---

Initialize a **Linux kernel module / device driver** project in the
**current directory**. Kernel space differs from userland, so the
common rules are adapted rather than taken literally. Follow the
pre-CLI-brief + confirm-destructive contract, and keep every step
idempotent.

Procedure:

1. **Run the common baseline first** — invoke `/init-proj-common`
   (idempotent; skips root-level steps inside a monorepo package). Note
   the adaptations below: the DI "in-memory fake" idea maps to **mocking
   at subsystem API boundaries**, and unit testing maps to **KUnit**.

2. **Kernel rules → `./CLAUDE.md`** (append the missing sections):

   ```
   ## Kernel driver rules

   - **Coding style**: Linux kernel style; `scripts/checkpatch.pl
     --strict` runs clean in `pre-commit`. Tabs, not spaces.
   - **No libc, no floating point, no dynamic loading of userspace
     assumptions.** Use kernel APIs (`kmalloc`/`kfree`, `pr_*`, etc.).
   - **Error handling**: unwind with `goto` ladders; free/undo in
     reverse acquisition order; check every allocation.
   - **Licensing**: `MODULE_LICENSE("GPL")` and an SPDX header on every
     file (GPL-compatible — required for many kernel symbols).
   - **Testing**: KUnit for unit tests; isolate logic behind subsystem
     API wrappers so those can be mocked in KUnit — the kernel-space
     analogue of the DI seam.
   - **Logging** via `pr_debug`/`pr_info`/`dev_*`, not custom sinks
     (overrides the common logging rule for kernel space).
   ```

3. **Kbuild scaffold** — create a `Makefile` (`obj-m += <name>.o`, with
   the `KDIR`/`M=$(PWD)` build + clean targets) and a module skeleton
   `.c` with SPDX header, `module_init`/`module_exit`, and
   `MODULE_LICENSE`.

4. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
