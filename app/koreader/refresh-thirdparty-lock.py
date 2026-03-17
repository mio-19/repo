#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    lock_path = Path(__file__).with_name("koreader_deps.json")
    data = json.loads(lock_path.read_text())
    changed = []

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

    lock_path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"updated {len(changed)} entries")
    for name, old_hash, new_hash in changed:
        print(f"{name}: {old_hash} -> {new_hash}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
