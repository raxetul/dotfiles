---
maintainer: raxetul@gmail.com
claude-rule: "When you change scripts/dotfiles-state.sh, or add/remove a state_record call in setup.sh / symlinks.sh / run-custom-install-hook, update this doc to match (record schema, domains, writers)."
---

# State management — the realized-state ledger

The package lists in `packages/` and the `COMMON_LINKS` array in
`scripts/symlinks.sh` describe what *should* exist. They do not record
what the setup *actually planted on a given host*. They also do not record
**which packages this repo installed and which packages you already had**.
Without this record, the uninstaller cannot safely use `--purge`. It could
remove tools that you installed yourself before you used these dotfiles.

`scripts/dotfiles-state.sh` fills this gap. It keeps an append-only ledger of
the realized footprint. The ledger is **not** a version lockfile. It records
presence, ownership, and paths. It never records versions, and it never freezes or
pins anything.

## Where it lives

```
${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/state.tsv
```

The file is per-user and is under `$HOME`. It is the same file if the repo is at
`/opt/dotfiles` or in a plain dev checkout (CLAUDE.md §15). It is next to the
`custom-install.log` and `update-dotfiles.log` files. It is not in the
repo and it is not a symlink. It is host state, and the install step writes it.

## Record format

One record per line, six TAB-separated fields:

```
<iso8601-utc>  <run-id>  <domain>  <action>  <id>  <detail>
```

The ledger is **reduced on read**. For each `(domain, id)`, the last action
wins. The reduction drops each entry whose final action negates presence
(`remove`/`unlink`/`purge`/`uninstall`/`delete`/`revert`).
It is therefore safe to run the setup again, because duplicate `create`/`install`
records collapse into one. The `prune` command rewrites the file to the reduced set.

| Domain        | Actions            | `id`              | `detail`                  |
| ------------- | ------------------ | ----------------- | ------------------------- |
| `symlink`     | `create` / `remove`| `~`-relative dst  | `src=<repo path>`         |
| `package`     | `install` / `present` / `purge` | package name | `mgr=<apt\|pacman\|dnf\|brew\|script>` |
| `plugin`      | `clone` / `remove` | checkout path     | `name=<id>`               |
| `bootstrap`   | `fetch` / `remove` | file path         | `name=<id>`               |
| `custom-hook` | `run`              | `<pkg>/<hook>`    | `rc=<exit code>`          |
| `shell`       | `chsh` / `revert`  | new login shell   | `from=<previous shell>`   |

The difference between `install` and `present` is important. Remove only the `install`
packages, because this repo installed them. The `present` packages were already on the host
when the setup ran. Do not remove them.

## Who writes it

`setup.sh` creates one run id (`DOTFILES_STATE_RUN`) with `state_begin_run`
and exports it. Each record from that run has the same run id.
This includes the records from the child scripts that `setup.sh` calls.

| Writer                        | Records                                                        |
| ----------------------------- | -------------------------------------------------------------- |
| `setup.sh` (package step)     | `package present` / `package install` — the `pkg_installed` probe classifies each package before the install (`dpkg -s` / `pacman -Q` / `rpm -q` / `brew list`) |
| `setup.sh` (plugin bootstrap) | `plugin clone` (TPM, zsh-you-should-use), `bootstrap fetch` (vim-plug, bash-preexec) |
| `setup.sh` (shell step)       | `shell chsh` with the prior login shell                        |
| `scripts/symlinks.sh`         | `symlink create` / `symlink remove` (you can also derive them from the array; this is the audit and uninstall trail) |
| `scripts/run-custom-install-hook` | `custom-hook run` per executed before/after hook          |
| `scripts/run-script-installers` | `package present` / `package install` (`mgr=script`) — tools of the script lane from `packages/script-install.list`; the probe is `command -v` |
| `scripts/uninstall.sh`       | `plugin remove` / `bootstrap remove` / `package purge` / `shell revert` — the negation records that remove entries from the realized set |

The ledger does **not** record `path` segments. Each segment describes itself with its
`# >>> <pkg> begin … end` markers (CLAUDE.md §9). The uninstaller reads
`$HOME/.dotfiles/path` and strips the segments directly.

## CLI

```sh
scripts/dotfiles-state.sh record <domain> <action> <id> [detail]
scripts/dotfiles-state.sh list [domain]        # raw ledger
scripts/dotfiles-state.sh reduce [domain]      # current realized set
scripts/dotfiles-state.sh owned-packages       # packages safe for --purge
scripts/dotfiles-state.sh prune                # compact file to reduced set
scripts/dotfiles-state.sh path                 # print the ledger path
```

When `DRY_RUN=1` is set, the script prints the intended record to stderr. It does not write anything.

## How `uninstall.sh` consumes it

`scripts/uninstall.sh` reads the reduced ledger. It then reverses the exact
realized set:

- **symlinks** — the script reverses them with `scripts/symlinks.sh uninstall`
  (the array drives this step; the ledger is the cross-check).
- **plugins / bootstraps** — the script removes the recorded checkout and file paths.
- **`--purge`** — the script removes only `owned-packages` (never `present` ones)
  with the matching package manager.
- **`--shell`** — the script runs `chsh` to set the shell back to the `from=` shell in the `shell` record.
- **`.path`** — the script strips the bracketed segment of each package.
