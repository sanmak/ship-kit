---
name: "Technology Stack"
description: "Languages, frameworks, tools, and quality infrastructure"
inclusion: always
---

## Core Stack
- All components are plain markdown files with YAML frontmatter — no build system
- Config is loaded at runtime via inline bash (`!` expressions in markdown)
- Distribution: Claude Code plugin marketplace + installer script

## Development Tools
- Shell scripts for validation (`scripts/validate-components.sh`) and installation (`install.sh`)
- JSON Schema for `.shipkit.json` config validation
- GitHub Actions for CI/CD (validation, release, CodeQL)

## Quality & Testing
- `validate-components.sh` validates YAML frontmatter in all component files
- CI validates schema, example configs, plugin manifests, and shellcheck on scripts
- End-to-end testing via manual verification in test repos
