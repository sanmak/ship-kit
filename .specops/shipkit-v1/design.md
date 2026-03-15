# Design: ShipKit v1 — Dev Workflow Automation Plugin

## Architecture Overview
ShipKit uses a four-tier component model where all components are plain markdown files with YAML frontmatter. Commands are user-facing entry points that compose Skills (reusable building blocks). Agents run autonomously in the background. Rules apply passively during all code generation. Config is loaded at runtime via inline bash — no generator or build system.

## Technical Decisions

### Decision 1: Four-Tier Component Model
**Context:** Need a composable architecture that separates user-facing workflows from reusable logic
**Options Considered:**
1. Monolithic commands (v1 plan) — each command self-contained
2. Two-tier (commands + utilities) — simple but limits reuse
3. Four-tier (commands, skills, agents, rules) — full separation of concerns

**Decision:** Four-tier model
**Rationale:** Skills enable composition (e.g., `stage-and-commit` used by 7 commands). Agents handle background monitoring. Rules enforce coding conventions passively. The litmus test determines tier placement clearly.

### Decision 2: Plain Markdown with YAML Frontmatter
**Context:** Need a format for all components that Claude Code can discover and execute
**Options Considered:**
1. TypeScript/JavaScript modules — requires build system
2. JSON config files — limited expressiveness for prompts
3. Markdown with YAML frontmatter — native Claude Code format, no build needed

**Decision:** Markdown with YAML frontmatter
**Rationale:** Claude Code natively discovers `.md` files in `commands/` directories. YAML frontmatter provides `description` and `allowed-tools`. All "logic" is prompt engineering in the markdown body.

### Decision 3: Runtime Config Loading via Inline Bash
**Context:** Components need access to `.shipkit.json` config and git state
**Options Considered:**
1. Pre-processing step that injects config — adds complexity, requires build
2. Runtime loading via inline bash expressions — zero build, each component loads what it needs

**Decision:** Runtime inline bash
**Rationale:** Each command/skill includes a Context section with `!`-prefixed bash expressions (e.g., `!`cat .shipkit.json 2>/dev/null || echo '{}'``). Components select only the context they need. No build step required.

### Decision 4: Git-State Idempotency for Recovery
**Context:** Need a way to recover from interrupted commands
**Options Considered:**
1. Checkpoint system with state files — complex, requires cleanup
2. Git-state idempotency — commands check current state before performing side effects

**Decision:** Git-state idempotency (v1), checkpoint system deferred to v2
**Rationale:** Commands check `git log`, `git tag -l`, `git branch -l`, `gh pr list` before acting. Rerunning an interrupted command skips completed steps naturally. Simpler and sufficient for v1.

### Decision 5: Pre-Authorized Toolchains in Frontmatter
**Context:** Without `allowed-tools`, every bash/git invocation prompts the user for permission
**Options Considered:**
1. Minimal permissions, prompt for everything — poor UX
2. Broad pre-authorization of common tools — smooth UX for most projects

**Decision:** Broad pre-authorization with tiered tool sets
**Rationale:** Commands that run user-configured shell commands pre-authorize: `git`, `gh`, `cat`, `shasum`, `npm`, `node`, `python3`, `python`, `bash`, `make`. Commands running compiler detection additionally include: `tsc`, `npx`, `cargo`, `go`. Read-only commands use minimal sets. Uncommon toolchains (e.g., `gradle`, `dotnet`) will prompt on first use — this is expected.

### Decision 6: Self-Hosted Marketplace Distribution
**Context:** Need a distribution mechanism for the plugin
**Options Considered:**
1. Official Anthropic marketplace only — not yet available for submission
2. Self-hosted marketplace via GitHub repo — available now
3. One-line installer script — fallback for non-plugin users

**Decision:** Self-hosted marketplace (primary) + installer script (fallback) + official marketplace (goal)
**Rationale:** Self-hosted via `marketplace.json` in the repo allows immediate availability. Installer script provides a fallback. Official marketplace submission is the long-term goal.

