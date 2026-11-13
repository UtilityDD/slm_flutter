"""Picture cards for lesson 5.5 শেখা ("'লো-ভোল্টেজ' সমস্যার সমাধান").

python -I tool/m5_board55_art.py .

Writes assets/game/art/m5_board55/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; meter readings are drawn as seven-segment digits (paths, English
digits), as a real meter shows them.

What the cards show comes from lesson 5.5 (and the Module 5 rulings) only:
  1. call: first ask whose problem it is — one house or many (ask the
     neighbour, sketch which houses complain); never climb and tighten
     everything first, blame the company, or go to the DTR tap for one house;
  2. house (one house only): measure first at the meter's incoming terminals,
     always with the load running (the pump on); never with every switch off,
     at the DTR for one house, or only at a socket inside;
  3. joint (the meter's incoming is low too): check and tighten every joint
     of the service connection, at the pole and at the meter (supply off and
     proven dead: the cut-out's carrier pulled out, dark windows, the meter
     on the joint reading 0); a thermal camera finds the hot joint; never
     only the one hot joint (camera in hand, walking off while the other
     joint glows), the inside wiring, or a too-thin service cable left as it
     is under a new AC (the cable glowing, the worker walking off);
  4. neutral: beside phase-neutral, measure neutral-earth; a reading well over
     5-10 V points to the neutral (written on the docket); never shrugged off,
     never phase-neutral only, never a corroded neutral left while only the
     phase is tightened;
  5. area (the whole neighbourhood low in the evening): the DTR first — the
     voltage at the LTDB incoming (ruling M5-15c), the load on a clamp meter
     against the nameplate, the off-load tap position only once the DTR is
     off and proven dead (ruling M5-2: drop-out barrels hanging open, the
     operating rod by the pole, the lane dark, the meter on the LTDB reading
     0, the earth set on the HT bushings; no tool on the tap); never house to
     house, never "it is always low in the evening", never a spanner on the
     tap changer while the DTR is live (barrels upright, windows lit, the
     earth set lying unused on the ground). For one house the worker only
     heads off to the DTR (call_tap): no hand on a live tap.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board55_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board55')
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
VEST = '#3F7F5A'       # the villager's kurta
VEST_D = '#326649'
LUNGI = '#5C4A7A'
WIRE = '#2B3138'
PHASE = '#C8352B'
NEUTRAL = '#22262B'
EARTHW = '#3E9B4F'
EARTH_Y = '#E8C830'
LCD_ON = '#1D2B22'
METER_Y = '#F2B630'
METER_D = '#B9851A'
PAPER = '#F4F1E6'
INK = '#4A5560'
BAG = '#6B5B3E'
RUST = '#9A5A2A'
WIN_DIM = '#8C6A2A'
WIN_LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
WATER = '#5FB2E6'
MOVE = '#FFFFFF'
TEA = '#E9E2D2'
AC = '#E6ECF0'
CLAMP = '#D8402F'

DEFS = """<defs>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3B4D7A"/><stop offset="0.6" stop-color="#C98A6A"/><stop offset="1" stop-color="#E9B884"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E4D3B4"/><stop offset="1" stop-color="#CDB892"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A7F6E"/><stop offset="1" stop-color="#6E6456"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="ir" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1B2A6B"/><stop offset="0.6" stop-color="#3B3F9E"/><stop offset="1" stop-color="#6A3C9A"/></linearGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4B0"/><stop offset="0.35" stop-color="#FF9A2E"/><stop offset="1" stop-color="#E2402A" stop-opacity="0"/></radialGradient>
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
# People (the worker from tool/m4_board41_art.py; the villager in a kurta).
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


