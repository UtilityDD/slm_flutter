"""Key magenta backgrounds and pack the Phase 6.5 illustrated plates."""

from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[2]
SRC = Path(r"C:\Users\dipnk\.cursor\projects\d-Dipankar-MyCodes-AndroidProjects-SLMToolBox-slm-flutter-slm-flutter\assets")
OUT = ROOT / "assets" / "duty_slip" / "world3d"


def key_magenta(path: Path, dest: Path) -> None:
    im = Image.open(path).convert("RGBA")
    arr = np.array(im)
    rgb = arr[:, :, :3].astype(np.float32)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    dist = np.sqrt((r - 216) ** 2 + (g - 10) ** 2 + (b - 173) ** 2)
    magenta = (dist < 78) | ((r > 170) & (b > 130) & (g < 70) & (r > g + 90) & (b > g + 80))
    alpha = np.where(magenta, 0, 255).astype(np.uint8)
    fringe = (dist < 108) & (g < 90) & (r > g + 70) & (b > g + 50)
    alpha = np.where(fringe, 0, alpha)
    pink = (r > 150) & (b > 90) & (g < 130) & ((r - g) > 40) & ((b - g) > 20)
    near = ndimage.binary_dilation(alpha == 0, iterations=2)
    alpha = np.where(near & pink, 0, alpha)
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
    print(dest.name, cropped.size)


def pack_valley() -> None:
    im = Image.open(SRC / "valley_illustrated_master.jpg").convert("RGB")
    im.thumbnail((1440, 2560), Image.Resampling.LANCZOS)
    plate = OUT / "valley_illustrated.webp"
    im.save(plate, "WEBP", quality=78, method=6)
    sky = im.crop((0, 0, im.width, int(im.height * 0.46)))
    sky.save(OUT / "valley_sky.webp", "WEBP", quality=76, method=6)
    print(plate.name, im.size, "sky", sky.size)


def main() -> None:
    pack_valley()
    props = {
        "prop_chest.jpg": "prop_chest.webp",
        "prop_clock_blank.jpg": "prop_clock.webp",
        "prop_identify.jpg": "prop_identify.webp",
        "prop_books.jpg": "prop_books.webp",
        "prop_tools.jpg": "prop_tools.webp",
        "prop_shield.jpg": "prop_shield.webp",
    }
    for src, dest in props.items():
        key_magenta(SRC / src, OUT / dest)


if __name__ == "__main__":
    main()
