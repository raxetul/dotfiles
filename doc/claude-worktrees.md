---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "The claude-worktree command is documented here and MUST be kept in lockstep with scripts/claude-worktree."
---

# Parallel Claude sessions with git worktrees

Run several Claude Code sessions at once — each on its own branch, in its
own **worktree** (a second checkout that shares the repo's single `.git`),
arranged by **herdr** as a **team**: the pane you launch from is the team
**leader** on the left, and every new session joins as a team **member**
stacked vertically down the right-hand column. Because each session has its
own working directory, they never clobber each other's edits.

The tool is `scripts/claude-worktree` (on `PATH` as `claude-worktree`, or
the alias **`cwt`**).

## Topology

```mermaid
flowchart TD
    subgraph GIT["one repo · one .git"]
        M["main checkout<br/>dotfiles/ · branch main"]
        W1["../dotfiles.worktrees/feature-x<br/>branch feature-x"]
        W2["../dotfiles.worktrees/review-pr-42<br/>branch review-pr-42"]
    end
    M -. shares .git .-> W1
    M -. shares .git .-> W2

    subgraph TAB["herdr tab — team layout"]
        direction LR
        L["leader<br/>(main · left)"]
        subgraph COL["members · right column (top → bottom)"]
            direction TB
            P1["member: claude<br/>(feature-x)"]
            P2["member: claude<br/>(review-pr-42)"]
            P1 --- P2
        end
        L --- COL
    end
    M --> L
    W1 --> P1
    W2 --> P2
```

- **Team layout** (default): the leader stays on the left; each new member
  joins the vertical stack down the right column. The **first** member splits
  the leader to the **right** (opening the column); each **later** member
  splits **down** off the bottom of that column.
- **`--tab` → new tab**: for when the column gets cramped or the work is
  unrelated — the member gets its own tab instead of joining the column.
- **`--split right|down` → manual override**: a plain split off the *current*
  pane, bypassing the team layout, for when you want to place by hand.

**Focus.** By default the **leader keeps focus** after a member is spawned, so
you go on orchestrating from the left instead of being yanked into each new
session. Use `--focus-member` to jump into the new member, or `--no-focus` to
leave focus on the pane you launched from.

## Commands

| Command | What it does |
| --- | --- |
| `cwt <branch>` | New branch from `HEAD`, worktree at `../<repo>.worktrees/<branch>`, launch Claude as a team member in the right-hand column |
| `cwt <branch> --base <ref>` | Branch off `<ref>` instead of `HEAD` |
| `cwt <branch> --tab` | Place the session in its own new tab instead of the team column |
| `cwt <branch> --split right\|down` | Override the team layout with a plain split off the current pane |
| `cwt <branch> --focus-member` | Jump into the new member instead of keeping focus on the leader |
| `cwt <branch> --no-focus` | Leave focus on the pane you launched from |
| `cwt <branch> --no-claude` | Just create the worktree; start Claude yourself later |
| `cwt <branch> -- <args>` | Pass extra args through to `claude` |
| `cwt list` | List all worktrees (`git worktree list`) |
| `cwt rm <branch> [--force]` | Remove that worktree (the branch is kept) |

An existing branch is checked out into the worktree; a new name is created
with `-b`. Re-running for the same branch reuses the existing worktree
(idempotent).

## How it's wired

```
cwt feature-x
  │
  ├─ git worktree add -b feature-x  ../<repo>.worktrees/feature-x  HEAD
  │      (plain git — portable, exact path, works without herdr)
  │
  └─ place in the team layout (read `herdr pane layout --current` geometry):
        leader = pane with the smallest x (leftmost) in the current tab
        right column = panes with x > leader.x ; its bottom = greatest y
        • no right column yet → focus leader,       agent start … --split right
        • column exists       → focus column bottom, agent start … --split down
        then focus the leader again (default) / the member / the origin
      (herdr only PLACES the session; --tab routes it to a fresh tab instead,
       and --split right|down forces a plain split off the current pane)
```

Placement is read from pane **rectangles**, not `pane neighbor` — that command
reports focus-movement targets within the split tree, not spatial adjacency, so
it can't be walked. Reading `x`/`y` from the layout finds the leftmost (leader)
and greatest-`y` right-column (column tail) panes deterministically, from
whichever pane you run `cwt` in. If the layout can't be parsed, it falls back to
a plain split-right so a member is still placed.

Each member is started under a **unique herdr agent name** (the branch slug),
because herdr rejects a duplicate name in the workspace; Claude is still
detected as a `claude` agent at runtime via its integration hooks regardless of
that label.

Worktrees are plain git, so `--no-claude` (or running outside herdr) still
leaves a usable checkout — the script prints the `cd … && claude` line.

## Cleanup

```sh
cwt rm feature-x          # git worktree remove  (branch kept)
git branch -d feature-x   # delete the branch too, once merged
```

When the Claude process in a pane/tab exits, close that pane/tab in herdr
as usual. `cwt rm` only removes the worktree checkout, never the branch or
its commits.

## Notes / assumptions

- **herdr must be running** for automatic placement; otherwise the worktree
  is still created and the launch command is printed.
- **The team lives in one tab.** Leader + members share the current tab; the
  members are the right-hand column. Use `--tab` to break a session out into
  its own tab when the column gets crowded.
- Team placement parses `herdr pane layout --current` at
  `.result.layout.panes[].{pane_id,rect}` to find the leader (min `x`) and the
  right column's bottom (max `y` among `x > leader.x`). If a herdr update changes
  that shape, adjust the two `jq` filters in the `team` branch of
  `scripts/claude-worktree`; on any parse failure the script falls back to a
  plain split-right so a member is still placed.
- **Agent names must be unique per workspace** — the script labels each member
  with the branch slug for that reason. Re-running `cwt` for a branch that
  already has a live member in the workspace will be rejected by herdr with
  `agent_name_taken`.
- The new-tab path assumes `herdr tab create --json` returns a tab id under
  `.result.tab.tab_id` (falls back to herdr's default placement if not).
  Adjust the one `jq` line in `scripts/claude-worktree` if a herdr update
  changes that shape.
