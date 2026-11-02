"""
Layered 2.5D environment for the golden ladder.

Blender is not required to run this. It paints separate transparent WebP
layers (sky, mountains, forest, cliffs, foreground foliage) that Flutter
scrolls at different speeds. A contact sheet is written beside this script
so the stack can be judged before it is wired into the app.

First-party / CC0. No downloaded models.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "duty_slip" / "world3d"
W = 540


def ridge(draw: ImageDraw.ImageDraw, base: int, amplitude: float, color: tuple[int, int, int, int], seed: float, height: int) -> None:
    pts = [(0, height)]
    x = 0
    while x <= W:
        y = base - amplitude * (
            0.62 * math.sin(x * 0.013 + seed)
            + 0.28 * math.sin(x * 0.031 + seed * 1.7)
            + 0.12 * math.sin(x * 0.07 + seed * 0.4)
        )
        pts.append((x, y))
        x += 8
    pts.append((W, height))
    draw.polygon(pts, fill=color)


def tree(base: Image.Image, x: int, y: int, scale: float, rng: random.Random) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    trunk_w = max(3, int(7 * scale))
    trunk_h = int(34 * scale)
    d.rounded_rectangle(
        [x - trunk_w // 2, y - trunk_h, x + trunk_w // 2, y],
        radius=2,
        fill=(74, 48, 28, 230),
    )
    greens = [
        (18, 72, 40, 235),
        (36, 110, 52, 230),
        (78, 150, 62, 210),
    ]
    for i, (dx, dy, r) in enumerate(((-8, -6, 18), (10, -4, 16), (0, -16, 20))):
        rad = int(r * scale)
        cx, cy = x + int(dx * scale), y - trunk_h + int(dy * scale)
        d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=greens[i])
    # Upper-left sun on the crown.
    hr = int(8 * scale)
    hx, hy = x - int(4 * scale), y - trunk_h - int(18 * scale)
    d.ellipse([hx - hr, hy - hr, hx + hr, hy + hr], fill=(186, 214, 120, 150))
    shade = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sw, sh = int(28 * scale), int(8 * scale)
    sd.ellipse([x - sw, y - sh, x + sw, y + sh], fill=(8, 16, 10, 90))
    shade = shade.filter(ImageFilter.GaussianBlur(3))
    base.alpha_composite(shade)
    base.alpha_composite(layer)


def sky(path: Path) -> None:
    h = 960
    img = Image.new("RGBA", (W, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        if t < 0.55:
            u = t / 0.55
            r = int(8 + (42 - 8) * u)
            g = int(22 + (92 - 22) * u)
            b = int(48 + (130 - 48) * u)
        else:
            u = (t - 0.55) / 0.45
            r = int(42 + (214 - 42) * u)
            g = int(92 + (176 - 92) * u)
            b = int(130 + (150 - 130) * u)
        for x in range(W):
            px[x, y] = (r, g, b, 255)
    glow = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([40, 70, 220, 250], fill=(255, 214, 140, 70))
    gd.ellipse([78, 108, 150, 180], fill=(255, 236, 190, 160))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(glow)
    clouds = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(clouds)
    rng = random.Random(3)
    for _ in range(7):
        cx, cy = rng.randint(20, W - 20), rng.randint(40, 280)
        for k in range(3):
            rw, rh = rng.randint(36, 78), rng.randint(14, 28)
            cd.ellipse([cx + k * 18 - rw, cy - rh, cx + k * 18 + rw, cy + rh], fill=(255, 255, 255, 90))
    clouds = clouds.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(clouds)
    img.save(path, "WEBP", quality=90, method=6)


def mountains(path: Path) -> None:
    h = 720
    img = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ridge(d, 250, 70, (120, 150, 176, 210), 0.4, h)
    ridge(d, 340, 88, (62, 104, 86, 230), 1.2, h)
    ridge(d, 460, 96, (28, 72, 48, 245), 2.1, h)
    # Lit snow-free ridge edge on the nearest range.
    edge = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    ed = ImageDraw.Draw(edge)
    pts = []
    x = 0
    while x <= W:
        y = 460 - 96 * (0.62 * math.sin(x * 0.013 + 2.1) + 0.28 * math.sin(x * 0.031 + 3.5) + 0.12 * math.sin(x * 0.07 + 0.8))
        pts.append((x, y))
        x += 8
    ed.line(pts, fill=(168, 196, 130, 180), width=3)
    img.alpha_composite(edge)
    img.save(path, "WEBP", quality=90, method=6)


def forest(path: Path, count: int, scale: float, name_seed: int) -> None:
    h = 980
    img = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    rng = random.Random(name_seed)
    spots = []
    for _ in range(count):
        side = rng.choice((0, 1))
        x = rng.randint(18, int(W * 0.30)) if side == 0 else rng.randint(int(W * 0.70), W - 18)
        y = rng.randint(80, h - 30)
        spots.append((y, x, 0.75 + rng.random() * scale))
    for y, x, sc in sorted(spots):
        tree(img, x, y, sc, rng)
    img.save(path, "WEBP", quality=90, method=6)


def cliffs(path: Path) -> None:
    h = 860
    img = Image.new("RGBA", (W, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Left cliff face, lit on the top edge, open through the centre.
    d.polygon([(0, 120), (118, 80), (150, 210), (96, h), (0, h)], fill=(92, 78, 64, 230))
    d.polygon([(0, 150), (70, 130), (88, h), (0, h)], fill=(58, 48, 40, 200))
    d.line([(0, 120), (118, 80), (150, 210)], fill=(186, 168, 140, 220), width=3)
    d.polygon([(W, 180), (W - 130, 110), (W - 168, 260), (W - 90, h), (W, h)], fill=(78, 96, 70, 220))
    d.line([(W, 180), (W - 130, 110), (W - 168, 260)], fill=(170, 196, 140, 200), width=3)
    # A short waterfall cut into the left cliff.
    d.polygon([(46, 90), (62, 88), (70, 420), (40, 430)], fill=(70, 150, 186, 180))
    d.polygon([(50, 100), (58, 98), (60, 410), (48, 414)], fill=(220, 244, 255, 200))
    img.save(path, "WEBP", quality=90, method=6)


def preview(path: Path) -> None:
    sky_i = Image.open(OUT / "layer_sky.webp").convert("RGBA")
    layers = ["layer_mountains.webp", "layer_forest.webp", "layer_cliffs.webp", "layer_foliage.webp"]
    canvas = sky_i.resize((W, 900))
    for name in layers:
        layer = Image.open(OUT / name).convert("RGBA")
        layer = layer.resize((W, 900))
        canvas.alpha_composite(layer)
    # Slim ladder so the centre stays readable in the contact sheet.
    d = ImageDraw.Draw(canvas)
    cx = W // 2
    span = int(W * 0.38)
    left, right = cx - span // 2, cx + span // 2
    d.rounded_rectangle([left, 40, left + 10, 860], radius=4, fill=(212, 168, 74, 255))
    d.rounded_rectangle([right - 10, 40, right, 860], radius=4, fill=(232, 196, 110, 255))
    for y in range(120, 840, 108):
        d.rounded_rectangle([left, y, right, y + 8], radius=3, fill=(236, 204, 120, 255))
        d.ellipse([cx - 16, y - 14, cx + 16, y + 18], fill=(16, 120, 78, 255))
    canvas.save(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sky(OUT / "layer_sky.webp")
    mountains(OUT / "layer_mountains.webp")
    forest(OUT / "layer_forest.webp", 16, 0.85, 11)
    forest(OUT / "layer_foliage.webp", 8, 1.35, 29)
    cliffs(OUT / "layer_cliffs.webp")
    preview(Path(__file__).resolve().parent / "_world_preview.png")
    print("layers written")


if __name__ == "__main__":
    main()
