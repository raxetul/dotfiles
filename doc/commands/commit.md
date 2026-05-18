---
source: .claude/commands/commit.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /commit

## Purpose

Build a Conventional Commit message from `git diff --cached` and
run `git commit`. Validates the draft subject against this repo's
commit-msg regex *before* invoking git, so the agent can revise
without engaging the commit machinery.

## Arguments

None — operates on what's staged.

## Behavior

1. `git status --short` — confirm there's something staged. Never
   uses `git add -A` / `git add .`.
2. `git diff --cached` — reads every hunk; groups by file and
   identifies the dominant intent (feat / fix / refactor / chore /
   docs / style / perf / build / ci / test / revert).
3. Picks a scope from touched paths (one short word). Multiple
   unrelated areas ⇒ omit the scope.
4. Drafts subject ≤ 72 chars, imperative mood, no trailing period.
   Must match
   `^(<type>)(\(<scope>\))?!?: <subject>`.
5. Drafts a body that explains the *why*, one bullet per file or
   per logical change, lines ≤ 72 chars.
6. Runs `./.claude/hooks/commit-msg.sh <draft>` to validate before
   committing. If it exits non-zero, revises and retries.
7. `git commit -m "$(cat <<'EOF' ... EOF)"` with the
   `Co-Authored-By` footer.
8. `git status` afterwards to confirm.

## Hard rules

- Never `--amend` unless the user explicitly asks.
- Never `--no-verify`. On lefthook failure, fixes the underlying
  issue and creates a new commit.
- Never commits files matching secret patterns: `.env`, `*.pem`,
  `credentials*`, `*.key`, `id_rsa*`. Refuses and warns.

## Related

- [.claude/hooks/commit-msg.sh](../../.claude/hooks/commit-msg.sh)
  — validator used in step 6.
- [.claude/hooks/pre-commit.sh](../../.claude/hooks/pre-commit.sh)
  — lefthook shim, runs before the commit.
- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — the regex this command honors.
- [doc/hooks/commit-msg.md](../hooks/commit-msg.md).
