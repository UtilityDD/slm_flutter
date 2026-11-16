"""Picture cards for lesson 6.7 শেখা ("ক্যাপাসিটর ব্যাংক: পাওয়ার বুস্টার").

python -I tool/m6_board67_art.py .

Writes assets/game/art/m6_board67/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the labels a worker reads (a meter's A / kW / V / PF / kVA, the
PF scale's 0.8 and 1.0, a stopwatch's minutes) are drawn as stroke glyphs
with English digits.

What the cards show comes from lesson 6.7 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only:
  1. pf: the bank switched in on a low-PF line (the switch's red ON window,
     its lever just moved). Every card has the same pole, line and tail-end
     house, and a panel of two meters with a ghost needle (before) and a red
     needle (now), and a trend arrow. Safe: A down with kW the same; V up at
     the tail end; the DTR's kVA bar down. Traps: kW up, A up with the
     conductor hot, the PF needle below 0.8. Meter figures are illustrative
     (spec unsupported[0]); only 0.8 and 1.0 are the lesson's;
  2. build: the pole bank — three cans on a rack, the bank's own switch and
     three fuses; the cans in star (one bar on their second bushings) or in
     delta (can to can); a ground APFC cabinet whose steps are lit by load.
     Traps: cans tapped straight off the line (no switch, no fuse), a worker
     switching the bank by hand with a clock and a log of many ON / OFF
     marks, a household switch plate in place of the bank's switch;
  3. wait: the bank's switch OFF (green window); the danger plate (bolt and
     clock) on the pole; a stopwatch shows the minutes since the switch-off.
     Safe: standing back with the watch running; after the wait, the
     discharge rod with its earth lead clamped on the earth spike, the hook
     on a terminal, a small spark. Traps: a bare hand on a terminal at 0
     minutes (spark); the rod at 0 minutes with the lever still moving; 10
     minutes and a gloved hand on the terminal, the rod lying on the ground;
     a spanner straight on a terminal at 0 minutes (spark);
  4. earthed: the line earthed (an earth set on the line, its lead down the
     pole) and the bank's fuses dropped open, so the bank is cut off from the
     earthed line; a small power capacitor in a box low on the pole. Safe: a
     separate rod on the bank's own terminal; the rod on the small capacitor
     before the hand. Traps: a hand on a can with the rod lying unused, bare
     hands unscrewing the small capacitor, the rod's hook on the line's drop
     (above the open fuse) and the other hand on a can;
  5. patrol: a worker on line patrol. Safe: straight dry cans, walking on;
     a bulged can, the bank's switch OFF and the worker phoning; a blown bank
     fuse, the switch OFF, the worker looking at the cans with his tester, a
     new fuse still in the bag. Traps: a bulged can leaking oil with the
     switch ON and the worker walking away; a fuse pushed back in straight
     away with a hot stick; all outside fuses in place and the docket
     ticked.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too. It
deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board67_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board67')
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
INK = '#4A5560'
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
COPPER = '#B8733A'
TIN = '#D9DDE0'        # tinned copper fuse wire
GI = '#8C949A'         # galvanised iron binding wire
ALU = '#B9C0C6'        # ACSR aluminium strand
PVC = '#C8352B'        # a wire's red insulation
RED = '#D8402F'        # HRC dot, ON window, tag, puller grip
DOT_OFF = '#1C1F24'    # a blown HRC dot (black)
GREEN = '#3E9B4F'      # OFF window; the earth lead's green
EARTH_Y = '#E8C830'
BRASS = '#C9A43A'
METER_Y = '#F2B630'
METER_D = '#B9851A'
LCD_ON = '#1D2B22'
GOGGLE = '#8FD0EE'
SUN = '#FFE08A'
WIN_LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
SMOKE = '#7A848C'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.62" stop-color="#E2E6DE"/><stop offset="1" stop-color="#B9B39E"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E6E7C"/><stop offset="0.42" stop-color="#7C8C98"/><stop offset="0.42" stop-color="#9A7650"/><stop offset="1" stop-color="#7A5A3A"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3ABB2"/><stop offset="1" stop-color="#6C747B"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#7D8891"/></linearGradient>
  <linearGradient id="ceramic" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9D3C6"/><stop offset="0.45" stop-color="#FAF8F2"/><stop offset="1" stop-color="#C8C1B2"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
  <linearGradient id="can" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.4" stop-color="#D3D9DD"/><stop offset="1" stop-color="#7A838A"/></linearGradient>
  <linearGradient id="rod" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F0B840"/><stop offset="1" stop-color="#C77F1E"/></linearGradient>
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
# People (the worker from tool/m5_board55_art.py via m6_board63_art.py; gloves or bare hands,
# goggles on or off).
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


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True, goggles=False, props_front=''):
    """The lineman: blue shirt, helmet; rubber gloves or bare hands; safety
    goggles or none."""
    hand_c = GLOVE if gloves else SKIN
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
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
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
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if goggles:
        hd.append(f'<rect x="{f(hx + (0 if face > 0 else -8))}" y="{f(hy - 1.6)}" width="8" height="4.4" rx="1.8" fill="{GOGGLE}" stroke="{WIRE}" stroke-width="0.8"/>')
        hd.append(f'<path d="M{f(hx - 6 * face)} {f(hy)} L{f(hx)} {f(hy + 0.4)}" stroke="{WIRE}" stroke-width="1.2"/>')
    hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>')
    hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, goggles=False, s=S):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, gloves, goggles)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def arms(hands, gloves=True, side=1):
    """Just the forearms of a worker reaching in from the bottom edge (a
    close-up): blue sleeves, gloved or bare hands."""
    hand_c = GLOVE if gloves else SKIN
    o = []
    for i, (hx, hy) in enumerate(hands):
        bx = hx + (30 + 18 * i) * side
        o.append(f'<path d="M{f(bx)} {H + 4} Q{f((bx + hx) / 2 + 6 * side)} {f((H + hy) / 2 + 10)} {f(hx)} {f(hy)}" '
                 f'stroke="{SHIRT if i else SHIRT_D}" stroke-width="11" stroke-linecap="round" fill="none"/>')
        o.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="6.5" fill="{hand_c}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Glyphs: English digits as seven-segment strokes, plus k, V, A, m and '.'.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'k': 'M0 0 L0 10 M5 4.5 L0.6 8 M2.4 6.6 L5.6 10',
    'V': 'M0 0 L3 10 L6 0',
    'A': 'M0 10 L3 0 L6 10 M1.2 6.6 L4.8 6.6',
    'W': 'M0 0 L1.5 10 L3 3.5 L4.5 10 L6 0',
    'P': 'M0 10 L0 0 L4 0 Q6 0 6 2.5 Q6 5 4 5 L0 5',
    'F': 'M6 0 L0 0 L0 10 M0 5 L4.5 5',
    'm': 'M0 10 L0 4.6 M0 6 Q0 4.6 1.5 4.6 Q3 4.6 3 6 L3 10 M3 6 Q3 4.6 4.5 4.6 Q6 4.6 6 6 L6 10',
}


def _shift(d, ox, oy, k):
    nums = re.split(r'([MLQ])', d)
    out = []
    for part in nums:
        if part in ('M', 'L', 'Q') or not part.strip():
            out.append(part)
            continue
        vals = [float(v) for v in part.split()]
        pts = [f'{f(ox + vals[i] * k)} {f(oy + vals[i + 1] * k)}' for i in range(0, len(vals), 2)]
        out.append(' '.join(pts) + ' ')
    return ''.join(out).strip()


def glyphs(x, y, text, h=10.0, color=INK, w=None):
    """[text] drawn with strokes; (x, y) = top left; h = cap height."""
    k = h / 10
    d = []
    dots = []
    ox = x
    for ch in text:
        if ch == ' ':
            ox += 4.5 * k
        elif ch == '.':
            dots.append(f'<circle cx="{f(ox + 0.6 * k)}" cy="{f(y + 10 * k)}" r="{f(1.1 * k)}" fill="{color}"/>')
            ox += 3.6 * k
        elif ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox   # a '1' sits narrow, not right-aligned
            for s in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[s]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
        else:
            d.append(_shift(_LET[ch], ox, y, k))
            ox += 7.8 * k
    sw = w if w is not None else 1.5 * k
    return (f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(sw)}" stroke-linecap="round" '
            f'stroke-linejoin="round" fill="none"/>' + ''.join(dots))


def glyph_width(text, h=10.0):
    k = h / 10
    wd = 0.0
    for ch in text:
        wd += 4.5 * k if ch == ' ' else 3.6 * k if ch == '.' else 5.4 * k if ch == '1' else 7.8 * k
    return wd - 1.8 * k


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def tester(x, y, reading, s=1.0):
    """The yellow voltage tester / multimeter (top-left x, y) with its reading."""
    w, h = 28 * s, 42 * s
    tw = glyph_width(reading, 10 * s)
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>'
            f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 3.5 * s)}" width="{f(w - 5 * s)}" height="{f(15 * s)}" rx="1.5" fill="url(#lcd)"/>'
            + glyphs(x + (w - tw) / 2, y + 6 * s, reading, 10 * s, LCD_ON)
            + f'<circle cx="{f(x + w / 2)}" cy="{f(y + 27 * s)}" r="{f(6 * s)}" fill="{WIRE}"/>')


def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def sun(x=168, y=30):
    return (f'<circle cx="{x}" cy="{y}" r="20" fill="url(#glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="8" fill="{SUN}"/>')


def cloud(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.75"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(16 * s)}" ry="{f(6 * s)}"/>'
            f'<ellipse cx="{f(x + 8 * s)}" cy="{f(y - 4 * s)}" rx="{f(9 * s)}" ry="{f(6 * s)}"/></g>')


def motion(x, y, dx=0, dy=-1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def earth_lead(d, w=2.6):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{GREEN}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """A portable earth set lying coiled on the ground, unused."""
    o = []
    for rx, ry in ((14, 5), (11, 4), (8, 3)):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0'))
    for dx in (-20, 18, 24):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="7" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def padlock(x, y):
    """A padlock (steel shackle, yellow body) and the red shutdown tag."""
    return (f'<path d="M{f(x - 3)} {f(y)} v-4 a3 3 0 0 1 6 0 v4" stroke="url(#steel)" stroke-width="1.8" fill="none"/>'
            f'<rect x="{f(x - 5)}" y="{f(y)}" width="10" height="8" rx="1.5" fill="{HELMET_D}"/>'
            f'<path d="M{f(x + 4)} {f(y + 6)} L{f(x + 8)} {f(y + 12)}" stroke="{PAPER}" stroke-width="0.9"/>'
            f'<rect x="{f(x + 5)}" y="{f(y + 12)}" width="9" height="13" rx="1.5" fill="{RED}"/>'
            f'<circle cx="{f(x + 9.5)}" cy="{f(y + 15)}" r="1.2" fill="{PAPER}"/>')




def spark(x, y, r=14):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)"/>'
            f'<path d="M{f(x - r * 0.7)} {f(y)} L{f(x + r * 0.7)} {f(y)} M{f(x)} {f(y - r * 0.7)} L{f(x)} {f(y + r * 0.7)} '
            f'M{f(x - r * 0.5)} {f(y - r * 0.5)} L{f(x + r * 0.5)} {f(y + r * 0.5)} M{f(x + r * 0.5)} {f(y - r * 0.5)} L{f(x - r * 0.5)} {f(y + r * 0.5)}" '
            f'stroke="{SUN}" stroke-width="1.6" stroke-linecap="round"/>')


def smoke(x, y):
    return (f'<g fill="{SMOKE}" opacity="0.8"><circle cx="{f(x)}" cy="{f(y)}" r="5"/><circle cx="{f(x + 4)}" cy="{f(y - 8)}" r="6"/>'
            f'<circle cx="{f(x - 2)}" cy="{f(y - 17)}" r="7"/></g>')


def clipboard(x, y, s=1.0, tick=True):
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(34 * s)}" rx="2" fill="{BAG}"/>',
         f'<rect x="{f(x + 3 * s)}" y="{f(y + 5 * s)}" width="{f(20 * s)}" height="{f(26 * s)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + 9 * s)}" y="{f(y + 2 * s)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="url(#steel)"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 6 * s)} {f(y + (12 + i * 6) * s)} h{f(10 * s)}" stroke="{INK}" stroke-width="0.8"/>')
    if tick:
        o.append(f'<path d="M{f(x + 13 * s)} {f(y + 23 * s)} l{f(3 * s)} {f(4 * s)} l{f(6 * s)} {f(-9 * s)}" stroke="{GREEN}" stroke-width="{f(2 * s)}" fill="none" stroke-linecap="round"/>')
    return ''.join(o)



CAN_OIL = '#8A6A1E'    # oil leaking from a burst can
HEAT = '#FF8A3D'       # heat shimmer over an overloaded conductor
LAMP_OFF = '#46525C'   # an APFC step lamp that is dark


# --------------------------------------------------------------------------
# Things on the capacitor pole.
# --------------------------------------------------------------------------

PX = 28                      # the pole
LINE_Y = 15                  # the three line conductors
INS_X = (92, 132, 172)       # pin insulators on the cross-arm
SW = (50, 36)                # the bank switch box (top-left)
SW_T = (58, 68, 78)          # its terminals
FUSE_X = (96, 124, 152)      # the bank's fuses
FUSE_TOP, FUSE_BOT = 62, 84
CAN_X = (100, 128, 156)      # can centres
CAN_TOP, CAN_BOT = 104, 142
BUSH_Y = 95                  # bushing terminal caps


def plain_sky(out, ground=True):
    out.append(sun(172, 30))
    out.append(cloud(150, 54, 0.9))
    if ground:
        out.append(f'<rect x="0" y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')


def line_top(out):
    out.append(pole(PX, 6))
    out.append(f'<rect x="14" y="22" width="176" height="5" rx="1.5" fill="url(#chan)"/>')
    for x in INS_X:
        out.append(f'<rect x="{x - 3}" y="{LINE_Y + 1}" width="6" height="7" rx="1.5" fill="url(#porc)"/>')
    out.append(f'<path d="M0 {LINE_Y} L{W} {LINE_Y}" stroke="{WIRE}" stroke-width="1.4"/>')
    out.append(f'<path d="M0 {LINE_Y - 4} L{W} {LINE_Y - 4}" stroke="{WIRE}" stroke-width="1.4"/>')
    out.append(f'<path d="M0 {LINE_Y - 8} L{W} {LINE_Y - 8}" stroke="{WIRE}" stroke-width="1.4"/>')


def danger_plate(x, y):
    """The bank's danger plate (no words): a yellow plate with a black bolt
    and a small clock face (wait before touching)."""
    return (f'<rect x="{f(x - 10)}" y="{f(y)}" width="20" height="26" rx="2" fill="{HELMET}" stroke="{INK}" stroke-width="0.8"/>'
            f'<path d="M{f(x + 1)} {f(y + 3)} L{f(x - 4)} {f(y + 11)} L{f(x)} {f(y + 11)} L{f(x - 2)} {f(y + 16)} L{f(x + 4)} {f(y + 8)} L{f(x)} {f(y + 8)} Z" fill="{INK}"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 21)}" r="3.4" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>'
            f'<path d="M{f(x)} {f(y + 21)} v-2.4 M{f(x)} {f(y + 21)} h1.8" stroke="{INK}" stroke-width="0.7"/>')


def switch_box(on=True, moving=False):
    """The bank's own switch: a grey box with its window (red ON, green OFF)
    and its lever; the operating rod runs down the pole to a handle."""
    x, y = SW
    o = [f'<rect x="{x}" y="{y}" width="36" height="16" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{x + 22}" y="{y + 5}" width="9" height="6" rx="1" fill="{RED if on else GREEN}"/>']
    end = (x - 9, y - 6) if on else (x - 9, y + 22)
    o.append(f'<path d="M{x} {y + 8} L{end[0]} {end[1]}" stroke="url(#steel)" stroke-width="3" stroke-linecap="round"/>')
    o.append(f'<path d="M{end[0]} {end[1]} L{PX + 9} 168" stroke="{INK}" stroke-width="1.6"/>')
    o.append(f'<rect x="{PX + 4}" y="166" width="12" height="5" rx="2" fill="{WIRE}"/>')
    if moving:
        o.append(motion(x - 14, y + 8, -1, 0, 3, 7))
    return ''.join(o)


def domestic_switch():
    """A household switch plate fixed where the bank's switch belongs."""
    x, y = SW
    return (f'<rect x="{x + 4}" y="{y - 2}" width="22" height="22" rx="3" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/>'
            f'<rect x="{x + 11}" y="{y + 3}" width="8" height="12" rx="1.5" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{x + 11} {y + 9} h8" stroke="{INK}" stroke-width="0.6"/>')


