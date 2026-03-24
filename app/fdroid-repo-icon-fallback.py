import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

workdir = Path(sys.argv[1])
aapt = sys.argv[2]
aapt2 = sys.argv[3]
font_path = sys.argv[4]
repo_dir = workdir / "repo"
index_v1_path = repo_dir / "index-v1.json"
index_v2_path = repo_dir / "index-v2.json"
entry_path = repo_dir / "entry.json"

with index_v1_path.open() as f:
    index_v1 = json.load(f)
with index_v2_path.open() as f:
    index_v2 = json.load(f)

densities = [120, 160, 240, 320, 480, 640]
resource_line_re = re.compile(r"\s*resource (0x[0-9a-f]+) ([^/]+)/(.+)")
file_line_re = re.compile(r"\s+\(([^)]*)\) \(file\) ([^ ]+) type=([A-Z]+)")
color_line_re = re.compile(r"\s+\(\) (#[0-9a-fA-F]{8})")
xml_id_re = re.compile(r"drawable\(0x[0-9a-f]+\)=@(0x[0-9a-f]+)")


def run(*cmd):
    return subprocess.check_output(cmd, text=True)


def parse_resources(apk_path):
    output = run(aapt2, "dump", "resources", str(apk_path))
    resources = {}
    current = None
    for line in output.splitlines():
        match = resource_line_re.match(line)
        if match:
            current = {
                "type": match.group(2),
                "name": match.group(3),
                "files": [],
                "color": None,
            }
            resources[match.group(1)] = current
            continue
        if current is None:
            continue
        match = file_line_re.match(line)
        if match:
            current["files"].append(
                {
                    "qualifier": match.group(1),
                    "path": match.group(2),
                    "kind": match.group(3),
                }
            )
            continue
        match = color_line_re.match(line)
        if match:
            current["color"] = match.group(1)
    return resources


def choose_best_file(files):
    density_map = {
        "ldpi": 120,
        "mdpi": 160,
        "hdpi": 240,
        "xhdpi": 320,
        "xxhdpi": 480,
        "xxxhdpi": 640,
    }
    ranked = []
    for entry in files:
        qualifier = entry["qualifier"]
        score = -1
        for token, density in density_map.items():
            if token in qualifier:
                score = density
                break
        is_raster = entry["path"].lower().endswith((".png", ".webp", ".jpg", ".jpeg"))
        ranked.append((is_raster, score, entry["path"]))
    ranked.sort()
    return ranked[-1][2] if ranked else None


def parse_icon_path(apk_path):
    badging = run(aapt, "dump", "badging", str(apk_path))
    candidates = []
    fallback = None
    for line in badging.splitlines():
        match = re.match(r"application-icon-(\d+):'([^']+)'", line)
        if match:
            density = int(match.group(1))
            if density < 65000:
                candidates.append((density, match.group(2)))
            continue
        match = re.match(r"application: .* icon='([^']+)'", line)
        if match:
            fallback = match.group(1)
    if candidates:
        candidates.sort()
        return candidates[-1][1]
    return fallback


def parse_adaptive_layers(apk_path, xml_path):
    xmltree = run(aapt2, "dump", "xmltree", "--file", xml_path, str(apk_path))
    ids = [match.group(1) for match in xml_id_re.finditer(xmltree)]
    if len(ids) < 2:
        return None, None
    return ids[0], ids[1]


def load_image_from_apk(zf, inner_path):
    if not inner_path.lower().endswith((".png", ".webp", ".jpg", ".jpeg")):
        return None
    with zf.open(inner_path) as src:
        image = Image.open(src)
        image.load()
        return image.convert("RGBA")


def parse_color(color):
    color = color.lstrip("#")
    if len(color) == 6:
        color = f"ff{color}"
    if len(color) != 8:
        raise ValueError(f"unsupported color format: {color}")
    alpha, red, green, blue = [int(color[i : i + 2], 16) for i in range(0, 8, 2)]
    return (red, green, blue, alpha)


def make_placeholder_icon(label, seed):
    digest = hashlib.sha256(seed.encode()).digest()
    background = (digest[0], digest[1], digest[2], 255)
    text = next((char for char in label.upper() if char.isalnum()), "?")
    image = Image.new("RGBA", (512, 512), background)
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype(font_path, 280)
    bbox = draw.textbbox((0, 0), text, font=font)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    draw.text(
        ((512 - width) / 2 - bbox[0], (512 - height) / 2 - bbox[1]),
        text,
        fill=(255, 255, 255, 255),
        font=font,
    )
    return image


