#!/usr/bin/env sh
# scripts/dotfiles-dir.sh — canonical DOTFILES_DIR resolution, sourced by
# every script that needs a repo-root default instead of duplicating the
# expression (previously copy-pasted across half a dozen files).
#
# Order: explicit ${DOTFILES_DIR} env var > /opt/dotfiles (the shared,
# root:dotfiles-owned install) > ${HOME}/gel-ort/dotfiles (a plain dev
# checkout, or a machine that never migrated to /opt/dotfiles).
#
# The two rc files (configurations/{zsh,bash}/rc) are the one place this
# is deliberately duplicated instead of sourced: at shell startup nothing
# is known yet about where the repo lives, so there is no path to source
# this file FROM. Keep that inline copy in sync with this one by hand.
#
# POSIX sh — sourced from bash scripts and from install.sh (which runs
# under plain `sh` before anything is installed).
if [ -z "${DOTFILES_DIR:-}" ]; then
    if [ -d /opt/dotfiles ]; then
        DOTFILES_DIR=/opt/dotfiles
    else
        DOTFILES_DIR="${HOME}/gel-ort/dotfiles"
    fi
fi
export DOTFILES_DIR
