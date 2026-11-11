"""Picture cards for the lesson 2.9 Learn board (হাইড্রোলিক ক্রিম্পার ও কাটার).

python -I tool/m2_board29_art.py .

Writes assets/game/art/m2_board29/*.svg in the clean gradient style of
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge, no words).

What the cards show comes from lesson 2.9 only:
  1. check: before use, look for an oil leak on the body, the pump action must
     be smooth; a battery tool's battery must be charged;
  2. die: the die selection chart says which die for which cable; every die
     is made for one size (no guessing, no "close enough" die);
  3. crimp: no finger or body part between the die and the lug; seat the die
     on the right place of the lug; pump to full pressure until the pressure
     release valve clicks open; a plain hand tool cannot do a big crimp;
  4. cut: the cable steady, think where the two cut ends will fall (not on
     your feet), safety lock closed then pump; a hacksaw is slow, the cut
     uneven;
  5. care: top up with the maker's approved oil only (no water, no other
     oil); keep dies and blades clean and lightly oiled (no rust); an oil
     leak means damaged seals -> send it for servicing at once.

Fairness (the playbook, section 4, and the step-10 / step-13 reviews): every
card of a round shares one backdrop and one set of props (the tool, the
cable, the chart, the rag, the torch...): only the act tells the safe card
from a trap. The script checks every hand the dealer can make (one safe card
+ any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand too, and the safe card's backdrop is a trap's backdrop.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board29_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board29')
W, H = 200, 220

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
PANTS_D = '#222B37'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
SHEATH = '#1E2226'
WHITE = '#FFFFFF'
RED = '#E0473A'
OIL = '#C9962E'
WATER = '#7FC4E8'
JUG = '#3F8F4E'
RUST = '#9A4B22'
TAPE = '#D9C24A'
RAG = '#ECE6D6'
WOOD = '#8A6A3E'

DEFS = """<defs>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5D6B66"/><stop offset="1" stop-color="#8C9A92"/></linearGradient>
  <linearGradient id="tarp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3E5566"/><stop offset="1" stop-color="#2C3E4C"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="toolRed" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E25A3C"/><stop offset="0.5" stop-color="#C8402B"/><stop offset="1" stop-color="#8E2A1C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="die" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9AA4AC"/><stop offset="1" stop-color="#55606A"/></linearGradient>
  <linearGradient id="tin" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#A9B1B6"/><stop offset="0.5" stop-color="#E9EDEF"/><stop offset="1" stop-color="#9BA3A9"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#A65A26"/><stop offset="0.5" stop-color="#E39A5C"/><stop offset="1" stop-color="#A65A26"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="beam" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF4B0" stop-opacity="0.75"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
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
# Props.
# --------------------------------------------------------------------------

def tarp(y=124):
    return (f'<rect x="-4" y="{y}" width="{W + 8}" height="{H - y + 4}" rx="6" fill="url(#tarp)"/>'
            f'<path d="M0 {y + 2} L{W} {y + 2}" stroke="{WHITE}" stroke-opacity="0.18" stroke-width="1.2"/>')


def arm(p0, p1, w=11, palm=False):
    """A sleeve from p0 (off the card edge) to the wrist p1, a black rubber glove."""
    (x0, y0), (x1, y1) = p0, p1
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    gx, gy = x1 + dx / n * 6, y1 + dy / n * 6
    s = (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{SHIRT}" stroke-width="{w}" stroke-linecap="round"/>'
         f'<path d="M{f(x1 - dx / n * 3)} {f(y1 - dy / n * 3)} L{f(x1 + dx / n * 1.5)} {f(y1 + dy / n * 1.5)}" stroke="{SHIRT_D}" stroke-width="{w + 1}"/>'
         f'<circle cx="{f(gx)}" cy="{f(gy)}" r="{f(w * 0.62)}" fill="{GLOVE}"/>')
    if palm:
        # One finger pointing on along the arm.
        s += f'<path d="M{f(gx)} {f(gy)} L{f(gx + dx / n * 11)} {f(gy + dy / n * 11)}" stroke="{GLOVE}" stroke-width="3.6" stroke-linecap="round"/>'
    return s


def hexagon(cx, cy, r, fill, stroke='none', sw=0):
    pts = ' '.join(f'{f(cx + r * math.cos(math.pi / 3 * i))},{f(cy + r * math.sin(math.pi / 3 * i))}' for i in range(6))
    return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'


