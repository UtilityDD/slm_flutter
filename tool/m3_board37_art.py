"""Picture cards for lesson 3.7 শেখা ("এলটি ডিস্ট্রিবিউশন বক্স / ফিডার পিলার").

python -I tool/m3_board37_art.py .

Writes assets/game/art/m3_board37/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the phases are told by their R / Y / B colours only.

What the cards show comes from lesson 3.7 and its film script only:
  1. door: after the work the feeder pillar door is locked properly — an open
     door is a deadly danger to the public, children above all; on patrol the
     door, broken / rusted parts, the door seal and the cable entry points at
     the bottom are checked so that no water or pests get in;
  2. fuse: every outgoing feeder's phase is taken off the busbar through a
     fuse unit (HRC fuse or SFU); a thick wire or a copper strip in place of a
     fuse kills the protection — on a fault the cable or transformer burns;
  3. faults: a loose connection sparks and turns into a hotspot (black marks,
     burnt smell); rain water through a broken door / seal (short circuit,
     rust); rats cut the cable insulation (short circuit);
  4. balance: a new connection shares the load among the three phases as
     equally as possible; an overloaded phase blows its fuse again and again
     and current flows in the neutral (the film: the neutral heats up);
  5. work: inside the pillar is as dangerous as a live panel — full PPE and
     insulated tools; the IR of each outgoing cable is meggered here with the
     line off and the fuses out (the film).

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
    print('usage: python -I tool/m3_board37_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board37')
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
NEUTRAL = '#15181C'
EARTH = '#3E9B4F'
FACE = '#1E2329'
BRASS = '#C9A23A'
BRASS_D = '#94741F'
SEAL = '#8F8A80'
HOLE = '#0E1013'
RUST = '#9A4E22'
WATER = '#6FA8D6'
RAT = '#7A7672'
KID = '#E0567A'
HOUSE = '#E9DCC4'
ROOF = '#B5533C'
HOT = '#FF7A2E'
TOOL_RED = '#C0392B'
MEGGER = '#2E5E4E'
BEAM = '#FFF3B0'

DEFS = """<defs>
  <linearGradient id="street" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7EF"/></linearGradient>
  <linearGradient id="pavement" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9C9A94"/><stop offset="1" stop-color="#7D7B76"/></linearGradient>
  <linearGradient id="cabinet" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E8577"/><stop offset="0.5" stop-color="#8FA597"/><stop offset="1" stop-color="#627869"/></linearGradient>
  <linearGradient id="door" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9DB3A5"/><stop offset="1" stop-color="#768C7E"/></linearGradient>
  <linearGradient id="cabIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2B3238"/><stop offset="1" stop-color="#3E474F"/></linearGradient>
  <linearGradient id="plinth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BDB8AE"/><stop offset="1" stop-color="#9A958B"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B074"/><stop offset="0.5" stop-color="#D98A3D"/><stop offset="1" stop-color="#A9632A"/></linearGradient>
  <linearGradient id="base" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2A2F35"/><stop offset="0.5" stop-color="#424A52"/><stop offset="1" stop-color="#262B30"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AC"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#8E98A0"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="blast" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE38A"/><stop offset="0.7" stop-color="#FF7A2E" stop-opacity="0.7"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
  <radialGradient id="burn" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#0B0B0B"/><stop offset="0.6" stop-color="#2A1A10" stop-opacity="0.85"/><stop offset="1" stop-color="#2A1A10" stop-opacity="0"/></radialGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFB15A" stop-opacity="0.9"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
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


# --------------------------------------------------------------------------
# Small things.
# --------------------------------------------------------------------------

def padlock(x, y, open_=False, s=1.0):
    """A brass padlock hanging from the hasp at (x, y)."""
    sh = (f'<path d="M{f(x - 3.6 * s)} {f(y + 5 * s)} L{f(x - 3.6 * s)} {f(y)} A3.6 3.6 0 0 1 {f(x + 3.6 * s)} {f(y)} '
          f'L{f(x + 3.6 * s)} {f(y + (1 if open_ else 5) * s)}" stroke="url(#steel)" stroke-width="{f(1.8 * s)}" fill="none"/>')
    if open_:
        sh = f'<g transform="rotate(-35 {f(x - 3.6 * s)} {f(y + 5 * s)})">{sh}</g>'
    return (sh + f'<rect x="{f(x - 5.5 * s)}" y="{f(y + 4 * s)}" width="{f(11 * s)}" height="{f(10 * s)}" rx="{f(2 * s)}" fill="{BRASS}" stroke="{BRASS_D}" stroke-width="0.8"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 8.5 * s)}" r="{f(1.2 * s)}" fill="{FACE}"/>')


