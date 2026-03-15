---
description: Sync branch with upstream — fetch, rebase/merge, handle conflicts
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob
argument-hint: "[base-branch] [--merge] [--rebase]"
---

# /sync

Sync the current branch with upstream by fetching and rebasing or merging.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Remotes: !`git remote -v`

## Procedure

### 1. Parse Arguments

- `[base-branch]` — optional target branch to sync against (overrides config/auto-detection)
- `--merge` — force merge strategy
- `--rebase` — force rebase strategy
- If both `--merge` and `--rebase` are provided, **fail fast**:
  ```
  ABORT: Cannot use both --merge and --rebase. Pick one.
  ```

### 2. Determine Base Branch

Resolution order:
1. Explicit argument (e.g., `/sync develop`)
2. `sync.baseBranch` from config
3. Auto-detect from PR base: `gh pr view --json baseRefName -q .baseRefName 2>/dev/null`
4. Remote default branch: `git remote show origin | grep 'HEAD branch'`
5. Fallback: `main`

### 3. Determine Strategy

Resolution order:
1. Explicit flag (`--merge` or `--rebase`)
2. `sync.strategy` from config (default: `"rebase"`)
3. Heuristic: `rebase` for feature branches, `merge` for main/develop

### 4. Auto-Stash (if dirty)

If `sync.autoStash` is `true` (default) and the working tree is dirty:

```bash
git stash push -m "shipkit-sync-autostash"
```

Record that a stash was created for later restoration.

### 5. Fetch

```bash
git fetch origin
```

If `sync.syncUpstream` is `true` and an `upstream` remote exists:

```bash
git fetch upstream
```

### 6. Check If Sync Needed

```bash
git log HEAD..origin/<base-branch> --oneline
```

If no new commits, report:

```
Branch is already up to date with origin/<base-branch>.
```

Restore stash if needed and exit.

### 7. Perform Sync

#### Rebase Strategy

```bash
git rebase origin/<base-branch>
```

If conflicts occur, call the **resolve-conflicts** skill. After resolution, rebase continues automatically if `continueAfterResolve` is true.

#### Merge Strategy

```bash
git merge origin/<base-branch>
```

If conflicts occur, call the **resolve-conflicts** skill. After resolution, merge continues automatically.

### 8. Restore Stash

If a stash was created in step 4:

```bash
git stash pop
```

If stash pop causes conflicts, warn (do not abort the sync):

```
Warning: Stash pop caused conflicts. Your stashed changes have been restored but may need manual resolution.
```

### 9. Optionally Run Validations

If `sync.runValidationAfterSync` is `true`:

Run `validation.commands` (same as validate-and-push step 3). Report results but do **not** auto-push.

### 10. Report

```
✓ Synced <current-branch> with origin/<base-branch> via <strategy>
  <N> new commits applied
  Stash: restored (if applicable)
```

## Notes

- `/sync` does **NOT** auto-push after sync — that's a deliberate design choice
- Fork-aware: fetches from `upstream` if present and configured
- Stash pop conflicts are warnings only — the sync itself succeeded
- If `sync.preferUpstream` is true and upstream remote exists, sync against `upstream/<base-branch>` instead of `origin/<base-branch>`
