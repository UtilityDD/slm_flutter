"""Picture cards for lesson 3.3 শেখা ("ক্রস-আর্ম ও ক্ল্যাম্প: লাইনের কঙ্কাল").

python -I tool/m3_board33_art.py .

Writes assets/game/art/m3_board33/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge; the worker
figure is copied from it). No words in the art.

What the cards show comes from lesson 3.3 and its film script only:
  1. arm: before climbing, look from below — a cross-arm must not be bent,
     twisted / tilted or rusty (a bent arm cuts the phase clearance; a cross-arm
     that is not right upsets the balance of the whole line); galvanised steel
     is shiny silver;
  2. clamp: the clamp joins the cross-arm to the pole — a wrap-around clamp on
     a round PCC pole, a bolted clamp on a rail / H-beam pole; the wrong clamp
     does not grip and slips; a clamp can slip down the pole;
  3. hold: with disc insulators, a tension clamp takes the pull where the line
     ends or turns a big angle; a suspension clamp hangs the conductor on a
     straight run and is never made to take tension; pins, split-pins and
     nut-bolts are checked to be secure;
  4. bolt: a spring washer under the nut against vibration; the right torque
     (too tight snaps the bolt, too loose stays loose); rust eats strength when
     the zinc (galvanising) layer is gone;
  5. climb: never stand on a rusty (or bent — film script) cross-arm or hook the
     harness to it; before opening any hardware, you and your tools are made
     secure. The line on these cards carries a portable earth set (house rule:
     line work only after shutdown, test and earth; not put into words here).

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
    print('usage: python -I tool/m3_board33_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board33')
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
EARTH = '#3E9B4F'
STEEL_D = '#7D868E'
RAIL_D = '#2C333B'
RAIL_L = '#8A949E'
RUST_D = '#5E2E14'
RUST_S = '#C2783A'
SCRAPE = '#E3E6E8'
STRAP = '#E8742A'
LADDER = '#B8C0C6'
BAG = '#8C6A3E'
BAG_D = '#6A4E2C'
FACE = '#1E2329'
WHITE = '#FFFFFF'
HANDLE = '#D8402F'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E8F2"/></linearGradient>
  <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DB46E"/><stop offset="1" stop-color="#7E9450"/></linearGradient>
  <linearGradient id="pcc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E9296"/><stop offset="0.5" stop-color="#C9CCCE"/><stop offset="1" stop-color="#8A8E92"/></linearGradient>
  <linearGradient id="rail" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#3E4650"/><stop offset="0.5" stop-color="#6C7682"/><stop offset="1" stop-color="#3A424C"/></linearGradient>
  <linearGradient id="galv" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.5" stop-color="#C3CBD1"/><stop offset="1" stop-color="#8C959D"/></linearGradient>
  <linearGradient id="rust" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B5652E"/><stop offset="0.5" stop-color="#8A4420"/><stop offset="1" stop-color="#6A3418"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="lens" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#F3F8FB"/><stop offset="1" stop-color="#C9D8E2"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
  <clipPath id="lensclip"><circle cx="156" cy="160" r="34"/></clipPath>
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


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0), gy=GY):
    """A standing worker at x (feet on gy), scaled S about his feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def hip_of(x, gy=GY):
    """Where a worker's harness sits (card coordinates)."""
    return (x, gy - 30 * S)


# --------------------------------------------------------------------------
# Things: the pole, the cross-arm, clamps, insulators.
# --------------------------------------------------------------------------

def outdoors():
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#grass)"/>')
    return out


def pole(x, top, kind='pcc', w=14, bottom=GY + 4):
    """A PCC pole (grey concrete, slightly tapered) or a rail pole (dark steel
    I-section, flanges at the edges)."""
    if kind == 'pcc':
        t, b = w * 0.42, w * 0.58
        return (f'<path d="M{f(x - t)} {f(top)} L{f(x + t)} {f(top)} L{f(x + b)} {f(bottom)} L{f(x - b)} {f(bottom)} Z" fill="url(#pcc)"/>')
    h = w / 2
    return (f'<rect x="{f(x - h)}" y="{f(top)}" width="{f(w)}" height="{f(bottom - top)}" fill="url(#rail)"/>'
            f'<rect x="{f(x - h)}" y="{f(top)}" width="2" height="{f(bottom - top)}" fill="{RAIL_D}"/>'
            f'<rect x="{f(x + h - 2)}" y="{f(top)}" width="2" height="{f(bottom - top)}" fill="{RAIL_D}"/>'
            f'<rect x="{f(x - 0.8)}" y="{f(top)}" width="1.6" height="{f(bottom - top)}" fill="{RAIL_L}"/>')


