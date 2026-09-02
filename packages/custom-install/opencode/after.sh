#!/usr/bin/env bash
# packages/custom-install/opencode/after.sh — runs AFTER the package
# manager step.
#
# macOS: nothing to do — before.sh tapped + trusted anomalyco/tap, and
# packages/Brewfile's `brew "anomalyco/tap/opencode"` line already installed
# the binary into /opt/homebrew/bin, already on PATH via brew's shellenv.
#
# Linux: opencode has no apt/pacman/dnf package. The upstream installer
# (curl https://opencode.ai/install | bash) drops the binary in
# ~/.opencode/bin (NOT ~/.local/bin) and, left to itself, edits shell rc
# files to add it to PATH — we pass --no-modify-path since .path owns PATH,
# not the installer (same pattern as atuin/after.sh).
#
# Idempotent — exits early when opencode is already on PATH. Honors
# DRY_RUN=1.
set -euo pipefail

if command -v opencode >/dev/null 2>&1; then
    exit 0
fi

if [ "$(uname)" = "Darwin" ]; then
    # Brewfile should have installed it; if it's still missing, brew
    # bundle failed or was skipped — nothing for this hook to fix.
    exit 0
fi

echo "==> installing opencode (upstream installer → ~/.opencode/bin)"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path"
else
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
fi

# --- .path segment for ~/.opencode/bin ---
_repo_root="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
_path_file="${_repo_root}/.path"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: write opencode segment (~/.opencode/bin) to ${_path_file}"
    unset _repo_root _path_file
    exit 0
fi
touch "${_path_file}"
sed -i.bak '/^# >>> opencode begin$/,/^# >>> opencode end$/d' "${_path_file}"
rm -f "${_path_file}.bak"
cat >> "${_path_file}" <<'EOF'
# >>> opencode begin
[ -d "${HOME}/.opencode/bin" ] && case ":${PATH}:" in
    *":${HOME}/.opencode/bin:"*) ;;
    *) PATH="${HOME}/.opencode/bin:${PATH}"; export PATH ;;
esac
# >>> opencode end
EOF
unset _repo_root _path_file
