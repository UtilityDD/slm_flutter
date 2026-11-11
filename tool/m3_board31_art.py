"""Picture cards for lesson 3.1 শেখা ("কন্ডাক্টর পরিচিতি: ACSR, AAAC").

python -I tool/m3_board31_art.py .

Writes assets/game/art/m3_board31/*.svg in the clean gradient style of
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: a conductor is told by its cut end (a zoom bubble): ACSR = grey
steel strands in the middle, aluminium round them; AAAC = all the same light
alloy; copper = orange. A sleeve's code and a drum's code are shown as the
same small shape (triangle) when they match, a different one (circle) when
they don't.

What the cards show comes from lesson 3.1 and its film script only:
  1. magnet: a magnet sticks to ACSR (steel core) and not to AAAC; the cut
     end shows the steel core; no guessing by thickness or shine;
  2. coast: in salt air or factory smoke ACSR's steel rusts — AAAC (no steel)
     is used there; heavy copper is not used overhead (aluminium is light, so
     the poles carry less and the span is longer);
  3. sleeve: ACSR and AAAC sleeves differ — match the sleeve's code to the
     conductor's, ask a senior when unsure; never force one in, never any
     connector; a wrong sleeve makes a hotspot and the line falls;
  4. strip: not one strand may be cut; no ordinary cutter on ACSR (steel
     inside); no joint on a rusty steel core; AAAC is slippery — the clamp
     must not slip;
  5. old: an old line's temper may be spoilt by sun and rain — inspect it
     closely before a new pull, pull by the sag chart (too tight snaps in
     winter); never a sudden pull, never pull past a broken strand.
The line in round 5 is drawn earthed (a portable earth on the pole): the
house rule "line work only after shutdown, PTW, test and earth" — the lesson
does not say it, so it is not put into words.

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one set of colours; the script checks every hand the dealer can
make (one safe card + any three traps).
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board31_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board31')
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
HELMET_W = '#F2F4F6'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
ALU = '#D5DCE2'
ALU_D = '#A9B3BB'
STEEL = '#5F6971'
RUST = '#9A4E24'
COPPER = '#D98A3D'
COPPER_D = '#A9632A'
MAGNET = '#D8402F'
MAGNET_D = '#A82E21'
WOOD = '#8A5A2B'
WOOD_D = '#6B4320'
TAG = '#F0C02E'
MARK = '#1E2329'
EARTH = '#3E9B4F'
HOT = '#FF7A2E'
PAPER = '#F4F1E8'

DEFS = """<defs>
  <linearGradient id="store" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5D6E7C"/><stop offset="1" stop-color="#8C9AA5"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="shop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6B6258"/><stop offset="1" stop-color="#9A9086"/></linearGradient>
  <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7B7F82"/><stop offset="1" stop-color="#5F6366"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8DB25E"/><stop offset="1" stop-color="#6E9246"/></linearGradient>
  <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3F86B8"/><stop offset="1" stop-color="#6FB0D6"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A5634"/><stop offset="1" stop-color="#5C3F25"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C3CAD0"/><stop offset="1" stop-color="#858E95"/></linearGradient>
  <linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.5" stop-color="#C9D1D8"/><stop offset="1" stop-color="#959FA8"/></linearGradient>
  <linearGradient id="cu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2B47A"/><stop offset="0.5" stop-color="#D98A3D"/><stop offset="1" stop-color="#9E5A24"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="factory" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A7E74"/><stop offset="1" stop-color="#6A6058"/></linearGradient>
  <radialGradient id="glint" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.95"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="hot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE38A"/><stop offset="0.7" stop-color="#FF7A2E" stop-opacity="0.7"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
  <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4C2"/><stop offset="0.5" stop-color="#FFD34E"/><stop offset="1" stop-color="#FFD34E" stop-opacity="0"/></radialGradient>
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


