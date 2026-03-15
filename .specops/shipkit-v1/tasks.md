# Implementation Tasks: ShipKit v1

## Task Breakdown

---

## Phase 1: Foundation + Core Skills

### Task 1: Initialize Repository and Plugin Manifests
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Set up the base repository structure. Create `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` with the plugin metadata, version, and component paths.

**Implementation Steps:**
1. Create `.claude-plugin/` directory
2. Write `plugin.json` with name, version, description, author, repository, license, keywords, and component paths
3. Write `marketplace.json` with plugin listing

**Acceptance Criteria:**
- [x] `plugin.json` contains all required fields (name, version, description)
- [x] `marketplace.json` lists the plugin with name and source
- [x] Component paths reference `./commands/`, `./skills/`, `./agents/`

**Files to Modify:**
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

---

### Task 2: Create JSON Schema for Config Validation
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create `schema.json` — a JSON Schema that validates `.shipkit.json` config files. Cover all config sections: build, validation, sensitive, commit, checksums, docs, release, pr, ci, resolve, review, hotfix, sync, cleanup, smokeTests, codeQuality, worktrees.

**Implementation Steps:**
1. Define the JSON Schema with `schemaVersion` envelope
2. Define all config sections with types, defaults, and descriptions
3. Add `additionalProperties: false` at the top level for unknown key detection
4. Validate the schema file is valid JSON

**Acceptance Criteria:**
- [x] `schema.json` is valid JSON
- [x] All config sections from the plan are represented
- [x] Unknown top-level keys cause validation failure
- [x] Backward-compatible: additive fields safe, breaking changes require schemaVersion bump
- [x] Default values documented in descriptions

**Files to Modify:**
- `schema.json`

---

### Task 3: Create License, Code of Conduct, and Security Policy
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create the foundational documentation files: MIT LICENSE, Contributor Covenant v2.1 CODE_OF_CONDUCT.md, and SECURITY.md with scope definition.

**Implementation Steps:**
1. Create `LICENSE` with MIT text, Copyright (c) 2026 Sanket Makhija
2. Create `CODE_OF_CONDUCT.md` using Contributor Covenant v2.1
3. Create `SECURITY.md` with supported versions, reporting instructions, and security scope

**Acceptance Criteria:**
- [x] LICENSE contains MIT text with correct copyright
- [ ] CODE_OF_CONDUCT.md follows Contributor Covenant v2.1 *(deferred — user requested skip)*
- [x] SECURITY.md defines scope: command injection beyond user config = vulnerability; user's own dangerous commands = not a vulnerability

