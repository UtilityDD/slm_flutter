"""Picture cards for lesson 5.10 শেখা ("প্রিভেন্টিভ মেইনটেন্যান্স: গোয়েন্দা থেকে ডাক্তার").

python -I tool/m5_board510_art.py .

Writes assets/game/art/m5_board510/*.svg in the clean gradient style of
tool/m4_board41_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 5.10 only:
  1. checklist (the lineman's PM checklist): a visual check of the pole,
     conductor, insulators and hardware; the earthing connections checked;
     branches that have come near the line trimmed. Traps: wiping one
     insulator and packing up (cleaning is only one part — myth 2), walking
     past a branch on the wire, stepping over a broken earth lead. The span
     carries a portable earth at both ends on every card: the PM day is a
     planned shutdown (lesson: 'পরিকল্পিত শাটডাউন'; the earthing rule itself
     is Module 1's);
  2. hidden (hidden loose connections): every joint scanned with a thermal
     camera (the screen shows the three phase joints, one hot — ruling M5-15:
     a joint is judged against the same joint on the other two phases), and
     the hot joint tightened on the shutdown (earth on). Traps: 'it looks
     fine' by eye, the hot joint left for the next PM, the joint wiped shiny;
  3. fixnow (pro tip 1): a loose nut tightened then and there, the rusted
     clamp dealt with on the same visit, a torque wrench on the nut (pro tip
     3). Traps: 'পরে করা যাবে' and leave, a rusty spanner with a pipe, the nut
     done but the rusted clamp left;
  4. record (pro tip 2): the logbook with both the work done and the
     abnormalities found, or the same record in a phone app. Traps: told to
     the supervisor in passing, the abnormality page left blank, a tick
     written without looking (eyes on a video);
  5. report (CBM pro tip): a DTR whose oil has changed colour and that makes
     an odd sound: the lineman phones the deterioration in, or writes it in
     the logbook. Traps: 'আগেও হতো' and walk off, waiting for the next
     scheduled PM, wiping the tank shiny.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; every round has exactly three traps, so each hand the dealer can
make (one safe card + three traps) holds all of them. The script checks every
such hand: each colour or gradient a safe card draws is drawn by a trap in
that hand, and the safe card's backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board510_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board510')
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
COND = '#A9B4BC'
COND_D = '#6F7A82'
BIND = '#DCE3E8'
RUST = '#9A5A2A'
RUST_D = '#6E3B18'
EARTH = '#3E9B4F'
EARTH_Y = '#E8C830'
GI = '#9AA3A9'
HARNESS = '#E8742A'
BAG = '#6B5B3E'
CRACK = '#1E2329'
TOOL = '#D8402F'
MOVE = '#FFFFFF'
LEAF = '#4F8A3C'
LEAF_D = '#3B6E2C'
TRUNK = '#6B4A2E'
RAG = '#EDE6D6'
PIT = '#B9B4A8'
SCREEN = '#1B1035'
COOL = '#4F63D8'
CAM = '#3A3F46'
PAGE = '#F4F1E8'
COVER = '#2F5D50'
INK = '#2B3F8F'
PIPE = '#4A4F57'
OIL = '#4A2A12'
WHITE_HAT = '#F4F7F9'
BUCKET = '#4A6FA5'
SOUND = '#2B3138'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="arm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A949B"/><stop offset="0.5" stop-color="#B7C0C6"/><stop offset="1" stop-color="#6E777E"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8277"/><stop offset="0.5" stop-color="#9AAEA2"/><stop offset="1" stop-color="#5E7066"/></linearGradient>
  <radialGradient id="heat" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE45C"/><stop offset="0.65" stop-color="#F0662A"/><stop offset="1" stop-color="#B0204A" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF6D0"/><stop offset="1" stop-color="#FFF6D0" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='sky', ground=True):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']
    if ground:
        out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    return out


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The worker (copied from tool/m4_board41_art.py): one figure, any pose.
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


def figure(hip, sh, head, feet, hands, face=1, look=0, point=(0, 0), props_front='', props_back=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves."""
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
    g.append(props_back)
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


S = 1.32  # the worker's scale


def _scaled(x, gy, body):
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{body}</g>'


def worker(x, hands_world, face=1, look=0, point=(0, 0), stride=0, props_front='', props_back=''):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    (and the props, drawn in his own frame) are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    hip = (x, GY - 30)
    sh = (x + 1 * face, GY - 56)
    head = (x + 3 * face, GY - 64)
    feet = ((x - (7 + stride) * face, GY - 1), (x + (6 + stride) * face, GY - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, point, props_front, props_back)
    return _scaled(x, GY, fig)


def head_of(x, face=1):
    """Card coordinates of a standing worker's head centre."""
    hx, hy = x + 3 * face, GY - 64
    return (x + (hx - x) * S, GY + (hy - GY) * S)


def kneeler(x, hands, face=1):
    """A worker down on one knee at x."""
    hip = (x, GY - 20)
    sh = (x + 3 * face, GY - 45)
    head = (x + 5 * face, GY - 53)
    feet = ((x - 10 * face, GY - 1), (x + 12 * face, GY - 1))
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    return _scaled(x, GY, figure(hip, sh, head, feet, (local(hands[0]), local(hands[1])), face, 18))


def sitter(x, y_seat, hands, face=1, look=0):
    """A worker sitting on something whose top is at y_seat."""
    hip = (x, y_seat - 4)
    sh = (x + 1 * face, y_seat - 30)
    head = (x + 3 * face, y_seat - 38)
    feet = ((x + 12 * face, GY - 1), (x + 18 * face, GY - 1))
    return figure(hip, sh, head, feet, hands, face, look)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(12 * s)}" fill="url(#spark)"/>'
            f'<g stroke="{MOVE}" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>')


