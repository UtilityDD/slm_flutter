"""Picture cards for lesson 6.1 শেখা ("ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড").

python -I tool/m6_board61_art.py .

Writes assets/game/art/m6_board61/*.svg in the clean gradient style of
tool/m5_board55_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the sight glass carries two tick marks (MIN / MAX), no letters.

The DTR is the WBSEDCL pole-mounted one (ruling M6-2): a gang-operated AB
switch on the top crossarm with its operating rod and handle down the left
pole, HG (horn-gap) fuses under it, the tank on a channel platform between
two poles, three tall HT bushings and four short LT bushings, the
conservator drum with its sight glass, the silica-gel breather, radiator
fins, a nameplate and a drain valve. No DO fuse anywhere.

What the cards show comes from lesson 6.1 (live text) and the Module 6
rulings (board 6.1 shortened to 4 rounds, ruling M6-8):
  1. signs (recap): outside signs that the inside is at risk — oil dripping
     with the gauge below MIN, pink silica gel, dark burnt-smelling oil from
     the drain valve in a clean glass bottle. Traps: the soft steady hum
     (normal, myth 2), blue dry gel, oil between MIN and MAX;
  2. inside: what the tank holds — the laminated soft-iron core, the HT and
     LT copper coils, kraft paper between the layers, everything sunk in
     mineral oil. Traps: a spinning fan / rotor (a DTR is static), a wire
     straight from the HT coil to the LT coil (induction, no wire), a tank
     full of water;
  3. coil (shop photos of an opened coil): paper black at the top of the
     coil, copper melted into lumps and splattered, a coil bent / bulged out
     of place, turns burst open at one spot. Traps: yellow-brown unburnt
     paper, a straight coil in its place, smooth whole copper;
  4. act (signs of an inside fault seen): report to the JE / control room
     and ask for tests, change the pink gel, take the DTR off the line and
     send its oil for DGA / BDV (X6: 'লাইন থেকে বিচ্ছিন্ন করে'). Traps: the
     tank opened on the pole, the tank
     opened in roadside dust, a burnt DTR put back on charge, a small drip
     ignored.
Hands on the DTR only once it is dead and earthed (rulings X1, X3, M6-4):
on the platform cards the AB blades stand open, the handle is down with its
red tag, and the earth leads are on the HT bushings. The recharge trap
shows the handle being pushed up with the earth set lying on the ground.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too.
It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board61_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board61')
W, H = 200, 220
GY = 198

SHIRT_D = '#174A70'
SHIRT = '#1F5F8F'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
STEEL_D = '#59626A'
FIN = '#56705F'
OIL = '#C98A1E'
OIL_D = '#9C6A12'
BURNT = HAIR            # dark, burnt drain oil (the same brown-black as hair)
GEL_BLUE = '#2F6BCB'
GEL_PINK = '#F2A2B8'
GLASS = '#DCE6EE'
PAPER = '#F4F1E6'
INK = '#4A5560'
PLATE = '#D9DEE2'
EARTHW = '#3E9B4F'
EARTH_Y = '#E8C830'
TAG = '#D8402F'
MOVE = '#FFFFFF'
LEAF = '#4E7A3A'
KRAFT = '#C9A060'       # kraft paper, yellow-brown
CHAR = '#22262B'        # charred paper, clamp iron
COPPER = '#C8703A'
COPPER_D = '#9A5228'
BENCH = '#8A6A44'
DUST = '#C9B48E'
WATER = '#5FB2E6'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="shop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9C2C8"/><stop offset="0.72" stop-color="#DCE1E4"/><stop offset="0.72" stop-color="#8E8A82"/><stop offset="1" stop-color="#77736B"/></linearGradient>
  <linearGradient id="cut" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2C3A46"/><stop offset="1" stop-color="#43525E"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5F7069"/><stop offset="0.45" stop-color="#9DB0A8"/><stop offset="1" stop-color="#596A63"/></linearGradient>
  <linearGradient id="drum" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DB0A8"/><stop offset="0.5" stop-color="#7C8F87"/><stop offset="1" stop-color="#55665F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E6A4E"/><stop offset="0.5" stop-color="#D49A78"/><stop offset="1" stop-color="#8A5A40"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="core" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E777E"/><stop offset="0.5" stop-color="#A9B3BA"/><stop offset="1" stop-color="#5E676E"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9A5228"/><stop offset="0.45" stop-color="#E8955A"/><stop offset="1" stop-color="#8A4622"/></linearGradient>
  <linearGradient id="oil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E0A440" stop-opacity="0.55"/><stop offset="1" stop-color="#B8862E" stop-opacity="0.7"/></linearGradient>
  <radialGradient id="zoom" cx="0.5" cy="0.45" r="0.6"><stop offset="0" stop-color="#F6F8F9"/><stop offset="1" stop-color="#C9D2D8"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The lineman (the worker of tool/m5_board55_art.py).
# --------------------------------------------------------------------------

def _joint(a, b, face, k=5.0, down=False):
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    dx, dy = b[0] - a[0], b[1] - a[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * k, dx / n * k
    if down:
        if py < 0:
            px, py = -px, -py
    elif px * face < 0:
        px, py = -px, -py
    return (mx + px, my + py)


def _limb(a, j, b, color, w):
    return (f'<path d="M{f(a[0])} {f(a[1])} L{f(j[0])} {f(j[1])} L{f(b[0])} {f(b[1])}" stroke="{color}" stroke-width="{w}" '
            'stroke-linecap="round" stroke-linejoin="round" fill="none"/>')


def _boot(p, face):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{BOOT}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, props_front=''):
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, SHIRT_D, 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{GLOVE}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{GLOVE}"/>')
    return ''.join(g)


def person(x, hands_world, face=-1, look=0, gy=GY, s=1.0, stride=0, props=''):
    """A standing lineman at x (feet on gy), scaled s about the feet; the hands
    are given in card coordinates. [stride] > 0 = walking."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face + stride * 0.2 * face, gy - 56)
    head = (x + 3 * face + stride * 0.3 * face, gy - 64)
    sp = 7 + stride
    feet = ((x - sp * face, gy - 1), (x + (sp - 1) * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}{props}</g>'


def kneel(x, gy, hands_world, face=1, s=1.0):
    """The lineman kneeling (one knee down) on gy."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 18)
    sh = (x + 6 * face, gy - 42)
    head = (x + 9 * face, gy - 50)
    feet = ((x - 14 * face, gy - 1), (x + 12 * face, gy - 1))
    fig = figure(hip, sh, head, feet, (local(hands_world[0]), local(hands_world[1])), face, 18)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def motion(x, y, dx=0, dy=1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def earth_lead(d):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{EARTHW}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.4" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """A portable earth set lying coiled on the ground, unused."""
    o = []
    for rx, ry in ((14, 5), (11, 4), (8, 3)):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0'))
    for dx in (-20, 18, 24):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="7" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def flowers(x, y, n=5):
    """A small bougainvillea sprig (leaves, pink bracts) — scenery."""
    o = [f'<path d="M{f(x)} {f(y)} q6 -10 14 -12 M{f(x + 4)} {f(y - 4)} q-6 -8 -4 -16" stroke="{LEAF}" stroke-width="2" fill="none"/>']
    pts = [(14, -13), (-1, -19), (8, -6), (-6, -9), (18, -4), (3, -14)]
    for dx, dy in pts[:n]:
        o.append(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="3" fill="{GEL_PINK}"/>')
    return ''.join(o)


def crate(x, y):
    """A blue plastic crate (the crew's kit box) — scenery."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="22" height="13" rx="2" fill="{GEL_BLUE}"/>'
            f'<path d="M{f(x + 3)} {f(y + 4)} h16 M{f(x + 3)} {f(y + 8)} h16" stroke="{SHIRT_D}" stroke-width="1.2"/>')


def bottle(x, y, oil='dark', s=1.0):
    """A clean glass bottle (bottom centre x, y) with a drain-oil sample."""
    w, h = 14 * s, 24 * s
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y - h)}" width="{f(w)}" height="{f(h)}" rx="{f(3 * s)}" fill="{GLASS}" stroke="{INK}" stroke-width="0.8"/>',
         f'<rect x="{f(x - 3 * s)}" y="{f(y - h - 5 * s)}" width="{f(6 * s)}" height="{f(6 * s)}" rx="1" fill="{GLASS}" stroke="{INK}" stroke-width="0.8"/>']
    fill = BURNT if oil == 'dark' else OIL
    o.append(f'<rect x="{f(x - w / 2 + 1.5 * s)}" y="{f(y - h * 0.62)}" width="{f(w - 3 * s)}" height="{f(h * 0.62 - 1.5 * s)}" rx="{f(2 * s)}" fill="{fill}"/>')
    return ''.join(o)


