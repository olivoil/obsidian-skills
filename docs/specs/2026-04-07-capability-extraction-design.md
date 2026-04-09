# Capability Extraction Design

Extract reusable capabilities from workflow skills to enable composition, reduce duplication, and support partial invocation.

## Problem

The current skill set is mostly made of large workflow-style skills (roughly 93-529 lines). Shared sub-tasks — vault entity discovery, GitHub activity reading, mapping resolution, vault section writing — are duplicated across workflows with subtle drift. New skills must rewrite these patterns from scratch instead of composing from a library.

**Priorities** (user-ranked):
1. Composability — build new skills faster by reusing existing sub-capabilities
2. DRY / Partial invocation — single source of truth for shared tasks; invoke sub-tasks standalone
3. Context budget — smaller files, lazy loading

## Architecture: Capabilities + Workflows

Two layers, both living in `skills/`:

- **Capabilities** — small (50-150 lines), focused, independently invocable. Clear inputs and outputs. No broad orchestration. Side effects, if any, are explicit.
- **Workflows** — orchestrators that define sequence and decision logic, delegating the *how* to capabilities via lazy-loaded references.

### File structure

Flat. Capabilities and workflows sit side-by-side in `skills/`, distinguished by naming convention and a `type:` frontmatter field. No subdirectories.

```
skills/
  # Capabilities (verb-noun, describes the action)
  discover-vault-entities/
  read-github-activity/
  read-slack-activity/
  read-outlook-calendar/
  resolve-mappings/
  write-vault-section/

  # Workflows (existing names, describes the outcome)
  refine-daily-note/
  intervals-time-entry/
  transcribe-meeting/
  freshbooks-time-entry/
  intervals-to-freshbooks/
  session-rollup/
  topic-pulse/
  weekly-rollup/
```

**Why flat:**
- Skill resolution systems (Claude Code, superpowers `skills-core.js`) resolve by directory name under `skills/`. Nesting would break `install-into-repo.sh`.
- Discovery is via frontmatter descriptions, not folder hierarchy.
- Composition uses the same reference syntax regardless of type: `om:read-github-activity`.

**Repo-level discoverability:**
- Add `type: capability|workflow` to every skill frontmatter.
- Add `used_by:` to capabilities.
- Add `uses:` to workflows.
- Add a `docs/CAPABILITIES.md` index that groups capabilities by domain and links to their consumers.

### Capability interface

Each capability has four sections:

```markdown
---
name: discover-vault-entities
type: capability
used_by:
  - refine-daily-note
  - intervals-time-entry
description: Use when you need the full catalog of vault entities
  (projects, people, topics, tags) for matching or linking
---

# Discover Vault Entities

Build a catalog of all known entities in the Obsidian vault.

## Inputs

- **vault_root** (required): path to the Obsidian vault root
- **entity_types** (optional): which types to discover. Default: all.

## Process

1. Projects: list files in Projects/, extract names from filenames
2. People: list files in Persons/, read frontmatter aliases
3. ...
If QMD is available, use it to supplement filesystem discovery for fuzzy matching. If QMD is unavailable, continue with filesystem discovery only.

## Output

Return a structured entity catalog:
- projects: list of { name, path }
- people: list of { name, aliases[], path }
- ...
```

**Key differences from workflows:**

| Aspect | Capability | Workflow |
|--------|-----------|---------|
| Sections | Inputs, Process, Output | Phases (sequential, numbered) |
| Inputs/Outputs | Explicitly declared | Implicit |
| User interaction | None | Confirmation steps, review gates |
| Length | 50-150 lines | 150-500 lines |
| Auto mode | N/A (always autonomous) | Optional flag |
| Error handling | Skip quietly / return empty | Present to user / ask |

**Inputs are guidance, not an API contract.** These are natural-language instructions to an LLM, not function signatures. If the vault root is obvious from context, the agent doesn't need to formally "pass" it.

### Workflow interface

Each workflow declares what outcome it owns and which capabilities it composes:

