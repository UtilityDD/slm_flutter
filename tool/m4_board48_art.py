"""Picture cards for lesson 4.8 শেখা ("গাছের ডালপালা ছাঁটা (Tree Trimming)").

python -I tool/m4_board48_art.py .

Writes assets/game/art/m4_board48/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 4.8 and its film script only:
  1. why: a branch broken in a storm falls on the line (short circuit / a
     snapped wire); constant rubbing wears the insulation of a service / AB
     cable; wet leaves touching two live wires short them; a dry branch on a
     live wire can catch fire. Safe = the tree trimmed back, a clear gap.
  2. plan: a branch very close to the line -> shutdown on a PTW before work
     (the earth leads on the wires are the house rule "test and earth"; the
     lesson says only "de-energise on a PTW"); the area below roped / taped
     off; never alone: a coworker below controls the traffic.
  3. tool: long insulated (fibreglass) pruner or saw for small branches; a
     chainsaw for big ones, held in both hands (kickback); strong gloves and
     goggles besides the standard PPE.
  4. cut: the 3-cut method — 1) a small cut under the branch a little away
     from the trunk, 2) the top cut just outside it brings the branch down
     without tearing the bark, 3) the finish cut just outside the collar; a
     rope controls where the branch falls.
  5. trim: topping (rounding off the crown) is forbidden; directional pruning
     cuts only the branches growing towards the line; V-trim when the line
     runs over the tree; felling only for a dead / rotten / dangerous tree
     (and only with written permission); 1.5–3 m clearance from conductors.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps).
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board48_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board48')
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
GOGGLE = '#7FD3F0'
WIRE = '#2B3138'
COPPER = '#D98A3D'
EARTH = '#3E9B4F'
WOOD = '#E8C99A'
BARK = '#6B4A2F'
DRY = '#9C7A4E'
TAPE_R = '#E0352B'
FIBRE = '#F2A32E'
SAW = '#E8742A'
FLAG = '#E0352B'
RAIN = '#9FD0F5'
CIVIL = '#B0476A'
TRUCK = '#3F8F8A'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E8F0"/></linearGradient>
  <linearGradient id="storm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5C6E80"/><stop offset="1" stop-color="#A9B8C2"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8DB36A"/><stop offset="1" stop-color="#6E9450"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E7276"/><stop offset="1" stop-color="#55595D"/></linearGradient>
  <linearGradient id="bark" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5A3D25"/><stop offset="0.5" stop-color="#7E5A3A"/><stop offset="1" stop-color="#553A23"/></linearGradient>
  <radialGradient id="leaf" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#6FBF4F"/><stop offset="1" stop-color="#3C7F2E"/></radialGradient>
  <radialGradient id="dryleaf" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#D2A65C"/><stop offset="1" stop-color="#9C7340"/></radialGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AC"/><stop offset="0.5" stop-color="#D2D8DC"/><stop offset="1" stop-color="#8E98A0"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="fire" cx="0.5" cy="0.6" r="0.5"><stop offset="0" stop-color="#FFF3B0"/><stop offset="0.4" stop-color="#FFB13B"/><stop offset="1" stop-color="#E5482B" stop-opacity="0"/></radialGradient>
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
# The worker (copied from tool/m2_board28_art.py) + goggles.
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


def _hand(p, bare=False):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{SKIN if bare else GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, goggles=True, props=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black gloves,
    blue goggles (bare = no gloves; goggles=False = no goggles)."""
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, SHIRT_D, 5.4))
    g.append(_hand(hb, bare))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    if goggles:
        hd.append(f'<path d="M{f(hx - 6 * face)} {f(hy + 1)} L{f(hx + 2 * face)} {f(hy + 1)}" stroke="{HAIR}" stroke-width="1.4"/>')
        hd.append(f'<rect x="{f(hx + 1.5 * face - 3)}" y="{f(hy - 0.8)}" width="7" height="3.6" rx="1.4" fill="{GOGGLE}" stroke="{HAIR}" stroke-width="0.8"/>')
    else:
        hd.append(f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>')
    g.append(f'<g transform="rotate({f(look * face)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(props)
    g.append(_hand(hf, bare))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, goggles=True, props=''):
    """A standing worker at x (feet on GY), scaled S about his feet; hands in
    card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    if props:
        # Props are given in card coordinates: undo the worker's scale.
        props = f'<g transform="translate({f(x)} {GY}) scale({f(1 / S)}) translate({f(-x)} -{GY})">{props}</g>'
    fig = figure(hip, sh, head, feet, (local(hands_world[0]), local(hands_world[1])), face, look, bare, goggles, props)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def passerby(x):
    """A villager walking by (no helmet): pink kurta."""
    return (f'<path d="M{x - 4} {GY} L{x - 2} {GY - 26} M{x + 4} {GY} L{x + 2} {GY - 26}" stroke="{PANTS}" stroke-width="5" stroke-linecap="round"/>'
            f'<rect x="{x - 8}" y="{GY - 58}" width="16" height="34" rx="5" fill="{CIVIL}"/>'
            f'<circle cx="{x}" cy="{GY - 66}" r="8" fill="{SKIN}"/>'
            f'<path d="M{x - 8} {GY - 68} A8 8 0 0 1 {x + 8} {GY - 68} Z" fill="{HAIR}"/>')


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def fire(x, y, s=1.0):
    return (f'<ellipse cx="{f(x)}" cy="{f(y - 8 * s)}" rx="{f(16 * s)}" ry="{f(20 * s)}" fill="url(#fire)"/>'
            f'<path d="M{f(x - 7 * s)} {f(y)} Q{f(x - 9 * s)} {f(y - 12 * s)} {f(x - 2 * s)} {f(y - 22 * s)} Q{f(x)} {f(y - 12 * s)} '
            f'{f(x + 4 * s)} {f(y - 16 * s)} Q{f(x + 9 * s)} {f(y - 8 * s)} {f(x + 7 * s)} {f(y)} Z" fill="#FFB13B"/>')


def leaves(blobs, grad='leaf'):
    return ''.join(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#{grad})"/>' for x, y, r in blobs)


def branch(p0, p1, w=5, col='url(#bark)'):
    if col.startswith('url'):
        # A tapered limb as a polygon so the gradient fills it.
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]
        n = math.hypot(dx, dy) or 1
        nx, ny = -dy / n, dx / n
        a, b = w / 2, w / 4
        return (f'<path d="M{f(p0[0] + nx * a)} {f(p0[1] + ny * a)} L{f(p1[0] + nx * b)} {f(p1[1] + ny * b)} '
                f'L{f(p1[0] - nx * b)} {f(p1[1] - ny * b)} L{f(p0[0] - nx * a)} {f(p0[1] - ny * a)} Z" fill="{col}"/>')
    return f'<path d="M{f(p0[0])} {f(p0[1])} L{f(p1[0])} {f(p1[1])}" stroke="{col}" stroke-width="{f(w)}" stroke-linecap="round"/>'


def stub(x, y, r=2.6):
    """A clean old cut end: pale wood ring."""
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{WOOD}" stroke="{BARK}" stroke-width="0.8"/>'


def trunk(x, top, w=14):
    return (f'<path d="M{f(x - w / 2 - 3)} {GY} Q{f(x - w / 2)} {f((GY + top) / 2)} {f(x - w / 3)} {f(top)} L{f(x + w / 3)} {f(top)} '
            f'Q{f(x + w / 2)} {f((GY + top) / 2)} {f(x + w / 2 + 3)} {GY} Z" fill="url(#bark)"/>')


WY = (40, 52, 64)  # the three conductors at the pole


def wire_y(i, x):
    """A slightly sagging span: lowest at x = 90."""
    return WY[i] + 6 * (1 - ((x - 90) / 110) ** 2)


def line(earthed=False, snap=False, ab=False, pole_x=182):
    """The LT line across the top: a pole on the right with three bare
    conductors on pin insulators — or one thick AB cable."""
    o = [f'<rect x="{pole_x - 4}" y="28" width="9" height="{GY - 28}" fill="url(#pole)"/>',
         f'<rect x="{pole_x - 14}" y="34" width="28" height="4" fill="#6F7880"/>']
    if ab:
        o.append(f'<path d="M0 {f(wire_y(1, 0))} Q90 {f(WY[1] + 12)} {pole_x} {WY[1] - 6}" stroke="{WIRE}" stroke-width="5" fill="none"/>')
        o.append(f'<path d="M0 {f(wire_y(1, 0) - 1.5)} Q90 {f(WY[1] + 10.5)} {pole_x} {WY[1] - 7.5}" stroke="#4A525A" stroke-width="1.2" fill="none"/>')
        o.append(f'<rect x="{pole_x - 6}" y="{WY[1] - 10}" width="12" height="8" rx="2" fill="url(#steel)"/>')
    else:
        for i, y in enumerate(WY):
            if snap and i == 2:
                o.append(f'<path d="M{pole_x - 10} {y} Q130 {y + 6} 96 {y + 30}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
                o.append(f'<path d="M0 {f(wire_y(i, 0))} Q40 {y + 14} 64 {y + 40}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
            else:
                o.append(f'<path d="M0 {f(wire_y(i, 0))} Q90 {f(y + 12)} {pole_x - 10} {y}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
        for i, y in enumerate(WY):
            o.append(f'<rect x="{pole_x - 13}" y="{y - 3}" width="6" height="6" rx="1.5" fill="url(#porcelain)"/>')
        o.append(f'<path d="M{pole_x - 10} 38 L{pole_x - 10} {WY[2]}" stroke="#6F7880" stroke-width="2"/>')
        # The pole's stay wire and its clamp (drawn on every bare-line card).
        o.append(f'<path d="M{pole_x + 4} 44 L210 {GY}" stroke="#4A525A" stroke-width="1.2"/>')
        o.append(f'<rect x="{pole_x + 2}" y="41" width="5" height="6" rx="1" fill="url(#steel)"/>')
    if earthed:
        # Earth leads clamped on all three wires, down to a rod in the ground.
        gx = 22
        for i in range(3):
            y = wire_y(i, gx)
            o.append(f'<rect x="{gx - 2.5}" y="{f(y - 2)}" width="5" height="5" rx="1" fill="url(#steel)"/>')
            o.append(f'<path d="M{gx} {f(y + 3)} Q{gx - 8 + i * 4} {f((y + GY) / 2)} {gx + (i - 1) * 3} {GY - 4}" stroke="{EARTH}" stroke-width="1.6" fill="none"/>')
        o.append(f'<rect x="{gx - 1.5}" y="{GY - 6}" width="3" height="12" fill="url(#steel)"/>')
    return ''.join(o)


def stage(back='sky', road=False):
    out = card_open(back)
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    if road:
        out.append(f'<rect y="{GY + 4}" width="{W}" height="{H - GY - 4}" fill="url(#road)"/>')
        out.append(f'<path d="M0 {GY + 13} L200 {GY + 13}" stroke="#FFFFFF" stroke-width="1.4" stroke-dasharray="10 8"/>')
    return out


def on_pole(lo, hi, t):
    return (lo[0] + (hi[0] - lo[0]) * t, lo[1] + (hi[1] - lo[1]) * t)


def pole_tool(lo, hi, kind='fibre'):
    """A long pruner: fibreglass (orange, insulated) or a steel pole; a hook
    blade at the tip."""
    col = FIBRE if kind == 'fibre' else 'url(#steel)'
    dx, dy = hi[0] - lo[0], hi[1] - lo[1]
    n = math.hypot(dx, dy) or 1
    ux, uy = dx / n, dy / n
    tip = (hi[0] + ux * 4, hi[1] + uy * 4)
    s = f'<path d="M{f(lo[0])} {f(lo[1])} L{f(hi[0])} {f(hi[1])}" stroke="{col}" stroke-width="3.2" stroke-linecap="round"/>'
    if kind == 'fibre':
        s += ''.join(f'<path d="M{f(lo[0] + dx * t)} {f(lo[1] + dy * t)} l{f(-uy * 2)} {f(ux * 2)}" stroke="#C47A16" stroke-width="1"/>' for t in (0.3, 0.6))
    s += (f'<path d="M{f(hi[0])} {f(hi[1])} L{f(tip[0])} {f(tip[1])} Q{f(tip[0] + uy * 6 + ux * 4)} {f(tip[1] - ux * 6 + uy * 4)} '
          f'{f(tip[0] + uy * 8 - ux * 3)} {f(tip[1] - ux * 8 - uy * 3)}" stroke="url(#steel)" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    return s


def chainsaw(x, y, ang=0):
    """A chainsaw at (x, y) = rear handle, bar pointing along ang degrees."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<rect x="-4" y="-7" width="22" height="14" rx="4" fill="{SAW}"/>'
            f'<path d="M2 -7 Q6 -14 12 -7" stroke="{BOOT}" stroke-width="2.4" fill="none"/>'
            f'<rect x="18" y="-3" width="34" height="6" rx="3" fill="url(#steel)"/>'
            f'<rect x="18" y="-3" width="34" height="6" rx="3" fill="none" stroke="{BOOT}" stroke-width="0.9" stroke-dasharray="2 1.5"/></g>')


