---
status: source-of-truth
maintainer: raxetul@gmail.com
claude-rule: "herdr's keybindings are documented here and MUST be kept in lockstep with configurations/herdr/config.toml. The 'no sticky prefix mode' finding below is a verified absence — do not re-litigate it without re-checking `herdr --default-config`."
---

# herdr — workspace manager keybindings

herdr places every parallel Claude session (see
[claude-worktrees.md](claude-worktrees.md)). Its config is in
`configurations/herdr/config.toml`. `scripts/symlinks.sh` symlinks it to
`~/.config/herdr/config.toml`.

This file is about **keybindings**. To upgrade the running herdr server, read
[herdr-upgrade.md](herdr-upgrade.md). A new binary alone does not upgrade the
server. That file explains why.

## The problem this config solves

By default, herdr puts every command behind a tmux-style prefix (`ctrl+b`). To
move between panes, tabs and workspaces, you must press two keys each time.
tmux is the other multiplexer on this machine. It uses the opposite setup: bare
`ctrl+h/j/k/l` move between panes. This difference made navigation difficult.

```
┌─ keystroke ─┐
│             ├─→ herdr binding?  ──yes──→ herdr acts   (the pane NEVER sees it)
│             └─────────────────────no───→ forwarded to the focused pane
└─────────────┘                                          (shell / vim / Claude)
```

herdr checks its own bindings first. For this reason, a herdr binding always
wins over an application binding. If herdr does not bind a key, the application
keeps it.

## The layer model

| Layer | Modifier | Owns |
| --- | --- | --- |
| inner — tmux (inside a pane) | `ctrl` | `ctrl+h/j/k/l` → panes, vim-aware |
| outer — herdr (around the pane) | `ctrl+alt` | panes, tabs, workspaces |

Use one rule: add `alt` to go one layer out.

## Bindings

| Action | Binding | Verified |
| --- | --- | --- |
| `goto` — enter navigate mode | `ctrl+alt+g` | 🔴 **does not fire** |
| `focus_pane_left/down/up/right` | `ctrl+alt+←/↓/↑/→` | 🟡 awaiting test (was `h/j/k/l`, dead) |
| `next_tab` / `previous_tab` | `ctrl+alt+n` / `ctrl+alt+p` | 🟡 untested |
| `next_workspace` / `previous_workspace` | `ctrl+alt+.` / `ctrl+alt+,` | 🟡 untested |
| `switch_tab` (indexed) | `ctrl+alt+1..9` | 🟡 untested |

> 🔴 **The `ctrl+alt` layer does not reach herdr.** `herdr server
> reload-config` reports `status: applied` with zero diagnostics. This shows
> that herdr accepts the bindings. The keys do not arrive at herdr. The root
> cause is still open. See "Diagnosing an undelivered chord" below. An earlier
> revision of this table said that `ctrl+alt+g` worked. That was wrong. This
> revision corrects it.

herdr does not bind `next_workspace` / `previous_workspace` by default. The
other actions move off the prefix.

All other actions keep their default prefix binding. Examples: `prefix+c` for a
new tab, `prefix+v` / `prefix+minus` for splits, `prefix+z` for zoom, and
`prefix+r` for resize mode. To see the full list, run `herdr --default-config`.

## Two findings to keep in mind

**herdr has no sticky/repeat prefix mode.** The whole of `herdr --default-config`
was searched for `sticky` / `repeat` / `remain`. There were zero hits. The
herdr prefix is single-shot. The substitute is the direct bindings above. They
skip the prefix, so the prefix does not need to stay active.

**`ctrl+alt+space` does not work on macOS.** It is the system default for
*Select next input source*. The OS takes it before Ghostty or herdr can see it.
For this reason, `goto` is `ctrl+alt+g`. The other candidate keys
(`h/j/k/l/n/p/g/,/./1-9`) were compared with the enabled macOS `ctrl+option`
hotkeys. There are no more collisions.

## Modes herdr does have

| Mode | Enter | Notes |
| --- | --- | --- |
| normal | — | keystrokes go to the focused pane |
| prefix | `ctrl+b` | single-shot, not sticky |
| navigate | `ctrl+alt+g` | sidebar selection UI with a cursor; `h/j/k/l` move panes, arrows move workspaces; `esc` exits |
| resize | `prefix+r` | |

Navigate mode is a **selection overlay**. It is not an invisible vim-style
normal mode. You can configure its movement keys with `navigate_pane_*` and
`navigate_workspace_*`. They are independent of `focus_pane_*`.

## 🔴 Do not bind bare `tab` / `shift+tab`

These keys look good for tab switching, but they cause problems. herdr takes a
direct binding before the pane sees it. Then shell completion and vim stop
working in **every** pane. Claude Code's own `shift+tab` (permission-mode
cycling) also stops working. Use the `ctrl+alt` layer instead.

## Applying and reverting

```sh
herdr server reload-config   # apply without restarting the session
herdr config reset-keys      # escape hatch: back up config.toml, drop custom keys
```

The terminal decides how it handles alt-modified chords. herdr's own docs give
this warning.

## Diagnosing an undelivered chord

When a binding does not fire, find which of the three layers loses it. Do the
checks in this order. Each check rules out one cause:

| # | Check | Rules out |
| --- | --- | --- |
| 1 | Which physical Option key? `configurations/ghostty/config` sets `macos-option-as-alt = left`, so **only the LEFT Option key produces Alt**. Right Option emits composed characters instead. | the most common false alarm |
| 2 | What bytes actually arrive? Run `cat -v`, press the chord, read the escape sequence. Nothing printed → the terminal/OS ate it. `^[^G` (ESC + ctrl+G) → it arrived and herdr is the one not matching it. | terminal vs herdr |
| 3 | Does the OS own it? macOS system shortcuts win before any terminal. `ctrl+alt+space` is *Select next input source*; `ctrl+↑` / `ctrl+↓` are Mission Control / Application Windows; `ctrl+cmd+←/→` move spaces. Read the live list with `defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys`. | OS-level capture |

### Letters vs arrows — why the encoding matters

The terminal sends a modified **letter** as an ESC-prefixed byte (`ctrl+alt+g`
→ `ESC` `0x07`). The terminal makes that ESC only if `macos-option-as-alt`
allows it. This setting is `left` here. The **right** Option key never produces
Alt. The terminal sends a modified **arrow** as a CSI sequence. The modifier is
a numeric parameter in that sequence (`ctrl+alt+left` → `ESC [ 1 ; 7 D`). This
does not depend on that setting.

For this reason, the pane-focus bindings moved from `h/j/k/l` to the arrow
keys. The letter layer did not work. `goto`, the tab bindings and the workspace
bindings are still on `ctrl+alt+<letter>`. They are still suspect. Suppose the
arrows work and the letters do not. Then the encoding difference is the
confirmed cause. In that case, move the rest to function keys.

herdr's own guidance names the most reliable direct bindings. Use them as a
fallback: function keys (`f1`–`f8`), or `ctrl+<letter>` chords that tmux does
not already use.
