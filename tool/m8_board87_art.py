"""Picture cards for lesson 8.7 শেখা ("ট্যারিফ অর্ডার (Tariff Order): বিদ্যুতের দামের হিসাব").

python -I tool/m8_board87_art.py .

Writes assets/game/art/m8_board87/*.svg in the gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art. A meter card carries only an icon for its category (a house, a
shop awning, a sheaf); a bill carries only highlighted rows; a tag carries
only digit strokes. Every label a worker reads is in the Dart pack.

What the cards show comes from lesson 8.7 (live text) and the Module 8
rulings only:
  1. closed: a padlocked house — the fixed (demand) charge still due; the
     service line kept connected and the meter box tagged with its load
     (kVA). Traps: the fixed-charge row struck out, the meter knocked as if
     faulty, the customer left behind with the bill;
  2. slab: a two-step staircase of coins (the upper units cost more); the
     energy-charge line split at 102 units. Traps: a flat bar of one coin, the
     staircase upside down, a reader's book filled as he pleases;
  3. cat: a house with a fan and a shop with a fridge, each meter card
     carrying the matching category icon. Traps: a shop fridge on the house
     icon, a wire from a house meter to the next shop, a reader writing with
     his back to the meter card;
  4. farm: a pump watering paddy or a vegetable field beside a channel.
     Traps: the same pump's hose washing a car at a garage, a pipe to a shop
     fridge, a reader writing at the pump while a car is washed behind him;
  5. extra: a coal heap with an up arrow beside its MVCA line (a government
     rule); a faulty meter being swapped while its meter rent line shows (the
     rent covers replacement and upkeep). Traps: the MVCA line struck out as a
     reader's trick, a price tag on the meter with the rent line struck, the
     rent line struck by the lineman.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too.
The factory round (dropped, ruling M8-21) is not drawn. It deletes only its
own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board87_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board87')
W, H = 200, 220
GY = 190

SHIRT = '#1F5F8F'
SHIRT2 = '#6B5B3E'
PANTS = '#2A3442'
SKIN = '#A86E48'
HAIR = '#2A1E16'
BOOT = '#1C1F24'
WALL = '#D9C3A0'
ROOF = '#9A4E35'
DOOR = '#6B5B3E'
GLASS = '#8FD0EE'
FAN = '#EEF1F3'
STEEL = '#7C8891'
STEEL_L = '#AEB8C0'
FRIDGE = '#E9EDF0'
AWN_R = '#C8352B'
AWN_W = '#FAF8F2'
PAPER = '#F4F1E6'
INK = '#4A5560'
HILITE = '#E8C830'
PADLOCK = '#E5B92E'
COIN = '#E8C830'
STEP = '#B9C0C6'
COAL = '#2B2F33'
WIRE = '#2B3138'
PUMP = '#3F7FB0'
PIPE = '#4A5560'
CROP = '#7E9C55'
WATER = '#8FD0EE'
CHAN = '#6C747B'
METER = '#B9851A'
DIAL = '#FAF8F2'
RED = '#C8352B'
DARK = '#2E3A46'

DEFS = """<defs>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9E3D6"/><stop offset="1" stop-color="#CFC6B3"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F1ECE0"/><stop offset="1" stop-color="#DCD5C4"/></linearGradient>
  <linearGradient id="street" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D6E7F0"/><stop offset="1" stop-color="#B9C7B0"/></linearGradient>
  <linearGradient id="field" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.6" stop-color="#B7CC8E"/><stop offset="1" stop-color="#8FB06A"/></linearGradient>
  <linearGradient id="office" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E4E8EA"/><stop offset="1" stop-color="#BFC6CC"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

BACKS = {'closed': 'room', 'slab': 'wall', 'cat': 'street', 'farm': 'field', 'extra': 'office'}


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card(back, parts):
    body = '\n'.join(parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n{DEFS}\n'
            f'<g clip-path="url(#card)">\n<rect width="{W}" height="{H}" fill="url(#{back})"/>\n{body}\n</g>\n'
            '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>\n'
            '</svg>')


