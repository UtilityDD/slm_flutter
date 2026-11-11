"""Picture cards for lesson 4.9 শেখা ("রাস্তার আলো (Street Light) মেরামত").

python -I tool/m4_board49_art.py .

Writes assets/game/art/m4_board49/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art.

What the cards show comes from lesson 4.9 and its film script only:
  1. dark (the light does not come on): step 1 is the supply — the voltage
     at the light's terminal with a multimeter; if the whole area is dark the
     common (group) controller at the feeder pillar is checked. Traps: going
     straight to the gear (ballast / driver), swapping the photocell, or
     changing one lamp when the whole area is dark;
  2. day (the light burns day and night): the photocell is bad, dirty or
     turned the wrong way — clean it, turn its sensor to the sky (or replace
     it). Traps: a new lamp, new gear, the sensor turned down to the road;
  3. cycle (on-off-on): the classic sign of an old HPSV lamp at the end of
     its life, or a loose connection — change the lamp, tighten every
     connection. Traps: a new photocell, any ballast at hand (each lamp needs
     its own wattage and type), the old lamp thrown away (mercury or other
     hazardous matter — disposed of by the rules);
  4. isolate: switch off that light's fuse / MCB, then prove no voltage at
     the fixture with a tester or multimeter. Traps: working live, working
     without the test, working on while the tester still shows voltage;
  5. platform: a ladder or sky lift that is stable, secured and a safe
     distance from overhead lines. Traps: a bucket by the overhead line, a
     ladder standing on a stone, a lift leaning on a slope.
House rules drawn, not said: anyone up a pole or in a bucket wears a helmet
and a harness; repair cards (rounds day and cycle) show the pole box OFF.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m4_board49_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm4_board49')
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
HARN = '#C8501E'
ROAD = '#3A3F46'
KERB = '#6B7178'
HOUSING = '#8D979F'
HOUSING_D = '#6C757D'
GLASS = '#E8EEF2'
CELL = '#E9ECEE'
CELL_D = '#5A636B'
DIRT = '#6E5A3A'
METER = '#F0C02E'
METER_D = '#B98A22'
FACE = '#1E2329'
DISPLAY = '#9FBF9A'
LEAD_R = '#D8402F'
LEAD_B = '#22262B'
TESTER = '#3B6FD1'
STEELC = '#C3CBD1'
NEON = '#FF8A3D'
GEAR = '#4A5560'
AMBER = '#F3B65A'
CAP = '#B8A27A'
CARTON = '#B58A55'
CARTON_D = '#8E6A3E'
RAG = '#4FA3C7'
DRIVER = '#E8742A'
BOX = '#9AA4AC'
BOX_D = '#7F8C8D'
ON_C = '#FF4B3E'
OFF_C = '#4CD964'
FUSE = '#F4F1E8'
PILLAR = '#6F8A6C'
PILLAR_D = '#93AE8F'
BUCKET = '#E6E9EC'
BUCKET_D = '#9AA3AA'
TRUCK = '#2F7D5B'
TRUCK_D = '#25634A'
TYRE = '#1C1F24'
WOOD = '#B98A22'
ROPE = '#C9A15A'
STONE = '#8C8F93'
ARROW = '#FFFFFF'
DRAIN = '#2A2E33'

DEFS = """<defs>
  <linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1B2A4A"/><stop offset="1" stop-color="#4A5C82"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E9F2"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7D868E"/><stop offset="0.5" stop-color="#C3CBD1"/><stop offset="1" stop-color="#6E777F"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="neon" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.95"/><stop offset="0.4" stop-color="#FFB37A" stop-opacity="0.8"/><stop offset="1" stop-color="#FF8A3D" stop-opacity="0"/></radialGradient>
  <radialGradient id="sun" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="0.6" stop-color="#FFE38A"/><stop offset="1" stop-color="#FFE38A" stop-opacity="0"/></radialGradient>
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


