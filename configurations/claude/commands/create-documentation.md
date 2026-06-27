---
description: Generate or refresh a project's docs/ tree (Markdown + embeddable Mermaid) in one of two house styles — work (Büyütech green) or personal (turquoise).
argument-hint: "[work|personal] [topic/scope notes — optional]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls*), Bash(find*), Bash(test*), Bash(cat*), Bash(git*)
---

Generate (or refresh) documentation for the **current project** using my
standard documentation layout and one of two house styles. Argument:
`$ARGUMENTS`.

## Step 0 — resolve the style

Parse the first whitespace token of `$ARGUMENTS`:

- `work` → **Work style** (professional / Büyütech-facing).
- `personal` → **Personal style** (playful / hobby projects).
- anything else / empty → **ask me** which style with the AskUserQuestion tool,
  then continue. Everything after the style token is the **topic/scope notes**.

The style only changes *tone and presentation* (headers, callouts, Mermaid
theme). The **folder layout below is identical for both** and is mandatory.

## Step 1 — the mandatory layout

This is my doc folder structure for every project. Write into the project root:

```
docs/
├── README.md              # index / landing page — links every other doc
├── <topic>.md             # one Markdown file per coherent topic
└── diagrams/
    └── <slug>.mmd         # one Mermaid file per diagram (standalone, editable)
```

Rules:
- **Markdown files** live directly under `docs/`. **Diagrams** live as
  standalone `.mmd` files under `docs/diagrams/`.
