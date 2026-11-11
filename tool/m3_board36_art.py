"""Picture cards for lesson 3.6 শেখা ("ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR): লাইনের হৃৎপিণ্ড").

python -I tool/m3_board36_art.py .

Writes assets/game/art/m3_board36/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

One stage for the outdoor rounds: an 11kV pole on the left (three DO fuses
on the crossarm, an LA bracket below), a plinth-mounted DTR in the middle
(three tall HT bushings, four short LT bushings - three phases and the
neutral -, the conservator drum on top with its oil level sight glass, the
silica gel breather hanging at its end, a drain valve, an off-load tap
changer on the tank side), the LT switch on a post at the right, and three
earth pits (LA, body, neutral).

What the cards show comes from lesson 3.6 (text + film script) only:
  1. side: HT (11kV) bushings are much bigger than the LT (415V) ones, with
     more creepage - that is how the HT side is told; the conservator (oil
     expansion) and the breather (silica gel) are not bushings;
  2. gel: good, dry silica gel is blue or orange; after soaking up moisture
     it turns pink or white - time to change it (moisture enters from the
     bottom, so the colour changes from the bottom up). An empty breather
     is drawn as a trap (the gel is what absorbs the moisture);
  3. sign: a mild, steady humming is normal; knocking / growling means a
     serious fault inside; oil leaks at the bushing gasket or the drain
     valve; a very low oil level overheats the transformer;
  4. tap: the off-load tap changer is turned only with the transformer off
     from both sides, HT and LT;
  5. earth: body, neutral and LA earthing are all vital - one weak and the
     whole system's protection is compromised.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board36_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board36')
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
FACE = '#1E2329'
OIL = '#C98A1E'
OIL_D = '#9C6A12'
GI = '#8E989F'          # galvanised earth strip
PIT = '#5E554B'
FIN = '#5C7459'
LED_G = '#4CD964'
LED_R = '#FF4B3E'
GEL_BLUE = '#2F6BCB'
GEL_ORANGE = '#F08A24'
GEL_PINK = '#F2A2B8'
GEL_WHITE = '#F4F2EA'

DEFS = """<defs>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="tankwall" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5F785C"/><stop offset="1" stop-color="#8FAA8B"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="drum" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#93AE8F"/><stop offset="0.5" stop-color="#7C977A"/><stop offset="1" stop-color="#5E785B"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9C8B78"/><stop offset="0.5" stop-color="#C9B49C"/><stop offset="1" stop-color="#8A7A68"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AC"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#8E98A0"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8C949A"/><stop offset="0.5" stop-color="#B9C0C5"/><stop offset="1" stop-color="#7A8288"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.35"/><stop offset="0.3" stop-color="#FFFFFF" stop-opacity="0.08"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0.25"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.85"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="blast" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE38A"/><stop offset="0.7" stop-color="#FF7A2E" stop-opacity="0.7"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
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


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0)):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves."""
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
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, point=(0, 0)):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    feet = ((x - 7 * face, GY - 1), (x + 6 * face, GY - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, False, point)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def rest_hand(x):
    """The worker's back hand hanging at his side."""
    return (x - 10, 156)


# --------------------------------------------------------------------------
# The stage.
# --------------------------------------------------------------------------

TANK = (44, 112, 86, 76)          # x, y, w, h
HT_X = (54, 70, 86)                # tall HT bushings on the cover
LT_X = (100, 109, 118, 127)        # short LT bushings; the last is the neutral
COVER_Y = 108
CONS = (92, 48, 46, 16)            # conservator drum x, y, w, h
SIGHT = (98, 49, 8, 14)            # oil level sight glass on the drum
BREATHER = (142, 66, 10, 20)       # breather glass x, y, w, h
TAP = (122, 132)                   # off-load tap changer dial on the tank side
DRAIN = (52, 184)                  # drain valve at the tank foot
LTBOX = (178, 118)                 # LT switch box
DO_X = (28, 40, 52)                # DO fuses on the crossarm
DO_TOP, DO_HINGE = 36, 58
LA_X = (26, 33, 40)                # LA stacks on their bracket
LA_Y = 92
PITS = {'la': 10, 'body': 30, 'neutral': 146}


