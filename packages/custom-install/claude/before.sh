#!/usr/bin/env bash
# packages/custom-install/claude/before.sh — runs BEFORE the package
# manager step.
#
# Claude Code installs from the upstream installer (a direct binary
# download) on every platform — no repo to register, no key, no dir to
# pre-create — so this hook is a no-op. Kept as a placeholder so every
# custom-install/<pkg>/ directory has the same before/after slots.
set -euo pipefail
exit 0