## Module Design

### Plugin Manifests (`.claude-plugin/`)

**plugin.json:**
```json
{
  "name": "ship-kit",
  "version": "1.0.0",
  "description": "Git workflow automation — commit, push, ship, release, review, and monitor from Claude Code",
  "author": { "name": "Sanket Makhija" },
  "repository": "https://github.com/sanmak/ship-kit",
  "license": "MIT",
  "keywords": ["git", "workflow", "commit", "push", "release", "pr", "ci", "automation", "review", "productivity"],
  "commands": "./commands/",
  "skills": "./skills/",
  "agents": "./agents/"
}
```

**marketplace.json:**
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

### Commands (20 total)

All commands live in `commands/`. Each is a `.md` file with YAML frontmatter (`description`, `allowed-tools`, optional `argument-hint`). Commands compose skills by inlining their logic.

| Category | Commands |
|----------|----------|
| Core Workflow | `/commit`, `/push`, `/ship` |
| PR Automation | `/ship-pr`, `/pr-fix` |
| Release & Versioning | `/release`, `/hotfix` |
| CI & Monitoring | `/monitor`, `/loop-on-ci` |
| Branch Management | `/sync`, `/resolve`, `/cleanup` |
| Code Review | `/review`, `/pr-review-canvas` |
| Documentation | `/docs-sync` |
| Developer Productivity | `/what-did-i-get-done`, `/weekly-review`, `/deslop`, `/sequence-diagram`, `/run-smoke-tests` |

### Skills (12 total)

All skills live in `skills/`. Each is a `.md` file defining a single reusable operation.

| Skill | Called By |
|-------|----------|
| `stage-and-commit` | `/commit`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/hotfix`, `/deslop` |
| `validate-and-push` | `/push`, `/ship`, `/ship-pr`, `/pr-fix`, `/loop-on-ci`, `/release`, `/hotfix` |
| `resolve-conflicts` | `/resolve`, `/sync`, `/hotfix` |
| `check-ci-status` | `/monitor`, `/loop-on-ci`, `ci-watcher` |
| `get-pr-comments` | `/pr-fix`, `/review`, `/pr-review-canvas` |
| `check-compiler-errors` | `/pr-fix`, `/monitor`, `/loop-on-ci`, `/run-smoke-tests` |
| `bump-version` | `/release`, `/hotfix` |
| `generate-changelog` | `/release`, `/hotfix` |
| `detect-stale-docs` | `/docs-sync` |
| `detect-sensitive` | `/review`, `stage-and-commit` |
| `gather-commit-summary` | `/what-did-i-get-done`, `/weekly-review` |
| `manage-worktrees` | Deferred to v2 |

### Agents (1 total)

`ci-watcher` — lives in `agents/`. Polls `gh run list`, tracks state transitions, produces pass/fail summaries, suggests fix workflows on failure.

### Rules (2 total)

Rules live in `rules/`. Passive conventions enforced during all code generation:
- `typescript-exhaustive-switch` — every `switch` on union/enum must handle all cases or have a `never` default
- `no-inline-imports` — all imports at module top-level (dynamic `import()` for code splitting excepted)

## Config Schema (`.shipkit.json`)

JSON Schema at `schema.json` validates the optional config file. Key sections:

| Section | Purpose |
|---------|---------|
| `build.triggers` | Watch patterns → run command → stage output |
| `validation.commands` | Pre-push quality gates |
| `sensitive` | Glob patterns, keywords, exact file paths to block |
| `commit` | Conventional prefixes, co-author trailer |
| `checksums` | Optional SHA-256 verification |
| `docs.dependencyMap` | Source → docs mapping for staleness detection |
| `release` | Version files, changelog, pre-release commands, tag prefix |
| `pr` | Template, base branch, branch prefix, unpushed commit policy |
| `ci` | Provider, max fix cycles, failure hints |
| `resolve` | Strategy, auto mode (v2), ignored patterns |
| `review` | Focus areas, severity threshold, custom rules, ignored paths |
| `hotfix` | Branch prefix, target branches, cherry-pick policy |
| `sync` | Strategy, base branch, auto-stash |
| `cleanup` | Protected branches, stale days, remote deletion policy |
| `smokeTests` | Runner, command, report dir, retries, timeout |
| `codeQuality` | Slop patterns, ignore files, auto-fix |

Schema versioning: `schemaVersion` defaults to 1. Unknown top-level keys fail validation with actionable errors.

## Command Format

Every command `.md` includes:

```yaml
---
description: <one-line description shown in /help>
allowed-tools: Bash(git:*), Bash(gh:*), ...
argument-hint: <optional>
---
```

Config loading preamble:
```markdown
## Context
- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
```

## Usage Examples

### Example 1: Basic Commit-Push Flow
```
Developer: /commit
ShipKit: Stages files → checks sensitive patterns → runs build triggers →
         reviews diff → generates "feat: add user auth endpoint" → commits
         ✓ Committed abc1234

