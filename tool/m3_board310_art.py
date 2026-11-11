"""Picture cards for lesson 3.10 শেখা ("লাইন ডায়াগ্রাম পড়া: কাগজের ওপর জাদুর নকশা").

python -I tool/m3_board310_art.py .

Writes assets/game/art/m3_board310/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the diagrams are drawn with their symbols only.

What the cards show comes from lesson 3.10 and its film script only:
  1. one: an SLD shows the three wires (R, Y, B) of a three-phase system as a
     single line — in the field that line is three wires (or a three-core
     cable), not one or two;
  2. tx: the transformer symbol is two coils that do not touch; the circuit
     breaker is a small box, the isolator / AB switch a broken line on a
     straight line, the lightning arrester an arrow-head on a box going to
     earth, earthing a few parallel lines;
  3. iso: the isolator symbol (an isolator is never opened on load); the DO
     fuse is a fuse symbol with an arrow-like mark; a plain line is a line;
  4. ring: on a ring / interconnected feeder power may come from the other
     side too; before work the work area and the isolation points are marked
     on the diagram (both sides of the work section — inferred, see REGISTER);
  5. field: an old diagram may not match the field (a new line not on it) —
     always match the diagram with the field; mark the work area and the
     isolation points before work; memory can be wrong.

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
    print('usage: python -I tool/m3_board310_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board310')
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
COPPER = '#D98A3D'
INK = '#25323D'
PENCIL = '#D8402F'
MARK = '#F0C02E'
FEED = '#FF7A2E'
EARTH = '#3E9B4F'
FACE = '#1E2329'

DEFS = """<defs>
  <linearGradient id="desk" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#5B4636"/><stop offset="1" stop-color="#7C6350"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBF7EC"/><stop offset="1" stop-color="#ECE4D0"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#CFE3EE"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="sheath" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A3F45"/><stop offset="1" stop-color="#22262B"/></linearGradient>
  <linearGradient id="van" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2F4F6"/><stop offset="1" stop-color="#C9D0D6"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="ladder" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9A25A"/><stop offset="1" stop-color="#A9823E"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFE38A"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
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


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="{FEED}" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


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


def _hand(p, point=0):
    x, y = p
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{GLOVE}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, point=(0, 0), props_front=''):
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
    g.append(_hand(hb, point[0]))
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
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf, point[1]))
    return ''.join(g)


S = 1.32


def worker(x, hands_world, face=-1, look=0, point=(0, 0), props_front=''):
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, point, props_front)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'


# --------------------------------------------------------------------------
# SLD symbols, drawn round a vertical line through (cx, cy); s = scale.
# --------------------------------------------------------------------------

def _ln(x0, y0, x1, y1, w=3.0, col=INK):
    return f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{col}" stroke-width="{f(w)}" stroke-linecap="round" fill="none"/>'


