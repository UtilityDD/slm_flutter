"""Picture cards for ladder step 25 (lesson 1.9 শেখা, "ঝড়-বৃষ্টিতে কাজ: কখন 'না' বলবেন").

python -I tool/storm_board_art.py .

Writes assets/game/art/storm_board/*.svg in the same clean gradient style as
tool/rod_board_art.py, tool/pole_board_art.py and tool/harness_board_art.py
(200 x 220 scene cards, drawn edge to edge). No words in the art.

What the cards show comes from lesson 1.9 only:
  1. rain: wet pole, cross-arm, ladder and tools are slippery (a fall);
     wet PPE / wet air conduct (flashover, arc flash); heavy rain hides the
     wires; routine maintenance stops in the rain;
  2. lightning is the red line: no PPE works; seen or heard -> work at height
     stops at once and the worker comes down; a direct strike on the pole or
     in the open is deadly; a strike nearby shocks through the ground and the
     line (induction);
  3. strong wind (usually over 40-50 km/h): balance lost on the pole, flying
     dust in the eyes, conductor galloping (phase-to-phase short, the safe
     distance shrinks); don't fight the wind;
  4. step potential: a strike spreads voltage through the ground — a shock
     between the two feet; no big steps (the lesson: "বজ্রে বড় পদক্ষেপ নয়",
     "hops/shelter নিয়ম");
  5. the pro tips: check the weather before and during the job, trust the
     feeling that it is unsafe, Stop Work is a right — saying 'না' is a duty.

Fairness (the playbook, section 4, and the step-10 / step-13 reviews): every
card in a round shares one sky, one ground, one pole, one ladder, one worker;
the storm is on the safe cards too. Only the act tells the safe card from a
trap. The script checks every hand the dealer can make (one safe card + any
three traps): each colour or gradient the safe card draws is drawn by a trap
in that hand, and the safe card's backdrop is a trap's backdrop too.
The pose must not give it away either (the step-25 review: "the lowest
worker is the right one"): no ladder is ever lying flat, and in every hand a
safe card with the worker on (or just off) the ground meets a trap with a
figure down there too: a ground-level trap or a low rung.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/storm_board_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'storm_board')
W, H = 200, 220

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
RAIL = '#B0B7BD'
BOLT = '#FFF4B0'

DEFS = """<defs>
  <linearGradient id="skyRain" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A5866"/><stop offset="1" stop-color="#8E9AA4"/></linearGradient>
  <linearGradient id="skyStorm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#252F3C"/><stop offset="0.7" stop-color="#4E5C6A"/><stop offset="1" stop-color="#6E7C88"/></linearGradient>
  <linearGradient id="skyWind" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6F7378"/><stop offset="0.6" stop-color="#A99F86"/><stop offset="1" stop-color="#CDBB93"/></linearGradient>
  <linearGradient id="skyTurn" x1="0" y1="0" x2="1" y2="0.3"><stop offset="0" stop-color="#3A4552"/><stop offset="0.45" stop-color="#6E8193"/><stop offset="1" stop-color="#A9CBE3"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="groundWet" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7F7356"/><stop offset="1" stop-color="#5E5440"/></linearGradient>
  <linearGradient id="groundDust" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C2AE84"/><stop offset="1" stop-color="#A08B60"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="bag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A6A3E"/><stop offset="1" stop-color="#5E4626"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.85"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.45"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="dust" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#D9C69A" stop-opacity="0.95"/><stop offset="1" stop-color="#D9C69A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(sky):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def cloud(x, y, s=1.0, fill='#3A4652', op=0.9):
    return (f'<g fill="{fill}" opacity="{op}"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(24 * s)}" ry="{f(9 * s)}"/>'
            f'<ellipse cx="{f(x + 16 * s)}" cy="{f(y - 7 * s)}" rx="{f(16 * s)}" ry="{f(10 * s)}"/>'
            f'<ellipse cx="{f(x - 14 * s)}" cy="{f(y - 3 * s)}" rx="{f(12 * s)}" ry="{f(7 * s)}"/></g>')


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def qpt(p0, p1, p2, t):
    a, b, c = (1 - t) ** 2, 2 * t * (1 - t), t * t
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])


# --------------------------------------------------------------------------
# The line: a PCC pole on the right, a cross-arm, three conductors running
# off to the left; a ladder against the pole's left face.
# --------------------------------------------------------------------------

GY = 192            # ground line
PX = 152            # pole centre
PW = 13
ARM_Y = 54
INS_NEAR = (116, ARM_Y + 3)
INS_FAR = (190, ARM_Y - 2)
TOP_PH = ((-4, 14), (70, 30), (PX, 2))
FAR_PH = ((-4, 30), (96, 46), (INS_FAR[0], INS_FAR[1] - 17))
NEAR_PH = ((-4, 46), (60, 62), (INS_NEAR[0], INS_NEAR[1] - 17))
LAD_FOOT = (106, GY)
LAD_TOP = (136, 62)
LAD_W = 9


def lad(t):
    """A point on the ladder's outer rail, t = 0 (foot) .. 1 (top)."""
    return lerp(LAD_FOOT, LAD_TOP, t)


