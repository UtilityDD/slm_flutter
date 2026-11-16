"""Picture cards for lesson 7.10 শেখা ("একজন 'সার্টিফায়েড' লাইনম্যান: লাইসেন্স ও
যোগ্যতার গুরুত্ব").

python -I tool/m7_board710_art.py .

Writes assets/game/art/m7_board710/*.svg in the clean gradient style of
tool/m6_board63_art.py and tool/m7_board71_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art; the sheets a worker reads (logbook
pages, notices, the register) are stroke lines.

What the cards show comes from the live lesson 7.10 text and the Module 7
rulings (docs/module_specs/module7_rulings.md; X3: the live text has no age
rule, so no card shows an age and no school-age boy is drawn; M7-5: an unfit
man on line work is a breach of the law, worded on the card) only:
  1. comp: who the law calls 'উপযুক্ত' (competent) - a lineman with his
     government certificate whose name is on the company register, a senior
     beside him; a lineman who knows the danger and keeps his crew back. Traps:
     a new man sent up the pole on his first day, a strong labourer with no
     training lifting a cross-arm, a joiner left alone with a booklet, a man
     with a certificate whose name is not on the register;
  2. permit: how a workman permit comes - an ITI certificate, years of work
     in a logbook and an exam; an interview before the state licensing
     board. Traps: experience and no exam, an exam and an empty logbook, the
     company ID shown as the permit;
  3. paper: which paper proves you are fit for a big contractor's job - the
     workman permit, the permit on top of the ITI file. Traps: only a first
     aid and fire safety certificate, empty hands and only words, only an ITI
     certificate;
  4. grow: what a good professional does next - live-line training, HV cable
     jointing certification, first aid and fire safety training. Traps: walking
     past the company's training notice, the new tool left unopened, a lineman
     who knows it all outside a classroom;
  5. habit: the habit that builds a career - a personal logbook, asking the
     senior, a goal and a course to match. Traps: certificates torn in a van,
     a junior silent behind the van, a wall of framed certificates with the
     gloves still in their wrapper.
The brass training seal on a certificate is the game device of tool/
m7_board71_art.py. The workman permit's look (a card with photo, brass seal
and violet stamp) is a game device too; the labels say what it is.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; each card also carries the same small kit bag (brass buckle, red
strap, paper tag, green tag, ...), so no colour is drawn only on a safe card;
the script checks every hand the dealer can make (one safe card + any three
traps): each colour or gradient the safe card draws is drawn by a trap in that
hand, and the safe card's backdrop is a trap's backdrop too. It deletes only
its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board710_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board710')
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
# Props for this board.
# --------------------------------------------------------------------------

def bag(x, y):
    """The kit bag every card carries in a corner: buckle, strap, tags and a
    pen - so no colour is drawn on the safe cards alone."""
    return (f'<g><rect x="{f(x)}" y="{f(y)}" width="30" height="20" rx="4" fill="{BAG}"/>'
            f'<path d="M{f(x + 4)} {f(y + 6)} h22" stroke="{RED}" stroke-width="2.6"/>'
            f'<rect x="{f(x + 12)}" y="{f(y + 4)}" width="6" height="5" rx="1" fill="{BRASS}"/>'
            f'<path d="M{f(x + 8)} {f(y)} q7 -9 14 0" stroke="url(#steel)" stroke-width="2" fill="none"/>'
            f'<rect x="{f(x + 20)}" y="{f(y + 11)}" width="7" height="6" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            f'<circle cx="{f(x + 6)}" cy="{f(y + 14)}" r="2.2" fill="{GREEN}"/>'
            f'<path d="M{f(x + 11)} {f(y + 15)} h7" stroke="{STAMP}" stroke-width="1.6"/>'
            f'<path d="M{f(x + 3)} {f(y + 18)} h9" stroke="{EARTH_Y}" stroke-width="1.8"/>'
            f'<path d="M{f(x + 22)} {f(y + 3)} l3 3" stroke="{COPPER}" stroke-width="1.4"/>'
            f'<rect x="{f(x + 1)}" y="{f(y + 19)}" width="28" height="2" fill="url(#wood)"/>'
            f'<rect x="{f(x + 1)}" y="{f(y + 21)}" width="28" height="1.5" fill="url(#conc)"/>'
            f'<rect x="{f(x + 0.5)}" y="{f(y - 6)}" width="6" height="7" rx="1" fill="{BOOK_B}"/>'
            f'<rect x="{f(x + 24)}" y="{f(y - 6)}" width="5" height="7" rx="1" fill="{BOOK_R}"/></g>')


def qmark(x, y):
    """A hand-drawn question mark (a worker who does not understand)."""
    return (f'<path d="M{f(x)} {f(y + 4)} q0 -7 6 -7 q6 0 6 5 q0 4 -6 6 v3" stroke="{MOVE}" stroke-width="2" fill="none" stroke-linecap="round"/>'
            f'<circle cx="{f(x + 6)}" cy="{f(y + 17)}" r="1.4" fill="{MOVE}"/>')


def register_board(x, y, mine=1, present=True):
    """The company register on a wooden board: a photo and a name line per
    row; his row has a yellow band. [present] False leaves his row empty."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="62" height="78" rx="3" fill="url(#wood)"/>',
         f'<rect x="{f(x + 5)}" y="{f(y + 5)}" width="52" height="68" rx="1.5" fill="{PAPER}"/>',
         f'<rect x="{f(x + 22)}" y="{f(y - 3)}" width="18" height="6" rx="2" fill="url(#steel)"/>']
    for i in range(4):
        yy = y + 10 + i * 15
        if i == mine:
            o.append(f'<rect x="{f(x + 6)}" y="{f(yy - 3)}" width="50" height="14" fill="{EARTH_Y}" fill-opacity="0.45"/>')
        if i == mine and not present:
            o.append(f'<rect x="{f(x + 8)}" y="{f(yy - 1)}" width="46" height="10" fill="none" stroke="{INK}" stroke-width="0.8" stroke-dasharray="2 2"/>')
        else:
            o.append(f'<circle cx="{f(x + 13)}" cy="{f(yy + 4)}" r="4" fill="{SKIN}"/>')
            o.append(f'<path d="M{f(x + 21)} {f(yy + 2)} h{26 - (i % 2) * 6} M{f(x + 21)} {f(yy + 7)} h{18 - (i % 2) * 4}" stroke="{INK}" stroke-width="1"/>')
    return ''.join(o)


