"""Picture cards for lesson 8.6 শেখা ("গ্রাহক অভিযোগ নিষ্পত্তি (Grievance
Redressal): আপনার কাজের পর্যালোচনা").

python -I tool/m8_board86_art.py .

Writes assets/game/art/m8_board86/*.svg (200 x 220 scene cards, drawn edge to
edge, the Module 6 board style of tool/m6_board63_art.py). No words in the
art: a worker reads the phone's 1912 and the counter's ID as stroke digits,
and the rest is drawn as objects (a phone, a slip, a form, a calendar).

What the cards show comes from lesson 8.6 (live text) and the Module 8
rulings only:
  1. docket: a docket made by 1912 (a phone with an SMS docket number) or at
     the CCC counter (a printed slip with an ID). Traps: a shout in the street
     with no paper, a tea-stall word of mouth, a docket written on a palm;
  2. calm: asking politely for the docket number, or handing over the CGRF
     form calmly. Traps: a red-faced argument, a 'tomorrow' promise with a
     calendar, a hand waved the consumer away;
  3. close: the slip stamped CLOSED on the office desk, or read out from the
     van by phone to the office. Traps: the van leaving with the slip still
     open on the dashboard, an office board of open dockets, telling the
     consumer and walking off;
  4. cgrf: the CGRF forum room (officers and one neutral member in a different
     coat) or the consumer filling its form beside the lineman. Traps: a street
     quarrel, a night knock at the lineman's door, tearing up the slip in the
     dark;
  5. order: a CGRF order copy on top of the day's papers with the crew going
     to that job first, or the MD passing on an Ombudsman ruling. Traps: the
     order pushed into a drawer, an officer tearing up the ruling, the order
     left on a desk with a far-off date and the crew drinking tea.

Round 4 of the spec (the false complaint: photo or video) left the board
(ruling M8-21: do_8_6_b plays it).

Fairness (GAME_LEVEL_PLAYBOOK §4): every card in a round shares one backdrop
and the same six palette colours (the wall notice, the footer stripe, the
floor, the shirt, the skin, the ink), so no colour or backdrop can give the
safe card away. The script checks every hand the dealer can make (one safe
card plus all three traps): each colour the safe card draws is drawn by
a trap in that hand, and the safe card's backdrop is a trap's backdrop too.
It deletes only its own stale cards.
"""

import itertools
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board86_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board86')
W, H = 200, 220
FLOOR_Y = 170
GY = 196

INK = '#2B3138'
PAPER = '#F4F1E6'
YELLOW = '#FFD34E'
SKIN = '#A86E48'
PALETTE = {INK, PAPER, YELLOW, SKIN, '#FFFFFF', 'url(#card)', 'url(#shirt)', 'url(#floor)'}

