---
description: Apply the dotfiles repo via setup.sh — confirm the plan first.
allowed-tools: Bash(./setup.sh*), Bash(grep*), Bash(ls*)
---

You are about to run this repo's bootstrap script (`./setup.sh`).
That installs Homebrew on macOS if missing, installs packages via the
native package manager (brew on macOS; apt/pacman/dnf on Linux),
bootstraps user-scope plugin managers, plants symlinks via
`scripts/symlinks.sh`, swaps the login shell to zsh, and installs
lefthook git hooks. It is idempotent — re-runs only do work that's
missing — but it does change real system state.

Procedure:

1. Read `./setup.sh` end-to-end so you understand every step. Quote
   each numbered "Step N" header from the script in your plan so the
   user can spot anything they want to skip.
2. Detect the active profile:
   - If `--desktop` is in the argv the user mentioned, run with that.
   - Otherwise default to baseline (Linux server profile, or macOS).
3. Print the plan: which steps will run, which will be skipped (e.g.
   Step 1 is a no-op on Linux because brew is macOS-only). Be
   explicit about anything that needs `sudo`: chsh, `/etc/shells`,
   distro-native install, optional `snap install`.
4. Wait for the user to confirm before invoking `./setup.sh`. If they
   say go, run it with the appropriate flags:
   - `./setup.sh` for baseline.
   - `./setup.sh --desktop` for Linux desktop.
   - Add `--update` only if the user explicitly asks to upgrade
     already-installed packages.
5. Stream the output. On non-zero exit, surface which step failed.

What this command does NOT do:

- Run `--update` unless the user explicitly asks. Default invocations
  install missing packages but don't upgrade ones already at older
  versions.
- Modify `configurations/`, `packages/`, or any other file in the
  repo. This is a pure runtime operation.
