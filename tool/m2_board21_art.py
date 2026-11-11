"""Picture cards for the Module 2 lesson 2.1 board (লাইনম্যানের টুলবক্স পরিচিতি).

python -I tool/m2_board21_art.py .

Writes assets/game/art/m2_board21/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 2.1 only:
  1. pliers: VDE 1000V insulated combination pliers; non-insulated pliers on
     an LT line = danger; a cracked / cut / burnt handle = do not use;
     "Pliers = Hammer নয়" (right tool for right job);
  2. strip: wire stripper (insulation off at the right size) and side cutter
     (cutting), both VDE 1000V; a knife or ordinary pliers nicks the
     conductor (weak point, hot spot); a blunt cutter is not used;
  3. screw: insulated screwdrivers, flat (-) and Phillips (+), the right size,
     VDE insulated from the handle to the blade root, metal tip only; the
     wrong size slips (short circuit / injury); a bent tip; "Screwdriver =
     Chisel নয়";
  4. spanner: ring and double-ended spanners of the right size; a wrong /
     loose spanner or a worn, widened mouth slips and spoils the nut;
  5. tester: the line tester says phase is there or not; test it first on a
     known live point (the neon glows); not reliable on neutral / earth;
     LV only (~500V).

Fairness (the playbook, section 4): every card in a round shares one
backdrop, one gloved hand and one work piece; only the tool and the act tell
the safe card from a trap. The script checks every hand the dealer can make
(one safe card + any three traps): each colour or gradient the safe card
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
    print('usage: python -I tool/m2_board21_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board21')
W, H = 200, 220

GLOVE = '#2A2D33'
GLOVE_L = '#3A3E46'
CABLE = '#2B3138'
VDE_R = '#D7372E'
VDE_Y = '#F2C230'
CHAR = '#3B2A1E'
CRACK = '#14161A'
WOOD = '#8A5A32'
NEON_OFF = '#7A4A2A'
NEON_ON = '#FF8A3D'
NUT = '#9AA3AA'
NUT_D = '#6F777E'
PHASE = '#C8352B'
NEUTRAL = '#1C1F24'
EARTH = '#3E8E4A'
SOCKET = '#ECE8DE'
SCRATCH = '#E9EEF2'

DEFS = """<defs>
  <linearGradient id="canvas" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B6B5A"/><stop offset="1" stop-color="#3E4B3F"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9AA4AC"/><stop offset="1" stop-color="#6C767E"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6FA6D6"/><stop offset="1" stop-color="#BFDDF0"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B27A"/><stop offset="0.5" stop-color="#D2843F"/><stop offset="1" stop-color="#9A5A25"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE0B0" stop-opacity="0.95"/><stop offset="0.4" stop-color="#FF8A3D" stop-opacity="0.55"/><stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/></radialGradient>
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


def at(svg, x, y, ang=0, s=1.0):
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({s})">{svg}</g>'


# --------------------------------------------------------------------------
# The gloved hand: a blue sleeve and a black rubber gauntlet from the card's
# edge to a fist at (x, y).
# --------------------------------------------------------------------------

def hand(x, y, from_xy, ang=0):
    ex, ey = from_xy
    mx, my = x + (ex - x) * 0.45, y + (ey - y) * 0.45
    return (f'<path d="M{f(ex)} {f(ey)} L{f(mx)} {f(my)}" stroke="url(#shirt)" stroke-width="26" stroke-linecap="round"/>'
            f'<path d="M{f(mx)} {f(my)} L{f(x)} {f(y)}" stroke="{GLOVE}" stroke-width="21" stroke-linecap="round"/>'
            f'<path d="M{f(mx + (x - mx) * 0.15)} {f(my + (y - my) * 0.15)} l0 0" stroke="{GLOVE_L}" stroke-width="22" stroke-linecap="round"/>'
            + at(f'<rect x="-13" y="-11" width="26" height="22" rx="8" fill="{GLOVE}"/>'
                 f'<path d="M-6 -11 L-6 -4 M0 -11 L0 -4 M6 -11 L6 -4" stroke="{GLOVE_L}" stroke-width="1.6" stroke-linecap="round"/>', x, y, ang))


