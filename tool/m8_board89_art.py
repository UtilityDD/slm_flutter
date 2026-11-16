"""Picture cards for lesson 8.9 শেখা ("পরিবেশগত নিয়মাবলী: রাজ্যের দৃষ্টিকোণ",
rung 8.9/learn, pack learn_8_9).

python -I tool/m8_board89_art.py .

Writes assets/game/art/m8_board89/*.svg: 200 x 220 scene cards drawn edge to
edge in the clean gradient style of tool/m6_board63_art.py. No words in the
art. Five rounds (ruling M8-21: the pre-monsoon round left the board).

What the cards show comes from lesson 8.9 (live text) and the board spec
(docs/module_specs/module8_items/board_89.json) only:
  1. trim: a branch touching the 11 kV conductor is pruned under a shutdown,
     earth set on the pole (safe: trim_touch, trim_nest). Traps: the trunk felled
     with a saw (fell_trunk), a branch with a nest falling (nest_cut), every
     branch hacked off far from the line (lopped_bare), a branch cut with the
     line live and no earth (live_cut);
  2. permit: a stamped written permission (forest_letter, local_letter). Traps:
     a phone call with the saw ready (phone_ok), an axe raised by a private
     yard (govt_line), shouting at the owner by his mango tree (quarrel);
  3. oil: old transformer on a plastic sheet, crew in gloves and masks, or
     capped drums by the disposal-centre truck (safe). Traps: oil on bare soil,
     oil poured into a drain, an uncapped drum tipping, bare hands and no mask
     at the drain valve;
  4. leak: a leaking drum, sand or sawdust thrown on the puddle (safe). Traps:
     the puddle hosed (spreading), the puddle left growing, oil swept into the
     floor drain;
  5. scrap: old batteries loaded into the authorised recycler's van, wire
     offcuts picked up into a bag (safe). Traps: batteries sold to a roadside
     cart, batteries dumped by a pond, offcuts left in the grass with a goat.

Fairness (the playbook, section 4): every card of a round shares one backdrop
and one ground; every colour a safe card draws is drawn on every card of its
round (the states differ by shape, not by colour). The script checks every
hand the dealer can make (one safe card + any three traps): the safe card's
colours are in the hand, and its backdrop is a trap's backdrop too. It
deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board89_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board89')
W, H = 200, 220
GY = 176  # the ground line

CROWN = '#4E7F3A'
BARK = '#6B4F32'
NEST = '#A88B5E'
POLE = '#C6CED4'
WIRE = '#2B3138'
INSUL = '#E8E4D8'
EARTH = '#3E9B4F'
STEEL = '#C3CBD1'
SKIN = '#A86E48'
SHIRT = '#1F5F8F'
PANTS = '#2A3442'
GLOVE = '#2A2D33'
BOOT = '#1C1F24'
MASK = '#FFFFFF'
HELMET = '#FFD34E'
PAPER = '#F4F1E6'
STAMP = '#B3262E'
PHONE = '#222A33'
HOUSE = '#D9C3A0'
MANGO = '#5E8E3A'
TANK = '#6F8A78'
PLASTIC = '#9CC9E8'
DRUM = '#3B4A5A'
OIL = '#1C1F24'
TRUCK = '#E7E9EC'
TRUCK_RED = '#D8402F'
SAND = '#E0C080'
SAWDUST = '#D8B77A'
HOSE = '#2E7D9A'
SHEEN = '#8FB8D6'
STORE = '#B9A88A'
DRAIN = '#4A5560'
KURTA = '#B5542E'
BROOM = '#B07A3A'
JUTE = '#6B5B3E'
COPPER = '#B8733A'
BATT = '#2A2F38'
BATT_Y = '#E5B92E'
POND = '#4F8FA8'
GOAT = '#E9E2D0'
SPARK = '#FFE08A'

DEFS = """<defs>
  <linearGradient id="bg_trim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BFDCEB"/><stop offset="1" stop-color="#E7F1E4"/></linearGradient>
  <linearGradient id="bg_perm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F7F3E4"/><stop offset="1" stop-color="#E8DFC6"/></linearGradient>
  <linearGradient id="bg_oil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9CED3"/><stop offset="1" stop-color="#AEB4BA"/></linearGradient>
  <linearGradient id="bg_leak" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D7CDB8"/><stop offset="1" stop-color="#BDB29A"/></linearGradient>
  <linearGradient id="bg_scrap" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9D9B5"/><stop offset="1" stop-color="#D3BC8E"/></linearGradient>
  <linearGradient id="gnd_grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="gnd_yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D6D0B8"/><stop offset="1" stop-color="#B9B39E"/></linearGradient>
  <linearGradient id="gnd_soil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A8875E"/><stop offset="1" stop-color="#7F6442"/></linearGradient>
  <linearGradient id="gnd_conc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9A9A2"/><stop offset="1" stop-color="#8E8E88"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

