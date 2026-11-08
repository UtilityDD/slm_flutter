"""Picture cards for ladder step 16 (lesson 1.6 শেখা, "পারমিট-টু-ওয়ার্ক").

python -I tool/ptw_board_art.py .

Writes assets/game/art/ptw_board/*.svg in the same clean gradient style as
tool/pole_board_art.py, tool/harness_board_art.py and tool/rod_board_art.py
(200 x 220 scene cards, drawn edge to edge). The only writing in the art is
what a worker reads on the job: the PTW form's fields (Permit No., Feeder,
Validity, Isolation, Signature — the lesson's own field names), a watch, the
ON / OFF marks and feeder plate on a breaker, the LOTO tag, and the feeder
plate on a pole. Feeder names and permit numbers are made-up examples.

What the cards show comes from lesson 1.6 only:
  1. the form: work starts only on a valid PTW signed by hand ("হাতে
     স্বাক্ষরিত PTW ছাড়া কাজ শুরু করবেন না"); every permit has a set
     validity — past it, stop and take a new permit; the operator issues the
     PTW with a unique permit number;
  2. the golden steps at the control room: the operator isolates the feeder,
     Breaker OFF, then LOTO — a physical lock so nobody can switch it on by
     mistake, and a tag on the lock saying why it is locked and whose
     permission is needed to open it;
  3. match the feeder name on the PTW with the feeder you work on (the
     feeder plate on the pole);
  4. a phone or spoken "line is off" has no legal or safety basis — the
     signed PTW in hand; after receiving the permit the team discharges and
     tests the line dead before work (one step, as the lesson lists it);
  5. line clear: everyone down from the line, all tools removed, the
     supervisor phones the control room to return the permit; leaving the
     field without returning it is a serious offence.

Fairness (the playbook, section 4, and the step-10 / step-13 / step-16
reviews): every card in a round shares one backdrop and one palette — only
what the form says, what hangs on the breaker and what the team does tell
the safe card from a trap. In the start round two traps stay on the ground
(the phone at the ladder's foot, a test with no PTW), so "nobody climbing"
never marks the safe card; every round has 4 traps so each play leaves a
different one out. `check_fair()` runs the same every-hand check as
test/learn_board_16_test.dart before anything is written.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'ptw_board')
W, H = 200, 220

SHIRT = '#1F5F8F'
PANTS = '#2A3442'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
WIRE = '#2B3138'
GRIP = '#2A2D33'
COPPER = '#C26A2E'
INK = '#1B2430'
PEN = '#1F4E9A'      # the ballpoint the form is filled in with
LABEL = '#5A6470'
RULE = '#C9D0D6'
DANGER = '#C62828'   # LOTO padlock body and the tag's header
LCD = '#9BE38A'
FONT = 'font-family="sans-serif"'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="fibre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F7A15A"/><stop offset="0.35" stop-color="#FFC48A"/><stop offset="1" stop-color="#C9561A"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="strip" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8F989F"/><stop offset="0.5" stop-color="#D5DADE"/><stop offset="1" stop-color="#848C93"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0A774"/><stop offset="0.5" stop-color="#C26A2E"/><stop offset="1" stop-color="#7E3F16"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9965E"/><stop offset="1" stop-color="#9E6B38"/></linearGradient>
  <linearGradient id="board" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9A6A3C"/><stop offset="1" stop-color="#6E4524"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEFF2"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#DCE2E6"/><stop offset="1" stop-color="#B9C1C7"/></linearGradient>
  <linearGradient id="cabinet" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F7D88"/><stop offset="0.5" stop-color="#8D9AA4"/><stop offset="1" stop-color="#5F6C76"/></linearGradient>
  <linearGradient id="plate" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DDE3E8"/></linearGradient>
  <radialGradient id="knob" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#4A5058"/><stop offset="1" stop-color="#15181C"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def text(x, y, s, size, fill=INK, weight=700, anchor='start', italic=False, extra=''):
    st = ' font-style="italic"' if italic else ''
    return (f'<text x="{f(x)}" y="{f(y)}" {FONT} font-size="{f(size)}" font-weight="{weight}"{st} '
            f'text-anchor="{anchor}" fill="{fill}"{extra}>{s}</text>')


def signature(x, y, s=1.0):
    """A handwritten signature in ballpoint."""
    return (f'<path d="M{f(x)} {f(y)} c{f(4 * s)} {f(-10 * s)} {f(8 * s)} {f(-9 * s)} {f(6 * s)} {f(1 * s)} '
            f's{f(-6 * s)} {f(7 * s)} {f(2 * s)} {f(-2 * s)} {f(8 * s)} {f(-8 * s)} {f(10 * s)} {f(-3 * s)} '
            f'{f(1 * s)} {f(6 * s)} {f(6 * s)} {f(-1 * s)} {f(12 * s)} {f(-6 * s)} {f(14 * s)} {f(-2 * s)} '
            f'{f(2 * s)} {f(5 * s)} {f(8 * s)} {f(2 * s)}" stroke="{PEN}" stroke-width="1.4" fill="none" '
            f'stroke-linecap="round" stroke-linejoin="round"/>')


def clouds(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.9"><ellipse cx="{x}" cy="{y}" rx="{f(22 * s)}" ry="{f(8 * s)}"/>'
            f'<ellipse cx="{f(x + 15 * s)}" cy="{f(y - 6 * s)}" rx="{f(15 * s)}" ry="{f(9 * s)}"/></g>')


def trees(y):
    blobs = ''.join(f'<ellipse cx="{x}" cy="{f(y - r * 0.55)}" rx="{f(r * 1.3)}" ry="{r}"/>'
                    for x, r in [(8, 12), (30, 9), (52, 14), (96, 8), (198, 9)])
    return f'<g fill="#7FA36A" opacity="0.75">{blobs}</g>'


def qpt(p0, p1, p2, t):
    a, b, c = (1 - t) ** 2, 2 * t * (1 - t), t * t
    return (a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1])


# --------------------------------------------------------------------------
# Round 1 — the PTW form on a clipboard, a watch beside it.
# --------------------------------------------------------------------------

def form_rows(x0, y0, w, rows, scale=1.0):
    """[rows] = [(label, value or '' or None for a signature line)]."""
    s = []
    y = y0
    for label, value in rows:
        s.append(text(x0, y, label, 7.8 * scale, LABEL, 600))
        s.append(f'<path d="M{f(x0)} {f(y + 17 * scale)} L{f(x0 + w)} {f(y + 17 * scale)}" stroke="{RULE}" stroke-width="0.9"/>')
        if label == 'Signature':
            if value:
                s.append(signature(x0 + 8 * scale, y + 14 * scale, scale))
        elif value:
            s.append(text(x0 + 1, y + 14.5 * scale, value, (13 if len(value) <= 14 else 10.5) * scale, PEN, 700, italic=True))
        y += 31 * scale
    return ''.join(s)


def clipboard(x, y, w, h, rows, title_size=9.5):
    s = [f'<rect x="{x + 2}" y="{y + 3}" width="{w}" height="{h}" rx="6" fill="#000000" opacity="0.18"/>',
         f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="6" fill="url(#board)"/>',
         f'<rect x="{x + 6}" y="{y + 13}" width="{w - 12}" height="{h - 19}" rx="1.5" fill="url(#paper)"/>',
         f'<rect x="{f(x + w / 2 - 20)}" y="{y - 3}" width="40" height="15" rx="4" fill="url(#steel)" stroke="#7D868E" stroke-width="0.6"/>',
         f'<circle cx="{f(x + w / 2)}" cy="{y + 3}" r="2.6" fill="#7D868E"/>',
         text(x + w / 2, y + 29, 'PERMIT TO WORK', title_size, INK, 800, 'middle'),
         f'<path d="M{x + 12} {y + 34} L{x + w - 12} {y + 34}" stroke="{INK}" stroke-width="1.1"/>',
         form_rows(x + 12, y + 47, w - 24, rows)]
    return ''.join(s)


def watch(cx, cy, time):
    """A digital wristwatch lying on the bench."""
    return (f'<rect x="{cx - 12}" y="{cy - 64}" width="24" height="128" rx="7" fill="{GRIP}"/>'
            + ''.join(f'<circle cx="{cx}" cy="{cy + d}" r="1.5" fill="#15181C"/>' for d in (34, 42, 50))
            + f'<rect x="{cx - 24}" y="{cy - 21}" width="48" height="42" rx="9" fill="url(#steel)" stroke="#7D868E" stroke-width="0.8"/>'
            f'<rect x="{cx - 20}" y="{cy - 14}" width="40" height="28" rx="4" fill="{INK}"/>'
            + text(cx, cy + 5, time, 13.5, LCD, 800, 'middle')
            + f'<rect x="{cx + 24}" y="{cy - 5}" width="2" height="10" rx="1" fill="#7D868E"/>')


def form_card(no, feeder, validity, now, signed=True):
    out = card_open('bench')
    out.append(''.join(f'<path d="M0 {y} Q100 {y + d} 200 {y}" stroke="#8A5A2E" stroke-width="0.8" fill="none" opacity="0.45"/>'
                       for y, d in ((22, 4), (64, -3), (118, 5), (170, -4), (204, 3))))
    out.append(clipboard(8, 12, 138, 200, [
        ('Permit No.', no),
        ('Feeder', feeder),
        ('Validity', validity),
        ('Isolation', 'Breaker OFF + LOTO'),
        ('Signature', signed),
    ]))
    out.append(watch(173, 120, now))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — the breaker in the control room: OFF, then Lock + Tag.
# --------------------------------------------------------------------------

def padlock(cx, top):
    """A LOTO padlock whose shackle top is at [top]; returns (svg, eye)."""
    return (f'<path d="M{cx - 7} {top + 14} L{cx - 7} {top + 7} A7 7 0 0 1 {cx + 7} {top + 7} L{cx + 7} {top + 14}" '
            f'stroke="url(#steel)" stroke-width="3.2" fill="none"/>'
            f'<rect x="{cx - 11}" y="{top + 13}" width="22" height="20" rx="3.5" fill="{DANGER}"/>'
            f'<rect x="{cx - 11}" y="{top + 13}" width="22" height="4" rx="2" fill="#FFFFFF" opacity="0.25"/>'
            f'<circle cx="{cx}" cy="{top + 22}" r="2.4" fill="{INK}"/><rect x="{cx - 1}" y="{top + 22}" width="2" height="6" fill="{INK}"/>'), (cx, top + 4)


def tag(cx, top, ang=0):
    """The LOTO tag on its string from (cx, top)."""
    return (f'<g transform="rotate({ang} {cx} {top})">'
            f'<path d="M{cx} {top} L{cx} {top + 12}" stroke="{INK}" stroke-width="1"/>'
            f'<rect x="{cx - 19}" y="{top + 12}" width="38" height="50" rx="3" fill="url(#paper)" stroke="#9AA5AD" stroke-width="0.6"/>'
            f'<circle cx="{cx}" cy="{top + 16}" r="1.8" fill="none" stroke="{INK}" stroke-width="0.8"/>'
            f'<rect x="{cx - 19}" y="{top + 20}" width="38" height="12" fill="{DANGER}"/>'
            + text(cx, top + 29.5, 'DANGER', 8, '#FFFFFF', 800, 'middle')
            + text(cx, top + 42, 'DO NOT', 7, INK, 800, 'middle')
            + text(cx, top + 51, 'OPERATE', 7, INK, 800, 'middle')
            + f'<path d="M{cx - 13} {top + 57} L{cx + 13} {top + 57}" stroke="{PEN}" stroke-width="1"/></g>')


def breaker_card(feeder, on, lock, tagged, tag_left=False):
    out = card_open('wall')
    out.append(f'<rect y="200" width="{W}" height="20" fill="#8E979E"/>')
    out.append('<rect x="28" y="8" width="144" height="198" rx="5" fill="#000000" opacity="0.15"/>')
    out.append('<rect x="24" y="4" width="144" height="198" rx="5" fill="url(#cabinet)" stroke="#4F5A63" stroke-width="1"/>')
    out.append('<path d="M34 30 L158 30" stroke="#4F5A63" stroke-width="0.8" opacity="0.6"/>')
    for sx in (34, 158):
        out.append(f'<circle cx="{sx}" cy="16" r="2" fill="#4F5A63"/><circle cx="{sx}" cy="192" r="2" fill="#4F5A63"/>')
    # The feeder plate.
    out.append('<rect x="62" y="10" width="68" height="16" rx="2" fill="url(#plate)" stroke="#4F5A63" stroke-width="0.6"/>')
    out.append(text(96, 22, feeder, 10, INK, 800, 'middle'))
    # The control switch: OFF on the left, ON on the right.
    cx, cy = 96, 82
    out.append(text(cx - 34, cy - 30, 'OFF', 11, '#FFFFFF', 800, 'middle'))
    out.append(text(cx + 34, cy - 30, 'ON', 11, '#FFFFFF', 800, 'middle'))
    out.append(f'<path d="M{cx - 22} {cy - 22} l-6 -6 M{cx + 22} {cy - 22} l6 -6" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="24" fill="url(#steel)" stroke="#4F5A63" stroke-width="1"/>')
    ang = 45 if on else -45
    out.append(f'<g transform="rotate({ang} {cx} {cy})"><rect x="{cx - 6}" y="{cy - 30}" width="12" height="46" rx="5" fill="url(#knob)"/>'
               f'<path d="M{cx} {cy - 26} L{cx} {cy - 14}" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/></g>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="5" fill="#15181C"/>')
    # The lock-out hasp under the switch.
    hx, hy = cx, 122
    out.append(f'<rect x="{hx - 16}" y="{hy - 6}" width="32" height="12" rx="2" fill="url(#steel)" stroke="#4F5A63" stroke-width="0.6"/>')
    out.append(f'<circle cx="{hx}" cy="{hy}" r="3" fill="#4F5A63"/>')
    if lock:
        lk, eye = padlock(hx, hy - 3)
        out.append(lk)
        if tagged:
            out.append(tag(hx + (-24 if tag_left else 20), hy + 26, 8 if tag_left else -6))
            out.append(f'<path d="M{hx} {hy + 30} L{hx + (-24 if tag_left else 20)} {hy + 26}" stroke="{INK}" stroke-width="1"/>')
    elif tagged:
        # A tag tied on the switch alone, no padlock through the hasp.
        out.append(f'<path d="M{cx - 4} {cy + 10} Q{cx + 8} {cy + 22} {cx + 20} {hy + 12}" stroke="{INK}" stroke-width="1" fill="none"/>')
        out.append(tag(cx + 20, hy + 12, -4))
    return card_close(out)


# --------------------------------------------------------------------------
# The line: a PCC pole on the right, three conductors running off to the left.
# --------------------------------------------------------------------------

GY = 196
PX = 168
PW = 14
TOP = ((-4, 3), (80, 14), (PX, 4))
FAR = ((-4, 20), (90, 33), (192, 15))
NEAR = ((-4, 36), (66, 52), (146, 33))
STRIP_CLAMP = (PX - PW / 2 + 3, 178)


def near_at(x):
    lo, hi = 0.0, 1.0
    for _ in range(40):
        mid = (lo + hi) / 2
        if qpt(*NEAR, mid)[0] < x:
            lo = mid
        else:
            hi = mid
    return qpt(*NEAR, lo)


def wire(p, w=2.0):
    (x0, y0), (cx, cy), (x1, y1) = p
    return f'<path d="M{x0} {y0} Q{cx} {cy} {x1} {y1}" stroke="{WIRE}" stroke-width="{w}" fill="none"/>'


def insulator(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


def line_scene(clouds_at=None):
    out = card_open('sky')
    for cx, cy, s in clouds_at or [(36, 92, 0.8), (120, 76, 0.7)]:
        out.append(clouds(cx, cy, s))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(trees(GY + 1))
    out.append(wire(FAR, 1.6))
    out.append(insulator(192, 34, 0.85))
    out.append(f'<rect x="{PX - PW / 2}" y="0" width="{PW}" height="{GY + 3}" fill="url(#pole)"/>')
    x = PX - PW / 2 + 0.5
    out.append(f'<rect x="{x}" y="112" width="6" height="{GY - 112 + 4}" fill="url(#strip)"/>'
               + ''.join(f'<circle cx="{x + 3}" cy="{y}" r="1.2" fill="#6F777E"/>' for y in (120, 150, 186)))
    out.append('<path d="M136 56 L204 28 L204 34 L136 62 Z" fill="url(#steelArm)"/>')
    out.append(f'<path d="M{PX} 50 L{PX - 18} 74" stroke="#5F676F" stroke-width="2.4"/>')
    out.append(insulator(PX, 14, 0.85))
    out.append(wire(TOP, 1.8))
    out.append(insulator(146, 52))
    out.append(wire(NEAR, 2.2))
    return out


# --------------------------------------------------------------------------
# The worker, side view facing right ([flip] = facing left).
# --------------------------------------------------------------------------

def _arm(sx, sy, hx, hy, bend=1):
    mx, my = (sx + hx) / 2, (sy + hy) / 2
    dx, dy = hx - sx, hy - sy
    n = math.hypot(dx, dy) or 1
    ex, ey = mx + (-dy / n) * 5 * bend, my + (dx / n) * 5 * bend
    if ey < my:
        ex, ey = mx - (-dy / n) * 5 * bend, my - (dx / n) * 5 * bend
    return (f'<path d="M{f(sx)} {f(sy)} L{f(ex)} {f(ey)} L{f(hx)} {f(hy)}" stroke="{SHIRT}" stroke-width="5.4" '
            f'stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
            f'<circle cx="{f(hx)}" cy="{f(hy)}" r="2.8" fill="{SKIN}"/>')


def worker(fx, gy, hands, pose='stand', props='', front=''):
    """[hands] = (back hand, front hand); [props] between the back arm and
    the body, [front] over the front hand (a phone, a held paper)."""
    g = []
    if pose == 'climb':
        hip, sh, head = (fx, gy - 30), (fx + 2, gy - 56), (fx + 4, gy - 64)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 4} {gy - 1}" stroke="#222B37" stroke-width="7" stroke-linecap="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 9} {gy - 20} L{fx + 6} {gy - 13}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{fx - 9}" y="{gy - 4}" width="10" height="5" rx="2" fill="{BOOT}"/><rect x="{fx + 2}" y="{gy - 16}" width="10" height="5" rx="2" fill="{BOOT}"/>')
    elif pose == 'walk':
        hip, sh, head = (fx, gy - 30), (fx + 3, gy - 56), (fx + 5, gy - 64)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 8} {gy - 14} L{fx - 13} {gy - 3}" stroke="#222B37" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 7} {gy - 15} L{fx + 11} {gy - 2}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{fx - 20}" y="{gy - 6}" width="11" height="5" rx="2" fill="{BOOT}" transform="rotate(-14 {fx - 14} {gy - 3})"/>'
                 f'<rect x="{fx + 6}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/>')
    else:
        hip, sh, head = (fx, gy - 30), (fx + 1, gy - 56), (fx + 3, gy - 64)
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx - 5} {gy - 15} L{fx - 7} {gy - 2}" stroke="#222B37" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{fx + 5} {gy - 15} L{fx + 6} {gy - 2}" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{fx - 13}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/><rect x="{fx + 1}" y="{gy - 4}" width="11" height="5" rx="2" fill="{BOOT}"/>')
    (bx, by), (hx, hy) = hands
    g.append(_arm(sh[0] - 2, sh[1] + 3, bx, by))
    g.append(props)
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy)
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    hx0, hy0 = head
    g.append(f'<rect x="{hx0 - 3}" y="{hy0 + 4}" width="6" height="6" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="{hx0}" cy="{hy0}" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M{hx0 - 7} {hy0 + 1} Q{hx0 - 7} {hy0 + 6} {hx0 - 3} {hy0 + 7} L{hx0 - 3} {hy0 + 1} Z" fill="{HAIR}"/>')
    g.append(f'<path d="M{hx0 - 8} {hy0 - 1} A8 8 0 0 1 {hx0 + 8} {hy0 - 1} Z" fill="{HELMET}"/>'
             f'<rect x="{hx0 - 8}" y="{hy0 - 2.4}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<circle cx="{hx0 + 4}" cy="{hy0 + 1}" r="1.1" fill="{HAIR}"/>')
    g.append(_arm(sh[0] + 1, sh[1] + 3, hx, hy, bend=-1))
    g.append(front)
    return ''.join(g)


def flipped(svg, axis_x):
    return f'<g transform="translate({f(2 * axis_x)} 0) scale(-1 1)">{svg}</g>'


def phone_at(x, y):
    """A mobile phone held to the ear at (x, y)."""
    return (f'<rect x="{f(x - 2.5)}" y="{f(y - 6)}" width="5" height="10" rx="1.3" fill="{BOOT}" transform="rotate(-18 {f(x)} {f(y)})"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 1)}" r="2.6" fill="{SKIN}"/>')


def paper_at(x, y, ang=-10, s=1.0):
    """A held PTW sheet with ballpoint lines and a signature."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({ang}) scale({s})">'
            f'<rect x="-9" y="-11" width="18" height="23" rx="1.5" fill="url(#paper)" stroke="#9AA5AD" stroke-width="0.6"/>'
            f'<path d="M-6 -6 L6 -6" stroke="{INK}" stroke-width="1.2"/>'
            f'<path d="M-6 -1 L5 -1 M-6 3 L6 3" stroke="{PEN}" stroke-width="0.9"/>'
            f'<path d="M-5 8 q2 -4 4 0 t4 -1 t3 0" stroke="{PEN}" stroke-width="0.9" fill="none"/></g>')


