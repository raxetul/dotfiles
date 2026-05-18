---
source: .claude/hooks/commit-msg.sh
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# commit-msg.sh hook

## Purpose

Validate a proposed commit message against this repo's
Conventional Commits regex *before* `git commit` runs. lefthook's
commit-msg hook covers the same ground at commit time; this hook
lets `/commit` reject its own draft and retry without engaging
the commit machinery.

## Flags

```
commit-msg.sh <path-to-message-file>
commit-msg.sh -                       # read from stdin
```

## Behavior

1. Reads the candidate message from the path argument or stdin.
2. Extracts the first non-comment line as the subject.
3. Matches against
   `^(feat|fix|refactor|chore|docs|style|perf|build|ci|test|revert)(\([a-z0-9_/.-]+\))?!?: .+`
   — kept in lockstep with `configurations/lefthook.yml`.

Exit codes:

- `0` — subject matches the Conventional Commits pattern.
- `1` — subject does not match.
- `2` — bad CLI usage (no argument, or stdin/file unreadable).

On failure, prints the offending subject + a usage cheat-sheet
(types list, three example messages) to stderr.

## Hard rules

- Regex is the single source of truth — keep this hook and
  `configurations/lefthook.yml` in sync when changing it.
- Never auto-fixes the message.
- Never edits the file argument.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — same regex, enforced at git commit time.
- [.claude/commands/commit.md](../../.claude/commands/commit.md)
  — `/commit` calls this hook on its draft.
