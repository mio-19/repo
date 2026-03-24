import hashlib
import io
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

import cairosvg
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
xml_element_re = re.compile(r"^(\s*)E: ([^ ]+)")
xml_attr_re = re.compile(r"^(\s*)A: (?:[^:]+:)?([^(:]+)\([^)]+\)=(.*)$")


def run(*cmd):
    return subprocess.check_output(cmd, text=True)


def strip_raw_suffix(value):
    return re.sub(r'\s+\(Raw: ".*"\)$', "", value).strip()


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] == '"':
        return value[1:-1]
    return value


def parse_number(value):
    if value is None:
        return None
    match = re.match(r"(-?\d+(?:\.\d+)?)", value)
    return float(match.group(1)) if match else None


def parse_resources(apk_path):
    output = run(aapt2, "dump", "resources", str(apk_path))
    resources = {}
    path_to_resource = {}
    current = None
    current_id = None
    for line in output.splitlines():
        match = resource_line_re.match(line)
        if match:
            current = {
                "type": match.group(2),
                "name": match.group(3),
                "files": [],
                "color": None,
            }
            current_id = match.group(1)
            resources[current_id] = current
            continue
        if current is None:
            continue
        match = file_line_re.match(line)
        if match:
            entry = {
                "qualifier": match.group(1),
                "path": match.group(2),
                "kind": match.group(3),
            }
            current["files"].append(entry)
            path_to_resource[entry["path"]] = current_id
            continue
        match = color_line_re.match(line)
        if match:
            current["color"] = match.group(1)
    return resources, path_to_resource


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
        ranked.append((is_raster, score, entry["path"], entry))
    ranked.sort()
    return ranked[-1][3] if ranked else None


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


def parse_xmltree(apk_path, xml_path):
    output = run(aapt2, "dump", "xmltree", "--file", xml_path, str(apk_path))
    root = None
    stack = []
    for line in output.splitlines():
        element_match = xml_element_re.match(line)
        if element_match:
            indent = len(element_match.group(1))
            node = {"tag": element_match.group(2), "attrs": {}, "children": []}
            while stack and stack[-1][0] >= indent:
                stack.pop()
            if stack:
                stack[-1][1]["children"].append(node)
            else:
                root = node
            stack.append((indent, node))
            continue
        attr_match = xml_attr_re.match(line)
        if attr_match and stack:
            name = attr_match.group(2)
            value = unquote(strip_raw_suffix(attr_match.group(3)))
            stack[-1][1]["attrs"][name] = value
    return root


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


def color_to_svg(color):
    red, green, blue, alpha = parse_color(color)
    return f"rgba({red},{green},{blue},{alpha / 255:.6f})"


def resolve_color(value, resources):
    if value is None:
        return None
    if value.startswith("#"):
        return value
    if value.startswith("@0x"):
        resource = resources.get(value[1:])
        if resource is not None:
            return resource.get("color")
    return None


def render_svg(svg, size=512):
    png = cairosvg.svg2png(
        bytestring=svg.encode(),
        output_width=size,
        output_height=size,
    )
    image = Image.open(io.BytesIO(png))
    image.load()
    return image.convert("RGBA")


def render_vector_node(node, resources):
    tag = node["tag"]
    attrs = node["attrs"]
    if tag == "group":
        transforms = []
        pivot_x = parse_number(attrs.get("pivotX")) or 0
        pivot_y = parse_number(attrs.get("pivotY")) or 0
        rotation = parse_number(attrs.get("rotation"))
        scale_x = parse_number(attrs.get("scaleX"))
        scale_y = parse_number(attrs.get("scaleY"))
        translate_x = parse_number(attrs.get("translateX"))
        translate_y = parse_number(attrs.get("translateY"))
        if translate_x or translate_y:
            transforms.append(f"translate({translate_x or 0} {translate_y or 0})")
        if rotation:
            transforms.append(f"translate({pivot_x} {pivot_y})")
            transforms.append(f"rotate({rotation})")
            transforms.append(f"translate({-pivot_x} {-pivot_y})")
        if scale_x is not None or scale_y is not None:
            transforms.append(f"scale({scale_x or 1} {scale_y or 1})")
        content = "".join(render_vector_node(child, resources) for child in node["children"])
        transform_attr = f' transform="{" ".join(transforms)}"' if transforms else ""
        return f"<g{transform_attr}>{content}</g>"
    if tag == "path":
        path_data = attrs.get("pathData")
        if not path_data:
            return ""
        fill_color = resolve_color(attrs.get("fillColor"), resources)
        stroke_color = resolve_color(attrs.get("strokeColor"), resources)
        fill = color_to_svg(fill_color) if fill_color else "none"
        stroke = color_to_svg(stroke_color) if stroke_color else "none"
        fill_rule = ' fill-rule="evenodd"' if attrs.get("fillType") == "evenOdd" else ""
        stroke_width = parse_number(attrs.get("strokeWidth"))
        stroke_attr = f' stroke-width="{stroke_width}"' if stroke_width is not None else ""
        return (
            f'<path d="{escape(path_data)}" fill="{fill}" stroke="{stroke}"'
            f"{stroke_attr}{fill_rule}/>"
        )
    return "".join(render_vector_node(child, resources) for child in node["children"])


