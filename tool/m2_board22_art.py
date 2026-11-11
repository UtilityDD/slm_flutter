"""Picture cards for lesson 2.2 শেখা ("মাল্টিমিটারের জাদু"), rung 2.2/learn.

python -I tool/m2_board22_art.py .

Writes assets/game/art/m2_board22/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the dial marks (~ wave, DC bars, Ω, beep arcs, A) and the port
marks are drawn as small icons.

What the cards show comes from lesson 2.2 only:
  1. check: before use, look at the probe leads for a cut or damage and check
     the battery level; rusty or blunt probe tips give a wrong reading;
  2. port: the black probe in COM, the red one in VΩmA (10A is for high
     current); a wrong port gives a wrong reading or blows the fuse;
  3. volt: our distribution lines are AC — dial on V~, start at the highest
     range and come down; the two tips touch the two points in parallel; a
     wrong setting gives a wrong reading or blows the fuse;
  4. off: continuity (beep) and resistance (Ω) only with the supply fully
     off — never on a live line; the dial in continuity mode;
  5. beep: a beep only says there is a connection — whether it is weak or of
     high resistance, the Ω reading tells; wait a second or two for the
     numbers to settle.

Fairness (the playbook, section 4): every card in a round shares one
backdrop, one bench, one meter, one pair of leads; only the act tells the
safe card from a trap. The script checks every hand the dealer can make (one
safe card + any three traps): each colour or gradient the safe card draws is
drawn by a trap in that hand too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board22_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board22')
W, H = 200, 220

RED = '#C8302C'
BLACK = '#1E2226'
FACE = '#2E3338'
INK = '#2A3328'
MARK = '#E8ECEF'
GLOVE = '#3A3F46'
GLOVE_D = '#2A2D33'
STEEL = '#D9DEE2'
RUST = '#8A4B22'
COPPER = '#D9893A'
BRASS = '#C9A14A'
PORT10 = '#E0662B'
PORTCOM = '#8A939B'
HOLE = '#111417'
WIRE = '#5A636B'
ON = '#C8302C'
OFF = '#3BA55C'
WHITE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2C3E50"/><stop offset="1" stop-color="#4A6278"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9825A"/><stop offset="1" stop-color="#7E5E3E"/></linearGradient>
  <linearGradient id="holster" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E3A21F"/><stop offset="0.5" stop-color="#F6C445"/><stop offset="1" stop-color="#D4931A"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D6B2"/><stop offset="1" stop-color="#A9B98F"/></linearGradient>
  <radialGradient id="knob" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#6E7881"/><stop offset="1" stop-color="#22282D"/></radialGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#848D94"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.6" stop-color="#DDE3E7"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="cap" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="1" stop-color="#8A939B"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='room'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>',
            '<rect x="0" y="150" width="200" height="70" fill="url(#wood)"/>',
            '<path d="M0 150 L200 150" stroke="#5E4428" stroke-width="2"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def polar(cx, cy, r, ang):
    a = math.radians(ang)
    return cx + r * math.sin(a), cy - r * math.cos(a)


# --------------------------------------------------------------------------
# The meter: drawn in its own 80 x 136 frame, placed by translate + scale.
# --------------------------------------------------------------------------

MW, MH = 80, 136
DIAL_C = (40, 70)
DIAL = {'A': -115, 'V~lo': -78, 'V~mid': -58, 'V~hi': -38, 'V-': 0, 'OHM': 42, 'BEEP': 82}
PORTS = {'10A': (16, 114), 'COM': (40, 114), 'V': (64, 114)}

# Seven segments: a b c d e f g on a 6 x 11 cell.
SEG = {
    'a': ((0.8, 0), (5.2, 0)), 'b': ((6, 0.8), (6, 4.7)), 'c': ((6, 6.3), (6, 10.2)), 'd': ((0.8, 11), (5.2, 11)),
    'e': ((0, 6.3), (0, 10.2)), 'f': ((0, 0.8), (0, 4.7)), 'g': ((0.8, 5.5), (5.2, 5.5)),
}
DIGIT = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd', '6': 'afgedc', '7': 'abc',
         '8': 'abcdefg', '9': 'abcdfg', '-': 'g'}


def digits(x, y, s, scale=1.0, op=1.0):
    out = []
    for i, ch in enumerate(s):
        ox = x + i * 8.5 * scale
        for seg in DIGIT[ch]:
            (a, b), (c, d) = SEG[seg]
            out.append(f'M{f(ox + a * scale)} {f(y + b * scale)} L{f(ox + c * scale)} {f(y + d * scale)}')
    return f'<path d="{" ".join(out)}" stroke="{INK}" stroke-width="{f(1.6 * scale)}" stroke-linecap="round" fill="none" opacity="{op}"/>'


def omega(x, y, s=1.0, color=MARK, w=1.0):
    return (f'<path d="M{f(x - 3 * s)} {f(y + 3 * s)} L{f(x - 1.3 * s)} {f(y + 3 * s)} '
            f'A{f(3 * s)} {f(3.2 * s)} 0 1 1 {f(x + 1.3 * s)} {f(y + 3 * s)} L{f(x + 3 * s)} {f(y + 3 * s)}" '
            f'stroke="{color}" stroke-width="{f(w)}" fill="none"/>')


def dial_icons():
    cx, cy = DIAL_C
    out = []
    # A (current): a small capital A as a path.
    x, y = polar(cx, cy, 27, DIAL['A'])
    out.append(f'<path d="M{f(x - 2.5)} {f(y + 3)} L{f(x)} {f(y - 3)} L{f(x + 2.5)} {f(y + 3)} M{f(x - 1.4)} {f(y + 0.8)} L{f(x + 1.4)} {f(y + 0.8)}" stroke="{MARK}" stroke-width="1" fill="none"/>')
    # V~: three range dots, small (low) to big (high), and a wave above them.
    for k, r in (('V~lo', 1.0), ('V~mid', 1.5), ('V~hi', 2.1)):
        x, y = polar(cx, cy, 25, DIAL[k])
        out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill="{MARK}"/>')
    x, y = polar(cx, cy, 33, DIAL['V~mid'])
    out.append(f'<path d="M{f(x - 4)} {f(y)} Q{f(x - 2)} {f(y - 3)} {f(x)} {f(y)} T{f(x + 4)} {f(y)}" stroke="{MARK}" stroke-width="1.1" fill="none"/>')
    # V--- : a bar over dashes.
    x, y = polar(cx, cy, 27, DIAL['V-'])
    out.append(f'<path d="M{f(x - 4)} {f(y - 1.5)} L{f(x + 4)} {f(y - 1.5)} M{f(x - 4)} {f(y + 1.5)} L{f(x - 2)} {f(y + 1.5)} M{f(x - 1)} {f(y + 1.5)} L{f(x + 1)} {f(y + 1.5)} M{f(x + 2)} {f(y + 1.5)} L{f(x + 4)} {f(y + 1.5)}" stroke="{MARK}" stroke-width="1" fill="none"/>')
    x, y = polar(cx, cy, 27, DIAL['OHM'])
    out.append(omega(x, y - 0.5, 1.0))
    x, y = polar(cx, cy, 26, DIAL['BEEP'])
    out.append(f'<circle cx="{f(x - 2)}" cy="{f(y)}" r="1" fill="{MARK}"/>')
    for r in (2.2, 3.8):
        out.append(f'<path d="M{f(x - 2 + r * 0.6)} {f(y - r * 0.8)} A{r} {r} 0 0 1 {f(x - 2 + r * 0.6)} {f(y + r * 0.8)}" stroke="{MARK}" stroke-width="0.9" fill="none"/>')
    return ''.join(out)


def lcd_battery(level):
    """Battery mark in the LCD's corner: level 0..3 bars."""
    out = [f'<rect x="15" y="15" width="11" height="6" rx="1" fill="none" stroke="{INK}" stroke-width="1"/>',
           f'<rect x="26" y="16.8" width="1.5" height="2.4" fill="{INK}"/>']
    for i in range(level):
        out.append(f'<rect x="{16.4 + i * 3.2}" y="16.4" width="2.4" height="3.2" fill="{INK}"/>')
    return ''.join(out)