# --------------------------------------------------------------------------
# Tools, each drawn in its own frame: the working end at (0, 0) pointing up
# (negative y), the grip below.
# --------------------------------------------------------------------------

def _handles(kind, length=74, spread=11, pivot=30):
    """Two plier-type handles from the pivot down. kind: vde | bare | cracked | burnt."""
    s = []
    for side in (-1, 1):
        x0, y0 = side * 3.5, pivot + 4
        x1, y1 = side * spread, pivot + length
        d = f'M{f(x0 - 4)} {f(y0)} L{f(x0 + 4)} {f(y0)} L{f(x1 + 4.5)} {f(y1)} Q{f(x1)} {f(y1 + 6)} {f(x1 - 4.5)} {f(y1)} Z'
        fill = 'url(#steel)' if kind == 'bare' else VDE_R
        s.append(f'<path d="{d}" fill="{fill}"/>')
        if kind != 'bare':
            # The yellow finger guard collar and the yellow inner layer showing at the end.
            s.append(f'<rect x="{f(x0 - 6.5)}" y="{f(y0 + 2)}" width="13" height="6" rx="2.5" fill="{VDE_Y}" transform="rotate({f(-side * 6)} {f(x0)} {f(y0 + 5)})"/>')
            s.append(f'<path d="M{f(x1 - 3)} {f(y1 - 3)} L{f(x1 + 3)} {f(y1 - 3)}" stroke="{VDE_Y}" stroke-width="2.2"/>')
    if kind == 'cracked':
        s.append(f'<path d="M-9 {f(pivot + 28)} l4 5 l-3 4 l4 6 l-2 5" stroke="{CRACK}" stroke-width="1.6" fill="none" stroke-linejoin="round"/>'
                 f'<path d="M-9.5 {f(pivot + 36)} l3 1.5 l-1 5 Z" fill="url(#steel)"/>'
                 f'<path d="M9 {f(pivot + 44)} l-3 5 l3 4 l-2 6" stroke="{CRACK}" stroke-width="1.6" fill="none" stroke-linejoin="round"/>')
    if kind == 'burnt':
        s.append(f'<ellipse cx="-7.5" cy="{f(pivot + 38)}" rx="5.5" ry="9" fill="{CHAR}" opacity="0.92"/>'
                 f'<ellipse cx="-7" cy="{f(pivot + 37)}" rx="2.6" ry="4.5" fill="{CRACK}"/>'
                 f'<ellipse cx="8.5" cy="{f(pivot + 52)}" rx="4" ry="6" fill="{CHAR}" opacity="0.85"/>')
    return ''.join(s)


def pliers(kind='vde', open_=0.0):
    """Combination pliers: flat gripper nose, cutter, pivot; handles below."""
    o = open_ * 6
    jaws = (f'<path d="M-1 30 L-9 22 L-7 4 L{f(-2 - o)} -2 L-1 0 Z" fill="url(#steel)"/>'
            f'<path d="M1 30 L9 22 L7 4 L{f(2 + o)} -2 L1 0 Z" fill="url(#steel)"/>'
            '<path d="M-6 8 L6 8 M-6 12 L6 12 M-6 16 L6 16" stroke="#7D868E" stroke-width="0.9"/>'
            '<circle cx="0" cy="27" r="4.2" fill="#7D868E"/><circle cx="0" cy="27" r="1.6" fill="#C3CBD1"/>')
    return _handles(kind) + jaws


def side_cutter(kind='vde'):
    """Diagonal side cutter: short pointed cutting jaws."""
    jaws = ('<path d="M-1 30 L-10 20 Q-8 6 -1 -2 L-1 30 Z" fill="url(#steel)"/>'
            '<path d="M1 30 L10 20 Q8 6 1 -2 L1 30 Z" fill="url(#steel)"/>'
            '<path d="M0 -2 L0 22" stroke="#7D868E" stroke-width="1"/>'
            '<circle cx="0" cy="27" r="4.2" fill="#7D868E"/><circle cx="0" cy="27" r="1.6" fill="#C3CBD1"/>')
    return _handles(kind, length=64, spread=10) + jaws


