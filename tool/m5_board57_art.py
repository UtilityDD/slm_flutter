"""Picture cards for lesson 5.7 শেখা ("রাতের বেলা ফল্ট খোঁজার কৌশল").

python -I tool/m5_board57_art.py .

Writes assets/game/art/m5_board57/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge, night
scenes). No words in the art.

What the cards show comes from lesson 5.7 only:
  1. prep: torch, headlamp and phone fully charged before leaving (pro tip 3);
     never alone at night (pro tip 4); a reflective jacket at the roadside
     (pro tip 2). Traps: setting off alone, a dark jacket at the roadside with
     a car coming, a flickering torch (flat battery);
  2. drive: slow, two people — one drives, one watches the line (section 4);
     a turnable searchlight for the pole top (myth 2); binoculars on a
     searchlit pole top (section 2). Traps: headlights only, the driver
     craning up himself, speeding, an unknown muddy track (section 4);
  3. eyes: after the torch, lights off and wait a while — the eyes adapt and
     a faint corona or spark shows (pro tip 1). Traps: the torch held on the
     insulators, the torch flicked on and off, looking for corona at midday
     (corona is invisible by day, section 3);
  4. clue: a faint blue-purple glow round a damaged insulator (corona); bluish
     tracking lines on an insulator = a bad insulator; the pole where a
     resident saw a flash (section 3). Traps: a torch glint taken for corona,
     tracking seen and walked away from, a flash walked past;
  5. sense: listening to a hiss in the night quiet; asking a resident who is
     awake (section 4). Traps: walking past a resident who calls, crossing a
     dark field with no light (stumbles, holes — section 1), running to finish
     (no hurry or shortcuts at night — section 1).

Every worker stays on the ground or seated in the van: the line may be in service (ruling M5-3) —
nobody climbs or touches it on these cards.

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
    print('usage: python -I tool/m5_board57_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board57')
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
VEST = '#C8E43A'
VEST_D = '#A6C02A'
REFL = '#EEF3F6'
DARKJ = '#2B2F37'
DARKJ_D = '#22252C'
COND = '#A9B4BC'
COND_D = '#6F7A82'
CRACK = '#1E2329'
BEAM = '#FFF4C2'
TORCH = '#D8402F'
BATT_G = '#4CC46A'
BATT_R = '#E04A3A'
BADGE = '#DDE3E8'
CRATE = '#6B5B3E'
CRATE_D = '#54472F'
STAR = '#F2F5FF'
MOON = '#F4EFD8'
SUN = '#FFE27A'
TRACK = '#8FB8FF'
VAN = '#E9ECEF'
VAN_D = '#B7BEC6'
GLASS = '#3A4C66'
TYRE = '#15181C'
CAR = '#7A2E2E'
WALL = '#4B4F5A'
WALL_D = '#3A3E48'
ROOF = '#5E3A2E'
RESI = '#8E3B5A'
HOLE = '#06080A'
PUDDLE = '#2E3A4A'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0A1330"/><stop offset="1" stop-color="#22345C"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1F2E24"/><stop offset="1" stop-color="#131C16"/></linearGradient>
  <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#30353F"/><stop offset="1" stop-color="#1D2128"/></linearGradient>
  <linearGradient id="mud" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A3A26"/><stop offset="1" stop-color="#35291B"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5E666E"/><stop offset="0.5" stop-color="#8E979E"/><stop offset="1" stop-color="#4E565D"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E99A6"/><stop offset="0.5" stop-color="#D8DEE6"/><stop offset="1" stop-color="#7A8592"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#E6DCFF" stop-opacity="0.95"/><stop offset="0.45" stop-color="#9C86FF" stop-opacity="0.55"/><stop offset="1" stop-color="#6E5BFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="lamp" cx="0.5" cy="0.5" r="0.7"><stop offset="0" stop-color="#FFE7A0"/><stop offset="1" stop-color="#F4B54A"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='night'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def night_sky(moon=True):
    stars = [(14, 14), (40, 30), (66, 10), (92, 24), (118, 12), (140, 34), (186, 16), (24, 52), (108, 46)]
    o = [f'<circle cx="{x}" cy="{y}" r="{1.1 if i % 3 else 1.6}" fill="{STAR}" opacity="0.85"/>' for i, (x, y) in enumerate(stars)]
    if moon:
        o.append(f'<circle cx="170" cy="30" r="9" fill="{MOON}"/><circle cx="174" cy="27" r="8" fill="#0A1330" opacity="0.9"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# The worker (from tool/m4_board41_art.py): one figure, any pose, with a
# reflective vest or a dark jacket over the shirt.
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


def figure(hip, sh, head, feet, hands, face=1, look=0, point=(0, 0), jacket='vest'):
    """The lineman: blue shirt (or a dark jacket), a reflective vest, dark
    trousers, yellow helmet, black gloves."""
    sleeve, sleeve_d = (DARKJ, DARKJ_D) if jacket == 'dark' else (SHIRT, SHIRT_D)
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
    g.append(_limb(sb, eb, hb, sleeve_d, 5.4))
    g.append(_hand(hb, point[0]))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    torso = (f'M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z')
    if jacket == 'dark':
        g.append(f'<path d="{torso}" fill="{DARKJ}"/>')
    else:
        g.append(f'<path d="{torso}" fill="url(#shirt)"/>')
        # The vest: a lime panel over the torso, two silver bands round it.
        vx, vy = px * 0.82, py * 0.82
        top = (hip[0] + (sh[0] - hip[0]) * 0.86, hip[1] + (sh[1] - hip[1]) * 0.86)
        g.append(f'<path d="M{f(hip[0] - vx)} {f(hip[1] - vy)} L{f(top[0] - vx)} {f(top[1] - vy)} L{f(top[0] + vx)} {f(top[1] + vy)} '
                 f'L{f(hip[0] + vx)} {f(hip[1] + vy)} Z" fill="{VEST}"/>')
        for t in (0.3, 0.55):
            bx, by = hip[0] + (sh[0] - hip[0]) * t, hip[1] + (sh[1] - hip[1]) * t
            g.append(f'<path d="M{f(bx - vx)} {f(by - vy)} L{f(bx + vx)} {f(by + vy)}" stroke="{REFL}" stroke-width="2.2"/>')
        g.append(f'<path d="M{f(hip[0] - vx)} {f(hip[1] - vy)} L{f(hip[0] + vx)} {f(hip[1] + vy)}" stroke="{VEST_D}" stroke-width="1.4"/>')
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
    g.append(_limb(sf, ef, hf, sleeve, 5.4))
    g.append(_hand(hf, point[1]))
    return ''.join(g)


S = 1.25  # the worker's scale

POSES = {
    # (hip, shoulder, head, back foot, front foot) as offsets from the feet point,
    # x offsets multiplied by the facing.
    'stand': ((0, -30), (1, -56), (3, -64), (-7, -1), (6, -1)),
    'walk': ((0, -30), (4, -56), (7, -63), (-12, -1), (12, -1)),
    'run': ((0, -29), (9, -54), (13, -61), (-18, -7), (16, -1)),
    'stumble': ((0, -27), (13, -49), (18, -54), (-14, -1), (5, -9)),
}


def worker(x, hands_world, face=1, look=0, point=(0, 0), jacket='vest', pose='stand', gy=GY):
    """A worker at x (feet on gy), scaled S about his feet; the hands are given
    in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip_o, sh_o, head_o, fb_o, ff_o = POSES[pose]

    def at(o):
        return (x + o[0] * face, gy + o[1])
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(at(hip_o), at(sh_o), at(head_o), (at(fb_o), at(ff_o)), hands, face, look, point, jacket)
    return f'<g transform="translate({f(x)} {gy}) scale({S}) translate({f(-x)} -{gy})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def motion(x, y, dx=0, dy=1, n=3, length=9):
    """Little white swish marks: something moving."""
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.85">{"".join(o)}</g>'


