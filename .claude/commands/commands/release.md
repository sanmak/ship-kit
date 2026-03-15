---
description: Bump version, update CHANGELOG, tag, and publish release
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Write, Edit, Grep, Glob
argument-hint: "[--dry-run]"
---

# /release

Bump version, generate changelog, tag, and publish a GitHub Release.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo "none"`

## Procedure

### 1. Parse Arguments

- `--dry-run` — preview the release without making any changes

### 2. Pre-Flight Checks

All checks must pass before proceeding:

1. **Clean tree**: `git status --porcelain` must be empty
   - Fail: "Working tree is dirty. Commit or stash changes first."
2. **On release branch**: current branch must match `release.releaseBranch` (default: `main`)
   - Fail: "Must be on <releaseBranch> to release. Currently on <branch>."
3. **Remote reachable**: `git ls-remote origin HEAD` must succeed
   - Fail: "Cannot reach remote. Check network connection."
4. **Tag doesn't exist**: the new tag must not already exist
   - Fail: "Tag <tag> already exists. Bump version or delete the existing tag."

### 3. Generate Changelog

Follow the **generate-changelog** skill:
1. Find last release tag
2. Gather and categorize commits since tag
3. Draft CHANGELOG entry
4. Prepend to changelog file

### 4. Bump Version

Follow the **bump-version** skill:
1. Read current version from configured or auto-detected version files
2. Determine bump type (from argument or commit analysis)
3. Calculate next version
4. Write new version to all version files

### 5. Run Pre-Release Commands

Execute each command in `release.preRelease` (e.g., `["npm run build", "npm test"]`):

```bash
npm run build
npm test
```

If any command fails, **abort** — no writes have been committed yet.

### 6. Dry-Run Preview

Display the release preview:

```
Release Preview: v1.2.0

  Version: 1.1.0 → 1.2.0
  Tag: v1.2.0
  Commits: 12 (3 feat, 5 fix, 4 chore)
  Version files modified:
    - package.json
  Changelog: CHANGELOG.md updated

  CHANGELOG entry:
  ## [1.2.0] - 2026-03-15
  ### Features
  - Add OAuth provider configuration
  ...
```

If `--dry-run`, stop here — no writes, no tag, no push.

### 7. Confirmation Gate

Prompt: "Proceed with release v1.2.0? (y/n)"

If declined, abort cleanly — no changes have been committed.

### 8. Commit

Follow the **stage-and-commit** skill (limited):
1. Stage modified files (changelog, version files)
2. Commit with message: `chore: release v<version>`

### 9. Create Tag

```bash
git tag -a v<version> -m "Release v<version>"
```

Using `release.tagPrefix` config (default: `v`).

### 10. Push

Follow the **validate-and-push** skill:
1. Push branch: `git push`
2. Push tag: `git push origin v<version>`

If push fails, the local commit and tag are preserved. Print recovery instructions:
```
Push failed. Local commit and tag are preserved.
  Resume: git push && git push origin v<version>
  Rollback: git tag -d v<version> && git reset --soft HEAD~1
```

### 11. Create GitHub Release

```bash
gh release create v<version> --title "v<version>" --notes "<changelog-entry>"
```

If this fails after push, do NOT auto-delete. Print:
```
Warning: GitHub Release creation failed. Tag and commit are pushed.
Create manually: gh release create v<version> --title "v<version>" --notes-file CHANGELOG.md
```

### 12. Report

```
✓ Released v<version>
  Tag: v<version>
  Commits: <N>
  GitHub Release: <release-url>
```

## Notes

- No writes before confirmation — the workflow is fully reversible until step 8
- `preRelease` commands run BEFORE confirmation to catch issues early
- Push failure preserves local state with clear recovery instructions
- GitHub Release failure after push is a warning, not a fatal error
