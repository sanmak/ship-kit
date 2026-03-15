# Feature: ShipKit v1 — Dev Workflow Automation Plugin for Claude Code

## Overview
ShipKit is a standalone Claude Code plugin that automates git workflows and developer productivity tasks. It uses a four-tier architecture — Commands, Skills, Agents, and Rules — to provide composable, configurable automation that any project can use via an optional `.shipkit.json` config file. The plugin ships 20 slash commands, 12 composable skills, 1 background agent, and 2 always-on coding rules.

## Developer Use Cases

### Use Case 1: Core Git Workflow (commit, push, ship)
**As a** developer using Claude Code
**I want** to commit, push, and ship code with automated quality gates
**So that** I can maintain consistent commit conventions, avoid pushing sensitive files, and reduce manual git ceremony

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/commit` THE SYSTEM SHALL stage files, check for sensitive file patterns, run configured build triggers, review the diff, generate a conventional commit message, and create the commit
- WHEN staged files match sensitive patterns (`.env`, `*.pem`, `*.key`, `credentials.json`) THE SYSTEM SHALL abort the commit with a list of blocked files
- WHEN staged files match build trigger watch patterns THE SYSTEM SHALL run the configured build command and stage the output files
- WHEN the developer invokes `/push` THE SYSTEM SHALL check for conflict markers, run configured validation commands, and push
- IF conflict markers are detected during `/push` THEN THE SYSTEM SHALL abort with "Run /resolve to fix conflicts"
- WHEN the developer invokes `/ship` with a dirty tree and unpushed commits THE SYSTEM SHALL stage-and-commit then validate-and-push
- WHEN the developer invokes `/ship` with a clean tree and unpushed commits THE SYSTEM SHALL skip commit and validate-and-push only
- WHEN the developer invokes `/ship` with a clean tree and nothing unpushed THE SYSTEM SHALL report "Nothing to ship"
- IF a conflict operation is in progress during `/ship` THEN THE SYSTEM SHALL abort with a conflict error

**Progress Checklist:**
- [ ] `/commit` stages, reviews, and commits with conventional message in zero-config mode
- [ ] `/commit` triggers builds and blocks sensitive files when configured
- [ ] `/push` validates and pushes, blocking on conflict markers
- [ ] `/ship` handles all 4 states (dirty/clean x pushed/unpushed)
- [ ] `/ship` detects active conflict operations and aborts

### Use Case 2: PR Automation (ship-pr, pr-fix)
**As a** developer using Claude Code
**I want** to create PRs and fix review comments without leaving the editor
**So that** I can streamline the PR lifecycle from branch creation to comment resolution

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/ship-pr` THE SYSTEM SHALL record the original branch, stage-and-commit, create a new branch from the starting HEAD using the configured prefix template, cherry-pick the new commits, validate-and-push, create a PR via `gh`, and return to the original branch
- IF the current branch has pre-existing unpushed commits and `allowExistingUnpushedCommits` is false THEN THE SYSTEM SHALL abort `/ship-pr`
- WHEN the developer invokes `/pr-fix [PR-number]` THE SYSTEM SHALL fetch review comments via `get-pr-comments`, group by issue, fix on the current branch, validate with `check-compiler-errors`, stage-and-commit, validate-and-push, and reply to comments
- IF validation fails during `/pr-fix` THEN THE SYSTEM SHALL report inline without pushing partial fixes

**Progress Checklist:**
- [ ] `/ship-pr` creates branch, commits, pushes, opens PR, returns URL
- [ ] `/ship-pr` aborts on pre-existing unpushed commits by default
- [ ] `/pr-fix` fetches comments, applies fixes, validates, commits, and pushes
- [ ] `/pr-fix` never pushes partial fixes

