"""Picture cards for lesson 4.2 শেখা ("জাম্পার কানেকশন ও টাইট করা").

python -I tool/m4_board42_art.py .

Writes assets/game/art/m4_board42/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 4.2 and its film script only:
  1. bridge: at a dead-end / angle pole the jumper joins the line on the two
     sides of the tension strings; it is the same size as the line conductor
     or bigger — a thin one overloads and melts; without it the current stops
     at the string; a loose one is a high-resistance point;
  2. connector: a PG clamp or a compression connector (pressed with the
     hydraulic tool and the right die); copper to aluminium only through a
     bi-metallic connector (galvanic corrosion);
  3. fit: clean both surfaces with a steel brush, anti-oxidant paste on
     aluminium; two wrenches — one holds the bolt head, one turns the nut;
     nuts tightened evenly;
  4. shape: a smooth U / C so that, swinging in a strong wind, it touches
     neither the cross-arm nor the next phase; a jumper support insulator if
     needed; no sharp edges (corona);
  5. patrol (night): a loose jumper shows as a red hotspot, sparking, a blue
     corona glow, and in the end the clamp melts and the wire falls.

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
    print('usage: python -I tool/m4_board42_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board42')
W, H = 200, 220
GY = 198

ALU = '#A7B0B8'
ALU_D = '#6E7881'
COPPER = '#C97A3A'
COPPER_D = '#8E5323'
GLOVE = '#2A2D33'
SHIRT = '#1F5F8F'
GRIP = '#C8452F'
FACE = '#1E2329'
OXI = '#5B4A36'
CORR = '#4FAF8A'
HOT = '#FF5A2E'
MOON = '#F4EFD8'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2D9"/><stop offset="1" stop-color="#CFE3EF"/></linearGradient>
  <linearGradient id="near" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9CC3E2"/><stop offset="1" stop-color="#DCEAF3"/></linearGradient>
  <linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0E1A2E"/><stop offset="1" stop-color="#253A57"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="hyd" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E3892E"/><stop offset="1" stop-color="#B9661A"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="hot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A"/><stop offset="0.35" stop-color="#FF5A2E"/><stop offset="1" stop-color="#FF2E1E" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF1A8"/><stop offset="1" stop-color="#FFB02E" stop-opacity="0"/></radialGradient>
  <radialGradient id="corona" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#E4F1FF"/><stop offset="0.4" stop-color="#7FB8FF" stop-opacity="0.8"/><stop offset="1" stop-color="#4F8CFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="fire" cx="0.5" cy="0.7" r="0.6"><stop offset="0" stop-color="#FFF1A8"/><stop offset="0.4" stop-color="#FF8A2E"/><stop offset="1" stop-color="#E5401E" stop-opacity="0"/></radialGradient>
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
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(14 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#FFF1A8" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def hot(x, y, r=16):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#hot)"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.28)}" fill="{HOT}"/>')


def corona(x, y, r=12):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#corona)"/>'


def wind(ys=(30, 112, 182)):
    return ''.join(f'<path d="M{f(8 + i * 6)} {y} q14 -6 28 0 t28 0" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.75"/>'
                   for i, y in enumerate(ys))


# --------------------------------------------------------------------------
# The dead-end pole: two phases, each with a tension string on either side of
# the pole and a jumper bridging them below the cross-arm.
# --------------------------------------------------------------------------

PX, PW = 100, 12
YA, YB = 62, 136        # the two phases (cross-arm heights)
LX, RX = 46, 154        # dead-end clamps (outer ends of the strings)


def string(x0, x1, y):
    """Insulator discs from the arm (x0) out to the dead-end clamp (x1)."""
    n = 6
    o = [f'<path d="M{x0} {y} L{x1} {y}" stroke="{ALU_D}" stroke-width="1.4"/>']
    for i in range(n):
        x = x0 + (x1 - x0) * (i + 0.5) / n
        o.append(f'<ellipse cx="{f(x)}" cy="{y}" rx="2.3" ry="6.4" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>')
    d = 1 if x1 > x0 else -1
    o.append(f'<rect x="{f(x1 - 3 if d > 0 else x1 - 4)}" y="{y - 3}" width="7" height="6" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def line(y, night=False):
    return (f'<path d="M0 {y} L{LX} {y} M{RX} {y} L200 {y}" stroke="{ALU}" stroke-width="3.2"/>'
            f'<path d="M0 {y - 0.8} L{LX} {y - 0.8} M{RX} {y - 0.8} L200 {y - 0.8}" stroke="#FFFFFF" stroke-width="0.6" opacity="{0.25 if night else 0.5}"/>'
            + string(PX - PW / 2 - 10, LX, y) + string(PX + PW / 2 + 10, RX, y))


def arm(y):
    return (f'<rect x="{PX - PW / 2 - 12}" y="{y - 4}" width="{PW + 24}" height="8" rx="1.5" fill="url(#steelArm)"/>'
            f'<path d="M{PX - PW / 2} {y + 4} L{PX - PW / 2 - 10} {y + 16} M{PX + PW / 2} {y + 4} L{PX + PW / 2 + 10} {y + 16}" stroke="{ALU_D}" stroke-width="2"/>')


def jumper_path(y, kind='u', sag=34):
    a, b = (LX + 2, y + 2), (RX - 2, y + 2)
    if kind == 'u':
        c = sag * 4 / 3
        return f'M{a[0]} {a[1]} C{a[0]} {f(a[1] + c)} {b[0]} {f(b[1] + c)} {b[0]} {b[1]}'
    if kind == 'c':
        return f'M{a[0]} {a[1]} C{a[0] - 18} {a[1] + 40} {b[0] + 18} {b[1] + 40} {b[0]} {b[1]}'
    if kind == 'taut':
        return f'M{a[0]} {a[1]} Q100 {a[1] + 10} {b[0]} {b[1]}'
    if kind == 'swing':
        return f'M{a[0]} {a[1]} C{a[0] - 30} {a[1] + 90} {b[0] - 60} {b[1] + 70} {b[0]} {b[1]}'
    if kind == 'kink':
        return f'M{a[0]} {a[1]} L{a[0] + 14} {a[1] + 34} L100 {a[1] + 26} L{b[0] - 14} {b[1] + 34} L{b[0]} {b[1]}'
    if kind == 'loose':
        return f'M{a[0]} {a[1]} C{a[0]} {a[1] + 44} {b[0] - 10} {b[1] + 40} {b[0] - 6} {b[1] + 12}'
    if kind == 'fallen':
        return f'M{a[0]} {a[1]} C{a[0]} {a[1] + 40} {b[0] - 30} {b[1] + 20} {b[0] - 18} {GY - 2}'
    raise ValueError(kind)


def jumper(y, kind='u', w=3.2, col=ALU, sag=34):
    d = jumper_path(y, kind, sag)
    join = 'miter' if kind == 'kink' else 'round'
    return (f'<path d="{d}" stroke="{col}" stroke-width="{w}" fill="none" stroke-linejoin="{join}" stroke-linecap="round"/>'
            f'<rect x="{LX - 2}" y="{y - 2}" width="8" height="8" rx="1.5" fill="url(#steel)"/>'
            + ('' if kind in ('loose', 'fallen') else f'<rect x="{RX - 6}" y="{y - 2}" width="8" height="8" rx="1.5" fill="url(#steel)"/>'))


def support(y, bottom):
    """A jumper support insulator on a bracket below the arm."""
    top = bottom - 12
    return (f'<path d="M{PX + PW / 2} {top + 14} L{PX + 20} {top + 14}" stroke="{ALU_D}" stroke-width="2.4"/>'
            f'<rect x="{PX + 16}" y="{top}" width="8" height="14" rx="2" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.5"/>'
            + ''.join(f'<path d="M{PX + 14} {top + 3 + i * 4} L{PX + 26} {top + 3 + i * 4}" stroke="#9AA5AD" stroke-width="1.2"/>' for i in range(3)))


def pole_stage(back='sky', night=False):
    out = card_open(back)
    if night:
        out.append(f'<circle cx="160" cy="26" r="11" fill="{MOON}"/><circle cx="165" cy="23" r="10" fill="url(#night)"/>')
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="0.9" fill="{MOON}" opacity="0.8"/>' for x, y in ((24, 18), (60, 34), (130, 14), (186, 52), (40, 96))))
    out.append(f'<rect x="0" y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(f'<rect x="{PX - PW / 2}" y="20" width="{PW}" height="{GY - 20}" fill="url(#pole)"/>')
    out.append(f'<path d="M{PX - 4} 20 L{PX + 4} 20 L{PX} 12 Z" fill="url(#pole)"/>')
    out.append(arm(YA) + arm(YB))
    out.append(line(YA, night) + line(YB, night))
    if night:
        out.append(f'<rect width="{W}" height="{H}" fill="{FACE}" opacity="0.35"/>')
    return out


def lower_jumper():
    return jumper(YB, 'u', sag=30)


# --------------------------------------------------------------------------
# Round 1 — bridge: the jumper across the dead-end, the right size.
# --------------------------------------------------------------------------

def bridge_card(kind):
    out = pole_stage()
    out.append(lower_jumper())
    if kind == 'same':
        out.append(jumper(YA))
    elif kind == 'thick':
        out.append(jumper(YA, w=4.8))
    elif kind == 'thin':
        out.append(f'<path d="{jumper_path(YA)}" stroke="{HOT}" stroke-width="5" fill="none" opacity="0.35"/>')
        out.append(jumper(YA, w=1.1, col=HOT))
        out.append(hot(100, YA + 36, 14))
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.4" fill="none" stroke-linecap="round" opacity="0.8">'
                   f'<path d="M78 {YA + 46} q-3 6 0 12"/><path d="M100 {YA + 52} q-3 6 0 12"/><path d="M122 {YA + 46} q-3 6 0 12"/></g>')
    elif kind == 'none':
        out.append(f'<rect x="{LX - 2}" y="{YA - 2}" width="8" height="8" rx="1.5" fill="url(#steel)"/>'
                   f'<rect x="{RX - 6}" y="{YA - 2}" width="8" height="8" rx="1.5" fill="url(#steel)"/>')
        out.append(f'<path d="M{LX + 2} {YA + 8} l0 8 M{RX - 2} {YA + 8} l0 8" stroke="{ALU}" stroke-width="3.2" stroke-linecap="round"/>')
    elif kind == 'loose':
        out.append(jumper(YA, 'loose'))
        out.append(spark(RX - 6, YA + 10, 0.8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — shape: a smooth U / C clear of the arm and the next phase.
# --------------------------------------------------------------------------

def shape_card(kind):
    out = pole_stage()
    out.append(wind())
    out.append(lower_jumper())
    if kind == 'u':
        out.append(jumper(YA))
    elif kind == 'support':
        out.append(support(YA, YA + 36))
        out.append(jumper(YA, 'c'))
    elif kind == 'arm':
        out.append(jumper(YA, 'taut'))
        out.append(spark(PX - PW / 2 - 10, YA + 6, 0.8))
    elif kind == 'phase':
        out.append(jumper(YA, 'swing'))
        out.append(spark(56, YB - 1, 0.9))
    elif kind == 'kink':
        out.append(jumper(YA, 'kink'))
        for x, y in ((LX + 16, YA + 36), (100, YA + 28), (RX - 16, YA + 36)):
            out.append(corona(x, y, 9))
        out.append(f'<g stroke="{ALU}" stroke-width="1" stroke-linecap="round"><path d="M{LX + 4} {YA + 6} l5 4 M{LX + 4} {YA + 6} l6 0 M{RX - 4} {YA + 6} l-5 4 M{RX - 4} {YA + 6} l-6 0"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — patrol at night: a sound jumper and the signs of a loose one.
# --------------------------------------------------------------------------

def patrol_card(kind):
    out = pole_stage('night', night=True)
    out.append(lower_jumper())
    if kind == 'calm':
        out.append(jumper(YA))
    elif kind == 'calm_support':
        out.append(support(YA, YA + 36))
        out.append(jumper(YA, 'c'))
    elif kind == 'hot':
        out.append(jumper(YA))
        out.append(hot(LX + 2, YA + 3, 20))
    elif kind == 'spark':
        out.append(jumper(YA))
        out.append(spark(RX - 2, YA + 3, 1.0))
        out.append(spark(RX + 6, YA + 14, 0.55))
    elif kind == 'corona':
        out.append(jumper(YA))
        out.append(corona(LX + 2, YA + 3, 16) + corona(RX - 2, YA + 3, 13))
    elif kind == 'fallen':
        out.append(jumper(YA, 'fallen'))
        out.append(hot(RX - 2, YA + 2, 10))
        out.append(f'<ellipse cx="{RX - 18}" cy="{GY - 4}" rx="16" ry="14" fill="url(#fire)"/>')
        out.append(spark(RX - 18, GY - 4, 0.7))
    return card_close(out)


# --------------------------------------------------------------------------
# Close-up: the main conductor (top) and the jumper (below) at the clamp.
# --------------------------------------------------------------------------

MY, JY = 70, 98          # main conductor, jumper (centre lines)
CX0, CX1 = 82, 126       # the clamp block


def conductor(y, x0, x1, col=ALU, dark=ALU_D, w=9):
    o = [f'<path d="M{x0} {y} L{x1} {y}" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>']
    o += [f'<path d="M{x} {f(y - w / 2 + 1)} l4 {f(w - 2)}" stroke="{dark}" stroke-width="0.9"/>' for x in range(int(x0) + 4, int(x1) - 4, 7)]
    return ''.join(o)


def near_stage(jcol=ALU, jdark=ALU_D, main_oxi=False):
    out = card_open('near')
    out.append(f'<rect x="150" y="0" width="22" height="220" fill="url(#pole)" opacity="0.35"/>')
    out.append(conductor(MY, -6, 206))
    if main_oxi:
        out.append(''.join(f'<ellipse cx="{x}" cy="{MY + (i % 2) * 2 - 1}" rx="7" ry="3.2" fill="{OXI}" opacity="0.85"/>' for i, x in enumerate(range(14, 200, 22))))
    # The jumper comes in from the right under the line and bends away down-left.
    out.append(conductor(JY, 40, 206, jcol, jdark))
    out.append(f'<path d="M40 {JY} Q14 {JY} 12 {JY + 40} L10 226" stroke="{jcol}" stroke-width="9" fill="none"/>')
    return out


def pg_clamp(gap=0.0, tilt=0, bimetal=False):
    """The PG clamp: two grooved plates over both conductors, two bolts."""
    cx, cy = (CX0 + CX1) / 2, (MY + JY) / 2
    o = [f'<g transform="rotate({tilt} {cx} {cy})">']
    if bimetal:
        o.append(f'<rect x="{CX0}" y="{MY - 10}" width="{CX1 - CX0}" height="{(JY - MY) / 2 + 10}" rx="4" fill="url(#steel)"/>')
        o.append(f'<rect x="{CX0}" y="{cy}" width="{CX1 - CX0}" height="{(JY - MY) / 2 + 10}" rx="4" fill="{COPPER}"/>')
        o.append(f'<path d="M{CX0} {cy} L{CX1} {cy}" stroke="{COPPER_D}" stroke-width="1.2"/>')
    else:
        o.append(f'<rect x="{CX0}" y="{MY - 10}" width="{CX1 - CX0}" height="{JY - MY + 20}" rx="4" fill="url(#steel)"/>')
    o.append(f'<path d="M{CX0 + 3} {cy} L{CX1 - 3} {cy}" stroke="{ALU_D}" stroke-width="1"/>')
    for i, bx in enumerate((CX0 + 11, CX1 - 11)):
        g = gap if i == 1 else 0
        o.append(f'<circle cx="{bx}" cy="{cy}" r="{6.2 + g * 0.2}" fill="{FACE}"/>')
        o.append(f'<polygon points="{" ".join(f"{f(bx + 5 * math.cos(a))},{f(cy + 5 * math.sin(a))}" for a in [k * math.pi / 3 for k in range(6)])}" fill="url(#steel)" stroke="{ALU_D}" stroke-width="0.8"/>')
        if g:
            o.append(f'<path d="M{bx - 2} {cy} l4 0" stroke="{ALU_D}" stroke-width="1.6"/>')
    o.append('</g>')
    return ''.join(o)


def arm_from(x0, y0, x, y, w=13):
    return (f'<path d="M{x0} {y0} L{f(x)} {f(y)}" stroke="url(#shirt)" stroke-width="{w}" stroke-linecap="round"/>'
            f'<path d="M{x0} {y0} L{f(x)} {f(y)}" stroke="{SHIRT}" stroke-width="{w}" stroke-linecap="round" opacity="0.35"/>')


def glove(x, y, r=8):
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{r}" ry="{f(r * 0.85)}" fill="{GLOVE}"/>'
            f'<path d="M{f(x - r + 2)} {f(y - 2)} q{f(r - 2)} -6 {f(2 * r - 4)} 0" stroke="#3A3E45" stroke-width="1.4" fill="none"/>')


def hand_at(x, y, x0=None, y0=226):
    x0 = x if x0 is None else x0
    return arm_from(x0, y0, x, y) + glove(x, y)


def wrench(bx, by, ang, behind=False):
    """An open spanner whose jaw sits on (bx, by), handle at angle ang (deg)."""
    op = 0.75 if behind else 1
    return (f'<g transform="rotate({ang} {bx} {by})" opacity="{op}">'
            f'<rect x="{bx}" y="{by - 3.2}" width="62" height="6.4" rx="2.6" fill="url(#steel)" stroke="{ALU_D}" stroke-width="0.6"/>'
            f'<rect x="{bx + 36}" y="{by - 4}" width="26" height="8" rx="3" fill="{GRIP}"/>'
            f'<path d="M{bx + 4} {by - 8} A8.5 8.5 0 1 0 {bx + 4} {by + 8} L{bx - 1} {by + 3.5} L{bx - 1} {by - 3.5} Z" fill="url(#steel)" stroke="{ALU_D}" stroke-width="0.6"/>'
            '</g>')


def spin(x, y, r=11):
    """Arrows round a bolt head turning with the nut."""
    return (f'<g stroke="#FFFFFF" stroke-width="1.8" fill="none" stroke-linecap="round">'
            f'<path d="M{x - r} {y} A{r} {r} 0 0 1 {x} {y - r}"/><path d="M{x + r} {y} A{r} {r} 0 0 1 {x} {y + r}"/></g>'
            f'<path d="M{x} {y - r - 3} l4 3 l-4 3 Z M{x} {y + r + 3} l-4 -3 l4 -3 Z" fill="#FFFFFF"/>')


# --------------------------------------------------------------------------
# Round 2 — connector: PG clamp, compression (hydraulic tool), bi-metallic.
# --------------------------------------------------------------------------

def sleeve(crooked=False):
    cy = (MY + JY) / 2
    rot = 'rotate(-9 104 84)' if crooked else ''
    o = [f'<g transform="{rot}"><rect x="{CX0}" y="{MY - 9}" width="{CX1 - CX0}" height="{JY - MY + 18}" rx="7" fill="url(#steel)"/>']
    for x in (CX0 + 10, CX0 + 22, CX0 + 34):
        o.append(f'<path d="M{x} {MY - 8} L{x} {JY + 8}" stroke="{ALU_D}" stroke-width="{1.4 if not crooked or x < CX0 + 20 else 0.4}"/>')
    o.append(f'<path d="M{CX0 + 3} {cy} L{CX1 - 3} {cy}" stroke="{ALU_D}" stroke-width="1"/></g>')
    return ''.join(o)


def crimper():
    """The hydraulic crimping head (C-frame with the die) and its handles."""
    return (f'<path d="M78 46 L130 46 Q138 46 138 54 L138 112 Q138 120 130 120 L118 120 L118 110 L128 110 L128 56 L88 56 L88 64 L78 64 Z" fill="url(#hyd)"/>'
            f'<rect x="90" y="108" width="28" height="10" rx="2" fill="url(#steel)"/>'
            f'<rect x="98" y="118" width="12" height="40" rx="3" fill="url(#hyd)"/>'
            f'<path d="M104 158 L84 210 M104 158 L132 208" stroke="{FACE}" stroke-width="7" stroke-linecap="round"/>')


def pliers(x, y):
    return (f'<g transform="rotate(-24 {x} {y})">'
            f'<path d="M{x - 6} {y - 14} L{x - 2} {y} L{x + 2} {y} L{x + 6} {y - 14}" stroke="url(#steel)" stroke-width="5" fill="none"/>'
            f'<circle cx="{x}" cy="{y + 2}" r="3" fill="{ALU_D}"/>'
            f'<path d="M{x - 2} {y + 4} L{x - 10} {y + 60} M{x + 2} {y + 4} L{x + 10} {y + 60}" stroke="url(#hyd)" stroke-width="7" stroke-linecap="round"/></g>')


def connector_card(kind):
    if kind in ('bimetal', 'plain_cu'):
        out = near_stage(COPPER, COPPER_D)
    else:
        out = near_stage()
    if kind == 'pg':
        out.append(pg_clamp())
        out.append(wrench(CX0 + 11, (MY + JY) / 2, 120))
        out.append(hand_at(66, 128, 40))
    elif kind == 'crimp':
        out.append(sleeve())
        out.append(crimper())
        out.append(hand_at(84, 204, 70) + hand_at(132, 202, 150))
    elif kind == 'bimetal':
        out.append(pg_clamp(bimetal=True))
        out.append(wrench(CX0 + 11, (MY + JY) / 2, 120))
        out.append(hand_at(66, 128, 40))
    elif kind == 'plain_cu':
        out.append(pg_clamp())
        out.append(''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="3.6" fill="{CORR}" opacity="0.9"/>'
                           for x, y, rx in ((CX0 - 4, JY + 1, 8), (CX1 + 6, JY - 1, 9), (CX1 + 2, MY + 13, 5), (CX0 + 4, MY - 9, 6), (CX1 + 20, JY + 2, 5))))
        out.append(wrench(CX0 + 11, (MY + JY) / 2, 120))
        out.append(hand_at(66, 128, 40))
    elif kind == 'twist':
        # The jumper end wound round the line by hand — no connector at all.
        out.append(''.join(f'<path d="M{x} {MY + 6} q4 -14 8 -12 q2 2 0 12" stroke="{ALU}" stroke-width="4" fill="none" stroke-linecap="round"/>' for x in range(84, 124, 9)))
        out.append(f'<path d="M84 {MY + 6} Q86 {JY} 100 {JY}" stroke="{ALU}" stroke-width="5" fill="none"/>')
        out.append(spark(122, MY + 2, 0.7))
        out.append(hand_at(140, 120, 160))
    elif kind == 'pliers':
        out.append(sleeve(crooked=True))
        out.append(pliers(104, 116))
        out.append(hand_at(96, 182, 70) + hand_at(124, 176, 150))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — fit: brush clean, paste on aluminium, two wrenches, even nuts.
# --------------------------------------------------------------------------

def steel_brush(x, y, ang):
    return (f'<g transform="rotate({ang} {x} {y})">'
            f'<rect x="{x - 18}" y="{y - 5}" width="30" height="10" rx="2" fill="url(#steel)"/>'
            + ''.join(f'<path d="M{x - 16 + i * 3} {y + 5} l0 5" stroke="{ALU_D}" stroke-width="1"/>' for i in range(10))
            + f'<rect x="{x + 12}" y="{y - 3.5}" width="40" height="7" rx="3" fill="{GRIP}"/></g>')


def paste_tube(x, y, ang):
    return (f'<g transform="rotate({ang} {x} {y})">'
            f'<path d="M{x} {y - 3} L{x + 8} {y - 9} L{x + 44} {y - 9} L{x + 46} {y + 9} L{x + 8} {y + 9} L{x} {y + 3} Z" fill="url(#steel)" stroke="{ALU_D}" stroke-width="0.6"/>'
            f'<rect x="{x - 5}" y="{y - 3}" width="6" height="6" rx="1" fill="{GRIP}"/></g>')


def fit_card(kind):
    out = near_stage(main_oxi=kind in ('brush', 'dirty'))
    cy = (MY + JY) / 2
    if kind == 'brush':
        # A bright, freshly brushed stretch where the brush has been.
        out.append(f'<path d="M100 {MY} L150 {MY}" stroke="#FFFFFF" stroke-width="5" opacity="0.6"/>')
        out.append(f'<path d="M100 {MY} L150 {MY}" stroke="{ALU}" stroke-width="9" opacity="0.5"/>')
        out.append(steel_brush(124, MY - 14, -8))
        out.append(hand_at(170, 52, 196, 140))
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"><path d="M104 {MY - 26} l-10 0 M104 {MY - 32} l-6 0"/></g>')
    elif kind == 'paste':
        out.append(f'<path d="M70 {JY - 3} L130 {JY - 3}" stroke="{ALU_D}" stroke-width="3.6" stroke-linecap="round"/>')
        out.append(f'<path d="M70 {MY + 3} L120 {MY + 3}" stroke="{ALU_D}" stroke-width="3.2" stroke-linecap="round"/>')
        out.append(paste_tube(134, JY - 10, -30))
        out.append(hand_at(168, 82, 196, 150))
    elif kind == 'wrenches':
        out.append(pg_clamp())
        out.append(wrench(CX0 + 11, cy, 120, behind=True))
        out.append(wrench(CX0 + 11, cy, 70))
        out.append(hand_at(64, 130, 30) + hand_at(106, 142, 120))
    elif kind == 'dirty':
        out.append(pg_clamp())
        out.append(wrench(CX0 + 11, cy, 70))
        out.append(hand_at(106, 142, 120))
    elif kind == 'one_wrench':
        out.append(pg_clamp())
        out.append(spin(CX0 + 11, cy))
        out.append(wrench(CX0 + 11, cy, 70))
        out.append(hand_at(106, 142, 120))
    elif kind == 'uneven':
        out.append(pg_clamp(gap=8, tilt=-7))
        out.append(f'<path d="M{CX1 - 4} {MY - 14} l7 -6" stroke="{FACE}" stroke-width="1.4"/>')
        out.append(wrench(CX0 + 11, cy, 70))
        out.append(hand_at(106, 142, 120))
        out.append(hot(CX1 + 2, JY + 2, 11))
    return card_close(out)


CARDS = {
    'bridge_same': bridge_card('same'),
    'bridge_thick': bridge_card('thick'),
    'bridge_thin': bridge_card('thin'),
    'bridge_none': bridge_card('none'),
    'bridge_loose': bridge_card('loose'),
    'connector_pg': connector_card('pg'),
    'connector_crimp': connector_card('crimp'),
    'connector_bimetal': connector_card('bimetal'),
    'connector_plain_cu': connector_card('plain_cu'),
    'connector_twist': connector_card('twist'),
    'connector_pliers': connector_card('pliers'),
    'fit_brush': fit_card('brush'),
    'fit_paste': fit_card('paste'),
    'fit_wrenches': fit_card('wrenches'),
    'fit_dirty': fit_card('dirty'),
    'fit_one_wrench': fit_card('one_wrench'),
    'fit_uneven': fit_card('uneven'),
    'shape_u': shape_card('u'),
    'shape_support': shape_card('support'),
    'shape_arm': shape_card('arm'),
    'shape_phase': shape_card('phase'),
    'shape_kink': shape_card('kink'),
    'patrol_calm': patrol_card('calm'),
    'patrol_calm_support': patrol_card('calm_support'),
    'patrol_hot': patrol_card('hot'),
    'patrol_spark': patrol_card('spark'),
    'patrol_corona': patrol_card('corona'),
    'patrol_fallen': patrol_card('fallen'),
}

# Safe cards and traps per round (mirrors learn_board_pack42.dart).
ROUNDS = {
    'bridge': (['bridge_same', 'bridge_thick'], ['bridge_thin', 'bridge_none', 'bridge_loose']),
    'connector': (['connector_pg', 'connector_crimp', 'connector_bimetal'], ['connector_plain_cu', 'connector_twist', 'connector_pliers']),
    'fit': (['fit_brush', 'fit_paste', 'fit_wrenches'], ['fit_dirty', 'fit_one_wrench', 'fit_uneven']),
    'shape': (['shape_u', 'shape_support'], ['shape_arm', 'shape_phase', 'shape_kink']),
    'patrol': (['patrol_calm', 'patrol_calm_support'], ['patrol_hot', 'patrol_spark', 'patrol_corona', 'patrol_fallen']),
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
