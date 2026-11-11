"""Picture cards for the lesson 3.2 শেখা board ("ইনসুলেটর পরিচিতি: পিন, ডিস্ক, শ্যাকল").

python -I tool/m3_board32_art.py .

Writes assets/game/art/m3_board32/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge; the look
round reuses that script's worker, ladder and pole). No words in the art.

What the cards show comes from lesson 3.2 and its checked film script only:
  1. look: before going up, the insulators are checked from below (binoculars
     or the naked eye) for a break or black marks; a broken insulator is a
     death trap; when it fails the pole goes live — whoever touches it dies;
  2. pin: straight line, pin insulator — conductor in the head groove, a
     tight binding; the petticoat sheds rain off the pin; a loose binding
     sparks and cracks it; a broken edge collects water and dust and leaks;
     wet bird droppings conduct;
  3. end: at a dead end or a turn a pin insulator breaks — a shackle (reel)
     on a D-iron takes the pull; a shackle worn sharp cuts the conductor;
  4. disc: a string of discs at a suspension or tension point; 1 disc = 11 kV,
     3 = 33 kV, a long string (drawn with 8: the lesson says 6 or more, the
     film 8–10) = 132 kV; a hairline crack blasts at high voltage;
  5. clean: by the sea or factories a salt / dust layer flashes over in fog
     or rain — routine washing; a bird's nest or droppings are cleaned off;
     polymer insulators do better in dirty places. The cleaning card draws
     the line earthed (house rule: work only after shutdown and earthing).

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one stage; the script checks every hand the dealer can make
(one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand too, and the safe card's backdrop is a
trap's backdrop too.
"""

import importlib.util
import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board32_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board32')
W, H = 200, 220

# The step-25 worker, ladder and pole (tool/storm_board_art.py).
_spec = importlib.util.spec_from_file_location('storm_board_art', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'storm_board_art.py'))
sb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sb)

f = sb.f
card_close = sb.card_close
GY = sb.GY

WIRE = sb.WIRE
BIND = '#D5DBE0'
PIN = '#7D868E'
RIM = '#9AA5AD'
CRACK = '#3A3F45'
BURN = '#2E2A26'
WATER = '#8CC4EA'
DIRT = '#8A6A3E'
SALT = '#EEEBE2'
DUST = '#8C8270'
TWIG = '#7A5A36'
HARNESS = '#E8762B'
TREE = '#6F9560'
SEA = '#6E9BB5'
FACTORY = '#7A7F86'
SMOKE = '#5B5F66'
ARC = '#C9E6FF'
TOWER = '#5F676F'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2D9"/><stop offset="1" stop-color="#CFE3EF"/></linearGradient>
  <linearGradient id="haze" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA9B4"/><stop offset="1" stop-color="#D3DADF"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="polymer" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#4E6158"/><stop offset="0.5" stop-color="#7D9488"/><stop offset="1" stop-color="#46584F"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def g(x, y, ang=0, s=1.0, body=''):
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({f(s)})">{body}</g>'


def path(pts, close=True):
    return 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts) + (' Z' if close else '')


def spark(x, y, r=14):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#spark)"/>'
            f'<path d="M{f(x - r * 0.6)} {f(y - r * 0.2)} l{f(r * 0.4)} {f(r * 0.3)} l{f(r * 0.2)} {f(-r * 0.5)} l{f(r * 0.5)} {f(r * 0.4)}" '
            f'stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linecap="round"/>')


def arc_down(x0, y0, x1, y1):
    """A flashover: a jagged bright arc from (x0, y0) down to (x1, y1)."""
    pts = []
    for i in range(7):
        t = i / 6
        x = x0 + (x1 - x0) * t + (5 if i % 2 else -5) * (0 < i < 6)
        pts.append((x, y0 + (y1 - y0) * t))
    return (f'<path d="{path(pts, False)}" stroke="{ARC}" stroke-width="4" fill="none" opacity="0.6" stroke-linejoin="round"/>'
            f'<path d="{path(pts, False)}" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linejoin="round"/>'
            + spark(x0, y0, 12) + spark(x1, y1, 10))


