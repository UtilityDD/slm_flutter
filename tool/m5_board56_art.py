"""Picture cards for lesson 5.6 শেখা ("শর্ট সার্কিট এবং ওপেন সার্কিট ফল্ট: দুই ভিন্ন শত্রু").

python -I tool/m5_board56_art.py .

Writes assets/game/art/m5_board56/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 5.6 only:
  1. short: a short circuit is a low-resistance path between conductors —
     two wires slapping together, a fallen branch, a bird across two wires;
     its signs are a big arc flash, a bang and burn marks. The traps are
     open circuits: a jumper hanging open (bulb dark), a connector pulled
     apart, a pump with one phase off (single-phasing);
  2. open: the path is broken — a loose jumper, a connector apart, a blown
     fuse wire; power is cut with no flash. The traps show a flash, a
     blackened cable end after a bang, a branch across two wires;
  3. fallen: a broken wire on the ground is never safe and is treated as
     live (pro tip 1). The trainee keeps a child back / stops a cyclist; the
     traps lift it bare-handed, push it with dry bamboo (semi-conductor,
     pro tip 3) while a child watches beside him, join the two broken ends
     with a helper holding the far end (full system voltage across the gap,
     the myth) or hang laundry on the GI fence it lies on. Both safe cards
     show two people, so two traps do too: every hand holds a two-person trap;
  4. single: single-phasing — one of three phases cut, the three-phase pump
     motor groans or stalls (pro tip 2). Traps: all three healthy with water
     flowing, two phases touching with a flash, all three open;
  5. hidden: a high-resistance fault through dry wood — the fuse does not
     operate, a wisp of smoke, the houses still lit (pro tip 3). Traps: a big
     flash with the DO dropped (an ordinary short), a jumper or a joint open
     with the houses dark, a clean span. The tea stall's kettle steams on
     every card, so smoke alone is not the tell.
The smoke wisp, the burnt leaves and the motor's groan are illustrations.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one stage; the script checks every hand the dealer can make
(one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too, and a trap in that hand shows as many people as the
safe card (a lone two-person card would give the answer away).
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board56_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board56')
W, H = 200, 220
GY = 206          # where the people stand (foreground)
HZ = 150          # the horizon / back of the ground

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'          # boots, rubber gloves, tyres, burn marks
WIRE = '#2B3138'
COPPER = '#D9A066'
CIV_A = '#C8553D'         # villagers' clothes, the bicycle
CIV_B = '#E0A43A'
WALL = '#D9CBB0'
WALL_D = '#BFAF92'
ROOF = '#8A5A44'
WIN_DARK = '#3A4350'
WIN_LIT = '#FFE48A'
TRUNK = '#6B4A2E'
LEAF = '#4F8A3C'
LEAF_D = '#3C6E2E'
LEAF_DRY = '#B08A46'
BIRD = '#4A4F57'
FLASH = '#FFF4B0'
SMOKE = '#8E979E'
BAMBOO = '#C9A45C'
BAMBOO_D = '#9E7E3E'
BRICK = '#A8573E'
WATER = '#5DA9D6'
FUSEBOX = '#5C6B78'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3B4A6B"/><stop offset="0.7" stop-color="#8E7E8C"/><stop offset="1" stop-color="#C9A58A"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="lane" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8F8A7C"/><stop offset="1" stop-color="#6E6A5E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF1A0"/><stop offset="1" stop-color="#FFD24A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


STREET_ZOOM = (100, 60, 1.22)    # the street rounds are drawn a little closer
PUMP_ZOOM = (60, 60, 1.15)


def card_close(out, zoom=None):
    if zoom:
        cx, cy, k = zoom
        # Everything after the backdrop moves closer; the backdrop stays the card's first rect.
        out.insert(4, f'<g transform="translate({f(cx)} {f(cy)}) scale({k}) translate({f(-cx)} {f(-cy)})">')
        out.append('</g>')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# People (the figure of tool/m4_board41_art.py, with clothes as parameters).
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


def _hand(p, bare):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{SKIN if bare else BOOT}"/>'


LINEMAN = dict(body='url(#shirt)', arm_b=SHIRT_D, arm_f=SHIRT, legs=(PANTS_D, PANTS), helmet=True)


def civ(top, legs=None):
    return dict(body=top, arm_b=top, arm_f=top, legs=(legs or PANTS, legs or PANTS), helmet=False)


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, cloth=LINEMAN):
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face)
    kf = _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, cloth['legs'][0], 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, kf, ff, cloth['legs'][1], 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, cloth['arm_b'], 5.4))
    g.append(_hand(hb, bare))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="{cloth["body"]}"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>']
    if cloth['helmet']:
        hd += [f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
               f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    else:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="{HAIR}"/>')
    hd.append(f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, cloth['arm_f'], 5.4))
    g.append(_hand(hf, bare))
    return ''.join(g)


def person(x, hands_world, face=-1, look=0, bare=False, cloth=LINEMAN, s=1.3, gy=GY, stride=1.0):
    """A standing person at x (feet on gy), scaled s about the feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face * stride, gy - 1), (x + 6 * face * stride, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, cloth)
    return f'<g transform="translate({f(x)} {gy}) scale({s}) translate({f(-x)} -{gy})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def flash(x, y, s=1.0):
    pts = []
    for i in range(16):
        r = (15 if i % 2 == 0 else 6) * s
        a = i * math.pi / 8
        pts.append(f'{f(x + r * math.cos(a))},{f(y + r * math.sin(a))}')
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(26 * s)}" fill="url(#flash)"/>'
            f'<polygon points="{" ".join(pts)}" fill="{FLASH}"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(3.4 * s)}" fill="#FFFFFF"/>')


