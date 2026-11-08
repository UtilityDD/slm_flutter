"""Picture cards for ladder step 7 (lesson 1.3 শেখা, "পোলের ভাষা").

python -I tool/pole_board_art.py .

Writes assets/game/art/pole_board/*.svg — the same clean gradient style as
tool/lakshman_art.py (200 x 220 cards, rounded clip, no text in the art).
Every picture shows only what lesson 1.3 teaches:
  walk 360° before touching the pole; the base (eroded soil, standing water,
  a cracked foundation, a lean); the hammer sound test at waist height (PCC
  solid vs hollow, steel clear vs dull where rust flakes off); the visual scan
  (hairline crack, spalling with the rod showing, rust at ground level and at
  joints); hardware seen from below (bent / loose cross-arm, broken
  insulator, rusty bolts, wasp hive, bird nest, cable tangle).
The picture carries the cue (the board hides a card's name until it is
tapped): the sound test is drawn as a cut-away of the pole's inside plus the
"shape" of the sound — bright, even rings for a sound pole, short broken grey
ones for a weak one.
"""

import math
import os
import random
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'pole_board')
W, H = 200, 220


def n(v):
    """Short number for SVG."""
    s = f'{v:.1f}'
    return s[:-2] if s.endswith('.0') else s


def pts(seq):
    return ' '.join(f'{n(x)},{n(y)}' for x, y in seq)


DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8CC2E6"/><stop offset="0.75" stop-color="#DCEBF2"/><stop offset="1" stop-color="#F1F1E6"/></linearGradient>
  <linearGradient id="skyUp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4E95CF"/><stop offset="1" stop-color="#B9DCF0"/></linearGradient>
  <linearGradient id="skyGrey" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8697A6"/><stop offset="1" stop-color="#D3DBE0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B7A27A"/><stop offset="1" stop-color="#94805A"/></linearGradient>
  <linearGradient id="groundWet" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E7C5C"/><stop offset="1" stop-color="#6E5E43"/></linearGradient>
  <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#86AE5E"/><stop offset="1" stop-color="#5F8A42"/></linearGradient>
  <linearGradient id="trees" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6E9A62"/><stop offset="1" stop-color="#4F7A4A"/></linearGradient>
  <linearGradient id="pcc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#A29F96"/><stop offset="0.45" stop-color="#DAD7CF"/><stop offset="1" stop-color="#B3B0A7"/></linearGradient>
  <linearGradient id="pccSide" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B83"/><stop offset="1" stop-color="#77746D"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F7D88"/><stop offset="0.38" stop-color="#D4DDE3"/><stop offset="0.55" stop-color="#EEF3F6"/><stop offset="1" stop-color="#7C8994"/></linearGradient>
  <linearGradient id="steelDull" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6B6E70"/><stop offset="0.45" stop-color="#A9ABA8"/><stop offset="1" stop-color="#6E706F"/></linearGradient>
  <linearGradient id="rust" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C46A2B"/><stop offset="0.5" stop-color="#9A4517"/><stop offset="1" stop-color="#6E2E0E"/></linearGradient>
  <linearGradient id="rustLight" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D98A45" stop-opacity="0.9"/><stop offset="1" stop-color="#A9541F" stop-opacity="0.2"/></linearGradient>
  <linearGradient id="core" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8C887E"/><stop offset="0.5" stop-color="#ABA79C"/><stop offset="1" stop-color="#8C887E"/></linearGradient>
  <linearGradient id="void" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A241D"/><stop offset="1" stop-color="#4A3E31"/></linearGradient>
  <linearGradient id="muff" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9F9A8E"/><stop offset="0.5" stop-color="#CFCABE"/><stop offset="1" stop-color="#A39E92"/></linearGradient>
  <linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DB8C6"/><stop offset="1" stop-color="#64849A"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AD"/><stop offset="0.5" stop-color="#6D7880"/><stop offset="1" stop-color="#4C555C"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8A4F2A"/><stop offset="0.45" stop-color="#D08A55"/><stop offset="1" stop-color="#7A4322"/></linearGradient>
  <linearGradient id="vest" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E06D10"/><stop offset="0.5" stop-color="#FF8A2A"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="hive" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F6250"/><stop offset="0.5" stop-color="#B6A68A"/><stop offset="1" stop-color="#6F6250"/></linearGradient>
  <linearGradient id="ladder" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D8DEE2"/><stop offset="1" stop-color="#9CA6AD"/></linearGradient>
  <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6D0" stop-opacity="0.95"/><stop offset="1" stop-color="#FFF6D0" stop-opacity="0"/></radialGradient>
  <radialGradient id="shade" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#000000" stop-opacity="0.32"/><stop offset="1" stop-color="#000000" stop-opacity="0"/></radialGradient>
  <radialGradient id="soot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1E1A16" stop-opacity="0.75"/><stop offset="1" stop-color="#1E1A16" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def card(body, sky='sky'):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']
    out += body
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# ---------------------------------------------------------------- backdrop

def field(horizon=150, wet=False, sun=True, far_pole=True, rng_seed=3):
    """Village edge after rain: sun glow, clouds, tree line, a far line, earth."""
    r = random.Random(rng_seed)
    s = []
    if sun:
        s.append('<circle cx="40" cy="40" r="44" fill="url(#sun)"/>')
    s.append('<g fill="#FFFFFF" opacity="0.85"><ellipse cx="150" cy="34" rx="26" ry="8"/><ellipse cx="166" cy="28" rx="16" ry="8"/><ellipse cx="58" cy="62" rx="18" ry="5.5"/></g>')
    # tree line
    blobs = []
    x = -10
    while x < 215:
        rr = r.uniform(9, 16)
        blobs.append(f'<circle cx="{n(x)}" cy="{n(horizon - rr * 0.55)}" r="{n(rr)}"/>')
        x += rr * 1.2
    s.append(f'<g fill="url(#trees)" opacity="0.9">{"".join(blobs)}</g>')
    s.append(f'<rect x="0" y="{horizon - 6}" width="{W}" height="8" fill="#6F955F" opacity="0.6"/>')
    if far_pole:
        s.append(f'<rect x="20" y="{horizon - 52}" width="3" height="52" fill="#8C8F8C"/><rect x="12" y="{horizon - 50}" width="19" height="2" fill="#6E7378"/>')
        s.append(f'<path d="M-4 {horizon - 47} Q 30 {horizon - 42} 60 {horizon - 49}" stroke="#4A5058" stroke-width="0.9" fill="none" opacity="0.7"/>')
    s.append(f'<rect x="0" y="{horizon}" width="{W}" height="{H - horizon}" fill="url(#{"groundWet" if wet else "ground"})"/>')
    # grass tufts and pebbles
    for _ in range(14):
        gx, gy = r.uniform(0, W), r.uniform(horizon + 6, H - 4)
        k = 0.6 + (gy - horizon) / (H - horizon)
        s.append(f'<path d="M{n(gx)} {n(gy)} l{n(-3 * k)} {n(-6 * k)} M{n(gx)} {n(gy)} l0 {n(-8 * k)} M{n(gx)} {n(gy)} l{n(3 * k)} {n(-6 * k)}" stroke="#5F8A42" stroke-width="{n(1.3 * k)}" stroke-linecap="round"/>')
    for _ in range(8):
        gx, gy = r.uniform(0, W), r.uniform(horizon + 4, H - 4)
        s.append(f'<ellipse cx="{n(gx)}" cy="{n(gy)}" rx="{n(r.uniform(1.2, 2.6))}" ry="{n(r.uniform(0.8, 1.5))}" fill="#7D6B4C" opacity="0.7"/>')
    return s


