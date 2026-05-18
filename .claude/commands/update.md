---
description: Refresh packages and configurations via scripts/update.sh.
allowed-tools: Bash(./scripts/update.sh*), Bash(scripts/update.sh*), Bash(grep*)
---

Run `scripts/update.sh`. This is the entry point for "make this host
current with what's checked in," covering both flake-pinned packages
and the configurations layer (symlinks, hooks, theme caches).

Procedure:

1. Read `scripts/update.sh` head comment (lines 1-26) and report which
   stages will run. If the user passes flag-style hints, forward them:
   - `--dry-run` → just print, don't run.
   - `--yes` → skip the git-pull confirmation prompt.
   - `--no-flake` → skip `nix flake update`; useful when you want a
     pure replay against the current `flake.lock`.
   - `--only=packages` / `--only=configurations` → run only that layer.
2. If the user said "what would change" without specifying flags,
   invoke `scripts/update.sh --dry-run --yes`. Show the output and
   ask whether to do it for real.
3. If running for real, capture exit code. Non-zero means a stage
   failed — surface the stage name from the error line
   ("ERR: stage X failed") so the user can rerun just that stage.

What this command does NOT do:
- Edit any file in the repo. Updates are runtime-only.
- Bypass the confirmation prompt unless `--yes` is explicitly passed.
- Push commits. `scripts/update.sh` runs `git pull --rebase`, never
  `git push`.