def pin_insulator(x, y):
    """A pin insulator standing on the arm at (x, y); returns svg and the
    conductor's tie point."""
    return (f'<rect x="{f(x - 1.2)}" y="{f(y - 6)}" width="2.4" height="6" fill="{STEEL_D}"/>'
            f'<path d="M{f(x - 7)} {f(y - 6)} Q{f(x - 6)} {f(y - 12)} {f(x - 3)} {f(y - 13)} L{f(x - 3)} {f(y - 17)} '
            f'L{f(x + 3)} {f(y - 17)} L{f(x + 3)} {f(y - 13)} Q{f(x + 6)} {f(y - 12)} {f(x + 7)} {f(y - 6)} Z" fill="url(#porcelain)"/>'
            f'<rect x="{f(x - 3.6)}" y="{f(y - 18.5)}" width="7.2" height="2.4" rx="1" fill="url(#porcelain)"/>'), (x, y - 17)


def rust_spots(x0, x1, y, h):
    """Flaking rust along a member from x0 to x1."""
    o = []
    n = 0
    x = x0 + 5
    while x < x1 - 3:
        r = 1.6 + (n % 3) * 0.7
        o.append(f'<circle cx="{f(x)}" cy="{f(y + h * (0.3 + 0.4 * (n % 2)))}" r="{f(r)}" fill="{RUST_D if n % 2 else RUST_S}"/>')
        x += 9 + (n % 4) * 2
        n += 1
    return ''.join(o)


def _rot(p, c, deg):
    a = math.radians(deg)
    dx, dy = p[0] - c[0], p[1] - c[1]
    return (c[0] + dx * math.cos(a) - dy * math.sin(a), c[1] + dx * math.sin(a) + dy * math.cos(a))


def cross_arm(x, y, half=60, state='ok', pole_w=14, insulators=True):
    """A channel cross-arm across the pole at height y with a V brace under it.
    state: ok | bent (right half bent down) | tilt (the whole arm leans) | rust.
    Returns (svg, conductor tie points)."""
    fill = 'url(#rust)' if state == 'rust' else 'url(#galv)'
    edge = RUST_D if state == 'rust' else STEEL_D
    c = (x, y)
    left_deg = -15 if state == 'tilt' else 0
    right_deg = {'tilt': -15, 'bent': 22}.get(state, 0)
    o = []
    ties = []
    # The brace: from the pole below to each half of the arm.
    for side, deg in ((-1, left_deg), (1, right_deg)):
        end = _rot((x + side * half * 0.55, y + 4), c, deg)
        o.append(f'<path d="M{f(x + side * pole_w * 0.4)} {f(y + 30)} L{f(end[0])} {f(end[1])}" stroke="{edge}" stroke-width="4.4" stroke-linecap="round"/>')
        o.append(f'<path d="M{f(x + side * pole_w * 0.4)} {f(y + 30)} L{f(end[0])} {f(end[1])}" stroke="{fill}" stroke-width="2.6" stroke-linecap="round"/>')
    for side, deg in ((-1, left_deg), (1, right_deg)):
        x0, x1 = (x - half, x) if side < 0 else (x, x + half)
        g = [f'<rect x="{f(x0)}" y="{f(y - 3.5)}" width="{f(x1 - x0)}" height="7" fill="{fill}"/>',
             f'<rect x="{f(x0)}" y="{f(y + 2)}" width="{f(x1 - x0)}" height="1.5" fill="{edge}"/>']
        if state == 'rust':
            g.append(rust_spots(x0, x1, y - 3.5, 7))
        if insulators:
            ix = x + side * (half - 8)
            svg, tie = pin_insulator(ix, y - 3.5)
            g.append(svg)
            ties.append(_rot(tie, c, deg))
        o.append(f'<g transform="rotate({deg} {f(x)} {f(y)})">' + ''.join(g) + '</g>')
    return ''.join(o), ties


def clamp(x, y, kind='wrap', w=14, state='ok', dx=0, dy=0, deg=0):
    """The clamp holding the arm to the pole: a wrap-around band (for a round
    PCC pole) or two bolted plates (for a rail pole)."""
    fill = 'url(#rust)' if state == 'rust' else 'url(#galv)'
    edge = RUST_D if state == 'rust' else STEEL_D
    cx, cy = x + dx, y + dy
    if kind == 'wrap':
        bw = w + 6
        g = (f'<rect x="{f(cx - bw / 2)}" y="{f(cy - 7)}" width="{f(bw)}" height="14" rx="5" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>'
             f'<path d="M{f(cx - bw / 2 + 2)} {f(cy)} L{f(cx + bw / 2 - 2)} {f(cy)}" stroke="{edge}" stroke-width="0.8"/>'
             f'<rect x="{f(cx - bw / 2 - 5)}" y="{f(cy - 4)}" width="6" height="8" rx="1.5" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>'
             f'<rect x="{f(cx + bw / 2 - 1)}" y="{f(cy - 4)}" width="6" height="8" rx="1.5" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>'
             f'<circle cx="{f(cx - bw / 2 - 2)}" cy="{f(cy)}" r="1.6" fill="{edge}"/><circle cx="{f(cx + bw / 2 + 2)}" cy="{f(cy)}" r="1.6" fill="{edge}"/>')
    else:
        pw = w + 10
        g = (f'<rect x="{f(cx - pw / 2)}" y="{f(cy - 9)}" width="{f(pw)}" height="18" rx="2" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>'
             + ''.join(f'<circle cx="{f(cx + sx * (pw / 2 - 3.5))}" cy="{f(cy + sy * 5)}" r="2" fill="{edge}"/>'
                       for sx in (-1, 1) for sy in (-1, 1)))
    if deg:
        g = f'<g transform="rotate({deg} {f(cx)} {f(cy)})">{g}</g>'
    return g


