"""Picture cards for the Module 4 lesson 4.4 board (ডিও (DO) ফিউজ পরিচালনা করা).

python -I tool/m4_board44_art.py .

Writes assets/game/art/m4_board44/*.svg in the same clean gradient style as
tool/m2_board25_art.py (200 x 220 scene cards, drawn edge to edge; the worker,
the hot stick and the DO fuse cutout are copied from it). No words in the
art. Never deletes anything: it only (over)writes its own cards.

What the cards show comes from lesson 4.4 (and its film script) only:
  1. prep: an undamaged operating rod (hot stick) of the right length and
     voltage rating; full PPE — helmet, insulated gloves and above all a face
     shield or safety goggles; the standing place dry and level; enough safe
     clearance around and overhead;
  2. link: clean the barrel and its contacts with a dry cloth; seat the
     link's top button in the barrel's top contact; wind the flexible tail
     round the bottom contact and tighten the nut — not too tight, not too
     loose (a loose joint heats and ruins the barrel); the leader wire must
     not block the expulsion port;
  3. open: stand under the pole with the fuse to the side / at an angle,
     never straight under or in front; hook the puller firmly in the ring;
     face aside, one quick, firm, controlled pull (a slow pull draws the arc
     out);
  4. close: seat the barrel in the bottom hinge with the stick, then, face
     aside, one quick confident push into the top contact and see it lock;
     a little spark on closing is normal (load current / transformer inrush)
     — do not open and close again and again; it stops once locked;
  5. field (the pro tips): a heavily loaded fuse is opened with a load break
     tool on the stick head; if a fault blows one fuse, open the other two
     phases too, clear the fault, then close all three one by one; a top
     contact that heats or sparks after closing is weak / worn — repaired.

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
    print('usage: python -I tool/m4_board44_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board44')
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
DROP = '#DCE6EE'
MUD = '#7A6A4A'
MOLTEN = '#FF8A3D'
LEAF = '#5E7F55'
TRUNK = '#5A4630'
TAIL = '#C9A15A'
CLOTH = '#E9E2D0'
CLOTH_D = '#C8BFA6'
GRIP = '#D8402F'
PORT = '#0E1013'
LBT = '#2F6BCB'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FA8C9"/><stop offset="1" stop-color="#CFE0EA"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3C4A57"/><stop offset="1" stop-color="#65788A"/></linearGradient>
  <linearGradient id="benchTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9C7B55"/><stop offset="1" stop-color="#7C5E3E"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="rod" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6CF5E"/><stop offset="0.5" stop-color="#E5A126"/><stop offset="1" stop-color="#B9781A"/></linearGradient>
  <linearGradient id="tube" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2A2E34"/><stop offset="0.45" stop-color="#5A616A"/><stop offset="1" stop-color="#262A2F"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.5"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE08A"/><stop offset="0.45" stop-color="#FF8A3D" stop-opacity="0.75"/><stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/></radialGradient>
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


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def rot(p, c, deg):
    a = math.radians(deg)
    dx, dy = p[0] - c[0], p[1] - c[1]
    return (c[0] + dx * math.cos(a) - dy * math.sin(a), c[1] + dx * math.sin(a) + dy * math.cos(a))


# --------------------------------------------------------------------------
# The worker (from tool/m2_board25_art.py, plus a safety-goggles switch).
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


def _hand(p):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, knees=None, head_face=None, eyes='shield',
           props_back='', props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, insulated
    gloves; eyes = 'shield' (clear face shield), 'goggles' or None."""
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
    g.append(_hand(hb))
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
    if eyes == 'shield':
        hd.append(f'<path d="M{f(hx + 2 * hf_)} {f(hy - 1)} L{f(hx + 11 * hf_)} {f(hy - 1)} L{f(hx + 10 * hf_)} {f(hy + 9)} '
                  f'L{f(hx + 4 * hf_)} {f(hy + 10)} Z" fill="{SHIELD}" fill-opacity="0.6" stroke="{SHIELD_D}" stroke-width="0.9"/>')
    elif eyes == 'goggles':
        hd.append(f'<path d="M{f(hx - 7 * hf_)} {f(hy + 0.4)} L{f(hx + 3 * hf_)} {f(hy + 0.4)}" stroke="{FUSE}" stroke-width="1.8"/>'
                  f'<rect x="{f(hx + 2.5 if hf_ > 0 else hx - 8.5)}" y="{f(hy - 1.6)}" width="6" height="4.2" rx="1.6" '
                  f'fill="{SHIELD}" stroke="{SHIELD_D}" stroke-width="0.9"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hfp, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hfp))
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
# The hot stick: fibreglass rod, ferrules at the joints, a head attachment.
# --------------------------------------------------------------------------

def rod(p0, p1, head='puller', bands=(0.36, 0.7), extra=''):
    (x0, y0), (x1, y1) = p0, p1
    L = math.hypot(x1 - x0, y1 - y0)
    ang = math.degrees(math.atan2(y1 - y0, x1 - x0))
    s = [f'<rect x="0" y="-2.6" width="{f(L)}" height="5.2" rx="2" fill="url(#rod)"/>']
    for b in bands:
        bx = L * b
        s.append(f'<rect x="{f(bx - 2)}" y="-3.4" width="4" height="6.8" rx="1" fill="{FERRULE}"/>')
    s.append(f'<rect x="-3" y="-3.2" width="7" height="6.4" rx="1.4" fill="{FERRULE}"/>')
    s.append(extra(L) if callable(extra) else extra)
    hd = ''
    if head == 'puller':
        hd = (f'<rect x="0" y="-2" width="7" height="4" fill="url(#steel)"/>'
              f'<path d="M7 0 q9 0 9 -6 q0 -5 -5 -5" stroke="#7D868E" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    elif head == 'lbt':
        hd = load_break_tool()
    if hd:
        s.append(f'<g transform="translate({f(L)} 0)">{hd}</g>')
    return f'<g transform="translate({f(x0)} {f(y0)}) rotate({f(ang)})">{"".join(s)}</g>'


def load_break_tool():
    """The load break tool on the stick head: a closed chamber body with its
    hook (local coords, along +x)."""
    return (f'<rect x="0" y="-2" width="5" height="4" fill="url(#steel)"/>'
            f'<rect x="4" y="-5.5" width="18" height="11" rx="3" fill="{LBT}" stroke="{WIRE}" stroke-width="0.8"/>'
            f'<rect x="8" y="-5.5" width="3" height="11" fill="url(#steel)"/>'
            f'<path d="M22 0 q8 0 8 -6 q0 -5 -5 -5" stroke="#7D868E" stroke-width="2.4" fill="none" stroke-linecap="round"/>')


def crack_marks(L):
    out = []
    for x in (L * 0.3, L * 0.62):
        d = f'M{f(x - 16)} -2.8 L{f(x - 9)} 1.6 L{f(x - 3)} -2 L{f(x + 3)} 2.2 L{f(x + 9)} -1.6 L{f(x + 16)} 2.8'
        out.append(f'<path d="{d}" stroke="#FFFFFF" stroke-width="3" fill="none" opacity="0.55"/>')
        out.append(f'<path d="{d}" stroke="{CRACK}" stroke-width="1.8" fill="none"/>')
    return ''.join(out)


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


def long_arc(p0, p1):
    """A drawn-out arc between two contacts (zig-zag bolt + glow)."""
    n = 7
    pts = []
    for i in range(n + 1):
        q = lerp(p0, p1, i / n)
        off = 0 if i in (0, n) else (4 if i % 2 else -4)
        pts.append((q[0] + off, q[1]))
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    mid = lerp(p0, p1, 0.5)
    r = math.hypot(p1[0] - p0[0], p1[1] - p0[1]) / 2 + 14
    return (f'<ellipse cx="{f(mid[0])}" cy="{f(mid[1])}" rx="{f(r)}" ry="{f(r)}" fill="url(#flash)"/>'
            f'<path d="{d}" stroke="#C9E6FF" stroke-width="3.4" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linejoin="round"/>')


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
# The line stage: a pole with a DO fuse cutout on its cross-arm.
# --------------------------------------------------------------------------

PX = 168
PW = 13
ARM_Y = 40
FX = 116
RING = (FX + 3, 62)            # the fuse's pull ring
BAR_B = (FX + 8, 94)           # barrel hinge (bottom)
BAR_T = (FX + 10, 54)          # barrel top contact
OPEN = -150                    # the barrel dropped open, hanging from its hinge


def do_fuse(angle=0, dx=0, jumper=True, hot=False):
    """The cutout; angle turns the barrel about its bottom hinge (0 = shut and
    latched, OPEN = dropped open). dx shifts the whole cutout along the arm."""
    s = [f'<path d="M{FX + 20} {ARM_Y + 4} L{FX + 20} 50" stroke="#5F676F" stroke-width="3"/>',
         f'<rect x="{FX + 16}" y="50" width="8" height="46" rx="2" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/>']
    for y in (58, 66, 74, 82, 90):
        s.append(f'<ellipse cx="{FX + 20}" cy="{y}" rx="6.5" ry="1.8" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>')
    s.append(f'<rect x="{FX + 4}" y="49" width="18" height="4" rx="1" fill="url(#steelArm)"/>')
    s.append(f'<rect x="{FX + 2}" y="94" width="20" height="4" rx="1" fill="url(#steelArm)"/>')
    barrel = (f'<path d="M{f(BAR_B[0])} {f(BAR_B[1])} L{f(BAR_T[0])} {f(BAR_T[1])}" stroke="{FUSE}" stroke-width="5.5" stroke-linecap="round"/>'
              f'<circle cx="{f(RING[0])}" cy="{f(RING[1])}" r="3.6" fill="none" stroke="#7D868E" stroke-width="1.8"/>'
              f'<path d="M{f(RING[0] + 3.4)} {f(RING[1])} L{f(BAR_T[0] - 1)} {f(RING[1])}" stroke="#7D868E" stroke-width="1.6"/>')
    if angle:
        barrel = f'<g transform="rotate({f(angle)} {f(BAR_B[0])} {f(BAR_B[1])})">{barrel}</g>'
    s.append(barrel)
    if hot:
        s.append(f'<circle cx="{FX + 13}" cy="51" r="13" fill="url(#heat)"/>'
                 f'<rect x="{FX + 4}" y="49" width="18" height="4" rx="1" fill="{MOLTEN}" opacity="0.8"/>')
    if jumper:
        s.append(f'<path d="M{FX + 22} 50 Q{FX + 30} 40 {PX - 26} {ARM_Y - 14}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    body = ''.join(s)
    return f'<g transform="translate({dx} 0)">{body}</g>' if dx else body


def ring_at(angle=0, dx=0):
    p = rot(RING, BAR_B, angle) if angle else RING
    return (p[0] + dx, p[1])


def top_at(angle=0, dx=0):
    p = rot(BAR_T, BAR_B, angle) if angle else BAR_T
    return (p[0] + dx, p[1])


def line_stage(angle=0, branch=False, wet=False):
    out = card_open('sky')
    out.append(cloudlet(36, 28))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(tree_row(GY + 1))
    out.append(f'<path d="M-4 22 Q60 38 {PX - 26} {ARM_Y - 14}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    out.append(f'<path d="M-4 8 Q70 22 {PX} 6" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    out.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M{FX - 4} {ARM_Y} L204 {ARM_Y - 6} L204 {ARM_Y} L{FX - 4} {ARM_Y + 6} Z" fill="url(#steelArm)"/>')
    out.append(insulator(PX - 26, ARM_Y + 3) + insulator(PX, 22, 0.85))
    out.append(do_fuse(angle))
    if branch:
        # A tree right over the standing place: its branches hang into the
        # stick's path (no clearance overhead).
        out.append(f'<path d="M14 {GY} L18 60" stroke="{TRUNK}" stroke-width="8"/>')
        out.append(f'<path d="M18 92 L78 70 M20 74 L64 52" stroke="{TRUNK}" stroke-width="3.4"/>')
        out.append(f'<g fill="{LEAF}"><ellipse cx="24" cy="50" rx="30" ry="22"/><ellipse cx="66" cy="62" rx="22" ry="13"/>'
                   f'<ellipse cx="82" cy="76" rx="14" ry="9"/></g>')
    if wet:
        # Wet, muddy, uneven ground where he stands.
        out.append(f'<path d="M20 {GY + 4} Q40 {GY - 6} 62 {GY + 2} Q80 {GY + 8} 98 {GY + 3} L98 {GY + 14} L20 {GY + 14} Z" fill="{MUD}"/>')
        out.append(f'<ellipse cx="58" cy="{GY + 6}" rx="30" ry="5" fill="{DROP}" opacity="0.85" stroke="{SHIELD_D}" stroke-width="0.8"/>')
        out.append(''.join(f'<path d="M{x} {GY + 6} q-3 -5 0 -9 q3 4 0 9 Z" fill="{DROP}" stroke="{SHIELD_D}" stroke-width="0.5"/>' for x in (36, 74, 88)))
    return out


def flash_at(p, s=0.7, r=22):
    return (f'<ellipse cx="{f(p[0] + 2)}" cy="{f(p[1] - 2)}" rx="{r}" ry="{r}" fill="url(#flash)"/>'
            + arc_spark(p[0] + 2, p[1] - 2, s))


# --------------------------------------------------------------------------
# Round 1 — prep: the right stick, full PPE with face shield or goggles,
# dry and level ground, clearance overhead.
# --------------------------------------------------------------------------

def prep_card(kind):
    out = line_stage(branch=(kind == 'branch'), wet=(kind == 'wet'))
    x = 58
    hb = (x + 2, GY - 32)
    tip = (RING[0] - 22, RING[1] + 26)            # raised, coming up to the ring
    if kind == 'branch':
        tip = (78, 74)                            # the head caught in the branches
    foot = lerp(hb, tip, -0.12)
    h2 = lerp(hb, tip, 0.17)
    eyes = {'goggles': 'goggles', 'no_eyes': None}.get(kind, 'shield')
    extra = crack_marks if kind == 'cracked' else ''
    out.append(worker(x, (hb, h2), look=-8, eyes=eyes, props_back=rod(foot, tip, extra=extra)))
    if kind == 'branch':
        out.append(shake(tip[0] + 2, tip[1] + 2))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — link: tying the fuse link in the barrel (a close-up on the bench).
# --------------------------------------------------------------------------

BX = 92                       # barrel centre x
B_TOP, B_BOT = 50, 168        # the tube's ends
STUD = (128, 176)             # the bottom contact's stud (the nut sits on it)


def gloved(x, y, ang=0):
    """A gloved hand coming in from the right edge, sleeve and all."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<rect x="8" y="-8" width="80" height="16" fill="url(#shirt)"/>'
            f'<ellipse cx="2" cy="0" rx="12" ry="9" fill="{GLOVE}"/>'
            f'<path d="M-6 -6 q-6 2 -6 7" stroke="{GLOVE}" stroke-width="5" stroke-linecap="round" fill="none"/></g>')


def pliers(x, y, ang=0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<path d="M0 -1.6 L14 -1.6 L14 1.6 L0 1.6 Z" fill="url(#steel)"/>'
            f'<path d="M14 -1 L40 -6 M14 1 L40 6" stroke="{GRIP}" stroke-width="4.4" stroke-linecap="round"/>'
            f'<circle cx="14" cy="0" r="2.2" fill="url(#steel)"/></g>')


def cloth(x, y, ang=0, s=1.0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({s})">'
            f'<path d="M-16 -8 Q0 -14 16 -8 L18 8 Q0 13 -18 8 Z" fill="{CLOTH}" stroke="{CLOTH_D}" stroke-width="1"/>'
            f'<path d="M-10 -4 Q0 -7 10 -4 M-12 3 Q0 6 12 3" stroke="{CLOTH_D}" stroke-width="1" fill="none"/></g>')


def barrel_closeup(button='seated', link=True):
    o = []
    # The tube.
    o.append(f'<rect x="{BX - 11}" y="{B_TOP}" width="22" height="{B_BOT - B_TOP}" rx="3" fill="url(#tube)"/>')
    # The top contact (cap) and, if seated, the link's button on it.
    o.append(f'<rect x="{BX - 14}" y="{B_TOP - 12}" width="28" height="14" rx="2.5" fill="url(#steel)" stroke="{FERRULE}" stroke-width="0.8"/>')
    if link and button == 'seated':
        o.append(f'<rect x="{BX - 2}" y="{B_TOP - 18}" width="4" height="7" fill="url(#steel)"/>'
                 f'<ellipse cx="{BX}" cy="{B_TOP - 18}" rx="8" ry="3.4" fill="url(#steel)" stroke="{FERRULE}" stroke-width="0.8"/>')
    elif link and button == 'askew':
        o.append(f'<g transform="rotate(32 {BX + 14} {B_TOP - 26})">'
                 f'<rect x="{BX + 12}" y="{B_TOP - 26}" width="4" height="7" fill="url(#steel)"/>'
                 f'<ellipse cx="{BX + 14}" cy="{B_TOP - 26}" rx="8" ry="3.4" fill="url(#steel)" stroke="{FERRULE}" stroke-width="0.8"/></g>'
                 f'<path d="M{BX + 3} {B_TOP - 12} Q{BX + 10} {B_TOP - 16} {BX + 12} {B_TOP - 20}" stroke="{TAIL}" stroke-width="1.6" fill="none"/>')
    # The bottom ferrule, its open end (the expulsion port) and the contact stud.
    o.append(f'<rect x="{BX - 13}" y="{B_BOT - 4}" width="26" height="12" rx="2" fill="url(#steel)" stroke="{FERRULE}" stroke-width="0.8"/>')
    o.append(f'<ellipse cx="{BX}" cy="{B_BOT + 8}" rx="10" ry="3.4" fill="{PORT}"/>')
    o.append(f'<rect x="{BX + 12}" y="{STUD[1] - 7}" width="{STUD[0] - BX - 8}" height="5" rx="1" fill="url(#steel)"/>')
    o.append(f'<rect x="{STUD[0] - 2}" y="{STUD[1] - 10}" width="4" height="14" rx="1" fill="url(#steel)"/>')
    return ''.join(o)


def nut(x, y):
    return f'<path d="M{x - 6} {y} L{x - 3} {y - 5} L{x + 3} {y - 5} L{x + 6} {y} L{x + 3} {y + 5} L{x - 3} {y + 5} Z" fill="url(#steel)" stroke="{FERRULE}" stroke-width="0.8"/>'


def tail_wrapped():
    """The flexible tail out of the port, wound round the stud, nut on."""
    x0, y0 = BX + 4, B_BOT + 9
    sx, sy = STUD
    return (f'<path d="M{x0} {y0} Q{x0 + 14} {y0 + 10} {sx - 5} {sy + 2}" stroke="{TAIL}" stroke-width="2" fill="none"/>'
            f'<ellipse cx="{sx}" cy="{sy}" rx="6" ry="2.6" fill="none" stroke="{TAIL}" stroke-width="2"/>'
            f'<ellipse cx="{sx}" cy="{sy - 3}" rx="6" ry="2.6" fill="none" stroke="{TAIL}" stroke-width="2"/>'
            + nut(sx, sy - 7))


def bench_stage():
    out = card_open('bench')
    out.append(f'<rect y="196" width="{W}" height="24" fill="url(#benchTop)"/>')
    return out


def link_card(kind):
    out = bench_stage()
    sx, sy = STUD
    if kind == 'wipe':
        # Step 1: the empty barrel and its contacts wiped with a dry cloth.
        out.append(barrel_closeup(link=False))
        out.append(gloved(BX + 24, 104, -8))
        out.append(cloth(BX + 6, 104, 10, 1.1))
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85" fill="none">'
                   f'<path d="M{BX - 26} 86 q-6 18 0 36"/><path d="M{BX - 34} 92 q-4 12 0 24"/></g>')
        out.append(pliers(28, 206, -6))
        out.append(f'<path d="M140 206 q16 -6 34 0" stroke="{TAIL}" stroke-width="2" fill="none"/>')
    else:
        button = 'askew' if kind == 'button' else 'seated'
        out.append(barrel_closeup(button))
        if kind in ('port', 'loose', 'button'):
            # A hand steadying the barrel (the job looks just as busy).
            out.append(gloved(BX + 22, 112, -6))
        if kind in ('wrap', 'button'):
            out.append(tail_wrapped())
        if kind == 'wrap':
            # The nut tightened with the pliers, a twist arrow.
            out.append(gloved(sx + 30, sy - 22, 20))
            out.append(pliers(sx + 2, sy - 7, 20))
            out.append(twist(sx, sy - 18, 9))
            out.append(cloth(40, 206, 4))
        elif kind == 'button':
            out.append(pliers(150, 206, 8))
            out.append(cloth(40, 206, 4))
        elif kind == 'port':
            # The leader wire bunched right across the port's mouth.
            x0, y0 = BX, B_BOT + 8
            out.append(f'<path d="M{x0 - 9} {y0} l4 -3 l4 5 l4 -5 l4 5 l4 -5 l3 3" stroke="{TAIL}" stroke-width="2.2" fill="none"/>'
                       f'<path d="M{x0 - 8} {y0 + 2} q8 6 18 0" stroke="{TAIL}" stroke-width="2.2" fill="none"/>'
                       f'<path d="M{x0 + 10} {y0} Q{x0 + 22} {y0 + 10} {sx - 5} {sy + 2}" stroke="{TAIL}" stroke-width="2" fill="none"/>'
                       f'<ellipse cx="{sx}" cy="{sy}" rx="6" ry="2.6" fill="none" stroke="{TAIL}" stroke-width="2"/>'
                       + nut(sx, sy - 7))
            out.append(pliers(150, 206, 8))
            out.append(cloth(40, 206, 4))
        elif kind == 'loose':
            # Slack tail in a big loop, nut left off on the bench.
            x0, y0 = BX + 4, B_BOT + 9
            out.append(f'<path d="M{x0} {y0} Q{x0 + 2} {y0 + 30} {x0 + 26} {y0 + 22} Q{sx + 14} {sy + 12} {sx + 8} {sy - 2}" stroke="{TAIL}" stroke-width="2" fill="none"/>'
                       f'<ellipse cx="{sx}" cy="{sy - 4}" rx="10" ry="4.4" fill="none" stroke="{TAIL}" stroke-width="2"/>')
            out.append(nut(166, 206))
            out.append(cloth(40, 206, 4))
            out.append(pliers(132, 210, -4))
        elif kind == 'taut':
            # Pulled bar-tight with the pliers, the tail stretched thin.
            x0, y0 = BX + 4, B_BOT + 9
            out.append(f'<path d="M{x0} {y0} L{sx + 22} {sy - 2}" stroke="{TAIL}" stroke-width="1.2"/>'
                       f'<ellipse cx="{sx}" cy="{sy}" rx="6" ry="2.6" fill="none" stroke="{TAIL}" stroke-width="2"/>' + nut(sx, sy - 7))
            out.append(gloved(sx + 46, sy - 4, 4))
            out.append(pliers(sx + 22, sy - 2, 4))
            out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9">'
                       f'<path d="M{sx + 70} {sy - 16} l10 0"/><path d="M{sx + 70} {sy + 10} l10 0"/></g>')
            out.append(shake(x0 + 18, y0 - 2))
            out.append(cloth(40, 206, 4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — open: aside / at an angle, puller in the ring, face away, one
# quick firm pull.
# --------------------------------------------------------------------------

def fuse_pose(out, x, tip, look=10, head_face=-1, head='puller', **kw):
    hb = (x + 2, GY - 32)
    out.append(worker(x, (hb, lerp(hb, tip, 0.17)), look=look, head_face=head_face,
                      props_back=rod(lerp(hb, tip, -0.1), tip, head=head), **kw))
    return hb


def open_card(kind):
    x = 58
    if kind == 'pull':
        out = line_stage()
        out.append(flash_at(BAR_T))
        fuse_pose(out, x, RING)
        out.append(motion(x - 6, GY - 22, 60, 3))
    elif kind == 'side':
        out = line_stage(OPEN)
        out.append(flash_at(BAR_T, 0.5, 16))
        fuse_pose(out, x, ring_at(OPEN))
    elif kind == 'under':
        out = line_stage()
        out.append(flash_at(BAR_T))
        fuse_pose(out, FX - 2, RING, look=-30, head_face=None)
        out.append(''.join(f'<circle cx="{f(BAR_T[0] + dx)}" cy="{f(BAR_T[1] + dy)}" r="{r}" fill="{MOLTEN}"/>'
                           for dx, dy, r in ((-3, 20, 1.6), (2, 34, 1.4), (-6, 48, 1.3), (1, 62, 1.5))))
    elif kind == 'slow':
        a = -40
        out = line_stage(a)
        out.append(long_arc(BAR_T, top_at(a)))
        fuse_pose(out, x, ring_at(a), look=-18, head_face=None)
        out.append(shake(x + 4, GY - 40))
    elif kind == 'stare':
        out = line_stage()
        out.append(flash_at(BAR_T))
        fuse_pose(out, x, RING, look=-24, head_face=None)
    elif kind == 'miss':
        out = line_stage()
        out.append(flash_at(BAR_T, 0.5, 14))
        miss = (RING[0] - 12, RING[1] - 4)
        fuse_pose(out, x, miss, look=-18, head_face=None)
        out.append(shake(miss[0] - 4, miss[1] + 6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — close: barrel in the bottom hinge, face aside, one confident push,
# see it lock; a small spark is normal — no open-and-close again.
# --------------------------------------------------------------------------

def close_card(kind):
    x = 58
    if kind == 'hinge':
        # The barrel hanging in its bottom hinge, the stick hooked to push.
        out = line_stage(OPEN)
        fuse_pose(out, x, ring_at(OPEN))
        out.append(twist(ring_at(OPEN)[0] - 4, ring_at(OPEN)[1] - 14, 7))
    elif kind == 'lock':
        # Pushed home: latched in the top contact, a small spark only.
        out = line_stage()
        out.append(flash_at(BAR_T, 0.45, 14))
        fuse_pose(out, x, RING)
        out.append(motion(x + 16, GY - 70, -120, 3))
    elif kind == 'half':
        # Left half-way: not latched, sparking at the top contact.
        a = -26
        out = line_stage(a)
        out.append(long_arc(BAR_T, top_at(a)))
        hb = (x + 2, GY - 32)
        out.append(worker(x, (hb, (x + 12, GY - 40)), look=-6, head_face=None,
                          props_back=rod((x - 4, GY - 4), (x + 30, GY - 104))))
    elif kind == 'reopen':
        # A spark at closing — and he yanks it open again.
        a = -60
        out = line_stage(a)
        out.append(flash_at(BAR_T, 0.6, 18))
        fuse_pose(out, x, ring_at(a), look=-18, head_face=None)
        out.append(motion(x - 6, GY - 22, 60, 3))
        out.append(shake(x + 6, GY - 70))
    elif kind == 'slow':
        a = -34
        out = line_stage(a)
        out.append(long_arc(BAR_T, top_at(a)))
        fuse_pose(out, x, ring_at(a), look=10, head_face=-1)
        out.append(shake(x + 4, GY - 40))
    elif kind == 'face':
        out = line_stage()
        out.append(flash_at(BAR_T, 0.45, 14))
        fuse_pose(out, x, RING, look=-26, head_face=None)
        out.append(motion(x + 16, GY - 70, -120, 3))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — field: a load break tool for a heavy load; a fault opens all
# three phases; a hot top contact is repaired.
# --------------------------------------------------------------------------

F3 = (30, -2, -34)            # the three cutouts along a longer arm (dx)
FPX = 184                     # the pole, further right


def field_stage(angles=(0, 0, 0), hot=None):
    out = card_open('sky')
    out.append(cloudlet(30, 22))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(tree_row(GY + 1))
    out.append(f'<rect x="{FPX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M{FX - 40} {ARM_Y} L204 {ARM_Y - 6} L204 {ARM_Y} L{FX - 40} {ARM_Y + 6} Z" fill="url(#steelArm)"/>')
    for i, dx in enumerate(F3):
        ix = PX - 26 + dx
        out.append(f'<path d="M-4 {16 + i * 5} Q{f(ix / 2)} {28 + i * 5} {f(ix)} {ARM_Y - 16}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
        out.append(insulator(ix, ARM_Y + 3, 0.9))
    for i, dx in enumerate(F3):
        out.append(do_fuse(angles[i], dx, hot=(hot == i)))
    return out


def field_card(kind):
    x = 40
    if kind == 'lbt':
        out = field_stage()
        tip = ring_at(0, F3[1])
        hb = (x + 2, GY - 32)
        # The stick carries the load break tool; its hook is in the ring.
        L = math.hypot(tip[0] - hb[0], tip[1] - hb[1])
        back = lerp(hb, tip, 1 - 30 / L)
        out.append(worker(x, (hb, lerp(hb, back, 0.17)), look=10, head_face=-1,
                          props_back=rod(lerp(hb, back, -0.1), back, head='lbt')))
        out.append(arc_spark(top_at(0, F3[1])[0], top_at(0, F3[1])[1], 0.35))
    elif kind == 'three':
        # One fuse blew on a fault: all three phases are opened.
        out = field_stage((OPEN, OPEN, OPEN))
        fuse_pose(out, x, ring_at(OPEN, F3[2]))
    elif kind == 'plain':
        # A heavily loaded fuse yanked with the plain puller: a big arc; the
        # load break tool lies unused on the ground.
        a = -40
        out = field_stage((0, a, 0))
        out.append(long_arc(top_at(0, F3[1]), top_at(a, F3[1])))
        fuse_pose(out, x, ring_at(a, F3[1]), look=-18, head_face=None)
        out.append(f'<g transform="translate(120 {GY + 10}) rotate(-6)">{load_break_tool()}</g>')
    elif kind == 'one':
        # One fuse blown, the other two left in: he pushes the blown one
        # straight back in.
        out = field_stage((0, 0, OPEN))
        fuse_pose(out, x, ring_at(OPEN, F3[2]), look=-10, head_face=None)
        out.append(motion(x + 14, GY - 70, -120, 3))
        out.append(flash_at(top_at(0, F3[2]), 0.5, 14))
    elif kind == 'hot':
        # The top contact glows hot after closing; he turns his back on it.
        out = field_stage(hot=1)
        out.append(arc_spark(top_at(0, F3[1])[0] + 3, top_at(0, F3[1])[1] - 3, 0.45))
        hb = (x - 2, GY - 32)
        out.append(worker(x, (hb, (x - 8, GY - 40)), face=-1, look=4,
                          props_back=rod((x - 2, GY - 2), (x - 26, GY - 120))))
    return card_close(out)


CARDS = {
    'prep_shield': prep_card('shield'),
    'prep_goggles': prep_card('goggles'),
    'prep_no_eyes': prep_card('no_eyes'),
    'prep_wet': prep_card('wet'),
    'prep_cracked': prep_card('cracked'),
    'prep_branch': prep_card('branch'),
    'link_wrap': link_card('wrap'),
    'link_wipe': link_card('wipe'),
    'link_port': link_card('port'),
    'link_loose': link_card('loose'),
    'link_taut': link_card('taut'),
    'link_button': link_card('button'),
    'open_pull': open_card('pull'),
    'open_side': open_card('side'),
    'open_under': open_card('under'),
    'open_slow': open_card('slow'),
    'open_stare': open_card('stare'),
    'open_miss': open_card('miss'),
    'close_hinge': close_card('hinge'),
    'close_lock': close_card('lock'),
    'close_half': close_card('half'),
    'close_reopen': close_card('reopen'),
    'close_slow': close_card('slow'),
    'close_face': close_card('face'),
    'field_lbt': field_card('lbt'),
    'field_three': field_card('three'),
    'field_plain': field_card('plain'),
    'field_one': field_card('one'),
    'field_hot': field_card('hot'),
}

# Safe cards and traps per round (mirrors learn_board_pack44.dart).
ROUNDS = {
    'prep': (['prep_shield', 'prep_goggles'], ['prep_no_eyes', 'prep_wet', 'prep_cracked', 'prep_branch']),
    'link': (['link_wrap', 'link_wipe'], ['link_port', 'link_loose', 'link_taut', 'link_button']),
    'open': (['open_pull', 'open_side'], ['open_under', 'open_slow', 'open_stare', 'open_miss']),
    'close': (['close_hinge', 'close_lock'], ['close_half', 'close_reopen', 'close_slow', 'close_face']),
    'field': (['field_lbt', 'field_three'], ['field_plain', 'field_one', 'field_hot']),
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
