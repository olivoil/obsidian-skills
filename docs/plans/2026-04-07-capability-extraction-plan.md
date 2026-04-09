# Capability Extraction Implementation Plan

> **For agentic workers:** Execute this plan task-by-task using the harness-appropriate planning/execution workflow. Validate capability invocation semantics before extracting shared behavior.

**Goal:** Prove the capability/workflow pattern, add discoverability metadata, extract 4 reusable Tier 1 capabilities from existing workflow skills, then update workflows to reference them.

**Architecture:** Two-layer skill architecture — capabilities (small, focused, independently invocable) composed by thinner workflow orchestrators via lazy-loaded `**USE CAPABILITY:**` markers. Capabilities have explicit Inputs/Process/Output sections. Workflows keep sequence logic and user interaction; capabilities handle the reusable "how."

**Tech Stack:** Markdown SKILL.md files, bash scripts, Obsidian CLI, QMD MCP search

**Design doc:** `docs/specs/2026-04-07-capability-extraction-design.md`

---

## Task 0: Validate capability invocation semantics

**Files:**
- Create: `skills/test-echo-capability/SKILL.md`
- Create: `skills/test-capability-workflow/SKILL.md`
- Delete after validation: `skills/test-echo-capability/SKILL.md`
- Delete after validation: `skills/test-capability-workflow/SKILL.md`

**Step 1: Create a tiny capability**

Create `skills/test-echo-capability/SKILL.md`:

```markdown
---
name: test-echo-capability
type: capability
used_by:
  - test-capability-workflow
description: Use when you need to confirm that a workflow can load and execute a capability skill by name
---

# Test Echo Capability

## Inputs

- `message` (optional): text to echo back. Default: `capability-loaded`

## Process

Return the message unchanged.

## Output

Return `capability-loaded` unless a different message was explicitly requested.
```

**Step 2: Create a tiny workflow**

Create `skills/test-capability-workflow/SKILL.md`:

```markdown
---
name: test-capability-workflow
type: workflow
uses:
  - test-echo-capability
description: Use when you need to verify nested capability invocation from inside a workflow
---

# Test Capability Workflow

## Phase 1: Invoke capability

**USE CAPABILITY: test-echo-capability**
Request the default output.

Expected result: `capability-loaded`
```

**Step 3: Validate in each target harness**

Invoke the workflow using each supported harness's normal skill invocation syntax.

Expected:
- the workflow loads
- the capability is resolved by name from inside the workflow
- the capability returns `capability-loaded`

**Step 4: Decide**

- If both harnesses support nested invocation reliably: continue with Task 1.
- If only one harness does: keep `USE CAPABILITY:` as a documentation convention for the other harness and avoid behavior-dependent extraction there.
- If neither does: stop and revise the architecture before proceeding.

**Step 5: Clean up and commit**

```bash
git add skills/test-echo-capability/SKILL.md skills/test-capability-workflow/SKILL.md
git commit -m "Add temporary capability invocation test skills"

# After validation is complete
git rm skills/test-echo-capability/SKILL.md skills/test-capability-workflow/SKILL.md
git commit -m "Remove temporary capability invocation test skills"
```

---

## Task 1: Add discoverability metadata and capability index

**Files:**
- Create: `docs/CAPABILITIES.md`
- Modify: `README.md`
- Modify: all 8 existing workflow `SKILL.md` files (frontmatter)

**Step 1: Add `type: workflow` and `uses:` to workflows**

For each workflow skill, add:
- `type: workflow`
- `uses: []` (start empty if the workflow has not yet been migrated)

Existing workflows:
- `skills/refine-daily-note/SKILL.md`
- `skills/intervals-time-entry/SKILL.md`
- `skills/transcribe-meeting/SKILL.md`
- `skills/freshbooks-time-entry/SKILL.md`
- `skills/intervals-to-freshbooks/SKILL.md`
- `skills/session-rollup/SKILL.md`
- `skills/topic-pulse/SKILL.md`
- `skills/weekly-rollup/SKILL.md`

**Step 2: Create `docs/CAPABILITIES.md`**

Create an index grouped by domain:
- Foundation
- Activity reading
- Note refinement
- Meeting/media
- Time/billing
- Rollups/research

For each capability include:
- name
- purpose
- side effects
- used by
- status (`planned`, `implemented`, `validated`)

**Step 3: Update README**

Add a short section explaining:
- what a capability skill is
- what a workflow skill is
- how workflows reference capabilities
- where to find the capability index

**Step 4: Commit**

```bash
git add docs/CAPABILITIES.md README.md skills/*/SKILL.md
git commit -m "Add capability/workflow metadata and capability index"
```

---

## Task 2: Create `discover-vault-entities` capability

**Files:**
- Create: `skills/discover-vault-entities/SKILL.md`

**Step 1: Create the skill directory**

```bash
mkdir -p skills/discover-vault-entities
```

