---
description: Stage, review, and commit with conventional message
allowed-tools: Bash(git:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob
---

# /commit

Stage all changes, check for sensitive files, run build triggers, review the diff, and create a conventional commit.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`

## Procedure

### 1. Pre-check

If `git status --porcelain` shows no changes (empty output), report:

```
Nothing to commit — working tree is clean.
```

Exit cleanly.

### 2. Stage and Commit

Follow the **stage-and-commit** skill procedure:

1. **Auto-stage** all changed files (`git add -A`)
2. **Detect sensitive files** — check staged files against sensitive patterns (defaults: `.env`, `*.pem`, `*.key`, `credentials.json`, `secrets.json`, `id_rsa`, `id_ed25519`). If any match, abort with a blocking report listing each file and the pattern it matched.
3. **Check build triggers** — if `build.triggers` are configured and staged files match `watch` patterns, run the trigger's `run` command and stage `stage` output files. Abort if any trigger command fails.
4. **Regenerate checksums** — if `checksums.enabled`, compute SHA-256 for configured files and update the checksums file.
5. **Review the diff** — display `git diff --cached --stat` and analyze the changes.
6. **Generate a conventional commit message** — use the format `<type>(<scope>): <description>` with types from `commit.conventionalPrefixes` (default: feat, fix, chore, docs, test, refactor). Append `commit.coAuthor` trailer if configured.
7. **Commit** — run `git commit -m "<message>"`. Never use `--no-verify`.

### 3. Report

On success:

```
✓ Committed <short-sha>: <commit message>
  <N> files changed
```