def stripper(kind='vde'):
    """Wire stripper: straight jaws with a row of size notches."""
    notches = ''.join(f'<circle cx="0" cy="{f(6 + i * 5.2)}" r="{f(1.2 + i * 0.35)}" fill="#4F575F"/>' for i in range(4))
    jaws = ('<path d="M-1 30 L-8 26 L-8 0 L-1 -2 Z" fill="url(#steel)"/>'
            '<path d="M1 30 L8 26 L8 0 L1 -2 Z" fill="url(#steel)"/>' + notches
            + '<circle cx="0" cy="29" r="4.2" fill="#7D868E"/><circle cx="0" cy="29" r="1.6" fill="#C3CBD1"/>')
    return _handles(kind, length=70, spread=10, pivot=32) + jaws


def knife():
    return ('<path d="M-3 0 L4 2 L4 40 L-4 40 Q-6 18 -3 0 Z" fill="url(#steel)"/>'
            f'<rect x="-6" y="40" width="12" height="44" rx="4" fill="{WOOD}"/>'
            '<circle cx="0" cy="52" r="1.6" fill="#C3CBD1"/><circle cx="0" cy="72" r="1.6" fill="#C3CBD1"/>')


def screwdriver(tip='flat', kind='vde', bent=False, short_tip=False):
    """Insulated screwdriver: metal tip only; the red sleeve runs from the
    handle to the blade root (VDE). kind 'bare' = a plain metal shaft."""
    s = []
    tip_len = 9
    shaft_top = tip_len
    if kind == 'bare':
        s.append(f'<rect x="-2.6" y="{shaft_top}" width="5.2" height="54" fill="url(#steel)"/>')
    else:
        s.append(f'<rect x="-3.6" y="{shaft_top}" width="7.2" height="54" rx="1.6" fill="{VDE_R}"/>')
    # Handle.
    s.append(f'<path d="M-9 62 L9 62 L10 112 Q0 118 -10 112 Z" fill="{VDE_R}"/>')
    s.append(f'<rect x="-9.5" y="62" width="19" height="7" rx="2.5" fill="{VDE_Y}"/>')
    s.append(f'<path d="M-4 74 L-4 106 M4 74 L4 106" stroke="{VDE_Y}" stroke-width="2.2" stroke-linecap="round"/>')
    w = 2.2 if short_tip else 4.6
    if tip == 'flat':
        body = f'<path d="M-2.4 {tip_len + 1} L2.4 {tip_len + 1} L{f(w)} 1.2 L{f(w)} 0 L{f(-w)} 0 L{f(-w)} 1.2 Z" fill="url(#steel)"/>'
    else:
        body = (f'<path d="M-2.6 {tip_len + 1} L2.6 {tip_len + 1} L1.4 1 L0 -1 L-1.4 1 Z" fill="url(#steel)"/>'
                '<path d="M0 -0.5 L0 9" stroke="#7D868E" stroke-width="0.9"/>')
    if bent:
        body = f'<g transform="rotate(38 0 {tip_len + 1}) translate(0 2)">{body}</g>'
    s.insert(0, body)
    return ''.join(s)


def hammer():
    return (f'<rect x="-3" y="0" width="6" height="66" rx="2.4" fill="{WOOD}"/>'
            '<path d="M-16 -10 L14 -10 L16 -4 L16 6 L-16 6 Z" fill="url(#steel)"/>'
            '<path d="M-16 -10 L-22 -6 L-22 2 L-16 6 Z" fill="#7D868E"/>')