def bang(x, y, r=14):
    """Short burst strokes around a spot (the 'explosion-like sound')."""
    out = []
    for i in range(8):
        a = i * math.pi / 4 + 0.3
        out.append(f'<path d="M{f(x + r * math.cos(a))} {f(y + r * math.sin(a))} l{f(6 * math.cos(a))} {f(6 * math.sin(a))}" '
                   f'stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round"/>')
    return ''.join(out)


def smoke(x, y, s=1.0, faint=False):
    op = 0.45 if faint else 0.7
    return ''.join(f'<circle cx="{f(x + dx * s)}" cy="{f(y - dy * s)}" r="{f(r * s)}" fill="{SMOKE}" fill-opacity="{op}"/>'
                   for dx, dy, r in ((0, 0, 3.2), (3, 7, 4.2), (-1, 15, 5), (4, 24, 5.6)))


def burn(x, y, rx=5, ry=3):
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{rx}" ry="{ry}" fill="{BOOT}" fill-opacity="0.85"/>'


def motion(x, y, dx=0, dy=1, n=3, length=9):
    out = []
    for i in range(n):
        ox, oy = -dy * (i - (n - 1) / 2) * 5, dx * (i - (n - 1) / 2) * 5
        out.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}" stroke="{MOVE}" stroke-width="1.8" '
                   'stroke-linecap="round" stroke-opacity="0.9"/>')
    return ''.join(out)


def groan(x, y):
    """Jagged hum lines beside a struggling motor."""
    return ''.join(f'<path d="M{f(x + i * 7)} {f(y)} l3 -4 l3 8 l3 -8 l3 8 l3 -4" transform="rotate(-90 {f(x + i * 7)} {f(y)})" '
                   f'stroke="{MOVE}" stroke-width="1.5" fill="none" stroke-linejoin="round"/>' for i in range(3))


def pole(x, top=34, bottom=HZ + 8, arm=True):
    out = [f'<rect x="{f(x - 4)}" y="{top}" width="8" height="{bottom - top}" fill="url(#pole)"/>']
    if arm:
        out.append(f'<rect x="{f(x - 20)}" y="{top + 8}" width="40" height="5" rx="1" fill="url(#arm)"/>')
        for dx in (-16, 0, 16):
            yy = top + 1 if dx == 0 else top + 3
            out.append(f'<rect x="{f(x + dx - 2.5)}" y="{yy}" width="5" height="{top + 8 - yy}" rx="1.5" fill="url(#porcelain)"/>')
    return ''.join(out)


def house(x, w, h, lit=False, door=True):
    win = WIN_LIT if lit else WIN_DARK
    y = HZ + 6 - h
    out = [f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" fill="{WALL}"/>',
           f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="3" fill="{WALL_D}"/>',
           f'<path d="M{f(x - 4)} {f(y)} L{f(x + w / 2)} {f(y - 14)} L{f(x + w + 4)} {f(y)} Z" fill="{ROOF}"/>',
           f'<rect x="{f(x + 5)}" y="{f(y + 8)}" width="9" height="9" rx="1" fill="{win}"/>']
    if w > 34:
        out.append(f'<rect x="{f(x + w - 14)}" y="{f(y + 8)}" width="9" height="9" rx="1" fill="{win}"/>')
    if door:
        out.append(f'<rect x="{f(x + w / 2 - 4)}" y="{f(y + h - 14)}" width="8" height="14" fill="{ROOF}"/>')
    return ''.join(out)


