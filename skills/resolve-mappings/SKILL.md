---
name: resolve-mappings
type: capability
used_by:
  - intervals-time-entry
  - freshbooks-time-entry
  - intervals-to-freshbooks
description: Use when a workflow needs to load, resolve, or learn mappings from the shared .cache/om/intervals-cache data.
---

# Resolve Mappings

Load mapping files from `.cache/om/intervals-cache/`, apply them to input data, and optionally learn new mappings. Supports multiple mapping types used across time-entry workflows, with an explicit operation mode so read-only and mutating behavior are clearly separated.

## Inputs

- **vault_root** (required): path to the Obsidian vault root (cache is at `{vault_root}/.cache/om/intervals-cache/`)
- **operation** (required): one of:
  - `load` — read mapping files and return structured mapping tables
  - `resolve` — read mapping files and apply them to `data_to_map`
  - `learn` — append confirmed new mappings to the selected cache file
- **mapping_types** (required): one or more of:
  - `project`
  - `github`
  - `outlook`
  - `slack`
  - `freshbooks`
  - `people`
- **data_to_map** (optional): list of items to resolve when `operation = resolve`
- **confirmed_mappings** (optional): confirmed new mappings to append when `operation = learn`

## Process

1. Load the requested mapping files from `{vault_root}/.cache/om/intervals-cache/`.
2. Parse their current format into structured data.
3. If `operation = load`, return the structured tables and stop.
4. If `operation = resolve`, apply the loaded mappings:
   - `project`: use CONTAINS matching because project names may include SOW suffixes
   - `github`: match `owner/repo`
   - `outlook`: match calendar subjects or recurring meeting patterns
   - `slack`: match channel names
   - `freshbooks`: match Intervals project names to FreshBooks destination
   - `people`: match person names against context data
5. If `operation = learn`, append only confirmed mappings. Do not infer and persist mappings without workflow-level confirmation.

## Output

Return:

- `mappings`: structured mapping tables
- `resolved`: resolved results for `data_to_map` when `operation = resolve`
- `unmapped`: items that did not match
- `missing_files`: mapping files that were absent
- `updated`: whether any mapping file was changed (only meaningful for `operation = learn`)
