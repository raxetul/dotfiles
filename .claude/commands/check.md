---
description: Run nix flake check, nixpkgs-fmt --check, shellcheck, and commitlint.
allowed-tools: Bash(nix*), Bash(nixpkgs-fmt*), Bash(shellcheck*), Bash(commitlint*), Bash(git log*), Bash(find*), Bash(grep*)
---

Verify the working tree against every linter this repo cares about.
This is the "is the branch shippable?" check — it does not modify
anything, only reports.

Procedure (run each in sequence; record exit codes; do not stop on
the first failure — report all four at the end):

1. **`nix flake check`** — schema-validates `flake.nix` and any
   `checks.*` exports. Use `--impure` (this repo needs it) and pass
   `--no-build` if a full build is overkill for the user's intent.
   On a slow host, mention that it can take minutes.
2. **`nixpkgs-fmt --check`** — formatting check across all `.nix`
   files. Targets:
   ```
   find . -path ./.git -prune -o -name '*.nix' -print
   ```
   If it reports diffs, summarize the file list (don't paste the
   diff); the fix is `nixpkgs-fmt <file>` per file.
3. **`shellcheck`** — over `scripts/*.sh` plus `setup.sh`. Exclude
   sample/git template hooks (`configurations/git/template/hooks/*`)
   from this check since they are bare-shim scripts.
4. **`commitlint --from origin/main`** — validate every commit on
   the current branch (relative to `origin/main`) against the
   Conventional Commits rule set. If the branch has commits with
   non-conventional messages, list the offending hashes — but do
   not propose rewriting history.

Final report shape:

```
nix flake check      : <ok|fail>
nixpkgs-fmt --check  : <ok|fail (N files)>
shellcheck           : <ok|fail (N findings)>
commitlint           : <ok|fail (N commits)>
```

If everything is `ok`, congratulate briefly. If anything failed,
list concrete next steps the user can take (`nixpkgs-fmt <file>`,
`shellcheck <file>`, "rebase and reword commit `<hash>`").
