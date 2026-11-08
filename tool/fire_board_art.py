"""Picture cards for ladder step 22 (lesson 1.8 শেখা, "মাঠে আগুন লাগলে করণীয়").

python -I tool/fire_board_art.py .

Writes assets/game/art/fire_board/*.svg in the same clean gradient style as
tool/rod_board_art.py and tool/pole_board_art.py (200 x 220 scene cards, drawn
edge to edge). The extinguishers and fire buckets keep the look of the step
23/24 fire levels (fire_world.dart): a red cylinder with a blue ABC band or a
black CO2 band, red conical buckets of water or sand. No words in the art; the
only writing is what a worker reads on the job: ABC / CO2 on a cylinder and
ON / OFF at a panel's switch.

What the cards show comes from lesson 1.8 only:
  1. know the enemy — Class A (dry grass, wood, paper), Class B (flammable
     liquid: diesel, transformer oil), Class C (live electrical equipment);
  2. water is the enemy on Class B (oil floats on water, the fire spreads)
     and Class C (water conducts — shock); the first job at an electrical
     fire is to switch the power source off when it is safe; the right
     weapons: DCP (ABC) and sand / dry soil for a small oil fire;
  3. the pressure gauge in the green = ready; used once, the pressure is
     gone and it must go for refill;
  4. PASS — pull the safety pin, aim at the base of the fire (not the
     flames), squeeze, sweep side to side at the base until it is fully out;
  5. stand with the wind at your back (smoke and heat not towards you), keep
     the escape route behind you open (never cornered), and when it is
     beyond control call the Fire Brigade — not a hero, smart.

Fairness (the playbook, section 4, and the step-10 review): every card in a
round shares one sky or backdrop, one place, the same equipment and the same
figure — the tools not in use stay on the fire point in every card, so only
the act tells the safe card from a trap, never a colour, a backdrop or a size.
"""

import math
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'fire_board')
W, H = 200, 220

SHIRT = '#1F5F8F'
PANTS = '#2A3442'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
INK = '#1E2126'
WIRE = '#2B3138'
ABC_BLUE = '#2F6FD0'
CO2_BLACK = '#2B2F35'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#F2E6D2"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DCE1E5"/><stop offset="1" stop-color="#B7BFC6"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="red" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E1F16"/><stop offset="0.45" stop-color="#E5483A"/><stop offset="1" stop-color="#9E2419"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#66746C"/><stop offset="0.4" stop-color="#8B9991"/><stop offset="1" stop-color="#5B6861"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7C858D"/><stop offset="0.5" stop-color="#A2ABB3"/><stop offset="1" stop-color="#7C858D"/></linearGradient>
  <linearGradient id="plinth" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BDB9AF"/><stop offset="1" stop-color="#A19D93"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9C6A3E"/><stop offset="0.5" stop-color="#D49A64"/><stop offset="1" stop-color="#8E5E36"/></linearGradient>
  <linearGradient id="jerry" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#2F5530"/><stop offset="0.5" stop-color="#4C7D49"/><stop offset="1" stop-color="#2A4C2B"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B07A4A"/><stop offset="1" stop-color="#7A4E2C"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E4E8EC"/></linearGradient>
  <linearGradient id="brick" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E4A32"/><stop offset="1" stop-color="#B0603F"/></linearGradient>
  <linearGradient id="flame" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#D9381E"/><stop offset="0.55" stop-color="#F26A22"/><stop offset="1" stop-color="#FF9B2E"/></linearGradient>
  <linearGradient id="flameIn" x1="0" y1="1" x2="0" y2="0"><stop offset="0" stop-color="#FFC43A"/><stop offset="1" stop-color="#FFF3B0"/></linearGradient>
  <linearGradient id="water" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#CDEBFB"/><stop offset="1" stop-color="#5AA0D8"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE08A" stop-opacity="0.9"/><stop offset="1" stop-color="#FF8A2A" stop-opacity="0"/></radialGradient>
  <radialGradient id="smoke" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#5E6266" stop-opacity="0.85"/><stop offset="1" stop-color="#7E8286" stop-opacity="0"/></radialGradient>
  <radialGradient id="powder" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.95"/><stop offset="1" stop-color="#F3EEF6" stop-opacity="0"/></radialGradient>
  <radialGradient id="oil" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#4A3E2A"/><stop offset="1" stop-color="#211B12"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF4B0"/><stop offset="1" stop-color="#FFD34E" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(sky='sky'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def clouds(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.9"><ellipse cx="{x}" cy="{y}" rx="{f(22 * s)}" ry="{f(8 * s)}"/>'
            f'<ellipse cx="{f(x + 15 * s)}" cy="{f(y - 6 * s)}" rx="{f(15 * s)}" ry="{f(9 * s)}"/></g>')


def trees(y):
    blobs = ''.join(f'<ellipse cx="{x}" cy="{f(y - r * 0.55)}" rx="{f(r * 1.3)}" ry="{r}"/>'
                    for x, r in [(8, 12), (34, 9), (60, 14), (104, 8), (150, 11), (196, 9)])
    return f'<g fill="#7FA36A" opacity="0.75">{blobs}</g>'