def sym(kind, cx, cy, s=1.0, top=None, bottom=None, w=3.0):
    """One symbol with the line coming in from `top` and going out at
    `bottom` (y values); the symbol spans about cy ± 22·s."""
    top = cy - 60 * s if top is None else top
    bottom = cy + 60 * s if bottom is None else bottom
    o = []
    if kind == 'coils':
        # Two coils facing each other with a gap: they do not touch.
        r = 6 * s
        for d in (-1, 1):
            y = cy + d * 5 * s
            path = f'M{f(cx - 18 * s)} {f(y)}'
            for i in range(3):
                x1 = cx - 18 * s + (i + 1) * 2 * r
                path += f' A{f(r)} {f(r)} 0 0 {1 if d < 0 else 0} {f(x1)} {f(y)}'
            o.append(f'<path d="{path}" stroke="{INK}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>')
        o.append(_ln(cx, top, cx, cy - 5 * s - r, w))
        o.append(_ln(cx, cy + 5 * s + r, cx, bottom, w))
    elif kind == 'box':
        a = 13 * s
        o.append(_ln(cx, top, cx, cy - a, w))
        o.append(f'<rect x="{f(cx - a)}" y="{f(cy - a)}" width="{f(2 * a)}" height="{f(2 * a)}" fill="none" stroke="{INK}" stroke-width="{f(w)}"/>')
        o.append(_ln(cx, cy + a, cx, bottom, w))
    elif kind == 'break':
        # A broken line over the straight line: the open blade of the isolator.
        g = 14 * s
        o.append(_ln(cx, top, cx, cy - g, w))
        o.append(_ln(cx - 7 * s, cy - g, cx + 7 * s, cy - g, w))
        o.append(_ln(cx, cy + g, cx + 15 * s, cy - g + 2 * s, w))
        o.append(f'<circle cx="{f(cx)}" cy="{f(cy + g)}" r="{f(2.6 * s)}" fill="{INK}"/>')
        o.append(_ln(cx, cy + g, cx, bottom, w))
    elif kind == 'fuse':
        # The fuse symbol with an arrow-like mark (the drop-out fuse).
        o.append(_ln(cx, top, cx, bottom, w))
        o.append(f'<rect x="{f(cx - 6 * s)}" y="{f(cy - 15 * s)}" width="{f(12 * s)}" height="{f(30 * s)}" fill="none" stroke="{INK}" stroke-width="{f(w)}"/>')
        o.append(_ln(cx - 14 * s, cy + 12 * s, cx + 12 * s, cy - 14 * s, w * 0.8))
        o.append(f'<path d="M{f(cx + 15 * s)} {f(cy - 17 * s)} L{f(cx + 5 * s)} {f(cy - 14 * s)} L{f(cx + 12 * s)} {f(cy - 7 * s)} Z" fill="{INK}"/>')
    elif kind == 'arrester':
        # An arrow-head joined to a box, going down to earth.
        o.append(_ln(cx, top, cx, cy - 18 * s, w))
        o.append(f'<path d="M{f(cx - 7 * s)} {f(cy - 18 * s)} L{f(cx + 7 * s)} {f(cy - 18 * s)} L{f(cx)} {f(cy - 8 * s)} Z" fill="{INK}"/>')
        o.append(f'<rect x="{f(cx - 8 * s)}" y="{f(cy - 8 * s)}" width="{f(16 * s)}" height="{f(20 * s)}" fill="none" stroke="{INK}" stroke-width="{f(w)}"/>')
        o.append(_ln(cx, cy + 12 * s, cx, cy + 24 * s, w))
        o.append(_earth(cx, cy + 24 * s, s * 0.8, w))
    elif kind == 'earth':
        o.append(_ln(cx, top, cx, cy - 4 * s, w))
        o.append(_earth(cx, cy - 4 * s, s * 1.2, w))
    elif kind == 'line':
        o.append(_ln(cx, top, cx, bottom, w))
    return ''.join(o)


def _earth(cx, y, s, w):
    return ''.join(_ln(cx - hw * s, y + i * 6 * s, cx + hw * s, y + i * 6 * s, w)
                   for i, hw in enumerate((14, 9, 4)))


def sheet():
    out = card_open('desk')
    out.append('<rect x="14" y="12" width="172" height="196" rx="4" fill="url(#paper)"/>')
    # Faint grid lines on the drawing sheet.
    out.append('<g stroke="#D9CFB8" stroke-width="0.6">'
               + ''.join(f'<path d="M14 {y} L186 {y}"/>' for y in range(32, 208, 20))
               + ''.join(f'<path d="M{x} 12 L{x} 208"/>' for x in range(34, 186, 20)) + '</g>')
    return out


def symbol_card(kind, turned=False):
    """A drawing sheet with one big symbol on its line (turned = the line runs
    across the sheet)."""
    out = sheet()
    g = sym(kind, 100, 110, 2.0, top=24, bottom=196 if kind not in ('earth', 'arrester') else None, w=4)
    if kind in ('earth', 'arrester'):
        g = sym(kind, 100, 96 if kind == 'earth' else 92, 2.0, top=24, w=4)
    if turned:
        g = f'<g transform="rotate(-90 100 110)">{g}</g>'
    out.append(g)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 1 — one: one line on the diagram = three wires in the field.
# --------------------------------------------------------------------------