def _hand(p):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, helmet=HELMET, props_front=''):
    """The lineman: blue shirt, dark trousers, helmet, black gloves."""
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
    g.append(_hand(hb))
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
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{helmet}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, lean=0, helmet=HELMET, props_front=''):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates; lean > 0 leans the body back (pulling)."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x - lean * face * 0.4, gy - 30)
    sh = (x + 1 * face - lean * face, gy - 56 + abs(lean) * 0.2)
    head = (x + 3 * face - lean * face * 1.15, gy - 64 + abs(lean) * 0.25)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, helmet, props_front)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def section(cx, cy, r, kind='acsr'):
    """A conductor's cut end, 1 + 6 + 12 strands: acsr (steel 7 inside),
    aaac (all alloy), cu (all copper), rust (acsr, rusty core), nick (acsr,
    one outer strand cut away)."""
    sr = r / 5.0
    inner = {'acsr': STEEL, 'rust': RUST, 'nick': STEEL, 'aaac': ALU, 'cu': COPPER}[kind]
    outer = COPPER if kind == 'cu' else ALU
    edge = COPPER_D if kind == 'cu' else ALU_D
    o = [f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{WIRE}"/>']
    pts = [(cx, cy, inner)]
    for i in range(6):
        a = i * math.pi / 3
        pts.append((cx + math.cos(a) * 2 * sr, cy + math.sin(a) * 2 * sr, inner))
    for i in range(12):
        a = i * math.pi / 6 + math.pi / 12
        if kind == 'nick' and i == 1:
            continue
        pts.append((cx + math.cos(a) * 3.87 * sr, cy + math.sin(a) * 3.87 * sr, outer))
    for x, y, c in pts:
        o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(sr * 0.96)}" fill="{c}" stroke="{edge}" stroke-width="{f(sr * 0.18)}"/>')
    if kind == 'rust':
        for i in range(5):
            a = i * 1.3
            o.append(f'<circle cx="{f(cx + math.cos(a) * sr * 1.6)}" cy="{f(cy + math.sin(a) * sr * 1.6)}" r="{f(sr * 0.45)}" fill="#6E3416"/>')
    return ''.join(o)


def zoom(cx, cy, r, kind, to=None):
    """A magnifier bubble on the cut end, a leader line to the point."""
    o = []
    if to:
        o.append(f'<path d="M{f(to[0])} {f(to[1])} L{f(cx)} {f(cy)}" stroke="#FFFFFF" stroke-width="1.4" stroke-dasharray="3 2" opacity="0.85"/>')
    o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r + 4)}" fill="#FFFFFF" opacity="0.92"/>')
    o.append(section(cx, cy, r, kind))
    o.append(f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r + 4)}" fill="none" stroke="{WIRE}" stroke-width="1.6"/>')
    return ''.join(o)


def cable(x0, y0, x1, y1, w=6, metal='alu', lay=True):
    """A stranded conductor from (x0, y0) to (x1, y1)."""
    g = 'cu' if metal == 'cu' else 'alu'
    edge = COPPER_D if metal == 'cu' else ALU_D
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    ang = math.degrees(math.atan2(dy, dx))
    o = [f'<g transform="translate({f(x0)} {f(y0)}) rotate({f(ang)})">',
         f'<rect x="0" y="{f(-w / 2)}" width="{f(n)}" height="{f(w)}" rx="{f(w / 2)}" fill="url(#{g})"/>']
    if lay:
        step = w * 0.9
        k = 0.0
        while k < n - w * 0.6:
            o.append(f'<path d="M{f(k)} {f(-w / 2 + 0.4)} l{f(w * 0.55)} {f(w - 0.8)}" stroke="{edge}" stroke-width="0.8"/>')
            k += step
    o.append('</g>')
    return ''.join(o)


