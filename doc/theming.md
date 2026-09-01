---
source: (cross-cutting)
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Keep this file in sync whenever a theme file under configurations/themes/ or its consumer config is touched."
---

# Theming — Catppuccin Mocha across the terminal stack

Most of the terminal stack runs on a single palette so context-switching
between apps doesn't trigger a visual jolt. This page documents the
palette, where each color lives, which module consumes it, and the two
apps that deliberately opt out (see "Intentional exceptions" below).

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

Two apps deliberately sit outside the Catppuccin Mocha palette above:

| App | Flavour/theme | Why |
| --- | --- | --- |
| tmux | Catppuccin **Latte** (light) | a light-background status bar is legible against the surrounding dark panes — `configurations/themes/tmux/catppuccin-latte.conf` |
| Claude Code | **Atom One Dark** (`custom:one-dark`) | Claude Code runs inside a [herdr](https://herdr.dev) pane, and herdr's own theme is already `one-dark` (`configurations/herdr/config.toml`); giving Claude Code the same palette avoids a visual jolt between the pane chrome and the CLI running inside it |

## Claude Code — One Dark theme

Claude Code's `theme` setting accepts a built-in enum value or a string
matching `^custom:.*`, which resolves to a JSON file at
`~/.claude/themes/<slug>.json`. This repo ships that file at
`configurations/themes/claude/one-dark.json`, symlinked in by
`scripts/symlinks.sh` (`COMMON_LINKS`), and `configurations/claude/settings.json`
selects it via `"theme": "custom:one-dark"`.

**Schema** (confirmed against the official docs, not guessed — see
<https://code.claude.com/docs/en/terminal-config#create-a-custom-theme>):

| Field | Type | Meaning |
| --- | --- | --- |
| `name` | string | Display label in `/theme` |
| `base` | string | Built-in preset to inherit from: `dark`, `light`, `dark-daltonized`, `light-daltonized`, `dark-ansi`, `light-ansi` |
| `overrides` | object | Sparse map of token name → color. Tokens not listed fall through to `base` |

Color values accept `#rrggbb`, `#rgb`, `rgb(r,g,b)`, `ansi256(n)`, or
`ansi:<name>`.

**🟡 Important limitation — code-block syntax highlighting is *not* one of
the overridable tokens.** The `overrides` schema only covers UI chrome:
brand accent, status colors (`success`/`error`/`warning`), mode-indicator
borders, diff backgrounds, and a handful of fullscreen/usage-meter/subagent
colors — there is no `keyword`/`string`/`number`/`function`/`type`/`operator`
token. Fenced code blocks in Claude's replies are colored by a fixed
highlight.js-scope → ANSI-SGR mapping baked into the Claude Code binary
(confirmed via `strings` on the installed binary at
`~/.local/share/claude/versions/2.1.252`, which contains the literal hljs
scope names `keyword`, `built_in`, `literal`, `title.function`,
`title.class`, `attr`, `operator`, `punctuation`, etc. right next to the
`diffAdded`/`diffRemoved` token names). That ANSI-SGR output is rendered
using **the terminal's own 16-color ANSI palette**, not a Claude-side
color — so the actual lever for code-block colors is the terminal
emulator (here, herdr), not this theme file.

herdr already ships a built-in `one-dark` theme (`theme.name = "one-dark"`
in `configurations/herdr/config.toml`, confirmed via `strings` on the
herdr binary, which lists it alongside other known full ANSI-palette
color schemes such as `catppuccin`, `dracula`, `nord`, `gruvbox`). If that
theme redefines the ANSI palette to Atom One Dark values, code blocks
already render in One Dark through the terminal, independent of any
Claude Code setting. **This repo could not independently verify herdr's
exact ANSI hex values** (herdr ships as a compiled binary with no
inspectable theme JSON) — if code-block colors still look wrong after
this change, check herdr's palette next, not Claude Code's.

What this theme file *does* reliably control: Claude Code's own accent
color, success/error/warning text, mode-indicator borders (plan mode,
auto-accept, bash mode), and diff line backgrounds/word-highlights —
recolored to Atom One Dark so Claude's own chrome matches the pane
around it.

**Palette used** (verified against the upstream
[`atom/one-dark-syntax`](https://github.com/atom/one-dark-syntax) source —
each hex below was recomputed from that repo's `colors.less` HSL
variables and matches exactly):

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

The four diff-background tokens (`diffAdded`, `diffRemoved`,
`diffAddedDimmed`, `diffRemovedDimmed`) are **not** upstream values —
this repo's own 20%/10% blends of green/red toward the background color,
so a saturated green/red doesn't overwhelm the diff text. `diffAddedWord`
/ `diffRemovedWord` use the pure green/red instead, since those are small
word-level highlights.

## How to change a color

1. Edit the palette entry in the source file (e.g. fzf colors → edit
   `configurations/themes/fzf/catppuccin-mocha.sh`).
2. Reload the consuming app. Most reload paths:
   - shell-sourced files: `exec $SHELL -l` (or `reload`).
   - tmux: `<prefix> r` (binding in tmux.conf) or `tmux source-file ~/.config/tmux/tmux.conf`.
   - dunst: `dunst --reload` or restart the service.
   - bat: `bat cache --build` (driven by `scripts/update-dotfiles` and
     the `setup.sh` plugin-bootstrap step).
3. If the color is set in `configurations/zsh/exports.sh` (env vars
   like `EZA_COLORS`, `MANPAGER`), open a new shell to pick it up.

## Related

- `configurations/zsh/exports.sh` — sets `MANPAGER` so the entire
  pager stack picks up the bat palette, plus `EZA_COLORS`.
- `configurations/themes/eza/catppuccin-mocha.yml` — the YML file is
  the human-readable reference; the actual `EZA_COLORS` value is
  exported from `exports.sh` so it ends up in the session
  environment without an extra source step.
- `configurations/tmux/tmux.conf` — pinning of the catppuccin/tmux
  plugin happens via TPM; the flavour selector is set before TPM
  sources the plugin file.
- `configurations/themes/claude/one-dark.json` — the Claude Code custom
  theme file, see "Claude Code — One Dark theme" above.
- `configurations/herdr/config.toml` — sets herdr's own `one-dark` theme,
  which is the actual lever for Claude Code's code-block syntax colors.