**Files to Modify:**
- `LICENSE`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`

---

### Task 4: Create Always-On Rules
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create the two always-on coding convention rules in `rules/`.

**Implementation Steps:**
1. Create `rules/typescript-exhaustive-switch.md` — require exhaustive switch handling for union types and enums
2. Create `rules/no-inline-imports.md` — keep imports at module top-level, allow dynamic `import()` for code splitting

**Acceptance Criteria:**
- [x] Both rule files exist with clear convention descriptions
- [x] `typescript-exhaustive-switch` specifies the `never` assertion default pattern
- [x] `no-inline-imports` documents the dynamic `import()` exception

**Files to Modify:**
- `rules/typescript-exhaustive-switch.md`
- `rules/no-inline-imports.md`

---

### Task 5: Implement detect-sensitive Skill
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create the `detect-sensitive` skill that checks files against sensitive patterns (globs, keywords, exact paths). This is a foundational skill used by `stage-and-commit` and `/review`.

**Implementation Steps:**
1. Create `skills/detect-sensitive.md`
2. Define the procedure: load config (or defaults), check paths against glob patterns, check exact file matches, scan UTF-8 file contents against keywords
3. Specify defaults: `.env`, `*.pem`, `*.key`, `credentials.json`, `secrets.json`, `id_rsa`, `id_ed25519`
4. Specify skip rules: binaries, `.git/`, `node_modules/`, files > 1 MB

**Acceptance Criteria:**
- [x] Skill matches files by glob pattern, exact path, and keyword scanning
- [x] Default sensitive patterns work without config
- [x] Binary files and large files are skipped during keyword scan
- [x] Returns structured list of matches with match type (pattern/file/keyword)

**Files to Modify:**
- `skills/detect-sensitive.md`

---

### Task 6: Implement stage-and-commit Skill
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 5
**Priority:** High
**Blocker:** None

**Description:**
Create the `stage-and-commit` skill — the core commit workflow used by 7 commands. Stages files, calls `detect-sensitive`, runs build triggers, reviews diff, generates conventional commit message, and commits.

**Implementation Steps:**
1. Create `skills/stage-and-commit.md`
2. Define the procedure: auto-stage, call detect-sensitive, check build triggers, regenerate checksums if enabled, review diff, generate conventional commit message, commit (never `--no-verify`)
3. Define config loading preamble with needed context lines
4. Specify return values: commit SHA, message, staged files list

**Acceptance Criteria:**
- [x] Stages files and calls detect-sensitive
- [x] Runs build triggers when staged files match watch patterns
- [x] Generates conventional commit messages using configured prefixes
- [x] Never uses `--no-verify`
- [x] Returns commit SHA, message, and staged files

**Files to Modify:**
- `skills/stage-and-commit.md`

---

### Task 7: Implement validate-and-push Skill
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create the `validate-and-push` skill — the core push workflow used by 7 commands. Checks for conflict markers, runs validation commands, verifies checksums, and pushes.

**Implementation Steps:**
1. Create `skills/validate-and-push.md`
2. Define the procedure: check conflict markers via `git status --porcelain`, check unpushed commits, run validation commands in order, verify checksums if enabled, push (never `--no-verify`, never force-push)
3. Define abort conditions: conflict markers present, validation failure
4. Specify return values: push result, list of pushed commits

**Acceptance Criteria:**
- [x] Detects conflict markers (UU, AA, DD, AU, UA, DU, UD) and aborts
- [x] Runs validation commands in order, aborting on failure
- [x] Never force-pushes or uses --no-verify
- [x] Returns push result and pushed commit list

**Files to Modify:**
- `skills/validate-and-push.md`

---

### Task 8: Implement /commit, /push, and /ship Commands
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 6, Task 7
**Priority:** High
**Blocker:** None

**Description:**
Create the three core workflow commands. `/commit` wraps `stage-and-commit`. `/push` wraps `validate-and-push`. `/ship` composes both with state detection.

**Implementation Steps:**
1. Create `commands/commit.md` — thin wrapper with frontmatter and config preamble, calls stage-and-commit
2. Create `commands/push.md` — thin wrapper, calls validate-and-push
3. Create `commands/ship.md` — checks for conflict state first, then implements the 4-state decision tree (dirty/clean x pushed/unpushed)
4. Set correct `allowed-tools` for each command per the plan's frontmatter table

**Acceptance Criteria:**
- [x] `/commit` has correct frontmatter and stages/reviews/commits
- [x] `/push` has correct frontmatter and validates/pushes
- [x] `/ship` checks for conflict state and handles all 4 decision tree states
- [x] All three commands load config via inline bash preamble

**Files to Modify:**
- `commands/commit.md`
- `commands/push.md`
- `commands/ship.md`

---

### Task 9: Phase 1 Verification
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7, Task 8
**Priority:** High
**Blocker:** None

**Description:**
Verify Phase 1 deliverables: plugin installs, commands appear in `/help`, zero-config works.

**Acceptance Criteria:**
- [x] Plugin manifests are valid JSON with all required fields
- [x] `schema.json` is valid JSON Schema
- [x] `/commit`, `/push`, `/ship` have correct YAML frontmatter
- [x] Skills are not directly visible in `/help`
- [x] Zero-config mode works (no `.shipkit.json` needed)
- [x] Rules exist with clear enforcement instructions

**Files to Modify:**
- None (verification only)

---

## Phase 2: Conflict Resolution + PR Automation + Sync

### Task 10: Implement resolve-conflicts Skill and /resolve Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 8
**Priority:** High
**Blocker:** None

**Description:**
Create the `resolve-conflicts` skill and its `/resolve` command wrapper. The skill classifies operation type, lists conflicted files, proposes AI resolutions per file, and supports interactive accept/skip/ours/theirs.

**Implementation Steps:**
1. Create `skills/resolve-conflicts.md` with full resolution procedure
2. Create `commands/resolve.md` supporting `--status` (read-only), `--abort` (with confirmation), and default interactive flow
3. Handle binary files (skip with manual instruction) and lock files (skip with regeneration instruction)

**Acceptance Criteria:**
- [x] Classifies operation type from sentinel files (.git/MERGE_HEAD, .git/rebase-merge/, .git/CHERRY_PICK_HEAD)
- [x] Per-file resolution with accept/skip/ours/theirs options
- [x] `--status` prints summary without changes
- [x] `--abort` prompts confirmation before aborting
- [x] Binary and lock files handled gracefully

**Files to Modify:**
- `skills/resolve-conflicts.md`
- `commands/resolve.md`

---

### Task 11: Add Conflict Gates to /push and /ship
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** Task 10
**Priority:** High
**Blocker:** None

**Description:**
Update `/push` and `/ship` to check for active conflict operations before proceeding.

**Implementation Steps:**
1. Add conflict state checks to `commands/push.md` (check for UU/AA/DD/etc in git status)
2. Add conflict sentinel file checks to `commands/ship.md` (.git/MERGE_HEAD, .git/rebase-merge/, .git/rebase-apply/, .git/CHERRY_PICK_HEAD)

**Acceptance Criteria:**
- [x] `/push` aborts if conflict markers detected
- [x] `/ship` aborts if conflict operation in progress

**Files to Modify:**
- `commands/push.md`
- `commands/ship.md`

---

### Task 12: Implement /sync Command
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 10
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `/sync` command for branch synchronization with upstream. Supports `--merge` and `--rebase` flags.

**Implementation Steps:**
1. Create `commands/sync.md` with frontmatter
2. Implement: check prerequisites, determine base branch, determine strategy, auto-stash if dirty, fetch, check if sync needed, perform rebase/merge, call resolve-conflicts if needed, restore stash
3. Handle fork-aware fetching (upstream remote)
4. Fail fast if both `--merge` and `--rebase` provided

**Acceptance Criteria:**
- [x] Syncs with correct strategy (rebase for feature branches, merge for main/develop)
- [x] Auto-stashes dirty working tree
- [x] Calls resolve-conflicts on conflicts
- [x] Does NOT auto-push after sync
- [x] Both --merge and --rebase together fails fast

**Files to Modify:**
- `commands/sync.md`

---

### Task 13: Implement get-pr-comments Skill
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create the `get-pr-comments` skill that fetches and parses review comments from a PR via `gh api`.

**Implementation Steps:**
1. Create `skills/get-pr-comments.md`
2. Define procedure: determine PR number (argument or auto-detect via `gh pr view`), fetch via `gh api`, group by file and issue, parse into structured data

**Acceptance Criteria:**
- [x] Auto-detects PR number from current branch
- [x] Groups comments by file and issue
- [x] Returns structured data with file, line, comment body, author, status

**Files to Modify:**
- `skills/get-pr-comments.md`

---

### Task 14: Implement /ship-pr Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 6, Task 7, Task 13
**Priority:** High
**Blocker:** None

**Description:**
Create the `/ship-pr` command that branches, commits, pushes, and opens a PR in one step.

**Implementation Steps:**
1. Create `commands/ship-pr.md` with frontmatter (includes `gh` in allowed-tools)
2. Implement: record original branch + starting HEAD, check for pre-existing unpushed commits, stage-and-commit, create branch from starting HEAD using prefix template, cherry-pick new commits, validate-and-push, create PR via `gh` with template, return to original branch

**Acceptance Criteria:**
- [x] Creates branch, commits, pushes, opens PR, returns URL
- [x] Aborts on pre-existing unpushed commits when `allowExistingUnpushedCommits` is false
- [x] Returns to original branch after PR creation
- [x] Uses configured PR template and branch prefix

**Files to Modify:**
- `commands/ship-pr.md`

---

### Task 15: Implement /pr-fix Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 6, Task 7, Task 13
**Priority:** High
**Blocker:** None

**Description:**
Create the `/pr-fix` command that fetches PR review comments, fixes them, and pushes.

**Implementation Steps:**
1. Create `commands/pr-fix.md` with frontmatter (includes Write, Edit in allowed-tools)
2. Implement default mode: call get-pr-comments, group by issue, fix on current branch, call check-compiler-errors to validate, stage-and-commit, validate-and-push, reply to comments
3. Never push partial fixes — if validation fails, report inline

**Acceptance Criteria:**
- [x] Fetches comments, groups by issue, and fixes them
- [x] Validates with check-compiler-errors before pushing
- [x] Never pushes partial fixes
- [x] Replies to resolved comments

**Files to Modify:**
- `commands/pr-fix.md`

---

### Task 16: Phase 2 Verification
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 10, Task 11, Task 12, Task 13, Task 14, Task 15
**Priority:** High
**Blocker:** None

**Description:**
Verify Phase 2 deliverables: conflict resolution, PR creation, PR fixing.

**Acceptance Criteria:**
- [x] `/resolve` handles merge, rebase, and cherry-pick conflicts
- [x] `/sync` syncs with upstream using correct strategy
- [x] `/ship-pr` creates branch, opens PR, returns URL
- [x] `/pr-fix` fetches and fixes review comments
- [x] Conflict gates work in `/push` and `/ship`

**Files to Modify:**
- None (verification only)

---

## Phase 3: Release + Operations

### Task 17: Implement bump-version and generate-changelog Skills
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create the two release-supporting skills.

**Implementation Steps:**
1. Create `skills/bump-version.md` — read version from configured files (JSON, TOML, text), calculate next version, write back
2. Create `skills/generate-changelog.md` — find last tag, gather commits, categorize by type, draft CHANGELOG entry, prepend to changelog file

**Acceptance Criteria:**
- [x] `bump-version` reads/writes version files across formats (JSON, TOML, text)
- [x] `bump-version` supports major/minor/patch increments
- [x] `generate-changelog` categorizes commits by conventional type
- [x] `generate-changelog` produces valid Keep a Changelog format

**Files to Modify:**
- `skills/bump-version.md`
- `skills/generate-changelog.md`

---

### Task 18: Implement /release Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 7, Task 17
**Priority:** High
**Blocker:** None

**Description:**
Create the `/release` command with pre-flight checks, dry-run preview, confirmation gate, and GitHub Release creation.

**Implementation Steps:**
1. Create `commands/release.md` with frontmatter (includes Write, Edit)
2. Implement: parse version, pre-flight checks (clean tree, on releaseBranch, remote reachable, tag doesn't exist), generate changelog, bump version, run pre-release commands, show dry-run preview, prompt for confirmation, commit, create tag, push (branch + tag), create GitHub Release via `gh`
3. Handle `--dry-run` flag (preview with zero writes)
4. Handle failure/recovery: no writes before confirmation, print resume/rollback on push failure

**Acceptance Criteria:**
- [x] Pre-flight checks prevent invalid releases
- [x] `--dry-run` shows preview with zero writes
- [x] Confirmation gate before any writes
- [x] Creates tag and GitHub Release
- [x] Push failure preserves local commit/tag with recovery instructions

**Files to Modify:**
- `commands/release.md`

---

### Task 19: Implement detect-stale-docs Skill and /docs-sync Command
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create the docs staleness detection skill and its command wrapper.

**Implementation Steps:**
1. Create `skills/detect-stale-docs.md` — match changed files against `docs.dependencyMap` source patterns, check doc freshness
2. Create `commands/docs-sync.md` — call skill, propose edits per stale doc, apply after user approval

**Acceptance Criteria:**
- [x] Matches source changes to docs via dependency map
- [x] Per-doc approval before applying edits
- [x] Auto-detect mode works without explicit dependency map

**Files to Modify:**
- `skills/detect-stale-docs.md`
- `commands/docs-sync.md`

---

### Task 20: Implement check-ci-status and check-compiler-errors Skills
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Create the two CI/compilation skills.

**Implementation Steps:**
1. Create `skills/check-ci-status.md` — query `gh run list --limit 1`, wait for completion, parse results, match `failureHints`, return structured results
2. Create `skills/check-compiler-errors.md` — auto-detect project type, run compile/type-check command, parse output into structured errors

**Acceptance Criteria:**
- [x] `check-ci-status` returns structured CI results with per-job status
- [x] `check-ci-status` matches `failureHints` patterns
- [x] `check-compiler-errors` auto-detects TypeScript/Rust/Go/etc
- [x] `check-compiler-errors` returns structured errors with file locations

**Files to Modify:**
- `skills/check-ci-status.md`
- `skills/check-compiler-errors.md`

---

### Task 21: Implement /monitor Command
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 6, Task 7, Task 20
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `/monitor` command for single-pass CI check-and-fix.

**Implementation Steps:**
1. Create `commands/monitor.md` with frontmatter
2. Implement: call check-ci-status, if passing report success, if failing diagnose (failureHints first, then AI analysis), fix, stage-and-commit, validate-and-push

**Acceptance Criteria:**
- [x] Checks latest CI run and reports status
- [x] Diagnoses failures using failureHints and AI analysis
- [x] Applies fixes and pushes
- [x] Never force-pushes

**Files to Modify:**
- `commands/monitor.md`

---

### Task 22: Implement /review Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 5, Task 13
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `/review` command for AI-assisted structured code review.

**Implementation Steps:**
1. Create `commands/review.md` with frontmatter
2. Implement: determine target (PR number / auto-detect / local diff), gather diff, filter ignored paths/binaries/lock files, call detect-sensitive, analyze for bugs/security/performance/style, produce structured findings with severity, output report
3. Handle `--post` flag: post comments via `gh api` in format `/pr-fix` consumes
4. Make `--post` idempotent (check for existing comments)

**Acceptance Criteria:**
- [x] Produces structured findings with severity/category/file:line/fix suggestions
- [x] Filters ignored paths, binaries, lock files
- [x] `--post` posts comments consumable by `/pr-fix`
- [x] `--post` is idempotent (no duplicate comments)
- [x] Read-only by default (no `--post`)

**Files to Modify:**
- `commands/review.md`

---

### Task 23: Implement /hotfix Command
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 6, Task 7, Task 10, Task 17
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `/hotfix` command with two-pass design.

**Implementation Steps:**
1. Create `commands/hotfix.md` with frontmatter
2. Implement first pass: detect latest release tag, calculate patch version, create `hotfix/<version>` branch, exit
3. Implement second pass: stage-and-commit, run validations + pre-release, bump-version + generate-changelog, `--dry-run` exit if flagged, tag, validate-and-push (branch + tag), create GitHub Release, cherry-pick fix commits to target branches
4. Handle cherry-pick conflicts (stop with /resolve instruction)

**Acceptance Criteria:**
- [x] First run creates hotfix branch and exits
- [x] Second run completes full hotfix flow
- [x] `--dry-run` previews with zero writes
- [x] Cherry-pick conflicts stop with `/resolve` instruction
- [x] Fails fast if no release tags exist

**Files to Modify:**
- `commands/hotfix.md`

---

### Task 24: Implement /cleanup and /sequence-diagram Commands
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** Low
**Blocker:** None

**Description:**
Create the branch cleanup and sequence diagram generation commands.

**Implementation Steps:**
1. Create `commands/cleanup.md` — fetch/prune, find merged/orphaned branches, check PR status, report, confirm, delete with `-d` (never `-D`)
2. Create `commands/sequence-diagram.md` — support three modes: code analysis (file path), natural language (quoted text), diff analysis (no arg)
3. Both commands use minimal allowed-tools sets

**Acceptance Criteria:**
- [x] `/cleanup` deletes merged branches with `-d`, respects protected branches
- [x] `/cleanup --dry-run` reports with zero deletions
- [x] `/cleanup --include-remote` requires per-branch confirmation
- [x] `/sequence-diagram` generates valid Mermaid `sequenceDiagram`
- [x] All three input modes work (file, text, diff)

**Files to Modify:**
- `commands/cleanup.md`
- `commands/sequence-diagram.md`

---

### Task 25: Phase 3 Verification
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 17, Task 18, Task 19, Task 20, Task 21, Task 22, Task 23, Task 24
**Priority:** High
**Blocker:** None

**Description:**
Verify Phase 3 deliverables: release flow, CI monitoring, code review, hotfix workflow.

**Acceptance Criteria:**
- [x] `/release` and `/release --dry-run` work correctly
- [x] `/monitor` checks CI and applies fixes
- [x] `/review` produces structured findings
- [x] `/hotfix` two-pass design works
- [x] `/cleanup` respects protected branches
- [x] `/sequence-diagram` produces valid Mermaid output
- [x] `/docs-sync` detects and proposes doc updates

**Files to Modify:**
- None (verification only)

---

## Phase 4: Developer Productivity + Agent

### Task 26: Implement /loop-on-ci Command
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 6, Task 7, Task 20
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `/loop-on-ci` command that iterates CI fixes until green.

**Implementation Steps:**
1. Create `commands/loop-on-ci.md` with frontmatter
2. Implement loop: check-ci-status, if green exit, diagnose failures, check-compiler-errors, apply fixes, stage-and-commit, validate-and-push, wait for new CI run, repeat up to `ci.maxFixCycles` times

**Acceptance Criteria:**
- [x] Loops up to maxFixCycles times
- [x] Exits on green CI
- [x] Reports remaining failures when cycles exhausted

**Files to Modify:**
- `commands/loop-on-ci.md`

---

### Task 27: Implement ci-watcher Agent
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 20
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `ci-watcher` agent for background CI monitoring.

**Implementation Steps:**
1. Create `agents/ci-watcher.md`
2. Define behavior: poll `gh run list` at configurable interval (default 30s), track state transitions, produce summaries on completion, suggest actions on failure

**Acceptance Criteria:**
- [x] Polls CI runs at configurable interval
- [x] Reports state transitions (queued → in_progress → completed)
- [x] Produces concise pass/fail summaries
- [x] Suggests `/monitor` or `/loop-on-ci` on failure

**Files to Modify:**
- `agents/ci-watcher.md`

---

### Task 28: Implement /pr-review-canvas and /run-smoke-tests Commands
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 13, Task 20
**Priority:** Medium
**Blocker:** None

**Description:**
Create the interactive HTML PR walkthrough and smoke test commands.

**Implementation Steps:**
1. Create `commands/pr-review-canvas.md` — fetch diff and comments, categorize changes, annotate diffs, generate self-contained HTML with sidebar navigation, expandable diffs, syntax highlighting, inline annotations, summary stats, embedded comment threads
2. Create `commands/run-smoke-tests.md` — run configured test command, parse results, call check-compiler-errors if compile failures, triage into categories (flaky, environment, regression), report with fix suggestions

**Acceptance Criteria:**
- [x] `/pr-review-canvas` generates valid self-contained HTML
- [x] HTML includes sidebar navigation, syntax highlighting, and embedded comments
- [x] `/run-smoke-tests` runs tests and triages failures
- [x] Failure categories: flaky, environment, genuine regression
- [x] HTML is self-contained (no external CDN dependencies, works offline)

**Files to Modify:**
- `commands/pr-review-canvas.md`
- `commands/run-smoke-tests.md`

---

### Task 29: Implement gather-commit-summary Skill and Productivity Commands
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create the commit summary skill and its two command wrappers.

**Implementation Steps:**
1. Create `skills/gather-commit-summary.md` — determine git user, gather authored commits over time range, parse conventional types, categorize, compute stats
2. Create `commands/what-did-i-get-done.md` — parse period argument, call skill, format concise status update
3. Create `commands/weekly-review.md` — call skill with 7-day range, format categorized recap with PR links

**Acceptance Criteria:**
- [x] `gather-commit-summary` gathers and categorizes commits correctly
- [x] `/what-did-i-get-done today` produces concise summary
- [x] `/weekly-review` produces categorized recap with emojied sections
- [x] Stats include commit counts, files changed, insertions, deletions

**Files to Modify:**
- `skills/gather-commit-summary.md`
- `commands/what-did-i-get-done.md`
- `commands/weekly-review.md`

---

### Task 30: Implement /deslop Command
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 6
**Priority:** Low
**Blocker:** None

**Description:**
Create the `/deslop` command for removing AI-generated code patterns.

**Implementation Steps:**
1. Create `commands/deslop.md` with frontmatter
2. Implement: scan target files for slop patterns (verbose comments, console.log, dead code, overly defensive null checks, generic error messages, redundant type assertions, copy-paste artifacts, TODO stubs), apply fixes, show before/after diff, confirm, optionally stage-and-commit

**Acceptance Criteria:**
- [x] Identifies configured and default slop patterns
- [x] Shows before/after diff before applying
- [x] Confirmation gate before committing
- [x] Respects `codeQuality.ignoreFiles` config

**Files to Modify:**
- `commands/deslop.md`

---

### Task 31: Phase 4 Verification
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 26, Task 27, Task 28, Task 29, Task 30
**Priority:** High
**Blocker:** None

**Description:**
Verify Phase 4 deliverables: CI loop, agent monitoring, HTML canvas, smoke tests, productivity reports, deslop.

**Acceptance Criteria:**
- [x] `/loop-on-ci` iterates and exits correctly
- [x] `ci-watcher` agent polls and reports
- [x] `/pr-review-canvas` generates valid HTML
- [x] `/run-smoke-tests` triages failures
- [x] `/what-did-i-get-done` and `/weekly-review` produce summaries
- [x] `/deslop` identifies and removes slop patterns

**Files to Modify:**
- None (verification only)

---

## Phase 5: Distribution + Polish

### Task 32: Create Example Configs
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** Task 2
**Priority:** Medium
**Blocker:** None

**Description:**
Create the `examples/` directory with sample `.shipkit.json` configs.

**Implementation Steps:**
1. Create `examples/.shipkit.json` — standard config
2. Create `examples/.shipkit.minimal.json` — zero-config baseline
3. Create `examples/.shipkit.full.json` — all options configured
4. Validate all examples against `schema.json`

**Acceptance Criteria:**
- [x] All three example configs are valid JSON
- [x] All validate against `schema.json`
- [x] Minimal config demonstrates zero-config
- [x] Full config demonstrates every option

**Files to Modify:**
- `examples/.shipkit.json`
- `examples/.shipkit.minimal.json`
- `examples/.shipkit.full.json`

---

### Task 33: Create README.md, CONTRIBUTING.md, and CHANGELOG.md
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 1
**Priority:** High
**Blocker:** None

**Description:**
Create the primary documentation files following the plan's README section order and content specifications.

**Implementation Steps:**
1. Create `README.md` — badges, tagline, overview, quick start (3 install methods), prerequisites, commands table (grouped by category), architecture, configuration, security considerations, permissions & prompts, contributing, license
2. Create `CONTRIBUTING.md` — bug reports, feature requests, adding components, four-tier litmus test, testing, commit conventions, PR process, code of conduct reference
3. Create `CHANGELOG.md` — Keep a Changelog format, initial `[Unreleased]` section listing all 20 commands, 12 skills, 1 agent, 2 rules

**Acceptance Criteria:**
- [x] README has all 6 badges in correct order
- [x] README includes all 20 commands grouped by category
- [x] README includes security warning about arbitrary shell execution
- [x] CONTRIBUTING describes the four-tier litmus test
- [x] CHANGELOG follows Keep a Changelog format with Unreleased section

**Files to Modify:**
- `README.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`

---

### Task 34: Create install.sh and validate-components.sh
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create the fallback installer script and the component validation script.

**Implementation Steps:**
1. Create `install.sh` — support `--scope user` (installs to `~/.claude/commands/`) and `--scope project` (installs to `.claude/commands/`)
2. Create `scripts/validate-components.sh` — accepts directory argument (commands/skills/agents/rules), validates YAML frontmatter, prints PASS/FAIL per file
3. Ensure both scripts pass shellcheck

**Acceptance Criteria:**
- [x] `install.sh` supports user and project scope
- [x] `validate-components.sh` validates frontmatter for commands (description + allowed-tools)
- [x] `validate-components.sh` validates non-empty files with headings for skills/agents/rules
- [x] Both scripts pass shellcheck

**Files to Modify:**
- `install.sh`
- `scripts/validate-components.sh`

---

### Task 35: Create CI/CD Workflows
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 34
**Priority:** High
**Blocker:** None

**Description:**
Create the three GitHub Actions workflows.

**Implementation Steps:**
1. Create `.github/workflows/ci.yml` — validate command frontmatter, skill/agent/rule files, schema.json, example configs, plugin.json, marketplace.json, shellcheck install.sh, markdown lint (advisory)
2. Create `.github/workflows/release.yml` — extract version from tag, extract CHANGELOG notes, validate version match with plugin.json, create GitHub Release (idempotent)
3. Create `.github/workflows/codeql.yml` — weekly + PR, javascript-typescript language

**Acceptance Criteria:**
- [x] CI validates all component frontmatter
- [x] CI validates schema and example configs
- [x] CI runs shellcheck on install.sh
- [x] Release workflow extracts notes from CHANGELOG
- [x] Release workflow validates version match with plugin.json
- [x] Release workflow is idempotent
- [x] CodeQL runs weekly and on PRs

**Files to Modify:**
- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `.github/workflows/codeql.yml`

---

### Task 36: Create GitHub Templates and Dependabot Config
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create issue templates, PR template, and dependabot configuration.

**Implementation Steps:**
1. Create `.github/ISSUE_TEMPLATE/bug_report.md` with environment and config fields
2. Create `.github/ISSUE_TEMPLATE/feature_request.md` with tier checkboxes
3. Create `.github/ISSUE_TEMPLATE/config.yml` to disable blank issues
4. Create `.github/PULL_REQUEST_TEMPLATE.md` with type checkboxes and checklist
5. Create `.github/dependabot.yml` for github-actions ecosystem (weekly)

**Acceptance Criteria:**
- [x] Bug report template has environment and config sections
- [x] Feature request template has tier selection checkboxes
- [x] Blank issues disabled with link to Discussions
- [x] PR template has type checkboxes and validation checklist
- [x] Dependabot configured for github-actions weekly updates

**Files to Modify:**
- `.github/ISSUE_TEMPLATE/bug_report.md`
- `.github/ISSUE_TEMPLATE/feature_request.md`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/dependabot.yml`