def motion(x, y, dx=0, dy=1, n=3, length=9):
    """Little white swish marks: something moving."""
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def turn_arrow(cx, cy, r, w=1.8):
    a0, a1 = math.radians(-160), math.radians(60)
    p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
    p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
    tx, ty = -math.sin(a1), math.cos(a1)
    nx, ny = -ty, tx
    hl = w * 2.4
    tip = (p1[0] + tx * hl, p1[1] + ty * hl)
    b1 = (p1[0] + nx * hl * 0.8, p1[1] + ny * hl * 0.8)
    b2 = (p1[0] - nx * hl * 0.8, p1[1] - ny * hl * 0.8)
    return (f'<path d="M{f(p0[0])} {f(p0[1])} A{f(r)} {f(r)} 0 1 1 {f(p1[0])} {f(p1[1])}" stroke="{MOVE}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'
            f'<path d="M{f(tip[0])} {f(tip[1])} L{f(b1[0])} {f(b1[1])} L{f(b2[0])} {f(b2[1])} Z" fill="{MOVE}"/>')


def arm(p0, p1, w=12):
    """A forearm in the blue sleeve reaching in from the card edge; a black
    rubber glove at p1."""
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]
    n = math.hypot(dx, dy) or 1
    cuff = (p1[0] - dx / n * 8, p1[1] - dy / n * 8)
    return (f'<path d="M{f(p0[0])} {f(p0[1])} L{f(cuff[0])} {f(cuff[1])}" stroke="{SHIRT}" stroke-width="{w}" stroke-linecap="round"/>'
            f'<path d="M{f(p0[0])} {f(p0[1])} L{f(cuff[0])} {f(cuff[1])}" stroke="{SHIRT_D}" stroke-width="{f(w * 0.3)}" stroke-linecap="round" opacity="0.6"/>'
            f'<path d="M{f(cuff[0])} {f(cuff[1])} L{f(p1[0])} {f(p1[1])}" stroke="{GLOVE}" stroke-width="{f(w * 0.9)}" stroke-linecap="round"/>'
            f'<circle cx="{f(p1[0])}" cy="{f(p1[1])}" r="{f(w * 0.55)}" fill="{GLOVE}"/>')


def spanner(x, y, ang=0, length=26, fill='url(#steel)'):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 2.2)}" width="{length}" height="4.4" rx="1.6" fill="{fill}"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} L{f(x + 4)} {f(y - 6)} L{f(x + 4)} {f(y - 2)} L{f(x + 1)} {f(y - 2)} L{f(x + 1)} {f(y + 2)} '
            f'L{f(x + 4)} {f(y + 2)} L{f(x + 4)} {f(y + 6)} L{f(x - 2)} {f(y + 6)} Z" fill="{fill}"/></g>')


def rag(x, y, s=1.0):
    return (f'<path d="M{f(x - 6 * s)} {f(y - 4 * s)} q{f(4 * s)} {f(-4 * s)} {f(9 * s)} {f(-1 * s)} l{f(3 * s)} {f(8 * s)} '
            f'q{f(-5 * s)} {f(4 * s)} {f(-11 * s)} {f(1 * s)} Z" fill="{RAG}" stroke="{COND_D}" stroke-width="0.5"/>')


def tool_bag(x, y, open_=False, inside=''):
    lid = (f'<path d="M{f(x - 8)} {f(y)} L{f(x - 12)} {f(y - 7)} L{f(x + 4)} {f(y - 7)} L{f(x + 8)} {f(y)}" fill="{BAG}" stroke="{CRACK}" stroke-width="0.6" opacity="0.85"/>'
           if open_ else '')
    return (inside + lid
            + f'<rect x="{f(x - 9)}" y="{f(y)}" width="18" height="13" rx="2.5" fill="{BAG}"/>'
            + f'<path d="M{f(x - 9)} {f(y + 4)} L{f(x + 9)} {f(y + 4)}" stroke="{CRACK}" stroke-width="0.8" opacity="0.5"/>'
            + f'<path d="M{f(x - 5)} {f(y)} Q{f(x)} {f(y - 6)} {f(x + 5)} {f(y)}" stroke="{TOOL}" stroke-width="1.6" fill="none"/>')


def pin_insulator(x, yb, s=1.0):
    """A pin insulator standing on a cross-arm top (yb); its top groove is
    at (x, yb - 44 s)."""
    return (f'<rect x="{f(x - 3 * s)}" y="{f(yb - 16 * s)}" width="{f(6 * s)}" height="{f(16 * s)}" fill="url(#steel)"/>'
            f'<path d="M{f(x - 24 * s)} {f(yb - 14 * s)} L{f(x + 24 * s)} {f(yb - 14 * s)} L{f(x + 14 * s)} {f(yb - 24 * s)} L{f(x - 14 * s)} {f(yb - 24 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 19 * s)} {f(yb - 23 * s)} L{f(x + 19 * s)} {f(yb - 23 * s)} L{f(x + 10 * s)} {f(yb - 34 * s)} L{f(x - 10 * s)} {f(yb - 34 * s)} Z" fill="url(#porcelain)"/>'
            f'<path d="M{f(x - 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 33 * s)} L{f(x + 10 * s)} {f(yb - 46 * s)} L{f(x - 10 * s)} {f(yb - 46 * s)} Z" fill="url(#porcelain)"/>')


def conductor_path(d, w=4.4):
    return (f'<path d="{d}" stroke="{COND_D}" stroke-width="{f(w + 1.4)}" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{COND}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>')


def phone(x, y, w=12, h=20, ang=0, screen=''):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{f(w)}" height="{f(h)}" rx="{f(w * 0.18)}" fill="{BOOT}"/>'
            f'<rect x="{f(x - w / 2 + 1.5)}" y="{f(y - h / 2 + 2)}" width="{f(w - 3)}" height="{f(h - 4)}" rx="1" fill="{PAGE}"/>{screen}</g>')


