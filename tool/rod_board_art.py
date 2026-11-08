"""Picture cards for ladder step 13 (lesson 1.5 শেখা, "ডিসচার্জ রড").

python -I tool/rod_board_art.py .

Writes assets/game/art/rod_board/*.svg in the same clean gradient style as
tool/pole_board_art.py and tool/harness_board_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art; the only writing is what a worker
reads on the job: the voltage on the docket (work order) and the rating
label on a rod.

What the cards show comes from lesson 1.5 only:
  1. pick the rod: its rating label must match the line voltage on the
     docket (11 kV rod on a 33 kV line = suicide; never a lower rating; LT /
     440 V has its own set); no PVC-pipe jugaad with a metal hook and a thin
     flexible wire — a standard rod has a tested insulating stick, a strong
     hook, a copper cable and an earth clamp;
  2. the 30-second check: the insulating stick clean, dry and crack-free;
     the copper cable's insulation not cut or torn, both end connections
     firm; clamp and hook clean with a firm grip;
  3. a dead line can still hold capacitive charge / induced voltage: the
     permit is paper, discharging is the physical safety; discharge the
     three phases yourself before touching; in wet or stormy weather the
     work is put off;
  4. earth first, then the line: the earth clamp goes first on a reliable
     earthing point (an earth rod, the pole's earthing strip) — a rusty or
     loose earth point does not work; hook on the line before the earth sends
     the charge through the body;
  5. the brass/copper shorting chain is thrown over the line after the rod,
     never instead of it; no rusty / broken / iron jugaad chain; never hold
     the chain bare-handed on an unverified line.

Fairness (the playbook, section 4, and the step-10 review): every card in a
round shares one sky or backdrop, one rod colour, one clamp, one figure — only
the gear and the act tell the safe card from a trap.
"""

import math
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'rod_board')
W, H = 200, 220

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
WIRE = '#2B3138'
GRIP = '#2A2D33'
COPPER = '#C26A2E'
INK = '#1B2430'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="skyRain" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A5866"/><stop offset="1" stop-color="#8E9AA4"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="groundWet" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8F8160"/><stop offset="1" stop-color="#6E6248"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="poleNear" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#A9A69E"/><stop offset="0.45" stop-color="#D9D6CE"/><stop offset="1" stop-color="#8F8C84"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="fibre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F7A15A"/><stop offset="0.35" stop-color="#FFC48A"/><stop offset="1" stop-color="#C9561A"/></linearGradient>
  <linearGradient id="pvc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9CED2"/><stop offset="0.35" stop-color="#F4F6F7"/><stop offset="1" stop-color="#9AA2A8"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="strip" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8F989F"/><stop offset="0.5" stop-color="#D5DADE"/><stop offset="1" stop-color="#848C93"/></linearGradient>
  <linearGradient id="rust" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A1C"/><stop offset="0.5" stop-color="#A65A2A"/><stop offset="1" stop-color="#5E2F16"/></linearGradient>
  <linearGradient id="brass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFE7A0"/><stop offset="0.5" stop-color="#D9A93A"/><stop offset="1" stop-color="#8E6A1C"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0A774"/><stop offset="0.5" stop-color="#C26A2E"/><stop offset="1" stop-color="#7E3F16"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9965E"/><stop offset="1" stop-color="#9E6B38"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3E7BB0"/><stop offset="1" stop-color="#2A5E8E"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEFF2"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF4B0"/><stop offset="1" stop-color="#FFD34E" stop-opacity="0"/></radialGradient>
  <radialGradient id="mud" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#5A4128"/><stop offset="0.8" stop-color="#6E5236"/><stop offset="1" stop-color="#7A5C3C" stop-opacity="0.6"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def card_open(sky='sky'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def clouds(x, y, s=1.0, fill='#FFFFFF', op=0.9):
    return (f'<g fill="{fill}" opacity="{op}"><ellipse cx="{x}" cy="{y}" rx="{f(22 * s)}" ry="{f(8 * s)}"/>'
            f'<ellipse cx="{f(x + 15 * s)}" cy="{f(y - 6 * s)}" rx="{f(15 * s)}" ry="{f(9 * s)}"/></g>')


def trees(y, fill='#7FA36A'):
    blobs = ''.join(f'<ellipse cx="{x}" cy="{f(y - r * 0.55)}" rx="{f(r * 1.3)}" ry="{r}"/>'
                    for x, r in [(8, 12), (30, 9), (52, 14), (96, 8), (198, 9)])
    return f'<g fill="{fill}" opacity="0.75">{blobs}</g>'


