"""Picture cards for lesson 6.5 শেখা ("আন্ডারগ্রাউন্ড (UG) কেবিল: লুকানো নেটওয়ার্ক").

python -I tool/m6_board65_art.py .

Writes assets/game/art/m6_board65/*.svg in the clean gradient style of
tool/m5_board55_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the kit boxes carry a drawn cross-section of their cable type,
and the jacket print is drawn as marks, not letters.

What the cards show comes from lesson 6.5 (and the Module 6 rulings) only:
  1. layers: an HT XLPE cable is a many-layered armour — conductor, screens,
     XLPE insulation, the copper metallic screen (the earth fault current's
     path), the steel armour (against blows and digging) and the outer PVC
     jacket (against moisture and chemicals). Safe: the cut end and the
     stepped-back end with every layer whole. Traps: the jacket split (water
     at the crack), the armour gashed, the copper screen wires broken;
  2. kits: XLPE and PILC need their own jointing kit, tools and method. The
     cut end tells the type: XLPE = white insulation, copper screen tape;
     PILC = paper layers inside a dull lead sheath, copper conductor. Each kit
     box carries a drawn cross-section of its cable. Traps: the wrong kit for
     either cable, an overhead joint sleeve beside a UG cable (myth 2);
  3. joint: HV jointing is specialist work needing training and certification,
     done clean and dry. Safe: the jointer with his ID card in a dry, clean pit
     on a tarp; the same jointer under a cover wiping his hands dry first.
     Traps: rain and muddy water on the open joint, dust and sweat, a helper
     with no ID card doing the joint. Every card shows the red isolation tag
     on its stake at the pit edge and a working earth clamped on the cable
     (its lead up the pit wall to a rod): the cable is shut down, proved dead
     and earthed (ruling X1), so the traps are about moisture, dirt and skill
     only;
  4. termination: where the cable rises to a line or a transformer, its end is
     sealed in an end termination kit (moisture out, stress controlled). Safe:
     the riser pole's three sealed terminations; the cable sealed into the
     DTR's cable box (the DTR drawn with no drop-out fuse, ruling M6-2).
     Traps: a bare open end on the pole, the screen cut back with nothing over
     its edge and sparks (stress control tubing missing), a cracked
     termination with water inside (90% of faults are at terminations and
     joints). No worker touches anything;
  5. lay: a new cable (not energised). Safe: a wide gentle bend at the trench
     corner (bending radius respected, no ring drawn), the armour bonded to
     earth at both ends, the jacket print read against the docket. Traps: a
     sharp kink at the trench corner, a sharp bend at the riser foot, the
     armour earthed at one end only (the other end's lead lying loose).

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board65_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board65')
W, H = 200, 220
GY = 198

SHIRT_D = '#174A70'
SHIRT = '#1F5F8F'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
VEST = '#3F7F5A'       # the helper's kurta
VEST_D = '#326649'
LUNGI = '#5C4A7A'
WIRE = '#2B3138'
SEMI = '#24272B'       # semiconducting screen (black)
BED = '#3A3F45'        # inner bedding
ARM_D = '#5E676F'      # armour wire helix lines
COP_D = '#8A4A1E'      # copper screen helix lines
PAPER = '#F4F1E6'
PAPER2 = '#E3D6B2'     # oil-soaked paper
INK = '#4A5560'
BAG = '#6B5B3E'
WATER = '#5FB2E6'
MUD = '#6A5236'
DUST = '#C9B48A'
RAIN = '#5A6670'
TAG = '#D8402F'
EARTHW = '#3E9B4F'
EARTH_Y = '#E8C830'
SPARK = '#FFE45C'
CRACK = '#1A1A1A'
CLOTH = '#F7F7F2'
IDC = '#FFFFFF'
ID_PHOTO = '#3B6EA8'
LANYARD = '#C8352B'
PRINT = '#E9E9E9'
SAND = '#E2CF9C'

DEFS = """<defs>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9C6CF"/><stop offset="0.65" stop-color="#DCE2E4"/><stop offset="1" stop-color="#C9C2B2"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C7CDBF"/><stop offset="1" stop-color="#A9B09E"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="site" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9B184"/><stop offset="1" stop-color="#AE9468"/></linearGradient>
  <linearGradient id="concrete" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9A69C"/><stop offset="1" stop-color="#8E8B82"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B07E4E"/><stop offset="1" stop-color="#8A5F36"/></linearGradient>
  <linearGradient id="soil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A6A45"/><stop offset="1" stop-color="#6E5234"/></linearGradient>
  <linearGradient id="pit" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E4630"/><stop offset="1" stop-color="#4A3724"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="trench" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#7A5C3C"/><stop offset="1" stop-color="#5E4630"/></linearGradient>
  <linearGradient id="jacket" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A4E54"/><stop offset="0.45" stop-color="#2A2D31"/><stop offset="1" stop-color="#16181B"/></linearGradient>
  <linearGradient id="armour" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E4E9EC"/><stop offset="0.5" stop-color="#A9B2B9"/><stop offset="1" stop-color="#6F7880"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0A86A"/><stop offset="0.5" stop-color="#C8743A"/><stop offset="1" stop-color="#94501F"/></linearGradient>
  <linearGradient id="xlpe" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.6" stop-color="#E8ECEE"/><stop offset="1" stop-color="#C9D0D4"/></linearGradient>
  <linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.5" stop-color="#C3CBD1"/><stop offset="1" stop-color="#8E979E"/></linearGradient>
  <linearGradient id="lead" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3AAB6"/><stop offset="0.5" stop-color="#7D8594"/><stop offset="1" stop-color="#5A6170"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="pipe" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F7A80"/><stop offset="0.5" stop-color="#A9B4BA"/><stop offset="1" stop-color="#5E686E"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="shed" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E2A20"/><stop offset="0.5" stop-color="#C9453A"/><stop offset="1" stop-color="#7E241B"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6A3B22"/><stop offset="0.5" stop-color="#A8643E"/><stop offset="1" stop-color="#5E331D"/></linearGradient>
  <linearGradient id="carton" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#D9B98A"/><stop offset="1" stop-color="#B4915F"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2F6FB0"/><stop offset="1" stop-color="#245A90"/></linearGradient>
  <linearGradient id="canopy" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F08A2E"/><stop offset="1" stop-color="#C9661A"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="dust" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#D8C69C"/><stop offset="1" stop-color="#C9B48A" stop-opacity="0"/></radialGradient>
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
# People (the worker of tool/m5_board55_art.py; the helper in a kurta).
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


