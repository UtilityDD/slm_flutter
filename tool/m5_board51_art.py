"""Picture cards for lesson 5.1 শেখা ("'লাইন ট্রিপ করেছে'—প্রথম কাজ কী?").

python -I tool/m5_board51_art.py .

Writes assets/game/art/m5_board51/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 5.1 only (and the Module 5 rulings):
  1. call (the depot at dusk, the phone rings): before going out, ask the
     operator about the trip (relay flag: instant? overcurrent or earth
     fault?), the weather at the time, and have the control room look up the
     feeder's old logbook. Traps: the van races off while the phone still
     rings; asking for one more charge after the breaker would not hold
     (ruling M5-1); waving the operator off;
  2. treat (a tripped, dark span): the tripped line is treated as live —
     stand back; a valid PTW, isolate and earth; personal earth before any
     hand on the line. Traps: a bare hand on the dark line; climbing on the
     guess that the recloser will not try again; a crew starting at the
     pole foot on "it's off anyway". The unused earth coil lies on the
     ground in the three traps and in "live" (not on yet, so they stand
     back); "guess" and two safe cards keep their figures on the ground;
  3. van (loading at the depot): torch and binoculars in the van; discharge
     rod and PPE in the van; the crew briefed on the facts and the plan
     beside the van, its engine running. Traps: shutting the van up with
     the torch and binoculars still on the shelf; driving off with the rod
     left leaning on the wall; driving off alone with the plan in one head.
     The parked van (doors open) and the van leaving are each drawn on safe
     cards and on traps;
  4. storm (wind and rain, earth-fault relay): start on the wooded section;
     look for a broken branch or a punctured insulator. Traps: starting
     across the open fields; hunting a melted jumper (a clear-day overcurrent
     clue); walking the whole feeder pole by pole;
  5. lockout (several recloses on a windy day, then the final trip):
     probably a temporary fault (wires clashing) turned permanent; LOCKOUT
     lamp lit, control informed before the hunt, a PTW before any hand on
     the line (ruling M5-3). Traps: a hand on the locked-out line; relaxing
     as if the fault had cleared itself (under the same swinging wires as
     "clash"); phoning for one more charge.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. Layout variants (the van parked or leaving, a figure on
the pole or on the ground, the unused earth coil, the swinging wires) are
tagged in each SVG as <!-- look:NAME -->; every look a safe card has must be
on a trap in the same hand, so no stage layout marks the safe card.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board51_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board51')
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
EARTH = '#3E9B4F'
EARTH_Y = '#E8C830'
HARNESS = '#E8742A'
TOOL = '#D8402F'
MOVE = '#FFFFFF'
PAPER = '#F7F3E6'
BOOK = '#8B5A2B'
DESK = '#6E5034'
CLOUD = '#8C99A6'
WARM = '#F2C86A'
GLASS = '#4F6578'
VAN_IN = '#26303C'
TRUNK = '#5A3D28'
RAIN = '#C9D7E3'
FOOT = '#2C3A26'
LAMP = '#E5483B'
LAMP_OFF = '#59636B'
ROOF = '#7E4636'
ROD = '#E8C830'

DEFS = """<defs>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F3D5E"/><stop offset="0.65" stop-color="#8E6E7A"/><stop offset="1" stop-color="#E2A272"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#86A9C4"/><stop offset="1" stop-color="#D8E4EA"/></linearGradient>
  <linearGradient id="storm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#323C48"/><stop offset="1" stop-color="#6F7C88"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="field" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4F6B3E"/><stop offset="1" stop-color="#3A5230"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A877D"/><stop offset="1" stop-color="#6B685F"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#B9A68A"/><stop offset="1" stop-color="#9C8A70"/></linearGradient>
  <linearGradient id="van" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F1F4F6"/><stop offset="1" stop-color="#C3CBD1"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="beam" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#FFF4C2" stop-opacity="0.85"/><stop offset="1" stop-color="#FFF4C2" stop-opacity="0"/></linearGradient>
  <radialGradient id="tree" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#4E8A45"/><stop offset="1" stop-color="#2C5A2A"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="lamp" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF8A7A" stop-opacity="0.9"/><stop offset="1" stop-color="#E5483B" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def look_tag(name):
    """A layout tag read by the fairness check (and the board test)."""
    return f'<!-- look:{name} -->'


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The worker (from tool/m4_board41_art.py): one figure, any pose.
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


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves (bare = no gloves). [front] is drawn between the front arm and
    the front hand (a tool held in that hand)."""
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
    g.append(front)
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the standing worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0), front='', gy=GY):
    """A standing worker at x (feet on gy), scaled S about his feet; the hands
    and [front] are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    front_local = f'<g transform="translate({f(x)} {f(gy)}) scale({1 / S:.4f}) translate({f(-x)} {f(-gy)})">{front}</g>' if front else ''
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point, front_local)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def head_of(x, face, gy=GY):
    """Where worker()'s head sits in card coordinates."""
    return (x + 3 * face * S, gy - 64 * S)


def sitter(x, face=1, hands=None, front=''):
    """A worker sitting on a crate (unscaled figure, a little larger)."""
    gy = GY
    hip = (x, gy - 22)
    sh = (x + 2 * face, gy - 46)
    head = (x + 4 * face, gy - 54)
    feet = ((x + 14 * face, gy - 1), (x + 20 * face, gy - 1))
    hands = hands or ((x + 12 * face, gy - 30), (x + 14 * face, gy - 34))
    crate = (f'<rect x="{f(x - 12)}" y="{gy - 20}" width="24" height="20" rx="2" fill="{DESK}"/>'
             f'<path d="M{f(x - 12)} {gy - 10} L{f(x + 12)} {gy - 10}" stroke="{BOOK}" stroke-width="1.4"/>')
    fig = crate + figure(hip, sh, head, feet, hands, face, 6, False, (0, 0), front)
    return f'<g transform="translate({f(x)} {gy}) scale({S}) translate({f(-x)} -{gy})">{fig}</g>'


