#!/usr/bin/env python3
import os
import re
import urllib.request
import urllib.error
import json
import configparser
import subprocess

def get_nvfetcher_managed():
    managed = set()
    if os.path.exists('nvfetcher.toml'):
        try:
            config = configparser.ConfigParser()
            config.read('nvfetcher.toml')
            for section in config.sections():
                managed.add(section)
        except Exception as e:
            pass
            
    if os.path.exists('_sources/generated.json'):
        try:
            with open('_sources/generated.json') as f:
                data = json.load(f)
                for k in data.keys():
                    managed.add(k)
        except:
            pass
    return managed

def get_latest_github_release(owner, repo):
    try:
        req = urllib.request.Request(f"https://api.github.com/repos/{owner}/{repo}/releases/latest")
        if 'GITHUB_TOKEN' in os.environ:
            req.add_header('Authorization', f"token {os.environ['GITHUB_TOKEN']}")
        with urllib.request.urlopen(req, timeout=5) as response:
            data = json.loads(response.read().decode())
            return data.get('tag_name')
    except Exception:
        pass
    return None

def get_latest_github_tag_by_date(owner, repo, current_rev=None):
    try:
        req = urllib.request.Request(f"https://github.com/{owner}/{repo}/tags.atom")
        with urllib.request.urlopen(req, timeout=5) as response:
            content = response.read().decode()
            tags = re.findall(r'href="[^"]+/releases/tag/([^"]+)"', content)
            
            if current_rev:
                curr_norm = current_rev.lstrip('vV')
                if curr_norm and curr_norm[0].isdigit():
                    tags = [t for t in tags if re.match(r'^[vV]?\d', t)]
                    if '.' in curr_norm:
                        tags = [t for t in tags if '.' in t or t.lstrip('vV').isdigit()]
                        
            if tags:
                return tags[0]
    except Exception:
        pass
    return None

def version_key(v):
    v = v.lstrip('vV')
    parts = re.findall(r'\d+|\.|[^\d.]+', v)
    res = []
    for p in parts:
        if p.isdigit():
            res.append((2, int(p)))
        elif p == '.':
            res.append((1, p))
        else:
            res.append((0, p))
    res.append((0.5, ''))
    return res

def get_latest_git_tag_url(url, current_rev=None):
    try:
        env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
        output = subprocess.check_output(["git", "ls-remote", "--tags", url], stderr=subprocess.DEVNULL, env=env).decode()
        
        tags = []
        for line in output.splitlines():
            if not line.strip(): continue
            sha, ref = line.split()
            tag = ref.replace("refs/tags/", "")
            if tag.endswith('^{}'):
                tag = tag[:-3]
            tags.append(tag)
            
        tags = list(set(tags))
        
        # Filter garbage tags
        if current_rev:
            curr_norm = current_rev.lstrip('vV')
            if curr_norm and curr_norm[0].isdigit():
                # Must start with digit
                tags = [t for t in tags if re.match(r'^[vV]?\d', t)]
                # If current has dot, tag must have dot OR be just digits
                if '.' in curr_norm:
                    tags = [t for t in tags if '.' in t or t.lstrip('vV').isdigit()]
                
        if not tags:
            return None
            
        tags.sort(key=version_key, reverse=True)
        return tags[0]
    except Exception:
        pass
    return None

def get_latest_git_commit_url(url):
    try:
        env = dict(os.environ, GIT_TERMINAL_PROMPT="0")
        output = subprocess.check_output(["git", "ls-remote", url, "HEAD"], stderr=subprocess.DEVNULL, env=env).decode()
        if output:
            return output.split()[0]
    except Exception:
        pass
    return None

def resolve_version(rev, content):
    vars = {}
    for k, v in re.findall(r'([a-zA-Z0-9_-]+)\s*=\s*"([^"]+)"', content):
        if k not in vars:
            vars[k] = v
    
    if rev in vars:
        return vars[rev]
    if rev == 'version' or rev.endswith('.version'):
        return vars.get('version', rev)

    if '${' not in rev:
        return rev
    
    def replacer(match):
        var_name = match.group(1)
        if var_name.endswith('.version'):
            var_name = 'version'
        return vars.get(var_name, match.group(0))
        
    return re.sub(r'\$\{([^}]+)\}', replacer, rev)