def magnet(x, y, ang=0, s=1.0):
    """A U-magnet, the open end (two steel tips) pointing down at (x, y)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({f(s)})">'
            f'<path d="M-7 0 L-7 -12 A7 7 0 0 1 7 -12 L7 0" stroke="{MAGNET}" stroke-width="5.4" fill="none"/>'
            f'<path d="M-7 -12 A7 7 0 0 1 7 -12" stroke="{MAGNET_D}" stroke-width="1.4" fill="none" transform="translate(0 -2.6)"/>'
            '<rect x="-9.7" y="-1" width="5.4" height="5" fill="url(#steel)"/><rect x="4.3" y="-1" width="5.4" height="5" fill="url(#steel)"/>'
            '</g>')


def pull_lines(x, y, s=1.0):
    """Little attraction arcs under the magnet's tips."""
    return (f'<g stroke="#FFFFFF" stroke-width="{f(1.2 * s)}" fill="none" stroke-linecap="round" opacity="0.9">'
            f'<path d="M{f(x - 14 * s)} {f(y - 2 * s)} q-3 3 0 6"/><path d="M{f(x + 14 * s)} {f(y - 2 * s)} q3 3 0 6"/></g>')


def glints(pts):
    return ''.join(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glint)"/>'
                   f'<path d="M{f(x - r * 0.8)} {f(y)} L{f(x + r * 0.8)} {f(y)} M{f(x)} {f(y - r * 0.8)} L{f(x)} {f(y + r * 0.8)}" stroke="#FFFFFF" stroke-width="1.1"/>'
                   for x, y, r in pts)


def drum(x, y, r=26, metal='alu', legs=True):
    """A cable drum seen end-on: wooden flange, conductor wound on the barrel."""
    g = 'cu' if metal == 'cu' else 'alu'
    o = [f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{WOOD}" stroke="{WOOD_D}" stroke-width="2"/>',
         f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.72)}" fill="url(#{g})"/>']
    for k in (0.62, 0.5, 0.38):
        o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * k)}" fill="none" stroke="{COPPER_D if metal == "cu" else ALU_D}" stroke-width="1"/>')
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.24)}" fill="{WOOD}" stroke="{WOOD_D}" stroke-width="1.4"/>')
    o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.09)}" fill="{WOOD_D}"/>')
    if legs:
        o.append(f'<path d="M{f(x - r * 0.8)} {f(y + r)} L{f(x - r * 0.95)} {GY} M{f(x + r * 0.8)} {f(y + r)} L{f(x + r * 0.95)} {GY}" stroke="{WOOD_D}" stroke-width="3"/>')
    return ''.join(o)


def tag(x, y, shape='tri'):
    """A code tag (yellow) with a code shape on it."""
    o = [f'<rect x="{f(x - 7)}" y="{f(y - 6)}" width="14" height="12" rx="2" fill="{TAG}" stroke="{WOOD_D}" stroke-width="0.8"/>']
    o.append(mark(x, y, shape, 3.6))
    return ''.join(o)


def mark(x, y, shape, s):
    if shape == 'tri':
        return f'<path d="M{f(x)} {f(y - s)} L{f(x + s)} {f(y + s * 0.8)} L{f(x - s)} {f(y + s * 0.8)} Z" fill="{MARK}"/>'
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(s * 0.85)}" fill="{MARK}"/>'


def sleeve(x, y, shape='tri', ang=0, s=1.0):
    """A compression joint sleeve (a steel-grey tube) with its code mark."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({f(s)})">'
            '<rect x="-15" y="-4.6" width="30" height="9.2" rx="2.4" fill="url(#steel)" stroke="#6F7880" stroke-width="0.8"/>'
            '<path d="M-10 -4.6 L-10 4.6 M10 -4.6 L10 4.6" stroke="#6F7880" stroke-width="0.8"/>'
            + mark(0, 0, shape, 2.6) + '</g>')


def hammer(x, y, ang=-30):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<rect x="-1.8" y="0" width="3.6" height="22" rx="1.4" fill="{WOOD}"/>'
            '<rect x="-7" y="-5" width="14" height="6" rx="1.2" fill="url(#steel)"/></g>')


def cutter(x, y, ang=0):
    """A small hand cutter (red handles) biting at (x, y)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            '<path d="M-3 0 L-1 -6 L1 -6 L3 0 Z" fill="url(#steel)"/>'
            f'<path d="M-2 0 L-6 16 M2 0 L6 16" stroke="{MAGNET}" stroke-width="3.2" stroke-linecap="round"/></g>')


