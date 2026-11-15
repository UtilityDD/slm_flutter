"""Picture cards for lesson 6.4 শেখা ("AB সুইচ ও আইসোলেটর: ট্র্যাফিক কন্ট্রোলার").

python -I tool/m6_board64_art.py .

Writes assets/game/art/m6_board64/*.svg in the clean gradient style of
tool/m5_board55_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 6.4 (item spec
docs/module_specs/module6_items/board_64.json, Module 6 rulings M6-1, M6-3, X3):
  1. gap (close-up of a three-phase AB head): an open isolator shows its gap
     to the naked eye — a tilting AB with all three posts tilted away from
     their jaws, or a vertical-break AB with all three blades lifted. Traps:
     the same AB closed, a breaker tank (its state can't be seen), and two
     blades open with the middle phase still in its jaw (pro tip 4);
  2. open (the AB on its DP structure, the operating handle at the pole, a
     small inset of the substation breaker with its two lamps — red lit =
     ON, green lit = OFF — and the houses it feeds): the breaker is OFF
     (green lamp, houses dark) and the worker takes the handle; or the
     breaker is still ON and he keeps his hands off the handle and phones
     first. Traps: opening with the breaker ON (a long arc on every phase),
     the breaker's lamp says OFF (green) but one house still has its lamp
     on — the line still carries load — and he pulls anyway; and, the
     breaker ON, hurrying to the handle to stop a downstream fault (sparks
     on a fallen wire; he reaches for the handle, not yet on it);
  3. close: the AB closed while the breaker is OFF (green lamp, a firm
     stroke), or all three phases fully home and only then the breaker ON
     (red lamp, houses lit, the worker looking up at the blades). Traps:
     closing with the breaker ON (a flash at the jaws), one blade half seated
     (glowing hot, pro tip 2), the handle stopped halfway (ruling M6-3: only
     a stalled stroke is wrong, never speed);
  4. earth: the handle's earth lead clamped and running to its earth, the
     worker on the ground with both hands on the handle. Traps: the lead
     cut and hanging, the clamp off with its bolt on the ground, a worker
     up at the switch head pushing a blade of the closed (live) switch by
     hand — drawn in a full-body harness (ruling X7), so the act itself is
     the error;
  5. care (close-up, as a patrol sees it): clean jaws with the blades fully
     home, or contacts with small arcing horns and clean insulators. Traps:
     blackened jaws with arcing marks, insulators crusted with dirt, a stiff
     rusty linkage that won't turn.

The lamp colours never give the safe card away, either way round: a safe
card shows the red lamp lit too (round 2: on the phone before the breaker is
off; round 3: the breaker back ON once the AB is fully home), and a trap shows
the green lamp lit too (round 2: OFF, but a house still lit; round 3: the
stalled stroke). In both rounds every lamp state a safe card shows is shown by
a trap in every hand. Nor does the pose: in round 2 one trap's worker is not
yet on the handle either.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board64_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board64')
W, H = 200, 220
GY = 198

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
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
EARTHW = '#3E9B4F'
EARTH_Y = '#E8C830'
PAPER = '#F4F1E6'
INK = '#4A5560'
BAG = '#6B5B3E'
RUST = '#9A5A2A'
SOOT = '#1E1A17'
WIN_DIM = '#8C6A2A'
WIN_LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
MOVE = '#FFFFFF'
LAMP_R = '#D8402F'
LAMP_G = '#2FB45A'
GRIP = '#C8352B'
HARNESS = '#F08A24'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="ins" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AA"/><stop offset="0.45" stop-color="#F2F4F5"/><stop offset="1" stop-color="#8E989E"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7E8A92"/><stop offset="0.5" stop-color="#B8C2C8"/><stop offset="1" stop-color="#6E7A82"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="arc" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#BFE6FF"/><stop offset="1" stop-color="#6FC3FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4B0"/><stop offset="0.35" stop-color="#FF9A2E"/><stop offset="1" stop-color="#E2402A" stop-opacity="0"/></radialGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='day'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def rot(p, c, deg):
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


# --------------------------------------------------------------------------
# The worker (from tool/m5_board55_art.py: blue shirt, helmet, rubber gloves).
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


S = 1.3  # the worker's scale


def person(x, hands_world, face=-1, look=0, gy=GY, props=''):
    """A standing worker at x (feet on gy), scaled S about the feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}{props}</g>'