def rect(x, y, w, h, fill, stroke=None, rx=0, sw=1.2):
    s = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ''
    r = f' rx="{rx}"' if rx else ''
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}"{r} fill="{fill}"{s}/>'


def circ(cx, cy, r, fill, stroke=None):
    s = f' stroke="{stroke}" stroke-width="1.5"' if stroke else ''
    return f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}"{s}/>'


def line(x1, y1, x2, y2, color, w=2.0):
    return (f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{color}" stroke-width="{f(w)}" '
            'stroke-linecap="round" fill="none"/>')


def poly(pts, fill):
    d = ' '.join(f'{f(x)},{f(y)}' for x, y in pts)
    return f'<polygon points="{d}" fill="{fill}"/>'


# ---------------------------------------------------------------- objects

def house(x, y, w=70, h=56):
    """A house whose base sits at y; the door at its middle."""
    return [
        rect(x, y - h, w, h, WALL, stroke=INK, sw=1),
        poly([(x - 6, y - h), (x + w / 2, y - h - 26), (x + w + 6, y - h)], ROOF),
        rect(x + w / 2 - 8, y - 30, 16, 30, DOOR),
        rect(x + 8, y - h + 12, 14, 12, GLASS),
    ]


def door_lock(x, y):
    """A door with a padlock on its hasp."""
    return [rect(x, y - 62, 34, 62, DOOR), rect(x + 27, y - 34, 4, 6, PADLOCK),
            rect(x + 4, y - 56, 26, 3, INK)]


def fan(cx, cy):
    out = [circ(cx, cy, 14, FAN, stroke=STEEL)]
    for a in (0, 90, 180, 270):
        r = math.radians(a + 25)
        out.append(line(cx, cy, cx + 10 * math.cos(r), cy + 10 * math.sin(r), STEEL, 3))
    return out


def fridge(x, y, w=26, h=52):
    return [rect(x, y - h, w, h, FRIDGE, stroke=STEEL, rx=2), line(x + 2, y - h * 0.55, x + w - 2, y - h * 0.55, STEEL, 1.5),
            rect(x + w - 7, y - h + 8, 3, 12, STEEL)]


def shop(x, y, w=80, h=60):
    out = [rect(x, y - h, w, h, FRIDGE, stroke=INK, sw=1)]
    n = 6
    for i in range(n):
        out.append(rect(x + i * w / n, y - h, w / n, 12, AWN_R if i % 2 == 0 else AWN_W))
    out.append(rect(x + 8, y - h + 18, w - 16, 22, GLASS))
    out.append(rect(x + w / 2 - 7, y - 26, 14, 26, DOOR))
    return out


def meter_card(x, y, icon):
    """A meter card (paper, one category icon; no words)."""
    out = [rect(x, y - 26, 36, 26, PAPER, stroke=INK, rx=2, sw=1)]
    cx, cy = x + 18, y - 13
    if icon == 'home':
        out.append(poly([(cx - 8, cy), (cx, cy - 8), (cx + 8, cy)], ROOF))
        out.append(rect(cx - 5, cy, 10, 8, WALL))
    elif icon == 'shop':
        for i in range(4):
            out.append(rect(cx - 9 + i * 4.5, cy - 7, 4.5, 6, AWN_R if i % 2 == 0 else AWN_W))
        out.append(rect(cx - 8, cy - 1, 16, 9, FRIDGE, stroke=INK, sw=0.8))
    else:  # farm: a sheaf of stalks
        for dx in (-5, 0, 5):
            out.append(line(cx + dx, cy + 8, cx + dx * 0.4, cy - 8, CROP, 2.2))
    return out


