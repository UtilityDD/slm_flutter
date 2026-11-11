"""Picture cards for the Module 2 lesson 2.6 board (কেবিল স্কিনিং-এর শিল্প).

python -I tool/m2_board26_art.py .

Writes assets/game/art/m2_board26/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 2.6 only:
  1. tool: the cable skinning knife (blade shaped to cut insulation, not the
     conductor) and the wire stripper are the right tools; an ordinary knife,
     a blunt cutter (extra force, it slips), a dirty / rusty blade (the daily
     check: sharp and clean) and teeth (myth 2) are wrong;
  2. stroke: the 'pencil sharpening' technique: a slight angle, thumb on the
     blunt back, cut away from the body, cut-resistant gloves; never pull
     towards yourself, never cut round (a ring mark), a steep blade nicks;
  3. length: strip to the crimping lug barrel's length (measure first) — not
     too long, not too short;
  4. inspect: the conductor smooth and bright, the insulation edge square
     (90 degrees); no deep nick, black mark, cut strand or torn edge;
  5. ab: AB cable insulation (XLPE) is much harder — the special stripping
     tool; start light (a groove first, then more pressure); in cold weather
     insulation is hard and brittle and cracks easily.

Fairness (the playbook, section 4): every card in a round shares one
backdrop, one gloved hand and one cable; only the act tells the safe card
from a trap. The script checks every hand the dealer can make (one safe card
+ any three traps): each colour or gradient the safe card draws is drawn by
a trap in that hand, and the safe card's backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board26_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board26')
W, H = 200, 220

GLOVE = '#8F9A7A'      # cut-resistant knit glove
GLOVE_D = '#6E785C'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
CABLE = '#2B3138'
CABLE_L = '#4A525A'
HANDLE = '#E0A21F'
HANDLE_D = '#B07A12'
WOOD = '#8A5A32'
RUST = '#9A4A22'
CRACK = '#14161A'
BURN = '#2A1A10'
WHITE = '#FFFFFF'
TOOTH = '#F4EFE2'
FROST = '#DDEFFF'

DEFS = """<defs>
  <linearGradient id="canvas" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5B6B5A"/><stop offset="1" stop-color="#3E4B3F"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A6A58"/><stop offset="1" stop-color="#55493C"/></linearGradient>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4E6E8E"/><stop offset="1" stop-color="#9DB8CC"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B27A"/><stop offset="0.5" stop-color="#D2843F"/><stop offset="1" stop-color="#9A5A25"/></linearGradient>
  <linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2F4F6"/><stop offset="0.5" stop-color="#C4CACF"/><stop offset="1" stop-color="#8E979E"/></linearGradient>
  <linearGradient id="tin" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6EAEE"/><stop offset="0.5" stop-color="#B9C1C7"/><stop offset="1" stop-color="#8A939A"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="lens" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.18"/><stop offset="1" stop-color="#CFE6FF" stop-opacity="0.32"/></radialGradient>
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


def hand(x, y, from_xy, ang=0, bare=False):
    """A blue sleeve and a cut-resistant glove (or a bare hand) from the card's edge to a fist at (x, y)."""
    ex, ey = from_xy
    mx, my = x + (ex - x) * 0.45, y + (ey - y) * 0.45
    g, gd = (SKIN, SKIN_D) if bare else (GLOVE, GLOVE_D)
    return (f'<path d="M{f(ex)} {f(ey)} L{f(mx)} {f(my)}" stroke="url(#shirt)" stroke-width="26" stroke-linecap="round"/>'
            f'<path d="M{f(mx)} {f(my)} L{f(x)} {f(y)}" stroke="{g}" stroke-width="21" stroke-linecap="round"/>'
            + at(f'<rect x="-13" y="-11" width="26" height="22" rx="8" fill="{g}"/>'
                 f'<path d="M-6 -11 L-6 -4 M0 -11 L0 -4 M6 -11 L6 -4" stroke="{gd}" stroke-width="1.6" stroke-linecap="round"/>', x, y, ang))


def grip(tip, ang, dist, back=70):
    """The fist position `dist` behind a tool tip at `tip` pointing at `ang`, and an arm start further back."""
    dx, dy = math.sin(math.radians(ang)), -math.cos(math.radians(ang))
    hx, hy = tip[0] - dx * dist, tip[1] - dy * dist
    return (hx, hy), (hx - dx * back, hy - dy * back)


