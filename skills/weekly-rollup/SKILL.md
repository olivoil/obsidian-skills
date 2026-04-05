---
name: weekly-rollup
description: Generate a weekly summary from daily notes — time totals, meeting highlights, coding sessions, key decisions, and todo progress. Use when asked for a weekly summary from daily notes, meetings, and todos.
---

# Weekly Rollup

Generate a weekly summary note from daily notes, aggregating time entries, meetings, coding sessions, decisions, and todo progress.

## Workflow

### Phase 1: Setup

1. Determine the vault root.
   - **Preferred**: if the Obsidian CLI is available and responsive, run `obsidian vault info=path` and use the returned path.
   - **Fallback**: if the CLI is unavailable, the app is not running, or the command does not return the expected payload, treat the current repo root as the vault root and continue by reading files directly.
2. Determine the target week:
   - If an argument is provided (e.g., `weekly-rollup 2026-02-17`), use the week containing that date
   - Otherwise, use the current week
3. Calculate Monday–Sunday dates for the target week.
4. Compute the ISO week number (`YYYY-WNN`) for the output filename.

### Phase 2: Collect Data

Read all daily notes for the target week. Prefer Obsidian CLI reads when available, but fall back to direct filesystem reads whenever needed.

For each day that has a note:

1. **Time entries**: Prefer `obsidian read path="Daily Notes/{date}.md"`, otherwise read `Daily Notes/{date}.md` from disk directly. Parse the structured bullet list at the top. Extract project, activity description, and hours for each line.
2. **Meetings & Coding sessions**: Prefer `obsidian links file="{date}"` if it works; otherwise parse wikilinks directly from the daily note. Filter for links pointing to `Meetings/` and `Coding/`. Read each linked note to get its summary (first paragraph after `# Title`), project, and participants.
3. **Todos**: Prefer Obsidian task commands if available. Otherwise scan project files directly for open and completed task lines, and infer completion dates from task metadata in the markdown. Track which were completed within the target week vs still open.
4. **Decisions**: For each meeting note, extract items from `## Decisions` sections.

### Phase 3: Aggregate

1. **Time by project**: Sum hours per project across all days. Break down by work type (meetings, dev, etc.) where inferable from the activity description.
2. **Meetings**: Group by project. Include one-line summary for each.
3. **Coding sessions**: List with one-line summaries.
4. **Todo stats**: Count completed, still open, and newly added during the week.
5. **Key decisions**: Collect from all meeting notes, attributed to the meeting.

### Phase 4: Generate Weekly Note

Build the weekly note content, then write it using the best available method:
- **Preferred**: `obsidian create path="Weekly Notes/{YYYY}-W{NN}.md" content="{content}"`
- **Fallback**: write `Weekly Notes/{YYYY}-W{NN}.md` directly on disk

If the file already exists and overwrite is approved, replace it in place.

```markdown
# Week of {Monday date}

## Time Summary
| Project | Hours | Activities |
|---------|-------|-----------|
| {Project} | {total} | {comma-separated activities} |
| ... | ... | ... |

**Total: {sum} hours**

## Meetings
### [[{Project}]]
- [[{Meeting Note Title}]] — {one-line summary}

## Coding Sessions
- [[{Coding Note Title}]] — {one-line summary}

## Key Decisions
- {decision} (from [[{Meeting Note}]])

## Todos
- Completed: {count} | Open: {count} | New this week: {count}

### Completed This Week
- [x] {todo text} ✅ {date} ([[Project]])

### Open
- [ ] {todo text} ([[Project]])
```

### Phase 5: Review & Write

1. **Present the generated note** to the user for review.
2. **Check idempotency**: Prefer `obsidian files folder="Weekly Notes"` to detect an existing note. If the CLI is unavailable, inspect the `Weekly Notes/` folder directly. Show a diff or clear summary of what would change, then ask whether to overwrite or skip.
3. **Write the note** if approved, using the Obsidian CLI when available or direct file writes otherwise.

## Key Rules

- **Read-only on daily notes** — never modify daily notes or time entries
- **Read-only on meeting/coding notes** — only read them for aggregation
- **Show before writing** — always preview the weekly note for approval
- **Idempotent** — re-running for the same week should produce the same output (or update an existing note)
- **Graceful with missing data** — if a day has no note, skip it. If a section is empty, omit it from the output.
