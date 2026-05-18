---
source: .claude/commands/new-module.md
maintainer: emrahurhan@buyutech.com.tr
claude-rule: "Update this doc whenever the source changes."
---
# /new-module &lt;name&gt;

## Purpose

Scaffold a new Home Manager module. Creates the `.nix` file, its
companion doc, adds the import to `home/common.nix`, and adds a
row to the repo README's module table.

## Arguments

- `<name>` — required, lowercase, `^[a-z][a-z0-9_-]*$`. Refused if
  missing or malformed.

## Behavior

Files touched, in order:

1. **`home/modules/$ARGUMENTS.nix`** — skeleton with TODO comment
   and an `enable` placeholder. If the module is platform-specific,
   the skeleton also accepts `system` and derives `isDarwin` /
   `isLinux` via `lib.hasSuffix` — never `pkgs.stdenv.isDarwin`.
2. **`doc/modules-$ARGUMENTS.md`** — uses the Phase 13 frontmatter
   template literally (`nix-file`, `maintainer`, `claude-rule`)
   and the standard heading set.
3. **`home/common.nix`** — adds `./modules/$ARGUMENTS.nix` to the
   existing `imports` list, preserving grouping (don't blindly
   append).
4. **`README.md`** — adds a row to the module/doc table. If no
   table exists yet, surfaces that and asks whether to skip or
   create.

After scaffolding:
- Prints the touched files (absolute paths).
- Prints a one-line `git status` summary.
- Suggests commit: `feat($ARGUMENTS): add Home Manager module + doc skeleton`.

## Hard rules

- Doesn't commit. The user reviews and commits with `/commit`.
- Never overwrites existing files. If
  `home/modules/$ARGUMENTS.nix` or `doc/modules-$ARGUMENTS.md`
  already exists, the command aborts.

## Related

- [.claude/skills/nix-module-author/SKILL.md](../../.claude/skills/nix-module-author/SKILL.md)
  — the full module-authoring prescription.
- [.claude/skills/doc-author/SKILL.md](../../.claude/skills/doc-author/SKILL.md)
  — doc heading + frontmatter rules.
- [home/common.nix](../../home/common.nix) — import list this
  command modifies.
