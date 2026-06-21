import os, re, subprocess

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

for pkg, old_ver, new_ver, attr in updates:
    pkg_dir = f"app/apks/{pkg}"
    if not os.path.exists(pkg_dir): pkg_dir = f"app/by-name/{pkg}"
    nix_file = os.path.join(pkg_dir, "package.nix")
    if not os.path.exists(nix_file): nix_file = os.path.join(pkg_dir, "default.nix")
    if not os.path.exists(nix_file): continue
    
    with open(nix_file, 'r') as f: content = f.read()
    
    # Only replace old_ver if it's assigned to version
    content = content.replace(old_ver, new_ver)
    
    # Find src block and replace hash
    src_match = re.search(r'(src\s*=\s*(?:pkgs\.)?fetch(?:FromGitHub|FromGitLab|git)\s*\{)(.+?)(\n\s*\})', content, re.DOTALL)
    if src_match:
        inner = src_match.group(2)
        inner = re.sub(r'hash\s*=\s*"[^"]*"', 'hash = ""', inner)
        content = content[:src_match.start()] + src_match.group(1) + inner + src_match.group(3) + content[src_match.end():]
        
    with open(nix_file, 'w') as f: f.write(content)
    
    # get new hash
    res = subprocess.run(["nix", "build", f".#{attr}", "--no-link"], capture_output=True, text=True)
    out = res.stderr + res.stdout
    hashes = re.findall(r'got:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    if not hashes: hashes = re.findall(r'actual:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    
    if hashes:
        new_hash = hashes[0]
        # write it back
        with open(nix_file, 'r') as f: content = f.read()
        src_match = re.search(r'(src\s*=\s*(?:pkgs\.)?fetch(?:FromGitHub|FromGitLab|git)\s*\{)(.+?)(\n\s*\})', content, re.DOTALL)
        if src_match:
            inner = src_match.group(2)
            inner = re.sub(r'hash\s*=\s*""', f'hash = "{new_hash}"', inner)
            content = content[:src_match.start()] + src_match.group(1) + inner + src_match.group(3) + content[src_match.end():]
            with open(nix_file, 'w') as f: f.write(content)
            
        # run mitmcache update
        script = subprocess.run(["nix", "build", f".#{attr}.mitmCache.updateScript", "--no-link", "--print-out-paths"], capture_output=True, text=True).stdout.strip()
        if script:
            print(f"Updating deps for {pkg}...")
            subprocess.run([script])
            
print("Done fixing updates")