def _hand(p):
    x, y = p
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{GLOVE}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, harness=False):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves; [harness] adds the orange chest and waist straps."""
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
    g.append(_hand(hb))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    if harness:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 5)} L{f(hip[0] + px)} {f(hip[1] + py - 5)}" stroke="{HARN}" stroke-width="2.6"/>')
        g.append(f'<path d="M{f(sh[0] - px * 0.7)} {f(sh[1] - 1)} L{f(hip[0] + px * 0.6)} {f(hip[1] - 6)}" stroke="{HARN}" stroke-width="2"/>')
        g.append(f'<path d="M{f(sh[0] + px * 0.7)} {f(sh[1] - 1)} L{f(hip[0] - px * 0.6)} {f(hip[1] - 6)}" stroke="{HARN}" stroke-width="2"/>')
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
    g.append(_hand(hf))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, gy=GY, harness=False):
    """A standing worker at x with his feet on gy, scaled S about his feet;
    the hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, harness)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} {f(-gy)})">{fig}</g>'


def hip_of(x, gy):
    return (x, gy - 30 * S)


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def road():
    return (f'<rect x="0" y="{GY - 4}" width="{W}" height="{H - GY + 4}" fill="{ROAD}"/>'
            f'<rect x="0" y="{GY - 6}" width="{W}" height="3" fill="{KERB}"/>'
            + ''.join(f'<rect x="{x}" y="{GY + 10}" width="16" height="3" rx="1.5" fill="{KERB}"/>' for x in range(8, 200, 34)))


def sky(back):
    if back == 'night':
        return ''.join(f'<circle cx="{x}" cy="{y}" r="0.9" fill="#FFFFFF" opacity="0.7"/>' for x, y in ((150, 14), (176, 30), (128, 22), (186, 60), (60, 16)))
    return '<circle cx="170" cy="26" r="16" fill="url(#sun)"/>'


def photocell(x, y, turn=0, dirty=False):
    """The photocell on its stalk, sensor window at (x, y); [turn] tilts it."""
    o = [f'<g transform="rotate({f(turn)} {f(x)} {f(y + 7)})">',
         f'<rect x="{f(x - 2)}" y="{f(y + 3)}" width="4" height="6" fill="{CELL_D}"/>',
         f'<path d="M{f(x - 7)} {f(y + 4)} A7 7 0 0 1 {f(x + 7)} {f(y + 4)} Z" fill="{CELL}" stroke="{CELL_D}" stroke-width="0.8"/>',
         f'<rect x="{f(x - 2.5)}" y="{f(y - 2)}" width="5" height="3" rx="1" fill="{FACE}"/>']
    if dirty:
        o += [f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="{r}" fill="{DIRT}"/>' for dx, dy, r in ((-3.5, 1.5, 1.4), (2.5, 2, 1.2), (4, 0, 0.9), (-1, -0.5, 0.9))]
    o.append('</g>')
    return ''.join(o)


def street_light(x=34, top=40, head=(40, 106), cell=True, turn=0, dirty=False, open_=False):
    """A steel pole at x with its arm and luminaire head (x0..x1) at the top;
    the photocell sits on the head; [open_] drops the cover on its hinge."""
    x0, x1 = head
    o = [f'<rect x="{f(x - 3.5)}" y="{top}" width="7" height="{GY - top}" fill="url(#steel)"/>',
         f'<path d="M{f(x)} {top + 4} Q{f(x)} {top - 6} {f(x + 14)} {top - 4} L{f(x0 + 4)} {top - 2}" stroke="{HOUSING_D}" stroke-width="4" fill="none"/>',
         f'<path d="M{f(x0)} {top - 4} Q{f((x0 + x1) / 2)} {top - 12} {f(x1)} {top - 2} L{f(x1)} {top + 6} L{f(x0)} {top + 6} Z" fill="{HOUSING}" stroke="{HOUSING_D}" stroke-width="1"/>']
    if open_:
        o.append(f'<rect x="{f(x0 + 8)}" y="{top + 6}" width="{f(x1 - x0 - 16)}" height="4" fill="{FACE}"/>')
        o.append(f'<rect x="{f(x0 + 10)}" y="{top + 7}" width="14" height="5" rx="1" fill="{GEAR}"/>')
        for i in range(3):
            o.append(f'<circle cx="{f(x0 + 13 + i * 4)}" cy="{top + 9.5}" r="1.2" fill="{STEELC}"/>')
        o.append(f'<path d="M{f(x0 + 2)} {top + 6} L{f(x0 - 2)} {top + 30}" stroke="{GLASS}" stroke-width="5" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{f(x0 + 4)} {top + 6} Q{f((x0 + x1) / 2)} {top + 14} {f(x1 - 4)} {top + 6} Z" fill="{GLASS}"/>')
    if cell:
        o.append(photocell(x1 - 10, top - 18, turn, dirty))
    return ''.join(o)


def pole_box(x=34, y=136, on=False, fuse_out=False):
    """The light's own switch box on the pole: MCB lever up = ON (red lamp),
    down = OFF (green lamp); a fuse carrier beside it."""
    o = [f'<rect x="{x - 15}" y="{y}" width="30" height="36" rx="2" fill="{BOX}" stroke="{BOX_D}" stroke-width="1.2"/>',
         f'<rect x="{x - 11}" y="{y + 6}" width="9" height="20" rx="1" fill="{FACE}"/>',
         f'<rect x="{x - 9}" y="{y + (8 if on else 16)}" width="5" height="8" rx="1" fill="{BOOT}" stroke="{STEELC}" stroke-width="0.6"/>',
         f'<circle cx="{x - 6.5}" cy="{y + 31}" r="2" fill="{ON_C if on else OFF_C}"/>']
    if fuse_out:
        o.append(f'<rect x="{x + 2}" y="{y + 6}" width="9" height="20" rx="1" fill="{FACE}"/>')
    else:
        o.append(f'<rect x="{x + 2}" y="{y + 6}" width="9" height="20" rx="1.5" fill="{FUSE}" stroke="{BOX_D}" stroke-width="0.6"/>')
    return ''.join(o)


def fuse_in_hand(x, y):
    return f'<rect x="{f(x - 4.5)}" y="{f(y - 10)}" width="9" height="20" rx="1.5" fill="{FUSE}" stroke="{BOX_D}" stroke-width="0.6"/>'


def multimeter(x, y, s=1.0):
    """A yellow multimeter, top-left at (x, y); returns svg and the lead roots."""
    w, h = 14 * s, 20 * s
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(2 * s)}" fill="{METER}" stroke="{METER_D}" stroke-width="0.8"/>'
            f'<rect x="{f(x + 2 * s)}" y="{f(y + 2 * s)}" width="{f(10 * s)}" height="{f(6 * s)}" rx="1" fill="{DISPLAY}"/>'
            f'<circle cx="{f(x + 7 * s)}" cy="{f(y + 13 * s)}" r="{f(3 * s)}" fill="{FACE}"/>'), (x + 4 * s, y + h), (x + 10 * s, y + h)