def meter(x, y, s=1.0, dial='V~hi', red='V', black='COM', lcd='', battery=None, red_plug=0.0):
    """The DMM. lcd: digits string, or '~' for jumping numbers, or 'ohm:<digits>'.
    battery: None (no mark) or bars 0..3. red_plug: lift of the red plug (being pushed in)."""
    cx, cy = DIAL_C
    out = [f'<g transform="translate({f(x)} {f(y)}) scale({s})">',
           f'<rect x="0" y="0" width="{MW}" height="{MH}" rx="12" fill="url(#holster)"/>',
           f'<rect x="6" y="6" width="68" height="124" rx="8" fill="{FACE}"/>',
           '<rect x="12" y="12" width="56" height="26" rx="3" fill="url(#lcd)"/>']
    if battery is not None:
        out.append(lcd_battery(battery))
    if lcd == '~':
        out.append(digits(32, 21, '888', 0.95, 0.25))
        out.append(digits(30, 22, '371', 0.95, 0.9))
        out.append(f'<path d="M62 18 L66 18 M62 24 L66 24 M62 30 L66 30" stroke="{INK}" stroke-width="1"/>')
    elif lcd.startswith('ohm:'):
        out.append(digits(24, 21, lcd[4:], 0.95))
        out.append(omega(61, 25, 1.2, INK, 1.2))
    elif lcd:
        out.append(digits(30, 21, lcd, 0.95))
    out.append(dial_icons())
    out.append(f'<circle cx="{cx}" cy="{cy}" r="18" fill="url(#knob)"/>')
    px, py = polar(cx, cy, 15, DIAL[dial])
    qx, qy = polar(cx, cy, 6, DIAL[dial] + 180)
    out.append(f'<path d="M{f(qx)} {f(qy)} L{f(px)} {f(py)}" stroke="{MARK}" stroke-width="3" stroke-linecap="round"/>')
    # Ports and their marks.
    for name, (px_, py_) in PORTS.items():
        ring = {'10A': PORT10, 'COM': PORTCOM, 'V': RED}[name]
        out.append(f'<circle cx="{px_}" cy="{py_}" r="6" fill="{ring}"/><circle cx="{px_}" cy="{py_}" r="3.6" fill="{HOLE}"/>')
    fx, fy = PORTS['10A']
    out.append(f'<rect x="{fx - 4}" y="{fy + 9}" width="8" height="4" rx="1" fill="none" stroke="{MARK}" stroke-width="0.9"/><path d="M{fx - 6} {fy + 11} L{fx + 6} {fy + 11}" stroke="{MARK}" stroke-width="0.9"/>')
    gx, gy = PORTS['COM']
    out.append(f'<path d="M{gx - 4} {gy + 9.5} L{gx + 4} {gy + 9.5} M{gx - 2.6} {gy + 11.5} L{gx + 2.6} {gy + 11.5} M{gx - 1.2} {gy + 13.5} L{gx + 1.2} {gy + 13.5}" stroke="{MARK}" stroke-width="0.9"/>')
    vx, vy = PORTS['V']
    out.append(omega(vx, vy + 10.5, 0.9))
    # Plugs.
    for port, color, lift in ((black, BLACK, 0.0), (red, RED, red_plug)):
        if port is None:
            continue
        px_, py_ = PORTS[port]
        out.append(f'<rect x="{px_ - 3.5}" y="{f(py_ - 3 + lift * -1)}" width="7" height="12" rx="2" fill="{color}" stroke="{HOLE}" stroke-width="0.6"/>')
    out.append('</g>')
    return ''.join(out)


