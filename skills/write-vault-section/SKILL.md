---
name: write-vault-section
type: capability
description: Use when you need to append or replace a named section in an Obsidian note — handles idempotency, section positioning, Obsidian CLI with filesystem fallback
---

# Write Vault Section

Append or replace a named markdown section in an Obsidian vault note. Handles idempotency (replace if exists, append if not), section positioning, missing notes, and Obsidian CLI with filesystem fallback.

## Inputs

- **note_path** (required): path to the note relative to vault root (e.g., `Daily Notes/2026-04-07.md`)
- **section_heading** (required): the heading to insert or replace (e.g., `### Intervals`, `### FreshBooks`, `### Coding Sessions`)
- **content** (required): the full markdown content to place under the heading (including any tables, bullet lists, etc.)
- **vault_root** (required): path to the Obsidian vault root
- **position_hint** (optional): where to insert if the section doesn't exist yet. One of:
  - `before:<heading>` — insert before the named heading (e.g., `before:### Coding Sessions`)
  - `after:<heading>` — insert after the named heading and its content
  - `end` — append at end of note (default)
- **separator** (optional): text to prepend before the section heading. Default: `------` (horizontal rule). Set to empty string to skip.
- **create_if_missing** (optional): if the note doesn't exist, create it with a minimal `# {date}` header. Default: false.

## Process

1. **Resolve the full note path**: `{vault_root}/{note_path}`
2. **Read the note**:
   - **Preferred**: `obsidian read path="{note_path}"`
   - **Fallback**: read file directly from disk
   - If the note doesn't exist and `create_if_missing` is true, create it with a `# {title}` header derived from the filename. If false, report the missing note and stop.
3. **Find existing section**: search for a line matching `{section_heading}` exactly.
   - **If found**: replace everything from the heading to the next heading of equal or higher level (or `---` or end of file) with the new content.
   - **If not found**: insert at the position indicated by `position_hint`:
     - `before:<heading>`: find the target heading, insert before it
     - `after:<heading>`: find the target heading, skip past its content (until next heading of equal/higher level), insert after
     - `end`: append at end of file
   - Prepend the `separator` before the heading when inserting (not when replacing — the separator from the original is already there).
4. **Write the updated note**:
   - **Preferred**: `obsidian write path="{note_path}" content="{updated_content}"`
   - **Fallback**: write file directly to disk

## Output

Report:
- whether the section was inserted (new) or replaced (existing)
- the final note path
