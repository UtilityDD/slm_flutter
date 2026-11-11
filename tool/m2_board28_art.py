"""Picture cards for lesson 2.8 শেখা ("ফেজ সিকোয়েন্স মিটার: সঠিক ঘূর্ণন").

python -I tool/m2_board28_art.py .

Writes assets/game/art/m2_board28/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the phases are told by their R / Y / B colours only.

What the cards show comes from lesson 2.8 only:
  1. when: after any new three-phase connection or a big repair the phase
     sequence is tested (mandatory); colours are not to be trusted; a motor
     started on a reversed sequence turns backwards (a lift / conveyor), and
     even a second backwards can ruin a pump / compressor / gearbox;
  2. meter: rotating-disc type turns clockwise on the right sequence,
     anti-clockwise on the wrong one; the digital type lights FWD/clockwise or
     REV/anti-clockwise; the old two-lamp + capacitor test is less reliable
     and dangerous (open wires on a live circuit);
  3. probe: it is a live-line test — full PPE, insulated gloves above all;
     the three probes / clips on R, Y and B must not touch each other or an
     earthing point; damaged probes or leads are not used; a non-contact
     (clamp) meter measures through the insulation for extra safety;
  4. fix: a reversed (R-B-Y) reading is put right by swapping any two phases
     (e.g. Y and B). The swap is drawn with the isolator OFF (the lesson does
     not say so; the house rule "work on lines only after shutdown" does);
  5. grid: after a new transformer or work on its HT / LT side the sequence
     is tested; a generator is synchronised to the grid only when the two
     sequences match — a wrong one is a deadly explosion.

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
    print('usage: python -I tool/m2_board28_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board28')
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
COPPER = '#D98A3D'
PH_R = '#D8402F'
PH_Y = '#F0C02E'
PH_B = '#2F6BCB'
PHASES = (PH_R, PH_Y, PH_B)
LED_G = '#4CD964'
LED_R = '#FF4B3E'
EARTH = '#3E9B4F'
METER = '#E8742A'
METER_D = '#B9561A'
FACE = '#1E2329'

DEFS = """<defs>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5D6E7C"/><stop offset="1" stop-color="#8C9AA5"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3C4A57"/><stop offset="1" stop-color="#65788A"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7B7F82"/><stop offset="1" stop-color="#5F6366"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AC"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#8E98A0"/></linearGradient>
  <linearGradient id="panelIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E363E"/><stop offset="1" stop-color="#434C55"/></linearGradient>
  <linearGradient id="motor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3F7FA6"/><stop offset="0.5" stop-color="#5E9CC2"/><stop offset="1" stop-color="#2F6587"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="genset" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E2B23A"/><stop offset="1" stop-color="#B98A22"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="belt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A3F45"/><stop offset="1" stop-color="#22262B"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="blast" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE38A"/><stop offset="0.7" stop-color="#FF7A2E" stop-opacity="0.7"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
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
# Things.
# --------------------------------------------------------------------------

def arc_arrow(cx, cy, r, cw, w=1.6, color='#FFFFFF', op=1.0):
    """A 270-degree arrow round (cx, cy): clockwise or anti-clockwise."""
    a0, a1 = math.radians(-200), math.radians(40)
    if not cw:
        a0, a1 = a1, a0
    p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
    p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
    sweep = 1 if cw else 0
    tx, ty = (-math.sin(a1), math.cos(a1)) if cw else (math.sin(a1), -math.cos(a1))
    nx, ny = -ty, tx
    hl = w * 2.6
    tip = (p1[0] + tx * hl, p1[1] + ty * hl)
    b1 = (p1[0] + nx * hl * 0.8, p1[1] + ny * hl * 0.8)
    b2 = (p1[0] - nx * hl * 0.8, p1[1] - ny * hl * 0.8)
    return (f'<g opacity="{op}"><path d="M{f(p0[0])} {f(p0[1])} A{f(r)} {f(r)} 0 1 {sweep} {f(p1[0])} {f(p1[1])}" stroke="{color}" '
            f'stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(tip[0])} {f(tip[1])} L{f(b1[0])} {f(b1[1])} L{f(b2[0])} {f(b2[1])} Z" fill="{color}"/></g>')


