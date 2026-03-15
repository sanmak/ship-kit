---
description: Fetch PR review comments and fix them
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob
argument-hint: "[PR-number]"
---

# /pr-fix

Fetch PR review comments, fix the issues, validate, commit, push, and reply.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`

## Procedure

### 1. Fetch Review Comments

Follow the **get-pr-comments** skill:

1. Determine PR number from argument or auto-detect from current branch
2. Fetch line-level review comments via `gh api`
3. Fetch top-level review comments
4. Group by file and issue
5. Filter to unresolved comments only

If no unresolved comments found:

```
No unresolved review comments on PR #<number>.
```

Exit cleanly.

### 2. Analyze and Group Issues

Present a summary of issues grouped by file:

```
PR #42 — 5 unresolved comments in 3 files

  src/auth.ts (2 comments)
    L42: "This should validate the token expiry" — @reviewer
    L78: "Missing error handling for network failures" — @reviewer

  src/config.ts (2 comments)
    L15: "Use environment variable instead of hardcoded value" — @reviewer
    L30: "This type assertion is unsafe" — @reviewer

  tests/auth.test.ts (1 comment)
    L12: "Add test for expired token case" — @reviewer
```

### 3. Fix Issues

For each file with comments:

1. Read the file
2. Understand each comment and the surrounding code context
3. Apply fixes that address the reviewer's feedback
4. Ensure fixes are consistent with each other (no conflicting changes)

### 4. Validate Fixes

Call the **check-compiler-errors** skill:

1. Auto-detect project type (TypeScript → `tsc --noEmit`, Rust → `cargo check`, etc.)
2. Run the compile/type-check command
3. Parse any errors

If validation fails:

```
Validation failed after applying fixes:

  src/auth.ts:45 — Type 'string' is not assignable to type 'number'

Fixes NOT pushed. Review the validation errors and try again.
```

**Never push partial fixes** — if validation fails, report inline and stop.

### 5. Stage and Commit

Follow the **stage-and-commit** skill:

1. Stage only the modified files (not `git add -A`)
2. Detect sensitive files
3. Skip build triggers (targeted fix, not full build)
4. Generate commit message: `fix: address PR review feedback`
5. Commit

### 6. Validate and Push

Follow the **validate-and-push** skill:

1. Check conflict markers
2. Run validation commands
3. Push

### 7. Reply to Comments

For each resolved comment, post a reply via `gh api`:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="Fixed in <commit-sha>: <brief description of fix>"
```

### 8. Report

```
✓ Fixed 5 comments on PR #42
  Committed: abc1234 fix: address PR review feedback
  Pushed to: origin/<branch>
  Replied to: 5 comments
```

## Error Handling

| Error | Action |
|-------|--------|
| No PR found for branch | Abort with guidance to provide PR number |
| No unresolved comments | Report cleanly, exit |
| Validation failure after fixes | Abort — never push partial fixes |
| Push failure | Report error, commit is local |
| Reply failure | Report warning, fix was pushed successfully |

## Notes

- Partial fixes are **never** pushed — all-or-nothing
- Only unresolved comments are processed (resolved/outdated are skipped)
- The commit message references the PR number for traceability
- `--watch` and `--all` modes are deferred to v2