def head_of(x, face=-1, gy=GY):
    return (x + 3 * face * S, gy - 64 * S)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def insulator(cx, base, height, w=7.0, shed=8.0):
    """A post insulator standing on (cx, base): core, sheds, steel cap."""
    top = base - height
    o = [f'<rect x="{f(cx - w / 2)}" y="{f(top + 3)}" width="{f(w)}" height="{f(height - 3)}" fill="url(#ins)"/>']
    n = max(3, int(height / 7))
    for i in range(n):
        y = top + 6 + i * (height - 9) / max(1, n - 1)
        o.append(f'<ellipse cx="{f(cx)}" cy="{f(y)}" rx="{f(shed)}" ry="{f(shed * 0.3)}" fill="url(#ins)"/>')
    o.append(f'<rect x="{f(cx - w / 2 - 1.5)}" y="{f(top - 1)}" width="{f(w + 3)}" height="4.5" rx="1" fill="url(#steel)"/>')
    o.append(f'<rect x="{f(cx - w / 2 - 2)}" y="{f(base - 3)}" width="{f(w + 4)}" height="3" fill="url(#steel)"/>')
    return ''.join(o)


def blade(p, length, deg, thick=4.0):
    """The switch blade from its hinge p, turned deg (0 = level, into the jaw;
    negative = lifted)."""
    x, y = p
    return (f'<g transform="rotate({f(deg)} {f(x)} {f(y)})"><rect x="{f(x - 2)}" y="{f(y - thick / 2)}" width="{f(length + 2)}" '
            f'height="{f(thick)}" rx="{f(thick / 2)}" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/></g>')


def jaw(x, y, s=1.0):
    """The fixed jaw (two spring fingers and a back plate) at (x, y)."""
    return (f'<rect x="{f(x - 6 * s)}" y="{f(y - 6 * s)}" width="{f(9 * s)}" height="{f(2.4 * s)}" rx="1" fill="url(#steel)" stroke="{INK}" stroke-width="0.4"/>'
            f'<rect x="{f(x - 6 * s)}" y="{f(y + 3.6 * s)}" width="{f(9 * s)}" height="{f(2.4 * s)}" rx="1" fill="url(#steel)" stroke="{INK}" stroke-width="0.4"/>'
            f'<rect x="{f(x + 2 * s)}" y="{f(y - 6 * s)}" width="{f(2.6 * s)}" height="{f(12 * s)}" rx="1" fill="url(#steel)"/>')


def horns(hx, jx, y, s=1.0):
    """Small arcing horns on the blade end and the jaw (a V of thin rods)."""
    return (f'<path d="M{f(jx + 1 * s)} {f(y - 6 * s)} q{f(1 * s)} {f(-9 * s)} {f(-9 * s)} {f(-13 * s)}" stroke="url(#steel)" stroke-width="{f(1.6 * s)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(jx - 7 * s)} {f(y - 2 * s)} q{f(-2 * s)} {f(-8 * s)} {f(-11 * s)} {f(-10 * s)}" stroke="url(#steel)" stroke-width="{f(1.6 * s)}" fill="none" stroke-linecap="round"/>')


