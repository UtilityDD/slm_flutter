"""Picture cards for lesson 8.1 শেখা ("WBERC পরিচিতি: রাজ্যের পাওয়ার বস").

python -I tool/m8_board81_art.py .

Writes assets/game/art/m8_board81/*.svg: 200 x 220 scene cards, drawn edge to
edge in the clean gradient style of tool/m6_board63_art.py. No words in the
art (no <text>): the only labels are the plain shapes a reader knows (a
plate, a sign board, a seal), and the names live in the Bangla labels.

What the cards show comes from lesson 8.1 (live text) and the Module 8
rulings (docs/module_specs/module8_rulings.md) only:
  1. ref: the referee. The WBERC building stands on its own (safe); the
     referee stands in the middle between a company office and the homes
     (safe). Traps: a WBERC plate inside the company office, the referee in
     the company's colours whistling only at the homes, company officers alone
     in a boardroom under an empty chair, one office with two counters;
  2. bal: the balance of interests (safe): a scale with a home on one pan and
     a company office on the other, and a commission table with two files.
     Traps: the scale tipped to a money bag, tipped to the homes with the
     office shuttered, a one-pan scale holding only a cost sheet;
  3. bill: a complaint about a high bill (safe): the trainee turns the bill
     over to a tariff table, or points to the tariff chart on the notice
     board, calm faces. Traps: shouting face to face, shrugging at the
     company office, a line struck on the bill with a pen;
  4. sop: the time limit for a fuse complaint (safe): the trainee leaves with
     the complaint slip glancing at the clock, or a new-connection file moves
     past a calendar with a few pages turned. Traps: a complaint slip under a
     tea glass, a dark house with calendar pages flying, a dusty file with a
     cobweb;
  5. lic: who grants the licence (safe): a framed WBERC-sealed licence on a
     company office wall, or three certificates on the commission's desk.
     Traps: a company officer signing a licence to his own company, a licence
     stamped as forever beside a torn rule book, a courtroom bench marked
     APTEL handing out licences.

Fairness (the playbook, section 4): every card of a round shares one
backdrop, and every card of a round draws the same set of colours and
gradients (a palette strip along the foot of each card). So the safe card's
backdrop and colours are on every trap in every hand the dealer can make. The
script checks every hand (one safe card + any three traps) and deletes only
its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board81_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board81')
W, H = 200, 220
GY = 172  # the ground line every figure stands on

WB = '#1F5F8F'      # WBERC blue
WB_D = '#174A70'
WB_L = '#EEF4F7'    # the commission's white stone
CO = '#D9822B'      # company orange (a company office)
CO_D = '#B5651F'
CE = '#B5573A'      # a second company's brick
HOME = '#E9DDC4'
HOME_R = '#9A4E35'
WIN = '#D6E7F0'
WIN_OFF = '#2E3A46'
DARK = '#1B232C'
PAPER = '#F4F1E6'
INK = '#4A5560'
WOOD = '#9A7650'
WOOD_D = '#6B5B3E'
GOLD = '#E5B92E'
RED = '#C8352B'
GREEN = '#3E9B4F'
SKIN = '#A86E48'
SKIN2 = '#D9A27A'
HAIR = '#2A1E16'
PANTS = '#2A3442'
GREY = '#7C8C98'
STEEL = '#C3CBD1'
GRASS = '#9DBB72'
PAVE = '#B9B39E'
BRASS = '#C9A43A'
TEA = '#C98A4B'
GLASS = '#D6E7F0'
COB = '#D9DDE0'
FOLDER = '#B9A07A'

DEFS = """<defs>
  <linearGradient id="refbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CFE3EE"/><stop offset="1" stop-color="#EEF4F7"/></linearGradient>
  <linearGradient id="balbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6E9EF"/><stop offset="1" stop-color="#F7F5EC"/></linearGradient>
  <linearGradient id="billbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9EEDF"/><stop offset="1" stop-color="#F3F8F1"/></linearGradient>
  <linearGradient id="sopbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6E2CF"/><stop offset="1" stop-color="#FBF3EA"/></linearGradient>
  <linearGradient id="licbg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E3DAF0"/><stop offset="1" stop-color="#F5F1FA"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

ROUND_BG = {'ref': 'refbg', 'bal': 'balbg', 'bill': 'billbg', 'sop': 'sopbg', 'lic': 'licbg'}


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


