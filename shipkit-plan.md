# ShipKit: Generic Dev Workflow Commands Plugin

## Context

SpecOps has 8 custom slash commands (`/commit`, `/push`, `/ship`, `/ship-pr`, `/pr-fix`, `/release`, `/monitor`, `/docs-sync`) that automate git workflows. Currently they're tightly coupled to SpecOps — hard-coded references to `generator/generate.py`, `CHECKSUMS.sha256`, platform regeneration, and SpecOps-specific CI jobs. We want to extract these into a **standalone Claude Code plugin** that any project can use, configured via a `.shipkit.json` file.

---

## Plugin Overview

| Attribute    | Value                                                              |
| ------------ | ------------------------------------------------------------------ |
| **Name**     | ShipKit                                                            |
| **Repo**     | New standalone repo (`sanmak/shipkit`)                             |
| **Config**   | `.shipkit.json` (optional — zero-config works for simple projects) |
| **Commands** | 14 slash commands (full suite)                                     |
| **Target**   | Claude Code only (commands format is Claude Code specific)         |
| **Install**  | Plugin marketplace + one-line installer script                     |

---

## Repository Structure

```
shipkit/
  .claude-plugin/
    plugin.json                    # Plugin manifest (valid fields only)
    marketplace.json               # Self-hosting marketplace listing
  commands/                        # At plugin root (Claude Code auto-discovers ./commands/)
    commit.md                      # /commit
    push.md                        # /push
    ship.md                        # /ship (commit + push)
    ship-pr.md                     # /ship-pr
    pr-fix.md                      # /pr-fix
    release.md                     # /release
    monitor.md                     # /monitor
    docs-sync.md                   # /docs-sync
    resolve.md                     # /resolve
    review.md                      # /review
    hotfix.md                      # /hotfix
    sync.md                        # /sync
    cleanup.md                     # /cleanup
    sequence-diagram.md            # /sequence-diagram
  examples/
    .shipkit.json                  # Standard config
    .shipkit.minimal.json          # Zero-config baseline
    .shipkit.full.json             # All options
  schema.json                     # JSON Schema for .shipkit.json
  install.sh                      # Fallback installer (marketplace is primary)
  README.md
  LICENSE
  CHANGELOG.md
```

**Key decisions**:
- No generator or build system. Commands are plain markdown files (with YAML frontmatter) that read config at runtime via inline bash. All "logic" is prompt engineering — Claude interprets the instructions and executes them.
- Commands live at `commands/` (plugin root), not `.claude/commands/` (project-level convention). Claude Code auto-discovers `./commands/` when loading installed plugins.

---

## Plugin Manifest (`.claude-plugin/plugin.json`)

Only valid `plugin.json` fields are used. Command descriptions are defined in each command's YAML frontmatter, not in the manifest.

```json
{
  "name": "shipkit",
  "version": "1.0.0",
  "description": "Git workflow automation — commit, push, ship, release, and monitor from Claude Code",
  "author": {
    "name": "Sanket Makhija"
  },
  "repository": "https://github.com/sanmak/shipkit",
  "homepage": "https://github.com/sanmak/shipkit",
  "license": "MIT",
  "keywords": [
    "git", "workflow", "commit", "push", "release",
    "pr", "ci", "automation"
  ]
}
```

**Note**: The `commands` field is omitted because Claude Code auto-discovers `./commands/` by default. No `configFile`, `configSchema`, or `claudeCode.minVersion` fields exist in the plugin.json schema — config loading is handled at runtime within each command via inline bash.

## Marketplace Manifest (`.claude-plugin/marketplace.json`)

ShipKit self-hosts as its own marketplace (same pattern as SpecOps). The repo contains both `plugin.json` and `marketplace.json` in `.claude-plugin/`.

```json
{
  "name": "shipkit-marketplace",
  "description": "ShipKit plugin marketplace",
  "plugins": [
    {
      "name": "shipkit",
      "description": "Git workflow automation — commit, push, ship, release, and monitor from Claude Code",
      "source": "./"
    }
  ]
}
```

Users install via:
```
/plugin marketplace add sanmak/shipkit
/plugin install shipkit
```

---

## Command Format

Every command `.md` file in `commands/` **must** include YAML frontmatter with `description` and `allowed-tools`. Without `allowed-tools`, every bash/git invocation prompts the user for permission, destroying the automation value.

### Frontmatter Template

```yaml
---
description: <one-line description shown in /help>
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Read, Grep, Glob
argument-hint: <optional, for commands accepting arguments>
---
```

### Config Loading Preamble

Every command must load config at the top using inline bash (`!` backtick syntax). This provides Claude with the project's config and current git state as context:

```markdown
## Context
- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
```

Each command selects only the context lines it needs. For example, `/commit` needs status and diff; `/release` needs branch, tags, and recent commits.

### Per-Command Frontmatter

