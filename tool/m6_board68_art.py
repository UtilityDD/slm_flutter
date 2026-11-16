"""Picture cards for lesson 6.8 শেখা ("অটো-রিক্লোজার ও সেকশনালাইজার: লাইনের স্মার্ট ব্রেন").

python -I tool/m6_board68_art.py .

Writes assets/game/art/m6_board68/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only labels are the ones a worker reads on the equipment —
the recloser's plate 'R', the sectionalizers' plates 'S-1', 'S-2', 'S-3', the
ON / OFF marks and the counter digits — drawn as stroke glyphs with English
digits.

What the cards show comes from lesson 6.8 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only:
  1. temp: a branch touches the line and falls clear (a temporary fault) —
     the recloser trips, waits and closes again by itself, the lights stay
     on, nobody patrols. Traps: the feeder dark and a crew patrolling for a
     fault that is gone, lock-out (handle down) after one trip, a branch
     sectionalizer open after a brief touch;
  2. perm: a tree down on one of three branches (a permanent fault) — in the
     end that branch's sectionalizer is open and the main line and the other
     branches are lit. Traps: the recloser closing and tripping without end
     (lights flicker), a healthy branch's sectionalizer open, the faulty
     branch cut off but everything dark;
  3. count: the sectionalizer counts while the recloser is open (its flag
     reads OFF), stays closed after the first count, and opens on a dead line
     before the recloser's last try (count 3: staged, the lesson gives
     '3-4 tries'). Traps: opening with a big arc under fault current, opening
     by itself with the recloser ON (count 0), opening at its first count,
     melted like a fuse;
  4. nonrec: before work on a recloser line — PTW asked by radio with
     Non-Reclose; the control box's Non-Reclose switch ON with its Hot Line
     Tag; Non-Reclose confirmed, tester at 0, earths on both sides, then the
     climb in a full-body harness (ruling X1, X7). Traps: climbing because the
     houses went dark, climbing on handle-down with no PTW and no
     Non-Reclose, working with the switch OFF (auto);
  5. pro: in front of the recloser — reading the operation counter, reading
     lock-out from a distance (handle hanging down), reading the control
     box's setting (pro tip 2). Traps: the manual handle pulled with a hook
     stick on a live line, writing 'lock-out' only because the houses are
     dark (handle up), waiting under a sectionalizer for it to blow.

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
    print('usage: python -I tool/m6_board68_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board68')
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
HARNESS = '#E07A1F'    # full-body harness straps (ruling X7)
WIRE = '#2B3138'
INK = '#4A5560'
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
COPPER = '#B8733A'
RED = '#D8402F'        # ON flag, Hot Line Tag, hook-stick grip
GREEN = '#3E9B4F'      # OFF flag; the earth lead's green
EARTH_Y = '#E8C830'
METER_Y = '#F2B630'
METER_D = '#B9851A'
LCD_ON = '#1D2B22'
SUN = '#FFE08A'
WIN_LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
SMOKE = '#7A848C'
MOVE = '#FFFFFF'
LEAF = '#4E8A3A'
LEAF_D = '#3B6E2B'
BARK = '#6B4A2E'
MOLTEN = '#F08A2C'
VAN = '#E9EEF2'
VAN_D = '#B8C3CC'
RADIO = '#1F2328'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3ABB2"/><stop offset="1" stop-color="#6C747B"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="rtank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7E8A93"/><stop offset="0.5" stop-color="#B7C1C8"/><stop offset="1" stop-color="#6E7A83"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#7D8891"/></linearGradient>
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


def card_open(back='day'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# People (the worker of tool/m6_board63_art.py; a full-body harness when he
# climbs, ruling X7).
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


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True, harness=False, props_front=''):
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
    if harness:
        # Shoulder straps crossing the chest, the waist belt and leg loops.
        g.append(f'<path d="M{f(sh[0] - px * 0.7)} {f(sh[1] - py * 0.7)} L{f(hip[0] + px * 0.6)} {f(hip[1] + py * 0.6 - 4)} '
                 f'M{f(sh[0] + px * 0.7)} {f(sh[1] + py * 0.7)} L{f(hip[0] - px * 0.6)} {f(hip[1] - py * 0.6 - 4)} '
                 f'M{f(hip[0] - px)} {f(hip[1] - py - 2)} L{f(hip[0] + px)} {f(hip[1] + py - 2)}" '
                 f'stroke="{HARNESS}" stroke-width="2" stroke-linecap="round" fill="none"/>')
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
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.25  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, s=S, front=''):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, gloves, props_front=front)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def climber(px, y, side=1, look=-20, s=1.0):
    """A lineman on the pole at x=[px]: [side] = which side of the pole he
    hangs on; y = his hip; harness on, gloves on, hands on the pole above."""
    hip = (px + 7 * side, y)
    sh = (px + 6 * side, y - 26)
    head = (px + 8 * side, y - 34)
    feet = ((px + 3 * side, y + 26), (px + 9 * side, y + 18))
    hands = ((px + 2 * side, y - 36), (px + 2 * side, y - 22))
    fig = figure(hip, sh, head, feet, hands, -side, look, True, harness=True)
    # The pole strap round the pole.
    strap = f'<path d="M{f(hip[0])} {f(y - 4)} Q{f(px - 6 * side)} {f(y - 10)} {f(hip[0])} {f(y - 12)}" stroke="{HARNESS}" stroke-width="1.6" fill="none"/>'
    return f'<g transform="translate({f(px)} {f(y)}) scale({s}) translate({f(-px)} {f(-y)})">{fig}{strap}</g>'


# --------------------------------------------------------------------------
# Glyphs: English digits as seven-segment strokes, plus the letters of the
# equipment plates (R, S, O, N, F) and '-'.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'R': 'M0 10 L0 0 L4 0 Q6 0 6 2.5 Q6 5 4 5 L0 5 M3 5 L6 10',
    'S': 'M6 1.5 Q5 0 3 0 Q0 0 0 2.5 Q0 5 3 5 Q6 5 6 7.5 Q6 10 3 10 Q1 10 0 8.5',
    'O': 'M3 0 Q6 0 6 5 Q6 10 3 10 Q0 10 0 5 Q0 0 3 0',
    'N': 'M0 10 L0 0 L6 10 L6 0',
    'F': 'M6 0 L0 0 L0 10 M0 5 L4.5 5',
    '-': 'M1 5 L5 5',
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
    ox = x
    for ch in text:
        if ch == ' ':
            ox += 4.5 * k
        elif ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox
            for sg in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[sg]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
        else:
            d.append(_shift(_LET[ch], ox, y, k))
            ox += (6.2 if ch == '-' else 7.8) * k
    sw = w if w is not None else 1.5 * k
    return (f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(sw)}" stroke-linecap="round" '
            f'stroke-linejoin="round" fill="none"/>')


def glyph_width(text, h=10.0):
    k = h / 10
    wd = 0.0
    for ch in text:
        wd += 4.5 * k if ch == ' ' else 5.4 * k if ch == '1' else 6.2 * k if ch == '-' else 7.8 * k
    return wd - 1.8 * k


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def ground():
    return f'<rect x="0" y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>'


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
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)"/>'
            f'<path d="M{f(x - r * 0.7)} {f(y)} L{f(x + r * 0.7)} {f(y)} M{f(x)} {f(y - r * 0.7)} L{f(x)} {f(y + r * 0.7)} '
            f'M{f(x - r * 0.5)} {f(y - r * 0.5)} L{f(x + r * 0.5)} {f(y + r * 0.5)} M{f(x + r * 0.5)} {f(y - r * 0.5)} L{f(x - r * 0.5)} {f(y + r * 0.5)}" '
            f'stroke="{SUN}" stroke-width="1.6" stroke-linecap="round"/>')


def smoke(x, y):
    return (f'<g fill="{SMOKE}" opacity="0.8"><circle cx="{f(x)}" cy="{f(y)}" r="4"/><circle cx="{f(x + 3)}" cy="{f(y - 7)}" r="5"/>'
            f'<circle cx="{f(x - 2)}" cy="{f(y - 15)}" r="6"/></g>')


def house(x, y, w, h, lit=True):
    """A house (feet on y) with one window, lit or dark."""
    top = y - h
    return (f'<rect x="{f(x)}" y="{f(top)}" width="{f(w)}" height="{f(h)}" fill="url(#house)"/>'
            f'<path d="M{f(x - 3)} {f(top + 1)} L{f(x + w / 2)} {f(top - 12)} L{f(x + w + 3)} {f(top + 1)} Z" fill="url(#roof)"/>'
            f'<rect x="{f(x + w / 2 - 5)}" y="{f(top + 8)}" width="10" height="9" fill="{WIN_LIT if lit else WIN_OFF}"/>')


def flicker(x, y):
    """Short dashes round a window: the lights keep going off and on."""
    return (f'<g stroke="{MOVE}" stroke-width="1.4" stroke-linecap="round">'
            f'<path d="M{f(x - 9)} {f(y - 3)} l-4 -2 M{f(x + 9)} {f(y - 3)} l4 -2 M{f(x)} {f(y - 10)} l0 -4"/></g>')


def tree(x, top, lean=0):
    """A roadside tree: trunk from the ground to [top], a leafy crown."""
    return (f'<path d="M{f(x)} {GY} L{f(x + lean)} {f(top + 24)}" stroke="{BARK}" stroke-width="6" stroke-linecap="round"/>'
            f'<ellipse cx="{f(x + lean)}" cy="{f(top + 18)}" rx="20" ry="16" fill="{LEAF_D}"/>'
            f'<ellipse cx="{f(x + lean - 6)}" cy="{f(top + 12)}" rx="13" ry="11" fill="{LEAF}"/>')


def branch(x0, y0, x1, y1):
    """A leafy branch from (x0, y0) to its tip (x1, y1)."""
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    return (f'<path d="M{f(x0)} {f(y0)} Q{f(mx + 4)} {f(my - 4)} {f(x1)} {f(y1)}" stroke="{BARK}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            f'<ellipse cx="{f(x1)}" cy="{f(y1)}" rx="8" ry="5" fill="{LEAF}"/>'
            f'<ellipse cx="{f(mx)}" cy="{f(my)}" rx="6" ry="4" fill="{LEAF_D}"/>')


def fallen_tree(x, y, ang=-28):
    """A whole tree fallen across a line (trunk at (x, y) on the ground)."""
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<path d="M{f(x)} {f(y)} L{f(x + 58)} {f(y)}" stroke="{BARK}" stroke-width="5" stroke-linecap="round"/>'
            f'<ellipse cx="{f(x + 62)}" cy="{f(y - 2)}" rx="16" ry="11" fill="{LEAF_D}"/>'
            f'<ellipse cx="{f(x + 56)}" cy="{f(y - 6)}" rx="10" ry="7" fill="{LEAF}"/></g>')


def van(x, y=GY):
    """The crew's van (feet of the wheels on y), facing left."""
    return (f'<rect x="{f(x)}" y="{f(y - 22)}" width="44" height="17" rx="3" fill="{VAN}" stroke="{VAN_D}" stroke-width="0.8"/>'
            f'<path d="M{f(x)} {f(y - 13)} L{f(x - 9)} {f(y - 11)} L{f(x - 9)} {f(y - 5)} L{f(x)} {f(y - 5)} Z" fill="{VAN}" stroke="{VAN_D}" stroke-width="0.8"/>'
            f'<rect x="{f(x + 2)}" y="{f(y - 20)}" width="9" height="6" rx="1" fill="{WIN_OFF}"/>'
            f'<rect x="{f(x + 18)}" y="{f(y - 17)}" width="22" height="3" fill="{RED}"/>'
            f'<circle cx="{f(x + 4)}" cy="{f(y - 4)}" r="4" fill="{WIRE}"/><circle cx="{f(x + 34)}" cy="{f(y - 4)}" r="4" fill="{WIRE}"/>')