# --------------------------------------------------------------------------
# Shapes
# --------------------------------------------------------------------------

def rect(x, y, w, h, fill, rx=None, stroke=None, sw=None, extra=''):
    s = f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" fill="{fill}"'
    if rx:
        s += f' rx="{f(rx)}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{f(sw or 1.5)}"'
    return s + (f' {extra}' if extra else '') + '/>'


def circ(cx, cy, r, fill, stroke=None, sw=None):
    s = f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{f(sw or 1.5)}"'
    return s + '/>'


def line(x1, y1, x2, y2, col, sw=2):
    return (f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{col}" stroke-width="{f(sw)}" '
            'stroke-linecap="round" fill="none"/>')


def poly(pts, fill, stroke=None, sw=None):
    d = ' '.join(f'{f(x)},{f(y)}' for x, y in pts)
    s = f'<polygon points="{d}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{f(sw or 1.5)}" stroke-linejoin="round"'
    return s + '/>'


def ground(col):
    return [rect(0, GY, W, H - GY, col)]


def block(x, foot, w, h, wall, rows=3, cols=3, win=WIN):
    """A plain office block: wall, and a grid of windows."""
    out = [rect(x, foot - h, w, h, wall, rx=2)]
    ww, wh = w / (cols * 2 + 1), h / (rows * 2 + 1)
    for r in range(rows):
        for c in range(cols):
            out.append(rect(x + ww + c * 2 * ww, foot - h + wh + r * 2 * wh, ww, wh, win))
    return out


def house(x, foot, w, h, wall=HOME, roof=HOME_R):
    return [
        rect(x, foot - h, w, h, wall),
        poly([(x - 3, foot - h), (x + w / 2, foot - h - w * 0.5), (x + w + 3, foot - h)], roof),
        rect(x + w * 0.2, foot - h * 0.7, w * 0.22, h * 0.3, WIN),
        rect(x + w * 0.6, foot - h * 0.7, w * 0.22, h * 0.3, WIN),
    ]


def person(cx, foot, shirt, s=1.0, arms='down', skin=SKIN, band=None, whistle=None, face_out=False):
    """A standing figure (tool/m6_board63_art.py's worker, simplified).
    Returns (elements, head_xy)."""
    hip = foot - 26 * s
    neck = foot - 50 * s
    hr = 7 * s
    hy = neck - hr - 1 * s
    out = [
        rect(cx - 6 * s, hip, 5 * s, 26 * s, PANTS, rx=1.5),
        rect(cx + 1 * s, hip, 5 * s, 26 * s, PANTS, rx=1.5),
        rect(cx - 9 * s, neck, 18 * s, 27 * s, shirt, rx=4 * s),
        circ(cx, hy, hr, skin),
        f'<path d="M{f(cx - hr)} {f(hy)} A{f(hr)} {f(hr)} 0 0 1 {f(cx + hr)} {f(hy)} Z" fill="{HAIR}"/>',
    ]
    sh = neck + 4 * s
    if arms == 'down':
        out += [line(cx - 9 * s, sh, cx - 12 * s, hip + 2 * s, shirt, 5 * s),
                line(cx + 9 * s, sh, cx + 12 * s, hip + 2 * s, shirt, 5 * s)]
    elif arms == 'up':
        out += [line(cx - 9 * s, sh, cx - 19 * s, neck - 10 * s, shirt, 5 * s),
                line(cx + 9 * s, sh, cx + 19 * s, neck - 10 * s, shirt, 5 * s)]
    elif arms == 'point':
        out += [line(cx - 9 * s, sh, cx - 12 * s, hip + 2 * s, shirt, 5 * s),
                line(cx + 9 * s, sh, cx + 27 * s, sh + 3 * s, shirt, 5 * s)]
    elif arms == 'point_l':
        out += [line(cx + 9 * s, sh, cx + 12 * s, hip + 2 * s, shirt, 5 * s),
                line(cx - 9 * s, sh, cx - 27 * s, sh + 3 * s, shirt, 5 * s)]
    elif arms == 'hold':
        out += [line(cx - 9 * s, sh, cx - 1 * s, sh + 15 * s, shirt, 5 * s),
                line(cx + 9 * s, sh, cx + 1 * s, sh + 15 * s, shirt, 5 * s)]
    elif arms == 'write':
        out += [line(cx - 9 * s, sh, cx - 12 * s, hip + 2 * s, shirt, 5 * s),
                line(cx + 9 * s, sh, cx + 15 * s, sh + 14 * s, shirt, 5 * s)]
    if band:
        out.append(rect(cx - 15 * s, sh + 1 * s, 7 * s, 5 * s, band, rx=1))
    if whistle:
        out.append(circ(cx + 5 * s, neck + 7 * s, 2.2 * s, whistle))
    return out, (cx, hy)


