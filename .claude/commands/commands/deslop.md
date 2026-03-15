---
description: Remove AI-generated code slop and clean up code style
allowed-tools: Bash(git:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Write, Edit, Grep, Glob
argument-hint: "[file|path]"
---

# /deslop

Scan for AI-generated code patterns ("slop") and clean them up.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`

## Procedure

### 1. Determine Target

If `[file|path]` argument provided, scan that file or directory.
Otherwise, scan all files changed since last commit:
```bash
git diff --name-only HEAD
```

If no changes, scan all tracked files in the project (excluding test files if `codeQuality.ignoreFiles` is configured).

### 2. Load Slop Patterns

From `codeQuality.slopPatterns` config, or defaults:

- Overly verbose comments that restate the code
- Unnecessary `console.log` / `print` debug statements
- Dead code and unused variables
- Overly defensive null checks where null is impossible
- Generic error messages ("An error occurred", "Something went wrong")
- Redundant type assertions (`as any`, `as unknown as X`)
- Copy-paste artifacts (duplicate code blocks)
- TODO stubs with no implementation (`// TODO: implement`)
- Empty catch blocks
- Unnecessary else after return

### 3. Scan Files

For each target file (respecting `codeQuality.ignoreFiles`):

1. Read the file
2. Identify slop patterns with line numbers
3. Classify each finding by pattern type

### 4. Show Findings

```
Slop Detected: 8 issues in 3 files

  src/auth.ts
    L15: Verbose comment restating the code
         // Check if the user is authenticated and return true if they are
    L42: console.log debug statement
         console.log("user data:", user)
    L78: Generic error message
         throw new Error("An error occurred")

  src/utils.ts
    L5:  Redundant type assertion
         const data = response as any
    L23: Empty catch block
         catch (e) {}
```

### 5. Apply Fixes

For each finding:
- **Verbose comments** → remove or replace with concise version
- **console.log** → remove
- **Dead code** → remove
- **Defensive null checks** → remove unnecessary checks
- **Generic errors** → replace with descriptive messages
- **Type assertions** → fix with proper types
- **TODO stubs** → flag for attention (don't auto-remove)
- **Empty catch** → add proper error handling

### 6. Show Diff and Confirm

Display before/after diff:
```bash
git diff
```

Prompt: "Apply these changes? (y/n)"

### 7. Optionally Commit

If `codeQuality.autoFix` is true or user confirms:

Follow the **stage-and-commit** skill with commit message:
```
refactor: remove AI-generated code slop
```

### 8. Report

```
✓ Deslopped 3 files (8 issues fixed)
  Committed: abc1234 refactor: remove AI-generated code slop (if committed)
```

## Notes

- Confirmation gate before applying changes
- Respects `codeQuality.ignoreFiles` (default: test files)
- TODO stubs are flagged but not auto-removed (they may be intentional)
- The commit message uses `refactor:` type since deslop is code cleanup