def torch(p, ang):
    """A hand torch held at p, pointing along ang (degrees, 0 = right)."""
    x, y = p
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x - 4)}" y="{f(y - 2.6)}" width="13" height="5.2" rx="1.6" fill="{TORCH}"/>'
            f'<rect x="{f(x + 8)}" y="{f(y - 3.6)}" width="4" height="7.2" rx="1" fill="url(#steel)"/></g>')


def beam(p, target, spread=14, broken=False, strength=1.0):
    """A torch or searchlight beam from p to target."""
    x0, y0 = p
    x1, y1 = target
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    nx, ny = -dy / n, dx / n
    if broken:
        o = []
        for a, b in ((0.08, 0.3), (0.42, 0.58), (0.72, 0.84)):
            ax, ay = x0 + dx * a, y0 + dy * a
            bx, by = x0 + dx * b, y0 + dy * b
            sa, sb = spread * a, spread * b
            o.append(f'<path d="M{f(ax + nx * sa)} {f(ay + ny * sa)} L{f(bx + nx * sb)} {f(by + ny * sb)} L{f(bx - nx * sb)} {f(by - ny * sb)} '
                     f'L{f(ax - nx * sa)} {f(ay - ny * sa)} Z" fill="{BEAM}" opacity="0.22"/>')
        return ''.join(o)
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1 + nx * spread)} {f(y1 + ny * spread)} L{f(x1 - nx * spread)} {f(y1 - ny * spread)} Z" '
            f'fill="{BEAM}" opacity="{f(0.3 * strength)}"/>'
            f'<path d="M{f(x0)} {f(y0)} L{f(x1 + nx * spread * 0.45)} {f(y1 + ny * spread * 0.45)} L{f(x1 - nx * spread * 0.45)} {f(y1 - ny * spread * 0.45)} Z" '
            f'fill="{BEAM}" opacity="{f(0.32 * strength)}"/>')


