"""Picture cards for lesson 7.3 শেখা ("ন্যূনতম ক্লিয়ারেন্স: আইনত কতটা দূরত্ব?").

python -I tool/m7_board73_art.py .

Writes assets/game/art/m7_board73/*.svg in the clean gradient style of
tool/m6_board63_art.py and tool/m7_board72_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art. The only marks a worker reads are
the pole plate (415 V / 11 kV / 33 kV) and a measured dimension tag in
metres ('6.5 m'), both drawn as stroke glyphs with English digits and
letters (owner question 3 of the item spec: a worker-readable label).

What the cards show comes from lesson 7.3 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md: M7-7, X5) only. The drawings
are to scale (18 px a metre up, 30 px a metre across), so the tag and the
picture agree. Five rounds:
  1. road: a line across a road. Safe: 11 kV at 6.5 m over a bus, 415 V at
     5.8 m over a truck, 33 kV at 6.5 m on a hot day. Traps: 11 kV at 5.8 m
     (the LT figure), an old 33 kV span at 6.1 m (below today's rule, report
     it — ruling X5), an 11 kV span sagging to 5.6 m in the heat (pro tip 3),
     415 V at 5.0 m over a bus;
  2. roof: a line over a roof. Safe: 415 V at 2.5 m over a flat roof, 11 kV
     at 3.7 m over the চিলেকোঠা's top. Traps: 11 kV at 2.5 m (the LT figure),
     415 V with the চিলেকোঠা rising to 1.0 m under it, masons raising a new
     floor under an 11 kV line (pro tip 2);
  3. side: a line beside a house (end view). Safe: 415 V at 1.2 m from the
     balcony, 33 kV at 2.0 m from the wall (M7-7: HT side sites are 33 kV
     only). Traps: 33 kV at 1.2 m, 415 V at 0.3 m from a balcony grill, a new
     balcony slab cast out to 0.6 m from a 33 kV line;
  4. section: lines on one pole (no figures; the lesson gives none). Safe:
     two circuits with a wide even gap on a windy day, a telephone/internet
     cable well below the power line. Traps: conductors swinging into each
     other in the wind (a spark), the cable tied against the LT wire,
     phases bunched on a short arm;
  5. duty: the lineman near a line. Safe: he raises a hand to stop a man
     carrying an iron rod toward the line; he phones about construction
     under the line; he phones about a sagging old span. Traps: he chats on
     the phone while a man carries a bamboo under the line; he walks past
     wet clothes hung under the wire; he walks past a bamboo leaning toward
     the wire on a windy roof; he walks past a low sagging span, on the
     phone.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, the safe card's backdrop is a trap's backdrop too, and
every prop or figure (tagged <!--prop:name-->: lineman, bus, truck, sun,
wind, phone, house...) on the safe card is on a trap in that hand, and none
sits on every trap of the hand but not on the safe card. It deletes only its
own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board73_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board73')
W, H = 200, 220
GY = 198
UP = 18.0      # px per metre, up
ACROSS = 30.0  # px per metre, across (the side round)

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
WIRE = '#2B3138'
INK = '#4A5560'
PLATE = '#F4F1E6'
CIVIL = '#B5523B'       # a passer-by's shirt
CIVIL_D = '#923F2C'
SAREE = '#9C2D4A'
SAREE_D = '#7A2038'
MASON = '#8C8F6A'       # a mason's vest
MASON_D = '#6E714F'
BRICK = '#B4583A'
BRICK_D = '#8F4229'
WOOD = '#8A6440'
WOOD_D = '#6B4A2E'
BAMBOO = '#C9B26A'
BAMBOO_D = '#9E8848'
BUS = '#2F7FB8'
BUS_D = '#245F8A'
TRUCK = '#D9822B'
TRUCK_D = '#A9631C'
GLASS = '#BFD9E8'
SUN = '#FFC93C'
SUN_D = '#F2A92A'
CLOTH_1 = '#E26D5A'
CLOTH_2 = '#5AA0D8'
CABLE = '#15181C'
SPARK = '#FFF2A8'
ARROW = '#C8352B'       # the dimension arrow (on every tagged card)
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="street" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FBCE0"/><stop offset="0.74" stop-color="#E2EAEE"/><stop offset="0.74" stop-color="#6E747A"/><stop offset="1" stop-color="#5A6066"/></linearGradient>
  <linearGradient id="town" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9CC3E0"/><stop offset="0.8" stop-color="#E4E8E0"/><stop offset="0.8" stop-color="#BDB7A2"/><stop offset="1" stop-color="#A9A28C"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E4C9A2"/><stop offset="1" stop-color="#C8A87E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def tag(name):
    """An XML comment naming a prop or figure on the card. The fairness check
    (here and in test/learn_board_73_test.dart) reads these: no prop may sit
    only on the safe card of a hand, or be missing only from it."""
    return f'<!--prop:{name}-->'


# Contact check. Every card records its conductors (the span() curves) and
# the points that must never reach them: each person's head and hands, the
# two ends of a held or leaning rod or bamboo, the top corners of a bus or
# truck, a clothes line. card_close() writes the smallest air gap (px, after
# the wire's stroke and the point's own radius) as <!--gap:N-->, and the
# build fails below MIN_GAP (the test checks the same tag): on this board nobody and nothing touches the line (R17, a
# passer-by's rod reaching the line, is do_7_3_b's deadly act).
MIN_GAP = 12.0
_GEOM = {'wires': [], 'pts': []}


def _wire(x0, y0, cx, cy, x1, y1, w):
    _GEOM['wires'].append((x0, y0, cx, cy, x1, y1, w))


def _pt(x, y, r):
    _GEOM['pts'].append((x, y, r))


def min_gap(wires, pts, steps=400):
    best = None
    for (x0, y0, cx, cy, x1, y1, w) in wires:
        curve = []
        for i in range(steps + 1):
            t = i / steps
            a, b, c = (1 - t) ** 2, 2 * t * (1 - t), t * t
            curve.append((a * x0 + b * cx + c * x1, a * y0 + b * cy + c * y1))
        for (px, py, r) in pts:
            d = min(math.hypot(px - qx, py - qy) for qx, qy in curve) - r - w / 2
            best = d if best is None else min(best, d)
    return best


def card_open(back):
    _GEOM['wires'], _GEOM['pts'] = [], []
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    gap = min_gap(_GEOM['wires'], _GEOM['pts']) if _GEOM['wires'] and _GEOM['pts'] else None
    if gap is not None:
        out.append(f'<!--gap:{gap:.1f}-->')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# Glyphs: English digits, '.', 'k', 'V', 'm' as strokes (no <text>).
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'k': ([(0, 0, 0, 10), (5, 4, 0.5, 7.5), (2, 6.5, 5.5, 10)], 7.4),
    'V': ([(0, 0, 3, 10), (3, 10, 6, 0)], 8.0),
    'm': ([(0, 10, 0, 4.5), (0, 5.5, 1.6, 4), (1.6, 4, 3, 5.2), (3, 5.2, 3, 10), (3, 5.2, 4.4, 4), (4.4, 4, 6, 5.5), (6, 5.5, 6, 10)], 8.4),
}


def glyph_width(text, h):
    k = h / 10
    w = 0.0
    for ch in text:
        if ch in _DIG:
            w += (5.4 if ch == '1' else 7.8) * k
        elif ch == '.':
            w += 3.2 * k
        elif ch == ' ':
            w += 3.4 * k
        else:
            w += _LET[ch][1] * k
    return w - 1.8 * k


def glyphs(x, y, text, h=10.0, color=INK):
    k = h / 10
    d = []
    ox = x
    for ch in text:
        if ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox
            for s in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[s]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
        elif ch == '.':
            d.append(f'M{f(ox + 0.6 * k)} {f(y + 10 * k)} l0.01 0')
            ox += 3.2 * k
        elif ch == ' ':
            ox += 3.4 * k
        else:
            segs, adv = _LET[ch]
            for x0, y0, x1, y1 in segs:
                d.append(f'M{f(ox + x0 * k)} {f(y + y0 * k)} L{f(ox + x1 * k)} {f(y + y1 * k)}')
            ox += adv * k
    return f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'


def label_box(cx, cy, text, h=9.0):
    """A white tag with [text] centred on (cx, cy)."""
    w = glyph_width(text, h) + 8
    x, y = cx - w / 2, cy - h / 2 - 3
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h + 6)}" rx="2.5" fill="{PLATE}" stroke="{INK}" stroke-width="0.8"/>'
            + glyphs(x + 4, y + 3, text, h))


def plate(x, y, volts):
    """The pole's voltage plate ('415V', '11kV', '33kV'). The comment lets
    the test match the plate with the card's label."""
    return f'<!--plate:{volts}-->' + label_box(x, y, volts, 8.0)


