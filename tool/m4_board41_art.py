"""Picture cards for lesson 4.1 শেখা ("পিন বা ডিস্ক ইনসুলেটর বদলানো").

python -I tool/m4_board41_art.py .

Writes assets/game/art/m4_board41/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 4.1 and its film script only:
  1. prep: a valid PTW; the line switched off and earthed from BOTH sides;
     the right new insulator, tools and binding wire in the bag; the pole and
     cross-arm looked over before climbing (helmet + harness on the pole);
  2. hold (pin insulator): the old binding is opened and the conductor is
     held on a rope or other support so it does not drop or swing to the next
     phase; never held or pushed aside by hand (induced voltage — the myth);
  3. fit (pin insulator): the new insulator screwed tight on the pin; the
     conductor seated in the top groove and bound tight with NEW binding wire
     (never loose); old / rusty pins and nuts are changed too (pro tip);
  4. bypass (tension disc string): the pull is first taken off the string
     onto a come-along + turnbuckle or ratchet puller fixed on both sides of
     the string; never opened under full tension or pulled by body strength
     (the second myth: hundreds of kilos);
  5. disc: the new disc is fitted cap-to-pin with its split pin locked; the
     pull is put back on the string SLOWLY and only then are the tools taken
     off; a cracked or punctured disc is never put back (check both).

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
    print('usage: python -I tool/m4_board41_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board41')
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
COND = '#A9B4BC'
COND_D = '#6F7A82'
BIND = '#DCE3E8'
RUST = '#9A5A2A'
ROPE = '#C8A15A'
ROPE_D = '#9C7A3C'
EARTH = '#3E9B4F'
EARTH_Y = '#E8C830'
HARNESS = '#E8742A'
BAG = '#6B5B3E'
CRACK = '#1E2329'
TOOL = '#D8402F'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="disc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8C5A3A"/><stop offset="0.5" stop-color="#C08355"/><stop offset="1" stop-color="#7A4C30"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
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


def worker_kit(x, hands_world, face=1, look=0, point=(0, 0), kit=''):
    """worker() with extra kit (harness belt) drawn in his own scaled frame."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    feet = ((x - 7 * face, GY - 1), (x + 6 * face, GY - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, False, point)
    belt = f'<rect x="{f(x - 8)}" y="{GY - 35}" width="16" height="4" rx="1.5" fill="{HARNESS}"/>'
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}{belt}{kit}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>')


def motion(x, y, dx=0, dy=1, n=3, length=9):
    """Little white swish marks: something moving / jerking."""
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def turn_arrow(cx, cy, r, w=1.8):
    a0, a1 = math.radians(-160), math.radians(60)
    p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
    p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
    tx, ty = -math.sin(a1), math.cos(a1)
    nx, ny = -ty, tx
    hl = w * 2.4
    tip = (p1[0] + tx * hl, p1[1] + ty * hl)
    b1 = (p1[0] + nx * hl * 0.8, p1[1] + ny * hl * 0.8)
    b2 = (p1[0] - nx * hl * 0.8, p1[1] - ny * hl * 0.8)
    return (f'<path d="M{f(p0[0])} {f(p0[1])} A{f(r)} {f(r)} 0 1 1 {f(p1[0])} {f(p1[1])}" stroke="{MOVE}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(tip[0])} {f(tip[1])} L{f(b1[0])} {f(b1[1])} L{f(b2[0])} {f(b2[1])} Z" fill="{MOVE}"/>')