**Step 2: Write the capability SKILL.md**

Create `skills/discover-vault-entities/SKILL.md` with this exact content:

```markdown
---
name: discover-vault-entities
type: capability
used_by:
  - refine-daily-note
  - intervals-time-entry
  - transcribe-meeting
  - topic-pulse
  - weekly-rollup
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

When QMD is available and a caller needs to verify whether a name corresponds to an existing entity (e.g., checking if "Jane Smith" already exists under a different spelling), use QMD:

```
qmd query collection="obsidian" searches=[{type:"lex", query:"{name}"}] intent="find vault entity matching this name"
```

This is especially useful for:
- Phase 4b of refine-daily-note (suggest new entities — check before creating)
- Fuzzy participant matching in transcribe-meeting
- Topic candidate validation in topic-pulse

QMD is supplemental and optional. The filesystem listing is always the primary, authoritative source.

## Output

Return a structured entity catalog:
- `projects`: list of `{ name, path }`
- `people`: list of `{ name, aliases[], path }`
- `topics`: list of `{ name, path }`
- `coding`: list of `{ name, path }` (if requested)
- `meetings`: list of `{ name, path }` (if requested)
- `tags`: list of tag strings (if available)
```

**Step 3: Verify standalone invocation**

Invoke the capability directly using your harness's normal skill invocation syntax.
Expected: it resolves the vault root, lists entities from each directory, returns the catalog. Verify at least projects and people are populated.

**Step 4: Commit**

```bash
git add skills/discover-vault-entities/SKILL.md
git commit -m "Add discover-vault-entities capability

Extracts vault entity discovery (projects, people, topics, tags,
coding sessions, meetings) into a reusable capability with QMD
integration for fuzzy matching."
```

---

## Task 3: Update `refine-daily-note` to use `discover-vault-entities`

**Files:**
- Modify: `skills/refine-daily-note/SKILL.md` (Phase 1, lines ~38-49)

**Step 1: Replace Phase 1 inline content with capability reference**

In `skills/refine-daily-note/SKILL.md`, replace the current Phase 1:

```markdown
### Phase 1: Discover Vault Entities

Build a catalog of all known entities so you can match them against the daily note text. Prefer Obsidian CLI discovery when available, but fall back to direct filesystem reads whenever needed.

1. **Projects**: list files in `Projects/` and extract project names from filenames
2. **People**: list files in `Persons/`. If frontmatter aliases are available, read them from each person note
3. **Topics**: list files in `Topics/` and extract topic names from filenames
4. **Coding sessions**: list files in `Coding/` for cross-reference awareness
5. **Meetings**: list files in `Meetings/` for cross-reference awareness
6. **Tags**: if the Obsidian CLI can return tag data, use it; otherwise skip tag discovery quietly

This gives you the full entity catalog to match against the daily note.
```

With:

```markdown
### Phase 1: Discover Vault Entities

**USE CAPABILITY: discover-vault-entities**
Pass the resolved vault root from Phase 0. Request all entity types.

This gives you the full entity catalog to match against the daily note text in later phases (wikilinks, entity suggestions, Slack/GitHub summaries).
```

**Step 2: Verify the workflow still works**

Run `refine-daily-note` interactively on a recent daily note. Verify:
- Entity discovery produces the same catalog as before
- Phase 3 (wikilinks) still finds the same entities to link
- Phase 4b (suggest new entities) still uses QMD for deduplication

**Step 3: Commit**

```bash
git add skills/refine-daily-note/SKILL.md
git commit -m "refine-daily-note: use discover-vault-entities capability

Replace inline entity discovery (Phase 1) with USE CAPABILITY
reference. Entity catalog behavior is unchanged."
```

---

## Task 4: Update remaining consumers to use `discover-vault-entities`

**Files:**
- Modify: `skills/intervals-time-entry/SKILL.md` (Phase 2, mapping context)
- Modify: `skills/transcribe-meeting/SKILL.md` (Phase 1.5, participant matching context)
- Modify: `skills/topic-pulse/SKILL.md` (Phase 1, topic candidate selection)
- Modify: `skills/weekly-rollup/SKILL.md` (Phase 2, data collection context)

**Step 1: Update `intervals-time-entry`**

The entity discovery in intervals-time-entry is implicit — Phase 2 reads project mappings from cache files. The entity catalog helps correlate calendar subjects and GitHub repos to projects. Add a capability reference before Phase 2:

In `skills/intervals-time-entry/SKILL.md`, insert before `### Phase 2: Load Mappings`:

```markdown
### Phase 1.8: Discover Vault Entities

**USE CAPABILITY: discover-vault-entities**
Pass the vault root. Request `projects` and `people` types.

Use the entity catalog to:
- Correlate GitHub repos to project names in Phase 1.5
- Match calendar attendees to person notes in Phase 1.7
- Validate project names before mapping resolution in Phase 2
```