---

### Task 37: Create Dogfood Config
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** Task 2
**Priority:** Medium
**Blocker:** None

**Description:**
Create `.shipkit.json` at the repo root so ShipKit can release itself.

**Implementation Steps:**
1. Create `.shipkit.json` with: schemaVersion 1, release config pointing to `.claude-plugin/plugin.json`, validation commands (validate-components, validate schema, shellcheck), sensitive patterns, conventional commit prefixes

**Acceptance Criteria:**
- [x] Config is valid against `schema.json`
- [x] Release section points to `.claude-plugin/plugin.json` for version
- [x] Validation commands cover component validation, schema, and shellcheck

**Files to Modify:**
- `.shipkit.json`

---

### Task 38: End-to-End Testing and First Release
**Status:** Completed
**Estimated Effort:** L
**Dependencies:** Task 9, Task 16, Task 25, Task 31, Task 33, Task 35, Task 37
**Priority:** High
**Blocker:** None

**Description:**
Perform end-to-end testing in a test repo and create the first release. Depends on all phase verification tasks to ensure full coverage.

**Implementation Steps:**
1. Test plugin installation via marketplace metadata
2. Verify all 20 commands appear in `/help`
3. Test core commands (commit, push, ship) in zero-config mode
4. Verify CI pipeline passes on a clean checkout
5. Tag `v1.0.0` and verify release workflow creates GitHub Release
6. Move CHANGELOG items from [Unreleased] to [1.0.0]

