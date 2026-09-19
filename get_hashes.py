import subprocess
import re

targets = [
    ".#apk_forkgram-classic",
    ".#apk_haven",
    ".#apk_mpv-android",
    ".#apk_hoodles-patches"
]

for t in targets:
    print(f"Fetching {t}...")
    p = subprocess.run(["nix", "build", t], capture_output=True, text=True)
    out = p.stdout + p.stderr
    hashes = re.findall(r'got:\s+(sha256-.*)', out)
    print(f"{t}: {hashes}")
