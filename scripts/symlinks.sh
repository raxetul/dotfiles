#!/usr/bin/env bash
# symlinks.sh — install or remove the symlinks the dotfiles repo plants under $HOME.
#
# Usage:
#   scripts/symlinks.sh install           # create all symlinks (idempotent)
#   scripts/symlinks.sh uninstall         # remove only symlinks this script plants
#   scripts/symlinks.sh list              # print the active mapping
#   scripts/symlinks.sh skills-install    # same, scoped to ~/.claude/skills/* only
#   scripts/symlinks.sh skills-uninstall  # (used by scripts/claude-skills link)
#   scripts/symlinks.sh skills-list
#
# Env:
#   DOTFILES_DESKTOP=1  add Linux desktop links (waybar, dunst) on Linux
#   CLAUDE_SKILLS_DIR   remote-less claude-skills repo to link ~/.claude/skills/*
#                        from (default: ${HOME}/gel-ort/claude-skills). See
#                        doc/claude-skills.md — never a fixed skill list here,
#                        every top-level entry in that repo gets linked.
#
# Phase 3 of v3-native: replaces Home Manager's xdg.configFile / home.file
# layer. Phase 4 wires this into setup.sh.

set -euo pipefail

# When invoked from PATH (~/.scripts is a dir-symlink into the repo),
# $0 resolves under ~/.scripts/ and `dirname $0/..` would land at $HOME.
# Trust $DOTFILES_DIR (exported by configurations/{zsh,bash}/rc); fall
# back to the documented default for non-interactive contexts.
REPO_ROOT="${DOTFILES_DIR:-${HOME}/gel-ort/dotfiles}"
[ -d "${REPO_ROOT}" ] || { printf 'ERR: repo not found at %s — set DOTFILES_DIR.\n' "${REPO_ROOT}" >&2; exit 1; }

# Realized-state ledger — record each symlink we plant/remove so uninstall.sh
# can reverse the exact set. (Symlinks are also derivable from the arrays
# below; this is the audit/uninstall trail.)
# shellcheck source=scripts/dotfiles-state.sh
. "${REPO_ROOT}/scripts/dotfiles-state.sh"

# === Symlink mapping ===
# Each entry: "<src relative to REPO_ROOT>::<dst relative to $HOME>".

COMMON_LINKS=(
  "configurations/zsh/zshrc::.zshrc"
  "configurations/bash/bashrc::.bashrc"
  "configurations/starship/starship.toml::.config/starship.toml"
  "configurations/atuin/config.toml::.config/atuin/config.toml"
  "configurations/themes/bat/Catppuccin-mocha.tmTheme::.config/bat/themes/Catppuccin-mocha.tmTheme"
  "configurations/git/gitconfig::.config/git/config"
  "configurations/git/workspace.gitconfig::.config/git/workspace.gitconfig"
  "configurations/git/commit-template::.config/git/commit-template"
  "configurations/git/template/hooks/commit-msg::.config/git/template/hooks/commit-msg"
  "configurations/git/template/hooks/pre-commit::.config/git/template/hooks/pre-commit"
  "configurations/gpg/gpg.conf::.gnupg/gpg.conf"
  "configurations/vim/vimrc::.vimrc"
  "configurations/vim/ftplugin/nix.vim::.vim/ftplugin/nix.vim"
  "configurations/vim/ftplugin/go.vim::.vim/ftplugin/go.vim"
  "configurations/vim/ftplugin/yaml.vim::.vim/ftplugin/yaml.vim"
  "configurations/vim/ftplugin/python.vim::.vim/ftplugin/python.vim"
  "configurations/nvim/init.vim::.config/nvim/init.vim"
  "configurations/ghostty/config::.config/ghostty/config"
  "configurations/herdr/config.toml::.config/herdr/config.toml"
  "configurations/tmux/tmux.conf::.config/tmux/tmux.conf"
  "configurations/claude/settings.json::.claude/settings.json"
  "configurations/claude/CLAUDE.md::.claude/CLAUDE.md"
  "configurations/claude/commands::.claude/commands"
  "configurations/claude/hooks/herdr-agent-state.sh::.claude/hooks/herdr-agent-state.sh"
  "configurations/claude/hooks/herdr-workspace-guard.sh::.claude/hooks/herdr-workspace-guard.sh"
  "configurations/claude/scripts::.claude/scripts"
  "configurations/themes/claude/one-dark.json::.claude/themes/one-dark.json"
  "configurations/cargo/bin/cargo-test-tree::.cargo/bin/cargo-test-tree"
  "scripts::.scripts"
)

DARWIN_LINKS=(
  "configurations/gpg/gpg-agent.conf.darwin::.gnupg/gpg-agent.conf"
)

LINUX_LINKS=(
  "configurations/gpg/gpg-agent.conf.linux::.gnupg/gpg-agent.conf"
)

