---
description: Generate an interactive HTML PR walkthrough with annotated diffs
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Grep, Glob
argument-hint: "[PR-number]"
---

# /pr-review-canvas

Generate a self-contained HTML file with an interactive PR walkthrough — sidebar navigation, expandable diffs with syntax highlighting, inline annotations, and embedded review comments.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`

## Procedure

### 1. Determine PR

Use argument if provided, otherwise auto-detect:
```bash
gh pr view --json number -q .number
```

### 2. Fetch PR Data

Gather all PR information:
```bash
gh pr view <number> --json title,body,additions,deletions,changedFiles,files,commits
gh pr diff <number>
```

Call the **get-pr-comments** skill to fetch existing review comments.

### 3. Categorize Changes

Group changed files by type:
- **New files** (added)
- **Modified files** (changed)
- **Deleted files** (removed)
- **Renamed files** (moved)

### 4. Annotate Diffs

For each file diff:
- Analyze what changed and why it matters
- Identify potential issues or notable patterns
- Create inline annotations as colored callouts

### 5. Generate HTML

Create a self-contained HTML file with:

- **No external dependencies** — all CSS/JS inline, works offline
- **Sidebar navigation** — file tree grouped by directory, click to jump
- **Expandable diff sections** — collapsed by default, click to expand
- **Syntax highlighting** — language-aware coloring via inline CSS classes
- **Inline annotations** — colored callouts (green=good, yellow=note, red=concern)
- **Summary statistics** — files changed, additions, deletions, commit count
- **Review comment threads** — embedded in context next to the relevant code

### 6. Write Output

Write to `pr-review-<number>.html` in the current directory.

### 7. Report

```
✓ PR review canvas generated: pr-review-<number>.html
  PR #<number>: <title>
  Files: <N> changed (+<additions> -<deletions>)
  Annotations: <M>
  Comments: <C> embedded
```

## Notes

- HTML is fully self-contained — no CDN dependencies, no external scripts
- Works offline after generation
- File size is proportional to diff size — large PRs produce large HTML files
- Syntax highlighting uses inline CSS classes, not external libraries
