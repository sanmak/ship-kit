# ShipKit v2: Dev Workflow Automation Plugin

## Context

ShipKit is a standalone Claude Code plugin that automates git workflows and developer productivity tasks. It uses a **four-tier architecture** — Commands, Skills, Agents, and Rules — to provide composable, configurable automation that any project can use via a `.shipkit.json` config file.

### Origin

Extracted from SpecOps's 8 custom slash commands, generalized and expanded. The v1 plan defined 14 monolithic commands. This v2 plan restructures them into a layered architecture that separates user-facing entry points (Commands) from reusable building blocks (Skills), long-running autonomous processes (Agents), and always-on coding conventions (Rules).

---

## Architecture: Four-Tier Component Model

### Tier 1 — Commands (User Entry Points)

Commands are what a developer types. They show up in `/help`, accept arguments, and orchestrate a workflow from start to finish. Each command is a `.md` file with YAML frontmatter.

**A command should:**

- Be invoked directly by a human via `/command-name`
- Orchestrate one or more skills into a complete workflow
- Handle argument parsing, flags, and user interaction
- Be the only tier that appears in `/help`

### Tier 2 — Skills (Composable Building Blocks)

Skills are reusable capabilities that commands (or agents, or other skills) call internally. They do one thing well and can be assembled into larger workflows.

**A skill should:**

- Perform a single, well-defined operation
- Be callable by multiple commands or agents
- Not assume a specific invocation context
- Return structured results that callers can act on

### Tier 3 — Agents (Long-Running Autonomous Processes)

Agents run in the background, monitor state, and take action autonomously. They differ from commands in that they persist beyond a single invocation.

**An agent should:**

- Run without blocking the user
- Monitor an external system (CI, PRs, etc.)
- Return concise summaries
- Feed results to skills or commands when action is needed

### Tier 4 — Rules (Always-On Coding Conventions)

Rules are coding standards that Claude enforces during any code generation or editing, not just during review. They are passive — they don't have an invocation, they shape behavior.

**A rule should:**

- Apply automatically during all code generation/editing
- Encode a single, clear convention
- Be enforceable without user invocation

### The Litmus Test

When categorizing a component:

1. **"Does a human type this to start a workflow?"** → Command
2. **"Does another command/agent need this capability internally?"** → Skill
3. **"Both?"** → Make it a **skill**, then create a **thin command** that wraps it
4. **"Does it run persistently in the background?"** → Agent
5. **"Does it apply passively to all code generation?"** → Rule

---

## Plugin Overview

| Attribute    | Value                                                              |
| ------------ | ------------------------------------------------------------------ |
| **Name**     | ShipKit                                                            |
| **Repo**     | `sanmak/ship-kit`                                                  |
| **Config**   | `.shipkit.json` (optional — zero-config works for simple projects) |
| **Commands** | 20 slash commands                                                  |
| **Skills**   | 12 composable building blocks                                      |
| **Agents**   | 1 long-running agent                                               |
| **Rules**    | 2 always-on coding conventions                                     |
| **Target**   | Claude Code only (commands format is Claude Code specific)         |
| **Install**  | Plugin marketplace + one-line installer script                     |

---

## Repository Structure

```
ship-kit/
  .claude-plugin/
    plugin.json                    # Plugin manifest (valid fields only)
    marketplace.json               # Self-hosting marketplace listing

  .github/
    workflows/
      ci.yml                      # Validate plugin structure on push/PR
      release.yml                  # Create GitHub Release on tag push (v*)
      codeql.yml                   # CodeQL security scanning (weekly + PR)
    ISSUE_TEMPLATE/
      bug_report.md                # Bug report template
      feature_request.md           # Feature request with tier selection
      config.yml                   # Disable blank issues, link to Discussions
    PULL_REQUEST_TEMPLATE.md       # PR template with checklist
    dependabot.yml                 # Auto-update GitHub Actions versions

  commands/                        # Tier 1: User-facing entry points
    commit.md                      # /commit → thin wrapper around stage-and-commit skill
    push.md                        # /push → thin wrapper around validate-and-push skill
    ship.md                        # /ship → composes stage-and-commit + validate-and-push
    ship-pr.md                     # /ship-pr → branch, commit, push, open PR
    pr-fix.md                      # /pr-fix → fetch comments, fix, push
    release.md                     # /release → version bump, changelog, tag, publish
    monitor.md                     # /monitor → single-pass CI check-and-fix
    loop-on-ci.md                  # /loop-on-ci → iterate CI fixes until green
    docs-sync.md                   # /docs-sync → detect/fix stale docs
    resolve.md                     # /resolve → thin wrapper around resolve-conflicts skill
    review.md                      # /review → structured code review
    hotfix.md                      # /hotfix → emergency branch, fix, release
    sync.md                        # /sync → fetch, rebase/merge, handle conflicts
    cleanup.md                     # /cleanup → prune stale branches
    sequence-diagram.md            # /sequence-diagram → generate Mermaid diagrams
    pr-review-canvas.md            # /pr-review-canvas → interactive HTML PR walkthrough
    run-smoke-tests.md             # /run-smoke-tests → Playwright smoke tests + triage
    what-did-i-get-done.md         # /what-did-i-get-done → commit summary over time range
    weekly-review.md               # /weekly-review → weekly recap with categorization
    deslop.md                      # /deslop → remove AI-generated code slop

  skills/                          # Tier 2: Reusable building blocks
    stage-and-commit.md            # Stage, sensitive check, build triggers, commit
    validate-and-push.md           # Run validations, check conflicts, push
    resolve-conflicts.md           # Detect + AI-propose + apply conflict resolution
    check-ci-status.md             # Query CI provider, parse results
    get-pr-comments.md             # Fetch + parse review comments from a PR
    check-compiler-errors.md       # Run compile/type-check, return structured failures
    bump-version.md                # Read version files, increment, write back
    generate-changelog.md          # Gather commits since tag, draft CHANGELOG entry
    detect-stale-docs.md           # Match changed files against docs dependency map
    detect-sensitive.md            # Check staged files against sensitive patterns
    gather-commit-summary.md       # Gather authored commits over time range, categorize by type
    manage-worktrees.md            # Create, find, lock, clean up git worktrees for parallel isolation

  agents/                          # Tier 3: Long-running autonomous processes
    ci-watcher.md                  # Monitor GitHub Actions, return pass/fail summaries

  rules/                           # Tier 4: Always-on coding conventions
    typescript-exhaustive-switch.md
    no-inline-imports.md

  examples/
    .shipkit.json                  # Standard config
    .shipkit.minimal.json          # Zero-config baseline
    .shipkit.full.json             # All options

  scripts/
    validate-components.sh         # Validate YAML frontmatter in all component .md files

  .shipkit.json                    # Dogfood config (ShipKit releases itself)
  schema.json                     # JSON Schema for .shipkit.json
  install.sh                      # Fallback installer (marketplace is primary)
  README.md
  CONTRIBUTING.md
  CODE_OF_CONDUCT.md
  SECURITY.md
  LICENSE
  CHANGELOG.md
```

**Key decisions**:

- `commands/`, `skills/`, and `agents/` are first-class plugin directories — explicitly declared in `plugin.json` via component path fields and auto-discovered by Claude Code.
- Rules live at `rules/` — passive, always-on conventions (not a plugin-native directory; loaded via convention).
- All component directories live at the plugin root, NOT inside `.claude-plugin/`. Only `plugin.json` and `marketplace.json` go in `.claude-plugin/`.
- No generator or build system. All components are plain markdown files with YAML frontmatter. All "logic" is prompt engineering.

---

## Complete Component Registry

### Commands (20)

| Command                | Invocation                                         | Composes Skills                                                                                        | Description                                           |
| :--------------------- | :------------------------------------------------- | :----------------------------------------------------------------------------------------------------- | :---------------------------------------------------- |
| `/commit`              | `/commit`                                          | `stage-and-commit`                                                                                     | Stage, review, and commit with conventional message   |
| `/push`                | `/push`                                            | `validate-and-push`                                                                                    | Validate and push unpushed commits                    |
| `/ship`                | `/ship`                                            | `stage-and-commit` + `validate-and-push`                                                               | Commit and push in one step                           |
| `/ship-pr`             | `/ship-pr`                                         | `stage-and-commit` + `validate-and-push`                                                               | Branch, commit, push, and open a PR                   |
| `/pr-fix`              | `/pr-fix [PR-number]`                              | `get-pr-comments` + `check-compiler-errors` + `stage-and-commit` + `validate-and-push`                 | Fix PR review comments                                |
| `/release`             | `/release [--dry-run]`                             | `bump-version` + `generate-changelog` + `validate-and-push`                                            | Bump version, CHANGELOG, tag, publish                 |
| `/monitor`             | `/monitor`                                         | `check-ci-status` + `check-compiler-errors`                                                            | Single-pass CI check-and-fix                          |
| `/loop-on-ci`          | `/loop-on-ci`                                      | `check-ci-status` + `check-compiler-errors` + `stage-and-commit` + `validate-and-push`                 | Watch CI and iterate on failures until green          |
| `/docs-sync`           | `/docs-sync`                                       | `detect-stale-docs`                                                                                    | Detect stale docs and propose edits                   |
| `/resolve`             | `/resolve [--status] [--abort]`                    | `resolve-conflicts`                                                                                    | Detect and resolve merge conflicts                    |
| `/review`              | `/review [PR-number] [--post]`                     | `get-pr-comments` + `detect-sensitive`                                                                 | AI-assisted code review                               |
| `/hotfix`              | `/hotfix [base-tag] [--dry-run]`                   | `stage-and-commit` + `bump-version` + `generate-changelog` + `validate-and-push` + `resolve-conflicts` | Emergency hotfix workflow                             |
| `/sync`                | `/sync [base-branch] [--merge] [--rebase]`         | `resolve-conflicts`                                                                                    | Sync branch with upstream                             |
| `/cleanup`             | `/cleanup [--dry-run] [--include-remote]`          | —                                                                                                      | Clean up stale branches                               |
| `/sequence-diagram`    | `/sequence-diagram [path\|"desc"] [--output file]` | —                                                                                                      | Generate Mermaid sequence diagrams                    |
| `/pr-review-canvas`    | `/pr-review-canvas [PR-number]`                    | `get-pr-comments`                                                                                      | Generate interactive HTML PR walkthrough              |
| `/run-smoke-tests`     | `/run-smoke-tests [test-path]`                     | `check-compiler-errors`                                                                                | Run Playwright smoke tests and triage                 |
| `/what-did-i-get-done` | `/what-did-i-get-done [period]`                    | `gather-commit-summary`                                                                                | Summarize authored commits over a time period         |
| `/weekly-review`       | `/weekly-review`                                   | `gather-commit-summary`                                                                                | Weekly recap with bugfix/tech-debt/net-new highlights |
| `/deslop`              | `/deslop [file\|path]`                             | `stage-and-commit`                                                                                     | Remove AI-generated code slop, clean up style         |