def shadow(cx, cy, rx, ry):
    return f'<ellipse cx="{n(cx)}" cy="{n(cy)}" rx="{n(rx)}" ry="{n(ry)}" fill="url(#shade)"/>'


# ---------------------------------------------------------------- poles

def pcc_pole(cx, base, top, wb, wt, tilt=0.0, side=True):
    """Tapered PCC pole (front face + a shaded side face), base on the ground."""
    s = []
    g = f'<g transform="rotate({n(tilt)} {n(cx)} {n(base)})">' if tilt else '<g>'
    s.append(g)
    sw_b, sw_t = wb * 0.28, wt * 0.28
    if side:
        s.append(f'<polygon points="{pts([(cx + wb / 2, base), (cx + wb / 2 + sw_b, base - 2), (cx + wt / 2 + sw_t, top - 1), (cx + wt / 2, top)])}" fill="url(#pccSide)"/>')
    s.append(f'<polygon points="{pts([(cx - wb / 2, base), (cx + wb / 2, base), (cx + wt / 2, top), (cx - wt / 2, top)])}" fill="url(#pcc)"/>')
    # cast texture: faint pores
    r = random.Random(int(cx * 7 + base))
    dots = []
    for _ in range(int((base - top) / 6)):
        y = r.uniform(top + 4, base - 4)
        f = (y - top) / max(1, base - top)
        w = wt + (wb - wt) * f
        dots.append(f'<circle cx="{n(cx + r.uniform(-w / 2.6, w / 2.6))}" cy="{n(y)}" r="{n(r.uniform(0.4, 0.9))}"/>')
    s.append(f'<g fill="#8E8A80" opacity="0.55">{"".join(dots)}</g>')
    s.append('</g>')
    return s


def pcc_x(cx, base, top, wb, wt, y):
    """Half width of the pole face at height y."""
    f = (y - top) / max(1, base - top)
    return (wt + (wb - wt) * f) / 2


def steel_tube(cx, base, top, wb, wt, step_y, dull=False, tilt=0.0):
    """Stepped tubular steel pole: the lower tube, a welded collar, the upper tube."""
    grad = 'steelDull' if dull else 'steel'
    s = [f'<g transform="rotate({n(tilt)} {n(cx)} {n(base)})">' if tilt else '<g>']
    s.append(f'<rect x="{n(cx - wb / 2)}" y="{n(step_y)}" width="{n(wb)}" height="{n(base - step_y)}" fill="url(#{grad})"/>')
    s.append(f'<rect x="{n(cx - wt / 2)}" y="{n(top)}" width="{n(wt)}" height="{n(step_y - top)}" fill="url(#{grad})"/>')
    # weld collar at the step
    s.append(f'<path d="M{n(cx - wb / 2)} {n(step_y)} L{n(cx - wt / 2)} {n(step_y - 5)} L{n(cx + wt / 2)} {n(step_y - 5)} L{n(cx + wb / 2)} {n(step_y)} Z" fill="url(#{grad})"/>')
    s.append(f'<rect x="{n(cx - wb / 2)}" y="{n(step_y - 1)}" width="{n(wb)}" height="2.4" fill="#5E6870" opacity="0.6"/>')
    s.append('</g>')
    return s


def muff(cx, y, w, h, crack=False):
    """Concrete foundation collar around the pole foot."""
    s = [f'<rect x="{n(cx - w / 2)}" y="{n(y - h)}" width="{n(w)}" height="{n(h)}" fill="url(#muff)"/>',
         f'<ellipse cx="{n(cx)}" cy="{n(y)}" rx="{n(w / 2)}" ry="{n(h * 0.28)}" fill="#A39E92"/>',
         f'<ellipse cx="{n(cx)}" cy="{n(y - h)}" rx="{n(w / 2)}" ry="{n(h * 0.28)}" fill="#D8D3C7"/>']
    if crack:
        s.append(f'<path d="M{n(cx - w * 0.2)} {n(y - h - 3)} l3 {n(h * 0.25)} l-4 {n(h * 0.25)} l4 {n(h * 0.25)} l-2 {n(h * 0.3)}" stroke="#2F2B26" stroke-width="2" fill="none" stroke-linejoin="round"/>')
        s.append(f'<path d="M{n(cx - w * 0.2 + 1)} {n(y - h * 0.5)} l-7 3 l-5 -1" stroke="#2F2B26" stroke-width="1.4" fill="none"/>')
        s.append(f'<path d="M{n(cx + w * 0.26)} {n(y - h - 2)} l-3 {n(h * 0.35)} l4 {n(h * 0.3)} l-2 {n(h * 0.35)}" stroke="#2F2B26" stroke-width="1.7" fill="none" stroke-linejoin="round"/>')
        s.append(f'<polygon points="{pts([(cx + w * 0.36, y - h * 0.5), (cx + w * 0.5, y - h * 0.62), (cx + w * 0.5, y - 2), (cx + w * 0.4, y - 4)])}" fill="#7C766A"/>')
        s.append(f'<polygon points="{pts([(cx + w * 0.55, y + 4), (cx + w * 0.66, y + 1), (cx + w * 0.7, y + 6), (cx + w * 0.58, y + 8)])}" fill="#B9B3A6"/>')
    return s


def ellipse_pt(cx, cy, rx, ry, t):
    return cx + rx * math.cos(t), cy + ry * math.sin(t)


def walk_track(cx, cy, rx, ry, front, arrow_t=None):
    """Dashed walking loop round the pole (front half or back half), drawn as short arcs."""
    s = []
    segs = 22
    for i in range(segs):
        t0 = 2 * math.pi * i / segs
        t1 = t0 + 2 * math.pi / segs * 0.55
        is_front = math.sin((t0 + t1) / 2) > 0
        if is_front != front:
            continue
        a = ellipse_pt(cx, cy, rx, ry, t0)
        b = ellipse_pt(cx, cy, rx, ry, (t0 + t1) / 2)
        c = ellipse_pt(cx, cy, rx, ry, t1)
        s.append(f'M{n(a[0])} {n(a[1])} Q{n(2 * b[0] - (a[0] + c[0]) / 2)} {n(2 * b[1] - (a[1] + c[1]) / 2)} {n(c[0])} {n(c[1])}')
    out = [f'<path d="{" ".join(s)}" stroke="#2E5B3A" stroke-width="4.4" stroke-linecap="round" fill="none" opacity="0.35"/>',
           f'<path d="{" ".join(s)}" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" fill="none" opacity="0.95"/>']
    if arrow_t is not None and (math.sin(arrow_t) > 0) == front:
        x, y = ellipse_pt(cx, cy, rx, ry, arrow_t)
        dx, dy = -rx * math.sin(arrow_t), ry * math.cos(arrow_t)
        L = math.hypot(dx, dy)
        dx, dy = dx / L, dy / L
        px, py = -dy, dx
        tip = (x + dx * 7, y + dy * 7)
        out.append(f'<polygon points="{pts([tip, (x + px * 4.5, y + py * 4.5), (x - px * 4.5, y - py * 4.5)])}" fill="#FFFFFF" stroke="#2E5B3A" stroke-opacity="0.35" stroke-width="1"/>')
    return out


def pole_top(cx, top, w, arm_y, arm_w=70):
    """Simple cross-arm with insulators for a full-pole scene."""
    s = [f'<rect x="{n(cx - arm_w / 2)}" y="{n(arm_y)}" width="{n(arm_w)}" height="4" rx="1.2" fill="url(#arm)"/>']
    for ix in (cx - arm_w / 2 + 6, cx + arm_w / 2 - 6, cx):
        iy = arm_y - 7 if ix != cx else top - 6
        s.append(f'<rect x="{n(ix - 2.6)}" y="{n(iy)}" width="5.2" height="7" rx="2" fill="url(#porc)"/>')
    return s