def leads(roots, tips):
    o = []
    for (rx, ry), (tx, ty), col in zip(roots, tips, (LEAD_R, LEAD_B)):
        o.append(f'<path d="M{f(rx)} {f(ry)} Q{f((rx + tx) / 2 + 6)} {f(max(ry, ty) + 14)} {f(tx)} {f(ty)}" stroke="{col}" stroke-width="1.4" fill="none"/>')
        o.append(f'<path d="M{f(tx)} {f(ty)} l0 -5" stroke="{col}" stroke-width="2.4" stroke-linecap="round"/>')
    return ''.join(o)


def tester(x, y, glow=False, ang=-30):
    """A neon tester screwdriver with its tip at (x, y)."""
    o = []
    if glow:
        o.append(f'<circle cx="{f(x)}" cy="{f(y + 9)}" r="9" fill="url(#neon)"/>')
    o.append(f'<g transform="rotate({ang} {f(x)} {f(y)})">'
             f'<path d="M{f(x)} {f(y)} l0 6" stroke="{STEELC}" stroke-width="1.6"/>'
             f'<rect x="{f(x - 2.4)}" y="{f(y + 6)}" width="4.8" height="15" rx="2" fill="{TESTER}"/>'
             f'<rect x="{f(x - 1.2)}" y="{f(y + 8)}" width="2.4" height="5" rx="1" fill="{NEON if glow else FACE}"/></g>')
    return ''.join(o)


def screwdriver(x, y, ang=-30):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})"><path d="M{f(x)} {f(y)} l0 8" stroke="{STEELC}" stroke-width="1.6"/>'
            f'<rect x="{f(x - 2.4)}" y="{f(y + 8)}" width="4.8" height="12" rx="2" fill="{DRIVER}"/></g>')


