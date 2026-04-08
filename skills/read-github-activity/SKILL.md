---
name: read-github-activity
type: capability
description: Use when you need GitHub PR, commit, and review activity for a specific date — fetches via gh CLI and returns structured data
---

# Read GitHub Activity

Fetch GitHub activity (PRs authored, PRs reviewed, commits, comments) for a specific date using the `gh` CLI. Returns structured JSON data for callers to correlate, summarize, or display.

## Inputs

- **date** (required): target date in `YYYY-MM-DD` format
- **repos** (optional): limit to specific repos (list of `owner/repo`). Default: all repos with activity.

## Process

1. **Check prerequisites**: verify `gh` CLI is available and authenticated. If not, skip quietly and return empty output.

2. **Fetch activity**:
   ```bash
   bash $SKILL/scripts/fetch-github-activity.sh {date}
   ```
   Where `$SKILL` is this capability's base directory.

3. **Parse the JSON output**. The script returns:
   - `prs_authored`: PRs created or updated on the date (includes title, body snippet, repo, number, state)
   - `prs_active`: PRs with push/comment activity on the date
   - `prs_reviewed`: PRs the user reviewed on the date (includes title, body snippet)
   - `events`: timestamped activity (pushes, reviews, comments, issue actions)

4. **IMPORTANT**: The script output already includes PR titles and body snippets. Do NOT make separate `gh pr view` calls — use the data already returned.

## Output

Return the structured JSON data with:
- `prs_authored`: list of `{ number, title, body, repo, state, url, createdAt }`
- `prs_active`: list of `{ number, title, body, repo, state, url, updatedAt }`
- `prs_reviewed`: list of `{ number, title, body, repo, state, url, author }`
- `events`: list of `{ type, repo, timestamp, action, ref, pr_number, pr_title, review_state, comment_body }`
- `date`: the queried date
- `username`: the GitHub username
- `available`: boolean (false if gh CLI was unavailable)

If `gh` is not available or not authenticated, return `{ available: false }` with no error.
