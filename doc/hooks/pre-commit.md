---
source: .claude/hooks/pre-commit.sh
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# pre-commit.sh hook

## Purpose

This hook is a thin shim around `lefthook run pre-commit`. `/commit` uses it to check the staged tree before the
agent runs `git commit`. The commit-msg hook of lefthook finds the same problems. But it runs only after the
commit machinery has started. When this shim runs first, the agent can change the commit with less rework.

## Flags

None. The script reads no arguments.

## Behavior

1. The hook checks that `lefthook` is on PATH. If it is missing, the hook exits with code 2. This is advisory,
   not a hard failure. The agent decides what to do.
2. The hook finds the repo root with `git rev-parse --show-toplevel`.
3. The hook does `cd` to the repo root and runs `exec lefthook run pre-commit`.

Exit codes:

- `0` — lefthook accepted the staged tree.
- `1` — lefthook rejected the staged tree (formatting, shellcheck, and so on).
- `2` — lefthook is not installed.

## Hard rules

- Do not bypass lefthook (`LEFTHOOK=0`).
- Do not run `lefthook install`. `setup.sh` (Phase 14) and `scripts/update-dotfiles` (Phase 11) do this task.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — the pre-commit pipeline (`shellcheck`).
- [.claude/commands/commit.md](../../.claude/commands/commit.md)
  — `/commit` runs this shim.