def spanner_open(gap=17, worn=False, length=96):
    """Double-ended spanner, working jaw at (0, 0) (the nut sits there)."""
    g = gap / 2
    flare = 5 if worn else 0
    head = (f'<path d="M{f(-g - 7)} -6 L{f(-g - flare)} -15 L{f(-g)} 8 L{f(g)} 8 L{f(g + flare)} -15 L{f(g + 7)} -6 '
            f'Q{f(g + 9)} 14 4 22 L-4 22 Q{f(-g - 9)} 14 {f(-g - 7)} -6 Z" fill="url(#steel)"/>')
    shank = f'<path d="M-5 20 L5 20 L4.4 {f(length)} L-4.4 {f(length)} Z" fill="url(#steel)"/>'
    tail = (f'<g transform="translate(0 {f(length + 8)})"><path d="M-9 -9 L9 -9 Q11 4 6 11 L3 6 L-3 6 L-6 11 Q-11 4 -9 -9 Z" fill="url(#steel)"/></g>')
    wear = ''
    if worn:
        wear = f'<path d="M{f(-g - 2)} -10 L{f(-g)} 4 M{f(g + 2)} -10 L{f(g)} 4" stroke="#4F575F" stroke-width="1.4"/>'
    return shank + tail + head + wear


def spanner_ring(length=96):
    ring = ('<circle cx="0" cy="0" r="17" fill="url(#steel)"/>'
            '<path d="M0 -11 L9.5 -5.5 L9.5 5.5 L0 11 L-9.5 5.5 L-9.5 -5.5 Z" fill="#4F575F"/>')
    shank = f'<path d="M-5 14 L5 14 L4.4 {f(length)} L-4.4 {f(length)} Z" fill="url(#steel)"/>'
    return shank + ring


def tester(lit):
    """Line tester: a metal tip, a clear body with the neon window, a cap."""
    neon = NEON_ON if lit else NEON_OFF
    glow = '<ellipse cx="0" cy="36" rx="14" ry="20" fill="url(#glow)"/>' if lit else ''
    return ('<path d="M-1.8 16 L1.8 16 L1.2 1 L0 -1 L-1.2 1 Z" fill="url(#steel)"/>'
            '<rect x="-5" y="16" width="10" height="56" rx="3" fill="#D9E6EE" opacity="0.85"/>'
            f'<rect x="-2.4" y="26" width="4.8" height="20" rx="2" fill="{neon}"/>' + glow
            + f'<rect x="-5.6" y="72" width="11.2" height="10" rx="3" fill="url(#steel)"/>'
            + f'<rect x="-5" y="60" width="10" height="4" fill="{VDE_R}"/>')


def nick_marks(x, y):
    return (f'<g stroke="{CRACK}" stroke-width="1.4" stroke-linecap="round">'
            f'<path d="M{f(x)} {f(y - 4)} l2 4"/><path d="M{f(x + 7)} {f(y - 4)} l2 4"/><path d="M{f(x + 3)} {f(y + 4)} l2 -4"/></g>')


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def swing(x, y, r=26, a0=200, a1=300):
    """Motion arcs of a tool swung like a hammer."""
    out = []
    for k, rr in enumerate((r, r + 8)):
        p0 = (x + rr * math.cos(math.radians(a0)), y + rr * math.sin(math.radians(a0)))
        p1 = (x + rr * math.cos(math.radians(a1)), y + rr * math.sin(math.radians(a1)))
        out.append(f'<path d="M{f(p0[0])} {f(p0[1])} A{rr} {rr} 0 0 1 {f(p1[0])} {f(p1[1])}" stroke="#FFFFFF" stroke-width="1.8" '
                   f'fill="none" stroke-linecap="round" opacity="{0.85 - k * 0.3}"/>')
    return ''.join(out)


def slip_marks(x, y):
    return ('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85">'
            f'<path d="M{f(x)} {f(y)} l10 -6"/><path d="M{f(x + 2)} {f(y + 7)} l12 -5"/><path d="M{f(x + 4)} {f(y + 14)} l10 -4"/></g>')


# --------------------------------------------------------------------------
# Round stages.
# --------------------------------------------------------------------------

