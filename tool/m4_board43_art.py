"""Picture cards for lesson 4.3 শেখা ("নতুন সার্ভিস কানেকশন দেওয়া").

python -I tool/m4_board43_art.py .

Writes assets/game/art/m4_board43/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the meter reading is drawn as seven-segment strokes.

What the cards show comes from lesson 4.3 and its film script only:
  1. plan: the approved connection order, meter details and the materials
     before starting; the straightest, safest route from the pole to the
     customer's meter is surveyed — not over a tree or another house; a cable
     over a road keeps its lawful ground clearance (no figure given);
  2. anchor: a rack bolt / eye hook firmly on the house wall; an anchor clamp
     on the pole below the LT line; the GI supporting (bearer) wire is pulled
     first to the right tension — it carries all the pull. Without it the
     cable sags or snaps (the lesson's first myth); a weak anchor lets the
     line sag or tear in a storm;
  3. ipc: the pole joint is an insulation piercing connector — no stripping;
     its nut is tightened until the shear head breaks off by itself. A
     stripped-and-twisted joint is not waterproof, corrodes, works loose and
     makes a hotspot that burns (the second myth);
  4. meter: the cable is strapped to the GI wire neatly at even spacing; at
     the house it enters the meter's incoming terminal through a drip loop
     (keeps the water out); phase and neutral go to their own terminals;
  5. test: every joint checked tight; with the pole fuse in, a multimeter at
     the meter's incoming terminal must read 230-240 V (single phase); then
     the customer is shown the meter and main switch; scraps are cleared.
No worker is drawn on the pole: the pole and IPC cards are close-ups of the
hardware (a gloved hand at most), so no harness / shutdown question arises.

Fairness (the playbook, section 4): every card in a round shares one set of
colours; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board43_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board43')
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
CABLE = '#23282E'
GI = '#A7B1B8'
COPPER = '#D98A3D'
BURNT = '#4A2E1C'
RUST = '#5FA37A'
PH_R = '#D8402F'
STRAP = '#EDE6D2'
PAPER = '#F4F1E8'
FACE = '#1E2329'
LCD = '#C9D8B8'
RAIN = '#8FC3E8'
ROUTE = '#FFFFFF'
ROOF = '#9C4A36'
KURTA = '#C98A3A'
KURTA_D = '#A8712C'
TRUCK = '#C8553D'
PACKET = '#D9CBA0'
TRUNK = '#6B4A30'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#D9C9A8"/><stop offset="1" stop-color="#BFAE8C"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5C6166"/><stop offset="1" stop-color="#474B50"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E8DCC0"/><stop offset="1" stop-color="#CDBD9C"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA0A4"/><stop offset="0.5" stop-color="#D3D7DA"/><stop offset="1" stop-color="#8A9094"/></linearGradient>
  <linearGradient id="leaf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5DA052"/><stop offset="1" stop-color="#3D7A3A"/></linearGradient>
  <linearGradient id="lt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A4048"/><stop offset="0.45" stop-color="#262B31"/><stop offset="1" stop-color="#16191D"/></linearGradient>
  <linearGradient id="ipc" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5A626B"/><stop offset="1" stop-color="#30363C"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2F5F7"/><stop offset="1" stop-color="#C9D1D7"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4C2" stop-opacity="0.95"/><stop offset="1" stop-color="#FFF4C2" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="burn" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A"/><stop offset="0.45" stop-color="#FF7A2E" stop-opacity="0.75"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
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


def _hand(p, bare=False, point=0):
    x, y = p
    c = SKIN if bare else GLOVE
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber gloves."""
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