def insulator(x, y, s=1.0):
    return (f'<g transform="translate({f(x)} {f(y)}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


def wire(p, w=2.0, op=1.0):
    (x0, y0), (cx, cy), (x1, y1) = p
    return f'<path d="M{f(x0)} {f(y0)} Q{f(cx)} {f(cy)} {f(x1)} {f(y1)}" stroke="{WIRE}" stroke-width="{w}" fill="none" opacity="{op}"/>'


def gallop_wire(p, amp, phase, w=2.0):
    """A conductor swinging in the wind: a wave along the span plus a ghost."""
    (x0, y0), (cx, cy), (x1, y1) = p
    pts = []
    for i in range(25):
        t = i / 24
        x, y = qpt(p[0], p[1], p[2], t)
        y += math.sin(t * math.pi) * amp * math.sin(t * math.pi * 2 + phase)
        pts.append((x, y))
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    ghost = []
    for i in range(25):
        t = i / 24
        x, y = qpt(p[0], p[1], p[2], t)
        y -= math.sin(t * math.pi) * amp * 0.7 * math.sin(t * math.pi * 2 + phase)
        ghost.append((x, y))
    g = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in ghost)
    return (f'<path d="{g}" stroke="{WIRE}" stroke-width="{w}" fill="none" opacity="0.28"/>'
            f'<path d="{d}" stroke="{WIRE}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>')


def ladder_svg(foot, top, w=LAD_W, rungs=10):
    (x0, y0), (x1, y1) = foot, top
    s = [f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)} M{f(x0 + w)} {f(y0 + 1)} L{f(x1 + w)} {f(y1 + 1)}" stroke="{RAIL}" stroke-width="2.6" stroke-linecap="round"/>']
    for i in range(1, rungs + 1):
        t = i / (rungs + 1)
        xa, ya = lerp(foot, top, t)
        s.append(f'<line x1="{f(xa)}" y1="{f(ya)}" x2="{f(xa + w)}" y2="{f(ya + 1)}" stroke="{RAIL}" stroke-width="2"/>')
    return ''.join(s)


def bag(x, y, s=1.0):
    """The canvas tool bag."""
    return (f'<g transform="translate({f(x)} {f(y)}) scale({s})">'
            '<path d="M-10 -10 Q0 -20 10 -10" stroke="#5E4626" stroke-width="2" fill="none"/>'
            '<path d="M-13 -10 L13 -10 L15 2 L-15 2 Z" fill="url(#bag)"/>'
            '<path d="M-13 -6 L13 -6" stroke="#5E4626" stroke-width="1"/></g>')


def tree_row(y, fill, bend=0.0):
    out = []
    for x, r in [(10, 12), (34, 9), (58, 13), (90, 8)]:
        out.append(f'<ellipse cx="{f(x + bend * r * 0.7)}" cy="{f(y - r * 0.6)}" rx="{f(r * (1.3 + abs(bend) * 0.3))}" '
                   f'ry="{f(r * (1 - abs(bend) * 0.15))}"/>')
    return f'<g fill="{fill}" opacity="0.8">{"".join(out)}</g>'


def bent_tree(x, y, h, bend):
    """A lone roadside tree bending in the wind (trunk + leaning crown)."""
    tx, ty = x + bend * h * 0.45, y - h
    return (f'<path d="M{f(x)} {f(y)} Q{f(x + bend * h * 0.05)} {f(y - h * 0.5)} {f(tx)} {f(ty)}" stroke="#5A4630" stroke-width="3.2" fill="none" stroke-linecap="round"/>'
            f'<g fill="#5E7F55"><ellipse cx="{f(tx + bend * 6)}" cy="{f(ty)}" rx="{f(h * 0.42)}" ry="{f(h * 0.24)}" transform="rotate({f(bend * 24)} {f(tx)} {f(ty)})"/>'
            f'<ellipse cx="{f(tx + bend * 14)}" cy="{f(ty + 4)}" rx="{f(h * 0.26)}" ry="{f(h * 0.15)}" transform="rotate({f(bend * 24)} {f(tx)} {f(ty)})"/></g>')


def bolt(pts, w=2.2):
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    x, y = pts[-1]
    return (f'<path d="{d}" stroke="{BOLT}" stroke-width="{f(w * 3.2)}" fill="none" opacity="0.35" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{HELMET}" stroke-width="{f(w * 1.6)}" fill="none" opacity="0.6" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="#FFFFFF" stroke-width="{f(w)}" fill="none" stroke-linejoin="round" stroke-linecap="round"/>')


def far_bolt():
    """Lightning over the far fields, on every card of a storm round."""
    pts = [(30, -2), (24, 22), (34, 30), (20, 58), (30, 64), (18, 96)]
    return (f'<ellipse cx="28" cy="40" rx="40" ry="46" fill="url(#flash)"/>' + bolt(pts, 1.8)
            + bolt([(24, 22), (12, 36), (8, 50)], 1.0))


def rain(out, dense=1):
    n = 46 * dense
    streaks = ''.join(f'<path d="M{(12 + (i * 37) % 210) - 6} {(i * 53) % 214} l-5 12"/>' for i in range(n))
    out.append(f'<g stroke="#DCE6EE" stroke-width="1.1" stroke-linecap="round" opacity="0.7">{streaks}</g>')