def v_dim(x, y_low, y_high, metres, side=1):
    """A vertical dimension arrow from y_low (ground / roof) up to y_high (the
    wire), its tag beside it ('6.5m')."""
    head = 4
    o = [f'<path d="M{f(x)} {f(y_low)} L{f(x)} {f(y_high)}" stroke="{ARROW}" stroke-width="1.2" stroke-dasharray="3 2"/>',
         f'<path d="M{f(x - head)} {f(y_high + head + 1)} L{f(x)} {f(y_high)} L{f(x + head)} {f(y_high + head + 1)}" stroke="{ARROW}" stroke-width="1.4" fill="none"/>',
         f'<path d="M{f(x - head)} {f(y_low - head - 1)} L{f(x)} {f(y_low)} L{f(x + head)} {f(y_low - head - 1)}" stroke="{ARROW}" stroke-width="1.4" fill="none"/>']
    tx = x + side * 24
    o.append(f'<!--dim:{metres}-->' + label_box(tx, (y_low + y_high) / 2, f'{metres}m', 10.0))
    return ''.join(o)


def h_dim(x0, x1, y, metres):
    """A horizontal dimension arrow from x0 (the house) to x1 (the wire)."""
    head = 4
    o = [f'<path d="M{f(x0)} {f(y)} L{f(x1)} {f(y)}" stroke="{ARROW}" stroke-width="1.2" stroke-dasharray="3 2"/>',
         f'<path d="M{f(x0 + head + 1)} {f(y - head)} L{f(x0)} {f(y)} L{f(x0 + head + 1)} {f(y + head)}" stroke="{ARROW}" stroke-width="1.4" fill="none"/>',
         f'<path d="M{f(x1 - head - 1)} {f(y - head)} L{f(x1)} {f(y)} L{f(x1 - head - 1)} {f(y + head)}" stroke="{ARROW}" stroke-width="1.4" fill="none"/>']
    o.append(f'<!--dim:{metres}-->' + label_box(max(28, (x0 + x1) / 2), y - 15, f'{metres}m', 10.0))
    return ''.join(o)


