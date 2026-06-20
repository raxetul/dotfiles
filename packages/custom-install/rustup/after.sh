#!/usr/bin/env bash
# packages/custom-install/rustup/after.sh — runs AFTER the package
# manager installs rustup.
#
# Two phases:
#   1. Provision the default Rust toolchain. Both Homebrew's `rustup`
#      formula and Linux distro `rustup` packages ship only the
#      `rustup` shim — the toolchain (cargo, rustc, rustfmt, clippy,
#      rust-analyzer) is materialized into ~/.cargo/bin/ only after
#      you pick a default channel. We pick `stable` once.
#   2. Install the cargo crates listed in CARGO_CRATES below. Each is
#      checked against `cargo install --list` first, so re-running
#      this script after a fresh add only installs the new entry.
#      cargo-binstall is bootstrapped first because it downloads
#      pre-built release binaries from GitHub for any subsequent
#      crate, which is roughly 10x faster than building from source.
#
# Idempotent. Honors DRY_RUN=1.
set -euo pipefail

# Crates to install. Edit this list to add/remove. Comments are
# intent, not a doc — keep them short.
CARGO_CRATES=(
    cargo-binstall    # prebuilt-binary installer (bootstrapped first; see below)
    cargo-edit        # cargo add / rm / upgrade
    cargo-update      # `cargo install-update -a` keeps installed crates current
    cargo-outdated    # check stale dependency versions
    cargo-audit       # CVE audit against the RustSec advisory DB
    cargo-nextest     # faster, friendlier test runner
)

# ----------------------------------------------------------------------
# Phase 1 — default toolchain
# ----------------------------------------------------------------------

if ! command -v rustup >/dev/null 2>&1; then
    echo "rustup not on PATH — skip"
    exit 0
fi

# `rustup default` (no args) exits 0 when a default is set, !=0 with
# "no default toolchain is configured" otherwise.
if rustup default >/dev/null 2>&1; then
    : # already provisioned, fall through to phase 2
else
    echo "==> rustup default stable (no toolchain configured yet)"
    if [ "${DRY_RUN:-0}" = "1" ]; then
        echo "DRY-RUN: rustup default stable"
    else
        rustup default stable
    fi
fi

# After phase 1, locate cargo via rustup itself. This handles all
# install flavors uniformly:
#   * upstream rustup-init      → ~/.cargo/bin/cargo
#   * brew rustup formula       → /opt/homebrew/Cellar/rustup/<v>/bin/cargo
#   * distro rustup package     → ~/.cargo/bin/cargo (rustup-managed)
# A bare ~/.cargo/bin PATH prepend doesn't cover brew, which keeps its
# shims in the Cellar — that was the bug behind "cargo not on PATH yet".
CARGO_BIN="$(rustup which cargo 2>/dev/null || true)"
if [ -z "${CARGO_BIN}" ] || [ ! -x "${CARGO_BIN}" ]; then
    echo "rustup could not resolve cargo (toolchain install pending?) — skipping CARGO_CRATES"
    exit 0
fi

# Add the toolchain's bin dir (where cargo/rustc/rustfmt/clippy live)
# AND ~/.cargo/bin (where `cargo install <crate>` lands) to PATH.
TOOLCHAIN_BIN="$(dirname "${CARGO_BIN}")"
case ":${PATH}:" in
    *":${TOOLCHAIN_BIN}:"*) ;;
    *) PATH="${TOOLCHAIN_BIN}:${PATH}"; export PATH ;;
esac
if [ -d "${HOME}/.cargo/bin" ]; then
    case ":${PATH}:" in
        *":${HOME}/.cargo/bin:"*) ;;
        *) PATH="${HOME}/.cargo/bin:${PATH}"; export PATH ;;
    esac
fi