def port_xy(mx, my, s, port, lift=0.0):
    px, py = PORTS[port]
    return mx + px * s, my + (py + 9 - lift) * s


def probe(tip, ang, color, rusty=False):
    """A probe whose tip is at `tip`, pointing along `ang` (deg, 0 = up). Returns (svg, back end)."""
    x, y = tip
    out = [f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">']
    if rusty:
        out.append(f'<path d="M-1.6 0 L1.6 0 L1.4 11 L-1.4 11 Z" fill="{RUST}"/>')
        out.append(f'<circle cx="-1" cy="4" r="1.4" fill="{RUST}"/><circle cx="1.2" cy="7" r="1.2" fill="{COPPER}" opacity="0.7"/>')
    else:
        out.append(f'<path d="M0 0 L1.2 3 L1.2 11 L-1.2 11 L-1.2 3 Z" fill="{STEEL}"/>')
    out.append(f'<rect x="-4.5" y="11" width="9" height="3" rx="1" fill="{color}"/>')
    out.append(f'<rect x="-3.2" y="14" width="6.4" height="24" rx="2.5" fill="{color}"/>')
    out.append('</g>')
    bx, by = polar(x, y, 38, ang + 180)
    return ''.join(out), (bx, by)


def lead(a, b, color, sag=30, cut=False):
    (x0, y0), (x1, y1) = a, b
    cx, cy = (x0 + x1) / 2, max(y0, y1) + sag
    if not cut:
        return f'<path d="M{f(x0)} {f(y0)} Q{f(cx)} {f(cy)} {f(x1)} {f(y1)}" stroke="{color}" stroke-width="3" fill="none" stroke-linecap="round"/>'
    # Split the curve at t = 0.55 and show bare copper in the gap.
    def q(t):
        u = 1 - t
        return (u * u * x0 + 2 * u * t * cx + t * t * x1, u * u * y0 + 2 * u * t * cy + t * t * y1)
    pa, pb = q(0.45), q(0.62)
    pts1 = ' L'.join(f'{f(q(i / 20 * 0.45)[0])} {f(q(i / 20 * 0.45)[1])}' for i in range(21))
    pts2 = ' L'.join(f'{f(q(0.62 + i / 20 * 0.38)[0])} {f(q(0.62 + i / 20 * 0.38)[1])}' for i in range(21))
    return (f'<path d="M{pts1}" stroke="{color}" stroke-width="3" fill="none" stroke-linecap="round"/>'
            f'<path d="M{pts2}" stroke="{color}" stroke-width="3" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(pa[0])} {f(pa[1])} L{f(pb[0])} {f(pb[1] - 2)} M{f(pa[0])} {f(pa[1] + 1)} L{f(pb[0] + 1)} {f(pb[1] + 2)} '
            f'M{f(pa[0] - 1)} {f(pa[1])} L{f(pb[0] - 2)} {f(pb[1] + 1)}" stroke="{COPPER}" stroke-width="2.4" fill="none"/>'
            f'<circle cx="{f((pa[0] + pb[0]) / 2)}" cy="{f((pa[1] + pb[1]) / 2)}" r="9" fill="none" stroke="{COPPER}" stroke-width="1.2" stroke-dasharray="2 2"/>')


def hand(x, y, ang=0, s=1.0):
    """A gloved fist around a probe handle at (x, y)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({s})">'
            f'<rect x="-7" y="-6" width="14" height="13" rx="5" fill="{GLOVE}"/>'
            f'<path d="M-6 -2 L6 -2 M-6 2 L6 2" stroke="{GLOVE_D}" stroke-width="1"/>'
            f'<rect x="-6" y="7" width="12" height="16" rx="3" fill="{GLOVE_D}"/></g>')


def finger(x, y, ang=0):
    """A gloved hand with the index finger out, touching (x, y)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})">'
            f'<rect x="-2.2" y="0" width="4.4" height="12" rx="2.2" fill="{GLOVE}"/>'
            f'<rect x="-7" y="9" width="14" height="13" rx="5" fill="{GLOVE}"/>'
            f'<rect x="-6" y="21" width="12" height="16" rx="3" fill="{GLOVE_D}"/></g>')


