---
source: .claude/commands/check.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /check

## Purpose

Run every linter this repo cares about: `shellcheck`,
package-list syntax, `commitlint --from origin/main`. Read-only —
reports, doesn't fix.

## Arguments

None.

## Behavior

Runs each step in sequence, records exit codes, does **not** stop
on first failure — reports all three at the end:

1. **`shellcheck`** — over `scripts/*.sh` plus `setup.sh`. Skips
   `configurations/git/template/hooks/*` (those are bare shims).
2. **`packages/*.list` syntax** — each non-comment line must be a
   single package name (no shell metacharacters, no spaces; the
   exception is `snap.list`, which allows trailing flags like
   `--classic`). Walks every `.list` under `packages/`.
3. **`commitlint --from origin/main`** — validates every commit on
   the current branch against the Conventional Commits ruleset.
   Lists offending hashes but does **not** propose rewriting
   history.

Final report shape:

```
shellcheck           : <ok|fail (N findings)>
package-list syntax  : <ok|fail (N bad lines)>
commitlint           : <ok|fail (N commits)>
```

If everything is `ok`, congratulates briefly. If anything fails,
lists concrete next steps (`shellcheck <file>`, "fix line in
packages/<file>:LINE", "rebase and reword `<hash>`").

## Hard rules

- Never fixes — only reports.
- Never rewrites history.
- Never marks a fail as ok.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — same `shellcheck` check at commit time.
- [packages/](../../packages/) — the install lists being syntax-
  checked.
