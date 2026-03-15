# Validate and Push

Run validation commands, check for conflict markers, verify checksums, and push to remote.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || git log --oneline -5`

## Procedure

### 1. Check for Conflict Markers

Check `git status --porcelain` output for conflict marker codes:

- `UU` — both modified (unmerged)
- `AA` — both added
- `DD` — both deleted
- `AU` — added by us, modified by them
- `UA` — modified by us, added by them
- `DU` — deleted by us, modified by them
- `UD` — modified by us, deleted by them

If any conflict markers are present:

```
ABORT: Conflict markers detected

  UU src/auth.ts
  UU src/config.ts

Run /resolve to fix conflicts before pushing.
```

**Abort immediately** — do not proceed to validation or push.

### 2. Check for Unpushed Commits

Verify there are commits to push:

```bash
git log @{u}..HEAD --oneline 2>/dev/null
```

If no unpushed commits exist, report "Nothing to push" and exit cleanly.

If upstream tracking is not configured, check `git log --oneline -1` to verify at least one commit exists, then proceed (push will set upstream).

### 3. Run Validation Commands

Read `validation.commands` from config. For each command entry, run in order:

```bash
# Example: { "name": "Lint", "run": "npm run lint" }
npm run lint
```

**Rules:**
- Run commands sequentially in the order defined
- If any command fails (non-zero exit), **abort** with failure output:
  ```
  ABORT: Validation failed

  ✗ Lint: npm run lint
    [error output]

  Fix the issue and try again.
  ```
- Do not continue to subsequent validation commands after a failure
- If no `validation.commands` are configured, skip this step entirely

### 4. Verify Checksums (if enabled)

If `checksums.enabled` is `true`:

1. For each file in `checksums.files`, compute SHA-256:
   ```bash
   shasum -a 256 <file>
   ```
2. Compare against stored values in `checksums.file`
3. If any mismatch, **abort** with details:
   ```
   ABORT: Checksum mismatch

     dist/main.js: expected abc123... got def456...

   Run /commit to regenerate checksums.
   ```

If `checksums` is not configured or `enabled` is `false`, skip this step.

### 5. Push

Push to the remote:

```bash
git push
```

**Rules:**
- **Never** force-push (`--force`, `--force-with-lease`)
- **Never** use `--no-verify`
- If the push fails due to remote rejection (e.g., diverged history), report the error with guidance:
  ```
  Push failed: remote has commits not present locally

  Run /sync to update your branch, then try again.
  ```
- If pushing a new branch without upstream:
  ```bash
  git push -u origin <branch-name>
  ```

### 6. Return Result

Report the result:

- `pushed: true`
- `commits` — list of pushed commits (SHA + message)
- `branch` — the branch that was pushed
- `remote` — the remote name (usually `origin`)

**Success output:**
```
✓ Pushed <N> commit(s) to origin/<branch>
  abc1234 feat: add user auth
  def5678 fix: handle null case
```

## Error Handling

| Error | Action |
|-------|--------|
| Conflict markers detected | Abort with "/resolve" guidance |
| No unpushed commits | Report "Nothing to push", exit cleanly |
| Validation command fails | Abort with failure output |
| Checksum mismatch | Abort with mismatch details |
| Push rejected (diverged) | Abort with "/sync" guidance |
| Push rejected (permission) | Abort with error, suggest checking remote access |
| Network error | Abort with connectivity guidance |

## Notes

- This skill is called by `/push`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/release`, and `/hotfix`
- Conflict marker check always runs first — it's the cheapest and most critical gate
- Validation commands run with the user's shell permissions
- The skill never modifies the working tree — it only validates and pushes
