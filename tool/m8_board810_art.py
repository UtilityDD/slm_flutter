"""Picture cards for lesson 8.10 learn board ("রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ").

python -I tool/m8_board810_art.py .

Writes assets/game/art/m8_board810/*.svg: 200 x 220 scene cards, drawn edge to
edge in the flat style of tool/m6_board63_art.py. No words in the art; every
label a worker reads is in learn_board_pack810.dart.

What the cards show comes from the live lesson 8.10 text and the Module 8
rulings (docs/module_specs/module8_rulings.md) only. Rounds (board_810.json
rounds, trimmed to five by M8-21: the carbon-copy round is dropped):
  1. log: the logbook page at shutdown and sign-off (live: 'কখন শাটডাউন নিলেন,
     কখন ছাড়লেন, কী কাজ করলেন'; 'দুবার পড়ে দেখুন'). Traps: a blank signed
     page, a page with no times, a one-handed sign on the walk to the van;
  2. climb: a phone or verbal 'line OFF' at the pole (live pro tip 1: written
     permit AND own earthing; ruling M8-17: tester 0 V before the earth). The
     tester and its earth lead lie at the pole foot in every card. Traps: the
     phone at the ear, the coworker's thumbs-up, a shrug climb;
  3. customer: a shouting customer (live: uniform = company's representative;
     SoP covers manner). Traps: shout back, turn away, a hot head;
  4. bribe: cash for a hook or a bypass (live: 'ধরা পড়লে আইন আপনাকে ছাড়বে
     না'). Traps: the note pocketed and the hook wire taken, a bridge wire
     across a meter's terminals, pliers handed over for the line;
  5. circular: the notice board and the training meeting (live pro tip 3).
     Traps: walking past the board, a yellowed old circular in a van window, a
     coworker waving a circular away at the tea stall.

Fairness (the playbook, section 4 and the Module 6 check): every card in a round
shares one backdrop and the same worker figure, so no colour or backdrop gives
the safe card away. The script checks every hand the dealer can make (one safe
card with all traps): the safe card's backdrop is a trap's backdrop, and each
colour the safe card draws is drawn by a trap in that hand. It deletes only its
own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board810_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board810')
W, H = 200, 220
GY = 198

SKIN = '#A86E48'
HAIR = '#2A1E16'
SHIRT = '#1F5F8F'
CUST = '#B5563A'
PANTS = '#2A3442'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
HELMET = '#FFD34E'
INK = '#4A5560'
PAPER = '#F4F1E6'
RED = '#D8402F'
GREEN = '#3E9B4F'
GREY = '#8C949A'
WOOD = '#8A6A45'
YELLOW = '#D8C27A'
MONEY = '#8BB174'
GROUND = '#7E9C55'
GLASS = '#7FB2DA'

DEFS = """<defs>
  <linearGradient id="bgl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9E3D2"/><stop offset="1" stop-color="#CFC6AE"/></linearGradient>
  <linearGradient id="bgc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9CC6E2"/><stop offset="0.7" stop-color="#E4F0F5"/><stop offset="1" stop-color="#D9E2C8"/></linearGradient>
  <linearGradient id="bgu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CFE3EE"/><stop offset="1" stop-color="#B8C7D1"/></linearGradient>
  <linearGradient id="bgb" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F5DEB0"/><stop offset="1" stop-color="#D7B684"/></linearGradient>
  <linearGradient id="bgo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6E0CF"/><stop offset="1" stop-color="#CFC7B0"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="van" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def n(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def rect(x, y, w, h, fill, rx=0, stroke=None, sw=1.2, op=None):
    s = f'<rect x="{n(x)}" y="{n(y)}" width="{n(w)}" height="{n(h)}"'
    if rx:
        s += f' rx="{n(rx)}"'
    s += f' fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{n(sw)}"'
    if op is not None:
        s += f' opacity="{op}"'
    return s + '/>'


def circ(cx, cy, r, fill, stroke=None, sw=1.2, op=None):
    s = f'<circle cx="{n(cx)}" cy="{n(cy)}" r="{n(r)}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{n(sw)}"'
    if op is not None:
        s += f' opacity="{op}"'
    return s + '/>'


def ln(x1, y1, x2, y2, stroke, sw=2.0):
    return (f'<line x1="{n(x1)}" y1="{n(y1)}" x2="{n(x2)}" y2="{n(y2)}" stroke="{stroke}" '
            f'stroke-width="{n(sw)}" stroke-linecap="round"/>')


def pth(d, fill='none', stroke=None, sw=2.0):
    s = f'<path d="{d}" fill="{fill}"'
    if stroke:
        s += f' stroke="{stroke}" stroke-width="{n(sw)}" stroke-linecap="round" stroke-linejoin="round"'
    return s + '/>'


def group(gid, items):
    return f'<g id="{gid}">' + ''.join(items) + '</g>'


def man(x, hands=(), s=1.0, face=1, gloves=False, helmet=True, shirt=SHIRT, mood='calm', legs='stand', back=False, skin=SKIN):
    """A worker at x, feet on the ground line; [hands] are card points for the
    hands (each arm bends from its shoulder through an elbow)."""
    k = s
    hip_y = GY - 36 * k
    sh_y = GY - 64 * k
    feet = {
        'stand': [(x - 6 * k, GY), (x + 6 * k, GY)],
        'stride': [(x - 13 * k, GY), (x + 11 * k, GY)],
        'step': [(x - 6 * k, GY), (x + 13 * k, GY - 34 * k)],
    }[legs]
    out = []
    for fx, fy in feet:
        out.append(ln(x, hip_y, fx, fy - 3 * k, PANTS, 9 * k))
        out.append(rect(fx - 4.5 * k, fy - 4 * k, 10 * k, 5 * k, BOOT, rx=2 * k))
    out.append(rect(x - 10 * k, sh_y, 20 * k, 32 * k, shirt, rx=4 * k))
    hx = x + (0 if back else face * 2 * k)
    hy = GY - 76 * k
    out.append(circ(hx, hy, 9 * k, skin))
    if helmet:
        out.append(pth(f'M{n(hx - 9.5 * k)} {n(hy)} A{n(9.5 * k)} {n(9.5 * k)} 0 0 1 {n(hx + 9.5 * k)} {n(hy)} Z', HELMET))
    else:
        out.append(pth(f'M{n(hx - 9 * k)} {n(hy)} A{n(9 * k)} {n(9 * k)} 0 0 1 {n(hx + 9 * k)} {n(hy)} Z', HAIR))
    if not back:
        ex = hx + face * 3 * k
        out.append(circ(ex, hy + 2 * k, 1.1 * k, INK))
        if mood == 'smile':
            out.append(pth(f'M{n(hx - 2 * k * face)} {n(hy + 4 * k)} Q{n(hx + k * face)} {n(hy + 7 * k)} {n(hx + 3 * k * face)} {n(hy + 4 * k)}', stroke=INK, sw=1.2 * k))
        elif mood == 'angry':
            out.append(ln(ex - 3 * k * face, hy - 1 * k, ex + 2 * k * face, hy - 3 * k, INK, 1.4 * k))
            out.append(pth(f'M{n(hx - 2 * k * face)} {n(hy + 5 * k)} L{n(hx + 2 * k * face)} {n(hy + 5 * k)}', stroke=INK, sw=1.2 * k))
    for ax, ay in hands:
        side = -1 if ax < x else 1
        sx, sy = x + side * 10 * k, sh_y + 4 * k
        ex, ey = (sx + ax) / 2 + side * 5 * k, (sy + ay) / 2 + 3 * k
        out.append(pth(f'M{n(sx)} {n(sy)} L{n(ex)} {n(ey)} L{n(ax)} {n(ay)}', stroke=shirt, sw=6.5 * k))
        out.append(circ(ax, ay, 4 * k, GLOVE if gloves else skin))
    return '\n'.join(out)


def burst(cx, cy, rx, ry, fill, stroke):
    pts = []
    for i in range(16):
        a = 2 * math.pi * i / 16
        r = 1.0 if i % 2 == 0 else 0.72
        pts.append(f'{n(cx + rx * r * math.cos(a))} {n(cy + ry * r * math.sin(a))}')
    return pth('M' + ' L'.join(pts) + ' Z', fill=fill, stroke=stroke, sw=2.0)


def bubble(cx, cy, rx=22, ry=14):
    """A speech bubble with a tail; the three dots say 'talking' (no words)."""
    out = [f'<ellipse cx="{n(cx)}" cy="{n(cy)}" rx="{n(rx)}" ry="{n(ry)}" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>',
           pth(f'M{n(cx - 6)} {n(cy + ry - 2)} L{n(cx - 12)} {n(cy + ry + 8)} L{n(cx - 1)} {n(cy + ry - 1)} Z', fill=PAPER, stroke=INK, sw=1.4)]
    for i in (-1, 0, 1):
        out.append(circ(cx + i * 7, cy, 2.0, INK))
    return out


def ground():
    return [rect(0, GY, 200, 22, GROUND)]


def logbook_pages(lines=True, times=True, sig=True, left_lines=None):
    out = [rect(46, 116, 108, 40, RED, rx=3),
           rect(50, 119, 50, 34, PAPER, stroke=INK, sw=0.8),
           rect(102, 119, 50, 34, PAPER, stroke=INK, sw=0.8)]
    if left_lines is None:
        left_lines = [(124, 30), (130, 40), (136, 26), (142, 36)] if lines else []
    for y, wd in left_lines:
        out.append(ln(56, y, 56 + wd, y, INK, 1.4))
    if times:
        for x1, x2, y in [(108, 122, 124), (128, 146, 124), (108, 122, 130), (128, 146, 130), (108, 124, 136)]:
            out.append(ln(x1, y, x2, y, INK, 1.4))
    if sig:
        out.append(rect(116, 144, 36, 9, 'none', stroke=INK, sw=0.8))
        out.append(pth('M120 149 q4 -6 8 0 t8 0 t6 -3', stroke=INK, sw=1.2))
    return out


def log_card(kind):
    desk = [rect(8, 152, 184, 10, WOOD, rx=2), rect(16, 162, 7, 36, WOOD), rect(177, 162, 7, 36, WOOD)]
    if kind == 'full':
        body = logbook_pages()
        mans = man(24, hands=[(62, 138)], face=1, shirt=SHIRT)
        extra = [ln(62, 138, 70, 131, INK, 2.0)]
    elif kind == 'reread':
        body = logbook_pages()
        mans = man(24, hands=[(62, 126), (46, 148)], face=1, shirt=SHIRT)
        extra = [circ(62, 124, 2.4, SKIN), pth('M70 118 q5 8 0 16', stroke=INK, sw=1.0)]
    elif kind == 'blank':
        body = logbook_pages(lines=False, times=False, sig=True)
        mans = man(24, hands=[(62, 138)], face=1, shirt=SHIRT)
        extra = [ln(62, 138, 70, 131, INK, 2.0)]
    elif kind == 'notimes':
        body = logbook_pages(lines=True, times=False, sig=True, left_lines=[(126, 42)])
        body += [ln(108, 119, 108, 153, INK, 0.8), ln(128, 119, 128, 153, INK, 0.8)]
        mans = man(24, hands=[(62, 138)], face=1, shirt=SHIRT)
        extra = [ln(62, 138, 70, 131, INK, 2.0)]
    else:  # rush: one-handed, walking to the van
        body = logbook_pages(lines=True, times=True, sig=True)
        mans = man(34, hands=[(60, 140)], face=1, shirt=SHIRT, legs='stride')
        extra = [ln(60, 140, 68, 134, INK, 2.0), ln(12, 120, 22, 120, GREY, 1.6), ln(8, 130, 20, 130, GREY, 1.6)]
    return desk + body + [mans] + extra


def tester(x, y, reading=True):
    """The tester at the pole foot: body, window and a 0 reading."""
    out = [rect(x - 2, y - 2, 16, 26, RED, rx=3), rect(x + 1, y + 2, 10, 6, PAPER, rx=1)]
    if reading:
        out.append(circ(x + 6, y + 5, 2.0, 'none', stroke=INK, sw=1.0))
    return out


def climb_base():
    out = ground()
    out.append(rect(140, 36, 12, 162, 'url(#pole)'))
    out.append(rect(116, 42, 58, 6, GREY))
    out.extend(tester(12, 172))
    out.append(pth('M28 194 Q80 204 138 196', stroke=GREEN, sw=2.4))
    return out


def climb_card(kind):
    base = climb_base()
    if kind == 'ptw':
        mans = man(112, hands=[(106, 122), (136, 150)], face=1, helmet=True)
        extra = [rect(96, 110, 18, 22, PAPER, rx=1, stroke=INK, sw=0.8),
                 ln(99, 117, 111, 117, INK, 1.2), ln(99, 122, 109, 122, INK, 1.2)]
        return base + [mans] + extra
    if kind == 'earth':
        mans = man(112, hands=[(136, 186), (124, 140)], face=1, helmet=True)
        extra = [group('clamp', [circ(140, 186, 4.0, GREY, stroke=INK, sw=0.8)]), ]
        return base + [mans] + extra
    if kind == 'phone':
        mans = man(112, hands=[(114, 98), (136, 134)], face=1, helmet=True, legs='step')
        extra = [rect(109, 88, 8, 14, INK, rx=2), rect(111, 91, 4, 8, PAPER, rx=0.5)]
        return base + [mans] + extra
    if kind == 'mate':
        mans = man(112, hands=[(136, 160), (122, 140)], face=1, helmet=True)
        second = man(180, hands=[(186, 106)], s=0.8, face=-1, helmet=True, shirt=CUST)
        extra = [ln(186, 106, 186, 96, SKIN, 3.0)]
        return base + [second, mans] + extra
    # shrug: climbing with a shrug in a thought bubble
    mans = man(112, hands=[(134, 122), (136, 104)], face=1, helmet=True, legs='step')
    extra = [circ(74, 84, 3.0, PAPER, stroke=INK, sw=1.0), circ(68, 92, 1.8, PAPER, stroke=INK, sw=1.0),
             f'<ellipse cx="88" cy="58" rx="24" ry="15" fill="{PAPER}" stroke="{INK}" stroke-width="1.4"/>',
             circ(88, 48, 3.0, INK), ln(78, 60, 98, 60, INK, 1.4),
             pth('M76 62 Q82 56 88 60 Q94 56 100 62', stroke=INK, sw=1.4)]
    return base + [mans] + extra


def customer_base(worker_hands, worker_mood='calm', worker_back=False, worker_helmet=True, worker_extra=()):
    out = ground()
    out.append(man(146, hands=[(128, 140)], face=-1, helmet=False, shirt=CUST, mood='calm'))
    out.extend(bubble(152, 46))
    out.append(man(60, hands=worker_hands, face=1, helmet=worker_helmet, mood=worker_mood, back=worker_back))
    out.extend(worker_extra)
    return out


def customer_card(kind):
    if kind == 'explain':
        return customer_base([(80, 116), (90, 124)], worker_mood='smile')
    if kind == 'listen':
        helmet = pth('M70 130 A6 6 0 0 1 82 130 Z', HELMET)
        return customer_base([(76, 134)], worker_mood='smile', worker_extra=[helmet])
    if kind == 'shout':
        out = customer_base([(92, 108)], worker_mood='angry', worker_extra=[ln(92, 108, 104, 102, SKIN, 2.6)])
        out.append(burst(152, 46, 26, 18, PAPER, RED))
        return out
    if kind == 'away':
        return customer_base([(52, 146), (68, 146)], worker_back=True)
    # hot: red face, a wrench up in the temper
    out = customer_base([(84, 96)], worker_mood='angry',
                        worker_extra=[circ(62, 123, 8.5, RED, op=0.45), ln(84, 96, 96, 84, GREY, 3.5), circ(96, 84, 3.0, GREY)])
    return out


def bribe_base(worker_hands, worker_back=False, worker_extra=(), customer_hands=((124, 132),), worker_mood='calm'):
    out = ground()
    out.append(man(140, hands=customer_hands, face=-1, helmet=False, shirt=CUST))
    out.append(rect(116, 126, 14, 8, MONEY, rx=1))
    out.append(man(62, hands=worker_hands, face=1, helmet=True, back=worker_back, mood=worker_mood))
    out.extend(worker_extra)
    return out


def bribe_card(kind):
    if kind == 'palm':
        return bribe_base([(88, 128)], worker_extra=[circ(86, 126, 4.0, SKIN)])
    if kind == 'walk':
        return bribe_base([(50, 142), (74, 148)], worker_back=True, customer_hands=((124, 132), (126, 140)),
                          worker_extra=[ln(124, 140, 128, 190, GREY, 1.8), circ(128, 192, 2.2, GREY)],
                          )
    if kind == 'takehook':
        return bribe_base([(92, 168), (60, 160)],
                          worker_extra=[rect(55, 156, 10, 6, MONEY, rx=1),
                                        pth('M92 170 L104 186 L116 180', stroke=GREY, sw=1.8)])
    if kind == 'bypass':
        return bribe_base([(104, 122)],
                          worker_extra=[rect(90, 88, 30, 46, 'url(#van)', rx=3),
                                        circ(96, 108, 2.4, GREY), circ(114, 108, 2.4, GREY),
                                        pth('M96 108 Q105 96 114 108', stroke=GREY, sw=2.0)])
    # pliers: handed to the customer, the worker points at the line overhead
    return bribe_base([(110, 132), (88, 70)],
                      worker_extra=[ln(20, 62, 186, 62, INK, 2.0),
                                    pth('M104 134 L118 128', stroke=GREY, sw=4.0)])


def circular_base():
    out = ground()
    out.append(rect(36, 44, 128, 90, WOOD, rx=3))
    out.append(rect(42, 50, 116, 78, '#D9CBA9', rx=2))
    for x, y, w, h in [(48, 58, 22, 28), (76, 56, 20, 24), (104, 62, 26, 20)]:
        out.append(rect(x, y, w, h, PAPER, stroke=INK, sw=0.6))
        out.append(ln(x + 3, y + 6, x + w - 3, y + 6, INK, 0.9))
        out.append(ln(x + 3, y + 11, x + w - 6, y + 11, INK, 0.9))
    out.append(rect(136, 58, 18, 26, PAPER, stroke=INK, sw=0.6))
    out.append(circ(145, 74, 3.4, RED, op=0.85))
    return out


def circular_card(kind):
    out = circular_base()
    if kind == 'board':
        out.append(rect(108, 64, 36, 42, PAPER, stroke=INK, sw=0.8))
        out.append(ln(112, 72, 140, 72, INK, 1.1))
        out.append(ln(112, 79, 136, 79, INK, 1.1))
        out.append(circ(130, 94, 4.0, RED, op=0.9))
        out.append(man(72, hands=[(102, 110)], face=1, helmet=True))
    elif kind == 'meeting':
        out.append(man(72, hands=[(90, 128)], face=1, helmet=True, mood='smile'))
        out.append(rect(84, 118, 22, 26, PAPER, stroke=INK, sw=0.8))
        out.append(ln(88, 124, 102, 124, INK, 1.1))
        out.append(ln(88, 130, 100, 130, INK, 1.1))
        out.append(circ(96, 138, 3.6, RED, op=0.9))
        out.append(man(150, s=0.6, face=-1, helmet=False, shirt=CUST, mood='smile'))
        out.append(man(176, s=0.6, face=-1, helmet=False, shirt=SHIRT, mood='smile'))
    elif kind == 'pastby':
        out.append(man(72, hands=[(56, 150), (84, 142)], face=1, helmet=True, back=True, legs='stride'))
    elif kind == 'oldpaper':
        out.append(rect(124, 118, 66, 50, 'url(#van)', rx=4))
        out.append(rect(134, 126, 46, 22, GLASS, rx=2))
        out.append(rect(140, 128, 18, 20, YELLOW, stroke=INK, sw=0.6))
        out.append(ln(143, 133, 155, 133, INK, 0.9))
        out.append(ln(143, 139, 153, 139, INK, 0.9))
        out.append(man(72, hands=[(118, 128)], face=1, helmet=True))
    else:  # jugaad: a tea stall, a coworker waving the circular away
        out.append(pth('M120 60 L186 60 L176 46 L130 46 Z', fill=WOOD))
        out.append(circ(152, 146, 6.0, GREY))
        out.append(rect(144, 152, 16, 10, PAPER, rx=2, stroke=INK, sw=0.6))
        out.append(man(72, hands=[(62, 150), (84, 150)], face=1, helmet=True))
        out.append(man(164, hands=[(146, 110)], s=0.9, face=-1, helmet=False, shirt=CUST))
        out.append(rect(138, 96, 14, 18, PAPER, stroke=INK, sw=0.6))
    return out


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def build(back, parts):
    return card_close(card_open(back) + [p if isinstance(p, str) else '\n'.join(p) for p in parts])


BACKDROP = {'log': 'bgl', 'climb': 'bgc', 'customer': 'bgu', 'bribe': 'bgb', 'circular': 'bgo'}

CARDS = {}
for k in ('full', 'reread', 'blank', 'notimes', 'rush'):
    CARDS[f'log_{k}'] = build(BACKDROP['log'], log_card(k))
for k in ('ptw', 'earth', 'phone', 'mate', 'shrug'):
    CARDS[f'climb_{k}'] = build(BACKDROP['climb'], climb_card(k))
for k in ('explain', 'listen', 'shout', 'away', 'hot'):
    CARDS[f'customer_{k}'] = build(BACKDROP['customer'], [customer_card(k)])
for k in ('palm', 'walk', 'takehook', 'bypass', 'pliers'):
    CARDS[f'bribe_{k}'] = build(BACKDROP['bribe'], [bribe_card(k)])
for k in ('board', 'meeting', 'pastby', 'oldpaper', 'jugaad'):
    CARDS[f'circular_{k}'] = build(BACKDROP['circular'], [circular_card(k)])

# Safe cards and traps per round (mirrors learn_board_pack810.dart).
ROUNDS = {
    'log': (['log_full', 'log_reread'], ['log_blank', 'log_notimes', 'log_rush']),
    'climb': (['climb_ptw', 'climb_earth'], ['climb_phone', 'climb_mate', 'climb_shrug']),
    'customer': (['customer_explain', 'customer_listen'], ['customer_shout', 'customer_away', 'customer_hot']),
    'bribe': (['bribe_palm', 'bribe_walk'], ['bribe_takehook', 'bribe_bypass', 'bribe_pliers']),
    'circular': (['circular_board', 'circular_meeting'], ['circular_pastby', 'circular_oldpaper', 'circular_jugaad']),
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
