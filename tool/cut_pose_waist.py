"""Key the waist-buckle pose onto the 864x1152 dress canvas."""
from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

SRC = Path(r"C:\Users\rouma\.cursor\projects\c-Dipankar-slm-flutter\assets\pose_waist.jpg")
DEST = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress\pose_waist.webp")


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    tw, th = 864, 1152
    sw, sh = im.size
    scale = max(tw / sw, th / sh)
    nw, nh = round(sw * scale), round(sh * scale)
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    im = im.crop((left, top, left + tw, top + th))
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
    grown = keep.copy()
    grown[1:, :] |= keep[:-1, :]
    grown[:-1, :] |= keep[1:, :]
    grown[:, 1:] |= keep[:, :-1]
    grown[:, :-1] |= keep[:, 1:]
    alpha[(dist < 26) & grown & ~keep] = 0
    arr[..., 3] = alpha
    Image.fromarray(arr).save(DEST, "WEBP", quality=90, method=4)
    print(DEST.name, arr.shape, int((arr[..., 3] == 0).sum()))


if __name__ == "__main__":
    main()
