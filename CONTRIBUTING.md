# Contributing to ShipKit

Thank you for your interest in contributing to ShipKit. This guide covers how to report bugs, request features, add new components, and submit pull requests.

## Bug Reports

File a bug report using the [bug issue template](https://github.com/sanmak/ship-kit/issues/new?template=bug_report.md). Include:

- The command you ran (e.g., `/ship`, `/monitor`)
- Expected behavior vs. actual behavior
- Claude Code version and OS
- Relevant `.shipkit.json` configuration (redact any secrets)

## Feature Requests

File a feature request using the [feature issue template](https://github.com/sanmak/ship-kit/issues/new?template=feature_request.md). Include:

- A clear description of the problem or workflow gap
- Your proposed solution
- **Tier selection** — identify which tier the feature belongs to (Command, Skill, Agent, or Rule) using the litmus test below

## Adding Components

### Commands

Add a new Markdown file in `commands/`. The file must include YAML frontmatter with `description` and `allowed-tools`:

```markdown
---
description: Short description of what the command does
allowed-tools: Bash(git:*), Read, Grep, Glob
argument-hint: "[optional-args]"
---

Prompt body that instructs Claude how to execute the command.
```

### Skills

Add a new Markdown file in `skills/`. Skills are single-responsibility — they do one thing well and are invoked by commands.

### Agents

Add a new Markdown file in `agents/`. Agents are long-running processes that operate autonomously (e.g., polling CI status in a loop).

### Rules

Add a new Markdown file in `rules/`. Rules are passive guardrails that Claude applies automatically without explicit user invocation.

## Four-Tier Litmus Test

When deciding where a new component belongs, answer these five questions:

1. **Does the user invoke it directly with a slash command?** Place it in `commands/`.
2. **Is it a single-responsibility building block used by commands?** Place it in `skills/`.
3. **Does it run autonomously in the background over time?** Place it in `agents/`.
4. **Does it enforce a coding standard without explicit invocation?** Place it in `rules/`.
5. **Is it reused by more than one command?** It is almost certainly a skill, not inline logic in a command.

If a component does not clearly fit one tier, start it as a skill. Skills are the easiest to promote to commands or compose into agents later.

## Testing

Run the component validation script to check that all components have valid frontmatter and follow naming conventions:

```bash
scripts/validate-components.sh
```

Fix any errors before submitting your pull request.

## Commit Conventions

ShipKit follows [Conventional Commits](https://www.conventionalcommits.org/). Every commit message must start with a type prefix:

| Prefix | Use when |
|--------|----------|
| `feat` | Adding a new command, skill, agent, or user-facing feature |
| `fix` | Fixing a bug in an existing component |
| `chore` | Maintenance tasks (CI config, dependency updates, tooling) |
| `docs` | Documentation-only changes |
| `test` | Adding or updating tests or validation scripts |
| `refactor` | Restructuring code without changing behavior |

Examples:

```
feat: add /weekly-review command
fix: handle missing gh CLI in /monitor
docs: add configuration examples to README
chore: update CI workflow to Node 20
test: add validation for skill frontmatter
refactor: extract commit message logic into stage-and-commit skill
```

## PR Process

1. **Fork** the repository and create a feature branch from `main`.
2. **Branch naming** — use a descriptive name: `feat/weekly-review`, `fix/monitor-exit-code`, `docs/config-examples`.
3. **Make your changes** following the guidelines above.
4. **Test** by running `scripts/validate-components.sh` and manually testing your command in Claude Code.
5. **Commit** using conventional commit messages.
6. **Open a pull request** against `main`. Fill in the PR template with a summary of changes, the tier(s) affected, and testing steps.
7. A maintainer will review your PR. Address any feedback and keep the branch up to date with `main`.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you agree to uphold a welcoming, inclusive, and harassment-free environment for everyone.