def puddles():
    return ('<ellipse cx="54" cy="206" rx="24" ry="3.4" fill="#B9C6D0" opacity="0.55"/>'
            '<ellipse cx="160" cy="212" rx="18" ry="2.8" fill="#B9C6D0" opacity="0.55"/>')


def dust_streaks():
    return ('<g stroke="#E3D3AA" stroke-width="1.2" stroke-linecap="round" opacity="0.6">'
            + ''.join(f'<path d="M{x} {y} l{L} {f(L * 0.12)}"/>' for x, y, L in
                      [(6, 70, 26), (60, 96, 18), (14, 130, 30), (120, 116, 16), (40, 160, 22), (150, 150, 20), (90, 176, 26), (4, 100, 14)])
            + '</g>')


def pole_and_line(galloping=False, faded=False):
    s = []
    op = 0.35 if faded else 1.0
    if galloping:
        s.append(gallop_wire(FAR_PH, 7, 0.4, 1.6))
    else:
        s.append(wire(FAR_PH, 1.6, op))
    s.append(insulator(*INS_FAR, 0.85))
    s.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    s.append(f'<path d="M{PX - PW / 2} 0 L{PX - PW / 2} {GY + 3}" stroke="#77746D" stroke-width="0.8"/>')
    s.append(f'<path d="M104 {ARM_Y} L204 {ARM_Y - 6} L204 {ARM_Y} L104 {ARM_Y + 6} Z" fill="url(#steelArm)"/>')
    s.append(f'<path d="M{PX} {ARM_Y + 3} L{PX - 20} {ARM_Y + 26}" stroke="#5F676F" stroke-width="2.4"/>')
    s.append(insulator(PX, 16, 0.85))
    s.append(insulator(*INS_NEAR))
    if galloping:
        s.append(gallop_wire(TOP_PH, 9, 1.6, 1.8))
        s.append(gallop_wire(NEAR_PH, 11, 0.0, 2.2))
    else:
        s.append(wire(TOP_PH, 1.8, op))
        s.append(wire(NEAR_PH, 2.2, op))
    for y in (150, 176):
        s.append(f'<rect x="{PX + PW / 2}" y="{y}" width="6" height="2.4" rx="1" fill="#6F777E"/>')
    return ''.join(s)


# --------------------------------------------------------------------------
# The worker: one figure, any pose, given the joints.
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


def _boot(p, face, ang=0):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{BOOT}" transform="rotate({f(ang)} {f(x)} {f(y)})"/>'


def _hand(p, palm=False, face=1):
    x, y = p
    if not palm:
        return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'
    # An open palm held up: "stop".
    fingers = ''.join(f'<rect x="{f(x - 3.6 + i * 2.4)}" y="{f(y - 9 + abs(i - 1.5) * 1.2)}" width="2" height="7" rx="1" fill="{GLOVE}"/>' for i in range(4))
    return (fingers + f'<rect x="{f(x - 3.8)}" y="{f(y - 4)}" width="9.6" height="8" rx="2.4" fill="{GLOVE}"/>'
            f'<rect x="{f(x + (5 if face > 0 else -7))}" y="{f(y - 2)}" width="3" height="5.4" rx="1.4" fill="{GLOVE}" transform="rotate({-30 * face} {f(x)} {f(y)})"/>')


def figure(hip, sh, head, feet, hands, face=1, look=0, knees=None, elbows=None, palm=False, props_back='', props_front='',
           boot_ang=(0, 0)):
    """The trainee lineman: blue shirt, dark trousers, yellow helmet, black
    rubber gloves. feet / hands = (back, front); look = head tilt in degrees
    (positive = chin down toward the facing side)."""
    g = []
    fb, ff = feet
    kb = knees[0] if knees and knees[0] else _joint(hip, fb, face)
    kf = knees[1] if knees and knees[1] else _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, PANTS_D, 7))
    g.append(_boot(fb, face, boot_ang[0]))
    g.append(_limb(hip, kf, ff, PANTS, 7))
    g.append(_boot(ff, face, boot_ang[1]))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = elbows[0] if elbows and elbows[0] else _joint(sb, hb, face, down=True)
    ef = elbows[1] if elbows and elbows[1] else _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, SHIRT_D, 5.4))
    g.append(_hand(hb))
    g.append(props_back)
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    # Belt.
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
    g.append(_hand(hf, palm, face))
    return ''.join(g)


def scaled(svg, ox, oy, s):
    return f'<g transform="translate({f(ox)} {f(oy)}) scale({s}) translate({f(-ox)} {f(-oy)})">{svg}</g>'


def standing(x, gy=GY, face=1, hands=None, look=0, lean=0, palm=False, props_back='', props_front='', feet_gap=12):
    hip = (x, gy - 30)
    sh = (x + (1 + lean) * face, gy - 56)
    head = (x + (3 + lean * 1.3) * face, gy - 64)
    feet = ((x - feet_gap / 2 * face - 1 * face, gy - 1), (x + feet_gap / 2 * face, gy - 1))
    if hands is None:
        hands = ((x - 4 * face, gy - 32), (x + 5 * face, gy - 31))
    knees = ((x - 3 * face, gy - 15), (x + 4 * face, gy - 15))
    return figure(hip, sh, head, feet, hands, face, look, knees=knees, palm=palm, props_back=props_back, props_front=props_front)


