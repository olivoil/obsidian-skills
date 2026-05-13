#!/usr/bin/env bash
set -euo pipefail

OWNER=""
REPO=""
PR=""
COMMIT=""
EVENT=""
BODY=""
COMMENTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --pr) PR="$2"; shift 2 ;;
    --commit) COMMIT="$2"; shift 2 ;;
    --event) EVENT="$2"; shift 2 ;;
    --body) BODY="$2"; shift 2 ;;
    --comments) COMMENTS="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

for var in OWNER REPO PR COMMIT BODY COMMENTS; do
  if [[ -z "${!var}" ]]; then
    echo "Missing required --${var,,}" >&2
    exit 1
  fi
done

if [[ ! -f "$COMMENTS" ]]; then
  echo "Comments file not found: $COMMENTS" >&2
  exit 1
fi

payload="$(mktemp)"
trap 'rm -f "$payload"' EXIT

python3 - "$COMMIT" "$BODY" "$EVENT" "$COMMENTS" > "$payload" <<'PY'
import json
import sys

commit, body, event, comments_path = sys.argv[1:]
with open(comments_path, "r", encoding="utf-8") as f:
    comments = json.load(f)

payload = {
    "commit_id": commit,
    "body": body,
    "comments": comments,
}
if event:
    payload["event"] = event

print(json.dumps(payload))
PY

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$REPO/pulls/$PR/reviews" \
  --input "$payload"