def bill(x, y, w=56, h=70, hl=(), cross=None):
    """A bill sheet: rows of ink, highlighted rows (indices), a red strike row."""
    out = [rect(x, y, w, h, PAPER, stroke=INK, rx=2, sw=1)]
    for i in range(5):
        ry = y + 10 + i * 10
        if i in hl:
            out.append(rect(x + 3, ry - 3, w - 6, 7, HILITE, rx=1))
        out.append(line(x + 7, ry, x + w - 7, ry, INK, 1.6))
    if cross is not None:
        ry = y + 10 + cross * 10
        out.append(line(x + 4, ry + 4, x + w - 4, ry - 4, RED, 3))
    return out


def meter_box(x, y, w=34, h=44, dial=True, tag=False):
    out = [rect(x, y - h, w, h, STEEL_L, stroke=STEEL, rx=3, sw=1)]
    if dial:
        out.append(circ(x + w / 2, y - h + 17, 9, DIAL, stroke=INK))
        out.append(line(x + w / 2, y - h + 17, x + w / 2 + 5, y - h + 12, METER, 2))
    if tag:
        out.append(rect(x + 6, y - 14, 22, 9, PAPER, stroke=INK, sw=0.8))
        out.append(line(x + 9, y - 10, x + 16, y - 10, INK, 1.5))
        out.append(line(x + 19, y - 10, x + 25, y - 10, INK, 1.5))
    return out


def coins(x, y, n):
    return [circ(x, y - 4 - i * 7, 6, COIN, stroke=METER) for i in range(n)]


def stair(x, y):
    """A two-step staircase: low step with a small coin stack, tall step high."""
    return [rect(x, y - 22, 52, 22, STEP, stroke=INK, sw=0.8), rect(x + 52, y - 46, 52, 46, STEP, stroke=INK, sw=0.8)] + \
        coins(x + 14, y - 22, 2) + coins(x + 66, y - 46, 5)


def person(x, face=1, back=False, point=None, hand=None):
    """A lineman or customer (drawn figure, no words). point=(x,y) to point at."""
    hipy, shy, hy = 150, 108, 88
    out = [line(x - 3, hipy, x - 5, GY_FEET, PANTS, 7), line(x + 3, hipy, x + 6, GY_FEET, PANTS, 7),
           rect(x - 11, shy, 22, hipy - shy + 6, SHIRT, rx=6)]
    out.append(circ(x, hy, 11, HAIR if back else SKIN))
    if not back:
        out.append(f'<path d="M{f(x - 11)} {f(hy)} A11 11 0 0 1 {f(x + 11)} {f(hy)} Z" fill="{HAIR}"/>')
    if point:
        sx, sy = x + face * 9, shy + 10
        out.append(line(sx, sy, point[0], point[1], SHIRT, 6))
        out.append(circ(point[0], point[1], 3.5, SKIN))
    elif hand:
        sx, sy = x + face * 9, shy + 10
        out.append(line(sx, sy, hand[0], hand[1], SHIRT, 6))
        out.append(circ(hand[0], hand[1], 3.5, SKIN))
    return out


GY_FEET = GY - 2


def pump(x, y):
    """A farm pump on a plinth, with an outlet pipe down to the ground."""
    return [rect(x, y - 24, 34, 24, PUMP, stroke=INK, sw=0.8), rect(x - 3, y - 2, 40, 6, PIPE),
            line(x + 30, y - 12, x + 46, y - 12, PIPE, 4), line(x + 46, y - 12, x + 46, y + 2, PIPE, 4),
            circ(x + 46, y + 6, 2.6, WATER), circ(x + 50, y + 11, 2, WATER)]


def crop_row(x, y, n=6, w=20):
    return [rect(x + i * w, y - 12, w - 3, 12, CROP) for i in range(n)]


def coal(x, y, w=58):
    return [f'<path d="M{f(x)} {f(y)} Q{f(x + w / 2)} {f(y - 40)} {f(x + w)} {f(y)} Z" fill="{COAL}"/>']