- **Every diagram is embeddable.** Author each diagram once as
  `docs/diagrams/<slug>.mmd`, then embed the *same* content inline in the
  owning Markdown file as a ` ```mermaid ` fenced block so it renders on
  GitHub/preview. Keep the inline copy byte-identical to the `.mmd` file
  (including the `%%{init}%%` theme line) so the two never drift.
- `docs/README.md` is the entry point: a short overview + a table linking every
  Markdown doc and listing every diagram.
- Each `.mmd` file starts with a `%%` comment naming the diagram, then the
  style's `%%{init}%%` theme directive (Step 3), then the graph.

## Step 2 — discover, propose, confirm

1. If `docs/` already exists, read it first and **refresh in place** (update,
   don't duplicate); preserve any content that's still accurate.
2. Inspect the project to decide what to document — prefer real sources:
   `README*`, `CLAUDE.md`, `project.md`, `PHASES.md`/`REQUIREMENTS.md`, package
   manifests, `compose*.y*ml`, the source tree, and (if present) the workspace
   `common/` catalog. Use the topic notes from `$ARGUMENTS` to focus scope.
3. **Propose an outline** — the list of `docs/*.md` files and `diagrams/*.mmd`
   you intend to create, one line each — and **wait for my confirmation**
   before writing anything.
4. Honor any locked project decisions (language, stack, conventions) and never
   invent facts: no fabricated dates, versions, owners, or sources. Use today's
   real date for any "last updated" field; leave unknowns as an explicit
   `_TBD_` for me to fill. Flag every assumption.
5. **Information security:** keep it self-contained — no external image/badge
   URLs, no CDN links, no customer names or part numbers (TISAX/ISO 27001).
   "Badges" are inline-code text, not remote images.

## Step 3 — apply the chosen style

### Edge & line conventions (both styles — STRICT, enforced)

Use **only** these edge types — each has fixed meaning, and no other edge
styling is permitted. This keeps every diagram uniform and the `.mmd` ↔ inline
copies stable.

| Meaning | Syntax |
|---|---|
| Primary / control flow | `A --> B` |
| Main / emphasized path | `A ==> B` |
| Secondary · reads · async · optional | `A -.-> B` |
| Association (no direction) | `A --- B` |
| Layout spacing only (invisible) | `A ~~~ B` |
| Labeled edge | `A -- label --> B` |

Shape and color/weight come from the init block + one `linkStyle default` line
(per style, below). Rules:

- **Never use `linkStyle <index>`** — index styling breaks when edges are
  reordered. Only `linkStyle default` is allowed.
- **Do not put `stroke-dasharray` in `linkStyle default`** — let `-.->` supply
  the dotted look from syntax.
- Line **weight semantics** stay with syntax (`==>` heavier than `-->`). If the
  `linkStyle default` width visually flattens an emphasized `==>` edge, give only
  those edges a targeted `linkStyle` width and say why.

### A) WORK style — professional, Büyütech **green** theme

Tone: precise, neutral, third-person; no decorative emoji (semantic status
markers `✅ ⚠️ ⛔` allowed inside tables only). Favor tables over prose for
structured facts. Cross-link requirement IDs and related docs. The brand color
manifests in the Mermaid diagrams (GitHub Markdown can't recolor prose).

> **Brand color:** the green below (`#0E7A3C`) is a placeholder. Replace it with
> Büyütech's exact logo-green hex once confirmed, then keep it identical across
> every `.mmd`/inline block. _TBD: confirm official brand hex._

**Every Markdown file opens with this header:**

```markdown
# <Title>

> **Purpose.** <one-sentence statement of what this document covers.>

| | |
|---|---|
| **Owner** | _TBD_ |
| **Status** | Draft · Reviewed · Approved |
| **Last updated** | <YYYY-MM-DD> |
| **Related** | <req IDs / sibling docs, or _none_> |

## Contents
<bulleted links to the H2 sections>
```

Callouts: `> **Note:** …`, `> **Warning:** …`. Close each doc with a one-line
maintenance footer: `> Maintained under \`docs/\`. Keep in sync with the source.`

**Mermaid init** — first line after the `%%` title comment in every `.mmd` and
every inline block:

```
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#0E7A3C','primaryTextColor':'#ffffff','primaryBorderColor':'#0A5C2D','lineColor':'#14532D','secondaryColor':'#34A853','tertiaryColor':'#E8F5E9','fontFamily':'Inter, Segoe UI, sans-serif'},'flowchart':{'curve':'basis'}}}%%
```

**Link defaults** — last line of the graph:

```
linkStyle default stroke:#14532D,stroke-width:1.5px;
```

### B) PERSONAL style — playful, **turquoise** theme

Tone: friendly, first-person, energetic. Emoji section headers welcome. Use
callout blockquotes liberally. Keep it skimmable and fun, still accurate. The
turquoise palette manifests in the Mermaid diagrams.

**Every Markdown file opens with this header:**

```markdown
# 🚀 <Title>

*<one punchy tagline>*

`🌱 status: living doc` · `🗓️ updated: <YYYY-MM-DD>`

## 📑 What's inside
<bulleted links to the H2 sections, each with a leading emoji>
```

Callouts: `> 💡 **Tip:** …`, `> ⚠️ **Heads up:** …`, `> 🎯 **TL;DR:** …`. Close
each doc with a friendly sign-off line.

**Mermaid init** — first line after the `%%` title comment in every `.mmd` and
every inline block:

```
%%{init: {'theme':'base','themeVariables':{'primaryColor':'#14B8A6','primaryTextColor':'#ffffff','primaryBorderColor':'#0D9488','lineColor':'#0EA5E9','secondaryColor':'#2DD4BF','tertiaryColor':'#CFFAFE','fontFamily':'Trebuchet MS, Poppins, sans-serif'},'flowchart':{'curve':'basis'}}}%%
```

**Link defaults** — last line of the graph:

```
linkStyle default stroke:#0EA5E9,stroke-width:2px;
```

## Step 4 — write & report

After I confirm the outline: create the files, embed each diagram inline as
described, and keep `.mmd` ↔ inline copies identical. Then report:

- the style used and the `docs/` tree you wrote (files + diagrams),
- any `_TBD_` placeholders left for me to fill and assumptions flagged,
- a suggested Conventional Commit (e.g. `docs: add project documentation`) —
  but **do not commit automatically**.