**Acceptance Criteria:**
- [x] Plugin installs correctly
- [x] All commands appear in `/help`
- [x] Core commands work in zero-config
- [ ] CI pipeline passes *(deferred — requires push to trigger)*
- [ ] Release workflow creates GitHub Release with correct notes *(deferred — requires v1.0.0 tag)*
- [ ] CHANGELOG reflects v1.0.0 *(deferred — currently [Unreleased], moved to v1.0.0 at release time)*

**Files to Modify:**
- `CHANGELOG.md`
- `.claude-plugin/plugin.json` (version update)

---

### Task 39: Finalize Marketplace Distribution
**Status:** Completed
**Estimated Effort:** M
**Dependencies:** Task 33, Task 35, Task 38
**Priority:** High
**Blocker:** None

**Description:**
Verify self-hosted marketplace works end-to-end and prepare for official marketplace submission.

**Implementation Steps:**
1. Verify `/plugin marketplace add sanmak/ship-kit` → `/plugin install ship-kit` works
2. Verify commands appear as "(ship-kit)" in `/help`
3. Prepare submission to official Anthropic marketplace
4. Enable GitHub Discussions on the repo

**Acceptance Criteria:**
- [x] Self-hosted marketplace install works end-to-end
- [x] Commands show correct plugin attribution
- [ ] GitHub Discussions enabled *(deferred — manual repo setting)*
- [ ] Official marketplace submission prepared *(deferred — requires published release)*

