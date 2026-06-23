#!/usr/bin/env bash
# packages/custom-install/atuin/after.sh — runs AFTER the package
# manager step.
#
# Two jobs:
#
#   1. Fallback install on Debian/Ubuntu/Mint. atuin is in
#      packages/Brewfile, pacman.list and dnf.list (brew/pacman/dnf
#      provide it), but not in apt repos. The upstream installer drops
#      the binary in ~/.atuin/bin (NOT ~/.local/bin), and we pass
#      ATUIN_NO_MODIFY_PATH=1 so it doesn't edit the shell rc files —
#      .path owns PATH, not the installer.
#
#   2. Write the ~/.atuin/bin segment into .path. ~/.atuin/bin is NOT
#      one of .load's bootstrap dirs (~/.scripts, ~/.local/bin), so
#      without this segment `command -v atuin` fails in interactive
#      shells and the `atuin init` guard in .load never fires — which
#      is exactly the bug this hook fixes. The [ -d ] guard keeps the
#      segment a harmless no-op on hosts where brew/pacman/dnf installed
#      atuin elsewhere (there ~/.atuin/bin simply won't exist).
#
# Idempotent. Honors DRY_RUN=1.
set -euo pipefail

# --- 1. Fallback install (Debian only — native managers cover the rest) ---
if [ "$(uname)" = "Linux" ] && ! command -v atuin >/dev/null 2>&1 \
   && [ ! -x "${HOME}/.atuin/bin/atuin" ]; then
    echo "==> installing atuin (upstream installer → ~/.atuin/bin)"
    if [ "${DRY_RUN:-0}" = "1" ]; then
        echo "DRY-RUN: curl -fsSL https://setup.atuin.sh | env ATUIN_NO_MODIFY_PATH=1 sh"
    else
        curl -fsSL https://setup.atuin.sh \
            | env ATUIN_NO_MODIFY_PATH=1 sh
    fi
fi

# --- 2. .path segment for ~/.atuin/bin ---
_repo_root="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
_path_file="${_repo_root}/.path"
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "DRY-RUN: write atuin segment (~/.atuin/bin) to ${_path_file}"
    unset _repo_root _path_file
    exit 0
fi
touch "${_path_file}"
# Strip any existing atuin segment (-i.bak for BSD sed on macOS).
sed -i.bak '/^# >>> atuin begin$/,/^# >>> atuin end$/d' "${_path_file}"
rm -f "${_path_file}.bak"
cat >> "${_path_file}" <<'EOF'
# >>> atuin begin
[ -d "${HOME}/.atuin/bin" ] && case ":${PATH}:" in
    *":${HOME}/.atuin/bin:"*) ;;
    *) PATH="${HOME}/.atuin/bin:${PATH}"; export PATH ;;
esac
# >>> atuin end
EOF
unset _repo_root _path_file
