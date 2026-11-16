"""Picture cards for lesson 8.5 শেখা ("সেফটি কোড (Safety Code): সুরক্ষার স্থানীয় আইন").

python -I tool/m8_board85_art.py .

Writes assets/game/art/m8_board85/*.svg (29 cards, 200 x 220, drawn edge to
edge in the clean gradient style of tool/m6_board63_art.py). No words in the
art; a worker's labels (a permit book number, a slip number, a tester reading)
are drawn as stroke glyphs with English digits. Plain text only: no logos, no
copied forms (ruling M8-11).

What the cards show comes from lesson 8.5 (live text) and the Module 8 rulings
(docs/module_specs/module8_rulings.md) only:
  1. ptw: the permit before the pole. Safe: the written slip whose number
     matches the permit book beside it; the lineman reading the page, pen
     capped. Traps: a phone 'line OFF' with no paper; a signature with the eyes
     on the pole; a climb with no permit; a slip whose number differs (103 v 104);
  2. loto: the breaker at OFF. Safe: the padlock through the handle and the
     'কাজ চলছে' board (drawn as a red-striped board); the key in the lineman's
     own shirt pocket. Traps: no lock and no board; the key left in the lock;
     the key handed to another man at the panel; the board alone;
  3. road: an 11 kV span high over a road with a loaded truck far below (6.5 m,
     ruling A2 / X3). Traps: the span sagging to the truck top; a covered
     conductor sagging with people reaching from the truck (myth 2); a
     lineman walking past a sagging span with no logbook;
  4. earth: the temporary earth on both sides of the work pole (rod, green lead,
     brass chain over the three phases), or the tester proving 0 V first, then
     the rod, the chain still coiled on the shoulder (M8-17 / X1). Traps: one
     side only; a ball chain with no rod; a rusty iron chain with a broken link;
     a bare hand on a line that is not earthed;
  5. ppe: whole rubber gloves and whole boots; the own discharge rod and chain
     in hand. Traps: a torn glove fingertip; a boot with the toes showing; a
     grey-haired lineman's bare hand on a wire; a mate's word on a pole.

Fairness (the playbook, section 4): every card in a round shares one backdrop,
and each colour the safe card draws is drawn by enough traps. The script checks
every hand the dealer can make (one safe card + the traps of the hand, three
traps in a five- or six-card round): each safe card's backdrop is a trap's
backdrop in that hand, and each colour or gradient the safe card draws is drawn
by a trap in that hand. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board85_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board85')
W, H = 200, 220
GY = 220

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
GREY_HAIR = '#BDBDBD'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
INK = '#4A5560'
PAPER = '#F4F1E6'
PAPER_D = '#E4DDC8'
PEN = '#2F5BA8'
GREEN = '#3E9B4F'
RED = '#D8402F'
PADLOCK = '#E5B92E'
PADLOCK_D = '#A8841C'
BRASS = '#C9A43A'
RUST = '#8A4B2A'
COVERED = '#4B5A4A'
TRUCK = '#3F6E8C'
ROAD = '#5A6068'
SUN = '#FFE08A'
SKYWIN = '#9CC6E4'
LCD = '#A9C997'
DEVICE = '#2B3138'
STEEL_IRON = '#7D868E'
BOX_DARK = '#4A525A'

DEFS = """<defs>
  <linearGradient id="office" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.6" stop-color="#D9CDB6"/><stop offset="0.6" stop-color="#9A7650"/><stop offset="1" stop-color="#6E5236"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#6F7A84"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.7" stop-color="#E2E6DE"/><stop offset="1" stop-color="#B9B39E"/></linearGradient>
  <linearGradient id="van" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E6E7C"/><stop offset="0.55" stop-color="#7C8C98"/><stop offset="1" stop-color="#4E5C68"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def rect(x, y, w, h, fill, rx=0, stroke=None, sw=1.0):
    st = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    r = f' rx="{f(rx)}"' if rx else ''
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}"{r} fill="{fill}"{st}/>'