def gear_box(x, y, s=1.0):
    """A ballast (or LED driver) box, centre (x, y)."""
    w, h = 18 * s, 11 * s
    return (f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{f(w)}" height="{f(h)}" rx="1.5" fill="{GEAR}"/>'
            + ''.join(f'<circle cx="{f(x - w / 2 + 3 * s + i * 3.5 * s)}" cy="{f(y - h / 2 + 2.5 * s)}" r="{f(0.9 * s)}" fill="{STEELC}"/>' for i in range(3)))


def hpsv(x, y, ang=0, s=1.0, broken=False):
    """A tubular sodium lamp: amber glass on a screw cap, cap end at (x, y)."""
    o = [f'<g transform="rotate({ang} {f(x)} {f(y)})">',
         f'<rect x="{f(x - 2.5 * s)}" y="{f(y)}" width="{f(5 * s)}" height="{f(5 * s)}" fill="{CAP}"/>']
    if broken:
        o.append(f'<path d="M{f(x - 3.5 * s)} {f(y + 5 * s)} l{f(7 * s)} 0 l{f(-1 * s)} {f(6 * s)} l{f(-2 * s)} {f(-3 * s)} l{f(-1.5 * s)} {f(4 * s)} Z" fill="{AMBER}"/>')
    else:
        o.append(f'<rect x="{f(x - 3.5 * s)}" y="{f(y + 5 * s)}" width="{f(7 * s)}" height="{f(16 * s)}" rx="{f(3.5 * s)}" fill="{AMBER}"/>')
    o.append('</g>')
    return ''.join(o)


def carton(x, y, lamp=True):
    o = [f'<rect x="{x}" y="{y}" width="16" height="12" fill="{CARTON}" stroke="{CARTON_D}" stroke-width="0.8"/>',
         f'<path d="M{x} {y} l-4 -4 M{x + 16} {y} l4 -4" stroke="{CARTON_D}" stroke-width="1.6"/>']
    if lamp:
        o.insert(0, hpsv(x + 8, y - 6, 0, 0.7))
    return ''.join(o)


def rag(x, y):
    return f'<path d="M{f(x)} {f(y)} q4 3 8 0 l1 9 q-5 3 -10 0 Z" fill="{RAG}"/>'


def turn_arrow(x, y, up=True):
    """A curved arrow beside the photocell: turning it to face up or down."""
    if up:
        return (f'<path d="M{f(x + 12)} {f(y + 8)} Q{f(x + 15)} {f(y - 4)} {f(x + 4)} {f(y - 10)}" stroke="{ARROW}" stroke-width="1.8" fill="none"/>'
                f'<path d="M{f(x + 1)} {f(y - 12)} l6 -1 l-2 5 Z" fill="{ARROW}"/>')
    return (f'<path d="M{f(x + 4)} {f(y - 10)} Q{f(x + 15)} {f(y - 4)} {f(x + 12)} {f(y + 8)}" stroke="{ARROW}" stroke-width="1.8" fill="none"/>'
            f'<path d="M{f(x + 9)} {f(y + 10)} l6 0 l-2.5 -5 Z" fill="{ARROW}"/>')


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


# --------------------------------------------------------------------------
# The sky lift: a truck at the right, its boom up to a bucket at (bx, by).
# --------------------------------------------------------------------------

def truck(tilt=0, legs=True):
    o = [f'<g transform="rotate({tilt} 165 {GY})">',
         f'<rect x="132" y="{GY - 28}" width="48" height="18" rx="2" fill="{TRUCK}"/>',
         f'<path d="M178 {GY - 10} L178 {GY - 44} L192 {GY - 44} L198 {GY - 30} L198 {GY - 10} Z" fill="{TRUCK_D}"/>',
         f'<rect x="183" y="{GY - 40}" width="9" height="9" rx="1" fill="{GLASS}"/>',
         f'<circle cx="146" cy="{GY - 7}" r="7" fill="{TYRE}"/><circle cx="186" cy="{GY - 7}" r="7" fill="{TYRE}"/>',
         f'<rect x="152" y="{GY - 36}" width="14" height="9" rx="2" fill="{TRUCK_D}"/>']
    if legs:
        o.append(f'<path d="M136 {GY - 14} L130 {GY - 1} M176 {GY - 14} L170 {GY - 1}" stroke="{BUCKET_D}" stroke-width="3"/>'
                 f'<rect x="125" y="{GY - 2}" width="10" height="3" fill="{BUCKET_D}"/><rect x="165" y="{GY - 2}" width="10" height="3" fill="{BUCKET_D}"/>')
    o.append('</g>')
    return ''.join(o)


