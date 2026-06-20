---
source: .claude/hooks/pre-commit.sh
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# pre-commit.sh hook

## Purpose

Thin shim around `lefthook run pre-commit`. Used by `/commit` to
sanity-check the staged tree before the agent invokes
`git commit`. lefthook's commit-msg hook would catch the same
issues, but only after the commit machinery has already engaged —
running it ahead-of-time lets the agent revise without churn.

## Flags

None. The script reads no arguments.

## Behavior

1. Checks `lefthook` is on PATH. If missing, exits with code 2
   (advisory — not a hard failure; the agent decides).
2. Resolves repo root via `git rev-parse --show-toplevel`.
3. `cd` into the repo root and `exec lefthook run pre-commit`.

Exit codes:

- `0` — lefthook accepted the staged tree.
- `1` — lefthook rejected (formatting / shellcheck / etc.).
- `2` — lefthook not installed.

## Hard rules

- Never bypasses lefthook (`LEFTHOOK=0`).
- Doesn't run `lefthook install`. That's the responsibility of
  `setup.sh` (Phase 14) and `scripts/update-dotfiles` (Phase 11).

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — pre-commit pipeline (`shellcheck`).
- [.claude/commands/commit.md](../../.claude/commands/commit.md)
  — `/commit` invokes this shim.