def bushing(x, base, h, sheds, w):
    """A porcelain bushing standing on base, h tall, with its metal cap."""
    o = [f'<rect x="{f(x - w / 2)}" y="{f(base - h)}" width="{f(w)}" height="{f(h)}" rx="{f(w / 3)}" fill="url(#porcelain)"/>']
    for i in range(sheds):
        sy = base - h + 5 + i * (h - 6) / max(1, sheds)
        o.append(f'<ellipse cx="{f(x)}" cy="{f(sy)}" rx="{f(w * 0.95)}" ry="{f(w * 0.28)}" fill="url(#porcelain)"/>')
    o.append(f'<rect x="{f(x - 1.6)}" y="{f(base - h - 4)}" width="3.2" height="5" fill="url(#steel)"/>')
    return ''.join(o)


def do_fuse(x, closed=True):
    o = [f'<rect x="{x - 2.5}" y="{DO_TOP}" width="5" height="5" rx="1" fill="url(#porcelain)"/>',
         f'<rect x="{x - 2.5}" y="{DO_HINGE}" width="5" height="5" rx="1" fill="url(#porcelain)"/>']
    if closed:
        o.append(f'<path d="M{x} {DO_TOP + 5} L{x} {DO_HINGE}" stroke="{FACE}" stroke-width="3.2" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{x} {DO_HINGE} L{x + 9} {DO_HINGE + 15}" stroke="{FACE}" stroke-width="3.2" stroke-linecap="round"/>')
    return ''.join(o)


def lt_switch(on=True):
    sx, sy = LTBOX
    o = [f'<path d="M{sx + 9} {sy + 26} L{sx + 9} {GY}" stroke="#6F7880" stroke-width="3"/>',
         f'<rect x="{sx}" y="{sy}" width="18" height="26" rx="2" fill="url(#panel)" stroke="#6F7880" stroke-width="0.8"/>']
    hy = sy + 5 if on else sy + 21
    o.append(f'<path d="M{sx + 9} {sy + 13} L{sx + 9} {hy}" stroke="{FACE}" stroke-width="3.4" stroke-linecap="round"/>')
    o.append(f'<circle cx="{sx + 9}" cy="{sy + 13}" r="2.6" fill="{FACE}"/>')
    return ''.join(o)


def earth_lead(points, cut=False):
    """A galvanised earth strip along points, into its pit; cut = a gap with
    the loose end hanging."""
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in points)
    if not cut:
        return f'<path d="{d}" stroke="{GI}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>'
    # Draw it up to the last leg's middle, then a dangling stub and the pit end.
    (x0, y0), (x1, y1) = points[-2], points[-1]
    my = (y0 + y1) / 2
    top = points[:-1] + [(x0, my - 12)]
    d1 = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in top)
    return (f'<path d="{d1}" stroke="{GI}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>'
            f'<path d="M{f(x0)} {f(my - 12)} q6 6 10 3" stroke="{GI}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(x1)} {f(y1)} L{f(x1)} {f(my + 12)} l-5 -4" stroke="{GI}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')


def pit(x):
    return (f'<rect x="{x - 6}" y="{GY + 3}" width="12" height="7" rx="1" fill="{PIT}"/>'
            f'<rect x="{x - 7}" y="{GY + 2}" width="14" height="2.4" rx="1" fill="url(#steel)"/>')


def sight_glass(level):
    x, y, w, h = SIGHT
    fill_h = h * level
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="{FACE}"/>'
            f'<rect x="{x + 1}" y="{f(y + h - fill_h)}" width="{w - 2}" height="{f(max(0.8, fill_h - 1))}" rx="1" fill="{OIL}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="url(#glass)"/>')