def qpt(p0, p1, p2, t):
    a = (1 - t) ** 2
    b = 2 * t * (1 - t)
    c = t * t
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(10 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#FFF4B0" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.4 * s)}" fill="#FFFFFF"/>')


# --------------------------------------------------------------------------
# The line: a PCC pole on the right, an oblique cross-arm, three conductors
# running off to the left. The pole always carries its earthing strip.
# --------------------------------------------------------------------------

GY = 196       # ground line
PX = 168       # pole centre
PW = 14
TOP = ((-4, 3), (80, 14), (PX, 4))          # top phase (pole-top insulator)
FAR = ((-4, 20), (90, 33), (192, 15))       # far phase (behind the pole)
NEAR = ((-4, 36), (66, 52), (146, 33))      # near phase


def near_at(x):
    """The near conductor's point at card x (bisection on the curve)."""
    lo, hi = 0.0, 1.0
    for _ in range(40):
        mid = (lo + hi) / 2
        if qpt(*NEAR, mid)[0] < x:
            lo = mid
        else:
            hi = mid
    return qpt(*NEAR, lo)


def wire(p, w=2.0):
    (x0, y0), (cx, cy), (x1, y1) = p
    return f'<path d="M{x0} {y0} Q{cx} {cy} {x1} {y1}" stroke="{WIRE}" stroke-width="{w}" fill="none"/>'


def insulator(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


def earth_strip(rusty=False):
    """The pole's earthing strip down its left face into the ground."""
    # 6 wide so the bright strip and the rusted one read apart on a phone.
    x = PX - PW / 2 + 0.5
    if not rusty:
        return (f'<rect x="{x}" y="112" width="6" height="{GY - 112 + 4}" fill="url(#strip)"/>'
                + ''.join(f'<circle cx="{x + 3}" cy="{y}" r="1.2" fill="#6F777E"/>' for y in (120, 150, 186)))
    # Rusted through near the foot: flaking, a gap, a loose end standing off.
    return (f'<rect x="{x}" y="112" width="6" height="62" fill="url(#rust)"/>'
            f'<path d="M{x} 174 L{x + 6} 174 L{x + 4.5} 179 L{x + 1.5} 176 Z" fill="#7A3E1A"/>'
            f'<path d="M{x + 1.5} 184 L{x - 4} {GY + 4} L{x + 1.5} {GY + 4} L{x + 6} 186 Z" fill="url(#rust)"/>'
            + ''.join(f'<circle cx="{f(x + dx)}" cy="{y}" r="{r}" fill="#D9823A" opacity="0.9"/>'
                      for dx, y, r in ((1.5, 124, 1.5), (4.5, 140, 1.2), (1, 158, 1.6), (4, 168, 1.3), (3, 132, 1)))
            + f'<circle cx="{x + 3}" cy="150" r="1.2" fill="#5E2F16"/>')


def line_scene(sky='sky', rain=False, strip_rusty=False, clouds_at=None):
    out = card_open(sky)
    if rain:
        out.append(clouds(40, 30, 1.6, '#3A4652', 0.9) + clouds(130, 18, 1.8, '#46525E', 0.9))
    else:
        for cx, cy, s in clouds_at or [(36, 92, 0.8), (120, 76, 0.7)]:
            out.append(clouds(cx, cy, s))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#{"groundWet" if rain else "ground"})"/>')
    out.append(trees(GY + 1, '#5E7F55' if rain else '#7FA36A'))
    # Far phase behind the pole, then the pole, cross-arm, the other phases.
    out.append(wire(FAR, 1.6))
    out.append(insulator(192, 34, 0.85))
    out.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(earth_strip(strip_rusty))
    out.append('<path d="M136 56 L204 28 L204 34 L136 62 Z" fill="url(#steelArm)"/>')
    out.append(f'<path d="M{PX} 50 L{PX - 18} 74" stroke="#5F676F" stroke-width="2.4"/>')
    out.append(insulator(PX, 14, 0.85))
    out.append(wire(TOP, 1.8))
    out.append(insulator(146, 52))
    out.append(wire(NEAR, 2.2))
    for y in (150, 176):
        out.append(f'<rect x="{PX + PW / 2}" y="{y}" width="6" height="2.4" rx="1" fill="#6F777E"/>')
    return out


def rain_over(out):
    streaks = ''.join(f'<path d="M{x} {y} l-5 12"/>' for x, y in
                      [(12 + (i * 37) % 196, (i * 53) % 210) for i in range(46)])
    out.append(f'<g stroke="#DCE6EE" stroke-width="1.1" stroke-linecap="round" opacity="0.7">{streaks}</g>')
    out.append('<ellipse cx="60" cy="206" rx="26" ry="3.5" fill="#B9C6D0" opacity="0.6"/><ellipse cx="146" cy="212" rx="20" ry="3" fill="#B9C6D0" opacity="0.6"/>')


# --------------------------------------------------------------------------
# The worker, side view facing right.
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


def worker(fx, gy, hands, pose='stand', props=''):
    """[hands] = (back hand, front hand) in card coords; [props] is drawn
    between the back arm and the body (e.g. a held paper)."""
    g = []
    if pose == 'crouch':
        hip = (fx - 2, gy - 19)
        sh = (fx + 9, gy - 42)
        head = (fx + 15, gy - 50)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 2} {gy - 3} L{fx - 11} {gy - 2}" stroke="#222B37" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 10} {gy - 16} L{fx + 8} {gy - 2}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{fx - 17} {gy - 5} L{fx - 8} {gy - 5} L{fx - 8} {gy} L{fx - 17} {gy} Z" fill="{BOOT}"/>'
                 f'<path d="M{fx + 5} {gy - 4} L{fx + 15} {gy - 4} L{fx + 15} {gy} L{fx + 5} {gy} Z" fill="{BOOT}"/>')
    elif pose == 'climb':
        hip = (fx, gy - 30)
        sh = (fx + 2, gy - 56)
        head = (fx + 4, gy - 64)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 4} {gy - 1}" stroke="#222B37" stroke-width="7" stroke-linecap="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 9} {gy - 20} L{fx + 6} {gy - 13}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{fx - 9}" y="{gy - 4}" width="10" height="5" rx="2" fill="{BOOT}"/><rect x="{fx + 2}" y="{gy - 16}" width="10" height="5" rx="2" fill="{BOOT}"/>')
    else:
        hip = (fx, gy - 30)
        sh = (fx + 1, gy - 56)
        head = (fx + 3, gy - 64)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 5} {gy - 15} L{fx - 7} {gy - 2}" stroke="#222B37" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 5} {gy - 15} L{fx + 6} {gy - 2}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{fx - 13}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/><rect x="{fx + 1}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/>')
    (bx, by), (hx, hy) = hands
    g.append(_arm(sh[0] - 2, sh[1] + 3, bx, by))
    g.append(props)
    # Torso from shoulder to hip.
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy)
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    # Head and helmet (visor to the right).
    hx0, hy0 = head
    g.append(f'<rect x="{hx0 - 3}" y="{hy0 + 4}" width="6" height="6" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="{hx0}" cy="{hy0}" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M{hx0 - 7} {hy0 + 1} Q{hx0 - 7} {hy0 + 6} {hx0 - 3} {hy0 + 7} L{hx0 - 3} {hy0 + 1} Z" fill="{HAIR}"/>')
    g.append(f'<path d="M{hx0 - 8} {hy0 - 1} A8 8 0 0 1 {hx0 + 8} {hy0 - 1} Z" fill="{HELMET}"/>'
             f'<rect x="{hx0 - 8}" y="{hy0 - 2.4}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<circle cx="{hx0 + 4}" cy="{hy0 + 1}" r="1.1" fill="{HAIR}"/>')
    g.append(_arm(sh[0] + 1, sh[1] + 3, hx, hy, bend=-1))
    return ''.join(g)


