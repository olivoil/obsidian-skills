# Obsidian skills

Skills for maintaining my personal Obsidian vault: refining daily notes, generating weekly rollups, transcribing meetings, enriching topic notes, and reconciling time-tracking data with external systems.

They are not meant to be a universal Obsidian framework. They encode my workflow and assumptions first, but the overall pattern may be useful to adapt.

## Install all Obsidian skills

From the vault repo:

```bash
cd ~/Code/github.com/olivoil/obsidian
npx skills add https://github.com/olivoil/skills/tree/main/skills/obsidian --skill '*' --agent codex claude-code
```

For local development from this checkout:

```bash
cd ~/Code/github.com/olivoil/obsidian
npx skills add ~/Code/github.com/olivoil/skills/skills/obsidian --skill '*' --agent codex claude-code
```

Then run the setup skill once from the vault repo:

```text
$setup-obsidian-skills
```

The setup skill creates shared runtime state under `.cache/om` and migrates data from the older Claude-only layout if it exists.

## Vault assumptions

These skills assume a vault structure roughly like this:

```text
Daily Notes/
Weekly Notes/
Meetings/
Coding/
Projects/
Persons/
Topics/
```

Some skills are more opinionated than others:

- `refine-daily-note` assumes daily notes are central.
- `weekly-rollup` assumes weekly notes are derived from daily notes and linked notes.
- `transcribe-meeting` assumes meeting notes live in `Meetings/`.
- `session-rollup` assumes coding-session summaries live in `Coding/`.

If your vault uses different folder names or a different note model, expect to adapt the skills.

## Skills

- `discover-vault-entities` — build a catalog of vault entities for matching, linking, and context.
- `freshbooks-time-entry` — sync Intervals data from local SQLite state into FreshBooks.
- `generate-project-dashboard` — create or update an Obsidian project dashboard / HTML project note.
- `intervals-time-entry` — prepare and fill Intervals time entries from daily notes, GitHub, and calendar context.
- `intervals-to-freshbooks` — copy a week of Intervals time entries into FreshBooks.
- `read-github-activity` — fetch GitHub PR, commit, and review activity for a date.
- `read-outlook-calendar` — read Outlook calendar events for a date.
- `read-slack-activity` — summarize Slack message activity and infer project mappings.
- `refine-daily-note` — polish a daily note, add wikilinks, and enrich context.
- `refresh-project-dashboards` — find and refresh stale project dashboards.
- `resolve-mappings` — load, apply, and learn shared project/repo/calendar/channel mappings.
- `session-rollup` — summarize recent work from memory into a coding note.
- `setup-obsidian-skills` — initialize or repair `.cache/om` runtime state.
- `topic-pulse` — deepen topic notes from recent vault activity and research.
- `transcribe-meeting` — process a meeting recording into a structured meeting note.
- `weekly-rollup` — generate weekly summary notes from daily notes and linked context.
- `write-vault-section` — append or replace named sections in Obsidian notes.

## Shared runtime state

The setup skill creates/preserves:

```text
.cache/om/
├── intervals-cache/
│   ├── project-mappings.md
│   ├── github-mappings.md
│   ├── outlook-mappings.md
│   ├── slack-mappings.md
│   ├── people-context.md
│   ├── freshbooks-mappings.md
│   └── worktype-mappings.md
└── time-entries.db
```

This state belongs to the consumer vault repo, not this skills source repo.