def wires_full(cx, arm_y, arm_w=70, top=None):
    s = []
    lx, rx = cx - arm_w / 2 + 6, cx + arm_w / 2 - 6
    for x0 in (lx, rx):
        s.append(f'<path d="M-6 {n(arm_y - 4)} Q {n(x0 / 2)} {n(arm_y + 2)} {n(x0)} {n(arm_y - 7)} Q {n((x0 + W) / 2 + 20)} {n(arm_y + 3)} {W + 6} {n(arm_y - 2)}" stroke="#2B3138" stroke-width="1.3" fill="none"/>')
    if top is not None:
        s.append(f'<path d="M-6 {n(top - 2)} Q {n(cx / 2)} {n(top + 4)} {n(cx)} {n(top - 6)} Q {n((cx + W) / 2)} {n(top + 4)} {W + 6} {n(top - 1)}" stroke="#2B3138" stroke-width="1.3" fill="none"/>')
    return s


# ---------------------------------------------------------------- the worker

SKIN, SHIRT, SHIRT_B, TROUS, TROUS_B = '#A86E48', '#1F5F8F', '#184B72', '#2A3442', '#1D2530'


def limb(a, b, c, color, w):
    return f'<path d="M{n(a[0])} {n(a[1])} L{n(b[0])} {n(b[1])} L{n(c[0])} {n(c[1])}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'


POSES = {
    #          back leg (knee, foot)     front leg            back arm (elbow, hand)   front arm
    'stand': (((-3, -10), (-4.5, 0)), ((3, -10), (4.5, 0)), ((-7, -28), (-7.5, -21)), ((7, -28), (7.5, -21))),
    'walk': (((-2, -10), (-8, -1)), ((5, -10), (9, 0)), ((-7, -28), (-4, -21)), ((6, -28), (10, -22))),
    'look': (((-3, -10), (-5, 0)), ((3, -10), (5, 0)), ((-7, -28), (-7.5, -21)), ((9, -40), (5, -46))),
    'point': (((-2, -10), (-7, -1)), ((5, -10), (9, 0)), ((-7, -28), (-4, -21)), ((10, -31), (15, -27))),
    'tap': (((-3, -10), (-5, 0)), ((3, -10), (5, 0)), ((-6, -28), (-2, -24)), ((10, -29), (17, -24))),
    'climb': (((1, -10), (5, -1)), ((9, -22), (8, -13)), ((5, -44), (9, -52)), ((8, -40), (10, -47))),
    'lean': (((1, -10), (5, 0)), ((1, -10), (-4, 0)), ((-6, -28), (-4, -20)), ((10, -38), (8, -46))),
    'rung': (((1, -9), (4, 0)), ((7, -18), (8, -10)), ((5, -42), (9, -48)), ((8, -38), (10, -44))),
    'phone': (((-3, -10), (-4.5, 0)), ((3, -10), (4.5, 0)), ((-7, -28), (-7.5, -21)), ((8, -29), (4, -38))),
}


def worker(x, y, s=1.0, pose='stand', face=1, hammer=False, look_down=False, look_up=False, bag=False):
    """The player's lineman: feet at (x, y), about 50 px tall at s=1, facing +x when face=1."""
    bl, fl, ba, fa = POSES[pose]
    hip, sh = (0, -20), (0, -35)
    p = [f'<g transform="translate({n(x)} {n(y)}) scale({n(s * face)} {n(s)})">']
    p.append(limb((-2, -20), bl[0], bl[1], TROUS_B, 5))
    p.append(f'<rect x="{n(bl[1][0] - 4)}" y="{n(bl[1][1] - 2)}" width="8" height="3.6" rx="1.5" fill="#15181C"/>')
    p.append(limb((-4, -34), ba[0], ba[1], SHIRT_B, 3.8))
    p.append(f'<circle cx="{n(ba[1][0])}" cy="{n(ba[1][1])}" r="2.1" fill="{SKIN}"/>')
    # torso: full-sleeve shirt, orange vest with reflective bands
    p.append('<rect x="-7" y="-37" width="14" height="19" rx="4.5" fill="#1F5F8F"/>')
    p.append('<rect x="-6" y="-36" width="12" height="16.5" rx="3.2" fill="url(#vest)"/>')
    p.append('<rect x="-6" y="-28.5" width="12" height="1.8" fill="#E3E8EC"/><rect x="-6" y="-24.5" width="12" height="1.8" fill="#E3E8EC"/>')
    p.append('<rect x="-7" y="-20.5" width="14" height="2.6" rx="1" fill="#3A2E22"/>')
    p.append(limb((2, -20), fl[0], fl[1], TROUS, 5))
    p.append(f'<rect x="{n(fl[1][0] - 3)}" y="{n(fl[1][1] - 2)}" width="8.5" height="3.6" rx="1.5" fill="#1C1F24"/>')
    if hammer and pose == 'tap':
        hx, hy = fa[1]
        p.append(f'<line x1="{n(hx - 1)}" y1="{n(hy + 1)}" x2="{n(hx + 11)}" y2="{n(hy - 1)}" stroke="#8A5A32" stroke-width="2.4" stroke-linecap="round"/>')
        p.append(f'<rect x="{n(hx + 10)}" y="{n(hy - 6.5)}" width="5" height="11" rx="1.2" fill="#5A636B"/>')
        p.append(f'<rect x="{n(hx + 10.6)}" y="{n(hy - 6)}" width="1.6" height="10" fill="#B8C1C7"/>')
    elif hammer:
        p.append('<line x1="-7" y1="-21" x2="-9" y2="-11" stroke="#8A5A32" stroke-width="2.2" stroke-linecap="round"/><rect x="-12.5" y="-12" width="7" height="3.6" rx="1" fill="#5A636B"/>')
    p.append(limb((4, -34), fa[0], fa[1], SHIRT, 3.8))
    p.append(f'<circle cx="{n(fa[1][0])}" cy="{n(fa[1][1])}" r="2.2" fill="{SKIN}"/>')
    if pose == 'phone':
        p.append(f'<rect x="{n(fa[1][0] - 1)}" y="{n(fa[1][1] - 5)}" width="3.4" height="6" rx="0.8" fill="#20252B"/>')
    # head + helmet (tilted when looking down / up)
    rot = 14 if look_down else (-22 if look_up else 0)
    p.append(f'<g transform="rotate({rot} 0 -38)">')
    p.append(f'<circle cx="0.6" cy="-42.5" r="5.4" fill="{SKIN}"/><circle cx="3.6" cy="-43" r="0.8" fill="#2A1B12"/>')
    p.append('<path d="M-6.5 -44.5 A6.5 6.5 0 0 1 6.5 -44.5 Z" fill="#FFD34E"/><rect x="-7.5" y="-45.3" width="16" height="2.1" rx="1" fill="#E5B92E"/>')
    p.append('<path d="M-4 -48 A4 4 0 0 1 2 -50" stroke="#FFF2B3" stroke-width="1.1" fill="none"/>')
    p.append('</g>')
    p.append('</g>')
    out = ''.join(p)
    if bag:
        out = f'<g transform="translate({n(x - 18 * face * s)} {n(y)}) scale({n(s)})"><rect x="-7" y="-9" width="14" height="9" rx="2" fill="#3E4E3A"/><rect x="-4" y="-11" width="8" height="3" rx="1.5" fill="none" stroke="#2E3A2B" stroke-width="1.4"/></g>' + out
    return out


# ---------------------------------------------------------------- damage marks