def chips(x, y, d=1):
    return ''.join(f'<rect x="{f(x + d * a)}" y="{f(y + b)}" width="2.4" height="1.6" fill="{WOOD}" transform="rotate({c} {f(x + d * a)} {f(y + b)})"/>'
                   for a, b, c in ((4, -6, 20), (8, -2, -30), (2, 3, 45), (10, 5, 10), (6, 9, -20)))


def tape(x0, x1):
    """A red-and-white cordon tape on two posts."""
    y = GY - 22
    return (f'<path d="M{x0} {GY} L{x0} {y - 2} M{x1} {GY} L{x1} {y - 2}" stroke="#6F7880" stroke-width="2.4"/>'
            f'<path d="M{x0} {y} Q{(x0 + x1) / 2} {y + 5} {x1} {y}" stroke="{TAPE_R}" stroke-width="3" fill="none"/>'
            f'<path d="M{x0} {y} Q{(x0 + x1) / 2} {y + 5} {x1} {y}" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-dasharray="4 4"/>')


def truck(x):
    y = GY - 22
    return (f'<rect x="{x}" y="{y}" width="40" height="22" rx="3" fill="{TRUCK}"/>'
            f'<rect x="{x - 16}" y="{y + 6}" width="18" height="16" rx="3" fill="{TRUCK}"/>'
            f'<rect x="{x - 13}" y="{y + 9}" width="10" height="6" rx="1" fill="{GOGGLE}"/>'
            f'<circle cx="{x - 6}" cy="{GY + 1}" r="5" fill="{BOOT}"/><circle cx="{x + 28}" cy="{GY + 1}" r="5" fill="{BOOT}"/>')


