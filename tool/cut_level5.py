"""Key cream backgrounds and paste the orange gloves onto earlier figures."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SRC = Path(r"C:\Users\rouma\.cursor\projects\c-Dipankar-slm-flutter\assets")
OUT = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")


def flood_clear(im: Image.Image, thresh: float = 16) -> Image.Image:
    im = im.convert("RGBA")
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    h, w = rgb.shape[:2]
    samples = np.stack(
        [
            rgb[2, 2],
            rgb[2, w - 3],
            rgb[h - 3, 2],
            rgb[h - 3, w - 3],
            rgb[8, w // 2],
            rgb[h // 2, 8],
        ]
    )
    bgc = np.median(samples, axis=0)
    dist = np.linalg.norm(rgb - bgc, axis=-1)
    mask = dist < thresh
    keep = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        if mask[0, x]:
            q.append((0, x))
        if mask[h - 1, x]:
            q.append((h - 1, x))
    for y in range(h):
        if mask[y, 0]:
            q.append((y, 0))
        if mask[y, w - 1]:
            q.append((y, w - 1))
    while q:
        y, x = q.popleft()
        if y < 0 or y >= h or x < 0 or x >= w or keep[y, x] or not mask[y, x]:
            continue
        keep[y, x] = True
        q.append((y - 1, x))
        q.append((y + 1, x))
        q.append((y, x - 1))
        q.append((y, x + 1))
    alpha = arr[..., 3]
    alpha[keep] = 0
    fringe = ndimage.binary_dilation(keep, iterations=1) & ~keep & (dist < thresh + 6)
    alpha[fringe] = 0
    arr[..., 3] = alpha
    return Image.fromarray(arr)


def fit_canvas(im: Image.Image, size=(864, 1152)) -> Image.Image:
    im = im.convert("RGBA")
    if im.size == size:
        return im
    fitted = Image.new("RGBA", size, (0, 0, 0, 0))
    scale = min(size[0] / im.width, size[1] / im.height)
    nw, nh = int(im.width * scale), int(im.height * scale)
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    fitted.paste(resized, ((size[0] - nw) // 2, (size[1] - nh) // 2), resized)
    return fitted


def bbox(im: Image.Image) -> tuple[int, int, int, int]:
    a = np.array(im)
    ys, xs = np.where(a[..., 3] > 30)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def glove_layer() -> tuple[np.ndarray, np.ndarray]:
    g = np.array(Image.open(OUT / "hands_gloves.webp").convert("RGBA"))
    r = g[..., 0].astype(np.int16)
    gr = g[..., 1].astype(np.int16)
    b = g[..., 2].astype(np.int16)
    al = g[..., 3]
    orange = (al > 180) & (r > 165) & (gr > 50) & (gr < 190) & (b < 95) & (r > gr + 25)
    orange[:500, :] = False
    mask = ndimage.binary_dilation(orange, iterations=2) & (al > 30)
    return g, mask


def paste(base_name: str, dest_name: str, layer: np.ndarray, mask: np.ndarray) -> None:
    base = np.array(Image.open(OUT / base_name).convert("RGBA"))
    if base.shape != layer.shape:
        raise SystemExit(f"shape {base_name} {base.shape}")
    out = base.copy()
    out[mask] = layer[mask]
    Image.fromarray(out).save(OUT / dest_name, "WEBP", quality=90, method=4)
    print("pasted", dest_name, int(mask.sum()))


def crop_tray(src: Path, dest: Path) -> None:
    im = flood_clear(Image.open(src), 22)
    a = np.array(im)
    ys, xs = np.where(a[..., 3] > 20)
    pad = 8
    box = (
        max(0, int(xs.min()) - pad),
        max(0, int(ys.min()) - pad),
        min(im.width, int(xs.max()) + pad),
        min(im.height, int(ys.max()) + pad),
    )
    im.crop(box).save(dest, "WEBP", quality=90, method=4)
    print("tray", dest.name, im.crop(box).size)


def main() -> None:
    for src, dest in [("kit_harness.jpg", "kit_harness.webp"), ("kit_shield.jpg", "kit_shield.webp")]:
        im = flood_clear(Image.open(SRC / src), 16)
        im = fit_canvas(im)
        im.save(OUT / dest, "WEBP", quality=90, method=4)
        print(dest, im.size, bbox(im))
    crop_tray(SRC / "tray_faceshield_flat.jpg", OUT / "tray_faceshield.webp")

    layer, mask = glove_layer()
    pairs = [
        ("body.webp", "gloves_body.webp"),
        ("shirt.webp", "gloves_shirt.webp"),
        ("pant.webp", "gloves_pant.webp"),
        ("boot.webp", "gloves_boot.webp"),
        ("shirt_pant.webp", "gloves_shirt_pant.webp"),
        ("shirt_boot.webp", "gloves_shirt_boot.webp"),
        ("pant_boot.webp", "gloves_pant_boot.webp"),
        ("all.webp", "gloves_all.webp"),
        ("head_gamcha.webp", "gloves_gamcha.webp"),
        ("body_harness.webp", "kit_helmet_gloves.webp"),
        ("kit_harness.webp", "kit_harness_gloves.webp"),
        ("kit_shield.webp", "kit_ready.webp"),
    ]
    for src, dest in pairs:
        paste(src, dest, layer, mask)


if __name__ == "__main__":
    main()
