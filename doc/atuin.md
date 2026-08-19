---
source: configurations/atuin/config.toml
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Keep this file in sync whenever configurations/atuin/config.toml changes."
---

# atuin — encrypted, fuzzy shell history

Replaces the old zsh-histdb + `HISTORY_IGNORE` regex setup. Runs
local-only (`auto_sync = false`) — nothing leaves the machine.

## Policy: no surface is session-scoped

Three different UI surfaces read the same local history DB
(`~/.local/share/atuin/history.db`). All three are pinned to
**global** scope, so a command typed in one tab/session is visible
from every other tab/session/host — never just the one it was typed in.

```mermaid
flowchart LR
    DB[(atuin history.db<br/>local, encrypted)]

    CtrlR["Ctrl+R<br/>atuin search -i"] -->|reads| DB
    UpKey["↑ up-arrow<br/>atuin search -i --shell-up-key-binding"] -->|reads| DB
    Suggest["grey autosuggestion<br/>zsh-autosuggestions strategy"] -->|reads| DB

    classDef surface fill:#89b4fa,stroke:#1e1e2e,color:#1e1e2e
    class CtrlR,UpKey,Suggest surface
```

| Surface | Invocation | Config key(s) read | Value |
| --- | --- | --- | --- |
| Ctrl+R search | `atuin search -i` | `filter_mode` | `"global"` |
| Up-arrow recall | `atuin search -i --shell-up-key-binding` | `filter_mode_shell_up_key_binding` | `"global"` |
| Grey autosuggestion | `_zsh_autosuggest_strategy_atuin` (from `atuin init zsh`) → `ATUIN_QUERY="$1" atuin search --cmd-only --author '$all-user' --limit 1 --search-mode prefix` | `filter_mode` (no override) | `"global"` |

## TUI height: inline vs alternate screen

Measured (query-layer innocent: atuin p50=20ms/max=110ms, starship 30ms, no
sqlite lock): the ↑-key delay traced to `inline_height_shell_up_key_binding`
defaulting to `0` (full alternate-screen TUI), while Ctrl+R's
`inline_height` already defaulted to `40` (inline). The alternate-screen
handoff is what's visible as lag under ghostty+herdr. Both are now pinned
to the same inline value so ↑ and Ctrl+R behave identically:

| Key | Value | Surface |
| --- | --- | --- |
| `inline_height` | `40` | Ctrl+R |
| `inline_height_shell_up_key_binding` | `40` | ↑ key |

Two extra keys close off the ways search scope could otherwise narrow:

| Key | Value | Why |
| --- | --- | --- |
| `workspaces` | `false` | Disables workspace-scoped filtering (limiting to the current git repo tree) entirely. |
| `[search].filters` | `["global"]` | Only `"global"` is enabled as a cycle-able filter mode, so no keybinding (e.g. the ctrl-r cycle key) can switch search into `session`, `directory`, `host`, `workspace`, or `session-preload` scoping. |

`YOU SHOULD VERIFY` — the filter-mode value list (`global`, `host`,
`session`, `session-preload`, `directory`, `workspace`) and the
`[search].filters` key come from `atuin default-config` on atuin
18.18.1; a future atuin release could add or rename modes.

## Recording-time filter (separate from search scope)

`history_filter` is evaluated when a command is **saved**, not when
it's searched — it never makes search session-scoped, it just keeps
noise/secrets out of the DB in the first place:

```mermaid
flowchart LR
    CMD[command typed] --> F{matches\nhistory_filter regex?}
    F -->|yes| DROP[not recorded]
    F -->|no| DB[(history.db)]
```

Current patterns (leading-token guards for common secret shapes, plus
the two noisiest commands so they don't drown out signal): `^aws `,
`^secret`, `^password`, `^token`, `^api[-_]?key`,
`^export .*(SECRET|TOKEN|API|KEY|PASSWORD|PASS)=`, `^pass `, `^cat `,
`^ls$`, `^ls .*`.

## Grey autosuggestion: atuin-only, no strategy fallback

`atuin init zsh` sets `ZSH_AUTOSUGGEST_STRATEGY` by *prepending* its own
`atuin` strategy in front of whatever was already set — if
zsh-autosuggestions' default (`history`) was already in place, the result
is `(atuin history)`. `scripts/init-load` overrides this explicitly right
after `eval "$(atuin init zsh)"`:

```sh
ZSH_AUTOSUGGEST_STRATEGY=(atuin)
```

Trade-off (deliberate): if atuin is ever unavailable, the grey suggestion
simply doesn't appear — no silent fallback to plain `history`-based
suggestions, which would read `~/.zsh_history` outside atuin's filtering.

## `HISTORY_IGNORE` (zsh): recall-time mirror of `history_filter`

`history_filter` (above) only stops atuin from *recording* a command.
`~/.zsh_history` still records independently (`setopt` history options
aren't touched by atuin), so `scripts/init-load` sets zsh's own
`HISTORY_IGNORE` to a glob translation of the same rules, applied to
`↑`/`history` on that file too. zsh's `HISTORY_IGNORE` takes **one**
pattern, so every rule folds into a single `(a|b|c)` alternation, and
`setopt EXTENDED_GLOB` is required for the `#` (zero-or-more) operator
used below.

| `history_filter` regex | `HISTORY_IGNORE` glob | Why the difference |
| --- | --- | --- |
| `^ls$` | `ls` | glob match is whole-string already, no anchors needed |
| `^ls .*` | `ls *` | `.*` (regex) → `*` (glob), both "anything after" |
| `^cat ` | `cat *` | trailing-space token → literal + `*` |
| `^aws ` | `aws *` | same |
| `^pass ` | `pass *` | same |
| `^secret` | `secret*` | prefix match either way |
| `^password` | `password*` | prefix match either way |
| `^token` | `token*` | prefix match either way |
| `^api[-_]?key` | `api[-_]#key*` | regex `?` (0-or-1) has no glob equivalent — `#` (0-or-more) is the closest, slightly looser |
| `^export .*(SECRET\|TOKEN\|API\|KEY\|PASSWORD\|PASS)=` | `export *(SECRET\|TOKEN\|API\|KEY\|PASSWORD\|PASS)=*` | regex `(a\|b)` alternation is native to zsh glob too — no translation needed |

## Daemon

```toml
[daemon]
enabled = true
autostart = true
```

The daemon speeds up sync/search but doesn't change scope — the
`filter_mode`/`workspaces`/`[search].filters` keys above are what
govern that.
