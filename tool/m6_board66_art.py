"""Picture cards for lesson 6.6 শেখা ("এবি কেবিল (AB Cable): ঝঞ্ঝাটমুক্ত আধুনিক লাইন").

python -I tool/m6_board66_art.py .

Writes assets/game/art/m6_board66/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
and no digits in the art.

What the cards show comes from lesson 6.6 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only:
  1. bundle: what an AB cable is — three insulated phase cores twisted round a
     bare, or an insulated (different size), neutral-cum-messenger. Traps:
     four bare wires on a cross-arm, four insulated wires hung apart, three
     cores twisted with no messenger;
  2. grip: the clamp's jaw holds the messenger only (pro tip 1). The phase
     cores carry 1, 2 or 3 ridges (pro tip 2), the insulated messenger is a
     different size and smooth. Traps: the jaw on a 1-ridge core, on a
     3-ridge core, on the whole bundle;
  3. pole: a suspension clamp on a straight run; a tension (anchoring) clamp
     where the line ends or turns. Traps: a dead end or a turn on a
     suspension clamp alone (the span sags), an ordinary bare-line bolted
     clamp biting the insulation (myth 2);
  4. ipc: the service joint — the IPC tightened till its shear head broke
     off; a cut-away of its teeth through the insulation into the conductor.
     Traps: a cut-away with the shear head still on and the teeth stuck in the
     insulation, a service wire twisted round a bared core, a bare-line bolted
     connector;
  5. care: the insulation — pulled over a roller on the pole, a small nick
     covered with waterproof tape (gloved hands) or a heat-shrink tube end to
     end. Traps: dragged over the bare bracket and the stony road, the nick
     left open in the rain, the tape wound with bare hands (the cable is
     always treated as live).
Five rounds (ruling M5-11 / the owner's Wave A answers): the spec's roller
and nick rounds share one 'care' round.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too. It
deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board66_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board66')
W, H = 200, 220
GY = 198

SHIRT_D = '#174A70'
SHIRT = '#1F5F8F'
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
INK = '#4A5560'
CORE = '#262B31'       # black XLPE insulation of a core
CORE_HI = '#56606B'    # the shine on a core
RIDGE = '#7A848E'      # the phase ridges on a core
ALU = '#C3C9CE'        # bare aluminium (messenger, conductor)
ALU_D = '#8C959C'      # its shadow / strands
IPC_C = '#3D454E'      # the IPC body
TOOTH = '#C9A43A'      # IPC teeth (tinned brass)
TAPE = '#3A4A5E'       # waterproof insulating tape
STONE = '#8E8A80'
RAIN = '#5E86B0'
CLOUD_D = '#76818C'
TREE = '#4E7A3C'
TREE_D = '#3C6230'
SUN = '#FFE08A'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="near" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9C6DC"/><stop offset="0.7" stop-color="#E4ECEE"/><stop offset="1" stop-color="#EFE7D6"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9AE98"/><stop offset="1" stop-color="#9C917C"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="ceramic" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9D3C6"/><stop offset="0.45" stop-color="#FAF8F2"/><stop offset="1" stop-color="#C8C1B2"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="drum" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A5A3A"/><stop offset="0.5" stop-color="#A47C52"/><stop offset="1" stop-color="#6E5034"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
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
# People (the worker from tool/m6_board63_art.py; gloves or bare hands).
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


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True):
    hand_c = GLOVE if gloves else SKIN
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, SHIRT_D, 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
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
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, SHIRT, 5.4))
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, s=S):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, gloves)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def arms(hands, gloves=True, side=1):
    """The forearms of a worker reaching in from the bottom edge (a close-up):
    blue sleeves, rubber gloves or bare hands."""
    hand_c = GLOVE if gloves else SKIN
    o = []
    for i, (hx, hy) in enumerate(hands):
        bx = hx + (30 + 18 * i) * side
        o.append(f'<path d="M{f(bx)} {H + 4} Q{f((bx + hx) / 2 + 6 * side)} {f((H + hy) / 2 + 10)} {f(hx)} {f(hy)}" '
                 f'stroke="{SHIRT if i else SHIRT_D}" stroke-width="11" stroke-linecap="round" fill="none"/>')
        o.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="6.5" fill="{hand_c}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Cable geometry.
# --------------------------------------------------------------------------

def qpt(p0, c, p1, t):
    u = 1 - t
    return (u * u * p0[0] + 2 * u * t * c[0] + t * t * p1[0], u * u * p0[1] + 2 * u * t * c[1] + t * t * p1[1])


def qnorm(p0, c, p1, t):
    dx = 2 * (1 - t) * (c[0] - p0[0]) + 2 * t * (p1[0] - c[0])
    dy = 2 * (1 - t) * (c[1] - p0[1]) + 2 * t * (p1[1] - c[1])
    n = math.hypot(dx, dy) or 1
    return (-dy / n, dx / n)


def qlen(p0, c, p1):
    pts = [qpt(p0, c, p1, i / 20) for i in range(21)]
    return sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(pts, pts[1:]))


def poly(pts):
    return 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)


def stroke(d, color, w, extra=''):
    return f'<path d="{d}" stroke="{color}" stroke-width="{f(w)}" fill="none" stroke-linecap="round" stroke-linejoin="round"{extra}/>'


def offset_q(p0, c, p1, off, n=24, t0=0.0, t1=1.0):
    out = []
    for i in range(n + 1):
        t = t0 + (t1 - t0) * i / n
        x, y = qpt(p0, c, p1, t)
        nx, ny = qnorm(p0, c, p1, t)
        out.append((x + nx * off, y + ny * off))
    return out


def core_q(p0, c, p1, w, ridges=0, color=CORE):
    """One insulated core along a quadratic: black body, a shine line, and
    [ridges] (0–3) raised ridge lines along it (the phase mark, pro tip 2)."""
    o = [stroke(poly(offset_q(p0, c, p1, 0)), color, w)]
    o.append(stroke(poly(offset_q(p0, c, p1, -w * 0.28, t0=0.04, t1=0.96)), CORE_HI, max(0.6, w * 0.14)))
    offs = {1: [0.0], 2: [-0.17, 0.17], 3: [-0.26, 0.0, 0.26]}.get(ridges, [])
    for k in offs:
        o.append(stroke(poly(offset_q(p0, c, p1, w * k + w * 0.08, t0=0.03, t1=0.97)), RIDGE, max(0.6, w * 0.1)))
    return ''.join(o)


def messenger_q(p0, c, p1, w, insulated=False):
    """The neutral-cum-messenger: bare aluminium (strand lay drawn), or
    insulated and of a different size (thicker, smooth)."""
    if insulated:
        return core_q(p0, c, p1, w * 1.45, 0)
    o = [stroke(poly(offset_q(p0, c, p1, 0)), ALU_D, w + 1.0), stroke(poly(offset_q(p0, c, p1, 0)), ALU, w)]
    o.append(stroke(poly(offset_q(p0, c, p1, 0)), ALU_D, max(0.5, w * 0.14), f' stroke-dasharray="{f(w * 0.6)} {f(w * 0.9)}"'))
    return ''.join(o)


def bundle(p0, c, p1, r=4.0, w=3.6, cores=3, msg='bare', pitch=None, tail_caps=True):
    """Insulated cores twisted round a messenger along a quadratic. msg is
    'bare', 'insul' or None (no messenger: the cores twist round nothing).
    Back halves of the twist are drawn first, then the messenger, then the
    front halves."""
    length = qlen(p0, c, p1)
    pitch = pitch or max(10.0, r * 4.2)
    turns = length / pitch
    n = max(24, int(turns * 18))
    back, front = [], []
    for i in range(cores):
        ph = 2 * math.pi * i / cores
        run, run_front = [], None
        for k in range(n + 1):
            t = k / n
            a = 2 * math.pi * turns * t + ph
            x, y = qpt(p0, c, p1, t)
            nx, ny = qnorm(p0, c, p1, t)
            pt = (x + nx * r * math.sin(a), y + ny * r * math.sin(a))
            is_front = math.cos(a) >= 0
            if run_front is None:
                run_front = is_front
            if is_front != run_front:
                run.append(pt)
                (front if run_front else back).append(run)
                run, run_front = [pt], is_front
            else:
                run.append(pt)
        if len(run) > 1:
            (front if run_front else back).append(run)
    o = []
    for run in back:
        o.append(stroke(poly(run), CORE, w))
    if msg == 'bare':
        o.append(messenger_q(p0, c, p1, w * 0.95))
    elif msg == 'insul':
        o.append(stroke(poly(offset_q(p0, c, p1, 0, n=max(24, n // 2))), CORE, w * 1.45))
        o.append(stroke(poly(offset_q(p0, c, p1, -w * 0.4, n=max(24, n // 2), t0=0.02, t1=0.98)), CORE_HI, max(0.6, w * 0.18)))
    for run in front:
        o.append(stroke(poly(run), CORE, w))
        if len(run) > 2:
            o.append(stroke(poly(run[1:-1]), CORE_HI, max(0.5, w * 0.22)))
    return ''.join(o)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def sun(x=168, y=30):
    return (f'<circle cx="{x}" cy="{y}" r="20" fill="url(#glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="8" fill="{SUN}"/>')


def cloud(x, y, s=1.0, color='#FFFFFF', op=0.75):
    return (f'<g fill="{color}" opacity="{op}"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(16 * s)}" ry="{f(6 * s)}"/>'
            f'<ellipse cx="{f(x + 8 * s)}" cy="{f(y - 4 * s)}" rx="{f(9 * s)}" ry="{f(6 * s)}"/></g>')


def tree(x, y, s=1.0):
    return (f'<rect x="{f(x - 2 * s)}" y="{f(y - 10 * s)}" width="{f(4 * s)}" height="{f(12 * s)}" fill="{TREE_D}"/>'
            f'<circle cx="{f(x)}" cy="{f(y - 18 * s)}" r="{f(11 * s)}" fill="{TREE}"/>'
            f'<circle cx="{f(x + 6 * s)}" cy="{f(y - 13 * s)}" r="{f(7 * s)}" fill="{TREE_D}"/>')


def house(x, y, s=1.0):
    return (f'<rect x="{f(x)}" y="{f(y - 22 * s)}" width="{f(30 * s)}" height="{f(22 * s)}" fill="url(#house)"/>'
            f'<path d="M{f(x - 3 * s)} {f(y - 22 * s)} L{f(x + 15 * s)} {f(y - 34 * s)} L{f(x + 33 * s)} {f(y - 22 * s)} Z" fill="url(#roof)"/>'
            f'<rect x="{f(x + 11 * s)}" y="{f(y - 12 * s)}" width="{f(8 * s)}" height="{f(12 * s)}" fill="{INK}"/>')


def motion(x, y, dx=0, dy=-1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def bracket(x0, y, x1, w=4):
    """A steel pole bracket (arm) from the pole face out to x1."""
    return f'<rect x="{f(min(x0, x1))}" y="{f(y - w / 2)}" width="{f(abs(x1 - x0))}" height="{f(w)}" rx="1" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>'


def susp_clamp(x, y, top, s=1.0, tilt=0):
    """A suspension clamp: a link down from the bracket at [top], a saddle
    cradling the messenger at (x, y)."""
    g = [stroke(f'M{f(x)} {f(top)} L{f(x)} {f(y - 5 * s)}', INK, 1.4 * s),
         f'<path d="M{f(x - 8 * s)} {f(y - 2 * s)} Q{f(x)} {f(y + 7 * s)} {f(x + 8 * s)} {f(y - 2 * s)} L{f(x + 6 * s)} {f(y - 6 * s)} L{f(x - 6 * s)} {f(y - 6 * s)} Z" '
         f'fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>',
         f'<circle cx="{f(x)}" cy="{f(y - 5 * s)}" r="{f(1.6 * s)}" fill="{INK}"/>']
    body = ''.join(g)
    if tilt:
        return f'<g transform="rotate({f(tilt)} {f(x)} {f(top)})">{body}</g>'
    return body


def tension_clamp(eye, tip, s=1.0):
    """A tension (anchoring) clamp: a bail from the pole's eye hook, then a
    tapered wedge body along the messenger from [eye] side to [tip]."""
    ex, ey = eye
    tx, ty = tip
    dx, dy = tx - ex, ty - ey
    n = math.hypot(dx, dy) or 1
    ux, uy = dx / n, dy / n
    px, py = -uy, ux
    bx, by = ex + ux * 6 * s, ey + uy * 6 * s   # body start
    wide, thin = 4.2 * s, 1.8 * s
    body = (f'<path d="M{f(bx + px * wide)} {f(by + py * wide)} L{f(tx + px * thin)} {f(ty + py * thin)} '
            f'L{f(tx - px * thin)} {f(ty - py * thin)} L{f(bx - px * wide)} {f(by - py * wide)} Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    bail = stroke(f'M{f(ex)} {f(ey)} L{f(bx)} {f(by)}', INK, 1.6 * s)
    eye_c = f'<circle cx="{f(ex)}" cy="{f(ey)}" r="{f(2 * s)}" fill="none" stroke="{INK}" stroke-width="{f(1.2 * s)}"/>'
    return eye_c + bail + body


def stay(x_top, y_top, x_anchor):
    return (stroke(f'M{f(x_top)} {f(y_top)} L{f(x_anchor)} {f(GY + 2)}', WIRE, 1.2)
            + f'<rect x="{f(x_anchor - 4)}" y="{f(GY - 1)}" width="8" height="4" rx="1" fill="url(#steel)"/>')


def ground(road=False):
    o = [f'<rect x="0" y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>']
    if road:
        o.append(f'<path d="M0 {GY + 6} L{W} {GY + 2} L{W} {H} L0 {H} Z" fill="url(#road)"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — bundle: which line is an AB cable.
# --------------------------------------------------------------------------

def bundle_card(kind):
    out = card_open('day')
    out += [sun(), cloud(120, 26, 1.1), tree(164, GY, 1.3), house(118, GY, 1.0), ground()]
    PX = 34
    out.append(pole(PX, 40))
    if kind in ('bare', 'insul', 'nomsg'):
        msg = {'bare': 'bare', 'insul': 'insul', 'nomsg': None}[kind]
        out.append(bracket(PX + 4, 52, PX + 20))
        cx, cy = PX + 18, 64
        out.append(bundle((-12, 74), (14, 76), (cx, cy), r=4.4, w=3.8, msg=msg))
        out.append(bundle((cx, cy), (118, 108), (214, 92), r=4.4, w=3.8, msg=msg))
        out.append(susp_clamp(cx, cy, 52))
    else:
        # a cross-arm with four pin insulators
        out.append(f'<rect x="8" y="52" width="56" height="5" rx="1" fill="url(#steel)" stroke="{INK}" stroke-width="0.5"/>')
        xs = (12, 24, 44, 58)
        for i, x in enumerate(xs):
            out.append(f'<rect x="{x - 3}" y="44" width="6" height="8" rx="2" fill="url(#ceramic)"/>')
            y0 = 44
            end_y = 82 + i * 9
            if kind == 'open':
                out.append(stroke(f'M{x} {y0} Q{(x + 214) / 2} {end_y + 18} 214 {end_y}', ALU_D, 2.6))
                out.append(stroke(f'M{x} {y0} Q{(x + 214) / 2} {end_y + 18} 214 {end_y}', ALU, 1.6))
                out.append(stroke(f'M{x} {y0} Q{x / 2 - 4} {y0 + 6} -10 {y0 + 4 + i * 3}', ALU, 1.6))
            else:
                p0, c, p1 = (x, y0), ((x + 214) / 2, end_y + 18), (214, end_y)
                out.append(core_q(p0, c, p1, 3.4))
                out.append(core_q((x, y0), (x / 2 - 4, y0 + 6), (-10, y0 + 4 + i * 3), 3.4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — grip: which conductor the clamp's jaw holds.
# --------------------------------------------------------------------------

def grip_card(kind):
    out = card_open('near')
    out.append(cloud(150, 30, 1.2))
    out.append(f'<rect x="-6" y="0" width="30" height="{H}" fill="url(#pole)"/>')
    out.append(bracket(24, 40, 100, 7))
    JX, JY = 92, 73
    left0, left1 = (-12, 92), (54, 84)
    right0, right1 = (130, 84), (214, 96)
    if kind == 'all':
        # the whole bundle squeezed in one big clamp
        out.append(bundle((-12, 96), (92, 60), (214, 96), r=6.5, w=6, msg='bare', pitch=26))
        out.append(stroke(f'M{JX} 44 L{JX} 66', INK, 2.2))
        out.append(f'<rect x="{JX - 15}" y="{JY - 10}" width="30" height="22" rx="5" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<circle cx="{JX - 9}" cy="{JY + 1}" r="2.2" fill="{INK}"/><circle cx="{JX + 9}" cy="{JY + 1}" r="2.2" fill="{INK}"/>')
        return card_close(out)
    gripped = {'bare': 'msg', 'mark': 'insul', 'r1': 1, 'r3': 3}[kind]
    msg = 'insul' if kind == 'mark' else 'bare'
    out.append(bundle(left0, (20, 90), left1, r=6.5, w=6, msg=msg, pitch=26))
    out.append(bundle(right0, (170, 84), right1, r=6.5, w=6, msg=msg, pitch=26))
    loops = [x for x in ('msg', 1, 2, 3) if x != gripped and not (gripped == 'insul' and x == 'msg')]
    for i, which in enumerate(loops):
        c = (92, 104 + i * 12)
        if which == 'msg':
            out.append(messenger_q(left1, c, right0, 5.4))
        else:
            out.append(core_q(left1, c, right0, 6.2, which))
    # the gripped conductor runs up through the jaw
    c = (92, 62)
    if gripped == 'msg':
        out.append(messenger_q(left1, c, right0, 5.4))
    elif gripped == 'insul':
        out.append(core_q(left1, c, right0, 8.6, 0))
    else:
        out.append(core_q(left1, c, right0, 6.2, gripped))
    out.append(stroke(f'M{JX} 44 L{JX} 66', INK, 2.2))
    out.append(f'<path d="M{JX - 13} {JY - 3} Q{JX} {JY + 12} {JX + 13} {JY - 3} L{JX + 10} {JY - 9} L{JX - 10} {JY - 9} Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<circle cx="{JX}" cy="{JY - 8}" r="2.4" fill="{INK}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — pole: suspension on a straight run, tension at an end or a turn.
# --------------------------------------------------------------------------

def pole_card(kind):
    out = card_open('day')
    out += [sun(30, 28), cloud(150, 24), tree(176, GY, 1.1), tree(22, GY, 0.9), ground()]
    PX = 100
    bw = dict(r=2.4, w=2.2)
    if kind in ('end', 'turn', 'endsus', 'turnsus'):
        out.append(stay(PX - 2, 46, 40))
    out.append(pole(PX, 36))
    if kind in ('straight', 'bolt'):
        out.append(bracket(PX + 4, 52, PX + 16))
        cx, cy = PX + 14, 62
        out.append(bundle((-12, 70), (50, 86), (cx, cy), **bw))
        out.append(bundle((cx, cy), (166, 86), (214, 70), **bw))
        if kind == 'straight':
            out.append(susp_clamp(cx, cy, 52))
        else:
            # an ordinary bolted bare-line clamp biting the insulation
            out.append(stroke(f'M{cx} 52 L{cx} 56', INK, 1.4))
            out.append(f'<rect x="{cx - 9}" y="{cy - 6}" width="18" height="11" rx="1.5" fill="url(#steel)" stroke="{INK}" stroke-width="0.7"/>')
            out.append(f'<circle cx="{cx - 4.5}" cy="{cy - 0.5}" r="2" fill="{INK}"/><circle cx="{cx + 4.5}" cy="{cy - 0.5}" r="2" fill="{INK}"/>')
            for dx in (-12, 11):
                out.append(f'<path d="M{cx + dx} {cy - 2} l2.5 -1 l1.5 3 l-2.5 1.5 Z" fill="{ALU}"/>')
            out.append(f'<path d="M{cx - 6} {cy + 9} l2 3 M{cx + 3} {cy + 10} l-1 4" stroke="{CORE}" stroke-width="1.6" stroke-linecap="round"/>')
    elif kind == 'end':
        out.append(tension_clamp((PX + 5, 56), (PX + 26, 61)))
        out.append(bundle((PX + 26, 61), (160, 72), (214, 68), **bw))
        out.append(bundle((PX + 8, 58), (PX + 18, 76), (PX + 6, 96), r=2.0, w=2.0))
    elif kind == 'turn':
        out.append(tension_clamp((PX + 5, 56), (PX + 26, 61)))
        out.append(bundle((PX + 26, 61), (160, 72), (214, 68), **bw))
        out.append(tension_clamp((PX - 5, 58), (PX - 22, 70)))
        out.append(bundle((PX - 22, 70), (40, 104), (-14, 168), r=3.6, w=3.4))
        out.append(bundle((PX + 8, 58), (PX, 84), (PX - 8, 61), r=1.8, w=1.8))
    elif kind == 'endsus':
        out.append(bracket(PX + 4, 52, PX + 16))
        cx, cy = PX + 14, 62
        out.append(susp_clamp(cx, cy, 52))
        out.append(bundle((cx, cy), (150, 136), (214, 74), **bw))
        out.append(bundle((cx - 2, cy + 1), (PX + 4, 76), (PX + 4, 96), r=2.0, w=2.0))
        out.append(motion(PX - 4, 96, 0, 1, 3, 7))
    elif kind == 'turnsus':
        out.append(bracket(PX + 4, 52, PX + 16))
        cx, cy = PX + 12, 63
        out.append(susp_clamp(cx, cy, 52, tilt=24))
        out.append(bundle((cx - 3, cy), (160, 112), (214, 72), **bw))
        out.append(bundle((cx - 3, cy), (60, 136), (-14, 172), r=3.6, w=3.4))
        out.append(motion(cx - 20, cy + 6, -1, 0.4, 3, 7))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — ipc: the service joint.
# --------------------------------------------------------------------------

def ipc_outside(kind):
    out = card_open('near')
    out.append(cloud(40, 26, 1.1))
    out.append(house(150, 206, 1.2))
    a0, a1 = (-12, 60), (40, 66)
    b0, b1 = (160, 66), (214, 60)
    out.append(bundle(a0, (14, 64), a1, r=7, w=6.2, msg='bare', pitch=28))
    out.append(bundle(b0, (186, 64), b1, r=7, w=6.2, msg='bare', pitch=28))
    out.append(bundle(a1, (100, 70), b0, r=5, w=6.2, cores=2, msg='bare', pitch=28))
    cc = (100, 108)
    if kind == 'twist':
        # insulation cut off a stretch of the core; the service wire's bared
        # end wound round it
        out.append(core_q(a1, cc, b0, 8, 2))
        out.append(stroke('M86 85.5 Q100 89 114 85.5', ALU, 7.4))
        for i in range(5):
            x = 88 + i * 6
            out.append(stroke(f'M{x} 80 Q{x + 3} 87 {x + 1} 93', ALU_D, 2.2))
        out.append(core_q((112, 94), (130, 140), (170, 196), 6, 0))
        out.append(stroke('M106 90 Q110 94 112 95', ALU, 2.6))
        out.append(arms(((78, 104), (124, 112)), gloves=True))
        return card_close(out)
    out.append(core_q(a1, cc, b0, 8, 2))
    # the service cable leaves the connector for the house
    out.append(core_q((108, 100), (128, 146), (170, 196), 6, 0))
    if kind == 'bolt':
        # a bare-line bolted connector (steel block, two bolts)
        out.append(f'<rect x="84" y="80" width="32" height="20" rx="2" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<circle cx="92" cy="90" r="3.2" fill="{INK}"/><circle cx="108" cy="90" r="3.2" fill="{INK}"/>')
        out.append(arms(((126, 96), (70, 110)), gloves=True, side=1))
        return card_close(out)
    # the IPC: black body round the core, its bolt on top
    out.append(f'<rect x="82" y="78" width="36" height="28" rx="6" fill="{IPC_C}" stroke="{CORE}" stroke-width="1"/>')
    out.append(f'<path d="M86 84 h28 M86 100 h28" stroke="{CORE_HI}" stroke-width="0.8"/>')
    out.append(f'<rect x="97" y="70" width="6" height="9" fill="url(#steel)"/>')
    out.append(f'<path d="M93 66 h14 l2 4 h-18 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    # sheared: the head broke off, falling away
    out.append(f'<path d="M136 120 h10 l1.6 4 h-13.2 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6" transform="rotate(28 141 122)"/>')
    out.append(motion(141, 112, 0, -1, 3, 7))
    out.append(arms(((112, 62), (70, 120)), gloves=True))
    return card_close(out)


def ipc_cutaway(kind):
    """The IPC cut open across the core (left) and the service conductor
    (right): XLPE ring, aluminium strands, brass teeth from both jaws."""
    out = card_open('near')
    out.append(cloud(40, 26, 1.1))
    deep = kind == 'teeth'
    # jaws
    out.append(f'<rect x="28" y="64" width="150" height="24" rx="6" fill="{IPC_C}" stroke="{CORE}" stroke-width="1"/>')
    out.append(f'<rect x="28" y="150" width="150" height="24" rx="6" fill="{IPC_C}" stroke="{CORE}" stroke-width="1"/>')
    for cx, R, r in ((74, 32, 20), (144, 22, 13)):
        out.append(f'<circle cx="{cx}" cy="119" r="{R}" fill="{CORE}"/>')
        out.append(f'<circle cx="{cx}" cy="119" r="{R - 3}" fill="none" stroke="{CORE_HI}" stroke-width="0.8"/>')
        out.append(f'<circle cx="{cx}" cy="119" r="{r}" fill="{ALU}"/>')
        for k in range(7):
            a = 2 * math.pi * k / 7
            out.append(f'<circle cx="{f(cx + math.cos(a) * r * 0.55)}" cy="{f(119 + math.sin(a) * r * 0.55)}" r="{f(r * 0.32)}" fill="none" stroke="{ALU_D}" stroke-width="0.8"/>')
        out.append(f'<circle cx="{cx}" cy="119" r="{f(r * 0.32)}" fill="none" stroke="{ALU_D}" stroke-width="0.8"/>')
        tip = (R - r) * (0.1 if deep else 0.75) + r - (6 if deep else 0)
        for side in (-1, 1):
            base = 119 + side * (R + 2)
            for dx in (-7, 0, 7):
                tip_y = 119 + side * (tip if dx == 0 else tip + 2)
                out.append(f'<path d="M{f(cx + dx - 3)} {f(base)} L{f(cx + dx)} {f(tip_y)} L{f(cx + dx + 3)} {f(base)} Z" fill="{TOOTH}" stroke="{INK}" stroke-width="0.5"/>')
    # the bolt through the jaws, at the right
    out.append(f'<rect x="183" y="58" width="6" height="122" fill="url(#steel)"/>')
    out.append(f'<path d="M179 52 h14 l2 6 h-18 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    if not deep:
        # the shear head still on, never tightened home
        out.append(f'<path d="M180 44 h12 l1.5 8 h-15 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<path d="M179 180 h14 l2 6 h-18 Z" fill="url(#steel)" stroke="{INK}" stroke-width="0.6"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — care: pulling and repairing the insulation.
# --------------------------------------------------------------------------

def drum(x, y):
    return (f'<ellipse cx="{x}" cy="{y}" rx="9" ry="22" fill="url(#drum)"/>'
            f'<rect x="{x}" y="{y - 14}" width="20" height="28" fill="{CORE}"/>'
            f'<path d="M{x + 3} {y - 14} v28 M{x + 9} {y - 14} v28 M{x + 15} {y - 14} v28" stroke="{CORE_HI}" stroke-width="0.8"/>'
            f'<ellipse cx="{x + 20}" cy="{y}" rx="9" ry="22" fill="url(#drum)"/>'
            f'<circle cx="{x + 20}" cy="{y}" r="3" fill="{WIRE}"/>'
            f'<path d="M{x + 10} {y + 22} L{x + 4} {GY} M{x + 10} {y + 22} L{x + 18} {GY}" stroke="{WIRE}" stroke-width="2"/>')


def care_wide(kind):
    out = card_open('day')
    out += [sun(170, 26), cloud(60, 22), ground(road=True)]
    PX = 134
    out.append(pole(PX, 34))
    out.append(bracket(PX + 4, 50, PX + 20))
    out.append(drum(20, 168))
    out.append(bundle((214, 70), (184, 54), (PX + 18, 56), r=2.4, w=2.2))
    if kind == 'roller':
        # a cable roller hung on the bracket; the cable runs over it
        rx, ry = PX + 18, 62
        out.append(stroke(f'M{rx} 50 L{rx} {ry - 8}', INK, 1.4))
        out.append(f'<circle cx="{rx}" cy="{ry}" r="8" fill="url(#steel)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<circle cx="{rx}" cy="{ry}" r="2.4" fill="{WIRE}"/>')
        out.append(bundle((PX + 12, 57), (80, 92), (46, 156), r=2.4, w=2.2))
        out.append(person(76, ((60, 150), (66, 144)), face=-1, look=-10))
        out.append(motion(100, 100, 1, -0.6, 3, 7))
    else:
        # no roller: over the bare bracket end, along the stony road
        out.append(bundle((PX + 18, 52), (120, 120), (90, 202), r=2.4, w=2.2))
        out.append(bundle((90, 202), (60, 206), (40, 168), r=2.4, w=2.2))
        for x, y in ((70, 206), (98, 210), (112, 204), (128, 212), (52, 212)):
            out.append(f'<ellipse cx="{x}" cy="{y}" rx="5" ry="2.6" fill="{STONE}"/>')
        for x, y in ((PX + 15, 54), (94, 199), (106, 186)):
            out.append(f'<path d="M{x - 2} {y - 1} l3 -1.5 l1.5 2.5 l-3 1.5 Z" fill="{ALU}"/>')
        out.append(person(176, ((160, 168), (166, 164)), face=-1, look=-6))
        out.append(motion(118, 150, 0.4, -1, 3, 7))
    return card_close(out)


def care_close(kind):
    out = card_open('day')
    out.append(cloud(150, 28, 1.2, CLOUD_D if kind == 'open' else '#FFFFFF', 0.9 if kind == 'open' else 0.75))
    # the rest of the bundle above, the big phase core in front
    out.append(bundle((-12, 66), (100, 58), (214, 66), r=6, w=6, cores=2, msg='bare', pitch=30))
    p0, c, p1 = (-12, 108), (100, 98), (214, 108)
    out.append(core_q(p0, c, p1, 24, 1))
    nick = '<path d="M95 99 l6 -9 l6 9 l-6 2 Z" fill="{}"/>'.format(ALU)
    if kind == 'tape':
        for i in range(7):
            x = 78 + i * 7
            out.append(f'<path d="M{x} 89 l8 0 l-3 22 l-8 0 Z" fill="{TAPE}" stroke="{CORE}" stroke-width="0.5"/>')
            out.append(stroke(f'M{x + 3} 91 l-2 15', CORE_HI, 0.8))
        out.append(f'<circle cx="138" cy="126" r="11" fill="none" stroke="{TAPE}" stroke-width="6"/>')
        out.append(arms(((138, 128), (72, 118)), gloves=True))
    elif kind == 'shrink':
        out.append(f'<path d="M72 90 Q76 86 82 86 L118 86 Q124 86 128 90 L128 110 Q124 114 118 114 L82 114 Q76 114 72 110 Z" fill="{CORE}" stroke="{CORE_HI}" stroke-width="1"/>')
        out.append(stroke('M80 91 L120 91', CORE_HI, 1.6))
        out.append(arms(((134, 118),), gloves=True))
    elif kind == 'open':
        out.append(nick)
        for x, y in ((30, 40), (60, 60), (84, 34), (120, 52), (150, 70), (176, 44), (44, 132), (140, 140), (170, 160), (70, 170)):
            out.append(stroke(f'M{x} {y} l-3 9', RAIN, 1.6))
        out.append(f'<path d="M101 80 q-3 4 0 6 q3 -2 0 -6 Z" fill="{RAIN}"/>')
    elif kind == 'bare':
        for i in range(4):
            x = 90 + i * 7
            out.append(f'<path d="M{x} 89 l8 0 l-3 22 l-8 0 Z" fill="{TAPE}" stroke="{CORE}" stroke-width="0.5"/>')
            out.append(stroke(f'M{x + 3} 91 l-2 15', CORE_HI, 0.8))
        out.append(f'<circle cx="138" cy="126" r="11" fill="none" stroke="{TAPE}" stroke-width="6"/>')
        out.append(arms(((138, 128), (72, 118)), gloves=False))
    return card_close(out)


CARDS = {}
for k in ('bare', 'insul', 'open', 'apart', 'nomsg'):
    CARDS[f'bundle_{k}'] = bundle_card(k)
for k in ('bare', 'mark', 'r1', 'r3', 'all'):
    CARDS[f'grip_{k}'] = grip_card(k)
for k in ('straight', 'end', 'turn', 'endsus', 'turnsus', 'bolt'):
    CARDS[f'pole_{k}'] = pole_card(k)
for k in ('sheared', 'twist', 'bolt'):
    CARDS[f'ipc_{k}'] = ipc_outside(k)
for k in ('teeth', 'head'):
    CARDS[f'ipc_{k}'] = ipc_cutaway(k)
for k in ('roller', 'drag'):
    CARDS[f'care_{k}'] = care_wide(k)
for k in ('tape', 'shrink', 'open', 'bare'):
    CARDS[f'care_{k}'] = care_close(k)

# Safe cards and traps per round (mirrors learn_board_pack66.dart).
ROUNDS = {
    'bundle': (['bundle_bare', 'bundle_insul'], ['bundle_open', 'bundle_apart', 'bundle_nomsg']),
    'grip': (['grip_bare', 'grip_mark'], ['grip_r1', 'grip_r3', 'grip_all']),
    'pole': (['pole_straight', 'pole_end', 'pole_turn'], ['pole_endsus', 'pole_turnsus', 'pole_bolt']),
    'ipc': (['ipc_sheared', 'ipc_teeth'], ['ipc_head', 'ipc_twist', 'ipc_bolt']),
    'care': (['care_roller', 'care_tape', 'care_shrink'], ['care_drag', 'care_open', 'care_bare']),
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
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old[:-4] not in CARDS:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
