---
version: alpha
name: Obsidian Project Dashboard Analyst Slate
description: Sparse internal project dashboards for Obsidian, optimized for re-entry, next focus, recent activity, todos, meetings, hours, people, and source links.
colors:
  primary: "#2563eb"
  secondary: "#475569"
  surface: "#f7f9fc"
  on-surface: "#20242c"
  surface-dark: "#151922"
  on-surface-dark: "#e6eaf0"
  muted: "#64748b"
  faint: "#8a94a6"
  wash: "#eef3f8"
  wash-strong: "#e2e8f0"
  success: "#166534"
  warning: "#92400e"
  danger: "#b91c1c"
typography:
  headline-display:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, system-ui, sans-serif"
    fontSize: 72px
    fontWeight: 750
    lineHeight: 0.94
    letterSpacing: -0.072em
  headline-md:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, system-ui, sans-serif"
    fontSize: 25px
    fontWeight: 730
    lineHeight: 1.1
    letterSpacing: -0.045em
  body-md:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.58
    letterSpacing: 0em
  body-lg:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, system-ui, sans-serif"
    fontSize: 17px
    fontWeight: 400
    lineHeight: 1.58
    letterSpacing: 0em
  label-sm:
    fontFamily: "ui-sans-serif, -apple-system, BlinkMacSystemFont, Segoe UI, system-ui, sans-serif"
    fontSize: 12px
    fontWeight: 760
    lineHeight: 1.2
    letterSpacing: 0.07em
rounded:
  sm: 8px
  md: 12px
  full: 999px
spacing:
  xs: 4px
  sm: 9px
  md: 18px
  lg: 32px
  xl: 58px
components:
  page-light:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
  page-dark:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.on-surface-dark}"
    typography: "{typography.body-md}"
  primary-action:
    backgroundColor: "{colors.on-surface}"
    textColor: "{colors.surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sm}"
    padding: 12px
  secondary-action:
    backgroundColor: "{colors.wash}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.sm}"
    padding: 12px
  active-chip:
    backgroundColor: "{colors.wash}"
    textColor: "{colors.success}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 9px
  status-warning:
    backgroundColor: "{colors.wash}"
    textColor: "{colors.warning}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 9px
  status-danger:
    backgroundColor: "{colors.wash}"
    textColor: "{colors.danger}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 9px
  metadata:
    backgroundColor: "{colors.wash-strong}"
    textColor: "{colors.secondary}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 9px
  muted-label:
    textColor: "{colors.muted}"
    typography: "{typography.body-md}"
  faint-label:
    textColor: "{colors.faint}"
    typography: "{typography.label-sm}"
  link:
    textColor: "{colors.primary}"
    typography: "{typography.body-md}"
---

# Project Dashboard Design Reference

## Overview

Olivier checks project dashboards inside Obsidian to re-enter a project quickly: what changed, what to do next, what is blocked, who is involved, which meetings matter, and which hours/work were recent. The UI should feel like a precise internal project cockpit, not a SaaS marketing dashboard.

The dashboard should answer, in order:
1. Where are we right now?
2. What should I focus on next?
3. What current todos/open questions need attention?
4. What happened most recently?
5. Which meetings should I reopen?
6. What did I do, and what hours are entered vs likely unentered?
7. Who is involved?
8. What source files should I jump to?

Prefer project-specific section names when useful, but keep the above jobs covered.

## Colors

Use the token palette as semantic intent, then implement final CSS with OKLCH equivalents so neutrals remain subtly tinted. Do not use pure black or pure white.

- **Primary**: focused links, current selections, and the smallest useful amount of emphasis.
- **Surface / on-surface**: page background and main text in light mode.
- **Surface-dark / on-surface-dark**: page background and main text in dark mode.
- **Muted / faint**: metadata, row labels, timestamps, and secondary descriptions.
- **Wash / wash-strong**: pills, quiet secondary actions, and theme-control backgrounds.
- **Success / warning / danger**: status dots and small semantic tags only.