def circ(x, y, r, fill, stroke=None, sw=1.0):
    st = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{fill}"{st}/>'


def line(x1, y1, x2, y2, stroke, w=2.0):
    return (f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{stroke}" stroke-width="{f(w)}" '
            'stroke-linecap="round" fill="none"/>')


def path(d, stroke, w=2.0, fill='none'):
    return f'<path d="{d}" stroke="{stroke}" stroke-width="{f(w)}" stroke-linecap="round" stroke-linejoin="round" fill="{fill}"/>'


def pole(x, top, bottom, wdt=7.0):
    return rect(x - wdt / 2, top, wdt, bottom - top, 'url(#pole)')


def sun(x=170, y=28):
    return circ(x, y, 13, SUN)


def truck(x, y, s=1.0):
    o = [rect(x, y, 46 * s, 22 * s, TRUCK, rx=3 * s),
         rect(x + 46 * s, y + 6 * s, 14 * s, 16 * s, TRUCK, rx=3 * s),
         rect(x + 50 * s, y + 8 * s, 8 * s, 6 * s, SKYWIN)]
    for wx in (x + 9 * s, x + 40 * s):
        o.append(circ(wx, y + 23 * s, 4 * s, INK))
    return ''.join(o)


# ---------------------------------------------------------------- digits
_SEG = {'a': ((0, 0), (4, 0)), 'b': ((4, 0), (4, 4)), 'c': ((4, 4), (4, 8)), 'd': ((0, 8), (4, 8)),
        'e': ((0, 4), (0, 8)), 'f': ((0, 0), (0, 4)), 'g': ((0, 4), (4, 4))}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd', '6': 'afgedc',
        '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}


def digits(x, y, text, k=1.0, color=INK, w=1.5):
    """English digits as seven-segment strokes; (x, y) = top left."""
    o = []
    cx = x
    for ch in text:
        if ch in _DIG:
            for seg in _DIG[ch]:
                (a, b), (c, d) = _SEG[seg]
                o.append(f'<path d="M{f(cx + a * k)} {f(y + b * k)} L{f(cx + c * k)} {f(y + d * k)}" stroke="{color}" '
                         f'stroke-width="{f(w)}" stroke-linecap="round"/>')
            cx += 7 * k
        else:
            cx += 4 * k
    return ''.join(o)


# ---------------------------------------------------------------- people
def man(x, gy=GY, s=1.0, hands=None, gloves=True, boots=True, helmet=True, hair=HAIR, face=1,
        shirt=SHIRT, skin=SKIN, extra=''):
    """A lineman standing at x (feet on gy), scaled [s]. [hands]: two hand
    points in card coordinates (default: hanging at the sides)."""
    hand_c = GLOVE if gloves else skin
    o = []
    o.append(f'<path d="M{f(x - 4 * s)} {f(gy - 30 * s)} L{f(x - 6 * s)} {f(gy - 2 * s)} M{f(x + 4 * s)} {f(gy - 30 * s)} '
             f'L{f(x + 6 * s)} {f(gy - 2 * s)}" stroke="{PANTS}" stroke-width="{f(7 * s)}" stroke-linecap="round" fill="none"/>')
    if boots:
        o.append(rect(x - 11 * s, gy - 4 * s, 9 * s, 4 * s, BOOT, rx=1.5 * s))
        o.append(rect(x + 2 * s, gy - 4 * s, 9 * s, 4 * s, BOOT, rx=1.5 * s))
    o.append(rect(x - 9 * s, gy - 58 * s, 18 * s, 30 * s, 'url(#shirt)', rx=4 * s))
    if hands is None:
        hands = ((x - 13 * s, gy - 28 * s), (x + 13 * s, gy - 28 * s))
    for (hx, hy), sx in zip(hands, (x - 8 * s, x + 8 * s)):
        o.append(line(sx, gy - 52 * s, hx, hy, shirt, 6 * s))
        o.append(circ(hx, hy, 3.6 * s, hand_c))
    hx, hy = x + 2 * face * s, gy - 66 * s
    o.append(circ(hx, hy, 6.5 * s, skin))
    if hair != HAIR:
        o.append(f'<path d="M{f(hx - 6 * s)} {f(hy - 1 * s)} Q{f(hx)} {f(hy - 9 * s)} {f(hx + 6 * s)} {f(hy - 1 * s)} '
                 f'L{f(hx + 4 * s)} {f(hy - 4 * s)} Q{f(hx)} {f(hy - 7 * s)} {f(hx - 4 * s)} {f(hy - 4 * s)} Z" fill="{hair}"/>')
    if helmet:
        o.append(f'<path d="M{f(hx - 7 * s)} {f(hy - 1 * s)} A{f(7 * s)} {f(7 * s)} 0 0 1 {f(hx + 7 * s)} {f(hy - 1 * s)} Z" fill="{HELMET}"/>')
        o.append(rect(hx - 8 * s, hy - 2.4 * s, 16 * s, 2.6 * s, HELMET_D, rx=1.2 * s))
    o.append(extra)
    return ''.join(o)


