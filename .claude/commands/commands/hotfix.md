---
description: Emergency hotfix — branch, fix, validate, tag, cherry-pick
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob
argument-hint: "[base-tag] [--dry-run]"
---

# /hotfix

Emergency hotfix workflow with two-pass design. First run creates the hotfix branch. Second run (after fix applied) completes the release.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo ""`
- Tags list: !`git tag --sort=-v:refname | head -5`

## Procedure

### 1. Detect Latest Release Tag

Use argument `[base-tag]` if provided, otherwise find latest:

```bash
git describe --tags --abbrev=0
```

If no tags exist, **fail fast**:
```
ABORT: No release tags found. Cannot create hotfix without a base release.
Create a release first with /release.
```

### 2. Calculate Patch Version

Parse the tag version and increment patch:
- `v1.2.0` → `v1.2.1`
- `v2.0.3` → `v2.0.4`

Using `release.tagPrefix` (default: `v`).

### 3. Check for Hotfix Branch

Check if a hotfix branch already exists:

```bash
git branch --list "hotfix/<version>"
```

### First Run (No Hotfix Branch)

If the hotfix branch does NOT exist:

1. Create the branch from the release tag:
   ```bash
   git checkout -b hotfix/<version> <base-tag>
   ```
2. Report and exit:
   ```
   ✓ Hotfix branch created: hotfix/<version>
     Based on: <base-tag>

   Apply your fix, then run /hotfix again to complete the release.
   ```

### Second Run (On Hotfix Branch with Changes)

If already on a hotfix branch with uncommitted or new changes:

1. **Stage and commit** — follow the **stage-and-commit** skill
2. **Run validations and pre-release commands** — execute `validation.commands` and `release.preRelease`
3. **Bump version** — follow the **bump-version** skill (patch increment)
4. **Generate changelog** — follow the **generate-changelog** skill
5. **Dry-run exit** — if `--dry-run`, show preview and stop
6. **Tag** — `git tag -a <tag> -m "Hotfix <version>"`
7. **Validate and push** — follow **validate-and-push** skill (branch + tag)
8. **Create GitHub Release** — `gh release create <tag> --title "Hotfix <version>" --notes "<changelog>"`
9. **Cherry-pick to target branches** — for each branch in `hotfix.targetBranches` (default: `["main"]`):
   ```bash
   git checkout <target>
   git cherry-pick <hotfix-commits>
   ```
   If cherry-pick conflicts, **stop** with:
   ```
   Cherry-pick conflict on <target>. Run /resolve to fix, then:
     git cherry-pick --continue
   ```
10. **Return to hotfix branch** and report

### Report

```
✓ Hotfix v<version> released
  Tag: v<version>
  GitHub Release: <url>
  Cherry-picked to: main
```

## Notes

- Two-pass design: first run creates branch, second run releases
- Fails fast if no release tags exist
- Cherry-pick conflicts are expected and handled gracefully
- `--dry-run` works on second run only (first run is branch creation only)
- If `hotfix.skipCherryPick` is true, skip step 9