def scale(cx, py, tilt, left_pan, right_pan, half=44, pan=20):
    """A balance: tilt -1 (left low), 0 (level), 1 (right low). left_pan and
    right_pan are callbacks that draw the pan contents at (x, top_y); None =
    an empty pan, 'none' = no pan at all (the one-pan scale)."""
    ly, ry = py - 12 * tilt, py + 12 * tilt
    lx, rx = cx - half, cx + half
    out = [rect(cx - 4, py, 8, GY - py - 2, STEEL), rect(cx - 22, GY - 6, 44, 6, STEEL, rx=2),
           line(lx, ly, rx, ry, INK, 4), circ(cx, py, 5, GOLD)]
    for x, y, pan_fn in ((lx, ly, left_pan), (rx, ry, right_pan)):
        if pan_fn == 'none':
            out.append(line(x, y, x, y + 8, GREY, 1.5))
            continue
        out += [line(x, y, x - pan, y + 30, INK, 1.5), line(x, y, x + pan, y + 30, INK, 1.5),
                rect(x - pan - 2, y + 30, 2 * pan + 4, 5, INK, rx=2)]
        if pan_fn:
            out += pan_fn(x, y + 30)
    return out


# --------------------------------------------------------------------------
# Round 1: ref (the referee)
# --------------------------------------------------------------------------

def ref_sep():
    out = ground(PAVE) + [rect(0, GY + 14, W, 3, STEEL)]
    out += [rect(8, GY - 40, 30, 40, CO), rect(160, GY - 36, 32, 36, CE)]
    out += [rect(58, 96, 84, GY - 96, WB), poly([(52, 96), (100, 68), (148, 96)], WB_D)]
    for i in range(4):
        out.append(rect(64 + i * 20, 106, 7, GY - 106, WB_L))
    out.append(rect(90, GY - 30, 20, 30, INK, rx=2))
    return out


def ref_mid():
    out = ground(PAVE) + [rect(0, GY + 14, W, 3, STEEL)]
    out += block(4, GY, 56, 64, CO, rows=3, cols=2)
    out += house(128, GY, 30, 28) + house(164, GY, 30, 28)
    body, _ = person(96, GY, WB, s=1.25, arms='hold', band=GOLD, whistle=RED)
    return out + body


def ref_plate():
    out = ground(PAVE)
    out += [rect(26, 40, 148, GY - 40, CO, rx=3)]
    for c in range(4):
        out.append(rect(34 + c * 34, 56, 18, 18, WIN))
    out += [circ(100, 90, 9, PAPER), rect(60, GY - 46, 80, 46, CO_D)]
    out += [rect(92, GY - 58, 34, 12, WB, rx=2)]  # the WBERC plate inside
    out += [rect(56, GY - 36, 88, 8, WOOD)]
    return out


def ref_tilt():
    out = ground(PAVE) + [rect(0, GY + 14, W, 3, STEEL)]
    out += block(2, GY, 40, 52, CO, rows=2, cols=2)
    out += house(128, GY, 30, 28) + house(164, GY, 30, 28)
    body, _ = person(70, GY, CO, s=1.25, arms='point', whistle=RED)
    return out + body


def ref_board():
    out = [rect(10, 36, 180, GY - 36, WIN, rx=4)]
    out += [rect(86, 62, 44, 6, GREY, rx=2), rect(96, 44, 4, 18, WOOD_D)]  # the empty chair up top
    out += [rect(28, GY - 34, 144, 8, WOOD), rect(36, GY - 26, 6, 26, WOOD_D), rect(158, GY - 26, 6, 26, WOOD_D)]
    b1, _ = person(70, GY, CO_D, s=1.0, arms='write')
    b2, _ = person(126, GY, CO, s=1.0, arms='write')
    return out + b1 + b2


