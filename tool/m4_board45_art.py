"""Picture cards for lesson 4.5 শেখা ("ট্রান্সফরমারের অয়েল লেভেল ও তাপমাত্রা পরীক্ষা").

python -I tool/m4_board45_art.py .

Writes assets/game/art/m4_board45/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the gauge's Max / normal / Min marks are told by tick colours.

What the cards show comes from lesson 4.5 and its film script only:
  1. level: the conservator's glass gauge — the oil should sit near the marked
     normal line; in heat the oil expands and the level rises (cold: falls);
     below Min is a serious danger sign — lower still and the winding comes
     out of the oil, cooling stops and the transformer burns;
  2. check: the level is read from a distance / from the ground, no shutdown
     needed; heat is measured from a distance with an infrared thermometer —
     no hand on the tank (film); going near a hot transformer is asking for
     danger;
  3. heat: a soft hum and mild warmth are normal, and a summer noon / peak
     load runs warmer; a boiling-oil sound / louder hum is overheating;
     creepers or dust on the cooling fins block the air;
  4. leak: oil leaking from a bushing gasket or the drain cock / valve is
     reported to the supervisor at once (the climb trap is drawn on a live
     transformer — house rule: no work on it before shutdown);
  5. topup: top-up only with the line shut down (the DO fuses hang open),
     with filtered new oil of the same grade; never engine oil, never wet oil.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; each round has exactly three traps, so every hand is one safe card
+ all three traps, and the script checks every colour or gradient a safe card
draws is drawn by a trap too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board45_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board45')
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
COPPER = '#D98A3D'
EARTH = '#3E9B4F'
FACE = '#1E2329'
FIN = '#5C7459'
OIL = '#D9A23A'
OIL_D = '#A8741E'
TICK_MAX = '#2B3138'
TICK_MIN = '#FF4B3E'
TICK_MID = '#FFFFFF'
LASER = '#FF4B3E'
HEAT = '#FF7A2E'
LEAF = '#3E8A3A'
LEAF_D = '#2C6A2A'
DUST = '#8C7A5C'
RAIN = '#9FD3FF'
SCREEN = '#9FD3FF'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="plinth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C2BEB4"/><stop offset="1" stop-color="#8F8B82"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="cons" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#627C60"/><stop offset="0.45" stop-color="#9CB798"/><stop offset="1" stop-color="#566E54"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#DDE8EE"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C7D4DC"/></linearGradient>
  <linearGradient id="oil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8B34A"/><stop offset="1" stop-color="#B9781E"/></linearGradient>
  <linearGradient id="inside" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2B3036"/><stop offset="1" stop-color="#3D444C"/></linearGradient>
  <linearGradient id="coil" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#B86A2A"/><stop offset="0.5" stop-color="#E39A52"/><stop offset="1" stop-color="#A65E22"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="drum" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1F4F9A"/><stop offset="0.5" stop-color="#3D79D2"/><stop offset="1" stop-color="#1B4688"/></linearGradient>
  <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="0.45" stop-color="#FFD84E"/><stop offset="1" stop-color="#FFD84E" stop-opacity="0"/></radialGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="hot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A"/><stop offset="0.45" stop-color="#FF7A2E" stop-opacity="0.75"/><stop offset="1" stop-color="#FF4B3E" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='sky'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The worker (copied from tool/m2_board28_art.py): one figure, any pose.
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


def _hand(p, bare=False, point=0):
    x, y = p
    c = SKIN if bare else GLOVE
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves (bare = no gloves)."""
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face)
    kf = _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, kf, ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, SHIRT_D, 5.4))
    g.append(_hand(hb, bare, point[0]))
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
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0)):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def worker_on(x, gy, hands_world, face=-1, look=0, bare=False, point=(0, 0)):
    """worker() with his feet on any floor line gy (e.g. the tank lid)."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point)
    return f'<g transform="translate({f(x)} {gy}) scale({S}) translate({f(-x)} -{gy})">{fig}</g>'


def head_at(x, face=-1, gy=GY):
    """Where the worker's head is drawn in card coordinates."""
    return (x + 3 * face * S, gy - 64 * S)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def sun(x=30, y=30, r=22):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#sun)"/><circle cx="{x}" cy="{y}" r="{f(r * 0.42)}" fill="#FFD84E"/>'


