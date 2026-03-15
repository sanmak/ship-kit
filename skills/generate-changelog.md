# Generate Changelog

Gather conventional commits since the last release tag, categorize them, and prepend a new entry to the changelog file.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Latest tag: !`git describe --tags --abbrev=0 2>/dev/null || echo ""`

## Procedure

### 1. Find Last Release Tag

Determine the starting point for commit gathering:

```bash
git describe --tags --abbrev=0 2>/dev/null
```

- If a tag is found, use it as the base reference.
- If no tags exist, use all commits in the repository (omit the tag range).

### 2. Gather Commits Since Tag

Collect all commits between the tag and HEAD:

```bash
# With a tag
git log <tag>..HEAD --format="%H %s"

# Without a tag (all commits)
git log --format="%H %s"
```

If there are no commits since the last tag, abort:
```
ABORT: No commits since last tag (<tag>). Nothing to changelog.
```

### 3. Parse Conventional Commit Types

For each commit, extract the type from the subject line using the pattern:

```
<type>(<optional-scope>): <description>
```

Match the type portion (everything before the first `(` or `:`). Recognized types:

| Type | Category |
|------|----------|
| `feat` | Features |
| `fix` | Bug Fixes |
| `docs` | Documentation |
| `chore` | Other |
| `test` | Other |
| `refactor` | Other |
| `style` | Other |
| `perf` | Performance |
| `ci` | Other |
| `build` | Other |

Commits that do not follow conventional commit format go into the **Other** category.

If a commit subject contains `BREAKING CHANGE` or the type has a `!` suffix (e.g., `feat!:`), mark it as a breaking change.

### 4. Categorize Commits

Group commits into sections:

1. **Breaking Changes** — any commit marked as breaking (across all types)
2. **Features** — `feat` commits
3. **Bug Fixes** — `fix` commits
4. **Performance** — `perf` commits
5. **Documentation** — `docs` commits
6. **Other** — `chore`, `test`, `refactor`, `style`, `ci`, `build`, and non-conventional commits

Omit empty sections from the output.

### 5. Draft Changelog Entry

Format the entry using [Keep a Changelog](https://keepachangelog.com/) style:

```markdown
## [<version>] - <YYYY-MM-DD>

### Breaking Changes

- <description> ([<short-sha>](commit-url))

### Features

- <description> ([<short-sha>](commit-url))

### Bug Fixes

- <description> ([<short-sha>](commit-url))

### Performance

- <description> ([<short-sha>](commit-url))

### Documentation

- <description> ([<short-sha>](commit-url))

### Other

- <description> ([<short-sha>](commit-url))
```

**Rules:**
- `<version>` is provided by the caller (e.g., from the `bump-version` skill). If not provided, use `Unreleased`.
- `<YYYY-MM-DD>` is today's date.
- `<short-sha>` is the first 7 characters of the commit hash.
- `<description>` is the commit subject with the type prefix removed (e.g., `feat(auth): add OAuth` becomes `add OAuth`). Include the scope in parentheses if present: `**auth:** add OAuth`.
- Commit URL format: if a remote origin exists (`git remote get-url origin`), construct the URL as `<repo-url>/commit/<full-sha>`. Otherwise omit the link.

### 6. Prepend to Changelog File

Read the changelog file path from `release.changelog` in config. Default to `CHANGELOG.md` if not configured.

If the file exists, prepend the new entry after any existing header. Look for the first `## ` heading and insert before it:

```bash
# Read existing content, insert new entry after the title line
```

If the file does not exist, create it with a standard header:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

<new entry here>
```

### 7. Return Result

Report the result:

- `changelogFile` — path to the updated changelog file
- `version` — the version header used
- `totalCommits` — total number of commits processed
- `categories` — commit count by category

**Success output:**
```
Generated changelog for <version> (<total> commits)
  Features:       <N>
  Bug Fixes:      <N>
  Documentation:  <N>
  Other:          <N>

  Written to: CHANGELOG.md
```

Also return the full changelog entry text so the caller can use it (e.g., for GitHub release notes).

## Error Handling

| Error | Action |
|-------|--------|
| No commits since last tag | Abort — nothing to changelog |
| Changelog file not writable | Abort with permissions error |
| Git not available or not a repo | Abort with environment error |
| No remote origin configured | Omit commit links, proceed normally |

## Notes

- This skill is typically called by `/release` after `bump-version`
- The caller should provide the version string; if omitted, `Unreleased` is used as the version header
- The skill does not commit the changelog — that is the caller's responsibility
- Duplicate entries are avoided: if the changelog already contains a `## [<version>]` heading matching the provided version, abort with a warning instead of creating a duplicate
