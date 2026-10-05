---
source: .claude/hooks/commit-msg.sh
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# commit-msg.sh hook

## Purpose

This hook checks a proposed commit message against the Conventional Commits regex of this repo. It runs
*before* `git commit`. The commit-msg hook of lefthook does the same check at commit time. This hook lets
`/commit` reject its own draft and try again. It does not call the commit machinery.

## Flags

```
commit-msg.sh <path-to-message-file>
commit-msg.sh -                       # read from stdin
```

## Behavior

1. The hook reads the candidate message from the path argument or from stdin.
2. The hook takes the first line that is not a comment as the subject.
3. The hook matches the subject against
   `^(feat|fix|refactor|chore|docs|style|perf|build|ci|test|revert)(\([a-z0-9_/.-]+\))?!?: .+`
   — this regex must stay the same as the one in `configurations/lefthook.yml`.

Exit codes:

- `0` — the subject matches the Conventional Commits pattern.
- `1` — the subject does not match.
- `2` — wrong use of the CLI (no argument, or the stdin or file is not readable).

When the check fails, the hook prints the subject that failed and a usage cheat-sheet to stderr.
The cheat-sheet has the list of types and three example messages.

## Hard rules

- The regex has one source of truth. When you change it, change this hook and `configurations/lefthook.yml`
  together.
- Do not fix the message automatically.
- Do not edit the file argument.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — the same regex, enforced at git commit time.
- [.claude/commands/commit.md](../../.claude/commands/commit.md)
  — `/commit` calls this hook on its draft.
