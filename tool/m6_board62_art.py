"""Picture cards for lesson 6.2 শেখা ("সার্কিট ব্রেকার: চূড়ান্ত রক্ষাকর্তা").

python -I tool/m6_board62_art.py .

Writes assets/game/art/m6_board62/*.svg in the clean gradient style of
tool/m5_board55_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: lamps, the spring flag (a tight or a loose coil), the IEC I / O
marks and the racking position pointer are drawn; the operation counter is
seven-segment English digits, as a real counter shows it.

What the cards show comes from lesson 6.2 (and the Module 6 rulings) only:
  1. reset: the breakers (a VCB panel on its trolley, an OCB panel with its
     oil tank) against a blown fuse, an open isolator (off-load only, ruling
     X3), a relay panel on its own and an ordinary switch;
  2. vcb: three sealed vacuum bottles on the trolley, and a vacuum bottle cut
     open with its contacts parted and only a fading wisp of arc; against the
     OCB's contacts in an oil tank, the OCB cut-away with the arc boiling a gas
     bubble, and a fuse carrier with a melted link;
  3. lamp: the panel of an OFF breaker (green lit, red dark) with the spring
     charged or discharged; against red lit (with or without TRIP CIRCUIT
     HEALTHY or SPRING CHARGED lit). Five rounds, as the Module 5 boards
     (ruling M5-11): the spring round left the board (owner 2026-11-15);
  4. rack: hands-on work with the trolley racked out (ISOLATED, the cubicle's
     shutters closed, both lamps dark; on the second safe card the trolley's
     cover is open); against work in SERVICE, in TEST
     (half in, control still live: the green lamp lit) and in SERVICE with the
     green lamp lit while the cover is opened;
  5. line: after a trip, the isolators open at both ends (from the ground,
     the tester in hand, the earth set still coiled); the line proved dead
     with the tester, then earths on all three phases and only then the climb
     (ruling X1: the tester leans by the pole, used); against climbing on
     green alone, the far end tied to another live feeder (near end opened
     from the ground), one end open with no earth (about to climb), and a
     hand reaching for an unearthed conductor. The worker is on the ground on
     one safe card and two traps, up the pole on one safe card and two traps.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too; and the other way round, nothing (a colour, a pose
marker class="pose-stand" / "pose-climb", the class="earth-coil" set) is on
every trap of a hand and missing from its safe card, except what the lesson
itself says through colour (LESSON_STATE: red lit / green dark on the lamp
round's ON traps). Lamp colours (lit and dark) are on every panel card,
because the relay's own LEDs (healthy lit, trip dark) are always drawn. It
deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board62_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board62')
W, H = 200, 220
GY = 198

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
INK = '#4A5560'
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
MOVE = '#FFFFFF'
EARTHW = '#3E9B4F'
EARTH_Y = '#E8C830'
LADDER = '#B9851A'

R_ON = '#FF4B3A'     # red lamp lit (ON)
R_OFF = '#5E2622'
G_ON = '#45E06E'     # green lamp lit (OFF / tripped)
G_OFF = '#1E4A2C'
A_ON = '#FFC233'     # spring charged lamp lit; the torch's warm lens
A_OFF = '#5E4A1C'
W_ON = '#FFF6D6'     # trip circuit healthy lamp lit
W_OFF = '#6D6A60'
RELAY = '#2E3640'
VAC = '#1A2434'      # vacuum / dark interior
ARC = '#BFE4FF'
COPPER = '#C8783A'
SCORCH = '#3A2A20'
TESTER = '#D8402F'   # the HV tester's red head

DEFS = """<defs>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D2CE"/><stop offset="1" stop-color="#A9B4AF"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E918B"/><stop offset="1" stop-color="#6C6F69"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#DCE2DA"/><stop offset="1" stop-color="#AEB8AF"/></linearGradient>
  <linearGradient id="panelD" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8F9A92"/><stop offset="1" stop-color="#6E7972"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#F6F1E6"/><stop offset="0.5" stop-color="#E4DCCB"/><stop offset="1" stop-color="#C2B9A6"/></linearGradient>
  <linearGradient id="oil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E7B95A"/><stop offset="1" stop-color="#B88426"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
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
# The lineman (as tool/m5_board55_art.py).
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


def figure(hip, sh, head, feet, hands, face=1, look=0):
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
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{GLOVE}"/>')
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
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, 'url(#shirt)', 5.4))
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{GLOVE}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, s=S):
    """A standing lineman at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look)
    return f'<g class="pose-stand" transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def climber(x, gy, hands_world, face=1, look=-20, s=1.1):
    """A lineman on the pole: feet one above the other on its steps."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x - 4 * face, gy - 28)
    sh = (x - 3 * face, gy - 54)
    head = (x, gy - 62)
    feet = ((x - 2 * face, gy + 2), (x + 1 * face, gy - 14))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look)
    return f'<g class="pose-climb" transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}


def digits(x, y, text, h=10.0, color=INK):
    """English digits drawn as seven-segment strokes; (x, y) = top left."""
    k = h / 10
    o = []
    for i, ch in enumerate(text):
        ox = x + i * 7.8 * k
        for s in _DIG[ch]:
            x0, y0, x1, y1 = _SEG[s]
            o.append(f'M{f(ox + x0 * k)} {f(y + y0 * k)} L{f(ox + x1 * k)} {f(y + y1 * k)}')
    return f'<path d="{" ".join(o)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" fill="none"/>'


