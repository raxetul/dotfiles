#!/usr/bin/env bash
# packages/custom-install/starship/before.sh — runs BEFORE the package
# manager installs starship.
#
# The Debian fallback is a direct release-binary download (no third-party
# apt repo to register, no key to trust, no dir to pre-create), so this
# hook is a no-op. Kept as a placeholder so every custom-install/<pkg>/
# directory has the same before/after slots.
set -euo pipefail
exit 0