def ref_counter():
    out = [rect(14, 30, 172, GY - 30, CO_D, rx=3)]
    for c in range(5):
        out.append(rect(24 + c * 34, 40, 20, 16, WIN))
    out += [rect(26, GY - 34, 66, 34, WOOD), rect(108, GY - 34, 66, 34, WOOD)]
    out += [rect(44, GY - 48, 30, 12, WB, rx=2), rect(122, GY - 48, 30, 12, CO, rx=2)]
    return out


# --------------------------------------------------------------------------
# Round 2: bal (the balance of interests)
# --------------------------------------------------------------------------

def _house_pan(x, top):
    return [rect(x - 14, top - 16, 28, 16, HOME), poly([(x - 18, top - 16), (x, top - 28), (x + 18, top - 16)], HOME_R)]


def _office_pan(x, top):
    return [rect(x - 13, top - 26, 26, 26, CO, rx=2), rect(x - 8, top - 20, 6, 6, WIN), rect(x + 2, top - 20, 6, 6, WIN)]


def _bag_pan(x, top):
    return [circ(x, top - 10, 10, BRASS), rect(x - 6, top - 22, 12, 6, WOOD_D, rx=1)]


def _sheet_pan(x, top):
    return [rect(x - 16, top - 22, 32, 22, PAPER, stroke=INK, sw=1), line(x - 10, top - 16, x + 10, top - 16, INK, 1.5),
            line(x - 10, top - 10, x + 10, top - 10, INK, 1.5)]


def bal_scale():
    out = ground(PAVE)
    out += scale(100, 60, 0, _house_pan, _office_pan)
    return out


def bal_files():
    out = [rect(0, 36, W, 30, WIN)]
    out += [rect(84, 46, 32, 12, WB, rx=2)]
    out += [rect(18, 118, 164, 10, WOOD), rect(24, 128, 8, GY - 128, WOOD_D), rect(168, 128, 8, GY - 128, WOOD_D)]
    out += [rect(34, 80, 64, 38, PAPER, stroke=INK, sw=1), rect(34, 74, 24, 7, WB, rx=1)]
    out += [poly([(54, 104), (66, 92), (78, 104)], HOME_R), rect(58, 104, 16, 14, HOME)]
    out += [rect(102, 80, 64, 38, PAPER, stroke=INK, sw=1), rect(102, 74, 24, 7, CO, rx=1)]
    out += [rect(124, 98, 22, 20, CO), rect(128, 102, 5, 5, WIN), rect(136, 102, 5, 5, WIN)]
    return out


def bal_tipco():
    out = ground(PAVE)
    out += scale(100, 60, 1, None, _bag_pan)
    return out


def bal_tiphome():
    out = ground(PAVE)
    out += scale(68, 60, -1, _house_pan, None)
    out += [rect(138, GY - 74, 58, 74, CO, rx=2)]
    out += [rect(142, GY - 56, 50, 26, GREY, rx=1), rect(160, GY - 36, 12, 10, GOLD, rx=2)]
    out += [line(164, GY - 36, 164, GY - 42, GOLD, 2), line(170, GY - 36, 170, GY - 42, GOLD, 2)]
    return out


def bal_one():
    out = ground(PAVE)
    out += [rect(96, 56, 8, GY - 56, STEEL), rect(78, GY - 6, 44, 6, STEEL, rx=2)]
    out += [line(56, 60, 150, 60, INK, 4), circ(100, 60, 5, GOLD)]
    out += [line(56, 60, 36, 92, INK, 1.5), line(56, 60, 76, 92, INK, 1.5), rect(32, 92, 48, 5, INK, rx=2)]
    out += _sheet_pan(56, 92)
    out += [line(150, 60, 150, 84, GREY, 1.5)]
    return out


# --------------------------------------------------------------------------
# Round 3: bill (a complaint about a high bill)
# --------------------------------------------------------------------------

def _bill_back(x, y, w, h):
    out = [rect(x, y, w, h, PAPER, stroke=INK, sw=1)]
    for r in range(1, 4):
        out.append(line(x + 4, y + r * h / 4, x + w - 4, y + r * h / 4, INK, 1.2))
    out.append(line(x + w / 2, y + 4, x + w / 2, y + h - 4, INK, 1.2))
    return out