# --------------------------------------------------------------------------
# The rod (drawn along +x from its butt, then placed by a transform).
# --------------------------------------------------------------------------

def rod_local(L, w, kind='std', label=None, defects=()):
    """A discharge rod L long, stick w thick, butt at 0, head at L.
    Returns (svg, cable lug point local)."""
    s = []
    hw = w / 2
    if kind == 'std':
        grip = 3.4 * w
        s.append(f'<rect x="0" y="{f(-hw - 0.6)}" width="{f(grip)}" height="{f(w + 1.2)}" rx="{f(hw)}" fill="{GRIP}"/>')
        s.append(''.join(f'<path d="M{f(grip * k)} {f(-hw - 0.6)} L{f(grip * k)} {f(hw + 0.6)}" stroke="#3E434B" stroke-width="{f(w * 0.12)}"/>'
                         for k in (0.25, 0.45, 0.65, 0.85)))
        s.append(f'<rect x="{f(grip)}" y="{f(-hw)}" width="{f(L - grip - 1.6 * w)}" height="{f(w)}" fill="url(#fibre)"/>')
        s.append(f'<path d="M{f(grip)} {f(-hw * 0.45)} L{f(L - 1.6 * w)} {f(-hw * 0.45)}" stroke="#FFFFFF" stroke-opacity="0.45" stroke-width="{f(w * 0.12)}"/>')
        if label:
            lx, lw = grip + 1.0 * w, 4.8 * w
            s.append(f'<rect x="{f(lx)}" y="{f(-hw - 0.4)}" width="{f(lw)}" height="{f(w + 0.8)}" rx="1" fill="url(#paper)" stroke="{INK}" stroke-width="0.5"/>')
            s.append(f'<text x="{f(lx + lw / 2)}" y="{f(hw * 0.62)}" font-family="sans-serif" font-size="{f(w * 0.86)}" font-weight="800" '
                     f'text-anchor="middle" fill="{INK}">{label}</text>')
        for d in defects:
            s.append(d)
        # Steel head and hook.
        hx = L - 1.6 * w
        s.append(f'<rect x="{f(hx)}" y="{f(-hw - 0.8)}" width="{f(1.6 * w)}" height="{f(w + 1.6)}" rx="1.2" fill="url(#steel)" stroke="#6F777E" stroke-width="0.4"/>')
        k = max(w * 0.7, 2.6)
        s.append(f'<path d="M{f(L)} 0 L{f(L + 1.6 * k)} 0 Q{f(L + 3.4 * k)} 0 {f(L + 3.4 * k)} {f(-1.7 * k)} '
                 f'Q{f(L + 3.4 * k)} {f(-3.3 * k)} {f(L + 1.8 * k)} {f(-3.3 * k)}" stroke="url(#steel)" stroke-width="{f(max(w * 0.42, 1.8))}" '
                 f'fill="none" stroke-linecap="round"/>')
        lug = (hx + 0.6 * w, hw + 0.8)
        s.append(f'<circle cx="{f(lug[0])}" cy="{f(lug[1])}" r="{f(max(w * 0.22, 1))}" fill="#6F777E"/>')
        return ''.join(s), lug
    # PVC water-pipe jugaad: grey pipe with couplers, a bent bolt for a hook
    # bound on with black tape, a thin flexible wire for an "earth".
    s.append(f'<rect x="0" y="{f(-hw)}" width="{f(L)}" height="{f(w)}" fill="url(#pvc)"/>')
    for cx in (L * 0.34, L * 0.68):
        s.append(f'<rect x="{f(cx - w * 0.6)}" y="{f(-hw - w * 0.18)}" width="{f(w * 1.2)}" height="{f(w * 1.36)}" rx="{f(w * 0.2)}" fill="url(#pvc)" stroke="#8E969C" stroke-width="0.5"/>')
    for d in defects:
        s.append(d)
    k = max(w * 0.7, 2.6)
    s.append(f'<path d="M{f(L - 2.2 * w)} {f(hw * 0.2)} L{f(L + 1.4 * k)} 0 Q{f(L + 3.2 * k)} 0 {f(L + 3.2 * k)} {f(-1.6 * k)} '
             f'Q{f(L + 3.2 * k)} {f(-3.1 * k)} {f(L + 1.8 * k)} {f(-3.1 * k)}" stroke="#7D868E" stroke-width="{f(max(w * 0.36, 1.6))}" fill="none" stroke-linecap="round"/>')
    s.append(f'<rect x="{f(L - 2.4 * w)}" y="{f(-hw - 0.6)}" width="{f(2.2 * w)}" height="{f(w + 1.2)}" rx="1" fill="#1E1F22"/>')
    s.append(''.join(f'<path d="M{f(L - 2.4 * w + w * 0.44 * i)} {f(-hw - 0.6)} l{f(w * 0.3)} {f(w + 1.2)}" stroke="#3A3C40" stroke-width="{f(w * 0.08)}"/>'
                     for i in range(5)))
    lug = (L - 1.3 * w, hw + 0.6)
    return ''.join(s), lug


