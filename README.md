# obsidian-skills

Cross-agent skills for maintaining my personal Obsidian vault.

This repo is public. My vault is not.

These skills are how I use agents like Claude Code and Codex to help maintain the vault I actually work out of: refining daily notes, generating weekly rollups, transcribing meetings, enriching topic notes, and reconciling time-tracking data with external systems.

They are not meant to be a universal Obsidian framework. They encode *my* workflow and assumptions first, but I am publishing them because the overall pattern may still be useful to adapt.

## How I use Obsidian

My vault is not just a notes app. It is my operating log.

A typical week looks something like this:

- I keep a structured **daily note** with time entries, links, and working notes.
- Meetings eventually become dedicated **meeting notes** with summaries, decisions, and follow-ups.
- Coding work is summarized into **coding notes** so it is easier to reconstruct what changed and why.
- Projects, people, and topics are linked together as a lightweight knowledge graph.
- At the end of the week, I generate a **weekly rollup** that summarizes time, meetings, decisions, and open work.
- Some of that information also needs to be reconciled with systems like **Intervals** and **FreshBooks**. I use Intervals to log work time and FreshBooks for billing/invoicing, so a few skills bridge the vault with those systems.

The goal of these skills is not just to automate text editing. The goal is to help keep Obsidian accurate, navigable, and useful as a long-term knowledge base.

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

Some skills are more opinionated than others. In particular:

- `refine-daily-note` assumes daily notes are central
- `weekly-rollup` assumes the weekly note is derived from daily notes and linked notes
- `transcribe-meeting` assumes meeting notes live in `Meetings/`
- `session-rollup` assumes coding-session summaries live in `Coding/`

If your vault uses different folder names or a different note model, expect to adapt the skills.

## Included skills

The repo now distinguishes between two kinds of skills:

- **Workflow skills** — user-facing outcomes that orchestrate multiple steps
- **Capability skills** — smaller reusable actions that workflows reference via `**USE CAPABILITY:**`

See [`docs/CAPABILITIES.md`](./docs/CAPABILITIES.md) for the current capability index and planned extraction map.

### Capability skills

These are the first extracted reusable capabilities:

### `discover-vault-entities`
Build a vault entity catalog (projects, people, topics, meetings, coding notes, tags) for matching, linking, and context resolution.

### `write-vault-section`
Create or update a named markdown section in a note with explicit replace/append semantics.

### `read-github-activity`
Fetch GitHub PR/review/commit activity for a date and return normalized structured data.

### `resolve-mappings`
Load, resolve, or learn mappings from `.cache/om/intervals-cache/`.

### `refine-daily-note`
Improve a daily note by polishing writing, adding missing links, extracting longer sections when appropriate, and enriching related vault context from Slack and GitHub activity.

### `weekly-rollup`
Generate a weekly note from the current ISO week by aggregating daily notes, linked meetings, coding sessions, decisions, and todo progress.

### `transcribe-meeting`
Process a meeting recording into a structured meeting note with summary, decisions, action items, and transcript artifacts.

### `session-rollup`
Use Engram as the system of record for recent work, then write a coding note into the vault and link it from the daily note.

### `intervals-time-entry`
Use daily notes, GitHub activity, and other context to prepare or fill Intervals time entries.

### `intervals-to-freshbooks`
Copy a week of time entries from Intervals into FreshBooks.

### `freshbooks-time-entry`
Sync Intervals data from local SQLite state into FreshBooks without re-reading everything from the browser.

### `topic-pulse`
Research recently active topics from recent notes across the vault, then deepen `Topics/` notes with concept documentation, subtopic exploration, and selective fresh context.

## Agent model

These skills are designed to work with both **Claude Code** and **Codex**.

The important design choices are:

- shared runtime state lives in the **consumer repo**, not in the skill repo
- mutable mappings are treated as local runtime data, not checked-in source files
- the same cache files should work no matter which agent you use

In practice, I usually invoke these skills explicitly:

- in Claude Code: slash-command style
- in Codex: `$skill-name`

For Codex, each skill includes `agents/openai.yaml` metadata and disables implicit invocation, because I usually know exactly which skill I want and these skills often write to the vault or external systems.

## Shared runtime state and mutable mappings

These skills expect the consumer repo to hold shared state at:

```text
.cache/om/
├── intervals-cache/
│   ├── project-mappings.md
│   ├── github-mappings.md
│   ├── outlook-mappings.md
│   ├── slack-mappings.md
│   ├── people-context.md
│   └── freshbooks-mappings.md
└── time-entries.db
```

This state is **not** part of the reusable skill source. It is local runtime data that belongs to the consumer vault repo.

I keep it there for a few reasons:

- I want to be able to switch between Claude and Codex without losing context
- I do not want private or evolving mappings checked into the public skill repo
- several workflows get better over time if they can reuse what they have already learned

### What “mutable mappings” means

Some of these skills depend on associations that are specific to my vault and my work. For example:

- a GitHub repo usually maps to a specific client or project
- a Slack channel often corresponds to a specific project
- an Outlook calendar event may imply a particular project context
- a person may have context that is useful when enriching notes
- an Intervals project may need to map to a FreshBooks client/project combination

Those mappings are **mutable** because they are not fixed forever. They evolve as my work changes, and the skills can read, extend, and reuse them over time.

That is why the repo ships templates, but the live data belongs under `.cache/om/` in the consumer repo.

## Obsidian CLI notes

Some skills can use the Obsidian CLI when it is available.

In my setup, the CLI is effectively app-backed: it works best when the Obsidian desktop app is already running. Because of that, the skills are written to:

- **prefer** the Obsidian CLI when it is available and responsive
- **fall back** to direct vault file reads/writes when it is not

That means they can still run in headless or agent-driven workflows where the app is not open.

## Other tools and dependencies

Depending on the skill, my real setup also uses some combination of:

- Obsidian desktop app / Obsidian CLI
- Chrome or Chromium with remote debugging enabled
- `gh`
- `sqlite3`
- `ffmpeg`
- FreshBooks API credentials
- Google Drive / YouTube / recording workflows
- Engram for cross-agent memory

Not every skill needs every dependency.

## Install

See [INSTALL.md](./INSTALL.md).

The usual local setup is:

```bash
./install.sh ~/Code/github.com/olivoil/obsidian
```

That installs the skills into the consumer repo for both Claude Code and Codex, creates the shared cache under `.cache/om`, and migrates data from the older Claude-only layout if it exists.

## Privacy and customization

This repo intentionally ships **templates**, not my real mapping data.

If you install these skills into your own vault, you should expect to customize:

- folder names
- project mappings
- person/context mappings
- external tool assumptions
- note formats and frontmatter conventions

The public repo is the reusable part. The private vault is still where the actual knowledge base lives.