DEFS = """<defs>
  <linearGradient id="bg_docket" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="bg_calm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9D7B8"/><stop offset="1" stop-color="#F6EEDC"/></linearGradient>
  <linearGradient id="bg_close" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9FC7B4"/><stop offset="1" stop-color="#DDEEE5"/></linearGradient>
  <linearGradient id="bg_cgrf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9B5D6"/><stop offset="1" stop-color="#E6E3F1"/></linearGradient>
  <linearGradient id="bg_order" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9B7B0"/><stop offset="1" stop-color="#F3E3DE"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9C2AE"/><stop offset="1" stop-color="#A89F88"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def line(x1, y1, x2, y2, color=INK, w=2.0):
    return (f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{color}" stroke-width="{f(w)}" '
            'stroke-linecap="round" fill="none"/>')


def rect(x, y, w, h, fill, rx=0):
    r = f' rx="{f(rx)}"' if rx else ''
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}"{r} fill="{fill}"/>'


def circle(x, y, r, fill):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{fill}"/>'


def ring(x, y, r, color=INK):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="none" stroke="{color}" stroke-width="2"/>'


# --------------------------------------------------------------------------
# People: a lineman (helmet, gloves or bare hands) or a consumer or officer.
# --------------------------------------------------------------------------

def person(x, hands, face=1, mouth=None, helmet=False, gloves=True, coat=None, s=1.0, sag=6.0):
    """A standing person, feet at (x, GY), scaled [s] about the feet. [hands]
    are the two hand points in card coordinates (left, right)."""
    g = []
    trousers = INK
    top = coat or 'url(#shirt)'

    g.append(line(x - 3, GY - 26, x - 4, GY, trousers, 6))
    g.append(line(x + 3, GY - 26, x + 4, GY, trousers, 6))
    g.append(f'<path d="M{f(x - 8)} {f(GY - 52)} L{f(x + 8)} {f(GY - 52)} L{f(x + 7)} {f(GY - 26)} '
             f'L{f(x - 7)} {f(GY - 26)} Z" fill="{top}"/>')
    g.append(circle(x, GY - 64, 7, SKIN))
    g.append(circle(x - 2.5 * face, GY - 66, 0.9, INK))
    g.append(circle(x + 2.5 * face, GY - 66, 0.9, INK))
    if mouth == 'open':
        g.append(f'<ellipse cx="{f(x + 2 * face)}" cy="{f(GY - 60)}" rx="2" ry="2.6" fill="{INK}"/>')
    elif mouth == 'smile':
        g.append(f'<path d="M{f(x - 2)} {f(GY - 60)} Q{f(x)} {f(GY - 57)} {f(x + 2)} {f(GY - 60)}" '
                 f'stroke="{INK}" stroke-width="1.2" fill="none"/>')
    if helmet:
        g.append(f'<path d="M{f(x - 8)} {f(GY - 66)} A8 8 0 0 1 {f(x + 8)} {f(GY - 66)} Z" fill="{YELLOW}"/>')
        g.append(rect(x - 9, GY - 67, 18, 2.6, YELLOW, 1.2))
    shoulders = ((x - 7, GY - 49), (x + 7, GY - 49))
    for (sx, sy), (hx, hy) in zip(shoulders, hands):
        mx, my = (sx + hx) / 2, (sy + hy) / 2 + sag
        g.append(f'<path d="M{f(sx)} {f(sy)} Q{f(mx)} {f(my)} {f(hx)} {f(hy)}" stroke="{top}" '
                 'stroke-width="6" stroke-linecap="round" fill="none"/>')
        g.append(circle(hx, hy, 3.4, INK if gloves else SKIN))
    body = ''.join(g)
    if s == 1.0:
        return body
    return f'<g transform="translate({f(x)} {f(GY)}) scale({s}) translate({f(-x)} {f(-GY)})">{body}</g>'


# --------------------------------------------------------------------------
# Objects: a phone, a slip, a form, a counter, a house, a van, a pole.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'1': 'bc', '2': 'abged', '9': 'abcdfg', '0': 'abcdef', '3': 'abgcd', '5': 'afgcd', '8': 'abcdefg'}


def digits(x, y, text, s=1.0, color=INK):
    """English digits as seven-segment strokes (no font, no words)."""
    out = []
    for i, ch in enumerate(text):
        ox = x + i * 8 * s
        for seg in _DIG.get(ch, ''):
            x1, y1, x2, y2 = _SEG[seg]
            out.append(line(ox + x1 * s, y + y1 * s, ox + x2 * s, y + y2 * s, color, 1.6 * s))
    return ''.join(out)


def phone(x, y, w=26, h=40, screen='docket', text='1912'):
    out = [rect(x, y, w, h, INK, 4), rect(x + 3, y + 5, w - 6, h - 12, PAPER, 1.5)]
    if screen == 'docket':
        # The digits fit inside the screen: n digits span 8s*(n-1) + 6s, with the screen
        # 10 px narrower than the phone (a 40 px phone takes 4 digits at 0.9).
        s = min(0.9, (w - 10) / (8 * (len(text) - 1) + 6))
        out.append(digits(x + 5, y + 10, text, s))
        out.append(line(x + 6, y + 24, x + w - 6, y + 24))
        out.append(line(x + 6, y + 28, x + w - 9, y + 28))
    else:
        for i in range(4):
            out.append(line(x + 6, y + 12 + i * 5, x + w - 6, y + 12 + i * 5))
    out.append(circle(x + w / 2, y + h - 4, 1.4, PAPER))
    return ''.join(out)


def slip(x, y, w=32, h=22, stamp=False, id_box=True):
    out = [rect(x, y, w, h, PAPER, 1.5)]
    for i in range(3):
        out.append(line(x + 4, y + 6 + i * 5, x + w - 6, y + 6 + i * 5, INK, 1.4))
    if id_box:
        out.append(rect(x + 4, y + h - 6, 8, 3, INK, 0.5))
    if stamp:
        out.append(rect(x + w - 16, y + h - 14, 11, 9, INK, 1))
    return ''.join(out)


def form(x, y, w=40, h=50):
    out = [rect(x, y, w, h, PAPER, 2)]
    for i in range(6):
        out.append(line(x + 5, y + 8 + i * 6, x + w - 6, y + 8 + i * 6, INK, 1.3))
    out.append(rect(x + w - 14, y + h - 12, 8, 7, INK, 1))
    return ''.join(out)


def wall_notice(x=10, y=12):
    return (rect(x, y, 52, 38, PAPER, 3) + line(x + 6, y + 10, x + 46, y + 10, INK, 1.4)
            + line(x + 6, y + 18, x + 40, y + 18, INK, 1.4) + line(x + 6, y + 26, x + 34, y + 26, INK, 1.4))


def bubble(x, y, w, h, zig=False):
    if zig:
        pts = []
        steps = 8
        for i in range(steps + 1):
            px = x + w * i / steps
            py = y + (0 if i % 2 == 0 else 6)
            pts.append(f'{f(px)} {f(py)}')
        d = 'M' + ' L'.join(pts) + f' L{f(x + w)} {f(y + h)} L{f(x)} {f(y + h)} Z'
        return f'<path d="{d}" fill="{PAPER}" stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>'
    return (f'<path d="M{f(x + 6)} {f(y)} L{f(x + w - 6)} {f(y)} Q{f(x + w)} {f(y)} {f(x + w)} {f(y + 6)} '
            f'L{f(x + w)} {f(y + h - 6)} Q{f(x + w)} {f(y + h)} {f(x + w - 6)} {f(y + h)} L{f(x + 14)} {f(y + h)} '
            f'L{f(x + 8)} {f(y + h + 7)} L{f(x + 8)} {f(y + h)} L{f(x + 6)} {f(y + h)} Q{f(x)} {f(y + h)} {f(x)} '
            f'{f(y + h - 6)} L{f(x)} {f(y + 6)} Q{f(x)} {f(y)} {f(x + 6)} {f(y)} Z" fill="{PAPER}" '
            f'stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>')


def pole(x, top=58):
    return (rect(x, top, 5, GY - top + 2, INK, 1) + rect(x - 12, top + 6, 29, 4, INK, 1))


def house(x, y, w, h, lit=True):
    out = [rect(x, y, w, h, PAPER, 2)]
    out.append(rect(x + 8, y + 12, 16, 14, YELLOW if lit else INK, 1.5))
    out.append(rect(x + w - 24, y + 12, 16, 14, YELLOW if lit else INK, 1.5))
    out.append(rect(x + w / 2 - 8, y + h - 26, 16, 26, INK, 1.5))
    return ''.join(out)


def van(x, y, w=86, h=44):
    out = [rect(x, y, w, h, PAPER, 6), rect(x + w - 26, y + 7, 20, 14, INK, 2)]
    out.append(circle(x + 18, y + h, 7, INK))
    out.append(circle(x + w - 18, y + h, 7, INK))
    return ''.join(out)


def desk(x, y, w, h=12):
    return rect(x, y, w, h, INK, 2) + rect(x + 8, y + h, 4, GY - y - h, INK, 1) + rect(x + w - 12, y + h, 4, GY - y - h, INK, 1)


def calendar(x, y, cell=12):
    out = [rect(x, y, 4 * cell, 4 * cell, PAPER, 2)]
    for i in range(1, 4):
        out.append(line(x + i * cell, y, x + i * cell, y + 4 * cell, INK, 1))
        out.append(line(x, y + i * cell, x + 4 * cell, y + i * cell, INK, 1))
    return ''.join(out)


def card(back, parts):
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 220" width="200" height="220">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="200" height="220" fill="url(#{back})"/>',
           rect(0, FLOOR_Y, W, GY + 10 - FLOOR_Y, 'url(#floor)')]
    out.append(wall_notice())
    out.extend(parts)
    # The footer stripe is on every card (the palette's yellow and ink).
    out.append(rect(0, 204, W, 16, INK))
    for x in range(-8, W + 8, 20):
        out.append(f'<path d="M{x} 220 L{x + 8} 204 L{x + 16} 204 L{x + 8} 220 Z" fill="{YELLOW}"/>')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" '
               'stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The 25 cards: five rounds, two safe cards and three traps each.
# --------------------------------------------------------------------------

def docket_call1912():
    return card('bg_docket', [
        phone(94, 92, 40, 52),
        bubble(36, 76, 52, 30),
        slip(46, 84, 30, 14, id_box=False),
        person(150, [(120, 124), (168, 158)], face=-1, gloves=False),
    ])


def docket_ccc():
    return card('bg_docket', [
        rect(16, 150, 96, 46, INK, 2),
        slip(78, 118, 34, 24, stamp=True),
        person(52, [(92, 136), (74, 160)], face=1, gloves=False),
        person(150, [(132, 138), (160, 160)], face=-1, gloves=False),
    ])


def docket_shout():
    return card('bg_docket', [
        pole(30),
        bubble(114, 36, 70, 36, zig=True),
        person(150, [(138, 96), (166, 92)], face=-1, mouth='open', gloves=False),
        person(72, [(78, 158), (84, 150)], face=1, helmet=True, mouth='open'),
    ])


def docket_tea():
    return card('bg_docket', [
        rect(104, 66, 90, 10, INK, 2),
        rect(110, 92, 80, 78, PAPER, 2),
        rect(120, 78, 12, 14, INK, 3),
        line(132, 84, 140, 78, INK, 2),
        rect(150, 84, 8, 8, INK, 1),
        rect(162, 84, 8, 8, INK, 1),
        circle(176, 136, 6, INK),
        person(60, [(70, 150), (82, 150)], face=1, helmet=True),
        person(142, [(128, 148), (150, 146)], face=-1, mouth='smile', gloves=False),
    ])


def docket_palm():
    return card('bg_docket', [
        circle(74, 108, 9, SKIN),
        line(84, 112, 98, 98, INK, 2.5),
        line(68, 104, 80, 104, INK, 1.2),
        line(68, 110, 78, 110, INK, 1.2),
        person(110, [(78, 110), (120, 160)], face=1, helmet=True, gloves=False),
    ])


def calm_ask():
    return card('bg_calm', [
        phone(100, 92, 40, 52, text='5821'),
        person(60, [(92, 142), (74, 162)], face=1, helmet=True, mouth='smile', gloves=False),
        person(154, [(126, 118), (164, 160)], face=-1, gloves=False),
    ])


def calm_form():
    return card('bg_calm', [
        form(88, 112, 40, 48),
        person(60, [(92, 128), (76, 160)], face=1, helmet=True, mouth='smile'),
        person(154, [(108, 132), (164, 160)], face=-1, gloves=False),
    ])


def calm_argue():
    return card('bg_calm', [
        person(60, [(102, 106), (70, 160)], face=1, helmet=True, mouth='open'),
        line(104, 102, 118, 96, INK, 3),
        person(150, [(122, 100), (162, 150)], face=-1, mouth='open', gloves=False),
    ])


def calm_promise():
    return card('bg_calm', [
        calendar(120, 40, 14),
        ring(136, 66, 9),
        circle(96, 132, 8, SKIN),
        rect(92, 118, 5, 12, SKIN, 2.5),
        person(60, [(96, 132), (76, 160)], face=1, helmet=True, mouth='smile'),
        person(154, [(134, 146), (162, 158)], face=-1, gloves=False),
    ])


def calm_brush():
    return card('bg_calm', [
        person(48, [(54, 160), (38, 150)], face=1, gloves=False, mouth='open'),
        person(132, [(96, 120), (112, 152)], face=-1, helmet=True, mouth='smile'),
    ])


def close_office():
    return card('bg_close', [
        desk(14, 146, 172),
        rect(60, 116, 52, 28, PAPER, 2),
        line(66, 124, 106, 124, INK, 1.2),
        line(66, 132, 100, 132, INK, 1.2),
        slip(120, 110, 36, 26, stamp=True),
        person(70, [(90, 138), (104, 144)], face=1, helmet=True),
    ])


def close_phone():
    return card('bg_close', [
        house(10, 100, 48, 70, lit=True),
        van(110, 128, 82, 44),
        phone(82, 112, 9, 16, screen='plain'),
        person(60, [(84, 124), (92, 152)], face=1, helmet=True, mouth='open'),
    ])


def close_van():
    return card('bg_close', [
        circle(162, 36, 13, YELLOW),
        van(102, 128, 84, 44),
        slip(128, 122, 18, 12, id_box=False),
        person(40, [(46, 150), (52, 150)], face=1, s=0.6, helmet=True),
    ])


def close_board():
    rows = []
    for i in range(4):
        y = 46 + i * 24
        rows.append(slip(40, y, 110, 16, id_box=False))
        rows.append(rect(44, y + 12, 8 + i * 22, 3, YELLOW, 1))
    return card('bg_close', rows + [
        person(56, [(70, 150), (82, 150)], face=1, helmet=True, s=0.9),
    ])


def close_customer():
    return card('bg_close', [
        person(56, [(68, 96), (60, 160)], face=1, mouth='open', gloves=False),
        person(134, [(116, 160), (134, 150)], face=-1, helmet=True, mouth='smile'),
    ])


def cgrf_bench():
    return card('bg_cgrf', [
        person(56, [(70, 116), (82, 118)], face=1, gloves=False),
        person(100, [(104, 116), (114, 118)], face=1, coat=INK, gloves=False),
        person(144, [(132, 116), (148, 118)], face=-1, gloves=False),
        rect(16, 140, 168, 12, INK, 2),
        person(174, [(152, 152), (166, 160)], face=-1, gloves=False, mouth='open'),
    ])


def cgrf_form():
    return card('bg_cgrf', [
        form(68, 118, 46, 52),
        person(44, [(84, 142), (60, 160)], face=1, gloves=False),
        person(152, [(136, 148), (162, 160)], face=-1, helmet=True, mouth='smile'),
    ])


def cgrf_street():
    return card('bg_cgrf', [
        person(16, [(20, 150), (24, 154)], face=1, s=0.5),
        person(184, [(180, 150), (176, 154)], face=-1, s=0.5),
        person(64, [(80, 98), (96, 150)], face=1, helmet=True, mouth='open'),
        person(138, [(120, 98), (106, 150)], face=-1, mouth='open', gloves=False),
    ])


def cgrf_home():
    return card('bg_cgrf', [
        circle(170, 36, 12, YELLOW),
        house(100, 70, 92, 100, lit=True),
        rect(132, 120, 24, 50, INK, 2),
        person(70, [(94, 118), (74, 160)], face=1, mouth='open', gloves=False),
    ])


def cgrf_giveup():
    return card('bg_cgrf', [
        rect(16, 40, 50, 40, INK, 2),
        person(116, [(100, 156), (126, 160)], face=-1, gloves=False),
        slip(60, 184, 16, 10, id_box=False),
        slip(82, 186, 14, 8, id_box=False),
        slip(140, 184, 14, 10, id_box=False),
    ])


def order_top():
    return card('bg_order', [
        desk(14, 150, 172),
        rect(40, 112, 56, 30, PAPER, 2),
        rect(44, 104, 56, 30, PAPER, 2),
        rect(94, 118, 4, 12, INK, 1),
        slip(92, 96, 36, 22, id_box=True),
        person(150, [(128, 136), (140, 146)], face=-1, helmet=True),
        person(178, [(160, 150), (168, 152)], face=-1, helmet=True, s=0.9),
    ])


def order_md():
    return card('bg_order', [
        person(58, [(86, 132), (90, 146)], face=1, coat=INK, gloves=False, mouth='smile'),
        form(96, 112, 40, 40),
        person(154, [(120, 128), (138, 152)], face=-1, helmet=True, gloves=False),
    ])


def order_drawer():
    return card('bg_order', [
        rect(50, 98, 100, 98, INK, 3),
        rect(58, 108, 84, 24, PAPER, 2),
        rect(58, 138, 84, 24, PAPER, 2),
        rect(94, 116, 30, 6, PAPER, 1),
        person(180, [(160, 138), (166, 150)], face=-1, helmet=True, s=0.9),
    ])


def order_tears():
    return card('bg_order', [
        person(64, [(116, 118), (140, 116)], face=1, helmet=True, mouth='open', coat=INK),
        rect(116, 96, 20, 30, PAPER, 2),
        rect(140, 90, 18, 28, PAPER, 2),
        slip(152, 64, 16, 12, id_box=False),
        person(160, [(146, 150), (152, 158)], face=-1, gloves=False, mouth='open'),
    ])


def order_later():
    return card('bg_order', [
        desk(14, 150, 172),
        rect(56, 140, 52, 8, PAPER, 1),
        calendar(130, 26, 12),
        ring(154, 50, 6),
        rect(106, 136, 8, 12, INK, 1.5),
        rect(152, 134, 8, 12, INK, 1.5),
        person(120, [(106, 140), (116, 132)], face=1, gloves=False),
        person(170, [(156, 140), (164, 130)], face=-1, helmet=True, gloves=False, mouth='smile'),
    ])


CARDS = {}
for name, fn in [
    ('docket_call1912', docket_call1912), ('docket_ccc', docket_ccc), ('docket_shout', docket_shout),
    ('docket_tea', docket_tea), ('docket_palm', docket_palm),
    ('calm_ask', calm_ask), ('calm_form', calm_form), ('calm_argue', calm_argue),
    ('calm_promise', calm_promise), ('calm_brush', calm_brush),
    ('close_office', close_office), ('close_phone', close_phone), ('close_van', close_van),
    ('close_board', close_board), ('close_customer', close_customer),
    ('cgrf_bench', cgrf_bench), ('cgrf_form', cgrf_form), ('cgrf_street', cgrf_street),
    ('cgrf_home', cgrf_home), ('cgrf_giveup', cgrf_giveup),
    ('order_top', order_top), ('order_md', order_md), ('order_drawer', order_drawer),
    ('order_tears', order_tears), ('order_later', order_later),
]:
    CARDS[name] = fn()

# Safe cards and traps per round (mirrors learn_board_pack86.dart).
ROUNDS = {
    'docket': (['docket_call1912', 'docket_ccc'], ['docket_shout', 'docket_tea', 'docket_palm']),
    'calm': (['calm_ask', 'calm_form'], ['calm_argue', 'calm_promise', 'calm_brush']),
    'close': (['close_office', 'close_phone'], ['close_van', 'close_board', 'close_customer']),
    'cgrf': (['cgrf_bench', 'cgrf_form'], ['cgrf_street', 'cgrf_home', 'cgrf_giveup']),
    'order': (['order_top', 'order_md'], ['order_drawer', 'order_tears', 'order_later']),
}
HAND = 4  # one safe card and the three traps (ruling M8-21; the board's default hand)

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for k, t in tok.items():
        stray = {x for x in t - PALETTE if not x.startswith('url(#bg_')}
        if stray:
            problems.append(f'{k}: colours outside the palette {sorted(stray)}')
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
