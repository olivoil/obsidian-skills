---
name: read-slack-activity
type: capability
description: Use when you need Slack message activity for a specific date — searches messages, groups by channel and time window, detects huddles, infers channel-to-project mappings
---

# Read Slack Activity

Search Slack for user messages on a specific date, group activity by channel and time window, detect huddles, and infer channel→project mappings. Returns structured activity data for callers to summarize, correlate with time entries, or display.

## Inputs

- **date** (required): target date in `YYYY-MM-DD` format
- **user_id** (required): Slack user ID (e.g., `U07J89FDWPJ`)
- **vault_root** (optional): path to Obsidian vault root, used for loading cached slack-mappings from `.cache/om/intervals-cache/slack-mappings.md`
- **time_entries** (optional): structured time entries from the daily note (start times, durations, projects), used to identify uncovered gaps

## Process

1. **Check prerequisites**: verify Slack tools are available in the current harness. If no Slack tools are available, skip quietly and return empty output.

2. **Search for user messages** on the target date using `slack_search_public_and_private`:
   - Query: `from:<@{user_id}> on:{date}`

3. **Group messages** by channel and 30-minute time windows.

4. **Build a time coverage map** from `time_entries` input (if provided) — start times, durations, projects.

5. **Identify gaps**: time windows with 3+ Slack messages but no matching time entry.

6. **Detect huddles**: for each DM or group DM channel found in step 2, read messages around the activity window using `slack_read_channel` with `oldest`/`latest` timestamps. Look for messages from Slackbot containing `"A huddle started"`.
   - Slack's search API does **not** index huddle system messages — they can only be found by reading the channel directly.
   - When a huddle is found, record:
     - **Start time**: the Slackbot message timestamp
     - **Participants**: inferred from the DM/group DM members (the channel context)
     - **Estimated duration**: gap between the huddle start and the next human message in the channel (rough estimate — Slack does not expose huddle duration via API)
   - Huddles should **always** have a corresponding time entry. Flag any huddle that doesn't match an existing entry.

7. **Infer channel→project mappings** from channel names and existing time entries:
   - Check cached mappings in `{vault_root}/.cache/om/intervals-cache/slack-mappings.md` (if vault_root provided)
   - If a new channel→project mapping is discovered, note it in the output for the caller to persist

## Output

Return structured activity data:
- `channels`: list of `{ channel_name, channel_id, time_window, message_count, is_dm }`
- `huddles`: list of `{ channel_name, participants, start_time, estimated_duration, has_matching_entry }`
- `uncovered_gaps`: list of `{ channel_name, time_window, message_count, suggested_project }` — activity windows with no matching time entry
- `new_mappings`: list of `{ channel_name, inferred_project }` — newly discovered channel→project associations for the caller to persist
- `available`: boolean (false if Slack tools were unavailable)

If Slack tools are not available, return `{ available: false }` with no error.
