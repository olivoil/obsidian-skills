---
name: generate-project-dashboard
description: Use when creating or updating an Obsidian project dashboard, HTML project note, project status page, or project Markdown source-of-truth for a specific project.
---

# Generate Project Dashboard

Create or refresh a grounded project dashboard for one Obsidian project. The Markdown project note is the durable source of truth; the HTML file is a read-only, more expressive dashboard rendering.

## Inputs

- Project name, folder, or note path.
- Vault root, default to the current repository root.
- Optional style request. Default to the bundled Analyst Slate style.

## Required reference

Read `references/design.md` before writing HTML or dashboard copy.

## Workflow

1. **Resolve the project**
   - Find `Projects/{Project}/{Project}.md` first.
   - If the folder/name differs, use vault search over `Projects/`, then confirm only if multiple plausible matches exist.
2. **Gather grounded context**
   - Read the project Markdown note fully.
   - Read linked meetings from its `## Meetings` section, prioritizing the newest 3-8.
   - Read recent daily notes that mention `[[Project]]`, the project name, or strong aliases.
   - Query `.cache/om/time-entries.db` when present for entered hours. Keep entered DB rows separate from recent daily-note time that may not be entered yet.
   - Read key local docs linked from the project note only when needed for current status, scope, pricing, technical notes, or takeaways.
3. **Improve the Markdown source first**
   Keep or add these sections when useful:
   - `## Current Status`
   - `## Next Focus`
   - `## Overview`
   - `## Recent Activity`
   - `## Meetings`
   - `## People`
   - project-specific focus areas
   - `## My Work`
   - `## Hours`
   - `## Open Questions`
   - `## Todos`
   - `## Key Documents` or `## Sources`

   Preserve existing todos and task metadata. Add new open todos only when they are directly supported by notes. Put `Last dashboard refresh: YYYY-MM-DD` in Current Status.
4. **Generate or update HTML**
   - Write `Projects/{Project}/{Project} Project Dashboard.html` unless an existing dashboard path is clearly established.
   - Render from the Markdown source, not from invented assumptions.
   - Include: where we are, best next focus, current todos, latest activity, recent meetings with `<details>` show-more, my work/hours, people, open questions, and source links.
   - Use CSS-only Light/Dark/System theme controls with hidden radio inputs before `.shell`. Do not use JS/localStorage.
5. **Verify**
   - Check local links resolve from the HTML file.
   - Search generated Markdown/HTML for defensive/meta copy: `No inferred`, `No invented`, `synthetic`, `grounded`, `based only`, `current vault notes`, `intentionally limited`, `Confirmed facts`.
   - Avoid em dashes in generated copy.
   - Render a Chromium screenshot to `.cache/dashboard-previews/{slug}-dashboard-updated.png` when Chromium is available.

## Grounding rules

- Do not invent status, staffing, deadlines, progress percentages, metrics, owners, or decisions.
- If uncertain, either omit the claim or phrase it as an open question backed by a note.
- Do not put defensive grounding disclaimers in the UI.
- Do not create separate interactive todo state. Todos remain in the project Markdown file.

## Output

Report changed files, verification performed, and preview screenshot paths.