def held(tool_svg, tip, ang, dist, back=70, bare=False):
    (hx, hy), arm = grip(tip, ang, dist, back)
    return at(tool_svg, tip[0], tip[1], ang) + hand(hx, hy, arm, ang + 90, bare=bare)


def arrow(x0, y0, x1, y1, op=0.9):
    a = math.atan2(y1 - y0, x1 - x0)
    l, w = 9, 6
    p1 = (x1 - l * math.cos(a) + w * math.sin(a), y1 - l * math.sin(a) - w * math.cos(a))
    p2 = (x1 - l * math.cos(a) - w * math.sin(a), y1 - l * math.sin(a) + w * math.cos(a))
    return (f'<g opacity="{op}"><path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{WHITE}" stroke-width="3" stroke-linecap="round" stroke-dasharray="6 4"/>'
            f'<path d="M{f(x1)} {f(y1)} L{f(p1[0])} {f(p1[1])} L{f(p2[0])} {f(p2[1])} Z" fill="{WHITE}"/></g>')


def slip_marks(x, y):
    return (f'<g stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round" opacity="0.85">'
            f'<path d="M{f(x)} {f(y)} l10 -6"/><path d="M{f(x + 2)} {f(y + 7)} l12 -5"/><path d="M{f(x + 4)} {f(y + 14)} l10 -4"/></g>')


def nick_marks(x, y, s=1.0):
    return (f'<g stroke="{CRACK}" stroke-width="{f(1.5 * s)}" stroke-linecap="round">'
            f'<path d="M{f(x)} {f(y - 4 * s)} l{f(2 * s)} {f(5 * s)}"/><path d="M{f(x + 7 * s)} {f(y - 4 * s)} l{f(2 * s)} {f(5 * s)}"/></g>')


# --------------------------------------------------------------------------
# Tools: working end at (0, 0) pointing up (negative y), the grip below.
# --------------------------------------------------------------------------

def skin_knife():
    """Cable skinning knife: a short hooked blade, insulated yellow handle."""
    return ('<path d="M0 0 Q9 10 6 34 L-4 34 Q-5 18 -2 6 Q-3 2 0 0 Z" fill="url(#steel)"/>'
            '<path d="M-2 6 Q4 12 3 30" stroke="#7D868E" stroke-width="0.9" fill="none"/>'
            f'<rect x="-6" y="34" width="13" height="48" rx="5" fill="{HANDLE}"/>'
            f'<rect x="-6" y="34" width="13" height="6" rx="2" fill="{HANDLE_D}"/>')


def plain_knife(blade='steel', handle=WOOD, chipped=False):
    """An ordinary (kitchen / utility) knife: a long straight blade."""
    fill = f'url(#{blade})' if blade == 'steel' else blade
    edge = 'L4 4 L4 44' if not chipped else 'L4 4 L2 10 L5 14 L2 20 L5 26 L2 32 L4 44'
    s = f'<path d="M-3 0 {edge} L-5 44 Q-7 20 -3 0 Z" fill="{fill}"/>'
    s += f'<rect x="-7" y="44" width="13" height="42" rx="4" fill="{handle}"/>'
    s += '<path d="M-3 2 Q-6 22 -4 42" stroke="#7D868E" stroke-width="0.9" fill="none"/>'
    s += f'<rect x="-7" y="44" width="13" height="6" rx="2" fill="{HANDLE_D}"/>'
    s += '<circle cx="-0.5" cy="60" r="1.6" fill="#4F575F"/><circle cx="-0.5" cy="76" r="1.6" fill="#4F575F"/>'
    return s


def rusty_knife():
    s = plain_knife(handle=HANDLE)
    s += (f'<g fill="{RUST}"><ellipse cx="-1" cy="12" rx="3" ry="4"/><ellipse cx="1" cy="26" rx="3.2" ry="5"/>'
          f'<ellipse cx="-2" cy="36" rx="2.4" ry="3"/></g>'
          f'<g fill="{BURN}" opacity="0.7"><circle cx="2" cy="18" r="1.4"/><circle cx="-2" cy="31" r="1.2"/></g>')
    return s