def logbook(x, y, full=True, s=1.0):
    """A logbook lying open on a desk: blue cover, pages with many lines (a
    long record) or blank pages."""
    w, h = 40 * s, 24 * s
    o = [f'<rect x="{f(x - 1)}" y="{f(y - 1)}" width="{f(w + 2)}" height="{f(h + 2)}" rx="2" fill="{BOOK_B}"/>',
         f'<rect x="{f(x + 1)}" y="{f(y + 1)}" width="{f(w / 2 - 1.5)}" height="{f(h - 2)}" fill="{PAPER}"/>',
         f'<rect x="{f(x + w / 2 + 0.5)}" y="{f(y + 1)}" width="{f(w / 2 - 1.5)}" height="{f(h - 2)}" fill="{PAPER}"/>']
    if full:
        for i in range(5):
            yy = y + (5 + i * 3.8) * s
            o.append(f'<path d="M{f(x + 4 * s)} {f(yy)} h{f(13 * s)} M{f(x + w / 2 + 3 * s)} {f(yy)} h{f(13 * s)}" stroke="{INK}" stroke-width="0.7"/>')
    return ''.join(o)


def exam_sheet(x, y, ticks=True, ang=0):
    """An answer sheet: print lines, with a tick against each (done) or none."""
    o = [f'<g transform="rotate({ang} {f(x + 11)} {f(y + 14)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="22" height="28" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>']
    for i in range(4):
        o.append(f'<path d="M{f(x + 7)} {f(y + 6 + i * 5.5)} h12" stroke="{INK}" stroke-width="0.8"/>')
        if ticks:
            o.append(f'<path d="M{f(x + 2)} {f(y + 6 + i * 5.5)} l1.5 1.8 l3 -3.4" stroke="{GREEN}" stroke-width="1" fill="none"/>')
    o.append('</g>')
    return ''.join(o)


