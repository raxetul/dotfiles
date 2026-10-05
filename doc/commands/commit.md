---
source: .claude/commands/commit.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /commit

## Purpose

This command builds a Conventional Commit message from `git diff --cached`. Then it runs `git commit`.
Before it calls git, the command checks the draft subject against the commit-msg regex of this repo. The agent
can then change the draft without a call to the commit machinery.

## Arguments

None. The command uses the files that are staged.

## Behavior

1. Run `git status --short` to confirm that a file is staged. Never use `git add -A` or `git add .`.
2. Run `git diff --cached`. Read every hunk and group the hunks by file. Find the main intent
   (feat / fix / refactor / chore / docs / style / perf / build / ci / test / revert).
3. Pick a scope from the paths that changed. The scope is one short word. If the changes are in
   several unrelated areas, omit the scope.
4. Write a subject of 72 characters or less. Use the imperative mood. Do not add a period at the end.
   The subject must match `^(<type>)(\(<scope>\))?!?: <subject>`.
5. Write a body that explains the *why*. Use one bullet for each file or each logical change.
   Each line has 72 characters or less.
6. Run `./.claude/hooks/commit-msg.sh <draft>` to check the draft before the commit. If it exits with a
   non-zero code, change the draft and run it again.
7. Run `git commit -m "$(cat <<'EOF' ... EOF)"` with the `Co-Authored-By` footer.
8. Run `git status` to confirm the result.

## Hard rules

- Do not use `--amend` unless the user asks for it.
- Do not use `--no-verify`. If lefthook fails, fix the cause and make a new commit.
- Do not commit files that match secret patterns: `.env`, `*.pem`, `credentials*`, `*.key`, `id_rsa*`.
  The command refuses and shows a warning.

## Related

- [.claude/hooks/commit-msg.sh](../../.claude/hooks/commit-msg.sh)
  — the validator that step 6 uses.
- [.claude/hooks/pre-commit.sh](../../.claude/hooks/pre-commit.sh)
  — the lefthook shim. It runs before the commit.
- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — the regex that this command uses.
- [doc/hooks/commit-msg.md](../hooks/commit-msg.md).
