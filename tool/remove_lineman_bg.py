"""Remove cream/white studio background from lineman JPGs → transparent WebP."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "assets" / "lineman"
# Generated art uses app cream + near-white studio fill.
TARGETS = np.array(
    [
        [255, 250, 244],  # #FFFAF4
        [255, 255, 255],
        [252, 248, 242],
        [250, 245, 238],
        [248, 244, 237],
        [245, 240, 232],
    ],
    dtype=np.float32,
)


def near_bg(rgb: np.ndarray) -> np.ndarray:
    """rgb: HxWx3 float → bool mask of background-like pixels."""
    dist = np.min(np.linalg.norm(rgb[..., None, :] - TARGETS, axis=-1), axis=-1)
    # Also treat very bright low-chroma pixels as bg.
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    chroma = mx - mn
    bright = (mx > 230) & (chroma < 28)
    return (dist < 38) | bright


def flood_from_edges(mask: np.ndarray) -> np.ndarray:
    h, w = mask.shape
    keep = np.zeros_like(mask, dtype=bool)
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
    return keep


def enclosed_bg(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Large studio-fill pockets the edge flood can't reach (ladder rungs, pole gaps)."""
    from scipy import ndimage

    dist = np.min(np.linalg.norm(rgb[..., None, :] - TARGETS, axis=-1), axis=-1)
    strict = (dist < 18) & ~bg
    labels, count = ndimage.label(strict)
    if count == 0:
        return bg
    sizes = ndimage.sum(strict, labels, index=np.arange(1, count + 1))
    big = np.zeros(count + 1, dtype=bool)
    big[1:] = sizes > 1500
    return bg | big[labels]


def grow_shadow(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Warm, low-chroma floor shadow connected to the background."""
    from scipy import ndimage

    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    shadowish = (mx > 160) & ((mx - mn) < 62) & (r >= g) & (g >= b)
    h = rgb.shape[0]
    shadowish[: int(h * 0.7)] = False
    grown = bg.copy()
    for _ in range(90):
        nxt = grown | (ndimage.binary_dilation(grown) & shadowish)
        if (nxt == grown).all():
            break
        grown = nxt
    return grown


def feather(alpha: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Soft edge: lower alpha for near-bg fringe around removed region."""
    from scipy import ndimage  # optional

    try:
        border = bg ^ ndimage.binary_dilation(bg, iterations=2)
        out = alpha.astype(np.float32)
        out[border] *= 0.35
        return out.astype(np.uint8)
    except Exception:
        return alpha


def process(src: Path) -> Path:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    candidate = near_bg(rgb)
    bg = flood_from_edges(candidate)
    bg = enclosed_bg(rgb, bg)
    bg = grow_shadow(rgb, bg)
    alpha = arr[..., 3].copy()
    alpha[bg] = 0
    # Mild fringe clean: any remaining edge-adjacent near-bg with weak coverage
    fringe = near_bg(rgb) & ~bg
    # Only knock out fringe if very close to already-cleared bg (erode character less)
    ys, xs = np.where(fringe)
    h, w = bg.shape
    for y, x in zip(ys, xs):
        y0, y1 = max(0, y - 1), min(h, y + 2)
        x0, x1 = max(0, x - 1), min(w, x + 2)
        if bg[y0:y1, x0:x1].any() and near_bg(rgb[y : y + 1, x : x + 1])[0, 0]:
            dist = float(np.min(np.linalg.norm(rgb[y, x] - TARGETS, axis=-1)))
            if dist < 22:
                alpha[y, x] = 0
            elif dist < 32:
                alpha[y, x] = min(alpha[y, x], 90)

    alpha = feather(alpha, bg)
    out = arr.copy()
    out[..., 3] = alpha
    dest = src.with_suffix(".webp")
    Image.fromarray(out).save(dest, "WEBP", quality=92, method=6)
    return dest


def main() -> None:
    jpgs = sorted(ROOT.glob("lineman_*.jpg"))
    if not jpgs:
        raise SystemExit(f"No JPGs in {ROOT}")
    for src in jpgs:
        dest = process(src)
        print(f"{src.name} -> {dest.name}")


if __name__ == "__main__":
    main()