def worker(x, hands_world, face=-1, look=0, point=(0, 0), step=False):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates. step = mid-stride (walking off)."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    spread = 12 if step else 7
    feet = ((x - spread * face, gy - 1), (x + (spread - 1) * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, False, point)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def customer(x, face=1):
    """The customer at his house: an orange kurta, no helmet."""
    def s(p):
        return f'{f(x + (p[0] - x) * S)} {f(GY + (p[1] - GY) * S)}'
    o = [f'<path d="M{s((x - 3, GY - 1))} L{s((x - 3, GY - 30))} M{s((x + 3, GY - 1))} L{s((x + 3, GY - 30))}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round"/>',
         f'<path d="M{s((x - 8, GY - 22))} L{s((x - 6, GY - 56))} Q{s((x, GY - 60))} {s((x + 6, GY - 56))} L{s((x + 8, GY - 22))} Z" fill="{KURTA}"/>',
         f'<path d="M{s((x + 5 * face, GY - 54))} L{s((x + 8 * face, GY - 38))} L{s((x + 6 * face, GY - 30))}" stroke="{KURTA_D}" stroke-width="7" fill="none" stroke-linecap="round"/>',
         f'<circle cx="{f(x + 1 * face * S)}" cy="{f(GY - 64 * S)}" r="{f(7 * S)}" fill="{SKIN}"/>',
         f'<path d="M{f(x - 8 * S)} {f(GY - 66 * S)} A{f(8 * S)} {f(7 * S)} 0 0 1 {f(x + 8 * S)} {f(GY - 66 * S)} Z" fill="{HAIR}"/>',
         f'<circle cx="{f(x + 4 * face * S)}" cy="{f(GY - 63 * S)}" r="1.2" fill="{HAIR}"/>']
    return ''.join(o)


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


def rain(x0, x1, y0, y1, n=14, seed=3):
    o = []
    for i in range(n):
        x = x0 + ((i * 37 + seed * 11) % 100) / 100 * (x1 - x0)
        y = y0 + ((i * 53 + seed * 7) % 100) / 100 * (y1 - y0)
        o.append(f'<path d="M{f(x)} {f(y)} l-2 7" stroke="{RAIN}" stroke-width="1.6" stroke-linecap="round"/>')
    return ''.join(o)


def drop(x, y, s=1.0):
    return (f'<path d="M{f(x)} {f(y)} Q{f(x + 3 * s)} {f(y + 5 * s)} {f(x)} {f(y + 7 * s)} Q{f(x - 3 * s)} {f(y + 5 * s)} {f(x)} {f(y)} Z" fill="{RAIN}"/>')


def wind(y):
    return (f'<g stroke="#FFFFFF" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.85">'
            f'<path d="M58 {y} q14 -6 28 0 t28 0"/><path d="M84 {y + 14} q12 -5 24 0 t24 0"/></g>')


def coil(x, y=GY + 9):
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="13" ry="5" fill="none" stroke="{CABLE}" stroke-width="2.8"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="8.5" ry="3" fill="none" stroke="{GI}" stroke-width="1.8"/>')


def paper(x, y, rot=-8):
    lines = ''.join(f'<path d="M{f(x + 2.5)} {f(y + 4 + i * 3.4)} l{f(9 if i % 2 else 11)} 0" stroke="{FACE}" stroke-width="0.9"/>' for i in range(4))
    return (f'<g transform="rotate({rot} {f(x + 7)} {f(y + 9)})"><rect x="{f(x)}" y="{f(y)}" width="15" height="19" rx="1.2" fill="{PAPER}"/>'
            f'{lines}</g>')


def pole(x, top=20):
    """A concrete pole with the insulated LT line run across the top."""
    return (f'<rect x="{x - 4}" y="{top}" width="8" height="{GY - top}" fill="url(#pole)"/>'
            f'<path d="M0 {top + 10} L200 {top + 10}" stroke="url(#lt)" stroke-width="5"/>'
            f'<rect x="{x - 6}" y="{top + 6}" width="12" height="8" rx="2" fill="url(#ipc)"/>')


def house(x0, x1, top, meter=True):
    o = [f'<rect x="{x0}" y="{top}" width="{x1 - x0}" height="{GY - top}" fill="url(#house)"/>',
         f'<rect x="{x0 - 3}" y="{top - 6}" width="{x1 - x0 + 6}" height="7" fill="{ROOF}"/>',
         f'<rect x="{x0 + 10}" y="{top + 30}" width="18" height="22" rx="1.5" fill="{FACE}" opacity="0.75"/>']
    if meter:
        o.append(f'<rect x="{x0 + 8}" y="{top + 70}" width="16" height="20" rx="2" fill="url(#box)"/>')
    return ''.join(o)


def anchor(x, y, firm=True):
    """A rack bolt with an eye on the house wall (or pulled out of it)."""
    if firm:
        return (f'<rect x="{f(x - 2)}" y="{f(y - 6)}" width="5" height="12" rx="1" fill="url(#steel)"/>'
                f'<circle cx="{f(x - 5)}" cy="{f(y)}" r="3.4" fill="none" stroke="url(#steel)" stroke-width="2.2"/>')
    return (f'<path d="M{f(x)} {f(y - 8)} l-4 5 l3 4 l-3 6" stroke="{TRUNK}" stroke-width="1.2" fill="none"/>'
            f'<g transform="rotate(-35 {f(x - 8)} {f(y + 4)})"><rect x="{f(x - 10)}" y="{f(y - 2)}" width="5" height="12" rx="1" fill="url(#steel)"/>'
            f'<circle cx="{f(x - 13)}" cy="{f(y + 4)}" r="3.4" fill="none" stroke="url(#steel)" stroke-width="2.2"/></g>')


def clamp(x, y):
    """The anchor clamp round the pole, below the LT line."""
    return (f'<rect x="{f(x - 6)}" y="{f(y - 3)}" width="12" height="6" rx="1.5" fill="url(#steel)"/>'
            f'<circle cx="{f(x + 8)}" cy="{f(y)}" r="3.2" fill="none" stroke="url(#steel)" stroke-width="2.2"/>')


def sag_path(p0, p1, sag):
    mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2 + sag
    return f'M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}'


def ring(x, y, r=11, op=0.9):
    """A soft halo drawing the eye to a detail (on safe and trap cards alike)."""
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill="none" stroke="#FFFFFF" stroke-width="1.8" stroke-dasharray="3 2.5" opacity="{op}"/>'


# --------------------------------------------------------------------------
# Round 1 — plan: papers and materials; survey the straight, safe route.
# --------------------------------------------------------------------------

PX, PTOP = 22, 26       # pole
HX0, HX1, HTOP = 140, 210, 88   # customer house


def plan_stage():
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(pole(PX, PTOP))
    out.append(house(HX0, HX1, HTOP))
    return out


def route(points, dashed=True):
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in points)
    dash = ' stroke-dasharray="6 4"' if dashed else ''
    return f'<path d="{d}" stroke="{ROUTE}" stroke-width="2.2" fill="none" stroke-linecap="round"{dash}/>'


