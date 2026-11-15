"""Picture cards for lesson 6.3 শেখা ("ফিউজ: নীরব প্রহরী ও তারের সঠিক হিসাব").

python -I tool/m6_board63_art.py .

Writes assets/game/art/m6_board63/*.svg in the clean gradient style of
tool/m5_board55_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the labels a worker reads (a nameplate's kVA, a reel tag, a gauge
plate's slot number, a micrometer's or tester's reading) are drawn as stroke
glyphs with English digits.

What the cards show comes from lesson 6.3 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only:
  1. hg: the horn gap fuse on the 11 kV DTR pole — tinned copper wire taut
     between the two arcing horns; on a fault the wire melts and the arc
     climbs the horns and dies in the air. Traps: GI binding wire, a slack
     wire, an ACSR aluminium strand;
  2. rating: HG fuse wire by the DTR's kVA (25 → 2-3 A, 63 → 5 A,
     100 → 8-10 A): the nameplate and the reel tag. Traps: 25 kVA + 10 A,
     63 kVA + 10 A, a thick conductor on a 100 kVA;
  3. hrc: the LT box's HRC fuses — sealed cartridge with its red dot; the DTR
     LT switch OFF, locked and tagged, the tester at 0, gloves, goggles and the
     insulated puller (ruling X4). Traps: copper strip on an empty base,
     ordinary pliers, the switch ON while pulling, bare hands and no goggles;
  4. gauge: a 100 A wire measured — bare wire snug in the gauge plate's 14
     slot, the micrometer at 2.00 mm (IS 9926 table, ruling X6). Traps: snug
     in 25 taken as thick, insulation still on, two reels judged by eye, a
     1.50 mm (63 A) wire put on 100 A. Five rounds, as the Module 5 boards
     (ruling M5-11): the spare-wire round left the board (owner 2026-11-15);
  5. blow: a house short circuit — only the house fuse blows (LT box dots and
     HG intact); an HG blown on a house fault: first find the wrong wire
     downstream; HG wire renewed only with the LT switch OFF, the AB open
     (all three blades), proven dead and earthed (ruling M6-2). Traps: the AB
     closed again with the cause not found (the house still smoking), the LT
     box blown and the house intact ticked as fine, HG wire renewed with the
     AB still closed (no earth: the set lies coiled on the ground).

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
    print('usage: python -I tool/m6_board63_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board63')
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
# People (the worker from tool/m5_board55_art.py; gloves or bare hands,
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


def reel(x, y, s=1.0, tag=None, wire=TIN):
    """A spool of fuse wire (brown flanges, tinned coil) with an optional
    paper tag (its rating drawn on it)."""
    o = [f'<rect x="{f(x - 14 * s)}" y="{f(y - 16 * s)}" width="{f(28 * s)}" height="{f(32 * s)}" rx="{f(3 * s)}" fill="{BAG}"/>',
         f'<rect x="{f(x - 10 * s)}" y="{f(y - 16 * s)}" width="{f(20 * s)}" height="{f(32 * s)}" fill="{wire}"/>']
    for i in range(6):
        yy = y - 13 * s + i * 5 * s
        o.append(f'<path d="M{f(x - 10 * s)} {f(yy)} L{f(x + 10 * s)} {f(yy + 2.5 * s)}" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.6"/>')
    o.append(f'<rect x="{f(x - 14 * s)}" y="{f(y - 18 * s)}" width="{f(28 * s)}" height="{f(4 * s)}" rx="1.5" fill="{BAG}"/>')
    o.append(f'<rect x="{f(x - 14 * s)}" y="{f(y + 14 * s)}" width="{f(28 * s)}" height="{f(4 * s)}" rx="1.5" fill="{BAG}"/>')
    if tag:
        tw = glyph_width(tag, 9 * s)
        o.append(f'<path d="M{f(x + 12 * s)} {f(y - 8 * s)} L{f(x + 20 * s)} {f(y - 2 * s)}" stroke="{INK}" stroke-width="0.8"/>')
        o.append(f'<rect x="{f(x + 18 * s)}" y="{f(y - 4 * s)}" width="{f(tw + 8 * s)}" height="{f(16 * s)}" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>')
        o.append(glyphs(x + 22 * s, y - 0.5 * s, tag, 9 * s, INK))
    return ''.join(o)


def micrometer(x, y, reading, s=1.0, wire=TIN):
    """A digital micrometer (C frame, spindle, thimble, reading window) with a
    wire held between anvil and spindle; (x, y) = the anvil face."""
    o = [f'<path d="M{f(x - 4 * s)} {f(y - 10 * s)} L{f(x - 4 * s)} {f(y + 22 * s)} Q{f(x - 4 * s)} {f(y + 34 * s)} {f(x + 10 * s)} {f(y + 34 * s)} '
         f'L{f(x + 26 * s)} {f(y + 34 * s)} Q{f(x + 38 * s)} {f(y + 34 * s)} {f(x + 38 * s)} {f(y + 22 * s)} L{f(x + 38 * s)} {f(y + 6 * s)}" '
         f'stroke="url(#steel)" stroke-width="{f(8 * s)}" fill="none" stroke-linecap="round"/>',
         f'<rect x="{f(x - 2 * s)}" y="{f(y - 3 * s)}" width="{f(6 * s)}" height="{f(6 * s)}" fill="{INK}"/>',
         f'<rect x="{f(x + 8 * s)}" y="{f(y - 3 * s)}" width="{f(24 * s)}" height="{f(6 * s)}" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>',
         f'<rect x="{f(x + 32 * s)}" y="{f(y - 6 * s)}" width="{f(24 * s)}" height="{f(12 * s)}" rx="2" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>']
    for i in range(4):
        o.append(f'<path d="M{f(x + (36 + i * 5) * s)} {f(y - 6 * s)} v{f(12 * s)}" stroke="{INK}" stroke-width="0.5"/>')
    tw = glyph_width(reading, 8 * s)
    o.append(f'<rect x="{f(x + 6 * s)}" y="{f(y + 12 * s)}" width="{f(28 * s)}" height="{f(14 * s)}" rx="1.5" fill="url(#lcd)" stroke="{INK}" stroke-width="0.5"/>')
    o.append(glyphs(x + 20 * s - tw / 2, y + 15 * s, reading, 8 * s, LCD_ON))
    if wire:
        o.append(f'<path d="M{f(x + 6 * s)} {f(y - 30 * s)} Q{f(x + 3 * s)} {f(y - 12 * s)} {f(x + 6 * s)} {f(y)} L{f(x + 6 * s)} {f(y + 2 * s)}" stroke="{wire}" stroke-width="{f(2.2 * s)}" fill="none"/>')
    return ''.join(o)


def gauge_plate(cx, cy, r=38, number='14', slot_at=-60, wire=TIN, sheathed=False):
    """A round wire gauge plate (steel) with slots round its rim; a wire end
    sits in the slot at angle [slot_at] (degrees), its number stamped beside."""
    o = [f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{r}" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>',
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="5" fill="{WIRE}"/>']
    for i in range(16):
        a = math.radians(i * 22.5)
        x0, y0 = cx + math.cos(a) * (r - 7), cy + math.sin(a) * (r - 7)
        x1, y1 = cx + math.cos(a) * (r + 0.5), cy + math.sin(a) * (r + 0.5)
        o.append(f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{WIRE}" stroke-width="{f(1.2 + (i % 8) * 0.25)}"/>')
    a = math.radians(slot_at)
    sx, sy = cx + math.cos(a) * (r - 4), cy + math.sin(a) * (r - 4)
    nx, ny = cx + math.cos(a) * (r - 17), cy + math.sin(a) * (r - 17)
    o.append(glyphs(nx - glyph_width(number, 8) / 2, ny - 4, number, 8, INK))
    ex, ey = sx + math.cos(a) * 40, sy + math.sin(a) * 40
    if sheathed:
        o.append(f'<path d="M{f(sx)} {f(sy)} L{f(ex)} {f(ey)}" stroke="{PVC}" stroke-width="5.5" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{f(sx)} {f(sy)} L{f(ex)} {f(ey)}" stroke="{wire}" stroke-width="2.2" stroke-linecap="round"/>')
    return ''.join(o)


def hrc(x, y, dot=RED, s=1.0):
    """A sealed HRC cartridge (white ceramic, steel end caps, its dot) in its
    black base with brass contacts; (x, y) = top-left of the base."""
    w, h = 22 * s, 52 * s
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{WIRE}"/>',
         f'<rect x="{f(x + 4 * s)}" y="{f(y + 2 * s)}" width="{f(w - 8 * s)}" height="{f(6 * s)}" fill="{BRASS}"/>',
         f'<rect x="{f(x + 4 * s)}" y="{f(y + h - 8 * s)}" width="{f(w - 8 * s)}" height="{f(6 * s)}" fill="{BRASS}"/>']
    if dot is not None:
        o.append(f'<rect x="{f(x + 3 * s)}" y="{f(y + 9 * s)}" width="{f(w - 6 * s)}" height="{f(h - 18 * s)}" rx="3" fill="url(#ceramic)"/>')
        o.append(f'<rect x="{f(x + 2 * s)}" y="{f(y + 7 * s)}" width="{f(w - 4 * s)}" height="{f(5 * s)}" rx="1.5" fill="url(#steel)"/>')
        o.append(f'<rect x="{f(x + 2 * s)}" y="{f(y + h - 12 * s)}" width="{f(w - 4 * s)}" height="{f(5 * s)}" rx="1.5" fill="url(#steel)"/>')
        o.append(f'<circle cx="{f(x + w / 2)}" cy="{f(y + 20 * s)}" r="{f(2.8 * s)}" fill="{dot}"/>')
    return ''.join(o)


def mccb(x, y, on=True, locked=False):
    """The DTR's LT switch (an MCCB): black body, handle up (ON, red window)
    or down (OFF, green window); [locked] = padlock and red tag on the handle."""
    o = [f'<rect x="{x}" y="{y}" width="46" height="36" rx="3" fill="{WIRE}"/>',
         f'<rect x="{x + 6}" y="{y + 6}" width="10" height="7" rx="1" fill="{RED if on else GREEN}"/>',
         f'<rect x="{x + 22}" y="{y + 8}" width="14" height="20" rx="2" fill="{INK}"/>']
    if on:
        o.append(f'<rect x="{x + 25}" y="{y + 4}" width="8" height="13" rx="2" fill="url(#steel)"/>')
    else:
        o.append(f'<rect x="{x + 25}" y="{y + 19}" width="8" height="13" rx="2" fill="url(#steel)"/>')
    if locked:
        o.append(padlock(x + 29, y + 32))
    return ''.join(o)


def puller(x, y, ang=0):
    """The insulated HRC fuse puller (yellow body, red grips) — its jaws at (x, y)."""
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x - 7)}" y="{f(y - 3)}" width="14" height="6" rx="1.5" fill="{HELMET_D}"/>'
            f'<rect x="{f(x - 3)}" y="{f(y + 3)}" width="6" height="16" fill="{HELMET_D}"/>'
            f'<rect x="{f(x - 4.5)}" y="{f(y + 19)}" width="9" height="16" rx="3" fill="{RED}"/></g>')


def pliers(x, y, ang=0):
    """Ordinary pliers (steel jaws, red handles) — the jaws at (x, y)."""
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<path d="M{f(x - 3)} {f(y - 6)} L{f(x - 1.5)} {f(y + 8)} M{f(x + 3)} {f(y - 6)} L{f(x + 1.5)} {f(y + 8)}" stroke="url(#steel)" stroke-width="3" stroke-linecap="round"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 8)}" r="2.4" fill="url(#steel)"/>'
            f'<path d="M{f(x - 1.5)} {f(y + 9)} L{f(x - 6)} {f(y + 30)} M{f(x + 1.5)} {f(y + 9)} L{f(x + 6)} {f(y + 30)}" stroke="{RED}" stroke-width="4" stroke-linecap="round"/></g>')


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


def kitkat(x, y, s=1.0, wire=TIN, stubs=False, thick=False, strands=0):
    """A kit-kat fuse carrier (white porcelain) lying flat, seen from above,
    with its fuse wire between the two terminal screws."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(54 * s)}" height="{f(20 * s)}" rx="{f(5 * s)}" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{f(x + 4 * s)}" y="{f(y + 6 * s)}" width="{f(10 * s)}" height="{f(8 * s)}" rx="1.5" fill="url(#steel)"/>',
         f'<rect x="{f(x + 40 * s)}" y="{f(y + 6 * s)}" width="{f(10 * s)}" height="{f(8 * s)}" rx="1.5" fill="url(#steel)"/>']
    a, b = (x + 9 * s, y + 10 * s), (x + 45 * s, y + 10 * s)
    if stubs:
        o.append(f'<path d="M{f(a[0])} {f(a[1])} l{f(8 * s)} {f(2 * s)} M{f(b[0])} {f(b[1])} l{f(-7 * s)} {f(-2 * s)}" stroke="{TIN}" stroke-width="1.4" stroke-linecap="round"/>')
    elif strands:
        for i in range(strands):
            amp = (i - (strands - 1) / 2) * 1.6 * s
            o.append(f'<path d="M{f(a[0])} {f(a[1])} Q{f((a[0] + b[0]) / 2)} {f(a[1] + amp * 2.5)} {f(b[0])} {f(b[1])}" stroke="{wire}" stroke-width="0.9" fill="none"/>')
    else:
        o.append(f'<path d="M{f(a[0])} {f(a[1])} L{f(b[0])} {f(b[1])}" stroke="{wire}" stroke-width="{f((4.2 if thick else 1.5) * s)}" stroke-linecap="round"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — hg: close-up of the horn gap fuse on the DTR pole.
# --------------------------------------------------------------------------

HGL, HGR = (88, 112), (112, 112)   # the horns' closest points (the wire's ends)


def hg_stage():
    out = card_open('day')
    out.append(sun())
    out.append(cloud(40, 34, 1.1))
    out.append(pole(100, 0, H, 14))
    out.append(f'<rect x="10" y="160" width="180" height="12" rx="2" fill="url(#chan)"/>')
    for x in (70, 130):
        # brown porcelain post insulator: stacked sheds
        out.append(f'<rect x="{x - 5}" y="122" width="10" height="40" fill="url(#porc)"/>')
        for i, yy in enumerate((128, 138, 148)):
            out.append(f'<ellipse cx="{x}" cy="{yy}" rx="{13 - i}" ry="3.6" fill="url(#porc)"/>')
        out.append(f'<rect x="{x - 7}" y="116" width="14" height="7" rx="2" fill="url(#steel)"/>')
    # The arcing horns (copper rods): up from the caps, in to the close gap,
    # then curving up and out like a V.
    out.append(f'<path d="M70 118 L{HGL[0]} {HGL[1]} Q96 88 82 60 Q70 38 48 22" stroke="{COPPER}" stroke-width="4.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    out.append(f'<path d="M130 118 L{HGR[0]} {HGR[1]} Q104 88 118 60 Q130 38 152 22" stroke="{COPPER}" stroke-width="4.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    # The line: in from the AB switch above-left, out to the DTR below-right.
    out.append(f'<path d="M0 74 Q40 90 64 119" stroke="{WIRE}" stroke-width="2.6" fill="none"/>')
    out.append(f'<path d="M136 119 Q170 140 200 196" stroke="{WIRE}" stroke-width="2.6" fill="none"/>')
    return out


def hg_card(kind):
    out = hg_stage()
    (ax, ay), (bx, by) = HGL, HGR
    if kind == 'taut':
        out.append(f'<path d="M{ax} {ay} L{bx} {by}" stroke="{TIN}" stroke-width="1.8"/>')
        out.append(f'<circle cx="{ax}" cy="{ay}" r="2.4" fill="none" stroke="{TIN}" stroke-width="1.2"/><circle cx="{bx}" cy="{by}" r="2.4" fill="none" stroke="{TIN}" stroke-width="1.2"/>')
    elif kind == 'arc':
        # The wire has melted (two short stubs); the arc has climbed the horns,
        # stretched long and thin, and is dying in the air.
        out.append(f'<path d="M{ax} {ay} l3 3 M{bx} {by} l-3 3" stroke="{TIN}" stroke-width="1.8" stroke-linecap="round"/>')
        out.append(f'<ellipse cx="100" cy="46" rx="34" ry="14" fill="url(#glow)"/>')
        out.append(f'<path d="M66 40 Q78 30 88 42 Q96 52 104 40 Q114 28 122 42 Q128 50 134 40" stroke="{SUN}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
        out.append(f'<path d="M84 84 Q92 74 100 84 Q108 94 116 84" stroke="{SUN}" stroke-width="1.2" fill="none" stroke-opacity="0.6"/>')
        out.append(motion(100, 26, 0, -1, 3, 7))
    elif kind == 'gi':
        # GI binding wire twisted between the horns and wrapped round them.
        d = ' '.join(f'L{f(ax + i * 3)} {f(ay + (1.6 if i % 2 else -1.6))}' for i in range(1, 8))
        out.append(f'<path d="M{ax} {ay} {d} L{bx} {by}" stroke="{GI}" stroke-width="2.2" fill="none" stroke-linejoin="round"/>')
        for x0, s in ((ax, -1), (bx, 1)):
            out.append(f'<path d="M{x0 - 3 * s} {ay - 6} l{6 * s} 3 l{-6 * s} 3 l{6 * s} 3" stroke="{GI}" stroke-width="2" fill="none"/>')
        out.append(f'<path d="M{bx} {by} Q{bx + 14} {by + 18} {bx + 4} {by + 34}" stroke="{GI}" stroke-width="1.6" fill="none"/>')
    elif kind == 'slack':
        out.append(f'<path d="M{ax} {ay} Q100 {ay + 26} {bx} {by}" stroke="{TIN}" stroke-width="1.8" fill="none"/>')
    elif kind == 'alu':
        # A thick ACSR aluminium strand bent between the horns.
        out.append(f'<path d="M{ax - 2} {ay - 3} Q100 {ay + 6} {bx + 2} {by - 3}" stroke="{ALU}" stroke-width="4" fill="none" stroke-linecap="round"/>')
        out.append(f'<path d="M{ax - 2} {ay - 3} Q100 {ay + 6} {bx + 2} {by - 3}" stroke="{INK}" stroke-width="4" stroke-opacity="0.3" stroke-dasharray="1.5 2.5" fill="none"/>')
        out.append(f'<path d="M{bx + 2} {by - 3} Q{bx + 20} {by + 10} {bx + 12} {by + 30}" stroke="{ALU}" stroke-width="3.4" fill="none" stroke-linecap="round"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — rating: the DTR's nameplate and the HG fuse wire reel's tag.
# --------------------------------------------------------------------------

def rating_stage(kva):
    out = card_open('yard')
    out.append(f'<rect x="0" y="180" width="{W}" height="40" fill="url(#ground)"/>')
    out.append(f'<rect x="6" y="28" width="112" height="170" rx="6" fill="url(#tank)"/>')
    for i in range(6):
        out.append(f'<rect x="{12 + i * 18}" y="150" width="8" height="44" rx="2" fill="#5E7766"/>')
    # The nameplate: four screws, engraved lines, the rating in kVA.
    out.append(f'<rect x="18" y="52" width="88" height="78" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    for sx, sy in ((23, 57), (101, 57), (23, 125), (101, 125)):
        out.append(f'<circle cx="{sx}" cy="{sy}" r="1.8" fill="url(#steel)" stroke="{INK}" stroke-width="0.4"/>')
    text = f'{kva} kVA'
    out.append(glyphs(62 - glyph_width(text, 13) / 2, 64, text, 13, INK, 2.2))
    for i in range(4):
        out.append(f'<path d="M28 {92 + i * 8} h{64 - (i % 2) * 18}" stroke="{INK}" stroke-width="1" stroke-opacity="0.6"/>')
    out.append(f'<rect x="56" y="12" width="12" height="18" rx="2" fill="url(#steel)"/>')
    return out


def rating_card(kind):
    kva, tag = {'r25': ('25', '3 A'), 'r63': ('63', '5 A'), 'r100': ('100', '10 A'),
                't25': ('25', '10 A'), 't63': ('63', '10 A'), 'tthick': ('100', None)}[kind]
    out = rating_stage(kva)
    if tag:
        out.append(f'<path d="M140 0 L140 70" stroke="{INK}" stroke-width="1.2"/>')
        out.append(f'<path d="M136 70 q4 6 8 0" stroke="url(#steel)" stroke-width="2" fill="none"/>')
        out.append(reel(140, 96, 1.2, tag))
        out.append(f'<path d="M150 112 Q164 136 156 160 Q148 178 164 192" stroke="{TIN}" stroke-width="1.4" fill="none"/>')
    else:
        # A coil of thick copper conductor, no tag — offered in place of
        # fuse wire.
        out.append(f'<path d="M150 0 L150 70" stroke="{INK}" stroke-width="1.2"/>')
        out.append(f'<path d="M146 70 q4 6 8 0" stroke="url(#steel)" stroke-width="2" fill="none"/>')
        for rx, ry in ((24, 10), (20, 8), (16, 6.5)):
            out.append(f'<ellipse cx="150" cy="{f(98 + ry)}" rx="{rx}" ry="{ry}" fill="none" stroke="{COPPER}" stroke-width="4.5"/>')
        out.append(f'<path d="M150 72 L150 92" stroke="{COPPER}" stroke-width="4.5"/>')
        out.append(f'<path d="M170 112 Q182 140 172 170" stroke="{COPPER}" stroke-width="4.5" fill="none" stroke-linecap="round"/>')
        out.append(f'<rect x="120" y="150" width="20" height="14" rx="2" fill="{BAG}"/>')
        out.append(f'<rect x="124" y="146" width="12" height="18" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — hrc: the LT distribution box on the DTR pole, its door open.
# --------------------------------------------------------------------------

BX, BY = 14, 34          # box top-left
FUSES = (34, 68, 102)    # HRC bases' x


def hrc_stage(on=True, locked=False, dots=(RED, RED, RED)):
    out = card_open('day')
    out.append(cloud(170, 22, 0.9))
    out.append(pole(178, 0, H, 14))
    out.append(f'<rect x="{BX}" y="{BY}" width="124" height="164" rx="4" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<rect x="{BX + 6}" y="{BY + 6}" width="112" height="152" rx="2" fill="url(#panel)"/>')
    out.append(mccb(BX + 34, BY + 12, on, locked))
    # copper busbars behind the fuse row
    out.append(f'<path d="M{BX + 12} {BY + 64} h100" stroke="{COPPER}" stroke-width="3"/>')
    for i, x in enumerate(FUSES):
        out.append(hrc(x, BY + 70, dots[i]))
    out.append(f'<path d="M{BX + 12} {BY + 132} h100" stroke="{WIRE}" stroke-width="3"/>')
    # the open door, swung out to the right (its inside face)
    out.append(f'<path d="M{BX + 124} {BY} L{BX + 150} {BY + 10} L{BX + 150} {BY + 156} L{BX + 124} {BY + 164} Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.8"/>')
    return out


def hrc_card(kind):
    if kind == 'dot':
        # In service, nobody touching: sealed cartridges, every dot showing.
        out = hrc_stage(on=True)
    elif kind == 'iso':
        # The LT switch OFF, padlocked and tagged; the tester reads 0; gloves,
        # goggles and the insulated puller on the middle cartridge.
        out = hrc_stage(on=False, locked=True)
        out.append(tester(BX + 92, BY + 12, '0', 0.75))
        out.append(puller(FUSES[1] + 11, BY + 84, 0))
        out.append(person(150, ((FUSES[1] + 11, BY + 112), (FUSES[1] + 16, BY + 108)), face=-1, look=-8, goggles=True))
    elif kind == 'strip':
        # A blown cartridge thrown away and a copper strip bolted across the
        # empty base; the box live (switch ON).
        out = hrc_stage(on=True, dots=(RED, None, RED))
        out.append(f'<rect x="{FUSES[1] + 6}" y="{BY + 72}" width="10" height="48" rx="1" fill="{COPPER}"/>')
        out.append(f'<circle cx="{FUSES[1] + 11}" cy="{BY + 76}" r="2" fill="url(#steel)"/><circle cx="{FUSES[1] + 11}" cy="{BY + 116}" r="2" fill="url(#steel)"/>')
        out.append(hrc(150, 182, DOT_OFF, 0.6))
    elif kind == 'pliers':
        # Isolated and proven dead, gloves and goggles on — but ordinary pliers.
        out = hrc_stage(on=False, locked=True)
        out.append(tester(BX + 92, BY + 12, '0', 0.75))
        out.append(pliers(FUSES[1] + 11, BY + 82, 0))
        out.append(person(150, ((FUSES[1] + 10, BY + 114), (FUSES[1] + 14, BY + 110)), face=-1, look=-8, goggles=True))
    elif kind == 'live':
        # The switch ON (red window) while the cartridge is pulled: an arc.
        out = hrc_stage(on=True)
        out.append(puller(FUSES[1] + 11, BY + 84, 0))
        out.append(spark(FUSES[1] + 11, BY + 76, 12))
        out.append(person(150, ((FUSES[1] + 11, BY + 112), (FUSES[1] + 16, BY + 108)), face=-1, look=-8, goggles=True))
    elif kind == 'bare':
        # Isolated, tester at 0, the puller — but bare hands and no goggles.
        out = hrc_stage(on=False, locked=True)
        out.append(tester(BX + 92, BY + 12, '0', 0.75))
        out.append(puller(FUSES[1] + 11, BY + 84, 0))
        out.append(person(150, ((FUSES[1] + 11, BY + 112), (FUSES[1] + 16, BY + 108)), face=-1, look=-8, gloves=False))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — gauge: measuring the wire for a 100 A box on the van's tailboard.
# --------------------------------------------------------------------------

def bench_stage():
    out = card_open('bench')
    # the LT box's empty carrier waiting on the bench (100 A job), a reel
    out.append(reel(160, 62, 1.0))
    out.append(kitkat(12, 186, 0.9, stubs=True))
    return out


def gauge_card(kind):
    out = bench_stage()
    if kind == 'slot':
        out.append(gauge_plate(86, 118, 40, '14', -40))
        out.append(arms(((54, 150), (128, 92)), gloves=False, side=1))
    elif kind == 'micro':
        out.append(micrometer(70, 112, '2.00', 1.3))
        out.append(arms(((90, 158), (150, 120)), gloves=False, side=1))
    elif kind == 'thin':
        # Snug in the 25 slot (a thin wire) — and off it goes as "thick".
        out.append(gauge_plate(86, 118, 40, '25', -40))
        out.append(arms(((54, 150), (128, 92)), gloves=False, side=1))
        out.append(motion(150, 74, 1, -1, 3, 8))
    elif kind == 'insul':
        out.append(gauge_plate(86, 118, 40, '14', -40, sheathed=True))
        out.append(arms(((54, 150), (128, 92)), gloves=False, side=1))
    elif kind == 'eye':
        # Two reels side by side, judged by eye; the gauge and the micrometer
        # lie unused.
        out.append(reel(64, 112, 1.2))
        out.append(reel(110, 112, 1.2, wire=TIN))
        out.append(f'<circle cx="150" cy="168" r="18" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(micrometer(28, 160, '0.00', 0.7, wire=None))
        out.append(arms(((88, 92),), gloves=False, side=1))
    elif kind == 'm150':
        # The micrometer reads 1.50 mm — a 63 A wire — and it is carried off
        # for the 100 A box.
        out.append(micrometer(70, 112, '1.50', 1.3))
        out.append(arms(((90, 158), (150, 120)), gloves=False, side=1))
        out.append(motion(26, 72, -1, -1, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — blow: a house short circuit, seen from the lane: the DTR on its
# double pole (AB switch, HG set, tank, LT box) and the house with its meter
# board.
# --------------------------------------------------------------------------

P1, P2 = 26, 92          # the DTR poles
AB_Y, HG_Y, PLAT = 30, 70, 148
PH = (40, 59, 78)        # the three phases' x


def dtr_stage(ab_open=False, hg=(True, True, True), lt_on=True, lt_open=False, dots=(RED, RED, RED),
              win=WIN_LIT, mb_on=True, kit_blown=False):
    out = card_open('day')
    out.append(f'<rect x="0" y="{GY - 8}" width="{W}" height="{H - GY + 8}" fill="url(#ground)"/>')
    # the house and its meter board on the wall
    out.append(f'<rect x="132" y="104" width="64" height="86" fill="url(#house)"/>')
    out.append(f'<path d="M126 105 L164 74 L202 105 Z" fill="url(#roof)"/>')
    out.append(f'<rect x="174" y="116" width="16" height="18" fill="{win}"/>')
    out.append(f'<rect x="138" y="118" width="30" height="34" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<rect x="142" y="122" width="10" height="7" rx="1" fill="{RED if mb_on else GREEN}"/>')
    out.append(f'<rect x="141" y="134" width="24" height="14" rx="2" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.5"/>')
    if kit_blown:
        out.append(f'<path d="M145 141 l5 1 M161 141 l-5 -1" stroke="{TIN}" stroke-width="1.2"/>')
    else:
        out.append(f'<path d="M145 141 L161 141" stroke="{TIN}" stroke-width="1.2"/>')
    out.append(f'<path d="M96 46 Q130 70 152 118" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    # the double pole and the platform
    out.append(pole(P1, 14, GY, 7))
    out.append(pole(P2, 14, GY, 7))
    out.append(f'<rect x="12" y="{AB_Y}" width="94" height="5" rx="1" fill="url(#chan)"/>')
    out.append(f'<rect x="12" y="{HG_Y + 12}" width="94" height="4" rx="1" fill="url(#chan)"/>')
    out.append(f'<rect x="10" y="{PLAT}" width="98" height="5" fill="url(#chan)"/>')
    # line in from the left
    for x in PH:
        out.append(f'<path d="M{x} 0 L{x} {AB_Y - 4}" stroke="{WIRE}" stroke-width="1.2"/>')
    # the AB switch: three blades, closed (lying flat) or open (standing up)
    for x in PH:
        out.append(f'<rect x="{x - 9}" y="{AB_Y - 6}" width="4" height="6" fill="url(#porc)"/><rect x="{x + 5}" y="{AB_Y - 6}" width="4" height="6" fill="url(#porc)"/>')
        if ab_open:
            out.append(f'<path d="M{x - 7} {AB_Y - 7} L{x - 3} {AB_Y - 25}" stroke="url(#steel)" stroke-width="3.2" stroke-linecap="round"/>')
        else:
            out.append(f'<path d="M{x - 8} {AB_Y - 8} L{x + 8} {AB_Y - 8}" stroke="url(#steel)" stroke-width="3.2" stroke-linecap="round"/>')
    # the AB's operating rod down the pole to its handle
    out.append(f'<path d="M{P2 + 5} {AB_Y + 2} L{P2 + 5} 170" stroke="url(#steel)" stroke-width="2"/>')
    out.append(f'<rect x="{P2 + 1}" y="166" width="12" height="5" rx="2" fill="{RED}"/>')
    # drops from the AB to the HG set
    for x in PH:
        out.append(f'<path d="M{x + 7} {AB_Y - 6} Q{x + 9} {HG_Y - 20} {x - 5} {HG_Y + 2}" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    # the HG set: a pair of small copper horns per phase, wire between
    for x, intact in zip(PH, hg):
        out.append(f'<rect x="{x - 6}" y="{HG_Y + 4}" width="3" height="8" fill="url(#porc)"/><rect x="{x + 3}" y="{HG_Y + 4}" width="3" height="8" fill="url(#porc)"/>')
        out.append(f'<path d="M{x - 4.5} {HG_Y + 4} L{x - 1.5} {HG_Y + 1} Q{x - 1} {HG_Y - 6} {x - 7} {HG_Y - 10}" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M{x + 4.5} {HG_Y + 4} L{x + 1.5} {HG_Y + 1} Q{x + 1} {HG_Y - 6} {x + 7} {HG_Y - 10}" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
        if intact:
            out.append(f'<path d="M{x - 1.5} {HG_Y + 1} L{x + 1.5} {HG_Y + 1}" stroke="{TIN}" stroke-width="1.8"/>')
        out.append(f'<path d="M{x + 4.5} {HG_Y + 12} L{x + 2} {HG_Y + 38}" stroke="{WIRE}" stroke-width="1"/>')
    # the tank on the platform
    out.append(f'<rect x="32" y="{HG_Y + 36}" width="54" height="{PLAT - HG_Y - 36}" rx="3" fill="url(#tank)"/>')
    for x in PH:
        out.append(f'<rect x="{x + 1}" y="{HG_Y + 30}" width="4" height="7" fill="url(#porc)"/>')
    # the LT box on the pole below the platform (door open when looked into)
    out.append(f'<rect x="38" y="158" width="44" height="30" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<rect x="42" y="162" width="9" height="6" rx="1" fill="{RED if lt_on else GREEN}"/>')
    if lt_open:
        for i, d in enumerate(dots):
            out.append(f'<rect x="{55 + i * 8}" y="162" width="6" height="22" rx="1" fill="url(#ceramic)"/>')
            out.append(f'<circle cx="{58 + i * 8}" cy="169" r="1.8" fill="{d}"/>')
        out.append(f'<path d="M82 158 L94 162 L94 186 L82 188 Z" fill="url(#panel)"/>')
    else:
        out.append(f'<path d="M56 166 h20 M56 172 h16" stroke="{INK}" stroke-width="0.8"/>')
    return out


def blow_card(kind):
    if kind == 'house':
        # Only the house's own fuse went: its kit-kat wire blown, its main
        # switch OFF, so its window is dark; the HG wires and the LT box are fine.
        out = dtr_stage(mb_on=False, kit_blown=True, win=WIN_OFF)
        out.append(person(126, ((150, 142), (156, 138)), face=1, look=-6))
    elif kind == 'find':
        # One HG wire blew on a house fault: before any re-charge the worker
        # finds the thick wire someone tied in the house's kit-kat.
        out = dtr_stage(hg=(True, False, True), mb_on=False, kit_blown=True, win=WIN_OFF)
        out.append(f'<path d="M128 124 Q134 116 140 122 Q146 128 152 120" stroke="{COPPER}" stroke-width="3.2" fill="none" stroke-linecap="round"/>')
        out.append(person(118, ((130, 124), (150, 142)), face=1, look=-4))
    elif kind == 'iso':
        # HG wire renewal done right: the LT switch OFF, the AB open (all three
        # blades up), proven dead, the earth set on the HG; the lane dark.
        out = dtr_stage(ab_open=True, hg=(True, False, True), lt_on=False, win=WIN_OFF)
        out.append(earth_lead(f'M{PH[0] - 3} {HG_Y + 8} L{PH[2] + 3} {HG_Y + 8} L{P1 - 8} {HG_Y + 20} L{P1 - 8} {GY - 4}', 1.8))
        out.append(f'<path d="M{P1 - 8} {GY - 6} L{P1 - 8} {GY + 10}" stroke="url(#steel)" stroke-width="3"/>')
        out.append(person(66, ((PH[1] - 2, HG_Y + 2), (PH[1] + 2, HG_Y + 6)), face=-1, look=-24, gy=PLAT, s=1.1))
        out.append(tester(96, PLAT - 21, '0', 0.5))
    elif kind == 'recharge':
        # A fresh HG wire and the AB closed again at once — the cause not
        # found: the house's meter board still smokes. The tester he used for
        # the wire job lies at the pole's foot (its last reading, 0): the wire
        # job looked right, the re-charge is the mistake.
        out = dtr_stage(lt_on=False, win=WIN_OFF)
        out.append(smoke(150, 116))
        out.append(tester(4, GY - 22, '0', 0.5))
        out.append(person(116, ((P2 + 6, 168), (P2 + 8, 160)), face=-1, look=-20))
        out.append(motion(P2 + 14, 150, 0, -1, 3, 8))
    elif kind == 'tick':
        # The LT box fuse blew (one dot black) while the house's own MCB
        # stayed ON — and the docket says all is well. The house sits on the
        # blown phase, so its window is dark. Only the coordination mistake:
        # no tester reading at a live box.
        out = dtr_stage(lt_open=True, dots=(RED, DOT_OFF, RED), win=WIN_OFF)
        out.append(person(116, ((110, 150), (106, 144)), face=-1, look=-8))
        out.append(clipboard(94, 132, 0.8))
    elif kind == 'live':
        # The AB still closed (lane lit), no earth on (the set lies coiled on
        # the ground), the worker's hands on the HG wire.
        out = dtr_stage(hg=(True, False, True))
        out.append(earth_coil(130, GY - 2))
        out.append(person(66, ((PH[1] - 2, HG_Y + 2), (PH[1] + 2, HG_Y + 6)), face=-1, look=-24, gy=PLAT, s=1.1))
    return card_close(out)


CARDS = {}
for k in ('taut', 'arc', 'gi', 'slack', 'alu'):
    CARDS[f'hg_{k}'] = hg_card(k)
for k in ('r25', 'r63', 'r100', 't25', 't63', 'tthick'):
    CARDS[f'rating_{k}'] = rating_card(k)
for k in ('dot', 'iso', 'strip', 'pliers', 'live', 'bare'):
    CARDS[f'hrc_{k}'] = hrc_card(k)
for k in ('slot', 'micro', 'thin', 'insul', 'eye', 'm150'):
    CARDS[f'gauge_{k}'] = gauge_card(k)
for k in ('house', 'find', 'iso', 'recharge', 'tick', 'live'):
    CARDS[f'blow_{k}'] = blow_card(k)

# Safe cards and traps per round (mirrors learn_board_pack63.dart).
ROUNDS = {
    'hg': (['hg_taut', 'hg_arc'], ['hg_gi', 'hg_slack', 'hg_alu']),
    'rating': (['rating_r25', 'rating_r63', 'rating_r100'], ['rating_t25', 'rating_t63', 'rating_tthick']),
    'hrc': (['hrc_dot', 'hrc_iso'], ['hrc_strip', 'hrc_pliers', 'hrc_live', 'hrc_bare']),
    'gauge': (['gauge_slot', 'gauge_micro'], ['gauge_thin', 'gauge_insul', 'gauge_eye', 'gauge_m150']),
    'blow': (['blow_house', 'blow_find', 'blow_iso'], ['blow_recharge', 'blow_tick', 'blow_live']),
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
