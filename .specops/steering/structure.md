---
name: "Project Structure"
description: "Directory layout, key files, and module boundaries"
inclusion: always
---

## Directory Layout
- `commands/` — 20 user-facing slash commands (Tier 1). Each is a `.md` with YAML frontmatter.
- `skills/` — 12 reusable building blocks (Tier 2). Called by commands/agents internally.
- `agents/` — 1 background agent (Tier 3). Runs autonomously.
- `rules/` — 2 always-on coding conventions (Tier 4). Passive enforcement.
- `.claude-plugin/` — Plugin manifests (`plugin.json`, `marketplace.json`)
- `examples/` — Sample `.shipkit.json` configs (minimal, standard, full)
- `scripts/` — Validation and utility scripts
- `.github/` — CI/CD workflows, issue templates, PR template, dependabot

## Key Files
- `schema.json` — JSON Schema validating `.shipkit.json`
- `.shipkit.json` — Dogfood config (ShipKit uses itself)
- `install.sh` — Fallback installer for non-marketplace users

## Module Boundaries
- Commands compose Skills — never the reverse
- Skills are stateless building blocks with structured returns
- Agents feed into Skills/Commands when action is needed
- Rules are passive — no invocation, no return values
- Config loading happens at runtime in each component independently