def rain(x0=0, x1=200, y0=0, y1=190):
    o = ['<g stroke="#9CC9EA" stroke-width="1.4" stroke-linecap="round" opacity="0.85">']
    for i in range(22):
        x = x0 + (i * 37) % (x1 - x0)
        y = y0 + (i * 53) % (y1 - y0)
        o.append(f'<path d="M{x} {y} l-3 8"/>')
    o.append('</g>')
    return ''.join(o)


def rat(x, y, face=-1, s=1.0):
    """A grey rat, nose towards face."""
    return (f'<g transform="translate({f(x)} {f(y)}) scale({f(face * s)} {f(s)})">'
            f'<path d="M-9 0 Q-20 2 -26 -4" stroke="{RAT}" stroke-width="1.6" fill="none"/>'
            f'<ellipse cx="0" cy="-4" rx="10" ry="5.5" fill="{RAT}"/>'
            f'<path d="M7 -8 L15 -3 L7 0 Z" fill="{RAT}"/>'
            f'<circle cx="5" cy="-9" r="2.6" fill="{RAT}"/><circle cx="10" cy="-5" r="0.9" fill="{FACE}"/></g>')


def child(x):
    """A small child at x (feet on GY), reaching left."""
    return (f'<path d="M{x - 3} {GY - 1} L{x - 2} {GY - 18} M{x + 3} {GY - 1} L{x + 2} {GY - 18}" stroke="{PANTS}" stroke-width="4.5" stroke-linecap="round"/>'
            f'<rect x="{x - 7}" y="{GY - 40}" width="14" height="24" rx="5" fill="{KID}"/>'
            f'<path d="M{x - 5} {GY - 36} L{x - 16} {GY - 44}" stroke="{KID}" stroke-width="4" stroke-linecap="round"/>'
            f'<circle cx="{x - 17}" cy="{GY - 45}" r="2.4" fill="{SKIN}"/>'
            f'<circle cx="{x}" cy="{GY - 47}" r="7" fill="{SKIN}"/>'
            f'<path d="M{x - 7} {GY - 49} A7 7 0 0 1 {x + 7} {GY - 49} Z" fill="{HAIR}"/>')


def screwdriver(x, y, insulated=True, ang=-35):
    handle = TOOL_RED if insulated else 'url(#steel)'
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 2.5)}" width="13" height="5" rx="2" fill="{handle}"/>'
            + (f'<rect x="{f(x - 13)}" y="{f(y - 1.4)}" width="13" height="2.8" fill="{TOOL_RED}"/>' if insulated else '')
            + f'<rect x="{f(x - 16 if insulated else x - 14)}" y="{f(y - 0.9)}" width="{3 if insulated else 14}" height="1.8" fill="url(#steel)"/></g>')


# --------------------------------------------------------------------------
# The street stage: a feeder pillar on its plinth, cables into the ground.
# --------------------------------------------------------------------------

CAB = (24, 72, 92, 112)   # x, y, w, h of the cabinet
GLANDS = (48, 70, 92)


def street():
    out = card_open('street')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#pavement)"/>')
    return out


def interior(x, y, w, h, fuses=True, puddle=False):
    """The open pillar seen from the street: R, Y, B, N busbars and one fuse
    way per phase, cables down to the bottom."""
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#cabIn)"/>']
    for i, col in enumerate(PHASES + (NEUTRAL,)):
        by = y + 8 + i * 8
        o.append(f'<rect x="{x + 6}" y="{by}" width="{w - 12}" height="4.5" rx="1" fill="url(#copper)"/>')
        o.append(f'<rect x="{x + 6}" y="{by}" width="6" height="4.5" fill="{col}"/>')
    for i, col in enumerate(PHASES):
        fx = x + 22 + i * 22
        o.append(f'<path d="M{fx} {y + 10 + i * 8} L{fx} {y + 48}" stroke="{col}" stroke-width="2.6"/>')
        o.append(f'<rect x="{fx - 7}" y="{y + 46}" width="14" height="30" rx="1.5" fill="url(#base)"/>')
        if fuses:
            o.append(f'<rect x="{fx - 4}" y="{y + 50}" width="8" height="22" rx="1.5" fill="url(#porcelain)"/>')
        o.append(f'<path d="M{fx} {y + 76} L{fx} {y + h}" stroke="{col}" stroke-width="3"/>')
    nx = x + w - 10
    o.append(f'<rect x="{nx - 3}" y="{y + 46}" width="6" height="30" rx="1" fill="url(#steel)"/>')
    o.append(f'<path d="M{nx} {y + 76} L{nx} {y + h}" stroke="{NEUTRAL}" stroke-width="3"/>')
    if puddle:
        o.append(f'<ellipse cx="{x + w / 2}" cy="{y + h - 6}" rx="{w / 2 - 6}" ry="5" fill="{WATER}" opacity="0.85"/>')
    return ''.join(o)


