---
name: discover-vault-entities
type: capability
description: Use when you need the full catalog of vault entities (projects, people, topics, tags, coding sessions, meetings) for matching, linking, or context building
---

# Discover Vault Entities

Build a catalog of all known entities in the Obsidian vault so callers can match text against real vault pages, add wikilinks, or build context.

## Inputs

- **vault_root** (required): path to the Obsidian vault root
- **entity_types** (optional): which types to discover. Default: all.
  Allowed: `projects`, `people`, `topics`, `coding`, `meetings`, `tags`

## Process

Prefer Obsidian CLI discovery when available. Fall back to direct filesystem reads whenever the CLI is unavailable or unresponsive.

1. **Projects**: list files in `Projects/` and extract project names from filenames.
   Supplement with `qmd query` (collection: obsidian, type: lex) for fuzzy matching when a caller passes candidate names to verify.
2. **People**: list files in `Persons/`. Read frontmatter `aliases:` from each person note to build a name→file lookup including short names and nicknames.
3. **Topics**: list files in `Topics/` and extract topic names from filenames.
   Supplement with `qmd query` for fuzzy matching when verifying candidate topic names.
4. **Coding sessions**: list files in `Coding/` for cross-reference awareness.
5. **Meetings**: list files in `Meetings/` for cross-reference awareness.
6. **Tags**: if the Obsidian CLI can return tag data (`obsidian tags`), use it. Otherwise skip tag discovery quietly.

### QMD integration

When a caller needs to verify whether a name corresponds to an existing entity (e.g., checking if "Jane Smith" already exists under a different spelling), use QMD:

```
qmd query collection="obsidian" searches=[{type:"lex", query:"{name}"}] intent="find vault entity matching this name"
```

This is especially useful for:
- Phase 4b of refine-daily-note (suggest new entities — check before creating)
- Fuzzy participant matching in transcribe-meeting
- Topic candidate validation in topic-pulse

QMD is supplemental. The filesystem listing is always the primary, authoritative source.

## Output

Return a structured entity catalog:
- `projects`: list of `{ name, path }`
- `people`: list of `{ name, aliases[], path }`
- `topics`: list of `{ name, path }`
- `coding`: list of `{ name, path }` (if requested)
- `meetings`: list of `{ name, path }` (if requested)
- `tags`: list of tag strings (if available)