BACKS = {'trim': 'bg_trim', 'permit': 'bg_perm', 'oil': 'bg_oil', 'leak': 'bg_leak', 'scrap': 'bg_scrap'}
GROUNDS = {'trim': 'gnd_grass', 'permit': 'gnd_yard', 'oil': 'gnd_soil', 'leak': 'gnd_conc', 'scrap': 'gnd_grass'}


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def el(*parts):
    return ''.join(parts)


def rect(x, y, w, h, fill, rx=0, extra=''):
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(rx)}" fill="{fill}"{extra}/>'


def circle(x, y, r, fill, extra=''):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{fill}"{extra}/>'


def ellipse(x, y, rx, ry, fill, extra=''):
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(rx)}" ry="{f(ry)}" fill="{fill}"{extra}/>'


def line(x1, y1, x2, y2, color, w=3.0, extra=''):
    return (f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke="{color}" '
            f'stroke-width="{f(w)}" stroke-linecap="round"{extra}/>')


def path(d, color, w=3.0, fill='none'):
    return f'<path d="{d}" fill="{fill}" stroke="{color}" stroke-width="{f(w)}" stroke-linecap="round" stroke-linejoin="round"/>'


def ground(back, grd):
    return el(f'<rect width="{W}" height="{H}" fill="url(#{back})"/>',
              rect(0, GY, W, H - GY, f'url(#{grd})'))


def card(out_parts):
    body = ''.join(out_parts)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n{DEFS}\n'
            f'<g clip-path="url(#card)">\n{body}\n</g>\n'
            '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" '
            'stroke-opacity="0.55" stroke-width="1.5"/>\n</svg>')


def person(x, gy=GY, gloves=True, mask=False, hand=None, s=1.0):
    """A lineman at x with feet on gy; hand = (x, y) the hand raised to, or None."""
    k = s
    o = []
    o.append(rect(x - 6 * k, gy - 30 * k, 5 * k, 30 * k, PANTS))
    o.append(rect(x + 1 * k, gy - 30 * k, 5 * k, 30 * k, PANTS))
    o.append(rect(x - 7 * k, gy - 3 * k, 7 * k, 3 * k, BOOT))
    o.append(rect(x, gy - 3 * k, 7 * k, 3 * k, BOOT))
    o.append(rect(x - 9 * k, gy - 58 * k, 18 * k, 30 * k, SHIRT, rx=5 * k))
    o.append(circle(x, gy - 64 * k, 8 * k, SKIN))
    o.append(f'<path d="M{f(x - 9 * k)} {f(gy - 65 * k)} A{f(9 * k)} {f(9 * k)} 0 0 1 {f(x + 9 * k)} {f(gy - 65 * k)} Z" fill="{HELMET}"/>')
    if mask:
        o.append(rect(x - 5 * k, gy - 62 * k, 10 * k, 5 * k, MASK, rx=1.5))
    if hand is not None:
        hx, hy = hand
        sx, sy = x + 7 * k, gy - 50 * k
        o.append(line(sx, sy, hx, hy, SHIRT, 6 * k))
        o.append(circle(hx, hy, 4 * k, GLOVE if gloves else SKIN))
    else:
        o.append(line(x + 7 * k, gy - 52 * k, x + 9 * k, gy - 30 * k, SHIRT, 6 * k))
        o.append(circle(x + 9 * k, gy - 28 * k, 4 * k, GLOVE if gloves else SKIN))
        o.append(line(x - 7 * k, gy - 52 * k, x - 9 * k, gy - 30 * k, SHIRT, 6 * k))
        o.append(circle(x - 9 * k, gy - 28 * k, 4 * k, GLOVE if gloves else SKIN))
    return ''.join(o)


