#!/usr/bin/env python3
"""Generate GrapheneOS bootanimation.zip files from a single SVG logo.

Only the vector artwork (logo.svg) lives in the repository.  The PNG frames and
the zip archives are produced at build time, because bootanimation.zip entries
must be stored (not compressed) and are therefore not worth committing.

The animation mirrors the shape of GrapheneOS' upstream animation:

  part0  dots fade in, assemble into a molecule, then the wordmark fades in
  part1  the molecule and wordmark fade out while the dots start orbiting
  part2  the dots keep orbiting, looping forever until boot completes

Run: generate.py LOGO_SVG OUTPUT_DIRECTORY
"""

import io
import math
import multiprocessing
import os
import random
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

import cairo
from PIL import Image

FPS = 60
PART0_FRAMES = 210
PART1_FRAMES = 84
PART2_FRAMES = 240
CANVAS_SIZES = (1080, 1280, 1344, 1440, 1600)

CYAN = (0.0, 0.88, 1.0)
MAGENTA = (1.0, 0.20, 0.82)
WHITE = (1.0, 1.0, 1.0)


def smoothstep(edge0, edge1, x):
    if edge0 == edge1:
        return float(x >= edge1)
    t = min(1.0, max(0.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def ease(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def circle(ctx, x, y, radius):
    ctx.new_sub_path()
    ctx.arc(x, y, radius, 0.0, 2.0 * math.pi)
    ctx.fill()


def alpha_surface(alpha_image):
    """Convert a Pillow L (alpha) image to a cairo A8 surface."""
    width, height = alpha_image.size
    stride = cairo.ImageSurface.format_stride_for_width(cairo.FORMAT_A8, width)
    data = bytearray(stride * height)
    raw = alpha_image.tobytes()
    for y in range(height):
        data[y * stride : y * stride + width] = raw[y * width : (y + 1) * width]
    surface = cairo.ImageSurface.create_for_data(data, cairo.FORMAT_A8, width, height, stride)
    return surface, data


class BootAnimation:
    def __init__(self, logo_svg, canvas):
        self.canvas = canvas
        self.center_x = canvas / 2.0
        self.center_y = canvas * 0.33
        self.molecule_radius = canvas * 0.15
        self.dot_radius = canvas * 0.020
        self.trim_margin = max(2, round(canvas * 0.004))
        self.halo_colors = {"cyan": CYAN, "magenta": MAGENTA}

        self.logo_width = round(canvas * 0.56)
        logo_png = Path(self._render_svg(logo_svg, self.logo_width))
        logo = Image.open(logo_png).convert("RGBA").copy()
        logo_png.unlink()
        self.logo_height = logo.height
        self.logo_x = (canvas - self.logo_width) // 2
        self.logo_y = round(canvas * 0.63) - self.logo_height // 2

        logo_alpha = logo.getchannel("A")
        self.logo_mask, self._logo_data = alpha_surface(logo_alpha)

        # Six atoms on a hexagon, starting at the top.
        self.base_angle = -math.pi / 2.0
        self.ring = [
            (
                self.center_x + self.molecule_radius * math.cos(self.base_angle + i * math.pi / 3.0),
                self.center_y + self.molecule_radius * math.sin(self.base_angle + i * math.pi / 3.0),
            )
            for i in range(6)
        ]

        rng = random.Random(0x4E474F)  # "NGO"
        self.scatter = []
        for i in range(6):
            angle = self.base_angle + i * math.pi / 3.0 + rng.uniform(-0.8, 0.8)
            radius = canvas * rng.uniform(0.012, 0.040)
            self.scatter.append(
                (
                    self.center_x + radius * math.cos(angle),
                    self.center_y + radius * math.sin(angle),
                )
            )

        self.surface = None
        self.ctx = None

    def _render_svg(self, logo_svg, width):
        handle, name = tempfile.mkstemp(suffix=".png")
        os.close(handle)
        subprocess.run(
            ["rsvg-convert", "-w", str(width), "-o", name, str(logo_svg)],
            check=True,
        )
        return name

    def begin(self):
        if self.surface is None:
            self.surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, self.canvas, self.canvas)
            self.ctx = cairo.Context(self.surface)
        else:
            self.ctx.set_operator(cairo.OPERATOR_CLEAR)
            self.ctx.paint()
            self.ctx.set_operator(cairo.OPERATOR_OVER)
        self.ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        self.ctx.set_line_join(cairo.LINE_JOIN_ROUND)
        return self.ctx

    def crop(self):
        """Trim the frame to its non-transparent content, as upstream does."""
        self.surface.flush()
        pixels = Image.frombuffer(
            "RGBA",
            (self.canvas, self.canvas),
            self.surface.get_data(),
            "raw",
            "BGRA",
            self.surface.get_stride(),
            1,
        )
        bbox = pixels.getchannel("A").getbbox()
        if bbox is None:
            return cairo.ImageSurface(cairo.FORMAT_ARGB32, 1, 1), (1, 1, 0, 0)

        margin = self.trim_margin
        x0 = max(0, bbox[0] - margin)
        y0 = max(0, bbox[1] - margin)
        x1 = min(self.canvas, bbox[2] + margin)
        y1 = min(self.canvas, bbox[3] + margin)
        width, height = x1 - x0, y1 - y0

        cropped = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
        ctx = cairo.Context(cropped)
        ctx.set_source_surface(self.surface, -x0, -y0)
        ctx.paint()
        return cropped, (width, height, x0, y0)

    def draw_bonds(self, ctx, points, alpha):
        if alpha <= 0.0:
            return
        ctx.set_source_rgba(WHITE[0], WHITE[1], WHITE[2], 0.55 * alpha)
        ctx.set_line_width(max(2.0, self.canvas * 0.004))
        for i in range(6):
            x0, y0 = points[i]
            x1, y1 = points[(i + 1) % 6]
            ctx.move_to(x0, y0)
            ctx.line_to(x1, y1)
            ctx.stroke()

            # Short substituent sticks, like the upstream molecule.
            angle = self.base_angle + i * math.pi / 3.0
            length = self.molecule_radius * 0.38
            ctx.move_to(x0, y0)
            ctx.line_to(
                x0 + length * math.cos(angle),
                y0 + length * math.sin(angle),
            )
            ctx.stroke()

    def paint_dot(self, ctx, x, y, radius, halo, alpha, halo_alpha):
        color = self.halo_colors[halo]
        if halo_alpha > 0.0:
            ctx.set_source_rgba(color[0], color[1], color[2], 0.10 * halo_alpha)
            circle(ctx, x, y, radius * 2.4)
            ctx.set_source_rgba(color[0], color[1], color[2], 0.16 * halo_alpha)
            circle(ctx, x, y, radius * 1.6)
        if alpha > 0.0:
            ctx.set_source_rgba(WHITE[0], WHITE[1], WHITE[2], alpha)
            circle(ctx, x, y, radius)

    def draw_atoms(self, ctx, points, alpha, halo_alpha, trail_points=()):
        # Trails first, so the leading atom stays crisp.
        for tx, ty, trail_alpha in trail_points:
            self.paint_dot(
                ctx,
                tx,
                ty,
                self.dot_radius * 0.55,
                "cyan",
                alpha * trail_alpha,
                0.0,
            )
        for i, (x, y) in enumerate(points):
            halo = "cyan" if i % 2 == 0 else "magenta"
            self.paint_dot(ctx, x, y, self.dot_radius, halo, alpha, halo_alpha)

    def draw_wordmark(self, ctx, alpha, shine_progress=None, shine_alpha=0.0):
        if alpha <= 0.0:
            return
        ctx.set_source_rgba(WHITE[0], WHITE[1], WHITE[2], alpha)
        ctx.mask_surface(self.logo_mask, self.logo_x, self.logo_y)

        if shine_progress is not None and shine_alpha > 0.0:
            start = self.logo_x + (shine_progress * 1.8 - 0.4) * self.logo_width
            shine = cairo.LinearGradient(start, self.logo_y, start + self.logo_width, self.logo_y)
            shine.add_color_stop_rgba(0.00, CYAN[0], CYAN[1], CYAN[2], 0.0)
            shine.add_color_stop_rgba(0.30, CYAN[0], CYAN[1], CYAN[2], 0.45 * shine_alpha)
            shine.add_color_stop_rgba(0.48, WHITE[0], WHITE[1], WHITE[2], 1.0 * shine_alpha)
            shine.add_color_stop_rgba(0.62, MAGENTA[0], MAGENTA[1], MAGENTA[2], 0.55 * shine_alpha)
            shine.add_color_stop_rgba(1.00, MAGENTA[0], MAGENTA[1], MAGENTA[2], 0.0)
            ctx.set_source(shine)
            ctx.mask_surface(self.logo_mask, self.logo_x, self.logo_y)

    def frame_part0(self, index):
        ctx = self.begin()
        t = index / float(PART0_FRAMES)

        points = []
        appear = []
        for i in range(6):
            appear.append(smoothstep(i * 0.010, i * 0.010 + 0.07, t))
            progress = smoothstep(0.10 + i * 0.018, 0.50 + i * 0.035, t)
            sx, sy = self.scatter[i]
            rx, ry = self.ring[i]
            points.append((lerp(sx, rx, ease(progress)), lerp(sy, ry, ease(progress))))

        bond_alpha = smoothstep(0.55, 0.80, t)
        self.draw_bonds(ctx, points, bond_alpha)

        for i, (x, y) in enumerate(points):
            if appear[i] > 0.0:
                halo = "cyan" if i % 2 == 0 else "magenta"
                self.paint_dot(ctx, x, y, self.dot_radius, halo, appear[i], appear[i] * 0.8)

        word_alpha = smoothstep(0.70, 0.88, t)
        shine_progress = smoothstep(0.86, 1.0, t)
        shine_alpha = smoothstep(0.86, 0.90, t) * (1.0 - smoothstep(0.97, 1.0, t))
        self.draw_wordmark(ctx, word_alpha, shine_progress, shine_alpha)

    def frame_part1(self, index):
        ctx = self.begin()
        t = index / float(PART1_FRAMES)

        word_alpha = 1.0 - smoothstep(0.0, 0.45, t)
        self.draw_wordmark(ctx, word_alpha)

        ring_alpha = 1.0 - smoothstep(0.0, 0.35, t)
        self.draw_bonds(ctx, self.ring, ring_alpha)
        self.draw_atoms(
            ctx,
            self.ring,
            ring_alpha,
            ring_alpha * 0.8,
        )

        orbit_alpha = smoothstep(0.08, 0.50, t)
        angle = self.base_angle + math.pi * ease(t)
        points = [
            (
                self.center_x + self.molecule_radius * math.cos(angle + i * math.pi / 3.0),
                self.center_y + self.molecule_radius * math.sin(angle + i * math.pi / 3.0),
            )
            for i in range(6)
        ]
        trails = []
        for i in range(6):
            for delta, strength in ((0.06, 0.35), (0.12, 0.15)):
                a = angle + i * math.pi / 3.0 - delta
                trails.append(
                    (
                        self.center_x + self.molecule_radius * math.cos(a),
                        self.center_y + self.molecule_radius * math.sin(a),
                        strength,
                    )
                )
        self.draw_atoms(ctx, points, orbit_alpha, orbit_alpha * 0.8, trails)

    def frame_part2(self, index):
        ctx = self.begin()
        t = index / float(PART2_FRAMES)

        angle = self.base_angle + math.pi + 2.0 * math.pi * t
        radius = self.molecule_radius * (1.0 + 0.02 * math.sin(4.0 * math.pi * t))
        alpha = 1.0 - 0.15 * (1.0 - math.cos(2.0 * math.pi * t)) / 2.0

        points = [
            (
                self.center_x + radius * math.cos(angle + i * math.pi / 3.0),
                self.center_y + radius * math.sin(angle + i * math.pi / 3.0),
            )
            for i in range(6)
        ]
        trails = []
        for i in range(6):
            for delta, strength in ((0.05, 0.35), (0.10, 0.15)):
                a = angle + i * math.pi / 3.0 - delta
                trails.append(
                    (
                        self.center_x + radius * math.cos(a),
                        self.center_y + radius * math.sin(a),
                        strength,
                    )
                )
        self.draw_atoms(ctx, points, alpha, alpha * 0.85, trails)

    def write_zip(self, out_path):
        def info(name):
            entry = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_STORED
            entry.external_attr = 0o100644 << 16
            return entry

        desc = (
            f"{self.canvas} {self.canvas} {FPS}\n"
            "c 1 0 part0 #000000\n"
            "p 1 0 part1 #000000\n"
            "p 0 0 part2 #000000\n"
        )

        with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_STORED) as archive:
            archive.writestr(info("desc.txt"), desc.encode())
            for part, count, draw in (
                ("part0", PART0_FRAMES, self.frame_part0),
                ("part1", PART1_FRAMES, self.frame_part1),
                ("part2", PART2_FRAMES, self.frame_part2),
            ):
                trim_lines = []
                for index in range(count):
                    draw(index)
                    cropped, (width, height, x, y) = self.crop()
                    buffer = io.BytesIO()
                    cropped.write_to_png(buffer)
                    # A 256-colour PNG keeps the animation as small as the
                    # upstream grayscale frames; the decoder expands it again.
                    image = Image.open(io.BytesIO(buffer.getvalue())).convert("RGBA")
                    palette = image.quantize(
                        colors=256,
                        method=Image.Quantize.FASTOCTREE,
                        dither=Image.Dither.NONE,
                    )
                    encoded = io.BytesIO()
                    palette.save(encoded, format="PNG", optimize=True)
                    archive.writestr(info(f"{part}/{index:05d}.png"), encoded.getvalue())
                    trim_lines.append(f"{width}x{height}+{x}+{y}\n")
                archive.writestr(info(f"{part}/trim.txt"), "".join(trim_lines).encode())
        return out_path


def build_size(job):
    logo_svg, size, out_dir = job
    animation = BootAnimation(Path(logo_svg), size)
    path = Path(out_dir) / f"{size}.zip"
    animation.write_zip(path)
    return path


def main():
    if len(sys.argv) != 3:
        print("usage: generate.py LOGO_SVG OUTPUT_DIRECTORY", file=sys.stderr)
        return 2
    logo_svg = Path(sys.argv[1]).resolve()
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    jobs = [(str(logo_svg), size, str(out_dir)) for size in CANVAS_SIZES]
    configured = int(os.environ.get("NIX_BUILD_CORES", "0") or 0)
    workers = max(1, min(len(jobs), configured or (os.cpu_count() or 1)))
    if workers == 1:
        for job in jobs:
            print(f"wrote {build_size(job)}")
    else:
        with multiprocessing.Pool(workers) as pool:
            for path in pool.imap_unordered(build_size, jobs):
                print(f"wrote {path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