def _boot(p, face, color=BOOT):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{color}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, villager=False, props_front=''):
    """A person: the lineman (blue shirt, helmet, rubber gloves) or the
    villager (green kurta, lungi, bare head and hands)."""
    shirt, shirt_d = ('url(#shirt)', SHIRT_D) if not villager else (VEST, VEST_D)
    sleeve_b, sleeve_f = (SHIRT_D, SHIRT) if not villager else (VEST_D, VEST)
    legs_b, legs_f = (PANTS_D, PANTS) if not villager else (LUNGI, LUNGI)
    hand_c = GLOVE if not villager else SKIN
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, legs_b, 7))
    g.append(_boot(fb, face, BOOT if not villager else SKIN_D))
    g.append(_limb(hip, _joint(hip, ff, face), ff, legs_f, 7))
    g.append(_boot(ff, face, BOOT if not villager else SKIN_D))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, sleeve_b, 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    low = 6 if villager else 0
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py + low)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py + low)} Z" fill="{shirt}"/>')
    if not villager:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    else:
        g.append(f'<path d="M{f(sh[0])} {f(sh[1] - 2)} L{f(sh[0])} {f(sh[1] + 10)}" stroke="{shirt_d}" stroke-width="1.2"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if villager:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Q{f(hx)} {f(hy - 4)} {f(hx - 7)} {f(hy - 1)} Z" fill="{HAIR}"/>')
    else:
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>')
        hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, sleeve_f, 5.4))
    g.append(props_front)
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, villager=False, gy=GY, props=''):
    """A standing person at x (feet on gy), scaled S about the feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, villager)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}{props}</g>'


def seated(x, gy, face=1, hands=None):
    """The lineman sitting on a bench (hips at bench height)."""
    hip = (x, gy - 22)
    sh = (x + 1 * face, gy - 48)
    head = (x + 3 * face, gy - 56)
    feet = ((x + 10 * face, gy + 6), (x + 16 * face, gy + 6))
    hands = hands or ((x + 10 * face, gy - 26), (x + 12 * face, gy - 30))
    return figure(hip, sh, head, feet, hands, face, 6)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

# Seven-segment digits: segments a..g as (x0, y0, x1, y1) in a 6 x 10 cell.
_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}


def digits(x, y, text, h=10.0, color=LCD_ON):
    """English digits drawn as seven-segment strokes; (x, y) = top left."""
    k = h / 10
    o = []
    for i, ch in enumerate(text):
        ox = x + i * 7.8 * k
        for s in _DIG[ch]:
            x0, y0, x1, y1 = _SEG[s]
            o.append(f'M{f(ox + x0 * k)} {f(y + y0 * k)} L{f(ox + x1 * k)} {f(y + y1 * k)}')
    return f'<path d="{" ".join(o)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" fill="none"/>'


def multimeter(x, y, reading, s=1.0):
    """A yellow hand-held multimeter (top-left x, y) with its reading."""
    w, h = 28 * s, 42 * s
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>'
            f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 3.5 * s)}" width="{f(w - 5 * s)}" height="{f(15 * s)}" rx="1.5" fill="url(#lcd)"/>'
            + digits(x + (w - (len(reading) * 7.8 - 1.8) * s) / 2, y + 6 * s, reading, 10 * s)
            + f'<circle cx="{f(x + w / 2)}" cy="{f(y + 27 * s)}" r="{f(6 * s)}" fill="{WIRE}"/>'
            f'<path d="M{f(x + w / 2)} {f(y + 27 * s)} l{f(3 * s)} {f(-4 * s)}" stroke="{PAPER}" stroke-width="1.2"/>')


def leads(start, tips, drop=18):
    """The red and black test leads from the meter to the probe tips."""
    o = []
    for (tx, ty), col in zip(tips, (PHASE, NEUTRAL)):
        mx, my = (start[0] + tx) / 2, max(start[1], ty) + drop
        o.append(f'<path d="M{f(start[0])} {f(start[1])} Q{f(mx)} {f(my)} {f(tx)} {f(ty)}" stroke="{col}" stroke-width="1.6" fill="none"/>')
        o.append(f'<path d="M{f(tx)} {f(ty)} l0 -0.1" stroke="{col}" stroke-width="3.4" stroke-linecap="round"/>')
    return ''.join(o)


def house(x, w, h, win=WIN_DIM, gy=GY, door=True):
    """A village house: wall, tiled roof, a lit / dim / dark window."""
    top = gy - h
    o = [f'<rect x="{f(x)}" y="{f(top)}" width="{f(w)}" height="{f(h)}" fill="url(#house)"/>',
         f'<path d="M{f(x - 5)} {f(top + 1)} L{f(x + w / 2)} {f(top - h * 0.45)} L{f(x + w + 5)} {f(top + 1)} Z" fill="url(#roof)"/>',
         f'<rect x="{f(x + w * 0.16)}" y="{f(top + h * 0.22)}" width="{f(w * 0.28)}" height="{f(h * 0.3)}" fill="{win}"/>']
    if win == WIN_LIT:
        o.append(f'<circle cx="{f(x + w * 0.3)}" cy="{f(top + h * 0.37)}" r="{f(w * 0.3)}" fill="url(#glow)" opacity="0.8"/>')
    if door:
        o.append(f'<rect x="{f(x + w * 0.58)}" y="{f(gy - h * 0.62)}" width="{f(w * 0.26)}" height="{f(h * 0.62)}" fill="{BAG}"/>')
    return ''.join(o)


def pole(x, top, gy=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(gy - top)}" fill="url(#pole)"/>'


def bubble(x, y, mark='?'):
    """A speech bubble with a question mark (asking) or a down arrow with a
    bolt (the 'company sends less' claim). No words."""
    o = [f'<path d="M{f(x - 15)} {f(y - 11)} h30 a5 5 0 0 1 5 5 v12 a5 5 0 0 1 -5 5 h-18 l-6 6 l1 -6 h-7 a5 5 0 0 1 -5 -5 v-12 a5 5 0 0 1 5 -5 Z" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>']
    if mark == '?':
        o.append(f'<path d="M{f(x - 3.5)} {f(y - 4)} q0 -4 3.5 -4 q3.5 0 3.5 3.5 q0 2.5 -3.5 3.5 v2.5" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
                 f'<circle cx="{f(x)}" cy="{f(y + 5.5)}" r="1.2" fill="{INK}"/>')
    else:
        o.append(f'<path d="M{f(x - 8)} {f(y - 5)} l3 0 l-3 5 l3 0 l-4 6" stroke="{HELMET_D}" stroke-width="1.6" fill="none" stroke-linejoin="round"/>'
                 f'<path d="M{f(x + 4)} {f(y - 6)} v9 m-4 -4 l4 5 l4 -5" stroke="{PHASE}" stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    return ''.join(o)


def clipboard(x, y, sketch=True, s=1.0):
    """A docket on a clipboard; [sketch] = a little street plan with the
    complaining houses marked."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(30 * s)}" height="{f(38 * s)}" rx="2" fill="{BAG}"/>',
         f'<rect x="{f(x + 3 * s)}" y="{f(y + 5 * s)}" width="{f(24 * s)}" height="{f(30 * s)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + 10 * s)}" y="{f(y + 2 * s)}" width="{f(10 * s)}" height="{f(5 * s)}" rx="1" fill="url(#steel)"/>']
    if sketch:
        o.append(f'<path d="M{f(x + 5 * s)} {f(y + 21 * s)} h{f(20 * s)}" stroke="{INK}" stroke-width="0.8" stroke-dasharray="2 1.5"/>')
        for i in range(4):
            bx = x + (5 + i * 5.2) * s
            o.append(f'<rect x="{f(bx)}" y="{f(y + 13 * s)}" width="{f(3.6 * s)}" height="{f(5 * s)}" fill="none" stroke="{INK}" stroke-width="0.7"/>')
        for i in (0, 2, 3):
            o.append(f'<circle cx="{f(x + (6.8 + i * 5.2) * s)}" cy="{f(y + 27 * s)}" r="{f(1.3 * s)}" fill="{PHASE}"/>')
    else:
        for i in range(4):
            o.append(f'<path d="M{f(x + 6 * s)} {f(y + (12 + i * 5) * s)} h{f(18 * s - (i % 2) * 5)}" stroke="{INK}" stroke-width="0.8"/>')
    return ''.join(o)