def main():
    managed = get_nvfetcher_managed()
    dirs_to_check = ['app/apks', 'app/by-name']
    
    print("Checking for updates...")
    print("-" * 50)
    
    updates_found = False

    for d in dirs_to_check:
        if not os.path.exists(d):
            continue
            
        for pkg in sorted(os.listdir(d)):
            pkg_path = os.path.join(d, pkg)
            if not os.path.isdir(pkg_path) or pkg.startswith('_'):
                continue
                
            if pkg in ['morphe-library-m2', 'morphe-patcher-src', 'npatch', 'revanced-apktool-m2']:
                continue
                
            pkg_nix = os.path.join(pkg_path, 'package.nix')
            if not os.path.exists(pkg_nix):
                pkg_nix = os.path.join(pkg_path, 'default.nix')
            if not os.path.exists(pkg_nix):
                continue
                
            with open(pkg_nix, 'r') as f:
                content = f.read()
                
            if re.search(r'src\s*=\s*sources\.', content) and 'fetchFromGitHub' not in content and 'fetchFromGitLab' not in content and 'fetchgit' not in content:
                continue
                
            git_match = re.search(r'\bsrc\s*=\s*(?:pkgs\.)?fetchFrom(GitHub|GitLab)\s*\{([^}]+)\}', content, re.MULTILINE | re.DOTALL)
            fetchgit_match = re.search(r'\bsrc\s*=\s*(?:pkgs\.)?fetchgit\s*\{([^}]+)\}', content, re.MULTILINE | re.DOTALL)
            
            url = None
            current_rev = None
            name_display = pkg
            domain = None
            owner = None
            repo = None
            
            if git_match:
                forge = git_match.group(1)
                src_block = git_match.group(2)
                
                owner_m = re.search(r'\bowner\s*=\s*"([^"]+)"', src_block)
                repo_m = re.search(r'\brepo\s*=\s*"([^"]+)"', src_block)
                rev_m = re.search(r'\b(?:rev|tag)\s*=\s*(?:"([^"]+)"|([^";\s]+))', src_block)
                domain_m = re.search(r'\bdomain\s*=\s*"([^"]+)"', src_block)
                
                if owner_m and repo_m and rev_m:
                    owner = owner_m.group(1)
                    repo = repo_m.group(1)
                    current_rev = rev_m.group(1) if rev_m.group(1) else rev_m.group(2)
                    current_rev = resolve_version(current_rev, content)
                    
                    domain = "github.com"
                    if forge == "GitLab":
                        domain = domain_m.group(1) if domain_m else "gitlab.com"
                    else:
                        domain = domain_m.group(1) if domain_m else "github.com"
                        
                    url = f"https://{domain}/{owner}/{repo}.git"
                    name_display = f"{pkg} ({owner}/{repo} on {domain})"
            
            elif fetchgit_match:
                src_block = fetchgit_match.group(1)
                url_m = re.search(r'\burl\s*=\s*(?:"([^"]+)"|([^";\s]+))', src_block)
                rev_m = re.search(r'\b(?:rev|tag)\s*=\s*(?:"([^"]+)"|([^";\s]+))', src_block)
                if url_m and rev_m:
                    url = url_m.group(1) if url_m.group(1) else url_m.group(2)
                    current_rev = rev_m.group(1) if rev_m.group(1) else rev_m.group(2)
                    current_rev = resolve_version(current_rev, content)
                    name_display = f"{pkg} (fetchgit {url})"
                    
            if url and current_rev:
                is_commit = bool(re.match(r'^([0-9a-f]{7,8}|[0-9a-f]{40})$', current_rev)) and not current_rev.isdigit()
                
                if is_commit:
                    latest = get_latest_git_commit_url(url)
                    if latest:
                        if not latest.startswith(current_rev):
                            print(f"[UPDATE] {name_display}: {current_rev[:7]} -> {latest[:7]}")
                            updates_found = True
                    else:
                        print(f"[WARN]   {name_display}: Could not fetch latest commit from {url}")
                else:
                    latest = None
                    if pkg != "tailscale" and domain == "github.com" and owner and repo:
                        latest = get_latest_github_release(owner, repo)
                        if not latest:
                            latest = get_latest_github_tag_by_date(owner, repo, current_rev)
                    if not latest:
                        latest = get_latest_git_tag_url(url, current_rev)
                    if latest:
                        if version_key(latest) > version_key(current_rev):
                            print(f"[UPDATE] {name_display}: {current_rev} -> {latest}")
                            updates_found = True
                        elif version_key(latest) < version_key(current_rev):
                            print(f"[DOWNGRADE] {name_display}: {current_rev} -> {latest}")
                    else:
                        print(f"[WARN]   {name_display}: Could not fetch latest version from {url}")

    if not updates_found:
        print("No updates found.")

if __name__ == '__main__':
    main()