def pillar(door='closed', lock='locked', entry='sealed', rusty=False, puddle=False):
    """door: closed / open / broken; lock: locked / hanging / none;
    entry: sealed / gap."""
    x, y, w, h = CAB
    o = [f'<rect x="{x - 6}" y="{y + h}" width="{w + 12}" height="{GY - y - h}" fill="url(#plinth)"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="url(#cabinet)"/>',
         f'<path d="M{x - 4} {y} L{x + w + 4} {y} L{x + w} {y - 6} L{x} {y - 6} Z" fill="url(#cabinet)"/>']
    if door == 'closed':
        o.append(f'<rect x="{x + 4}" y="{y + 4}" width="{w - 8}" height="{h - 8}" rx="2" fill="url(#door)"/>')
        o += [f'<path d="M{x + 18} {y + 14 + i * 5} L{x + w - 18} {y + 14 + i * 5}" stroke="#5E7366" stroke-width="2"/>' for i in range(4)]
        o.append(f'<rect x="{x + w - 14}" y="{y + 48}" width="5" height="16" rx="2" fill="{FACE}"/>')
        o.append(f'<rect x="{x + w - 16}" y="{y + 66}" width="9" height="4" rx="1" fill="url(#steel)"/>')
    else:
        o.append(interior(x + 4, y + 4, w - 8, h - 8, puddle=puddle))
        if door == 'open':
            o.append(f'<path d="M{x + 4} {y + 4} L{x - 18} {y + 12} L{x - 18} {y + h - 4} L{x + 4} {y + h - 4} Z" fill="url(#door)"/>')
            o.append(f'<rect x="{x - 15}" y="{y + 66}" width="7" height="4" rx="1" fill="url(#steel)"/>')
        else:  # broken: hanging off one hinge
            o.append(f'<g transform="rotate(24 {x + 4} {y + h - 4})"><rect x="{x - 18}" y="{y + 4}" width="22" height="{h - 8}" fill="url(#door)"/>'
                     f'<path d="M{x - 14} {y + 30} l6 4 l-4 6 M{x - 10} {y + 70} l5 -4" stroke="{RUST}" stroke-width="3" stroke-linecap="round"/></g>')
    if rusty:
        o.append(f'<path d="M{x + 4} {y + h - 6} q8 -10 18 -2 q10 -8 16 0 M{x + w - 8} {y + 8} q-4 10 2 18" stroke="{RUST}" stroke-width="4" fill="none" stroke-linecap="round"/>')
    if lock == 'locked':
        o.append(padlock(x + w - 12, y + 70))
    elif lock == 'hanging':
        o.append(padlock(x - 12, y + 70, open_=True))
    # Cable entries along the plinth: sealed glands or an open gap.
    for gx in GLANDS:
        o.append(f'<path d="M{gx} {y + h} L{gx} {H}" stroke="{WIRE}" stroke-width="4"/>')
        if entry == 'sealed':
            o.append(f'<ellipse cx="{gx}" cy="{y + h + 6}" rx="6" ry="4" fill="{SEAL}"/>')
    if entry == 'gap':
        o.append(f'<path d="M{GLANDS[0] - 6} {GY} L{GLANDS[0] - 6} {y + h + 4} Q{GLANDS[1]} {y + h - 2} {GLANDS[2] + 6} {y + h + 4} L{GLANDS[2] + 6} {GY} Z" fill="{HOLE}"/>')
        for gx in GLANDS:
            o.append(f'<path d="M{gx} {y + h} L{gx} {GY}" stroke="{WIRE}" stroke-width="4"/>')
        o.append(f'<ellipse cx="{GLANDS[2] + 14}" cy="{GY - 4}" rx="5" ry="3" fill="{SEAL}"/>')
    return ''.join(o)


