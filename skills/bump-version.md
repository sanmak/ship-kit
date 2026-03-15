# Bump Version

Read version files, calculate the next semver version, and write the updated version to all configured files.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`

## Procedure

### 1. Read Current Version

Read `release.versionFiles` from config. Each entry has `path`, `type`, and `field`:

```json
{
  "release": {
    "versionFiles": [
      { "path": "package.json", "type": "json", "field": "version" },
      { "path": "pyproject.toml", "type": "toml", "field": "project.version" }
    ]
  }
}
```

If `release.versionFiles` is not configured, auto-detect by checking the following files in order:

| File | Type | Field |
|------|------|-------|
| `package.json` | json | `version` |
| `pyproject.toml` | toml | `project.version` |
| `Cargo.toml` | toml | `package.version` |
| `VERSION` | text | (entire file content, matched via regex `[0-9]+\.[0-9]+\.[0-9]+`) |

Use the first file that exists. Read its current version:

**JSON** (via `node -e` or `python3`):
```bash
node -e "console.log(require('./package.json').version)"
```

**TOML** (via `python3`):
```bash
python3 -c "
import re
content = open('pyproject.toml').read()
m = re.search(r'version\s*=\s*\"([^\"]+)\"', content)
print(m.group(1))
"
```

**Text** (regex):
```bash
grep -oE '[0-9]+\.[0-9]+\.[0-9]+' VERSION | head -1
```

If no version file is found, abort with an error:
```
ABORT: No version file found. Configure release.versionFiles in .shipkit.json or add a package.json / pyproject.toml / Cargo.toml / VERSION file.
```

### 2. Determine Bump Type

If the caller provides an explicit bump type argument (`major`, `minor`, or `patch`), use it directly.

Otherwise, infer from conventional commits since the last tag:

```bash
git describe --tags --abbrev=0 2>/dev/null
```

If a tag exists, gather commits since that tag:
```bash
git log <tag>..HEAD --format="%s"
```

If no tag exists, gather all commits:
```bash
git log --format="%s"
```

Apply these rules (highest priority wins):

| Condition | Bump |
|-----------|------|
| Any commit subject contains `BREAKING CHANGE` or has a `!` after the type (e.g., `feat!:`) | major |
| Any commit has type `feat` | minor |
| All other cases (fix, chore, docs, etc.) | patch |

If there are no commits since the last tag, abort:
```
ABORT: No commits since last tag (<tag>). Nothing to bump.
```

### 3. Calculate Next Version

Parse the current version as `MAJOR.MINOR.PATCH` and apply the bump:

| Bump Type | Rule |
|-----------|------|
| major | `MAJOR+1.0.0` |
| minor | `MAJOR.MINOR+1.0` |
| patch | `MAJOR.MINOR.PATCH+1` |

### 4. Write New Version to All Version Files

Write the new version to **every** configured (or auto-detected) version file. If `release.versionFiles` lists multiple files, update all of them.

**JSON** (via `node -e` or `python3`):
```bash
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.version = '<new_version>';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"
```

**TOML** (via `python3 -c` with toml lib, falling back to sed):
```bash
python3 -c "
import toml, sys
data = toml.load('pyproject.toml')
data['project']['version'] = '<new_version>'
with open('pyproject.toml', 'w') as f:
    toml.dump(data, f)
" 2>/dev/null || sed -i.bak 's/version = \"<old_version>\"/version = \"<new_version>\"/' pyproject.toml && rm -f pyproject.toml.bak
```

For `Cargo.toml`, use the same TOML approach but navigate to `package.version`:
```bash
python3 -c "
import toml
data = toml.load('Cargo.toml')
data['package']['version'] = '<new_version>'
with open('Cargo.toml', 'w') as f:
    toml.dump(data, f)
" 2>/dev/null || sed -i.bak 's/version = \"<old_version>\"/version = \"<new_version>\"/' Cargo.toml && rm -f Cargo.toml.bak
```

**Text** (regex replace):
```bash
sed -i.bak 's/<old_version>/<new_version>/g' VERSION && rm -f VERSION.bak
```

### 5. Return Result

Report the result:

- `oldVersion` — the version before bumping
- `newVersion` — the version after bumping
- `bumpType` — major, minor, or patch
- `modifiedFiles` — list of files that were updated

**Success output:**
```
Bumped version: <old_version> -> <new_version> (<bump_type>)
  Modified files:
    - package.json
    - pyproject.toml
```

## Error Handling

| Error | Action |
|-------|--------|
| No version file found | Abort with configuration guidance |
| No commits since last tag | Abort — nothing to bump |
| Version file is unreadable or malformed | Abort with parse error details |
| Write fails (permissions, disk) | Abort with error output |
| TOML python lib unavailable and sed fallback fails | Abort with guidance to install `toml` package |

## Notes

- This skill is typically called by `/release` and `/hotfix`
- When multiple version files are configured, ALL must be updated atomically — if any write fails, report which files succeeded and which failed
- The skill does not create a git commit or tag — that is the caller's responsibility
- Pre-release suffixes (e.g., `-beta.1`, `-rc.1`) are not handled; only standard `MAJOR.MINOR.PATCH` is supported