def one_card(kind):
    out = card_open('yard')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # The diagram strip at the top: one line.
    out.append('<rect x="20" y="12" width="160" height="44" rx="3" fill="url(#paper)"/>')
    out.append(_ln(34, 34, 166, 34, 3.2))
    # A white chevron from the diagram down to the field.
    out.append('<path d="M92 62 L100 72 L108 62" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round"/>')
    if kind in ('three', 'oneW', 'twoW'):
        # A pole with a crossarm and its wires running off to the right.
        out.append(f'<rect x="54" y="84" width="10" height="{GY - 84}" fill="url(#pole)"/>')
        out.append('<rect x="22" y="96" width="74" height="6" fill="#6F7880"/>')
        xs = {'three': (30, 59, 88), 'oneW': (59,), 'twoW': (30, 88)}[kind]
        for x in xs:
            out.append(f'<path d="M{x - 4} 96 L{x + 4} 96 L{x + 3} 84 L{x - 3} 84 Z" fill="url(#porcelain)"/>')
            out.append(f'<path d="M{x} 82 Q{(x + 200) / 2} {98 + (x - 30) * 0.15} 204 {86 + (x - 30) * 0.1}" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
            out.append(f'<path d="M{x} 82 Q{x / 2} 92 -4 84" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
    else:
        # A cable end cut open: three cores (three) or one core.
        cx, cy = 100, 140
        out.append(f'<path d="M-4 {cy + 30} Q60 {cy + 34} {cx - 20} {cy + 10}" stroke="#2A2E33" stroke-width="22" fill="none"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="38" fill="url(#sheath)"/>')
        out.append(f'<circle cx="{cx}" cy="{cy}" r="32" fill="#4A5058"/>')
        cores = [(cx + 15 * math.cos(a), cy + 15 * math.sin(a)) for a in (-math.pi / 2, math.pi / 6, 5 * math.pi / 6)] if kind == 'cable3' else [(cx, cy)]
        r = 11 if kind == 'cable3' else 20
        for x, y in cores:
            out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r + 2.5}" fill="{WIRE}"/>')
            out.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{r}" fill="{COPPER}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — ring: the work section and its isolation points on the diagram.
# --------------------------------------------------------------------------

RING_L, RING_R, RING_T, RING_B = 40, 160, 46, 176


def source(x, y):
    """A source: a circle with a wave in it."""
    return (f'<circle cx="{x}" cy="{y}" r="11" fill="url(#paper)" stroke="{INK}" stroke-width="2.6"/>'
            f'<path d="M{x - 6} {y} q3 -6 6 0 q3 6 6 0" stroke="{INK}" stroke-width="2" fill="none"/>')


def mini_switch(x, y, across):
    """A small isolator on the ring at (x, y); across = on a horizontal run."""
    g = (f'<rect x="{x - 9}" y="{y - 9}" width="18" height="18" fill="url(#paper)"/>'
         + _ln(x - 9, y, x - 5, y, 2.6) + _ln(x + 5, y, x + 9, y, 2.6)
         + _ln(x - 5, y, x + 5, y - 7, 2.6) + f'<circle cx="{x - 5}" cy="{y}" r="1.8" fill="{INK}"/>')
    return g if across else f'<g transform="rotate(90 {x} {y})">{g}</g>'


RING_SW = {'b1': (75, RING_B, True), 'b2': (125, RING_B, True),
           'l1': (RING_L, 90, False), 'l2': (RING_L, 140, False),
           'r1': (RING_R, 90, False), 'r2': (RING_R, 140, False)}


def ring_card(section, marks, feed=None):
    """section: 'bottom' (between b1 and b2) or 'left' (between l1 and l2);
    marks: the switches circled in pencil; feed: a side power comes in from
    to the unmarked end of the work section ('left' / 'right')."""
    out = sheet()
    out.append(source(RING_L, 30) + source(RING_R, 30))
    out.append(f'<path d="M{RING_L} 41 L{RING_L} {RING_B} L{RING_R} {RING_B} L{RING_R} 41" stroke="{INK}" stroke-width="3" fill="none" stroke-linejoin="round"/>')
    # Branches off the ring to loads (small transformers).
    for x, y in ((100, RING_B), (RING_L, 115), (RING_R, 115)):
        dx = 0 if y == RING_B else (18 if x == RING_L else -18)
        if dx:
            out.append(_ln(x, y, x + dx, y, 2.4))
            out.append(f'<g transform="rotate(90 {x + dx + 10} {y})">{sym("coils", x + dx + 10, y, 0.42, top=y - 10, bottom=y + 12, w=2)}</g>')
        else:
            out.append(_ln(x, y, x, y + 8, 2.4))
            out.append(sym('coils', x, y + 16, 0.42, top=y + 8, bottom=y + 26, w=2))
    # The work section: a yellow band with the helmet sign.
    if section == 'bottom':
        out.append(f'<path d="M84 {RING_B} L116 {RING_B}" stroke="{MARK}" stroke-width="9" stroke-opacity="0.75"/>')
        hx, hy = 100, RING_B - 18
    else:
        out.append(f'<path d="M{RING_L} 99 L{RING_L} 131" stroke="{MARK}" stroke-width="9" stroke-opacity="0.75"/>')
        hx, hy = RING_L + 20, 106
    out.append(f'<path d="M{hx - 8} {hy + 3} A8 8 0 0 1 {hx + 8} {hy + 3} Z" fill="{HELMET}"/>'
               f'<rect x="{hx - 10}" y="{hy + 2}" width="20" height="3" rx="1.3" fill="{HELMET_D}"/>')
    for k, (x, y, across) in RING_SW.items():
        out.append(mini_switch(x, y, across))
    for k in marks:
        x, y, _ = RING_SW[k]
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="15" ry="14" fill="none" stroke="{PENCIL}" stroke-width="2.6" transform="rotate(-12 {x} {y})"/>')
    if feed:
        # Power coming round the ring into the unmarked end of the section.
        def chev(x, y, ang):
            return (f'<g transform="rotate({ang} {x} {y})"><path d="M{x - 4} {y - 5} L{x + 3} {y} L{x - 4} {y + 5}" '
                    f'stroke="{FEED}" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/></g>')
        if section == 'bottom' and feed == 'right':
            out.append(chev(RING_R + 10, 70, 90) + chev(RING_R + 10, 150, 90) + chev(140, RING_B + 10, 180))
            out.append(spark(116, RING_B, 0.8))
        elif section == 'bottom':
            out.append(chev(RING_L - 10, 70, 90) + chev(RING_L - 10, 150, 90) + chev(60, RING_B + 10, 0))
            out.append(spark(84, RING_B, 0.8))
        elif feed == 'right':
            out.append(chev(RING_R + 10, 70, 90) + chev(100, RING_B + 10, 180) + chev(RING_L - 10, 158, -90))
            out.append(spark(RING_L, 131, 0.8))
        else:
            out.append(chev(RING_L - 10, 70, 90))
            out.append(spark(RING_L, 99, 0.8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — field: an old diagram in the field, a new branch not on it.
# --------------------------------------------------------------------------

def field_stage():
    out = card_open('yard')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # Two poles of the old line and a new branch going off to a third pole.
    for x, top in ((28, 40), (150, 46)):
        out.append(f'<rect x="{x - 4}" y="{top}" width="8" height="{GY - top}" fill="url(#pole)"/>')
        out.append(f'<rect x="{x - 20}" y="{top + 8}" width="40" height="4" fill="#6F7880"/>')
    for dx in (-15, 0, 15):
        out.append(f'<path d="M{28 + dx} {44} Q89 {60} {150 + dx} {50}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
        out.append(f'<path d="M{150 + dx} {50} Q180 {58} 206 {54}" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    # The new branch (bright new wire) to a short pole at the back right.
    out.append(f'<rect x="183" y="86" width="6" height="{GY - 86 - 30}" fill="url(#pole)" opacity="0.85"/>')
    out.append(f'<rect x="174" y="92" width="24" height="3" fill="#6F7880"/>')
    for dx in (-8, 0, 8):
        out.append(f'<path d="M{150 + dx} {58} Q170 {82} {186 + dx} {90}" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
    out.append(f'<ellipse cx="186" cy="{GY - 30}" rx="10" ry="3" fill="#9C8A64"/>')
    return out


def van(x=6, y=150):
    return (f'<rect x="{x}" y="{y}" width="62" height="{GY - 8 - y}" rx="6" fill="url(#van)"/>'
            f'<rect x="{x + 40}" y="{y + 6}" width="18" height="14" rx="3" fill="#7FB2DA"/>'
            f'<circle cx="{x + 14}" cy="{GY - 6}" r="7" fill="{FACE}"/><circle cx="{x + 48}" cy="{GY - 6}" r="7" fill="{FACE}"/>')


def plan(x, y, w=34, h=26, rot=0, marked=False):
    """The diagram held open: a paper sheet with a line and two symbols."""
    g = (f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{w}" height="{h}" rx="1.5" fill="url(#paper)" stroke="#BFB394" stroke-width="0.6"/>'
         + _ln(x - w / 2 + 4, y - 3, x + w / 2 - 4, y - 3, 1.4)
         + _ln(x + 2, y - 3, x + 2, y + h / 2 - 4, 1.4)
         + f'<rect x="{f(x - 9)}" y="{f(y - 6)}" width="6" height="6" fill="none" stroke="{INK}" stroke-width="1.1"/>')
    if marked:
        g += f'<ellipse cx="{f(x + 2)}" cy="{f(y + 4)}" rx="5" ry="4" fill="none" stroke="{PENCIL}" stroke-width="1.4"/>'
    return f'<g transform="rotate({rot} {f(x)} {f(y)})">{g}</g>' if rot else g


def rolled(x, y):
    """The diagram rolled up, left lying on the ground with its pencil."""
    return (f'<rect x="{x}" y="{y}" width="30" height="7" rx="3.5" fill="url(#paper)" stroke="#BFB394" stroke-width="0.6"/>'
            f'<ellipse cx="{x + 30}" cy="{y + 3.5}" rx="2.4" ry="3.5" fill="#D9CFB8"/>'
            f'<path d="M{x + 36} {y + 8} l12 -2" stroke="{PENCIL}" stroke-width="2.2" stroke-linecap="round"/>')


def field_card(kind):
    out = field_stage()
    out.append(van())
    if kind == 'compare':
        # Diagram held up, eyes on the new branch.
        out.append(worker(108, ((122, 134), (128, 128)), face=1, look=-22))
        out.append(plan(128, 124, rot=8))
    elif kind == 'mark':
        # Diagram spread on the van's bonnet, pencil marking it.
        out.append(plan(52, 146, w=40, h=14, marked=True))
        out.append(worker(92, ((66, 150), (56, 146)), face=-1, look=8))
        out.append(f'<path d="M56 146 l-6 -9" stroke="{PENCIL}" stroke-width="2.2" stroke-linecap="round"/>')
    elif kind == 'memory':
        # No diagram: going by memory, the plan lying rolled on the ground.
        out.append(worker(112, ((104, 150), (118, 128)), face=1, look=-14))
        out.append('<g fill="#FFFFFF" opacity="0.92"><circle cx="134" cy="112" r="2.5"/><circle cx="140" cy="102" r="3.5"/>'
                   '<ellipse cx="146" cy="86" rx="14" ry="9"/></g>')
        out.append(_ln(136, 86, 156, 86, 1.6))
        out.append(rolled(70, GY - 8))
    elif kind == 'ladder':
        # Ladder up to the new branch pole without looking at the diagram.
        out.append(f'<g transform="rotate(16 150 {GY})"><rect x="144" y="{GY - 104}" width="3" height="104" fill="url(#ladder)"/>'
                   f'<rect x="158" y="{GY - 104}" width="3" height="104" fill="url(#ladder)"/>'
                   + ''.join(f'<rect x="144" y="{GY - 100 + i * 14}" width="17" height="2.4" fill="url(#ladder)"/>' for i in range(8)) + '</g>')
        out.append(worker(136, ((150, 150), (156, 136)), face=1, look=-16))
        out.append(rolled(80, GY - 8))
    elif kind == 'trust':
        # Eyes on the old diagram only, back to the new branch.
        out.append(worker(124, ((106, 132), (112, 128)), face=-1, look=18))
        out.append(plan(107, 128, rot=10))
    return card_close(out)


CARDS = {
    'one_three': one_card('three'),
    'one_cable3': one_card('cable3'),
    'one_single': one_card('oneW'),
    'one_two': one_card('twoW'),
    'one_core': one_card('core1'),
    'tx_coils': symbol_card('coils'),
    'tx_coils_turned': symbol_card('coils', turned=True),
    'tx_box': symbol_card('box', turned=True),
    'tx_break': symbol_card('break'),
    'tx_earth': symbol_card('earth'),
    'tx_arrester': symbol_card('arrester'),
    'iso_break': symbol_card('break'),
    'iso_break_turned': symbol_card('break', turned=True),
    'iso_box': symbol_card('box'),
    'iso_fuse': symbol_card('fuse'),
    'iso_coils': symbol_card('coils', turned=True),
    'iso_line': symbol_card('line', turned=True),
    'ring_bottom': ring_card('bottom', ['b1', 'b2']),
    'ring_left': ring_card('left', ['l1', 'l2']),
    'ring_one_left': ring_card('bottom', ['b1'], feed='right'),
    'ring_one_side': ring_card('left', ['l2'], feed='left'),
    'ring_none': ring_card('bottom', [], feed='right'),
    'ring_far': ring_card('left', ['r1', 'r2'], feed='right'),
    'field_compare': field_card('compare'),
    'field_mark': field_card('mark'),
    'field_memory': field_card('memory'),
    'field_ladder': field_card('ladder'),
    'field_trust': field_card('trust'),
}

# Safe cards and traps per round (mirrors learn_board_pack310.dart).
ROUNDS = {
    'one': (['one_three', 'one_cable3'], ['one_single', 'one_two', 'one_core']),
    'tx': (['tx_coils', 'tx_coils_turned'], ['tx_box', 'tx_break', 'tx_earth', 'tx_arrester']),
    'iso': (['iso_break', 'iso_break_turned'], ['iso_box', 'iso_fuse', 'iso_coils', 'iso_line']),
    'ring': (['ring_bottom', 'ring_left'], ['ring_one_left', 'ring_one_side', 'ring_none', 'ring_far']),
    'field': (['field_compare', 'field_mark'], ['field_memory', 'field_ladder', 'field_trust']),
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
