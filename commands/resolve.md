---
description: Detect and resolve merge/rebase/cherry-pick conflicts
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob
argument-hint: "[--status] [--abort]"
---

# /resolve

Detect and resolve merge, rebase, or cherry-pick conflicts with AI-assisted per-file resolution.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Conflict state: !`ls .git/MERGE_HEAD .git/CHERRY_PICK_HEAD 2>/dev/null; ls -d .git/rebase-merge .git/rebase-apply 2>/dev/null`

## Procedure

### Parse Flags

Check for flags in the invocation:

- **`--status`**: Print a read-only conflict summary and exit (no resolution)
- **`--abort`**: Prompt for confirmation, then abort the current operation and exit

### --status Mode

If `--status` is provided:

1. Detect the operation type from sentinel files (`.git/MERGE_HEAD` → merge, `.git/rebase-merge/` → rebase, `.git/CHERRY_PICK_HEAD` → cherry-pick)
2. List conflicted files from `git status --porcelain`
3. Print summary:
   ```
   Conflict Status
     Operation: merge
     Conflicted files: 3
       UU src/auth.ts
       UU src/config.ts
       AA src/utils.ts
   ```
4. Exit — no changes made.

### --abort Mode

If `--abort` is provided:

1. Detect the operation type
2. Prompt: "Abort the current <operation-type>? This will discard all conflict resolutions. (y/n)"
3. If confirmed:
   ```bash
   git merge --abort    # or git rebase --abort / git cherry-pick --abort
   ```
4. Report: "Aborted <operation-type>. Working tree restored."

### Default Mode (Interactive Resolution)

Follow the **resolve-conflicts** skill procedure:

1. **Classify operation** from sentinel files
2. **List conflicted files** from `git status --porcelain`
3. **Per-file resolution loop**:
   - Skip ignored patterns (lock files) — take theirs and regenerate
   - Skip binary files — provide manual instruction
   - Read conflict markers, extract ours/theirs/base
   - AI-propose resolution with explanation
   - Interactive review: Accept / Skip / Ours / Theirs
   - Apply accepted resolutions and stage
4. **Post-loop summary** (applied/skipped/remaining counts)
5. **Git continuation** if all conflicts resolved and `continueAfterResolve` is true

### Report

```
✓ Resolved <N> files (<M> skipped, <R> remaining)
  Operation: <type> continued successfully
```

## Notes

- v1 config keys used: `ignorePatterns`, `continueAfterResolve`, `allowedOperations`
- v1 ignores: `autoMode`, `resolutionStrategy`, `autoSkipLowConfidence` (defined in schema, emit warning if set)
