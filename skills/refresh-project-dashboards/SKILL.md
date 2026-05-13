---
name: refresh-project-dashboards
description: Use when scanning Obsidian projects for new activity, stale project notes, stale HTML dashboards, or batch-refreshing project dashboards across the vault.
---

# Refresh Project Dashboards

Find project notes whose surrounding activity is newer than their last dashboard refresh, then update each candidate using `generate-project-dashboard`.

## Workflow

1. Resolve vault root, default to the current repository root.
2. Run the stale-project scanner:
   ```bash
   python skills/refresh-project-dashboards/scripts/find-stale-projects.py --vault-root "$PWD"
   ```
   Use `--json` if easier to post-process.
3. Review candidates. In interactive mode, summarize the candidates and ask before batch edits if more than one project will be changed. In auto mode, limit to the top 5 stale projects unless the user specifies a limit.
4. For each selected project, use `generate-project-dashboard`:
   - update the Markdown source-of-truth first
   - update/create the HTML dashboard
   - verify links and preview rendering
5. Report refreshed projects, skipped projects, and reasons.

## Candidate policy

A project is stale when any of these are newer than its project note's `Last dashboard refresh` date, or newer than the project file mtime when no refresh date exists:
- a daily note that mentions the project or `[[Project]]`
- a meeting note whose filename/content mentions the project
- an Intervals DB row matching the project alias
- an HTML dashboard older than the project Markdown note

The scanner is only a triage tool. Before editing, still read the relevant notes and avoid unsupported claims.

## Batch safety

- Do not invent missing project data to make every dashboard look complete.
- Keep dashboards read-only with todos in Markdown.
- Prefer refreshing fewer projects well over sweeping many thinly.
- If a project has ambiguous aliases or unrelated false-positive activity, skip it and report why.
