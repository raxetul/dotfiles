---
argument-hint: <name>
description: Scaffold a new Home Manager module + its doc + wire it into common.nix and README.
allowed-tools: Read, Write, Edit, Bash(ls*), Bash(grep*)
---

Scaffold a new module called `$ARGUMENTS` (a single lowercase word
matching `^[a-z][a-z0-9_-]*$`). Refuse if the name is missing or
malformed.

Files to create / edit, in this order:

1. **`home/modules/$ARGUMENTS.nix`** — start from this skeleton, with
   placeholder header comment that explains *why* the module exists
   (the user will edit this; leave a clear TODO):

   ```nix
   { config, lib, pkgs, ... }:

   # $ARGUMENTS — TODO: one-paragraph description of what this module
   # configures and why it earns its own file.

   {
     # TODO: enable programs.$ARGUMENTS or write the home.file / xdg.configFile
     # declarations that wire configurations/$ARGUMENTS/ into the live tree.
   }
   ```

   If the module is platform-specific, also accept `system` and derive
   `isDarwin`/`isLinux` via `lib.hasSuffix` — never `pkgs.stdenv.isDarwin`.

2. **`doc/modules-$ARGUMENTS.md`** — use the Phase 13 frontmatter
   template literally:

   ```markdown
   ---
   nix-file: home/modules/$ARGUMENTS.nix
   maintainer: emrahurhan@buyutech.com.tr
   claude-rule: "Update this doc whenever the nix file changes."
   ---
   # $ARGUMENTS

   ## Purpose
   TODO

   ## My preferences (why it's configured this way)
   TODO

   ## Options enabled
   TODO

   ## Diagram
   (optional)

   ## Related
   - `home/modules/$ARGUMENTS.nix`
   ```

3. **`home/common.nix`** — add `./modules/$ARGUMENTS.nix` to the
   `imports = [ ... ]` list, sorted by what's already there (this
   file groups related modules; preserve the existing grouping
   rather than appending blindly).

4. **`README.md`** — add a row to the module/doc table. If no such
   table exists yet (likely until Phase 13 lands), surface that and
   ask the user whether to skip this step or create the table.

After scaffolding, print:
- The five files touched (with absolute paths).
- A one-line `git status` summary.
- The suggested commit message:
  `feat($ARGUMENTS): add Home Manager module + doc skeleton`.

Do NOT commit. The user reviews and commits with `/commit`.
