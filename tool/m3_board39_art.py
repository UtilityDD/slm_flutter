"""Picture cards for lesson 3.9 শেখা ("গার্ড ওয়্যার ও ক্রেডল গার্ডিং: অতিরিক্ত সুরক্ষা জাল").

python -I tool/m3_board39_art.py .

Writes assets/game/art/m3_board39/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

One stage for every card: a line crossing over a road (or a railway, or a
telecom line) seen down the road; two poles, the three live conductors on
top, and the cradle guarding — a laced net of GI wire — hung below them on
its own arm, earthed down each pole.

What the cards show comes from lesson 3.9 and its film script only:
  1. cross: guarding is mandatory where a line crosses a road, a railway or a
     telecom line (Indian Electricity Rules);
  2. catch: a snapped live conductor falls on the earthed cradle (or, on a
     vertical-formation line, the cage) — a heavy phase-to-earth fault, the
     substation relay trips the breaker and the line goes dead. Traps: no
     guard (the wire falls on the road), stolen / broken earthing (the net
     itself turns live), a torn net that cannot hold the wire;
  3. build: the minimum vertical clearance between the live conductor and the
     net is mandatory; joints / clamps firm; the right tension — not too
     tight (it snaps), not too slack (it sags); the earthing wire run through
     a pipe against theft;
  4. patrol: at crossing points check the net is intact; rust, a broken
     wire, a sagging net (the wind swings it into the live wire) and a stolen
     earth wire are faults;
  5. repair: treat the guard as live until the line above is shut down and
     earthed; control the traffic below. The worker on the pole always wears
     a helmet and a full-body harness (house rule; not put into words here).

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
    print('usage: python -I tool/m3_board39_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board39')
W, H = 200, 220
HZ = 150          # horizon
GY = 204          # the near ground line (feet of a standing worker)

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
GI = '#6E7882'        # the galvanised guard wire
ARM = '#7D868E'       # steel arms, clamps, the earth pipe
EARTH = '#3E9B4F'     # earth leads (the guard's and the portable earth set)
RUST = '#B5652B'
LIVE = '#FFE38A'      # the hum of a line that is still live
LAMP = '#FF4B3E'
BUS = '#E9A23B'
BUS_D = '#B97A22'
GLASS = '#A8D4EE'
CONE = '#F07A22'
HARNESS = '#E8762B'
RAIL = '#B0B7BD'
SLEEPER = '#6B4F32'
DASH = '#F2F2F2'
TEL = '#4A3A2C'

LP, RP = 24, 176      # the two poles
P_TOP = 22
PH_Y = (28, 38, 42)   # top conductor, near and far conductors at the poles
ARM_Y = 64            # the guard arm
NET_TOP, NET_BOT = 64, 78

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6A6F75"/><stop offset="1" stop-color="#474B51"/></linearGradient>
  <linearGradient id="ballast" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A39A8E"/><stop offset="1" stop-color="#7D756B"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="panelIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E363E"/><stop offset="1" stop-color="#434C55"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='sky'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The worker (copied from tool/m2_board28_art.py): one figure, any pose.
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
    c = SKIN if bare else GLOVE
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, props_front=''):
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
    g.append(_hand(hb, bare))
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
    g.append(_hand(hf, bare))
    return ''.join(g)


def standing(x, hands, face=-1, look=0, s=1.0, props_front=''):
    """A standing worker, feet on GY, scaled s about his feet; hands in card
    coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, GY + (p[1] - GY) / s)
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    feet = ((x - 7 * face, GY - 1), (x + 6 * face, GY - 1))
    fig = figure(hip, sh, head, feet, (local(hands[0]), local(hands[1])), face, look, props_front=props_front)
    return f'<g transform="translate({f(x)} {GY}) scale({s}) translate({f(-x)} -{GY})">{fig}</g>'


