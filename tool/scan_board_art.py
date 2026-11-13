"""Picture cards for ladder steps 28–29 (lesson 1.10, "১০ সেকেন্ডের মেন্টাল চেকলিস্ট").

python -I tool/scan_board_art.py .

Writes assets/game/art/scan_board/*.svg (200 x 220 scene cards, drawn edge to
edge, no words) for the step-28 picture board (learn_board_pack110.dart) and
the step-29 checks (ten_sec_scan.dart). Every card shows only what a lineman
would see; content follows lessons 1.1–1.10:

* kit_*      — the day's PPE laid out on the bench (lesson 1.1): helmet, the
               boot turned sole up, the air-filled rubber glove, the shirt.
               Traps: a hairline crack in the helmet, a nail in the sole, a
               pinhole leaking air, a shiny synthetic (polyester) shirt.
* harness_*  — the full body harness on him (lesson 1.4): four fingers under
               the strap; traps: chest strap open, chest strap up at the
               neck, a twisted strap, cut/frayed webbing; the label against
               the calendar (step 29 only).
* tool_/rod_ — the tool bag and the discharge rod on the tarp (lessons 1.5,
               1.10): a cracked rod stick, a PVC jugaad rod (step 29 only).
* ptw_/mind_ — him at the pole with the written, signed permit (lessons 1.6,
               1.10): calm vs a phone "permit", rushing, tired, the permit
               pushed in the pocket unread.
* pole_/clearance_ — the pole and the লক্ষ্মণ রেখা (lessons 1.2, 1.3): the
               hammer's long even ring; traps: a leaning pole with a cracked
               base, rust at the ground line, climbing unchecked, a tool tip
               inside the line's distance.
* site_/hazard_/rescue_/weather_ — the surroundings, the weather and the way
               down (lessons 1.3, 1.9, 1.10): a mate standing by, a clear
               site; traps: a hive under the cross-arm, traffic, a storm,
               water at the pole base; a blocked way down (step 29 only).

Each round's cards are one scene template with one thing changed, so no
colour, backdrop or highlight points at the safe card (no green glow, no red
warning marks): the generator asserts that in every hand the dealer can make
(one safe card + three traps) every colour and gradient the safe card draws
is drawn by a trap too, and the safe card's backdrop is on a trap. Invisible
shapes are ignored by the check, here and in test/learn_board_110_test.dart,
so they can never satisfy it: zero size, no paint, opacity 0 / display none /
visibility hidden on the shape or on any group around it, a scale(0)
transform, or a shape wholly off the card. Paint the check can't follow (a
mask, a filter, <use>, an image, a clip other than the card's) is refused.
Shapes also never single out the safe card: the mate standing by is on two
traps too, and the লক্ষ্মণ রেখা ring is on every pole card.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/scan_board_art.py <repo root>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'scan_board')
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
RED = '#D32F2F'
WHITE = '#FFFFFF'
DARK = '#1E293B'
INK = '#0F172A'
HANDLE = '#B45309'
WEB_D = '#9A3412'
HELMET_S = '#B45309'
BRIM = '#EAB308'
BRIM_S = '#A16207'
PLANK = '#7E5229'
GROUND_L = '#8C7550'
GLOVE = '#EA580C'
GLOVE_S = '#9A3412'
GLOVE_H = '#FDBA74'
CUFF = '#C2410C'
SHIRT_L = '#0E3352'
SHIRT_B = '#174A70'
SIGN = '#1D4ED8'
SUN = '#FDE68A'
LEAF = '#4E7A3A'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="storm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1B2433"/><stop offset="1" stop-color="#4A5568"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B6470"/><stop offset="1" stop-color="#3F4650"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelPole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E7780"/><stop offset="0.5" stop-color="#C9D0D6"/><stop offset="1" stop-color="#666F78"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A3B1E"/><stop offset="0.5" stop-color="#B0643A"/><stop offset="1" stop-color="#6B3219"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="poly" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3E8FD6"/><stop offset="0.35" stop-color="#BFE3FF"/><stop offset="0.5" stop-color="#3C8AD0"/><stop offset="0.75" stop-color="#A7D6FF"/><stop offset="1" stop-color="#2F76B8"/></linearGradient>
  <linearGradient id="webO" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF9F45"/><stop offset="0.5" stop-color="#F7811F"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="webBack" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C2560A"/><stop offset="1" stop-color="#8F3C06"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="board" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9A6A3C"/><stop offset="1" stop-color="#6E4524"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEFF2"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9965E"/><stop offset="1" stop-color="#9E6B38"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F6EA6"/><stop offset="1" stop-color="#1F4F7C"/></linearGradient>
  <linearGradient id="rust" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C46A2B"/><stop offset="0.5" stop-color="#9A4517"/><stop offset="1" stop-color="#6E2E0E"/></linearGradient>
  <linearGradient id="bootSole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#111827"/><stop offset="0.4" stop-color="#1F2937"/><stop offset="1" stop-color="#0F172A"/></linearGradient>
  <linearGradient id="bootLug" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#374151"/><stop offset="1" stop-color="#111827"/></linearGradient>
  <linearGradient id="helmetDome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FEF08A"/><stop offset="0.25" stop-color="#FACC15"/><stop offset="1" stop-color="#CA8A04"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9C46A"/><stop offset="1" stop-color="#C7962E"/></linearGradient>
  <linearGradient id="pvc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E5E7EB"/><stop offset="0.5" stop-color="#9CA3AF"/><stop offset="1" stop-color="#D1D5DB"/></linearGradient>
  <linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB8D8"/><stop offset="1" stop-color="#3F7FA6"/></linearGradient>
  <linearGradient id="car" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E04848"/><stop offset="1" stop-color="#9E1F1F"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.5"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
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

def head(x, y, s=1.0, face='calm', tilt=0):
    """His head with the helmet; [face]: calm, talk, tense, tired, up."""
    g = [f'<g transform="translate({n(x)} {n(y)}) rotate({tilt}) scale({s})">']
    g.append(f'<rect x="-6" y="8" width="12" height="12" rx="3" fill="{SKIN_D}"/>')
    g.append(f'<ellipse cx="0" cy="0" rx="14" ry="16" fill="{SKIN}"/>')
    g.append(f'<path d="M-17 -4 Q-16 -26 0 -27 Q16 -26 17 -4 Z" fill="url(#helmetDome)" stroke="{HELMET_S}" stroke-width="1.4"/>')
    g.append(f'<path d="M-20 -4 Q0 2 20 -4 L19 0 Q0 6 -19 0 Z" fill="{BRIM}" stroke="{BRIM_S}" stroke-width="1"/>')
    g.append(f'<path d="M-12 0 Q-12 14 0 16 Q12 14 12 0" fill="none" stroke="{DARK}" stroke-width="1.8"/>')
    ey = 4 if face != 'up' else 1
    if face == 'tired':
        g.append(f'<path d="M-8 {ey} L-3 {ey + 1}" stroke="{HAIR}" stroke-width="2" stroke-linecap="round"/>')
        g.append(f'<path d="M3 {ey + 1} L8 {ey}" stroke="{HAIR}" stroke-width="2" stroke-linecap="round"/>')
        g.append(f'<ellipse cx="0" cy="12" rx="3.2" ry="4" fill="{HAIR}"/>')
    else:
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
    return f'<path d="M{n(a[0])} {n(a[1])} L{n(b[0])} {n(b[1])} L{n(c[0])} {n(c[1])}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'


def hand(p, r=4.2):
    return f'<circle cx="{n(p[0])}" cy="{n(p[1])}" r="{r}" fill="{SKIN}"/>'


def worker(x, gy, s=1.0, pose='stand', face='calm', reach=1.0):
    """Full figure, feet at ([x], [gy]), ~95 px tall at s=1.
    pose: stand, hammer (knocks left), rod (holds a rod up-left), climb (on the
    pole to his left), look (looks up, hand at brow)."""
    def P(dx, dy):
        return (x + dx * s, gy + dy * s)
    g = []
    hip, sh = P(0, -44), P(0, -74)
    # legs
    if pose == 'climb':
        g.append(limb(hip, P(-10, -30), P(-14, -18), PANTS, 9 * s))
        g.append(limb(hip, P(6, -24), P(2, -6), PANTS_D, 9 * s))
        g.append(f'<rect x="{n(x - 20 * s)}" y="{n(gy - 22 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x - 3 * s)}" y="{n(gy - 9 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    else:
        g.append(limb(hip, P(-5, -22), P(-6, -4), PANTS_D, 9 * s))
        g.append(limb(hip, P(5, -22), P(6, -4), PANTS, 9 * s))
        g.append(f'<rect x="{n(x - 13 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
        g.append(f'<rect x="{n(x + 1 * s)}" y="{n(gy - 6 * s)}" width="{n(13 * s)}" height="{n(6 * s)}" rx="2" fill="{BOOT}"/>')
    # torso
    g.append(f'<path d="M{n(x - 13 * s)} {n(gy - 76 * s)} L{n(x + 13 * s)} {n(gy - 76 * s)} L{n(x + 11 * s)} {n(gy - 42 * s)} L{n(x - 11 * s)} {n(gy - 42 * s)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{n(x)} {n(gy - 76 * s)} L{n(x)} {n(gy - 44 * s)}" stroke="{SHIRT_L}" stroke-width="1"/>')
    # arms + props
    props = []
    if pose == 'hammer':
        g.append(limb(sh, P(8, -58), P(10, -46), SHIRT_B, 7 * s))
        g.append(hand(P(10, -46), 3.8 * s))
        g.append(limb(sh, P(-12, -64), P(-24, -56), SHIRT_B, 7 * s))
        hx, hy = P(-24, -56)
        props.append(f'<path d="M{n(hx)} {n(hy)} L{n(hx - 16 * s)} {n(hy - 8 * s)}" stroke="{HANDLE}" stroke-width="{n(3.5 * s)}" stroke-linecap="round"/>')
        props.append(f'<rect x="{n(hx - 22 * s)}" y="{n(hy - 16 * s)}" width="{n(8 * s)}" height="{n(13 * s)}" rx="1.5" fill="url(#steel)" stroke="{DARK}" stroke-width="0.8" transform="rotate(-25 {n(hx - 18 * s)} {n(hy - 9 * s)})"/>')
        props.append(hand(P(-24, -56), 3.8 * s))
    elif pose == 'rod':
        g.append(limb(sh, P(-10, -84), P(-18, -94), SHIRT_B, 7 * s))
        g.append(limb(sh, P(-4, -66), P(-12, -76), SHIRT_B, 7 * s))
        props.append(f'<path d="M{n(x - 4 * s)} {n(gy - 64 * s)} L{n(x - 4 * s - 40 * reach * s)} {n(gy - 64 * s - 86 * reach * s)}" stroke="{YELLOW}" stroke-width="{n(4 * s)}" stroke-linecap="round"/>')
        props.append(f'<path d="M{n(x - 4 * s)} {n(gy - 64 * s)} L{n(x - 14 * s)} {n(gy - 86 * s)}" stroke="{HANDLE}" stroke-width="{n(4.4 * s)}" stroke-linecap="round"/>')
        props.append(hand(P(-18, -94), 3.8 * s))
        props.append(hand(P(-12, -76), 3.8 * s))
    elif pose == 'climb':
        g.append(limb(sh, P(-12, -88), P(-16, -100), SHIRT_B, 7 * s))
        g.append(limb(sh, P(-10, -66), P(-16, -70), SHIRT_B, 7 * s))
        props.append(hand(P(-16, -100), 3.8 * s))
        props.append(hand(P(-16, -70), 3.8 * s))
    elif pose == 'look':
        g.append(limb(sh, P(-10, -80), P(-4, -92), SHIRT_B, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), SHIRT_B, 7 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    else:
        g.append(limb(sh, P(-10, -60), P(-12, -46), SHIRT_B, 7 * s))
        g.append(limb(sh, P(10, -60), P(12, -46), SHIRT_B, 7 * s))
        props.append(hand(P(-12, -46), 3.8 * s))
        props.append(hand(P(12, -46), 3.8 * s))
    tilt = -8 if pose in ('look',) else (-6 if pose == 'climb' else 0)
    g.append(head(x, gy - 90 * s, s * 0.78, 'up' if pose == 'look' else face, tilt))
    if pose == 'look':
        g.append(hand(P(-4, -92), 3.8 * s))
    return ''.join(g + props)


# =============================================================================
# Round 1 — the PPE kit on the bench (lesson 1.1)
# =============================================================================

def bench():
    return ''.join(f'<line x1="0" y1="{y}" x2="200" y2="{y}" stroke="{PLANK}" stroke-width="1.2" opacity="0.6"/>' for y in (42, 110, 178))


def kit_helmet(cx, cy, crack=False):
    g = [f'<g transform="translate({cx} {cy})">']
    g.append('<ellipse cx="0" cy="22" rx="40" ry="8" fill="#000000" opacity="0.22"/>')
    g.append(f'<path d="M-34 14 Q-32 -34 0 -36 Q32 -34 34 14 Z" fill="url(#helmetDome)" stroke="{HELMET_S}" stroke-width="2"/>')
    g.append('<path d="M-16 6 Q-12 -24 0 -26 Q12 -24 16 6" fill="none" stroke="#FFFFFF" stroke-width="2" opacity="0.6"/>')
    g.append(f'<path d="M-42 12 Q0 26 42 12 L40 20 Q0 34 -40 20 Z" fill="{BRIM}" stroke="{BRIM_S}" stroke-width="1.6"/>')
    # chin strap lying in front, buckle closed
    g.append(f'<path d="M-30 22 Q-20 40 0 40 Q20 40 30 22" fill="none" stroke="{DARK}" stroke-width="4" stroke-linecap="round"/>')
    g.append(f'<rect x="-6" y="35" width="12" height="9" rx="2" fill="{INK}" stroke="url(#steel)" stroke-width="1.2"/>')
    if crack:
        g.append(f'<path d="M6 -33 L2 -22 L9 -14 L3 -4 L8 8" fill="none" stroke="{HAIR}" stroke-width="1.8" stroke-linejoin="round"/>')
        g.append(f'<path d="M2 -22 L-5 -18 M9 -14 L15 -12" fill="none" stroke="{HAIR}" stroke-width="1.1"/>')
    g.append('</g>')
    return ''.join(g)


def kit_shirt(cx, cy, poly=False):
    fill = 'url(#poly)' if poly else 'url(#shirt)'
    g = [f'<g transform="translate({cx} {cy})">']
    g.append('<rect x="-38" y="-30" width="76" height="66" rx="5" fill="#000000" opacity="0.22"/>')
    g.append(f'<path d="M-38 -34 L-14 -40 L14 -40 L38 -34 L38 32 L-38 32 Z" fill="{fill}" stroke="{SHIRT_L}" stroke-width="1.6"/>')
    g.append(f'<path d="M-14 -40 L0 -26 L14 -40" fill="none" stroke="{SHIRT_L}" stroke-width="1.6"/>')
    g.append(f'<path d="M-38 4 L-22 4 L-22 32" fill="none" stroke="{SHIRT_L}" stroke-width="1.2"/>')
    g.append(f'<path d="M38 4 L22 4 L22 32" fill="none" stroke="{SHIRT_L}" stroke-width="1.2"/>')
    g.append(f'<path d="M0 -26 L0 32" stroke="{SHIRT_L}" stroke-width="1.2"/>')
    for by in (-14, 2, 18):
        g.append(f'<circle cx="0" cy="{by}" r="2.4" fill="{SHIRT_B}"/>')
    if poly:
        # synthetic sheen and a melted, curled hole
        g.append('<path d="M-32 -26 L-8 26 M-18 -32 L6 22 M12 -34 L32 14" stroke="#FFFFFF" stroke-width="2.4" opacity="0.55"/>')
        g.append(f'<path d="M16 12 Q22 6 28 12 Q30 20 22 22 Q14 22 16 12 Z" fill="{HAIR}"/>')
        g.append('<path d="M15 12 Q22 4 29 12" fill="none" stroke="#5B3A1E" stroke-width="1.6"/>')
    g.append('</g>')
    return ''.join(g)


def kit_boot(cx, cy, nail=False):
    """The boot turned sole up: thick rubber, lugs, heel."""
    g = [f'<g transform="translate({cx} {cy})">']
    g.append('<ellipse cx="0" cy="4" rx="30" ry="46" fill="#000000" opacity="0.22"/>')
    g.append('<path d="M-22 -30 C-24 -46 -10 -48 0 -48 C10 -48 24 -46 22 -30 C21 -14 24 4 22 14 C20 22 14 24 13 30 L18 36 C20 44 14 50 0 50 C-14 50 -20 44 -18 36 L-13 30 C-14 24 -20 22 -22 14 C-24 4 -21 -14 -22 -30 Z" fill="url(#bootSole)" stroke="#090D14" stroke-width="2"/>')
    for y in (-38, -26, -14, -2, 10):
        g.append(f'<path d="M-12 {y + 4} L0 {y} L12 {y + 4} L10 {y + 9} L0 {y + 5} L-10 {y + 9} Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="0.9"/>')
    g.append('<rect x="-10" y="18" width="20" height="10" rx="2" fill="#1F2937" stroke="#0B0E14" stroke-width="1"/>')
    g.append('<path d="M-14 38 C-14 46 -6 47 0 47 C6 47 14 46 14 38 L12 33 C6 38 -6 38 -12 33 Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1"/>')
    if nail:
        g.append('<ellipse cx="3" cy="-12" rx="8" ry="6" fill="url(#steel)" stroke="#334155" stroke-width="1.4"/>')
        g.append('<ellipse cx="2" cy="-13" rx="5" ry="3.5" fill="none" stroke="#FFFFFF" stroke-width="1" opacity="0.9"/>')
        g.append(f'<circle cx="3" cy="-12" r="1.6" fill="{DARK}"/>')
        g.append('<path d="M-9 -9 Q3 -4 15 -10" stroke="#000000" stroke-width="2" fill="none"/>')
    g.append('</g>')
    return ''.join(g)


def kit_glove(cx, cy, leak=False):
    """The rubber glove rolled at the cuff and full of air (the air test)."""
    g = [f'<g transform="translate({cx} {cy})">']
    g.append('<ellipse cx="0" cy="6" rx="32" ry="40" fill="#000000" opacity="0.22"/>')
    g.append(f'<path d="M-24 26 C-32 4 -30 -22 -16 -34 C-10 -38 -4 -40 0 -40 C4 -40 10 -38 16 -34 C30 -22 32 4 24 26 Z" fill="{GLOVE}" stroke="{GLOVE_S}" stroke-width="1.8"/>')
    for fx, top in ((-15, -52), (-5, -58), (6, -56), (16, -48)):
        g.append(f'<path d="M{fx - 5} -34 Q{fx - 5} {top} {fx} {top} Q{fx + 5} {top} {fx + 5} -34" fill="{GLOVE}" stroke="{GLOVE_S}" stroke-width="1.4"/>')
    g.append(f'<ellipse cx="-8" cy="-12" rx="7" ry="16" fill="{GLOVE_H}" opacity="0.55"/>')
    g.append(f'<ellipse cx="0" cy="27" rx="26" ry="7" fill="{CUFF}" stroke="#7C2D12" stroke-width="1.4"/>')
    g.append(f'<ellipse cx="0" cy="33" rx="28" ry="8" fill="{DARK}" stroke="{INK}" stroke-width="1.2"/>')
    if leak:
        g.append(f'<circle cx="12" cy="-8" r="1.8" fill="{INK}"/>')
        for r in (5, 9, 13):
            g.append(f'<path d="M{12 + r * 0.5} {-8 - r} Q{12 + r * 1.2} -8 {12 + r * 0.5} {-8 + r}" fill="none" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>')
    g.append('</g>')
    return ''.join(g)


def kit_card(layout='a', flaw=None):
    a = layout == 'a'
    spots = {'helmet': (56, 66), 'shirt': (146, 62), 'boot': (52, 158), 'glove': (148, 160)}
    if not a:
        spots = {'helmet': (146, 66), 'shirt': (54, 62), 'boot': (148, 158), 'glove': (52, 160)}
    return ''.join([
        bench(),
        kit_shirt(*spots['shirt'], poly=flaw == 'poly'),
        kit_helmet(*spots['helmet'], crack=flaw == 'crack'),
        kit_boot(*spots['boot'], nail=flaw == 'nail'),
        kit_glove(*spots['glove'], leak=flaw == 'leak'),
    ])


# =============================================================================
# Round 2 — the harness on him (lesson 1.4)
# =============================================================================

def strap(x0, y0, x1, y1, w=16):
    """A webbing strap from (x0,y0) to (x1,y1) with its stitch line."""
    dx, dy = x1 - x0, y1 - y0
    ln = math.hypot(dx, dy) or 1
    px, py = -dy / ln * w / 2, dx / ln * w / 2
    pts = f'{n(x0 + px)} {n(y0 + py)} {n(x1 + px)} {n(y1 + py)} {n(x1 - px)} {n(y1 - py)} {n(x0 - px)} {n(y0 - py)}'
    return (f'<polygon points="{pts}" fill="url(#webO)" stroke="{WEB_D}" stroke-width="1.4"/>'
            f'<line x1="{n(x0)}" y1="{n(y0)}" x2="{n(x1)}" y2="{n(y1)}" stroke="#FFFFFF" stroke-width="1.2" stroke-dasharray="4 2.5" opacity="0.8"/>')


def harness_card(kind):
    """kind: snug, tail, loose, high, twisted, frayed, label."""
    g = []
    # torso and neck
    g.append(f'<rect x="84" y="0" width="32" height="40" fill="{SKIN_D}"/>')
    g.append('<path d="M6 220 L6 70 Q20 34 70 30 L130 30 Q180 34 194 70 L194 220 Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M78 30 L100 54 L122 30" fill="none" stroke="{SHIRT_L}" stroke-width="2"/>')
    g.append(f'<line x1="100" y1="54" x2="100" y2="220" stroke="{SHIRT_L}" stroke-width="1.4" opacity="0.6"/>')
    chest_y = 70 if kind == 'high' else 116
    # shoulder straps
    if kind == 'twisted':
        g.append(strap(64, 30, 60, 84))
        g.append('<polygon points="52 84 68 84 64 104 56 104" fill="url(#webBack)" stroke="#7C2D12" stroke-width="1.4"/>')
        g.append('<path d="M52 84 L68 104 M68 84 L52 104" stroke="#7C2D12" stroke-width="1.2"/>')
        g.append(strap(60, 104, 58, 220))
    else:
        g.append(strap(64, 30, 58, 220))
    g.append(strap(136, 30, 142, 220))
    if kind == 'frayed':
        # a cut through half the webbing, the fibres sticking out of it
        g.append('<path d="M53 62 L62 70 L55 76 L63 84 L54 90 L51 90 L50 62 Z" fill="url(#shirt)" stroke="#5B2A0B" stroke-width="1.6"/>')
        for fx, fy in ((54, 64), (58, 70), (56, 76), (59, 82), (55, 88)):
            g.append(f'<line x1="{fx}" y1="{fy}" x2="{fx - 9}" y2="{fy - 4}" stroke="#FFFFFF" stroke-width="1.3" stroke-linecap="round"/>')
            g.append(f'<line x1="{fx}" y1="{fy}" x2="{fx - 8}" y2="{fy + 3}" stroke="#FFB070" stroke-width="1.2" stroke-linecap="round"/>')
        g.append('<path d="M137 150 L145 158 L138 164" fill="none" stroke="#5B2A0B" stroke-width="1.6"/>')
    # chest strap and buckle
    if kind == 'loose':
        g.append(strap(60, 116, 80, 150, 14))
        g.append(strap(140, 116, 124, 156, 14))
        g.append('<rect x="74" y="146" width="14" height="18" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.4"/>')
        g.append('<rect x="118" y="152" width="14" height="18" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.4"/>')
    else:
        g.append(strap(60, chest_y, 140, chest_y, 14))
        g.append(f'<rect x="90" y="{chest_y - 12}" width="20" height="24" rx="3.5" fill="url(#steel)" stroke="#334155" stroke-width="1.6"/>')
        g.append(f'<rect x="96" y="{chest_y - 7}" width="8" height="14" rx="2" fill="{DARK}"/>')
    # waist belt with its buckle
    g.append(strap(6, 196, 194, 196, 14))
    g.append('<rect x="90" y="186" width="20" height="20" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.4"/>')
    # his hand
    if kind == 'snug':
        g.append(f'<rect x="126" y="134" width="30" height="34" rx="6" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        for fy in (140, 147, 154, 161):
            g.append(f'<line x1="129" y1="{fy}" x2="153" y2="{fy}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        g.append(strap(136, 128, 142, 172))
    elif kind == 'tail':
        g.append(f'<rect x="104" y="{chest_y + 4}" width="26" height="22" rx="6" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        for fx in (110, 116, 122):
            g.append(f'<line x1="{fx}" y1="{chest_y + 7}" x2="{fx}" y2="{chest_y + 24}" stroke="{SKIN_D}" stroke-width="1.3"/>')
    elif kind in ('loose', 'high'):
        hy = 158 if kind == 'loose' else chest_y + 4
        g.append(f'<rect x="104" y="{hy}" width="26" height="22" rx="6" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        for fx in (110, 116, 122):
            g.append(f'<line x1="{fx}" y1="{hy + 3}" x2="{fx}" y2="{hy + 20}" stroke="{SKIN_D}" stroke-width="1.3"/>')
    elif kind == 'twisted':
        g.append(f'<rect x="126" y="134" width="30" height="34" rx="6" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        for fy in (140, 147, 154, 161):
            g.append(f'<line x1="129" y1="{fy}" x2="153" y2="{fy}" stroke="{SKIN_D}" stroke-width="1.4"/>')
        g.append(strap(136, 128, 142, 172))
    elif kind == 'label':
        # The label hanging off the belt, held up against the calendar on the van wall.
        g.append('<rect x="22" y="128" width="58" height="50" rx="4" fill="url(#paper)" stroke="#94A3B8" stroke-width="1.4"/>')
        g.append(f'<rect x="22" y="128" width="58" height="12" rx="4" fill="{RED}"/>')
        g.append(f'<text x="51" y="166" text-anchor="middle" font-family="sans-serif" font-size="17" font-weight="700" fill="{DARK}">2026</text>')
        g.append('<rect x="130" y="128" width="54" height="44" rx="3" fill="url(#paper)" stroke="#94A3B8" stroke-width="1.4"/>')
        g.append(f'<text x="157" y="146" text-anchor="middle" font-family="sans-serif" font-size="11" font-weight="700" fill="{DARK}">EXP</text>')
        g.append(f'<text x="157" y="164" text-anchor="middle" font-family="sans-serif" font-size="15" font-weight="700" fill="{RED}">2023</text>')
        g.append('<path d="M142 196 L150 172" stroke="#94A3B8" stroke-width="1.4"/>')
    return ''.join(g)


# =============================================================================
# Tools on the tarp (lessons 1.5, 1.10) — step 29 only
# =============================================================================

def tool_card(kind):
    """kind: ok, cracked (the rod's stick), pvc (a PVC jugaad for a rod)."""
    g = []
    g.append(''.join(f'<path d="M0 {y} L200 {y - 30}" stroke="#244F78" stroke-width="1" opacity="0.6"/>' for y in (60, 130, 200, 270)))
    # tool bag, open, the tools standing in it
    g.append('<path d="M28 150 L92 150 L86 206 L34 206 Z" fill="#D97706" stroke="#92400E" stroke-width="2"/>')
    g.append('<ellipse cx="60" cy="150" rx="32" ry="8" fill="#B45309" stroke="#92400E" stroke-width="1.6"/>')
    g.append('<rect x="40" y="118" width="7" height="34" rx="2" fill="url(#steel)"/>')
    g.append(f'<rect x="52" y="110" width="6" height="42" rx="2" fill="{YELLOW}"/>')
    g.append('<rect x="63" y="122" width="8" height="30" rx="2" fill="url(#steel)"/>')
    g.append(f'<path d="M74 152 L80 120 L86 124 L80 152 Z" fill="{RED}"/>')
    g.append(f'<path d="M30 150 Q60 120 90 150" fill="none" stroke="{INK}" stroke-width="3"/>')
    # the discharge rod across the tarp: hook, stick (or PVC), copper lead, clamp
    if kind == 'pvc':
        g.append('<path d="M20 70 L176 30" stroke="url(#pvc)" stroke-width="11" stroke-linecap="round"/>')
        g.append('<path d="M20 70 L176 30" stroke="#6B7280" stroke-width="1" opacity="0.6"/>')
        g.append('<path d="M168 28 L184 22 Q194 20 192 30 Q190 38 182 34" fill="none" stroke="url(#steel)" stroke-width="4" stroke-linecap="round"/>')
        g.append(f'<path d="M160 26 L172 23 M162 36 L174 33" stroke="{INK}" stroke-width="3"/>')
    else:
        for i, (x0, x1) in enumerate(((20, 72), (72, 124), (124, 172))):
            y0 = 70 - (x0 - 20) * 40 / 156
            y1 = 70 - (x1 - 20) * 40 / 156
            g.append(f'<path d="M{x0} {n(y0)} L{x1} {n(y1)}" stroke="url(#glass)" stroke-width="10" stroke-linecap="round"/>')
            g.append(f'<path d="M{x1 - 2} {n(y1 - 8)} L{x1 + 2} {n(y1 + 8)}" stroke="{HANDLE}" stroke-width="3"/>')
        g.append('<path d="M168 30 L184 22 Q194 20 192 30 Q190 38 182 34" fill="none" stroke="url(#steel)" stroke-width="4" stroke-linecap="round"/>')
        if kind == 'cracked':
            g.append(f'<path d="M96 52 L101 58 L95 62 L102 68" fill="none" stroke="{HAIR}" stroke-width="2" stroke-linejoin="round"/>')
            g.append(f'<path d="M101 58 L110 55 M95 62 L88 64" stroke="{HAIR}" stroke-width="1.2"/>')
    g.append('<path d="M24 74 Q60 112 120 100 Q160 92 172 118" fill="none" stroke="#C26A2E" stroke-width="3.4"/>')
    g.append('<rect x="164" y="114" width="18" height="16" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.4"/>')
    return ''.join(g)


# =============================================================================
# Round 3 — him at the pole, the permit and his state of mind (1.6, 1.10)
# =============================================================================

def permit_board(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({n(x)} {n(y)}) rotate({rot}) scale({s})">'
            '<rect x="-22" y="-28" width="44" height="56" rx="4" fill="url(#board)" stroke="#451A03" stroke-width="1.4"/>'
            '<rect x="-18" y="-22" width="36" height="46" rx="2" fill="url(#paper)"/>'
            '<rect x="-8" y="-31" width="16" height="7" rx="2" fill="url(#steel)"/>'
            + ''.join(f'<rect x="-14" y="{yy}" width="28" height="3" rx="1" fill="#334155" opacity="0.6"/>' for yy in (-16, -10, -4, 2))
            + f'<path d="M-14 13 Q-8 8 -2 14 Q4 8 8 13" fill="none" stroke="{SIGN}" stroke-width="1.6" stroke-linecap="round"/>'
            f'<circle cx="11" cy="16" r="5" fill="{RED}" fill-opacity="0.85"/>'
            '</g>')


def mind_card(kind):
    """kind: signed, calm, phone, rushed, tired, pocket."""
    g = []
    g.append('<rect y="176" width="200" height="44" fill="url(#ground)"/>')
    g.append(f'<line x1="0" y1="176" x2="200" y2="176" stroke="{GROUND_L}" stroke-width="2"/>')
    g.append('<rect x="14" y="0" width="30" height="180" fill="url(#pole)" stroke="#6B7280" stroke-width="1.4"/>')
    g.append('<ellipse cx="160" cy="34" rx="22" ry="8" fill="#FFFFFF" opacity="0.7"/>')
    # torso
    g.append('<path d="M60 220 L64 128 Q108 108 152 128 L156 220 Z" fill="url(#shirt)"/>')
    g.append(f'<line x1="108" y1="122" x2="108" y2="220" stroke="{SHIRT_L}" stroke-width="1.2"/>')
    g.append(f'<rect x="120" y="140" width="22" height="18" rx="2" fill="{SHIRT_B}"/>')
    face = {'phone': 'talk', 'rushed': 'tense', 'tired': 'tired'}.get(kind, 'calm')
    tilt = 12 if kind == 'tired' else 0
    g.append(head(108, 84, 2.0, face, tilt))
    if kind in ('signed', 'calm', 'rushed', 'tired'):
        if kind == 'signed':
            g.append(limb((72, 136), (70, 170), (92, 178), SHIRT_B, 14))
            g.append(limb((144, 136), (148, 170), (126, 178), SHIRT_B, 14))
            g.append(permit_board(108, 168, 1.2))
            g.append(hand((88, 186), 7))
            g.append(hand((128, 186), 7))
        elif kind == 'calm':
            g.append(limb((72, 136), (54, 150), (44, 132), SHIRT_B, 14))
            g.append(hand((44, 132), 7))
            g.append(limb((144, 136), (152, 172), (150, 196), SHIRT_B, 14))
            g.append(permit_board(154, 186, 0.9, 8))
            g.append(hand((150, 196), 7))
        elif kind == 'rushed':
            g.append(limb((72, 136), (70, 172), (88, 186), SHIRT_B, 14))
            g.append(permit_board(84, 186, 0.9, -12))
            g.append(hand((88, 194), 7))
            g.append(limb((144, 136), (160, 150), (144, 132), SHIRT_B, 14))
            g.append('<rect x="132" y="124" width="22" height="18" rx="4" fill="url(#steel)" stroke="#1E293B" stroke-width="1.6"/>')
            g.append('<circle cx="143" cy="133" r="6" fill="#FFFFFF"/>')
            g.append(f'<path d="M143 133 L143 128 M143 133 L147 135" stroke="{INK}" stroke-width="1.4" stroke-linecap="round"/>')
            g.append('<circle cx="130" cy="72" r="3" fill="#38BDF8"/>')
            g.append('<circle cx="86" cy="66" r="2.6" fill="#38BDF8"/>')
        elif kind == 'tired':
            g.append(limb((72, 136), (66, 176), (70, 204), SHIRT_B, 14))
            g.append(permit_board(70, 206, 0.9, 24))
            g.append(hand((70, 204), 7))
            g.append(limb((144, 136), (150, 176), (148, 204), SHIRT_B, 14))
            g.append(hand((148, 204), 7))
    elif kind == 'phone':
        g.append(limb((144, 136), (156, 112), (134, 88), SHIRT_B, 14))
        g.append('<rect x="128" y="70" width="14" height="26" rx="3" fill="#0F172A" stroke="url(#steel)" stroke-width="1.4"/>')
        g.append('<rect x="130" y="73" width="10" height="19" rx="1" fill="#38BDF8" opacity="0.85"/>')
        g.append(hand((134, 90), 7))
        g.append(limb((72, 136), (68, 172), (72, 200), SHIRT_B, 14))
        g.append(hand((72, 200), 7))
    elif kind == 'pocket':
        # the permit crumpled into his shirt pocket, unread; already reaching for the pole
        g.append('<path d="M118 146 L116 118 L134 112 L146 120 L142 146 Z" fill="url(#paper)" stroke="#94A3B8" stroke-width="1.4"/>')
        g.append(f'<path d="M120 126 Q126 122 132 128" fill="none" stroke="{SIGN}" stroke-width="1.4"/>')
        g.append(f'<circle cx="136" cy="132" r="4" fill="{RED}" fill-opacity="0.85"/>')
        g.append(f'<rect x="120" y="140" width="22" height="18" rx="2" fill="{SHIRT_B}"/>')
        g.append(limb((72, 136), (54, 150), (44, 132), SHIRT_B, 14))
        g.append(hand((44, 132), 7))
        g.append(limb((144, 136), (152, 172), (150, 196), SHIRT_B, 14))
        g.append(hand((150, 196), 7))
    return ''.join(g)


# =============================================================================
# Round 4 — the pole and the লক্ষ্মণ রেখা (lessons 1.2, 1.3)
# =============================================================================

GY = 188


def pole_top(cx, top=8):
    g = [f'<rect x="{cx - 40}" y="{top + 18}" width="80" height="8" rx="2" fill="url(#steelArm)"/>']
    for ix in (cx - 34, cx + 26):
        g.append(f'<rect x="{ix}" y="{top + 4}" width="8" height="14" rx="3" fill="url(#porcelain)"/>')
    g.append(f'<path d="M0 {top + 6} Q100 {top + 10} 200 {top + 6}" stroke="{WIRE}" stroke-width="2.6" fill="none"/>')
    return ''.join(g)


def rings(x, y, good=True):
    """The hammer's sound: long even rings (sound) or short broken ones (weak)."""
    dash = '' if good else ' stroke-dasharray="3 6"'
    return ''.join(f'<path d="M{x} {y - r} A{r} {r} 0 0 0 {x} {y + r}" stroke="{YELLOW}" stroke-width="2.6" fill="none" stroke-linecap="round"{dash}/>'
                   for r in (10, 18, 26))


LAKSHMAN = '<circle cx="140" cy="{cy}" r="38" fill="none" stroke="' + YELLOW + '" stroke-width="2.2" stroke-dasharray="6 4"/>'


def pole_card(kind):
    """kind: sound, spot, lean, inside, skip, rusted."""
    g = []
    g.append(f'<rect y="{GY}" width="200" height="{H - GY}" fill="url(#ground)"/>')
    g.append(f'<line x1="0" y1="{GY}" x2="200" y2="{GY}" stroke="{GROUND_L}" stroke-width="2"/>')
    cx = 74
    if kind == 'rusted':
        g.append(f'<rect x="{cx - 12}" y="0" width="24" height="{GY}" fill="url(#steelPole)" stroke="#475569" stroke-width="1.4"/>')
        g.append(f'<path d="M{cx - 13} {GY - 34} Q{cx} {GY - 42} {cx + 13} {GY - 32} L{cx + 13} {GY} L{cx - 13} {GY} Z" fill="url(#rust)" stroke="#78350F" stroke-width="1.2"/>')
        g.append(f'<ellipse cx="{cx - 3}" cy="{GY - 14}" rx="5" ry="8" fill="#1E1610"/>')
        g.append(pole_top(cx))
    elif kind == 'lean':
        g.append(f'<g transform="rotate(-9 {cx} {GY})">')
        g.append(f'<rect x="{cx - 12}" y="-10" width="24" height="{GY + 10}" fill="url(#pole)" stroke="#6B7280" stroke-width="1.4"/>')
        g.append(pole_top(cx, 4))
        g.append(LAKSHMAN.format(cy=14))
        g.append('</g>')
        g.append(f'<path d="M{cx - 30} {GY + 2} L{cx - 16} {GY + 8} L{cx - 22} {GY + 14} L{cx - 6} {GY + 20} M{cx + 4} {GY + 2} L{cx + 14} {GY + 12} L{cx + 30} {GY + 16}" stroke="{HAIR}" stroke-width="2" fill="none"/>')
        g.append(f'<path d="M{cx - 40} {GY + 1} Q{cx - 10} {GY - 8} {cx + 34} {GY + 3}" stroke="#5B3A1E" stroke-width="3" fill="none"/>')
    else:
        g.append(f'<rect x="{cx - 12}" y="0" width="24" height="{GY}" fill="url(#pole)" stroke="#6B7280" stroke-width="1.4"/>')
        g.append(pole_top(cx))
        if kind == 'skip':
            # spalling at the foot he never looked at, a rebar showing
            g.append(f'<path d="M{cx - 12} {GY - 40} L{cx - 2} {GY - 36} L{cx - 6} {GY - 22} L{cx - 12} {GY - 20} Z" fill="#6B6A64"/>')
            g.append(f'<path d="M{cx - 8} {GY - 38} L{cx - 7} {GY - 22}" stroke="#7A3B1E" stroke-width="2"/>')
            g.append(f'<path d="M{cx + 2} {GY - 60} L{cx + 8} {GY - 46} L{cx + 3} {GY - 34}" stroke="{HAIR}" stroke-width="1.4" fill="none"/>')
            for y in range(GY - 150, GY - 10, 22):
                g.append(f'<rect x="{cx + 12}" y="{y}" width="8" height="3" rx="1" fill="url(#steel)"/>')
    # the লক্ষ্মণ রেখা around the live wire (a worker draws it in his head) —
    # on every pole card, so the dashed ring never marks the clearance cards
    if kind != 'lean':
        g.append(LAKSHMAN.format(cy=18))
    # the worker
    if kind == 'sound':
        g.append(worker(cx + 40, GY, 0.9, 'hammer'))
        g.append(rings(cx - 14, GY - 52, True))
    elif kind == 'rusted':
        g.append(worker(cx + 40, GY, 0.9, 'hammer'))
        g.append(rings(cx - 14, GY - 52, False))
    elif kind == 'lean':
        g.append(worker(cx + 46, GY, 0.9, 'hammer'))
        g.append(rings(cx - 10, GY - 52, False))
    elif kind == 'spot':
        g.append(worker(150, GY, 0.9, 'rod', reach=0.8))
    elif kind == 'inside':
        g.append(worker(166, GY, 0.9, 'rod', reach=1.12))
        g.append('<circle cx="127" cy="36" r="13" fill="url(#flash)"/>')
        g.append('<path d="M138 20 L131 27 L136 30 L128 36" stroke="#38BDF8" stroke-width="2.6" fill="none"/>')
    elif kind == 'skip':
        g.append(worker(cx + 26, GY - 70, 0.9, 'climb'))
    return ''.join(g)


# =============================================================================
# Round 5 — the surroundings, the weather and the way down (1.3, 1.9, 1.10)
# =============================================================================

def site_card(kind):
    """kind: mate, clear, hive, traffic, storm, water, sky (weather clear), blocked."""
    g = []
    storm = kind == 'storm'
    if storm:
        for cx_, cy_, rx_, ry_ in ((40, 30, 50, 26), (120, 24, 60, 30), (186, 40, 40, 24)):
            g.append(f'<ellipse cx="{cx_}" cy="{cy_}" rx="{rx_}" ry="{ry_}" fill="#2D3748"/>')
    else:
        g.append(f'<circle cx="170" cy="30" r="{16 if kind == "sky" else 12}" fill="{SUN}"/>')
        g.append('<ellipse cx="44" cy="34" rx="20" ry="7" fill="#FFFFFF" opacity="0.75"/>')
        if kind == 'sky':
            g.append('<ellipse cx="112" cy="22" rx="18" ry="6" fill="#FFFFFF" opacity="0.75"/>')
    gy = 168
    g.append(f'<rect y="{gy}" width="200" height="{H - gy}" fill="url(#ground)"/>')
    g.append(f'<line x1="0" y1="{gy}" x2="200" y2="{gy}" stroke="{GROUND_L}" stroke-width="2"/>')
    g.append('<rect y="196" width="200" height="24" fill="url(#road)"/>')
    g.append('<path d="M0 208 L200 208" stroke="#FFFFFF" stroke-width="2" stroke-dasharray="14 10"/>')
    # a tree by the road
    g.append(f'<rect x="176" y="128" width="6" height="40" fill="#5B3A1E"/>')
    g.append(f'<circle cx="179" cy="120" r="16" fill="{LEAF}"/>')
    cx = 70
    g.append(f'<rect x="{cx - 9}" y="20" width="18" height="{gy - 20}" fill="url(#pole)" stroke="#6B7280" stroke-width="1.2"/>')
    g.append(pole_top(cx, 16))
    if kind == 'hive':
        g.append(f'<path d="M{cx + 14} 42 Q{cx + 6} 62 {cx + 14} 80 Q{cx + 26} 90 {cx + 38} 80 Q{cx + 46} 62 {cx + 38} 42 Z" fill="url(#board)" stroke="#451A03" stroke-width="1.6"/>')
        for hy in (52, 62, 72):
            g.append(f'<path d="M{cx + 14} {hy} Q{cx + 26} {hy + 4} {cx + 38} {hy}" stroke="{YELLOW}" stroke-width="2" fill="none"/>')
        for bx, by in ((cx + 52, 56), (cx + 4, 70), (cx + 48, 84), (cx + 30, 96), (cx + 58, 70)):
            g.append(f'<ellipse cx="{bx}" cy="{by}" rx="3" ry="2" fill="{INK}"/><circle cx="{bx + 1}" cy="{by - 2}" r="1.6" fill="#FFFFFF" opacity="0.8"/>')
    if kind == 'storm':
        g.append('<circle cx="140" cy="60" r="34" fill="url(#flash)"/>')
        g.append(f'<polygon points="150 10 128 58 144 58 124 108 166 50 146 50" fill="{YELLOW}" stroke="#FFFFFF" stroke-width="1.6"/>')
    if kind == 'water':
        g.append(f'<ellipse cx="{cx + 4}" cy="{gy + 10}" rx="56" ry="11" fill="url(#water)"/>')
        g.append(f'<path d="M{cx - 30} {gy + 8} Q{cx - 20} {gy + 5} {cx - 10} {gy + 8} M{cx + 18} {gy + 12} Q{cx + 28} {gy + 9} {cx + 38} {gy + 12}" stroke="#FFFFFF" stroke-width="1.4" fill="none" opacity="0.8"/>')
    if kind == 'traffic':
        g.append('<path d="M86 210 L100 194 L150 192 L168 200 L178 212 L86 214 Z" fill="url(#car)" stroke="#7F1D1D" stroke-width="1.4"/>')
        g.append('<rect x="104" y="196" width="18" height="8" rx="1.5" fill="url(#steel)"/><rect x="126" y="196" width="20" height="8" rx="1.5" fill="url(#steel)"/>')
        g.append(f'<circle cx="104" cy="214" r="7" fill="{INK}"/><circle cx="160" cy="214" r="7" fill="{INK}"/>')
        g.append('<path d="M182 198 L198 198 M184 206 L200 206" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>')
    if kind == 'blocked':
        # crates and drums stacked hard against the pole: no room to come down or be lowered
        for bx, by, bw, bh in ((cx - 50, gy - 34, 34, 34), (cx + 12, gy - 30, 30, 30), (cx - 40, gy - 62, 30, 28), (cx + 16, gy - 56, 26, 26)):
            g.append(f'<rect x="{bx}" y="{by}" width="{bw}" height="{bh}" fill="url(#board)" stroke="#451A03" stroke-width="1.4"/>')
            g.append(f'<path d="M{bx} {by} L{bx + bw} {by + bh} M{bx + bw} {by} L{bx} {by + bh}" stroke="#451A03" stroke-width="1"/>')
        g.append(f'<rect x="{cx - 14}" y="{gy - 26}" width="20" height="26" rx="3" fill="url(#steelArm)"/>')
    # him at the foot of the pole, about to climb; a mate standing by. The
    # mate also stands by on the hive and water traps, so "two people" never
    # marks the safe card.
    if kind in ('mate', 'hive', 'water'):
        g.append(worker(cx + 30, gy, 0.85, 'stand'))
        g.append(worker(150, gy + 4, 0.85, 'look'))
    elif kind == 'sky':
        g.append(worker(cx + 34, gy, 0.85, 'look'))
    elif kind == 'blocked':
        g.append(worker(cx + 70, gy, 0.85, 'stand'))
    else:
        g.append(worker(cx + 30, gy, 0.85, 'stand'))
    return ''.join(g)


# =============================================================================
# The cards
# =============================================================================

CARDS = {
    # Round 1 — PPE kit (board) · step 29 check 1
    'kit_ok_a': make_card(kit_card('a'), 'url(#bench)'),
    'kit_ok_b': make_card(kit_card('b'), 'url(#bench)'),
    'kit_helmet_crack': make_card(kit_card('a', 'crack'), 'url(#bench)'),
    'kit_nail_sole': make_card(kit_card('b', 'nail'), 'url(#bench)'),
    'kit_glove_leak': make_card(kit_card('a', 'leak'), 'url(#bench)'),
    'kit_polyester': make_card(kit_card('b', 'poly'), 'url(#bench)'),
    # Round 2 — the harness on him (board) · step 29 check 2
    'harness_snug': make_card(harness_card('snug')),
    'harness_tail': make_card(harness_card('tail')),
    'harness_loose_chest': make_card(harness_card('loose')),
    'harness_chest_high': make_card(harness_card('high')),
    'harness_twisted': make_card(harness_card('twisted')),
    'harness_frayed': make_card(harness_card('frayed')),
    'harness_label_expired': make_card(harness_card('label')),
    # Tools (step 29 check 3)
    'tool_ready': make_card(tool_card('ok'), 'url(#tarp)'),
    'tool_rod_cracked': make_card(tool_card('cracked'), 'url(#tarp)'),
    'tool_rod_pvc': make_card(tool_card('pvc'), 'url(#tarp)'),
    # Round 3 — permit and state of mind (board) · step 29 checks 4–5
    'ptw_signed': make_card(mind_card('signed')),
    'mind_calm': make_card(mind_card('calm')),
    'ptw_verbal_phone': make_card(mind_card('phone')),
    'mind_rushed': make_card(mind_card('rushed')),
    'mind_tired': make_card(mind_card('tired')),
    'ptw_no_read': make_card(mind_card('pocket')),
    # Round 4 — pole and লক্ষ্মণ রেখা (board) · step 29 checks 6–7
    'pole_sound': make_card(pole_card('sound')),
    'clearance_spot': make_card(pole_card('spot')),
    'pole_lean': make_card(pole_card('lean')),
    'clearance_inside': make_card(pole_card('inside')),
    'pole_skip_scan': make_card(pole_card('skip')),
    'pole_rusted_base': make_card(pole_card('rusted')),
    # Round 5 — surroundings, weather, the way down (board) · step 29 checks 8–10
    'rescue_mate': make_card(site_card('mate')),
    'site_clear': make_card(site_card('clear')),
    'hazard_beehive': make_card(site_card('hive')),
    'hazard_traffic': make_card(site_card('traffic')),
    'hazard_storm_sky': make_card(site_card('storm'), 'url(#storm)'),
    'hazard_water': make_card(site_card('water')),
    'weather_clear': make_card(site_card('sky')),
    'rescue_blocked': make_card(site_card('blocked')),
}

# Which cards are safe in each board round (mirrors learn_board_pack110.dart).
ROUNDS = {
    'ppe': ({'kit_ok_a', 'kit_ok_b'}, {'kit_helmet_crack', 'kit_nail_sole', 'kit_glove_leak', 'kit_polyester'}),
    'harness_tool': ({'harness_snug', 'harness_tail'}, {'harness_loose_chest', 'harness_chest_high', 'harness_twisted', 'harness_frayed'}),
    'ptw_mind': ({'ptw_signed', 'mind_calm'}, {'ptw_verbal_phone', 'mind_rushed', 'mind_tired', 'ptw_no_read'}),
    'pole_distance': ({'pole_sound', 'clearance_spot'}, {'pole_lean', 'clearance_inside', 'pole_skip_scan', 'pole_rusted_base'}),
    'hazard_rescue': ({'rescue_mate', 'site_clear'}, {'hazard_beehive', 'hazard_traffic', 'hazard_storm_sky', 'hazard_water'}),
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
