#!/usr/bin/env python3
import os
import re
import urllib.request
import urllib.error
import json
import configparser

def get_nvfetcher_managed():
    managed = set()
    # Read nvfetcher.toml
    if os.path.exists('nvfetcher.toml'):
        try:
            config = configparser.ConfigParser()
            config.read('nvfetcher.toml')
            for section in config.sections():
                managed.add(section)
        except Exception as e:
            pass
            
    # Also parse generated.json if available
    if os.path.exists('_sources/generated.json'):
        try:
            with open('_sources/generated.json') as f:
                data = json.load(f)
                for k in data.keys():
                    managed.add(k)
        except:
            pass
    return managed

import subprocess

def get_latest_github_release(owner, repo):
    # Fallback to tags for git ls-remote
    return get_latest_github_tag(owner, repo)

def get_latest_github_tag(owner, repo):
    url = f"https://github.com/{owner}/{repo}.git"
    try:
        env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
        output = subprocess.check_output(["git", "ls-remote", "--tags", "--sort=-v:refname", url], stderr=subprocess.DEVNULL, env=env).decode()
        for line in output.splitlines():
            if not line.strip(): continue
            sha, ref = line.split()
            tag = ref.replace("refs/tags/", "")
            if not tag.endswith('^{}'):
                return tag
    except Exception:
        pass
    return None

def get_latest_github_commit(owner, repo):
    url = f"https://github.com/{owner}/{repo}.git"
    try:
        # Check HEAD (default branch)
        env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
        output = subprocess.check_output(["git", "ls-remote", url, "HEAD"], stderr=subprocess.DEVNULL, env=env).decode()
        if output:
            return output.split()[0]
    except Exception:
        pass
    return None

def resolve_version(rev, content):
    if '${' not in rev:
        return rev
    # Try to find all variable definitions like name = "value";
    vars = dict(re.findall(r'([a-zA-Z0-9_-]+)\s*=\s*"([^"]+)"', content))
    
    # Try to replace placeholders
    def replacer(match):
        var_name = match.group(1)
        # handle finalAttrs.version or finalAttrs0.version
        if var_name.endswith('.version'):
            var_name = 'version'
        return vars.get(var_name, match.group(0))
        
    return re.sub(r'\$\{([^}]+)\}', replacer, rev)

def main():
    managed = get_nvfetcher_managed()
    apks_dir = 'app/apks'
    
    if not os.path.exists(apks_dir):
        print(f"Error: {apks_dir} not found. Run from repo root.")
        return

    print("Checking for APK updates...")
    print("-" * 50)
    
    updates_found = False

    for pkg in sorted(os.listdir(apks_dir)):
        pkg_path = os.path.join(apks_dir, pkg)
        if not os.path.isdir(pkg_path) or pkg.startswith('_'):
            continue
            
        pkg_nix = os.path.join(pkg_path, 'package.nix')
        if not os.path.exists(pkg_nix):
            pkg_nix = os.path.join(pkg_path, 'default.nix')
        if not os.path.exists(pkg_nix):
            continue
            
        with open(pkg_nix, 'r') as f:
            content = f.read()
            
        # If it explicitly uses a source from nvfetcher for its main src, skip it
        # (Often looks like `src = sources.some_name.src`)
        if re.search(r'src\s*=\s*sources\.', content) and 'fetchFromGitHub' not in content:
            continue
            
        has_update_script = 'passthru.updateScript' in content
        
        # Check for fetchFromGitHub. We look specifically for src = fetchFromGitHub
        github_match = re.search(r'src\s*=\s*(?:pkgs\.)?fetchFromGitHub\s*\{[^}]*owner\s*=\s*"([^"]+)";[^}]*repo\s*=\s*"([^"]+)";[^}]*(?:rev|tag)\s*=\s*"([^"]+)";', content, re.MULTILINE | re.DOTALL)
        
        if github_match:
            owner, repo, current_rev = github_match.groups()
            current_rev = resolve_version(current_rev, content)
            
            is_commit = re.match(r'^[0-9a-f]{40}$', current_rev) is not None
            
            if is_commit:
                latest = get_latest_github_commit(owner, repo)
                if latest:
                    if latest != current_rev:
                        print(f"[UPDATE] {pkg} ({owner}/{repo}): {current_rev[:7]} -> {latest[:7]}")
                        updates_found = True
                else:
                    print(f"[WARN]   {pkg}: Could not fetch latest commit from GitHub API for {owner}/{repo}")
            else:
                latest = get_latest_github_release(owner, repo)
                if not latest:
                    latest = get_latest_github_tag(owner, repo)
                    
                if latest:
                    curr_norm = current_rev.lstrip('v')
                    latest_norm = latest.lstrip('v')
                    if curr_norm != latest_norm and latest_norm not in curr_norm and curr_norm not in latest_norm:
                        print(f"[UPDATE] {pkg} ({owner}/{repo}): {current_rev} -> {latest}")
                        updates_found = True
                else:
                    print(f"[WARN]   {pkg}: Could not fetch latest version from GitHub API for {owner}/{repo}")
        
        elif has_update_script:
            print(f"[MANUAL] {pkg} has an updateScript. Check with `nix-update` or manually.")
            updates_found = True

    if not updates_found:
        print("No updates found.")

if __name__ == '__main__':
    main()
