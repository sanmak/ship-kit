---
description: Check CI status and auto-fix failures
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob
---

# /monitor

Single-pass CI check-and-fix. Checks the latest CI run, diagnoses failures, applies fixes, and pushes.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`
- Latest CI run: !`gh run list --branch $(git branch --show-current) --limit 1 --json databaseId,status,conclusion,name 2>/dev/null || echo "[]"`

## Procedure

### 1. Check CI Status

Follow the **check-ci-status** skill:
1. Identify latest CI run for current branch
2. Wait for completion if still running
3. Parse per-job results
4. Check `ci.failureHints` for known patterns

### 2. Evaluate Results

If all checks pass:
```
✓ CI is green — all checks passing on <branch>
```
Exit cleanly.

### 3. Diagnose Failures

For each failed job:

1. **Check failure hints first** — match error output against `ci.failureHints[].pattern`. If match found, apply the configured `fix` command.
2. **AI analysis** — if no hint matches, analyze the failure logs to identify the root cause. Check for:
   - Compile/type errors → call **check-compiler-errors** skill
   - Test failures → identify failing test and fix
   - Lint errors → run linter with auto-fix
   - Dependency issues → update/install dependencies
   - Environment issues → report (cannot auto-fix)

### 4. Apply Fixes

Make the necessary code changes to resolve the failures.

### 5. Stage, Commit, and Push

Follow the **stage-and-commit** skill → follow the **validate-and-push** skill.

Commit message: `fix: resolve CI failures (<brief description>)`

Never force-push. If push conflicts, stop with recovery instructions.

### 6. Report

```
✓ CI fix pushed
  Failures diagnosed: <N>
  Fixes applied: <M>
  Committed: <sha> fix: resolve CI failures
  Pushed to: origin/<branch>

  Next: Wait for CI to re-run, or use /loop-on-ci for automated iteration.
```

## Notes

- Single-pass only — use `/loop-on-ci` for iterative fixing
- Never force-pushes
- Failure hints are checked before AI analysis (cheaper, more reliable)
- Environment issues (missing secrets, infrastructure) are reported but not auto-fixed
