#!/usr/bin/env bash
# packages/custom-install/herdr/before.sh — runs BEFORE the package manager
# installs herdr.
#
# herdr has no third-party repo to register and no system file to pre-create
# (macOS takes it from packages/Brewfile, Linux from packages/script-install.list),
# so this hook is a no-op. Kept as a placeholder so every custom-install/<pkg>/
# directory has the same before/after slots.
set -euo pipefail
exit 0
