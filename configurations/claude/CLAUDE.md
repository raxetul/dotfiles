# Global agent rules

These apply across every project on this machine, on top of any
repo-local `CLAUDE.md` and the organization instructions. When a
repo-local rule or the organization instructions conflict with
something here, those win.

## Adding rules: prefer project-scoped commands

Keep this global file small — it loads into every session. When I ask
for something to be "added to global", first **offer a project-specific
mechanism**: a slash command that writes the rule into an individual
project's `CLAUDE.md` on demand, rather than growing this always-loaded
file. The `/backend-stack` command (pins a project's backend framework
by language) is the reference pattern. Only put a rule here when it
genuinely must apply everywhere.

## Dependency injection

Every module takes its external collaborators (I/O, clock, network,
database, filesystem, randomness, other services) through **dependency
injection** rather than constructing them internally or reaching for a
global. A module depends on an **abstraction** (interface / protocol /
trait / callable); the concrete implementation is passed in by the
caller, wired at a **composition root** (startup / `main` / container).

The point is isolation-testability: **tests inject in-memory
fakes/mocks** (no real network, disk, or clock — fast, deterministic,
hermetic) and **production injects the real implementations** through
the same seam. Every side-effecting dependency sits behind an interface
the project can re-implement in memory. Library- and language-agnostic:
pick any DI style (constructor injection, interface + factory, parameter
passing, a container) — keep the seam, not a specific tool.