### Skills (12)

| Skill                   | Called By                                                                   | Description                                                                                                          |
| :---------------------- | :-------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------- |
| `stage-and-commit`      | `/commit`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/hotfix`, `/deslop` | Stage files, check sensitive patterns, run build triggers, review diff, generate conventional commit message, commit |
| `validate-and-push`     | `/push`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/release`, `/hotfix` | Check for conflict markers, run validation commands, verify checksums, push                                          |
| `resolve-conflicts`     | `/resolve`, `/sync`, `/hotfix`                                              | Detect conflict type, read markers, AI-propose resolution per file, interactive accept/skip, apply, git continue     |
| `check-ci-status`       | `/monitor`, `/loop-on-ci`, `ci-watcher` agent                               | Query CI provider via `gh`, parse run status, match `failureHints`, return structured results                        |
| `get-pr-comments`       | `/pr-fix`, `/review`, `/pr-review-canvas`                                   | Fetch review comments via `gh api`, group by file/issue, return structured data                                      |
| `check-compiler-errors` | `/pr-fix`, `/monitor`, `/loop-on-ci`, `/run-smoke-tests`                    | Run compile and type-check commands, parse output, return structured error list                                      |
| `bump-version`          | `/release`, `/hotfix`                                                       | Read version from configured files, calculate next version, write back                                               |
| `generate-changelog`    | `/release`, `/hotfix`                                                       | Gather commits since last tag, categorize, draft CHANGELOG entry                                                     |
| `detect-stale-docs`     | `/docs-sync`                                                                | Match changed files against docs dependency map, identify stale docs                                                 |
| `detect-sensitive`      | `/review`, `stage-and-commit` skill                                         | Check files against sensitive patterns (globs, keywords, exact paths)                                                |
| `gather-commit-summary` | `/what-did-i-get-done`, `/weekly-review`                                    | Gather authored commits over a time range, categorize by conventional type, return structured summary                |
| `manage-worktrees`      | `/pr-fix` (watch/all modes), `/hotfix` (optional)                           | Create, find, lock, and clean up deterministic git worktrees for isolated parallel operations                        |

### Agents (1)

| Agent        | Feeds Into                                                     | Description                                                                                                                 |
| :----------- | :------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------- |
| `ci-watcher` | `check-ci-status` skill → `/monitor` or `/loop-on-ci` commands | Monitor GitHub Actions runs in background, return concise pass/fail summaries, trigger fix workflows when failures detected |

### Rules (2)

| Rule                           | Scope            | Description                                                                                                                                 |
| :----------------------------- | :--------------- | :------------------------------------------------------------------------------------------------------------------------------------------ |
| `typescript-exhaustive-switch` | TypeScript files | Require exhaustive `switch` handling for union types and enums — every case must be handled or an explicit `default` with `never` assertion |
| `no-inline-imports`            | All languages    | Keep `import`/`require` statements at module top-level, never inline within functions or blocks                                             |

---

## Plugin Manifest (`.claude-plugin/plugin.json`)

```json
{
  "name": "ship-kit",
  "version": "1.0.0",
  "description": "Git workflow automation — commit, push, ship, release, review, and monitor from Claude Code",
  "author": {
    "name": "Sanket Makhija"
  },
  "repository": "https://github.com/sanmak/ship-kit",
  "homepage": "https://github.com/sanmak/ship-kit",
  "license": "MIT",
  "keywords": [
    "git",
    "workflow",
    "commit",
    "push",
    "release",
    "pr",
    "ci",
    "automation",
    "review",
    "productivity"
  ],
  "commands": "./commands/",
  "skills": "./skills/",
  "agents": "./agents/"
}
```

**Note**: Component paths (`commands`, `skills`, `agents`) are explicitly declared for clarity, though Claude Code also auto-discovers `./commands/` by convention. All paths are relative to the plugin root. Config loading is handled at runtime within each command/skill via inline bash.

## Marketplace Manifest (`.claude-plugin/marketplace.json`)

```json
{
  "name": "ship-kit-marketplace",
  "description": "ShipKit plugin marketplace",
  "plugins": [
    {
      "name": "ship-kit",
      "description": "Git workflow automation — commit, push, ship, release, review, and monitor from Claude Code",
      "source": "./"
    }
  ]
}
```

Users install via:

```
/plugin marketplace add sanmak/ship-kit
/plugin install ship-kit
```

---

## Command Format

Every command `.md` file **must** include YAML frontmatter with `description` and `allowed-tools`. Without `allowed-tools`, every bash/git invocation prompts the user for permission.

**Permission coverage**: ShipKit pre-authorizes common toolchains (`git`, `gh`, `npm`, `node`, `python3`, `bash`, `make`, `cargo`, `go`, `tsc`, `npx`) so most operations run without prompting. Commands that don't execute user-configured shell commands (e.g., `/resolve`, `/review`, `/cleanup`) use a minimal set. If a user's `.shipkit.json` configures commands using unlisted toolchains (e.g., `gradle`, `mvn`, `dotnet`, `ruby`), Claude Code will prompt for permission on first use. See the **Permissions & Prompts** section for full details.

### Frontmatter Template

```yaml
---
description: <one-line description shown in /help>
allowed-tools: Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob
argument-hint: <optional, for commands accepting arguments>
---
```

### Config Loading Preamble

Every command and skill must load config at the top using inline bash. Each component selects only the context lines it needs:

```markdown
## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`
```

### Skill Inclusion Pattern

Commands reference skills by including their instructions. Since Claude Code resolves all content at runtime, a command composes skills by inlining the relevant logic from the skill files:

```markdown
## Step 1: Stage and Commit

Follow the stage-and-commit skill procedure:
[Include stage-and-commit skill logic]

## Step 2: Validate and Push