def zig(x, y, s=1.0, col='#FFFFFF'):
    """Strain / impact marks."""
    return (f'<g stroke="{col}" stroke-width="{f(1.5 * s)}" stroke-linecap="round" fill="none">'
            f'<path d="M{f(x - 8 * s)} {f(y - 6 * s)} l{f(3 * s)} {f(3 * s)} l{f(-2 * s)} {f(2 * s)} l{f(3 * s)} {f(3 * s)}"/>'
            f'<path d="M{f(x + 8 * s)} {f(y - 6 * s)} l{f(-3 * s)} {f(3 * s)} l{f(2 * s)} {f(2 * s)} l{f(-3 * s)} {f(3 * s)}"/>'
            f'<path d="M{f(x)} {f(y - 10 * s)} l0 {f(4 * s)}"/></g>')


def motion(x, y, d=1, col='#FFFFFF'):
    """Speed lines: something sliding in direction d."""
    return (f'<g stroke="{col}" stroke-width="1.4" stroke-linecap="round" opacity="0.9">'
            f'<path d="M{f(x - 6 * d)} {f(y - 4)} l{f(-8 * d)} 0"/><path d="M{f(x - 4 * d)} {f(y)} l{f(-10 * d)} 0"/>'
            f'<path d="M{f(x - 6 * d)} {f(y + 4)} l{f(-8 * d)} 0"/></g>')


def hotspot(x, y, r=16):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#hot)"/>'


def pole(x, top=40, arm=True, lean=0):
    o = [f'<g transform="rotate({f(lean)} {f(x)} {GY})">',
         f'<path d="M{f(x - 4.5)} {GY} L{f(x - 3)} {top} L{f(x + 3)} {top} L{f(x + 4.5)} {GY} Z" fill="url(#pole)"/>']
    if arm:
        o.append(f'<rect x="{f(x - 16)}" y="{top + 8}" width="32" height="4" rx="1" fill="#6F7880"/>')
        for dx in (-12, 12):
            o.append(f'<rect x="{f(x + dx - 2.6)}" y="{top + 1}" width="5.2" height="8" rx="1.6" fill="url(#porcelain)"/>')
    o.append('</g>')
    return ''.join(o)


def span(x0, x1, y, sag, metal='alu', w=2.4):
    mx = (x0 + x1) / 2
    col = COPPER if metal == 'cu' else ALU_D
    return f'<path d="M{f(x0)} {f(y)} Q{f(mx)} {f(y + sag * 2)} {f(x1)} {f(y)}" stroke="{col}" stroke-width="{f(w)}" fill="none"/>'


def sea_band(y=128):
    o = [f'<rect x="0" y="{y}" width="{W}" height="{GY - y}" fill="url(#sea)"/>']
    for i, yy in enumerate((y + 8, y + 20, y + 32)):
        x0 = 6 + (i % 2) * 12
        for x in range(x0, W, 26):
            o.append(f'<path d="M{x} {yy} q4 -3 8 0 q4 3 8 0" stroke="#FFFFFF" stroke-width="1.2" fill="none" opacity="0.7"/>')
    return ''.join(o)


def factory(x=6, y=96):
    return (f'<rect x="{x}" y="{y + 30}" width="56" height="{GY - y - 30}" fill="url(#factory)"/>'
            f'<path d="M{x} {y + 30} l14 -10 l0 10 l14 -10 l0 10 l14 -10 l0 10" fill="url(#factory)"/>'
            f'<rect x="{x + 44}" y="{y - 20}" width="9" height="50" fill="url(#factory)"/>'
            + ''.join(f'<circle cx="{f(x + 48 + dx)}" cy="{f(y - 26 - dy)}" r="{f(r)}" fill="#9AA0A6" opacity="0.75"/>'
                      for dx, dy, r in ((0, 0, 7), (8, 10, 9), (18, 18, 11), (30, 22, 10)))
            + ''.join(f'<rect x="{x + 6 + i * 13}" y="{y + 40}" width="7" height="7" fill="{WIRE}" opacity="0.6"/>' for i in range(3)))


