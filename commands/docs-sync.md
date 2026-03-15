---
description: Sync docs stale relative to changed source files
allowed-tools: Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob
---

# /docs-sync

## Procedure

1. Follow the `detect-stale-docs` skill to identify stale docs.

2. If no stale docs are found, report "All docs are up to date" and exit.

3. For each stale doc:
   a. Read the doc and the changed source files.
   b. Determine what changed in the sources that affects the doc.
   c. Generate minimal edit proposals (not full rewrites).
   d. Present the proposal and ask for approval per doc.
   e. If approved, apply the edits.

4. Report summary: N docs updated, M skipped.