def climber_at(px, up=0, bare=False, hands=None, look=-16, front=''):
    """A lineman on the left of a pole at px, facing it: helmet, harness belt
    with its strap round the pole. [up] lifts him (card px)."""
    hip, sh, head = (px - 13, 150 - up), (px - 10, 125 - up), (px - 7, 117 - up)
    feet = ((px - 11, 178 - up), (px - 5, 166 - up))
    hands = hands or ((px - 2, 106 - up), (px - 2, 120 - up))
    strap = (f'<path d="M{f(px - 8)} {f(146 - up)} Q{f(px)} {f(132 - up)} {f(px + 7)} {f(140 - up)}" stroke="{HARNESS}" stroke-width="2.4" fill="none"/>'
             f'<path d="M{f(px + 7)} {f(140 - up)} Q{f(px + 3)} {f(150 - up)} {f(px - 8)} {f(150 - up)}" stroke="{HARNESS}" stroke-width="2.4" fill="none" opacity="0.6"/>')
    belt = f'<rect x="{f(px - 21)}" y="{f(144 - up)}" width="16" height="4" rx="1.5" fill="{HARNESS}"/>'
    return look_tag('climber') + strap + figure(hip, sh, head, feet, hands, 1, look, bare, (0, 0), front) + belt


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>')


def motion(x, y, dx=0, dy=1, n=3, length=9, color=MOVE):
    """Little swish marks: something moving / jerking."""
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{color}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def turn_arrow(cx, cy, r, w=1.8, color=MOVE, a0=-160, a1=60):
    a0, a1 = math.radians(a0), math.radians(a1)
    p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
    p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
    tx, ty = -math.sin(a1), math.cos(a1)
    nx, ny = -ty, tx
    hl = w * 2.4
    tip = (p1[0] + tx * hl, p1[1] + ty * hl)
    b1 = (p1[0] + nx * hl * 0.8, p1[1] + ny * hl * 0.8)
    b2 = (p1[0] - nx * hl * 0.8, p1[1] - ny * hl * 0.8)
    return (f'<path d="M{f(p0[0])} {f(p0[1])} A{f(r)} {f(r)} 0 1 1 {f(p1[0])} {f(p1[1])}" stroke="{color}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(tip[0])} {f(tip[1])} L{f(b1[0])} {f(b1[1])} L{f(b2[0])} {f(b2[1])} Z" fill="{color}"/>')


def conductor_path(d, w=2.2):
    return (f'<path d="{d}" stroke="{COND_D}" stroke-width="{f(w + 1.4)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{COND}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>')


def pin_insulator(x, yb, s=0.36):
    return (f'<rect x="{f(x - 3 * s)}" y="{f(yb - 16 * s)}" width="{f(6 * s)}" height="{f(16 * s)}" fill="url(#steel)"/>'
            f'<path d="M{f(x - 24 * s)} {f(yb - 14 * s)} L{f(x + 24 * s)} {f(yb - 14 * s)} L{f(x + 14 * s)} {f(yb - 24 * s)} L{f(x - 14 * s)} {f(yb - 24 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 19 * s)} {f(yb - 23 * s)} L{f(x + 19 * s)} {f(yb - 23 * s)} L{f(x + 10 * s)} {f(yb - 34 * s)} L{f(x - 10 * s)} {f(yb - 34 * s)} Z" fill="url(#porcelain)"/>'
            f'<rect x="{f(x - 10 * s)}" y="{f(yb - 46 * s)}" width="{f(20 * s)}" height="{f(13 * s)}" fill="url(#porcelain)"/>')


def bubble(x, y, w, h, tail):
    """A speech bubble (paper) with a tail to [tail]."""
    cx = x + w / 2
    return (f'<path d="M{f(cx - 7)} {f(y + h - 1)} L{f(tail[0])} {f(tail[1])} L{f(cx + 7)} {f(y + h - 1)} Z" fill="{PAPER}" stroke="{COND_D}" stroke-width="1"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="10" fill="{PAPER}" stroke="{COND_D}" stroke-width="1"/>'
            f'<path d="M{f(cx - 6)} {f(y + h - 1)} L{f(cx + 6)} {f(y + h - 1)}" stroke="{PAPER}" stroke-width="2.4"/>')


def thought(x, y, w, h, tail):
    """A thought cloud: the bubble with two little dots to [tail]."""
    mx, my = (x + w / 2 + tail[0]) / 2, (y + h + tail[1]) / 2
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(h / 2)}" fill="{PAPER}" stroke="{COND_D}" stroke-width="1"/>'
            f'<circle cx="{f(mx)}" cy="{f(my)}" r="3.4" fill="{PAPER}" stroke="{COND_D}" stroke-width="1"/>'
            f'<circle cx="{f(tail[0])}" cy="{f(tail[1])}" r="2" fill="{PAPER}" stroke="{COND_D}" stroke-width="1"/>')


def relay_icon(cx, cy):
    """A relay with its target flag dropped: grey case, a dial, a red flag."""
    return (f'<rect x="{f(cx - 17)}" y="{f(cy - 13)}" width="34" height="26" rx="3" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<circle cx="{f(cx - 6)}" cy="{f(cy - 1)}" r="7.5" fill="{PAPER}" stroke="{WIRE}" stroke-width="1"/>'
            f'<path d="M{f(cx - 6)} {f(cy - 1)} L{f(cx - 1)} {f(cy - 6)}" stroke="{WIRE}" stroke-width="1.4" stroke-linecap="round"/>'
            f'<path d="M{f(cx + 6)} {f(cy - 8)} L{f(cx + 14)} {f(cy - 4)} L{f(cx + 6)} {f(cy)} Z" fill="{TOOL}"/>'
            f'<path d="M{f(cx + 6)} {f(cy - 9)} L{f(cx + 6)} {f(cy + 9)}" stroke="{WIRE}" stroke-width="1.2"/>')


