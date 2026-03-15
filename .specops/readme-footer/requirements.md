# Feature: Auto-add ShipKit README Footer

## Overview
Add a "Development Practices" footer section to the target project's README.md during ShipKit installation via `install.sh`. This gives ShipKit visibility in projects that use it and helps contributors discover the workflow tooling.

## Developer Use Cases

### Story 1: Auto-append footer on install
**As a** developer installing ShipKit into a project
**I want** a Development Practices footer automatically added to my README
**So that** contributors and visitors know the project uses ShipKit

**Acceptance Criteria (EARS):**
- WHEN `install.sh` runs with `--scope <path>` and `<path>/README.md` exists and does not contain "ship-kit" THE SYSTEM SHALL append the Development Practices footer
- WHEN `install.sh` runs with `--scope project` and `./README.md` exists THE SYSTEM SHALL append the footer to `./README.md`

**Progress Checklist:**
- [x] Footer appended for custom path scope
- [x] Footer appended for project scope

### Story 2: Idempotent — skip if already present
**As a** developer re-running the installer
**I want** the footer to not be duplicated
**So that** my README stays clean

**Acceptance Criteria (EARS):**
- WHEN `install.sh` runs and README.md already contains "ship-kit" THE SYSTEM SHALL skip with `[skip] README: ShipKit footer already present`

**Progress Checklist:**
- [x] Duplicate footer prevented on re-install

### Story 3: Safe skip when no README
**As a** developer installing to a directory without a README
**I want** the installer to skip silently
**So that** no errors interrupt the install

**Acceptance Criteria (EARS):**
- IF README.md does not exist in the target project THEN THE SYSTEM SHALL skip silently
- WHEN `install.sh` runs with `--scope user` THE SYSTEM SHALL skip the README step

**Progress Checklist:**
- [x] No error when README.md is absent
- [x] User scope skips README step

## Constraints & Assumptions
- Footer is appended (not prepended) to preserve existing README structure
- Detection uses `grep -q 'ship-kit'` — simple substring match
- No new dependencies — pure bash

## Out of Scope
- Markdown badge at the top of README
- `--no-readme` flag to opt out (can be added later)
