# Capability Index

This file tracks reusable capability skills that workflows can compose via `**USE CAPABILITY:**` markers.

## Status meanings

- `implemented` — the capability skill exists in `skills/`
- `planned` — named in the architecture, but not yet extracted into its own skill

## Foundation

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `discover-vault-entities` | Build a catalog of projects, people, topics, meetings, coding notes, and tags from the vault | none | `refine-daily-note`, `intervals-time-entry`, `transcribe-meeting`, `topic-pulse`, `weekly-rollup` | implemented |
| `write-vault-section` | Create or update a named section in a note with explicit write mode | writes note content | `session-rollup`, `intervals-time-entry`, `freshbooks-time-entry`, `intervals-to-freshbooks` | implemented |
| `resolve-mappings` | Load, resolve, or learn mappings from `.cache/om/intervals-cache/` | only `operation=learn` mutates cache files | `intervals-time-entry`, `freshbooks-time-entry`, `intervals-to-freshbooks` | implemented |

## Activity reading

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `read-github-activity` | Fetch PR/review/commit activity for a date | none | `refine-daily-note`, `intervals-time-entry` | implemented |
| `read-slack-activity` | Read Slack messages, group activity windows, and detect huddles | none | `refine-daily-note` | planned |
| `read-outlook-calendar` | Read Outlook day view and extract meetings visually | none | `intervals-time-entry` | planned |

## Note refinement

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `summarize-slack-activity` | Turn Slack activity into note-ready summary text | none | `refine-daily-note` | planned |
| `summarize-github-activity` | Turn GitHub activity into note-ready summary text | none | `refine-daily-note` | planned |
| `improve-note-prose` | Tighten prose without changing author intent | writes note content | `refine-daily-note` | planned |
| `add-missing-wikilinks` | Link known vault entities in unlinked text | writes note content | `refine-daily-note` | planned |
| `extract-note-sections` | Split large note sections into dedicated notes | creates and rewrites note content | `refine-daily-note` | planned |
| `suggest-new-vault-entities` | Identify likely missing project/person/topic notes | none | `refine-daily-note` | planned |
| `suggest-todo-completions` | Identify likely completed todos from note context | none | `refine-daily-note` | planned |
| `freeze-done-today` | Preserve prior daily-note completion snapshots | writes note content | `refine-daily-note` | planned |
| `move-inline-todos` | Move inline todos to longer-lived project pages | writes note content | `refine-daily-note` | planned |
| `update-project-recent-activity` | Update project notes with recent activity context | writes note content | `refine-daily-note` | planned |
| `enrich-person-notes` | Update person pages with meeting-derived context | writes note content | `refine-daily-note` | planned |

## Meeting and media

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `discover-recordings` | Find candidate screen and Rodecaster recordings | none | `transcribe-meeting` | planned |
| `match-recordings` | Pair audio and video recordings by overlap | none | `transcribe-meeting` | planned |
| `gather-meeting-context` | Gather names, project vocabulary, and context for transcription | none | `transcribe-meeting` | planned |
| `transcribe-audio` | Produce transcript segments from meeting audio | creates transcript output | `transcribe-meeting` | planned |
| `create-meeting-note` | Turn transcript + context into a structured meeting note | writes note content | `transcribe-meeting` | planned |
| `extract-meeting-screenshots` | Pull screenshots relevant to a meeting window | writes image artifacts | `transcribe-meeting` | planned |
| `publish-recording-assets` | Upload audio/video artifacts to external destinations | uploads external artifacts | `transcribe-meeting` | planned |

## Time and billing

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `fill-intervals-ui` | Fill Intervals UI with prepared entries | browser writes | `intervals-time-entry` | planned |
| `read-intervals-timesheet` | Read Intervals timesheet entries from browser | none | `intervals-to-freshbooks` | planned |
| `create-freshbooks-entries` | Create FreshBooks time entries via API | external API writes | `freshbooks-time-entry`, `intervals-to-freshbooks` | planned |
| `read-freshbooks-entries` | Read back created FreshBooks entries for verification | none | `freshbooks-time-entry`, `intervals-to-freshbooks` | planned |
| `verify-freshbooks-sync` | Compare expected vs created FreshBooks entries | none | `intervals-to-freshbooks` | planned |
| `refresh-freshbooks-browser` | Refresh FreshBooks browser state after sync | browser writes | `freshbooks-time-entry` | planned |

## Rollups and research

| Capability | Purpose | Side effects | Used by | Status |
|---|---|---|---|---|
| `read-engram-memory` | Read recent project memory from Engram | none | `session-rollup` | planned |
| `gather-repo-metadata` | Gather repo, branch, and file-change context | none | `session-rollup` | planned |
| `create-coding-session-note` | Generate a coding-session note body | writes note content | `session-rollup` | planned |
| `collect-weekly-source-notes` | Gather the week’s daily notes and linked notes | none | `weekly-rollup` | planned |
| `aggregate-weekly-time` | Summarize weekly time from note data | none | `weekly-rollup` | planned |
| `summarize-weekly-meetings` | Summarize meetings across a week | none | `weekly-rollup` | planned |
| `summarize-weekly-coding-sessions` | Summarize coding sessions across a week | none | `weekly-rollup` | planned |
| `summarize-weekly-decisions` | Extract and summarize key decisions | none | `weekly-rollup` | planned |
| `summarize-weekly-todos` | Summarize todo progress | none | `weekly-rollup` | planned |
| `create-weekly-note` | Produce the weekly rollup note body | writes note content | `weekly-rollup` | planned |
| `select-active-topics` | Choose candidate topics for fresh research | none | `topic-pulse` | planned |
| `resolve-topic-notes` | Resolve topic names to note paths | none | `topic-pulse` | planned |
| `research-topic-context` | Gather current outside context for a topic | none | `topic-pulse` | planned |
| `draft-topic-pulse` | Draft the new pulse section for a topic note | writes note content | `topic-pulse` | planned |
