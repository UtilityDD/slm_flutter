"""Pack the Phase 6.5 depth plates. Near frames stay full-size with a clear centre."""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SRC = Path(r"C:\Users\dipnk\.cursor\projects\d-Dipankar-MyCodes-AndroidProjects-SLMToolBox-slm-flutter-slm-flutter\assets")
OUT = Path(__file__).resolve().parents[2] / "assets" / "duty_slip" / "world3d"

OPAQUE = {
    "layer_sky_a.jpg": ("depth_sky_a.webp", 900),
    "layer_sky_b.jpg": ("depth_sky_b.webp", 900),
    "layer_ridge_a.jpg": ("depth_ridge_a.webp", 840),
    "layer_ridge_b.jpg": ("depth_ridge_b.webp", 840),
    "layer_ridge_c.jpg": ("depth_ridge_c.webp", 840),
    "layer_mid_river.jpg": ("depth_mid_river.webp", 960),
    "layer_mid_falls.jpg": ("depth_mid_falls.webp", 960),
    "layer_mid_forest.jpg": ("depth_mid_forest.webp", 960),
}


def pack_opaque(src: Path, dest: Path, width: int) -> None:
    im = Image.open(src).convert("RGB")
    im.thumbnail((width, width * 3), Image.Resampling.LANCZOS)
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, "WEBP", quality=76, method=6)
    print(dest.name, im.size)


def key_frame(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    arr = np.array(im)
    rgb = arr[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    magenta = (g < 90) & (r > 130) & (b > 45) & ((r - g) > 60) & ((b - g) > 15)
    alpha = np.where(magenta, 0, 255).astype(np.uint8)
    pink = (r > 140) & (b > 40) & (g < 120) & ((r - g) > 40)
    near = ndimage.binary_dilation(alpha == 0, iterations=1)
    alpha = np.where(near & pink, 0, alpha)
    arr[:, :, 3] = alpha
    out = Image.fromarray(arr)
    out.thumbnail((900, 1600), Image.Resampling.LANCZOS)
    out.save(dest, "WEBP", quality=78, method=6)
    print(dest.name, out.size, "clear", int((alpha == 0).mean() * 100))


def main() -> None:
    for src, (name, width) in OPAQUE.items():
        pack_opaque(SRC / src, OUT / name, width)
    key_frame(SRC / "layer_near_a.jpg", OUT / "depth_near_a.webp")
    key_frame(SRC / "layer_near_b.jpg", OUT / "depth_near_b.webp")


if __name__ == "__main__":
    main()
