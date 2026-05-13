---
name: read-outlook-calendar
type: capability
description: Use when you need Outlook calendar events for a specific date — visually reads the day view via browser screenshot, extracts meetings with times, participants, and subjects
---

# Read Outlook Calendar

Visually read the Outlook Web calendar day view via browser screenshot and extract meeting data. Returns structured calendar events for callers to correlate with time entries, detect gaps, or validate durations.

## Inputs

- **date** (required): target date in `YYYY-MM-DD` format

## Process

**Prerequisite**: user must be logged into Outlook Web in the browser (Chrome with `--remote-debugging-port=9222`).

1. **Find or open Outlook Web tab**:
   - Call `list_pages` to see all open browser tabs
   - Look for a tab with URL containing `outlook.office.com` or `outlook.live.com`
   - If found: call `select_page` with that page's ID
   - If NOT found: call `new_page` with the day view URL

2. **Navigate to the target date's day view**:
   ```
   https://outlook.office.com/calendar/view/day/YYYY/M/D
   ```
   Note: month and day are **not zero-padded** (e.g., `2026/2/16` not `2026/02/16`).

   - If the tab is already on Outlook but wrong date: call `navigate_page` with the day view URL
   - If a new tab was created: it will already be on the correct URL

3. **Verify the date**: immediately after navigation, call `take_screenshot` and confirm the calendar is showing the correct date (visible in the date header).
   - If wrong date: wait 3 seconds, retry `navigate_page`. Take another screenshot.
   - If still wrong: try alternative URL format with zero-padded month/day.
   - **Only proceed once the correct date is confirmed.**

4. **Extract calendar data** visually from the verified screenshot:
   - **Meeting subjects** — the text on each calendar block
   - **Start and end times** — from the time labels on the left axis and block positions
   - **Duration** — calculated from start/end times
   - **Declined events** — shown with strikethrough text or dimmed/crossed-out appearance
   - **All-day events** — shown in the top banner area (above the hourly grid)
   - **Attendee names** — visible if shown in the calendar block
   - **Location** — if visible in the calendar block

   If the calendar is zoomed out and events are hard to read, note which events need clarification and proceed with what's visible.

   **CRITICAL**: Use `take_screenshot` for visual reading — do NOT use `take_snapshot`, DOM inspection, or click-based navigation for calendar data extraction. If the screenshot is unclear, take another screenshot — never fall back to DOM snapshots or clicking calendar elements.

## Output

Return structured calendar data:
- `events`: list of `{ subject, start_time, end_time, duration, attendees[], location, is_declined, is_all_day }`
- `date`: the confirmed date shown in the calendar
- `available`: boolean (false if Outlook tab could not be found or opened)

Declined events and all-day events are included in the output but flagged — the caller decides how to handle them.

If Outlook Web is not available or the date cannot be confirmed, return `{ available: false }` with no error.