def on_ladder(t_feet, hands_t=(0.24, 0.3), look=0, slip=False, up=False, props_front='', hands=None, reach_down=False):
    """Climbing (facing the ladder, i.e. right): feet on a rung at t_feet."""
    fa = lad(t_feet)
    fb_ = lad(t_feet + 0.07)
    foot_low = (fa[0] + 4, fa[1] - 1)
    foot_high = (fb_[0] + 4, fb_[1] - 1)
    hip = (foot_low[0] - 9, foot_low[1] - 26)
    sh = (hip[0] + 5, hip[1] - 25)
    head = (sh[0] + 3, sh[1] - 9)
    if hands is None:
        h1 = lad(t_feet + hands_t[0])
        h2 = lad(t_feet + hands_t[1])
        hands = ((h1[0] + 1, h1[1]), (h2[0] + 3, h2[1]))
    feet = (foot_low, foot_high)
    knees = (None, (foot_high[0] + 2, foot_high[1] - 10))
    ang = (0, 0)
    if slip:
        # The front boot skidded off its wet rung and kicks out into the air.
        feet = ((foot_low[0] - 14, foot_low[1] + 9), foot_high)
        knees = ((hip[0] - 4, hip[1] + 14), knees[1])
        ang = (32, 0)
    if up:
        feet = (foot_low, (foot_high[0], foot_high[1] - 6))
    if reach_down:
        # Coming down: one boot on the rung, the other feeling for the one below.
        feet = ((foot_low[0] - 4, foot_low[1] + 13), foot_low)
        knees = ((hip[0] - 3, hip[1] + 15), (foot_low[0] + 3, foot_low[1] - 11))
    return figure(hip, sh, head, feet, hands, 1, look, knees=knees, props_front=props_front, boot_ang=ang)


def motion_down(x, y):
    """Short streaks above a worker moving down."""
    return ('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85">'
            f'<path d="M{f(x - 6)} {f(y - 12)} l1 9"/><path d="M{f(x)} {f(y - 16)} l1 11"/><path d="M{f(x + 6)} {f(y - 12)} l1 9"/></g>')


def motion_up(x, y):
    return ('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85">'
            f'<path d="M{f(x - 6)} {f(y + 4)} l-1 9"/><path d="M{f(x)} {f(y + 6)} l-1 11"/><path d="M{f(x + 6)} {f(y + 4)} l-1 9"/></g>')


def spanner(x, y, ang):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({ang})"><rect x="0" y="-1.4" width="13" height="2.8" rx="1.2" fill="url(#steel)"/>'
            '<path d="M13 -4 L18 -4 L18 -1.4 L15.5 -1.4 L15.5 1.4 L18 1.4 L18 4 L13 4 Z" fill="url(#steel)"/></g>')


def arc_spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def coil(x, y):
    """A coil of wire carried up on the shoulder."""
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="9" ry="6" fill="none" stroke="{WIRE}" stroke-width="2.2"/>'
            f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="6.5" ry="4" fill="none" stroke="{WIRE}" stroke-width="1.6"/>')


# --------------------------------------------------------------------------
# A round's stage.
# --------------------------------------------------------------------------

def stage(kind, ladder='up', bag_at=(184, GY + 4), galloping=False, faded=False):
    sky = {'rain': 'skyRain', 'thunder': 'skyStorm', 'wind': 'skyWind', 'plan': 'skyTurn'}[kind]
    out = card_open(sky)
    if kind == 'rain':
        out.append(cloud(40, 26, 1.7, '#3A4652') + cloud(140, 14, 1.9, '#46525E'))
    elif kind == 'thunder':
        out.append(far_bolt())
        out.append(cloud(40, 10, 1.9, '#1E2733', 0.95) + cloud(140, 4, 2.0, '#2A3440', 0.95))
    elif kind == 'wind':
        out.append(cloud(30, 30, 1.4, '#5E6168', 0.8) + cloud(130, 18, 1.5, '#6A6C70', 0.75))
    elif kind == 'plan':
        # A dark bank of cloud rolling in from the west (left), blue sky ahead.
        out.append(cloud(18, 30, 2.4, '#262F3A', 0.95) + cloud(56, 48, 1.6, '#323C48', 0.9) + cloud(10, 70, 1.5, '#323C48', 0.9))
        out.append(f'<g fill="#FFFFFF" opacity="0.85"><ellipse cx="170" cy="96" rx="18" ry="6"/><ellipse cx="182" cy="91" rx="12" ry="7"/></g>')
    ground = {'rain': 'groundWet', 'thunder': 'groundWet', 'wind': 'groundDust', 'plan': 'ground'}[kind]
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#{ground})"/>')
    if kind == 'wind':
        out.append(tree_row(GY + 1, '#5E7F55', bend=0.6))
        out.append(bent_tree(40, GY, 58, 0.9))
        out.append(dust_streaks())
    else:
        out.append(tree_row(GY + 1, '#4E6B48' if kind in ('rain', 'thunder') else '#6F9560'))
    out.append(pole_and_line(galloping, faded))
    if kind == 'rain':
        out.append(puddles())
    if bag_at:
        out.append(bag(*bag_at))
    if ladder == 'up':
        out.append(ladder_svg(LAD_FOOT, LAD_TOP))
    return out


