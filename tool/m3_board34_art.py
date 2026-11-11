"""Picture cards for lesson 3.4 শেখা ("ডিও (DO) ফিউজ ও হর্ন গ্যাপ ফিউজ: নীরব প্রহরী").

python -I tool/m3_board34_art.py .

Writes assets/game/art/m3_board34/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 3.4 and its film script only:
  1. three: on a three-phase transformer one DO fuse has dropped out (the
     barrel hangs — the fault sign seen from afar); the rule is to open the
     other two phases' fuses too, so the transformer is fully isolated
     ("দুটি নয়, তিনটিই খুলুন"); pushing the blown one straight back means the
     fault is still on the line;
  2. operate: a DO fuse is opened / closed with a hot stick and a correct
     body position; opening it may give a small bang (the expulsion gas from
     the boric-acid lining throws the arc out) — that is normal. The trap
     "standing right under the barrel" is our drawing of a wrong body
     position (the lesson only says "correct body position" — flagged);
  3. link: the fuse link's ampere rating is read off the plate on the
     transformer / pole; only a rated, tested link — never a thick wire
     (the transformer burns on overload), never a too-thin wire (it blows on
     normal load again and again), never any ordinary wire (no telling when
     it melts);
  4. fit: the link is tied in the barrel straight and at the right tension;
     the top and bottom contacts are kept clean (dirt or carbon sparks and
     ruins them); a loose or wrongly tied link does not work properly;
  5. horn: on a horn gap fuse the arc rises with the hot air between the two
     horns and, as the gap widens, goes out by itself.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board34_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board34')
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
WIRE = '#2B3138'
COPPER = '#D98A3D'
BRASS = '#C9A24A'
BRASS_D = '#9C7A2E'
LINK = '#D7DCE0'
SOOT = '#1B1B1B'
STICK = '#F2A23A'
STICK_D = '#C47A1E'
ARM = '#6F7880'
FACE = '#1E2329'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3C4A57"/><stop offset="1" stop-color="#65788A"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="tube" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5A3E28"/><stop offset="0.5" stop-color="#8A6240"/><stop offset="1" stop-color="#523822"/></linearGradient>
  <linearGradient id="tubeH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5A3E28"/><stop offset="0.45" stop-color="#8A6240"/><stop offset="1" stop-color="#523822"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E959B"/><stop offset="0.5" stop-color="#B9C0C5"/><stop offset="1" stop-color="#7E858B"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="puff" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4D0"/><stop offset="0.4" stop-color="#D9D4C8" stop-opacity="0.85"/><stop offset="1" stop-color="#B8B4AC" stop-opacity="0"/></radialGradient>
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
# The worker (copied from tool/storm_board_art.py): one figure, any pose.
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


def _hand(p, bare=False, point=0):
    x, y = p
    c = SKIN if bare else GLOVE
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves (bare = no gloves)."""
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face)
    kf = _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, kf, ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, SHIRT_D, 5.4))
    g.append(_hand(hb, bare, point[0]))
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
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0)):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'