def tree(x, crown_y):
    return (f'<rect x="{x - 4}" y="{crown_y}" width="8" height="{GY - crown_y}" fill="{TRUNK}"/>'
            f'<circle cx="{x}" cy="{crown_y}" r="22" fill="url(#leaf)"/><circle cx="{x - 16}" cy="{crown_y + 10}" r="14" fill="url(#leaf)"/>'
            f'<circle cx="{x + 15}" cy="{crown_y + 8}" r="15" fill="url(#leaf)"/>')


def plan_card(kind):
    out = plan_stage()
    start, end = (PX + 6, PTOP + 34), (HX0, HTOP + 20)
    if kind == 'order':
        out.append(route([start, end]))
        out.append(coil(70))
        out.append(worker(104, ((92, 150), (96, 138)), face=-1, look=10))
        out.append(paper(86, 128))
    elif kind == 'survey':
        out.append(route([start, end]))
        out.append(ring(*end, 10))
        out.append(coil(150))
        out.append(worker(96, ((84, 150), (112, 118)), face=1, look=-14, point=(0, 1)))
        out.append(paper(78, 150, 4))
    elif kind == 'tree':
        out.append(tree(84, 72))
        out.append(route([start, end]))
        out.append(ring(84, 70, 14))
        out.append(coil(150))
        out.append(worker(118, ((106, 150), (98, 112)), face=-1, look=-14, point=(0, -1)))
        out.append(paper(132, 150, 4))
    elif kind == 'roof':
        out.append(house(66, 112, 76, meter=False))
        out.append(route([start, (88, 66), end]))
        out.append(ring(88, 68, 12))
        out.append(coil(130))
        out.append(worker(126, ((116, 150), (100, 112)), face=-1, look=-14, point=(0, -1)))
    elif kind == 'road':
        out.append(f'<rect x="34" y="{GY - 2}" width="104" height="{H - GY + 2}" fill="url(#road)"/>')
        out.append(''.join(f'<rect x="{40 + i * 22}" y="{GY + 9}" width="12" height="2.4" fill="{ROUTE}"/>' for i in range(5)))
        # The service cable sags low over the road; a truck brushes it.
        out.append(f'<rect x="56" y="{GY - 44}" width="54" height="34" rx="3" fill="{TRUCK}"/>'
                   f'<rect x="96" y="{GY - 40}" width="12" height="12" rx="1.5" fill="{FACE}" opacity="0.75"/>'
                   f'<circle cx="68" cy="{GY - 8}" r="6" fill="{CABLE}"/><circle cx="100" cy="{GY - 8}" r="6" fill="{CABLE}"/>')
        out.append(f'<path d="{sag_path(start, end, 96)}" stroke="{CABLE}" stroke-width="2.6" fill="none"/>')
        out.append(ring(82, GY - 46, 12))
        out.append(coil(176))
        out.append(worker(160, ((150, 150), (152, 140)), face=-1, look=6))
        out.append(paper(142, 130))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — anchor: rack bolt on the house, clamp on the pole, GI wire first.
# --------------------------------------------------------------------------

AP = (PX + 4, PTOP + 40)       # pole anchor clamp (below the LT line)
AH = (HX0, HTOP + 16)          # house rack bolt