### Use Case 3: Release & Versioning (release, hotfix)
**As a** developer using Claude Code
**I want** to release versions and ship emergency hotfixes with automated changelog and tagging
**So that** releases are consistent, auditable, and recoverable

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/release` THE SYSTEM SHALL run pre-flight checks (clean tree, on release branch, remote reachable, tag doesn't exist), generate changelog, bump version, run pre-release commands, show a dry-run preview, prompt for confirmation, commit, tag, push, and create a GitHub Release
- WHEN `/release --dry-run` is invoked THE SYSTEM SHALL show the preview with zero writes
- WHEN the developer invokes `/hotfix` with no prior hotfix branch THE SYSTEM SHALL detect the latest release tag, calculate patch version, create the hotfix branch, and exit (two-pass design)
- WHEN the developer invokes `/hotfix` on an existing hotfix branch with new changes THE SYSTEM SHALL stage-and-commit, validate, bump version, generate changelog, tag, push, create GitHub Release, and cherry-pick to target branches
- IF cherry-pick conflicts occur during `/hotfix` THEN THE SYSTEM SHALL stop with `/resolve` instruction
- IF no release tags exist THEN THE SYSTEM SHALL fail fast on `/hotfix`

**Progress Checklist:**
- [ ] `/release` performs full release flow with confirmation gate
- [ ] `/release --dry-run` previews with zero writes
- [ ] `/hotfix` creates branch and exits on first run
- [ ] `/hotfix` completes full flow on second run
- [ ] `/hotfix` handles cherry-pick conflicts gracefully

### Use Case 4: CI & Monitoring (monitor, loop-on-ci)
**As a** developer using Claude Code
**I want** to monitor CI status and automatically iterate on failures
**So that** CI failures are resolved quickly without manual monitoring

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/monitor` THE SYSTEM SHALL check the latest CI run via `check-ci-status`, diagnose failures (checking `failureHints` first, then AI analysis), apply fixes, commit, and push
- WHEN the developer invokes `/loop-on-ci` THE SYSTEM SHALL loop up to `ci.maxFixCycles` times: check CI status, diagnose failures, apply fixes, commit, push, and wait for the new CI run
- WHEN all CI checks pass during `/loop-on-ci` THE SYSTEM SHALL report success and exit
- IF max fix cycles are exhausted THEN THE SYSTEM SHALL report remaining failures with manual remediation suggestions

**Progress Checklist:**
- [ ] `/monitor` checks CI, diagnoses, fixes, and pushes
- [ ] `/loop-on-ci` iterates up to maxFixCycles until green
- [ ] `/loop-on-ci` exits on success or exhaustion with clear reporting

### Use Case 5: Branch Management (sync, resolve, cleanup)
**As a** developer using Claude Code
**I want** to sync branches, resolve conflicts, and clean up stale branches
**So that** my branch state stays healthy without manual git operations

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/sync` THE SYSTEM SHALL determine the base branch, auto-stash if dirty, fetch, perform rebase or merge per strategy, invoke `resolve-conflicts` if needed, restore stash, and report
- WHEN the developer invokes `/resolve` during a merge conflict THE SYSTEM SHALL classify the operation type, list conflicted files, propose AI resolutions per file, allow interactive accept/skip/ours/theirs, apply resolutions, and run git continue
- WHEN the developer invokes `/resolve --status` THE SYSTEM SHALL print a read-only summary
- WHEN the developer invokes `/resolve --abort` THE SYSTEM SHALL prompt for confirmation and run `git <op> --abort`
- WHEN the developer invokes `/cleanup` THE SYSTEM SHALL fetch and prune, find merged/orphaned branches, check PR status, show report, confirm, and delete with `-d`
- WHILE protected branches are configured THE SYSTEM SHALL never delete them during `/cleanup`

**Progress Checklist:**
- [ ] `/sync` handles rebase/merge with auto-stash and conflict resolution
- [ ] `/resolve` performs interactive per-file conflict resolution
- [ ] `/resolve --status` and `--abort` work correctly
- [ ] `/cleanup` deletes merged branches, respects protected list
- [ ] `/cleanup --dry-run` reports with zero deletions

### Use Case 6: Code Review (review, pr-review-canvas)
**As a** developer using Claude Code
**I want** AI-assisted code review with structured findings and interactive PR walkthroughs
**So that** code quality issues are caught early with actionable feedback

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/review` THE SYSTEM SHALL gather the diff, filter ignored paths, check for sensitive files, analyze for bugs/security/performance/style, produce structured findings with severity, and output a report
- WHEN `/review [PR-number] --post` is invoked THE SYSTEM SHALL post review comments via `gh api` in a format consumable by `/pr-fix`
- WHEN the developer invokes `/pr-review-canvas [PR-number]` THE SYSTEM SHALL generate a self-contained HTML file with sidebar navigation, expandable diffs with syntax highlighting, inline annotations, summary statistics, and embedded review comment threads

**Progress Checklist:**
- [ ] `/review` produces structured findings report
- [ ] `/review --post` posts comments that `/pr-fix` can consume
- [ ] `/pr-review-canvas` generates valid self-contained HTML

