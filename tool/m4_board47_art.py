"""Picture cards for lesson 4.7 শেখা ("ডিপি (DP) স্ট্রাকচার ড্রেসিং: পরিচ্ছন্নতার শিল্প").

python -I tool/m4_board47_art.py .

Writes assets/game/art/m4_board47/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

One double-pole (DP) structure is drawn and every card is a view of it: the
HT crossarm with three pin insulators and the incoming line on top, the DO
fuse crossarm below, the transformer on its platform, and the LT cables from
the transformer down to the LT box on the right pole.

What the cards show comes from lesson 4.7 and its film script only:
  1. jumper: a smooth, even 'U' or 'C' jumper is right; a tangled jumper, a
     jumper pulled tight (strain on the wire) and an over-long, unmeasured
     jumper hanging near the next phase / the structure are wrong;
  2. align: crossarms and insulators exactly horizontal and vertical, and the
     two sides of the structure symmetrical; a tilted crossarm, leaning
     insulators and a lopsided structure are wrong;
  3. cable: the transformer's LT cables are bunched with cable ties or clamped
     on the way down; loose hanging loops, a cable pulled tight and a cable
     looped up near the HT side (HT-LT clearance) are wrong;
  4. gap: the spare tail of the binding wire is cut off, and the clearance is
     checked by stepping back and looking from a distance; a long binding tail
     flapping in the wind, insulated cables rubbing on each other (the
     lesson's second myth) and a jumper against the structure are wrong;
  5. finish: every nut and connector tightened; a photo of the finished
     dressing as a record; a loose nut left while shaping the jumper, a
     crossarm crammed with no room for a future connection, and starting at
     the LT bottom with the HT top still untidy are wrong.

Anyone on the structure wears a helmet and a harness, and the HT line carries
portable earths while he works (house rule; the lesson does not say it).

Fairness (the playbook, section 4): every card is on the one sky backdrop;
the script checks every hand the dealer can make (one safe card + any three
traps): each colour or gradient the safe card draws is drawn by a trap in
that hand.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board47_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board47')
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
HARNESS = '#E8742A'
COND = '#59636C'       # bare HT conductor / jumper
BIND = '#C3CBD1'       # aluminium binding wire
CABLE = '#1E2226'      # insulated LT cable
COPPER = '#D98A3D'
EARTH = '#3E9B4F'
TIE = '#E9EDF0'
FACE = '#1E2329'
BOX = '#8E98A0'
PH = ('#D8402F', '#F0C02E', '#2F6BCB', '#1E2226')

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F7880"/><stop offset="0.5" stop-color="#A9B2B9"/><stop offset="1" stop-color="#5E676E"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8C969E"/><stop offset="1" stop-color="#525B63"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="fuse" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8A6A3E"/><stop offset="0.5" stop-color="#C9A56A"/><stop offset="1" stop-color="#7A5C34"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card(body):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#sky)"/>',
           body, '</g>',
           '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>',
           '</svg>']
    return '\n'.join(out)


def zoom(body, cx, cy, s, tx=100, ty=110):
    """Show (cx, cy) of the full view at (tx, ty), magnified s times."""
    return f'<g transform="translate({f(tx)} {f(ty)}) scale({f(s)}) translate({f(-cx)} {f(-cy)})">{body}</g>'


def ground():
    return (f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>'
            f'<path d="M0 {GY} L200 {GY}" stroke="#8A7A58" stroke-width="1"/>')


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def wind(x, y, s=1.0):
    return ''.join(f'<path d="M{f(x)} {f(y + i * 6 * s)} q{f(8 * s)} {f(-3 * s)} {f(16 * s)} 0 t{f(16 * s)} 0" stroke="#FFFFFF" '
                   f'stroke-width="{f(1.2 * s)}" fill="none" stroke-linecap="round" opacity="0.8"/>' for i in range(3))


# --------------------------------------------------------------------------
# The worker (from tool/m2_board28_art.py): one figure, any pose.
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


def _hand(p):
    return f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="3" fill="{GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, harness=False, front=''):
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
    g.append(_hand(hb))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    if harness:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{HARNESS}" stroke-width="3"/>'
                 f'<path d="M{f(sh[0] - px * 0.6)} {f(sh[1] - 1)} L{f(hip[0] + px * 0.6)} {f(hip[1] - 4)}" stroke="{HARNESS}" stroke-width="2"/>')
    hx, hy = head
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(look * face)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(front)
    g.append(_hand(hf))
    return ''.join(g)


def worker(x, hands_world, face=-1, look=0, gy=GY, s=1.32, harness=False, front=''):
    """A standing worker at x with his feet on gy, scaled s about his feet;
    the hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, harness, front)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({f(s)}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# The DP structure (full view, 200 x 220).
# --------------------------------------------------------------------------

PX = (55, 100, 145)       # the three phases
ARM_Y = 40                # HT crossarm top
HEAD_Y = 24               # conductor on the insulator head
DO_Y = 86                 # DO-fuse crossarm top
DO_TOP = 64
PLAT = 150                # transformer platform top
TANK = (64, 112, 72, 38)  # x, y, w, h
HTB = (82, 100, 118)      # transformer HT bushings
LTB = (118, 124, 130, 136, 142)[:4]
BOXP = (146, 166, 24, 26)  # the LT box on the right pole


def poles():
    return (f'<rect x="18" y="4" width="10" height="{GY - 4}" fill="url(#pole)"/>'
            f'<rect x="172" y="4" width="10" height="{GY - 4}" fill="url(#pole)"/>')


def crossarm(y, tilt=0):
    return f'<g transform="rotate({f(tilt)} 100 {y})"><rect x="10" y="{y}" width="180" height="6" fill="url(#arm)"/></g>'


def pin(x, base=ARM_Y, lean=0, bind='neat', line=True):
    """A pin insulator on the crossarm with the conductor bound on its head."""
    o = [f'<path d="M{x - 2} {base} L{x - 2} {base - 4} L{x - 7} {base - 6} L{x - 3} {base - 9} L{x - 6} {base - 11} '
         f'L{x - 3} {base - 14} L{x + 3} {base - 14} L{x + 6} {base - 11} L{x + 3} {base - 9} L{x + 7} {base - 6} '
         f'L{x + 2} {base - 4} L{x + 2} {base} Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>']
    hy = base - 16
    if line:
        o.append(f'<path d="M{x - 18} {hy - 22} L{x - 4} {hy}" stroke="{COND}" stroke-width="2.2"/>')
    o.append(f'<path d="M{x - 5} {hy} L{x + 5} {hy}" stroke="{COND}" stroke-width="2.2"/>')
    o.append(''.join(f'<path d="M{f(x - 3.5 + i * 1.75)} {hy - 2} l0 4" stroke="{BIND}" stroke-width="0.9"/>' for i in range(5)))
    if bind == 'tail':
        o.append(f'<path d="M{x + 4} {hy} q8 -6 14 2 t16 -2 t12 6" stroke="{COND}" stroke-width="1.6" fill="none"/>'
                 f'<path d="M{x + 4} {hy} q8 -6 14 2 t16 -2 t12 6" stroke="{BIND}" stroke-width="0.9" fill="none"/>')
    return f'<g transform="rotate({f(lean)} {x} {base})">' + ''.join(o) + '</g>'


def do_fuse(x, y=DO_TOP):
    return (f'<rect x="{x - 3}" y="{y}" width="6" height="4" rx="1" fill="url(#porcelain)"/>'
            f'<rect x="{x - 2.5}" y="{y + 4}" width="5" height="14" rx="1.5" fill="url(#fuse)"/>'
            f'<rect x="{x - 3}" y="{y + 18}" width="6" height="4" rx="1" fill="url(#porcelain)"/>')


def jumper(x, kind, i=0):
    hx, hy = x + 5, HEAD_Y
    w = f'stroke="{COND}" stroke-width="1.8" fill="none" stroke-linecap="round"'
    if kind == 'c':
        return f'<path d="M{hx} {hy} C{hx + 16} {hy + 6} {x + 16} {DO_TOP - 8} {x} {DO_TOP}" {w}/>'
    if kind == 'u':
        return (f'<path d="M{hx} {hy} C{hx} {hy + 28} {x - 7} {hy + 28} {x - 7} {hy}" {w}/>'
                f'<path d="M{x - 1} {hy + 21} L{x} {DO_TOP}" {w}/>')
    if kind == 'tangle':
        k = (1, -1, 1)[i]
        return (f'<path d="M{hx} {hy} C{hx + 26 * k} {hy + 4} {x - 20 * k} {hy + 10} {x + 8 * k} {hy + 20} '
                f'S{x + 22 * k} {hy + 30} {x - 6 * k} {hy + 28} S{x - 14 * k} {DO_TOP - 4} {x} {DO_TOP}" {w}/>'
                f'<circle cx="{x + 4 * k}" cy="{hy + 22}" r="4" {w}/>')
    if kind == 'taut':
        return (f'<path d="M{hx} {hy} L{x + 9} {hy + 18} L{x + 6} {hy + 20} L{x} {DO_TOP}" stroke="{COND}" stroke-width="1.8" fill="none" stroke-linejoin="miter"/>')
    if kind == 'long':
        d = (-1, 1, 1)[i]
        s = 22 if i != 0 else 34
        return f'<path d="M{hx} {hy} C{hx + s * d * 1.4} {hy + 10} {x + s * d * 1.6} {DO_TOP + 26} {x + s * d * 0.2} {DO_TOP + 14} S{x - 4} {DO_TOP - 6} {x} {DO_TOP}" {w}/>'
    if kind == 'body':
        if i == 0:
            return f'<path d="M{hx} {hy} C{x - 30} {hy + 4} {x - 36} {DO_TOP + 4} {x} {DO_TOP}" {w}/>'
        return jumper(x, 'c')
    if kind == 'cram':
        return jumper(x, 'c')
    return ''


def transformer():
    x, y, w, h = TANK
    o = [f'<rect x="10" y="{PLAT}" width="180" height="6" fill="url(#arm)"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#tank)"/>']
    o += [f'<rect x="{x + 6 + i * 9}" y="{y + 8}" width="4" height="{h - 14}" rx="1.5" fill="#5C7459"/>' for i in range(7)]
    for bx in HTB:
        o.append(f'<path d="M{bx - 4} {y} L{bx + 4} {y} L{bx + 2} {y - 12} L{bx - 2} {y - 12} Z" fill="url(#porcelain)"/>')
    for px, bx in zip(PX, HTB):
        o.append(f'<path d="M{px} {DO_TOP + 22} L{bx} {y - 12}" stroke="{COND}" stroke-width="1.6"/>')
    # The LT bushings on the right wall.
    for i, ly in enumerate(LTB):
        o.append(f'<rect x="{x + w}" y="{ly - 2}" width="6" height="4" rx="1" fill="url(#porcelain)"/>')
    return ''.join(o)


def lt_box():
    x, y, w, h = BOXP
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{BOX}" stroke="#5E676E" stroke-width="0.8"/>'
            f'<path d="M{x + 3} {y + 4} L{x + w - 3} {y + 4}" stroke="#5E676E" stroke-width="0.8"/>')


