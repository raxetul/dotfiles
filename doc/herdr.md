---
status: source-of-truth
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "herdr's keybindings are documented here and MUST be kept in lockstep with configurations/herdr/config.toml. The 'no sticky prefix mode' finding below is a verified absence — do not re-litigate it without re-checking `herdr --default-config`."
---

# herdr — workspace manager keybindings

herdr places every parallel Claude session (see
[claude-worktrees.md](claude-worktrees.md)). Its config lives at
`configurations/herdr/config.toml`, symlinked to `~/.config/herdr/config.toml`
by `scripts/symlinks.sh`.

## The problem this config solves

herdr ships with everything behind a tmux-style prefix (`ctrl+b` by default),
so moving between panes, tabs and workspaces costs two keystrokes each. tmux —
the other multiplexer on this machine — was already configured the opposite
way, with bare `ctrl+h/j/k/l` for panes. That asymmetry is what made navigation
feel awkward.

```
┌─ keystroke ─┐
│             ├─→ herdr binding?  ──yes──→ herdr acts   (the pane NEVER sees it)
│             └─────────────────────no───→ forwarded to the focused pane
└─────────────┘                                          (shell / vim / Claude)
```

That order is why a herdr binding always wins over an application binding — and
why binding a key herdr does not need is what lets the application keep it.

## The layer model

| Layer | Modifier | Owns |
| --- | --- | --- |
| inner — tmux (inside a pane) | `ctrl` | `ctrl+h/j/k/l` → panes, vim-aware |
| outer — herdr (around the pane) | `ctrl+alt` | panes, tabs, workspaces |

One mental model: add `alt` to go one layer out.

## Bindings

| Action | Binding | Verified |
| --- | --- | --- |
| `goto` — enter navigate mode | `ctrl+alt+g` | 🔴 **does not fire** |
| `focus_pane_left/down/up/right` | `ctrl+alt+h/j/k/l` | 🔴 j/k confirmed dead; h/l untested |
| `next_tab` / `previous_tab` | `ctrl+alt+n` / `ctrl+alt+p` | 🟡 untested |
| `next_workspace` / `previous_workspace` | `ctrl+alt+.` / `ctrl+alt+,` | 🟡 untested |
| `switch_tab` (indexed) | `ctrl+alt+1..9` | 🟡 untested |

> 🔴 **The `ctrl+alt` layer is not reaching herdr.** `herdr server
> reload-config` reports `status: applied` with zero diagnostics, so herdr
> accepts the bindings — the keys are simply not being delivered to it. Root
> cause still open; see "Diagnosing an undelivered chord" below. An earlier
> revision of this table recorded `ctrl+alt+g` as confirmed working; that was
> wrong and is corrected here.

`next_workspace` / `previous_workspace` are unbound in herdr's defaults; the
rest are moved off the prefix.

Everything not listed keeps its default prefix binding — `prefix+c` new tab,
`prefix+v` / `prefix+minus` splits, `prefix+z` zoom, `prefix+r` resize mode, and
so on. See `herdr --default-config`.

## Two findings worth not rediscovering

**There is no sticky/repeat prefix mode.** Verified by grepping the whole of
`herdr --default-config` for `sticky` / `repeat` / `remain` — zero hits. herdr's
prefix is single-shot. The substitute is the direct bindings above: skip the
prefix entirely rather than making it stick.

**`ctrl+alt+space` is unusable on macOS.** It is the system default for *Select
next input source*, so the OS swallows it before Ghostty or herdr ever sees it.
That is why `goto` is `ctrl+alt+g`. Every other candidate key
(`h/j/k/l/n/p/g/,/./1-9`) was checked against the enabled macOS `ctrl+option`
hotkeys — no further collisions.

## Modes herdr does have

| Mode | Enter | Notes |
| --- | --- | --- |
| normal | — | keystrokes go to the focused pane |
| prefix | `ctrl+b` | single-shot, not sticky |
| navigate | `ctrl+alt+g` | sidebar selection UI with a cursor; `h/j/k/l` move panes, arrows move workspaces; `esc` exits |
| resize | `prefix+r` | |

Navigate mode is a **selection overlay**, not an invisible vim-style normal
mode. Its movement keys are configurable via `navigate_pane_*` /
`navigate_workspace_*`; they are independent of `focus_pane_*`.

## 🔴 Do not bind bare `tab` / `shift+tab`

They are tempting for tab switching and they are a trap: a direct herdr binding
is consumed before the pane sees it, which would kill shell completion, vim, and
Claude Code's own `shift+tab` (permission-mode cycling) in **every** pane. Use
the `ctrl+alt` layer instead.

## Applying and reverting

```sh
herdr server reload-config   # apply without restarting the session
herdr config reset-keys      # escape hatch: back up config.toml, drop custom keys
```

Alt-modified chords are terminal-dependent — herdr's own docs flag them.

## Diagnosing an undelivered chord

When a binding does not fire, first establish **which** of the three layers is
losing it, in this order — each step rules out one:

| # | Check | Rules out |
| --- | --- | --- |
| 1 | Which physical Option key? `configurations/ghostty/config` sets `macos-option-as-alt = left`, so **only the LEFT Option key produces Alt**. Right Option emits composed characters instead. | the most common false alarm |
| 2 | What bytes actually arrive? Run `cat -v`, press the chord, read the escape sequence. Nothing printed → the terminal/OS ate it. `^[^G` (ESC + ctrl+G) → it arrived and herdr is the one not matching it. | terminal vs herdr |
| 3 | Does the OS own it? macOS system shortcuts win before any terminal. `ctrl+alt+space` is *Select next input source* — that is why `goto` is not on it. | OS-level capture |

Fallback, per herdr's own guidance on the most reliable direct bindings:
function keys (`f1`–`f8`), or `ctrl+<letter>` chords that tmux does not already
claim.