def bill_door():
    out = [rect(0, 0, W, GY, WIN), rect(106, 46, 56, GY - 46, WOOD)]
    out += [rect(156, 90, 5, 6, GOLD)]
    t, _ = person(70, GY, WB, s=1.2, arms='hold', band=GOLD)
    c, _ = person(146, GY, CO_D, s=1.2, arms='down', skin=SKIN2)
    out += ground(PAVE) + t + c
    out += _bill_back(56, 96, 40, 28)
    return out


def bill_chart():
    out = [rect(0, 0, W, GY, WIN)]
    out += [rect(36, 34, 128, 70, WOOD_D, rx=2), rect(42, 40, 116, 58, PAPER)]
    for i, hgt in enumerate([24, 36, 30, 44]):
        out.append(rect(52 + i * 26, 92 - hgt, 14, hgt, WB if i % 2 else CO))
    t, _ = person(64, GY, WB, s=1.1, arms='down')
    c, _ = person(150, GY, CO_D, s=1.15, arms='point_l', skin=SKIN2)
    out += t + c
    out += [rect(18, GY - 40, 164, 40, WOOD), rect(14, GY - 44, 172, 6, WOOD_D)]
    return out


def bill_shout():
    out = ground(PAVE)
    a, (ax, ay) = person(60, GY, WB, s=1.15, arms='up')
    b, (bx, by) = person(142, GY, CO_D, s=1.15, arms='up', skin=SKIN2)
    out += a + b + [circ(ax + 5, ay + 5, 2.2, RED), circ(bx - 5, by + 5, 2.2, RED)]
    out += [poly([(86, 118), (98, 104), (106, 116), (116, 102), (126, 120), (112, 130), (96, 126)], PAPER, stroke=INK, sw=1)]
    return out


def bill_shrug():
    out = ground(PAVE)
    out += block(136, GY, 60, 84, CO, rows=4, cols=2)
    a, _ = person(70, GY, WB, s=1.25, arms='point', band=GOLD)
    return out + a


def bill_strike():
    out = [rect(0, 0, W, GY, WIN)]
    out += [rect(14, GY - 40, 172, 8, WOOD), rect(22, GY - 32, 6, 32, WOOD_D), rect(172, GY - 32, 6, 32, WOOD_D)]
    out += [rect(54, GY - 50, 90, 10, PAPER, stroke=INK, sw=1)]
    out += [line(58, GY - 45, 140, GY - 45, RED, 3)]
    a, _ = person(100, GY, WB, s=1.2, arms='write')
    return out + a + [rect(14, GY - 40, 172, 8, WOOD)]


# --------------------------------------------------------------------------
# Round 4: sop (the time limit for a fuse complaint)
# --------------------------------------------------------------------------

def sop_leave():
    out = [rect(0, 16, 110, GY - 16, WIN), rect(92, 74, 24, GY - 74, WOOD_D)]
    out += [circ(56, 46, 13, PAPER, stroke=INK, sw=1.5), line(56, 46, 56, 38, INK, 2), line(56, 46, 63, 48, INK, 2)]
    out += [rect(128, GY - 44, 58, 34, WB_D, rx=3), rect(182, GY - 30, 14, 20, WB, rx=2)]
    out += [rect(122, GY - 40, 6, 30, WB), circ(144, GY, 6, INK), circ(182, GY, 6, INK)]
    out += ground(PAVE)
    a, _ = person(112, GY, WB, s=1.2, arms='hold')
    out += [rect(104, GY - 66, 14, 10, PAPER, stroke=INK, sw=0.8)]
    return out + a


def sop_file():
    out = [rect(0, 0, W, GY, WIN)]
    out += [rect(116, 26, 68, 62, PAPER, stroke=INK, sw=1), rect(116, 26, 68, 12, WB)]
    for r in range(3):
        for c in range(4):
            out.append(rect(122 + c * 15, 44 + r * 13, 11, 8, PAPER, stroke=INK, sw=0.6))
    out += [rect(124, 44, 11, 8, RED), rect(139, 44, 11, 8, RED)]
    out += [rect(72, 100, 62, 20, PAPER, stroke=INK, sw=1), rect(72, 94, 22, 7, GREEN, rx=1)]
    out += [line(36, 108, 66, 108, STEEL, 2), line(30, 116, 60, 116, STEEL, 2)]
    out += [rect(0, 120, W, 10, WOOD), rect(20, 130, 8, GY - 130, WOOD_D), rect(172, 130, 8, GY - 130, WOOD_D)]
    return out