def stripper(handle=HANDLE):
    """Wire stripper: straight jaws with a row of size notches, yellow handles."""
    s = []
    for side in (-1, 1):
        x0, y0 = side * 3.5, 36
        x1, y1 = side * 10, 102
        s.append(f'<path d="M{f(x0 - 4)} {f(y0)} L{f(x0 + 4)} {f(y0)} L{f(x1 + 4.5)} {f(y1)} Q{f(x1)} {f(y1 + 6)} {f(x1 - 4.5)} {f(y1)} Z" fill="{handle}"/>')
    notches = ''.join(f'<circle cx="0" cy="{f(6 + i * 5.2)}" r="{f(1.2 + i * 0.35)}" fill="#4F575F"/>' for i in range(4))
    s.append('<path d="M-1 30 L-8 26 L-8 0 L-1 -2 Z" fill="url(#steel)"/><path d="M1 30 L8 26 L8 0 L1 -2 Z" fill="url(#steel)"/>' + notches
             + '<circle cx="0" cy="29" r="4.2" fill="#7D868E"/><circle cx="0" cy="29" r="1.6" fill="#4F575F"/>')
    return ''.join(s)


def ab_tool():
    """AB cable insulation stripping tool: a clamp body around the core, a set blade, a yellow handle."""
    return ('<rect x="-14" y="-8" width="28" height="30" rx="5" fill="url(#steel)"/>'
            '<path d="M-14 6 L14 6" stroke="#7D868E" stroke-width="1.2"/>'
            f'<rect x="-5" y="22" width="10" height="56" rx="4" fill="{HANDLE}"/>'
            f'<rect x="-5" y="22" width="10" height="6" rx="2" fill="{HANDLE_D}"/>'
            '<circle cx="0" cy="-2" r="3" fill="#4F575F"/>')


# --------------------------------------------------------------------------
# The cable (horizontal, coming in from the left) and its bared end.
# --------------------------------------------------------------------------

def cable(y=96, end_x=128, strip_len=34, metal='copper', state='clean', w=16, core=CABLE, edge='square', strands=True):
    """An insulated cable to end_x, then the bared conductor (strip_len long).
    state: clean | nicked | ring | black | strand | crushed | none."""
    h = w / 2
    cw = w * 0.55
    s = [f'<rect x="-6" y="{f(y - h)}" width="{f(end_x + 6)}" height="{f(w)}" fill="{core}"/>',
         f'<path d="M-6 {f(y - h + 2.5)} L{f(end_x)} {f(y - h + 2.5)}" stroke="{CABLE_L}" stroke-width="2"/>']
    if state != 'none':
        cx = end_x
        s.append(f'<rect x="{f(cx)}" y="{f(y - cw / 2)}" width="{f(strip_len)}" height="{f(cw)}" rx="2" fill="url(#{metal})"/>')
        if metal == 'copper' and strands:
            s.append(f'<path d="M{f(cx)} {f(y - cw / 6)} L{f(cx + strip_len)} {f(y - cw / 6)} M{f(cx)} {f(y + cw / 6)} L{f(cx + strip_len)} {f(y + cw / 6)}" stroke="#9A5A25" stroke-width="0.7"/>')
        if state == 'nicked':
            s.append(nick_marks(cx + strip_len * 0.25, y - cw / 2 + 2, w / 16))
        elif state == 'ring':
            for k in (0.3, 0.55):
                xx = cx + strip_len * k
                s.append(f'<path d="M{f(xx)} {f(y - cw / 2)} q3 {f(cw / 2)} 0 {f(cw)}" stroke="{CRACK}" stroke-width="{f(1.4 * w / 16)}" fill="none"/>')
        elif state == 'black':
            s.append(f'<g fill="{BURN}" opacity="0.85"><ellipse cx="{f(cx + strip_len * 0.35)}" cy="{f(y)}" rx="{f(cw * 0.45)}" ry="{f(cw * 0.32)}"/>'
                     f'<ellipse cx="{f(cx + strip_len * 0.7)}" cy="{f(y + cw * 0.15)}" rx="{f(cw * 0.3)}" ry="{f(cw * 0.22)}"/></g>')
        elif state == 'strand':
            s.append(f'<path d="M{f(cx + strip_len * 0.4)} {f(y - cw / 2)} l{f(cw * 0.6)} {f(-cw * 1.1)} M{f(cx + strip_len * 0.5)} {f(y - cw / 2)} l{f(cw * 0.9)} {f(-cw * 0.8)}" '
                     f'stroke="#D2843F" stroke-width="{f(1.6 * w / 16)}" stroke-linecap="round"/>'
                     f'<path d="M{f(cx + strip_len * 0.4)} {f(y - cw / 2 + 1)} L{f(cx + strip_len * 0.56)} {f(y - cw / 2 + 1)}" stroke="{CRACK}" stroke-width="{f(1.2 * w / 16)}"/>')
        elif state == 'crushed':
            s.append(f'<path d="M{f(cx + 4)} {f(y - cw / 2)} l4 3 l4 -3 l4 3" stroke="{CRACK}" stroke-width="1.2" fill="none"/>')
    if edge == 'torn':
        # A ragged, uneven insulation edge with a torn flap.
        s.append(f'<path d="M{f(end_x - 1)} {f(y - h)} l5 3 l-3 3 l6 3 l-4 3 l5 {f(w - 12)} l-9 0 Z" fill="{core}"/>'
                 f'<path d="M{f(end_x + 2)} {f(y - h)} l10 -7 l2 5 Z" fill="{core}"/>')
    return ''.join(s)


