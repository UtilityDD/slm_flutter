"""Clear leftover studio cream and item drop-shadows from dress art.

White cloth (vest, gamcha, cotton gloves) is yellower than the studio
cream, so a blue-channel guard keeps it. Drop shadows are the wide, short
gray blobs sitting under a shelf item.
"""
from __future__ import annotations

import numpy as np
from PIL import Image
from pathlib import Path
from scipy import ndimage

OUT = Path(r"C:\Dipankar\slm_flutter\assets\duty_slip\dress")
CREAM = np.array([253.0, 242.0, 232.0], dtype=np.float32)

# Light objects. Clearing near-cream pixels would eat the cloth itself.
SKIP_INTERIOR = {
    "tray_fatua.webp",
    "tray_pajama.webp",
    "tray_cotton_gloves.webp",
    "tray_gamcha.webp",
    "tray_vent_helmet.webp",
    "tray_loose.webp",
    "tray_shirt.webp",
    "tray_halftee.webp",
    "tray_poly.webp",
    "tray_normalshoe.webp",
}


def _large(mask: np.ndarray, min_n: int) -> np.ndarray:
    lab, n = ndimage.label(mask)
    keep = np.zeros(mask.shape, dtype=bool)
    for i in range(1, n + 1):
        comp = lab == i
        if int(comp.sum()) >= min_n:
            keep |= comp
    return keep


def gap_mask(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    dist = np.linalg.norm(rgb - CREAM, axis=-1)
    raw = (alpha > 0) & (dist < 10) & (rgb[..., 2] > 226)
    # Tiny hits are highlights on white cloth, not a hole.
    return _large(raw, 60)


def shadow_mask(rgb: np.ndarray, alpha: np.ndarray) -> np.ndarray:
    opaque = alpha > 200
    if not opaque.any():
        return np.zeros(alpha.shape, dtype=bool)
    ys, xs = np.where(opaque)
    y1 = int(ys.max())
    # Only the floor under the item.
    band = np.zeros(alpha.shape, dtype=bool)
    band[max(0, y1 - 90) :, :] = True
    dist = np.linalg.norm(rgb - CREAM, axis=-1)
    chroma = rgb.max(-1) - rgb.min(-1)
    # Shadows sit well off the studio cream. White soles and toes are closer, so they stay.
    soft = opaque & band & (chroma < 42) & (dist > 20) & (dist < 70)
    lab, n = ndimage.label(soft)
    keep = np.zeros(alpha.shape, dtype=bool)
    for i in range(1, n + 1):
        m = lab == i
        c = int(m.sum())
        if c < 400:
            continue
        yy, xx = np.where(m)
        w = int(xx.max() - xx.min())
        h = int(yy.max() - yy.min())
        if w > 180 and w > h * 2.2 and h < 90 and int(yy.max()) > y1 - 45:
            keep |= m
    return keep


def clean(path: Path, *, interiors: bool, shadows: bool) -> tuple[int, int]:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    rgb = arr[..., :3].astype(np.float32)
    alpha = arr[..., 3]
    drop = np.zeros(alpha.shape, dtype=bool)
    if interiors:
        drop |= gap_mask(rgb, alpha)
    if shadows:
        faded = alpha.copy()
        faded[drop] = 0
        shadow = shadow_mask(rgb, faded)
        if shadow.any():
            chroma = rgb.max(-1) - rgb.min(-1)
            dist = np.linalg.norm(rgb - CREAM, axis=-1)
            shadow = ndimage.binary_dilation(shadow, iterations=2) & (alpha > 0) & (chroma < 42) & (dist > 18) & (dist < 70)
        drop |= shadow
    # Pale rim left against a hole. Stay off yellow cloth and boot leather.
    if drop.any():
        fringe = ndimage.binary_dilation(drop, iterations=1) & ~drop
        dist = np.linalg.norm(rgb - CREAM, axis=-1)
        chroma = rgb.max(-1) - rgb.min(-1)
        drop |= fringe & (alpha > 0) & (dist < 12) & (rgb[..., 2] > 228) & (chroma < 28)
    n = int(drop.sum())
    alpha = alpha.copy()
    alpha[drop] = 0
    arr[..., 3] = alpha
    Image.fromarray(arr).save(path, "WEBP", quality=90, method=4)
    return n, int((arr[..., 3] > 0).sum())


def main() -> None:
    for path in sorted(OUT.glob("*.webp")):
        tray = path.name.startswith("tray_")
        if path.name in SKIP_INTERIOR:
            n, _ = clean(path, interiors=False, shadows=True)
        else:
            n, _ = clean(path, interiors=True, shadows=not path.name.startswith("house"))
        if n:
            print(f"{path.name:28} cleared {n}")


if __name__ == "__main__":
    main()