def weather_icon(cx, cy):
    """A storm cloud with a lightning bolt."""
    return (f'<circle cx="{f(cx - 8)}" cy="{f(cy - 2)}" r="8" fill="{CLOUD}"/>'
            f'<circle cx="{f(cx + 3)}" cy="{f(cy - 7)}" r="10" fill="{CLOUD}"/>'
            f'<circle cx="{f(cx + 12)}" cy="{f(cy - 1)}" r="7" fill="{CLOUD}"/>'
            f'<rect x="{f(cx - 15)}" y="{f(cy - 2)}" width="33" height="8" rx="4" fill="{CLOUD}"/>'
            f'<path d="M{f(cx + 2)} {f(cy + 3)} L{f(cx - 4)} {f(cy + 13)} L{f(cx + 1)} {f(cy + 13)} L{f(cx - 3)} {f(cy + 22)} L{f(cx + 8)} {f(cy + 9)} L{f(cx + 3)} {f(cy + 9)} L{f(cx + 7)} {f(cy + 3)} Z" fill="{HELMET}"/>')


def book_icon(cx, cy, s=1.0):
    """An open logbook: brown cover, two ruled pages."""
    lines = ''.join(
        f'<path d="M{f(cx + side * 3 * s)} {f(cy - 6 * s + i * 4 * s)} l{f(side * 11 * s)} 0"/>'
        for side in (-1, 1) for i in range(4))
    return (f'<path d="M{f(cx - 18 * s)} {f(cy - 11 * s)} L{f(cx + 18 * s)} {f(cy - 11 * s)} L{f(cx + 18 * s)} {f(cy + 11 * s)} L{f(cx - 18 * s)} {f(cy + 11 * s)} Z" fill="{BOOK}"/>'
            f'<path d="M{f(cx - 16 * s)} {f(cy - 10 * s)} Q{f(cx - 8 * s)} {f(cy - 12 * s)} {f(cx)} {f(cy - 9 * s)} L{f(cx)} {f(cy + 9 * s)} Q{f(cx - 8 * s)} {f(cy + 7 * s)} {f(cx - 16 * s)} {f(cy + 9 * s)} Z" fill="{PAPER}"/>'
            f'<path d="M{f(cx + 16 * s)} {f(cy - 10 * s)} Q{f(cx + 8 * s)} {f(cy - 12 * s)} {f(cx)} {f(cy - 9 * s)} L{f(cx)} {f(cy + 9 * s)} Q{f(cx + 8 * s)} {f(cy + 7 * s)} {f(cx + 16 * s)} {f(cy + 9 * s)} Z" fill="{PAPER}"/>'
            f'<g stroke="{COND_D}" stroke-width="{f(0.8 * s)}">{lines}</g>')


def breaker_icon(cx, cy):
    """A breaker being pushed ON again: a case, the red handle thrown up, an
    up arrow beside it, a flash at the contacts."""
    return (f'<rect x="{f(cx - 13)}" y="{f(cy - 14)}" width="26" height="28" rx="3" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<rect x="{f(cx - 4)}" y="{f(cy - 6)}" width="8" height="14" rx="2" fill="{WIRE}"/>'
            f'<path d="M{f(cx)} {f(cy + 2)} L{f(cx)} {f(cy - 10)}" stroke="{TOOL}" stroke-width="4" stroke-linecap="round"/>'
            f'<path d="M{f(cx + 21)} {f(cy + 10)} L{f(cx + 21)} {f(cy - 8)} M{f(cx + 16)} {f(cy - 3)} L{f(cx + 21)} {f(cy - 9)} L{f(cx + 26)} {f(cy - 3)}" stroke="{WIRE}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="M{f(cx - 22)} {f(cy - 9)} l4 5 l-3 1 l5 6" stroke="{HELMET_D}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')


def phone_hand(p, face=1):
    """A mobile phone held to the ear at p."""
    x, y = p
    return f'<rect x="{f(x - 2.5)}" y="{f(y - 7)}" width="5" height="11" rx="1.5" fill="{WIRE}" transform="rotate({-14 * face} {f(x)} {f(y)})"/>'


def sheet(x, y, ang=0, s=1.0):
    """A permit sheet (paper, three ruled lines, a signature stroke)."""
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<rect x="{f(x - 6 * s)}" y="{f(y - 8 * s)}" width="{f(12 * s)}" height="{f(16 * s)}" rx="1" fill="{PAPER}" stroke="{COND_D}" stroke-width="0.6"/>'
            f'<path d="M{f(x - 4 * s)} {f(y - 4 * s)} l{f(8 * s)} 0 M{f(x - 4 * s)} {f(y - 1 * s)} l{f(8 * s)} 0 M{f(x - 4 * s)} {f(y + 2 * s)} l{f(6 * s)} 0" stroke="{COND_D}" stroke-width="0.7"/>'
            f'<path d="M{f(x - 3 * s)} {f(y + 5.5 * s)} q2 -2 3 0 q1 2 3 -1" stroke="{SHIRT}" stroke-width="0.8" fill="none"/>'
            '</g>')


def binoculars(x, y):
    return (f'<rect x="{f(x - 6)}" y="{f(y - 3.5)}" width="5" height="8" rx="1.6" fill="{WIRE}"/>'
            f'<rect x="{f(x + 1)}" y="{f(y - 3.5)}" width="5" height="8" rx="1.6" fill="{WIRE}"/>'
            f'<rect x="{f(x - 1.5)}" y="{f(y - 1)}" width="3" height="3" fill="{COND_D}"/>')


def torch(x, y, ang=0, beam=0):
    """A torch held at (x, y) pointing at angle [ang] (deg, 0 = right); a
    light beam [beam] px long."""
    o = [f'<g transform="rotate({ang} {f(x)} {f(y)})">']
    if beam:
        o.append(f'<path d="M{f(x + 8)} {f(y - 2)} L{f(x + 8 + beam)} {f(y - beam * 0.28)} L{f(x + 8 + beam)} {f(y + beam * 0.28)} L{f(x + 8)} {f(y + 2)} Z" fill="url(#beam)"/>')
    o.append(f'<rect x="{f(x - 6)}" y="{f(y - 2.2)}" width="12" height="4.4" rx="1.6" fill="{WIRE}"/>')
    o.append(f'<rect x="{f(x + 5)}" y="{f(y - 3.2)}" width="4" height="6.4" rx="1" fill="{HELMET}"/>')
    o.append('</g>')
    return ''.join(o)