def shaving(x, y, s=1.0):
    """A curl of skinned insulation lifting off ahead of the blade."""
    return f'<path d="M{f(x)} {f(y)} q{f(10 * s)} {f(-4 * s)} {f(14 * s)} {f(-14 * s)} q{f(2 * s)} {f(-8 * s)} {f(-6 * s)} {f(-6 * s)}" stroke="{CABLE}" stroke-width="{f(4 * s)}" fill="none" stroke-linecap="round"/>'


# ---- Round 1: which tool ---------------------------------------------------

def bench_stage():
    out = card_open('canvas')
    out.append('<g stroke="#2F3A30" stroke-width="1.4" stroke-dasharray="4 3" fill="none">'
               '<path d="M0 176 L200 176"/><path d="M40 176 L40 220 M80 176 L80 220 M120 176 L120 220 M160 176 L160 220"/></g>')
    out.append('<g fill="#4F575F">' + ''.join(f'<circle cx="{x}" cy="184" r="2.4"/>' for x in (20, 60, 100, 140, 180)) + '</g>')
    return out


def tool_card(kind):
    out = bench_stage()
    n = len(out)
    card_close_ = _tool_card(kind, out)
    return card_close_


def _zoomed(out, n, s=1.4, cx=110, cy=104):
    """Wrap everything drawn after the stage (index n) in a zoom about (cx, cy)."""
    out.insert(n, f'<g transform="translate({f(cx)} {f(cy)}) scale({s}) translate({f(-cx)} {f(-cy)})">')
    out.append('</g>')
    return card_close(out)


