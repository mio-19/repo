import os
import re

hashes = {
    "weathermaster": "sha256-hSqAXn5IJfaAQ0qF6us1/GRWHcYJbVxvTRBC41TEUVQ=",
    "ytdlnis": "sha256-tjRvk37L37IoEsxGj9RbSOtZXU57RfmyHCxEDwVEStU=",
    "haven": "sha256-NLdJfCK9hXY7dLDH5zZvBKvH3UGPxxs+G558jwuxAb8=",
    "gamenative": "sha256-m1+RpeP45d3hyFN3grxXQ14y0mB+fjAa2W18ukTh+RE=",
    "forkgram-classic": "sha256-Z4EwDY3EDv38HqQ382RoyFle7xijwNUpJJ2Hz7nGDw4=",
    "meditrak": "sha256-MKZp8WCTR+AfqJDJlC27R27vKWRbJcDfIBm/jwgGEiA=",
    "kdeconnect-android": "sha256-nF7j1w4uP/99iwJ6F8A9qIdAsIx9aw52OIWeX3fOLCU=",
    "mastodon-android": "sha256-AEkucNw6ASUvaTQXlWWF1HoBl3Xhj0dZHFQSU5qFgHA=",
    "rain": "sha256-Q8S1aMWO8AE49sgUAuo8C7Vvvn7d4XOWBzjWbR62wIY="
}

for pkg, hsh in hashes.items():
    pkg_dir = f"app/apks/{pkg}"
    if not os.path.exists(pkg_dir):
        pkg_dir = f"app/by-name/{pkg}"
    nix_file = os.path.join(pkg_dir, "package.nix")
    if not os.path.exists(nix_file):
        nix_file = os.path.join(pkg_dir, "default.nix")
        
    if not os.path.exists(nix_file):
        continue
        
    with open(nix_file, 'r') as f:
        content = f.read()
        
    # we replace hash = "" with the new hash for the FIRST occurrence which is usually the source
    # wait, what if there are multiple blanked hashes?
    content = re.sub(r'hash\s*=\s*""', f'hash = "{hsh}"', content, count=1)
    
    with open(nix_file, 'w') as f:
        f.write(content)

