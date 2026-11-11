"""Picture cards for lesson 4.6 শেখা ("সঠিক আর্থিং (Earthing) পরীক্ষা ও রক্ষণাবেক্ষণ").

python -I tool/m4_board46_art.py .

Writes assets/game/art/m4_board46/*.svg in the clean gradient style of
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 4.6 and its film script only:
  1. patrol: on line patrolling every pole's earthing is checked by eye —
     the earth strip down the pole is not cut, stolen or badly rusted, and its
     connection points are tight and rust-free;
  2. measure: looking is not enough — the real test is an Earth Resistance
     Tester or Earth Megger, by the Fall of Potential method: two temporary
     spikes driven into the ground besides the earth electrode;
  3. tx: a transformer has double earthing — two separate earth pits — for
     its neutral (system earthing) and for its body (equipment earthing);
     earth connections use brass or stainless-steel nuts and bolts, not
     ordinary ones that rust;
  4. care: loose connections are cleaned, greased and tightened; in dry
     weather water is poured into the pit (pipe earthing); the area round the
     pit is kept clean and its cover in place;
  5. soil: rocky or sandy soil has a high resistance — use several
     electrodes or treat the soil (layers of charcoal and salt round the
     electrode); not just any iron rod pushed into the ground (right
     material, right length).

Fairness (the playbook, section 4): every card in a round shares one
backdrop family and one set of colours; the script checks every hand the
dealer can make (one safe card + any three traps): each colour or gradient
the safe card draws is drawn by a trap in that hand, and the safe card's
backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board46_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board46')
W, H = 200, 220
GY = 184

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
STRIP = '#AEB7BE'      # the GI earth strip
STRIP_D = '#7D868E'
BRASS = '#D9A93B'
BRASS_D = '#A87C22'
RUST = '#9A4A22'
RUST_L = '#C46A33'
PH_R = '#D8402F'
PH_Y = '#F0C02E'
PH_B = '#2F6BCB'
PHASES = (PH_R, PH_Y, PH_B)
EARTH = '#3E9B4F'
METER = '#E8742A'
METER_D = '#B9561A'
FACE = '#1E2329'
LCD = '#9FD49B'
CREAM = '#F4F1E8'
WATER = '#5FB4E8'
CRACK = '#6E5B3A'
CHAR = '#26221F'      # charcoal
SALT = '#F2F2EC'
ROCK = '#8F8A80'
ROCK_D = '#6E6A62'
WEED = '#5E8C3A'
TIN = '#4F7FA0'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D8E8EF"/></linearGradient>
  <linearGradient id="close" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#8E7D59"/></linearGradient>
  <linearGradient id="section" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9C7B55"/><stop offset="1" stop-color="#6E5236"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA0A4"/><stop offset="0.5" stop-color="#C9CED1"/><stop offset="1" stop-color="#8A9094"/></linearGradient>
  <linearGradient id="cover" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B7B9B6"/><stop offset="1" stop-color="#8D908C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="bucket" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9563E"/><stop offset="0.5" stop-color="#E2775C"/><stop offset="1" stop-color="#B04A34"/></linearGradient>
  <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="0.5" stop-color="#FFE07A" stop-opacity="0.8"/><stop offset="1" stop-color="#FFE07A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
  <clipPath id="bub"><circle cx="46" cy="44" r="30"/></clipPath>
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


def _hand(p, point=0):
    x, y = p
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{GLOVE}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, point=(0, 0), knee=5.0, props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black gloves."""
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face, knee)
    kf = _joint(hip, ff, face, knee)
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
    g.append(_hand(hb, point[0]))
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
    g.append(_hand(hf, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def _scaled(x, fig):
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def _local(x, p):
    return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)


def worker(x, hands_world, face=-1, look=0, point=(0, 0)):
    """A standing worker at x (feet on GY); hands in card coordinates."""
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    feet = ((x - 7 * face, GY - 1), (x + 6 * face, GY - 1))
    hands = (_local(x, hands_world[0]), _local(x, hands_world[1]))
    return _scaled(x, figure(hip, sh, head, feet, hands, face, look, point))


def squat(x, hands_world, face=-1, look=0):
    """A worker squatting at x to work low down; hands in card coordinates."""
    hip = (x - 2 * face, GY - 16)
    sh = (x + 5 * face, GY - 40)
    head = (x + 9 * face, GY - 48)
    feet = ((x - 10 * face, GY - 1), (x + 8 * face, GY - 1))
    hands = (_local(x, hands_world[0]), _local(x, hands_world[1]))
    return _scaled(x, figure(hip, sh, head, feet, hands, face, look, knee=9.0))


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def nut(x, y, r=3.2, col=BRASS, dark=BRASS_D):
    pts = ' '.join(f'{f(x + r * math.cos(a))},{f(y + r * math.sin(a))}' for a in [i * math.pi / 3 + math.pi / 6 for i in range(6)])
    return f'<polygon points="{pts}" fill="{col}" stroke="{dark}" stroke-width="0.8"/><circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.38)}" fill="{dark}"/>'


def rust_blots(pts, s=1.0):
    return ''.join(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(4.2 * s)}" ry="{f(2.6 * s)}" fill="{RUST}" opacity="0.9"/>'
                   f'<ellipse cx="{f(x + 1.5 * s)}" cy="{f(y - 0.6 * s)}" rx="{f(2 * s)}" ry="{f(1.2 * s)}" fill="{RUST_L}"/>' for x, y in pts)


