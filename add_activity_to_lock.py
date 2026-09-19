import json
import urllib.request
import hashlib
import base64
import sys

def get_sri_hash(url):
    print(f"Fetching {url}")
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        data = response.read()
        sha256 = hashlib.sha256(data).digest()
        sri = "sha256-" + base64.b64encode(sha256).decode('utf-8')
        return sri

def add_file(lockfile_path):
    with open(lockfile_path, 'r') as f:
        lock = json.load(f)
    
    url = "https://dl.google.com/dl/android/maven2/androidx/activity/activity/1.2.0/activity-1.2.0.aar"
    
    if "androidx.activity:activity:1.2.0" in lock:
        if "activity-1.2.0.aar" not in lock["androidx.activity:activity:1.2.0"]:
            sri = get_sri_hash(url)
            lock["androidx.activity:activity:1.2.0"]["activity-1.2.0.aar"] = {
                "url": url,
                "hash": sri
            }
            with open(lockfile_path, 'w') as f:
                json.dump(lock, f, indent=2)
            print(f"Added to {lockfile_path}")
        else:
            print(f"Already exists in {lockfile_path}")
    else:
        print(f"Dependency not found in {lockfile_path}")

add_file('app/apks/forkgram/gradle.lock')
add_file('app/apks/forkgram-classic/gradle.lock')
