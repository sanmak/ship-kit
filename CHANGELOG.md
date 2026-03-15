# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [1.1.0] - 2026-03-15

### Features
- Auto-add Development Practices footer to project README

### Fixed
- Support custom path scope and curl pipe in installer
- Remove unsupported agents field from plugin manifest
- Add required owner field to marketplace.json

## [1.0.0] - 2026-03-15

### Added
- 20 commands: /commit, /push, /ship, /ship-pr, /pr-fix, /release, /monitor, /loop-on-ci, /docs-sync, /resolve, /review, /hotfix, /sync, /cleanup, /sequence-diagram, /pr-review-canvas, /run-smoke-tests, /what-did-i-get-done, /weekly-review, /deslop
- 12 skills: stage-and-commit, validate-and-push, resolve-conflicts, check-ci-status, get-pr-comments, check-compiler-errors, bump-version, generate-changelog, detect-stale-docs, detect-sensitive, gather-commit-summary, manage-worktrees (deferred)
- 1 agent: ci-watcher
- 2 rules: typescript-exhaustive-switch, no-inline-imports
- JSON Schema for .shipkit.json validation
- Example configurations (minimal, standard, full)
- CI/CD workflows (CI, Release, CodeQL)
- Plugin marketplace support

### Fixed
- Resolve CodeQL failures and suppress AI co-author trailers

### Other
- Add CODEOWNERS file