def lift(bx, by, hands, look=0, tilt=0, legs=True, face=-1):
    """Truck + boom + bucket (top-left (bx, by), 34 x 42) with the harnessed
    worker standing in it; his lanyard is clipped to the bucket rim."""
    o = [truck(tilt, legs)]
    o.append(f'<path d="M159 {GY - 32} L{bx + 26} {by + 40}" stroke="{BUCKET_D}" stroke-width="7" stroke-linecap="round"/>')
    o.append(f'<path d="M159 {GY - 32} L{bx + 26} {by + 40}" stroke="{BUCKET}" stroke-width="4" stroke-linecap="round"/>')
    wx = bx + 17
    gy = by + 4 + 30 * S
    o.append(worker(wx, hands, face=face, look=look, gy=gy, harness=True))
    hx, hy = hip_of(wx, gy)
    o.append(f'<path d="M{f(hx)} {f(hy - 6)} Q{f(bx + 30)} {f(by - 4)} {f(bx + 32)} {f(by + 2)}" stroke="{HARN}" stroke-width="1.6" fill="none"/>')
    o.append(f'<rect x="{bx}" y="{by}" width="34" height="42" rx="3" fill="{BUCKET}" stroke="{BUCKET_D}" stroke-width="1.4"/>')
    o.append(f'<path d="M{bx} {by + 5} L{bx + 34} {by + 5}" stroke="{BUCKET_D}" stroke-width="1.2"/>')
    return ''.join(o)


def pouch(bx, by):
    """The tool pouch on the bucket rim: a screwdriver handle sticks out."""
    return (screwdriver(bx + 6, by - 6, 0)
            + f'<rect x="{bx + 2}" y="{by + 6}" width="9" height="11" rx="1.5" fill="{CARTON_D}"/>')


def clipped_meter(bx, by):
    m, (r1x, r1y), (r2x, r2y) = multimeter(bx + 20, by + 7, 0.7)
    coil = ''.join(f'<path d="M{f(rx)} {f(ry)} q-3 6 2 8 q5 1 3 -4" stroke="{col}" stroke-width="1.2" fill="none"/>'
                   for rx, ry, col in ((r1x, r1y, LEAD_R), (r2x, r2y, LEAD_B)))
    return m + coil


BX, BY = 104, 96  # the bucket at the luminaire
HEAD = (40, 104)


# --------------------------------------------------------------------------
# Round 1 — the light does not come on: start with the supply.
# --------------------------------------------------------------------------

def small_light(x, top=96):
    return (f'<rect x="{x - 2.5}" y="{top}" width="5" height="{GY - top}" fill="url(#steel)"/>'
            f'<path d="M{x} {top + 3} Q{x} {top - 4} {x + 10} {top - 3} L{x + 18} {top - 2}" stroke="{HOUSING_D}" stroke-width="3" fill="none"/>'
            f'<path d="M{x + 14} {top - 4} Q{x + 24} {top - 10} {x + 34} {top - 2} L{x + 34} {top + 2} L{x + 14} {top + 2} Z" fill="{HOUSING}"/>'
            f'<path d="M{x + 16} {top + 2} Q{x + 24} {top + 7} {x + 32} {top + 2} Z" fill="{GLASS}"/>')