def rain(n=26, seed=3):
    out = []
    for i in range(n):
        x = (i * 37 + seed * 11) % 210 - 5
        y = (i * 53 + seed * 7) % 200
        out.append(f'<path d="M{x} {y} l-3 9"/>')
    return f'<g stroke="{WATER}" stroke-width="1.4" stroke-linecap="round" opacity="0.85">{"".join(out)}</g>'


# --------------------------------------------------------------------------
# The pin insulator (local coordinates: the foot of the pin at 0,0, the
# conductor groove at 0,-126).
# --------------------------------------------------------------------------

_PIN_R = [(20, -130), (24, -100), (28, -96), (54, -78), (54, -73), (32, -72), (34, -66), (68, -46), (68, -41), (20, -40), (12, -36)]
_PIN_CHIP = [(20, -130), (24, -100), (28, -96), (54, -78), (54, -73), (32, -72), (34, -66), (44, -60), (36, -50), (40, -41), (20, -40), (12, -36)]
_PIN_BROKEN = [(20, -130), (24, -100), (28, -96), (40, -88), (34, -80), (44, -73), (32, -72), (34, -66), (68, -46), (68, -41), (20, -40), (12, -36)]
GROOVE = -126


def pin_ins(state='ok', binding='tight'):
    right = {'chip': _PIN_CHIP, 'broken': _PIN_BROKEN}.get(state, _PIN_R)
    left = [(-x, y) for x, y in reversed(_PIN_R)]
    body = right + left
    o = [f'<rect x="-6" y="-42" width="12" height="42" fill="url(#steel)"/>',
         f'<path d="{path(body)}" fill="url(#porcelain)" stroke="{RIM}" stroke-width="1.2" stroke-linejoin="round"/>',
         f'<path d="M-50 -73 Q0 -66 50 -73" stroke="{RIM}" stroke-width="3" fill="none"/>',
         f'<path d="M-64 -41 Q0 -33 64 -41" stroke="{RIM}" stroke-width="3" fill="none"/>',
         f'<path d="M-9 -130 Q0 -122 9 -130" stroke="{RIM}" stroke-width="2" fill="none"/>']
    if state == 'chip':
        o.append(f'<path d="M44 -60 L36 -50 L40 -41" fill="none" stroke="{DIRT}" stroke-width="4" stroke-linejoin="round" stroke-linecap="round"/>'
                 f'<ellipse cx="37" cy="-46" rx="5" ry="3" fill="{WATER}" stroke="{DIRT}" stroke-width="1.4"/>')
    if state == 'broken':
        o.append(f'<path d="M34 -80 L22 -70 L26 -58 L16 -50" stroke="{CRACK}" stroke-width="1.6" fill="none"/>')
    if state == 'black':
        o.append(f'<g fill="{BURN}" opacity="0.75"><path d="M-30 -86 Q-22 -76 -18 -60 Q-26 -64 -34 -80 Z"/>'
                 '<path d="M12 -60 Q22 -54 30 -44 Q18 -46 10 -54 Z"/><ellipse cx="-6" cy="-112" rx="9" ry="5"/></g>')
    if state == 'droppings':
        o.append(f'<g fill="{SALT}" stroke="{DUST}" stroke-width="1.2"><path d="M-16 -128 Q-24 -106 -14 -90 Q-6 -106 -8 -128 Z"/>'
                 '<path d="M-40 -84 Q-48 -62 -36 -50 Q-28 -64 -30 -82 Z"/><path d="M8 -128 Q8 -110 18 -96 Q22 -112 16 -128 Z"/>'
                 '<path d="M30 -70 Q26 -54 36 -44 Q40 -56 38 -70 Z"/></g>')
    if binding == 'tight':
        for side in (-1, 1):
            for i in range(6):
                x = side * (24 + i * 4.2)
                o.append(f'<path d="M{f(x - 1.6)} {GROOVE - 6} L{f(x + 1.6)} {GROOVE + 6}" stroke="{BIND}" stroke-width="2.2" stroke-linecap="round"/>')
    elif binding == 'loose':
        o.append(f'<path d="M24 {GROOVE - 5} q8 -14 16 -2 q6 10 14 -8 M-24 {GROOVE + 5} q-10 14 -18 0 q-6 -10 -16 6" '
                 f'stroke="{BIND}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
                 f'<path d="M-18 {GROOVE - 6} L-26 {GROOVE + 6}" stroke="{BIND}" stroke-width="2.2"/>')
    return ''.join(o)