def blob(cx, cy, rw, rh, r, k=16, lo=0.72, hi=1.06):
    out = []
    for i in range(k):
        t = 2 * math.pi * i / k
        rr = r.uniform(lo, hi)
        out.append((cx + rw * rr * math.cos(t), cy + rh * rr * math.sin(t)))
    return out


def rust_area(poly, seed, drips=4, flakes=0, fall_to=None, pits=True, peel=True):
    """Rust over [poly]: blotchy orange-brown, dark pits, peeling flakes, drips below."""
    r = random.Random(seed)
    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    cid = f'ra{seed}'
    s = [f'<clipPath id="{cid}"><polygon points="{pts(poly)}"/></clipPath>',
         f'<polygon points="{pts(poly)}" fill="url(#rust)"/>',
         f'<g clip-path="url(#{cid})">']
    for _ in range(int((x1 - x0) * (y1 - y0) / 40) + 4):
        bx, by = r.uniform(x0, x1), r.uniform(y0, y1)
        col = r.choice(['#D9883F', '#B9581F', '#7A3410', '#E09A55', '#8E3F14'])
        s.append(f'<polygon points="{pts(blob(bx, by, r.uniform(2, 6), r.uniform(1.5, 4), r, k=9))}" fill="{col}" opacity="{n(r.uniform(0.35, 0.7))}"/>')
    if pits:
        for _ in range(int((x1 - x0) * (y1 - y0) / 30)):
            s.append(f'<circle cx="{n(r.uniform(x0, x1))}" cy="{n(r.uniform(y0, y1))}" r="{n(r.uniform(0.5, 1.4))}" fill="#3A1505" opacity="0.85"/>')
    s.append('</g>')
    # peeling scale at the edge: lighter flakes lifting off
    for i in range(0, len(poly) if peel else 0, 3):
        px, py = poly[i]
        sz = r.uniform(2, 3.6)
        s.append(f'<polygon points="{pts([(px, py), (px + sz, py - sz * 0.6), (px + sz * 1.4, py + sz * 0.3), (px + sz * 0.3, py + sz * 0.7)])}" fill="#D9883F" stroke="#6E2E0E" stroke-width="0.5"/>')
    bottom = [p for p in poly if p[1] > y0 + (y1 - y0) * 0.6] or poly
    for _ in range(drips):
        dx, dy = r.choice(bottom)
        L = r.uniform(8, 22)
        w = r.uniform(1.2, 2.4)
        s.append(f'<path d="M{n(dx - w / 2)} {n(dy - 1)} q{n(r.uniform(-1, 1))} {n(L * 0.6)} {n(w / 2)} {n(L)} q{n(w / 2)} {n(-L * 0.4)} {n(w / 2)} {n(-L)} Z" fill="#A9541F" opacity="0.7"/>')
    for _ in range(flakes):
        fx = r.uniform(x0 - 4, x1 + 4)
        fy = y1 + r.uniform(4, (fall_to - y1) if fall_to else 20)
        sz = r.uniform(1.6, 3.2)
        s.append(f'<polygon points="{pts([(fx, fy), (fx + sz, fy - sz * 0.5), (fx + sz * 1.3, fy + sz * 0.6), (fx + sz * 0.2, fy + sz * 0.8)])}" fill="#9A4517" transform="rotate({r.randint(0, 80)} {n(fx)} {n(fy)})"/>')
    return s


def rust_patch(cx, cy, rw, rh, seed, flakes=0, fall_to=None):
    r = random.Random(seed + 1000)
    return rust_area(blob(cx, cy, rw, rh, r), seed, drips=max(2, int(rw / 4)), flakes=flakes, fall_to=fall_to, peel=rw >= 14)


