# shellcheck shell=sh
# python.sh — POSIX aliases sourced by both bash and zsh.
# Fills only the names the platform's packages leave missing (see
# doc/packages-native.md, "Language toolchains"): a real `python`, `pip` or
# `py` from a distro package or python-launcher always wins; each alias
# appears only when the command is absent AND its target exists.
# Typically fires for: python/pip on macOS (brew has only python3/pip3),
# py on Debian/Ubuntu (no apt package for the launcher).
command -v python >/dev/null 2>&1 || { command -v python3 >/dev/null 2>&1 && alias python='python3'; }
command -v pip >/dev/null 2>&1 || { command -v pip3 >/dev/null 2>&1 && alias pip='pip3'; }
command -v py >/dev/null 2>&1 || { command -v python3 >/dev/null 2>&1 && alias py='python3'; }
