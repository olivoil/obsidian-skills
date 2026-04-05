---
name: session-rollup
description: Summarize recent work from Engram memory into an Obsidian coding note and link it from the daily note. Use when wrapping up a coding session or when asked to sync recent project work into the vault.
---

# Session Rollup

Capture recent work into the Obsidian vault using Engram as the system of record for cross-agent session memory.

## Goal

Create a coding-session note in the vault, summarize recent work for the current project, and link it from the relevant daily note.

## Workflow

### 0. Resolve context

1. Run `obsidian vault info=path` to get the vault root.
2. Determine the target date. Default to today unless the user requested a different date.
3. Determine the current repo name and branch from the working directory.
4. Determine the Engram project key to summarize:
   - Prefer an explicit project named by the user.
   - Otherwise use the current repo name.

### 1. Read Engram memory

Use Engram to gather recent context for the chosen project:

1. Read recent memory context for the project.
2. Search for recent observations if the context view is too sparse.
3. Pull any full observations needed to clarify decisions, discoveries, or bug fixes.

Focus on extracting:
- a one-line summary of what was accomplished
- notable decisions
- open questions
- follow-ups
- relevant files or systems touched

If Engram does not contain enough context, say so explicitly and fall back to the current working tree plus the current conversation.

### 2. Gather repo metadata

Collect:
- **Date** in `YYYY-MM-DD`
- **Branch** from `git branch --show-current`
- **Repo** from the working directory
- **Files changed** using:
  ```bash
  git diff --name-only $(git merge-base HEAD main 2>/dev/null || echo HEAD) HEAD 2>/dev/null || true
  git diff --name-only
  git diff --name-only --cached
  ```

Deduplicate the file list.

### 3. Write the coding note

Path:

```text
Coding/{date}--{repo-name}--{branch}.md
```

If a file with the same prefix already exists for the same day and branch, append `--2`, `--3`, and so on.

Format:

```markdown
---
date: {date}
branch: {branch}
repo: {repo}
source: engram
---

# Session: {branch}

> {one-line summary}

## Decisions
- ...

## Open Questions
- ...

## Follow-ups
- [ ] ...

## Files Changed
- ...
```

Omit any empty section.

### 4. Link from the daily note

1. Read the relevant daily note.
2. Create it if missing.
3. Insert or update a `### Coding Sessions` section.
4. Add a bullet linking to the new coding note with the one-line summary.

Preferred bullet format:

```markdown
- [[{date}--{repo-name}--{branch}]] - {one-line summary}
```

### 5. Confirm

Report:
- the created coding-note path
- whether the daily note was updated
- a short preview of the summary

## Rules

- Engram is the primary source of truth for recent session history.
- Always write the result into Obsidian; do not stop at an Engram-only summary.
- If Engram and the current repo state conflict, say so instead of smoothing it over.
