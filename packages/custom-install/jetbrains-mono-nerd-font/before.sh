#!/usr/bin/env bash
# packages/custom-install/jetbrains-mono-nerd-font/before.sh — runs BEFORE
# the package manager step.
#
# The Nerd Font has no third-party repo to register and no system file to
# pre-create, so this hook is a no-op. Kept as a placeholder so every
# custom-install/<pkg>/ directory has the same before/after slots.
set -euo pipefail
exit 0