def _tool_card(kind, out):
    n = len(out)
    card_close = lambda o: _zoomed(o, n)  # noqa: E731
    if kind == 'teeth':
        out.append(cable(y=92, end_x=104, strip_len=18, state='nicked'))
        # A worker's head in profile biting the cable end.
        out.append(f'<ellipse cx="160" cy="92" rx="34" ry="40" fill="{SKIN}"/>'
                   f'<path d="M126 70 Q140 40 172 48 Q196 56 194 92 L186 92 Q182 66 160 62 Q138 62 132 76 Z" fill="{HAIR}"/>'
                   f'<path d="M124 92 L140 86 L140 100 Z" fill="{SKIN_D}"/>'
                   f'<rect x="118" y="86" width="14" height="4" fill="{TOOTH}"/><rect x="118" y="98" width="14" height="4" fill="{TOOTH}"/>'
                   f'<circle cx="138" cy="74" r="3" fill="{HAIR}"/>'
                   f'<path d="M150 132 L150 160 L188 160 L188 128" fill="url(#shirt)"/>')
        out.append(f'<path d="M116 80 l-6 -8 M112 106 l-6 8" stroke="{WHITE}" stroke-width="1.6" stroke-linecap="round"/>')
        out.append(hand(60, 118, (20, 240), 10))
        return card_close(out)
    clean = kind in ('skinning', 'stripper')
    state = {'skinning': 'none', 'stripper': 'clean', 'kitchen': 'nicked', 'blunt': 'crushed', 'rusty': 'nicked'}[kind]
    if kind == 'stripper':
        out.append(cable(end_x=120, strip_len=24, state='clean'))
        out.append(f'<rect x="150" y="89" width="22" height="16" rx="2" fill="{CABLE}" transform="rotate(10 160 96)"/>')
        out.append(held(stripper(), (110, 96), 0, 76))
        return card_close(out)
    if kind == 'skinning':
        out.append(cable(end_x=150, strip_len=24, state='none'))
        # The bared stretch already skinned, clean copper, the next shaving lifting.
        out.append('<rect x="124" y="91.6" width="50" height="8.8" rx="2" fill="url(#copper)"/>')
        out.append(shaving(118, 88))
    else:
        out.append(cable(end_x=124, strip_len=40, state=state))
    tools = {'skinning': skin_knife(), 'kitchen': plain_knife(), 'blunt': plain_knife(handle=HANDLE, chipped=True), 'rusty': rusty_knife()}
    ang = 70
    tip = (122, 88) if clean else (132, 90)
    out.append(held(tools[kind], tip, ang, 66))
    if kind == 'blunt':
        out.append(slip_marks(140, 102))
    return card_close(out)


# ---- Round 2: the stroke ---------------------------------------------------

def body_stage():
    """The worker's chest on the left, the cable held out to the right."""
    out = card_open('bench')
    out.append('<path d="M-10 40 Q30 34 34 70 L36 220 L-10 220 Z" fill="url(#shirt)"/>'
               '<path d="M20 60 L22 220" stroke="#174A70" stroke-width="2"/>')
    return out


def stroke_card(kind):
    out = body_stage()
    y = 120
    state = {'away': 'none', 'thumb': 'none', 'toward': 'none', 'round': 'ring', 'steep': 'nicked', 'bare': 'none'}[kind]
    out.append(cable(y=y, end_x=150, strip_len=34, state=state, w=18))
    if state == 'none':
        out.append(f'<rect x="150" y="{y - 5}" width="40" height="10" rx="2" fill="url(#copper)"/>')
    # The left hand holding the cable near the body.
    out.append(hand(66, y + 2, (30, y + 60), 0, bare=(kind == 'bare')))
    if kind in ('away', 'bare', 'thumb'):
        tip = (150, y - 8)
        out.append(shaving(150, y - 9, 1.1))
        out.append(held(skin_knife(), tip, 108, 62, back=60, bare=(kind == 'bare')))
        if kind == 'thumb':
            # The thumb pressing on the blade's blunt back.
            out.append(f'<ellipse cx="140" cy="{y - 18}" rx="7" ry="4.5" fill="{GLOVE}" transform="rotate(18 140 {y - 18})"/>')
        out.append(arrow(120, y - 46, 176, y - 30))
    elif kind == 'toward':
        tip = (104, y - 8)
        out.append(held(skin_knife(), tip, -72, 62, back=60))
        out.append(arrow(170, y - 30, 112, y - 50))
    elif kind == 'round':
        out.append(at(skin_knife(), 128, y - 9, 180))
        out.append(f'<ellipse cx="128" cy="{y}" rx="9" ry="16" fill="none" stroke="{WHITE}" stroke-width="2.4" stroke-dasharray="5 4"/>')
        out.append(f'<path d="M137 {y - 4} l5 -6 l2 8 Z" fill="{WHITE}"/>')
        out.append(hand(128, y - 52 - 34, (168, -20), 180))
    elif kind == 'steep':
        tip = (156, y - 2)
        out.append(held(skin_knife(), tip, 180, 64, back=50))
        out.append(arrow(176, y - 80, 176, y - 40))
    return card_close(out)


# ---- Round 3: the length ---------------------------------------------------

