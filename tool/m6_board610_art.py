"""Picture cards for lesson 6.10 শেখা ("এনার্জি মিটার: ক্যাশ রেজিস্টার").

python -I tool/m6_board610_art.py .

Writes assets/game/art/m6_board610/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only marks a worker reads (a meter's LCD, a tester's reading)
are stroke glyphs with English digits. LCD numbers are game data.

What the cards show comes from lesson 6.10 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md, X5) only. Five rounds (owner
answers after Wave A: boards are 5 rounds): the item spec's LED round and its
fast-meter round are one round here (the CAL LED is read in the fast-meter
check).
  1. modern: the electronic meter (LCD, chip board, no moving part), its
     push-button stepping the LCD through the readings, the smart meter
     sending its reading to the office. Traps: a disc meter ticked as modern,
     only the kWh read on a fault call, a disc meter put back;
  2. fast: "the meter runs fast" — every load off, then the CAL LED; LED
     still, a 100 W bulb run for an hour; the customer shown his old fridge
     and pump. Traps: all off yet the LED races, ticked "all fine"; a verdict
     with the fan and bulb still on; the weather blamed (myth 2);
  3. blank: the blank LCD — the tester on the incoming terminals first; no
     voltage there — follow the service cable to the pole; meter alive but
     the house dark — the neutral. Traps: a new meter fitted untested;
     voltage present yet off to the pole; meter alive, house dark, ticked
     "meter bad";
  4. theft: a broken seal, a bypass wire (seen from a distance), a magnet on
     the meter — each reported by phone. Traps: walking off from the broken
     seal, the bypass pulled bare-handed while phoning it in, the magnet
     pocketed;
  5. swap: the incoming cut-out out with gloves and the tester at 0 before
     hands go in (ruling X5); photos of the old meter's final reading and the
     new meter's first one. Traps: a screwdriver on the terminals with the
     cut-out in (the line live), the old meter bagged with no photo, the
     cut-out out but no tester (N4).

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too;
and every prop or figure (tagged <!--prop:name-->: worker, phone, clipboard,
tester, camera...) on the safe card is on a trap in that hand, and none sits
on every trap of the hand but not on the safe card. It
deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board610_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board610')
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
PVC = '#C8352B'        # the bypass wire's red insulation
RED = '#D8402F'        # CAL LED lit, magnet, a cross on the docket
LED_OFF = '#6A3A34'    # CAL LED dark
GREEN = '#3E9B4F'      # a tick on the docket
BRASS = '#C9A43A'      # terminals, chip legs
PCB = '#2F7A4A'        # the electronic meter's chip board
SEAL = '#6E747A'       # the lead seal
METER_Y = '#F2B630'
METER_D = '#B9851A'
LCD_ON = '#1D2B22'
LCD_OFF = '#34413A'    # a blank LCD
SUN = '#FFE08A'
WIN_OFF = '#2E3A46'
MOVE = '#FFFFFF'
RAIN = '#5C7C96'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8DCC4"/><stop offset="1" stop-color="#CDBB98"/></linearGradient>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EFE6D2"/><stop offset="1" stop-color="#D9CBAE"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A88A66"/><stop offset="1" stop-color="#86694A"/></linearGradient>
  <linearGradient id="paving" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3A49C"/><stop offset="1" stop-color="#85867E"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#7D8891"/></linearGradient>
  <linearGradient id="mbody" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBFBF8"/><stop offset="1" stop-color="#D3D7D9"/></linearGradient>
  <linearGradient id="cover" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9CED2"/><stop offset="1" stop-color="#A9B0B6"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E4EEF2"/><stop offset="1" stop-color="#B8C8D0"/></linearGradient>
  <linearGradient id="ceramic" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9D3C6"/><stop offset="0.45" stop-color="#FAF8F2"/><stop offset="1" stop-color="#C8C1B2"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <linearGradient id="fridge" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#DCE3E6"/><stop offset="0.5" stop-color="#F3F6F7"/><stop offset="1" stop-color="#C2CBD0"/></linearGradient>
  <linearGradient id="pump" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4F8FB0"/><stop offset="1" stop-color="#2F6A88"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
  <radialGradient id="redglow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF8A70"/><stop offset="1" stop-color="#D8402F" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def tag(name):
    """An XML comment naming a prop or figure on the card. The fairness check
    (here and in test/learn_board_610_test.dart) reads these: no prop may sit
    only on the safe card of a hand, or be missing only from it."""
    return f'<!--prop:{name}-->'


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# People (the worker of tool/m6_board63_art.py; gloves or bare hands).
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


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True, props_front='', phone=False):
    """The lineman: blue shirt, helmet; rubber gloves or bare hands; [phone]
    = a mobile held to his ear (reporting)."""
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
    hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>')
    hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(props_front)
    if phone:
        g.append(f'<rect x="{f(hf[0] - 2.5)}" y="{f(hf[1] - 6)}" width="5" height="9" rx="1" fill="{WIRE}"/>'
                 f'<rect x="{f(hf[0] - 1.6)}" y="{f(hf[1] - 5)}" width="3.2" height="6" fill="url(#lcd)"/>')
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, s=S, phone=False):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates. With [phone], the front hand goes to
    his ear."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hb = local(hands_world[0])
    hf = (head[0] - 5 * face, head[1] + 2) if phone else local(hands_world[1])
    fig = figure(hip, sh, head, feet, (hb, hf), face, look, gloves, phone=phone)
    tags = tag('worker') + (tag('phone') if phone else '') + ('' if gloves else tag('barehands'))
    return tags + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def arms(hands, gloves=True, side=1):
    """Just the forearms of a worker reaching in from the bottom edge (a
    close-up): blue sleeves, gloved or bare hands."""
    hand_c = GLOVE if gloves else SKIN
    o = [tag('arms')]
    for i, (hx, hy) in enumerate(hands):
        bx = hx + (30 + 18 * i) * side
        o.append(f'<path d="M{f(bx)} {H + 4} Q{f((bx + hx) / 2 + 6 * side)} {f((H + hy) / 2 + 10)} {f(hx)} {f(hy)}" '
                 f'stroke="{SHIRT if i else SHIRT_D}" stroke-width="11" stroke-linecap="round" fill="none"/>')
        o.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="6.5" fill="{hand_c}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Glyphs: English digits as seven-segment strokes, plus V, A and '.'.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'V': 'M0 0 L3 10 L6 0',
    'A': 'M0 10 L3 0 L6 10 M1.2 6.6 L4.8 6.6',
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
            sx = ox - 4 * k if ch == '1' else ox
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

def tester(x, y, reading, s=1.0, probes=()):
    """The yellow voltage tester (top-left x, y). [reading] '0' = dead; 'live'
    = its lamp glows and the bar graph is full; None = lying unused (blank).
    [probes] = the points its two leads touch."""
    w, h = 28 * s, 42 * s
    o = [tag('tester')]
    for i, (px, py) in enumerate(probes):
        sx = x + (8 + 12 * i) * s
        o.append(f'<path d="M{f(sx)} {f(y + h)} Q{f((sx + px) / 2)} {f(max(y + h, py) + 12)} {f(px)} {f(py)}" '
                 f'stroke="{RED if i == 0 else WIRE}" stroke-width="1.3" fill="none"/>')
        o.append(f'<circle cx="{f(px)}" cy="{f(py)}" r="1.6" fill="{RED if i == 0 else WIRE}"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>')
    o.append(f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 3.5 * s)}" width="{f(w - 5 * s)}" height="{f(15 * s)}" rx="1.5" fill="url(#lcd)"/>')
    if reading == 'live':
        for i in range(4):
            o.append(f'<rect x="{f(x + (5 + i * 5) * s)}" y="{f(y + (14 - i * 2.5) * s)}" width="{f(3.5 * s)}" height="{f((3 + i * 2.5) * s)}" fill="{LCD_ON}"/>')
        o.append(f'<circle cx="{f(x + w / 2)}" cy="{f(y + 28 * s)}" r="{f(10 * s)}" fill="url(#redglow)"/>')
        o.append(f'<circle cx="{f(x + w / 2)}" cy="{f(y + 28 * s)}" r="{f(4.5 * s)}" fill="{RED}"/>')
    else:
        if reading:
            tw = glyph_width(reading, 10 * s)
            o.append(glyphs(x + (w - tw) / 2, y + 6 * s, reading, 10 * s, LCD_ON))
        o.append(f'<circle cx="{f(x + w / 2)}" cy="{f(y + 28 * s)}" r="{f(4.5 * s)}" fill="{LED_OFF}"/>')
    return ''.join(o)


def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


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


def spark(x, y, r=14):
    return (tag('spark') + f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)"/>'
            f'<path d="M{f(x - r * 0.7)} {f(y)} L{f(x + r * 0.7)} {f(y)} M{f(x)} {f(y - r * 0.7)} L{f(x)} {f(y + r * 0.7)} '
            f'M{f(x - r * 0.5)} {f(y - r * 0.5)} L{f(x + r * 0.5)} {f(y + r * 0.5)} M{f(x + r * 0.5)} {f(y - r * 0.5)} L{f(x - r * 0.5)} {f(y + r * 0.5)}" '
            f'stroke="{SUN}" stroke-width="1.6" stroke-linecap="round"/>')


def clipboard(x, y, s=1.0, mark='tick'):
    """The docket on a clipboard: a green tick, a red cross, or blank."""
    o = [tag('clipboard'), f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(34 * s)}" rx="2" fill="{BAG}"/>',
         f'<rect x="{f(x + 3 * s)}" y="{f(y + 5 * s)}" width="{f(20 * s)}" height="{f(26 * s)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + 9 * s)}" y="{f(y + 2 * s)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="url(#steel)"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 6 * s)} {f(y + (12 + i * 6) * s)} h{f(10 * s)}" stroke="{INK}" stroke-width="0.8"/>')
    if mark == 'tick':
        o.append(f'<path d="M{f(x + 13 * s)} {f(y + 23 * s)} l{f(3 * s)} {f(4 * s)} l{f(6 * s)} {f(-9 * s)}" stroke="{GREEN}" stroke-width="{f(2 * s)}" fill="none" stroke-linecap="round"/>')
    elif mark == 'cross':
        o.append(f'<path d="M{f(x + 13 * s)} {f(y + 19 * s)} l{f(8 * s)} {f(8 * s)} M{f(x + 21 * s)} {f(y + 19 * s)} l{f(-8 * s)} {f(8 * s)}" stroke="{RED}" stroke-width="{f(2 * s)}" stroke-linecap="round"/>')
    return ''.join(o)


def phone_shot(x, y):
    """A phone held up to photograph (screen facing the viewer), a small flash."""
    return (tag('camera') + f'<circle cx="{f(x + 7)}" cy="{f(y - 2)}" r="7" fill="url(#glow)"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="14" height="22" rx="2" fill="{WIRE}"/>'
            f'<rect x="{f(x + 1.5)}" y="{f(y + 2)}" width="11" height="17" fill="url(#lcd)"/>')


def phone_down(x, y):
    """The same phone lying flat on the ground, unused (no flash)."""
    return (tag('camera') + f'<rect x="{f(x)}" y="{f(y)}" width="22" height="14" rx="2" fill="{WIRE}"/>'
            f'<rect x="{f(x + 2)}" y="{f(y + 1.5)}" width="17" height="11" fill="url(#lcd)"/>')


def screwdriver(x, y, ang=0):
    """A screwdriver, its tip at (x, y)."""
    return (tag('screwdriver') + f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<path d="M{f(x)} {f(y)} L{f(x)} {f(y + 14)}" stroke="url(#steel)" stroke-width="2"/>'
            f'<rect x="{f(x - 3)}" y="{f(y + 14)}" width="6" height="16" rx="2.5" fill="{METER_D}"/></g>')


def magnet(x, y, s=1.0):
    """A horseshoe magnet (red, steel tips); (x, y) = its tips' line."""
    return (tag('magnet') + f'<path d="M{f(x - 6 * s)} {f(y)} L{f(x - 6 * s)} {f(y - 8 * s)} A{f(6 * s)} {f(6 * s)} 0 0 1 {f(x + 6 * s)} {f(y - 8 * s)} L{f(x + 6 * s)} {f(y)}" '
            f'stroke="{RED}" stroke-width="{f(4.5 * s)}" fill="none"/>'
            f'<rect x="{f(x - 8.3 * s)}" y="{f(y - 1 * s)}" width="{f(4.6 * s)}" height="{f(4 * s)}" fill="url(#steel)"/>'
            f'<rect x="{f(x + 3.7 * s)}" y="{f(y - 1 * s)}" width="{f(4.6 * s)}" height="{f(4 * s)}" fill="url(#steel)"/>')


