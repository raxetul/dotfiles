# `packages/custom-install/` — per-package install hooks

Some packages need a step that the native package manager does not run:

* **Before the install** — register a third-party APT/COPR/RPM-Fusion
  repo, accept an upstream key, create a config dir for the
  post-install script to write to, or install a build dependency.
* **After the install** — provision a toolchain (`rustup default stable`
  → `~/.cargo/bin/cargo`), enable a service, write a one-time config
  file, or run a self-test.

This directory holds one subdirectory for each package that needs a
hook. Each subdirectory contains two scripts:

```text
packages/custom-install/
├── README.md
└── <pkg>/
    ├── before.sh    # runs BEFORE the package install step
    └── after.sh     # runs AFTER the package install step (+ AUR/Snap fallback)
```

The folder name is the same as the package name on the install lists
(`packages/Brewfile`, `packages/<pkgmgr>.list`). **Both `before.sh`
and `after.sh` MUST exist** for each `<pkg>/`. Make the unused side
a stub (`#!/usr/bin/env bash` + `set -euo pipefail` + `exit 0`).
This keeps the layout uniform. Each package then adds
both banners to the log on every run, also when that side has no work.

## Driver order

`setup.sh` and `scripts/update-dotfiles` both go through `custom-install/*`
in lexical order. For each directory, they run these scripts:

1. `before.sh` — runs in the **before-install** phase, before
   `brew bundle` / `apt|pacman|dnf install`.
2. `after.sh` — runs in the **after-install** phase, after the package
   step *and* the AUR/Snap fallback are complete.

`update-dotfiles` has a separate stage for each phase
(`stage_packages_custom_before`, `stage_packages_custom_after`).
To run one phase, use `--only=custom-install-before` or
`--only=custom-install-after`. To run both phases, use
`--only=custom-install`.

## Contract (every script)

1. **Be executable** (`chmod +x`).
2. **Be idempotent.** If the work is already done, the script must exit
   `0` and have no side effects. Check the state first. Then act.
3. **Skip cleanly when the package is not installed.** The list-driven
   install step can leave the package out (older distro, dry-run,
   `--only=symlinks`). In `after.sh`, check `command -v <bin>`. If the command
   is missing, exit `0` with a one-line note. In `before.sh`,
   stop early when the work is already done (the repo is already
   registered, the key is already trusted, and so on).
4. **Print one `==>` banner** for the action. Print nothing else
   when the script succeeds.
5. **Honor `DRY_RUN`.** If the caller sets `DRY_RUN=1`, print the
   command. Do not run it.
6. **Use `$DOTFILES_DIR`** to find files in this repo. Do not
   calculate it from `$0` again. You can also run these scripts from
   `~/.scripts/` through PATH.
