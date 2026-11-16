"""Picture cards for lesson 7.7 শেখা ("দুর্ঘটনার রিপোর্ট: আপনার দায়িত্ব").

python -I -X utf8 tool/m7_board77_art.py .

Writes assets/game/art/m7_board77/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; nothing a worker would read is drawn as text (a note's lines are
icons: a calendar, a clock, digits drawn as strokes).

What the cards show comes from lesson 7.7 (live text, today's corrected
version) and the Module 7 rulings (docs/module_specs/module7_rulings.md,
item spec docs/module_specs/module7_items/board_77.json). Five rounds (ruling
X6: the spec's six rounds are trimmed; the small-shock/doctor round folds
into the duty round):
  1. must: which accidents are reportable (Electricity Act s.161) - a dead
     cow by a fallen service wire (drawn without gore), a burnt DTR, a
     colleague three days in bed. Traps: walking away from the cow, locking
     the gate on the DTR fire, the register saying 'on leave';
  2. duty: what the lineman does at once - phone the supervisor; take the
     shocked colleague to the doctor and tell the supervisor. Traps: going
     home to tell tomorrow, 'the company's job', settling it among the crew,
     tea and back up the pole after a 'small shock';
  3. note: the supervisor's note - date, time, pole, the injured man; how it
     happened, the injury, who saw. Traps: vague, 'nobody hurt' beside a
     bandaged hand, a blown-up account of one burnt glove;
  4. scene: the place after an accident - left as it was (crew waits by the
     van); a flaring ember by an oil drip covered with sand (a danger
     stopped). Traps: ladder stood up and tools packed, a new fuse in the
     scorched pillar, burnt pieces swept into a sack;
  5. near: a near miss, nobody hurt - the spanner fell beside the helper;
     told to the safety department / a short written note. Traps: laughed
     off, 'only big accidents' board, hunting for someone to blame.

Fairness (the playbook, section 4): the script checks every hand the dealer
can make (one safe card + any three traps): each colour or gradient the safe
card draws is drawn by a trap in that hand, and the safe card's backdrop is
a trap's backdrop too. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I -X utf8 tool/m7_board77_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board77')
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
RED = '#D8402F'
GREEN = '#3E9B4F'
BRASS = '#C9A43A'
METER_Y = '#F2B630'
GOGGLE = '#8FD0EE'
SUN = '#FFE08A'
SMOKE = '#7A848C'
MOVE = '#FFFFFF'
SOOT = '#3A3F45'
FLAME = '#F28C28'
SAND = '#D9C28A'
WOOD = '#8A6A44'
WALL = '#E8E2D2'
BLANKET = '#8FB8CC'
COW_W = '#EDE9DD'

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
  <linearGradient id="ceramic" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9D3C6"/><stop offset="0.45" stop-color="#FAF8F2"/><stop offset="1" stop-color="#C8C1B2"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def tag(name):
    """An XML comment naming a prop or figure on the card. The fairness check
    (here and in test/learn_board_77_test.dart) reads these: no prop may sit
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
# People (the worker from tool/m6_board63_art.py).
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
    return tag('lineman') + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'

def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def sun(x=168, y=30):
    return (f'<circle cx="{x}" cy="{y}" r="20" fill="url(#glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="8" fill="{SUN}"/>')


def cloud(x, y, s=1.0):
    return (tag('cloud') + f'<g fill="#FFFFFF" opacity="0.75"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(16 * s)}" ry="{f(6 * s)}"/>'
            f'<ellipse cx="{f(x + 8 * s)}" cy="{f(y - 4 * s)}" rx="{f(9 * s)}" ry="{f(6 * s)}"/></g>')