def lamp(x, y, col, lit, r=8.0):
    """An indicator lamp: steel bezel, coloured lens; a lit lamp throws short
    white rays."""
    o = [f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r + 2.2)}" fill="url(#steel)"/>',
         f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{col}"/>',
         f'<circle cx="{f(x - r * 0.35)}" cy="{f(y - r * 0.35)}" r="{f(r * 0.28)}" fill="{PAPER}" opacity="0.7"/>']
    if lit:
        rays = []
        for k in range(8):
            a = k * math.pi / 4 + math.pi / 8
            rays.append(f'M{f(x + math.cos(a) * (r + 4))} {f(y + math.sin(a) * (r + 4))} '
                        f'L{f(x + math.cos(a) * (r + 7.5))} {f(y + math.sin(a) * (r + 7.5))}')
        o.append(f'<path d="{" ".join(rays)}" stroke="{MOVE}" stroke-width="1.4" stroke-linecap="round" opacity="0.9"/>')
    return ''.join(o)


def plate(x, y, mark, w=14.0, h=9.0):
    """A small label plate under a lamp with a drawn mark: 'I' (ON), 'O'
    (OFF), 'spring' (a zigzag) or 'coil' (a trip coil loop)."""
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="1.5" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>']
    cx, cy = x, y + h / 2
    if mark == 'I':
        o.append(f'<path d="M{f(cx)} {f(cy - 2.8)} L{f(cx)} {f(cy + 2.8)}" stroke="{INK}" stroke-width="1.3"/>')
    elif mark == 'O':
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="2.6" fill="none" stroke="{INK}" stroke-width="1.2"/>')
    elif mark == 'spring':
        o.append(f'<path d="M{f(cx - 5)} {f(cy)} l1.5 -2.5 l2 5 l2 -5 l2 5 l2 -5 l1.5 2.5" stroke="{INK}" stroke-width="0.9" fill="none"/>')
    elif mark == 'coil':
        o.append(f'<path d="M{f(cx - 5)} {f(cy)} h2 m6 0 h2" stroke="{INK}" stroke-width="0.9"/>'
                 f'<rect x="{f(cx - 3)}" y="{f(cy - 2.4)}" width="6" height="4.8" fill="none" stroke="{INK}" stroke-width="0.9"/>')
    return ''.join(o)


def spring_coil(x, y, w, h, charged):
    """The spring drawn in its flag window: [charged] = a tight, compressed
    coil with its latch closed; else a loose, stretched coil."""
    turns = 9 if charged else 4
    span = w * (0.45 if charged else 0.9)
    x0 = x + (w - span) / 2 if not charged else x + w * 0.1
    pts = [f'M{f(x0)} {f(y + h / 2)}']
    step = span / (turns * 2)
    for i in range(turns * 2):
        yy = y + h * (0.18 if i % 2 == 0 else 0.82)
        pts.append(f'L{f(x0 + step * (i + 1))} {f(yy)}')
    o = [f'<path d="{" ".join(pts)}" stroke="{INK}" stroke-width="{f(max(1.0, h / 14))}" fill="none" stroke-linejoin="round"/>']
    end = x0 + span
    o.append(f'<rect x="{f(end)}" y="{f(y + h * 0.15)}" width="{f(w * 0.06)}" height="{f(h * 0.7)}" fill="{INK}"/>')
    return ''.join(o)


