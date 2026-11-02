"""Key the PPE tip icons and pack them as transparent WebP."""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(r"C:\Users\dipnk\.cursor\projects\d-Dipankar-MyCodes-AndroidProjects-SLMToolBox-slm-flutter-slm-flutter\assets")
OUT = ROOT / "assets" / "duty_slip" / "world3d"

NAMES = [
    "ppe_gloves",
    "ppe_harness",
    "ppe_boots",
    "ppe_vest",
    "ppe_lock",
    "ppe_rope",
    "ppe_cone",
    "ppe_goggles",
]


def key_magenta(path: Path, dest: Path) -> None:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    rgb = arr[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    magenta = (r > 170) & (b > 80) & (g < 120) & ((r - g) > 80) & ((b - g) > 40)
    alpha = np.where(magenta, 0, 255).astype(np.uint8)
    pink = (r > 140) & (b > 60) & (g < 100) & ((r - g) > 45) & ((b - g) > 25) & (b > r * 0.28)
    fringe = ndimage.binary_dilation(alpha == 0, iterations=2) & pink
    alpha = np.where(fringe, 0, alpha)
    if path.stem == "ppe_goggles":
        solid = alpha > 16
        holes = ndimage.binary_fill_holes(solid) & ~solid
        arr[holes, 0] = 186
        arr[holes, 1] = 214
        arr[holes, 2] = 226
        alpha = np.where(holes, 210, alpha)
    arr[:, :, 3] = alpha
    ys, xs = np.where(alpha > 16)
    if len(xs) == 0:
        raise SystemExit(f"nothing left after key: {path}")
    pad = 8
    x0 = max(0, int(xs.min()) - pad)
    y0 = max(0, int(ys.min()) - pad)
    x1 = min(arr.shape[1], int(xs.max()) + pad + 1)
    y1 = min(arr.shape[0], int(ys.max()) + pad + 1)
    cropped = Image.fromarray(arr[y0:y1, x0:x1])
    cropped.thumbnail((512, 512), Image.Resampling.LANCZOS)
    dest.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(dest, "WEBP", quality=82, method=6)
    clear = float((alpha == 0).mean())
    print(dest.name, cropped.size, f"clear {clear:.2f}", "corner", tuple(int(v) for v in rgb[4, 4]))


def main() -> None:
    for name in NAMES:
        src = SRC / f"{name}.jpg"
        if not src.exists():
            src = SRC / f"{name}.png"
        key_magenta(src, OUT / f"prop_{name}.webp")


if __name__ == "__main__":
    main()
