"""Picture cards for lesson 7.1 শেখা ("ইলেকট্রিসিটি অ্যাক্ট ও CEA রেগুলেশন: আপনার বাইবেল").

python -I tool/m7_board71_art.py .

Writes assets/game/art/m7_board71/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only label a worker reads (the Act's year on its cover) is
drawn as stroke glyphs with English digits.

What the cards show comes from the live lesson 7.1 text and the Module 7
rulings (docs/module_specs/module7_rulings.md; X3: the live CEA 2023
regulation numbers 3 / 20 / 43 ও 50) only:
  1. book: where the rulebook is followed — the Electricity Act, 2003 taken
     from the office shelf, the CEA safety regulations booklet open in a
     lineman's hand. Traps: the book
     locked away for engineers only, a senior's own notebook, a contractor's
     own rules board (the CEA booklet pushed aside), a dusty file left as
     "only paper";
  2. plate: Reg 20 — a danger plate fixed on the transformer, on the feeder
     pillar's door. Traps: no plate on the transformer, a bare pillar door,
     the plate unscrewed and lying on the ground;
  3. earth: Reg 43 and 50 — the tank body and the neutral both earthed, the
     pillar's metal body earthed. Traps: the body's earth lead cut, the
     neutral's lead hanging loose, a pillar with no earth lead;
  4. person: Reg 3 — a trained lineman showing his ID (with the brass
     training seal of his certificate) and a signed, stamped
     authorization; a lineman with his training certificate and the signed
     authorization. Traps: the consumer's son on the pole with pliers, a
     training certificate with a blank authorization, a helper who learned by
     watching reaching for the line, the local electrician at an open pillar;
  5. ask: the work looks unsafe — question the supervisor with the rulebook,
     ask the store for the right tools and PPE. Traps: climbing up without a
     word, starting with whatever is at hand, telling the officer "knowing
     the rules is not my job", throwing the rulebook away as a burden.
How training and authorization show in the field (a brass seal for
training, a stamped, signed letter for authorization) is a game device (item
spec, unsupported[4]).

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
    print('usage: python -I tool/m7_board71_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board71')
W, H = 200, 220
GY = 198

SHIRT_D = '#174A70'
SHIRT = '#1F5F8F'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
GREY_HAIR = '#B8B8B0'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
WHITE_H = '#F2F4F5'      # the supervisor's white helmet
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
INK = '#4A5560'
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
RED = '#D8402F'
GREEN = '#3E9B4F'
EARTH_Y = '#E8C830'
BRASS = '#C9A43A'
BOOK_R = '#8E3A2C'       # the Act's maroon cover
BOOK_B = '#2F5D8C'       # the CEA booklet's blue cover
STAMP = '#6A4FA0'        # an office stamp's violet ink
LUNGI = '#6A4FA0'        # a check lungi (the same violet)
KURTA_D = '#7A6A3A'
KURTA = '#93824E'
OFF_D = '#C9CED2'        # the supervisor's / officer's light shirt sleeves
OFF = '#DDE1E4'
DUST = '#9A938A'
COPPER = '#B8733A'       # bare copper strands at a cut lead
SUN = '#FFE08A'
MOVE = '#FFFFFF'
PLATE = '#FAFAF5'        # the danger plate's enamel

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="0.78" stop-color="#D6E7F0"/><stop offset="0.78" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.78" stop-color="#E2E6DE"/><stop offset="0.78" stop-color="#B9B39E"/><stop offset="1" stop-color="#A39C84"/></linearGradient>
  <linearGradient id="office" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8E2D2"/><stop offset="0.8" stop-color="#D9D1BC"/><stop offset="0.8" stop-color="#8F7F66"/><stop offset="1" stop-color="#7A6B54"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="pillar" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#B4C2B0"/><stop offset="1" stop-color="#7F9180"/></linearGradient>
  <linearGradient id="conc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C4C1B8"/><stop offset="1" stop-color="#9C988C"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A8774A"/><stop offset="1" stop-color="#7E5534"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#DDEEF6" stop-opacity="0.55"/><stop offset="1" stop-color="#A9C9D8" stop-opacity="0.45"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="kurta" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A6A3A"/><stop offset="0.5" stop-color="#A3925C"/><stop offset="1" stop-color="#6E5F33"/></linearGradient>
  <linearGradient id="offshirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9CED2"/><stop offset="0.5" stop-color="#EEF1F3"/><stop offset="1" stop-color="#BFC5CA"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
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
# People: the lineman (blue shirt, yellow helmet), a civilian (kurta, check
# lungi, no helmet), the supervisor / officer (light shirt, white helmet).
# --------------------------------------------------------------------------

KINDS = {
    #            body           sleeves (back, front)  legs (back, front)  helmet            hair
    'lineman': ('url(#shirt)', (SHIRT_D, SHIRT), (PANTS_D, PANTS), (HELMET, HELMET_D), HAIR),
    'senior': ('url(#shirt)', (SHIRT_D, SHIRT), (PANTS_D, PANTS), (HELMET, HELMET_D), GREY_HAIR),
    'civil': ('url(#kurta)', (KURTA_D, KURTA), (LUNGI, LUNGI), None, HAIR),
    'helper': ('url(#kurta)', (KURTA_D, KURTA), (PANTS_D, PANTS), (HELMET, HELMET_D), HAIR),
    'officer': ('url(#offshirt)', (OFF_D, OFF), (PANTS_D, PANTS), (WHITE_H, OFF_D), HAIR),
}


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


def figure(hip, sh, head, feet, hands, face=1, look=0, gloves=True, kind='lineman', props_front=''):
    body, sleeves, legs, helmet, hair = KINDS[kind]
    hand_c = GLOVE if gloves else SKIN
    g = []
    fb, ff = feet
    g.append(_limb(hip, _joint(hip, fb, face), fb, legs[0], 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, _joint(hip, ff, face), ff, legs[1], 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    g.append(_limb(sb, _joint(sb, hb, face, down=True), hb, sleeves[0], 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{hand_c}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="{body}"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{legs[0]}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{hair}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if helmet:
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{helmet[0]}"/>')
        hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{helmet[1]}"/>')
    else:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Q{f(hx)} {f(hy - 4)} {f(hx - 7)} {f(hy - 1)} Z" fill="{hair}"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, _joint(sf, hf, face, down=True), hf, sleeves[1], 5.4))
    g.append(props_front)
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{hand_c}"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, gloves=True, kind='lineman', s=S):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, gloves, kind)
    return f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'


# --------------------------------------------------------------------------
# Glyphs: English digits as seven-segment strokes.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}


def glyphs(x, y, text, h=10.0, color=INK, w=None):
    k = h / 10
    d = []
    ox = x
    for ch in text:
        if ch == ' ':
            ox += 4.5 * k
            continue
        sx = ox - 4 * k if ch == '1' else ox
        for s in _DIG[ch]:
            x0, y0, x1, y1 = _SEG[s]
            d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
        ox += (5.4 if ch == '1' else 7.8) * k
    sw = w if w is not None else 1.5 * k
    return (f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(sw)}" stroke-linecap="round" '
            f'stroke-linejoin="round" fill="none"/>')


# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def line_pole(x=150, top=18):
    """A line pole with its cross-arm, three insulators and the conductors."""
    o = [pole(x, top),
         f'<rect x="{x - 30}" y="{top + 8}" width="60" height="5" fill="url(#steel)"/>']
    for dx in (-24, 0, 24):
        o.append(f'<rect x="{x + dx - 3}" y="{top}" width="6" height="9" rx="1.5" fill="url(#porc)"/>')
    o.append(f'<path d="M0 {top + 2} L{W} {top + 1} M0 {top + 1} L{W} {top} M0 {top + 3} L{W} {top + 2}" stroke="{WIRE}" stroke-width="1.1"/>')
    # step bolts
    for i in range(6):
        y = top + 40 + i * 22
        o.append(f'<path d="M{x - 4} {y} h-5 M{x + 4} {y + 11} h5" stroke="{WIRE}" stroke-width="1.6" stroke-linecap="round"/>')
    return ''.join(o)


def motion(x, y, dx=0, dy=-1, n=3, length=8):
    o = []
    px, py = -dy, dx
    for i in range(n):
        ox, oy = px * (i - 1) * 5, py * (i - 1) * 5
        o.append(f'<path d="M{f(x + ox)} {f(y + oy)} l{f(dx * length)} {f(dy * length)}"/>')
    return f'<g stroke="{MOVE}" stroke-width="1.8" stroke-linecap="round" opacity="0.9">{"".join(o)}</g>'


def earth_lead(d, w=2.6):
    """An earth lead (green with yellow stripes) along the path [d]."""
    return (f'<path d="{d}" stroke="{GREEN}" stroke-width="{w}" fill="none" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-dasharray="4 4" stroke-linejoin="round"/>')


def earth_pit(x, y=GY + 4):
    """An earth pit: a concrete cover in the ground, the electrode's head."""
    return (f'<rect x="{f(x - 9)}" y="{f(y - 3)}" width="18" height="7" rx="1.5" fill="url(#conc)"/>'
            f'<circle cx="{f(x)}" cy="{f(y - 3)}" r="2.6" fill="url(#steel)"/>')