def cable(y=74, end_x=150, strip_len=18, copper_state='clean'):
    """An LT insulated cable running in from the left, copper bared at the end."""
    s = [f'<path d="M-6 {y} L{end_x} {y}" stroke="{CABLE}" stroke-width="14" stroke-linecap="butt"/>',
         f'<path d="M-6 {y - 4} L{end_x} {y - 4}" stroke="#4A525A" stroke-width="2"/>']
    cx = end_x
    if copper_state == 'crushed':
        s.append(f'<path d="M{cx} {y - 7} L{cx + strip_len} {y - 2} L{cx + strip_len} {y + 2} L{cx} {y + 7} Z" fill="url(#copper)"/>')
        s.append(f'<path d="M{cx + strip_len} {y - 2} l6 -5 M{cx + strip_len} {y} l7 0 M{cx + strip_len} {y + 2} l6 5" stroke="#D2843F" stroke-width="1.4"/>')
    else:
        s.append(f'<rect x="{cx}" y="{y - 4}" width="{strip_len}" height="8" rx="2" fill="url(#copper)"/>')
        s.append(f'<path d="M{cx} {y - 1.5} L{cx + strip_len} {y - 1.5} M{cx} {y + 1.5} L{cx + strip_len} {y + 1.5}" stroke="#9A5A25" stroke-width="0.7"/>')
        if copper_state == 'nicked':
            s.append(nick_marks(cx + 3, y))
    return ''.join(s)


def bench_stage():
    out = card_open('canvas')
    # Stitched tool-roll pockets along the bottom.
    out.append('<g stroke="#2F3A30" stroke-width="1.4" stroke-dasharray="4 3" fill="none">'
               '<path d="M0 176 L200 176"/><path d="M40 176 L40 220 M80 176 L80 220 M120 176 L120 220 M160 176 L160 220"/></g>')
    # Press studs on the pockets.
    out.append('<g fill="#4F575F">' + ''.join(f'<circle cx="{x}" cy="184" r="2.4"/>' for x in (20, 60, 100, 140, 180)) + '</g>')
    return out


# ---- Round 1: pliers ------------------------------------------------------

def pliers_card(kind):
    out = bench_stage()
    if kind == 'hammer':
        # The pliers swung at a bolt head like a hammer.
        out.append(cable(y=56))
        out.append('<rect x="70" y="128" width="64" height="12" rx="2" fill="url(#steelArm)"/>'
                   f'<rect x="94" y="116" width="16" height="12" rx="2" fill="{NUT}"/><rect x="99" y="106" width="6" height="10" fill="{NUT_D}"/>')
        out.append(swing(108, 104, 30, 200, 290))
        out.append(at(pliers('vde'), 112, 100, 100, 1.15))
        out.append(hand(28, 84, (-20, 120), 80))
        return card_close(out)
    out.append(cable())
    tool = {'vde': 'vde', 'cut': 'vde', 'bare': 'bare', 'cracked': 'cracked', 'burnt': 'burnt'}[kind]
    if kind == 'cut':
        # Cutting the cable end: a short off-cut drops away.
        out.append(f'<g transform="rotate(24 172 110)"><rect x="160" y="106" width="14" height="10" rx="2" fill="{CABLE}"/>'
                   '<rect x="174" y="107" width="10" height="8" rx="2" fill="url(#copper)"/></g>')
        out.append(at(pliers(tool, 0.4), 132, 74, 8, 1.25))
        out.append(hand(145, 180, (155, 250), 4))
    else:
        out.append(at(pliers(tool), 116, 74, -6, 1.25))
        out.append(hand(127, 180, (133, 250), -4))
    return card_close(out)


# ---- Round 2: strip and cut -----------------------------------------------