# --------------------------------------------------------------------------
# Round 1 — rain: slippery, arc flash, can't see; routine work stops.
# --------------------------------------------------------------------------

def rain_card(kind):
    if kind == 'packed':
        out = stage('rain', bag_at=None)
        out.append(standing(66, face=1, hands=((60, GY - 34), (78, GY - 38)), look=8,
                            props_front=bag(80, GY - 30, 0.9)))
    elif kind == 'down':
        out = stage('rain')
        out.append(on_ladder(0.12, hands_t=(0.26, 0.32), look=26, reach_down=True))
        out.append(motion_down(lad(0.46)[0] - 6, lad(0.46)[1] - 22))
    elif kind == 'arc':
        out = stage('rain')
        out.append(on_ladder(0.62, hands=((lad(0.88)[0] + 2, lad(0.88)[1]), (INS_NEAR[0] + 2, INS_NEAR[1] - 14)),
                             props_front=spanner(INS_NEAR[0] + 2, INS_NEAR[1] - 14, -120), look=-10))
        out.append(arc_spark(INS_NEAR[0] - 4, INS_NEAR[1] - 22, 1.2))
    elif kind == 'slip':
        out = stage('rain')
        # Rushing up the wet ladder: a boot skids off a low rung.
        ha = lad(0.46)
        out.append(on_ladder(0.18, hands=((ha[0] + 2, ha[1]), (ha[0] - 30, ha[1] - 6)), slip=True, look=-6))
        x, y = lad(0.18)
        out.append(f'<g fill="#DCE6EE">' + ''.join(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="{r}"/>'
                                                   for dx, dy, r in ((-2, -4, 1.6), (6, -7, 1.3), (-8, 0, 1.2), (10, -2, 1.1))) + '</g>')
    elif kind == 'blind':
        out = stage('rain', faded=True)
        out.append(on_ladder(0.62, hands=((lad(0.9)[0] + 2, lad(0.9)[1]), (INS_NEAR[0] + 4, INS_NEAR[1] - 12)), look=-8))
        rain(out, 2)
        out.append('<rect width="200" height="220" fill="#B9C6D0" opacity="0.32"/>')
    elif kind == 'raise':
        out = stage('rain', ladder=None)
        out.append(ladder_svg((118, GY), (64, 86)))
        out.append(standing(84, face=-1, hands=((76, 124), (86, 118)), look=-24))
    if kind != 'blind':
        rain(out)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — lightning: the red line. Seen or heard -> come down.
# --------------------------------------------------------------------------

def thunder_card(kind):
    if kind == 'down':
        out = stage('thunder')
        out.append(on_ladder(0.12, hands_t=(0.26, 0.32), look=26, reach_down=True))
        out.append(motion_down(lad(0.46)[0] - 6, lad(0.46)[1] - 22))
    elif kind == 'away':
        out = stage('thunder', bag_at=None)
        # Off the ladder, walking away from the pole, the bag over the shoulder.
        x = 70
        hip, sh, head = (x, GY - 30), (x - 3, GY - 56), (x - 5, GY - 64)
        out.append(figure(hip, sh, head, ((x + 8, GY - 1), (x - 10, GY - 1)), ((x + 4, GY - 46), (x - 10, GY - 34)), face=-1,
                          knees=((x + 3, GY - 15), (x - 7, GY - 16)), props_back=bag(x + 6, GY - 40, 0.8)))
    elif kind == 'finish':
        out = stage('thunder')
        out.append(on_ladder(0.62, hands=((lad(0.88)[0] + 2, lad(0.88)[1]), (INS_NEAR[0] + 2, INS_NEAR[1] - 12)),
                             props_front=spanner(INS_NEAR[0] + 2, INS_NEAR[1] - 12, -120), look=-10))
    elif kind == 'wait_top':
        out = stage('thunder')
        # Sitting on the cross-arm against the pole, waiting for it to pass.
        hip = (132, ARM_Y - 1)
        out.append(figure(hip, (130, ARM_Y - 26), (131, ARM_Y - 35), ((136, ARM_Y + 22), (140, ARM_Y + 20)),
                          ((141, ARM_Y - 12), (PX - 6, ARM_Y - 20)), face=1, look=-4,
                          knees=((142, ARM_Y + 2), (146, ARM_Y))))
    elif kind == 'climb_up':
        out = stage('thunder')
        out.append(on_ladder(0.2, hands_t=(0.3, 0.42), up=True, look=-18))
        sx, sy = lad(0.2)
        out.append(coil(sx - 4, sy - 50))
        out.append(motion_up(sx - 10, sy + 6))
    elif kind == 'lean_pole':
        out = stage('thunder', bag_at=(74, GY + 4))
        x = PX + PW / 2 + 12
        out.append(standing(x, face=1, hands=((x - 9, GY - 36), (x - 2, GY - 40)), lean=-7, look=-12))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — strong wind: balance, dust, galloping conductors.
