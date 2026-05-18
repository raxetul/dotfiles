---
description: Build a Conventional Commit message from the staged diff and run git commit.
allowed-tools: Bash(git diff*), Bash(git status*), Bash(git log*), Bash(git commit*), Bash(./.claude/hooks/commit-msg.sh*)
---

Produce a Conventional Commit from `git diff --cached` and commit it.

Procedure:

1. `git status --short` — confirm there's something staged. If
   nothing is staged, list unstaged changes and ask whether to
   `git add` specific files. Never `git add -A` / `git add .` —
   that picks up `.env`, secrets, IDE state, and build artifacts.
2. `git diff --cached` — read every hunk. Group changes by file
   and identify the dominant intent:
   - **feat**: net-new functionality or a wholly new feature file.
   - **fix**: a bug fix (something previously broken).
   - **refactor**: behavior preserved, structure changed.
   - **docs**: only `doc/`, `README.md`, `ROADMAP.md`, or comment-
     only edits.
   - **chore**: tooling, ignore files, dep version bumps without
     behavior change.
   - **style** / **perf** / **build** / **ci** / **test** / **revert**:
     as named.
3. Pick a scope from the touched paths (one short word):
   - `home/modules/zsh.nix` → `zsh`.
   - `home/modules/gpg.nix` + `scripts/gpg-setup.sh` → `gpg`.
   - `configurations/themes/*` + multiple modules → `theme`.
   - Multiple unrelated areas → omit the scope.
4. Write a subject line ≤ 72 chars, imperative mood, no trailing
   period. Match the regex in `lefthook.yml`:
   `^(feat|fix|refactor|chore|docs|style|perf|build|ci|test|revert)(\(<scope>\))?!?: <subject>`.
5. Write a body that explains the **why**, not the what — the diff
   already shows the what. Use a bulleted list, one bullet per file
   or per logical change. Keep lines ≤ 72 chars.
6. Run `./.claude/hooks/commit-msg.sh <draft-file>` against the draft
   to catch a malformed subject before invoking `git commit`. If it
   exits non-zero, revise and retry.
7. `git commit -m "$(cat <<'EOF'
   <subject>

   <body>

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"`
8. `git status` afterwards to confirm the commit landed.

Hard rules:
- Never `--amend` an existing commit unless the user explicitly asks.
- Never `--no-verify`. If the pre-commit hook fails, fix the underlying
  issue, re-stage, and create a new commit.
- Never commit files that look like secrets (`.env`, `*.pem`,
  `credentials*`, `*.key`, `id_rsa*`). If one is staged, refuse and
  warn.