def meter(x, y, kind='disc', state='cw', s=1.0):
    """A handheld phase sequence meter, top-centre at (x, y): an orange body;
    a rotating-disc window or two LEDs (FWD green, REV red) with their arrows."""
    w, h = 22 * s, 30 * s
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER}" stroke="{METER_D}" stroke-width="{f(1.2 * s)}"/>',
         f'<rect x="{f(x - w / 2 + 3 * s)}" y="{f(y + 3 * s)}" width="{f(w - 6 * s)}" height="{f(17 * s)}" rx="{f(2 * s)}" fill="{FACE}"/>']
    cx, cy = x, y + 11.5 * s
    if kind == 'disc':
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(6.4 * s)}" fill="#F4F1E8"/>')
        ang = {'cw': 30, 'ccw': -30, 'off': 0}[state]
        o.append(f'<g transform="rotate({ang} {f(cx)} {f(cy)})"><path d="M{f(cx - 6.4 * s)} {f(cy)} L{f(cx + 6.4 * s)} {f(cy)}" stroke="{FACE}" stroke-width="{f(2.4 * s)}"/>'
                 f'<circle cx="{f(cx + 4 * s)}" cy="{f(cy)}" r="{f(1.3 * s)}" fill="{PH_R}"/></g>')
        if state != 'off':
            o.append(arc_arrow(cx, cy, 4.4 * s, state == 'cw', 1.2 * s, PH_R))
    else:
        for dx, col, cw, on in ((-4.2, LED_G, True, state == 'cw'), (4.2, LED_R, False, state == 'ccw')):
            lx = cx + dx * s
            if on:
                o.append(f'<circle cx="{f(lx)}" cy="{f(cy - 2.4 * s)}" r="{f(5 * s)}" fill="url(#glow)"/>')
            o.append(f'<circle cx="{f(lx)}" cy="{f(cy - 2.4 * s)}" r="{f(2.3 * s)}" fill="{col}" opacity="{1 if on else 0.28}"/>')
            o.append(arc_arrow(lx, cy + 3.8 * s, 2 * s, cw, 0.55 * s, '#FFFFFF', 0.9 if on else 0.35))
    for i, col in enumerate(PHASES):
        o.append(f'<circle cx="{f(x + (i - 1) * 6 * s)}" cy="{f(y + 25 * s)}" r="{f(1.8 * s)}" fill="{col}"/>')
    return ''.join(o)


