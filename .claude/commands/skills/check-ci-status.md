# Check CI Status

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`

## Procedure

1. **Identify the latest CI run** on the current branch:
   ```bash
   gh run list --branch <branch> --limit 1 --json databaseId,status,conclusion,name,headSha
   ```
   Extract the `databaseId` as `<id>` for subsequent steps.

2. **If the run is still in progress, poll until it completes.**
   Check every 15 seconds:
   ```bash
   gh run view <id> --json status,conclusion
   ```
   Continue polling while `status` is `in_progress` or `queued`. Stop once it reaches a terminal state (`completed`).

3. **Parse run status and get per-job results:**
   ```bash
   gh run view <id> --json jobs
   ```
   Extract each job's `name`, `status`, and `conclusion`.

4. **For failures, check `ci.failureHints` config patterns first.**
   Read the `ci.failureHints` array from `.shipkit.json`. Each entry has a `pattern` and a `fix`. Match patterns against the failure output (e.g., pattern `"ENOSPC"` -> fix `"npm prune"`). If a hint matches, include it in the result.

5. **If no hint matches, retrieve failure logs:**
   ```bash
   gh run view <id> --log-failed
   ```
   Extract relevant log excerpts surrounding the error.

6. **Return the result:**
   - Run ID
   - Overall status: `success`, `failure`, or `cancelled`
   - Per-job results: list of `{ name, status, conclusion }`
   - Matched hints (if any)
   - Failure log excerpts (if no hints matched and the run failed)

## Callers

Called by: `/monitor`, `/loop-on-ci`, `ci-watcher` agent.

## Defaults

- Default CI provider: `github-actions`