def breather_small(gel):
    x, y, w, h = BREATHER
    cx = CONS[0] + CONS[2]
    o = [f'<path d="M{cx} {CONS[1] + 9} L{x + w / 2} {CONS[1] + 9} L{x + w / 2} {y}" stroke="url(#steel)" stroke-width="2.6" fill="none"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{FACE}"/>',
         f'<rect x="{x + 1.4}" y="{y + 2}" width="{w - 2.8}" height="{h - 4}" rx="1.4" fill="{gel}"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="url(#glass)"/>',
         f'<rect x="{x - 1}" y="{y + h - 1}" width="{w + 2}" height="4" rx="1.5" fill="{OIL_D}"/>']
    return ''.join(o)


def stage(do_closed=True, lt_on=True, level=0.6, cut=None, extra_front=''):
    """The whole yard: pole, DO fuses, LAs, DTR, LT switch, earth pits."""
    out = card_open('yard')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<path d="M0 {GY} L200 {GY}" stroke="#8A7A58" stroke-width="1"/>')
    # The 11kV pole, the line coming in, the crossarm with the DO fuses.
    out.append(f'<rect x="12" y="14" width="7" height="{GY - 14}" fill="url(#pole)"/>')
    out.append('<rect x="2" y="30" width="58" height="4.5" fill="#6F7880"/>')
    for i, x in enumerate(DO_X):
        out.append(f'<path d="M0 {20 + i * 3} Q{x / 2} {24 + i * 3} {x} {DO_TOP}" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
        out.append(do_fuse(x, do_closed))
    # HT jumpers from the DO fuses down to the HT bushings.
    for x, bx in zip(DO_X, HT_X):
        out.append(f'<path d="M{x} {DO_HINGE + 5} Q{(x + bx) / 2} {DO_HINGE + 22} {bx} {COVER_Y - 38}" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
    # The LA bracket with its three arresters, tapped off the jumpers.
    out.append(f'<rect x="18" y="{LA_Y}" width="26" height="3.5" fill="#6F7880"/>')
    for x in LA_X:
        out.append(f'<rect x="{x - 2.5}" y="{LA_Y - 13}" width="5" height="13" rx="1.5" fill="url(#porcelain)"/>')
        out.append(f'<path d="M{x} {LA_Y - 13} L{x + 4} {LA_Y - 22}" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    # The DTR on its plinth.
    x, y, w, h = TANK
    out.append(f'<rect x="36" y="{y + h}" width="102" height="{GY - y - h}" fill="#A8A29A"/>')
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#tank)"/>')
    for i in range(8):
        out.append(f'<rect x="{x + 6 + i * 9.6}" y="{y + 10}" width="4" height="{h - 18}" rx="1.5" fill="{FIN}"/>')
    out.append(f'<rect x="{x - 2}" y="{COVER_Y}" width="{w + 6}" height="5" rx="1.5" fill="url(#drum)"/>')
    for bx in HT_X:
        out.append(bushing(bx, COVER_Y, 34, 4, 7))
    for bx in LT_X:
        out.append(bushing(bx, COVER_Y, 12, 1, 5))
    # The conservator on a pipe, the sight glass and the breather.
    cx, cy, cw, ch = CONS
    out.append(f'<path d="M{cx + cw - 6} {cy + ch} L{cx + cw - 6} {COVER_Y}" stroke="url(#steel)" stroke-width="3"/>')
    out.append(f'<rect x="{cx}" y="{cy}" width="{cw}" height="{ch}" rx="7" fill="url(#drum)"/>')
    out.append(sight_glass(level))
    # The tap changer dial and the drain valve.
    tx, ty = TAP
    out.append(f'<circle cx="{tx}" cy="{ty}" r="6.5" fill="url(#steel)"/><path d="M{tx - 5} {ty} L{tx + 5} {ty}" stroke="{FACE}" stroke-width="2.6" stroke-linecap="round"/>')
    dx, dy = DRAIN
    out.append(f'<rect x="{dx - 3}" y="{dy - 3}" width="7" height="5" fill="url(#steel)"/><circle cx="{dx - 4}" cy="{dy - 0.5}" r="3" fill="{LED_R}"/>')
    # LT cable from the LT bushings to the switch.
    out.append(f'<path d="M{LT_X[0]} {COVER_Y - 14} Q{LT_X[0] + 6} 88 140 88 L{LTBOX[0] + 9} 88 L{LTBOX[0] + 9} {LTBOX[1]}" stroke="{WIRE}" stroke-width="2.8" fill="none"/>')
    out.append(lt_switch(lt_on))
    # Earth leads: LA (down the pole), body (tank foot), neutral (LT neutral bushing).
    cut = cut or ''
    out.append(earth_lead([(18, LA_Y + 3), (9, LA_Y + 10), (PITS['la'], GY + 3)], cut == 'la'))
    out.append(earth_lead([(x, y + h - 14), (PITS['body'], y + h - 14), (PITS['body'], GY + 3)], cut == 'body'))
    out.append(earth_lead([(LT_X[3], COVER_Y - 14), (140, 98), (PITS['neutral'], 104), (PITS['neutral'], GY + 3)], cut == 'neutral'))
    for p in PITS.values():
        out.append(pit(p))
    out.append(extra_front)
    return out


def ring(x, y, r):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.72)}" fill="none" stroke="#FFFFFF" stroke-width="1.6" '
            'stroke-dasharray="4 3" opacity="0.9"/>')