def up_arrow(x, y):
    return [line(x, y, x, y - 28, RED, 4), poly([(x - 8, y - 22), (x + 8, y - 22), (x, y - 36)], RED)]


def fixed_bill_on_door():
    return door_lock(22, GY) + bill(118, 92, hl=(0,))


def car(x, y, w=56):
    return [rect(x, y - 16, w, 12, RED, rx=4), rect(x + 10, y - 26, w - 22, 12, RED, rx=4),
            rect(x + 14, y - 24, w - 30, 8, GLASS), circ(x + 12, y - 4, 5, BOOT), circ(x + w - 12, y - 4, 5, BOOT)]


# ---------------------------------------------------------------- cards

CARDS = {}


def add(slot, name, parts):
    CARDS[f'{slot}_{name}'] = card(BACKS[slot], parts)


# closed: the padlocked house with its fixed-charge bill; the load tag

def closed_base():
    return [rect(0, GY, W, H - GY, '#A9A08C')]


def closed_house():
    """A padlocked house wall with its door (no words)."""
    return [rect(0, GY - 120, 62, 120, WALL, stroke=INK, sw=1), rect(10, GY - 100, 18, 16, GLASS)] + door_lock(18, GY)


def bolt_tag(x, y):
    """A load tag on a meter box: a bolt on a paper tag (no words)."""
    return [rect(x + 6, y - 14, 22, 9, PAPER, stroke=INK, sw=0.8),
            poly([(x + 17, y - 13.5), (x + 12.5, y - 8.5), (x + 16, y - 8.5), (x + 14, y - 5.5),
                  (x + 19, y - 10.5), (x + 15.5, y - 10.5), (x + 18, y - 13.5)], METER)]


def price_tag(x, y):
    """A price tag hanging from a meter box's side (no words)."""
    return [poly([(x, y - 9), (x + 16, y - 9), (x + 24, y), (x + 16, y + 9), (x, y + 9)], COIN),
            circ(x + 4, y, 2, PAPER)]


def scissors(x, y):
    """A pair of open scissors (the cut), no words."""
    return [line(x, y - 10, x + 22, y + 10, STEEL, 3), line(x + 22, y - 10, x, y + 10, STEEL, 3),
            circ(x - 3, y - 12, 4, STEEL), circ(x - 3, y + 12, 4, STEEL)]


def meter_card_big(x, y, icon, s=1.3):
    """The meter card of meter_card(), scaled up (the category icon reads at a glance)."""
    return [f'<g transform="translate({f(x)} {f(y)}) scale({f(s)})">'] + meter_card(0, 0, icon) + ['</g>']


def closed_service_wire():
    return [line(62, 60, 124, 60, WIRE, 2.4), line(124, 60, 124, 106, WIRE, 2.4)]


add('closed', 'fixed', closed_base() + door_lock(40, GY) + [rect(22, GY - 70, 74, 6, INK)] +
    bill(112, 60, hl=(0,)) + person(160, face=-1, point=(118, 84)))
add('closed', 'load', closed_base() + closed_house() + closed_service_wire() +
    meter_box(108, 150, tag=False) + bolt_tag(108, 150))
add('closed', 'strike', closed_base() + door_lock(40, GY) + [rect(22, GY - 70, 74, 6, INK)] +
    bill(112, 60, hl=(0,), cross=0) + person(160, face=-1, point=(118, 84)))
add('closed', 'meter', closed_base() + closed_house() + closed_service_wire() +
    meter_box(108, 150, tag=False) +
    [line(138, 98, 146, 92, INK, 2), line(142, 106, 152, 104, INK, 2), line(138, 116, 146, 118, INK, 2)] +
    person(168, face=-1, hand=(146, 124)))