def phone(x, y):
    return rect(x, y, 11, 19, DEVICE, rx=2) + rect(x + 2, y + 3, 7, 10, LCD, rx=1)


def tester(x, y, reading='0'):
    return rect(x, y, 15, 11, DEVICE, rx=2) + rect(x + 2, y + 2, 11, 7, LCD, rx=1) + digits(x + 4.5, y + 1.2, reading, 0.5, INK, 0.9)


def padlock(x, y):
    return (path(f'M{f(x + 3)} {f(y)} L{f(x + 3)} {f(y - 4)} Q{f(x + 5)} {f(y - 8)} {f(x + 7)} {f(y - 4)} L{f(x + 7)} {f(y)}',
                 PADLOCK_D, 2.0) + rect(x, y, 10, 8, PADLOCK, rx=1.5))


def chain(points, color=BRASS, r=1.7):
    return ''.join(circ(px, py, r, color, stroke=PADLOCK_D, sw=0.4) for px, py in points)


def arc_points(x1, y1, x2, y2, bow, n=9):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = x1 + (x2 - x1) * t
        y = y1 + (y2 - y1) * t - bow * math.sin(math.pi * t)
        pts.append((x, y))
    return pts


def sag(x1, y1, x2, y2, bow):
    """A wire's quadratic sag: its middle drops [bow] below the end line."""
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2 + 2 * bow
    return f'M{f(x1)} {f(y1)} Q{f(cx)} {f(cy)} {f(x2)} {f(y2)}'


def card(back, parts):
    head = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']
    tail = ['</g>',
            '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>',
            '</svg>']
    return '\n'.join(head + parts + tail)


# ================================================================ ptw
def _ptw_base(page='104'):
    o = [rect(128, 14, 52, 46, SKYWIN, rx=3, stroke=INK, sw=1.2), pole(154, 14, 60, 4)]
    o.append(f'<path d="M30 150 L100 142 L100 196 L30 204 Z" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>')
    o.append(f'<path d="M170 150 L100 142 L100 196 L170 204 Z" fill="{PAPER_D}" stroke="{INK}" stroke-width="1"/>')
    for i in range(4):
        y = 166 + i * 7
        o.append(line(108, y - 3, 162, y + 1, INK, 0.9))
    o.append(digits(40, 158, page, 1.2))
    o.append(line(150, 190, 184, 172, PEN, 4.2))
    o.append(circ(150, 190, 2.4, PEN))
    return o


def _slip(num):
    return [rect(112, 112, 66, 36, PAPER, rx=2, stroke=INK, sw=1.2), digits(124, 120, num, 1.2),
            line(124, 138, 166, 138, INK, 0.9), line(124, 142, 150, 142, INK, 0.9)]