def bearer_span(gi=True, gi_sag=4, cable_sag=6, firm=True):
    o = []
    hx, hy = AH if firm else (AH[0] - 8, AH[1] + 6)
    if gi:
        o.append(f'<path d="{sag_path(AP, (hx - 5, hy), gi_sag)}" stroke="{GI}" stroke-width="1.6" fill="none"/>')
        o.append(f'<path d="{sag_path((AP[0], AP[1] + 4), (hx - 5, hy + 4), cable_sag)}" stroke="{CABLE}" stroke-width="2.8" fill="none"/>')
        # Straps every 14 px along the span.
        for i in range(1, 8):
            t = i / 8
            x = AP[0] + (hx - 5 - AP[0]) * t
            y = AP[1] + (hy - AP[1]) * t + 4 * t * (1 - t) * gi_sag
            o.append(f'<rect x="{f(x - 1)}" y="{f(y - 1)}" width="2.4" height="{f(5 + 4 * t * (1 - t) * (cable_sag - gi_sag))}" fill="{STRAP}"/>')
    o.append(clamp(*AP))
    o.append(anchor(*AH, firm=firm))
    return ''.join(o)


def anchor_card(kind):
    out = plan_stage()
    if kind == 'rack':
        out.append(bearer_span())
        out.append(ring(AH[0] - 3, AH[1], 12))
        out.append(worker(118, ((106, 150), (130, 112)), face=1, look=-18, point=(0, 1)))
    elif kind == 'clamp':
        out.append(bearer_span())
        out.append(ring(AP[0] + 2, AP[1], 12))
        out.append(worker(52, ((42, 150), (36, 98)), face=-1, look=-18, point=(0, -1)))
    elif kind == 'nowire':
        # The cable alone: a deep sag, torn in the wind.
        out.append(f'<path d="{sag_path((AP[0], AP[1] + 4), (92, 150), 30)}" stroke="{CABLE}" stroke-width="2.8" fill="none"/>')
        out.append(f'<path d="M{AH[0] - 5} {AH[1] + 4} Q112 150 100 170" stroke="{CABLE}" stroke-width="2.8" fill="none"/>')
        out.append(clamp(*AP))
        out.append(anchor(*AH))
        out.append(wind(40))
        out.append(spark(96, 160, 0.8))
        out.append(worker(126, ((116, 150), (110, 120)), face=-1, look=-6, point=(0, -1)))
    elif kind == 'loose':
        out.append(bearer_span(gi_sag=30, cable_sag=34, firm=False))
        out.append(ring(AH[0] - 8, AH[1] + 6, 13))
        out.append(wind(40))
        out.append(worker(118, ((106, 150), (130, 112)), face=1, look=-18, point=(0, 1)))
    elif kind == 'slack':
        out.append(bearer_span(gi_sag=46, cable_sag=50))
        out.append(ring(82, AP[1] + 34, 13))
        out.append(worker(52, ((42, 150), (36, 98)), face=-1, look=-18, point=(0, -1)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — ipc: the pole joint (close-up of the LT line).
# --------------------------------------------------------------------------

LTY = 70   # the LT conductor's centre line


def lt_line(stripped=False):
    o = [f'<rect x="-4" y="{LTY - 8}" width="208" height="16" rx="8" fill="url(#lt)"/>']
    if stripped:
        o.append(f'<rect x="80" y="{LTY - 4}" width="40" height="8" fill="{COPPER}"/>')
        o.append(''.join(f'<path d="M{82 + i * 4} {LTY - 4} l3 8" stroke="#B36A26" stroke-width="1"/>' for i in range(10)))
    # The pole the line is hung from, at the left.
    o.append(f'<rect x="10" y="0" width="22" height="{H}" fill="url(#pole)"/>')
    o.append(f'<rect x="6" y="{LTY - 12}" width="30" height="24" rx="4" fill="url(#ipc)"/>')
    return ''.join(o)


def service_down(stripped=False):
    if stripped:
        return (f'<path d="M100 220 L100 150 Q100 110 112 92" stroke="{CABLE}" stroke-width="10" fill="none" stroke-linecap="round"/>')
    return f'<path d="M100 220 L100 90" stroke="{CABLE}" stroke-width="10" fill="none"/>'


def ipc_body(head=True, stub=True):
    """The connector clamped across both cables; nut on top; shear head."""
    o = [f'<rect x="78" y="{LTY - 22}" width="44" height="16" rx="4" fill="url(#ipc)"/>',
         f'<rect x="78" y="{LTY + 6}" width="44" height="20" rx="4" fill="url(#ipc)"/>',
         f'<rect x="76" y="{LTY - 8}" width="48" height="16" rx="3" fill="{FACE}" opacity="0.35"/>',
         f'<rect x="97" y="{LTY - 30}" width="6" height="64" fill="url(#steel)"/>']
    if stub:
        o.append(f'<path d="M92 {LTY - 30} l4 -6 h8 l4 6 l-4 6 h-8 Z" fill="url(#steel)"/>')
    if head:
        o.append(f'<rect x="94" y="{LTY - 44}" width="12" height="8" rx="1" fill="url(#ipc)"/>'
                 f'<path d="M93 {LTY - 44} h14" stroke="{GI}" stroke-width="1.4"/>')
    return ''.join(o)


def twisted(burnt=False):
    c = BURNT if burnt else COPPER
    o = [f'<path d="M112 92 Q120 84 116 {LTY + 4}" stroke="{c}" stroke-width="4" fill="none"/>']
    for i in range(6):
        x = 84 + i * 6
        o.append(f'<ellipse cx="{x}" cy="{LTY}" rx="3" ry="7" fill="none" stroke="{c}" stroke-width="2.4"/>')
    return ''.join(o)


def spanner(x, y, rot=0):
    return (f'<g transform="rotate({rot} {f(x)} {f(y)})"><path d="M{f(x - 7)} {f(y - 6)} h14 v4 h-4 v4 h4 v4 h-14 Z" fill="url(#steel)"/>'
            f'<rect x="{f(x + 6)}" y="{f(y - 3)}" width="44" height="6" rx="3" fill="url(#steel)"/></g>')


def glove_hand(x, y):
    return (f'<path d="M{f(x - 10)} {f(y - 8)} Q{f(x)} {f(y - 14)} {f(x + 12)} {f(y - 6)} L{f(x + 30)} {f(y + 20)} L{f(x + 14)} {f(y + 30)} '
            f'L{f(x - 6)} {f(y + 8)} Z" fill="{GLOVE}"/>'
            f'<rect x="{f(x + 18)}" y="{f(y + 16)}" width="22" height="18" rx="3" fill="url(#shirt)" transform="rotate(40 {f(x + 29)} {f(y + 25)})"/>')


def ipc_card(kind):
    out = card_open('sky')
    out.append(rain(40, 196, 6, 200, 10, 5))
    if kind == 'fit':
        out.append(service_down())
        out.append(lt_line())
        out.append(ipc_body(head=False))
        out.append(ring(100, LTY - 34, 13))
    elif kind == 'shear':
        out.append(service_down())
        out.append(lt_line())
        out.append(ipc_body(head=False))
        # The shear head snapping off by itself, flying away.
        out.append(f'<g transform="rotate(32 134 26)"><rect x="128" y="22" width="12" height="8" rx="1" fill="url(#ipc)"/>'
                   f'<path d="M127 22 h14" stroke="{GI}" stroke-width="1.4"/></g>')
        out.append('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9"><path d="M110 34 l10 -4"/><path d="M112 42 l10 -3"/><path d="M118 22 l7 -5"/></g>')
        out.append(spanner(100, LTY - 30, 30))
        out.append(glove_hand(140, LTY + 10))
    elif kind == 'head':
        out.append(service_down())
        out.append(lt_line())
        out.append(ipc_body(head=True))
        out.append(ring(100, LTY - 40, 13))
        out.append(spanner(146, 150, -60))
        out.append(glove_hand(150, 150))
    elif kind == 'twist':
        out.append(service_down(stripped=True))
        out.append(lt_line(stripped=True))
        out.append(twisted())
        out.append(drop(96, LTY + 10) + drop(106, LTY + 16, 0.8))
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="2" fill="{RUST}"/>' for x, y in ((88, LTY - 3), (104, LTY + 4), (114, 86))))
        out.append(ring(100, LTY, 26))
    elif kind == 'burn':
        out.append(service_down(stripped=True))
        out.append(lt_line(stripped=True))
        out.append(f'<circle cx="100" cy="{LTY}" r="40" fill="url(#burn)"/>')
        out.append(twisted(burnt=True))
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{GI}" opacity="0.6"/>' for x, y, r in ((96, 40, 7), (106, 28, 9), (98, 14, 11))))
        out.append(spark(110, LTY - 6, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — meter: straps at even spacing; a drip loop into the meter.
# --------------------------------------------------------------------------

def span_card(even=True):
    out = plan_stage()
    p0, p1 = (PX + 4, PTOP + 40), (HX0 - 5, HTOP + 16)
    out.append(f'<path d="M{p0[0]} {p0[1]} L{p1[0]} {p1[1]}" stroke="{GI}" stroke-width="1.6"/>')
    n = 10 if even else 3
    pts = [(p0[0] + (p1[0] - p0[0]) * i / n, p0[1] + (p1[1] - p0[1]) * i / n) for i in range(n + 1)]
    if even:
        d = 'M' + ' L'.join(f'{f(x)} {f(y + 4)}' for x, y in pts)
    else:
        d = f'M{f(pts[0][0])} {f(pts[0][1] + 4)}' + ''.join(
            f' Q{f((a[0] + b[0]) / 2)} {f((a[1] + b[1]) / 2 + 30)} {f(b[0])} {f(b[1] + 4)}' for a, b in zip(pts, pts[1:]))
    out.append(f'<path d="{d}" stroke="{CABLE}" stroke-width="2.8" fill="none"/>')
    for x, y in pts[1:-1]:
        out.append(f'<rect x="{f(x - 1.2)}" y="{f(y - 1)}" width="2.4" height="6" fill="{STRAP}"/>')
    # The drip loop below the bolt, then into the meter on the wall.
    mx, my = HX0 + 8, HTOP + 70
    out.append(f'<path d="M{p1[0]} {p1[1] + 4} Q{HX0 - 8} {my + 26} {mx + 2} {my + 6}" stroke="{CABLE}" stroke-width="2.8" fill="none"/>')
    out.append(clamp(*p0) + anchor(HX0, HTOP + 16))
    out.append(ring(*(pts[n // 2] if even else (((pts[1][0] + pts[2][0]) / 2), (pts[1][1] + pts[2][1]) / 2 + 18)), 14))
    return out


MB = (104, 96, 70, 70)   # meter box x, y, w, h on the close-up wall


def wall_stage(loop=True, swap=False, rain_in=False):
    out = card_open('wall')
    out.append(''.join(f'<path d="M0 {y} L200 {y}" stroke="#B4A27E" stroke-width="1"/>' for y in range(18, 220, 22)))
    # GI wire and cable coming in from the top-left to the rack bolt.
    out.append(f'<path d="M-4 6 L46 40" stroke="{GI}" stroke-width="2.2"/>')
    out.append(f'<path d="M-4 12 L44 46" stroke="{CABLE}" stroke-width="4.4"/>')
    out.append(''.join(f'<rect x="{x}" y="{f(6 + (x + 4) * 0.68 - 1)}" width="3.4" height="9" fill="{STRAP}"/>' for x in (8, 26)))
    out.append(f'<rect x="44" y="30" width="8" height="18" rx="1.5" fill="url(#steel)"/>'
               f'<circle cx="46" cy="40" r="5" fill="none" stroke="url(#steel)" stroke-width="3"/>')
    x, y, w, h = MB
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="5" fill="url(#box)"/>'
               f'<rect x="{x + 10}" y="{y + 8}" width="{w - 20}" height="18" rx="2" fill="{LCD}"/>'
               f'<rect x="{x + 8}" y="{y + 36}" width="{w - 16}" height="26" rx="2" fill="{FACE}"/>')
    # Incoming terminals: phase (red mark) and neutral (black mark).
    tp, tn = (x + 22, y + 49), (x + 48, y + 49)
    out.append(f'<rect x="{tp[0] - 6}" y="{tp[1] - 6}" width="12" height="12" rx="1.5" fill="url(#steel)"/><rect x="{tp[0] - 6}" y="{tp[1] - 10}" width="12" height="3" fill="{PH_R}"/>')
    out.append(f'<rect x="{tn[0] - 6}" y="{tn[1] - 6}" width="12" height="12" rx="1.5" fill="url(#steel)"/><rect x="{tn[0] - 6}" y="{tn[1] - 10}" width="12" height="3" fill="{CABLE}"/>')
    if loop:
        # Down below the entry, round the loop and up into the box bottom.
        out.append(f'<path d="M44 46 Q40 120 62 190 Q78 214 96 186 Q110 172 {x + 35} {y + h}" stroke="{CABLE}" stroke-width="4.4" fill="none"/>')
        entry = (x + 35, y + h)
        out.append(drop(76, 204, 1.2) + drop(70, 196 + 16, 0.9))
    else:
        out.append(f'<path d="M44 46 Q90 40 {x + 35} {y}" stroke="{CABLE}" stroke-width="4.4" fill="none"/>')
        entry = (x + 35, y)
    cores = ((PH_R, tn), (CABLE, tp)) if swap else ((PH_R, tp), (CABLE, tn))
    for col, t in cores:
        out.append(f'<path d="M{entry[0]} {entry[1]} Q{entry[0]} {t[1] + (14 if loop else -14)} {t[0]} {t[1]}" stroke="{col}" stroke-width="2.4" fill="none"/>')
    if rain_in:
        out.append(rain(60, 196, 0, 100, 12, 2))
        out.append(drop(96, 44) + drop(118, 62) + drop(x + 35, y + 10, 1.1))
    return out, tp, tn


def meter_card(kind):
    if kind == 'strap':
        out = span_card(even=True)
    elif kind == 'loose':
        out = span_card(even=False)
    elif kind == 'drip':
        out, _, _ = wall_stage(loop=True)
        out.append(ring(74, 198, 18))
    elif kind == 'nodrip':
        out, _, _ = wall_stage(loop=False, rain_in=True)
        out.append(ring(MB[0] + 35, MB[1], 14))
    elif kind == 'swap':
        out, tp, tn = wall_stage(loop=True, swap=True)
        out.append(spark((tp[0] + tn[0]) / 2, tp[1] - 4, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — test: 230 V at the incoming terminal; hand over; clear up.
# --------------------------------------------------------------------------

SEG = {'2': 'abged', '3': 'abgcd', '0': 'abcdef'}


def seven(x, y, digits, s=1.0, col=FACE):
    o = []
    for k, ch in enumerate(digits):
        dx = x + k * 9 * s
        pts = {'a': ((0, 0), (6, 0)), 'b': ((6, 0), (6, 6)), 'c': ((6, 6), (6, 12)), 'd': ((0, 12), (6, 12)),
               'e': ((0, 6), (0, 12)), 'f': ((0, 0), (0, 6)), 'g': ((0, 6), (6, 6))}
        for seg in SEG[ch]:
            (a, b), (c, d) = pts[seg]
            o.append(f'<path d="M{f(dx + a * s)} {f(y + b * s)} L{f(dx + c * s)} {f(y + d * s)}" stroke="{col}" stroke-width="{f(1.6 * s)}" stroke-linecap="round"/>')
    return ''.join(o)


def multimeter(x, y, reading=True, s=1.0):
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(26 * s)}" height="{f(40 * s)}" rx="{f(4 * s)}" fill="{HELMET}" stroke="{HELMET_D}" stroke-width="1.2"/>',
         f'<rect x="{f(x + 3 * s)}" y="{f(y + 4 * s)}" width="{f(20 * s)}" height="{f(14 * s)}" rx="1.5" fill="{LCD}"/>',
         f'<circle cx="{f(x + 13 * s)}" cy="{f(y + 28 * s)}" r="{f(6 * s)}" fill="{FACE}"/>']
    if reading:
        o.append(seven(x + 4.4 * s, y + 6 * s, '230', 0.8 * s))
    return ''.join(o)


# The house front: meter box (cover open) and main switch beside the door.
TB = (112, 92, 40, 46)   # meter box
SW = (160, 100, 18, 26)  # main switch
WIN = (20, 70, 30, 30)   # window with the room lamp


def front(lit=False, sw_on=False):
    out = card_open('wall')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    x, y, w, h = WIN
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{FACE}" opacity="0.8"/>')
    if lit:
        out.append(f'<circle cx="{x + w / 2}" cy="{y + 12}" r="22" fill="url(#glow)"/>')
    out.append(f'<circle cx="{x + w / 2}" cy="{y + 12}" r="4" fill="{PAPER}" opacity="{1 if lit else 0.4}"/>')
    # The cable from the drip loop up top, into the meter.
    out.append(f'<path d="M200 30 L150 34 Q120 50 {TB[0] + 20} {TB[1]}" stroke="{CABLE}" stroke-width="3.2" fill="none"/>')
    x, y, w, h = TB
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="url(#box)"/>'
               f'<rect x="{x + 6}" y="{y + 6}" width="{w - 12}" height="10" rx="1.5" fill="{LCD}"/>'
               f'<rect x="{x + 5}" y="{y + 24}" width="{w - 10}" height="16" rx="2" fill="{FACE}"/>')
    for i in range(2):
        out.append(f'<rect x="{x + 10 + i * 14}" y="{y + 28}" width="7" height="8" rx="1" fill="url(#steel)"/>')
    out.append(f'<path d="M{x + w} {y + 30} L{SW[0]} {SW[1] + 13}" stroke="{CABLE}" stroke-width="2.4"/>')
    sx, sy, sw, sh = SW
    out.append(f'<rect x="{sx}" y="{sy}" width="{sw}" height="{sh}" rx="2" fill="url(#box)" stroke="#8E98A0" stroke-width="0.8"/>')
    hy = sy + 5 if sw_on else sy + 21
    out.append(f'<path d="M{sx + 9} {sy + 13} L{sx + 9} {hy}" stroke="{PH_R}" stroke-width="3.4" stroke-linecap="round"/>')
    return out


def test_card(kind):
    tx, ty = TB[0] + 13, TB[1] + 32
    if kind == 'measure':
        out = front()
        mx, my = 34, 136
        out.append(worker(90, ((mx + 14, my + 22), (tx, ty)), face=1, look=-8))
        out.append(multimeter(mx, my, True, 1.0))
        out.append(f'<path d="M{mx + 8} {my + 44} Q{mx + 30} {my + 70} {tx} {ty}" stroke="{PH_R}" stroke-width="1.6" fill="none"/>'
                   f'<path d="M{mx + 18} {my + 44} Q{mx + 50} {my + 60} {tx + 14} {ty}" stroke="{CABLE}" stroke-width="1.6" fill="none"/>')
        out.append(ring(tx + 7, ty + 4, 13))
    elif kind == 'explain':
        out = front(lit=True, sw_on=True)
        out.append(customer(176, face=-1))
        out.append(worker(96, ((88, 150), (TB[0] + 20, TB[1] + 10)), face=1, look=-6, point=(0, 1)))
        out.append(multimeter(56, GY - 24, True, 0.6))
    elif kind == 'skip':
        out = front(lit=True, sw_on=True)
        out.append(customer(64, face=1))
        out.append(worker(146, ((136, 150), (SW[0] + 9, SW[1] + 6)), face=1, look=-6))
        out.append(f'<g transform="rotate(-80 104 {GY - 6})">' + multimeter(96, GY - 18, False, 0.6) + '</g>')
    elif kind == 'litter':
        out = front(lit=True, sw_on=True)
        out.append(''.join(f'<path d="M{x} {GY + 6 + (i % 2) * 6} l{14 if i % 2 else -12} {-3 if i % 2 else 2}" stroke="{CABLE}" stroke-width="3" stroke-linecap="round"/>'
                           for i, x in enumerate((40, 70, 96, 120, 150))))
        out.append(''.join(f'<rect x="{x}" y="{GY + 3}" width="12" height="9" rx="1" fill="{PACKET}" transform="rotate({r} {x + 6} {GY + 7})"/>'
                           for x, r in ((56, -14), (108, 18), (136, -6))))
        out.append(''.join(f'<rect x="{x}" y="{GY + 1}" width="2.4" height="8" fill="{STRAP}" transform="rotate(60 {x} {GY + 5})"/>' for x in (84, 128)))
        out.append(worker(176, ((182, 160), (170, 150)), face=1, look=0, step=True))
    elif kind == 'loose':
        out = front(lit=True, sw_on=True)
        out.append(f'<path d="M{tx + 4} {ty + 4} q10 14 -2 22" stroke="{PH_R}" stroke-width="2.4" fill="none"/>')
        out.append(spark(tx + 4, ty + 6, 0.9))
        out.append(customer(176, face=-1))
        out.append(worker(60, ((52, 150), (48, 152)), face=-1, look=0, step=True))
    return card_close(out)


CARDS = {
    'plan_order': plan_card('order'),
    'plan_survey': plan_card('survey'),
    'plan_tree': plan_card('tree'),
    'plan_roof': plan_card('roof'),
    'plan_road': plan_card('road'),
    'anchor_rack': anchor_card('rack'),
    'anchor_clamp': anchor_card('clamp'),
    'anchor_nowire': anchor_card('nowire'),
    'anchor_loose': anchor_card('loose'),
    'anchor_slack': anchor_card('slack'),
    'ipc_fit': ipc_card('fit'),
    'ipc_shear': ipc_card('shear'),
    'ipc_head': ipc_card('head'),
    'ipc_twist': ipc_card('twist'),
    'ipc_burn': ipc_card('burn'),
    'meter_strap': meter_card('strap'),
    'meter_drip': meter_card('drip'),
    'meter_nodrip': meter_card('nodrip'),
    'meter_swap': meter_card('swap'),
    'meter_loose': meter_card('loose'),
    'test_measure': test_card('measure'),
    'test_explain': test_card('explain'),
    'test_skip': test_card('skip'),
    'test_litter': test_card('litter'),
    'test_loose': test_card('loose'),
}

# Safe cards and traps per round (mirrors learn_board_pack43.dart).
ROUNDS = {
    'plan': (['plan_order', 'plan_survey'], ['plan_tree', 'plan_roof', 'plan_road']),
    'anchor': (['anchor_rack', 'anchor_clamp'], ['anchor_nowire', 'anchor_loose', 'anchor_slack']),
    'ipc': (['ipc_fit', 'ipc_shear'], ['ipc_head', 'ipc_twist', 'ipc_burn']),
    'meter': (['meter_strap', 'meter_drip'], ['meter_nodrip', 'meter_swap', 'meter_loose']),
    'test': (['test_measure', 'test_explain'], ['test_skip', 'test_litter', 'test_loose']),
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
