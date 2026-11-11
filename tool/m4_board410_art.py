"""Picture cards for lesson 4.10 শেখা ("এলটি (LT) লাইনের ফেজ ব্যালেন্সিং").

python -I tool/m4_board410_art.py .

Writes assets/game/art/m4_board410/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
or numbers in the art: the phases are told by their R / Y / B colours only,
the neutral is black, and a current is drawn as a bar.

What the cards show comes from lesson 4.10 and its film script only:
  1. spot: one phase's fuse blowing again and again, low-voltage complaints
     from one area (dim windows) are clear signs of unbalance; the clamp-on
     meter (tong tester) is the main tool — clamp each phase (R, Y, B) and the
     neutral at the feeder pillar; working on guesswork is wrong;
  2. measure: at peak-load time (dusk, lit houses) measure each phase and the
     neutral and make a list; a midday reading, counting houses or judging by
     a bulb's glow are guesses;
  3. plan: readings R=120A, Y=70A, B=50A (bars only) — move some service
     lines from the overloaded phase (R) to a lightly loaded one (Y or B);
  4. work: change the phase connection only under PTW / shutdown (switch OFF,
     tag, earth lead — the house rule) and tell the customer first;
  5. check: measure every phase again — the neutral current near zero — and
     keep a record of which customer is on which phase; an unbalanced line's
     neutral carries current and can be dangerous.

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
    print('usage: python -I tool/m4_board410_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board410')
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
PH_R = '#D8402F'
PH_Y = '#F0C02E'
PH_B = '#2F6BCB'
PH_N = '#15181C'
PHASES = (PH_R, PH_Y, PH_B)
LED_G = '#4CD964'
EARTH = '#3E9B4F'
METER = '#E8742A'
METER_D = '#B9561A'
FACE = '#1E2329'
PAPER = '#F4F1E8'
INK = '#5B6670'
TAG = '#E53935'
WALL = '#D9C7A6'
WALL_D = '#B9A27C'
ROOF = '#8A4B3A'
LIT = '#FFD86B'
DIMW = '#B98944'
DARKW = '#3A3F4A'
KURTA = '#3E8E6E'
KURTA_D = '#2F6E55'
SCORCH = '#2A2420'

DEFS = """<defs>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#34446F"/><stop offset="0.6" stop-color="#9A6E86"/><stop offset="1" stop-color="#E8A06E"/></linearGradient>
  <linearGradient id="noon" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6FB3E6"/><stop offset="1" stop-color="#D3EAF6"/></linearGradient>
  <linearGradient id="chart" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#22303C"/><stop offset="1" stop-color="#36485A"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E8163"/><stop offset="1" stop-color="#6E6248"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7E8C86"/><stop offset="0.5" stop-color="#A7B5AE"/><stop offset="1" stop-color="#74827C"/></linearGradient>
  <linearGradient id="panelIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E363E"/><stop offset="1" stop-color="#434C55"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE9A8" stop-opacity="0.85"/><stop offset="1" stop-color="#FFE9A8" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
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


# --------------------------------------------------------------------------

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


def arrow(p0, p1, bend=-18, w=2.2, color='#FFFFFF', dash=False):
    """A curved arrow from p0 to p1 (the head at p1)."""
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2 + bend
    tx, ty = p1[0] - mx, p1[1] - my
    n = math.hypot(tx, ty) or 1
    tx, ty = tx / n, ty / n
    nx, ny = -ty, tx
    hl = w * 2.8
    b1 = (p1[0] - tx * hl + nx * hl * 0.6, p1[1] - ty * hl + ny * hl * 0.6)
    b2 = (p1[0] - tx * hl - nx * hl * 0.6, p1[1] - ty * hl - ny * hl * 0.6)
    da = ' stroke-dasharray="4 3"' if dash else ''
    return (f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0] - tx * hl * 0.6)} {f(p1[1] - ty * hl * 0.6)}" stroke="{color}" '
            f'stroke-width="{f(w)}" fill="none" stroke-linecap="round"{da}/>'
            f'<path d="M{f(p1[0])} {f(p1[1])} L{f(b1[0])} {f(b1[1])} L{f(b2[0])} {f(b2[1])} Z" fill="{color}"/>')