def padlock(x, y):
    return (f'<path d="M{f(x - 3)} {f(y)} v-4 a3 3 0 0 1 6 0 v4" stroke="url(#steel)" stroke-width="1.8" fill="none"/>'
            f'<rect x="{f(x - 5)}" y="{f(y)}" width="10" height="8" rx="1.5" fill="{HELMET_D}"/>')


def pliers(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x)} {f(y)})">'
            f'<path d="M{f(x - 3)} {f(y - 6)} L{f(x - 1.5)} {f(y + 8)} M{f(x + 3)} {f(y - 6)} L{f(x + 1.5)} {f(y + 8)}" stroke="url(#steel)" stroke-width="3" stroke-linecap="round"/>'
            f'<circle cx="{f(x)}" cy="{f(y + 8)}" r="2.4" fill="url(#steel)"/>'
            f'<path d="M{f(x - 1.5)} {f(y + 9)} L{f(x - 6)} {f(y + 24)} M{f(x + 1.5)} {f(y + 9)} L{f(x + 6)} {f(y + 24)}" stroke="{RED}" stroke-width="4" stroke-linecap="round"/></g>')


def shelf(x, y, w=70, books=(BOOK_R, BOOK_B, BOOK_R)):
    """A wooden wall shelf with books standing on it (brass spine bands)."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="5" rx="1" fill="url(#wood)"/>']
    bx = x + 4
    for i, c in enumerate(books):
        bh = 24 - (i % 2) * 4
        o.append(f'<rect x="{f(bx)}" y="{f(y - bh)}" width="9" height="{f(bh)}" rx="1" fill="{c}"/>')
        o.append(f'<path d="M{f(bx)} {f(y - bh + 4)} h9 M{f(bx)} {f(y - 4)} h9" stroke="{BRASS}" stroke-width="1.2"/>')
        bx += 11
    return ''.join(o)


def act_book(x, y, s=1.0):
    """The Electricity Act, 2003 standing face-out: maroon cover, brass
    border, the year in brass glyphs."""
    w, h = 34 * s, 46 * s
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{BOOK_R}"/>'
            f'<rect x="{f(x + 3 * s)}" y="{f(y + 3 * s)}" width="{f(w - 6 * s)}" height="{f(h - 6 * s)}" rx="1.5" fill="none" stroke="{BRASS}" stroke-width="1"/>'
            f'<path d="M{f(x + 8 * s)} {f(y + 12 * s)} h{f(w - 16 * s)} M{f(x + 10 * s)} {f(y + 17 * s)} h{f(w - 20 * s)}" stroke="{BRASS}" stroke-width="1.6"/>'
            + glyphs(x + 4.5 * s, y + 28 * s, '2003', 7 * s, BRASS))


def cea_booklet(x, y, s=1.0, open_=False):
    """The CEA safety regulations booklet: blue cover with a brass bolt; open,
    it shows white pages with lines of print."""
    if open_:
        w, h = 44 * s, 30 * s
        o = [f'<path d="M{f(x)} {f(y)} L{f(x + w / 2)} {f(y + 3 * s)} L{f(x + w)} {f(y)} L{f(x + w)} {f(y + h)} L{f(x + w / 2)} {f(y + h + 3 * s)} L{f(x)} {f(y + h)} Z" fill="{BOOK_B}"/>',
             f'<path d="M{f(x + 2 * s)} {f(y + 2 * s)} L{f(x + w / 2)} {f(y + 5 * s)} L{f(x + w - 2 * s)} {f(y + 2 * s)} L{f(x + w - 2 * s)} {f(y + h - 2 * s)} L{f(x + w / 2)} {f(y + h + 1 * s)} L{f(x + 2 * s)} {f(y + h - 2 * s)} Z" fill="{PAPER}"/>']
        for i in range(4):
            yy = y + (9 + i * 5) * s
            o.append(f'<path d="M{f(x + 5 * s)} {f(yy)} l{f(14 * s)} {f(1.5 * s)} M{f(x + w - 5 * s)} {f(yy)} l{f(-14 * s)} {f(1.5 * s)}" stroke="{INK}" stroke-width="0.8"/>')
        return ''.join(o)
    w, h = 26 * s, 36 * s
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{BOOK_B}"/>'
            f'<path d="M{f(x + 15 * s)} {f(y + 8 * s)} L{f(x + 9 * s)} {f(y + 19 * s)} L{f(x + 14 * s)} {f(y + 19 * s)} L{f(x + 11 * s)} {f(y + 29 * s)} L{f(x + 18 * s)} {f(y + 16 * s)} L{f(x + 13 * s)} {f(y + 16 * s)} Z" fill="{BRASS}"/>')


def paper(x, y, w=22, h=28, lines=4, ang=0):
    o = [f'<g transform="rotate({ang} {f(x + w / 2)} {f(y + h / 2)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>']
    for i in range(lines):
        o.append(f'<path d="M{f(x + 3)} {f(y + 5 + i * 5)} h{f(w - 6 - (i % 2) * 4)}" stroke="{INK}" stroke-width="0.8"/>')
    o.append('</g>')
    return ''.join(o)


def letter(x, y, stamped=True, ang=0):
    """An authorization letter: print lines; signed and stamped (violet round
    stamp, ink signature) or left blank at the foot."""
    w, h = 24, 30
    o = [f'<g transform="rotate({ang} {f(x + w / 2)} {f(y + h / 2)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>']
    for i in range(3):
        o.append(f'<path d="M{f(x + 3)} {f(y + 5 + i * 4.5)} h{f(18 - (i % 2) * 5)}" stroke="{INK}" stroke-width="0.8"/>')
    if stamped:
        o.append(f'<circle cx="{f(x + 7)}" cy="{f(y + 23)}" r="4.2" fill="none" stroke="{STAMP}" stroke-width="1.3"/>')
        o.append(f'<path d="M{f(x + 13)} {f(y + 24)} q2 -4 3 0 t3 -1 t3 1" stroke="{INK}" stroke-width="0.9" fill="none"/>')
    else:
        o.append(f'<path d="M{f(x + 3)} {f(y + 25)} h7 M{f(x + 13)} {f(y + 25)} h8" stroke="{INK}" stroke-width="0.5" stroke-dasharray="1.5 1.5"/>')
    o.append('</g>')
    return ''.join(o)


def certificate(x, y, ang=0):
    """A training certificate: a border, print lines, a brass seal and a red
    ribbon."""
    w, h = 30, 22
    return (f'<g transform="rotate({ang} {f(x + w / 2)} {f(y + h / 2)})">'
            f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="1" fill="{PAPER}" stroke="{BRASS}" stroke-width="1.2"/>'
            f'<path d="M{f(x + 5)} {f(y + 6)} h20 M{f(x + 7)} {f(y + 10)} h16" stroke="{INK}" stroke-width="0.8"/>'
            f'<path d="M{f(x + 20)} {f(y + 15)} l-2 8 M{f(x + 22)} {f(y + 15)} l2 8" stroke="{RED}" stroke-width="1.6"/>'
            + training_seal(x + 21, y + 15) + '</g>')


def training_seal(cx, cy, r=3.2):
    """The training mark: the certificate's round brass seal (a game device
    for "trained"; the same seal sits on the ID card of a trained lineman)."""
    return f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{BRASS}"/>'


def id_card(x, y, ang=0, trained=True):
    """A company ID card: photo, print lines and, for a trained lineman, the
    brass training seal in the corner."""
    return (f'<g transform="rotate({ang} {f(x + 11)} {f(y + 8)})">'
            f'<rect x="{f(x)}" y="{f(y)}" width="22" height="16" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            f'<rect x="{f(x + 2.5)}" y="{f(y + 3)}" width="7" height="9" fill="{SHIRT}"/>'
            f'<circle cx="{f(x + 6)}" cy="{f(y + 6)}" r="2.4" fill="{SKIN}"/>'
            f'<path d="M{f(x + 12)} {f(y + 5)} h7 M{f(x + 12)} {f(y + 9)} h6" stroke="{INK}" stroke-width="0.8"/>'
            + (training_seal(x + 17, y + 12.4, 2.6) if trained else '') + '</g>')


def danger_plate(x, y, s=1.0, ang=0):
    """A danger plate: white enamel, red border, a skull and a red bolt."""
    w, h = 22 * s, 16 * s
    cx = x + 7 * s
    return (f'<g transform="rotate({ang} {f(x + w / 2)} {f(y + h / 2)})">'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(1.5 * s)}" fill="{PLATE}" stroke="{RED}" stroke-width="{f(1.4 * s)}"/>'
            f'<circle cx="{f(cx)}" cy="{f(y + 6.5 * s)}" r="{f(3.4 * s)}" fill="{WIRE}"/>'
            f'<rect x="{f(cx - 2.2 * s)}" y="{f(y + 8.5 * s)}" width="{f(4.4 * s)}" height="{f(3.4 * s)}" fill="{WIRE}"/>'
            f'<circle cx="{f(cx - 1.3 * s)}" cy="{f(y + 6.2 * s)}" r="{f(0.9 * s)}" fill="{PLATE}"/>'
            f'<circle cx="{f(cx + 1.3 * s)}" cy="{f(y + 6.2 * s)}" r="{f(0.9 * s)}" fill="{PLATE}"/>'
            f'<path d="M{f(x + 17 * s)} {f(y + 2.5 * s)} L{f(x + 13 * s)} {f(y + 8.5 * s)} L{f(x + 16 * s)} {f(y + 8.5 * s)} L{f(x + 14 * s)} {f(y + 13.5 * s)} L{f(x + 19 * s)} {f(y + 7 * s)} L{f(x + 16 * s)} {f(y + 7 * s)} Z" fill="{RED}"/></g>')


def dtr(x, plate=False):
    """A plinth-mounted distribution transformer: concrete plinth, the tank
    with its fins, three HT bushings on top (lines up to the pole), LT
    bushings and the neutral bushing at the side. Returns (svg, points)."""
    o = [f'<rect x="{x - 4}" y="{GY - 14}" width="68" height="16" fill="url(#conc)"/>',
         f'<rect x="{x}" y="{GY - 74}" width="60" height="60" rx="3" fill="url(#tank)"/>']
    for i in range(5):
        o.append(f'<rect x="{x + 6 + i * 11}" y="{GY - 66}" width="4" height="46" rx="1" fill="{WIRE}" fill-opacity="0.25"/>')
    for dx in (12, 30, 48):
        o.append(f'<rect x="{x + dx - 3}" y="{GY - 92}" width="6" height="18" rx="2" fill="url(#porc)"/>')
        o.append(f'<path d="M{x + dx} {GY - 92} L{x + dx + 6} 0" stroke="{WIRE}" stroke-width="1"/>')
    # LT side: three LT bushings and the neutral (the fourth) on the right wall
    for i in range(4):
        o.append(f'<rect x="{x + 60}" y="{GY - 70 + i * 9}" width="8" height="5" rx="1.5" fill="url(#porc)"/>')
    if plate:
        o.append(danger_plate(x + 19, GY - 50, 1.0))
    pts = {'body': (x + 4, GY - 20), 'neutral': (x + 68, GY - 43)}
    return ''.join(o), pts


def feeder_pillar(x, plate=False, holes=False, door_open=False):
    """A feeder pillar on its plinth: a metal box with a door and handle."""
    o = [f'<rect x="{x - 3}" y="{GY - 10}" width="56" height="12" fill="url(#conc)"/>',
         f'<rect x="{x}" y="{GY - 78}" width="50" height="68" rx="3" fill="url(#pillar)"/>',
         f'<path d="M{x} {GY - 80} L{x + 25} {GY - 88} L{x + 50} {GY - 80} Z" fill="url(#pillar)"/>']
    if door_open:
        o.append(f'<rect x="{x + 4}" y="{GY - 74}" width="42" height="60" rx="2" fill="{WIRE}"/>')
        for i in range(3):
            o.append(f'<rect x="{x + 9 + i * 13}" y="{GY - 66}" width="8" height="18" rx="1" fill="url(#porc)"/>')
        o.append(f'<path d="M{x + 6} {GY - 40} h38" stroke="url(#steel)" stroke-width="3"/>')
        o.append(f'<path d="M{x + 50} {GY - 76} L{x + 66} {GY - 70} L{x + 66} {GY - 18} L{x + 50} {GY - 12} Z" fill="url(#pillar)"/>')
    else:
        o.append(f'<path d="M{x + 25} {GY - 74} v60" stroke="{WIRE}" stroke-width="0.8" stroke-opacity="0.5"/>')
        o.append(f'<rect x="{x + 28}" y="{GY - 48}" width="3" height="10" rx="1" fill="url(#steel)"/>')
        if plate:
            o.append(danger_plate(x + 4, GY - 70, 0.9))
        if holes:
            for hx, hy in ((x + 5, GY - 69), (x + 23, GY - 69), (x + 5, GY - 56), (x + 23, GY - 56)):
                o.append(f'<circle cx="{hx}" cy="{hy}" r="0.9" fill="{WIRE}"/>')
    pts = {'body': (x + 2, GY - 16)}
    return ''.join(o), pts


def table(x, y, w=80):
    """A wooden table (desk or store counter)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="7" rx="1.5" fill="url(#wood)"/>'
            f'<rect x="{f(x + 4)}" y="{f(y + 7)}" width="5" height="{f(GY - y - 7)}" fill="url(#wood)"/>'
            f'<rect x="{f(x + w - 9)}" y="{f(y + 7)}" width="5" height="{f(GY - y - 7)}" fill="url(#wood)"/>')