def lt_cables(kind):
    """The four LT cables from the transformer's LT bushings to the LT box."""
    x0 = TANK[0] + TANK[2] + 6
    bx, by = BOXP[0], BOXP[1]
    o = []
    if kind in ('tie', 'clamp', 'touch'):
        for i, ly in enumerate(LTB):
            cx = 152 + i * 3.2
            o.append(f'<path d="M{x0} {ly} L{cx - 8} {ly} Q{cx} {ly} {cx} {ly + 8} L{cx} {by}" stroke="{CABLE}" stroke-width="2.6" fill="none"/>')
            o.append(f'<rect x="{f(cx - 1.6)}" y="{by - 5}" width="3.2" height="3" fill="{PH[i]}"/>')
        if kind == 'tie':
            for ty in (148, 160):
                o.append(f'<rect x="150" y="{ty}" width="14" height="2.4" rx="1" fill="{TIE}"/>')
        elif kind == 'clamp':
            for ty in (146, 159):
                o.append(f'<rect x="149" y="{ty - 1}" width="28" height="3.6" rx="1" fill="url(#steel)" stroke="#7D868E" stroke-width="0.5"/>')
        else:
            # Two cables crossed over each other, worn through where they rub.
            o.append(f'<path d="M{x0} {LTB[3]} C150 {LTB[3]} 166 132 154 150" stroke="{CABLE}" stroke-width="2.6" fill="none"/>')
            o.append(f'<path d="M157 140 l3 1" stroke="{COPPER}" stroke-width="2.4" stroke-linecap="round"/>')
            o.append(spark(158, 140, 0.55))
            o.append(wind(118, 168, 0.8))
    elif kind == 'hang':
        for i, ly in enumerate(LTB):
            sag = 196 - i * 6
            o.append(f'<path d="M{x0} {ly} C{x0 - 56 + i * 16} {214 - i * 16} {bx - 34 + i * 22} {206 - i * 12} {bx + 4 + i * 5} {by}" stroke="{CABLE}" stroke-width="2.6" fill="none"/>')
            o.append(f'<rect x="{bx + 2.4 + i * 5}" y="{by - 5}" width="3.2" height="3" fill="{PH[i]}"/>')
    elif kind == 'strain':
        for i, ly in enumerate(LTB):
            o.append(f'<path d="M{x0} {ly} L{bx + 4 + i * 5} {by}" stroke="{CABLE}" stroke-width="2.6"/>')
            o.append(f'<rect x="{bx + 2.4 + i * 5}" y="{by - 5}" width="3.2" height="3" fill="{PH[i]}"/>')
        o.append(f'<path d="M{x0 - 2} {LTB[0] - 5} l3 -4 M{x0 + 2} {LTB[0] - 4} l4 -2" stroke="#FFFFFF" stroke-width="1.2" stroke-linecap="round"/>')
    elif kind == 'near':
        for i, ly in enumerate(LTB):
            cx = 152 + i * 3.2
            up = 96 + i * 3
            o.append(f'<path d="M{x0} {ly} C{x0 + 14} {ly - 10} {130 + i * 3} {up - 8} {HTB[2] + 6 + i * 3} {up} '
                     f'S{cx + 6} {up + 14} {cx} {ly + 14} L{cx} {by}" stroke="{CABLE}" stroke-width="2.6" fill="none"/>')
            o.append(f'<rect x="{f(cx - 1.6)}" y="{by - 5}" width="3.2" height="3" fill="{PH[i]}"/>')
        o.append(f'<rect x="150" y="160" width="14" height="2.4" rx="1" fill="{TIE}"/>')
        o.append(f'<rect x="149" y="145" width="28" height="3.6" rx="1" fill="url(#steel)" stroke="#7D868E" stroke-width="0.5"/>')
        o.append(spark(HTB[2] + 6, 100, 0.7))
    return ''.join(o)