def ladder(x0, y0, x1, y1, w=10, rungs=8):
    s = [f'<path d="M{x0} {y0} L{x1} {y1} M{x0 + w} {y0 + 1} L{x1 + w} {y1 + 1}" stroke="#B0B7BD" stroke-width="2.6"/>']
    for i in range(1, rungs + 1):
        t = i / (rungs + 1)
        xa, ya = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        s.append(f'<line x1="{f(xa)}" y1="{f(ya)}" x2="{f(xa + w)}" y2="{f(ya + 1)}" stroke="#B0B7BD" stroke-width="2"/>')
    return ''.join(s)


def lying_ladder(x0=4, x1=110, y=GY + 12):
    s = [f'<path d="M{x0} {y} L{x1} {y - 2} M{x0} {y + 6} L{x1} {y + 4}" stroke="#B0B7BD" stroke-width="2.4"/>']
    for i in range(1, 9):
        xa = x0 + (x1 - x0) * i / 9
        s.append(f'<path d="M{f(xa)} {f(y - 2 * i / 9)} L{f(xa)} {f(y + 6 - 2 * i / 9)}" stroke="#B0B7BD" stroke-width="1.8"/>')
    return ''.join(s)


# --------------------------------------------------------------------------
# The discharge rod and the line tester (both on fibreglass sticks).
# --------------------------------------------------------------------------