def conductor(y, w=6, x0=-4, x1=204, sag=0):
    return f'<path d="M{f(x0)} {f(y + sag)} Q{f((x0 + x1) / 2)} {f(y - sag * 0.2)} {f(x1)} {f(y + sag)}" stroke="{WIRE}" stroke-width="{w}" fill="none"/>'


# --------------------------------------------------------------------------
# Round 1 — look: check the insulators from below before going up.
# --------------------------------------------------------------------------

ARM = 92
LS = 0.48


def look_stage(state):
    out = card_open('sky')
    out.append(sb.cloud(40, 26, 0.9, '#FFFFFF', 0.85))
    out.append(f'<rect x="0" y="{GY}" width="200" height="{H - GY}" fill="url(#ground)"/>')
    out.append(sb.tree_row(GY + 1, TREE))
    out.append(f'<rect x="{sb.PX - sb.PW / 2}" y="0" width="{sb.PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M96 {ARM} L204 {ARM - 6} L204 {ARM + 1} L96 {ARM + 7} Z" fill="url(#steelArm)"/>')
    for x, st in ((114, state), (186, 'ok')):
        y = ARM + (ARM - 6 - ARM) * (x - 96) / 108 + 1
        out.append(g(x, y, 0, LS, pin_ins(st)))
        out.append(conductor(y + GROOVE * LS, 2.4, -4, x, 0))
    out.append(sb.ladder_svg(sb.LAD_FOOT, sb.LAD_TOP))
    return out


def harness_on(hip, sh):
    """Full-body harness straps over the torso (tool/m2_board210_art.py)."""
    hx, hy = hip
    sx, sy = sh
    return (f'<path d="M{f(sx - 4)} {f(sy)} L{f(hx - 4)} {f(hy - 2)} M{f(sx + 3)} {f(sy)} L{f(hx + 4)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2" fill="none"/>'
            f'<path d="M{f(hx - 7)} {f(hy - 2)} L{f(hx + 7)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2.4"/>')


def binoculars(x, y):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate(-35)"><rect x="-1" y="-6" width="10" height="5" rx="1.6" fill="{sb.BOOT}"/>'
            f'<rect x="-1" y="1" width="10" height="5" rx="1.6" fill="{sb.BOOT}"/><rect x="8" y="-6" width="2" height="12" fill="{sb.RAIL}"/></g>')


