"""Picture cards for the Module 2 lesson 2.5 board (অপারেটিং রড (হট স্টিক): দূরত্বের সুরক্ষা).

python -I tool/m2_board25_art.py .

Writes assets/game/art/m2_board25/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art. Never deletes anything: it only (over)writes its own cards.

What the cards show comes from lesson 2.5 only:
  1. check: before every use run a hand along the full length for cracks,
     deep scratches or a damaged glaze; it must be clean and fully dry; every
     telescopic section locked (pro tip 4);
  2. hold: the attachment fitted firmly on the head (a loose one can fall from
     above, pro tip 3); hold the stick in two hands (pro tip 2); a smooth
     operation needs no jerk or force (pro tip 1);
  3. fuse: DO fuse — stand to the side / at an angle, never straight under or
     in front; hook the fuse puller firmly in the ring; one quick controlled
     pull with the face and body turned aside; goggles or face shield and
     insulated gloves (an arc or flash can come);
  4. switch: an AB switch / isolator only off-load (the breaker opened first);
     a spline / socket on the handle, turned slowly and in control; on-load
     makes a huge arc;
  5. care: wipe with a soft dry cloth after use; store in a waterproof bag or
     hung on a wall — never on the ground or a vehicle floor (scratches);
     never used as an ordinary stick for other work.

Fairness (the playbook, section 4): every card in a round shares one
backdrop, one worker and one stick; only the act (or the defect) tells the
safe card from a trap. The script checks every hand the dealer can make (one
safe card + any three traps): each colour or gradient the safe card draws is
drawn by a trap in that hand, and the safe card's backdrop is a trap's
backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board25_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board25')
W, H = 200, 220

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
FERRULE = '#6F777E'
FUSE = '#3C4148'
SHIELD = '#BFE3F5'
SHIELD_D = '#7FB3CF'
CRACK = '#14161A'
GREASE = '#4A3A26'
DROP = '#DCE6EE'
MOLTEN = '#FF8A3D'
LIT = '#FFD86B'
DARKWIN = '#3A4552'
WALL = '#B98A6A'
WALL_D = '#9C7052'
LEAF = '#5E7F55'
TRUNK = '#5A4630'
BAGC = '#24476B'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FA8C9"/><stop offset="1" stop-color="#CFE0EA"/></linearGradient>
  <linearGradient id="skyYard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8DB3CF"/><stop offset="1" stop-color="#DCE8EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="rod" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6CF5E"/><stop offset="0.5" stop-color="#E5A126"/><stop offset="1" stop-color="#B9781A"/></linearGradient>
  <linearGradient id="bag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F5A85"/><stop offset="1" stop-color="#1C3A58"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.5"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(sky):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


# --------------------------------------------------------------------------
# The worker (the storm board's figure, with gloves / face shield switches).
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


def _hand(p, gloves=True):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE if gloves else SKIN}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, knees=None, head_face=None, gloves=True, shield=True,
           props_back='', props_front='', front_hand=True):
    """The lineman: blue shirt, dark trousers, yellow helmet; insulated
    gloves and a clear face shield unless switched off. head_face turns the
    head alone (the face turned aside)."""
    hf_ = face if head_face is None else head_face
    g = []
    fb, ff = feet
    kb = knees[0] if knees and knees[0] else _joint(hip, fb, face)
    kf = knees[1] if knees and knees[1] else _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, kf, ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hfp = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hfp, face, down=True)
    g.append(_limb(sb, eb, hb, SHIRT_D, 5.4))
    g.append(_hand(hb, gloves))
    g.append(props_back)
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * hf_
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * hf_)} {f(hy + 1)} Q{f(hx - 7 * hf_)} {f(hy + 6)} {f(hx - 3 * hf_)} {f(hy + 7)} L{f(hx - 3 * hf_)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if hf_ > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * hf_)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if shield:
        hd.append(f'<path d="M{f(hx + 2 * hf_)} {f(hy - 1)} L{f(hx + 11 * hf_)} {f(hy - 1)} L{f(hx + 10 * hf_)} {f(hy + 9)} '
                  f'L{f(hx + 4 * hf_)} {f(hy + 10)} Z" fill="{SHIELD}" fill-opacity="0.6" stroke="{SHIELD_D}" stroke-width="0.9"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    if front_hand:
        g.append(_limb(sf, ef, hfp, SHIRT, 5.4))
    g.append(props_front)
    if front_hand:
        g.append(_hand(hfp, gloves))
    return ''.join(g)


GY = 192


def worker(x, hands, face=1, look=0, lean=0, gy=GY, feet_gap=12, **kw):
    hip = (x, gy - 30)
    sh = (x + (1 + lean) * face, gy - 56)
    head = (x + (3 + lean * 1.3) * face, gy - 64)
    feet = ((x - feet_gap / 2 * face - 1 * face, gy - 1), (x + feet_gap / 2 * face, gy - 1))
    knees = ((x - 3 * face, gy - 15), (x + 4 * face, gy - 15))
    return figure(hip, sh, head, feet, hands, face, look, knees=knees, **kw)


# --------------------------------------------------------------------------
# The hot stick: fibreglass rod, ferrules at the telescopic joints, an
# attachment on its head. Drawn in local coords (x along the rod).
# --------------------------------------------------------------------------

def rod(p0, p1, head='puller', bands=(0.36, 0.7), loose=False, slid=False, extra='', bow=0.0):
    (x0, y0), (x1, y1) = p0, p1
    L = math.hypot(x1 - x0, y1 - y0)
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    s = []
    if bow:
        # A rod bent under force: a curved body.
        s.append(f'<path d="M0 0 Q{f(L / 2)} {f(bow)} {f(L)} 0" stroke="#B9781A" stroke-width="6" fill="none" stroke-linecap="round"/>'
                 f'<path d="M0 0 Q{f(L / 2)} {f(bow)} {f(L)} 0" stroke="#E5A126" stroke-width="4" fill="none" stroke-linecap="round"/>')
    elif slid:
        # The top section has slid down into the one below (lock not set).
        cut = L * bands[-1]
        s.append(f'<rect x="0" y="-2.6" width="{f(cut)}" height="5.2" rx="2" fill="url(#rod)"/>')
        s.append(f'<rect x="{f(cut - 16)}" y="-2.1" width="{f(L - cut + 16)}" height="4.2" rx="1.8" fill="url(#rod)" transform="translate(-16 0)"/>')
        s.append(f'<g stroke="#FFFFFF" stroke-width="1.4" stroke-linecap="round" opacity="0.9"><path d="M{f(cut - 8)} -8 l-10 0"/><path d="M{f(cut - 4)} 8 l-10 0"/></g>')
        L = L - 16
    else:
        s.append(f'<rect x="0" y="-2.6" width="{f(L)}" height="5.2" rx="2" fill="url(#rod)"/>')
    for b in bands:
        bx = L * b
        s.append(f'<rect x="{f(bx - 2)}" y="-3.4" width="4" height="6.8" rx="1" fill="{FERRULE}"/>')
    s.append(f'<rect x="-3" y="-3.2" width="7" height="6.4" rx="1.4" fill="{FERRULE}"/>')
    s.append(extra)
    hd = ''
    if head == 'puller':
        hd = (f'<rect x="0" y="-2" width="7" height="4" fill="url(#steel)"/>'
              f'<path d="M7 0 q9 0 9 -6 q0 -5 -5 -5" stroke="#7D868E" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    elif head == 'socket':
        hd = f'<rect x="0" y="-3.6" width="10" height="7.2" rx="1.2" fill="url(#steel)"/><rect x="8" y="-2.4" width="2.4" height="4.8" fill="{FUSE}"/>'
    if hd:
        if loose:
            hd = f'<g transform="translate({f(L + 2)} 0) rotate(38)">{hd}</g>'
            hd += (f'<g stroke="#FFFFFF" stroke-width="1.3" fill="none" stroke-linecap="round" opacity="0.9">'
                   f'<path d="M{f(L + 4)} -12 q6 2 6 9"/><path d="M{f(L + 10)} -16 q8 3 8 13"/></g>')
        else:
            hd = f'<g transform="translate({f(L)} 0)">{hd}</g>'
    s.append(hd)
    return f'<g transform="translate({f(x0)} {f(y0)}) rotate({f(ang)})">{"".join(s)}</g>'


def on_rod(p0, p1, t):
    return lerp(p0, p1, t)


def crack_marks(L):
    """A long split along the body, opened up (dark gap, pale edge)."""
    out = []
    for x in (L * 0.3, L * 0.62):
        d = f'M{f(x - 16)} -2.8 L{f(x - 9)} 1.6 L{f(x - 3)} -2 L{f(x + 3)} 2.2 L{f(x + 9)} -1.6 L{f(x + 16)} 2.8'
        out.append(f'<path d="{d}" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.55"/>')
        out.append(f'<path d="{d}" stroke="{CRACK}" stroke-width="1.8" fill="none"/>')
    return ''.join(out)


def scratch_marks(L):
    """Deep gouges through the glaze."""
    return ''.join(f'<path d="M{f(L * t + i * 5)} -3.2 l6 6.4" stroke="{CRACK}" stroke-width="1.5" stroke-linecap="round"/>'
                   for t in (0.18, 0.58) for i in range(4))


def grease_marks(L):
    return ''.join(f'<ellipse cx="{f(L * t)}" cy="{f(dy)}" rx="{f(rx)}" ry="2.6" fill="{GREASE}" opacity="0.85"/>'
                   for t, dy, rx in ((0.18, 0.4, 6), (0.27, -0.6, 4), (0.55, 0.3, 7), (0.82, -0.2, 5)))


def wet_marks(L):
    drips = ''.join(f'<path d="M{f(L * t)} 2.6 q-2.6 5 0 7.5 q2.6 -2.5 0 -7.5 Z" fill="{DROP}" stroke="#7FB3CF" stroke-width="0.6"/>' for t in (0.15, 0.3, 0.47, 0.62, 0.8, 0.92))
    sheen = ''.join(f'<ellipse cx="{f(L * t)}" cy="-1" rx="3" ry="0.9" fill="{DROP}" opacity="0.9"/>' for t in (0.1, 0.24, 0.4, 0.56, 0.72, 0.88))
    return drips + sheen


def motion(x, y, ang=0, n=3, op=0.85):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})" stroke="#FFFFFF" stroke-width="1.5" stroke-linecap="round" opacity="{op}">'
            + ''.join(f'<path d="M0 {i * 5 - (n - 1) * 2.5} l-11 0"/>' for i in range(n)) + '</g>')


def shake(x, y):
    return (f'<g stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linecap="round" opacity="0.9">'
            f'<path d="M{f(x - 8)} {f(y - 6)} l-4 4 l4 4 l-4 4"/><path d="M{f(x + 8)} {f(y - 6)} l4 4 l-4 4 l4 4"/></g>')


def twist(x, y, r=8):
    return (f'<path d="M{f(x - r)} {f(y + 2)} A{r} {r * 0.5} 0 1 0 {f(x + r)} {f(y + 2)}" stroke="#FFFFFF" stroke-width="1.5" fill="none" opacity="0.9"/>'
            f'<path d="M{f(x + r)} {f(y + 2)} l-3.4 -1.2 M{f(x + r)} {f(y + 2)} l0.6 -3.4" stroke="#FFFFFF" stroke-width="1.5" opacity="0.9"/>')


def arc_spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def insulator(x, y, s=1.0):
    return (f'<g transform="translate({f(x)} {f(y)}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


def tree_row(y, fill='#6F9560'):
    out = ''.join(f'<ellipse cx="{x}" cy="{f(y - r * 0.6)}" rx="{f(r * 1.3)}" ry="{r}"/>' for x, r in [(10, 12), (34, 9), (58, 13), (90, 8)])
    return f'<g fill="{fill}" opacity="0.8">{out}</g>'


def cloudlet(x, y):
    return (f'<g fill="#FFFFFF" opacity="0.85"><ellipse cx="{x}" cy="{y}" rx="18" ry="6"/>'
            f'<ellipse cx="{x + 12}" cy="{y - 5}" rx="12" ry="7"/></g>')


# --------------------------------------------------------------------------
# Stage A — the line with a DO fuse cutout (rounds hold, fuse).
# --------------------------------------------------------------------------

PX = 168
PW = 13
ARM_Y = 40
FX = 116
RING = (FX + 3, 62)            # the fuse's pull ring
BAR_B = (FX + 8, 94)           # barrel hinge (bottom)
BAR_T = (FX + 10, 54)          # barrel top contact


def do_fuse(open_=False):
    s = []
    # Bracket from the cross-arm, porcelain body, contacts.
    s.append(f'<path d="M{FX + 20} {ARM_Y + 4} L{FX + 20} 50" stroke="#5F676F" stroke-width="3"/>')
    s.append(f'<rect x="{FX + 16}" y="50" width="8" height="46" rx="2" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/>')
    for y in (58, 66, 74, 82, 90):
        s.append(f'<ellipse cx="{FX + 20}" cy="{y}" rx="6.5" ry="1.8" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>')
    s.append(f'<rect x="{FX + 4}" y="49" width="18" height="4" rx="1" fill="url(#steelArm)"/>')
    s.append(f'<rect x="{FX + 2}" y="94" width="20" height="4" rx="1" fill="url(#steelArm)"/>')
    barrel = (f'<path d="M{f(BAR_B[0])} {f(BAR_B[1])} L{f(BAR_T[0])} {f(BAR_T[1])}" stroke="{FUSE}" stroke-width="5.5" stroke-linecap="round"/>'
              f'<circle cx="{f(RING[0])}" cy="{f(RING[1])}" r="3.6" fill="none" stroke="#7D868E" stroke-width="1.8"/>'
              f'<path d="M{f(RING[0] + 3.4)} {f(RING[1])} L{f(BAR_T[0] - 1)} {f(RING[1])}" stroke="#7D868E" stroke-width="1.6"/>')
    if open_:
        barrel = f'<g transform="rotate(-150 {f(BAR_B[0])} {f(BAR_B[1])})">{barrel}</g>'
    s.append(barrel)
    # The jumper from the line to the top contact.
    s.append(f'<path d="M{FX + 22} 50 Q{FX + 30} 40 {PX - 26} {ARM_Y - 14}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    return ''.join(s)


def line_stage(open_=False, flash=False):
    out = card_open('sky')
    out.append(cloudlet(36, 28))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(tree_row(GY + 1))
    out.append(f'<path d="M-4 22 Q60 38 {PX - 26} {ARM_Y - 14}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    out.append(f'<path d="M-4 8 Q70 22 {PX} 6" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    out.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M{FX - 4} {ARM_Y} L204 {ARM_Y - 6} L204 {ARM_Y} L{FX - 4} {ARM_Y + 6} Z" fill="url(#steelArm)"/>')
    out.append(insulator(PX - 26, ARM_Y + 3) + insulator(PX, 22, 0.85))
    out.append(do_fuse(open_))
    if flash:
        out.append(f'<ellipse cx="{BAR_T[0] + 2}" cy="{BAR_T[1] - 2}" rx="22" ry="22" fill="url(#flash)"/>')
        out.append(arc_spark(BAR_T[0] + 2, BAR_T[1] - 2, 0.7))
    return out


# --------------------------------------------------------------------------
# Round 1 — check the stick before use.
# --------------------------------------------------------------------------

WALL_X = 0
WALL_W = 116


def yard_stage(tree=False, bag_on_ground=False, hooks=True):
    out = card_open('skyYard')
    out.append(cloudlet(150, 26))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # The store's wall with two hooks for the stick.
    out.append(f'<rect x="{WALL_X}" y="62" width="{WALL_W}" height="{GY - 62}" fill="{WALL}"/>')
    out.append(f'<rect x="{WALL_X}" y="56" width="{WALL_W + 6}" height="8" fill="{WALL_D}"/>')
    bricks = ''.join(f'<path d="M0 {y} L{WALL_W} {y}"/>' for y in range(78, GY, 16))
    out.append(f'<g stroke="{WALL_D}" stroke-width="1" opacity="0.7">{bricks}</g>')
    if hooks:
        for hx in (20, 96):
            out.append(f'<path d="M{hx} 92 l0 6 q0 4 4 4 l2 0" stroke="#7D868E" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    # A tree by the yard (its branch is in reach).
    out.append(f'<path d="M184 {GY} L182 70" stroke="{TRUNK}" stroke-width="7"/>')
    out.append(f'<path d="M182 92 L150 70" stroke="{TRUNK}" stroke-width="3"/>')
    out.append(f'<g fill="{LEAF}"><ellipse cx="180" cy="56" rx="30" ry="22"/><ellipse cx="150" cy="64" rx="16" ry="10"/></g>')
    if bag_on_ground:
        out.append(empty_bag(30, GY + 10))
    return out


def empty_bag(x, y):
    """The waterproof stick bag lying empty, unused."""
    return (f'<path d="M{x} {y} q30 -6 64 -2 l2 6 q-34 -2 -66 2 Z" fill="url(#bag)"/>'
            f'<path d="M{x + 60} {y - 2} l6 0" stroke="{BAGC}" stroke-width="2"/>')


HOLD_Y = GY - 34


def held_level(x, extra=None, look=10, hands=None, head_face=None, gloves=True, front_hand=True, rod_extra=''):
    """Stick held level across the body at waist height."""
    p0, p1 = (14, HOLD_Y), (186, HOLD_Y - 2)
    hands = hands or ((x - 10, HOLD_Y), (x + 16, HOLD_Y))
    return (worker(x, hands, look=look, head_face=head_face, gloves=gloves, front_hand=front_hand, shield=False,
                   props_back=rod(p0, p1, head='puller', extra=rod_extra)), p0, p1)


def check_card(kind):
    out = yard_stage()
    x = 100
    L = math.hypot(172, 2)
    if kind == 'feel':
        # A gloved hand runs along the full length, eyes on the surface.
        fig, p0, p1 = held_level(x, look=22, hands=((x - 10, HOLD_Y), (x + 40, HOLD_Y)))
        out.append(fig)
        out.append(motion(x + 56, HOLD_Y - 8, 0, 2))
    elif kind == 'lock':
        # Twisting a telescopic joint's lock, looking at it.
        fig, p0, p1 = held_level(x, look=24, hands=((x - 10, HOLD_Y), (14 + L * 0.7 - 4, HOLD_Y - 1)))
        out.append(fig)
        out.append(twist(14 + L * 0.7, HOLD_Y - 1))
    elif kind == 'crack':
        # A cracked stick, off to the job anyway (looking toward the line).
        fig, p0, p1 = held_level(x, look=-8, rod_extra=crack_marks(L))
        out.append(fig)
        out.append(motion(x - 30, GY - 30, 0, 3))
    elif kind == 'wet':
        fig, p0, p1 = held_level(x, look=-8, rod_extra=wet_marks(L))
        out.append(fig)
        out.append(''.join(f'<circle cx="{cx}" cy="{GY + 6}" r="1.4" fill="{DROP}"/>' for cx in (40, 66, 94, 120, 150)))
    elif kind == 'scratch':
        fig, p0, p1 = held_level(x, look=-8, head_face=-1, rod_extra=scratch_marks(L))
        out.append(fig)
    elif kind == 'grease':
        fig, p0, p1 = held_level(x, look=-8, rod_extra=grease_marks(L))
        out.append(fig)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — fit the attachment, hold in two hands, no jerk.
# --------------------------------------------------------------------------

def hold_card(kind):
    out = line_stage()
    x = 60
    tip = (RING[0] - 10, RING[1] + 16)     # raised toward the fuse, not yet hooked
    hb = (x + 2, GY - 32)
    foot = lerp(hb, tip, -0.1)
    h2 = lerp(hb, tip, 0.17)
    if kind == 'two_hands':
        out.append(worker(x, (hb, h2), look=-22, props_back=rod(foot, tip)))
    elif kind == 'check_head':
        # Stick low and level, a hand on the fuse puller, checking it is firm.
        a, b = (8, GY - 38), (104, GY - 58)
        out.append(worker(x, (lerp(a, b, 0.5), lerp(b, a, 0.06)), look=18,
                          props_back=rod(a, b)))
        out.append(twist(b[0] + 4, b[1] - 2))
    elif kind == 'one_hand':
        out.append(worker(x, ((x - 6, GY - 34), h2), look=-22, props_back=rod(foot, tip)))
        out.append(shake(tip[0], tip[1]))
    elif kind == 'loose':
        out.append(worker(x, (hb, h2), look=-22, props_back=rod(foot, tip, loose=True)))
    elif kind == 'slid':
        out.append(worker(x, (hb, h2), look=-22, props_back=rod(foot, tip, slid=True)))
    elif kind == 'jerk':
        out.append(worker(x, (hb, h2), look=-22, lean=3, props_back=rod(foot, tip)))
        mid = lerp(foot, tip, 0.65)
        out.append(shake(mid[0], mid[1]))
        out.append(shake(tip[0] - 2, tip[1] - 6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — the DO fuse: stand aside, hook the ring, face away, PPE.
# --------------------------------------------------------------------------

def fuse_card(kind):
    flash = True
    if kind == 'open':
        out = line_stage(open_=True, flash=flash)
    else:
        out = line_stage(flash=flash)
    x = 58
    tip = RING
    hb = (x + 2, GY - 32)
    foot = lerp(hb, tip, -0.1)
    h2 = lerp(hb, tip, 0.17)
    if kind == 'side':
        # Hooked in the ring, one quick pull, face turned aside.
        out.append(worker(x, (hb, h2), look=10, head_face=-1, props_back=rod(foot, tip)))
        out.append(motion(foot[0] - 4, foot[1] + 4, 60, 3))
    elif kind == 'open':
        # The barrel has dropped open; he stands aside, face away.
        open_ring = (FX - 26, 112)
        hb2 = (x + 2, GY - 32)
        out.append(worker(x, (hb2, lerp(hb2, open_ring, 0.2)), look=10, head_face=-1,
                          props_back=rod(lerp(hb2, open_ring, -0.12), (open_ring[0] - 4, open_ring[1] + 2))))
    elif kind == 'under':
        # Straight under the fuse, looking up into it.
        ux = FX - 2
        hb2 = (ux + 2, GY - 32)
        out.append(worker(ux, (hb2, lerp(hb2, tip, 0.2)), look=-30, props_back=rod(lerp(hb2, tip, -0.1), tip)))
        out.append(''.join(f'<circle cx="{f(BAR_T[0] + dx)}" cy="{f(BAR_T[1] + dy)}" r="{r}" fill="{MOLTEN}"/>'
                           for dx, dy, r in ((-3, 20, 1.6), (2, 34, 1.4), (-6, 48, 1.3), (1, 62, 1.5))))
    elif kind == 'no_shield':
        out.append(worker(x, (hb, h2), look=-22, shield=False, props_back=rod(foot, tip)))
    elif kind == 'bare':
        out.append(worker(x, (hb, h2), look=10, head_face=-1, gloves=False, props_back=rod(foot, tip)))
    elif kind == 'miss':
        # Poking beside the ring instead of latching the puller in it.
        miss = (RING[0] - 12, RING[1] - 4)
        out.append(worker(x, (hb, lerp(hb, miss, 0.17)), look=-18, props_back=rod(lerp(hb, miss, -0.1), miss)))
        out.append(shake(miss[0] - 4, miss[1] + 6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — AB switch / isolator: off-load only, socket on, slow turn.
# --------------------------------------------------------------------------

HUB = (PX - PW / 2 - 4, 104)


def houses(lit):
    win = LIT if lit else DARKWIN
    out = []
    for hx, hw, hh in ((6, 34, 30), (46, 30, 24)):
        y = GY - hh
        out.append(f'<rect x="{hx}" y="{y}" width="{hw}" height="{hh}" fill="{WALL}"/>')
        out.append(f'<path d="M{hx - 3} {y} L{hx + hw / 2} {y - 14} L{hx + hw + 3} {y} Z" fill="{WALL_D}"/>')
        out.append(f'<rect x="{hx + 6}" y="{y + 7}" width="8" height="8" fill="{win}"/>')
        out.append(f'<rect x="{hx + hw - 13}" y="{y + 7}" width="8" height="8" fill="{win}"/>')
    # The service drop from the line to the houses.
    out.append(f'<path d="M{PX - 6} 60 Q90 110 26 {GY - 30}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    return ''.join(out)


def switch_stage(lit=False, arc=False):
    out = card_open('sky')
    out.append(cloudlet(80, 22))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(houses(lit))
    out.append(f'<path d="M-4 18 Q70 34 {PX - 30} 30" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    out.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    # The AB switch: a frame on top with three blades on porcelain posts.
    out.append(f'<rect x="{PX - 46}" y="32" width="84" height="5" fill="url(#steelArm)"/>')
    for bx in (PX - 38, PX - 16, PX + 22):
        out.append(f'<rect x="{bx - 3}" y="18" width="6" height="14" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>')
        out.append(f'<rect x="{bx - 8}" y="15" width="16" height="3" rx="1" fill="url(#steel)"/>')
    # The operating pipe down the pole to the handle hub.
    out.append(f'<path d="M{PX - PW / 2 - 4} 37 L{PX - PW / 2 - 4} {HUB[1]}" stroke="#5F676F" stroke-width="2.6"/>')
    out.append(f'<rect x="{HUB[0] - 6}" y="{HUB[1] - 6}" width="10" height="12" rx="2" fill="url(#steelArm)"/>')
    out.append(f'<circle cx="{HUB[0] - 1}" cy="{HUB[1]}" r="2.6" fill="{FUSE}"/>')
    if arc:
        out.append(f'<ellipse cx="{PX - 16}" cy="16" rx="40" ry="30" fill="url(#flash)"/>')
        out.append(arc_spark(PX - 38, 16, 1.0) + arc_spark(PX - 16, 14, 1.2))
    return out


def switch_card(kind):
    out = switch_stage(lit=kind == 'on_load', arc=kind == 'on_load')
    x = 70
    tip = (HUB[0] - 8, HUB[1])
    hb = (x + 2, GY - 34)
    foot = lerp(hb, tip, -0.1)
    h2 = lerp(hb, tip, 0.2)
    rotor = twist(HUB[0] - 1, HUB[1] - 14, 10)
    if kind == 'slow':
        out.append(worker(x, (hb, h2), look=-10, props_back=rod(foot, tip, head='socket')))
        out.append(rotor)
    elif kind == 'breaker':
        # The stick held upright beside him; on the phone: is the breaker open?
        rx = x + 14
        out.append(worker(x, ((rx, GY - 40), (x + 6, GY - 62)), look=-6,
                          props_back=rod((rx, GY - 2), (rx + 2, GY - 150), head='socket'),
                          props_front=f'<rect x="{x + 3}" y="{GY - 74}" width="5" height="10" rx="1.2" fill="{BOOT}"/>'))
    elif kind == 'on_load':
        out.append(worker(x, (hb, h2), look=-10, props_back=rod(foot, tip, head='socket')))
        out.append(rotor)
    elif kind == 'rush':
        out.append(worker(x, (hb, h2), look=-10, lean=2, props_back=rod(foot, tip, head='socket')))
        out.append(rotor + twist(HUB[0] - 1, HUB[1] + 14, 12) + motion(x - 10, GY - 50, 0, 3))
    elif kind == 'no_socket':
        miss = (HUB[0] - 10, HUB[1] + 14)
        out.append(worker(x, (hb, lerp(hb, miss, 0.2)), look=-10, props_back=rod(lerp(hb, miss, -0.1), miss, head='socket')))
        out.append(shake(miss[0] + 4, miss[1] + 4))
    elif kind == 'force':
        # Leaning his weight on it: the rod bows.
        out.append(worker(x + 6, ((x + 8, GY - 30), lerp((x + 8, GY - 30), tip, 0.2)), look=-4, lean=6,
                          props_back=rod(lerp((x + 8, GY - 30), tip, -0.1), tip, head='socket', bow=9)))
        out.append(shake(x + 40, GY - 62))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — care after the job.
# --------------------------------------------------------------------------

def care_card(kind):
    x = 100
    if kind == 'wipe':
        out = yard_stage(bag_on_ground=True)
        fig, p0, p1 = held_level(x, look=22, hands=((x - 10, HOLD_Y), (x + 30, HOLD_Y - 2)))
        out.append(fig)
        out.append(f'<path d="M{x + 24} {HOLD_Y - 6} l14 -1 l2 9 l-14 2 Z" fill="#FFFFFF" opacity="0.92"/>')
        out.append(motion(x + 52, HOLD_Y - 10, 0, 2))
    elif kind == 'hang':
        out = yard_stage()
        out.append(rod((14, 97), (110, 97)))
        out.append(worker(x + 30, ((x + 6, 96), (x - 18, 98)), face=-1, look=-12, shield=False))
    elif kind == 'bag':
        out = yard_stage()
        # Sliding the stick into its waterproof bag.
        out.append(rod((60, HOLD_Y - 2), (186, HOLD_Y - 4)))
        out.append(f'<path d="M6 {HOLD_Y - 8} L92 {HOLD_Y - 9} q4 6 0 12 L6 {HOLD_Y + 4} Z" fill="url(#bag)"/>')
        out.append(f'<path d="M88 {HOLD_Y - 9} l0 13" stroke="{BAGC}" stroke-width="2"/>')
        out.append(worker(x + 20, ((x + 4, HOLD_Y - 4), (x + 30, HOLD_Y - 4)), look=20, shield=False))
        out.append(motion(56, HOLD_Y - 14, 180, 2))
    elif kind == 'ground':
        out = yard_stage(bag_on_ground=True)
        out.append(rod((20, GY + 6), (150, GY + 4)))
        out.append(worker(x + 30, ((x + 22, GY - 32), (x + 36, GY - 32)), look=-6, shield=False))
        out.append(motion(x + 16, GY - 40, 180, 3))
    elif kind == 'branch':
        out = yard_stage(bag_on_ground=True)
        # Knocking a branch with it, as if it were any old stick.
        hb = (x + 2, GY - 36)
        out.append(worker(x, (hb, (x + 12, GY - 56)), look=-30, shield=False, props_back=rod(lerp(hb, (156, 70), -0.12), (156, 70))))
        out.append(f'<g fill="{LEAF}">' + ''.join(f'<ellipse cx="{cx}" cy="{cy}" rx="3.4" ry="1.8" transform="rotate(30 {cx} {cy})"/>' for cx, cy in ((140, 96), (160, 118), (132, 130))) + '</g>')
        out.append(shake(156, 78))
    elif kind == 'drag':
        out = yard_stage(bag_on_ground=True)
        # Dragging it along the ground behind him.
        out.append(rod((14, GY + 8), (x - 6, GY - 32)))
        out.append(worker(x + 4, ((x - 6, GY - 32), (x + 12, GY - 32)), face=1, look=-4, shield=False))
        out.append(f'<g stroke="{CRACK}" stroke-width="0.9" opacity="0.6">' + ''.join(f'<path d="M{sx} {GY + 12} l-12 0"/>' for sx in (40, 64, 88)) + '</g>')
        out.append(motion(x - 20, GY - 46, 0, 3))
    return card_close(out)


CARDS = {
    'check_feel': check_card('feel'),
    'check_lock': check_card('lock'),
    'check_crack': check_card('crack'),
    'check_wet': check_card('wet'),
    'check_scratch': check_card('scratch'),
    'check_grease': check_card('grease'),
    'hold_two_hands': hold_card('two_hands'),
    'hold_check_head': hold_card('check_head'),
    'hold_one_hand': hold_card('one_hand'),
    'hold_loose': hold_card('loose'),
    'hold_slid': hold_card('slid'),
    'hold_jerk': hold_card('jerk'),
    'fuse_side': fuse_card('side'),
    'fuse_open': fuse_card('open'),
    'fuse_under': fuse_card('under'),
    'fuse_no_shield': fuse_card('no_shield'),
    'fuse_bare': fuse_card('bare'),
    'fuse_miss': fuse_card('miss'),
    'switch_slow': switch_card('slow'),
    'switch_breaker': switch_card('breaker'),
    'switch_on_load': switch_card('on_load'),
    'switch_rush': switch_card('rush'),
    'switch_no_socket': switch_card('no_socket'),
    'switch_force': switch_card('force'),
    'care_wipe': care_card('wipe'),
    'care_hang': care_card('hang'),
    'care_bag': care_card('bag'),
    'care_ground': care_card('ground'),
    'care_branch': care_card('branch'),
    'care_drag': care_card('drag'),
}

# Safe cards and traps per round (mirrors learn_board_pack25.dart).
ROUNDS = {
    'check': (['check_feel', 'check_lock'], ['check_crack', 'check_wet', 'check_scratch', 'check_grease']),
    'hold': (['hold_two_hands', 'hold_check_head'], ['hold_one_hand', 'hold_loose', 'hold_slid', 'hold_jerk']),
    'fuse': (['fuse_side', 'fuse_open'], ['fuse_under', 'fuse_no_shield', 'fuse_bare', 'fuse_miss']),
    'switch': (['switch_slow', 'switch_breaker'], ['switch_on_load', 'switch_rush', 'switch_no_socket', 'switch_force']),
    'care': (['care_wipe', 'care_hang', 'care_bag'], ['care_ground', 'care_branch', 'care_drag']),
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