### Use Case 7: Documentation (docs-sync)
**As a** developer using Claude Code
**I want** to detect and fix stale documentation automatically
**So that** docs stay in sync with code changes

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/docs-sync` THE SYSTEM SHALL match changed files against the docs dependency map, identify stale docs, propose edits, and apply after per-doc user approval

**Progress Checklist:**
- [ ] `/docs-sync` detects stale docs and proposes edits

### Use Case 8: Developer Productivity (what-did-i-get-done, weekly-review, deslop, sequence-diagram, run-smoke-tests)
**As a** developer using Claude Code
**I want** to summarize my work, generate diagrams, run smoke tests, and clean up AI-generated code slop
**So that** I can track productivity, communicate progress, and maintain code quality

**Acceptance Criteria (EARS):**
- WHEN the developer invokes `/what-did-i-get-done [period]` THE SYSTEM SHALL gather authored commits over the specified time range and format a concise status update grouped by conventional commit type
- WHEN the developer invokes `/weekly-review` THE SYSTEM SHALL gather commits for the past 7 days and format a categorized recap with PR links
- WHEN the developer invokes `/deslop [file|path]` THE SYSTEM SHALL scan for AI-generated code patterns, apply fixes, show before/after diff, confirm, and optionally commit
- WHEN the developer invokes `/sequence-diagram` with a file path THE SYSTEM SHALL trace function calls and produce a valid Mermaid `sequenceDiagram`
- WHEN the developer invokes `/sequence-diagram` with quoted text THE SYSTEM SHALL interpret the description, explore the codebase, and generate a diagram
- WHEN the developer invokes `/run-smoke-tests` THE SYSTEM SHALL run the configured test command, parse results, triage failures, and report with suggested fixes

**Progress Checklist:**
- [ ] `/what-did-i-get-done` produces concise commit summaries
- [ ] `/weekly-review` produces categorized weekly recap
- [ ] `/deslop` identifies and removes AI slop patterns
- [ ] `/sequence-diagram` generates valid Mermaid diagrams from code or text
- [ ] `/run-smoke-tests` runs tests and triages failures

### Use Case 9: Plugin Infrastructure & Distribution
**As a** developer installing ShipKit
**I want** the plugin to work out of the box with zero config and be installable via the marketplace
**So that** I can start using ShipKit immediately without setup friction

**Acceptance Criteria (EARS):**
- THE SYSTEM SHALL work in zero-config mode with sensible defaults for all features
- WHEN a `.shipkit.json` config file is present THE SYSTEM SHALL use its settings to override defaults
- THE SYSTEM SHALL be installable via `/plugin marketplace add sanmak/ship-kit` and `/plugin install ship-kit`
- THE SYSTEM SHALL display all 20 commands in `/help` with correct descriptions
- THE SYSTEM SHALL enforce two always-on rules: exhaustive switch handling for TypeScript and no inline imports
- THE SYSTEM SHALL validate its own plugin structure via CI on every push/PR
- WHEN a `v*` tag is pushed THE SYSTEM SHALL create a GitHub Release with notes extracted from CHANGELOG.md

**Progress Checklist:**
- [ ] Zero-config mode works for all commands
- [ ] `.shipkit.json` overrides defaults correctly
- [ ] Plugin installs via marketplace
- [ ] All 20 commands appear in `/help`
- [ ] Rules are active during code generation
- [ ] CI validates plugin structure
- [ ] Release workflow creates GitHub Releases

## API Design Principles
- All components are plain markdown files with YAML frontmatter — no build system
- Commands are the only user-facing entry points (appear in `/help`)
- Skills are internal building blocks callable by multiple commands
- Agents run autonomously in the background
- Rules apply passively during all code generation
- Config loading is handled at runtime via inline bash in each component

## Compatibility Requirements
- Target: Claude Code only (command format is Claude Code specific)
- Runtime: `git`, `gh` CLI, network access to GitHub
- Optional toolchains: `npm`, `node`, `python3`, `bash`, `make`, `tsc`, `npx`, `cargo`, `go`
- Distribution: Plugin marketplace (primary), one-line installer (fallback), manual copy

## Public API Surface

### Commands (20)

| Command | Invocation | Description |
|---------|-----------|-------------|
| `/commit` | `/commit` | Stage, review, and commit with conventional message |
| `/push` | `/push` | Validate and push unpushed commits |
| `/ship` | `/ship` | Commit and push in one step |
| `/ship-pr` | `/ship-pr` | Branch, commit, push, and open a PR |
| `/pr-fix` | `/pr-fix [PR-number]` | Fix PR review comments |
| `/release` | `/release [--dry-run]` | Bump version, changelog, tag, publish |
| `/monitor` | `/monitor` | Single-pass CI check-and-fix |
| `/loop-on-ci` | `/loop-on-ci` | Iterate CI fixes until green |
| `/docs-sync` | `/docs-sync` | Detect and fix stale docs |
| `/resolve` | `/resolve [--status] [--abort]` | Detect and resolve merge conflicts |
| `/review` | `/review [PR-number] [--post]` | AI-assisted code review |
| `/hotfix` | `/hotfix [base-tag] [--dry-run]` | Emergency hotfix workflow |
| `/sync` | `/sync [base-branch] [--merge] [--rebase]` | Sync branch with upstream |
| `/cleanup` | `/cleanup [--dry-run] [--include-remote]` | Clean up stale branches |
| `/sequence-diagram` | `/sequence-diagram [path\|"desc"] [--output file]` | Generate Mermaid diagrams |
| `/pr-review-canvas` | `/pr-review-canvas [PR-number]` | Interactive HTML PR walkthrough |
| `/run-smoke-tests` | `/run-smoke-tests [test-path]` | Playwright smoke tests + triage |
| `/what-did-i-get-done` | `/what-did-i-get-done [period]` | Commit summary over time range |
| `/weekly-review` | `/weekly-review` | Weekly recap with categorization |
| `/deslop` | `/deslop [file\|path]` | Remove AI-generated code slop |

### Skills (12)

| Skill | Called By |
|-------|----------|
| `stage-and-commit` | `/commit`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/hotfix`, `/deslop` |
| `validate-and-push` | `/push`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/release`, `/hotfix` |
| `resolve-conflicts` | `/resolve`, `/sync`, `/hotfix` |
| `check-ci-status` | `/monitor`, `/loop-on-ci`, `ci-watcher` agent |
| `get-pr-comments` | `/pr-fix`, `/review`, `/pr-review-canvas` |
| `check-compiler-errors` | `/pr-fix`, `/monitor`, `/loop-on-ci`, `/run-smoke-tests` |
| `bump-version` | `/release`, `/hotfix` |
| `generate-changelog` | `/release`, `/hotfix` |
| `detect-stale-docs` | `/docs-sync` |
| `detect-sensitive` | `/review`, `stage-and-commit` skill |
| `gather-commit-summary` | `/what-did-i-get-done`, `/weekly-review` |
| `manage-worktrees` | Deferred to v2 |

### Agent (1)

| Agent | Description |
|-------|-------------|
| `ci-watcher` | Monitor GitHub Actions, return pass/fail summaries, suggest fix workflows |

### Rules (2)

| Rule | Scope | Description |
|------|-------|-------------|
| `typescript-exhaustive-switch` | TypeScript files | Require exhaustive switch handling for union types and enums |
| `no-inline-imports` | All languages | Keep imports at module top-level |

## Constraints & Assumptions
- No binary dependencies — entirely markdown + JSON + shell script
- Never force-push, never `--no-verify`
- Sensitive file detection always blocks — no bypass
- Commands are idempotent by design (git-state based recovery)
- Phase 6 (advanced features: worktrees, checkpoints, auto-resolve) is deferred to v2

## Success Metrics
- All 20 commands operational with correct `allowed-tools` frontmatter
- All 12 skills composable and callable by multiple commands
- Zero-config mode works for all features
- CI pipeline validates plugin structure on every push/PR
- ShipKit can release itself using its own `/release` command (dogfooding)

## Out of Scope
- Checkpoint/resume system (v2)
- `/resolve --auto` mode with confidence scoring (v2)
- Worktree management system (v2)
- Multi-round rebase conflict handling (v2)
- Additional configurable rules (v2)
- Skill composition API with formal dependency declaration (v2)

## Team Conventions
- Use TypeScript for all new code
- Write unit tests for business logic with minimum 80% coverage
- Follow existing code style and patterns
- Use async/await instead of promises
- Document public APIs with JSDoc
- Keep functions small and focused (max 50 lines)
- Use meaningful variable and function names
- Handle errors explicitly, never silently fail
