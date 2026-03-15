# Detect Sensitive Files

Check staged or specified files against sensitive patterns to prevent accidental commits of secrets, credentials, and private keys.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Staged files: !`git diff --cached --name-only`

## Procedure

### 1. Load Sensitive Config

Read the `sensitive` section from `.shipkit.json`. If absent, use defaults:

```json
{
  "patterns": [".env", ".env.*", "*.pem", "*.key", "credentials.json", "secrets.json", "id_rsa", "id_ed25519"],
  "keywords": ["PRIVATE KEY", "-----BEGIN RSA", "-----BEGIN EC", "-----BEGIN OPENSSH", "sk-", "ghp_", "gho_", "github_pat_"],
  "files": []
}
```

### 2. Check File Paths Against Glob Patterns

For each file in the input list, match against `sensitive.patterns` using glob matching:

- `.env` matches any file named `.env`
- `.env.*` matches `.env.local`, `.env.production`, etc.
- `*.pem` matches any `.pem` file
- `*.key` matches any `.key` file

If a file matches any pattern, record it as a **pattern match**.

### 3. Check Exact File Matches

For each file in the input list, check against `sensitive.files` for exact path matches.

If a file matches, record it as a **file match**.

### 4. Keyword Scanning

For each file in the input list that was NOT already caught by pattern or file matching:

**Skip these files:**
- Binary files (detected by null bytes in first 8KB)
- Files inside `.git/` directory
- Files inside `node_modules/` directory
- Files larger than 1 MB

**For remaining UTF-8 text files:**
- Read the file content
- Search for any `sensitive.keywords` entries (case-sensitive)
- If a keyword is found, record it as a **keyword match** with the keyword and line number

### 5. Return Results

Return a structured result:

- `blocked: true/false` — whether any matches were found
- `matches[]` — list of matches, each with:
  - `file` — file path
  - `type` — `"pattern"` | `"file"` | `"keyword"`
  - `detail` — the matching pattern, exact path, or keyword found
  - `line` — line number (keyword matches only)

### 6. Reporting

If any matches are found, format a clear error:

```
BLOCKED: Sensitive files detected

  .env.local          — matches pattern ".env.*"
  certs/server.pem    — matches pattern "*.pem"
  config/auth.ts:42   — contains keyword "ghp_"

Remove these files from staging or update .shipkit.json sensitive config to adjust patterns.
```

## Notes

- All three checks (patterns, files, keywords) run independently — any single match blocks
- Default patterns apply even without `.shipkit.json`
- This skill is called by `stage-and-commit` (pre-commit gate) and `/review` (advisory)
- When called by `/review`, findings are advisory (included in report) rather than blocking