def harness(hip, sh, pole_x):
    """Full-body harness straps over the torso and a pole strap round the pole."""
    hx, hy = hip
    sx, sy = sh
    return (f'<path d="M{f(sx - 4)} {f(sy)} L{f(hx - 4)} {f(hy - 2)} M{f(sx + 3)} {f(sy)} L{f(hx + 4)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2" fill="none"/>'
            f'<path d="M{f(hx - 7)} {f(hy - 2)} L{f(hx + 7)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2.4"/>'
            f'<path d="M{f((sx + hx) / 2 - 5)} {f((sy + hy) / 2)} L{f((sx + hx) / 2 + 5)} {f((sy + hy) / 2)}" stroke="{HARNESS}" stroke-width="1.6"/>'
            f'<path d="M{f(hx + 4)} {f(hy - 2)} Q{f((hx + pole_x) / 2)} {f(hy + 6)} {f(pole_x - 4)} {f(hy - 8)}" stroke="{HARNESS}" stroke-width="1.6" fill="none"/>'
            f'<path d="M{f(pole_x - 4)} {f(hy - 8)} L{f(pole_x + 4)} {f(hy - 8)}" stroke="{HARNESS}" stroke-width="1.8"/>')


def climber(bare=False, reach=(50, 80)):
    """The worker up the left pole at the guard arm, harnessed to the pole,
    one hand on the pole and one at the net."""
    hip = (36, 120)
    sh = (38, 94)
    head = (40, 86)
    feet = ((30, 148), (31, 136))
    fig = figure(hip, sh, head, feet, ((LP + 4, 100), reach), face=1, look=-14, bare=bare)
    return fig + harness(hip, sh, LP)


# --------------------------------------------------------------------------
# The stage.
# --------------------------------------------------------------------------

def sag_path(x0, y0, x1, y1, sag, col, w, extra=''):
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2 + sag * 2
    return f'<path d="M{f(x0)} {f(y0)} Q{f(mx)} {f(my)} {f(x1)} {f(y1)}" stroke="{col}" stroke-width="{f(w)}" fill="none"{extra}/>'


def qy(x, x0, x1, y, sag):
    """Height of a sagging span at x."""
    t = (x - x0) / (x1 - x0)
    return y + sag * 4 * t * (1 - t)


