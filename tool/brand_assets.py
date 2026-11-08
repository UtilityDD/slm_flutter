"""Make the app icon and the launch-screen art from the brand logo.

    python -I tool/brand_assets.py .

Source: assets/brand/source/app_icon_512.png (the SmartLineman gear-and-bolt
logo on navy; not bundled in the app). Writes:
  - Android launcher icons: mipmap-*/ic_launcher.png (legacy, square),
    adaptive icon (mipmap-*/ic_launcher_foreground.png + monochrome for
    themed icons, mipmap-anydpi-v26/ic_launcher.xml, values/colors.xml).
  - Android launch screen: drawable-*/splash_logo.png (144 dp) for the
    pre-Android-12 window background, drawable-*/splash_icon.png (288 dp
    canvas, logo inside the 192 dp circle) for the Android 12+ splash.
  - iOS: AppIcon.appiconset (flattened, no alpha) and LaunchImage (144 pt).
  - Flutter: assets/brand/splash_logo.png (the logo the intro overlay shows
    while the video loads, same size as the native one).
The navy background is the logo's own (#0E162B).
"""
import io
import json
import os
import sys

from PIL import Image, ImageFilter

NAVY = (0x0E, 0x16, 0x2B)
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

root = sys.argv[1]
res = os.path.join(root, 'android', 'app', 'src', 'main', 'res')
src = Image.open(os.path.join(root, 'assets', 'brand', 'source', 'app_icon_512.png')).convert('RGB')


def logo_on_clear(img):
    """The logo with the navy background cut away (soft edge)."""
    px = img.load()
    w, h = img.size
    out = Image.new('RGBA', (w, h))
    op = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            d = ((r - NAVY[0]) ** 2 + (g - NAVY[1]) ** 2 + (b - NAVY[2]) ** 2) ** 0.5
            a = max(0, min(255, int((d - 10) * 255 / 30)))
            op[x, y] = (r, g, b, a)
    # Crop to the logo itself, square.
    box = out.getchannel('A').point(lambda v: 255 if v > 40 else 0).getbbox()
    l, t, r_, b_ = box
    side = max(r_ - l, b_ - t)
    cx, cy = (l + r_) // 2, (t + b_) // 2
    return out.crop((cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side))


logo = logo_on_clear(src)


def save(img, *parts):
    """Writes a PNG; transparent art is palette-quantized (the logo has few
    colours) so the files stay small."""
    p = os.path.join(*parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if img.mode == 'RGBA':
        img = img.quantize(colors=96, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    img.save(p, optimize=True)


def canvas(px, logo_frac, bg=None):
    """A px×px image with the logo centred at logo_frac of the side."""
    im = Image.new('RGBA', (px, px), bg + (255,) if bg else (0, 0, 0, 0))
    s = max(1, round(px * logo_frac))
    lg = logo.resize((s, s), Image.LANCZOS)
    im.alpha_composite(lg, ((px - s) // 2, (px - s) // 2))
    return im


# --- Android launcher -----------------------------------------------------------
for name, k in DENSITIES.items():
    d = os.path.join(res, f'mipmap-{name}')
    # Legacy: the logo on its navy square (as the source).
    save(src.resize((round(48 * k), round(48 * k)), Image.LANCZOS), d, 'ic_launcher.png')
    # Adaptive foreground: 108 dp canvas, logo inside the 66 dp safe circle.
    fg = canvas(round(108 * k), 0.62)
    save(fg, d, 'ic_launcher_foreground.png')
    # Themed icon: the yellow strokes (gear, ring, bolt) in white.
    rgb = fg.convert('RGB')
    stroke = Image.eval(rgb.getchannel('R'), lambda v: max(0, min(255, (v - 110) * 3)))
    mono = Image.new('RGBA', fg.size, (255, 255, 255, 0))
    mono.putalpha(Image.composite(stroke, Image.new('L', fg.size, 0), fg.getchannel('A')))
    save(mono, d, 'ic_launcher_monochrome.png')
    # Launch screen art.
    save(canvas(round(144 * k), 1.0), os.path.join(res, f'drawable-{name}'), 'splash_logo.png')
    save(canvas(round(288 * k), 0.50), os.path.join(res, f'drawable-{name}'), 'splash_icon.png')

anydpi = os.path.join(res, 'mipmap-anydpi-v26')
os.makedirs(anydpi, exist_ok=True)
io.open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8', newline='\n').write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background" />\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />\n'
    '</adaptive-icon>\n')
hexc = '#%02X%02X%02X' % NAVY
io.open(os.path.join(res, 'values', 'colors.xml'), 'w', encoding='utf-8', newline='\n').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <!-- The brand navy (the logo\'s own background): icon and launch screen. -->\n'
    f'    <color name="ic_launcher_background">{hexc}</color>\n'
    f'    <color name="splash_background">{hexc}</color>\n'
    '</resources>\n')

# --- iOS ------------------------------------------------------------------------
ios = os.path.join(root, 'ios', 'Runner', 'Assets.xcassets')
if os.path.isdir(ios):
    iconset = os.path.join(ios, 'AppIcon.appiconset')
    for i in json.load(io.open(os.path.join(iconset, 'Contents.json'), encoding='utf-8'))['images']:
        pt = float(i['size'].split('x')[0])
        px = round(pt * int(i['scale'].rstrip('x')))
        src.resize((px, px), Image.LANCZOS).save(os.path.join(iconset, i['filename']), optimize=True)
    launch = os.path.join(ios, 'LaunchImage.imageset')
    for suffix, k in (('', 1), ('@2x', 2), ('@3x', 3)):
        save(canvas(144 * k, 1.0), launch, f'LaunchImage{suffix}.png')

# --- Flutter (the intro overlay's placeholder) ------------------------------------
save(canvas(432, 1.0), root, 'assets', 'brand', 'splash_logo.png')
print('ok', logo.size)