def ptw_slip():
    return _ptw_base() + _slip('104') + [circ(118, 152, 4.5, SKIN)]


def ptw_read():
    return _ptw_base() + [man(44, s=1.25, hands=((84, 160), (96, 170)), extra=line(92, 170, 102, 176, PEN, 3))]


def ptw_phone():
    return _ptw_base() + [man(52, s=1.25, hands=((74, 96), (40, 190)), extra=phone(68, 70))]


def ptw_sign():
    return _ptw_base() + [man(126, s=1.25, hands=((104, 152), (98, 178)), extra=line(104, 152, 112, 160, PEN, 2.2))]


def ptw_none():
    return [pole(100, 0, H, 8)] + _ptw_base() + [man(100, s=1.25, hands=((95, 118), (106, 138)))]


def ptw_mismatch():
    return _ptw_base() + _slip('103') + [circ(118, 152, 4.5, SKIN)]


# ================================================================ loto
def _loto_base(man_left=True):
    o = [rect(46, 34, 108, 160, 'url(#box)', rx=6, stroke=INK, sw=1.2),
         rect(58, 48, 84, 132, '#8A949C', rx=4),
         rect(72, 66, 56, 92, BOX_DARK, rx=4),
         rect(84, 82, 32, 12, GREEN, rx=2),
         rect(84, 120, 32, 14, '#D0D6DB', rx=3, stroke=INK, sw=0.8)]
    if man_left:
        o.append(man(18, s=1.1, hands=((34, 160), (36, 176))))
    return o


def _padlock_on_handle():
    return [padlock(96, 130)]


def _board():
    return [line(126, 102, 126, 96, INK, 1.0), rect(120, 96, 56, 34, PAPER, rx=2, stroke=INK, sw=1.0),
            rect(120, 96, 56, 8, RED, rx=2)]


def loto_lock():
    return _loto_base() + _padlock_on_handle() + _board()


def loto_pocket():
    return _loto_base() + _padlock_on_handle() + _board() + [
        circ(150, 150, 1.5, BRASS),
        man(170, s=1.2, hands=((158, 150), (176, 186)), extra=rect(160, 158, 6, 4, 'url(#shirt)', rx=1)),
        line(152, 150, 158, 156, BRASS, 2.0),
    ]


def loto_nolock():
    return _loto_base()


def loto_keyin():
    return _loto_base() + _padlock_on_handle() + _board() + [
        line(101, 140, 101, 156, BRASS, 1.6), circ(101, 158, 3, BRASS, stroke=PADLOCK_D, sw=0.6)]


def loto_handkey():
    return _loto_base() + _padlock_on_handle() + _board() + [
        line(52, 152, 104, 152, BRASS, 1.6), circ(104, 152, 3, BRASS, stroke=PADLOCK_D, sw=0.6),
        man(170, s=1.2, hands=((118, 152), (176, 186))),
    ]


def loto_boardonly():
    return _loto_base() + _board()


# ================================================================ road
def _road_base(wire_bow=40, near_truck=None, far_truck=True, extra_truck=''):
    o = [sun(170, 26), rect(0, 176, W, 44, ROAD), rect(0, 180, W, 3, PAPER, rx=1),
         pole(18, 34, 200), pole(182, 34, 200),
         rect(4, 100, 28, 22, PAPER, rx=2, stroke=INK, sw=1.0), rect(8, 108, 20, 4, INK),
         line(16, 68, 26, 68, INK, 1.0)]
    o.append(path(sag(18, 58, 182, 58, wire_bow), WIRE, 2.0))
    if far_truck:
        o.append(truck(40, 188, 0.7))
    if near_truck:
        o.append(near_truck)
    o.append(man(150, s=0.95, hands=((140, 160), (160, 160))))
    o.append(extra_truck)
    return o


def road_high():
    return _road_base(40)


