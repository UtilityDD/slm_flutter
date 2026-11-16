"""Picture cards for lesson 7.5 শেখা ("বিদ্যুৎ চুরি: একটি অপরাধ এবং তার বিপদ").

python -I tool/m7_board75_art.py .

Writes assets/game/art/m7_board75/*.svg in the clean gradient style of
tool/m6_board610_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only marks a worker reads (the OFF tag on the AB handle, a
tester's reading) are stroke glyphs with English letters and digits.

What the cards show comes from lesson 7.5 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md: M7-8 tester + earth before the
hook, M7-9 / X4 the lane DTR is an AB switch + HG fuses, no DO; X6 five
rounds). The item spec's six rounds are five here: its evidence round left
the board (do_7_5_b plays the evidence shot; the far-off photo lives on in
the act round).
  1. legal: the lawful supply — pole, service cable, sealed meter, house
     (bare LT or AB cable with its service connector). Traps (Electricity
     Act s.135, as the lesson lists it): a hook on the bare LT line, a magnet
     on the meter, a wire joined on before the meter (upstream), a loop round
     the meter (bypass, seal broken);
  2. danger ('which picture shows the theft wire doing harm right now?'):
     a loose hook sparking over a thatch roof that catches fire; the lane
     DTR's HG fuse wire blown under the hooks' load, the lane dark at dusk.
     Traps show NO harm happening (wrong by what they show, never by a
     hidden label): a taped hook joint with no spark and no fire, hooks
     running while the neighbours' lights burn at dusk, a cool DTR with all
     its fuses whole and the lane lit (no spark anywhere);
  3. signs (pro tip 1): few houses on the DTR, yet it is overloaded (an HG
     wire blown, heat rising) or the bulbs burn dim. Traps: many houses and
     a hot DTR, many houses with bright bulbs, few houses with bright bulbs;
  4. act (section 3): photograph from across the road; phone it in at the
     van, facing the house and pointing up at the hook while he talks. Traps:
     arguing at the door, climbing to pull the hook, walking off (his back to
     the house, mid-stride past the van, head down over the phone), a
     close-up photo under the window while the man glares;
  5. remove (pro tip 4 + M7-8): on the authority's order, the DTR's AB open
     (all three blades up) and tagged OFF, the tester at 0, the earth set on
     the span, a gloved lineman takes the hook off (with or without the
     officer and the constable in view). Traps: the AB still closed (the
     officer there, a spark at the hook), the hand on the hook with the
     tester unused, the tester at 0 but the earth set coiled on the ground,
     alone at night with no order.

Fairness (the playbook, section 4): every card in a round shares one
backdrop (the 'alone' trap's night sky is a trap's own); the script checks
every hand the dealer can make (one safe card + any three traps): each colour
or gradient the safe card draws is drawn by a trap in that hand, the safe
card's backdrop is a trap's backdrop too, and every prop or figure (tagged
<!--prop:name-->) on the safe card is on a trap in that hand, and none sits on
every trap of the hand but not on the safe card. One narrow exception
(ANSWER_PROPS): in the danger round the spark and the fire ARE the harm the
round asks about, so they may sit on the safe card alone; their colours still
appear on the traps (the flame red is the DTR's AB handle, the flame yellow
and the glow are the lit windows). It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board75_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board75')
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
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
COPPER = '#B8733A'     # the thief's thin copper wire and the hook
TAPE = '#1C1F24'       # black tape on a theft joint
RED = '#D8402F'        # AB handle, magnet, tag border, flame
GREEN = '#3E9B4F'      # earth lead
EARTH_Y = '#E8C830'    # earth lead stripe
SEAL = '#6E747A'       # the meter's lead seal
METER_Y = '#F2B630'
METER_D = '#B9851A'
LCD_ON = '#1D2B22'
LED_OFF = '#6A3A34'
SUN = '#FFE08A'        # a lit window, a bright bulb, the flame's core
WIN_OFF = '#2E3A46'    # a dark window
DIM = '#9C7A3A'        # a dim bulb (low voltage)
HEAT = '#E8A060'       # heat rising off an overloaded DTR
TINW = '#D9DDE0'       # HG fuse wire
IPC = '#3A4048'        # the AB cable's service connector
KURTA = '#ECE9DF'      # the householder's shirt / the officer's shirt
LUNGI = '#3F6E5A'
KHAKI = '#A88D52'      # the constable's uniform
KHAKI_D = '#8A7240'
VAN = '#E9EEF2'
VAN_D = '#5C6B78'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="eve" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3E4F78"/><stop offset="0.6" stop-color="#9A7E8E"/><stop offset="1" stop-color="#E0A878"/></linearGradient>
  <linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#121A2C"/><stop offset="1" stop-color="#34405A"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="paving" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3A49C"/><stop offset="1" stop-color="#85867E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3ABB2"/><stop offset="1" stop-color="#6C747B"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="mbody" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FBFBF8"/><stop offset="1" stop-color="#D3D7D9"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <linearGradient id="thatch" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9A25A"/><stop offset="1" stop-color="#9C7A3A"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFE08A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def tag(name):
    """An XML comment naming a prop or figure on the card. The fairness check
    (here and in test/learn_board_75_test.dart) reads these: no prop may sit
    only on the safe card of a hand, or be missing only from it."""
    return f'<!--prop:{name}-->'


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# People: the lineman of tool/m6_board610_art.py, plus the householder, the
# officer and the constable (no helmet).
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


def _boot(p, face, color=BOOT):
    x, y = p
    x0 = -4 if face > 0 else -7
    return f'<rect x="{f(x + x0)}" y="{f(y - 4)}" width="11" height="5" rx="2" fill="{color}"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True, phone=False, kind='lineman'):
    """A person. [kind] 'lineman' (blue shirt, helmet, rubber gloves or bare
    hands), 'civil' (the householder: white kurta, green lungi), 'officer'
    (white shirt, dark trousers) or 'police' (khaki, cap). [phone] = a mobile
    in the front hand."""
    if kind == 'lineman':
        torso, back_arm, front_arm, leg_b, leg_f = 'url(#shirt)', SHIRT_D, SHIRT, PANTS_D, PANTS
        hand_c = GLOVE if gloves else SKIN
    elif kind == 'civil':
        torso, back_arm, front_arm, leg_b, leg_f = KURTA, KURTA, KURTA, LUNGI, LUNGI
        hand_c = SKIN
    elif kind == 'officer':
        torso, back_arm, front_arm, leg_b, leg_f = KURTA, KURTA, KURTA, PANTS_D, PANTS
        hand_c = SKIN
    else:
        torso, back_arm, front_arm, leg_b, leg_f = KHAKI, KHAKI_D, KHAKI, KHAKI_D, KHAKI
        hand_c = SKIN
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, leg_b, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, leg_f, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, back_arm, 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="{torso}"/>')
    if kind == 'lineman':
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if kind == 'lineman':
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>')
        hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    elif kind == 'police':
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 2)} L{f(hx - 6)} {f(hy - 8)} L{f(hx + 6)} {f(hy - 8)} L{f(hx + 7)} {f(hy - 2)} Z" fill="{KHAKI_D}"/>')
    else:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="{HAIR}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, front_arm, 5.4))
    if phone:
        g.append(f'<rect x="{f(hf[0] - 2.5)}" y="{f(hf[1] - 6)}" width="5" height="9" rx="1" fill="{WIRE}"/>'
                 f'<rect x="{f(hf[0] - 1.6)}" y="{f(hf[1] - 5)}" width="3.2" height="6" fill="url(#lcd)"/>')
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, s=S, phone=None, kind='lineman', walk=False):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates. [phone] 'ear' puts the front hand
    and a phone to his ear; 'up' holds the phone up in the front hand."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    stride = 13 if walk else 7
    # walking: the back heel lifts off the ground mid-stride
    feet = ((x - stride * face, gy - (6 if walk else 1)), (x + (stride - 1) * face, gy - 1))
    hb = local(hands_world[0])
    hf = (head[0] - 5 * face, head[1] + 2) if phone == 'ear' else local(hands_world[1])
    fig = figure(hip, sh, head, feet, (hb, hf), face, look, gloves, phone=phone is not None, kind=kind)
    names = {'lineman': 'worker', 'civil': 'householder', 'officer': 'officer', 'police': 'constable'}
    tags = tag(names[kind]) + (tag('phone') if phone else '')
    return tags + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Glyphs: English digits and the letters of OFF as strokes.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', 'O': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {'F': 'M6 0 L0 0 L0 10 M0 5 L4.5 5'}


def _shift(d, ox, oy, k):
    nums = re.split(r'([MLQ])', d)
    out = []
    for part in nums:
        if part in ('M', 'L', 'Q') or not part.strip():
            out.append(part)
            continue
        vals = [float(v) for v in part.split()]
        pts = [f'{f(ox + vals[i] * k)} {f(oy + vals[i + 1] * k)}' for i in range(0, len(vals), 2)]
        out.append(' '.join(pts) + ' ')
    return ''.join(out).strip()


def glyphs(x, y, text, h=10.0, color=INK, w=None):
    """[text] drawn with strokes; (x, y) = top left; h = cap height."""
    k = h / 10
    d = []
    ox = x
    for ch in text:
        if ch == ' ':
            ox += 4.5 * k
        elif ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox
            for s in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[s]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
        else:
            d.append(_shift(_LET[ch], ox, y, k))
            ox += 7.8 * k
    sw = w if w is not None else 1.5 * k
    return (f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(sw)}" stroke-linecap="round" '
            f'stroke-linejoin="round" fill="none"/>')


def glyph_width(text, h=10.0):
    k = h / 10
    wd = 0.0
    for ch in text:
        wd += 4.5 * k if ch == ' ' else 5.4 * k if ch == '1' else 7.8 * k
    return wd - 1.8 * k


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def pole(x, top, bottom=GY, wdt=7):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def cloud(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.75"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(16 * s)}" ry="{f(6 * s)}"/>'
            f'<ellipse cx="{f(x + 8 * s)}" cy="{f(y - 4 * s)}" rx="{f(9 * s)}" ry="{f(6 * s)}"/></g>')


def motion(x, y, dx=0, dy=-1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def spark(x, y, r=12):
    return (tag('spark') + f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#glow)"/>'
            f'<path d="M{f(x - r * 0.7)} {f(y)} L{f(x + r * 0.7)} {f(y)} M{f(x)} {f(y - r * 0.7)} L{f(x)} {f(y + r * 0.7)} '
            f'M{f(x - r * 0.5)} {f(y - r * 0.5)} L{f(x + r * 0.5)} {f(y + r * 0.5)} M{f(x + r * 0.5)} {f(y - r * 0.5)} L{f(x - r * 0.5)} {f(y + r * 0.5)}" '
            f'stroke="{SUN}" stroke-width="1.6" stroke-linecap="round"/>')


def flames(x, y, s=1.0):
    """Small flames licking up from (x, y) — a thatch roof catching fire."""
    o = []
    for i, (dx, hgt) in enumerate(((-10, 14), (0, 20), (9, 12))):
        bx = x + dx * s
        o.append(f'<path d="M{f(bx - 5 * s)} {f(y)} Q{f(bx - 4 * s)} {f(y - hgt * 0.6 * s)} {f(bx)} {f(y - hgt * s)} '
                 f'Q{f(bx + 4 * s)} {f(y - hgt * 0.6 * s)} {f(bx + 5 * s)} {f(y)} Z" fill="{RED}"/>')
        o.append(f'<path d="M{f(bx - 2.4 * s)} {f(y)} Q{f(bx - 2 * s)} {f(y - hgt * 0.4 * s)} {f(bx)} {f(y - hgt * 0.6 * s)} '
                 f'Q{f(bx + 2 * s)} {f(y - hgt * 0.4 * s)} {f(bx + 2.4 * s)} {f(y)} Z" fill="{SUN}"/>')
    return tag('fire') + ''.join(o)


def tester(x, y, reading, s=1.0):
    """The yellow voltage tester (top-left x, y). [reading] '0' = proved dead;
    None = lying unused (blank screen)."""
    w, h = 28 * s, 42 * s
    o = [tag('tester'),
         f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(4 * s)}" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>',
         f'<rect x="{f(x + 2.5 * s)}" y="{f(y + 3.5 * s)}" width="{f(w - 5 * s)}" height="{f(15 * s)}" rx="1.5" fill="url(#lcd)"/>']
    if reading:
        tw = glyph_width(reading, 10 * s)
        o.append(glyphs(x + (w - tw) / 2, y + 6 * s, reading, 10 * s, LCD_ON))
    o.append(f'<circle cx="{f(x + w / 2)}" cy="{f(y + 28 * s)}" r="{f(4.5 * s)}" fill="{LED_OFF}"/>')
    return ''.join(o)


def earth_lead(d, w=2.2):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{GREEN}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_coil(x, y):
    """The portable earth set lying coiled on the ground, unused."""
    o = [tag('earthset')]
    for rx, ry in ((13, 4.5), (10, 3.6), (7, 2.8)):
        o.append(earth_lead(f'M{f(x - rx)} {f(y)} a{f(rx)} {f(ry)} 0 1 0 {f(2 * rx)} 0 a{f(rx)} {f(ry)} 0 1 0 {f(-2 * rx)} 0', 2))
    for dx in (-19, 16, 22):
        o.append(f'<rect x="{f(x + dx)}" y="{f(y - 3)}" width="5" height="7" rx="1.5" fill="url(#steel)"/>')
    return ''.join(o)


def phone_up(x, y):
    """A phone held up to photograph, screen to the viewer, a small flash."""
    return (f'<circle cx="{f(x + 5)}" cy="{f(y - 2)}" r="6" fill="url(#glow)"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="10" height="16" rx="2" fill="{WIRE}"/>'
            f'<rect x="{f(x + 1.3)}" y="{f(y + 1.6)}" width="7.4" height="12" fill="url(#lcd)"/>')


def magnet(x, y, s=1.0):
    """A horseshoe magnet (red, steel tips); (x, y) = its tips' line."""
    return (tag('magnet') + f'<path d="M{f(x - 5 * s)} {f(y)} L{f(x - 5 * s)} {f(y - 6 * s)} A{f(5 * s)} {f(5 * s)} 0 0 1 {f(x + 5 * s)} {f(y - 6 * s)} L{f(x + 5 * s)} {f(y)}" '
            f'stroke="{RED}" stroke-width="{f(3.6 * s)}" fill="none"/>'
            f'<rect x="{f(x - 7 * s)}" y="{f(y - 1 * s)}" width="{f(4 * s)}" height="{f(3.4 * s)}" fill="url(#steel)"/>'
            f'<rect x="{f(x + 3 * s)}" y="{f(y - 1 * s)}" width="{f(4 * s)}" height="{f(3.4 * s)}" fill="url(#steel)"/>')


