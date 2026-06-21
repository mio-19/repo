import os, re, subprocess

updates = [
    ("weathermaster", "3.3.0", "3.4.0", "apk_weathermaster"),
    ("ytdlnis", "1.8.8", "1.8.9.1", "apk_ytdlnis"),
    ("haven", "5.59.65", "5.59.75", "apk_haven"),
    ("gamenative", "1.0.0-prerelease", "1.0.0", "apk_gamenative"),
    ("forkgram-classic", "12.7.12.0", "12.7.13.0", "apk_forkgram-classic"),
    ("meditrak", "0.17.5", "0.17.6", "apk_meditrak"),
    ("kdeconnect-android", "1.35.8", "1.35.9", "apk_kdeconnect-android"),
    ("mastodon-android", "2.12.3", "2.13.1", "apk_mastodon-android"),
    ("rain", "1.3.16", "1.3.18", "apk_rain")
]

for pkg, old_ver, new_ver, attr in updates:
    pkg_dir = f"app/apks/{pkg}"
    if not os.path.exists(pkg_dir): pkg_dir = f"app/by-name/{pkg}"
    nix_file = os.path.join(pkg_dir, "package.nix")
    if not os.path.exists(nix_file): nix_file = os.path.join(pkg_dir, "default.nix")
    if not os.path.exists(nix_file): continue
    
    with open(nix_file, 'r') as f: content = f.read()
    
    content = content.replace(f'"{old_ver}"', f'"{new_ver}"')
    
    src_match = re.search(r'(src\s*=\s*(?:pkgs\.)?fetch(?:FromGitHub|FromGitLab|git)\s*\{)(.+?)(\n\s*\})', content, re.DOTALL)
    if src_match:
        inner = src_match.group(2)
        inner = re.sub(r'hash\s*=\s*"[^"]*"', 'hash = ""', inner)
        content = content[:src_match.start()] + src_match.group(1) + inner + src_match.group(3) + content[src_match.end():]
        
    with open(nix_file, 'w') as f: f.write(content)
    
    print(f"Bumping version for {pkg} to {new_ver}...")
    res = subprocess.run(["nix", "build", f".#{attr}", "--no-link"], capture_output=True, text=True)
    out = res.stderr + res.stdout
    hashes = re.findall(r'got:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    if not hashes: hashes = re.findall(r'actual:\s+(sha256-[a-zA-Z0-9+/=]+)', out)
    
    if hashes:
        new_hash = hashes[0]
        print(f"Got new hash {new_hash} for {pkg}")
        with open(nix_file, 'r') as f: content = f.read()
        src_match = re.search(r'(src\s*=\s*(?:pkgs\.)?fetch(?:FromGitHub|FromGitLab|git)\s*\{)(.+?)(\n\s*\})', content, re.DOTALL)
        if src_match:
            inner = src_match.group(2)
            inner = re.sub(r'hash\s*=\s*""', f'hash = "{new_hash}"', inner)
            content = content[:src_match.start()] + src_match.group(1) + inner + src_match.group(3) + content[src_match.end():]
            with open(nix_file, 'w') as f: f.write(content)
            
        script = subprocess.run(["nix", "build", f".#{attr}.mitmCache.updateScript", "--no-link", "--print-out-paths"], capture_output=True, text=True).stdout.strip()
        if script:
            print(f"Updating deps for {pkg}...")
            subprocess.run([script])
            
print("Done fixing updates")