def strip_card(kind):
    out = bench_stage()
    if kind == 'stripper':
        out.append(cable(copper_state='clean', strip_len=20, end_x=136))
        # The slid-off insulation sleeve.
        out.append(f'<rect x="164" y="67" width="20" height="14" rx="2" fill="{CABLE}" transform="rotate(10 174 74)"/>')
        out.append(at(stripper('vde'), 122, 74, 0, 1.25))
        out.append(hand(122, 182, (128, 250), 0))
    elif kind == 'cutter':
        out.append(cable(copper_state='clean', end_x=140))
        out.append(at(side_cutter('vde'), 104, 74, 0, 1.25))
        out.append(hand(104, 170, (110, 250), 0))
    elif kind == 'knife':
        out.append(cable(copper_state='nicked', end_x=124, strip_len=26))
        out.append(at(knife(), 132, 70, 24))
        out.append(hand(98, 142, (60, 240), 20))
    elif kind == 'pliers':
        out.append(cable(copper_state='nicked', end_x=124, strip_len=26))
        out.append(f'<path d="M118 66 l4 -6 l3 6 l4 -5" stroke="{CABLE}" stroke-width="2" fill="none"/>')
        out.append(at(pliers('vde'), 128, 74, -4, 1.25))
        out.append(hand(137, 180, (143, 250), -4))
    elif kind == 'blunt':
        out.append(cable(copper_state='crushed', end_x=118))
        out.append(at(side_cutter('vde'), 112, 74, 0, 1.25))
        out.append(hand(112, 170, (118, 250), 0))
        out.append('<g fill="#7D868E"><circle cx="106" cy="73" r="1.2"/><circle cx="118" cy="73" r="1.2"/></g>')
    elif kind == 'bare':
        out.append(cable(copper_state='clean', strip_len=20, end_x=136))
        out.append(at(stripper('bare'), 122, 74, 0, 1.25))
        out.append(hand(122, 182, (128, 250), 0))
    return card_close(out)


# ---- Round 3: screwdrivers -------------------------------------------------

def panel_stage(terminals=True):
    out = card_open('panel')
    # Four panel rivets and a terminal block.
    out.append('<g fill="#5A646C"><circle cx="14" cy="14" r="3"/><circle cx="186" cy="14" r="3"/><circle cx="14" cy="206" r="3"/><circle cx="186" cy="206" r="3"/></g>')
    if terminals:
        out.append(f'<rect x="20" y="40" width="160" height="64" rx="6" fill="{NEUTRAL}" opacity="0.85"/>')
    return out


def screw_head(x, y, kind, chewed=False):
    s = [f'<circle cx="{x}" cy="{y}" r="15" fill="url(#steel)"/>', f'<circle cx="{x}" cy="{y}" r="15" fill="none" stroke="#7D868E" stroke-width="1.2"/>']
    if kind == 'flat':
        s.append(f'<rect x="{x - 12}" y="{y - 2}" width="24" height="4" rx="1" fill="#4F575F"/>')
    else:
        s.append(f'<path d="M{x - 9} {y} L{x + 9} {y} M{x} {y - 9} L{x} {y + 9}" stroke="#4F575F" stroke-width="3.6" stroke-linecap="round"/>')
    if chewed:
        s.append(f'<g stroke="{SCRATCH}" stroke-width="1.3"><path d="M{x - 9} {y - 6} l6 3"/><path d="M{x + 4} {y + 5} l6 3"/><path d="M{x - 3} {y + 8} l4 -3"/></g>')
    return ''.join(s)


def screw_card(kind):
    out = panel_stage()
    # Three terminal screws; the tool works on the middle one.
    for i, x in enumerate((50, 100, 150)):
        sk = 'phillips' if (kind in ('phillips', 'wrong') and i == 1) else 'flat'
        out.append(screw_head(x, 72, sk, chewed=(kind in ('wrong', 'small') and i == 1)))
    if kind == 'chisel':
        out.append(at(screwdriver('flat'), 100, 72, 0))
        out.append(hand(100, 160, (110, 240), 0))
        out.append(swing(100, 192, 26, 280, 350))
        out.append(at(hammer(), 150, 188, 64))
        return card_close(out)
    tip = 'phillips' if kind == 'phillips' else 'flat'
    out.append(at(screwdriver(tip, kind='bare' if kind == 'bare' else 'vde', bent=(kind == 'bent'), short_tip=(kind == 'small')), 100, 72, 0))
    out.append(hand(100, 160, (110, 240), 0))
    if kind == 'small':
        out.append(slip_marks(112, 64))
        out.append(spark(132, 80, 0.8))
    if kind == 'bare':
        out.append(spark(118, 98, 0.8))
        out.append(f'<path d="M104 96 L126 92" stroke="{PHASE}" stroke-width="4" stroke-linecap="round"/>')
    return card_close(out)


