#!/usr/bin/env bash
# packages/custom-install/opencode/before.sh — runs BEFORE the package
# manager step.
#
# macOS only: opencode has no homebrew-core formula. anomalyco/tap
# (github.com/anomalyco/homebrew-tap) is the only tap that builds it —
# brew refuses to load ANY third-party tap's formula until it's explicitly
# trusted ("Refusing to load formula ... from untrusted tap"); this is a
# blanket Homebrew policy for every non-core tap (confirmed: qmk/qmk hits
# the identical gate), not a signal specific to this tap. sst/tap exists
# and is still auto-updated, but its formula points at the same
# github.com/anomalyco/opencode release artifacts and trips the same gate
# via lineage tracking — tapping it buys nothing over anomalyco/tap
# directly. The repo owner approved this tap on 2026-09-02, after being shown
# that brew offers no other route to opencode and that the untrusted-tap gate
# fires for EVERY non-core tap rather than being specific to this one.
#
# Linux: opencode has no apt/pacman/dnf package either; it's installed by
# the upstream script in after.sh instead, so this hook is a no-op there.
#
# Idempotent — `brew tap`/`brew trust` are no-ops when already
# tapped/trusted. Honors DRY_RUN=1.
set -euo pipefail

if [ "$(uname)" != "Darwin" ]; then
    exit 0
fi

if ! command -v brew >/dev/null 2>&1; then
    exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: brew tap anomalyco/tap"
    echo "DRY-RUN: brew trust --tap anomalyco/tap"
    exit 0
fi

if ! brew tap | grep -qx "anomalyco/tap"; then
    echo "==> tapping anomalyco/tap (opencode)"
    brew tap anomalyco/tap
fi

if ! brew trust --json=v1 2>/dev/null | grep -q "anomalyco/tap"; then
    echo "==> trusting anomalyco/tap (approved by the lead 2026-09-02)"
    brew trust --tap anomalyco/tap
fi