def thumbs_up(x, y):
    return (f'<g transform="translate({f(x)} {f(y)}) scale(1.5)">'
            f'<rect x="-2.4" y="-12" width="4.8" height="12" rx="2.4" fill="{GLOVE}"/>'
            f'<rect x="-7" y="-2" width="14" height="13" rx="5" fill="{GLOVE}"/>'
            f'<path d="M-6 3 L6 3 M-6 6.5 L6 6.5" stroke="{GLOVE_D}" stroke-width="1"/>'
            f'<rect x="-6" y="10" width="12" height="16" rx="3" fill="{GLOVE_D}"/></g>')


def beep_arcs(x, y):
    return ''.join(f'<path d="M{f(x + r * 0.5)} {f(y - r * 0.85)} A{r} {r} 0 0 1 {f(x + r * 0.5)} {f(y + r * 0.85)}" '
                   f'stroke="{WHITE}" stroke-width="2" fill="none" opacity="0.85"/>' for r in (6, 11, 16))


def magnifier(x, y):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="13" fill="{WHITE}" fill-opacity="0.22" stroke="{STEEL}" stroke-width="3"/>'
            f'<path d="M{f(x + 9)} {f(y + 9)} L{f(x + 20)} {f(y + 22)}" stroke="{GLOVE_D}" stroke-width="5" stroke-linecap="round"/>')


