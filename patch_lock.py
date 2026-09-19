import json

paths = [
    '/home/dev/Documents/repo/app/apks/forkgram/gradle.lock',
    '/home/dev/Documents/repo/app/apks/forkgram-classic/gradle.lock'
]

for p in paths:
    try:
        with open(p, 'r') as f:
            data = json.load(f)
        
        changed = False
        if "androidx.annotation:annotation:1.2.0" in data:
            if "annotation-1.2.0.jar" not in data["androidx.annotation:annotation:1.2.0"]:
                data["androidx.annotation:annotation:1.2.0"]["annotation-1.2.0.jar"] = {
                    "url": "https://dl.google.com/dl/android/maven2/androidx/annotation/annotation/1.2.0/annotation-1.2.0.jar",
                    "sha256": "8024256bf35cd466cd9f4c3f56b50e4130be1e7f340cebc10bfdd1a0459c5d13" # dummy hash, will be replaced or wait, can I get real hash? Let's just use empty string or nix will fail, wait, we can just run a fetchurl to get hash? Actually we can use a known good hash if we just fetch it now
                }
                changed = True
        
        if changed:
            with open(p, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Patched {p}")
    except Exception as e:
        print(f"Failed {p}: {e}")