def pillar(open_=False):
    """The feeder pillar on the pavement, with the group controller inside."""
    x, y = 112, 134
    o = [f'<rect x="{x}" y="{y}" width="40" height="{GY - 4 - y}" rx="3" fill="{PILLAR}"/>']
    if open_:
        o.append(f'<rect x="{x + 4}" y="{y + 6}" width="32" height="48" rx="1" fill="{FACE}"/>')
        o.append(gear_box(x + 20, y + 16, 1.2))
        o.append(f'<rect x="{x + 9}" y="{y + 30}" width="9" height="16" rx="1" fill="{FUSE}"/><rect x="{x + 22}" y="{y + 30}" width="9" height="16" rx="1" fill="{FUSE}"/>')
        o.append(f'<path d="M{x + 40} {y + 4} L{x + 56} {y + 10} L{x + 56} {y + 58} L{x + 40} {y + 56} Z" fill="{PILLAR_D}"/>')
    else:
        o.append(f'<rect x="{x + 4}" y="{y + 6}" width="32" height="48" rx="1" fill="{PILLAR_D}"/>')
        o.append(f'<rect x="{x + 30}" y="{y + 26}" width="3" height="10" rx="1" fill="{FUSE}"/>')
    return ''.join(o)


def dark_card(kind):
    out = card_open('night')
    out.append(sky('night'))
    out.append(road())
    if kind in ('area', 'one'):
        for x in (14, 70, 150):
            out.append(small_light(x, 96 if x != 70 else 100))
        out.append(pillar(open_=(kind == 'area')))
        if kind == 'area':
            out.append(worker(98, ((112, 162), (128, 152)), face=1, look=4))
        else:
            out.append(worker(92, ((104, 150), (80, 160)), face=-1, look=-6))
            out.append(hpsv(104, 140, 0, 0.9))
        return card_close(out)
    out.append(street_light(head=HEAD, open_=True))
    if kind == 'volt':
        tips = ((56, 52), (64, 52))
        out.append(lift(BX, BY, (tips[0], (98, 74)), look=-6))
        m, r1, r2 = multimeter(91, 64, 1.0)
        out.append(leads((r1, r2), tips))
        out.append(m)
    elif kind == 'gear':
        out.append(lift(BX, BY, ((60, 60), (74, 58)), look=-4))
        out.append(gear_box(66, 56, 1.1))
        out.append(clipped_meter(BX, BY))
    elif kind == 'cell':
        out.append(lift(BX, BY, ((86, 26), (100, 40)), look=10))
        out.append(photocell(92, 18, -25))
        out.append(clipped_meter(BX, BY))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — burning day and night: the photocell.
# --------------------------------------------------------------------------