# --------------------------------------------------------------------------
# People: the lineman of tool/m6_board63_art.py, a passer-by, a woman, a
# mason.
# --------------------------------------------------------------------------

OUTFITS = {
    'lineman': dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='helmet'),
    'public': dict(torso=CIVIL, sb=CIVIL_D, sf=CIVIL, pants=PANTS, pants_d=PANTS_D, head='bare'),
    'woman': dict(torso=SAREE, sb=SAREE_D, sf=SAREE, pants=SAREE, pants_d=SAREE_D, head='bun', saree=True),
    'mason': dict(torso=MASON, sb=MASON_D, sf=MASON, pants=PANTS, pants_d=PANTS_D, head='bare'),
}

KIND_TAG = {'lineman': 'lineman', 'public': 'public', 'woman': 'public', 'mason': 'mason'}


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


def figure(hip, sh, head, feet, hands, face=1, look=0, kind='lineman', phone=False, held=''):
    o = OUTFITS[kind]
    g = []
    fb, ff = feet
    if o.get('saree'):
        g.append(f'<path d="M{f(hip[0] - 9)} {f(hip[1] - 4)} L{f(hip[0] - 12)} {f(fb[1])} L{f(hip[0] + 12)} {f(fb[1])} L{f(hip[0] + 9)} {f(hip[1] - 4)} Z" fill="{SAREE_D}"/>')
    else:
        g.append(_limb(hip, _joint(hip, fb, face), fb, o['pants_d'], 7))
        g.append(_boot(fb, face))
        g.append(_limb(hip, _joint(hip, ff, face), ff, o['pants'], 7))
        g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, o['sb'], 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{SKIN}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="{o["torso"]}"/>')
    if not o.get('saree'):
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    hk = o['head']
    if hk == 'helmet':
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>')
        hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    elif hk == 'bun':
        hd.append(f'<path d="M{f(hx - 7)} {f(hy)} A7 7 0 0 1 {f(hx + 7)} {f(hy)} Z" fill="{HAIR}"/>')
        hd.append(f'<circle cx="{f(hx - 7 * face)}" cy="{f(hy + 1)}" r="3.2" fill="{HAIR}"/>')
    else:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="{HAIR}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(held)
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, o['sf'], 5.4))
    if phone:
        g.append(f'<rect x="{f(hf[0] - 2.5)}" y="{f(hf[1] - 6)}" width="5" height="9" rx="1" fill="{WIRE}"/>'
                 f'<rect x="{f(hf[0] - 1.6)}" y="{f(hf[1] - 5)}" width="3.2" height="6" fill="url(#lcd)"/>')
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{SKIN}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, s=S, kind='lineman', phone=False, held=''):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates. With [phone], the front hand goes to
    his ear. [held] (card coordinates) is drawn between the arms."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hb = local(hands_world[0])
    hf = (head[0] - 5 * face, head[1] + 2) if phone else local(hands_world[1])
    held_local = f'<g transform="translate({f(x)} {f(gy)}) scale({f(1 / s)}) translate({f(-x)} {f(-gy)})">{held}</g>' if held else ''
    fig = figure(hip, sh, head, feet, (hb, hf), face, look, kind, phone, held_local)
    def world(p):
        return (x + (p[0] - x) * s, gy + (p[1] - gy) * s)
    _pt(*world(head), 8 * s)
    for h in (hb, hf):
        _pt(*world(h), 3 * s)
    tags = tag(KIND_TAG[kind]) + (tag('phone') if phone else '')
    return tags + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def pole(x, top, bottom=GY, wdt=7):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{wdt}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def arm(x, y, half=18):
    return f'<rect x="{f(x - half)}" y="{f(y)}" width="{2 * half}" height="3.4" fill="{INK}"/>'


def insulator(x, y):
    return f'<rect x="{f(x - 1.6)}" y="{f(y - 5)}" width="3.2" height="5" rx="1" fill="{PLATE}" stroke="{INK}" stroke-width="0.5"/>'