def spanner(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x)}" y="{f(y - 2.2)}" width="22" height="4.4" rx="1.6" fill="url(#steel)"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} L{f(x + 4)} {f(y - 6)} L{f(x + 4)} {f(y - 2)} L{f(x + 1)} {f(y - 2)} L{f(x + 1)} {f(y + 2)} '
            f'L{f(x + 4)} {f(y + 2)} L{f(x + 4)} {f(y + 6)} L{f(x - 2)} {f(y + 6)} Z" fill="url(#steel)"/></g>')


def screwdriver(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 1)}" width="12" height="2" fill="url(#steel)"/>'
            f'<rect x="{f(x + 12)}" y="{f(y - 2.6)}" width="11" height="5.2" rx="2" fill="{CLAMP}"/></g>')


def motion(x, y, dx=0, dy=1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def earth_lead(d):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{EARTHW}" stroke-width="2.6" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """A portable earth set lying coiled on the ground, unused."""
    o = []
    for i, (rx, ry) in enumerate(((14, 5), (11, 4), (8, 3))):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0'))
    for dx in (-20, 18, 24):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="7" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def op_rod(x0, y0, x1, y1):
    """An insulated operating rod (yellow fibreglass with a steel hook)."""
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{HELMET_D}" stroke-width="3" stroke-linecap="round"/>'
            f'<circle cx="{f(x1)}" cy="{f(y1)}" r="2.6" fill="none" stroke="url(#steel)" stroke-width="1.6"/>')


def cutout(x, y, pulled=True):
    """The service cut-out (fuse carrier box) on the pole or wall; [pulled] =
    its carrier taken out, an empty dark slot."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="14" height="20" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.7"/>']
    if pulled:
        o.append(f'<rect x="{f(x + 3)}" y="{f(y + 4)}" width="8" height="12" rx="1" fill="{WIRE}"/>')
    else:
        o.append(f'<rect x="{f(x + 3)}" y="{f(y + 4)}" width="8" height="12" rx="1" fill="url(#steel)"/>')
    return ''.join(o)


def fuse_carrier(x, y):
    """The pulled-out fuse carrier, lying down."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="16" height="6" rx="1.5" fill="url(#steel)"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="4" height="6" rx="1" fill="url(#box)" stroke="{INK}" stroke-width="0.5"/>')


def heat(x, y, r=12):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#heat)"/>'


def tool_bag(x, y, shut=True):
    o = f'<rect x="{f(x - 11)}" y="{f(y)}" width="22" height="14" rx="3" fill="{BAG}"/>'
    if shut:
        o += f'<path d="M{f(x - 6)} {f(y)} q6 -7 12 0" stroke="{WIRE}" stroke-width="1.6" fill="none"/>'
    else:
        o += f'<path d="M{f(x - 11)} {f(y)} l-4 -5 M{f(x + 11)} {f(y)} l4 -5" stroke="{BAG}" stroke-width="2"/>'
    return o


# --------------------------------------------------------------------------
# Round 1 — call: an evening lane, a row of houses on one LT line.
# --------------------------------------------------------------------------

def lane_stage(wins=(WIN_DIM, WIN_DIM, WIN_DIM)):
    out = card_open('dusk')
    out.append(f'<rect y="{GY - 8}" width="{W}" height="{H - GY + 8}" fill="url(#road)"/>')
    out.append(house(6, 46, 48, wins[0], GY - 8, door=False))
    out.append(house(60, 50, 54, wins[1], GY - 8))
    out.append(house(148, 46, 50, wins[2], GY - 8, door=False))
    out.append(pole(126, 40, GY - 8, 6))
    out.append(f'<path d="M0 46 Q63 54 126 44 Q163 50 200 46" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
    out.append(f'<path d="M126 48 Q110 92 96 {GY - 60}" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    return out


def call_card(kind):
    if kind == 'ask':
        out = lane_stage()
        out.append(person(62, ((70, 160), (76, 152)), face=1, look=-6))
        out.append(person(150, ((142, 164), (138, 158)), face=-1, villager=True))
        out.append(bubble(150, 96))
    elif kind == 'sketch':
        out = lane_stage()
        out.append(person(150, ((138, 168), (130, 150)), face=-1, villager=True))
        out.append(person(66, ((88, 150), (96, 156)), face=1, look=10))
        out.append(clipboard(84, 126, True, 1.25))
    elif kind == 'climb':
        out = lane_stage()
        out.append(person(126, ((121, 70), (132, 60)), face=1, look=-24, gy=110))
        out.append(spanner(132, 56, -40))
        out.append(tool_bag(150, GY - 22))
    elif kind == 'blame':
        out = lane_stage()
        out.append(person(150, ((142, 164), (138, 158)), face=-1, villager=True))
        out.append(person(66, ((56, 152), (40, 104)), face=1, look=-14))
        out.append(clipboard(52, 150, True, 0.7))
        out.append(bubble(96, 88, 'down'))
    elif kind == 'tap':
        out = lane_stage((WIN_LIT, WIN_DIM, WIN_LIT))
        # A small DTR on its platform at the lane end; for one house's
        # complaint the worker heads off to it, pointing at its tap (no hand on it).
        out.append(f'<rect x="164" y="104" width="30" height="36" rx="3" fill="url(#tank)"/>')
        out.append(f'<rect x="160" y="140" width="38" height="4" fill="url(#steel)"/>')
        out.append(f'<circle cx="170" cy="122" r="3.2" fill="url(#steel)" stroke="{WIRE}" stroke-width="0.8"/>')
        out.append(person(122, ((114, 170), (152, 118)), face=1, look=-14))
        out.append(spanner(112, 172, 95))
        out.append(motion(98, 150, -1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — house: the outside wall with the energy meter, the pump below.
# --------------------------------------------------------------------------

MX, MY = 112, 52      # meter box top-left
INC = ((MX + 10, MY + 54), (MX + 20, MY + 54))   # incoming terminals (phase, neutral)


def meter_box(reading_glow=True):
    o = [f'<rect x="{MX}" y="{MY}" width="52" height="62" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>',
         f'<rect x="{MX + 8}" y="{MY + 8}" width="36" height="14" rx="1.5" fill="url(#lcd)"/>',
         f'<circle cx="{MX + 26}" cy="{MY + 34}" r="3" fill="{PHASE}" opacity="0.8"/>']
    for i, col in enumerate((PHASE, NEUTRAL, PHASE, NEUTRAL)):
        x = MX + 10 + i * 10
        o.append(f'<rect x="{x - 3}" y="{MY + 50}" width="6" height="6" rx="1" fill="url(#steel)"/>')
        o.append(f'<path d="M{x} {MY + 56} L{x} {MY + 74}" stroke="{col}" stroke-width="2"/>')
    # The service cable coming in from above.
    o.append(f'<path d="M200 20 Q150 26 {MX + 52} {MY + 4}" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
    return ''.join(o)


def pump(x, running=True):
    y = GY - 16
    o = [f'<rect x="{x - 18}" y="{y - 14}" width="30" height="18" rx="6" fill="url(#tank)"/>',
         f'<rect x="{x + 12}" y="{y - 8}" width="16" height="6" fill="url(#steel)"/>',
         f'<rect x="{x - 22}" y="{y + 4}" width="38" height="5" fill="{WIRE}"/>',
         f'<path d="M{x - 6} {y - 14} Q{x - 10} {MY + 40} {MX + 30} {MY + 74}" stroke="{NEUTRAL}" stroke-width="1.4" fill="none"/>']
    if running:
        o.append(f'<path d="M{x + 28} {y - 5} q10 0 12 18" stroke="{WATER}" stroke-width="4" fill="none" stroke-linecap="round"/>')
        o.append(motion(x - 3, y - 22, 1, 0, 3, 7))
    else:
        o.append(f'<path d="M{x + 28} {y - 5} l3 0" stroke="{WATER}" stroke-width="2" stroke-linecap="round" opacity="0.6"/>')
    o.append(f'<rect x="{x + 30}" y="{y + 9}" width="16" height="12" rx="2" fill="{BAG}"/>')
    return ''.join(o)


def switchboard(x, y, on=True):
    o = [f'<rect x="{x}" y="{y}" width="34" height="24" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>']
    for i in range(3):
        sx = x + 6 + i * 10
        o.append(f'<rect x="{sx - 2.5}" y="{y + 6}" width="5" height="12" rx="1" fill="url(#box)" stroke="{INK}" stroke-width="0.5"/>')
        o.append(f'<rect x="{sx - 2}" y="{y + (7 if on else 12)}" width="4" height="5" rx="1" fill="{WIRE}"/>')
    return ''.join(o)


def house_stage(on=True, running=True):
    out = card_open('wall')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    out.append(switchboard(26, 60, on))
    out.append(meter_box())
    out.append(pump(44, running))
    return out


def house_card(kind):
    if kind == 'incoming':
        out = house_stage()
        out.append(person(176, ((150, 132), (166, 138)), face=-1, look=-8))
        out.append(leads((136 + 14 * 1.1, 116 + 42 * 1.1), INC))
        out.append(multimeter(136, 116, '186', 1.1))
    elif kind == 'pump':
        out = house_stage()
        out.append(person(98, ((76, 150), (110, 140)), face=-1, look=18))
        out.append(leads((94 + 14 * 1.1, 124 + 42 * 1.1), INC))
        out.append(multimeter(94, 124, '184', 1.1))
    elif kind == 'off':
        out = house_stage(on=False, running=False)
        out.append(person(176, ((150, 132), (166, 138)), face=-1, look=-8))
        out.append(leads((136 + 14 * 1.1, 116 + 42 * 1.1), INC))
        out.append(multimeter(136, 116, '231', 1.1))
    elif kind == 'dtr':
        out = card_open('dusk')
        out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
        out.append(house(10, 34, 34, WIN_DIM, GY - 4))
        out.append(pole(110, 30, GY - 4, 7) + pole(170, 30, GY - 4, 7))
        out.append(f'<rect x="120" y="70" width="40" height="44" rx="3" fill="url(#tank)"/>')
        out.append(f'<rect x="104" y="114" width="74" height="4" fill="url(#steel)"/>')
        out.append(f'<rect x="102" y="140" width="22" height="26" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(person(72, ((90, 150), (96, 146)), face=1, look=-8))
        out.append(leads((82 + 14 * 0.8, 132 + 42 * 0.8), ((108, 158), (116, 158))))
        # A normal reading at the DTR: the area is fine, only one house is low.
        out.append(multimeter(82, 132, '231', 0.8))
    elif kind == 'socket':
        out = card_open('wall')
        out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="{BAG}"/>')
        out.append(switchboard(120, 70, True))
        out.append(f'<rect x="124" y="104" width="26" height="22" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<circle cx="133" cy="115" r="1.8" fill="{WIRE}"/><circle cx="141" cy="115" r="1.8" fill="{WIRE}"/>')
        out.append(pump(44, False))
        out.append(person(176, ((150, 140), (160, 146)), face=-1, look=6))
        out.append(leads((92 + 14 * 1.1, 136 + 42 * 1.1), ((133, 115), (141, 115))))
        out.append(multimeter(92, 136, '188', 1.1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — joint: the service drop from the pole to the house meter.
# --------------------------------------------------------------------------

PJ = (38, 52)          # the service joint on the pole top
MJ = (150, 128)        # the meter terminal on the house wall


def drop_stage(win=WIN_DIM, sag=10, thin=False):
    out = card_open('day')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    out.append(pole(30, 28, GY - 4, 9))
    out.append(f'<rect x="20" y="44" width="34" height="5" fill="url(#steel)"/>')
    out.append(f'<path d="M0 40 L200 36" stroke="{WIRE}" stroke-width="1.6"/>')
    out.append(f'<path d="M0 46 L200 42" stroke="{NEUTRAL}" stroke-width="1.6"/>')
    out.append(house(118, 76, 96, win, GY - 4))
    out.append(f'<rect x="{MJ[0] - 12}" y="{MJ[1] - 18}" width="24" height="30" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.7"/>')
    out.append(f'<rect x="{MJ[0] - 7}" y="{MJ[1] - 13}" width="14" height="6" fill="url(#lcd)"/>')
    w = 1.1 if thin else 2.4
    out.append(f'<path d="M{PJ[0]} {PJ[1]} Q{(PJ[0] + MJ[0]) / 2} {PJ[1] + 40 + sag} {MJ[0] - 14} {MJ[1] - 30} L{MJ[0]} {MJ[1] - 18}" stroke="{WIRE}" stroke-width="{w}" fill="none"/>')
    out.append(f'<circle cx="{PJ[0]}" cy="{PJ[1]}" r="3.4" fill="url(#steel)" stroke="{WIRE}" stroke-width="0.8"/>')
    out.append(f'<rect x="{MJ[0] - 5}" y="{MJ[1] + 4}" width="10" height="5" rx="1" fill="url(#steel)"/>')
    return out


def ladder(x0, y0, x1, y1):
    o = [f'<path d="M{x0} {y0} L{x1} {y1} M{x0 + 9} {y0} L{x1 + 9} {y1}" stroke="{METER_D}" stroke-width="2.2"/>']
    for i in range(1, 9):
        t = i / 9
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        o.append(f'<path d="M{f(x)} {f(y)} l9 0" stroke="{METER_D}" stroke-width="1.6"/>')
    return ''.join(o)


def thermal_cam(x, y, hot=True):
    o = [f'<rect x="{x}" y="{y}" width="30" height="24" rx="3" fill="{WIRE}"/>',
         f'<rect x="{x + 3}" y="{y + 3}" width="24" height="16" rx="1" fill="url(#ir)"/>',
         f'<rect x="{x + 11}" y="{y + 23}" width="8" height="12" rx="2" fill="{WIRE}"/>']
    if hot:
        o.append(heat(x + 17, y + 9, 7))
    return ''.join(o)


def joint_card(kind):
    if kind == 'pole':
        # Supply off and proven dead: the cut-out's carrier is out (lying by
        # the bag), the windows are dark, the meter on the joint reads 0.
        out = drop_stage(WIN_OFF)
        out.append(cutout(23, 66, pulled=True))
        out.append(ladder(58, GY - 4, 40, 64))
        out.append(person(52, ((40, 58), (44, 52)), face=-1, look=-20, gy=128))
        out.append(spanner(42, 52, 200))
        out.append(leads((66 + 12.6, 70), ((PJ[0] + 2, PJ[1] + 3), (PJ[0] - 3, PJ[1] + 4)), drop=-14))
        out.append(multimeter(66, 70, '0', 0.9))
        out.append(tool_bag(80, GY - 18))
        out.append(fuse_carrier(96, GY - 10))
    elif kind == 'meter':
        # Supply off and proven dead: the cut-out's carrier is out, the
        # windows are dark, the meter on the terminals reads 0.
        out = drop_stage(WIN_OFF)
        out.append(cutout(168, 110, pulled=True))
        out.append(person(110, ((140, 140), (144, 134)), face=1, look=-6))
        out.append(screwdriver(146, MJ[1] + 6, 170))
        out.append(leads((126 + 11.2, 156), ((MJ[0] - 3, MJ[1] + 8), (MJ[0] + 3, MJ[1] + 8)), drop=-10))
        out.append(multimeter(126, 156, '0', 0.8))
        out.append(tool_bag(80, GY - 18))
        out.append(fuse_carrier(70, GY - 30))
    elif kind == 'thermal':
        out = drop_stage()
        out.append(heat(PJ[0], PJ[1], 10))
        out.append(person(84, ((70, 132), (76, 126)), face=-1, look=-26))
        out.append(thermal_cam(56, 108))
    elif kind == 'onlyhot':
        # Found the one hot joint with the camera, tightened it, and leaves:
        # the other joint still glows.
        out = drop_stage()
        out.append(ladder(58, GY - 4, 40, 64))
        out.append(heat(MJ[0], MJ[1] + 6, 12))
        out.append(person(70, ((62, 168), (84, 166)), face=1, look=4))
        out.append(thermal_cam(47, 134))
        out.append(tool_bag(88, 160))
        out.append(spanner(40, 52, 200))
        out.append(motion(46, 120, 1, 0, 3, 7))
    elif kind == 'inside':
        out = drop_stage(WIN_OFF)
        # A cut-away window: the worker inside, probing the switchboard.
        out.append(f'<rect x="128" y="132" width="56" height="58" fill="{BAG}"/>')
        out.append(switchboard(146, 140, True))
        out.append(f'<g transform="translate(150 186) scale(0.7) translate(-150 -186)">'
                   + person(160, ((150, 160), (156, 154)), face=-1, look=-6, gy=186) + '</g>')
        out.append(screwdriver(150, 154, 200))
        out.append(leads((130 + 8.4, 164), ((152, 162), (162, 162)), drop=6))
        out.append(multimeter(130, 164, '186', 0.6))
    elif kind == 'thin':
        # The new AC running on a thin, sagging, hot service cable; the worker
        # packs up and walks off, leaving it as it is.
        out = drop_stage(sag=18, thin=True)
        out.append(f'<rect x="164" y="96" width="28" height="16" rx="2" fill="{AC}" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<path d="M168 106 h20 M168 109 h20" stroke="{INK}" stroke-width="0.6"/>')
        out.append(motion(178, 118, 0, 1, 3, 6))
        out.append(heat(93, 93, 12))
        out.append(heat(113, 99, 8))
        out.append(person(60, ((50, 168), (72, 166)), face=-1, look=6))
        out.append(tool_bag(50, 166))
        out.append(motion(84, 150, 1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — neutral: the board on the wall with phase, neutral and earth.
# --------------------------------------------------------------------------

TP, TN, TE = (96, 96), (118, 96), (140, 96)    # phase, neutral, earth terminals


def board_stage(corroded=False):
    out = card_open('wall')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    out.append(f'<rect x="80" y="56" width="76" height="58" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    for (x, y), col in ((TP, PHASE), (TN, NEUTRAL), (TE, EARTHW)):
        out.append(f'<path d="M{x} {y - 40} L{x} {y - 4}" stroke="{col}" stroke-width="2.6"/>')
        out.append(f'<rect x="{x - 4}" y="{y - 4}" width="8" height="8" rx="1.5" fill="url(#steel)"/>')
    # The earth lead runs down to a rod in the ground.
    out.append(f'<path d="M{TE[0]} {TE[1] + 4} L{TE[0]} 120 Q{TE[0] + 30} 130 172 {GY - 6}" stroke="{EARTHW}" stroke-width="2.4" fill="none"/>')
    out.append(f'<path d="M{TE[0]} {TE[1] + 4} L{TE[0]} 120 Q{TE[0] + 30} 130 172 {GY - 6}" stroke="{EARTH_Y}" stroke-width="2.4" fill="none" stroke-dasharray="5 5"/>')
    out.append(f'<path d="M172 {GY - 8} L172 {GY + 10}" stroke="url(#steel)" stroke-width="3"/>')
    if corroded:
        out.append(f'<rect x="{TN[0] - 5}" y="{TN[1] - 16}" width="10" height="20" rx="2" fill="{RUST}" opacity="0.85"/>')
        out.append(f'<path d="M{TN[0] - 3} {TN[1] - 20} l-4 -3 M{TN[0] + 2} {TN[1] - 20} l3 -4" stroke="{NEUTRAL}" stroke-width="1.2"/>')
    return out


def neutral_card(kind):
    if kind == 'ne':
        out = board_stage()
        out.append(person(46, ((60, 150), (70, 146)), face=1, look=-10))
        out.append(leads((54 + 14 * 1.1, 128 + 42 * 1.1), (TE, TN)))
        out.append(multimeter(54, 128, '18', 1.1))
    elif kind == 'note':
        out = board_stage()
        out.append(leads((114 + 14 * 1.1, 126 + 42 * 1.1), (TE, TN)))
        out.append(multimeter(114, 126, '18', 1.1))
        out.append(person(46, ((58, 156), (74, 150)), face=1, look=12))
        out.append(clipboard(56, 132, False, 1.0))
    elif kind == 'shrug':
        out = board_stage()
        out.append(leads((114 + 14 * 1.1, 126 + 42 * 1.1), (TE, TN)))
        out.append(multimeter(114, 126, '18', 1.1))
        out.append(person(46, ((28, 120), (66, 118)), face=1, look=-8))
        out.append(clipboard(64, GY - 14, False, 0.6))
        out.append(tool_bag(30, GY - 18))
    elif kind == 'pn':
        out = board_stage()
        out.append(leads((114 + 14 * 1.1, 126 + 42 * 1.1), (TP, TN)))
        out.append(multimeter(114, 126, '214', 1.1))
        out.append(person(46, ((54, 176), (62, 172)), face=1, look=16))
        out.append(tool_bag(66, GY - 20, shut=False))
    elif kind == 'weak':
        out = board_stage(corroded=True)
        out.append(person(46, ((80, 108), (88, 100)), face=1, look=-14))
        out.append(screwdriver(94, 100, 190))
        out.append(multimeter(28, GY - 46, '18', 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — area: the DTR on its two-pole structure at dusk, houses behind.
# --------------------------------------------------------------------------

HTB = (78, 98, 118)   # the HT bushings on the tank top


def dtr_stage(do_open=False, houses=True, win=WIN_DIM):
    """The DTR on its two-pole structure. [do_open]: the drop-out fuses are
    open, their barrels hanging right down below the crossarm (closed =
    upright above it)."""
    out = card_open('dusk')
    out.append(f'<rect y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="url(#ground)"/>')
    if houses:
        out.append(house(4, 30, 30, win, GY - 4, door=False))
        out.append(house(166, 30, 34, win, GY - 4, door=False))
    out.append(pole(64, 18, GY - 4, 7) + pole(136, 18, GY - 4, 7))
    out.append(f'<rect x="56" y="30" width="88" height="4" fill="url(#steel)"/>')
    for x, bx in zip((80, 100, 120), HTB):
        out.append(f'<path d="M{x} 18 L{x} 30" stroke="{WIRE}" stroke-width="1.2"/>')
        # Top contact on the crossarm, and the jumper from the hinge to the bushing.
        out.append(f'<rect x="{x - 3}" y="34" width="6" height="3" rx="1" fill="{WIRE}"/>')
        out.append(f'<path d="M{x} 47 Q{x} 52 {bx} 51" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        if do_open:
            out.append(f'<g transform="rotate(160 {x} 47)"><rect x="{x - 2.5}" y="33" width="5" height="14" rx="1.5" fill="url(#steel)"/></g>')
        else:
            out.append(f'<rect x="{x - 2.5}" y="33" width="5" height="14" rx="1.5" fill="url(#steel)"/>')
        out.append(f'<circle cx="{x}" cy="47" r="1.6" fill="{WIRE}"/>')
    out.append(f'<rect x="56" y="98" width="88" height="5" fill="url(#steel)"/>')
    out.append(f'<rect x="72" y="58" width="56" height="40" rx="4" fill="url(#tank)"/>')
    for bx in HTB:
        out.append(f'<rect x="{bx - 2}" y="50" width="4" height="8" rx="1" fill="url(#steel)"/>')
    out.append(f'<rect x="78" y="70" width="14" height="10" rx="1" fill="url(#box)"/>')
    out.append(f'<path d="M80 73 h10 M80 76 h7" stroke="{INK}" stroke-width="0.7"/>')
    out.append(f'<circle cx="116" cy="76" r="3.4" fill="url(#steel)" stroke="{WIRE}" stroke-width="0.8"/>')
    # The LT cable down to the LTDB on the pole.
    out.append(f'<path d="M124 98 Q132 112 136 128" stroke="{NEUTRAL}" stroke-width="2.6" fill="none"/>')
    out.append(f'<rect x="126" y="128" width="22" height="28" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    return out


def area_card(kind):
    if kind == 'ltdb':
        out = dtr_stage()
        out.append(person(176, ((150, 146), (152, 140)), face=-1, look=-6))
        out.append(leads((150 + 14 * 1.0, 148 + 42 * 1.0), ((132, 134), (140, 134))))
        out.append(multimeter(150, 148, '196', 1.0))
    elif kind == 'clamp':
        out = dtr_stage()
        out.append(f'<ellipse cx="132" cy="116" rx="7" ry="5" fill="none" stroke="{CLAMP}" stroke-width="3"/>')
        out.append(f'<rect x="138" y="114" width="12" height="20" rx="3" fill="{CLAMP}"/>')
        out.append(f'<rect x="140" y="117" width="8" height="6" fill="url(#lcd)"/>')
        out.append(person(172, ((150, 128), (156, 124)), face=-1, look=-30))
    elif kind == 'tap':
        # The DTR switched off and proven dead before anyone goes up: the
        # drop-outs hang open (the operating rod leans on the pole), the whole
        # lane is dark, the meter on the LTDB reads 0 and the earth set is on
        # the HT bushings. Only then the worker reads the tap position (with
        # his docket; no tool on it).
        out = dtr_stage(do_open=True, win=NEUTRAL)
        out.append(op_rod(34, GY - 4, 56, 40))
        out.append(earth_lead(f'M{HTB[2]} 52 L{HTB[0]} 52 L64 56 L69 {GY - 6}'))
        out.append(f'<path d="M69 {GY - 8} L69 {GY + 10}" stroke="url(#steel)" stroke-width="3"/>')
        out.append(person(134, ((146, 82), (122, 72)), face=-1, look=-4, gy=98))
        out.append(clipboard(140, 70, False, 0.5))
        out.append(leads((150 + 14 * 1.0, 148 + 42 * 1.0), ((132, 134), (140, 134))))
        out.append(multimeter(150, 148, '0', 1.0))
    elif kind == 'houses':
        out = dtr_stage(houses=False)
        out.append(house(150, 50, 60, WIN_DIM, GY - 4))
        out.append(f'<rect x="156" y="152" width="14" height="18" rx="1.5" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(person(140, ((156, 162), (160, 158)), face=1, look=-4))
        out.append(screwdriver(160, 160, 180))
        out.append(leads((112 + 14 * 0.8, 150 + 42 * 0.8), ((160, 166), (166, 166))))
        out.append(multimeter(112, 150, '196', 0.8))
        out.append(clipboard(10, GY - 30, False, 0.6))
    elif kind == 'evening':
        out = dtr_stage()
        out.append(f'<rect x="20" y="{GY - 22}" width="44" height="4" fill="{BAG}"/><rect x="24" y="{GY - 18}" width="3" height="14" fill="{BAG}"/><rect x="57" y="{GY - 18}" width="3" height="14" fill="{BAG}"/>')
        out.append(seated(38, GY - 18, 1, ((50, GY - 46), (46, GY - 52))))
        out.append(f'<rect x="44" y="{GY - 58}" width="7" height="8" rx="1.5" fill="{TEA}"/>')
        out.append(f'<ellipse cx="132" cy="116" rx="5" ry="3.5" fill="none" stroke="{CLAMP}" stroke-width="2" transform="translate(-90 66)"/>')
        out.append(f'<rect x="48" y="{GY - 2}" width="10" height="16" rx="3" fill="{CLAMP}"/>')
        out.append(f'<rect x="50" y="{GY + 1}" width="6" height="5" fill="url(#lcd)"/>')
        out.append(multimeter(166, GY - 40, '196', 0.7))
    elif kind == 'live':
        # Live: the drop-outs closed (barrels upright), the lane's windows lit,
        # the earth set and the operating rod lying unused on the ground, and a
        # spanner on the tap changer.
        out = dtr_stage(do_open=False, win=WIN_LIT)
        out.append(op_rod(14, GY - 2, 54, GY - 8))
        out.append(earth_coil(32, GY - 14))
        out.append(person(134, ((138, 80), (134, 76)), face=-1, look=-6, gy=98))
        out.append(spanner(117, 76, 4))
        out.append(multimeter(166, GY - 40, '196', 0.7))
    return card_close(out)


CARDS = {
    'call_ask': call_card('ask'),
    'call_sketch': call_card('sketch'),
    'call_climb': call_card('climb'),
    'call_blame': call_card('blame'),
    'call_tap': call_card('tap'),
    'house_incoming': house_card('incoming'),
    'house_pump': house_card('pump'),
    'house_off': house_card('off'),
    'house_dtr': house_card('dtr'),
    'house_socket': house_card('socket'),
    'joint_pole': joint_card('pole'),
    'joint_meter': joint_card('meter'),
    'joint_thermal': joint_card('thermal'),
    'joint_onlyhot': joint_card('onlyhot'),
    'joint_inside': joint_card('inside'),
    'joint_thin': joint_card('thin'),
    'neutral_ne': neutral_card('ne'),
    'neutral_note': neutral_card('note'),
    'neutral_shrug': neutral_card('shrug'),
    'neutral_pn': neutral_card('pn'),
    'neutral_weak': neutral_card('weak'),
    'area_ltdb': area_card('ltdb'),
    'area_clamp': area_card('clamp'),
    'area_tap': area_card('tap'),
    'area_houses': area_card('houses'),
    'area_evening': area_card('evening'),
    'area_live': area_card('live'),
}

# Safe cards and traps per round (mirrors learn_board_pack55.dart).
ROUNDS = {
    'call': (['call_ask', 'call_sketch'], ['call_climb', 'call_blame', 'call_tap']),
    'house': (['house_incoming', 'house_pump'], ['house_off', 'house_dtr', 'house_socket']),
    'joint': (['joint_pole', 'joint_meter', 'joint_thermal'], ['joint_onlyhot', 'joint_inside', 'joint_thin']),
    'neutral': (['neutral_ne', 'neutral_note'], ['neutral_shrug', 'neutral_pn', 'neutral_weak']),
    'area': (['area_ltdb', 'area_clamp', 'area_tap'], ['area_houses', 'area_evening', 'area_live']),
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
