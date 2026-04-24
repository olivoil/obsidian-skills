---
name: resolve-mappings
type: capability
description: Use when you need to resolve project/repo/calendar/channel/FreshBooks mappings from the shared cache — loads mapping files, applies CONTAINS-match logic, learns new mappings
---

# Resolve Mappings

Load mapping files from `.cache/om/intervals-cache/`, apply them to input data, and optionally learn new mappings. Supports multiple mapping types used across time-entry workflows.

## Inputs

- **vault_root** (required): path to the Obsidian vault root (cache is at `{vault_root}/.cache/om/intervals-cache/`)
- **mapping_types** (required): which mappings to load. One or more of:
  - `project` — project→workType mappings (`project-mappings.md`)
  - `github` — repo→project mappings (`github-mappings.md`)
  - `outlook` — calendar event→project mappings (`outlook-mappings.md`)
  - `slack` — channel→project mappings (`slack-mappings.md`)
  - `freshbooks` — Intervals project→FreshBooks project mappings (`freshbooks-mappings.md`)
  - `people` — person metadata (`people-context.md`)
  - `worktype` — activity language→work type fallback mappings (`worktype-mappings.md`)
- **data_to_map** (optional): list of items to resolve against the mappings. If provided, the capability applies the mappings and returns resolved results. If omitted, just returns the raw mapping tables.

## Process

1. **Load mapping files** from `{vault_root}/.cache/om/intervals-cache/`:
   - Read each requested mapping file
   - Parse the structured markdown into data — format varies by file:
     - `project-mappings.md`: heading+bullet format (`### Project Name` with `- Work Type` bullets)
     - `github-mappings.md`, `freshbooks-mappings.md`: markdown table format
     - `outlook-mappings.md`: mixed (tables for subject patterns and recurring meetings)
     - `slack-mappings.md`, `people-context.md`: structured markdown (varies)
   - If a file is missing, report it and continue with others

2. **Apply mappings** (if `data_to_map` is provided):
   - For `project` mappings: match input project names using **CONTAINS** logic (Intervals project names may have SOW numbers appended like `(20250040)`)
   - For `github` mappings: match `owner/repo` strings against the mapping table
   - For `outlook` mappings: match calendar subjects against subject patterns, and recurring meeting names
   - For `slack` mappings: match channel names against mapped channels
   - For `freshbooks` mappings: match Intervals project names (CONTAINS) to FreshBooks project + note
   - For `people` mappings: match person names against the context file
   - For `worktype` mappings: match activity descriptions from the time entry against known terms (e.g., "standup" → Meeting: Internal Stand Up - US, "PR reviews" → Architecture/Technical Design - US). Use as a **fallback** after project-specific mappings — if the project mapping already resolved a work type, skip; if the entry only has an activity description, use the worktype table to infer it. Context-based rules (e.g., "meeting with client stakeholders" → Client Meeting) apply when the notes term table has no exact match.

3. **Flag unmapped items**: if any input items don't match a mapping, flag them for the caller to handle (ask user, skip, etc.)

4. **Learn new mappings** (when the caller provides confirmed new associations):
   - Read the current mapping file
   - Append the new mapping row to the appropriate table
   - Write the updated file back
   - This is called by the workflow after user confirmation, not automatically

## Output

Return:
- `mappings`: the loaded mapping data, structured by type
- `resolved`: mapped results for `data_to_map` (if provided), with `{ input, mapped_to, confidence }` for each item
- `unmapped`: list of items that didn't match any mapping
- `missing_files`: list of mapping files that couldn't be found

## Mapping File Formats

### project-mappings.md
```markdown
### Project Name (SOW Number)
- Work Type 1
- Work Type 2
```

### github-mappings.md
```markdown
| Repo | Intervals Project |
|------|-------------------|
| owner/repo | Project Name |
```

### outlook-mappings.md
Subject patterns and recurring meeting→project tables.

### slack-mappings.md
Channel name→project mappings.

### freshbooks-mappings.md
```markdown
| Intervals Project (contains) | FB Project | FB Note | Has FB Project? |
```

### people-context.md
Person metadata with project associations.

### worktype-mappings.md
```markdown
| Notes Term | Intervals Work Type |
|------------|---------------------|
| standup, standup meeting, daily standup | Meeting: Internal Stand Up - US |
| PR review, code review | Architecture/Technical Design - US |
```
Plus a context-based selection table for ambiguous scenarios.
