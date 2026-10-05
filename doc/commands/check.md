---
source: .claude/commands/check.md
maintainer: raxetul@gmail.com
claude-rule: "Update this doc whenever the source changes."
---
# /check

## Purpose

This command runs every linter that this repo uses: `shellcheck`, the package-list syntax check, and
`commitlint --from origin/main`. The command is read-only. It reports problems and does not fix them.

## Arguments

None.

## Behavior

The command runs each step in sequence and records the exit codes. It does **not** stop at the first failure.
At the end, it reports all three results:

1. **`shellcheck`** — runs on `scripts/*.sh` and `setup.sh`. It skips `configurations/git/template/hooks/*`,
   because those files are bare shims.
2. **`packages/*.list` syntax** — each line that is not a comment must be one package name. The name has no
   shell metacharacters and no spaces. Two files are exceptions:
   - `snap.list` allows trailing flags, for example `--classic`.
   - `script-install.list` has two columns: `<probe-bin> <installer cmd>`. The command column can have shell
     metacharacters. The check skips this file.
3. **`commitlint --from origin/main`** — checks each commit on the current branch against the Conventional
   Commits rules. It lists the hashes that fail. It does **not** suggest a rewrite of the history.

The final report has this shape:

```
shellcheck           : <ok|fail (N findings)>
package-list syntax  : <ok|fail (N bad lines)>
commitlint           : <ok|fail (N commits)>
```

If all results are `ok`, the command gives a short congratulation. If a result is `fail`, the command lists the
next steps: `shellcheck <file>`, "fix line in packages/<file>:LINE", or "rebase and reword `<hash>`".

## Hard rules

- Do not fix a problem. Only report it.
- Do not rewrite history.
- Do not mark a failure as ok.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — the same `shellcheck` check at commit time.
- [packages/](../../packages/) — the install lists that the command checks for syntax.