def rod_local(L, w):
    s = []
    hw = w / 2
    grip = 3.4 * w
    s.append(f'<rect x="0" y="{f(-hw - 0.6)}" width="{f(grip)}" height="{f(w + 1.2)}" rx="{f(hw)}" fill="{GRIP}"/>')
    s.append(f'<rect x="{f(grip)}" y="{f(-hw)}" width="{f(L - grip - 1.6 * w)}" height="{f(w)}" fill="url(#fibre)"/>')
    hx = L - 1.6 * w
    s.append(f'<rect x="{f(hx)}" y="{f(-hw - 0.8)}" width="{f(1.6 * w)}" height="{f(w + 1.6)}" rx="1.2" fill="url(#steel)" stroke="#6F777E" stroke-width="0.4"/>')
    k = max(w * 0.7, 2.6)
    s.append(f'<path d="M{f(L)} 0 L{f(L + 1.6 * k)} 0 Q{f(L + 3.4 * k)} 0 {f(L + 3.4 * k)} {f(-1.7 * k)} '
             f'Q{f(L + 3.4 * k)} {f(-3.3 * k)} {f(L + 1.8 * k)} {f(-3.3 * k)}" stroke="url(#steel)" stroke-width="{f(max(w * 0.42, 1.8))}" '
             f'fill="none" stroke-linecap="round"/>')
    lug = (hx + 0.6 * w, hw + 0.8)
    s.append(f'<circle cx="{f(lug[0])}" cy="{f(lug[1])}" r="{f(max(w * 0.22, 1))}" fill="#6F777E"/>')
    return ''.join(s), lug