def rod(x0, y0, x1, y1, w=3.2):
    """A discharge rod: yellow insulated pole with red bands, hook at (x1, y1)."""
    dx, dy = x1 - x0, y1 - y0
    bands = ''.join(
        f'<path d="M{f(x0 + dx * t)} {f(y0 + dy * t)} L{f(x0 + dx * (t + 0.04))} {f(y0 + dy * (t + 0.04))}" stroke="{TOOL}" stroke-width="{f(w + 0.6)}"/>'
        for t in (0.3, 0.55))
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{ROD}" stroke-width="{f(w)}" stroke-linecap="round"/>' + bands
            + f'<path d="M{f(x1)} {f(y1)} q{f(4)} {f(-6)} {f(-2)} {f(-9)}" stroke="url(#steel)" stroke-width="2" fill="none" stroke-linecap="round"/>')


def helmet_item(x, y):
    return (f'<path d="M{f(x - 8)} {f(y)} A8 8 0 0 1 {f(x + 8)} {f(y)} Z" fill="{HELMET}"/>'
            f'<rect x="{f(x - 10)}" y="{f(y - 1.5)}" width="20" height="2.6" rx="1.2" fill="{HELMET_D}"/>')


def gloves_item(x, y):
    return (f'<rect x="{f(x - 6)}" y="{f(y - 8)}" width="6" height="11" rx="2.6" fill="{GLOVE}"/>'
            f'<rect x="{f(x + 1)}" y="{f(y - 7)}" width="6" height="11" rx="2.6" fill="{GLOVE}"/>')


def earth_coil(x, y=GY + 6):
    """A portable earth set lying unused on the ground: the green-yellow lead
    coiled up, its clamps and spike beside it."""
    return (look_tag('coil') + f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="11" ry="4.5" stroke="{EARTH}" stroke-width="2.4" fill="none"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="11" ry="4.5" stroke="{EARTH_Y}" stroke-width="2.4" fill="none" stroke-dasharray="4 5"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y - 1)}" rx="7" ry="3" stroke="{EARTH}" stroke-width="2" fill="none"/>'
            f'<path d="M{f(x + 13)} {f(y + 4)} L{f(x + 30)} {f(y + 1)}" stroke="url(#steel)" stroke-width="2.6" stroke-linecap="round"/>'
            f'<rect x="{f(x - 22)}" y="{f(y - 2)}" width="7" height="5" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.5"/>')


def tree(x, y, s=1.0):
    return (f'<rect x="{f(x - 2.5 * s)}" y="{f(y - 20 * s)}" width="{f(5 * s)}" height="{f(20 * s)}" fill="{TRUNK}"/>'
            f'<circle cx="{f(x)}" cy="{f(y - 30 * s)}" r="{f(15 * s)}" fill="url(#tree)"/>'
            f'<circle cx="{f(x - 10 * s)}" cy="{f(y - 22 * s)}" r="{f(10 * s)}" fill="url(#tree)"/>'
            f'<circle cx="{f(x + 10 * s)}" cy="{f(y - 22 * s)}" r="{f(10 * s)}" fill="url(#tree)"/>')


