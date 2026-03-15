# ShipKit

![CI](https://github.com/sanmak/ship-kit/actions/workflows/ci.yml/badge.svg)
![Release](https://github.com/sanmak/ship-kit/actions/workflows/release.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-Claude%20Code-purple.svg)
![CodeQL](https://github.com/sanmak/ship-kit/actions/workflows/codeql.yml/badge.svg)

> Git workflow automation — commit, push, ship, release, review, and monitor from Claude Code

## Overview

ShipKit is a Claude Code plugin that automates your entire git workflow. It provides 20 slash commands, 12 skills, 1 agent, and 2 rules organized into a **four-tier architecture**:

- **Commands** — user-facing slash commands that orchestrate multi-step workflows
- **Skills** — reusable, single-responsibility building blocks invoked by commands
- **Agents** — long-running autonomous processes that operate in the background
- **Rules** — passive guardrails that enforce coding standards without user invocation

## Quick Start

### Option 1: Plugin Marketplace

```
/plugin marketplace add sanmak/ship-kit
/plugin install ship-kit
```

### Option 2: One-Line Installer

```bash
curl -fsSL https://raw.githubusercontent.com/sanmak/ship-kit/main/install.sh | bash
```

### Option 3: Manual Installation

```bash
git clone https://github.com/sanmak/ship-kit.git
cd ship-kit
./install.sh --scope project   # or --scope user for user-wide install
```

## Prerequisites

- **git** (2.x or later)
- **gh** CLI ([GitHub CLI](https://cli.github.com/)) — authenticated
- **Claude Code** with plugin support

## Commands

### Core Workflow

| Command | Description |
|---------|-------------|
| `/commit` | Stage, review, and commit with conventional message |
| `/push` | Validate and push unpushed commits |
| `/ship` | Commit and push in one step |

### PR Automation

| Command | Description |
|---------|-------------|
| `/ship-pr` | Commit, create PR branch, and open a pull request |
| `/pr-fix [PR-number]` | Fetch PR review comments and fix them |
| `/pr-review-canvas [PR-number]` | Generate an interactive HTML PR walkthrough with annotated diffs |

### Release & Versioning

| Command | Description |
|---------|-------------|
| `/release [--dry-run]` | Bump version, update CHANGELOG, tag, and publish release |
| `/hotfix [base-tag] [--dry-run]` | Emergency hotfix — branch, fix, validate, tag, cherry-pick |

### CI & Monitoring

| Command | Description |
|---------|-------------|
| `/monitor` | Check CI status and auto-fix failures |
| `/loop-on-ci` | Watch CI runs and iterate on failures until checks pass |
| `/run-smoke-tests [test-path]` | Run Playwright smoke tests and triage failures |

### Branch Management

| Command | Description |
|---------|-------------|
| `/sync [base-branch] [--merge] [--rebase]` | Sync branch with upstream — fetch, rebase/merge, handle conflicts |
| `/resolve [--status] [--abort]` | Detect and resolve merge/rebase/cherry-pick conflicts |
| `/cleanup [--dry-run] [--include-remote]` | Clean up stale branches — delete merged locals, prune remotes |

### Code Review

| Command | Description |
|---------|-------------|
| `/review [PR-number] [--post]` | AI-assisted code review with structured findings |
| `/deslop [file\|path]` | Remove AI-generated code slop and clean up code style |

### Documentation

| Command | Description |
|---------|-------------|
| `/docs-sync` | Sync docs stale relative to changed source files |
| `/sequence-diagram [file/path \| "description"] [--output file.md]` | Generate Mermaid sequence diagrams from code or natural language |

### Developer Productivity

| Command | Description |
|---------|-------------|
| `/what-did-i-get-done [period]` | Summarize authored commits over a given time period |
| `/weekly-review` | Generate weekly recap with bugfix/tech-debt/net-new highlights |

## Architecture

ShipKit uses a **four-tier architecture** to keep components focused and composable:

| Tier | Purpose | Example |
|------|---------|---------|
| **Command** | Orchestrates a user-facing workflow | `/ship` calls stage-and-commit then validate-and-push |
| **Skill** | Performs a single, reusable task | `stage-and-commit` stages files and creates a commit |
| **Agent** | Runs autonomously over time | `ci-watcher` polls CI and fixes failures in a loop |
| **Rule** | Enforces a coding standard passively | `typescript-exhaustive-switch` flags missing switch cases |

**Litmus test** — when adding a new component, ask:

1. Does the user invoke it directly? **Command.**
2. Is it a single-responsibility building block? **Skill.**
3. Does it run autonomously in the background? **Agent.**
4. Does it enforce a standard without invocation? **Rule.**
5. Is it used by more than one command? Almost certainly a **Skill.**

## Configuration

ShipKit reads project-level settings from `.shipkit.json` in your repository root. The file is validated against [`schema.json`](schema.json).

```jsonc
{
  "schemaVersion": 1,
  "commit": {
    "conventionalPrefixes": ["feat", "fix", "chore", "docs", "test", "refactor"],
    "coAuthor": "Co-Authored-By: ShipKit <noreply@shipkit.dev>"
  },
  "ci": {
    "provider": "github-actions",
    "maxFixCycles": 3
  }
}
```

See the [`examples/`](examples/) directory for minimal, standard, and full configuration files.

## Security Considerations

> **Warning:** The following configuration fields execute shell commands with the same permissions as your user account:
>
> - `build.triggers[].run` — build commands triggered by file changes
> - `validation.commands[].run` — validation commands run during pre-commit checks
> - `release.preRelease[]` — commands run before creating a release
>
> Only use `.shipkit.json` files from sources you trust. Review any configuration before running ShipKit in a new repository.

## Permissions & Prompts

ShipKit commands declare their required tools via `allowed-tools` in each command's frontmatter. Claude Code will prompt you for permission the first time a command needs access to a tool (e.g., `Bash(git:*)`, `Bash(gh:*)`, `Write`, `Edit`).

You can pre-approve tools in your Claude Code settings to reduce prompts, or review each request as it appears. No command runs silently — Claude Code's permission model ensures you stay in control.

## Development Process

This project uses [SpecOps](https://github.com/sanmak/specops) for spec-driven development. Feature requirements, designs, and task breakdowns live in `.specops/`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on filing issues, proposing features, adding components, and submitting pull requests.

## License

[MIT](LICENSE)