def sop_tea():
    out = [rect(0, 0, W, GY, WIN)]
    out += [rect(14, 120, 172, 10, WOOD), rect(22, 130, 8, GY - 130, WOOD_D), rect(170, 130, 8, GY - 130, WOOD_D)]
    out += [rect(36, 108, 52, 14, PAPER, stroke=INK, sw=1), line(42, 113, 80, 113, INK, 1.2)]
    out += [rect(62, 92, 14, 24, GLASS, rx=2), rect(64, 100, 10, 14, TEA, rx=1)]
    a, _ = person(146, GY - 20, CO, s=1.05, arms='down', skin=SKIN2)
    return out + a


def sop_dark():
    out = ground(PAVE)
    out += [poly([(36, 66), (84, 34), (132, 66)], WIN_OFF), rect(36, 66, 96, GY - 66, WIN_OFF)]
    out += [rect(44, 82, 20, 20, DARK), rect(96, 82, 20, 20, DARK), rect(70, 120, 18, GY - 120, DARK)]
    out += [rect(94, 84, 16, 18, GREY)]
    out += [f'<rect x="150" y="34" width="22" height="16" fill="{PAPER}" transform="rotate(18 161 42)"/>',
            f'<rect x="162" y="66" width="20" height="14" fill="{PAPER}" transform="rotate(-22 172 73)"/>',
            f'<rect x="136" y="90" width="18" height="13" fill="{PAPER}" transform="rotate(30 145 96)"/>']
    return out


def sop_cob():
    out = [rect(0, 0, W, GY, WIN), rect(10, 112, 180, 8, WOOD_D), rect(18, 120, 6, 30, WOOD_D), rect(176, 120, 6, 30, WOOD_D)]
    out += [rect(58, 80, 58, 32, FOLDER, rx=2), rect(58, 74, 22, 8, FOLDER, rx=1)]
    out += [line(0, 0, 58, 0, COB, 1.5), line(0, 0, 0, 58, COB, 1.5), line(0, 0, 40, 40, COB, 1.5),
            f'<path d="M0 28 Q 28 28 28 0" stroke="{COB}" stroke-width="1.5" fill="none"/>',
            f'<path d="M0 46 Q 46 44 46 0" stroke="{COB}" stroke-width="1.5" fill="none"/>',
            circ(30, 60, 2.5, COB), circ(42, 18, 2.5, COB)]
    out += [circ(120, 98, 2, COB), circ(150, 92, 2, COB), circ(172, 100, 2, COB)]
    return out


# --------------------------------------------------------------------------
# Round 5: lic (who grants the licence)
# --------------------------------------------------------------------------

def lic_wall():
    out = [rect(0, 0, W, GY, WIN), rect(0, GY, W, H - GY, CO)]
    out += [rect(40, 36, 120, 96, PAPER, stroke=WB, sw=4), rect(60, 56, 80, 6, WB, rx=2), rect(66, 70, 68, 4, INK, rx=2),
            rect(66, 80, 56, 4, INK, rx=2)]
    out += [poly([(124, 118), (120, 140), (130, 134)], RED), poly([(144, 118), (148, 140), (138, 134)], RED)]
    out += [circ(134, 112, 14, GOLD), circ(134, 112, 8, WB)]
    return out


def lic_three():
    out = [rect(0, 0, W, GY, WIN)]
    out += [rect(12, 120, 176, 10, WOOD), rect(20, 130, 8, GY - 130, WOOD_D), rect(172, 130, 8, GY - 130, WOOD_D)]
    out += [rect(28, 78, 52, 40, PAPER, stroke=INK, sw=1), rect(28, 78, 52, 8, GREEN)]
    out += [rect(72, 66, 52, 40, PAPER, stroke=INK, sw=1), rect(72, 66, 52, 8, CO)]
    out += [rect(116, 78, 52, 40, PAPER, stroke=INK, sw=1), rect(116, 78, 52, 8, WB)]
    for x in (34, 78, 122):
        out.append(line(x, 98, x + 36, 98, INK, 1.5))
    return out


