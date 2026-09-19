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
            data["androidx.annotation:annotation:1.2.0"]["annotation-1.2.0.jar"] = {
                "url": "https://dl.google.com/dl/android/maven2/androidx/annotation/annotation/1.2.0/annotation-1.2.0.jar",
                "sha256": "0dha965ykmsp7dmvg1wh4d6g48dszm59wjdy09nnw4ffvlmjcach"
            }
            changed = True
        
        if changed:
            with open(p, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Patched {p}")
    except Exception as e:
        pass