LINUX_DESKTOP_LINKS=(
  "configurations/dunst/dunstrc::.config/dunst/dunstrc"
  "configurations/waybar/config.jsonc::.config/waybar/config.jsonc"
  "configurations/waybar/style.css::.config/waybar/style.css"
)

# Claude skills live outside this repo entirely, in a remote-less local git
# repo (see doc/claude-skills.md and hard rule in configurations/claude/CLAUDE.md).
# Never a fixed array here — every top-level entry the skills repo currently
# holds gets linked, so dropping a new skill in there needs no edit to this
# script.
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-${HOME}/gel-ort/claude-skills}"

# === Helpers ===

_os() {
  case "$(uname)" in
    Darwin) echo "darwin" ;;
    Linux)  echo "linux"  ;;
    *)      echo "other"  ;;
  esac
}

# Emit "<abs-src-in-claude-skills-repo>::.claude/skills/<name>" for every
# top-level entry (skill dir or stray *.md like SKILL_ROUTER.md) currently in
# the skills repo. Absolute src (outside REPO_ROOT) so _resolve_src passes it
# through unchanged. Silently empty if the repo doesn't exist yet — setup.sh
# creates it (Step 4.5) before calling this, but `symlinks.sh list` on a bare
# checkout should not fail.
_skill_links() {
  [ -d "${CLAUDE_SKILLS_DIR}" ] || return 0
  local entry name
  for entry in "${CLAUDE_SKILLS_DIR}"/*; do
    [ -e "${entry}" ] || continue
    name="$(basename "${entry}")"
    # README.md is the skills repo's own metadata, not a skill — skip it.
    [ "${name}" = "README.md" ] && continue
    printf '%s::.claude/skills/%s\n' "${entry}" "${name}"
  done
}

# Emit the active mapping (one entry per line) for the current OS + profile.
_active_links() {
  printf '%s\n' "${COMMON_LINKS[@]}"
  case "$(_os)" in
    darwin) printf '%s\n' "${DARWIN_LINKS[@]}" ;;
    linux)
      printf '%s\n' "${LINUX_LINKS[@]}"
      if [ "${DOTFILES_DESKTOP:-0}" = "1" ]; then
        printf '%s\n' "${LINUX_DESKTOP_LINKS[@]}"
      fi
      ;;
  esac
  _skill_links
}

# Entries are normally repo-relative (resolved against REPO_ROOT); the
# skills repo sits outside REPO_ROOT, so _skill_links emits absolute paths
# instead — pass those through unchanged.
_resolve_src() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *)  printf '%s/%s\n' "${REPO_ROOT}" "$1" ;;
  esac
}

_install_one() {
  local src dst
  src="$(_resolve_src "$1")"
  dst="${HOME}/$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  if [ ! -e "$src" ]; then
    printf '  skip (missing src): %s\n' "$1" >&2
    return 0
  fi

  mkdir -p "$dst_dir"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return 0
  fi

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local backup
    backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    printf '  backup: %s -> %s\n' "$dst" "$backup" >&2
    mv "$dst" "$backup"
  fi

  ln -sfn "$src" "$dst"
  printf '  link: ~/%s\n' "$2"
  state_record symlink create "$2" "src=$1"
}

_uninstall_one() {
  local src dst
  src="$(_resolve_src "$1")"
  dst="${HOME}/$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    rm "$dst"
    printf '  removed: ~/%s\n' "$2"
    state_record symlink remove "$2" "src=$1"
  fi
}

# === Actions ===

cmd_install() {
  local suffix=""
  [ "${DOTFILES_DESKTOP:-0}" = "1" ] && suffix=" + desktop"
  printf '==> installing symlinks (%s%s)\n' "$(_os)" "$suffix"
  local links_fn="${1:-_active_links}"
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local src="${entry%%::*}"
    local dst="${entry##*::}"
    _install_one "$src" "$dst"
  done < <("$links_fn")
}

cmd_uninstall() {
  local links_fn="${1:-_active_links}"
  printf '==> removing symlinks\n'
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local src="${entry%%::*}"
    local dst="${entry##*::}"
    _uninstall_one "$src" "$dst"
  done < <("$links_fn")
}

cmd_list() {
  local links_fn="${1:-_active_links}"
  "$links_fn"
}

case "${1:-install}" in
  install)          cmd_install ;;
  uninstall)        cmd_uninstall ;;
  list)             cmd_list ;;
  # Skills-only scope: used by scripts/claude-skills link, so a skills
  # refresh never has to walk (and touch) every other dotfiles symlink.
  skills-install)   cmd_install _skill_links ;;
  skills-uninstall) cmd_uninstall _skill_links ;;
  skills-list)      cmd_list _skill_links ;;
  *)
    printf 'usage: %s [install|uninstall|list|skills-install|skills-uninstall|skills-list]\n' "$0" >&2
    exit 1
    ;;
esac