def meter(x, y, s=1.0, kind='lcd', reading='04521', lcd=True, led='on', seal='ok', pcb=False, cover=True):
    """A single-phase energy meter: white body; an electronic one has its
    LCD, the red CAL LED and the push-button (and, with [pcb], a window on
    its chip board); a disc one has the mechanical counter and the
    aluminium disc. Below, the terminal cover and its lead seal ('ok',
    'broken' or 'none'); without [cover] the brass terminals show."""
    w, h = 56 * s, 84 * s
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(5 * s)}" fill="url(#mbody)" stroke="{INK}" stroke-width="0.8"/>']
    if kind == 'lcd':
        o.append(f'<rect x="{f(x + 7 * s)}" y="{f(y + 9 * s)}" width="{f(42 * s)}" height="{f(17 * s)}" rx="1.5" '
                 f'fill="{"url(#lcd)" if lcd else LCD_OFF}" stroke="{INK}" stroke-width="0.5"/>')
        if lcd and reading:
            tw = glyph_width(reading, 9 * s)
            o.append(glyphs(x + 28 * s - tw / 2, y + 13 * s, reading, 9 * s, LCD_ON))
        lx, ly = x + 13 * s, y + 36 * s
        if led == 'fast':
            o.append(f'<circle cx="{f(lx)}" cy="{f(ly)}" r="{f(max(12 * s, 9))}" fill="url(#redglow)"/>')
        o.append(f'<circle cx="{f(lx)}" cy="{f(ly)}" r="{f(max(2.8 * s, 1.8))}" fill="{RED if led in ("on", "fast") else LED_OFF}"/>')
        o.append(f'<circle cx="{f(x + 43 * s)}" cy="{f(y + 36 * s)}" r="{f(4.2 * s)}" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
        if pcb:
            o.append(f'<rect x="{f(x + 7 * s)}" y="{f(y + 44 * s)}" width="{f(42 * s)}" height="{f(12 * s)}" rx="1" fill="{PCB}" stroke="{INK}" stroke-width="0.5"/>')
            for i in range(3):
                cx = x + (11 + i * 13) * s
                o.append(f'<rect x="{f(cx)}" y="{f(y + 47 * s)}" width="{f(8 * s)}" height="{f(6 * s)}" fill="{WIRE}"/>')
                o.append(f'<path d="M{f(cx + 1 * s)} {f(y + 46 * s)} h{f(6 * s)} M{f(cx + 1 * s)} {f(y + 54 * s)} h{f(6 * s)}" stroke="{BRASS}" stroke-width="0.8" stroke-dasharray="1 1"/>')
    else:
        o.append(f'<rect x="{f(x + 6 * s)}" y="{f(y + 8 * s)}" width="{f(44 * s)}" height="{f(44 * s)}" rx="2" fill="url(#glass)" stroke="{INK}" stroke-width="0.6"/>')
        o.append(f'<rect x="{f(x + 12 * s)}" y="{f(y + 12 * s)}" width="{f(32 * s)}" height="{f(11 * s)}" fill="{WIRE}"/>')
        tw = glyph_width(reading, 7 * s)
        o.append(glyphs(x + 28 * s - tw / 2, y + 14 * s, reading, 7 * s, PAPER))
        o.append(f'<ellipse cx="{f(x + 28 * s)}" cy="{f(y + 40 * s)}" rx="{f(19 * s)}" ry="{f(4 * s)}" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
        o.append(f'<rect x="{f(x + 34 * s)}" y="{f(y + 37.5 * s)}" width="{f(4 * s)}" height="{f(3 * s)}" fill="{WIRE}"/>')
    if cover:
        o.append(f'<rect x="{f(x + 3 * s)}" y="{f(y + 60 * s)}" width="{f(50 * s)}" height="{f(21 * s)}" rx="{f(3 * s)}" fill="url(#cover)" stroke="{INK}" stroke-width="0.5"/>')
        o.append(f'<circle cx="{f(x + 28 * s)}" cy="{f(y + 64 * s)}" r="{f(1.6 * s)}" fill="url(#steel)"/>')
        sx, sy = x + 28 * s, y + 64 * s
        if seal == 'ok':
            o.append(f'<path d="M{f(sx)} {f(sy)} q{f(-5 * s)} {f(14 * s)} 0 {f(24 * s)} q{f(5 * s)} {f(-10 * s)} 0 {f(-24 * s)}" stroke="{SEAL}" stroke-width="1.1" fill="none"/>')
            o.append(f'<circle cx="{f(sx)}" cy="{f(sy + 27 * s)}" r="{f(3.8 * s)}" fill="{SEAL}" stroke="{INK}" stroke-width="0.6"/>')
        elif seal == 'broken':
            o.append(f'<path d="M{f(sx)} {f(sy)} q{f(-5 * s)} {f(6 * s)} {f(-4 * s)} {f(11 * s)}" stroke="{SEAL}" stroke-width="1.1" fill="none"/>')
            o.append(f'<path d="M{f(sx + 6 * s)} {f(y + 90 * s)} q{f(5 * s)} {f(-6 * s)} {f(11 * s)} {f(-3 * s)}" stroke="{SEAL}" stroke-width="1.1" fill="none"/>')
            o.append(f'<circle cx="{f(sx + 6 * s)}" cy="{f(y + 92 * s)}" r="{f(3.8 * s)}" fill="{SEAL}" stroke="{INK}" stroke-width="0.6"/>')
    else:
        o.append(f'<rect x="{f(x + 3 * s)}" y="{f(y + 60 * s)}" width="{f(50 * s)}" height="{f(21 * s)}" rx="{f(3 * s)}" fill="{WIRE}"/>')
        for i in range(4):
            o.append(f'<rect x="{f(x + (8 + i * 11) * s)}" y="{f(y + 64 * s)}" width="{f(7 * s)}" height="{f(10 * s)}" rx="1" fill="{BRASS}"/>')
    return ''.join(o)


def terminals(x, y, s=1.0):
    """The meter's terminal points (phase in, phase out, neutral in, neutral
    out) in card coordinates."""
    return [(x + (11.5 + i * 11) * s, y + 72 * s) for i in range(4)]


# --------------------------------------------------------------------------
# The meter box on the house wall (rounds modern, theft, swap).
# --------------------------------------------------------------------------

MX, MY = 72, 54          # the meter in the box
CX, CY = 80, 28          # the incoming cut-out's base


def cutout(x, y, fitted=True):
    """The incoming cut-out: black base with brass contacts; its white
    porcelain carrier pushed in, or out (the base empty)."""
    o = [f'<rect x="{x}" y="{y}" width="40" height="16" rx="2" fill="{WIRE}"/>',
         f'<rect x="{x + 3}" y="{y + 4}" width="7" height="8" fill="{BRASS}"/><rect x="{x + 30}" y="{y + 4}" width="7" height="8" fill="{BRASS}"/>']
    if fitted:
        o.append(carrier(x - 2, y - 2))
    return ''.join(o)


def carrier(x, y, ang=0):
    """The cut-out's porcelain carrier, (x, y) its top-left."""
    return (f'<g transform="rotate({ang} {f(x + 22)} {f(y + 10)})">'
            f'<rect x="{f(x)}" y="{f(y)}" width="44" height="20" rx="5" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/>'
            f'<rect x="{f(x + 16)}" y="{f(y - 4)}" width="12" height="6" rx="2" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/></g>')


def wall_stage(cut=True, kind='lcd', reading='04521', lcd=True, led='on', seal='ok', pcb=False, cover=True, meter_in=True):
    out = card_open('wall')
    out.append(f'<rect x="0" y="{GY - 2}" width="{W}" height="{H - GY + 2}" fill="url(#paving)"/>')
    # the box and its door, swung open to the left
    out.append(f'<rect x="44" y="12" width="112" height="156" rx="4" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<rect x="50" y="18" width="100" height="144" rx="2" fill="url(#panel)"/>')
    out.append(f'<path d="M44 12 L22 22 L22 158 L44 168 Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.8"/>')
    # the service cable in from the top, the house wires out at the bottom
    out.append(f'<path d="M64 0 V36 H{CX}" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
    out.append(f'<path d="M58 0 V152 H{f(terminals(MX, MY)[2][0])} V{MY + 80}" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
    out.append(f'<path d="M{CX + 40} 36 H142 V148 H{f(terminals(MX, MY)[0][0])} V{MY + 80}" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
    for i in (1, 3):
        tx = terminals(MX, MY)[i][0]
        out.append(f'<path d="M{f(tx)} {MY + 80} V{GY - 2}" stroke="{WIRE}" stroke-width="2.4"/>')
    if cut:
        out.append(cutout(CX, CY, fitted=True))
    if meter_in:
        out.append(meter(MX, MY, 1.0, kind, reading, lcd, led, seal, pcb, cover))
    return out


# --------------------------------------------------------------------------
# Round 1 — modern: old and new meters.
# --------------------------------------------------------------------------

def modern_card(kind):
    if kind == 'lcd':
        # The electronic meter: LCD, chip board seen through its window, no
        # disc; the CAL LED lit.
        out = wall_stage(cut=False, pcb=True)
        out.append(person(178, ((150, 152), (MX + 46, MY + 66)), face=-1, look=-12))
    elif kind == 'button':
        # A gloved finger on the push-button: the LCD has stepped on to the
        # current.
        out = wall_stage(cut=False, reading='4.8 A')
        out.append(motion(MX + 28, MY + 6, 0, -1, 3, 5))
        out.append(person(172, ((150, 152), (MX + 43, MY + 38)), face=-1, look=-14))
    elif kind == 'smart':
        # The smart meter: its reading goes out to the office by itself.
        out = wall_stage(cut=False)
        out.append(f'<path d="M{MX + 50} {MY} L{MX + 50} {MY - 14}" stroke="{WIRE}" stroke-width="1.6"/>')
        for r in (6, 11, 16):
            out.append(f'<path d="M{MX + 50 + r * 0.7} {MY - 14 - r * 0.7} A{r} {r} 0 0 1 {MX + 50 + r * 0.7} {MY - 14 + r * 0.7}" '
                       f'transform="rotate(-45 {MX + 50} {MY - 14})" stroke="{MOVE}" stroke-width="2" fill="none" stroke-linecap="round"/>')
        out.append(f'<rect x="162" y="20" width="32" height="44" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
        for i in range(3):
            for j in range(2):
                out.append(f'<rect x="{167 + j * 13}" y="{26 + i * 12}" width="9" height="7" fill="{INK}"/>')
        out.append(person(178, ((150, 152), (146, 146)), face=-1, look=-24))
        out.append(clipboard(132, 132, 0.8, mark=''))
    elif kind == 'disc':
        # A disc meter, its disc turning — and the docket says modern.
        out = wall_stage(cut=False, kind='disc', reading='04521')
        out.append(motion(MX + 50, MY + 40, 1, 0, 2, 6))
        out.append(person(178, ((150, 152), (146, 146)), face=-1, look=-8))
        out.append(clipboard(132, 132, 0.8))
    elif kind == 'kwh':
        # A fault call: only the kWh read off the LCD, docket ticked, the
        # push-button never touched.
        out = wall_stage(cut=False)
        out.append(person(178, ((150, 152), (146, 146)), face=-1, look=-8))
        out.append(clipboard(132, 132, 0.8))
    elif kind == 'putback':
        # The electronic meter lies on the ground, its chip board showing; a
        # disc meter goes back in.
        out = wall_stage(cut=False, kind='disc', reading='04521')
        out.append(f'<g transform="rotate(-80 150 196)">{meter(150, 196, 0.42, pcb=True, cover=False)}</g>')
        out.append(person(176, ((MX + 50, MY + 30), (MX + 54, MY + 60)), face=-1, look=-14))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — fast: "the meter runs fast" inside the customer's house.
# --------------------------------------------------------------------------

SB = (74, 92)            # the switchboard's top-left


def room_stage(switches=(False, False, False), bulb=False, fan=False, led='off', rain=False):
    out = card_open('room')
    out.append(f'<rect x="0" y="176" width="{W}" height="44" fill="url(#floor)"/>')
    # the window (rain outside on a wet day)
    out.append(f'<rect x="146" y="22" width="44" height="40" fill="url(#day)" stroke="{PAPER}" stroke-width="3"/>')
    out.append(f'<path d="M168 22 V62" stroke="{PAPER}" stroke-width="2"/>')
    if rain:
        for i in range(7):
            x0 = 150 + i * 6
            out.append(f'<path d="M{x0} {26 + (i % 3) * 8} l-3 9" stroke="{RAIN}" stroke-width="1.2" stroke-linecap="round"/>')
    # the meter board high on the wall
    out.append(f'<rect x="8" y="14" width="44" height="64" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(meter(13, 18, 0.62, led=led))
    out.append(f'<path d="M30 78 V96 H{SB[0]}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    # the switchboard: three switches, down = OFF
    out.append(f'<rect x="{SB[0]}" y="{SB[1]}" width="38" height="24" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>')
    for i, on in enumerate(switches):
        sx = SB[0] + 6 + i * 10
        out.append(f'<rect x="{sx}" y="{SB[1] + 5}" width="6" height="14" rx="1" fill="url(#cover)"/>')
        out.append(f'<rect x="{sx + 1}" y="{SB[1] + (6 if on else 12)}" width="4" height="6" rx="1" fill="{WIRE}"/>')
    # the wall clock
    out.append(f'<circle cx="80" cy="40" r="11" fill="{PAPER}" stroke="{INK}" stroke-width="1.2"/>')
    out.append(f'<path d="M80 40 V32 M80 40 L86 43" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
    # the ceiling fan
    out.append(f'<path d="M116 0 V14" stroke="{INK}" stroke-width="1.6"/>')
    out.append(f'<ellipse cx="102" cy="16" rx="14" ry="2.6" fill="url(#steel)"/><ellipse cx="130" cy="16" rx="14" ry="2.6" fill="url(#steel)"/>')
    out.append(f'<circle cx="116" cy="16" r="3.5" fill="{INK}"/>')
    if fan:
        for dx in (-22, 22):
            out.append(f'<path d="M{116 + dx - 8} 23 Q{116 + dx} 27 {116 + dx + 8} 23" stroke="{MOVE}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    # the bulb
    out.append(f'<path d="M140 0 V36" stroke="{WIRE}" stroke-width="1"/>')
    if bulb:
        out.append(f'<circle cx="140" cy="42" r="15" fill="url(#glow)"/>')
    out.append(f'<circle cx="140" cy="42" r="5.5" fill="{SUN if bulb else PAPER}" stroke="{INK}" stroke-width="0.6"/>')
    # the old fridge and the water pump
    out.append(f'<rect x="150" y="92" width="40" height="96" rx="4" fill="url(#fridge)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<path d="M150 124 H190 M156 104 V118 M156 132 V150" stroke="{INK}" stroke-width="1.2"/>')
    out.append(f'<rect x="112" y="170" width="28" height="18" rx="4" fill="url(#pump)"/>')
    out.append(f'<path d="M140 178 H148 M126 170 V160" stroke="url(#steel)" stroke-width="3"/>')
    return out


def fast_card(kind):
    if kind == 'off':
        # Every switch down, fan and bulb still — and his eyes on the CAL LED.
        out = room_stage(led='off')
        out.append(person(44, ((50, 150), (58, 146)), face=-1, look=-26))
        out.append(clipboard(52, 128, 0.8, mark=''))
    elif kind == 'bulb':
        # The LED stayed still; now one switch up, a 100 W bulb alight, the
        # clock marking the hour; the LED ticks slowly.
        out = room_stage(switches=(True, False, False), bulb=True, led='on')
        out.append(f'<path d="M80 29 A11 11 0 1 1 79.9 29" stroke="{SUN}" stroke-width="3" fill="none"/>')
        out.append(person(44, ((50, 150), (58, 146)), face=-1, look=-26))
        out.append(clipboard(52, 128, 0.8, mark=''))
    elif kind == 'explain':
        # Showing the customer how the old fridge and the pump draw power.
        out = room_stage(led='off')
        out.append(person(110, ((104, 150), (148, 120)), face=1, look=-6))
    elif kind == 'leak':
        # All switches down, yet the LED races — and the docket says fine.
        out = room_stage(led='fast')
        out.append(motion(21, 36, -1, 0, 2, 6))
        out.append(person(44, ((50, 150), (58, 146)), face=-1, look=-26))
        out.append(clipboard(52, 128, 0.8))
    elif kind == 'fan':
        # Fan turning, bulb alight — a verdict written anyway.
        out = room_stage(switches=(True, True, True), bulb=True, fan=True, led='fast')
        out.append(person(44, ((50, 150), (58, 146)), face=-1, look=-26))
        out.append(clipboard(52, 128, 0.8))
    elif kind == 'weather':
        # Rain outside: "the cold makes it run so" — and off he goes.
        out = room_stage(led='off', rain=True)
        out.append(person(60, ((54, 150), (66, 146)), face=1, look=-4))
        out.append(motion(34, 160, -1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — blank: the service cable from the pole to the house's meter.
# --------------------------------------------------------------------------

BMX, BMY, BS = 112, 92, 0.62     # the meter on the house wall


def blank_stage(lcd=False, cut_neutral=False):
    out = card_open('day')
    out.append(cloud(60, 26, 1.0))
    out.append(f'<rect x="0" y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    out.append(f'<rect x="92" y="54" width="110" height="144" fill="url(#house)"/>')
    out.append(f'<path d="M84 56 L146 18 L208 56 Z" fill="url(#roof)"/>')
    out.append(f'<rect x="166" y="72" width="24" height="26" fill="{WIN_OFF}" stroke="{PAPER}" stroke-width="2"/>')
    out.append(pole(18, 8, GY, 8))
    out.append(f'<rect x="8" y="24" width="22" height="4" rx="1" fill="url(#pole)"/>')
    # the service cable: phase and neutral, sagging from the pole to the wall
    out.append(f'<path d="M24 26 Q60 56 100 66" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    if cut_neutral:
        out.append(f'<path d="M24 31 Q32 40 40 45 M46 49 Q74 64 100 70" stroke="{INK}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M40 45 q3 5 -1 8 M46 49 q-4 4 0 8" stroke="{INK}" stroke-width="1.2" fill="none"/>')
    else:
        out.append(f'<path d="M24 31 Q60 62 100 70" stroke="{INK}" stroke-width="1.6" fill="none"/>')
    out.append(f'<path d="M100 66 L{BMX + 6} 66 L{BMX + 6} {BMY - 4}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    out.append(f'<rect x="{BMX - 6}" y="{BMY - 6}" width="47" height="70" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(meter(BMX, BMY, BS, lcd=lcd, led='on' if lcd else 'off', cover=False))
    return out


def blank_card(kind):
    t = terminals(BMX, BMY, BS)
    if kind == 'tester':
        # Blank LCD: the tester's leads on the incoming terminals first.
        out = blank_stage(lcd=False)
        out.append(person(174, ((150, 146), (146, 140)), face=-1, look=-10))
        out.append(tester(132, 124, 'live', 0.75, probes=(t[0], t[2])))
    elif kind == 'cable':
        # Nothing at the incoming terminals (tester at 0): he follows the
        # service cable back to the pole.
        out = blank_stage(lcd=False)
        out.append(tester(136, 128, '0', 0.75, probes=(t[0], t[2])))
        out.append(person(66, ((60, 150), (54, 120)), face=-1, look=-30))
    elif kind == 'neutral':
        # The meter alive, the house dark: the neutral of the service cable,
        # parted, under his eye.
        out = blank_stage(lcd=True, cut_neutral=True)
        out.append(person(66, ((60, 150), (54, 120)), face=-1, look=-30))
        out.append(tester(146, 150, None, 0.6))
    elif kind == 'newmeter':
        # A blank LCD — and a new meter on its way in, nothing measured; the
        # tester lies in the grass.
        out = blank_stage(lcd=False)
        out.append(person(172, ((140, 140), (150, 136)), face=-1, look=-10))
        out.append(meter(124, 120, 0.42))
        out.append(tester(148, 186, None, 0.55))
    elif kind == 'pole':
        # The tester shows the incoming is live — yet he carries the ladder
        # to the pole.
        out = blank_stage(lcd=False)
        out.append(tester(136, 128, 'live', 0.75, probes=(t[0], t[2])))
        out.append(f'<path d="M30 196 L74 120 M40 198 L84 122" stroke="url(#pole)" stroke-width="3"/>')
        for i in range(6):
            out.append(f'<path d="M{34 + i * 7} {189 - i * 12} l10 2" stroke="url(#pole)" stroke-width="2.4"/>')
        out.append(person(70, ((64, 150), (76, 140)), face=-1, look=-6))
    elif kind == 'bad':
        # The meter alive, the house dark — docket: the meter is bad.
        out = blank_stage(lcd=True)
        out.append(person(174, ((150, 152), (146, 146)), face=-1, look=-8))
        out.append(clipboard(132, 136, 0.8, mark='cross'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — theft: signs of tampering at the meter box.
# --------------------------------------------------------------------------

def bypass_wire():
    t = terminals(MX, MY)
    # A red wire tapped off the incoming before the meter, round the box to
    # the house side, with a rough twisted joint.
    return (f'<path d="M142 70 Q166 90 160 128 Q154 156 {f(t[1][0])} 168" stroke="{PVC}" stroke-width="2.6" fill="none"/>'
            f'<path d="M138 66 l8 8 M140 72 l6 -4" stroke="{BRASS}" stroke-width="1.4"/>')


def theft_card(kind):
    if kind == 'seal':
        # The seal hangs broken: he reports it by phone.
        out = wall_stage(seal='broken')
        out.append(person(180, ((172, 160), (0, 0)), face=-1, look=-8, phone=True))
    elif kind == 'bypass':
        # A bypass wire round the meter: seen from a distance, reported.
        out = wall_stage()
        out.append(bypass_wire())
        out.append(person(186, ((178, 160), (0, 0)), face=-1, look=-4, phone=True))
    elif kind == 'magnet':
        # A magnet stuck on the meter: reported by phone.
        out = wall_stage()
        out.append(magnet(MX + 28, MY + 50, 1.3))
        out.append(person(180, ((172, 160), (0, 0)), face=-1, look=-8, phone=True))
    elif kind == 'walk':
        # The seal broken — and he walks off.
        out = wall_stage(seal='broken')
        out.append(person(176, ((170, 150), (182, 152)), face=1, look=0))
        out.append(motion(150, 150, -1, 0, 3, 8))
    elif kind == 'pull':
        # On the phone reporting it — and his bare hand tugging the bypass
        # wire off at the same time: a flash.
        out = wall_stage()
        out.append(bypass_wire())
        out.append(spark(156, 110, 12))
        out.append(person(180, ((158, 112), (0, 0)), face=-1, look=-10, gloves=False, phone=True))
    elif kind == 'pocket':
        # The magnet comes off the meter — into his pocket.
        out = wall_stage()
        out.append(person(176, ((182, 160), (172, 168)), face=-1, look=8))
        out.append(magnet(170, 172, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — swap: the old meter out, the new meter in (ruling X5).
# --------------------------------------------------------------------------

def swap_card(kind):
    t = terminals(MX, MY)
    if kind == 'cutout':
        # Gloves on, the cut-out's carrier out in his hand; the tester's
        # leads on the incoming terminals read 0. Only then hands in.
        out = wall_stage(cut=False, cover=False)
        out.append(cutout(CX, CY, fitted=False))
        out.append(tester(150, 92, '0', 0.75, probes=(t[0], t[2])))
        out.append(person(178, ((150, 148), (160, 150)), face=-1, look=-12))
        out.append(tag('carrier') + carrier(148, 150, -20))
    elif kind == 'oldphoto':
        # Before anything: the old meter's final reading, photographed.
        out = wall_stage()
        out.append(person(180, ((170, 160), (150, 100)), face=-1, look=-14))
        out.append(phone_shot(140, 82))
    elif kind == 'newphoto':
        # The new meter in: its first reading, photographed; the old one
        # waits on the ground.
        out = wall_stage(reading='00001')
        out.append(person(180, ((170, 160), (150, 100)), face=-1, look=-14))
        out.append(phone_shot(140, 82))
        out.append(f'<g transform="rotate(-80 150 196)">{meter(150, 196, 0.42)}</g>')
    elif kind == 'live':
        # The cut-out still in — the tester shows live — and a screwdriver on
        # the terminals: a flash.
        out = wall_stage(cover=False)
        out.append(tester(150, 92, 'live', 0.75))
        out.append(screwdriver(t[0][0], t[0][1], 20))
        out.append(spark(t[0][0], t[0][1], 12))
        out.append(person(178, ((t[0][0] + 8, t[0][1] + 26), (150, 150)), face=-1, look=-16))
    elif kind == 'bag':
        # The old meter goes into the bag, no reading taken: his phone lies
        # unused in the grass.
        out = wall_stage(cut=False, cover=False, meter_in=False)
        out.append(cutout(CX, CY, fitted=False))
        out.append(f'<path d="M126 150 L180 150 L174 196 L132 196 Z" fill="{BAG}"/>')
        out.append(meter(136, 120, 0.5))
        out.append(person(186, ((170, 140), (160, 134)), face=-1, look=-6))
        out.append(tag('carrier') + carrier(18, 182, 0))
        out.append(phone_down(98, 184))
    elif kind == 'notest':
        # The cut-out out — but the tester lies unused and the screwdriver is
        # already on the terminals.
        out = wall_stage(cut=False, cover=False)
        out.append(cutout(CX, CY, fitted=False))
        out.append(tag('carrier') + carrier(18, 182, 0))
        out.append(screwdriver(t[0][0], t[0][1], 20))
        out.append(tester(150, 176, None, 0.55))
        out.append(person(178, ((t[0][0] + 8, t[0][1] + 26), (150, 150)), face=-1, look=-16))
    return card_close(out)


CARDS = {}
for k in ('lcd', 'button', 'smart', 'disc', 'kwh', 'putback'):
    CARDS[f'modern_{k}'] = modern_card(k)
for k in ('off', 'bulb', 'explain', 'leak', 'fan', 'weather'):
    CARDS[f'fast_{k}'] = fast_card(k)
for k in ('tester', 'cable', 'neutral', 'newmeter', 'pole', 'bad'):
    CARDS[f'blank_{k}'] = blank_card(k)
for k in ('seal', 'bypass', 'magnet', 'walk', 'pull', 'pocket'):
    CARDS[f'theft_{k}'] = theft_card(k)
for k in ('cutout', 'oldphoto', 'newphoto', 'live', 'bag', 'notest'):
    CARDS[f'swap_{k}'] = swap_card(k)

# Safe cards and traps per round (mirrors learn_board_pack610.dart).
ROUNDS = {
    'modern': (['modern_lcd', 'modern_button', 'modern_smart'], ['modern_disc', 'modern_kwh', 'modern_putback']),
    'fast': (['fast_off', 'fast_bulb', 'fast_explain'], ['fast_leak', 'fast_fan', 'fast_weather']),
    'blank': (['blank_tester', 'blank_cable', 'blank_neutral'], ['blank_newmeter', 'blank_pole', 'blank_bad']),
    'theft': (['theft_seal', 'theft_bypass', 'theft_magnet'], ['theft_walk', 'theft_pull', 'theft_pocket']),
    'swap': (['swap_cutout', 'swap_oldphoto', 'swap_newphoto'], ['swap_live', 'swap_bag', 'swap_notest']),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
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
                # Props and figures: none only on the safe card, none missing
                # only from it (on every trap of the hand but not the safe).
                trap_props = [props[t] for t in hand]
                alone = props[s] - set().union(*trap_props)
                missing = set.intersection(*trap_props) - props[s]
                if alone:
                    problems.append(f'{rnd}: {s} with {hand} has props {sorted(alone)} alone')
                if missing:
                    problems.append(f'{rnd}: {s} with {hand} alone lacks props {sorted(missing)}')
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
