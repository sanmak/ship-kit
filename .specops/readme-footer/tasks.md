# Implementation Tasks: Auto-add ShipKit README Footer

## Task Breakdown

### Task 1: Add `add_readme_footer` function to install.sh + ship.md
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** High
**Blocker:** None

**Description:**
Add a bash function that derives the project root from TARGET_DIR, checks for README.md, and appends the Development Practices footer if not already present.

**Implementation Steps:**
1. Add `add_readme_footer()` function after `copy_components()` definition
2. Call `add_readme_footer` after the three `copy_components` calls (line 130)
3. Function logic: derive PROJECT_README, check existence, grep for "ship-kit", append if not found

**Acceptance Criteria:**
- [x] Footer appended to README.md when running with `--scope <path>`
- [x] Footer appended to README.md when running with `--scope project`
- [x] `[skip]` message when footer already present
- [x] Silent skip when README.md does not exist
- [x] Silent skip when `--scope user`
- [x] Shellcheck passes

**Files to Modify:**
- `install.sh`

**Tests Required:**
- [ ] Manual: `./install.sh --scope ../boxpiper` appends footer
- [ ] Manual: re-run shows `[skip]` message
- [ ] Manual: shellcheck passes

---

### Task 2: Create GitHub issue for tracking
**Status:** Completed
**Estimated Effort:** S
**Dependencies:** None
**Priority:** Medium
**Blocker:** None

**Description:**
Create a GitHub issue to track this feature per taskTracking config.

**Acceptance Criteria:**
- [x] GitHub issue created with feature label (https://github.com/sanmak/ship-kit/issues/10)

**Files to Modify:**
- None (external action)

## Implementation Order
1. Task 1 (core implementation)
2. Task 2 (tracking — parallel)

## Progress Tracking
- Total Tasks: 2
- Completed: 2
- In Progress: 0
- Blocked: 0
- Pending: 0
