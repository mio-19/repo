import os
import re
import subprocess
import sys

updates = [
    ("weathermaster", "v3.3.0", "v3.4.0", "apk_weathermaster"),
    ("ytdlnis", "v1.8.8", "v1.8.9.1", "apk_ytdlnis"),
    ("haven", "v5.59.65", "v5.59.75", "apk_haven"),
    ("gamenative", "v1.0.0-prerelease", "v1.0.0", "apk_gamenative"),
    ("forkgram-classic", "12.7.12.0", "12.7.13.0", "apk_forkgram-classic"),
    ("meditrak", "v0.17.5", "v0.17.6", "apk_meditrak"),
    ("kdeconnect-android", "v1.35.8", "v1.35.9", "apk_kdeconnect-android"),
    ("mastodon-android", "v2.12.3", "v2.13.1", "apk_mastodon-android"),
    ("rain", "v1.3.16", "v1.3.18", "apk_rain")
]

def blank_hashes(content):
    # Blank out hashes
    content = re.sub(r'hash\s*=\s*"[^"]*"', 'hash = ""', content)
    content = re.sub(r'vendorHash\s*=\s*"[^"]*"', 'vendorHash = ""', content)
    content = re.sub(r'cargoHash\s*=\s*"[^"]*"', 'cargoHash = ""', content)
    return content

for pkg, old_ver, new_ver, attr in updates:
    print(f"Updating {pkg} to {new_ver}...")
    pkg_dir = f"app/apks/{pkg}"
    if not os.path.exists(pkg_dir):
        pkg_dir = f"app/by-name/{pkg}"
    
    nix_file = os.path.join(pkg_dir, "package.nix")
    if not os.path.exists(nix_file):
        nix_file = os.path.join(pkg_dir, "default.nix")
        
    if not os.path.exists(nix_file):
        print(f"Could not find package.nix for {pkg}")
        continue
        
    with open(nix_file, 'r') as f:
        content = f.read()
        
    # Replace version
    content = content.replace(old_ver, new_ver)
    
    # If the version string doesn't have 'v' but the old_ver did, maybe we need to be careful.
    # We replaced old_ver with new_ver globally. Let's hope it's fine.
    
    content = blank_hashes(content)
    
    with open(nix_file, 'w') as f:
        f.write(content)
        
    # Try to build to get the hash
    print(f"Building {attr} to get hashes...")
    res = subprocess.run(["nix", "build", f".#{attr}", "--no-link"], capture_output=True, text=True)
    
    out = res.stderr + res.stdout
    # Find hash mismatches
    # e.g., specified: empty, got: sha256-...
    got_hashes = re.findall(r'got:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    if not got_hashes:
        # sometimes it says 'actual: sha256-...' or 'actual   : sha256-...'
        got_hashes = re.findall(r'actual:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    
    print("Got hashes from build output:", got_hashes)
    
    # Now we need to put the hashes back into the file.
    # A simple way: restore the file, then replace old_ver with new_ver, and then replace old hash with new hash?
    # No, there could be multiple hashes (src, vendorHash, etc.)
    # Let's just do it manually for each package if it's too complex.
    
