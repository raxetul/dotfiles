---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "This doc MUST be kept in lockstep with scripts/dc-image-update — any change to its scan/mark/apply behavior, menu keys, state schema, or exit codes is a doc change in the same commit."
---

# dc-image-update — docker compose image pull/recreate helper

An interactive zsh script that recursively scans a directory for docker
compose files, lists every service image, lets you mark each image for
`pull` or `pull + recreate`, remembers your marks between runs, and — on
apply — pulls the marked images and recreates only the **running**
containers whose image digest actually changed.

No file extension on purpose: this repo's shellcheck pre-commit glob is
`{scripts/*.sh,setup.sh}` and shellcheck does not understand zsh (SC1071),
so a `.sh` name would fail commit. `scripts/` is linked wholesale onto
`~/.scripts` (`scripts::.scripts` in `scripts/symlinks.sh`), so once the
file is executable it's on `PATH` with no further wiring — same pattern
as `init-load`, `herdr-team`, `claude-worktree`.

**Dependency note:** `docker` is required but **not installed by this
repo** — see [packages-native.md](packages-native.md) for why it's
commented out in `packages/apt.list` (rooted vs. rootless vs. Docker
Desktop is a per-user choice). `jq` ships in every package list already.
Missing either exits 3 before anything else runs.

## Flow

```mermaid
flowchart TD
    A[scan DIR recursively] --> B[find compose.yaml / compose.yml /<br/>docker-compose.yaml / docker-compose.yml]
    B -->|prune| P[".git node_modules target vendor<br/>.venv dist build .cache"]
    B --> C{docker compose -f file<br/>config --format json}
    C -->|ok| D[jq: services[].image]
    C -->|fails| E["⚠ degraded: grep image: lines<br/>(best-effort service name too)"]
    D --> F[image list + used-by]
    E --> F
    F --> G[load .dc-image-update.json<br/>from scan root]
    G --> H["merge: known marks restored,<br/>unseen images -> '' + ← new,<br/>vanished images kept, not shown"]
    H --> I[docker ps --format image<br/>-> ▶running marker]
    I --> J[render menu]
    J -->|invalid key| J
    J -->|Enter / s / --yes| K[write state atomically<br/>tmp file + mv]
    J -->|q| Z[exit, no write]
    K -->|--dry-run: skip write, print plan| L
    K --> L[for each P/R image]
    L --> M[digest before -> docker pull -> digest after]
    M --> N{mark == R AND<br/>digest changed?}
    N -->|no| O[report up-to-date /<br/>not-running / skipped]
    N -->|yes| Q["docker ps --filter ancestor=image<br/>+ inspect compose.* labels"]
    Q --> R[group by com.docker.compose.project,<br/>one 'compose up -d' per project]
    R --> S[results table + exit code]
    O --> S
```

## Marks

Assigned **per image**, never per compose service — the same image can
back several services across several compose files, and gets one mark.

| Mark  | Meaning                                                                                |
| ----- | --------------------------------------------------------------------------------------- |
| `[P]` | pull only                                                                                |
| `[R]` | pull, then recreate every **running** container using that image, but only if the pull actually changed the digest |
| `[ ]` | do nothing                                                                               |

Recreate scope is deliberately the **running containers** (found via
`docker ps` + `com.docker.compose.*` labels), not "every service listed
in the compose file" — a compose file can define services that are not
currently up, and those are left alone.

## Menu keys

| Input          | Effect                                                              |
| -------------- | -------------------------------------------------------------------- |
| `<n>`          | cycle row `n`: `[ ]` → `[P]` → `[R]` → `[ ]`                          |
| `p<spec>`      | set rows in `<spec>` to `[P]` — `p3`, `p1-4`, `p1,3,5`                |
| `r<spec>`      | set rows in `<spec>` to `[R]`                                         |
| `x<spec>`      | clear rows in `<spec>` (`[ ]`)                                       |
| `a`            | mark every row `[R]`                                                  |
| `c`            | clear every row                                                       |
| `<Enter>`      | save marks, then apply                                                 |
| `s`            | save marks only, do not apply                                          |
| `q`            | quit without saving (confirms first if there are unsaved changes)      |
| anything else  | prints an error line and redraws the menu — the menu never exits on a bad key |

## State file

`<scan-root>/.dc-image-update.json`, written with `jq` (never hand-built
strings), atomically (temp file + `mv`):

```json
{
  "version": 1,
  "updated_at": "2026-08-19T09:12:33Z",
  "marks": { "nginx:latest": "R", "postgres:16": "P", "redis:7": "" }
}
```

- A previously-tracked image whose compose file disappears keeps its
  entry (not shown in the menu, not deleted) — so the mark comes back
  automatically if the compose file reappears. The scan summary reports
  how many are currently "absent".
- An image seen for the first time gets `""` and is flagged `← new` in
  the menu (until the marks are saved).
- A `version` other than `1` triggers a warning and a best-effort
  migration of marks — nothing is dropped silently.

## Flags

```
dc-image-update [DIR] [--dry-run] [--yes|-y] [--help]
```

| Flag              | Behavior                                                                          |
| ----------------- | ---------------------------------------------------------------------------------- |
| `DIR`             | scan root; defaults to `$PWD`                                                      |
| `--dry-run`       | print the plan; never runs `docker pull`/`docker compose up`; never writes state, even on Enter/`s` (env `DRY_RUN=1` is equivalent, matching the `packages/custom-install/*` hook convention) |
| `--yes` / `-y`    | skip the menu, apply whatever marks are already on disk (cron/automation)           |
| `--help` / `-h`   | usage + this reference                                                             |

**Non-interactive stdin:** when stdin is not a TTY and `--yes` was not
passed, the menu still reads commands from stdin line by line (this is
exactly how the fixture tests below drive it — e.g. piping
`r1`, `p2`, then an empty line for Enter). Two edge cases are resolved
deliberately:
- the very **first** read hits EOF with nothing piped in at all (e.g.
  stdin redirected from `/dev/null`, as a timer unit would) → behaves
  as if `--yes` had been passed;
- EOF happens **after** at least one command was read → whatever marks
  were set so far are saved and the script exits, as if `s` had been
  typed, rather than silently discarding them.

## Exit codes

| Code | Meaning                                             |
| ---- | ---------------------------------------------------- |
| 0    | success, or user quit (`q`) without applying          |
| 1    | at least one `pull` or `up` (recreate) failed          |
| 2    | usage error — bad flag, `DIR` is not a directory       |
| 3    | a required dependency (`docker` or `jq`) is missing    |

## Shell-strictness note

zsh's closest analogue to bash's `set -euo pipefail` is
`setopt err_exit no_unset pipe_fail`, but this script only sets
`emulate -L zsh; setopt pipe_fail`, deliberately skipping `err_exit` /
`err_return` and `no_unset`:

- a failed `docker pull` for one image must **not** abort the run —
  every other marked image still has to be tried, with the failure
  surfaced in the results table and a non-zero exit at the end. errexit
  semantics (abort on first non-zero) fight that requirement directly,
  so every risky command is checked explicitly instead.
- `no_unset` turns a bare `$1` in a function called with fewer arguments
  into a hard error, which collides with the small-helper-function style
  used throughout (`"${1:-}"` is used wherever a default makes sense).

## Requirements

This repository has no requirements-tracking file (no `docs/requirements/`
or similar) at the time of writing, so there is nothing to update in
lockstep here — noted per the "keep requirements & docs in sync" rule.