def smell(x, y, n=3):
    """Wavy smoke-grey wisps rising: a burnt smell."""
    o = []
    for i in range(n):
        ox = x + (i - 1) * 7
        o.append(f'<path d="M{f(ox)} {f(y)} q-4 -5 0 -10 q4 -5 0 -10" stroke="{INK}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.8"/>')
    return ''.join(o)


def drops(x, y0, n=3, gap=7):
    o = []
    for i in range(n):
        yy = y0 + i * gap
        o.append(f'<path d="M{f(x)} {f(yy - 2.6)} q2.2 3 0 4.6 q-2.2 -1.6 0 -4.6 Z" fill="{OIL}"/>')
    return ''.join(o)


def puddle(x, y, rx=16):
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(rx)}" ry="{f(rx * 0.25)}" fill="{OIL}" opacity="0.7"/>'


def phone(x, y, ang=0):
    """A mobile phone (top-left x, y)."""
    o = [f'<g transform="rotate({ang} {f(x + 6)} {f(y + 10)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="12" height="20" rx="2" fill="{WIRE}"/>',
         f'<rect x="{f(x + 1.4)}" y="{f(y + 2)}" width="9.2" height="15" fill="{GLASS}"/>']
    o.append('</g>')
    return ''.join(o)


def clipboard(x, y, s=1.0):
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(22 * s)}" height="{f(28 * s)}" rx="2" fill="{BENCH}"/>',
         f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 4 * s)}" width="{f(17 * s)}" height="{f(22 * s)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + 7 * s)}" y="{f(y + 1.5 * s)}" width="{f(8 * s)}" height="{f(4 * s)}" rx="1" fill="url(#steel)"/>']
    for i in range(4):
        o.append(f'<path d="M{f(x + 5 * s)} {f(y + (10 + i * 4) * s)} h{f(12 * s - (i % 2) * 4)}" stroke="{INK}" stroke-width="0.8"/>')
    return ''.join(o)


def spanner(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x)}" y="{f(y - 2.2)}" width="20" height="4.4" rx="1.6" fill="url(#steel)"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} L{f(x + 4)} {f(y - 6)} L{f(x + 4)} {f(y - 2)} L{f(x + 1)} {f(y - 2)} L{f(x + 1)} {f(y + 2)} '
            f'L{f(x + 4)} {f(y + 2)} L{f(x + 4)} {f(y + 6)} L{f(x - 2)} {f(y + 6)} Z" fill="url(#steel)"/></g>')