def permit_card(x, y, ang=0, s=1.0):
    """The workman permit: a card with a blue header, the holder's photo, print
    lines, a brass seal and a violet office stamp (a game device)."""
    w, h = 36 * s, 25 * s
    return (f'<g transform="rotate({ang} {f(x + w / 2)} {f(y + h / 2)})">'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(2 * s)}" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(6 * s)}" rx="{f(2 * s)}" fill="{BOOK_B}"/>'
            f'<rect x="{f(x + 3 * s)}" y="{f(y + 9 * s)}" width="{f(9 * s)}" height="{f(11 * s)}" fill="{SHIRT}"/>'
            f'<circle cx="{f(x + 7.5 * s)}" cy="{f(y + 12.5 * s)}" r="{f(3 * s)}" fill="{SKIN}"/>'
            f'<path d="M{f(x + 15 * s)} {f(y + 11 * s)} h{f(15 * s)} M{f(x + 15 * s)} {f(y + 15 * s)} h{f(11 * s)}" stroke="{INK}" stroke-width="{f(1 * s)}"/>'
            f'<circle cx="{f(x + 29 * s)}" cy="{f(y + 19.5 * s)}" r="{f(3 * s)}" fill="{BRASS}"/>'
            f'<circle cx="{f(x + 20 * s)}" cy="{f(y + 19 * s)}" r="{f(3.6 * s)}" fill="none" stroke="{STAMP}" stroke-width="{f(1.2 * s)}"/></g>')


def emblem(x, y):
    """A state licensing board's wall emblem: a brass ring on a plaque."""
    return (f'<rect x="{f(x - 18)}" y="{f(y - 18)}" width="36" height="36" rx="4" fill="url(#wood)"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="12" fill="none" stroke="{BRASS}" stroke-width="3"/>'
            f'<path d="M{f(x - 6)} {f(y + 4)} L{f(x)} {f(y - 7)} L{f(x + 6)} {f(y + 4)} Z" fill="{BRASS}"/>')


def clipboard(x, y, ang=0):
    return (f'<g transform="rotate({ang} {f(x + 10)} {f(y + 13)})"><rect x="{f(x)}" y="{f(y)}" width="20" height="26" rx="2" fill="url(#wood)"/>'
            f'<rect x="{f(x + 2)}" y="{f(y + 4)}" width="16" height="20" fill="{PAPER}"/>'
            f'<path d="M{f(x + 4)} {f(y + 9)} h12 M{f(x + 4)} {f(y + 13)} h10 M{f(x + 4)} {f(y + 17)} h12" stroke="{INK}" stroke-width="0.8"/>'
            f'<rect x="{f(x + 6)}" y="{f(y - 1)}" width="8" height="5" rx="1.5" fill="url(#steel)"/></g>')


def hot_stick(x0, y0, x1, y1):
    """A live-line (hot) stick: a long insulated rod with a hook at its tip."""
    return (f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{HELMET}" stroke-width="3.2" stroke-linecap="round"/>'
            f'<path d="M{f(x0 + (x1 - x0) * 0.35)} {f(y0 + (y1 - y0) * 0.35)} L{f(x0 + (x1 - x0) * 0.42)} {f(y0 + (y1 - y0) * 0.42)}" stroke="{RED}" stroke-width="3.4"/>'
            f'<path d="M{f(x1)} {f(y1)} q-4 -3 -6 -8" stroke="url(#steel)" stroke-width="2.2" fill="none"/>')


