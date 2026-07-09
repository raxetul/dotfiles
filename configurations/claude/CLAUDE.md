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

Concretely: project setup and per-project standards (DI, unit testing,
logging, conventional commits, error format, framework choice, …) are
delivered by the `/init-proj-*` command family, which writes those
rules into the *project's own* `./CLAUDE.md`. They therefore load only
inside that project, keeping this always-loaded global file — and every
session's context — small. See the dotfiles repo's `doc/init-proj.md`.