def conductors(ties, base_y):
    """Each phase runs in from the card edges to its insulator: a pulled-down
    insulator drags its conductor."""
    o = []
    for tx, ty in ties:
        o.append(f'<path d="M-4 {f(base_y)} Q{f(tx / 2)} {f(base_y + 3)} {f(tx)} {f(ty)} Q{f((tx + 200) / 2)} {f(base_y + 3)} 204 {f(base_y)}" '
                 f'stroke="{WIRE}" stroke-width="1.5" fill="none"/>')
    return ''.join(o)


def chevrons(x, y, n=3, col=WHITE):
    """Down arrows: something sliding down."""
    return ''.join(f'<path d="M{f(x - 4)} {f(y + i * 7)} L{f(x)} {f(y + i * 7 + 4)} L{f(x + 4)} {f(y + i * 7)}" stroke="{col}" '
                   'stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>' for i in range(n))


def scrapes(x, y0, y1, w=14):
    """Bright scrape marks on the pole where a clamp has slid down."""
    return ''.join(f'<path d="M{f(x + dx)} {f(y0)} L{f(x + dx)} {f(y1)}" stroke="{SCRAPE}" stroke-width="1.2" stroke-linecap="round"/>'
                   for dx in (-w * 0.3, -w * 0.05, w * 0.25))


# --------------------------------------------------------------------------
# Round 1 — arm: look up from below before climbing.
# --------------------------------------------------------------------------

ARM_X, ARM_Y = 92, 58


def pole_top(kind, state, ck=None, x=ARM_X, y=ARM_Y, top=16, half=60):
    o = [pole(x, top, kind)]
    arm, ties = cross_arm(x, y, half, state)
    o.append(arm)
    o.append(clamp(x, y, ck or ('wrap' if kind == 'pcc' else 'bolt'), state='rust' if state == 'rust' else 'ok'))
    svg, tie = pin_insulator(x, top)
    o.append(svg)
    ties = ties + [tie]
    o.append(conductors(ties, y - 21))
    return ''.join(o)


