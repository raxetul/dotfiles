---
maintainer: raxetul@gmail.com
claude-rule: "When you change scripts/dotfiles-state.sh, or add/remove a state_record call in setup.sh / symlinks.sh / run-custom-install-hook, update this doc to match (record schema, domains, writers)."
---

# State management — the realized-state ledger

The repo's package lists (`packages/`) and the `COMMON_LINKS` array in
`scripts/symlinks.sh` describe what *should* exist. They do not record
what *actually got planted on a given host* — and crucially, not
**which packages this repo installed versus ones you already had**.
Without that, an uninstaller can't safely `--purge`: it would risk
removing tools you installed yourself before adopting these dotfiles.

`scripts/dotfiles-state.sh` fills that gap with an append-only ledger of
the realized footprint. It is **not** a version lockfile — it records
presence, ownership, and paths, never versions, and never freezes or
pins anything.

## Where it lives

```
${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.tsv
```

Per-host, under `$HOME` (footprint policy, CLAUDE.md §8), alongside the
existing `custom-install.log` / `update-dotfiles.log`. It is not in the
repo and not symlinked — it is host state, written at install time.

## Record format

One record per line, six TAB-separated fields:

```
<iso8601-utc>  <run-id>  <domain>  <action>  <id>  <detail>
```

The ledger is **reduced on read**: the last action per `(domain, id)`
wins, and entries whose final action negates presence
(`remove`/`unlink`/`purge`/`uninstall`/`delete`/`revert`) are dropped.
Re-runs are therefore safe — duplicate `create`/`install` records
collapse — and `prune` rewrites the file to that reduced set.

| Domain        | Actions            | `id`              | `detail`                  |
| ------------- | ------------------ | ----------------- | ------------------------- |
| `symlink`     | `create` / `remove`| `~`-relative dst  | `src=<repo path>`         |
| `package`     | `install` / `present` | package name   | `mgr=<apt\|pacman\|dnf\|brew>` |
| `plugin`      | `clone`            | checkout path     | `name=<id>`               |
| `bootstrap`   | `fetch`            | file path         | `name=<id>`               |
| `custom-hook` | `run`              | `<pkg>/<hook>`    | `rc=<exit code>`          |
| `shell`       | `chsh`             | new login shell   | `from=<previous shell>`   |

`install` vs `present` is the load-bearing distinction: only `install`
packages are ours to remove. `present` packages were already on the host
when setup ran and must be left alone.

## Who writes it

A single run id (`DOTFILES_STATE_RUN`) is minted once by `setup.sh` via
`state_begin_run` and exported, so every record from that invocation —
including the child scripts it calls — groups under one run.

| Writer                        | Records                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| `setup.sh` (package step)     | `package present` / `package install` — classified by a pre-install `pkg_installed` probe (`dpkg -s` / `pacman -Q` / `rpm -q` / `brew list`) |
| `setup.sh` (plugin bootstrap) | `plugin clone` (TPM, zsh-you-should-use), `bootstrap fetch` (vim-plug, bash-preexec) |
| `setup.sh` (shell step)       | `shell chsh` with the prior login shell                        |
| `scripts/symlinks.sh`         | `symlink create` / `symlink remove` (also derivable from the array — this is the audit/uninstall trail) |
| `scripts/run-custom-install-hook` | `custom-hook run` per executed before/after hook          |

`.path` segments are **not** recorded here — they are self-describing via
their `# >>> <pkg> begin … end` markers (CLAUDE.md §10), so an uninstaller
strips them by reading `.path` directly.

## CLI

```sh
scripts/dotfiles-state.sh record <domain> <action> <id> [detail]
scripts/dotfiles-state.sh list [domain]        # raw ledger
scripts/dotfiles-state.sh reduce [domain]      # current realized set
scripts/dotfiles-state.sh owned-packages       # packages safe for --purge
scripts/dotfiles-state.sh prune                # compact file to reduced set
scripts/dotfiles-state.sh path                 # print the ledger path
```

`DRY_RUN=1` prints the intended record to stderr and writes nothing.

## How `uninstall.sh` will consume it (Phase 4)

The yet-to-be-written `scripts/uninstall.sh` reads the reduced ledger to
reverse the exact realized set:

- **symlinks** — reverse via `scripts/symlinks.sh uninstall` (array-driven;
  the ledger is the cross-check).
- **plugins / bootstraps** — remove the recorded checkout/file paths.
- **`--purge`** — remove only `owned-packages` (never `present` ones),
  through the matching package manager.
- **`--shell`** — `chsh` back to the `from=` shell in the `shell` record.
- **`.path`** — strip each package's bracketed segment.
