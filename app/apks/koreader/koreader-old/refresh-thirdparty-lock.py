#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


URL_RE = re.compile(r"DOWNLOAD\s+URL(?:\s+[0-9a-fA-F]+)?\s+(https?://\S+)", re.MULTILINE)
GIT_RE = re.compile(r"DOWNLOAD\s+GIT\s+(\S+)\s+(\S+)", re.MULTILINE)
SPEC_ROCK_RE = re.compile(r"spec_rock\(\s*(https?://\S+)\s+[0-9a-fA-F]+\s*\)", re.MULTILINE)


def discover_from_source(source_root: Path) -> tuple[dict[str, str], dict[str, dict[str, str]]]:
    thirdparty = source_root / "base" / "thirdparty"
    url_deps: dict[str, str] = {}
    git_deps: dict[str, dict[str, str]] = {}

    for cmake in thirdparty.rglob("CMakeLists.txt"):
        rel = cmake.relative_to(thirdparty).parts
        key = rel[1] if rel and rel[0] == "spec" and len(rel) > 1 else rel[0]
        text = cmake.read_text(errors="ignore")

        url_match = URL_RE.search(text)
        if url_match:
            url_deps[key] = url_match.group(1)
        else:
            rock_match = SPEC_ROCK_RE.search(text)
            if rock_match:
                url_deps[key] = rock_match.group(1)

        git_match = GIT_RE.search(text)
        if git_match:
            git_deps[key] = {"rev": git_match.group(1), "url": git_match.group(2)}

    return url_deps, git_deps


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        help="KOReader source root (e.g. nix eval --raw .#packages.x86_64-linux.koreader.src.outPath)",
    )
    parser.add_argument(
        "--create-if-missing",
        action="store_true",
        help="Create a new lock from --source when koreader_deps.json does not exist.",
    )
    args = parser.parse_args()

    lock_path = Path(__file__).with_name("koreader_deps.json")
    if lock_path.exists():
        data = json.loads(lock_path.read_text())
    else:
        if not args.create_if_missing or not args.source:
            sys.stderr.write("koreader_deps.json missing; pass --source and --create-if-missing\n")
            return 2
        data = {}

    data.setdefault("git", {})
    url_changes: list[tuple[str, str, str]] = []
    git_changes: list[tuple[str, str, str]] = []
    changed = []

    if args.source:
        source_urls, source_git = discover_from_source(args.source)
        for name, new_url in source_urls.items():
            entry = data.get(name)
            if not isinstance(entry, dict):
                data[name] = {"url": new_url, "hash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="}
                url_changes.append((name, "<missing>", new_url))
                continue
            old_url = entry.get("url")
            if old_url != new_url:
                entry["url"] = new_url
                url_changes.append((name, old_url or "<missing>", new_url))

        git_data = data["git"]
        if not isinstance(git_data, dict):
            git_data = {}
            data["git"] = git_data
        for name, spec in source_git.items():
            old = git_data.get(name, {})
            old_url = old.get("url")
            old_rev = old.get("rev")
            if old_url != spec["url"] or old_rev != spec["rev"]:
                git_changes.append((name, f"{old_url or '<missing>'}@{old_rev or '<missing>'}", f"{spec['url']}@{spec['rev']}"))
            git_data[name] = {
                "url": spec["url"],
                "rev": spec["rev"],
                "hash": old.get("hash", "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="),
            }

    for name, info in data.items():
        if name == "git" or not isinstance(info, dict):
            continue
        if "url" not in info or "hash" not in info:
            continue

        proc = subprocess.run(
            ["nix", "store", "prefetch-file", "--json", info["url"]],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            sys.stderr.write(f"failed to prefetch {name}: {info['url']}\n")
            sys.stderr.write(proc.stderr)
            return proc.returncode

        payload = json.loads(proc.stdout.strip().splitlines()[-1])
        new_hash = payload["hash"]
        if new_hash != info["hash"]:
            changed.append((name, info["hash"], new_hash))
            info["hash"] = new_hash

    git_hash_changes = []
    git_data = data.get("git", {})
    if isinstance(git_data, dict):
        for name, info in git_data.items():
            if not isinstance(info, dict) or "url" not in info or "rev" not in info:
                continue
            proc = subprocess.run(
                [
                    "nix",
                    "run",
                    "nixpkgs#nix-prefetch-git",
                    "--",
                    "--url",
                    info["url"],
                    "--rev",
                    info["rev"],
                    "--fetch-submodules",
                ],
                capture_output=True,
                text=True,
            )
            if proc.returncode != 0:
                sys.stderr.write(f"failed to prefetch git {name}: {info['url']}@{info['rev']}\n")
                sys.stderr.write(proc.stderr)
                return proc.returncode
            payload = json.loads(proc.stdout)
            new_hash = payload["sha256"]
            resolved_rev = payload.get("rev", info["rev"])
            info["rev"] = resolved_rev
            if new_hash != info.get("hash"):
                git_hash_changes.append((name, info.get("hash", "<missing>"), new_hash))
                info["hash"] = new_hash

    lock_path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"updated urls: {len(url_changes)}")
    for name, old_url, new_url in url_changes:
        print(f"{name}: {old_url} -> {new_url}")
    print(f"updated git urls/revs: {len(git_changes)}")
    for name, old_spec, new_spec in git_changes:
        print(f"{name}: {old_spec} -> {new_spec}")
    print(f"updated {len(changed)} entries")
    for name, old_hash, new_hash in changed:
        print(f"{name}: {old_hash} -> {new_hash}")
    print(f"updated git hashes: {len(git_hash_changes)}")
    for name, old_hash, new_hash in git_hash_changes:
        print(f"{name}: {old_hash} -> {new_hash}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