def road_patrol():
    return _road_base(40, extra_truck=rect(133, 146, 16, 20, PAPER, rx=1.5, stroke=INK, sw=0.8) +
                      line(136, 152, 146, 152, INK, 0.8) + line(136, 158, 146, 158, INK, 0.8))


def road_low():
    return _road_base(160, near_truck=truck(78, 126, 1.0) + man(70, s=0.85, hands=((64, 150), (74, 150))))


def road_covered():
    base = _road_base(160, near_truck=truck(78, 126, 1.0) +
                      man(66, s=0.85, hands=((62, 118), (70, 110))) + man(122, s=0.85, hands=((120, 118), (116, 110))))
    base.append(path(sag(18, 58, 182, 58, 160), COVERED, 3.6))
    return base


def road_walk():
    return _road_base(160, near_truck=None)


# ================================================================ earth
def _earth_base():
    o = [rect(0, 170, W, 50, 'url(#ground)'),
         pole(40, 20, 200), pole(160, 20, 200), pole(100, 20, 200, 6)]
    for y in (60, 72, 84):
        o.append(line(0, y, 200, y, WIRE, 1.6))
        for x in (40, 100, 160):
            o.append(circ(x, y, 1.8, WIRE))
    o.append(rect(34, 186, 8, 8, GREEN, rx=2))
    o.append(rect(158, 186, 8, 8, GREEN, rx=2))
    o.append(rect(120, 198, 52, 4.5, 'url(#steel)', rx=2))
    return o


def _rod(x, top=110):
    return [rect(x - 2, top, 4, 80, 'url(#steel)', rx=1.5)]


def earth_both():
    o = _earth_base()
    for x in (62, 138):
        o += _rod(x)
        o.append(line(x, 110, x, 72, GREEN, 2.2))
        o.append(chain([(x + 4, py) for py in (60, 66, 72, 78, 84)]))
    o.append(tester(84, 190))  # M8-17: the tester proves 0 V before any earth
    return o


def earth_tester():
    o = _earth_base()
    o.append(man(100, s=1.15, hands=((122, 70), (84, 136)), gloves=True))
    o.append(tester(118, 74))
    o += [rect(88, 128, 4, 52, 'url(#steel)', rx=1.5)]
    o.append(circ(92, 118, 5.5, BRASS, stroke=PADLOCK_D, sw=0.8))
    return o


def earth_oneside():
    o = _earth_base()
    o += _rod(62)
    o.append(line(62, 110, 62, 72, GREEN, 2.2))
    o.append(chain([(66, py) for py in (60, 66, 72, 78, 84)]))
    o.append(man(124, s=1.1, hands=((104, 146), (134, 146))))
    o.append(tester(132, 186))
    return o


def earth_ball():
    o = _earth_base()
    o.append(chain(arc_points(120, 70, 62, 80, 34), BRASS, 1.8))
    o.append(man(124, s=1.1, hands=((118, 68), (134, 146))))
    return o


