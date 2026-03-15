---
name: "Product Context"
description: "What ShipKit builds, for whom, and how it's positioned"
inclusion: always
---

## Product Overview
ShipKit is a standalone Claude Code plugin that automates git workflows and developer productivity tasks — commit, push, ship, release, review, and monitor without leaving the editor.

## Target Users
Developers using Claude Code who want to streamline their git workflow. Primary use cases: solo developers shipping fast, and small teams wanting consistent commit conventions, automated PR creation, and CI monitoring.

## Key Differentiators
- Four-tier composable architecture (Commands, Skills, Agents, Rules) — not monolithic scripts
- Zero-config works out of the box; `.shipkit.json` for customization
- Never force-pushes, never `--no-verify` — safety by design
- Sensitive file detection always blocks — no bypass
- ShipKit can release itself (dogfooding)
