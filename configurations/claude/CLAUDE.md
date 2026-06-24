# Global agent rules

These apply across every project on this machine, on top of any
repo-local `CLAUDE.md` and the organization instructions. When a
repo-local rule or the organization instructions conflict with
something here, those win.

## Backend framework defaults

When building a backend service, default to the idiomatic framework for
the language:

- **Rust** → Loco (`loco.rs`).
- **Java** → Spring Boot.
- **JavaScript / TypeScript** → NestJS.

If the project already uses a different backend framework, match the
existing stack rather than introducing a second one — and if a new
service genuinely warrants a different choice, say so and confirm before
proceeding.
