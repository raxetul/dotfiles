# `packages/custom-install/` — per-package install hooks

Some packages need a step that the native package manager doesn't run
for you:

* **Before the install** — register a third-party APT/COPR/RPM-Fusion
  repo, accept an upstream key, pre-create a config dir the
  post-install script will write to, install a build dependency.
* **After the install** — provision a toolchain (`rustup default stable`
  → `~/.cargo/bin/cargo`), enable a service, write a one-shot config
  file, run a self-test.

This directory holds one subdirectory per package that needs either
hook. Each subdirectory contains two scripts:

```text
packages/custom-install/
├── README.md
└── <pkg>/
    ├── before.sh    # runs BEFORE the package install step
    └── after.sh     # runs AFTER the package install step (+ AUR/Snap fallback)
```

The folder name matches the package name on the install lists
(`packages/Brewfile`, `packages/<pkgmgr>.list`). **Both `before.sh`
and `after.sh` MUST exist** for every `<pkg>/` — the unused side is
a stub (`#!/usr/bin/env bash` + `set -euo pipefail` + `exit 0`).
This keeps the layout uniform and ensures every package contributes
both banners to the log on every run, even when there's no work to
do on that side.

## Driver order

`setup.sh` and `scripts/update-dotfiles` both walk `custom-install/*`
in lexical order and run, per directory:

1. `before.sh` — during the **before-install** phase, before
   `brew bundle` / `apt|pacman|dnf install`.
2. `after.sh` — during the **after-install** phase, after the package
   step *and* the AUR/Snap fallback have completed.

The phases are wired as distinct stages in `update-dotfiles`
(`stage_packages_custom_before`, `stage_packages_custom_after`), so
you can target them with `--only=custom-install-before` /
`--only=custom-install-after`, or run the umbrella with
`--only=custom-install`.

## Contract (every script)

1. **Be executable** (`chmod +x`).
2. **Be idempotent.** Re-running with the work already done must exit
   `0` without side effects. Probe state first; act second.
3. **Skip cleanly when the package isn't installed.** The list-driven
   install step may have left the package out (older distro, dry-run,
   `--only=symlinks`). For `after.sh`: check `command -v <bin>` and
   exit `0` with a one-line note if missing. For `before.sh`:
   short-circuit when the work is already done (repo already
   registered, key already trusted, etc.).
4. **Print one `==>` banner** for the action taken, and nothing else
   on the happy path.
5. **Honor `DRY_RUN`.** If the caller sets `DRY_RUN=1`, print the
   command instead of running it.
6. **Use `$DOTFILES_DIR`** to find anything in this repo; never
   recompute it from `$0` (these scripts are also invocable from
   `~/.scripts/` via PATH).
