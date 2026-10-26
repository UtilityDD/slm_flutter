"""Clear leftover studio cream trapped between the legs on full-body frames."""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

DRESS = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")


def clear(path: Path) -> None:
    im = Image.open(path).convert("RGBA")
    if im.size != (864, 1152):
        return
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3]
    bg = np.median(np.stack([rgb[2, 2], rgb[2, -3], rgb[-3, 2], rgb[-3, -3]]), axis=0)
    dist = np.linalg.norm(rgb - bg, axis=-1)
    hole = (alpha > 12) & (dist < 16)
    if int(hole.sum()) < 80:
        return
    alpha[hole] = 0
    grown = hole.copy()
    grown[1:, :] |= hole[:-1, :]
    grown[:-1, :] |= hole[1:, :]
    grown[:, 1:] |= hole[:, :-1]
    grown[:, :-1] |= hole[:, 1:]
    fringe = (alpha > 12) & (dist < 24) & grown & ~hole
    alpha[fringe] = 0
    arr[..., 3] = alpha
    Image.fromarray(arr).save(path, "WEBP", quality=90, method=4)
    print(f"{path.name} cleared {int(hole.sum())} fringe {int(fringe.sum())}")


def main() -> None:
    for path in sorted(DRESS.glob("*.webp")):
        clear(path)


if __name__ == "__main__":
    main()
