"""Turn generated art into Zero Loss scene-kit assets.

    python tool/cut_scene_assets.py <src_dir> [names...]

bg_* / acc_* -> resized opaque webp
spr_* / prop_* -> background removed (rembg), cropped to content, alpha webp
gear_* (kit icons, 360 max) / cust_* (customer busts, 480 max) -> same cut
Output: assets/zero_loss/scene/<name>.webp
"""

import sys
from pathlib import Path

from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "assets" / "zero_loss" / "scene"
BG_WIDTH = 900
SPRITE_MAX = 720


def cut(img: Image.Image, size: int = SPRITE_MAX) -> Image.Image:
    from rembg import new_session, remove

    global _session
    if "_session" not in globals():
        _session = new_session("isnet-general-use")
    rgba = remove(img, session=_session, post_process_mask=True)
    box = rgba.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
    if box:
        pad = 6
        box = (max(box[0] - pad, 0), max(box[1] - pad, 0), min(box[2] + pad, rgba.width), min(box[3] + pad, rgba.height))
        rgba = rgba.crop(box)
    rgba.thumbnail((size, size), Image.LANCZOS)
    return rgba


def main() -> None:
    src = Path(sys.argv[1])
    wanted = set(sys.argv[2:])
    OUT.mkdir(parents=True, exist_ok=True)
    for f in sorted(src.iterdir()):
        name = f.stem
        if f.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
            continue
        if wanted and name not in wanted:
            continue
        img = Image.open(f).convert("RGB")
        if name.startswith(("bg_", "acc_")):
            h = round(img.height * BG_WIDTH / img.width)
            img.resize((BG_WIDTH, h), Image.LANCZOS).save(OUT / f"{name}.webp", quality=82, method=6)
        elif name.startswith(("spr_", "prop_")):
            cut(img).save(OUT / f"{name}.webp", quality=88, method=6)
        elif name.startswith("gear_"):
            cut(img, 360).save(OUT / f"{name}.webp", quality=88, method=6)
        elif name.startswith("cust_"):
            cut(img, 480).save(OUT / f"{name}.webp", quality=86, method=6)
        else:
            continue
        print(f"{name}: {(OUT / f'{name}.webp').stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
