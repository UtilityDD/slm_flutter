"""Picture cards for the lesson 5.4 board ("ফিউজ বারবার উড়ে যাওয়ার কারণ: অস্থায়ী বনাম স্থায়ী ফল্ট").

python -I tool/m5_board54_art.py .

Writes assets/game/art/m5_board54/*.svg (200 x 220 scene cards, drawn edge to
edge, no words) for the picture board in learn_board_pack54.dart. Every card
shows only what a lineman would see; content follows lesson 5.4:

* where_*     — a DTR whose HT DO fuse keeps blowing: the HT line before it
                (a branch on the conductor, a cracked insulator), inside the
                tank (a cut-away winding with a scorched turn) or the LT side
                (a short at the consumer's service). Traps: searching the HT
                line only while the LT box flashes behind him, thick copper
                wound into the DO barrel, closing the DO again into a flash.
* transient_* — a span in a field: lightning, two conductors clashing in the
                wind, a bird across two conductors. Traps (permanent faults):
                a snapped conductor on the ground, a broken pin insulator,
                smoke from a DTR tank.
* blast_*     — the DO dropped open with scorch marks after a blast with arc:
                walking the line with binoculars, a new insulator in hand by
                the broken one. Traps: the rod lifting the same fuse into a
                flash, thick wire on the carrier, sitting under a tree.
* reblow_*    — four poles in a row: the middle span sagging far lower, a
                branch close to the conductors, him reading the line logbook.
                Traps: the rod on the DO with nothing checked, driving off in
                the jeep, closing into a burning branch.
* section_*   — the DTR with its LT distribution box: every LT fuse out on
                the tarp, one fuse going back, the megger on an outgoing way.
                Traps: all LT in and the DTR roaring (hands on his ears), all
                three fuses pushed in together, running with one fuse.

Each round's cards are one scene template with one thing changed, so no
colour, backdrop or highlight points at the safe card (no green glow, no red
warning marks): the generator asserts that in every hand the dealer can make
(one safe card + three traps) every colour and gradient the safe card draws
is drawn by a trap too, and the safe card's backdrop is on a trap. Invisible
shapes are ignored by the check, here and in test/learn_board_54_test.dart
(the same rules as tool/scan_board_art.py), so they can never satisfy it.
Paint the check can't follow (a mask, a filter, <use>, an image, a clip other
than the card's) is refused. Every worker wears orange rubber gloves on every
card (safe and trap alike), so a bare hand on a live LT box is never drawn.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board54_art.py <repo root>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board54')
W, H = 200, 220
GY = 184  # ground line

# Palette (shared by every template).
SKIN = '#A86E48'
SKIN_D = '#7C4A2D'
# Rubber gloves (the same orange as tool/scan_board_art.py): every hand is gloved.
GLOVE = '#EA580C'
GLOVE_S = '#9A3412'
HAIR = '#2A1E16'
PANTS = '#2A3442'
PANTS_D = '#1E2631'
BOOT = '#1C1F24'
WIRE = '#2B3138'
YELLOW = '#FBC02D'
RED = '#C62828'
WHITE = '#FFFFFF'
DARK = '#1E293B'
HANDLE = '#B45309'
HELMET_S = '#B45309'
BRIM = '#EAB308'
BRIM_S = '#A16207'
SHIRT_L = '#0E3352'
SHIRT_B = '#174A70'
LEAF = '#4E7A3A'
LEAF_D = '#3B5E2B'
BARK = '#6B4A2B'
PORC = '#ECE8DF'
PORC_S = '#9C968A'
COPPER = '#B8732E'
SCORCH = '#3B1F12'
SMOKE = '#4A5568'
FIN = '#56645C'
WALL = '#E7D3A8'
ROOF = '#A14D2A'
DROP = '#7FB8D8'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9C98E"/><stop offset="1" stop-color="#94A86A"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F7F76"/><stop offset="0.5" stop-color="#A9B8AE"/><stop offset="1" stop-color="#66756C"/></linearGradient>
  <linearGradient id="barrel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5B3A22"/><stop offset="0.5" stop-color="#8A5A36"/><stop offset="1" stop-color="#53351F"/></linearGradient>
  <linearGradient id="ltbox" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9AA4AD"/><stop offset="1" stop-color="#6B757E"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="helmetDome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FEF08A"/><stop offset="0.25" stop-color="#FACC15"/><stop offset="1" stop-color="#CA8A04"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEFF2"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F6EA6"/><stop offset="1" stop-color="#1F4F7C"/></linearGradient>
  <linearGradient id="car" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8E8E2"/><stop offset="1" stop-color="#B9B9B0"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.95"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.6"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def n(v):
    s = f'{v:.1f}'
    return s[:-2] if s.endswith('.0') else s


def make_card(body, back='url(#sky)'):
    return '\n'.join([
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
        DEFS,
        '<g clip-path="url(#card)">',
        f'<rect width="{W}" height="{H}" fill="{back}"/>',
        body,
        '</g>',
        '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>',
        '</svg>',
    ])


def ground():
    return (f'<rect x="0" y="{GY}" width="200" height="{H - GY}" fill="url(#ground)"/>'
            f'<path d="M0 {GY} L200 {GY}" stroke="{LEAF_D}" stroke-width="1.2" opacity="0.5"/>')


# =============================================================================
# The worker (one figure for every scene)
# =============================================================================

def head(x, y, s=1.0, face='calm', tilt=0):
    """His head with the helmet; [face]: calm, talk, tense, up."""
    g = [f'<g transform="translate({n(x)} {n(y)}) rotate({tilt}) scale({s})">']
    g.append(f'<rect x="-6" y="8" width="12" height="12" rx="3" fill="{SKIN_D}"/>')
    g.append(f'<ellipse cx="0" cy="0" rx="14" ry="16" fill="{SKIN}"/>')
    g.append(f'<path d="M-17 -4 Q-16 -26 0 -27 Q16 -26 17 -4 Z" fill="url(#helmetDome)" stroke="{HELMET_S}" stroke-width="1.4"/>')
    g.append(f'<path d="M-20 -4 Q0 2 20 -4 L19 0 Q0 6 -19 0 Z" fill="{BRIM}" stroke="{BRIM_S}" stroke-width="1"/>')
    g.append(f'<path d="M-12 0 Q-12 14 0 16 Q12 14 12 0" fill="none" stroke="{DARK}" stroke-width="1.8"/>')
    ey = 4 if face != 'up' else 1
    g.append(f'<circle cx="-5" cy="{ey}" r="1.8" fill="{HAIR}"/>')
    g.append(f'<circle cx="5" cy="{ey}" r="1.8" fill="{HAIR}"/>')
    if face == 'tense':
        g.append(f'<path d="M-9 {ey - 5} L-2 {ey - 3} M9 {ey - 5} L2 {ey - 3}" stroke="{HAIR}" stroke-width="1.6" stroke-linecap="round"/>')
        g.append(f'<path d="M-4 12 Q0 9 4 12" fill="none" stroke="{HAIR}" stroke-width="1.6" stroke-linecap="round"/>')
    elif face == 'talk':
        g.append(f'<ellipse cx="0" cy="11" rx="3" ry="2.2" fill="{HAIR}"/>')
    else:
        g.append(f'<path d="M-4 10 Q0 13 4 10" fill="none" stroke="{HAIR}" stroke-width="1.6" stroke-linecap="round"/>')
    g.append('</g>')
    return ''.join(g)


def limb(a, b, c, color, w):
    return f'<path d="M{n(a[0])} {n(a[1])} L{n(b[0])} {n(b[1])} L{n(c[0])} {n(c[1])}" stroke="{color}" stroke-width="{n(w)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'


def hand(p, r=4.2):
    """A gloved hand: he never touches the LT box or a rod bare-handed (গ্লাভস)."""
    return f'<circle cx="{n(p[0])}" cy="{n(p[1])}" r="{n(r * 1.1)}" fill="{GLOVE}" stroke="{GLOVE_S}" stroke-width="{n(max(0.6, r * 0.2))}"/>'


def worker(x, gy, s=1.0, pose='stand', face='calm', reach=1.0, facing=1, item=''):
    """Full figure, feet at ([x], [gy]), ~95 px tall at s=1; [facing] -1 mirrors him.
    pose: stand, walk, look (hand at brow, looking up), binos (binoculars up),
    rod (operating rod up to his left), reach (both hands forward to his right),
    hold (an item held at the chest: [item] is drawn around the hands at (0, 0)),
    ears (hands over his ears), sit (sitting on the ground, knees up)."""
    def P(dx, dy):
        return (x + dx * s, gy + dy * s)
    g = []
    hip, sh = P(0, -44), P(0, -74)
    if pose == 'sit':
        hip, sh = P(0, -12), P(-2, -42)
        g.append(limb(hip, P(14, -24), P(20, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(18, -20), P(24, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x + 16 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 21 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<path d="M{n(x - 15 * s)} {n(gy - 44 * s)} L{n(x + 11 * s)} {n(gy - 44 * s)} L{n(x + 9 * s)} {n(gy - 10 * s)} L{n(x - 13 * s)} {n(gy - 10 * s)} Z" fill="url(#shirt)"/>')
        g.append(limb(sh, P(10, -28), P(18, -24), SHIRT_B, 7 * s))
        g.append(hand(P(18, -24), 3.8 * s))
        g.append(head(x - 2 * s, gy - 58 * s, s * 0.78, face, -4))
        body = ''.join(g)
        return f'<g transform="translate({n(2 * x)} 0) scale(-1 1)">{body}</g>' if facing < 0 else body
    if pose == 'walk':
        g.append(limb(hip, P(-9, -22), P(-14, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(8, -22), P(14, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 21 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 9 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    else:
        g.append(limb(hip, P(-5, -22), P(-6, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(5, -22), P(6, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 13 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 1 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    g.append(f'<path d="M{n(x - 13 * s)} {n(gy - 76 * s)} L{n(x + 13 * s)} {n(gy - 76 * s)} L{n(x + 11 * s)} {n(gy - 42 * s)} L{n(x - 11 * s)} {n(gy - 42 * s)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{n(x)} {n(gy - 76 * s)} L{n(x)} {n(gy - 44 * s)}" stroke="{SHIRT_L}" stroke-width="1"/>')
    props = []
    hface = face
    tilt = 0
    if pose == 'rod':
        g.append(limb(sh, P(-10, -84), P(-18, -94), SHIRT_B, 7 * s))
        g.append(limb(sh, P(-4, -66), P(-12, -76), SHIRT_B, 7 * s))
        props.append(f'<path d="M{n(x - 4 * s)} {n(gy - 64 * s)} L{n(x - 4 * s - 40 * reach * s)} {n(gy - 64 * s - 86 * reach * s)}" stroke="{YELLOW}" stroke-width="{n(4 * s)}" stroke-linecap="round"/>')
        props.append(f'<path d="M{n(x - 4 * s)} {n(gy - 64 * s)} L{n(x - 14 * s)} {n(gy - 86 * s)}" stroke="{HANDLE}" stroke-width="{n(4.4 * s)}" stroke-linecap="round"/>')
        props.append(hand(P(-18, -94), 3.8 * s))
        props.append(hand(P(-12, -76), 3.8 * s))
        hface, tilt = 'up', -8
    elif pose == 'look':
        g.append(limb(sh, P(-10, -80), P(-4, -92), SHIRT_B, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), SHIRT_B, 7 * s))
        props.append(hand(P(12, -46), 3.8 * s))
        hface, tilt = 'up', -8
    elif pose == 'binos':
        g.append(limb(sh, P(-12, -74), P(-8, -90), SHIRT_B, 7 * s))
        g.append(limb(sh, P(12, -74), P(6, -90), SHIRT_B, 7 * s))
        hface, tilt = 'up', -8
    elif pose == 'reach':
        g.append(limb(sh, P(12, -70), P(26, -66), SHIRT_B, 7 * s))
        g.append(limb(sh, P(10, -64), P(26, -58), SHIRT_B, 7 * s))
        props.append(hand(P(26, -66), 3.8 * s))
        props.append(hand(P(26, -58), 3.8 * s))
    elif pose == 'hold':
        g.append(limb(sh, P(-12, -62), P(-2, -58), SHIRT_B, 7 * s))
        g.append(limb(sh, P(12, -62), P(4, -56), SHIRT_B, 7 * s))
        props.append(f'<g transform="translate({n(x)} {n(gy - 58 * s)}) scale({n(s)})">{item}</g>')
        props.append(hand(P(-2, -58), 3.8 * s))
        props.append(hand(P(4, -56), 3.8 * s))
    elif pose == 'ears':
        g.append(limb(sh, P(-16, -78), P(-10, -90), SHIRT_B, 7 * s))
        g.append(limb(sh, P(16, -78), P(10, -90), SHIRT_B, 7 * s))
        hface = 'tense'
    else:
        g.append(limb(sh, P(-10, -60), P(-12, -46), SHIRT_B, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), SHIRT_B, 7 * s))
        props.append(hand(P(-12, -46), 3.8 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    g.append(head(x, gy - 90 * s, s * 0.78, hface, tilt))
    if pose == 'look':
        g.append(hand(P(-4, -92), 3.8 * s))
    elif pose == 'binos':
        for bx in (-5, 3):
            g.append(f'<rect x="{n(x + bx * s)}" y="{n(gy - 100 * s)}" width="{n(5 * s)}" height="{n(9 * s)}" rx="1.5" fill="{DARK}" transform="rotate(-20 {n(x)} {n(gy - 96 * s)})"/>')
        g.append(hand(P(-8, -90), 3.8 * s))
        g.append(hand(P(6, -90), 3.8 * s))
    elif pose == 'ears':
        g.append(hand(P(-10, -90), 3.8 * s))
        g.append(hand(P(10, -90), 3.8 * s))
    body = ''.join(g + props)
    return f'<g transform="translate({n(2 * x)} 0) scale(-1 1)">{body}</g>' if facing < 0 else body


# =============================================================================
# Line parts
# =============================================================================

def pole(x, top, bot=GY + 6, w=7):
    return f'<rect x="{n(x - w / 2)}" y="{n(top)}" width="{n(w)}" height="{n(bot - top)}" fill="url(#pole)" stroke="#7A776F" stroke-width="0.8"/>'


def crossarm(x, y, half=30):
    return f'<rect x="{n(x - half)}" y="{n(y)}" width="{n(2 * half)}" height="5" rx="1" fill="url(#steelArm)"/>'


def insulator(x, y, state='ok'):
    """A pin insulator standing on a cross-arm whose top is at [y]; its
    conductor groove is at (x, y - 10). state: ok, cracked, broken."""
    g = []
    if state == 'broken':
        g.append(f'<path d="M{n(x - 6)} {n(y)} L{n(x - 5)} {n(y - 5)} L{n(x - 1)} {n(y - 3)} L{n(x + 2)} {n(y - 6)} L{n(x + 6)} {n(y)} Z" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.8"/>')
        g.append(f'<path d="M{n(x - 5)} {n(y - 5)} L{n(x - 1)} {n(y - 3)} L{n(x + 2)} {n(y - 6)}" stroke="{HAIR}" stroke-width="1" fill="none"/>')
        return ''.join(g)
    g.append(f'<path d="M{n(x - 6)} {n(y)} L{n(x - 4)} {n(y - 5)} L{n(x - 7)} {n(y - 6)} L{n(x - 3)} {n(y - 10)} L{n(x + 3)} {n(y - 10)} L{n(x + 7)} {n(y - 6)} L{n(x + 4)} {n(y - 5)} L{n(x + 6)} {n(y)} Z" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.8"/>')
    if state == 'cracked':
        g.append(f'<path d="M{n(x + 1)} {n(y - 10)} L{n(x - 1)} {n(y - 6)} L{n(x + 2)} {n(y - 3)} L{n(x)} {n(y)}" stroke="{HAIR}" stroke-width="1.1" fill="none"/>')
    return ''.join(g)


def shards(x, y):
    return (f'<path d="M{n(x)} {n(y)} l5 -3 l3 3 z M{n(x + 9)} {n(y + 1)} l4 -4 l2 4 z M{n(x - 7)} {n(y + 2)} l3 -3 l3 2 z" '
            f'fill="{PORC}" stroke="{PORC_S}" stroke-width="0.6"/>')


def wire(d, w=1.6, color=WIRE):
    return f'<path d="{d}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'


def span(x1, y1, x2, y2, sag=6, w=1.6):
    mx, my = (x1 + x2) / 2, max(y1, y2) + sag
    return wire(f'M{n(x1)} {n(y1)} Q{n(mx)} {n(my + sag)} {n(x2)} {n(y2)}', w)


def flash(x, y, r=14, bolt=True):
    g = [f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r)}" fill="url(#flash)"/>']
    if bolt:
        g.append(f'<path d="M{n(x - r * 0.5)} {n(y - r * 0.4)} L{n(x - r * 0.1)} {n(y + r * 0.05)} L{n(x - r * 0.3)} {n(y + r * 0.1)} L{n(x + r * 0.5)} {n(y + r * 0.45)}" '
                 f'stroke="{YELLOW}" stroke-width="1.8" fill="none" stroke-linejoin="round"/>')
    return ''.join(g)


def scorch(x, y, rx=7, ry=4):
    return f'<ellipse cx="{n(x)}" cy="{n(y)}" rx="{n(rx)}" ry="{n(ry)}" fill="{SCORCH}" opacity="0.75"/>'


def do_unit(x, y, state='closed'):
    """One drop-out fuse cutout hanging under a cross-arm at [y]. state:
    closed (barrel up in its contacts), open (barrel dropped, hanging),
    empty (barrel taken out)."""
    g = [f'<rect x="{n(x - 2.5)}" y="{n(y + 5)}" width="5" height="26" rx="2" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.7"/>']
    g.append(f'<rect x="{n(x + 2.5)}" y="{n(y + 7)}" width="4" height="3" fill="url(#steelArm)"/>')
    g.append(f'<rect x="{n(x + 2.5)}" y="{n(y + 26)}" width="4" height="3" fill="url(#steelArm)"/>')
    if state == 'closed':
        g.append(f'<rect x="{n(x + 4)}" y="{n(y + 9)}" width="4" height="18" rx="1.5" fill="url(#barrel)"/>')
    elif state == 'open':
        g.append(f'<rect x="{n(x + 4)}" y="{n(y + 27)}" width="4" height="18" rx="1.5" fill="url(#barrel)" transform="rotate(-28 {n(x + 6)} {n(y + 28)})"/>')
    return ''.join(g)


def do_set(x, y, state='closed', half=26):
    g = [crossarm(x, y, half)]
    for dx in (-18, -2, 14):
        g.append(do_unit(x + dx, y, state))
    return ''.join(g)


def carrier(x, y, rot=0, thick=False):
    """A DO fuse barrel (carrier) held or lying; thick: copper wound round it."""
    g = [f'<g transform="translate({n(x)} {n(y)}) rotate({rot})">']
    g.append('<rect x="-3" y="-12" width="6" height="24" rx="2" fill="url(#barrel)"/>')
    g.append('<rect x="-4" y="-14" width="8" height="3" rx="1" fill="url(#steelArm)"/>')
    g.append('<rect x="-4" y="11" width="8" height="3" rx="1" fill="url(#steelArm)"/>')
    if thick:
        for k in range(5):
            g.append(f'<path d="M-6 {-8 + k * 4} Q0 {-11 + k * 4} 6 {-8 + k * 4}" stroke="{COPPER}" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
        g.append(f'<path d="M6 10 Q12 16 9 22" stroke="{COPPER}" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
    g.append('</g>')
    return ''.join(g)


def dtr(x, y, cut=False, smoke=False, shake=False):
    """A pole-mounted distribution transformer, tank top-left at (x, y), 44 x 40."""
    g = [f'<rect x="{n(x - 4)}" y="{n(y + 40)}" width="52" height="5" rx="1" fill="url(#steelArm)"/>']
    if shake:
        for k in (-1, 1):
            g.append(f'<path d="M{n(x + (-7 if k < 0 else 51))} {n(y + 6)} q{n(-4 * k)} 6 0 12 q{n(4 * k)} 6 0 12 q{n(-4 * k)} 6 0 12" stroke="{WHITE}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    g.append(f'<rect x="{n(x)}" y="{n(y)}" width="44" height="40" rx="3" fill="url(#tank)" stroke="{FIN}" stroke-width="1"/>')
    for fx in range(6, 40, 6):
        g.append(f'<path d="M{n(x + fx)} {n(y + 6)} L{n(x + fx)} {n(y + 36)}" stroke="{FIN}" stroke-width="1.2"/>')
    g.append(f'<rect x="{n(x - 2)}" y="{n(y - 4)}" width="48" height="5" rx="2" fill="url(#steelArm)"/>')
    for bx in (8, 22, 36):
        g.append(f'<rect x="{n(x + bx - 2.5)}" y="{n(y - 14)}" width="5" height="10" rx="2" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.7"/>')
    g.append(f'<rect x="{n(x + 44)}" y="{n(y + 8)}" width="7" height="4" rx="1.5" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.7"/>')
    if cut:
        g.append(f'<rect x="{n(x + 9)}" y="{n(y + 8)}" width="26" height="26" rx="2" fill="{DARK}"/>')
        for k, cy in enumerate((13, 18, 23, 28)):
            col = SCORCH if k == 2 else COPPER
            g.append(f'<rect x="{n(x + 12)}" y="{n(y + cy)}" width="20" height="3.6" rx="1.8" fill="{col}"/>')
        g.append(f'<path d="M{n(x + 16)} {n(y + 21)} q3 -4 6 0 q3 -4 6 0" stroke="{SCORCH}" stroke-width="1.4" fill="none"/>')
    if smoke:
        g.append(f'<path d="M{n(x + 20)} {n(y - 4)} C{n(x + 8)} {n(y - 20)} {n(x + 34)} {n(y - 28)} {n(x + 22)} {n(y - 46)} C{n(x + 14)} {n(y - 58)} {n(x + 36)} {n(y - 64)} {n(x + 30)} {n(y - 80)}" stroke="{SMOKE}" stroke-width="10" fill="none" stroke-linecap="round" opacity="0.7"/>')
        g.append(f'<path d="M{n(x + 30)} {n(y - 2)} C{n(x + 44)} {n(y - 18)} {n(x + 26)} {n(y - 30)} {n(x + 40)} {n(y - 48)}" stroke="{SMOKE}" stroke-width="7" fill="none" stroke-linecap="round" opacity="0.55"/>')
    return ''.join(g)


def tree(x, base=GY, s=1.0, reach=None):
    """A roadside tree; [reach] = (x, y) a branch stretches to."""
    g = [f'<path d="M{n(x - 4 * s)} {n(base)} L{n(x - 3 * s)} {n(base - 46 * s)} L{n(x + 3 * s)} {n(base - 46 * s)} L{n(x + 4 * s)} {n(base)} Z" fill="{BARK}"/>']
    if reach:
        rx, ry = reach
        g.append(f'<path d="M{n(x)} {n(base - 40 * s)} Q{n((x + rx) / 2)} {n(min(ry, base - 40 * s) - 8)} {n(rx)} {n(ry)}" stroke="{BARK}" stroke-width="{n(3 * s)}" fill="none" stroke-linecap="round"/>')
        g.append(f'<circle cx="{n(rx)}" cy="{n(ry + 3)}" r="{n(7 * s)}" fill="{LEAF}"/>')
        g.append(f'<circle cx="{n(rx - 6 * s)}" cy="{n(ry + 6)}" r="{n(5 * s)}" fill="{LEAF_D}"/>')
    for cx, cy, r, c in ((0, -58, 22, LEAF_D), (-14, -48, 16, LEAF), (14, -50, 17, LEAF), (0, -70, 15, LEAF)):
        g.append(f'<circle cx="{n(x + cx * s)}" cy="{n(base + cy * s)}" r="{n(r * s)}" fill="{c}"/>')
    return ''.join(g)


def house(x, gy=GY):
    return ''.join([
        f'<rect x="{n(x - 18)}" y="{n(gy - 30)}" width="36" height="30" fill="{WALL}"/>',
        f'<path d="M{n(x - 24)} {n(gy - 28)} L{n(x)} {n(gy - 48)} L{n(x + 24)} {n(gy - 28)} Z" fill="{ROOF}"/>',
        f'<rect x="{n(x - 5)}" y="{n(gy - 16)}" width="10" height="16" fill="{BARK}"/>',
        f'<rect x="{n(x + 8)}" y="{n(gy - 22)}" width="7" height="7" fill="{PANTS}"/>',
    ])


def ltbox(x, y, ways=('in', 'in', 'in')):
    """The LT distribution box (open door) with three outgoing fuse ways,
    box top-left (x, y), 46 x 32; a way is 'in' (fuse in) or 'out' (empty)."""
    g = [f'<rect x="{n(x)}" y="{n(y)}" width="46" height="32" rx="2" fill="url(#ltbox)" stroke="{FIN}" stroke-width="1"/>']
    for k, state in enumerate(ways):
        sx = x + 6 + k * 13
        g.append(f'<rect x="{n(sx)}" y="{n(y + 6)}" width="8" height="20" rx="1" fill="{DARK}"/>')
        if state == 'in':
            g.append(f'<rect x="{n(sx - 1)}" y="{n(y + 8)}" width="10" height="16" rx="2" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.6"/>')
            g.append(f'<rect x="{n(sx + 1)}" y="{n(y + 13)}" width="6" height="6" rx="1" fill="{RED}"/>')
    # outgoing cables down out of the box
    for k in range(3):
        sx = x + 10 + k * 13
        g.append(wire(f'M{n(sx)} {n(y + 32)} L{n(sx)} {n(y + 40)} Q{n(sx)} {n(GY - 4)} {n(sx + (k - 1) * 40)} {n(GY + 8)}', 2.2, PANTS_D))
    return ''.join(g)


def lt_fuse(x, y, rot=0):
    """One LT fuse carrier lying or held (porcelain with its red grip)."""
    return (f'<g transform="translate({n(x)} {n(y)}) rotate({rot})">'
            f'<rect x="-5" y="-8" width="10" height="16" rx="2" fill="{PORC}" stroke="{PORC_S}" stroke-width="0.6"/>'
            f'<rect x="-3" y="-3" width="6" height="6" rx="1" fill="{RED}"/></g>')


def tarp(x=8, w=64):
    return f'<rect x="{n(x)}" y="{n(GY + 8)}" width="{n(w)}" height="14" rx="2" fill="url(#tarp)"/>'


def bird(x, y):
    return (f'<path d="M{n(x - 9)} {n(y)} Q{n(x - 2)} {n(y - 9)} {n(x + 6)} {n(y - 4)} Q{n(x + 9)} {n(y - 7)} {n(x + 12)} {n(y - 5)} L{n(x + 8)} {n(y - 2)} Q{n(x + 4)} {n(y + 5)} {n(x - 9)} {n(y)} Z" fill="{HAIR}"/>'
            f'<path d="M{n(x + 12)} {n(y - 5)} l4 1 l-4 1 z" fill="{BRIM}"/>'
            f'<path d="M{n(x - 3)} {n(y + 2)} L{n(x - 3)} {n(y + 7)} M{n(x + 3)} {n(y + 1)} L{n(x + 3)} {n(y + 6)}" stroke="{HAIR}" stroke-width="1"/>')


def cloud(x, y, s=1.0, color=SMOKE):
    return ''.join(f'<ellipse cx="{n(x + dx * s)}" cy="{n(y + dy * s)}" rx="{n(rx * s)}" ry="{n(ry * s)}" fill="{color}"/>'
                   for dx, dy, rx, ry in ((0, 0, 30, 14), (-22, 6, 18, 10), (22, 6, 20, 11), (4, -10, 18, 12)))


def bolt(points):
    d = 'M' + ' L'.join(f'{n(px)} {n(py)}' for px, py in points)
    return (f'<path d="{d}" stroke="{WHITE}" stroke-width="5" fill="none" stroke-linejoin="round" opacity="0.7"/>'
            f'<path d="{d}" stroke="{YELLOW}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>')


def wind(x, y):
    return ''.join(f'<path d="M{n(x)} {n(y + k * 9)} q12 -4 24 0 t24 0" stroke="{WHITE}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85"/>' for k in range(3))


def notebook():
    """The line logbook held open at (0, 0): ruled pages, a cloud and a bolt doodled by past entries."""
    return (f'<rect x="-18" y="-14" width="17" height="22" rx="1" fill="url(#paper)" stroke="{PORC_S}" stroke-width="0.6" transform="rotate(-6)"/>'
            f'<rect x="1" y="-14" width="17" height="22" rx="1" fill="url(#paper)" stroke="{PORC_S}" stroke-width="0.6" transform="rotate(6)"/>'
            f'<path d="M-15 -8 L-4 -9 M-15 -4 L-4 -5 M-15 0 L-4 -1 M4 -9 L15 -8 M4 -5 L15 -4" stroke="{DARK}" stroke-width="0.8"/>'
            f'<path d="M5 1 q2 -3 5 -1 q3 -1 4 2 z" fill="{DARK}"/><path d="M9 3 l-1 3 l2 -1 l-1 3" stroke="{DARK}" stroke-width="0.8" fill="none"/>')


def docket(x, y):
    return f'<rect x="{n(x)}" y="{n(y)}" width="7" height="9" rx="0.8" fill="url(#paper)" stroke="{PORC_S}" stroke-width="0.5"/>'


def jeep(x, gy=GY):
    return ''.join([
        f'<path d="M{n(x - 34)} {n(gy - 8)} L{n(x - 34)} {n(gy - 26)} L{n(x - 14)} {n(gy - 28)} L{n(x - 6)} {n(gy - 44)} L{n(x + 24)} {n(gy - 44)} L{n(x + 30)} {n(gy - 28)} L{n(x + 36)} {n(gy - 26)} L{n(x + 36)} {n(gy - 8)} Z" fill="url(#car)" stroke="{FIN}" stroke-width="1"/>',
        f'<path d="M{n(x - 3)} {n(gy - 40)} L{n(x + 21)} {n(gy - 40)} L{n(x + 26)} {n(gy - 29)} L{n(x - 8)} {n(gy - 29)} Z" fill="{DROP}"/>',
        head(x + 10, gy - 34, 0.42, 'calm'),
        f'<circle cx="{n(x - 20)}" cy="{n(gy - 6)}" r="8" fill="{BOOT}"/><circle cx="{n(x + 22)}" cy="{n(gy - 6)}" r="8" fill="{BOOT}"/>',
        f'<circle cx="{n(x - 20)}" cy="{n(gy - 6)}" r="3" fill="url(#steelArm)"/><circle cx="{n(x + 22)}" cy="{n(gy - 6)}" r="3" fill="url(#steelArm)"/>',
        ''.join(f'<path d="M{n(x - 40 - k * 6)} {n(gy - 10 - k * 7)} l-12 0" stroke="{WALL}" stroke-width="2" stroke-linecap="round"/>' for k in range(3)),
    ])


def megger(x, y, to):
    """The insulation tester on the ground at (x, y), its leads to [to]."""
    tx, ty = to
    return ''.join([
        wire(f'M{n(x - 6)} {n(y - 2)} Q{n((x + tx) / 2 - 10)} {n(y + 10)} {n(tx)} {n(ty)}', 1.6, RED),
        wire(f'M{n(x + 6)} {n(y - 2)} Q{n((x + tx) / 2 + 6)} {n(y + 14)} {n(tx + 6)} {n(ty + 2)}', 1.6, DARK),
        f'<rect x="{n(x - 14)}" y="{n(y)}" width="28" height="18" rx="2" fill="{DARK}"/>',
        f'<rect x="{n(x - 10)}" y="{n(y + 3)}" width="13" height="9" rx="1" fill="{BRIM}"/>',
        f'<circle cx="{n(x + 8)}" cy="{n(y + 9)}" r="3" fill="{PORC}"/>',
    ])


def sweat(x, y):
    return ''.join(f'<path d="M{n(x + dx)} {n(y + dy)} q-2 4 0 5 q2 -1 0 -5 z" fill="{DROP}"/>' for dx, dy in ((0, 0), (7, 4), (-6, 6)))


def sound(x, y, k=1):
    return ''.join(f'<path d="M{n(x + k * r * 0.2)} {n(y - r)} q{n(k * r * 0.7)} {n(r)} 0 {n(2 * r)}" stroke="{WHITE}" stroke-width="2" fill="none" stroke-linecap="round"/>' for r in (6, 11, 16))


# =============================================================================
# Round 1 — where can the fault be? (HT line · inside the DTR · LT side)
# =============================================================================

def where_card(kind):
    """The HT line from the left onto the DTR structure (DO set, tank, LT box),
    the LT service to a house on the right."""
    g = [ground(), house(176), tree(64, s=0.9, reach=(58, 50) if kind == 'htline' else None)]
    g.append(pole(30, 44))
    g.append(crossarm(30, 50, 22))
    for ix in (12, 30, 48):
        g.append(insulator(ix, 50, 'cracked' if (kind == 'htline' and ix == 48) else 'ok'))
    g.append(pole(120, 38))
    do_state = 'empty' if kind == 'thick' else ('open' if kind == 'burn' else 'closed')
    g.append(do_set(120, 46, do_state))
    for k, ix in enumerate((12, 30, 48)):
        dx = (-18, -2, 14)[k]
        g.append(wire(f'M0 {n(42 + k)} L{n(ix)} 40'))
        g.append(span(ix, 40, 120 + dx + 4, 53, 4))
        g.append(wire(f'M{n(120 + dx + 4)} 77 L{n(106 + k * 14)} 84', 1.4))
    g.append(dtr(98, 92, cut=kind == 'tank'))
    g.append(ltbox(97, 146))
    # LT service from the DTR's LT bushing to the house
    g.append(span(151, 102, 160, 150, 3, 1.4))
    if kind == 'htline':
        g.append(worker(70, GY, 0.6, 'look'))
    elif kind == 'tank':
        g.append(worker(78, GY, 0.6, 'stand', 'tense'))
    elif kind == 'lt':
        g.append(flash(160, 150, 15))
        g.append(scorch(160, 154, 5, 3))
        g.append(worker(140, GY, 0.6, 'look', facing=1))
    elif kind == 'htonly':
        g.append(flash(118, 160, 16))
        g.append(worker(26, GY, 0.6, 'binos', facing=-1))
    elif kind == 'thick':
        g.append(worker(80, GY, 0.6, 'hold', item=carrier(0, 0, 10, thick=True)))
    elif kind == 'burn':
        g.append(flash(122, 62, 18))
        g.append(scorch(122, 60))
        g.append(worker(84, GY, 0.6, 'rod', reach=1.5, facing=-1))
    return ''.join(g)


# =============================================================================
# Round 2 — what makes a transient fault? (a span in a field)
# =============================================================================

def transient_card(kind):
    g = [ground()]
    if kind == 'lightning':
        g.append(cloud(150, 18, 1.1))
    g.append(pole(24, 50))
    g.append(crossarm(24, 56, 22))
    right_pole = kind != 'smoke'
    g.append(pole(176, 50))
    g.append(crossarm(176, 56, 22))
    ys = (46, 46, 46)
    left = (8, 24, 40)
    right = (160, 176, 192)
    for k in range(3):
        g.append(insulator(left[k], 56))
        if right_pole:
            g.append(insulator(right[k], 56, 'broken' if (kind == 'insulator' and k == 1) else 'ok'))
    for k in range(3):
        x1, x2 = left[k], right[k]
        if kind == 'snapped' and k == 2:
            g.append(wire(f'M{n(x1)} 46 Q70 70 96 {GY}'))
            g.append(wire(f'M{n(x2)} 46 Q170 60 164 96'))
            g.append(flash(96, GY - 2, 14))
            continue
        if kind == 'clash' and k in (0, 1):
            mid = 92 if k == 0 else 84
            g.append(wire(f'M{n(x1)} 46 Q100 {mid + 26} {n(x2)} 46'))
            continue
        if kind == 'insulator' and k == 1:
            g.append(wire(f'M{n(x1)} 46 Q100 72 {n(x2)} 58'))
            continue
        g.append(wire(f'M{n(x1)} 46 Q100 {66 + k * 2} {n(x2)} 46'))
    if kind == 'clash':
        g.append(flash(100, 70, 14))
        g.append(wind(20, 112))
    elif kind == 'bird':
        g.append(flash(100, 66, 12, bolt=False))
        g.append(f'<g transform="translate(100 60) scale(1.7) translate(-100 -60)">{bird(100, 60)}</g>')
    elif kind == 'lightning':
        g.append(bolt([(150, 30), (138, 46), (146, 48), (128, 66)]))
        g.append(flash(128, 66, 12, bolt=False))
    elif kind == 'insulator':
        g.append(shards(168, GY + 10))
        g.append(scorch(176, 58, 5, 3))
    elif kind == 'smoke':
        g.append(dtr(148, 92, smoke=True))
        for k in range(3):
            g.append(wire(f'M{n(right[k])} 46 L{n(156 + k * 14)} 78', 1.4))
    g.append(worker(100, GY, 0.58, 'look'))
    return ''.join(g)


# =============================================================================
# Round 3 — a blast with arc at once: a permanent fault
# =============================================================================

def blast_card(kind):
    """The DO pole after the blast: scorched, the fuses hanging open."""
    g = [ground(), tree(26, s=0.85)]
    g.append(pole(140, 36))
    g.append(do_set(140, 44, 'closed' if kind == 'reclose' else 'open'))
    for k, dx in enumerate((-18, -2, 14)):
        g.append(span(0, 30 + k * 4, 140 + dx + 4, 51, 6))
        g.append(wire(f'M{n(140 + dx + 4)} 75 L{n(126 + k * 14)} 84', 1.4))
    g.append(dtr(118, 92))
    g.append(scorch(124, 70, 8, 5))
    g.append(scorch(152, 62, 6, 4))
    g.append(pole(64, 46))
    g.append(crossarm(64, 52, 22))
    for ix in (46, 64, 82):
        g.append(insulator(ix, 52, 'broken' if (kind == 'repair' and ix == 82) else 'ok'))
    if kind == 'patrol':
        g.append(worker(52, GY, 0.6, 'binos', facing=-1))
    elif kind == 'repair':
        g.append(shards(88, GY + 10))
        g.append(worker(98, GY, 0.6, 'hold', item=insulator(0, 6)))
    elif kind == 'reclose':
        g.append(flash(142, 62, 20))
        g.append(worker(104, GY, 0.6, 'rod', reach=1.54, facing=-1))
    elif kind == 'thick':
        g.append(worker(100, GY, 0.6, 'hold', item=carrier(0, 0, 10, thick=True)))
    elif kind == 'wait':
        g.append(worker(40, GY, 0.6, 'sit'))
    return ''.join(g)


# =============================================================================
# Round 4 — it held for hours, then blew: where to look
# =============================================================================

POLES4 = (16, 72, 128, 184)


def reblow_card(kind):
    g = [ground()]
    g.append(tree(160, s=1.0, reach=(150, 66) if kind in ('branch', 'burn') else None))
    for px in POLES4:
        g.append(pole(px, 52))
        g.append(crossarm(px, 58, 14))
        for dx in (-9, 9):
            g.append(insulator(px + dx, 58))
    for i in range(3):
        a, b = POLES4[i], POLES4[i + 1]
        sag = 30 if (kind == 'sag' and i == 1) else 6
        for dx in (-9, 9):
            g.append(span(a + dx, 48, b + dx, 48, sag))
    g.append(crossarm(16, 74, 14))
    for dx in (-8, 4):
        g.append(do_unit(16 + dx, 74, 'closed'))
    if kind == 'sag':
        g.append(worker(100, GY, 0.6, 'look'))
    elif kind == 'branch':
        g.append(worker(118, GY, 0.6, 'look'))
    elif kind == 'log':
        g.append(worker(100, GY, 0.62, 'hold', item=notebook()))
    elif kind == 'refit':
        g.append(worker(53, GY, 0.6, 'rod', reach=1.19))
        g.append(docket(57, GY - 34))  # the day's docket in his back pocket
    elif kind == 'leave':
        g.append(jeep(104))
    elif kind == 'burn':
        g.append(flash(150, 60, 16))
        g.append(scorch(150, 66, 5, 3))
        g.append(worker(53, GY, 0.6, 'rod', reach=1.19))
    return ''.join(g)


# =============================================================================
# Round 5 — sectionalizing: LT fuses out, back one at a time, then the megger
# =============================================================================

def section_card(kind):
    g = [ground(), tarp()]
    g.append(pole(100, 22))
    g.append(do_set(100, 30, 'closed'))
    for k, dx in enumerate((-18, -2, 14)):
        g.append(wire(f'M0 {n(16 + k * 3)} L{n(100 + dx + 4)} 37', 1.4))
        g.append(wire(f'M{n(100 + dx + 4)} 61 L{n(86 + k * 14)} 70', 1.4))
    g.append(dtr(78, 78, shake=kind == 'roar'))
    ways = {
        'ltout': ('out', 'out', 'out'),
        'onebyone': ('in', 'out', 'out'),
        'megger': ('out', 'out', 'out'),
        'roar': ('in', 'in', 'in'),
        'allback': ('out', 'out', 'out'),
        'guess': ('out', 'out', 'out'),
    }[kind]
    g.append(ltbox(77, 132, ways))
    on_tarp = {'ltout': 3, 'onebyone': 2, 'megger': 3, 'roar': 0, 'allback': 0, 'guess': 2}[kind]
    for k in range(on_tarp):
        g.append(lt_fuse(22 + k * 18, GY + 15, 90))
    if kind == 'ltout':
        g.append(worker(156, GY, 0.6, 'look'))
    elif kind == 'onebyone':
        g.append(worker(70, GY, 0.6, 'reach'))
        g.append(lt_fuse(100, 144))
    elif kind == 'megger':
        g.append(megger(150, GY - 2, (87, 172)))
        g.append(worker(176, GY, 0.6, 'stand'))
    elif kind == 'roar':
        g.append(sound(132, 96, 1))
        g.append(worker(156, GY, 0.6, 'ears'))
    elif kind == 'allback':
        g.append(worker(66, GY, 0.6, 'reach'))
        for k in range(3):
            g.append(lt_fuse(84 + k * 7, 142 + k * 3, -10 + k * 10))
    elif kind == 'guess':
        g.append(worker(160, GY, 0.6, 'walk', 'tense', facing=1))
        g.append(lt_fuse(172, 150, 20))
        g.append(sweat(150, 120))
    return ''.join(g)


CARDS = {
    # Round 1 — where (3 safe, 3 traps)
    'where_htline': make_card(where_card('htline')),
    'where_tank': make_card(where_card('tank')),
    'where_lt': make_card(where_card('lt')),
    'where_htonly': make_card(where_card('htonly')),
    'where_thick': make_card(where_card('thick')),
    'where_burn': make_card(where_card('burn')),
    # Round 2 — transient causes vs permanent faults
    'transient_lightning': make_card(transient_card('lightning')),
    'transient_clash': make_card(transient_card('clash')),
    'transient_bird': make_card(transient_card('bird')),
    'transient_snapped': make_card(transient_card('snapped')),
    'transient_insulator': make_card(transient_card('insulator')),
    'transient_smoke': make_card(transient_card('smoke')),
    # Round 3 — blast with arc at once
    'blast_patrol': make_card(blast_card('patrol')),
    'blast_repair': make_card(blast_card('repair')),
    'blast_reclose': make_card(blast_card('reclose')),
    'blast_thick': make_card(blast_card('thick')),
    'blast_wait': make_card(blast_card('wait')),
    # Round 4 — held for hours, then blew
    'reblow_sag': make_card(reblow_card('sag')),
    'reblow_branch': make_card(reblow_card('branch')),
    'reblow_log': make_card(reblow_card('log')),
    'reblow_refit': make_card(reblow_card('refit')),
    'reblow_leave': make_card(reblow_card('leave')),
    'reblow_burn': make_card(reblow_card('burn')),
    # Round 5 — sectionalizing
    'section_ltout': make_card(section_card('ltout')),
    'section_onebyone': make_card(section_card('onebyone')),
    'section_megger': make_card(section_card('megger')),
    'section_roar': make_card(section_card('roar')),
    'section_allback': make_card(section_card('allback')),
    'section_guess': make_card(section_card('guess')),
}

# Which cards are safe in each board round (mirrors learn_board_pack54.dart).
ROUNDS = {
    'where': ({'where_htline', 'where_tank', 'where_lt'}, {'where_htonly', 'where_thick', 'where_burn'}),
    'transient': ({'transient_lightning', 'transient_clash', 'transient_bird'},
                  {'transient_snapped', 'transient_insulator', 'transient_smoke'}),
    'blast': ({'blast_patrol', 'blast_repair'}, {'blast_reclose', 'blast_thick', 'blast_wait'}),
    'reblow': ({'reblow_sag', 'reblow_branch', 'reblow_log'}, {'reblow_refit', 'reblow_leave', 'reblow_burn'}),
    'section': ({'section_ltout', 'section_onebyone', 'section_megger'},
                {'section_roar', 'section_allback', 'section_guess'}),
}
HAND = 4

_ELEM = re.compile(r'<(/?)([\w:]+)\b([^>]*?)(/?)>')
_ATTR = re.compile(r'([\w:-]+)="([^"]*)"')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
_NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
_XFORM = re.compile(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)')
_PATH_TOK = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
# Containers: they paint nothing themselves.
_NO_PAINT = {'g', 'svg', 'a', 'switch'}
# Everything inside these is a definition, never painted where it stands.
_DEFS = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'}
# Inherited paint properties (a child without its own value takes its parent's).
_INHERIT = ('fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility')
_ID = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def _num(v, default=1.0):
    try:
        v = v.strip()
        return float(v[:-1]) / 100 if v.endswith('%') else float(v)
    except (AttributeError, TypeError, ValueError):
        return default


def _attrs(raw):
    """Attributes, with an inline style="k:v" winning over its attribute."""
    a = dict(_ATTR.findall(raw))
    for part in a.pop('style', '').split(';'):
        if ':' in part:
            k, v = part.split(':', 1)
            a[k.strip()] = v.strip()
    return a


def _mul(m, n):
    a1, b1, c1, d1, e1, f1 = m
    a2, b2, c2, d2, e2, f2 = n
    return (a1 * a2 + c1 * b2, b1 * a2 + d1 * b2, a1 * c2 + c1 * d2, b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1, b1 * e2 + d1 * f2 + f1)


def _transform(text):
    """The SVG transform list as one matrix (a, b, c, d, e, f)."""
    m = _ID
    for fn, args in _XFORM.findall(text or ''):
        v = [float(x) for x in _NUM.findall(args)]
        if fn == 'matrix' and len(v) == 6:
            t = tuple(v)
        elif fn == 'translate' and v:
            t = (1, 0, 0, 1, v[0], v[1] if len(v) > 1 else 0)
        elif fn == 'scale' and v:
            t = (v[0], 0, 0, v[1] if len(v) > 1 else v[0], 0, 0)
        elif fn == 'rotate' and v:
            r = math.radians(v[0])
            t = (math.cos(r), math.sin(r), -math.sin(r), math.cos(r), 0, 0)
            if len(v) >= 3:
                t = _mul(_mul((1, 0, 0, 1, v[1], v[2]), t), (1, 0, 0, 1, -v[1], -v[2]))
        elif fn == 'skewX' and v:
            t = (1, 0, math.tan(math.radians(v[0])), 1, 0, 0)
        elif fn == 'skewY' and v:
            t = (1, math.tan(math.radians(v[0])), 0, 1, 0, 0)
        else:
            continue
        m = _mul(m, t)
    return m


def _path_points(d):
    """Points whose box holds the whole path (end and control points; an arc
    adds a box of its size around its ends). None when the path can't be read."""
    toks = _PATH_TOK.findall(d)
    arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0}
    pts, i, cmd = [], 0, None
    x = y = sx = sy = 0.0
    last_c = None  # last control point, for S/T reflection
    try:
        while i < len(toks):
            if toks[i].isalpha():
                cmd = toks[i]
                i += 1
                if cmd in 'zZ':
                    x, y = sx, sy
                    pts.append((x, y))
                    last_c = None
                    continue
            if cmd is None:
                return None
            n = arity[cmd.lower()]
            v = [float(t) for t in toks[i:i + n]]
            if len(v) < n:
                return None
            i += n
            rel = cmd.islower()
            ox, oy = (x, y) if rel else (0.0, 0.0)
            c = cmd.lower()
            if c == 'h':
                x = v[0] + (x if rel else 0)
                pts.append((x, y))
                last_c = None
            elif c == 'v':
                y = v[0] + (y if rel else 0)
                pts.append((x, y))
                last_c = None
            elif c == 'a':
                ex, ey = v[5] + ox, v[6] + oy
                r = 2 * max(abs(v[0]), abs(v[1]), math.hypot(ex - x, ey - y))
                pts += [(x - r, y - r), (x + r, y + r), (ex, ey)]
                x, y = ex, ey
                last_c = None
            else:
                ctrl = [(v[k] + ox, v[k + 1] + oy) for k in range(0, n, 2)]
                if c in 'st':
                    ref = (2 * x - last_c[0], 2 * y - last_c[1]) if last_c else (x, y)
                    ctrl.insert(0, ref)
                pts += ctrl
                last_c = ctrl[-2] if len(ctrl) > 1 else None
                x, y = ctrl[-1]
                if c == 'm':
                    sx, sy = x, y
                    cmd = 'l' if rel else 'L'
    except (ValueError, KeyError, IndexError):
        return None
    return pts or None