def motion(x, y, dx=0, dy=-1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'




# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def ground():
    return f'<rect x="0" y="{GY - 8}" width="{W}" height="{H - GY + 8}" fill="url(#ground)"/>'


def idle_hands(x, s, face=1, gy=GY):
    return ((x - 6 * face * s, gy - 34 * s), (x + 6 * face * s, gy - 34 * s))


def phone(x, y, rot=0):
    return (tag('phone') + f'<g transform="rotate({f(rot)} {f(x)} {f(y)})"><rect x="{f(x - 3)}" y="{f(y - 6)}" width="6" height="11" rx="1.5" fill="{BOOT}"/>'
            f'<rect x="{f(x - 2)}" y="{f(y - 4.5)}" width="4" height="7" fill="{SHIRT_D}"/></g>')


def talker(x, s=1.2, face=1, gy=GY):
    """A lineman with a phone at his ear."""
    hx, hy = x + 3 * face * s, gy - 64 * s
    hand = (hx + 9 * face * s, hy + 3)
    return (person(x, ((x - 6 * face * s, gy - 34 * s), hand), face, 0, gy, True, False, s)
            + phone(hand[0] + 1 * face, hand[1] - 2, 8 * face))


def smoke(x, y):
    return (f'<g fill="{SMOKE}" opacity="0.8"><circle cx="{f(x)}" cy="{f(y)}" r="5"/><circle cx="{f(x + 4)}" cy="{f(y - 8)}" r="6"/>'
            f'<circle cx="{f(x - 2)}" cy="{f(y - 17)}" r="7"/></g>')


def glint(x, y):
    return f'<path d="M{f(x - 3)} {f(y)} h6 M{f(x)} {f(y - 3)} v6" stroke="{MOVE}" stroke-width="1.2" stroke-linecap="round"/>'


def cow(x, y):
    """A cow lying on its side (nothing gory): white with brown patches."""
    o = [tag('cow'),
         f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="28" ry="12" fill="{COW_W}"/>',
         f'<ellipse cx="{f(x + 6)}" cy="{f(y - 3)}" rx="9" ry="6" fill="{BAG}"/>',
         f'<ellipse cx="{f(x - 14)}" cy="{f(y + 3)}" rx="6" ry="4" fill="{BAG}"/>',
         f'<ellipse cx="{f(x - 31)}" cy="{f(y + 5)}" rx="9" ry="7" fill="{COW_W}"/>',
         f'<path d="M{f(x - 38)} {f(y + 1)} l-5 -3 l2 6 Z" fill="{BAG}"/>',
         f'<path d="M{f(x - 34)} {f(y + 4)} h4" stroke="{HAIR}" stroke-width="1.2" stroke-linecap="round"/>']
    for dx in (-12, -3, 8, 17):
        o.append(f'<path d="M{f(x + dx)} {f(y + 10)} l{f(dx / 8 + 2)} 9" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    return ''.join(o)


def pole_set(x, top=26):
    return tag('pole') + pole(x, top) + f'<rect x="{f(x - 16)}" y="{top + 6}" width="32" height="4" rx="1" fill="url(#chan)"/>'


def fallen_wire(px, py, ex, ey):
    """A service wire down from the pole's cross-arm to the ground."""
    return (tag('wire') + f'<path d="M{f(px)} {f(py)} Q{f(px - 10)} {f((py + ey) / 2 + 20)} {f(ex)} {f(ey)} q-14 6 -30 2" stroke="{WIRE}" '
            'stroke-width="1.8" fill="none" stroke-linecap="round"/>')


def tank_dtr(x, y, soot=True):
    """A DTR on its platform (tank, three bushings); scorched when [soot]."""
    o = [tag('dtr'), f'<rect x="{f(x - 6)}" y="{f(y + 36)}" width="72" height="5" fill="url(#chan)"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="60" height="36" rx="4" fill="url(#tank)"/>']
    for i in range(3):
        o.append(f'<rect x="{f(x + 8 + i * 18)}" y="{f(y - 9)}" width="6" height="10" fill="url(#porc)"/>')
    if soot:
        o.append(f'<ellipse cx="{f(x + 22)}" cy="{f(y + 14)}" rx="20" ry="12" fill="{SOOT}" opacity="0.75"/>')
        o.append(f'<ellipse cx="{f(x + 44)}" cy="{f(y + 6)}" rx="10" ry="6" fill="{SOOT}" opacity="0.6"/>')
        o.append(smoke(x + 26, y - 14))
    return ''.join(o)


def clipboard(x, y, s=1.0, tick=True):
    o = [tag('clipboard'), f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(34 * s)}" rx="2" fill="{BAG}"/>',
         f'<rect x="{f(x + 3 * s)}" y="{f(y + 5 * s)}" width="{f(20 * s)}" height="{f(26 * s)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + 9 * s)}" y="{f(y + 2 * s)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="url(#steel)"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 6 * s)} {f(y + (12 + i * 6) * s)} h{f(10 * s)}" stroke="{INK}" stroke-width="0.8"/>')
    if tick:
        o.append(f'<path d="M{f(x + 13 * s)} {f(y + 23 * s)} l{f(3 * s)} {f(4 * s)} l{f(6 * s)} {f(-9 * s)}" stroke="{GREEN}" stroke-width="{f(2 * s)}" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def calendar(x, y, crossed=3):
    """A tear-off wall calendar: a red header, a grid of days, [crossed] of
    them struck out in red."""
    o = [tag('calendar'), f'<rect x="{f(x)}" y="{f(y)}" width="44" height="50" rx="3" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="44" height="10" rx="3" fill="{RED}"/>']
    for r in range(3):
        for c in range(4):
            gx, gy = x + 5 + c * 9, y + 16 + r * 10
            o.append(f'<rect x="{f(gx)}" y="{f(gy)}" width="6" height="6" fill="none" stroke="{INK}" stroke-width="0.6"/>')
    for i in range(crossed):
        gx, gy = x + 5 + i * 9, y + 16
        o.append(f'<path d="M{f(gx - 1)} {f(gy - 1)} l8 8 M{f(gx + 7)} {f(gy - 1)} l-8 8" stroke="{RED}" stroke-width="1.6" stroke-linecap="round"/>')
    return ''.join(o)


def van(x, y, s=1.0):
    o = [tag('van'), f'<rect x="{f(x)}" y="{f(y)}" width="{f(54 * s)}" height="{f(26 * s)}" rx="{f(4 * s)}" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{f(x + 36 * s)}" y="{f(y + 4 * s)}" width="{f(14 * s)}" height="{f(10 * s)}" rx="1.5" fill="{GOGGLE}"/>',
         f'<rect x="{f(x)}" y="{f(y + 17 * s)}" width="{f(54 * s)}" height="{f(3 * s)}" fill="{HELMET}"/>',
         f'<circle cx="{f(x + 12 * s)}" cy="{f(y + 27 * s)}" r="{f(5 * s)}" fill="{WIRE}"/>',
         f'<circle cx="{f(x + 42 * s)}" cy="{f(y + 27 * s)}" r="{f(5 * s)}" fill="{WIRE}"/>']
    return ''.join(o)


def ladder(x0, y0, x1, y1, w=9):
    """A wooden ladder from (x0, y0) to (x1, y1)."""
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * w / 2, dx / n * w / 2
    o = [tag('ladder'), f'<path d="M{f(x0 - px)} {f(y0 - py)} L{f(x1 - px)} {f(y1 - py)} M{f(x0 + px)} {f(y0 + py)} L{f(x1 + px)} {f(y1 + py)}" '
         f'stroke="{WOOD}" stroke-width="2.2" stroke-linecap="round"/>']
    for i in range(1, 6):
        t = i / 6
        cx, cy = x0 + dx * t, y0 + dy * t
        o.append(f'<path d="M{f(cx - px)} {f(cy - py)} L{f(cx + px)} {f(cy + py)}" stroke="{WOOD}" stroke-width="1.6"/>')
    return ''.join(o)


def spanner(x, y, rot=0, s=1.0):
    return (tag('spanner') + f'<g transform="rotate({f(rot)} {f(x)} {f(y)}) translate({f(x)} {f(y)}) scale({s})">'
            f'<path d="M-12 -1.6 L9 -1.6 L9 1.6 L-12 1.6 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>'
            f'<circle cx="11" cy="0" r="4.2" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>'
            f'<circle cx="-13" cy="0" r="3.6" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/></g>')


def mouth_open(x, y):
    return f'<path d="M{f(x - 3)} {f(y)} q3 6 6 0 Z" fill="{HAIR}"/>'


def pen(x, y, rot=-20):
    return (tag('pen') + f'<g transform="rotate({f(rot)} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 1.5)}" width="22" height="3" rx="1.4" fill="{RED}"/>'
            f'<rect x="{f(x + 22)}" y="{f(y - 1)}" width="4" height="2" fill="{BRASS}"/></g>')


# --------------------------------------------------------------------------
# Round 1 - must: which accidents are reportable.
# --------------------------------------------------------------------------

def outdoor(back='day'):
    out = card_open(back)
    out.append(ground())
    return out


def cow_scene():
    out = outdoor()
    out.append(cloud(52, 32, 1.1))
    out.append(pole_set(158))
    out.append(fallen_wire(158, 34, 112, 188))
    out.append(cow(96, 178))
    return out


def must_card(kind):
    if kind == 'cow':
        # The lineman keeps well back from the fallen wire and phones his
        # supervisor at once.
        out = cow_scene()
        out.append(talker(32, 1.0, 1))
    elif kind == 'walk':
        # The crew walks away from the dead cow, a phone dangling unused.
        out = cow_scene()
        out.append(person(34, idle_hands(34, 1.0, -1), -1, 4, GY, True, False, 1.0))
        out.append(person(62, idle_hands(62, 1.0, -1), -1, 4, GY, True, False, 1.0))
        out.append(phone(55, 164, 12))
        out.append(motion(78, 150, 1, 0, 3, 8))
    elif kind in ('dtr', 'gate'):
        # The burnt DTR; the crew phones the control room (dtr), or the fire
        # is out and the crew quietly locks the gate (gate).
        out = outdoor()
        out.append(cloud(52, 32, 1.1))
        out.append(pole_set(120, 30))
        out.append(tank_dtr(88, 84))
        out.append('<rect x="116" y="124" width="8" height="74" fill="url(#pole)"/>')
        if kind == 'dtr':
            out.append(talker(40, 1.2, 1))
        else:
            out.append(tag('gate') + '<path d="M20 120 V198 M84 120 V198 M20 130 H84 M20 160 H84 M52 120 V198" stroke="url(#chan)" stroke-width="3" fill="none"/>')
            out.append(tag('padlock') + '<path d="M62 160 v-4 a3 3 0 0 1 6 0 v4" stroke="url(#steel)" stroke-width="1.8" fill="none"/>'
                       f'<rect x="60" y="160" width="10" height="8" rx="1.5" fill="{HELMET_D}"/>')
            out.append(glint(74, 156))
            out.append(person(150, ((144, 160), (158, 156)), -1, 0, GY, True, False, 1.1))
            out.append(phone(161, 160, 14))
    else:
        # Indoors: a colleague in a hospital bed with three days crossed off;
        # the supervisor with his board (the tick, or a beach umbrella for
        # "on leave") and his phone on the bed.
        out = card_open('day')
        out.append(f'<rect x="0" y="0" width="{W}" height="{H}" fill="{WALL}"/>')
        out.append(f'<rect x="0" y="176" width="{W}" height="44" fill="{WOOD}"/>')
        out.append(calendar(138, 40, 3))
        out.append(tag('bed') + '<rect x="20" y="140" width="110" height="9" rx="3" fill="url(#chan)"/>')
        out.append('<rect x="22" y="148" width="5" height="30" fill="url(#chan)"/><rect x="123" y="148" width="5" height="30" fill="url(#chan)"/>')
        out.append(f'<rect x="26" y="122" width="98" height="20" rx="7" fill="{BLANKET}"/>')
        out.append(f'<rect x="26" y="118" width="28" height="12" rx="6" fill="{PAPER}"/>')
        out.append(f'<circle cx="40" cy="120" r="9" fill="{SKIN}"/><path d="M31 117 Q40 108 49 117" fill="{HAIR}"/>')
        out.append(phone(100, 122, -70))
        out.append(person(166, ((156, 150), (150, 136)), -1, 0, GY, True, False, 1.0))
        if kind == 'bed':
            out.append(clipboard(128, 122, 0.9, tick=False))
            out.append(pen(122, 130, -35))
        else:  # leave: the board says "on leave" (a beach umbrella)
            out.append(clipboard(128, 122, 0.9, tick=False))
            out.append(tag('umbrella') + f'<path d="M137 150 L137 138" stroke="{INK}" stroke-width="1.2"/>'
                       f'<path d="M130 140 Q137 130 144 140 Z" fill="{RED}"/>')
            out.append(pen(122, 130, -35))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 - duty: what the lineman does at once.
# --------------------------------------------------------------------------

def yard():
    """The duty round's common stage: the clinic down the road and the pole."""
    out = card_open('yard')
    out.append(ground())
    out.append(pole_set(22, 44))
    out.append(tag('clinic') + f'<rect x="132" y="126" width="62" height="64" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>'
               f'<rect x="126" y="118" width="74" height="10" fill="{INK}"/>'
               f'<rect x="156" y="144" width="14" height="46" fill="{GOGGLE}"/>'
               f'<path d="M163 130 v12 M157 136 h12" stroke="{RED}" stroke-width="4"/>')
    return out


def colleague(x, mode='seat', y=150):
    """The colleague who took a small shock: a bandaged hand. Seated on a
    crate (mode 'seat') or standing (mode 'stand')."""
    if mode == 'seat':
        o = [tag('lineman'), f'<rect x="{f(x - 12)}" y="{f(y + 14)}" width="24" height="16" rx="2" fill="{PANTS_D}"/>',
             f'<rect x="{f(x - 9)}" y="{f(y - 14)}" width="18" height="30" rx="6" fill="{SHIRT}"/>',
             f'<circle cx="{f(x)}" cy="{f(y - 22)}" r="8" fill="{SKIN}"/>',
             f'<path d="M{f(x - 8)} {f(y - 24)} A8 8 0 0 1 {f(x + 8)} {f(y - 24)} Z" fill="{HELMET}"/>',
             f'<rect x="{f(x - 11)}" y="{f(y + 12)}" width="22" height="9" rx="3" fill="{PANTS}"/>',
             f'<circle cx="{f(x + 8)}" cy="{f(y + 8)}" r="3" fill="{SKIN}"/>',
             tag('bandage') + f'<rect x="{f(x + 4)}" y="{f(y + 4)}" width="9" height="5" rx="2" fill="{PAPER}"/>']
        return ''.join(o)
    return (person(x, ((x - 6, GY - 36), (x + 8, GY - 38)), 1, 0, GY, True, False, 1.2)
            + tag('bandage') + f'<rect x="{f(x + 3)}" y="{f(GY - 46)}" width="9" height="5" rx="2" fill="{PAPER}"/>')





def duty_card(kind):
    if kind == 'call':
        # He phones the supervisor at once; the colleague sits, hand bandaged.
        out = yard()
        out.append(talker(62, 1.3, 1))
        out.append(colleague(110))
    elif kind == 'doc':
        # He phones the supervisor while walking the colleague to the clinic.
        out = yard()
        out.append(talker(56, 1.2, 1))
        out.append(colleague(98, 'stand'))
        out.append(motion(118, 160, 1, 0, 3, 8))
    elif kind == 'home':
        # Packs up and goes home: 'I will tell them at the office tomorrow';
        # his phone stays on his belt.
        out = yard()
        out.append(tag('bag') + f'<rect x="76" y="140" width="22" height="26" rx="3" fill="{BAG}"/>')
        out.append(person(62, ((54, 150), (74, 150)), -1, 0, GY, True, False, 1.3))
        out.append(phone(70, 156, 10))
        out.append(motion(40, 150, -1, 0, 3, 9))
        out.append(colleague(112))
    elif kind == 'comp':
        # 'Reporting is the company's job, not mine': hands open, shrugging;
        # his phone lies on the ground.
        out = yard()
        out.append(person(62, ((32, 108), (92, 108)), 1, 0, GY, True, False, 1.3))
        out.append(tag('qmark') + f'<path d="M64 44 q-6 -8 0 -14 q8 -2 8 6 q0 6 -8 8 M66 52 v1" stroke="{INK}" stroke-width="2" fill="none" stroke-linecap="round"/>')
        out.append(phone(96, 190, -70))
        out.append(colleague(112))
    elif kind == 'huddle':
        # 'Let us settle it among ourselves': a closed huddle of three.
        out = yard()
        out.append(person(40, ((32, 150), (62, 118)), 1, 6, GY, True, False, 1.1))
        out.append(person(82, ((74, 150), (98, 130)), -1, 0, GY, True, False, 1.1))
        out.append(phone(76, 158, 12))
        out.append(colleague(112))
        out.append(f'<path d="M72 70 q-6 -4 0 -9 M80 70 q6 -4 0 -9" stroke="{INK}" stroke-width="2" fill="none" stroke-linecap="round"/>')
    else:  # tea
        # A cup of tea, then back up the ladder after a 'small shock'.
        out = yard()
        out.append(ladder(34, 198, 24, 60))
        out.append(person(70, ((60, 150), (90, 108)), 1, -8, GY, True, False, 1.3))
        out.append(tag('cup') + f'<rect x="88" y="100" width="10" height="9" rx="2" fill="{COPPER}"/><path d="M98 103 q4 1 0 5" stroke="{COPPER}" stroke-width="1.4" fill="none"/>'
                   f'<path d="M91 96 q-2 -3 0 -6 M95 96 q-2 -3 0 -6" stroke="{MOVE}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')
        out.append(phone(104, 190, -80))
        out.append(colleague(112))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 - note: the supervisor's note.
# --------------------------------------------------------------------------

def desk(note_x=36):
    out = card_open('bench')
    out.append(tag('paper') + f'<rect x="{note_x}" y="40" width="128" height="150" rx="4" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>')
    out.append(f'<rect x="{note_x}" y="40" width="128" height="12" rx="4" fill="{INK}" opacity="0.18"/>')
    # the desk's things: a pen, a pencil, a brass clip, a mug
    out.append(pen(150, 196, -8))
    out.append(f'<rect x="12" y="188" width="22" height="3" rx="1.4" fill="{METER_Y}"/>')
    out.append(f'<path d="M168 44 v-8 a4 4 0 0 1 8 0 v10" stroke="{BRASS}" stroke-width="2" fill="none"/>')
    out.append(f'<rect x="8" y="150" width="20" height="22" rx="3" fill="{COPPER}"/><path d="M28 156 q7 0 0 10" stroke="{COPPER}" stroke-width="2" fill="none"/>')
    return out


def icon_cal(x, y):
    return (tag('cal') + f'<rect x="{f(x)}" y="{f(y)}" width="16" height="16" rx="2" fill="none" stroke="{INK}" stroke-width="1.2"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="16" height="5" rx="2" fill="{RED}"/>'
            f'<path d="M{f(x + 4)} {f(y + 9)} h8 M{f(x + 4)} {f(y + 12.5)} h8" stroke="{INK}" stroke-width="1"/>')


def icon_clock(x, y):
    return (tag('clock') + f'<circle cx="{f(x + 8)}" cy="{f(y + 8)}" r="8" fill="none" stroke="{BRASS}" stroke-width="1.8"/>'
            f'<path d="M{f(x + 8)} {f(y + 8)} v-5 M{f(x + 8)} {f(y + 8)} l4 3" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')


def icon_pole(x, y):
    return (tag('polei') + f'<path d="M{f(x + 8)} {f(y)} v16" stroke="{INK}" stroke-width="2.4"/>'
            f'<path d="M{f(x + 1)} {f(y + 4)} h14" stroke="{INK}" stroke-width="1.6"/>')


def icon_person(x, y):
    return (tag('personi') + f'<circle cx="{f(x + 8)}" cy="{f(y + 4)}" r="4" fill="{SKIN}"/>'
            f'<path d="M{f(x + 1)} {f(y + 16)} q0 -8 7 -8 q7 0 7 8 Z" fill="{SHIRT}"/>')


def icon_house(x, y):
    return (tag('house') + f'<path d="M{f(x)} {f(y + 8)} L{f(x + 8)} {f(y)} L{f(x + 16)} {f(y + 8)} V{f(y + 16)} H{f(x)} Z" fill="none" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>'
            f'<rect x="{f(x + 6)}" y="{f(y + 10)}" width="4" height="6" fill="{INK}"/>')


def icon_hand(x, y):
    return (tag('handi') + f'<circle cx="{f(x + 8)}" cy="{f(y + 8)}" r="7" fill="{SKIN}"/>'
            f'<rect x="{f(x + 1)}" y="{f(y + 5)}" width="14" height="5" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 6)} {f(y + 5)} v5 M{f(x + 10)} {f(y + 5)} v5" stroke="{RED}" stroke-width="0.8"/>')


def icon_eye(x, y):
    return (tag('eye') + f'<path d="M{f(x)} {f(y + 8)} Q{f(x + 8)} {f(y)} {f(x + 16)} {f(y + 8)} Q{f(x + 8)} {f(y + 16)} {f(x)} {f(y + 8)} Z" fill="none" stroke="{INK}" stroke-width="1.4"/>'
            f'<circle cx="{f(x + 8)}" cy="{f(y + 8)}" r="3" fill="{INK}"/>')


def icon_fall(x, y):
    return (tag('fall') + f'<path d="M{f(x + 4)} {f(y)} v10" stroke="{RED}" stroke-width="1.6" stroke-linecap="round"/>'
            f'<path d="M{f(x + 1)} {f(y + 7)} l3 5 l3 -5" stroke="{RED}" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(x + 8)} {f(y + 14)} h8" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>')


def lines(x, y, n, w=70, gap=6):
    d = ' '.join(f'M{f(x)} {f(y + i * gap)} h{f(w - (i % 2) * 14)}' for i in range(n))
    return tag('lines') + f'<path d="{d}" stroke="{INK}" stroke-width="1.4" stroke-linecap="round" opacity="0.7"/>'


def digits_on(x, y):
    return (tag('digits') + f'<path d="M{f(x)} {f(y)} h5 v5 h-5 v5 h5 M{f(x + 8)} {f(y)} v10 M{f(x + 8)} {f(y)} h5 v10 h-5 Z" stroke="{INK}" '
            'stroke-width="1.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')


def note_card(kind):
    out = desk()
    nx = 36
    if kind == 'when':
        for i, ic in enumerate((icon_cal, icon_clock, icon_pole)):
            out.append(ic(nx + 10, 62 + i * 26))
            out.append(digits_on(nx + 36, 65 + i * 26))
        out.append(icon_person(nx + 10, 142))
        out.append(lines(nx + 36, 148, 2, 70, 6))
        out.append(icon_house(nx + 10, 166))
        out.append(lines(nx + 36, 172, 2, 70, 6))
    elif kind == 'how':
        out.append(icon_fall(nx + 12, 62))
        out.append(lines(nx + 36, 68, 2, 70, 6))
        out.append(icon_hand(nx + 10, 94))
        out.append(lines(nx + 36, 100, 2, 70, 6))
        out.append(icon_eye(nx + 10, 124))
        out.append(icon_person(nx + 34, 122))
        out.append(lines(nx + 58, 130, 2, 56, 6))
        out.append(lines(nx + 10, 152, 3, 100, 8))
    elif kind == 'vague':
        out.append(lines(nx + 12, 66, 3, 100, 10))
        out.append(tag('qmark') + f'<path d="M80 110 q0 -14 20 -14 q20 0 20 14 q0 10 -20 16 v10 M100 150 v0.5" stroke="{RED}" stroke-width="5" fill="none" stroke-linecap="round"/>')
    elif kind == 'hide':
        out.append(icon_person(nx + 10, 62))
        out.append(tag('tick') + f'<path d="M{nx + 30} 74 l6 7 l12 -16" stroke="{GREEN}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
        out.append(lines(nx + 58, 70, 2, 56, 6))
        out.append(lines(nx + 12, 100, 3, 100, 10))
        out.append(icon_house(nx + 10, 140) + icon_cal(nx + 34, 140) + icon_clock(nx + 58, 140) + digits_on(nx + 82, 143))
        out.append(tag('handi') + f'<circle cx="150" cy="170" r="14" fill="{SKIN}"/><rect x="136" y="164" width="28" height="9" rx="4" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>'
                   f'<path d="M144 164 v9 M152 164 v9" stroke="{RED}" stroke-width="1"/>')
    else:  # over
        out.append(tag('flame') + f'<path d="M100 62 l8 18 l16 -10 l-6 20 l18 4 l-18 8 l8 16 l-18 -8 l-8 18 l-6 -18 l-18 4 l12 -14 l-14 -10 l18 0 Z" fill="{FLAME}" stroke="{RED}" stroke-width="2" stroke-linejoin="round"/>')
        out.append(f'<path d="M52 66 v14 M52 86 v0.5 M148 66 v14 M148 86 v0.5" stroke="{RED}" stroke-width="3.4" stroke-linecap="round"/>')
        out.append(lines(nx + 12, 150, 3, 100, 8))
        out.append(icon_pole(nx + 10, 124) + icon_eye(nx + 34, 126) + icon_fall(nx + 58, 124) + digits_on(nx + 82, 127))
        out.append(tag('glove') + f'<path d="M140 176 q-4 -14 4 -18 q4 8 10 4 q6 4 4 14 q-8 6 -18 0 Z" fill="{GLOVE}"/>'
                   f'<ellipse cx="148" cy="172" rx="5" ry="3" fill="{SOOT}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 - scene: the place after an accident.
# --------------------------------------------------------------------------

def site(extra=''):
    """The scorched feeder pillar with the crew's van behind and a sand bucket."""
    out = card_open('yard')
    out.append(ground())
    out.append(van(124, 118, 0.9))
    out.append(tag('pillar') + f'<rect x="76" y="92" width="40" height="76" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<ellipse cx="96" cy="120" rx="15" ry="22" fill="{SOOT}" opacity="0.7"/>')
    out.append(f'<path d="M86 138 q4 -10 8 0 q4 -8 8 2" stroke="{FLAME}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    out.append(f'<path d="M76 92 L116 92" stroke="{INK}" stroke-width="0.8"/>')
    out.append(tag('sand') + f'<path d="M60 186 h10 l-2 12 h-6 Z" fill="{SAND}"/><path d="M60 186 h10" stroke="{INK}" stroke-width="1"/>')
    out.append(tag('oil') + f'<ellipse cx="38" cy="194" rx="16" ry="4" fill="{SOOT}"/>')
    out.append(extra)
    return out


def tool_bag(x, y):
    return tag('bag') + f'<rect x="{x}" y="{y}" width="16" height="10" rx="2" fill="{BAG}"/>'


def scene_card(kind):
    if kind == 'asis':
        # Everything left as it was: ladder on the ground, tools where they
        # fell; the crew waits by the van.
        out = site(tool_bag(8, 188))
        out.append(ladder(10, 176, 52, 184))
        out.append(spanner(80, 196, 8, 0.9))
        out.append(person(132, idle_hands(132, 0.8, 1), 1, 0, GY, True, False, 0.8))
        out.append(person(156, idle_hands(156, 0.8, -1), -1, 0, GY, True, False, 0.8))
    elif kind == 'sand':
        # A flaring ember by the oil drip, put out with sand (a danger
        # stopped); the rest of the place untouched.
        out = site(tool_bag(8, 188))
        out.append(f'<path d="M34 192 q2 -8 5 0 q3 -5 5 1 Z" fill="{FLAME}"/>')
        out.append(f'<path d="M22 196 q14 -16 32 0 Z" fill="{SAND}"/>')
        out.append(tag('shovel') + f'<path d="M64 150 L48 184" stroke="{WOOD}" stroke-width="2.6" stroke-linecap="round"/>'
                   '<path d="M44 182 l10 8 l-12 2 Z" fill="url(#steel)"/>')
        out.append(person(136, ((120, 150), (80, 152)), -1, 8, GY, True, False, 1.0))
    elif kind == 'ladder':
        # The ladder stood up and the tools packed into the bag.
        out = site(tool_bag(124, 188))
        out.append(ladder(20, 198, 40, 80))
        out.append(person(150, ((140, 160), (130, 150)), -1, 0, GY, True, False, 1.0))
        out.append(spanner(80, 196, 0, 0.8))
    elif kind == 'fuse':
        # A new fuse fitted in the scorched pillar.
        out = site(tool_bag(8, 188))
        out.append(tag('fuse') + f'<rect x="84" y="98" width="24" height="14" rx="2" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(person(50, ((60, 140), (78, 112)), 1, -6, GY, True, False, 1.1))
    else:  # sweep
        # The burnt pieces swept up into a sack.
        out = site(tag('sack') + f'<rect x="8" y="170" width="24" height="28" rx="5" fill="{BAG}"/>')
        out.append(f'<path d="M64 196 q4 -4 8 0 M74 198 q4 -3 7 0" stroke="{SOOT}" stroke-width="3" stroke-linecap="round"/>')
        out.append(tag('shovel') + f'<path d="M118 120 L90 192" stroke="{WOOD}" stroke-width="2.6" stroke-linecap="round"/>'
                   '<path d="M80 192 l16 -2 l-2 8 h-14 Z" fill="url(#steel)"/>')
        out.append(person(138, ((128, 150), (110, 150)), -1, 8, GY, True, False, 1.1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 - near: nobody hurt, one step from it.
# --------------------------------------------------------------------------

def near_base():
    out = outdoor()
    out.append(cloud(60, 34, 1.0))
    out.append(pole_set(176, 30))
    out.append(ladder(166, 198, 174, 90))
    # the helper and the spanner that fell beside him
    out.append(person(136, idle_hands(136, 1.0, -1), -1, -6, GY, True, False, 1.0))
    out.append(spanner(112, 194, 12, 1.0))
    out.append(f'<path d="M112 168 v14 M108 176 l4 6 l4 -6" stroke="{MOVE}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    return out


def near_card(kind):
    out = near_base()
    if kind == 'tell':
        out.append(talker(50, 1.2, 1))
    elif kind == 'write':
        out.append(person(56, ((48, 160), (74, 150)), 1, 6, GY, True, False, 1.2))
        out.append(tag('paper') + f'<rect x="72" y="132" width="24" height="30" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<path d="M76 140 h16 M76 147 h12 M76 154 h16" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
        out.append(phone(52, 166, 10))
        out.append(f'<path d="M100 126 l8 -10 M108 116 l-3 1 M108 116 l-1 3" stroke="{MOVE}" stroke-width="1.6" fill="none" stroke-linecap="round"/>')
    elif kind == 'laugh':
        out.append(person(56, ((44, 160), (66, 160)), 1, -14, GY, True, False, 1.2))
        out.append(phone(68, 164, 10))
        out.append(mouth_open(56 + 3 * 1.2 + 5, 198 - 64 * 1.2 + 4))
        out.append(tag('laugh') + f'<path d="M30 72 q-6 -4 -2 -10 M78 66 q6 -6 12 -2" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
        out.append(motion(92, 126, 1, -1, 3, 6))
    elif kind == 'sign':
        # A sign on the van: only the big accidents are written down.
        out.append(van(10, 140, 1.0))
        out.append(tag('paper') + f'<rect x="24" y="80" width="36" height="30" rx="3" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>'
                   f'<path d="M42 86 l4 9 l8 -5 l-3 10 l-18 0 l5 -8 Z" fill="{FLAME}" stroke="{RED}" stroke-width="1.2" stroke-linejoin="round"/>')
        out.append(f'<path d="M42 110 v30" stroke="{WOOD}" stroke-width="2.6"/>')
        out.append(person(78, ((70, 160), (88, 160)), 1, 0, GY, True, False, 1.2))
        out.append(phone(90, 164, 10))
    else:  # blame
        out.append(person(56, ((48, 160), (92, 118)), 1, 0, GY, True, False, 1.2))
        out.append(phone(46, 166, 10))
        out.append(tag('finger') + f'<path d="M96 118 q8 0 14 4" stroke="{SKIN}" stroke-width="3" stroke-linecap="round"/>')
        out.append(f'<path d="M28 58 l10 -6 M70 54 l-6 -8" stroke="{RED}" stroke-width="2" stroke-linecap="round"/>')
    return card_close(out)


CARDS = {}
for k in ('cow', 'dtr', 'bed', 'walk', 'gate', 'leave'):
    CARDS[f'must_{k}'] = must_card(k)
for k in ('call', 'doc', 'home', 'comp', 'huddle', 'tea'):
    CARDS[f'duty_{k}'] = duty_card(k)
for k in ('when', 'how', 'vague', 'hide', 'over'):
    CARDS[f'note_{k}'] = note_card(k)
for k in ('asis', 'sand', 'ladder', 'fuse', 'sweep'):
    CARDS[f'scene_{k}'] = scene_card(k)
for k in ('tell', 'write', 'laugh', 'sign', 'blame'):
    CARDS[f'near_{k}'] = near_card(k)

# Safe cards and traps per round (mirrors learn_board_pack77.dart).
ROUNDS = {
    'must': (['must_cow', 'must_dtr', 'must_bed'], ['must_walk', 'must_gate', 'must_leave']),
    'duty': (['duty_call', 'duty_doc'], ['duty_home', 'duty_comp', 'duty_huddle', 'duty_tea']),
    'note': (['note_when', 'note_how'], ['note_vague', 'note_hide', 'note_over']),
    'scene': (['scene_asis', 'scene_sand'], ['scene_ladder', 'scene_fuse', 'scene_sweep']),
    'near': (['near_tell', 'near_write'], ['near_laugh', 'near_sign', 'near_blame']),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_MARK = re.compile(r'<!--mark:(\w+)-->')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    said = {k: sorted(_PROP.findall(v) + _MARK.findall(v)) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for t in traps:
                if said[t] == said[s]:
                    problems.append(f'{rnd}: {t} says just what {s} says (a near-copy)')
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