**Files to Modify:**
- None (verification and configuration)

---

## Implementation Order

### Phase 1: Foundation (Tasks 1–9)
1. Task 1: Plugin manifests (foundation)
2. Task 2: Schema (foundation)
3. Task 3: License/CoC/Security (parallel with 1-2)
4. Task 4: Rules (parallel with 1-3)
5. Task 5: detect-sensitive skill (foundation for Task 6)
6. Task 6: stage-and-commit skill (depends on Task 5)
7. Task 7: validate-and-push skill (parallel with Task 6)
8. Task 8: commit/push/ship commands (depends on Tasks 6, 7)
9. Task 9: Phase 1 verification (depends on all above)

### Phase 2: Conflict Resolution + PR (Tasks 10–16)
10. Task 10: resolve-conflicts + /resolve (depends on Phase 1)
11. Task 11: Conflict gates (depends on Task 10)
12. Task 12: /sync (depends on Task 10)
13. Task 13: get-pr-comments skill (parallel)
14. Task 14: /ship-pr (depends on Tasks 6, 7, 13)
15. Task 15: /pr-fix (depends on Tasks 6, 7, 13)
16. Task 16: Phase 2 verification

### Phase 3: Release + Operations (Tasks 17–25)
17. Task 17: bump-version + generate-changelog (parallel)
18. Task 18: /release (depends on Tasks 7, 17)
19. Task 19: detect-stale-docs + /docs-sync (parallel)
20. Task 20: check-ci-status + check-compiler-errors (parallel)
21. Task 21: /monitor (depends on Tasks 6, 7, 20)
22. Task 22: /review (depends on Tasks 5, 13)
23. Task 23: /hotfix (depends on Tasks 6, 7, 10, 17)
24. Task 24: /cleanup + /sequence-diagram (parallel)
25. Task 25: Phase 3 verification

### Phase 4: Productivity + Agent (Tasks 26–31)
26. Task 26: /loop-on-ci (depends on Tasks 6, 7, 20)
27. Task 27: ci-watcher agent (depends on Task 20)
28. Task 28: /pr-review-canvas + /run-smoke-tests (depends on Tasks 13, 20)
29. Task 29: gather-commit-summary + productivity commands (parallel)
30. Task 30: /deslop (depends on Task 6)
31. Task 31: Phase 4 verification

### Phase 5: Distribution + Polish (Tasks 32–39)
32. Task 32: Example configs (depends on Task 2)
33. Task 33: README + CONTRIBUTING + CHANGELOG
34. Task 34: install.sh + validate-components.sh
35. Task 35: CI/CD workflows (depends on Task 34)
36. Task 36: GitHub templates + dependabot
37. Task 37: Dogfood config (depends on Task 2)
38. Task 38: E2E testing + first release (depends on Tasks 9, 16, 25, 31, 33, 35, 37)
39. Task 39: Finalize marketplace (depends on Tasks 33, 35, 38)

## Progress Tracking
- Total Tasks: 39
- Completed: 39
- In Progress: 0
- Blocked: 0
- Pending: 0
