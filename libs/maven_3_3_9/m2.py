
import json
from pathlib import Path

repo = Path.home() / ".m2" / "repository"
base_url = "https://repo.maven.apache.org/maven2"

deps = {}

if repo.exists():
    for f in sorted(repo.rglob("*")):
        if not f.is_file():
            continue

        rel = f.relative_to(repo).as_posix()

        # Skip Maven metadata/checksum helper files
        if rel.endswith((".sha1", ".md5", ".lastUpdated", "_remote.repositories")):
            continue

        parts = rel.split("/")
        if len(parts) < 4:
            continue

        filename = parts[-1]
        version = parts[-2]
        artifact = parts[-3]
        group = ".".join(parts[:-3])

        # classifier-aware parsing:
        # artifact-version[-classifier].ext
        if "." not in filename:
            continue
        stem, ext = filename.rsplit(".", 1)

        prefix = f"{artifact}-{version}"
        if not stem.startswith(prefix):
            continue

        remainder = stem[len(prefix):]
        classifier = remainder[1:] if remainder.startswith("-") else None

        coord = f"{group}:{artifact}:{ext}:{version}"
        if classifier:
            coord += f":{classifier}"

        deps[coord] = {
            "layout": rel,
            "sha256": "",
            "url": f"{base_url}/{rel}",
        }

print(json.dumps({"dependencies": deps}, indent=2, sort_keys=True))