def tree(x, y=HZ + 6, s=1.0, dry=True):
    out = [f'<path d="M{f(x)} {f(y)} L{f(x)} {f(y - 30 * s)}" stroke="{TRUNK}" stroke-width="{f(5 * s)}" stroke-linecap="round"/>',
           f'<circle cx="{f(x)}" cy="{f(y - 40 * s)}" r="{f(15 * s)}" fill="{LEAF_D}"/>',
           f'<circle cx="{f(x - 8 * s)}" cy="{f(y - 34 * s)}" r="{f(10 * s)}" fill="{LEAF}"/>',
           f'<circle cx="{f(x + 8 * s)}" cy="{f(y - 46 * s)}" r="{f(9 * s)}" fill="{LEAF}"/>']
    if dry:
        out.append(f'<circle cx="{f(x + 9 * s)}" cy="{f(y - 33 * s)}" r="{f(4 * s)}" fill="{LEAF_DRY}"/>')
    return ''.join(out)


def branch(x0, y0, x1, y1, leaves=True, dry=False):
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    out = [f'<path d="M{f(x0)} {f(y0)} Q{f(mx)} {f(my - 6)} {f(x1)} {f(y1)}" stroke="{TRUNK}" stroke-width="3.4" fill="none" stroke-linecap="round"/>',
           f'<path d="M{f(mx)} {f(my - 3)} l-6 -10 M{f(mx + 14)} {f(my)} l4 -9 M{f(mx - 14)} {f(my - 4)} l2 9" stroke="{TRUNK}" stroke-width="1.8" stroke-linecap="round"/>']
    if leaves:
        c = LEAF_DRY if dry else LEAF
        for lx, ly in ((mx - 6, my - 13), (mx + 18, my - 9), (mx - 12, my + 6), (x0 + 3, y0 - 3)):
            out.append(f'<ellipse cx="{f(lx)}" cy="{f(ly)}" rx="4.5" ry="2.6" fill="{c}"/>')
    return ''.join(out)


def bird(x, y, s=1.0, spread=False):
    """A crow: perched (wings folded) or spread across two wires."""
    if spread:
        return (f'<path d="M{f(x - 22 * s)} {f(y - 14 * s)} Q{f(x - 6 * s)} {f(y - 6 * s)} {f(x)} {f(y)} Q{f(x + 6 * s)} {f(y - 6 * s)} '
                f'{f(x + 22 * s)} {f(y - 14 * s)} Q{f(x + 6 * s)} {f(y + 2 * s)} {f(x)} {f(y + 6 * s)} Q{f(x - 6 * s)} {f(y + 2 * s)} Z" fill="{BIRD}"/>'
                f'<circle cx="{f(x)}" cy="{f(y - 3 * s)}" r="{f(3.4 * s)}" fill="{BIRD}"/>'
                f'<path d="M{f(x - 2 * s)} {f(y + 6 * s)} l0 {f(6 * s)} M{f(x + 2 * s)} {f(y + 6 * s)} l0 {f(6 * s)}" stroke="{BIRD}" stroke-width="1.2"/>')
    return (f'<ellipse cx="{f(x)}" cy="{f(y - 4 * s)}" rx="{f(5 * s)}" ry="{f(3.6 * s)}" fill="{BIRD}"/>'
            f'<circle cx="{f(x + 4 * s)}" cy="{f(y - 7 * s)}" r="{f(2.4 * s)}" fill="{BIRD}"/>'
            f'<path d="M{f(x - 4 * s)} {f(y - 4 * s)} l{f(-4 * s)} {f(2 * s)}" stroke="{BIRD}" stroke-width="{f(1.6 * s)}" stroke-linecap="round"/>')


def lamp(x, y, face=1):
    """A street lamp on a bracket; dark (the area has no power)."""
    return (f'<path d="M{f(x)} {f(y)} l{f(12 * face)} -3" stroke="{WIRE}" stroke-width="2" stroke-linecap="round"/>'
            f'<path d="M{f(x + 8 * face)} {f(y - 4)} l{f(9 * face)} 0 l{f(-2 * face)} 5 l{f(-6 * face)} 0 Z" fill="{WIRE}"/>'
            f'<ellipse cx="{f(x + 12.5 * face)}" cy="{f(y + 1.5)}" rx="2.6" ry="1.6" fill="{WIN_DARK}"/>')


def wire(d, w=2.2, color=WIRE):
    return f'<path d="{d}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'