def pit(cx, y=GY + 10, cover=True, rubbish=False, dry=False, funnel=False):
    """An earth pit in the ground: a concrete frame; its cover on or lifted
    aside; the electrode pipe top in the middle."""
    o = []
    if dry:
        o.append(''.join(f'<path d="M{f(cx + dx)} {f(y + dy)} l{f(a)} {f(b)} l{f(c)} {f(d)}" stroke="{CRACK}" stroke-width="1.2" fill="none"/>'
                         for dx, dy, a, b, c, d in ((-30, 2, 6, 4, 5, -2), (24, -2, 5, 5, 6, 1), (-22, 10, -5, 4, -6, 2), (18, 9, 6, 3, 4, 3))))
    o.append(f'<path d="M{f(cx - 20)} {f(y - 6)} L{f(cx + 20)} {f(y - 6)} L{f(cx + 24)} {f(y + 6)} L{f(cx - 24)} {f(y + 6)} Z" fill="url(#cover)" stroke="{ROCK_D}" stroke-width="1"/>')
    if cover:
        o.append(f'<path d="M{f(cx - 16)} {f(y - 4)} L{f(cx + 16)} {f(y - 4)} L{f(cx + 19)} {f(y + 4)} L{f(cx - 19)} {f(y + 4)} Z" fill="url(#cover)" stroke="{ROCK}" stroke-width="0.8"/>'
                 f'<path d="M{f(cx - 4)} {f(y)} L{f(cx + 4)} {f(y)}" stroke="{ROCK_D}" stroke-width="1.6" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{f(cx - 16)} {f(y - 4)} L{f(cx + 16)} {f(y - 4)} L{f(cx + 19)} {f(y + 4)} L{f(cx - 19)} {f(y + 4)} Z" fill="{CHAR}"/>')
        o.append(f'<rect x="{f(cx - 3)}" y="{f(y - 8)}" width="6" height="10" fill="url(#steel)"/>')
        if funnel:
            o.append(f'<path d="M{f(cx - 9)} {f(y - 18)} L{f(cx + 9)} {f(y - 18)} L{f(cx + 2.5)} {f(y - 8)} L{f(cx - 2.5)} {f(y - 8)} Z" fill="url(#steel)" stroke="{STRIP_D}" stroke-width="0.8"/>')
    if rubbish:
        o.append(f'<path d="M{f(cx - 22)} {f(y + 4)} q-2 -12 3 -16 M{f(cx - 16)} {f(y + 4)} q1 -10 -3 -14 M{f(cx + 18)} {f(y + 4)} q3 -12 -1 -17 M{f(cx + 24)} {f(y + 5)} q-1 -9 4 -12" stroke="{WEED}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                 f'<path d="M{f(cx - 10)} {f(y - 2)} l12 -4 l6 6 l-10 3 Z" fill="{CREAM}" stroke="{ROCK}" stroke-width="0.8"/>'
                 f'<ellipse cx="{f(cx + 6)}" cy="{f(y + 1)}" rx="6" ry="2.6" fill="{TIN}"/>')
    return ''.join(o)