# ---- Round 4: spanners -----------------------------------------------------

def spanner_card(kind):
    out = card_open('sky')
    out.append('<path d="M0 54 L200 46 L200 78 L0 86 Z" fill="url(#steelArm)"/>')
    # The bolt through the cross-arm and its hex nut (face on).
    nx, ny = 100, 66
    rnd = kind in ('worn', 'pliers')
    out.append(f'<circle cx="{nx}" cy="{ny}" r="22" fill="{NUT_D}"/>')
    if rnd:
        out.append(f'<path d="M{nx} {ny - 15} Q{nx + 10} {ny - 12} {nx + 13} {ny - 6} L{nx + 13} {ny + 6} Q{nx + 10} {ny + 12} {nx} {ny + 15} '
                   f'Q{nx - 10} {ny + 12} {nx - 13} {ny + 6} L{nx - 13} {ny - 6} Q{nx - 10} {ny - 12} {nx} {ny - 15} Z" fill="{NUT}"/>')
    else:
        out.append(f'<path d="M{nx} {ny - 15} L{nx + 13} {ny - 7.5} L{nx + 13} {ny + 7.5} L{nx} {ny + 15} L{nx - 13} {ny + 7.5} L{nx - 13} {ny - 7.5} Z" fill="{NUT}"/>')
    out.append(f'<circle cx="{nx}" cy="{ny}" r="5" fill="#4F575F"/>')
    if kind == 'ring':
        out.append(at(spanner_ring(), nx, ny, 0))
    elif kind == 'de':
        out.append(at(spanner_open(26), nx, ny + 2, 0))
    elif kind == 'loose':
        out.append(at(spanner_open(40), nx + 8, ny + 6, 8))
        out.append(slip_marks(128, 62))
    elif kind == 'worn':
        out.append(at(spanner_open(28, worn=True), nx, ny + 2, 0))
        out.append(f'<g stroke="{SCRATCH}" stroke-width="1.2"><path d="M88 54 l5 3"/><path d="M108 76 l5 3"/></g>')
    elif kind == 'pliers':
        out.append(at(pliers('vde', 0.9), nx, ny + 2, 0))
        out.append(f'<g stroke="{SCRATCH}" stroke-width="1.2"><path d="M88 54 l5 3"/><path d="M108 76 l5 3"/></g>')
    out.append(hand(nx, 170 if kind != 'pliers' else 164, (nx + 10, 250), 0))
    return card_close(out)


# ---- Round 5: the line tester ----------------------------------------------

def pilot_lamp(x, y):
    """The panel's 'supply on' pilot lamp, lit on every card of the round."""
    return (f'<circle cx="{x}" cy="{y}" r="12" fill="url(#glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="4.5" fill="{NEON_ON}"/><circle cx="{x}" cy="{y}" r="4.5" fill="none" stroke="#4F575F" stroke-width="1.2"/>')


def tester_panel():
    out = panel_stage(terminals=False)
    out.append(pilot_lamp(36, 98))
    # A socket (upper left) and a terminal row: phase (red), neutral (black), earth (green).
    out.append(f'<rect x="20" y="22" width="56" height="56" rx="8" fill="{SOCKET}"/>'
               f'<g fill="{NEUTRAL}"><circle cx="48" cy="38" r="4"/><circle cx="36" cy="60" r="3.4"/><circle cx="60" cy="60" r="3.4"/></g>')
    out.append(f'<rect x="92" y="30" width="90" height="40" rx="4" fill="{NEUTRAL}" opacity="0.85"/>')
    for i, (x, c) in enumerate(((108, PHASE), (137, NEUTRAL), (166, EARTH))):
        out.append(f'<path d="M{x} 66 L{x} 120 Q{x} 140 {x - 20 + i * 10} 160" stroke="{c}" stroke-width="7" fill="none"/>')
        out.append(f'<circle cx="{x}" cy="48" r="7" fill="url(#steel)"/><rect x="{x - 5}" y="47" width="10" height="2" fill="#4F575F"/>')
    return out