add('closed', 'walk', closed_base() + [rect(0, GY - 120, 30, 120, WALL, stroke=INK, sw=1), rect(8, GY - 100, 14, 14, GLASS)] +
    bill(92, 66, w=54, h=64, hl=(0,)) + person(62, face=1, hand=(90, 100)) +
    person(160, face=-1, back=True) + [line(180, 150, 196, 150, INK, 2), line(178, 164, 194, 164, INK, 2)])

# slab: staircase of coins, the 102-unit split
add('slab', 'stairs', [rect(0, GY, W, H - GY, '#CFC7B3')] + stair(40, GY) + [line(20, 60, 180, 60, INK, 1)] +
    coins(152, 60, 1))
add('slab', 'bill', [rect(0, GY, W, H - GY, '#CFC7B3')] + bill(64, 34, w=72, h=120) +
    [rect(70, 102, 20, 8, STEP, rx=1), rect(90, 102, 40, 8, HILITE, rx=1), line(90, 96, 90, 116, INK, 2)])
add('slab', 'flat', [rect(0, GY, W, H - GY, '#CFC7B3')] + [rect(20, GY - 22, 160, 22, STEP, stroke=INK, sw=0.8)] +
    [circ(30 + i * 20, GY - 30, 6, COIN, stroke=METER) for i in range(8)])
# an inverted staircase: the tall (upper) step on the left has the fewer coins
add('slab', 'upside', [rect(0, GY, W, H - GY, '#CFC7B3')] +
    [rect(30, GY - 64, 56, 64, STEP, stroke=INK, sw=0.8), rect(86, GY - 30, 56, 30, STEP, stroke=INK, sw=0.8)] +
    coins(58, GY - 64, 2) + coins(114, GY - 30, 5))
add('slab', 'reader', [rect(0, GY, W, H - GY, '#CFC7B3')] + bill(60, 60, w=84, h=112, hl=(1,)) +
    person(160, face=-1, hand=(128, 110)) + [circ(154, 92, 2, COIN)])

# cat: house with fan, shop with fridge, the meter card's icon (big on the safe pair)
add('cat', 'home', [rect(0, GY, W, H - GY, '#A7B99A')] + house(16, GY, w=70, h=56) + fan(138, 110) +
    meter_card_big(150, 186, 'home') + [line(136, 124, 136, 140, STEEL, 1)])
add('cat', 'shop', [rect(0, GY, W, H - GY, '#A7B99A')] + shop(14, GY, w=96, h=64) + fridge(118, GY, 26, 52) +
    meter_card_big(150, 186, 'shop') + [rect(0, GY, W, 4, STEEL)])
add('cat', 'shop_dom', [rect(0, GY, W, H - GY, '#A7B99A')] + shop(14, GY, w=96, h=64) + fridge(118, GY, 26, 52) +
    meter_card_big(150, 186, 'home') + [rect(0, GY, W, 4, STEEL)])
add('cat', 'wire', [rect(0, GY, W, H - GY, '#A7B99A')] + house(4, GY, w=56, h=50) + fan(68, 100) +
    [line(88, 80, 124, 60, WIRE, 2.2), line(124, 60, 150, 92, WIRE, 2.2)] + shop(108, GY, w=84, h=60) +
    fridge(160, GY, 20, 40) + meter_card(20, 186, 'home'))
add('cat', 'nolook', [rect(0, GY, W, H - GY, '#A7B99A')] + house(14, GY, w=76, h=58) + fan(122, 108) +
    person(160, face=-1, back=True, hand=(140, 104)) + meter_card(118, 186, 'shop'))

# farm: a pump on a field
add('farm', 'paddy', [rect(0, GY, W, H - GY, '#8FB06A')] + pump(30, GY) + crop_row(92, GY, 5) +
    crop_row(100, GY - 16, 5) + meter_card(146, 186, 'farm'))
add('farm', 'veg', [rect(0, GY, W, H - GY, '#8FB06A')] + pump(40, GY) +
    [rect(0, GY - 6, W, 6, CHAN), rect(0, GY - 2, W, 2, WATER)] + crop_row(140, GY, 3) + meter_card(150, 186, 'farm'))