def extinguisher(x, y):
    return (f'<rect x="{f(x - 6)}" y="{f(y)}" width="12" height="30" rx="4" fill="{RED}"/>'
            f'<rect x="{f(x - 3)}" y="{f(y - 5)}" width="6" height="6" fill="url(#steel)"/>'
            f'<path d="M{f(x + 3)} {f(y - 3)} q8 0 8 10" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')


def first_aid_box(x, y):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="28" height="20" rx="3" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 14)} {f(y + 4)} v12 M{f(x + 8)} {f(y + 10)} h12" stroke="{RED}" stroke-width="3.4"/>')


def cable_end(x, y):
    """A cable's cut end: black sheath, coloured cores, copper centres."""
    o = [f'<rect x="{f(x - 30)}" y="{f(y - 9)}" width="30" height="18" rx="3" fill="{WIRE}"/>',
         f'<circle cx="{f(x)}" cy="{f(y)}" r="9" fill="{WIRE}"/>']
    for dx, dy, c in ((-3, -3, RED), (3, -3, SHIRT), (0, 3, EARTH_Y)):
        o.append(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="3.4" fill="{c}"/>')
        o.append(f'<circle cx="{f(x + dx)}" cy="{f(y + dy)}" r="1.4" fill="{COPPER}"/>')
    return ''.join(o)


def notice(x, y, w=40, h=48, ring=False):
    """A notice sheet on a post board: a blue heading, print lines and a
    helmet sign; [ring] circles it in red."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="2" fill="{PAPER}" stroke="{BAG}" stroke-width="3"/>',
         f'<rect x="{f(x + 4)}" y="{f(y + 5)}" width="{f(w - 8)}" height="7" fill="{BOOK_B}"/>',
         f'<path d="M{f(x + 6)} {f(y + 18)} h{f(w - 12)} M{f(x + 6)} {f(y + 24)} h{f(w - 18)}" stroke="{INK}" stroke-width="1"/>',
         f'<path d="M{f(x + w / 2 - 7)} {f(y + h - 8)} A7 7 0 0 1 {f(x + w / 2 + 7)} {f(y + h - 8)} Z" fill="{HELMET}"/>']
    if ring:
        o.append(f'<ellipse cx="{f(x + w / 2)}" cy="{f(y + h / 2)}" rx="{f(w / 2 + 6)}" ry="{f(h / 2 + 6)}" fill="none" stroke="{RED}" stroke-width="2.4"/>')
    return ''.join(o)


def frame(x, y):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="26" height="20" fill="{PAPER}" stroke="{BRASS}" stroke-width="2.4"/>'
            f'<path d="M{f(x + 5)} {f(y + 7)} h16 M{f(x + 7)} {f(y + 12)} h12" stroke="{INK}" stroke-width="0.9"/>'
            f'<circle cx="{f(x + 20)}" cy="{f(y + 14)}" r="2" fill="{RED}"/>')


# --------------------------------------------------------------------------
# Round 1 - comp: who does the law call 'উপযুক্ত'?
# --------------------------------------------------------------------------

def comp_card(kind):
    out = card_open('yard')
    out.append(bag({'cert': 8, 'aware': 150, 'new': 10, 'strong': 152, 'booklet': 80, 'noreg': 150}[kind], 176))
    if kind == 'cert':
        out.append(line_pole(178, 20))
        out.append(register_board(10, 60, 1, True))
        out.append(person(102, ((92, 150), (118, 138)), face=1, look=0))
        out.append(certificate(108, 126, -6))
        out.append(person(146, ((136, 150), (156, 150)), face=-1, look=4, kind='senior'))
    elif kind == 'aware':
        out.append(line_pole(150, 20))
        out.append(danger_plate(136, 96, 1.2))
        out.append(person(24, ((30, 152), (40, 150)), face=1, look=0, kind='helper', s=1.0))
        out.append(person(78, ((50, 126), (108, 116)), face=1, look=-6))
    elif kind == 'new':
        out.append(line_pole(140, 18))
        out.append(person(96, ((88, 150), (118, 116)), face=1, look=-18, gloves=False, kind='helper'))
        out.append(danger_plate(126, 92, 1.1))
        out.append(person(40, ((32, 150), (78, 92)), face=1, look=-6, kind='lineman'))
    elif kind == 'strong':
        out.append(line_pole(176, 20))
        out.append(danger_plate(162, 96, 1.1))
        out.append(person(142, ((134, 150), (156, 150)), face=-1, look=-4, kind='senior', s=1.1))
        out.append(person(78, ((50, 82), (108, 80)), face=1, look=-6, gloves=False, kind='civil', s=1.55))
        out.append('<rect x="38" y="76" width="84" height="6" fill="url(#steel)"/>')
        for dx in (46, 80, 114):
            out.append(f'<rect x="{dx - 3}" y="68" width="6" height="9" rx="1.5" fill="url(#porc)"/>')
    elif kind == 'booklet':
        out.append(pole(30, 24))
        out.append('<rect x="54" y="168" width="44" height="30" rx="2" fill="url(#wood)"/>')
        out.append(person(76, ((64, 148), (88, 144)), face=1, look=8, gloves=False, kind='helper', gy=170, s=1.15))
        out.append(cea_booklet(60, 128, 0.9, open_=True))
        out.append(qmark(104, 70))
        out.append(person(158, ((148, 150), (170, 150)), face=1, look=0, kind='officer', s=1.2))
        out.append(speech(170, 100))
    elif kind == 'noreg':
        out.append(register_board(12, 60, 1, False))
        out.append(person(104, ((92, 150), (120, 138)), face=1, look=0))
        out.append(certificate(110, 126, -6))
        out.append(person(160, ((150, 150), (146, 112)), face=-1, look=0, kind='senior'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 - permit: how a workman permit comes.
# --------------------------------------------------------------------------

def permit_scene(kind):
    out = card_open('office')
    out.append(bag({'path': 8, 'board': 8, 'expnoexam': 8, 'examnoexp': 150, 'compid': 8}[kind], 176))
    if kind == 'path':
        out.append(person(40, ((48, 150), (70, 138)), face=1, look=4))
        out.append(table(66, 140, 128))
        out.append(certificate(76, 118, -2))
        out.append(logbook(114, 116, True))
        out.append(exam_sheet(160, 112, True, 4))
    elif kind == 'board':
        out.append(emblem(150, 50))
        out.append(person(44, ((36, 150), (66, 146)), face=1, look=2))
        out.append(speech(76, 118))
        out.append(person(128, ((120, 150), (138, 146)), face=-1, look=0, kind='officer', s=1.2))
        out.append(person(170, ((162, 150), (178, 146)), face=-1, look=0, kind='officer', s=1.2))
        out.append(table(96, 148, 100))
        out.append(clipboard(110, 128, -4))
    elif kind == 'expnoexam':
        out.append(person(56, ((46, 150), (96, 112)), face=1, look=-4, kind='senior'))
        out.append(exam_sheet(104, 100, False, 28))
        out.append(motion(112, 124, 1, 0.3, 3, 9))
        out.append(table(122, 150, 72))
        out.append(logbook(132, 126, True))
    elif kind == 'examnoexp':
        out.append(person(56, ((46, 150), (70, 134)), face=1, look=0))
        out.append(certificate(62, 124, -4))
        out.append(table(104, 150, 90))
        out.append(logbook(112, 126, False))
        out.append(exam_sheet(158, 122, True, 0))
    elif kind == 'compid':
        out.append(person(56, ((46, 150), (84, 124)), face=1, look=0))
        out.append(id_card(78, 112, -6, trained=False))
        out.append(table(104, 150, 90))
        out.append(paper(122, 124, 24, 26, 3, 0))
        out.append(person(160, ((152, 150), (146, 110)), face=-1, look=0, kind='officer'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 - paper: which paper proves your fitness to a big contractor?
# --------------------------------------------------------------------------

def paper_scene(kind):
    out = card_open('office')
    out.append(bag({'permit': 8, 'withiti': 150, 'firstaid': 8, 'word': 150, 'iti': 8}[kind], 176))
    if kind == 'permit':
        out.append(person(52, ((44, 150), (88, 128)), face=1, look=0))
        out.append(permit_card(82, 116, -4, 1.1))
        out.append(table(112, 148, 82))
        out.append(paper(150, 122, 22, 28, 3, 0))
        out.append(person(166, ((158, 150), (140, 134)), face=-1, look=0, kind='officer', s=1.2))
    elif kind == 'withiti':
        out.append(person(30, ((24, 150), (50, 140)), face=1, look=0, kind='officer', s=1.2))
        out.append(table(54, 146, 92))
        out.append(f'<rect x="70" y="126" width="48" height="20" rx="2" fill="{BAG}"/>')
        out.append(certificate(76, 120, 3))
        out.append(permit_card(78, 108, -3, 1.1))
        out.append(person(166, ((172, 150), (140, 138)), face=-1, look=0))
    elif kind == 'firstaid':
        out.append(person(48, ((40, 150), (84, 126)), face=1, look=0))
        out.append(certificate(70, 118, -4))
        out.append(f'<path d="M96 126 v8 M92 130 h8" stroke="{RED}" stroke-width="2.4"/>')
        out.append(first_aid_box(118, 176))
        out.append(extinguisher(170, 168))
        out.append(person(128, ((120, 140), (138, 138)), face=-1, look=0, kind='officer', s=1.2))
    elif kind == 'word':
        out.append(person(52, ((40, 148), (84, 132)), face=1, look=0))
        out.append(speech(88, 110))
        out.append(person(150, ((142, 140), (160, 138)), face=-1, look=0, kind='officer'))
        out.append(table(80, 150, 40))
    elif kind == 'iti':
        out.append(person(52, ((44, 150), (88, 128)), face=1, look=0))
        out.append(certificate(78, 116, -4))
        out.append(f'<path d="M104 124 l6 6 M110 124 l-6 6" stroke="{INK}" stroke-width="1.6"/>')
        out.append(table(112, 148, 82))
        out.append(person(166, ((158, 150), (140, 134)), face=-1, look=0, kind='officer', s=1.2))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 - grow: what a good professional does next.
# --------------------------------------------------------------------------

def grow_scene(kind):
    out = card_open('day')
    out.append(bag({'live': 8, 'hv': 150, 'aid': 8, 'skip': 150, 'old': 8, 'knowall': 150}[kind], 176))
    if kind == 'live':
        out.append(line_pole(160, 18))
        out.append(person(54, ((46, 150), (78, 118)), face=1, look=-4, kind='senior', s=1.2))
        out.append(person(104, ((96, 150), (112, 126)), face=1, look=-14))
        out.append(hot_stick(98, 148, 150, 26))
    elif kind == 'hv':
        out.append(person(32, ((26, 150), (46, 122)), face=1, look=0, kind='officer', s=1.2))
        out.append(clipboard(44, 112, -6))
        out.append(person(150, ((142, 140), (122, 136)), face=-1, look=8))
        out.append(table(54, 148, 120))
        out.append(cable_end(118, 140))
        out.append(f'<rect x="60" y="136" width="30" height="12" rx="2" fill="{COPPER}"/>')
    elif kind == 'aid':
        out.append('<rect x="20" y="186" width="120" height="12" rx="3" fill="url(#conc)"/>')
        out.append('<rect x="46" y="176" width="50" height="12" rx="5" fill="url(#offshirt)"/>')
        out.append(f'<circle cx="38" cy="180" r="8" fill="{SKIN}"/>')
        out.append(f'<rect x="94" y="180" width="26" height="8" rx="3" fill="{PANTS}"/>')
        out.append(person(100, ((86, 150), (66, 174)), face=-1, look=8))
        out.append(extinguisher(172, 160))
    elif kind == 'skip':
        out.append('<rect x="16" y="60" width="4" height="138" fill="url(#wood)"/><rect x="74" y="60" width="4" height="138" fill="url(#wood)"/>')
        out.append(notice(18, 70, 56, 62))
        out.append('<path d="M160 92 L190 92 L190 160 L130 160 L130 92 Z" fill="url(#conc)"/>')
        out.append('<path d="M124 96 L160 66 L196 96 Z" fill="url(#porc)"/>')
        out.append('<rect x="150" y="120" width="16" height="40" fill="url(#wood)"/>')
        out.append(person(100, ((90, 148), (112, 154)), face=1, look=0))
        out.append(motion(86, 150, -1, 0, 3, 9))
        out.append(person(176, ((168, 150), (186, 150)), face=-1, look=0, kind='officer', s=1.0))
    elif kind == 'old':
        out.append(line_pole(166, 18))
        out.append(person(100, ((90, 150), (122, 128)), face=1, look=-6))
        out.append(pliers(124, 112, 26))
        out.append(person(66, ((58, 150), (76, 150)), face=1, look=0, kind='officer', s=1.0))
        out.append(f'<rect x="20" y="170" width="44" height="28" rx="2" fill="{BAG}"/>')
        out.append(f'<path d="M20 184 h44 M42 170 v28" stroke="{RED}" stroke-width="3"/>')
        out.append(f'<rect x="38" y="164" width="8" height="8" rx="1" fill="{PAPER}"/>')
    elif kind == 'knowall':
        out.append('<rect x="96" y="40" width="104" height="158" fill="url(#conc)"/>')
        out.append(f'<rect x="108" y="60" width="44" height="34" fill="{WIRE}"/>')
        out.append(f'<path d="M112 70 h18 M112 76 h24 M112 82 h14" stroke="{PAPER}" stroke-width="1.6"/>')
        out.append('<rect x="108" y="102" width="44" height="22" fill="url(#glass)"/>')
        out.append(f'<circle cx="120" cy="114" r="5" fill="{SKIN}"/><circle cx="138" cy="114" r="5" fill="{SKIN}"/>')
        out.append(f'<path d="M115 109 a6 4 0 0 1 10 0 Z M133 109 a6 4 0 0 1 10 0 Z" fill="{HELMET}"/>')
        out.append('<rect x="162" y="120" width="26" height="78" fill="url(#wood)"/>')
        out.append(person(64, ((56, 126), (80, 128)), face=1, look=-6, kind='senior'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 - habit: the habit that builds a career.
# --------------------------------------------------------------------------

def habit_scene(kind):
    out = card_open('yard')
    out.append(bag({'log': 150, 'senior': 8, 'goal': 150, 'norec': 8, 'shy': 150, 'paper': 70}[kind], 176))
    if kind == 'log':
        out.append(shelf(112, 92, 76))
        out.append(f'<rect x="124" y="64" width="22" height="26" fill="{PAPER}" stroke="{BRASS}" stroke-width="2"/>')
        out.append(person(80, ((66, 142), (96, 138)), face=1, look=8))
        out.append(logbook(70, 128, True, 1.0))
        out.append(f'<path d="M104 140 l8 -8" stroke="{STAMP}" stroke-width="2"/>')
    elif kind == 'senior':
        out.append(pole(178, 20))
        out.append(person(48, ((40, 150), (74, 112)), face=1, look=-6))
        out.append(qmark(30, 60))
        out.append(person(124, ((134, 150), (100, 128)), face=-1, look=2, kind='senior'))
        out.append(speech(118, 92))
    elif kind == 'goal':
        out.append('<rect x="98" y="50" width="4" height="148" fill="url(#wood)"/><rect x="170" y="50" width="4" height="148" fill="url(#wood)"/>')
        out.append(notice(106, 66, 58, 70, True))
        out.append(cable_end(146, 112))
        out.append(person(54, ((46, 150), (88, 96)), face=1, look=-8))
        out.append(f'<path d="M88 96 l8 -6" stroke="{RED}" stroke-width="2.4"/>')
    elif kind == 'norec':
        out.append('<rect x="10" y="108" width="100" height="72" rx="6" fill="url(#pillar)"/>')
        out.append('<rect x="20" y="118" width="40" height="30" fill="url(#glass)"/>')
        out.append(f'<circle cx="34" cy="182" r="14" fill="{WIRE}"/><circle cx="34" cy="182" r="6" fill="url(#steel)"/>')
        out.append(f'<rect x="64" y="150" width="46" height="30" fill="{WIRE}"/>')
        for px, py, a in ((70, 168, 20), (86, 176, -30), (100, 164, 60), (118, 188, 10), (132, 182, -20)):
            out.append(paper(px, py, 16, 14, 2, a))
        out.append(person(160, ((150, 144), (172, 142)), face=-1, look=0))
    elif kind == 'shy':
        out.append(pole(178, 20))
        out.append(person(150, ((144, 150), (166, 130)), face=1, look=0, kind='senior'))
        out.append(person(50, ((44, 150), (60, 150)), face=1, look=6, kind='helper'))
        out.append('<rect x="20" y="118" width="86" height="64" rx="6" fill="url(#pillar)"/>')
        out.append(f'<circle cx="46" cy="184" r="13" fill="{WIRE}"/><circle cx="46" cy="184" r="5" fill="url(#steel)"/>')
        out.append(qmark(112, 80))
    elif kind == 'paper':
        out.append('<rect x="0" y="40" width="200" height="110" fill="url(#wood)" fill-opacity="0.35"/>')
        for i in range(3):
            out.append(frame(14 + i * 44, 52))
            out.append(frame(14 + i * 44, 82))
        out.append(f'<rect x="20" y="166" width="46" height="24" rx="3" fill="url(#glass)" stroke="{INK}" stroke-width="0.6"/>')
        out.append(f'<rect x="26" y="171" width="12" height="14" rx="4" fill="{GLOVE}"/><rect x="42" y="171" width="12" height="14" rx="4" fill="{GLOVE}"/>')
        out.append(person(140, ((130, 134), (150, 136)), face=-1, look=0))
    return card_close(out)


CARDS = {}
for k in ('cert', 'aware', 'new', 'strong', 'booklet', 'noreg'):
    CARDS[f'comp_{k}'] = comp_card(k)
for k in ('path', 'board', 'expnoexam', 'examnoexp', 'compid'):
    CARDS[f'permit_{k}'] = permit_scene(k)
for k in ('permit', 'withiti', 'firstaid', 'word', 'iti'):
    CARDS[f'paper_{k}'] = paper_scene(k)
for k in ('live', 'hv', 'aid', 'skip', 'old', 'knowall'):
    CARDS[f'grow_{k}'] = grow_scene(k)
for k in ('log', 'senior', 'goal', 'norec', 'shy', 'paper'):
    CARDS[f'habit_{k}'] = habit_scene(k)

# Safe cards and traps per round (mirrors learn_board_pack710.dart).
ROUNDS = {
    'comp': (['comp_cert', 'comp_aware'], ['comp_new', 'comp_strong', 'comp_booklet', 'comp_noreg']),
    'permit': (['permit_path', 'permit_board'], ['permit_expnoexam', 'permit_examnoexp', 'permit_compid']),
    'paper': (['paper_permit', 'paper_withiti'], ['paper_firstaid', 'paper_word', 'paper_iti']),
    'grow': (['grow_live', 'grow_hv', 'grow_aid'], ['grow_skip', 'grow_old', 'grow_knowall']),
    'habit': (['habit_log', 'habit_senior', 'habit_goal'], ['habit_norec', 'habit_shy', 'habit_paper']),
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
