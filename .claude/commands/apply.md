---
description: Apply the dotfiles repo via setup.sh — dry-run first, then confirm.
allowed-tools: Bash(./setup.sh*), Bash(grep*), Bash(ls*)
---

You are about to run this repo's bootstrap script (`./setup.sh`).
That installs Nix if missing, enables flakes, installs Homebrew on
macOS, runs `home-manager switch`, swaps the login shell to zsh, and
installs distro-native packages on Linux. It is idempotent — re-runs
only do work that's actually missing — but it does change real system
state.

Procedure:

1. Read `./setup.sh` end-to-end so you understand every step. Quote
   each numbered "Step N" header from the script in your plan so the
   user can spot anything they want to skip.
2. Detect the active profile:
   - If `$DOTFILES_PROFILE` is set in the environment, honor it.
   - Otherwise default to `server`. The user can pass `--desktop`.
3. Print the plan: which steps will run, which will be skipped (e.g.
   Step 2b is a no-op on Linux). Be explicit about anything that
   needs `sudo` (chsh, `/etc/shells`, distro-native install).
4. Wait for the user to confirm before invoking `./setup.sh`. If they
   say go, run it with the appropriate flags:
   - `./setup.sh` for server.
   - `./setup.sh --desktop` for desktop.
   - Add `--update` only if the user explicitly asks for a flake bump.
5. Stream the output. On non-zero exit, surface which step failed.

What this command does NOT do:
- Run `nix flake update` unless the user passes `--update`. Default
  invocations of `setup.sh` are reproducible against the current
  `flake.lock`.
- Modify `flake.lock`, `home/`, `configurations/`, or any other file
  in the repo. This is a pure runtime operation.