def hook(x, y):
    """The thief's hook hung over a conductor at (x, y)."""
    return (tag('hook') + f'<path d="M{f(x - 3)} {f(y + 1)} Q{f(x - 3)} {f(y - 5)} {f(x + 1)} {f(y - 5)} Q{f(x + 5)} {f(y - 5)} {f(x + 4)} {f(y + 1)} L{f(x + 4)} {f(y + 8)}" '
            f'stroke="{COPPER}" stroke-width="1.8" fill="none" stroke-linecap="round"/>')


def ladder(x, top, bottom=GY, w=12):
    o = [tag('ladder'), f'<path d="M{f(x)} {f(bottom)} L{f(x)} {f(top)} M{f(x + w)} {f(bottom)} L{f(x + w)} {f(top)}" stroke="{BAG}" stroke-width="2.2"/>']
    yy = bottom - 8
    while yy > top + 2:
        o.append(f'<path d="M{f(x)} {f(yy)} H{f(x + w)}" stroke="{BAG}" stroke-width="1.6"/>')
        yy -= 11
    return ''.join(o)


def van(x, y):
    """The department's van (white body, blue-grey stripe), (x, y) top-left."""
    return (tag('van') + f'<rect x="{f(x)}" y="{f(y)}" width="56" height="28" rx="4" fill="{VAN}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 56)} {f(y + 8)} L{f(x + 68)} {f(y + 14)} L{f(x + 68)} {f(y + 28)} L{f(x + 56)} {f(y + 28)} Z" fill="{VAN}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 58)} {f(y + 11)} L{f(x + 66)} {f(y + 15)} L{f(x + 66)} {f(y + 19)} L{f(x + 58)} {f(y + 19)} Z" fill="url(#lcd)"/>'
            f'<rect x="{f(x)}" y="{f(y + 14)}" width="68" height="4" fill="{VAN_D}"/>'
            f'<circle cx="{f(x + 14)}" cy="{f(y + 29)}" r="6" fill="{WIRE}"/><circle cx="{f(x + 54)}" cy="{f(y + 29)}" r="6" fill="{WIRE}"/>'
            f'<circle cx="{f(x + 14)}" cy="{f(y + 29)}" r="2.4" fill="url(#steel)"/><circle cx="{f(x + 54)}" cy="{f(y + 29)}" r="2.4" fill="url(#steel)"/>')