def scribble(x0, x1, y, amp=1.2):
    """A written line: a short wave in ink."""
    pts = []
    n = max(2, int((x1 - x0) / 4))
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        pts.append(f'{f(x)} {f(y + (amp if i % 2 else -amp))}')
    return f'<path d="M{" L".join(pts)}" stroke="{INK}" stroke-width="1.1" fill="none" stroke-linejoin="round"/>'


def wrench_icon(x, y, s=1.0):
    return (f'<path d="M{f(x - 5 * s)} {f(y + 5 * s)} L{f(x + 3 * s)} {f(y - 3 * s)}" stroke="{COND_D}" stroke-width="{f(2.2 * s)}" stroke-linecap="round"/>'
            f'<circle cx="{f(x + 4 * s)}" cy="{f(y - 4 * s)}" r="{f(3 * s)}" fill="none" stroke="{COND_D}" stroke-width="{f(1.8 * s)}"/>')


def warn_icon(x, y, s=1.0):
    return (f'<path d="M{f(x)} {f(y - 6 * s)} L{f(x + 6.5 * s)} {f(y + 5 * s)} L{f(x - 6.5 * s)} {f(y + 5 * s)} Z" fill="{HELMET}" stroke="{HELMET_D}" stroke-width="{f(0.8 * s)}"/>'
            f'<rect x="{f(x - 0.8 * s)}" y="{f(y - 2.5 * s)}" width="{f(1.6 * s)}" height="{f(4.4 * s)}" fill="{CRACK}"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 3.2 * s)}" r="{f(0.9 * s)}" fill="{CRACK}"/>')