def place(svg, bx, by, ang, scale=1.0):
    return f'<g transform="translate({f(bx)} {f(by)}) rotate({f(ang)}) scale({scale})">{svg}</g>'


def to_global(pt, bx, by, ang, scale=1.0):
    a = math.radians(ang)
    x, y = pt[0] * scale, pt[1] * scale
    return (bx + x * math.cos(a) - y * math.sin(a), by + x * math.sin(a) + y * math.cos(a))


def rod_on_wire(butt, wire_pt, w=3.6, kind='std'):
    """A rod from [butt] whose hook seat rests on [wire_pt]; returns (svg, lug)."""
    bx, by = butt
    ang = math.degrees(math.atan2(wire_pt[1] - by, wire_pt[0] - bx))
    k = max(w * 0.7, 2.6)
    L = math.hypot(wire_pt[0] - bx, wire_pt[1] - by) - 3.0 * k
    svg, lug = rod_local(L, w, kind)
    return place(svg, bx, by, ang), to_global(lug, bx, by, ang)


def cable(p0, p1, sag=40, w=2.2):
    mx, my = (p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + sag
    return (f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="#7E3F16" stroke-width="{f(w + 0.8)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="{COPPER}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}" stroke="#F0A774" stroke-width="{f(w * 0.3)}" fill="none" stroke-linecap="round" opacity="0.8"/>')


def clamp(x, y, s=1.0, rot=0, open_jaw=False):
    """A steel earth clamp (C-frame with a T-screw); (x, y) = jaw centre."""
    gap = 4 if open_jaw else 0
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({rot}) scale({s})">'
            f'<path d="M-3 -7 L7 -7 L7 7 L-3 7" stroke="url(#steel)" stroke-width="2.6" fill="none" stroke-linejoin="round"/>'
            f'<rect x="{-6 - gap}" y="-1.4" width="{3.4 + gap}" height="2.8" fill="#8E979F"/>'
            f'<path d="M7 0 L13 0 M13 -4 L13 4" stroke="#6F777E" stroke-width="2" stroke-linecap="round"/>'
            f'<rect x="-6.5" y="5.5" width="5" height="4" rx="1" fill="url(#copper)"/></g>')


def earth_spike(x, s=1.0):
    """A portable earth rod driven into the ground; returns (svg, clamp point)."""
    top = GY - 16 * s
    svg = (f'<ellipse cx="{x}" cy="{GY + 2}" rx="{f(6 * s)}" ry="{f(1.8 * s)}" fill="#7A6A4C" opacity="0.7"/>'
           f'<rect x="{f(x - 1.6 * s)}" y="{f(top)}" width="{f(3.2 * s)}" height="{f(18 * s)}" fill="url(#steel)"/>'
           f'<circle cx="{x}" cy="{f(top - 1.6 * s)}" r="{f(3 * s)}" fill="none" stroke="url(#steel)" stroke-width="{f(1.6 * s)}"/>')
    return svg, (x, top + 5 * s)


STRIP_CLAMP = (PX - PW / 2 + 3, 178)


# --------------------------------------------------------------------------
# Chains.
# --------------------------------------------------------------------------

