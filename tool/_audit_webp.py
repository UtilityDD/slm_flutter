"""Locate leftover cream and shadow blobs on the cut dress webps."""
from __future__ import annotations

import numpy as np
from PIL import Image
from pathlib import Path
from scipy import ndimage

OUT = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")
CREAM = np.array([253, 242, 232], dtype=np.float32)


def blobs(mask: np.ndarray, min_n: int = 80) -> list[tuple]:
    lab, n = ndimage.label(mask)
    rows = []
    for i in range(1, n + 1):
        ys, xs = np.where(lab == i)
        if len(ys) < min_n:
            continue
        rows.append((len(ys), int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())))
    rows.sort(reverse=True)
    return rows[:4]


def main() -> None:
    for p in sorted(OUT.glob("*.webp")):
        a = np.array(Image.open(p).convert("RGBA"))
        rgb = a[..., :3].astype(np.float32)
        al = a[..., 3]
        opaque = al > 200
        dist = np.linalg.norm(rgb - CREAM, axis=-1)
        cream = opaque & (dist < 14)
        # Soft shadow: dark warm gray, still fairly close to cream, sitting in a thin band.
        delta = CREAM - rgb
        shadow = opaque & (delta.min(-1) > 12) & (delta.max(-1) < 80) & (dist < 48) & (dist > 14)
        if cream.sum() < 80 and shadow.sum() < 400:
            continue
        print(
            f"{p.name:28} cream {int(cream.sum()):6} {blobs(cream, 60)}  shadow {int(shadow.sum()):6} {blobs(shadow, 200)}"
        )


if __name__ == "__main__":
    main()