def fuse(x, intact=True, moving=False):
    """One bank fuse: a porcelain base on a bracket and the fuse tube; blown,
    the tube has dropped open and hangs from its lower hinge."""
    o = [f'<rect x="{x - 2}" y="{FUSE_TOP - 4}" width="4" height="{FUSE_BOT - FUSE_TOP + 8}" rx="1.5" fill="url(#porc)" opacity="0.55"/>',
         f'<circle cx="{x}" cy="{FUSE_TOP - 2}" r="2" fill="url(#steel)"/>',
         f'<circle cx="{x}" cy="{FUSE_BOT + 2}" r="2" fill="url(#steel)"/>']
    if intact:
        o.append(f'<path d="M{x} {FUSE_TOP} L{x} {FUSE_BOT}" stroke="{WIRE}" stroke-width="4" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{x} {FUSE_BOT} L{x + 15} {FUSE_BOT + 13}" stroke="{WIRE}" stroke-width="4" stroke-linecap="round"/>')
    if moving:
        o.append(motion(x + 6, FUSE_TOP + 8, 0, -1, 3, 7))
    return ''.join(o)


def can(cx, bulged=False, leak=False):
    """One capacitor unit: a grey steel can with two porcelain bushings."""
    w2 = 10
    o = []
    if bulged:
        o.append(f'<path d="M{cx - w2} {CAN_BOT} Q{cx - w2 - 7} {f((CAN_TOP + CAN_BOT) / 2)} {cx - w2} {CAN_TOP + 2} '
                 f'Q{cx} {CAN_TOP - 6} {cx + w2} {CAN_TOP + 2} Q{cx + w2 + 7} {f((CAN_TOP + CAN_BOT) / 2)} {cx + w2} {CAN_BOT} Z" fill="url(#can)" stroke="{INK}" stroke-width="0.6"/>')
    else:
        o.append(f'<rect x="{cx - w2}" y="{CAN_TOP}" width="{2 * w2}" height="{CAN_BOT - CAN_TOP}" rx="1.5" fill="url(#can)" stroke="{INK}" stroke-width="0.6"/>')
        o.append(f'<path d="M{cx - w2 + 3} {CAN_TOP + 6} v{CAN_BOT - CAN_TOP - 12}" stroke="#FFFFFF" stroke-opacity="0.4" stroke-width="1.5"/>')
    top = CAN_TOP - (4 if bulged else 0)
    for dx in (-5, 5):
        o.append(f'<rect x="{cx + dx - 2}" y="{BUSH_Y + 1}" width="4" height="{top - BUSH_Y - 1}" fill="url(#porc)"/>')
        o.append(f'<circle cx="{cx + dx}" cy="{BUSH_Y}" r="1.8" fill="url(#steel)"/>')
    if leak:
        o.append(f'<path d="M{cx + 6} {CAN_BOT - 4} Q{cx + 9} {CAN_BOT + 6} {cx + 8} {CAN_BOT + 14}" stroke="{CAN_OIL}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
        o.append(f'<ellipse cx="{cx + 8}" cy="{GY - 1}" rx="12" ry="2.5" fill="{CAN_OIL}" opacity="0.85"/>')
        o.append(f'<circle cx="{cx + 8}" cy="{CAN_BOT + 30}" r="1.6" fill="{CAN_OIL}"/>')
    return ''.join(o)


def bank_rig(out, on=True, fuses=(True, True, True), conn='star', bulge=None, leak=False, direct=False,
             switch='box', moving=False, fuse_moving=None, plate=True):
    """The pole capacitor bank: line → its own switch → its three fuses →
    three cans on a rack (star or delta); [direct] = cans tapped straight off
    the line (no switch, no fuses)."""
    line_top(out)
    # rack and bracket
    out.append(f'<rect x="{PX + 4}" y="{CAN_BOT + 1}" width="{CAN_X[2] + 16 - PX - 4}" height="5" rx="1.5" fill="url(#chan)"/>')
    if direct:
        for xi, cx in zip(INS_X, CAN_X):
            out.append(f'<path d="M{xi} {LINE_Y} Q{xi - 4} {LINE_Y + 40} {cx - 5} {BUSH_Y}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    else:
        for xi, t in zip(INS_X, SW_T):
            out.append(f'<path d="M{xi} {LINE_Y} Q{(xi + t) / 2} {LINE_Y + 8} {t} {SW[1]}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
        for t, fx in zip(SW_T, FUSE_X):
            out.append(f'<path d="M{t} {SW[1] + 16} Q{t} {FUSE_TOP - 6} {fx} {FUSE_TOP - 2}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
        for fx, cx in zip(FUSE_X, CAN_X):
            out.append(f'<path d="M{fx} {FUSE_BOT + 2} Q{fx} {BUSH_Y - 4} {cx - 5} {BUSH_Y}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
        out.append(f'<rect x="{PX + 4}" y="{SW[1] + 18}" width="{FUSE_X[2] - PX + 4}" height="3" rx="1" fill="url(#chan)"/>')
        if switch == 'box':
            out.append(switch_box(on, moving))
        else:
            out.append(domestic_switch())
        for i, (fx, ok) in enumerate(zip(FUSE_X, fuses)):
            out.append(fuse(fx, ok, fuse_moving == i))
    for i, cx in enumerate(CAN_X):
        out.append(can(cx, bulge == i, leak and bulge == i))
    if conn == 'star':
        out.append(f'<path d="M{CAN_X[0] + 5} {BUSH_Y} L{CAN_X[0] + 5} {BUSH_Y - 5} L{CAN_X[2] + 5} {BUSH_Y - 5} L{CAN_X[2] + 5} {BUSH_Y} '
                   f'M{CAN_X[1] + 5} {BUSH_Y - 5} L{CAN_X[1] + 5} {BUSH_Y}" stroke="url(#steel)" stroke-width="2.2" fill="none"/>')
    elif conn == 'delta':
        for a, b in ((0, 1), (1, 2)):
            out.append(f'<path d="M{CAN_X[a] + 5} {BUSH_Y} Q{(CAN_X[a] + CAN_X[b]) / 2 + 4} {BUSH_Y - 10} {CAN_X[b] - 5} {BUSH_Y}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
        out.append(f'<path d="M{CAN_X[2] + 5} {BUSH_Y} Q{CAN_X[2] + 14} {BUSH_Y + 50} {CAN_X[1]} {CAN_BOT + 14} '
                   f'Q{CAN_X[0] - 20} {CAN_BOT + 14} {CAN_X[0] - 5} {BUSH_Y}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    if plate:
        out.append(danger_plate(PX, 112))


def stopwatch(cx, cy, minutes, r=15):
    """A stopwatch: its hand and its window show the minutes since the bank's
    switch went OFF (10 marks round the dial = 10 minutes)."""
    a = math.radians(minutes / 10 * 360 - 90)
    o = [f'<rect x="{f(cx - 3)}" y="{f(cy - r - 6)}" width="6" height="5" rx="1" fill="url(#steel)"/>',
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{r}" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>',
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{r - 3}" fill="{PAPER}"/>']
    for i in range(10):
        b = math.radians(i * 36 - 90)
        o.append(f'<path d="M{f(cx + math.cos(b) * (r - 6))} {f(cy + math.sin(b) * (r - 6))} L{f(cx + math.cos(b) * (r - 3.5))} {f(cy + math.sin(b) * (r - 3.5))}" stroke="{INK}" stroke-width="0.9"/>')
    txt = str(minutes)
    low = 2.5 < minutes % 10 < 7.5            # the hand in the lower half: the minutes above the pivot
    o.append(glyphs(cx - glyph_width(txt, 6) / 2, cy - 9 if low else cy + 2, txt, 6, INK))
    o.append(f'<path d="M{f(cx)} {f(cy)} L{f(cx + math.cos(a) * (r - 5))} {f(cy + math.sin(a) * (r - 5))}" stroke="{RED}" stroke-width="1.6" stroke-linecap="round"/>')
    o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="1.6" fill="{WIRE}"/>')
    return ''.join(o)


def earth_spike(x):
    return (f'<path d="M{x} {GY - 6} L{x} {GY + 10}" stroke="url(#steel)" stroke-width="3"/>'
            f'<rect x="{x - 3}" y="{GY - 8}" width="6" height="4" rx="1" fill="{BRASS}"/>')


def disch_rod(hand, hook, spike=PX + 22, lead=True):
    """The discharge rod: a yellow insulated stick from the worker's hands to
    a steel hook; its earth lead runs from the hook to the earth spike, its
    clamp already on (the earth side first)."""
    hx, hy = hand
    kx, ky = hook
    o = [f'<path d="M{f(hx)} {f(hy)} L{f(kx)} {f(ky + 6)}" stroke="url(#rod)" stroke-width="3.4" stroke-linecap="round"/>',
         f'<path d="M{f(kx)} {f(ky + 6)} L{f(kx)} {f(ky + 1)} Q{f(kx)} {f(ky - 4)} {f(kx + 4)} {f(ky - 3)}" stroke="url(#steel)" stroke-width="2" fill="none" stroke-linecap="round"/>']
    if lead:
        o.append(earth_lead(f'M{f(kx)} {f(ky + 8)} Q{f((kx + spike) / 2)} {f(GY - 30)} {f(spike)} {f(GY - 6)}', 1.8))
        o.append(earth_spike(spike))
    return ''.join(o)


def rod_on_ground(x, y=GY - 3):
    """The discharge rod lying on the ground, its lead coiled beside it."""
    return (f'<path d="M{x} {y} L{x + 56} {y - 4}" stroke="url(#rod)" stroke-width="3.4" stroke-linecap="round"/>'
            f'<path d="M{x + 56} {y - 4} q4 -1 4 -5 q0 -3 -3 -3" stroke="url(#steel)" stroke-width="2" fill="none"/>'
            + earth_coil(x + 24, y - 10))


def spanner(x, y, ang=-40):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x)}" y="{f(y - 2)}" width="24" height="4" rx="2" fill="url(#steel)"/>'
            f'<path d="M{f(x - 3)} {f(y - 5)} a5 5 0 1 0 0.1 0 Z" fill="url(#steel)"/></g>')


def phone(x, y):
    return f'<rect x="{f(x - 2.5)}" y="{f(y - 5)}" width="5" height="9" rx="1.2" fill="{WIRE}"/>'


def bag(x, y, fuse_in=True, tester_in=False):
    """The tool bag on the ground; a spare fuse tube (and the tester) in it."""
    o = []
    if fuse_in:
        o.append(f'<path d="M{x + 4} {y - 4} L{x + 14} {y - 20}" stroke="{WIRE}" stroke-width="4" stroke-linecap="round"/>')
    if tester_in:
        o.append(tester(x + 12, y - 26, '0', 0.5))
    o.append(f'<path d="M{x - 14} {y} L{x - 11} {y - 12} L{x + 19} {y - 12} L{x + 22} {y} Z" fill="{BAG}"/>')
    o.append(f'<path d="M{x - 6} {y - 12} q10 -9 20 0" stroke="{BAG}" stroke-width="2" fill="none"/>')
    return ''.join(o)


def small_cap(x, y, open_box=True):
    """A small power capacitor: a little cylinder with two terminals, in a
    box fixed low on the pole."""
    o = [f'<rect x="{x - 15}" y="{y - 16}" width="30" height="34" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{x - 12}" y="{y - 13}" width="24" height="28" rx="1.5" fill="url(#panel)"/>',
         f'<rect x="{x - 6}" y="{y - 4}" width="12" height="17" rx="5" fill="url(#can)" stroke="{INK}" stroke-width="0.5"/>']
    for dx in (-3, 3):
        o.append(f'<rect x="{x + dx - 1}" y="{y - 8}" width="2" height="4" fill="{BRASS}"/>')
    o.append(f'<path d="M{x - 3} {y - 8} Q{x - 8} {y - 14} {x - 12} {y - 12} M{x + 3} {y - 8} Q{x + 8} {y - 14} {x + 12} {y - 12}" stroke="{WIRE}" stroke-width="0.9" fill="none"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Meters (round 1).
# --------------------------------------------------------------------------

def dial(cx, cy, label, ghost, val, r=26, marks=()):
    """A panel meter: scale from -60° to +60°; [ghost] = where the needle
    stood before the bank came in (dashed), [val] = now (red); 0..1."""
    def pt(v, rr):
        a = math.radians(-150 + v * 120)
        return cx + math.cos(a) * rr, cy + math.sin(a) * rr
    o = [f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{PAPER}" stroke="{INK}" stroke-width="1.2"/>']
    for i in range(7):
        x0, y0 = pt(i / 6, r - 8)
        x1, y1 = pt(i / 6, r - 3)
        o.append(f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{INK}" stroke-width="1"/>')
    for v, txt in marks:
        mx, my = pt(v, r - 13)
        o.append(glyphs(mx - glyph_width(txt, 5) / 2, my - 2.5, txt, 5, INK, 0.9))
    lw = glyph_width(label, 8)
    o.append(glyphs(cx - lw / 2, cy + 7, label, 8, INK))
    if ghost is not None:
        gx, gy = pt(ghost, r - 5)
        o.append(f'<path d="M{cx} {cy} L{f(gx)} {f(gy)}" stroke="{INK}" stroke-width="1.2" stroke-dasharray="2 2"/>')
    nx, ny = pt(val, r - 5)
    o.append(f'<path d="M{cx} {cy} L{f(nx)} {f(ny)}" stroke="{RED}" stroke-width="1.8" stroke-linecap="round"/>')
    o.append(f'<circle cx="{cx}" cy="{cy}" r="2.6" fill="{WIRE}"/>')
    return ''.join(o)


def bar_meter(cx, cy, label, ghost, val):
    """A load bar (the DTR's kVA): the frame, the bar now and a dashed mark
    where it stood before."""
    x, top, h, w = cx - 9, cy - 24, 34, 18
    lvl = top + h * (1 - val)
    o = [f'<rect x="{x}" y="{top}" width="{w}" height="{h}" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="1.2"/>',
         f'<rect x="{x + 3}" y="{f(lvl)}" width="{w - 6}" height="{f(top + h - lvl - 2)}" fill="{RED}"/>']
    if ghost is not None:
        gy = top + h * (1 - ghost)
        o.append(f'<path d="M{x - 3} {f(gy)} L{x + w + 3} {f(gy)}" stroke="{INK}" stroke-width="1.2" stroke-dasharray="2 2"/>')
    lw = glyph_width(label, 7)
    o.append(glyphs(cx - lw / 2, top + h + 4, label, 7, INK))
    return ''.join(o)


def trend(x, y, kind):
    if kind == 'up':
        d = f'M{x} {y + 8} L{x} {y - 8} M{x - 5} {y - 3} L{x} {y - 8} L{x + 5} {y - 3}'
    elif kind == 'down':
        d = f'M{x} {y - 8} L{x} {y + 8} M{x - 5} {y + 3} L{x} {y + 8} L{x + 5} {y + 3}'
    else:
        d = f'M{x - 6} {y - 3} L{x + 6} {y - 3} M{x - 6} {y + 3} L{x + 6} {y + 3}'
    return f'<path d="{d}" stroke="{WIRE}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'


def pf_stage(hot=False):
    """The same pole and line on every card of round 1: the bank on the pole
    just switched in (red window, lever moving), the line to the tail-end
    house, and the meter panel below."""
    out = card_open('yard')
    out.append(sun(172, 24))
    out.append(f'<rect x="0" y="104" width="{W}" height="16" fill="url(#ground)"/>')
    out.append(pole(30, 6, 110))
    out.append(f'<rect x="16" y="20" width="40" height="4" rx="1.5" fill="url(#chan)"/>')
    for yy in (8, 12, 16):
        out.append(f'<path d="M0 {yy} L{W} {yy + 30}" stroke="{WIRE}" stroke-width="1.2"/>')
    # tail-end house
    out.append('<path d="M146 74 L170 58 L194 74 Z" fill="url(#roof)"/>')
    out.append('<rect x="150" y="74" width="40" height="32" fill="url(#house)"/>')
    out.append(f'<rect x="158" y="82" width="9" height="9" fill="{WIN_LIT}"/><rect x="174" y="84" width="9" height="20" fill="{BAG}"/>')
    out.append(f'<path d="M190 46 Q186 56 186 76" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    # small bank on the pole
    out.append(f'<rect x="34" y="86" width="56" height="4" rx="1.5" fill="url(#chan)"/>')
    for cx in (48, 64, 80):
        out.append(f'<rect x="{cx - 6}" y="62" width="12" height="24" rx="1.2" fill="url(#can)" stroke="{INK}" stroke-width="0.5"/>')
        out.append(f'<rect x="{cx - 1.5}" y="55" width="3" height="7" fill="url(#porc)"/>')
        out.append(f'<path d="M{cx} 55 Q{cx + 8} 36 {cx + 16} 18" stroke="{WIRE}" stroke-width="0.9" fill="none"/>')
    out.append(f'<rect x="36" y="32" width="24" height="12" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.5"/>')
    out.append(f'<rect x="48" y="35" width="8" height="6" rx="1" fill="{RED}"/>')
    out.append(motion(42, 46, 0, 1, 3, 6))
    if hot:
        for x0 in (96, 124, 152):
            out.append(f'<path d="M{x0} 30 q3 -4 0 -8 q-3 -4 0 -8" stroke="{HEAT}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    out.append(f'<rect x="12" y="122" width="176" height="84" rx="9" fill="url(#panel)"/>')
    return out


def pf_card(kind):
    out = pf_stage(hot=kind == 'hot')
    L, R = (62, 166), (142, 166)
    if kind == 'amps':
        out += [dial(*L, 'A', 0.8, 0.45), trend(L[0] + 31, 140, 'down'), dial(*R, 'kW', 0.55, 0.55), trend(R[0] + 31, 140, 'eq')]
    elif kind == 'volt':
        out += [dial(*L, 'V', 0.25, 0.6), trend(L[0] + 31, 140, 'up'), dial(*R, 'kW', 0.55, 0.55), trend(R[0] + 31, 140, 'eq')]
    elif kind == 'load':
        out += [bar_meter(L[0], L[1], 'kVA', 0.85, 0.5), trend(L[0] + 31, 140, 'down'), dial(*R, 'kW', 0.55, 0.55), trend(R[0] + 31, 140, 'eq')]
    elif kind == 'kw':
        out += [dial(*L, 'A', 0.6, 0.6), trend(L[0] + 31, 140, 'eq'), dial(*R, 'kW', 0.4, 0.85), trend(R[0] + 31, 140, 'up')]
    elif kind == 'hot':
        out += [dial(*L, 'A', 0.5, 0.88), trend(L[0] + 31, 140, 'up'), dial(*R, 'kW', 0.55, 0.55), trend(R[0] + 31, 140, 'eq')]
    elif kind == 'pfdown':
        marks = ((0.35, '0.8'), (0.95, '1.0'))
        out += [dial(*L, 'PF', 0.45, 0.12, marks=marks), trend(L[0] + 31, 140, 'down'), dial(*R, 'kW', 0.55, 0.55), trend(R[0] + 31, 140, 'eq')]
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2: build.
# --------------------------------------------------------------------------

def apfc_cabinet(out):
    """A substation APFC panel, door open: a controller and four steps, each
    a contactor, its fuses, a row of cans and a lamp (two steps lit by the
    load, two dark)."""
    out.append(f'<rect x="40" y="40" width="124" height="{GY - 40}" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<rect x="46" y="46" width="112" height="{GY - 52}" rx="2" fill="url(#panel)"/>')
    out.append(f'<path d="M164 42 L186 50 L186 {GY - 4} L164 {GY}" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<rect x="56" y="52" width="40" height="24" rx="2" fill="{WIRE}"/>')
    out.append(f'<rect x="60" y="56" width="32" height="12" rx="1.5" fill="url(#lcd)"/>')
    for i in range(4):
        out.append(f'<rect x="{63 + i * 7}" y="{65 - (i + 1) * 2}" width="4" height="{(i + 1) * 2}" fill="{LCD_ON}"/>')
    for row in range(4):
        y = 86 + row * 27
        lit = row < 2
        out.append(f'<circle cx="{58}" cy="{y + 8}" r="4" fill="{SUN if lit else LAMP_OFF}" stroke="{INK}" stroke-width="0.5"/>')
        out.append(f'<rect x="68" y="{y}" width="16" height="18" rx="1.5" fill="{WIRE}"/>')
        for k in range(3):
            out.append(f'<rect x="{90 + k * 6}" y="{y + 2}" width="4" height="14" rx="1" fill="url(#ceramic)"/>')
        for k in range(3):
            out.append(f'<rect x="{114 + k * 13}" y="{y - 1}" width="10" height="20" rx="1.2" fill="url(#can)" stroke="{INK}" stroke-width="0.4"/>')


def build_card(kind):
    out = card_open('day')
    plain_sky(out)
    if kind == 'star':
        bank_rig(out, conn='star')
    elif kind == 'delta':
        bank_rig(out, conn='delta')
    elif kind == 'apfc':
        apfc_cabinet(out)
        out.append(person(24, ((40, 150), (44, 158)), face=1, look=0, gy=GY, s=1.1))
    elif kind == 'direct':
        bank_rig(out, conn='star', direct=True)
    elif kind == 'hourly':
        # The bank switched by hand again and again: the worker at the
        # handle (lever moving), a clock and a log of many ON / OFF marks.
        bank_rig(out, on=False, conn='star', moving=True)
        out.append(person(58, ((PX + 10, 166), (PX + 12, 172)), face=-1, look=-10))
        out.append(f'<circle cx="168" cy="172" r="14" fill="{PAPER}" stroke="{INK}" stroke-width="1.2"/>'
                   f'<path d="M168 172 L168 162 M168 172 L175 175" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
        out.append(f'<rect x="96" y="154" width="44" height="40" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>')
        for i in range(5):
            for j in range(4):
                out.append(f'<rect x="{100 + j * 10}" y="{158 + i * 7}" width="6" height="4" rx="1" fill="{RED if (i + j) % 2 == 0 else GREEN}"/>')
        out.append(motion(110, 150, 0, -1, 3, 5))
        out.append(apfc_tokens())
    elif kind == 'domestic':
        bank_rig(out, conn='star', switch='domestic')
        out.append(apfc_tokens())
    return card_close(out)


def apfc_tokens():
    """The step lamps and the controller's screen colours, also on two traps
    (a lamp on the pole's street light box), so the APFC card is not the only
    one that draws them."""
    return (f'<rect x="170" y="150" width="22" height="30" rx="2" fill="{WIRE}"/>'
            f'<rect x="172" y="165" width="18" height="12" rx="1" fill="url(#panel)"/>'
            f'<rect x="173" y="153" width="16" height="9" rx="1.5" fill="url(#lcd)"/>'
            f'<rect x="176" y="156" width="3" height="4" fill="{LCD_ON}"/>'
            f'<circle cx="177" cy="170" r="3" fill="{SUN}"/><circle cx="186" cy="170" r="3" fill="{LAMP_OFF}"/>')


# --------------------------------------------------------------------------
# Round 3: the wait.
# --------------------------------------------------------------------------

def wait_card(kind):
    out = card_open('day')
    plain_sky(out)
    moving = kind in ('bare', 'early')
    bank_rig(out, on=False, conn='star', moving=moving)
    term = (CAN_X[0] - 5, BUSH_Y)
    if kind not in ('rod', 'early'):
        out.append(earth_spike(PX + 22))   # the pole's earth spike, the rod not on it yet
    if kind == 'watch':
        # Standing well back from the rack (the cans end at x 166).
        out.append(stopwatch(180, 74, 5, 13))
        out.append(person(183, ((177, 136), (181, 132)), face=-1, look=-30))
        out.append(motion(180, 54, 0, -1, 3, 5))
        out.append(rod_on_ground(60))
    elif kind == 'rod':
        out.append(stopwatch(180, 74, 10))
        out.append(person(150, ((132, 140), (138, 134)), face=-1, look=-22))
        out.append(disch_rod((134, 138), term))
        out.append(spark(term[0], term[1], 8))
    elif kind == 'bare':
        out.append(stopwatch(180, 74, 0))
        out.append(person(116, (term, (110, 140)), face=-1, look=-24, gloves=False))
        out.append(spark(term[0], term[1], 10))
        out.append(rod_on_ground(130))
    elif kind == 'early':
        out.append(stopwatch(180, 74, 0))
        out.append(person(150, ((132, 140), (138, 134)), face=-1, look=-22))
        out.append(disch_rod((134, 138), term))
        out.append(spark(term[0], term[1], 8))
    elif kind == 'norod':
        out.append(stopwatch(180, 74, 10))
        out.append(person(116, (term, (110, 140)), face=-1, look=-24))
        out.append(rod_on_ground(130))
    elif kind == 'load':
        out.append(stopwatch(180, 74, 0))
        out.append(person(116, ((term[0] + 4, term[1] + 6), (110, 140)), face=-1, look=-24))
        out.append(spanner(term[0] + 2, term[1] + 4, 40))
        out.append(spark(term[0], term[1], 8))
        out.append(motion(180, 54, 0, -1, 3, 5))
        out.append(rod_on_ground(130))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4: the line is OFF and earthed.
# --------------------------------------------------------------------------

def line_earth(out):
    """The line's earth set: a clamp on each conductor, joined, its lead
    down the pole to the earth spike at its foot."""
    for i, yy in enumerate((LINE_Y - 8, LINE_Y - 4, LINE_Y)):
        out.append(f'<rect x="{8 + i * 4}" y="{yy - 2}" width="5" height="5" rx="1" fill="url(#steel)"/>')
    out.append(earth_lead(f'M10 {LINE_Y - 6} L18 {LINE_Y + 2} L{PX - 6} 40 L{PX - 6} {GY - 6}', 1.8))
    out.append(earth_spike(PX - 6))


def earthed_card(kind):
    out = card_open('day')
    plain_sky(out)
    bank_rig(out, on=False, fuses=(False, False, False), conn='star')
    line_earth(out)
    out.append(small_cap(PX + 26, 176))
    term = (CAN_X[1] - 5, BUSH_Y)
    sc = (PX + 23, 168)
    if kind == 'own':
        out.append(person(160, ((142, 140), (148, 134)), face=-1, look=-22))
        out.append(disch_rod((144, 138), term, spike=170))
        out.append(spark(term[0], term[1], 7))
    elif kind == 'small':
        out.append(person(110, ((88, 166), (94, 160)), face=-1, look=-6))
        out.append(disch_rod((90, 164), sc, spike=78))
    elif kind == 'trust':
        out.append(person(140, ((CAN_X[1] + 6, 126), (CAN_X[1] + 8, 132)), face=-1, look=-12))
        out.append(rod_on_ground(140))
    elif kind == 'smallbare':
        out.append(person(90, ((sc[0] + 4, sc[1] + 6), (sc[0] + 8, sc[1] + 12)), face=-1, look=-4, gloves=False))
        out.append(motion(sc[0] - 6, sc[1] - 2, -1, 0, 3, 5))
        out.append(rod_on_ground(130))
    elif kind == 'lineonly':
        # The hook on the line conductor only (above the bank's open fuses);
        # the other hand on a can.
        out.append(person(140, ((126, 140), (CAN_X[1] + 6, 128)), face=-1, look=-30))
        out.append(disch_rod((128, 138), (112, LINE_Y + 3), spike=170))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5: on patrol.
# --------------------------------------------------------------------------

ICE = '#6EC3F0'          # frost on a cold (dead) can


def warm(cx):
    """A working can's heat: a short shimmer rising from its side."""
    x0 = cx + 13
    return (f'<path d="M{x0} {CAN_TOP + 26} q3 -4 0 -8 q-3 -4 0 -8" stroke="{HEAT}" stroke-width="1.4" '
            f'fill="none" stroke-linecap="round" opacity="0.9"/>')


def frost(cx, cy, r=6):
    """A cold can: a pale-blue snowflake on its face."""
    o = []
    for i in range(3):
        a = math.radians(i * 60)
        dx, dy = math.cos(a) * r, math.sin(a) * r
        o.append(f'M{f(cx - dx)} {f(cy - dy)} L{f(cx + dx)} {f(cy + dy)}')
    return (f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r + 2)}" fill="{ICE}" opacity="0.25"/>'
            f'<path d="{" ".join(o)}" stroke="{ICE}" stroke-width="1.6" stroke-linecap="round"/>')


def patrol_card(kind):
    out = card_open('day')
    plain_sky(out)
    if kind == 'sound':
        # A bank at work: every can warm.
        bank_rig(out, on=True)
        for cx in CAN_X:
            out.append(warm(cx))
        out.append(person(180, ((172, 168), (188, 170)), face=1, look=-14))
        out.append(motion(164, 160, -1, 0, 3, 8))
    elif kind == 'bulge':
        bank_rig(out, on=False, bulge=1)
        out.append(person(160, ((154, 132), (166, 168)), face=-1, look=-14))
        out.append(phone(153, 128))
    elif kind == 'cause':
        # The cause looked for from the ground, eyes on the blown fuse and the
        # cans, notes on the clipboard; no tool goes near a can (ruling M6-6:
        # nothing touches a can before the rod). Tester and new fuse stay in
        # the bag.
        bank_rig(out, on=False, fuses=(True, False, True))
        out.append(person(183, ((172, 150), (178, 152)), face=-1, look=-34))
        out.append(clipboard(166, 144, 0.7, tick=False))
        out.append(bag(76, GY, tester_in=True))
    elif kind == 'leak':
        bank_rig(out, on=True, bulge=1, leak=True)
        out.append(person(176, ((168, 168), (184, 170)), face=1, look=0))
        out.append(motion(160, 160, -1, 0, 3, 8))
    elif kind == 'refuse':
        # A new fuse tube pushed straight back with a hot stick, the cause not
        # looked for; the tester stays in the bag.
        bank_rig(out, on=False, fuses=(True, True, True), fuse_moving=1)
        out.append(person(166, ((150, 150), (156, 142)), face=-1, look=-30))
        out.append(f'<path d="M152 148 L{FUSE_X[1] + 2} {FUSE_BOT + 2}" stroke="url(#rod)" stroke-width="3.4" stroke-linecap="round"/>')
        out.append(bag(172, GY, fuse_in=False, tester_in=True))
    elif kind == 'outer':
        # Pro tip 1's cue: two cans warm at work, the third one cold (no
        # shimmer, frost) — yet the outer fuses look fine and he ticks it off.
        bank_rig(out, on=True)
        out.append(warm(CAN_X[0]))
        out.append(warm(CAN_X[1]))
        out.append(frost(CAN_X[2], (CAN_TOP + CAN_BOT) / 2))
        out.append(person(183, ((172, 152), (176, 146)), face=-1, look=-10))
        out.append(clipboard(158, 144, 0.8))
    return card_close(out)


CARDS = {}
for k in ('amps', 'volt', 'load', 'kw', 'hot', 'pfdown'):
    CARDS[f'pf_{k}'] = pf_card(k)
for k in ('star', 'delta', 'apfc', 'direct', 'hourly', 'domestic'):
    CARDS[f'build_{k}'] = build_card(k)
for k in ('watch', 'rod', 'bare', 'early', 'norod', 'load'):
    CARDS[f'wait_{k}'] = wait_card(k)
for k in ('own', 'small', 'trust', 'smallbare', 'lineonly'):
    CARDS[f'earthed_{k}'] = earthed_card(k)
for k in ('sound', 'bulge', 'cause', 'leak', 'refuse', 'outer'):
    CARDS[f'patrol_{k}'] = patrol_card(k)

# Safe cards and traps per round (mirrors learn_board_pack67.dart).
ROUNDS = {
    'pf': (['pf_amps', 'pf_volt', 'pf_load'], ['pf_kw', 'pf_hot', 'pf_pfdown']),
    'build': (['build_star', 'build_delta', 'build_apfc'], ['build_direct', 'build_hourly', 'build_domestic']),
    'wait': (['wait_watch', 'wait_rod'], ['wait_bare', 'wait_early', 'wait_norod', 'wait_load']),
    'earthed': (['earthed_own', 'earthed_small'], ['earthed_trust', 'earthed_smallbare', 'earthed_lineonly']),
    'patrol': (['patrol_sound', 'patrol_bulge', 'patrol_cause'], ['patrol_leak', 'patrol_refuse', 'patrol_outer']),
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
