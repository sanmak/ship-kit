---
description: Watch CI runs and iterate on failures until checks pass
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob
---

# /loop-on-ci

Watch CI runs and iterate on failures until all checks pass or max cycles are exhausted.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`

## Procedure

Load `ci.maxFixCycles` from config (default: 3).

### Loop (up to maxFixCycles iterations)

For each cycle:

#### 1. Check CI Status

Follow the **check-ci-status** skill:
1. Get latest CI run for current branch
2. Wait for completion if running
3. Parse results

#### 2. Evaluate

If all checks pass:
```
✓ CI is green after <N> cycle(s)!
```
Exit successfully.

#### 3. Diagnose Failures

For each failed job:
1. Check `ci.failureHints` for pattern matches
2. If no hint, get failure logs and analyze
3. Call **check-compiler-errors** if compile/type failures detected

#### 4. Apply Fixes

Make code changes to resolve identified failures.

#### 5. Commit and Push

Follow **stage-and-commit** → **validate-and-push**:
- Commit message: `fix: resolve CI failure (cycle <N>/<max>)`
- Never force-push

#### 6. Wait for New CI Run

After push, wait for the new CI run to start and complete:
```bash
gh run list --branch <branch> --limit 1 --json databaseId,status
```
Poll until the run completes.

#### 7. Loop Back

Continue to the next cycle.

### Exhaustion

If max cycles reached without green CI:

```
⚠ Max fix cycles exhausted (<N>/<max>)

  Remaining failures:
    - Job "test": 2 failures in src/auth.test.ts
    - Job "lint": 1 error in src/config.ts

  Manual remediation suggestions:
    1. Check test failures for flaky tests or environment issues
    2. Run locally: npm test -- --verbose
```

## Notes

- Maximum iterations bounded by `ci.maxFixCycles` (default: 3)
- Each cycle produces one commit — the git history shows the fix iterations
- Never force-pushes between cycles
- If push conflicts (someone else pushed), stop with guidance
