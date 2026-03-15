# Design: Auto-add ShipKit README Footer

## Architecture Overview
Single function addition to `install.sh`. No new files, no new dependencies.

## Technical Decisions

### Decision 1: Derive project root from TARGET_DIR
**Context:** Need to find the README.md relative to where components are installed.
**Options Considered:**
1. Strip `/.claude/commands` suffix from TARGET_DIR — simple, works for all scopes
2. Accept a separate `--readme-path` flag — over-engineered

**Decision:** Option 1
**Rationale:** TARGET_DIR always ends with `/.claude/commands` by construction. Stripping gives us the project root reliably.

### Decision 2: Detection mechanism
**Context:** Need to check if footer already exists to prevent duplicates.
**Options Considered:**
1. `grep -q 'ship-kit'` — simple substring match
2. `grep -q '### Development Practices'` — heading match

**Decision:** Option 1
**Rationale:** More resilient — catches the footer even if the heading is slightly modified. The string "ship-kit" is unique enough to avoid false positives in typical READMEs.

## Module Design

### Function: `add_readme_footer`
**Responsibility:** Append Development Practices footer to target project's README.md
**Interface:** No arguments — uses global `TARGET_DIR`
**Dependencies:** None (uses built-in bash commands)

## Footer Content

```markdown

---

### Development Practices

This project uses [ShipKit](https://github.com/sanmak/ship-kit) for git workflow automation — commit, push, ship, release, review, and monitor from Claude Code.
```

## Testing Strategy
- Manual: run `./install.sh --scope <path>` and verify README
- Manual: re-run to verify idempotency
- Shellcheck validation