def die_box(x, y, missing=None, rusty=False):
    """The die set: a steel case with five hex dies, small to big."""
    s = [f'<rect x="{f(x)}" y="{f(y)}" width="74" height="30" rx="4" fill="url(#die)"/>',
         f'<rect x="{f(x + 3)}" y="{f(y + 3)}" width="68" height="24" rx="3" fill="{GLOVE}"/>']
    for i, r in enumerate([5, 6, 7, 8, 9.5]):
        cx = x + 9 + i * 13.5
        if missing == i:
            continue
        s.append(hexagon(cx, y + 15, r, 'url(#steel)'))
        s.append(hexagon(cx, y + 15, r * 0.48, GLOVE))
        if rusty and i % 2 == 0:
            s.append(f'<circle cx="{f(cx + 2)}" cy="{f(y + 12)}" r="2.4" fill="{RUST}"/>')
    return ''.join(s)


def chart(x, y, ang=0, mark=None):
    """The die selection chart: rows of cable size -> die size (no words)."""
    s = [f'<g transform="translate({f(x)} {f(y)}) rotate({ang})">',
         f'<rect x="0" y="0" width="38" height="46" rx="2.5" fill="{RAG}"/>']
    for i, r in enumerate([2.4, 3.2, 4.0, 4.8]):
        yy = 7 + i * 10.5
        s.append(f'<circle cx="8" cy="{f(yy)}" r="{f(r)}" fill="{SHEATH}"/>')
        s.append(f'<path d="M15 {f(yy)} L23 {f(yy)}" stroke="{GLOVE}" stroke-width="1"/>')
        s.append(hexagon(30, yy, r + 0.6, 'none', GLOVE, 1.2))
        if mark == i:
            s.append(f'<rect x="1.5" y="{f(yy - 5)}" width="35" height="10" rx="2" fill="none" stroke="{SHIRT}" stroke-width="1.6"/>')
    s.append('</g>')
    return ''.join(s)


def rag(x, y):
    return (f'<path d="M{f(x)} {f(y)} q10 -6 20 -1 q8 4 16 0 l-2 10 q-9 4 -18 0 q-8 -3 -14 2 Z" fill="{RAG}"/>'
            f'<path d="M{f(x + 4)} {f(y + 3)} q9 -3 18 0" stroke="{GLOVE}" stroke-opacity="0.25" stroke-width="1" fill="none"/>')


def torch(x, y, ang=0, on=False):
    s = f'<g transform="translate({f(x)} {f(y)}) rotate({ang})">'
    if on:
        s += '<ellipse cx="-34" cy="0" rx="34" ry="16" fill="url(#beam)"/>'
    s += (f'<rect x="0" y="-3.5" width="22" height="7" rx="2" fill="{GLOVE}"/>'
          f'<rect x="-4" y="-5" width="6" height="10" rx="1.5" fill="url(#steel)"/></g>')
    return s


def drip(x, y, n=3):
    s = ''.join(f'<path d="M{f(x)} {f(y + i * 9)} q-2.6 4 0 6 q2.6 -2 0 -6 Z" fill="{OIL}"/>' for i in range(n))
    return s + f'<ellipse cx="{f(x + 2)}" cy="{f(y + n * 9 + 6)}" rx="16" ry="3.4" fill="{OIL}" opacity="0.8"/>'