def tester_card(kind):
    if kind == 'ht':
        out = card_open('sky')
        # An 11 kV-class line: a big porcelain pin insulator and a bare conductor.
        out.append('<path d="M0 70 L200 62" stroke="#2B3138" stroke-width="3"/>')
        out.append('<path d="M84 72 L116 72 L110 82 L122 86 L110 96 L118 100 L104 112 L96 112 L82 100 L90 96 L78 86 L90 82 Z" fill="url(#porcelain)"/>')
        out.append('<rect x="20" y="118" width="170" height="10" fill="url(#steelArm)"/>')
        out.append(at(tester(False), 70, 72, 6))
        out.append(hand(62, 164, (40, 250), 6))
        # The same small panel on the pole below (every card shares it).
        out.append(f'<rect x="130" y="150" width="60" height="50" rx="4" fill="{SOCKET}"/>'
                   f'<g fill="{NEUTRAL}"><circle cx="160" cy="166" r="4"/></g>'
                   f'<path d="M140 200 l0 20" stroke="{PHASE}" stroke-width="5"/><path d="M160 200 l0 20" stroke="{NEUTRAL}" stroke-width="5"/>'
                   f'<path d="M180 200 l0 20" stroke="{EARTH}" stroke-width="5"/>' + pilot_lamp(142, 184))
        return card_close(out)
    out = tester_panel()
    target = {'known': (48, 38), 'phase': (108, 48), 'neutral': (137, 48), 'earth': (166, 48)}[kind]
    lit = kind in ('known', 'phase')
    x, y = target
    out.append(at(tester(lit), x, y, 0))
    out.append(hand(x, y + 98, (x + 10, 260), 0))
    return card_close(out)


CARDS = {
    'pliers_vde': pliers_card('vde'),
    'pliers_cut': pliers_card('cut'),
    'pliers_bare': pliers_card('bare'),
    'pliers_cracked': pliers_card('cracked'),
    'pliers_burnt': pliers_card('burnt'),
    'pliers_hammer': pliers_card('hammer'),
    'strip_stripper': strip_card('stripper'),
    'strip_cutter': strip_card('cutter'),
    'strip_knife': strip_card('knife'),
    'strip_pliers': strip_card('pliers'),
    'strip_blunt': strip_card('blunt'),
    'strip_bare': strip_card('bare'),
    'screw_flat': screw_card('flat'),
    'screw_phillips': screw_card('phillips'),
    'screw_small': screw_card('small'),
    'screw_wrong': screw_card('wrong'),
    'screw_chisel': screw_card('chisel'),
    'screw_bare': screw_card('bare'),
    'screw_bent': screw_card('bent'),
    'spanner_ring': spanner_card('ring'),
    'spanner_de': spanner_card('de'),
    'spanner_loose': spanner_card('loose'),
    'spanner_worn': spanner_card('worn'),
    'spanner_pliers': spanner_card('pliers'),
    'tester_known': tester_card('known'),
    'tester_phase': tester_card('phase'),
    'tester_neutral': tester_card('neutral'),
    'tester_earth': tester_card('earth'),
    'tester_ht': tester_card('ht'),
}

# Safe cards and traps per round (mirrors learn_board_pack21.dart).
ROUNDS = {
    'pliers': (['pliers_vde', 'pliers_cut'], ['pliers_bare', 'pliers_cracked', 'pliers_burnt', 'pliers_hammer']),
    'strip': (['strip_stripper', 'strip_cutter'], ['strip_knife', 'strip_pliers', 'strip_blunt', 'strip_bare']),
    'screw': (['screw_flat', 'screw_phillips'], ['screw_small', 'screw_wrong', 'screw_chisel', 'screw_bare', 'screw_bent']),
    'spanner': (['spanner_ring', 'spanner_de'], ['spanner_loose', 'spanner_worn', 'spanner_pliers']),
    'tester': (['tester_known', 'tester_phase'], ['tester_neutral', 'tester_earth', 'tester_ht']),
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