```markdown
---
name: refine-daily-note
type: workflow
uses:
  - discover-vault-entities
  - read-slack-activity
  - read-github-activity
  - write-vault-section
description: Use when you want to improve a daily note by polishing writing, enriching context, and updating linked vault state
---

# Refine Daily Note

## Outcome

Improve a daily note while preserving workflow-specific review and approval behavior.

## Uses Capabilities

- `discover-vault-entities`
- `read-slack-activity`
- `read-github-activity`
- `write-vault-section`
```

### Composition: how workflows reference capabilities

A workflow references a capability with a bold marker:

```markdown
### Phase 1: Discover Vault Entities

**USE CAPABILITY: discover-vault-entities**
Pass the resolved vault root. Request all entity types.
Use QMD search to supplement filesystem discovery for fuzzy matching.
```

The workflow can add workflow-specific context after the marker — things the capability doesn't know about:

```markdown
### Phase 1.5: GitHub Activity Correlation

**USE CAPABILITY: read-github-activity**
Fetch activity for the target date.

After receiving the activity data, correlate with time entries from Phase 1:
1. Match PRs to time entries by repo or PR number
2. Enhance descriptions using PR titles
3. Flag time gaps where GitHub shows commits but no time entry exists
```

**Pattern:** the capability produces data, the workflow decides what to do with it.

**Loading behavior (target design):**
1. Agent reads the workflow SKILL.md (loaded on invocation)
2. Hits `**USE CAPABILITY: read-github-activity**`
3. Loads that capability's SKILL.md using the harness's normal skill invocation mechanism
4. Follows the capability's Process section
5. Returns to the workflow with the capability's Output
6. Continues with workflow-specific logic

This is intended to be lazy loading — the capability only enters context when the agent reaches that phase. Skipped phases (auto mode, tools unavailable) should never load their capabilities.

### Feasibility requirement

This architecture depends on the target harness being able to resolve a named skill from inside a workflow step. That must be validated before broad extraction work begins.

If a harness cannot reliably do nested invocation yet, the fallback is:
- keep the `**USE CAPABILITY:**` markers as a documentation convention
- keep enough inline workflow detail to remain executable
- postpone full extraction for that harness until capability resolution is proven

**Three marker variants:**

| Pattern | When to use |
|---------|------------|
| `**USE CAPABILITY: name**` + context line | Common case |
| `**USE CAPABILITY: name**` + follow-up logic | Capability produces data, workflow interprets it |
| `**USE CAPABILITY (optional): name**` | May be skipped (tools unavailable, auto mode) |

**Capabilities generally do not reference other capabilities.** Keep composition flat unless a future need is both common and proven. If a workflow needs two capabilities in sequence, it calls both:

```markdown
**USE CAPABILITY: read-github-activity**
Fetch activity for the target date.

**USE CAPABILITY: resolve-mappings**
- **vault_root**: resolved vault root
Resolve repo-to-project mappings for the repos found above.

Now correlate the activity with mapped projects...
```

## Capability Extraction Plan

### Tier 1: Extract first (2+ consumers AND independently useful)

**`discover-vault-entities`** (~80-100 lines, 5 consumers)
- Consumers: refine-daily-note, intervals-time-entry, transcribe-meeting, topic-pulse, weekly-rollup
- Builds catalog of projects, people, topics, tags, coding sessions, meetings
- Natural home for QMD integration (semantic + keyword search alongside filesystem listing)

**`write-vault-section`** (~60-90 lines, 5+ consumers)
- Consumers: intervals-time-entry, freshbooks-time-entry, session-rollup, refine-daily-note, topic-pulse
- Write to a named section in a daily/topic note with an explicit mode:
  - `replace_section`
  - `append_items`
  - `ensure_section`
- Handles Obsidian CLI with filesystem fallback

**`read-github-activity`** (~60-80 lines, 2 consumers + standalone)
- Consumers: refine-daily-note, intervals-time-entry
- Wraps `fetch-github-activity.sh`, returns structured PR/commit/review data
- Script moves from current skill to this capability