def span(y, sag=6, x0=26, x1=174):
    return f'M{x0} {y} Q{f((x0 + x1) / 2)} {y + 2 * sag} {x1} {y}'


def sag_y(x, y, sag=6, x0=26, x1=174):
    t = (x - x0) / (x1 - x0)
    return y + 2 * sag * 2 * t * (1 - t)


def ground(fill='ground'):
    return f'<rect x="0" y="{HZ}" width="{W}" height="{H - HZ}" fill="url(#{fill})"/>'


# --------------------------------------------------------------------------
# Rounds 1, 2 and 5 — a village street: two poles, three wires.
# --------------------------------------------------------------------------

WY = (46, 56, 66)            # the three phases at the poles


def street_stage(lit=False, back='sky'):
    """[lit] lights both houses, or is a (left, right) pair."""
    lit_l, lit_r = lit if isinstance(lit, tuple) else (lit, lit)
    out = card_open(back)
    # The afternoon sun (the glow shares its gradient with an arc flash).
    out.append(f'<circle cx="150" cy="28" r="16" fill="url(#flash)"/><circle cx="150" cy="28" r="6.5" fill="{FLASH}"/>')
    out.append(ground())
    out.append(house(52, 30, 26, lit_l))
    out.append(house(118, 40, 30, lit_r))
    out.append(tree(186, s=0.9))
    out.append(pole(26))
    out.append(pole(174))
    out.append(lamp(26, 92))
    return out


def phase(i, sag=6):
    return span(WY[i], sag)


def all_wires(skip=(), sags=(6, 6, 6)):
    return ''.join(wire(phase(i, sags[i])) for i in range(3) if i not in skip)


def street_bird(out):
    # A crow perched on one wire only (harmless), near the right pole.
    out.append(bird(150, sag_y(150, WY[2]) - 1, 1.0))


def jumper_open(out, x, side=1):
    """One phase's jumper at the pole hanging open: the span stops short and
    its end dangles."""
    end = x + 14 * side
    out.append(wire(f'M{end} {WY[1] + 2} Q{f((end + 100) / 2)} {WY[1] + 12} {200 - end} {WY[1]}'))
    out.append(wire(f'M{end} {WY[1] + 2} q{f(4 * side)} 10 {f(-1 * side)} 24'))
    out.append(f'<circle cx="{f(end - side)}" cy="{WY[1] + 26}" r="1.8" fill="{COPPER}"/>')


def connector_apart(out, x=100, i=2, sleeve='url(#steel)'):
    y = sag_y(x, WY[i])
    out.append(wire(f'M26 {WY[i]} Q{f((26 + x - 6) / 2)} {f(y + 4)} {f(x - 6)} {f(y)}'))
    out.append(wire(f'M{f(x + 6)} {f(y)} Q{f((174 + x + 6) / 2)} {f(y + 4)} 174 {WY[i]}'))
    out.append(wire(f'M{f(x - 6)} {f(y)} q-1 9 -5 16'))
    out.append(wire(f'M{f(x + 6)} {f(y)} q2 10 7 15'))
    out.append(f'<rect x="{f(x - 13)}" y="{f(y + 13)}" width="9" height="4" rx="1.5" fill="{sleeve}" transform="rotate(-60 {f(x - 9)} {f(y + 15)})"/>')
    out.append(f'<circle cx="{f(x + 13)}" cy="{f(y + 15)}" r="1.8" fill="{COPPER}"/>')


def short_card(kind):
    out = street_stage()
    street_bird(out)
    if kind == 'slap':
        out.append(wire(phase(0, 12)))
        out.append(wire(phase(1, 1)))
        out.append(wire(phase(2)))
        out.append(flash(100, 57))
        out.append(motion(78, 40, 0, 1, 2, 7))
        out.append(motion(122, 40, 0, 1, 2, 7))
        out.append(burn(100, 59, 4, 2))
    elif kind == 'branch':
        out.append(all_wires())
        out.append(branch(64, 36, 128, 66))
        out.append(flash(98, 56, 0.9))
    elif kind == 'bird':
        out.append(all_wires())
        out.append(bird(96, sag_y(96, WY[1]) - 2, 1.0, spread=True))
        out.append(flash(116, sag_y(116, WY[0]) + 2, 0.7))
        out.append(burn(116, sag_y(116, WY[0]) + 1, 4, 2))
    elif kind == 'jumper':
        out.append(all_wires(skip=(1,)))
        jumper_open(out, 26, 1)
    elif kind == 'connector':
        out.append(all_wires(skip=(2,)))
        connector_apart(out, 104)
    elif kind == 'pump':
        # A pump room fed from the right pole: three drops, one hanging off.
        out.append(all_wires())
        out.append(f'<rect x="100" y="146" width="56" height="34" fill="{BRICK}"/>')
        out.append(f'<path d="M96 146 L128 134 L160 146 Z" fill="{ROOF}"/>')
        out.append(f'<rect x="110" y="158" width="20" height="14" rx="3" fill="url(#steel)"/>')
        out.append(f'<rect x="130" y="162" width="16" height="5" fill="{BOOT}"/>')
        out.append(wire('M170 70 Q156 104 146 142', 1.6))
        out.append(wire('M174 70 Q162 108 152 142', 1.6))
        out.append(wire('M178 70 Q172 96 164 112', 1.6))
        out.append(f'<circle cx="164" cy="113" r="1.6" fill="{COPPER}"/>')
    return card_close(out, STREET_ZOOM)