def arm_card(kind):
    out = outdoors()
    pk, st = {'pcc': ('pcc', 'ok'), 'rail': ('rail', 'ok'), 'bent': ('pcc', 'bent'),
              'tilt': ('rail', 'tilt'), 'rust': ('pcc', 'rust')}[kind]
    out.append(pole_top(pk, st))
    out.append(worker(166, ((172, 150), (150, 112)), face=-1, look=-18, point=(0, -1)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — clamp: the right clamp for the pole (close-up).
# --------------------------------------------------------------------------

def zoom(svg, cx, cy, s=2.6, to=(100, 104)):
    return f'<g transform="translate({to[0]} {to[1]}) scale({s}) translate({f(-cx)} {f(-cy)})">{svg}</g>'


def clamp_card(kind):
    out = outdoors()
    x, y = ARM_X, ARM_Y
    pk, ck = {'pcc': ('pcc', 'wrap'), 'rail': ('rail', 'bolt'), 'wrap_rail': ('rail', 'wrap'),
              'bolt_pcc': ('pcc', 'bolt'), 'slip': ('pcc', 'wrap')}[kind]
    slid = kind in ('wrap_rail', 'bolt_pcc', 'slip')
    dy = {'slip': 14, 'wrap_rail': 8, 'bolt_pcc': 8}.get(kind, 0)
    deg = {'wrap_rail': 5, 'bolt_pcc': -6}.get(kind, 0)
    g = [pole(x, -40, pk)]
    if slid:
        g.append(scrapes(x, y - 6, y + dy - 6))
    arm, _ = cross_arm(x, y, 60, 'ok', insulators=False)
    g.append(f'<g transform="translate(0 {dy}) rotate({deg} {x} {y})">{arm}</g>')
    if kind == 'wrap_rail':
        # A band made for a round pole stands off the flat flanges: daylight shows.
        g.append(clamp(x, y, 'wrap', w=20, dy=dy))
        g.append(f'<path d="M{f(x - 10)} {f(y + dy - 6)} L{f(x - 7)} {f(y + dy)} L{f(x - 10)} {f(y + dy + 6)} Z" fill="url(#sky)"/>'
                 f'<path d="M{f(x + 10)} {f(y + dy - 6)} L{f(x + 7)} {f(y + dy)} L{f(x + 10)} {f(y + dy + 6)} Z" fill="url(#sky)"/>')
    else:
        g.append(clamp(x, y, ck, dy=dy, deg=deg))
    out.append(zoom(''.join(g), x, y))
    if slid:
        out.append(chevrons(160, 150) + chevrons(40, 150))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — hold: tension and suspension hardware on disc insulators
# (side view: the line runs left-right; the arm is seen end-on).
# --------------------------------------------------------------------------

HP = (100, 48)   # the arm's end on the pole (side view)


def disc(x, y, upright):
    """One disc of a string: upright = string horizontal (discs seen edge-on, tall)."""
    if upright:
        return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="2.4" ry="9" fill="url(#porcelain)" stroke="{STEEL_D}" stroke-width="0.6"/>'
    return f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="9" ry="2.4" fill="url(#porcelain)" stroke="{STEEL_D}" stroke-width="0.6"/>'


def string(p0, p1, n=5):
    """A disc string from p0 to p1 (link line + discs)."""
    o = [f'<path d="M{f(p0[0])} {f(p0[1])} L{f(p1[0])} {f(p1[1])}" stroke="{STEEL_D}" stroke-width="1.6"/>']
    ang = math.degrees(math.atan2(p1[1] - p0[1], p1[0] - p0[0]))
    for i in range(n):
        t = (i + 1) / (n + 1)
        x, y = p0[0] + (p1[0] - p0[0]) * t, p0[1] + (p1[1] - p0[1]) * t
        o.append(f'<g transform="rotate({f(ang - 90)} {f(x)} {f(y)})">{disc(x, y, False)}</g>')
    return ''.join(o)


def tension_clamp(x, y):
    """A bolted strain clamp gripping the conductor's end (pointing left)."""
    return (f'<path d="M{f(x + 6)} {f(y - 4)} L{f(x - 14)} {f(y - 3)} Q{f(x - 18)} {f(y)} {f(x - 14)} {f(y + 3)} L{f(x + 6)} {f(y + 4)} Z" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="0.8"/>'
            + ''.join(f'<circle cx="{f(x - 10 + i * 6)}" cy="{f(y)}" r="1.4" fill="{STEEL_D}"/>' for i in range(3)))


def suspension_clamp(x, y, deg=0):
    """A boat-shaped saddle the conductor lies in."""
    g = (f'<path d="M{f(x - 9)} {f(y - 1)} Q{f(x)} {f(y + 9)} {f(x + 9)} {f(y - 1)} Z" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="0.8"/>'
         f'<path d="M{f(x)} {f(y - 6)} L{f(x)} {f(y)}" stroke="{STEEL_D}" stroke-width="2"/><circle cx="{f(x)}" cy="{f(y + 2.4)}" r="1.4" fill="{STEEL_D}"/>')
    return f'<g transform="rotate({deg} {f(x)} {f(y)})">{g}</g>' if deg else g


def lens(target, detail):
    """A magnifier in the corner looking at a small piece of hardware."""
    cx, cy, r = 156, 160, 34
    a = math.atan2(target[1] - cy, target[0] - cx)
    ex, ey = cx + r * math.cos(a), cy + r * math.sin(a)
    return (f'<path d="M{f(target[0])} {f(target[1])} L{f(ex)} {f(ey)}" stroke="{WHITE}" stroke-width="1.4" stroke-dasharray="3 2"/>'
            f'<circle cx="{f(target[0])}" cy="{f(target[1])}" r="4" fill="none" stroke="{WHITE}" stroke-width="1.4"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#lens)"/>'
            f'<g clip-path="url(#lensclip)">{detail}</g>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{WHITE}" stroke-width="2.6"/>')


def pin_detail(missing=False):
    """Inside the lens: a clevis, its pin and the split-pin through the pin's end."""
    cx, cy = 156, 160
    o = [f'<rect x="{cx - 22}" y="{cy - 9}" width="30" height="18" rx="6" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<rect x="{cx - 2}" y="{cy - 14}" width="26" height="28" rx="4" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>']
    if missing:
        # The split-pin has dropped out and the pin is walking out of the clevis.
        o.append(f'<rect x="{cx - 4}" y="{cy - 3}" width="34" height="6" rx="3" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>')
        o.append(f'<circle cx="{cx + 25}" cy="{cy}" r="2" fill="{FACE}"/>')
        o.append(f'<path d="M{cx - 10} {cy + 20} l12 5 l10 -2 M{cx - 10} {cy + 20} l12 2 l10 -2" stroke="{STEEL_D}" stroke-width="2" fill="none" stroke-linecap="round"/>')
        o.append(f'<path d="M{cx + 33} {cy - 6} l5 0 M{cx + 33} {cy} l7 0 M{cx + 33} {cy + 6} l5 0" stroke="{WIRE}" stroke-width="1.4" stroke-linecap="round"/>')
    else:
        o.append(f'<rect x="{cx - 4}" y="{cy - 3}" width="32" height="6" rx="3" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>')
        o.append(f'<path d="M{cx + 25} {cy - 8} L{cx + 25} {cy + 8} M{cx + 27} {cy - 8} L{cx + 27} {cy + 10}" stroke="{STEEL_D}" stroke-width="1.4" stroke-linecap="round"/>')
    return ''.join(o)


def nut_detail(loose=False):
    """Inside the lens: a bolt through the clamp, its spring washer and nut."""
    cx, cy = 156, 160
    gap = 7 if loose else 0
    o = [f'<rect x="{cx - 34}" y="{cy - 22}" width="20" height="44" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<rect x="{cx - 14}" y="{cy - 4}" width="40" height="8" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         ''.join(f'<path d="M{cx - 10 + i * 4} {cy - 4} l2 8" stroke="{STEEL_D}" stroke-width="0.8"/>' for i in range(9)),
         f'<path d="M{cx - 14} {cy - 10} L{cx - 9} {cy - 10} L{cx - 11} {cy + 10} L{cx - 14} {cy + 10} Z" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<rect x="{cx - 9 + gap}" y="{cy - 12}" width="14" height="24" rx="1.5" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<path d="M{cx - 9 + gap} {cy - 4} l14 0 M{cx - 9 + gap} {cy + 4} l14 0" stroke="{STEEL_D}" stroke-width="0.8"/>']
    if loose:
        o.append(f'<path d="M{cx + 10} {cy - 18} q6 -4 10 2 M{cx + 20} {cy - 16} l-1 -4 M{cx + 20} {cy - 16} l-4 0" stroke="{WIRE}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def hold_card(kind):
    out = outdoors()
    x, y = HP
    out.append(pole(x, 14, 'pcc'))
    # The arm, end-on: a short channel stub.
    out.append(f'<rect x="{x - 15}" y="{y - 5}" width="30" height="10" rx="1" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="0.8"/>')
    out.append(clamp(x, y, 'wrap'))
    if kind in ('tension', 'pin'):
        a, b = (x - 16, y), (x - 50, y)
        out.append(string(a, b))
        out.append(f'<path d="M{f(b[0] - 14)} {f(b[1])} Q{f(b[0] - 40)} {f(b[1] + 8)} -4 {f(b[1] + 24)}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
        out.append(tension_clamp(b[0], b[1]))
        out.append(lens((b[0] + 4, b[1]), pin_detail(missing=(kind == 'pin'))))
    elif kind in ('susp', 'nut'):
        a, b = (x, y + 5), (x, y + 46)
        out.append(string(a, b))
        out.append(f'<path d="M-4 {f(b[1] + 22)} Q{f(x / 2)} {f(b[1] + 8)} {f(x)} {f(b[1] + 1)} Q{f(x + 50)} {f(b[1] + 8)} 204 {f(b[1] + 22)}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
        out.append(suspension_clamp(b[0], b[1] + 1))
        out.append(lens((b[0], b[1] + 2), nut_detail(loose=(kind == 'nut'))))
    elif kind == 'susp_end':
        # A suspension string at a dead-end: dragged sideways by the full pull.
        a, b = (x, y + 5), (x - 34, y + 38)
        out.append(string(a, b))
        out.append(f'<path d="M{f(b[0])} {f(b[1] + 1)} Q{f(b[0] - 30)} {f(b[1] + 8)} -4 {f(b[1] + 22)}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
        out.append(suspension_clamp(b[0], b[1] + 1, deg=40))
        out.append(f'<g stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round"><path d="M{f(b[0] - 18)} {f(b[1] - 12)} l-8 -2"/>'
                   f'<path d="M{f(b[0] - 20)} {f(b[1] - 4)} l-9 0"/><path d="M{f(b[0] - 18)} {f(b[1] + 4)} l-8 2"/></g>')
        out.append(f'<path d="M{f(x - 6)} {f(y + 12)} l4 4 l-3 3 l4 4" stroke="{FACE}" stroke-width="1.2" fill="none"/>')
        out.append(lens((b[0], b[1] + 2), pin_detail(missing=False)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — bolt: spring washer, right torque, no rust (close-up).
# --------------------------------------------------------------------------

BY = 104   # the bolt's axis


def bolt_stack(state='ok', washer=True, gap=0, snapped=False):
    """Side view: clamp plate and arm flange, a bolt through them, a flat
    washer, a spring washer and the nut."""
    rust = state == 'rust'
    fill = 'url(#rust)' if rust else 'url(#galv)'
    edge = RUST_D if rust else STEEL_D
    o = [pole(14, -10, 'pcc', w=30, bottom=230),
         f'<rect x="40" y="34" width="16" height="150" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<rect x="56" y="50" width="16" height="118" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="1"/>',
         f'<path d="M28 {BY - 13} L40 {BY - 13} L40 {BY + 13} L28 {BY + 13} Z" fill="{fill}" stroke="{edge}" stroke-width="1"/>',
         f'<path d="M28 {BY - 4} L40 {BY - 4} M28 {BY + 4} L40 {BY + 4}" stroke="{edge}" stroke-width="0.8"/>']
    end = 84 if snapped else 124
    o.append(f'<rect x="40" y="{BY - 5}" width="{end - 40}" height="10" fill="{fill}" stroke="{edge}" stroke-width="1"/>')
    o.append(''.join(f'<path d="M{x} {BY - 5} l2 10" stroke="{edge}" stroke-width="0.8"/>' for x in range(78, end - 1, 4)))
    o.append(f'<rect x="72" y="{BY - 17}" width="4" height="34" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>')
    nx = 76
    if washer:
        o.append(f'<path d="M76 {BY - 15} L82 {BY - 15} L80 {BY + 15} L76 {BY + 15} Z" fill="{fill}" stroke="{edge}" stroke-width="0.8"/>')
        o.append(f'<path d="M76 {BY - 1} L82 {BY + 2}" stroke="{FACE}" stroke-width="1"/>')
        nx = 82
    if snapped:
        o.append(f'<path d="M{end} {BY - 5} l3 3 l-2 2 l3 3 l-4 2" stroke="{edge}" stroke-width="1.2" fill="none"/>')
        # The nut and the broken stub falling away.
        o.append(f'<g transform="rotate(35 128 168)"><rect x="118" y="156" width="20" height="26" rx="2" fill="{fill}" stroke="{edge}" stroke-width="1"/>'
                 f'<rect x="138" y="164" width="16" height="10" fill="{fill}" stroke="{edge}" stroke-width="1"/></g>')
        o.append(f'<g stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round"><path d="M112 150 l-4 -6"/><path d="M106 156 l-6 -3"/></g>')
    else:
        x = nx + gap
        o.append(f'<rect x="{x}" y="{BY - 15}" width="20" height="30" rx="2" fill="{fill}" stroke="{edge}" stroke-width="1"/>')
        o.append(f'<path d="M{x} {BY - 5} l20 0 M{x} {BY + 5} l20 0" stroke="{edge}" stroke-width="0.8"/>')
    if rust:
        o.append(f'<path d="M48 {BY + 16} q2 20 -1 40 M62 {BY + 18} q-2 16 1 30 M86 {BY + 16} q2 14 0 24" stroke="{RUST_S}" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.8"/>')
        o.append(rust_spots(30, 120, BY - 5, 10))
    return ''.join(o)


def wrench(nut_x, dial=False, pipe=False):
    """A ring spanner on the nut, held in a gloved hand down to the right;
    a torque wrench carries a dial, a long pipe is a cheater bar."""
    cx, cy = nut_x + 10, BY
    hx, hy = 150, 170
    o = [f'<path d="M{cx} {cy + 15} L{hx} {hy}" stroke="{STEEL_D}" stroke-width="8" stroke-linecap="round"/>',
         f'<path d="M{cx} {cy + 15} L{hx} {hy}" stroke="url(#galv)" stroke-width="5" stroke-linecap="round"/>',
         f'<rect x="{cx - 13}" y="{cy - 18}" width="26" height="36" rx="6" fill="none" stroke="{STEEL_D}" stroke-width="5"/>']
    if dial:
        dx, dy = cx + (hx - cx) * 0.55, cy + 15 + (hy - cy - 15) * 0.55
        o.append(f'<circle cx="{f(dx)}" cy="{f(dy)}" r="10" fill="{WHITE}" stroke="{STEEL_D}" stroke-width="2"/>'
                 f'<path d="M{f(dx)} {f(dy)} l5 -6" stroke="{FACE}" stroke-width="1.6" stroke-linecap="round"/>'
                 f'<circle cx="{f(dx)}" cy="{f(dy)}" r="1.6" fill="{FACE}"/>')
    if pipe:
        o.append(f'<path d="M{hx - 16} {hy - 14} L190 214" stroke="{RAIL_D}" stroke-width="10" stroke-linecap="round"/>')
    gx, gy = hx + 4, hy + 4
    o.append(f'<circle cx="{gx}" cy="{gy}" r="12" fill="{GLOVE}"/>'
             f'<rect x="{gx - 2}" y="{gy + 6}" width="30" height="30" rx="4" fill="url(#shirt)" transform="rotate(-30 {gx} {gy})"/>')
    return ''.join(o)


def bolt_card(kind):
    out = outdoors()
    out.append('<g transform="translate(92 104) scale(1.4) translate(-76 -104)">')
    if kind == 'washer':
        out.append(bolt_stack())
    elif kind == 'torque':
        out.append(bolt_stack())
        out.append(wrench(82, dial=True))
    elif kind == 'none':
        out.append(bolt_stack(washer=False, gap=8))
        out.append(f'<g stroke="{WHITE}" stroke-width="1.6" fill="none" stroke-linecap="round">'
                   f'<path d="M64 30 q-4 -4 0 -8 q4 -4 0 -8"/><path d="M48 192 q-4 4 0 8 q4 4 0 8"/>'
                   f'<path d="M100 82 q6 -6 12 0 M112 82 l0 -5 M112 82 l-5 0"/></g>')
    elif kind == 'snap':
        out.append(bolt_stack(snapped=True))
        out.append(wrench(100, pipe=True))
    elif kind == 'loose':
        out.append(bolt_stack(gap=9))
        out.append(wrench(91))
    elif kind == 'rust':
        out.append(bolt_stack(state='rust'))
    out.append('</g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — climb: harness round a sound pole, tools secured, never on rust.
# --------------------------------------------------------------------------

CX, CY = 96, 100   # pole and arm in the climbing scene
FEET = (124, 172)  # the worker's feet on the ladder


def earth_set(ties):
    """A portable earth set: a clamp on each conductor, leads down the pole."""
    o = []
    for tx, ty in ties:
        o.append(f'<path d="M{f(tx + 5)} {f(ty - 1)} Q{f((tx + CX) / 2)} {f(ty + 26)} {f(CX - 9)} {f(CY + 40)}" stroke="{EARTH}" stroke-width="1.6" fill="none"/>'
                 f'<rect x="{f(tx + 3)}" y="{f(ty - 3)}" width="5" height="5" rx="1" fill="{EARTH}"/>')
    o.append(f'<path d="M{CX - 9} {CY + 40} L{CX - 9} {GY + 6}" stroke="{EARTH}" stroke-width="2"/>')
    return ''.join(o)


def ladder():
    x0, y0, x1, y1 = 136, GY + 2, 104, CY + 18
    o = []
    for d in (-7, 7):
        o.append(f'<path d="M{x0 + d} {y0} L{x1 + d} {y1}" stroke="{LADDER}" stroke-width="3" stroke-linecap="round"/>')
    for i in range(1, 9):
        t = i / 9
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        o.append(f'<path d="M{f(x - 7)} {f(y)} L{f(x + 7)} {f(y)}" stroke="{LADDER}" stroke-width="2.2"/>')
    return ''.join(o)


def tool_bag(x, y, empty=False):
    o = [f'<path d="M{x} {y - 10} L{x} {y}" stroke="{BAG_D}" stroke-width="1.4"/>']
    if not empty:
        o.append(f'<path d="M{x - 3} {y + 2} L{x - 6} {y - 8}" stroke="{STEEL_D}" stroke-width="2.4" stroke-linecap="round"/>'
                 f'<path d="M{x + 3} {y + 2} L{x + 5} {y - 7}" stroke="{HANDLE}" stroke-width="2.6" stroke-linecap="round"/>')
    o.append(f'<path d="M{x - 8} {y} L{x + 8} {y} L{x + 6} {y + 16} L{x - 6} {y + 16} Z" fill="{BAG}" stroke="{BAG_D}" stroke-width="1"/>')
    return ''.join(o)


def pole_strap(hip, pole_x, w=14):
    """The harness's pole strap passing round the front of the pole."""
    hx, hy = hip
    return (f'<path d="M{f(hx - 4)} {f(hy)} Q{f((hx + pole_x) / 2)} {f(hy + 8)} {f(pole_x - w * 0.7)} {f(hy - 2)}" stroke="{STRAP}" stroke-width="2.6" fill="none" stroke-linecap="round"/>')


def lanyard(hip, anchor):
    hx, hy = hip
    ax, ay = anchor
    return (f'<path d="M{f(hx)} {f(hy)} Q{f(hx + 6)} {f((hy + ay) / 2)} {f(ax)} {f(ay + 4)}" stroke="{STRAP}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(ax - 3)} {f(ay + 6)} a3.2 3.2 0 1 1 6 0" stroke="{STEEL_D}" stroke-width="1.8" fill="none"/>')


def spanner(x, y, deg=0):
    return (f'<g transform="rotate({deg} {f(x)} {f(y)})"><rect x="{f(x - 10)}" y="{f(y - 1.6)}" width="20" height="3.2" rx="1.2" fill="url(#galv)" stroke="{STEEL_D}" stroke-width="0.6"/>'
            f'<circle cx="{f(x + 11)}" cy="{f(y)}" r="3.4" fill="none" stroke="{STEEL_D}" stroke-width="1.8"/></g>')


def climb_card(kind):
    out = outdoors()
    pk, st = {'pcc': ('pcc', 'ok'), 'rail': ('rail', 'ok'), 'rust_stand': ('pcc', 'rust'),
              'rust_hook': ('rail', 'rust'), 'bent_hook': ('pcc', 'bent'), 'loose': ('rail', 'ok')}[kind]
    out.append(pole(CX, -6, pk, w=16))
    arm, ties = cross_arm(CX, CY, 62, st, pole_w=16)
    out.append(arm)
    out.append(clamp(CX, CY, 'wrap' if pk == 'pcc' else 'bolt', w=16, state='rust' if st == 'rust' else 'ok'))
    out.append(conductors(ties, CY - 22))
    out.append(earth_set(ties))
    out.append(ladder())
    if kind == 'rust_stand':
        # Standing on the rusty arm itself.
        fx = 66
        out.append(tool_bag(140, 150))
        out.append(worker(fx, ((CX - 9, CY - 46), (CX - 8, CY - 36)), face=1, look=4, gy=CY - 3))
        out.append(pole_strap((fx + 4, CY - 3 - 30 * S), CX + 2, 16))
        return card_close(out)
    fx, fy = FEET
    hip = hip_of(fx, fy)
    hands = ((CX + 8, CY + 6), (CX + 14, CY - 2))
    out.append(tool_bag(fx + 12, fy - 26, empty=(kind == 'loose')))
    out.append(worker(fx, hands, face=-1, look=-8, gy=fy))
    if kind in ('pcc', 'rail', 'loose'):
        out.append(pole_strap(hip, CX, 16))
    elif kind in ('rust_hook', 'bent_hook'):
        anchor = ties[1] if kind == 'rust_hook' else (ties[1][0] - 14, ties[1][1] + 11)
        out.append(lanyard(hip, (anchor[0] - 10, anchor[1] + 13)))
    if kind == 'loose':
        out.append(spanner(56, CY - 7))
        out.append(spanner(70, 156, 50))
        out.append(f'<g stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round"><path d="M70 136 l0 -8"/><path d="M64 140 l0 -8"/><path d="M76 140 l0 -8"/></g>')
    return card_close(out)


CARDS = {
    'arm_pcc': arm_card('pcc'),
    'arm_rail': arm_card('rail'),
    'arm_bent': arm_card('bent'),
    'arm_tilt': arm_card('tilt'),
    'arm_rust': arm_card('rust'),
    'clamp_pcc': clamp_card('pcc'),
    'clamp_rail': clamp_card('rail'),
    'clamp_wrap_rail': clamp_card('wrap_rail'),
    'clamp_bolt_pcc': clamp_card('bolt_pcc'),
    'clamp_slip': clamp_card('slip'),
    'hold_tension': hold_card('tension'),
    'hold_susp': hold_card('susp'),
    'hold_susp_end': hold_card('susp_end'),
    'hold_pin': hold_card('pin'),
    'hold_nut': hold_card('nut'),
    'bolt_washer': bolt_card('washer'),
    'bolt_torque': bolt_card('torque'),
    'bolt_none': bolt_card('none'),
    'bolt_snap': bolt_card('snap'),
    'bolt_loose': bolt_card('loose'),
    'bolt_rust': bolt_card('rust'),
    'climb_pcc': climb_card('pcc'),
    'climb_rail': climb_card('rail'),
    'climb_rust_stand': climb_card('rust_stand'),
    'climb_rust_hook': climb_card('rust_hook'),
    'climb_bent_hook': climb_card('bent_hook'),
    'climb_loose': climb_card('loose'),
}

# Safe cards and traps per round (mirrors learn_board_pack33.dart).
ROUNDS = {
    'arm': (['arm_pcc', 'arm_rail'], ['arm_bent', 'arm_tilt', 'arm_rust']),
    'clamp': (['clamp_pcc', 'clamp_rail'], ['clamp_wrap_rail', 'clamp_bolt_pcc', 'clamp_slip']),
    'hold': (['hold_tension', 'hold_susp'], ['hold_susp_end', 'hold_pin', 'hold_nut']),
    'bolt': (['bolt_washer', 'bolt_torque'], ['bolt_none', 'bolt_snap', 'bolt_loose', 'bolt_rust']),
    'climb': (['climb_pcc', 'climb_rail'], ['climb_rust_stand', 'climb_rust_hook', 'climb_bent_hook', 'climb_loose']),
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