def speech(x, y):
    """Speech marks beside a mouth (someone is speaking)."""
    return (f'<path d="M{f(x)} {f(y)} q4 -3 8 0 M{f(x + 1)} {f(y + 5)} q5 -3 10 0" stroke="{MOVE}" stroke-width="1.8" '
            'fill="none" stroke-linecap="round"/>')


def dust(x, y, w, h):
    o = []
    for i in range(9):
        o.append(f'<circle cx="{f(x + (i * 37 % w))}" cy="{f(y + (i * 23 % h))}" r="{f(1 + (i % 3) * 0.5)}" fill="{DUST}"/>')
    return ''.join(o)


def cobweb(x, y, r=14):
    o = [f'<g stroke="{MOVE}" stroke-width="0.6" fill="none" opacity="0.8">']
    for a in (0, 30, 60, 90):
        t = math.radians(a)
        o.append(f'<path d="M{x} {y} l{f(math.cos(t) * r)} {f(math.sin(t) * r)}"/>')
    for k in (0.4, 0.7, 1.0):
        o.append(f'<path d="M{f(x + r * k)} {y} Q{f(x + r * k * 0.8)} {f(y + r * k * 0.8)} {x} {f(y + r * k)}"/>')
    o.append('</g>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Round 1 — book: where is the rulebook followed?
# --------------------------------------------------------------------------

def book_card(kind):
    out = card_open('office')
    if kind == 'act':
        # The Act on the site-office shelf, face out; the lineman reaches for it.
        out.append(shelf(98, 96, 92, (BOOK_B, BOOK_R)))
        out.append(act_book(130, 50))
        out.append(paper(20, 40, 24, 30, 4, -4))
        out.append(person(78, ((70, 150), (128, 84)), face=1, look=-10))
    elif kind == 'cea':
        # The CEA booklet open in the lineman's hands; the shelf behind.
        out.append(shelf(110, 70, 80))
        out.append(person(92, ((80, 146), (118, 146)), face=1, look=12))
        out.append(cea_booklet(77, 132, 1.0, open_=True))
    elif kind == 'locked':
        # The books behind a locked glass cupboard; a slip taped on the door.
        out.append(f'<rect x="100" y="40" width="80" height="140" rx="3" fill="url(#wood)"/>')
        out.append(f'<rect x="106" y="46" width="68" height="128" fill="{WIRE}" fill-opacity="0.35"/>')
        out.append(act_book(110, 64, 0.7))
        out.append(cea_booklet(140, 70, 0.8))
        out.append(f'<path d="M106 110 h68" stroke="url(#wood)" stroke-width="4"/>')
        out.append(f'<rect x="106" y="46" width="68" height="128" fill="url(#glass)"/>')
        out.append(f'<path d="M140 46 v128" stroke="url(#steel)" stroke-width="2"/>')
        out.append(padlock(140, 116))
        out.append(paper(150, 124, 18, 14, 2, 3))
        out.append(person(66, ((56, 152), (72, 150)), face=1, look=4))
    elif kind == 'notebook':
        # A senior hands over his own hand-written notebook; the CEA booklet
        # lies shut on the shelf, the Act beside it.
        out.append(shelf(14, 64, 70, (BOOK_R,)))
        out.append(cea_booklet(44, 30, 0.9))
        out.append(person(132, ((116, 128), (110, 124)), face=-1, look=-6, kind='senior'))
        out.append(paper(94, 112, 22, 26, 5, -10))
        out.append(f'<path d="M95 115 q2 -2 4 0 t4 0 t4 0" stroke="{INK}" stroke-width="0.9" fill="none"/>')
        out.append(person(62, ((70, 150), (90, 126)), face=1, look=6))
    elif kind == 'contract':
        # The contractor's own rules board; the CEA booklet pushed aside on
        # the floor, the Act left on the shelf.
        out.append(shelf(14, 50, 50, (BOOK_R, BOOK_B)))
        out.append(f'<rect x="110" y="44" width="70" height="56" rx="2" fill="{PAPER}" stroke="url(#wood)" stroke-width="4"/>')
        for i in range(5):
            out.append(f'<path d="M118 {56 + i * 9} q6 -3 12 0 t12 0 t14 0" stroke="{INK}" stroke-width="1.2" fill="none"/>')
        out.append(f'<path d="M126 100 l-8 98 M164 100 l8 98" stroke="url(#wood)" stroke-width="3"/>')
        out.append(person(112, ((128, 80), (100, 150)), face=1, look=-14, kind='civil'))
        out.append(f'<g transform="rotate(-80 30 186)">{cea_booklet(20, 176, 0.7)}</g>')
        out.append(person(58, ((50, 152), (66, 150)), face=1, look=0))
    elif kind == 'dusty':
        # A dusty file box on the shelf, cobwebbed, stamped across in red.
        out.append(shelf(96, 104, 94, (BOOK_R, BOOK_B, BOOK_R)))
        out.append(f'<rect x="138" y="60" width="48" height="44" rx="2" fill="url(#wood)"/>')
        out.append(paper(144, 52, 30, 14, 2, -3))
        out.append(f'<rect x="146" y="74" width="32" height="12" rx="1" fill="none" stroke="{RED}" stroke-width="1.6" transform="rotate(-8 162 80)"/>')
        out.append(dust(140, 56, 46, 46))
        out.append(cobweb(186, 40, 18))
        out.append(person(70, ((62, 152), (78, 150)), face=1, look=-8))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — plate: Reg 20, a danger plate on every installation.
# --------------------------------------------------------------------------

def plate_card(kind):
    out = card_open('day')
    if kind in ('dtr', 'dtrbare'):
        svg, _ = dtr(96, plate=(kind == 'dtr'))
        out.append(svg)
        out.append(person(56, ((48, 152), (66, 150)), face=1, look=-6))
    elif kind in ('pillar', 'pillarbare', 'ground'):
        svg, _ = feeder_pillar(110, plate=(kind == 'pillar'), holes=(kind == 'ground'))
        out.append(svg)
        if kind == 'ground':
            out.append(danger_plate(76, GY - 9, 1.0, ang=12))
        out.append(person(60, ((52, 152), (70, 150)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — earth: Reg 43 and 50, metal bodies and the neutral earthed.
# --------------------------------------------------------------------------

def earth_card(kind):
    out = card_open('yard')
    if kind in ('dtr', 'bodycut', 'neutral'):
        svg, p = dtr(64)
        out.append(svg)
        bx, by = p['body']
        nx, ny = p['neutral']
        out.append(earth_pit(40))
        out.append(earth_pit(168))
        if kind == 'bodycut':
            out.append(earth_lead(f'M{bx} {by} L{bx - 8} {by + 2}'))
            out.append(earth_lead(f'M{bx - 20} {by + 8} L40 {GY - 2}'))
            out.append(f'<path d="M{bx - 8} {by + 2} l-2 -2 M{bx - 8} {by + 2} l-2 2 M{bx - 20} {by + 8} l2 -3 M{bx - 20} {by + 8} l3 1" stroke="{COPPER}" stroke-width="0.9"/>')
        else:
            out.append(earth_lead(f'M{bx} {by} L{bx - 14} {by + 4} L40 {GY - 2}'))
        if kind == 'neutral':
            out.append(earth_lead(f'M{nx} {ny + 2} L{nx + 14} {ny + 6} Q{nx + 22} {ny + 14} {nx + 18} {ny + 30}'))
        else:
            out.append(earth_lead(f'M{nx} {ny + 2} L{nx + 14} {ny + 6} L168 {GY - 2}'))
        out.append(person(24, ((18, 152), (30, 150)), face=1, look=0, s=1.0))
    else:
        svg, p = feeder_pillar(96)
        out.append(svg)
        bx, by = p['body']
        out.append(earth_pit(70))
        if kind == 'pillar':
            out.append(earth_lead(f'M{bx} {by} L78 {by + 2} L70 {GY - 2}'))
        out.append(person(40, ((32, 152), (50, 150)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — person: Reg 3, only a trained and authorized person.
# --------------------------------------------------------------------------

def person_card(kind):
    out = card_open('day')
    out.append(line_pole(150))
    if kind == 'id':
        # A trained company lineman at the pole shows his ID card (with the
        # brass training seal) and the signed, stamped authorization letter.
        out.append(person(100, ((82, 146), (120, 142)), face=1, look=0))
        out.append(id_card(68, 138, -8))
        out.append(letter(112, 126, True, 6))
    elif kind == 'cert':
        # Training certificate and the signed authorization, both in hand.
        out.append(person(100, ((80, 146), (120, 142)), face=1, look=0))
        out.append(certificate(58, 136, -8))
        out.append(letter(112, 126, True, 6))
    elif kind == 'trained':
        # A training certificate, but the authorization letter's foot is blank.
        out.append(person(100, ((80, 146), (120, 142)), face=1, look=0))
        out.append(certificate(58, 136, -8))
        out.append(letter(112, 126, False, 6))
    elif kind == 'son':
        # The consumer's son climbs the pole with pliers, bare-handed.
        out.append(person(132, ((146, 74), (142, 100)), face=1, look=-30, gy=136, gloves=False, kind='civil', s=1.1))
        out.append(pliers(146, 66, 20))
        out.append(f'<rect x="10" y="120" width="56" height="78" fill="url(#conc)"/>')
        out.append(f'<rect x="22" y="150" width="14" height="48" fill="url(#wood)"/>')
        out.append(f'<rect x="44" y="134" width="14" height="12" fill="{PAPER}"/>')
    elif kind == 'helper':
        # A helper who only learned by watching goes up a bamboo ladder and
        # reaches for the line; a lineman looks on from below.
        out.append(f'<path d="M126 196 L138 40 M142 198 L152 42" stroke="url(#wood)" stroke-width="3"/>')
        for i in range(8):
            y = 186 - i * 19
            out.append(f'<path d="M{f(127 + i * 1.5)} {y} L{f(143 + i * 1.3)} {y + 1}" stroke="url(#wood)" stroke-width="2.4"/>')
        out.append(person(134, ((150, 24), (140, 80)), face=1, look=-40, gy=110, gloves=False, kind='helper', s=1.1))
        out.append(f'<rect x="127" y="76" width="7" height="3" fill="{BRASS}"/>')
        out.append(person(60, ((52, 152), (70, 150)), face=1, look=-30))
    elif kind == 'mistri':
        # The local electrician has opened the feeder pillar's door.
        svg, _ = feeder_pillar(30, door_open=True)
        out.append(svg)
        out.append(paper(36, 100, 16, 12, 2, 0))
        out.append(person(110, ((84, 150), (80, 130)), face=-1, look=-6, gloves=False, kind='civil'))
        out.append(f'<rect x="116" y="176" width="26" height="20" rx="3" fill="{BAG}"/>')
        out.append(f'<rect x="126" y="178" width="6" height="4" fill="{BRASS}"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — ask: the job looks unsafe by the CEA rules.
# --------------------------------------------------------------------------

def ask_card(kind):
    out = card_open('yard')
    out.append(pole(176, 10))
    if kind == 'super':
        # Before the job: the lineman shows the rulebook page to his supervisor.
        out.append(person(64, ((72, 148), (100, 144)), face=1, look=6))
        out.append(cea_booklet(76, 132, 0.8, open_=True))
        out.append(person(140, ((128, 150), (150, 150)), face=-1, look=0, kind='officer'))
        out.append(speech(98, 104))
    elif kind == 'store':
        # At the store counter: a requisition slip for the right tools and PPE.
        out.append(table(92, 140, 84))
        out.append(f'<rect x="100" y="52" width="70" height="4" fill="url(#wood)"/><rect x="100" y="92" width="70" height="4" fill="url(#wood)"/>')
        out.append(f'<path d="M106 52 A8 8 0 0 1 122 52 Z" fill="{HELMET}"/><path d="M128 52 A8 8 0 0 1 144 52 Z" fill="{HELMET}"/>')
        out.append(f'<rect x="150" y="76" width="8" height="16" rx="3" fill="{GLOVE}"/><rect x="160" y="76" width="8" height="16" rx="3" fill="{GLOVE}"/>')
        out.append(f'<path d="M108 92 q6 -14 12 0 M124 92 q6 -14 12 0" stroke="{RED}" stroke-width="2" fill="none"/>')
        out.append(person(140, ((128, 138), (150, 150)), face=-1, look=0, kind='officer'))
        out.append(person(58, ((50, 152), (96, 132)), face=1, look=0))
        out.append(paper(92, 122, 14, 16, 3, 10))
    elif kind == 'silent':
        # Up the pole without a word; the supervisor's back is turned.
        out.append(person(160, ((172, 40), (170, 70)), face=1, look=-30, gy=100, s=1.1))
        out.append(person(70, ((62, 152), (78, 150)), face=-1, look=0, kind='officer'))
    elif kind == 'nokit':
        # Starting with whatever lies about: an old crate of odds and ends, bare
        # hands, pliers off the heap.
        out.append(f'<rect x="96" y="168" width="40" height="30" fill="url(#wood)"/>')
        out.append(f'<path d="M100 168 l10 -12 M118 168 l-4 -16 M128 168 l6 -10" stroke="{RED}" stroke-width="2"/>')
        out.append(paper(104, 150, 14, 10, 1, -20))
        out.append(f'<path d="M30 196 L60 40" stroke="url(#wood)" stroke-width="4"/>')
        out.append(person(78, ((96, 150), (110, 134)), face=1, look=8, gloves=False))
        out.append(pliers(112, 126, 30))
    elif kind == 'excuse':
        # At the office desk, palms up, pushing the rulebook back to the
        # officer: "knowing the rules is not my job".
        out.append(table(96, 140, 90))
        out.append(f'<g transform="rotate(-90 117 133)">{cea_booklet(110, 124, 0.5)}</g>')
        out.append(paper(150, 132, 18, 8, 1, 0))
        out.append(f'<path d="M150 136 h18" stroke="{RED}" stroke-width="1.4"/>')
        out.append(person(150, ((140, 140), (160, 140)), face=-1, look=0, kind='officer'))
        out.append(person(56, ((40, 130), (78, 126)), face=1, look=-6, gloves=False))
        out.append(speech(80, 116))
    elif kind == 'burden':
        # The rulebook tossed aside as a burden, pages flying.
        out.append(person(70, ((62, 152), (100, 96)), face=1, look=-10))
        out.append(f'<g transform="rotate(-30 128 70)">{cea_booklet(116, 54, 0.8)}</g>')
        out.append(paper(150, 100, 12, 14, 2, 20))
        out.append(motion(110, 90, 1, -0.6, 3, 10))
        out.append(person(146, ((136, 150), (156, 150)), face=-1, look=0, kind='officer', s=1.0))
    return card_close(out)


CARDS = {}
for k in ('act', 'cea', 'locked', 'notebook', 'contract', 'dusty'):
    CARDS[f'book_{k}'] = book_card(k)
for k in ('dtr', 'pillar', 'dtrbare', 'pillarbare', 'ground'):
    CARDS[f'plate_{k}'] = plate_card(k)
for k in ('dtr', 'pillar', 'bodycut', 'neutral', 'pillarnone'):
    CARDS[f'earth_{k}'] = earth_card(k)
for k in ('id', 'cert', 'son', 'trained', 'helper', 'mistri'):
    CARDS[f'person_{k}'] = person_card(k)
for k in ('super', 'store', 'silent', 'nokit', 'excuse', 'burden'):
    CARDS[f'ask_{k}'] = ask_card(k)

# Safe cards and traps per round (mirrors learn_board_pack71.dart).
ROUNDS = {
    'book': (['book_act', 'book_cea'], ['book_locked', 'book_notebook', 'book_contract', 'book_dusty']),
    'plate': (['plate_dtr', 'plate_pillar'], ['plate_dtrbare', 'plate_pillarbare', 'plate_ground']),
    'earth': (['earth_dtr', 'earth_pillar'], ['earth_bodycut', 'earth_neutral', 'earth_pillarnone']),
    'person': (['person_id', 'person_cert'], ['person_son', 'person_trained', 'person_helper', 'person_mistri']),
    'ask': (['ask_super', 'ask_store'], ['ask_silent', 'ask_nokit', 'ask_excuse', 'ask_burden']),
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