def open_card(kind):
    out = street_stage()
    # A service box on the near house wall (the fuse lives here).
    out.append(f'<rect x="136" y="134" width="12" height="14" rx="1.5" fill="{FUSEBOX}"/>')
    if kind == 'jumper':
        out.append(all_wires(skip=(1,)))
        jumper_open(out, 174, -1)
    elif kind == 'connector':
        out.append(all_wires(skip=(2,)))
        connector_apart(out, 92, sleeve=FUSEBOX)
    elif kind == 'fuse':
        out.append(all_wires())
        # The box door open, the fuse carrier out, its wire broken.
        out.append(f'<rect x="148" y="134" width="7" height="14" rx="1" fill="{FUSEBOX}"/>')
        out.append(f'<rect x="139" y="138" width="6" height="7" fill="{WIN_DARK}"/>')
        out.append(f'<rect x="126" y="144" width="20" height="7" rx="2" fill="url(#porcelain)"/>')
        out.append(f'<path d="M129 147.5 l5 -1 M138 148 l5 -1" stroke="{COPPER}" stroke-width="1.4" stroke-linecap="round"/>')
        out.append(person(116, ((127, 150), (133, 146)), face=1, look=6, gy=178, s=1.0))
    elif kind == 'touch':
        out.append(wire(phase(0, 1)))
        out.append(wire(phase(1, 1)))
        out.append(wire(phase(2, 12)))
        out.append(wire('M26 56 Q100 64 174 56'))
        out.append(flash(100, 61))
        out.append(burn(100, 62, 4, 2))
    elif kind == 'burnt':
        out.append(all_wires())
        # The service cable end blackened at the box after a bang.
        out.append(wire('M148 141 q8 2 10 14', 2.6, COPPER))
        out.append(burn(157, 155, 6, 4))
        out.append(burn(142, 140, 7, 6))
        out.append(smoke(156, 148, 0.8))
        out.append(bang(157, 152, 12))
        out.append(person(112, ((120, 160), (124, 156)), face=1, look=8, gy=178, s=1.0))
    elif kind == 'branch':
        out.append(all_wires())
        out.append(branch(140, 40, 76, 64))
        out.append(flash(104, 55, 0.9))
    return card_close(out, STREET_ZOOM)