def ball_chain(points, step=3.2, r=1.45, iron=False, broken_at=None):
    """Dots (brass ball chain) or oval links (iron) along a polyline."""
    s = []
    acc = 0.0
    idx = 0
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        seg = math.hypot(x1 - x0, y1 - y0)
        t = acc
        while t < seg:
            x, y = x0 + (x1 - x0) * t / seg, y0 + (y1 - y0) * t / seg
            if broken_at is None or not (broken_at[0] <= idx <= broken_at[1]):
                if iron:
                    ang = math.degrees(math.atan2(y1 - y0, x1 - x0)) + (0 if idx % 2 else 90)
                    s.append(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="2.6" ry="1.4" transform="rotate({f(ang)} {f(x)} {f(y)})" fill="none" stroke="url(#rust)" stroke-width="1.3"/>')
                    if idx % 4 == 1:
                        s.append(f'<circle cx="{f(x + 0.8)}" cy="{f(y - 0.6)}" r="0.8" fill="#D9823A"/>')
                else:
                    s.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill="url(#brass)"/>')
            idx += 1
            t += step
        acc = t - seg
    return ''.join(s)


def draped_chain(x, iron=False, broken=False, hand=None):
    """A chain thrown over the three phases at card x: over the top phase,
    across the far and near ones, its two ends hanging below the line."""
    top = qpt(*TOP, 0.42)
    xt = x
    yt = TOP[0][1] + (x + 4) / (PX + 4) * 4 + 6
    near = near_at(x + 4)
    front = [(xt, yt), (xt + 2, yt + 16), (near[0], near[1] + 1), (x + 5, near[1] + 26), (x + 3, near[1] + 48)]
    back = [(xt, yt), (xt - 3, yt + 18), (x - 4, near[1] + 2), (x - 6, near[1] + 30)]
    if hand:
        front = front[:3] + [hand]
    s = ball_chain(back, iron=iron)
    s += ball_chain(front, iron=iron, broken_at=(12, 14) if broken else None)
    del top
    return s


# --------------------------------------------------------------------------
# Round 1 — pick the rod: docket voltage vs the rod's label; no PVC jugaad.
# --------------------------------------------------------------------------

def docket(kv):
    s = ['<g>']
    s.append('<rect x="12" y="14" width="86" height="104" rx="5" fill="#7A4E2C"/>')
    s.append('<rect x="17" y="22" width="76" height="92" rx="2" fill="url(#paper)"/>')
    s.append('<rect x="40" y="9" width="30" height="11" rx="3" fill="url(#steel)" stroke="#6F777E" stroke-width="0.6"/>')
    s.append(f'<text x="55" y="38" font-family="sans-serif" font-size="9.5" font-weight="700" text-anchor="middle" fill="#5A6470">WORK ORDER</text>')
    s.append(f'<path d="M24 46 L86 46 M24 53 L72 53" stroke="#B7C0C8" stroke-width="2.2" stroke-linecap="round"/>')
    s.append(f'<text x="55" y="84" font-family="sans-serif" font-size="25" font-weight="800" text-anchor="middle" fill="{INK}">{kv}</text>')
    s.append(f'<path d="M24 96 L80 96 M24 104 L62 104" stroke="#B7C0C8" stroke-width="2.2" stroke-linecap="round"/>')
    s.append('</g>')
    return ''.join(s)


def bench_lines():
    return ''.join(f'<path d="M0 {y} Q100 {y + 4} 200 {y - 2}" stroke="#8A5A2E" stroke-width="0.8" opacity="0.5" fill="none"/>' for y in (40, 98, 132, 188))


def pick_card(kv, rod, label=None, taped=False):
    out = card_open('bench')
    out.append(bench_lines())
    out.append(docket(kv))
    if rod == 'std':
        # The rod's copper cable coiled beside it, the earth clamp on top.
        for i in range(3):
            out.append(f'<ellipse cx="150" cy="{70 + i * 3}" rx="{36 - i * 3}" ry="{20 - i * 2}" fill="none" stroke="#7E3F16" stroke-width="4.6"/>'
                       f'<ellipse cx="150" cy="{70 + i * 3}" rx="{36 - i * 3}" ry="{20 - i * 2}" fill="none" stroke="{COPPER}" stroke-width="3.2"/>')
        out.append('<path d="M114 72 Q100 120 150 142" stroke="#7E3F16" stroke-width="4.6" fill="none"/><path d="M114 72 Q100 120 150 142" stroke="#C26A2E" stroke-width="3.2" fill="none"/>')
        out.append(clamp(154, 40, 2.2, -10))
        svg, _ = rod_local(206, 15, 'std', label=label)
        out.append(place(svg, -44, 176, 0))
    else:
        # A thin household wire, twisted, its bare end where a clamp should be.
        for i in range(3):
            out.append(f'<ellipse cx="150" cy="{70 + i * 3}" rx="{34 - i * 4}" ry="{18 - i * 2}" fill="none" stroke="#2F6FD0" stroke-width="1.4"/>')
        out.append('<path d="M118 74 Q108 120 150 150" stroke="#2F6FD0" stroke-width="1.4" fill="none"/>')
        out.append('<path d="M176 64 l10 -10 M176 64 l12 -6 M176 64 l9 -13" stroke="#D08A4A" stroke-width="0.9" stroke-linecap="round"/>')
        defects = []
        if taped:
            # Snapped and taped back together.
            defects.append('<rect x="100" y="-9.2" width="20" height="18.4" rx="2" fill="#1E1F22"/>'
                           + ''.join(f'<path d="M{100 + 4 * i} -9.2 l3 18.4" stroke="#3A3C40" stroke-width="1"/>' for i in range(5))
                           + '<path d="M96 -7.5 L99 -2 L95 3 L98 7" stroke="#6F777E" stroke-width="1" fill="none"/>')
        svg, _ = rod_local(206, 15, 'pvc', defects=defects)
        out.append(place(svg, -44, 176, 0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — the 30-second check: the whole rod set laid out on one tarp.
#
# Every card is the same set (stick, copper cable, earth clamp) on the same
# tarp, in one of two layouts: A = the stick across the card (stick_ok,
# crack, cable_cut), B = the stick along the top and the clamp close
# (clamp_ok, clamp_loose, dirty). Each layout carries two of the four traps,
# so a hand (one safe card + any three traps) always shows the safe card's
# layout on a trap too — neither the backdrop nor the layout points at it.
# --------------------------------------------------------------------------

def tarp():
    return ('<rect width="200" height="220" fill="url(#tarp)"/>'
            + ''.join(f'<path d="M0 {y} L200 {y - 30}" stroke="#244F78" stroke-width="1" opacity="0.6"/>' for y in (60, 130, 200, 270))
            + ''.join(f'<path d="M{x} 0 L{x - 20} 220" stroke="#4E8AC0" stroke-width="0.6" opacity="0.35"/>' for x in range(20, 240, 18)))


def stick_defects(kind):
    """Crack or mud on the fibre stick, in the stick's local coords."""
    if kind == 'crack':
        return ['<path d="M160 -17 L168 -7 L161 -1 L172 5 L166 17" stroke="#3A1606" stroke-width="2.8" fill="none" stroke-linejoin="round"/>'
                '<path d="M168 -7 L182 -12 M161 -1 L148 4 M172 5 L186 8" stroke="#3A1606" stroke-width="1.6" fill="none"/>'
                '<g stroke="#FFF2DE" stroke-width="1" stroke-linecap="round"><path d="M170 6 l8 8"/><path d="M168 9 l5 10"/><path d="M166 -8 l-6 -10"/><path d="M163 -4 l-9 -5"/><path d="M175 4 l9 -2"/></g>']
    if kind == 'dirty':
        d = [f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="url(#mud)"/>'
             for cx, cy, rx, ry in ((140, -4, 18, 10), (182, 6, 14, 9), (214, -6, 11, 8), (160, 10, 9, 5))]
        d += [f'<path d="M{cx} {cy - 4} Q{cx + 3} {cy} {cx} {cy + 2} Q{cx - 3} {cy} {cx} {cy - 4} Z" fill="#CFE6F5" opacity="0.95"/>'
              f'<circle cx="{cx - 0.8}" cy="{cy - 0.6}" r="0.7" fill="#FFFFFF"/>'
              for cx, cy in ((126, 8), (150, -10), (196, -10), (200, 10), (228, 6), (170, -12))]
        return d
    return []


def copper_cable(path, w=7):
    return (f'<path d="{path}" stroke="#7E3F16" stroke-width="{w + 2}" fill="none" stroke-linecap="round"/>'
            f'<path d="{path}" stroke="{COPPER}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'
            f'<path d="{path}" stroke="#F0A774" stroke-width="1.6" fill="none" opacity="0.8"/>'
            f'<path d="{path}" stroke="#FFFFFF" stroke-width="{w + 0.6}" fill="none" opacity="0.18"/>')


def stick_card(kind):
    """Layout A: the stick across the card, the cable below it."""
    out = card_open('tarp')
    out.append(tarp())
    out.append(copper_cable('M-10 150 Q60 120 110 168 Q150 205 214 176'))
    if kind == 'cable_cut':
        # The sheath slit open, bare strands fanning out.
        out.append('<path d="M96 155 Q110 165 124 182" stroke="#1E3F60" stroke-width="7.4" fill="none"/>')
        out.append('<path d="M96 155 Q110 165 124 182" stroke="#E08A4E" stroke-width="3" fill="none" stroke-dasharray="1.6 1"/>')
        out.append('<g stroke="#FFC08A" stroke-width="1.3" stroke-linecap="round">'
                   + ''.join(f'<path d="M{106 + i} {164 + i} l{dx} {dy}"/>' for i, dx, dy in
                             ((0, -9, -13), (1, -3, -16), (2, 4, -15), (3, 10, -10), (1, 13, -3), (2, -13, -5), (4, 8, -16)))
                   + '</g>')
        out.append('<path d="M94 153 l6 -3 M124 184 l5 -4 M98 160 l-5 3" stroke="#F0A774" stroke-width="2" stroke-linecap="round"/>')
    svg, _ = rod_local(300, 34, 'std', defects=stick_defects(kind))
    out.append(place(svg, -40, 196, -33))
    return card_close(out)


def g_clamp(loose):
    """The rod's earth clamp lying on the tarp, close: a steel C-frame, the
    T-screw through its top arm onto the fixed jaw, the copper lug bolted to
    the back bar. Loose: screw backed out (no grip), lug off its bolt, the
    nut fallen on the tarp. Both draw the same parts in the same colours."""
    s = []
    s.append(f'<g transform="translate(104 160) rotate({-14 if loose else 0})">')
    frame = 'M34 -34 L-30 -34 L-30 34 L34 34'
    s.append(f'<path d="{frame}" stroke="#5F676F" stroke-width="15" fill="none" stroke-linejoin="round"/>')
    s.append(f'<path d="{frame}" stroke="url(#steel)" stroke-width="12" fill="none" stroke-linejoin="round"/>')
    # Fixed jaw on the bottom arm, the boss on the top arm the screw runs in.
    s.append('<rect x="20" y="18" width="18" height="10" rx="2" fill="url(#steel)" stroke="#6F777E" stroke-width="0.8"/>')
    s.append('<rect x="21" y="-44" width="16" height="20" rx="3" fill="url(#steel)" stroke="#6F777E" stroke-width="0.8"/>')
    pad = -8 if loose else 10          # pad top; closed = pressed on the jaw
    s.append(f'<rect x="25" y="-62" width="8" height="{pad + 64}" fill="url(#steel)"/>')
    s.append(''.join(f'<path d="M25 {y} l8 3" stroke="#6F777E" stroke-width="0.9"/>' for y in range(-58, pad, 5)))
    s.append(f'<rect x="19" y="{pad}" width="20" height="8" rx="2" fill="#8E979F" stroke="#5F676F" stroke-width="0.8"/>')
    s.append('<rect x="10" y="-68" width="38" height="7" rx="3" fill="url(#steel)" stroke="#5F676F" stroke-width="0.8"/>')
    # The bolt on the back bar for the cable lug.
    s.append('<circle cx="-30" cy="6" r="3" fill="#6F777E"/>')
    s.append('</g>')
    return ''.join(s)


HEXNUT = 'l7 0 l3.5 4 l-3.5 4 l-7 0 l-3.5 -4 Z" fill="url(#steel)" stroke="#5F676F" stroke-width="0.8"/>'


def clamp_card(kind):
    """Layout B: the stick along the top, the cable round to the clamp."""
    out = card_open('tarp')
    out.append(tarp())
    svg, lug = rod_local(300, 34, 'std', defects=stick_defects(kind))
    out.append(place(svg, -60, 34, 8))
    lx, ly = to_global(lug, -60, 34, 8)
    loose = kind == 'clamp_loose'
    out.append(g_clamp(loose))
    if not loose:
        # Cable from the rod head round to the lug, bolted tight.
        out.append(copper_cable(f'M{f(lx)} {f(ly)} C226 170 170 220 112 212 S50 196 46 176'))
        out.append('<path d="M38 176 L54 160 L80 158 L80 174 L56 184 Z" fill="url(#copper)" stroke="#7E3F16" stroke-width="0.8"/>')
        out.append(f'<path d="M70 162 {HEXNUT}')
    else:
        # The lug off its bolt, lying on the tarp; the nut fallen beside it.
        out.append(copper_cable(f'M{f(lx)} {f(ly)} C226 170 170 220 112 212 S50 204 30 200'))
        out.append('<g transform="rotate(24 30 200)"><path d="M22 204 L38 188 L64 186 L64 202 L40 212 Z" fill="url(#copper)" stroke="#7E3F16" stroke-width="0.8"/>'
                   '<circle cx="56" cy="194" r="3.6" fill="none" stroke="#7E3F16" stroke-width="1.4"/></g>')
        out.append(f'<path d="M150 200 {HEXNUT}')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — permit in hand, line off: discharge before anything else.
# --------------------------------------------------------------------------

def held_rod_scene(earth='strip', sky='sky', rain=False, clouds_at=None):
    out = line_scene(sky, rain=rain, clouds_at=clouds_at)
    wire_pt = near_at(98)
    butt = (40, 166)
    rod_svg, lug = rod_on_wire(butt, wire_pt)
    if earth == 'strip':
        cp = STRIP_CLAMP
        out.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=70))
        out.append(clamp(cp[0], cp[1], 0.9, 180))
    else:
        sp, cp = earth_spike(132, 1.6)
        out.append(sp)
        out.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=60))
        out.append(clamp(cp[0], cp[1], 0.9, 180))
    a = math.atan2(wire_pt[1] - butt[1], wire_pt[0] - butt[0])
    h1 = (butt[0] + math.cos(a) * 8, butt[1] + math.sin(a) * 8)
    h2 = (butt[0] + math.cos(a) * 30, butt[1] + math.sin(a) * 30)
    out.append(rod_svg)
    out.append(worker(26, GY, (h1, h2)))
    out.append(spark(wire_pt[0] + 2, wire_pt[1] - 1))
    if rain:
        rain_over(out)
    return card_close(out)


