"""Picture cards for lesson 5.2 শেখা ("লাইন পেট্রোলিং-এর সঠিক নিয়ম").

python -I tool/m5_board52_art.py .

Writes assets/game/art/m5_board52/*.svg (200 x 220 scene cards, drawn edge to
edge, no words) for learn_board_pack52.dart. What the cards show comes from
lesson 5.2 only:

* start_  — a long feeder seen from above the field: the substation at the
            left, the poles to the houses (the load) at the right, a T-off
            branch going back with a kite caught on its wire (the lesson's
            "তারে আটকে থাকা ঘুড়ি", on every card). Safe: walking from the substation toward the
            load; two teams from both ends keeping in touch (a hand radio —
            the lesson only says "যোগাযোগ বজায় রাখুন"). Traps: starting in
            the middle, walking on far past the T-off with his head down and
            the kite left behind him, two teams with no contact,
            lost at the fork with no feeder map.
* eyes_   — one pole close up with a hairline crack on an insulator, the stay
            anchor and a pothole on the path. Safe: standing still with
            binoculars on the pole top; stopped and looking at the pole base
            and anchor (the base is whole). Traps: climbing to look, walking
            with binoculars to the eyes, standing on a smashed pole base with
            the head thrown back to the top.
* senses_ — a pole that looks whole: a dirty insulator and a scorched cable
            box. Safe: stopped and listening; stopped, leaning in and pointing
            at the smell's source (hands away from the face). Traps: music in the ears, shrugging past, hurrying past
            the smell holding the nose.
* wire_   — a conductor lying on a dry road, no spark. Safe: a rope ring far
            round it; stopped far off with a hand up. Traps: lifting it with
            a stick, bending over it, a rope ring two steps off, stepping
            over it.
* exit_   — standing near the wire, the ground's voltage rings round its end.
            Safe: feet together, small shuffling steps; a two-foot hop.
            Traps: long running strides, feet wide apart, walking toward it.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
really paints is painted by a trap in that hand, and the safe card's backdrop
is a trap's backdrop too. Invisible shapes never count (zero size, no paint,
opacity 0, display none, visibility hidden, a scale(0) transform, a shape
wholly off the card), and paint the check can't follow (a mask, a filter,
<use>, an image, a clip other than the card's) is refused. The same check
runs in test/learn_board_52_test.dart. Deletes only its own stale files.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board52_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board52')
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
COND = '#A9B4BC'
COND_D = '#6F7A82'
BIND = '#DCE3E8'
CRACK = '#1E2329'
ROPE = '#C8A15A'
ROPE_D = '#9C7A3C'
HARNESS = '#E8742A'
MOVE = '#FFFFFF'
FOOT = '#5E4A30'
PATH = '#C9B489'
HOUSE = '#D9C7A6'
ROOF = '#9A4E32'
PAPER = '#F4EBD0'
HOLE = '#3B3328'
DIRT = '#5A4632'
SCORCH = '#3A2A1E'
SMELL = '#8C7A5A'
SOUND = '#F6E27A'
KITE = '#D9483B'
KITE_D = '#A8332A'
STICK = '#B08D57'
VOLT = '#FFE36B'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6A7078"/><stop offset="1" stop-color="#4D535B"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
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
# The worker (the figure of tool/m4_board41_art.py): one figure, any pose.
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


def figure(hip, sh, head, feet, hands, face=1, look=0):
    """The lineman: blue shirt, dark trousers, yellow helmet, black gloves."""
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
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(_hand(hf))
    return ''.join(g)


def man(x, gy=GY, s=1.32, face=1, look=0, feet=((-7, -1), (6, -1)), hands=((-5, -30), (7, -30)),
        crouch=0, lean=0, lift=0, props=None):
    """A worker standing at x on the ground line gy, scaled s about his feet.
    feet / hands are offsets from (x, gy) in his own frame (mirrored by face);
    props(p) draws kit in the same frame from his joints."""
    by = gy - lift
    hip = (x - lean * 0.2 * face, by - 30 + crouch)
    sh = (x + (1 + lean) * face, by - 56 + crouch * 1.3)
    hd = (x + (3 + lean) * face, by - 64 + crouch * 1.3)
    ft = tuple((x + dx * face, by + dy) for dx, dy in feet)
    hs = tuple((x + dx * face, by + dy) for dx, dy in hands)
    body = figure(hip, sh, hd, ft, hs, face, look)
    extra = props({'hip': hip, 'sh': sh, 'head': hd, 'hands': hs, 'feet': ft, 'face': face, 'look': look}) if props else ''
    shadow = (f'<ellipse cx="{f(x)}" cy="{f(gy)}" rx="9" ry="2.4" fill="{BOOT}" fill-opacity="0.3"/>' if lift else '')
    return shadow + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{body}{extra}</g>'


def binoculars(p):
    hx, hy = p['head']
    face = p['face']
    a = p['look'] * face
    bx = hx + 7 * face
    return (f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">'
            f'<rect x="{f(bx - 2.5)}" y="{f(hy - 3)}" width="5" height="4" rx="1" fill="{BOOT}"/>'
            f'<rect x="{f(bx - 2.5)}" y="{f(hy + 1.5)}" width="5" height="4" rx="1" fill="{BOOT}"/>'
            f'<circle cx="{f(bx + 2.6 * face)}" cy="{f(hy - 1)}" r="1.5" fill="{COND_D}"/>'
            f'<circle cx="{f(bx + 2.6 * face)}" cy="{f(hy + 3.5)}" r="1.5" fill="{COND_D}"/></g>')


def radio(p, arcs=True):
    """A hand radio held up by the front hand; little arcs when talking."""
    x, y = p['hands'][1]
    face = p['face']
    o = (f'<rect x="{f(x - 2.5)}" y="{f(y - 7)}" width="5" height="9" rx="1.2" fill="{BOOT}"/>'
         f'<path d="M{f(x + 1)} {f(y - 7)} l0 -5" stroke="{COND_D}" stroke-width="1.2" stroke-linecap="round"/>')
    if arcs:
        for r in (5, 9):
            o += (f'<path d="M{f(x + face * r * 0.5)} {f(y - 12 - r * 0.8)} q{f(face * r * 0.6)} {f(r * 0.6)} 0 {f(r * 1.4)}" '
                  f'stroke="{MOVE}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    return o


def map_sheet(p):
    x, y = p['hands'][1]
    return (f'<path d="M{f(x - 5)} {f(y - 8)} l10 -1 l1 9 l-10 1 Z" fill="{PAPER}"/>'
            f'<path d="M{f(x - 3)} {f(y - 5)} l3 2 l4 -3" stroke="{COND_D}" stroke-width="0.8" fill="none"/>')


def motion(x, y, dx=1, dy=0, n=3, length=8):
    """Little white swish marks: someone moving."""
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 4, py * (i - 1) * 4
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def footprints(x0, x1, y, step=9, pair=3.2, size=1.0, color=FOOT):
    """Boot prints from x0 to x1 (left / right foot staggered by pair)."""
    o = []
    x, i = x0, 0
    sgn = 1 if x1 >= x0 else -1
    while (x - x1) * sgn <= 0:
        dy = -pair if i % 2 else pair
        o.append(f'<ellipse cx="{f(x)}" cy="{f(y + dy * 0.5)}" rx="{f(2.4 * size)}" ry="{f(1.2 * size)}" fill="{color}" fill-opacity="0.75"/>')
        x += step * sgn
        i += 1
    return ''.join(o)


def crack(x, y, s=1.0):
    return (f'<path d="M{f(x)} {f(y)} l{f(3 * s)} {f(5 * s)} l{f(-4 * s)} {f(4 * s)} l{f(4 * s)} {f(6 * s)} l{f(-2 * s)} {f(5 * s)}" '
            f'stroke="{CRACK}" stroke-width="{f(1.4 * s)}" fill="none" stroke-linejoin="round"/>')


def pin_insulator(x, yb, s=1.0, dirty=False):
    """A small pin insulator standing on a cross-arm top yb."""
    o = (f'<rect x="{f(x - 1.5 * s)}" y="{f(yb - 6 * s)}" width="{f(3 * s)}" height="{f(6 * s)}" fill="url(#steel)"/>'
         f'<path d="M{f(x - 7 * s)} {f(yb - 5 * s)} L{f(x + 7 * s)} {f(yb - 5 * s)} L{f(x + 4 * s)} {f(yb - 10 * s)} L{f(x - 4 * s)} {f(yb - 10 * s)} Z" fill="url(#porcelain)"/>'
         f'<path d="M{f(x - 5 * s)} {f(yb - 10 * s)} L{f(x + 5 * s)} {f(yb - 10 * s)} L{f(x + 3 * s)} {f(yb - 15 * s)} L{f(x - 3 * s)} {f(yb - 15 * s)} Z" fill="url(#porcelain)"/>')
    if dirty:
        for dx, dy in ((-4, -7), (2, -8), (-1, -12), (3, -13)):
            o += f'<circle cx="{f(x + dx * s)}" cy="{f(yb + dy * s)}" r="{f(1.1 * s)}" fill="{DIRT}" fill-opacity="0.8"/>'
    return o


def conductor(d, w=2.2):
    return (f'<path d="{d}" stroke="{COND_D}" stroke-width="{f(w + 1.2)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{COND}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>')


# --------------------------------------------------------------------------
# Round 1 — start: the feeder from above the field.
# --------------------------------------------------------------------------

FRONT = (62, 96, 130, 164)   # front-row poles (base y 150)
TEE = 96                     # the T-off pole
PY = 172                     # the path the workers walk


def small_pole(x, base, top):
    return (f'<rect x="{f(x - 1.6)}" y="{f(top)}" width="3.2" height="{f(base - top)}" fill="url(#pole)"/>'
            f'<rect x="{f(x - 6)}" y="{f(top + 2)}" width="12" height="2.4" fill="url(#arm)"/>')


def house(x, y, s=1.0):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(18 * s)}" height="{f(13 * s)}" fill="{HOUSE}"/>'
            f'<path d="M{f(x - 2 * s)} {f(y)} L{f(x + 9 * s)} {f(y - 8 * s)} L{f(x + 20 * s)} {f(y)} Z" fill="{ROOF}"/>'
            f'<rect x="{f(x + 7 * s)}" y="{f(y + 6 * s)}" width="{f(4 * s)}" height="{f(7 * s)}" fill="{ROOF}"/>')


def start_stage():
    out = card_open('sky')
    out.append(f'<rect y="56" width="{W}" height="{H - 56}" fill="url(#ground)"/>')
    out.append(f'<path d="M0 {PY - 8} L200 {PY - 8} L200 {PY + 10} L0 {PY + 10} Z" fill="{PATH}"/>')
    # The T-off branch going back to a hamlet.
    out.append(small_pole(122, 106, 82) + small_pole(146, 86, 66))
    out.append(house(160, 70, 0.8))
    out.append(conductor(f'M{TEE} 102 Q110 96 122 84 Q134 76 146 68 Q156 66 166 66', 1.4))
    # A kite caught on the T-off conductor (the lesson's "তারে আটকে থাকা ঘুড়ি"):
    # the clue every card shows; the T-off is where to look first.
    out.append(f'<path d="M134 76 l6 -9 l6 9 l-6 9 Z" fill="{KITE}" stroke="{KITE_D}" stroke-width="0.8"/>'
               f'<path d="M140 85 q-3 6 1 10 q4 4 0 10" stroke="{KITE_D}" stroke-width="1" fill="none"/>')
    # The substation yard at the left.
    out.append(f'<rect x="4" y="112" width="40" height="40" fill="url(#steel)" stroke="{COND_D}" stroke-width="1.2"/>')
    for i in range(6):
        out.append(f'<path d="M{6 + i * 7} 112 L{6 + i * 7} 152" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<rect x="14" y="122" width="20" height="18" rx="2" fill="url(#arm)"/>')
    out.append(f'<path d="M18 122 l0 -6 M24 122 l0 -6 M30 122 l0 -6" stroke="{COND_D}" stroke-width="2"/>')
    # The feeder poles and the line to the houses (the load) at the right.
    for x in FRONT:
        out.append(f'<rect x="{x - 2}" y="100" width="4" height="50" fill="url(#pole)"/>')
        out.append(f'<rect x="{x - 8}" y="102" width="16" height="3" fill="url(#arm)"/>')
    out.append(conductor('M30 116 Q46 108 62 102 Q79 106 96 102 Q113 106 130 102 Q147 106 164 102 Q178 106 188 122', 1.6))
    out.append(house(178, 124) + house(182, 146, 0.9))
    return out


def start_card(kind):
    out = start_stage()
    walk = dict(feet=((-9, -1), (8, -2)), hands=((-8, -31), (9, -33)))
    if kind == 'source':
        out.append(footprints(36, 48, PY + 4))
        out.append(man(56, PY, 0.62, 1, -4, props=map_sheet, **walk))
        out.append(motion(36, PY - 22))
    elif kind == 'split':
        out.append(man(54, PY, 0.62, 1, -6, hands=((-5, -30), (5, -60)), props=radio))
        out.append(man(170, PY, 0.62, -1, -6, hands=((-5, -30), (5, -60)), props=radio))
    elif kind == 'middle':
        out.append(footprints(118, 124, PY + 4))
        out.append(man(132, PY, 0.62, 1, -4, props=map_sheet, **walk))
        out.append(motion(112, PY - 22))
    elif kind == 'skiptee':
        # Far past the T-off, head down, the kite on the branch left behind him;
        # his prints run straight along the path, never toward the branch pole.
        out.append(footprints(36, 160, PY + 4, step=10))
        out.append(man(172, PY, 0.62, 1, 14, props=map_sheet, **walk))
        out.append(motion(150, PY - 22))
    elif kind == 'nocontact':
        out.append(man(54, PY, 0.62, 1, -6, hands=((-5, -30), (6, -58))))
        out.append(man(170, PY, 0.62, -1, -6, hands=((-5, -30), (6, -58))))
    elif kind == 'nomap':
        out.append(footprints(36, 88, PY + 4, step=10))
        # Both hands on the helmet, looking one way then the other at the fork.
        out.append(man(100, PY, 0.62, 1, -10, hands=((-6, -66), (8, -66))))
        out.append(f'<path d="M98 {PY - 56} q0 -6 5 -6 q5 0 5 5 q0 4 -5 5 l0 4" stroke="{MOVE}" stroke-width="2" fill="none" stroke-linecap="round"/>'
                   f'<circle cx="103" cy="{PY - 42}" r="1.4" fill="{MOVE}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — eyes: one pole close up.
# --------------------------------------------------------------------------

PX2 = 140


def eyes_stage(smashed=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<ellipse cx="80" cy="{GY + 8}" rx="11" ry="3.5" fill="{HOLE}"/>')
    # Conductors off both edges, the cross-arm and its insulators.
    for y in (24, 30):
        out.append(conductor(f'M0 {y + 8} Q70 {y} {PX2} {y - 1} Q170 {y} 200 {y + 6}', 1.8))
    out.append(f'<rect x="{PX2 - 5}" y="18" width="10" height="{GY - 18}" fill="url(#pole)"/>')
    out.append(f'<rect x="{PX2 - 30}" y="34" width="60" height="6" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(PX2 - 24, 34) + pin_insulator(PX2 + 24, 34) + pin_insulator(PX2, 18))
    out.append(crack(PX2 + 22, 20, 0.5))
    # The stay wire to its anchor.
    out.append(f'<path d="M{PX2 + 4} 70 L190 {GY - 3}" stroke="url(#steel)" stroke-width="2"/>')
    out.append(f'<rect x="185" y="{GY - 4}" width="10" height="4" rx="1" fill="{COND_D}"/>')
    # Step bolts.
    for i in range(6):
        y = 66 + i * 18
        side = -1 if i % 2 else 1
        out.append(f'<path d="M{PX2 + side * 5} {y} l{side * 5} 0" stroke="{COND_D}" stroke-width="2" stroke-linecap="round"/>')
    if smashed:
        # A vehicle hit: the base broken open, chips on the ground.
        out.append(f'<path d="M{PX2 - 5} {GY - 26} l7 4 l-4 6 l6 5 l-9 3 Z" fill="{HOLE}"/>')
        out.append(crack(PX2 - 2, GY - 44, 1.4) + crack(PX2 + 2, GY - 20, 1.0))
        out.append(f'<path d="M{PX2 - 16} {GY} l4 -4 l4 4 Z M{PX2 - 24} {GY} l3 -3 l3 3 Z M{PX2 + 9} {GY} l3 -4 l4 4 Z" fill="url(#pole)"/>')
    return out


def eyes_card(kind):
    looking = dict(hands=((5, -62), (9, -61)), props=binoculars)
    if kind == 'bino':
        out = eyes_stage()
        out.append(man(54, GY, 1.2, 1, -30, feet=((-4, -1), (4, -1)), **looking))
    elif kind == 'base':
        out = eyes_stage()
        out.append(man(108, GY, 1.2, 1, 22, feet=((-12, -1), (6, -1)), crouch=14, lean=3,
                       hands=((-2, -26), (22, -24))))
    elif kind == 'climb':
        out = eyes_stage()
        hip, sh, head = (126, 112), (129, 88), (132, 80)
        feet = ((128, 140), (134, 128))
        hands = ((PX2 - 4, 70), (PX2 - 4, 84))
        strap = (f'<path d="M131 108 Q{PX2} 96 {PX2 + 7} 103" stroke="{HARNESS}" stroke-width="2.4" fill="none"/>'
                 f'<path d="M{PX2 + 7} 103 Q{PX2 + 3} 112 131 112" stroke="{HARNESS}" stroke-width="2.4" fill="none" opacity="0.6"/>')
        out.append(strap + figure(hip, sh, head, feet, hands, 1, -24))
        out.append(f'<rect x="118" y="106" width="16" height="4" rx="1.5" fill="{HARNESS}"/>')
    elif kind == 'walkup':
        out = eyes_stage()
        out.append(man(62, GY, 1.2, 1, -30, feet=((-11, -1), (9, -3)), **looking))
        out.append(motion(30, GY - 50, 1, 0))
    elif kind == 'onlyup':
        # Right at the pole, standing on the broken base's chips, head thrown
        # back to the top: the smashed base at his feet goes unseen.
        out = eyes_stage(smashed=True)
        out.append(man(112, GY, 1.2, 1, -52, feet=((-4, -1), (4, -1)), lean=-1, **looking))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — senses: a pole that looks whole.
# --------------------------------------------------------------------------

PX3 = 156
BOX_Y = 106


def senses_stage(arcs=False, smell=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    for y in (22, 28):
        out.append(conductor(f'M0 {y + 8} Q80 {y} {PX3} {y - 1} Q180 {y} 200 {y + 4}', 1.8))
    out.append(f'<rect x="{PX3 - 5}" y="16" width="10" height="{GY - 16}" fill="url(#pole)"/>')
    out.append(f'<rect x="{PX3 - 30}" y="32" width="60" height="6" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(PX3 - 24, 32, dirty=True) + pin_insulator(PX3 + 24, 32) + pin_insulator(PX3, 16))
    # The cable riser and its box, scorched at the gland.
    out.append(f'<path d="M{PX3 - 7} 40 L{PX3 - 7} {BOX_Y}" stroke="{CRACK}" stroke-width="2.4"/>')
    out.append(f'<rect x="{PX3 - 16}" y="{BOX_Y}" width="16" height="20" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<ellipse cx="{PX3 - 10}" cy="{BOX_Y + 14}" rx="5" ry="4" fill="{SCORCH}" fill-opacity="0.85"/>')
    out.append(f'<path d="M{PX3 - 7} {BOX_Y + 20} L{PX3 - 7} {GY}" stroke="{CRACK}" stroke-width="2.4"/>')
    if arcs:
        cx, cy = PX3 - 24, 18
        for r in (6, 11, 16):
            out.append(f'<path d="M{f(cx - r * 0.6)} {f(cy - r * 0.8)} Q{f(cx - r * 1.2)} {f(cy)} {f(cx - r * 0.6)} {f(cy + r * 0.8)}" '
                       f'stroke="{SOUND}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    if smell:
        for i, dy in enumerate((-6, 2, 10)):
            x0, y0 = PX3 - 18, BOX_Y + 12 + dy
            out.append(f'<path d="M{f(x0)} {f(y0)} q-5 -4 -10 0 t-10 0 t-10 0" stroke="{SMELL}" stroke-width="1.6" fill="none" '
                       f'stroke-linecap="round" opacity="{0.9 - i * 0.15:.2f}"/>')
    return out


def earphones(p):
    hx, hy = p['head']
    face = p['face']
    hip = p['hip']
    ex = hx - 1 * face
    return (f'<circle cx="{f(ex)}" cy="{f(hy + 1)}" r="1.6" fill="{BIND}"/>'
            f'<path d="M{f(ex)} {f(hy + 2)} Q{f(ex - 3 * face)} {f(hy + 18)} {f(hip[0] + 2 * face)} {f(hip[1] - 2)}" stroke="{BIND}" stroke-width="0.9" fill="none"/>'
            f'<rect x="{f(hip[0] + 0.5 * face - 2)}" y="{f(hip[1] - 4)}" width="4" height="6" rx="1" fill="{BOOT}"/>')


def senses_card(kind):
    walk = dict(feet=((-11, -1), (9, -3)))
    if kind == 'ear':
        out = senses_stage(arcs=True)
        out.append(man(72, GY, 1.2, 1, -14, feet=((-4, -1), (4, -1)), hands=((-5, -30), (0, -63))))
    elif kind == 'nose':
        out = senses_stage(smell=True)
        # Stopped, leaning in toward the scorched box, the front arm pointing at
        # the smell's source (hands well away from the face).
        out.append(man(98, GY, 1.2, 1, 0, feet=((-6, -1), (6, -1)), lean=4, hands=((-5, -30), (20, -48))))
    elif kind == 'earphone':
        out = senses_stage(arcs=True)
        out.append(man(84, GY, 1.2, 1, 6, hands=((-9, -31), (9, -33)), props=earphones, **walk))
        out.append(motion(46, GY - 50, 1, 0))
    elif kind == 'shrug':
        out = senses_stage()
        out.append(man(90, GY, 1.2, 1, 0, hands=((-14, -58), (14, -58)), **walk))
        out.append(motion(52, GY - 50, 1, 0))
    elif kind == 'holdnose':
        out = senses_stage(smell=True)
        out.append(man(80, GY, 1.2, 1, 0, hands=((-9, -31), (8, -61)), lean=2, **walk))
        out.append(motion(42, GY - 50, 1, 0))
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 4-5 — the fallen wire on a dry road.
# --------------------------------------------------------------------------

ROAD_T, ROAD_B = 150, 204
WIRE_END = (112, 184)


def road_stage(pole_x=24, end=WIRE_END):
    out = card_open('sky')
    out.append(f'<rect y="118" width="{W}" height="{H - 118}" fill="url(#ground)"/>')
    out.append(f'<rect y="{ROAD_T}" width="{W}" height="{ROAD_B - ROAD_T}" fill="url(#road)"/>')
    out.append(f'<path d="M0 {(ROAD_T + ROAD_B) // 2} L200 {(ROAD_T + ROAD_B) // 2}" stroke="{BIND}" stroke-width="1.6" stroke-dasharray="10 9" opacity="0.7"/>')
    # The pole at the roadside, two whole conductors, the broken one down.
    out.append(f'<rect x="{pole_x - 4}" y="26" width="8" height="{ROAD_T - 26}" fill="url(#pole)"/>')
    out.append(f'<rect x="{pole_x - 18}" y="34" width="36" height="5" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(pole_x - 12, 34, 0.8) + pin_insulator(pole_x + 12, 34, 0.8) + pin_insulator(pole_x, 26, 0.8))
    out.append(conductor(f'M0 {28} Q{pole_x} 22 {pole_x + 12} 23 Q120 34 200 30', 1.8))
    out.append(conductor(f'M0 {16} Q{pole_x - 4} 12 {pole_x} 14 Q120 24 200 18', 1.8))
    ex, ey = end
    out.append(conductor(f'M{pole_x - 12} 24 Q{pole_x + 6} 120 {pole_x + 36} 176 Q{(pole_x + 36 + ex) / 2:.0f} {ey + 6} {ex} {ey}', 2.2))
    out.append(f'<path d="M{ex} {ey} l4 -3 M{ex} {ey} l5 1 M{ex} {ey} l3 4" stroke="{COND}" stroke-width="1.2" stroke-linecap="round"/>')
    return out


def rope_coil(x, y):
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="8" ry="3.5" stroke="{ROPE}" stroke-width="2.4" fill="none"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y - 1.5)}" rx="5" ry="2.2" stroke="{ROPE_D}" stroke-width="1.6" fill="none"/>')


def rope_ring(cx, cy, rx, ry, stakes=8):
    o = [f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" stroke="{ROPE}" stroke-width="2" fill="none"/>']
    for i in range(stakes):
        a = 2 * math.pi * i / stakes + 0.3
        x, y = cx + rx * math.cos(a), cy + ry * math.sin(a)
        o.append(f'<rect x="{f(x - 1.2)}" y="{f(y - 8)}" width="2.4" height="9" fill="{ROPE_D}"/>')
    return ''.join(o)


def wire_card(kind):
    out = road_stage()
    if kind == 'cordon':
        out.append(rope_ring(84, 176, 70, 26))
        out.append(man(178, 196, 0.86, -1, 0, hands=((-5, -30), (10, -34))))
        out.append(f'<path d="M{f(178 - 10 * 0.86)} {f(196 - 34 * 0.86)} Q166 172 154 {176}" stroke="{ROPE}" stroke-width="2" fill="none"/>')
    elif kind == 'stop':
        out.append(rope_coil(162, 200))
        out.append(man(180, 196, 0.86, -1, 0, feet=((-4, -1), (4, -1)), hands=((-5, -30), (12, -60))))
    elif kind == 'stick':
        out.append(rope_coil(176, 200))
        out.append(man(136, 196, 0.86, -1, 10, lean=2, hands=((8, -40), (14, -44))))
        out.append(f'<path d="M{f(136 - 14 * 0.86)} {f(196 - 44 * 0.86)} L{WIRE_END[0] - 2} {WIRE_END[1] - 8}" stroke="{STICK}" stroke-width="2.6" stroke-linecap="round"/>')
    elif kind == 'close':
        out.append(rope_coil(176, 200))
        out.append(man(128, 196, 0.86, -1, 34, feet=((-6, -1), (8, -1)), crouch=12, lean=5, hands=((8, -22), (14, -24))))
    elif kind == 'tight':
        out.append(rope_ring(92, 180, 30, 11, 6))
        out.append(man(146, 196, 0.86, -1, 6, hands=((-5, -30), (10, -34))))
        out.append(f'<path d="M{f(146 - 10 * 0.86)} {f(196 - 34 * 0.86)} Q132 176 122 180" stroke="{ROPE}" stroke-width="2" fill="none"/>')
    elif kind == 'stepover':
        out.append(rope_coil(176, 200))
        out.append(man(96, 192, 0.86, 1, 10, feet=((-12, -6), (12, 0)), hands=((-10, -32), (10, -34))))
        out.append(motion(70, 150, 1, 0))
    return card_close(out)


EXIT_END = (84, 182)


def exit_stage():
    out = road_stage(pole_x=14, end=EXIT_END)
    ex, ey = EXIT_END
    for i, r in enumerate((16, 34, 54)):
        out.append(f'<ellipse cx="{ex}" cy="{ey}" rx="{r}" ry="{f(r * 0.34)}" stroke="{VOLT}" stroke-width="1.4" fill="none" '
                   f'stroke-dasharray="4 4" opacity="{0.75 - i * 0.18:.2f}"/>')
    return out


def exit_card(kind):
    out = exit_stage()
    if kind == 'shuffle':
        out.append(footprints(104, 122, 197, step=4.5, pair=1.0, size=1.1, color=BIND))
        out.append(man(132, 196, 0.86, 1, 4, feet=((-2, -1), (3, -1)), hands=((-6, -30), (7, -30))))
    elif kind == 'hop':
        for x0 in (100, 116):
            out.append(f'<path d="M{x0} 194 q7 -16 14 0" stroke="{MOVE}" stroke-width="2" fill="none" stroke-dasharray="3 2.5"/>')
        out.append(man(138, 196, 0.86, 1, 0, feet=((-2, -1), (3, -1)), hands=((-9, -38), (10, -38)), crouch=4, lift=10))
    elif kind == 'stride':
        out.append(footprints(102, 138, 196, step=18, color=BIND))
        out.append(man(150, 196, 0.86, 1, 4, feet=((-17, -1), (16, -6)), lean=3, hands=((-12, -34), (12, -40))))
        out.append(motion(118, 160, 1, 0))
    elif kind == 'wide':
        out.append(man(122, 196, 0.86, 1, 0, feet=((-15, -1), (15, -1)), hands=((-16, -40), (16, -40))))
    elif kind == 'toward':
        out.append(footprints(150, 122, 196, step=9, color=BIND))
        out.append(man(112, 196, 0.86, -1, 6, feet=((-9, -1), (8, -2)), hands=((-8, -31), (9, -33))))
        out.append(motion(140, 160, -1, 0))
    return card_close(out)


CARDS = {
    'start_source': start_card('source'),
    'start_split': start_card('split'),
    'start_middle': start_card('middle'),
    'start_skiptee': start_card('skiptee'),
    'start_nocontact': start_card('nocontact'),
    'start_nomap': start_card('nomap'),
    'eyes_bino': eyes_card('bino'),
    'eyes_base': eyes_card('base'),
    'eyes_climb': eyes_card('climb'),
    'eyes_walkup': eyes_card('walkup'),
    'eyes_onlyup': eyes_card('onlyup'),
    'senses_ear': senses_card('ear'),
    'senses_nose': senses_card('nose'),
    'senses_earphone': senses_card('earphone'),
    'senses_shrug': senses_card('shrug'),
    'senses_holdnose': senses_card('holdnose'),
    'wire_cordon': wire_card('cordon'),
    'wire_stop': wire_card('stop'),
    'wire_stick': wire_card('stick'),
    'wire_close': wire_card('close'),
    'wire_tight': wire_card('tight'),
    'wire_stepover': wire_card('stepover'),
    'exit_shuffle': exit_card('shuffle'),
    'exit_hop': exit_card('hop'),
    'exit_stride': exit_card('stride'),
    'exit_wide': exit_card('wide'),
    'exit_toward': exit_card('toward'),
}

# Safe cards and traps per round (mirrors learn_board_pack52.dart).
ROUNDS = {
    'start': ({'start_source', 'start_split'}, {'start_middle', 'start_skiptee', 'start_nocontact', 'start_nomap'}),
    'eyes': ({'eyes_bino', 'eyes_base'}, {'eyes_climb', 'eyes_walkup', 'eyes_onlyup'}),
    'senses': ({'senses_ear', 'senses_nose'}, {'senses_earphone', 'senses_shrug', 'senses_holdnose'}),
    'wire': ({'wire_cordon', 'wire_stop'}, {'wire_stick', 'wire_close', 'wire_tight', 'wire_stepover'}),
    'exit': ({'exit_shuffle', 'exit_hop'}, {'exit_stride', 'exit_wide', 'exit_toward'}),
}
HAND = 4

# --------------------------------------------------------------------------
# The painted-token check (as tool/scan_board_art.py and its test).
# --------------------------------------------------------------------------

_ELEM = re.compile(r'<(/?)([\w:]+)\b([^>]*?)(/?)>')
_ATTR = re.compile(r'([\w:-]+)="([^"]*)"')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
_NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
_XFORM = re.compile(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)')
_PATH_TOK = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
_NO_PAINT = {'g', 'svg', 'a', 'switch'}
_DEFS = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'}
_INHERIT = ('fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility')
_ID = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def _num(v, default=1.0):
    try:
        v = v.strip()
        return float(v[:-1]) / 100 if v.endswith('%') else float(v)
    except (AttributeError, TypeError, ValueError):
        return default


def _attrs(raw):
    a = dict(_ATTR.findall(raw))
    for part in a.pop('style', '').split(';'):
        if ':' in part:
            k, v = part.split(':', 1)
            a[k.strip()] = v.strip()
    return a


def _mul(m, n):
    a1, b1, c1, d1, e1, f1 = m
    a2, b2, c2, d2, e2, f2 = n
    return (a1 * a2 + c1 * b2, b1 * a2 + d1 * b2, a1 * c2 + c1 * d2, b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1, b1 * e2 + d1 * f2 + f1)


def _transform(text):
    m = _ID
    for fn, args in _XFORM.findall(text or ''):
        v = [float(x) for x in _NUM.findall(args)]
        if fn == 'matrix' and len(v) == 6:
            t = tuple(v)
        elif fn == 'translate' and v:
            t = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif fn == 'scale' and v:
            t = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif fn == 'rotate' and v:
            r = math.radians(v[0])
            t = (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)
            if len(v) >= 3:
                t = _mul(_mul((1, 0, 0, 1, v[1], v[2]), t), (1, 0, 0, 1, -v[1], -v[2]))
        elif fn == 'skewX' and v:
            t = (1, 0, math.tan(math.radians(v[0])), 1, 0, 0)
        elif fn == 'skewY' and v:
            t = (1, math.tan(math.radians(v[0])), 0, 1, 0, 0)
        else:
            continue
        m = _mul(m, t)
    return m


def _path_points(d):
    toks = _PATH_TOK.findall(d)
    arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0}
    pts, i, cmd = [], 0, None
    x = y = sx = sy = 0.0
    last_c = None
    try:
        while i < len(toks):
            if toks[i].isalpha():
                cmd = toks[i]
                i += 1
                if cmd in 'zZ':
                    x, y = sx, sy
                    pts.append((x, y))
                    last_c = None
                    continue
            if cmd is None:
                return None
            n = arity[cmd.lower()]
            v = [float(t) for t in toks[i:i + n]]
            if len(v) < n:
                return None
            i += n
            rel = cmd.islower()
            ox, oy = (x, y) if rel else (0.0, 0.0)
            c = cmd.lower()
            if c == 'h':
                x = v[0] + (x if rel else 0)
                pts.append((x, y))
                last_c = None
            elif c == 'v':
                y = v[0] + (y if rel else 0)
                pts.append((x, y))
                last_c = None
            elif c == 'a':
                ex, ey = v[5] + ox, v[6] + oy
                r = 2 * max(abs(v[0]), abs(v[1]), math.hypot(ex - x, ey - y))
                pts += [(x - r, y - r), (x + r, y + r), (ex, ey)]
                x, y = ex, ey
                last_c = None
            else:
                ctrl = [(v[k] + ox, v[k + 1] + oy) for k in range(0, n, 2)]
                if c in 'st':
                    ref = (2 * x - last_c[0], 2 * y - last_c[1]) if last_c else (x, y)
                    ctrl.insert(0, ref)
                pts += ctrl
                last_c = ctrl[-2] if len(ctrl) > 1 else None
                x, y = ctrl[-1]
                if c == 'm':
                    sx, sy = x, y
                    cmd = 'l' if rel else 'L'
    except (ValueError, KeyError, IndexError):
        return None
    return pts or None


def _local_points(tag, a):
    n = lambda k: _num(a.get(k), 0.0)
    if tag == 'rect':
        return [(n('x'), n('y')), (n('x') + n('width'), n('y') + n('height'))]
    if tag == 'circle':
        return [(n('cx') - n('r'), n('cy') - n('r')), (n('cx') + n('r'), n('cy') + n('r'))]
    if tag == 'ellipse':
        return [(n('cx') - n('rx'), n('cy') - n('ry')), (n('cx') + n('rx'), n('cy') + n('ry'))]
    if tag == 'line':
        return [(n('x1'), n('y1')), (n('x2'), n('y2'))]
    if tag in ('polygon', 'polyline'):
        v = [float(t) for t in _NUM.findall(a.get('points', ''))]
        return list(zip(v[0::2], v[1::2])) or None
    if tag == 'path':
        return _path_points(a.get('d', ''))
    return None


def _paint(tag, a):
    fill_on = a.get('fill') != 'none' and _num(a.get('fill-opacity')) > 0
    stroke_on = (a.get('stroke') not in (None, 'none') and _num(a.get('stroke-opacity')) > 0
                 and _num(a.get('stroke-width')) > 0)
    if tag == 'rect' and (_num(a.get('width'), 0) <= 0 or _num(a.get('height'), 0) <= 0):
        return fill_on, stroke_on, False
    if tag == 'circle' and _num(a.get('r'), 0) <= 0:
        return fill_on, stroke_on, False
    if tag == 'ellipse' and (_num(a.get('rx'), 0) <= 0 or _num(a.get('ry'), 0) <= 0):
        return fill_on, stroke_on, False
    if tag in ('path', 'polygon', 'polyline') and not (a.get('d') or a.get('points')):
        return fill_on, stroke_on, False
    if tag == 'line':
        fill_on = False
        if a.get('x1') == a.get('x2') and a.get('y1') == a.get('y2'):
            return fill_on, stroke_on, False
    return fill_on, stroke_on, fill_on or stroke_on


def painted(svg):
    root = re.search(r'<svg\b[^>]*viewBox="([^"]*)"', svg)
    vb = [float(t) for t in _NUM.findall(root.group(1))] if root else []
    x0, y0, cw, ch = vb if len(vb) == 4 else (0.0, 0.0, 200.0, 220.0)
    stack = [('#doc', False, False, {}, _ID)]
    for close, tag, raw, self_close in _ELEM.findall(svg):
        if close:
            for k in range(len(stack) - 1, 0, -1):
                if stack[k][0] == tag:
                    del stack[k:]
                    break
            continue
        _, p_hidden, p_defs, p_inh, p_m = stack[-1]
        own = _attrs(raw)
        inh = dict(p_inh)
        for k in _INHERIT:
            if k in own:
                inh[k] = own[k]
        m = _mul(p_m, _transform(own.get('transform')))
        in_defs = p_defs or tag in _DEFS
        hidden = (p_hidden or own.get('display') == 'none' or _num(own.get('opacity')) <= 0
                  or abs(m[0] * m[3] - m[1] * m[2]) < 1e-9)
        if not (self_close or raw.rstrip().endswith('/')):
            stack.append((tag, hidden, in_defs, inh, m))
        if in_defs or hidden or tag in _NO_PAINT or inh.get('visibility') in ('hidden', 'collapse'):
            continue
        a = dict(own)
        a.update(inh)
        fill_on, stroke_on, seen = _paint(tag, a)
        if not seen:
            continue
        pts = _local_points(tag, a)
        if pts:
            pad = 2 * _num(a.get('stroke-width')) if stroke_on else 0.0
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            box = [(min(xs) - pad, min(ys) - pad), (max(xs) + pad, min(ys) - pad),
                   (min(xs) - pad, max(ys) + pad), (max(xs) + pad, max(ys) + pad)]
            tx = [m[0] * px + m[2] * py + m[4] for px, py in box]
            ty = [m[1] * px + m[3] * py + m[5] for px, py in box]
            if max(tx) <= x0 or min(tx) >= x0 + cw or max(ty) <= y0 or min(ty) >= y0 + ch:
                continue
        yield tag, a, fill_on, stroke_on


def tokens(svg):
    out = set()
    for tag, a, fill_on, stroke_on in painted(svg):
        if fill_on and 'fill' in a:
            out.update(_TOKEN.findall(a['fill']))
        if stroke_on and 'stroke' in a:
            out.update(_TOKEN.findall(a['stroke']))
    return out


def fairness_problems():
    tok = {k: tokens(v) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    problems = []
    for rnd, (safes, traps) in ROUNDS.items():
        for s in sorted(safes):
            for hand_ in itertools.combinations(sorted(traps), HAND - 1):
                if back[s] not in {back[t] for t in hand_}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand_}')
                only = tok[s] - set().union(*(tok[t] for t in hand_))
                if only:
                    problems.append(f'{rnd}: {s} with {hand_} draws {sorted(only)} alone')
        for name in safes | traps:
            if '<text' in CARDS[name]:
                problems.append(f'{rnd}: {name} has words in the art')
    for name, svg in CARDS.items():
        clips = set(re.findall(r'clip-path="([^"]*)"', svg)) - {'url(#card)'}
        if clips or re.search(r'\b(mask|filter)="|<use\b|<image\b|<foreignObject\b', svg):
            problems.append(f'{name}: paint the fairness check cannot follow')
    return problems


if __name__ == '__main__':
    bad = fairness_problems()
    if bad:
        print('\n'.join('UNFAIR ' + p for p in bad))
        sys.exit(1)
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}; every hand fair')