def walking_away(x=168):
    return worker(x, ((x - 12, 162), (x + 12, 160)), face=1, look=0)


# --------------------------------------------------------------------------
# Round 1 — door: lock the door; check the seal and the cable entry.
# --------------------------------------------------------------------------

def door_card(kind):
    out = street()
    x, y, w, h = CAB
    if kind == 'lock':
        out.append(pillar())
        out.append(worker(146, ((132, 160), (x + w - 10, y + 82)), face=-1, look=6))
        out.append(f'<rect x="{x + w - 6}" y="{y + 80}" width="7" height="2.4" fill="url(#steel)"/>')
    elif kind == 'seal':
        out.append(pillar())
        out.append(worker(146, ((132, 160), (x + w + 4, y + h + 2)), face=-1, look=16, point=(0, -1)))
    elif kind == 'open':
        out.append(pillar(door='open', lock='hanging'))
        out.append(child(140))
        out.append(walking_away(176))
    elif kind == 'broken':
        out.append(rain())
        out.append(pillar(door='broken', lock='none', rusty=True, puddle=True))
        out.append(walking_away(168))
    elif kind == 'gap':
        out.append(pillar(entry='gap'))
        out.append(rat(GLANDS[2] + 24, GY + 2, face=-1, s=1.6))
        out.append(walking_away(168))
    return card_close(out)


# --------------------------------------------------------------------------
# The close-up stage: inside the pillar. R, Y, B, N busbars across the top,
# one fuse way per phase for an outgoing feeder, the neutral link, the
# earthing terminal, sealed cable glands at the bottom.
# --------------------------------------------------------------------------

BARS = (26, 44, 62, 80)
WAYS = (60, 100, 140)
FTOP, FBOT = 106, 164


def inside(ways=('hrc', 'hrc', 'hrc'), direct=False, rusty=False):
    out = card_open('cabIn')
    for by, col in zip(BARS, PHASES + (NEUTRAL,)):
        out.append(f'<rect x="12" y="{by}" width="178" height="9" rx="1.5" fill="url(#copper)"/>')
        out.append(f'<rect x="12" y="{by}" width="10" height="9" fill="{col}"/>')
        if rusty:
            out.append(f'<path d="M30 {by + 9} l2 6 M60 {by + 9} l-1 8 M150 {by + 9} l2 5" stroke="{RUST}" stroke-width="2.4" stroke-linecap="round"/>')
    for cx, by, col in zip(WAYS, BARS, PHASES):
        out.append(f'<circle cx="{cx}" cy="{by + 4.5}" r="2.6" fill="{FACE}"/>')
        bottom = H if direct else FTOP + 4
        out.append(f'<path d="M{cx} {by + 7} L{cx} {bottom}" stroke="{col}" stroke-width="4.4"/>')
    if not direct:
        for cx, col, kind in zip(WAYS, PHASES, ways):
            out.append(fuse_way(cx, col, kind))
    # Neutral link with the outgoing neutral, the earthing terminal.
    out.append(f'<circle cx="172" cy="{BARS[3] + 4.5}" r="2.6" fill="{FACE}"/>')
    out.append(f'<rect x="166" y="{FTOP}" width="12" height="48" rx="2" fill="url(#steel)"/>')
    out.append(f'<path d="M172 {BARS[3] + 7} L172 {FTOP}" stroke="{NEUTRAL}" stroke-width="4.4"/>')
    out += [f'<circle cx="172" cy="{FTOP + 10 + i * 14}" r="2.4" fill="{FACE}"/>' for i in range(3)]
    out.append(f'<path d="M172 {FTOP + 48} L172 {H}" stroke="{NEUTRAL}" stroke-width="4.4"/>')
    out.append(f'<rect x="10" y="190" width="22" height="8" rx="2" fill="url(#steel)"/><circle cx="21" cy="194" r="2.4" fill="{FACE}"/>')
    out.append(f'<path d="M21 198 L21 {H}" stroke="{EARTH}" stroke-width="3.4"/>')
    # Gland plate with sealed entries.
    out.append(f'<rect x="0" y="206" width="200" height="14" fill="url(#base)"/>')
    for cx in WAYS + (172,):
        out.append(f'<ellipse cx="{cx}" cy="207" rx="7" ry="3.6" fill="{SEAL}"/>')
    return out


