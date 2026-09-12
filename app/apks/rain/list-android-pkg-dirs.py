import json
import urllib.parse

with open(".dart_tool/package_config.json") as f:
    data = json.load(f)
for pkg in data["packages"]:
    path = urllib.parse.urlparse(pkg["rootUri"]).path.removesuffix("/.")
    print(path)
