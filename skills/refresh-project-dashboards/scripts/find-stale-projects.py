#!/usr/bin/env python3
"""Find Obsidian project notes with activity newer than their last dashboard refresh."""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sqlite3
from pathlib import Path

DATE_RE = re.compile(r"(20\d{2}-\d{2}-\d{2})")
REFRESH_RE = re.compile(r"Last dashboard refresh\*?\*?:\s*(20\d{2}-\d{2}-\d{2})", re.I)
WIKILINK_RE = re.compile(r"\[\[([^\]|#]+)(?:[#|][^\]]*)?\]\]")


def parse_date(value: str | None) -> dt.date | None:
    if not value:
        return None
    try:
        return dt.date.fromisoformat(value)
    except ValueError:
        return None


def file_date(path: Path) -> dt.date:
    return dt.datetime.fromtimestamp(path.stat().st_mtime).date()


def first_heading(text: str) -> str | None:
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return None


def project_files(vault: Path) -> list[Path]:
    projects = vault / "Projects"
    if not projects.exists():
        return []
    results: list[Path] = []
    for path in projects.rglob("*.md"):
        if any(part.startswith(".") for part in path.parts):
            continue
        if path.parent == projects:
            results.append(path)
        elif path.stem == path.parent.name:
            results.append(path)
    return sorted(set(results))


def aliases_for(path: Path, text: str) -> list[str]:
    aliases = {path.stem, path.parent.name}
    heading = first_heading(text)
    if heading:
        aliases.add(heading)
    for key in ("project", "client", "product"):
        match = re.search(rf"^{key}:\s*(.+)$", text, re.M | re.I)
        if match:
            aliases.add(match.group(1).strip().strip('"'))
    return sorted(a for a in aliases if len(a) >= 3)


def word_match(text: str, alias: str) -> bool:
    return re.search(rf"(?<![A-Za-z0-9]){re.escape(alias)}(?![A-Za-z0-9])", text, re.I) is not None


def linked(text: str, aliases: list[str]) -> bool:
    links = {m.lower() for m in WIKILINK_RE.findall(text)}
    return any(alias.lower() in links for alias in aliases)


def mentions_activity(path_text: str, body_text: str, aliases: list[str]) -> bool:
    # Strong signals first: wikilinks or filenames. Avoid broad substring matches in
    # meeting bodies, which cause false positives for generic project names.
    if linked(body_text, aliases):
        return True
    if any(word_match(path_text, alias) for alias in aliases):
        return True
    # Long aliases are safe enough as body text matches; short aliases like YPO, EWG,
    # CDS, or KHov should appear as wikilinks or in filenames to count.
    return any(len(alias) >= 6 and word_match(body_text, alias) for alias in aliases)


def mentions(text: str, aliases: list[str]) -> bool:
    return linked(text, aliases) or any(word_match(text, alias) for alias in aliases)


def note_activity(vault: Path, aliases: list[str], cutoff: dt.date) -> list[dict]:
    hits: list[dict] = []
    for folder in ("Daily Notes", "Meetings"):
        root = vault / folder
        if not root.exists():
            continue
        for path in root.glob("*.md"):
            name_date = parse_date(DATE_RE.search(path.name).group(1)) if DATE_RE.search(path.name) else None
            activity_date = name_date or file_date(path)
            if activity_date <= cutoff:
                continue
            try:
                text = path.read_text(errors="ignore")
            except OSError:
                continue
            if folder == "Meetings":
                matched = linked(text, aliases) or any(word_match(path.stem, alias) for alias in aliases)
            else:
                matched = mentions_activity(path.stem, text, aliases)
            if matched:
                hits.append({"date": activity_date.isoformat(), "type": folder, "path": str(path.relative_to(vault))})
    return hits


def db_activity(vault: Path, aliases: list[str], cutoff: dt.date) -> list[dict]:
    db = vault / ".cache" / "om" / "time-entries.db"
    if not db.exists():
        return []
    hits: list[dict] = []
    try:
        con = sqlite3.connect(db)
        con.row_factory = sqlite3.Row
        rows = con.execute("select date, project, hours, description from intervals_time_entries where date > ? order by date desc", (cutoff.isoformat(),)).fetchall()
    except Exception:
        return []
    finally:
        try:
            con.close()
        except Exception:
            pass
    for row in rows:
        haystack = f"{row['project']} {row['description']}"
        if mentions(haystack, aliases):
            hits.append({"date": row["date"], "type": "Intervals DB", "hours": row["hours"], "project": row["project"], "description": row["description"]})
    return hits


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--vault-root", default=".")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args()

    vault = Path(args.vault_root).expanduser().resolve()
    candidates = []
    for project in project_files(vault):
        text = project.read_text(errors="ignore")
        refresh_match = REFRESH_RE.search(text)
        refresh_date = parse_date(refresh_match.group(1)) if refresh_match else file_date(project)
        if not refresh_date:
            refresh_date = file_date(project)
        aliases = aliases_for(project, text)
        activity = note_activity(vault, aliases, refresh_date) + db_activity(vault, aliases, refresh_date)
        dashboard = project.with_name(f"{project.stem} Project Dashboard.html")
        dashboard_stale = dashboard.exists() and file_date(dashboard) < file_date(project)
        if activity or dashboard_stale:
            latest = max([parse_date(a["date"]) for a in activity if parse_date(a.get("date"))] + [file_date(project)])
            candidates.append({
                "project": project.stem,
                "path": str(project.relative_to(vault)),
                "last_refresh": refresh_date.isoformat(),
                "latest_activity": latest.isoformat(),
                "activity_count": len(activity),
                "dashboard_stale": dashboard_stale,
                "activity": sorted(activity, key=lambda x: x.get("date", ""), reverse=True)[:8],
            })
    candidates.sort(key=lambda x: (x["latest_activity"], x["activity_count"]), reverse=True)
    candidates = candidates[: args.limit]
    if args.json:
        print(json.dumps(candidates, indent=2))
    else:
        if not candidates:
            print("No stale project dashboards found.")
        for c in candidates:
            flag = " + dashboard older than project note" if c["dashboard_stale"] else ""
            print(f"{c['project']}: refresh {c['last_refresh']} -> activity {c['latest_activity']} ({c['activity_count']} hits){flag}")
            for a in c["activity"][:3]:
                print(f"  - {a.get('date')} {a.get('type')}: {a.get('path') or a.get('description')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