def tester_local(L, w):
    """A line tester head on an insulated stick, its probe at L."""
    hw = w / 2
    grip = 3.4 * w
    return (f'<rect x="0" y="{f(-hw - 0.6)}" width="{f(grip)}" height="{f(w + 1.2)}" rx="{f(hw)}" fill="{GRIP}"/>'
            f'<rect x="{f(grip)}" y="{f(-hw)}" width="{f(L - grip - 5 * w)}" height="{f(w)}" fill="url(#fibre)"/>'
            f'<rect x="{f(L - 5 * w)}" y="{f(-w)}" width="{f(4 * w)}" height="{f(2 * w)}" rx="{f(w * 0.6)}" fill="{GRIP}"/>'
            f'<circle cx="{f(L - 3 * w)}" cy="0" r="{f(w * 0.45)}" fill="#6F777E"/>'
            f'<path d="M{f(L - w)} 0 L{f(L)} 0" stroke="url(#steel)" stroke-width="{f(w * 0.5)}" stroke-linecap="round"/>')


def place(svg, bx, by, ang):
    return f'<g transform="translate({f(bx)} {f(by)}) rotate({f(ang)})">{svg}</g>'


def to_global(pt, bx, by, ang):
    a = math.radians(ang)
    return (bx + pt[0] * math.cos(a) - pt[1] * math.sin(a), by + pt[0] * math.sin(a) + pt[1] * math.cos(a))