Follow the validate-and-push skill procedure:
[Include validate-and-push skill logic]
```

### Per-Command Frontmatter

| Command                | `description`                                                     | `allowed-tools`                                                                                                                                              | `argument-hint`                                   |
| ---------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| `/commit`              | Stage, review, and commit with conventional message               | `Bash(git:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob`         | —                                                 |
| `/push`                | Validate and push unpushed commits                                | `Bash(git:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob`                         | —                                                 |
| `/ship`                | Commit and push in one step                                       | `Bash(git:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob`         | —                                                 |
| `/ship-pr`             | Commit, create PR branch, and open a pull request                 | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Grep, Glob` | —                                                 |
| `/pr-fix`              | Fetch PR review comments and fix them                             | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob` | `[PR-number]`                                     |
| `/release`             | Bump version, update CHANGELOG, tag, and publish release          | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Write, Edit, Grep, Glob` | `[--dry-run]`                                     |
| `/monitor`             | Check CI status and auto-fix failures                             | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob` | —                                                 |
| `/loop-on-ci`          | Watch CI runs and iterate on failures until checks pass           | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob` | —                                                 |
| `/docs-sync`           | Sync docs stale relative to changed source files                  | `Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob`                                                                                                   | —                                                 |
| `/resolve`             | Detect and resolve merge/rebase/cherry-pick conflicts             | `Bash(git:*), Bash(cat:*), Read, Write, Edit, Grep, Glob`                                                                                                   | `[--status] [--abort]`                            |
| `/review`              | AI-assisted code review with structured findings                  | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob`                                                                                                    | `[PR-number] [--post]`                            |
| `/hotfix`              | Emergency hotfix — branch, fix, validate, tag, cherry-pick        | `Bash(git:*), Bash(gh:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(npx:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob` | `[base-tag] [--dry-run]`                          |
| `/sync`                | Sync branch with upstream — fetch, rebase/merge, handle conflicts | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Edit, Grep, Glob`                                                                                       | `[base-branch] [--merge] [--rebase]`              |
| `/cleanup`             | Clean up stale branches — delete merged locals, prune remotes     | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob`                                                                                                    | `[--dry-run] [--include-remote]`                  |
| `/sequence-diagram`    | Generate Mermaid sequence diagrams from code or natural language  | `Bash(git:*), Bash(cat:*), Read, Grep, Glob, Write, Edit`                                                                                                   | `[file/path \| "description"] [--output file.md]` |
| `/pr-review-canvas`    | Generate an interactive HTML PR walkthrough with annotated diffs  | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Write, Grep, Glob`                                                                                             | `[PR-number]`                                     |
| `/run-smoke-tests`     | Run Playwright smoke tests and triage failures                    | `Bash(git:*), Bash(npx:*), Bash(cat:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob`                                              | `[test-path]`                                     |
| `/what-did-i-get-done` | Summarize authored commits over a given time period               | `Bash(git:*), Bash(cat:*), Read, Grep, Glob`                                                                                                                | `[period]`                                        |
| `/weekly-review`       | Generate weekly recap with bugfix/tech-debt/net-new highlights    | `Bash(git:*), Bash(gh:*), Bash(cat:*), Read, Grep, Glob`                                                                                                    | —                                                 |
| `/deslop`              | Remove AI-generated code slop and clean up code style             | `Bash(git:*), Bash(cat:*), Bash(shasum:*), Bash(npm:*), Bash(node:*), Bash(python3:*), Bash(python:*), Bash(bash:*), Bash(make:*), Read, Write, Edit, Grep, Glob` | `[file\|path]`                                    |

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

`patterns` uses glob matching against file paths. `keywords` scans UTF-8 text files only (skip binaries, `.git/`, `node_modules/`, and files larger than 1 MB by default). `files` lists exact paths to always block. All three are checked; any match blocks the commit. Defaults apply even without config.

### Commit Conventions

```json
"commit": {
  "conventionalPrefixes": ["feat", "fix", "chore", "docs", "test", "refactor"],
  "coAuthor": null
}
```

`coAuthor` is a full trailer string (e.g. `"Co-authored-by: Name <email>"`) appended to every commit message, or `null`/absent to skip.

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

**`preRelease` vs `validation.commands`**: `preRelease` runs only during `/release` as a version gate. `validation.commands` runs during every `/push` and `/ship-pr` as a quality gate. They may overlap and that's intentional.

### PR Configuration

```json
"pr": {
  "template": "## Summary\n{{summary}}\n\n## Test Plan\n{{testPlan}}",
  "baseBranch": "main",
  "branchPrefix": "{{type}}/{{slug}}",
  "allowExistingUnpushedCommits": false
}
```

`branchPrefix` tokens: `{{type}}` (conventional commit type), `{{slug}}` (kebab-cased summary). Set to `null` or omit to use current branch.

`allowExistingUnpushedCommits` defaults to `false`. When `false`, `/ship-pr` aborts if the current branch already has unpushed commits.

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

| Key                     | Description                                                            | Default                                        |
| :---------------------- | :--------------------------------------------------------------------- | :--------------------------------------------- |
| `autoMode`              | Apply resolutions without per-file prompts (v2 feature, ignored in v1) | `false`                                        |
| `resolutionStrategy`    | `"balanced"` / `"ours"` / `"theirs"` — influences AI resolution        | `"balanced"`                                   |
| `autoSkipLowConfidence` | In auto mode, skip low-confidence files (v2 feature)                   | `true`                                         |
| `continueAfterResolve`  | Prompt to continue git operation after all conflicts resolved          | `true`                                         |
| `allowedOperations`     | Restrict `/resolve` to specific operation types                        | `["merge", "rebase", "cherry-pick"]`           |
| `ignorePatterns`        | Glob patterns for files `/resolve` always skips                        | `["*.lock", "package-lock.json", "yarn.lock"]` |

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

### Hotfix

```json
"hotfix": {
  "branchPrefix": "hotfix/",
  "targetBranches": ["main"],
  "skipCherryPick": false,
  "requireCleanCherryPick": true
}
```

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

### Branch Cleanup

```json
"cleanup": {
  "protectedBranches": ["main", "master", "develop", "release/*", "hotfix/*"],
  "deleteRemote": false,
  "staleDays": 90,
  "autoConfirmLocal": false
}
```

### Smoke Tests

```json
"smokeTests": {
  "runner": "playwright",
  "command": "npx playwright test",
  "reportDir": "playwright-report",
  "retries": 1,
  "timeout": 60000
}
```

### Code Quality (Deslop)

```json
"codeQuality": {
  "slopPatterns": [
    "console.log",
    "// TODO: implement",
    "any",
    "as any"
  ],
  "ignoreFiles": ["*.test.ts", "*.spec.ts"],
  "autoFix": false
}
```

### Worktree Management

```json
"worktrees": {
  "dir": ".shipkit/worktrees",
  "lockDir": ".shipkit/locks",
  "maxLockAgeDays": 1,
  "cleanupOnSuccess": true,
  "branchPrefix": "shipkit/"
}
```

| Key                | Description                                                       | Default                |
| :----------------- | :---------------------------------------------------------------- | :--------------------- |
| `dir`              | Directory for ShipKit-managed worktrees, relative to repo root    | `".shipkit/worktrees"` |
| `lockDir`          | Directory for lock files, relative to repo root                   | `".shipkit/locks"`     |
| `maxLockAgeDays`   | Stale lock threshold in days (dead PID + age > threshold = stale) | `1`                    |
| `cleanupOnSuccess` | Automatically remove worktree after successful operation          | `true`                 |
| `branchPrefix`     | Prefix for ShipKit-created worktree branches                      | `"shipkit/"`           |

Worktrees use deterministic naming: `<context-type>-<context-id>` (e.g., `pr-42`, `hotfix-v1.2.1`, `branch-feat-login`). This ensures re-runs find and reuse existing worktrees without state files. Lock files use PID-based ownership with stale detection (`kill -0`). See `skills/manage-worktrees.md` for full protocol.

**Important**: `.shipkit/` must be added to `.gitignore`. The `manage-worktrees` skill warns if this entry is missing.

---

## Zero-Config Defaults

When `.shipkit.json` is absent:

| Feature             | Default                                                                                                                              |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Sensitive files     | `.env`, `*.pem`, `*.key`, `credentials.json`, `secrets.json`, `id_rsa`, `id_ed25519` + keyword matches                               |
| Build triggers      | None (skip)                                                                                                                          |
| Validation          | None (skip)                                                                                                                          |
| Commit prefixes     | `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`                                                                             |
| Co-author           | None                                                                                                                                 |
| Checksums           | Disabled                                                                                                                             |
| Docs map            | Auto-detect (`README.md`, `docs/`, `CHANGELOG.md`)                                                                                   |
| Version files       | Auto-detect: `package.json` → `json`/`version`, `pyproject.toml` → `toml`/`project.version`, `Cargo.toml` → `toml`/`package.version` |
| Release branch      | `main`                                                                                                                               |
| CI provider         | `github-actions`                                                                                                                     |
| Max fix cycles      | 3                                                                                                                                    |
| Conflict resolution | Interactive mode, balanced strategy, lock files always skipped                                                                       |
| Review focus        | `["bugs", "security", "performance", "style"]`                                                                                       |
| Review severity     | `"suggestion"` (show all)                                                                                                            |
| Review ignored      | `["*.lock", "vendor/**", "dist/**", "*.min.js", "*.min.css"]`                                                                        |
| Hotfix prefix       | `"hotfix/"`                                                                                                                          |
| Hotfix targets      | `["main"]`                                                                                                                           |
| Sync strategy       | `"rebase"` for feature branches, `"merge"` for main/develop                                                                          |
| Sync base           | Auto-detect from PR → remote default → `main`                                                                                        |
| Sync auto-stash     | Enabled                                                                                                                              |
| Cleanup protected   | `["main", "master", "develop", "release/*", "hotfix/*"]`                                                                             |
| Cleanup remote      | Disabled (requires `--include-remote` + config)                                                                                      |
| Cleanup stale       | 90 days                                                                                                                              |
| Smoke tests         | Playwright, `npx playwright test`                                                                                                    |
| Code quality        | `console.log`, TODO stubs, `as any`                                                                                                  |
| Worktree dir        | `.shipkit/worktrees`                                                                                                                 |
| Worktree locks      | `.shipkit/locks`                                                                                                                     |
| Worktree branch pfx | `shipkit/`                                                                                                                           |
| Worktree cleanup    | Auto-remove on success, stale lock threshold 1 day                                                                                   |

Auto-detection checks for: `package.json` (node), `pyproject.toml` (python), `Cargo.toml` (rust), `go.mod` (go), `Makefile`, `.github/workflows/` (CI).

---

## Skill Specifications

### `stage-and-commit`

**Purpose**: Stage files, enforce sensitive-file checks, run build triggers, review diff, generate conventional commit message, and commit.

**Called by**: `/commit`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/hotfix`

**Procedure**:

1. Auto-stage changed files (`git add -A` or selective staging based on context)
2. Call `detect-sensitive` skill — if any match, abort with list of blocked files
3. Check build triggers — if staged files match `watch` patterns, run `run` command, stage `stage` files
4. Regenerate checksums if enabled
5. Review diff (`git diff --cached`)
6. Generate conventional commit message using configured prefixes
7. Commit (never `--no-verify`)

**Returns**: Commit SHA, commit message, list of staged files

### `validate-and-push`

**Purpose**: Run validation commands, check for conflict markers, verify checksums, and push.

**Called by**: `/push`, `/ship`, `/ship-pr`, `/loop-on-ci`, `/release`, `/hotfix`

**Procedure**:

1. Check for conflict markers (`git status --porcelain` codes `UU AA DD AU UA DU UD`) — if any, abort with "Run /resolve to fix conflicts"
2. Check for unpushed commits (`git log origin/<branch>..HEAD`)
3. Run `validation.commands` in order — if any fail, abort with failure output
4. Verify checksums if enabled
5. Push (never `--no-verify`, never force-push)

**Returns**: Push result (success/failure), list of pushed commits

### `resolve-conflicts`

**Purpose**: Detect conflict type, read markers, AI-propose resolution per file, interactive accept/skip, apply, git continue.

**Called by**: `/resolve`, `/sync`, `/hotfix`

**Procedure**:

1. Classify operation from sentinel files (`.git/MERGE_HEAD` → merge, `.git/rebase-merge/` → rebase, `.git/CHERRY_PICK_HEAD` → cherry-pick)
2. List conflicted files from `git status --porcelain`
3. Per-file resolution loop:
   - Read conflict markers — extract `ours`, `theirs`, optional `base`
   - Binary files → skip with manual instruction
   - Lock files / ignored patterns → skip with regeneration instruction
   - AI proposal → produce resolved content and explanation
   - Interactive review → Accept / Skip / Accept-ours / Accept-theirs
   - Apply → write resolved file, `git add <file>`
4. Post-loop summary (applied / skipped counts)
5. Git continuation if `continueAfterResolve` is true

**Returns**: Applied count, skipped count, remaining conflicts (if any)

### `check-ci-status`

**Purpose**: Query CI provider, parse run results, match against `failureHints`.

**Called by**: `/monitor`, `/loop-on-ci`, `ci-watcher` agent

**Procedure**:

1. Identify latest CI run via `gh run list --limit 1`
2. If still running, wait for completion (with timeout)
3. Parse run status and job results
4. For failures, check `failureHints` patterns first
5. Return structured results with job names, statuses, and failure details

**Returns**: Run ID, overall status, per-job results, matched hints (if any)

### `get-pr-comments`

**Purpose**: Fetch and parse review comments from a PR.

**Called by**: `/pr-fix`, `/review`, `/pr-review-canvas`

**Procedure**:

1. Determine PR number (argument → auto-detect from current branch via `gh pr view`)
2. Fetch review comments via `gh api`
3. Group by file and issue
4. Parse into structured data (file, line, comment body, author, status)

**Returns**: List of grouped review comments with file/line references

### `check-compiler-errors`

**Purpose**: Run compile and type-check commands, parse output into structured error list.

**Called by**: `/pr-fix`, `/monitor`, `/loop-on-ci`, `/run-smoke-tests`

**Procedure**:

1. Auto-detect project type (TypeScript → `tsc --noEmit`, Rust → `cargo check`, Go → `go build`, etc.)
2. Run compile/type-check command
3. Parse output into structured errors (file, line, column, message, severity)
4. Return sorted by severity

**Returns**: List of compiler/type errors with file locations

### `bump-version`

**Purpose**: Read version from configured files, calculate next version, write back.

**Called by**: `/release`, `/hotfix`

**Procedure**:

1. Read current version from `release.versionFiles` (or auto-detect)
2. Calculate next version based on bump type (major/minor/patch)
3. Write new version to all configured version files
4. Return old and new version

**Returns**: Previous version, new version, list of modified files

### `generate-changelog`

**Purpose**: Gather commits since last tag, categorize, draft CHANGELOG entry.

**Called by**: `/release`, `/hotfix`

**Procedure**:

1. Find last release tag (`git describe --tags --abbrev=0`)
2. Gather commits since tag (`git log <tag>..HEAD`)
3. Categorize by conventional commit type (feat, fix, chore, etc.)
4. Draft CHANGELOG entry with version header and categorized items
5. Prepend to `release.changelog` file

**Returns**: CHANGELOG entry text, commit count by category

### `detect-stale-docs`

**Purpose**: Match changed files against docs dependency map, identify stale docs.

**Called by**: `/docs-sync`

**Procedure**:

1. Determine changed files (since last commit or configurable range)
2. Match against `docs.dependencyMap` source patterns
3. For matched sources, identify linked docs
4. Check if docs have been updated more recently than sources
5. Return list of stale doc files with their triggering source changes

**Returns**: List of stale docs with source-change context

### `detect-sensitive`

**Purpose**: Check files against sensitive patterns (globs, keywords, exact paths).

**Called by**: `stage-and-commit` skill, `/review` command

**Procedure**:

1. Load sensitive config (or use defaults)
2. Check file paths against `patterns` (glob match)
3. Check file paths against `files` (exact match)
4. Scan file contents against `keywords` (UTF-8 files only, skip binaries/large files)
5. Return list of matched files with match reason

**Returns**: List of sensitive file matches with type (pattern/file/keyword)

### `gather-commit-summary`

**Purpose**: Gather authored commits over a configurable time range, categorize by conventional commit type, and return a structured summary.

**Called by**: `/what-did-i-get-done`, `/weekly-review`

**Procedure**:

1. Determine current git user (`git config user.name` or `git config user.email`)
2. Gather authored commits over the specified time range (`git log --author=<user> --since=<start> --until=<end>`)
3. Parse each commit: extract SHA, message, conventional type (feat, fix, chore, etc.), scope, timestamp, files changed
4. Categorize commits by conventional type
5. Compute summary statistics: commit count per category, total files changed, insertions, deletions
6. Return structured data (categorized commits + stats)

**Returns**: Categorized commit list (grouped by type), per-category counts, aggregate stats (files changed, insertions, deletions)

---

## Agent Specification

### `ci-watcher`

**Purpose**: Monitor GitHub Actions runs in background, return concise pass/fail summaries, optionally trigger fix workflows.

**Feeds into**: `check-ci-status` skill → `/monitor` or `/loop-on-ci` commands

**Behavior**:

1. Poll `gh run list` at configurable interval (default: 30 seconds)
2. Track run state transitions (queued → in_progress → completed)
3. On completion, produce concise summary (run ID, status, duration, failed jobs)
4. On failure, surface failure details and suggest next action (`/monitor` or `/loop-on-ci`)
5. Continue monitoring until user stops or all runs are green

**Config**: Uses `ci.provider` and `ci.maxFixCycles` from `.shipkit.json`

---

## Rule Specifications

### `typescript-exhaustive-switch`

**Scope**: All TypeScript files

**Convention**: Every `switch` statement on a union type or enum must handle all cases. Either:

- Enumerate every member explicitly, or
- Include a `default` case with a `never` assertion: `default: { const _exhaustive: never = value; throw new Error(...); }`

**Enforcement**: During any code generation or editing involving TypeScript `switch` statements, Claude must verify exhaustiveness. If a case is missing, add it or add the `never` default.

### `no-inline-imports`

**Scope**: All languages with module import systems

**Convention**: All `import`, `require`, `from X import Y`, and equivalent statements must appear at the top of the module, never inside functions, conditionals, or blocks.

**Exceptions**: Dynamic `import()` expressions for code splitting are allowed inline when they return a Promise (lazy loading pattern).

**Enforcement**: During any code generation or editing, Claude must place imports at module top-level. If editing code that has inline imports, move them to the top.

---

## Command Specifications

### /commit

Thin wrapper around `stage-and-commit` skill.

**Procedure**: Load config → call `stage-and-commit` skill → report result.

### /push

Thin wrapper around `validate-and-push` skill.

**Procedure**: Load config → call `validate-and-push` skill → report result.

### /ship

Composes `stage-and-commit` + `validate-and-push` with state detection.

Check for conflict state first (`.git/MERGE_HEAD`, `.git/rebase-merge/`, `.git/rebase-apply/`, `.git/CHERRY_PICK_HEAD`) → if any, abort with conflict error.

Decision tree:

1. **Dirty tree + unpushed commits** → `stage-and-commit` → `validate-and-push` (pushes all)
2. **Dirty tree, nothing unpushed** → `stage-and-commit` → `validate-and-push`
3. **Clean tree + unpushed commits** → skip commit, `validate-and-push` only
4. **Clean tree, nothing unpushed** → "Nothing to ship"

### /ship-pr

Record original branch + starting `HEAD` → check for pre-existing unpushed commits (abort unless `allowExistingUnpushedCommits=true`) → `stage-and-commit` → create branch from starting `HEAD` using prefix template → cherry-pick only commit(s) created by this run → `validate-and-push` → create PR via `gh` with template → return to original branch.

### /pr-fix

Invocation: `/pr-fix [PR-number] [--watch] [--all]`

**Default (no flags)**: Call `get-pr-comments` skill → group by issue → fix on current branch → call `check-compiler-errors` skill to validate → `stage-and-commit` → `validate-and-push` → reply to comments. Partial fixes are never pushed — if validation fails, report inline without touching remote.

**`--watch` (v2)**: Call `manage-worktrees` ACQUIRE for the PR → fix comments in isolated worktree using `git -C` threading → poll for new comments at configured interval → on PR merge/close, call `manage-worktrees` REMOVE → exit. Main working directory is never touched.

**`--all` (v2)**: List open PRs with unresolved comments → for each PR, call `manage-worktrees` ACQUIRE → fix in parallel worktrees (each with independent locks) → call `manage-worktrees` RELEASE → report summary. Each PR gets its own deterministic worktree (`pr-<N>`).

### /release

Invocation: `/release [--dry-run]`

Parse version → pre-flight checks (clean tree, on `releaseBranch`, remote reachable, tag doesn't exist) → call `generate-changelog` skill → call `bump-version` skill → run pre-release commands → validate → **dry-run preview** (display new version, CHANGELOG diff, modified files, tag) → **prompt for confirmation** → `stage-and-commit` → create local tag → `validate-and-push` (branch + tag) → create GitHub Release via `gh`.

Failure and recovery:

- No writes before confirmation
- Push failure: keep local commit/tag, print resume/rollback commands
- GitHub Release failure after push: do not auto-delete, print remediation

### /monitor

Invocation: `/monitor`

Call `check-ci-status` skill → if passing, report success and exit → if failing, diagnose (check `failureHints` first, then AI analysis) → fix → `stage-and-commit` → `validate-and-push` → report result. Never force-push. If push conflicts, stop with recovery instructions.

### /loop-on-ci

Invocation: `/loop-on-ci`

Loop up to `ci.maxFixCycles` times:

1. Call `check-ci-status` skill → if green, report success and exit
2. Diagnose failures → call `check-compiler-errors` skill if relevant
3. Apply fixes
4. `stage-and-commit` → `validate-and-push`
5. Wait for new CI run to complete
6. Loop back to step 1

If max cycles exhausted, report remaining failures with manual remediation suggestions.

### /resolve

Invocation: `/resolve [--status] [--abort]`

Thin wrapper around `resolve-conflicts` skill.

**`--status`**: Call skill in read-only mode, print summary, exit.
**`--abort`**: Prompt confirmation → run `git <op> --abort` → exit.
**Default**: Call `resolve-conflicts` skill with full interactive flow.

v1 config keys used: `ignorePatterns`, `continueAfterResolve`, `allowedOperations`. Keys `autoMode`, `resolutionStrategy`, `autoSkipLowConfidence` are defined in schema but emit a warning and are ignored in v1.

### /review

Invocation: `/review [PR-number] [--post]`

Determine target (PR number → auto-detect → local diff) → gather diff → filter ignored paths, binaries, lock files → call `detect-sensitive` skill on changed files → analyze for bugs, security, performance, style → produce structured findings with severity/category/file:line/fix suggestions → apply severity threshold → output report → if `--post` and PR exists, post via `gh api`.

Key rules:

- Read-only by default
- `--post` creates comments in format `/pr-fix` consumes (enabling `/review --post` → `/pr-fix` workflow)
- Idempotent for `--post`: check for existing comments before posting duplicates

### /hotfix

Invocation: `/hotfix [base-tag] [--dry-run]`

**Two-pass design**: First run creates branch and exits. Second run (after fix applied) continues.

Detect latest release tag → calculate patch version → create `hotfix/<version>` branch → **first-run exit** if no new changes → `stage-and-commit` → run validations + pre-release → call `bump-version` + `generate-changelog` → **`--dry-run` exit** → tag → `validate-and-push` (branch + tag) → create GitHub Release → cherry-pick fix commits to `hotfix.targetBranches` → if cherry-pick conflicts, stop with `/resolve` instruction → return to hotfix branch → summary.

### /sync

Invocation: `/sync [base-branch] [--merge] [--rebase]`

Check prerequisites → determine base branch → determine strategy → auto-stash if dirty → fetch → check if sync needed → perform rebase or merge → if conflicts, call `resolve-conflicts` skill → continue after resolution → optionally run validations → restore stash → summary.

Key rules:

- Does NOT auto-push after sync
- Fork-aware (fetches `upstream` if present)
- Both `--merge` and `--rebase` → fail fast
- Stash pop conflict: warning only, don't abort sync

### /cleanup

Invocation: `/cleanup [--dry-run] [--include-remote]`

`git fetch --prune` → determine protected branches → find merged locals → find orphaned locals → check PR status via `gh` → print report → **`--dry-run` exit** → confirm → delete locals (`-d`, never `-D`) → if `--include-remote` and `deleteRemote: true`, delete remotes with per-branch confirmation → summary.

### /docs-sync

Call `detect-stale-docs` skill → for each stale doc, determine what changed in sources → generate minimal edit proposals → user approval per doc → apply edits.

### /sequence-diagram

Invocation: `/sequence-diagram [file/path | "description"] [--output file.md]`

Three modes:

- **Code analysis**: file path arg → trace function calls, API interactions → produce `sequenceDiagram`
- **Natural language**: quoted text arg → interpret + explore codebase → generate diagram
- **Diff analysis**: no arg → read `git diff` → diagram changed interaction flows

Output: valid Mermaid `sequenceDiagram` in fenced code block. Written to file with `--output`.

### /pr-review-canvas

Invocation: `/pr-review-canvas [PR-number]`

Determine PR → call `get-pr-comments` skill for existing comments → fetch full diff via `gh` → categorize changes (new files, modified, deleted, renamed) → annotate diffs with inline commentary (what changed, why it matters, potential issues) → generate self-contained HTML file with:

- Sidebar navigation by file
- Expandable diff sections with syntax highlighting
- Inline annotations as colored callouts
- Summary statistics (files changed, additions, deletions)
- Review comment threads embedded in context

Output: HTML file written to working directory (default: `pr-review-<number>.html`).

### /run-smoke-tests

Invocation: `/run-smoke-tests [test-path]`

Run configured smoke test command (default: `npx playwright test`) → parse results → call `check-compiler-errors` if compile failures detected → triage failures into categories (flaky, environment, genuine regression) → report with:

- Test name, file, line
- Failure type and error message
- Screenshot/trace links if available
- Suggested fix for genuine regressions

### /what-did-i-get-done

Invocation: `/what-did-i-get-done [period]`

Determine period (argument like `"today"`, `"this week"`, `"last 3 days"` → default: `"today"`) → call `gather-commit-summary` skill with the resolved time range → format the structured results into a concise status update grouped by category → include stats (commits, files changed, insertions, deletions).

### /weekly-review

Invocation: `/weekly-review`

Call `gather-commit-summary` skill with a 7-day time range → format results into categorized recap:

- **🚀 Net-new**: `feat` commits — new functionality shipped
- **🐛 Bugfixes**: `fix` commits — issues resolved
- **🔧 Tech debt**: `refactor`, `chore` commits — improvements and maintenance
- **📚 Docs**: `docs` commits — documentation updates
- **🧪 Tests**: `test` commits — test coverage changes

Generate formatted recap with PR links (if available via `gh`), highlight notable items, and include week-over-week comparison if previous week data is available.

### /deslop

Invocation: `/deslop [file|path]`

Scan target files for AI-generated code patterns ("slop"):

- Overly verbose comments that restate the code
- Unnecessary `console.log` / `print` statements
- Dead code and unused variables
- Overly defensive null checks that can't actually be null
- Generic error messages ("An error occurred")
- Redundant type assertions (`as any`, `as unknown as X`)
- Copy-paste artifacts (duplicate code blocks)
- Placeholder implementations (`// TODO: implement`)

Apply fixes → show before/after diff → confirm → `stage-and-commit` (or just save if `codeQuality.autoFix` is false).

---

## Plugin Compatibility Gate

Before every ShipKit release, validate plugin metadata and command wiring:

1. Validate `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` field compatibility with current Claude Code docs.
2. Run install smoke test from marketplace metadata in a clean repo.
3. Verify all commands appear in `/help` with correct descriptions.
4. Record Claude Code version used for validation in `CHANGELOG.md` release notes.

---

## Permissions & Prompts

ShipKit pre-authorizes common tools via `allowed-tools` in each command's YAML frontmatter so most operations run without prompting. This section documents what runs silently, what may still prompt, and where commands intentionally pause for user input.

### Pre-Authorized Toolchains

Commands that execute user-configured shell commands (build triggers, validation, pre-release) pre-authorize these common tool prefixes:

`git`, `gh`, `cat`, `shasum`, `npm`, `node`, `python3`, `python`, `bash`, `make`

Commands that run compiler/type-check auto-detection additionally pre-authorize:

`tsc`, `npx`, `cargo`, `go`

Commands that don't execute user-configured commands (e.g., `/resolve`, `/review`, `/cleanup`, `/sync`) use a minimal set (`git`, `gh`, `cat` only).

### What May Still Prompt

| Category | When It Happens | Example | Affected Commands |
| :--- | :--- | :--- | :--- |
| **Uncommon toolchains** | `.shipkit.json` configures commands using tools not in the pre-authorized list | `gradle build`, `mvn test`, `dotnet build`, `ruby script.rb`, `zig build` | Any command running `build.triggers`, `validation.commands`, or `release.preRelease` |
| **Text processing utilities** | Skills construct bash commands starting with a non-authorized binary | `jq '.version' package.json`, `awk '...' CHANGELOG.md`, `sed -i ...` | `/release`, `/hotfix` (version/changelog parsing) |
| **Worktree operations (v2)** | `manage-worktrees` skill creates directories, manages locks, checks PIDs | `mkdir -p .shipkit/worktrees/pr-42`, `rm -rf ...`, `kill -0 <PID>` | `/pr-fix --watch`, `/pr-fix --all`, `/hotfix` |

When a prompt appears, users can approve once per session. These are Claude Code permission prompts, not ShipKit bugs.

### Intentional Confirmation Points

These are **workflow confirmations** built into commands by design — safety gates, not permission prompts. They will always pause regardless of `allowed-tools` settings.

| Command | Confirmation Point | Why |
| :--- | :--- | :--- |
| `/release` | Preview before writes | Prevent accidental releases |
| `/release` | Confirm before push + tag | Final safety gate |
| `/hotfix` | First-run exit after branch creation | Two-pass design — apply fix, then re-run |
| `/resolve` | Per-file Accept / Skip / Accept-ours / Accept-theirs | User controls each conflict resolution |
| `/resolve --abort` | Confirm before aborting | Prevent accidental abort |
| `/cleanup` | Confirm before branch deletion | Prevent accidental deletion |
| `/cleanup --include-remote` | Per-branch remote confirmation | Extra safety for shared branches |
| `/docs-sync` | Per-doc approval before edit | User reviews proposed changes |
| `/deslop` | Review before committing | User reviews slop removal |
| `detect-sensitive` (skill) | Hard abort with blocked file list | Security gate — no bypass, must unstage |

### Fully Automated Commands

These commands run end-to-end without intentional confirmation points (assuming all tools are authorized):

`/commit`, `/push`, `/ship`, `/ship-pr`, `/monitor`, `/loop-on-ci`, `/what-did-i-get-done`, `/weekly-review`

---

## SpecOps Dogfood: Migration Path

SpecOps commands would be replaced by ShipKit + a `.shipkit.json`. Example config:

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
      "platforms/claude/SKILL.md"
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

### Option 1: Self-Hosted Marketplace (primary for launch)

ShipKit self-hosts as its own marketplace via the GitHub repo. Users add the marketplace, then install:

```
/plugin marketplace add sanmak/ship-kit
/plugin install ship-kit
```

Commands appear as "(ship-kit)" in `/help`. Updates managed via plugin system.

### Option 2: Official Anthropic Marketplace (goal)

Submit ShipKit to the Anthropic-curated marketplace for maximum discoverability. Users would install directly from the Discover tab in `/plugin` without adding a custom marketplace.

Submission via: `claude.ai/settings/plugins/submit` or `platform.claude.com/plugins/submit`

Once accepted, users install with just:

```
/plugin install ship-kit
```

### Option 3: One-line installer (fallback)

For users who prefer not to use the plugin system. Commands install as project-level or user-level commands with no automatic updates.

```bash
# User-level (all projects) — installs to ~/.claude/commands/
curl -fsSL https://raw.githubusercontent.com/sanmak/ship-kit/main/install.sh | bash -s -- --scope user

# Project-level — installs to .claude/commands/ in the current repo
curl -fsSL https://raw.githubusercontent.com/sanmak/ship-kit/main/install.sh | bash -s -- --scope project
```

### Option 4: Manual

Copy `.md` files from `commands/` into your project's `.claude/commands/`.

---

## Runtime Prerequisites

- `git` installed, repository initialized, and `origin` remote configured.
- `gh` CLI installed and authenticated for PR/release/CI commands.
- Network access to GitHub for PR, release, and CI APIs.
- Any tool binaries referenced in user config commands (`npm`, `python3`, `bash`, etc.).
- `npx` and Playwright for `/run-smoke-tests`.

If prerequisites are missing, commands fail fast with a concrete install/auth message and no partial side effects.

---

## Interruption and Recovery

### v1: Git-State Idempotency

Commands are idempotent by design — they check current state before performing side effects:

- **Commit**: check `git log` for matching commit before creating new one
- **Tag**: check `git tag -l <tag>` before creating
- **Push**: check `git log origin/<branch>..HEAD` — if empty, already pushed
- **Branch**: check `git branch -l <name>` before creating
- **PR/Release**: check via `gh pr list` / `gh release list` before creating duplicates

Rerunning an interrupted command skips completed steps and resumes from where it left off.

### v2: Checkpoint System (deferred)

Full checkpoint system deferred to v2 if real usage reveals cases where git-state idempotency is insufficient. Would use `.shipkit/state/<command>-<runId>.json` files with temp-file + rename atomicity.

---

## Relationship to SpecOps

**Independent but complementary:**

- **SpecOps** = spec-driven development (requirements → design → tasks → implementation)
- **ShipKit** = git workflow automation + developer productivity

They coexist without conflict. SpecOps could recommend ShipKit during `/specops init`.

---

## README.md

### Badges

Single line after `# ShipKit` heading:

```markdown
[![CI](https://github.com/sanmak/ship-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/sanmak/ship-kit/actions/workflows/ci.yml)
[![CodeQL](https://github.com/sanmak/ship-kit/actions/workflows/codeql.yml/badge.svg)](https://github.com/sanmak/ship-kit/actions/workflows/codeql.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Release](https://img.shields.io/github/v/release/sanmak/ship-kit)](https://github.com/sanmak/ship-kit/releases/latest)
[![GitHub Stars](https://img.shields.io/github/stars/sanmak/ship-kit)](https://github.com/sanmak/ship-kit/stargazers)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blueviolet)](https://github.com/sanmak/ship-kit)
```

Badge order: health signals (CI, CodeQL) → trust (license) → currency (release) → social proof (stars) → context (Claude Code plugin).

### Section Order

1. **Heading + Badges**
2. **Tagline**: "Git workflow automation for Claude Code — commit, push, ship, release, review, and monitor without leaving your editor."
3. **Overview**: What ShipKit is, zero-config value prop, four-tier architecture summary (2-3 sentences)
4. **Quick Start**: 3 installation methods (marketplace, one-line installer, manual)
5. **Prerequisites**: git, gh CLI, Claude Code
6. **Commands**: All 20 commands in a table, grouped by category:
   - Core Workflow (`/commit`, `/push`, `/ship`, `/ship-pr`)
   - Code Review & PR (`/pr-fix`, `/review`, `/pr-review-canvas`)
   - Release & Versioning (`/release`, `/hotfix`)
   - CI & Monitoring (`/monitor`, `/loop-on-ci`)
   - Branch Management (`/sync`, `/resolve`, `/cleanup`)
   - Documentation (`/docs-sync`)
   - Developer Productivity (`/what-did-i-get-done`, `/weekly-review`, `/deslop`, `/sequence-diagram`, `/run-smoke-tests`)
7. **Architecture**: Four-tier model with litmus test, skills reference table, agent description, rules list
8. **Configuration**: Zero-config defaults table + full `.shipkit.json` reference with all config sections
9. **Security Considerations**: Arbitrary shell execution warning — `.shipkit.json` allows configuring arbitrary shell commands via `build.triggers[].run`, `validation.commands[].run`, `release.preRelease[]`. These execute with the user's permissions. Users should review `.shipkit.json` before running commands in untrusted repos.
10. **Permissions & Prompts**: What runs silently (pre-authorized toolchains), what may still prompt (uncommon toolchains, text utilities, worktree ops), intentional confirmation points table, fully automated commands list.
11. **Contributing**: Points to CONTRIBUTING.md
12. **License**: MIT, links to LICENSE file

---

## Documentation Files

| File | Content |
|------|---------|
| `LICENSE` | MIT license, Copyright (c) 2026 Sanket Makhija |
| `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. Initial `[Unreleased]` section listing all 20 commands, 11 skills, 1 agent, 2 rules. Adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). |
| `CONTRIBUTING.md` | How to report bugs (link to issue templates), suggest features, add a command/skill (create `.md` in the right directory with YAML frontmatter), the four-tier litmus test, testing via `scripts/validate-components.sh`, conventional commit conventions, PR process, code of conduct reference. |
| `CODE_OF_CONDUCT.md` | [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Standard adoption with contact email. |
| `SECURITY.md` | Supported versions table (latest minor of current major only). Vulnerability reporting via email (not public issues). Security model: ShipKit executes shell commands from `.shipkit.json` by design. Scope: command injection beyond user config = vulnerability; user configuring a dangerous command in their own config = not a vulnerability. |

### GitHub Templates

| File | Content |
|------|---------|
| `.github/ISSUE_TEMPLATE/bug_report.md` | YAML frontmatter (`name: Bug Report`, `labels: bug`). Fields: Description, Steps to Reproduce, Expected/Actual Behavior, Environment (OS, Claude Code version, ShipKit version, install method), Config (redacted `.shipkit.json`). |
| `.github/ISSUE_TEMPLATE/feature_request.md` | YAML frontmatter (`name: Feature Request`, `labels: enhancement`). Fields: Problem, Proposed Solution, Tier checkboxes (Command / Skill / Agent / Rule / Config / Other), Alternatives Considered. |
| `.github/ISSUE_TEMPLATE/config.yml` | Disable blank issues. Link to GitHub Discussions for questions. |
| `.github/PULL_REQUEST_TEMPLATE.md` | Fields: Summary, Type checkboxes (New command / New skill / Bug fix / Documentation / CI/config / Other), Checklist (YAML frontmatter correct, `validate-components.sh` passes, README updated if needed, CHANGELOG updated under `[Unreleased]`), Test Plan. |

---

## CI/CD Pipeline

### Workflow 1: CI (`.github/workflows/ci.yml`)

**Trigger**: `push` to `main`, `pull_request` to `main`.

**Permissions**: `contents: read`

**Jobs**:

1. **Validate command frontmatter** — run `bash scripts/validate-components.sh commands`. Asserts every `.md` file in `commands/` has YAML frontmatter with `description` and `allowed-tools` fields.
2. **Validate skill/agent/rule files** — run `bash scripts/validate-components.sh skills`, `agents`, `rules`. Asserts files are non-empty with basic structure.
3. **Validate schema.json** — `python3 -c "import json; json.load(open('schema.json'))"` to verify valid JSON. Optionally validate it's valid JSON Schema using `jsonschema` package.
4. **Validate example configs** — `pip install jsonschema`, then validate each file in `examples/*.json` against `schema.json`.
5. **Validate plugin.json** — assert required fields (`name`, `version`, `description`) exist.
6. **Validate marketplace.json** — assert `plugins` array exists with at least one entry, each having `name` and `source`.
7. **Shellcheck install.sh** — `shellcheck install.sh`.
8. **Markdown lint** — uses `DavidAnson/markdownlint-cli2-action` on README, CONTRIBUTING, SECURITY, CHANGELOG, and all component `.md` files. **Advisory only** (`continue-on-error: true`).

### Workflow 2: Release (`.github/workflows/release.yml`)

**Trigger**: tag push `v*`.

**Permissions**: `contents: write`

**Steps**:

1. Extract version from tag (`${GITHUB_REF#refs/tags/}`)
2. Extract release notes from CHANGELOG.md — use `awk` to capture text between `## [x.y.z]` heading and the next `## [` heading. Write to `release-notes.md`.
3. Validate version match — assert `.claude-plugin/plugin.json` `version` field equals the tag version (without `v` prefix). Fail if mismatch.
4. Create GitHub Release — `gh release create` with `--notes-file release-notes.md` and `--verify-tag`. **Idempotent**: check `gh release view` first; skip creation if release already exists (supports dogfooding via `/release` command).

No binary artifacts attached. GitHub auto-includes source archives (`.tar.gz`, `.zip`).

### Workflow 3: CodeQL (`.github/workflows/codeql.yml`)

**Trigger**: `push` to `main`, `pull_request` to `main`, `schedule` weekly (Monday 06:00 UTC: `cron: '0 6 * * 1'`).

**Permissions**: `actions: read`, `contents: read`, `security-events: write`

**Language**: `javascript-typescript` (covers JSON schema files; shell script is covered by shellcheck in CI).

**Value**: Primarily badge signal and future-proofing. Minimal findings expected for a markdown-heavy repo. If CodeQL cannot find analyzable code, it may pass with zero results — this is fine.

### Dependabot (`.github/dependabot.yml`)

**Scope**: `github-actions` ecosystem only. No package dependencies exist.

**Schedule**: weekly.

Keeps GitHub Actions versions (e.g., `actions/checkout@v4`) up to date automatically via PRs.

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Validation Script: `scripts/validate-components.sh`

- Accepts a directory argument: `commands`, `skills`, `agents`, or `rules`
- Iterates over all `.md` files in the specified directory
- Extracts YAML frontmatter (text between first and second `---` lines) using `awk`
- For `commands/`: asserts `description` and `allowed-tools` fields exist in frontmatter
- For `skills/`, `agents/`, `rules/`: asserts file is non-empty and has at least a top-level heading
- Prints `PASS: <filename>` for each valid file
- Exits with non-zero status on any failure, printing `FAIL: <filename> — <reason>`
- No external dependencies beyond standard Unix tools (`awk`, `grep`)

---

## GitHub Releases

### Versioning Strategy

**Semantic Versioning** (`MAJOR.MINOR.PATCH`):

- **MAJOR**: Breaking changes to command behavior, config schema (`schemaVersion` bump), or skill interfaces
- **MINOR**: New commands, skills, config options, or features
- **PATCH**: Bug fixes, documentation improvements, prompt engineering refinements

**Initial version**: `v1.0.0`. Tag prefix: `v`.

### Release Flow

1. Update CHANGELOG.md — move items from `[Unreleased]` to `[x.y.z] - YYYY-MM-DD`
2. Update version in `.claude-plugin/plugin.json`
3. Commit: `chore: prepare release v1.0.0`
4. Tag: `git tag v1.0.0`
5. Push: `git push origin main --tags`
6. `release.yml` fires → extracts notes from CHANGELOG → validates version match → creates GitHub Release

**Or, using ShipKit's own `/release` command** (dogfooding): run `/release` in the ship-kit repo. The command bumps version, updates CHANGELOG, commits, tags, pushes, and creates the GitHub Release. The `release.yml` workflow fires as a secondary validation but skips release creation if it already exists.

### Dogfood Config

ShipKit's own `.shipkit.json` at the repo root:

```json
{
  "schemaVersion": 1,
  "release": {
    "changelog": "CHANGELOG.md",
    "versionFiles": [
      { "path": ".claude-plugin/plugin.json", "type": "json", "jsonPath": "version" }
    ],
    "preRelease": [],
    "releaseBranch": "main",
    "tagPrefix": "v"
  },
  "validation": {
    "commands": [
      {
        "name": "Validate components",
        "run": "bash scripts/validate-components.sh commands && bash scripts/validate-components.sh skills && bash scripts/validate-components.sh agents && bash scripts/validate-components.sh rules"
      },
      { "name": "Validate schema", "run": "python3 -c \"import json; json.load(open('schema.json'))\"" },
      { "name": "Shellcheck", "run": "shellcheck install.sh" }
    ]
  },
  "sensitive": {
    "patterns": [".env", "*.pem", "*.key"]
  },
  "commit": {
    "conventionalPrefixes": ["feat", "fix", "chore", "docs", "test", "refactor", "ci"]
  }
}
```

This enables the compelling dogfooding story: "ShipKit releases itself using its own `/release` command."

### No Binary Artifacts

Since ShipKit is entirely markdown + JSON + shell script, GitHub auto-attaches source archives. No additional assets need to be attached to releases.

---

## Implementation Phases

### Phase 1: Foundation + Core Skills

1. Initialize git repo
2. Create `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
3. Create `schema.json` for `.shipkit.json` validation
4. Create `LICENSE` (MIT), `CODE_OF_CONDUCT.md` (Contributor Covenant v2.1), `SECURITY.md`
5. Create `rules/typescript-exhaustive-switch.md` and `rules/no-inline-imports.md`
6. Implement skill: `detect-sensitive`
7. Implement skill: `stage-and-commit` (depends on `detect-sensitive`)
8. Implement skill: `validate-and-push`
9. Implement command: `/commit` (wraps `stage-and-commit`)
10. Implement command: `/push` (wraps `validate-and-push`)
11. Implement command: `/ship` (composes both skills with decision tree)
12. **Verify**: plugin installs, commands appear in `/help`, zero-config works

### Phase 2: Conflict Resolution + PR Automation + Sync

1. Implement skill: `resolve-conflicts`
2. Implement command: `/resolve` (wraps `resolve-conflicts`)
3. Add conflict gates to `/push` and `/ship`
4. Implement command: `/sync` (uses `resolve-conflicts` skill)
5. Implement skill: `get-pr-comments`
6. Implement command: `/ship-pr` (composes `stage-and-commit` + `validate-and-push`)
7. Implement command: `/pr-fix` (uses `get-pr-comments` + `stage-and-commit`)
8. **Verify**: conflict resolution flow, PR creation, PR fixing

### Phase 3: Release + Operations

1. Implement skill: `bump-version`
2. Implement skill: `generate-changelog`
3. Implement command: `/release` (composes `bump-version` + `generate-changelog` + `validate-and-push`)
4. Implement skill: `detect-stale-docs`
5. Implement command: `/docs-sync` (wraps `detect-stale-docs`)
6. Implement skill: `check-ci-status`
7. Implement skill: `check-compiler-errors`
8. Implement command: `/monitor` (uses `check-ci-status` + `check-compiler-errors`)
9. Implement command: `/review` (uses `get-pr-comments` + `detect-sensitive`)
10. Implement command: `/hotfix` (composes multiple skills)
11. Implement command: `/cleanup`
12. Implement command: `/sequence-diagram`
13. **Verify**: release flow, CI monitoring, code review, hotfix workflow

### Phase 4: Developer Productivity + Agent

1. Implement command: `/loop-on-ci` (composes `check-ci-status` + `check-compiler-errors` + `stage-and-commit` + `validate-and-push`)
2. Implement agent: `ci-watcher` (uses `check-ci-status` skill)
3. Implement command: `/pr-review-canvas` (uses `get-pr-comments`)
4. Implement command: `/run-smoke-tests` (uses `check-compiler-errors`)
5. Implement skill: `gather-commit-summary`
6. Implement command: `/what-did-i-get-done` (wraps `gather-commit-summary`)
7. Implement command: `/weekly-review` (wraps `gather-commit-summary` with 7-day window + PR links + formatting)
8. Implement command: `/deslop` (uses `stage-and-commit`)
9. **Verify**: CI loop, agent monitoring, HTML canvas, smoke tests, productivity reports, commit summaries

### Phase 5: Distribution + Polish

1. Create `examples/` directory with sample configs (`.shipkit.json`, `.shipkit.minimal.json`, `.shipkit.full.json`)
2. Create `README.md` (full structure: badges, tagline, overview, quick start, prerequisites, commands table, architecture, configuration, security, contributing, license)
3. Create `CONTRIBUTING.md` (bug reports, feature requests, adding components, litmus test, testing, commit conventions, PR process)
4. Create `CHANGELOG.md` (keep-a-changelog format, initial `[Unreleased]` section)
5. Create `install.sh` as fallback installer
6. Create `scripts/validate-components.sh` — validates YAML frontmatter in all component `.md` files
7. Create `.github/workflows/ci.yml` — validate plugin structure on push/PR (frontmatter, schema, examples, plugin manifests, shellcheck, markdown lint advisory)
8. Create `.github/workflows/release.yml` — create GitHub Release on tag push `v*` (extract CHANGELOG notes, validate version match, idempotent creation)
9. Create `.github/workflows/codeql.yml` — CodeQL security scanning (weekly + PR, `javascript-typescript` language)
10. Create `.github/ISSUE_TEMPLATE/bug_report.md`, `feature_request.md`, `config.yml`
11. Create `.github/PULL_REQUEST_TEMPLATE.md`
12. Create `.github/dependabot.yml` — auto-update GitHub Actions versions (weekly)
13. Create `.shipkit.json` at repo root (dogfood config — ShipKit releases itself)
14. Enable GitHub Discussions on the repo
15. Manual end-to-end testing in a test repo
16. First release: tag `v1.0.0`, verify `release.yml` creates GitHub Release with correct notes
17. Finalize self-hosted marketplace — verify `/plugin marketplace add sanmak/ship-kit` → `/plugin install ship-kit` works end-to-end
18. Submit to official Anthropic marketplace via `claude.ai/settings/plugins/submit` for broader discoverability

### Phase 6: Advanced Features (v2, future)

1. Checkpoint/resume system
2. `/resolve --auto` mode with confidence scoring
3. Worktree management system:
   a. Implement `manage-worktrees` skill (ACQUIRE, FIND, RELEASE, REMOVE, CLEANUP operations)
   b. Add `worktrees` config section to `schema.json`
   c. Update `/pr-fix` command with `--watch` and `--all` flags that use `manage-worktrees`
   d. Add `.gitignore` warning for `.shipkit/` directory
   e. Integrate `/cleanup --worktrees` flag for manual worktree garbage collection
4. Multi-round rebase conflict handling in `/resolve`
5. Additional rules (configurable rule sets per project)
6. Skill composition API (formal dependency declaration between skills)

---

## Verification

### Plugin Infrastructure

1. Install ShipKit via marketplace in a clean repo → commands appear as "(ship-kit)" in `/help`.
2. Each command's `allowed-tools` is sufficient — no unexpected permission prompts.
3. Skills are not directly visible in `/help` — they are internal building blocks.
4. Rules are active during all code generation sessions.

### Skills (internal correctness)

5. `stage-and-commit`: stages files, blocks sensitive files, runs build triggers, produces conventional commit.
6. `validate-and-push`: blocks on conflict markers, runs validations, pushes.
7. `resolve-conflicts`: detects operation type, proposes resolution, handles accept/skip/ours/theirs.
8. `check-ci-status`: returns structured CI results, matches `failureHints`.
9. `get-pr-comments`: returns grouped comments with file/line references.
10. `check-compiler-errors`: returns structured error list for TypeScript/Rust/Go/etc.
11. `bump-version`: correctly reads/writes version files across formats (JSON, TOML, text).
12. `generate-changelog`: categorizes commits, produces valid CHANGELOG entry.
13. `detect-stale-docs`: matches source changes to docs via dependency map.
14. `detect-sensitive`: matches via glob patterns, exact files, and keyword scanning.

### Core Commands

15. `/commit` in zero-config → stages, reviews, commits with conventional message.
16. `/commit` with build triggers and sensitive patterns → triggers fire, sensitive files blocked.
17. `/push` with validation commands → validations run before push.
18. `/push` with conflict markers → fails fast, no push.
19. `/ship` handles all 4 states (dirty/clean × pushed/unpushed).
20. `/ship` with conflict operation in progress → fails fast.

### Conflict Resolution

21. `/resolve --status` with no conflict → fails fast, no changes.
22. `/resolve` during merge conflict → interactive per-file resolution → clean merge commit.
23. `/resolve --abort` during rebase → `git rebase --abort`, tree restored.
24. Binary files in conflict → skipped with manual instruction.

### PR Automation

25. `/ship-pr` creates branch, commits, pushes, opens PR, returns URL.
26. `/ship-pr` with pre-existing unpushed commits → aborts by default.
27. `/pr-fix` fetches comments, applies fixes on current branch.

### Release + Operations

28. `/release --dry-run` shows preview with zero writes.
29. `/release` bumps version, updates CHANGELOG, creates tag and GitHub Release.
30. `/monitor` checks latest CI run, diagnoses failure, applies fix.
31. `/docs-sync` detects stale docs, proposes edits.

### Code Review

32. `/review` with local changes → structured findings report.
33. `/review 42 --post` → posts review comments via `gh api`.
34. `/review` with no changes → "Nothing to review."

### Hotfix

35. `/hotfix` with no release tags → fails fast.
36. `/hotfix` first run → creates branch, prints instructions, exits.
37. `/hotfix` second run → commits, validates, tags, pushes, creates release, cherry-picks.
38. `/hotfix --dry-run` → preview with zero writes.
39. `/hotfix` cherry-pick conflict → stops with `/resolve` instruction.

### Branch Sync

40. `/sync` on up-to-date branch → "Already up to date."
41. `/sync` with dirty tree → auto-stash, sync, restore.
42. `/sync` with rebase conflicts → `resolve-conflicts` skill invoked.
43. Both `--merge` and `--rebase` → fails fast.

### Branch Cleanup

44. `/cleanup --dry-run` → report with zero deletions.
45. `/cleanup` with merged branches → prompts, deletes with `-d`.
46. Protected branches → never deleted.

### Developer Productivity (new in v2)

47. `/loop-on-ci` iterates up to `maxFixCycles`, fixes and pushes each round, exits when green.
48. `/pr-review-canvas` generates valid self-contained HTML with navigable diffs.
49. `/run-smoke-tests` runs Playwright, triages failures by category.
50. `/what-did-i-get-done today` → concise summary of today's commits.
51. `/weekly-review` → categorized recap with PR links.
52. `/deslop` → identifies and removes AI slop patterns, shows before/after diff.
53. `/sequence-diagram src/auth.ts` → valid Mermaid `sequenceDiagram`.
54. `/sequence-diagram "login flow"` → diagram grounded in codebase components.

### Agent

55. `ci-watcher` polls CI, reports state transitions, suggests actions on failure.

### Worktree Management (v2)

56. `manage-worktrees` ACQUIRE creates worktree with deterministic name from PR number (e.g., `pr-42`).
57. `manage-worktrees` ACQUIRE reuses existing worktree on re-invocation (idempotent).
58. Lock file prevents concurrent operations on the same worktree; second ACQUIRE fails with clear error.
59. Stale lock (dead PID) is cleaned automatically on next ACQUIRE.
60. `manage-worktrees` CLEANUP removes orphaned worktrees and stale locks.
61. `manage-worktrees` REMOVE aborts if worktree has uncommitted or unpushed changes.
62. `/pr-fix 42 --watch` fixes comments in isolated worktree without touching main working directory.
63. `/pr-fix --all` creates parallel worktrees for multiple PRs with independent locks.
64. ShipKit worktrees (`.shipkit/worktrees/`) do not conflict with Claude Code worktrees (`.claude/worktrees/`).
65. Interrupted operation resumes by finding existing worktree deterministically (no state file needed).
66. `git -C <worktree-path>` threading works correctly for all skills (`stage-and-commit`, `validate-and-push`).

### Config Schema

67. Valid `.shipkit.json` passes validation; unknown keys fail with actionable errors.
68. Sensitive file detection works with patterns, exact files, and keyword scanning.

### Documentation

69. README renders correctly on GitHub with all 6 badges visible and linked.
70. All badge links resolve (CI, CodeQL, license, release, stars, Claude Code plugin).
71. CONTRIBUTING.md accurately describes the development workflow and four-tier litmus test.
72. SECURITY.md has valid contact information and clear scope definition.

### CI/CD

73. `ci.yml` passes on a clean checkout with all components present.
74. `ci.yml` fails when a command `.md` is missing `description` or `allowed-tools` in frontmatter.
75. `ci.yml` fails when `schema.json` is invalid JSON.
76. `ci.yml` fails when example configs don't validate against schema.
77. `release.yml` creates a GitHub Release when a `v*` tag is pushed.
78. `release.yml` correctly extracts release notes from CHANGELOG.md for the tagged version.
79. `release.yml` fails if `plugin.json` version doesn't match the tag.
80. `release.yml` is idempotent — handles case where `/release` command already created the release.
81. CodeQL runs without errors on weekly schedule and on PRs.
82. Dependabot creates PRs to update GitHub Actions versions.

### Dogfooding

83. Running `/release` in the ship-kit repo successfully releases ShipKit using its own commands.
84. `.shipkit.json` at repo root is valid against `schema.json`.

---

## Definition of Done (v1)

1. Plugin and marketplace manifests install correctly via `/plugin install`.
2. All 20 command `.md` files have correct YAML frontmatter (`description`, `allowed-tools`) and config loading preamble.
3. All 11 skill `.md` files are composable and callable by multiple commands.
4. Agent `ci-watcher` runs as a background process with configurable polling.
5. Rules are enforced during all code generation (not just during `/review`).
6. `schema.json` validates config with clear errors for unknown/invalid keys.
7. All components work in zero-config mode.
8. Recovery uses git-state idempotency.
9. README documents all four tiers: commands, skills, agents, rules — with badges, security section, and configuration reference.
10. CI pipeline validates plugin structure on every push/PR.
11. Release workflow creates GitHub Releases from CHANGELOG on tag push.
12. CodeQL scanning enabled with weekly schedule.
13. Dependabot configured for GitHub Actions updates.
14. GitHub Discussions enabled for community Q&A.
15. All documentation files present: CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, LICENSE, issue/PR templates.
16. SpecOps dogfooding confirms migration parity.