def click_burst(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 5 * s)} {f(y + math.sin(a) * 5 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [-math.pi / 2 + (i - 2) * 0.55 for i in range(5)])
    return f'<g stroke="{WHITE}" stroke-width="{f(1.8 * s)}" stroke-linecap="round">{rays}</g>'


def motion(x, y, ang=0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({ang})" stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round" opacity="0.85">'
            '<path d="M-6 0 l0 8"/><path d="M0 -3 l0 11"/><path d="M6 0 l0 8"/></g>')


def strain(x, y):
    """Jerky, stuck pumping: zig-zag marks."""
    return (f'<g stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.9">'
            f'<path d="M{f(x)} {f(y)} l4 -4 l-3 -3 l4 -4"/><path d="M{f(x + 9)} {f(y + 2)} l4 -4 l-3 -3 l4 -4"/></g>')


def question(x, y):
    return (f'<g stroke="{WHITE}" stroke-width="2.4" stroke-linecap="round" fill="none">'
            f'<path d="M{f(x - 4)} {f(y - 4)} q0 -6 5 -6 q5 0 5 5 q0 4 -5 6 l0 4"/></g>'
            f'<circle cx="{f(x + 1)}" cy="{f(y + 11)}" r="1.6" fill="{WHITE}"/>')


# --------------------------------------------------------------------------
# The hydraulic crimper (manual pump or battery), lying flat, head on the left.
# --------------------------------------------------------------------------

def jaws(hx, hy, r=9.0, gap=0.0, dies=True):
    """The C-head ring with its two hex half-dies around (hx, hy)."""
    s = [f'<circle cx="{f(hx)}" cy="{f(hy)}" r="24" fill="{GLOVE}"/>',
         f'<circle cx="{f(hx)}" cy="{f(hy)}" r="24" fill="none" stroke="url(#steel)" stroke-width="8"/>']
    return ''.join(s), (die_pair(hx, hy, r, gap) if dies else '')


def die_pair(hx, hy, r, gap):
    a, b = r / 2, r * math.sqrt(3) / 2
    left = [(-19, -13), (-a - gap, -13), (-a - gap, -b), (-r - gap, 0), (-a - gap, b), (-a - gap, 13), (-19, 13)]
    right = [(-x, y) for x, y in left]

    def poly(pts):
        return ' '.join(f'{f(hx + x)},{f(hy + y)}' for x, y in pts)
    return (f'<polygon points="{poly(left)}" fill="url(#die)" stroke="{GLOVE}" stroke-width="0.8"/>'
            f'<polygon points="{poly(right)}" fill="url(#die)" stroke="{GLOVE}" stroke-width="0.8"/>')


def cable_lug(hx, hy, top=-6, offset=0.0, crushed=False):
    """A thick cable coming down from the top into a tinned lug: barrel at
    (hx, hy + offset), palm with its bolt hole below."""
    by = hy + offset
    s = [f'<path d="M{f(hx)} {f(top)} L{f(hx)} {f(by - 20)}" stroke="{SHEATH}" stroke-width="15"/>',
         f'<rect x="{f(hx - 6.5)}" y="{f(by - 22)}" width="13" height="5" fill="url(#copper)"/>',
         f'<rect x="{f(hx - 8)}" y="{f(by - 17)}" width="16" height="32" rx="2" fill="url(#tin)"/>',
         f'<path d="M{f(hx - 6)} {f(by + 15)} L{f(hx + 6)} {f(by + 15)} L{f(hx + 7)} {f(by + 36)} Q{f(hx)} {f(by + 42)} {f(hx - 7)} {f(by + 36)} Z" fill="url(#tin)"/>',
         f'<circle cx="{f(hx)}" cy="{f(by + 31)}" r="3.4" fill="{GLOVE}"/>']
    if crushed:
        # Squeezed out between too small dies: ears of metal and cracks.
        s.append(f'<path d="M{f(hx - 4)} {f(by - 1)} L{f(hx - 13)} {f(by - 4)} L{f(hx - 4)} {f(by + 3)} Z" fill="url(#tin)"/>')
        s.append(f'<path d="M{f(hx + 4)} {f(by - 1)} L{f(hx + 13)} {f(by - 4)} L{f(hx + 4)} {f(by + 3)} Z" fill="url(#tin)"/>')
    return ''.join(s)


def crimper_body(hx, hy, battery=False, pump_ang=0.0, valve=True, bars=4, low=False):
    """Body, ram collar and handles to the right of the head."""
    s = [f'<rect x="{f(hx + 20)}" y="{f(hy - 7)}" width="12" height="14" rx="2" fill="url(#steel)"/>',
         f'<rect x="{f(hx + 30)}" y="{f(hy - 10)}" width="58" height="20" rx="5" fill="url(#toolRed)"/>']
    if valve:
        s.append(f'<rect x="{f(hx + 64)}" y="{f(hy - 16)}" width="8" height="7" rx="1.5" fill="url(#steel)"/>')
    if battery:
        # A pistol grip down from the body and the battery pack with its gauge.
        s.append(f'<path d="M{f(hx + 72)} {f(hy + 8)} L{f(hx + 84)} {f(hy + 8)} L{f(hx + 90)} {f(hy + 42)} L{f(hx + 76)} {f(hy + 42)} Z" fill="{GLOVE}"/>')
        s.append(f'<rect x="{f(hx + 66)}" y="{f(hy + 42)}" width="36" height="20" rx="4" fill="url(#toolRed)"/>')
        s.append(f'<rect x="{f(hx + 70)}" y="{f(hy + 47)}" width="28" height="9" rx="1.5" fill="{GLOVE}"/>')
        for i in range(4):
            lit = i < bars
            col = (RED if low else WHITE) if lit else '#4A4F57'
            s.append(f'<rect x="{f(hx + 72 + i * 6.5)}" y="{f(hy + 49)}" width="5" height="5" rx="1" fill="{col}"/>')
    else:
        s.append(f'<rect x="{f(hx + 86)}" y="{f(hy - 5)}" width="62" height="11" rx="5" fill="{GLOVE}"/>')
        a = math.radians(18 + pump_ang)
        px, py = hx + 78, hy + 8
        ex, ey = px + math.cos(a) * 68, py + math.sin(a) * 68
        mx, my = px + math.cos(a) * 26, py + math.sin(a) * 26
        s.append(f'<path d="M{f(px)} {f(py)} L{f(mx)} {f(my)}" stroke="url(#steel)" stroke-width="6" stroke-linecap="round"/>')
        s.append(f'<path d="M{f(px)} {f(py)} L{f(mx)} {f(my)}" stroke="#9AA4AC" stroke-width="6" stroke-linecap="round"/>')
        s.append(f'<path d="M{f(mx)} {f(my)} L{f(ex)} {f(ey)}" stroke="{GLOVE}" stroke-width="10" stroke-linecap="round"/>')
        s.append(f'<circle cx="{f(px)}" cy="{f(py)}" r="3" fill="url(#steel)"/>')
    return ''.join(s)


def pump_end(hx, hy, pump_ang=0.0, t=0.8):
    a = math.radians(18 + pump_ang)
    px, py = hx + 78, hy + 8
    return (px + math.cos(a) * 68 * t, py + math.sin(a) * 68 * t)


def crimper(hx, hy, **kw):
    """The whole tool lying flat (no lug): head ring, closed dies, body."""
    ring, dies = jaws(hx, hy, gap=kw.pop('gap', 0.0))
    return ring + dies + crimper_body(hx, hy, **kw)


# --------------------------------------------------------------------------
# Round 1 — the pre-use check.
# --------------------------------------------------------------------------

def check_card(kind):
    out = card_open('yard')
    out.append(tarp(96))
    battery = kind in ('battery', 'flat')
    hx, hy = 44, 120
    torch_on = kind == 'look'
    out.append(rag(140, 196))
    if not torch_on:
        # Lit and lying on the tarp, unused.
        out.append(torch(176, 108, -8, on=True))
    if kind == 'drip':
        out.append(drip(hx + 56, hy + 13, 4))
    out.append(crimper(hx, hy, battery=battery, bars=1 if kind == 'flat' else 4, low=kind == 'flat',
                       pump_ang=-10 if kind == 'stiff' else 0))
    if kind == 'look':
        # Torch on the body, a glove turns the tool over: looking for a leak.
        out.append(torch(hx + 118, hy - 40, 28, on=True))
        out.append(arm((214, 40), (hx + 128, hy - 34)))
        out.append(arm((60, -10), (hx + 52, hy - 18)))
    elif kind == 'battery':
        # A finger on the gauge: all four bars lit.
        out.append(arm((40, 224), (hx + 70, hy + 72), palm=True))
        out.append(arm((214, 120), (hx + 104, hy + 34)))
    elif kind == 'drip':
        # Oil running off the body, and he lifts it for the job anyway.
        out.append(arm((214, 60), (hx + 132, hy - 6)))
        out.append(motion(hx + 140, hy - 22, 0))
    elif kind == 'flat':
        # One red bar — and the tool goes straight into the bag.
        out.append(arm((214, 120), (hx + 104, hy + 34)))
        out.append(motion(hx + 110, hy + 8, 180))
        out.append(arm((40, 224), (hx + 52, hy + 30)))
    elif kind == 'stiff':
        # The pump handle sticks; he forces it with both hands.
        ex, ey = pump_end(hx, hy, -10, 0.92)
        out.append(arm((214, 220), (ex + 4, ey + 6)))
        out.append(arm((214, 40), (hx + 140, hy - 4)))
        out.append(strain(ex - 18, ey - 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — choosing the die.
# --------------------------------------------------------------------------

def zoom(parts, ox, oy, k):
    return f'<g transform="translate({f(ox)} {f(oy)}) scale({k}) translate({f(-ox)} {f(-oy)})">' + ''.join(parts) + '</g>'


def die_card(kind):
    out = card_open('yard')
    out.append(tarp(124))
    out.append(die_box(110, 180, missing=None))
    if kind != 'chart':
        out.append(chart(152, 128, 8))
    hx, hy = 52, 76
    r = {'big': 14.0, 'small': 5.5}.get(kind, 9.0)
    ring, _ = jaws(hx, hy, dies=False)
    head = [ring, cable_lug(hx, hy, crushed=kind == 'small'), die_pair(hx, hy, r, 0.0), crimper_body(hx, hy)]
    if kind in ('match', 'big', 'small'):
        # The glove sets the die home on the barrel.
        head.append(arm((-10, 150), (hx - 24, hy + 8)))
    if kind == 'small':
        head.append(strain(hx + 12, hy - 26))
    out.append(zoom(head, hx, hy, 1.3))
    if kind == 'chart':
        # Chart held up next to the die case, a finger on the cable's row.
        out.append(chart(142, 120, -6, mark=2))
        out.append(arm((214, 96), (186, 134)))
        out.append(arm((70, 230), (140, 152), palm=True))
    elif kind in ('match', 'big'):
        out.append(arm((214, 230), (128, 188)))
    elif kind == 'guess':
        # A hand hovers over the case, picking one by eye.
        out.append(arm((214, 230), (150, 174)))
        out.append(question(160, 152))
        out.append(question(128, 162))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — pumping the crimp.
# --------------------------------------------------------------------------

def crimp_card(kind):
    out = card_open('yard')
    out.append(tarp(124))
    if kind == 'plier':
        out.append(zoom(_plier_parts(56, 80), 56, 80, 1.3))
        return card_close(out)
    # The tool tilted down to the right so both handles (and the hands on
    # them) stay on the card; the cable comes in from the top right.
    hx, hy, rot, k = 54, 64, 32, 1.12

    def T(p):
        x, y = p[0] - hx, p[1] - hy
        c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
        return (hx + k * (x * c - y * sn), hy + k * (x * sn + y * c))

    offset = 26 if kind == 'offset' else 0
    gap = 7.0 if kind == 'half' else 0.0
    pump = 6 if kind in ('click', 'clear') else 0
    ring, _ = jaws(hx, hy, dies=False)
    tool = [ring, cable_lug(hx, hy, top=-120, offset=-offset), die_pair(hx, hy, 9.0, gap), crimper_body(hx, hy, pump_ang=pump)]
    if kind == 'click':
        tool.append(click_burst(hx + 68, hy - 17, 1.3))
    if kind == 'finger':
        tool.append(f'<circle cx="{f(hx - 3)}" cy="{f(hy + 1)}" r="4.8" fill="{GLOVE}"/>')
    out.append(f'<g transform="translate({f(hx)} {f(hy)}) rotate({rot}) scale({k}) translate({f(-hx)} {f(-hy)})">' + ''.join(tool) + '</g>')
    pe = T(pump_end(hx, hy, pump, 0.86))
    grip = T((hx + 128, hy))
    if kind in ('click', 'clear', 'offset'):
        out.append(arm((90, 236), (pe[0] - 4, pe[1] + 6)))
        out.append(arm((214, 120), (grip[0] + 4, grip[1] - 4)))
        if kind == 'clear':
            out.append(motion(pe[0] - 22, pe[1] - 4, 0))
    elif kind == 'finger':
        # A glove steadies the lug from the front — its finger inside the die.
        out.append(arm((90, 236), (pe[0] - 4, pe[1] + 6)))
        out.append(arm((-10, 120), T((hx - 20, hy + 2)), w=13, palm=True))
    elif kind == 'half':
        # Dies still apart, the hand already off the pump and walking away.
        out.append(arm((100, 236), (pe[0] - 30, pe[1] + 26)))
        out.append(motion(pe[0] - 14, pe[1] + 10, 140))
        out.append(arm((214, 120), (grip[0] + 4, grip[1] - 4)))
    return card_close(out)


def _plier_parts(hx, hy):
    # The hydraulic tool left on the tarp; a plain hand crimper on the lug.
    out = [crimper(60, 168, pump_ang=-14), cable_lug(hx, hy - 10)]
    px, py = hx, hy - 4
    out.append(f'<path d="M{f(px - 7)} {f(py)} L{f(px - 30)} {f(py + 60)}" stroke="url(#steel)" stroke-width="5" stroke-linecap="round"/>')
    out.append(f'<path d="M{f(px + 7)} {f(py)} L{f(px + 26)} {f(py + 60)}" stroke="url(#steel)" stroke-width="5" stroke-linecap="round"/>')
    out.append(f'<rect x="{f(px - 10)}" y="{f(py - 5)}" width="20" height="9" rx="2" fill="url(#die)"/>')
    out.append(arm((-10, 214), (px - 28, py + 64)))
    out.append(arm((140, 230), (px + 24, py + 66)))
    out.append(strain(px + 16, py + 20))
    return out


# --------------------------------------------------------------------------
# Round 4 — cutting an armoured cable (low camera: legs, cable on trestles).
# --------------------------------------------------------------------------

GY = 186
CY = 112        # cable axis
CUT_X = 104


def trestle(x):
    return (f'<path d="M{f(x - 14)} {GY} L{f(x)} {CY + 8} L{f(x + 14)} {GY}" stroke="{WOOD}" stroke-width="4" fill="none" stroke-linecap="round"/>'
            f'<rect x="{f(x - 12)}" y="{CY + 6}" width="24" height="5" rx="1.5" fill="{WOOD}"/>')


def armoured(x0, x1, hang=False):
    """The armoured cable along the trestles; hang = the right end dangles."""
    if hang:
        d = f'M{f(x0)} {CY} L{CUT_X + 10} {CY} Q{CUT_X + 60} {CY + 6} {f(x1)} {CY + 46}'
    else:
        d = f'M{f(x0)} {CY} L{f(x1)} {CY}'
    return (f'<path d="{d}" stroke="{SHEATH}" stroke-width="16" fill="none"/>'
            f'<path d="{d}" stroke="#4A4F57" stroke-width="16" fill="none" stroke-dasharray="2 5" opacity="0.8"/>')


def worker_low(x, sep=22):
    """The worker from the chest down (the camera is low): shirt, belt,
    trousers and boots, standing behind the cable."""
    s = [f'<path d="M{f(x - 19)} -8 L{f(x + 19)} -8 L{f(x + 17)} 58 L{f(x - 17)} 58 Z" fill="url(#shirt)"/>',
         f'<rect x="{f(x - 18)}" y="54" width="36" height="6" fill="{PANTS_D}"/>']
    for i, lx in enumerate((x - sep / 2, x + sep / 2)):
        col = PANTS_D if i == 0 else PANTS
        s.append(f'<path d="M{f(lx)} 58 L{f(lx)} {GY - 7}" stroke="{col}" stroke-width="15"/>')
        s.append(f'<rect x="{f(lx - 8)}" y="{GY - 10}" width="19" height="10" rx="3" fill="{BOOT}"/>')
    return ''.join(s)


def cutter(cx, cy, lock=True, pump_ang=0.0):
    """Hydraulic cable cutter standing on its handles, blades round the cable."""
    s = [f'<rect x="{f(cx - 9)}" y="{f(cy + 14)}" width="18" height="34" rx="4" fill="url(#toolRed)"/>',
         f'<rect x="{f(cx - 5)}" y="{f(cy + 48)}" width="10" height="24" rx="4" fill="{GLOVE}"/>',
         f'<path d="M{f(cx - 12)} {f(cy + 12)} Q{f(cx - 24)} {f(cy - 8)} {f(cx - 4)} {f(cy - 16)} L{f(cx - 2)} {f(cy - 10)} Q{f(cx - 14)} {f(cy - 4)} {f(cx - 4)} {f(cy + 12)} Z" fill="url(#steel)"/>',
         f'<path d="M{f(cx + 12)} {f(cy + 12)} Q{f(cx + 24)} {f(cy - 8)} {f(cx + 4)} {f(cy - 16)} L{f(cx + 2)} {f(cy - 10)} Q{f(cx + 14)} {f(cy - 4)} {f(cx + 4)} {f(cy + 12)} Z" fill="url(#steel)"/>']
    if lock:
        s.append(f'<rect x="{f(cx - 9)}" y="{f(cy - 21)}" width="18" height="5" rx="2" fill="url(#die)"/>')
    else:
        s.append(f'<rect x="{f(cx + 6)}" y="{f(cy - 21)}" width="18" height="5" rx="2" fill="url(#die)" transform="rotate(-55 {f(cx + 8)} {f(cy - 18)})"/>')
    a = math.radians(60 + pump_ang)
    px, py = cx + 6, cy + 30
    s.append(f'<path d="M{f(px)} {f(py)} L{f(px + math.cos(a) * 44)} {f(py + math.sin(a) * 44)}" stroke="{GLOVE}" stroke-width="8" stroke-linecap="round"/>')
    return ''.join(s), (px + math.cos(a) * 40, py + math.sin(a) * 40)


def cut_card(kind):
    out = card_open('yard')
    out.append(f'<rect x="-4" y="{GY - 6}" width="{W + 8}" height="{H - GY + 10}" fill="url(#ground)"/>')
    wx = 168 if kind == 'foot' else 34
    out.append(worker_low(wx))
    out.append(trestle(54))
    # No trestle under the cut-off end: it will drop (foot) or it swings (swing).
    loose = kind in ('foot', 'swing')
    if not loose:
        out.append(trestle(160))
    hang = kind == 'swing'
    out.append(armoured(-6, 210 if not hang else 176, hang))
    sh_l, sh_r = (wx - 16, 6), (wx + 16, 6)
    k = 1.5
    if kind == 'saw':
        # A hacksaw across the armour; ragged filings fall.
        out.append(f'<path d="M{CUT_X - 34} {CY - 30} L{CUT_X + 30} {CY - 30} L{CUT_X + 30} {CY - 6} L{CUT_X - 34} {CY - 6}" stroke="url(#steel)" stroke-width="3" fill="none"/>')
        out.append(f'<path d="M{CUT_X - 34} {CY - 8} L{CUT_X + 30} {CY - 8}" stroke="{GLOVE}" stroke-width="2"/>')
        out.append(f'<rect x="{CUT_X + 28}" y="{CY - 34}" width="20" height="9" rx="3" fill="{GLOVE}"/>')
        out.append(''.join(f'<rect x="{f(CUT_X - 6 + (i * 7) % 18)}" y="{f(CY + 12 + i * 8)}" width="2.4" height="2.4" fill="#4A4F57"/>' for i in range(6)))
        out.append(arm(sh_r, (CUT_X + 44, CY - 30)))
        out.append(arm(sh_l, (CUT_X - 30, CY - 28)))
        out.append(motion(CUT_X - 2, CY - 44, 90))
        # The hydraulic cutter left on the ground.
        tool, _ = cutter(180, 150)
        out.append(f'<g transform="rotate(-90 180 168)">{tool}</g>')
        return card_close(out)
    tool, (ex, ey) = cutter(CUT_X, CY, lock=kind != 'open', pump_ang=-8)
    out.append(zoom([tool], CUT_X, CY, k))
    ex, ey = CUT_X + (ex - CUT_X) * k, CY + (ey - CY) * k
    gx, gy = CUT_X - 2, CY + 60 * k * 0.62
    near, far = (sh_r, sh_l) if wx < CUT_X else (sh_l, sh_r)
    out.append(arm(near, (gx - 4, gy - 30)))
    if kind == 'lock':
        # A finger flips the safety lock across the blades.
        out.append(arm(far, (CUT_X + 12, CY - 36), palm=True))
        out.append(f'<path d="M{CUT_X + 34} {CY - 40} q12 8 4 22" stroke="{WHITE}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    else:
        out.append(arm(far, (ex + 2, ey - 4)))
    if kind == 'open':
        out.append(motion(ex + 14, ey - 14, 30))
    elif kind == 'steady':
        out.append(motion(ex + 14, ey - 14, 30))
    elif kind == 'swing':
        out.append(f'<g stroke="{WHITE}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85">'
                   f'<path d="M184 {CY + 20} q10 10 4 24"/><path d="M194 {CY + 14} q12 14 4 32"/></g>')
    elif kind == 'foot':
        out.append(f'<path d="M{wx - 26} {CY + 14} l0 26 m-5 -7 l5 7 l5 -7" stroke="{WHITE}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — care after the job.
# --------------------------------------------------------------------------

def can(x, y, approved=True, ang=0):
    """The maker's oil can: steel with the tool's red band. The other jug is green."""
    g = f'<g transform="translate({f(x)} {f(y)}) rotate({ang})">'
    if approved:
        g += ('<rect x="-12" y="-16" width="24" height="32" rx="3" fill="url(#steel)"/>'
              '<rect x="-12" y="-6" width="24" height="10" fill="url(#toolRed)"/>'
              '<rect x="-3" y="-24" width="6" height="9" rx="1" fill="url(#steel)"/>')
    else:
        g += (f'<rect x="-13" y="-16" width="26" height="32" rx="6" fill="{JUG}"/>'
              f'<rect x="-4" y="-24" width="8" height="9" rx="1" fill="{JUG}"/>')
    return g + '</g>'


def care_card(kind):
    out = card_open('yard')
    out.append(tarp(124))
    out.append(die_box(14, 176, rusty=kind == 'rust'))
    if kind != 'wipe':
        out.append(rag(150, 196))
    hx, hy = 40, 92
    # The reservoir cap is off on every card: the tool is serviced.
    out.append(crimper(hx, hy))
    fx, fy = hx + 54, hy - 12
    out.append(f'<rect x="{f(fx - 4)}" y="{f(fy - 4)}" width="8" height="5" rx="1" fill="{GLOVE}"/>')
    if kind in ('oil', 'any_oil'):
        out.append(f'<path d="M{f(fx + 6)} {f(fy - 34)} Q{f(fx)} {f(fy - 22)} {f(fx)} {f(fy - 4)}" stroke="{OIL}" stroke-width="2.4" fill="none"/>')
        out.append(can(fx + 22, fy - 46, approved=kind == 'oil', ang=-60))
        out.append(arm((214, -10), (fx + 38, fy - 44)))
    elif kind == 'water':
        out.append(f'<path d="M{f(fx + 6)} {f(fy - 34)} Q{f(fx)} {f(fy - 22)} {f(fx)} {f(fy - 4)}" stroke="{WATER}" stroke-width="2.4" fill="none"/>')
        out.append(f'<g transform="translate({f(fx + 22)} {f(fy - 46)}) rotate(-60)"><rect x="-9" y="-18" width="18" height="34" rx="5" fill="{WATER}" opacity="0.8"/>'
                   f'<rect x="-4" y="-24" width="8" height="7" rx="1" fill="{SHIRT}"/></g>')
        out.append(arm((214, -10), (fx + 38, fy - 44)))
        out.append(can(176, 150))
    elif kind == 'wipe':
        # Rag over the dies, a die wiped bright, a drop of oil on it.
        out.append(f'<g transform="translate(-6 -6)">{rag(38, 176)}</g>')
        out.append(arm((90, 230), (52, 178)))
        out.append(hexagon(120, 170, 10, 'url(#steel)'))
        out.append(f'<path d="M120 152 q-2.6 4 0 6 q2.6 -2 0 -6 Z" fill="{OIL}"/>')
        out.append(can(170, 150))
    elif kind == 'tape':
        # A leak bound with tape — and still dripping onto the tarp.
        out.append(f'<rect x="{hx + 40}" y="{hy - 11}" width="12" height="22" fill="{TAPE}"/>')
        out.append(drip(hx + 46, hy + 13, 3))
        out.append(arm((214, 40), (hx + 132, hy - 6)))
        out.append(can(176, 150))
    elif kind == 'rust':
        # The dies left wet and dirty: rust on them; the tool goes into the bag.
        out.append(f'<g fill="{WATER}" opacity="0.7"><circle cx="30" cy="172" r="2"/><circle cx="62" cy="170" r="2.4"/><circle cx="76" cy="174" r="1.8"/></g>')
        out.append(arm((214, 40), (hx + 132, hy - 6)))
        out.append(motion(hx + 140, hy - 22, 0))
        out.append(can(176, 150))
    if kind in ('any_oil',):
        out.append(can(176, 150))
    return card_close(out)


CARDS = {
    'check_look': check_card('look'),
    'check_battery': check_card('battery'),
    'check_drip': check_card('drip'),
    'check_flat': check_card('flat'),
    'check_stiff': check_card('stiff'),
    'die_chart': die_card('chart'),
    'die_match': die_card('match'),
    'die_guess': die_card('guess'),
    'die_big': die_card('big'),
    'die_small': die_card('small'),
    'crimp_click': crimp_card('click'),
    'crimp_clear': crimp_card('clear'),
    'crimp_finger': crimp_card('finger'),
    'crimp_half': crimp_card('half'),
    'crimp_offset': crimp_card('offset'),
    'crimp_plier': crimp_card('plier'),
    'cut_steady': cut_card('steady'),
    'cut_lock': cut_card('lock'),
    'cut_foot': cut_card('foot'),
    'cut_swing': cut_card('swing'),
    'cut_saw': cut_card('saw'),
    'cut_open': cut_card('open'),
    'care_oil': care_card('oil'),
    'care_wipe': care_card('wipe'),
    'care_water': care_card('water'),
    'care_any_oil': care_card('any_oil'),
    'care_tape': care_card('tape'),
    'care_rust': care_card('rust'),
}

# Safe cards and traps per round (mirrors learn_board_pack29.dart).
ROUNDS = {
    'check': (['check_look', 'check_battery'], ['check_drip', 'check_flat', 'check_stiff']),
    'die': (['die_chart', 'die_match'], ['die_guess', 'die_big', 'die_small']),
    'crimp': (['crimp_click', 'crimp_clear'], ['crimp_finger', 'crimp_half', 'crimp_offset', 'crimp_plier']),
    'cut': (['cut_steady', 'cut_lock'], ['cut_foot', 'cut_swing', 'cut_saw', 'cut_open']),
    'care': (['care_oil', 'care_wipe'], ['care_water', 'care_any_oil', 'care_tape', 'care_rust']),
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
    # Never removes anything: the folder holds only this board's cards.
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