# Write the PATH addition to ${DOTFILES_DIR}/.path. .path is sourced
# from .load, which is sourced from zshrc + bashrc. Each segment is
# bracketed by `# >>> <pkg> begin` / `# >>> <pkg> end` so re-running
# this hook deletes the old segment in-place before appending the
# fresh one — idempotent regardless of how many times we run.
#
# Two directories go into the rustup segment:
#
#   1. ~/.cargo/bin — every `cargo install <crate>` drops its
#      produced binary (cargo-edit, cargo-binstall, …) here.
#
#   2. The active toolchain's bin directory, resolved at hook-run
#      time via `rustup which cargo`. On macOS+brew today that's
#      ~/.rustup/toolchains/<triple>/bin/, which holds `cargo`,
#      `rustc`, `rustfmt`, `clippy-driver`, `rust-analyzer`, etc.
#
#      Why this and not the brew opt path? brew's `rustup` formula
#      only links the `rustup` binary itself; the shims it ships in
#      $(brew --prefix rustup)/bin are not on PATH. The toolchain
#      bin dir is the one location guaranteed to hold a working
#      `cargo` across every install flavor (upstream rustup-init,
#      Homebrew, distro packages) once `rustup default <channel>`
#      has provisioned the toolchain.
#
#      Tradeoff: the resolved path encodes the host triple AND the
#      active channel. Switching to `nightly`/`beta` makes the
#      baked-in path stale. Re-run this hook
#      (`update-dotfiles --only=custom-install-after`) after any
#      `rustup default <channel>` to refresh the segment.
_repo_root="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
_path_file="${_repo_root}/.path"
touch "${_path_file}"
# Strip any existing rustup segment (-i.bak for BSD sed compatibility on macOS).
sed -i.bak '/^# >>> rustup begin$/,/^# >>> rustup end$/d' "${_path_file}"
rm -f "${_path_file}.bak"

# CARGO_BIN was resolved earlier (phase 2 PATH prep); reuse it.
# dirname → the toolchain bin directory to bake into .path.
TOOLCHAIN_BIN_DIR="$(dirname "${CARGO_BIN}")"

{
    cat <<'STATIC'
# >>> rustup begin
[ -d "${HOME}/.cargo/bin" ] && case ":${PATH}:" in
    *":${HOME}/.cargo/bin:"*) ;;
    *) PATH="${HOME}/.cargo/bin:${PATH}"; export PATH ;;
esac
STATIC
    # Toolchain bin dir baked in as an absolute path. ${PATH} stays
    # literal via backslash escaping; ${TOOLCHAIN_BIN_DIR} expands now.
    cat <<EOF
[ -d "${TOOLCHAIN_BIN_DIR}" ] && case ":\${PATH}:" in
    *":${TOOLCHAIN_BIN_DIR}:"*) ;;
    *) PATH="${TOOLCHAIN_BIN_DIR}:\${PATH}"; export PATH ;;
esac
EOF
    echo "# >>> rustup end"
} >> "${_path_file}"

unset _repo_root _path_file TOOLCHAIN_BIN_DIR

# ----------------------------------------------------------------------
# Phase 2 — cargo crates
# ----------------------------------------------------------------------

if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo still unresolvable after PATH update — skipping CARGO_CRATES"
    exit 0
fi

# `cargo install --list` prints lines like `cargo-edit v0.13.0:` for
# each installed crate followed by indented binary entries. We just
# need the crate names — first field on non-indented lines.
_installed_crates() {
    cargo install --list 2>/dev/null | awk '/^[^[:space:]]/ {sub(/:$/,"",$1); print $1}'
}

_is_installed() {
    _installed_crates | grep -qx "$1"
}

_install_one() {
    local crate="$1"
    if _is_installed "${crate}"; then
        return 0
    fi
    echo "==> cargo install ${crate}"
    if [ "${DRY_RUN:-0}" = "1" ]; then
        return 0
    fi
    # Prefer binstall once it's available — much faster than building
    # from source. Fall back to source build if binstall doesn't have
    # a release for the host triple.
    if command -v cargo-binstall >/dev/null 2>&1 && [ "${crate}" != "cargo-binstall" ]; then
        cargo binstall --no-confirm --locked "${crate}" \
            || cargo install --locked "${crate}"
    else
        cargo install --locked "${crate}"
    fi
}

for crate in "${CARGO_CRATES[@]}"; do
    _install_one "${crate}"
done