def tree(x, crown=True, rot=0, base=GY):
    """A tree at x; rot tilts the whole tree about its foot (felling)."""
    o = []
    if crown:
        o.append(rect(x - 4, base - 40, 8, 40, BARK))
        o.append(circle(x, base - 58, 26, CROWN))
        o.append(circle(x - 16, base - 46, 17, CROWN))
        o.append(circle(x + 16, base - 46, 17, CROWN))
    else:
        o.append(rect(x - 4, base - 60, 8, 60, BARK))
    if rot:
        return f'<g transform="rotate({rot} {f(x)} {base})">' + ''.join(o) + '</g>'
    return ''.join(o)


def nest(x, y, s=1.0):
    return ellipse(x, y, 7 * s, 3.5 * s, NEST) + path(f'M{f(x - 6 * s)} {f(y)} q{f(6 * s)} {f(4 * s)} {f(12 * s)} 0', BARK, 1.2)


def pole(x=160):
    return el(rect(x - 4, 34, 8, GY - 34, POLE), rect(x - 22, 34, 44, 5, BARK))


def conductor(y=50):
    return el(line(0, y, W, y, WIRE, 2.4), circle(138, y, 2.8, INSUL), circle(160, y, 2.8, INSUL), circle(182, y, 2.8, INSUL))


def earth_hung(x=164):
    return el(line(x, 90, x, GY - 2, EARTH, 2.6), rect(x - 3, 96, 6, 5, POLE))


def earth_coil(x=128, y=GY - 4):
    return path(f'M{x - 14} {y} a14 5 0 1 0 28 0 a14 5 0 1 0 -28 0', EARTH, 2.6)


def spark(x, y, r=9):
    pts = []
    for i in range(8):
        a = math.pi * i / 4
        rr = r if i % 2 == 0 else r * 0.45
        pts.append(f'{f(x + rr * math.cos(a))},{f(y + rr * math.sin(a))}')
    return f'<polygon points="{" ".join(pts)}" fill="{SPARK}"/>'


def saw(x, y, ang=-20):
    return f'<g transform="rotate({ang} {f(x)} {f(y)})">' + rect(x - 14, y - 3, 28, 6, STEEL, rx=1) + rect(x + 10, y - 6, 6, 4, BOOT) + '</g>'


# ---------------------------------------------------------------- round 1: trim
def trim_base():
    return [ground(BACKS['trim'], GROUNDS['trim']), tree(40), pole(160), conductor(50)]


def trim_touch():
    return trim_base() + [
        path('M74 92 L118 52', BARK, 6),          # the branch resting on the conductor
        line(118, 100, 124, 60, STEEL, 3.0), line(119, 57, 131, 57, STEEL, 4.0),  # the pole pruner
        earth_hung(), person(112, gloves=True, hand=(118, 100)),
        nest(30, 126),
    ]


def trim_nest():
    return trim_base() + [
        path('M66 98 L126 60', BARK, 5),          # the branch over the line, pruned
        line(100, GY - 6, 124, 62, STEEL, 3.0),   # the pole pruner
        circle(124, 60, 3.2, STEEL),
        earth_hung(), person(96, gloves=True, hand=(106, 92)),
        nest(32, 104),                             # the nest in the crown, left alone
        path('M46 96 L30 84', BARK, 3),
    ]