def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def blast(x, y, r=40):
    rays = ''.join(f'<path d="M{f(x + math.cos(a) * r * 0.3)} {f(y + math.sin(a) * r * 0.3)} L{f(x + math.cos(a) * r)} {f(y + math.sin(a) * r)}"/>'
                   for a in [i * math.pi / 6 + 0.2 for i in range(12)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#blast)"/>'
            f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9">{rays}</g>')



def puff(x, y, r=16):
    """The small bang of a DO fuse opening: expulsion gas thrown out."""
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#puff)"/>'
            f'<g stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.85">'
            + ''.join(f'<path d="M{f(x + math.cos(a) * r * 0.55)} {f(y + math.sin(a) * r * 0.55)} '
                      f'L{f(x + math.cos(a) * r * 0.95)} {f(y + math.sin(a) * r * 0.95)}"/>'
                      for a in [i * math.pi / 3 + 0.4 for i in range(6)])
            + '</g>')


def rot(p, c, a):
    r = math.radians(a)
    dx, dy = p[0] - c[0], p[1] - c[1]
    return (c[0] + dx * math.cos(r) - dy * math.sin(r), c[1] + dx * math.sin(r) + dy * math.cos(r))


def on_line(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


# --------------------------------------------------------------------------
# The pole yard: a crossarm with three DO fuses feeding a transformer.
# --------------------------------------------------------------------------

DO_X = (76, 112, 148)
HINGE_Y = 94
BUSH_X = (124, 143, 162)
CLOSED = 0
DROP = -165


def ring_at(i, angle):
    x = DO_X[i]
    return rot((x - 6.5, 66), (x, HINGE_Y), angle)


def do_unit(x, angle):
    o = [f'<path d="M{x - 3} 56 Q{x - 12} 40 {x - 12} 0" stroke="{WIRE}" stroke-width="1.8" fill="none"/>',
         f'<rect x="{x + 7}" y="45" width="6" height="9" fill="{ARM}"/>',
         f'<rect x="{x + 6}" y="52" width="8" height="46" rx="3" fill="url(#porcelain)"/>']
    o += [f'<ellipse cx="{x + 10}" cy="{yy}" rx="7" ry="2.2" fill="url(#porcelain)" stroke="#B8C2C9" stroke-width="0.5"/>' for yy in range(60, 97, 8)]
    o.append(f'<path d="M{x + 7} 56 L{x - 3} 56" stroke="{BRASS}" stroke-width="3.2" stroke-linecap="round"/>')
    o.append(f'<path d="M{x + 7} 95 L{x - 1} 95" stroke="{BRASS}" stroke-width="3.6" stroke-linecap="round"/>')
    g = (f'<rect x="{f(x - 3.2)}" y="59" width="6.4" height="36" rx="2" fill="url(#tube)"/>'
         f'<rect x="{x - 4}" y="57" width="8" height="5" rx="1.2" fill="{BRASS}"/>'
         f'<circle cx="{f(x - 6.5)}" cy="66" r="3" fill="none" stroke="{BRASS_D}" stroke-width="1.6"/>'
         f'<circle cx="{x}" cy="{HINGE_Y}" r="2.6" fill="{BRASS_D}"/>')
    o.append(f'<g transform="rotate({angle} {x} {HINGE_Y})">{g}</g>')
    return ''.join(o)


def transformer():
    x0, y0, x1, y1 = 112, 150, 174, GY - 6
    o = [f'<rect x="{x0 - 4}" y="{y1}" width="{x1 - x0 + 8}" height="6" fill="{ARM}"/>',
         f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="3" fill="url(#tank)"/>']
    o += [f'<rect x="{x0 + 6 + i * 9}" y="{y0 + 8}" width="4" height="{y1 - y0 - 14}" rx="1.5" fill="#5C7459"/>' for i in range(6)]
    for bx in BUSH_X:
        o.append(f'<path d="M{bx - 4} {y0} L{bx + 4} {y0} L{bx + 2.5} {y0 - 11} L{bx - 2.5} {y0 - 11} Z" fill="url(#porcelain)"/>')
    for x, bx in zip(DO_X, BUSH_X):
        o.append(f'<path d="M{x + 12} 97 L{bx} {y0 - 11}" stroke="{WIRE}" stroke-width="1.8"/>')
    return ''.join(o)


def yard(angles):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<path d="M0 {GY} L200 {GY}" stroke="#8A7A58" stroke-width="1"/>')
    out.append(f'<rect x="178" y="8" width="10" height="{GY - 8}" fill="url(#pole)"/>')
    out.append(f'<rect x="56" y="40" width="136" height="6" fill="{ARM}"/>')
    out.append(transformer())
    for x, a in zip(DO_X, angles):
        out.append(do_unit(x, a))
    return out


def stick(butt, tip, metal=False):
    """The hot stick (fibreglass, dark grip at the butt, a hook at the tip);
    metal = an ordinary steel rod instead."""
    col = '#9AA4AC' if metal else STICK
    o = [f'<path d="M{f(butt[0])} {f(butt[1])} L{f(tip[0])} {f(tip[1])}" stroke="{col}" stroke-width="4" stroke-linecap="round"/>']
    if not metal:
        g = on_line(butt, tip, 0.22)
        o.append(f'<path d="M{f(butt[0])} {f(butt[1])} L{f(g[0])} {f(g[1])}" stroke="{FACE}" stroke-width="4.6" stroke-linecap="round"/>')
        for t in (0.45, 0.7):
            b = on_line(butt, tip, t)
            c = on_line(butt, tip, t + 0.02)
            o.append(f'<path d="M{f(b[0])} {f(b[1])} L{f(c[0])} {f(c[1])}" stroke="{STICK_D}" stroke-width="4.4"/>')
    o.append(f'<circle cx="{f(tip[0])}" cy="{f(tip[1])}" r="2.8" fill="none" stroke="{col if metal else ARM}" stroke-width="1.8"/>')
    return ''.join(o)


def operator(x, butt, tip, face=1, look=-14, metal=False):
    """A worker on the ground working a stick from butt to tip."""
    h1 = on_line(butt, tip, 0.12)
    h2 = on_line(butt, tip, 0.34)
    return stick(butt, tip, metal) + worker(x, (h1, h2), face=face, look=look)


def stick_card(angles, target=None, kind='steady'):
    out = yard(angles)
    if kind == 'under':
        tip = ring_at(1, angles[1])
        out.append(operator(102, (103, 176), tip, look=-30))
    elif kind == 'walk':
        out.append(stick((64, 150), (6, 118)))
        out.append(worker(44, ((54, 146), (36, 136)), face=-1, look=4))
    elif kind == 'rest':
        out.append(stick((52, 196), (70, 74)))
        out.append(worker(36, (on_line((52, 196), (70, 74), 0.42), on_line((52, 196), (70, 74), 0.55)), face=1, look=-18))
    elif kind == 'bang':
        out.append(puff(DO_X[1] - 3, 56))
        out.append(stick((14, 194), (112, 189)))
        out.append(worker(46, ((38, 108), (54, 104)), face=-1, look=8))
    else:
        tip = ring_at(target, angles[target])
        if kind == 'steady':
            out.append(puff(DO_X[target] - 3, 56))
            tip = (tip[0] - 14, tip[1] - 4)
        out.append(operator(34, (40, 170), tip, metal=(kind == 'rod')))
    return card_close(out)


# Round 1 — three: one fuse dropped out on a three-phase transformer.
def three_card(kind):
    return {
        'open2': lambda: stick_card((DROP, DROP, -20), 2, 'pull'),
        'all3': lambda: stick_card((DROP, DROP, DROP), kind='rest'),
        'one': lambda: stick_card((-70, CLOSED, CLOSED), 0, 'pull'),
        'two': lambda: stick_card((DROP, DROP, CLOSED), kind='walk'),
        'leave': lambda: stick_card((CLOSED, DROP, CLOSED), kind='walk'),
    }[kind]()


# Round 2 — operate: a hot stick and a correct body position; the bang is normal.
def operate_card(kind):
    return {
        'open': lambda: stick_card((CLOSED, -18, CLOSED), 1, 'pull'),
        'steady': lambda: stick_card((CLOSED, DROP, CLOSED), 1, 'steady'),
        'rod': lambda: stick_card((CLOSED, -18, CLOSED), 1, 'rod'),
        'under': lambda: stick_card((CLOSED, -18, CLOSED), kind='under'),
        'bang': lambda: stick_card((CLOSED, DROP, CLOSED), kind='bang'),
    }[kind]()


# --------------------------------------------------------------------------
# The bench: the barrel taken down, below the transformer's rating plate.
# --------------------------------------------------------------------------

BX0, BX1, BY, BH = 44, 150, 86, 22
RAG = '#B7C4CF'


def bench_stage():
    out = card_open('bench')
    out.append('<rect x="0" y="0" width="200" height="44" fill="url(#tank)"/>')
    out += [f'<rect x="{6 + i * 16}" y="0" width="6" height="40" rx="2" fill="#5C7459"/>' for i in range(6)]
    out.append('<rect x="116" y="7" width="58" height="30" rx="2.5" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>')
    out += [f'<circle cx="{cx}" cy="{cy}" r="1.4" fill="{FACE}"/>' for cx in (120, 170) for cy in (11, 33)]
    out += [f'<path d="M124 {y} L{x} {y}" stroke="{WIRE}" stroke-width="2.2"/>' for y, x in ((15, 164), (22, 150), (29, 158))]
    out.append(f'<rect x="0" y="44" width="200" height="4" fill="{ARM}"/>')
    return out


def barrel_h(window=False, soot=False):
    x0, x1, y, h = BX0, BX1, BY, BH
    o = [f'<rect x="{x0}" y="{y}" width="{x1 - x0}" height="{h}" rx="4" fill="url(#tubeH)"/>',
         f'<rect x="{x0 - 12}" y="{y - 4}" width="13" height="{h + 8}" rx="2" fill="{BRASS}"/>',
         f'<rect x="{x1}" y="{y - 3}" width="11" height="{h + 6}" rx="2" fill="{BRASS}"/>',
         f'<circle cx="{x1 + 13}" cy="{y + h / 2}" r="4.5" fill="{BRASS_D}"/>',
         f'<circle cx="{x1 - 10}" cy="{y - 6}" r="4.5" fill="none" stroke="{BRASS_D}" stroke-width="2"/>',
         f'<circle cx="{x0 - 6}" cy="{y + h + 12}" r="5.5" fill="url(#steel)"/>',
         f'<path d="M{x0 - 6} {y + h + 4} L{x0 - 6} {y + h + 7}" stroke="{BRASS_D}" stroke-width="3"/>']
    if window:
        o.append(f'<rect x="{x0 + 10}" y="{y + 5}" width="{x1 - x0 - 20}" height="{h - 10}" rx="2" fill="{FACE}"/>')
    if soot:
        for cx, cy, rx in ((x0 - 6, y + 4, 6), (x0 - 4, y + h - 2, 5), (x1 + 6, y + 2, 5), (x1 + 4, y + h - 3, 6), (x1 + 13, y + h / 2, 4)):
            o.append(f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{rx * 0.7}" fill="{SOOT}" opacity="0.85"/>')
    return ''.join(o)


def arm(p, base, point=None):
    """A sleeve from the card's lower edge to a black rubber glove at p."""
    o = [f'<path d="M{f(base[0])} {f(base[1])} L{f(p[0])} {f(p[1])}" stroke="{SHIRT}" stroke-width="14" stroke-linecap="round"/>',
         f'<circle cx="{f(p[0])}" cy="{f(p[1])}" r="8.5" fill="{GLOVE}"/>']
    if point:
        o.append(f'<path d="M{f(p[0])} {f(p[1])} L{f(point[0])} {f(point[1])}" stroke="{GLOVE}" stroke-width="4" stroke-linecap="round"/>')
    return ''.join(o)


def rated_link(x0, y, x1):
    return (f'<path d="M{x0} {y} L{x1} {y}" stroke="{LINK}" stroke-width="1.8"/>'
            f'<rect x="{x1}" y="{y - 5}" width="4" height="10" rx="1" fill="url(#steel)"/>'
            f'<path d="M{x0} {y} l-4 -2 l-4 4 l-4 -4 l-4 4 l-4 -2" stroke="{COPPER}" stroke-width="2" fill="none"/>')


def coil(cx, cy, col, w=3.4, n=3):
    return ''.join(f'<ellipse cx="{cx}" cy="{cy + i * 2}" rx="{22 - i * 3}" ry="{8 - i}" fill="none" stroke="{col}" stroke-width="{w}"/>' for i in range(n))


def link_card(kind):
    out = bench_stage()
    out.append(barrel_h())
    if kind == 'plate':
        out.append(rated_link(56, 150, 132))
        out.append(arm((150, 66), (196, 220), point=(140, 44)))
    elif kind == 'packet':
        out.append(f'<rect x="18" y="138" width="52" height="38" rx="3" fill="url(#steel)"/><rect x="18" y="146" width="52" height="5" fill="{WIRE}"/>')
        out.append(rated_link(70, 160, 142))
        out.append(arm((152, 168), (186, 220)))
    elif kind == 'thick':
        out.append(coil(56, 168, COPPER, 5))
        out.append(f'<path d="M76 168 Q96 160 104 140 Q110 124 {BX0 + 20} {BY + BH / 2}" stroke="{COPPER}" stroke-width="5" fill="none" stroke-linecap="round"/>')
        out.append(arm((104, 142), (150, 220)))
    elif kind == 'thin':
        for x, y in ((40, 150), (72, 162), (104, 148)):
            out.append(f'<path d="M{x} {y} l12 3" stroke="{LINK}" stroke-width="0.9"/><circle cx="{x + 12}" cy="{y + 3}" r="1.8" fill="{LINK}"/>'
                       f'<path d="M{x + 18} {y + 4} l10 2" stroke="{LINK}" stroke-width="0.9"/><circle cx="{x + 18}" cy="{y + 4}" r="1.8" fill="{LINK}"/>'
                       f'<circle cx="{x + 15}" cy="{y + 4}" r="2.6" fill="{SOOT}" opacity="0.6"/>')
        out.append(f'<path d="M140 166 Q120 150 {BX0 + 30} {BY + BH / 2}" stroke="{LINK}" stroke-width="1.1" fill="none"/>')
        out.append(arm((146, 168), (180, 220)))
    elif kind == 'any':
        out.append(coil(58, 166, '#D9DDE0', 4.4))
        out.append(f'<path d="M80 166 Q100 150 112 146" stroke="#D9DDE0" stroke-width="4.4" fill="none"/>'
                   f'<path d="M112 146 L128 140" stroke="{COPPER}" stroke-width="2.2"/>')
        out.append(f'<g transform="rotate(-25 132 152)"><path d="M124 150 L150 146 M124 154 L150 160" stroke="url(#steel)" stroke-width="4" stroke-linecap="round"/>'
                   f'<path d="M150 146 L176 140 M150 160 L176 168" stroke="{STICK}" stroke-width="6" stroke-linecap="round"/></g>')
        out.append(arm((166, 160), (190, 220)))
    return card_close(out)


def fit_card(kind):
    out = bench_stage()
    out.append(barrel_h(window=True, soot=(kind == 'carbon')))
    y = BY + BH / 2
    if kind == 'loose':
        pts = ' '.join(f'L{f(BX0 + 12 + i * 4)} {f(y + 3.5 * math.sin(i * 0.9))}' for i in range(22))
        out.append(f'<path d="M{BX0 + 8} {y} {pts} L{BX1 - 8} {y}" stroke="{LINK}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M{BX0 - 10} {y} Q{BX0 - 26} {y + 30} {BX0 - 18} {y + 52}" stroke="{COPPER}" stroke-width="2" fill="none"/>')
    elif kind == 'kink':
        out.append(f'<path d="M{BX0 + 8} {y} L84 {y} L90 {y - 5} L94 {y + 5} L98 {y - 5} L92 {y - 1} L104 {y} L{BX1 - 8} {y}" '
                   f'stroke="{LINK}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M{BX0 - 10} {y} Q{BX0 - 14} {y + 12} {BX0 - 6} {y + BH / 2 + 12}" stroke="{COPPER}" stroke-width="2" fill="none"/>')
    else:
        out.append(f'<path d="M{BX0 + 8} {y} L{BX1 - 8} {y}" stroke="{LINK}" stroke-width="1.6"/>')
        out.append(f'<path d="M{BX0 - 10} {y} Q{BX0 - 14} {y + 12} {BX0 - 6} {y + BH / 2 + 12}" stroke="{COPPER}" stroke-width="2" fill="none"/>'
                   f'<circle cx="{BX0 - 6}" cy="{BY + BH + 12}" r="7" fill="none" stroke="{COPPER}" stroke-width="1.6"/>')
    if kind == 'taut':
        sx, sy = BX0 - 6, BY + BH + 12
        out.append(f'<g transform="rotate(30 {sx} {sy})"><rect x="{sx}" y="{sy - 3.5}" width="56" height="7" rx="3.5" fill="url(#steel)"/>'
                   f'<circle cx="{sx}" cy="{sy}" r="9" fill="none" stroke="url(#steel)" stroke-width="4"/></g>')
        out.append(arm((sx + 50, sy + 28), (110, 220)))
    elif kind == 'clean':
        out.append(f'<path d="M{BX1 - 2} {BY + 30} q8 -14 22 -10 q6 10 -4 18 q-12 4 -18 -8 Z" fill="{RAG}"/>')
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"><path d="M{BX0 - 9} {BY + 2} l6 0"/><path d="M{BX1 + 3} {BY + 1} l6 0"/>'
                   f'<path d="M{BX1 + 4} {BY - 8} l3 -5"/><path d="M{BX0 - 14} {BY - 8} l-3 -5"/></g>')
        out.append(arm((BX1 + 14, BY + 34), (186, 220)))
    elif kind == 'carbon':
        out.append(f'<path d="M140 176 q8 -14 22 -10 q6 10 -4 18 q-12 4 -18 -8 Z" fill="{RAG}"/>')
        out.append(arm((100, BY + BH + 20), (120, 220)))
    else:
        out.append(arm((100, BY + BH + 20), (120, 220)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — horn: the arc rises between the horns and goes out by itself.
# --------------------------------------------------------------------------

HL = ((90, 142), (94, 100), (42, 26))


def bez(p, t):
    a, c, b = p
    return ((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
            (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1])


def mirror(p):
    return (200 - p[0], p[1])


def horn_stage(parallel=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<rect x="95" y="170" width="10" height="{GY - 170}" fill="url(#pole)"/>')
    out.append(f'<rect x="24" y="170" width="152" height="6" fill="{ARM}"/>')
    for x in (70, 130):
        out.append(f'<rect x="{x - 5}" y="150" width="10" height="20" rx="2" fill="url(#porcelain)"/>')
        out += [f'<ellipse cx="{x}" cy="{yy}" rx="9" ry="2.6" fill="url(#porcelain)" stroke="#B8C2C9" stroke-width="0.5"/>' for yy in (156, 164)]
    if parallel:
        paths = ['M70 152 L91 142 L91 26', 'M130 152 L109 142 L109 26']
    else:
        (a, c, b) = HL
        paths = [f'M70 152 L{a[0]} {a[1]} Q{c[0]} {c[1]} {b[0]} {b[1]}',
                 f'M130 152 L{200 - a[0]} {a[1]} Q{200 - c[0]} {c[1]} {200 - b[0]} {b[1]}']
    for p in paths:
        out.append(f'<path d="{p}" stroke="#5E6870" stroke-width="4.4" fill="none" stroke-linecap="round"/>')
    # The melted fuse wire: two stubs with beads.
    out.append(f'<path d="M90 142 l4 1" stroke="{LINK}" stroke-width="1.4"/><circle cx="94.5" cy="143" r="1.8" fill="{LINK}"/>'
               f'<path d="M110 142 l-4 1" stroke="{LINK}" stroke-width="1.4"/><circle cx="105.5" cy="143" r="1.8" fill="{LINK}"/>')
    return out


def arc(l, r, bow=-8, s=1.0, op=1.0):
    mx, my = (l[0] + r[0]) / 2, (l[1] + r[1]) / 2 + bow
    pts = [l]
    for i in range(1, 8):
        t = i / 8
        x = (1 - t) ** 2 * l[0] + 2 * (1 - t) * t * mx + t * t * r[0]
        y = (1 - t) ** 2 * l[1] + 2 * (1 - t) * t * my + t * t * r[1]
        pts.append((x, y + (3 if i % 2 else -3) * s))
    pts.append(r)
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    return (f'<g opacity="{op}"><circle cx="{f(mx)}" cy="{f(my)}" r="{f(26 * s)}" fill="url(#glow)"/>'
            f'<path d="{d}" stroke="#C9E6FF" stroke-width="{f(4.4 * s)}" fill="none" stroke-linejoin="round" opacity="0.7"/>'
            f'<path d="{d}" stroke="#FFFFFF" stroke-width="{f(1.8 * s)}" fill="none" stroke-linejoin="round"/></g>')


def chevrons(x, y, up=True, n=3):
    d = -1 if up else 1
    return ''.join(f'<path d="M{x - 6} {f(y + i * 10 * d + 5 * -d)} L{x} {f(y + i * 10 * d)} L{x + 6} {f(y + i * 10 * d + 5 * -d)}" '
                   f'stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.8"/>' for i in range(n))


def horn_card(kind):
    out = horn_stage(parallel=(kind == 'parallel'))
    if kind == 'rise':
        l = bez(HL, 0.45)
        out.append(arc(l, mirror(l), -14))
        out.append(chevrons(100, 60))
    elif kind == 'out':
        l = bez(HL, 0.93)
        r = mirror(l)
        out.append(f'<circle cx="100" cy="{f(l[1] - 6)}" r="30" fill="url(#glow)" opacity="0.5"/>')
        out.append(arc(l, (l[0] + 16, l[1] - 4), -3, 0.7, 0.75))
        out.append(arc((r[0] - 16, r[1] - 4), r, -3, 0.7, 0.75))
        out.append(chevrons(100, 70))
    elif kind == 'down':
        out.append(arc((92, 142), (108, 142), 34, 1.0))
        out.append(chevrons(100, 108, up=False))
    elif kind == 'stuck':
        out.append(spark(100, 142, 1.6))
        out.append(arc((92, 142), (108, 142), -2, 1.2))
    elif kind == 'parallel':
        out.append(arc((91, 96), (109, 96), -4, 0.9))
        out.append(chevrons(100, 70))
    return card_close(out)


CARDS = {
    'three_open2': three_card('open2'),
    'three_all3': three_card('all3'),
    'three_one': three_card('one'),
    'three_two': three_card('two'),
    'three_leave': three_card('leave'),
    'operate_open': operate_card('open'),
    'operate_steady': operate_card('steady'),
    'operate_rod': operate_card('rod'),
    'operate_under': operate_card('under'),
    'operate_bang': operate_card('bang'),
    'link_plate': link_card('plate'),
    'link_packet': link_card('packet'),
    'link_thick': link_card('thick'),
    'link_thin': link_card('thin'),
    'link_any': link_card('any'),
    'fit_taut': fit_card('taut'),
    'fit_clean': fit_card('clean'),
    'fit_loose': fit_card('loose'),
    'fit_kink': fit_card('kink'),
    'fit_carbon': fit_card('carbon'),
    'horn_rise': horn_card('rise'),
    'horn_out': horn_card('out'),
    'horn_down': horn_card('down'),
    'horn_stuck': horn_card('stuck'),
    'horn_parallel': horn_card('parallel'),
}

# Safe cards and traps per round (mirrors learn_board_pack34.dart).
ROUNDS = {
    'three': (['three_open2', 'three_all3'], ['three_one', 'three_two', 'three_leave']),
    'operate': (['operate_open', 'operate_steady'], ['operate_rod', 'operate_under', 'operate_bang']),
    'link': (['link_plate', 'link_packet'], ['link_thick', 'link_thin', 'link_any']),
    'fit': (['fit_taut', 'fit_clean'], ['fit_loose', 'fit_kink', 'fit_carbon']),
    'horn': (['horn_rise', 'horn_out'], ['horn_down', 'horn_stuck', 'horn_parallel']),
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
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
