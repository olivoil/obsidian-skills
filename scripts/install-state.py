#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path


def hash_path(path: Path) -> str:
    hasher = hashlib.sha256()

    if not path.exists() and not path.is_symlink():
        raise FileNotFoundError(f"path does not exist: {path}")

    def update_entry(entry: Path, relative_name: str) -> None:
        hasher.update(relative_name.encode("utf-8") + b"\0")

        if entry.is_symlink():
            hasher.update(b"S")
            hasher.update(os.readlink(entry).encode("utf-8") + b"\0")
        elif entry.is_file():
            hasher.update(b"F")
            hasher.update(entry.read_bytes())
        elif entry.is_dir():
            hasher.update(b"D")
        else:
            hasher.update(b"O")

    if path.is_file() or path.is_symlink():
        update_entry(path, path.name)
        return hasher.hexdigest()

    update_entry(path, ".")
    for child in sorted(path.rglob("*"), key=lambda p: p.relative_to(path).as_posix()):
        update_entry(child, child.relative_to(path).as_posix())

    return hasher.hexdigest()


def read_manifest(manifest_path: Path) -> dict:
    if not manifest_path.exists():
        return {"skills": {}}

    data = json.loads(manifest_path.read_text())
    if not isinstance(data, dict):
        raise ValueError(f"manifest is not a JSON object: {manifest_path}")
    data.setdefault("skills", {})
    return data


def write_manifest(manifest_path: Path, data: dict) -> None:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")


def cmd_hash_tree(args: argparse.Namespace) -> int:
    print(hash_path(Path(args.path)))
    return 0


def cmd_get_entry(args: argparse.Namespace) -> int:
    manifest = read_manifest(Path(args.manifest))
    entry = manifest.get("skills", {}).get(args.skill_name)
    if entry is None:
        return 0
    print(json.dumps(entry, sort_keys=True))
    return 0


def cmd_set_entry(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest)
    manifest = read_manifest(manifest_path)
    manifest.setdefault("skills", {})[args.skill_name] = {
        "mode": args.mode,
        "source": args.source,
        "installed_hash": args.installed_hash,
    }
    write_manifest(manifest_path, manifest)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    hash_tree = subparsers.add_parser("hash-tree")
    hash_tree.add_argument("path")
    hash_tree.set_defaults(func=cmd_hash_tree)

    get_entry = subparsers.add_parser("get-entry")
    get_entry.add_argument("manifest")
    get_entry.add_argument("skill_name")
    get_entry.set_defaults(func=cmd_get_entry)

    set_entry = subparsers.add_parser("set-entry")
    set_entry.add_argument("manifest")
    set_entry.add_argument("skill_name")
    set_entry.add_argument("mode")
    set_entry.add_argument("source")
    set_entry.add_argument("installed_hash")
    set_entry.set_defaults(func=cmd_set_entry)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
