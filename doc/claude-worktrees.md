---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "The claude-worktree command is documented here and MUST be kept in lockstep with scripts/claude-worktree."
---

# Parallel Claude sessions with git worktrees

Run several Claude Code sessions at once — each on its own branch, in its
own **worktree** (a second checkout that shares the repo's single `.git`),
placed by **herdr** as a split pane or a new tab. Because each session has
its own working directory, they never clobber each other's edits.

The tool is `scripts/claude-worktree` (on `PATH` as `claude-worktree`, or
the alias **`cwt`**).

## Topology

```mermaid
flowchart TD
    subgraph GIT["one repo · one .git"]
        M["main checkout<br/>dotfiles/  · branch main"]
        W1["../dotfiles.worktrees/feature-x<br/>branch feature-x"]
        W2["../dotfiles.worktrees/hotfix<br/>branch hotfix"]
    end
    M -. shares .git .-> W1
    M -. shares .git .-> W2

    subgraph HERDR["herdr layout"]
        direction LR
        P0["pane: claude<br/>(main)"]
        P1["split pane: claude<br/>(feature-x)"]
        T1["new tab: claude<br/>(hotfix)"]
    end
    M --> P0
    W1 --> P1
    W2 --> T1
```

- **Same repo → split pane** (default): the new session opens beside the
  current one, so you watch both at once.
- **`--tab` → new tab**: for when splits get cramped or the work is
  unrelated. Each parallel Claude is then its own tab.

## Commands

| Command | What it does |
| --- | --- |
| `cwt <branch>` | New branch from `HEAD`, worktree at `../<repo>.worktrees/<branch>`, launch Claude in a split pane |
| `cwt <branch> --base <ref>` | Branch off `<ref>` instead of `HEAD` |
| `cwt <branch> --tab` | Place the session in a new tab instead of a split |
| `cwt <branch> --split down` | Split downward instead of right |
| `cwt <branch> --no-focus` | Create it but stay in the current session |
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
  └─ herdr agent start claude --cwd <path> --split right --focus -- claude
         (herdr only PLACES the session: split pane, or a new tab via
          `herdr tab create` + `--tab <id>`)
```

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
- The new-tab path assumes `herdr tab create --json` returns a tab id under
  `.result.tab.tab_id` (falls back to herdr's default placement if not).
  Adjust the one `jq` line in `scripts/claude-worktree` if a herdr update
  changes that shape.