def flag_hand(x, y):
    return (f'<path d="M{x} {y} L{x} {y - 30}" stroke="#6F7880" stroke-width="1.8"/>'
            f'<path d="M{x} {y - 30} L{x + 14} {y - 26} L{x} {y - 21} Z" fill="{FLAG}"/>')


def falling_branch(cx, cy, ang=-20, grad='leaf'):
    return (f'<g transform="rotate({ang} {cx} {cy})">' + branch((cx - 24, cy), (cx + 22, cy), 5)
            + leaves([(cx + 14, cy - 6, 9), (cx + 4, cy - 8, 8), (cx + 22, cy + 2, 7)], grad) + '</g>'
            + f'<g stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.85"><path d="M{cx - 6} {cy - 18} l-3 -7"/><path d="M{cx + 6} {cy - 20} l1 -7"/></g>')


# --------------------------------------------------------------------------
# Round 1 — why: a tree grown into the line vs one trimmed clear.
# --------------------------------------------------------------------------

def tree_below(x=78, top=100, stubs=True, extra=''):
    """A tree under the line, trimmed down to `top` — a clear gap above."""
    o = [trunk(x, top + 20), branch((x, top + 30), (x - 30, top + 6)), branch((x, top + 26), (x + 30, top + 4))]
    if stubs:
        o += [branch((x - 20, top + 14), (x - 24, top - 4), 4), stub(x - 24, top - 4),
              branch((x + 20, top + 12), (x + 26, top - 6), 4), stub(x + 26, top - 6)]
    o.append(leaves([(x - 34, top + 10, 15), (x - 14, top + 2, 17), (x + 10, top, 18), (x + 34, top + 8, 15), (x, top + 20, 18)]))
    o.append(extra)
    return ''.join(o)