def span(x0, x1, y_end, y_low, color=WIRE, w=1.6, dx=0.0):
    """A wire hanging from (x0, y_end) to (x1, y_end), lowest at y_low mid-span
    (a quadratic through the low point); [dx] swings the middle sideways."""
    cx = (x0 + x1) / 2 + dx
    cy = 2 * y_low - y_end
    _wire(x0, y_end, cx, cy, x1, y_end, w)
    return f'<path d="M{f(x0)} {f(y_end)} Q{f(cx)} {f(cy)} {f(x1)} {f(y_end)}" stroke="{color}" stroke-width="{w}" fill="none"/>'


def sun(x=164, y=30):
    rays = ''.join(
        f'<path d="M{f(x + 15 * math.cos(a))} {f(y + 15 * math.sin(a))} L{f(x + 21 * math.cos(a))} {f(y + 21 * math.sin(a))}" stroke="{SUN_D}" stroke-width="2" stroke-linecap="round"/>'
        for a in [i * math.pi / 4 for i in range(8)])
    return tag('sun') + f'<circle cx="{f(x)}" cy="{f(y)}" r="11" fill="{SUN}"/>' + rays


def wind(x=12, y=26):
    return tag('wind') + ''.join(
        f'<path d="M{f(x)} {f(y + i * 9)} q12 -5 24 0 t24 0" stroke="{MOVE}" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-opacity="0.9"/>'
        for i in range(3))


def bus(x, gy=GY):
    """A bus about 3.2 m tall."""
    top = gy - 3.2 * UP
    _pt(x, top, 0)
    _pt(x + 74, top, 0)
    o = [tag('bus'), f'<rect x="{f(x)}" y="{f(top)}" width="74" height="{f(3.2 * UP - 6)}" rx="5" fill="{BUS}"/>',
         f'<rect x="{f(x)}" y="{f(gy - 18)}" width="74" height="6" fill="{BUS_D}"/>']
    for i in range(5):
        o.append(f'<rect x="{f(x + 5 + i * 13.5)}" y="{f(top + 6)}" width="10" height="13" rx="1.5" fill="{GLASS}"/>')
    for cx in (x + 15, x + 58):
        o.append(f'<circle cx="{f(cx)}" cy="{f(gy - 5)}" r="6" fill="{BOOT}"/><circle cx="{f(cx)}" cy="{f(gy - 5)}" r="2.4" fill="{INK}"/>')
    return ''.join(o)


def truck(x, gy=GY):
    """A loaded truck about 3.8 m tall (its load the top)."""
    top = gy - 3.8 * UP
    _pt(x, top, 0)
    _pt(x + 52, top, 0)
    o = [tag('truck'),
         f'<rect x="{f(x)}" y="{f(top)}" width="52" height="{f(3.8 * UP - 12)}" rx="2" fill="{TRUCK}"/>',
         f'<path d="M{f(x)} {f(top + 10)} h52 M{f(x)} {f(top + 24)} h52" stroke="{TRUCK_D}" stroke-width="1.4"/>',
         f'<path d="M{f(x + 54)} {f(gy - 12)} L{f(x + 54)} {f(gy - 44)} L{f(x + 68)} {f(gy - 44)} L{f(x + 76)} {f(gy - 28)} L{f(x + 76)} {f(gy - 12)} Z" fill="{TRUCK_D}"/>',
         f'<rect x="{f(x + 58)}" y="{f(gy - 40)}" width="10" height="11" rx="1" fill="{GLASS}"/>']
    for cx in (x + 12, x + 40, x + 64):
        o.append(f'<circle cx="{f(cx)}" cy="{f(gy - 5)}" r="6" fill="{BOOT}"/><circle cx="{f(cx)}" cy="{f(gy - 5)}" r="2.4" fill="{INK}"/>')
    return ''.join(o)


def road_marks():
    return ''.join(f'<rect x="{6 + i * 40}" y="{GY + 6}" width="22" height="3" fill="{PLATE}" opacity="0.8"/>' for i in range(5))


def house_block(x, w, roof_y, floors_line=True):
    """A flat-roofed house from x to x+w, roof at roof_y."""
    o = [tag('house'), f'<rect x="{f(x)}" y="{f(roof_y)}" width="{f(w)}" height="{f(GY - roof_y)}" fill="url(#house)"/>',
         f'<rect x="{f(x - 2)}" y="{f(roof_y - 3)}" width="{f(w + 4)}" height="4" fill="{WOOD_D}"/>']
    if floors_line:
        mid = (roof_y + GY) / 2
        o.append(f'<path d="M{f(x)} {f(mid)} h{f(w)}" stroke="{WOOD_D}" stroke-width="1.4"/>')
    for wy in (roof_y + 10, (roof_y + GY) / 2 + 8):
        if wy + 16 < GY:
            o.append(f'<rect x="{f(x + 10)}" y="{f(wy)}" width="14" height="14" fill="{GLASS}" stroke="{WOOD_D}" stroke-width="1.2"/>')
    return ''.join(o)