Developer: /push
ShipKit: Checks conflict markers → runs validation commands (lint, test) →
         pushes to origin/feature-auth
         ✓ Pushed 1 commit to origin/feature-auth
```

### Example 2: PR Workflow
```
Developer: /ship-pr
ShipKit: Records original branch (main) → stages and commits →
         creates branch feat/add-user-auth → cherry-picks commit →
         validates and pushes → creates PR via gh →
         returns to main
         ✓ PR #42 created: https://github.com/user/repo/pull/42

Developer: /pr-fix 42
ShipKit: Fetches review comments → groups by issue →
         fixes on current branch → validates with tsc --noEmit →
         commits "fix: address PR review feedback" → pushes →
         replies to resolved comments
         ✓ Fixed 3 comments, pushed to feat/add-user-auth
```

### Example 3: Release Flow
```
Developer: /release
ShipKit: Pre-flight: clean tree ✓, on main ✓, remote reachable ✓, tag v1.2.0 doesn't exist ✓
         Generates changelog → bumps version in package.json (1.1.0 → 1.2.0) →
         runs pre-release commands (npm run build, npm test) →
         Preview: v1.2.0, 12 commits, 3 feat + 5 fix + 4 chore
         Confirm release? [y/n]
         → Commits "chore: release v1.2.0" → tags v1.2.0 → pushes → creates GitHub Release
         ✓ Released v1.2.0
```

## Security Considerations
- `.shipkit.json` allows arbitrary shell commands via `build.triggers[].run`, `validation.commands[].run`, `release.preRelease[]` — these execute with user permissions
- `detect-sensitive` skill blocks commits containing files matching sensitive patterns — no bypass
- Never force-push, never `--no-verify`
- Sensitive keyword scanning skips binaries, `.git/`, `node_modules/`, and files > 1 MB

## Testing Strategy
- `scripts/validate-components.sh` validates YAML frontmatter in all component `.md` files
- CI validates schema.json, example configs, plugin manifests, and runs shellcheck on install.sh
- Markdown lint runs as advisory (non-blocking)
- End-to-end testing in a test repo before first release

## Release Plan
1. **Phase 1**: Foundation + core skills (commit/push/ship)
2. **Phase 2**: Conflict resolution + PR automation + sync
3. **Phase 3**: Release + operations + review
4. **Phase 4**: Developer productivity + agent
5. **Phase 5**: Distribution + polish + first release

## Risks & Mitigations
- **Risk**: `allowed-tools` insufficient for user's toolchain → **Mitigation**: Claude Code prompts for permission on first use; user approves per session
- **Risk**: CI provider not GitHub Actions → **Mitigation**: Config defaults to `github-actions`; other providers can be added later
- **Risk**: Plugin marketplace format changes → **Mitigation**: Plugin compatibility gate validates before every release
- **Risk**: Large repos slow down sensitive file scanning → **Mitigation**: Skip binaries, `.git/`, `node_modules/`, files > 1 MB