def trim_fell():
    return [ground(BACKS['trim'], GROUNDS['trim']), tree(80, rot=-36, base=GY), pole(160), conductor(50),
            saw(40, 150, -20), person(52, gloves=True, hand=(46, 146)),
            earth_hung(), nest(30, 140)]


def trim_nestcut():
    return trim_base() + [
        path('M62 84 L108 132', BARK, 5),         # the branch falling away
        nest(106, 134), saw(132, 146, 30),
        path('M116 120 q8 10 4 22', SHEEN, 2),
        person(70, gloves=True, hand=(88, 118)),
        earth_hung(),
    ]


def trim_bare():
    stubs = ''.join(line(40 + dx, 80 + dy, 40 + dx + 10, 76 + dy, BARK, 3)
                    for dx, dy in [(-14, 6), (-10, 28), (4, 40), (14, 14), (-18, 48), (10, 50)])
    return [ground(BACKS['trim'], GROUNDS['trim']), rect(36, 90, 8, 86, BARK), stubs, pole(160), conductor(50),
            person(104, gloves=True, hand=(118, 100)), earth_hung(), nest(60, 150), saw(136, 140, 20)]


def trim_live():
    return trim_base() + [
        path('M70 92 L122 52', BARK, 6),
        spark(120, 52, 9), spark(106, 60, 6), line(104, 68, 126, 46, STEEL, 3.0),
        person(96, gloves=True, hand=(108, 102)),
        earth_coil(128),
        nest(56, 102),
    ]


# ---------------------------------------------------------------- round 2: permit
def paper_stack_empty():
    """A stack of unstamped papers (the stamp is a dashed outline)."""
    return [rect(14, GY - 22, 30, 12, PAPER, rx=1),
            f'<circle cx="29" cy="{GY - 16}" r="5" fill="none" stroke="{STAMP}" stroke-width="1.6" stroke-dasharray="2 2"/>']


def permit_forest():
    return [ground(BACKS['permit'], GROUNDS['permit']), rect(0, 96, 58, 80, HOUSE), tree(176),
            rect(94, 62, 66, 52, PAPER, rx=3), circle(146, 92, 9, 'none', f' stroke="{STAMP}" stroke-width="2.4"'),
            f'<path d="M146 84 l-6 8 h4 l-5 8 h12 l-5 -8 h4 Z" fill="{CROWN}"/>',
            line(100, 124, 116, 124, BARK, 1.6), line(100, 104, 116, 104, BARK, 1.6),
            person(70, gloves=True, hand=(90, 88)), *paper_stack_empty()]


def permit_local():
    return [ground(BACKS['permit'], GROUNDS['permit']), rect(0, 96, 58, 80, HOUSE), tree(176),
            rect(94, 62, 66, 52, PAPER, rx=3), circle(146, 92, 9, 'none', f' stroke="{STAMP}" stroke-width="2.4"'),
            f'<path d="M140 96 h12 v-6 l-6 -5 l-6 5 Z" fill="{HOUSE}"/>',
            line(100, 124, 116, 124, BARK, 1.6), line(100, 104, 116, 104, BARK, 1.6),
            person(70, gloves=True, hand=(90, 88)), *paper_stack_empty()]


def permit_phone():
    return [ground(BACKS['permit'], GROUNDS['permit']), rect(0, 96, 58, 80, HOUSE), tree(176),
            rect(98, 78, 8, 14, PHONE, rx=2), rect(100, 80, 4, 7, SHEEN, rx=1),
            person(90, gloves=True, hand=(102, 94)),
            saw(120, GY - 8, -10), *paper_stack_empty()]