def order_paper(x, y):
    """The authority's written order on a clipboard (no words: lines and a
    signature squiggle)."""
    return (tag('order') + f'<rect x="{f(x)}" y="{f(y)}" width="16" height="21" rx="1.5" fill="{BAG}"/>'
            f'<rect x="{f(x + 2)}" y="{f(y + 3)}" width="12" height="16" fill="{PAPER}"/>'
            f'<path d="M{f(x + 4)} {f(y + 7)} h8 M{f(x + 4)} {f(y + 10)} h8 M{f(x + 4)} {f(y + 13)} h6" stroke="{INK}" stroke-width="0.7"/>'
            f'<path d="M{f(x + 4)} {f(y + 17)} q2 -3 3 0 q2 3 4 -1" stroke="{SHIRT}" stroke-width="0.8" fill="none"/>')


def meter_board(x, y, seal='ok'):
    """The outdoor meter board on the house wall: grey box, white meter with
    its LCD strip, the lead seal hanging under the terminal cover ('ok' or
    'broken')."""
    o = [tag('meterboard'),
         f'<rect x="{f(x)}" y="{f(y)}" width="28" height="36" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{f(x + 5)}" y="{f(y + 4)}" width="18" height="24" rx="2" fill="url(#mbody)" stroke="{INK}" stroke-width="0.5"/>',
         f'<rect x="{f(x + 7)}" y="{f(y + 7)}" width="14" height="6" rx="1" fill="url(#lcd)"/>',
         f'<rect x="{f(x + 6)}" y="{f(y + 22)}" width="16" height="5" rx="1" fill="{SEAL}"/>']
    sx, sy = x + 14, y + 27
    if seal == 'ok':
        o.append(f'<path d="M{f(sx)} {f(sy)} q-2 4 0 7 q2 -3 0 -7" stroke="{SEAL}" stroke-width="0.9" fill="none"/>')
        o.append(f'<circle cx="{f(sx)}" cy="{f(sy + 8)}" r="2.2" fill="{SEAL}" stroke="{INK}" stroke-width="0.5"/>')
    else:
        o.append(f'<path d="M{f(sx)} {f(sy)} q-2 2 -2 4" stroke="{SEAL}" stroke-width="0.9" fill="none"/>')
        o.append(f'<circle cx="{f(sx + 5)}" cy="{f(GY - 3)}" r="2.2" fill="{SEAL}" stroke="{INK}" stroke-width="0.5"/>')
    return ''.join(o)