# --------------------------------------------------------------------------

def wind_card(kind):
    if kind == 'wait':
        out = stage('wind', galloping=True)
        x = 70
        out.append(standing(x, face=1, hands=((x - 4, GY - 32), (x + 3, GY - 72)), lean=-2, look=-14))
    elif kind == 'down':
        out = stage('wind', galloping=True)
        out.append(on_ladder(0.12, hands_t=(0.26, 0.32), look=26, reach_down=True))
        out.append(motion_down(lad(0.46)[0] - 6, lad(0.46)[1] - 22))
    elif kind == 'sway':
        out = stage('wind', ladder=None, galloping=True)
        g = ladder_svg(LAD_FOOT, LAD_TOP) + on_ladder(0.62, hands=((lad(0.62)[0] - 26, lad(0.62)[1] - 40), (lad(0.62)[0] + 18, lad(0.62)[1] - 48)), look=-14)
        out.append(f'<g transform="rotate(-7 {LAD_FOOT[0]} {LAD_FOOT[1]})">{g}</g>')
        x, y = lad(0.85)
        out.append(f'<g stroke="#FFFFFF" stroke-width="1.4" fill="none" opacity="0.85" stroke-linecap="round">'
                   f'<path d="M{f(x - 34)} {f(y - 4)} q-6 10 0 20"/><path d="M{f(x - 40)} {f(y - 8)} q-8 14 0 28"/></g>')
    elif kind == 'gallop':
        out = stage('wind', galloping=True)
        out.append(on_ladder(0.62, hands=((lad(0.88)[0] + 2, lad(0.88)[1]), (INS_NEAR[0] + 2, INS_NEAR[1] - 12)), look=-14))
        # Two phases swung together: a flash between them, right by his head.
        out.append(arc_spark(62, 46, 1.1))
    elif kind == 'dust':
        out = stage('wind', galloping=True)
        # Setting off up the ladder with an arm over his eyes in the dust.
        fa = lad(0.03)
        out.append(on_ladder(0.03, hands=((lad(0.29)[0] + 1, lad(0.29)[1]), (fa[0] - 6, fa[1] - 58)), look=10))
        out.append(f'<ellipse cx="{f(fa[0] - 14)}" cy="{f(fa[1] - 60)}" rx="34" ry="20" fill="url(#dust)"/>')
        out.append(f'<ellipse cx="{f(fa[0] - 36)}" cy="{f(fa[1] - 50)}" rx="22" ry="12" fill="url(#dust)"/>')
    elif kind == 'raise':
        out = stage('wind', ladder=None, galloping=True)
        out.append(ladder_svg((118, GY), (64, 84)))
        out.append(standing(86, face=-1, hands=((78, 122), (88, 116)), look=-24, lean=2))
        out.append('<g stroke="#FFFFFF" stroke-width="1.4" fill="none" opacity="0.85" stroke-linecap="round">'
                   '<path d="M52 74 q-8 8 -4 18"/><path d="M44 70 q-10 12 -5 26"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — step potential: a strike on the pole spreads into the ground.
# --------------------------------------------------------------------------

SGY = 150           # horizon of the step round (the ground runs to the bottom)
SPX = 40            # the struck pole


def step_stage():
    out = card_open('skyStorm')
    out.append(cloud(80, 8, 2.0, '#1E2733', 0.95) + cloud(170, 14, 1.8, '#2A3440', 0.95))
    out.append(f'<rect y="{SGY}" width="{W}" height="{H - SGY}" fill="url(#groundWet)"/>')
    out.append(tree_row(SGY + 1, '#4E6B48'))
    # The pole, struck at its top.
    out.append(f'<rect x="{SPX - 6}" y="20" width="12" height="{SGY - 18}" fill="url(#pole)"/>')
    out.append(f'<path d="M{SPX - 26} 34 L{SPX + 30} 29 L{SPX + 30} 34 L{SPX - 26} 39 Z" fill="url(#steelArm)"/>')
    out.append(insulator(SPX - 18, 36, 0.7) + insulator(SPX + 22, 31, 0.7))
    out.append(wire(((SPX - 18, 23), (100, 40), (204, 30)), 1.6) + wire(((SPX + 22, 18), (120, 30), (204, 18)), 1.6))
    out.append(f'<ellipse cx="{SPX}" cy="24" rx="34" ry="34" fill="url(#flash)"/>')
    out.append(bolt([(70, -4), (58, 6), (66, 10), (50, 18), (SPX + 2, 22)], 2.2))
    # Voltage rings spreading through the ground from the pole's foot.
    rings = ''.join(f'<ellipse cx="{SPX}" cy="{SGY + 2}" rx="{rx}" ry="{f(rx * 0.3)}" fill="none" stroke="{HELMET}" '
                    f'stroke-width="1.6" stroke-dasharray="5 4" opacity="{op}"/>'
                    for rx, op in ((26, 0.9), (60, 0.7), (100, 0.5), (146, 0.35), (196, 0.22)))
    out.append(rings)
    out.append(f'<ellipse cx="{SPX}" cy="{SGY + 2}" rx="12" ry="4" fill="url(#flash)"/>')
    return out


def walk_streaks(x, y):
    """Short streaks behind a worker on the move."""
    return ('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.8">'
            f'<path d="M{f(x)} {f(y)} l-10 0"/><path d="M{f(x + 2)} {f(y - 8)} l-12 0"/><path d="M{f(x)} {f(y - 16)} l-8 0"/></g>')


def step_card(kind):
    out = step_stage()
    gy = 204
    s = 1.45
    if kind == 'small':
        x = 120
        hip, sh, head = (x, gy - 30), (x + 2, gy - 56), (x + 4, gy - 64)
        fig = figure(hip, sh, head, ((x - 7, gy - 3), (x + 6, gy - 1)), ((x - 5, gy - 33), (x + 8, gy - 32)), face=1, look=12,
                     knees=((x - 2, gy - 15), (x + 5, gy - 16)), boot_ang=(14, 0))
        out.append(scaled(fig, x, gy, s))
        out.append(walk_streaks(x - 22, gy - 8))
    elif kind == 'hop':
        x, lift = 122, 12
        hip, sh, head = (x, gy - 30 - lift), (x + 3, gy - 55 - lift), (x + 5, gy - 63 - lift)
        fig = figure(hip, sh, head, ((x - 1, gy - 1 - lift), (x + 3, gy - 1 - lift)), ((x - 5, gy - 40 - lift), (x + 9, gy - 42 - lift)),
                     face=1, look=10, knees=((x + 6, gy - 17 - lift), (x + 9, gy - 17 - lift)))
        out.append(f'<ellipse cx="{x + 2}" cy="{gy + 1}" rx="10" ry="2.6" fill="{PANTS_D}" opacity="0.35"/>')
        out.append(scaled(fig, x, gy, s))
        out.append('<g stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85">'
                   f'<path d="M{x - 30} {gy - 10} q8 -14 16 -2"/><path d="M{x - 46} {gy - 8} q8 -10 14 -2"/></g>')
    elif kind == 'stride':
        x = 118
        hip, sh, head = (x, gy - 29), (x + 9, gy - 53), (x + 13, gy - 61)
        fig = figure(hip, sh, head, ((x - 22, gy - 7), (x + 20, gy - 1)), ((x - 9, gy - 36), (x + 18, gy - 44)), face=1, look=-4,
                     knees=((x - 10, gy - 14), (x + 12, gy - 18)), boot_ang=(28, 0))
        out.append(scaled(fig, x, gy, s))
        out.append(walk_streaks(x - 46, gy - 14))
    elif kind == 'wide':
        x = 124
        hip, sh, head = (x, gy - 28), (x - 1, gy - 54), (x - 3, gy - 62)
        fig = figure(hip, sh, head, ((x + 14, gy - 1), (x - 15, gy - 1)), ((x + 5, gy - 30), (x - 6, gy - 30)), face=-1, look=-6,
                     knees=((x + 7, gy - 14), (x - 8, gy - 14)))
        out.append(scaled(fig, x, gy, s))
    elif kind == 'pole':
        # Crouched at the foot of the struck pole, back against it.
        x, g2 = SPX + 16, SGY + 18
        hip, sh, head = (x - 2, g2 - 19), (x + 3, g2 - 43), (x + 5, g2 - 51)
        fig = figure(hip, sh, head, ((x + 2, g2 - 1), (x + 12, g2 - 1)), ((x + 9, g2 - 20), (x + 13, g2 - 24)), face=1, look=4,
                     knees=((x + 10, g2 - 20), (x + 15, g2 - 18)))
        out.append(scaled(fig, x, g2, 1.1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — the sky turns: check the weather, trust the feeling, say 'না'.
# --------------------------------------------------------------------------

def phone(x, y):
    """A phone held up, its screen showing the storm on the weather."""
    return (f'<g transform="rotate(-12 {f(x)} {f(y)})"><rect x="{f(x - 6)}" y="{f(y - 10)}" width="12" height="20" rx="2" fill="{BOOT}"/>'
            f'<rect x="{f(x - 4.6)}" y="{f(y - 8)}" width="9.2" height="15" rx="1" fill="url(#skyTurn)"/>'
            f'<g fill="#262F3A"><ellipse cx="{f(x)}" cy="{f(y - 3)}" rx="3.4" ry="1.8"/><ellipse cx="{f(x + 1.6)}" cy="{f(y - 4.4)}" rx="2.2" ry="1.6"/></g>'
            f'<path d="M{f(x + 0.6)} {f(y - 1.4)} L{f(x - 1)} {f(y + 1.6)} L{f(x + 0.8)} {f(y + 1.6)} L{f(x - 0.6)} {f(y + 4.6)}" stroke="{HELMET}" stroke-width="1" fill="none"/></g>')


def plan_card(kind):
    if kind == 'forecast':
        out = stage('plan')
        x = 64
        out.append(standing(x, face=1, hands=((x - 4, GY - 32), (x + 13, GY - 44)), look=22,
                            props_front=scaled(phone(x + 15, GY - 52), x + 15, GY - 46, 1.15)))
    elif kind == 'say_no':
        out = stage('plan')
        x = 64
        out.append(standing(x, face=1, hands=((x - 4, GY - 32), (x + 24, GY - 54)), look=-4, palm=True))
    elif kind == 'rush':
        out = stage('plan')
        out.append(on_ladder(0.2, hands_t=(0.3, 0.42), up=True, look=-18))
        sx, sy = lad(0.2)
        out.append(motion_up(sx - 10, sy + 6))
    elif kind == 'back':
        out = stage('plan')
        out.append(on_ladder(0.62, hands=((lad(0.88)[0] + 2, lad(0.88)[1]), (INS_NEAR[0] + 2, INS_NEAR[1] - 12)),
                             props_front=spanner(INS_NEAR[0] + 2, INS_NEAR[1] - 12, -120), look=12))
    elif kind == 'mate':
        out = stage('plan')
        # The mate below points at the cloud; the man on the ladder waves him off.
        x = 54
        out.append(standing(x, face=-1, hands=((x + 4, GY - 32), (x - 16, GY - 76)), look=-20))
        out.append(on_ladder(0.62, hands=((lad(0.88)[0] + 2, lad(0.88)[1]), (lad(0.62)[0] - 26, lad(0.62)[1] - 50)), look=-6))
    elif kind == 'raise':
        # The cloud bank rolls in and he raises the ladder to start anyway.
        out = stage('plan', ladder=None)
        out.append(ladder_svg((118, GY), (64, 86)))
        out.append(standing(84, face=-1, hands=((76, 124), (86, 118)), look=-24))
    return card_close(out)


CARDS = {
    # Round 1 — rain.
    'rain_packed': rain_card('packed'),
    'rain_down': rain_card('down'),
    'rain_arc': rain_card('arc'),
    'rain_slip': rain_card('slip'),
    'rain_blind': rain_card('blind'),
    'rain_raise': rain_card('raise'),
    # Round 2 — lightning.
    'thunder_down': thunder_card('down'),
    'thunder_away': thunder_card('away'),
    'thunder_finish': thunder_card('finish'),
    'thunder_wait_top': thunder_card('wait_top'),
    'thunder_climb_up': thunder_card('climb_up'),
    'thunder_lean_pole': thunder_card('lean_pole'),
    # Round 3 — strong wind.
    'wind_wait': wind_card('wait'),
    'wind_down': wind_card('down'),
    'wind_sway': wind_card('sway'),
    'wind_gallop': wind_card('gallop'),
    'wind_dust': wind_card('dust'),
    'wind_raise': wind_card('raise'),
    # Round 4 — step potential.
    'step_small': step_card('small'),
    'step_hop': step_card('hop'),
    'step_stride': step_card('stride'),
    'step_wide': step_card('wide'),
    'step_pole': step_card('pole'),
    # Round 5 — the sky turns: say 'না'.
    'plan_forecast': plan_card('forecast'),
    'plan_say_no': plan_card('say_no'),
    'plan_rush': plan_card('rush'),
    'plan_back': plan_card('back'),
    'plan_mate': plan_card('mate'),
    'plan_raise': plan_card('raise'),
}

# Safe cards and traps per round (mirrors learn_board_pack19.dart), for the
# fairness check below.
ROUNDS = {
    'rain': (['rain_packed', 'rain_down'], ['rain_arc', 'rain_slip', 'rain_blind', 'rain_raise']),
    'thunder': (['thunder_down', 'thunder_away'], ['thunder_finish', 'thunder_wait_top', 'thunder_climb_up', 'thunder_lean_pole']),
    'wind': (['wind_wait', 'wind_down'], ['wind_sway', 'wind_gallop', 'wind_dust', 'wind_raise']),
    'step': (['step_small', 'step_hop'], ['step_stride', 'step_wide', 'step_pole']),
    'plan': (['plan_forecast', 'plan_say_no'], ['plan_rush', 'plan_back', 'plan_mate', 'plan_raise']),
}
HAND = 4

# Where the figures are: low = a figure on the ground or on the ladder's
# lowest rungs (feet at t <= 0.25); every other card has its figure only up
# the pole.
LOW = {
    'rain_packed', 'rain_down', 'rain_slip', 'rain_raise',
    'thunder_down', 'thunder_away', 'thunder_climb_up', 'thunder_lean_pole',
    'wind_wait', 'wind_down', 'wind_dust', 'wind_raise',
    'step_small', 'step_hop', 'step_stride', 'step_wide', 'step_pole',
    'plan_forecast', 'plan_say_no', 'plan_rush', 'plan_mate', 'plan_raise',
}

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
                if s in LOW and not any(t in LOW for t in hand):
                    problems.append(f'{rnd}: {s} is the only low figure with {hand}')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    # The folder is shared with steps 26/27 (sky_*.svg, push_*.svg): only
    # stale cards of this board's own rounds are removed.
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old.split('_')[0] in ROUNDS and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