**Step 2: Update `transcribe-meeting`**

In `skills/transcribe-meeting/SKILL.md`, in Phase 1.5 (Gather Context), add a capability reference at the start of Track 2 (Vault context). Find the section that reads daily notes and project terminology, and prepend:

```markdown
**USE CAPABILITY: discover-vault-entities**
Pass the vault root. Request `projects`, `people`, and `meetings` types.

Use the people catalog to match participant names from screenshots (Track 1) to existing vault person notes. Use the project catalog to build the whisper prompt vocabulary.
```

**Step 3: Update `topic-pulse`**

In `skills/topic-pulse/SKILL.md`, replace Phase 1's inline candidate building with:

```markdown
### Phase 1: Select candidate topics

**USE CAPABILITY: discover-vault-entities**
Pass the vault root. Request `topics` and `projects` types.

Build a candidate list from:
- explicit topic names named by the user
- existing wikilinks to `Topics/` notes in recent notes (cross-reference against the entity catalog)
- repeated unlinked topic phrases that appear important in recent work — verify against the entity catalog using QMD before treating as new

Then rank candidates by relevance. Prefer topics that are:
- repeated across multiple notes
- clearly tied to current work
- likely to benefit from fresh outside context

By default, work on **no more than 3 topics** in one run unless the user asks for more.
```

**Step 4: Update `weekly-rollup`**

In `skills/weekly-rollup/SKILL.md`, add at the start of Phase 2:

```markdown
### Phase 2: Collect Data

**USE CAPABILITY: discover-vault-entities**
Pass the vault root. Request `projects`, `meetings`, and `coding` types.

Use the entity catalog to resolve wikilinks in daily notes to their correct paths when reading linked meeting and coding notes.

Read all daily notes for the target week. Prefer Obsidian CLI reads when available, but fall back to direct filesystem reads whenever needed.
```