def relay_box(x, y, w=44, h=24, leds=((G_ON, True), (R_OFF, False))):
    """A protection relay: dark case, lcd window and its LEDs (healthy lit,
    trip dark on a normal day)."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{RELAY}"/>',
         f'<rect x="{f(x + 3)}" y="{f(y + 3)}" width="{f(w * 0.55)}" height="{f(h * 0.45)}" rx="1" fill="url(#lcd)"/>']
    for i, (col, lit) in enumerate(leds):
        cx = x + w * 0.72 + i * w * 0.13
        o.append(f'<circle cx="{f(cx)}" cy="{f(y + h * 0.3)}" r="{f(h * 0.09)}" fill="{col}"/>')
        if lit:
            o.append(f'<circle cx="{f(cx)}" cy="{f(y + h * 0.3)}" r="{f(h * 0.16)}" fill="none" stroke="{MOVE}" stroke-width="0.6" opacity="0.8"/>')
    for i in range(3):
        o.append(f'<rect x="{f(x + 4 + i * 7)}" y="{f(y + h * 0.68)}" width="5" height="{f(h * 0.18)}" rx="1" fill="url(#steel)"/>')
    return ''.join(o)


def spanner(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x)}" y="{f(y - 2.2)}" width="22" height="4.4" rx="1.6" fill="url(#steel)"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} L{f(x + 4)} {f(y - 6)} L{f(x + 4)} {f(y - 2)} L{f(x + 1)} {f(y - 2)} L{f(x + 1)} {f(y + 2)} '
            f'L{f(x + 4)} {f(y + 2)} L{f(x + 4)} {f(y + 6)} L{f(x - 2)} {f(y + 6)} Z" fill="url(#steel)"/></g>')


def motion(x, y, dx=0, dy=1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def earth_lead(d, w=2.6):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{EARTHW}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """A portable earth set lying coiled on the ground, unused."""
    o = ['<g class="earth-coil">']
    for rx, ry in ((14, 5), (11, 4), (8, 3)):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0'))
    for dx in (-20, 18, 24):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="7" rx="1.5" fill="url(#steel)"/>')
    o.append('</g>')
    return ''.join(o)


def hv_tester(x0, y0, x1, y1):
    """The HV tester on its insulated stick: yellow stick, red head with a
    dark (no voltage) lamp at the tip end [x1, y1]."""
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{HELMET_D}" stroke-width="3" stroke-linecap="round"/>'
            f'<g transform="rotate({f(ang)} {f(x1)} {f(y1)})">'
            f'<rect x="{f(x1)}" y="{f(y1 - 4)}" width="14" height="8" rx="2.5" fill="{TESTER}"/>'
            f'<circle cx="{f(x1 + 9)}" cy="{f(y1)}" r="2" fill="{W_OFF}"/>'
            f'<path d="M{f(x1 + 14)} {f(y1)} l5 0" stroke="url(#steel)" stroke-width="1.6"/></g>')


def tool_bag(x, y):
    return (f'<rect x="{f(x - 11)}" y="{f(y)}" width="22" height="14" rx="3" fill="{BAG}"/>'
            f'<path d="M{f(x - 6)} {f(y)} q6 -7 12 0" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')


def pole(x, top, gy=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(gy - top)}" fill="url(#pole)"/>'


def insulator(x, y, h=10, w=6):
    """A porcelain post insulator standing on (x, y)."""
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y - h)}" width="{f(w)}" height="{f(h)}" rx="1.5" fill="url(#porcelain)"/>']
    for i in range(1, 3):
        yy = y - h * i / 3
        o.append(f'<rect x="{f(x - w / 2 - 1.5)}" y="{f(yy - 1)}" width="{f(w + 3)}" height="2" rx="1" fill="url(#porcelain)"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — reset: the switch room; the thing in front.
# --------------------------------------------------------------------------

def room_stage(back_row=True):
    out = card_open('room')
    out.append(f'<rect y="150" width="{W}" height="{H - 150}" fill="url(#floor)"/>')
    if back_row:
        # A row of panels along the back wall, pushed back (faded).
        g = []
        for i in range(6):
            x = 4 + i * 33
            g.append(f'<rect x="{x}" y="34" width="30" height="116" fill="url(#panel)"/>')
            g.append(relay_box(x + 4, 40, 22, 12))
            on = i % 2 == 0
            g.append(f'<circle cx="{x + 9}" cy="64" r="2.4" fill="{R_ON if on else R_OFF}"/>')
            g.append(f'<circle cx="{x + 17}" cy="64" r="2.4" fill="{G_OFF if on else G_ON}"/>')
            g.append(f'<circle cx="{x + 24}" cy="64" r="1.6" fill="{A_ON if i % 3 == 0 else A_OFF}"/>')
            g.append(f'<rect x="{x + 4}" y="84" width="22" height="60" rx="1" fill="none" stroke="{INK}" stroke-width="0.6"/>')
            g.append(f'<rect x="{x + 8}" y="72" width="14" height="5" rx="1" fill="{PAPER}"/>')
            g.append(f'<rect x="{x + 9}" y="92" width="12" height="16" rx="1" fill="{VAC}"/>')
        out.append('<g opacity="0.55">' + ''.join(g) + '</g>')
    return out


def cabinet(x, y, w, h, side=10):
    """A switchgear cubicle front with its side face."""
    return (f'<path d="M{f(x + w)} {f(y)} l{f(side)} {f(-side * 0.6)} L{f(x + w + side)} {f(y + h - side * 0.6)} L{f(x + w)} {f(y + h)} Z" fill="url(#panelD)"/>'
            f'<path d="M{f(x)} {f(y)} l{f(side)} {f(-side * 0.6)} L{f(x + w + side)} {f(y - side * 0.6)} L{f(x + w)} {f(y)} Z" fill="url(#panelD)" opacity="0.8"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')


def wheels(x0, x1, y, r=5):
    return ''.join(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill="{WIRE}"/><circle cx="{f(x)}" cy="{f(y)}" r="1.6" fill="url(#steel)"/>'
                   for x in (x0, x1))


def bottle(x, y, h=26, w=11):
    """A sealed vacuum interrupter (bottle) standing on (x, y)."""
    return (f'<rect x="{f(x - w / 2)}" y="{f(y - h)}" width="{f(w)}" height="{f(h)}" rx="3" fill="url(#porcelain)"/>'
            f'<rect x="{f(x - w / 2 - 1)}" y="{f(y - h - 3)}" width="{f(w + 2)}" height="4" rx="1" fill="url(#steel)"/>'
            f'<rect x="{f(x - w / 2 - 1)}" y="{f(y - 2)}" width="{f(w + 2)}" height="4" rx="1" fill="url(#steel)"/>')


def reset_card(kind):
    out = room_stage()
    if kind == 'vcb':
        out.append(cabinet(52, 40, 92, 160))
        out.append(relay_box(62, 48, 46, 24))
        out.append(lamp(72, 90, R_ON, True, 6) + plate(72, 100, 'I'))
        out.append(lamp(96, 90, G_OFF, False, 6) + plate(96, 100, 'O'))
        out.append(f'<circle cx="124" cy="92" r="6" fill="url(#steel)"/><rect x="122" y="83" width="4" height="12" rx="2" fill="{WIRE}"/>')
        # Lower compartment: the trolley on its wheels, its three bottles on top.
        out.append(f'<rect x="58" y="120" width="80" height="76" fill="{VAC}"/>')
        for bx in (78, 98, 118):
            out.append(bottle(bx, 150, 22, 10))
        out.append(f'<rect x="62" y="150" width="72" height="36" rx="2" fill="url(#panel)" stroke="{INK}" stroke-width="0.5"/>')
        out.append(f'<rect x="88" y="160" width="20" height="5" rx="2" fill="url(#steel)"/>')
        out.append(wheels(72, 124, 190))
    elif kind == 'ocb':
        out.append(cabinet(52, 40, 92, 104))
        out.append(relay_box(62, 48, 46, 24))
        out.append(lamp(72, 90, R_OFF, False, 6) + plate(72, 100, 'I'))
        out.append(lamp(96, 90, G_ON, True, 6) + plate(96, 100, 'O'))
        out.append(f'<circle cx="124" cy="92" r="6" fill="url(#steel)"/><rect x="122" y="83" width="4" height="12" rx="2" fill="{WIRE}"/>')
        # The oil tank hanging under the mechanism, with its oil sight glass.
        for bx in (74, 98, 122):
            out.append(insulator(bx, 152, 10, 6))
        out.append(f'<path d="M60 150 L136 150 L136 186 Q136 198 124 198 L72 198 Q60 198 60 186 Z" fill="url(#panelD)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="92" y="160" width="12" height="26" rx="3" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="93.5" y="170" width="9" height="15" rx="2" fill="{A_ON}"/>')
        out.append(f'<path d="M60 150 L136 150" stroke="url(#steel)" stroke-width="3"/>')
    elif kind == 'fuse':
        # A fuse board: three fuse bases, one carrier pulled out with its
        # blown wire (broken ends, scorch).
        out.append(cabinet(46, 60, 104, 120, 8))
        for i, fx in enumerate((68, 98, 128)):
            out.append(f'<rect x="{fx - 9}" y="78" width="18" height="70" rx="3" fill="url(#porcelain)"/>')
            out.append(f'<rect x="{fx - 4}" y="82" width="8" height="8" rx="1" fill="url(#steel)"/>')
            out.append(f'<rect x="{fx - 4}" y="136" width="8" height="8" rx="1" fill="url(#steel)"/>')
            if i != 1:
                out.append(f'<rect x="{fx - 6}" y="94" width="12" height="38" rx="3" fill="url(#porcelain)" stroke="{INK}" stroke-width="0.5"/>')
            else:
                out.append(f'<rect x="{fx - 3}" y="94" width="6" height="38" fill="{VAC}"/>')
        # The pulled carrier lying on the floor.
        out.append(f'<g transform="rotate(-12 92 186)"><rect x="66" y="180" width="52" height="12" rx="4" fill="url(#porcelain)" stroke="{INK}" stroke-width="0.5"/>'
                   f'<rect x="62" y="183" width="6" height="6" rx="1" fill="url(#steel)"/><rect x="116" y="183" width="6" height="6" rx="1" fill="url(#steel)"/>'
                   f'<path d="M70 178 L86 178 M98 178 L114 178" stroke="{COPPER}" stroke-width="1.6"/>'
                   f'<circle cx="92" cy="179" r="5" fill="{SCORCH}" opacity="0.8"/>'
                   f'<circle cx="87" cy="178" r="1.6" fill="{COPPER}"/><circle cx="97" cy="178" r="1.6" fill="{COPPER}"/></g>')
    elif kind == 'isolator':
        # A wall-mounted isolator: steel frame, porcelain posts, three blades
        # swung open; its operating rod down the side.
        out.append(f'<rect x="36" y="128" width="128" height="10" fill="url(#panelD)"/>')
        for px in (56, 100, 144):
            out.append(insulator(px - 12, 128, 26, 8))
            out.append(insulator(px + 12, 128, 26, 8))
            out.append(f'<g transform="rotate(-58 {px - 12} 100)"><rect x="{px - 12}" y="97" width="28" height="5" rx="2" fill="url(#steel)"/></g>')
            out.append(f'<rect x="{px + 8}" y="97" width="8" height="6" rx="1" fill="url(#steel)"/>')
            out.append(f'<path d="M{px - 12} 100 L{px - 12} 60 M{px + 12} 100 L{px + 12} 60" stroke="{COPPER}" stroke-width="2"/>')
        out.append(f'<path d="M158 138 L158 192" stroke="url(#steel)" stroke-width="3"/>')
        out.append(f'<rect x="150" y="184" width="18" height="6" rx="2" fill="{WIRE}"/>')
    elif kind == 'relay':
        # A relay panel on its own: three relays, no breaker in it.
        out.append(cabinet(52, 40, 92, 160))
        out.append(relay_box(62, 50, 46, 24, ((G_ON, True), (R_ON, True))))
        out.append(relay_box(62, 82, 46, 24, ((G_ON, True), (R_OFF, False))))
        out.append(relay_box(62, 114, 46, 24, ((A_ON, True), (G_OFF, False))))
        out.append(f'<path d="M120 54 Q132 90 120 140 M126 54 Q138 96 126 140" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
        out.append(f'<rect x="58" y="148" width="80" height="46" fill="none" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="126" y="166" width="5" height="12" rx="2" fill="url(#steel)"/>')
    elif kind == 'switch':
        # An ordinary switch board on a pillar.
        out.append(f'<rect x="70" y="40" width="60" height="160" fill="url(#panelD)"/>')
        out.append(f'<rect x="58" y="80" width="84" height="60" rx="5" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>')
        for i in range(3):
            sx = 72 + i * 18
            out.append(f'<rect x="{sx - 5}" y="92" width="10" height="20" rx="2" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
            out.append(f'<rect x="{sx - 3}" y="94" width="6" height="8" rx="1.5" fill="{WIRE}"/>')
        out.append(f'<circle cx="126" cy="100" r="3" fill="{R_ON}"/>')
        out.append(f'<circle cx="80" cy="126" r="2" fill="{WIRE}"/><circle cx="90" cy="126" r="2" fill="{WIRE}"/><circle cx="85" cy="120" r="2.4" fill="{WIRE}"/>')
        out.append(f'<path d="M100 40 L100 80" stroke="{WIRE}" stroke-width="2"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — vcb: the breakers on the workshop floor.
# --------------------------------------------------------------------------

def vcb_card(kind):
    out = room_stage(back_row=False)
    if kind == 'bottles':
        # The VCB trolley: three sealed vacuum bottles, copper contact arms.
        out.append(f'<rect x="40" y="130" width="120" height="56" rx="3" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="86" y="146" width="28" height="6" rx="2" fill="url(#steel)"/>')
        for bx in (66, 100, 134):
            out.append(bottle(bx, 128, 44, 16))
            out.append(f'<path d="M{bx} 81 L{bx} 66 L{bx + 14} 60" stroke="{COPPER}" stroke-width="3" fill="none" stroke-linecap="round"/>')
            out.append(f'<rect x="{bx - 2}" y="98" width="4" height="10" fill="{VAC}" opacity="0.4"/>')
        out.append(wheels(56, 144, 190, 7))
    elif kind == 'cutaway':
        # A vacuum bottle cut open: contacts just parted, the arc already gone
        # (a last faint wisp), the dark vacuum inside.
        out.append(f'<rect x="66" y="40" width="68" height="140" rx="10" fill="url(#porcelain)"/>')
        out.append(f'<rect x="76" y="56" width="48" height="108" rx="6" fill="{VAC}"/>')
        out.append(f'<rect x="62" y="34" width="76" height="8" rx="2" fill="url(#steel)"/><rect x="62" y="178" width="76" height="8" rx="2" fill="url(#steel)"/>')
        out.append(f'<rect x="94" y="20" width="12" height="76" fill="{COPPER}"/><rect x="88" y="92" width="24" height="6" rx="2" fill="{COPPER}"/>')
        out.append(f'<rect x="94" y="124" width="12" height="78" fill="{COPPER}"/><rect x="88" y="120" width="24" height="6" rx="2" fill="{COPPER}"/>')
        out.append(f'<path d="M98 106 q4 -3 2 4 q-2 4 3 3" stroke="{ARC}" stroke-width="1.2" fill="none" opacity="0.5"/>')
        out.append(motion(100, 86, 0, -1, 3, 7))
        out.append(motion(100, 132, 0, 1, 3, 7))
    elif kind == 'oiltank':
        # The OCB: contacts closed under oil in a steel tank on its truck.
        for bx in (72, 100, 128):
            out.append(insulator(bx, 70, 22, 9))
        out.append(f'<rect x="52" y="68" width="96" height="10" fill="url(#steel)"/>')
        out.append(f'<path d="M56 78 L144 78 L144 150 Q144 170 124 170 L76 170 Q56 170 56 150 Z" fill="url(#panelD)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="70" y="96" width="60" height="60" rx="4" fill="url(#oil)"/>')
        out.append(f'<rect x="70" y="90" width="60" height="8" fill="{VAC}"/>')
        for bx in (82, 100, 118):
            out.append(f'<path d="M{bx} 90 L{bx} 136" stroke="{COPPER}" stroke-width="3"/>')
        out.append(f'<path d="M78 136 L122 136" stroke="{COPPER}" stroke-width="4"/>')
        out.append(f'<rect x="44" y="170" width="112" height="16" rx="2" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(wheels(60, 140, 190, 7))
    elif kind == 'bubble':
        # The OCB cut away: the arc boils the oil into a big gas bubble.
        out.append(f'<rect x="38" y="30" width="124" height="160" rx="12" fill="url(#panelD)"/>')
        out.append(f'<rect x="48" y="40" width="104" height="140" rx="6" fill="{VAC}"/>')
        out.append(f'<rect x="48" y="64" width="104" height="116" rx="4" fill="url(#oil)"/>')
        out.append(f'<rect x="94" y="30" width="12" height="76" fill="{COPPER}"/><rect x="88" y="102" width="24" height="6" rx="2" fill="{COPPER}"/>')
        out.append(f'<rect x="88" y="136" width="24" height="6" rx="2" fill="{COPPER}"/><rect x="94" y="140" width="12" height="46" fill="{COPPER}"/>')
        out.append(f'<ellipse cx="100" cy="122" rx="28" ry="22" fill="{PAPER}" opacity="0.45" stroke="{PAPER}" stroke-width="1.2"/>')
        out.append(f'<path d="M100 108 l-5 7 l8 3 l-6 8 l7 2 l-4 8" stroke="{ARC}" stroke-width="2.6" fill="none" stroke-linejoin="round"/>')
        for cx, cy, r in ((70, 90, 4), (132, 96, 3), (124, 80, 2.5), (78, 74, 2)):
            out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{PAPER}" stroke-width="1"/>')
        out.append(motion(100, 96, 0, -1, 3, 6))
    elif kind == 'fuse':
        # A fuse carrier whose link has melted (broken, beaded ends, scorch).
        out.append(f'<rect x="26" y="140" width="148" height="10" rx="2" fill="{BAG}"/>')
        out.append(f'<rect x="40" y="100" width="120" height="40" rx="10" fill="url(#porcelain)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="30" y="110" width="14" height="20" rx="2" fill="url(#steel)"/><rect x="156" y="110" width="14" height="20" rx="2" fill="url(#steel)"/>')
        out.append(f'<path d="M44 96 L88 96 M112 96 L156 96" stroke="{COPPER}" stroke-width="2.4"/>')
        out.append(f'<circle cx="88" cy="96" r="3" fill="{COPPER}"/><circle cx="112" cy="96" r="3" fill="{COPPER}"/>')
        out.append(f'<ellipse cx="100" cy="104" rx="16" ry="8" fill="{SCORCH}" opacity="0.75"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — lamp: the breaker panel's front.
# --------------------------------------------------------------------------

def panel_front(red, green, spring_lamp, healthy, charged):
    out = card_open('room')
    out.append(f'<rect y="196" width="{W}" height="{H - 196}" fill="url(#floor)"/>')
    out.append(f'<rect x="22" y="10" width="156" height="190" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<path d="M22 138 L178 138" stroke="{INK}" stroke-width="0.6"/>')
    out.append(relay_box(40, 20, 76, 34))
    out.append(f'<rect x="126" y="24" width="38" height="26" rx="2" fill="none" stroke="{INK}" stroke-width="0.6"/>')
    out.append(lamp(52, 80, R_ON if red else R_OFF, red, 9) + plate(52, 94, 'I'))
    out.append(lamp(84, 80, G_ON if green else G_OFF, green, 9) + plate(84, 94, 'O'))
    out.append(lamp(118, 80, A_ON if spring_lamp else A_OFF, spring_lamp, 7) + plate(118, 92, 'spring', 12, 8))
    out.append(lamp(148, 80, W_ON if healthy else W_OFF, healthy, 7) + plate(148, 92, 'coil', 12, 8))
    # The control switch (pistol grip) at neutral.
    out.append(f'<circle cx="100" cy="120" r="8" fill="url(#steel)"/><rect x="97" y="108" width="6" height="18" rx="3" fill="{WIRE}"/>')
    # Lower door: the spring flag window and the operation counter.
    out.append(f'<rect x="40" y="150" width="50" height="30" rx="2" fill="url(#steel)"/>')
    out.append(f'<rect x="43" y="153" width="44" height="24" rx="1" fill="{PAPER}"/>')
    out.append(spring_coil(45, 156, 40, 18, charged))
    out.append(f'<rect x="108" y="154" width="54" height="22" rx="2" fill="url(#steel)"/>')
    out.append(f'<rect x="111" y="157" width="48" height="16" rx="1" fill="{PAPER}"/>')
    out.append(digits(116, 160, '04127', 10))
    out.append(f'<rect x="162" y="160" width="6" height="16" rx="2" fill="url(#steel)"/>')
    return out


def lamp_card(kind):
    states = {
        'green': (False, True, True, True, True),
        'green2': (False, True, False, True, False),
        'red': (True, False, False, False, False),
        'healthy': (True, False, False, True, False),
        'spring': (True, False, True, False, True),
    }
    return card_close(panel_front(*states[kind]))


# --------------------------------------------------------------------------
# Round 4 — rack: the cubicle and its breaker trolley.
# --------------------------------------------------------------------------

CUB = (96, 16, 76, 182)   # cubicle front x, y, w, h


def cubicle(red, green, pos, mouth='trolley'):
    """The cubicle front: its lamps, the racking position window (pointer at
    1 SERVICE, 2 TEST, 3 ISOLATED) and the compartment [mouth]: 'trolley'
    (the trolley in it), 'test' (half out), 'open' (cover off) or 'shut'
    (empty, shutters closed)."""
    x, y, w, h = CUB
    o = [cabinet(x, y, w, h, 12)]
    o.append(relay_box(x + 8, y + 8, 38, 20))
    o.append(lamp(x + 16, y + 46, R_ON if red else R_OFF, red, 6) + plate(x + 16, y + 55, 'I', 11, 7))
    o.append(lamp(x + 36, y + 46, G_ON if green else G_OFF, green, 6) + plate(x + 36, y + 55, 'O', 11, 7))
    o.append(f'<rect x="{x + 50}" y="{y + 36}" width="20" height="22" rx="2" fill="{VAC}"/>')
    for i in range(3):
        o.append(f'<path d="M{x + 54} {y + 41 + i * 6} l5 0" stroke="{PAPER}" stroke-width="1.2"/>')
    py = y + 41 + (pos - 1) * 6
    o.append(f'<path d="M{x + 67} {py - 3} L{x + 61} {py} L{x + 67} {py + 3} Z" fill="url(#steel)"/>')
    o.append(f'<path d="M{x} {y + 78} L{x + w} {y + 78}" stroke="{INK}" stroke-width="0.6"/>')
    mx, my, mw, mh = x + 6, y + 88, w - 12, h - 92
    if mouth == 'shut':
        o.append(f'<rect x="{mx}" y="{my}" width="{mw}" height="{mh}" fill="url(#panelD)"/>')
        for i in range(1, 8):
            o.append(f'<path d="M{mx} {my + i * mh / 8} L{mx + mw} {my + i * mh / 8}" stroke="{INK}" stroke-width="0.6"/>')
    else:
        o.append(f'<rect x="{mx}" y="{my}" width="{mw}" height="{mh}" fill="{VAC}"/>')
        if mouth in ('trolley', 'open'):
            o.append(f'<rect x="{mx + 3}" y="{my + 6}" width="{mw - 6}" height="{mh - 8}" rx="2" fill="url(#panel)" stroke="{INK}" stroke-width="0.5"/>')
            o.append(f'<rect x="{mx + 22}" y="{my + 40}" width="20" height="5" rx="2" fill="url(#steel)"/>')
            o.append(f'<rect x="{mx + 10}" y="{my + 14}" width="16" height="10" rx="1" fill="{PAPER}"/>')
            if mouth == 'open':
                # The front cover swung open: the mechanism inside shows.
                o.append(f'<rect x="{mx + 8}" y="{my + 50}" width="{mw - 16}" height="{mh - 58}" fill="{VAC}"/>')
                o.append(f'<path d="M{mx + 12} {my + 56} l4 6 l4 -6 l4 6 l4 -6 l4 6 l4 -6" stroke="url(#steel)" stroke-width="1.4" fill="none"/>')
                o.append(f'<path d="M{mx + 14} {my + 72} L{mx + mw - 14} {my + 72}" stroke="{COPPER}" stroke-width="2"/>')
                o.append(f'<path d="M{mx + 8} {my + 50} L{mx - 22} {my + 58} L{mx - 22} {my + mh + 2} L{mx + 8} {my + mh - 6} Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.5"/>')
    return ''.join(o)


def trolley_front(x, y, w=70, h=60, out_far=0):
    """The breaker trolley seen from the front, standing on the floor, its
    three bottles behind; [out_far] draws its side (pulled part way out)."""
    o = []
    for i in range(3):
        o.append(bottle(x + 16 + i * (w - 32) / 2, y + 2, 22, 10))
    if out_far:
        o.append(f'<path d="M{f(x + w)} {f(y)} l{f(out_far)} {f(-out_far * 0.6)} L{f(x + w + out_far)} {f(y + h - out_far * 0.6)} L{f(x + w)} {f(y + h)} Z" fill="url(#panelD)"/>')
        o.append(f'<path d="M{f(x + w + 4)} {f(y + 18)} l{f(out_far - 6)} {f(-(out_far - 6) * 0.6)}" stroke="{COPPER}" stroke-width="2.4"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
    o.append(f'<rect x="{f(x + w / 2 - 10)}" y="{f(y + h * 0.55)}" width="20" height="5" rx="2" fill="url(#steel)"/>')
    o.append(f'<rect x="{f(x + 8)}" y="{f(y + 8)}" width="16" height="10" rx="1" fill="{PAPER}"/>')
    o.append(wheels(x + 10, x + w - 10, y + h + 4, 5))
    return ''.join(o)


def rack_card(kind):
    out = room_stage(back_row=False)
    if kind == 'out':
        out.append(cubicle(False, False, 3, 'shut'))
        out.append(trolley_front(8, 130, 60, 56))
        out.append(person(90, ((66, 160), (68, 150)), face=-1, look=10))
        out.append(spanner(60, 150, 210))
        out.append(f'<path d="M100 202 L136 196 M136 196 l2 -8" stroke="url(#steel)" stroke-width="3" stroke-linecap="round"/>')
    elif kind == 'side':
        # Racked out too, another job: the trolley wheeled further off with
        # its front cover open, the mechanism being serviced; the cubicle's
        # shutters closed, both lamps dark, the pointer at 3 ISOLATED.
        out.append(cubicle(False, False, 3, 'shut'))
        tx, ty, tw, th = 6, 128, 64, 60
        out.append(trolley_front(tx, ty, tw, th))
        out.append(f'<rect x="{tx + 8}" y="{ty + 26}" width="{tw - 16}" height="{th - 30}" fill="{VAC}"/>')
        out.append(f'<path d="M{tx + 12} {ty + 34} l4 6 l4 -6 l4 6 l4 -6 l4 6 l4 -6 l4 6 l4 -6" stroke="url(#steel)" stroke-width="1.4" fill="none"/>')
        out.append(f'<path d="M{tx + 14} {ty + 48} L{tx + tw - 14} {ty + 48}" stroke="{COPPER}" stroke-width="2"/>')
        out.append(f'<path d="M{tx + tw - 8} {ty + 26} L{tx + tw + 14} {ty + 32} L{tx + tw + 14} {ty + th + 2} L{tx + tw - 8} {ty + th - 4} Z" fill="url(#panel)" stroke="{INK}" stroke-width="0.5"/>')
        out.append(person(98, ((52, 168), (58, 160)), face=-1, look=14))
        out.append(spanner(50, 164, 200))
    elif kind == 'service':
        out.append(cubicle(True, False, 1, 'trolley'))
        out.append(person(70, ((112, 150), (108, 140)), face=1, look=-4))
        out.append(spanner(110, 146, -30))
    elif kind == 'test':
        out.append(cubicle(False, True, 2, 'test'))
        out.append(trolley_front(98, 128, 70, 62, out_far=10))
        out.append(person(64, ((104, 160), (100, 150)), face=1, look=-2))
        out.append(spanner(102, 156, -30))
    elif kind == 'green':
        out.append(cubicle(False, True, 1, 'open'))
        out.append(person(56, ((76, 150), (80, 160)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — line: the tripped feeder out on its poles.
# --------------------------------------------------------------------------

TOP = 34   # the AB switch's top (wide view)


def ab_switch(x, closed=True):
    """A pole-top AB isolator: three phases on porcelain posts; each blade
    lies flat (closed) or stands raised (open)."""
    o = [f'<rect x="{x - 27}" y="{TOP + 16}" width="54" height="4" fill="url(#steel)"/>']
    for i in range(3):
        bx = x - 17 + i * 17
        o.append(insulator(bx - 5, TOP + 16, 12, 5) + insulator(bx + 5, TOP + 16, 12, 5))
        if closed:
            o.append(f'<rect x="{bx - 8}" y="{TOP + 2.5}" width="16" height="3" rx="1" fill="url(#steel)"/>')
        else:
            o.append(f'<g transform="rotate(-72 {bx - 5} {TOP + 4})"><rect x="{bx - 5}" y="{TOP + 2.5}" width="16" height="3" rx="1" fill="url(#steel)"/></g>')
    o.append(f'<path d="M{x + 5} {TOP + 20} L{x + 5} 160" stroke="url(#steel)" stroke-width="1.8"/>')
    o.append(f'<rect x="{x - 2}" y="158" width="14" height="6" rx="2" fill="{WIRE}"/>')
    return ''.join(o)


XL, XR = 30, 170


def wide_stage(left_open, right_open, beyond='edge'):
    out = card_open('day')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    if beyond == 'tie':
        # Another feeder's line at the side, tied on through the closed switch.
        out.append(pole(198, 60, GY - 4, 7))
        out.append(f'<rect x="184" y="70" width="16" height="4" fill="url(#steel)"/>')
    out.append(pole(XL, TOP + 10, GY - 4, 8) + pole(XR, TOP + 10, GY - 4, 8))
    out.append(ab_switch(XL, not left_open) + ab_switch(XR, not right_open))
    out.append(pole(100, 56, GY - 4, 6))
    out.append(f'<rect x="82" y="62" width="36" height="3" fill="url(#steel)"/>')
    y = TOP + 4
    for i in range(3):
        d = (i - 1) * 17
        out.append(f'<path d="M0 {y} L{XL + d - 8} {y}" stroke="{WIRE}" stroke-width="1.1"/>')
        out.append(f'<path d="M{XL + d + 8} {y} Q100 {y + 44 + i * 3} {XR + d - 8} {y}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        if beyond == 'edge':
            out.append(f'<path d="M{XR + d + 8} {y} L200 {y}" stroke="{WIRE}" stroke-width="1.1"/>')
        else:
            out.append(f'<path d="M{XR + d + 8} {y} Q{190 + i * 2} {y + 14} {188 + i * 5} 72" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    return out


def close_stage():
    out = card_open('day')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    out.append(pole(100, 30, GY - 4, 10))
    out.append(f'<rect x="58" y="46" width="84" height="5" fill="url(#steel)"/>')
    for cx in (66, 100, 134):
        out.append(insulator(cx, 46, 10, 6))
    out.append(f'<path d="M0 32 Q66 38 200 32" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    out.append(f'<path d="M0 35 Q100 38 200 35" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    out.append(f'<path d="M0 32 Q134 38 200 32" stroke="{WIRE}" stroke-width="1.8" fill="none" opacity="0"/>')
    for i in range(16):
        out.append(f'<rect x="94" y="{60 + i * 8}" width="12" height="2" fill="url(#steel)" opacity="0.8"/>')
    return out


def line_card(kind):
    # Poses never mark the answer: a man on the ground and a man up the pole
    # are on a safe card and on the traps (every hand holds both poses); the
    # coiled earth set, the tester and the tool bag likewise.
    if kind == 'ends':
        # Both ends opened from the ground; next he proves the line dead (the
        # tester in his hands), then earths it (the set still coiled).
        out = wide_stage(True, True)
        out.append(earth_coil(62, GY - 10))
        out.append(tool_bag(112, GY - 18))
        out.append(person(150, ((138, 152), (132, 142)), face=-1, look=-20))
        out.append(hv_tester(136, 160, 120, 108))
    elif kind == 'earth':
        # Proved dead first (the tester leans on the pole, used), then the
        # earth set clamped on all three phases down to its rod: only now he
        # climbs to work.
        out = close_stage()
        for cx in (66, 100, 134):
            out.append(f'<rect x="{cx - 3}" y="{33}" width="6" height="6" rx="1" fill="url(#steel)"/>')
            out.append(earth_lead(f'M{cx} 39 Q{cx + 10} 90 156 {GY - 12}', 2.2))
        out.append(f'<path d="M156 {GY - 14} L156 {GY + 10}" stroke="url(#steel)" stroke-width="3"/>')
        out.append(hv_tester(80, GY - 4, 92, 96))
        out.append(tool_bag(40, GY - 18))
        out.append(climber(92, 140, ((96, 80), (100, 92)), face=1))
    elif kind == 'climb':
        out = close_stage()
        out.append(climber(92, 140, ((96, 80), (100, 92)), face=1))
        out.append(earth_coil(44, GY - 10))
        out.append(tool_bag(150, GY - 18))
        out.append(hv_tester(132, GY - 6, 168, GY - 12))
        out.append(motion(80, 120, 0, -1, 3, 8))
    elif kind == 'tie':
        # He has opened the near end from the ground; the far end stays
        # closed, tied on to another live feeder.
        out = wide_stage(True, False, beyond='tie')
        out.append(person(56, ((38, 162), (40, 156)), face=-1, look=-24))
        out.append(hv_tester(118, GY - 6, 146, GY - 12))
        out.append(tool_bag(90, GY - 18))
    elif kind == 'oneend':
        # Near end open, far end closed: he is about to climb, no earth on.
        out = wide_stage(True, False)
        out.append(person(116, ((104, 150), (104, 138)), face=-1, look=-30))
        out.append(tool_bag(50, GY - 18))
    elif kind == 'hand':
        # At the top, an ungloved reach for the conductor: no earths on.
        out = close_stage()
        out.append(climber(94, 104, ((84, 40), (102, 70)), face=-1, look=20))
        out.append(earth_coil(150, GY - 10))
        out.append(hv_tester(30, GY - 6, 64, GY - 12))
        out.append(tool_bag(176, GY - 34))
    return card_close(out)


CARDS = {
    'reset_vcb': reset_card('vcb'),
    'reset_ocb': reset_card('ocb'),
    'reset_fuse': reset_card('fuse'),
    'reset_isolator': reset_card('isolator'),
    'reset_relay': reset_card('relay'),
    'reset_switch': reset_card('switch'),
    'vcb_bottles': vcb_card('bottles'),
    'vcb_cutaway': vcb_card('cutaway'),
    'vcb_oiltank': vcb_card('oiltank'),
    'vcb_bubble': vcb_card('bubble'),
    'vcb_fuse': vcb_card('fuse'),
    'lamp_green': lamp_card('green'),
    'lamp_green2': lamp_card('green2'),
    'lamp_red': lamp_card('red'),
    'lamp_healthy': lamp_card('healthy'),
    'lamp_spring': lamp_card('spring'),
    'rack_out': rack_card('out'),
    'rack_side': rack_card('side'),
    'rack_service': rack_card('service'),
    'rack_test': rack_card('test'),
    'rack_green': rack_card('green'),
    'line_ends': line_card('ends'),
    'line_earth': line_card('earth'),
    'line_climb': line_card('climb'),
    'line_tie': line_card('tie'),
    'line_oneend': line_card('oneend'),
    'line_hand': line_card('hand'),
}

# Safe cards and traps per round (mirrors learn_board_pack62.dart).
ROUNDS = {
    'reset': (['reset_vcb', 'reset_ocb'], ['reset_fuse', 'reset_isolator', 'reset_relay', 'reset_switch']),
    'vcb': (['vcb_bottles', 'vcb_cutaway'], ['vcb_oiltank', 'vcb_bubble', 'vcb_fuse']),
    'lamp': (['lamp_green', 'lamp_green2'], ['lamp_red', 'lamp_healthy', 'lamp_spring']),
    'rack': (['rack_out', 'rack_side'], ['rack_service', 'rack_test', 'rack_green']),
    'line': (['line_ends', 'line_earth'], ['line_climb', 'line_tie', 'line_oneend', 'line_hand']),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b|class="[\w-]+"')

# What a round's lesson itself says through colour may sit on every trap and
# not on the safe card: lamp — an OFF breaker shows green lit and red dark
# (lesson: red = ON, green = OFF), so red lit / green dark are the traps' state.
LESSON_STATE = {'lamp': {R_ON, G_OFF}}
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
                # The other way round: nothing (a colour, a pose, the coiled
                # earth set) on every trap of the hand and missing from the
                # safe card.
                missing = set.intersection(*(tok[t] for t in hand)) - tok[s] - LESSON_STATE.get(rnd, set())
                if missing:
                    problems.append(f'{rnd}: {s} with {hand} lacks {sorted(missing)}, on every trap')
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