def hum(x, y, n=2, loud=False, side=1):
    """Hum arcs beside the tank; loud = thick, many."""
    o = []
    w = 2.6 if loud else 1.4
    op = 0.95 if loud else 0.6
    for i in range(n):
        r = 6 + i * 6
        o.append(f'<path d="M{f(x + side * r * 0.5)} {f(y - r)} Q{f(x + side * r * 1.1)} {y} {f(x + side * r * 0.5)} {f(y + r)}" '
                 f'stroke="#FFFFFF" stroke-width="{w}" fill="none" stroke-linecap="round" opacity="{op}"/>')
    return ''.join(o)


def shimmer(x0, x1, y, n=3):
    o = []
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        o.append(f'<path d="M{f(x)} {y} q-4 -6 0 -12 q4 -6 0 -12" stroke="{HEAT}" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.85"/>')
    return ''.join(o)


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def drops(x, y0, n=3, gap=7, col=OIL, r=1.8):
    return ''.join(f'<ellipse cx="{f(x)}" cy="{f(y0 + i * gap)}" rx="{f(r * 0.8)}" ry="{f(r * 1.2)}" fill="{col}"/>' for i in range(n))


def gauge(x, y, w, h, level, ticks=True):
    """The conservator's glass level gauge: a tube (x, y, w, h); level 0..1
    from the bottom (None = empty). Ticks: Max (dark) at the top, the normal
    mark (white) near the middle, Min (red) near the bottom."""
    o = [f'<rect x="{f(x - 1.5)}" y="{f(y - 1.5)}" width="{f(w + 3)}" height="{f(h + 3)}" rx="{f(w / 2 + 1.5)}" fill="{WIRE}"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(w / 2)}" fill="url(#glass)"/>']
    if level is not None and level > 0:
        top = y + h * (1 - level)
        o.append(f'<rect x="{f(x + 1)}" y="{f(top)}" width="{f(w - 2)}" height="{f(y + h - top - 1)}" rx="{f(min(w / 2 - 1, (y + h - top) / 2))}" fill="url(#oil)"/>')
        o.append(f'<path d="M{f(x + 1)} {f(top)} L{f(x + w - 1)} {f(top)}" stroke="{OIL_D}" stroke-width="{f(max(0.8, w / 10))}"/>')
    if ticks:
        tl = w * 0.7 + 2
        for frac, col in ((MAXF, TICK_MAX), (MIDF, TICK_MID), (MINF, TICK_MIN)):
            ty = y + h * (1 - frac)
            o.append(f'<path d="M{f(x - tl)} {f(ty)} L{f(x + w * 0.35)} {f(ty)}" stroke="{col}" stroke-width="{f(max(1.2, w / 7))}" stroke-linecap="round"/>')
    return ''.join(o)


MAXF, MIDF, MINF = 0.86, 0.55, 0.22
LEVEL = {'mark': 0.55, 'warm': 0.68, 'low': 0.14, 'empty': None, 'leak': 0.16}


# --------------------------------------------------------------------------
# The yard: a plinth-mounted distribution transformer (main tank, cooling
# fins, conservator with its gauge, HT bushings) fed from a pole at the left
# through three DO fuses; earthed.
# --------------------------------------------------------------------------

TK = (40, 122, 80, 64)     # tank x, y, w, h
CONS = (88, 94, 40, 14)    # conservator x, y, w, h
GAUGE = (129, 88, 6, 24)
BUSH = (52, 66, 80)


def do_fuses(closed=True, x0=26, y=24, step=14):
    o = [f'<rect x="7" y="4" width="7" height="{GY - 4}" fill="url(#steel)"/>',
         f'<rect x="0" y="{y - 4}" width="{x0 + 2 * step + 10}" height="4" fill="#6F7880"/>']
    for i in range(3):
        x = x0 + i * step
        o.append(f'<rect x="{x - 2.5}" y="{y}" width="5" height="6" rx="1" fill="url(#porcelain)"/>')
        if closed:
            o.append(f'<rect x="{x - 2}" y="{y + 6}" width="4" height="16" rx="1.5" fill="{WIRE}"/>')
        else:
            o.append(f'<rect x="{x - 2}" y="{y + 6}" width="4" height="16" rx="1.5" fill="{WIRE}" transform="rotate(150 {x} {y + 22})"/>')
        o.append(f'<rect x="{x - 2.5}" y="{y + 22}" width="5" height="6" rx="1" fill="url(#porcelain)"/>')
    return ''.join(o)