def ground(kind='road'):
    o = [f'<rect x="0" y="{HZ}" width="{W}" height="{H - HZ}" fill="url(#ground)"/>']
    if kind == 'road':
        o.append(f'<path d="M94 {HZ} L106 {HZ} L146 {H} L54 {H} Z" fill="url(#road)"/>')
        for y0, y1 in ((154, 160), (168, 178), (188, 204)):
            def xw(y):
                return 0.8 + (y - HZ) / (H - HZ) * 2.2
            o.append(f'<path d="M100 {y0} L100 {y1}" stroke="{DASH}" stroke-width="{f(xw((y0 + y1) / 2))}"/>')
    elif kind == 'rail':
        o.append(f'<path d="M92 {HZ} L108 {HZ} L150 {H} L50 {H} Z" fill="url(#ballast)"/>')
        for y in (154, 162, 172, 185, 202):
            t = (y - HZ) / (H - HZ)
            hw = 8 + 44 * t
            o.append(f'<path d="M{f(100 - hw)} {y} L{f(100 + hw)} {y}" stroke="{SLEEPER}" stroke-width="{f(1 + 3 * t)}"/>')
        o.append(f'<path d="M97 {HZ} L72 {H} M103 {HZ} L128 {H}" stroke="{RAIL}" stroke-width="2.6"/>')
    elif kind == 'tele':
        for x, yb, h in ((102, 154, 12), (108, 170, 26), (120, 206, 52)):
            o.append(f'<rect x="{f(x - 1 - h / 30)}" y="{yb - h}" width="{f(2 + h / 15)}" height="{h}" fill="{TEL}"/>')
            o.append(f'<path d="M{f(x - h / 4)} {yb - h + 2} L{f(x + h / 4)} {yb - h + 2}" stroke="{TEL}" stroke-width="{f(1 + h / 30)}"/>')
        for dx in (-1, 1):
            o.append(f'<path d="M{f(102 + dx * 3)} 144 L{f(108 + dx * 6.5)} 146 L{f(120 + dx * 13)} 156 L{f(136 + dx * 22)} 176" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    return ''.join(o)


def bus(x=100, y=148, s=1.0):
    w, h = 46 * s, 40 * s
    x0 = x - w / 2
    return (f'<rect x="{f(x0)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(5 * s)}" fill="{BUS}"/>'
            f'<rect x="{f(x0 + 4 * s)}" y="{f(y + 4 * s)}" width="{f(w - 8 * s)}" height="{f(14 * s)}" rx="{f(2 * s)}" fill="{GLASS}"/>'
            f'<rect x="{f(x0)}" y="{f(y + h - 9 * s)}" width="{f(w)}" height="{f(4 * s)}" fill="{BUS_D}"/>'
            f'<circle cx="{f(x0 + 6 * s)}" cy="{f(y + h - 14 * s)}" r="{f(2.4 * s)}" fill="{DASH}"/>'
            f'<circle cx="{f(x0 + w - 6 * s)}" cy="{f(y + h - 14 * s)}" r="{f(2.4 * s)}" fill="{DASH}"/>'
            f'<rect x="{f(x0 + 4 * s)}" y="{f(y + h)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="{BOOT}"/>'
            f'<rect x="{f(x0 + w - 12 * s)}" y="{f(y + h)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="{BOOT}"/>')


def cone(x, y, s=1.0):
    return (f'<path d="M{f(x - 6 * s)} {f(y)} L{f(x - 1.6 * s)} {f(y - 16 * s)} L{f(x + 1.6 * s)} {f(y - 16 * s)} L{f(x + 6 * s)} {f(y)} Z" fill="{CONE}"/>'
            f'<path d="M{f(x - 4 * s)} {f(y - 6 * s)} L{f(x + 4 * s)} {f(y - 6 * s)}" stroke="{DASH}" stroke-width="{f(2.2 * s)}"/>'
            f'<rect x="{f(x - 8 * s)}" y="{f(y - 1)}" width="{f(16 * s)}" height="2" fill="{CONE}"/>')


def pole(x, steps=False):
    o = [f'<rect x="{x - 4}" y="{P_TOP}" width="8" height="{GY - 4 - P_TOP}" fill="url(#pole)"/>']
    if steps:
        for y in range(104, 190, 12):
            o.append(f'<path d="M{x - 7} {y} L{x + 7} {y}" stroke="{ARM}" stroke-width="1.6"/>')
    return ''.join(o)


def insulator(x, y):
    return f'<rect x="{f(x - 2.6)}" y="{f(y)}" width="5.2" height="7" rx="1.8" fill="url(#porcelain)"/>'


def line_top(broken=None, live=False, earth_set=False):
    """Pole tops, cross-arms, insulators and the three conductors. broken =
    (left end, right end) of the snapped near conductor."""
    o = []
    for x in (LP, RP):
        o.append(f'<rect x="{x - 15}" y="{PH_Y[1] + 7}" width="30" height="3.4" fill="{ARM}"/>')
        o.append(insulator(x, PH_Y[0]))
        o.append(insulator(x - 11, PH_Y[1]))
        o.append(insulator(x + 11, PH_Y[2]))
    spans = [((LP, PH_Y[0]), (RP, PH_Y[0]), 5), ((LP - 11, PH_Y[2]), (RP + 11, PH_Y[2]), 6)]
    for (x0, y0), (x1, y1), s in spans:
        if live:
            o.append(sag_path(x0, y0, x1, y1, s, LIVE, 4.6, ' stroke-opacity="0.75"'))
        o.append(sag_path(x0, y0, x1, y1, s, WIRE, 1.8))
    x0, x1, y = LP - 11, RP + 11, PH_Y[1]
    if broken is None:
        if live:
            o.append(sag_path(x0, y, x1, y, 6, LIVE, 4.6, ' stroke-opacity="0.75"'))
        o.append(sag_path(x0, y, x1, y, 6, WIRE, 2))
    else:
        (lx, ly), (rx, ry) = broken
        for a, b in (((x0, y), (lx, ly)), ((x1, y), (rx, ry))):
            mx = (a[0] + b[0]) / 2
            d = f'M{f(a[0])} {f(a[1])} Q{f(mx)} {f(a[1] + 4)} {f(b[0])} {f(b[1])}'
            if live:
                o.append(f'<path d="{d}" stroke="{LIVE}" stroke-width="4.6" stroke-opacity="0.75" fill="none"/>')
            o.append(f'<path d="{d}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
    if earth_set:
        # A portable earth set clamped on all three conductors near the work.
        ex = 142
        tops = [qy(ex, LP, RP, PH_Y[0], 5), qy(ex, x0, x1, PH_Y[1], 6) + 0.5, qy(ex, x0, x1, PH_Y[2], 6) + 1]
        for i, ty in enumerate(tops):
            cx = ex + (i - 1) * 5
            o.append(f'<rect x="{f(cx - 2)}" y="{f(ty - 2)}" width="4" height="5" rx="1" fill="{ARM}"/>')
            o.append(f'<path d="M{f(cx)} {f(ty + 3)} Q{f(cx + 4)} {f(ty + 30)} {ex + 8} 120 L{ex + 16} {GY - 6}" stroke="{EARTH}" stroke-width="1.6" fill="none"/>')
        o.append(f'<rect x="{ex + 13}" y="{GY - 8}" width="6" height="8" fill="{ARM}"/>')
    return ''.join(o)


def guard_arm(x, drop=0):
    return (f'<rect x="{x - 16}" y="{ARM_Y + drop}" width="32" height="3.6" fill="{ARM}"/>'
            f'<circle cx="{x - 13}" cy="{f(ARM_Y + drop + 1.8)}" r="1.6" fill="{GI}"/><circle cx="{x + 13}" cy="{f(ARM_Y + drop + 1.8)}" r="1.6" fill="{GI}"/>')


def cradle(top=NET_TOP, bot=NET_BOT, sag=6, col=GI, rust=False, torn=False, broken=False, x0=LP + 13, x1=RP - 13, end_drop=None):
    """The cradle: a top wire (both side wires, seen edge-on) and the belly
    wire, laced together with U-shaped cross wires. torn = a hole in the
    middle; broken = a cross wire or two snapped and hanging; end_drop = the
    right end slipped from its clamp and hanging down to that height."""
    o = []
    xr = x1
    if end_drop is not None:
        # The right end has come off its clamp: the net hangs from the left arm.
        o.append(f'<path d="M{f(x0)} {f(top)} Q{f((x0 + xr) / 2)} {f(top + 34)} {f(xr - 8)} {f(end_drop)}" stroke="{col}" stroke-width="1.5" fill="none"/>')
        o.append(f'<path d="M{f(x0)} {f(bot)} Q{f((x0 + xr) / 2)} {f(bot + 36)} {f(xr - 14)} {f(end_drop + 10)}" stroke="{col}" stroke-width="1.5" fill="none"/>')
        for i in range(1, 12):
            t = i / 12
            xa = x0 + (xr - 8 - x0) * t
            ya = (1 - t) ** 2 * top + 2 * (1 - t) * t * (top + 34) + t * t * end_drop
            xb = x0 + (xr - 14 - x0) * t
            yb = (1 - t) ** 2 * bot + 2 * (1 - t) * t * (bot + 36) + t * t * (end_drop + 10)
            o.append(f'<path d="M{f(xa)} {f(ya)} L{f(xb)} {f(yb)}" stroke="{col}" stroke-width="0.9"/>')
        return ''.join(o)
    hole = (88, 112) if torn else None
    xs = [x0 + i * (x1 - x0) / 14 for i in range(15)]

    def seg(y, s, w):
        if hole is None:
            return sag_path(x0, y, x1, y, s, col, w)
        p = []
        for a, b in ((x0, hole[0]), (hole[1], x1)):
            ya, yb = qy(a, x0, x1, y, s * 2), qy(b, x0, x1, y, s * 2)
            p.append(f'<path d="M{f(a)} {f(ya)} L{f(b)} {f(yb)}" stroke="{col}" stroke-width="{w}" fill="none"/>')
        return ''.join(p)

    o.append(seg(top, sag, 1.9))
    o.append(seg(bot, sag, 1.9))
    for i, x in enumerate(xs[1:-1], 1):
        if hole and hole[0] - 2 < x < hole[1] + 2:
            continue
        ya = qy(x, x0, x1, top, sag)
        yb = qy(x, x0, x1, bot, sag)
        if broken and i in (5, 9):
            o.append(f'<path d="M{f(x)} {f(ya)} L{f(x - 1)} {f(ya + 4)}" stroke="{col}" stroke-width="0.9"/>')
            o.append(f'<path d="M{f(x)} {f(yb)} Q{f(x + 3)} {f(yb + 10)} {f(x - 1)} {f(yb + 18)}" stroke="{col}" stroke-width="0.9" fill="none"/>')
            continue
        o.append(f'<path d="M{f(x)} {f(ya)} Q{f(x + 3)} {f((ya + yb) / 2 + 3)} {f(x)} {f(yb)}" stroke="{col}" stroke-width="1.2" fill="none"/>')
        if i < len(xs) - 2:
            xn = xs[i + 1]
            o.append(f'<path d="M{f(x)} {f(yb)} L{f(xn)} {f(qy(xn, x0, x1, top, sag))}" stroke="{col}" stroke-width="0.8" stroke-opacity="0.85"/>')
    if hole:
        for a, d in ((hole[0], 1), (hole[1], -1)):
            yb = qy(a, x0, x1, bot, sag)
            o.append(f'<path d="M{f(a)} {f(yb)} Q{f(a + 4 * d)} {f(yb + 10)} {f(a + 1 * d)} {f(yb + 20)}" stroke="{col}" stroke-width="1.2" fill="none"/>')
    if rust:
        for x in (52, 74, 101, 126, 150):
            y = qy(x, x0, x1, (top + bot) / 2, sag)
            o.append(f'<ellipse cx="{x}" cy="{f(y)}" rx="6" ry="4" fill="{RUST}" opacity="0.85"/>')
    return ''.join(o)


def earth_lead(x, cut=False, pipe=False, side=1):
    """The guard's earth lead down the pole to an earth rod; cut = stolen
    below the cut; pipe = the lower part run inside a pipe."""
    ex = x + 5 * side
    o = [f'<circle cx="{ex}" cy="{ARM_Y + 4}" r="1.8" fill="{GI}"/>']
    if cut:
        o.append(f'<path d="M{ex} {ARM_Y + 3} L{ex} 118" stroke="{EARTH}" stroke-width="1.8"/>')
        o.append(f'<path d="M{ex - 2} 118 l2 3 l2 -3" stroke="{EARTH}" stroke-width="1.2" fill="none"/>')
        o.append(f'<rect x="{ex - 2}" y="{GY - 8}" width="4" height="4" fill="{ARM}"/>')
        return ''.join(o)
    o.append(f'<path d="M{ex} {ARM_Y + 3} L{ex} {GY - 6}" stroke="{EARTH}" stroke-width="1.8"/>')
    if pipe:
        o.append(f'<rect x="{ex - 2.6}" y="140" width="5.2" height="{GY - 140}" rx="1.2" fill="{ARM}"/>')
        o.append(f'<rect x="{ex - 3.4}" y="139" width="6.8" height="2.4" rx="1" fill="{GI}"/>')
    o.append(f'<rect x="{ex - 2}" y="{GY - 8}" width="4" height="8" fill="{ARM}"/>')
    return ''.join(o)


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def wind(x, y):
    return ''.join(f'<path d="M{x + dx} {y + dy} q8 -4 16 0 t16 0" stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-opacity="0.85" stroke-linecap="round"/>'
                   for dx, dy in ((0, 0), (12, 10), (-6, 20)))


def breaker(tripped):
    """The substation breaker, inset at the top of the card: lever up and lamp
    lit = the line still on; lever down, lamp dark = tripped."""
    x, y = 82, 4
    o = [f'<rect x="{x}" y="{y}" width="36" height="17" rx="3" fill="url(#panelIn)" stroke="{ARM}" stroke-width="1"/>']
    o.append(f'<rect x="{x + 6}" y="{y + 4}" width="8" height="9" rx="1.5" fill="{ARM}"/>')
    ly = y + 11 if tripped else y + 2
    o.append(f'<path d="M{x + 10} {y + 8.5} L{x + 10} {ly}" stroke="{HELMET}" stroke-width="2.6" stroke-linecap="round"/>')
    if not tripped:
        o.append(f'<circle cx="{x + 26}" cy="{y + 8.5}" r="6" fill="url(#glow)"/>')
    o.append(f'<circle cx="{x + 26}" cy="{y + 8.5}" r="3" fill="{LAMP}" opacity="{1 if not tripped else 0.25}"/>')
    return ''.join(o)


def stage(floor='road', guard=True, net=None, cut=False, pipe=False, broken=None, live=False, earth_set=False, steps=False,
          arm_drop=0):
    out = card_open('sky')
    out.append(ground(floor))
    out.append(pole(LP, steps))
    out.append(pole(RP))
    if guard:
        out.append(guard_arm(LP, arm_drop))
        out.append(guard_arm(RP, arm_drop))
    out.append(earth_lead(LP, cut=cut, pipe=pipe, side=-1))
    out.append(earth_lead(RP, cut=cut, pipe=pipe, side=1))
    out.append(line_top(broken, live, earth_set))
    if guard:
        out.append(net if net is not None else cradle())
    return out


# --------------------------------------------------------------------------
# Round 1 — cross: where the guarding is mandatory.
# --------------------------------------------------------------------------

def cross_card(kind):
    floor = {'road': 'road', 'rail': 'rail', 'road_bare': 'road', 'rail_bare': 'rail', 'tele_bare': 'tele'}[kind]
    guard = not kind.endswith('_bare')
    out = stage(floor, guard=guard)
    if floor == 'road':
        out.insert(5, bus(100, 160, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — catch: a snapped live conductor on the earthed net trips the line.
# --------------------------------------------------------------------------

def cage():
    """Cage guarding round a vertical-formation line on side brackets."""
    o = []
    for x, d in ((LP, 1), (RP, -1)):
        o.append(f'<rect x="{min(x, x + 14 * d)}" y="16" width="14" height="3" fill="{ARM}"/>')
        o.append(f'<rect x="{min(x, x + 14 * d)}" y="62" width="14" height="3" fill="{ARM}"/>')
    return ''.join(o)


def catch_card(kind):
    fell_road = ((92, 170), (108, 172))
    on_net = ((94, qy(94, LP + 13, RP - 13, NET_BOT, 6) - 2), (106, qy(106, LP + 13, RP - 13, NET_BOT, 6) - 2))
    if kind == 'cage':
        out = card_open('sky')
        out.append(ground('road'))
        out.append(bus(100, 160, 0.9))
        out.append(pole(LP) + pole(RP))
        out.append(cage())
        for i, y in enumerate((26, 38, 50)):
            for x, d in ((LP, 1), (RP, -1)):
                out.append(f'<rect x="{min(x, x + 8 * d)}" y="{y + 5}" width="8" height="2.4" fill="{ARM}"/>')
                out.append(insulator(x + 8 * d, y))
        out.append(sag_path(LP + 8, 26, RP - 8, 26, 5, WIRE, 1.8))
        out.append(sag_path(LP + 8, 50, RP - 8, 50, 5, WIRE, 1.8))
        for a, b in (((LP + 8, 38), (94, 66)), ((RP - 8, 38), (106, 66))):
            out.append(f'<path d="M{a[0]} {a[1]} Q{f((a[0] + b[0]) / 2)} {a[1] + 4} {b[0]} {b[1]}" stroke="{WIRE}" stroke-width="2" fill="none"/>')
        out.append(cradle(16, 64, 3, x0=LP + 13, x1=RP - 13))
        out.append(sag_path(LP + 13, 64, RP - 13, 64, 3, GI, 1.5))
        out.append(earth_lead(LP, side=-1) + earth_lead(RP, side=1))
        out.append(breaker(True))
        return card_close(out)
    if kind == 'road':
        out = stage('road', guard=False, broken=fell_road, live=True)
        out.insert(5, bus(100, 160, 0.9))
        out.append(spark(96, 174, 0.9))
        out.append(breaker(False))
        return card_close(out)
    if kind == 'torn':
        out = stage('road', net=cradle(torn=True), broken=fell_road, live=True)
        out.insert(5, bus(100, 160, 0.9))
        out.append(spark(96, 174, 0.9))
        out.append(breaker(False))
        return card_close(out)
    if kind == 'noearth':
        out = stage('road', broken=on_net, cut=True, live=True)
        out.insert(5, bus(100, 160, 0.9))
        out.append(f'<path d="M{LP + 13} {NET_TOP} Q100 {NET_TOP + 12} {RP - 13} {NET_TOP}" stroke="{LIVE}" stroke-width="4" stroke-opacity="0.7" fill="none"/>')
        out.append(spark(100, 84, 0.8))
        out.append(breaker(False))
        return card_close(out)
    # 'cradle': caught on the earthed net, the breaker has tripped.
    out = stage('road', broken=on_net)
    out.insert(5, bus(100, 160, 0.9))
    out.append(breaker(True))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — build: clearance, firm joints, the right tension, earth in a pipe.
# --------------------------------------------------------------------------

def gap_mark(x, y0, y1):
    return (f'<path d="M{x} {f(y0 + 3)} L{x} {f(y1 - 3)}" stroke="#FFFFFF" stroke-width="1.2"/>'
            f'<path d="M{x - 3} {f(y0 + 6)} L{x} {f(y0 + 2)} L{x + 3} {f(y0 + 6)} M{x - 3} {f(y1 - 6)} L{x} {f(y1 - 2)} L{x + 3} {f(y1 - 6)}" stroke="#FFFFFF" stroke-width="1.2" fill="none"/>')


def build_card(kind):
    if kind == 'close':
        out = stage('road', net=cradle(top=46, bot=58, sag=4), arm_drop=-18)
        out.append(spark(72, 47, 0.7))
    elif kind == 'tight':
        net = cradle(sag=0) + f'<path d="M{LP + 13} {NET_TOP + 7} L{RP - 13} {NET_TOP + 7}" stroke="{GI}" stroke-width="1.2"/>'
        out = stage('road', net=net)
        # A wire pulled too tight has snapped next to the right clamp.
        out.append(f'<path d="M{RP - 22} {NET_BOT} Q{RP - 30} {NET_BOT + 12} {RP - 26} {NET_BOT + 22}" stroke="{GI}" stroke-width="1.5" fill="none"/>')
        out.append(f'<path d="M{RP - 18} {NET_BOT} Q{RP - 12} {NET_BOT + 8} {RP - 16} {NET_BOT + 16}" stroke="{GI}" stroke-width="1.5" fill="none"/>')
        out.append(f'<rect x="{RP - 21}" y="{NET_BOT - 3}" width="2" height="6" fill="#FFFFFF"/>')
    elif kind == 'slack':
        out = stage('road', net=cradle(top=NET_TOP, bot=NET_BOT, sag=28))
    elif kind == 'joint':
        out = stage('road', net=cradle(end_drop=150))
        out.append(f'<path d="M{RP - 13} {ARM_Y + 2} l-3 6 M{RP - 13} {ARM_Y + 2} l3 6" stroke="{GI}" stroke-width="1.2"/>')
    else:
        out = stage('road', pipe=kind == 'pipe')
        if kind == 'gap':
            out.append(gap_mark(64, qy(64, LP - 11, RP + 11, PH_Y[1], 6) + 2, qy(64, LP + 13, RP - 13, NET_TOP, 6)))
    out.insert(5, bus(100, 160, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — patrol: what an intact guarding looks like at a crossing.
# --------------------------------------------------------------------------

def patroller(kind):
    if kind == 'earth':
        return standing(46, ((40, 176), (33, 166)), face=-1, look=6, s=1.05)
    return standing(150, ((144, 176), (138, 136)), face=-1, look=-18, s=1.05)


def patrol_card(kind):
    if kind == 'rust':
        out = stage('road', net=cradle(rust=True))
    elif kind == 'broken':
        out = stage('road', net=cradle(broken=True))
    elif kind == 'sag':
        net = f'<g transform="rotate(-9 {LP + 13} {NET_TOP})">' + cradle(sag=16) + '</g>'
        out = stage('road', net=net)
        out.append(spark(150, 46, 0.7))
        out.append(wind(110, 100))
    elif kind == 'stolen':
        out = stage('road', cut=True)
    else:
        out = stage('road', pipe=True)
    out.insert(5, bus(100, 160, 0.7))
    out.append(patroller(kind))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — repair: line above shut down and earthed, traffic held below.
# --------------------------------------------------------------------------

def flagman():
    flag = (f'<path d="M150 134 L150 112" stroke="{WIRE}" stroke-width="1.6"/>'
            f'<path d="M150 112 L164 116 L150 121 Z" fill="{CONE}"/>')
    return standing(140, ((132, 176), (150, 134)), face=1, look=0, s=1.05, props_front=flag)


def repair_card(kind):
    earthed = kind in ('earthed', 'traffic', 'cars')
    live = not earthed
    out = stage('road', live=live, earth_set=earthed, steps=True)
    if kind == 'cars':
        out.insert(5, bus(100, 158, 1.0))
    else:
        out.insert(5, bus(100, 152, 0.62))
        for x in (78, 100, 122):
            out.append(cone(x, 188, 0.9))
    if kind in ('traffic', 'live'):
        out.append(flagman())
    out.append(climber(bare=kind == 'bare'))
    return card_close(out)


CARDS = {
    'cross_road': cross_card('road'),
    'cross_rail': cross_card('rail'),
    'cross_road_bare': cross_card('road_bare'),
    'cross_rail_bare': cross_card('rail_bare'),
    'cross_tele_bare': cross_card('tele_bare'),
    'catch_cradle': catch_card('cradle'),
    'catch_cage': catch_card('cage'),
    'catch_road': catch_card('road'),
    'catch_noearth': catch_card('noearth'),
    'catch_torn': catch_card('torn'),
    'build_gap': build_card('gap'),
    'build_pipe': build_card('pipe'),
    'build_close': build_card('close'),
    'build_tight': build_card('tight'),
    'build_slack': build_card('slack'),
    'build_joint': build_card('joint'),
    'patrol_intact': patrol_card('intact'),
    'patrol_earth': patrol_card('earth'),
    'patrol_rust': patrol_card('rust'),
    'patrol_broken': patrol_card('broken'),
    'patrol_sag': patrol_card('sag'),
    'patrol_stolen': patrol_card('stolen'),
    'repair_earthed': repair_card('earthed'),
    'repair_traffic': repair_card('traffic'),
    'repair_live': repair_card('live'),
    'repair_bare': repair_card('bare'),
    'repair_cars': repair_card('cars'),
}

# Safe cards and traps per round (mirrors learn_board_pack39.dart).
ROUNDS = {
    'cross': (['cross_road', 'cross_rail'], ['cross_road_bare', 'cross_rail_bare', 'cross_tele_bare']),
    'catch': (['catch_cradle', 'catch_cage'], ['catch_road', 'catch_noearth', 'catch_torn']),
    'build': (['build_gap', 'build_pipe'], ['build_close', 'build_tight', 'build_slack', 'build_joint']),
    'patrol': (['patrol_intact', 'patrol_earth'], ['patrol_rust', 'patrol_broken', 'patrol_sag', 'patrol_stolen']),
    'repair': (['repair_earthed', 'repair_traffic'], ['repair_live', 'repair_bare', 'repair_cars']),
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