def sound_rings(x, y, good, face=-1, scale=1.0):
    """The sound of the hammer: bright even rings (sound pole) or short broken grey ones."""
    s = []
    if good:
        for i, rad in enumerate((9, 16, 23)):
            rad *= scale
            a0, a1 = math.radians(-42), math.radians(42)
            x0, y0 = x + face * rad * math.cos(a0), y + rad * math.sin(a0)
            x1, y1 = x + face * rad * math.cos(a1), y + rad * math.sin(a1)
            sweep = 1 if face > 0 else 0
            d = f'M{n(x0)} {n(y0)} A{n(rad)} {n(rad)} 0 0 {sweep} {n(x1)} {n(y1)}'
            s.append(f'<path d="{d}" stroke="#5B4A12" stroke-opacity="0.35" stroke-width="4.6" fill="none" stroke-linecap="round"/>')
            s.append(f'<path d="{d}" stroke="#FFD54A" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
        s.append(f'<circle cx="{n(x)}" cy="{n(y)}" r="{n(3.4 * scale)}" fill="#FFF3B0"/>')
    else:
        for rad, segs in ((9, ((-30, -8), (8, 26))), (14, ((-20, -4), (10, 20)))):
            rad *= scale
            for a0, a1 in segs:
                a0r, a1r = math.radians(a0), math.radians(a1)
                x0, y0 = x + face * rad * math.cos(a0r), y + rad * math.sin(a0r)
                x1, y1 = x + face * rad * math.cos(a1r), y + rad * math.sin(a1r)
                sweep = 1 if face > 0 else 0
                s.append(f'<path d="M{n(x0)} {n(y0)} A{n(rad)} {n(rad)} 0 0 {sweep} {n(x1)} {n(y1)}" stroke="#7B7F84" stroke-width="2.2" fill="none" stroke-linecap="round" opacity="0.85"/>')
        r = random.Random(int(x * 13 + y))
        for _ in range(7):
            s.append(f'<circle cx="{n(x + face * r.uniform(2, 12))}" cy="{n(y + r.uniform(-6, 9))}" r="{n(r.uniform(0.7, 1.6))}" fill="#9A9488" opacity="0.8"/>')
    return s


def rebar(x, y0, y1, rusty=True):
    col = '#8C3F14' if rusty else '#6E7A84'
    hi = '#C66A2C' if rusty else '#A9B4BC'
    s = [f'<rect x="{n(x - 1.8)}" y="{n(y0)}" width="3.6" height="{n(y1 - y0)}" rx="1.2" fill="{col}"/>',
         f'<rect x="{n(x - 0.9)}" y="{n(y0)}" width="1" height="{n(y1 - y0)}" fill="{hi}" opacity="0.8"/>']
    y = y0 + 2
    ribs = []
    while y < y1 - 1:
        ribs.append(f'M{n(x - 2.2)} {n(y + 1)} L{n(x + 2.2)} {n(y - 1)}')
        y += 3.4
    s.append(f'<path d="{" ".join(ribs)}" stroke="{col}" stroke-width="1" opacity="0.9"/>')
    return s


# ---------------------------------------------------------------- round 1: walk 360° first

def walk_card(kind):
    hz = 128
    s = field(hz, rng_seed=11 + len(kind))
    cx, base, top = 108, 176, 30
    k = 1.25  # worker scale
    track = (cx, base + 4, 66, 17)
    if kind in ('walk_round', 'walk_back'):
        s += walk_track(*track, front=False)
    if kind == 'walk_back':
        # On the far side, half hidden by the pole, eyes on its foot.
        s.append(shadow(cx + 18, base - 11, 13, 3))
        s.append(worker(cx + 18, base - 12, 1.1, 'walk', face=-1, look_down=True))
    if kind == 'one_side':
        # The far side of the foot, which he never looks at, is washed out.
        r = random.Random(4)
        s.append(f'<polygon points="{pts(blob(cx + 18, base - 3, 24, 7, r))}" fill="#7A6447"/>')
        s.append(f'<polygon points="{pts(blob(cx + 18, base - 2, 18, 4.6, r))}" fill="#3E3022"/>')
        for dx, dy in [(-2, -9), (40, -4), (34, 3), (8, 4)]:
            s.append(f'<ellipse cx="{cx + dx}" cy="{base + dy}" rx="3" ry="2" fill="#8A7553"/>')
    s.append(shadow(cx + 6, base + 1, 24, 5))
    s += pcc_pole(cx, base, top, 17, 10)
    s += pole_top(cx, top, 10, top + 14, arm_w=76)
    s += wires_full(cx, top + 14, arm_w=76, top=top)
    if kind in ('walk_round', 'walk_back'):
        s += walk_track(*track, front=True, arrow_t=math.radians(52 if kind == 'walk_round' else 128))
    if kind == 'walk_round':
        s.append(shadow(cx - 40, base + 15, 14, 3.4))
        s.append(worker(cx - 40, base + 14, k, 'point', face=1, look_down=True))
    elif kind == 'climb_now':
        s.append(worker(cx - 10, base - 40, k, 'climb', face=1))
        s.append(f'<g transform="translate({cx - 46} {base + 16})"><rect x="-9" y="-11" width="18" height="11" rx="2" fill="#3E4E3A"/><rect x="-5.5" y="-14" width="11" height="4" rx="1.5" fill="none" stroke="#2E3A2B" stroke-width="1.5"/></g>')
    elif kind == 'ladder_up':
        lx0, lx1, ly = cx - 46, cx - 10, base + 16
        s.append(f'<path d="M{lx0} {ly} L{lx1 - 7} 64 M{lx0 + 11} {ly} L{lx1 + 3} 64" stroke="url(#ladder)" stroke-width="3.2" stroke-linecap="round"/>')
        rungs = []
        for i in range(1, 12):
            f = i / 12
            ya = ly - (ly - 64) * f
            xa = lx0 + (lx1 - 7 - lx0) * f
            rungs.append(f'M{n(xa)} {n(ya)} L{n(xa + 10.5)} {n(ya)}')
        s.append(f'<path d="{" ".join(rungs)}" stroke="#AEB7BD" stroke-width="2"/>')
        s.append(worker(lx0 + 7, ly - 26, k, 'rung', face=1))
    elif kind == 'lean_on':
        # Resting his shoulder on a pole he has not checked.
        s.append(shadow(cx - 18, base + 11, 14, 3.4))
        s.append(f'<g transform="rotate(14 {cx - 20} {base + 10})">' + worker(cx - 20, base + 10, k, 'lean', face=1) + '</g>')
    elif kind == 'one_side':
        s.append(shadow(cx - 50, base + 17, 14, 3.4))
        s.append(worker(cx - 50, base + 16, k, 'look', face=1, look_up=True))
    return card(s)


# ---------------------------------------------------------------- round 2: the base and the lean

def base_card(kind):
    hz = 96
    wet = kind == 'water'
    s = field(hz, wet=wet, sun=not wet, far_pole=False, rng_seed=21 + len(kind))
    if wet:
        s.insert(0, f'<rect width="{W}" height="{hz}" fill="url(#skyGrey)" opacity="0.75"/>')
    cx, gy = 100, 176
    if kind == 'lean':
        # A far pole stands plumb behind it: the lean reads against it.
        s.append(f'<rect x="160" y="{hz - 70}" width="5" height="70" fill="#9C9990"/><rect x="148" y="{hz - 66}" width="29" height="3" fill="#6E7378"/>')
    if kind == 'base_dry':
        s.append(shadow(cx + 8, gy + 4, 46, 9))
        s += muff(cx, gy, 66, 14)
        s += steel_tube(cx, gy - 12, -10, 34, 26, 70)
        s.append(f'<ellipse cx="{cx}" cy="{gy - 12}" rx="17" ry="4" fill="#6E7A84" opacity="0.6"/>')
        return card(s)
    tilt = 9 if kind == 'lean' else 0
    if kind == 'erosion':
        # The soil is washed out round the foot: a pit, the buried part showing.
        s.append(f'<ellipse cx="{cx}" cy="{gy + 4}" rx="60" ry="16" fill="#6E5B40"/>')
        s.append(f'<ellipse cx="{cx}" cy="{gy + 6}" rx="48" ry="11" fill="#4A3C2A"/>')
        s.append(f'<polygon points="{pts([(cx - 19, gy - 2), (cx + 19, gy - 2), (cx + 18, gy + 12), (cx - 18, gy + 12)])}" fill="#7E7A70"/>')
        s.append(f'<rect x="{cx - 19}" y="{gy - 2}" width="38" height="5" fill="#5E5A51" opacity="0.6"/>')
        for i, (dx, dy, rr) in enumerate([(-48, 2, 4), (44, 6, 3.5), (-30, 14, 3), (36, 15, 4.5), (52, -2, 2.6)]):
            s.append(f'<ellipse cx="{cx + dx}" cy="{gy + dy}" rx="{rr}" ry="{rr * 0.7}" fill="#8A7553"/>')
        s.append(f'<path d="M{cx - 60} {gy + 2} q8 -6 16 -2 M{cx + 44} {gy - 4} q8 -4 16 2" stroke="#5F8A42" stroke-width="1.6" fill="none"/>')
        s += pcc_pole(cx, gy - 2, -10, 38, 30)
        return card(s)
    if kind == 'water':
        s.append(shadow(cx + 6, gy + 2, 40, 8))
    elif kind == 'lean':
        s.append(f'<path d="M{cx + 18} {gy - 2} q12 -8 26 -2 q8 4 18 0" fill="#8A7553" stroke="#6E5B40" stroke-width="1.2"/>')
        s.append(f'<path d="M{cx - 30} {gy + 2} l10 -3 l8 4 l9 -2" stroke="#4A3C2A" stroke-width="1.6" fill="none"/>')
        s.append(shadow(cx + 30, gy + 4, 50, 7))
    else:
        s.append(shadow(cx + 8, gy + 4, 46, 9))
    has_muff = kind in ('base_firm', 'found_crack')
    if has_muff:
        s += muff(cx, gy, 70, 20, crack=kind == 'found_crack')
    pole_base = gy - 18 if has_muff else gy
    s += pcc_pole(cx, pole_base, -10, 38, 30, tilt=tilt)
    if kind == 'water':
        s.append(f'<ellipse cx="{cx}" cy="{gy + 4}" rx="74" ry="17" fill="url(#water)"/>')
        s.append(f'<polygon points="{pts([(cx - 19, gy + 3), (cx + 19, gy + 3), (cx + 17, gy + 18), (cx - 17, gy + 18)])}" fill="#B6B3AA" opacity="0.35"/>')
        s.append(f'<path d="M{cx - 58} {gy + 2} q10 -3 20 0 M{cx + 30} {gy + 10} q12 -3 24 0 M{cx - 40} {gy + 12} q8 -2 16 0" stroke="#E4EEF3" stroke-width="1.3" fill="none" opacity="0.85"/>')
        s.append(f'<ellipse cx="{cx - 24}" cy="{gy - 1}" rx="10" ry="2.2" fill="none" stroke="#E4EEF3" stroke-width="1" opacity="0.8"/>')
        s.append('<g stroke="#E4EEF3" stroke-width="1" opacity="0.55" stroke-linecap="round">' + ''.join(f'<line x1="{x}" y1="{y}" x2="{x - 3}" y2="{y + 9}"/>' for x in range(10, 200, 23) for y in range(10, 90, 30)) + '</g>')
    if kind == 'base_firm':
        s.append(f'<path d="M{cx - 44} {gy + 6} l-3 -7 M{cx - 44} {gy + 6} l1 -9 M{cx - 44} {gy + 6} l4 -7 M{cx + 46} {gy + 8} l-3 -7 M{cx + 46} {gy + 8} l1 -9" stroke="#5F8A42" stroke-width="1.6" stroke-linecap="round"/>')
    return card(s)


# ---------------------------------------------------------------- round 3: the hammer sound test

def sound_card(kind):
    hz = 140
    s = field(hz, sun=True, far_pole=False, rng_seed=31 + len(kind))
    px, base = 60, 206
    tap_y = base - 2.0 * 23  # the hammer at the worker's waist (s = 2)
    if kind in ('pcc_solid', 'pcc_hollow', 'no_tap'):
        s.append(shadow(px + 8, base + 2, 34, 6))
        s += pcc_pole(px, base, -10, 40, 33)
        if kind != 'no_tap':
            # Cut-away window: the pole's inside at the tap point.
            wx0, wx1, wy0, wy1 = px - 15, px + 13, tap_y - 30, tap_y + 22
            s.append(f'<rect x="{wx0 - 2}" y="{n(wy0 - 2)}" width="{wx1 - wx0 + 4}" height="{n(wy1 - wy0 + 4)}" rx="3" fill="#E9E6DE"/>')
            s.append(f'<rect x="{wx0}" y="{n(wy0)}" width="{wx1 - wx0}" height="{n(wy1 - wy0)}" rx="2" fill="url(#core)"/>')
            r = random.Random(5)
            agg = ''.join(f'<circle cx="{n(r.uniform(wx0 + 2, wx1 - 2))}" cy="{n(r.uniform(wy0 + 2, wy1 - 2))}" r="{n(r.uniform(0.8, 1.8))}"/>' for _ in range(26))
            s.append(f'<g fill="#7A766C" opacity="0.7">{agg}</g>')
            if kind == 'pcc_hollow':
                cav = [(px - 9, tap_y - 22), (px + 2, tap_y - 26), (px + 8, tap_y - 14), (px + 7, tap_y + 2), (px + 9, tap_y + 14), (px - 3, tap_y + 17), (px - 10, tap_y + 6), (px - 7, tap_y - 8)]
                s.append(f'<polygon points="{pts(cav)}" fill="url(#void)"/>')
                s.append(f'<path d="M{px - 7} {n(tap_y - 22)} l-4 -6 M{px + 8} {n(tap_y + 14)} l4 7" stroke="#3B342C" stroke-width="1.2"/>')
            s += rebar(wx0 + 5, wy0, wy1, rusty=kind == 'pcc_hollow')
            s += rebar(wx1 - 5, wy0, wy1, rusty=kind == 'pcc_hollow')
    else:
        s.append(shadow(px + 8, base + 2, 30, 6))
        s += steel_tube(px, base, -10, 30, 22, 46, dull=kind == 'steel_dull')
        if kind == 'steel_dull':
            s += rust_patch(px, tap_y + 2, 13, 18, 44, flakes=9, fall_to=base)
    if kind == 'no_tap':
        # He goes up without a single tap: the hammer still hangs on his belt.
        s.append(worker(px - 12, base - 66, 2.0, 'climb', face=1, hammer=True))
        return card(s)
    good = kind in ('pcc_solid', 'steel_ring')
    hit_x = px + (20 if kind.startswith('pcc') else 15)
    s += sound_rings(hit_x + 2, tap_y - 1, good, face=1, scale=1.25)
    wx = hit_x - 2.0 * 27 + 2 * 0  # hammer head face sits on the pole surface
    s.append(shadow(hit_x + 2.0 * 27 - 4, base + 1, 22, 4.5))
    s.append(worker(hit_x + 2.0 * 27, base, 2.0, 'tap', face=-1, hammer=True))
    return card(s)


# ---------------------------------------------------------------- round 4: the visual scan

def scan_card(kind):
    hz = 168
    s = field(hz, far_pole=True, rng_seed=41 + len(kind))
    cx, base = 100, 196
    if kind in ('pcc_clean', 'hairline', 'spalling'):
        s.append(shadow(cx + 8, base + 3, 40, 7))
        s += pcc_pole(cx, base, -12, 54, 44)
        if kind == 'hairline':
            # Fine cracks across the face; a rust stain bleeds from one.
            s.append(f'<path d="M{cx - 24} 74 l7 2 l5 -2 l6 3 l7 -1 l6 2 l9 -1" stroke="#3C3A36" stroke-width="1.15" fill="none"/>')
            s.append(f'<path d="M{cx - 22} 118 l8 -1 l6 3 l8 -2 l5 2 l9 0 l7 2" stroke="#3C3A36" stroke-width="1.1" fill="none"/>')
            s.append(f'<path d="M{cx + 3} 119 l2 6 l-1 5 l2 6" stroke="#3C3A36" stroke-width="0.9" fill="none"/>')
            s.append(f'<path d="M{cx - 6} 120 q1 10 -1 22 l3 0 q2 -12 0 -22 Z" fill="url(#rustLight)"/>')
            s.append(f'<path d="M{cx - 20} 158 l9 1 l7 -2 l9 2 l12 -1" stroke="#3C3A36" stroke-width="1" fill="none"/>')
        elif kind == 'spalling':
            hole = [(cx - 18, 96), (cx - 4, 88), (cx + 12, 92), (cx + 19, 106), (cx + 16, 128), (cx + 4, 140), (cx - 12, 136), (cx - 20, 118)]
            s.append(f'<polygon points="{pts([(x + (2.5 if x > cx else -2.5), y + (2.5 if y > 114 else -2.5)) for x, y in hole])}" fill="#BDB9AF"/>')
            s.append(f'<polygon points="{pts(hole)}" fill="#86817A"/>')
            s.append(f'<polygon points="{pts([(cx - 18, 96), (cx - 4, 88), (cx + 12, 92), (cx + 9, 97), (cx - 3, 94), (cx - 14, 101)])}" fill="#5F5B54"/>')
            r = random.Random(9)
            s.append('<g fill="#6A665E">' + ''.join(f'<circle cx="{n(r.uniform(cx - 14, cx + 14))}" cy="{n(r.uniform(94, 134))}" r="{n(r.uniform(0.8, 2))}"/>' for _ in range(18)) + '</g>')
            s.append(f'<clipPath id="spallHole"><polygon points="{pts(hole)}"/></clipPath><g clip-path="url(#spallHole)">')
            s.append(f'<polygon points="{pts([(cx - 20, 100), (cx + 20, 96), (cx + 20, 104), (cx - 20, 108)])}" fill="#6A665E" opacity="0.5"/>')
            s += rebar(cx - 9, 80, 150)
            s += rebar(cx + 8, 80, 150)
            s.append('</g>')
            s.append(f'<path d="M{cx - 10} 138 q-1 8 1 22 l2 0 q0 -12 -1 -22 Z M{cx + 7} 140 q1 10 -1 24 l2 0 q1 -12 0 -24 Z" fill="#A9541F" opacity="0.6"/>')
            for dx, dy, sz in [(-30, 4, 6), (26, 8, 5), (-12, 10, 4), (40, 2, 3.5)]:
                s.append(f'<polygon points="{pts([(cx + dx, base + dy), (cx + dx + sz, base + dy - sz * 0.7), (cx + dx + sz * 1.6, base + dy + 1), (cx + dx + sz * 0.5, base + dy + sz * 0.5)])}" fill="#A9A59C"/>')
    else:
        s.append(shadow(cx + 8, base + 3, 36, 7))
        step = 92
        s += steel_tube(cx, base, -12, 46, 36, step)
        if kind == 'steel_clean':
            s.append(f'<rect x="{cx - 23}" y="{step + 34}" width="46" height="6" rx="1" fill="#5E6870" opacity="0.5"/>')
            s += bolt_band(cx, step + 37, 46, rusty=False)
        elif kind == 'rust_ground':
            # Rust eats the foot where it meets the soil; scale flakes on the ground.
            r = random.Random(64)
            top_edge = [(cx - 23 + 46 * i / 9, base - 36 + r.uniform(-7, 7)) for i in range(10)]
            poly = [(cx - 23, base)] + top_edge + [(cx + 23, base)]
            s += rust_area(poly, 65, drips=0)
            s += rust_patch(cx + 6, base - 52, 8, 5, 66)
            hole = blob(cx - 4, base - 12, 7, 5, r, k=10)
            s.append(f'<polygon points="{pts(hole)}" fill="#1E0E05"/>')
            for dx, dy in [(-34, 6), (28, 9), (-22, 12), (36, 4), (14, 13), (-8, 15)]:
                s.append(f'<polygon points="{pts([(cx + dx, base + dy), (cx + dx + 4, base + dy - 2), (cx + dx + 5, base + dy + 2), (cx + dx + 1, base + dy + 3)])}" fill="#9A4517"/>')
        elif kind == 'rust_weld':
            # Rust bleeds from the welded joint and round the clamp bolts.
            r = random.Random(73)
            band = [(cx - 23 + 46 * i / 8, step - 4 + r.uniform(-4, 2)) for i in range(9)]
            band += [(cx + 23 - 46 * i / 8, step + 9 + r.uniform(-2, 6)) for i in range(9)]
            s += rust_area(band, 74, drips=6)
            s.append(f'<rect x="{cx - 23}" y="{step + 34}" width="46" height="6" rx="1" fill="#5E6870" opacity="0.5"/>')
            s += bolt_band(cx, step + 37, 46, rusty=True)
    return card(s)


def bolt_band(cx, y, w, rusty):
    s = [f'<rect x="{n(cx - w / 2 - 3)}" y="{n(y - 5)}" width="{n(w + 6)}" height="10" rx="2" fill="url(#arm)"/>']
    for bx in (cx - w / 2 - 6, cx + w / 2 + 6):
        s.append(f'<rect x="{n(bx - 3.5)}" y="{n(y - 6)}" width="7" height="12" rx="1.5" fill="#59636B"/>')
        s.append(f'<circle cx="{n(bx)}" cy="{n(y)}" r="2.4" fill="{"#8C3F14" if rusty else "#9CA6AD"}"/>')
        if rusty:
            s += rust_patch(bx, y + 2, 5, 5, int(bx))
    return s


# ---------------------------------------------------------------- round 5: hardware, seen from below

def top_card(kind, steel=False):
    s = ['<circle cx="170" cy="36" r="42" fill="url(#sun)"/>',
         '<g fill="#FFFFFF" opacity="0.9"><ellipse cx="40" cy="26" rx="30" ry="9"/><ellipse cx="58" cy="20" rx="18" ry="9"/><ellipse cx="156" cy="168" rx="22" ry="6"/></g>',
         '<g fill="url(#trees)"><circle cx="-6" cy="216" r="34"/><circle cx="26" cy="230" r="26"/><circle cx="206" cy="220" r="30"/></g>']
    cx = 100
    arm_y = 96
    ins_k = 1.7
    # Looking up: the pole narrows towards the sky.
    if steel:
        s.append(f'<polygon points="{pts([(cx - 19, 230), (cx + 19, 230), (cx + 13, 140), (cx - 13, 140)])}" fill="url(#steel)"/>')
        s.append(f'<polygon points="{pts([(cx - 13, 144), (cx + 13, 144), (cx + 9, 52), (cx - 9, 52)])}" fill="url(#steel)"/>')
        s.append(f'<rect x="{cx - 14}" y="138" width="28" height="5" fill="#5E6870" opacity="0.55"/>')
    else:
        s.append(f'<polygon points="{pts([(cx + 20, 230), (cx + 27, 228), (cx + 14, 52), (cx + 10, 52)])}" fill="url(#pccSide)"/>')
        s.append(f'<polygon points="{pts([(cx - 20, 230), (cx + 20, 230), (cx + 10, 52), (cx - 10, 52)])}" fill="url(#pcc)"/>')
    s += insulator(cx, 52, k=ins_k)
    s.append(f'<path d="M-6 26 Q 50 42 {cx} {n(52 - 23 * ins_k)} Q 150 42 206 24" stroke="#2B3138" stroke-width="2" fill="none"/>')
    left_drop = 26 if kind == 'arm_bent' else 0
    arm_tilt = 8 if kind == 'clamp_loose' else 0
    half = 88
    s.append(f'<g transform="rotate({arm_tilt} {cx} {arm_y + 5})">')
    s.append(f'<rect x="{cx - 2}" y="{arm_y}" width="{half + 2}" height="10" rx="1.5" fill="url(#arm)"/>')
    if left_drop:
        kink = cx - 30
        s.append(f'<polygon points="{pts([(cx + 2, arm_y), (kink, arm_y + 1), (cx - half, arm_y + left_drop), (cx - half, arm_y + left_drop + 10), (kink, arm_y + 11), (cx + 2, arm_y + 10)])}" fill="url(#arm)"/>')
        s.append(f'<path d="M{kink} {arm_y + 1} l1 10" stroke="#3E474E" stroke-width="1.4"/>')
    else:
        s.append(f'<rect x="{cx - half}" y="{arm_y}" width="{half + 2}" height="10" rx="1.5" fill="url(#arm)"/>')
        s.append(f'<rect x="{cx - half}" y="{arm_y + 7.5}" width="{2 * half}" height="2.5" fill="#3E474E" opacity="0.35"/>')
    s.append('</g>')
    # the clamp (U-bolts) holding the arm on the pole
    rusty = kind == 'clamp_loose'
    s.append(f'<rect x="{cx - 16}" y="{arm_y - 4}" width="32" height="18" rx="3.5" fill="none" stroke="#59636B" stroke-width="3.4"/>')
    for bx in (cx - 19, cx + 19):
        s.append(f'<circle cx="{bx}" cy="{arm_y + 5}" r="3.8" fill="{"#8C3F14" if rusty else "#C9D1D6"}" stroke="#3E474E" stroke-width="1.1"/>')
    if rusty:
        for bx in (cx - 19, cx + 19):
            s.append(f'<circle cx="{bx}" cy="{arm_y + 5}" r="5.4" fill="#9A4517" opacity="0.55"/>')
            s.append(f'<path d="M{bx - 1.5} {arm_y + 9} q-0.5 8 0.5 16 l1.6 0 q0.4 -8 -0.2 -16 Z M{bx + 2} {arm_y + 9} q0.6 5 -0.2 10 l1.2 0 q0.4 -5 0 -10 Z" fill="#A9541F" opacity="0.85"/>')
        # a nut gone: it lies below, the arm has slipped round the pole
        s.append(f'<rect x="{cx + 22}" y="{arm_y + 36}" width="6" height="4" rx="1" fill="#8C3F14" transform="rotate(35 {cx + 25} {arm_y + 38})"/>')
    lx, rx = cx - half + 12, cx + half - 12
    if kind == 'arm_bent':
        ly, ltilt = arm_y + 1 + (left_drop - 1) * (half - 12 - 30) / (half - 30), -math.degrees(math.atan2(left_drop - 1, half - 30))
    elif kind == 'clamp_loose':
        ly, ltilt = arm_y - (half - 12) * math.sin(math.radians(arm_tilt)), arm_tilt
    else:
        ly, ltilt = arm_y, 0
    ry = arm_y + ((half - 12) * math.sin(math.radians(arm_tilt)) if kind == 'clamp_loose' else 0)
    s += insulator(lx, ly, tilt=ltilt, k=ins_k)
    s += insulator(rx, ry, broken=kind == 'insulator_broken', tilt=arm_tilt, k=ins_k)
    lt = rt = 23 * ins_k
    s.append(f'<path d="M-6 {n(ly - lt - 10)} Q {n(lx / 2)} {n(ly - lt + 6)} {n(lx + math.sin(math.radians(ltilt)) * lt)} {n(ly - lt)}" stroke="#2B3138" stroke-width="2" fill="none"/>')
    s.append(f'<path d="M{n(rx + math.sin(math.radians(arm_tilt)) * rt)} {n(ry - rt)} Q {n((rx + W) / 2)} {n(ry - rt + 6)} 206 {n(ry - rt - 10)}" stroke="#2B3138" stroke-width="2" fill="none"/>')
    if kind == 'hive_nest':
        # Wasp hive under the arm, a bird's nest on it, cables wound round the pole.
        hx, hy = cx + 46, arm_y + 10
        s.append(f'<path d="M{hx} {hy} q-20 8 -18 32 q2 20 18 22 q16 -2 18 -22 q2 -24 -18 -32 Z" fill="url(#hive)"/>')
        s.append(f'<path d="M{hx - 15} {hy + 16} q15 5 30 0 M{hx - 17} {hy + 28} q17 5 34 0 M{hx - 13} {hy + 41} q13 4 26 0" stroke="#5A4E3E" stroke-width="1.3" fill="none"/>')
        s.append(f'<ellipse cx="{hx}" cy="{hy + 52}" rx="3.5" ry="2.6" fill="#2A241D"/>')
        for wx, wy in [(hx + 22, hy + 22), (hx - 22, hy + 34), (hx + 12, hy + 62), (hx + 28, hy + 44), (hx - 8, hy + 66)]:
            s.append(f'<ellipse cx="{wx - 0.6}" cy="{wy - 2.4}" rx="2.4" ry="1.3" fill="#FFFFFF" opacity="0.85"/><ellipse cx="{wx}" cy="{wy}" rx="3.2" ry="1.8" fill="#2A241D"/><ellipse cx="{wx + 1.6}" cy="{wy}" rx="1.2" ry="1" fill="#F2C230"/>')
        nx = cx - 52
        s.append(f'<path d="M{nx - 18} {arm_y + 1} q18 -16 36 0 Z" fill="#7A5A36"/>')
        s.append(f'<path d="M{nx - 20} {arm_y} l11 -7 M{nx - 11} {arm_y - 1} l13 -9 M{nx} {arm_y - 2} l15 -6 M{nx + 5} {arm_y + 1} l15 -2 M{nx - 15} {arm_y - 5} l-7 -5 M{nx + 8} {arm_y - 6} l6 -8" stroke="#5E4426" stroke-width="1.4" stroke-linecap="round"/>')
        for i in range(4):
            yy = 136 + i * 9
            s.append(f'<path d="M{cx - 34} {yy - 8} Q {cx} {yy + 10} {cx + 34} {yy - 4}" stroke="#16191D" stroke-width="2.2" fill="none"/>')
        s.append(f'<path d="M{cx + 34} 128 q22 10 12 32 q-8 18 14 42 M{cx - 34} 132 q-26 20 -14 52 q6 14 -10 40" stroke="#16191D" stroke-width="2.2" fill="none"/>')
        s.append(f'<rect x="{cx - 13}" y="152" width="26" height="15" rx="2" fill="#E6E2D6" stroke="#6E6A60" stroke-width="1"/>')
    return card(s, sky='skyUp')


def insulator(x, y, broken=False, tilt=0, k=1.0):
    """A pin insulator standing on (x, y): brown glazed sheds on a steel pin, 23 px tall at k=1."""
    s = [f'<g transform="translate({n(x)} {n(y)}) rotate({n(tilt)}) scale({k})">']
    s.append('<rect x="-1.6" y="-4" width="3.2" height="6" fill="#59636B"/>')
    yy = -4
    for w, h in [(14, 5), (11, 5), (8, 6)]:
        s.append(f'<ellipse cx="0" cy="{yy}" rx="{w / 2 + 1.5}" ry="2.4" fill="#8A4F2A"/>')
        s.append(f'<rect x="{-w / 2}" y="{yy - h}" width="{w}" height="{h}" rx="2" fill="url(#porc)"/>')
        yy -= h
    s.append(f'<ellipse cx="0" cy="{yy}" rx="4" ry="2" fill="#E7A773"/>')
    s.append('<path d="M-3 -14 q1 -4 0 -7" stroke="#F4D2B2" stroke-width="1.2" fill="none" opacity="0.8"/>')
    if broken:
        # A shed broken away on one side, a crack down it and a scorch mark.
        s.append(f'<polygon points="{pts([(0, -19), (10, -17), (10, -3), (4, -5), (6, -10), (1, -12)])}" fill="#7DB6DF"/>')
        s.append(f'<polygon points="{pts([(0, -19), (1, -12), (6, -10), (4, -5)])}" fill="#E9C7A6"/>')
        s.append('<path d="M-1 -20 l-2 4 l2 3 l-3 4 l2 4" stroke="#2A1A0E" stroke-width="0.9" fill="none"/>')
        s.append('<ellipse cx="-3" cy="-5" rx="6" ry="4.4" fill="url(#soot)"/>')
    s.append('</g>')
    if broken:
        for dx, dy, r in [(12, 12, 20), (18, 28, 50), (10, 44, 10)]:
            px, py = x + dx, y + dy
            s.append(f'<polygon points="{pts([(px, py), (px + 4, py - 1.5), (px + 5.5, py + 2.5), (px + 1, py + 4)])}" fill="#B9764A" transform="rotate({r} {n(px)} {n(py)})"/>')
    return s


CARDS = {
    # Round 1 — before touching the pole: one full walk round it.
    'walk_round': walk_card('walk_round'),
    'walk_back': walk_card('walk_back'),
    'climb_now': walk_card('climb_now'),
    'ladder_up': walk_card('ladder_up'),
    'lean_on': walk_card('lean_on'),
    'one_side': walk_card('one_side'),
    # Round 2 — the base is the pole's strength; a lean can break it.
    'base_firm': base_card('base_firm'),
    'base_dry': base_card('base_dry'),
    'base_erosion': base_card('erosion'),
    'base_water': base_card('water'),
    'base_lean': base_card('lean'),
    'base_crack': base_card('found_crack'),
    # Round 3 — tap at waist height: PCC solid vs hollow, steel clear vs dull.
    'sound_pcc_solid': sound_card('pcc_solid'),
    'sound_steel_ring': sound_card('steel_ring'),
    'sound_pcc_hollow': sound_card('pcc_hollow'),
    'sound_steel_dull': sound_card('steel_dull'),
    'sound_no_tap': sound_card('no_tap'),
    # Round 4 — eyes from the foot to the top.
    'scan_pcc_clean': scan_card('pcc_clean'),
    'scan_steel_clean': scan_card('steel_clean'),
    'scan_hairline': scan_card('hairline'),
    'scan_spalling': scan_card('spalling'),
    'scan_rust_ground': scan_card('rust_ground'),
    'scan_rust_weld': scan_card('rust_weld'),
    # Round 5 — hardware from below.
    'top_ok_pcc': top_card('ok'),
    'top_ok_steel': top_card('ok', steel=True),
    'top_arm_bent': top_card('arm_bent'),
    'top_insulator_broken': top_card('insulator_broken'),
    'top_clamp_loose': top_card('clamp_loose', steel=True),
    'top_hive_nest': top_card('hive_nest'),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