def cable(p0, p1, sag=40, w=2.2):
    mx, my = (p0[0] + p1[0]) / 2, max(p0[1], p1[1]) + sag
    d = f'M{f(p0[0])} {f(p0[1])} Q{f(mx)} {f(my)} {f(p1[0])} {f(p1[1])}'
    return (f'<path d="{d}" stroke="#7E3F16" stroke-width="{f(w + 0.8)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{COPPER}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>')


def clamp(x, y, s=1.0, rot=0):
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({rot}) scale({s})">'
            f'<path d="M-3 -7 L7 -7 L7 7 L-3 7" stroke="url(#steel)" stroke-width="2.6" fill="none" stroke-linejoin="round"/>'
            f'<rect x="-6" y="-1.4" width="3.4" height="2.8" fill="#8E979F"/>'
            f'<path d="M7 0 L13 0 M13 -4 L13 4" stroke="#6F777E" stroke-width="2" stroke-linecap="round"/>'
            f'<rect x="-6.5" y="5.5" width="5" height="4" rx="1" fill="url(#copper)"/></g>')


def rod_on_ground(x0=8, x1=96, y=GY + 7):
    """The discharge rod and the tester lying unused on the ground."""
    rsvg, lug = rod_local(x1 - x0, 3.4)
    g = to_global(lug, x0, y, -2)
    tsvg = tester_local(x1 - x0 - 16, 3.0)
    return (place(tsvg, x0 + 6, y + 9, -1) + place(rsvg, x0, y, -2)
            + cable(g, (g[0] + 14, g[1] + 6), sag=4) + clamp(g[0] + 18, g[1] + 7, 0.8, 90))


