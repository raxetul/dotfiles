---
description: Pin instance-keyed configuration (the envist crate) and an injected environment-access seam as this project's standard by writing a rule into the local ./CLAUDE.md.
argument-hint: (none)
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(test*), Bash(cat*)
---

Pin the configuration convention for the **current project** by adding a
short rule to its local `./CLAUDE.md`.

Procedure:

1. **Confirm this is a Rust project** — check for `Cargo.toml` at the repo
   root. If it's missing, stop and ask whether to proceed anyway; don't
   guess.

2. **Locate the project file** at the repo root: `./CLAUDE.md`. If it
   doesn't exist yet, you'll create it.

3. **Idempotency / conflict check.** If a `## Configuration` section
   already exists and matches the text below, report "already set" and
   stop. If it exists but differs, show the existing section and confirm
   before replacing it.

4. **Write the rule** — append the section (or create the file with it):

   ```
   ## Configuration

   Instance-keyed configuration (multiple named instances of the same
   kind — upstreams, tenants, devices) binds environment variables
   through the **envist** crate, keyed by id (`APP_UPSTREAM_PRIMARY_TOKEN`),
   never by positional index (`APP_UPSTREAM_1_TOKEN`). Reordering the
   config document must never silently rebind a credential to the wrong
   instance while the secret manifest stays byte-identical — id-keyed
   binding makes that impossible; index-keyed binding doesn't.

   Environment access sits behind an injected seam: `std::env` is read
   only at the composition root, inside the one adapter that implements
   the seam. Business code and config loaders take the seam as a
   dependency, so tests run against an in-memory fake — never
   `std::env::set_var` (`unsafe` in newer editions).

   An `APP_*` variable that binds to nothing is a startup error, not a
   silent no-op — that's the typo catch.

   Secrets come from references, not values, in this order:
   secret-manager reference > mounted secrets directory > `_FILE`
   indirection > plain environment variable. The process environment is
   readable via `/proc/<pid>/environ`, inherited by child processes, and
   captured in crash dumps — fine as a channel for a reference, wrong for
   the secret's value.

   Ordinary structural config (not instance-keyed) keeps using a normal
   layered loader (figment or config-rs); `envist` covers only
   instance-keyed binding and the unbound-variable check.

   `envist` (MIT OR Apache-2.0) is not yet published to crates.io — until
   it is, depend on it via a local path
   (`envist = { path = "~/gel-ort/workspace/envist" }`), then switch to a
   version pin once published.
   ```

5. **Report** which file was created/edited. Suggest committing it using
   the project's own commit convention — do not commit automatically.