def _local_points(tag, a):
    """Points whose box holds the shape in its own coordinates, or None."""
    n = lambda k: _num(a.get(k), 0.0)
    if tag == 'rect':
        return [(n('x'), n('y')), (n('x') + n('width'), n('y') + n('height'))]
    if tag == 'circle':
        return [(n('cx') - n('r'), n('cy') - n('r')), (n('cx') + n('r'), n('cy') + n('r'))]
    if tag == 'ellipse':
        return [(n('cx') - n('rx'), n('cy') - n('ry')), (n('cx') + n('rx'), n('cy') + n('ry'))]
    if tag == 'line':
        return [(n('x1'), n('y1')), (n('x2'), n('y2'))]
    if tag in ('polygon', 'polyline'):
        v = [float(t) for t in _NUM.findall(a.get('points', ''))]
        return list(zip(v[0::2], v[1::2])) or None
    if tag == 'path':
        return _path_points(a.get('d', ''))
    return None  # text and anything else: can't place it, so it counts


def _paint(tag, a):
    """(fill on, stroke on, can be seen) for one element with inherited values in a."""
    fill_on = a.get('fill') != 'none' and _num(a.get('fill-opacity')) > 0
    stroke_on = (a.get('stroke') not in (None, 'none') and _num(a.get('stroke-opacity')) > 0
                 and _num(a.get('stroke-width')) > 0)
    if tag == 'rect' and (_num(a.get('width'), 0) <= 0 or _num(a.get('height'), 0) <= 0):
        return fill_on, stroke_on, False
    if tag == 'circle' and _num(a.get('r'), 0) <= 0:
        return fill_on, stroke_on, False
    if tag == 'ellipse' and (_num(a.get('rx'), 0) <= 0 or _num(a.get('ry'), 0) <= 0):
        return fill_on, stroke_on, False
    if tag in ('path', 'polygon', 'polyline') and not (a.get('d') or a.get('points')):
        return fill_on, stroke_on, False
    if tag == 'line':
        fill_on = False  # a line has no inside
        if a.get('x1') == a.get('x2') and a.get('y1') == a.get('y2'):
            return fill_on, stroke_on, False
    return fill_on, stroke_on, fill_on or stroke_on