def permit_govt():
    return [ground(BACKS['permit'], GROUNDS['permit']), rect(0, 96, 58, 80, HOUSE), tree(176),
            line(126, GY, 126, 120, BARK, 3), line(134, GY, 134, 120, BARK, 3),  # a private yard fence
            line(120, 120, 176, 120, BARK, 2),
            line(92, 110, 84, 58, BARK, 4.5),                                   # the axe handle
            rect(78, 52, 14, 9, STEEL, rx=1.5),
            person(92, gloves=True, hand=(88, 84)), *paper_stack_empty()]


def owner(x, hand):
    """The tree's owner: plain kurta, no helmet, no gloves."""
    hx, hy = hand
    return el(rect(x - 6, GY - 30, 5, 30, PANTS), rect(x + 1, GY - 30, 5, 30, PANTS),
              rect(x - 9, GY - 58, 18, 30, KURTA, rx=5), circle(x, GY - 64, 8, SKIN),
              line(x + 7, GY - 52, hx, hy, KURTA, 6), circle(hx, hy, 4, SKIN))


def permit_quarrel():
    return [ground(BACKS['permit'], GROUNDS['permit']), rect(0, 96, 58, 80, HOUSE), tree(176),
            owner(70, hand=(82, 90)), person(116, gloves=True, hand=(104, 90)),
            f'<path d="M92 60 l4 -6 l4 6 l4 -6 l4 6" fill="none" stroke="{STAMP}" stroke-width="2"/>',
            *paper_stack_empty()]


# ---------------------------------------------------------------- round 3: oil
def oil_base(sheet=False, bare=False):
    o = [ground(BACKS['oil'], GROUNDS['oil'])]
    o += [rect(132, GY - 12, 62, 12, TRUCK, rx=1.5), rect(168, GY - 20, 26, 9, TRUCK, rx=1.5),
          rect(132, GY - 4, 6, 4, BOOT), circle(144, GY - 2, 3.4, BOOT), circle(180, GY - 2, 3.4, BOOT),
          rect(170, GY - 16, 6, 3, TRUCK_RED)]
    o += [rect(44, 100, 84, 62, TANK, rx=4), rect(56, 88, 10, 12, DRUM), rect(116, 88, 10, 12, DRUM),
          rect(40, 160, 92, 6, DRUM, rx=2)]
    return o


def drum(x, y, capped=True, tip=0):
    o = [rect(x - 10, y - 26, 20, 26, DRUM, rx=3)]
    if capped:
        o.append(rect(x - 11, y - 28, 22, 4, STEEL, rx=1.5))
    else:
        o.append(ellipse(x, y - 26, 10, 3, OIL))
    if tip:
        o.append(f'<g transform="rotate({tip} {f(x)} {f(y)})">' + rect(x - 10, y - 26, 20, 26, DRUM, rx=3) + '</g>')
    return ''.join(o)


def oil_sheet():
    return oil_base() + [rect(38, GY - 4, 124, 6, PLASTIC, rx=1), person(64, gloves=True, mask=True, hand=(78, 136)),
                         person(156, gloves=True, mask=True, hand=(146, 136)), drum(176, GY - 4)]


def oil_drums():
    return oil_base() + [rect(38, GY - 4, 60, 6, PLASTIC, rx=1), drum(64, GY - 4), drum(84, GY - 4),
                         drum(106, GY - 4), person(150, gloves=True, mask=True, hand=(140, 132))]


def oil_soil():
    return oil_base() + [rect(160, GY - 8, 26, 8, PLASTIC, rx=3),
                         ellipse(96, GY - 2, 14, 2.4, OIL), circle(96, 170, 2, OIL), circle(102, 160, 1.8, OIL),
                         person(70, gloves=True, mask=True, hand=(78, 136)), drum(176, GY - 4)]


def oil_drain():
    return oil_base() + [rect(38, GY - 4, 40, 6, PLASTIC, rx=1), rect(96, GY - 6, 26, 6, DRAIN, rx=1),
                         line(108, 124, 108, GY - 6, OIL, 3.5), rect(100, 118, 14, 8, TRUCK_RED, rx=1.5),
                         person(74, gloves=True, mask=True, hand=(104, 118)), drum(178, GY - 4)]


