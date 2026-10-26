"""Cut the cream studio fill from dress-up art. Tight threshold so the white vest stays."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SRC = Path(r"C:\Users\rouma\.cursor\projects\c-Dipankar-slm-flutter\assets")
OUT = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")

MAP = {
    "dress_base.jpg": "body.webp",
    "dress_shirt.jpg": "shirt.webp",
    "dress_pant.jpg": "pant.webp",
    "dress_boot.jpg": "boot.webp",
    "dress_shirt_pant.jpg": "shirt_pant.webp",
    "dress_shirt_boot.jpg": "shirt_boot.webp",
    "dress_pant_boot.jpg": "pant_boot.webp",
    "dress_all.jpg": "all.webp",
    "tray_halfpant.jpg": "tray_halfpant.webp",
    "tray_loose.jpg": "tray_loose.webp",
    "tray_slipper.jpg": "tray_slipper.webp",
    "tray_shirt.jpg": "tray_shirt.webp",
    "tray_pant.jpg": "tray_pant.webp",
    "tray_boot.jpg": "tray_boot.webp",
    "house.jpg": "house.webp",
    "house_bare.jpg": "house_bare.webp",
    "house_boot.jpg": "house_boot.webp",
    "tray_fatua.jpg": "tray_fatua.webp",
}


def cut(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    h, w = rgb.shape[:2]
    samples = np.stack(
        [
            rgb[0, 0],
            rgb[0, -1],
            rgb[-1, 0],
            rgb[-1, -1],
            rgb[4, w // 2],
            rgb[h // 2, 4],
        ]
    )
    bgc = np.median(samples, axis=0)
    dist = np.linalg.norm(rgb - bgc, axis=-1)
    mask = dist < 16
    from collections import deque

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
    fringe = ndimage.binary_dilation(keep, iterations=1) & ~keep & (dist < 22)
    alpha[fringe] = 0
    arr[..., 3] = alpha
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr).save(dest, "WEBP", quality=90, method=4)
    print(f"{dest.name} cleared {int(keep.sum())}")


def main() -> None:
    for src_name, dest_name in MAP.items():
        cut(SRC / src_name, OUT / dest_name)


if __name__ == "__main__":
    main()