def _boot(p, face, color=BOOT):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{color}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, helper=False, badge=False):
    """A person: the lineman / jointer (blue shirt, helmet, gloves) or the
    helper (green kurta, lungi, helmet, bare hands). [badge] = an ID card on
    a lanyard on his chest."""
    shirt, shirt_d = ('url(#shirt)', SHIRT_D) if not helper else (VEST, VEST_D)
    sleeve_b, sleeve_f = (SHIRT_D, SHIRT) if not helper else (VEST_D, VEST)
    legs_b, legs_f = (PANTS_D, PANTS) if not helper else (LUNGI, LUNGI)
    hand_c = GLOVE if not helper else SKIN
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, legs_b, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, legs_f, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, sleeve_b, 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    low = 6 if helper else 0
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py + low)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py + low)} Z" fill="{shirt}"/>')
    if not helper:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    else:
        g.append(f'<path d="M{f(sh[0])} {f(sh[1] - 2)} L{f(sh[0])} {f(sh[1] + 10)}" stroke="{shirt_d}" stroke-width="1.2"/>')
    if badge:
        cx, cy = (hip[0] + sh[0]) / 2 + 2 * face, (hip[1] + sh[1]) / 2 - 2
        g.append(f'<path d="M{f(sh[0] - 4)} {f(sh[1] - 1)} L{f(cx)} {f(cy - 3)} L{f(sh[0] + 4)} {f(sh[1] - 1)}" stroke="{LANYARD}" stroke-width="1.1" fill="none"/>')
        g.append(f'<rect x="{f(cx - 3.5)}" y="{f(cy - 3)}" width="7" height="9" rx="1" fill="{IDC}"/>')
        g.append(f'<rect x="{f(cx - 2.2)}" y="{f(cy - 1.6)}" width="4.4" height="3.6" fill="{ID_PHOTO}"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, sleeve_f, 5.4))
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, helper=False, badge=False, gy=GY, crouch=0):
    """A standing (or, with [crouch], a stooping) person at x, feet on gy,
    scaled S about the feet; hands in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x - crouch * 0.3 * face, gy - 30 + crouch * 0.5)
    sh = (x + (1 + crouch * 0.6) * face, gy - 56 + crouch)
    head = (x + (3 + crouch * 0.8) * face, gy - 64 + crouch * 1.1)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, helper, badge)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# The cable.
# --------------------------------------------------------------------------

def helix(x0, x1, cy, r, color, step=4.0, w=0.8):
    """Diagonal helix lines across a layer's exposed band."""
    o = []
    x = x0 + 1
    while x < x1 - 1:
        o.append(f'M{f(x)} {f(cy - r + 0.6)} L{f(min(x + r * 0.6, x1 - 0.5))} {f(cy + r - 0.6)}')
        x += step
    return f'<path d="{" ".join(o)}" stroke="{color}" stroke-width="{w}" fill="none"/>' if o else ''


