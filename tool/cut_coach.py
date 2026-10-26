"""Cut the cream fill from the level-1 coach and crop to the character."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\rouma\.cursor\projects\c-Dipankar-slm-flutter\assets")
OUT = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")
NAMES = ("coach_talk", "coach_happy", "coach_oops", "coach_ready", "coach_blink", "coach_glance")


def cut(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    h, w = rgb.shape[:2]
    bgc = np.median(np.stack([rgb[0, 0], rgb[0, -1], rgb[-1, 0], rgb[-1, -1]]), axis=0)
    dist = np.linalg.norm(rgb - bgc, axis=-1)
    mask = dist < 18
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
    fringe = (dist < 26) & ~keep
    # only clear fringe pixels that touch a cleared pixel
    cleared = keep.copy()
    ys, xs = np.where(cleared)
    near = np.zeros_like(cleared)
    near[ys, xs] = True
    # cheap 1px dilate
    grown = cleared.copy()
    grown[1:, :] |= cleared[:-1, :]
    grown[:-1, :] |= cleared[1:, :]
    grown[:, 1:] |= cleared[:, :-1]
    grown[:, :-1] |= cleared[:, 1:]
    alpha[fringe & grown & ~cleared] = 0
    arr[..., 3] = alpha
    ys, xs = np.where(arr[..., 3] > 12)
    pad = 8
    box = arr[max(0, ys.min() - pad) : ys.max() + pad, max(0, xs.min() - pad) : xs.max() + pad]
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(box).save(dest, "WEBP", quality=90, method=4)
    print(dest.name, box.shape)


def main() -> None:
    for name in NAMES:
        src = SRC / f"{name}.jpg"
        if not src.exists():
            src = SRC / f"{name}.png"
        cut(src, OUT / f"{name}.webp")


if __name__ == "__main__":
    main()