def stair_room(x, roof_y, height_m=2.5):
    """A চিলেকোঠা (stair room) on the roof; returns (svg, top_y)."""
    top = roof_y - height_m * UP
    svg = (tag('stairroom') + f'<rect x="{f(x)}" y="{f(top)}" width="34" height="{f(roof_y - top)}" fill="url(#house)" stroke="{WOOD_D}" stroke-width="1"/>'
           f'<rect x="{f(x - 2)}" y="{f(top - 3)}" width="38" height="4" fill="{WOOD_D}"/>'
           f'<rect x="{f(x + 20)}" y="{f(roof_y - 26)}" width="10" height="26" fill="{WOOD}"/>')
    return svg, top


def bricks(x, y, rows=2, cols=4):
    o = [tag('bricks')]
    for r in range(rows):
        for c in range(cols):
            o.append(f'<rect x="{f(x + c * 11 + (r % 2) * 5)}" y="{f(y - (r + 1) * 6)}" width="10" height="5" fill="{BRICK}" stroke="{BRICK_D}" stroke-width="0.6"/>')
    return ''.join(o)


def scaffold(x, top, bottom, w=30):
    return (f'<path d="M{f(x)} {f(bottom)} V{f(top)} M{f(x + w)} {f(bottom)} V{f(top)} M{f(x)} {f(top + 8)} h{w} M{f(x)} {f((top + bottom) / 2)} h{w} '
            f'M{f(x)} {f(bottom)} L{f(x + w)} {f(top + 8)}" stroke="{BAMBOO_D}" stroke-width="2"/>')


