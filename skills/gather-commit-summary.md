# Gather Commit Summary

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git user: !`git config user.name`

## Procedure

1. Determine current git user from `git config user.name` or `git config user.email`.
2. Parse time range from argument (e.g., "today", "this week", "last 3 days", "7 days"). Convert to git date format.
3. Gather authored commits:
   ```bash
   git log --author="<user>" --since="<start>" --until="<end>" --format="%H|%s|%aI"
   ```
4. Parse each commit: extract SHA, full message, conventional type (`feat`/`fix`/`chore`/`docs`/`test`/`refactor`), scope, and timestamp.
5. Categorize by conventional commit type.
6. Compute stats: commit count per category, total files changed, insertions, and deletions (from `git diff --stat`).
7. Return structured data: categorized commits + per-category counts + aggregate stats.
