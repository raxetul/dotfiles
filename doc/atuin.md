---
source: configurations/atuin/config.toml
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Keep this file in sync whenever configurations/atuin/config.toml changes."
---

# atuin — encrypted, fuzzy shell history

Replaces the old zsh-histdb + `HISTORY_IGNORE` regex setup. Runs
local-only (`auto_sync = false`) — nothing leaves the machine.

## Policy: no surface may HIDE history

Three different UI surfaces read the same local history DB
(`~/.local/share/atuin/history.db`). Ctrl+R and the grey suggestion are
**global** — a command typed in one tab is visible from every other
tab/session/host. The ↑ key is the one deliberate narrowing, and it is only
allowed because Ctrl+R stays global behind it: nothing ↑ omits is actually
lost.

```mermaid
flowchart LR
    DB[(atuin history.db<br/>local, encrypted)]

    CtrlR["Ctrl+R<br/>atuin search -i<br/>GLOBAL — everything"] -->|reads| DB
    UpKey["↑ up-arrow<br/>--shell-up-key-binding<br/>SESSION+ — mine first"] -->|reads| DB
    Suggest["grey autosuggestion<br/>zsh-autosuggestions strategy<br/>GLOBAL"] -->|reads| DB

    classDef surface fill:#89b4fa,stroke:#1e1e2e,color:#1e1e2e
    classDef narrowed fill:#f9e2af,stroke:#1e1e2e,color:#1e1e2e
    class CtrlR,Suggest surface
    class UpKey narrowed
```

| Surface | Invocation | Config key(s) read | Value |
| --- | --- | --- | --- |
| Ctrl+R search | `atuin search -i` | `filter_mode` | `"global"` |
| Up-arrow recall | `atuin search -i --shell-up-key-binding` | `filter_mode_shell_up_key_binding` | `"session-preload"` |
| Grey autosuggestion | `_zsh_autosuggest_strategy_atuin` (from `atuin init zsh`) → `ATUIN_QUERY="$1" atuin search --cmd-only --author '$all-user' --limit 1 --search-mode prefix` | `filter_mode` (no override) | `"global"` |

### Why ↑ uses `session-preload` — and what it costs

**atuin has no session-aware ordering.** Verified in the v18.19.0 source
(`atuin-client/src/database.rs`): every search `ORDER BY` is a plain
`f.timestamp DESC`, and `smart_sort` plus the three
`search.*_score_multiplier` knobs are recency/frequency only — none of them
looks at the `session` column. So "show my commands first" cannot be done with
a sort. The only lever is a **filter**, `session-preload` (`SESSION+` in the
TUI), whose SQL is:

```sql
WHERE session = '<this session>' OR timestamp < <this session's start time>
```

Recency ordering then floats this terminal's own commands to the top, because
they are the newest rows matching. The session start time is decoded from the
UUIDv7 in `$ATUIN_SESSION`; if that value is not a v7 UUID the `OR` clause is
dropped and the mode silently degrades to plain `session` — i.e. only this
terminal's commands. Worth knowing if ↑ ever looks suspiciously empty.

**The cost.** Commands run in *other* sessions *after this one started* are
excluded from ↑. The excluded set grows with session age, and long-lived
Claude Code / herdr panes make that significant:

| Measured 2026-08-24, session started 2026-08-18 (6 days old) | Commands |
| --- | --- |
| This session's own | 324 |
| Everything predating the session | 7 591 |
| **↑ (`session-preload`) sees** | **7 915** |
| **Ctrl+R (`global`) sees** | **11 309** |
| Hidden from ↑ — 22 concurrent sessions | 3 394 (~30%) |

Those 3 394 are one Ctrl+R away. That escape hatch is the entire justification;
if `filter_mode` were ever narrowed too, this arrangement would stop being
acceptable.

**Plain `session` remains forbidden** — it drops the `OR timestamp <` clause
and hides everything older as well, which is the regression `a0b8995` fixed.
To revert, set `filter_mode_shell_up_key_binding = "global"`.

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
pattern, so every rule folds into a single `(a|b|c)` alternation.

**Deliberately NOT `setopt EXTENDED_GLOB`**: it turns `^` into a glob
operator, which breaks unquoted everyday commands like `git show HEAD^`
/ `git diff HEAD^^` (they fail with "no matches found" — measured, not
assumed: `zsh -f -c 'setopt extended_glob; eval "print -r -- HEAD^"'`
reproduces it). `(a|b|c)` alternation works without EXTENDED_GLOB, so
the one rule that used to need `#` (zero-or-more repetition, for
`api[-_]#key*`) is spelled instead as an explicit alternation —
`(apikey*|api-key*|api_key*)` — with no repetition operator at all.

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
| `^api[-_]?key` | `(apikey*\|api-key*\|api_key*)` | regex `?` (0-or-1 on `[-_]`) has no plain-glob equivalent, so it's spelled out as an explicit alternation instead of the EXTENDED_GLOB-only `#` (0-or-more) operator |
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
