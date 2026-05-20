---
description: Run shellcheck and commitlint to verify the branch is shippable.
allowed-tools: Bash(shellcheck*), Bash(commitlint*), Bash(git log*), Bash(find*), Bash(grep*)
---

Verify the working tree against every linter this repo cares about.
"Is the branch shippable?" check — does not modify anything, only
reports.

Procedure (run each in sequence; record exit codes; don't stop on
the first failure — report all three at the end):

1. **`shellcheck`** — over `scripts/*.sh` plus `setup.sh`. Exclude
   sample/git template hooks (`configurations/git/template/hooks/*`)
   since they are bare-shim scripts.
   ```sh
   shellcheck setup.sh scripts/*.sh
   ```
2. **`packages/*.list` syntax** — each non-comment line must be a
   single package name (no shell metacharacters, no spaces — except
   `snap.list`, which permits trailing flags like `--classic`).
   ```sh
   for f in packages/*.list; do
     awk '/^\s*[^#]/ && /[;&|<>$]/ { print FILENAME":"NR": bad chars: "$0 }' "$f"
   done
   ```
3. **`commitlint --from origin/main`** — validate every commit on
   the current branch against the Conventional Commits rule set. If
   the branch has non-conventional messages, list the offending
   hashes — but don't propose rewriting history.

Final report shape:

```
shellcheck           : <ok|fail (N findings)>
package-list syntax  : <ok|fail (N bad lines)>
commitlint           : <ok|fail (N commits)>
```

If everything is `ok`, congratulate briefly. If anything failed,
list concrete next steps (`shellcheck <file>`, "fix line in
packages/<file>:LINE", "rebase and reword commit `<hash>`").