def battery(x, y, bars=3):
    """A battery badge above a lamp or phone: 3 green bars = charged, 1 red = flat."""
    o = [f'<rect x="{f(x - 7)}" y="{f(y - 4)}" width="14" height="8" rx="1.6" fill="none" stroke="{BADGE}" stroke-width="1.2"/>',
         f'<rect x="{f(x + 7)}" y="{f(y - 1.6)}" width="1.8" height="3.2" fill="{BADGE}"/>']
    color = BATT_G if bars >= 3 else BATT_R
    for i in range(bars):
        o.append(f'<rect x="{f(x - 5.4 + i * 4)}" y="{f(y - 2.4)}" width="3" height="4.8" fill="{color}"/>')
    return ''.join(o)


def headlamp(x, y):
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="8" ry="4" fill="none" stroke="{CRATE_D}" stroke-width="2"/>'
            f'<rect x="{f(x + 5)}" y="{f(y - 3.5)}" width="6" height="7" rx="1.5" fill="url(#steel)"/>')


def phone(x, y, ang=0):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x - 4)}" y="{f(y - 7)}" width="8" height="14" rx="1.6" fill="{BOOT}"/>'
            f'<rect x="{f(x - 3)}" y="{f(y - 5.5)}" width="6" height="10" rx="0.8" fill="{GLASS}"/></g>')


def kit_crate(x, y=GY, bars=3):
    """A crate at the roadside with a torch, a headlamp and a phone on top,
    each with its battery badge."""
    o = [f'<rect x="{f(x - 22)}" y="{f(y - 22)}" width="44" height="22" rx="2" fill="{CRATE}"/>',
         f'<path d="M{f(x - 22)} {f(y - 11)} L{f(x + 22)} {f(y - 11)}" stroke="{CRATE_D}" stroke-width="1.4"/>',
         torch((x - 15, y - 26), 0), headlamp(x + 2, y - 26), phone(x + 16, y - 29)]
    o += [battery(x - 9, y - 40, bars), battery(x + 4, y - 40, bars), battery(x + 16, y - 44, bars)]
    return ''.join(o)


def pin_insulator(x, yb, s=1.0, cracked=False):
    """A pin insulator on the cross-arm top (yb); its top is at yb - 46 s."""
    o = [f'<rect x="{f(x - 3 * s)}" y="{f(yb - 16 * s)}" width="{f(6 * s)}" height="{f(16 * s)}" fill="url(#steel)"/>',
         f'<path d="M{f(x - 24 * s)} {f(yb - 14 * s)} L{f(x + 24 * s)} {f(yb - 14 * s)} L{f(x + 14 * s)} {f(yb - 24 * s)} L{f(x - 14 * s)} {f(yb - 24 * s)} Z" fill="url(#porcelain)"/>',
         f'<path d="M{f(x - 19 * s)} {f(yb - 23 * s)} L{f(x + 19 * s)} {f(yb - 23 * s)} L{f(x + 10 * s)} {f(yb - 34 * s)} L{f(x - 10 * s)} {f(yb - 34 * s)} Z" fill="url(#porcelain)"/>',
         f'<path d="M{f(x - 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 46 * s)} L{f(x - 10 * s)} {f(yb - 46 * s)} Z" fill="url(#porcelain)"/>']
    if cracked:
        o.append(f'<path d="M{f(x - 4 * s)} {f(yb - 44 * s)} l{f(3 * s)} {f(6 * s)} l{f(-4 * s)} {f(5 * s)} l{f(5 * s)} {f(8 * s)} l{f(-2 * s)} {f(6 * s)}" '
                 f'stroke="{CRACK}" stroke-width="{f(1.6 * s)}" fill="none" stroke-linejoin="round"/>')
    return ''.join(o)


def pole(x, top, s=1.0, cracked_at=None):
    """A line pole with a cross-arm, three pin insulators and the conductors
    running off both card edges. Returns (svg, insulator tops)."""
    arm_y = top + 12 * s
    o = [f'<rect x="{f(x - 4 * s)}" y="{f(top)}" width="{f(8 * s)}" height="{f(GY + 4 - top)}" fill="url(#pole)"/>',
         f'<rect x="{f(x - 30 * s)}" y="{f(arm_y)}" width="{f(60 * s)}" height="{f(5 * s)}" rx="1" fill="url(#pole)"/>']
    tops = []
    for i, dx in enumerate((-24, 0, 24)):
        ix = x + dx * s
        o.append(pin_insulator(ix, arm_y, 0.42 * s, cracked=(cracked_at == i)))
        tops.append((ix, arm_y - 46 * 0.42 * s))
    for ix, iy in tops:
        o.append(f'<path d="M0 {f(iy + 3)} Q{f(ix / 2)} {f(iy + 6)} {f(ix)} {f(iy)} Q{f((ix + 200) / 2)} {f(iy + 6)} 200 {f(iy + 3)}" '
                 f'stroke="{COND_D}" stroke-width="{f(1.6 * s)}" fill="none"/>')
    return ''.join(o), tops


def glow(x, y, r=14, opacity=1.0):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)" opacity="{f(opacity)}"/>'