def mcb(x, y, on):
    """The circuit's switch on the wall: lever up (on, red window) or down (off, green window)."""
    lever = f'<rect x="{x + 8}" y="{y + (8 if on else 20)}" width="10" height="12" rx="2" fill="{FACE}"/>'
    return (f'<rect x="{x}" y="{y}" width="26" height="44" rx="3" fill="url(#porcelain)" stroke="{PORTCOM}" stroke-width="1"/>'
            f'<rect x="{x + 6}" y="{y + 6}" width="14" height="28" rx="2" fill="{HOLE}" opacity="0.25"/>' + lever +
            f'<rect x="{x + 9}" y="{y + 36}" width="8" height="4" rx="1" fill="{ON if on else OFF}"/>')


def fuse_rig(on):
    """MCB on the wall feeding a cartridge fuse in its clips on the bench."""
    return (mcb(160, 20, on) +
            f'<path d="M166 64 L166 120 L128 120 L128 158 M180 64 L180 158" stroke="{WIRE}" stroke-width="2.4" fill="none"/>'
            f'<rect x="122" y="158" width="12" height="10" fill="{WIRE}"/><rect x="174" y="158" width="12" height="10" fill="{WIRE}"/>'
            f'<rect x="132" y="155" width="44" height="14" rx="6" fill="url(#porcelain)"/>'
            f'<rect x="124" y="154" width="10" height="16" rx="2" fill="url(#cap)"/><rect x="174" y="154" width="10" height="16" rx="2" fill="url(#cap)"/>')


def joint_rig(on):
    """MCB on the wall feeding a cable with a twisted joint, its ends on the bench."""
    return (mcb(160, 20, on) +
            f'<path d="M166 64 L166 120 L128 120 L128 160 M180 64 L180 160" stroke="{WIRE}" stroke-width="2.4" fill="none"/>'
            f'<path d="M120 162 L144 162 M164 162 L188 162" stroke="{BLACK}" stroke-width="7" stroke-linecap="round"/>'
            f'<path d="M144 162 Q149 153 154 162 T164 162 M144 162 Q149 170 154 162 T164 162" stroke="{COPPER}" stroke-width="3" fill="none"/>'
            f'<circle cx="150" cy="161" r="2.6" fill="{RUST}"/><circle cx="157" cy="163" r="2.2" fill="{RUST}"/>')


def terminal_box():
    """An LT terminal box: phase (red) and neutral (black) on two brass screws."""
    return ('<rect x="118" y="40" width="72" height="104" rx="6" fill="url(#box)"/>'
            f'<rect x="126" y="92" width="56" height="30" rx="3" fill="{FACE}"/>'
            f'<path d="M140 40 L140 100 M168 40 L168 100" stroke-width="5" stroke-linecap="round" fill="none" stroke="{RED}"/>'
            f'<path d="M168 40 L168 100" stroke="{BLACK}" stroke-width="5" stroke-linecap="round"/>'
            f'<circle cx="140" cy="108" r="6" fill="{BRASS}"/><circle cx="168" cy="108" r="6" fill="{BRASS}"/>'
            f'<path d="M136 108 L144 108 M164 108 L172 108" stroke="{HOLE}" stroke-width="1.2"/>')