def bucket(x, y=GY, tilt=0, water=True):
    o = [f'<g transform="rotate({tilt} {f(x)} {f(y - 8)})">',
         f'<path d="M{f(x - 9)} {f(y - 16)} L{f(x + 9)} {f(y - 16)} L{f(x + 7)} {f(y)} L{f(x - 7)} {f(y)} Z" fill="url(#bucket)"/>',
         f'<path d="M{f(x - 9)} {f(y - 16)} Q{f(x)} {f(y - 30)} {f(x + 9)} {f(y - 16)}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>']
    if water:
        o.append(f'<ellipse cx="{f(x)}" cy="{f(y - 15)}" rx="8" ry="2" fill="{WATER}"/>')
    o.append('</g>')
    return ''.join(o)


def grease_tin(x, y=GY):
    return (f'<rect x="{f(x - 7)}" y="{f(y - 10)}" width="14" height="10" rx="1.5" fill="{TIN}"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y - 10)}" rx="7" ry="2" fill="{PH_Y}"/>')


def spanner(x, y, ang=-30, s=1.0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({ang}) scale({s})"><rect x="0" y="-1.8" width="20" height="3.6" rx="1.4" fill="url(#steel)"/>'
            '<path d="M20 -5 L27 -5 L27 -1.8 L23.5 -1.8 L23.5 1.8 L27 1.8 L27 5 L20 5 Z" fill="url(#steel)"/></g>')


def sun(x=170, y=28):
    rays = ''.join(f'<path d="M{f(x + math.cos(a) * 14)} {f(y + math.sin(a) * 14)} L{f(x + math.cos(a) * 20)} {f(y + math.sin(a) * 20)}"/>'
                   for a in [i * math.pi / 4 for i in range(8)])
    return (f'<circle cx="{x}" cy="{y}" r="26" fill="url(#sun)"/><circle cx="{x}" cy="{y}" r="10" fill="{PH_Y}"/>'
            f'<g stroke="{PH_Y}" stroke-width="2" stroke-linecap="round">{rays}</g>')


# --------------------------------------------------------------------------
# The pole stage: a PCC pole, its GI earth strip clamped down its side and
# run along the ground into the earth pit.
# --------------------------------------------------------------------------

PX = 56            # pole centre
PIT = 112          # pit centre
JOINT = (PIT, GY + 2)


def pole_stage(strip='whole', cover=True, rubbish=False, dry=False, funnel=False, joint='tight'):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<path d="M{PX - 6} 0 L{PX + 6} 0 L{PX + 10} {GY + 4} L{PX - 10} {GY + 4} Z" fill="url(#pole)"/>')
    out.append(f'<rect x="{PX - 40}" y="22" width="80" height="6" fill="{STRIP_D}"/>')
    for dx in (-30, 30):
        out.append(f'<path d="M{PX + dx - 4} 22 L{PX + dx + 4} 22 L{PX + dx + 2.5} 10 L{PX + dx - 2.5} 10 Z" fill="url(#porcelain)"/>')
    out.append(f'<path d="M0 8 L200 8" stroke="{WIRE}" stroke-width="1.4"/>')
    out.append(pit(PIT, cover=cover, rubbish=rubbish, dry=dry, funnel=funnel))
    # The earth strip: from the crossarm down the pole's right side, along the ground to the pit.
    sx = lambda y: PX + 7 + (y / GY) * 3.5
    top, bend = 28, GY - 2
    def band(d):
        return (f'<path d="{d}" stroke="{WIRE}" stroke-width="5.6" fill="none" stroke-linejoin="round" stroke-linecap="round"/>'
                f'<path d="{d}" stroke="{STRIP}" stroke-width="3.4" fill="none" stroke-linejoin="round" stroke-linecap="round"/>')
    if strip == 'whole':
        out.append(band(f'M{f(sx(top))} {top} L{f(sx(bend))} {bend} L{JOINT[0] - 4} {JOINT[1]}'))
    elif strip == 'cut':
        out.append(band(f'M{f(sx(top))} {top} L{f(sx(92))} 92 l7 6'))
        out.append(band(f'M{f(sx(140) + 8)} 134 L{f(sx(142))} 142 L{f(sx(bend))} {bend} L{JOINT[0] - 4} {JOINT[1]}'))
    elif strip == 'stolen':
        out.append(band(f'M{f(sx(top))} {top} L{f(sx(40))} 40'))
        out.append(band(f'M{JOINT[0] - 10} {JOINT[1]} L{JOINT[0] - 4} {JOINT[1]}'))
    for y in (60, 100, 140):
        x = sx(y)
        out.append(f'<rect x="{f(x - 4)}" y="{y - 2}" width="8" height="4" rx="1" fill="{STRIP_D}"/>')
    jx, jy = JOINT
    if joint == 'loose':
        out.append(nut(jx + 1, jy + 6, 2.6))
    else:
        out.append(nut(jx, jy, 2.8))
    return out


# --------------------------------------------------------------------------
# The close-up of the bottom joint: the strip bolted to the electrode clamp.
# --------------------------------------------------------------------------

def joint_close(state='tight'):
    out = card_open('close')
    # The pit frame and the electrode pipe rising out of it.
    out.append(f'<path d="M30 168 L170 168 L190 220 L10 220 Z" fill="url(#cover)" stroke="{ROCK_D}" stroke-width="1.2"/>')
    out.append(f'<path d="M48 176 L152 176 L166 220 L34 220 Z" fill="{CHAR}"/>')
    out.append('<rect x="84" y="60" width="32" height="160" fill="url(#steel)"/>')
    out.append(f'<ellipse cx="100" cy="60" rx="16" ry="5" fill="{STRIP_D}"/>')
    # The clamp band round the pipe.
    out.append(f'<rect x="78" y="98" width="44" height="20" rx="3" fill="url(#steel)" stroke="{STRIP_D}" stroke-width="1"/>')
    if state == 'loose':
        # The strip end pulled off the bolt, hanging; the nut lies below.
        out.append(f'<path d="M0 34 L46 70 Q60 82 58 104 L54 128" stroke="{STRIP}" stroke-width="10" fill="none" stroke-linejoin="round"/>')
        out.append(f'<circle cx="55" cy="122" r="3" fill="{STRIP_D}"/>')
        out.append('<rect x="120" y="104" width="12" height="8" rx="1" fill="url(#steel)"/>')
        out.append(nut(126, 108, 3.4, STRIP, STRIP_D))
        out.append(nut(70, 160, 7.5))
        out.append(f'<path d="M86 108 L114 108" stroke="{STRIP_D}" stroke-width="1"/>')
    else:
        out.append(f'<path d="M0 34 L46 70 Q60 82 82 106 L124 106" stroke="{STRIP}" stroke-width="10" fill="none" stroke-linejoin="round"/>')
        out.append(f'<path d="M0 34 L46 70 Q60 82 82 106 L124 106" stroke="{STRIP_D}" stroke-width="1" fill="none" transform="translate(0 4)"/>')
        if state == 'rust':
            out.append(nut(96, 108, 7.5, RUST, '#5E2A12'))
            out.append(nut(116, 108, 7.5, RUST, '#5E2A12'))
            out.append(rust_blots([(30, 54), (52, 80), (104, 102), (88, 118), (100, 140), (92, 86)], 2.2))
        else:
            out.append(nut(96, 108, 7.5))
            out.append(nut(116, 108, 7.5))
            out.append(f'<path d="M108 66 l4 -8 M116 70 l7 -5" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" opacity="0.8"/>')
    return out


def patrol_card(kind):
    if kind == 'close_ok':
        return card_close(joint_close('tight'))
    if kind in ('rust', 'loose'):
        return card_close(joint_close(kind))
    out = pole_stage(strip={'ok': 'whole', 'cut': 'cut', 'stolen': 'stolen'}[kind])
    out.append(worker(156, ((150, 150), (128, 112)), face=-1, look=-8, point=(0, -1)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — measure: the earth tester and two spikes (fall of potential).
# --------------------------------------------------------------------------

EX = 30            # the earth electrode (pit) in this stage


def spike(x, planted=True):
    if planted:
        return (f'<rect x="{f(x - 1.6)}" y="{GY - 14}" width="3.2" height="26" fill="url(#steel)"/>'
                f'<rect x="{f(x - 6)}" y="{GY - 16}" width="12" height="3" rx="1.2" fill="{STRIP_D}"/>'
                f'<ellipse cx="{f(x)}" cy="{GY + 12}" rx="5" ry="1.6" fill="{CRACK}"/>')
    return (f'<g transform="rotate(84 {f(x)} {GY + 9})"><rect x="{f(x - 1.6)}" y="{GY - 4}" width="3.2" height="26" fill="url(#steel)"/>'
            f'<rect x="{f(x - 6)}" y="{GY - 6}" width="12" height="3" rx="1.2" fill="{STRIP_D}"/></g>')


def tester(x, y, kind='digital', lid=False):
    """A ground-standing earth tester, top-left at (x, y): an orange case;
    digital = an LCD with bars; megger = a dial and a crank on its side."""
    o = [f'<rect x="{x}" y="{y}" width="34" height="24" rx="3" fill="{METER}" stroke="{METER_D}" stroke-width="1.2"/>']
    if lid:
        o.append(f'<rect x="{x - 1}" y="{y - 3}" width="36" height="8" rx="2" fill="{METER_D}"/>')
        return ''.join(o)
    if kind == 'digital':
        o.append(f'<rect x="{x + 4}" y="{y + 4}" width="26" height="11" rx="1.5" fill="{FACE}"/>')
        o.append(''.join(f'<rect x="{x + 7 + i * 6}" y="{y + 6.5}" width="4" height="6" rx="0.8" fill="{LCD}"/>' for i in range(4)))
    else:
        o.append(f'<path d="M{x + 6} {y + 16} A11 11 0 0 1 {x + 28} {y + 16} Z" fill="{CREAM}" stroke="{FACE}" stroke-width="1"/>')
        o.append(f'<path d="M{x + 17} {y + 16} L{x + 10} {y + 9}" stroke="{PH_R}" stroke-width="1.4" stroke-linecap="round"/>')
        o.append(f'<path d="M{x + 34} {y + 12} l8 0 l0 -10" stroke="{FACE}" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                 f'<circle cx="{x + 42}" cy="{y + 1}" r="2.4" fill="{FACE}"/>')
    for i in range(3):
        o.append(f'<circle cx="{x + 8 + i * 9}" cy="{y + 20}" r="1.8" fill="{(EARTH, PH_Y, PH_R)[i]}"/>')
    return ''.join(o)


def tlead(p0, p1, col, sag=6):
    mx, my = (p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + sag
    return f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="{col}" stroke-width="1.6" fill="none"/>'


def measure_stage():
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<path d="M{EX - 4} 0 L{EX + 4} 0 L{EX + 7} {GY + 4} L{EX - 7} {GY + 4} Z" fill="url(#pole)"/>')
    out.append(f'<path d="M{EX + 5} 20 L{EX + 7.5} {GY - 2} L{EX + 16} {GY + 4}" stroke="{STRIP}" stroke-width="2.6" fill="none"/>')
    out.append(f'<path d="M{EX + 4} {GY + 4} L{EX + 30} {GY + 4} L{EX + 33} {GY + 12} L{EX + 1} {GY + 12} Z" fill="url(#cover)" stroke="{ROCK_D}" stroke-width="0.8"/>')
    out.append(nut(EX + 17, GY + 4, 2.4))
    return out


def measure_card(kind):
    out = measure_stage()
    tx, ty = 66, GY - 24
    if kind == 'eye':
        out.append(tester(150, GY - 24, lid=True))
        out.append(spike(150, planted=False))
        out.append(spike(176, planted=False))
        out.append(worker(76, ((70, 150), (44, 112)), face=-1, look=-10, point=(0, -1)))
        return card_close(out)
    out.append(squat(112, ((tx + 26, ty + 2), (tx + 34, ty + 6)), face=-1, look=8))
    out.append(tester(tx, ty, 'megger' if kind in ('megger', 'one') else 'digital'))
    e_t, p_t, c_t = (tx + 8, ty + 20), (tx + 17, ty + 20), (tx + 26, ty + 20)
    out.append(tlead(e_t, (EX + 17, GY + 2), EARTH, 4))
    xp, xc = 140, 184
    if kind in ('tester', 'megger'):
        out += [spike(xp), spike(xc), tlead(p_t, (xp, GY - 15), PH_Y, 10), tlead(c_t, (xc, GY - 15), PH_R, 14)]
    elif kind == 'one':
        out += [spike(xp), tlead(p_t, (xp, GY - 15), PH_Y, 10)]
    elif kind == 'lying':
        out += [spike(xp, planted=False), spike(xc, planted=False),
                tlead(p_t, (xp - 12, GY + 9), PH_Y, 4), tlead(c_t, (xc - 12, GY + 9), PH_R, 6)]
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — tx: a transformer's double earthing (neutral and body), brass /
# stainless nuts on the earth connections.
# --------------------------------------------------------------------------

TK = (64, 98, 70)          # tank x, y, width
NPITS = (150, 182)
BPITS = (16, 44)


def small_pit(cx):
    return (f'<path d="M{cx - 12} {GY + 6} L{cx + 12} {GY + 6} L{cx + 14} {GY + 14} L{cx - 14} {GY + 14} Z" fill="url(#cover)" stroke="{ROCK_D}" stroke-width="0.8"/>'
            + nut(cx, GY + 6, 2.2))


def transformer(neutral_pits=NPITS, body_pits=BPITS, bubble='brass'):
    x, y, w = TK
    o = [f'<rect x="{x - 6}" y="{GY - 8}" width="{w + 12}" height="8" fill="#A8A29A"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{GY - 8 - y}" rx="3" fill="url(#tank)"/>']
    o += [f'<rect x="{x + 6 + i * 9}" y="{y + 10}" width="4" height="{GY - 26 - y}" rx="1.5" fill="#5C7459"/>' for i in range(7)]
    for i, col in enumerate(PHASES):
        bx = x + 10 + i * 18
        o.append(f'<path d="M{bx - 5} {y} L{bx + 5} {y} L{bx + 3} {y - 14} L{bx - 3} {y - 14} Z" fill="url(#porcelain)"/>')
        o.append(f'<rect x="{bx - 1.2}" y="{y - 26}" width="2.4" height="7" fill="url(#steel)"/>')
        o.append(f'<rect x="{bx - 3.5}" y="{y - 20}" width="7" height="6" rx="1" fill="{col}"/>')
    nx = x + w - 8
    o.append(f'<path d="M{nx - 3.5} {y} L{nx + 3.5} {y} L{nx + 2} {y - 10} L{nx - 2} {y - 10} Z" fill="url(#porcelain)"/>')
    o.append(f'<rect x="{nx - 2.5}" y="{y - 15}" width="5" height="5" rx="1" fill="{FACE}"/>')
    for cx in set(neutral_pits) | set(body_pits):
        o.append(small_pit(cx))
    # Neutral earth: from the neutral bushing over the tank's right side down to its pits.
    for k, cx in enumerate(neutral_pits):
        dx = 6 + k * 5
        o.append(f'<path d="M{nx + 2} {y - 12} L{x + w + dx} {y - 4} L{x + w + dx} {GY + 2} L{cx - 3} {GY + 2} L{cx} {GY + 6}" '
                 f'stroke="{STRIP}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>')
    # Body earth: from two bolts at the tank's foot to its pits.
    for k, cx in enumerate(body_pits):
        by = GY - 22 + k * 8
        o.append(nut(x + 4, by, 2.2))
        o.append(f'<path d="M{x + 2} {by} L{x - 4 - k * 5} {by} L{x - 4 - k * 5} {GY + 2} L{cx + 3} {GY + 2} L{cx} {GY + 6}" '
                 f'stroke="{STRIP}" stroke-width="2.4" fill="none" stroke-linejoin="round"/>')
    # The zoom bubble on a body-earth bolt.
    bx, by, r = 46, 44, 30
    tgt = (x + 4, GY - 22)
    o.append(f'<path d="M{bx + 14} {by + 26} L{tgt[0]} {tgt[1]}" stroke="#FFFFFF" stroke-width="1.4" stroke-dasharray="3 2"/>')
    o.append(f'<circle cx="{bx}" cy="{by}" r="{r}" fill="url(#tank)" stroke="#FFFFFF" stroke-width="2"/>')
    o.append('<g clip-path="url(#bub)">')
    o.append(f'<path d="M{bx - 34} {by + 4} L{bx + 34} {by + 4}" stroke="{STRIP}" stroke-width="12"/>')
    if bubble == 'rust':
        o.append(nut(bx, by + 4, 10, RUST, '#5E2A12'))
        o.append(rust_blots([(bx - 20, by + 2), (bx + 18, by + 6), (bx - 6, by + 14)], 1.8))
    else:
        o.append(nut(bx, by + 4, 10))
        if bubble == 'spanner':
            o.append(spanner(bx + 32, by - 22, 128, 1.6))
    o.append('</g>')
    return ''.join(o)


def tx_card(kind):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    if kind == 'double':
        out.append(transformer())
    elif kind == 'brass':
        out.append(transformer(bubble='spanner'))
    elif kind == 'one':
        out.append(transformer(neutral_pits=(166,), body_pits=(166,)))
    elif kind == 'nobody':
        out.append(transformer(body_pits=()))
    elif kind == 'noneutral':
        out.append(transformer(neutral_pits=()))
    elif kind == 'rust':
        out.append(transformer(bubble='rust'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — care: tighten and grease, water the pit in dry weather, keep the
# pit clean and covered. A bucket of water and a grease tin are in every card.
# --------------------------------------------------------------------------

def care_card(kind):
    if kind == 'water':
        out = pole_stage(cover=False, funnel=True, dry=True)
        out.append(sun())
        bx, by = PIT + 14, GY - 30
        out.append(f'<path d="M{bx - 8} {by - 4} Q{PIT + 2} {by} {PIT} {GY - 10}" stroke="{WATER}" stroke-width="3.2" fill="none" stroke-linecap="round"/>')
        out.append(squat(146, ((bx + 6, by - 2), (bx + 2, by - 14)), face=-1, look=10))
        out.append(bucket(bx + 4, by + 2, tilt=-62))
        out.append(grease_tin(182))
    elif kind == 'tighten':
        out = pole_stage()
        out.append(sun())
        out.append(squat(138, ((JOINT[0] + 10, JOINT[1] - 6), (JOINT[0] + 18, GY - 14)), face=-1, look=14))
        out.append(spanner(JOINT[0] + 2, JOINT[1] - 2, -24, 0.9))
        out.append(f'<path d="M{JOINT[0] - 6} {JOINT[1] - 3} q6 -3 10 0" stroke="{PH_Y}" stroke-width="2" fill="none"/>')
        out.append(grease_tin(160))
        out.append(bucket(184))
    elif kind == 'dry':
        out = pole_stage(dry=True)
        out.append(sun())
        out.append(worker(162, ((156, 150), (150, 152)), face=-1, look=0))
        out.append(bucket(184))
        out.append(grease_tin(140))
    elif kind == 'loose':
        out = pole_stage(joint='loose')
        out.append(sun())
        out.append(f'<path d="M{JOINT[0] - 4} {JOINT[1]} l-2 5" stroke="{STRIP}" stroke-width="3.2"/>')
        out.append(worker(166, ((172, 150), (160, 150)), face=1, look=0))
        out.append(bucket(140))
        out.append(grease_tin(186))
    elif kind == 'rubbish':
        out = pole_stage(cover=False, rubbish=True)
        out.append(sun())
        out.append(worker(162, ((156, 150), (150, 152)), face=-1, look=0))
        out.append(bucket(184))
        out.append(grease_tin(140))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — soil: rocky / sandy soil — several electrodes or a treated pit
# (charcoal and salt); not any iron rod, not too short.
# --------------------------------------------------------------------------

SG = 52   # the ground surface in the cross-section


def soil_stage():
    out = card_open('section')
    out.append(f'<rect width="{W}" height="{SG}" fill="url(#sky)"/>')
    out.append(f'<rect y="{SG - 3}" width="{W}" height="5" fill="{WEED}"/>')
    for x, y, rx, ry in ((22, 90, 12, 7), (170, 80, 14, 8), (40, 150, 15, 9), (160, 160, 13, 8), (86, 205, 16, 7),
                         (150, 120, 9, 6), (20, 196, 11, 7), (184, 206, 10, 6), (64, 112, 8, 5), (132, 196, 9, 5)):
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{ROCK}" stroke="{ROCK_D}" stroke-width="1.2"/>')
    # The earth strip coming down from a pole stub at the left to the electrode head.
    out.append(f'<path d="M6 0 L14 0 L16 {SG} L4 {SG} Z" fill="url(#pole)"/>')
    # A sack of charcoal and a sack of salt on the surface.
    for sx, col in ((168, CHAR), (186, SALT)):
        out.append(f'<path d="M{sx - 8} {SG - 3} L{sx - 6} {SG - 17} Q{sx} {SG - 21} {sx + 6} {SG - 17} L{sx + 8} {SG - 3} Z" fill="{col}" stroke="{ROCK_D}" stroke-width="0.8"/>')
    return out


def rod(x, top, bottom, iron=False, bend=False):
    if iron:
        d = f'M{x} {top} L{x} {top + 30} Q{x + 2} {top + 44} {x + 14} {bottom}' if bend else f'M{x} {top} L{x} {bottom}'
        return (f'<path d="{d}" stroke="{RUST}" stroke-width="5" fill="none" stroke-linecap="round"/>'
                + rust_blots([(x, top + 16), (x + 4, top + 40)], 0.9))
    return f'<rect x="{x - 3}" y="{top}" width="6" height="{bottom - top}" rx="1.5" fill="url(#steel)" stroke="{STRIP_D}" stroke-width="0.6"/>'


def soil_card(kind):
    out = soil_stage()
    top = SG - 6
    heads = []
    if kind == 'multi':
        for x in (60, 108, 156):
            out.append(rod(x, top, 196))
            heads.append(x)
        out.append(f'<path d="M60 {top + 2} L156 {top + 2}" stroke="{STRIP}" stroke-width="3"/>')
    elif kind == 'salt':
        x = 100
        for i in range(7):
            y0 = 76 + i * 18
            out.append(f'<rect x="{x - 22}" y="{y0}" width="44" height="18" fill="{CHAR if i % 2 == 0 else SALT}"/>')
        out.append(rod(x, top, 202))
        out.append(f'<path d="M{x - 9} {top - 12} L{x + 9} {top - 12} L{x + 2.5} {top} L{x - 2.5} {top} Z" fill="url(#steel)" stroke="{STRIP_D}" stroke-width="0.8"/>')
        heads.append(x)
    elif kind == 'one':
        out.append(rod(100, top, 124))
        heads.append(100)
    elif kind == 'iron':
        out.append(rod(100, top, 112, iron=True, bend=True))
        heads.append(100)
    elif kind == 'short':
        out.append(rod(100, top, 72))
        heads.append(100)
    # Strip from the pole stub to the first head.
    out.append(f'<path d="M16 {SG - 22} L30 {SG - 22} L30 {top + 2} L{heads[0]} {top + 2}" stroke="{STRIP}" stroke-width="3" fill="none"/>')
    for x in heads:
        out.append(nut(x, top + 2, 3))
    return card_close(out)


CARDS = {
    'patrol_ok': patrol_card('ok'),
    'patrol_close_ok': patrol_card('close_ok'),
    'patrol_cut': patrol_card('cut'),
    'patrol_stolen': patrol_card('stolen'),
    'patrol_rust': patrol_card('rust'),
    'patrol_loose': patrol_card('loose'),
    'measure_tester': measure_card('tester'),
    'measure_megger': measure_card('megger'),
    'measure_eye': measure_card('eye'),
    'measure_one': measure_card('one'),
    'measure_lying': measure_card('lying'),
    'tx_double': tx_card('double'),
    'tx_brass': tx_card('brass'),
    'tx_one': tx_card('one'),
    'tx_nobody': tx_card('nobody'),
    'tx_noneutral': tx_card('noneutral'),
    'tx_rust': tx_card('rust'),
    'care_water': care_card('water'),
    'care_tighten': care_card('tighten'),
    'care_dry': care_card('dry'),
    'care_loose': care_card('loose'),
    'care_rubbish': care_card('rubbish'),
    'soil_multi': soil_card('multi'),
    'soil_salt': soil_card('salt'),
    'soil_one': soil_card('one'),
    'soil_iron': soil_card('iron'),
    'soil_short': soil_card('short'),
}

# Safe cards and traps per round (mirrors learn_board_pack46.dart).
ROUNDS = {
    'patrol': (['patrol_ok', 'patrol_close_ok'], ['patrol_cut', 'patrol_stolen', 'patrol_rust', 'patrol_loose']),
    'measure': (['measure_tester', 'measure_megger'], ['measure_eye', 'measure_one', 'measure_lying']),
    'tx': (['tx_double', 'tx_brass'], ['tx_one', 'tx_nobody', 'tx_noneutral', 'tx_rust']),
    'care': (['care_water', 'care_tighten'], ['care_dry', 'care_loose', 'care_rubbish']),
    'soil': (['soil_multi', 'soil_salt'], ['soil_one', 'soil_iron', 'soil_short']),
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