def look_card(kind):
    state = {'broken': 'broken', 'black': 'black', 'lean': 'broken'}.get(kind, 'ok')
    out = look_stage(state)
    if kind in ('binoc', 'eye'):
        x = 64
        if kind == 'binoc':
            hands = ((x + 8, GY - 60), (x + 10, GY - 64))
            props = binoculars(x + 7, GY - 68)
            out.append(sb.standing(x, face=1, hands=hands, look=-24, props_front=props))
        else:
            out.append(sb.standing(x, face=1, hands=((x - 4, GY - 32), (x + 22, GY - 88)), look=-26))
        out.append(harness_on((x, GY - 30), (x + 1, GY - 56)))
    elif kind in ('broken', 'black'):
        out.append(sb.on_ladder(0.3))
        fa = sb.lad(0.3)
        hip = (fa[0] + 4 - 9, fa[1] - 1 - 26)
        out.append(harness_on(hip, (hip[0] + 5, hip[1] - 25)))
    else:  # lean: a hand on the pole under a failed insulator
        x = 126
        out.append(sb.standing(x, face=1, hands=((x + 13, GY - 70), (x + 14, GY - 56)), lean=2))
        out.append(harness_on((x, GY - 30), (x + 1, GY - 56)))
        out.append(spark(114, ARM - 32, 14))
        out.append(f'<path d="M{sb.PX - 4} {ARM + 14} l4 10 l-4 8 l4 10" stroke="{ARC}" stroke-width="2" fill="none"/>')
    if kind == 'broken':
        out.append(spark(114, ARM - 36, 9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — pin: a straight line's pin insulator, close up.
# --------------------------------------------------------------------------

PB = 190


def pin_card(kind):
    out = card_open('sky')
    out.append(sb.cloud(150, 30, 1.0, '#FFFFFF', 0.85))
    out.append(f'<rect x="-4" y="{PB}" width="208" height="18" fill="url(#steelArm)"/>')
    out.append(f'<rect x="-4" y="{PB + 18}" width="208" height="4" fill="{TOWER}"/>')
    state = {'chip': 'chip', 'bird': 'droppings'}.get(kind, 'ok')
    binding = 'loose' if kind == 'loose' else 'tight'
    out.append(g(100, PB, 0, 1.0, pin_ins(state, binding)))
    out.append(conductor(PB + GROOVE, 6))
    if kind == 'rain':
        out.append(rain())
        out.append(f'<g fill="{WATER}"><circle cx="46" cy="124" r="2.6"/><circle cx="154" cy="124" r="2.6"/>'
                   '<circle cx="32" cy="156" r="2.8"/><circle cx="168" cy="156" r="2.8"/><circle cx="31" cy="170" r="2"/><circle cx="169" cy="172" r="2"/></g>')
    if kind == 'loose':
        out.append(spark(124, PB + GROOVE, 16))
        out.append(f'<path d="M108 72 L114 82 L110 92 L116 104" stroke="{CRACK}" stroke-width="1.6" fill="none"/>')
    if kind == 'chip':
        out.append(rain(14, 5))
    if kind == 'bird':
        out.append(rain(18, 2))
        out.append(spark(64, 120, 16))
        out.append(f'<g fill="{WIRE}"><ellipse cx="170" cy="{PB + GROOVE - 12}" rx="9" ry="6"/><circle cx="178" cy="{PB + GROOVE - 18}" r="4"/>'
                   f'<path d="M181 {PB + GROOVE - 18} l6 1 l-6 2 Z"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — end: the end / turn of an LT line: shackle on a D-iron.
# --------------------------------------------------------------------------

EPX = 128  # the pole's centre
SHACKLES = (78, 138)


def shackle(x, y, sharp=False):
    """A shackle (reel) insulator on a D-iron: two steel straps from the pole
    and a bolt through the reel."""
    o = [f'<path d="M{EPX - 8} {y - 22} L{x - 4} {y - 20} L{x - 4} {y + 20} L{EPX - 8} {y + 22}" stroke="{PIN}" stroke-width="4" fill="none" stroke-linejoin="round"/>',
         f'<rect x="{x - 20}" y="{y - 24}" width="34" height="5" rx="1.5" fill="url(#steel)"/>',
         f'<rect x="{x - 20}" y="{y + 19}" width="34" height="5" rx="1.5" fill="url(#steel)"/>',
         f'<path d="M{x - 14} {y - 19} L{x + 6} {y - 19} L{x + 2} {y - 12} L{x + 2} {y + 12} L{x + 6} {y + 19} L{x - 14} {y + 19} L{x - 10} {y + 12} L{x - 10} {y - 12} Z" '
         f'fill="url(#porcelain)" stroke="{RIM}" stroke-width="1"/>']
    if sharp:
        o.append(f'<path d="M{x + 2} {y - 8} l4 3 l-4 3 l4 3 l-4 3 l4 3" stroke="#FFFFFF" stroke-width="1.4" fill="none"/>')
    return ''.join(o)


def end_stage():
    out = card_open('sky')
    out.append(sb.cloud(46, 24, 0.9, '#FFFFFF', 0.85))
    out.append(f'<rect x="0" y="196" width="200" height="24" fill="url(#ground)"/>')
    out.append(sb.tree_row(197, TREE))
    out.append(f'<rect x="{EPX - 9}" y="0" width="18" height="200" fill="url(#pole)"/>')
    return out


AY, ES = 120, 0.5


def end_card(kind):
    out = end_stage()
    if kind in ('dead', 'angle', 'sharp'):
        for i, y in enumerate(SHACKLES):
            x = 100
            out.append(shackle(x, y, sharp=kind == 'sharp' and i == 0))
            out.append(f'<path d="M-4 {y - 14} Q50 {y - 2} {x - 4} {y - 2}" stroke="{WIRE}" stroke-width="4" fill="none"/>'
                       f'<path d="M{x - 4} {y - 2} Q{x + 6} {y} {x - 4} {y + 4} Q{x - 20} {y + 6} {x - 34} {y + 1}" stroke="{WIRE}" stroke-width="3.4" fill="none"/>')
            if kind == 'angle':
                out.append(f'<path d="M{x - 4} {y + 4} Q{EPX + 30} {y + 16} 204 {y + 52}" stroke="{WIRE}" stroke-width="4" fill="none"/>')
        if kind == 'sharp':
            y = SHACKLES[0]
            out.append(f'<path d="M78 {y - 4} l4 -2 l4 2 l4 -2" stroke="{BIND}" stroke-width="1.8" fill="none"/>'
                       + spark(84, y - 4, 9))
    else:
        out.append(f'<rect x="40" y="{AY}" width="136" height="10" fill="url(#steelArm)"/>')
        for x in (74, 166):
            ang = -18
            out.append(g(x, AY, ang, ES, pin_ins('broken', 'tight')))
            hx = x - math.sin(math.radians(ang)) * GROOVE * ES
            hy = AY + GROOVE * ES * math.cos(math.radians(ang))
            out.append(f'<path d="M-4 {f(hy + 12)} Q{f(hx / 2)} {f(hy + 18)} {f(hx)} {f(hy)}" stroke="{WIRE}" stroke-width="3.4" fill="none"/>')
            if kind == 'pin_turn':
                out.append(f'<path d="M{f(hx)} {f(hy)} Q{f(hx + 30)} {f(hy + 26)} 204 {f(hy + 80)}" stroke="{WIRE}" stroke-width="3.4" fill="none"/>')
            out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9"><path d="M{f(hx - 10)} {f(hy - 8)} l-8 0"/><path d="M{f(hx - 10)} {f(hy - 2)} l-10 0"/></g>')
            out.append(spark(hx - 4, hy - 4, 11))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — disc: a string of discs at a tower.
# --------------------------------------------------------------------------

def disc(cx, cy, vertical=True, crack=False):
    """One disc; for a hanging (vertical) string the disc lies flat."""
    body = (f'<rect x="-3" y="-11" width="6" height="7" fill="url(#steel)"/>'
            f'<path d="M-24 2 Q-20 -8 0 -9 Q20 -8 24 2 Q0 8 -24 2 Z" fill="url(#porcelain)" stroke="{RIM}" stroke-width="1"/>'
            f'<path d="M-20 3 Q0 9 20 3" stroke="{RIM}" stroke-width="2.4" fill="none"/>')
    if crack:
        body += f'<path d="M-12 -5 L-8 -1 L-11 2 L-5 5" stroke="{CRACK}" stroke-width="1" fill="none"/>'
    return g(cx, cy, 0 if vertical else -90, 1.0, body)


def tower():
    o = [f'<rect x="0" y="196" width="200" height="24" fill="url(#ground)"/>', sb.tree_row(197, TREE)]
    # The tower's body on the left and its cross-arm along the top.
    o.append(f'<g stroke="{TOWER}" stroke-width="3" fill="none"><path d="M6 0 L6 200 M34 0 L34 200"/>'
             + ''.join(f'<path d="M6 {y} L34 {y + 24} M34 {y} L6 {y + 24}"/>' for y in range(0, 200, 24)) + '</g>')
    o.append(f'<g stroke="{TOWER}" stroke-width="3" fill="none"><path d="M34 14 L204 14 M34 30 L204 30"/>'
             + ''.join(f'<path d="M{x} 14 L{x + 16} 30 M{x + 16} 14 L{x} 30"/>' for x in range(34, 204, 16)) + '</g>')
    return ''.join(o)


def disc_card(kind):
    out = card_open('sky')
    out.append(sb.cloud(150, 60, 0.9, '#FFFFFF', 0.8))
    out.append(tower())
    n = {'one': 1, 'many': 8}.get(kind, 3)
    vertical = kind in ('sus3', 'many', 'crack')
    if vertical:
        x, y = 120, 40
        out.append(f'<rect x="{x - 2}" y="30" width="4" height="12" fill="{PIN}"/>')
        step = 17 if n > 3 else 19
        for i in range(n):
            out.append(disc(x, y + 10 + i * step, True, crack=kind == 'crack' and i == 1))
        yc = y + 10 + n * step
        out.append(f'<rect x="{x - 8}" y="{yc - 6}" width="16" height="8" rx="2" fill="url(#steel)"/>')
        out.append(conductor(yc, 4, -4, 204, 10))
        if kind == 'crack':
            out.append(spark(x - 6, y + 10 + step, 12))
    else:
        y, x = 110, 36
        out.append(f'<rect x="{x}" y="{y - 2}" width="12" height="4" fill="{PIN}"/>')
        step = 19
        for i in range(n):
            out.append(disc(x + 20 + i * step, y, False))
        xe = x + 20 + n * step
        out.append(f'<rect x="{xe - 8}" y="{y - 4}" width="16" height="8" rx="2" fill="url(#steel)"/>')
        out.append(f'<path d="M{xe + 8} {y} Q{(xe + 204) / 2} {y + 14} 204 {y + 10}" stroke="{WIRE}" stroke-width="4" fill="none"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — clean: insulators by the sea and a factory.
# --------------------------------------------------------------------------

CARM = 132


def polymer_ins():
    """A polymer (rubber) insulator: a rod with many small sheds."""
    o = [f'<rect x="-6" y="-42" width="12" height="42" fill="url(#steel)"/>',
         '<rect x="-7" y="-128" width="14" height="88" fill="url(#polymer)"/>']
    for i in range(7):
        y = -48 - i * 12
        o.append(f'<ellipse cx="0" cy="{y}" rx="{30 if i % 2 == 0 else 22}" ry="5" fill="url(#polymer)"/>')
    o.append('<rect x="-12" y="-136" width="24" height="10" rx="3" fill="url(#steel)"/>')
    return ''.join(o)


def coat(colour, op=0.9):
    """A patchy layer (salt or dust) over a pin insulator's sheds (local)."""
    return (f'<g fill="{colour}" opacity="{op}" stroke="{DUST}" stroke-width="1"><path d="M-54 -76 Q-30 -86 -10 -80 Q-20 -72 -50 -72 Z"/><path d="M14 -82 Q36 -84 52 -76 Q30 -72 16 -76 Z"/>'
            '<path d="M-66 -44 Q-40 -54 -20 -50 Q-30 -40 -64 -41 Z"/><path d="M20 -52 Q50 -54 66 -44 Q40 -40 22 -44 Z"/>'
            '<ellipse cx="-8" cy="-112" rx="10" ry="6"/><ellipse cx="12" cy="-100" rx="8" ry="5"/></g>')


def clean_stage():
    out = card_open('haze')
    out.append(f'<rect x="0" y="182" width="120" height="40" fill="{SEA}"/>')
    out.append(f'<path d="M0 190 q10 -3 20 0 t20 0 t20 0 t20 0 t20 0 t20 0" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.7"/>')
    out.append(f'<rect x="120" y="150" width="80" height="72" fill="{FACTORY}"/><rect x="168" y="96" width="12" height="56" fill="{FACTORY}"/>')
    out.append(f'<rect x="94" y="0" width="12" height="222" fill="url(#pole)"/>')
    out.append(f'<rect x="14" y="{CARM}" width="172" height="10" fill="url(#steelArm)"/>')
    return out


S5 = 0.6


def clean_card(kind):
    out = clean_stage()
    if kind == 'dust':
        out.append(f'<g fill="{SMOKE}" opacity="0.7"><ellipse cx="176" cy="86" rx="12" ry="8"/><ellipse cx="162" cy="70" rx="16" ry="9"/><ellipse cx="140" cy="58" rx="20" ry="10"/></g>')
    if kind == 'salt':
        out.append('<g fill="#FFFFFF" opacity="0.45"><rect x="0" y="40" width="200" height="16"/><rect x="0" y="150" width="200" height="12"/></g>')
    for x in (48, 152):
        if kind in ('polymer', 'nest'):
            body = polymer_ins()
        else:
            body = pin_ins('ok')
            if kind == 'salt':
                body += coat(SALT)
            elif kind == 'dust':
                body += coat(DUST)
        out.append(g(x, CARM, 0, S5, body))
    hy = CARM + GROOVE * S5
    out.append(f'<path d="M-4 {f(hy + 4)} L204 {f(hy + 4)}" stroke="{WIRE}" stroke-width="3.4"/>')
    if kind == 'wash':
        # The line is earthed: a clamp on the conductor, its lead down the pole.
        out.append(f'<rect x="112" y="{f(hy - 2)}" width="10" height="12" rx="2" fill="url(#steel)"/>'
                   f'<path d="M117 {f(hy + 10)} Q124 120 110 222" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
        # A gloved hand wiping the left insulator with a cloth.
        out.append(f'<path d="M-4 150 L30 112" stroke="{WIRE}" stroke-width="12" stroke-linecap="round"/>'
                   f'<path d="M22 104 Q36 96 44 108 Q38 122 24 118 Z" fill="{SALT}" stroke="{RIM}" stroke-width="1"/>')
    if kind in ('salt', 'dust'):
        if kind == 'dust':
            out.append(rain(18, 4))
        out.append(arc_down(152, hy + 4, 152 + 30, CARM))
    if kind == 'nest':
        out.append(rain(16, 6))
        out.append(f'<g stroke="{TWIG}" stroke-width="2" fill="none"><path d="M30 {CARM} q18 -12 36 0"/><path d="M28 {CARM - 2} q20 -16 40 -2"/>'
                   f'<path d="M32 {CARM - 6} l30 4 M34 {CARM - 1} l28 -6"/></g>'
                   f'<g fill="{SALT}"><path d="M40 {CARM + 10} q-2 10 2 18 q3 -8 1 -18 Z"/><path d="M58 {CARM + 10} q-2 8 1 14 q3 -6 1 -14 Z"/></g>')
        out.append(arc_down(48, hy + 4, 48 + 26, CARM))
    return card_close(out)


CARDS = {
    'look_binoc': look_card('binoc'),
    'look_eye': look_card('eye'),
    'look_broken': look_card('broken'),
    'look_black': look_card('black'),
    'look_lean': look_card('lean'),
    'pin_tight': pin_card('tight'),
    'pin_rain': pin_card('rain'),
    'pin_loose': pin_card('loose'),
    'pin_chip': pin_card('chip'),
    'pin_bird': pin_card('bird'),
    'end_dead': end_card('dead'),
    'end_angle': end_card('angle'),
    'end_pin_dead': end_card('pin_dead'),
    'end_pin_turn': end_card('pin_turn'),
    'end_sharp': end_card('sharp'),
    'disc_sus3': disc_card('sus3'),
    'disc_ten3': disc_card('ten3'),
    'disc_one': disc_card('one'),
    'disc_many': disc_card('many'),
    'disc_crack': disc_card('crack'),
    'clean_wash': clean_card('wash'),
    'clean_polymer': clean_card('polymer'),
    'clean_salt': clean_card('salt'),
    'clean_dust': clean_card('dust'),
    'clean_nest': clean_card('nest'),
}

# Safe cards and traps per round (mirrors learn_board_pack32.dart).
ROUNDS = {
    'look': (['look_binoc', 'look_eye'], ['look_broken', 'look_black', 'look_lean']),
    'pin': (['pin_tight', 'pin_rain'], ['pin_loose', 'pin_chip', 'pin_bird']),
    'end': (['end_dead', 'end_angle'], ['end_pin_dead', 'end_pin_turn', 'end_sharp']),
    'disc': (['disc_sus3', 'disc_ten3'], ['disc_one', 'disc_many', 'disc_crack']),
    'clean': (['clean_wash', 'clean_polymer'], ['clean_salt', 'clean_dust', 'clean_nest']),
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