def clamp_meter(cx, cy, hand):
    """A clamp-on meter (tong tester): its jaw round the cable at (cx, cy),
    the body running down to the hand."""
    hx, hy = hand
    L = math.hypot(hx - cx, hy - cy)
    ang = math.degrees(math.atan2(hy - cy, hx - cx)) - 90
    return (f'<g transform="translate({f(cx)} {f(cy)}) rotate({f(ang)})">'
            f'<path d="M-3 7 A7.5 7.5 0 1 1 3 7" stroke="{METER}" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            f'<rect x="-6" y="6" width="12" height="{f(max(L - 2, 14))}" rx="3" fill="{METER}" stroke="{METER_D}" stroke-width="1"/>'
            f'<rect x="-4" y="9" width="8" height="7" rx="1" fill="{FACE}"/>'
            f'<rect x="-2.6" y="11.5" width="5.2" height="2" fill="{LED_G}"/></g>')


def meter_case(x, y=GY - 4):
    """The clamp meter left lying on the ground, unused."""
    return (f'<g transform="rotate(-80 {f(x)} {f(y)})"><rect x="{f(x - 5)}" y="{f(y - 18)}" width="10" height="20" rx="3" fill="{METER}" stroke="{METER_D}" stroke-width="1"/>'
            f'<path d="M{f(x - 3)} {f(y - 18)} A6 6 0 1 1 {f(x + 3)} {f(y - 18)}" stroke="{METER}" stroke-width="2.6" fill="none"/>'
            f'<rect x="{f(x - 3.4)}" y="{f(y - 14)}" width="6.8" height="5" rx="1" fill="{FACE}"/>'
            f'<rect x="{f(x - 2)}" y="{f(y - 12.4)}" width="4" height="1.6" fill="{LED_G}"/></g>')


