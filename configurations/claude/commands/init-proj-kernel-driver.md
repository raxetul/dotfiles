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

1. **Run the common baseline first, with kernel overrides** — invoke
   `/init-proj-common` **with overrides: `logging=off`,
   `dependency-injection=off`, `unit-testing=off`**. Kernel space
   doesn't use userland logging, a composition-root/container DI style,
   or host unit-test runners, so those three common rules are disabled
   and **replaced** by the kernel-native forms in step 2 below. `git`
   and the conventional-commit lefthook stay on. (Idempotent; skips
   root-level steps inside a monorepo package.)

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
   - **Dependency seam** (replaces the common DI rule): decouple via
     kernel idioms — `ops` structs / function-pointer tables and
     subsystem API wrappers — not constructor injection or a container.
   - **Testing** (replaces the common unit-testing rule): KUnit; mock
     at those subsystem-API wrappers so logic is exercised without real
     hardware.
   - **Logging** (replaces the common logging rule): `pr_debug` /
     `pr_info` / `dev_*`, not custom multi-writer sinks.
   ```

3. **Kbuild scaffold** — create a `Makefile` (`obj-m += <name>.o`, with
   the `KDIR`/`M=$(PWD)` build + clean targets) and a module skeleton
   `.c` with SPDX header, `module_init`/`module_exit`, and
   `MODULE_LICENSE`.

4. **Report** files created/edited; suggest committing with the
   Conventional Commit convention.