def house(x, y, w=80, roof='tile', window=WIN_OFF, door=True, glow=False):
    """A house: wall [x, x+w] from [y] to the ground, a tiled or thatched
    roof, one window (its colour: lit, dim or dark) and a door."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(GY - y)}" fill="url(#house)"/>']
    peak = y - 30
    fill = 'url(#roof)' if roof == 'tile' else 'url(#thatch)'
    o.append(f'<path d="M{f(x - 8)} {f(y + 2)} L{f(x + w / 2)} {f(peak)} L{f(x + w + 8)} {f(y + 2)} Z" fill="{fill}"/>')
    if roof == 'thatch':
        for i in range(5):
            xx = x + i * w / 4
            o.append(f'<path d="M{f(xx)} {f(y + 1)} L{f((xx + x + w / 2) / 2)} {f((y + peak) / 2)}" stroke="#8A6A30" stroke-width="0.8"/>')
    wx, wy = x + 10, y + 14
    if glow:
        o.append(f'<circle cx="{f(wx + 9)}" cy="{f(wy + 7)}" r="16" fill="url(#glow)"/>')
    o.append(f'<rect x="{f(wx)}" y="{f(wy)}" width="18" height="14" fill="{window}" stroke="{INK}" stroke-width="0.6"/>')
    o.append(f'<path d="M{f(wx + 9)} {f(wy)} V{f(wy + 14)}" stroke="{INK}" stroke-width="0.6"/>')
    if door:
        o.append(f'<rect x="{f(x + w - 30)}" y="{f(GY - 38)}" width="18" height="38" fill="#7A5A3A"/>')
    return ''.join(o)


def ground(back_y=GY):
    return f'<rect x="0" y="{back_y - 2}" width="{W}" height="{H - back_y + 2}" fill="url(#ground)"/>'


# --------------------------------------------------------------------------
# Round 1 — legal: the lawful supply and the four kinds of theft.
# --------------------------------------------------------------------------

LT_Y = (28, 34, 40, 46)       # the bare LT conductors (left end)


def lt_line(x, sag=6):
    """y of the lowest LT conductor at x (a gentle sag)."""
    t = x / W
    return LT_Y[3] + sag * 4 * t * (1 - t)


def street_lines(kind):
    o = [pole(22, 16), f'<rect x="6" y="24" width="34" height="4" rx="1" fill="url(#chan)"/>']
    if kind == 'bare':
        for yy in LT_Y:
            o.append(f'<path d="M0 {yy} Q100 {yy + 12} 200 {yy}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    else:
        o.append(f'<path d="M0 38 Q100 50 200 38" stroke="{WIRE}" stroke-width="5" fill="none"/>')
        o.append(f'<path d="M0 38 Q100 50 200 38" stroke="#4A525A" stroke-width="2" fill="none" stroke-dasharray="3 3"/>')
    return o


def ab_y(x):
    t = x / W
    return 38 + 24 * t * (1 - t)


def legal_card(kind):
    out = card_open('day')
    out.append(cloud(150, 18, 0.8))
    out.append(ground())
    line = 'ab' if kind in ('ab', 'magnet', 'upstream') else 'bare'
    out += street_lines(line)
    out.append(house(110, 118, 80, 'tile', WIN_OFF))
    mx, my = 116, 150
    take_x = 64
    take_y = lt_line(take_x) if line == 'bare' else ab_y(take_x)
    if kind != 'hook':
        # the service cable from the line to the meter board, then in
        out.append(f'<path d="M{take_x} {f(take_y)} Q{take_x + 24} {f(take_y + 60)} {mx + 14} {my}" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
        if line == 'ab':
            out.append(tag('connector') + f'<rect x="{take_x - 5}" y="{f(take_y - 5)}" width="10" height="10" rx="2" fill="{IPC}"/>'
                       f'<circle cx="{take_x}" cy="{f(take_y)}" r="2" fill="url(#steel)"/>')
        else:
            out.append(f'<circle cx="{take_x}" cy="{f(take_y)}" r="2" fill="url(#steel)"/>')
        out.append(meter_board(mx, my, 'broken' if kind == 'bypass' else 'ok'))
        out.append(f'<path d="M{mx + 28} {my + 18} H{mx + 40}" stroke="{WIRE}" stroke-width="2.2"/>')
    if kind == 'hook':
        hx = 84
        hy = lt_line(hx)
        out.append(hook(hx, hy - 1))
        out.append(f'<path d="M{hx + 4} {f(hy + 7)} Q{hx + 20} {f(hy + 70)} 124 139" stroke="{COPPER}" stroke-width="1.2" fill="none"/>')
    elif kind == 'magnet':
        out.append(magnet(mx + 14, my + 14, 0.9))
    elif kind == 'upstream':
        # a second wire twisted on to the service cable half-way, taped, into the window
        jx, jy = 92, 101
        out.append(tag('joint') + f'<rect x="{jx - 4}" y="{jy - 3}" width="8" height="6" rx="2" fill="{TAPE}"/>')
        out.append(f'<path d="M{jx} {jy} Q{jx + 18} {jy + 6} 126 139" stroke="{COPPER}" stroke-width="1.2" fill="none"/>')
    elif kind == 'bypass':
        out.append(tag('joint') + f'<path d="M{mx + 13} {my - 2} Q{mx - 10} {my + 18} {mx + 2} {my + 40} Q{mx + 30} {my + 44} {mx + 34} {my + 18}" '
                   f'stroke="{COPPER}" stroke-width="1.3" fill="none"/>')
        out.append(f'<rect x="{mx + 10}" y="{my - 5}" width="7" height="5" rx="2" fill="{TAPE}"/>')
    # the lineman on his round, looking at the house
    out.append(person(60, ((52, 172), (70, 170)), face=1, look=-14))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — danger: what the theft wire really does.
# --------------------------------------------------------------------------

DX = 34                    # the lane DTR's pole
AB_Y2, HG_Y2 = 36, 70


def dtr(x=DX, ab_open=False, hg=(True, True, True), heat=False, s=1.0, tag_off=False, ab_tag=True):
    """The lane DTR on its pole: the AB switch at the top (three blades lying
    closed, or standing open), the HG fuses below (a wire per phase, or a gap
    where one blew), the tank, the AB's red handle at the foot. [heat] = heat
    rising off the tank (overload). [tag_off] hangs the OFF tag and padlock
    on the handle."""
    o = [tag('dtr'), f'<g transform="translate({f(x)} 0) scale({s} 1) translate({f(-x)} 0)">']
    o.append(pole(x, 14, GY, 7))
    ph = (x - 16, x, x + 16)
    o.append(f'<rect x="{x - 26}" y="{AB_Y2}" width="52" height="4" rx="1" fill="url(#chan)"/>')
    o.append(f'<rect x="{x - 26}" y="{HG_Y2 + 10}" width="52" height="4" rx="1" fill="url(#chan)"/>')
    for p in ph:
        o.append(f'<path d="M{p} 0 L{p} {AB_Y2 - 6}" stroke="{WIRE}" stroke-width="1.1"/>')
        o.append(f'<rect x="{p - 7}" y="{AB_Y2 - 5}" width="3" height="5" fill="url(#porc)"/><rect x="{p + 4}" y="{AB_Y2 - 5}" width="3" height="5" fill="url(#porc)"/>')
        if ab_open:
            o.append(f'<path d="M{p - 5.5} {AB_Y2 - 6} L{p - 2} {AB_Y2 - 22}" stroke="url(#steel)" stroke-width="2.8" stroke-linecap="round"/>')
        else:
            o.append(f'<path d="M{p - 6} {AB_Y2 - 7} L{p + 6} {AB_Y2 - 7}" stroke="url(#steel)" stroke-width="2.8" stroke-linecap="round"/>')
        o.append(f'<path d="M{p + 5} {AB_Y2} Q{p + 7} {HG_Y2 - 18} {p - 4} {HG_Y2 + 2}" stroke="{WIRE}" stroke-width="0.9" fill="none"/>')
    for p, intact in zip(ph, hg):
        o.append(f'<rect x="{p - 5}" y="{HG_Y2 + 3}" width="2.6" height="7" fill="url(#porc)"/><rect x="{p + 2.4}" y="{HG_Y2 + 3}" width="2.6" height="7" fill="url(#porc)"/>')
        o.append(f'<path d="M{p - 3.7} {HG_Y2 + 3} L{p - 1.2} {HG_Y2 + 1} Q{p - 1} {HG_Y2 - 5} {p - 6} {HG_Y2 - 8}" stroke="{COPPER}" stroke-width="1.4" fill="none"/>')
        o.append(f'<path d="M{p + 3.7} {HG_Y2 + 3} L{p + 1.2} {HG_Y2 + 1} Q{p + 1} {HG_Y2 - 5} {p + 6} {HG_Y2 - 8}" stroke="{COPPER}" stroke-width="1.4" fill="none"/>')
        if intact:
            o.append(f'<path d="M{p - 1.2} {HG_Y2 + 1} L{p + 1.2} {HG_Y2 + 1}" stroke="{TINW}" stroke-width="1.6"/>')
        else:
            o.append(f'<path d="M{p - 1.4} {HG_Y2 + 1} l0.6 2.6 M{p + 1.4} {HG_Y2 + 1} l-0.6 2.6" stroke="{TINW}" stroke-width="1"/>')
        o.append(f'<path d="M{p + 3.7} {HG_Y2 + 10} L{p + 2} {HG_Y2 + 30}" stroke="{WIRE}" stroke-width="0.9"/>')
    o.append(f'<rect x="{x - 22}" y="{HG_Y2 + 28}" width="44" height="34" rx="3" fill="url(#tank)"/>')
    o.append(f'<rect x="{x - 28}" y="{HG_Y2 + 62}" width="56" height="4" fill="url(#chan)"/>')
    if heat:
        for i, dx in enumerate((-12, 0, 12)):
            o.append(f'<path d="M{x + dx} {HG_Y2 + 26} q-3 -5 0 -10 q3 -5 0 -10" stroke="{HEAT}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    # the AB's operating rod and red handle
    o.append(f'<path d="M{x + 5} {AB_Y2 + 4} L{x + 5} 168" stroke="url(#steel)" stroke-width="1.6"/>')
    o.append(f'<rect x="{x + 1}" y="164" width="11" height="5" rx="2" fill="{RED}"/>')
    if tag_off:
        o.append(off_tag(x + 6, 170))
    o.append('</g>')
    return ''.join(o)


def off_tag(x, y):
    """The padlock and the OFF tag hung on the AB handle."""
    return (tag('offtag') + f'<path d="M{f(x - 2.5)} {f(y + 4)} v-3 a2.5 2.5 0 0 1 5 0 v3" stroke="url(#steel)" stroke-width="1.4" fill="none"/>'
            f'<rect x="{f(x - 4)}" y="{f(y + 4)}" width="8" height="6" rx="1.2" fill="{HELMET_D}"/>'
            f'<path d="M{f(x + 3)} {f(y + 9)} L{f(x + 6)} {f(y + 13)}" stroke="{PAPER}" stroke-width="0.8"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 13)}" width="26" height="13" rx="1.5" fill="{PAPER}" stroke="{RED}" stroke-width="1.4"/>'
            + glyphs(x + 6.5, y + 16, 'OFF', 7, RED, 1.2))


def danger_card(kind):
    # dusk for the lane cards (lit or dark windows read as the supply), day
    # for the thatch cards
    out = card_open('day' if kind in ('fire', 'tape') else 'eve')
    out.append(ground())
    if kind in ('fire', 'tape'):
        for yy in LT_Y:
            out.append(f'<path d="M0 {yy} Q100 {yy + 12} 200 {yy}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        out.append(pole(18, 16))
        out.append(house(112, 128, 76, 'thatch', WIN_OFF))
        hx = 96
        hy = lt_line(hx)
        out.append(hook(hx, hy - 1))
        out.append(f'<path d="M{hx + 4} {f(hy + 7)} Q{hx + 12} {f(hy + 50)} 132 112" stroke="{COPPER}" stroke-width="1.2" fill="none"/>')
        if kind == 'fire':
            out.append(spark(hx + 2, hy, 12))
            out.append(flames(136, 112, 1.0))
        else:
            # the taped joint: no spark, no fire — nothing is happening (yet)
            out.append(tag('joint') + f'<rect x="{hx + 1}" y="{f(hy + 9)}" width="7" height="9" rx="2" fill="{TAPE}"/>')
        out.append(person(56, ((48, 172), (70, 120)), face=1, look=-22))
    elif kind in ('hg', 'calm'):
        out.append(dtr(DX, hg=(True, False, True) if kind == 'hg' else (True, True, True)))
        win = WIN_OFF if kind == 'hg' else SUN
        out.append(f'<path d="M{DX + 16} 60 Q120 72 200 62" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        out.append(house(96, 140, 40, 'tile', win, door=False, glow=kind == 'calm'))
        out.append(house(150, 136, 44, 'tile', win, door=False, glow=kind == 'calm'))
        for hx, tx in ((104, 112), (128, 118), (160, 168)):
            hy = 60 + (72 - 60) * 0.0 + 6 * math.sin(math.pi * (hx - DX - 16) / (200 - DX - 16))
            out.append(hook(hx, hy))
            out.append(f'<path d="M{hx + 4} {f(hy + 8)} Q{hx + 6} {f(hy + 50)} {tx} 160" stroke="{COPPER}" stroke-width="1" fill="none"/>')
        if kind == 'hg':
            out.append(f'<circle cx="{DX}" cy="{HG_Y2 + 2}" r="6" fill="url(#glow)"/>')
        # calm: no spark, no flash — the DTR cool, every fuse whole, the lane lit
        out.append(person(78, ((70, 172), (86, 170)), face=1, look=-18))
    elif kind == 'bright':
        for yy in LT_Y:
            out.append(f'<path d="M0 {yy} Q100 {yy + 12} 200 {yy}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        out.append(pole(18, 16))
        out.append(house(70, 140, 44, 'tile', SUN, door=False, glow=True))
        out.append(house(140, 136, 48, 'tile', SUN, door=False, glow=True))
        for hx, tx in ((88, 84), (150, 154)):
            hy = lt_line(hx)
            out.append(hook(hx, hy - 1))
            out.append(f'<path d="M{hx + 4} {f(hy + 7)} Q{hx + 8} {f(hy + 60)} {tx} 154" stroke="{COPPER}" stroke-width="1" fill="none"/>')
        out.append(person(40, ((32, 172), (50, 170)), face=1, look=-16))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — signs: few houses, yet overload or low voltage (pro tip 1).
# --------------------------------------------------------------------------

def bulb(x, y, bright):
    if bright:
        return f'<circle cx="{f(x)}" cy="{f(y)}" r="7" fill="url(#glow)"/><circle cx="{f(x)}" cy="{f(y)}" r="2.6" fill="{SUN}"/>'
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="2.6" fill="{DIM}"/>'


def signs_card(houses, hot, bright):
    out = card_open('eve')
    out.append(ground())
    out.append(dtr(28, hg=(True, False, True) if hot else (True, True, True), heat=hot, s=0.8))
    out.append(f'<path d="M40 60 Q120 70 200 64" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    if houses == 2:
        spots = [(84, 34), (148, 34)]
    else:
        spots = [(62, 24), (90, 24), (118, 24), (146, 24), (174, 24)]
    for hx, w in spots:
        out.append(house(hx, 158, w, 'tile', WIN_OFF, door=False))
        bx = hx + w / 2
        out.append(f'<path d="M{f(bx)} {f(64 + 4 * math.sin(math.pi * (bx - 40) / 160))} L{f(bx)} 150" stroke="{WIRE}" stroke-width="0.7"/>')
        out.append(bulb(bx, 150, bright))
    out.append(person(48, ((42, 174), (56, 172)), face=1, look=-10, s=1.0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — act: the thief at his door; what the lineman does (section 3).
# --------------------------------------------------------------------------

def act_stage(householder_angry=False):
    out = card_open('day')
    out.append(cloud(40, 20, 0.7))
    out.append(f'<rect x="0" y="{GY - 2}" width="{W}" height="{H - GY + 2}" fill="url(#paving)"/>')
    for yy in LT_Y:
        out.append(f'<path d="M0 {yy} Q100 {yy + 12} 200 {yy}" stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
    out.append(pole(96, 16))
    out.append(house(118, 120, 76, 'tile', WIN_OFF))
    hx = 150
    hy = lt_line(hx)
    out.append(hook(hx, hy - 1))
    out.append(f'<path d="M{hx + 4} {f(hy + 7)} Q{hx - 6} {f(hy + 50)} 136 134" stroke="{COPPER}" stroke-width="1.2" fill="none"/>')
    # the householder at his door (fists up when he is confronted or crowded)
    if householder_angry:
        out.append(person(174, ((166, 124), (182, 122)), face=-1, look=8, kind='civil'))
    else:
        out.append(person(174, ((168, 172), (182, 170)), face=-1, look=0, kind='civil'))
    return out


def act_card(kind):
    if kind == 'photo':
        out = act_stage()
        out.append(van(4, 158))
        out.append(person(36, ((30, 170), (58, 122)), face=1, look=-8, phone=None))
        out.append(tag('phone') + phone_up(54, 112))
    elif kind == 'call':
        # at the van's nose, facing the house: the phone at his ear, his
        # other arm pointing up at the hook he is reporting, eyes on it
        out = act_stage()
        out.append(van(4, 158))
        out.append(person(86, ((112, 104), (0, 0)), face=1, look=-18, phone='ear'))
    elif kind == 'argue':
        out = act_stage(householder_angry=True)
        out.append(van(4, 158))
        # face to face at the door, his finger jabbing at the man (no phone out)
        out.append(person(146, ((138, 172), (164, 118)), face=1, look=6))
        out.append(f'<path d="M164 118 l6 -3" stroke="{GLOVE}" stroke-width="2" stroke-linecap="round"/>')
    elif kind == 'climb':
        out = act_stage(householder_angry=True)
        out.append(van(4, 158))
        out.append(ladder(100, 50))
        out.append(person(110, ((104, 76), (148, lt_line(148) + 2)), face=1, look=-20, gy=112, s=1.1, gloves=False))
        out.append(spark(150, lt_line(150) + 2, 9))
    elif kind == 'walk':
        # leaving: his back to the house and the hook, mid-stride past the
        # van towards the card's edge, head down over the phone chat
        out = act_stage()
        out.append(van(4, 158))
        out.append(person(46, ((56, 170), (0, 0)), face=-1, look=14, phone='ear', walk=True))
        out.append(motion(64, 140, 1, 0, 3, 10))
    elif kind == 'close':
        out = act_stage(householder_angry=True)
        out.append(person(126, ((120, 172), (136, 118)), face=1, look=-16))
        out.append(tag('phone') + phone_up(132, 104))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — remove: the hook taken off on the authority's order (pro tip 4,
# M7-8: line off, tester 0, earth, full PPE).
# --------------------------------------------------------------------------

RX = 150          # the pole where the hook hangs
SPAN_Y = (54, 60, 66)


def span_y(i, x):
    t = (x - (DX + 16)) / (200 - DX - 16)
    return SPAN_Y[i] + 6 * math.sin(math.pi * max(0, min(1, t)))


def remove_card(kind):
    night = kind == 'alone'
    out = card_open('night' if night else 'day')
    out.append(ground())
    ab_open = kind in ('safe', 'order', 'notest', 'noearth')
    out.append(dtr(DX, ab_open=ab_open, tag_off=ab_open))
    for i in range(3):
        out.append(f'<path d="M{DX + 16} {SPAN_Y[i]} Q{(DX + 216) / 2} {SPAN_Y[i] + 12} 200 {SPAN_Y[i]}" stroke="{WIRE}" stroke-width="1.1" fill="none"/>')
    out.append(pole(RX, 40))
    out.append(house(160, 140, 36, 'tile', WIN_OFF, door=False))
    hx = RX + 14
    hy = span_y(2, hx)
    out.append(hook(hx, hy - 1))
    out.append(f'<path d="M{hx + 4} {f(hy + 7)} Q{hx + 8} {f(hy + 40)} 176 154" stroke="{COPPER}" stroke-width="1" fill="none"/>')
    out.append(ladder(RX - 16, 70))
    if kind in ('safe', 'order'):
        # the earth set clamped on the three conductors beside the hook, down to its rod
        ex = RX - 22
        d = f'M{ex} {f(span_y(0, ex))} L{ex} {f(span_y(1, ex))} L{ex} {f(span_y(2, ex))} L{ex - 8} 120 L{ex - 8} {GY - 4}'
        out.append(tag('earthset') + earth_lead(d))
        for i in range(3):
            out.append(f'<rect x="{ex - 2.5}" y="{f(span_y(i, ex) - 2.5)}" width="5" height="5" rx="1" fill="url(#steel)"/>')
        out.append(f'<path d="M{ex - 8} {GY - 6} L{ex - 8} {GY + 10}" stroke="url(#steel)" stroke-width="3"/>')
    elif kind in ('notest', 'noearth'):
        out.append(earth_coil(112, GY - 3))
    if kind in ('safe', 'order', 'noearth'):
        out.append(tester(RX + 6, GY - 26, '0', 0.55))
    elif kind == 'notest':
        out.append(tester(RX + 6, GY - 26, None, 0.55))
    elif kind == 'live':
        # the tester read the line live — and still his hand goes to the hook
        out.append(tester(RX + 6, GY - 26, '230', 0.55))
    # the lineman on the ladder, gloved, his hand on the hook
    out.append(person(RX - 10, ((RX - 14, 96), (hx + 1, hy + 4)), face=1, look=-22, gy=124, s=1.0))
    if kind == 'live':
        out.append(spark(hx + 2, hy + 2, 10))
    if kind in ('order', 'live', 'notest'):
        out.append(person(70, ((64, 172), (84, 160)), face=1, look=-14, kind='officer', s=1.1))
        out.append(order_paper(80, 150))
    if kind in ('order', 'live', 'notest'):
        out.append(person(100, ((94, 172), (108, 172)), face=1, look=-10, kind='police', s=1.1))
    if night:
        out.append(f'<circle cx="182" cy="22" r="7" fill="{PAPER}" opacity="0.85"/>')
    return card_close(out)


CARDS = {}
for k in ('sealed', 'ab', 'hook', 'magnet', 'upstream', 'bypass'):
    CARDS[f'legal_{k}'] = legal_card(k)
for k in ('fire', 'hg', 'tape', 'bright', 'calm'):
    CARDS[f'danger_{k}'] = danger_card(k)
for name, args in (('fewhot', (2, True, False)), ('fewdim', (2, False, False)), ('crowdhot', (5, True, False)),
                   ('crowdbright', (5, False, True)), ('fewbright', (2, False, True))):
    CARDS[f'signs_{name}'] = signs_card(*args)
for k in ('photo', 'call', 'argue', 'climb', 'walk', 'close'):
    CARDS[f'act_{k}'] = act_card(k)
for k in ('safe', 'order', 'live', 'notest', 'noearth', 'alone'):
    CARDS[f'remove_{k}'] = remove_card(k)

# Safe cards and traps per round (mirrors learn_board_pack75.dart).
ROUNDS = {
    'legal': (['legal_sealed', 'legal_ab'], ['legal_hook', 'legal_magnet', 'legal_upstream', 'legal_bypass']),
    'danger': (['danger_fire', 'danger_hg'], ['danger_tape', 'danger_bright', 'danger_calm']),
    'signs': (['signs_fewhot', 'signs_fewdim'], ['signs_crowdhot', 'signs_crowdbright', 'signs_fewbright']),
    'act': (['act_photo', 'act_call'], ['act_argue', 'act_climb', 'act_walk', 'act_close']),
    'remove': (['remove_safe', 'remove_order'], ['remove_live', 'remove_notest', 'remove_noearth', 'remove_alone']),
}
HAND = 4

# The round's answer itself (see the module doc): in the danger round the
# spark and the fire are the harm the prompt asks about, so they may sit on a
# safe card alone. Mirrored in test/learn_board_75_test.dart.
ANSWER_PROPS = {'danger': {'spark', 'fire'}}

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')
_PROP = re.compile(r'<!--prop:(\w+)-->')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for c in safes + traps:
            if 'worker' not in props[c]:
                problems.append(f'{rnd}: {c} has no lineman')
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
                lone = props[s] - set().union(*(props[t] for t in hand)) - ANSWER_PROPS.get(rnd, set())
                if lone:
                    problems.append(f'{rnd}: {s} with {hand} has props {sorted(lone)} alone')
                every = set.intersection(*(props[t] for t in hand)) - props[s]
                if every:
                    problems.append(f'{rnd}: every trap in {hand} has {sorted(every)}, {s} has not')
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