def lead(p0, p1, col, sag=10, w=1.6, torn=False):
    mx, my = (p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + sag
    s = f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="{col}" stroke-width="{f(w)}" fill="none"/>'
    s += f'<rect x="{f(p1[0] - 2.2)}" y="{f(p1[1] - 1)}" width="4.4" height="6" rx="1" fill="{col}" stroke="{WIRE}" stroke-width="0.6"/>'
    if torn:
        q = (0.25 * p0[0] + 0.5 * mx + 0.25 * p1[0], 0.25 * p0[1] + 0.5 * my + 0.25 * p1[1])
        s += (f'<path d="M{f(q[0] - 4)} {f(q[1] - 1)} l3 2 l2 -2 l3 2" stroke="{COPPER}" stroke-width="1.6" fill="none"/>'
              + spark(q[0], q[1] - 3, 0.6))
    return s


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def blast(x, y, r=40):
    rays = ''.join(f'<path d="M{f(x + math.cos(a) * r * 0.3)} {f(y + math.sin(a) * r * 0.3)} L{f(x + math.cos(a) * r)} {f(y + math.sin(a) * r)}"/>'
                   for a in [i * math.pi / 6 + 0.2 for i in range(12)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#blast)"/>'
            f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9">{rays}</g>')


def case_on_floor(x):
    """The meter left lying on the floor, unused."""
    return (f'<g transform="rotate(-90 {f(x)} {GY - 6})">' + meter(x, GY - 17, 'disc', 'off', 0.75) + '</g>')


def flow_arrows(x0, x1, y, back=False, col='#FFFFFF'):
    """Chevrons along a belt: forward = to the right, back = to the left."""
    o = []
    step = 16
    xs = range(int(x0) + 6, int(x1) - 4, step)
    for x in xs:
        d = -1 if back else 1
        o.append(f'<path d="M{f(x - 3 * d)} {f(y - 4)} L{f(x + 3 * d)} {f(y)} L{f(x - 3 * d)} {f(y + 4)}" stroke="{col}" stroke-width="2" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# The workshop stage: an open LT panel on the left (R, Y, B terminals, a
# start / stop station and an isolator), a motor driving a conveyor (or a
# pump) on the right.
# --------------------------------------------------------------------------

PNL = (12, 46, 74, 104)          # x, y, w, h of the panel
TERM_Y = 70
TERM_X = (30, 49, 68)
ISO = (90, 66)                   # the isolator box (x, y)
BTN = (90, 104)                  # the start / stop station (x, y)


def panel(iso_on=True, earth_hit=False):
    x, y, w, h = PNL
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#panel)"/>',
         f'<rect x="{x + 6}" y="{y + 8}" width="{w - 12}" height="{h - 16}" rx="2" fill="url(#panelIn)"/>']
    # Busbars with phase-coloured sleeves, cables down to the gland.
    for tx, col in zip(TERM_X, PHASES):
        o.append(f'<rect x="{tx - 3}" y="{TERM_Y - 10}" width="6" height="30" rx="1.2" fill="url(#steel)"/>')
        o.append(f'<rect x="{tx - 3.6}" y="{TERM_Y + 8}" width="7.2" height="6" rx="1" fill="{col}"/>')
        o.append(f'<path d="M{tx} {TERM_Y + 20} L{tx} {y + h - 14}" stroke="{col}" stroke-width="3.4"/>')
    # The earth bar along the bottom.
    o.append(f'<rect x="{x + 12}" y="{y + h - 16}" width="{w - 24}" height="4" rx="1" fill="url(#steel)"/>')
    o.append(f'<path d="M{x + 14} {y + h - 12} L{x + 14} {y + h - 2}" stroke="{EARTH}" stroke-width="2.4"/>')
    # Isolator: handle up = ON, down = OFF.
    ix, iy = ISO
    o.append(f'<rect x="{ix}" y="{iy}" width="18" height="26" rx="2" fill="url(#panel)" stroke="#6F7880" stroke-width="0.8"/>')
    hy = iy + 5 if iso_on else iy + 21
    o.append(f'<path d="M{ix + 9} {iy + 13} L{ix + 9} {hy}" stroke="{FACE}" stroke-width="3.4" stroke-linecap="round"/>')
    o.append(f'<circle cx="{ix + 9}" cy="{iy + 13}" r="2.6" fill="{FACE}"/>')
    # Start (green) / stop (red) buttons.
    bx, by = BTN
    o.append(f'<rect x="{bx}" y="{by}" width="18" height="24" rx="2" fill="url(#panel)" stroke="#6F7880" stroke-width="0.8"/>')
    o.append(f'<circle cx="{bx + 9}" cy="{by + 7}" r="3.6" fill="{LED_G}"/><circle cx="{bx + 9}" cy="{by + 17}" r="3.6" fill="{LED_R}"/>')
    # Cable from the panel to the motor along the floor.
    o.append(f'<path d="M{x + w / 2} {y + h} L{x + w / 2} {GY - 2} L150 {GY - 2}" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    return ''.join(o)


def motor(x=150, y=GY - 30):
    return (f'<rect x="{x}" y="{y}" width="34" height="26" rx="5" fill="url(#motor)"/>'
            + ''.join(f'<path d="M{x + 4 + i * 5} {y + 3} L{x + 4 + i * 5} {y + 23}" stroke="#2A5674" stroke-width="1"/>' for i in range(6))
            + f'<rect x="{x + 10}" y="{y - 6}" width="12" height="7" rx="1.5" fill="url(#motor)"/>'
            + f'<rect x="{x + 4}" y="{y + 26}" width="26" height="4" fill="{FACE}"/>'
            + f'<rect x="{x + 34}" y="{y + 11}" width="8" height="4" fill="url(#steel)"/>')


def conveyor(back=False, falling=False):
    """A belt above the motor; back = running backwards (boxes tumbling)."""
    o = [f'<rect x="118" y="118" width="86" height="9" rx="4.5" fill="url(#belt)"/>',
         f'<circle cx="123" cy="122.5" r="4.5" fill="url(#steel)"/>',
         f'<path d="M126 127 L126 {GY} M196 127 L196 {GY}" stroke="#6F7880" stroke-width="3"/>',
         f'<path d="M167 {GY - 30} L190 127" stroke="{FACE}" stroke-width="2"/>']
    for bx in (150, 176):
        o.append(f'<rect x="{bx}" y="103" width="15" height="15" rx="1.5" fill="#B98A50" stroke="#8A6438" stroke-width="1"/>')
    if back:
        o.append(flow_arrows(130, 200, 112 - 22, back=True, col=LED_R))
    if falling:
        o.append('<rect x="104" y="128" width="15" height="15" rx="1.5" fill="#B98A50" stroke="#8A6438" stroke-width="1" transform="rotate(-28 111 135)"/>')
        o.append('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85"><path d="M118 116 l4 -6"/><path d="M112 118 l2 -7"/></g>')
    return ''.join(o)


def pump(broken=False):
    o = [f'<path d="M192 {GY - 30} L192 120 L204 120" stroke="#6F7880" stroke-width="6" fill="none"/>',
         f'<circle cx="192" cy="{GY - 17}" r="14" fill="url(#motor)" stroke="#2A5674" stroke-width="1.2"/>',
         f'<circle cx="192" cy="{GY - 17}" r="4" fill="url(#steel)"/>']
    if broken:
        o.append(f'<path d="M184 {GY - 28} l5 7 l-3 5 l6 6" stroke="{FACE}" stroke-width="1.6" fill="none"/>')
        o.append(spark(188, GY - 22, 0.9))
        o.append(arc_arrow(192, GY - 17, 9, False, 1.8, LED_R))
    return ''.join(o)


def shop(load='belt', iso_on=True, back=False, falling=False, broken=False, coil=False, repair=False):
    out = card_open('wall')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#floor)"/>')
    out.append(panel(iso_on))
    if load == 'belt':
        out.append(conveyor(back, falling))
    out.append(motor())
    if load == 'pump':
        out.append(pump(broken))
    if coil:
        out.append(f'<ellipse cx="96" cy="{GY + 8}" rx="12" ry="5" fill="none" stroke="{WIRE}" stroke-width="2.6"/>'
                   f'<ellipse cx="96" cy="{GY + 8}" rx="8" ry="3" fill="none" stroke="{WIRE}" stroke-width="2"/>')
    if repair:
        out.append(f'<rect x="156" y="{GY - 44}" width="22" height="7" rx="1.5" fill="url(#motor)" transform="rotate(-24 167 {GY - 40})"/>')
        out.append(f'<g transform="translate(108 {GY + 10}) rotate(-8)"><rect x="0" y="-1.6" width="16" height="3.2" rx="1.2" fill="url(#steel)"/>'
                   '<path d="M16 -4.4 L22 -4.4 L22 -1.6 L19 -1.6 L19 1.6 L22 1.6 L22 4.4 L16 4.4 Z" fill="url(#steel)"/></g>')
    return out


def testing(out, kind='disc', state='cw', bare=False, clips=None, torn=False, x=118):
    """The worker at the panel, the meter in his left hand, leads on R/Y/B."""
    mx, my = 96, 120
    out.append(worker(x, ((mx + 4, my + 20), (mx + 2, my + 12)), face=-1, look=10, bare=bare))
    out.append(meter(mx, my, kind, state, 1.0))
    clips = clips or [(tx, TERM_Y + 2) for tx in TERM_X]
    for i, (col, c) in enumerate(zip(PHASES, clips)):
        out.append(lead((mx - 6 + i * 6, my + 2), c, col, sag=6 + i * 4, torn=torn and i == 1))
    return out


# --------------------------------------------------------------------------
# Round 1 — when: test after a new connection or a big repair.
# --------------------------------------------------------------------------

def when_card(kind):
    if kind == 'new':
        out = testing(shop(coil=True), 'disc', 'cw')
    elif kind == 'repair':
        out = testing(shop(repair=True), 'disc', 'cw')
    elif kind == 'colour':
        out = shop(coil=True)
        out.append(worker(118, ((104, 150), (74, 92)), face=-1, look=-6, point=(0, -1)))
        out.append(case_on_floor(150))
    elif kind == 'run':
        out = shop(coil=True, back=True, falling=True)
        out.append(worker(124, ((110, 150), (BTN[0] + 9, BTN[1] + 7)), face=-1, look=0))
        out.append(case_on_floor(84))
    elif kind == 'pump':
        out = shop(load='pump', repair=True)
        out.append(worker(124, ((110, 150), (BTN[0] + 9, BTN[1] + 7)), face=-1, look=0))
        out.append(case_on_floor(84))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — meter: reading the disc or the LEDs (close-up).
# --------------------------------------------------------------------------

def bench_stage():
    out = card_open('bench')
    # The terminal block along the top: R, Y, B.
    out.append('<rect x="24" y="10" width="152" height="30" rx="4" fill="url(#panelIn)"/>')
    for i, col in enumerate(PHASES):
        x = 54 + i * 46
        out.append(f'<rect x="{x - 8}" y="14" width="16" height="22" rx="2" fill="url(#steel)"/>')
        out.append(f'<rect x="{x - 9}" y="30" width="18" height="7" rx="1.5" fill="{col}"/>')
    return out


def gloved_hand(x, y, s=3.0):
    """A big black rubber glove holding the meter from below."""
    return (f'<path d="M{f(x - 34)} {f(y + 30)} Q{f(x - 40)} {f(y + 4)} {f(x - 30)} {f(y - 6)} L{f(x - 22)} {f(y - 4)} '
            f'L{f(x - 22)} {f(y + 20)} L{f(x + 22)} {f(y + 20)} L{f(x + 22)} {f(y - 4)} L{f(x + 30)} {f(y - 6)} '
            f'Q{f(x + 40)} {f(y + 4)} {f(x + 34)} {f(y + 30)} L{f(x + 26)} {f(y + 60)} L{f(x - 26)} {f(y + 60)} Z" fill="{GLOVE}"/>'
            f'<rect x="{f(x - 28)}" y="{f(y + 56)}" width="56" height="20" fill="url(#shirt)"/>')


def meter_card(kind):
    out = bench_stage()
    if kind == 'lamp':
        # Two bulbs and a capacitor wired star-fashion with bare wire ends.
        cx, cy = 100, 132
        for i, (x, y) in enumerate(((60, 112), (140, 112))):
            out.append(f'<path d="M{54 + i * 92} 36 Q{x - 10} 70 {x} {y - 14}" stroke="{COPPER}" stroke-width="2" fill="none"/>')
            if i == 0:
                out.append(f'<circle cx="{x}" cy="{y}" r="26" fill="url(#glow)"/>')
            out.append(f'<circle cx="{x}" cy="{y}" r="12" fill="{PH_Y}" opacity="{0.95 if i == 0 else 0.3}"/>')
            out.append(f'<rect x="{x - 5}" y="{y + 10}" width="10" height="8" fill="url(#steel)"/>')
            out.append(f'<path d="M{x} {y + 18} L{cx} {cy + 26}" stroke="{COPPER}" stroke-width="2"/>')
        out.append(f'<path d="M100 36 L100 {cy - 12}" stroke="{COPPER}" stroke-width="2"/>')
        out.append(f'<rect x="{cx - 9}" y="{cy - 12}" width="18" height="26" rx="4" fill="url(#motor)"/>')
        out.append(f'<path d="M{cx} {cy + 14} L{cx} {cy + 26}" stroke="{COPPER}" stroke-width="2"/>')
        out.append(spark(54, 40, 0.7))
    else:
        t = 'disc' if kind.startswith('disc') else 'led'
        st = 'cw' if kind.endswith('cw') and not kind.endswith('ccw') or kind.endswith('fwd') else 'ccw'
        mx, my, s = 100, 72, 3.6
        out.append(gloved_hand(mx, my + 92, 1.0))
        out.append(meter(mx, my, t, st, s))
        for i, col in enumerate(PHASES):
            out.append(lead((mx + (i - 1) * 20, my + 2), (54 + i * 46, 36), col, sag=-30, w=3))
        if t == 'disc':
            # Motion swishes beside the turning disc.
            cy = my + 11.5 * s
            d = 1 if st == 'cw' else -1
            out.append(f'<g stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.8">'
                       f'<path d="M{f(mx + 34 * d)} {f(cy - 14)} q{f(8 * d)} 14 0 28"/><path d="M{f(mx - 34 * d)} {f(cy + 14)} q{f(-8 * d)} -14 0 -28"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — probe: a live test — gloves, probes apart, no damaged lead.
# --------------------------------------------------------------------------

def clamp_jaw(x, y):
    return (f'<path d="M{f(x - 6)} {f(y + 3)} A6.5 6.5 0 1 1 {f(x + 6)} {f(y + 3)}" stroke="{METER}" stroke-width="3" fill="none"/>'
            f'<rect x="{f(x - 3)}" y="{f(y + 3)}" width="6" height="7" rx="1.5" fill="{METER_D}"/>')


def probe_card(kind):
    out = shop()
    if kind == 'gloves':
        testing(out, 'led', 'cw')
    elif kind == 'clamp':
        # Clamped round the insulated cables below the busbars.
        cy = TERM_Y + 30
        testing(out, 'led', 'cw', clips=[(tx, cy + 10) for tx in TERM_X])
        for tx in TERM_X:
            out.append(clamp_jaw(tx, cy))
    elif kind == 'bare':
        testing(out, 'led', 'cw', bare=True)
    elif kind == 'touch':
        testing(out, 'led', 'off', clips=[(TERM_X[0], TERM_Y + 2), (40, TERM_Y + 4), (TERM_X[2], TERM_Y + 2)])
        out.append(spark(37, TERM_Y + 4, 0.9))
    elif kind == 'earth':
        x, y, w, h = PNL
        testing(out, 'led', 'off', clips=[(TERM_X[0], TERM_Y + 2), (TERM_X[1], TERM_Y + 2), (x + 40, y + h - 18)])
        out.append(spark(x + 40, y + h - 15, 0.9))
    elif kind == 'torn':
        testing(out, 'led', 'cw', torn=True)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — fix: reversed (R-B-Y) -> swap any two phases (isolator OFF).
# --------------------------------------------------------------------------

def swap_marks(i, j):
    """Two cable ends lifted off and crossed, with a curved swap arrow."""
    xa, xb = TERM_X[i], TERM_X[j]
    y0, y1 = TERM_Y + 22, TERM_Y + 50
    ca, cb = PHASES[i], PHASES[j]
    return (f'<rect x="{xa - 4}" y="{y0 - 2}" width="{xb - xa + 8}" height="{y1 - y0 + 6}" fill="url(#panelIn)"/>'
            f'<path d="M{xa} {y1} C{xa} {y0 + 14} {xb} {y0 + 10} {xb} {y0}" stroke="{ca}" stroke-width="3.4" fill="none"/>'
            f'<path d="M{xb} {y1} C{xb} {y0 + 14} {xa} {y0 + 10} {xa} {y0}" stroke="{cb}" stroke-width="3.4" fill="none"/>'
            f'<path d="M{xa + 2} {y0 - 6} Q{(xa + xb) / 2} {y0 - 16} {xb - 2} {y0 - 6}" stroke="#FFFFFF" stroke-width="1.6" fill="none"/>'
            f'<path d="M{xb - 2} {y0 - 6} l-5 -1 M{xb - 2} {y0 - 6} l-1 -5" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>'
            f'<path d="M{xa + 2} {y0 - 6} l5 -1 M{xa + 2} {y0 - 6} l1 -5" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>')


def screwdriver(x, y):
    return (f'<g transform="rotate(-35 {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 2.5)}" width="12" height="5" rx="2" fill="{PH_R}"/>'
            f'<rect x="{f(x - 12)}" y="{f(y - 0.9)}" width="12" height="1.8" fill="url(#steel)"/></g>')


def hung_meter(state):
    """The meter hung on the panel door, showing its reading."""
    return meter(176, 54, 'led', state, 0.9) + f'<path d="M176 54 L176 46" stroke="{WIRE}" stroke-width="1.4"/>'


def fix_card(kind):
    if kind in ('yb', 'ry'):
        out = shop(iso_on=False)
        i, j = (1, 2) if kind == 'yb' else (0, 1)
        out.append(swap_marks(i, j))
        out.append(hung_meter('off'))
        hx = (TERM_X[i] + TERM_X[j]) / 2
        out.append(worker(118, ((104, 150), (hx + 10, TERM_Y + 30)), face=-1, look=14))
        out.append(screwdriver(hx + 10, TERM_Y + 30))
    elif kind == 'run':
        out = shop(back=True, falling=True)
        out.append(hung_meter('ccw'))
        out.append(worker(124, ((110, 150), (BTN[0] + 9, BTN[1] + 7)), face=-1, look=0))
    elif kind == 'colour':
        out = shop()
        out.append(hung_meter('ccw'))
        out.append(worker(118, ((104, 150), (74, 92)), face=-1, look=-6, point=(0, -1)))
        out.append(screwdriver(150, GY + 10))
    elif kind == 'pump':
        out = shop(load='pump', broken=True)
        out.append(hung_meter('ccw'))
        out.append(worker(124, ((110, 150), (BTN[0] + 9, BTN[1] + 7)), face=-1, look=0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — grid: a new transformer; a generator synchronised to the grid.
# --------------------------------------------------------------------------

def yard():
    out = card_open('yard')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<path d="M0 {GY} L200 {GY}" stroke="#8A7A58" stroke-width="1"/>')
    return out


TX = (26, 98)   # transformer tank x, y


def transformer(switch_on=False):
    x, y = TX
    o = [f'<rect x="{x - 6}" y="{GY - 8}" width="84" height="8" fill="#A8A29A"/>',
         f'<rect x="{x}" y="{y}" width="72" height="{GY - 8 - y}" rx="3" fill="url(#tank)"/>']
    o += [f'<rect x="{x + 6 + i * 9}" y="{y + 10}" width="4" height="{GY - 26 - y}" rx="1.5" fill="#5C7459"/>' for i in range(7)]
    # LT bushings on the top with phase caps.
    for i, col in enumerate(PHASES):
        bx = x + 14 + i * 22
        o.append(f'<path d="M{bx - 5} {y} L{bx + 5} {y} L{bx + 3} {y - 14} L{bx - 3} {y - 14} Z" fill="url(#porcelain)"/>')
        o.append(f'<rect x="{bx - 3.5}" y="{y - 20}" width="7" height="6" rx="1" fill="{col}"/>')
    # The LT switch box on a post at the right of the tank.
    sx, sy = 110, 112
    o.append(f'<path d="M{sx + 9} {sy + 26} L{sx + 9} {GY}" stroke="#6F7880" stroke-width="3"/>')
    o.append(f'<rect x="{sx}" y="{sy}" width="18" height="26" rx="2" fill="url(#panel)" stroke="#6F7880" stroke-width="0.8"/>')
    hy = sy + 5 if switch_on else sy + 21
    o.append(f'<path d="M{sx + 9} {sy + 13} L{sx + 9} {hy}" stroke="{FACE}" stroke-width="3.4" stroke-linecap="round"/>')
    o.append(f'<circle cx="{sx + 9}" cy="{sy + 13}" r="2.6" fill="{FACE}"/>')
    o.append(f'<path d="M{x + 72} {y + 30} Q{sx - 4} {y + 30} {sx} {sy + 10}" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    return ''.join(o)


def grid_tx(kind):
    out = yard()
    out.append(transformer(switch_on=(kind == 'skip')))
    x, y = TX
    if kind == 'tx':
        mx, my = 116, 140
        out.append(worker(150, ((mx + 4, my + 20), (mx + 2, my + 12)), face=-1, look=6))
        out.append(meter(mx, my, 'disc', 'cw', 1.0))
        for i, col in enumerate(PHASES):
            out.append(lead((mx - 6 + i * 6, my + 2), (x + 14 + i * 22, y - 16), col, sag=-10 + i * 2))
    elif kind == 'skip':
        out.append(worker(146, ((134, 156), (119, 116)), face=-1, look=-4))
        out.append(case_on_floor(176))
    elif kind == 'colour':
        out.append(worker(146, ((134, 156), (x + 40, y - 22)), face=-1, look=-12, point=(0, -1)))
        out.append(case_on_floor(176))
    return out


def genset(x=8, y=130):
    return (f'<rect x="{x}" y="{y}" width="64" height="{GY - y}" rx="4" fill="url(#genset)"/>'
            + ''.join(f'<path d="M{x + 8} {y + 12 + i * 8} L{x + 40} {y + 12 + i * 8}" stroke="#8C6A1C" stroke-width="2"/>' for i in range(5))
            + f'<rect x="{x + 48}" y="{y - 14}" width="6" height="16" fill="{FACE}"/>')


def grid_line():
    """The incoming grid: a pole with three conductors coming in at the right."""
    o = [f'<rect x="182" y="20" width="9" height="{GY - 20}" fill="url(#steel)"/>',
         f'<rect x="150" y="34" width="50" height="5" fill="#6F7880"/>']
    for i, col in enumerate(PHASES):
        o.append(f'<path d="M{156 + i * 15} 34 l0 -6" stroke="#9AA5AD" stroke-width="3"/>')
        o.append(f'<circle cx="{156 + i * 15}" cy="27" r="2" fill="{col}"/>')
    o.append(f'<path d="M186 39 L186 60 Q186 72 170 72 L140 72 L140 92" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    return ''.join(o)


def sync_panel(closed=False):
    """The synchronising panel between the generator and the grid: a meter on
    each side and the coupling breaker in the middle."""
    x, y = 82, 92
    o = [f'<rect x="{x}" y="{y}" width="78" height="{GY - y}" rx="3" fill="url(#panel)"/>',
         f'<path d="M72 160 L{x} 160" stroke="{WIRE}" stroke-width="3"/>']
    bx, by = x + 30, y + 54
    o.append(f'<rect x="{bx}" y="{by}" width="18" height="26" rx="2" fill="url(#panelIn)"/>')
    hy = by + 5 if closed else by + 21
    o.append(f'<path d="M{bx + 9} {by + 13} L{bx + 9} {hy}" stroke="{PH_Y}" stroke-width="3.4" stroke-linecap="round"/>')
    o.append(f'<circle cx="{bx + 9}" cy="{by + 13}" r="2.6" fill="{PH_Y}"/>')
    return ''.join(o), (x, y)


def grid_gen(kind):
    out = yard()
    out.append(grid_line())
    out.append(genset())
    closed = kind == 'sync'
    svg, (x, y) = sync_panel(closed)
    out.append(svg)
    left, right = ('cw', 'cw') if kind == 'gen' else ('ccw', 'cw')
    out.append(meter(x + 18, y + 10, 'disc', left, 1.1))
    out.append(meter(x + 60, y + 10, 'disc', right, 1.1))
    if kind == 'gen':
        out.append(worker(118, ((106, 156), (x + 18, y + 46)), face=-1, look=-4, point=(0, 0)))
    else:
        out.append(worker(118, ((106, 156), (x + 39, y + 59)), face=-1, look=-4))
        out.append(blast(x + 39, y + 66, 46))
    return out


def grid_card(kind):
    out = grid_gen(kind) if kind in ('gen', 'sync') else grid_tx(kind)
    return card_close(out)


CARDS = {
    'when_new': when_card('new'),
    'when_repair': when_card('repair'),
    'when_colour': when_card('colour'),
    'when_run': when_card('run'),
    'when_pump': when_card('pump'),
    'meter_disc_cw': meter_card('disc_cw'),
    'meter_led_fwd': meter_card('led_fwd'),
    'meter_disc_ccw': meter_card('disc_ccw'),
    'meter_led_rev': meter_card('led_rev'),
    'meter_lamp': meter_card('lamp'),
    'probe_gloves': probe_card('gloves'),
    'probe_clamp': probe_card('clamp'),
    'probe_bare': probe_card('bare'),
    'probe_touch': probe_card('touch'),
    'probe_earth': probe_card('earth'),
    'probe_torn': probe_card('torn'),
    'fix_yb': fix_card('yb'),
    'fix_ry': fix_card('ry'),
    'fix_run': fix_card('run'),
    'fix_colour': fix_card('colour'),
    'fix_pump': fix_card('pump'),
    'grid_tx': grid_card('tx'),
    'grid_gen': grid_card('gen'),
    'grid_sync': grid_card('sync'),
    'grid_skip': grid_card('skip'),
    'grid_colour': grid_card('colour'),
}

# Safe cards and traps per round (mirrors learn_board_pack28.dart).
ROUNDS = {
    'when': (['when_new', 'when_repair'], ['when_colour', 'when_run', 'when_pump']),
    'meter': (['meter_disc_cw', 'meter_led_fwd'], ['meter_disc_ccw', 'meter_led_rev', 'meter_lamp']),
    'probe': (['probe_gloves', 'probe_clamp'], ['probe_bare', 'probe_touch', 'probe_earth', 'probe_torn']),
    'fix': (['fix_yb', 'fix_ry'], ['fix_run', 'fix_colour', 'fix_pump']),
    'grid': (['grid_tx', 'grid_gen'], ['grid_sync', 'grid_skip', 'grid_colour']),
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