def painted(svg):
    """Yield (tag, attrs, fill on, stroke on) for every element that really puts
    paint on the 200 x 220 card. Skipped: definitions; anything with
    display:none, visibility:hidden or opacity 0, on itself or on any ancestor
    group; a transform that squashes it flat (scale(0)); zero-size shapes; no
    fill and no stroke; a shape wholly off the card."""
    root = re.search(r'<svg\b[^>]*viewBox="([^"]*)"', svg)
    vb = [float(t) for t in _NUM.findall(root.group(1))] if root else []
    x0, y0, cw, ch = vb if len(vb) == 4 else (0.0, 0.0, 200.0, 220.0)
    # One frame per open element: (tag, hidden, in defs, inherited attrs, matrix).
    stack = [('#doc', False, False, {}, _ID)]
    for close, tag, raw, self_close in _ELEM.findall(svg):
        if close:
            for k in range(len(stack) - 1, 0, -1):
                if stack[k][0] == tag:
                    del stack[k:]
                    break
            continue
        _, p_hidden, p_defs, p_inh, p_m = stack[-1]
        own = _attrs(raw)
        inh = dict(p_inh)
        for k in _INHERIT:
            if k in own:
                inh[k] = own[k]
        m = _mul(p_m, _transform(own.get('transform')))
        in_defs = p_defs or tag in _DEFS
        hidden = (p_hidden or own.get('display') == 'none' or _num(own.get('opacity')) <= 0
                  or abs(m[0] * m[3] - m[1] * m[2]) < 1e-9)
        if not (self_close or raw.rstrip().endswith('/')):
            stack.append((tag, hidden, in_defs, inh, m))
        if in_defs or hidden or tag in _NO_PAINT or inh.get('visibility') in ('hidden', 'collapse'):
            continue
        a = dict(own)
        a.update(inh)
        fill_on, stroke_on, seen = _paint(tag, a)
        if not seen:
            continue
        pts = _local_points(tag, a)
        if pts:
            pad = 2 * _num(a.get('stroke-width')) if stroke_on else 0.0  # miter joins reach 2 x width
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            box = [(min(xs) - pad, min(ys) - pad), (max(xs) + pad, min(ys) - pad),
                   (min(xs) - pad, max(ys) + pad), (max(xs) + pad, max(ys) + pad)]
            tx = [m[0] * px + m[2] * py + m[4] for px, py in box]
            ty = [m[1] * px + m[3] * py + m[5] for px, py in box]
            if max(tx) <= x0 or min(tx) >= x0 + cw or max(ty) <= y0 or min(ty) >= y0 + ch:
                continue
        yield tag, a, fill_on, stroke_on