def lug(x, y, barrel=40, s=1.0):
    """Crimping lug: a tinned barrel (length `barrel`) and a flat palm with a bolt hole, barrel opening at x."""
    return (f'<rect x="{f(x)}" y="{f(y - 9)}" width="{f(barrel)}" height="18" rx="4" fill="url(#tin)"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="3" ry="8" fill="#5A646C"/>'
            f'<path d="M{f(x + barrel)} {f(y - 7)} L{f(x + barrel + 12)} {f(y - 13)} L{f(x + barrel + 34)} {f(y - 13)} Q{f(x + barrel + 46)} {f(y)} {f(x + barrel + 34)} {f(y + 13)} '
            f'L{f(x + barrel + 12)} {f(y + 13)} L{f(x + barrel)} {f(y + 7)} Z" fill="url(#tin)"/>'
            f'<circle cx="{f(x + barrel + 30)}" cy="{f(y)}" r="5" fill="#4F575F"/>')


def length_card(kind):
    out = card_open('canvas')
    barrel = 40
    end_x = 70
    copper = {'match': barrel, 'measure': 0, 'long': barrel + 34, 'short': 14, 'guess': barrel + 18}[kind]
    out.append(lug(end_x, 60, barrel))
    # The barrel's depth carried down by guide marks on every card.
    out.append(f'<g stroke="{WHITE}" stroke-width="1.4" stroke-dasharray="3 3" opacity="0.7"><path d="M{end_x} 72 L{end_x} 150"/><path d="M{end_x + barrel} 72 L{end_x + barrel} 150"/></g>')
    if kind == 'measure':
        out.append(cable(y=130, end_x=170, state='none'))
        # A score mark at the barrel length from the end, the knife tip on it.
        mark = 170 - barrel
        out.append(f'<path d="M{mark} 122 L{mark} 138" stroke="{WHITE}" stroke-width="2"/>')
        out.append(f'<g stroke="{WHITE}" stroke-width="1.4" opacity="0.7"><path d="M{mark} 150 L170 150"/><path d="M{mark} 146 l0 8 M170 146 l0 8"/></g>')
        out.append(held(skin_knife(), (mark, 121), 30, 60))
    else:
        out.append(cable(y=130, end_x=end_x, strip_len=copper, state='clean'))
        if kind == 'guess':
            out.append(held(plain_knife(handle=HANDLE), (end_x + 2, 121), 30, 66))
            out.append(f'<path d="M{end_x + 4} 122 l3 -4 l3 4 l3 -4" stroke="{CRACK}" stroke-width="1.2" fill="none"/>')
        else:
            out.append(hand(30, 160, (-10, 230), 20))
    return card_close(out)


# ---- Round 4: the final inspection ------------------------------------------

def inspect_card(kind):
    out = card_open('bench')
    metal = 'copper'
    state = {'copper': 'clean', 'solid': 'clean', 'nick': 'nicked', 'black': 'black', 'strand': 'strand', 'torn': 'clean'}[kind]
    out.append(cable(y=104, end_x=86, strip_len=104, metal=metal, state=state, w=40,
                     edge='torn' if kind == 'torn' else 'square', strands=(kind != 'solid')))
    # The magnifying glass over the bared end (on every card).
    out.append('<circle cx="128" cy="100" r="44" fill="url(#lens)" stroke="#2B3138" stroke-width="7"/>'
               f'<path d="M158 134 L186 170" stroke="{HANDLE}" stroke-width="12" stroke-linecap="round"/>'
               f'<path d="M156 131 L162 139" stroke="{HANDLE_D}" stroke-width="12"/>')
    out.append(hand(188, 176, (220, 240), -40))
    return card_close(out)


# ---- Round 5: AB cable -----------------------------------------------------

def ab_stage(cold=False):
    out = card_open('dusk')
    # The AB cable bundle: the other cores twisted behind the one being skinned.
    for k, yy in enumerate((60, 74)):
        out.append(f'<path d="M-6 {yy} Q60 {yy - 8} 120 {yy} T220 {yy}" stroke="{CABLE}" stroke-width="12" fill="none"/>')
    if cold:
        out.append(f'<g stroke="{FROST}" stroke-width="1.8" stroke-linecap="round">'
                   + ''.join(f'<path d="M{x - 6} {y} l12 0 M{x} {y - 6} l0 12 M{x - 4} {y - 4} l8 8 M{x - 4} {y + 4} l8 -8"/>'
                             for x, y in ((24, 26), (100, 20), (172, 32), (176, 196)))
                   + '</g>')
    return out