def earth_jugaad():
    o = _earth_base()
    o.append(line(138, 60, 138, 78, RUST, 4.0))
    links = [(138, 80 + i * 6) for i in range(5)]
    for i, (x, y) in enumerate(links):
        col = RUST if i % 2 == 0 else STEEL_IRON
        o.append(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="2.6" ry="3.6" fill="none" stroke="{col}" stroke-width="1.6"/>')
    o.append(f'<ellipse cx="138" cy="112" rx="2.6" ry="3.6" fill="none" stroke="{RUST}" stroke-width="1.6" stroke-dasharray="2 2"/>')
    o.append(man(60, s=1.1, hands=((70, 146), (52, 146))))
    return o


def earth_bare():
    o = _earth_base()
    o.append(man(100, s=1.15, hands=((100, 74), (84, 146)), gloves=False))
    o.append(chain(arc_points(54, 196, 92, 198, 4, 9), BRASS, 1.6))
    o.append(tester(126, 186))
    return o


# ================================================================ ppe
def _van_base():
    o = [rect(0, 150, W, 70, 'url(#van)'), rect(0, 150, W, 7, INK)]
    for x in (150, 160, 170, 180):
        o.append(rect(x - 2, 42, 4, 106, 'url(#steel)', rx=1.5))
    o.append(circ(178, 124, 5, BRASS, stroke=PADLOCK_D, sw=0.8))
    o.append(circ(178, 136, 5, BRASS, stroke=PADLOCK_D, sw=0.8))
    return o


def ppe_full():
    return _van_base() + [man(88, s=1.25, hands=((66, 150), (110, 150)))]


def ppe_rod():
    return _van_base() + [man(88, s=1.25, hands=((126, 128), (70, 148)),
                              extra=rect(124, 96, 4, 60, 'url(#steel)', rx=1.5) + circ(72, 150, 4.5, BRASS, stroke=PADLOCK_D, sw=0.7))]


def ppe_torn():
    return _van_base() + [man(88, s=1.25, hands=((66, 150), (110, 150)),
                              extra=line(106, 150, 111, 156, SKIN, 3.0) + circ(111, 156, 1.6, SKIN))]


def ppe_sole():
    return _van_base() + [man(88, s=1.25, hands=((66, 150), (110, 150)),
                              extra=circ(90, 218, 3.2, SKIN) + circ(98, 218, 2.4, SKIN))]


def ppe_veteran():
    return _van_base() + [pole(40, 0, 200, 3), man(96, s=1.25, hands=((52, 118), (76, 150)), gloves=False,
                                                  helmet=False, hair=GREY_HAIR)]


def ppe_mate():
    return _van_base() + [man(80, s=1.25, hands=((66, 150), (98, 150))),
                          man(156, s=1.2, hands=((140, 136), (172, 150)), shirt='#2F7A4F')]


# ================================================================ rounds
ROUNDS = {
    'ptw': ('office', [('ptw_slip', ptw_slip, True), ('ptw_read', ptw_read, True),
                       ('ptw_phone', ptw_phone, False), ('ptw_sign', ptw_sign, False),
                       ('ptw_none', ptw_none, False), ('ptw_mismatch', ptw_mismatch, False)]),
    'loto': ('panel', [('loto_lock', loto_lock, True), ('loto_pocket', loto_pocket, True),
                       ('loto_nolock', loto_nolock, False), ('loto_keyin', loto_keyin, False),
                       ('loto_handkey', loto_handkey, False), ('loto_boardonly', loto_boardonly, False)]),
    'road': ('day', [('road_high', road_high, True), ('road_patrol', road_patrol, True),
                     ('road_low', road_low, False), ('road_covered', road_covered, False),
                     ('road_walk', road_walk, False)]),
    'earth': ('yard', [('earth_both', earth_both, True), ('earth_tester', earth_tester, True),
                       ('earth_oneside', earth_oneside, False), ('earth_ball', earth_ball, False),
                       ('earth_jugaad', earth_jugaad, False), ('earth_bare', earth_bare, False)]),
    'ppe': ('van', [('ppe_full', ppe_full, True), ('ppe_rod', ppe_rod, True),
                    ('ppe_torn', ppe_torn, False), ('ppe_sole', ppe_sole, False),
                    ('ppe_veteran', ppe_veteran, False), ('ppe_mate', ppe_mate, False)]),
}

CARDS = {}
SAFE = {}
TRAPS = {}
for _rnd, (_back, _opts) in ROUNDS.items():
    for _name, _fn, _safe in _opts:
        CARDS[_name] = card(_back, _fn())
        (SAFE if _safe else TRAPS).setdefault(_rnd, []).append(_name)

# A dealt hand: one safe card with (cards - 1) traps; the lesson deal is 4 cards.
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rnd in ROUNDS:
        for s in SAFE[rnd]:
            for hand in itertools.combinations(TRAPS[rnd], HAND - 1):
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
