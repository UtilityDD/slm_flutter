"""Picture cards for lesson 5.9 শেখা ("কেবিল ফল্ট খোঁজার প্রাথমিক ধারণা").

python -I tool/m5_board59_art.py .

Writes assets/game/art/m5_board59/*.svg in the same clean gradient style as
tool/m4_board410_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: meter readings are segment glyphs and dial marks drawn as paths,
never <text>. The three cores are told by their R / Y / B colours only.

What the cards show comes from lesson 5.9 only:
  1. cause: the common causes of a UG cable fault — a digging machine hitting
     the cable (the most common), moisture getting into a joint, rats or
     termites cutting the sheath; the cable is safe from the weather (storm,
     a branch on the overhead wires), and a dry, well-made joint is no cause;
  2. short: a megger reading of zero (or very low) between two cores (R, Y)
     = short circuit; a high reading = no short; core-to-armour low = earth
     fault; no continuity beep across a core's two ends = open circuit;
  3. earth: a low megger reading between one core (Y) and the armour = earth
     fault; core-to-core low = short; a high core-to-armour reading = no earth
     fault; continuity end to end checks for a cut core;
  4. route: walk along the cable route (with the route map) and look for
     fresh digging, wet or burnt patches; open the joint pits and look for
     burn marks; a hole off the route is not this cable's clue, walking past
     a shut pit misses it, and no route map is "throwing stones in the dark";
  5. locate: the TDR tells the fault's distance in metres; the thumper's
     surge makes a 'thump' at the fault, heard with a special microphone;
     before digging, ask about other underground lines (ruling M5-7: call the
     underground-service owners); never trench the whole route, never dig
     without asking, and UG fault work is a specialist team's job (myth 2).

Fairness (the playbook, section 4): every card in a round shares one
backdrop and one scene, and props reuse the scene's colours; the script
checks every hand the dealer can make (one safe card + any three traps):
each colour or gradient the safe card draws is drawn by a trap in that hand,
and the safe card's backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m5_board59_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm5_board59')
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
PH_R = '#D8402F'
PH_Y = '#F0C02E'
PH_B = '#2F6BCB'
LEAD_B = '#1C1F24'
LCD_INK = '#1E2A1E'
CASE_D = '#2A2F36'
KNOB = '#6F777E'
DIAL = '#F4F1E8'
PAPER = '#F4F1E8'
INK = '#5B6670'
TAG = '#E53935'
DROP = '#9CC8E8'
SCORCH = '#2A2420'
SOIL_D = '#5E4630'
SOIL_L = '#9C7B56'
GRASS = '#5E8F3E'
ROOT_C = '#C9A27A'
ROCK = '#7D7F86'
EXC = '#F2B21B'
EXC_D = '#C98C10'
LEAF = '#3E7A34'
BARK = '#6B4A2E'
CLOUD = '#4A5260'
HARNESS = '#E8742A'
LED_G = '#4CD964'
WHITE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="cut" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7DB6DE"/><stop offset="0.44" stop-color="#CFE6F2"/><stop offset="0.44" stop-color="#8A6A48"/><stop offset="1" stop-color="#5C4530"/></linearGradient>
  <linearGradient id="kiosk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3C4A57"/><stop offset="0.62" stop-color="#5D6E7C"/><stop offset="0.62" stop-color="#8A6E4C"/><stop offset="1" stop-color="#6E5638"/></linearGradient>
  <linearGradient id="field" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8CC3E8"/><stop offset="0.3" stop-color="#D7ECF6"/><stop offset="0.3" stop-color="#8FA35E"/><stop offset="1" stop-color="#6E8445"/></linearGradient>
  <linearGradient id="site" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8B07E"/><stop offset="0.32" stop-color="#F6DDB8"/><stop offset="0.32" stop-color="#9AA066"/><stop offset="1" stop-color="#76804A"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="sheath" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A535C"/><stop offset="0.5" stop-color="#2B3138"/><stop offset="1" stop-color="#1A1E23"/></linearGradient>
  <linearGradient id="armour" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6EBEF"/><stop offset="0.5" stop-color="#A9B3BB"/><stop offset="1" stop-color="#6E7880"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2B07A"/><stop offset="0.5" stop-color="#C9783A"/><stop offset="1" stop-color="#8E4E22"/></linearGradient>
  <linearGradient id="case" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B64A"/><stop offset="1" stop-color="#C98622"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C7DEB2"/><stop offset="1" stop-color="#A9C795"/></linearGradient>
  <linearGradient id="concrete" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9AA3A8"/><stop offset="0.5" stop-color="#C9D0D4"/><stop offset="1" stop-color="#8A9398"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#5E7A6C"/><stop offset="0.5" stop-color="#7E9C8C"/><stop offset="1" stop-color="#557062"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#C9E6FF"/><stop offset="1" stop-color="#7FB8FF" stop-opacity="0"/></radialGradient>
  <radialGradient id="scorch" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1A1410"/><stop offset="0.6" stop-color="#3A2C22" stop-opacity="0.85"/><stop offset="1" stop-color="#3A2C22" stop-opacity="0"/></radialGradient>
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
# The worker (copied from tool/m4_board410_art.py): one figure, any pose.
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


def figure(hip, sh, head, feet, hands, face=1, look=0, phones=False, harness=False, props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black gloves.
    phones = ear defenders/headphones; harness = orange body harness straps."""
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
        g.append(f'<path d="M{f(sh[0] - px * 0.7)} {f(sh[1])} L{f(hip[0] + px * 0.6)} {f(hip[1] - 2)} M{f(sh[0] + px * 0.7)} {f(sh[1])} '
                 f'L{f(hip[0] - px * 0.6)} {f(hip[1] - 2)}" stroke="{HARNESS}" stroke-width="2.2" fill="none"/>'
                 f'<path d="M{f(hip[0] - px)} {f(hip[1] - 2)} L{f(hip[0] + px)} {f(hip[1] - 2)}" stroke="{HARNESS}" stroke-width="2.6"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if phones:
        hd.append(f'<path d="M{f(hx - 6)} {f(hy - 2)} Q{f(hx)} {f(hy - 11)} {f(hx + 6)} {f(hy - 2)}" stroke="{BOOT}" stroke-width="1.8" fill="none"/>'
                  f'<rect x="{f(hx - 3 * face - 2.5)}" y="{f(hy - 2)}" width="5" height="7" rx="2" fill="{BOOT}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, gy=GY, phones=False, harness=False, crouch=0.0, props=''):
    """A standing worker at x (feet on gy), scaled S about his feet; the hands
    are given in card coordinates. crouch (0..1) bends the knees."""
    def local(p):
        return (x + (p[0] - x) / S, gy + (p[1] - gy) / S)
    hip = (x - 3 * face * crouch, gy - 30 + 9 * crouch)
    sh = (x + (1 + 6 * crouch) * face, gy - 56 + 12 * crouch)
    head = (x + (3 + 7 * crouch) * face, gy - 64 + 12 * crouch)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    if props:
        props = f'<g transform="translate({f(x)} {f(gy)}) scale({f(1 / S)}) translate({f(-x)} -{f(gy)})">{props}</g>'
    fig = figure(hip, sh, head, feet, hands, face, look, phones, harness, props)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({S}) translate({f(-x)} -{f(gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Shared things.
# --------------------------------------------------------------------------

def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#C9E6FF" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="{WHITE}"/>')


def drops(x, y, span, n=7):
    out = []
    for k in range(n):
        dx = x + (k * 37 % 97) / 97 * span
        dy = y - (k * 23 % 31) * 0.6
        out.append(f'<path d="M{f(dx)} {f(dy)} q2.6 4.4 0 6.2 q-2.6 -1.8 0 -6.2 Z" fill="{DROP}"/>')
    return ''.join(out)


def puddle(cx, cy, rx):
    return f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(rx * 0.22)}" fill="{DROP}" opacity="0.7"/>'


def route_post(x, y, s=1.0):
    """A concrete cable-route marker post with a yellow cap band."""
    return (f'<rect x="{f(x - 4 * s)}" y="{f(y - 16 * s)}" width="{f(8 * s)}" height="{f(16 * s)}" rx="{f(1.5 * s)}" fill="url(#concrete)"/>'
            f'<rect x="{f(x - 4 * s)}" y="{f(y - 16 * s)}" width="{f(8 * s)}" height="{f(4 * s)}" rx="{f(1.5 * s)}" fill="{EXC}"/>'
            f'<path d="M{f(x - 2.5 * s)} {f(y - 8 * s)} l{f(2.5 * s)} {f(-2.5 * s)} l{f(2.5 * s)} {f(2.5 * s)}" stroke="{TAG}" stroke-width="{f(1.2 * s)}" fill="none"/>')


def mound(cx, cy, w, h=None):
    h = h if h is not None else w * 0.45
    return (f'<path d="M{f(cx - w / 2)} {f(cy)} Q{f(cx - w / 4)} {f(cy - h)} {f(cx)} {f(cy - h)} Q{f(cx + w / 4)} {f(cy - h)} {f(cx + w / 2)} {f(cy)} Z" fill="{SOIL_D}"/>'
            f'<circle cx="{f(cx - w / 6)}" cy="{f(cy - h * 0.55)}" r="{f(max(1.2, w * 0.04))}" fill="{SOIL_L}"/>'
            f'<circle cx="{f(cx + w / 5)}" cy="{f(cy - h * 0.35)}" r="{f(max(1.2, w * 0.035))}" fill="{SOIL_L}"/>')


def hole(cx, cy, rx, ry=None):
    ry = ry if ry is not None else rx * 0.32
    return (f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx + 2)}" ry="{f(ry + 1.5)}" fill="{SOIL_D}"/>'
            f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(ry)}" fill="{SCORCH}"/>')


def spade(x0, y0, x1, y1):
    """A spade: handle from (x0, y0) to the blade at (x1, y1)."""
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    ux, uy = dx / n, dy / n
    nx, ny = -uy, ux
    b0 = (x1 - ux * 10, y1 - uy * 10)
    return (f'<path d="M{f(x0)} {f(y0)} L{f(b0[0])} {f(b0[1])}" stroke="{BARK}" stroke-width="2.6" stroke-linecap="round"/>'
            f'<path d="M{f(b0[0] + nx * 5)} {f(b0[1] + ny * 5)} L{f(x1 + nx * 4)} {f(y1 + ny * 4)} Q{f(x1 + ux * 3)} {f(y1 + uy * 3)} '
            f'{f(x1 - nx * 4)} {f(y1 - ny * 4)} L{f(b0[0] - nx * 5)} {f(b0[1] - ny * 5)} Z" fill="url(#armour)"/>')


def paper_map(cx, cy, s=1.0, ang=0):
    """The cable route map: a sheet with the route drawn on it."""
    return (f'<g transform="translate({f(cx)} {f(cy)}) rotate({f(ang)}) scale({f(s)})">'
            f'<rect x="-11" y="-8" width="22" height="16" rx="1.2" fill="{PAPER}"/>'
            f'<path d="M-8 5 L-3 0 L2 2 L8 -5" stroke="{TAG}" stroke-width="1.4" fill="none"/>'
            f'<path d="M-9 -5 L-2 -5 M-9 -2 L-5 -2" stroke="{INK}" stroke-width="0.9"/></g>')


def phone(cx, cy, ang=0, s=1.0):
    return (f'<g transform="translate({f(cx)} {f(cy)}) rotate({f(ang)}) scale({f(s)})">'
            f'<rect x="-3.4" y="-6" width="6.8" height="12" rx="1.4" fill="{CASE_D}"/>'
            f'<rect x="-2.4" y="-4.6" width="4.8" height="8" rx="0.6" fill="url(#lcd)"/>'
            f'<path d="M-1.4 -2.4 L1.4 -2.4 M-1.4 -0.6 L1.4 -0.6" stroke="{LCD_INK}" stroke-width="0.6"/></g>')


# --------------------------------------------------------------------------
# Segment glyphs for meter displays (copied from tool/m2_board27_art.py).
# --------------------------------------------------------------------------

SEG = {'0': 'abcdef', '1': 'bc', '-': 'g'}


def glyph(ch, x, y, w, h, ink=LCD_INK):
    t = max(1.2, w * 0.2)
    if ch in SEG:
        segs = {
            'a': (x, y, w, t), 'd': (x, y + h - t, w, t), 'g': (x, y + h / 2 - t / 2, w, t),
            'f': (x, y, t, h / 2), 'e': (x, y + h / 2, t, h / 2),
            'b': (x + w - t, y, t, h / 2), 'c': (x + w - t, y + h / 2, t, h / 2),
        }
        s = ''.join(f'<rect x="{f(sx)}" y="{f(sy)}" width="{f(sw)}" height="{f(sh)}" rx="0.4"/>'
                    for sx, sy, sw, sh in (segs[k] for k in SEG[ch]))
        return f'<g fill="{ink}">{s}</g>', w + t * 1.6
    sw = f(t * 0.9)
    if ch == '.':
        return f'<circle cx="{f(x + t / 2)}" cy="{f(y + h - t / 2)}" r="{f(t * 0.6)}" fill="{ink}"/>', t * 2.2
    if ch == 'M':
        return (f'<path d="M{f(x)} {f(y + h)} L{f(x)} {f(y)} L{f(x + w / 2)} {f(y + h * 0.6)} L{f(x + w)} {f(y)} L{f(x + w)} {f(y + h)}" '
                f'stroke="{ink}" stroke-width="{sw}" fill="none" stroke-linejoin="round"/>', w + t * 1.8)
    if ch == 'O':  # Ω
        return (f'<path d="M{f(x)} {f(y + h)} L{f(x + w * 0.32)} {f(y + h)} L{f(x + w * 0.32)} {f(y + h * 0.8)} '
                f'A{f(w * 0.48)} {f(h * 0.45)} 0 1 1 {f(x + w * 0.68)} {f(y + h * 0.8)} L{f(x + w * 0.68)} {f(y + h)} L{f(x + w)} {f(y + h)}" '
                f'stroke="{ink}" stroke-width="{sw}" fill="none" stroke-linejoin="round"/>', w + t * 1.8)
    if ch == ' ':
        return '', w * 0.5
    raise ValueError(ch)


def readout(s, x, y, h, ink=LCD_INK):
    w = h * 0.55
    out, cx = [], x
    for ch in s:
        g, adv = glyph(ch, cx, y, w, h, ink)
        out.append(g)
        cx += adv
    return ''.join(out), cx - x


def infinity(cx, cy, r, ink=LCD_INK, sw=2.0):
    return (f'<path d="M{f(cx)} {f(cy)} C{f(cx + r * 0.6)} {f(cy - r * 0.9)} {f(cx + r * 1.6)} {f(cy - r * 0.9)} {f(cx + r * 1.6)} {f(cy)} '
            f'C{f(cx + r * 1.6)} {f(cy + r * 0.9)} {f(cx + r * 0.6)} {f(cy + r * 0.9)} {f(cx)} {f(cy)} '
            f'C{f(cx - r * 0.6)} {f(cy - r * 0.9)} {f(cx - r * 1.6)} {f(cy - r * 0.9)} {f(cx - r * 1.6)} {f(cy)} '
            f'C{f(cx - r * 1.6)} {f(cy + r * 0.9)} {f(cx - r * 0.6)} {f(cy + r * 0.9)} {f(cx)} {f(cy)} Z" stroke="{ink}" stroke-width="{f(sw)}" fill="none"/>')


# --------------------------------------------------------------------------
# Round 1 — cause: a cutaway of the street, the UG cable in the soil below
# and an overhead line above.
# --------------------------------------------------------------------------

CUT_Y = 97      # the ground line on the cutaway
CABLE_Y = 172   # the buried cable's centre


def cutaway(storm=False, branch=False):
    out = card_open('cut')
    out.append(f'<rect x="0" y="{CUT_Y - 3}" width="200" height="5" fill="{GRASS}"/>')
    # Roots and stones in the soil (the same on every card).
    for x, y, r in ((22, 128, 3.2), (150, 134, 2.6), (182, 206, 3.4), (64, 204, 2.4)):
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="{r * 1.4}" ry="{r}" fill="{ROCK}"/>')
    for x in (40, 118, 172):
        out.append(f'<path d="M{x} {CUT_Y + 2} q-3 9 2 16 q4 6 -1 12" stroke="{ROOT_C}" stroke-width="1.2" fill="none"/>')
    # The overhead line: two poles, a cross-arm each, three wires.
    sway = 9 if storm else 0
    tilt = 4 if storm else 0
    for x in (26, 174):
        t = tilt if x < 100 else -tilt
        out.append(f'<g transform="rotate({t} {x} {CUT_Y})"><rect x="{x - 3}" y="18" width="6" height="{CUT_Y - 18}" fill="url(#concrete)"/>'
                   f'<rect x="{x - 15}" y="24" width="30" height="3.4" fill="{WIRE}"/>'
                   + ''.join(f'<rect x="{x + dx - 1.6}" y="19" width="3.2" height="5" rx="1" fill="{DIAL}"/>' for dx in (-12, 0, 12))
                   + '</g>')
    for k, dx in enumerate((-12, 0, 12)):
        y0 = 21
        sag = 14 + sway * (1 if k != 1 else -0.6)
        out.append(f'<path d="M{26 + dx} {y0} Q100 {y0 + sag + (k - 1) * 3} {174 + dx} {y0}" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
    # A route post on the street over the cable.
    out.append(route_post(150, CUT_Y))
    # The buried cable.
    out.append(f'<rect x="-6" y="{CABLE_Y - 7}" width="212" height="14" rx="7" fill="url(#sheath)"/>')
    out.append(f'<path d="M-6 {CABLE_Y - 4} L206 {CABLE_Y - 4}" stroke="#4A535C" stroke-width="1.4"/>')
    out.append(cable_face())
    if storm:
        out.append(f'<ellipse cx="64" cy="14" rx="40" ry="12" fill="{CLOUD}"/><ellipse cx="120" cy="10" rx="44" ry="13" fill="{CLOUD}"/>')
        for y in (40, 56, 70):
            out.append(f'<path d="M{18 + y % 30} {y} q20 -5 40 0 t40 0" stroke="{WHITE}" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.8"/>')
        out.append(drops(30, 82, 140, n=9))
        out.append(spark(100, 42, 0.8))
    if branch:
        out.append(f'<path d="M62 6 L138 46" stroke="{BARK}" stroke-width="5" stroke-linecap="round"/>'
                   f'<path d="M92 22 L104 8 M116 34 L132 30" stroke="{BARK}" stroke-width="2.6" stroke-linecap="round"/>')
        for x, y in ((66, 4), (104, 6), (134, 28), (124, 40), (80, 14)):
            out.append(f'<ellipse cx="{x}" cy="{y}" rx="7" ry="4" fill="{LEAF}" transform="rotate(-25 {x} {y})"/>')
    return out


def cable_face():
    """The cable's cut face at the left edge: sheath, the three cores."""
    return (f'<ellipse cx="10" cy="{CABLE_Y}" rx="6" ry="9" fill="#4A535C"/>'
            f'<circle cx="9" cy="{CABLE_Y - 4}" r="2.2" fill="{PH_R}"/><circle cx="12" cy="{CABLE_Y + 1}" r="2.2" fill="{PH_Y}"/>'
            f'<circle cx="8" cy="{CABLE_Y + 4.5}" r="2.2" fill="{PH_B}"/>')


def joint_box(cx, cy=CABLE_Y, cracked=False):
    s = (f'<rect x="{cx - 22}" y="{cy - 12}" width="44" height="24" rx="10" fill="{PANTS}"/>'
         f'<rect x="{cx - 22}" y="{cy - 12}" width="44" height="6" rx="3" fill="#4A535C"/>'
         f'<path d="M{cx - 14} {cy - 12} L{cx - 14} {cy + 12} M{cx + 14} {cy - 12} L{cx + 14} {cy + 12}" stroke="{BOOT}" stroke-width="1.4"/>')
    if cracked:
        s += (f'<path d="M{cx - 4} {cy - 12} l3 6 l-3 4 l4 5" stroke="{BOOT}" stroke-width="1.6" fill="none"/>'
              f'<path d="M{cx + 6} {cy - 12} l-2 5 l3 4" stroke="{BOOT}" stroke-width="1.4" fill="none"/>')
    return s


def excavator(arm_to=None):
    """A yellow digging machine on the street; its arm reaches arm_to (the
    bucket teeth) or is folded."""
    s = [f'<rect x="8" y="{CUT_Y - 10}" width="54" height="9" rx="4.5" fill="{WIRE}"/>',
         ''.join(f'<circle cx="{14 + k * 10.5}" cy="{CUT_Y - 5.5}" r="3" fill="{ROCK}"/>' for k in range(5)),
         f'<rect x="12" y="{CUT_Y - 30}" width="44" height="20" rx="3" fill="{EXC}"/>',
         f'<rect x="16" y="{CUT_Y - 48}" width="22" height="20" rx="3" fill="{EXC}"/>',
         f'<rect x="19" y="{CUT_Y - 45}" width="16" height="11" rx="1.5" fill="#CFE6F2"/>',
         f'<rect x="12" y="{CUT_Y - 14}" width="44" height="4" fill="{EXC_D}"/>']
    if arm_to:
        bx, by = arm_to
        ex, ey = 82, CUT_Y - 56
        s.append(f'<path d="M50 {CUT_Y - 28} L{ex} {ey}" stroke="{EXC}" stroke-width="7" stroke-linecap="round"/>')
        s.append(f'<path d="M{ex} {ey} L{bx} {by - 14}" stroke="{EXC_D}" stroke-width="5.5" stroke-linecap="round"/>')
        s.append(f'<path d="M{bx - 9} {by - 18} L{bx + 8} {by - 18} L{bx + 6} {by} L{bx - 4} {by - 2} Z" fill="{EXC}"/>')
        s.append(''.join(f'<path d="M{bx - 3 + k * 4} {by - 1} l1 4" stroke="{WIRE}" stroke-width="1.6"/>' for k in range(3)))
    else:
        s.append(f'<path d="M50 {CUT_Y - 28} L70 {CUT_Y - 44} L76 {CUT_Y - 14}" stroke="{EXC}" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    return ''.join(s)


def cause_card(kind):
    out = cutaway(storm=kind == 'storm', branch=kind == 'branch')
    if kind == 'dig':
        # A trench cut from the street down to the cable, the bucket on it.
        out.append(f'<path d="M92 {CUT_Y} L128 {CUT_Y} L122 {CABLE_Y + 10} L98 {CABLE_Y + 10} Z" fill="{SOIL_D}"/>')
        out.append(f'<rect x="-6" y="{CABLE_Y - 7}" width="212" height="14" rx="7" fill="url(#sheath)"/>')
        out.append(cable_face())
        out.append(excavator(arm_to=(110, CABLE_Y - 6)))
        out.append(mound(78, CUT_Y - 1, 26))
        out.append(spark(112, CABLE_Y - 4, 0.9))
    elif kind == 'joint':
        out.append(excavator())
        out.append(joint_box(110, cracked=True))
        out.append(drops(96, CABLE_Y - 30, 30, n=6))
        out.append(f'<path d="M100 {CUT_Y + 6} q-4 14 2 28 q5 12 2 24" stroke="{DROP}" stroke-width="2" fill="none" opacity="0.8"/>')
        out.append(f'<path d="M122 {CUT_Y + 6} q4 16 -2 30 q-4 10 0 20" stroke="{DROP}" stroke-width="2" fill="none" opacity="0.8"/>')
        out.append(puddle(110, CABLE_Y + 18, 26))
    elif kind == 'rat':
        out.append(excavator())
        # A gnawed notch in the sheath, the core colours showing.
        out.append(f'<path d="M98 {CABLE_Y - 7} q4 6 8 1 q4 6 8 0 l0 6 l-16 0 Z" fill="{SOIL_L}"/>')
        out.append(f'<rect x="100" y="{CABLE_Y - 3}" width="4" height="4" fill="{PH_R}"/><rect x="105" y="{CABLE_Y - 3}" width="4" height="4" fill="{PH_Y}"/>'
                   f'<rect x="110" y="{CABLE_Y - 3}" width="4" height="4" fill="{PH_B}"/>')
        # The rat, nose to the notch.
        out.append(f'<ellipse cx="132" cy="{CABLE_Y - 16}" rx="15" ry="8" fill="{ROCK}"/>'
                   f'<path d="M118 {CABLE_Y - 18} L106 {CABLE_Y - 9} L120 {CABLE_Y - 10} Z" fill="{ROCK}"/>'
                   f'<circle cx="122" cy="{CABLE_Y - 22}" r="3.6" fill="{ROCK}"/><circle cx="115" cy="{CABLE_Y - 15}" r="1.2" fill="{BOOT}"/>'
                   f'<path d="M146 {CABLE_Y - 14} q14 4 18 -8 q2 -8 10 -6" stroke="{ROOT_C}" stroke-width="1.6" fill="none"/>')
        for k in range(6):
            out.append(f'<ellipse cx="{60 + k * 7}" cy="{CABLE_Y + 11 + (k % 2) * 2}" rx="2" ry="1.2" fill="{ROOT_C}"/>')
    elif kind == 'storm':
        out.append(excavator())
        out.append(joint_box(110))
    elif kind == 'dry':
        out.append(excavator())
        out.append(joint_box(110))
        out.append(mound(78, CUT_Y - 1, 26))
    elif kind == 'branch':
        out.append(excavator())
        out.append(mound(78, CUT_Y - 1, 26))
        for k in range(6):
            out.append(f'<ellipse cx="{30 + k * 9}" cy="{CABLE_Y + 22}" rx="3" ry="1.6" fill="{ROOT_C}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 2 and 3 — the cable end on the bench: three cores (R, Y, B), the
# armour, and a megger or a multimeter with its leads.
# --------------------------------------------------------------------------

CY = 80          # the cable's centre line
CORE_DY = (-20, 0, 20)
CORE_C = (PH_R, PH_Y, PH_B)
R_END = 188      # the near (right) end's core tips
L_END = 12       # the far (left) end's core tips
ARM_R = (140, CY + 13)   # where a clip bites the armour (its lower edge), near end


def core_tip(i, right=True):
    x = R_END - 4 if right else L_END + 4
    return (x, CY + CORE_DY[i])


def cable_bench():
    out = card_open('kiosk')
    out.append('<path d="M0 136 L200 136" stroke="#5A4630" stroke-width="2"/>')
    # Sheath in the middle, armour bands, then the cores fanning out.
    out.append(f'<rect x="66" y="{CY - 15}" width="68" height="30" rx="5" fill="url(#sheath)"/>')
    for x0 in (54, 134):
        out.append(f'<rect x="{x0}" y="{CY - 14}" width="12" height="28" fill="url(#armour)"/>')
        for k in range(3):
            out.append(f'<path d="M{x0 + 2 + k * 4} {CY - 13} l2 26" stroke="#6E7880" stroke-width="0.8"/>')
    for i, dy in enumerate(CORE_DY):
        for right in (True, False):
            x0 = 146 if right else 54
            x1 = (R_END - 12) if right else (L_END + 12)
            y1 = CY + dy
            out.append(f'<path d="M{x0} {CY + dy * 0.3} C{(x0 + x1) / 2} {CY + dy * 0.3} {(x0 + x1) / 2} {y1} {x1} {y1}" '
                       f'stroke="{CORE_C[i]}" stroke-width="8" fill="none" stroke-linecap="round"/>')
            cx0 = x1 if right else x1 - 12
            out.append(f'<rect x="{cx0}" y="{y1 - 2.6}" width="12" height="5.2" rx="2" fill="url(#copper)"/>')
    return out


CLIP_S = 1.5


def clip(p, color, ang):
    """A crocodile clip, jaws at p, body trailing along ang (deg). Returns
    (svg, the tail where its lead joins)."""
    x, y = p
    a = math.radians(ang)
    tail = (x + math.cos(a) * 15 * CLIP_S, y + math.sin(a) * 15 * CLIP_S)
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({CLIP_S})">'
            f'<path d="M0 -2 L13 -4.4 L15 -1 L15 1 L13 4.4 L0 2 Z" fill="{color}"/>'
            f'<path d="M-3 -2.6 L2 -2.6 L2 2.6 L-3 2.6 Z" fill="url(#armour)"/></g>'), tail


def lead(a, b, color, sag=24, w=2.4):
    (x0, y0), (x1, y1) = a, b
    cx, cy = (x0 + x1) / 2, max(y0, y1) + sag
    return f'<path d="M{f(x0)} {f(y0)} Q{f(cx)} {f(cy)} {f(x1)} {f(y1)}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'


def megger_case(x, y, w=84, h=62):
    return [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" fill="url(#case)"/>',
            f'<rect x="{x + 5}" y="{y + 5}" width="{w - 10}" height="{h - 10}" rx="4" fill="{CASE_D}"/>',
            f'<rect x="{x + 10}" y="{y - 5}" width="8" height="6" rx="1.5" fill="{PH_R}"/>',
            f'<rect x="{x + w - 18}" y="{y - 5}" width="8" height="6" rx="1.5" fill="{LEAD_B}"/>']


MX, MY = 58, 150   # the instrument's top-left corner


def megger_analog(needle):
    """An analogue insulation tester: a dial from 0 (left) to infinity (right).
    needle: 'zero' or 'inf'. Returns (svg, L terminal, E terminal)."""
    g = megger_case(MX, MY)
    cx, cy, r = MX + 42, MY + 50, 34
    g.append(f'<path d="M{cx - r - 4} {cy} A{r + 4} {r + 4} 0 0 1 {cx + r + 4} {cy} Z" fill="{DIAL}"/>')
    for k in range(9):
        a = math.pi * (1 - k / 8)
        x0, y0 = cx + math.cos(a) * (r - 2), cy - math.sin(a) * (r - 2)
        x1, y1 = cx + math.cos(a) * (r - 7), cy - math.sin(a) * (r - 7)
        g.append(f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{LCD_INK}" stroke-width="1"/>')
    g.append(f'<ellipse cx="{cx - r + 7}" cy="{cy - 6}" rx="2.2" ry="3" fill="none" stroke="{LCD_INK}" stroke-width="1.2"/>')
    g.append(infinity(cx + r - 9, cy - 6, 2.6, sw=1.2))
    a = math.pi * (0.97 if needle == 'zero' else 0.03)
    g.append(f'<path d="M{cx} {cy - 1} L{f(cx + math.cos(a) * (r - 3))} {f(cy - 1 - math.sin(a) * (r - 3))}" stroke="{TAG}" stroke-width="1.8" stroke-linecap="round"/>')
    g.append(f'<circle cx="{cx}" cy="{cy - 1}" r="3" fill="{LCD_INK}"/>')
    return ''.join(g), (MX + 14, MY - 4), (MX + 70, MY - 4)


def megger_digital(show):
    """A digital insulation tester. show: 'zero' (0.00 MΩ) or 'inf'."""
    g = megger_case(MX, MY)
    g.append(f'<rect x="{MX + 10}" y="{MY + 10}" width="50" height="26" rx="2" fill="url(#lcd)"/>')
    if show == 'zero':
        txt, wid = readout('0.00 MO', 0, 0, 10)
        sc = min(1.0, 44 / wid)
        g.append(f'<g transform="translate({MX + 13} {f(MY + 15 + (10 - 10 * sc) / 2)}) scale({f(sc)})">{txt}</g>')
    else:
        g.append(infinity(MX + 35, MY + 23, 6, sw=1.8))
    g.append(f'<circle cx="{MX + 70}" cy="{MY + 22}" r="7.5" fill="{KNOB}"/><path d="M{MX + 70} {MY + 22} L{MX + 74} {MY + 16}" stroke="#E6EBEF" stroke-width="1.6" stroke-linecap="round"/>')
    g.append(f'<circle cx="{MX + 22}" cy="{MY + 46}" r="5.6" fill="{PH_R}"/>')
    for k in range(3):
        g.append(f'<rect x="{MX + 38 + k * 10}" y="{MY + 43}" width="6" height="6" rx="1.2" fill="{KNOB}"/>')
    return ''.join(g), (MX + 14, MY - 4), (MX + 70, MY - 4)


def dmm(beep):
    """A multimeter on continuity, a speaker mark with sound waves (beep) or
    struck through (no beep). Returns (svg, red socket, black socket)."""
    x, y = MX + 18, MY - 2
    g = [f'<rect x="{x}" y="{y}" width="48" height="66" rx="6" fill="url(#case)"/>',
         f'<rect x="{x + 4}" y="{y + 4}" width="40" height="58" rx="4" fill="{CASE_D}"/>',
         f'<rect x="{x + 8}" y="{y + 8}" width="32" height="16" rx="2" fill="url(#lcd)"/>',
         # speaker mark on the display
         f'<path d="M{x + 13} {y + 13} L{x + 17} {y + 13} L{x + 21} {y + 10} L{x + 21} {y + 22} L{x + 17} {y + 19} L{x + 13} {y + 19} Z" fill="{LCD_INK}"/>']
    if beep:
        g.append(f'<path d="M{x + 25} {y + 12} q3 4 0 8 M{x + 29} {y + 10} q5 6 0 12" stroke="{LCD_INK}" stroke-width="1.3" fill="none"/>')
    else:
        g.append(f'<path d="M{x + 25} {y + 11} L{x + 34} {y + 21} M{x + 34} {y + 11} L{x + 25} {y + 21}" stroke="{LCD_INK}" stroke-width="1.5"/>')
    g.append(f'<circle cx="{x + 24}" cy="{y + 38}" r="8" fill="{KNOB}"/><path d="M{x + 24} {y + 38} L{x + 28} {y + 32}" stroke="#E6EBEF" stroke-width="1.4"/>')
    g.append(f'<circle cx="{x + 14}" cy="{y + 56}" r="2.6" fill="{PH_R}"/><circle cx="{x + 34}" cy="{y + 56}" r="2.6" fill="{LEAD_B}"/>')
    return ''.join(g), (x + 14, y + 56), (x + 34, y + 56)


def bench_test(meter, a, b):
    """meter: ('analog', 'zero'|'inf') / ('digital', 'zero'|'inf') /
    ('dmm', beep). a, b: where the red and the black clip bite."""
    out = cable_bench()
    kind, show = meter
    if kind == 'analog':
        svg, L, E = megger_analog(show)
    elif kind == 'digital':
        svg, L, E = megger_digital(show)
    else:
        svg, L, E = dmm(show)
    out.append(svg)

    def ang(p):
        if p[0] < 100:
            return 70           # far end: trail down to the right
        if p == ARM_R:
            return 95           # armour: straight down
        return 112              # near-end core tip: down to the left
    ca, ta = clip(a, PH_R, ang(a))
    cb, tb = clip(b, LEAD_B, ang(b))
    out.append(lead(L, ta, PH_R, sag=14))
    out.append(lead(E, tb, LEAD_B, sag=10))
    out.append(ca)
    out.append(cb)
    return card_close(out)


TIP_R = core_tip(0)
TIP_Y = core_tip(1)
TIP_B = core_tip(2)
FAR_R = core_tip(0, right=False)
FAR_Y = core_tip(1, right=False)


def short_card(kind):
    if kind == 'needle':
        return bench_test(('analog', 'zero'), TIP_R, TIP_Y)
    if kind == 'digital':
        return bench_test(('digital', 'zero'), TIP_R, TIP_Y)
    if kind == 'inf':
        return bench_test(('analog', 'inf'), TIP_R, TIP_Y)
    if kind == 'armour':
        return bench_test(('digital', 'zero'), TIP_R, ARM_R)
    if kind == 'open':
        return bench_test(('dmm', False), TIP_R, FAR_R)
    raise ValueError(kind)


def earth_card(kind):
    if kind == 'needle':
        return bench_test(('analog', 'zero'), TIP_Y, ARM_R)
    if kind == 'digital':
        return bench_test(('digital', 'zero'), TIP_Y, ARM_R)
    if kind == 'yb':
        return bench_test(('analog', 'zero'), TIP_Y, TIP_B)
    if kind == 'inf':
        return bench_test(('digital', 'inf'), TIP_Y, ARM_R)
    if kind == 'beep':
        return bench_test(('dmm', True), TIP_Y, FAR_Y)
    raise ValueError(kind)


# --------------------------------------------------------------------------
# Round 4 — route: walking the cable route (marker posts in a row).
# --------------------------------------------------------------------------

ROUTE_Y = 150
POSTS = (14, 66, 118, 170)


def field(posts=True):
    out = card_open('field')
    out.append(f'<path d="M0 66 L200 66" stroke="{GRASS}" stroke-width="2"/>')
    for x, y in ((30, 58), (150, 56), (92, 60)):
        out.append(f'<ellipse cx="{x}" cy="{y}" rx="16" ry="9" fill="{LEAF}"/>')
        out.append(f'<rect x="{x - 1.5}" y="{y + 6}" width="3" height="6" fill="{BARK}"/>')
    # A distant pond on the horizon, far from the route (the same on every
    # route card, so water on the route itself stays the only wet clue).
    out.append(f'<ellipse cx="61" cy="75" rx="15" ry="3.2" fill="{DROP}" opacity="0.8"/>')
    for x, y in ((40, 96), (130, 104), (176, 88), (20, 196), (96, 206)):
        out.append(f'<path d="M{x} {y} l3 -6 l3 6 M{x + 4} {y} l3 -5" stroke="{GRASS}" stroke-width="1.3" fill="none"/>')
    if posts:
        out.append(f'<path d="M0 {ROUTE_Y + 3} L200 {ROUTE_Y + 3}" stroke="{SOIL_L}" stroke-width="10" stroke-opacity="0.35"/>')
        for x in POSTS:
            out.append(route_post(x, ROUTE_Y + 2))
    return out


def pit(cx, cy, open_=True, burnt=False):
    """A joint pit on the route: a concrete chamber; open shows the joint."""
    if not open_:
        return (f'<rect x="{cx - 18}" y="{cy - 7}" width="36" height="14" rx="2" fill="url(#concrete)"/>'
                f'<path d="M{cx - 12} {cy} L{cx + 12} {cy}" stroke="{ROCK}" stroke-width="1.4"/>'
                f'<circle cx="{cx - 13}" cy="{cy}" r="1.4" fill="{WIRE}"/><circle cx="{cx + 13}" cy="{cy}" r="1.4" fill="{WIRE}"/>')
    s = (f'<rect x="{cx - 20}" y="{cy - 9}" width="40" height="18" rx="2" fill="url(#concrete)"/>'
         f'<rect x="{cx - 16}" y="{cy - 6}" width="32" height="12" fill="{SCORCH}"/>'
         f'<rect x="{cx - 16}" y="{cy - 2}" width="32" height="5" fill="{WIRE}"/>'
         f'<rect x="{cx - 8}" y="{cy - 4}" width="16" height="9" rx="3" fill="{PANTS}"/>'
         # the lid lifted off, leaning beside the pit
         f'<rect x="{cx + 22}" y="{cy - 20}" width="10" height="22" rx="1.5" fill="url(#concrete)" transform="rotate(12 {cx + 27} {cy})"/>')
    if burnt:
        s += (f'<ellipse cx="{cx}" cy="{cy}" rx="9" ry="5" fill="url(#scorch)"/>'
              f'<path d="M{cx - 4} {cy - 4} l2 -6 l2 6 M{cx + 2} {cy - 3} l2 -5 l1 5" stroke="{SCORCH}" stroke-width="1.4" fill="none"/>')
    return s


def route_card(kind):
    out = field(posts=kind != 'nomap')
    if kind == 'dig':
        out.append(hole(130, ROUTE_Y + 6, 12))
        out.append(mound(146, ROUTE_Y + 4, 20))
        out.append(worker(84, ((74, 150), (104, 140)), face=1, look=12,
                          props=paper_map(72, 150, 1.0, -8)))
    elif kind == 'burn':
        out.append(f'<ellipse cx="136" cy="{ROUTE_Y + 6}" rx="26" ry="8" fill="{DROP}" opacity="0.6"/>')
        out.append(f'<ellipse cx="136" cy="{ROUTE_Y + 6}" rx="16" ry="6" fill="url(#scorch)"/>')
        out.append(worker(84, ((74, 150), (106, 142)), face=1, look=14,
                          props=paper_map(72, 150, 1.0, -8)))
    elif kind == 'pit':
        out.append(pit(132, ROUTE_Y + 6, open_=True, burnt=True))
        out.append(worker(98, ((88, 158), (118, 156)), face=1, look=26, crouch=0.8,
                          props=paper_map(86, 160, 0.9, 10)))
    elif kind == 'off':
        out.append(hole(150, 92, 11))
        out.append(mound(166, 91, 16))
        out.append(f'<ellipse cx="150" cy="92" rx="6" ry="2.4" fill="url(#scorch)"/>')
        out.append(worker(112, ((104, 124), (136, 104)), face=1, look=-14, gy=128,
                          props=paper_map(102, 124, 1.0, -8)))
    elif kind == 'shut':
        out.append(pit(132, ROUTE_Y + 6, open_=False))
        out.append(worker(64, ((56, 150), (74, 152)), face=-1, look=0,
                          props=paper_map(56, 150, 1.0, 8)))
    elif kind == 'nomap':
        out.append(hole(140, 120, 10))
        out.append(mound(156, 119, 14))
        out.append(hole(60, 176, 9))
        # no map: one hand scratching the helmet, the other empty
        out.append(worker(100, ((112, 104), (88, 158)), face=1, look=-10))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — locate: the cable's end kiosk, the route posts along the road.
# --------------------------------------------------------------------------

LOC_Y = 160
LOC_POSTS = (58, 112, 166)
FLAG_X = 142


def site():
    out = card_open('site')
    out.append(f'<path d="M0 70 L200 70" stroke="{GRASS}" stroke-width="2"/>')
    # Houses in the distance.
    for x in (100, 150):
        out.append(f'<rect x="{x}" y="46" width="30" height="24" fill="{SOIL_L}"/><path d="M{x - 3} 47 L{x + 15} 34 L{x + 33} 47 Z" fill="{BARK}"/>'
                   f'<rect x="{x + 11}" y="55" width="8" height="8" fill="{DIAL}"/>')
    # The cable's end kiosk (a feeder pillar) where the cable comes up.
    out.append(f'<rect x="6" y="104" width="34" height="58" rx="3" fill="url(#panel)"/>'
               f'<path d="M23 108 L23 158" stroke="#3E5246" stroke-width="1.2"/>'
               f'<circle cx="15" cy="112" r="2" fill="{LED_G}"/><rect x="26" y="128" width="3" height="10" rx="1.2" fill="{KNOB}"/>')
    out.append(f'<path d="M0 {LOC_Y + 3} L200 {LOC_Y + 3}" stroke="{SOIL_L}" stroke-width="10" stroke-opacity="0.35"/>')
    for x in LOC_POSTS:
        out.append(route_post(x, LOC_Y + 2))
    return out


def flag(x, y=LOC_Y + 4):
    return (f'<path d="M{x} {y} L{x} {y - 24}" stroke="{WIRE}" stroke-width="1.6"/>'
            f'<path d="M{x} {y - 24} L{x + 12} {y - 20} L{x} {y - 16} Z" fill="{TAG}"/>')


def tdr_box(x, y, trace=True):
    """The TDR: an orange box, its screen showing a trace with one echo."""
    s = (f'<rect x="{x}" y="{y}" width="40" height="30" rx="4" fill="url(#case)"/>'
         f'<rect x="{x + 4}" y="{y + 4}" width="32" height="18" rx="2" fill="url(#lcd)"/>')
    if trace:
        s += (f'<path d="M{x + 6} {y + 16} L{x + 9} {y + 9} L{x + 12} {y + 16} L{x + 24} {y + 16} L{x + 26} {y + 10} L{x + 28} {y + 16} L{x + 34} {y + 16}" '
              f'stroke="{LCD_INK}" stroke-width="1.2" fill="none"/>')
    s += f'<circle cx="{x + 10}" cy="{y + 26}" r="2" fill="{KNOB}"/><circle cx="{x + 30}" cy="{y + 26}" r="2" fill="{LED_G}"/>'
    return s


def thumper(x, y):
    """The surge generator (thumper) beside the kiosk, its lead into it."""
    return (f'<rect x="{x}" y="{y}" width="34" height="40" rx="4" fill="url(#case)"/>'
            f'<rect x="{x + 4}" y="{y + 4}" width="26" height="10" rx="2" fill="{CASE_D}"/>'
            f'<path d="M{x + 13} {y + 22} l6 0 l-4 7 l6 0 l-9 10 l3 -8 l-5 0 Z" fill="{TAG}"/>'
            f'<circle cx="{x + 8}" cy="{y + 9}" r="2" fill="{LED_G}"/>')


def locate_card(kind):
    out = site()
    if kind == 'tdr':
        out.append(tdr_box(44, LOC_Y - 34))
        out.append(f'<path d="M44 {LOC_Y - 22} Q36 {LOC_Y - 22} 34 {LOC_Y - 30}" stroke="{LEAD_B}" stroke-width="2" fill="none"/>')
        # the distance told in metres: an arrow along the route to the flag
        out.append(f'<path d="M40 {LOC_Y + 14} L{FLAG_X - 6} {LOC_Y + 14}" stroke="{WHITE}" stroke-width="1.8" stroke-dasharray="5 4"/>'
                   f'<path d="M{FLAG_X} {LOC_Y + 14} l-8 -4 l0 8 Z" fill="{WHITE}"/>')
        out.append(flag(FLAG_X))
        out.append(worker(78, ((62, 140), (66, 130)), face=-1, look=18, gy=LOC_Y + 34))
    elif kind == 'thump':
        out.append(thumper(42, LOC_Y - 38))
        out.append(f'<path d="M42 {LOC_Y - 20} Q36 {LOC_Y - 20} 34 {LOC_Y - 28}" stroke="{LEAD_B}" stroke-width="2.4" fill="none"/>')
        # the 'thump' rising from the fault under the ground
        for r in (8, 14, 20):
            out.append(f'<path d="M{FLAG_X - r} {LOC_Y + 30} A{r} {r * 0.6} 0 0 1 {FLAG_X + r} {LOC_Y + 30}" stroke="{WHITE}" stroke-width="1.6" fill="none" opacity="0.85"/>')
        # trainee with headphones, the ground microphone on the route
        out.append(f'<path d="M{FLAG_X - 2} {LOC_Y + 12} L{FLAG_X - 8} {LOC_Y - 24}" stroke="{WIRE}" stroke-width="2"/>'
                   f'<ellipse cx="{FLAG_X - 1}" cy="{LOC_Y + 14}" rx="7" ry="2.6" fill="url(#armour)"/>')
        out.append(worker(FLAG_X + 18, ((FLAG_X - 8, LOC_Y - 24), (FLAG_X + 2, LOC_Y - 30)), face=-1, look=24,
                          gy=LOC_Y + 34, phones=True))
    elif kind == 'call':
        out.append(flag(FLAG_X))
        out.append(spade(FLAG_X + 30, LOC_Y + 26, FLAG_X + 6, LOC_Y + 30))
        out.append(worker(96, ((84, 150), (104, 118)), face=1, look=-6, gy=LOC_Y + 34,
                          props=phone(104, 111, 15, 1.2)))
        out.append(tdr_box(44, LOC_Y - 34, trace=False))
    elif kind == 'trench':
        out.append(f'<rect x="44" y="{LOC_Y - 2}" width="156" height="12" fill="{SCORCH}"/>')
        for x in (60, 96, 132, 168):
            out.append(mound(x, LOC_Y - 2, 26))
        out.append(worker(110, ((100, 168), (112, 158)), face=-1, look=20, gy=LOC_Y + 40,
                          props=spade(112, 158, 96, LOC_Y + 10)))
    elif kind == 'nocall':
        out.append(flag(FLAG_X))
        out.append(hole(FLAG_X - 18, LOC_Y + 14, 12))
        out.append(mound(FLAG_X - 40, LOC_Y + 12, 18))
        out.append(worker(FLAG_X - 2, ((FLAG_X - 12, LOC_Y), (FLAG_X - 6, LOC_Y - 12)), face=-1, look=26, gy=LOC_Y + 36, crouch=0.5,
                          props=spade(FLAG_X - 6, LOC_Y - 12, FLAG_X - 18, LOC_Y + 14)))
        out.append(phone(70, LOC_Y + 30, 80, 1.0))
    elif kind == 'alone':
        # a lone overhead man in his climbing harness, down in the jointing pit
        out.append(f'<rect x="96" y="{LOC_Y - 4}" width="76" height="40" fill="{SCORCH}"/>'
                   f'<rect x="92" y="{LOC_Y - 8}" width="84" height="6" fill="{SOIL_D}"/>')
        out.append(f'<rect x="96" y="{LOC_Y + 18}" width="76" height="9" fill="url(#sheath)"/>'
                   f'<rect x="124" y="{LOC_Y + 14}" width="22" height="16" rx="4" fill="{PANTS}"/>'
                   f'<rect x="128" y="{LOC_Y + 17}" width="14" height="10" rx="2" fill="url(#copper)"/>')
        out.append(worker(116, ((126, LOC_Y + 18), (134, LOC_Y + 16)), face=1, look=30, gy=LOC_Y + 36, crouch=0.7, harness=True))
        out.append(spade(60, LOC_Y + 30, 80, LOC_Y + 26))
        # his toolbox left up on the ground
        out.append(f'<rect x="56" y="{LOC_Y - 14}" width="26" height="16" rx="2" fill="url(#case)"/>'
                   f'<path d="M63 {LOC_Y - 14} q6 -6 12 0" stroke="{KNOB}" stroke-width="2" fill="none"/>')
    return card_close(out)


CARDS = {
    'cause_dig': cause_card('dig'),
    'cause_joint': cause_card('joint'),
    'cause_rat': cause_card('rat'),
    'cause_storm': cause_card('storm'),
    'cause_dry': cause_card('dry'),
    'cause_branch': cause_card('branch'),
    'short_needle': short_card('needle'),
    'short_digital': short_card('digital'),
    'short_inf': short_card('inf'),
    'short_armour': short_card('armour'),
    'short_open': short_card('open'),
    'earth_needle': earth_card('needle'),
    'earth_digital': earth_card('digital'),
    'earth_yb': earth_card('yb'),
    'earth_inf': earth_card('inf'),
    'earth_beep': earth_card('beep'),
    'route_dig': route_card('dig'),
    'route_burn': route_card('burn'),
    'route_pit': route_card('pit'),
    'route_off': route_card('off'),
    'route_shut': route_card('shut'),
    'route_nomap': route_card('nomap'),
    'locate_tdr': locate_card('tdr'),
    'locate_thump': locate_card('thump'),
    'locate_call': locate_card('call'),
    'locate_trench': locate_card('trench'),
    'locate_nocall': locate_card('nocall'),
    'locate_alone': locate_card('alone'),
}

# Safe cards and traps per round (mirrors learn_board_pack59.dart).
ROUNDS = {
    'cause': (['cause_dig', 'cause_joint', 'cause_rat'], ['cause_storm', 'cause_dry', 'cause_branch']),
    'short': (['short_needle', 'short_digital'], ['short_inf', 'short_armour', 'short_open']),
    'earth': (['earth_needle', 'earth_digital'], ['earth_yb', 'earth_inf', 'earth_beep']),
    'route': (['route_dig', 'route_burn', 'route_pit'], ['route_off', 'route_shut', 'route_nomap']),
    'locate': (['locate_tdr', 'locate_thump', 'locate_call'], ['locate_trench', 'locate_nocall', 'locate_alone']),
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
    # Deletes only this generator's own stale cards.
    for name in os.listdir(OUT):
        if name.endswith('.svg') and name[:-4] not in CARDS:
            os.remove(os.path.join(OUT, name))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
