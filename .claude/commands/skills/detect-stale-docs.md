# Detect Stale Docs

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Recent changes: !`git diff --name-only HEAD~5..HEAD 2>/dev/null || git diff --name-only`

## Procedure

1. Determine the changed files from the recent changes context above, or from an explicit argument if one was provided.

2. Load `docs.dependencyMap` from the config. If it is not configured and `docs.autoDetect` is true (which is the default), auto-detect the dependency map:
   - Map `src/**` to `README.md`
   - Map all source files to matching docs in the `docs/` directory

3. Match the changed source files against the `sources` patterns in the dependency map using glob matching.

4. For each matched source pattern, identify the linked docs files.

5. Check whether each linked doc has been updated since the source change by comparing last-modified timestamps:
   ```bash
   git log -1 --format=%ct -- <file>
   ```

6. Return the list of stale docs, including for each entry:
   - Doc path
   - Triggering source files
   - How stale the doc is (number of commits since the last doc update)

## Called by

`/docs-sync`
