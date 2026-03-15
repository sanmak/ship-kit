# Get PR Comments

Fetch and parse PR review comments, grouping them by file and thread for downstream consumption.

## Context

- Config: !`cat .shipkit.json 2>/dev/null || echo '{}'`
- Current branch: !`git branch --show-current`

## Procedure

### 1. Determine PR Number

If a PR number is provided as an argument, use it directly.

Otherwise, auto-detect the PR associated with the current branch:

```bash
gh pr view --json number -q .number
```

If no PR is found for the current branch, report:

```
ERROR: No pull request found for branch <branch-name>.
Push the branch and open a PR first, or pass a PR number explicitly.
```

Exit immediately.

### 2. Fetch Review Comments

Retrieve the repository owner and name:

```bash
gh repo view --json owner,name -q '"\(.owner.login)/\(.name)"'
```

Fetch line-level review comments (comments attached to specific lines in the diff):

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate
```

Fetch top-level review comments (review body summaries submitted with approve/request-changes/comment):

```bash
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate
```

### 3. Group by File and Issue

Parse the fetched comments and organize them:

1. **Filter out bot comments** — Exclude comments where the author type is `Bot` (e.g., dependabot, codecov, github-actions). Keep only human reviewer comments.
2. **Group by file path** — Use the `path` field from line-level comments to bucket them per file. Top-level review comments (from `/reviews`) have no file association; collect these in a separate "general" group.
3. **Thread related comments** — Within each file group, cluster comments that share the same `line`/`original_line` range or are linked via `in_reply_to_id` into a single thread. A thread represents one conversation about a specific code location.

### 4. Parse into Structured Data

Extract the following fields for each comment:

| Field | Source | Description |
|-------|--------|-------------|
| `file` | `path` | File path the comment is attached to (null for top-level reviews) |
| `line` | `line` or `original_line` | Line number in the diff |
| `body` | `body` | Comment text (markdown) |
| `author` | `user.login` | GitHub username of the commenter |
| `status` | derived | `active` if the comment is on current code, `resolved` if the review thread was resolved, `outdated` if the diff position is no longer valid (indicated by `position: null`) |
| `comment_id` | `id` | Unique comment identifier |
| `in_reply_to` | `in_reply_to_id` | Parent comment ID if this is a reply (null for thread starters) |

For top-level review comments, additionally capture:

| Field | Source | Description |
|-------|--------|-------------|
| `state` | `state` | Review state: `APPROVED`, `CHANGES_REQUESTED`, `COMMENTED`, `DISMISSED` |
| `submitted_at` | `submitted_at` | Timestamp of the review submission |

### 5. Return Results

Return the grouped review comments in this structure:

```
PR #<number> Review Comments (<total_count> comments across <file_count> files)

General Reviews:
  - <author> (<state>): <body summary>
  ...

File: <path>
  Thread 1 (line <N>, <status>):
    - <author>: <body>
    - <author>: <reply body>
  Thread 2 (line <M>, <status>):
    - <author>: <body>
  ...

File: <path>
  ...
```

If there are no comments on the PR, report:

```
PR #<number> has no review comments.
```

## Returns

- `pr_number` — the resolved PR number
- `total_count` — total number of comments (excluding bots)
- `file_groups` — list of file groups, each containing threaded comments
- `general_reviews` — list of top-level review comments with state
- `has_unresolved` — whether any active/unresolved threads remain

## Notes

- This skill is called by `/pr-fix`, `/review`, `/pr-review-canvas`
- If no PR is found for the current branch, report the error and exit — do not prompt the user
- Bot comments are filtered out by default to reduce noise
- Both line-level review comments (`/pulls/{number}/comments`) and top-level review body comments (`/pulls/{number}/reviews`) are included
- Pagination is handled via `--paginate` to ensure all comments are retrieved on large PRs
- Outdated comments (where the diff position is no longer valid) are still included but marked with status `outdated`
