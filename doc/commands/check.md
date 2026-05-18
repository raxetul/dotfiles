---
source: .claude/commands/check.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /check

## Purpose

Run every linter this repo cares about: `nix flake check`,
`nixpkgs-fmt --check`, `shellcheck`, `commitlint --from origin/main`.
Read-only — reports, doesn't fix.

## Arguments

None.

## Behavior

Runs each step in sequence, records exit codes, does **not** stop
on first failure — reports all four at the end:

1. **`nix flake check`** — schema-validates `flake.nix` and any
   `checks.*` exports. Uses `--impure` (this repo needs it) and
   optionally `--no-build` for speed.
2. **`nixpkgs-fmt --check`** — formatting check across every
   `.nix` file. Targets:
   `find . -path ./.git -prune -o -name '*.nix' -print`.
3. **`shellcheck`** — over `scripts/*.sh` plus `setup.sh`. Skips
   `configurations/git/template/hooks/*` (those are bare shims).
4. **`commitlint --from origin/main`** — validates every commit on
   the current branch against the Conventional Commits ruleset.
   Lists offending hashes but does **not** propose rewriting
   history.

Final report shape:

```
nix flake check      : <ok|fail>
nixpkgs-fmt --check  : <ok|fail (N files)>
shellcheck           : <ok|fail (N findings)>
commitlint           : <ok|fail (N commits)>
```

If everything is `ok`, congratulates briefly. If anything fails,
lists concrete next steps (`nixpkgs-fmt <file>`,
`shellcheck <file>`, "rebase and reword `<hash>`").

## Hard rules

- Never fixes — only reports.
- Never rewrites history.
- Never marks a fail as ok.

## Related

- [configurations/lefthook.yml](../../configurations/lefthook.yml)
  — same `nixpkgs-fmt` + `shellcheck` checks at commit time.
- [home/modules/packages/common.nix](../../home/modules/packages/common.nix)
  — provides the binaries.