def hidden_card(kind):
    # Open: houses dark. One joint open cuts one phase only, so the near house
    # (on another phase) stays lit; the far one, behind the stall, is dark.
    lit = (False, True) if kind == 'joint' else kind in ('branch', 'awning', 'clean')
    out = street_stage(lit=lit)
    # A tea stall with a bamboo-poled awning on the left (clear of the wires).
    out.append(f'<rect x="40" y="128" width="40" height="22" fill="{WALL_D}"/>')
    out.append(f'<path d="M36 128 L84 128 L90 116 L42 116 Z" fill="{CIV_B}"/>')
    out.append(f'<path d="M88 118 L88 150" stroke="{BAMBOO}" stroke-width="3" stroke-linecap="round"/>')
    out.append(f'<path d="M86 132 l4 0 M86 142 l4 0" stroke="{BAMBOO_D}" stroke-width="1.2"/>')
    # The stall's black kettle on its stove, steaming, on every card: a wisp of
    # smoke is not by itself the sign of the hidden short (where it rises is).
    out.append(f'<rect x="50" y="138" width="16" height="6" rx="1" fill="{BRICK}"/>')
    out.append(f'<path d="M52 138 q6 -9 12 0 Z" fill="{BOOT}"/>')
    out.append(smoke(58, 128, 0.45, faint=True))
    if kind == 'branch':
        out.append(all_wires())
        out.append(branch(196, 86, 128, sag_y(128, WY[2]) + 1, leaves=True, dry=True))
        out.append(smoke(130, sag_y(130, WY[2]) - 3, 0.7, faint=True))
        out.append(burn(130, sag_y(130, WY[2]) + 1, 3, 2))
    elif kind == 'awning':
        out.append(all_wires())
        # The stall's long bamboo pole leant up against the bottom wire.
        out.append(f'<path d="M64 150 L58 {f(sag_y(58, WY[2]) + 1)}" stroke="{BAMBOO}" stroke-width="3" stroke-linecap="round"/>')
        out.append(f'<path d="M61 120 l4 1 M59 100 l4 1" stroke="{BAMBOO_D}" stroke-width="1.2"/>')
        out.append(smoke(58, sag_y(58, WY[2]) - 3, 0.7, faint=True))
        out.append(burn(58, sag_y(58, WY[2]) + 1, 3, 2))
    elif kind == 'bigflash':
        out.append(all_wires())
        out.append(branch(196, 86, 128, sag_y(128, WY[2]) + 1, leaves=True))
        out.append(flash(128, sag_y(128, WY[2]), 1.2))
        out.append(smoke(132, sag_y(132, WY[2]) - 12, 0.8))
        # The DO fuse dropped open on the pole.
        out.append(f'<rect x="178" y="74" width="5" height="18" rx="2" fill="url(#steel)" transform="rotate(35 180 74)"/>')
        out.append(f'<rect x="176" y="70" width="8" height="4" fill="{BOOT}"/>')
    elif kind == 'open':
        out.append(all_wires(skip=(1,)))
        jumper_open(out, 26, 1)
    elif kind == 'joint':
        out.append(all_wires(skip=(2,)))
        connector_apart(out, 116)
    elif kind == 'clean':
        out.append(all_wires())
    return card_close(out, STREET_ZOOM)


# --------------------------------------------------------------------------
# Round 3 — fallen: a dark lane at dusk, a broken wire on the ground.
# --------------------------------------------------------------------------

WEND = (74, 176)            # the end of the wire lying on the lane


def fallen_stage():
    out = card_open('dusk')
    out.append(f'<rect x="0" y="{HZ - 14}" width="{W}" height="{H - HZ + 14}" fill="url(#lane)"/>')
    out.append(house(110, 44, 34))
    out.append(house(160, 34, 28))
    out.append(pole(22, top=30, bottom=HZ))
    out.append(lamp(22, 80))
    out.append(wire('M200 44 Q60 46 38 42', 2))      # the healthy phase
    return out


def fallen_wire(lift=None):
    """The broken wire: from the pole top down to the lane, its end lying at
    WEND, or lifted to [lift]."""
    if lift:
        return wire(f'M22 42 Q30 120 50 168 Q66 180 {f(lift[0])} {f(lift[1])}')
    return wire(f'M22 42 Q30 120 50 168 Q60 178 {WEND[0]} {WEND[1]}') + f'<circle cx="{WEND[0]}" cy="{WEND[1]}" r="1.8" fill="{COPPER}"/>'


def bicycle(x, y, face=-1):
    out = [f'<circle cx="{f(x - 13)}" cy="{f(y - 10)}" r="10" fill="none" stroke="{BOOT}" stroke-width="2.4"/>',
           f'<circle cx="{f(x + 13)}" cy="{f(y - 10)}" r="10" fill="none" stroke="{BOOT}" stroke-width="2.4"/>',
           f'<path d="M{f(x - 13)} {f(y - 10)} L{f(x - 2)} {f(y - 26)} L{f(x + 10)} {f(y - 26)} L{f(x + 13)} {f(y - 10)} M{f(x - 2)} {f(y - 26)} L{f(x)} {f(y - 10)} L{f(x - 13)} {f(y - 10)} '
           f'M{f(x - 13 * face)} {f(y - 10)} L{f(x - 9 * face)} {f(y - 32)}" stroke="{CIV_A}" stroke-width="2.4" fill="none" stroke-linejoin="round" stroke-linecap="round"/>']
    return ''.join(out)


