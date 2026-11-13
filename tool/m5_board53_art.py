"""Picture cards for the Module 5 lesson 5.3 board ("সাধারণ ফল্ট: অপরাধীদের প্যারেড").

python -I tool/m5_board53_art.py .

Writes assets/game/art/m5_board53/*.svg (200 x 220 scene cards, drawn edge to
edge, no words) for learn_board_pack53.dart. Every card shows only what a
lineman would see; content follows lesson 5.3 (and the Module 5 rulings):

* type_*      — a branch on an 11 kV span: across two wires or across all
                three (phase-to-phase); traps: a branch from one wire down to
                the ground (phase-to-earth), a pin insulator with a black
                carbon track (an earth fault), a snapped wire hanging free
                (open circuit).
* branch_*    — a big branch on the line: the crew planning its removal from
                the ground, a whole tree cut up by the forest department's team
                (green shirts, cloth caps, a bow saw) while the lineman stands
                back,
                the conductor / insulators / pole looked over after removal;
                traps: one man yanking the branch off at once, the branch
                cleared and a call for charge, a strike mark on the bracket
                left behind.
* insulator_* — a cracked insulator on a dead, earthed pole (earth leads on
                every card): the new insulator fitted, the cross-arm checked
                first; traps: tape round the crack, the carbon track wiped,
                a new insulator on a split cross-arm.
* clamp_*     — a melted PG clamp (close-up, the tool tray on every card): a
                new connector, the conductor beside the burn checked for
                softness (shown as dark, kinked, splayed strands — ruling
                M5-15a: discolouration and softness, no bend-test claim), the
                discoloured soft length cut away; traps: the melted clamp
                re-tightened, a new clamp on a blackened soft end, snapped ends
                twisted by hand.
* evidence_*  — clues at the span: a burnt bird under the wire and a blood
                stain on it, a burst LA with its earth lead hanging, metal
                manja across two wires; traps: a live bird in a far tree, an
                intact LA with its lead bolted, a kite in a tree away from the
                wires.

Each round's cards are one scene template with one thing changed, so no
colour, backdrop or highlight points at the safe card (no green glow, no red
warning marks): the generator asserts that in every hand the dealer can make
(one safe card + three traps) every colour and gradient the safe card draws
is drawn by a trap too, and the safe card's backdrop is on a trap. Invisible
shapes are ignored by the check, here and in test/learn_board_53_test.dart,
so they can never satisfy it: zero size, no paint, opacity 0 / display none /
visibility hidden on the shape or on any group around it, a scale(0)
transform, or a shape wholly off the card. Paint the check can't follow (a
mask, a filter, <use>, an image, a clip other than the card's) is refused.
The check is the one in tool/scan_board_art.py.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board53_art.py <repo root>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board53')
W, H = 200, 220

# Palette (shared by every template).
SKIN = '#A86E48'
SKIN_D = '#7C4A2D'
HAIR = '#2A1E16'
PANTS = '#2A3442'
PANTS_D = '#1E2631'
BOOT = '#1C1F24'
WIRE = '#2B3138'
YELLOW = '#FBC02D'
WHITE = '#FFFFFF'
DARK = '#1E293B'
INK = '#0F172A'
HELMET_S = '#B45309'
BRIM = '#EAB308'
BRIM_S = '#A16207'
SHIRT_L = '#0E3352'
SHIRT_B = '#174A70'
BARK = '#6B4423'
BARK_D = '#4A2E17'
LEAF = '#4E7A3A'
LEAF_D = '#355A27'
ROPE = '#D6B26E'
COPPER = '#B8692E'
GLOVE = '#EA580C'
GLOVE_S = '#9A3412'
CHAR = '#1C1917'
BLOOD = '#7F1D1D'
KITE = '#DC2626'
MANJA = '#AEB6BF'
CLOTH = '#E2E8F0'
TAPE = '#111827'
PHONE = '#0B1220'
SCAR = '#E8D3A8'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BB377"/><stop offset="1" stop-color="#7C9558"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A3B1E"/><stop offset="0.5" stop-color="#B0643A"/><stop offset="1" stop-color="#6B3219"/></linearGradient>
  <linearGradient id="porcNew" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8F4826"/><stop offset="0.5" stop-color="#D88A55"/><stop offset="1" stop-color="#7E3D1F"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="helmetDome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FEF08A"/><stop offset="0.25" stop-color="#FACC15"/><stop offset="1" stop-color="#CA8A04"/></linearGradient>
  <linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E5E9EC"/><stop offset="0.5" stop-color="#AEB7BE"/><stop offset="1" stop-color="#7E878F"/></linearGradient>
  <linearGradient id="burnt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8A7A5C"/><stop offset="0.35" stop-color="#4A3B2A"/><stop offset="0.65" stop-color="#2B221A"/><stop offset="1" stop-color="#7A6A4E"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F6EA6"/><stop offset="1" stop-color="#1F4F7C"/></linearGradient>
  <linearGradient id="laBody" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5B6470"/><stop offset="0.5" stop-color="#9AA4AF"/><stop offset="1" stop-color="#525A65"/></linearGradient>
  <linearGradient id="canopy" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E8F45"/><stop offset="1" stop-color="#3D6630"/></linearGradient>
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


# =============================================================================
# The worker (one figure for every scene)
# =============================================================================

def head(x, y, s=1.0, face='calm', tilt=0, cap=None):
    """His head with the helmet; [face]: calm, talk, tense, up. [cap]: a
    cloth cap of that colour instead of the yellow helmet (another team)."""
    g = [f'<g transform="translate({n(x)} {n(y)}) rotate({tilt}) scale({s})">']
    g.append(f'<rect x="-6" y="8" width="12" height="12" rx="3" fill="{SKIN_D}"/>')
    g.append(f'<ellipse cx="0" cy="0" rx="14" ry="16" fill="{SKIN}"/>')
    if cap:
        g.append(f'<path d="M-15 -3 Q-14 -22 0 -23 Q14 -22 15 -3 Z" fill="{cap}"/>')
        g.append(f'<path d="M2 -6 L24 -3 L22 1 L2 -1 Z" fill="{BARK}"/>')
    else:
        g.append(f'<path d="M-17 -4 Q-16 -26 0 -27 Q16 -26 17 -4 Z" fill="url(#helmetDome)" stroke="{HELMET_S}" stroke-width="1.4"/>')
        g.append(f'<path d="M-20 -4 Q0 2 20 -4 L19 0 Q0 6 -19 0 Z" fill="{BRIM}" stroke="{BRIM_S}" stroke-width="1"/>')
    g.append(f'<path d="M-12 0 Q-12 14 0 16 Q12 14 12 0" fill="none" stroke="{DARK}" stroke-width="1.8"/>')
    ey = 1 if face == 'up' else 4
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
    return f'<circle cx="{n(p[0])}" cy="{n(p[1])}" r="{n(r)}" fill="{SKIN}"/>'


def glove_hand(p, r=4.6):
    return f'<circle cx="{n(p[0])}" cy="{n(p[1])}" r="{n(r)}" fill="{GLOVE}" stroke="{GLOVE_S}" stroke-width="1"/>'


def worker(x, gy, s=1.0, pose='stand', face='calm', walk=False, team=None):
    """Full figure, feet at ([x], [gy]), ~95 px tall at s=1.
    pose: stand, look (looks up, hand at brow), point (points up-left),
    phone (phone at his ear), pull (both hands up-left on a rope),
    saw (both hands forward-right, low, on a saw).
    [team]: (shirt, seam, cap) for a man from another team (the forest
    department) in place of the lineman's blue shirt and yellow helmet."""
    if team is None:
        shirt, seam, sleeve, cap = 'url(#shirt)', SHIRT_L, SHIRT_B, None
    else:
        shirt, seam, sleeve, cap = team[0], team[1], team[0], team[2]

    def P(dx, dy):
        return (x + dx * s, gy + dy * s)
    g = []
    hip, sh = P(0, -44), P(0, -74)
    if walk:
        g.append(limb(hip, P(-9, -22), P(-15, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(6, -22), P(12, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 22 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 7 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    elif pose == 'pull':
        g.append(limb(hip, P(6, -22), P(14, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(-4, -22), P(-8, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 15 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 9 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    else:
        g.append(limb(hip, P(-5, -22), P(-6, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(5, -22), P(6, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 13 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 1 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    lean = 6 if pose == 'pull' else 0
    g.append(f'<path d="M{n(x - 13 * s + lean * s)} {n(gy - 76 * s)} L{n(x + 13 * s + lean * s)} {n(gy - 76 * s)} L{n(x + 11 * s)} {n(gy - 42 * s)} L{n(x - 11 * s)} {n(gy - 42 * s)} Z" fill="{shirt}"/>')
    g.append(f'<path d="M{n(x + lean * s)} {n(gy - 76 * s)} L{n(x)} {n(gy - 44 * s)}" stroke="{seam}" stroke-width="1"/>')
    props = []
    if pose == 'look':
        g.append(limb(sh, P(-10, -80), P(-4, -92), sleeve, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), sleeve, 7 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    elif pose == 'point':
        g.append(limb(sh, P(-14, -86), P(-24, -100), sleeve, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), sleeve, 7 * s))
        props.append(hand(P(-24, -100), 3.8 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    elif pose == 'phone':
        g.append(limb(sh, P(12, -70), P(9, -88), sleeve, 7 * s))
        g.append(limb(sh, P(-10, -60), P(-12, -46), sleeve, 7 * s))
        props.append(hand(P(-12, -46), 3.8 * s))
    elif pose == 'pull':
        g.append(limb(P(lean, -74), P(-8, -86), P(-18, -96), sleeve, 7 * s))
        g.append(limb(P(lean, -74), P(-4, -80), P(-12, -88), sleeve, 7 * s))
    elif pose == 'saw':
        g.append(limb(sh, P(12, -64), P(25, -60), sleeve, 7 * s))
        g.append(limb(sh, P(8, -58), P(20, -52), sleeve, 7 * s))
        props.append(hand(P(25, -60), 3.8 * s))
        props.append(hand(P(20, -52), 3.8 * s))
    else:
        g.append(limb(sh, P(-10, -60), P(-12, -46), sleeve, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), sleeve, 7 * s))
        props.append(hand(P(-12, -46), 3.8 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    tilt = {'look': -8, 'point': -6, 'pull': -10}.get(pose, 0)
    hface = 'up' if pose in ('look', 'point') else ('tense' if pose == 'pull' else face)
    g.append(head(x + lean * s, gy - 90 * s, s * 0.78, hface, tilt, cap))
    if pose == 'look':
        g.append(hand(P(-4, -92), 3.8 * s))
    elif pose == 'phone':
        px, py = P(9, -92)
        g.append(f'<rect x="{n(px - 3 * s)}" y="{n(py - 7 * s)}" width="{n(7 * s)}" height="{n(13 * s)}" rx="1.5" fill="{PHONE}" stroke="#334155" stroke-width="0.8"/>')
        g.append(hand(P(10, -86), 3.8 * s))
    elif pose == 'pull':
        props.append(hand(P(-18, -96), 3.8 * s))
        props.append(hand(P(-12, -88), 3.8 * s))
    return ''.join(g + props)


# =============================================================================
# Line parts shared by the rounds
# =============================================================================

def ground(y=186):
    return (f'<rect x="0" y="{y}" width="200" height="{220 - y}" fill="url(#ground)"/>'
            f'<path d="M0 {y} L200 {y}" stroke="{LEAF_D}" stroke-width="1.4" opacity="0.7"/>')


def pole(x, top, w=12):
    return (f'<path d="M{n(x - w / 2 + 1)} {top} L{n(x + w / 2 - 1)} {top} L{n(x + w / 2 + 1)} 220 L{n(x - w / 2 - 1)} 220 Z" '
            f'fill="url(#pole)" stroke="#6F6C64" stroke-width="1"/>')


def pin_insulator(x, y, kind='ok', s=1.0):
    """A pin insulator, its top (the conductor's groove) at ([x], [y]).
    kind: ok, crack, track (black carbon track), new, bare (pin only)."""
    g = [f'<g transform="translate({n(x)} {n(y)}) scale({s})">']
    g.append(f'<rect x="-1.6" y="16" width="3.2" height="9" fill="url(#steelArm)"/>')
    if kind != 'bare':
        fill = 'url(#porcNew)' if kind == 'new' else 'url(#porcelain)'
        g.append(f'<path d="M-4 0 L4 0 L5 4 L10 6 L10 9 L6 10 L8 13 L8 16 L-8 16 L-8 13 L-6 10 L-10 9 L-10 6 L-5 4 Z" fill="{fill}" stroke="#4A2412" stroke-width="0.9"/>')
        g.append('<path d="M-2 3 L-2 14" stroke="#FFFFFF" stroke-width="1.2" opacity="0.45"/>')
        if kind == 'crack':
            g.append(f'<path d="M3 1 L1 6 L5 9 L2 15" fill="none" stroke="{HAIR}" stroke-width="1.3" stroke-linejoin="round"/>')
            g.append(f'<path d="M5 9 L9 8" stroke="{HAIR}" stroke-width="0.9"/>')
        elif kind == 'track':
            # a black carbon track burnt down the porcelain, top to bottom
            g.append(f'<ellipse cx="-1" cy="1.5" rx="4" ry="2.2" fill="{CHAR}"/>')
            g.append(f'<path d="M-1 1 Q-7 4 -6 7 Q-2 10 -7 12 Q-4 14 -5 17" fill="none" stroke="{CHAR}" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"/>')
            g.append(f'<path d="M2 3 Q5 6 3 9 Q1 12 4 16" fill="none" stroke="{CHAR}" stroke-width="1.8" stroke-linecap="round"/>')
            g.append(f'<path d="M-9 8 L-6 9 M-9 13 L-6 13" stroke="{CHAR}" stroke-width="1.6" stroke-linecap="round"/>')
    g.append('</g>')
    return ''.join(g)


def bracket(px, y, length=16, side=1, scar=False):
    """A short steel bracket off the pole at ([px], [y]) towards [side]."""
    x1 = px + side * length
    g = [f'<rect x="{n(min(px, x1))}" y="{n(y)}" width="{length}" height="5" rx="1" fill="url(#steelArm)"/>']
    if scar:
        # a fresh strike mark: the bracket bent down, a pale gouge torn in the pole
        g[0] = (f'<path d="M{n(px)} {n(y)} L{n(x1)} {n(y + 7)} L{n(x1)} {n(y + 12)} L{n(px)} {n(y + 5)} Z" '
                f'fill="url(#steelArm)"/>')
        g.append(f'<path d="M{n(px - 5)} {n(y - 8)} L{n(px + 4)} {n(y - 4)} L{n(px + 5)} {n(y + 16)} L{n(px - 4)} {n(y + 22)} L{n(px - 6)} {n(y + 6)} Z" '
                 f'fill="{SCAR}" stroke="{HAIR}" stroke-width="1"/>')
        g.append(f'<path d="M{n(px - 3)} {n(y - 4)} l3 7 l-2 6 l3 8 M{n(px + 2)} {n(y)} l-2 9" fill="none" stroke="{HAIR}" stroke-width="1.3"/>')
    return ''.join(g)


def span(px, ys, ends, tops=None, kinds=('ok', 'ok', 'ok'), snap=None, scar=False):
    """Vertical-formation span: pole at [px], three brackets at [ys] (to the
    right), wires from the insulator tops to the right edge at [ends].
    [snap]: the wire index that is broken (two hanging ends)."""
    g = []
    tops = tops or [y - 16 for y in ys]
    g.append(pole(px, 20))
    for i, (y, t) in enumerate(zip(ys, tops)):
        g.append(bracket(px, y, 18, 1, scar=scar and i == 1))
        g.append(pin_insulator(px + 14, t, kinds[i]))
    for i, (t, e) in enumerate(zip(tops, ends)):
        x0, y0 = px + 14, t + 1
        if snap == i:
            # broken at x ~ 128: both ends hang free in the air
            ym = y0 + (e - y0) * (128 - x0) / (200 - x0)
            g.append(f'<path d="M{x0} {n(y0)} Q{n(x0 + 56)} {n(ym + 6)} 124 {n(ym + 18)} Q118 {n(ym + 40)} 122 {n(ym + 64)}" fill="none" stroke="{WIRE}" stroke-width="2.2"/>')
            g.append(f'<path d="M200 {n(e)} Q170 {n(e + 6)} 146 {n(ym + 22)} Q140 {n(ym + 44)} 144 {n(ym + 70)}" fill="none" stroke="{WIRE}" stroke-width="2.2"/>')
            g.append(f'<path d="M120 {n(ym + 64)} l2 6 l3 -5 M142 {n(ym + 70)} l2 6 l3 -5" fill="none" stroke="{WIRE}" stroke-width="1.2"/>')
        else:
            g.append(f'<path d="M{x0} {n(y0)} Q{n((x0 + 200) / 2)} {n((y0 + e) / 2 + 7)} 200 {n(e)}" fill="none" stroke="{WIRE}" stroke-width="2.2"/>')
    return ''.join(g)


def wire_y(x, px, top, end):
    """Height of a span wire (see span()) at [x]."""
    x0, y0 = px + 14, top + 1
    t = (x - x0) / (200 - x0)
    cy = (y0 + end) / 2 + 7
    return (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy + t * t * end


def branch(x0, y0, x1, y1, w=5, leaves=True):
    """A broken-off branch from (x0, y0) to (x1, y1), twigs and leaves at the far end."""
    g = [f'<path d="M{n(x0)} {n(y0)} L{n(x1)} {n(y1)}" stroke="{BARK}" stroke-width="{w}" stroke-linecap="round"/>']
    dx, dy = x1 - x0, y1 - y0
    for t, side in ((0.35, 1), (0.55, -1), (0.75, 1)):
        bx, by = x0 + dx * t, y0 + dy * t
        tx, ty = bx + (-dy * 0.18 + dx * 0.12) * side, by + (dx * 0.18 + dy * 0.12) * side
        g.append(f'<path d="M{n(bx)} {n(by)} L{n(tx)} {n(ty)}" stroke="{BARK_D}" stroke-width="{n(w * 0.5)}" stroke-linecap="round"/>')
        if leaves:
            g.append(f'<ellipse cx="{n(tx)}" cy="{n(ty)}" rx="6" ry="3.4" fill="{LEAF}" transform="rotate({n(math.degrees(math.atan2(dy, dx)))} {n(tx)} {n(ty)})"/>')
    if leaves:
        for k, (ox, oy) in enumerate(((0, 0), (5, -5), (-4, 5))):
            g.append(f'<ellipse cx="{n(x1 + ox)}" cy="{n(y1 + oy)}" rx="7" ry="4" fill="{LEAF if k % 2 == 0 else LEAF_D}"/>')
    return ''.join(g)


def spark(x, y, r=6):
    pts = []
    for k in range(8):
        a = math.pi * k / 4
        rr = r if k % 2 == 0 else r * 0.4
        pts.append(f'{n(x + rr * math.cos(a))} {n(y + rr * math.sin(a))}')
    return (f'<polygon points="{" ".join(pts)}" fill="{YELLOW}"/>'
            f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(r * 0.28)}" fill="{WHITE}"/>')


def tree(x, gy, cy, r=28):
    return (f'<path d="M{n(x - 5)} {gy} L{n(x - 3)} {n(cy)} L{n(x + 3)} {n(cy)} L{n(x + 5)} {gy} Z" fill="{BARK}"/>'
            f'<circle cx="{n(x)}" cy="{n(cy)}" r="{r}" fill="url(#canopy)"/>'
            f'<circle cx="{n(x - r * 0.6)}" cy="{n(cy + r * 0.3)}" r="{n(r * 0.6)}" fill="url(#canopy)"/>'
            f'<circle cx="{n(x + r * 0.6)}" cy="{n(cy + r * 0.25)}" r="{n(r * 0.62)}" fill="url(#canopy)"/>')


# =============================================================================
# Round 1 — which picture is a phase-to-phase fault?
# =============================================================================

R1_PX, R1_YS, R1_ENDS = 26, (66, 92, 118), (54, 80, 106)


def type_card(kind):
    """kind: two, three (branch across wires), ground, track, snapped."""
    tops = [y - 16 for y in R1_YS]
    g = [ground(), tree(184, 186, 38, 22)]
    kinds = ['ok', 'track' if kind == 'track' else 'ok', 'ok']
    g.append(span(R1_PX, R1_YS, R1_ENDS, kinds=kinds, snap=1 if kind == 'snapped' else None))

    def wy(i, x):
        return wire_y(x, R1_PX, tops[i], R1_ENDS[i])

    if kind == 'two':
        # a branch lying over the top two wires
        g.append(branch(96, wy(0, 104) - 14, 150, wy(1, 140) + 12))
        g.append(spark(110, wy(0, 110)))
        g.append(spark(138, wy(1, 138)))
    elif kind == 'three':
        g.append(branch(88, wy(0, 96) - 14, 156, wy(2, 150) + 12))
        g.append(spark(101, wy(0, 101)))
        g.append(spark(124, wy(1, 124)))
        g.append(spark(146, wy(2, 146)))
    elif kind == 'ground':
        # from the bottom wire down to the ground
        g.append(branch(158, 188, 120, wy(2, 120) - 10))
        g.append(spark(124, wy(2, 124)))
    elif kind == 'track':
        # only a small flash beside it: the black track is the clue
        g.append(spark(R1_PX + 25, tops[1] + 2, 3.6))
    return ''.join(g)


# =============================================================================
# Round 2 — a big branch on the line: what is the right work?
# =============================================================================

R2_PX, R2_YS, R2_ENDS = 30, (62, 84, 106), (50, 72, 94)


def branch_card(kind):
    """kind: plan, forest, check (safe); yank, charge, mark (traps)."""
    tops = [y - 16 for y in R2_YS]
    g = [ground(), tree(194, 186, 128, 18)]

    def wy(i, x):
        return wire_y(x, R2_PX, tops[i], R2_ENDS[i])

    g.append(span(R2_PX, R2_YS, R2_ENDS, scar=kind == 'mark'))
    on_line = kind in ('plan', 'yank')
    if on_line:
        g.append(branch(110, wy(0, 116) - 16, 176, wy(1, 168) + 14, w=6))
    elif kind == 'forest':
        # a whole tree fallen across the line, roots on the ground at the right
        g.append(f'<path d="M196 190 L120 {n(wy(0, 120) - 6)}" stroke="{BARK}" stroke-width="11" stroke-linecap="round"/>')
        g.append(f'<path d="M150 {n(wy(2, 150) + 30)} L132 {n(wy(2, 132) + 18)}" stroke="{BARK_D}" stroke-width="4" stroke-linecap="round"/>')
        g.append(f'<circle cx="112" cy="{n(wy(0, 112) - 12)}" r="20" fill="url(#canopy)"/>')
        g.append(f'<circle cx="96" cy="{n(wy(0, 96) - 2)}" r="14" fill="url(#canopy)"/>')
        g.append(f'<ellipse cx="196" cy="192" rx="12" ry="5" fill="{BARK_D}"/>')
    else:
        # the branch already down, cut into pieces on the ground
        g.append(branch(118, 196, 170, 190, w=6))
        g.append(f'<path d="M60 202 L92 198" stroke="{BARK}" stroke-width="5" stroke-linecap="round"/>')
    if kind == 'plan':
        g.append(worker(70, 204, 0.8, 'point'))
        g.append(worker(100, 206, 0.78, 'look'))
        g.append(worker(130, 204, 0.8, 'stand'))
    elif kind == 'forest':
        # the forest department's team (green shirts, cloth caps, a bow saw)
        # cuts the tree up at its foot; the lineman, in his own blue shirt and
        # yellow helmet, stands well back and points; nobody hauls on a rope
        forest = (LEAF_D, LEAF, BARK_D)
        g.append(worker(104, 206, 0.72, 'look', team=forest))
        g.append(worker(150, 208, 0.72, 'saw', team=forest))
        # the bow saw across the trunk, square to it
        g.append('<path d="M161 172 L195 153" stroke="url(#steelArm)" stroke-width="3" stroke-linecap="round"/>')
        g.append(f'<path d="M161 172 Q164 144 195 153" fill="none" stroke="{ROPE}" stroke-width="2.6" stroke-linecap="round"/>')
        g.append(worker(56, 206, 0.72, 'point'))
    elif kind == 'check':
        # after removal he points up at the insulators and the pole, checking them
        g.append(worker(72, 204, 0.86, 'point'))
    elif kind == 'yank':
        # one man, right under the line, hauling the branch down at once
        g.append(f'<path d="M150 {n(wy(1, 150) + 8)} L128 128" stroke="{ROPE}" stroke-width="2.2"/>')
        g.append(worker(142, 206, 0.86, 'pull'))
    elif kind == 'charge':
        g.append(worker(80, 204, 0.86, 'phone', 'talk'))
    elif kind == 'mark':
        g.append(worker(92, 206, 0.86, 'stand', walk=True))
        g.append(f'<rect x="108" y="178" width="18" height="14" rx="2" fill="{BARK_D}" stroke="{INK}" stroke-width="1"/>')
    return ''.join(g)


# =============================================================================
# Round 3 — a cracked insulator: what is the right work?
# =============================================================================

def pole_top_scene(right='crack', split=False):
    """Close-up: pole at x=100, cross-arm at y=96, insulators at 46 / pole top / 154,
    earth leads clamped on all three wires at the left (the line is dead and earthed)."""
    g = [pole(100, 40, 16)]
    g.append(f'<rect x="20" y="96" width="160" height="10" rx="2" fill="url(#steelArm)" stroke="#3B4148" stroke-width="1"/>')
    if split:
        # the cross-arm split open under the insulator
        g.append(f'<path d="M146 95 L152 100 L148 103 L155 107 L161 107 L156 103 L160 100 L154 95 Z" fill="{INK}"/>')
        g.append(f'<path d="M156 101 L178 99 M140 101 L148 102" fill="none" stroke="{HAIR}" stroke-width="1.8" stroke-linecap="round"/>')
    g.append(pin_insulator(46, 70, 'ok', 1.2))
    g.append(pin_insulator(100, 40 - 30, 'ok', 1.2))
    g.append(pin_insulator(154, 70, right, 1.2))
    # wires (the right one sits on its insulator unless it is off for the swap)
    g.append(f'<path d="M0 72 L200 70" stroke="{WIRE}" stroke-width="2.4"/>')
    g.append(f'<path d="M0 12 L200 10" stroke="{WIRE}" stroke-width="2.4"/>')
    if right == 'bare':
        g.append(f'<path d="M0 74 Q120 64 200 52" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
    else:
        g.append(f'<path d="M0 72 L200 70" stroke="{WIRE}" stroke-width="2.4"/>')
    # earth set: clamps on the three wires, leads to the spike off the card
    for y in (11, 71):
        g.append(f'<rect x="12" y="{y - 4}" width="8" height="9" rx="2" fill="url(#steel)" stroke="#334155" stroke-width="0.8"/>')
    g.append(f'<path d="M16 16 Q8 80 4 220 M16 80 Q12 140 10 220" fill="none" stroke="{COPPER}" stroke-width="2.2"/>')
    return ''.join(g)


def pole_worker(reach, extra=''):
    """The lineman on the pole (belted round it), gloved; one hand on the pole,
    the other at [reach]."""
    x, top = 120, 118
    g = [f'<path d="M{x - 12} {top + 36} Q100 {top + 46} {x - 22} {top + 26}" fill="none" stroke="{INK}" stroke-width="3"/>']
    g.append(limb((x, top + 40), (x + 8, top + 64), (x + 2, top + 92), PANTS_D, 9))
    g.append(limb((x, top + 40), (x - 6, top + 66), (x - 12, top + 88), PANTS, 9))
    g.append(f'<path d="M{x - 13} {top + 8} L{x + 13} {top + 8} L{x + 11} {top + 42} L{x - 11} {top + 42} Z" fill="url(#shirt)"/>')
    sh = (x - 4, top + 12)
    g.append(limb(sh, (x - 12, top + 20), (106, top + 30), SHIRT_B, 7))
    g.append(glove_hand((106, top + 30)))
    mx, my = (sh[0] + reach[0]) / 2 + 6, (sh[1] + reach[1]) / 2 + 6
    g.append(limb((x + 6, top + 12), (mx, my), reach, SHIRT_B, 7))
    g.append(head(x, top - 6, 0.78, 'up', -6))
    g.append(extra)
    g.append(glove_hand(reach))
    return ''.join(g)


def insulator_card(kind):
    """kind: swap, arm (safe); tape, wipe, splitarm (traps)."""
    g = []
    if kind == 'swap':
        g.append(pole_top_scene('bare'))
        # the new insulator in his hand, about to go on the bare pin
        g.append(pole_worker((156, 64), pin_insulator(154, 50, 'new', 1.2)))
        g.append(pin_insulator(140, 182, 'crack', 1.2))  # the old one, lying in his bag
    elif kind == 'arm':
        g.append(pole_top_scene('crack'))
        g.append(pole_worker((150, 100)))
    elif kind == 'tape':
        g.append(pole_top_scene('crack'))
        g.append(f'<path d="M142 80 L166 78 M141 86 L167 84 M142 92 L166 90" stroke="{TAPE}" stroke-width="3.2"/>')
        g.append(pole_worker((160, 98), f'<circle cx="166" cy="104" r="6" fill="none" stroke="{TAPE}" stroke-width="4"/>'))
    elif kind == 'wipe':
        g.append(pole_top_scene('track'))
        g.append(pole_worker((150, 84), f'<path d="M140 78 Q150 72 162 80 L158 92 Q148 88 140 92 Z" fill="{CLOTH}" stroke="#94A3B8" stroke-width="1"/>'))
    elif kind == 'splitarm':
        g.append(pole_top_scene('new', split=True))
        g.append(pole_worker((150, 88)))
    # his tool bag on the belt, on every card
    g.append(f'<path d="M126 196 L156 196 L152 214 L130 214 Z" fill="{BARK_D}" stroke="{INK}" stroke-width="1"/>')
    return ''.join(g)


# =============================================================================
# Round 4 — a melted PG clamp: how is the hotspot repaired?
# =============================================================================

def tool_tray():
    """The canvas tray with the same tools on every card: spanner, cutter, tape."""
    g = ['<rect x="0" y="176" width="200" height="44" fill="url(#tarp)"/>']
    g.append('<path d="M20 200 L70 190" stroke="url(#steel)" stroke-width="6" stroke-linecap="round"/>')
    g.append('<circle cx="72" cy="190" r="6" fill="none" stroke="url(#steel)" stroke-width="4"/>')
    g.append(f'<path d="M100 190 L128 196 M100 206 L128 200" stroke="{KITE}" stroke-width="5" stroke-linecap="round"/>')
    g.append('<path d="M128 196 Q138 190 148 192 M128 200 Q138 204 148 200" fill="none" stroke="url(#steel)" stroke-width="4" stroke-linecap="round"/>')
    g.append(f'<circle cx="174" cy="198" r="9" fill="none" stroke="{TAPE}" stroke-width="6"/>')
    return ''.join(g)


def conductor(x0, x1, y=78, fill='url(#alu)'):
    return f'<rect x="{n(x0)}" y="{n(y - 6)}" width="{n(x1 - x0)}" height="12" rx="5" fill="{fill}" stroke="#5B636B" stroke-width="1"/>'


def strands(x, y, side=1, color=MANJA):
    return ''.join(f'<path d="M{n(x)} {n(y + dy)} l{n(side * 10)} {n(dy * 1.4)}" stroke="{color}" stroke-width="1.6" stroke-linecap="round"/>'
                   for dy in (-4, -1.5, 1.5, 4))


def pg_clamp(x, y, melted=False):
    if melted:
        return (f'<path d="M{x - 18} {y - 12} Q{x} {y - 20} {x + 18} {y - 12} L{x + 16} {y + 14} Q{x + 8} {y + 26} {x + 2} {y + 16} '
                f'Q{x - 6} {y + 30} {x - 10} {y + 16} L{x - 18} {y + 12} Z" fill="url(#burnt)" stroke="{CHAR}" stroke-width="1.2"/>'
                f'<circle cx="{x - 7}" cy="{y}" r="3" fill="{CHAR}"/><circle cx="{x + 7}" cy="{y}" r="3" fill="{CHAR}"/>')
    return (f'<rect x="{x - 18}" y="{y - 13}" width="36" height="26" rx="4" fill="url(#steel)" stroke="#475569" stroke-width="1.2"/>'
            f'<circle cx="{x - 8}" cy="{y}" r="4" fill="url(#steelArm)"/><circle cx="{x + 8}" cy="{y}" r="4" fill="url(#steelArm)"/>')


def gloves_at(*pts):
    out = []
    for (x, y) in pts:
        out.append(f'<path d="M{n(x)} {n(y + 6)} L{n(x + (8 if x < 100 else -8))} 176" stroke="{SHIRT_B}" stroke-width="12" stroke-linecap="round"/>')
        out.append(f'<ellipse cx="{n(x)}" cy="{n(y)}" rx="9" ry="8" fill="{GLOVE}" stroke="{GLOVE_S}" stroke-width="1.2"/>')
    return ''.join(out)


def spanner(x, y):
    return (f'<path d="M{x} {y} L{x + 34} {y + 40}" stroke="url(#steel)" stroke-width="6" stroke-linecap="round"/>'
            f'<path d="M{x - 6} {y - 6} L{x + 2} {y - 8} L{x + 6} {y} " fill="none" stroke="url(#steel)" stroke-width="4"/>')


def clamp_card(kind):
    """kind: fresh, soft, cut (safe); retight, blackend, twist (traps)."""
    g = []
    # the jumper dropping away from the main conductor, behind everything
    g.append('<path d="M104 92 Q110 140 160 176" fill="none" stroke="url(#alu)" stroke-width="9"/>')
    if kind == 'fresh':
        g.append(conductor(0, 200))
        g.append(pg_clamp(100, 82))
        g.append(spanner(108, 82))
        g.append(gloves_at((140, 122), (56, 110)))
    elif kind == 'soft':
        # the old clamp is off; the conductor beside the burn is dark, and bends
        # and stays kinked with its strands splayed (softened by the heat)
        g.append(conductor(0, 84))
        g.append('<path d="M84 78 L104 84 L124 78" fill="none" stroke="url(#burnt)" stroke-width="12" stroke-linejoin="round"/>')
        g.append(strands(102, 86, 1, '#4A3B2A'))
        g.append(conductor(124, 200))
        g.append(gloves_at((76, 92), (132, 92)))
        g.append(pg_clamp(40, 150, melted=True))
    elif kind == 'cut':
        g.append(conductor(0, 76))
        g.append(conductor(130, 200))
        # the discoloured soft length falls away
        g.append(f'<rect x="84" y="120" width="40" height="12" rx="5" fill="url(#burnt)" stroke="{CHAR}" stroke-width="1" transform="rotate(14 104 126)"/>')
        # the cutter: steel jaws closed round the conductor at the cut, the
        # pivot under it, two red handles opening downwards to his gloves
        g.append('<path d="M68 102 Q58 86 66 68 M74 102 Q84 86 76 68" fill="none" stroke="url(#steel)" stroke-width="5" stroke-linecap="round"/>')
        g.append('<circle cx="71" cy="103" r="4" fill="url(#steelArm)" stroke="#475569" stroke-width="1"/>')
        g.append(f'<path d="M68 107 L50 146 M74 107 L90 146" stroke="{KITE}" stroke-width="6" stroke-linecap="round"/>')
        g.append(gloves_at((50, 148), (90, 148)))
    elif kind == 'retight':
        g.append(conductor(0, 200))
        g.append(pg_clamp(100, 82, melted=True))
        g.append(spanner(108, 82))
        g.append(gloves_at((140, 122), (56, 110)))
    elif kind == 'blackend':
        g.append(conductor(0, 200))
        g.append('<rect x="64" y="72" width="70" height="12" rx="5" fill="url(#burnt)"/>')
        g.append(strands(124, 78, 1, '#4A3B2A'))
        g.append(pg_clamp(100, 82))
        g.append(spanner(108, 82))
        g.append(gloves_at((140, 122), (56, 110)))
    elif kind == 'twist':
        g.append(conductor(0, 86))
        g.append(conductor(114, 200))
        g.append(f'<path d="M84 78 Q92 66 100 78 Q108 90 116 78 M86 78 Q94 90 102 78 Q110 66 118 78" fill="none" stroke="url(#alu)" stroke-width="5"/>')
        g.append(f'<circle cx="84" cy="70" r="3" fill="url(#burnt)"/><circle cx="118" cy="86" r="3" fill="url(#burnt)"/>')
        g.append(gloves_at((82, 92), (120, 92)))
    g.append(tool_tray())
    return ''.join(g)


# =============================================================================
# Round 5 — which picture is clear evidence of the fault?
# =============================================================================

R5_PX, R5_YS, R5_ENDS = 40, (54, 72, 90), (40, 58, 76)


def lightning_arrester(px, y, burst=False):
    """An LA on its bracket on the pole, the earth lead running down the pole."""
    x = px + 20
    g = [f'<g transform="translate({px} {y}) scale(1.5) translate({-px} {-y})">',
         f'<rect x="{px}" y="{y + 30}" width="22" height="5" rx="1" fill="url(#steelArm)"/>']
    if burst:
        g.append(f'<path d="M{x - 6} {y + 30} L{x - 6} {y + 18} L{x - 2} {y + 22} L{x + 1} {y + 14} L{x + 4} {y + 21} L{x + 6} {y + 16} L{x + 6} {y + 30} Z" fill="url(#laBody)" stroke="{CHAR}" stroke-width="1"/>')
        g.append(f'<path d="M{x - 5} {y + 18} Q{x} {y + 10} {x + 5} {y + 17}" fill="none" stroke="{CHAR}" stroke-width="2.2"/>')
        # its pieces on the ground and the earth lead hanging loose
        for fx, fy, r in ((x + 14, y + 61, 0), (x + 26, y + 62, 30), (x + 18, y + 64, -20)):
            g.append(f'<rect x="{fx}" y="{fy}" width="9" height="6" rx="1" fill="url(#laBody)" transform="rotate({r} {fx} {fy})"/>')
        g.append(f'<path d="M{x} {y + 35} Q{x + 8} {y + 46} {x + 3} {y + 54} Q{x - 3} {y + 59} {x + 7} {y + 61}" fill="none" stroke="{COPPER}" stroke-width="2.2"/>')
    else:
        g.append(f'<rect x="{x - 6}" y="{y - 4}" width="12" height="34" rx="2" fill="url(#laBody)" stroke="#3B4148" stroke-width="0.8"/>')
        for k in range(4):
            g.append(f'<rect x="{x - 9}" y="{y + k * 8}" width="18" height="3" rx="1.5" fill="url(#laBody)"/>')
        g.append(f'<path d="M{x} {y + 35} L{x} {y + 44} L{px + 7} {y + 48} L{px + 7} 220" fill="none" stroke="{COPPER}" stroke-width="2.2"/>')
        g.append(f'<circle cx="{px + 7}" cy="{y + 48}" r="2.6" fill="url(#steel)" stroke="#334155" stroke-width="0.8"/>')
        g.append(f'<circle cx="{x}" cy="{y + 44}" r="2.6" fill="url(#steel)" stroke="#334155" stroke-width="0.8"/>')
    g.append('</g>')
    return ''.join(g)


def bird(x, y, s=1.0, burnt=False):
    """A crow-sized bird; burnt: lying on its back, charred, wings splayed."""
    if burnt:
        return (f'<g transform="translate({n(x)} {n(y)}) scale({s})">'
                f'<path d="M-16 0 Q-8 -8 0 -4 Q8 -8 16 0 Q8 4 0 2 Q-8 4 -16 0 Z" fill="{CHAR}"/>'
                f'<ellipse cx="0" cy="-2" rx="7" ry="5" fill="{CHAR}"/>'
                f'<path d="M-2 -6 L-4 -12 M2 -6 L4 -12" stroke="{CHAR}" stroke-width="1.4"/>'
                '</g>')
    return (f'<g transform="translate({n(x)} {n(y)}) scale({s})">'
            f'<ellipse cx="0" cy="0" rx="9" ry="6" fill="#4B5563"/>'
            f'<circle cx="8" cy="-5" r="4.4" fill="#4B5563"/>'
            f'<path d="M12 -5 L17 -4 L12 -3 Z" fill="{YELLOW}"/>'
            f'<path d="M-6 -2 Q-2 -8 4 -2" fill="{CHAR}"/>'
            f'<path d="M-9 0 L-16 3 L-9 3 Z" fill="{CHAR}"/>'
            f'<circle cx="9" cy="-6" r="1" fill="{WHITE}"/>'
            f'<path d="M-1 6 L-1 9 M2 6 L2 9" stroke="#C2410C" stroke-width="1"/>'
            '</g>')


def kite(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({n(x)} {n(y)}) rotate({rot}) scale({s})">'
            f'<path d="M0 -14 L10 0 L0 16 L-10 0 Z" fill="{KITE}" stroke="{BLOOD}" stroke-width="1.4"/>'
            f'<path d="M0 -14 L0 16 M-10 0 L10 0" stroke="{BLOOD}" stroke-width="1"/>'
            f'<path d="M0 16 Q-4 22 0 26 Q4 30 0 34" fill="none" stroke="{YELLOW}" stroke-width="1.6"/>'
            '</g>')


def evidence_card(kind):
    """kind: bird, la, manja (safe); livebird, intactla, farkite (traps)."""
    tops = [y - 16 for y in R5_YS]
    g = [ground(), tree(166, 186, 140, 24)]
    g.append(span(R5_PX, R5_YS, R5_ENDS))

    def wy(i, x):
        return wire_y(x, R5_PX, tops[i], R5_ENDS[i])

    if kind == 'bird':
        g.append(f'<path d="M110 {n(wy(1, 110) - 1)} Q116 {n(wy(1, 116) + 3)} 122 {n(wy(1, 122) - 1)}" fill="none" stroke="{BLOOD}" stroke-width="4" stroke-linecap="round"/>')
        g.append(f'<path d="M116 {n(wy(1, 116) + 2)} L117 {n(wy(1, 116) + 7)}" stroke="{BLOOD}" stroke-width="2" stroke-linecap="round"/>')
        g.append(bird(116, 196, 1.1, burnt=True))
    elif kind == 'la':
        g.append(lightning_arrester(R5_PX, 96, burst=True))
    elif kind == 'manja':
        # the kite hangs below; its metal string lies over the top two wires
        g.append(f'<path d="M96 {n(wy(0, 96) - 1)} L118 {n(wy(0, 118) - 1)} L132 {n(wy(1, 132))} L136 {n(wy(1, 136) + 30)}" fill="none" stroke="{MANJA}" stroke-width="1.8"/>')
        g.append(kite(136, wy(1, 136) + 44, 1.0, -8))
    elif kind == 'livebird':
        g.append(bird(170, 122, 1.0))
    elif kind == 'intactla':
        g.append(lightning_arrester(R5_PX, 96))
    elif kind == 'farkite':
        g.append(f'<path d="M150 128 Q160 140 168 150" fill="none" stroke="{MANJA}" stroke-width="1.8"/>')
        g.append(kite(146, 120, 0.9, 20))
    return ''.join(g)


CARDS = {
    # Round 1 — phase-to-phase or not
    'type_two': make_card(type_card('two')),
    'type_three': make_card(type_card('three')),
    'type_ground': make_card(type_card('ground')),
    'type_track': make_card(type_card('track')),
    'type_snapped': make_card(type_card('snapped')),
    # Round 2 — a big branch on the line
    'branch_plan': make_card(branch_card('plan')),
    'branch_forest': make_card(branch_card('forest')),
    'branch_check': make_card(branch_card('check')),
    'branch_yank': make_card(branch_card('yank')),
    'branch_charge': make_card(branch_card('charge')),
    'branch_mark': make_card(branch_card('mark')),
    # Round 3 — a cracked insulator
    'insulator_swap': make_card(insulator_card('swap')),
    'insulator_arm': make_card(insulator_card('arm')),
    'insulator_tape': make_card(insulator_card('tape')),
    'insulator_wipe': make_card(insulator_card('wipe')),
    'insulator_splitarm': make_card(insulator_card('splitarm')),
    # Round 4 — a melted PG clamp
    'clamp_fresh': make_card(clamp_card('fresh')),
    'clamp_soft': make_card(clamp_card('soft')),
    'clamp_cut': make_card(clamp_card('cut')),
    'clamp_retight': make_card(clamp_card('retight')),
    'clamp_blackend': make_card(clamp_card('blackend')),
    'clamp_twist': make_card(clamp_card('twist')),
    # Round 5 — clear evidence
    'evidence_bird': make_card(evidence_card('bird')),
    'evidence_la': make_card(evidence_card('la')),
    'evidence_manja': make_card(evidence_card('manja')),
    'evidence_livebird': make_card(evidence_card('livebird')),
    'evidence_intactla': make_card(evidence_card('intactla')),
    'evidence_farkite': make_card(evidence_card('farkite')),
}

# Which cards are safe in each board round (mirrors learn_board_pack53.dart).
ROUNDS = {
    'type': ({'type_two', 'type_three'}, {'type_ground', 'type_track', 'type_snapped'}),
    'branch': ({'branch_plan', 'branch_forest', 'branch_check'}, {'branch_yank', 'branch_charge', 'branch_mark'}),
    'insulator': ({'insulator_swap', 'insulator_arm'}, {'insulator_tape', 'insulator_wipe', 'insulator_splitarm'}),
    'clamp': ({'clamp_fresh', 'clamp_soft', 'clamp_cut'}, {'clamp_retight', 'clamp_blackend', 'clamp_twist'}),
    'evidence': ({'evidence_bird', 'evidence_la', 'evidence_manja'}, {'evidence_livebird', 'evidence_intactla', 'evidence_farkite'}),
}
HAND = 4

# ---- The fairness check (same as tool/scan_board_art.py) --------------------

_ELEM = re.compile(r'<(/?)([\w:]+)\b([^>]*?)(/?)>')
_ATTR = re.compile(r'([\w:-]+)="([^"]*)"')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
_NUM = re.compile(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
_XFORM = re.compile(r'(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)')
_PATH_TOK = re.compile(r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?')
_NO_PAINT = {'g', 'svg', 'a', 'switch'}
_DEFS = {'defs', 'clipPath', 'mask', 'pattern', 'symbol', 'marker', 'linearGradient', 'radialGradient', 'filter'}
_INHERIT = ('fill', 'stroke', 'fill-opacity', 'stroke-opacity', 'stroke-width', 'visibility')
_ID = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def _num(v, default=1.0):
    try:
        v = v.strip()
        return float(v[:-1]) / 100 if v.endswith('%') else float(v)
    except (AttributeError, TypeError, ValueError):
        return default


def _attrs(raw):
    a = dict(_ATTR.findall(raw))
    for part in a.pop('style', '').split(';'):
        if ':' in part:
            k, v = part.split(':', 1)
            a[k.strip()] = v.strip()
    return a


def _mul(m, k):
    a1, b1, c1, d1, e1, f1 = m
    a2, b2, c2, d2, e2, f2 = k
    return (a1 * a2 + c1 * b2, b1 * a2 + d1 * b2, a1 * c2 + c1 * d2, b1 * c2 + d1 * d2,
            a1 * e2 + c1 * f2 + e1, b1 * e2 + d1 * f2 + f1)


def _transform(text):
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
    toks = _PATH_TOK.findall(d)
    arity = {'m': 2, 'l': 2, 'h': 1, 'v': 1, 'c': 6, 's': 4, 'q': 4, 't': 2, 'a': 7, 'z': 0}
    pts, i, cmd = [], 0, None
    x = y = sx = sy = 0.0
    last_c = None
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
            k = arity[cmd.lower()]
            v = [float(t) for t in toks[i:i + k]]
            if len(v) < k:
                return None
            i += k
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
                ctrl = [(v[j] + ox, v[j + 1] + oy) for j in range(0, k, 2)]
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
    v = lambda k: _num(a.get(k), 0.0)
    if tag == 'rect':
        return [(v('x'), v('y')), (v('x') + v('width'), v('y') + v('height'))]
    if tag == 'circle':
        return [(v('cx') - v('r'), v('cy') - v('r')), (v('cx') + v('r'), v('cy') + v('r'))]
    if tag == 'ellipse':
        return [(v('cx') - v('rx'), v('cy') - v('ry')), (v('cx') + v('rx'), v('cy') + v('ry'))]
    if tag == 'line':
        return [(v('x1'), v('y1')), (v('x2'), v('y2'))]
    if tag in ('polygon', 'polyline'):
        p = [float(t) for t in _NUM.findall(a.get('points', ''))]
        return list(zip(p[0::2], p[1::2])) or None
    if tag == 'path':
        return _path_points(a.get('d', ''))
    return None


def _paint(tag, a):
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
        fill_on = False
        if a.get('x1') == a.get('x2') and a.get('y1') == a.get('y2'):
            return fill_on, stroke_on, False
    return fill_on, stroke_on, fill_on or stroke_on


def painted(svg):
    """Yield (tag, attrs, fill on, stroke on) for every element that really puts
    paint on the 200 x 220 card (see tool/scan_board_art.py)."""
    root = re.search(r'<svg\b[^>]*viewBox="([^"]*)"', svg)
    vb = [float(t) for t in _NUM.findall(root.group(1))] if root else []
    x0, y0, cw, ch = vb if len(vb) == 4 else (0.0, 0.0, 200.0, 220.0)
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
            pad = 2 * _num(a.get('stroke-width')) if stroke_on else 0.0
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
    out = set()
    for tag, a, fill_on, stroke_on in painted(svg):
        if fill_on and 'fill' in a:
            out.update(_TOKEN.findall(a['fill']))
        if stroke_on and 'stroke' in a:
            out.update(_TOKEN.findall(a['stroke']))
    return out


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
