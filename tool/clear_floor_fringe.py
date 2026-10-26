"""Remove the studio-floor puddle under the boots, and close holes in the white vest.

The floor is cream that never touched the picture edge, so the first key left it.
On a dark page it reads as a jagged white mat. The vest is the same cream, and the
key punched holes through it. Those holes are filled only when the pixels around
them are the vest, so the navy shirt, the gap between the legs, and the skin stay.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

DRESS = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")
FLOOR = np.array([236.0, 220.0, 204.0])


def _fill_vest(rgb: np.ndarray, alpha: np.ndarray) -> int:
    h, w = alpha.shape
    transparent = alpha < 16
    labels, count = ndimage.label(transparent)
    if count == 0:
        return 0
    border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]])))
    border.discard(0)
    filled = 0
    struct = np.ones((3, 3), dtype=bool)
    for idx in range(1, count + 1):
        if idx in border:
            continue
        hole = labels == idx
        ys, xs = np.where(hole)
        if ys.size == 0 or ys.size > 400:
            continue
        cy = float(ys.mean()) / h
        if cy < 0.05 or cy > 0.62:
            continue
        ring = ndimage.binary_dilation(hole, structure=struct) & ~hole & (alpha > 20)
        if int(ring.sum()) < 6:
            continue
        cols = rgb[ring]
        lum = cols.mean(axis=1)
        sat = cols.max(axis=1) - cols.min(axis=1)
        light = (lum > 198) & (sat < 48)
        need = 0.72 if ys.size > 400 else 0.35
        if light.mean() < need:
            continue
        color = np.median(cols[light], axis=0)
        rgb[hole] = color
        alpha[hole] = 255
        filled += int(ys.size)
    return filled


def _clear_floor(rgb: np.ndarray, alpha: np.ndarray) -> int:
    h, w = alpha.shape
    dist = np.linalg.norm(rgb - FLOOR, axis=-1)
    lum = rgb.mean(axis=-1)
    sat = rgb.max(axis=-1) - rgb.min(axis=-1)
    floor = (alpha > 20) & (dist < 58) & (lum > 180) & (sat < 62)
    floor[: int(h * 0.86)] = False
    transparent = alpha < 16
    near = transparent.copy()
    near[1:] |= transparent[:-1]
    near[:-1] |= transparent[1:]
    near[:, 1:] |= transparent[:, :-1]
    near[:, :-1] |= transparent[:, 1:]
    labels, count = ndimage.label(floor)
    clear = np.zeros_like(floor)
    for idx in range(1, count + 1):
        blob = labels == idx
        if not np.any(blob & near):
            continue
        clear |= blob
    alpha[clear] = 0
    return int(clear.sum())


def process(path: Path) -> None:
    image = Image.open(path).convert("RGBA")
    if image.size != (864, 1152):
        return
    arr = np.array(image)
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3]
    vest = _fill_vest(rgb, alpha)
    floor = _clear_floor(rgb, alpha)
    if vest == 0 and floor == 0:
        return
    arr[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    arr[..., 3] = alpha
    Image.fromarray(arr).save(path, "WEBP", quality=90, method=4)
    print(f"{path.name} vest {vest} floor {floor}")


def main() -> None:
    for path in sorted(DRESS.glob("*.webp")):
        process(path)


if __name__ == "__main__":
    main()