def ladder(x0, y0, x1, y1, w=10, rungs=8):
    s = [f'<path d="M{x0} {y0} L{x1} {y1} M{x0 + w} {y0 + 1} L{x1 + w} {y1 + 1}" stroke="#B0B7BD" stroke-width="2.6"/>']
    for i in range(1, rungs + 1):
        t = i / (rungs + 1)
        xa, ya = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        s.append(f'<line x1="{f(xa)}" y1="{f(ya)}" x2="{f(xa + w)}" y2="{f(ya + 1)}" stroke="#B0B7BD" stroke-width="2"/>')
    return ''.join(s)


def climb_scene(kind):
    """No rod at all: up the ladder straight to the wire / with the permit."""
    out = line_scene(clouds_at=[(40, 110, 0.8), (100, 140, 0.6)])
    out.append(ladder(118, GY, 150, 62, 10, 9))
    if kind == 'touch':
        hand = near_at(124)
        out.append(worker(134, 118, ((150, 66), (hand[0] + 1, hand[1] + 2)), 'climb'))
    else:
        paper = ('<g transform="rotate(-12 116 150)"><rect x="106" y="140" width="18" height="22" rx="1.5" fill="url(#paper)" stroke="#9AA5AD" stroke-width="0.6"/>'
                 '<path d="M109 146 L121 146 M109 150 L119 150 M109 154 L121 154" stroke="#9AA5AD" stroke-width="1"/></g>')
        out.append(worker(134, 168, ((116, 150), (150, 98)), 'climb', props=paper))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — earth first: the clamp goes on a reliable earth point first.