def arm(p0, p1, bare=False, w=12):
    """A forearm in the blue sleeve reaching in from the card edge; a black
    rubber glove (or a bare hand) at p1."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy) or 1
    cuff = (p1[0] - dx / n * 8, p1[1] - dy / n * 8)
    hand = SKIN if bare else GLOVE
    o = [f'<path d="M{f(p0[0])} {f(p0[1])} L{f(cuff[0])} {f(cuff[1])}" stroke="{SHIRT}" stroke-width="{w}" stroke-linecap="round"/>',
         f'<path d="M{f(p0[0])} {f(p0[1])} L{f(cuff[0])} {f(cuff[1])}" stroke="{SHIRT_D}" stroke-width="{w * 0.3}" stroke-linecap="round" opacity="0.6"/>',
         f'<path d="M{f(cuff[0])} {f(cuff[1])} L{f(p1[0])} {f(p1[1])}" stroke="{hand}" stroke-width="{w * 0.9}" stroke-linecap="round"/>',
         f'<circle cx="{f(p1[0])}" cy="{f(p1[1])}" r="{f(w * 0.55)}" fill="{hand}"/>']
    return ''.join(o)


def pliers(x, y, ang=-30):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})"><path d="M{f(x)} {f(y - 2)} L{f(x - 16)} {f(y - 3)} M{f(x)} {f(y + 2)} L{f(x - 16)} {f(y + 3)}" '
            f'stroke="{TOOL}" stroke-width="3" stroke-linecap="round"/><path d="M{f(x - 16)} {f(y - 2)} L{f(x - 24)} {f(y)} L{f(x - 16)} {f(y + 2)} Z" fill="url(#steel)"/></g>')


def spanner(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 2.2)}" width="26" height="4.4" rx="1.6" fill="url(#steel)"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} L{f(x + 4)} {f(y - 6)} L{f(x + 4)} {f(y - 2)} L{f(x + 1)} {f(y - 2)} L{f(x + 1)} {f(y + 2)} '
            f'L{f(x + 4)} {f(y + 2)} L{f(x + 4)} {f(y + 6)} L{f(x - 2)} {f(y + 6)} Z" fill="url(#steel)"/></g>')


def crack(x, y, s=1.0):
    return (f'<path d="M{f(x)} {f(y)} l{f(3 * s)} {f(5 * s)} l{f(-4 * s)} {f(4 * s)} l{f(4 * s)} {f(6 * s)} l{f(-2 * s)} {f(5 * s)}" '
            f'stroke="{CRACK}" stroke-width="{f(1.4 * s)}" fill="none" stroke-linejoin="round"/>')


def pin_insulator(x, yb, tilt=0, cracked=False, rusty=False, s=1.0):
    """A pin insulator standing on the cross-arm top (yb); its top groove is
    at (x, yb - 44 s)."""
    pin = RUST if rusty else None
    o = []
    if rusty:
        o.append(f'<rect x="{f(x - 3 * s)}" y="{f(yb - 16 * s)}" width="{f(6 * s)}" height="{f(16 * s)}" fill="{pin}"/>')
        o.append(f'<circle cx="{f(x - 1)}" cy="{f(yb - 5 * s)}" r="{f(1.6 * s)}" fill="{CRACK}" opacity="0.5"/>')
    else:
        o.append(f'<rect x="{f(x - 3 * s)}" y="{f(yb - 16 * s)}" width="{f(6 * s)}" height="{f(16 * s)}" fill="url(#steel)"/>')
    body = (f'<path d="M{f(x - 24 * s)} {f(yb - 14 * s)} L{f(x + 24 * s)} {f(yb - 14 * s)} L{f(x + 14 * s)} {f(yb - 24 * s)} L{f(x - 14 * s)} {f(yb - 24 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 19 * s)} {f(yb - 23 * s)} L{f(x + 19 * s)} {f(yb - 23 * s)} L{f(x + 10 * s)} {f(yb - 34 * s)} L{f(x - 10 * s)} {f(yb - 34 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 46 * s)} L{f(x + 3 * s)} {f(yb - 46 * s)} '
            f'L{f(x + 3 * s)} {f(yb - 42 * s)} L{f(x - 3 * s)} {f(yb - 42 * s)} L{f(x - 3 * s)} {f(yb - 46 * s)} L{f(x - 10 * s)} {f(yb - 46 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 10 * s)} {f(yb - 38 * s)} L{f(x + 10 * s)} {f(yb - 38 * s)}" stroke="{COND_D}" stroke-width="{f(0.8 * s)}" opacity="0.5"/>')
    if cracked:
        body += crack(x - 6 * s, yb - 44 * s, 1.2 * s) + crack(x + 8 * s, yb - 24 * s, 0.9 * s)
    if tilt:
        body = f'<g transform="rotate({tilt} {f(x)} {f(yb - 16 * s)})">{body}</g>'
    o.append(body)
    return ''.join(o)


def conductor_path(d, w=4.4):
    return (f'<path d="{d}" stroke="{COND_D}" stroke-width="{f(w + 1.4)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{COND}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{BIND}" stroke-width="{f(w * 0.25)}" fill="none" stroke-linecap="round" opacity="0.8"/>')


def binding(x, y, kind='new'):
    """Binding wire round the conductor on both sides of the top groove."""
    o = []
    if kind == 'new':
        for side in (-1, 1):
            for i in range(4):
                bx = x + side * (12 + i * 4)
                o.append(f'<path d="M{f(bx - 1)} {f(y - 4)} L{f(bx + 1)} {f(y + 4)}" stroke="{BIND}" stroke-width="1.8" stroke-linecap="round"/>')
                o.append(f'<path d="M{f(bx - 1)} {f(y - 4)} L{f(bx + 1)} {f(y + 4)}" stroke="{COND_D}" stroke-width="0.5"/>')
        o.append(f'<path d="M{f(x - 12)} {f(y + 3)} Q{f(x)} {f(y + 9)} {f(x + 12)} {f(y + 3)}" stroke="{BIND}" stroke-width="1.8" fill="none"/>')
    elif kind == 'old':
        for side in (-1, 1):
            for i in range(4):
                bx = x + side * (12 + i * 4)
                o.append(f'<path d="M{f(bx - 2)} {f(y - 4)} l2 3 l-1 2 l2 3" stroke="{RUST}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
        o.append(f'<path d="M{f(x - 12)} {f(y + 3)} l5 4 l3 -2 l5 3 l4 -3 l7 1" stroke="{RUST}" stroke-width="1.8" fill="none"/>')
    elif kind == 'loose':
        for side in (-1, 1):
            bx = x + side * 18
            o.append(f'<ellipse cx="{f(bx)}" cy="{f(y + 9)}" rx="7" ry="11" stroke="{BIND}" stroke-width="1.6" fill="none"/>')
            o.append(f'<path d="M{f(bx + side * 6)} {f(y + 4)} q{f(side * 8)} 14 {f(side * 2)} 24" stroke="{BIND}" stroke-width="1.6" fill="none"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — prep: the span seen from the side (wires run left-right).
# --------------------------------------------------------------------------

PX = 101          # the work pole's centre
WIRES = (40, 58, 63)


def span_stage(earth=(True, True), cracked=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # Pole, step bolts, top bracket and the cross-arm seen end on.
    out.append(f'<rect x="{PX - 5}" y="30" width="10" height="{GY - 30}" fill="url(#pole)"/>')
    for i in range(7):
        y = 86 + i * 16
        side = -1 if i % 2 else 1
        out.append(f'<path d="M{PX + side * 5} {y} l{side * 6} 0" stroke="{COND_D}" stroke-width="2.2" stroke-linecap="round"/>')
    if cracked:
        out.append(crack(PX - 2, 100, 1.6) + crack(PX + 1, 132, 1.2))
        out.append(f'<g transform="rotate(16 {PX} 64)"><rect x="{PX - 14}" y="62" width="28" height="7" rx="1.5" fill="url(#arm)"/></g>')
        out.append(crack(PX + 8, 62, 0.8))
    else:
        out.append(f'<rect x="{PX - 14}" y="62" width="28" height="7" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(PX + 8, 63, s=0.36) + pin_insulator(PX - 7, 63, s=0.36))
    out.append(pin_insulator(PX, 47, s=0.36))
    # Three conductors, gently sagging.
    for y in WIRES:
        out.append(conductor_path(f'M0 {y + 8} Q50 {y - 2} {PX} {y - 1} Q150 {y - 2} 200 {y + 8}', 2.2))
    for x, on in ((26, earth[0]), (174, earth[1])):
        if on:
            out.append(earth_set(x))
    return out


def wire_y(x, y):
    """Where a conductor (drawn as two quadratic curves) crosses x."""
    if x <= PX:
        t, (a, b, c) = x / PX, (y + 8, y - 2, y - 1)
    else:
        t, (a, b, c) = (x - PX) / (200 - PX), (y - 1, y - 2, y + 8)
    return (1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c


def earth_set(x):
    """A portable earth: a clamp on each conductor, a bar, the green-yellow
    lead down to a rod driven into the ground."""
    ys = [wire_y(x, y) for y in WIRES]
    o = [f'<path d="M{f(x)} {f(ys[0])} L{f(x)} {f(ys[-1] + 6)}" stroke="url(#steel)" stroke-width="3"/>']
    for y in ys:
        o.append(f'<rect x="{f(x - 3.5)}" y="{f(y - 3)}" width="7" height="6" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.6"/>')
    d = f'M{f(x)} {f(ys[-1] + 6)} Q{f(x + 10)} {f((ys[-1] + GY) / 2)} {f(x)} {GY - 4}'
    o.append(f'<path d="{d}" stroke="{EARTH}" stroke-width="2.6" fill="none"/>')
    o.append(f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="5 5"/>')
    o.append(f'<path d="M{f(x)} {GY - 6} L{f(x)} {GY + 12}" stroke="url(#steel)" stroke-width="3"/>')
    o.append(f'<rect x="{f(x - 3)}" y="{GY - 7}" width="6" height="4" rx="1" fill="{COND_D}"/>')
    return ''.join(o)


def tool_bag(x, y):
    """The canvas tool bag with a new insulator and binding wire peeking out."""
    return (pin_insulator(x + 4, y + 2, s=0.22)
            + f'<ellipse cx="{f(x - 3)}" cy="{f(y + 1)}" rx="4" ry="2" stroke="{BIND}" stroke-width="1.2" fill="none"/>'
            + f'<rect x="{f(x - 8)}" y="{f(y)}" width="16" height="13" rx="2.5" fill="{BAG}"/>'
            + f'<path d="M{f(x - 8)} {f(y + 4)} L{f(x + 8)} {f(y + 4)}" stroke="{CRACK}" stroke-width="0.8" opacity="0.5"/>')


def climber(bag=True):
    """A lineman half way up the pole: helmet, gloves, harness belt with its
    strap round the pole."""
    hip, sh, head = (88, 150), (91, 125), (94, 117)
    feet = ((90, 178), (96, 166))
    hands = ((PX - 2, 106), (PX - 2, 120))
    strap = (f'<path d="M93 146 Q{PX} 132 {PX + 8} 140" stroke="{HARNESS}" stroke-width="2.4" fill="none"/>'
             f'<path d="M{PX + 8} 140 Q{PX + 4} 150 93 150" stroke="{HARNESS}" stroke-width="2.4" fill="none" opacity="0.6"/>')
    belt = f'<rect x="80" y="144" width="16" height="4" rx="1.5" fill="{HARNESS}"/>'
    kit = tool_bag(78, 150) if bag else ''
    return strap + figure(hip, sh, head, feet, hands, 1, -16) + belt + kit


def prep_card(kind):
    if kind == 'both':
        out = span_stage((True, True))
        out.append(climber())
    elif kind == 'inspect':
        out = span_stage((True, True))
        out.append(tool_bag(PX + 18, GY - 13))
        out.append(worker_kit(60, ((52, 168), (78, 118)), face=1, look=-24, point=(0, 1)))
    elif kind == 'oneside':
        out = span_stage((True, False))
        out.append(climber())
    elif kind == 'noearth':
        out = span_stage((False, False))
        out.append(climber())
    elif kind == 'cracked':
        out = span_stage((True, True), cracked=True)
        out.append(climber())
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 2-3 — the pin insulator close up: pole at the left, the cross-arm
# along the bottom, the neighbouring phase on the pole-top bracket above.
# --------------------------------------------------------------------------

IX, IB = 112, 152        # the pin insulator's x and the cross-arm top
GROOVE = IB - 44
TOPW = 34                # the neighbouring phase


def pin_stage():
    out = card_open('sky')
    out.append('<rect x="16" y="0" width="24" height="220" fill="url(#pole)"/>')
    out.append(f'<rect x="0" y="{IB}" width="200" height="14" rx="2" fill="url(#arm)"/>')
    out.append(f'<path d="M28 {IB + 14} L60 {IB + 40}" stroke="url(#steel)" stroke-width="4"/>')
    # The pole-top bracket and the neighbouring phase above.
    out.append(f'<rect x="28" y="{TOPW + 30}" width="22" height="6" fill="url(#arm)"/>')
    out.append(pin_insulator(44, TOPW + 30, s=0.5))
    out.append(conductor_path(f'M0 {TOPW + 10} L200 {TOPW + 6}', 3.6))
    # A spare rope coil hung on the cross-arm.
    out.append(f'<ellipse cx="66" cy="{IB + 26}" rx="9" ry="12" stroke="{ROPE}" stroke-width="2.6" fill="none"/>'
               f'<ellipse cx="66" cy="{IB + 26}" rx="6" ry="9" stroke="{ROPE_D}" stroke-width="1.6" fill="none"/>'
               f'<path d="M66 {IB + 14} L66 {IB + 10}" stroke="{ROPE}" stroke-width="2.6"/>')
    return out


def rope_from_arm(cx, cy):
    """A rope sling tied at the pole bracket, round the conductor."""
    return (f'<path d="M40 {TOPW + 36} Q{f((40 + cx) / 2)} {f(cy - 8)} {f(cx)} {f(cy - 4)}" stroke="{ROPE}" stroke-width="2.4" fill="none"/>'
            f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="4" ry="5.5" stroke="{ROPE}" stroke-width="2.4" fill="none"/>'
            f'<path d="M36 {TOPW + 34} l8 4" stroke="{ROPE_D}" stroke-width="3" stroke-linecap="round"/>')


def rope_from_block(cx, cy):
    """A rope run over a block at the pole top and down to the ground."""
    bx, by = 52, 10
    return (f'<path d="M28 {by} L{bx} {by}" stroke="url(#steel)" stroke-width="3"/>'
            f'<circle cx="{bx}" cy="{by + 4}" r="5" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<path d="M{bx + 5} {by + 4} L{f(cx)} {f(cy - 5)}" stroke="{ROPE}" stroke-width="2.4"/>'
            f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="4" ry="5.5" stroke="{ROPE}" stroke-width="2.4" fill="none"/>'
            f'<path d="M{bx - 5} {by + 4} L{bx - 7} 220" stroke="{ROPE}" stroke-width="2.4"/>')


def hold_card(kind):
    out = pin_stage()
    out.append(pin_insulator(IX, IB, cracked=True))
    lift = GROOVE - 16
    if kind == 'arm':
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} {lift - 2} 200 {lift + 4}'))
        out.append(rope_from_arm(IX - 14, lift))
        out.append(arm((200, 196), (IX + 16, GROOVE + 4)))
        out.append(pliers(IX + 14, GROOVE + 2, -150))
    elif kind == 'block':
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} {lift - 2} 200 {lift + 4}'))
        out.append(rope_from_block(IX + 14, lift))
        out.append(arm((200, 196), (IX + 16, GROOVE + 4)))
        out.append(pliers(IX + 14, GROOVE + 2, -150))
    elif kind == 'bare':
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} {lift - 2} 200 {lift + 4}'))
        out.append(arm((200, 170), (IX + 14, lift + 1), bare=True))
    elif kind == 'near':
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} {TOPW - 30} 200 {lift + 4}'))
        out.append(motion(IX + 30, TOPW + 30, 0.4, -1))
        out.append(arm((200, 196), (IX + 16, GROOVE + 4)))
        out.append(pliers(IX + 14, GROOVE + 2, -150))
    elif kind == 'drop':
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} 290 200 {lift + 4}'))
        out.append(motion(IX + 26, IB + 30, 0, 1))
        out.append(arm((200, 196), (IX + 16, GROOVE + 4)))
        out.append(pliers(IX + 14, GROOVE + 2, -150))
    return card_close(out)


def fit_card(kind):
    out = pin_stage()
    seated = f'M0 {GROOVE + 5} Q{IX} {GROOVE - 1} 200 {GROOVE + 5}'
    if kind == 'bind':
        out.append(pin_insulator(IX, IB))
        out.append(conductor_path(seated))
        out.append(binding(IX, GROOVE + 2, 'new'))
        out.append(arm((200, 196), (IX + 34, GROOVE + 12)))
        out.append(pliers(IX + 32, GROOVE + 10, -150))
    elif kind == 'tight':
        lift = GROOVE - 16
        out.append(pin_insulator(IX, IB))
        out.append(conductor_path(f'M0 {lift + 4} Q{IX} {lift - 2} 200 {lift + 4}'))
        out.append(rope_from_arm(IX - 14, lift))
        out.append(spanner(IX + 4, IB - 8, 20))
        out.append(arm((200, 206), (IX + 30, IB - 2)))
        out.append(turn_arrow(IX, IB - 30, 30))
    elif kind == 'loose':
        out.append(pin_insulator(IX, IB))
        out.append(conductor_path(f'M0 {GROOVE + 3} Q{IX} {GROOVE - 8} 200 {GROOVE + 3}'))
        out.append(binding(IX, GROOVE - 2, 'loose'))
        out.append(motion(IX, GROOVE - 18, 1, 0, 2, 8))
        out.append(arm((200, 196), (IX + 34, GROOVE + 12)))
        out.append(pliers(IX + 32, GROOVE + 10, -150))
    elif kind == 'old':
        out.append(pin_insulator(IX, IB))
        out.append(conductor_path(seated))
        out.append(binding(IX, GROOVE + 2, 'old'))
        out.append(arm((200, 196), (IX + 34, GROOVE + 12)))
        out.append(pliers(IX + 32, GROOVE + 10, -150))
    elif kind == 'wobble':
        out.append(pin_insulator(IX, IB, tilt=14))
        out.append(conductor_path(f'M0 {GROOVE + 5} Q{IX + 10} {GROOVE + 1} 200 {GROOVE + 5}'))
        out.append(binding(IX + 10, GROOVE + 4, 'new'))
        out.append(motion(IX - 34, GROOVE + 20, -1, 0.3, 2, 8))
        out.append(spanner(IX + 4, IB - 8, 20))
        out.append(arm((200, 196), (IX + 34, GROOVE + 12)))
        out.append(pliers(IX + 32, GROOVE + 10, -150))
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 4-5 — the tension disc string close up: the cross-arm end at the
# left, four discs, the dead-end clamp, the conductor off to the right.
# --------------------------------------------------------------------------

SY = 118                 # the string's line
DISCS = (64, 84, 104, 124)
CLAMP = 136
GRIP = 180


def sy(x, sag):
    if x <= 44 or x >= 152:
        return SY
    return SY + sag * math.sin(math.pi * (x - 44) / (152 - 44))


def disc_unit(x, y, new=False, cracked=False, flip=False):
    fill = 'url(#porcelain)' if new else 'url(#disc)'
    o = [f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="5" ry="18" fill="{fill}" stroke="{COND_D}" stroke-width="0.6"/>',
         f'<rect x="{f(x - 9 if not flip else x + 3)}" y="{f(y - 4)}" width="6" height="8" rx="1.5" fill="url(#steel)"/>']
    if cracked:
        o.append(crack(x - 2, y - 15, 1.0))
        o.append(f'<ellipse cx="{f(x + 1)}" cy="{f(y + 8)}" rx="3" ry="5" fill="{CRACK}" opacity="0.55"/>')
    return ''.join(o)


def string_stage(sag=4, new_at=None, cracked_at=None, gap_at=None):
    out = card_open('sky')
    out.append('<rect x="4" y="0" width="22" height="220" fill="url(#pole)"/>')
    out.append(f'<rect x="0" y="{SY - 8}" width="46" height="14" rx="2" fill="url(#arm)"/>')
    out.append(f'<path d="M40 {SY - 2} L48 {SY}" stroke="url(#steel)" stroke-width="4" stroke-linecap="round"/>')
    out.append(f'<rect x="28" y="{SY - 16}" width="12" height="8" rx="1.5" fill="url(#steel)"/>')
    pts = [(48, SY)]
    for i, x in enumerate(DISCS):
        dx = 6 if gap_at == i else 0
        pts.append((x + dx, sy(x, sag)))
    pts.append((CLAMP, sy(CLAMP, sag)))
    out.append(f'<path d="M48 {SY} ' + ' '.join(f'L{f(x)} {f(y)}' for x, y in pts[1:]) + f' L152 {SY}" stroke="url(#steel)" stroke-width="2.4" fill="none"/>')
    for i, x in enumerate(DISCS):
        dx = 6 if gap_at == i else 0
        out.append(disc_unit(x + dx, sy(x, sag) + (8 if gap_at == i else 0), new=(new_at == i), cracked=(cracked_at == i)))
        if i > 0 and gap_at != i:
            # A split pin locking the link.
            out.append(f'<path d="M{f(x - 7)} {f(sy(x, sag) - 6)} l0 12 M{f(x - 7)} {f(sy(x, sag) + 6)} l2 3" stroke="{BIND}" stroke-width="1.2" stroke-linecap="round"/>')
    out.append(f'<path d="M{CLAMP} {f(sy(CLAMP, sag) - 5)} L152 {SY - 4} L152 {SY + 4} L{CLAMP} {f(sy(CLAMP, sag) + 5)} Z" fill="url(#steel)"/>')
    out.append(conductor_path(f'M150 {SY} Q176 {SY + 2} 200 {SY + 6}', 4))
    return out


def come_along(hooked=True, flying=False):
    """Grip on the conductor, a turnbuckle and chain back to the cross-arm."""
    gy = SY + 1
    o = [f'<rect x="{GRIP - 8}" y="{gy - 7}" width="16" height="12" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>',
         f'<path d="M{GRIP - 4} {gy - 7} L{GRIP - 10} {gy - 22}" stroke="{TOOL}" stroke-width="3" stroke-linecap="round"/>']
    if hooked:
        o.append(f'<path d="M{GRIP - 8} {gy - 3} L128 88" stroke="url(#steel)" stroke-width="2.4"/>')
        o.append(f'<rect x="88" y="83" width="40" height="9" rx="4" fill="none" stroke="url(#steel)" stroke-width="2.6"/>')
        o.append(f'<rect x="102" y="84" width="12" height="7" rx="2" fill="{TOOL}"/>')
        o.append(f'<path d="M88 88 L34 {SY - 16}" stroke="{COND_D}" stroke-width="2.4" stroke-dasharray="3 2"/>')
    elif flying:
        o.append(f'<path d="M{GRIP - 8} {gy - 3} Q150 60 120 40" stroke="url(#steel)" stroke-width="2.4" fill="none"/>')
        o.append(f'<rect x="96" y="30" width="30" height="9" rx="4" fill="none" stroke="url(#steel)" stroke-width="2.6" transform="rotate(-24 111 34)"/>')
        o.append(motion(100, 56, -1, -0.6))
    else:
        o.append(f'<path d="M{GRIP - 8} {gy - 3} Q170 160 160 196" stroke="url(#steel)" stroke-width="2.4" fill="none"/>')
        o.append(f'<rect x="150" y="190" width="9" height="28" rx="4" fill="none" stroke="url(#steel)" stroke-width="2.6"/>')
        o.append(f'<rect x="151" y="198" width="7" height="10" rx="2" fill="{TOOL}"/>')
    return ''.join(o)


def ratchet():
    """A ratchet puller: a strap from the cross-arm, the ratchet body with its
    handle, a grip on the conductor."""
    gy = SY + 1
    return (f'<rect x="{GRIP - 8}" y="{gy - 7}" width="16" height="12" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<path d="M{GRIP - 8} {gy - 3} L120 86" stroke="url(#steel)" stroke-width="2.4"/>'
            f'<path d="M34 {SY - 16} L90 86" stroke="{COND_D}" stroke-width="4"/>'
            f'<rect x="90" y="78" width="30" height="16" rx="3" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<path d="M105 80 L96 56" stroke="{TOOL}" stroke-width="4" stroke-linecap="round"/>'
            f'<circle cx="105" cy="86" r="3" fill="{COND_D}"/>')


def bypass_card(kind):
    if kind == 'comealong':
        out = string_stage(sag=6)
        out.append(come_along())
    elif kind == 'ratchet':
        out = string_stage(sag=6)
        out.append(ratchet())
    elif kind == 'nobypass':
        out = string_stage(sag=0)
        out.append(arm((150, 220), (82, SY + 14)))
        out.append(pliers(80, SY + 8, -100))
    elif kind == 'muscle':
        out = string_stage(sag=0)
        out.append(arm((200, 176), (168, SY + 2)))
        out.append(arm((200, 150), (186, SY + 4)))
        out.append(motion(160, SY + 24, 1, 0.5, 3, 8))
    elif kind == 'half':
        out = string_stage(sag=0)
        out.append(come_along(hooked=False))
        out.append(arm((130, 220), (82, SY + 14)))
        out.append(pliers(80, SY + 8, -100))
    return card_close(out)


def disc_card(kind):
    if kind == 'capfit':
        out = string_stage(sag=6, new_at=2)
        out.append(come_along())
        out.append(arm((150, 220), (98, SY + 22)))
        out.append(pliers(96, SY + 16, -100))
    elif kind == 'release':
        out = string_stage(sag=2, new_at=2)
        out.append(come_along())
        out.append(arm((130, 40), (110, 78)))
        out.append(turn_arrow(108, 88, 14))
    elif kind == 'nosplit':
        out = string_stage(sag=6, new_at=2, gap_at=2)
        out.append(come_along())
        # The split pin left out: it falls away from the open link.
        out.append(f'<path d="M96 {SY + 34} l0 9 l2 3" stroke="{BIND}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
        out.append(motion(97, SY + 52, 0, 1, 2, 7))
        out.append(arm((170, 220), (130, SY + 40)))
        out.append(pliers(128, SY + 34, -100))
    elif kind == 'yank':
        out = string_stage(sag=0, new_at=2)
        out.append(come_along(hooked=False, flying=True))
        out.append(arm((130, 0), (124, 30)))
        out.append(motion(186, SY - 16, 0, -1))
    elif kind == 'cracked':
        out = string_stage(sag=6, cracked_at=2)
        out.append(come_along())
        out.append(arm((150, 220), (98, SY + 22)))
        out.append(pliers(96, SY + 16, -100))
    return card_close(out)


CARDS = {
    'prep_both': prep_card('both'),
    'prep_inspect': prep_card('inspect'),
    'prep_oneside': prep_card('oneside'),
    'prep_noearth': prep_card('noearth'),
    'prep_cracked': prep_card('cracked'),
    'hold_arm': hold_card('arm'),
    'hold_block': hold_card('block'),
    'hold_bare': hold_card('bare'),
    'hold_near': hold_card('near'),
    'hold_drop': hold_card('drop'),
    'fit_bind': fit_card('bind'),
    'fit_tight': fit_card('tight'),
    'fit_loose': fit_card('loose'),
    'fit_old': fit_card('old'),
    'fit_wobble': fit_card('wobble'),
    'bypass_comealong': bypass_card('comealong'),
    'bypass_ratchet': bypass_card('ratchet'),
    'bypass_nobypass': bypass_card('nobypass'),
    'bypass_muscle': bypass_card('muscle'),
    'bypass_half': bypass_card('half'),
    'disc_capfit': disc_card('capfit'),
    'disc_release': disc_card('release'),
    'disc_nosplit': disc_card('nosplit'),
    'disc_yank': disc_card('yank'),
    'disc_cracked': disc_card('cracked'),
}

# Safe cards and traps per round (mirrors learn_board_pack41.dart).
ROUNDS = {
    'prep': (['prep_both', 'prep_inspect'], ['prep_oneside', 'prep_noearth', 'prep_cracked']),
    'hold': (['hold_arm', 'hold_block'], ['hold_bare', 'hold_near', 'hold_drop']),
    'fit': (['fit_bind', 'fit_tight'], ['fit_loose', 'fit_old', 'fit_wobble']),
    'bypass': (['bypass_comealong', 'bypass_ratchet'], ['bypass_nobypass', 'bypass_muscle', 'bypass_half']),
    'disc': (['disc_capfit', 'disc_release'], ['disc_nosplit', 'disc_yank', 'disc_cracked']),
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