def why_card(kind):
    out = stage('storm' if kind in ('wet', 'storm') else 'sky')
    if kind == 'clear':
        out.append(line())
        out.append(tree_below())
    elif kind == 'clear_ab':
        out.append(line(ab=True))
        out.append(tree_below(top=104))
    elif kind == 'rub':
        out.append(line(ab=True))
        out.append(tree_below(top=104))
        # A limb grown up through the cable; the jacket worn to the copper.
        out.append(branch((96, 112), (124, WY[1] + 6), 5))
        out.append(leaves([(132, WY[1] - 2, 11), (118, WY[1] + 12, 10), (140, WY[1] + 14, 9)]))
        out.append(f'<path d="M118 {WY[1] + 6.5} L130 {WY[1] + 5.5}" stroke="{COPPER}" stroke-width="3"/>')
    elif kind == 'wet':
        out.append(line())
        out.append(tree_below(top=104))
        # A wet leafy branch lying across two wires: a short.
        out.append(branch((100, 116), (132, wire_y(1, 132)), 5))
        out.append(leaves([(132, wire_y(1, 132) - 4, 10), (140, wire_y(2, 140) - 2, 9), (124, wire_y(2, 124), 9)]))
        out.append(spark(136, wire_y(2, 136) - 6, 0.8))
        out.append(''.join(f'<path d="M{x} {y} l-3 8" stroke="{RAIN}" stroke-width="1.4" stroke-linecap="round"/>'
                           for x, y in ((20, 80), (44, 96), (160, 90), (150, 120), (30, 130), (120, 84), (176, 140), (60, 150))))
    elif kind == 'storm':
        out.append(line(snap=True))
        out.append(tree_below(top=104))
        out.append(falling_branch(80, 70, 18))
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.7"><path d="M10 30 q20 -6 40 0"/><path d="M120 22 q20 -6 40 0"/></g>')
    elif kind == 'dry':
        out.append(line())
        out.append(tree_below(top=104))
        out.append(branch((100, 116), (130, wire_y(2, 130)), 5, DRY))
        out.append(leaves([(132, wire_y(2, 132) - 4, 9), (122, wire_y(2, 122) + 4, 8)], 'dryleaf'))
        out.append(spark(130, wire_y(2, 130) - 2, 0.6))
        out.append(fire(134, wire_y(2, 134) + 4, 1.0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — plan: shutdown + PTW (earthed), cordon, a coworker on the road.
# --------------------------------------------------------------------------

TARGET = (112, wire_y(2, 112) + 12)  # the branch growing up into the line


def plan_scene(earthed=True, cordon=True, mate=True, live_spark=False, falling=False, civilian=False, lorry=False):
    out = stage(road=True)
    out.append(line(earthed=earthed))
    out.append(trunk(80, 120))
    out.append(branch((80, 130), (TARGET[0], TARGET[1] + 2), 5))
    out.append(branch((80, 140), (52, 112), 5))
    out.append(leaves([(52, 108, 15), (72, 112, 16), (TARGET[0] + 4, TARGET[1] - 2, 9), (96, 124, 13)]))
    if cordon:
        out.append(tape(40, 150))
    lo, hi = (122, 172), (TARGET[0] + 2, TARGET[1] + 6)
    out.append(worker(132, (on_pole(lo, hi, 0.17), on_pole(lo, hi, 0.45)), face=-1, look=-16, props=pole_tool(lo, hi)))
    if live_spark:
        out.append(spark(TARGET[0] + 4, TARGET[1] - 6, 0.9))
    if mate:
        out.append(worker(162, ((168, 150), (172, 150)), face=1, look=0, props=flag_hand(172, 150)))
    if civilian:
        out.append(passerby(62))
    if falling:
        out.append(falling_branch(70, 112, -30))
    if lorry:
        out.append(truck(170))
    return out


def plan_card(kind):
    if kind == 'ptw':
        out = plan_scene()
    elif kind == 'traffic':
        out = plan_scene()
        out.append(truck(6))  # stopped at the cordon by the flag
    elif kind == 'live':
        out = plan_scene(earthed=False, live_spark=True)
    elif kind == 'nocordon':
        out = plan_scene(cordon=False, falling=True, civilian=True)
    elif kind == 'alone':
        out = plan_scene(mate=False, lorry=True)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — tool: an insulated pruner, a chainsaw in both hands, gloves and
# goggles.
# --------------------------------------------------------------------------

def tool_stage(held_pruner=False):
    out = stage()
    out.append(line())
    out.append(trunk(60, 96, 18))
    out.append(branch((60, 104), (TARGET[0], TARGET[1] + 2), 5))
    out.append(branch((60, 140), (124, 132), 9))   # a big low limb
    out.append(branch((60, 110), (26, 86), 6))
    out.append(leaves([(26, 82, 16), (48, 90, 18), (TARGET[0] + 4, TARGET[1] - 2, 9), (124, 126, 12), (136, 132, 10)]))
    if not held_pruner:
        # The insulated pruner laid on the grass (every card but the one using it).
        out.append(pole_tool((20, GY + 8), (100, GY + 4)))
    return out


def tool_card(kind):
    out = tool_stage(held_pruner=kind == 'pruner')
    if kind == 'pruner':
        lo, hi = (132, 172), (TARGET[0] + 2, TARGET[1] + 6)
        out.append(worker(142, (on_pole(lo, hi, 0.17), on_pole(lo, hi, 0.45)), face=-1, look=-18, props=pole_tool(lo, hi)))
    elif kind == 'metal':
        lo, hi = (132, 172), (TARGET[0] + 2, TARGET[1] + 6)
        out.append(worker(142, (on_pole(lo, hi, 0.17), on_pole(lo, hi, 0.45)), face=-1, look=-18, props=pole_tool(lo, hi, 'metal')))
        out.append(spark(TARGET[0] + 4, TARGET[1] - 4, 0.8))
    elif kind in ('chainsaw', 'onehand', 'bare'):
        two = kind != 'onehand'
        saw = chainsaw(142, 146, -168)
        hands = ((140, 144), (128, 141)) if two else ((150, 168), (140, 145))
        out.append(worker(150, hands, face=-1, look=-6, bare=kind == 'bare', goggles=kind != 'bare', props=saw))
        out.append(chips(96, 140, -1))
        if kind == 'onehand':
            # The bar kicking back up at the worker.
            out.append(f'<path d="M104 128 Q112 104 136 108" stroke="{FLAG}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'
                       f'<path d="M136 108 l-6 -4 l1 7 Z" fill="{FLAG}"/>')
        if kind == 'bare':
            out.append(chips(130, 112, 1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — cut: the 3-cut method on a heavy limb (close-up).
# --------------------------------------------------------------------------

TX, BY = 34, 112   # trunk centre x, branch axis y


def limb_stage(limb=True, collar=True):
    out = stage()
    out.append(f'<g opacity="0.9">' + ''.join(f'<path d="M0 {y} Q100 {y + 6} 200 {y - 2}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>' for y in (22, 32)) + '</g>')
    out.append(f'<rect x="{TX - 16}" y="0" width="32" height="{GY}" fill="url(#bark)"/>')
    if collar:
        out.append(f'<ellipse cx="{TX + 17}" cy="{BY}" rx="6" ry="14" fill="url(#bark)"/>')
    if limb:
        out.append(f'<path d="M{TX + 16} {BY - 11} L190 {BY - 6} L190 {BY + 6} L{TX + 16} {BY + 11} Z" fill="url(#bark)"/>')
        out.append(leaves([(180, BY - 16, 16), (196, BY + 4, 14), (166, BY - 22, 11)]))
    out.append(leaves([(TX - 10, 14, 18), (TX + 14, 8, 16)]))
    # A coil of rope at the foot of the tree (on every card of the round).
    out.append(f'<ellipse cx="{TX + 40}" cy="{GY + 6}" rx="12" ry="4" fill="none" stroke="#C9A25A" stroke-width="2.2"/>'
               f'<ellipse cx="{TX + 40}" cy="{GY + 6}" rx="7" ry="2.4" fill="none" stroke="#C9A25A" stroke-width="1.8"/>')
    return out


def hand_saw(x, y, ang):
    """A pruning saw: orange grip, steel toothed blade, gloved hand."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<path d="M0 -3 L44 -2 L44 2 L0 3 Z" fill="url(#steel)"/>'
            f'<path d="M2 3 L44 2" stroke="{BOOT}" stroke-width="1" stroke-dasharray="1.5 1.5"/>'
            f'<rect x="-18" y="-4" width="18" height="8" rx="3" fill="{FIBRE}"/>'
            f'<circle cx="-10" cy="0" r="6" fill="{GLOVE}"/>'
            f'<path d="M-10 0 L-34 22" stroke="{SHIRT}" stroke-width="10" stroke-linecap="round"/></g>')


def kerf(x, y0, y1):
    return f'<path d="M{f(x)} {f(y0)} L{f(x)} {f(y1)}" stroke="{WOOD}" stroke-width="2.4"/>'


def cut_card(kind):
    if kind == 'under':
        out = limb_stage()
        cx = 96
        out.append(kerf(cx, BY + 10, BY + 2))
        out.append(hand_saw(cx - 2, BY + 13, 0))
    elif kind == 'rope':
        out = limb_stage(limb=False)
        out.append(stub(TX + 18, BY, 9))
        # The limb, cut, lowered on a rope tied round it, away from the line.
        out.append(f'<g transform="rotate(38 96 {BY})"><path d="M96 {BY - 9} L190 {BY - 6} L190 {BY + 6} L96 {BY + 9} Z" fill="url(#bark)"/>'
                   + stub(96, BY, 9) + leaves([(180, BY - 16, 14), (194, BY + 4, 12)]) + '</g>')
        out.append(f'<path d="M140 {BY + 34} Q150 60 {TX + 4} 40 M140 {BY + 34} L176 {GY}" stroke="#C9A25A" stroke-width="2.2" fill="none"/>')
        out.append(f'<circle cx="176" cy="{GY - 4}" r="4" fill="{GLOVE}"/>')
    elif kind == 'collar':
        out = limb_stage(limb=False)
        # The short stub left by cuts 1 and 2, being cut just outside the collar.
        out.append(f'<path d="M{TX + 16} {BY - 11} L84 {BY - 9} L84 {BY + 9} L{TX + 16} {BY + 11} Z" fill="url(#bark)"/>')
        out.append(stub(84, BY, 9))
        out.append(kerf(TX + 24, BY - 9, BY + 2))
        out.append(hand_saw(TX + 26, BY - 13, -90))
    elif kind == 'tear':
        out = limb_stage(limb=False)
        # One cut from the top: the falling limb rips a strip of bark down the trunk.
        out.append(f'<g transform="rotate(30 90 {BY})"><path d="M90 {BY - 9} L190 {BY - 6} L190 {BY + 6} L90 {BY + 9} Z" fill="url(#bark)"/>'
                   + leaves([(180, BY - 16, 14), (194, BY + 4, 12)]) + '</g>')
        out.append(f'<path d="M{TX + 16} {BY - 8} L{TX + 50} {BY - 8} L{TX + 40} {BY + 6} L{TX + 12} {BY + 70} L{TX + 6} {BY + 64} Z" fill="{WOOD}"/>')
        out.append(f'<path d="M{TX + 50} {BY - 8} Q{TX + 64} {BY + 40} {TX + 54} {BY + 80}" stroke="{BARK}" stroke-width="5" fill="none"/>')
        out.append(hand_saw(70, BY - 20, 30))
    elif kind == 'fall':
        out = limb_stage(limb=False)
        out.append(stub(TX + 18, BY, 9))
        # Cut loose with no rope: the limb swings up onto the wires.
        out.append(f'<g transform="rotate(-32 70 {BY})"><path d="M70 {BY - 9} L190 {BY - 6} L190 {BY + 6} L70 {BY + 9} Z" fill="url(#bark)"/>'
                   + leaves([(180, BY - 16, 14), (194, BY + 4, 12)]) + '</g>')
        out.append(spark(150, 34, 1.0))
    elif kind == 'flush':
        out = limb_stage(limb=False, collar=False)
        # Cut flat into the trunk, collar and all: an open wound.
        out.append(f'<ellipse cx="{TX + 8}" cy="{BY}" rx="7" ry="16" fill="{WOOD}"/>')
        out.append(f'<ellipse cx="{TX + 8}" cy="{BY}" rx="3" ry="8" fill="{DRY}"/>')
        out.append(hand_saw(TX + 12, BY - 22, -90))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — trim: V-trim / directional pruning; never topping; felling only
# for a dangerous tree; 1.5–3 m clearance.
# --------------------------------------------------------------------------

ZONE_Y = (34, 92)  # the clearance zone round the wires


def zone():
    y0, y1 = ZONE_Y
    return f'<rect x="0" y="{y0}" width="200" height="{y1 - y0}" fill="#FFFFFF" opacity="0.18"/>' \
           f'<path d="M0 {y1} L200 {y1}" stroke="#FFFFFF" stroke-width="1.2" stroke-dasharray="5 4" opacity="0.8"/>'


def trim_card(kind):
    out = stage()
    out.append(zone())
    out.append(line())
    x = 80
    if kind == 'v':
        # Line over the tree: the middle opened in a V, two sides left.
        out.append(trunk(x, 160, 16))
        out.append(branch((x, 168), (x - 40, 112), 7) + branch((x, 168), (x + 40, 112), 7))
        out.append(stub(x, 150, 3.4))
        out.append(leaves([(x - 46, 110, 14), (x - 32, 124, 13), (x - 54, 128, 12), (x + 46, 110, 14), (x + 32, 124, 13), (x + 54, 128, 12), (x - 20, 144, 11), (x + 20, 144, 11)]))
    elif kind == 'side':
        # Directional pruning: only the limbs heading for the line cut; the
        # crown grows away (to the left).
        out.append(trunk(x, 120, 16))
        out.append(branch((x, 146), (x - 46, 112), 7) + branch((x, 136), (x - 20, 104), 6) + branch((x, 136), (x + 26, 112), 5))
        out.append(stub(x + 26, 112, 3.4))
        out.append(leaves([(x - 52, 110, 16), (x - 30, 114, 15), (x - 22, 108, 13), (x - 44, 126, 14), (x - 8, 124, 12)]))
        out.append(f'<path d="M{x - 66} 100 l-8 -6 M{x - 66} 100 l-2 -9" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85"/>')
    elif kind == 'top':
        # Topping: the whole crown rounded off flat — stubs and sprouts.
        out.append(trunk(x, 110, 16))
        for dx in (-30, -14, 0, 14, 30):
            out.append(branch((x, 130), (x + dx, 104), 5))
            out.append(stub(x + dx, 104, 2.8))
            out.append(leaves([(x + dx - 3, 98, 4), (x + dx + 4, 99, 3.5)]))
        out.append(leaves([(x, 126, 12)]))
    elif kind == 'fell':
        # A healthy tree cut down at the root, the chainsaw beside the stump.
        out.append(f'<rect x="{x - 9}" y="{GY - 12}" width="18" height="12" fill="url(#bark)"/>')
        out.append(f'<ellipse cx="{x}" cy="{GY - 12}" rx="9" ry="3" fill="{WOOD}"/>')
        out.append(branch((x + 12, GY - 6), (190, GY - 14), 12))
        out.append(leaves([(160, GY - 22, 16), (184, GY - 30, 18), (198, GY - 14, 14), (172, GY - 8, 12)]))
        out.append(chainsaw(x - 40, GY - 8, -10))
    elif kind == 'close':
        # Trimmed — but one limb left inside the clearance, near the wires.
        out.append(trunk(x, 120, 16))
        out.append(branch((x, 140), (x - 40, 104), 7) + branch((x, 130), (x + 34, 104), 6) + branch((x, 124), (x + 16, wire_y(2, 96) + 8), 5))
        out.append(leaves([(x - 44, 100, 16), (x - 20, 104, 15), (x + 34, 100, 14), (x + 18, wire_y(2, 98) + 4, 9)]))
        out.append(stub(x - 6, 112, 2.8))
    return card_close(out)


CARDS = {
    'why_clear': why_card('clear'),
    'why_clear_ab': why_card('clear_ab'),
    'why_rub': why_card('rub'),
    'why_wet': why_card('wet'),
    'why_storm': why_card('storm'),
    'why_dry': why_card('dry'),
    'plan_ptw': plan_card('ptw'),
    'plan_traffic': plan_card('traffic'),
    'plan_live': plan_card('live'),
    'plan_nocordon': plan_card('nocordon'),
    'plan_alone': plan_card('alone'),
    'tool_pruner': tool_card('pruner'),
    'tool_chainsaw': tool_card('chainsaw'),
    'tool_onehand': tool_card('onehand'),
    'tool_metal': tool_card('metal'),
    'tool_bare': tool_card('bare'),
    'cut_under': cut_card('under'),
    'cut_rope': cut_card('rope'),
    'cut_collar': cut_card('collar'),
    'cut_tear': cut_card('tear'),
    'cut_fall': cut_card('fall'),
    'cut_flush': cut_card('flush'),
    'trim_v': trim_card('v'),
    'trim_side': trim_card('side'),
    'trim_top': trim_card('top'),
    'trim_fell': trim_card('fell'),
    'trim_close': trim_card('close'),
}

# Safe cards and traps per round (mirrors learn_board_pack48.dart).
ROUNDS = {
    'why': (['why_clear', 'why_clear_ab'], ['why_rub', 'why_wet', 'why_storm', 'why_dry']),
    'plan': (['plan_ptw', 'plan_traffic'], ['plan_live', 'plan_nocordon', 'plan_alone']),
    'tool': (['tool_pruner', 'tool_chainsaw'], ['tool_onehand', 'tool_metal', 'tool_bare']),
    'cut': (['cut_under', 'cut_rope', 'cut_collar'], ['cut_tear', 'cut_fall', 'cut_flush']),
    'trim': (['trim_v', 'trim_side'], ['trim_top', 'trim_fell', 'trim_close']),
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
