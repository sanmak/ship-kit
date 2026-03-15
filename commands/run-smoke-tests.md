---
description: Run Playwright smoke tests and triage failures
allowed-tools: Bash(git:*), Bash(npx:*), Bash(cat:*), Bash(tsc:*), Bash(cargo:*), Bash(go:*), Read, Write, Edit, Grep, Glob
argument-hint: "[test-path]"
---

# /run-smoke-tests

Run smoke tests, parse results, triage failures into categories, and report with suggested fixes.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`

## Procedure

### 1. Determine Test Command

Use `smokeTests.command` from config (default: `npx playwright test`).

If `[test-path]` argument is provided, append it:
```bash
npx playwright test <test-path>
```

### 2. Run Tests

Execute the test command with configured retries (`smokeTests.retries`, default: 1) and timeout (`smokeTests.timeout`, default: 60000ms):

```bash
npx playwright test --retries <retries> --timeout <timeout>
```

### 3. Parse Results

Parse the test output to extract:
- Test name and file path
- Pass/fail/skip status
- Error messages and stack traces
- Duration per test

If compile failures are detected in the output, call the **check-compiler-errors** skill.

### 4. Triage Failures

Categorize each failure:

- **Flaky** — passed on retry, or known flaky pattern (timeouts, network errors)
- **Environment** — missing dependencies, port conflicts, configuration issues
- **Genuine regression** — consistent failure with code-related error

### 5. Report

```
Smoke Test Results

  Total: 24 tests
  ✓ Passed: 20
  ✗ Failed: 3
  ⊘ Skipped: 1

  Failures:

  🔴 REGRESSION
  ┌ tests/auth.spec.ts:42 — "should redirect after login"
  │ Error: Expected URL to contain '/dashboard', got '/login'
  │ Suggested fix: Check auth redirect logic in src/auth.ts
  └

  🟡 FLAKY
  ┌ tests/api.spec.ts:78 — "should return user data"
  │ Error: Timeout 30000ms exceeded
  │ Note: Passed on retry — likely a timing issue
  └

  🔵 ENVIRONMENT
  ┌ tests/db.spec.ts:15 — "should connect to database"
  │ Error: ECONNREFUSED 127.0.0.1:5432
  │ Note: Database server not running
  └

  Report: playwright-report/ (if available)
```

### 6. Screenshot/Trace Links

If `smokeTests.reportDir` is configured and reports exist, include links:
```
  Screenshots: playwright-report/screenshots/
  Traces: playwright-report/traces/
```

## Notes

- Default runner is Playwright but the command is fully configurable
- Flaky tests are reported separately to avoid noise
- Environment issues are flagged but not auto-fixed (infrastructure dependency)
- Genuine regressions get suggested fixes based on error analysis
