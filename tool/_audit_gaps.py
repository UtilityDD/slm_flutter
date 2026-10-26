"""Find enclosed cream gaps and soft shadows in dress source art."""
from __future__ import annotations

import numpy as np
from PIL import Image
from pathlib import Path
from scipy import ndimage

SRC = Path(r"C:\Users\rouma\.cursor\projects\c-Dipankar-slm-flutter\assets")
FILES = [
    "dress_base.jpg",
    "dress_all.jpg",
    "dress_shirt.jpg",
    "body_harness.jpg",
    "kit_harness.jpg",
    "kit_shield.jpg",
    "hands_gloves.jpg",
    "head_helmet.jpg",
    "head_gamcha.jpg",
    "tray_harness.jpg",
    "tray_waist_belt.jpg",
    "tray_elec_helmet.jpg",
    "tray_wet_gloves.jpg",
    "tray_normalshoe.jpg",
    "tray_rubber_gloves.jpg",
    "tray_boot.jpg",
    "tray_shirt.jpg",
    "tray_pant.jpg",
    "tray_hole_gloves.jpg",
    "tray_bike_gloves.jpg",
    "tray_faceshield_flat.jpg",
    "tray_fatua.jpg",
    "tray_pajama.jpg",
    "tray_cotton_gloves.jpg",
    "tray_vent_helmet.jpg",
    "tray_gamcha.jpg",
    "tray_road_helmet.jpg",
    "tray_halftee.jpg",
    "tray_poly.jpg",
    "tray_slipper.jpg",
    "tray_halfpant.jpg",
]


def bg_of(rgb: np.ndarray) -> np.ndarray:
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
    return np.median(samples, axis=0)


def enclosed(mask: np.ndarray) -> np.ndarray:
    lab, n = ndimage.label(mask)
    if n == 0:
        return mask
    border = np.zeros(n + 1, dtype=bool)
    border[lab[0, :]] = True
    border[lab[-1, :]] = True
    border[lab[:, 0]] = True
    border[lab[:, -1]] = True
    border[0] = False
    return mask & ~border[lab]


def main() -> None:
    print(f"{'file':28} {'bg':20} {'enc18':8} {'enc28':8} {'shadow':8} top")
    for name in FILES:
        im = np.array(Image.open(SRC / name).convert("RGB")).astype(np.float32)
        bg = bg_of(im)
        dist = np.linalg.norm(im - bg, axis=-1)
        e18 = enclosed(dist < 18)
        e28 = enclosed(dist < 28)
        # Soft shadow: warmer and darker than the cream, still low chroma.
        delta = bg - im
        darker = (delta.min(axis=-1) > 8) & (delta.max(axis=-1) < 70) & (dist < 55) & (dist > 18)
        shadow = enclosed(darker) | (darker & enclosed(dist < 40))
        lab, n = ndimage.label(e28)
        tops = []
        for i in range(1, n + 1):
            m = lab == i
            c = int(m.sum())
            if c < 40:
                continue
            tops.append((c, np.round(im[m].mean(0)).astype(int).tolist(), round(float(dist[m].mean()), 1)))
        tops.sort(reverse=True)
        print(
            f"{name:28} {np.round(bg).astype(int).tolist()!s:20} {int(e18.sum()):8} {int(e28.sum()):8} {int(shadow.sum()):8} {tops[:2]}"
        )


if __name__ == "__main__":
    main()
