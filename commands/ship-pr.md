---
description: Commit, create PR branch, and open a pull request
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob
---

# /ship-pr

Branch, commit, push, and open a pull request in one step.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Unpushed commits: !`git log @{u}..HEAD --oneline 2>/dev/null || echo ""`

## Procedure

### 1. Record Starting State

```bash
ORIGINAL_BRANCH=$(git branch --show-current)
STARTING_HEAD=$(git rev-parse HEAD)
```

### 2. Check for Pre-Existing Unpushed Commits

```bash
git log @{u}..HEAD --oneline 2>/dev/null
```

If unpushed commits exist and `pr.allowExistingUnpushedCommits` is `false` (default):

```
ABORT: Branch has pre-existing unpushed commits.
Commit your current work first, or set pr.allowExistingUnpushedCommits: true in .shipkit.json
```

### 3. Stage and Commit

If there are uncommitted changes, follow the **stage-and-commit** skill:
1. Auto-stage, detect sensitive, run build triggers, review diff
2. Generate conventional commit message
3. Commit

If no changes to commit and no unpushed commits, abort:
```
Nothing to ship — no changes and no unpushed commits.
```

### 4. Create PR Branch

Determine branch name using `pr.branchPrefix` template (default: `{{type}}/{{slug}}`):
- `{{type}}` — conventional commit type from the commit message (e.g., `feat`, `fix`)
- `{{slug}}` — kebab-cased summary from the commit message

```bash
git checkout -b <branch-name> $STARTING_HEAD
```

### 5. Cherry-Pick New Commits

Cherry-pick only the commits created by this run (from `$STARTING_HEAD` to the tip of `$ORIGINAL_BRANCH`):

```bash
git cherry-pick $STARTING_HEAD..$ORIGINAL_BRANCH
```

### 6. Validate and Push

Follow the **validate-and-push** skill:
1. Check conflict markers
2. Run validation commands
3. Push with upstream tracking: `git push -u origin <branch-name>`

### 7. Create Pull Request

```bash
gh pr create \
  --base <pr.baseBranch or "main"> \
  --head <branch-name> \
  --title "<commit-subject>" \
  --body "<pr-body>"
```

Use `pr.template` from config if defined, otherwise generate a body from the commit message.

### 8. Return to Original Branch

```bash
git checkout $ORIGINAL_BRANCH
```

### 9. Report

```
✓ PR created: <PR-URL>
  Branch: <branch-name>
  Commit: <short-sha> <message>
  Returned to: <original-branch>
```

## Error Handling

| Error | Action |
|-------|--------|
| Pre-existing unpushed commits | Abort (unless config allows) |
| No changes to commit | Abort cleanly |
| Cherry-pick conflict | Abort, clean up branch |
| Push failure | Abort, keep local branch for retry |
| PR creation failure | Report error, branch is pushed (user can create PR manually) |

## Notes

- Always returns to the original branch, even on failure
- The new branch is created from `$STARTING_HEAD`, not from the tip — this ensures only new commits are included
- If the original branch was `main`, the PR base is still `main` (the cherry-picked commits won't be duplicated)
