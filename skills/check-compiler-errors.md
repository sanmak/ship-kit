# Check Compiler Errors

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`

## Procedure

1. **Auto-detect project type** from files present in the repository root:
   - `tsconfig.json` -> TypeScript -> run `npx tsc --noEmit`
   - `Cargo.toml` -> Rust -> run `cargo check 2>&1`
   - `go.mod` -> Go -> run `go build ./... 2>&1`
   - `pyproject.toml` -> Python -> run `python3 -m py_compile` on changed files
   - If multiple config files are detected, try all applicable compilers/type-checkers.

2. **Run the compile / type-check command** identified in step 1.

3. **Parse the output into structured errors.** Each entry should contain:
   - `file` — the file path
   - `line` — line number
   - `column` — column number
   - `message` — the error or warning message
   - `severity` — `error` or `warning`

4. **Sort by severity** — errors first, then warnings.

5. **Return the result:**
   - List of errors with file locations
   - Total error count
   - Total warning count

## Callers

Called by: `/pr-fix`, `/monitor`, `/loop-on-ci`, `/run-smoke-tests`.
