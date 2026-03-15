---
description: AI-assisted code review with structured findings
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob
argument-hint: "[PR-number] [--post]"
---

# /review

AI-assisted code review that produces structured findings with severity, categories, and fix suggestions.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`

## Procedure

### 1. Determine Review Target

Resolution order:
1. PR number argument → fetch diff via `gh pr diff <number>`
2. Auto-detect PR from current branch → `gh pr view --json number -q .number`
3. Fall back to local diff → `git diff origin/main..HEAD`

### 2. Gather Diff

```bash
gh pr diff <number>    # or git diff for local review
```

### 3. Filter Files

Exclude files matching `review.ignorePaths` (defaults: `["*.lock", "vendor/**", "dist/**", "*.min.js", "*.min.css"]`):
- Lock files (auto-generated)
- Vendor/dist directories (third-party or build output)
- Minified files

Also exclude:
- Binary files
- Files exceeding `review.maxFileSize` (default: 5000 lines)

### 4. Check for Sensitive Files

Call the **detect-sensitive** skill on changed files. Include any findings as high-severity security issues in the report.

### 5. Analyze Changes

For each file in the diff, analyze for issues in `review.focusAreas` (default: `["bugs", "security", "performance", "style"]`):

**Bugs**: Logic errors, null dereferences, race conditions, incorrect comparisons, off-by-one errors, missing error handling.

**Security**: SQL injection, XSS, command injection, hardcoded credentials, insecure randomness, missing input validation, path traversal.

**Performance**: N+1 queries, unnecessary allocations, missing memoization, blocking I/O in async context, unbounded loops.

**Style**: Naming conventions, dead code, overly complex functions, missing error types, inconsistent patterns.

Also check `review.customRules` for pattern-based matches.

### 6. Apply Severity Threshold

Filter findings by `review.severityThreshold` (default: `"suggestion"`):
- `"error"` — only critical issues
- `"warning"` — errors + warnings
- `"suggestion"` — all findings (default)

### 7. Produce Report

```
Code Review: PR #42 (or local diff)

  Files reviewed: 8 (3 skipped)
  Findings: 12 (2 error, 5 warning, 5 suggestion)

  🔴 ERROR
  ┌ src/auth.ts:42
  │ SQL injection via string concatenation
  │ Fix: Use parameterized query
  └

  🟡 WARNING
  ┌ src/api.ts:78
  │ Missing error handling for async operation
  │ Fix: Add try/catch with appropriate error response
  └

  🔵 SUGGESTION
  ┌ src/utils.ts:15
  │ Unresolved TODO marker
  │ Fix: Implement or remove TODO
  └
```

### 8. Post Comments (--post flag)

If `--post` is provided and a PR exists:

1. Check for existing ShipKit review comments (idempotent — don't post duplicates)
2. Post each finding as a line-level review comment via `gh api`:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments \
     -f body="**[<severity>]** <finding>\n\nSuggested fix: <fix>" \
     -f path="<file>" \
     -F line=<line> \
     -f side="RIGHT"
   ```
3. Format comments so `/pr-fix` can parse and consume them

### 9. Report

```
✓ Review complete: 12 findings (2 error, 5 warning, 5 suggestion)
  Posted: 12 comments on PR #42 (if --post)
```

## Notes

- Read-only by default — `--post` explicitly required to write comments
- `--post` is idempotent (checks for existing comments before posting)
- Comments are formatted for `/pr-fix` consumption (enabling `/review --post` → `/pr-fix` workflow)
- Sensitive file findings are always severity `error`