def fuse_way(cx, col, kind):
    o = [f'<rect x="{cx - 15}" y="{FTOP}" width="30" height="{FBOT - FTOP}" rx="3" fill="url(#base)"/>',
         f'<rect x="{cx - 7}" y="{FTOP + 4}" width="14" height="6" rx="1" fill="url(#steel)"/>',
         f'<rect x="{cx - 7}" y="{FBOT - 10}" width="14" height="6" rx="1" fill="url(#steel)"/>']
    if kind == 'hrc':
        o.append(f'<rect x="{cx - 9}" y="{FTOP + 12}" width="18" height="{FBOT - FTOP - 24}" rx="3" fill="url(#porcelain)"/>')
        o.append(f'<rect x="{cx - 6}" y="{FTOP + 8}" width="12" height="5" fill="url(#steel)"/><rect x="{cx - 6}" y="{FBOT - 13}" width="12" height="5" fill="url(#steel)"/>')
    elif kind == 'wire':
        pts = ' '.join(f'L{cx + (6 if i % 2 else -6)} {FTOP + 10 + i * 5}' for i in range(8))
        o.append(f'<path d="M{cx} {FTOP + 8} {pts} L{cx} {FBOT - 8}" stroke="{COPPER}" stroke-width="3" fill="none" stroke-linejoin="round"/>')
    elif kind == 'strip':
        o.append(f'<rect x="{cx - 5}" y="{FTOP + 6}" width="10" height="{FBOT - FTOP - 12}" rx="1" fill="url(#copper)"/>')
        o.append(f'<circle cx="{cx}" cy="{FTOP + 10}" r="2" fill="{FACE}"/><circle cx="{cx}" cy="{FBOT - 10}" r="2" fill="{FACE}"/>')
    o.append(f'<path d="M{cx} {FBOT} L{cx} 206" stroke="{col}" stroke-width="5"/>')
    return ''.join(o)