def ab_card(kind):
    out = ab_stage(cold=(kind == 'cold'))
    y = 128
    state = {'tool': 'clean', 'light': 'none', 'force': 'nicked', 'cold': 'none', 'oneshot': 'nicked', 'blunt': 'crushed'}[kind]
    out.append(cable(y=y, end_x=120, strip_len=40, metal='alu', state=state, w=18))
    if kind == 'tool':
        out.append(at(ab_tool(), 104, y, 0))
        out.append(hand(104, y + 84, (114, 260), 0))
        out.append(f'<rect x="150" y="{y + 18}" width="20" height="14" rx="2" fill="{CABLE}" transform="rotate(14 160 {y + 25})"/>')
    elif kind == 'light':
        out.append(f'<path d="M100 {y - 9} L100 {y - 4}" stroke="{CRACK}" stroke-width="1.4"/>')
        out.append(held(skin_knife(), (100, y - 10), 150, 62))
        out.append(f'<g stroke="{WHITE}" stroke-width="2" stroke-linecap="round" opacity="0.85"><path d="M124 {y - 52} l0 8"/><path d="M134 {y - 56} l0 14"/><path d="M144 {y - 60} l0 20"/></g>')
    elif kind == 'cold':
        out.append(f'<path d="M86 {y - 9} l4 6 l-3 4 l5 6 M100 {y + 9} l3 -6 l-4 -3 l3 -5" stroke="{CRACK}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M120 {y} l40 -24" stroke="{CABLE}" stroke-width="18"/><path d="M118 {y - 9} l5 6 l-4 4" stroke="{CRACK}" stroke-width="1.6" fill="none"/>')
        out.append(hand(166, y - 28, (230, y - 60), -60))
        out.append(hand(70, y + 4, (40, 260), 0))
    elif kind in ('force', 'oneshot', 'blunt'):
        k = plain_knife(handle=HANDLE, chipped=(kind == 'blunt'))
        out.append(held(k, (112, y - 2), 180 if kind == 'oneshot' else 160, 66, back=50))
        if kind == 'force':
            out.append(slip_marks(132, y + 14))
        out.append(f'<g stroke="{WHITE}" stroke-width="3" stroke-linecap="round" opacity="0.85"><path d="M150 {y - 70} l0 22"/><path d="M162 {y - 74} l0 30"/><path d="M174 {y - 78} l0 38"/></g>')
    return card_close(out)


CARDS = {}
for k in ('skinning', 'stripper', 'kitchen', 'blunt', 'rusty', 'teeth'):
    CARDS[f'tool_{k}'] = tool_card(k)
for k in ('away', 'thumb', 'toward', 'round', 'steep', 'bare'):
    CARDS[f'stroke_{k}'] = stroke_card(k)
for k in ('match', 'measure', 'long', 'short', 'guess'):
    CARDS[f'length_{k}'] = length_card(k)
for k in ('copper', 'solid', 'nick', 'black', 'strand', 'torn'):
    CARDS[f'inspect_{k}'] = inspect_card(k)
for k in ('tool', 'light', 'force', 'cold', 'oneshot', 'blunt'):
    CARDS[f'ab_{k}'] = ab_card(k)

# Safe cards and traps per round (mirrors learn_board_pack26.dart).
ROUNDS = {
    'tool': (['tool_skinning', 'tool_stripper'], ['tool_kitchen', 'tool_blunt', 'tool_rusty', 'tool_teeth']),
    'stroke': (['stroke_away', 'stroke_thumb'], ['stroke_toward', 'stroke_round', 'stroke_steep', 'stroke_bare']),
    'length': (['length_match', 'length_measure'], ['length_long', 'length_short', 'length_guess']),
    'inspect': (['inspect_copper', 'inspect_solid'], ['inspect_nick', 'inspect_black', 'inspect_strand', 'inspect_torn']),
    'ab': (['ab_tool', 'ab_light'], ['ab_force', 'ab_cold', 'ab_oneshot', 'ab_blunt']),
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
    for p in sorted(set(p.split(' with ')[0] + ' ' + p.split(' draws ')[-1] if ' draws ' in p else p for p in bad)):
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
