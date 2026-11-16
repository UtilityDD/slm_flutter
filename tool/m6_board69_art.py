"""Picture cards for lesson 6.9 শেখা ("এলটি ডিস্ট্রিবিউশন পিলার: শেষ প্রবেশদ্বার").

python -I tool/m6_board69_art.py .

Writes assets/game/art/m6_board69/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge; the people,
glyph, tester, padlock, MCCB, HRC and puller helpers are copied from it so
this script stands alone). No words in the art; the only reading drawn is a
tester's, as stroke glyphs with English digits.

What the cards show comes from lesson 6.9 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only. Ruling M6-8: four rounds.
  1. pillar (recap): a fault on one lane darkens only that lane, its own way's
     HRC dot black (point 1); inside, R, Y, B and N bars apart and bolted, the
     neutrals on the common N link, the armour and the body on the earth bar
     (point 2), every way's R, Y, B ferrules on the matching fuses (pro tip
     2) - one inside picture; the door shut and padlocked with children near
     (pro tip 1). Traps: one common fuse blown and every house dark; a neutral
     through a fuse unit with one cable's armour lead hanging free (one
     'wired wrong' picture); the door left open with children near. Six
     cards (owner answers after Wave A: 4-6 a round);
  2. thermal: a gloved, goggled lineman's thermal camera shows a red-white
     spot on a joint that looks normal (pro tip 3); a blackened joint noted on
     the clipboard (point 3). Traps: a bare hand on the joint, water thrown
     from a mug, the hotspot seen and the lineman walking away, a ticked
     clipboard with no camera;
  3. fix: every card shows the DTR LT switch OFF and padlocked at the pole, so
     only the fix differs (ruling X4). Safe: the new top seal pressed on, the
     rat nest lifted out into a bag, the loose lug tightened with the tester
     at 0. Traps: a fourth HRC pushed into the same phase over a pile of blown
     ones, the puddle wiped under a cracked seal, a nest left by a gnawed
     cable;
  4. dead (lesson myth 1, the safety tip, the HRC fact): the DTR LT switch
     OFF with padlock and tag; the tester at 0 on the busbar; a cut-away HRC
     whose quartz sand has swallowed the arc. Traps: a bare hand on a fuse
     with the switch ON, a fuse pulled with the switch ON (an arc), the switch
     OFF but no padlock and the tester lying unused.

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
    print('usage: python -I tool/m6_board69_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board69')
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



# --------------------------------------------------------------------------
# Lesson 6.9: the feeder pillar.
# --------------------------------------------------------------------------

BLUE = '#2F6FD0'        # the B phase sleeve / ferrule
NEUT = '#1C1F24'        # the N bar sleeve, neutral cores (same hex as BOOT)
SAND = '#D9C9A0'        # the pavement; the HRC's quartz sand
WATER = '#5BA7E0'
STRAW = '#9A7650'       # a rat's nest
HOT = '#FF3B1F'         # the camera's hotspot ring
PHASE = (RED, EARTH_Y, BLUE)
PAVE = 178

DEFS = DEFS.replace('<clipPath id="card">',
                    '<linearGradient id="thermal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2A1650"/>'
                    '<stop offset="0.6" stop-color="#3B3FA8"/><stop offset="1" stop-color="#6A2E8C"/></linearGradient>\n'
                    '  <clipPath id="card">')

WAYS = (32, 75, 118)           # outgoing way centres, pillar-local
BAR_Y = (16, 24, 32, 40)       # R, Y, B, N bars


def fuse_x(cx):
    return (cx - 14, cx - 4, cx + 6)


def danger_plate(x, y, s=1.0):
    """The white danger plate with its red bolt (on every pillar door)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(16 * s)}" height="{f(12 * s)}" rx="1.5" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            f'<path d="M{f(x + 9 * s)} {f(y + 1.5 * s)} L{f(x + 5 * s)} {f(y + 6.5 * s)} L{f(x + 9 * s)} {f(y + 6.5 * s)} L{f(x + 6 * s)} {f(y + 10.5 * s)}" '
            f'stroke="{RED}" stroke-width="{f(1.4 * s)}" fill="none" stroke-linejoin="round"/>')