7. **Route PATH and per-package env through `$HOME/.dotfiles/path`.**
   If the package adds binaries to PATH or defines a
   `FOO_HOME`-style env var, the `after.sh` MUST write a segment
   into `path`. Put the markers `# >>> <pkg> begin` and `# >>> <pkg> end` around the segment
   (see [load and path](#load-and-path--shell-init-centre)).
   Do NOT add ad-hoc `PATH=…` lines to `configurations/{zsh,bash}/rc`.

## `load` and `path` — shell init centre

Two files under `$HOME/.dotfiles/` form the runtime shell-init centre.
They are per-user state and are never inside the repo. The repo can be shared
and owned by root:dotfiles at `/opt/dotfiles`.

```text
$HOME/.dotfiles/load    # sourced by zshrc + bashrc — the entrypoint
$HOME/.dotfiles/path    # sourced by load — PATH + per-package env
```

Hosts that did not yet run `scripts/migrate-to-opt.sh` still read a legacy
in-repo `${DOTFILES_DIR}/.load` / `${DOTFILES_DIR}/.path` pair as a fallback.
Every writer uses the new location.

* **`load`** is the orchestrator. `scripts/init-load` creates it on
  the first run of `setup.sh` or `update-dotfiles`. The user can then edit
  it for host-specific exports, aliases, or plugin init
  calls. The only content that the script generates is the `. path` line.
* **`path`** is fully managed by the `after.sh` hooks. Each package
  owns one segment. The segment has these markers:

  ```sh
  # >>> <pkg> begin
  …
  # >>> <pkg> end
  ```

  When an `after.sh` runs again, it strips the old segment with `sed
  -i.bak '/^# >>> <pkg> begin$/,/^# >>> <pkg> end$/d'` and appends
  a fresh one. This makes the script idempotent.

`configurations/{zsh,bash}/rc` must only do `source
"$HOME/.dotfiles/load"` (with the legacy fallback above). Everything
else goes through `load` → `path` → segments.

### Skeleton segment writer (`after.sh`)

```sh
_path_dir="${HOME}/.dotfiles"
_path_file="${_path_dir}/path"
mkdir -p "${_path_dir}"
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
unset _path_dir _path_file
```

The `case` guard makes the sourcing idempotent across shell reloads.
The `[ -d ]` guard makes it safe before the bin dir exists. An example is a
freshly cloned host before `setup.sh` has run.

## Logging

Two append-only logs under
`${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/`:

| File                  | Written by                                   | Captures                                                                                                              |
| --------------------- | -------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `custom-install.log`  | `scripts/run-custom-install-hook` (per-hook) | Only the `before.sh` / `after.sh` script output, one banner per hook.                                                 |
| `update-dotfiles.log` | `scripts/update-dotfiles` (per-session)      | The entire update run: git-pull, brew/native install, fallbacks, custom-install hooks, and the configurations layer.  |

Both logs also go to the terminal at the same time through `tee`.
The scripts do not capture output in silence.

### Per-hook log format

Each hook has one header line. The phase name is padded on the left to 6 characters, so the
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

Each `update-dotfiles` run has an ISO-timestamped banner at the start and at the end.
These banners help you find one run:

```text
==== 2026-06-17T13:45:01Z update-dotfiles  only=both dry-run=0 desktop=0 ====
... full session output ...
==== 2026-06-17T13:46:38Z update-dotfiles end rc=0 ====
```

### Why repeat the hooks on every update?

`before.sh` and `after.sh` must be **idempotent** (see the
contract above). `update-dotfiles` can therefore run them again on each
invocation without harm. The session log shows which hooks did nothing
and which hooks changed something.

### Inspecting

* To follow the log live, run `tail -F ~/.local/state/dotfiles/update-dotfiles.log`.
* To find one hook in the history, run
  `grep -A 200 '^after .* rustup$' ~/.local/state/dotfiles/custom-install.log`.
* To find one session, open `update-dotfiles.log` and search for the
  matching pair of `==== … ====` banners.

## When NOT to add a hook here

* Configuration in `~/.config/<app>/<file>`. This is a task for
  `configurations/<app>/`, and `scripts/symlinks.sh` plants it.
* Plugin bootstraps that need a network and a managed `~/.config/`
  layout (vim-plug, TPM, oh-my-zsh-style plugin checkouts). These
  belong in `setup.sh` Step 5 (plugin bootstrap), not here. The
  difference: custom-install hooks run before and after the work of the *package
  manager*. Plugin bootstraps are user-scope tools outside
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
| `herdr/`     | herdr    | no-op stub  | warn when the RUNNING server is older than the installed binary |

* **`rustup/after.sh`** — runs `rustup default stable` if no default
  toolchain is configured. It then installs the crates in the
  `CARGO_CRATES` array at the top of the script with cargo (defaults: `cargo-binstall`,
  `cargo-edit`, `cargo-update`, `cargo-outdated`, `cargo-audit`,
  `cargo-nextest`). Edit the array to add or remove crates. The script installs
  `cargo-binstall` first, so that the other crates install from prebuilt binaries.
* **`starship/`, `atuin/`, `claude/`, `lefthook/after.sh`** —
  release-binary fallbacks for tools that the native package manager might
  not have. Each script exits early when the tool is already on PATH (that is,
  brew/pacman/dnf/AUR provided it). It installs the upstream
  binary only on the platforms that do not have the tool. **`atuin/after.sh`** is the
  only one of these that writes a `.path` segment. Its installer puts the tool in
  `~/.atuin/bin`, which is *not* one of the bootstrap dirs of `.load`. The
  segment is what puts `atuin` on PATH. The other three scripts install
  into `~/.local/bin` (already on PATH) and write no segment.
* **`herdr/after.sh`** — the only hook that installs nothing. A new
  herdr binary does not replace the herdr *server* that already runs.
  After an update run, the client and the server can use
  different protocol generations. Then each socket-API command
  (`herdr agent`/`pane`, and so `scripts/herdr-team` and
  `scripts/claude-worktree`) fails with `protocol_mismatch`. The hook
  finds this with `herdr status --json` and prints the fix. It does
  **not** restart anything. When you stop a session, each process in
  its panes exits. An update run must never cause this. Run
  `herdr-upgrade` when you are ready. See
  [`doc/herdr-upgrade.md`](../../doc/herdr-upgrade.md).
* **`opencode/before.sh`** — macOS only. opencode has no
  homebrew-core formula. `anomalyco/tap` is the only tap that builds
  it, and brew does not load the formula of a third-party tap until
  you explicitly trust it. The script taps and trusts the tap here, before
  the `brew "anomalyco/tap/opencode"` line in `packages/Brewfile` runs.
  **`opencode/after.sh`** installs it on Linux instead (no apt/pacman/dnf
  package exists there). It uses the upstream installer to install into `~/.opencode/bin`.
  It also writes the `.path` segment that puts the tool on PATH.
* **`ollama/before.sh`** — macOS only. A machine of this class might
  already run ollama from the upstream `Ollama.app` installer and not from brew.
  The before.sh script quits that running server. Then the brew formula (in
  `packages/Brewfile`) does not use the same port as the server.
  **`ollama/after.sh`** starts the service that brew manages on macOS. On Debian/Ubuntu
  (the one Linux family with no native `ollama` package), it falls back to the
  `ollama` snap. It deliberately does *not* use
  `packages/snap.list`, because that would install the package twice on Fedora.
  It also deliberately does *not* use the upstream installer. That installer writes a systemd
  unit and a system user outside the home of any user. This is the wrong footprint
  for a package binary, wherever the dotfiles repo is.
  Neither script ever touches `~/.ollama` (20GB of models).