def earths():
    """Portable earths: a green lead from each HT conductor to the left pole."""
    o = []
    for x in PX:
        o.append(f'<path d="M{x - 8} {HEAD_Y - 9} Q{(x + 28) / 2} {HEAD_Y + 30} 28 {HEAD_Y + 36}" stroke="{EARTH}" stroke-width="1.4" fill="none"/>'
                 f'<rect x="{x - 10}" y="{HEAD_Y - 12}" width="4" height="4" rx="1" fill="url(#steel)"/>')
    return ''.join(o)


def dp(jump='c', tilt=0, lean=(0, 0, 0), cable='tie', bind='neat', lopsided=False, cram=False, earth=False, u_pins=False):
    o = [ground(), poles(), crossarm(ARM_Y, tilt), crossarm(DO_Y)]
    xs = PX
    if lopsided:
        xs = (30, 48, 66)
    for i, x in enumerate(xs):
        o.append(f'<g transform="rotate({f(tilt)} 100 {ARM_Y})">' + pin(x, lean=lean[i], bind=bind if i == 1 else 'neat') + '</g>')
        if u_pins:
            o.append(pin(x - 12, line=False))
    if cram:
        for x in (32, 78, 122, 166):
            o.append(pin(x))
            o.append(do_fuse(x))
    o.append(transformer())
    for i, x in enumerate(PX):
        o.append(do_fuse(x))
    for i, (x, sx) in enumerate(zip(PX, xs)):
        if lopsided:
            o.append(f'<path d="M{sx + 5} {HEAD_Y} C{sx + 30} {HEAD_Y + 10} {x + 10} {DO_TOP - 16} {x} {DO_TOP}" stroke="{COND}" stroke-width="1.8" fill="none"/>')
        else:
            o.append(jumper(x, jump, i))
    o.append(lt_box())
    o.append(lt_cables(cable))
    if earth:
        o.append(earths())
    return ''.join(o)


