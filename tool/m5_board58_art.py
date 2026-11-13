"""Picture cards for lesson 5.8 শেখা ("ট্রান্সফরমারের সাধারণ সমস্যা: হৃৎপিণ্ডের রোগ নির্ণয়").

python -I tool/m5_board58_art.py .

Writes assets/game/art/m5_board58/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

One stage on every card: a distribution transformer (DTR) on its plinth, the
three HT DO fuses on the cross-arm of the pole behind it, the LT distribution
box on the pole, the oil sight glass on the tank. What the cards show comes
from lesson 5.8 only (module rules for switch-off and prove-dead):
  1. htfuse: the HT DO fuse blows again at once -> first sectionalize (every
     LT way out, then the HT DO in once); a faulty DTR is isolated and sent
     to the workshop; never charged again and again (it can explode), never
     only the HT line walked, never closed onto a punctured HT bushing;
  2. noise: loud, irregular rattling instead of the hum -> the load checked
     first (tong tester); load normal and still noisy -> report to the
     supervisor; never ignored, never ticked "ঠিক আছে", never written off as
     an inside short without the load check;
  3. leak: source and amount found first; small leak with the level fine ->
     watched and logged; big leak -> the DTR off (DOs open), gasket changed,
     oil topped up; never driven past, never wiped and left, never topped up
     without finding the source;
  4. ltdead: HT fuse sound, one LT phase dead -> the DTR off, the tester
     shows dead, then the LT bushing connection checked; connection sound ->
     the DTR replaced; never a spanner on a live DTR, never a new link in a
     DO that did not blow, never left running;
  5. proof: megger IR near zero on an ISOLATED DTR, very dark oil with carbon
     specks, a cracked bushing with a flashover track; never a megger on a
     live DTR, never water beads in the oil shrugged off (myth 2), never the
     old record book binned (pro tip 4).

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one stage; the script checks every hand the dealer can make
(one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. No trap shows the result of its mistake (a flash) when
the safe cards show none, and no card carries a green tick. It deletes only
its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board58_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board58')
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
FUSE = '#3C4148'
CRACK = '#14161A'
MOVE = '#FFFFFF'
OIL = '#B8862E'
TONG = '#E8C830'
PAPER = '#F4F1E8'
BOARD = '#C8A15A'
CROSS = '#D8402F'
MEGGER = '#E8742A'
VAN = '#E9E2D0'
LAMP = '#FFE27A'
GLASS = '#DCE6EE'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4E5F86"/><stop offset="0.6" stop-color="#C98E73"/><stop offset="1" stop-color="#E8C39A"/></linearGradient>
  <linearGradient id="haze" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA8B4"/><stop offset="1" stop-color="#DCE2E6"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5F7069"/><stop offset="0.45" stop-color="#9DB0A8"/><stop offset="1" stop-color="#596A63"/></linearGradient>
  <linearGradient id="plinth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9C3B6"/><stop offset="1" stop-color="#9E978A"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7D878E"/><stop offset="0.5" stop-color="#A9B3BA"/><stop offset="1" stop-color="#6D777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E6A4E"/><stop offset="0.5" stop-color="#D49A78"/><stop offset="1" stop-color="#8A5A40"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="rod" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6CF5E"/><stop offset="0.5" stop-color="#E5A126"/><stop offset="1" stop-color="#B9781A"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFE9A8"/><stop offset="1" stop-color="#FF9A3D" stop-opacity="0"/></radialGradient>
  <radialGradient id="pool" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#3A2A12"/><stop offset="0.7" stop-color="#5A4220" stop-opacity="0.85"/><stop offset="1" stop-color="#5A4220" stop-opacity="0"/></radialGradient>
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
# The worker (copied from tool/m4_board41_art.py): one figure, any pose.
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


def _hand(p):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves."""
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
    g.append(_hand(hb))
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
    g.append(_hand(hf))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=1, look=0, stride=0):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates. stride > 0 = walking."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    sp = 7 + stride
    feet = ((x - sp * face, GY - 1), (x + (sp - 1) * face, GY - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


# --------------------------------------------------------------------------
# The stage: pole, cross-arm, three DO fuses, the DTR on its plinth, the LT
# distribution box. Every card of every round draws it.
# --------------------------------------------------------------------------

PX = 150          # pole left edge
PW = 12
ARM_Y = 34
DOS = (84, 104, 124)
HINGE_Y = 64      # the DO barrel's bottom hinge
TANK = (66, 112, 142, 176)
HTB_TOP = 96
LTB = ((146, 128), (146, 140), (146, 152))   # LT bushing tips
BOX = (164, 116, 194, 158)
WAYS = (124, 136, 148)                         # LT fuse way rows in the box


def do_cutout(x, state='closed'):
    """One DO: porcelain body, the barrel beside it. closed = latched up;
    open = dropped, hanging from its hinge."""
    s = [f'<rect x="{x - 3}" y="{ARM_Y + 6}" width="6" height="22" rx="2" fill="url(#porcelain)"/>']
    for y in (ARM_Y + 10, ARM_Y + 16, ARM_Y + 22):
        s.append(f'<ellipse cx="{x}" cy="{y}" rx="5" ry="1.5" fill="url(#porcelain)"/>')
    s.append(f'<rect x="{x - 1}" y="{ARM_Y + 3}" width="10" height="3" fill="url(#arm)"/>')
    s.append(f'<rect x="{x - 1}" y="{HINGE_Y - 1}" width="10" height="3" fill="url(#arm)"/>')
    top = (x + 7, ARM_Y + 6)
    bot = (x + 7, HINGE_Y)
    barrel = (f'<path d="M{f(bot[0])} {f(bot[1])} L{f(top[0])} {f(top[1])}" stroke="{FUSE}" stroke-width="4.4" stroke-linecap="round"/>'
              f'<circle cx="{f(top[0] + 1)}" cy="{f(top[1] + 6)}" r="2.4" fill="none" stroke="#7D868E" stroke-width="1.4"/>')
    if state == 'open':
        barrel = f'<g transform="rotate(-160 {f(bot[0])} {f(bot[1])})">{barrel}</g>'
    s.append(barrel)
    return ''.join(s)


def ring(i, state='closed'):
    """Where the hot stick hooks DO i."""
    x = DOS[i]
    if state == 'open':
        return (x + 9, HINGE_Y + 16)
    return (x + 8, ARM_Y + 12)


def htb(x, cracked=False):
    """An HT bushing standing on the tank lid."""
    s = [f'<rect x="{x - 3}" y="{HTB_TOP}" width="6" height="{TANK[1] - HTB_TOP}" rx="2" fill="url(#porcelain)"/>']
    for y in (HTB_TOP + 4, HTB_TOP + 9):
        s.append(f'<ellipse cx="{x}" cy="{y}" rx="5" ry="1.6" fill="url(#porcelain)"/>')
    if cracked:
        s.append(f'<path d="M{x - 2} {HTB_TOP + 2} L{x + 1} {HTB_TOP + 6} L{x - 1} {HTB_TOP + 9} L{x + 2} {HTB_TOP + 14}" '
                 f'stroke="{CRACK}" stroke-width="1.4" fill="none"/>')
        # The flashover track: a black burn streak down the sheds to the lid.
        s.append(f'<path d="M{x + 3} {HTB_TOP + 1} Q{x + 7} {HTB_TOP + 8} {x + 4} {TANK[1] + 1}" stroke="{HAIR}" stroke-width="2.6" fill="none" opacity="0.85"/>')
    return ''.join(s)


def stage(back, dos=('closed', 'closed', 'closed'), ways='in', tank=True, cracked=False, lamps=(1, 1, 1),
          gauge='ok', ground_items=''):
    out = card_open(back)
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # HT line in from the left to the cross-arm.
    for i, y in enumerate((14, 20, 26)):
        out.append(f'<path d="M-4 {y + 8} Q40 {y + 14} {DOS[i]} {ARM_Y + 4}" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
    out.append(f'<rect x="{PX}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<rect x="70" y="{ARM_Y}" width="104" height="5" fill="url(#arm)"/>')
    for i, x in enumerate(DOS):
        out.append(do_cutout(x, dos[i]))
    # Jumpers from the DO bottoms to the HT bushing tops.
    if tank:
        for x in DOS:
            out.append(f'<path d="M{x + 7} {HINGE_Y + 2} Q{x + 6} {HINGE_Y + 18} {x} {HTB_TOP}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    # Plinth.
    out.append(f'<rect x="56" y="{TANK[3]}" width="96" height="{GY - TANK[3] + 2}" fill="url(#plinth)"/>')
    if tank:
        out.append(dtr_tank(cracked=cracked, gauge=gauge))
    # LT distribution box on the pole, cables from the LT bushings.
    x0, y0, x1, y1 = BOX
    if tank:
        for (bx, by), wy in zip(LTB, WAYS):
            out.append(f'<path d="M{bx} {by} Q{bx + 10} {by + 2} {x0} {wy}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
    out.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="2" fill="url(#box)" stroke="{WIRE}" stroke-width="0.8"/>')
    for wy in WAYS:
        out.append(f'<rect x="{x0 + 5}" y="{wy - 4}" width="16" height="8" rx="1" fill="{CRACK}"/>')
        if ways == 'in':
            out.append(f'<rect x="{x0 + 6}" y="{wy - 3}" width="14" height="6" rx="1" fill="{PAPER}"/>')
    for i, wy in enumerate(WAYS):
        out.append(f'<circle cx="{x1 - 5}" cy="{wy}" r="2.2" fill="{LAMP if lamps[i] else CRACK}"/>')
    out.append(f'<path d="M{x0 + 8} {y1} L{x0 + 8} {GY + 3}" stroke="{WIRE}" stroke-width="2.4"/>')
    if ways == 'out':
        # The three LT fuse carriers pulled out, laid on the ground.
        for i in range(3):
            out.append(f'<rect x="{150 + i * 16}" y="{GY + 6}" width="13" height="5" rx="1" fill="{PAPER}" stroke="{WIRE}" stroke-width="0.6"/>')
    out.append(ground_items)
    return out


def dtr_tank(dx=0, dy=0, cracked=False, gauge='ok'):
    x0, y0, x1, y1 = TANK
    s = []
    for i in range(5):
        fx = x0 - 9 + i * 2
        s.append(f'<rect x="{fx}" y="{y0 + 8}" width="1.6" height="{y1 - y0 - 14}" fill="url(#arm)"/>')
    s.append(f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" rx="3" fill="url(#tank)"/>')
    s.append(f'<rect x="{x0 - 4}" y="{y0 - 4}" width="{x1 - x0 + 8}" height="6" rx="2" fill="url(#arm)"/>')
    s.append(f'<path d="M{x0 + 2} {y1 - 8} L{x1 - 2} {y1 - 8}" stroke="{WIRE}" stroke-width="1" opacity="0.5"/>')
    # Oil sight glass: level fine (half) or low.
    level = {'ok': 0.5, 'low': 0.85}[gauge]
    s.append(f'<rect x="{x1 - 16}" y="{y0 + 8}" width="8" height="20" rx="3" fill="{GLASS}" stroke="{WIRE}" stroke-width="0.8"/>')
    s.append(f'<rect x="{x1 - 15}" y="{f(y0 + 9 + 18 * level)}" width="6" height="{f(18 * (1 - level))}" rx="2" fill="{OIL}"/>')
    for x in DOS:
        s.append(htb(x, cracked=cracked and x == DOS[1]))
    for bx, by in LTB:
        s.append(f'<rect x="{x1}" y="{by - 2.5}" width="{bx - x1}" height="5" rx="1.5" fill="url(#porcelain)"/>')
    body = ''.join(s)
    return f'<g transform="translate({dx} {dy})">{body}</g>' if (dx or dy) else body


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def motion(x, y, dx=0, dy=1, n=3, length=9):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def rattle(x, y, side=-1):
    """Loud, irregular noise: jagged white bolts off the tank."""
    o = []
    for i, (oy, ln) in enumerate(((-12, 14), (0, 18), (12, 12))):
        sx = x + side * 2
        d = f'M{f(sx)} {f(y + oy)} l{f(side * ln * 0.3)} -4 l{f(side * ln * 0.25)} 7 l{f(side * ln * 0.25)} -6 l{f(side * ln * 0.2)} 4'
        o.append(f'<path d="{d}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" fill="none" stroke-linejoin="round" stroke-linecap="round">{"".join(o)}</g>'


def hot_stick(p0, p1):
    (x0, y0), (x1, y1) = p0, p1
    L = math.hypot(x1 - x0, y1 - y0)
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    s = (f'<rect x="0" y="-2" width="{f(L)}" height="4" rx="1.6" fill="url(#rod)"/>'
         f'<rect x="{f(L * 0.4)}" y="-2.6" width="3" height="5.2" fill="#7D868E"/>'
         f'<path d="M{f(L)} 0 q6 0 6 -4 q0 -4 -4 -4" stroke="#7D868E" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    return f'<g transform="translate({f(x0)} {f(y0)}) rotate({f(ang)})">{s}</g>'


def fuse_link(x, y, ang=0, spent=False):
    s = (f'<rect x="-1" y="-9" width="2" height="18" fill="url(#steel)"/>'
         f'<rect x="-3" y="-3" width="6" height="6" rx="1" fill="{CROSS if not spent else HAIR}"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{s}</g>'


def tong_tester(x, y, ang=0):
    s = (f'<rect x="-4" y="0" width="8" height="18" rx="2.5" fill="{TONG}" stroke="{WIRE}" stroke-width="0.7"/>'
         f'<rect x="-2.6" y="3" width="5.2" height="4" rx="0.8" fill="{CRACK}"/>'
         f'<circle cx="0" cy="-6" r="6.5" fill="none" stroke="{WIRE}" stroke-width="2.6"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{s}</g>'


def phone(x, y):
    return f'<rect x="{f(x - 2.5)}" y="{f(y - 5)}" width="5" height="10" rx="1.2" fill="{GLOVE}" stroke="{MOVE}" stroke-width="0.5"/>'


def clipboard(x, y, mark=''):
    s = [f'<rect x="{f(x - 8)}" y="{f(y - 10)}" width="16" height="20" rx="1.5" fill="{BOARD}"/>',
         f'<rect x="{f(x - 6)}" y="{f(y - 7)}" width="12" height="15" fill="{PAPER}"/>',
         f'<rect x="{f(x - 3)}" y="{f(y - 11.5)}" width="6" height="3" rx="1" fill="#7D868E"/>']
    for i in range(3):
        s.append(f'<path d="M{f(x - 4)} {f(y - 4 + i * 4)} l8 0" stroke="{WIRE}" stroke-width="0.7" opacity="0.6"/>')
    if mark == 'scribble':
        # Fresh handwriting, the same on every card: never a tick or a cross
        # (the universal right/wrong marks, banned on cards by §4).
        s.append(f'<path d="M{f(x - 4)} {f(y + 6)} q1.5 -2.5 3 0 t3 0 t3 0" stroke="{WIRE}" stroke-width="1.1" fill="none" stroke-linecap="round"/>')
    return ''.join(s)


def spanner(x, y, ang=0):
    s = (f'<rect x="0" y="-1.6" width="16" height="3.2" rx="1" fill="url(#steel)"/>'
         f'<path d="M16 -4 a4 4 0 1 1 0 8 l2 -2.4 l0 -3.2 Z" fill="url(#steel)"/>'
         f'<rect x="-2" y="-2.2" width="7" height="4.4" rx="1.5" fill="{CROSS}"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{s}</g>'


def tester(x, y, ang=0, lit=False):
    """A voltage tester probe: red body, its lamp dark (dead) or lit."""
    s = (f'<rect x="-2.5" y="0" width="5" height="22" rx="2" fill="{CROSS}"/>'
         f'<rect x="-1" y="-8" width="2" height="8" fill="url(#steel)"/>'
         f'<circle cx="0" cy="5" r="2" fill="{LAMP if lit else CRACK}"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{s}</g>'


def oil_can(x, y, ang=0, pouring=False):
    s = [f'<rect x="-8" y="-10" width="16" height="20" rx="2" fill="{CROSS}"/>',
         f'<path d="M8 -6 L16 -14" stroke="{CROSS}" stroke-width="3" stroke-linecap="round"/>',
         f'<rect x="-6" y="-14" width="8" height="4" rx="1" fill="#7D868E"/>']
    if pouring:
        s.append(f'<path d="M16 -14 Q20 -6 19 4" stroke="{OIL}" stroke-width="2.2" fill="none"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{"".join(s)}</g>'


def drip(x, y, big=False):
    if big:
        return (f'<path d="M{x} {y} Q{x + 2} {y + 18} {x + 1} {GY + 2}" stroke="{OIL}" stroke-width="2.6" fill="none"/>'
                f'<ellipse cx="{x + 4}" cy="{GY + 6}" rx="34" ry="7" fill="url(#pool)"/>')
    return (f'<path d="M{x} {y} q-2.4 4 0 6 q2.4 -2 0 -6 Z" fill="{OIL}"/>'
            f'<ellipse cx="{x}" cy="{GY + 4}" rx="5" ry="1.6" fill="url(#pool)"/>')


def gasket(x, y):
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="6" ry="3.4" fill="none" stroke="{GLOVE}" stroke-width="2.2"/>'


def cloth(x, y):
    return f'<path d="M{f(x - 6)} {f(y - 4)} l11 -2 l3 9 l-12 3 Z" fill="{VAN}" stroke="{OIL}" stroke-width="0.8"/>'


def van(x, y, moving=False):
    s = [f'<rect x="{x}" y="{y - 22}" width="44" height="18" rx="3" fill="{VAN}" stroke="{WIRE}" stroke-width="0.8"/>',
         f'<path d="M{x + 44} {y - 18} L{x + 56} {y - 18} L{x + 60} {y - 8} L{x + 60} {y - 4} L{x + 44} {y - 4} Z" fill="{VAN}" stroke="{WIRE}" stroke-width="0.8"/>',
         f'<path d="M{x + 46} {y - 16} L{x + 55} {y - 16} L{x + 58} {y - 9} L{x + 46} {y - 9} Z" fill="{WIRE}"/>',
         f'<circle cx="{x + 10}" cy="{y - 3}" r="5" fill="{BOOT}"/>', f'<circle cx="{x + 48}" cy="{y - 3}" r="5" fill="{BOOT}"/>']
    if moving:
        s.append(motion(x - 6, y - 12, -1, 0, 3, 10))
    return ''.join(s)


def crane(hook_x, hook_y):
    """A truck crane's boom from the top right, hook and slings."""
    return (f'<path d="M210 40 L{hook_x + 6} 6" stroke="{HELMET_D}" stroke-width="7" stroke-linecap="round"/>'
            f'<path d="M{hook_x + 6} 6 L{hook_x} {hook_y - 8}" stroke="{WIRE}" stroke-width="1.2"/>'
            f'<path d="M{hook_x} {hook_y - 8} q4 0 4 4 q0 4 -4 4" stroke="#7D868E" stroke-width="2" fill="none"/>')


def slings(hook, tank_top, x0, x1):
    return (f'<path d="M{hook[0]} {hook[1]} L{x0} {tank_top} M{hook[0]} {hook[1]} L{x1} {tank_top}" '
            f'stroke="{WIRE}" stroke-width="1.2"/>')


def megger(x, y, needle=0.0):
    """The insulation tester: orange case, dial, crank. needle 0 = at zero
    (left), 1 = high."""
    a = math.radians(200 + 140 * needle)
    nx, ny = x + math.cos(a) * 7, y - 2 + math.sin(a) * 7
    return (f'<rect x="{x - 12}" y="{y - 12}" width="24" height="20" rx="3" fill="{MEGGER}" stroke="{WIRE}" stroke-width="0.8"/>'
            f'<path d="M{x - 8} {y - 2} A8 8 0 0 1 {x + 8} {y - 2} Z" fill="{PAPER}"/>'
            f'<path d="M{x} {y - 2} L{f(nx)} {f(ny)}" stroke="{CRACK}" stroke-width="1.2"/>'
            f'<path d="M{x + 12} {y + 2} l6 0 l0 6" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')


def leads(src, dsts):
    return ''.join(f'<path d="M{src[0]} {src[1]} Q{(src[0] + d[0]) / 2} {max(src[1], d[1]) + 14} {d[0]} {d[1]}" '
                   f'stroke="{CROSS if i == 0 else WIRE}" stroke-width="1.2" fill="none"/>' for i, d in enumerate(dsts))


def jar(x, y, oil='dark'):
    s = [f'<rect x="{x - 7}" y="{y - 12}" width="14" height="22" rx="3" fill="{GLASS}" opacity="0.8" stroke="{WIRE}" stroke-width="0.8"/>']
    if oil == 'dark':
        s.append(f'<rect x="{x - 6}" y="{y - 6}" width="12" height="15" rx="2" fill="{HAIR}"/>')
        for px, py in ((-2, -2), (2, 2), (-3, 5), (3, -4), (0, 6)):
            s.append(f'<circle cx="{x + px}" cy="{y + py}" r="0.9" fill="{BOOT}" stroke="{MOVE}" stroke-width="0.3"/>')
    else:
        s.append(f'<rect x="{x - 6}" y="{y - 6}" width="12" height="15" rx="2" fill="{OIL}"/>')
        for px, py in ((-2, 6), (2, 5), (0, 7)):
            s.append(f'<circle cx="{x + px}" cy="{y + py}" r="1.6" fill="{GLASS}" stroke="{MOVE}" stroke-width="0.4"/>')
    s.append(f'<rect x="{x - 7.5}" y="{y - 14}" width="15" height="3" rx="1" fill="#7D868E"/>')
    return ''.join(s)


def book(x, y, ang=0):
    s = (f'<rect x="-8" y="-6" width="16" height="12" rx="1" fill="{SKIN_D}"/>'
         f'<rect x="-7" y="-5" width="7" height="10" fill="{PAPER}"/><rect x="0" y="-5" width="7" height="10" fill="{PAPER}"/>'
         f'<path d="M0 -6 L0 6" stroke="{SKIN_D}" stroke-width="1"/>')
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">{s}</g>'


def binbox(x, y):
    return (f'<path d="M{x - 9} {y - 16} L{x + 9} {y - 16} L{x + 7} {y} L{x - 7} {y} Z" fill="url(#steel)" stroke="{WIRE}" stroke-width="0.8"/>'
            f'<rect x="{x - 10}" y="{y - 18}" width="20" height="3" rx="1" fill="#7D868E"/>')


def lens(x, y):
    return (f'<circle cx="{x}" cy="{y}" r="7" fill="{GLASS}" opacity="0.55" stroke="{WIRE}" stroke-width="1.8"/>'
            f'<path d="M{x + 5} {y + 5} l7 7" stroke="{WIRE}" stroke-width="3" stroke-linecap="round"/>')


OPEN3 = ('open', 'open', 'open')


# --------------------------------------------------------------------------
# Round 1 — htfuse: the HT DO fuse blows again at once.
# --------------------------------------------------------------------------

def htfuse_card(kind):
    if kind == 'section':
        # Every LT way out (carriers on the ground), then one DO in with the stick.
        out = stage('sky', dos=('closed', 'open', 'open'), ways='out')
        out.append(fuse_link(30, GY + 8, 80, spent=True))
        out.append(hot_stick((40, 146), ring(0)))
        out.append(worker(30, ((40, 146), (48, 132)), face=1, look=-14))
    elif kind == 'workshop':
        # Faulty DTR off its plinth on the crane, the van waiting.
        out = stage('sky', dos=OPEN3, tank=False)
        out.append(crane(104, 84))
        out.append(slings((104, 84), 98, 70, 138))
        out.append(dtr_tank(dy=-12))
        out.append(van(0, GY + 4))
        out.append(fuse_link(30, GY + 8, 80, spent=True))
        out.append(worker(30, ((42, 150), (44, 112)), face=1, look=-18))
    elif kind == 'third':
        # LT ways still in, two spent links on the ground, the DO pushed in
        # again. No flash: the result plays only after the pick.
        out = stage('sky', dos=('closed', 'open', 'open'))
        out.append(fuse_link(30, GY + 8, 80, spent=True))
        out.append(fuse_link(46, GY + 9, 100, spent=True))
        out.append(hot_stick((40, 146), ring(0)))
        out.append(worker(30, ((40, 146), (48, 132)), face=1, look=-14))
    elif kind == 'htonly':
        # He walks off along the HT line, eyes up; the LT cable at the box is scorched.
        out = stage('sky', dos=OPEN3, lamps=(1, 0, 1))
        out.append(f'<path d="M{BOX[0] - 4} {WAYS[1] - 4} q-6 6 -2 10" stroke="{HAIR}" stroke-width="4" fill="none" opacity="0.8"/>')
        out.append(van(0, GY + 4))
        out.append(fuse_link(46, GY + 9, 100, spent=True))
        out.append(worker(22, ((14, 150), (32, 152)), face=-1, look=-24, stride=4))
        out.append(motion(42, 170, 1, 0, 3, 8))
    elif kind == 'bushing':
        # The middle HT bushing is cracked with a flashover track; the DO is closed onto it.
        out = stage('sky', dos=('open', 'closed', 'open'), cracked=True)
        out.append(fuse_link(30, GY + 8, 80, spent=True))
        out.append(hot_stick((40, 146), ring(1)))
        out.append(worker(30, ((40, 146), (48, 132)), face=1, look=-14))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — noise: loud, irregular rattling instead of the hum.
# --------------------------------------------------------------------------

def noise_card(kind):
    if kind == 'load':
        out = stage('dusk')
        out.append(rattle(TANK[0] - 12, 140))
        out.append(worker(182, ((172, 186), (174, 168)), face=-1, look=18))
        out.append(tong_tester(BOX[0] + 8, 172, 0))
    elif kind == 'report':
        out = stage('dusk')
        out.append(rattle(TANK[0] - 12, 140))
        out.append(worker(182, ((176, 176), (186, 118)), face=-1, look=6))
        out.append(tong_tester(176, 170, 8))
        out.append(phone(186, 116))
    elif kind == 'walkaway':
        out = stage('dusk')
        out.append(rattle(TANK[0] - 12, 140))
        out.append(tong_tester(36, GY + 2, 90))
        out.append(worker(22, ((16, 150), (30, 152)), face=-1, look=0, stride=4))
        out.append(motion(40, 172, 1, 0, 3, 8))
    elif kind == 'tickok':
        out = stage('dusk')
        out.append(rattle(TANK[0] - 12, 140))
        out.append(worker(182, ((176, 176), (180, 136)), face=-1, look=14))
        out.append(tong_tester(176, 170, 8))
        out.append(clipboard(184, 134, 'scribble'))
        out.append(phone(36, GY + 4))
    elif kind == 'guess':
        out = stage('dusk')
        out.append(rattle(TANK[0] - 12, 140))
        out.append(tong_tester(36, GY + 2, 90))
        out.append(worker(182, ((190, 142), (180, 136)), face=-1, look=14))
        out.append(clipboard(184, 134, 'scribble'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — leak: oil seeping down the tank.
# --------------------------------------------------------------------------

GASKET_Y = TANK[1] + 4


def leak_card(kind):
    if kind == 'watch':
        out = stage('sky')
        out.append(drip(TANK[0] + 10, TANK[3] - 6))
        out.append(worker(36, ((52, 146), (56, 138)), face=1, look=8))
        out.append(clipboard(52, 140))
    elif kind == 'fix':
        # DOs open AND the tester against the tank shows dead (dark lamp,
        # M5-2) before the spanner goes on the gasket bolt.
        out = stage('sky', dos=OPEN3, gauge='low')
        out.append(drip(TANK[0] + 10, TANK[3] - 6, big=True))
        out.append(worker(40, ((44, 158), (56, 120)), face=1, look=-6))
        out.append(tester(58, 152, 70))
        out.append(spanner(54, 120, -20))
        out.append(gasket(44, GY + 8))
        out.append(oil_can(24, GY - 8))
    elif kind == 'driveoff':
        out = stage('sky', gauge='low')
        out.append(drip(TANK[0] + 10, TANK[3] - 6, big=True))
        out.append(van(-6, GY + 6, moving=True))
        out.append(gasket(184, GY + 8))
        out.append(clipboard(30, GY + 6))
        out.append(spanner(44, GY + 8, 10))
    elif kind == 'wipe':
        # A small drip too (the lesson's point here is moisture, not size).
        out = stage('sky')
        out.append(drip(TANK[0] + 10, TANK[3] - 6))
        out.append(worker(44, ((70, 150), (60, 160)), face=1, look=10))
        out.append(cloth(70, 150))
        out.append(motion(64, 162, 0, 1, 2, 6))
    elif kind == 'pour':
        out = stage('sky', gauge='low')
        out.append(drip(TANK[0] + 10, TANK[3] - 6, big=True))
        out.append(worker(52, ((76, 104), (70, 94)), face=1, look=-12))
        out.append(oil_can(84, 96, 30, pouring=True))
        out.append(clipboard(30, GY + 6))
        out.append(tester(182, GY + 8, 90))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — ltdead: HT fuse sound, one LT phase dead.
# --------------------------------------------------------------------------

def ltdead_card(kind):
    if kind == 'check':
        out = stage('sky', dos=OPEN3, lamps=(1, 0, 1))
        out.append(worker(178, ((168, 136), (172, 168)), face=-1, look=10))
        out.append(tester(150, 130, -70))
        out.append(spanner(176, 186, -10))
    elif kind == 'swap':
        # The connection was sound: the DTR is replaced (the crane sets the new one).
        out = stage('sky', dos=OPEN3, tank=False, lamps=(0, 0, 0))
        out.append(crane(104, 80))
        out.append(slings((104, 80), 96, 70, 138))
        out.append(dtr_tank(dy=-16))
        out.append(tester(30, GY + 6, 90))
        out.append(worker(178, ((168, 150), (172, 130)), face=-1, look=-16))
    elif kind == 'livespanner':
        out = stage('sky', lamps=(1, 0, 1))
        out.append(worker(178, ((166, 140), (172, 168)), face=-1, look=10))
        out.append(spanner(166, 140, 180))
        out.append(tester(30, GY + 6, 90))
    elif kind == 'newlink':
        out = stage('sky', dos=('closed', 'open', 'closed'), lamps=(1, 0, 1))
        out.append(hot_stick((40, 146), ring(1, 'open')))
        out.append(worker(30, ((40, 146), (52, 134)), face=1, look=-14))
        out.append(fuse_link(52, 132, 20))
    elif kind == 'leftrun':
        out = stage('sky', lamps=(1, 0, 1))
        out.append(spanner(30, GY + 8, 10))
        out.append(worker(22, ((16, 150), (30, 152)), face=-1, look=0, stride=4))
        out.append(motion(40, 172, 1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — proof: what proves an inside fault.
# --------------------------------------------------------------------------

def proof_card(kind):
    if kind == 'ir':
        out = stage('haze', dos=OPEN3)
        out.append(megger(36, GY - 8, needle=0.0))
        out.append(leads((40, GY - 18), [(DOS[0], HTB_TOP + 1), (TANK[0] + 4, TANK[3] - 4)]))
        out.append(worker(178, ((170, 150), (172, 164)), face=-1, look=0))
    elif kind == 'oil':
        out = stage('haze', dos=OPEN3)
        out.append(worker(182, ((176, 128), (172, 132)), face=-1, look=-8))
        out.append(jar(174, 120, 'dark'))
    elif kind == 'bushing':
        out = stage('haze', dos=OPEN3, cracked=True)
        out.append(lens(DOS[1] + 14, HTB_TOP + 8))
        out.append(worker(44, ((60, 116), (54, 150)), face=1, look=-18))
    elif kind == 'livemegger':
        out = stage('haze')
        out.append(megger(36, GY - 8, needle=0.0))
        out.append(leads((40, GY - 18), [(DOS[0], HTB_TOP + 1), (TANK[0] + 4, TANK[3] - 4)]))
        out.append(worker(178, ((170, 150), (172, 164)), face=-1, look=0))
    elif kind == 'water':
        out = stage('haze', dos=OPEN3)
        out.append(jar(30, GY - 10, 'water'))
        out.append(jar(46, GY - 10, 'dark'))
        out.append(worker(182, ((168, 132), (194, 132)), face=-1, look=20))
    elif kind == 'records':
        out = stage('haze', dos=OPEN3, cracked=True)
        out.append(binbox(30, GY + 2))
        out.append(worker(52, ((40, 162), (60, 150)), face=-1, look=6))
        out.append(book(34, 168, -30))
        out.append(motion(38, 178, 0, 1, 2, 6))
        out.append(lens(178, GY + 6))
    return card_close(out)


CARDS = {
    'htfuse_section': htfuse_card('section'),
    'htfuse_workshop': htfuse_card('workshop'),
    'htfuse_third': htfuse_card('third'),
    'htfuse_htonly': htfuse_card('htonly'),
    'htfuse_bushing': htfuse_card('bushing'),
    'noise_load': noise_card('load'),
    'noise_report': noise_card('report'),
    'noise_walkaway': noise_card('walkaway'),
    'noise_tickok': noise_card('tickok'),
    'noise_guess': noise_card('guess'),
    'leak_watch': leak_card('watch'),
    'leak_fix': leak_card('fix'),
    'leak_driveoff': leak_card('driveoff'),
    'leak_wipe': leak_card('wipe'),
    'leak_pour': leak_card('pour'),
    'ltdead_check': ltdead_card('check'),
    'ltdead_swap': ltdead_card('swap'),
    'ltdead_livespanner': ltdead_card('livespanner'),
    'ltdead_newlink': ltdead_card('newlink'),
    'ltdead_leftrun': ltdead_card('leftrun'),
    'proof_ir': proof_card('ir'),
    'proof_oil': proof_card('oil'),
    'proof_bushing': proof_card('bushing'),
    'proof_livemegger': proof_card('livemegger'),
    'proof_water': proof_card('water'),
    'proof_records': proof_card('records'),
}

# Safe cards and traps per round (mirrors learn_board_pack58.dart).
ROUNDS = {
    'htfuse': (['htfuse_section', 'htfuse_workshop'], ['htfuse_third', 'htfuse_htonly', 'htfuse_bushing']),
    'noise': (['noise_load', 'noise_report'], ['noise_walkaway', 'noise_tickok', 'noise_guess']),
    'leak': (['leak_watch', 'leak_fix'], ['leak_driveoff', 'leak_wipe', 'leak_pour']),
    'ltdead': (['ltdead_check', 'ltdead_swap'], ['ltdead_livespanner', 'ltdead_newlink', 'ltdead_leftrun']),
    'proof': (['proof_ir', 'proof_oil', 'proof_bushing'], ['proof_livemegger', 'proof_water', 'proof_records']),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    body = {k: v.split('</defs>')[-1] for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
        if not any('url(#spark)' in body[s] for s in safes):
            for t in traps:
                if 'url(#spark)' in body[t]:
                    problems.append(f'{rnd}: {t} shows a flash before the pick')
    for k, v in CARDS.items():
        if '<text' in v:
            problems.append(f'{k}: words in the art')
        if '#3E9B4F' in body[k].upper():
            problems.append(f'{k}: a green tick on a card')
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