def fallen_card(kind):
    out = fallen_stage()
    if kind == 'child':
        out.append(fallen_wire())
        # A child running toward the wire; the trainee steps in, arm across.
        out.append(person(126, ((116, 170), (112, 176)), face=-1, cloth=civ(CIV_A), s=0.9, stride=1.5))
        out.append(person(150, ((112, 156), (136, 172)), face=-1, look=-6))
    elif kind == 'cyclist':
        out.append(fallen_wire())
        out.append(bicycle(156, GY - 2))
        out.append(person(160, ((148, 172), (144, 172)), face=-1, cloth=civ(CIV_B), s=1.0, gy=GY - 16))
        # The trainee, in front of the bike, palm up: stop.
        out.append(person(114, ((134, 146), (126, 168)), face=1, look=-8))
    elif kind == 'bare':
        out.append(fallen_wire(lift=(118, 150)))
        out.append(f'<path d="M118 150 l-4 -3" stroke="{COPPER}" stroke-width="2" stroke-linecap="round"/>')
        out.append(person(126, ((118, 150), (114, 156)), face=-1, bare=True))
    elif kind == 'bamboo':
        out.append(fallen_wire())
        out.append(f'<path d="M150 150 L{WEND[0] + 2} {WEND[1] - 1}" stroke="{BAMBOO}" stroke-width="3" stroke-linecap="round"/>')
        out.append(f'<path d="M128 160 l2 3 M112 168 l2 3" stroke="{BAMBOO_D}" stroke-width="1.4"/>')
        out.append(person(156, ((146, 152), (138, 156)), face=-1, bare=True, cloth=civ(CIV_A, CIV_B)))
        # A child standing by, watching him push it.
        out.append(person(184, ((178, 186), (190, 186)), face=-1, look=-6, cloth=civ(CIV_B), s=0.9))
    elif kind == 'join':
        # Both broken ends, one in each bare hand, about to be twisted together;
        # a villager helps, holding the far end's wire in his bare hands.
        out.append(fallen_wire(lift=(108, 160)))
        out.append(wire('M200 60 Q170 130 150 168 Q140 176 128 160'))
        out.append(person(172, ((158, 152), (154, 160)), face=-1, bare=True, cloth=civ(CIV_B), s=1.15))
        out.append(f'<path d="M108 160 l5 -3 M128 160 l-5 -3" stroke="{COPPER}" stroke-width="2" stroke-linecap="round"/>')
        out.append(person(118, ((108, 160), (128, 160)), face=-1, bare=True))
    elif kind == 'fence':
        # A GI wire fence with the broken wire across it; laundry going on it.
        for px in (70, 110, 150):
            out.append(f'<rect x="{px - 2}" y="146" width="4" height="40" fill="url(#steel)"/>')
        for fy in (152, 164, 176):
            out.append(f'<path d="M62 {fy} L158 {fy}" stroke="{WIRE}" stroke-width="1.2"/>')
        out.append(wire('M22 42 Q30 110 60 150 Q76 152 92 152'))
        out.append(f'<rect x="114" y="152" width="12" height="14" fill="{CIV_B}"/>')
        out.append(f'<rect x="128" y="152" width="9" height="11" fill="{CIV_A}"/>')
        out.append(person(166, ((140, 150), (144, 154)), face=-1, bare=True, cloth=civ(CIV_A)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — single: a three-phase pump room fed from a pole.
# --------------------------------------------------------------------------

PH = (40, 48, 56)           # the three phases at the pole top


def pump_stage(water=False):
    out = card_open('sky')
    out.append(ground())
    out.append(tree(186, s=0.8))
    out.append(pole(30, top=30, bottom=HZ + 6))
    # The pump room.
    out.append(f'<rect x="96" y="110" width="76" height="54" fill="{BRICK}"/>')
    out.append(f'<path d="M90 110 L134 92 L178 110 Z" fill="{ROOF}"/>')
    out.append(f'<rect x="108" y="124" width="40" height="40" fill="{WIN_DARK}"/>')
    # Motor and pump inside, the outlet pipe to the field channel.
    out.append(f'<rect x="112" y="140" width="20" height="16" rx="3" fill="url(#steel)"/>')
    out.append(f'<rect x="132" y="146" width="10" height="6" fill="{WIRE}"/>')
    out.append(f'<rect x="148" y="170" width="52" height="10" fill="{SKIN_D}"/>')
    out.append(f'<rect x="138" y="164" width="14" height="6" rx="2" fill="url(#steel)"/>')
    if water:
        out.append(f'<rect x="150" y="172" width="50" height="6" fill="{WATER}"/>')
        out.append(f'<path d="M152 167 q6 2 8 7" stroke="{WATER}" stroke-width="3" fill="none" stroke-linecap="round"/>')
    return out


def drop(i, cut=False, at_pole=False):
    """Service drop of phase i from the pole to the pump room wall."""
    y0 = PH[i]
    x1, y1 = 100, 116 + i * 6
    if cut and at_pole:
        return (wire(f'M44 {y0 + 6} Q72 {y0 + 30} {x1} {y1}', 1.8)
                + wire(f'M44 {y0 + 6} q3 10 -2 22', 1.8) + f'<circle cx="42" cy="{y0 + 28}" r="1.6" fill="{COPPER}"/>')
    if cut:
        return (wire(f'M34 {y0} Q60 {y0 + 26} 84 {y1 - 4}', 1.8) + wire(f'M84 {y1 - 4} q4 12 -1 26', 1.8)
                + f'<circle cx="83" cy="{y1 + 22}" r="1.6" fill="{COPPER}"/>')
    return wire(f'M34 {y0} Q64 {y0 + 30} {x1} {y1}', 1.8)


def single_card(kind):
    out = pump_stage(water=(kind == 'allok'))
    if kind == 'onewire':
        out.append(drop(0) + drop(1, cut=True) + drop(2))
        out.append(groan(120, 136))
    elif kind == 'onejumper':
        out.append(drop(0) + drop(1, cut=True, at_pole=True) + drop(2))
        out.append(groan(120, 136))
    elif kind == 'allok':
        out.append(drop(0) + drop(1) + drop(2))
        out.append(motion(176, 176, 1, 0, 2, 6))
    elif kind == 'flash':
        out.append(wire('M34 40 Q58 66 70 70 Q86 80 100 116', 1.8))
        out.append(wire('M34 48 Q60 72 70 70 Q86 82 100 122', 1.8))
        out.append(drop(2))
        out.append(flash(70, 70, 0.9))
        out.append(burn(70, 71, 4, 2))
    elif kind == 'allopen':
        out.append(drop(0, True, True) + drop(1, True, True) + drop(2, True, True))
    return card_close(out, PUMP_ZOOM)


CARDS = {
    'short_slap': short_card('slap'),
    'short_branch': short_card('branch'),
    'short_bird': short_card('bird'),
    'short_jumper': short_card('jumper'),
    'short_connector': short_card('connector'),
    'short_pump': short_card('pump'),
    'open_jumper': open_card('jumper'),
    'open_connector': open_card('connector'),
    'open_fuse': open_card('fuse'),
    'open_touch': open_card('touch'),
    'open_burnt': open_card('burnt'),
    'open_branch': open_card('branch'),
    'fallen_child': fallen_card('child'),
    'fallen_cyclist': fallen_card('cyclist'),
    'fallen_bare': fallen_card('bare'),
    'fallen_bamboo': fallen_card('bamboo'),
    'fallen_join': fallen_card('join'),
    'fallen_fence': fallen_card('fence'),
    'single_onewire': single_card('onewire'),
    'single_onejumper': single_card('onejumper'),
    'single_allok': single_card('allok'),
    'single_flash': single_card('flash'),
    'single_allopen': single_card('allopen'),
    'hidden_branch': hidden_card('branch'),
    'hidden_awning': hidden_card('awning'),
    'hidden_bigflash': hidden_card('bigflash'),
    'hidden_open': hidden_card('open'),
    'hidden_clean': hidden_card('clean'),
    'hidden_joint': hidden_card('joint'),
}

# Safe cards and traps per round (mirrors learn_board_pack56.dart).
ROUNDS = {
    'short': (['short_slap', 'short_branch', 'short_bird'], ['short_jumper', 'short_connector', 'short_pump']),
    'open': (['open_jumper', 'open_connector', 'open_fuse'], ['open_touch', 'open_burnt', 'open_branch']),
    'fallen': (['fallen_child', 'fallen_cyclist'], ['fallen_bare', 'fallen_bamboo', 'fallen_join', 'fallen_fence']),
    'single': (['single_onewire', 'single_onejumper'], ['single_allok', 'single_flash', 'single_allopen']),
    'hidden': (['hidden_branch', 'hidden_awning'], ['hidden_bigflash', 'hidden_open', 'hidden_clean', 'hidden_joint']),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
# Every person's head is one skin-coloured circle of radius 7.
_HEAD = f'r="7" fill="{SKIN}"'


def figures(svg):
    return svg.count(_HEAD)


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
                if figures(CARDS[s]) not in {figures(CARDS[t]) for t in hand}:
                    problems.append(f'{rnd}: {s} is the only card with {figures(CARDS[s])} people in {hand}')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name in os.listdir(OUT):
        if name.endswith('.svg') and name[:-4] not in CARDS:
            os.remove(os.path.join(OUT, name))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