def tokens(svg):
    """Colours and gradients the card really paints (see painted())."""
    out = set()
    for tag, a, fill_on, stroke_on in painted(svg):
        if fill_on and 'fill' in a:
            out.update(_TOKEN.findall(a['fill']))
        if stroke_on and 'stroke' in a:
            out.update(_TOKEN.findall(a['stroke']))
    return out


def visible(tag, attrs):
    """True when this one element, standing alone on the card, puts paint on it."""
    return any(True for _ in painted(f'<svg viewBox="0 0 200 220"><{tag} {attrs}/></svg>'))


def fairness_problems():
    tok = {k: tokens(v) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    problems = []
    for rnd, (safes, traps) in ROUNDS.items():
        for s in sorted(safes):
            for hand_ in itertools.combinations(sorted(traps), HAND - 1):
                if back[s] not in {back[t] for t in hand_}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand_}')
                only = tok[s] - set().union(*(tok[t] for t in hand_))
                if only:
                    problems.append(f'{rnd}: {s} with {hand_} draws {sorted(only)} alone')
        for name in safes | traps:
            if '<text' in CARDS[name]:
                problems.append(f'{rnd}: {name} has words in the art')
    for name, svg in CARDS.items():
        # Paint the check can't follow (a mask, a filter, a reused shape, an
        # image, a clip other than the card's own) could hide a token.
        clips = set(re.findall(r'clip-path="([^"]*)"', svg)) - {'url(#card)'}
        if clips or re.search(r'\b(mask|filter)="|<use\b|<image\b|<foreignObject\b', svg):
            problems.append(f'{name}: paint the fairness check cannot follow')
    return problems




if __name__ == '__main__':
    bad = fairness_problems()
    if bad:
        print('\n'.join('UNFAIR ' + p for p in bad))
        sys.exit(1)
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}; every hand fair')