def sfu():
    """A switch fuse unit over the three ways: a steel box, a window on the
    HRC cartridges and the operating handle."""
    o = [f'<rect x="38" y="{FTOP - 4}" width="124" height="{FBOT - FTOP + 8}" rx="4" fill="url(#panel)"/>',
         f'<rect x="46" y="{FTOP + 6}" width="108" height="26" rx="2" fill="url(#base)"/>']
    for cx in WAYS:
        o.append(f'<rect x="{cx - 8}" y="{FTOP + 9}" width="16" height="20" rx="2" fill="url(#porcelain)"/>')
    o.append(f'<circle cx="100" cy="{FBOT - 18}" r="9" fill="{FACE}"/>')
    o.append(f'<rect x="86" y="{FBOT - 21}" width="28" height="6" rx="3" fill="{TOOL_RED}" transform="rotate(-30 100 {FBOT - 18})"/>')
    for cx, col in zip(WAYS, PHASES):
        o.append(f'<path d="M{cx} {FBOT + 4} L{cx} 206" stroke="{col}" stroke-width="5"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 2 — fuse: every outgoing phase through a fuse unit (HRC / SFU).
# --------------------------------------------------------------------------

def fuse_card(kind):
    if kind == 'hrc':
        out = inside()
        out.append(screwdriver(150, 196, insulated=True, ang=0))
    elif kind == 'sfu':
        out = inside(ways=('none', 'none', 'none'))
        out.append(sfu())
    elif kind == 'wire':
        out = inside(ways=('hrc', 'wire', 'hrc'))
        out.append(f'<rect x="88" y="186" width="24" height="4" rx="1" fill="{TOOL_RED}"/>')
    elif kind == 'strip':
        out = inside(ways=('hrc', 'strip', 'hrc'))
        out.append(f'<circle cx="100" cy="{FTOP - 10}" r="10" fill="url(#steel)" opacity="0.6"/><circle cx="100" cy="{FTOP - 10}" r="4" fill="{FACE}"/>')
    elif kind == 'direct':
        out = inside(direct=True)
        out.append(f'<rect x="38" y="{FTOP - 4}" width="124" height="10" rx="3" fill="url(#panel)"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — faults: a gloved hand shines a torch inside the pillar.
# --------------------------------------------------------------------------

def torch(tx, ty):
    """A gloved hand from the bottom right with a torch, its beam on (tx, ty)."""
    hx, hy = 184, 186
    ang = math.degrees(math.atan2(ty - hy, tx - hx))
    d = math.hypot(tx - hx, ty - hy)
    return (f'<g transform="rotate({f(ang)} {hx} {hy})">'
            f'<path d="M{hx + 12} {hy - 4} L{f(hx + d)} {f(hy - 16)} L{f(hx + d)} {f(hy + 16)} L{hx + 12} {hy + 4} Z" fill="{BEAM}" opacity="0.35"/>'
            f'<rect x="{hx - 10}" y="{hy - 4}" width="24" height="8" rx="2" fill="{FACE}"/>'
            f'<rect x="{hx + 12}" y="{hy - 5}" width="4" height="10" rx="1" fill="{BEAM}"/>'
            f'<circle cx="{hx - 2}" cy="{hy}" r="7" fill="{GLOVE}"/>'
            f'<rect x="{hx - 30}" y="{hy - 6}" width="22" height="12" rx="4" fill="url(#shirt)"/></g>'
            f'<circle cx="{tx}" cy="{ty}" r="16" fill="url(#glow)" opacity="0.7"/>')


def faults_card(kind):
    if kind == 'tight':
        out = inside()
        out.append(torch(WAYS[0], FTOP + 6))
    elif kind == 'dry':
        out = inside()
        out.append(torch(WAYS[1], 204))
    elif kind == 'hotspot':
        out = inside()
        cx = WAYS[1]
        out.append(f'<circle cx="{cx}" cy="{FTOP + 8}" r="18" fill="url(#heat)"/>')
        out.append(f'<ellipse cx="{cx}" cy="{FTOP + 8}" rx="12" ry="9" fill="url(#burn)"/>')
        out.append(f'<g stroke="#5A5A5A" stroke-width="1.6" fill="none" opacity="0.8"><path d="M{cx - 4} {FTOP - 4} q-4 -6 0 -12 q4 -6 0 -12"/><path d="M{cx + 5} {FTOP - 2} q-4 -6 0 -12"/></g>')
        out.append(torch(cx, FTOP + 8))
    elif kind == 'spark':
        out = inside()
        cx = WAYS[2]
        out.append(f'<rect x="{cx - 6}" y="{FTOP + 2}" width="12" height="5" fill="url(#steel)" transform="rotate(-25 {cx} {FTOP + 4})"/>')
        out.append(spark(cx + 3, FTOP + 6, 1.0))
        out.append(torch(cx, FTOP + 8))
    elif kind == 'water':
        out = inside(rusty=True)
        out.append(rain(0, 200, 0, 100))
        out.append(f'<ellipse cx="100" cy="200" rx="80" ry="8" fill="{WATER}" opacity="0.85"/>')
        out.append(torch(WAYS[0], 200))
    elif kind == 'rat':
        out = inside()
        cx = WAYS[0]
        out.append(torch(cx + 20, 186))
        out.append(f'<rect x="{cx - 3}" y="182" width="6" height="8" fill="{COPPER}"/>')
        out.append(rat(cx + 8, 196, face=-1, s=1.3))
        out.append(spark(cx, 184, 0.6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — balance: a new connection on the lightest phase.
# --------------------------------------------------------------------------

ROWS = (52, 98, 144)


def house(x, y, new=False):
    s = (f'<rect x="{x}" y="{y - 11}" width="16" height="11" fill="{HOUSE}"/>'
         f'<path d="M{x - 2} {y - 10} L{x + 8} {y - 19} L{x + 18} {y - 10} Z" fill="{ROOF}"/>'
         f'<rect x="{x + 6}" y="{y - 7}" width="4" height="7" fill="{FACE}"/>')
    if new:
        s = (f'<circle cx="{x + 8}" cy="{y - 9}" r="18" fill="url(#glow)"/>' + s
             + f'<rect x="{x - 4}" y="{y - 23}" width="24" height="26" rx="3" fill="none" stroke="#FFFFFF" stroke-width="1.6" stroke-dasharray="3 2"/>')
    return s


def balance_card(counts, new_on=None, blown=False, hot=False):
    out = street()
    # Neutral along the pavement.
    out.append(f'<path d="M44 186 L196 186" stroke="{NEUTRAL}" stroke-width="3"/>')
    if hot:
        out.append(f'<path d="M44 186 L196 186" stroke="{HOT}" stroke-width="5" opacity="0.8"/>')
        out.append(f'<circle cx="60" cy="186" r="22" fill="url(#heat)"/>')
        out.append(f'<g stroke="{HOT}" stroke-width="1.6" fill="none" opacity="0.9">'
                   + ''.join(f'<path d="M{x} 180 q-3 -5 0 -10 q3 -5 0 -10"/>' for x in (70, 104, 138, 172)) + '</g>')
    # The pillar, bottom left, three phase feeders to the rows.
    out.append(f'<rect x="4" y="{GY - 2}" width="44" height="6" fill="url(#plinth)"/>')
    out.append(f'<rect x="8" y="140" width="36" height="56" rx="2" fill="url(#cabinet)"/>')
    out.append(f'<rect x="11" y="143" width="30" height="50" rx="2" fill="url(#door)"/>')
    out.append(padlock(36, 166, s=0.7))
    for i, (ry, col) in enumerate(zip(ROWS, PHASES)):
        px = 16 + i * 10
        out.append(f'<path d="M{px} 140 L{px} {ry} L198 {ry}" stroke="{col}" stroke-width="3" fill="none"/>')
        n = counts[i]
        for k in range(n):
            out.append(house(52 + k * 24, ry))
        if new_on == i:
            out.append(house(52 + n * 24, ry, new=True))
    if blown:
        out.append(spark(16, 136, 1.0))
        for k in range(3):
            out.append(f'<g transform="rotate({-20 + k * 25} {58 + k * 12} {GY + 6})"><rect x="{52 + k * 12}" y="{GY + 3}" width="12" height="6" rx="2" fill="url(#porcelain)"/>'
                       f'<rect x="{55 + k * 12}" y="{GY + 3}" width="6" height="6" fill="url(#burn)"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — work: PPE + insulated tools; megger with the line off, fuses out.
# --------------------------------------------------------------------------

BIG = (12, 58, 100, 128)   # x, y, w, h of the big open cabinet
BWAYS = (40, 62, 84)
BTOP = 120


def big_pillar(fuses_in):
    x, y, w, h = BIG
    o = [f'<rect x="{x - 4}" y="{y + h}" width="{w + 8}" height="{GY - y - h}" fill="url(#plinth)"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="url(#cabinet)"/>',
         f'<rect x="{x + 5}" y="{y + 5}" width="{w - 10}" height="{h - 10}" fill="url(#cabIn)"/>',
         f'<path d="M{x + 5} {y + 5} L{x - 10} {y + 12} L{x - 10} {y + h - 6} L{x + 5} {y + h - 5} Z" fill="url(#door)"/>']
    for i, col in enumerate(PHASES + (NEUTRAL,)):
        by = y + 12 + i * 10
        o.append(f'<rect x="{x + 10}" y="{by}" width="{w - 20}" height="6" rx="1" fill="url(#copper)"/>')
        o.append(f'<rect x="{x + 10}" y="{by}" width="7" height="6" fill="{col}"/>')
    for i, (cx, col) in enumerate(zip(BWAYS, PHASES)):
        o.append(f'<path d="M{cx} {y + 15 + i * 10} L{cx} {BTOP}" stroke="{col}" stroke-width="3"/>')
        o.append(f'<rect x="{cx - 8}" y="{BTOP}" width="16" height="40" rx="2" fill="url(#base)"/>')
        o.append(f'<rect x="{cx - 5}" y="{BTOP + 3}" width="10" height="4" fill="url(#steel)"/><rect x="{cx - 5}" y="{BTOP + 33}" width="10" height="4" fill="url(#steel)"/>')
        if fuses_in:
            o.append(f'<rect x="{cx - 6}" y="{BTOP + 7}" width="12" height="26" rx="2" fill="url(#porcelain)"/>')
        o.append(f'<path d="M{cx} {BTOP + 40} L{cx} {H}" stroke="{col}" stroke-width="3.6"/>')
    o.append(f'<rect x="{x + w - 16}" y="{BTOP}" width="6" height="34" rx="1" fill="url(#steel)"/>')
    o.append(f'<path d="M{x + w - 13} {BTOP + 34} L{x + w - 13} {H}" stroke="{NEUTRAL}" stroke-width="3.6"/>')
    o.append(f'<rect x="{x + w - 22}" y="{y + h - 14}" width="12" height="5" rx="1" fill="url(#steel)"/>')
    if not fuses_in:
        # The pulled fuses in a tray on the plinth.
        o.append(f'<rect x="18" y="{GY - 9}" width="40" height="9" rx="1.5" fill="url(#base)"/>')
        for k in range(3):
            o.append(f'<rect x="{22 + k * 12}" y="{GY - 16}" width="8" height="13" rx="2" fill="url(#porcelain)"/>')
    return ''.join(o)


def megger(x, y):
    return (f'<rect x="{x}" y="{y}" width="28" height="22" rx="3" fill="{MEGGER}"/>'
            f'<rect x="{x + 4}" y="{y + 3}" width="20" height="11" rx="2" fill="url(#porcelain)"/>'
            f'<path d="M{x + 14} {y + 13} L{x + 19} {y + 6}" stroke="{FACE}" stroke-width="1.2"/>'
            f'<path d="M{x + 28} {y + 11} l6 0 l0 -8" stroke="url(#steel)" stroke-width="2.4" fill="none"/>')


def work_card(kind):
    out = street()
    fuses_in = kind == 'live'
    out.append(big_pillar(fuses_in))
    target = (BWAYS[2], BTOP + 38)
    if kind in ('ppe', 'bare', 'metal'):
        tool_at = (BWAYS[2] + 6, BTOP + 2)
        out.append(worker(124, ((112, 166), (tool_at[0] + 14, tool_at[1] + 8)), face=-1, look=10, bare=(kind == 'bare')))
        out.append(screwdriver(tool_at[0] + 10, tool_at[1] + 6, insulated=(kind != 'metal'), ang=-30))
        if kind == 'metal':
            out.append(spark(BWAYS[2] - 2, 98, 0.9))
    else:  # megger on the outgoing cable: fuses out (safe) or still in (trap)
        mx, my = 150, GY - 22
        out.append(megger(mx, my))
        out.append(f'<path d="M{mx} {my + 6} Q{target[0] + 20} {target[1] + 30} {target[0]} {target[1] + 4}" stroke="{PH_R}" stroke-width="1.8" fill="none"/>')
        out.append(f'<path d="M{mx} {my + 14} Q120 {GY + 6} {BIG[0] + BIG[2] - 16} {BIG[1] + BIG[3] - 12}" stroke="{NEUTRAL}" stroke-width="1.8" fill="none"/>')
        out.append(worker(132, ((mx + 4, my + 10), (target[0] + 4, target[1] + 2)), face=-1, look=12))
        if kind == 'live':
            out.append(spark(target[0], target[1] + 2, 1.0))
    return card_close(out)


CARDS = {
    'door_lock': door_card('lock'),
    'door_seal': door_card('seal'),
    'door_open': door_card('open'),
    'door_broken': door_card('broken'),
    'door_gap': door_card('gap'),
    'fuse_hrc': fuse_card('hrc'),
    'fuse_sfu': fuse_card('sfu'),
    'fuse_wire': fuse_card('wire'),
    'fuse_strip': fuse_card('strip'),
    'fuse_direct': fuse_card('direct'),
    'faults_tight': faults_card('tight'),
    'faults_dry': faults_card('dry'),
    'faults_hotspot': faults_card('hotspot'),
    'faults_spark': faults_card('spark'),
    'faults_water': faults_card('water'),
    'faults_rat': faults_card('rat'),
    'balance_low_b': balance_card((4, 4, 3), new_on=2),
    'balance_low_y': balance_card((4, 3, 4), new_on=1),
    'balance_heavy': balance_card((5, 3, 2), new_on=0),
    'balance_blown': balance_card((6, 2, 2), blown=True),
    'balance_neutral': balance_card((5, 3, 2), new_on=0, hot=True),
    'work_ppe': work_card('ppe'),
    'work_megger': work_card('megger'),
    'work_bare': work_card('bare'),
    'work_metal': work_card('metal'),
    'work_live': work_card('live'),
}

# Safe cards and traps per round (mirrors learn_board_pack37.dart).
ROUNDS = {
    'door': (['door_lock', 'door_seal'], ['door_open', 'door_broken', 'door_gap']),
    'fuse': (['fuse_hrc', 'fuse_sfu'], ['fuse_wire', 'fuse_strip', 'fuse_direct']),
    'faults': (['faults_tight', 'faults_dry'], ['faults_hotspot', 'faults_spark', 'faults_water', 'faults_rat']),
    'balance': (['balance_low_b', 'balance_low_y'], ['balance_heavy', 'balance_blown', 'balance_neutral']),
    'work': (['work_ppe', 'work_megger'], ['work_bare', 'work_metal', 'work_live']),
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