| Command | `description` | `allowed-tools` | `argument-hint` |
|---------|---------------|-----------------|-----------------|
| `/commit` | Stage, review, and commit with conventional message | `Bash(git:*), Bash(cat:*), Bash(shasum:*), Read, Grep, Glob` | — |
| `/push` | Validate and push unpushed commits | `Bash(git:*), Bash(cat:*), Read, Grep, Glob` | — |
| `/ship` | Commit and push in one step | `Bash(git:*), Bash(cat:*), Bash(shasum:*), Read, Grep, Glob` | — |
| `/ship-pr` | Commit, create PR branch, and open a pull request | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob` | — |
| `/pr-fix` | Fetch PR review comments and fix them | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | `[PR-number]` |
| `/release` | Bump version, update CHANGELOG, tag, and publish release | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | `[--dry-run]` |
| `/monitor` | Check CI status and auto-fix failures | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | — |
| `/docs-sync` | Sync docs stale relative to changed source files | `Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | — |
| `/resolve` | Detect and resolve merge/rebase/cherry-pick conflicts | `Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | `[--status] [--abort]` |
| `/review` | AI-assisted code review — find bugs, security issues, and style concerns | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob` | `[PR-number] [--post]` |
| `/hotfix` | Emergency hotfix — branch from release tag, fix, validate, tag, cherry-pick | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Read, Write, Edit, Grep, Glob` | `[base-tag] [--dry-run]` |
| `/sync` | Sync branch with upstream — fetch, rebase/merge, handle conflicts | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob` | `[base-branch] [--merge] [--rebase]` |
| `/cleanup` | Clean up stale branches — delete merged locals, prune remotes | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob` | `[--dry-run] [--include-remote]` |
| `/sequence-diagram` | Generate Mermaid sequence diagrams from code or natural language | `Bash(git:*), Bash(cat:*), Read, Grep, Glob, Write, Edit` | `[file/path \| "description"] [--output file.md]` |

---

## Plugin Compatibility Gate

Before every ShipKit release, validate plugin metadata and command wiring against the latest Claude Code plugin requirements:

1. Validate `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` field compatibility with the current Claude Code docs.
2. Run an install smoke test from marketplace metadata in a clean repo.
3. Record the Claude Code version used for validation in `CHANGELOG.md` release notes.

---

## Config Schema (`.shipkit.json`)

### Schema Envelope and Versioning

```json
{
  "schemaVersion": 1
}
```

Versioning policy:

- `schemaVersion` defaults to `1` if omitted in v1.
- Additive fields are backward-compatible.
- Breaking changes require incrementing `schemaVersion` and adding a migration section in `README.md`.
- Unknown top-level keys fail validation with actionable errors (field name + allowed alternatives).

### Build Triggers

```json
"build": {
  "triggers": [
    {
      "watch": ["src/**", "lib/**"],
      "run": "npm run build",
      "stage": ["dist/"]
    }
  ]
}
```

When staged files match `watch` patterns → run `run` → stage `stage` files.

### Pre-Push Validation

```json
"validation": {
  "commands": [
    { "name": "Lint", "run": "npm run lint" },
    { "name": "Tests", "run": "npm test" }
  ]
}
```

### Sensitive File Detection

```json
"sensitive": {
  "patterns": [".env", ".env.*", "*.pem", "*.key", "credentials.json"],
  "keywords": ["secret", "credential", "token"],
  "files": ["auth.config.js", "db-migration.sql"]
}
```

`patterns` uses glob matching against file paths (use this for entries like `hooks/*`). `keywords` scans UTF-8 text files only (skip binaries, `.git/`, `node_modules/`, and files larger than 1 MB by default). `files` lists exact paths to always block. All three are checked; any match blocks the commit. Defaults apply even without config.

### Commit Conventions

```json
"commit": {
  "conventionalPrefixes": ["feat", "fix", "chore", "docs", "test", "refactor"],
  "coAuthor": null
}
```

`coAuthor` is a full trailer string (e.g. `"Co-authored-by: Name <email>"`) appended to every commit message, or `null`/absent to skip it entirely.

### Checksums (optional)

```json
"checksums": {
  "enabled": false,
  "file": "CHECKSUMS.sha256",
  "files": ["dist/main.js", "schema.json"]
}
```

### Documentation Dependency Map

```json
"docs": {
  "dependencyMap": [
    { "sources": ["src/**"], "docs": ["README.md", "docs/API.md"] },
    { "sources": ["config/"], "docs": ["docs/CONFIGURATION.md"] }
  ],
  "autoDetect": true
}
```

### Release

```json
"release": {
  "changelog": "CHANGELOG.md",
  "versionFiles": [
    { "path": "package.json", "type": "json", "jsonPath": "version" },
    { "path": "pyproject.toml", "type": "toml", "tomlPath": "project.version" },
    { "path": "Cargo.toml", "type": "toml", "tomlPath": "package.version" },
    { "path": "VERSION", "type": "text", "pattern": "^(\\d+\\.\\d+\\.\\d+)$" }
  ],
  "preRelease": ["npm run build", "npm test"],
  "releaseBranch": "main",
  "tagPrefix": "v"
}
```

**`preRelease` vs `validation.commands`**: `preRelease` runs only during `/release` as a version gate — must pass before any version bump or tag is created. `validation.commands` runs during every `/push` and `/ship-pr` as a quality gate. They may overlap (e.g. both run tests) and that's intentional.

### PR Configuration

```json
"pr": {
  "template": "## Summary\n{{summary}}\n\n## Test Plan\n{{testPlan}}",
  "baseBranch": "main",
  "branchPrefix": "{{type}}/{{slug}}",
  "allowExistingUnpushedCommits": false
}
```

`branchPrefix` is a format string. Available tokens: `{{type}}` (conventional commit type, e.g. `feat`), `{{slug}}` (kebab-cased commit summary). Example output: `feat/add-auth-middleware`. Set to `null` or omit to use the current branch.

`allowExistingUnpushedCommits` defaults to `false`. When `false`, `/ship-pr` aborts if the current branch already has unpushed commits before the command starts, preventing accidental inclusion of unrelated history.

### CI Monitoring

```json
"ci": {
  "provider": "github-actions",
  "maxFixCycles": 3,
  "failureHints": [
    { "pattern": "ENOSPC", "fix": "npm prune", "description": "Disk space issue" }
  ]
}
```

### Conflict Resolution

```json
"resolve": {
  "autoMode": false,
  "resolutionStrategy": "balanced",
  "autoSkipLowConfidence": true,
  "continueAfterResolve": true,
  "allowedOperations": ["merge", "rebase", "cherry-pick"],
  "ignorePatterns": ["*.lock", "package-lock.json", "yarn.lock"]
}
```

`autoMode`: if `true`, `--auto` is the default (apply without per-file prompts). Set `false` to disable the `--auto` flag entirely.

`resolutionStrategy`: influences AI resolution prompt. `"balanced"` = neutral synthesis; `"ours"` = prefer current branch when ambiguous; `"theirs"` = prefer incoming changes.

`autoSkipLowConfidence`: in auto mode, skip files where AI confidence is `low` rather than applying them. Defaults to `true`.

`continueAfterResolve`: after all conflicts are applied, prompt to continue the git operation. Set `false` to stop and require the user to run continuation manually.

`allowedOperations`: restrict `/resolve` to specific operation types. Useful to enforce manual handling of, for example, rebases.

`ignorePatterns`: glob patterns for files `/resolve` always skips (emits manual instruction). Lock files are in the default list because their conflicts should be regenerated by the package manager, not AI-merged.

### Code Review

```json
"review": {
  "focusAreas": ["bugs", "security", "performance", "style"],
  "severityThreshold": "suggestion",
  "ignorePaths": ["*.lock", "vendor/**", "dist/**", "*.min.js", "*.min.css"],
  "maxFileSize": 5000,
  "customRules": [
    {
      "pattern": "TODO|FIXME|HACK",
      "severity": "suggestion",
      "message": "Unresolved TODO/FIXME marker"
    }
  ],
  "autoPost": false
}
```

`focusAreas`: categories to analyze — `bugs`, `security`, `performance`, `style`. Subset to narrow reviews. `severityThreshold`: minimum severity to include in output — `"critical"`, `"warning"`, or `"suggestion"` (default, show all). `ignorePaths`: glob patterns for files to skip during review. `maxFileSize`: skip files exceeding this line count (default 5000). `customRules`: additional pattern-based checks with configurable severity. `autoPost`: if `true`, always post to PR (equivalent to always passing `--post`).

### Hotfix

```json
"hotfix": {
  "branchPrefix": "hotfix/",
  "targetBranches": ["main"],
  "skipCherryPick": false,
  "requireCleanCherryPick": true
}
```

`branchPrefix`: prefix for hotfix branch names (e.g. `hotfix/v1.2.4`). `targetBranches`: branches to cherry-pick the fix into after release (default `["main"]`). `skipCherryPick`: if `true`, skip the cherry-pick step entirely. `requireCleanCherryPick`: if `true` (default), abort cherry-pick on conflicts rather than pushing conflicted state.

### Branch Sync

```json
"sync": {
  "strategy": "rebase",
  "baseBranch": "main",
  "syncUpstream": true,
  "preferUpstream": false,
  "runValidationAfterSync": false,
  "autoStash": true
}
```

`strategy`: `"rebase"` (default for feature branches) or `"merge"` (default for main/develop). `baseBranch`: default base branch to sync against. `syncUpstream`: fetch from `upstream` remote if it exists (fork scenario). `preferUpstream`: rebase onto `upstream/<base>` instead of `origin/<base>`. `runValidationAfterSync`: run `validation.commands` after sync completes. `autoStash`: auto-stash dirty working tree before sync, restore after.

### Branch Cleanup

```json
"cleanup": {
  "protectedBranches": ["main", "master", "develop", "release/*", "hotfix/*"],
  "deleteRemote": false,
  "staleDays": 90,
  "autoConfirmLocal": false
}
```

`protectedBranches`: glob patterns for branches that are never deleted (current branch and remote default are always protected regardless of this list). `deleteRemote`: enable remote branch deletion when `--include-remote` is passed (default `false` — double gate). `staleDays`: branches with no activity beyond this threshold are highlighted as stale (default 90). `autoConfirmLocal`: skip confirmation prompt for local merged branch deletion (default `false`).

### Execution State (v2 — deferred)

> **v1 approach**: Instead of a checkpoint/resume system, v1 commands use **git-state idempotency** — each command checks the current state of git (tags, branches, remote refs, working tree) before performing side effects. For example, `/release` checks `git tag -l v1.2.3` instead of reading a checkpoint file. This is simpler, more robust, and accomplishes the same recovery goal without a stateful checkpoint system.
>
> The full checkpoint system below is deferred to v2 if real usage reveals a need for it.

```json
"execution": {
  "stateDir": ".shipkit/state",
  "resumeOnStart": true,
  "maxStateAgeDays": 7
}
```

`stateDir` stores per-command checkpoints. `resumeOnStart=true` means commands check for interrupted runs before performing side effects and offer resume-first behavior.

---

## Zero-Config Defaults

When `.shipkit.json` is absent:

| Feature         | Default                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| Sensitive files | `.env`, `*.pem`, `*.key`, `credentials.json`, `secrets.json`, `id_rsa`, `id_ed25519` + keyword matches |
| Build triggers  | None (skip)                                                                                            |
| Validation      | None (skip)                                                                                            |
| Commit prefixes | `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`                                               |
| Co-author       | None                                                                                                   |
| Checksums       | Disabled                                                                                               |
| Docs map        | Auto-detect (`README.md`, `docs/`, `CHANGELOG.md`)                                                     |
| Version files   | Auto-detect: `package.json` → `json`/`version`, `pyproject.toml` → `toml`/`project.version`, `Cargo.toml` → `toml`/`package.version` |
| Release branch  | `main`                                                                                                 |
| CI provider     | `github-actions`                                                                                       |
| Max fix cycles  | 3                                                                                                      |
| Conflict resolution | Interactive mode, balanced strategy, lock files always skipped |
| Review focus areas  | `["bugs", "security", "performance", "style"]`                                                         |
| Review severity     | `"suggestion"` (show all)                                                                              |
| Review ignored paths | `["*.lock", "vendor/**", "dist/**", "*.min.js", "*.min.css"]`                                         |
| Hotfix branch prefix | `"hotfix/"`                                                                                           |
| Hotfix targets      | `["main"]`                                                                                             |
| Sync strategy       | `"rebase"` for feature branches, `"merge"` for main/develop                                            |
| Sync base branch    | Auto-detect from PR → remote default → `main`                                                         |
| Sync auto-stash     | Enabled                                                                                                |
| Cleanup protected   | `["main", "master", "develop", "release/*", "hotfix/*"]`                                               |
| Cleanup remote del  | Disabled (requires `--include-remote` + config)                                                        |
| Cleanup stale days  | 90                                                                                                     |

Auto-detection checks for: `package.json` (node), `pyproject.toml` (python), `Cargo.toml` (rust), `go.mod` (go), `Makefile`, `.github/workflows/` (CI).

---

## Command Generalization Summary

### /commit

Auto-stage → exclude sensitive files → run build triggers if source files changed → regenerate checksums if enabled → review diff → generate conventional commit message → commit (never `--no-verify`)

### /push

Check for conflict markers first (`git status --porcelain` codes `UU AA DD AU UA DU UD`) → if any found, emit error ("Conflicts detected — cannot push with unresolved conflict markers. Run /resolve to resolve conflicts, then retry /push.") and exit with no changes → check unpushed commits → run validation commands → verify checksums if enabled → push (never `--no-verify`)

### /ship

Check for conflict state first (`.git/MERGE_HEAD`, `.git/rebase-merge/`, `.git/rebase-apply/`, `.git/CHERRY_PICK_HEAD`) → if any conflict operation is in progress, emit error ("Conflict operation in progress (<operation>). Resolve conflicts before shipping. Run /resolve to resolve conflicts, then retry /ship.") and exit with no changes.

`/commit` + `/push` composed. Decision tree:

1. **Dirty tree + unpushed commits** → run full `/commit` flow → then `/push` (pushes all commits including the new one)
2. **Dirty tree, nothing unpushed** → run full `/commit` flow → then `/push`
3. **Clean tree + unpushed commits** → skip `/commit`, run `/push` only
4. **Clean tree, nothing unpushed** → report "Nothing to ship" and exit cleanly

### /ship-pr

Record original branch + starting `HEAD` → check for pre-existing unpushed commits (abort unless `allowExistingUnpushedCommits=true`) → commit current changes → create branch from starting `HEAD` using prefix template → cherry-pick only commit(s) created by this run → validate → push → create PR via `gh` with template → return to original branch

### /pr-fix

**v1 scope**: Fix mode only, on the current branch (no worktree management). Fetch review comments via `gh api` → group by issue → fix on current branch → run build/validate → commit and push → reply to comments. Partial fixes are never pushed — if build/validate fails, the failure is reported inline without touching the remote.

> **v2 additions**: Watch (babysit) and all (all open PRs) modes. Worktree-based isolation for fixes. Checkpoint after each side-effect phase.

### /release

Parse version → pre-flight checks (clean tree, on `releaseBranch`, remote reachable, tag does not already exist) → gather commits since last tag → draft CHANGELOG → bump version in configured files → run pre-release commands → validate → **dry-run preview** (display: new version, full CHANGELOG diff, list of files to be modified, tag to be created) → **prompt for explicit confirmation** → commit → create local tag → push branch + tag → create GitHub Release via `gh`.

Failure and recovery rules:

- No writes occur before explicit confirmation.
- If local commit/tag creation fails, abort with no remote changes.
- If push fails, keep local commit/tag and print exact resume/rollback commands.
- If GitHub Release creation fails after push, do not auto-delete remote commit/tag; print explicit remediation (retry `gh release create` or manual cleanup commands).
- `--dry-run` exits after preview with zero writes.
- Recovery uses git-state idempotency: check `git tag -l`, `git log origin/main..HEAD`, and `gh release list` before each step.

### /monitor

**v1 scope**: Single-pass check-and-fix (not a persistent polling loop). Identify the latest CI run via `gh` → if still running, wait for completion (with a reasonable timeout) → diagnose failures (check `failureHints` first, then AI analysis) → fix → commit and push (never force-push) → report result. If push conflicts or branch protections block, stop immediately and print recovery instructions including: "Run /resolve if a merge conflict is present, then retry /monitor."

> **v2 additions**: Multi-cycle fix loop (up to `maxFixCycles`). Persistent polling mode. Per-cycle checkpoints. Structured summary on cycle exhaustion.

### /docs-sync

Determine changed files → match against dependency map → check for staleness → generate minimal edit proposals → user approval → apply

### /resolve

Invocation: `/resolve [--status] [--abort]`

**v1 scope**: Simplified conflict resolution — detect, show, AI-propose, accept/skip, continue. No `--auto` mode, no confidence scoring, no checkpoint system.

**v1 config keys**: `/resolve` reads `ignorePatterns`, `continueAfterResolve`, and `allowedOperations` from config. Keys `autoMode`, `resolutionStrategy`, and `autoSkipLowConfidence` are defined in the schema but ignored in v1 — if present, emit a one-line warning (e.g. "resolve.autoMode is a v2 feature and will be ignored") and continue.

**Prerequisites** (fail fast, no side effects): `git` installed and inside a git repo; a merge/rebase/cherry-pick is in progress.

**Step 1 — Conflict detection** (read-only): classify operation type from sentinel files (`.git/MERGE_HEAD` → merge, `.git/rebase-merge/` or `.git/rebase-apply/` → rebase, `.git/CHERRY_PICK_HEAD` → cherry-pick). List conflicted files from `git status --porcelain` (codes: `UU AA DD AU UA DU UD`). Emit summary.

**Step 2 — `--status` branch**: print summary and exit with no changes.

**Step 3 — `--abort` branch**: prompt confirmation → run `git <op> --abort` → exit.

**Step 4 — Per-file resolution loop**: for each conflicted file:
- **a. Read conflict markers** — extract `ours`, `theirs`, optional `base` (diff3), plus surrounding context.
- **b. Binary files** — skip with manual instruction (`git checkout --ours|--theirs <file>`).
- **c. Lock files / ignored patterns** — skip with regeneration instruction.
- **d. AI proposal** — produce resolved content and explanation.
- **e. Interactive review** — show conflict region and proposed resolution. Options: **Accept** / **Skip** / **Accept-ours** / **Accept-theirs**.
- **f. Apply** — write resolved file, `git add <file>`.

**Step 5 — Post-loop summary**: show applied / skipped counts. If any files still have conflict markers → print manual instructions.

**Step 6 — Git continuation**:

| Operation | Continue | Abort |
|-----------|----------|-------|
| merge | `git merge --continue` | `git merge --abort` |
| rebase | `git rebase --continue` | `git rebase --abort` |
| cherry-pick | `git cherry-pick --continue` | `git cherry-pick --abort` |

Never pass `--no-verify`. If a hook blocks continuation → surface hook output verbatim and stop without bypassing.

> **v2 additions**: `--auto` mode with confidence scoring (`high`/`medium`/`low`). `autoSkipLowConfidence` config. Conflict classification (`trivial-ours`, `trivial-theirs`, `additive`, `semantic`, `deletion-conflict`). Checkpoint/resume system. Multi-round rebase conflict handling (loop back to Step 1 after `--continue` produces new conflicts).

### /review

Invocation: `/review [PR-number] [--post]`

Determine review target (PR number arg → auto-detect PR on current branch via `gh pr view` → local diff against base branch) → gather diff content → filter ignored paths, binaries, lock files, generated files → analyze each changed file for bugs, security issues, performance problems, and style concerns → produce structured findings with severity (`critical` / `warning` / `suggestion`), category, file:line references, and fix suggestions → apply severity threshold filter → output formatted report → if `--post` flag and PR target exists, post findings as PR review comments via `gh api`.

Key rules:

- Read-only by default — no `Write`/`Edit` in allowed-tools. Output goes to console; `--post` writes via `gh` (already in allowed-tools).
- `--post` creates review comments in the same format `/pr-fix` consumes, enabling a `/review --post` → `/pr-fix` workflow.
- Base branch detection priority: PR base (if PR exists) → `pr.baseBranch` config → remote default → `main`.
- Severity threshold configurable via `review.severityThreshold`; default `"suggestion"` shows all.
- Skip binary files, lock files (`*.lock`), generated files (`dist/`, `vendor/`, `*.min.js`), and files exceeding `review.maxFileSize` lines.
- Idempotency for `--post`: check for existing review comments before posting duplicates.
- `--post` without a PR target: fail fast with "Cannot post review: no PR found."

### /hotfix

Invocation: `/hotfix [base-tag] [--dry-run]`

**Two-pass design**: First run creates branch and exits for user to apply fix. Second run (after fix is applied) continues from commit step.

Detect latest release tag (or use provided arg) → calculate patch version (increment patch of base tag) → create `hotfix/<version>` branch from tag → **first-run exit**: if no new changes since base tag, print instructions and exit → commit fix (compose `/commit` logic: stage, sensitive check, build triggers, conventional message) → run `validation.commands` and `release.preRelease` → bump version in configured files + update CHANGELOG with hotfix entry → **`--dry-run` exit**: display preview (base tag, new version, changed files, CHANGELOG diff, target cherry-pick branches) and exit with zero writes → tag (`git tag -a`) → push branch + tag → create GitHub Release via `gh` → cherry-pick fix commit(s) (NOT version bump) to each `hotfix.targetBranches` branch → if cherry-pick conflicts, stop with `/resolve` instruction → return to hotfix branch → print summary.

Key rules:

- Working tree must be clean at start (fail fast if dirty).
- Idempotent: check `git tag -l`, `git branch -l`, `gh release view` before each side effect.
- Cherry-pick only the fix commit(s) to target branches, not the version bump commit.
- If cherry-pick conflicts: stop and print "Run /resolve to resolve, then push manually." Never push conflicted state.
- Never force-push. Never `--no-verify`.

Failure and recovery:

- Validation failure: abort before version bump/tag, hotfix branch preserved for retry.
- Push failure: keep local tag, print exact retry commands.
- GitHub Release failure after push: do not auto-delete; print `gh release create` retry command.

### /sync

Invocation: `/sync [base-branch] [--merge] [--rebase]`

Check prerequisites (not detached HEAD, no conflict operation in progress) → determine base branch (explicit arg → PR base via `gh pr view` → `sync.baseBranch` config → `pr.baseBranch` config → remote default → `main`) → determine strategy (explicit flag → `sync.strategy` config → `"rebase"` for feature branches / `"merge"` for main/develop) → auto-stash dirty working tree if present → fetch origin (+ `upstream` remote if it exists and `sync.syncUpstream` is true) → check if sync needed (`git rev-list HEAD..origin/<base> --count`) → if zero, report "Already up to date" and restore stash → perform rebase or merge → if conflicts, invoke `/resolve` per-file resolution flow → after resolution, `git rebase --continue` or `git merge --continue` (never `--no-verify`) → for multi-step rebase, loop back to conflict resolution if new conflicts arise → optionally run `validation.commands` if `sync.runValidationAfterSync` is true → restore stashed changes (`git stash pop`) → print summary (strategy, base, commits integrated, conflicts resolved, stash status).

Key rules:

- Auto-stash/unstash dirty working tree (configurable via `sync.autoStash`, default true).
- Does NOT auto-push after sync — rebase rewrites history, user should verify first.
- Fork-aware: fetches from `upstream` remote if present.
- Both `--merge` and `--rebase` provided → fail fast.
- Stash pop conflict: print warning with `git stash show -p` instruction, do not abort sync.

### /cleanup

Invocation: `/cleanup [--dry-run] [--include-remote]`

`git fetch --prune origin` → determine protected branches (config `cleanup.protectedBranches` + current branch + default branch) → find merged local branches (`git branch --merged origin/<default>`, excluding protected) → find orphaned local branches (remote counterpart deleted after prune) → if `gh` available, check PR status for ambiguous branches (`gh pr list --head <branch> --state merged`) → print structured report (safe to delete / dangling / open PRs / protected) → **`--dry-run` exit** → prompt confirmation → delete local merged branches (`git branch -d`, never `-D`) → if `--include-remote` and `cleanup.deleteRemote` is true, delete remote merged branches with per-branch confirmation (`git push origin --delete`) → print advisory for dangling branches (last commit date, commits ahead of default) → print summary.

Key rules:

- Always uses `-d` (safe delete, only works for merged branches), never `-D`.
- Never deletes current branch or protected branches.
- Remote deletion requires both `--include-remote` CLI flag AND `cleanup.deleteRemote: true` in config — double gate.
- Per-branch confirmation for remote deletions.
- Shows last commit date and ahead-count for dangling branches.
- Stale threshold: branches with no activity for `cleanup.staleDays` (default 90) days get highlighted.

### /sequence-diagram

Invocation: `/sequence-diagram [file/path | "description"] [--output file.md]`

Generates Mermaid sequence diagrams using three input modes:

**Mode detection:**
- If argument is a valid file path or glob pattern → **code analysis mode**: read target files, trace function calls, API interactions, and inter-module communication, then produce a `sequenceDiagram` showing participants and message flow.
- If argument is quoted text or doesn't match a file → **natural language mode**: interpret the description, optionally explore the codebase for matching components, and generate a diagram from the description + codebase context.
- If no argument → **diff analysis mode**: read `git diff` (staged + unstaged), identify changed interaction patterns, and diagram the affected flows.

**Output:**
- Mermaid `sequenceDiagram` syntax in a fenced ` ```mermaid ` code block (renders natively on GitHub).
- Displayed inline by default.
- Written to file when `--output <path>` is specified (uses Write tool).

**Diagram elements:**
- `participant` declarations with aliases for readability.
- Labeled arrows (`->>`, `-->>`) showing method calls, HTTP requests, and messages.
- `alt`/`opt`/`loop` blocks for conditional, optional, and repeated flows.
- `Note` blocks for important context (auth checks, validation, side effects).
- Activation/deactivation bars (`activate`/`deactivate`) for long-running operations.

**Context preamble:**
```markdown
## Context
- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git diff: !`git diff --stat 2>/dev/null`
- Changed files: !`git diff --name-only 2>/dev/null`
```

Key rules:
- Code analysis traces across file boundaries — follows imports, function calls, and API routes to build the full interaction chain.
- Natural language mode uses codebase exploration (Grep, Glob, Read) to ground the diagram in actual component names and interfaces when possible.
- Diff mode focuses only on changed interaction flows, not the entire codebase.
- Output is always valid Mermaid syntax that renders on GitHub without modification.

---

## SpecOps Dogfood: Migration Path

SpecOps's own commands would be replaced by ShipKit + a `.shipkit.json`. Example config that reproduces all current SpecOps behavior:

```json
{
  "build": {
    "triggers": [
      {
        "watch": [
          "core/**",
          "generator/templates/**",
          "generator/generate.py",
          "platforms/*/platform.json"
        ],
        "run": "python3 generator/generate.py --all",
        "stage": ["platforms/", "skills/", ".claude-plugin/"]
      }
    ]
  },
  "validation": {
    "commands": [
      { "name": "Platform validation", "run": "python3 generator/validate.py" },
      {
        "name": "Checksum verification",
        "run": "shasum -a 256 -c CHECKSUMS.sha256"
      },
      {
        "name": "Generated freshness",
        "run": "python3 generator/generate.py --all && git diff --exit-code platforms/ skills/ .claude-plugin/"
      },
      {
        "name": "Schema structure",
        "run": "python3 tests/check_schema_sync.py"
      },
      { "name": "Test suite", "run": "bash scripts/run-tests.sh" }
    ]
  },
  "checksums": {
    "enabled": true,
    "file": "CHECKSUMS.sha256",
    "files": [
      "skills/specops/SKILL.md",
      "schema.json",
      "platforms/claude/SKILL.md",
      "..."
    ]
  },
  "sensitive": {
    "files": [
      "core/workflow.md",
      "core/safety.md",
      "schema.json",
      "generator/generate.py"
    ],
    "patterns": ["hooks/*"]
  }
}
```

---

## Installation

### Plugin Marketplace (primary)

```
/plugin marketplace add sanmak/shipkit
/plugin install shipkit
```

This is the recommended method. Commands appear as "(shipkit)" in `/help`, and updates are managed via the plugin system.

### Fallback: One-line installer

For users who prefer not to use the plugin system. Commands will appear as project-level commands, with no automatic updates.

```bash
# User-level (all projects) — installs to ~/.claude/commands/
curl -fsSL https://raw.githubusercontent.com/sanmak/shipkit/main/install.sh | bash -s -- --scope user