# --------------------------------------------------------------------------
# Rounds.
# --------------------------------------------------------------------------

TOP = (100, 62, 1.7)       # zoom on the HT top and the jumpers


def top(body):
    cx, cy, s = TOP
    return zoom(body, cx, cy, s)


def jumper_card(kind):
    if kind == 'u':
        return card(top(dp('u', u_pins=True)))
    return card(top(dp(kind)))


def align_card(kind):
    if kind == 'level':
        return card(zoom(dp('c'), 100, 96, 1.3))
    if kind == 'even':
        return card(dp('c'))
    if kind == 'tilt':
        return card(dp('c', tilt=-6))
    if kind == 'lean':
        return card(top(dp('c', lean=(-20, 14, -24))))
    if kind == 'lopsided':
        return card(dp('c', lopsided=True))
    raise ValueError(kind)


LOW = (128, 150, 1.45)     # zoom on the transformer and the LT cables


def cable_card(kind):
    cx, cy, s = LOW
    return card(zoom(dp('c', cable=kind), cx, cy, s))


def stand_back(body, kind):
    """The structure a little smaller on the left, the worker on the ground."""
    o = [ground(), f'<g transform="translate(6 {GY}) scale(0.74) translate(0 -{GY})">{body}</g>']
    if kind == 'look':
        o.append(worker(172, ((182, 160), (170, 132)), face=-1, look=-14))
    elif kind == 'away':
        o.append(worker(176, ((168, 158), (186, 156)), face=1, look=4))
    elif kind == 'photo':
        phone = '<rect x="160" y="124" width="8" height="12" rx="1.5" fill="#1E2329" transform="rotate(-12 164 130)"/>'
        o.append(worker(176, ((162, 134), (166, 130)), face=-1, look=-8, front=phone))
    return ''.join(o)


