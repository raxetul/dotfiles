#!/usr/bin/env bash
# packages/custom-install/atuin/before.sh — runs BEFORE the package
# manager installs atuin.
#
# The Debian fallback is the upstream installer (https://setup.atuin.sh),
# a direct binary download — no third-party apt repo to register, no key
# to trust, no dir to pre-create — so this hook is a no-op. Kept as a
# placeholder so every custom-install/<pkg>/ directory has the same
# before/after slots.
set -euo pipefail
exit 0