def rod_hung(x_on=120):
    """The rod hanging on the near phase, its cable clamped to the earth strip."""
    wire_pt = near_at(x_on)
    butt = (wire_pt[0] - 6, wire_pt[1] + 92)
    ang = math.degrees(math.atan2(wire_pt[1] - butt[1], wire_pt[0] - butt[0]))
    k = max(3.6 * 0.7, 2.6)
    L = math.hypot(wire_pt[0] - butt[0], wire_pt[1] - butt[1]) - 3.0 * k
    svg, lug = rod_local(L, 3.6)
    lug = to_global(lug, butt[0], butt[1], ang)
    cp = STRIP_CLAMP
    return cable(lug, (cp[0] - 4, cp[1] + 6), sag=40) + clamp(cp[0], cp[1], 0.9, 180) + place(svg, butt[0], butt[1], ang)


# --------------------------------------------------------------------------
# Round 3 — the feeder name on the PTW vs the feeder plate on the pole.
# --------------------------------------------------------------------------

def feeder_card(on_paper, on_pole):
    out = card_open('sky')
    out.append(clouds(30, 30, 0.8) + clouds(70, 70, 0.6))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(trees(GY + 1))
    out.append('<path d="M-4 16 Q70 30 150 14 M-4 34 Q60 50 150 32" stroke="#2B3138" stroke-width="1.8" fill="none"/>')
    px = 150
    out.append(f'<rect x="{px - 10}" y="0" width="20" height="{GY + 3}" fill="url(#pole)"/>')
    # The feeder plate bolted to the pole.
    out.append(f'<rect x="{px - 2}" y="54" width="4" height="48" fill="#6F777E"/>')
    out.append(f'<rect x="{px - 47}" y="62" width="94" height="40" rx="3" fill="url(#plate)" stroke="{INK}" stroke-width="1.4"/>')
    out.append(text(px, 76, 'FEEDER', 8, LABEL, 800, 'middle'))
    out.append(text(px, 95, on_pole, 13.5, INK, 800, 'middle'))
    for bx in (px - 42, px + 42):
        out.append(f'<circle cx="{bx}" cy="68" r="1.6" fill="#6F777E"/><circle cx="{bx}" cy="96" r="1.6" fill="#6F777E"/>')
    # The PTW held up in the worker's hands, bottom left.
    g = ['<g transform="rotate(-5 60 165)">',
         '<rect x="10" y="110" width="104" height="104" rx="5" fill="url(#board)"/>',
         '<rect x="15" y="121" width="94" height="90" rx="1.5" fill="url(#paper)"/>',
         '<rect x="47" y="106" width="30" height="12" rx="3" fill="url(#steel)" stroke="#7D868E" stroke-width="0.6"/>',
         text(62, 135, 'PERMIT TO WORK', 7.6, INK, 800, 'middle'),
         '<path d="M20 139 L104 139" stroke="#1B2430" stroke-width="1"/>',
         text(21, 151, 'Permit No.', 6.4, LABEL, 600),
         text(70, 151, '0417', 8.5, PEN, 700, italic=True),
         text(21, 166, 'Feeder', 6.6, LABEL, 600),
         text(22, 184, on_paper, 14, PEN, 800, italic=True),
         f'<path d="M21 188 L104 188" stroke="{RULE}" stroke-width="0.9"/>',
         signature(60, 204, 0.8),
         '</g>']
    out.append(''.join(g))
    out.append(f'<path d="M-6 230 L20 196 M130 230 L112 200" stroke="{SHIRT}" stroke-width="10" stroke-linecap="round"/>')
    out.append(f'<circle cx="20" cy="196" r="6" fill="{SKIN}"/><circle cx="112" cy="198" r="6" fill="{SKIN}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — "line is off" on the phone / by mouth vs the signed PTW + test.
# --------------------------------------------------------------------------

def pole_plate():
    """The pole's number plate (every start card; ballpoint-blue digits)."""
    x = PX - PW / 2 + 1
    return (f'<rect x="{f(x)}" y="88" width="12" height="15" rx="1.5" fill="url(#paper)" stroke="{INK}" stroke-width="0.6"/>'
            + text(PX, 99, '17', 7.5, PEN, 800, 'middle'))


def tester_at_line(butt=(40, 166), x_wire=84):
    """A worker on the ground touching the tester's probe to the near phase."""
    wire_pt = near_at(x_wire)
    ang = math.degrees(math.atan2(wire_pt[1] - butt[1], wire_pt[0] - butt[0]))
    L = math.hypot(wire_pt[0] - butt[0], wire_pt[1] - butt[1]) + 1.5
    a = math.radians(ang)
    h1 = (butt[0] + math.cos(a) * 8, butt[1] + math.sin(a) * 8)
    h2 = (butt[0] + math.cos(a) * 28, butt[1] + math.sin(a) * 28)
    return place(tester_local(L, 3.0), butt[0], butt[1], ang) + worker(26, GY, (h1, h2))


def start_card(kind):
    out = line_scene(clouds_at=[(40, 110, 0.8), (100, 140, 0.6)])
    out.append(pole_plate())
    if kind not in ('test_ok', 'no_permit'):
        out.append(ladder(118, GY, 150, 62, 10, 9))
    if kind == 'paper_ok':
        # Reading the signed PTW at chest height, at the foot of the pole.
        out.append(rod_on_ground())
        out.append(worker(82, GY, ((94, 150), (100, 152)), front=paper_at(98, 146, -6, 1.25)))
    elif kind in ('test_ok', 'no_permit'):
        # The rod already on the line, the tester's probe on the near phase;
        # beside him the supervisor holds the signed PTW (safe) or a coworker
        # only shouts that the line is off (trap).
        out.append(rod_hung(126))
        out.append(lying_ladder(4, 92))
        out.append(tester_at_line())
        if kind == 'test_ok':
            out.append(worker(92, GY, ((104, 152), (108, 154)), front=paper_at(108, 148, -6, 1.15)))
        else:
            out.append(worker(92, GY, ((88, 160), (101, 133))))
            out.append('<path d="M106 126 q6 -4 6 -12 M110 130 q10 -6 10 -18" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.9"/>')
    elif kind == 'phone_climb':
        # On the ground at the ladder's foot, a hand on the rail, phone at the ear.
        out.append(rod_on_ground())
        out.append(worker(100, GY, ((128, 150), (108, 136)), front=phone_at(109, 135)))
    elif kind == 'shout_climb':
        out.append(rod_on_ground(8, 70))
        out.append(worker(134, 150, ((150, 82), (150, 100)), 'climb'))
        out.append(worker(84, GY, ((80, 160), (93, 133))))
        out.append('<path d="M98 126 q6 -4 6 -12 M102 130 q10 -6 10 -18" stroke="#FFFFFF" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.9"/>')
    elif kind == 'permit_climb':
        out.append(rod_on_ground())
        out.append(worker(134, 150, ((150, 82), (140, 112)), 'climb', front=paper_at(138, 110, -12)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — line clear: everyone down, tools off, call, return the permit.
# --------------------------------------------------------------------------

def supervisor_on_phone(fx):
    return worker(fx, GY, ((fx + 12, GY - 36), (fx + 6, GY - 64)),
                  props=paper_at(fx + 13, GY - 38, -8), front=phone_at(fx + 7, GY - 64))


def clear_card(kind):
    out = line_scene(clouds_at=[(40, 100, 0.8), (110, 128, 0.6)])
    if kind == 'clear_a':
        out.append(lying_ladder(2, 120))
        out.append(rod_on_ground(10, 110, GY + 2))
        out.append(worker(28, GY, ((24, 168), (36, 168))))
        out.append(worker(56, GY, ((52, 168), (64, 168))))
        out.append(supervisor_on_phone(96))
    elif kind == 'clear_b':
        out.append(lying_ladder(60, 150))
        out.append(rod_on_ground(64, 150, GY + 2))
        out.append(supervisor_on_phone(24))
        out.append(worker(78, GY, ((74, 168), (86, 168))))
        out.append(worker(108, GY, ((104, 168), (116, 168))))
    elif kind == 'worker_up':
        out.append(ladder(118, GY, 150, 62, 10, 9))
        out.append(rod_on_ground(10, 90, GY + 2))
        out.append(worker(134, 120, ((150, 66), (152, 60)), 'climb'))
        out.append(worker(28, GY, ((24, 168), (36, 168))))
        out.append(supervisor_on_phone(70))
    elif kind == 'tool_on':
        out.append(rod_hung(120))
        out.append(lying_ladder(2, 100))
        out.append(worker(24, GY, ((20, 168), (32, 168))))
        out.append(worker(50, GY, ((46, 168), (58, 168))))
        out.append(supervisor_on_phone(80))
    elif kind == 'coming_down':
        # Still on the lower rungs while the supervisor already calls.
        out.append(ladder(118, GY, 150, 62, 10, 9))
        out.append(rod_on_ground(10, 90, GY + 2))
        out.append(worker(120, 186, ((134, 128), (132, 136)), 'climb'))
        out.append(worker(28, GY, ((24, 168), (36, 168))))
        out.append(supervisor_on_phone(70))
    elif kind == 'leave':
        # The team walks off, the permit still in the supervisor's hand.
        team = (lying_ladder(60, 150) + rod_on_ground(64, 150, GY + 2)
                + worker(60, GY, ((54, 168), (68, 168)), 'walk')
                + worker(92, GY, ((86, 168), (100, 168)), 'walk')
                + worker(126, GY, ((118, 170), (134, 160)), 'walk', front=paper_at(136, 156, 8)))
        out.append(flipped(team, 100))
        out.append('<path d="M150 150 l14 0 M146 160 l16 0 M152 170 l12 0" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85"/>')
    return card_close(out)


CARDS = {
    # Round 1 — the form: signed, within validity, numbered.
    'form_ok_a': form_card('0417', 'BAZAR-1', '09:00 – 13:00', '11:20'),
    'form_ok_b': form_card('0582', 'RAMPUR-2', '14:00 – 18:00', '15:45'),
    'form_unsigned': form_card('0631', 'BAZAR-1', '09:00 – 13:00', '10:05', signed=False),
    'form_expired': form_card('0244', 'RAMPUR-2', '08:00 – 11:00', '11:40'),
    'form_no_number': form_card('', 'BAZAR-1', '14:00 – 18:00', '14:30'),
    'form_early': form_card('0739', 'RAMPUR-2', '14:00 – 18:00', '12:35'),
    # Round 2 — the breaker: OFF, then Lock + Tag.
    'loto_ok_a': breaker_card('F-3', on=False, lock=True, tagged=True),
    'loto_ok_b': breaker_card('F-5', on=False, lock=True, tagged=True, tag_left=True),
    'loto_on': breaker_card('F-2', on=True, lock=True, tagged=True),
    'loto_bare': breaker_card('F-3', on=False, lock=False, tagged=False),
    'loto_lock_only': breaker_card('F-5', on=False, lock=True, tagged=False),
    'loto_tag_only': breaker_card('F-4', on=False, lock=False, tagged=True),
    # Round 3 — the PTW's feeder vs the pole's plate.
    'feeder_ok_a': feeder_card('BAZAR-1', 'BAZAR-1'),
    'feeder_ok_b': feeder_card('RAMPUR-2', 'RAMPUR-2'),
    'feeder_near': feeder_card('BAZAR-1', 'BAZAR-11'),
    'feeder_num': feeder_card('RAMPUR-2', 'RAMPUR-3'),
    'feeder_other': feeder_card('HAT-4', 'BAZAR-1'),
    'feeder_long': feeder_card('RAMPUR-12', 'RAMPUR-2'),
    # Round 4 — the written signed PTW, then discharge & test.
    'start_paper': start_card('paper_ok'),
    'start_test': start_card('test_ok'),
    'start_phone': start_card('phone_climb'),
    'start_shout': start_card('shout_climb'),
    'start_permit': start_card('permit_climb'),
    'start_no_permit': start_card('no_permit'),
    # Round 5 — line clear.
    'clear_a': clear_card('clear_a'),
    'clear_b': clear_card('clear_b'),
    'clear_worker_up': clear_card('worker_up'),
    'clear_tool_on': clear_card('tool_on'),
    'clear_leave': clear_card('leave'),
    'clear_coming_down': clear_card('coming_down'),
}

# Which cards are safe in each round (mirrors learn_board_pack16.dart).
ROUNDS = {
    'form': ({'form_ok_a', 'form_ok_b'}, {'form_unsigned', 'form_expired', 'form_no_number', 'form_early'}),
    'loto': ({'loto_ok_a', 'loto_ok_b'}, {'loto_on', 'loto_bare', 'loto_lock_only', 'loto_tag_only'}),
    'feeder': ({'feeder_ok_a', 'feeder_ok_b'}, {'feeder_near', 'feeder_num', 'feeder_other', 'feeder_long'}),
    'start': ({'start_paper', 'start_test'}, {'start_phone', 'start_shout', 'start_permit', 'start_no_permit'}),
    'clear': ({'clear_a', 'clear_b'}, {'clear_worker_up', 'clear_tool_on', 'clear_leave', 'clear_coming_down'}),
}
HAND = 4

TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


# Who is on the ladder in each start / clear card (the step-16 review: the
# start round's safe cards were the only ones with nobody climbing). In every
# hand a trap must share the safe card's pose.
ON_LADDER = {'start_phone': False, 'start_shout': True, 'start_permit': True, 'start_no_permit': False,
             'start_paper': False, 'start_test': False,
             'clear_a': False, 'clear_b': False, 'clear_worker_up': True, 'clear_tool_on': False,
             'clear_leave': False, 'clear_coming_down': True}


def check_fair():
    """Every hand (one safe + HAND-1 traps): the safe card's backdrop is on a
    trap and every colour it draws is drawn by a trap in that hand."""
    def tokens(name):
        return set(TOKEN.findall(CARDS[name].split('</defs>')[-1]))

    bad = []
    for rnd, (safe, traps) in ROUNDS.items():
        for s in sorted(safe):
            for hand in itertools.combinations(sorted(traps), HAND - 1):
                if BACK.search(CARDS[s]).group(1) not in {BACK.search(CARDS[t]).group(1) for t in hand}:
                    bad.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                if s in ON_LADDER and ON_LADDER[s] not in {ON_LADDER[t] for t in hand}:
                    bad.append(f'{rnd}: {s} alone in its pose with {hand}')
                miss = tokens(s) - set().union(*(tokens(t) for t in hand))
                if miss:
                    bad.append(f'{rnd}: {s} with {hand} draws {sorted(miss)} alone')
    return bad


if __name__ == '__main__':
    problems = check_fair()
    if problems:
        print('\n'.join(problems))
        sys.exit(1)
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