def ground(kind='ground', y=GY):
    return f'<rect y="{y}" width="{W}" height="{H - y}" fill="url(#{kind})"/>'


# --------------------------------------------------------------------------
# Round 1 — magnet: which one is ACSR? The store, a sample on the bench.
# --------------------------------------------------------------------------

def store_stage():
    out = card_open('store')
    out.append(ground('floor'))
    # Racks of drums at the back (a sleeve of colour only, no sign of type).
    out.append(drum(30, 76, 20, legs=False))
    out.append(drum(76, 76, 20, legs=False))
    out.append(f'<rect x="0" y="96" width="{W}" height="4" fill="{STEEL}"/>')
    # The bench.
    out.append(f'<rect x="64" y="150" width="136" height="9" rx="2" fill="url(#bench)"/>')
    out.append(f'<path d="M74 159 L74 {GY} M190 159 L190 {GY}" stroke="{WOOD_D}" stroke-width="4"/>')
    return out


def magnet_card(kind):
    out = store_stage()
    if kind == 'thick':
        out.append(cable(84, 140, 178, 140, 7, 'alu'))
        out.append(cable(90, 131, 180, 131, 11, 'alu', lay=False))
        out.append(magnet(150, 149, 90, 0.8))
        out.append(worker(52, ((56, 150), (96, 128)), face=1, look=8))
        out.append(zoom(162, 46, 20, 'aaac', (180, 131)))
        return card_close(out)
    if kind == 'shine':
        out.append(cable(82, 140, 182, 140, 7, 'alu'))
        out.append(magnet(150, 149, 90, 0.8))
        out.append(cable(66, 112, 112, 92, 8, 'alu', lay=False))
        out.append(glints([(84, 104, 6), (100, 97, 5), (92, 100, 3)]))
        out.append(worker(52, ((68, 112), (98, 98)), face=1, look=-8))
        out.append(zoom(162, 46, 20, 'aaac', (112, 92)))
        return card_close(out)
    metal = 'aaac' if kind == 'nostick' else 'acsr'
    end = 150 if kind == 'core' else 182
    out.append(cable(82, 140, end, 140, 8, 'alu'))
    if kind == 'stick':
        out.append(magnet(130, 136, 0, 1.0))
        out.append(pull_lines(130, 137))
        out.append(worker(52, ((56, 150), (96, 130)), face=1, look=10))
    elif kind == 'nostick':
        out.append(magnet(134, 132, 24, 1.0))
        out.append(motion(134, 120, -1))
        out.append(worker(52, ((56, 150), (112, 120)), face=1, look=10))
    else:  # core: looking at the cut end
        out.append(magnet(110, 149, 90, 0.8))
        out.append(worker(176, ((156, 132), (160, 140)), face=-1, look=16))
    out.append(zoom(162, 46, 20, metal, (end, 140)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — coast: salt air / factory smoke, which conductor goes up?
# --------------------------------------------------------------------------

def coast_stage(where):
    out = card_open('sky')
    if where == 'sea':
        out.append(sea_band(128))
        out.append(f'<path d="M30 {GY} Q52 140 74 128 L{W} 128 L{W} {GY} Z" fill="url(#ground)"/>')
    else:
        out.append(f'<rect x="0" y="128" width="{W}" height="{GY - 128}" fill="url(#grass)"/>')
        out.append(factory(4, 92))
    out.append(ground('ground'))
    out.append(pole(88, 52))
    out.append(pole(178, 52))
    return out


def coast_card(kind):
    where = 'sea' if kind in ('sea', 'acsr', 'copper') else 'smoke'
    out = coast_stage(where)
    metal = 'cu' if kind == 'copper' else 'alu'
    sec = {'sea': 'aaac', 'smoke': 'aaac', 'acsr': 'acsr', 'rusty': 'rust', 'copper': 'cu'}[kind]
    out.append(span(76, 166, 61, 6, metal))
    out.append(drum(150, 166, 24, metal))
    out.append(f'<path d="M150 145 Q120 120 76 61" stroke="{COPPER if metal == "cu" else ALU_D}" stroke-width="2.2" fill="none"/>')
    if kind == 'copper':
        out.append(worker(112, ((126, 128), (132, 134)), face=1, look=6, lean=6))
        out.append(zig(150, 136, 0.9))
    else:
        out.append(worker(112, ((124, 128), (130, 132)), face=1, look=-10))
    if kind == 'rusty':
        for x, y in ((100, 72), (122, 74), (140, 70)):
            out.append(f'<circle cx="{x}" cy="{y}" r="2.6" fill="{RUST}"/>')
    out.append(zoom(40, 44, 20, sec, (150, 166)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — sleeve: an AAAC joint on the ground, which sleeve?
# --------------------------------------------------------------------------

def site_stage(cond_mark='tri'):
    out = card_open('sky')
    out.append(f'<rect x="0" y="120" width="{W}" height="{GY - 120}" fill="url(#grass)"/>')
    out.append(ground('ground'))
    out.append(pole(150, 34))
    out.append(drum(34, 162, 26, 'alu'))
    out.append(tag(34, 128, cond_mark))
    # A spare helmet on the ground by the drum.
    out.append(f'<path d="M58 {GY} A8 8 0 0 1 74 {GY} Z" fill="{HELMET_W}"/>')
    # The two conductor ends on a stand, meeting in the middle.
    out.append(f'<path d="M86 {GY} L92 176 M176 {GY} L170 176" stroke="{WOOD_D}" stroke-width="3"/>')
    return out


def sleeve_card(kind):
    out = site_stage()
    if kind == 'hot':
        out.append(span(140, 214, 46, 4))
        out.append(f'<path d="M140 46 Q120 70 104 102 L96 {GY - 6}" stroke="{ALU_D}" stroke-width="2.4" fill="none"/>')
        out.append(sleeve(114, 80, 'circle', 62, 0.8))
        out.append(hotspot(114, 80, 18))
        out.append(cable(70, 178, 184, 178, 6, 'alu'))
        out.append(worker(66, ((70, 160), (76, 154)), face=1, look=-14))
        out.append(zoom(104, 30, 16, 'aaac', (130, 50)))
        return card_close(out)
    out.append(cable(70, 176, 126, 176, 6, 'alu'))
    out.append(cable(136, 176, 190, 176, 6, 'alu'))
    out.append(zoom(104, 30, 16, 'aaac', (126, 176)))
    if kind == 'match':
        out.append(sleeve(56, 128, 'tri', 0, 1.0))
        out.append(worker(84, ((60, 128), (52, 128)), face=-1, look=-6))
    elif kind == 'ask':
        out.append(worker(84, ((96, 150), (110, 132)), face=1, look=0))
        out.append(sleeve(114, 132, 'tri', 0, 1.0))
        out.append(worker(140, ((128, 136), (130, 150)), face=-1, look=6, helmet=HELMET_W))
    elif kind == 'force':
        out.append(sleeve(131, 176, 'circle', 0, 1.0))
        out.append(zig(131, 168, 0.9))
        out.append(hammer(130, 154, -40))
        out.append(worker(104, ((118, 150), (126, 158)), face=1, look=12))
    elif kind == 'any':
        out.append(f'<rect x="110" y="{GY - 14}" width="34" height="14" rx="2" fill="url(#bench)"/>')
        out.append(sleeve(120, GY - 16, 'circle', -14, 0.7))
        out.append(sleeve(134, GY - 15, 'tri', 10, 0.7))
        out.append(sleeve(100, 148, 'circle', 20, 0.9))
        out.append(worker(84, ((98, 150), (96, 158)), face=1, look=-18))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — strip: making the conductor end ready for the joint.
# --------------------------------------------------------------------------

def shop_stage():
    out = card_open('shop')
    out.append(ground('floor'))
    out.append(f'<rect x="20" y="146" width="180" height="9" rx="2" fill="url(#bench)"/>')
    out.append(f'<path d="M30 155 L30 {GY} M190 155 L190 {GY}" stroke="{WOOD_D}" stroke-width="4"/>')
    # The vice holding the conductor.
    out.append('<rect x="58" y="126" width="16" height="20" rx="2" fill="url(#steel)"/>')
    out.append(f'<rect x="54" y="122" width="24" height="5" rx="1" fill="{WIRE}"/>')
    return out


def strip_card(kind):
    out = shop_stage()
    sec = {'intact': 'acsr', 'clean': 'acsr', 'nick': 'nick', 'cutter': 'acsr', 'rust': 'rust', 'slip': 'aaac'}[kind]
    if kind == 'slip':
        out.append(cable(36, 132, 112, 132, 7, 'alu', lay=False))
        out.append(motion(118, 132, 1))
        out.append(worker(150, ((126, 136), (132, 128)), face=-1, look=-4))
        out.append(zoom(160, 46, 22, sec, (112, 132)))
        return card_close(out)
    out.append(cable(36, 132, 126, 132, 7, 'alu'))
    if kind in ('intact', 'nick'):
        # Outer strands opened like a fan at the end.
        for i, dy in enumerate((-9, -4, 4, 9)):
            out.append(f'<path d="M126 132 Q134 {132 + dy * 0.4} 140 {132 + dy}" stroke="{ALU_D}" stroke-width="2" fill="none"/>')
        out.append(cable(126, 132, 144, 132, 3.6, 'alu', lay=False))
        if kind == 'nick':
            out.append(f'<path d="M110 128 l6 -12" stroke="{ALU_D}" stroke-width="2"/>')
            out.append(zig(112, 126, 0.7))
        out.append(worker(164, ((140, 128), (146, 136)), face=-1, look=8))
    elif kind == 'clean':
        out.append(cable(126, 132, 142, 132, 3.6, 'alu', lay=False))
        out.append(worker(166, ((150, 136), (156, 144)), face=-1, look=18))
    elif kind == 'cutter':
        out.append(cutter(118, 132, 180))
        out.append(zig(118, 124, 0.7))
        out.append(worker(160, ((126, 146), (122, 150)), face=-1, look=10))
    elif kind == 'rust':
        out.append(cable(126, 132, 142, 132, 3.6, 'alu', lay=False))
        out.append(f'<circle cx="134" cy="132" r="1.6" fill="{RUST}"/><circle cx="139" cy="131" r="1.4" fill="{RUST}"/>')
        out.append(sleeve(154, 132, 'tri', 0, 0.9))
        out.append(worker(176, ((158, 134), (162, 130)), face=-1, look=6))
    out.append(zoom(160, 46, 22, sec, (130, 132)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — old: a new pull on an old line (earthed), under a hot sun.
# --------------------------------------------------------------------------

def field_stage():
    out = card_open('sky')
    out.append('<circle cx="36" cy="30" r="20" fill="url(#sun)"/>')
    out.append(f'<rect x="0" y="130" width="{W}" height="{GY - 130}" fill="url(#grass)"/>')
    out.append(ground('ground'))
    out.append(pole(24, 52))
    out.append(pole(176, 52))
    # Portable earth on the far pole down to a rod.
    out.append(f'<path d="M188 62 Q196 120 190 {GY - 2}" stroke="{EARTH}" stroke-width="1.8" fill="none"/>')
    out.append(f'<rect x="188" y="{GY - 6}" width="3" height="10" fill="url(#steel)"/>')
    # The tool bag with a rolled chart.
    out.append(f'<rect x="132" y="{GY - 14}" width="22" height="14" rx="3" fill="{WIRE}"/>')
    out.append(f'<rect x="136" y="{GY - 22}" width="4" height="10" rx="1" fill="{PAPER}"/>')
    # An offcut of the conductor by the bag.
    out.append(cable(156, GY - 3, 176, GY - 3, 4, 'alu'))
    return out


def old_card(kind):
    out = field_stage()
    sag = {'tight': 0, 'chart': 9, 'inspect': 9, 'yank': 9, 'frayed': 9}[kind]
    out.append(span(36, 164, 61, sag))
    if kind == 'inspect':
        out.append(f'<path d="M36 61 Q50 110 70 {GY - 30} L120 {GY - 30}" stroke="{ALU_D}" stroke-width="2.4" fill="none"/>')
        out.append(cable(78, GY - 30, 118, GY - 30, 5, 'alu'))
        out.append(worker(100, ((88, GY - 32), (108, GY - 32)), face=1, look=22))
        out.append(zoom(140, 108, 18, 'acsr', (110, GY - 30)))
    elif kind == 'chart':
        out.append(f'<rect x="88" y="124" width="22" height="16" rx="1.5" fill="{PAPER}" stroke="{WIRE}" stroke-width="0.8"/>')
        out.append(f'<path d="M91 128 Q99 138 107 128" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        out.append(worker(110, ((92, 136), (104, 136)), face=-1, look=-18))
    else:
        # A rope from the line's end down to the worker pulling it.
        out.append(f'<path d="M164 61 L88 {GY - 40}" stroke="{WOOD}" stroke-width="1.8"/>')
        lean = 10 if kind == 'yank' else 6
        out.append(worker(78, ((88, GY - 40), (92, GY - 44)), face=1, look=-14, lean=lean))
        if kind == 'yank':
            out.append(zig(160, 70, 0.9))
            out.append(motion(80, GY - 50, -1))
        elif kind == 'tight':
            out.append(zig(100, 58, 0.8))
        elif kind == 'frayed':
            out.append(f'<path d="M110 {61 + sag * 1.4} l-4 -9 M114 {61 + sag * 1.4} l3 -10" stroke="{ALU_D}" stroke-width="1.6"/>')
            out.append(zoom(140, 108, 18, 'nick', (112, 61 + sag * 1.4)))
    return card_close(out)


CARDS = {
    'magnet_stick': magnet_card('stick'),
    'magnet_core': magnet_card('core'),
    'magnet_nostick': magnet_card('nostick'),
    'magnet_thick': magnet_card('thick'),
    'magnet_shine': magnet_card('shine'),
    'coast_sea': coast_card('sea'),
    'coast_smoke': coast_card('smoke'),
    'coast_acsr': coast_card('acsr'),
    'coast_rusty': coast_card('rusty'),
    'coast_copper': coast_card('copper'),
    'sleeve_match': sleeve_card('match'),
    'sleeve_ask': sleeve_card('ask'),
    'sleeve_force': sleeve_card('force'),
    'sleeve_any': sleeve_card('any'),
    'sleeve_hot': sleeve_card('hot'),
    'strip_intact': strip_card('intact'),
    'strip_clean': strip_card('clean'),
    'strip_nick': strip_card('nick'),
    'strip_cutter': strip_card('cutter'),
    'strip_rust': strip_card('rust'),
    'strip_slip': strip_card('slip'),
    'old_inspect': old_card('inspect'),
    'old_chart': old_card('chart'),
    'old_yank': old_card('yank'),
    'old_tight': old_card('tight'),
    'old_frayed': old_card('frayed'),
}

# Safe cards and traps per round (mirrors learn_board_pack31.dart).
ROUNDS = {
    'magnet': (['magnet_stick', 'magnet_core'], ['magnet_nostick', 'magnet_thick', 'magnet_shine']),
    'coast': (['coast_sea', 'coast_smoke'], ['coast_acsr', 'coast_rusty', 'coast_copper']),
    'sleeve': (['sleeve_match', 'sleeve_ask'], ['sleeve_force', 'sleeve_any', 'sleeve_hot']),
    'strip': (['strip_intact', 'strip_clean'], ['strip_nick', 'strip_cutter', 'strip_rust', 'strip_slip']),
    'old': (['old_inspect', 'old_chart'], ['old_yank', 'old_tight', 'old_frayed']),
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