def tracking(x, y, s=1.0):
    """Small bluish spark-like lines over the insulator surface."""
    o = []
    for i, (ox, oy) in enumerate(((-6, 2), (2, -1), (5, 5))):
        o.append(f'<path d="M{f(x + ox * s)} {f(y + oy * s)} l{f(2 * s)} {f(2.5 * s)} l{f(-2.2 * s)} {f(1.8 * s)} l{f(2.4 * s)} {f(3 * s)}" '
                 f'stroke="{TRACK}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def flash(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(12 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.2 * s)}" stroke-linecap="round">{rays}</g>')


def glint(x, y):
    """A sharp white torch reflection: a four-point star."""
    return (f'<path d="M{f(x)} {f(y - 9)} L{f(x + 2)} {f(y - 2)} L{f(x + 9)} {f(y)} L{f(x + 2)} {f(y + 2)} L{f(x)} {f(y + 9)} '
            f'L{f(x - 2)} {f(y + 2)} L{f(x - 9)} {f(y)} L{f(x - 2)} {f(y - 2)} Z" fill="{MOVE}"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="2.2" fill="{STAR}"/>')


def sound_arcs(x, y, toward=-1, n=3):
    """Sound rings travelling from (x, y) towards the listener's side."""
    o = []
    for i in range(n):
        r = 7 + i * 6
        a0, a1 = math.radians(150), math.radians(210)
        if toward > 0:
            a0, a1 = math.radians(-30), math.radians(30)
        p0 = (x + r * math.cos(a0), y + r * math.sin(a0))
        p1 = (x + r * math.cos(a1), y + r * math.sin(a1))
        sweep = 0 if toward < 0 else 1
        o.append(f'<path d="M{f(p0[0])} {f(p0[1])} A{f(r)} {f(r)} 0 0 {sweep} {f(p1[0])} {f(p1[1])}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85">{"".join(o)}</g>'


def house(x0, x1, top=96, resident=None):
    """A house wall with a lit window; resident None / 'point' / 'wave' / 'talk'."""
    o = [f'<path d="M{f(x0 - 6)} {f(top)} L{f((x0 + x1) / 2)} {f(top - 24)} L{f(x1 + 6)} {f(top)} Z" fill="{ROOF}"/>',
         f'<rect x="{f(x0)}" y="{f(top)}" width="{f(x1 - x0)}" height="{f(GY + 2 - top)}" fill="{WALL}"/>',
         f'<path d="M{f(x0)} {f(top + 4)} L{f(x1)} {f(top + 4)}" stroke="{WALL_D}" stroke-width="2"/>']
    wx, wy, ww, wh = x0 + 8, top + 18, x1 - x0 - 16, 34
    o.append(f'<rect x="{f(wx)}" y="{f(wy)}" width="{f(ww)}" height="{f(wh)}" fill="url(#lamp)"/>')
    if resident:
        cx = wx + ww * 0.45
        o.append(f'<path d="M{f(cx - 9)} {f(wy + wh)} Q{f(cx)} {f(wy + 16)} {f(cx + 9)} {f(wy + wh)} Z" fill="{RESI}"/>')
        o.append(f'<circle cx="{f(cx)}" cy="{f(wy + 13)}" r="6" fill="{SKIN}"/>')
        o.append(f'<path d="M{f(cx - 6)} {f(wy + 11)} A6 6 0 0 1 {f(cx + 6)} {f(wy + 11)} Z" fill="{HAIR}"/>')
        if resident == 'point':
            o.append(f'<path d="M{f(cx + 6)} {f(wy + 24)} L{f(cx + 22)} {f(wy + 12)}" stroke="{RESI}" stroke-width="4" stroke-linecap="round"/>')
            o.append(f'<circle cx="{f(cx + 23)}" cy="{f(wy + 11)}" r="2.4" fill="{SKIN}"/>')
        elif resident == 'wave':
            o.append(f'<path d="M{f(cx + 6)} {f(wy + 24)} L{f(cx + 14)} {f(wy + 4)}" stroke="{RESI}" stroke-width="4" stroke-linecap="round"/>')
            o.append(f'<circle cx="{f(cx + 14)}" cy="{f(wy + 2)}" r="2.6" fill="{SKIN}"/>')
            o.append(motion(cx + 22, wy + 2, 1, 0, 2, 6))
        elif resident == 'talk':
            o.append(f'<path d="M{f(cx + 6)} {f(wy + 26)} L{f(cx + 16)} {f(wy + 22)}" stroke="{RESI}" stroke-width="4" stroke-linecap="round"/>')
            o.append(f'<circle cx="{f(cx + 17)}" cy="{f(wy + 21)}" r="2.4" fill="{SKIN}"/>')
    o.append(f'<path d="M{f(wx + ww / 2)} {f(wy)} L{f(wx + ww / 2)} {f(wy + wh)} M{f(wx)} {f(wy + wh / 2)} L{f(wx + 4)} {f(wy + wh / 2)}" '
             f'stroke="{WALL_D}" stroke-width="2"/>')
    o.append(f'<rect x="{f(wx)}" y="{f(wy)}" width="{f(ww)}" height="{f(wh)}" fill="none" stroke="{WALL_D}" stroke-width="2.4"/>')
    return ''.join(o)


def van(x, gy=192, face=1, light='off', light_to=None, driver=True, crane=False, tilt=0, headlights=False, crew=False):
    """The patrol van (side view), x = its rear end, facing right. light:
    the roof searchlight 'off' / 'on' (a beam to light_to) / 'smear'. crew:
    a second man seated in the crew-cab window, steering the searchlight
    (mounted on the roof right over him) by its handle from inside."""
    L, Hh = 92, 40
    top = gy - Hh - 8
    o = []
    lx, ly = (x + L - 31.5, top - 5) if crew else (x + 18, top - 5)
    if light in ('on', 'smear') and light_to:
        o.append(beam((lx + 8, ly), light_to, spread=12))
        if light == 'smear':
            tx, ty = light_to
            o.append(beam((lx + 8, ly), (tx - 26, ty + 16), spread=12, strength=0.5))
            o.append(beam((lx + 8, ly), (tx - 50, ty + 34), spread=12, strength=0.3))
    if headlights:
        o.append(f'<path d="M{f(x + L)} {f(gy - 18)} L200 {f(gy - 30)} L200 {f(gy + 14)} Z" fill="{BEAM}" opacity="0.3"/>')
    body = [f'<rect x="{f(x)}" y="{f(top)}" width="{f(L - 22)}" height="{f(Hh)}" rx="4" fill="{VAN}"/>',
            f'<path d="M{f(x + L - 24)} {f(top)} L{f(x + L - 10)} {f(top)} L{f(x + L)} {f(top + 18)} L{f(x + L)} {f(top + Hh)} L{f(x + L - 24)} {f(top + Hh)} Z" fill="{VAN}"/>',
            f'<path d="M{f(x + L - 20)} {f(top + 4)} L{f(x + L - 11)} {f(top + 4)} L{f(x + L - 3)} {f(top + 18)} L{f(x + L - 20)} {f(top + 18)} Z" fill="{GLASS}"/>',
            f'<rect x="{f(x)}" y="{f(top + Hh - 10)}" width="{f(L)}" height="4" fill="{VAN_D}"/>',
            f'<rect x="{f(x + L - 4)}" y="{f(top + Hh - 18)}" width="4" height="5" rx="1" fill="{BEAM}"/>']
    if crew:
        # The crew-cab window, the second man seated in it, one hand up on
        # the searchlight's handle that comes down through the roof.
        cx = x + L - 32
        body.append(f'<rect x="{f(cx - 8)}" y="{f(top + 4)}" width="17" height="14" rx="2" fill="{GLASS}"/>')
        body.append(f'<circle cx="{f(cx - 4)}" cy="{f(top + 12)}" r="4.4" fill="{SKIN}"/>')
        body.append(f'<path d="M{f(cx - 9)} {f(top + 11)} A5 5 0 0 1 {f(cx + 1)} {f(top + 11)} Z" fill="{HELMET}"/>')
        body.append(f'<path d="M{f(lx + 4.5)} {f(top)} L{f(lx + 4.5)} {f(top + 10)}" stroke="{VAN_D}" stroke-width="2"/>')
        body.append(f'<circle cx="{f(lx + 4.5)}" cy="{f(top + 11)}" r="2.4" fill="{GLOVE}"/>')
    if driver:
        dx = x + L - 13
        body.append(f'<circle cx="{f(dx)}" cy="{f(top + 12)}" r="4.4" fill="{SKIN}"/>')
        body.append(f'<path d="M{f(dx - 5)} {f(top + 11)} A5 5 0 0 1 {f(dx + 5)} {f(top + 11)} Z" fill="{HELMET}"/>')
    if crane:
        # The driver leans out of his window, head up, one hand on the wheel.
        hx, hy = x + L - 4, top + 2
        body.append(f'<path d="M{f(x + L - 12)} {f(top + 16)} L{f(hx)} {f(hy + 6)}" stroke="{VEST}" stroke-width="7" stroke-linecap="round"/>')
        body.append(f'<g transform="rotate(-28 {f(hx)} {f(hy)})"><circle cx="{f(hx)}" cy="{f(hy)}" r="5.4" fill="{SKIN}"/>'
                    f'<path d="M{f(hx - 6)} {f(hy - 1)} A6 6 0 0 1 {f(hx + 6)} {f(hy - 1)} Z" fill="{HELMET}"/></g>')
    body.append(f'<rect x="{f(lx)}" y="{f(ly)}" width="9" height="6" rx="2" fill="url(#steel)"/>')
    body.append(f'<rect x="{f(lx + 3)}" y="{f(ly + 5)}" width="3" height="4" fill="{VAN_D}"/>')
    for wx in (x + 16, x + L - 18):
        body.append(f'<circle cx="{f(wx)}" cy="{f(gy - 2)}" r="9" fill="{TYRE}"/><circle cx="{f(wx)}" cy="{f(gy - 2)}" r="3.6" fill="url(#steel)"/>')
    g = ''.join(body)
    if tilt:
        g = f'<g transform="rotate({f(tilt)} {f(x + L / 2)} {f(gy)})">{g}</g>'
    o.append(g)
    return ''.join(o)


def car(x, gy=196):
    """An oncoming car (from the right), headlights on, coming left."""
    return (f'<path d="M{f(x)} {f(gy - 14)} L0 {f(gy - 26)} L0 {f(gy + 10)} Z" fill="{BEAM}" opacity="0.3"/>'
            f'<rect x="{f(x)}" y="{f(gy - 24)}" width="56" height="18" rx="5" fill="{CAR}"/>'
            f'<path d="M{f(x + 10)} {f(gy - 24)} L{f(x + 18)} {f(gy - 36)} L{f(x + 44)} {f(gy - 36)} L{f(x + 50)} {f(gy - 24)} Z" fill="{CAR}"/>'
            f'<path d="M{f(x + 14)} {f(gy - 25)} L{f(x + 20)} {f(gy - 33)} L{f(x + 42)} {f(gy - 33)} L{f(x + 46)} {f(gy - 25)} Z" fill="{GLASS}"/>'
            f'<rect x="{f(x)}" y="{f(gy - 18)}" width="4" height="5" rx="1" fill="{BEAM}"/>'
            f'<circle cx="{f(x + 12)}" cy="{f(gy - 5)}" r="7" fill="{TYRE}"/><circle cx="{f(x + 44)}" cy="{f(gy - 5)}" r="7" fill="{TYRE}"/>')


def binoculars(x, y):
    return (f'<rect x="{f(x - 5)}" y="{f(y - 7)}" width="5" height="11" rx="2" fill="{BOOT}"/>'
            f'<rect x="{f(x + 1)}" y="{f(y - 7)}" width="5" height="11" rx="2" fill="{BOOT}"/>'
            f'<rect x="{f(x - 5)}" y="{f(y - 8)}" width="11" height="3" rx="1" fill="url(#steel)"/>')


# --------------------------------------------------------------------------
# Round 1 — prep: the roadside before leaving.
# --------------------------------------------------------------------------

def road_stage(back='night'):
    out = card_open(back)
    out.append(night_sky())
    out.append(f'<rect y="170" width="{W}" height="{H - 170}" fill="url(#road)"/>')
    out.append(f'<path d="M0 206 L200 206" stroke="{REFL}" stroke-width="2" stroke-dasharray="12 10" opacity="0.5"/>')
    return out


def prep_card(kind):
    out = road_stage()
    if kind == 'charged':
        out.append(kit_crate(100))
        out.append(worker(52, ((44, 168), (72, 142)), face=1, look=12))
        out.append(phone(72, 138))
        out.append(worker(154, ((146, 168), (132, 160)), face=-1, look=14, point=(0, 1)))
    elif kind == 'pair':
        out.append(beam((92, 148), (176, 200), 10))
        out.append(beam((140, 148), (196, 196), 10))
        out.append(worker(70, ((62, 170), (92, 148)), face=1, pose='walk'))
        out.append(torch((92, 148), 34))
        out.append(worker(120, ((112, 170), (140, 148)), face=1, pose='walk'))
        out.append(torch((140, 148), 34))
    elif kind == 'alone':
        out.append(kit_crate(34))
        out.append(beam((146, 148), (198, 196), 10))
        out.append(worker(124, ((116, 170), (146, 148)), face=1, pose='walk'))
        out.append(torch((146, 148), 34))
    elif kind == 'dark':
        out.append(car(146))
        out.append(worker(40, ((32, 170), (54, 160)), face=1, look=10))
        out.append(worker(96, ((88, 170), (106, 162)), face=1, look=8, jacket='dark'))
    elif kind == 'flicker':
        out.append(beam((92, 148), (176, 200), 10))
        out.append(beam((140, 148), (196, 196), 10, broken=True))
        out.append(worker(70, ((62, 170), (92, 148)), face=1, pose='walk'))
        out.append(torch((92, 148), 34))
        out.append(worker(120, ((112, 170), (140, 148)), face=1, pose='walk', look=18))
        out.append(torch((140, 148), 34))
        out.append(motion(150, 136, 1, -0.6, 2, 6))
        out.append(battery(146, 124, bars=1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — drive: the van on the feeder road; the pole top at the right.
# --------------------------------------------------------------------------

def drive_stage(ground='road'):
    out = card_open('night')
    out.append(night_sky(moon=False))
    out.append(f'<rect y="176" width="{W}" height="{H - 176}" fill="url(#{ground})"/>')
    p, tops = pole(168, 40)
    out.append(p)
    return out, tops


def drive_card(kind):
    if kind == 'track':
        out, tops = drive_stage('mud')
        out.append(f'<ellipse cx="40" cy="206" rx="20" ry="4" fill="{PUDDLE}"/><ellipse cx="130" cy="212" rx="16" ry="3" fill="{PUDDLE}"/>')
    else:
        out, tops = drive_stage()
    top = tops[1]
    if kind == 'slow':
        # Both men seated in the cab: one drives, the other aims the roof
        # searchlight at the pole top from his seat (section 4, myth 2).
        out.append(van(10, light='on', light_to=(top[0], top[1] + 2), crew=True))
    elif kind == 'binoc':
        out.append(van(4, light='on', light_to=(top[0], top[1] + 2), driver=True))
        out.append(worker(124, ((134, 120), (138, 120)), face=1, look=-30))
        out.append(binoculars(137, 121))
    elif kind == 'headlights':
        out.append(worker(16, ((10, 170), (24, 168)), face=1, look=6))
        out.append(van(30, light='off', headlights=True))
    elif kind == 'crane':
        out.append(van(30, light='off', crane=True, driver=False))
        out.append(motion(16, 166, -1, 0, 3, 10))
    elif kind == 'speed':
        out.append(van(40, light='smear', light_to=(top[0], top[1] + 2), tilt=-2))
        out.append(motion(30, 160, -1, 0, 3, 18))
        out.append(motion(30, 182, -1, 0, 2, 14))
    elif kind == 'track':
        out.append(van(18, light='on', light_to=(top[0], top[1] + 2), tilt=-7))
        out.append(worker(132, ((124, 170), (140, 166)), face=1, pose='walk'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — eyes: a field, the line far away at the top right.
# --------------------------------------------------------------------------

def eyes_stage(back='night'):
    out = card_open(back)
    if back == 'night':
        out.append(night_sky())
        out.append(f'<rect y="160" width="{W}" height="{H - 160}" fill="url(#ground)"/>')
    else:
        out.append(f'<circle cx="34" cy="30" r="13" fill="{SUN}"/>')
        out.append(f'<rect y="160" width="{W}" height="{H - 160}" fill="url(#grass)"/>')
    p, tops = pole(150, 70, s=0.7)
    out.append(p)
    return out, tops


def eyes_card(kind):
    out, tops = eyes_stage('day' if kind == 'midday' else 'night')
    ix, iy = tops[1]
    if kind == 'dark':
        out.append(worker(60, ((52, 170), (72, 172)), face=1, look=-18))
        out.append(torch((72, 172), 100))
    elif kind == 'glow':
        out.append(glow(ix, iy + 3, 12))
        out.append(worker(60, ((52, 170), (80, 130)), face=1, look=-22, point=(0, 1)))
        out.append(torch((52, 170), 100))
    elif kind == 'beam':
        # Torch glare on the porcelain (the glint of clue_glint), not the
        # spark sprite, which means a real fault flash on this board.
        out.append(beam((80, 140), (ix, iy + 3), 10))
        out.append(glint(ix - 3, iy + 1))
        out.append(worker(60, ((52, 170), (80, 140)), face=1, look=-22))
        out.append(torch((80, 140), -36))
    elif kind == 'flick':
        out.append(glow(ix, iy + 3, 10, 0.35))
        out.append(beam((80, 140), (ix, iy + 3), 10, broken=True))
        out.append(worker(60, ((52, 170), (80, 140)), face=1, look=-22))
        out.append(torch((80, 140), -36))
        out.append(motion(86, 128, 1, -1, 2, 6))
        out.append(motion(78, 154, -1, 1, 2, 6))
    elif kind == 'midday':
        out.append(worker(60, ((52, 170), (68, 132)), face=1, look=-22))
        out.append(torch((52, 170), 100))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — clue: one pole close up; the worker below on the ground.
# --------------------------------------------------------------------------

def clue_stage(cracked=False, home=None):
    out = card_open('night')
    out.append(night_sky(moon=False))
    out.append(f'<rect y="172" width="{W}" height="{H - 172}" fill="url(#ground)"/>')
    if home is not None:
        out.append(house(0, 46, top=104, resident=home))
    p, tops = pole(146, 52, s=1.15, cracked_at=1 if cracked else None)
    out.append(p)
    return out, tops


def clue_card(kind):
    if kind == 'corona':
        out, tops = clue_stage(cracked=True)
        ix, iy = tops[1]
        out.insert(len(out) - 1, glow(ix, iy + 10, 20))
        out.append(worker(62, ((54, 170), (88, 128)), face=1, look=-24, point=(0, 1)))
        out.append(torch((54, 170), 100))
    elif kind == 'tracking':
        out, tops = clue_stage()
        ix, iy = tops[1]
        out.append(glow(ix, iy + 10, 12, 0.6))
        out.append(tracking(ix, iy + 4, 1.8))
        out.append(worker(62, ((54, 170), (88, 128)), face=1, look=-24, point=(0, 1)))
        out.append(torch((54, 170), 100))
    elif kind == 'flash':
        out, tops = clue_stage(home='point')
        ix, iy = tops[2]
        out.append(glow(ix, iy + 8, 14, 0.7))
        out.append(beam((104, 140), (ix, iy + 8), 10))
        out.append(worker(84, ((76, 170), (104, 140)), face=1, look=-26))
        out.append(torch((104, 140), -44))
    elif kind == 'glint':
        out, tops = clue_stage()
        ix, iy = tops[1]
        out.append(beam((88, 142), (ix, iy + 10), 10))
        out.append(glint(ix - 3, iy + 8))
        out.append(worker(66, ((88, 142), (92, 126)), face=1, look=-24, point=(0, 1)))
        out.append(torch((88, 142), -42))
    elif kind == 'fine':
        out, tops = clue_stage(cracked=True)
        ix, iy = tops[1]
        out.append(glow(ix, iy + 10, 12, 0.6))
        out.append(tracking(ix, iy + 4, 1.8))
        out.append(worker(60, ((68, 170), (40, 168)), face=-1, pose='walk'))
        out.append(torch((40, 168), 160))
        out.append(motion(84, 150, 1, 0, 3, 8))
    elif kind == 'ignored':
        out, tops = clue_stage(home='point')
        ix, iy = tops[2]
        out.append(glow(ix, iy + 8, 14, 0.7))
        out.append(flash(ix, iy + 8, 0.8))
        out.append(worker(104, ((112, 170), (84, 168)), face=-1, pose='walk'))
        out.append(torch((84, 168), 160))
        out.append(motion(128, 150, 1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — sense: a village lane at night, a house and a pole.
# --------------------------------------------------------------------------

def sense_stage(resident=None, hole=False):
    out = card_open('night')
    out.append(night_sky(moon=False))
    out.append(f'<rect y="172" width="{W}" height="{H - 172}" fill="url(#ground)"/>')
    out.append(house(0, 48, top=100, resident=resident))
    p, tops = pole(164, 36)
    out.append(p)
    if hole:
        out.append(f'<ellipse cx="150" cy="204" rx="18" ry="6" fill="{HOLE}"/>'
                   f'<path d="M132 204 Q150 196 168 204" stroke="{CRATE_D}" stroke-width="2" fill="none"/>')
    return out, tops


def sense_card(kind):
    if kind == 'listen':
        out, tops = sense_stage()
        ix, iy = tops[0]
        out.append(sound_arcs(ix - 6, iy + 2, toward=-1))
        out.append(worker(100, ((92, 170), (108, 128)), face=1, look=-14))
        out.append(torch((92, 170), 100))
    elif kind == 'ask':
        out, tops = sense_stage(resident='talk')
        out.append(worker(84, ((76, 170), (62, 150)), face=-1, look=-10))
        out.append(torch((76, 170), 100))
        out.append(sound_arcs(58, 136, toward=1, n=2))
    elif kind == 'pass':
        # He keeps his back to the resident who calls him, torch on the pole.
        out, tops = sense_stage(resident='wave')
        ix, iy = tops[0]
        out.append(beam((122, 140), (ix, iy + 8), 10))
        out.append(worker(102, ((94, 170), (122, 140)), face=1, look=-20))
        out.append(torch((122, 140), -50))
    elif kind == 'field':
        out, tops = sense_stage(hole=True)
        out.append(worker(112, ((104, 160), (138, 150)), face=1, pose='stumble'))
        out.append(motion(98, 140, -1, -0.4, 3, 8))
    elif kind == 'run':
        out, tops = sense_stage()
        out.append(beam((146, 136), (196, 120), 10))
        out.append(worker(118, ((104, 168), (146, 136)), face=1, pose='run'))
        out.append(torch((146, 136), -16))
        out.append(motion(92, 150, -1, 0, 3, 12))
    return card_close(out)


CARDS = {
    'prep_charged': prep_card('charged'),
    'prep_pair': prep_card('pair'),
    'prep_alone': prep_card('alone'),
    'prep_dark': prep_card('dark'),
    'prep_flicker': prep_card('flicker'),
    'drive_slow': drive_card('slow'),
    'drive_binoc': drive_card('binoc'),
    'drive_headlights': drive_card('headlights'),
    'drive_crane': drive_card('crane'),
    'drive_speed': drive_card('speed'),
    'drive_track': drive_card('track'),
    'eyes_dark': eyes_card('dark'),
    'eyes_glow': eyes_card('glow'),
    'eyes_beam': eyes_card('beam'),
    'eyes_flick': eyes_card('flick'),
    'eyes_midday': eyes_card('midday'),
    'clue_corona': clue_card('corona'),
    'clue_tracking': clue_card('tracking'),
    'clue_flash': clue_card('flash'),
    'clue_glint': clue_card('glint'),
    'clue_fine': clue_card('fine'),
    'clue_ignored': clue_card('ignored'),
    'sense_listen': sense_card('listen'),
    'sense_ask': sense_card('ask'),
    'sense_pass': sense_card('pass'),
    'sense_field': sense_card('field'),
    'sense_run': sense_card('run'),
}

# Safe cards and traps per round (mirrors learn_board_pack57.dart).
ROUNDS = {
    'prep': (['prep_charged', 'prep_pair'], ['prep_alone', 'prep_dark', 'prep_flicker']),
    'drive': (['drive_slow', 'drive_binoc'], ['drive_headlights', 'drive_crane', 'drive_speed', 'drive_track']),
    'eyes': (['eyes_dark', 'eyes_glow'], ['eyes_beam', 'eyes_flick', 'eyes_midday']),
    'clue': (['clue_corona', 'clue_tracking', 'clue_flash'], ['clue_glint', 'clue_fine', 'clue_ignored']),
    'sense': (['sense_listen', 'sense_ask'], ['sense_pass', 'sense_field', 'sense_run']),
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
