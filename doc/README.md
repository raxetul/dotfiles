# Documentation index

One doc per significant artifact: the package inventory, the
theming palette, the per-command and per-hook reference. The
frontmatter `claude-rule:` on each page is a contract — agents
edit the doc whenever they edit its source.

## Architecture at a glance

```mermaid
graph TD
    SU[setup.sh]
    SU -->|macOS| B[brew bundle<br/>packages/Brewfile]
    SU -->|Linux| L[distro detect<br/>via /etc/os-release]
    L -->|apt| LA[packages/apt.list<br/>+ apt-desktop.list]
    L -->|pacman| LP[packages/pacman.list<br/>+ pacman-desktop.list]
    L -->|dnf| LD[packages/dnf.list<br/>+ dnf-desktop.list]
    L -->|fallback| LF[aur.list / snap.list]

    SU --> SL[scripts/symlinks.sh<br/>install]
    SL --> CFG[configurations/&lt;app&gt;/]
    SL --> HOME[~/.config/, ~/.vimrc, ~/.zshrc, …]

    SU --> SH[chsh -s zsh]
    SU --> LH[lefthook install]
```

## Top-level

| File                | Doc                                  |
| ------------------- | ------------------------------------ |
| `setup.sh`          | (this README) — bootstrap entrypoint |
| `scripts/symlinks.sh` | (inline help via `--help`) — symlink driver |
| `scripts/update-dotfiles` | (inline help) — refresh entrypoint |
| `scripts/dotfiles-state.sh` | [state-management.md](state-management.md) — realized-state ledger |
| `scripts/gpg-setup.sh` | (inline help) — GPG signing wizard |
| `scripts/claude-worktree` | [claude-worktrees.md](claude-worktrees.md) — parallel Claude sessions in git worktrees |
| `scripts/nix-uninstall.sh` | (inline help) — legacy Nix cleanup |
| `scripts/dc-image-update` | [dc-image-update.md](dc-image-update.md) — interactive docker compose image pull/recreate helper |

## Packages

| Doc                                              | Purpose                                                                 |
| ------------------------------------------------ | ----------------------------------------------------------------------- |
| [packages-native.md](packages-native.md)         | Single lookup table — every package, per OS, with fallback notes.       |
| [packages-summary.md](packages-summary.md)       | Flat summary — one row per package, per-OS install lane.                |

## Slash commands (`.claude/commands/*.md`)

| Command         | Doc                                            |
| --------------- | ---------------------------------------------- |
| `/apply`        | [commands/apply.md](commands/apply.md)         |
| `/update`       | [commands/update.md](commands/update.md)       |
| `/commit`       | [commands/commit.md](commands/commit.md)       |
| `/check`        | [commands/check.md](commands/check.md)         |

## Hooks (`.claude/hooks/*.sh`)

| Hook               | Doc                                              |
| ------------------ | ------------------------------------------------ |
| `pre-commit.sh`    | [hooks/pre-commit.md](hooks/pre-commit.md)       |
| `commit-msg.sh`    | [hooks/commit-msg.md](hooks/commit-msg.md)       |
| `post-tool-use.sh` | [hooks/post-tool-use.md](hooks/post-tool-use.md) |

## Refactor history

| Doc                                                         | Purpose                                                                 |
| ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| [v3-native-inventory.md](v3-native-inventory.md)            | The v2→v3 plan: maps every former Nix-managed surface to its native equivalent and tracks phase status. |

## Cross-cutting

| Topic              | Doc                                                                                                 |
| ------------------ | --------------------------------------------------------------------------------------------------- |
| Theming            | [theming.md](theming.md) — Catppuccin Mocha palette + per-app mapping.                              |
| Shell history      | [atuin.md](atuin.md) — atuin's three search surfaces, all pinned to global (non-session) scope.     |
| Project init       | [init-proj.md](init-proj.md) — the `/init-proj-*` command family and how per-project standards layer. |
| Parallel Claude    | [claude-worktrees.md](claude-worktrees.md) — `claude-worktree` / `cwt`: a worktree + Claude session per branch. |
| Footprint / state  | [state-management.md](state-management.md) — the realized-state ledger that records what got planted (and what we may safely remove). |
| Agentic promotion  | [agentic-promotion.md](agentic-promotion.md) — lifting rules from repo-local `.claude/` to global. |
| Claude settings    | [claude-settings.md](claude-settings.md) — tracked `settings.json` vs. gitignored `settings.local.json`, and the atomic-save symlink-break failure mode. |
