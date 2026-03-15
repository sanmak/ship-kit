---
description: Clean up stale branches — delete merged locals, prune remotes
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob
argument-hint: "[--dry-run] [--include-remote]"
---

# /cleanup

Prune stale branches — find merged and orphaned local branches, check PR status, and delete safely.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`
- All branches: !`git branch --list`

## Procedure

### 1. Fetch and Prune

```bash
git fetch --prune
```

### 2. Determine Protected Branches

Load `cleanup.protectedBranches` (default: `["main", "master", "develop", "release/*", "hotfix/*"]`).

Always protect the current branch.

### 3. Find Candidate Branches

**Merged branches** — already merged into the default branch:
```bash
git branch --merged origin/main
```

**Orphaned branches** — no upstream tracking and no recent commits (older than `cleanup.staleDays`, default: 90):
```bash
git branch -vv | grep ': gone]'
```

Filter out protected branches from both lists.

### 4. Check PR Status

For each candidate, check if there's an associated PR:
```bash
gh pr list --head <branch> --state all --json number,state,title
```

Classify:
- PR merged → safe to delete
- PR closed (not merged) → safe to delete
- PR open → keep (active work)
- No PR → include in report

### 5. Print Report

```
Branch Cleanup Report

  Merged (safe to delete):
    feature/auth (PR #42 merged)
    fix/typo (PR #43 merged)

  Orphaned (no tracking, stale):
    old-experiment (120 days, no PR)

  Skipped:
    feature/wip (PR #44 open)

  Protected:
    main, develop

  Total: 3 deletable, 1 skipped, 2 protected
```

### 6. Dry-Run Exit

If `--dry-run`, stop here — zero deletions.

### 7. Confirm and Delete Local Branches

Prompt: "Delete 3 local branches? (y/n)"

If confirmed:
```bash
git branch -d <branch>   # never -D (force delete)
```

Report any branches that fail to delete (not fully merged):
```
Warning: <branch> could not be deleted (not fully merged).
  Use git branch -D <branch> to force delete if intentional.
```

### 8. Remote Cleanup (--include-remote)

If `--include-remote` is provided AND `cleanup.deleteRemote` is `true`:

For each deleted local branch, check for remote counterpart:
```bash
git push origin --delete <branch>
```

**Per-branch confirmation** required for remote deletion.

If `--include-remote` without `cleanup.deleteRemote: true`:
```
Remote deletion requires cleanup.deleteRemote: true in .shipkit.json
```

### 9. Report

```
✓ Cleaned up 3 branches (2 merged, 1 orphaned)
  Remote: 2 deleted (if --include-remote)
```

## Notes

- Never uses `-D` (force delete) — only `-d` (safe delete)
- Protected branches are NEVER deleted
- Remote deletion requires both the flag AND config permission
- Current branch is always protected