def oil_open():
    return oil_base() + [rect(38, GY - 4, 60, 6, PLASTIC, rx=1), drum(58, GY - 4, capped=False, tip=-40),
                         ellipse(92, GY - 3, 18, 3, OIL), person(140, gloves=True, mask=True, hand=(130, 136))]


def oil_bare():
    return oil_base() + [rect(38, GY - 4, 60, 6, PLASTIC, rx=1), rect(96, GY - 6, 26, 6, DRAIN, rx=1),
                         person(84, gloves=False, mask=False, hand=(100, 118)),
                         person(156, gloves=True, mask=True, hand=(146, 136)), drum(180, GY - 4)]


# ---------------------------------------------------------------- round 4: leak
def leak_base(puddle=40):
    o = [ground(BACKS['leak'], GROUNDS['leak']),
         rect(0, 58, W, 90, STORE),
         rect(146, 96, 40, 52, DRUM, rx=3), rect(144, 92, 44, 5, STEEL, rx=1.5),
         ellipse(70, GY + 6, puddle, 6, OIL), ellipse(70, GY + 6, puddle * 0.7, 3.4, SHEEN, ' opacity="0.7"'),
         f'<path d="M22 {GY} L42 {GY - 26} L60 {GY} Z" fill="{SAND}"/>',
         rect(20, GY - 12, 28, 12, SAWDUST, rx=2)]
    return o


def leak_sand():
    return leak_base() + [person(104, gloves=True, hand=(88, 134)), line(92, 126, 78, 140, STEEL, 3),
                          rect(86, 138, 12, 4, STEEL, rx=1), circle(72, 136, 2.4, SAND), circle(80, 140, 2, SAND),
                          circle(66, 142, 2, SAND)]


def leak_saw():
    return leak_base() + [person(104, gloves=True, hand=(88, 132)), circle(72, 136, 2.4, SAWDUST),
                          circle(80, 140, 2, SAWDUST), circle(64, 142, 2, SAWDUST), circle(70, 128, 2, SAWDUST),
                          rect(88, 128, 10, 6, SAWDUST, rx=1.5)]


def leak_hose():
    return leak_base(puddle=54) + [line(190, 100, 150, 120, HOSE, 4), path('M140 124 q-14 10 -28 6', HOSE, 2),
                                   person(176, gloves=True, mask=True, hand=(162, 118)),
                                   ellipse(70, GY + 6, 66, 9, SHEEN, ' opacity="0.45"'),
                                   rect(20, GY - 12, 28, 12, SAWDUST, rx=2)]


def leak_ignored():
    return leak_base(puddle=62) + [ellipse(70, GY + 6, 80, 10, SHEEN, ' opacity="0.35"'),
                                   person(188, gloves=True, mask=True, hand=(178, 136), s=0.45)]


def leak_broom():
    return leak_base() + [rect(108, GY - 8, 30, 8, DRAIN, rx=1), line(78, 132, 116, 160, BROOM, 4),
                          rect(112, 156, 14, 5, BROOM, rx=1),
                          path('M84 150 q18 6 26 10', OIL, 3), person(70, gloves=True, hand=(80, 132))]


# ---------------------------------------------------------------- round 5: scrap
def scrap_base():
    o = [ground(BACKS['scrap'], GROUNDS['scrap'])]
    o += [rect(138, 110, 50, 58, TRUCK, rx=5), rect(146, 116, 34, 14, POND, rx=2),
          rect(138, 166, 10, 10, BOOT, rx=3), rect(176, 166, 10, 10, BOOT, rx=3),
          rect(20, GY - 22, 44, 22, BATT, rx=2), rect(20, GY - 24, 44, 4, BATT_Y, rx=1),
          rect(186, 70, 6, 60, POLE), circle(189, 62, 9, '#3E9B4F'),
          path('M142 106 q5 -6 10 0 t10 0 t10 0', COPPER, 2.6),
          rect(60, GY - 12, 16, 12, JUTE, rx=2)]
    return o