def pillar_open(x, y, s=1.0, nfuse=False, armour_loose=False, tags=False, dots=None, black=False, puddle=False,
                crack=False, nest=False, gnawed=False, seal_new=False, empty=None):
    """The feeder pillar with its door open (box 150 x 150 in local units):
    R, Y, B, N bars bolted across the top, three outgoing ways each with three
    HRC fuses (one per phase), the neutral cores up to the N bar (the common
    neutral link), each cable's armour and the body on the earth bar."""
    dots = dots or {}
    o = [f'<rect x="-4" y="-9" width="158" height="11" rx="3" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>']
    if crack:
        o.append(f'<path d="M0 2 h66 M82 2 h68" stroke="{NEUT}" stroke-width="2.6"/>')
        o.append(f'<path d="M66 -9 l6 6 l-3 4 l7 3" stroke="{INK}" stroke-width="1.2" fill="none"/>')
        for i, dy in enumerate((12, 28, 46)):
            o.append(f'<path d="M{74 + i} {dy} q-2 4 0 6 q2 -2 0 -6" fill="{WATER}"/>')
    else:
        o.append(f'<path d="M0 2 h150" stroke="{NEUT}" stroke-width="{3.4 if seal_new else 2.6}"/>')
    o.append(f'<rect x="0" y="0" width="150" height="150" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    o.append(f'<rect x="6" y="6" width="138" height="138" rx="2" fill="url(#panel)"/>')
    # taps from the bars down to the fuse tops (drawn under the bars)
    for i, cx in enumerate(WAYS):
        for j, fx in enumerate(fuse_x(cx)):
            if empty == (i, j):
                continue
            o.append(f'<path d="M{fx + 4} {BAR_Y[j]} V50" stroke="{COPPER}" stroke-width="1.4"/>')
        if nfuse and i == 1:
            o.append(f'<path d="M{cx + 18} {BAR_Y[3]} V50" stroke="{COPPER}" stroke-width="1.4"/>')
    for yy, col in zip(BAR_Y, (RED, EARTH_Y, BLUE, NEUT)):
        o.append(f'<rect x="10" y="{yy - 2}" width="130" height="4" rx="1" fill="{COPPER}"/>')
        o.append(f'<rect x="10" y="{yy - 2.5}" width="8" height="5" rx="1" fill="{col}"/>')
        for bx in (24, 136):
            o.append(f'<circle cx="{bx}" cy="{yy}" r="1.6" fill="url(#steel)"/>')
    # the ways: fuses, cores to the gland, the neutral up to the N bar, armour
    for i, cx in enumerate(WAYS):
        for j, fx in enumerate(fuse_x(cx)):
            if empty == (i, j):
                o.append(hrc(fx, 50, None, 0.36))
            else:
                o.append(hrc(fx, 50, dots.get((i, j), RED), 0.36))
            o.append(f'<path d="M{fx + 4} 69 Q{fx + 4} 104 {cx - 2 + (j - 1) * 2} 124" stroke="{INK}" stroke-width="2" fill="none"/>')
            if tags:
                o.append(f'<rect x="{fx + 1}" y="74" width="6" height="5" rx="1" fill="{PHASE[j]}"/>')
        if nfuse and i == 1:
            o.append(hrc(cx + 14, 50, RED, 0.36))
            o.append(f'<path d="M{cx + 18} 69 Q{cx + 18} 104 {cx + 3} 124" stroke="{NEUT}" stroke-width="2" fill="none"/>')
        else:
            o.append(f'<path d="M{cx + 18} {BAR_Y[3]} V96 Q{cx + 18} 112 {cx + 3} 124" stroke="{NEUT}" stroke-width="2" fill="none"/>')
            o.append(f'<circle cx="{cx + 18}" cy="{BAR_Y[3]}" r="1.8" fill="url(#steel)"/>')
        o.append(f'<rect x="{cx - 8}" y="124" width="16" height="7" rx="1.5" fill="url(#steel)"/>')
        o.append(f'<rect x="{cx - 6}" y="131" width="12" height="40" fill="{WIRE}"/>')
    # the earth bar: every armour and the body bonded to it
    o.append(f'<rect x="10" y="139" width="130" height="4" rx="1" fill="{BRASS}"/>')
    o.append(earth_lead('M6 118 L12 141', 1.6))
    for i, cx in enumerate(WAYS):
        if armour_loose and i == 2:
            o.append(earth_lead(f'M{cx + 8} 128 q12 4 8 12 q-5 6 3 9', 1.6))
        else:
            o.append(earth_lead(f'M{cx - 8} 128 L{cx - 8} 141', 1.6))
    if black:
        fx = fuse_x(WAYS[0])[0]
        o.append(f'<ellipse cx="{fx + 4}" cy="51" rx="9" ry="6" fill="{NEUT}" opacity="0.9"/>'
                 f'<path d="M{fx - 2} 46 l-4 -8 M{fx + 10} 46 l4 -8" stroke="{NEUT}" stroke-width="1.6"/>')
    if puddle:
        o.append(f'<ellipse cx="75" cy="135" rx="44" ry="4" fill="{WATER}" opacity="0.85"/>')
    if nest:
        o.append(f'<g stroke="{STRAW}" stroke-width="1.6" fill="none" stroke-linecap="round">'
                 f'<path d="M104 118 q8 -8 18 0 M106 114 q10 -6 16 2 M102 120 q12 2 22 -2 M108 112 l10 8 M120 112 l-8 8"/></g>')
    if gnawed:
        cx = WAYS[2]
        o.append(f'<rect x="{cx - 6}" y="148" width="12" height="6" fill="{COPPER}"/>')
        o.append(f'<path d="M{cx - 6} 148 l3 2 l3 -2 l3 2 l3 -2 M{cx - 6} 154 l3 -2 l3 2 l3 -2 l3 2" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    # the open door, swung out to the right, its danger plate
    o.append(f'<path d="M150 0 L172 8 L172 142 L150 150 Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.8"/>')
    o.append(danger_plate(153, 20, 1.0))
    return f'<g transform="translate({f(x)} {f(y)}) scale({s})">' + ''.join(o) + '</g>'


def at(x, y, s, lx, ly):
    """A pillar-local point in card coordinates."""
    return (x + lx * s, y + ly * s)


def pavement():
    return f'<rect x="0" y="{PAVE}" width="{W}" height="{H - PAVE}" fill="{SAND}"/>'


def plinth(x0, x1, top):
    return f'<rect x="{f(x0)}" y="{f(top)}" width="{f(x1 - x0)}" height="{f(PAVE - top + 4)}" fill="url(#chan)"/>'


def kid(x, gy=GY, s=1.0, ball=None):
    """A child at play (red shirt, dark shorts)."""
    o = [f'<path d="M{f(x - 3 * s)} {f(gy - 14 * s)} L{f(x - 4 * s)} {f(gy)} M{f(x + 3 * s)} {f(gy - 14 * s)} L{f(x + 4 * s)} {f(gy)}" '
         f'stroke="{PANTS}" stroke-width="{f(3.6 * s)}" stroke-linecap="round"/>',
         f'<rect x="{f(x - 6 * s)}" y="{f(gy - 30 * s)}" width="{f(12 * s)}" height="{f(17 * s)}" rx="{f(4 * s)}" fill="{RED}"/>',
         f'<path d="M{f(x - 5 * s)} {f(gy - 27 * s)} l{f(-6 * s)} {f(-8 * s)} M{f(x + 5 * s)} {f(gy - 27 * s)} l{f(6 * s)} {f(4 * s)}" '
         f'stroke="{SKIN}" stroke-width="{f(3 * s)}" stroke-linecap="round"/>',
         f'<circle cx="{f(x)}" cy="{f(gy - 36 * s)}" r="{f(6 * s)}" fill="{SKIN}"/>',
         f'<path d="M{f(x - 6 * s)} {f(gy - 37 * s)} A6 6 0 0 1 {f(x + 6 * s)} {f(gy - 37 * s)} Z" fill="{HAIR}"/>']
    if ball:
        o.append(f'<circle cx="{f(ball[0])}" cy="{f(ball[1])}" r="{f(4 * s)}" fill="{HELMET}"/>')
    return ''.join(o)


def toolbag(x, y=GY):
    return (f'<rect x="{f(x)}" y="{f(y - 12)}" width="22" height="12" rx="2" fill="{BAG}"/>'
            f'<path d="M{f(x + 5)} {f(y - 12)} q6 -8 12 0" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')


# --------------------------------------------------------------------------
# Round 1 — pillar: the street (one lane's fault) and the pillar's inside.
# --------------------------------------------------------------------------

HOUSES = (88, 128, 168)


def house(cx, lit=True):
    return (f'<rect x="{cx - 17}" y="142" width="34" height="36" fill="url(#house)"/>'
            f'<path d="M{cx - 21} 144 L{cx} 124 L{cx + 21} 144 Z" fill="url(#roof)"/>'
            f'<rect x="{cx - 11}" y="152" width="12" height="10" rx="1" fill="{WIN_LIT if lit else WIN_OFF}"/>'
            f'<rect x="{cx + 4}" y="150" width="6" height="6" rx="1" fill="{WIN_OFF}"/>'
            f'<rect x="{cx + 3}" y="164" width="9" height="14" fill="{BAG}"/>')


def mini_pillar(x=8, y=110, open_=True, dots=(RED, RED, RED), common=None, locked=False):
    """The pillar seen from the street (52 x 68): door open on its fuse units
    (one per lane, or one common fuse), or shut (padlocked or not)."""
    o = [f'<rect x="{x - 2}" y="{y - 5}" width="56" height="7" rx="2" fill="url(#panel)"/>',
         f'<rect x="{x}" y="{y}" width="52" height="68" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.7"/>']
    if open_:
        o.append(f'<rect x="{x + 4}" y="{y + 4}" width="44" height="60" fill="url(#panel)"/>')
        o.append(f'<rect x="{x + 6}" y="{y + 8}" width="40" height="3" fill="{COPPER}"/>')
        if common is not None:
            o.append(hrc(x + 13, y + 12, common, 0.6))
            o.append(f'<path d="M{x + 26} {y + 43} V{y + 60}" stroke="{INK}" stroke-width="2"/>')
        else:
            for i, d in enumerate(dots):
                o.append(hrc(x + 6 + i * 14, y + 14, d, 0.5))
                o.append(f'<path d="M{x + 11.5 + i * 14} {y + 40} V{y + 60}" stroke="{INK}" stroke-width="2"/>')
        o.append(f'<path d="M{x + 52} {y} L{x + 64} {y + 6} L{x + 64} {y + 62} L{x + 52} {y + 68} Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
        o.append(danger_plate(x + 53, y + 14, 0.6))
    else:
        o.append(f'<path d="M{x + 26} {y + 2} V{y + 66}" stroke="{INK}" stroke-width="0.6"/>')
        o.append(danger_plate(x + 18, y + 12, 1.0))
        o.append(f'<rect x="{x + 29}" y="{y + 34}" width="3" height="10" rx="1" fill="url(#steel)"/>')
        if locked:
            o.append(padlock(x + 36, y + 40))
    return ''.join(o)


def street_stage(lit=(True, True, True)):
    out = card_open('day')
    out.append(sun(150, 28))
    out.append(cloud(60, 30, 0.9))
    out.append(pavement())
    for cx, l in zip(HOUSES, lit):
        out.append(house(cx, l))
    # the three lanes' cables under the pavement
    for i, cx in enumerate(HOUSES):
        yy = 186 + i * 7
        out.append(f'<path d="M{20 + i * 13} {PAVE} V{yy} H{cx - 6} V{PAVE}" stroke="{WIRE}" stroke-width="1.6" stroke-dasharray="4 3" fill="none"/>')
    return out


def inside_stage(**kw):
    out = card_open('day')
    out.append(sun(150, 28))
    out.append(pavement())
    out.append(plinth(14, 172, 176))
    out.append(pillar_open(16, 26, 1.0, **kw))
    return out


def pillar_card(kind):
    if kind == 'lane':
        # A fault on the middle lane: only its own way's HRC went (black dot);
        # that lane is dark, the other two lit.
        out = street_stage(lit=(True, False, True))
        out.append(mini_pillar(dots=(RED, NEUT, RED)))
        out.append(spark(HOUSES[1] - 18, 193, 9))
        out.append(person(188, ((176, 160), (180, 166)), face=-1, look=-6))
    elif kind == 'alldark':
        # One common fuse for all three lanes: the fault on the middle lane
        # blew it, and every house is dark.
        out = street_stage(lit=(False, False, False))
        out.append(mini_pillar(common=NEUT))
        out.append(spark(HOUSES[1] - 18, 193, 9))
        out.append(person(188, ((176, 160), (180, 166)), face=-1, look=-6))
    elif kind == 'locked':
        # Work done: the door shut and padlocked; children play near it, the
        # lineman walks off with his bag.
        out = street_stage()
        out.append(mini_pillar(open_=False, locked=True))
        out.append(kid(70, GY, 1.0, ball=(84, GY - 4)))
        out.append(person(176, ((182, 168), (170, 170)), face=1, look=0))
        out.append(toolbag(184, GY))
    elif kind == 'door':
        # Work done, the door left wide open on the live fuses, children near.
        out = street_stage()
        out.append(mini_pillar())
        out.append(kid(78, GY, 1.0, ball=(64, GY - 30)))
        out.append(person(176, ((182, 168), (170, 170)), face=1, look=0))
        out.append(toolbag(184, GY))
    elif kind == 'inside':
        # Bars apart, neutrals on the N link, armour on the earth bar, and
        # every way's R, Y and B ferrules on the R, Y and B fuses (pro tip 2).
        out = inside_stage(tags=True)
    elif kind == 'wiring':
        # Wired wrong: the middle way's neutral taken through a fourth fuse
        # unit, and the right-hand cable's armour lead hanging off the earth bar.
        out = inside_stage(nfuse=True, armour_loose=True)
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 2-4 share one view: the open pillar on its plinth, right of centre.
# --------------------------------------------------------------------------

PX, PY, PS = 78, 88, 0.6


def P(lx, ly):
    return at(PX, PY, PS, lx, ly)


JOINT = P(fuse_x(WAYS[0])[0] + 4, 51)       # way 1, R fuse's top contact
LUG = P(WAYS[0] - 2, 126)                    # way 1's cable lug at the gland


def side_stage(**kw):
    out = card_open('day')
    out.append(sun(150, 26))
    out.append(cloud(40, 28, 0.8))
    out.append(pavement())
    out.append(plinth(PX - 2, PX + 152 * PS, PY + 150 * PS))
    out.append(pillar_open(PX, PY, PS, **kw))
    return out


def thermal_cam(x, y, hot=True):
    """A thermal camera (black body, false-colour screen, lens); the screen
    shows the red-white hotspot."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="30" height="24" rx="3" fill="{WIRE}"/>',
         f'<rect x="{f(x + 3)}" y="{f(y + 3)}" width="24" height="17" rx="1.5" fill="url(#thermal)"/>',
         f'<rect x="{f(x + 12)}" y="{f(y + 24)}" width="7" height="12" rx="2" fill="{WIRE}"/>']
    if hot:
        o.append(f'<circle cx="{f(x + 11)}" cy="{f(y + 10)}" r="4.4" fill="{HOT}"/>')
        o.append(f'<circle cx="{f(x + 11)}" cy="{f(y + 10)}" r="1.9" fill="#FFFFFF"/>')
    return ''.join(o)


def thermal_card(kind):
    jx, jy = JOINT
    if kind == 'scan':
        # Gloves and goggles on; the camera finds the hotspot on a joint that
        # looks normal to the eye.
        out = side_stage()
        out.append(person(42, ((62, 138), (68, 134)), face=1, look=-4, goggles=True))
        out.append(thermal_cam(56, 112))
    elif kind == 'black':
        # A blackened joint noted on the clipboard for tightening.
        out = side_stage(black=True)
        out.append(person(42, ((58, 146), (66, 140)), face=1, look=-6, goggles=True))
        out.append(clipboard(52, 128, 0.8, tick=False))
    elif kind == 'touch':
        # A bare hand on the joint to feel if it is hot.
        out = side_stage()
        out.append(person(52, ((jx, jy + 2), (70, 150)), face=1, look=-10, gloves=False, goggles=True))
        out.append(thermal_cam(4, 170))
    elif kind == 'water':
        # Water thrown from a mug on the hot joint: a flash.
        out = side_stage()
        out.append(person(46, ((66, 128), (60, 136)), face=1, look=-8, goggles=True))
        out.append(f'<path d="M62 122 h10 l-2 12 h-6 Z" fill="url(#steel)"/>')
        for i in range(4):
            out.append(f'<circle cx="{f(74 + i * 5)}" cy="{f(120 - i * 2)}" r="1.8" fill="{WATER}"/>')
        out.append(spark(jx, jy, 10))
    elif kind == 'wait':
        # The camera showed the hotspot; the lineman walks away from it.
        out = side_stage()
        out.append(person(30, ((22, 150), (18, 146)), face=-1, look=0, goggles=True))
        out.append(thermal_cam(4, 130))
        out.append(motion(50, 150, 1, 0, 3, 8))
    elif kind == 'eye':
        # No camera: everything looks fine to the eye, the clipboard ticked.
        out = side_stage()
        out.append(person(42, ((58, 146), (66, 140)), face=1, look=-6, goggles=True))
        out.append(clipboard(52, 128, 0.8, tick=True))
    out.append(toolbag(170, GY))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — fix: the DTR LT switch OFF and padlocked on every card.
# --------------------------------------------------------------------------

def lt_inset(on=False, locked=True):
    """The DTR's LT switch (MCCB) on its pole at the left edge, scaled."""
    return (pole(10, 0, PAVE, 10)
            + f'<g transform="translate(2 34) scale(0.62)">{mccb(0, 0, on, locked)}</g>')


def spanner(x, y, ang=-30):
    """An insulated spanner (steel head, yellow grip) — its jaws at (x, y)."""
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<path d="M{f(x - 4)} {f(y - 3)} a5 5 0 1 1 8 0" stroke="url(#steel)" stroke-width="3" fill="none"/>'
            f'<rect x="{f(x - 2)}" y="{f(y + 2)}" width="4" height="8" fill="url(#steel)"/>'
            f'<rect x="{f(x - 3)}" y="{f(y + 10)}" width="6" height="18" rx="2" fill="{HELMET_D}"/></g>')


def fix_stage(**kw):
    out = side_stage(**kw)
    out.append(lt_inset())
    out.append(toolbag(30, GY))
    return out


def fix_card(kind):
    if kind == 'seal':
        # A new top seal pressed on along the roof; the inside is dry.
        out = fix_stage(seal_new=True)
        rx, ry = P(40, 0)
        out.append(person(56, ((rx, ry + 2), (rx + 14, ry + 4)), face=1, look=-14))
        out.append(motion(rx + 30, ry - 6, 1, 0, 3, 8))
        for i in range(4):
            out.append(f'<path d="M{24 + i * 9} {44 + (i % 2) * 8} l-2 5" stroke="{WATER}" stroke-width="1.4"/>')
    elif kind == 'nest':
        # The rat nest lifted out of the box into a bag; the inside clean.
        out = fix_stage()
        out.append(f'<g stroke="{STRAW}" stroke-width="1.8" fill="none" stroke-linecap="round">'
                   '<path d="M60 150 q8 -8 18 0 M62 146 q10 -6 16 2 M58 152 q12 2 22 -2 M64 144 l10 8"/></g>')
        out.append(person(46, ((62, 152), (76, 150)), face=1, look=-8))
        out.append(f'<rect x="62" y="166" width="22" height="16" rx="3" fill="{SMOKE}"/>')
    elif kind == 'lug':
        # The tester read 0; the loose lug tightened with an insulated spanner.
        out = fix_stage()
        lx, ly = LUG
        out.append(tester(40, 160, '0', 0.6))
        out.append(spanner(lx, ly, -30))
        out.append(person(56, ((lx - 6, ly + 14), (lx - 10, ly + 18)), face=1, look=-10))
    elif kind == 'fuse3':
        # Three blown cartridges on the ground, and a fourth pushed into the
        # same R slot again — the load never balanced.
        out = fix_stage(empty=(0, 0))
        out.append(tester(40, 160, '0', 0.6))
        jx, jy = JOINT
        out.append(hrc(jx - 4, jy - 4, RED, 0.36))
        for i in range(3):
            out.append(hrc(66 + i * 10, 186, NEUT, 0.36))
        out.append(person(56, ((jx - 2, jy + 10), (jx - 6, jy + 14)), face=1, look=-10))
    elif kind == 'wipe':
        # The puddle wiped with a rag while the cracked seal still lets rain in.
        out = fix_stage(crack=True, puddle=True)
        px, py = P(60, 134)
        out.append(f'<rect x="{f(px - 6)}" y="{f(py - 4)}" width="12" height="6" rx="2" fill="{PAPER}"/>')
        out.append(person(56, ((px, py), (px - 6, py + 4)), face=1, look=-12))
    elif kind == 'gnaw':
        # A rat's nest left beside a gnawed cable; the rat still there.
        out = fix_stage(nest=True, gnawed=True)
        out.append(f'<ellipse cx="160" cy="174" rx="8" ry="4" fill="{SMOKE}"/><circle cx="168" cy="172" r="3" fill="{SMOKE}"/>'
                   f'<path d="M152 175 q-8 2 -10 -4" stroke="{SMOKE}" stroke-width="1.2" fill="none"/>')
        out.append(person(46, ((58, 150), (64, 146)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — dead: the DTR's LT switch on its pole, the pillar beside it.
# --------------------------------------------------------------------------

def dead_stage(on=True, locked=False):
    out = side_stage()
    out.append(pole(28, 0, PAVE, 12))
    out.append(mccb(6, 52, on, locked))
    out.append(f'<path d="M30 88 V172 H{PX + 10}" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    return out


def dead_card(kind):
    jx, jy = JOINT
    if kind == 'lock':
        # The LT switch OFF; the padlock and tag going on.
        out = dead_stage(on=False, locked=True)
        out.append(person(58, ((36, 96), (40, 100)), face=-1, look=-12))
    elif kind == 'test':
        # Locked off; the tester on the busbar reads 0.
        out = dead_stage(on=False, locked=True)
        bx, by = P(60, BAR_Y[0])
        out.append(f'<path d="M{f(bx)} {f(by)} Q{f(bx - 20)} {f(by + 30)} 78 150" stroke="{RED}" stroke-width="1.2" fill="none"/>')
        out.append(f'<path d="M{f(bx + 10)} {f(P(0, BAR_Y[3])[1])} Q{f(bx - 10)} {f(by + 40)} 82 150" stroke="{NEUT}" stroke-width="1.2" fill="none"/>')
        out.append(tester(64, 146, '0', 0.7))
        out.append(person(52, ((70, 160), (bx, by + 2)), face=1, look=-10, goggles=True))
    elif kind == 'sand':
        # The blown HRC cut open: quartz sand packed round the melted element
        # swallowed the arc (a faint glow dying inside).
        out = dead_stage(on=True)
        cx, top = 132, 62
        out.append(f'<rect x="{cx - 22}" y="{top}" width="44" height="104" rx="6" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<rect x="{cx - 26}" y="{top - 6}" width="52" height="12" rx="3" fill="url(#steel)"/>')
        out.append(f'<rect x="{cx - 26}" y="{top + 98}" width="52" height="12" rx="3" fill="url(#steel)"/>')
        out.append(f'<rect x="{cx - 15}" y="{top + 12}" width="30" height="80" rx="3" fill="{SAND}" stroke="{INK}" stroke-width="0.6"/>')
        for i in range(36):
            sx = cx - 12 + (i * 7) % 25
            sy = top + 16 + (i * 13) % 72
            out.append(f'<circle cx="{sx}" cy="{sy}" r="0.9" fill="{INK}"/>')
        out.append(f'<path d="M{cx} {top + 12} l-4 6 l8 6 l-8 6 l4 6 M{cx} {top + 92} l4 -6 l-8 -6 l8 -6 l-4 -6" stroke="{COPPER}" stroke-width="2" fill="none"/>')
        out.append(f'<circle cx="{cx}" cy="{top + 52}" r="9" fill="url(#glow)"/>')
        out.append(f'<circle cx="{cx}" cy="{top + 52}" r="1.4" fill="{SUN}"/>')
    elif kind == 'bare':
        # The LT switch ON; a bare hand on a fuse ("only 415 V").
        out = dead_stage(on=True)
        out.append(person(56, ((jx, jy + 4), (70, 150)), face=1, look=-10, gloves=False))
    elif kind == 'livepull':
        # The LT switch ON; the cartridge pulled with the puller: an arc.
        out = dead_stage(on=True)
        out.append(puller(jx, jy + 6, 0))
        out.append(spark(jx, jy, 11))
        out.append(person(56, ((jx, jy + 32), (jx - 4, jy + 36)), face=1, look=-10, goggles=True))
    elif kind == 'nolock':
        # The LT switch OFF but no padlock or tag; the tester lies unused.
        out = dead_stage(on=False, locked=False)
        out.append(tester(36, 182, '', 0.5))
        out.append(person(56, ((jx, jy + 4), (70, 150)), face=1, look=-10))
    return card_close(out)


CARDS = {}
for k in ('lane', 'inside', 'locked', 'alldark', 'wiring', 'door'):
    CARDS[f'pillar_{k}'] = pillar_card(k)
for k in ('scan', 'black', 'touch', 'water', 'wait', 'eye'):
    CARDS[f'thermal_{k}'] = thermal_card(k)
for k in ('seal', 'nest', 'lug', 'fuse3', 'wipe', 'gnaw'):
    CARDS[f'fix_{k}'] = fix_card(k)
for k in ('lock', 'test', 'sand', 'bare', 'livepull', 'nolock'):
    CARDS[f'dead_{k}'] = dead_card(k)

# Safe cards and traps per round (mirrors learn_board_pack69.dart).
ROUNDS = {
    'pillar': (['pillar_lane', 'pillar_inside', 'pillar_locked'],
               ['pillar_alldark', 'pillar_wiring', 'pillar_door']),
    'thermal': (['thermal_scan', 'thermal_black'], ['thermal_touch', 'thermal_water', 'thermal_wait', 'thermal_eye']),
    'fix': (['fix_seal', 'fix_nest', 'fix_lug'], ['fix_fuse3', 'fix_wipe', 'fix_gnaw']),
    'dead': (['dead_lock', 'dead_test', 'dead_sand'], ['dead_bare', 'dead_livepull', 'dead_nolock']),
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