**`resolve-mappings`** (~90-120 lines, 3 consumers)
- Consumers: intervals-time-entry, freshbooks-time-entry, intervals-to-freshbooks
- Handles multiple mapping types via `mapping_types` input
- Uses an explicit `operation` mode:
  - `load` — read mapping tables only
  - `resolve` — apply mapping tables to provided data
  - `learn` — append confirmed new mappings
- Only `learn` mutates files

### Tier 2: Extract second (strong standalone value)

**`read-slack-activity`** (~90-110 lines, 1 consumer + standalone)
- Consumer: refine-daily-note
- Slack message search, channel grouping, huddle detection, coverage mapping, channel-to-project inference

**`read-outlook-calendar`** (~70-90 lines, 1 consumer + standalone)
- Consumer: intervals-time-entry
- Browser-based visual calendar reading via screenshot, meeting extraction with times/participants/subjects

### Tier 3: Don't extract yet

| Pattern | Why not |
|---------|---------|
| Vault root resolution | 3-4 lines — keep as convention |
| SQLite time DB ops | Already wrapped in dedicated scripts |
| FreshBooks API | Already shared as `freshbooks-api.sh` |
| Transcription pipeline | Single consumer, deeply specific |
| Intervals browser automation | Single consumer |

## Migration Strategy

One capability at a time. Each step produces a working system.

### Sequence

**Step 0: Prove capability invocation**
- Create one tiny test capability and one tiny test workflow
- Verify nested capability invocation works in each target harness
- If not proven, keep the markers as documentation only and defer behavior-changing extraction

**Step 1: Add discoverability metadata**
- Add `type:` to all skills
- Add `uses:` to workflows
- Add `used_by:` to capabilities as they are created
- Add `docs/CAPABILITIES.md`

**Step 2: `discover-vault-entities`**
- Best first extraction: most consumers, pure reads, no scripts to move, QMD integration opportunity
- Write capability, update `refine-daily-note` Phase 1 first, validate, then update remaining 4 consumers

**Step 3: `write-vault-section`**
- The other bookend — discovery reads, this writes. Together they establish the pattern.
- Update `session-rollup` first (smallest consumer), extend to others

**Step 4: `read-github-activity`**
- Involves moving `fetch-github-activity.sh` into capability's `scripts/`
- Update both consumers, verify script path references

**Step 5: `resolve-mappings`**
- Trickiest: three consumers with different mapping formats
- Capability needs `operation` + `mapping_types`
- Update `freshbooks-time-entry` first (simplest consumer)

**Step 6-7: Tier 2 extractions**
- `read-slack-activity` and `read-outlook-calendar` after Tier 1 is stable

### Migration rules

- Don't rewrite phases that aren't being extracted in the same pass
- Don't change auto mode behavior — capabilities don't know about auto mode
- Don't move scripts that aren't shared
- Don't update `agents/openai.yaml` until the pattern is validated

### Validation checklist (per extraction)

1. Same outputs — vault note looks identical
2. Lazy loading works — capability loads when reached, not at skill start
3. Standalone invocation works — calling capability directly produces useful output
4. Skipping works — skipped phases don't load their capabilities
5. Discoverability metadata is correct — `uses`, `used_by`, and `docs/CAPABILITIES.md` stay in sync

## Prior Art

This design is informed by patterns from:

- **Superpowers skill collection** — three-tier architecture (commands, skills, agents), lazy loading via Skill tool, CSO (descriptions say WHEN not WHAT), anti-rationalization tables, supporting files for heavy content
- **PR Review Toolkit** — command orchestrates specialized agents as subagents
- **Superpowers `writing-skills` meta-skill** — technique vs pattern vs reference taxonomy, TDD applied to skill creation, context-budget awareness
- **37signals/Basecamp** — large reference skill + small purpose-built skills
- **Atlassian** — self-contained enterprise workflows with heavy documentation

Key insight from superpowers: descriptions must say WHEN to use the skill, never WHAT it does. When a description summarizes the workflow, the agent shortcuts by following the summary and skips the actual body.
