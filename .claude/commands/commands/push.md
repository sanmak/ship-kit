---
description: Validate and push unpushed commits
allowed-tools: Bash(git:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob
---

# /push

Run pre-push validations, check for conflict markers, and push unpushed commits to the remote.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || echo ""`

## Procedure

### 1. Pre-check

If there are no unpushed commits, report:

```
Nothing to push — branch is up to date with remote.
```

Exit cleanly.

### 2. Validate and Push

Follow the **validate-and-push** skill procedure:

1. **Check conflict markers** — scan `git status --porcelain` for conflict codes (UU, AA, DD, AU, UA, DU, UD). If any are present, abort:
   ```
   ABORT: Conflict markers detected. Run /resolve to fix conflicts.
   ```
2. **Run validation commands** — execute each command in `validation.commands` sequentially. Abort on first failure with the error output.
3. **Verify checksums** — if `checksums.enabled`, compare computed SHA-256 hashes against stored values. Abort on mismatch.
4. **Push** — run `git push`. Never force-push. Never use `--no-verify`. If pushing a new branch, use `git push -u origin <branch>`.

### 3. Report

On success:

```
✓ Pushed <N> commit(s) to origin/<branch>
```