def field(gy, clouds_at=((40, 46, 0.9), (140, 30, 0.8))):
    out = card_open('sky')
    for cx, cy, s in clouds_at:
        out.append(clouds(cx, cy, s))
    out.append(f'<rect y="{gy}" width="{W}" height="{H - gy}" fill="url(#ground)"/>')
    out.append(trees(gy + 1))
    return out


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(10 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#FFF4B0" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.4 * s)}" fill="#FFFFFF"/>')


# --------------------------------------------------------------------------
# Fire and smoke.
# --------------------------------------------------------------------------

FL_OUT = 'M0 0 C-22 -10 -18 -40 -4 -56 C-6 -38 8 -36 6 -52 C22 -36 24 -10 0 0 Z'
FL_IN = 'M0 -2 C-12 -8 -10 -26 -2 -36 C0 -26 8 -26 6 -34 C14 -22 12 -8 0 -2 Z'
HEIGHTS = (0.62, 0.9, 1.0, 0.78, 0.94, 0.68, 0.86, 0.72)


def flame(x, y, w, h):
    return (f'<g transform="translate({f(x)} {f(y)}) scale({w / 44:.3f} {h / 56:.3f})">'
            f'<path d="{FL_OUT}" fill="url(#flame)"/><path d="{FL_IN}" fill="url(#flameIn)"/></g>')


def fire(cx, gy, w, h, glow=True):
    """A fire [w] wide and up to [h] tall standing on [gy], centred on [cx]."""
    s = []
    if glow:
        s.append(f'<ellipse cx="{f(cx)}" cy="{f(gy - h * 0.18)}" rx="{f(w * 0.8)}" ry="{f(h * 0.42)}" fill="url(#glow)"/>')
    n = max(2, round(w / 13))
    fw = w / n * 1.7
    order = sorted(range(n), key=lambda i: -abs(i - (n - 1) / 2))   # outer flames first
    for i in order:
        x = cx - w / 2 + w * (i + 0.5) / n
        hh = h * HEIGHTS[i % len(HEIGHTS)] * (1.0 if 0 < i < n - 1 or n < 3 else 0.82)
        s.append(flame(x, gy, fw, hh))
    return ''.join(s)


def smoke(x, y, dx, dy, n=5, r0=7):
    """A plume from (x, y) drifting by (dx, dy), widening as it goes."""
    s = []
    m = n * 2 + 2
    for i in range(m):
        t = i / (m - 1)
        r = r0 * (1 + t * 1.6)
        wob = math.sin(i * 1.7) * r0 * 0.35
        s.append(f'<circle cx="{f(x + dx * t + wob)}" cy="{f(y + dy * t)}" r="{f(r)}" fill="url(#smoke)" opacity="{f(0.8 - 0.4 * t)}"/>')
    return ''.join(s)


def grass(x0, x1, gy, lean=0, step=5):
    s = ['<g stroke-linecap="round" fill="none">']
    for i, x in enumerate(range(int(x0), int(x1), step)):
        h = 7 + (i * 7) % 6
        col = '#C9A55A' if i % 2 else '#A88A3E'
        s.append(f'<path d="M{x} {gy + 1} q{f(lean * 0.5)} {-h * 0.6} {f(lean + 1.5)} {-h}" stroke="{col}" stroke-width="1.4"/>'
                 f'<path d="M{x + 2} {gy + 1} q{f(lean * 0.5 - 1)} {-h * 0.5} {f(lean - 2)} {-h * 0.8}" stroke="{col}" stroke-width="1.2"/>')
    s.append('</g>')
    return ''.join(s)


# --------------------------------------------------------------------------
# Tools: the extinguisher (as in fire_world.dart) and the red fire bucket.
# --------------------------------------------------------------------------

def extinguisher(kind='ABC', pin=True, label=True):
    """A cylinder, bottom centre at (0, 0), 38 tall. Carry handle at (3, -37),
    hose outlet at (-4, -33)."""
    band = ABC_BLUE if kind == 'ABC' else CO2_BLACK
    s = [f'<rect x="-6.5" y="-31" width="13" height="31" rx="5" fill="url(#red)"/>',
         f'<rect x="-6.5" y="-21" width="13" height="8" fill="{band}"/>']
    if label:
        s.append(f'<text x="0" y="-15.2" font-family="sans-serif" font-size="5.2" font-weight="800" text-anchor="middle" fill="#FFFFFF">{kind}</text>')
    s.append('<rect x="-2.6" y="-34" width="5.2" height="4" fill="#4A4F55"/>'
             '<rect x="-4" y="-37.5" width="8" height="4" rx="1" fill="#3B3F45"/>'
             f'<path d="M-1 -37.5 L10 -41" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
             f'<path d="M-1 -35 L9 -35.5" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>')
    if kind == 'ABC':
        s.append('<circle cx="-5.5" cy="-37" r="2.6" fill="#FFFFFF" stroke="#7D868E" stroke-width="0.7"/>'
                 '<path d="M-7.3 -37.6 A2 2 0 0 1 -3.7 -37.6" stroke="#2FA84F" stroke-width="1.1" fill="none"/>')
    if pin:
        s.append('<circle cx="6.5" cy="-36.4" r="3" fill="none" stroke="#C9CED2" stroke-width="1.4"/>'
                 '<path d="M1 -36.4 L3.6 -36.4" stroke="#C9CED2" stroke-width="1.2"/>')
    return ''.join(s)


def ext_at(x, y, s=0.8, kind='ABC', pin=True, label=True, rot=0):
    return f'<g transform="translate({f(x)} {f(y)}) rotate({rot}) scale({s})">{extinguisher(kind, pin, label)}</g>'


def ext_in_hand(hand, s=0.8, kind='ABC', pin=True):
    """The cylinder hanging from [hand] by its carry handle; returns (svg, hose outlet)."""
    x, y = hand[0] - 3 * s, hand[1] + 37 * s
    return ext_at(x, y, s, kind, pin), (x - 4 * s, y - 33 * s)


def hose(p0, p1, sag=10):
    mx, my = (p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + sag
    return f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'


def nozzle(p, target, length=7):
    a = math.atan2(target[1] - p[1], target[0] - p[0])
    tip = (p[0] + math.cos(a) * length, p[1] + math.sin(a) * length)
    return f'<path d="M{f(p[0])} {f(p[1])} L{f(tip[0])} {f(tip[1])}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>', tip


def spray(tip, target, spread=0.32, puffs=True):
    a = math.atan2(target[1] - tip[1], target[0] - tip[0])
    d = math.hypot(target[0] - tip[0], target[1] - tip[1])
    w = d * spread
    nx, ny = -math.sin(a), math.cos(a)
    p1 = (target[0] + nx * w, target[1] + ny * w)
    p2 = (target[0] - nx * w, target[1] - ny * w)
    s = [f'<path d="M{f(tip[0])} {f(tip[1])} L{f(p1[0])} {f(p1[1])} Q{f(target[0] + math.cos(a) * w * 0.6)} {f(target[1] + math.sin(a) * w * 0.6)} {f(p2[0])} {f(p2[1])} Z" fill="#FFFFFF" opacity="0.6"/>']
    if puffs:
        for k, (u, v, r) in enumerate(((0.55, 0.15, 0.32), (0.8, -0.3, 0.42), (1.0, 0.25, 0.5), (1.05, -0.6, 0.38), (0.95, 0.75, 0.36))):
            px = tip[0] + math.cos(a) * d * u + nx * w * v
            py = tip[1] + math.sin(a) * d * u + ny * w * v
            s.append(f'<circle cx="{f(px)}" cy="{f(py)}" r="{f(w * r + 2)}" fill="url(#powder)"/>')
    return ''.join(s)


def bucket(content=None, s=1.0):
    """A red conical fire bucket, mouth up, bottom centre at (0, 0), 16 tall."""
    fill = {'water': 'url(#water)', 'sand': 'url(#ground)'}.get(content)
    out = ['<path d="M-8 -16 L8 -16 L5 0 L-5 0 Z" fill="url(#red)"/>']
    if fill:
        out.append(f'<ellipse cx="0" cy="-16" rx="8" ry="2.2" fill="{fill}"/>')
    out.append('<path d="M-8 -16 Q0 -26 8 -16" stroke="#3B3F45" stroke-width="1" fill="none"/>')
    return f'<g transform="scale({s})">{"".join(out)}</g>'


def fire_point(x, gy, used=()):
    """A fire point on its stand: the ABC cylinder on top, sand and water
    buckets on hooks; a tool in use leaves its hook empty."""
    s = [f'<rect x="{x - 1.5}" y="{gy - 64}" width="3" height="64" fill="#5F676F"/>',
         f'<rect x="{x - 15}" y="{gy - 66}" width="30" height="3" rx="1" fill="#5F676F"/>',
         f'<rect x="{x - 15}" y="{gy - 34}" width="30" height="2.4" rx="1" fill="#5F676F"/>']
    s.append(f'<path d="M{x - 8} {gy - 63} l0 4 M{x + 8} {gy - 31.6} l0 3 M{x - 8} {gy - 31.6} l0 3" stroke="#3B3F45" stroke-width="1.2"/>')
    if 'abc' not in used:
        s.append(f'<g transform="translate({x - 8} {gy - 36}) scale(0.72)">{extinguisher("ABC", label=False)}</g>')
    else:
        s.append(f'<path d="M{x - 11} {gy - 58} l0 6 l6 0 l0 -6" stroke="#3B3F45" stroke-width="1.2" fill="none"/>')
    for bx, kind in ((x - 8, 'sand'), (x + 8, 'water')):
        if kind not in used:
            s.append(f'<g transform="translate({bx} {gy - 12})">{bucket(kind, 0.85)}</g>')
    return ''.join(s)


# --------------------------------------------------------------------------
# The worker, side view facing right (from tool/rod_board_art.py).
# --------------------------------------------------------------------------

def _arm(sx, sy, hx, hy, bend=1):
    mx, my = (sx + hx) / 2, (sy + hy) / 2
    dx, dy = hx - sx, hy - sy
    n = math.hypot(dx, dy) or 1
    ex, ey = mx + (-dy / n) * 5 * bend, my + (dx / n) * 5 * bend
    if ey < my:
        ex, ey = mx - (-dy / n) * 5 * bend, my - (dx / n) * 5 * bend
    return (f'<path d="M{f(sx)} {f(sy)} L{f(ex)} {f(ey)} L{f(hx)} {f(hy)}" stroke="{SHIRT}" stroke-width="5.4" '
            f'stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
            f'<circle cx="{f(hx)}" cy="{f(hy)}" r="2.8" fill="{SKIN}"/>')


def worker(fx, gy, hands, props='', front=''):
    """[hands] = (back hand, front hand); [props] is drawn behind the body
    (after the back arm), [front] after the front arm."""
    g = []
    hip = (fx, gy - 30)
    sh = (fx + 1, gy - 56)
    head = (fx + 3, gy - 64)
    g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 5} {gy - 15} L{fx - 7} {gy - 2}" stroke="#222B37" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 5} {gy - 15} L{fx + 6} {gy - 2}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<rect x="{fx - 13}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/><rect x="{fx + 1}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/>')
    (bx, by), (hx, hy) = hands
    g.append(_arm(sh[0] - 2, sh[1] + 3, bx, by))
    g.append(props)
    g.append(f'<path d="M{hip[0] - 7.5} {hip[1]} L{sh[0] - 7.5} {sh[1] - 1} Q{sh[0]} {sh[1] - 4} {sh[0] + 7.5} {sh[1] - 1} L{hip[0] + 7.5} {hip[1]} Z" fill="url(#shirt)"/>')
    hx0, hy0 = head
    g.append(f'<rect x="{hx0 - 3}" y="{hy0 + 4}" width="6" height="6" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="{hx0}" cy="{hy0}" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M{hx0 - 7} {hy0 + 1} Q{hx0 - 7} {hy0 + 6} {hx0 - 3} {hy0 + 7} L{hx0 - 3} {hy0 + 1} Z" fill="{HAIR}"/>')
    g.append(f'<path d="M{hx0 - 8} {hy0 - 1} A8 8 0 0 1 {hx0 + 8} {hy0 - 1} Z" fill="{HELMET}"/>'
             f'<rect x="{hx0 - 8}" y="{hy0 - 2.4}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<circle cx="{hx0 + 4}" cy="{hy0 + 1}" r="1.1" fill="{HAIR}"/>')
    g.append(_arm(sh[0] + 1, sh[1] + 3, hx, hy, bend=-1))
    g.append(front)
    return ''.join(g)


def mirrored(svg, fx):
    """Turn a drawing round to face left about x = fx (no text inside)."""
    return f'<g transform="translate({2 * fx} 0) scale(-1 1)">{svg}</g>'


def spraying_worker(fx, gy, target, pin=False, kind='ABC', aim=True, s=0.8):
    """Cylinder in the front hand, nozzle in the back hand pointed at
    [target]; [aim] False = nozzle lowered, nothing coming out."""
    handle = (fx + 11, gy - 31)
    noz = (fx + 26, gy - 40) if aim else (fx + 20, gy - 24)
    tgt = target if aim else (fx + 34, gy)
    ext, outlet = ext_in_hand(handle, s, kind, pin)
    nz, tip = nozzle(noz, tgt)
    body = worker(fx, gy, (noz, handle), props=hose(outlet, noz, 6) + nz, front=ext)
    return body, tip


def dropped_pin(x, y):
    return (f'<circle cx="{x}" cy="{y}" r="2.6" fill="none" stroke="#C9CED2" stroke-width="1.3"/>'
            f'<path d="M{x + 2.6} {y} l7 0.6" stroke="#C9CED2" stroke-width="1.2" stroke-linecap="round"/>')


def throw_worker(fx, gy, content):
    """Both hands up, the bucket tipped forward; returns (svg, mouth point)."""
    back, front = (fx + 20, gy - 50), (fx + 22, gy - 41)
    b = f'<g transform="translate({fx + 27} {gy - 44}) rotate(-62)">{bucket(content, 1.0)}</g>'
    mouth = (fx + 27 + 14, gy - 44 - 8)
    return worker(fx, gy, (back, front), front=b), mouth


def stream(p0, p1, content, lift=26):
    mx, my = (p0[0] + p1[0]) / 2, min(p0[1], p1[1]) - lift
    if content == 'water':
        drops = ''.join(f'<circle cx="{f(p1[0] + dx)}" cy="{f(p1[1] + dy)}" r="{r}" fill="#9FD3F5"/>'
                        for dx, dy, r in ((-6, -5, 1.6), (5, -7, 1.3), (9, -2, 1.5), (-10, 0, 1.2), (2, -11, 1.1)))
        # The splash where it lands.
        drops += f'<circle cx="{f(p1[0])}" cy="{f(p1[1] - 3)}" r="7" fill="url(#powder)"/>'
        return (f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="url(#water)" stroke-width="5" fill="none" stroke-linecap="round"/>'
                f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.7"/>' + drops)
    grains = []
    for i in range(34):
        t = (i + 0.5) / 34
        x = (1 - t) ** 2 * p0[0] + 2 * t * (1 - t) * mx + t * t * p1[0]
        y = (1 - t) ** 2 * p0[1] + 2 * t * (1 - t) * my + t * t * p1[1]
        off = ((i * 37) % 7 - 3) * (0.4 + t)
        grains.append(f'<circle cx="{f(x + off * 0.4)}" cy="{f(y + off)}" r="{f(1.5 + t * 0.9)}" fill="url(#ground)" stroke="#8A7A5A" stroke-width="0.6"/>')
    return ''.join(grains)


# --------------------------------------------------------------------------
# Round 1 — know the enemy: which fire is Class B (flammable liquid)?
# One yard in every card: dry grass, a wood-and-paper heap, a diesel can
# leaking a puddle, an LT panel on a pole. Only where the fire is differs.
# --------------------------------------------------------------------------

G1 = 172


def jerrycan(x, y):
    return (f'<g transform="translate({x} {y})">'
            '<path d="M0 0 L26 0 L26 -30 L8 -30 L0 -22 Z" fill="url(#jerry)"/>'
            '<path d="M4 -4 L22 -26 M4 -26 L22 -4" stroke="#24412A" stroke-width="1.4" opacity="0.7"/>'
            '<rect x="12" y="-36" width="12" height="4" rx="1.5" fill="#24412A"/>'
            '<rect x="1" y="-31" width="6" height="6" rx="1" fill="#3B3F45" transform="rotate(-40 4 -28)"/></g>')


def wood_heap(x, y, charred=False):
    """Logs with paper beside them; [charred] = burning logs drawn over the
    bottom of their own flames (blackened bark, glowing ends)."""
    bark, end, ring = ('#4A2E1A', '#FF9B2E', '#2A1A10') if charred else ('url(#wood)', '#D9B07A', '#7A4E2C')
    logs = ''.join(f'<rect x="{x + dx}" y="{y + dy}" width="{w}" height="7" rx="3.5" fill="{bark}"/>'
                   f'<ellipse cx="{x + dx + w - 3}" cy="{y + dy + 3.5}" rx="3" ry="3.5" fill="{end}" stroke="{ring}" stroke-width="0.6"/>'
                   for dx, dy, w in ((0, -7, 34), (4, -14, 30), (8, -21, 22)))
    papers = (f'<path d="M{x - 6} {y} l8 -9 l7 4 l3 5 Z" fill="url(#paper)" stroke="#AEB6BD" stroke-width="0.5"/>'
              f'<path d="M{x + 30} {y} l6 -8 l8 3 l-2 5 Z" fill="url(#paper)" stroke="#AEB6BD" stroke-width="0.5"/>')
    return logs + papers


def lt_panel(x, y, w=36, h=40, lever_on=True, labels=True, lever=True):
    """An LT distribution panel; the switch lever on its right side
    ([lever] False = no switch on the box itself)."""
    s = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="url(#panel)" stroke="#5F676F" stroke-width="0.8"/>',
         f'<rect x="{x + 4}" y="{y + 4}" width="{w - 8}" height="{h - 8}" rx="1" fill="none" stroke="#5F676F" stroke-width="0.8"/>',
         f'<rect x="{x + w - 9}" y="{y + h / 2 - 3}" width="2.4" height="6" rx="1" fill="#3B3F45"/>',
         f'<path d="M{x + 2} {y} L{x + w / 2} {y - 6} L{x + w - 2} {y} Z" fill="#7C858D"/>']
    if not lever:
        return ''.join(s)
    px, py = x + w + 3, y + h / 2
    end = (px + 2, py - 11) if lever_on else (px + 2, py + 11)
    s.append(f'<rect x="{x + w}" y="{py - 13}" width="6" height="26" rx="1.5" fill="#5F676F"/>')
    s.append(f'<path d="M{px} {py} L{end[0]} {end[1]}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
             f'<circle cx="{end[0]}" cy="{end[1]}" r="2.4" fill="#C0392B"/>')
    if labels:
        s.append(f'<text x="{px + 6}" y="{py - 9}" font-family="sans-serif" font-size="5" font-weight="700" fill="{INK}">ON</text>'
                 f'<text x="{px + 6}" y="{py + 13}" font-family="sans-serif" font-size="5" font-weight="700" fill="{INK}">OFF</text>')
    return ''.join(s)


def class_card(burning):
    out = field(G1, clouds_at=((34, 40, 0.8), (128, 26, 0.7)))
    # The LT panel on its pole, its cable running up.
    out.append(f'<rect x="164" y="0" width="12" height="{G1 + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M168 0 L168 86" stroke="{WIRE}" stroke-width="2"/>')
    out.append(lt_panel(144, 90, 30, 36, labels=False))
    out.append(grass(4, 44, G1))
    out.append(wood_heap(88, G1))
    out.append(f'<ellipse cx="66" cy="{G1 + 10}" rx="30" ry="6" fill="url(#oil)"/>'
               f'<path d="M48 {G1 + 8} q14 -3 30 0" stroke="#8A7A5A" stroke-width="0.8" fill="none" opacity="0.7"/>')
    out.append(jerrycan(50, G1 + 2))
    if burning == 'grass':
        out.append(fire(24, G1 + 2, 38, 44) + smoke(26, G1 - 54, 18, -40))
    elif burning == 'wood':
        # The flames rise out of the heap; the charred logs and the burning
        # paper stay in front so it reads as wood, not the diesel can.
        out.append(fire(104, G1 - 14, 28, 44) + smoke(106, G1 - 66, 16, -38))
        out.append(wood_heap(88, G1, charred=True))
        out.append(flame(83, G1, 9, 12) + flame(122, G1, 9, 12))
    elif burning == 'jerry':
        out.append(fire(66, G1 - 30, 26, 40) + smoke(68, G1 - 80, 14, -40))
    elif burning == 'puddle':
        out.append(fire(66, G1 + 12, 56, 34) + smoke(70, G1 - 34, 16, -46))
    elif burning == 'panel':
        out.append(fire(159, 98, 30, 34) + smoke(160, 54, 14, -40))
        out.append(spark(150, 112, 0.8) + spark(170, 122, 0.7) + spark(146, 128, 0.6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — oil or power on fire: no water; power off first; ABC or sand.
# One yard: an LT panel on a pole (left), a transformer on its plinth with
# an oil leak in front (right), the fire point on the right edge. The panel
# cards add its supply isolator on a post of its own, well away from the
# burning box, so "power OFF" is done at arm's length with nothing touching
# the panel (the step-22 review); the water-on-panel trap shows the same post.
# --------------------------------------------------------------------------

G2 = 180
PANEL2 = (8, 96)


def transformer(x, gy):
    s = [f'<rect x="{x - 8}" y="{gy - 12}" width="74" height="12" fill="url(#plinth)"/>',
         f'<rect x="{x}" y="{gy - 64}" width="58" height="52" rx="2" fill="url(#tank)"/>']
    s.append(''.join(f'<rect x="{x + 6 + i * 9}" y="{gy - 58}" width="3.4" height="42" rx="1.5" fill="#5B6861" opacity="0.8"/>' for i in range(6)))
    s.append(f'<rect x="{x + 8}" y="{gy - 78}" width="42" height="10" rx="5" fill="url(#tank)"/>'
             f'<path d="M{x + 14} {gy - 68} L{x + 14} {gy - 64} M{x + 44} {gy - 68} L{x + 44} {gy - 64}" stroke="#5B6861" stroke-width="2"/>')
    for bx in (x + 12, x + 29, x + 46):
        s.append(f'<rect x="{bx - 3}" y="{gy - 82}" width="6" height="18" rx="1" fill="url(#porcelain)"/>'
                 + ''.join(f'<rect x="{bx - 4.5}" y="{gy - 80 + k * 5}" width="9" height="2" rx="1" fill="#B98454"/>' for k in range(3)))
    return ''.join(s)


ISO = (76, 116)   # the isolator's post centre x and box top


def isolator(on=True):
    """The panel's supply switch on its own post, well away from the box:
    a cable runs from it along the ground to the panel's pole. The lever on
    its right side (up = ON, down = OFF), the labels on its left."""
    cx, top = ISO
    px, py = cx + 11, top + 10
    end = (px + 2, py - 11) if on else (px + 2, py + 11)
    return (f'<path d="M{cx} {top + 20} L{cx} {G2 + 1} L27 {G2 + 1} L27 {PANEL2[1] + 40}" stroke="{WIRE}" stroke-width="2" fill="none"/>'
            f'<rect x="{cx - 1.5}" y="{top + 14}" width="3" height="{G2 - top - 14}" fill="#5F676F"/>'
            f'<rect x="{cx - 8}" y="{top}" width="16" height="20" rx="1.5" fill="url(#panel)" stroke="#5F676F" stroke-width="0.8"/>'
            f'<rect x="{cx + 8}" y="{py - 12}" width="5" height="24" rx="1.5" fill="#5F676F"/>'
            f'<path d="M{px} {py} L{end[0]} {end[1]}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>'
            f'<circle cx="{end[0]}" cy="{end[1]}" r="2.4" fill="#C0392B"/>'
            f'<text x="{cx - 10}" y="{top + 6}" font-family="sans-serif" font-size="5" font-weight="700" text-anchor="end" fill="{INK}">ON</text>'
            f'<text x="{cx - 10}" y="{top + 19}" font-family="sans-serif" font-size="5" font-weight="700" text-anchor="end" fill="{INK}">OFF</text>')


def yard2(used=(), lever_on=True, switch=False):
    out = field(G2, clouds_at=((70, 30, 0.8), (150, 46, 0.6)))
    out.append(f'<rect x="21" y="0" width="12" height="{G2 + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M27 0 L27 92" stroke="{WIRE}" stroke-width="2"/>')
    out.append(lt_panel(PANEL2[0], PANEL2[1], 34, 40, labels=False, lever=False))
    if switch:
        out.append(isolator(lever_on))
    out.append(transformer(108, G2))
    out.append(f'<ellipse cx="128" cy="{G2 + 9}" rx="40" ry="6.5" fill="url(#oil)"/>'
               f'<path d="M100 {G2 + 7} q24 -3 50 0" stroke="#8A7A5A" stroke-width="0.8" fill="none" opacity="0.7"/>')
    out.append(fire_point(186, G2, used))
    return out


def panel_fire():
    x, y = PANEL2
    return (fire(x + 17, y + 2, 30, 34) + smoke(x + 20, y - 40, 14, -44)
            + spark(x + 10, y + 26, 0.8) + spark(x + 28, y + 34, 0.7))


def oil_fire(spread=False):
    s = fire(126, G2 + 11, 64, 40)
    if spread:
        s += fire(78, G2 + 22, 34, 26, glow=False) + fire(176, G2 + 22, 30, 24, glow=False)
        s += f'<path d="M60 {G2 + 22} q60 6 136 0" stroke="#9FD3F5" stroke-width="1.6" fill="none" opacity="0.8"/>'
    return s + smoke(130, G2 - 44, 14, -50, 5, 8)


def water_card(kind):
    used = {'oil_abc': ('abc',), 'oil_sand': ('sand',), 'oil_water': ('water',), 'panel_water': ('water',)}.get(kind, ())
    panel = kind in ('panel_off', 'panel_water')
    out = yard2(used, lever_on=kind != 'panel_off', switch=panel)
    if kind == 'panel_off':
        out.append(panel_fire())
        # Well away from the burning box: one hand pulls the isolator's lever
        # down to OFF, the other hangs free at his side — nothing touches the panel.
        lever = (ISO[0] + 13, ISO[1] + 20)
        fx = 112
        out.append(mirrored(worker(fx, G2, ((fx - 6, G2 - 30), (2 * fx - lever[0], lever[1]))), fx))
    elif kind == 'panel_water':
        out.append(panel_fire())
        fx = 124
        body, mouth = throw_worker(fx, G2, 'water')
        out.append(mirrored(body, fx))
        m = (2 * fx - mouth[0], mouth[1])
        out.append(stream(m, (PANEL2[0] + 22, PANEL2[1] + 22), 'water', 14))
        # The current comes back down the wet stream into the worker.
        p0, p1 = (PANEL2[0] + 30, PANEL2[1] + 24), (m[0] + 4, m[1] + 8)
        zig = ' '.join(f'L{f(p0[0] + (p1[0] - p0[0]) * k / 8)} {f(p0[1] + (p1[1] - p0[1]) * k / 8 + (5 if k % 2 else -1))}' for k in range(1, 9))
        out.append(f'<path d="M{p0[0]} {p0[1]} {zig}" stroke="#FFE34A" stroke-width="1.8" fill="none" stroke-linejoin="round"/>')
        out.append(f'<path d="M{fx - 18} {G2 - 74} l-5 -6 M{fx - 6} {G2 - 78} l0 -8 M{fx + 6} {G2 - 74} l5 -6 M{fx - 22} {G2 - 52} l-7 -2 M{fx + 10} {G2 - 52} l7 -2" '
                   'stroke="#FFE34A" stroke-width="1.8" stroke-linecap="round"/>')
        out.append(spark(PANEL2[0] + 24, PANEL2[1] + 22, 1.0))
    elif kind == 'oil_abc':
        out.append(oil_fire())
        body, tip = spraying_worker(58, G2, (112, G2 + 8), pin=False)
        out.append(body)
        out.append(spray(tip, (112, G2 + 8)))
        out.append(dropped_pin(40, G2 + 6))
    elif kind == 'oil_sand':
        out.append(oil_fire())
        body, mouth = throw_worker(58, G2, 'sand')
        out.append(body)
        out.append(stream(mouth, (112, G2 + 4), 'sand', 2))
    elif kind == 'oil_water':
        out.append(oil_fire(spread=True))
        body, mouth = throw_worker(52, G2, 'water')
        out.append(body)
        out.append(stream(mouth, (108, G2 + 4), 'water', 2))
    elif kind == 'tr_hose':
        out.append(fire(137, G2 - 70, 54, 40) + smoke(140, G2 - 124, 14, -40))
        out.append(f'<path d="M-4 {G2 + 12} Q30 {G2 + 20} 50 {G2 + 2} T74 {G2 - 34}" stroke="#2F7A3A" stroke-width="3" fill="none"/>')
        body = worker(60, G2, ((74, G2 - 34), (80, G2 - 42)))
        out.append(body)
        tip = (84, G2 - 46)
        out.append(f'<path d="M76 {G2 - 38} L{tip[0]} {tip[1]}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
        out.append(stream(tip, (132, G2 - 70), 'water', 14))
        out.append(spark(124, G2 - 74, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — the pressure gauge: in the green = ready.
# Close-up of the same ABC cylinder on the van's wall; layout A alone,
# layout B with the worker's hand on the carry handle.
# --------------------------------------------------------------------------

DIAL = (62, 74, 42)   # centre x, centre y, radius


def gauge(needle_deg):
    cx, cy, r = DIAL

    def pt(a, rr):
        return (cx + math.cos(math.radians(a)) * rr, cy + math.sin(math.radians(a)) * rr)

    def arc(a0, a1, rr, col, w):
        p0, p1 = pt(a0, rr), pt(a1, rr)
        large = 1 if (a1 - a0) > 180 else 0
        return f'<path d="M{f(p0[0])} {f(p0[1])} A{rr} {rr} 0 {large} 1 {f(p1[0])} {f(p1[1])}" stroke="{col}" stroke-width="{w}" fill="none"/>'

    s = [f'<circle cx="{cx}" cy="{cy}" r="{r + 4}" fill="url(#steel)" stroke="#5F676F" stroke-width="1"/>',
         f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF"/>',
         arc(-210, -140, r - 9, '#D9381E', 12), arc(-140, -40, r - 9, '#2FA84F', 12), arc(-40, 30, r - 9, '#D9381E', 12)]
    for k in range(9):
        a = -210 + k * 30
        p0, p1 = pt(a, r - 2), pt(a, r - 16)
        s.append(f'<path d="M{f(p0[0])} {f(p0[1])} L{f(p1[0])} {f(p1[1])}" stroke="{INK}" stroke-width="1.2"/>')
    tip = pt(needle_deg, r - 6)
    tail = pt(needle_deg + 180, 8)
    s.append(f'<path d="M{f(tail[0])} {f(tail[1])} L{f(tip[0])} {f(tip[1])}" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>'
             f'<circle cx="{cx}" cy="{cy}" r="6" fill="{INK}"/>')
    s.append(f'<ellipse cx="{cx - 13}" cy="{cy - 20}" rx="15" ry="7" fill="#FFFFFF" opacity="0.4" transform="rotate(-30 {cx - 13} {cy - 20})"/>')
    return ''.join(s)


def gauge_card(needle, hand=False, used=False):
    out = card_open('wall')
    out.append('<rect x="0" y="150" width="200" height="8" fill="#8E979F" opacity="0.6"/>'
               '<path d="M0 40 L200 40" stroke="#A9B1B8" stroke-width="1"/>')
    # Body: shoulders and the ABC band.
    out.append('<path d="M46 240 L46 132 Q46 108 76 104 L124 104 Q154 108 154 132 L154 240 Z" fill="url(#red)"/>')
    out.append(f'<rect x="46" y="150" width="108" height="34" fill="{ABC_BLUE}"/>'
               '<text x="100" y="176" font-family="sans-serif" font-size="25" font-weight="800" text-anchor="middle" fill="#F5F7FA">ABC</text>')
    # Neck, valve head, levers.
    out.append('<rect x="86" y="88" width="28" height="18" fill="#4A4F55"/>'
               '<rect x="76" y="64" width="50" height="26" rx="4" fill="#3B3F45"/>')
    out.append(f'<path d="M96 66 L176 50" stroke="{INK}" stroke-width="8" stroke-linecap="round"/>'
               f'<path d="M98 84 L170 86" stroke="{INK}" stroke-width="8" stroke-linecap="round"/>')
    # Hose down the left side, the nozzle at the bottom.
    out.append(f'<path d="M80 86 Q36 96 30 150 L30 206" stroke="{INK}" stroke-width="6" fill="none" stroke-linecap="round"/>'
               f'<rect x="25" y="202" width="10" height="16" rx="2" fill="{INK}"/>')
    if used:
        # Powder caked on the nozzle and the valve; pin gone, seal snapped.
        caked = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#F3EEF6" stroke="#B7BFC6" stroke-width="0.6"/>'
                        for x, y, rx, ry in ((30, 214, 9, 6), (36, 204, 6, 4), (24, 206, 4, 3), (116, 94, 8, 4),
                                             (84, 62, 7, 4), (98, 64, 4, 2.5), (60, 128, 10, 4), (70, 140, 5, 3)))
        out.append(caked + '<circle cx="34" cy="216" r="12" fill="url(#powder)"/>')
        out.append('<circle cx="118" cy="76" r="2.4" fill="#1E2126"/>'
                   '<path d="M130 92 l6 8 M138 90 l4 9" stroke="#2FA84F" stroke-width="1.4" stroke-linecap="round"/>')
    else:
        out.append('<path d="M112 76 L136 76" stroke="#C9CED2" stroke-width="3" stroke-linecap="round"/>'
                   '<circle cx="144" cy="76" r="9" fill="none" stroke="#C9CED2" stroke-width="3"/>'
                   '<path d="M136 82 Q140 94 132 98" stroke="#2FA84F" stroke-width="1.6" fill="none"/>')
    out.append(gauge(needle))
    if hand:
        # The worker's hand round the carry handle, sleeve from the right edge.
        out.append(f'<path d="M210 120 L172 98" stroke="url(#shirt)" stroke-width="22" stroke-linecap="round"/>'
                   f'<path d="M210 120 L172 98" stroke="{SHIRT}" stroke-width="2" opacity="0.4"/>'
                   f'<ellipse cx="156" cy="88" rx="16" ry="11" fill="{SKIN}"/>'
                   f'<path d="M146 80 Q140 88 146 96 M153 79 Q147 88 153 97 M160 80 Q154 88 160 96" stroke="{SKIN_D}" stroke-width="1.4" fill="none"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — PASS: pull the pin, aim at the base, squeeze, sweep until out.
# --------------------------------------------------------------------------

G4 = 184


def pass_card(kind):
    out = field(G4, clouds_at=((120, 34, 0.8), (40, 60, 0.6)))
    out.append(f'<rect x="178" y="0" width="12" height="{G4 + 3}" fill="url(#pole)"/>')
    out.append(grass(112, 200, G4))
    # Fire size never tells the cards apart: one safe card (just started at
    # the base) and one trap (the pin) face the tall fire, the rest the low one.
    full = kind in ('base', 'pin')
    fh = 70 if full else 44
    out.append(fire(152, G4 + 2, 64, fh))
    out.append(smoke(156, G4 - (88 if full else 62), 12, -46))
    base = (128, G4 - 2)
    if kind == 'pin':
        body, tip = spraying_worker(52, G4, base, pin=True)
        out.append(body)
        # Squeezing hard: nothing comes out with the pin still in.
        out.append(f'<path d="M{tip[0] + 4} {tip[1] - 6} l4 -3 M{tip[0] + 5} {tip[1]} l5 0" stroke="{INK}" stroke-width="1" stroke-linecap="round" opacity="0.6"/>')
    elif kind == 'stop':
        body, tip = spraying_worker(52, G4, base, aim=False)
        out.append(body)
        out.append(dropped_pin(30, G4 + 7))
    else:
        target = (150, G4 + 2 - fh * 0.82) if kind == 'flame' else base
        body, tip = spraying_worker(52, G4, target)
        out.append(body)
        out.append(spray(tip, target))
        out.append(dropped_pin(30, G4 + 7))
        if kind == 'sweep':
            out.append(f'<path d="M116 {G4 + 12} Q140 {G4 + 22} 170 {G4 + 12}" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round"/>'
                       f'<path d="M116 {G4 + 12} l3 -5 M116 {G4 + 12} l6 2 M170 {G4 + 12} l-3 -5 M170 {G4 + 12} l-6 2" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — where to stand: wind at the back, the way out open, and call
# the Fire Brigade when it is beyond control.
# --------------------------------------------------------------------------

G5 = 186


def stand_card(kind):
    out = field(G5, clouds_at=((100, 30, 0.8), (170, 52, 0.6)))
    big = kind in ('hero', 'call')
    wind = -1 if kind == 'wind_face' else 1
    if kind == 'cornered':
        # A brick wall right behind him and round the corner.
        out.append(f'<rect x="0" y="96" width="34" height="{G5 - 96 + 2}" fill="url(#brick)"/>'
                   + ''.join(f'<path d="M0 {y} L34 {y}" stroke="#E8D2C0" stroke-width="0.8" opacity="0.7"/>' for y in range(104, G5, 8))
                   + ''.join(f'<path d="M{(x + (8 if (y // 8) % 2 else 0)) % 34} {y} l0 8" stroke="#E8D2C0" stroke-width="0.8" opacity="0.7"/>'
                             for y in range(96, G5 - 4, 8) for x in (0, 16)))
        out.append(f'<path d="M34 96 L60 110 L60 {G5 + 6} L34 {G5 + 2} Z" fill="url(#brick)" opacity="0.85"/>')
    out.append(grass(70, 200, G5, lean=3 * wind))
    out.append(grass(4, 60, G5, lean=3 * wind, step=9))
    if big:
        out.append(fire(150, G5 + 2, 100, 112))
        out.append(smoke(150, G5 - 130, 30 * wind, -30, 5, 14))
    else:
        out.append(fire(148, G5 + 2, 56, 54))
        if wind > 0:
            out.append(smoke(152, G5 - 66, 40, -40, 5, 9))
        else:
            # The smoke drifting back over the worker's head.
            out.append(smoke(140, G5 - 62, -90, -6, 6, 10))
    if kind == 'call':
        fx = 26
        phone = f'<rect x="{fx + 6}" y="{G5 - 70}" width="5" height="9" rx="1.2" fill="{INK}" transform="rotate(12 {fx + 8} {G5 - 66})"/>'
        out.append(worker(fx, G5, ((fx - 6, G5 - 32), (fx + 9, G5 - 62)), front=phone))
        out.append(ext_at(fx + 22, G5 + 2, 0.8, label=False))
        # His way out stays open behind him.
    elif kind == 'hero':
        body, tip = spraying_worker(70, G5, (104, G5 - 4))
        out.append(body)
        out.append(spray(tip, (104, G5 - 4)))
        out.append(dropped_pin(54, G5 + 7))
    else:
        fx = 44 if kind != 'cornered' else 42
        body, tip = spraying_worker(fx, G5, (122, G5 - 2))
        out.append(body)
        out.append(spray(tip, (122, G5 - 2)))
        out.append(dropped_pin(fx - 16, G5 + 7))
    if kind == 'cornered':
        # The fire has run round in front of the corner: no way out.
        out.append(fire(60, G5 + 14, 40, 34, glow=False))
    return card_close(out)


CARDS = {
    # Round 1 — which fire is Class B?
    'class_jerry': class_card('jerry'),
    'class_puddle': class_card('puddle'),
    'class_grass': class_card('grass'),
    'class_wood': class_card('wood'),
    'class_panel': class_card('panel'),
    # Round 2 — oil or power on fire: no water.
    'water_panel_off': water_card('panel_off'),
    'water_oil_abc': water_card('oil_abc'),
    'water_oil_sand': water_card('oil_sand'),
    'water_oil_water': water_card('oil_water'),
    'water_panel_water': water_card('panel_water'),
    'water_tr_hose': water_card('tr_hose'),
    # Round 3 — the pressure gauge.
    'gauge_ok': gauge_card(-95),
    'gauge_ok_hand': gauge_card(-70, hand=True),
    'gauge_low': gauge_card(-190),
    'gauge_high': gauge_card(10, hand=True),
    'gauge_used': gauge_card(-200, used=True),
    # Round 4 — PASS.
    'pass_base': pass_card('base'),
    'pass_sweep': pass_card('sweep'),
    'pass_flame': pass_card('flame'),
    'pass_pin': pass_card('pin'),
    'pass_stop': pass_card('stop'),
    # Round 5 — where to stand.
    'stand_wind_back': stand_card('wind_back'),
    'stand_call': stand_card('call'),
    'stand_wind_face': stand_card('wind_face'),
    'stand_cornered': stand_card('cornered'),
    'stand_hero': stand_card('hero'),
}

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
