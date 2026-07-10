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

## Project type: personal vs work

Every project is either **personal** or **work**. Before doing substantive
work in a project, know which it is:
- If the project's `./CLAUDE.md` records a type, use it.
- Otherwise, if the project already has implementation or history (i.e. not a
  brand-new empty repo), **ask me to classify it as personal or work** before
  applying any work-specific conventions — then record my answer in that
  project's `./CLAUDE.md` so I don't ask again.

Apply by type:
- **work** → the Büyütech organization conventions apply (task templates,
  compliance/standards framing, etc.).
- **personal** → skip those work-only conventions (task templates, ASPICE /
  automotive-compliance framing, "customer" assumptions). General safety and
  security practices still apply where relevant.

## Visual-first documentation

I'm a visual thinker: favor **visual representations** in documentation
over walls of prose. Anything that gets documented — concepts, howtos,
runbooks, test cases, architecture, workflows — should carry a diagram,
table, flowchart, or sequence/state diagram (plus annotated examples),
not just paragraphs. Use **Mermaid** (embeddable in Markdown) or DrawIO
for diagrams. If a repo has no documentation style, or a concept isn't
documented at all, create **informal** documentation for it rather than
leaving it undocumented — a rough visual doc beats none.
