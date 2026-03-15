---
description: Summarize authored commits over a given time period
allowed-tools: Bash(git:*), Bash(cat:*), Read, Grep, Glob
argument-hint: "[period]"
---

# /what-did-i-get-done

## Procedure

1. Parse period argument (default: "today"). Support: "today", "yesterday", "this week", "last week", "last N days", "since YYYY-MM-DD".
2. Call gather-commit-summary skill with the resolved time range.
3. Format as concise status update grouped by conventional commit type.
4. Include stats: N commits, M files changed, +X/-Y lines.