def arc_spark(x, y, r=13, n=2):
    """A bright arc: a blue-white glow with jagged white strokes."""
    o = [f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#arc)"/>']
    for i in range(n):
        dy = (i - (n - 1) / 2) * 4
        o.append(f'<path d="M{f(x - r * 0.6)} {f(y + dy)} l{f(r * 0.3)} -3 l{f(r * 0.25)} 5 l{f(r * 0.3)} -4 l{f(r * 0.3)} 3" '
                 f'stroke="{MOVE}" stroke-width="1.4" fill="none" stroke-linejoin="round"/>')
    return ''.join(o)


def heat(x, y, r=10):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#heat)"/>'


def motion(x, y, dx=0, dy=1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 4, py * (i - 1) * 4
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def strain(x, y):
    """Short strain marks round a part that won't move."""
    o = []
    for a in (-60, -20, 20, 60, 160, 200):
        p0 = rot((x + 9, y), (x, y), a)
        p1 = rot((x + 14, y), (x, y), a)
        o.append(f'<path d="M{f(p0[0])} {f(p0[1])} L{f(p1[0])} {f(p1[1])}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round">{"".join(o)}</g>'


def earth_lead(d):
    """The handle's earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{EARTHW}" stroke-width="3.4" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="3.4" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def house(x, w, h, win=WIN_DIM, gy=GY):
    top = gy - h
    o = [f'<rect x="{f(x)}" y="{f(top)}" width="{f(w)}" height="{f(h)}" fill="url(#house)"/>',
         f'<path d="M{f(x - 4)} {f(top + 1)} L{f(x + w / 2)} {f(top - h * 0.4)} L{f(x + w + 4)} {f(top + 1)} Z" fill="url(#roof)"/>',
         f'<rect x="{f(x + w * 0.18)}" y="{f(top + h * 0.25)}" width="{f(w * 0.3)}" height="{f(h * 0.3)}" fill="{win}"/>',
         f'<rect x="{f(x + w * 0.6)}" y="{f(gy - h * 0.6)}" width="{f(w * 0.24)}" height="{f(h * 0.6)}" fill="{BAG}"/>']
    if win == WIN_LIT:
        o.append(f'<circle cx="{f(x + w * 0.33)}" cy="{f(top + h * 0.4)}" r="{f(w * 0.32)}" fill="url(#glow)" opacity="0.85"/>')
    return ''.join(o)


def harness(x, gy, face):
    """A full-body harness in the figure's own (unscaled) coordinates:
    shoulder straps, chest strap, waist belt, leg loops, the back D-ring."""
    c = HARNESS
    o = [f'<path d="M{f(x - 5)} {f(gy - 55)} L{f(x - 4)} {f(gy - 31)} M{f(x + 5)} {f(gy - 55)} L{f(x + 4)} {f(gy - 31)}" '
         f'stroke="{c}" stroke-width="2" fill="none" stroke-linecap="round"/>',
         f'<path d="M{f(x - 6)} {f(gy - 46)} L{f(x + 6)} {f(gy - 46)}" stroke="{c}" stroke-width="1.8" stroke-linecap="round"/>',
         f'<rect x="{f(x - 8)}" y="{f(gy - 34)}" width="16" height="3" rx="1" fill="{c}"/>',
         f'<path d="M{f(x - 6)} {f(gy - 31)} q-2 6 2 8 M{f(x + 6)} {f(gy - 31)} q2 6 -2 8" stroke="{c}" stroke-width="1.8" fill="none" stroke-linecap="round"/>',
         f'<circle cx="{f(x - 6 * face)}" cy="{f(gy - 52)}" r="1.8" fill="none" stroke="url(#steel)" stroke-width="1.2"/>']
    return ''.join(o)


def phone(x, y):
    return f'<rect x="{f(x - 2)}" y="{f(y - 5)}" width="4.6" height="9" rx="1.2" fill="{WIRE}" transform="rotate(-18 {f(x)} {f(y)})"/>'


# --------------------------------------------------------------------------
# Close-up stage (rounds 1 and 5): the three-phase AB head on its crossarm.
# --------------------------------------------------------------------------

CX = (38, 100, 162)
ARM = 150        # crossarm top
POST = 62        # post height
HALF = 19        # hinge / jaw post offset from the phase centre
TOP = ARM - POST - 4


def closeup_stage():
    out = card_open()
    out.append(f'<rect y="192" width="{W}" height="{H - 192}" fill="url(#ground)"/>')
    out.append(f'<rect x="3" y="120" width="10" height="{H - 120}" fill="url(#pole)"/>')
    out.append(f'<rect x="187" y="120" width="10" height="{H - 120}" fill="url(#pole)"/>')
    out.append(f'<rect x="0" y="{ARM}" width="{W}" height="9" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    return out


def linkage(out, rust=False):
    """The common operating rod under the arm and the down-rod to the handle."""
    out.append(f'<rect x="14" y="{ARM + 13}" width="172" height="3.2" rx="1.4" fill="url(#steel)" stroke="{INK}" stroke-width="0.4"/>')
    out.append(f'<rect x="15" y="{ARM + 13}" width="3.4" height="{H - ARM - 13}" fill="url(#steel)" stroke="{INK}" stroke-width="0.4"/>')
    for cx in CX:
        hx = cx - HALF
        out.append(f'<rect x="{f(hx - 2)}" y="{ARM + 8}" width="4" height="8" fill="url(#steel)"/>')
        out.append(f'<circle cx="{f(hx)}" cy="{ARM + 14.6}" r="3" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    if rust:
        for cx in CX:
            hx = cx - HALF
            out.append(f'<circle cx="{f(hx)}" cy="{ARM + 14.6}" r="4.2" fill="{RUST}" opacity="0.85"/>')
            out.append(f'<path d="M{f(hx - 9)} {ARM + 14.6} h8 M{f(hx + 3)} {ARM + 15} h9" stroke="{RUST}" stroke-width="2.6" opacity="0.8"/>')
        out.append(f'<circle cx="16.7" cy="{ARM + 15}" r="4.4" fill="{RUST}" opacity="0.85"/>')
        out.append(f'<path d="M16.7 {ARM + 24} v26" stroke="{RUST}" stroke-width="3" opacity="0.7"/>')


def phase(out, cx, state='closed', tilt=0.0, lift=0.0, horn=False, soot=False, dirt=False):
    """One phase: hinge post with the blade, jaw post with the jaw.
    state: 'closed', 'tilt' (the hinge post tilted away, tilting type),
    'lift' (the blade lifted, vertical break)."""
    hx, jx = cx - HALF, cx + HALF
    base = (hx, ARM)
    # The jaw post, its jaw and the outgoing jumper.
    out.append(f'<path d="M{f(jx + 3)} {f(TOP + 2)} Q{f(jx + 16)} {f(TOP - 26)} {f(jx + 12)} 0" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
    out.append(insulator(jx, ARM, POST, 9, 10.5))
    out.append(jaw(jx, TOP, 1.25))
    # The hinge post (it tilts with its blade on a tilting AB).
    ang = -tilt if state == 'tilt' else 0.0
    top = rot((hx, TOP), base, ang)
    out.append(f'<path d="M{f(top[0] - 3)} {f(top[1] + 2)} Q{f(hx - 16)} {f(TOP - 26)} {f(hx - 12)} 0" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
    out.append(f'<g transform="rotate({f(ang)} {f(hx)} {f(ARM)})">{insulator(hx, ARM, POST, 9, 10.5)}</g>')
    deg = ang - (lift if state == 'lift' else 0.0)
    out.append(blade(top, HALF * 2 - 3, deg, 5.2))
    out.append(f'<circle cx="{f(top[0])}" cy="{f(top[1])}" r="3.8" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    if horn:
        out.append(horns(hx, jx, TOP, 1.3))
    if soot:
        out.append(f'<ellipse cx="{f(jx - 3)}" cy="{f(TOP)}" rx="11" ry="8" fill="{SOOT}" opacity="0.35"/>')
        for dx, dy, r in ((-8, -5, 2.6), (-3, 6, 2.2), (2, -7, 1.8), (-11, 3, 1.6), (4, 4, 2)):
            out.append(f'<circle cx="{f(jx + dx)}" cy="{f(TOP + dy)}" r="{r}" fill="{SOOT}" opacity="0.75"/>')
        out.append(f'<path d="M{f(jx - 12)} {f(TOP + 9)} l3 -4 M{f(jx + 5)} {f(TOP - 11)} l-2 4" stroke="{SOOT}" stroke-width="1.6" opacity="0.7"/>')
    if dirt:
        for i, dy in enumerate((12, 22, 32, 42, 52)):
            for px, w in ((hx, 8 + i % 2), (jx, 9 - i % 2)):
                out.append(f'<ellipse cx="{f(px + (2 if i % 2 else -2))}" cy="{f(TOP + 4 + dy)}" rx="{f(w)}" ry="3.2" fill="{BAG}" opacity="0.85"/>')


def gap_card(kind):
    if kind == 'breaker':
        # A breaker tank on its plinth: closed metal, a small round flag
        # window — nothing shows whether its contacts are apart.
        out = closeup_stage()
        out.append(f'<rect x="52" y="188" width="96" height="10" fill="url(#steel)"/>')
        out.append(f'<rect x="58" y="96" width="84" height="92" rx="6" fill="url(#tank)" stroke="{INK}" stroke-width="0.8"/>')
        for x in (76, 100, 124):
            out.append(insulator(x, 96, 34, 8, 8))
            out.append(f'<path d="M{x} 59 Q{x + 4} 30 {x + 2} 0" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
        out.append(f'<rect x="80" y="118" width="40" height="48" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<circle cx="100" cy="132" r="7.5" fill="{WIRE}"/><rect x="94" y="130" width="12" height="4.5" fill="{PAPER}"/>')
        out.append(f'<rect x="90" y="148" width="20" height="10" rx="2" fill="url(#steel)"/>')
        return card_close(out)
    out = closeup_stage()
    linkage(out)
    for i, cx in enumerate(CX):
        if kind == 'tilt':
            phase(out, cx, 'tilt', tilt=28)
        elif kind == 'lift':
            phase(out, cx, 'lift', lift=70)
        elif kind == 'closed':
            phase(out, cx, 'closed')
        elif kind == 'stuck':
            phase(out, cx, 'closed' if i == 1 else 'lift', lift=70)
    return card_close(out)


def care_card(kind):
    out = closeup_stage()
    linkage(out, rust=kind == 'jam')
    for cx in CX:
        phase(out, cx, 'closed', horn=kind == 'horns', soot=kind == 'black', dirt=kind == 'dirty')
    if kind == 'jam':
        out.append(strain(16.7, ARM + 15))
        out.append(strain(CX[0] - HALF, ARM + 14.6))
    return card_close(out)


# --------------------------------------------------------------------------
# Field stage (rounds 2–4): the AB on its DP structure, the handle at the
# pole, the houses it feeds and (rounds 2–3) the substation breaker inset.
# --------------------------------------------------------------------------

FCX = (64, 100, 136)
FARM = 52
FPOST = 18
FHALF = 11
FTOP = FARM - FPOST - 3
PIV = (40, 133)          # handle pivot on the pole
LEVER = 22
CLAMP_AT = (38, 147)


def lever_end(deg):
    return rot((PIV[0] + LEVER, PIV[1]), PIV, deg)


def field_stage(wins=(WIN_DIM, WIN_DIM)):
    out = card_open()
    out.append(f'<rect y="172" width="{W}" height="{H - 172}" fill="url(#ground)"/>')
    out.append(house(116, 34, 30, wins[0], 174))
    out.append(house(156, 34, 34, wins[1], 174))
    out.append(f'<path d="M200 70 Q182 104 173 {174 - 34 * 0.8}" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    out.append(f'<rect x="25" y="12" width="9" height="{176 - 12}" fill="url(#pole)"/>')
    out.append(f'<rect x="166" y="12" width="9" height="{174 - 12}" fill="url(#pole)"/>')
    out.append(f'<rect x="18" y="{FARM}" width="164" height="6" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    # The down-rod from the switch to the handle's gearbox.
    out.append(f'<rect x="35" y="{FARM + 6}" width="3" height="{PIV[1] - FARM - 10}" fill="url(#steel)" stroke="{INK}" stroke-width="0.3"/>')
    out.append(f'<rect x="31" y="{PIV[1] - 8}" width="12" height="16" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    return out


def field_phases(out, deg=0.0, only=None, hot=False):
    """The three phases; deg lifts the blades (negative = open), [only]
    = (phase index, deg) for one phase that differs."""
    for i, cx in enumerate(FCX):
        hx, jx = cx - FHALF, cx + FHALF
        out.append(f'<path d="M{f(jx + 2)} {f(FTOP + 1)} Q{f(jx + 8)} {f(FTOP - 14)} {f(jx + 6)} 0" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M{f(hx - 2)} {f(FTOP + 1)} Q{f(hx - 8)} {f(FTOP - 14)} {f(hx - 6)} 0" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
        out.append(insulator(hx, FARM, FPOST, 4.5, 5))
        out.append(insulator(jx, FARM, FPOST, 4.5, 5))
        out.append(jaw(jx, FTOP, 0.6))
        d = only[1] if only and only[0] == i else deg
        out.append(blade((hx, FTOP), FHALF * 2 - 2, d, 2.8))
        if hot and only and only[0] == i:
            tip = rot((hx + FHALF * 2 - 2, FTOP), (hx, FTOP), d)
            out.append(heat(tip[0], tip[1], 9))


def field_arcs(out, deg, r=12):
    for cx in FCX:
        hx = cx - FHALF
        tip = rot((hx + FHALF * 2 - 2, FTOP), (hx, FTOP), deg)
        jx = cx + FHALF
        out.append(arc_spark((tip[0] + jx) / 2, (tip[1] + FTOP) / 2, r))


def handle(out, deg):
    e = lever_end(deg)
    out.append(f'<path d="M{PIV[0]} {PIV[1]} L{f(e[0])} {f(e[1])}" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/>')
    g = rot((PIV[0] + LEVER - 5, PIV[1]), PIV, deg)
    out.append(f'<path d="M{f(g[0])} {f(g[1])} L{f(e[0])} {f(e[1])}" stroke="{GRIP}" stroke-width="4.4" stroke-linecap="round"/>')
    out.append(f'<circle cx="{PIV[0]}" cy="{PIV[1]}" r="3" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    return e


def handle_earth(out, state='ok'):
    """The handle's earth lead: from its clamp on the gearbox bracket down the
    pole to the earth electrode. 'cut' = cut and hanging; 'off' = the clamp
    off its bracket, its bolt on the ground."""
    cx, cy = CLAMP_AT
    out.append(f'<rect x="{cx - 9}" y="{cy - 6}" width="9" height="4" fill="url(#steel)"/>')
    out.append(f'<rect x="42" y="187" width="9" height="5" rx="1" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    if state == 'ok':
        out.append(earth_lead(f'M{cx} {cy + 3} L{cx} 178 L46 188'))
        out.append(f'<rect x="{cx - 4}" y="{cy - 4}" width="8" height="8" rx="1.5" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="1.8" fill="{INK}"/>')
    elif state == 'cut':
        out.append(earth_lead(f'M{cx} {cy + 3} L{cx} 152 Q{cx + 2} 160 {cx + 12} 162'))
        out.append(f'<path d="M{cx + 12} 162 l3 2 M{cx + 12} 162 l3 -2" stroke="{EARTHW}" stroke-width="1.2" />')
        out.append(earth_lead(f'M{cx} 180 L46 188'))
        out.append(f'<path d="M{cx} 180 l-2 -3 M{cx} 180 l2 -3.5" stroke="{EARTHW}" stroke-width="1.2" />')
        out.append(f'<rect x="{cx - 4}" y="{cy - 4}" width="8" height="8" rx="1.5" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="1.8" fill="{INK}"/>')
    else:
        out.append(earth_lead(f'M{cx + 2} {cy + 12} L{cx + 2} 178 L46 188'))
        out.append(f'<rect x="{cx - 2}" y="{cy + 4}" width="8" height="8" rx="1.5" fill="url(#steel)" stroke="{INK}" stroke-width="0.6" transform="rotate(38 {cx + 2} {cy + 8})"/>')
        out.append(f'<circle cx="14" cy="192" r="2.8" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="16" y="191" width="7" height="2.2" fill="url(#steel)"/>')


def inset(out, on):
    """The substation breaker, inset: a small tank and its two lamps; red lit
    = ON, green lit = OFF (the other lamp dim)."""
    out.append(f'<rect x="144" y="70" width="50" height="36" rx="4" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<rect x="151" y="80" width="17" height="20" rx="2" fill="url(#tank)"/>')
    for x in (154, 159.5, 165):
        out.append(f'<rect x="{x - 1}" y="74" width="2" height="6" fill="url(#ins)"/>')
    for (y, col, lit) in ((82, LAMP_R, on), (96, LAMP_G, not on)):
        if lit:
            out.append(f'<circle cx="181" cy="{y}" r="8" fill="url(#glow)"/>')
        out.append(f'<circle cx="181" cy="{y}" r="4.2" fill="{col}" opacity="{1 if lit else 0.22}" stroke="{INK}" stroke-width="0.5"/>')


CLOSED, PULL, MID = -24, -10, 6   # handle angles: closed (lever up), starting a pull, halfway


def worker_at_handle(out, deg, look=-10):
    e = lever_end(deg)
    out.append(person(68, ((e[0] + 1, e[1] + 1), (e[0] - 3, e[1])), face=-1, look=look))


def open_card(kind):
    if kind == 'brkoff':
        out = field_stage((WIN_OFF, WIN_OFF))
        inset(out, on=False)
        field_phases(out, 0)
        handle(out, CLOSED)
        handle_earth(out)
        worker_at_handle(out, CLOSED, -16)
    elif kind == 'phone':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        field_phases(out, 0)
        handle(out, CLOSED)
        handle_earth(out)
        hx, hy = head_of(76)
        out.append(person(76, ((80, 168), (hx + 1, hy + 4)), face=-1, look=-20, props=''))
        out.append(phone(hx, hy + 2))
    elif kind == 'arc':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        field_phases(out, -26)
        field_arcs(out, -26, 14)
        handle(out, MID)
        handle_earth(out)
        worker_at_handle(out, MID, -6)
    elif kind == 'lamp':
        # The breaker's lamp says OFF, yet one house is still lit: the line
        # still carries load (fed some other way), and he pulls anyway.
        out = field_stage((WIN_LIT, WIN_OFF))
        inset(out, on=False)
        field_phases(out, 0)
        handle(out, PULL)
        handle_earth(out)
        worker_at_handle(out, PULL, -6)
    elif kind == 'fault':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        # A broken wire down the line, sparking on the ground.
        out.append(f'<path d="M175 40 Q186 120 182 182" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
        out.append(arc_spark(182, 182, 14, 2))
        field_phases(out, 0)
        e = handle(out, CLOSED)
        handle_earth(out)
        # Hurrying in to pull it: one arm stretched for the grip, not on it yet.
        out.append(person(86, ((e[0] + 8, e[1] + 1), (96, 170)), face=-1, look=-6))
        out.append(motion(104, 150, dx=1, dy=0, n=3, length=7))
    return card_close(out)


def close_card(kind):
    if kind == 'shut':
        out = field_stage((WIN_OFF, WIN_OFF))
        inset(out, on=False)
        field_phases(out, 0)
        handle(out, CLOSED)
        handle_earth(out)
        worker_at_handle(out, CLOSED, -16)
    elif kind == 'seated':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        field_phases(out, 0)
        handle(out, CLOSED)
        handle_earth(out)
        out.append(person(82, ((86, 168), (80, 112)), face=-1, look=-34))
    elif kind == 'flash':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        field_phases(out, -9)
        field_arcs(out, -9, 13)
        handle(out, CLOSED)
        handle_earth(out)
        worker_at_handle(out, CLOSED, -6)
    elif kind == 'half':
        out = field_stage((WIN_LIT, WIN_LIT))
        inset(out, on=True)
        field_phases(out, 0, only=(1, -14), hot=True)
        handle(out, CLOSED)
        handle_earth(out)
        out.append(person(82, ((86, 168), (80, 112)), face=-1, look=-34))
    elif kind == 'stall':
        out = field_stage((WIN_OFF, WIN_OFF))
        inset(out, on=False)
        field_phases(out, -36)
        handle(out, MID)
        handle_earth(out)
        worker_at_handle(out, MID, -16)
    return card_close(out)


def earth_card(kind):
    out = field_stage((WIN_DIM, WIN_DIM))
    field_phases(out, 0)
    if kind == 'lead':
        handle(out, CLOSED)
        handle_earth(out, 'ok')
        out.append(person(60, ((CLAMP_AT[0] + 6, CLAMP_AT[1] + 2), (CLAMP_AT[0] + 8, CLAMP_AT[1] + 8)), face=-1, look=26))
    elif kind == 'ground':
        handle(out, CLOSED)
        handle_earth(out, 'ok')
        worker_at_handle(out, CLOSED, -16)
    elif kind == 'cut':
        handle(out, CLOSED)
        handle_earth(out, 'cut')
        worker_at_handle(out, CLOSED, -16)
    elif kind == 'bolt':
        handle(out, CLOSED)
        handle_earth(out, 'off')
        worker_at_handle(out, CLOSED, -16)
    elif kind == 'head':
        # Up the pole at the switch head, pushing a blade by hand; the
        # handle below is left alone.
        handle(out, CLOSED)
        handle_earth(out, 'ok')
        for y in (92, 110, 128):
            out.append(f'<rect x="33" y="{y}" width="9" height="3" fill="url(#steel)"/>')
        hx = FCX[0] - FHALF
        # In a full-body harness (ruling X7), its lanyard looped round the
        # pole above him: the harness is right, the hand on the live blade
        # is not.
        out.append(person(44, ((hx + 6, FTOP - 1), (hx + 12, FTOP + 2)), face=1, look=-30, gy=92, props=harness(44, 92, 1)))
        out.append(f'<path d="M36.2 24.4 Q34 18 30 16" stroke="{HARNESS}" stroke-width="1.6" fill="none"/>')
        out.append(f'<ellipse cx="29.5" cy="16" rx="6.5" ry="2.2" fill="none" stroke="{HARNESS}" stroke-width="1.6"/>')
    return card_close(out)


CARDS = {
    'gap_tilt': gap_card('tilt'),
    'gap_lift': gap_card('lift'),
    'gap_closed': gap_card('closed'),
    'gap_breaker': gap_card('breaker'),
    'gap_stuck': gap_card('stuck'),
    'open_brkoff': open_card('brkoff'),
    'open_phone': open_card('phone'),
    'open_arc': open_card('arc'),
    'open_lamp': open_card('lamp'),
    'open_fault': open_card('fault'),
    'close_shut': close_card('shut'),
    'close_seated': close_card('seated'),
    'close_flash': close_card('flash'),
    'close_half': close_card('half'),
    'close_stall': close_card('stall'),
    'earth_lead': earth_card('lead'),
    'earth_ground': earth_card('ground'),
    'earth_cut': earth_card('cut'),
    'earth_bolt': earth_card('bolt'),
    'earth_head': earth_card('head'),
    'care_clean': care_card('clean'),
    'care_horns': care_card('horns'),
    'care_black': care_card('black'),
    'care_dirty': care_card('dirty'),
    'care_jam': care_card('jam'),
}

# Safe cards and traps per round (mirrors learn_board_pack64.dart).
ROUNDS = {
    'gap': (['gap_tilt', 'gap_lift'], ['gap_closed', 'gap_breaker', 'gap_stuck']),
    'open': (['open_brkoff', 'open_phone'], ['open_arc', 'open_lamp', 'open_fault']),
    'close': (['close_shut', 'close_seated'], ['close_flash', 'close_half', 'close_stall']),
    'earth': (['earth_lead', 'earth_ground'], ['earth_cut', 'earth_bolt', 'earth_head']),
    'care': (['care_clean', 'care_horns'], ['care_black', 'care_dirty', 'care_jam']),
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