# --------------------------------------------------------------------------
# Round 1 — side: the big bushings are the HT side.
# --------------------------------------------------------------------------

TARGETS = {
    'ht': (HT_X[1], COVER_Y - 18, 24),
    'lt': (113, COVER_Y - 7, 18),
    'cons': (CONS[0] + CONS[2] / 2, CONS[1] + CONS[3] / 2, 26),
    'breather': (BREATHER[0] + 5, BREATHER[1] + 10, 15),
}


def side_card(kind):
    tgt = 'ht' if kind in ('ht', 'htr') else kind
    out = stage()
    out.append(breather_small(GEL_BLUE))
    tx, ty, r = TARGETS[tgt]
    out.insert(4, ring(tx, ty, r))  # the glow sits behind the drawing
    hand = (146, 100)
    out.append(worker(170, (rest_hand(170), hand), face=-1, look=-14, point=(0, -1)))
    if kind == 'htr':
        # The same yard seen from the other side: HT on the right.
        body = '\n'.join(out[4:])
        out = out[:4] + [f'<g transform="translate(200 0) scale(-1 1)">{body}</g>']
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — gel: the breather close up.
# --------------------------------------------------------------------------

def gel_card(kind):
    out = card_open('tankwall')
    # The conservator's underside at the top, the breather pipe, the glass.
    out.append('<rect x="-10" y="-30" width="220" height="56" rx="26" fill="url(#drum)"/>')
    out.append('<rect x="92" y="24" width="16" height="18" fill="url(#steel)"/>')
    gx, gy, gw, gh = 58, 42, 84, 132
    out.append(f'<rect x="{gx - 6}" y="{gy}" width="{gw + 12}" height="12" rx="3" fill="url(#steel)"/>')
    out.append(f'<rect x="{gx}" y="{gy + 12}" width="{gw}" height="{gh - 12}" rx="6" fill="{FACE}"/>')
    # Beads: the colour changes from the bottom (where the air comes in) up.
    spent = {'blue': (GEL_BLUE, GEL_BLUE, 0), 'orange': (GEL_ORANGE, GEL_ORANGE, 0),
             'pink': (GEL_BLUE, GEL_PINK, 0.78), 'white': (GEL_ORANGE, GEL_WHITE, 0.78)}
    if kind in spent:
        fresh, used, frac = spent[kind]
        rows = 11
        for r in range(rows):
            col = used if r >= rows * (1 - frac) else fresh
            yy = gy + 20 + r * 10.4
            off = 0 if r % 2 == 0 else 5
            for c in range(8):
                xx = gx + 8 + off + c * 10
                if xx > gx + gw - 6:
                    continue
                out.append(f'<circle cx="{f(xx)}" cy="{f(yy)}" r="4.6" fill="{col}"/>')
    out.append(f'<rect x="{gx}" y="{gy + 12}" width="{gw}" height="{gh - 12}" rx="6" fill="url(#glass)"/>')
    out.append(f'<rect x="{gx - 6}" y="{gy + gh}" width="{gw + 12}" height="10" rx="3" fill="url(#steel)"/>')
    # The oil cup below.
    out.append(f'<rect x="{gx + 10}" y="{gy + gh + 10}" width="{gw - 20}" height="24" rx="6" fill="url(#glass)" stroke="#FFFFFF" stroke-opacity="0.5"/>')
    out.append(f'<rect x="{gx + 12}" y="{gy + gh + 22}" width="{gw - 24}" height="10" rx="4" fill="{OIL}"/>')
    # The lineman's gloved finger at the glass on every card.
    out.append(f'<path d="M200 150 L176 146 Q166 144 160 140" stroke="{GLOVE}" stroke-width="12" stroke-linecap="round" fill="none"/>')
    out.append(f'<path d="M160 140 L148 136" stroke="{GLOVE}" stroke-width="5" stroke-linecap="round"/>')
    out.append(f'<rect x="186" y="138" width="20" height="22" fill="url(#shirt)"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — sign: the patrol from a distance - hear and look.
# --------------------------------------------------------------------------

def hum_lines(rough=False):
    o = []
    cx, cy = TANK[0] + TANK[2] / 2, TANK[1] + 30
    for side in (-1, 1):
        for i, r in enumerate((52, 60, 68)):
            x = cx + side * r
            if rough:
                pts = []
                for k in range(7):
                    yy = cy - 18 + k * 6
                    xx = x + (4 if k % 2 else -4) * side
                    pts.append(f'{f(xx)} {f(yy)}')
                o.append(f'<path d="M{" L".join(pts)}" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linejoin="miter" opacity="0.95"/>')
            else:
                o.append(f'<path d="M{f(x)} {f(cy - 16)} q{f(5 * side)} 16 0 32" stroke="#FFFFFF" stroke-width="1.6" fill="none" '
                         f'stroke-linecap="round" opacity="{0.75 - i * 0.2:.2f}"/>')
    return ''.join(o)


def drip(x, y, n=3):
    o = [f'<path d="M{x} {y} q-1 6 0 10" stroke="{OIL}" stroke-width="3" fill="none" stroke-linecap="round"/>']
    for i in range(n):
        o.append(f'<ellipse cx="{x}" cy="{y + 15 + i * 5}" rx="1.6" ry="2.2" fill="{OIL}"/>')
    return ''.join(o)


def sign_card(kind):
    level = 0.1 if kind == 'low' else 0.6
    out = stage(level=level)
    out.append(breather_small(GEL_BLUE))
    ear = (163, 112)
    if kind == 'hum':
        out.append(hum_lines())
        out.append(worker(176, (rest_hand(176), ear), face=-1, look=-4))
    elif kind == 'knock':
        out.append(hum_lines(rough=True))
        out.append(worker(176, (rest_hand(176), ear), face=-1, look=-4))
    elif kind in ('dry', 'low'):
        out.insert(4, ring(SIGHT[0] + 3, SIGHT[1] + 5, 14))
        out.append(worker(176, (rest_hand(176), (150, 102)), face=-1, look=-18, point=(0, -1)))
    elif kind == 'drain':
        dx, dy = DRAIN
        out.insert(4, ring(dx - 4, dy + 4, 16))
        out.append(drip(dx - 4, dy + 2, 2))
        out.append(f'<ellipse cx="{dx - 6}" cy="{GY + 6}" rx="14" ry="3.4" fill="{OIL_D}" opacity="0.85"/>')
        out.append(worker(176, (rest_hand(176), (160, 130)), face=-1, look=8, point=(0, -1)))
    elif kind == 'gasket':
        bx = HT_X[1]
        out.insert(4, ring(bx + 2, COVER_Y + 4, 16))
        out.append(f'<path d="M{bx + 2} {COVER_Y + 2} q2 14 -1 30 q-2 14 1 26" stroke="{OIL}" stroke-width="3.4" fill="none" stroke-linecap="round" opacity="0.95"/>')
        out.append(f'<ellipse cx="{bx + 2}" cy="{GY - 10}" rx="10" ry="2.6" fill="{OIL_D}" opacity="0.85"/>')
        out.append(worker(176, (rest_hand(176), (160, 120)), face=-1, look=-6, point=(0, -1)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — tap: the off-load tap changer, only with HT and LT both off.
# --------------------------------------------------------------------------

def tap_card(kind):
    do_closed = kind in ('live', 'lt')
    lt_on = kind in ('live', 'ht')
    out = stage(do_closed=do_closed, lt_on=lt_on)
    out.append(breather_small(GEL_BLUE))
    tx, ty = TAP
    if kind == 'check':
        out.insert(4, ring(DO_X[1] + 4, DO_HINGE + 6, 22))
        out.append(worker(160, (rest_hand(160), (138, 98)), face=-1, look=-22, point=(0, -1)))
    else:
        out.insert(4, ring(tx, ty, 16))
        out.append(worker(150, ((tx + 6, ty + 6), (tx + 2, ty - 2)), face=-1, look=6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — earth: body, neutral and LA earthing all whole.
# --------------------------------------------------------------------------

def earth_card(kind):
    cut = {'body': 'body', 'neutral': 'neutral', 'arrester': 'la'}.get(kind)
    out = stage(cut=cut)
    out.append(breather_small(GEL_BLUE))
    spot = {'all': (PITS['body'], 176), 'pits': (PITS['neutral'], GY + 2), 'body': (PITS['body'], 178),
            'neutral': (PITS['neutral'], 150), 'arrester': (PITS['la'], 150)}[kind]
    out.insert(4, ring(spot[0], spot[1], 16))
    out.append(worker(176, (rest_hand(176), (160, 140)), face=-1, look=12, point=(0, -1)))
    return card_close(out)


CARDS = {
    'side_ht': side_card('ht'),
    'side_htr': side_card('htr'),
    'side_lt': side_card('lt'),
    'side_cons': side_card('cons'),
    'side_breather': side_card('breather'),
    'gel_blue': gel_card('blue'),
    'gel_orange': gel_card('orange'),
    'gel_pink': gel_card('pink'),
    'gel_white': gel_card('white'),
    'gel_empty': gel_card('empty'),
    'sign_hum': sign_card('hum'),
    'sign_dry': sign_card('dry'),
    'sign_knock': sign_card('knock'),
    'sign_drain': sign_card('drain'),
    'sign_gasket': sign_card('gasket'),
    'sign_low': sign_card('low'),
    'tap_turn': tap_card('turn'),
    'tap_check': tap_card('check'),
    'tap_live': tap_card('live'),
    'tap_lt': tap_card('lt'),
    'tap_ht': tap_card('ht'),
    'earth_all': earth_card('all'),
    'earth_pits': earth_card('pits'),
    'earth_body': earth_card('body'),
    'earth_neutral': earth_card('neutral'),
    'earth_arrester': earth_card('arrester'),
}

# Safe cards and traps per round (mirrors learn_board_pack36.dart).
ROUNDS = {
    'side': (['side_ht', 'side_htr'], ['side_lt', 'side_cons', 'side_breather']),
    'gel': (['gel_blue', 'gel_orange'], ['gel_pink', 'gel_white', 'gel_empty']),
    'sign': (['sign_hum', 'sign_dry'], ['sign_knock', 'sign_drain', 'sign_gasket', 'sign_low']),
    'tap': (['tap_turn', 'tap_check'], ['tap_live', 'tap_lt', 'tap_ht']),
    'earth': (['earth_all', 'earth_pits'], ['earth_body', 'earth_neutral', 'earth_arrester']),
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