def render_vector(node, resources):
    viewport_width = parse_number(node["attrs"].get("viewportWidth")) or 108
    viewport_height = parse_number(node["attrs"].get("viewportHeight")) or 108
    content = "".join(render_vector_node(child, resources) for child in node["children"])
    svg = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {viewport_width} {viewport_height}">'
        f"{content}</svg>"
    )
    return render_svg(svg)


def gradient_direction(angle):
    normalized = int(angle or 0) % 360
    if normalized == 0:
        return ("0%", "100%", "0%", "0%")
    if normalized == 45:
        return ("0%", "100%", "100%", "0%")
    if normalized == 90:
        return ("0%", "0%", "100%", "0%")
    if normalized == 135:
        return ("0%", "0%", "100%", "100%")
    if normalized == 180:
        return ("0%", "0%", "0%", "100%")
    if normalized == 225:
        return ("100%", "0%", "0%", "100%")
    if normalized == 270:
        return ("100%", "0%", "0%", "0%")
    if normalized == 315:
        return ("100%", "100%", "0%", "0%")
    return ("0%", "0%", "100%", "0%")


def shape_svg(node, resources):
    attrs = node["attrs"]
    shape_type = attrs.get("shape", "rectangle")
    solid = None
    gradient = None
    radius = 0
    for child in node["children"]:
        if child["tag"] == "solid":
            solid = resolve_color(child["attrs"].get("color"), resources)
        elif child["tag"] == "gradient":
            start_color = resolve_color(child["attrs"].get("startColor"), resources)
            end_color = resolve_color(child["attrs"].get("endColor"), resources)
            if start_color and end_color:
                gradient = (
                    start_color,
                    end_color,
                    gradient_direction(parse_number(child["attrs"].get("angle"))),
                )
        elif child["tag"] == "corners":
            radius = parse_number(child["attrs"].get("radius")) or 0

    if gradient is not None:
        start_color, end_color, (x1, y1, x2, y2) = gradient
        fill = (
            "<defs><linearGradient id=\"grad\" "
            f'x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">'
            f'<stop offset="0%" stop-color="{color_to_svg(start_color)}"/>'
            f'<stop offset="100%" stop-color="{color_to_svg(end_color)}"/>'
            "</linearGradient></defs>"
        )
        fill_value = "url(#grad)"
    else:
        fill = ""
        fill_value = color_to_svg(solid or "#00000000")

    if shape_type == "oval":
        body = f'<ellipse cx="54" cy="54" rx="54" ry="54" fill="{fill_value}"/>'
    else:
        body = f'<rect x="0" y="0" width="108" height="108" rx="{radius}" ry="{radius}" fill="{fill_value}"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108">{fill}{body}</svg>'


def render_shape(node, resources):
    return render_svg(shape_svg(node, resources))


def composite_image(base, layer):
    if layer is None:
        return base
    if layer.size != base.size:
        layer = layer.resize(base.size, Image.Resampling.LANCZOS)
    base.alpha_composite(layer)
    return base


