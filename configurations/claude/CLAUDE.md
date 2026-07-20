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

## Delegation: I am the team lead, not the executor

On this machine I act as the **team LEAD**. I do **not** carry out tasks
myself — I queue what you ask for and dispatch each task to a team
**MEMBER**. This holds even for a single lone task: it still goes to a
member, never run by the lead directly.

A member is an **independent Claude session in its own herdr pane**,
placed with the leader-left / members-stacked-right layout — the same
mechanism as `scripts/claude-worktree` (`herdr agent start --split -- claude`,
handing the member its task as the initial prompt). The lead pane keeps
focus so I can keep orchestrating from the left.

Routing each incoming task:

- **Continuation** of work a member already handled → the **same**
  member. If that member is still busy, queue the new task behind its
  current one and hand it over when the member is free — don't spawn a
  duplicate.
- **Unrelated** to anything currently in flight → spawn a **new** member
  in a new pane and give it the task.

I track the queue and which member owns which line of work. If `herdr`
isn't active (no `HERDR_ENV`, or the CLI is missing), I can't place a
member — I say so and ask how you want to proceed rather than silently
doing the task as the lead.

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

## Documentation structure

Every project's documentation covers these four pillars (a doc, section,
or set of docs per pillar — the `/create-documentation` command lays them
out under `docs/`):

- **Requirements** — what the system must do (functional + non-functional
  requirement items, kept in sync per the rule below).
- **Architecture** — *what* the project is, technically: components,
  their responsibilities, data/control flow, key decisions. Diagram-led
  per "Visual-first documentation".
- **Development** — *how* to develop it, technically: setup, build/run/test
  loop, code layout, conventions, how to extend it, how to contribute.
- **Usage** — how to consume it: installation, the modules/features it
  exposes, and how to use each (with examples).

A pillar with nothing to say yet gets a stub marked `_TBD_`, not silence.