def pole_rod(x0, y0, x1, y1, kind):
    """A long thing held: an iron rod (grey) or a bamboo (with nodes)."""
    color, w = (INK, 2.6) if kind == 'rod' else (BAMBOO, 3.4)
    _pt(x0, y0, w / 2)
    _pt(x1, y1, w / 2)
    o = [f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{color}" stroke-width="{w}" stroke-linecap="round"/>']
    if kind == 'bamboo':
        for t in (0.2, 0.4, 0.6, 0.8):
            px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            o.append(f'<circle cx="{f(px)}" cy="{f(py)}" r="1.6" fill="{BAMBOO_D}"/>')
    return ''.join(o)


def clothes_line(x0, x1, y):
    for x in (x0, (x0 + x1) / 2, x1):
        _pt(x, y, 0.4)
    o = [tag('clothes'), f'<path d="M{f(x0)} {f(y)} L{f(x1)} {f(y)}" stroke="{INK}" stroke-width="0.8"/>']
    for i, c in enumerate((CLOTH_1, CLOTH_2, CLOTH_1)):
        cx = x0 + 6 + i * (x1 - x0 - 16) / 2
        o.append(f'<rect x="{f(cx)}" y="{f(y)}" width="12" height="16" fill="{c}"/>')
        o.append(f'<path d="M{f(cx + 3)} {f(y + 19)} v3 M{f(cx + 9)} {f(y + 21)} v3" stroke="{CLOTH_2}" stroke-width="1.2" stroke-linecap="round"/>')
    return ''.join(o)


def spark(x, y):
    pts = []
    for i in range(10):
        r = 7 if i % 2 == 0 else 3
        a = i * math.pi / 5
        pts.append(f'{f(x + r * math.cos(a))} {f(y + r * math.sin(a))}')
    return tag('spark') + f'<path d="M{" L".join(pts)} Z" fill="{SPARK}" stroke="{SUN_D}" stroke-width="0.8"/>'


def palm_up(x, y):
    """A raised open palm (stop!) at (x, y)."""
    return (f'<rect x="{f(x - 3.5)}" y="{f(y - 6)}" width="7" height="9" rx="2.5" fill="{SKIN}"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} v-3 M{f(x)} {f(y - 6)} v-4 M{f(x + 2)} {f(y - 6)} v-3" stroke="{SKIN}" stroke-width="1.4" stroke-linecap="round"/>')


# --------------------------------------------------------------------------
# Round 1 — road: ground clearance across a road (lesson section 1).
# --------------------------------------------------------------------------

def road_card(kind):
    volts, metres, low_m, veh, hot = {
        'ok11': ('11kV', '6.5', 6.5, 'bus', False),
        'oklt': ('415V', '5.8', 5.8, 'truck', False),
        'ok33': ('33kV', '6.5', 6.5, 'truck', True),
        'low11': ('11kV', '5.8', 5.8, 'bus', False),
        'old33': ('33kV', '6.1', 6.1, 'truck', True),
        'sag': ('11kV', '5.6', 5.6, 'truck', True),
        'lowlt': ('415V', '5.0', 5.0, 'bus', False),
    }[kind]
    out = card_open('street')
    if hot:
        out.append(sun())
    out.append(road_marks())
    attach = GY - 8.2 * UP
    y_low = GY - low_m * UP
    ht = volts != '415V'
    for x in (16, 184):
        out.append(pole(x, attach - 18))
        out.append(arm(x, attach - 2, 12))
    # the conductors: three for HT, four for LT; the lowest one is measured
    n = 3 if ht else 4
    for i in range(n):
        dy = -i * (6 if ht else 4)
        out.append(span(16, 184, attach + dy, y_low + dy))
    for x in (16, 184):
        for i in range(2):
            out.append(insulator(x - 8 + i * 16, attach))
    out.append(plate(16 + 20, attach + 34, volts))
    if veh == 'bus':
        out.append(bus(22))
    else:
        out.append(truck(18))
    out.append(v_dim(110, GY, y_low, metres))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — roof: vertical clearance over a roof or a চিলেকোঠা (section 2).
# --------------------------------------------------------------------------

def roof_card(kind):
    volts, metres, gap_m, stair, masons = {
        'lt': ('415V', '2.5', 2.5, False, False),
        'ht': ('11kV', '3.7', 3.7, True, False),
        'htlow': ('11kV', '2.5', 2.5, False, False),
        'stair': ('415V', '1.0', 1.0, True, False),
        'newfloor': ('11kV', '1.4', 1.4, False, True),
    }[kind]
    out = card_open('town')
    roof_y = GY - 3.2 * UP
    out.append(house_block(8, 150, roof_y))
    top = roof_y
    if stair:
        svg, top = stair_room(92, roof_y)
        out.append(svg)
    if masons:
        # a new floor rising on the roof: fresh brick courses and a mason
        new_top = roof_y - 2.3 * UP
        out.append(f'<rect x="60" y="{f(new_top)}" width="80" height="{f(roof_y - new_top)}" fill="{BRICK}" stroke="{BRICK_D}" stroke-width="0.8"/>')
        for r in range(1, 7):
            out.append(f'<path d="M60 {f(new_top + r * 6)} h80" stroke="{BRICK_D}" stroke-width="0.6"/>')
        out.append(bricks(30, roof_y))
        # the mason stands on the old roof beside the new wall, a smaller
        # figure so his head keeps a clear air gap under the 11 kV span
        # (nobody touches the line on the board; MIN_GAP)
        out.append(person(48, ((40, roof_y - 22), (60, new_top + 4)), face=1, look=-10, gy=roof_y, s=0.7, kind='mason'))
        top = new_top
    y_wire = top - gap_m * UP
    attach = y_wire - 10
    out.append(pole(186, attach - 12))
    out.append(arm(186, attach - 2, 12))
    ht = volts != '415V'
    n = 3 if ht else 4
    for i in range(n):
        dy = -i * (6 if ht else 4)
        out.append(span(-20, 186, attach + dy, y_wire + dy))
    out.append(plate(162, attach + 30, volts))
    dx = 112 if stair else 118
    out.append(v_dim(dx, top, y_wire, metres, side=-1 if dx > 100 else 1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — side: horizontal clearance beside a house (section 2), end view.
# --------------------------------------------------------------------------

def side_card(kind):
    volts, metres, gap_m, grill, slab = {
        'lt': ('415V', '1.2', 1.2, True, False),
        'ht33': ('33kV', '2.0', 2.0, False, False),
        'close33': ('33kV', '1.2', 1.2, False, False),
        'grill': ('415V', '0.3', 0.3, True, False),
        'slab': ('33kV', '0.6', 0.6, False, True),
    }[kind]
    out = card_open('town')
    wall_x = 70
    out.append(tag('house') + f'<rect x="0" y="40" width="{wall_x}" height="{GY - 40}" fill="url(#house)"/>')
    out.append(f'<rect x="12" y="132" width="22" height="66" fill="{WOOD}"/>')
    # the balcony on the first floor, its edge 18 px out
    bal_y = 100
    edge = wall_x + 18
    out.append(f'<rect x="{wall_x}" y="{bal_y}" width="18" height="5" fill="{WOOD_D}"/>')
    out.append(f'<rect x="14" y="58" width="22" height="30" fill="{GLASS}" stroke="{WOOD_D}" stroke-width="1.4"/>')
    if grill:
        out.append(tag('grill') + ''.join(f'<path d="M{wall_x + 3 + i * 5} {bal_y} v-22" stroke="{INK}" stroke-width="1.2"/>' for i in range(4))
                   + f'<path d="M{wall_x} {bal_y - 22} h18" stroke="{INK}" stroke-width="1.6"/>')
    else:
        out.append(f'<path d="M{wall_x} {bal_y - 18} h18 v18" stroke="{WOOD_D}" stroke-width="2" fill="none"/>')
    if slab:
        # a new slab cast out from the balcony toward the line, shuttering under it
        out.append(f'<rect x="{edge}" y="{bal_y}" width="36" height="5" fill="{BRICK}" stroke="{BRICK_D}" stroke-width="0.6"/>')
        out.append(scaffold(edge + 2, bal_y + 5, GY, 30))
        out.append(bricks(edge + 6, GY))
        edge += 36
    wire_x = edge + gap_m * ACROSS
    # the pole on the far side, its arm reaching back toward the house
    px = 186
    arm_y = bal_y - 14
    out.append(pole(px, arm_y - 30))
    out.append(f'<rect x="{f(min(wire_x - 6, px - 20))}" y="{f(arm_y)}" width="{f(px - min(wire_x - 6, px - 20) + 8)}" height="3.4" fill="{INK}"/>')
    ht = volts != '415V'
    xs = [wire_x + i * (14 if ht else 9) for i in range(3 if ht else 4)]
    for x in xs:
        out.append(insulator(x, arm_y))
        out.append(f'<circle cx="{f(x)}" cy="{f(arm_y - 6)}" r="2.6" fill="{WIRE}"/>')
    out.append(plate(px - 14, arm_y + 64, volts))
    out.append(h_dim(edge, wire_x, arm_y - 6 + 30, metres))
    out.append(f'<path d="M{f(wire_x)} {f(arm_y - 3)} V{f(arm_y + 26)}" stroke="{ARROW}" stroke-width="0.8" stroke-dasharray="2 2"/>')
    out.append(f'<path d="M{f(edge)} {f(bal_y)} V{f(arm_y + 26)}" stroke="{ARROW}" stroke-width="0.8" stroke-dasharray="2 2"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — section: lines on one pole (section 3). No figures.
# --------------------------------------------------------------------------

def section_card(kind):
    out = card_open('town')
    if kind in ('twin', 'windtouch'):
        out.append(wind())
    xa, xb = 20, 180
    out.append(pole(xa, 30))
    out.append(pole(xb, 30))
    if kind == 'twin':
        for x in (xa, xb):
            out.append(arm(x, 44, 14))
            out.append(arm(x, 104, 14))
        for i in range(3):
            out.append(span(xa, xb, 42 - i * 0.01 + 0, 62 + i * 9, dx=10))
        for i in range(4):
            out.append(span(xa, xb, 102, 122 + i * 7, dx=10))
    elif kind == 'windtouch':
        for x in (xa, xb):
            out.append(arm(x, 44, 14))
        out.append(span(xa, xb, 42, 64, dx=-14))
        out.append(span(xa, xb, 48, 74, dx=18))
        out.append(span(xa, xb, 54, 70, dx=-6))
        out.append(spark(100, 68))
    elif kind == 'phases':
        for x in (xa, xb):
            out.append(arm(x, 44, 5))
        for i in range(3):
            out.append(span(xa, xb, 42, 70 + i * 1.6))
    elif kind in ('cable', 'tied'):
        for x in (xa, xb):
            out.append(arm(x, 44, 14))
        for i in range(4):
            out.append(span(xa, xb, 42, 60 + i * 6))
        out.append(tag('cable'))
        for x in (xa, xb):
            out.append(f'<rect x="{f(x - 6)}" y="128" width="12" height="16" rx="2" fill="{CABLE}"/>')
        if kind == 'cable':
            out.append(span(xa, xb, 132, 150, color=CABLE, w=2.4))
        else:
            # the cable pulled up and tied against the lowest LT wire
            out.append(f'<path d="M{xa} 132 Q60 120 92 80 L112 80 Q140 120 {xb} 132" stroke="{CABLE}" stroke-width="2.4" fill="none"/>')
            for x in (96, 104):
                out.append(f'<ellipse cx="{x}" cy="79" rx="2.4" ry="4" fill="none" stroke="{TRUCK}" stroke-width="1.2"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — duty: the lineman near a line (section 4, pro tip 2).
# --------------------------------------------------------------------------

def overhead(out, low=False):
    """A line across the top of the card; [low] = an old span sagging over
    the lane."""
    for x in (10, 190):
        out.append(pole(x, 26))
        out.append(arm(x, 38, 10))
    for i in range(3):
        out.append(span(10, 190, 36 - i * 0.01, (82 if low else 56) + i * 5))


def duty_card(kind):
    out = card_open('town')
    if kind == 'warnrod':
        overhead(out)
        out.append(house_block(150, 50, 128, floors_line=False))
        rod = pole_rod(124, 176, 148, 76, 'rod')
        out.append(person(134, ((128, 176), (140, 150)), face=-1, look=-8, kind='public', held=rod))
        out.append(person(60, ((52, 150), (84, 104)), face=1, look=0, kind='lineman'))
        out.append(palm_up(84, 104))
    elif kind == 'callbuild':
        overhead(out)
        out.append(house_block(110, 90, 120, floors_line=False))
        out.append(scaffold(118, 84, 120, 36))
        out.append(bricks(124, 120, 3, 4))
        out.append(bricks(160, 120, 2, 3))
        out.append(person(112, ((106, 150), (118, 150)), face=-1, look=-10, s=1.15, kind='public'))
        # acting on it: his free hand points up at the construction
        out.append(person(56, ((81, 121), (70, 140)), face=1, look=-14, kind='lineman', phone=True))
    elif kind == 'reportsag':
        overhead(out, low=True)
        out.append(house_block(140, 60, 128, floors_line=False))
        out.append(bricks(146, 128, 1, 3))
        out.append(person(126, ((120, 150), (132, 150)), face=1, look=0, s=1.15, kind='public'))
        # acting on it: his free hand points up at the sag
        out.append(person(70, ((94, 121), (84, 140)), face=1, look=-18, kind='lineman', phone=True))
    elif kind == 'ignorebamboo':
        overhead(out)
        bam = pole_rod(122, 178, 152, 74, 'bamboo')
        out.append(person(134, ((128, 176), (140, 150)), face=-1, look=-8, kind='public', held=bam))
        out.append(person(56, ((48, 150), (70, 140)), face=-1, look=6, kind='lineman', phone=True))
    elif kind == 'wetclothes':
        overhead(out)
        # the roof low enough that the woman's head and the clothes keep a
        # clear air gap under the line (MIN_GAP)
        roof_y = 126
        out.append(house_block(96, 104, roof_y, floors_line=False))
        out.append(bricks(170, roof_y, 1, 2))
        out.append(clothes_line(108, 172, roof_y - 34))
        out.append(f'<path d="M108 {roof_y} V{roof_y - 36} M172 {roof_y} V{roof_y - 36}" stroke="{WOOD_D}" stroke-width="1.6"/>')
        out.append(person(186, ((180, roof_y - 30), (176, roof_y - 36)), face=-1, look=-6, gy=roof_y, s=0.9, kind='woman'))
        out.append(person(46, ((38, 150), (56, 150)), face=-1, look=4, kind='lineman'))
    elif kind == 'roofbamboo':
        overhead(out)
        out.append(wind(30, 70))
        roof_y = 120
        out.append(house_block(96, 104, roof_y, floors_line=False))
        out.append(bricks(170, roof_y, 1, 2))
        # leaning toward the line, its tip about 1 m (18 px) below it
        out.append(tag('bamboo') + pole_rod(150, roof_y, 128, 84, 'bamboo'))
        out.append(person(46, ((38, 150), (56, 150)), face=-1, look=4, kind='lineman'))
    else:  # walkpast — a low sagging span; he walks on, on the phone
        overhead(out, low=True)
        out.append(house_block(140, 60, 128, floors_line=False))
        out.append(person(124, ((118, 150), (130, 150)), face=1, look=0, s=1.15, kind='public'))
        out.append(person(60, ((68, 150), (50, 140)), face=-1, look=6, kind='lineman', phone=True))
    return card_close(out)


CARDS = {}
for k in ('ok11', 'oklt', 'ok33', 'low11', 'old33', 'sag', 'lowlt'):
    CARDS[f'road_{k}'] = road_card(k)
for k in ('lt', 'ht', 'htlow', 'stair', 'newfloor'):
    CARDS[f'roof_{k}'] = roof_card(k)
for k in ('lt', 'ht33', 'close33', 'grill', 'slab'):
    CARDS[f'side_{k}'] = side_card(k)
for k in ('twin', 'cable', 'windtouch', 'tied', 'phases'):
    CARDS[f'section_{k}'] = section_card(k)
for k in ('warnrod', 'callbuild', 'reportsag', 'ignorebamboo', 'wetclothes', 'roofbamboo', 'walkpast'):
    CARDS[f'duty_{k}'] = duty_card(k)

# Safe cards and traps per round (mirrors learn_board_pack73.dart).
ROUNDS = {
    'road': (['road_ok11', 'road_oklt', 'road_ok33'], ['road_low11', 'road_old33', 'road_sag', 'road_lowlt']),
    'roof': (['roof_lt', 'roof_ht'], ['roof_htlow', 'roof_stair', 'roof_newfloor']),
    'side': (['side_lt', 'side_ht33'], ['side_close33', 'side_grill', 'side_slab']),
    'section': (['section_twin', 'section_cable'], ['section_windtouch', 'section_tied', 'section_phases']),
    'duty': (['duty_warnrod', 'duty_callbuild', 'duty_reportsag'],
             ['duty_ignorebamboo', 'duty_wetclothes', 'duty_roofbamboo', 'duty_walkpast']),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_GAP = re.compile(r'<!--gap:(-?[\d.]+)-->')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
                trap_props = [props[t] for t in hand]
                alone = props[s] - set().union(*trap_props)
                missing = set.intersection(*trap_props) - props[s]
                if alone:
                    problems.append(f'{rnd}: {s} with {hand} has props {sorted(alone)} alone')
                if missing:
                    problems.append(f'{rnd}: {s} with {hand} alone lacks props {sorted(missing)}')
    for k, v in CARDS.items():
        m = _GAP.search(v)
        if m and float(m.group(1)) < MIN_GAP:
            problems.append(f'{k}: something reaches within {m.group(1)} px of a conductor (min {MIN_GAP})')
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