def radio(x, y):
    """A handheld radio, its aerial up; (x, y) = its centre."""
    return (f'<rect x="{f(x - 3)}" y="{f(y - 5)}" width="6" height="10" rx="1.4" fill="{RADIO}"/>'
            f'<path d="M{f(x + 1.5)} {f(y - 5)} l0 -7" stroke="{RADIO}" stroke-width="1.2" stroke-linecap="round"/>'
            f'<rect x="{f(x - 1.8)}" y="{f(y - 3.6)}" width="3.6" height="2.6" fill="url(#lcd)"/>')


def sheet(x, y, s=1.0):
    """The PTW paper (a sheet with a red header stripe and lines)."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(14 * s)}" height="{f(18 * s)}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{f(14 * s)}" height="{f(3.5 * s)}" fill="{RED}"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 2.5 * s)} {f(y + (7 + i * 3.5) * s)} h{f(9 * s)}" stroke="{INK}" stroke-width="0.6"/>')
    return ''.join(o)


def clipboard(x, y, s=1.0):
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(20 * s)}" height="{f(26 * s)}" rx="2" fill="{BAG}"/>',
         f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 4 * s)}" width="{f(15 * s)}" height="{f(20 * s)}" fill="{PAPER}"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 5 * s)} {f(y + (9 + i * 5) * s)} h{f(9 * s)}" stroke="{INK}" stroke-width="0.8"/>')
    return ''.join(o)


def tester(x, y, reading, s=1.0):
    """The yellow voltage tester (top-left x, y) with its reading."""
    w, h = 28 * s, 42 * s
    tw = glyph_width(reading, 10 * s)
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>'
            f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 3.5 * s)}" width="{f(w - 5 * s)}" height="{f(15 * s)}" rx="1.5" fill="url(#lcd)"/>'
            + glyphs(x + (w - tw) / 2, y + 6 * s, reading, 10 * s, LCD_ON)
            + f'<circle cx="{f(x + w / 2)}" cy="{f(y + 27 * s)}" r="{f(6 * s)}" fill="{WIRE}"/>')


def earth_lead(d, w=2.2):
    return (f'<path d="{d}" stroke="{GREEN}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """A portable earth set lying coiled on the ground, unused."""
    o = []
    for rx, ry in ((12, 4.5), (9, 3.5), (6, 2.5)):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0', 1.8))
    for dx in (-18, 15):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="6" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def earth_set(x, ys):
    """A portable earth on the three conductors at x (their heights [ys]):
    a clamp on each, the bar, the lead down to a spike."""
    o = [f'<path d="M{f(x)} {f(ys[0] - 2)} L{f(x)} {f(ys[-1] + 4)}" stroke="url(#steel)" stroke-width="2.4"/>']
    for y in ys:
        o.append(f'<rect x="{f(x - 3)}" y="{f(y - 2.5)}" width="6" height="5" rx="1.2" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
    o.append(earth_lead(f'M{f(x)} {f(ys[-1] + 4)} Q{f(x + 8)} {f((ys[-1] + GY) / 2)} {f(x)} {GY - 4}'))
    o.append(f'<path d="M{f(x)} {GY - 6} L{f(x)} {GY + 8}" stroke="url(#steel)" stroke-width="2.6"/>')
    return ''.join(o)


def hook_stick(x0, y0, x1, y1):
    """An insulated hook stick from the hands (x0, y0) up to its hook at (x1, y1)."""
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{METER_Y}" stroke-width="2.6" stroke-linecap="round"/>'
            f'<path d="M{f(x0)} {f(y0)} L{f(x0 + (x1 - x0) * 0.12)} {f(y0 + (y1 - y0) * 0.12)}" stroke="{RED}" stroke-width="3.4" stroke-linecap="round"/>'
            f'<path d="M{f(x1)} {f(y1)} q3 -4 0 -6" stroke="url(#steel)" stroke-width="1.8" fill="none"/>')


def conductors(ys, x0=0, x1=W, sag=6):
    return ''.join(f'<path d="M{f(x0)} {f(y)} Q{f((x0 + x1) / 2)} {f(y + sag)} {f(x1)} {f(y)}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>'
                   for y in ys)


def recloser(cx, top, s=1.0, handle_down=False, counter='', flag=None):
    """The pole-top auto-recloser: grey tank, two bushings, the 'R' plate,
    its operation counter window, the yellow manual handle (tucked up when in
    service, hanging down at lock-out) and, if [flag], its ON / OFF flag."""
    def p(v):
        return f(v)
    x, y = cx - 15 * s, top
    o = [f'<rect x="{p(x + 4 * s)}" y="{p(y - 9 * s)}" width="{p(4 * s)}" height="{p(9 * s)}" fill="url(#porc)"/>',
         f'<rect x="{p(x + 22 * s)}" y="{p(y - 9 * s)}" width="{p(4 * s)}" height="{p(9 * s)}" fill="url(#porc)"/>',
         f'<rect x="{p(x)}" y="{p(y)}" width="{p(30 * s)}" height="{p(22 * s)}" rx="{p(3 * s)}" fill="url(#rtank)" stroke="{INK}" stroke-width="0.7"/>',
         f'<rect x="{p(x + 2.5 * s)}" y="{p(y + 4 * s)}" width="{p(9 * s)}" height="{p(12 * s)}" rx="1" fill="{PAPER}"/>',
         glyphs(x + 4 * s, y + 6 * s, 'R', 8 * s, INK, 1.3 * s),
         f'<rect x="{p(x + 13 * s)}" y="{p(y + 5 * s)}" width="{p(15 * s)}" height="{p(9 * s)}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>']
    if counter:
        tw = glyph_width(counter, 6 * s)
        o.append(glyphs(x + 20.5 * s - tw / 2, y + 6.5 * s, counter, 6 * s, WIRE, 1.1 * s))
    # the manual handle, pivoting under the tank's right end
    px, py = x + 24 * s, y + 22 * s
    if handle_down:
        hx, hy = px + 3 * s, py + 17 * s
    else:
        hx, hy = px + 12 * s, py - 4 * s
    o.append(f'<path d="M{p(px)} {p(py)} L{p(hx)} {p(hy)}" stroke="{HELMET_D}" stroke-width="{p(2.6 * s)}" stroke-linecap="round"/>')
    o.append(f'<circle cx="{p(hx)}" cy="{p(hy)}" r="{p(2.6 * s)}" fill="none" stroke="{HELMET_D}" stroke-width="{p(1.4 * s)}"/>')
    o.append(f'<circle cx="{p(px)}" cy="{p(py)}" r="{p(1.6 * s)}" fill="{INK}"/>')
    if flag:
        fw = 20 * s
        o.append(f'<rect x="{p(x + 2 * s)}" y="{p(y + 24 * s)}" width="{p(fw)}" height="{p(10 * s)}" rx="1.5" fill="{RED if flag == "ON" else GREEN}"/>')
        tw = glyph_width(flag, 6 * s)
        o.append(glyphs(x + 2 * s + (fw - tw) / 2, y + 26 * s, flag, 6 * s, PAPER, 1.1 * s))
    return ''.join(o)


def control_box(px, y, side=1, s=1.0, door=False, switch=None, screen=''):
    """The recloser's control box on the pole at x=[px] (top y), cable up to
    the recloser; [door] open shows the panel: the Non-Reclose switch at
    'ON' (with its red Hot Line Tag) or 'OFF', and the setting screen."""
    w, h = 22 * s, 30 * s
    x = px + 4 * side if side > 0 else px - 4 - w
    o = [f'<path d="M{f(x + w / 2)} {f(y)} L{f(x + w / 2)} {f(y - 10)} L{f(px)} {f(y - 14)}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.7"/>']
    if not door:
        o.append(f'<path d="M{f(x + 4 * s)} {f(y + 8 * s)} h{f(14 * s)} M{f(x + 4 * s)} {f(y + 13 * s)} h{f(10 * s)}" stroke="{INK}" stroke-width="0.7"/>')
        return ''.join(o)
    o.append(f'<rect x="{f(x + 2 * s)}" y="{f(y + 2 * s)}" width="{f(w - 4 * s)}" height="{f(h - 4 * s)}" rx="1" fill="url(#panel)"/>')
    # the door swung out
    dx = x + w if side > 0 else x
    sgn = 1 if side > 0 else -1
    o.append(f'<path d="M{f(dx)} {f(y)} L{f(dx + 8 * s * sgn)} {f(y + 3 * s)} L{f(dx + 8 * s * sgn)} {f(y + h - 3 * s)} L{f(dx)} {f(y + h)} Z" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    if screen:
        o.append(f'<rect x="{f(x + 4 * s)}" y="{f(y + 4 * s)}" width="{f(w - 8 * s)}" height="{f(9 * s)}" rx="1" fill="url(#lcd)"/>')
        tw = glyph_width(screen, 6 * s)
        o.append(glyphs(x + w / 2 - tw / 2, y + 5.5 * s, screen, 6 * s, LCD_ON, 1.1 * s))
    if switch:
        o.append(non_reclose(x + w / 2, y + 21 * s, switch, s * 0.55))
    return ''.join(o)


def non_reclose(cx, cy, state, s=1.0):
    """The Non-Reclose toggle: its plate marked ON (top) and OFF (bottom),
    the lever up at ON or down at OFF; at ON the red Hot Line Tag hangs on it."""
    o = [f'<rect x="{f(cx - 14 * s)}" y="{f(cy - 22 * s)}" width="{f(28 * s)}" height="{f(44 * s)}" rx="{f(3 * s)}" fill="{WIRE}"/>',
         glyphs(cx - glyph_width('ON', 7 * s) / 2, cy - 19 * s, 'ON', 7 * s, PAPER, 1.3 * s),
         glyphs(cx - glyph_width('OFF', 7 * s) / 2, cy + 12 * s, 'OFF', 7 * s, PAPER, 1.3 * s),
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(4.5 * s)}" fill="url(#steel)"/>']
    ey = cy - 11 * s if state == 'ON' else cy + 11 * s
    o.append(f'<path d="M{f(cx)} {f(cy)} L{f(cx)} {f(ey)}" stroke="url(#steel)" stroke-width="{f(4 * s)}" stroke-linecap="round"/>')
    if state == 'ON':
        o.append(f'<path d="M{f(cx + 1.5 * s)} {f(ey + 1 * s)} L{f(cx + 9 * s)} {f(cy + 4 * s)}" stroke="{PAPER}" stroke-width="{f(0.9 * s)}"/>')
        o.append(f'<rect x="{f(cx + 5 * s)}" y="{f(cy + 3 * s)}" width="{f(11 * s)}" height="{f(17 * s)}" rx="1.5" fill="{RED}"/>')
        o.append(f'<circle cx="{f(cx + 10.5 * s)}" cy="{f(cy + 6.5 * s)}" r="{f(1.5 * s)}" fill="{PAPER}"/>')
    return ''.join(o)


def sectionalizer(cx, top, label='S-1', s=1.0, blade='closed', count=''):
    """A branch sectionalizer: its switch blade on two insulators (closed
    flat, open standing up, 'opening' half way, or 'melt' sagging), the grey
    body with its plate and, if [count], its count window."""
    x, y = cx - 13 * s, top
    o = []
    bl, br = (cx - 9 * s, y - 9 * s), (cx + 9 * s, y - 9 * s)
    for bx in (bl[0], br[0]):
        o.append(f'<rect x="{f(bx - 2 * s)}" y="{f(y - 8 * s)}" width="{f(4 * s)}" height="{f(8 * s)}" fill="url(#porc)"/>')
    sw = f(2.6 * s)
    if blade == 'closed':
        o.append(f'<path d="M{f(bl[0])} {f(bl[1])} L{f(br[0])} {f(br[1])}" stroke="url(#steel)" stroke-width="{sw}" stroke-linecap="round"/>')
    elif blade == 'open':
        o.append(f'<path d="M{f(bl[0])} {f(bl[1])} L{f(bl[0] + 4 * s)} {f(bl[1] - 16 * s)}" stroke="url(#steel)" stroke-width="{sw}" stroke-linecap="round"/>')
    elif blade == 'opening':
        o.append(f'<path d="M{f(bl[0])} {f(bl[1])} L{f(bl[0] + 13 * s)} {f(bl[1] - 9 * s)}" stroke="url(#steel)" stroke-width="{sw}" stroke-linecap="round"/>')
    elif blade == 'melt':
        o.append(f'<path d="M{f(bl[0])} {f(bl[1])} Q{f(cx)} {f(bl[1] + 9 * s)} {f(cx + 2 * s)} {f(bl[1] + 7 * s)}" stroke="url(#steel)" stroke-width="{sw}" fill="none" stroke-linecap="round"/>')
        o.append(f'<path d="M{f(br[0])} {f(br[1])} l{f(-3 * s)} {f(4 * s)}" stroke="url(#steel)" stroke-width="{sw}" stroke-linecap="round"/>')
        for i, (ddx, ddy) in enumerate(((1, 11), (4, 15), (-1, 18))):
            o.append(f'<ellipse cx="{f(cx + ddx * s)}" cy="{f(bl[1] + ddy * s)}" rx="{f(1.4 * s)}" ry="{f(2 * s)}" fill="{MOLTEN}"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(18 * s)}" rx="{f(2.5 * s)}" fill="url(#rtank)" stroke="{INK}" stroke-width="0.7"/>')
    lw = glyph_width(label, 6 * s)
    o.append(f'<rect x="{f(x + 2 * s)}" y="{f(y + 3 * s)}" width="{f(lw + 4 * s)}" height="{f(10 * s)}" rx="1" fill="{PAPER}"/>')
    o.append(glyphs(x + 4 * s, y + 5 * s, label, 6 * s, INK, 1.1 * s))
    if count:
        o.append(f'<rect x="{f(x + 26 * s + 2)}" y="{f(y + 2 * s)}" width="{f(10 * s)}" height="{f(13 * s)}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>')
        tw = glyph_width(count, 8 * s)
        o.append(glyphs(x + 31 * s + 2 - tw / 2, y + 4.5 * s, count, 8 * s, WIRE, 1.3 * s))
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — temp: a branch touches the line (a temporary fault). The recloser
# R on the left pole with its control box; the main line to two houses; the
# S-1 branch to a third house; a tree by the line.
# --------------------------------------------------------------------------

T_LINE = (30, 36, 42)
T_RP, T_SP = 22, 132


def temp_stage(lit=(True, True, True), handle_down=False, s1='closed', touch=False, branch_gone=False, sway=False):
    out = card_open('day')
    out.append(cloud(170, 16, 0.8))
    out.append(ground())
    out.append(pole(T_RP, 18, GY, 8))
    out.append(pole(T_SP, 18, GY, 7))
    out.append(f'<rect x="{T_RP - 12}" y="24" width="24" height="4" rx="1" fill="url(#chan)"/>')
    out.append(f'<rect x="{T_SP - 12}" y="24" width="24" height="4" rx="1" fill="url(#chan)"/>')
    # The tree behind the houses, its branch near the line.
    out.append(tree(92, 66))
    if sway:
        out.append(conductors((T_LINE[0],), sag=6))
        out.append(f'<path d="M0 {T_LINE[1]} Q100 {T_LINE[1] + 2} 200 {T_LINE[1]}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M0 {T_LINE[2]} Q100 {T_LINE[2] - 3} 200 {T_LINE[2]}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    else:
        out.append(conductors(T_LINE))
    if touch:
        out.append(branch(98, 76, 104, 48))
    elif branch_gone:
        out.append(branch(112, GY - 4, 136, GY - 10))
    else:
        out.append(branch(98, 76, 114, 62))
    # Recloser on the left pole, control box below.
    out.append(f'<path d="M{T_RP + 6} 26 L{T_RP + 6} 50 M{T_RP + 24} 32 L{T_RP + 24} 50" stroke="{WIRE}" stroke-width="1"/>')
    out.append(recloser(T_RP + 15, 58, 1.25, handle_down, counter='1'))
    out.append(control_box(T_RP, 124, 1))
    # S-1 on the branch pole; the branch line down to house B.
    out.append(f'<path d="M{T_SP} 40 L{T_SP + 10} 62" stroke="{WIRE}" stroke-width="1"/>')
    out.append(sectionalizer(T_SP + 20, 70, 'S-1', 0.95, s1))
    out.append(f'<path d="M{T_SP + 30} 64 Q178 90 182 132" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    # Service drops to the two main-line houses.
    out.append(f'<path d="M64 40 Q66 90 68 140 M100 40 Q104 100 108 150" stroke="{WIRE}" stroke-width="0.8" fill="none"/>')
    out.append(house(50, GY - 4, 34, 52, lit[0]))
    out.append(house(92, GY - 4, 30, 42, lit[1]))
    out.append(house(160, GY - 4, 34, 60, lit[2]))
    return out


def temp_card(kind):
    if kind == 'trip':
        # The branch touched and is falling clear; the recloser tripped once
        # (counter 1), closed again; every window lit.
        out = temp_stage()
        out.append(branch(98, 76, 118, 70))
        out.append(motion(122, 58, 0.5, 1, 3, 8))
    elif kind == 'wind':
        # Wind swung two wires together for a moment; one trip (counter 1),
        # the line holds, the van stays parked.
        out = temp_stage(sway=True)
        out.append(motion(30, 70, 1, 0.1, 3, 14))
        out.append(motion(150, 104, 1, 0.1, 2, 12))
        out.append(van(130))
    elif kind == 'patrol':
        # Everything dark, the crew walking the line with a torch for a fault
        # that has gone.
        out = temp_stage(lit=(False, False, False), handle_down=True)
        out.append(van(128))
        out.append(f'<path d="M78 120 L120 70 L136 80 Z" fill="url(#glow)"/>')
        out.append(person(70, ((78, 122), (64, 150)), face=1, look=-24, s=1.1))
        out.append(motion(52, 168, -1, 0, 2, 8))
    elif kind == 'lock1':
        # One trip (counter 1) and the handle already hangs down: lock-out.
        out = temp_stage(lit=(False, False, False), handle_down=True, branch_gone=True)
    elif kind == 'sopen':
        # A brief touch and the branch's S-1 stands open; house B dark.
        out = temp_stage(lit=(True, True, False), s1='open', branch_gone=True)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — perm: a tree down on one of three branches (a permanent fault).
# R on the left pole; the main line across the top; S-1, S-2, S-3 on three
# branch poles, each branch down to its house.
# --------------------------------------------------------------------------

P_BR = (66, 114, 162)
P_TOP = 34


def perm_stage(tree_on, open_s=None, lit=(True, True, True), handle_down=False):
    out = card_open('day')
    out.append(ground())
    out.append(pole(18, 20, GY, 8))
    out.append(f'<rect x="8" y="26" width="20" height="4" rx="1" fill="url(#chan)"/>')
    out.append(conductors((P_TOP - 4, P_TOP + 2), x0=0, x1=W, sag=4))
    out.append(f'<path d="M24 28 L24 44 M38 34 L38 44" stroke="{WIRE}" stroke-width="1"/>')
    out.append(recloser(32, 50, 1.0, handle_down, counter=''))
    for i, x in enumerate(P_BR):
        out.append(pole(x, P_TOP - 8, GY, 6))
        out.append(f'<path d="M{x} {P_TOP} L{x + 8} {P_TOP + 16}" stroke="{WIRE}" stroke-width="1"/>')
        out.append(sectionalizer(x + 16, P_TOP + 24, f'S-{i + 1}', 0.8, 'open' if open_s == i else 'closed'))
        out.append(f'<path d="M{x + 24} {P_TOP + 20} Q{x + 26} 110 {x + 20} 146" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
        out.append(house(x + 8, GY - 4, 28, 40, lit[i]))
    tx = P_BR[tree_on]
    out.append(fallen_tree(tx - 22, GY - 6, -52))
    return out


def perm_card(kind):
    if kind == 's1':
        out = perm_stage(0, open_s=0, lit=(False, True, True))
    elif kind == 's3':
        out = perm_stage(2, open_s=2, lit=(True, True, False))
    elif kind == 'endless':
        # No lock-out: the recloser closes and trips again and again; every
        # window flickers.
        out = perm_stage(1)
        out.append(spark(P_BR[1] + 24, 104, 10))
        for x in P_BR:
            out.append(flicker(x + 22, GY - 44 + 12))
        out.append(motion(46, 46, 1, -1, 3, 6))
    elif kind == 'wrongs':
        # The tree is on branch 1, but S-3 (a healthy branch) is open; the
        # recloser locked out, all dark.
        out = perm_stage(0, open_s=2, lit=(False, False, False), handle_down=True)
    elif kind == 'alldark':
        # S-2 has cut off the faulty branch — and still everything is dark.
        out = perm_stage(1, open_s=1, lit=(False, False, False), handle_down=True)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — count: close-up of the S-1 sectionalizer on its branch pole; the
# recloser on the far pole with its ON / OFF flag; a fault down the branch.
# --------------------------------------------------------------------------

def count_stage(flag='OFF', lit=False):
    out = card_open('day')
    out.append(ground())
    out.append(pole(20, 26, GY, 6))
    out.append(f'<rect x="10" y="32" width="20" height="3" rx="1" fill="url(#chan)"/>')
    out.append(conductors((38, 44), x0=0, x1=W, sag=3))
    out.append(f'<path d="M24 34 L24 52 M36 40 L36 52" stroke="{WIRE}" stroke-width="0.9"/>')
    out.append(recloser(30, 56, 0.8, False, counter='', flag=flag))
    out.append(pole(104, 30, GY, 9))
    out.append(f'<rect x="90" y="40" width="28" height="4" rx="1" fill="url(#chan)"/>')
    out.append(f'<path d="M104 44 L112 74 M150 74 Q176 110 172 150" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    out.append(house(150, GY - 4, 36, 44, lit))
    out.append(fallen_tree(158, GY - 2, -40))
    return out


def count_card(kind):
    if kind == 'one':
        # The recloser has opened (OFF): the sectionalizer counted 1 and stays
        # closed, waiting.
        out = count_stage('OFF')
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'closed', '1'))
    elif kind == 'dead':
        # Recloser OFF, line dead: at count 3 the blade opens, no arc.
        out = count_stage('OFF')
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'open', '3'))
    elif kind == 'arc':
        # Recloser ON, fault current flowing: the blade pulled open in a big arc.
        out = count_stage('ON')
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'opening', '1'))
        out.append(spark(124, 66, 20))
    elif kind == 'self':
        # Recloser ON, count 0 — and the blade stands open by itself.
        out = count_stage('ON', lit=False)
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'open', '0'))
    elif kind == 'first':
        # Recloser OFF, count 1 — and the blade is already open.
        out = count_stage('OFF')
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'open', '1'))
    elif kind == 'melt':
        # Drawn like a blown fuse: the blade sagging, dripping, smoking.
        out = count_stage('ON')
        out.append(sectionalizer(124, 92, 'S-1', 2.0, 'melt', '1'))
        out.append(smoke(132, 64))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — nonrec: before work on a line with a recloser. The pole with the
# recloser and its control box; the houses dark (the line is off).
# --------------------------------------------------------------------------

N_P = 96
N_LINE = (28, 34, 40)


def nonrec_stage(handle_down=False, climb=False):
    out = card_open('day')
    out.append(ground())
    out.append(pole(N_P, 16, GY, 9))
    out.append(f'<rect x="{N_P - 16}" y="22" width="32" height="4" rx="1" fill="url(#chan)"/>')
    out.append(conductors(N_LINE, sag=5))
    out.append(f'<path d="M{N_P + 6} 30 L{N_P + 6} 50 M{N_P + 24} 36 L{N_P + 24} 50" stroke="{WIRE}" stroke-width="1"/>')
    out.append(recloser(N_P + 15, 58, 1.2, handle_down, counter='4'))
    out.append(control_box(N_P, 128, 1))
    out.append(house(150, GY - 4, 36, 52, False))
    out.append(house(10, GY - 4, 30, 40, False))
    if climb:
        out.append(climber(N_P, 112, -1, -24, 1.1))
    return out


def closeup_stage(state, climb):
    """The control box opened up close (left), the pole and its recloser
    behind (right)."""
    out = card_open('day')
    out.append(ground())
    out.append(pole(160, 10, GY, 8))
    out.append(conductors((20, 26), x0=100, x1=W, sag=3))
    out.append(recloser(172, 44, 0.9, False, counter='4'))
    out.append(house(118, GY - 4, 26, 34, False))
    out.append(f'<rect x="10" y="40" width="96" height="130" rx="5" fill="url(#box)" stroke="{INK}" stroke-width="1"/>')
    out.append(f'<rect x="16" y="46" width="84" height="118" rx="3" fill="url(#panel)"/>')
    out.append(f'<rect x="24" y="54" width="68" height="22" rx="2" fill="url(#lcd)"/>')
    out.append(glyphs(58 - glyph_width('4', 12) / 2, 59, '4', 12, LCD_ON, 1.8))
    out.append(non_reclose(48, 118, state, 1.1))
    if climb:
        out.append(climber(160, 104, -1, -24, 0.9))
    return out


def nonrec_card(kind):
    if kind == 'radio':
        # On the ground, the PTW in hand, asking the control room on the
        # radio for Non-Reclose.
        out = nonrec_stage()
        out.append(person(70, ((74, 140), (63, 118)), face=1, look=-6,
                          front=sheet(74, 132, 1.0) + radio(63, 118)))
    elif kind == 'switch':
        # The control box open: the Non-Reclose switch at ON, the Hot Line
        # Tag hung on it; nobody up the pole yet.
        out = closeup_stage('ON', False)
        out.append(f'<circle cx="62" cy="150" r="6.5" fill="{GLOVE}"/>')
        out.append(f'<path d="M66 154 Q80 190 92 {H + 4}" stroke="{SHIRT}" stroke-width="11" stroke-linecap="round" fill="none"/>')
    elif kind == 'earth':
        # Non-Reclose confirmed and the PTW pinned at the foot of the pole;
        # tester at 0; earths on both sides of the work; then up in the
        # harness.
        out = nonrec_stage(climb=True)
        out.append(earth_set(54, [y + 4 for y in N_LINE]))
        out.append(earth_set(140, [y + 4 for y in N_LINE]))
        out.append(tester(N_P - 24, GY - 26, '0', 0.5))
        out.append(sheet(N_P + 6, GY - 22, 1.0))
        out.append(radio(N_P + 26, GY - 8))
    elif kind == 'dark':
        # The houses went dark — so up he goes: no earth (the set lies
        # coiled on the ground), the radio on the ground unused.
        out = nonrec_stage(climb=True)
        out.append(earth_coil(60, GY - 2))
        out.append(radio(N_P + 26, GY - 8))
    elif kind == 'handle':
        # The handle hangs down (lock-out) — he climbs: no PTW, no Non-Reclose.
        out = nonrec_stage(handle_down=True, climb=True)
        out.append(tester(N_P - 24, GY - 26, '0', 0.5))
    elif kind == 'auto':
        # The switch left at OFF (auto reclose on), no tag — and a man up the pole.
        out = closeup_stage('OFF', True)
        out.append(sheet(70, 172, 1.0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — pro: in front of the recloser. The pole with R (big) and its
# control box; S-1 on a branch pole to the right; houses.
# --------------------------------------------------------------------------

R_P = 62
R_S = 168


def pro_stage(handle_down=False, lit=True, door=False, screen=''):
    out = card_open('day')
    out.append(ground())
    out.append(pole(R_P, 12, GY, 9))
    out.append(f'<rect x="{R_P - 18}" y="18" width="36" height="4" rx="1" fill="url(#chan)"/>')
    out.append(conductors((24, 30, 36), sag=4))
    out.append(f'<path d="M{R_P + 6} 26 L{R_P + 6} 48 M{R_P + 30} 32 L{R_P + 30} 48" stroke="{WIRE}" stroke-width="1"/>')
    out.append(recloser(R_P + 18, 56, 1.5, handle_down, counter='27'))
    out.append(control_box(R_P, 120, -1, 1.3, door=door, screen=screen))
    out.append(pole(R_S, 22, GY, 6))
    out.append(f'<path d="M{R_S} 34 L{R_S + 6} 50" stroke="{WIRE}" stroke-width="1"/>')
    out.append(sectionalizer(R_S + 12, 58, 'S-1', 0.75, 'closed'))
    out.append(f'<path d="M{R_S + 20} 54 Q{R_S + 24} 100 {R_S + 14} 132" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    out.append(house(150, GY - 4, 40, 54, lit))
    return out


def pro_card(kind):
    if kind == 'counter':
        # Close under the recloser, reading its operation counter.
        out = pro_stage()
        out.append(person(104, ((112, 128), (96, 150)), face=-1, look=-30, front=clipboard(90, 140, 0.8)))
    elif kind == 'handle':
        # From well back: the handle hangs down — lock-out, houses dark.
        out = pro_stage(handle_down=True, lit=False)
        out.append(person(124, ((118, 120), (130, 150)), face=-1, look=-22))
    elif kind == 'setting':
        # The control box open, reading the setting on its screen.
        out = pro_stage(door=True, screen='3')
        out.append(person(88, ((60, 146), (76, 152)), face=-1, look=-4))
    elif kind == 'manual':
        # The manual handle pulled down with a hook stick — on a live line.
        out = pro_stage()
        out.append(person(110, ((104, 150), (100, 140)), face=-1, look=-30,
                          front=hook_stick(102, 146, R_P + 40, 82)))
        out.append(motion(R_P + 44, 92, 0, 1, 3, 7))
    elif kind == 'deadonly':
        # The houses are dark, the handle still up — and 'lock-out' goes in
        # the book.
        out = pro_stage(lit=False)
        out.append(person(110, ((100, 150), (92, 146)), face=-1, look=4, front=clipboard(82, 136, 0.8)))
    elif kind == 'wait':
        # A branch on the S-1 line (a fault); he stands right under S-1,
        # waiting for it to blow like a fuse.
        out = pro_stage(lit=False)
        out.append(branch(196, 100, R_S + 22, 96))
        out.append(spark(R_S + 22, 96, 8))
        out.append(person(R_S - 6, ((R_S - 2, 128), (R_S - 12, 150)), face=1, look=-34))
    return card_close(out)


CARDS = {}
for k in ('trip', 'wind', 'patrol', 'lock1', 'sopen'):
    CARDS[f'temp_{k}'] = temp_card(k)
for k in ('s1', 's3', 'endless', 'wrongs', 'alldark'):
    CARDS[f'perm_{k}'] = perm_card(k)
for k in ('one', 'dead', 'arc', 'self', 'first', 'melt'):
    CARDS[f'count_{k}'] = count_card(k)
for k in ('radio', 'switch', 'earth', 'dark', 'handle', 'auto'):
    CARDS[f'nonrec_{k}'] = nonrec_card(k)
for k in ('counter', 'handle', 'setting', 'manual', 'deadonly', 'wait'):
    CARDS[f'pro_{k}'] = pro_card(k)

# Safe cards and traps per round (mirrors learn_board_pack68.dart).
ROUNDS = {
    'temp': (['temp_trip', 'temp_wind'], ['temp_patrol', 'temp_lock1', 'temp_sopen']),
    'perm': (['perm_s1', 'perm_s3'], ['perm_endless', 'perm_wrongs', 'perm_alldark']),
    'count': (['count_one', 'count_dead'], ['count_arc', 'count_self', 'count_first', 'count_melt']),
    'nonrec': (['nonrec_radio', 'nonrec_switch', 'nonrec_earth'], ['nonrec_dark', 'nonrec_handle', 'nonrec_auto']),
    'pro': (['pro_counter', 'pro_handle', 'pro_setting'], ['pro_manual', 'pro_deadonly', 'pro_wait']),
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