def logbook(x, y, w, h, left_lines=5, right_lines=5, tick=False):
    """An open logbook: the left page for the work done (a wrench), the right
    page for the abnormalities found (a warning sign)."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="3" fill="{COVER}"/>']
    pw = (w - 10) / 2
    for side in (0, 1):
        px = x + 4 + side * (pw + 2)
        o.append(f'<rect x="{f(px)}" y="{f(y + 4)}" width="{f(pw)}" height="{f(h - 8)}" rx="1.5" fill="{PAGE}"/>')
    o.append(f'<path d="M{f(x + w / 2)} {f(y + 4)} L{f(x + w / 2)} {f(y + h - 4)}" stroke="{COND_D}" stroke-width="0.8"/>')
    s = max(0.7, min(1.4, w / 140))
    o.append(wrench_icon(x + 4 + pw / 2, y + 14 * s, s))
    o.append(warn_icon(x + 6 + pw * 1.5, y + 14 * s, s))
    gap = (h - 34 * s) / 6
    for side, n in ((0, left_lines), (1, right_lines)):
        px = x + 4 + side * (pw + 2)
        for i in range(n):
            ly = y + 26 * s + i * gap
            o.append(scribble(px + 5, px + pw - 5 - (i % 2) * 6, ly, 1.0 * s))
    if tick:
        px = x + 6 + pw
        o.append(f'<path d="M{f(px + pw * 0.2)} {f(y + h * 0.5)} L{f(px + pw * 0.42)} {f(y + h * 0.78)} L{f(px + pw * 0.86)} {f(y + h * 0.26)}" '
                 f'stroke="{INK}" stroke-width="{f(3.2 * s)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    return ''.join(o)


def pen(x, y, ang=-35, s=1.0):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x)}" y="{f(y - 2 * s)}" width="{f(26 * s)}" height="{f(4 * s)}" rx="{f(1.6 * s)}" fill="{INK}"/>'
            f'<path d="M{f(x)} {f(y - 2 * s)} L{f(x - 5 * s)} {f(y)} L{f(x)} {f(y + 2 * s)} Z" fill="url(#steel)"/></g>')


def earth_lead(d):
    return (f'<path d="{d}" stroke="{EARTH}" stroke-width="2.6" fill="none"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="5 5"/>')


# --------------------------------------------------------------------------
# Round 1 — checklist: the span seen from the side, a tree at the right, the
# pole's own earth lead down to its pit. Portable earths at both span ends.
# --------------------------------------------------------------------------

PX = 92
WIRES = (40, 56, 61)
TREE = 156


def wire_y(x, y):
    if x <= PX:
        t, (a, b, c) = x / PX, (y + 8, y - 2, y - 1)
    else:
        t, (a, b, c) = (x - PX) / (200 - PX), (y - 1, y - 2, y + 8)
    return (1 - t) ** 2 * a + 2 * (1 - t) * t * b + t * t * c


def portable_earth(x):
    ys = [wire_y(x, y) for y in WIRES]
    o = [f'<path d="M{f(x)} {f(ys[0])} L{f(x)} {f(ys[-1] + 6)}" stroke="url(#steel)" stroke-width="3"/>']
    for y in ys:
        o.append(f'<rect x="{f(x - 3.5)}" y="{f(y - 3)}" width="7" height="6" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.6"/>')
    o.append(earth_lead(f'M{f(x)} {f(ys[-1] + 6)} Q{f(x + 8)} {f((ys[-1] + GY) / 2)} {f(x)} {GY - 4}'))
    o.append(f'<path d="M{f(x)} {GY - 6} L{f(x)} {GY + 12}" stroke="url(#steel)" stroke-width="3"/>')
    return ''.join(o)


def tree(branch):
    """A roadside tree; [branch] 'near' (leaves on the wire), 'stub' (cut
    back), or 'cut' (near, with a pruner's blade on it)."""
    o = [f'<path d="M{TREE - 5} {GY} L{TREE - 3} 96 L{TREE + 3} 96 L{TREE + 6} {GY} Z" fill="{TRUNK}"/>',
         f'<circle cx="{TREE + 6}" cy="88" r="20" fill="{LEAF_D}"/>',
         f'<circle cx="{TREE - 6}" cy="96" r="16" fill="{LEAF}"/>',
         f'<circle cx="{TREE + 12}" cy="104" r="14" fill="{LEAF}"/>']
    if branch == 'stub':
        o.append(f'<path d="M{TREE - 2} 104 L{TREE - 16} 90" stroke="{TRUNK}" stroke-width="4" stroke-linecap="round"/>')
        o.append(f'<circle cx="{TREE - 16}" cy="90" r="2.4" fill="{PIT}"/>')
    else:
        o.append(f'<path d="M{TREE - 2} 104 Q{TREE - 18} 84 {TREE - 34} 66" stroke="{TRUNK}" stroke-width="4" fill="none" stroke-linecap="round"/>')
        for cx, cy, r in ((TREE - 34, 62, 8), (TREE - 26, 70, 7), (TREE - 40, 70, 6)):
            o.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{LEAF}"/>')
        if branch == 'cut':
            o.append(f'<path d="M{TREE - 22} 78 l6 -5 l2 4 Z" fill="url(#steel)"/>')
    return ''.join(o)


def pit_earth(broken=False):
    """The pole's own earth: a GI wire down the pole to a clamp at the pit."""
    px = PX - 6
    o = [f'<rect x="{PX - 34}" y="{GY - 2}" width="22" height="6" rx="1" fill="{PIT}"/>',
         f'<rect x="{PX - 30}" y="{GY - 4}" width="14" height="3" rx="1" fill="{COND_D}"/>']
    if broken:
        o.append(f'<path d="M{px} 70 L{px} 146 Q{px - 4} 160 {px - 16} 166" stroke="{GI}" stroke-width="2.6" fill="none"/>')
        o.append(f'<path d="M{PX - 22} {GY - 4} Q{PX - 32} {GY - 12} {PX - 44} {GY - 4}" stroke="{GI}" stroke-width="2.6" fill="none"/>')
    else:
        o.append(f'<path d="M{px} 70 L{px} {GY - 8} Q{px - 2} {GY - 4} {PX - 22} {GY - 4}" stroke="{GI}" stroke-width="2.6" fill="none"/>')
    return ''.join(o)


def span_stage(branch='stub', broken=False):
    out = card_open()
    out.append(tree(branch))
    out.append(f'<rect x="{PX - 5}" y="30" width="10" height="{GY - 30}" fill="url(#pole)"/>')
    for i in range(6):
        y = 92 + i * 16
        side = -1 if i % 2 else 1
        out.append(f'<path d="M{PX + side * 5} {y} l{side * 6} 0" stroke="{COND_D}" stroke-width="2.2" stroke-linecap="round"/>')
    out.append(f'<rect x="{PX - 14}" y="62" width="28" height="7" rx="1.5" fill="url(#arm)"/>')
    out.append(pin_insulator(PX + 8, 63, s=0.36) + pin_insulator(PX - 7, 63, s=0.36))
    out.append(pin_insulator(PX, 47, s=0.36))
    for y in WIRES:
        out.append(conductor_path(f'M0 {y + 8} Q{PX / 2} {y - 2} {PX} {y - 1} Q{(PX + 200) / 2} {y - 2} 200 {y + 8}', 2.2))
    out.append(portable_earth(14) + portable_earth(188))
    out.append(pit_earth(broken))
    return out


def checklist_card(kind):
    if kind == 'visual':
        out = span_stage('stub')
        out.append(worker(50, ((44, 160), (70, 112)), face=1, look=-26, point=(0, 1)))
    elif kind == 'earth':
        out = span_stage('stub')
        out.append(kneeler(52, ((66, 192), (72, 190)), face=1))
        out.append(spanner(70, 192, -20, 18))
    elif kind == 'trim':
        out = span_stage('cut')
        # An insulated pruner pole (fibreglass) up to the branch.
        out.append(f'<path d="M108 170 L{TREE - 20} 76" stroke="{EARTH_Y}" stroke-width="3" stroke-linecap="round"/>')
        out.append(worker(110, ((104, 168), (114, 150)), face=1, look=-30))
    elif kind == 'wipe':
        out = span_stage('stub')
        out.append(spark(PX + 8, 51, 0.7))
        out.append(worker(40, ((32, 168), (52, 166)), face=-1, look=4, stride=4,
                          props_front=tool_bag(52, 160)))
        out.append(rag(30, 168))
        out.append(motion(62, 150, 1, 0, 3, 8))
    elif kind == 'branch':
        out = span_stage('near')
        out.append(worker(52, ((44, 168), (62, 168)), face=-1, look=8, stride=4))
        out.append(motion(72, 150, 1, 0, 3, 8))
    elif kind == 'earthlead':
        out = span_stage('stub', broken=True)
        out.append(worker(60, ((52, 166), (70, 166)), face=-1, look=6, stride=7))
        out.append(motion(80, 150, 1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — hidden: the pole top seen from the front (three pin insulators,
# a bolted joint by each phase), the camera's screen as an inset.
# --------------------------------------------------------------------------

CX = 100
ARM_Y = 60
PHASES = ((46, ARM_Y), (CX, 46), (154, ARM_Y))
HOT = 1  # the middle phase's joint is the hot one


def groove(i):
    x, yb = PHASES[i]
    return (x, yb - 44 * 0.5)


def joint_at(i):
    x, y = groove(i)
    return (x + 9, y + 2)


def pole_top(earth=False):
    out = card_open()
    out.append(f'<rect x="{CX - 6}" y="46" width="12" height="{GY - 46}" fill="url(#pole)"/>')
    out.append(f'<rect x="30" y="{ARM_Y}" width="140" height="8" rx="2" fill="url(#arm)"/>')
    out.append(f'<path d="M{CX - 4} {ARM_Y + 8} L60 {ARM_Y + 30} M{CX + 4} {ARM_Y + 8} L140 {ARM_Y + 30}" stroke="url(#steel)" stroke-width="3"/>')
    for i, (x, yb) in enumerate(PHASES):
        out.append(pin_insulator(x, yb, s=0.5))
        gx, gy = groove(i)
        # The conductor seen end on, a jumper loop and its bolted joint.
        out.append(f'<path d="M{f(gx)} {f(gy)} q16 4 9 16" stroke="{COND_D}" stroke-width="2.4" fill="none"/>')
        out.append(f'<circle cx="{f(gx)}" cy="{f(gy)}" r="4.2" fill="{COND}" stroke="{COND_D}" stroke-width="1.2"/>')
        jx, jy = joint_at(i)
        out.append(f'<rect x="{f(jx - 4)}" y="{f(jy - 3.5)}" width="8" height="7" rx="1.2" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.7"/>')
        out.append(f'<circle cx="{f(jx)}" cy="{f(jy)}" r="1.4" fill="{COND_D}"/>')
    if earth:
        out.append(f'<path d="M40 {ARM_Y + 18} L160 {ARM_Y + 18}" stroke="url(#steel)" stroke-width="3"/>')
        for i in range(3):
            gx, gy = groove(i)
            out.append(f'<path d="M{f(gx - 3)} {f(gy + 3)} L{f(gx - 6)} {ARM_Y + 18}" stroke="url(#steel)" stroke-width="1.6"/>')
            out.append(f'<rect x="{f(gx - 6)}" y="{f(gy)}" width="5" height="5" rx="1" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.5"/>')
        out.append(earth_lead(f'M40 {ARM_Y + 18} Q20 {ARM_Y + 70} 22 {GY - 4}'))
        out.append(f'<path d="M22 {GY - 6} L22 {GY + 12}" stroke="url(#steel)" stroke-width="3"/>')
    return out


def thermal_screen(x, y, w=74, h=58):
    """The camera's view: the same three joints, the middle one hot."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="6" fill="{CAM}"/>',
         f'<rect x="{f(x + 4)}" y="{f(y + 4)}" width="{w - 8}" height="{h - 8}" rx="3" fill="{SCREEN}"/>']
    sx, sy = (w - 8) / 200, (h - 8) / 80
    def m(p):
        return (x + 4 + p[0] * sx, y + 4 + (p[1] - 10) * sy)
    a0, a1 = m((30, ARM_Y + 4)), m((170, ARM_Y + 4))
    o.append(f'<path d="M{f(a0[0])} {f(a0[1])} L{f(a1[0])} {f(a1[1])}" stroke="{COOL}" stroke-width="2.4"/>')
    for i in range(3):
        jx, jy = m(joint_at(i))
        if i == HOT:
            o.append(f'<circle cx="{f(jx)}" cy="{f(jy)}" r="9" fill="url(#heat)"/>')
        else:
            o.append(f'<circle cx="{f(jx)}" cy="{f(jy)}" r="3.4" fill="{COOL}"/>')
    return ''.join(o)


def camera(x, y, ang=-40):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x - 8)}" y="{f(y - 5)}" width="16" height="10" rx="2" fill="{CAM}"/>'
            f'<circle cx="{f(x + 8)}" cy="{f(y)}" r="3.6" fill="{SCREEN}" stroke="{COND_D}" stroke-width="0.8"/></g>')


def climber_top(hands, props=''):
    hip, sh, head = (84, 84), (87, 59), (90, 51)
    feet = ((86, 116), (92, 102))
    strap = (f'<path d="M88 80 Q{CX} 68 {CX + 8} 76" stroke="{HARNESS}" stroke-width="2.4" fill="none"/>'
             f'<path d="M{CX + 8} 76 Q{CX + 4} 86 88 84" stroke="{HARNESS}" stroke-width="2.4" fill="none" opacity="0.6"/>')
    belt = f'<rect x="76" y="78" width="16" height="4" rx="1.5" fill="{HARNESS}"/>'
    return strap + figure(hip, sh, head, feet, hands, 1, -20, props_front=props) + belt


def hidden_card(kind):
    jx, jy = joint_at(HOT)
    if kind == 'scan':
        out = pole_top()
        out.append(worker(48, ((60, 132), (66, 130)), face=1, look=-24, props_front=camera(64, 128)))
        out.append(thermal_screen(118, 132))
    elif kind == 'tighten':
        out = pole_top(earth=True)
        out.append(climber_top(((CX - 2, 66), (jx - 2, jy + 10))))
        out.append(spanner(jx, jy, 110, 18))
        out.append(turn_arrow(jx, jy, 9, 1.4))
        out.append(thermal_screen(118, 132))
    elif kind == 'eyes':
        out = pole_top()
        hx, hy = head_of(48)
        out.append(worker(48, ((hx + 6, hy - 4), (72, 140)), face=1, look=-24, point=(0, 0)))
        out.append(f'<path d="M72 140 l0 -7" stroke="{GLOVE}" stroke-width="2.6" stroke-linecap="round"/>')
    elif kind == 'later':
        out = pole_top()
        out.append(worker(40, ((30, 168), (54, 166)), face=-1, look=4, stride=4,
                          props_front=tool_bag(54, 160), props_back=camera(31, 166, 10)))
        out.append(motion(64, 150, 1, 0, 3, 8))
        out.append(thermal_screen(118, 132))
    elif kind == 'shine':
        out = pole_top(earth=True)
        out.append(climber_top(((CX - 2, 66), (jx - 2, jy + 6))))
        out.append(rag(jx - 1, jy + 4, 0.9))
        out.append(spark(jx + 2, jy - 3, 0.7))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — fixnow: the pole close up. Top: the cross-arm's bolt and nut.
# Lower: a pole-band clamp holding the stay wire. The line overhead is
# earthed (the PM shutdown).
# --------------------------------------------------------------------------

NUT = (112, 82)
CLAMP_Y = 150


def fix_stage(nut='tight', clamp='rusty'):
    out = card_open()
    out.append('<rect x="36" y="0" width="26" height="220" fill="url(#pole)"/>')
    out.append(conductor_path('M62 24 Q130 30 200 26', 4))
    out.append(f'<rect x="176" y="20" width="8" height="10" rx="1.5" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.6"/>')
    out.append(earth_lead('M180 30 Q196 90 190 220'))
    # Cross-arm through the top clamp.
    out.append('<rect x="56" y="74" width="144" height="14" rx="2" fill="url(#arm)"/>')
    out.append(f'<rect x="32" y="70" width="34" height="22" rx="3" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>')
    x, y = NUT
    out.append(f'<circle cx="{x}" cy="{y}" r="8" fill="url(#steel)" stroke="{COND_D}" stroke-width="0.8"/>')
    if nut == 'tight':
        out.append(_hex(x, y, 6))
    else:
        # Backed off down the thread: a gap and the bare thread showing.
        out.append(f'<rect x="{x - 2}" y="{y - 2}" width="12" height="4" fill="{COND_D}"/>')
        for i in range(3):
            out.append(f'<path d="M{x + 1 + i * 3} {y - 2} l1.5 4" stroke="{BIND}" stroke-width="0.8"/>')
        out.append(f'<g transform="rotate(18 {x + 12} {y})">{_hex(x + 12, y, 6)}</g>')
    # The pole band and its ear, the stay wire.
    fill = 'url(#steel)' if clamp == 'new' else RUST
    out.append(f'<rect x="32" y="{CLAMP_Y - 8}" width="34" height="16" rx="3" fill="{fill}" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<path d="M66 {CLAMP_Y - 5} L84 {CLAMP_Y - 5} L84 {CLAMP_Y + 5} L66 {CLAMP_Y + 5}" fill="{fill}" stroke="{COND_D}" stroke-width="0.8"/>')
    out.append(f'<circle cx="78" cy="{CLAMP_Y}" r="2.6" fill="{COND_D}"/>')
    if clamp != 'new':
        for cx, cy, r in ((40, CLAMP_Y - 3, 2.4), (52, CLAMP_Y + 3, 3), (60, CLAMP_Y - 2, 1.8), (74, CLAMP_Y + 2, 2)):
            out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{RUST_D}"/>')
    out.append(f'<path d="M84 {CLAMP_Y} L200 214" stroke="{GI}" stroke-width="2.4"/>')
    return out


def _hex(x, y, r):
    pts = ' '.join(f'{f(x + r * math.cos(math.radians(a)))},{f(y + r * math.sin(math.radians(a)))}' for a in range(0, 360, 60))
    return f'<polygon points="{pts}" fill="url(#steel)" stroke="{COND_D}" stroke-width="1"/>'


def old_clamp(x, y):
    return (f'<path d="M{x - 9} {y} q9 -12 18 0" stroke="{RUST}" stroke-width="3.4" fill="none"/>'
            f'<circle cx="{x - 3}" cy="{y - 6}" r="1.6" fill="{RUST_D}"/>')


def fixnow_card(kind):
    x, y = NUT
    if kind == 'nut':
        # The clamp was already put right this visit; now the nut is brought
        # up tight. Only the traps (leave, half) leave a rusted clamp behind.
        out = fix_stage('tight', 'new')
        out.append(spanner(x, y, 30, 34))
        out.append(arm((200, 150), (140, 100)))
        out.append(turn_arrow(x, y, 14))
    elif kind == 'clamp':
        out = fix_stage('tight', 'new')
        out.append(tool_bag(150, 196, open_=True, inside=old_clamp(146, 194)))
        out.append(arm((200, 196), (82, CLAMP_Y + 4)))
        out.append(spanner(78, CLAMP_Y, 60, 20))
    elif kind == 'torque':
        out = fix_stage('tight', 'new')
        out.append(f'<g transform="rotate(24 {x} {y})"><rect x="{x}" y="{y - 2.6}" width="66" height="5.2" rx="2" fill="url(#steel)"/>'
                   f'<rect x="{x + 50}" y="{y - 3.6}" width="20" height="7.2" rx="3" fill="{TOOL}"/>'
                   f'<circle cx="{x + 24}" cy="{y}" r="6" fill="{MOVE}" stroke="{COND_D}" stroke-width="1"/>'
                   f'<path d="M{x + 24} {y} l3.6 -3.4" stroke="{TOOL}" stroke-width="1.2" stroke-linecap="round"/></g>')
        out.append(_hex(x, y, 6))
        out.append(arm((200, 170), (172, 112)))
        out.append(turn_arrow(x, y, 14))
    elif kind == 'leave':
        out = fix_stage('loose', 'rusty')
        out.append(tool_bag(150, 196))
        out.append(arm((200, 120), (184, 116)))
        out.append(motion(166, 104, 1, 0, 3, 8))
    elif kind == 'pipe':
        out = fix_stage('loose', 'new')
        out.append(spanner(x, y, 30, 30, fill=RUST))
        out.append(f'<g transform="rotate(30 {x} {y})"><rect x="{x + 22}" y="{y - 4}" width="60" height="8" rx="2" fill="{PIPE}"/></g>')
        out.append(arm((200, 170), (178, 126)))
        out.append(motion(150, 140, 0.6, 1, 3, 8))
    elif kind == 'half':
        out = fix_stage('tight', 'rusty')
        out.append(tool_bag(150, 196))
        out.append(arm((200, 206), (162, 196)))
        out.append(motion(176, 180, 1, 0, 3, 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — record: close-ups at the end of the PM visit, the pole behind.
# --------------------------------------------------------------------------

def record_stage():
    out = card_open()
    out.append(f'<rect x="12" y="0" width="16" height="{GY}" fill="url(#pole)"/>')
    return out


def record_card(kind):
    out = record_stage()
    if kind == 'logbook':
        out.append(logbook(24, 84, 152, 104))
        out.append(pen(128, 150, -35))
        out.append(arm((200, 220), (172, 186)) + arm((0, 220), (28, 186)))
    elif kind == 'app':
        screen = (wrench_icon(84, 92, 1.0) + warn_icon(116, 92, 1.0)
                  + ''.join(scribble(70, 96 - (i % 2) * 4, 106 + i * 12) for i in range(5))
                  + ''.join(scribble(104, 130 - (i % 2) * 4, 106 + i * 12) for i in range(5))
                  + f'<path d="M100 84 L100 172" stroke="{COND_D}" stroke-width="0.8"/>')
        out.append(phone(100, 130, 76, 120, 0, screen))
        out.append(arm((60, 220), (78, 182)) + arm((150, 220), (124, 176)))
    elif kind == 'chat':
        # The supervisor (white helmet) and the lineman talking; the logbook stays shut.
        for (x, face, hat) in ((58, 1, HELMET), (146, -1, WHITE_HAT)):
            out.append(f'<path d="M{x - 30} 220 Q{x} 150 {x + 30} 220 Z" fill="url(#shirt)"/>')
            out.append(f'<circle cx="{x}" cy="128" r="22" fill="{SKIN}"/>')
            out.append(f'<path d="M{x - 26} 124 A26 26 0 0 1 {x + 26} 124 Z" fill="{hat}"/>')
            out.append(f'<circle cx="{x + 9 * face}" cy="132" r="2.4" fill="{HAIR}"/>')
            out.append(f'<path d="M{x + 6 * face} 142 q{6 * face} 4 {12 * face} 0" stroke="{SKIN_D}" stroke-width="2" fill="none"/>')
        out.append(f'<path d="M66 40 h70 a10 10 0 0 1 10 10 v24 a10 10 0 0 1 -10 10 h-50 l-12 12 l2 -12 h-10 a10 10 0 0 1 -10 -10 v-24 a10 10 0 0 1 10 -10 Z" fill="{MOVE}"/>')
        out.append(scribble(76, 132, 56, 1.4).replace(INK, COND_D) + scribble(76, 120, 68, 1.4).replace(INK, COND_D))
        out.append(f'<rect x="8" y="176" width="40" height="30" rx="3" fill="{COVER}" transform="rotate(-12 28 191)"/>')
    elif kind == 'blank':
        out.append(logbook(24, 84, 152, 104, right_lines=0))
        out.append(pen(56, 150, -35))
        out.append(arm((200, 220), (172, 186)) + arm((0, 220), (28, 186)))
    elif kind == 'blind':
        out.append(logbook(24, 92, 152, 104, tick=True))
        out.append(phone(46, 60, 40, 64, -14, f'<path d="M42 52 L54 60 L42 68 Z" fill="{TOOL}"/>'))
        out.append(arm((0, 120), (34, 84)))
        out.append(arm((200, 220), (172, 194)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — report: a plinth DTR in its fenced yard; its oil gauge shows dark
# oil and it hums oddly (sound marks). The lineman outside the fence.
# --------------------------------------------------------------------------

def dtr_stage():
    out = card_open()
    out.append(f'<rect x="96" y="176" width="88" height="{GY - 176}" fill="{PIT}"/>')
    out.append('<rect x="104" y="112" width="72" height="64" rx="3" fill="url(#tank)"/>')
    for x in range(108, 176, 6):
        out.append(f'<path d="M{x} 118 L{x} 170" stroke="{COND_D}" stroke-width="1" opacity="0.5"/>')
    out.append('<rect x="112" y="92" width="56" height="14" rx="7" fill="url(#tank)"/>')
    out.append(f'<path d="M124 106 L124 112 M156 106 L156 112" stroke="{COND_D}" stroke-width="3"/>')
    for x in (120, 140, 160):
        out.append(f'<rect x="{x - 3}" y="98" width="6" height="14" fill="url(#porcelain)"/>')
        out.append(f'<path d="M{x} 98 L{x} 76" stroke="{COND_D}" stroke-width="1.6"/>')
    # The oil gauge on the tank: the oil has gone dark.
    out.append(f'<circle cx="160" cy="132" r="9" fill="{MOVE}" stroke="{COND_D}" stroke-width="1.4"/>')
    out.append(f'<path d="M153 134 A7 7 0 0 0 167 134 Z" fill="{OIL}"/>')
    # The odd sound from inside.
    for i, r in enumerate((8, 14, 20)):
        out.append(f'<path d="M{100 - r * 0.2} {132 - r} A{r} {r} 0 0 0 {100 - r * 0.2} {132 + r}" stroke="{SOUND}" stroke-width="1.6" fill="none" opacity="{f(0.9 - i * 0.2)}"/>')
    # The yard fence in front (posts and a light mesh).
    for x in (88, 192):
        out.append(f'<rect x="{x - 2}" y="150" width="4" height="{GY - 150}" fill="{COND_D}"/>')
    mesh = ''.join(f'<path d="M{x} 152 l20 46 M{x + 20} 152 l-20 46"/>' for x in range(90, 190, 12))
    out.append(f'<g stroke="{GI}" stroke-width="0.8" opacity="0.6">{mesh}</g>')
    return out


def report_card(kind):
    out = dtr_stage()
    if kind == 'phone':
        hx, hy = head_of(46)
        out.append(worker(46, ((hx + 5, hy + 3), (72, 124)), face=1, look=-6, point=(0, 1)))
        out.append(phone(hx + 6, hy + 2, 6, 11, 14))
    elif kind == 'note':
        out.append(worker(46, ((52, 140), (70, 138)), face=1, look=-8))
        out.append(logbook(48, 126, 30, 20, 3, 2))
        out.append(pen(70, 138, -40, 0.5))
    elif kind == 'shrug':
        hx, hy = head_of(40, -1)
        out.append(worker(40, ((hx - 14, hy - 4), (hx + 14, hy - 4)), face=-1, look=10, stride=4))
        out.append(phone(hx + 14, hy - 8, 6, 11, 8))
        out.append(motion(16, 150, -1, 0, 3, 8))
    elif kind == 'wait':
        out.append(f'<path d="M30 {GY} L34 172 L58 172 L62 {GY} Z" fill="{BUCKET}"/>'
                   f'<path d="M33 178 L59 178" stroke="{CRACK}" stroke-width="1" opacity="0.5"/>')
        out.append(sitter(46, 172, ((60, 162), (64, 158)), face=1, look=-6))
        out.append(f'<rect x="64" y="{GY - 6}" width="20" height="6" rx="1.5" fill="{COVER}"/>'
                   f'<rect x="66" y="{GY - 8}" width="16" height="2.5" fill="{PAGE}"/>')
        out.append(pen(88, GY - 2, 0, 0.5))
        # The thought: a calendar page, the next PM some weeks away.
        out.append(f'<circle cx="52" cy="116" r="3" fill="{MOVE}"/><circle cx="46" cy="104" r="5" fill="{MOVE}"/>')
        out.append(f'<rect x="14" y="40" width="64" height="56" rx="10" fill="{MOVE}"/>')
        out.append(f'<rect x="24" y="48" width="44" height="40" rx="3" fill="{PAGE}" stroke="{COND_D}" stroke-width="1"/>')
        out.append(f'<rect x="24" y="48" width="44" height="9" rx="2" fill="{TOOL}"/>')
        for r in range(3):
            for c in range(4):
                out.append(f'<rect x="{27 + c * 10}" y="{61 + r * 9}" width="7" height="6" fill="{GI}"/>')
    elif kind == 'polish':
        # Polishing instead of reporting: from OUTSIDE the yard he shines the
        # plate hung on the fence mesh; the failing tank stays untouched (no
        # card puts him inside a live DTR yard).
        px, py = 84, 156
        out.append(f'<rect x="{px}" y="{py}" width="30" height="22" rx="2" fill="{PAGE}" stroke="{COND_D}" stroke-width="1"/>'
                   f'<path d="M{px + 17} {py + 3} L{px + 10} {py + 12} L{px + 15} {py + 12} L{px + 12} {py + 19} '
                   f'L{px + 20} {py + 9} L{px + 15} {py + 9} Z" fill="{TOOL}"/>'
                   f'<path d="M{px + 4} {py} L{px + 4} {py - 4} M{px + 26} {py} L{px + 26} {py - 4}" stroke="{COND_D}" stroke-width="1"/>')
        out.append(worker(56, ((86, 166), (92, 172)), face=1, look=-4))
        out.append(rag(93, 168))
        out.append(spark(108, 160, 0.6) + spark(80, 178, 0.45))
    return card_close(out)


CARDS = {
    'checklist_visual': checklist_card('visual'),
    'checklist_earth': checklist_card('earth'),
    'checklist_trim': checklist_card('trim'),
    'checklist_wipe': checklist_card('wipe'),
    'checklist_branch': checklist_card('branch'),
    'checklist_earthlead': checklist_card('earthlead'),
    'hidden_scan': hidden_card('scan'),
    'hidden_tighten': hidden_card('tighten'),
    'hidden_eyes': hidden_card('eyes'),
    'hidden_later': hidden_card('later'),
    'hidden_shine': hidden_card('shine'),
    'fixnow_nut': fixnow_card('nut'),
    'fixnow_clamp': fixnow_card('clamp'),
    'fixnow_torque': fixnow_card('torque'),
    'fixnow_leave': fixnow_card('leave'),
    'fixnow_pipe': fixnow_card('pipe'),
    'fixnow_half': fixnow_card('half'),
    'record_logbook': record_card('logbook'),
    'record_app': record_card('app'),
    'record_chat': record_card('chat'),
    'record_blank': record_card('blank'),
    'record_blind': record_card('blind'),
    'report_phone': report_card('phone'),
    'report_note': report_card('note'),
    'report_shrug': report_card('shrug'),
    'report_wait': report_card('wait'),
    'report_polish': report_card('polish'),
}

# Safe cards and traps per round (mirrors learn_board_pack510.dart).
ROUNDS = {
    'checklist': (['checklist_visual', 'checklist_earth', 'checklist_trim'],
                  ['checklist_wipe', 'checklist_branch', 'checklist_earthlead']),
    'hidden': (['hidden_scan', 'hidden_tighten'], ['hidden_eyes', 'hidden_later', 'hidden_shine']),
    'fixnow': (['fixnow_nut', 'fixnow_clamp', 'fixnow_torque'], ['fixnow_leave', 'fixnow_pipe', 'fixnow_half']),
    'record': (['record_logbook', 'record_app'], ['record_chat', 'record_blank', 'record_blind']),
    'report': (['report_phone', 'report_note'], ['report_shrug', 'report_wait', 'report_polish']),
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


def stale_files():
    """SVGs in the folder that this script no longer draws."""
    if not os.path.isdir(OUT):
        return []
    return [n for n in os.listdir(OUT) if n.endswith('.svg') and n[:-4] not in CARDS]


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name in stale_files():
        os.remove(os.path.join(OUT, name))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
