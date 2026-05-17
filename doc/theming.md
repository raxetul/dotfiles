---
nix-file: (cross-cutting)
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Keep this file in sync whenever a theme file under configurations/themes/ or its consumer module is touched."
---

# Theming — Catppuccin Mocha across the terminal stack

The whole terminal stack runs on a single palette so context-switching
between apps doesn't trigger a visual jolt. This page documents the
palette, where each color lives, and which module consumes it.

## Palette

Reference: <https://github.com/catppuccin/palette>. Only Mocha is used —
the other three flavours (frappe, latte, macchiato) were trimmed in
Phase 4.

| Role        | Hex       | Used as |
| ----------- | --------- | ------- |
| base        | `#1e1e2e` | terminal bg, fzf bg, dunst bg |
| mantle      | `#181825` | accent surfaces |
| crust       | `#11111b` | starship segments (fg on red/peach) |
| surface0    | `#313244` | borders, separators |
| surface2    | `#585b70` | dim text |
| text        | `#cdd6f4` | foreground |
| subtext0    | `#a6adc8` | muted foreground |
| overlay1    | `#7f849c` | comments, line numbers |
| red         | `#f38ba8` | errors, dangerous urgency |
| peach       | `#fab387` | directories segment |
| yellow      | `#f9e2af` | git, sizes |
| green       | `#a6e3a1` | commands, success, added lines |
| sapphire    | `#74c7ec` | docker context |
| lavender    | `#b4befe` | time, dunst frame |
| pink        | `#f5c2e7` | symlinks |
| mauve       | `#cba6f7` | prompts, headers |

## Per-app mapping

| App | Where the palette is set | File |
| --- | --- | --- |
| Ghostty (term) | `theme = catppuccin-mocha` (ships in-tree) | `configurations/ghostty/config` |
| tmux           | `catppuccin/tmux` plugin + flavour selector | `configurations/themes/tmux/catppuccin-mocha.conf` |
| Starship       | `palette = 'catppuccin_mocha'` | `configurations/starship/starship.toml` |
| Vim / Neovim   | `colorscheme catppuccin_mocha` | `configurations/vim/vimrc` |
| bat            | `theme = "Catppuccin-mocha"` (tmTheme symlinked) | `configurations/themes/bat/Catppuccin-mocha.tmTheme` |
| delta          | `[include] path = …catppuccin.gitconfig` (wired in Phase 7) | `configurations/themes/delta/catppuccin.gitconfig` |
| fzf            | `FZF_DEFAULT_OPTS --color=…` exported from a shell script | `configurations/themes/fzf/catppuccin-mocha.sh` |
| eza            | `EZA_COLORS` env (sessionVariable) | `home/modules/eza.nix` (mirrors `configurations/themes/eza/catppuccin-mocha.yml`) |
| zsh syntax-hl  | `ZSH_HIGHLIGHT_STYLES` overrides | `home/modules/zsh.nix` (initContent) |
| man / less     | `MANPAGER` pipes through bat | `home/modules/bat.nix` |
| dunst          | per-urgency colors in dunstrc | `configurations/dunst/dunstrc` |
| Waybar         | CSS variables in `style.css` (Phase 9) | `configurations/waybar/style.css` |

## How to change a color

1. Edit the palette entry in the source file (e.g. fzf colors → edit
   `configurations/themes/fzf/catppuccin-mocha.sh`).
2. Reload the consuming app. Most reload paths:
   - shell-sourced files: `exec $SHELL -l` (or `reload`).
   - tmux: `<prefix> r` (binding in tmux.conf) or `tmux source-file ~/.config/tmux/tmux.conf`.
   - dunst: `dunst --reload` or restart the service.
   - bat: `bat cache --build` (driven automatically by home.activation).
3. If the color lives in a `home/modules/*.nix` (e.g. `EZA_COLORS`), a
   `home-manager switch` is required — that's the trade-off for keeping
   the value in the Nix store.

## Related

- `home/modules/bat.nix` — also sets `MANPAGER` and `LESS` so the entire
  pager stack picks up the bat palette.
- `home/modules/eza.nix` — the YML file is the reference; the actual
  `EZA_COLORS` value lives in the module so it ends up in the session
  environment without an extra source step.
- `home/modules/tmux.nix` — pinning of the catppuccin/tmux plugin happens
  via `programs.tmux.plugins`; the flavour selector is set in the
  per-plugin `extraConfig` so it runs before the plugin file is sourced.
