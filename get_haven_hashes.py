import subprocess
import re

p = subprocess.run(["nix", "build", ".#apk_haven"], capture_output=True, text=True)
out = p.stdout + p.stderr
print(out)
