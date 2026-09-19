import json
import urllib.request
import urllib.error
import hashlib
import base64
import sys

def get_sri_hash(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            data = response.read()
            sha256 = hashlib.sha256(data).digest()
            sri = "sha256-" + base64.b64encode(sha256).decode('utf-8')
            return sri
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise e
    except Exception as e:
        print(f"Error fetching {url}: {e}")
        return None

def process_lock(lockfile_path):
    print(f"Processing {lockfile_path}")
    with open(lockfile_path, 'r') as f:
        lock = json.load(f)
    
    modified = False
    
    for dep, files in lock.items():
        # Check if we only have pom/module
        has_aar_or_jar = any(f.endswith('.aar') or f.endswith('.jar') for f in files.keys())
        if not has_aar_or_jar:
            # dep looks like group:name:version
            parts = dep.split(':')
            if len(parts) == 3:
                group, name, version = parts
                base_url = f"https://dl.google.com/dl/android/maven2/{group.replace('.', '/')}/{name}/{version}/{name}-{version}"
                
                # try aar
                aar_url = f"{base_url}.aar"
                print(f"Checking {aar_url}")
                aar_hash = get_sri_hash(aar_url)
                if aar_hash:
                    lock[dep][f"{name}-{version}.aar"] = {"url": aar_url, "hash": aar_hash}
                    modified = True
                    print(f"Added {name}-{version}.aar")
                    continue
                
                # try jar
                jar_url = f"{base_url}.jar"
                print(f"Checking {jar_url}")
                jar_hash = get_sri_hash(jar_url)
                if jar_hash:
                    lock[dep][f"{name}-{version}.jar"] = {"url": jar_url, "hash": jar_hash}
                    modified = True
                    print(f"Added {name}-{version}.jar")
                    continue
                    
                # try maven central
                base_url_central = f"https://repo.maven.apache.org/maven2/{group.replace('.', '/')}/{name}/{version}/{name}-{version}"
                aar_url_central = f"{base_url_central}.aar"
                print(f"Checking {aar_url_central}")
                aar_hash = get_sri_hash(aar_url_central)
                if aar_hash:
                    lock[dep][f"{name}-{version}.aar"] = {"url": aar_url_central, "hash": aar_hash}
                    modified = True
                    print(f"Added {name}-{version}.aar")
                    continue
                    
                jar_url_central = f"{base_url_central}.jar"
                print(f"Checking {jar_url_central}")
                jar_hash = get_sri_hash(jar_url_central)
                if jar_hash:
                    lock[dep][f"{name}-{version}.jar"] = {"url": jar_url_central, "hash": jar_hash}
                    modified = True
                    print(f"Added {name}-{version}.jar")
                    continue
    
    if modified:
        with open(lockfile_path, 'w') as f:
            json.dump(lock, f, indent=2)
        print("Updated lockfile")
    else:
        print("No updates")

process_lock('app/apks/forkgram/gradle.lock')
process_lock('app/apks/forkgram-classic/gradle.lock')