def hum_waves(x, y, side=1, rough=False):
    """Sound lines beside the tank: soft and even (normal hum)."""
    o = []
    for i, r in enumerate((8, 14, 20)):
        if rough:
            o.append(f'<path d="M{f(x + side * r)} {f(y - r * 0.7)} l{f(side * 3)} 4 l{f(-side * 3)} 4 l{f(side * 3)} 4 l{f(-side * 3)} 4" stroke="{MOVE}" stroke-width="1.6" fill="none"/>')
        else:
            o.append(f'<path d="M{f(x + side * r * 0.6)} {f(y - r * 0.8)} q{f(side * r * 0.5)} {f(r * 0.8)} 0 {f(r * 1.6)}" stroke="{MOVE}" stroke-width="1.5" fill="none" opacity="{f(0.9 - i * 0.2)}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# The pole-mounted DTR (rounds 1 and 4).
# --------------------------------------------------------------------------

PL = 30, 170          # the two poles
PLAT = 112            # platform top
TK = (64, 70, 136, PLAT)   # the tank: x0, y0, x1, y1
HTB = (76, 92, 108)        # HT bushing x
LTB = (116, 122, 128, 134)  # LT bushing x


def bushing(x, base, h, w, sheds):
    o = [f'<rect x="{f(x - w * 0.3)}" y="{f(base - h)}" width="{f(w * 0.6)}" height="{f(h)}" fill="url(#porcelain)"/>']
    for i in range(sheds):
        yy = base - h + 3 + i * (h - 4) / max(1, sheds)
        o.append(f'<ellipse cx="{f(x)}" cy="{f(yy)}" rx="{f(w / 2)}" ry="1.6" fill="url(#porcelain)"/>')
    o.append(f'<rect x="{f(x - 1)}" y="{f(base - h - 3)}" width="2" height="4" fill="url(#steel)"/>')
    return ''.join(o)


def sight_glass(x, y, w, h, level):
    """The conservator's oil gauge: a glass with two ticks (MAX up, MIN low);
    [level] 0..1 of its height filled with oil."""
    lvl = y + h - h * level
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(w * 0.3)}" fill="{GLASS}" stroke="{WIRE}" stroke-width="1"/>'
            f'<rect x="{f(x + 1)}" y="{f(lvl)}" width="{f(w - 2)}" height="{f(y + h - lvl - 1)}" rx="{f(w * 0.2)}" fill="{OIL}"/>'
            f'<path d="M{f(x - 3)} {f(y + h * 0.22)} h{f(w + 6)} M{f(x - 3)} {f(y + h * 0.78)} h{f(w + 6)}" stroke="{WIRE}" stroke-width="1.2"/>')


def breather(x, y, w, h, gel):
    """The silica-gel breather (top-left x, y) with its glass window."""
    col = GEL_PINK if gel == 'pink' else GEL_BLUE
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(w * 0.2)}" fill="url(#steel)" stroke="{WIRE}" stroke-width="0.8"/>',
         f'<rect x="{f(x + w * 0.18)}" y="{f(y + h * 0.12)}" width="{f(w * 0.64)}" height="{f(h * 0.72)}" rx="{f(w * 0.12)}" fill="{col}"/>']
    # granules
    r = max(0.6, w * 0.06)
    for i in range(int(h * 0.72 / (r * 3.2))):
        for j in range(2):
            cx = x + w * (0.34 + 0.32 * j) + (i % 2) * r
            cy = y + h * 0.16 + i * r * 3.2 + r
            o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{MOVE}" opacity="0.35"/>')
    o.append(f'<rect x="{f(x + w * 0.3)}" y="{f(y + h)}" width="{f(w * 0.4)}" height="{f(h * 0.1)}" fill="{STEEL_D}"/>')
    return ''.join(o)