# --------------------------------------------------------------------------

def lying_rod(x0=6, x1=96, y=GY + 6):
    svg, lug = rod_local(x1 - x0, 3.6, 'std')
    return place(svg, x0, y, -2), to_global(lug, x0, y, -2)


def order_scene(kind):
    out = line_scene(strip_rusty=kind == 'rust', clouds_at=[(36, 92, 0.8), (108, 120, 0.6)])
    if kind in ('strip', 'rust'):
        rod_svg, lug = lying_rod()
        cp = STRIP_CLAMP
        out.append(rod_svg)
        out.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=6))
        out.append(clamp(cp[0], cp[1], 0.9, 180))
        out.append(worker(128, GY, ((cp[0] - 9, cp[1] - 2), (cp[0] - 6, cp[1] + 5)), 'crouch'))
    elif kind in ('spike', 'soil'):
        rod_svg, lug = lying_rod(6, 70)
        out.append(rod_svg)
        if kind == 'spike':
            sp, cp = earth_spike(126, 2.0)
            out.append(sp)
            out.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=6))
            out.append(clamp(cp[0], cp[1], 1.2, 180))
            out.append(worker(90, GY, ((cp[0] - 13, cp[1] - 5), (cp[0] - 11, cp[1] + 3)), 'crouch'))
        else:
            cp = (126, GY + 3)
            out.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=6))
            out.append(clamp(cp[0], cp[1], 1.2, 200))
            out.append(worker(90, GY, ((cp[0] - 13, cp[1] - 5), (cp[0] - 11, cp[1] + 1)), 'crouch'))
    elif kind == 'hook_first':
        # Hook already on the line; the clamp still in his other hand.
        sp, _ = earth_spike(132, 2.0)
        out.append(sp)
        wire_pt = near_at(98)
        butt = (40, 166)
        rod_svg, lug = rod_on_wire(butt, wire_pt)
        a = math.atan2(wire_pt[1] - butt[1], wire_pt[0] - butt[0])
        h2 = (butt[0] + math.cos(a) * 18, butt[1] + math.sin(a) * 18)
        held = (14, 166)
        out.append(cable(lug, (held[0] + 3, held[1] + 4), sag=30))
        out.append(rod_svg)
        out.append(worker(26, GY, (held, h2), props=clamp(held[0] + 2, held[1] + 3, 0.9, 90)))
        out.append(spark(wire_pt[0] + 2, wire_pt[1] - 1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — the shorting chain: after the rod, never instead of it.
# --------------------------------------------------------------------------

def hanging_rod(earth='strip'):
    """The rod left hanging on the near phase, its cable to the earth."""
    s = []
    wire_pt = near_at(120)
    butt = (wire_pt[0] - 6, wire_pt[1] + 92)
    rod_svg, lug = rod_on_wire(butt, wire_pt)
    if earth == 'strip':
        cp = STRIP_CLAMP
        s.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=40))
    else:
        sp, cp = earth_spike(140, 1.6)
        s.append(sp)
        s.append(cable(lug, (cp[0] - 4, cp[1] + 6), sag=34))
    s.append(clamp(cp[0], cp[1], 0.9, 180))
    s.append(rod_svg)
    return ''.join(s)