# Project-level — installs to .claude/commands/ in the current repo
curl -fsSL https://raw.githubusercontent.com/sanmak/shipkit/main/install.sh | bash -s -- --scope project
```

### Manual

Copy the 14 `.md` files from `commands/` into your project's `.claude/commands/`.

---

## Runtime Prerequisites

- `git` installed, repository initialized, and `origin` remote configured.
- `gh` CLI installed and authenticated (`gh auth status`) for `/ship-pr`, `/pr-fix`, `/release`, `/monitor`, `/review` (with `--post`), `/hotfix`, `/sync` (for PR base detection), and `/cleanup` (with `--include-remote`).
- Network access to GitHub for PR, release, and CI APIs.
- Any tool binaries referenced in user config commands (for example `npm`, `python3`, `bash`).

If prerequisites are missing, commands fail fast with a concrete install/auth message and no partial side effects.

---

## Interruption and Compaction Recovery

### v1: Git-State Idempotency (no checkpoint files)

Instead of a stateful checkpoint system, v1 commands are **idempotent by design** — they check the current state of git and external systems before performing side effects:

- **Commit**: check `git log` for a commit matching the expected message/content before creating a new one.
- **Tag**: check `git tag -l <tag>` before creating. If tag exists and points to expected commit, continue. If it points elsewhere, stop with manual remediation.
- **Push**: check `git log origin/<branch>..HEAD` — if empty, already pushed.
- **Branch**: check `git branch -l <name>` before creating.
- **PR/Release**: check via `gh pr list` / `gh release list` before creating duplicates.

If a command is interrupted (compaction, user abort), rerunning it will skip already-completed steps and resume from where it left off — without any state files.

### v2: Checkpoint System (deferred)

The full checkpoint system is deferred to v2 if real usage reveals cases where git-state idempotency is insufficient.

<details>
<summary>v2 checkpoint design (for reference)</summary>

- Checkpoints: write JSON state to `.shipkit/state/<command>-<runId>.json` after every side effect.
- Atomicity: checkpoint writes use temp-file + rename to avoid partial/corrupt state.
- Locking: one active run per command per repo using a lock file in `.shipkit/state/`.
- Resume: on command start, detect unfinished state and prompt `Resume` (default) or `Abort and cleanup`.
- Cleanup: completed checkpoints are retained for 7 days then pruned.

Minimum checkpoint fields:
- `runId`, `command`, `repoRoot`, `startedAt`, `updatedAt`
- `originalBranch`, `startHead`
- `phase`, `status`
- `createdCommits`, `createdTags`, `pushedRefs`
- `externalArtifacts` (for example PR number, release id)

</details>

---

## Relationship to SpecOps

**Independent but complementary:**

- **SpecOps** = spec-driven development (requirements → design → tasks → implementation)
- **ShipKit** = git workflow automation (commit, push, ship, release, monitor)

They coexist without conflict. SpecOps could recommend ShipKit during `/specops init`.

---

## Implementation Phases

### Phase 1: Foundation + Core Commands

1. Initialize git repo
2. Create `.claude-plugin/plugin.json` (valid fields only, per manifest reference)
3. Create `.claude-plugin/marketplace.json` (self-hosting format)
4. Create `schema.json` for `.shipkit.json` validation
5. Implement `/commit` — with frontmatter, config loading preamble, zero-config defaults
6. Implement `/push` — with conflict-marker gate, validation commands
7. Implement `/ship` — composed `/commit` + `/push` with 4-state decision tree
8. **Verify**: plugin installs correctly, commands appear in `/help`, zero-config works

### Phase 2: Conflict Resolution + PR Automation + Sync

1. Implement `/resolve` (v1 scope: detect → show → AI propose → accept/skip → continue)
2. Add conflict gates to `/push` and `/ship` (referencing `/resolve`)
3. Implement `/sync` — fetch, rebase/merge, auto-stash, conflict handling via `/resolve`
4. Implement `/ship-pr` — branch creation, commit, push, PR via `gh`
5. Implement `/pr-fix` — fix mode only, current branch, no worktree

### Phase 3: Operations

1. Implement `/release` — version bump, CHANGELOG, tag, push, GitHub Release, `--dry-run`
2. Implement `/docs-sync` — detect stale docs, propose edits
3. Implement `/monitor` — single-pass check-and-fix
4. Implement `/review` — AI code review, structured findings, optional PR posting via `--post`
5. Implement `/hotfix` — branch from tag, fix, validate, release, cherry-pick to targets
6. Implement `/cleanup` — prune remotes, delete merged locals, report dangling branches
7. Implement `/sequence-diagram` — Mermaid sequence diagrams from code analysis, natural language, or git diff

### Phase 4: Distribution + Polish

1. Create `examples/` directory with sample configs
2. Create `README.md` with installation, command reference, zero-config defaults, and a "Security" section noting that `validation.commands`, `preRelease`, and `build.triggers[].run` execute arbitrary shell commands with the user's permissions — users should review `.shipkit.json` before running commands in untrusted repos
3. Create `install.sh` as fallback installer
4. Add `LICENSE` and `CHANGELOG.md`
5. Create `scripts/validate-commands.sh` — validates all 14 command `.md` files have required YAML frontmatter fields (`description`, `allowed-tools`) and config loading preamble. Non-interactive, exits non-zero on failure.
6. Manual end-to-end testing of all 14 commands in a test repo
7. Finalize marketplace self-hosting or submit to official marketplace

### Phase 5: Advanced Features (v2, future)

1. Checkpoint/resume system (if real usage reveals need)
2. `/resolve --auto` mode with confidence scoring
3. `/pr-fix` watch and all modes with worktree management
4. `/monitor` multi-cycle polling loop
5. Multi-round rebase conflict handling in `/resolve`

---

## Verification (v1)

### Plugin Infrastructure
1. Install ShipKit via marketplace in a clean repo → commands appear as "(shipkit)" in `/help`.
2. Each command's `allowed-tools` is sufficient — no unexpected permission prompts during normal use.

### Core Commands
3. `/commit` in a repo with no `.shipkit.json` → stages, reviews, commits with conventional message (zero-config).
4. `/commit` with `.shipkit.json` containing build triggers and sensitive patterns → triggers fire, sensitive files blocked.
5. `/push` with validation commands configured → validations run before push.
6. `/push` with conflict markers present → fails fast with conflict message, no push attempted.
7. `/ship` correctly handles all 4 states (dirty/clean × pushed/unpushed) in the decision tree.
8. `/ship` with conflict operation in progress → fails fast with conflict message.

### Conflict Resolution
9. `/resolve --status` with no conflict in progress → fails fast with correct message, no changes.
10. `/resolve` during a `git merge` conflict → interactive prompt per file; accepting all produces a clean merge commit.
11. `/resolve --abort` during a rebase → `git rebase --abort` runs, working tree restored.
12. Binary file in conflict list → skipped with manual instruction; other files proceed normally.

### PR Automation
13. `/ship-pr` creates branch, commits, pushes, opens PR, returns PR URL.
14. `/ship-pr` with pre-existing unpushed commits → aborts by default.
15. `/pr-fix` fetches review comments and applies fixes on current branch.

### Operations
16. `/release --dry-run` shows preview with zero writes.
17. `/release` bumps version in `package.json`, updates CHANGELOG, creates tag and GitHub Release.
18. `/monitor` checks latest CI run, diagnoses failure, and applies fix.
19. `/docs-sync` detects stale docs and proposes edits.

### Code Review
20. `/review` with no PR and local changes → produces structured findings report to console.
21. `/review 42 --post` → fetches PR #42 diff, analyzes, posts review comments via `gh api`.
22. `/review` with no changes → "No changes detected. Nothing to review."

### Hotfix
23. `/hotfix` with no release tags → fails fast with "No release tags found."
24. `/hotfix` first run → creates `hotfix/v<patch>` branch, prints instructions, exits.
25. `/hotfix` second run (after fix applied) → commits, validates, bumps version, tags, pushes, creates release, cherry-picks to main.
26. `/hotfix --dry-run` → shows full preview with zero writes.
27. `/hotfix` cherry-pick conflict → stops with `/resolve` instruction, no push.

### Branch Sync
28. `/sync` on up-to-date branch → "Already up to date" with no changes.
29. `/sync` with dirty working tree → auto-stashes, syncs, restores stash.
30. `/sync` with rebase conflicts → invokes `/resolve` flow, continues after resolution.
31. `/sync --merge` on feature branch → uses merge strategy instead of default rebase.
32. Both `--merge` and `--rebase` → fails fast.

### Branch Cleanup
33. `/cleanup --dry-run` → shows report with zero deletions.
34. `/cleanup` with merged branches → prompts confirmation, deletes with `git branch -d`.
35. `/cleanup --include-remote` with `deleteRemote: false` → skips remote deletion with message.
36. Protected branches (`main`, `develop`, `release/*`) → never deleted.
37. Dangling branches → advisory with last commit date and ahead-count.

### Sequence Diagram
38.1. `/sequence-diagram src/auth/login.ts` → produces valid Mermaid `sequenceDiagram` with participants and message flow traced from code.
38.2. `/sequence-diagram "user login flow"` → generates Mermaid diagram from natural language, grounded in codebase components.
38.3. `/sequence-diagram` with uncommitted changes → produces diagram of changed interaction flows from git diff.
38.4. `/sequence-diagram src/api/orders.ts --output docs/orders-flow.md` → writes diagram to specified file with proper mermaid fencing.
38.5. Mermaid output renders correctly when pasted into a GitHub markdown file.

### Config Schema
38. Valid `.shipkit.json` passes validation; unknown keys fail with actionable errors.
39. Sensitive file detection works with path patterns, exact files, and keyword scanning.

## Definition of Done (v1)

1. Plugin and marketplace manifests use only valid Claude Code fields and install correctly via `/plugin install`.
2. All 14 command `.md` files have correct YAML frontmatter (`description`, `allowed-tools`) and config loading preamble.
3. `schema.json` includes `schemaVersion` rules and rejects invalid/unknown config with clear error output.
4. All 14 commands work in zero-config mode (no `.shipkit.json` required).
5. Recovery uses git-state idempotency — rerunning an interrupted command skips already-completed steps.
6. README documents prerequisites, command reference, zero-config defaults, and installation methods.
7. SpecOps dogfooding confirms migration parity for existing workflows.
