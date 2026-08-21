---
description: Opt THIS project into immediate deletion of dead/stale git worktrees — wires the autoprune hook into the project's own .claude/settings.json and records the rule in its ./CLAUDE.md.
allowed-tools: Read, Write, Edit, AskUserQuestion, Bash(git worktree*), Bash(git rev-parse*), Bash(ls*), Bash(test*), Bash(cat*), Bash(jq*), Bash(mkdir*)
---

Opt the **current project** into automatic pruning of dead git worktrees.

A worktree is **dead** when its working directory is gone but git still keeps
the admin record under `.git/worktrees/<name>/`. Those records keep the branch
marked "checked out elsewhere" — so it can't be checked out or deleted — and
keep the worktree in `git worktree list` forever. `git worktree prune` removes
exactly and only those records.

**Scope is deliberately narrow, and it is what makes this safe to run
unattended:** a worktree whose directory still exists is never touched, however
dirty. No branch, commit, or file the user still has is ever deleted. A worktree
holding uncommitted work is by definition *not* dead — its directory is right
there — so pruning cannot lose it.

This is project-scoped on purpose (global rule: keep `~/.claude/` small — a rule
loads only inside the project it governs). The hook **script** is a shared
machine resource at `${HOME}/.claude/hooks/git-worktree-autoprune.sh`, symlinked
from this repo by `scripts/symlinks.sh`; this command only **activates** it here.

## Procedure

1. **Verify preconditions.** Confirm the cwd is a non-bare git repo
   (`git rev-parse --is-bare-repository` → `false`). If not, stop and say so.
   Confirm `${HOME}/.claude/hooks/git-worktree-autoprune.sh` exists and is
   executable; if it doesn't, tell the user to run `scripts/symlinks.sh install`
   from the dotfiles repo first, and stop.

2. **Report the current state** as a table before changing anything — run
   `git worktree list` and mark which entries git reports as `prunable`. If
   there are none, say so; the hook is still worth wiring for the future.

3. **Pre-CLI brief.** Show exactly what will be written:
   - the two hook entries (`SessionStart`, `WorktreeRemove`) added to
     `./.claude/settings.json`
   - the rule paragraph added to `./CLAUDE.md`
   Then confirm before writing.

4. **Merge into `./.claude/settings.json`** — read it first and MERGE; never
   replace. Create the file if absent. Both events run the same command:

   ```json
   {
     "hooks": {
       "SessionStart": [
         { "hooks": [ { "type": "command",
                        "command": "bash \"$HOME/.claude/hooks/git-worktree-autoprune.sh\"",
                        "timeout": 15 } ] }
       ],
       "WorktreeRemove": [
         { "hooks": [ { "type": "command",
                        "command": "bash \"$HOME/.claude/hooks/git-worktree-autoprune.sh\"",
                        "timeout": 15 } ] }
       ]
     }
   }
   ```

   If an entry for either event already runs this script, leave it alone and
   report it as already wired — this command is idempotent.

5. **Record the rule in `./CLAUDE.md`** under a `## Git worktrees` heading
   (create it if missing), stating that dead worktree records are pruned
   automatically on session start and on worktree removal, that only records
   whose directory is already gone are affected, and that `DRY_RUN=1` makes the
   hook report instead of act.

6. **Validate**, and show the result:

   ```
   jq -e '.hooks.SessionStart[].hooks[] | select(.command | test("git-worktree-autoprune"))' ./.claude/settings.json
   ```

   Exit 0 = wired. Then run the hook once by hand to prove it works in this repo:

   ```
   echo "{\"cwd\":\"$PWD\"}" | DRY_RUN=1 bash "$HOME/.claude/hooks/git-worktree-autoprune.sh"
   ```

7. **Hand off.** Tell the user it's live for this project only, that `/hooks`
   lists and disables it, and that the settings watcher may need `/hooks` opened
   once (or a restart) before it fires this session.

Never commit automatically. Leave the changes staged for the user to review.