def transformer(level=0.55, fins='clean', closed=True, leak=None, glow=False):
    x, y, w, h = TK
    o = [f'<rect x="24" y="{y + h}" width="112" height="{GY - y - h}" fill="url(#plinth)"/>']
    # Cooling fins, both sides.
    for fx in (28, w + x):
        o.append(f'<rect x="{fx}" y="{y + 6}" width="12" height="{h - 12}" rx="1.5" fill="{FIN}"/>')
        o += [f'<path d="M{fx + 2 + i * 2.7} {y + 8} L{fx + 2 + i * 2.7} {y + h - 8}" stroke="#93AE8F" stroke-width="1"/>' for i in range(4)]
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#tank)"/>')
    o.append(f'<rect x="{x - 3}" y="{y - 4}" width="{w + 6}" height="5" rx="1.5" fill="url(#cons)"/>')
    # The conservator on its leg, gauge at its right end.
    cx, cy, cw, ch = CONS
    o.append(f'<rect x="{cx + 14}" y="{cy + ch}" width="5" height="{y - 4 - cy - ch}" fill="{FIN}"/>')
    o.append(f'<path d="M{cx + 6} {cy + ch} L{cx - 4} {y - 4}" stroke="{FIN}" stroke-width="2.4"/>')
    o.append(f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" rx="{ch / 2}" fill="url(#cons)"/>')
    gx, gy, gw, gh = GAUGE
    o.append(gauge(gx, gy, gw, gh, level, ticks=True))
    # HT bushings and their drops from the DO fuses.
    for i, bx in enumerate(BUSH):
        o.append(f'<path d="M{bx - 4} {y - 4} L{bx + 4} {y - 4} L{bx + 2} {y - 20} L{bx - 2} {y - 20} Z" fill="url(#porcelain)"/>')
        o.append(f'<path d="M{bx} {y - 21} Q{bx - 6} {y - 50} {26 + i * 14} 52" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    # Earthing: tank to the ground.
    o.append(f'<path d="M{x + w - 4} {y + h - 6} L{x + w + 18} {y + h - 6} L{x + w + 18} {GY + 8}" stroke="{EARTH}" stroke-width="2.2" fill="none"/>')
    # Drain cock at the front bottom.
    o.append(f'<rect x="{x + 12}" y="{y + h - 9}" width="9" height="5" rx="1.5" fill="url(#steel)"/><rect x="{x + 14.5}" y="{y + h - 4}" width="4" height="4" fill="url(#steel)"/>')
    if fins == 'vines':
        for fx in (28, w + x):
            for j in range(6):
                lx, ly = fx + 6 + (3 if j % 2 else -3), y + 10 + j * 9
                o.append(f'<ellipse cx="{lx}" cy="{ly}" rx="6" ry="3.6" fill="{LEAF if j % 2 else LEAF_D}" transform="rotate({35 if j % 2 else -35} {lx} {ly})"/>')
            o.append(f'<path d="M{fx + 6} {y + h} Q{fx + 1} {y + 40} {fx + 8} {y + 6}" stroke="{LEAF_D}" stroke-width="1.6" fill="none"/>')
    elif fins == 'dust':
        for fx in (28, w + x):
            o.append(f'<rect x="{fx - 1}" y="{y + 5}" width="14" height="{h - 10}" rx="2" fill="{DUST}" opacity="0.85"/>')
            o += [f'<circle cx="{fx + 2 + (j * 5) % 11}" cy="{y + 12 + j * 7}" r="2.4" fill="#6E5F46"/>' for j in range(7)]
    if leak == 'drain':
        o.append(drops(x + 16.5, y + h + 3, 2, 5))
        o.append(f'<ellipse cx="{x + 17}" cy="{GY - 1}" rx="10" ry="2" fill="{OIL_D}"/>')
    elif leak == 'bush':
        bx = BUSH[1]
        o.append(f'<path d="M{bx + 3} {y - 3} q2 10 0 22 q-2 12 1 26" stroke="{OIL_D}" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
        o.append(drops(bx + 4, y + h + 3, 2, 5))
        o.append(f'<ellipse cx="{bx + 4}" cy="{GY - 1}" rx="10" ry="2" fill="{OIL_D}"/>')
    if glow:
        o.append(f'<ellipse cx="{x + w / 2}" cy="{y + h / 2}" rx="{w * 0.75}" ry="{h * 0.7}" fill="url(#hot)" opacity="0.7"/>')
    return do_fuses(closed) + ''.join(o)


def yard(**kw):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    if kw.pop('sunny', False):
        out.append(sun(176, 28, 20))
    out.append(transformer(**kw))
    return out


def ir_gun(x, y):
    """An infrared thermometer held at (x, y), aimed left."""
    return (f'<path d="M{f(x - 10)} {f(y - 4)} L{f(x + 6)} {f(y - 4)} L{f(x + 6)} {f(y + 3)} L{f(x + 2)} {f(y + 3)} L{f(x + 4)} {f(y + 12)} '
            f'L{f(x - 1)} {f(y + 12)} L{f(x - 3)} {f(y + 3)} L{f(x - 10)} {f(y + 3)} Z" fill="{FACE}"/>'
            f'<rect x="{f(x - 6)}" y="{f(y - 3)}" width="6" height="3" rx="0.8" fill="{SCREEN}"/>')


def phone(x, y):
    return f'<rect x="{f(x - 2.6)}" y="{f(y - 5)}" width="5.2" height="10" rx="1.2" fill="{FACE}"/><rect x="{f(x - 1.6)}" y="{f(y - 3.6)}" width="3.2" height="6.4" fill="{SCREEN}"/>'


def spanner(x, y, rot=-30):
    return (f'<g transform="rotate({rot} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 1.6)}" width="16" height="3.2" rx="1.2" fill="url(#steel)"/>'
            f'<path d="M{f(x - 6)} {f(y - 4.4)} L{f(x)} {f(y - 4.4)} L{f(x)} {f(y + 4.4)} L{f(x - 6)} {f(y + 4.4)} L{f(x - 6)} {f(y + 1.6)} L{f(x - 3)} {f(y + 1.6)} L{f(x - 3)} {f(y - 1.6)} L{f(x - 6)} {f(y - 1.6)} Z" fill="url(#steel)"/></g>')


def bucket(x, y, w=18, h=16):
    return (f'<path d="M{x} {y} L{x + w} {y} L{x + w - 2.5} {y + h} L{x + 2.5} {y + h} Z" fill="url(#steel)"/>'
            f'<ellipse cx="{x + w / 2}" cy="{y}" rx="{w / 2}" ry="2.4" fill="url(#oil)"/>'
            f'<path d="M{x} {y} Q{x + w / 2} {y - 12} {x + w} {y}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')


# --------------------------------------------------------------------------
# Round 1 — level: the gauge close up, with a cut-away of the main tank.
# --------------------------------------------------------------------------

def level_card(kind):
    out = card_open('sky')
    lv = LEVEL[kind]
    if kind in ('warm', 'low'):
        out.append(sun(30, 26, 22))
    # Conservator (big) and its gauge at the right end.
    out.append('<rect x="-20" y="38" width="160" height="44" rx="22" fill="url(#cons)"/>')
    out.append('<rect x="58" y="82" width="10" height="20" fill="url(#cons)"/>')
    out.append(gauge(152, 18, 22, 84, lv))
    out.append('<path d="M140 50 L152 50 M140 70 L152 70" stroke="#566E54" stroke-width="4"/>')
    # The main tank with a cut-away: oil, core and winding.
    out.append('<rect x="-4" y="102" width="208" height="130" rx="4" fill="url(#tank)"/>')
    out.append('<rect x="22" y="114" width="156" height="98" rx="6" fill="url(#inside)"/>')
    oil_top = {'mark': 118, 'warm': 117, 'low': 121, 'leak': 121, 'empty': 150}[kind]
    out.append(f'<rect x="24" y="{oil_top}" width="152" height="{212 - oil_top - 2}" rx="4" fill="url(#oil)" opacity="0.85"/>')
    out.append(f'<path d="M24 {oil_top} L176 {oil_top}" stroke="{OIL_D}" stroke-width="1.6"/>')
    out.append('<rect x="56" y="128" width="88" height="8" fill="url(#steel)"/><rect x="56" y="196" width="88" height="8" fill="url(#steel)"/>')
    for cxw in (70, 100, 130):
        out.append(f'<rect x="{cxw - 11}" y="136" width="22" height="60" rx="4" fill="url(#coil)"/>')
        out += [f'<path d="M{cxw - 11} {140 + i * 6} L{cxw + 11} {140 + i * 6}" stroke="#8A4E1A" stroke-width="1"/>' for i in range(10)]
    if kind == 'empty':
        out.append('<ellipse cx="100" cy="140" rx="64" ry="18" fill="url(#hot)"/>')
        out.append(shimmer(60, 140, 138, 4))
    if kind == 'leak':
        out.append(f'<rect x="10" y="206" width="12" height="6" rx="1.5" fill="url(#steel)"/>')
        out.append(drops(14, 214, 1, 6, OIL, 2.4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — check: read the gauge from the ground, measure heat from afar.
# --------------------------------------------------------------------------

def check_card(kind):
    if kind == 'ground':
        out = yard()
        out.append(worker(172, ((166, 160), (150, 116)), face=-1, look=-14, point=(0, -1)))
    elif kind == 'ir':
        out = yard()
        hx, hy = 152, 140
        out.append(worker(172, ((166, 160), (hx + 2, hy + 2)), face=-1, look=-4))
        out.append(ir_gun(hx, hy))
        out.append(f'<path d="M{hx - 10} {hy - 1} L{TK[0] + TK[2] - 6} 152" stroke="{LASER}" stroke-width="1" stroke-dasharray="3 2"/>')
        out.append(f'<circle cx="{TK[0] + TK[2] - 6}" cy="152" r="2" fill="{LASER}"/>')
    elif kind == 'hand':
        out = yard()
        out.append(shimmer(48, 112, 116, 3))
        out.append(worker(146, ((134, 150), (124, 146)), face=-1, look=4))
        out.append(f'<circle cx="124" cy="146" r="9" fill="url(#hot)"/>')
        out.append(ir_gun(160, GY - 2))
    elif kind == 'ear':
        out = yard()
        out.append(shimmer(48, 112, 116, 3))
        out.append(hum(TK[0] + TK[2] + 12, 150, 3, loud=True))
        out.append(worker(140, ((128, 150), (126, 136)), face=-1, look=18))
    elif kind == 'climb':
        out = yard()
        out.append(worker_on(112, TK[1] - 3, ((124, 94), (132, 98)), face=1, look=8))
        out.append(ir_gun(176, GY - 2))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — heat: what is normal running, what is overheating.
# --------------------------------------------------------------------------

def heat_card(kind):
    if kind == 'hum':
        out = yard()
        out.append(hum(TK[0] + TK[2] + 14, 150, 2))
    elif kind == 'noon':
        out = yard(sunny=True)
        out.append(hum(TK[0] + TK[2] + 14, 150, 2))
    elif kind == 'boil':
        out = yard(glow=True, level=0.3)
        out.append(hum(TK[0] + TK[2] + 14, 150, 4, loud=True))
        out.append(hum(TK[0] - 14, 150, 4, loud=True, side=-1))
        out.append(shimmer(46, 114, 114, 4))
        out += [f'<circle cx="{132}" cy="{100 - i * 7}" r="{1.4 + i * 0.5}" fill="none" stroke="#FFFFFF" stroke-width="1"/>' for i in range(3)]
    elif kind == 'vines':
        out = yard(fins='vines', sunny=True)
        out.append(hum(TK[0] + TK[2] + 14, 150, 2))
        out.append(shimmer(46, 114, 114, 2))
    elif kind == 'dust':
        out = yard(fins='dust')
        out.append(hum(TK[0] + TK[2] + 14, 150, 2))
        out.append(shimmer(46, 114, 114, 2))
    out.append(worker(176, ((170, 160), (168, 156)), face=-1, look=-6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — leak: oil from the drain cock or a bushing -> report at once.
# --------------------------------------------------------------------------

def leak_card(kind):
    hx, hy = head_at(168)
    if kind == 'call_drain':
        out = yard(level=0.16, leak='drain')
        out.append(worker(168, ((160, 162), (hx - 4, hy + 2)), face=-1, look=-4))
        out.append(phone(hx - 4, hy + 2))
    elif kind == 'call_bush':
        out = yard(level=0.16, leak='bush')
        out.append(worker(168, ((160, 162), (hx - 4, hy + 2)), face=-1, look=-4))
        out.append(phone(hx - 4, hy + 2))
    elif kind == 'ignore':
        out = yard(level=0.16, leak='drain')
        out.append(worker(170, ((178, 162), (184, 146)), face=1, look=20))
        out.append(phone(185, 144))
    elif kind == 'bucket':
        out = yard(level=0.16, leak='drain')
        out.append(bucket(48, GY - 14))
        out.append(worker(176, ((170, 160), (182, 162)), face=1, look=0))
    elif kind == 'climb':
        out = yard(level=0.16, leak='bush')
        bx = BUSH[1]
        out.append(worker_on(88, TK[1] - 3, ((96, 100), (bx + 6, TK[1] - 10)), face=-1, look=10))
        out.append(spanner(bx + 6, TK[1] - 10, -150))
        out.append(phone(180, GY + 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — topup: line shut down, filtered new oil of the same grade.
# --------------------------------------------------------------------------

def arm(hand, base=(212, 40)):
    """A gloved arm reaching in from the right edge."""
    return (f'<path d="M{base[0]} {base[1]} L{f(hand[0] + 6)} {f(hand[1] + 2)}" stroke="{SHIRT}" stroke-width="14" stroke-linecap="round"/>'
            f'<circle cx="{f(hand[0])}" cy="{f(hand[1])}" r="7.5" fill="{GLOVE}"/>')


def can(x, y, kind='new'):
    """A can tilted to pour, its spout at (x, y)."""
    if kind == 'new':
        body = (f'<rect x="{x + 8}" y="{y - 6}" width="34" height="26" rx="4" fill="url(#drum)"/>'
                f'<rect x="{x + 16}" y="{y + 2}" width="18" height="9" rx="2" fill="url(#steel)"/>')
    elif kind == 'engine':
        body = (f'<rect x="{x + 8}" y="{y - 6}" width="34" height="26" rx="4" fill="{FACE}"/>'
                f'<path d="M{x + 15} {y + 9} l3 -5 l12 0 l3 5 l2 0 l0 4 l-22 0 l0 -4 Z" fill="#FFFFFF"/>'
                f'<circle cx="{x + 19}" cy="{y + 13}" r="2" fill="#FFFFFF"/><circle cx="{x + 31}" cy="{y + 13}" r="2" fill="#FFFFFF"/>')
    elif kind == 'bucket':
        return f'<g transform="rotate(-35 {x + 18} {y + 8})">' + bucket(x + 6, y, 26, 22) + '</g>'
    return (f'<g transform="rotate(-30 {x} {y})">' + body + f'<path d="M{x + 8} {y} L{x} {y - 3} L{x} {y + 2} L{x + 8} {y + 4} Z" fill="url(#steel)"/></g>')


def topup_stage(closed=False):
    out = card_open('sky')
    out.append(do_fuses(closed, 18, 18, 11).replace(f'height="{GY - 4}"', 'height="216"'))
    out.append('<rect x="-20" y="118" width="170" height="48" rx="24" fill="url(#cons)"/>')
    out.append('<rect x="-4" y="184" width="208" height="40" fill="url(#tank)"/>')
    out.append('<rect x="40" y="166" width="10" height="18" fill="url(#cons)"/>')
    out.append(gauge(154, 104, 16, 66, 0.2))
    # The filler neck and a funnel with a filter mesh.
    out.append('<rect x="88" y="104" width="12" height="16" fill="url(#steel)"/>')
    out.append('<path d="M76 80 L112 80 L98 104 L90 104 Z" fill="url(#steel)"/>')
    out.append('<g stroke="#7D868E" stroke-width="0.8">' + ''.join(f'<path d="M{80 + i * 4} 82 L{80 + i * 4} 88"/>' for i in range(8)) + '<path d="M78 84 L110 84 M79 87 L109 87"/></g>')
    return out


def stream(x0, y0, x1, y1, col=OIL, w=3):
    return f'<path d="M{x0} {y0} Q{x1 + 4} {(y0 + y1) / 2} {x1} {y1}" stroke="{col}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'


def topup_card(kind):
    out = topup_stage(closed=(kind == 'live'))
    if kind in ('drum', 'live'):
        out.append(stream(118, 52, 94, 84, 'url(#oil)'))
        out.append(can(118, 50, 'new'))
        out.append(arm((150, 48)))
        if kind == 'live':
            out.append(hum(4, 150, 3, loud=True, side=1))
            out.append(spark(36, 38, 0.6))
    elif kind == 'pump':
        # A sealed new drum below, a hand pump, a hose up to the funnel.
        out.append('<rect x="2" y="172" width="44" height="52" rx="4" fill="url(#drum)"/>')
        out.append(f'<rect x="2" y="184" width="44" height="3" fill="{WIRE}"/><rect x="2" y="208" width="44" height="3" fill="{WIRE}"/>')
        out.append('<rect x="20" y="150" width="8" height="24" fill="url(#steel)"/><path d="M24 150 L40 138" stroke="#7D868E" stroke-width="3" stroke-linecap="round"/>')
        out.append(f'<path d="M28 156 Q60 150 58 100 Q56 66 84 62 L90 78" stroke="{WIRE}" stroke-width="3.2" fill="none"/>')
        out.append(stream(90, 78, 94, 86, 'url(#oil)'))
        out.append(arm((40, 136), (90, 236)))
    elif kind == 'engine':
        out.append(stream(118, 52, 94, 84, '#3A2A18'))
        out.append(can(118, 50, 'engine'))
        out.append(arm((150, 48)))
    elif kind == 'wet':
        out.append(stream(118, 58, 94, 84, 'url(#oil)'))
        out += [f'<circle cx="{100 + i * 6}" cy="{70 + i * 3}" r="1.6" fill="{RAIN}"/>' for i in range(3)]
        out.append(can(116, 50, 'bucket'))
        out.append(arm((150, 48)))
        out.append('<g stroke="' + RAIN + '" stroke-width="1.4" stroke-linecap="round" opacity="0.9">'
                   + ''.join(f'<path d="M{20 + (i * 37) % 180} {10 + (i * 23) % 90} l-3 8"/>' for i in range(14)) + '</g>')
    return card_close(out)


CARDS = {
    'level_mark': level_card('mark'),
    'level_warm': level_card('warm'),
    'level_low': level_card('low'),
    'level_empty': level_card('empty'),
    'level_leak': level_card('leak'),
    'check_ground': check_card('ground'),
    'check_ir': check_card('ir'),
    'check_hand': check_card('hand'),
    'check_ear': check_card('ear'),
    'check_climb': check_card('climb'),
    'heat_hum': heat_card('hum'),
    'heat_noon': heat_card('noon'),
    'heat_boil': heat_card('boil'),
    'heat_vines': heat_card('vines'),
    'heat_dust': heat_card('dust'),
    'leak_call_drain': leak_card('call_drain'),
    'leak_call_bush': leak_card('call_bush'),
    'leak_ignore': leak_card('ignore'),
    'leak_bucket': leak_card('bucket'),
    'leak_climb': leak_card('climb'),
    'topup_drum': topup_card('drum'),
    'topup_pump': topup_card('pump'),
    'topup_engine': topup_card('engine'),
    'topup_wet': topup_card('wet'),
    'topup_live': topup_card('live'),
}

# Safe cards and traps per round (mirrors learn_board_pack45.dart).
ROUNDS = {
    'level': (['level_mark', 'level_warm'], ['level_low', 'level_empty', 'level_leak']),
    'check': (['check_ground', 'check_ir'], ['check_hand', 'check_ear', 'check_climb']),
    'heat': (['heat_hum', 'heat_noon'], ['heat_boil', 'heat_vines', 'heat_dust']),
    'leak': (['leak_call_drain', 'leak_call_bush'], ['leak_ignore', 'leak_bucket', 'leak_climb']),
    'topup': (['topup_drum', 'topup_pump'], ['topup_engine', 'topup_wet', 'topup_live']),
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
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
