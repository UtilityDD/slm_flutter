"""Picture cards for lesson 3.8 শেখা ("সার্ভিস কেবিল ও এনার্জি মিটার: শেষ সংযোগ").

python -I tool/m3_board38_art.py .

Writes assets/game/art/m3_board38/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 3.8 and its film script only:
  1. cable: the service cable runs from the pole to the house on a supporting
     (bearer / GI) wire so the cable itself carries no strain; on a new
     connection the insulation is checked for cuts;
  2. drip: a U-shaped drip loop before the cable enters the meter box stops
     rain water running down the cable into the meter;
  3. box: the meter box is a live panel — insulated tools, and the incoming
     supply made sure OFF; the company seal is left whole;
  4. fault: lights flickering / low voltage — a loose connection (it can heat
     up and start a fire); a cut neutral burns appliances; a cable rubbing on
     a branch loses its insulation;
  5. fast: a meter that "runs fast" — check the house load (an old fridge) and
     earth leakage first; be patient and polite with the customer.

Fairness (the playbook, section 4): every card in a round shares one set of
backdrops and colours; the script checks every hand the dealer can make (one
safe card + any three traps): each colour or gradient the safe card draws is
drawn by a trap in that hand, and the safe card's backdrop is a trap's too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board38_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board38')
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
CABLE = '#1E2329'
GI = '#9AA5AD'
TIE = '#E8E8E8'
COPPER = '#D98A3D'
WATER = '#5FB4EE'
LCD_ON = '#9BE37A'
FACE = '#1E2329'
HANDLE = '#D8402F'
METER = '#E8742A'
METER_D = '#B9561A'
RED = '#FF4B3E'
KURTA = '#8E5BA6'
KURTA_D = '#734889'
LUNGI = '#3E7F6A'
LUNGI_D = '#33695A'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="rain" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E7F8C"/><stop offset="1" stop-color="#A3B0B8"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E3D2AE"/><stop offset="1" stop-color="#CDB98F"/></linearGradient>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9DFCB"/><stop offset="1" stop-color="#D3C6AA"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9C8B73"/><stop offset="1" stop-color="#7F6F59"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA4AC"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#8E98A0"/></linearGradient>
  <linearGradient id="boxIn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2E363E"/><stop offset="1" stop-color="#434C55"/></linearGradient>
  <linearGradient id="meter" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2F4F6"/><stop offset="1" stop-color="#D3D9DE"/></linearGradient>
  <linearGradient id="fridge" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D7DCD6"/><stop offset="0.5" stop-color="#EEF1EC"/><stop offset="1" stop-color="#C3C9C2"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8C969E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="leaf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E9C4E"/><stop offset="1" stop-color="#3F7536"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8" stop-opacity="0.95"/><stop offset="1" stop-color="#FFF6C8" stop-opacity="0"/></radialGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A"/><stop offset="0.45" stop-color="#FF7A2E"/><stop offset="1" stop-color="#FF4B3E" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="smoke" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#6B6F73" stop-opacity="0.85"/><stop offset="1" stop-color="#6B6F73" stop-opacity="0"/></radialGradient>
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
# People (the worker copied from tool/m2_board28_art.py; the customer is the
# same figure in a kurta and lungi, bare-headed and bare-handed).
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


def _boot(p, face, col=BOOT):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{col}"/>'


def _hand(p, bare=False, point=0):
    x, y = p
    c = SKIN if bare else GLOVE
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), props_front='', civil=False):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves. civil = the customer: kurta and lungi, no helmet, bare hands."""
    shirt_b, shirt_f = (KURTA_D, KURTA) if civil else (SHIRT_D, SHIRT)
    leg_b, leg_f = (LUNGI_D, LUNGI) if civil else (PANTS_D, PANTS)
    bare = bare or civil
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face)
    kf = _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, leg_b, 7))
    g.append(_boot(fb, face, SKIN_D if civil else BOOT))
    g.append(_limb(hip, kf, ff, leg_f, 7))
    g.append(_boot(ff, face, SKIN_D if civil else BOOT))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, shirt_b, 5.4))
    g.append(_hand(hb, bare, point[0]))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    body = KURTA if civil else 'url(#shirt)'
    low = 8 if civil else 0
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py + low)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py + low)} Z" fill="{body}"/>')
    if not civil:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>']
    if civil:
        hd.append(f'<path d="M{f(hx - 7.4)} {f(hy)} A7.4 7.4 0 0 1 {f(hx + 7.4)} {f(hy)} Q{f(hx)} {f(hy - 3)} {f(hx - 7.4)} {f(hy)} Z" fill="{HAIR}"/>')
    else:
        hd += [f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
               f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    hd.append(f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, shirt_f, 5.4))
    g.append(props_front)
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0), civil=False, stride=0):
    """A standing figure at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates. stride > 0 = walking."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - (7 + stride) * face, gy - 1), (x + (6 + stride) * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point, civil=civil)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


def customer(x, hands_world, face=1, look=0):
    return worker(x, hands_world, face, look, civil=True)


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


def smoke(x, y, s=1.0):
    return ''.join(f'<circle cx="{f(x + dx * s)}" cy="{f(y - dy * s)}" r="{f(r * s)}" fill="url(#smoke)"/>'
                   for dx, dy, r in ((0, 0, 7), (5, 9, 8), (-2, 19, 9), (6, 28, 8)))


def drop(x, y, s=1.0):
    return (f'<path d="M{f(x)} {f(y - 4 * s)} Q{f(x + 3 * s)} {f(y + 0.5 * s)} {f(x)} {f(y + 2 * s)} '
            f'Q{f(x - 3 * s)} {f(y + 0.5 * s)} {f(x)} {f(y - 4 * s)} Z" fill="{WATER}"/>')


def rain():
    """Light rain streaks over the whole card."""
    o = ['<g stroke="#DCEAF4" stroke-width="1" stroke-linecap="round" opacity="0.55">']
    for i in range(26):
        x = (i * 37) % 210 - 4
        y = (i * 53) % 200 + 4
        o.append(f'<path d="M{x} {y} l-3 9"/>')
    o.append('</g>')
    return ''.join(o)


def screwdriver(x, y, insulated=True, ang=-35):
    """Tip at (x, y), handle up to the right."""
    shank = (f'<rect x="{f(x)}" y="{f(y - 0.9)}" width="13" height="1.8" fill="url(#steel)"/>')
    if insulated:
        sleeve = f'<rect x="{f(x + 2.5)}" y="{f(y - 1.4)}" width="10.5" height="2.8" rx="1" fill="{HANDLE}"/>'
        hand = f'<rect x="{f(x + 13)}" y="{f(y - 2.6)}" width="13" height="5.2" rx="2" fill="{HANDLE}"/>'
    else:
        sleeve = ''
        hand = f'<rect x="{f(x + 13)}" y="{f(y - 2.6)}" width="13" height="5.2" rx="2" fill="url(#steel)"/>'
    return f'<g transform="rotate({ang} {f(x)} {f(y)})">{shank}{sleeve}{hand}</g>'


def clamp_meter(x, y, s=1.0):
    """A handheld clamp meter, jaw centre at (x, y), body below."""
    return (f'<path d="M{f(x - 6 * s)} {f(y + 3 * s)} A6.5 6.5 0 1 1 {f(x + 6 * s)} {f(y + 3 * s)}" stroke="{METER}" stroke-width="{f(3 * s)}" fill="none"/>'
            f'<rect x="{f(x - 6 * s)}" y="{f(y + 3 * s)}" width="{f(12 * s)}" height="{f(20 * s)}" rx="{f(2.5 * s)}" fill="{METER}" stroke="{METER_D}" stroke-width="0.8"/>'
            f'<rect x="{f(x - 4 * s)}" y="{f(y + 6 * s)}" width="{f(8 * s)}" height="{f(5 * s)}" rx="1" fill="{LCD_ON}"/>')


def bulb(x, y, flicker=True):
    """A hanging bulb (the customer's light), flickering."""
    o = [f'<path d="M{x} 0 L{x} {y - 8}" stroke="{WIRE}" stroke-width="1.4"/>',
         f'<rect x="{x - 3}" y="{y - 9}" width="6" height="5" rx="1" fill="url(#steel)"/>',
         f'<circle cx="{x}" cy="{y}" r="16" fill="url(#glow)" opacity="0.6"/>',
         f'<circle cx="{x}" cy="{y}" r="6" fill="#FFE38A"/>']
    if flicker:
        o.append(f'<g stroke="#FFE38A" stroke-width="1.6" stroke-linecap="round" fill="none">'
                 f'<path d="M{x - 11} {y - 3} l-3 3 l3 3 l-3 3"/><path d="M{x + 11} {y - 3} l3 3 l-3 3 l3 3"/></g>')
    return ''.join(o)


# --------------------------------------------------------------------------
# The street stage: a pole on the left, the customer's house on the right;
# the drop cable runs from the pole to a hook on the house wall, then down
# through a drip loop into the meter box.
# --------------------------------------------------------------------------

POLE_PT = (34, 50)      # where the service line leaves the pole
HOOK = (132, 88)        # the hook on the house wall
MBOX = (140, 112)       # the small meter box on the house wall


def _quad(p0, c, p1, t):
    return ((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * c[0] + t * t * p1[0],
            (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * c[1] + t * t * p1[1])


def street(window_bulb=False):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # The pole and its LT crossarm.
    out.append(f'<rect x="22" y="22" width="9" height="{GY - 22}" fill="url(#pole)"/>')
    out.append('<rect x="6" y="34" width="44" height="5" fill="#6F7880"/>')
    for x in (12, 26, 44):
        out.append(f'<path d="M{x} 34 L{x} 28" stroke="{GI}" stroke-width="3"/>')
    out.append(f'<path d="M0 26 L200 22" stroke="{WIRE}" stroke-width="1.2" opacity="0.7"/>')
    # The house: wall, slab roof, a window.
    out.append(f'<rect x="128" y="76" width="80" height="{GY - 76}" fill="url(#house)"/>')
    out.append('<rect x="122" y="68" width="86" height="9" fill="#8C7A5C"/>')
    out.append('<rect x="168" y="96" width="24" height="26" rx="2" fill="url(#boxIn)"/>')
    if window_bulb:
        out.append('<circle cx="180" cy="106" r="10" fill="url(#glow)"/><circle cx="180" cy="106" r="3.4" fill="#FFE38A"/>')
    out.append(f'<rect x="164" y="150" width="26" height="{GY - 150}" rx="2" fill="#7A5C3E"/>')
    # The meter box on the wall, and the cable's last run: down, a U, up in.
    mx, my = MBOX
    out.append(f'<rect x="{mx}" y="{my}" width="20" height="24" rx="2" fill="url(#box)"/>')
    out.append(f'<rect x="{mx + 4}" y="{my + 4}" width="12" height="6" rx="1" fill="{LCD_ON}"/>')
    hx, hy = HOOK
    out.append(f'<path d="M{hx} {hy + 3} L{hx + 1} {my + 34} Q{hx + 2} {my + 42} {mx + 4} {my + 40} Q{mx + 7} {my + 38} {mx + 7} {my + 24}" '
               f'stroke="{CABLE}" stroke-width="3" fill="none"/>')
    return out


def hook(out, strained=False):
    hx, hy = HOOK
    out.append(f'<path d="M{hx - 4} {hy} L{hx + 2} {hy}" stroke="#6F7880" stroke-width="2.4"/>')
    out.append(f'<circle cx="{hx - 6}" cy="{hy}" r="3" fill="none" stroke="#6F7880" stroke-width="2"/>')
    if strained:
        out.append(f'<g stroke="{CABLE}" stroke-width="2.4" fill="none"><ellipse cx="{hx - 6}" cy="{hy}" rx="4.6" ry="2.4"/>'
                   f'<ellipse cx="{hx - 6}" cy="{hy + 2}" rx="4.6" ry="2.4"/></g>')
        out.append(f'<path d="M{hx - 14} {hy - 3} l3 2 l2 -2 l3 2" stroke="{COPPER}" stroke-width="1.8" fill="none"/>')


def span(out, bearer=True, sag=30, ties=True, cut=None, tight=False):
    """The service line from the pole to the house hook: a GI bearer wire
    with the cable tied under it, or the cable alone."""
    p0, p1 = POLE_PT, (HOOK[0] - 6, HOOK[1])
    c = ((p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + (2 if tight else sag))
    if bearer:
        out.append(f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(c[0])} {f(c[1])} {f(p1[0])} {f(p1[1])}" stroke="{GI}" stroke-width="1.6" fill="none"/>')
    cp0, cp1, cc = (p0[0], p0[1] + 3), (p1[0], p1[1] + 3), (c[0], c[1] + 3)
    out.append(f'<path d="M{f(cp0[0])} {f(cp0[1])} Q{f(cc[0])} {f(cc[1])} {f(cp1[0])} {f(cp1[1])}" stroke="{CABLE}" stroke-width="3" fill="none"/>')
    if bearer and ties:
        for i in range(1, 8):
            x, y = _quad(p0, c, p1, i / 8)
            out.append(f'<rect x="{f(x - 1)}" y="{f(y - 1)}" width="2" height="6" rx="0.8" fill="{TIE}"/>')
    if cut is not None:
        x, y = _quad(cp0, cc, cp1, cut)
        out.append(f'<rect x="{f(x - 5)}" y="{f(y - 1.6)}" width="10" height="3.2" fill="{COPPER}"/>')
        out.append(spark(x, y + 2, 0.55))
    return out


# --------------------------------------------------------------------------
# Round 1 — cable: the strain on the bearer wire, never on the cable.
# --------------------------------------------------------------------------

def cable_card(kind):
    out = street()
    if kind == 'span':
        span(out)
        hook(out)
        out.append(worker(70, ((62, 156), (86, 126)), face=1, look=-18, point=(0, 1)))
    elif kind == 'anchor':
        span(out, sag=34)
        hook(out)
        # The cable's slack loop below the hook, tied up to the bearer.
        hx, hy = HOOK
        out.append(f'<path d="M{hx - 16} {hy + 3} Q{hx - 10} {hy + 16} {hx - 4} {hy + 6}" stroke="{CABLE}" stroke-width="3" fill="none"/>')
        out.append(f'<rect x="{hx - 11}" y="{hy - 1}" width="2" height="6" rx="0.8" fill="{TIE}"/>')
        out.append(worker(92, ((84, 156), (108, 124)), face=1, look=-20, point=(0, 1)))
    elif kind == 'tight':
        span(out, bearer=False, tight=True)
        hook(out, strained=True)
        out.append(worker(70, ((62, 156), (86, 126)), face=1, look=-10, point=(0, 1)))
    elif kind == 'torn':
        span(out, cut=0.45)
        hook(out)
        out.append(worker(108, ((98, 160), (120, 160)), face=1, look=8, stride=3))
    elif kind == 'hook':
        span(out, bearer=False, sag=20)
        hook(out, strained=True)
        out.append(worker(92, ((84, 156), (108, 124)), face=1, look=-20, point=(0, 1)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — drip: the U loop before the box (close-up, in the rain).
# --------------------------------------------------------------------------

DB = (74, 64, 56, 74)     # the meter box (x, y, w, h)


def drip_stage(water_in=False):
    out = card_open('rain')
    out.append(f'<rect x="0" y="0" width="{W}" height="{GY}" fill="url(#house)" opacity="0.35"/>')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#floor)"/>')
    x, y, w, h = DB
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="url(#box)"/>')
    out.append(f'<rect x="{x + 8}" y="{y + 8}" width="{w - 16}" height="{h - 22}" rx="3" fill="url(#boxIn)"/>')
    out.append(f'<rect x="{x + 14}" y="{y + 14}" width="{w - 28}" height="34" rx="2" fill="url(#meter)"/>')
    out.append(f'<rect x="{x + 18}" y="{y + 18}" width="{w - 36}" height="10" rx="1" fill="{LCD_ON}"/>')
    for gx, gy in ((x + w / 2, y), (x + w / 2, y + h), (x, y + h / 2), (x + w, y + h / 2)):
        out.append(f'<rect x="{f(gx - 4)}" y="{f(gy - 3)}" width="8" height="6" rx="1.5" fill="{FACE}"/>')
    if water_in:
        for dx, dy in ((20, 54), (30, 58), (38, 52)):
            out.append(drop(x + dx, y + dy, 1.0))
        out.append(spark(x + 30, y + 44, 0.7))
    out.append(rain())
    return out


def cable_path(out, d):
    out.append(f'<path d="{d}" stroke="{CABLE}" stroke-width="4.4" fill="none" stroke-linecap="round"/>')


def drip_card(kind):
    x, y, w, h = DB
    bx, by = x + w / 2, y + h          # bottom gland
    if kind == 'loop':
        out = drip_stage()
        cable_path(out, f'M0 30 Q44 34 48 80 L48 168 Q48 190 {bx - 6} 186 Q{bx} 182 {bx} {by + 2}')
        for i in range(3):
            out.append(drop(68 + i * 2, 196 + i * 8 - 4, 1.1))
        out.append(worker(168, ((176, 158), (150, 138)), face=-1, look=8, point=(0, -1)))
    elif kind == 'side':
        out = drip_stage()
        cable_path(out, f'M200 26 Q160 30 160 84 L160 168 Q160 190 {bx + 10} 186 Q{bx} 182 {bx} {by + 2}')
        for i in range(3):
            out.append(drop(138 - i * 2, 196 + i * 8 - 4, 1.1))
        out.append(worker(34, ((24, 158), (54, 140)), face=1, look=8, point=(0, 1)))
    elif kind == 'top':
        out = drip_stage(water_in=True)
        cable_path(out, f'M{bx} 0 L{bx} {y + 2}')
        for i in range(3):
            out.append(drop(bx + 4, 16 + i * 14, 1.0))
        out.append(worker(168, ((176, 158), (150, 138)), face=-1, look=-6))
    elif kind == 'taut':
        out = drip_stage(water_in=True)
        cable_path(out, f'M0 28 L{x - 2} {y + h / 2}')
        for i in range(3):
            t = (i + 1) / 4
            out.append(drop(t * (x - 2), 28 + t * (y + h / 2 - 28) - 5, 1.0))
        out.append(worker(168, ((176, 158), (150, 138)), face=-1, look=-6))
    elif kind == 'hump':
        out = drip_stage(water_in=True)
        cable_path(out, f'M0 150 Q10 30 60 24 Q{bx} 18 {bx} {y + 2}')
        for i in range(3):
            out.append(drop(bx + 4, 30 + i * 11, 1.0))
        out.append(worker(168, ((176, 158), (150, 138)), face=-1, look=-6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — box: incoming OFF, insulated tools, the seal left whole.
# The open meter box on the left, the incoming switch beside it.
# --------------------------------------------------------------------------

MB = (14, 46, 72, 106)    # x, y, w, h of the open meter box
SW = (92, 92)             # the incoming switch box (x, y)
TERM_Y = 128
TERM_X = (28, 40, 52, 64)


def box_stage(on=False, seal='whole', cover=True, loose=False, hot=False, neutral_cut=False, bulb_light=False):
    out = card_open('house')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#floor)"/>')
    if bulb_light:
        out.append(bulb(170, 26))
    x, y, w, h = MB
    # Incoming cable from above into the switch, switch to the meter.
    sx, sy = SW
    out.append(f'<path d="M{sx + 9} 0 L{sx + 9} {sy}" stroke="{CABLE}" stroke-width="3.4"/>')
    out.append(f'<path d="M{sx + 9} {sy + 26} L{sx + 9} {y + h + 8} L{x + w / 2} {y + h + 8} L{x + w / 2} {y + h}" stroke="{CABLE}" stroke-width="3.4" fill="none"/>')
    out.append(f'<rect x="{sx}" y="{sy}" width="18" height="26" rx="2" fill="url(#box)" stroke="#6F7880" stroke-width="0.8"/>')
    hy = sy + 5 if on else sy + 21
    out.append(f'<path d="M{sx + 9} {sy + 13} L{sx + 9} {hy}" stroke="{FACE}" stroke-width="3.4" stroke-linecap="round"/>')
    out.append(f'<circle cx="{sx + 9}" cy="{sy + 13}" r="2.6" fill="{FACE}"/>')
    # The box, its door swung open to the left edge.
    out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#box)"/>')
    out.append(f'<rect x="{x + 5}" y="{y + 5}" width="{w - 10}" height="{h - 10}" rx="2" fill="url(#boxIn)"/>')
    out.append(f'<path d="M{x} {y + 4} L{x - 12} {y + 10} L{x - 12} {y + h - 10} L{x} {y + h - 4} Z" fill="url(#box)" opacity="0.9"/>')
    # The meter: body, LCD, terminal block below.
    out.append(f'<rect x="{x + 11}" y="{y + 10}" width="{w - 22}" height="{h - 22}" rx="3" fill="url(#meter)"/>')
    out.append(f'<rect x="{x + 17}" y="{y + 18}" width="{w - 34}" height="14" rx="1.5" fill="{LCD_ON if on else FACE}"/>')
    out.append(f'<circle cx="{x + w / 2}" cy="{y + 46}" r="2" fill="{HANDLE if on else FACE}"/>')
    # Terminals (the cover off in every card: work at the terminals).
    for i, tx in enumerate(TERM_X):
        out.append(f'<rect x="{tx - 4}" y="{TERM_Y - 5}" width="8" height="10" rx="1" fill="url(#steel)"/>')
        out.append(f'<path d="M{tx} {TERM_Y + 5} L{tx} {y + h - 5}" stroke="{CABLE}" stroke-width="2.6"/>')
    if hot:
        out.append(f'<circle cx="{TERM_X[1]}" cy="{TERM_Y}" r="12" fill="url(#heat)"/>')
        out.append(smoke(TERM_X[1] + 2, TERM_Y - 12, 0.9))
    if loose:
        out.append(f'<path d="M{TERM_X[2]} {TERM_Y + 5} L{TERM_X[2] + 5} {TERM_Y - 4}" stroke="{COPPER}" stroke-width="2"/>')
    if neutral_cut:
        tx = TERM_X[3]
        out.append(f'<rect x="{tx - 3}" y="{TERM_Y + 8}" width="6" height="7" fill="url(#boxIn)"/>')
        out.append(f'<path d="M{tx - 1.5} {TERM_Y + 8} l0 -1.5 M{tx + 1.5} {TERM_Y + 15} l0 1.5" stroke="{COPPER}" stroke-width="2"/>')
    # The terminal cover: on its seal (a red lead disc on a twisted wire).
    if cover:
        out.append(f'<rect x="{x + 9}" y="{TERM_Y - 7}" width="{w - 18}" height="5" rx="1.5" fill="url(#meter)" opacity="0.85"/>')
    if seal == 'whole':
        out.append(f'<path d="M{x + w - 12} {TERM_Y - 4} q6 4 4 10" stroke="#6F7880" stroke-width="0.9" fill="none"/>'
                   f'<circle cx="{x + w - 8}" cy="{TERM_Y + 8}" r="3" fill="{HANDLE}"/>')
    else:
        out.append(f'<path d="M{x + w - 12} {TERM_Y - 4} l3 3 M{x + w - 6} {TERM_Y + 2} l1 6" stroke="#6F7880" stroke-width="0.9" fill="none"/>'
                   f'<circle cx="{x + w - 5}" cy="{TERM_Y + 12}" r="3" fill="{HANDLE}"/>')
        # The prised-off cover on the floor.
        out.append(f'<rect x="96" y="{GY + 6}" width="{w - 18}" height="5" rx="1.5" fill="url(#meter)" transform="rotate(8 96 {GY + 6})"/>')
    return out


def box_card(kind):
    tip = (TERM_X[2] + 2, TERM_Y)
    if kind == 'off':
        out = box_stage(on=False)
        out.append(worker(132, ((SW[0] + 9, SW[1] + 21), (120, 162)), face=-1, look=6))
        out.append(screwdriver(118, 160, True, 60))
    elif kind == 'tools':
        out = box_stage(on=False)
        out.append(worker(132, ((126, 162), (tip[0] + 22, tip[1] - 12)), face=-1, look=10))
        out.append(screwdriver(tip[0], tip[1], True, -30))
    elif kind == 'metal':
        out = box_stage(on=False)
        out.append(worker(132, ((126, 162), (tip[0] + 22, tip[1] - 12)), face=-1, look=10))
        out.append(screwdriver(tip[0], tip[1], False, -30))
    elif kind == 'live':
        out = box_stage(on=True)
        out.append(worker(132, ((126, 162), (tip[0] + 22, tip[1] - 12)), face=-1, look=10))
        out.append(screwdriver(tip[0], tip[1], True, -30))
        out.append(spark(tip[0], tip[1], 0.8))
    elif kind == 'seal':
        out = box_stage(on=False, seal='broken', cover=False)
        out.append(worker(132, ((126, 162), (tip[0] + 22, tip[1] - 8)), face=-1, look=10))
        out.append(screwdriver(tip[0] + 10, tip[1] + 6, True, -20))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — fault: flickering lights. Two stages: the meter box (loose /
# hot terminal, cut neutral) and the street (a cable rubbing on a branch).
# --------------------------------------------------------------------------

def tree(out):
    out.append(f'<path d="M86 {GY} Q84 150 90 112 L94 112 Q92 150 96 {GY} Z" fill="#7A5C3E"/>')
    out.append('<path d="M92 118 Q78 96 60 84" stroke="#7A5C3E" stroke-width="3" fill="none"/>')
    for cx, cy, r in ((90, 96, 22), (72, 104, 16), (108, 104, 16), (64, 80, 12)):
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#leaf)"/>')


def tv(out, burnt=False):
    out.append('<rect x="146" y="40" width="44" height="30" rx="2" fill="#2E363E"/>'
               '<rect x="149" y="43" width="38" height="24" rx="1" fill="url(#boxIn)"/>'
               '<rect x="164" y="70" width="8" height="5" fill="#2E363E"/><rect x="154" y="75" width="28" height="3" fill="#7A5C3E"/>')
    if burnt:
        out.append(smoke(168, 40, 1.0))
        out.append(f'<path d="M156 47 l8 9 l-4 3 l9 6" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')


def fault_card(kind):
    tip = (TERM_X[2] + 2, TERM_Y)
    if kind == 'tighten':
        out = box_stage(on=False, loose=True, bulb_light=True)
        out.append(worker(132, ((126, 162), (tip[0] + 22, tip[1] - 12)), face=-1, look=10))
        out.append(screwdriver(tip[0], tip[1], True, -30))
    elif kind == 'inspect':
        out = street(window_bulb=True)
        span(out)
        hook(out)
        out.append(worker(70, ((62, 156), (86, 126)), face=1, look=-18, point=(0, 1)))
    elif kind == 'hot':
        out = box_stage(on=True, loose=True, hot=True, bulb_light=True)
        out.append(worker(146, ((140, 162), (156, 160)), face=1, look=4, stride=3))
        out.append(screwdriver(150, 164, True, 70))
    elif kind == 'neutral':
        out = box_stage(on=True, neutral_cut=True, bulb_light=False)
        tv(out, burnt=True)
        out.append(worker(146, ((140, 162), (156, 160)), face=1, look=4, stride=3))
        out.append(screwdriver(150, 164, True, 70))
    elif kind == 'rub':
        out = street(window_bulb=True)
        tree(out)
        span(out, cut=0.42)
        hook(out)
        out.append(worker(130, ((120, 160), (142, 160)), face=1, look=6, stride=3))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — fast: "the meter runs fast" — the house load first, politely.
# A room: the meter on the wall at the left, an old fridge at the right.
# --------------------------------------------------------------------------

RM = (14, 48)     # the room meter (x, y)


def room(meter_off=False, new_meter=False):
    out = card_open('room')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#floor)"/>')
    x, y = RM
    # The meter on the wall; its outgoing cable down the wall to the floor.
    out.append(f'<path d="M{x + 18} 0 L{x + 18} {y}" stroke="{CABLE}" stroke-width="3"/>')
    if not meter_off:
        out.append(f'<rect x="{x}" y="{y}" width="36" height="46" rx="3" fill="url(#meter)" stroke="#9AA4AC" stroke-width="1"/>')
        out.append(f'<rect x="{x + 6}" y="{y + 7}" width="24" height="10" rx="1" fill="{LCD_ON}"/>')
        out.append(f'<circle cx="{x + 18}" cy="{y + 26}" r="2" fill="{HANDLE}"/>')
        out.append(f'<circle cx="{x + 30}" cy="{y + 40}" r="2.4" fill="{HANDLE}"/>')
    else:
        out.append(f'<rect x="{x}" y="{y}" width="36" height="46" rx="3" fill="url(#boxIn)"/>')
        out.append(f'<path d="M{x + 10} {y + 46} l-3 8 M{x + 26} {y + 46} l3 8" stroke="{COPPER}" stroke-width="2"/>')
    out.append(f'<path d="M{x + 18} {y + 46} L{x + 18} {GY}" stroke="{CABLE}" stroke-width="3"/>')
    # The old fridge, rust spots, humming.
    out.append(f'<rect x="150" y="84" width="44" height="{GY - 84}" rx="4" fill="url(#fridge)"/>')
    out.append(f'<path d="M150 118 L194 118" stroke="#9AA4AC" stroke-width="1.2"/>')
    out.append('<rect x="154" y="96" width="3" height="14" rx="1" fill="#9AA4AC"/><rect x="154" y="124" width="3" height="18" rx="1" fill="#9AA4AC"/>')
    for cx, cy, r in ((182, 150, 3), (172, 176, 2.4), (188, 104, 2)):
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#A8743E" opacity="0.8"/>')
    out.append('<g stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linecap="round" opacity="0.8">'
               '<path d="M196 160 q4 4 0 8 q-4 4 0 8"/><path d="M146 160 q-4 4 0 8 q4 4 0 8"/></g>')
    if new_meter:
        out.append(f'<rect x="100" y="{GY - 20}" width="18" height="22" rx="2" fill="url(#meter)" stroke="#9AA4AC" stroke-width="1"/>')
    return out


def angry(x, y):
    return (f'<g stroke="{RED}" stroke-width="1.8" fill="none" stroke-linecap="round">'
            f'<path d="M{x} {y} l5 -4 l-1 5 l5 -4"/><path d="M{x + 2} {y + 8} l8 0"/><path d="M{x} {y - 10} l4 -5"/></g>')


def fast_card(kind):
    if kind == 'fridge':
        out = room()
        out.append(customer(56, ((48, 158), (64, 160)), face=1, look=4))
        out.append(worker(118, ((110, 160), (146, 128)), face=1, look=6, point=(0, 1)))
        out.append(clamp_meter(108, 168, 0.8))
    elif kind == 'leak':
        out = room()
        x, y = RM
        cx, cy = x + 18, 124
        out.append(worker(62, ((cx + 6, cy + 12), (cx + 4, cy + 18)), face=-1, look=4))
        out.append(clamp_meter(cx, cy, 1.0))
        out.append(customer(118, ((110, 158), (126, 160)), face=-1, look=4))
    elif kind == 'swap':
        out = room(meter_off=True, new_meter=True)
        x, y = RM
        out.append(worker(62, ((x + 12, y + 48), (x + 26, y + 46)), face=-1, look=-12))
        out.append(customer(126, ((118, 158), (134, 160)), face=-1, look=4))
        out.append(clamp_meter(140, 186, 0.6))
    elif kind == 'rude':
        out = room()
        out.append(customer(56, ((44, 140), (66, 150)), face=1, look=-8))
        out.append(worker(104, ((112, 128), (84, 120)), face=-1, look=-6, point=(0, -1)))
        out.append(angry(80, 100))
        out.append(clamp_meter(140, 186, 0.6))
    elif kind == 'leave':
        out = room()
        out.append(customer(56, ((44, 120), (70, 122)), face=1, look=-4))
        out.append(worker(124, ((116, 160), (134, 160)), face=1, look=4, stride=4))
        out.append(f'<g stroke="{FACE}" stroke-width="1.4" stroke-linecap="round" opacity="0.6"><path d="M98 150 l-10 0"/><path d="M100 160 l-12 0"/><path d="M98 170 l-10 0"/></g>')
        out.append(clamp_meter(140, 186, 0.6))
    return card_close(out)


CARDS = {
    'cable_span': cable_card('span'),
    'cable_anchor': cable_card('anchor'),
    'cable_tight': cable_card('tight'),
    'cable_torn': cable_card('torn'),
    'cable_hook': cable_card('hook'),
    'drip_loop': drip_card('loop'),
    'drip_side': drip_card('side'),
    'drip_top': drip_card('top'),
    'drip_taut': drip_card('taut'),
    'drip_hump': drip_card('hump'),
    'box_off': box_card('off'),
    'box_tools': box_card('tools'),
    'box_metal': box_card('metal'),
    'box_live': box_card('live'),
    'box_seal': box_card('seal'),
    'fault_tighten': fault_card('tighten'),
    'fault_inspect': fault_card('inspect'),
    'fault_hot': fault_card('hot'),
    'fault_neutral': fault_card('neutral'),
    'fault_rub': fault_card('rub'),
    'fast_fridge': fast_card('fridge'),
    'fast_leak': fast_card('leak'),
    'fast_swap': fast_card('swap'),
    'fast_rude': fast_card('rude'),
    'fast_leave': fast_card('leave'),
}

# Safe cards and traps per round (mirrors learn_board_pack38.dart).
ROUNDS = {
    'cable': (['cable_span', 'cable_anchor'], ['cable_tight', 'cable_torn', 'cable_hook']),
    'drip': (['drip_loop', 'drip_side'], ['drip_top', 'drip_taut', 'drip_hump']),
    'box': (['box_off', 'box_tools'], ['box_metal', 'box_live', 'box_seal']),
    'fault': (['fault_tighten', 'fault_inspect'], ['fault_hot', 'fault_neutral', 'fault_rub']),
    'fast': (['fast_fridge', 'fast_leak'], ['fast_swap', 'fast_rude', 'fast_leave']),
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