def cable_side(x0, xe, cy, s=1.0, kind='xlpe', defect=None, prints=False):
    """A cable lying left to right, its right end stepped back layer by layer
    (side view). [kind] xlpe or pilc. [defect]: 'jacket' (split, water),
    'armour' (gashed through to the screen), 'screen' (copper wires broken).
    [prints] = the jacket's printed marking (marks, no letters)."""
    if kind == 'xlpe':
        layers = [  # (radius, exposed length, fill, helix colour)
            (22, None, 'url(#jacket)', None),
            (19.5, 18, 'url(#armour)', ARM_D),
            (16.5, 16, 'url(#copper)', COP_D),
            (14.5, 9, SEMI, None),
            (12.5, 16, 'url(#xlpe)', None),
            (6, 14, 'url(#alu)', None),
        ]
    else:  # PILC: serving, armour, lead sheath, belt paper, core paper, copper
        layers = [
            (22, None, 'url(#jacket)', None),
            (19.5, 14, 'url(#armour)', ARM_D),
            (16.5, 18, 'url(#lead)', None),
            (14.5, 10, PAPER, INK),
            (12, 16, PAPER2, BAG),
            (6, 14, 'url(#copper)', None),
        ]
    total = sum(l[1] for l in layers[1:]) * s
    o = []
    ends = []
    for i, (r, _, fill, _h) in enumerate(layers):
        inner = sum(l[1] for l in layers[i + 1:]) * s
        x1 = xe - inner
        rr = r * s
        start = x0 if i == 0 else xe - total + sum(l[1] for l in layers[1:i]) * s - 2
        o.append(f'<rect x="{f(start)}" y="{f(cy - rr)}" width="{f(x1 - start)}" height="{f(2 * rr)}" rx="{f(min(3, rr / 3))}" fill="{fill}"/>')
        ends.append((start, x1, rr, _h))
    for i, (st, x1, rr, hcol) in enumerate(ends):
        if hcol and i > 0:
            nxt = ends[i + 1][0] if i + 1 < len(ends) else x1
            o.append(helix(max(st, nxt - (layers[i][1] * s)), nxt + 2, cy, rr, hcol, 3.4 * s, 0.7))
    # Strands on the conductor.
    cst, cx1, crr, _ = ends[-1]
    o.append(f'<path d="M{f(cst + 2)} {f(cy - crr / 2)} L{f(cx1 - 1)} {f(cy - crr / 2)} M{f(cst + 2)} {f(cy + crr / 2)} L{f(cx1 - 1)} {f(cy + crr / 2)}" '
             f'stroke="{ARM_D}" stroke-width="0.5"/>')
    jx1 = ends[0][1]
    if prints:
        x = x0 + 8
        while x < jx1 - 12:
            o.append(f'<rect x="{f(x)}" y="{f(cy - 2 * s)}" width="{f(9 * s)}" height="{f(2.2 * s)}" fill="{PRINT}"/>'
                     f'<rect x="{f(x + 11 * s)}" y="{f(cy - 2 * s)}" width="{f(4 * s)}" height="{f(2.2 * s)}" fill="{PRINT}"/>')
            x += 26 * s
    if defect == 'jacket':
        mx = x0 + (jx1 - x0) * 0.45
        o.append(f'<path d="M{f(mx - 16 * s)} {f(cy - 9 * s)} Q{f(mx)} {f(cy - 18 * s)} {f(mx + 16 * s)} {f(cy - 9 * s)} Q{f(mx)} {f(cy - 2 * s)} {f(mx - 16 * s)} {f(cy - 9 * s)} Z" fill="url(#armour)"/>')
        o.append(helix(mx - 12 * s, mx + 12 * s, cy - 9.5 * s, 4 * s, ARM_D, 3 * s, 0.6))
        o.append(f'<path d="M{f(mx - 16 * s)} {f(cy - 9 * s)} Q{f(mx)} {f(cy - 18 * s)} {f(mx + 16 * s)} {f(cy - 9 * s)}" stroke="{CRACK}" stroke-width="1" fill="none"/>')
        for dx, dy in ((-6, -26), (3, -32), (9, -24)):
            o.append(water_drop(mx + dx * s, cy + dy * s, 2.4 * s))
    elif defect == 'armour':
        mx = x0 + (jx1 - x0) * 0.5
        o.append(f'<path d="M{f(mx - 18 * s)} {f(cy - 4 * s)} L{f(mx - 6 * s)} {f(cy - 15 * s)} L{f(mx + 18 * s)} {f(cy - 9 * s)} L{f(mx + 6 * s)} {f(cy + 2 * s)} Z" fill="url(#copper)"/>')
        o.append(helix(mx - 10 * s, mx + 10 * s, cy - 6.5 * s, 5 * s, COP_D, 3 * s, 0.6))
        for k in range(5):
            bx = mx - 12 * s + k * 6 * s
            o.append(f'<path d="M{f(bx)} {f(cy - 13 * s + k)} l{f(-3 * s)} {f(-6 * s)} M{f(bx + 4 * s)} {f(cy - 1 * s)} l{f(3 * s)} {f(5 * s)}" '
                     f'stroke="url(#steel)" stroke-width="{f(1.6 * s)}" stroke-linecap="round"/>')
        o.append(f'<path d="M{f(mx - 18 * s)} {f(cy - 4 * s)} L{f(mx - 6 * s)} {f(cy - 15 * s)} L{f(mx + 18 * s)} {f(cy - 9 * s)} L{f(mx + 6 * s)} {f(cy + 2 * s)} Z" '
                 f'stroke="{CRACK}" stroke-width="0.9" fill="none"/>')
    elif defect == 'screen':
        st, x1, rr, _ = ends[2]
        gx = (st + x1) / 2 + 3 * s
        o.append(f'<rect x="{f(gx - 4 * s)}" y="{f(cy - rr)}" width="{f(8 * s)}" height="{f(2 * rr)}" fill="{SEMI}"/>')
        for k in range(4):
            yy = cy - rr + (k + 0.5) * rr / 2
            o.append(f'<path d="M{f(gx - 4 * s)} {f(yy)} q{f(-3 * s)} {f(-4 * s)} {f(-1 * s)} {f(-8 * s)} M{f(gx + 4 * s)} {f(yy + 2 * s)} q{f(3 * s)} {f(3 * s)} {f(2 * s)} {f(8 * s)}" '
                     f'stroke="url(#copper)" stroke-width="{f(1.3 * s)}" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def cable_end(cx, cy, R, kind='xlpe', defect=None):
    """The cut end of a 3-core cable (end view): jacket, armour, bedding and
    three cores. XLPE core: copper screen, black screen, white insulation,
    aluminium conductor. PILC: lead sheath round paper-insulated cores with
    copper conductors. [defect] 'jacket' = a split in the jacket ring."""
    o = [f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R)}" fill="url(#jacket)"/>',
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.88)}" fill="url(#armour)"/>',
         f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.82)}" fill="none" stroke="{ARM_D}" stroke-width="{f(R * 0.05)}" stroke-dasharray="{f(R * 0.06)} {f(R * 0.04)}"/>']
    if kind == 'pilc':
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.76)}" fill="url(#lead)"/>')
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.68)}" fill="{PAPER}"/>')
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.62)}" fill="none" stroke="{INK}" stroke-width="0.5"/>')
    else:
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(R * 0.76)}" fill="{BED}"/>')
    rc = R * 0.33
    for ang in (90, 210, 330):
        a = math.radians(ang)
        x, y = cx + math.cos(a) * R * 0.36, cy - math.sin(a) * R * 0.36
        if kind == 'pilc':
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc * 0.92)}" fill="{PAPER2}" stroke="{BAG}" stroke-width="0.6"/>')
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc * 0.45)}" fill="url(#copper)"/>')
        else:
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc)}" fill="url(#copper)"/>')
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc * 0.88)}" fill="{SEMI}"/>')
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc * 0.8)}" fill="url(#xlpe)"/>')
            o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(rc * 0.42)}" fill="url(#alu)"/>')
    if defect == 'jacket':
        a0 = math.radians(40)
        px, py = cx + math.cos(a0) * R, cy - math.sin(a0) * R
        ix, iy = cx + math.cos(a0) * R * 0.86, cy - math.sin(a0) * R * 0.86
        o.append(f'<path d="M{f(px - 9)} {f(py - 7)} L{f(ix)} {f(iy)} L{f(px + 7)} {f(py + 9)} Z" fill="url(#armour)" stroke="{CRACK}" stroke-width="0.8"/>')
        o.append(water_drop(px + 6, py - 10, 2.6))
        o.append(water_drop(px + 12, py - 2, 2.2))
    return ''.join(o)


def water_drop(x, y, r):
    return (f'<path d="M{f(x)} {f(y - 2.2 * r)} Q{f(x + r * 1.1)} {f(y - 0.4 * r)} {f(x)} {f(y + r)} Q{f(x - r * 1.1)} {f(y - 0.4 * r)} {f(x)} {f(y - 2.2 * r)} Z" '
            f'fill="{WATER}"/>')


def spark(x, y, s=1.0):
    pts = []
    for i in range(16):
        rr = (9 if i % 2 == 0 else 3.5) * s
        a = math.radians(i * 22.5)
        pts.append(f'{f(x + math.cos(a) * rr)} {f(y + math.sin(a) * rr)}')
    return f'<path d="M{" L".join(pts)} Z" fill="{SPARK}" stroke="{HELMET_D}" stroke-width="0.6"/>'


# --------------------------------------------------------------------------
# Round 1 — layers: a cable sample on the store yard's concrete.
# --------------------------------------------------------------------------

def yard_stage():
    out = card_open('yard')
    out.append(f'<rect y="{GY - 20}" width="{W}" height="{H - GY + 20}" fill="url(#concrete)"/>')
    return out


def layers_card(kind):
    out = yard_stage()
    if kind in ('whole', 'jacket'):
        # The cut end close up, the cable's side below.
        out.append(cable_side(-4, 196, GY - 6, 0.7, defect='jacket' if kind == 'jacket' else None))
        out.append(f'<ellipse cx="100" cy="{GY - 20}" rx="60" ry="6" fill="{CRACK}" opacity="0.18"/>')
        out.append(cable_end(100, 92, 60, defect='jacket' if kind == 'jacket' else None))
    else:
        out.append(f'<ellipse cx="100" cy="{GY - 30}" rx="90" ry="6" fill="{CRACK}" opacity="0.18"/>')
        out.append(cable_end(48, 66, 34))
        out.append(cable_side(-6, 194, 140, 1.5, defect={'stepped': None, 'armour': 'armour', 'screen': 'screen'}[kind]))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — kits: the cut end on the jointer's bench beside a kit box.
# --------------------------------------------------------------------------

def kit_box(x, y, kind):
    """A kit carton; its badge shows the cross-section of its cable type."""
    o = [f'<rect x="{x}" y="{y}" width="62" height="48" rx="3" fill="url(#carton)" stroke="{BAG}" stroke-width="0.8"/>',
         f'<path d="M{x} {y + 10} L{x + 62} {y + 10}" stroke="{BAG}" stroke-width="0.8"/>',
         f'<rect x="{x + 6}" y="{y + 16}" width="18" height="3" rx="1" fill="{BAG}"/>',
         f'<rect x="{x + 6}" y="{y + 23}" width="12" height="3" rx="1" fill="{BAG}"/>']
    o.append(cable_end(x + 42, y + 29, 16, kind))
    return ''.join(o)


def sleeve(x, y):
    """An overhead line's compression joint sleeve with two bare conductor ends."""
    return (f'<path d="M{x - 26} {y} L{x} {y}" stroke="url(#alu)" stroke-width="5" stroke-linecap="round"/>'
            f'<path d="M{x + 44} {y} L{x + 66} {y}" stroke="url(#alu)" stroke-width="5" stroke-linecap="round"/>'
            f'<rect x="{x - 2}" y="{y - 6}" width="48" height="12" rx="5" fill="url(#steel)"/>'
            f'<path d="M{x + 10} {y - 6} v12 M{x + 22} {y - 6} v12 M{x + 34} {y - 6} v12" stroke="{ARM_D}" stroke-width="0.9"/>')


def bench_stage():
    out = card_open('bench')
    out.append(f'<rect y="{GY - 52}" width="{W}" height="{H - GY + 52}" fill="url(#wood)"/>')
    out.append(f'<path d="M0 {GY - 52} L{W} {GY - 52}" stroke="{BAG}" stroke-width="2"/>')
    return out


def kits_card(kind):
    cable, kit = {'xlpe': ('xlpe', 'xlpe'), 'pilc': ('pilc', 'pilc'), 'xlpe_pilc': ('xlpe', 'pilc'),
                  'pilc_xlpe': ('pilc', 'xlpe'), 'sleeve': ('xlpe', None)}[kind]
    out = bench_stage()
    out.append(cable_end(58, 72, 40, cable))
    out.append(cable_side(-6, 128, GY - 22, 1.0, cable))
    if kit:
        out.append(kit_box(128, 92, kit))
    else:
        out.append(sleeve(140, 120))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — joint: the jointing pit, the cable shut down (red tag on a stake).
# --------------------------------------------------------------------------

PIT_TOP = 76


def pit_stage(water=False, tarp=True):
    out = card_open('day')
    out.append(f'<rect y="{PIT_TOP}" width="{W}" height="{H - PIT_TOP}" fill="url(#soil)"/>')
    out.append(f'<rect y="{PIT_TOP - 4}" width="{W}" height="6" fill="url(#ground)"/>')
    out.append(f'<path d="M24 {PIT_TOP + 2} L32 {H} L170 {H} L178 {PIT_TOP + 2} Z" fill="url(#pit)"/>')
    # The red isolation tag on its stake at the pit edge (the cable is shut down).
    out.append(f'<path d="M186 {PIT_TOP} L186 {PIT_TOP - 34}" stroke="{BAG}" stroke-width="2.4"/>')
    out.append(f'<path d="M186 {PIT_TOP - 30} L190 {PIT_TOP - 22}" stroke="{PAPER}" stroke-width="0.9"/>'
               f'<rect x="185" y="{PIT_TOP - 22}" width="10" height="15" rx="1.5" fill="{TAG}"/>'
               f'<circle cx="190" cy="{PIT_TOP - 19}" r="1.3" fill="{PAPER}"/>')
    if tarp:
        out.append(f'<path d="M44 {GY - 4} L156 {GY - 4} L162 {GY + 6} L38 {GY + 6} Z" fill="url(#tarp)"/>')
    if water:
        out.append(f'<path d="M30 {GY - 14} Q100 {GY - 20} 172 {GY - 14} L174 {H} L28 {H} Z" fill="{MUD}" opacity="0.85"/>')
        out.append(f'<path d="M46 {GY - 16} q8 -3 16 0 M128 {GY - 17} q8 -3 16 0" stroke="{WATER}" stroke-width="1.2" fill="none"/>')
    return out


def pit_cable(open_joint=True):
    """The cable along the pit with the joint being made in the middle."""
    cy = GY - 16
    o = [cable_side(-10, 78, cy, 0.62)]
    o.append(f'<g transform="translate(200 0) scale(-1 1)">{cable_side(-10, 78, cy, 0.62)}</g>')
    if open_joint:
        o.append(f'<path d="M78 {cy} L122 {cy}" stroke="url(#alu)" stroke-width="3.6"/>')
        o.append(f'<rect x="92" y="{cy - 3.4}" width="16" height="6.8" rx="2" fill="url(#steel)"/>')
    # Ruling X1: the cable is proved dead and earthed before the joint is made —
    # a working earth clamped on the cable, its lead up the pit wall to a rod.
    # Drawn the same in every joint card, so it never marks the safe one.
    o.append(earth_rod(12, PIT_TOP - 8))
    o.append(earth_lead(f'M40 {cy - 4} C32 {cy - 30} 28 {PIT_TOP + 30} 12 {PIT_TOP - 8}'))
    o.append(f'<rect x="36" y="{cy - 6}" width="8" height="12" rx="1.5" fill="{EARTHW}" stroke="{INK}" stroke-width="0.6"/>')
    return ''.join(o)


def canopy(x0, x1, top):
    return (f'<path d="M{x0} {top + 12} L{(x0 + x1) / 2} {top} L{x1} {top + 12} Z" fill="url(#canopy)"/>'
            f'<path d="M{x0 + 4} {top + 12} L{x0 + 4} {PIT_TOP} M{x1 - 4} {top + 12} L{x1 - 4} {PIT_TOP}" stroke="url(#steel)" stroke-width="2.2"/>')


def canopy_folded(x, y):
    return (f'<rect x="{x}" y="{y}" width="40" height="7" rx="3" fill="url(#canopy)"/>'
            f'<path d="M{x + 2} {y + 10} L{x + 38} {y + 10}" stroke="url(#steel)" stroke-width="2"/>')


def cloth(x, y, hanging=False):
    if hanging:
        return f'<path d="M{x} {y} l6 0 l-1 12 l-5 2 Z" fill="{CLOTH}" stroke="{INK}" stroke-width="0.4"/>'
    return f'<path d="M{x} {y} q6 -4 12 0 q-2 6 -12 4 Z" fill="{CLOTH}" stroke="{INK}" stroke-width="0.4"/>'


def joint_card(kind):
    if kind == 'certified':
        out = pit_stage()
        out.append(pit_cable())
        out.append(person(126, ((104, GY - 18), (96, GY - 14)), face=-1, look=20, badge=True, gy=GY + 8, crouch=10))
    elif kind == 'cover':
        out = pit_stage()
        out.append(canopy(20, 180, 18))
        out.append(pit_cable())
        out.append(person(132, ((122, GY - 50), (114, GY - 54)), face=-1, look=12, badge=True, gy=GY + 8))
        out.append(cloth(112, GY - 58))
    elif kind == 'rain':
        out = pit_stage(water=True)
        out.append(f'<rect width="{W}" height="{PIT_TOP}" fill="{RAIN}" opacity="0.55"/>')
        rain = ' '.join(f'M{x} {y} l-4 10' for x in range(8, 200, 14) for y in (8, 34, 60, 96, 130) if (x + y) % 3)
        out.append(f'<path d="{rain}" stroke="{WATER}" stroke-width="1.2" stroke-linecap="round"/>')
        out.append(canopy_folded(4, PIT_TOP - 12))
        out.append(pit_cable())
        out.append(water_drop(88, GY - 24, 2.2) + water_drop(100, GY - 28, 2) + water_drop(112, GY - 23, 2.2))
        out.append(person(126, ((104, GY - 18), (96, GY - 14)), face=-1, look=20, badge=True, gy=GY + 8, crouch=10))
    elif kind == 'dust':
        out = pit_stage()
        out.append(f'<circle cx="70" cy="{PIT_TOP - 6}" r="40" fill="url(#dust)"/>'
                   f'<circle cx="112" cy="{GY - 40}" r="34" fill="url(#dust)"/>'
                   f'<circle cx="40" cy="{GY - 30}" r="26" fill="url(#dust)"/>')
        for dx, dy in ((8, -6), (30, 4), (60, -12), (84, 8)):
            out.append(f'<circle cx="{40 + dx}" cy="{PIT_TOP - 20 + dy}" r="1.6" fill="{DUST}"/>')
        out.append(pit_cable())
        out.append(person(126, ((104, GY - 18), (96, GY - 14)), face=-1, look=20, badge=True, gy=GY + 8, crouch=10))
        out.append(water_drop(116, 132, 1.8) + water_drop(122, 140, 1.5))
        out.append(cloth(150, PIT_TOP - 8, hanging=False))
    elif kind == 'helper':
        out = pit_stage()
        out.append(pit_cable())
        out.append(person(126, ((104, GY - 18), (96, GY - 14)), face=-1, look=20, helper=True, gy=GY + 8, crouch=10))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — termination: the riser pole and the DTR's cable box.
# --------------------------------------------------------------------------

def sky_stage():
    out = card_open('day')
    out.append(f'<rect y="{GY - 6}" width="{W}" height="{H - GY + 6}" fill="url(#ground)"/>')
    return out


def termination(x, top, s=1.0, cracked=False):
    """One sealed end termination: a red heat-shrink body with sheds, a lug."""
    o = [f'<rect x="{f(x - 3 * s)}" y="{f(top)}" width="{f(6 * s)}" height="{f(40 * s)}" rx="2" fill="url(#shed)"/>']
    for k in range(3):
        y = top + (10 + k * 9) * s
        o.append(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(8 * s)}" ry="{f(2.6 * s)}" fill="url(#shed)"/>')
    o.append(f'<rect x="{f(x - 2.5 * s)}" y="{f(top - 7 * s)}" width="{f(5 * s)}" height="{f(8 * s)}" rx="1" fill="url(#alu)"/>')
    if cracked:
        o.append(f'<path d="M{f(x - 7 * s)} {f(top + 8 * s)} l{f(5 * s)} {f(5 * s)} l{f(-3 * s)} {f(6 * s)} l{f(5 * s)} {f(6 * s)} l{f(-2 * s)} {f(6 * s)} l{f(4 * s)} {f(5 * s)}" stroke="{CRACK}" stroke-width="1.6" fill="none"/>')
        o.append(water_drop(x + 1 * s, top + 22 * s, 2 * s) + water_drop(x - 1 * s, top + 34 * s, 1.8 * s))
    return ''.join(o)


def bare_core(x, top, s=1.0, sparks=False):
    """A core cut back with nothing over it: white insulation, the black
    screen ending, the bare conductor at the top."""
    o = [f'<rect x="{f(x - 3 * s)}" y="{f(top + 22 * s)}" width="{f(6 * s)}" height="{f(18 * s)}" fill="{SEMI}"/>',
         f'<rect x="{f(x - 2.4 * s)}" y="{f(top + 4 * s)}" width="{f(4.8 * s)}" height="{f(18 * s)}" fill="url(#xlpe)"/>',
         f'<rect x="{f(x - 1.4 * s)}" y="{f(top - 6 * s)}" width="{f(2.8 * s)}" height="{f(10 * s)}" fill="url(#alu)"/>']
    if sparks:
        o.append(spark(x, top + 22 * s, 0.75 * s))
    return ''.join(o)


def riser_pole(ends='sealed'):
    """The riser pole: crossarm and line on top, the cable up its side in a
    guard pipe, then its three ends on a bracket."""
    o = [f'<rect x="96" y="10" width="9" height="{GY - 10}" fill="url(#pole)"/>',
         f'<rect x="56" y="22" width="90" height="5" fill="url(#steel)"/>',
         f'<path d="M0 18 L200 16 M0 30 L200 28" stroke="{WIRE}" stroke-width="1.3"/>',
         f'<rect x="108" y="96" width="10" height="{GY - 96}" fill="url(#pipe)"/>',
         f'<path d="M113 96 Q113 88 104 86 L64 86" stroke="url(#jacket)" stroke-width="7" fill="none"/>',
         f'<rect x="52" y="76" width="66" height="4" fill="url(#steel)"/>']
    for x in (64, 82, 100):
        if ends == 'bare':
            o.append(bare_core(x + 12, 42, 1.0))
        else:
            o.append(termination(x + 12, 40, 1.0, cracked=(ends == 'cracked' and x == 82)))
        o.append(f'<path d="M{x + 12} {33} L{x + 4} 18" stroke="{WIRE}" stroke-width="1.1"/>')
    if ends == 'bare':
        o.append(water_drop(78, 60, 2.2) + water_drop(96, 54, 2))
    return ''.join(o)


def dtr_box(ends='sealed'):
    """A pole-mounted style DTR on its plinth (no drop-out fuse): the cable
    rises from the ground into the HT cable box on its side."""
    o = [f'<rect x="96" y="{GY - 16}" width="96" height="12" fill="url(#concrete)"/>',
         f'<rect x="110" y="{GY - 82}" width="66" height="66" rx="4" fill="url(#tank)"/>']
    for k in range(5):
        o.append(f'<rect x="{114 + k * 12}" y="{GY - 74}" width="5" height="50" rx="2" fill="url(#tank)" stroke="#5E7766" stroke-width="0.6"/>')
    for k in range(3):
        o.append(f'<rect x="{124 + k * 16}" y="{GY - 100}" width="6" height="18" rx="2" fill="url(#porcelain)"/>')
    o.append(f'<rect x="54" y="{GY - 92}" width="56" height="36" rx="3" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    o.append(f'<rect x="78" y="{GY - 56}" width="10" height="50" fill="url(#pipe)"/>')
    for k, x in enumerate((64, 82, 100)):
        if ends == 'bare':
            o.append(bare_core(x - 4, GY - 132, 1.0, sparks=(k == 1)))
        else:
            o.append(termination(x - 4, GY - 134, 1.0))
        o.append(f'<path d="M{x - 4} {GY - 141} Q{x + 30} {GY - 150} {127 + k * 16} {GY - 100}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    o.append(f'<path d="M54 {GY - 92} L110 {GY - 92}" stroke="{INK}" stroke-width="0.6"/>')
    return ''.join(o)


def term_card(kind):
    out = sky_stage()
    if kind == 'pole':
        out.append(riser_pole('sealed'))
    elif kind == 'bare':
        out.append(riser_pole('bare'))
    elif kind == 'cracked':
        out.append(riser_pole('cracked'))
    elif kind == 'dtr':
        out.append(dtr_box('sealed'))
    elif kind == 'stress':
        out.append(dtr_box('bare'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — lay: a new cable, not yet energised, going into its trench.
# --------------------------------------------------------------------------

def site_stage():
    return card_open('site')


def trench_corner(sharp=False, worker=False):
    """Top view of an L-shaped trench on a sand bed, the cable turning the corner."""
    o = [f'<path d="M0 54 L150 54 L150 220 L110 220 L110 94 L0 94 Z" fill="url(#trench)"/>',
         f'<path d="M0 64 L140 64 L140 220 L120 220 L120 84 L0 84 Z" fill="{SAND}" opacity="0.85"/>']
    if sharp:
        o.append(f'<path d="M0 74 L130 74 L130 220" stroke="url(#jacket)" stroke-width="9" fill="none" stroke-linejoin="miter"/>')
    else:
        o.append(f'<path d="M0 74 L84 74 Q130 74 130 120 L130 220" stroke="url(#jacket)" stroke-width="9" fill="none"/>')
    if worker:
        o.append(person(176, ((150, 132), (156, 128)), face=-1, look=10))
    return ''.join(o)


def earth_lead(d):
    return (f'<path d="{d}" stroke="{EARTHW}" stroke-width="2.6" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_rod(x, y):
    return (f'<rect x="{x - 2}" y="{y}" width="4" height="30" fill="url(#steel)"/>'
            f'<rect x="{x - 5}" y="{y - 3}" width="10" height="5" rx="1.5" fill="url(#steel)"/>')


def armour_clamp(x, y):
    return f'<rect x="{x - 4}" y="{y - 9}" width="8" height="18" rx="2" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>'


def span(both=True):
    """Side view of a cable laid in its trench, each end's armour exposed;
    [both] bonded to earth at both ends, else the far end's lead lies loose."""
    cy = 118
    o = [f'<rect y="132" width="{W}" height="{H - 132}" fill="url(#trench)"/>',
         f'<rect y="126" width="{W}" height="12" fill="{SAND}"/>',
         f'<rect x="24" y="{cy - 7}" width="152" height="14" rx="3" fill="url(#jacket)"/>',
         f'<rect x="12" y="{cy - 6}" width="14" height="12" fill="url(#armour)"/>',
         f'<rect x="174" y="{cy - 6}" width="14" height="12" fill="url(#armour)"/>',
         helix(12, 26, cy, 6, ARM_D, 3, 0.6), helix(174, 188, cy, 6, ARM_D, 3, 0.6),
         f'<rect x="4" y="{cy - 3}" width="10" height="6" fill="url(#xlpe)"/>',
         f'<rect x="186" y="{cy - 3}" width="10" height="6" fill="url(#xlpe)"/>']
    o.append(armour_clamp(19, cy))
    o.append(earth_lead(f'M19 {cy + 9} L19 150 L36 160'))
    o.append(earth_rod(36, 158))
    o.append(earth_rod(164, 158))
    if both:
        o.append(armour_clamp(181, cy))
        o.append(earth_lead(f'M181 {cy + 9} L181 150 L164 160'))
    else:
        o.append(earth_lead('M164 160 Q150 150 140 160 Q128 168 120 160'))
    return ''.join(o)


def clipboard(x, y, s=1.0):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(30 * s)}" height="{f(38 * s)}" rx="2" fill="{BAG}"/>'
            f'<rect x="{f(x + 3 * s)}" y="{f(y + 5 * s)}" width="{f(24 * s)}" height="{f(30 * s)}" fill="{PAPER}"/>'
            f'<rect x="{f(x + 10 * s)}" y="{f(y + 2 * s)}" width="{f(10 * s)}" height="{f(5 * s)}" rx="1" fill="url(#steel)"/>'
            + ''.join(f'<path d="M{f(x + 6 * s)} {f(y + (12 + i * 5) * s)} h{f(18 * s - (i % 2) * 5)}" stroke="{INK}" stroke-width="0.8"/>' for i in range(4)))


def drum(x, y, r=40):
    """A cable drum standing on the ground, the printed cable wound on it."""
    o = [f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#wood)" stroke="{BAG}" stroke-width="1.2"/>',
         f'<circle cx="{x}" cy="{y}" r="{r * 0.72}" fill="url(#jacket)"/>']
    for k in range(4):
        rr = r * (0.66 - k * 0.1)
        o.append(f'<circle cx="{x}" cy="{y}" r="{f(rr)}" fill="none" stroke="{PRINT}" stroke-width="1" stroke-dasharray="5 9" opacity="0.8"/>')
    o.append(f'<circle cx="{x}" cy="{y}" r="{r * 0.22}" fill="url(#wood)"/>')
    o.append(f'<circle cx="{x}" cy="{y}" r="{r * 0.08}" fill="url(#steel)"/>')
    return ''.join(o)


def lay_card(kind):
    out = site_stage()
    if kind == 'bend':
        out.append(trench_corner(sharp=False))
    elif kind == 'kink':
        out.append(trench_corner(sharp=True, worker=True))
    elif kind == 'bond':
        out.append(span(both=True))
    elif kind == 'oneend':
        out.append(span(both=False))
        out.append(clipboard(84, 160, 0.9))
    elif kind == 'print':
        out.append(f'<rect y="{GY - 10}" width="{W}" height="{H - GY + 10}" fill="url(#trench)"/>')
        out.append(drum(62, GY - 52, 46))
        out.append(f'<rect x="62" y="{GY - 17}" width="150" height="14" rx="3" fill="url(#jacket)"/>')
        out.append(''.join(f'<rect x="{x}" y="{GY - 11}" width="12" height="2.4" fill="{PRINT}"/>'
                           f'<rect x="{x + 15}" y="{GY - 11}" width="5" height="2.4" fill="{PRINT}"/>' for x in range(96, 200, 30)))
        out.append(person(150, ((132, GY - 30), (128, GY - 46)), face=-1, look=20, crouch=8))
        out.append(clipboard(116, GY - 70, 0.8))
    elif kind == 'riser':
        out.append(f'<rect y="{GY - 10}" width="{W}" height="{H - GY + 10}" fill="url(#trench)"/>')
        out.append(drum(40, GY - 46, 40))
        out.append(f'<rect x="150" y="0" width="10" height="{GY - 10}" fill="url(#pole)"/>')
        out.append(f'<rect x="138" y="70" width="10" height="{GY - 80}" fill="url(#pipe)"/>')
        out.append(f'<path d="M40 {GY - 6} L143 {GY - 6} L143 {GY - 20}" stroke="url(#jacket)" stroke-width="9" fill="none" stroke-linejoin="miter"/>')
        out.append(person(104, ((124, GY - 30), (128, GY - 26)), face=1, look=10))
    return card_close(out)


CARDS = {
    'layers_whole': layers_card('whole'),
    'layers_stepped': layers_card('stepped'),
    'layers_jacket': layers_card('jacket'),
    'layers_armour': layers_card('armour'),
    'layers_screen': layers_card('screen'),
    'kits_xlpe': kits_card('xlpe'),
    'kits_pilc': kits_card('pilc'),
    'kits_xlpe_pilc': kits_card('xlpe_pilc'),
    'kits_pilc_xlpe': kits_card('pilc_xlpe'),
    'kits_sleeve': kits_card('sleeve'),
    'joint_certified': joint_card('certified'),
    'joint_cover': joint_card('cover'),
    'joint_rain': joint_card('rain'),
    'joint_dust': joint_card('dust'),
    'joint_helper': joint_card('helper'),
    'term_pole': term_card('pole'),
    'term_dtr': term_card('dtr'),
    'term_bare': term_card('bare'),
    'term_stress': term_card('stress'),
    'term_cracked': term_card('cracked'),
    'lay_bend': lay_card('bend'),
    'lay_bond': lay_card('bond'),
    'lay_print': lay_card('print'),
    'lay_kink': lay_card('kink'),
    'lay_riser': lay_card('riser'),
    'lay_oneend': lay_card('oneend'),
}

# Safe cards and traps per round (mirrors learn_board_pack65.dart).
ROUNDS = {
    'layers': (['layers_whole', 'layers_stepped'], ['layers_jacket', 'layers_armour', 'layers_screen']),
    'kits': (['kits_xlpe', 'kits_pilc'], ['kits_xlpe_pilc', 'kits_pilc_xlpe', 'kits_sleeve']),
    'joint': (['joint_certified', 'joint_cover'], ['joint_rain', 'joint_dust', 'joint_helper']),
    'term': (['term_pole', 'term_dtr'], ['term_bare', 'term_stress', 'term_cracked']),
    'lay': (['lay_bend', 'lay_bond', 'lay_print'], ['lay_kink', 'lay_riser', 'lay_oneend']),
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