def notebook(x, y, rows=True, s=1.0):
    """The phase record: a page with a dot per customer in his phase colour."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(32 * s)}" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>']
    if rows:
        for i, col in enumerate(PHASES):
            yy = y + (8 + i * 9) * s
            for j in range(3 if i else 2):
                o.append(f'<circle cx="{f(x + (6 + j * 7) * s)}" cy="{f(yy)}" r="{f(2.2 * s)}" fill="{col}"/>')
            o.append(f'<path d="M{f(x + 3 * s)} {f(yy + 4 * s)} L{f(x + 23 * s)} {f(yy + 4 * s)}" stroke="{INK}" stroke-width="0.6"/>')
    return ''.join(o)


def bubble(x, y, bars, tail=None):
    """A read-out callout: four bars R, Y, B and N (neutral, black)."""
    o = []
    if tail:
        o.append(f'<path d="M{f(x + 14)} {f(y + 38)} L{f(tail[0])} {f(tail[1])} L{f(x + 26)} {f(y + 38)} Z" fill="{PAPER}"/>')
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="54" height="40" rx="8" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>')
    for i, (col, h) in enumerate(zip(PHASES + (PH_N,), bars)):
        bx = x + 7 + i * 11
        o.append(f'<rect x="{f(bx)}" y="{f(y + 34 - h)}" width="8" height="{f(h)}" rx="1" fill="{col}"/>')
    o.append(f'<path d="M{f(x + 5)} {f(y + 34)} L{f(x + 49)} {f(y + 34)}" stroke="{INK}" stroke-width="1"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# The street stage: a feeder pillar (door open: switch, three fuses, R, Y, B
# busbars, the neutral link, the outgoing cables) and a house behind.
# --------------------------------------------------------------------------

PX0, PY0, PX1 = 26, 66, 92            # pillar box
FUSE_Y = 96
BAR_Y0, BAR_Y1 = 106, 128
CAB_Y1 = 190
BAR_X = (40, 54, 68, 81)             # R, Y, B, N
CLAMP_Y = 156


def house(windows='lit'):
    o = [f'<rect x="132" y="128" width="64" height="{GY - 128}" fill="{WALL}"/>',
         f'<path d="M126 130 L164 104 L202 130 Z" fill="{ROOF}"/>',
         f'<rect x="132" y="128" width="64" height="4" fill="{WALL_D}"/>',
         f'<rect x="158" y="170" width="13" height="{GY - 170}" rx="1" fill="{WALL_D}"/>']
    col = {'lit': LIT, 'dim': DIMW, 'dark': DARKW}[windows]
    for wx in (140, 178):
        if windows == 'lit':
            o.append(f'<circle cx="{wx + 6}" cy="148" r="15" fill="url(#glow)"/>')
        o.append(f'<rect x="{wx}" y="142" width="12" height="12" rx="1" fill="{col}" stroke="{WALL_D}" stroke-width="1.2"/>')
    return ''.join(o)


def pillar(switch_on=True, door=True, tag=False, earth=False, lifted=None, blown_r=False):
    o = [f'<rect x="{PX0}" y="{PY0}" width="{PX1 - PX0}" height="{GY - PY0}" rx="2" fill="url(#panel)"/>',
         f'<rect x="{PX0 - 3}" y="{PY0 - 5}" width="{PX1 - PX0 + 6}" height="7" rx="1.5" fill="url(#panel)"/>']
    if not door:
        o.append(f'<rect x="{PX0 + 5}" y="{PY0 + 6}" width="{PX1 - PX0 - 10}" height="{GY - PY0 - 12}" rx="1.5" fill="none" stroke="#5F6C66" stroke-width="1.2"/>')
        o.append(f'<rect x="{PX1 - 12}" y="128" width="3" height="12" rx="1" fill="#5F6C66"/>')
        return ''.join(o)
    o.append(f'<path d="M{PX0} {PY0 + 2} L8 {PY0 + 10} L8 {GY - 8} L{PX0} {GY - 2} Z" fill="url(#panel)" stroke="#5F6C66" stroke-width="0.8"/>')
    o.append(f'<rect x="{PX0 + 5}" y="{PY0 + 6}" width="{PX1 - PX0 - 10}" height="{GY - PY0 - 12}" rx="1.5" fill="url(#panelIn)"/>')
    # Main switch: the handle up = ON, down = OFF.
    o.append(f'<rect x="38" y="74" width="44" height="16" rx="2" fill="url(#steel)"/>')
    hx = 72 if switch_on else 48
    o.append(f'<path d="M60 82 L{hx} 82" stroke="{FACE}" stroke-width="3.6" stroke-linecap="round"/><circle cx="60" cy="82" r="2.6" fill="{FACE}"/>')
    if tag:
        o.append(f'<path d="M48 84 L50 96" stroke="{INK}" stroke-width="0.8"/><rect x="44" y="94" width="11" height="14" rx="1.5" fill="{TAG}"/>'
                 f'<circle cx="49.5" cy="97" r="1.3" fill="{PAPER}"/>')
    # Fuse carriers, busbars and cables.
    for i, (bx, col) in enumerate(zip(BAR_X, PHASES + (PH_N,))):
        if i < 3:
            o.append(f'<rect x="{bx - 4}" y="{FUSE_Y - 4}" width="8" height="9" rx="1.5" fill="url(#porcelain)"/>')
            if blown_r and i == 0:
                o.append(f'<circle cx="{bx}" cy="{FUSE_Y}" r="3.4" fill="{SCORCH}" opacity="0.8"/>')
            o.append(f'<rect x="{bx - 2.5}" y="{BAR_Y0}" width="5" height="{BAR_Y1 - BAR_Y0}" rx="1" fill="url(#steel)"/>')
        else:
            o.append(f'<rect x="{bx - 2.5}" y="{BAR_Y0 + 8}" width="5" height="{BAR_Y1 - BAR_Y0 - 8}" rx="1" fill="url(#steel)"/>')
        o.append(f'<rect x="{bx - 3.5}" y="{BAR_Y1 - 2}" width="7" height="6" rx="1" fill="{col}"/>')
        if lifted is not None and i == lifted[0]:
            continue
        o.append(f'<path d="M{bx} {BAR_Y1 + 4} L{bx} {CAB_Y1}" stroke="{col}" stroke-width="3.6"/>')
    if lifted is not None:
        i, j = lifted
        bx, col = BAR_X[i], PHASES[i]
        # The service cable that was on phase i, its end lifted and led to phase j.
        o.append(f'<path d="M{bx} {CAB_Y1} C{bx} {CLAMP_Y} {BAR_X[j]} {CLAMP_Y + 8} {BAR_X[j]} {BAR_Y1 + 10}" stroke="{col}" stroke-width="3.6" fill="none"/>')
        o.append(f'<path d="M{bx} {BAR_Y1 + 4} L{bx} {BAR_Y1 + 12}" stroke="{col}" stroke-width="3.6" stroke-dasharray="2 2" opacity="0.6"/>')
    if earth:
        o.append(f'<path d="M{BAR_X[0]} {BAR_Y0 + 4} L33 {BAR_Y0 + 4} L33 {GY - 10}" stroke="{EARTH}" stroke-width="2" fill="none"/>'
                 + ''.join(f'<circle cx="{bx}" cy="{BAR_Y0 + 4}" r="2" fill="{EARTH}"/>' for bx in BAR_X[:3])
                 + f'<path d="M{BAR_X[0]} {BAR_Y0 + 4} L{BAR_X[2]} {BAR_Y0 + 4}" stroke="{EARTH}" stroke-width="2"/>')
    return ''.join(o)


def street(back='dusk', windows='dim', **kw):
    out = card_open(back)
    if back == 'noon':
        out.append('<circle cx="160" cy="34" r="14" fill="#FFE27A"/>')
    out.append(house(windows))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(pillar(**kw))
    return out


def clamping(out, k, x=112, look=8):
    """The worker clamps cable k (0..2 = R, Y, B; 3 = N)."""
    cx = BAR_X[k]
    hand = (cx + 14, CLAMP_Y + 18)
    out.append(worker(x, ((x - 14, 150), hand), face=-1, look=look))
    out.append(clamp_meter(cx, CLAMP_Y, hand))
    return out


def person(x, arms='down', face=-1):
    """The customer at his door: a green kurta, no helmet."""
    gy = GY
    o = [f'<path d="M{x - 4} {gy} L{x - 3} {gy - 26} M{x + 4} {gy} L{x + 3} {gy - 26}" stroke="{PANTS}" stroke-width="6" stroke-linecap="round"/>',
         f'<path d="M{x - 10} {gy - 22} L{x - 8} {gy - 66} Q{x} {gy - 72} {x + 8} {gy - 66} L{x + 10} {gy - 22} Z" fill="{KURTA}"/>']
    if arms == 'up':
        o.append(f'<path d="M{x - 7} {gy - 62} L{x - 16} {gy - 78} L{x - 14} {gy - 92} M{x + 7} {gy - 62} L{x + 16} {gy - 78} L{x + 14} {gy - 92}" '
                 f'stroke="{KURTA_D}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
                 f'<circle cx="{x - 14}" cy="{gy - 93}" r="3" fill="{SKIN}"/><circle cx="{x + 14}" cy="{gy - 93}" r="3" fill="{SKIN}"/>')
    else:
        o.append(f'<path d="M{x - 7} {gy - 62} L{x - 10} {gy - 44} L{x - 6} {gy - 30} M{x + 7} {gy - 62} L{x + 10} {gy - 44} L{x + 6} {gy - 30}" '
                 f'stroke="{KURTA_D}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
                 f'<circle cx="{x - 6}" cy="{gy - 29}" r="3" fill="{SKIN}"/><circle cx="{x + 6}" cy="{gy - 29}" r="3" fill="{SKIN}"/>')
    o.append(f'<circle cx="{x}" cy="{gy - 78}" r="8" fill="{SKIN}"/>'
             f'<path d="M{x - 8} {gy - 80} Q{x} {gy - 92} {x + 8} {gy - 80} Z" fill="{HAIR}"/>'
             f'<circle cx="{x + 4 * face}" cy="{gy - 78}" r="1.1" fill="{HAIR}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — spot: a fuse that keeps blowing, low voltage: measure, not guess.
# --------------------------------------------------------------------------

def spot_card(kind):
    if kind == 'phase':
        out = clamping(street(windows='dim', blown_r=True), 0)
    elif kind == 'neutral':
        out = clamping(street(windows='dim', blown_r=True), 3)
    elif kind == 'fuse':
        out = street(windows='dim', blown_r=True)
        out.append(worker(112, ((98, 150), (BAR_X[0] + 6, FUSE_Y + 2)), face=-1, look=10))
        out.append(f'<rect x="{BAR_X[0] + 2}" y="{FUSE_Y - 3}" width="9" height="9" rx="1.5" fill="url(#porcelain)"/>')
        for i, bx in enumerate((84, 98, 120)):
            out.append(f'<g transform="rotate({-20 + i * 25} {bx} {GY + 6})"><rect x="{bx - 5}" y="{GY + 2}" width="10" height="8" rx="1.5" fill="url(#porcelain)"/>'
                       f'<circle cx="{bx}" cy="{GY + 6}" r="3" fill="{SCORCH}" opacity="0.8"/></g>')
        out.append(meter_case(146))
    elif kind == 'guess':
        out = street(windows='dim', switch_on=False, lifted=(0, 2), blown_r=True)
        out.append(worker(112, ((98, 150), (BAR_X[1] + 10, CLAMP_Y + 6)), face=-1, look=4))
        out.append(meter_case(146))
    elif kind == 'ignore':
        out = street(windows='dim', door=False)
        out.append(worker(112, ((104, 160), (124, 162)), face=1, look=0))
        out.append(f'<rect x="120" y="156" width="16" height="12" rx="2" fill="{FACE}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — measure: at peak load, each phase and the neutral, on a list.
# --------------------------------------------------------------------------

def measure_card(kind):
    if kind == 'peak':
        out = clamping(street(windows='lit'), 1)
    elif kind == 'list':
        out = street(windows='lit')
        out.append(clamp_meter(BAR_X[3], CLAMP_Y, (BAR_X[3] + 10, CLAMP_Y + 20)))
        out.append(worker(112, ((106, 140), (118, 146)), face=-1, look=20))
        out.append(notebook(100, 128, rows=False, s=0.9))
        out.append(''.join(f'<rect x="104" y="{134 + i * 7}" width="{14 - i * 3}" height="3" rx="1" fill="{col}"/>' for i, col in enumerate(PHASES)))
    elif kind == 'noon':
        out = clamping(street(back='noon', windows='dark'), 1)
    elif kind == 'count':
        out = street(windows='lit')
        out.append(worker(112, ((98, 150), (150, 112)), face=1, look=-14, point=(0, 1)))
        out.append(meter_case(60, GY + 10))
        out.append(notebook(84, GY + 4, rows=False, s=0.5))
    elif kind == 'bulb':
        out = street(windows='lit')
        out.append(worker(124, ((112, 150), (146, 128)), face=1, look=-8))
        out.append(meter_case(60, GY + 10))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — plan: R=120A, Y=70A, B=50A (bars) — move some R lines to Y / B.
# --------------------------------------------------------------------------

COL_X = (46, 100, 154)
SLOT_Y = (124, 142, 160, 178, 196)
START = (4, 2, 2)            # houses on R, Y, B before the change


def mini_house(x, y, col, ghost=False):
    op = ' opacity="0.3"' if ghost else ''
    return (f'<g{op}><path d="M{x - 8} {y - 2} L{x} {y - 9} L{x + 8} {y - 2} Z" fill="{ROOF}"/>'
            f'<rect x="{x - 6.5}" y="{y - 2}" width="13" height="10" fill="{WALL}"/>'
            f'<rect x="{x - 2}" y="{y + 1}" width="4" height="4" fill="{LIT}"/>'
            f'<rect x="{x - 6.5}" y="{y + 8}" width="13" height="2.4" fill="{col}"/></g>')


def plan_card(moves):
    """moves: list of (from phase, to phase); each moves one house."""
    out = card_open('chart')
    # The readings, as bars over each phase column.
    for x, col, h in zip(COL_X, PHASES, (66, 38, 28)):
        out.append(f'<rect x="{x - 14}" y="{96 - h}" width="28" height="{h}" rx="2" fill="{col}"/>')
    out.append(f'<path d="M18 97 L182 97" stroke="#8A97A3" stroke-width="1.4"/>')
    count = list(START)
    gone = {0: [], 1: [], 2: []}
    arrows = []
    for a, b in moves:
        count[a] -= 1
        gone[a].append(count[a])
        arrows.append((a, count[a], b, count[b]))
        count[b] += 1
    for p, (x, col) in enumerate(zip(COL_X, PHASES)):
        out.append(f'<path d="M{x} 104 L{x} 206" stroke="{col}" stroke-width="2.4"/>')
        n = max(count[p], START[p])
        for s in range(n):
            side = -1 if s % 2 == 0 else 1
            hx = x + side * 13
            ghost = s in gone[p]
            if s < START[p] or s < count[p]:
                out.append(f'<path d="M{x} {SLOT_Y[s] + 6} L{hx} {SLOT_Y[s] + 6}" stroke="{col}" stroke-width="1.4"{" opacity=\"0.3\"" if ghost else ""}/>')
                out.append(mini_house(hx, SLOT_Y[s], col, ghost))
    for a, sa, b, sb in arrows:
        p0 = (COL_X[a] + (-13 if sa % 2 == 0 else 13), SLOT_Y[sa] - 4)
        p1 = (COL_X[b] + (-13 if sb % 2 == 0 else 13), SLOT_Y[sb] - 12)
        out.append(arrow(p0, p1, bend=-16))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — work: shutdown + PTW, and the customer told first.
# --------------------------------------------------------------------------

def work_card(kind):
    if kind in ('shutdown', 'wrong'):
        a, b = (0, 2) if kind == 'shutdown' else (2, 0)
        out = street(windows='dark', switch_on=False, tag=True, earth=True, lifted=(a, b))
        out.append(worker(112, ((98, 150), (BAR_X[b] + (8 if b == 2 else 18), BAR_Y1 + 14)), face=-1, look=10))
    elif kind == 'notify':
        out = street(windows='lit', door=False)
        out.append(person(176, 'down', face=-1))
        out.append(worker(132, ((122, 150), (150, 128)), face=1, look=-6))
    elif kind == 'live':
        out = street(windows='lit', switch_on=True, lifted=(0, 2))
        out.append(worker(112, ((98, 150), (BAR_X[2] + 8, BAR_Y1 + 14)), face=-1, look=10))
        out.append(spark(BAR_X[2], BAR_Y1 + 10, 0.9))
    elif kind == 'surprise':
        out = street(windows='dark', switch_on=False, tag=True, earth=True, lifted=(0, 2))
        out.append(person(176, 'up', face=-1))
        out.append(worker(108, ((94, 150), (BAR_X[2] + 8, BAR_Y1 + 14)), face=-1, look=10))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — check: measure again (neutral near zero) and keep a record.
# --------------------------------------------------------------------------

def check_card(kind):
    if kind == 'again':
        out = clamping(street(windows='lit'), 3)
        out.append(bubble(118, 34, (22, 21, 20, 3), tail=(124, 98)))
    elif kind == 'record':
        out = street(windows='lit')
        out.append(worker(112, ((104, 138), (120, 144)), face=-1, look=20))
        out.append(notebook(98, 124))
        out.append(bubble(118, 34, (22, 21, 20, 3)))
    elif kind == 'leave':
        out = street(windows='lit', door=False)
        out.append(worker(112, ((104, 160), (124, 162)), face=1, look=0))
        out.append(f'<rect x="120" y="156" width="16" height="12" rx="2" fill="{FACE}"/>')
        out.append(meter_case(146))
    elif kind == 'high':
        out = street(windows='lit')
        out.append(clamp_meter(BAR_X[3], CLAMP_Y, (BAR_X[3] + 10, CLAMP_Y + 20)))
        out.append(bubble(118, 34, (30, 18, 12, 18), tail=(BAR_X[3] + 14, CLAMP_Y + 6)))
        out.append(worker(140, ((132, 160), (152, 162)), face=1, look=0))
        out.append(f'<rect x="148" y="156" width="16" height="12" rx="2" fill="{FACE}"/>')
        out.append(notebook(96, GY - 6, rows=False, s=0.5))
    elif kind == 'bare':
        out = street(windows='lit')
        out.append(worker(112, ((98, 150), (BAR_X[3] + 2, CLAMP_Y)), face=-1, look=8, bare=True))
        out.append(spark(BAR_X[3], CLAMP_Y - 6, 0.9))
        out.append(bubble(118, 34, (30, 18, 12, 18)))
    return card_close(out)


CARDS = {
    'spot_phase': spot_card('phase'),
    'spot_neutral': spot_card('neutral'),
    'spot_fuse': spot_card('fuse'),
    'spot_guess': spot_card('guess'),
    'spot_ignore': spot_card('ignore'),
    'measure_peak': measure_card('peak'),
    'measure_list': measure_card('list'),
    'measure_noon': measure_card('noon'),
    'measure_count': measure_card('count'),
    'measure_bulb': measure_card('bulb'),
    'plan_r_to_b': plan_card([(0, 2)]),
    'plan_r_to_y': plan_card([(0, 1)]),
    'plan_b_to_r': plan_card([(2, 0)]),
    'plan_y_to_r': plan_card([(1, 0)]),
    'plan_all_to_b': plan_card([(0, 2), (0, 2), (0, 2)]),
    'work_shutdown': work_card('shutdown'),
    'work_notify': work_card('notify'),
    'work_live': work_card('live'),
    'work_surprise': work_card('surprise'),
    'work_wrong': work_card('wrong'),
    'check_again': check_card('again'),
    'check_record': check_card('record'),
    'check_leave': check_card('leave'),
    'check_high': check_card('high'),
    'check_bare': check_card('bare'),
}

# Safe cards and traps per round (mirrors learn_board_pack410.dart).
ROUNDS = {
    'spot': (['spot_phase', 'spot_neutral'], ['spot_fuse', 'spot_guess', 'spot_ignore']),
    'measure': (['measure_peak', 'measure_list'], ['measure_noon', 'measure_count', 'measure_bulb']),
    'plan': (['plan_r_to_b', 'plan_r_to_y'], ['plan_b_to_r', 'plan_y_to_r', 'plan_all_to_b']),
    'work': (['work_shutdown', 'work_notify'], ['work_live', 'work_surprise', 'work_wrong']),
    'check': (['check_again', 'check_record'], ['check_leave', 'check_high', 'check_bare']),
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
