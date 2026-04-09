---
name: topic-pulse
type: workflow
uses:
  - discover-vault-entities
description: Research recently active topics from the vault and deepen topic notes with concept documentation, subtopic exploration, and selective fresh context. Use when you want Topics notes expanded from recent vault activity.
---

# Topic Pulse

Research topics that were active in recent vault work, then update the corresponding `Topics/` notes with enough conceptual framing and supporting detail to make the notes genuinely useful later.

This skill is intentionally separate from `refine-daily-note`. `refine-daily-note` improves a single day's note; `topic-pulse` deepens topic notes by bringing in current outside context.

## Goal

For a small set of relevant topics, gather the most useful context from the vault and the web, then deepen the corresponding topic notes in the vault.

The output should not be just a thin news-style pulse. The main job is to identify what deserves fuller explanation, what subtopics should exist, and what knowledge gaps should be filled so the vault becomes a better long-term reference.

## Workflow

### Phase 0: Setup

1. Determine the vault root.
   - **Preferred**: if the Obsidian CLI is available and responsive, run `obsidian vault info=path` and use the returned path.
   - **Fallback**: if the CLI is unavailable, the app is not running, or the command does not return the expected payload, treat the current repo root as the vault root and continue by reading files directly.
2. Determine the scope:
   - If the user named one or more topics explicitly, use those.
   - Otherwise, inspect the requested date or recent note activity.
3. Build the source corpus from recent notes across the main vault areas that carry topical signal:
   - `Daily Notes/`
   - `Clippings/`
   - `Topics/`
   - `Projects/`
   - `Coding/`
   - `Meetings/`
   - optionally `Weekly Notes/` when they help summarize a thread of work
4. Prefer recency, but do not limit yourself to only daily notes. The goal is to detect what the user has been thinking about across the vault, not just what was journaled today.
5. Build a simple evidence log for candidate topics: which recent notes, links, repeated phrases, or clusters of related documents pointed to each topic.

### Phase 1: Select candidate topics

**USE CAPABILITY: discover-vault-entities**
Pass the vault root. Request `topics` and `projects` types.

Build a candidate list from:
- explicit topic names named by the user
- existing wikilinks to `Topics/` notes in recent notes (cross-reference against the entity catalog)
- repeated unlinked topic phrases that appear important in recent work — verify against the entity catalog before treating them as candidates
- recent notes in `Clippings/`, `Projects/`, `Coding/`, `Meetings/`, `Topics/`, and `Daily Notes/`
- clusters of notes that imply a broader topic needing better structure

Then rank candidates by relevance. Prefer topics that are:
- repeated across multiple notes
- reinforced by multiple folders or note types
- clearly tied to current work
- likely to benefit from deeper explanation or better organization

By default, work on **no more than 3 topics** in one run unless the user asks for more.

### Phase 2: Resolve topic notes

For each selected topic:

1. Check whether a corresponding note already exists under `Topics/`.
2. If the topic note exists, read it before researching so you can avoid repeating content.
3. If no note exists:
   - in interactive mode, propose creating it
   - in auto/unattended mode, skip missing topics unless the user explicitly asked to create them
4. Decide what kind of update the note needs:
   - **Expand in place**: the note is thin or incomplete but still belongs as one document
   - **Add subtopic sections**: the note needs clearer internal structure and named subsections
   - **Split into subtopic notes**: the topic has multiple durable sub-subjects that deserve their own notes

### Phase 2b: Decide note organization

Use this default organization rule:

- **Default to flat**: one note per topic under `Topics/`
- **Promote to a folder only when warranted**: create `Topics/<Topic>/` when the topic now has multiple durable subtopics, recurring investigations, or reference notes that would clutter a single file
- When creating a topic folder, prefer an index note at `Topics/<Topic>/<Topic>.md`
- Put narrow, reusable subtopic notes inside that folder

Use a folder when at least one of these is true:
- there are 3 or more stable subtopics that would each benefit from their own note
- the topic mixes a high-level overview with repeated case notes, issue notes, or implementation deep dives
- the topic is becoming a miniature knowledge area rather than a single concept

Otherwise, keep the topic flat and improve the single note.

### Phase 3: Research current context

For each selected topic, research both:
- the current vault context already captured in recent notes
- any outside context needed to explain or complete the topic

Research rules:
- Prefer **primary sources** when the topic is technical, official, or product-specific.
- Use broader high-signal sources when the topic is market/news/general-interest.
- Favor recent information when the topic is time-sensitive.
- Prefer explanatory material over trend-chasing when the note is conceptually weak.
- Keep the goal narrow: gather enough context to make the topic note more useful, not to write a full essay.

Collect:
- a compact explanation of the topic when the note is thin:
  - what it is
  - why it matters
  - the key moving parts, terms, or tradeoffs
- the most important subtopics or questions that should be documented next
- a 1-3 bullet summary of what matters now, only when recent developments are actually useful
- the most useful source links
- any terminology, decisions, or developments that help future note-taking

When recent vault notes are available, use them as hints for:
- which subtopics matter most
- which questions keep reappearing
- which ideas the user probably wants to understand rather than merely track

### Phase 4: Draft note updates

Update each topic note by improving whichever structure is appropriate, for example:

```markdown
## Overview

Short explanation of what this topic is and why it matters.

### Key Ideas
- Important concept 1
- Important concept 2
- Important concept 3

## Subtopics
- [[Subtopic A]]
- [[Subtopic B]]
```

Use a dated recent-context section only when it adds value:

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
- If the note is thin, add a compact explanatory section such as `## Overview`, `## Key Ideas`, `## Why It Matters`, or `## Mental Model`
- If the note is broad, add a `## Subtopics`, `## Related Questions`, or `## Open Threads` section
- If a subtopic deserves its own note, propose or create a dedicated note and link it from the parent topic
- Prefer 4-10 bullets or 1-3 short paragraphs for concept documentation, not a long essay
- Keep foundational explanation stable and use `## Pulse` only for dated context that is genuinely worth preserving
- Keep updates concise and scannable
- Prefer additive updates over rewriting the whole note
- Avoid duplicating an existing dated entry for the same date
- If the note already has a `## Pulse` or `## Recent Context` section, append or refresh that section instead of inventing a new structure
- If the note already has a good explanatory section, improve it lightly instead of rewriting it from scratch

### Phase 5: Review and write

1. Show the proposed topic updates before writing.
2. For each topic, explain:
   - why it was selected
   - which recent notes or folders led to it
   - whether the note should stay flat or become a topic folder
   - what explanatory material or subtopics will be added
   - which sources informed the update
3. After approval, write the updates using the Obsidian CLI when available or direct file edits otherwise.

## Key Rules

- **Be selective** — this skill is better at 1-3 topics than at broad unattended research sweeps
- **Use recent notes broadly** — any recent note in the main vault folders can be evidence for a topic
- **Do more than link-dumping** — topic notes should explain concepts and identify subtopics when they are currently too thin
- **Prefer flat by default** — create topic folders only when the topic has clearly outgrown a single note
- **Cite useful sources** — include links in the topic note so future work can trace them
- **Prefer explanatory completeness over novelty** — current context matters, but only when it actually improves the topic note
- **Avoid note bloat** — add compact, dated updates instead of long essays
- **Separate concerns** — this skill updates `Topics/` notes; it does not rewrite daily notes