## Typography

Use the system font stack throughout. Product UI familiarity matters more than display novelty.

- **Headline display**: project name in the hero, large and tight.
- **Headline medium**: section headings.
- **Body medium**: normal dashboard text, rows, tables, timelines, and list content.
- **Body large**: hero summary text.
- **Label small**: eyebrow labels, timestamps, metadata, and pills.

Keep prose line length around 65-75 characters when possible. Use scale, weight, and spacing for hierarchy, not borders around every section.

## Layout & Spacing

- Topbar: breadcrumbs left, status/update/theme controls right.
- Hero: project title and document actions on the left; compact current-state rows on the right.
- Strip: 3-4 high-signal facts separated by sparse horizontal rules.
- Sections: two-column section header, with `h2` left and a short explanatory sentence right.
- Content: use 2-3 columns, timelines, simple tables, and compact people grids.
- Recent meetings: show newest 3, then `<details><summary>Show more meetings</summary>`.
- Todos: read-only checkbox-looking list. Do not wire up local state.

Vary vertical spacing for rhythm. Do not wrap every section in a bordered container.

## Elevation & Depth

Avoid decorative elevation. The default dashboard should feel flat, quiet, and durable.

- Prefer whitespace, alignment, type hierarchy, and sparse horizontal rules.
- Use subtle background washes for pills and secondary actions only.
- Do not use glassmorphism or ornamental shadows.
- If dark mode needs depth, use a restrained radial background glow on `.shell::before`.

## Shapes

- Buttons and source chips: small rounded rectangles, about 8px.
- Status/theme pills: fully rounded.
- Avoid mixing many radius systems in one dashboard.
- Do not use side-stripe borders as visual accents.

## Components

### Theme controls

Obsidian HTML plugin may render the file in an iframe where JavaScript/localStorage is unreliable. Use CSS-only controls:

```html
<input class="theme-radio" type="radio" name="theme" id="theme-light">
<input class="theme-radio" type="radio" name="theme" id="theme-dark">
<input class="theme-radio" type="radio" name="theme" id="theme-system" checked>
<main class="shell">...</main>
```

Override CSS variables with sibling selectors:

```css
#theme-light:checked ~ .shell { ... }
#theme-dark:checked ~ .shell { ... }
#theme-light:checked ~ .shell label[for="theme-light"],
#theme-dark:checked ~ .shell label[for="theme-dark"],
#theme-system:checked ~ .shell label[for="theme-system"] { ... }
```

Put the fixed full-page background on `.shell::before`, not `body`, so checked variables affect it reliably.

### Dashboard sections

- **Current status**: compact label/value rows, not a prose block.
- **Best next focus**: three concise columns with ordered steps.
- **Todos**: split into useful groups; keep them read-only and sourced from Markdown.
- **Latest activity**: timeline rows with dates and short summaries.
- **Recent meetings**: link to meeting notes, newest first, with show-more for older meetings.
- **My work and hours**: separate entered DB rows from recent daily-note scan.
- **People**: compact grid with name, role, and why they matter.
- **Sources**: quiet chips linking to local vault files.

## Do's and Don'ts

- Do keep every claim grounded in the project note, linked meetings, daily notes, time-entry DB, or local key documents.
- Do use concrete dates, especially for latest activity and refresh time.
- Do keep copy useful, terse, and normal.
- Do separate “entered in DB” from “recent daily-note scan” when showing hours.
- Don't invent status, staffing, deadlines, progress percentages, metrics, owners, or decisions.
- Don't include apologies, meta commentary, or “based on available notes” UI disclaimers.
- Don't mention missing data unless it is an actual open question or blocker.
- Don't create separate interactive todo state; todos live in the project Markdown file.
- Don't use gradient text, glassmorphism, hero-metric templates, identical card grids, or card-in-card layouts.
- Don't use em dashes in generated dashboard copy.