def chain_scene(kind):
    out = line_scene(clouds_at=[(150, 110, 0.7), (40, 150, 0.6)])
    if kind == 'rod_chain':
        out.append(hanging_rod('strip'))
        out.append(draped_chain(58))
        out.append(worker(24, GY, ((18, 168), (34, 168))))
    elif kind == 'rod_throw':
        out.append(hanging_rod('spike'))
        # The chain in flight, arcing up over the line.
        arc = [qpt((30, 130), (40, -10), (78, 60), t / 12) for t in range(13)]
        out.append(ball_chain(arc))
        out.append('<path d="M24 118 q4 -10 10 -14 M30 124 q4 -12 12 -16" stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linecap="round" opacity="0.85"/>')
        out.append(worker(22, GY, ((14, 168), (32, 126))))
    elif kind == 'chain_only':
        out.append(draped_chain(58))
        out.append(worker(24, GY, ((18, 168), (34, 168))))
    elif kind == 'iron':
        out.append(hanging_rod('spike'))
        out.append(draped_chain(58, iron=True, broken=True))
        out.append(worker(24, GY, ((18, 168), (34, 168))))
    elif kind == 'hand':
        hand = (44, 132)
        out.append(draped_chain(58, hand=hand))
        out.append(worker(26, GY, ((20, 168), hand)))
    return card_close(out)


CARDS = {
    # Round 1 — the rod's rating label vs the docket; no PVC jugaad.
    'pick_33_ok': pick_card('33 kV', 'std', '33 kV'),
    'pick_11_ok': pick_card('11 kV', 'std', '11 kV'),
    'pick_33_low': pick_card('33 kV', 'std', '11 kV'),
    'pick_11_lt': pick_card('11 kV', 'std', 'LT 440 V'),
    'pick_33_pvc': pick_card('33 kV', 'pvc'),
    'pick_11_pvc': pick_card('11 kV', 'pvc', taped=True),
    # Round 2 — the 30-second check.
    'check_stick_ok': stick_card('ok'),
    'check_clamp_ok': clamp_card('clamp_ok'),
    'check_crack': stick_card('crack'),
    'check_dirty': clamp_card('dirty'),
    'check_cable_cut': stick_card('cable_cut'),
    'check_clamp_loose': clamp_card('clamp_loose'),
    # Round 3 — a dead line still holds charge: discharge first.
    'dead_rod_strip': held_rod_scene('strip'),
    'dead_rod_spike': held_rod_scene('spike', clouds_at=[(150, 118, 0.7), (70, 96, 0.6)]),
    'dead_touch': climb_scene('touch'),
    'dead_permit': climb_scene('permit'),
    'dead_rain': held_rod_scene('spike', 'skyRain', rain=True),
    # Round 4 — earth first, then the line.
    'order_strip': order_scene('strip'),
    'order_spike': order_scene('spike'),
    'order_hook_first': order_scene('hook_first'),
    'order_soil': order_scene('soil'),
    'order_rust': order_scene('rust'),
    # Round 5 — the shorting chain after the rod.
    'chain_rod': chain_scene('rod_chain'),
    'chain_rod_throw': chain_scene('rod_throw'),
    'chain_only': chain_scene('chain_only'),
    'chain_iron': chain_scene('iron'),
    'chain_hand': chain_scene('hand'),
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