(Remove the existing first line "Read all daily notes for the target week..." since it's now included after the capability reference.)

**Step 5: Commit**

```bash
git add skills/intervals-time-entry/SKILL.md skills/transcribe-meeting/SKILL.md skills/topic-pulse/SKILL.md skills/weekly-rollup/SKILL.md
git commit -m "Update 4 workflows to use discover-vault-entities capability

intervals-time-entry, transcribe-meeting, topic-pulse, and
weekly-rollup now reference the shared capability instead of
inline entity discovery."
```

---

## Task 5: Create `write-vault-section` capability

**Files:**
- Create: `skills/write-vault-section/SKILL.md`

**Step 1: Create the skill directory**

```bash
mkdir -p skills/write-vault-section
```

**Step 2: Write the capability SKILL.md**

Create `skills/write-vault-section/SKILL.md` with this exact content:

```markdown
---
name: write-vault-section
type: capability
used_by:
  - session-rollup
  - intervals-time-entry
  - freshbooks-time-entry
  - intervals-to-freshbooks
description: Use when you need to append or replace a named section in an Obsidian note — handles idempotency, section positioning, Obsidian CLI with filesystem fallback
---

# Write Vault Section

Write to a named markdown section in an Obsidian vault note. Supports explicit modes for replacing a whole section, appending items inside an existing section, or ensuring a section exists. Handles idempotency, section positioning, missing notes, and Obsidian CLI with filesystem fallback.

## Inputs

- **note_path** (required): path to the note relative to vault root (e.g., `Daily Notes/2026-04-07.md`)
- **section_heading** (required): the heading to insert or replace (e.g., `### Intervals`, `### FreshBooks`, `### Coding Sessions`)
- **content** (required): the full markdown content to place under the heading (including any tables, bullet lists, etc.)
- **vault_root** (required): path to the Obsidian vault root
- **mode** (required): one of:
  - `replace_section` — replace the entire section body
  - `append_items` — ensure the section exists, then append items within it if not already present
  - `ensure_section` — create the section if missing, but do not replace existing content
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
   - **If found and `mode = replace_section`**: replace everything from the heading to the next heading of equal or higher level (or `---` or end of file) with the new content.
   - **If found and `mode = append_items`**: keep the existing section body and append only items that are not already present as exact lines.
   - **If found and `mode = ensure_section`**: leave the existing section unchanged.
   - **If not found**: insert at the position indicated by `position_hint`:
     - `before:<heading>`: find the target heading, insert before it
     - `after:<heading>`: find the target heading, skip past its content (until next heading of equal/higher level), insert after
     - `end`: append at end of file
   - Prepend the `separator` before the heading when inserting.
4. **Write the updated note**:
   - **Preferred**: `obsidian write path="{note_path}" content="{updated_content}"`
   - **Fallback**: write file directly to disk

## Output

Report:
- whether the section was inserted, replaced, appended-to, or left unchanged
- the final note path
```

**Step 3: Verify standalone invocation**

Test by invoking the capability directly using your harness's normal skill invocation syntax with:
```
note_path="Daily Notes/2026-04-07.md", section_heading="### Test Section", content="- test bullet", mode="append_items"
```
Expected: the section appears in the note. Running again is a no-op because the exact bullet already exists.

**Step 4: Commit**

```bash
git add skills/write-vault-section/SKILL.md
git commit -m "Add write-vault-section capability

Extracts the repeated pattern of appending/replacing named sections
in vault notes with idempotency, positioning, and Obsidian CLI
fallback into a reusable capability."
```

---

## Task 6: Update workflows to use `write-vault-section`

**Files:**
- Modify: `skills/session-rollup/SKILL.md` (Phase 4)
- Modify: `skills/intervals-time-entry/SKILL.md` (Phase 7)
- Modify: `skills/freshbooks-time-entry/SKILL.md` (Phase 6)
- Modify: `skills/intervals-to-freshbooks/SKILL.md` (Phase 5, Step 3)

**Step 1: Update `session-rollup` (simplest consumer)**

In `skills/session-rollup/SKILL.md`, replace Phase 4:

```markdown
### 4. Link from the daily note

1. Read the relevant daily note.
2. Create it if missing.
3. Insert or update a `### Coding Sessions` section.
4. Add a bullet linking to the new coding note with the one-line summary.

Preferred bullet format:

\`\`\`markdown
- [[{date}--{repo-name}--{branch}]] - {one-line summary}
\`\`\`
```

With:

```markdown
### 4. Link from the daily note

**USE CAPABILITY: write-vault-section**
- **vault_root**: resolved vault root from Phase 0
- **note_path**: `Daily Notes/{date}.md`
- **section_heading**: `### Coding Sessions`
- **content**: `- [[{date}--{repo-name}--{branch}]] - {one-line summary}`
- **mode**: `append_items`
- **position_hint**: `end`
- **create_if_missing**: true

Append the new bullet only if it is not already present as an exact line.
```

**Step 2: Update `intervals-time-entry`**

In `skills/intervals-time-entry/SKILL.md`, replace Phase 7 (the entire "Write Time Entry Table to Daily Note" section including Steps 1-4) with:

```markdown
### Phase 7: Write Time Entry Table to Daily Note

**USE CAPABILITY: write-vault-section**
- **vault_root**: resolved vault root
- **note_path**: `Daily Notes/{date}.md`
- **section_heading**: `### Intervals`
- **content**: the markdown table built from ENTRIES data:
  ```markdown
  | Project | Hours | Description |
  |---------|------:|-------------|
  | {project} | {hours} | {description} |
  | **Total** | **{sum}** | |
  ```
- **mode**: `replace_section`
- **position_hint**: `before:### Coding Sessions` (fall back to `after:### Done today`, then `end`)
- **separator**: `------`

Use the same ENTRIES data that was sent to `fill-entries.js`. Right-align Hours column. Add bold Total row.
```

**Step 3: Update `freshbooks-time-entry`**

In `skills/freshbooks-time-entry/SKILL.md`, replace Phase 6 with:

```markdown
### Phase 6: Update Daily Notes

For each date with new entries:

**USE CAPABILITY: write-vault-section**
- **vault_root**: `$VAULT`
- **note_path**: `Daily Notes/{date}.md`
- **section_heading**: `### FreshBooks`
- **content**: the markdown table:
  ```markdown
  | Project | Hours | Description |
  |---------|------:|-------------|
  | {fb_project} | {hours} | {note} |
  | **Total** | **{sum}** | |
  ```
- **mode**: `replace_section`
- **separator**: `------`
- **create_if_missing**: true

Right-align Hours column. Add bold Total row.
```

**Step 4: Update `intervals-to-freshbooks`**

In `skills/intervals-to-freshbooks/SKILL.md`, replace the "Step 3: Append FreshBooks Section to Daily Notes" portion of Phase 5 with:

```markdown
#### Step 3: Append FreshBooks Section to Daily Notes

For each date with entries:

**USE CAPABILITY: write-vault-section**
- **vault_root**: resolved Obsidian vault root
- **note_path**: `Daily Notes/{date}.md`
- **section_heading**: `### FreshBooks`
- **content**: the markdown table (same format as freshbooks-time-entry)
- **mode**: `replace_section`
- **separator**: `------`
- **create_if_missing**: true
```

**Step 5: Commit**

```bash
git add skills/session-rollup/SKILL.md skills/intervals-time-entry/SKILL.md skills/freshbooks-time-entry/SKILL.md skills/intervals-to-freshbooks/SKILL.md
git commit -m "Update 4 workflows to use write-vault-section capability

session-rollup, intervals-time-entry, freshbooks-time-entry, and
intervals-to-freshbooks now reference the shared capability for
writing named sections to vault notes."
```

---

## Task 7: Create `read-github-activity` capability

**Files:**
- Create: `skills/read-github-activity/SKILL.md`
- Move: `skills/intervals-time-entry/scripts/fetch-github-activity.sh` → `skills/read-github-activity/scripts/fetch-github-activity.sh`
- Delete: `skills/refine-daily-note/scripts/fetch-github-activity.sh` (duplicate)

**Step 1: Create the skill directory and move the script**

```bash
mkdir -p skills/read-github-activity/scripts
cp skills/intervals-time-entry/scripts/fetch-github-activity.sh skills/read-github-activity/scripts/fetch-github-activity.sh
```

**Step 2: Write the capability SKILL.md**

Create `skills/read-github-activity/SKILL.md` with this exact content:

```markdown
---
name: read-github-activity
type: capability
used_by:
  - refine-daily-note
  - intervals-time-entry
description: Use when you need GitHub PR, commit, and review activity for a specific date — fetches via gh CLI and returns structured data
---

# Read GitHub Activity

Fetch GitHub activity (PRs authored, PRs reviewed, commits, comments) for a specific date using the `gh` CLI. Returns structured JSON data for callers to correlate, summarize, or display.

## Inputs

- **date** (required): target date in `YYYY-MM-DD` format
- **repos** (optional): limit to specific repos (list of `owner/repo`). Default: all repos with activity.

## Process

1. **Check prerequisites**: verify `gh` CLI is available and authenticated. If not, skip quietly and return empty output.

2. **Fetch activity**:
   ```bash
   bash $SKILL/scripts/fetch-github-activity.sh {date}
   ```
   Where `$SKILL` is this capability's base directory.

3. **Parse the JSON output**. The script returns:
   - `prs_authored`: PRs created or updated on the date (includes title, body snippet, repo, number, state)
   - `prs_active`: PRs with push/comment activity on the date
   - `prs_reviewed`: PRs the user reviewed on the date (includes title, body snippet)
   - `events`: timestamped activity (pushes, reviews, comments, issue actions)

4. **IMPORTANT**: The script output already includes PR titles and body snippets. Do NOT make separate `gh pr view` calls — use the data already returned.

## Output

Return the structured JSON data with:
- `prs_authored`: list of `{ repo, number, title, body_snippet, state, created_at, updated_at }`
- `prs_reviewed`: list of `{ repo, number, title, body_snippet }`
- `events`: list of `{ type, repo, timestamp, details }`
- `date`: the queried date
- `available`: boolean (false if gh CLI was unavailable)

If `gh` is not available or not authenticated, return `{ available: false }` with no error.
```

**Step 3: Verify standalone invocation**

Invoke the capability directly using your harness's normal skill invocation syntax.

Expected:
- when `gh` is available, structured PR/review/event data is returned
- when `gh` is unavailable, the capability returns `{ available: false }` with no error

**Step 4: Remove duplicate scripts from old locations**

After verifying the capability works:

```bash
rm skills/intervals-time-entry/scripts/fetch-github-activity.sh
rm skills/refine-daily-note/scripts/fetch-github-activity.sh
```

Check if the `scripts/` directories are now empty and can be removed (only if no other scripts remain):

```bash
ls skills/refine-daily-note/scripts/
```

If empty, remove the directory. If other scripts remain, leave it.

**Step 5: Update script path references in workflows**

In `skills/intervals-time-entry/SKILL.md`, the Phase 1.5 step that runs `bash scripts/fetch-github-activity.sh YYYY-MM-DD` will be replaced by the capability reference (Task 7). No path update needed here — the capability handles the script path internally.

In `skills/refine-daily-note/SKILL.md`, Phase 1d runs `bash scripts/fetch-github-activity.sh {date}`. This will also be replaced by the capability reference (Task 7).

**Step 6: Commit**

```bash
git add skills/read-github-activity/
git rm skills/intervals-time-entry/scripts/fetch-github-activity.sh
git rm skills/refine-daily-note/scripts/fetch-github-activity.sh
git commit -m "Add read-github-activity capability, consolidate script

Move fetch-github-activity.sh (identical in both skills) into the
new capability. Remove duplicates from intervals-time-entry and
refine-daily-note."
```

---

## Task 8: Update workflows to use `read-github-activity`

**Files:**
- Modify: `skills/refine-daily-note/SKILL.md` (Phase 1d)
- Modify: `skills/intervals-time-entry/SKILL.md` (Phase 1.5 Step 1)

**Step 1: Update `refine-daily-note`**

In `skills/refine-daily-note/SKILL.md`, replace Phase 1d:

```markdown
### Phase 1d: GitHub Activity Scan

**Always attempt this phase.** If `gh` is unavailable, not authenticated, or returns no useful data, skip gracefully with no error.

1. Run:
   \`\`\`bash
   bash scripts/fetch-github-activity.sh {date}
   \`\`\`
   This returns JSON for:
   - PRs authored on the date
   - PRs active/updated on the date
   - PRs reviewed on the date
   - event-level activity (pushes, comments, reviews, issue/PR actions)
2. Build a repo→project correlation map using:
   ...
```

With:

```markdown
### Phase 1d: GitHub Activity Scan

**USE CAPABILITY (optional): read-github-activity**
Fetch activity for the target date. If the capability returns `available: false`, skip this phase and Phase 1e silently.

Using the returned activity data:

1. Build a repo→project correlation map using:
   - `.cache/om/intervals-cache/github-mappings.md`
   - project names already present in the day's time entries
   - explicit repo links already mentioned in the daily note
2. Identify the day's meaningful GitHub work:
   - authored PRs
   - reviewed PRs
   - notable pushes or comment/review bursts
   - repos with concentrated activity even if the daily note only mentions them vaguely
3. Improve weak note context when GitHub data clarifies it. Examples:
   - `worked on OIDC stuff` → mention the PR title or repo involved
   - `reviewed PRs` → list the most important PRs/repositories reviewed
   - `pipeline work` → mention the repo and PR title when available
4. Infer or extend repo→project mappings when the association is clear, then append new mappings to `.cache/om/intervals-cache/github-mappings.md`.
5. Do **not** rewrite time-entry lines automatically. Use GitHub activity to enrich the prose sections of the daily note, not to mutate the structured time-entry block.
```

**Step 2: Update `intervals-time-entry`**

In `skills/intervals-time-entry/SKILL.md`, replace Phase 1.5 Step 1 (Fetch Activity):

```markdown
#### Step 1: Fetch Activity

**Run this command** (replace YYYY-MM-DD with the target date):
\`\`\`bash
bash scripts/fetch-github-activity.sh YYYY-MM-DD
\`\`\`

This returns JSON with:
- PRs authored (created or updated)
- PRs reviewed
- Events with timestamps (commits, reviews, comments)

**IMPORTANT**: The script output already includes PR titles and body snippets in `prs_authored`, `prs_active`, and `prs_reviewed`. Do NOT make separate `gh pr view` calls — use the data already returned by the script.
```

With:

```markdown
#### Step 1: Fetch Activity

**USE CAPABILITY: read-github-activity**
Fetch activity for the target date.

The capability returns structured JSON with PRs authored, PRs reviewed, and timestamped events. PR titles and body snippets are already included — do NOT make separate `gh pr view` calls.
```

**Step 3: Commit**

```bash
git add skills/refine-daily-note/SKILL.md skills/intervals-time-entry/SKILL.md
git commit -m "Update refine-daily-note and intervals-time-entry to use read-github-activity

Both workflows now reference the shared capability instead of
calling fetch-github-activity.sh directly."
```

---

## Task 9: Create `resolve-mappings` capability

**Files:**
- Create: `skills/resolve-mappings/SKILL.md`

**Step 1: Create the skill directory**

```bash
mkdir -p skills/resolve-mappings
```

**Step 2: Write the capability SKILL.md**

Create `skills/resolve-mappings/SKILL.md` with this exact content:

```markdown
---
name: resolve-mappings
type: capability
used_by:
  - intervals-time-entry
  - freshbooks-time-entry
  - intervals-to-freshbooks
description: Use when you need to load, resolve, or learn project/repo/calendar/channel/FreshBooks mappings from the shared cache
---

# Resolve Mappings

Load mapping files from `.cache/om/intervals-cache/`, apply them to input data, and optionally learn new mappings. Supports multiple mapping types used across time-entry workflows, with an explicit operation mode so read-only and mutating behavior are clearly separated.

## Inputs

- **vault_root** (required): path to the Obsidian vault root (cache is at `{vault_root}/.cache/om/intervals-cache/`)
- **operation** (required): one of:
  - `load` — read mapping files and return structured mapping tables
  - `resolve` — read mapping files and apply them to `data_to_map`
  - `learn` — append confirmed new mappings to the selected cache file
- **mapping_types** (required): which mappings to load. One or more of:
  - `project` — project→workType mappings (`project-mappings.md`)
  - `github` — repo→project mappings (`github-mappings.md`)
  - `outlook` — calendar event→project mappings (`outlook-mappings.md`)
  - `slack` — channel→project mappings (`slack-mappings.md`)
  - `freshbooks` — Intervals project→FreshBooks project mappings (`freshbooks-mappings.md`)
  - `people` — person metadata (`people-context.md`)
- **data_to_map** (optional): list of items to resolve against the mappings. If provided, the capability applies the mappings and returns resolved results. If omitted, just returns the raw mapping tables.

## Process

1. **Load mapping files** from `{vault_root}/.cache/om/intervals-cache/`:
   - Read each requested mapping file
   - Parse the markdown tables into structured data
   - If a file is missing, report it and continue with others

2. **If `operation = load`**:
   - Return the structured mapping tables and stop.

3. **If `operation = resolve`**:
   - For `project` mappings: match input project names using **CONTAINS** logic (Intervals project names may have SOW numbers appended like `(20250040)`)
   - For `github` mappings: match `owner/repo` strings against the mapping table
   - For `outlook` mappings: match calendar subjects against subject patterns, and recurring meeting names
   - For `slack` mappings: match channel names against mapped channels
   - For `freshbooks` mappings: match Intervals project names (CONTAINS) to FreshBooks project + note
   - For `people` mappings: match person names against the context file

4. **Flag unmapped items**: if any input items don't match a mapping, flag them for the caller to handle (ask user, skip, etc.)

5. **If `operation = learn`**:
   - Require confirmed new associations from the caller
   - Read the current mapping file
   - Append the new mapping row to the appropriate table
   - Write the updated file back
   - Do not infer or auto-write mappings without workflow confirmation

## Output

Return:
- `mappings`: the loaded mapping data, structured by type
- `resolved`: mapped results for `data_to_map` (when `operation = resolve`), with `{ input, mapped_to, confidence }` for each item
- `unmapped`: list of items that didn't match any mapping
- `missing_files`: list of mapping files that couldn't be found
- `updated`: boolean indicating whether a mapping file was modified (only for `operation = learn`)

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
```

**Step 3: Verify standalone invocation**

Test the capability directly using your harness's normal skill invocation syntax with `mapping_types=["project", "freshbooks"]` and `operation="load"`.
Expected: loads and displays the mapping tables from cache.

**Step 4: Commit**

```bash
git add skills/resolve-mappings/SKILL.md
git commit -m "Add resolve-mappings capability

Extracts the shared pattern of loading and applying project/repo/
calendar/channel/FreshBooks mappings from the cache into a reusable
capability with CONTAINS-match logic and mapping learning."
```

---

## Task 10: Update workflows to use `resolve-mappings`

**Files:**
- Modify: `skills/intervals-time-entry/SKILL.md` (Phases 2-3, 5.5, 5.6)
- Modify: `skills/freshbooks-time-entry/SKILL.md` (Phase 1)
- Modify: `skills/intervals-to-freshbooks/SKILL.md` (Phase 3)

**Step 1: Update `intervals-time-entry`**

In `skills/intervals-time-entry/SKILL.md`, replace Phase 2 (Load Mappings):

```markdown
### Phase 2: Load Mappings

**USE CAPABILITY: resolve-mappings**
- **vault_root**: resolved vault root
Operation: `load`
Load mapping types: `project`, `github`, `outlook`, `people`.

Use the loaded mappings to:
- Resolve project→workType for each time entry (Phase 3)
- Correlate GitHub repos to projects (from Phase 1.5 data)
- Match Outlook calendar events to projects (from Phase 1.7 data)
- Look up attendee→project associations from people context

If shared cache files are missing, bootstrap them with this repo's install script before running the workflow.
```

Replace Phase 3 (Validate Against Cache):

```markdown
### Phase 3: Validate Against Cache

Using the mappings from Phase 2, check each time entry's project has cached work types:
- If all projects have cached work types → skip browser inspection
- If any project is NOT cached → inspect browser to discover its work types
```

Update Phases 5.5 and 5.6 to reference the capability's learning feature:

```markdown
### Phase 5.5: Update GitHub Mappings Cache

When you discover a new repo→project association:

**USE CAPABILITY: resolve-mappings**
- **vault_root**: resolved vault root
Operation: `learn`
Learn new mapping: type `github`, add the `owner/repo → Intervals Project` row.

### Phase 5.6: Update Outlook Mappings Cache

When you discover a new calendar event→project association:

**USE CAPABILITY: resolve-mappings**
- **vault_root**: resolved vault root
Operation: `learn`
Learn new mapping: type `outlook`, add the subject pattern or recurring meeting mapping.
```

**Step 2: Update `freshbooks-time-entry`**

In `skills/freshbooks-time-entry/SKILL.md`, replace Phase 1 (Read Project Mappings):

```markdown
### Phase 1: Load FreshBooks Mapping Table

**USE CAPABILITY: resolve-mappings**
- **vault_root**: `$VAULT`
Operation: `load`
Load mapping type: `freshbooks`.
Load the FreshBooks mapping table first so it is ready when Intervals project names are available in Phase 2.

**Client-only entries** (no FB project — Meetings, Biz Dev, Training, Recruiting) use `--client EXSquared` without `--project`. In SQLite they are stored with project = "EXSquared".
```

(Keep the existing mapping examples table from the current Phase 1 as documentation below the capability reference — it's workflow-specific reference data.)

Then, in Phase 2 where `query-intervals.sh` has already produced Intervals rows, update the mapping step to say:

```markdown
3. Using the loaded FreshBooks mapping table, map each Intervals row's project name to FB project + note. Match using CONTAINS because Intervals project names may have SOW numbers appended.
```

**Step 3: Update `intervals-to-freshbooks`**

In `skills/intervals-to-freshbooks/SKILL.md`, replace Phase 3 (Map Entries):

```markdown
### Phase 3: Map Entries

**USE CAPABILITY: resolve-mappings**
- **vault_root**: resolved Obsidian vault root
Operation: `resolve`
Load mapping type: `freshbooks`. Pass the Intervals entries from Phase 2 as `data_to_map`.

For each Intervals entry, the capability resolves the FreshBooks destination:
- **Client** is always required for invoicing (defaults to "EXSquared")
- **Project** is optional — use when work is for a specific project
- For unmapped entries, ask user for the FreshBooks mapping and learn it via the capability using:
  - `operation = learn`
  - `mapping_types = [freshbooks]`
```

**Step 4: Commit**

```bash
git add skills/intervals-time-entry/SKILL.md skills/freshbooks-time-entry/SKILL.md skills/intervals-to-freshbooks/SKILL.md
git commit -m "Update 3 workflows to use resolve-mappings capability

intervals-time-entry, freshbooks-time-entry, and
intervals-to-freshbooks now reference the shared capability
for loading and applying cache mappings."
```

---

## Task 11: Sync `uses`, `used_by`, and capability index metadata

**Files:**
- Modify: all 8 workflow `SKILL.md` files (frontmatter)
- Modify: all 4 capability `SKILL.md` files (frontmatter)
- Modify: `docs/CAPABILITIES.md`

**Step 1: Update workflow `uses:` lists**

For each workflow, replace any temporary empty `uses: []` with the actual capability list introduced by this plan:
- `skills/refine-daily-note/SKILL.md`
- `skills/intervals-time-entry/SKILL.md`
- `skills/transcribe-meeting/SKILL.md`
- `skills/freshbooks-time-entry/SKILL.md`
- `skills/intervals-to-freshbooks/SKILL.md`
- `skills/session-rollup/SKILL.md`
- `skills/topic-pulse/SKILL.md`
- `skills/weekly-rollup/SKILL.md`

Example for `refine-daily-note` after this plan:
```yaml
---
name: refine-daily-note
type: workflow
uses:
  - discover-vault-entities
  - read-github-activity
description: Improve Obsidian daily notes — ...
---
```

**Step 2: Update capability `used_by:` lists**

For each implemented capability, list its current consumers:
- `skills/discover-vault-entities/SKILL.md`
- `skills/write-vault-section/SKILL.md`
- `skills/read-github-activity/SKILL.md`
- `skills/resolve-mappings/SKILL.md`

Example:
```yaml
---
name: write-vault-section
type: capability
used_by:
  - session-rollup
  - intervals-time-entry
  - freshbooks-time-entry
  - intervals-to-freshbooks
description: ...
---
```

**Step 3: Update `docs/CAPABILITIES.md`**

Mark the four implemented capabilities as `validated` and fill in their actual consumers.

**Step 4: Commit**

```bash
git add skills/*/SKILL.md docs/CAPABILITIES.md
git commit -m "Sync workflow uses, capability used_by, and capability index

Keep skill metadata and capability index aligned with the first
wave of extracted capabilities."
```

---

## Task 12: Final validation pass

**Step 1: Verify skill listing**

List all skills and verify the type distribution:
```bash
grep -r "^type:" skills/*/SKILL.md
```

Expected: 4 capabilities, 8 workflows.

Also verify metadata coverage:
```bash
grep -r "^uses:" skills/*/SKILL.md
grep -r "^used_by:" skills/*/SKILL.md
test -f docs/CAPABILITIES.md
```

**Step 2: Spot-check lazy loading**

Run `refine-daily-note --auto` on a recent daily note. Verify:
- `discover-vault-entities` loads during Phase 1
- `read-github-activity` loads during Phase 1d (or skips if gh unavailable)
- `write-vault-section` is not loaded (refine-daily-note writes differently — via Phase 5 apply)
- Skipped phases don't trigger capability loads

**Step 3: Spot-check standalone invocation**

Run each capability directly using your harness's normal skill invocation syntax:
- `discover-vault-entities` — returns entity catalog
- `write-vault-section` with a test section — writes and is idempotent for the selected mode
- `read-github-activity` — returns PR data or `available: false`
- `resolve-mappings` with `operation="load"` and `mapping_types=["project"]` — returns mapping table

**Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "Fix any issues found during validation"
```

---

## Future Work (Tier 2 — not part of this plan)

After Tier 1 is stable and validated:

- **`read-slack-activity`**: Extract from `refine-daily-note` Phases 1b-1d. ~90-110 lines.
- **`read-outlook-calendar`**: Extract from `intervals-time-entry` Phase 1.7. ~70-90 lines.

These are single-consumer extractions with strong standalone value but lower urgency.