def gap_card(kind):
    if kind == 'trim':
        return card(zoom(dp('c', bind='neat'), 101, 26, 4.2, ty=100))
    if kind == 'tail':
        return card(zoom(dp('c', bind='tail'), 108, 26, 4.2, ty=100) + wind(18, 150))
    if kind == 'look':
        return card(stand_back(dp('c'), 'look'))
    if kind == 'body':
        return card(stand_back(dp('body') + spark(30, 44, 0.8), 'away'))
    if kind == 'touch':
        cx, cy, s = LOW
        return card(zoom(dp('c', cable='touch'), cx + 14, cy - 6, 1.9))
    raise ValueError(kind)


# The close-up of a jumper's bolted connector: two plates on the conductor,
# two bolts; a portable earth on the conductor at the left.

def connector(loose=False):
    o = ['<rect x="0" y="176" width="200" height="12" fill="url(#arm)"/>',
         f'<path d="M-10 70 L210 70" stroke="{COND}" stroke-width="7"/>',
         f'<path d="M120 70 C122 120 150 140 178 176" stroke="{COND}" stroke-width="6" fill="none"/>',
         f'<path d="M30 70 Q40 120 18 176" stroke="{EARTH}" stroke-width="3.4" fill="none"/>',
         '<rect x="22" y="58" width="16" height="16" rx="2" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>']
    gap = 6 if loose else 0
    o.append(f'<rect x="90" y="{56 - gap}" width="50" height="12" rx="2" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>')
    o.append(f'<rect x="90" y="72" width="50" height="12" rx="2" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>')
    for i, bx in enumerate((100, 130)):
        o.append(f'<rect x="{bx - 2.5}" y="{46 - gap}" width="5" height="44" fill="#9AA5AD"/>')
        ny = 40 - (14 if loose and i == 0 else 0) - gap
        o.append(f'<path d="M{bx - 7} {ny} L{bx + 7} {ny} L{bx + 9} {ny + 8} L{bx - 9} {ny + 8} Z" fill="{FACE}"/>')
        if not (loose and i == 0):
            o.append(f'<rect x="{bx - 8}" y="{ny + 8}" width="16" height="3" fill="url(#steel)"/>')
    return ''.join(o)


