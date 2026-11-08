"""Tray picture for ladder step 3's helmet station (lesson 1.1, কাজ 2).

python -I tool/helmet_art.py .

Writes assets/duty_slip/dress/tray_bike_helmet.webp: a full-face motorcycle
(bike / road) helmet, three-quarter side view facing left, in the same
glossy rendered cut-out style as tray_elec_helmet.webp / tray_vent_helmet.webp
(the other helmets on the shelf). Each part is lit from a height field (a
rounded dome from its outline): diffuse + gloss + a soft environment band,
so the shell reads as moulded plastic, the visor as smoked glass and the trim
as matte rubber. Lesson 1.1: "বাইকের হেলমেট (IS 4151) পথ-দুর্ঘটনায় মাথা বাঁচায়,
কিন্তু লাইনের শক ... জন্য তৈরি নয়—কাজে পরা নিষেধ". No words or brand marks.
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

SS = 3  # supersampling
W, H = 512, 420
LIGHT = np.array([-0.55, -0.62, 0.56])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
VIEW = np.array([0.0, 0.0, 1.0])
HALF = (LIGHT + VIEW) / np.linalg.norm(LIGHT + VIEW)


def bez(p0, p1, p2, p3, n=48):
    t = np.linspace(0, 1, n + 1)[:, None]
    p0, p1, p2, p3 = (np.array(p, float) for p in (p0, p1, p2, p3))
    return ((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3).tolist()


def path(*segs):
    pts = []
    for s in segs:
        pts.extend(bez(*s))
    return [(x * SS, y * SS) for x, y in pts]


def mask(poly, grow=0):
    m = Image.new('L', (W * SS, H * SS), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    if grow > 0:
        m = m.filter(ImageFilter.MaxFilter(grow * 2 + 1))
    elif grow < 0:
        m = m.filter(ImageFilter.MinFilter(-grow * 2 + 1))
    return np.asarray(m, float) / 255.0


def soft(m, r=0.8):
    """Antialiased edge for a hard mask."""
    return ndimage.gaussian_filter(m, r * SS)


def shade(m, radius, base, gloss=0.9, shininess=60, amb=0.34, env=0.0, rim=0.0):
    """Light a part from a rounded height field built from its outline."""
    d = ndimage.distance_transform_edt(m > 0.5) / (radius * SS)
    d = np.clip(d, 0, 1)
    hgt = np.sqrt(1 - (1 - d) ** 2) * radius * SS
    hgt = ndimage.gaussian_filter(hgt, 1.2 * SS)
    gy, gx = np.gradient(hgt)
    n = np.stack([-gx, -gy, np.ones_like(hgt)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    diff = np.clip(n @ LIGHT, 0, 1)
    spec = np.clip(n @ HALF, 0, 1) ** shininess * gloss
    col = np.array(base, float)[None, None, :] / 255.0
    rgb = col * (amb + (1 - amb) * diff[..., None])
    # Environment: a pale sky band reflected across the upper body.
    if env > 0:
        sky = np.clip(1 - np.abs(n[..., 1] + 0.45) * 3.2, 0, 1) * np.clip(n[..., 2] - 0.15, 0, 1)
        rgb = rgb * (1 - env * sky[..., None]) + env * sky[..., None] * np.array([0.93, 0.95, 1.0])
    # Darker toward the silhouette (the shell turns away).
    if rim > 0:
        rgb *= (1 - rim * (1 - n[..., 2]) ** 2)[..., None]
    rgb = rgb + spec[..., None]
    return np.clip(rgb, 0, 1)


class Canvas:
    def __init__(self):
        self.rgb = np.zeros((H * SS, W * SS, 3))
        self.a = np.zeros((H * SS, W * SS))

    def put(self, rgb, alpha):
        alpha = np.clip(alpha, 0, 1)[..., None]
        if np.ndim(rgb) == 1:
            rgb = np.array(rgb, float)[None, None, :] / 255.0
        self.rgb = self.rgb * (1 - alpha) + rgb * alpha
        self.a = self.a + (1 - self.a) * alpha[..., 0]

    def image(self):
        arr = np.dstack([self.rgb, self.a])
        im = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), 'RGBA')
        return im.resize((W, H), Image.LANCZOS)


def line(pts, width, color, alpha=1.0, blur=0.6):
    m = Image.new('L', (W * SS, H * SS), 0)
    ImageDraw.Draw(m).line([(x * SS, y * SS) for x, y in pts], fill=255, width=int(width * SS), joint='curve')
    return np.asarray(m, float) / 255.0, color, alpha, blur


def main(root):
    cv = Canvas()

    # ---- the shell: dome, back, and the chin bar jutting forward ----------------
    shell = path(
        ((96, 380), (66, 350), (56, 300), (66, 246)),          # chin bar front, up to the brow
        ((66, 246), (78, 120), (170, 30), (290, 28)),          # brow to crown
        ((290, 28), (410, 26), (486, 104), (490, 214)),        # crown to back
        ((490, 214), (494, 286), (470, 330), (430, 350)),      # back of the head
        ((430, 350), (350, 374), (220, 388), (128, 384)),      # lower edge
        ((128, 384), (112, 384), (102, 382), (96, 380)),
    )
    sm = mask(shell)
    # The neck opening seen from a little below: the padded liner inside.
    liner = path(
        ((112, 380), (220, 392), (350, 378), (446, 340)),
        ((446, 340), (450, 360), (420, 384), (360, 400)),
        ((360, 400), (290, 414), (190, 414), (140, 402)),
        ((140, 402), (124, 396), (114, 388), (112, 380)),
    )
    lm = mask(liner)
    cv.put((22, 20, 22), soft(mask(liner, grow=2)))
    cv.put(shade(lm, 16, (58, 56, 60), gloss=0.15, shininess=20, amb=0.45, rim=0.4), soft(lm, 0.6))
    for k in range(9):
        x = 160 + k * 30
        cv.put((30, 28, 32), ndimage.gaussian_filter(line([(x, 386 - k * 2.4), (x + 6, 404 - k * 2.6)], 1.6, None)[0], 0.6 * SS) * 0.3 * lm)
    # A thin dark contour around the whole helmet, like the other tray art.
    cv.put((52, 10, 12), soft(mask(shell, grow=2)) * 0.95)
    cv.put(shade(sm, 120, (206, 30, 36), gloss=1.1, shininess=70, amb=0.30, env=0.32, rim=0.55), soft(sm))

    # A white race stripe over the crown, shaded with the shell.
    stripe = path(
        ((214, 44), (300, 30), (400, 52), (456, 126)),
        ((456, 126), (474, 152), (482, 180), (484, 206)),
        ((484, 206), (462, 168), (420, 120), (360, 96)),
        ((360, 96), (300, 74), (250, 70), (214, 44)),
    )
    stm = mask(stripe) * (sm > 0.5)
    cv.put(shade(sm, 120, (236, 236, 240), gloss=1.0, shininess=70, amb=0.42, env=0.25, rim=0.55), soft(stm, 0.6))
    thin = path(
        ((232, 82), (300, 92), (380, 124), (440, 196)),
        ((440, 196), (444, 204), (446, 212), (447, 220)),
        ((447, 220), (420, 172), (360, 136), (300, 116)),
        ((300, 116), (270, 106), (246, 96), (232, 82)),
    )
    cv.put(shade(sm, 120, (34, 34, 40), gloss=0.9, shininess=70, amb=0.5, env=0.2, rim=0.5), soft(mask(thin) * (sm > 0.5), 0.6))

    # ---- the rubber trim along the lower edge ------------------------------------
    trim = path(
        ((92, 372), (100, 382), (114, 386), (128, 386)),
        ((128, 386), (220, 390), (350, 376), (432, 350)),
        ((432, 350), (452, 340), (468, 326), (478, 308)),
        ((478, 308), (450, 324), (380, 352), (300, 364)),
        ((300, 364), (220, 374), (140, 372), (100, 360)),
        ((100, 360), (96, 364), (93, 368), (92, 372)),
    )
    tm = mask(trim)
    cv.put(shade(tm, 10, (36, 36, 40), gloss=0.25, shininess=30, amb=0.55, rim=0.2), soft(tm, 0.6))

    # ---- the chin bar: its own rounded bulge below the visor ----------------
    chin = path(
        ((70, 262), (110, 280), (220, 290), (330, 262)),
        ((330, 262), (346, 300), (330, 340), (300, 362)),
        ((300, 362), (220, 372), (140, 370), (100, 360)),
        ((100, 360), (70, 340), (62, 300), (70, 262)),
    )
    cm = mask(chin) * (sm > 0.5)
    cv.put(shade(cm, 46, (206, 30, 36), gloss=1.0, shininess=60, amb=0.30, env=0.25, rim=0.5), soft(cm, 1.4) * 0.75)

    # ---- panel line: the chin bar meets the shell behind the visor -------------
    groove = bez((338, 238), (344, 290), (328, 330), (296, 372))
    for (m, col, a, b) in (line(groove, 3.6, (60, 6, 10), 0.95), line([(x + 2.5, y + 1) for x, y in groove], 1.8, (255, 160, 160), 0.45)):
        cv.put(col, ndimage.gaussian_filter(m, b * SS) * a * (sm > 0.5))

    # ---- chin vent: three recessed slots ----------------------------------------
    for i in range(3):
        y = 300 + i * 17
        x0 = 82 + i * 3
        slot = path(((x0, y), (x0 + 20, y - 3), (x0 + 44, y - 3), (x0 + 58, y)),
                    ((x0 + 58, y), (x0 + 60, y + 4), (x0 + 58, y + 8), (x0 + 56, y + 9)),
                    ((x0 + 56, y + 9), (x0 + 40, y + 6), (x0 + 18, y + 6), (x0 + 2, y + 9)),
                    ((x0 + 2, y + 9), (x0 - 1, y + 6), (x0 - 1, y + 3), (x0, y)))
        smk = mask(slot)
        cv.put((255, 140, 140), soft(np.roll(smk, 2 * SS, axis=0)) * 0.35)
        cv.put((18, 16, 20), soft(smk, 0.5))

    # ---- the visor over the eye port ------------------------------------------
    port = path(
        ((90, 238), (92, 160), (156, 112), (246, 112)),
        ((246, 112), (312, 112), (334, 160), (330, 216)),
        ((330, 216), (326, 262), (276, 276), (196, 276)),
        ((196, 276), (126, 276), (90, 268), (90, 238)),
    )
    # The dark rubber seal around the port, then the smoked visor on it.
    cv.put((14, 14, 18), soft(mask(port, grow=7)))
    vm = mask(port)
    cv.put(shade(vm, 60, (38, 52, 74), gloss=1.6, shininess=110, amb=0.42, env=0.55, rim=0.35), soft(vm, 0.6))
    # A crisp reflection streak across the visor (the sky).
    streak = path(
        ((104, 214), (112, 168), (160, 132), (230, 128)),
        ((230, 128), (196, 146), (156, 178), (136, 222)),
        ((136, 222), (124, 224), (110, 222), (104, 214)),
    )
    cv.put((228, 238, 250), soft(mask(streak) * (vm > 0.5), 0.7) * 0.55)
    streak2 = path(
        ((246, 126), (282, 128), (306, 150), (312, 182)),
        ((312, 182), (300, 160), (280, 144), (246, 126)),
    )
    cv.put((228, 238, 250), soft(mask(streak2) * (vm > 0.5), 0.7) * 0.35)

    # ---- the visor pivot plate --------------------------------------------------
    pivot = path(((326, 200), (340, 192), (360, 196), (364, 214)),
                 ((364, 214), (366, 232), (350, 242), (334, 238)),
                 ((334, 238), (322, 234), (318, 214), (326, 200)))
    pm = mask(pivot)
    cv.put((20, 20, 24), soft(mask(pivot, grow=2)))
    cv.put(shade(pm, 14, (60, 62, 68), gloss=0.9, shininess=50, amb=0.45), soft(pm, 0.6))
    knob = path(((336, 210), (340, 204), (350, 204), (352, 212)), ((352, 212), (354, 222), (344, 226), (338, 222)), ((338, 222), (334, 218), (334, 214), (336, 210)))
    km = mask(knob)
    cv.put(shade(km, 6, (170, 172, 178), gloss=1.2, shininess=60, amb=0.5), soft(km, 0.5))

    # ---- a small brow vent scoop -------------------------------------------------
    scoop = path(((150, 96), (176, 74), (214, 64), (238, 66)),
                 ((238, 66), (236, 76), (230, 84), (222, 88)),
                 ((222, 88), (196, 90), (172, 98), (156, 108)),
                 ((156, 108), (150, 106), (148, 100), (150, 96)))
    scm = mask(scoop)
    cv.put((30, 8, 10), soft(mask(scoop, grow=2)) * 0.8)
    cv.put(shade(scm, 8, (40, 40, 46), gloss=0.8, shininess=50, amb=0.5), soft(scm, 0.5))

    out = cv.image()
    dst = os.path.join(root, 'assets', 'duty_slip', 'dress', 'tray_bike_helmet.webp')
    out.save(dst, 'WEBP', quality=86, method=6)
    print('wrote', dst, os.path.getsize(dst), 'bytes')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