7. **Route PATH + per-package env through `${DOTFILES_DIR}/.path`.**
   If the package adds binaries to PATH or defines a
   `FOO_HOME`-style env var, the `after.sh` MUST write a segment
   into `.path` bracketed by `# >>> <pkg> begin` / `# >>> <pkg> end`
   (see [.load and .path](#load-and-path--shell-init-centre)).
   Do NOT add ad-hoc `PATH=…` lines to `configurations/{zsh,bash}/rc`.

## `.load` and `.path` — shell init centre

Two gitignored files at repo root form the runtime shell-init centre:

```text
${DOTFILES_DIR}/.load    # sourced by zshrc + bashrc — the entrypoint
${DOTFILES_DIR}/.path    # sourced by .load — PATH + per-package env
```

* **`.load`** is the orchestrator. `scripts/init-load` creates it on
  first `setup.sh` / `update-dotfiles` run; the user can then edit
  it freely for host-specific exports, aliases, or plugin init
  calls. Its only auto-generated content is the `. .path` line.
* **`.path`** is fully managed by `after.sh` hooks. Each package
  owns one segment bracketed by:

  ```sh
  # >>> <pkg> begin
  …
  # >>> <pkg> end
  ```

  Re-running an `after.sh` strips the old segment with `sed
  -i.bak '/^# >>> <pkg> begin$/,/^# >>> <pkg> end$/d'` and appends
  a fresh one. Idempotent by construction.

`configurations/{zsh,bash}/rc` only have to do `source
"${DOTFILES_DIR}/.load"` — everything else propagates through
`.load` → `.path` → segments.

### Skeleton segment writer (`after.sh`)

```sh
_repo_root="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
_path_file="${_repo_root}/.path"
touch "${_path_file}"
sed -i.bak '/^# >>> <pkg> begin$/,/^# >>> <pkg> end$/d' "${_path_file}"
rm -f "${_path_file}.bak"
cat >> "${_path_file}" <<'EOF'
# >>> <pkg> begin
export FOO_HOME="${HOME}/.foo"
[ -d "${FOO_HOME}/bin" ] && case ":${PATH}:" in
    *":${FOO_HOME}/bin:"*) ;;
    *) PATH="${FOO_HOME}/bin:${PATH}"; export PATH ;;
esac
# >>> <pkg> end
EOF
unset _repo_root _path_file
```

The `case` guard makes sourcing idempotent across shell reloads; the
`[ -d ]` guard keeps it safe before the bin dir exists (e.g. on a
freshly-cloned host before `setup.sh` has run).

## Logging

Two append-only logs under
`${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/`:

| File                  | Written by                                   | Captures                                                                                                              |
| --------------------- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `custom-install.log`  | `scripts/run-custom-install-hook` (per-hook) | Only the `before.sh` / `after.sh` script output, one banner per hook.                                                 |
| `update-dotfiles.log` | `scripts/update-dotfiles` (per-session)      | The entire update run: git-pull, brew/native install, fallbacks, custom-install hooks, and the configurations layer.  |

Both stream to the terminal at the same time via `tee` — nothing is
captured silently.

### Per-hook log format

A single header line per hook, phase left-padded to 6 chars so the
dashes align:

```text
before ---------------------- rustup
... before.sh output ...
after  ---------------------- rustup
... after.sh output ...
before ---------------------- foo
after  ---------------------- foo
```

### Per-session log format

Each `update-dotfiles` invocation is bracketed by ISO-timestamped
banners so individual runs are easy to slice out:

```text
==== 2026-06-17T13:45:01Z update-dotfiles  only=both dry-run=0 desktop=0 ====
... full session output ...
==== 2026-06-17T13:46:38Z update-dotfiles end rc=0 ====
```

### Why repeat the hooks on every update?

`before.sh` and `after.sh` are required to be **idempotent** (see
contract above), so `update-dotfiles` re-runs them on every invocation
without harm. The session log lets you see exactly what was a no-op
vs. what actually changed.

### Inspecting

* Follow live: `tail -F ~/.local/state/dotfiles/update-dotfiles.log`
* Slice one hook from history:
  `grep -A 200 '^after .* rustup$' ~/.local/state/dotfiles/custom-install.log`
* Slice one session: open `update-dotfiles.log` and search for the
  matching pair of `==== … ====` banners.

## When NOT to add a hook here

* Configuration that lives in `~/.config/<app>/<file>` — that's a
  `configurations/<app>/` job, planted by `scripts/symlinks.sh`.
* Plugin bootstraps that need network and a managed `~/.config/`
  layout (vim-plug, TPM, oh-my-zsh-style plugin checkouts) — those
  belong to `setup.sh` Step 5 (plugin bootstrap), not here. The
  distinction: custom-install hooks bracket what the *package
  manager* does; plugin bootstraps are user-scope tooling outside
  the package manager.

## Per-package inventory

| Folder       | Package  | `before.sh` | `after.sh`                                      |
| ------------ | -------- | ----------- | ----------------------------------------------- |
| `rustup/`    | rustup   | no-op stub  | toolchain + CARGO_CRATES                        |
| `starship/`  | starship | no-op stub  | apt release-binary fallback → `~/.local/bin`    |
| `atuin/`     | atuin    | no-op stub  | apt fallback → `~/.atuin/bin` + `.path` segment |
| `claude/`    | claude   | no-op stub  | upstream installer → `~/.local/bin` (all OSes)  |
| `lefthook/`  | lefthook | no-op stub  | apt/dnf release-binary fallback → `~/.local/bin`|
| `opencode/`  | opencode | macOS: tap + trust `anomalyco/tap` | Linux: upstream installer → `~/.opencode/bin` + `.path` segment |
| `ollama/`    | ollama   | macOS: quit the upstream `.app` server | macOS: `brew services start ollama`; Debian: `ollama` snap |

* **`rustup/after.sh`** — runs `rustup default stable` if no default
  toolchain is configured, then cargo-installs the crates listed in
  `CARGO_CRATES` at the top of the script (defaults: `cargo-binstall`,
  `cargo-edit`, `cargo-update`, `cargo-outdated`, `cargo-audit`,
  `cargo-nextest`). Edit the array to add/remove. `cargo-binstall` is
  bootstrapped first so the rest install from prebuilt binaries.
* **`starship/`, `atuin/`, `claude/`, `lefthook/after.sh`** —
  release-binary fallbacks for tools the native package manager may
  not carry. Each exits early when the tool is already on PATH (i.e.
  brew/pacman/dnf/AUR provided it) and only installs the upstream
  binary on the platforms that lack it. **`atuin/after.sh`** is the
  one that writes a `.path` segment: its installer lands in
  `~/.atuin/bin`, which is *not* one of `.load`'s bootstrap dirs, so
  the segment is what puts `atuin` on PATH. The other three install
  into `~/.local/bin` (already on PATH) and write no segment.
* **`opencode/before.sh`** — macOS only. opencode has no
  homebrew-core formula; `anomalyco/tap` is the only tap that builds
  it, and brew refuses to load any third-party tap's formula until
  it's explicitly trusted. Tapping and trusting happen here, before
  `packages/Brewfile`'s `brew "anomalyco/tap/opencode"` line runs.
  **`opencode/after.sh`** installs it on Linux instead (no apt/pacman/dnf
  package exists there): the upstream installer into `~/.opencode/bin`,
  plus the `.path` segment that puts it on PATH.
* **`ollama/before.sh`** — macOS only. This class of machine may
  already run ollama via the upstream `Ollama.app` installer instead
  of brew; before.sh quits that running server so brew's formula (in
  `packages/Brewfile`) doesn't fight it for the same port.
  **`ollama/after.sh`** starts the brew-managed service on macOS, and
  on Debian/Ubuntu (the one Linux family with no native `ollama`
  package) falls back to the `ollama` snap — deliberately *not*
  `packages/snap.list`, which would double-install on Fedora, and
  deliberately *not* the upstream installer, which writes outside
  `$HOME` (systemd unit, system user) in violation of CLAUDE.md §8.
  Neither script ever touches `~/.ollama` (20GB of models).
