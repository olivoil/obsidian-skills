---
name: topic-pulse
description: Research recently active topics from the vault and update topic notes with fresh context, links, and concise summaries. Use when you want recent external context added to Topics notes or want a Pulse-style update based on what you touched recently.
---

# Topic Pulse

Research topics that were active in recent vault work, then update the corresponding `Topics/` notes with fresh external context.

This skill is intentionally separate from `refine-daily-note`. `refine-daily-note` improves a single day's note; `topic-pulse` deepens topic notes by bringing in current outside context.

## Goal

For a small set of relevant topics, gather current high-signal context from the web and write compact updates into the corresponding topic notes in the vault.

## Workflow

### Phase 0: Setup

1. Determine the vault root.
   - **Preferred**: if the Obsidian CLI is available and responsive, run `obsidian vault info=path` and use the returned path.
   - **Fallback**: if the CLI is unavailable, the app is not running, or the command does not return the expected payload, treat the current repo root as the vault root and continue by reading files directly.
2. Determine the scope:
   - If the user named one or more topics explicitly, use those.
   - Otherwise, inspect the requested date or the most recent 1-3 days of daily notes.
3. Read the relevant daily notes, linked meeting notes, and linked coding notes to identify which topics were active recently.

### Phase 1: Select candidate topics

Build a candidate list from:
- explicit topic names named by the user
- existing wikilinks to `Topics/` notes in recent notes
- repeated unlinked topic phrases that appear important in recent work

Then rank candidates by relevance. Prefer topics that are:
- repeated across multiple notes
- clearly tied to current work
- likely to benefit from fresh outside context

By default, work on **no more than 3 topics** in one run unless the user asks for more.

### Phase 2: Resolve topic notes

For each selected topic:

1. Check whether a corresponding note already exists under `Topics/`.
2. If the topic note exists, read it before researching so you can avoid repeating content.
3. If no note exists:
   - in interactive mode, propose creating it
   - in auto/unattended mode, skip missing topics unless the user explicitly asked to create them

### Phase 3: Research current context

For each selected topic, research recent or foundational context from the web.

Research rules:
- Prefer **primary sources** when the topic is technical, official, or product-specific.
- Use broader high-signal sources when the topic is market/news/general-interest.
- Favor recent information when the topic is time-sensitive.
- Keep the goal narrow: gather enough context to make the topic note more useful, not to write a full essay.

Collect:
- a 1-3 bullet summary of what matters now
- the most useful source links
- any terminology, decisions, or developments that help future note-taking

### Phase 4: Draft note updates

Update each topic note by adding or refreshing a compact section such as:

```markdown
## Pulse

### 2026-04-04
- Short summary bullet 1
- Short summary bullet 2

#### Sources
- [Source title](https://example.com)
- [Another source](https://example.com)
```

Guidelines:
- Keep updates concise and scannable
- Prefer additive updates over rewriting the whole note
- Avoid duplicating an existing Pulse entry for the same date
- If the note already has a `## Pulse` or `## Recent Context` section, append or refresh that section instead of inventing a new structure

### Phase 5: Review and write

1. Show the proposed topic updates before writing.
2. For each topic, explain:
   - why it was selected
   - what new context will be added
   - which sources informed the update
3. After approval, write the updates using the Obsidian CLI when available or direct file edits otherwise.

## Key Rules

- **Be selective** — this skill is better at 1-3 topics than at broad unattended research sweeps
- **Cite useful sources** — include links in the topic note so future work can trace them
- **Prefer current, high-signal context** — especially for changing technical or market topics
- **Avoid note bloat** — add compact, dated updates instead of long essays
- **Separate concerns** — this skill updates `Topics/` notes; it does not rewrite daily notes
