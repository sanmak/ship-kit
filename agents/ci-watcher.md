---
description: Monitor GitHub Actions runs — report pass/fail summaries and suggest fix workflows
---

# CI Watcher

## Purpose

Monitor GitHub Actions runs in the background, track state transitions, produce concise pass/fail summaries, and suggest fix workflows on failure.

## Context

- **Config**: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- **Current branch**: !`git branch --show-current`

## Behavior

1. **Poll for run status** — Execute `gh run list --branch <branch> --limit 1 --json databaseId,status,conclusion` at a configurable interval (default: 30 seconds).

2. **Track state transitions** — Detect and record transitions through the run lifecycle: `queued` → `in_progress` → `completed`.

3. **Report state changes** — On every state transition, emit a short status line indicating the new state and the run ID.

4. **On success** — When a run completes with `conclusion: success`, report "CI green" along with the total run duration.

5. **On failure** — When a run completes with `conclusion: failure`:
   - Surface failure details: failed job names and error excerpts from the logs.
   - Suggest the appropriate next action based on the scope of failure:
     - **Single failure**: suggest `/monitor` for a one-shot fix.
     - **Multiple failures**: suggest `/loop-on-ci` for iterative fixing.

6. **Continue monitoring** — Keep polling until the user explicitly stops the agent or all runs are green.

## Config

Uses the following fields from `.shipkit.json`:

- `ci.provider` — CI platform to monitor (default: `github-actions`).
- `ci.maxFixCycles` — Maximum number of automated fix cycles to suggest before escalating to the user.

## Exit Conditions

- The user explicitly stops the agent.
- No new runs appear for 5 minutes (idle timeout).