def lic_self():
    out = [rect(0, 0, W, GY - 40, WIN), rect(0, GY - 40, W, 40, PAVE)]
    out += [rect(20, GY - 40, 160, 8, WOOD)]
    out += [rect(118, GY - 50, 60, 12, PAPER, stroke=INK, sw=1), rect(118, GY - 50, 60, 4, CO)]
    a, _ = person(92, GY, CO_D, s=1.2, arms='write')
    return out + a


def lic_torn():
    out = [rect(0, 0, W, GY, WIN), rect(0, GY - 36, W, 36, WOOD)]
    out += [rect(24, 52, 84, 62, PAPER, stroke=WB, sw=4), rect(40, 70, 52, 5, WB, rx=2)]
    out += [circ(86, 98, 14, RED, stroke=RED, sw=2)]
    out += [rect(116, 116, 70, 46, WB_D, rx=2)]
    out += [poly([(116, 116), (148, 116), (140, 128), (152, 138), (140, 148), (150, 154), (116, 154)], PAPER)]
    out += [line(120, 124, 140, 124, INK, 1.2), line(120, 140, 136, 140, INK, 1.2)]
    return out


def lic_apt():
    out = [rect(0, 0, W, GY, COB), rect(0, GY - 8, W, 8, WOOD_D)]
    out += [rect(72, 48, 56, 24, WB, rx=2), rect(80, 56, 40, 3, WB_L), rect(80, 62, 28, 3, WB_L)]
    out += [rect(16, 118, 168, 10, WOOD), rect(18, 128, 164, GY - 128, WOOD_D)]
    out += [rect(46, 104, 44, 12, PAPER, stroke=INK, sw=0.8), rect(54, 100, 40, 12, PAPER, stroke=INK, sw=0.8)]
    a, _ = person(140, 118, WB, s=1.1, arms='hold', band=GOLD)
    return out + a


# --------------------------------------------------------------------------
# The cards. Round id, card name, drawing, safe?  (mirrors learn_board_pack81.dart)
# --------------------------------------------------------------------------

ROUNDS = {
    'ref': (
        {'ref_sep': ref_sep, 'ref_mid': ref_mid},
        {'ref_plate': ref_plate, 'ref_tilt': ref_tilt, 'ref_board': ref_board, 'ref_counter': ref_counter},
    ),
    'bal': (
        {'bal_scale': bal_scale, 'bal_files': bal_files},
        {'bal_tipco': bal_tipco, 'bal_tiphome': bal_tiphome, 'bal_one': bal_one},
    ),
    'bill': (
        {'bill_door': bill_door, 'bill_chart': bill_chart},
        {'bill_shout': bill_shout, 'bill_shrug': bill_shrug, 'bill_strike': bill_strike},
    ),
    'sop': (
        {'sop_leave': sop_leave, 'sop_file': sop_file},
        {'sop_tea': sop_tea, 'sop_dark': sop_dark, 'sop_cob': sop_cob},
    ),
    'lic': (
        {'lic_wall': lic_wall, 'lic_three': lic_three},
        {'lic_self': lic_self, 'lic_torn': lic_torn, 'lic_apt': lic_apt},
    ),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def _card(rid, body_elems, palette):
    strip = []
    n = len(palette)
    for i, tok in enumerate(palette):
        x0 = i * W / n
        strip.append(rect(x0, 206, W / n + 0.5, 14, tok))
    lines = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
             '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{ROUND_BG[rid]})"/>']
    lines += body_elems + strip
    lines.append('</g>')
    lines.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    lines.append('</svg>')
    return '\n'.join(lines)


def build():
    cards = {}
    for rid, (safe, traps) in ROUNDS.items():
        bodies = {}
        for name, fn in {**safe, **traps}.items():
            bodies[name] = fn()
        # Every card of the round draws the round's whole colour set, so no
        # colour can give the safe card away (the same palette strip on all).
        union = {f'url(#{ROUND_BG[rid]})'}
        for elems in bodies.values():
            union |= set(_TOKEN.findall(' '.join(elems)))
        palette = sorted(union)
        for name, elems in bodies.items():
            cards[name] = _card(rid, elems, palette)
    return cards


CARDS = build()


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rid, (safe, traps) in ROUNDS.items():
        for s in safe:
            for hand in itertools.combinations(list(traps), HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rid}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rid}: {s} with {hand} draws {sorted(only)} alone')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old[:-4] not in CARDS:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        if '<text' in svg:
            print('WORDS in', name)
            sys.exit(1)
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