def day_card(kind):
    out = card_open('day')
    out.append(sky('day'))
    out.append(road())
    turn = {'sky': -40, 'down': 0}.get(kind, -40 if kind != 'down' else 0)
    if kind == 'sky':
        turn = 35  # tilted, being turned back up
    elif kind == 'down':
        turn = 0
    else:
        turn = 0
    out.append(street_light(head=HEAD, dirty=(kind != 'clean'), turn=turn, open_=(kind in ('lamp', 'gear'))))
    out.append(pole_box(on=False))
    cx, cy = HEAD[1] - 10, 40 - 18
    if kind == 'clean':
        out.append(lift(BX, BY, ((cx + 4, cy + 2), (cx + 8, cy + 14)), look=12))
        out.append(rag(cx + 1, cy - 1))
    elif kind == 'sky':
        out.append(lift(BX, BY, ((cx + 5, cy + 4), (cx + 9, cy + 14)), look=12))
        out.append(turn_arrow(cx, cy, up=True))
        out.append(rag(BX + 24, BY + 6))
    elif kind == 'down':
        out.append(lift(BX, BY, ((cx + 5, cy + 4), (cx + 9, cy + 14)), look=12))
        out.append(turn_arrow(cx, cy, up=False))
        out.append(rag(BX + 24, BY + 6))
    elif kind == 'lamp':
        out.append(lift(BX, BY, ((66, 58), (80, 70)), look=-4))
        out.append(hpsv(68, 50, 20, 1.0))
        out.append(rag(BX + 24, BY + 6))
    elif kind == 'gear':
        out.append(lift(BX, BY, ((60, 60), (74, 58)), look=-4))
        out.append(gear_box(66, 56, 1.1))
        out.append(rag(BX + 24, BY + 6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — on, off, on: an old sodium lamp or a loose connection.
# --------------------------------------------------------------------------

def cycle_card(kind):
    out = card_open('night')
    out.append(sky('night'))
    out.append(road())
    out.append(street_light(head=HEAD, open_=(kind != 'cell')))
    out.append(pole_box(on=False))
    if kind == 'lamp':
        out.append(lift(BX, BY, ((66, 58), (80, 70)), look=-4))
        out.append(hpsv(68, 50, 20, 1.0))
        out.append(carton(BX + 4, BY - 10))
        out.append(pouch(BX + 20, BY - 8))
    elif kind == 'tight':
        tip = (54, 52)
        out.append(lift(BX, BY, ((60, 64), (82, 70)), look=-6))
        out.append(screwdriver(tip[0], tip[1], -38))
        out.append(carton(BX + 4, BY - 10, lamp=False))
    elif kind == 'cell':
        out.append(lift(BX, BY, ((86, 26), (100, 40)), look=10))
        out.append(photocell(92, 18, -25))
        out.append(pouch(BX + 20, BY - 8))
    elif kind == 'any':
        out.append(lift(BX, BY, ((56, 62), (78, 62)), look=-4))
        out.append(gear_box(66, 58, 1.6))
        out.append(gear_box(BX + 9, BY - 4, 0.8))
        out.append(gear_box(BX + 26, BY - 5, 1.0))
        out.append(pouch(BX + 20, BY - 30))
    elif kind == 'dump':
        out.append(lift(BX, BY, ((90, 92), (82, 72)), look=-20))
        out.append(hpsv(74, 150, 140, 1.0))
        out.append(f'<rect x="58" y="{GY - 4}" width="40" height="6" rx="2" fill="{DRAIN}"/>')
        out.append(hpsv(84, GY - 8, 70, 0.8, broken=True))
        out.append(carton(BX + 4, BY - 10, lamp=False))
        out.append(pouch(BX + 20, BY - 8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — before the lamp comes out: switch off, then prove it dead.
# --------------------------------------------------------------------------

def isolate_card(kind):
    out = card_open('night')
    out.append(sky('night'))
    out.append(road())
    out.append(street_light(head=HEAD, open_=True))
    on = kind == 'live'
    out.append(pole_box(on=on, fuse_out=(kind == 'fuse')))
    if kind == 'mcb':
        out.append(lift(BX, BY, ((58, 58), (84, 74)), look=-6))
        out.append(tester(58, 52, glow=False))
    elif kind == 'glow':
        out.append(lift(BX, BY, ((58, 58), (62, 56)), look=-6))
        out.append(tester(58, 52, glow=True))
    elif kind == 'fuse':
        tips = ((56, 52), (64, 52))
        out.append(lift(BX, BY, (tips[0], (98, 74)), look=-6))
        m, r1, r2 = multimeter(91, 64, 1.0)
        out.append(leads((r1, r2), tips))
        out.append(m)
        out.append(fuse_in_hand(BX + 8, BY + 14))
    elif kind in ('live', 'notest'):
        out.append(lift(BX, BY, ((60, 56), (66, 56)), look=-6))
        out.append(clipped_meter(BX, BY))
        out.append(tester(BX + 6, BY - 4, glow=False, ang=0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — the platform: stable, secured, clear of overhead lines.
# --------------------------------------------------------------------------

def overhead():
    return (f'<path d="M0 14 L200 10 M0 22 L200 18" stroke="{WIRE}" stroke-width="1.6"/>'
            f'<rect x="186" y="6" width="6" height="22" fill="url(#steel)"/>')


def ladder(foot, top, stone=False, lashed=False):
    (fx, fy), (tx, ty) = foot, top
    o = []
    for d in (-6, 6):
        o.append(f'<path d="M{f(fx + d)} {f(fy)} L{f(tx + d * 0.6)} {f(ty)}" stroke="{WOOD}" stroke-width="3" stroke-linecap="round"/>')
    for i in range(1, 9):
        t = i / 9
        x, y = fx + (tx - fx) * t, fy + (ty - fy) * t
        o.append(f'<path d="M{f(x - 6 + 2.4 * t)} {f(y)} L{f(x + 6 - 2.4 * t)} {f(y)}" stroke="{WOOD}" stroke-width="2"/>')
    if lashed:
        o.append(f'<path d="M{f(tx - 8)} {f(ty + 6)} L{f(tx + 8)} {f(ty + 2)} M{f(tx - 8)} {f(ty + 10)} L{f(tx + 8)} {f(ty + 6)}" stroke="{ROPE}" stroke-width="2"/>')
    return ''.join(o)


def platform_card(kind):
    out = card_open('night')
    out.append(sky('night'))
    out.append(overhead())
    out.append(road())
    out.append(street_light(head=HEAD))
    if kind == 'lift':
        out.append(lift(BX, BY, ((92, 56), (98, 70)), look=-4))
    elif kind == 'near':
        bx, by = 120, 52
        out.append(lift(bx, by, ((128, 12), (150, 30)), look=16))
        out.append(spark(132, 14, 0.9))
    elif kind == 'tilt':
        out.append(f'<path d="M110 {GY - 4} Q150 {GY - 26} 200 {GY - 22} L200 {GY + 2} L110 {GY + 2} Z" fill="{STONE}"/>')
        out.append(f'<g transform="rotate(-9 165 {GY})">' + lift(BX + 6, BY + 4, ((92, 64), (102, 76)), look=-4, legs=False) + '</g>')
    else:
        slope = kind == 'slope'
        foot = (86, GY - 6) if not slope else (90, GY - 12)
        top = (40, 66)
        if slope:
            out.append(f'<ellipse cx="94" cy="{GY - 8}" rx="8" ry="5" fill="{STONE}"/>')
            out.append(f'<g transform="rotate(7 88 {GY})">')
        out.append(ladder(foot, top, lashed=not slope))
        gy = 140
        out.append(worker(68, ((56, 52), (64, 54)), face=-1, look=-10, gy=gy, harness=True))
        hx, hy = hip_of(68, gy)
        out.append(f'<path d="M{f(hx)} {f(hy - 6)} Q{f(hx - 14)} {f(hy - 2)} 38 {f(hy - 10)}" stroke="{HARN}" stroke-width="1.6" fill="none"/>')
        if slope:
            out.append('</g>')
            out.append(f'<path d="M118 {GY - 4} q4 -4 8 0 q4 4 8 0" stroke="{ROPE}" stroke-width="2" fill="none"/>')
            out.append(f'<path d="M108 120 l6 -2 M110 128 l7 0 M108 136 l6 2" stroke="{ARROW}" stroke-width="1.6" stroke-linecap="round"/>')
    return card_close(out)


CARDS = {
    'dark_volt': dark_card('volt'),
    'dark_area': dark_card('area'),
    'dark_gear': dark_card('gear'),
    'dark_cell': dark_card('cell'),
    'dark_one': dark_card('one'),
    'day_clean': day_card('clean'),
    'day_sky': day_card('sky'),
    'day_lamp': day_card('lamp'),
    'day_gear': day_card('gear'),
    'day_down': day_card('down'),
    'cycle_lamp': cycle_card('lamp'),
    'cycle_tight': cycle_card('tight'),
    'cycle_cell': cycle_card('cell'),
    'cycle_any': cycle_card('any'),
    'cycle_dump': cycle_card('dump'),
    'isolate_mcb': isolate_card('mcb'),
    'isolate_fuse': isolate_card('fuse'),
    'isolate_live': isolate_card('live'),
    'isolate_notest': isolate_card('notest'),
    'isolate_glow': isolate_card('glow'),
    'platform_lift': platform_card('lift'),
    'platform_ladder': platform_card('ladder'),
    'platform_near': platform_card('near'),
    'platform_slope': platform_card('slope'),
    'platform_tilt': platform_card('tilt'),
}

# Safe cards and traps per round (mirrors learn_board_pack49.dart).
ROUNDS = {
    'dark': (['dark_volt', 'dark_area'], ['dark_gear', 'dark_cell', 'dark_one']),
    'day': (['day_clean', 'day_sky'], ['day_lamp', 'day_gear', 'day_down']),
    'cycle': (['cycle_lamp', 'cycle_tight'], ['cycle_cell', 'cycle_any', 'cycle_dump']),
    'isolate': (['isolate_mcb', 'isolate_fuse'], ['isolate_live', 'isolate_notest', 'isolate_glow']),
    'platform': (['platform_lift', 'platform_ladder'], ['platform_near', 'platform_slope', 'platform_tilt']),
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