def scrap_van():
    return scrap_base() + [rect(60, 110, 40, 48, TRUCK, rx=4), rect(68, 120, 24, 10, POND, rx=2),
                           rect(74, GY - 36, 22, 22, BATT, rx=2), rect(74, GY - 38, 22, 3, BATT_Y, rx=1),
                           person(116, gloves=True, hand=(108, 140)), circle(72, GY - 2, 3.4, BOOT)]


def scrap_bag():
    return scrap_base() + [rect(60, GY - 22, 16, 22, JUTE, rx=2), person(100, gloves=True, hand=(92, 150)),
                           path('M86 168 q6 -4 12 0', COPPER, 2.6), path('M96 172 q5 -3 9 0', COPPER, 2.6),
                           circle(120, 170, 2.6, COPPER)]


def scrap_cart():
    return scrap_base() + [line(44, 140, 80, 140, BARK, 4), rect(80, 128, 40, 14, BARK, rx=2),
                           rect(84, 118, 24, 12, BATT, rx=2), person(120, gloves=True, hand=(108, 140))]


def scrap_pond():
    return scrap_base() + [ellipse(68, 150, 40, 14, POND), rect(52, 130, 30, 18, BATT, rx=2),
                           rect(56, 128, 22, 4, BATT_Y, rx=1), person(120, gloves=True, hand=(110, 130))]


def scrap_field():
    return scrap_base() + [path('M86 170 q6 -4 12 0', COPPER, 2.6), circle(104, 168, 2.6, COPPER),
                           circle(116, 172, 2.6, COPPER), path('M70 160 q6 -4 12 0', COPPER, 2.6),
                           ellipse(94, 150, 9, 5, GOAT), circle(104, 144, 4, GOAT), rect(90, 154, 3, 10, GOAT),
                           rect(98, 154, 3, 10, GOAT), person(170, gloves=True, hand=(160, 140))]


# ---------------------------------------------------------------- the board
CARDS = {
    'trim_touch': trim_touch(), 'trim_nest': trim_nest(),
    'trim_fell': trim_fell(), 'trim_nestcut': trim_nestcut(), 'trim_bare': trim_bare(), 'trim_live': trim_live(),
    'permit_forest': permit_forest(), 'permit_local': permit_local(),
    'permit_phone': permit_phone(), 'permit_govt': permit_govt(), 'permit_quarrel': permit_quarrel(),
    'oil_sheet': oil_sheet(), 'oil_drums': oil_drums(),
    'oil_soil': oil_soil(), 'oil_drain': oil_drain(), 'oil_open': oil_open(), 'oil_bare': oil_bare(),
    'leak_sand': leak_sand(), 'leak_saw': leak_saw(),
    'leak_hose': leak_hose(), 'leak_ignored': leak_ignored(), 'leak_broom': leak_broom(),
    'scrap_van': scrap_van(), 'scrap_bag': scrap_bag(),
    'scrap_cart': scrap_cart(), 'scrap_pond': scrap_pond(), 'scrap_field': scrap_field(),
}
CARDS = {k: card(v) if isinstance(v, list) else v for k, v in CARDS.items()}

ROUNDS = {
    'trim': (['trim_touch', 'trim_nest'], ['trim_fell', 'trim_nestcut', 'trim_bare', 'trim_live']),
    'permit': (['permit_forest', 'permit_local'], ['permit_phone', 'permit_govt', 'permit_quarrel']),
    'oil': (['oil_sheet', 'oil_drums'], ['oil_soil', 'oil_drain', 'oil_open', 'oil_bare']),
    'leak': (['leak_sand', 'leak_saw'], ['leak_hose', 'leak_ignored', 'leak_broom']),
    'scrap': (['scrap_van', 'scrap_bag'], ['scrap_cart', 'scrap_pond', 'scrap_field']),
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
            for hand in itertools.combinations(traps, min(HAND - 1, len(traps))):
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
