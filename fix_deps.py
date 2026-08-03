import json

with open("app/apks/meshtastic/meshtastic_deps.json", "r") as f:
    d = json.load(f)

repo = d["https://central.sonatype.com/repository/maven-snapshots/org"]
new_repo = {}
for k, v in repo.items():
    new_repo[k] = v
    if "20260728.163041-1" in k:
        new_k = k.replace("20260728.163041-1", "SNAPSHOT")
        new_repo[new_k] = v

d["https://central.sonatype.com/repository/maven-snapshots/org"] = new_repo

with open("app/apks/meshtastic/meshtastic_deps.json", "w") as f:
    json.dump(d, f, indent=1)