def glove_arm(x, y, ang):
    return (f'<g transform="rotate({ang} {x} {y})"><rect x="{x}" y="{y - 9}" width="90" height="18" rx="6" fill="url(#shirt)"/>'
            f'<rect x="{x - 4}" y="{y - 11}" width="20" height="22" rx="8" fill="{GLOVE}"/></g>')


def finish_card(kind):
    if kind == 'tight':
        body = connector()
        body += ('<g transform="rotate(-24 130 44)"><rect x="118" y="38" width="64" height="11" rx="4" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>'
                 '<path d="M114 36 L124 36 L124 52 L114 52 Z" fill="url(#steel)"/></g>')
        body += glove_arm(170, 20, -24)
        body += f'<path d="M150 14 A22 22 0 0 1 168 34" stroke="#FFFFFF" stroke-width="1.8" fill="none"/><path d="M168 34 l-6 -1 M168 34 l1 -6" stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round"/>'
        return card(body)
    if kind == 'loose':
        body = connector(loose=True)
        body += glove_arm(150, 132, 30)
        return card(body)
    if kind == 'photo':
        return card(stand_back(dp('c'), 'photo'))
    if kind == 'cram':
        return card(dp('c', cram=True))
    if kind == 'bottom':
        body = dp('tangle', cable='hang', earth=True)
        body += worker(160, ((156, 176), (150, 160)), face=-1, look=10, gy=PLAT, s=0.95, harness=True)
        body += f'<path d="M153 {PLAT - 26} Q170 {PLAT - 34} 176 {PLAT - 22}" stroke="{HARNESS}" stroke-width="1.6" fill="none"/>'
        return card(body)
    raise ValueError(kind)


CARDS = {}
ROUNDS = {
    'jumper': (['u', 'c'], ['tangle', 'taut', 'long'], jumper_card),
    'align': (['level', 'even'], ['tilt', 'lean', 'lopsided'], align_card),
    'cable': (['tie', 'clamp'], ['hang', 'strain', 'near'], cable_card),
    'gap': (['trim', 'look'], ['tail', 'touch', 'body'], gap_card),
    'finish': (['tight', 'photo'], ['loose', 'cram', 'bottom'], finish_card),
}
for _r, (_s, _t, _fn) in ROUNDS.items():
    for _k in _s + _t:
        CARDS[f'{_r}_{_k}'] = _fn(_k)
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rnd, (safes, traps, _) in ROUNDS.items():
        for s in safes:
            s = f'{rnd}_{s}'
            for hand in itertools.combinations([f'{rnd}_{t}' for t in traps], HAND - 1):
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
