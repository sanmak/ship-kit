---
description: Generate weekly recap with bugfix/tech-debt/net-new highlights
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob
---

# /weekly-review

## Procedure

1. Call gather-commit-summary skill with 7-day time range.
2. Format into categorized recap with emoji headers:
   - Net-new (feat commits)
   - Bugfixes (fix commits)
   - Tech debt (refactor, chore commits)
   - Docs (docs commits)
   - Tests (test commits)
3. Include PR links where available (via `gh pr list --state merged --search "author:@me"`).
4. Include week stats summary.
