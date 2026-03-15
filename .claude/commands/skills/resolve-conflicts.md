# Resolve Conflicts

Detect conflict type, read markers, AI-propose resolution per file, interactive accept/skip, apply, and git continue.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Conflict state: !`ls .git/MERGE_HEAD .git/CHERRY_PICK_HEAD 2>/dev/null; ls -d .git/rebase-merge .git/rebase-apply 2>/dev/null`

## Procedure

### 1. Classify Operation Type

Check sentinel files to determine which git operation is in progress:

| Sentinel | Operation |
|----------|-----------|
| `.git/MERGE_HEAD` | Merge |
| `.git/rebase-merge/` | Interactive rebase |
| `.git/rebase-apply/` | Rebase (apply) |
| `.git/CHERRY_PICK_HEAD` | Cherry-pick |

If no sentinel file exists, report:

```
No conflict operation in progress. Nothing to resolve.
```

Exit cleanly.

Check `resolve.allowedOperations` config (default: `["merge", "rebase", "cherry-pick"]`). If the detected operation type is not in the allowed list, abort:

```
ABORT: /resolve is not configured to handle <operation-type> conflicts.
Check resolve.allowedOperations in .shipkit.json
```

### 2. List Conflicted Files

Parse `git status --porcelain` for conflict markers:

```bash
git status --porcelain | grep -E '^(UU|AA|DD|AU|UA|DU|UD) '
```

Extract the file paths. If no conflicted files found, report:

```
No conflicted files found. The operation may have been resolved already.
Run: git <operation> --continue
```

### 3. Per-File Resolution Loop

For each conflicted file:

#### a. Check Skip Rules

Load `resolve.ignorePatterns` config (default: `["*.lock", "package-lock.json", "yarn.lock"]`).

- If the file matches an ignore pattern → **skip** with instruction:
  ```
  Skipping <file> (matches ignore pattern). Regenerate this file after resolution:
    npm install / yarn install / cargo generate-lockfile
  ```
  Run `git checkout --theirs <file> && git add <file>` for lock files.

#### b. Detect Binary Files

Check if the file is binary (null bytes in first 8KB):

```bash
head -c 8192 <file> | grep -qP '\x00'
```

- If binary → **skip** with instruction:
  ```
  Skipping <file> (binary file). Resolve manually:
    git checkout --ours <file>    # keep your version
    git checkout --theirs <file>  # take their version
  ```

#### c. Read Conflict Markers

Read the file and extract conflict sections:

```
<<<<<<< HEAD (ours)
... our changes ...
||||||| base (optional, if diff3)
... original content ...
=======
... their changes ...
>>>>>>> branch-name (theirs)
```

Extract `ours`, `theirs`, and optionally `base` content for each conflict region.

#### d. AI Resolution Proposal

Analyze both sides of the conflict:
- Understand the intent of each change
- Produce a resolved version that preserves both intents where possible
- Provide a brief explanation of the resolution

Present the proposal:

```
File: src/auth.ts (2 conflict regions)

Region 1 (lines 42-58):
  Ours:   Added OAuth configuration
  Theirs: Added SAML configuration
  Resolution: Keep both — OAuth and SAML configs are independent

Region 2 (lines 120-135):
  Ours:   Changed error message format
  Theirs: Added error logging
  Resolution: Merge both — use new message format with logging
```

#### e. Interactive Review

Prompt for action on each file:

- **Accept** — Apply the AI resolution
- **Skip** — Leave the conflict markers in place for manual resolution
- **Ours** — Accept our version entirely (`git checkout --ours <file>`)
- **Theirs** — Accept their version entirely (`git checkout --theirs <file>`)

#### f. Apply Resolution

For accepted resolutions:
1. Write the resolved content to the file
2. Stage the file: `git add <file>`

### 4. Post-Loop Summary

```
Conflict Resolution Summary
  Applied: 5 files
  Skipped: 1 file (binary)
  Ignored: 2 files (lock files)
  Remaining: 0 unresolved conflicts
```

### 5. Git Continuation

If `resolve.continueAfterResolve` is `true` (default) and all conflicts are resolved (no remaining unresolved files):

Prompt: "All conflicts resolved. Continue the <operation-type>?"

If confirmed:
```bash
git <operation> --continue
```

Where `<operation>` is `merge`, `rebase`, or `cherry-pick` based on the detected type.

If not all conflicts resolved, report:

```
<N> files still have unresolved conflicts.
Resolve them manually, then run: git <operation> --continue
```

## Returns

- `resolved: true/false`
- `appliedCount` — files where resolution was applied
- `skippedCount` — files skipped (binary, ignored, or user chose skip)
- `remainingCount` — files with unresolved conflicts
- `operationType` — merge / rebase / cherry-pick

## Notes

- This skill is called by `/resolve`, `/sync`, and `/hotfix`
- v1 uses interactive mode only — `autoMode` config key is defined in schema but ignored
- `resolutionStrategy` config key is defined but ignored in v1 (always uses balanced AI resolution)
- Lock files are always handled by taking `theirs` and regenerating — never merge lock file contents