def ab_switch(open_=False):
    """The gang-operated AB switch on the top crossarm, its HG fuses below and
    the jumpers down to the HT bushings."""
    o = [f'<rect x="{PL[0] - 8}" y="14" width="{PL[1] - PL[0] + 16}" height="5" fill="{STEEL_D}"/>']
    for x in (76, 100, 124):
        o.append(f'<rect x="{x - 9}" y="8" width="3" height="7" fill="url(#porcelain)"/><rect x="{x + 6}" y="8" width="3" height="7" fill="url(#porcelain)"/>')
        if open_:
            o.append(f'<path d="M{x - 7.5} 8 L{x - 1} -6" stroke="url(#steel)" stroke-width="2.6" stroke-linecap="round"/>')
            o.append(f'<path d="M{x + 7.5} 8 l0 -3" stroke="url(#steel)" stroke-width="2.6"/>')
        else:
            o.append(f'<path d="M{x - 7.5} 8 L{x + 7.5} 8" stroke="url(#steel)" stroke-width="2.6" stroke-linecap="round"/>')
        # HG fuse: two horns with the fuse wire across
        o.append(f'<path d="M{x - 2} 24 q-5 -3 -6 -8 M{x + 2} 24 q5 -3 6 -8" stroke="url(#steel)" stroke-width="1.4" fill="none"/>')
        o.append(f'<rect x="{x - 3}" y="24" width="6" height="5" fill="url(#porcelain)"/>')
    for x, b in zip((76, 100, 124), HTB):
        o.append(f'<path d="M{x + 7.5} 19 L{x} 24 M{x} 29 L{b} {TK[1] - 25}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    # The operating rod down the left pole to its handle.
    o.append(f'<path d="M{PL[0] + 6} 19 L{PL[0] + 6} 160" stroke="url(#steel)" stroke-width="1.8"/>')
    if open_:
        o.append(f'<path d="M{PL[0] + 6} 162 l10 8" stroke="{STEEL_D}" stroke-width="3.4" stroke-linecap="round"/>')
        o.append(f'<path d="M{PL[0] + 16} 170 l2 4" stroke="{PAPER}" stroke-width="0.8"/><rect x="{PL[0] + 14}" y="174" width="8" height="11" rx="1.5" fill="{TAG}"/>')
    else:
        o.append(f'<path d="M{PL[0] + 6} 162 l10 -8" stroke="{STEEL_D}" stroke-width="3.4" stroke-linecap="round"/>')
    return ''.join(o)


def dtr_tank(dx=0, dy=0, gel='pink', level=0.5, lid_open=False, soot=False, earth=False):
    x0, y0, x1, y1 = TK[0] + dx, TK[1] + dy, TK[2] + dx, TK[3] + dy
    o = []
    # fins
    for i in range(4):
        o.append(f'<rect x="{f(x0 - 9 + i * 0.1)}" y="{f(y0 + 6 + i * 9)}" width="9" height="5" rx="1" fill="{FIN}"/>')
        o.append(f'<rect x="{f(x1)}" y="{f(y0 + 6 + i * 9)}" width="9" height="5" rx="1" fill="{FIN}"/>')
    o.append(f'<rect x="{f(x0)}" y="{f(y0)}" width="{f(x1 - x0)}" height="{f(y1 - y0)}" rx="3" fill="url(#tank)"/>')
    if soot:
        o.append(f'<path d="M{f(x0 + 8)} {f(y0 + 4)} q10 14 4 30 q16 -10 24 -30 Z" fill="{CHAR}" opacity="0.55"/>')
    # nameplate
    o.append(f'<rect x="{f(x0 + 6)}" y="{f(y0 + 16)}" width="20" height="13" fill="{PLATE}" stroke="{INK}" stroke-width="0.6"/>')
    o.append(f'<path d="M{f(x0 + 9)} {f(y0 + 20)} h14 M{f(x0 + 9)} {f(y0 + 23)} h14 M{f(x0 + 9)} {f(y0 + 26)} h9" stroke="{INK}" stroke-width="0.6"/>')
    # drain valve
    o.append(f'<rect x="{f(x0 + 4)}" y="{f(y1 - 9)}" width="8" height="6" rx="1" fill="url(#steel)"/><path d="M{f(x0 + 8)} {f(y1 - 9)} v-3 h4" stroke="{STEEL_D}" stroke-width="1.4" fill="none"/>')
    # lid and bushings
    if lid_open:
        o.append(f'<g transform="rotate(-24 {f(x0)} {f(y0)})"><rect x="{f(x0 - 2)}" y="{f(y0 - 4)}" width="{f(x1 - x0 + 4)}" height="5" rx="1" fill="url(#drum)"/>'
                 + ''.join(bushing(b + dx, y0 - 4, 22, 9, 4) for b in HTB) + '</g>')
        o.append(f'<rect x="{f(x0 + 3)}" y="{f(y0)}" width="{f(x1 - x0 - 6)}" height="6" fill="{OIL_D}"/>')
    else:
        o.append(f'<rect x="{f(x0 - 2)}" y="{f(y0 - 4)}" width="{f(x1 - x0 + 4)}" height="5" rx="1" fill="url(#drum)"/>')
        for b in HTB:
            o.append(bushing(b + dx, y0 - 4, 22, 9, 4))
    for b in LTB:
        o.append(bushing(b + dx, y0 - 4, 9, 6, 2))
    # conservator drum, sight glass, breather
    o.append(f'<rect x="{f(x1 - 30)}" y="{f(y0 - 26)}" width="5" height="12" fill="{STEEL_D}"/><rect x="{f(x1 + 2)}" y="{f(y0 - 26)}" width="4" height="22" fill="{STEEL_D}"/>')
    o.append(f'<rect x="{f(x1 - 34)}" y="{f(y0 - 36)}" width="44" height="13" rx="6.5" fill="url(#drum)"/>')
    o.append(sight_glass(x1 + 11, y0 - 37, 5, 14, level))
    o.append(f'<path d="M{f(x1 + 6)} {f(y0 - 24)} v4 h12 v10" stroke="{STEEL_D}" stroke-width="2" fill="none"/>')
    o.append(breather(x1 + 14, y0 - 10, 8, 18, gel))
    if earth:
        o.append(earth_lead(f'M{f(HTB[0] + dx)} {f(y0 - 28)} L{f(HTB[2] + dx)} {f(y0 - 28)} M{f(HTB[0] + dx)} {f(y0 - 28)} '
                            f'L{f(x0 - 12)} {f(y0 - 18)} L{f(PL[0] + 4)} {f(y1 + 6)} L{f(PL[0] + 4)} {GY - 2}'))
        for b in HTB:
            o.append(f'<rect x="{f(b + dx - 2.5)}" y="{f(y0 - 30)}" width="5" height="5" rx="1" fill="url(#steel)"/>')
    return ''.join(o)


def pole_stage(open_=False, tank=True, ground=True, **tank_kw):
    out = card_open('day')
    if ground:
        out.append(f'<rect y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>')
    for x in PL:
        out.append(f'<rect x="{x - 4}" y="2" width="8" height="{GY - 2}" fill="url(#pole)"/>')
    out.append(f'<rect x="{PL[0] - 6}" y="{PLAT}" width="{PL[1] - PL[0] + 12}" height="6" fill="{STEEL_D}"/>')
    # body earth strip down the right pole
    out.append(f'<path d="M{TK[2] - 4} {PLAT + 3} L{PL[1] - 5} {PLAT + 6} L{PL[1] - 5} {GY - 2}" stroke="{STEEL_D}" stroke-width="1.6" fill="none"/>')
    out.append(ab_switch(open_))
    if tank:
        out.append(dtr_tank(**tank_kw))
    return out


# --------------------------------------------------------------------------
# Round 1 — signs: close views and the DTR on its poles.
# --------------------------------------------------------------------------

def close_gauge(level=0.5, drip=False):
    """A close view of the conservator's end: the big sight glass with its two
    ticks, the drum, the tank top below; [drip] = oil running down the tank
    from a bushing gasket into a puddle."""
    out = card_open('day')
    out.append(f'<rect y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>')
    out.append(f'<rect x="20" y="110" width="150" height="100" rx="4" fill="url(#tank)"/>')
    for i in range(5):
        out.append(f'<rect x="170" y="{118 + i * 16}" width="18" height="9" rx="2" fill="{FIN}"/>')
    out.append(f'<rect x="16" y="104" width="158" height="8" rx="2" fill="url(#drum)"/>')
    out.append(bushing(44, 104, 22, 14, 2))
    out.append(bushing(70, 104, 22, 14, 2))
    out.append(f'<rect x="100" y="70" width="8" height="34" fill="{STEEL_D}"/><rect x="146" y="70" width="8" height="34" fill="{STEEL_D}"/>')
    out.append(f'<rect x="-20" y="22" width="166" height="52" rx="26" fill="url(#drum)"/>')
    out.append(f'<rect x="144" y="16" width="10" height="64" rx="3" fill="{STEEL_D}"/>')
    out.append(sight_glass(160, 14, 18, 68, level))
    if drip:
        out.append(f'<path d="M78 106 q3 12 0 30 q-2 34 3 58" stroke="{OIL}" stroke-width="3.4" fill="none" opacity="0.9"/>')
        out.append(drops(82, 200, 1, 7))
        out.append(puddle(86, GY - 2, 26))
    return out


def close_breather(gel='blue'):
    """A close view of the silica-gel breather hanging from its pipe beside
    the tank, the gel seen through its glass."""
    out = card_open('day')
    out.append(f'<rect y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>')
    out.append(f'<rect x="-20" y="60" width="78" height="150" rx="4" fill="url(#tank)"/>')
    for i in range(7):
        out.append(f'<rect x="58" y="{70 + i * 18}" width="16" height="9" rx="2" fill="{FIN}"/>')
    out.append(f'<rect x="-20" y="8" width="150" height="36" rx="18" fill="url(#drum)"/>')
    out.append(f'<path d="M118 40 L118 52 L130 52 L130 62" stroke="{STEEL_D}" stroke-width="7" fill="none"/>')
    out.append(breather(102, 62, 56, 118, gel))
    return out


def signs_card(kind):
    if kind == 'drip':
        out = close_gauge(level=0.08, drip=True)
        out.append(flowers(150, GY - 4))
    elif kind == 'midoil':
        out = close_gauge(level=0.5)
        out.append(flowers(150, GY - 4))
    elif kind == 'pink':
        out = close_breather('pink')
    elif kind == 'blue':
        out = close_breather('blue')
        out.append(flowers(176, GY - 4))
    elif kind == 'burnt':
        # The drain valve close: dark, burnt oil running into a clean glass
        # bottle, wisps of a burnt smell; the worker holds it.
        out = card_open('day')
        out.append(f'<rect y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>')
        out.append(f'<rect x="-10" y="20" width="130" height="120" rx="4" fill="url(#tank)"/>')
        for i in range(6):
            out.append(f'<rect x="120" y="{28 + i * 18}" width="18" height="10" rx="2" fill="{FIN}"/>')
        out.append(f'<rect x="-14" y="140" width="160" height="10" fill="{STEEL_D}"/>')
        out.append(f'<rect x="80" y="118" width="20" height="12" rx="2" fill="url(#steel)"/><path d="M90 118 v-6 h10" stroke="{STEEL_D}" stroke-width="2.4" fill="none"/>')
        out.append(f'<path d="M86 130 q1 14 4 22" stroke="{BURNT}" stroke-width="3" fill="none"/>')
        out.append(bottle(92, 186, 'dark', 1.5))
        out.append(smell(92, 140, 3))
        out.append(person(150, ((104, 168), (106, 180)), face=-1, look=8, s=0.95))
        out.append(flowers(14, GY - 4))
    elif kind == 'hum':
        out = pole_stage(open_=False, gel='blue', level=0.5)
        out.append(hum_waves(TK[0] - 10, 90, -1))
        out.append(hum_waves(TK[2] + 10, 90, 1))
        out.append(person(120, ((112, 134), (126, 138)), face=-1, look=-12, s=0.85))
        out.append(flowers(150, GY - 4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — inside: a cut-away tank.
# --------------------------------------------------------------------------

LEGS = (58, 100, 142)


def coil(x, y0, y1, w=30, paper=True):
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y0)}" width="{f(w)}" height="{f(y1 - y0)}" rx="4" fill="url(#copper)"/>']
    for yy in range(int(y0) + 5, int(y1) - 2, 5):
        o.append(f'<path d="M{f(x - w / 2 + 1)} {yy} h{f(w - 2)}" stroke="{COPPER_D}" stroke-width="0.9"/>')
    if paper:
        for yy in range(int(y0) + 14, int(y1) - 6, 22):
            o.append(f'<rect x="{f(x - w / 2)}" y="{yy}" width="{f(w)}" height="3" fill="{KRAFT}"/>')
    return ''.join(o)


def core(coils=(True, True, True), bright=False, paper=True):
    o = [f'<rect x="38" y="62" width="124" height="12" rx="2" fill="url(#core)"/>',
         f'<rect x="38" y="176" width="124" height="12" rx="2" fill="url(#core)"/>']
    for x, c in zip(LEGS, coils):
        o.append(f'<rect x="{x - 6}" y="70" width="12" height="110" fill="url(#core)"/>')
        if not c or bright:
            for yy in range(76, 178, 4):
                o.append(f'<path d="M{x - 6} {yy} h12" stroke="{STEEL_D}" stroke-width="0.8"/>')
        if c:
            o.append(coil(x, 82, 170, 32, paper))
    # clamps
    o.append(f'<rect x="34" y="58" width="132" height="4" fill="{CHAR}"/><rect x="34" y="188" width="132" height="4" fill="{CHAR}"/>')
    return ''.join(o)


def tank_cut():
    out = card_open('cut')
    out.append(f'<rect x="22" y="36" width="156" height="172" rx="6" fill="none" stroke="url(#steel)" stroke-width="5"/>')
    out.append(f'<rect x="16" y="28" width="168" height="8" rx="2" fill="url(#steel)"/>')
    for x in (60, 100, 140):
        out.append(bushing(x, 28, 18, 10, 3))
    return out


def liquid(kind='oil', top=48):
    if kind == 'water':
        o = [f'<rect x="25" y="{top}" width="150" height="{205 - top}" fill="{WATER}" opacity="0.55"/>']
        for i in range(5):
            o.append(f'<path d="M{28 + i * 30} {top} q7 -4 15 0 q8 4 15 0" stroke="{MOVE}" stroke-width="1.2" fill="none"/>')
        for x, y in ((40, 120), (160, 90), (90, 200), (130, 150), (70, 96)):
            o.append(f'<circle cx="{x}" cy="{y}" r="2.6" fill="none" stroke="{MOVE}" stroke-width="1"/>')
        return ''.join(o)
    return (f'<rect x="25" y="{top}" width="150" height="{205 - top}" fill="url(#oil)"/>'
            f'<path d="M25 {top} h150" stroke="{OIL}" stroke-width="1.6"/>')


def zoom_bubble(cx, cy, r, inner, src):
    """A magnified look: a lens circle tied to [src], [inner] clipped to it."""
    return (f'<path d="M{src[0]} {src[1]} L{f(cx)} {f(cy + r)}" stroke="{MOVE}" stroke-width="1.2" stroke-dasharray="3 2"/>'
            f'<clipPath id="lens"><circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}"/></clipPath>'
            f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="url(#zoom)"/>'
            f'<g clip-path="url(#lens)">{inner}</g>'
            f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" stroke="{MOVE}" stroke-width="2"/>')


def inside_card(kind):
    out = tank_cut()
    if kind == 'core':
        out.append(core(coils=(False, False, False), bright=True))
        out.append(liquid())
    elif kind == 'coils':
        # HT outside, LT inside: a zoom on one limb's two copper windings.
        out.append(core())
        out.append(liquid())
        inner = (f'<rect x="64" y="70" width="12" height="90" fill="url(#core)"/>'
                 f'<rect x="78" y="70" width="14" height="90" fill="url(#copper)"/><rect x="48" y="70" width="14" height="90" fill="url(#copper)"/>'
                 f'<rect x="96" y="70" width="24" height="90" fill="url(#copper)"/><rect x="20" y="70" width="24" height="90" fill="url(#copper)"/>'
                 f'<rect x="92" y="70" width="4" height="90" fill="{KRAFT}"/><rect x="44" y="70" width="4" height="90" fill="{KRAFT}"/>')
        out.append(zoom_bubble(70, 112, 40, inner, (142, 150)))
    elif kind == 'paper':
        out.append(core())
        out.append(liquid())
        inner = []
        for i in range(6):
            yy = 76 + i * 13
            inner.append(f'<rect x="56" y="{yy}" width="90" height="8" fill="{COPPER}"/>')
            inner.append(f'<rect x="56" y="{yy + 8}" width="90" height="5" fill="{KRAFT}"/>')
        out.append(zoom_bubble(100, 112, 40, ''.join(inner), (142, 150)))
    elif kind == 'oil':
        # Everything sunk in oil; the warm oil rises, cools at the walls, sinks.
        out.append(core())
        out.append(liquid(top=44))
        for x0, x1 in ((79, 30), (121, 170)):
            out.append(f'<path d="M{x0} 168 L{x0} 56 Q{x0} 48 {(x0 + x1) / 2} 48 Q{x1} 48 {x1} 60 L{x1} 190" stroke="{MOVE}" stroke-width="2" fill="none" stroke-dasharray="6 5"/>')
            out.append(f'<path d="M{x1 - 4} 184 l4 7 l4 -7" stroke="{MOVE}" stroke-width="2" fill="none"/>')
    elif kind == 'rotor':
        out.append(core(coils=(True, False, True)))
        # a fan spinning where the middle limb stands
        out.append(f'<circle cx="100" cy="125" r="6" fill="url(#steel)"/>')
        for a in (0, 90, 180, 270):
            out.append(f'<path d="M100 125 q14 -6 24 4 q-12 6 -24 -4 Z" fill="url(#steel)" transform="rotate({a} 100 125)"/>')
        out.append(f'<path d="M72 98 a38 38 0 0 1 30 -10 M128 152 a38 38 0 0 1 -30 10" stroke="{MOVE}" stroke-width="2" fill="none"/>')
        out.append(liquid())
    elif kind == 'wire':
        out.append(core())
        out.append(f'<path d="M58 82 Q58 52 100 50 Q142 52 142 82" stroke="{TAG}" stroke-width="3" fill="none"/>')
        out.append(f'<circle cx="58" cy="82" r="3" fill="url(#steel)"/><circle cx="142" cy="82" r="3" fill="url(#steel)"/>')
        out.append(liquid())
        inner = (f'<rect x="146" y="40" width="24" height="10" fill="{KRAFT}"/><rect x="146" y="50" width="24" height="8" fill="{COPPER}"/>'
                 f'<path d="M150 46 L166 40" stroke="{TAG}" stroke-width="2.4"/>')
        out.append(zoom_bubble(158, 48, 14, inner, (142, 82)))
    elif kind == 'water':
        out.append(core())
        out.append(liquid('water'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — coil: shop photos of an opened coil on the bench.
# --------------------------------------------------------------------------

def shop_stage():
    out = card_open('shop')
    out.append(f'<rect x="20" y="186" width="160" height="10" rx="2" fill="{BENCH}"/>')
    out.append(f'<rect x="30" y="196" width="8" height="24" fill="{CHAR}"/><rect x="162" y="196" width="8" height="24" fill="{CHAR}"/>')
    out.append(f'<path d="M150 0 v18" stroke="{WIRE}" stroke-width="1.4"/><path d="M138 30 q12 -16 24 0 Z" fill="{STEEL_D}"/>')
    return out


def shop_coil(x=100, top=50, bottom=184, w=74, char_top=0.0, bulge=0.0, tilt=0, burst=False, beads=False):
    o = [f'<g transform="rotate({tilt} {x} {bottom})">']
    if bulge:
        o.append(f'<path d="M{x - w / 2} {top} Q{x - w / 2 - bulge} {(top + bottom) / 2} {x - w / 2} {bottom} L{x + w / 2} {bottom} '
                 f'Q{x + w / 2 + bulge * 0.3} {(top + bottom) / 2} {x + w / 2} {top} Z" fill="url(#copper)"/>')
    else:
        o.append(f'<rect x="{x - w / 2}" y="{top}" width="{w}" height="{bottom - top}" rx="5" fill="url(#copper)"/>')
    for yy in range(top + 6, bottom - 2, 6):
        o.append(f'<path d="M{x - w / 2 + 2} {yy} h{w - 4}" stroke="{COPPER_D}" stroke-width="0.9"/>')
    for yy in range(top + 10, bottom - 8, 18):
        col = CHAR if (yy - top) < (bottom - top) * char_top else KRAFT
        o.append(f'<rect x="{x - w / 2}" y="{yy}" width="{w}" height="6" fill="{col}"/>')
    if char_top:
        o.append(f'<rect x="{x - w / 2}" y="{top}" width="{w}" height="{(bottom - top) * char_top * 0.6}" rx="5" fill="{CHAR}" opacity="0.75"/>')
    if burst:
        cx, cy = x + 8, top + (bottom - top) * 0.5
        o.append(f'<ellipse cx="{cx}" cy="{cy}" rx="14" ry="8" fill="{CHAR}"/>')
        for a in (-60, -25, 10, 40, 160, 200):
            ex, ey = cx + 20 * math.cos(math.radians(a)), cy + 14 * math.sin(math.radians(a))
            o.append(f'<path d="M{f(cx)} {f(cy)} Q{f((cx + ex) / 2 + 4)} {f((cy + ey) / 2 - 6)} {f(ex)} {f(ey)}" stroke="{COPPER}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    if beads:
        for bx, by, r in ((x - 12, top + 40, 6), (x + 6, top + 52, 4.5), (x - 4, top + 64, 5), (x + 16, top + 36, 3.5)):
            o.append(f'<circle cx="{bx}" cy="{by}" r="{r}" fill="url(#copper)" stroke="{COPPER_D}" stroke-width="0.8"/>')
            o.append(f'<circle cx="{bx - r * 0.3}" cy="{by - r * 0.3}" r="{r * 0.3}" fill="{MOVE}" opacity="0.6"/>')
        for bx, by in ((x - 30, 30), (x + 34, 40), (x + 44, 70), (x - 44, 58), (x + 28, 22)):
            o.append(f'<circle cx="{bx}" cy="{by}" r="1.8" fill="{COPPER}"/>')
    o.append('</g>')
    return ''.join(o)


def coil_card(kind):
    out = shop_stage()
    if kind == 'black':
        out.append(shop_coil(char_top=0.45))
    elif kind == 'melt':
        out.append(shop_coil(beads=True))
    elif kind == 'bent':
        out.append(f'<rect x="94" y="40" width="12" height="146" fill="url(#core)"/>')
        out.append(shop_coil(x=108, bulge=22, tilt=8))
    elif kind == 'burst':
        out.append(shop_coil(burst=True))
    elif kind == 'yellow':
        # A close look at whole, yellow-brown paper on the turns.
        out.append(shop_coil())
        inner = []
        for i in range(6):
            yy = 30 + i * 12
            inner.append(f'<rect x="110" y="{yy}" width="72" height="6" fill="{COPPER}"/><rect x="110" y="{yy + 6}" width="72" height="6" fill="{KRAFT}"/>')
        out.append(zoom_bubble(146, 62, 32, ''.join(inner), (118, 110)))
    elif kind == 'straight':
        out.append(f'<rect x="94" y="40" width="12" height="146" fill="url(#core)"/>')
        out.append(shop_coil())
        out.append(f'<path d="M38 36 L38 184" stroke="{TAG}" stroke-width="1.2" stroke-dasharray="4 3"/><circle cx="38" cy="186" r="3" fill="{TAG}"/>')
    elif kind == 'smooth':
        out.append(shop_coil(char_top=0.0))
        inner = []
        for i in range(4):
            yy = 34 + i * 16
            inner.append(f'<rect x="18" y="{yy}" width="72" height="12" rx="5" fill="url(#copper)"/><path d="M22 {yy + 3} h64" stroke="{MOVE}" stroke-width="1.4" opacity="0.6"/>')
        out.append(zoom_bubble(54, 64, 32, ''.join(inner), (80, 110)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — act: the DTR with signs of an inside fault (a drip, pink gel).
# --------------------------------------------------------------------------

def act_card(kind):
    drip = (TK[0] + 30, TK[3] + 10)
    if kind in ('gel', 'dga', 'poletank'):
        out = pole_stage(open_=True, gel='pink', level=0.25, earth=True, lid_open=(kind == 'poletank'))
        if kind == 'gel':
            # Fresh blue gel poured into the breather.
            bx = TK[2] + 18
            out.append(person(TK[2] - 4, ((bx - 2, TK[1] - 14), (bx + 4, TK[1] - 16)), face=1, look=-10, gy=PLAT, s=0.62))
            out.append(f'<rect x="{bx - 1}" y="{TK[1] - 28}" width="10" height="12" rx="2" fill="{GLASS}" stroke="{INK}" stroke-width="0.6"/>'
                       f'<rect x="{bx}" y="{TK[1] - 23}" width="8" height="6" fill="{GEL_BLUE}"/>')
        elif kind == 'dga':
            # An oil sample from the drain valve into a clean glass bottle.
            out.append(kneel(TK[0] + 24, PLAT, ((TK[0] + 12, PLAT - 6), (TK[0] + 16, PLAT - 10)), face=-1, s=0.62))
            out.append(bottle(TK[0] + 10, PLAT, 'clear', 0.6))
        else:
            # The lid unbolted and lifted on the pole.
            out.append(person(TK[2] - 12, ((TK[0] + 30, TK[1] - 22), (TK[0] + 40, TK[1] - 18)), face=-1, look=-14, gy=PLAT, s=0.62))
            out.append(spanner(TK[0] + 40, TK[1] - 18, -30))
        out.append(drops(*drip, 3))
        out.append(puddle(drip[0], GY - 2, 14))
    elif kind == 'report':
        out = pole_stage(open_=False, gel='pink', level=0.25)
        out.append(person(132, ((126, 150), (138, 140)), face=-1, look=-8, s=0.9, props=''))
        out.append(phone(134, 128, -10))
        out.append(clipboard(110, 154, 0.8))
        out.append(drops(*drip, 3))
        out.append(puddle(drip[0], GY - 2, 14))
        out.append(crate(146, GY - 13))
    elif kind == 'dust':
        # The tank brought down and opened on the roadside dirt, dust blowing.
        out = pole_stage(open_=True, tank=False)
        out.append(f'<ellipse cx="98" cy="{GY + 4}" rx="80" ry="10" fill="{DUST}"/>')
        out.append(dtr_tank(dx=-6, dy=GY - 4 - TK[3], gel='pink', level=0.25, lid_open=True))
        for i, (x, y) in enumerate(((150, 150), (166, 136), (44, 150), (140, 126))):
            out.append(f'<path d="M{x} {y} q8 -6 16 0 q-6 6 -14 2" stroke="{DUST}" stroke-width="3" fill="none" opacity="0.9"/>')
        out.append(person(150, ((122, 166), (128, 170)), face=-1, look=20, s=0.8))
        out.append(crate(14, GY - 13))
        out.append(f'<rect x="40" y="{GY - 14}" width="16" height="12" rx="3" fill="{BENCH}"/>')
        out.append(bottle(176, GY - 2, 'clear', 0.6))
    elif kind == 'recharge':
        # The burnt DTR (soot, dark oil in the bottle) put back on: the AB
        # handle pushed up, the earth set left on the ground.
        out = pole_stage(open_=False, gel='pink', level=0.25, soot=True)
        out.append(person(PL[0] + 26, ((PL[0] + 16, 152), (PL[0] + 18, 158)), face=-1, look=-10, s=0.85))
        out.append(motion(PL[0] + 22, 156, 0, -1, 3, 8))
        out.append(earth_coil(120, GY - 4))
        out.append(bottle(156, GY - 2, 'dark', 0.7))
        out.append(crate(160, GY - 40))
        out.append(drops(*drip, 3))
    elif kind == 'ignore':
        # A small drip, and the worker walking off with his bag.
        out = pole_stage(open_=False, gel='pink', level=0.25)
        out.append(drops(*drip, 3))
        out.append(puddle(drip[0], GY - 2, 14))
        out.append(person(150, ((140, 166), (162, 168)), face=1, look=0, s=0.9, stride=4))
        out.append(f'<rect x="156" y="160" width="16" height="12" rx="3" fill="{BENCH}"/>')
        out.append(motion(130, 160, -1, 0, 3, 8))
        out.append(crate(10, GY - 13))
        out.append(bottle(186, GY - 2, 'clear', 0.5))
    return card_close(out)


CARDS = {}
for k in ('drip', 'pink', 'burnt', 'hum', 'blue', 'midoil'):
    CARDS['signs_' + k] = signs_card(k)
for k in ('core', 'coils', 'paper', 'oil', 'rotor', 'wire', 'water'):
    CARDS['inside_' + k] = inside_card(k)
for k in ('black', 'melt', 'bent', 'burst', 'yellow', 'straight', 'smooth'):
    CARDS['coil_' + k] = coil_card(k)
for k in ('report', 'gel', 'dga', 'poletank', 'dust', 'recharge', 'ignore'):
    CARDS['act_' + k] = act_card(k)

# Safe cards and traps per round (mirrors learn_board_pack61.dart).
ROUNDS = {
    'signs': (['signs_drip', 'signs_pink', 'signs_burnt'], ['signs_hum', 'signs_blue', 'signs_midoil']),
    'inside': (['inside_core', 'inside_coils', 'inside_paper', 'inside_oil'], ['inside_rotor', 'inside_wire', 'inside_water']),
    'coil': (['coil_black', 'coil_melt', 'coil_bent', 'coil_burst'], ['coil_yellow', 'coil_straight', 'coil_smooth']),
    'act': (['act_report', 'act_gel', 'act_dga'], ['act_poletank', 'act_dust', 'act_recharge', 'act_ignore']),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old[:-4] not in CARDS:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