def van(x, y=GY, doors=False, moving=False, driver=False):
    """The crew van side on, cab to the right: [doors] = rear doors open (the
    dark load space shows), [moving] = swish marks behind and a lit lamp."""
    o = []
    if moving:
        o.append(motion(x - 10, y - 26, -1, 0, 3, 12))
        o.append(f'<circle cx="{f(x - 6)}" cy="{f(y - 10)}" r="3.4" fill="{CLOUD}" opacity="0.8"/>'
                 f'<circle cx="{f(x - 13)}" cy="{f(y - 13)}" r="4.6" fill="{CLOUD}" opacity="0.6"/>')
    body = (f'<path d="M{f(x)} {f(y - 8)} L{f(x)} {f(y - 46)} Q{f(x)} {f(y - 50)} {f(x + 4)} {f(y - 50)} L{f(x + 58)} {f(y - 50)} '
            f'L{f(x + 74)} {f(y - 32)} L{f(x + 80)} {f(y - 30)} L{f(x + 80)} {f(y - 8)} Z" fill="url(#van)" stroke="{COND_D}" stroke-width="0.8"/>')
    o.append(body)
    o.append(f'<path d="M{f(x + 60)} {f(y - 46)} L{f(x + 71)} {f(y - 33)} L{f(x + 60)} {f(y - 33)} Z" fill="{GLASS}"/>')
    o.append(f'<rect x="{f(x + 6)}" y="{f(y - 44)}" width="18" height="12" rx="2" fill="{VAN_IN}"/>')
    o.append(f'<path d="M{f(x)} {f(y - 24)} L{f(x + 80)} {f(y - 24)}" stroke="{TOOL}" stroke-width="2.4"/>')
    o.append(f'<rect x="{f(x + 76)}" y="{f(y - 22)}" width="4" height="4" rx="1" fill="{HELMET}"/>')
    if driver:
        hx, hy = x + 64, y - 39
        o.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="4.5" fill="{SKIN}"/>'
                 f'<path d="M{f(hx - 5)} {f(hy - 1)} A5 5 0 0 1 {f(hx + 5)} {f(hy - 1)} Z" fill="{HELMET}"/>')
    if doors:
        o.append(f'<rect x="{f(x + 1)}" y="{f(y - 48)}" width="30" height="38" fill="{VAN_IN}"/>')
        o.append(f'<path d="M{f(x)} {f(y - 49)} L{f(x - 16)} {f(y - 44)} L{f(x - 16)} {f(y - 12)} L{f(x)} {f(y - 9)} Z" fill="url(#van)" stroke="{COND_D}" stroke-width="0.8"/>')
    for wx in (x + 16, x + 64):
        o.append(f'<circle cx="{f(wx)}" cy="{f(y - 7)}" r="8" fill="{BOOT}"/><circle cx="{f(wx)}" cy="{f(y - 7)}" r="3.4" fill="url(#steel)"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — call: the depot at dusk; a desk with the landline and the
# feeder logbook, the van in the yard, the worker on the phone.
# --------------------------------------------------------------------------

def depot_stage(van_part=True, van_kw=None):
    out = card_open('dusk')
    out.append(f'<circle cx="150" cy="30" r="12" fill="{CLOUD}" opacity="0.7"/><circle cx="166" cy="34" r="9" fill="{CLOUD}" opacity="0.7"/>')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#yard)"/>')
    out.append(f'<rect x="0" y="78" width="70" height="{GY - 78}" fill="url(#wall)"/>')
    out.append(f'<path d="M-4 80 L74 74" stroke="{ROOF}" stroke-width="6" stroke-linecap="round"/>')
    out.append(f'<rect x="12" y="96" width="22" height="18" rx="1.5" fill="{WARM}"/>'
               f'<path d="M23 96 L23 114 M12 105 L34 105" stroke="{BOOK}" stroke-width="1.4"/>')
    # The desk: the landline and the feeder logbook.
    out.append(f'<rect x="4" y="160" width="58" height="5" rx="1" fill="{DESK}"/>'
               f'<path d="M8 165 L8 {GY} M58 165 L58 {GY}" stroke="{DESK}" stroke-width="3"/>')
    out.append(book_icon(44, 154, 0.42))
    out.append(f'<rect x="12" y="153" width="16" height="7" rx="2" fill="{WIRE}"/>')
    if van_part:
        out.append(look_tag('leaving' if (van_kw or {}).get('moving') else 'parked'))
        out.append(van(132, **(van_kw or {})))
    return out


def phone_worker(x=96, away=False):
    """The worker at the desk end with a phone at his ear (or held away)."""
    face = -1 if away else 1
    hx, hy = head_of(x, face)
    if away:
        ear = (x + 22, hy + 10)
        return worker(x, ((x - 18, hy + 8), ear), face=face, look=10, point=(-1, 0)) + phone_hand(ear, -1)
    ear = (hx + 4 * face, hy + 3)
    return worker(x, ((x + 10, 160), ear), face=face, look=-4) + phone_hand(ear, face)


def call_card(kind):
    if kind == 'blind':
        out = depot_stage(van_kw={'moving': True, 'driver': True})
        # The landline still ringing on the desk.
        out.append(f'<g stroke="{MOVE}" stroke-width="1.6" fill="none" stroke-linecap="round">'
                   '<path d="M8 146 q-4 -6 0 -12"/><path d="M32 146 q4 -6 0 -12"/><path d="M4 148 q-6 -9 0 -18"/><path d="M36 148 q6 -9 0 -18"/></g>')
        out.append(f'<rect x="10" y="146" width="20" height="5" rx="2.4" fill="{WIRE}" transform="rotate(-12 20 148)"/>')
        out.append(f'<path d="M106 196 l-14 -2 M104 188 l-12 -3" stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round"/>')
        return card_close(out)
    if kind == 'ignore':
        out = depot_stage()
        out.append(phone_worker(96, away=True))
        # The operator still talking out of the held-away phone.
        hx, hy = head_of(96, -1)
        out.append(bubble(118, 52, 48, 34, (120, hy + 2)))
        out.append(relay_icon(142, 69))
        out.append(f'<g stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round"><path d="M76 108 l-8 -4"/><path d="M76 116 l-9 0"/></g>')
        return card_close(out)
    out = depot_stage()
    out.append(phone_worker(96))
    hx, hy = head_of(96, 1)
    out.append(bubble(66, 14, 76, 52, (hx + 2, hy - 10)))
    icon = {'trip': relay_icon(104, 40), 'weather': weather_icon(102, 38),
            'logbook': book_icon(104, 40), 'charge': breaker_icon(102, 40)}[kind]
    out.append(icon)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — treat: a tripped span by the village (houses dark), a recloser
# on the pole below the cross-arm.
# --------------------------------------------------------------------------

PX = 132
WIRES = (40, 58, 63)


def wire_y(x, y):
    if x <= PX:
        t, (a, b, c) = x / PX, (y + 8, y - 2, y - 1)
    else:
        t, (a, b, c) = (x - PX) / (200 - PX), (y - 1, y - 2, y + 8)
    return (1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c


def house(x, w, h):
    y = GY - h
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" fill="{PAPER}" opacity="0.85"/>'
            f'<path d="M{f(x - 3)} {f(y)} L{f(x + w / 2)} {f(y - 12)} L{f(x + w + 3)} {f(y)} Z" fill="{ROOF}"/>'
            f'<rect x="{f(x + w / 2 - 4)}" y="{f(y + 8)}" width="8" height="8" fill="{WIRE}"/>')


def recloser(x, y):
    return (f'<rect x="{f(x - 9)}" y="{f(y)}" width="18" height="16" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>'
            f'<rect x="{f(x - 6)}" y="{f(y - 5)}" width="3" height="5" fill="url(#porcelain)"/>'
            f'<rect x="{f(x + 3)}" y="{f(y - 5)}" width="3" height="5" fill="url(#porcelain)"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 9)}" r="2.2" fill="{LAMP_OFF}"/>')


def span_stage():
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(house(8, 26, 26) + house(170, 24, 22))
    out.append(f'<rect x="{PX - 5}" y="30" width="10" height="{GY - 30}" fill="url(#pole)"/>')
    for i in range(6):
        y = 100 + i * 16
        side = -1 if i % 2 else 1
        out.append(f'<path d="M{PX + side * 5} {y} l{side * 6} 0" stroke="{COND_D}" stroke-width="2.2" stroke-linecap="round"/>')
    out.append(f'<rect x="{PX - 14}" y="62" width="28" height="7" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(PX + 8, 63) + pin_insulator(PX - 7, 63) + pin_insulator(PX, 47))
    for y in WIRES:
        out.append(conductor_path(f'M0 {y + 8} Q66 {y - 2} {PX} {y - 1} Q166 {y - 2} 200 {y + 8}'))
    out.append(recloser(PX + 16, 76))
    return out


def earth_set(x):
    """A portable earth on the span: a clamp on each conductor, the bar, the
    green-yellow lead down to a spike in the ground."""
    ys = [wire_y(x, y) for y in WIRES]
    o = [f'<path d="M{f(x)} {f(ys[0])} L{f(x)} {f(ys[-1] + 6)}" stroke="url(#steel)" stroke-width="3"/>']
    for y in ys:
        o.append(f'<rect x="{f(x - 3.5)}" y="{f(y - 3)}" width="7" height="6" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.6"/>')
    d = f'M{f(x)} {f(ys[-1] + 6)} Q{f(x + 10)} {f((ys[-1] + GY) / 2)} {f(x)} {GY - 4}'
    o.append(f'<path d="{d}" stroke="{EARTH}" stroke-width="2.6" fill="none"/>')
    o.append(f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="5 5"/>')
    o.append(f'<path d="M{f(x)} {GY - 6} L{f(x)} {GY + 12}" stroke="url(#steel)" stroke-width="3"/>')
    return ''.join(o)


def treat_card(kind):
    out = span_stage()
    if kind == 'live':
        # Standing well back; one arm across the crewmate stepping forward.
        # The earth set is not on yet: it still lies coiled on the ground.
        out.append(look_tag('ground'))
        out.append(worker(78, ((88, 150), (100, 146)), face=1, look=-20))
        out.append(worker(52, ((44, 168), (84, 138)), face=1, look=-24, point=(0, 1)))
        out.append(earth_coil(110))
    elif kind == 'ptw':
        out.append(look_tag('ground'))
        out.append(earth_set(174))
        out.append(earth_set(30))
        out.append(worker(76, ((66, 168), (96, 140)), face=1, look=-22, front=sheet(98, 134, -10)))
    elif kind == 'personal':
        # Personal earth clamped on the conductor next to his hands.
        cy = wire_y(PX - 12, 58)
        lead = f'M{PX - 12} {f(cy + 3)} Q{PX - 40} 84 {PX - 20} 106'
        out.append(f'<path d="{lead}" stroke="{EARTH}" stroke-width="3" fill="none"/>'
                   f'<path d="{lead}" stroke="{EARTH_Y}" stroke-width="3" fill="none" stroke-dasharray="4 4"/>'
                   f'<rect x="{PX - 16}" y="{f(cy - 3)}" width="8" height="6" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.6"/>')
        out.append(climber_at(PX, up=40, hands=((PX - 4, 74), (PX - 4, 86)), look=-28))
        out.append(earth_set(30))
    elif kind == 'bare':
        cy = wire_y(PX - 12, 58)
        out.append(climber_at(PX, up=40, bare=True, hands=((PX - 4, 86), (PX - 13, cy + 1)), look=-30))
        out.append(earth_coil(62))
    elif kind == 'climb':
        out.append(climber_at(PX, up=0, look=-34))
        out.append(turn_arrow(PX + 16, 84, 14, 1.8))
        out.append(earth_coil(62))
    elif kind == 'guess':
        # The crew start at the pole foot, tools out, the earth set unused.
        out.append(look_tag('ground'))
        spanner = ('<g transform="rotate(-40 124 134)"><rect x="124" y="132" width="18" height="4" rx="1.5" fill="url(#steel)"/></g>')
        out.append(worker(110, ((120, 160), (124, 134)), face=1, look=-24, front=spanner))
        # The mate shrugs: arms out, palms up.
        out.append(worker(64, ((44, 146), (84, 146)), face=1, look=-10, point=(-1, 1)))
        out.append(earth_coil(26))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — van: loading at the depot at dusk; a pegboard on the wall.
# --------------------------------------------------------------------------

def yard_stage(doors=True, moving=False, driver=False):
    out = card_open('dusk')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#yard)"/>')
    out.append(f'<rect x="0" y="70" width="62" height="{GY - 70}" fill="url(#wall)"/>')
    out.append(f'<path d="M-4 72 L66 66" stroke="{ROOF}" stroke-width="6" stroke-linecap="round"/>')
    # Pegboard with a rope coil and a shelf.
    out.append(f'<rect x="6" y="90" width="48" height="40" rx="2" fill="{DESK}"/>'
               f'<rect x="6" y="128" width="48" height="4" fill="{BOOK}"/>'
               f'<ellipse cx="18" cy="106" rx="7" ry="9" stroke="{EARTH_Y}" stroke-width="2.4" fill="none"/>')
    vx = 104 if not moving else 118
    out.append(look_tag('leaving' if moving else 'parked'))
    out.append(van(vx, doors=doors, moving=moving, driver=driver))
    return out


def van_card(kind):
    if kind == 'torch':
        out = yard_stage(doors=True)
        out.append(worker(78, ((96, 162), (104, 150)), face=1, look=-6, front=torch(104, 150, 0) + binoculars(97, 163)))
    elif kind == 'rod':
        out = yard_stage(doors=True)
        out.append(helmet_item(112, 186) + gloves_item(124, 186))
        out.append(worker(76, ((88, 160), (98, 146)), face=1, look=-6, front=rod(64, 182, 112, 134)))
    elif kind == 'brief':
        # The van ready, engine running; the leader goes over the facts and
        # the plan with the crew beside it before they climb in.
        out = yard_stage(doors=False, moving=True, driver=True)
        out.append(worker(20, ((28, 160), (34, 162)), face=1, look=8))
        out.append(worker(46, ((54, 158), (60, 162)), face=1, look=8))
        out.append(worker(88, ((78, 150), (72, 140)), face=-1, look=10, front=sheet(72, 146, -8, 1.1)))
    elif kind == 'torch_left':
        # Shutting the van up while the torch and binoculars stay on the shelf.
        out = yard_stage(doors=True)
        out.append(torch(22, 124, 0) + binoculars(42, 124))
        out.append(worker(72, ((86, 158), (90, 146)), face=1, look=-6))
        out.append(motion(84, 136, 1, 0.3, 3, 8))
    elif kind == 'rod_left':
        out = yard_stage(doors=False, moving=True, driver=True)
        out.append(rod(30, GY - 1, 50, 96))
    elif kind == 'solo':
        out = yard_stage(doors=False, moving=True, driver=True)
        out.append(thought(140, 74, 44, 26, (182, 152)))
        out.append(f'<path d="M148 92 Q158 78 168 88 T180 82" stroke="{WIRE}" stroke-width="1.6" fill="none" stroke-dasharray="3 2"/>')
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="1.8" fill="{TOOL}"/>' for x, y in ((148, 92), (163, 84), (180, 82))))
        out.append(worker(76, ((86, 132), (68, 168)), face=1, look=-8, point=(1, 0)))
        out.append(worker(98, ((92, 166), (106, 166)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — storm: wind and rain at night; the feeder runs from a wooded
# stretch (left) out across open fields (right).
# --------------------------------------------------------------------------

LINE_Y = 70


def storm_stage():
    out = card_open('storm')
    out.append(f'<rect y="{GY - 40}" width="{W}" height="{H - GY + 40}" fill="url(#field)"/>')
    # The wooded stretch: trees grown up to the wires on the left.
    for x, s in ((6, 1.9), (36, 2.1), (66, 1.7), (88, 1.15)):
        out.append(tree(x, GY - 34, s))
    for x in (40, 110, 180):
        out.append(f'<rect x="{x - 2.5}" y="{LINE_Y - 4}" width="5" height="{GY - 40 - LINE_Y + 8}" fill="url(#pole)"/>')
        out.append(f'<rect x="{x - 9}" y="{LINE_Y - 2}" width="18" height="3" fill="url(#arm)"/>')
    out.append(conductor_path(f'M0 {LINE_Y + 4} Q20 {LINE_Y + 8} 40 {LINE_Y} Q75 {LINE_Y + 9} 110 {LINE_Y} Q145 {LINE_Y + 9} 180 {LINE_Y} Q190 {LINE_Y + 4} 200 {LINE_Y + 6}', 1.8))
    rain = ''.join(f'<path d="M{x} {y} l-5 12"/>' for x, y in
                   ((12, 18), (40, 40), (70, 12), (96, 34), (128, 16), (150, 46), (176, 22), (190, 60), (58, 94), (140, 100), (24, 120), (164, 128)))
    out.append(f'<g stroke="{RAIN}" stroke-width="1.2" opacity="0.7" stroke-linecap="round">{rain}</g>')
    out.append(motion(150, 30, -1, 0.2, 2, 14))
    return out


def lens(cx, cy, r, inner):
    return (f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="#323C48" opacity="0.92"/>'
            f'{inner}'
            f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" stroke="{MOVE}" stroke-width="2.4"/>')


def storm_card(kind):
    out = storm_stage()
    gy = GY - 6
    if kind == 'trees':
        out.append(worker(88, ((80, gy - 30), (100, gy - 70)), face=-1, look=-20, gy=gy,
                          front=torch(100, gy - 70, -150, 46)))
    elif kind == 'branch':
        # The broken branch across the line in the wood, seen in the lens.
        inner = (f'<path d="M58 68 L88 54" stroke="{COND}" stroke-width="2.6"/>'
                 f'<path d="M60 44 L86 76" stroke="{TRUNK}" stroke-width="5" stroke-linecap="round"/>'
                 f'<circle cx="64" cy="48" r="7" fill="url(#tree)"/><circle cx="82" cy="72" r="5" fill="url(#tree)"/>')
        out.append(lens(72, 60, 22, inner))
        out.append(f'<path d="M90 70 L104 {gy - 82}" stroke="{MOVE}" stroke-width="1.2" stroke-dasharray="3 3"/>')
        out.append(worker(108, ((100, gy - 68), (106, gy - 70)), face=-1, look=-26, gy=gy,
                          front=binoculars(104, gy - 72)))
    elif kind == 'field':
        out.append(worker(146, ((138, gy - 30), (156, gy - 66)), face=1, look=-20, gy=gy,
                          front=torch(156, gy - 66, -40, 46)))
    elif kind == 'jumper':
        inner = (f'<path d="M150 50 L170 50" stroke="url(#arm)" stroke-width="3"/>'
                 f'<path d="M152 50 Q160 70 168 50" stroke="{COND}" stroke-width="2.2" fill="none"/>'
                 f'<circle cx="160" cy="60" r="3" fill="{HARNESS}"/>')
        out.append(lens(176, 52, 20, inner.replace('150 50 L170', '166 46 L186').replace('152 50 Q160 70 168 50', '168 46 Q176 66 184 46').replace('cx="160" cy="60"', 'cx="176" cy="56"')))
        out.append(f'<path d="M172 72 L166 {gy - 82}" stroke="{MOVE}" stroke-width="1.2" stroke-dasharray="3 3"/>')
        out.append(worker(160, ((152, gy - 68), (158, gy - 70)), face=-1, look=-30, gy=gy,
                          front=binoculars(156, gy - 72)))
    elif kind == 'walk':
        steps = ''.join(f'<ellipse cx="{f(x)}" cy="{f(GY + 4 + (2 if i % 2 else -2))}" rx="2.6" ry="1.4"/>'
                        for i, x in enumerate(range(16, 168, 9)))
        out.append(f'<g fill="{FOOT}" opacity="0.8">{steps}</g>')
        out.append(worker(178, ((170, gy - 30), (186, gy - 40)), face=-1, look=8, gy=gy,
                          front=torch(186, gy - 40, 170, 30)))
        out.append(motion(196, gy - 40, 1, 0, 2, 6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — lockout: a windy day; the recloser with its lamps on the left
# pole (LOCKOUT lamp lit), the span to the right pole, the van parked.
# --------------------------------------------------------------------------

LX, RX = 28, 176


def lock_stage(clash=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    for x in (LX, RX):
        out.append(f'<rect x="{x - 5}" y="30" width="10" height="{GY - 30}" fill="url(#pole)"/>')
        out.append(f'<rect x="{x - 14}" y="44" width="28" height="6" rx="1.5" fill="url(#arm)"/>')
        out.append(pin_insulator(x - 8, 45, 0.3) + pin_insulator(x + 8, 45, 0.3))
    out.append(look_tag('clash' if clash else 'still'))
    if clash:
        out.append(conductor_path(f'M{LX - 8} 36 Q100 66 {RX - 8} 36'))
        out.append(conductor_path(f'M{LX + 8} 36 Q96 60 {RX + 8} 36'))
    else:
        out.append(conductor_path(f'M{LX - 8} 36 Q100 50 {RX - 8} 36'))
        out.append(conductor_path(f'M{LX + 8} 36 Q100 56 {RX + 8} 36'))
    # The recloser and its control box: the LOCKOUT lamp lit red.
    out.append(f'<rect x="{LX - 11}" y="64" width="22" height="16" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<rect x="{LX + 6}" y="104" width="18" height="26" rx="2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<circle cx="{LX + 15}" cy="112" r="9" fill="url(#lamp)"/><circle cx="{LX + 15}" cy="112" r="3" fill="{LAMP}"/>'
               f'<circle cx="{LX + 15}" cy="122" r="2.6" fill="{LAMP_OFF}"/>')
    out.append(motion(120, 20, 1, 0.1, 3, 12) + motion(60, 90, 1, 0.1, 2, 10))
    out.append(van(110))
    return out


def lock_card(kind):
    if kind == 'clash':
        out = lock_stage(clash=True)
        out.append(spark(98, 58, 0.8))
        out.append(f'<path d="M96 76 L84 {GY - 92}" stroke="{TOOL}" stroke-width="1.2" stroke-dasharray="3 3"/>')
        out.append(worker(80, ((74, GY - 82), (80, GY - 84)), face=1, look=-30, front=binoculars(78, GY - 86)))
    elif kind == 'ptw':
        out = lock_stage()
        out.append(worker(78, ((62, GY - 80), (90, GY - 58)), face=-1, look=-8, point=(1, 0),
                          front=sheet(92, GY - 64, -8, 1.1)))
    elif kind == 'touch':
        out = lock_stage()
        out.append(climber_at(RX, up=60, bare=True, hands=((RX - 4, 70), (RX - 12, 44)), look=-34))
    elif kind == 'tea':
        out = lock_stage(clash=True)
        cup = (f'<rect x="84" y="{GY - 40}" width="6" height="7" rx="1.2" fill="{PAPER}"/>'
               f'<path d="M86 {GY - 44} q2 -3 0 -6" stroke="{MOVE}" stroke-width="1" fill="none"/>')
        out.append(sitter(72, 1, hands=((84, GY - 36), (86, GY - 38)), front=cup))
    elif kind == 'charge':
        out = lock_stage()
        hx, hy = head_of(80, 1)
        ear = (hx + 4, hy + 3)
        out.append(worker(80, ((90, 160), ear), face=1, look=-4) + phone_hand(ear, 1))
        out.append(bubble(56, 50, 76, 44, (hx + 2, hy - 10)))
        out.append(breaker_icon(92, 72))
        # The flash of closing onto a standing fault.
        out.append(spark(72, 64, 0.45))
    return card_close(out)


CARDS = {
    'call_trip': call_card('trip'),
    'call_weather': call_card('weather'),
    'call_logbook': call_card('logbook'),
    'call_blind': call_card('blind'),
    'call_charge': call_card('charge'),
    'call_ignore': call_card('ignore'),
    'treat_live': treat_card('live'),
    'treat_ptw': treat_card('ptw'),
    'treat_personal': treat_card('personal'),
    'treat_bare': treat_card('bare'),
    'treat_climb': treat_card('climb'),
    'treat_guess': treat_card('guess'),
    'van_torch': van_card('torch'),
    'van_rod': van_card('rod'),
    'van_brief': van_card('brief'),
    'van_torch_left': van_card('torch_left'),
    'van_rod_left': van_card('rod_left'),
    'van_solo': van_card('solo'),
    'storm_trees': storm_card('trees'),
    'storm_branch': storm_card('branch'),
    'storm_field': storm_card('field'),
    'storm_jumper': storm_card('jumper'),
    'storm_walk': storm_card('walk'),
    'lockout_clash': lock_card('clash'),
    'lockout_ptw': lock_card('ptw'),
    'lockout_touch': lock_card('touch'),
    'lockout_tea': lock_card('tea'),
    'lockout_charge': lock_card('charge'),
}

# Safe cards and traps per round (mirrors learn_board_pack51.dart).
ROUNDS = {
    'call': (['call_trip', 'call_weather', 'call_logbook'], ['call_blind', 'call_charge', 'call_ignore']),
    'treat': (['treat_live', 'treat_ptw', 'treat_personal'], ['treat_bare', 'treat_climb', 'treat_guess']),
    'van': (['van_torch', 'van_rod', 'van_brief'], ['van_torch_left', 'van_rod_left', 'van_solo']),
    'storm': (['storm_trees', 'storm_branch'], ['storm_field', 'storm_jumper', 'storm_walk']),
    'lockout': (['lockout_clash', 'lockout_ptw'], ['lockout_touch', 'lockout_tea', 'lockout_charge']),
}
HAND = 4

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
_LOOK = re.compile(r'<!-- look:(\w+) -->')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    looks = {k: set(_LOOK.findall(v)) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
                lone = looks[s] - set().union(*(looks[t] for t in hand))
                if lone:
                    problems.append(f'{rnd}: {s} with {hand} has the look {sorted(lone)} alone')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