def render_drawable(apk_path, zf, resources, path_to_resource, ref, seen=None):
    if ref is None:
        return None
    if seen is None:
        seen = set()
    if ref in seen:
        return None
    seen.add(ref)

    if ref.startswith("#"):
        return Image.new("RGBA", (512, 512), parse_color(ref))

    if ref.startswith("@0x"):
        resource_id = ref[1:]
    elif ref.startswith("@"):
        return None
    else:
        if ref.lower().endswith((".png", ".webp", ".jpg", ".jpeg")):
            return load_image_from_apk(zf, ref)
        resource_id = path_to_resource.get(ref)
        if resource_id is None:
            node = parse_xmltree(apk_path, ref)
            return render_xml_node(apk_path, zf, resources, path_to_resource, node, seen)

    resource = resources.get(resource_id)
    if resource is None:
        return None

    if resource["color"] is not None:
        return Image.new("RGBA", (512, 512), parse_color(resource["color"]))

    best_file = choose_best_file(resource["files"])
    if best_file is None:
        return None

    path = best_file["path"]
    if path.lower().endswith((".png", ".webp", ".jpg", ".jpeg")):
        return load_image_from_apk(zf, path)

    node = parse_xmltree(apk_path, path)
    return render_xml_node(apk_path, zf, resources, path_to_resource, node, seen)


def render_selector(apk_path, zf, resources, path_to_resource, node, seen):
    for item in node["children"]:
        drawable = item["attrs"].get("drawable")
        if drawable:
            rendered = render_drawable(apk_path, zf, resources, path_to_resource, drawable, seen)
            if rendered is not None:
                return rendered
        for child in item["children"]:
            rendered = render_xml_node(apk_path, zf, resources, path_to_resource, child, seen)
            if rendered is not None:
                return rendered
    return None


def render_layer_list(apk_path, zf, resources, path_to_resource, node, seen):
    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    rendered_any = False
    for item in node["children"]:
        drawable = item["attrs"].get("drawable")
        layer = render_drawable(apk_path, zf, resources, path_to_resource, drawable, seen) if drawable else None
        if layer is None:
            for child in item["children"]:
                layer = render_xml_node(apk_path, zf, resources, path_to_resource, child, seen)
                if layer is not None:
                    break
        if layer is not None:
            rendered_any = True
            composite_image(canvas, layer)
    return canvas if rendered_any else None


def render_adaptive_icon(apk_path, zf, resources, path_to_resource, node, seen):
    canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    for tag in ("background", "foreground"):
        for child in node["children"]:
            if child["tag"] != tag:
                continue
            drawable = child["attrs"].get("drawable")
            layer = render_drawable(apk_path, zf, resources, path_to_resource, drawable, seen) if drawable else None
            if layer is None:
                for grandchild in child["children"]:
                    layer = render_xml_node(apk_path, zf, resources, path_to_resource, grandchild, seen)
                    if layer is not None:
                        break
            if layer is not None:
                composite_image(canvas, layer)
    return canvas


def render_xml_node(apk_path, zf, resources, path_to_resource, node, seen):
    if node is None:
        return None
    tag = node["tag"]
    if tag == "adaptive-icon":
        return render_adaptive_icon(apk_path, zf, resources, path_to_resource, node, seen)
    if tag == "vector":
        return render_vector(node, resources)
    if tag == "shape":
        return render_shape(node, resources)
    if tag == "selector":
        return render_selector(apk_path, zf, resources, path_to_resource, node, seen)
    if tag == "layer-list":
        return render_layer_list(apk_path, zf, resources, path_to_resource, node, seen)
    return None


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
    resources, path_to_resource = parse_resources(apk_path)
    with zipfile.ZipFile(apk_path) as zf:
        image = render_drawable(apk_path, zf, resources, path_to_resource, icon_path)
        if image is None:
            background_id, foreground_id = parse_adaptive_layers(apk_path, icon_path)
            if background_id or foreground_id:
                canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
                if background_id:
                    background = render_drawable(apk_path, zf, resources, path_to_resource, f"@{background_id}")
                    if background is not None:
                        composite_image(canvas, background)
                if foreground_id:
                    foreground = render_drawable(apk_path, zf, resources, path_to_resource, f"@{foreground_id}")
                    if foreground is not None:
                        composite_image(canvas, foreground)
                image = canvas
        return image


def parse_adaptive_layers(apk_path, xml_path):
    xmltree = run(aapt2, "dump", "xmltree", "--file", xml_path, str(apk_path))
    ids = [match.group(1) for match in xml_id_re.finditer(xmltree)]
    if len(ids) < 2:
        return None, None
    return ids[0], ids[1]


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
