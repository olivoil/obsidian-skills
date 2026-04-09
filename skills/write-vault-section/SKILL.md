---
name: write-vault-section
type: capability
used_by:
  - session-rollup
  - intervals-time-entry
  - freshbooks-time-entry
  - intervals-to-freshbooks
description: Use when a workflow needs to create or update a named markdown section in a vault note with explicit replace/append semantics.
---

# Write Vault Section

Write to a named markdown section in an Obsidian vault note. Supports explicit modes for replacing a whole section, appending items inside an existing section, or ensuring a section exists. Handles idempotency, section positioning, missing notes, and Obsidian CLI with filesystem fallback.

## Inputs

- **note_path** (required): path to the note relative to vault root (for example `Daily Notes/2026-04-08.md`)
- **section_heading** (required): the heading to insert or replace (for example `### Intervals`, `### FreshBooks`, `### Coding Sessions`)
- **content** (required): the markdown content to place under the heading
- **vault_root** (required): path to the vault root
- **mode** (required): one of:
  - `replace_section` — replace the entire section body
  - `append_items` — ensure the section exists, then append items if not already present
  - `ensure_section` — create the section if missing, but do not replace existing content
- **position_hint** (optional): where to insert if the section does not exist:
  - `before:<heading>`
  - `after:<heading>`
  - `end` (default)
- **separator** (optional): text to prepend before the section heading when inserting. Default: `------`. Use empty string to skip.
- **create_if_missing** (optional): whether to create the note if it does not exist. Default: false.

## Process

1. Resolve the full note path as `{vault_root}/{note_path}`.
2. Read the note:
   - **Preferred**: use Obsidian CLI if available
   - **Fallback**: read from disk
   - If the note is missing and `create_if_missing` is true, create it with a minimal title derived from the filename.
3. Find the existing section by exact heading match.
   - If found and `mode = replace_section`: replace everything from the heading to the next heading of equal/higher level or end of file.
   - If found and `mode = append_items`: preserve existing body and append only items that are not already present as exact lines.
   - If found and `mode = ensure_section`: leave the existing section unchanged.
   - If not found: insert a new section at the requested position.
4. Write the updated note:
   - **Preferred**: Obsidian CLI
   - **Fallback**: write to disk

## Output

Report:

- whether the section was inserted, replaced, appended-to, or left unchanged
- the final note path
