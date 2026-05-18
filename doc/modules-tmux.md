---
nix-file: home/modules/tmux.nix
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the nix file changes."
---
# tmux

## Purpose

Tmux configured declaratively for plugin + binding state, with the
detail-heavy parts (status-bar, splits, pane-nav) sourced from
`configurations/tmux/tmux.conf`. Catppuccin Mocha via the
`catppuccin/tmux` plugin; session persistence via
`resurrect` + `continuum`.

## My preferences (why it's configured this way)

- **Prefix `C-a`.** Cleaner than the default `C-b`; doesn't
  collide with readline's start-of-line in zsh because zsh's
  binding is handled by the terminal before tmux sees the key.
- **Vi key mode.** Selection / copy-mode bindings match vim/nvim
  muscle memory.
- **`baseIndex = 1`.** Windows and panes start at 1 so the
  keyboard row matches: `<prefix> 1` is window 1, not window 2.
- **`historyLimit = 50000`.** Scrollback for hours of build
  output without runaway memory.
- **`focusEvents = true`.** Lets gitgutter / fugitive refresh
  when the surrounding tmux pane regains focus.
- **catppuccin plugin via `programs.tmux.plugins` with
  `extraConfig`.** Per-plugin `extraConfig` runs *before* the
  plugin file is sourced — the flavour selector
  (`set -g @catppuccin_flavour 'mocha'`) must be set before
  catppuccin loads.
- **Resurrect + continuum on.** Session reboot survives a host
  restart; saves every 10 minutes.
- **`extraConfig`** at the end sources
  `configurations/tmux/tmux.conf` so the rest of the bindings can
  be edited without a rebuild.

## Options enabled

- `programs.tmux.enable = true`.
- `prefix = "C-a"`, `mouse = true`, `keyMode = "vi"`,
  `baseIndex = 1`, `historyLimit = 50000`,
  `escapeTime = 10`, `terminal = "tmux-256color"`,
  `focusEvents = true`.
- `plugins`:
  - `sensible`, `yank`, `vim-tmux-navigator`.
  - `catppuccin` with `extraConfig` setting the mocha flavour and
    sourcing `configurations/themes/tmux/catppuccin-mocha.conf`.
  - `resurrect`.
  - `continuum` with `extraConfig` enabling restore + 10-minute
    interval.
- `extraConfig` sources
  `configurations/tmux/tmux.conf`.

## Related

- [configurations/tmux/tmux.conf](../configurations/tmux/tmux.conf)
  — bindings, splits, status-bar tuning.
- [configurations/themes/tmux/catppuccin-mocha.conf](../configurations/themes/tmux/catppuccin-mocha.conf)
  — palette file the plugin sources.
- [doc/theming.md](theming.md).
