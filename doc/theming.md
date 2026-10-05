---
source: (cross-cutting)
maintainer: raxetul@gmail.com
claude-rule: "Keep this file in sync whenever a theme file under configurations/themes/ or its consumer config is touched."
---

# Theming — Catppuccin Mocha across the terminal stack

Most of the terminal stack uses one palette. When you change between apps, the colors stay the same. This page
shows the palette, where each color is set, and which module uses it. It also lists the two apps that do not use
the palette on purpose (see "Intentional exceptions" below).

## Palette

Reference: <https://github.com/catppuccin/palette>. The repo uses only Mocha. Phase 4 removed the other three
flavours (frappe, latte, macchiato).

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
| tmux           | `catppuccin/tmux` plugin + flavour selector | `configurations/themes/tmux/catppuccin-latte.conf` (see exception below) |
| Starship       | `palette = 'catppuccin_mocha'` | `configurations/starship/starship.toml` |
| Vim / Neovim   | `colorscheme catppuccin_mocha` | `configurations/vim/vimrc` |
| bat            | `theme = "Catppuccin-mocha"` (tmTheme symlinked) | `configurations/themes/bat/Catppuccin-mocha.tmTheme` |
| delta          | `[include] path = …catppuccin.gitconfig` (wired in Phase 7) | `configurations/themes/delta/catppuccin.gitconfig` |
| fzf            | `FZF_DEFAULT_OPTS --color=…` exported from a shell script | `configurations/themes/fzf/catppuccin-mocha.sh` |
| eza            | `EZA_COLORS` env exported from a shell script | `configurations/zsh/exports.sh` (mirrors `configurations/themes/eza/catppuccin-mocha.yml`) |
| zsh syntax-hl  | `ZSH_HIGHLIGHT_STYLES` overrides | `configurations/zsh/zshrc` |
| man / less     | `MANPAGER` pipes through bat | `configurations/zsh/exports.sh` |
| dunst          | per-urgency colors in dunstrc | `configurations/dunst/dunstrc` |
| Waybar         | CSS variables in `style.css` (Phase 9) | `configurations/waybar/style.css` |

## Intentional exceptions

Two apps do not use the Catppuccin Mocha palette above, on purpose:

| App | Flavour/theme | Why |
| --- | --- | --- |
| tmux | Catppuccin **Latte** (light) | a light-background status bar is legible against the surrounding dark panes — `configurations/themes/tmux/catppuccin-latte.conf` |
| Claude Code | **Atom One Dark** (`custom:one-dark`) | Claude Code runs inside a [herdr](https://herdr.dev) pane, and herdr's own theme is already `one-dark` (`configurations/herdr/config.toml`); giving Claude Code the same palette avoids a visual jolt between the pane chrome and the CLI running inside it |

## Claude Code — One Dark theme

The Claude Code `theme` setting accepts a built-in enum value or a string that matches `^custom:.*`. A custom
string points to a JSON file at `~/.claude/themes/<slug>.json`. This repo has that file at
`configurations/themes/claude/one-dark.json`. `scripts/symlinks.sh` (`COMMON_LINKS`) links it into place.
`configurations/claude/settings.json` selects it with `"theme": "custom:one-dark"`.

**Schema** (checked against the official docs, not guessed — see
<https://code.claude.com/docs/en/terminal-config#create-a-custom-theme>):

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Display label in `/theme` |
| `base` | string | Built-in preset to inherit from: `dark`, `light`, `dark-daltonized`, `light-daltonized`, `dark-ansi`, `light-ansi` |
| `overrides` | object | Sparse map of token name → color. Tokens not listed fall through to `base` |

A color value can be `#rrggbb`, `#rgb`, `rgb(r,g,b)`, `ansi256(n)`, or `ansi:<name>`.

**🟡 Important limitation — you cannot override the code-block syntax highlighting with a token.** The `overrides`
schema covers only the UI chrome. It covers the brand accent, the status colors (`success`/`error`/`warning`), the
mode-indicator borders, the diff backgrounds, and a few fullscreen, usage-meter, and subagent colors. There is no
`keyword`, `string`, `number`, `function`, `type`, or `operator` token.

The Claude Code binary has a fixed map from highlight.js scopes to ANSI-SGR codes. This map colors the fenced code
blocks in Claude replies. The check used `strings` on the installed binary at
`~/.local/share/claude/versions/2.1.252`. It contains the literal hljs scope names `keyword`, `built_in`,
`literal`, `title.function`, `title.class`, `attr`, `operator`, `punctuation`, and others. They are next to the
`diffAdded` and `diffRemoved` token names. The terminal draws this ANSI-SGR output with **its own 16-color ANSI
palette**. Claude does not set the color. To change the code-block colors, change the terminal emulator (here,
herdr). Do not change this theme file.

herdr has a built-in `one-dark` theme (`theme.name = "one-dark"` in `configurations/herdr/config.toml`). The check
used `strings` on the herdr binary. The binary lists this theme with other full ANSI-palette color schemes, such as
`catppuccin`, `dracula`, `nord`, and `gruvbox`. If that theme sets the ANSI palette to Atom One Dark values, code
blocks already show One Dark colors through the terminal. This does not depend on any Claude Code setting.

**This repo could not verify the exact ANSI hex values of herdr.** herdr is a compiled binary, and it has no theme
JSON that you can read. If the code-block colors still look wrong after this change, check the herdr palette. Do
not check Claude Code.

This theme file controls these items reliably: the Claude Code accent color, the success, error, and warning
text, the mode-indicator borders (plan mode, auto-accept, bash mode), and the diff line backgrounds and word
highlights. The file sets them to Atom One Dark colors. The Claude chrome then matches the pane around it.

**Palette used** (checked against the upstream [`atom/one-dark-syntax`](https://github.com/atom/one-dark-syntax)
source). Each hex below was recomputed from the HSL variables in `colors.less` of that repo, and it matches
exactly:

| Role | Hex | Source variable |
| --- | --- | --- |
| background | `#282c34` | `hsl(220, 13%, 18%)` |
| foreground | `#abb2bf` | `@mono-1` |
| comment grey | `#5c6370` | `@mono-3` |
| red | `#e06c75` | `@hue-5` |
| green | `#98c379` | `@hue-4` |
| yellow | `#e5c07b` | `@hue-6-2` |
| blue | `#61afef` | `@hue-2` |
| magenta | `#c678dd` | `@hue-3` |
| cyan | `#56b6c2` | `@hue-1` |

The four diff-background tokens (`diffAdded`, `diffRemoved`, `diffAddedDimmed`, `diffRemovedDimmed`) are **not**
upstream values. They are blends of green or red with the background color, at 20% and 10%. This repo made them.
A full green or red color would be too strong behind the diff text. `diffAddedWord` and `diffRemovedWord` use the
full green and red, because they mark only small word-level changes.

## How to change a color

1. Edit the palette entry in the source file (e.g. fzf colors → edit
   `configurations/themes/fzf/catppuccin-mocha.sh`).
2. Reload the app that uses the file. These are the reload commands:
   - shell-sourced files: `exec $SHELL -l` (or `reload`).
   - tmux: `<prefix> r` (binding in tmux.conf) or `tmux source-file ~/.config/tmux/tmux.conf`.
   - dunst: `dunst --reload` or restart the service.
   - bat: `bat cache --build` (driven by `scripts/update-dotfiles` and
     the `setup.sh` plugin-bootstrap step).
3. If `configurations/zsh/exports.sh` sets the color (env vars such as `EZA_COLORS` and `MANPAGER`), open a new
   shell.

## Related

- `configurations/zsh/exports.sh` — sets `MANPAGER`, so the whole pager stack uses the bat palette. It also sets
  `EZA_COLORS`.
- `configurations/themes/eza/catppuccin-mocha.yml` — this YML file is the reference that a person can read.
  `exports.sh` exports the real `EZA_COLORS` value. The session environment gets it without an extra source step.
- `configurations/tmux/tmux.conf` — TPM pins the catppuccin/tmux plugin. The file sets the flavour selector before
  TPM sources the plugin file.
- `configurations/themes/claude/one-dark.json` — the Claude Code custom theme file. See "Claude Code — One Dark
  theme" above.
- `configurations/herdr/config.toml` — sets the `one-dark` theme of herdr. This theme sets the syntax colors of the
  Claude Code code blocks.