def build_icon(apk_path):
    icon_path = parse_icon_path(apk_path)
    if icon_path is None:
        return None
    resources = parse_resources(apk_path)
    with zipfile.ZipFile(apk_path) as zf:
        if icon_path.lower().endswith((".png", ".webp", ".jpg", ".jpeg")):
            return load_image_from_apk(zf, icon_path)

        background_id, foreground_id = parse_adaptive_layers(apk_path, icon_path)
        if not background_id or not foreground_id:
            return None

        background = resources.get(background_id)
        foreground = resources.get(foreground_id)
        if foreground is None:
            return None

        canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        if background is not None:
            if background["color"] is not None:
                canvas = Image.new("RGBA", (512, 512), parse_color(background["color"]))
            elif background["files"]:
                background_path = choose_best_file(background["files"])
                if background_path is not None:
                    background_image = load_image_from_apk(zf, background_path)
                    if background_image is not None:
                        background_image = background_image.resize((512, 512), Image.Resampling.LANCZOS)
                        canvas.alpha_composite(background_image)

        foreground_path = choose_best_file(foreground["files"])
        if foreground_path is None:
            return None
        foreground_image = load_image_from_apk(zf, foreground_path)
        if foreground_image is None:
            return None
        foreground_image = foreground_image.resize((512, 512), Image.Resampling.LANCZOS)
        canvas.alpha_composite(foreground_image)
        return canvas


def ensure_icon(pkg, version_code, apk_rel_path, label):
    icon_name = f"{pkg}.{version_code}.png"
    base_icon_path = repo_dir / "icons" / icon_name
    if base_icon_path.exists():
        digest = hashlib.sha256(base_icon_path.read_bytes()).hexdigest()
        return icon_name, digest, base_icon_path.stat().st_size

    image = build_icon(repo_dir / apk_rel_path)
    if image is None:
        image = make_placeholder_icon(label, pkg)

    (repo_dir / "icons").mkdir(parents=True, exist_ok=True)
    image.save(base_icon_path)
    for density in densities:
        target_dir = repo_dir / f"icons-{density}"
        target_dir.mkdir(parents=True, exist_ok=True)
        resized = image.resize((density, density), Image.Resampling.LANCZOS)
        resized.save(target_dir / icon_name)

    digest = hashlib.sha256(base_icon_path.read_bytes()).hexdigest()
    return icon_name, digest, base_icon_path.stat().st_size


for app in index_v1.get("apps", []):
    pkg = app.get("packageName")
    if not pkg or app.get("icon"):
        continue
    pkg_entry = index_v2["packages"].get(pkg)
    if not pkg_entry:
        continue
    versions = pkg_entry.get("versions", {})
    if not versions:
        continue
    first_version = next(iter(versions.values()))
    apk_rel_path = first_version["file"]["name"].lstrip("/")
    version_code = first_version["manifest"]["versionCode"]
    name_map = pkg_entry["metadata"].get("name", {})
    label = name_map.get("en-US") or app.get("localized", {}).get("en-US", {}).get("name") or pkg
    icon_info = ensure_icon(pkg, version_code, apk_rel_path, label)
    if icon_info is None:
        continue
    icon_name, digest, size = icon_info
    app["icon"] = icon_name
    pkg_entry["metadata"]["icon"] = {
        "en-US": {
            "name": f"/icons/{icon_name}",
            "sha256": digest,
            "size": size,
        }
    }

with index_v1_path.open("w") as f:
    json.dump(index_v1, f, indent=2, ensure_ascii=False)
    f.write("\n")
with index_v2_path.open("w") as f:
    json.dump(index_v2, f, indent=2, ensure_ascii=False)
    f.write("\n")

if entry_path.exists():
    with entry_path.open() as f:
        entry = json.load(f)
    entry["index"]["sha256"] = hashlib.sha256(index_v2_path.read_bytes()).hexdigest()
    entry["index"]["size"] = index_v2_path.stat().st_size
    entry["index"]["numPackages"] = len(index_v2["packages"])
    with entry_path.open("w") as f:
        json.dump(entry, f, indent=2, ensure_ascii=False)
        f.write("\n")
