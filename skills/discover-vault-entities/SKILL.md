---
name: discover-vault-entities
type: capability
used_by:
  - refine-daily-note
  - intervals-time-entry
  - transcribe-meeting
  - topic-pulse
  - weekly-rollup
description: Use when a workflow needs the catalog of vault entities (projects, people, topics, coding notes, meetings, tags) for matching, linking, or context resolution.
---

# Discover Vault Entities

Build a catalog of known entities in the Obsidian vault so callers can match text against real notes, add wikilinks, or resolve context.

## Inputs

- **vault_root** (required): path to the Obsidian vault root
- **entity_types** (optional): which entity types to discover. Default: all.
  Allowed: `projects`, `people`, `topics`, `coding`, `meetings`, `tags`

## Process

Prefer Obsidian CLI discovery when available. Fall back to direct filesystem reads whenever the CLI is unavailable or unresponsive.

1. **Projects**: list files in `Projects/` and extract project names from filenames.
2. **People**: list files in `Persons/`. Read frontmatter `aliases:` from each person note to build a name-to-file lookup including short names and nicknames.
3. **Topics**: list files in `Topics/` and extract topic names from filenames.
4. **Coding sessions**: list files in `Coding/`.
5. **Meetings**: list files in `Meetings/`.
6. **Tags**: if the Obsidian CLI can return tag data (for example via `obsidian tags`), use it. Otherwise skip tag discovery quietly.

### Optional QMD integration

When QMD is available and a caller needs to verify whether a candidate name corresponds to an existing entity under a different spelling, use it as a supplement:

```bash
qmd query collection="obsidian" searches=[{type:"lex", query:"{name}"}] intent="find vault entity matching this name"
```

QMD is supplemental and optional. Filesystem/CLI discovery remains the primary source of truth.

## Output

Return a structured entity catalog:

- `projects`: list of `{ name, path }`
- `people`: list of `{ name, aliases[], path }`
- `topics`: list of `{ name, path }`
- `coding`: list of `{ name, path }` (if requested)
- `meetings`: list of `{ name, path }` (if requested)
- `tags`: list of tag strings (if available)
