---
name: pr-review
description: Use when asked to review a pull request, inspect a PR URL or number, review a local branch before opening a PR, post GitHub review comments, or give code-review feedback on changed files.
---

# PR Review

Review changed code for real risk. The goal is risk reduction, not perfect code. Prefer a small number of high-confidence, actionable findings over a long list of style opinions.

This skill is project-agnostic. Infer the stack from the repository, changed files, manifests, and local instructions instead of assuming a framework.

## Inputs

Accept any of:

- PR URL
- `#123` or `123`
- branch name
- no argument, meaning current branch's PR if one exists
- no PR, meaning local branch review mode

## Workflow

### 1. Resolve the review target

If a PR exists, collect metadata:

```bash
gh pr view {input} --json number,title,body,author,baseRefName,headRefName,headRefOid,files,additions,deletions,url

gh pr diff {number}
```

If `gh pr view` fails or the user explicitly asks for a pre-PR review, use local branch mode:

```bash
git rev-parse --abbrev-ref HEAD
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#^refs/remotes/origin/##'
git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null || git merge-base HEAD origin/dev
git diff {base_sha}
git diff {base_sha} --name-only
git log {base_sha}..HEAD --oneline
```

In local mode, never post to GitHub. Present findings in chat and end by saying you can post inline comments once a PR exists.

### 2. Load project context

Read only relevant context:

- Root `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `.cursor/rules`, `.cursorrules`, `README.md`
- Any instruction files in directories containing changed files
- Manifests/config that identify stack: `package.json`, `pnpm-lock.yaml`, `Gemfile`, `pyproject.toml`, `go.mod`, `Cargo.toml`, framework configs
- Full changed files when needed to understand the diff

Summarize the PR's purpose in 2–4 sentences from PR body, commit messages, and diff.

### 3. Review passes

If subagents/parallel agents are available, run these passes in parallel. If not, run them sequentially yourself. Every pass must return findings as JSON-like objects with `path`, `line`, `severity`, `body`, and `category`.

| Pass | Focus | What to flag |
|---|---|---|
| Project conventions | Explicit repo rules | Only violations backed by project docs/instructions |
| Bugs/regressions | Runtime correctness | Null/undefined issues, race conditions, off-by-one errors, broken control flow, resource leaks |
| Tests | Risk coverage | Missing meaningful tests for new behavior, brittle tests, tests that assert implementation details instead of requirements |
| Security/privacy | Exploitable or sensitive behavior | Injection, XSS, authz/authn gaps, IDOR, secrets exposure, unsafe deserialization, user-controlled filesystem/shell access |
| Performance | User-visible or scaling risk | N+1 queries, unbounded loops, expensive render paths, unnecessary network calls, cache invalidation bugs |
| API/design | Maintainability and compatibility | Breaking public contracts, leaky abstractions, overly rigid component APIs, migration gaps |
| Stack-specific | Detected frameworks | Apply relevant checks for React/Next, Vue/Nuxt, Rails, Django, Go, Rust, etc. |
| History/context | Changed-file history | Use `git log`/`git blame` to catch regressions against nearby code intent |

Useful commands:

```bash
git log --oneline -- {path}
git blame -L {start},{end} -- {path}
gh pr list --state merged --search {path}
```

### 4. Finding schema

Use this internal format:

```json
{
  "path": "src/example.ts",
  "line": 42,
  "severity": "important",
  "body": "Could we guard this before calling it? In the empty-state path this looks like it can be undefined.",
  "category": "bug",
  "confidence": 90
}
```

Severity values:

- `critical` — likely exploitable security issue, data loss, production outage, or severe regression
- `important` — likely bug, missing required test, meaningful security/privacy/performance issue
- `suggestion` — actionable improvement with clear benefit
- `nitpick` — only include when explicitly asked or when backed by repo rules

### 5. Filter hard

Discard findings that:

- Are below 80% confidence
- Are pre-existing and not worsened by the PR
- Are purely stylistic and not backed by project rules
- Would be caught by lint/typecheck/formatters
- Are contradicted by the PR's stated goal
- Cannot be placed on a changed line if posting inline
- Do not include a concrete fix, test, or verification suggestion

Deduplicate by path + line + concern. Prefer the clearest version.

### 6. Tone

Comments must sound like a human teammate:

- Prefer questions when uncertain: “could this be undefined here?”
- Use “we” language when referring to project practice
- No category prefixes like `[Bug]`
- No AI attribution/footer
- Keep comments short unless the issue needs explanation
- Suggest tests when uncertainty remains
- Do not cite instruction files by name in inline comments; state the practice naturally

### 7. Preview before posting

Always show findings before any GitHub write:

```markdown
## Code Review: {owner}/{repo}#{number or local branch}
**{title or branch}** | Changes: +{additions} -{deletions} across {N} files

### Critical ({count})
- **path:line** — summary (confidence: NN)

### Important ({count})
...

### Suggestions ({count})
...

**Summary:** 1–2 sentence overall assessment.
```

For PRs, ask how to post:

1. Pending draft review (default)
2. Comment
3. Approve
4. Request changes
5. Cancel

### 8. Post only after confirmation

Create `/tmp/review-comments-{number}.json`:

```json
[{"path":"src/example.ts","line":42,"body":"Could we guard this before calling it?"}]
```

Then run the helper script from this skill directory:

```bash
bash /path/to/pr-review/scripts/post-github-review.sh \
  --owner "{owner}" \
  --repo "{repo}" \
  --pr "{number}" \
  --commit "{head_sha}" \
  --event "COMMENT|APPROVE|REQUEST_CHANGES" \
  --body "{summary}" \
  --comments "/tmp/review-comments-{number}.json"
```

Omit `--event` for a pending draft review. Delete the temp comments file after posting.

Report the review URL and comment count.
