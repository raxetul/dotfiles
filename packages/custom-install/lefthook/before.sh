#!/usr/bin/env bash
# packages/custom-install/lefthook/before.sh — runs BEFORE the package
# manager step.
#
# The apt/dnf fallback is a direct GitHub release-binary download (no
# third-party repo to register), and Arch pulls lefthook-bin from the
# AUR via packages/aur.list — so this hook is a no-op. Kept as a
# placeholder so every custom-install/<pkg>/ directory has the same
# before/after slots.
set -euo pipefail
exit 0