add('farm', 'carwash', [rect(0, GY, W, H - GY, '#8FB06A'), rect(0, GY - 6, W, 6, CHAN), rect(0, GY - 2, W, 2, WATER)] + pump(20, GY) + [line(56, GY - 8, 92, GY - 8, PIPE, 3)] +
    car(104, GY - 4, w=56) + crop_row(0, GY + 2, 2) + [circ(92, GY - 20, 2.5, WATER), circ(96, GY - 26, 2, WATER)])
# the farm pump's electric line runs overhead to a shop with a fridge; the only meter card is the farm card at the pump
add('farm', 'shop', [rect(0, GY, W, H - GY, '#8FB06A')] + pump(10, GY) + meter_card(12, 150, 'farm') +
    [line(48, 136, 112, 110, WIRE, 2.2), line(112, 110, 176, 130, WIRE, 2.2), rect(110, 100, 3, 30, STEEL)] +
    shop(104, GY, w=90, h=60) + fridge(118, GY, 22, 40))
add('farm', 'blind', [rect(0, GY, W, H - GY, '#8FB06A')] + pump(18, GY) + bill(96, 60, w=56, h=60, hl=(3,)) +
    person(146, face=-1, hand=(118, 100)) + car(126, GY - 4, w=50) + crop_row(0, GY + 2, 2))

# extra: MVCA (a coal heap with up arrow), the meter rent line
add('extra', 'mvca', [rect(0, GY, W, H - GY, '#9C9C90')] + coal(20, GY, w=76) + up_arrow(56, GY - 44) +
    bill(112, 46, w=66, h=96, hl=(4,)) + [line(116, 103, 174, 103, STEEL, 2.6)])
# a faulty meter (red X on its dial) swapped for a new one; the rent row on the bill
add('extra', 'rent', [rect(0, GY, W, H - GY, '#9C9C90')] + meter_box(14, GY, w=40, h=52) +
    [line(28, 149, 40, 161, RED, 2.5), line(40, 149, 28, 161, RED, 2.5)] +
    [line(62, 164, 84, 164, INK, 2.5), poly([(84, 159), (93, 164), (84, 169)], INK)] +
    meter_box(98, GY, w=34, h=52) + bill(138, 46, w=56, h=90, hl=(3,)))
add('extra', 'fraud', [rect(0, GY, W, H - GY, '#9C9C90')] + coal(12, GY, w=54) +
    bill(88, 36, w=76, h=100, hl=(1,)) + person(164, face=-1, point=(124, 92)) + scissors(104, 152))
add('extra', 'price', [rect(0, GY, W, H - GY, '#9C9C90')] + meter_box(30, GY, w=56, h=70) + price_tag(86, 150) +
    bill(120, 46, w=60, h=96, hl=(1,), cross=3))
add('extra', 'rentcut', [rect(0, GY, W, H - GY, '#9C9C90')] + bill(20, 46, w=66, h=96, hl=(3,)) +
    [line(20, 122, 90, 102, RED, 4)] + person(140, face=-1, hand=(108, 112)) + [line(92, 120, 110, 104, STEEL, 5)])

# Safe cards and traps per round (mirrors learn_board_pack87.dart).
ROUNDS = {
    'closed': (['closed_fixed', 'closed_load'], ['closed_strike', 'closed_meter', 'closed_walk']),
    'slab': (['slab_stairs', 'slab_bill'], ['slab_flat', 'slab_upside', 'slab_reader']),
    'cat': (['cat_home', 'cat_shop'], ['cat_shop_dom', 'cat_wire', 'cat_nolook']),
    'farm': (['farm_paddy', 'farm_veg'], ['farm_carwash', 'farm_shop', 'farm_blind']),
    'extra': (['extra_mvca', 'extra_rent'], ['extra_fraud', 'extra_price', 'extra_rentcut']),
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