# --------------------------------------------------------------------------
# Rounds.
# --------------------------------------------------------------------------

MX, MY, MS = 12, 66, 1.0          # the meter's spot on most cards


def probes_on(out, tips, mx=MX, my=MY, ms=MS, red='V', black='COM', rusty=False, cut=False, hands=True, sag=26):
    """Red probe to tips[0], black to tips[1]; each as (x, y, angle)."""
    for (tx, ty, ang), color, port in ((tips[1], BLACK, black), (tips[0], RED, red)):
        svg, back = probe((tx, ty), ang, color, rusty=rusty)
        out.append(lead(port_xy(mx, my, ms, port), back, color, sag=sag, cut=cut and color == RED))
        out.append(svg)
        if hands:
            hx, hy = polar(tx, ty, 28, ang + 180)
            out.append(hand(hx, hy, ang))


def check_card(kind):
    out = card_open()
    if kind == 'lead':
        out.append(meter(MX, MY, dial='V~hi'))
        probes_on(out, [(150, 120, 200), (176, 128, 200)], sag=40)
        out.append(magnifier(104, 176))
    elif kind == 'battery':
        out.append(meter(MX, MY, dial='V~hi', battery=3, lcd='000'))
        out.append(finger(84, 92, 270))
        probes_on(out, [(150, 120, 200), (176, 128, 200)], sag=40, hands=False)
    elif kind == 'cut':
        out.append(meter(MX, MY, dial='V~hi'))
        probes_on(out, [(150, 120, 200), (176, 128, 200)], sag=40, cut=True)
    elif kind == 'rusty':
        out.append(meter(MX, MY, dial='V~hi'))
        probes_on(out, [(150, 120, 200), (176, 128, 200)], sag=40, rusty=True)
    elif kind == 'low_batt':
        out.append(meter(MX, MY, dial='V~hi', battery=0, lcd='---'))
        probes_on(out, [(150, 120, 200), (176, 128, 200)], sag=40)
    return card_close(out)


PMX, PMY, PMS = 30, 22, 1.3


def port_card(kind):
    out = card_open()
    red, black, lift = {'com_v': ('V', 'COM', 0), 'com_v2': ('V', 'COM', 8), 'red_10a': ('10A', 'COM', 8),
                        'swap': ('COM', 'V', 0), 'black_10a': ('V', '10A', 0)}[kind]
    out.append(meter(PMX, PMY, PMS, dial='V~hi', red=red, black=black, red_plug=lift))
    # The leads run down off the meter to the probes lying on the bench.
    for port, color, tip, l in ((black, BLACK, (176, 206, 250), 0), (red, RED, (182, 186, 250), lift)):
        svg, back = probe(tip[:2], tip[2], color)
        out.append(lead(port_xy(PMX, PMY, PMS, port, l), back, color, sag=18))
        out.append(svg)
    if lift:
        px, py = port_xy(PMX, PMY, PMS, red, lift)
        out.append(hand(px + 2, py + 18, 0, 1.3))
    return card_close(out)


def volt_card(kind):
    out = card_open()
    out.append(terminal_box())
    dial = {'parallel': 'V~hi', 'high_range': 'V~hi', 'dc': 'V-', 'low_range': 'V~lo', 'amp_dial': 'A', 'ohm_live': 'OHM'}[kind]
    out.append(meter(MX, MY, dial=dial))
    if kind == 'high_range':
        cx, cy = MX + DIAL_C[0], MY + DIAL_C[1]
        out.append(finger(cx - 8, cy - 2, 230))
        out.append(f'<path d="M{cx - 18} {cy - 28} A24 24 0 0 1 {cx + 2} {cy - 31}" stroke="{WHITE}" stroke-width="2" fill="none" opacity="0.85"/>')
        probes_on(out, [(132, 150, 160), (176, 152, 200)], sag=30, hands=False)
    else:
        probes_on(out, [(140, 112, 30), (168, 112, -10)], sag=20)
    return card_close(out)


