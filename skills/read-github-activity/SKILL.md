---
name: read-github-activity
type: capability
used_by:
  - refine-daily-note
  - intervals-time-entry
description: Use when a workflow needs GitHub PR, review, and commit activity for a specific date to correlate or summarize work.
---

# Read GitHub Activity

Fetch GitHub activity for a specific date using the `gh` CLI and return structured data that workflows can correlate, summarize, or display.

## Inputs

- **date** (required): target date in `YYYY-MM-DD` format
- **repos** (optional): list of `owner/repo` values to focus on. Default: all repos with activity.

## Process

1. Verify `gh` is available and authenticated. If not, return `available: false` with no error.
2. Run:

```bash
bash $SKILL/scripts/fetch-github-activity.sh {date}
```

Where `$SKILL` is this capability's base directory.

3. Parse the JSON output. The script returns:
   - `prs_authored`
   - `prs_active`
   - `prs_reviewed`
   - `events`
4. Use the returned PR titles and body snippets directly. Do not make extra `gh pr view` calls for the same data.

## Output

Return structured JSON with:

- `prs_authored`
- `prs_active`
- `prs_reviewed`
- `events`
- `date`
- `available`

If `gh` is unavailable or unauthenticated, return:

```json
{ "available": false }
```