def off_card(kind):
    on = kind in ('live_beep', 'live_ohm')
    out = card_open()
    out.append(fuse_rig(on))
    dial = {'switch_off': 'BEEP', 'beep_off': 'BEEP', 'live_beep': 'BEEP', 'wrong_dial': 'V~hi', 'live_ohm': 'OHM'}[kind]
    out.append(meter(MX, MY, dial=dial))
    if kind == 'switch_off':
        out.append(finger(173, 52, 0))
        probes_on(out, [(112, 196, 210), (140, 204, 240)], sag=12, hands=False)
    else:
        probes_on(out, [(129, 156, 200), (179, 156, 160)], sag=22)
        if kind in ('beep_off', 'live_beep'):
            out.append(beep_arcs(MX + 76, MY + 20))
    return card_close(out)


def beep_card(kind):
    out = card_open()
    joint = kind in ('ohm_check', 'weak_joint')
    out.append(joint_rig(False) if joint else fuse_rig(False))
    dial = 'BEEP' if kind in ('beep_done', 'weak_joint') else 'OHM'
    lcd = {'ohm_read': 'ohm:0.4', 'ohm_check': 'ohm:0.6', 'jumpy': '~'}.get(kind, '')
    lcd = lcd.replace('.', '')
    out.append(meter(MX, MY, dial=dial, lcd=lcd))
    if joint:
        probes_on(out, [(128, 160, 200), (180, 160, 160)], sag=22)
    else:
        probes_on(out, [(129, 156, 200), (179, 156, 160)], sag=22)
    if kind in ('beep_done', 'weak_joint'):
        out.append(beep_arcs(MX + 76, MY + 20))
        out.append(thumbs_up(104, 40))
    if kind == 'jumpy':
        out.append(thumbs_up(104, 40))
    return card_close(out)


CARDS = {
    'check_lead': check_card('lead'),
    'check_battery': check_card('battery'),
    'check_cut': check_card('cut'),
    'check_rusty': check_card('rusty'),
    'check_low_batt': check_card('low_batt'),
    'port_com_v': port_card('com_v'),
    'port_com_v2': port_card('com_v2'),
    'port_red_10a': port_card('red_10a'),
    'port_swap': port_card('swap'),
    'port_black_10a': port_card('black_10a'),
    'volt_parallel': volt_card('parallel'),
    'volt_high_range': volt_card('high_range'),
    'volt_dc': volt_card('dc'),
    'volt_low_range': volt_card('low_range'),
    'volt_amp_dial': volt_card('amp_dial'),
    'volt_ohm_live': volt_card('ohm_live'),
    'off_switch_off': off_card('switch_off'),
    'off_beep_off': off_card('beep_off'),
    'off_live_beep': off_card('live_beep'),
    'off_wrong_dial': off_card('wrong_dial'),
    'off_live_ohm': off_card('live_ohm'),
    'beep_ohm_read': beep_card('ohm_read'),
    'beep_ohm_check': beep_card('ohm_check'),
    'beep_beep_done': beep_card('beep_done'),
    'beep_weak_joint': beep_card('weak_joint'),
    'beep_jumpy': beep_card('jumpy'),
}

# Safe cards and traps per round (mirrors learn_board_pack22.dart).
ROUNDS = {
    'check': (['check_lead', 'check_battery'], ['check_cut', 'check_rusty', 'check_low_batt']),
    'port': (['port_com_v', 'port_com_v2'], ['port_red_10a', 'port_swap', 'port_black_10a']),
    'volt': (['volt_parallel', 'volt_high_range'], ['volt_dc', 'volt_low_range', 'volt_amp_dial', 'volt_ohm_live']),
    'off': (['off_switch_off', 'off_beep_off'], ['off_live_beep', 'off_wrong_dial', 'off_live_ohm']),
    'beep': (['beep_ohm_read', 'beep_ohm_check'], ['beep_beep_done', 'beep_weak_joint', 'beep_jumpy']),
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
            for hand_ in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand_}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand_}')
                only = tok[s] - set().union(*(tok[t] for t in hand_))
                if only:
                    problems.append(f'{rnd}: {s} with {hand_} draws {sorted(only)} alone')
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
