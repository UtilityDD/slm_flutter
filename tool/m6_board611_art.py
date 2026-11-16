"""Picture cards for lesson 6.11 শেখা ("আর্থিং সিস্টেম: অদৃশ্য অভিভাবক").

python -I tool/m6_board611_art.py .

Writes assets/game/art/m6_board611/*.svg in the clean gradient style of
tool/m6_board63_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only things a worker reads (a pipe's length on a measuring
staff, the earth tester's reading) are stroke glyphs with English digits.

What the cards show comes from lesson 6.11 (live text) and the Module 6
rulings (docs/module_specs/module6_rulings.md) only:
  1. role: why earthing matters (section 1, pro tip 1) — a feeder pillar's
     metal body bonded to its earth pit; the DTR neutral led down to a pit;
     the DTR earthed from two separate pits. Traps: a new breaker box with no
     earth at all, a pole's earth wire cut while the line runs (houses lit),
     LAs on the DTR crossarm with no lead below;
  2. type: pipe and plate earthing (section 2) — a perforated GI pipe about
     3 m long driven upright (a measuring staff beside it); a copper plate
     buried deep. Traps: any rusty iron rod, the GI pipe laid flat, a short
     stub half above the ground (the staff reads 1 m);
  3. joint: the patrol look at a pole's earth joint (section 3, pro tip 2,
     section 4) — clean brass nut-bolts, a welded joint, a joint brushed,
     greased and tightened. Traps: rusty iron nuts, the earth wire only
     twisted on, the strip torn and hanging;
  4. pit: the pit and its care (sections 3 and 4) — charcoal and salt layers
     round the electrode, water by funnel on a dry day, a clean concrete
     chamber with its lid on. Traps: sand only, a broken chamber with no lid
     and rubbish inside, a cracked dry pit never watered;
  5. test: soil and the test before sign-off (pro tips 3 and 4; ruling M6-13,
     ≤ 5 ohm good) — the earth tester reads 3.2 and the sheet is signed;
     several electrodes joined in rocky soil; bentonite poured round the
     electrode in sandy soil. Traps: one untreated electrode in rocky soil,
     the sheet signed with the tester still shut in its case, the tester
     reading 18 and the sheet signed all the same.
The item spec's sixth round (the substation: touch and step potential,
gravel and earth mat) left the board: boards are 5 rounds (owner after Wave A).

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too. It
deletes only its own stale cards.
"""

import itertools
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m6_board611_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_board611')
W, H = 200, 220
GY = 190          # ground line on the open-air cards (role, joint)
SY = 72           # surface line on the cut-away cards (type, pit, test)

WIRE = '#2B3138'
INK = '#4A5560'
PAPER = '#F4F1E6'
BAG = '#6B5B3E'
BRASS = '#C9A43A'
EARTH_Y = '#E8C830'    # earth lead (yellow-green)
GREEN = '#3E9B4F'
RUST = '#9A4A22'
RUST_D = '#6E3416'
WELD = '#5E5A55'
GREASE = '#D9A441'
BRISTLE = '#3A2E22'
CONC = '#9A9C98'       # concrete chamber
CONC_D = '#6F716D'
LID = '#B7B9B4'        # chamber lid
HOLE = '#3B2C1E'       # pipe perforations, soil cracks
CHAR = '#2A2622'       # charcoal layer
SALT = '#EDEDE6'       # salt layer
SAND = '#D8C08A'
ROCK = '#8A8579'
ROCK_D = '#6A665C'
BENTO = '#A7A9A0'      # bentonite (grey clay)
WATER = '#4F8FC0'
FUNNEL = '#3F7A5C'
TRASH_A = '#C8352B'
TRASH_B = '#4B6BB0'
METER_Y = '#F2B630'
METER_D = '#B9851A'
LCD_ON = '#1D2B22'
SUN = '#FFE08A'
WIN_LIT = '#FFE08A'
GRASS = '#5E8A3A'
LINE = '#3A4048'

DEFS = """<defs>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="soil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8DBBDD"/><stop offset="0.327" stop-color="#CFE2EC"/><stop offset="0.327" stop-color="#8A6A48"/><stop offset="1" stop-color="#5E4630"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="chan" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A3ABB2"/><stop offset="1" stop-color="#6C747B"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A78"/><stop offset="0.5" stop-color="#9DB5A5"/><stop offset="1" stop-color="#5E7766"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="ceramic" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9D3C6"/><stop offset="0.45" stop-color="#FAF8F2"/><stop offset="1" stop-color="#C8C1B2"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="gi" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8C949A"/><stop offset="0.5" stop-color="#D2D8DC"/><stop offset="1" stop-color="#7A8288"/></linearGradient>
  <linearGradient id="gih" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8C949A"/><stop offset="0.5" stop-color="#D2D8DC"/><stop offset="1" stop-color="#7A8288"/></linearGradient>
  <linearGradient id="cu" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E0A060"/><stop offset="0.5" stop-color="#C47A3C"/><stop offset="1" stop-color="#8E5226"/></linearGradient>
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
# Glyphs: English digits as seven-segment strokes, plus m and '.'.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'm': 'M0 10 L0 4.6 M0 6 Q0 4.6 1.5 4.6 Q3 4.6 3 6 L3 10 M3 6 Q3 4.6 4.5 4.6 Q6 4.6 6 6 L6 10',
}


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


def glyphs(x, y, text, h=10.0, color=INK):
    """[text] drawn with strokes; (x, y) = top left; h = cap height."""
    k = h / 10
    d = []
    dots = []
    ox = x
    for ch in text:
        if ch == ' ':
            ox += 4.5 * k
        elif ch == '.':
            dots.append(f'<circle cx="{f(ox + 0.6 * k)}" cy="{f(y + 10 * k)}" r="{f(1.1 * k)}" fill="{color}"/>')
            ox += 3.6 * k
        elif ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox
            for s in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[s]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
        else:
            d.append(_shift(_LET[ch], ox, y, k))
            ox += 7.8 * k
    return (f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" '
            f'stroke-linejoin="round" fill="none"/>' + ''.join(dots))


def glyph_width(text, h=10.0):
    k = h / 10
    wd = 0.0
    for ch in text:
        wd += 4.5 * k if ch == ' ' else 3.6 * k if ch == '.' else 5.4 * k if ch == '1' else 7.8 * k
    return wd - 1.8 * k


# --------------------------------------------------------------------------
# Shared things.
# --------------------------------------------------------------------------

def ground():
    return (f'<rect x="0" y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>'
            f'<path d="M0 {GY} H{W}" stroke="{GRASS}" stroke-width="2"/>')


def surface():
    """The grass edge of a cut-away card."""
    tufts = ''.join(f'M{x} {SY} l2 -5 l2 5' for x in range(6, 200, 22))
    return f'<path d="M0 {SY} H{W}" stroke="{GRASS}" stroke-width="3"/><path d="{tufts}" stroke="{GRASS}" stroke-width="1.4" fill="none"/>'


def sun(x=168, y=30):
    return (f'<circle cx="{x}" cy="{y}" r="20" fill="url(#glow)"/>'
            f'<circle cx="{x}" cy="{y}" r="8" fill="{SUN}"/>')


def cloud(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.75"><ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(16 * s)}" ry="{f(6 * s)}"/>'
            f'<ellipse cx="{f(x + 8 * s)}" cy="{f(y - 4 * s)}" rx="{f(9 * s)}" ry="{f(6 * s)}"/></g>')


def pole(x, top, bottom=GY, wdt=8):
    return f'<rect x="{f(x - wdt / 2)}" y="{f(top)}" width="{f(wdt)}" height="{f(bottom - top)}" fill="url(#pole)"/>'


def chamber(x, y=GY, w=24, lid=True):
    """An earth pit's concrete chamber seen from the side, rim at ground [y]."""
    o = [f'<rect x="{f(x - w / 2)}" y="{f(y - 3)}" width="{f(w)}" height="9" rx="1.5" fill="{CONC}"/>',
         f'<path d="M{f(x - w / 2)} {f(y + 6)} H{f(x + w / 2)}" stroke="{CONC_D}" stroke-width="1.4"/>']
    if lid:
        o.append(f'<rect x="{f(x - w / 2 - 1)}" y="{f(y - 6)}" width="{f(w + 2)}" height="4" rx="1.5" fill="{LID}"/>')
    return ''.join(o)


def lead(d, w=2.2):
    """The earth lead: yellow-green."""
    return (f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="{w}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="{d}" stroke="{GREEN}" stroke-width="{f(w * 0.45)}" fill="none" stroke-dasharray="3 5" stroke-linecap="round"/>')


def nut(x, y, c=BRASS, r=3.2):
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{c}" stroke="{WIRE}" stroke-width="0.6"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r * 0.35)}" fill="{WIRE}"/>')


def lines(y1=26, y2=34):
    return (f'<path d="M0 {y1} Q100 {y1 + 6} 200 {y1}" stroke="{LINE}" stroke-width="1.2" fill="none"/>'
            f'<path d="M0 {y2} Q100 {y2 + 6} 200 {y2}" stroke="{LINE}" stroke-width="1.2" fill="none"/>')


def dtr(x, y):
    """A pole DTR (tank, fins, HT and LT bushings) centred at x, top at y."""
    o = [f'<rect x="{f(x - 28)}" y="{f(y + 10)}" width="56" height="42" rx="4" fill="url(#tank)"/>',
         ''.join(f'<path d="M{f(x - 22 + i * 9)} {f(y + 16)} V{f(y + 46)}" stroke="#5E7766" stroke-width="1.6"/>' for i in range(6)),
         f'<rect x="{f(x - 30)}" y="{f(y + 6)}" width="60" height="6" rx="2" fill="url(#chan)"/>']
    for i in range(3):
        o.append(f'<rect x="{f(x - 18 + i * 14)}" y="{f(y - 8)}" width="6" height="14" rx="2" fill="url(#ceramic)"/>')
    for i in range(4):
        o.append(f'<rect x="{f(x - 22 + i * 13)}" y="{f(y + 52)}" width="5" height="9" rx="1.5" fill="url(#ceramic)"/>')
    return ''.join(o)


def crossarm(x, y, w=70):
    return f'<rect x="{f(x - w / 2)}" y="{f(y)}" width="{w}" height="5" rx="1" fill="url(#chan)"/>'


def house(x, y, lit=True):
    win = WIN_LIT if lit else '#2E3A46'
    return (f'<rect x="{f(x)}" y="{f(y)}" width="34" height="26" fill="url(#house)"/>'
            f'<path d="M{f(x - 4)} {f(y)} L{f(x + 17)} {f(y - 14)} L{f(x + 38)} {f(y)} Z" fill="url(#roof)"/>'
            f'<rect x="{f(x + 6)}" y="{f(y + 8)}" width="9" height="8" fill="{win}"/>'
            f'<rect x="{f(x + 20)}" y="{f(y + 10)}" width="8" height="16" fill="{BAG}"/>')


# --------------------------------------------------------------------------
# Round 1 — role.
# --------------------------------------------------------------------------

def role_card(kind):
    out = card_open('day')
    out.append(cloud(40, 24))
    out.append(ground())
    if kind == 'body':
        # A feeder pillar: its metal body bonded by a strip to its earth pit.
        out.append(f'<rect x="48" y="96" width="84" height="{GY - 96}" rx="4" fill="url(#box)"/>')
        out.append(f'<path d="M90 102 V{GY - 6} M54 104 H126" stroke="{INK}" stroke-width="1.2"/>')
        out.append(f'<rect x="80" y="140" width="4" height="12" rx="1" fill="{INK}"/><rect x="96" y="140" width="4" height="12" rx="1" fill="{INK}"/>')
        out.append(f'<rect x="40" y="{GY - 2}" width="100" height="6" fill="{CONC}"/>')
        out.append(lead(f'M132 170 L150 170 L158 {GY - 6}'))
        out.append(nut(132, 170))
        out.append(chamber(160))
        out.append(f'<path d="M90 {GY + 10} V{GY + 20}" stroke="{WIRE}" stroke-width="4"/>')
    elif kind in ('neutral', 'double', 'la'):
        out.append(lines())
        out.append(pole(100, 18))
        out.append(crossarm(100, 30))
        out.append(dtr(100, 76))
        if kind == 'neutral':
            # The neutral (fourth LT bushing) led down the pole to its own pit.
            out.append(lead(f'M{100 - 22 + 39 + 2.5} 137 L{100 - 22 + 39 + 2.5} 146 L104 152 L104 {GY - 8} L132 {GY - 6}'))
            out.append(nut(104, 152))
            out.append(chamber(136))
        elif kind == 'double':
            # The tank earthed from two separate pits, one each side.
            out.append(lead(f'M72 118 L52 124 L36 {GY - 6}'))
            out.append(lead(f'M128 118 L148 124 L164 {GY - 6}'))
            out.append(nut(72, 118))
            out.append(nut(128, 118))
            out.append(chamber(34))
            out.append(chamber(166))
        else:
            # LAs on the crossarm, their bottom terminals with nothing below.
            for i in range(3):
                x = 74 + i * 26
                out.append(f'<rect x="{x - 4}" y="40" width="8" height="18" rx="2" fill="url(#porc)"/>')
                out.append(f'<path d="M{x} 58 v4" stroke="{WIRE}" stroke-width="1.6"/>')
                out.append(f'<path d="M{x} 30 L{x} 22" stroke="{LINE}" stroke-width="1.2"/>')
    elif kind == 'unearthed':
        # A brand-new breaker box on its plinth, the cable in, no earth at all.
        out.append(f'<rect x="56" y="{GY - 12}" width="88" height="14" fill="{CONC}"/>')
        out.append(f'<rect x="62" y="104" width="76" height="{GY - 116}" rx="4" fill="url(#box)"/>')
        out.append(f'<rect x="78" y="118" width="44" height="26" rx="2" fill="{INK}"/>')
        out.append(f'<rect x="96" y="124" width="8" height="14" rx="1" fill="{WIRE}"/>')
        out.append(f'<path d="M100 {GY - 12} V{GY + 30}" stroke="{WIRE}" stroke-width="5"/>')
        out.append(nut(100, GY - 14, BRASS, 3.6))
    elif kind == 'cut':
        # The line runs (the house is lit) but the pole's earth wire is cut.
        out.append(lines())
        out.append(pole(84, 18))
        out.append(crossarm(84, 30))
        for x in (58, 84, 110):
            out.append(f'<rect x="{x - 3}" y="22" width="6" height="9" rx="2" fill="url(#porc)"/>')
        out.append(house(134, 160))
        out.append(lead('M88 36 L88 108 Q93 114 97 109'))
        out.append(lead(f'M88 150 Q83 144 79 149 M88 150 L88 {GY - 8} L104 {GY - 6}'))
        out.append(nut(88, 40))
        out.append(chamber(108))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — electrode type (cut-away soil).
# --------------------------------------------------------------------------

def gi_pipe(x, top, bottom, w=9, holes=True):
    o = [f'<rect x="{f(x - w / 2)}" y="{f(top)}" width="{w}" height="{f(bottom - top)}" rx="1.5" fill="url(#gi)"/>']
    if holes:
        y = top + 14
        while y < bottom - 6:
            if y > SY + 4:
                o.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="1.4" fill="{HOLE}"/>')
            y += 12
    return ''.join(o)


def cu_lead(d):
    return f'<path d="{d}" stroke="url(#cu)" stroke-width="2.6" fill="none" stroke-linecap="round"/>'


def staff(x, top, bottom, label):
    o = [f'<path d="M{x} {f(top)} V{f(bottom)}" stroke="{INK}" stroke-width="1.2"/>',
         f'<path d="M{x - 4} {f(top)} h8 M{x - 4} {f(bottom)} h8" stroke="{INK}" stroke-width="1.2"/>']
    mid = (top + bottom) / 2
    o.append(f'<rect x="{x + 3}" y="{f(mid - 8)}" width="{f(glyph_width(label, 10) + 6)}" height="16" rx="2" fill="{PAPER}"/>')
    o.append(glyphs(x + 6, mid - 5, label, 10))
    return ''.join(o)


def type_card(kind):
    out = card_open('soil')
    out.append(cloud(40, 26))
    out.append(surface())
    if kind == 'pipe':
        # A perforated GI pipe, about 3 m, driven straight down.
        out.append(gi_pipe(80, SY - 8, 204))
        out.append(cu_lead(f'M80 {SY - 6} L40 {SY - 6} L30 {SY - 20}'))
        out.append(nut(80, SY - 6))
        out.append(staff(118, SY - 8, 204, '3 m'))
    elif kind == 'plate':
        # A copper plate set deep in the ground, its lead up to the surface.
        out.append(f'<rect x="70" y="146" width="54" height="54" rx="2" fill="url(#cu)"/>')
        out.append(gi_pipe(97, SY - 8, 146, 5, holes=False))
        out.append(cu_lead(f'M97 {SY - 6} L56 {SY - 6} L46 {SY - 20}'))
        out.append(nut(97, 146))
        out.append(nut(97, SY - 6))
    elif kind == 'rod':
        # Any rusty iron rod knocked in.
        out.append(f'<path d="M84 {SY - 10} L86 120 L82 150" stroke="{RUST}" stroke-width="4" fill="none" stroke-linecap="round"/>')
        out.append(f'<path d="M85 90 l3 2 M86 112 l-3 2 M84 136 l3 2" stroke="{RUST_D}" stroke-width="1.4"/>')
        out.append(cu_lead(f'M84 {SY - 8} L44 {SY - 8} L34 {SY - 22}'))
        out.append(nut(84, SY - 8, RUST))
    elif kind == 'flat':
        # The GI pipe laid flat in a shallow trench.
        out.append(f'<rect x="40" y="96" width="120" height="9" rx="1.5" fill="url(#gih)"/>')
        out.append(''.join(f'<circle cx="{x}" cy="100.5" r="1.4" fill="{HOLE}"/>' for x in range(52, 160, 12)))
        out.append(cu_lead(f'M44 100 L36 {SY - 6} L28 {SY - 20}'))
        out.append(nut(44, 100))
        out.append(f'<path d="M30 {SY} L36 92 M170 {SY} L164 92" stroke="{HOLE}" stroke-width="1" stroke-dasharray="3 3"/>')
    elif kind == 'stub':
        # A short stub, half of it above the ground.
        out.append(gi_pipe(80, SY - 30, SY + 30))
        out.append(cu_lead(f'M80 {SY - 28} L44 {SY - 28} L34 {SY - 40}'))
        out.append(nut(80, SY - 28))
        out.append(staff(118, SY - 30, SY + 30, '1 m'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — the earth joint on a pole (close-up).
# --------------------------------------------------------------------------

def weld_bead(y):
    """A solid weld bead fusing the strip end to the clamp, across at [y]."""
    return (f'<rect x="117" y="{f(y - 2.6)}" width="16" height="5.2" rx="2.6" fill="{WELD}"/>'
            f'<path d="M119 {f(y - 0.8)} H131" stroke="{INK}" stroke-width="0.7"/>')


def joint_card(kind):
    """A close-up of the earth joint clamped to the pole: the joint is drawn
    in its own small coordinates and enlarged round the card's middle."""
    out = card_open('day')
    out.append(cloud(160, 26))
    out.append(ground())
    out.append(pole(77, -4, H + 4, 74))
    j = []      # the joint, enlarged
    strip = f'M125 126 L125 170'
    # The earth wire comes down the pole to the joint; the GI strip goes on
    # down to the pit below the card.
    j.append(lead('M124 40 L124 96', 2.4))
    if kind in ('brass', 'grease'):
        j.append(f'<rect x="118" y="96" width="14" height="30" rx="2" fill="url(#gi)"/>')
        j.append(nut(125, 104))
        j.append(nut(125, 118))
        j.append(f'<path d="{strip}" stroke="url(#gi)" stroke-width="6" fill="none"/>')
        if kind == 'grease':
            j.append(f'<path d="M120 100 Q125 96 130 100 M120 114 Q125 110 130 114" stroke="{GREASE}" stroke-width="1.6" fill="none"/>')
            j.append(f'<path d="M129 102 l2 -1.5 M129 116 l2 -1.5" stroke="#FFFFFF" stroke-width="0.8"/>')
            out.append(f'<path d="M160 176 l28 -22" stroke="{BAG}" stroke-width="5" stroke-linecap="round"/>')
            out.append(f'<path d="M148 182 l12 -10 M150 186 l12 -10 M152 190 l12 -10" stroke="{BRISTLE}" stroke-width="2"/>')
    elif kind == 'weld':
        j.append(f'<rect x="118" y="96" width="14" height="30" rx="2" fill="url(#gi)"/>')
        # The strip end runs into the clamp and is fused there: two solid
        # beads along the seam, no nut needed.
        j.append(f'<path d="M125 108 L125 170" stroke="url(#gi)" stroke-width="6" fill="none"/>')
        j.append(weld_bead(110))
        j.append(weld_bead(122))
    elif kind == 'iron':
        j.append(f'<rect x="118" y="96" width="14" height="30" rx="2" fill="url(#gi)"/>')
        j.append(nut(125, 104, RUST))
        j.append(nut(125, 118, RUST))
        j.append(f'<path d="M123 107 l-1 8 M127 121 l1 7" stroke="{RUST_D}" stroke-width="1.4"/>')
        j.append(f'<path d="{strip}" stroke="url(#gi)" stroke-width="6" fill="none"/>')
    elif kind == 'twist':
        # The wire only wound round the strip end, loose; the brush and the
        # grease tin lie unused on the ground.
        j.append(f'<path d="M125 108 L125 170" stroke="url(#gi)" stroke-width="6" fill="none"/>')
        j.append(f'<path d="M124 96 Q119 100 124 104 Q131 108 124 112 Q118 116 126 120 Q134 124 131 132" '
                 f'stroke="{EARTH_Y}" stroke-width="2" fill="none"/>')
        out.append(f'<rect x="146" y="{GY - 6}" width="18" height="13" rx="2" fill="{GREASE}"/>')
        out.append(f'<path d="M172 {GY + 6} l22 -4" stroke="{BAG}" stroke-width="4" stroke-linecap="round"/>')
        out.append(f'<path d="M167 {GY + 1} l-2 9 M170 {GY + 1} l-2 9" stroke="{BRISTLE}" stroke-width="1.6"/>')
    elif kind == 'torn':
        # The joint is bolted and welded, but the strip below it is torn
        # through and its end hangs loose.
        j.append(f'<rect x="118" y="96" width="14" height="30" rx="2" fill="url(#gi)"/>')
        j.append(nut(125, 104))
        j.append(weld_bead(118))
        j.append(f'<path d="M125 126 L125 136 l-3 3 l4 2 l-2 3" stroke="url(#gi)" stroke-width="6" fill="none"/>')
        j.append(f'<path d="M134 172 L132 158 l3 -3 l-4 -2" stroke="url(#gi)" stroke-width="6" fill="none"/>')
    out.append('<g transform="translate(125 100) scale(2.2) translate(-125 -111)">' + ''.join(j) + '</g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — the pit (cut-away).
# --------------------------------------------------------------------------

PX = 100        # the pit's electrode


def pit_base(fill='layers', lid=True, lid_off=False):
    o = []
    if fill == 'layers':
        for i, y in enumerate(range(SY + 10, 214, 14)):
            o.append(f'<rect x="{PX - 26}" y="{y}" width="52" height="14" fill="{CHAR if i % 2 == 0 else SALT}"/>')
    else:
        o.append(f'<rect x="{PX - 26}" y="{SY + 10}" width="52" height="{214 - SY - 10}" fill="{SAND}"/>')
        o.append(''.join(f'<circle cx="{PX - 18 + (i * 13) % 36}" cy="{SY + 20 + i * 11}" r="1" fill="{BAG}"/>' for i in range(11)))
    o.append(gi_pipe(PX, SY + 2, 214))
    # The chamber walls round the pipe head.
    o.append(f'<rect x="{PX - 22}" y="{SY - 6}" width="6" height="18" fill="{CONC}"/>')
    o.append(f'<rect x="{PX + 16}" y="{SY - 6}" width="6" height="18" fill="{CONC}"/>')
    o.append(f'<path d="M{PX - 22} {SY + 12} h6 M{PX + 16} {SY + 12} h6" stroke="{CONC_D}" stroke-width="1.4"/>')
    o.append(cu_lead(f'M{PX} {SY + 4} L{PX + 12} {SY + 4} L{PX + 12} {SY - 4}'))
    o.append(nut(PX, SY + 4))
    if lid:
        if lid_off:
            o.append(f'<rect x="{PX + 34}" y="{SY - 5}" width="38" height="5" rx="1.5" fill="{LID}"/>')
        else:
            o.append(f'<rect x="{PX - 24}" y="{SY - 10}" width="48" height="5" rx="1.5" fill="{LID}"/>')
    return o


def pit_card(kind):
    out = card_open('soil')
    out.append(surface())
    if kind == 'salt':
        # Building the pit: the lid aside, the layers of charcoal and salt
        # round the electrode in full view, a heap of each still at the edge.
        out.append(cloud(44, 30))
        out += pit_base(lid_off=True)
        out.append(f'<path d="M12 {SY} Q24 {SY - 16} 38 {SY} Z" fill="{CHAR}"/>')
        out.append(f'<path d="M36 {SY} Q50 {SY - 14} 62 {SY} Z" fill="{SALT}"/>')
        out.append(''.join(f'<path d="M{PX - 30} {y + 7} h-6" stroke="{WIRE}" stroke-width="1.2"/>' for y in range(SY + 10, 214, 14)))
    elif kind == 'lid':
        # Close up on the finished pit: a clean concrete apron flush with the
        # grass, the chamber whole, its lid seated with a lifting ring; the
        # layers only start at the card's foot.
        out.append(cloud(44, 30))
        out.append(f'<rect x="{PX - 70}" y="{SY - 2}" width="140" height="5" rx="1.5" fill="{CONC}"/>')
        out.append(f'<g transform="translate({PX} {SY}) scale(1.8) translate({-PX} {-SY})">' + ''.join(pit_base()) +
                   f'<path d="M{PX - 4} {SY - 10} q4 -4 8 0" stroke="{CONC_D}" stroke-width="1.2" fill="none"/></g>')
    elif kind == 'water':
        # A dry, sunny day: the lid set aside, water poured in by funnel.
        out.append(sun())
        out += pit_base(lid_off=True)
        out.append(f'<path d="M{PX - 12} {SY - 30} L{PX + 12} {SY - 30} L{PX + 3} {SY - 14} L{PX + 3} {SY - 4} L{PX - 3} {SY - 4} '
                   f'L{PX - 3} {SY - 14} Z" fill="{FUNNEL}"/>')
        out.append(f'<path d="M{PX - 34} {SY - 50} Q{PX - 14} {SY - 46} {PX - 4} {SY - 30}" stroke="{WATER}" stroke-width="4" fill="none" stroke-linecap="round"/>')
        out.append(''.join(f'<path d="M{PX - 20 + i * 10} {SY + 16 + i * 30} q2 4 0 6" stroke="{WATER}" stroke-width="1.6" fill="none"/>' for i in range(4)))
    elif kind == 'sand':
        out.append(cloud(44, 30))
        out += pit_base(fill='sand')
    elif kind == 'broken':
        # The chamber cracked, the lid broken, rubbish and dirty water inside.
        out.append(cloud(44, 30))
        out += pit_base(lid=False)
        out.append(f'<path d="M{PX - 19} {SY - 6} l-3 8 l4 4 M{PX + 19} {SY - 4} l3 6 l-4 5" stroke="{HOLE}" stroke-width="1.4" fill="none"/>')
        out.append(f'<path d="M{PX + 30} {SY - 2} l12 -5 l8 4 Z M{PX + 54} {SY - 1} l10 -3 l4 3 Z" fill="{LID}"/>')
        out.append(f'<rect x="{PX - 14}" y="{SY - 2}" width="28" height="6" rx="2" fill="{WATER}" opacity="0.7"/>')
        out.append(f'<path d="M{PX - 12} {SY - 6} l8 -4 l3 5 Z" fill="{TRASH_A}"/>')
        out.append(f'<rect x="{PX + 4}" y="{SY - 9}" width="9" height="6" rx="1" fill="{TRASH_B}" transform="rotate(-18 {PX + 8} {SY - 6})"/>')
        out.append(f'<rect x="{PX - 4}" y="{SY - 12}" width="8" height="5" fill="{PAPER}"/>')
    elif kind == 'dry':
        # A hot dry spell: the soil cracked, the funnel lying dry beside.
        out.append(sun())
        out += pit_base()
        out.append(''.join(f'<path d="M{x} {SY} l3 10 l-4 8 l5 12" stroke="{HOLE}" stroke-width="1.4" fill="none"/>' for x in (20, 46, 150, 178)))
        out.append(f'<path d="M140 {SY - 2} L160 {SY - 10} L162 {SY - 4} L146 {SY + 1} Z" fill="{FUNNEL}"/>')
        out.append(f'<path d="M24 {SY - 1} l4 -8 M30 {SY - 1} l1 -9" stroke="{SAND}" stroke-width="1.4"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — soil and the test before sign-off (cut-away).
# --------------------------------------------------------------------------

def earth_tester(x, y, reading=None):
    """The earth tester: yellow case; its reading on the LCD, or the lid shut."""
    if reading is None:
        return (f'<rect x="{x}" y="{y}" width="40" height="26" rx="4" fill="{METER_D}"/>'
                f'<rect x="{x + 3}" y="{y + 3}" width="34" height="8" rx="2" fill="{METER_Y}"/>'
                f'<rect x="{x + 16}" y="{y - 4}" width="8" height="5" rx="2" fill="{WIRE}"/>')
    tw = glyph_width(reading, 10)
    return (f'<rect x="{x}" y="{y}" width="40" height="30" rx="4" fill="{METER_Y}" stroke="{METER_D}" stroke-width="1"/>'
            f'<rect x="{x + 4}" y="{y + 4}" width="32" height="15" rx="1.5" fill="url(#lcd)"/>'
            + glyphs(x + (40 - tw) / 2, y + 6.5, reading, 10, LCD_ON)
            + f'<circle cx="{x + 20}" cy="{y + 24}" r="3" fill="{WIRE}"/>')


def sheet(x, y, signed=True):
    o = [f'<rect x="{x}" y="{y}" width="26" height="32" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>',
         f'<path d="M{x + 4} {y + 7} h18 M{x + 4} {y + 12} h18 M{x + 4} {y + 17} h12" stroke="{INK}" stroke-width="0.8"/>']
    if signed:
        o.append(f'<path d="M{x + 4} {y + 26} q4 -6 6 0 q3 5 6 -2 q2 -3 6 1" stroke="{INK}" stroke-width="1.2" fill="none"/>')
    return ''.join(o)


def sack(x=8, y=SY - 22, open_=False):
    o = [f'<path d="M{x} {y + 22} L{x + 2} {y + 2} Q{x + 11} {y - 2} {x + 20} {y + 2} L{x + 22} {y + 22} Z" fill="{BAG}"/>',
         f'<rect x="{x + 5}" y="{y + 9}" width="12" height="7" rx="1" fill="{BENTO}"/>']
    if open_:
        o.append(f'<path d="M{x + 20} {y + 4} Q{x + 40} {y + 4} {x + 52} {y + 18}" stroke="{BENTO}" stroke-width="5" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def rocks():
    pts = [(24, 100), (56, 128), (150, 104), (172, 150), (40, 170), (130, 186), (70, 198), (160, 206), (28, 140)]
    return ''.join(f'<ellipse cx="{x}" cy="{y}" rx="11" ry="7" fill="{ROCK}" stroke="{ROCK_D}" stroke-width="1"/>' for x, y in pts)


def sand_band():
    return (f'<rect x="0" y="{SY + 2}" width="{W}" height="{H - SY - 2}" fill="{SAND}" opacity="0.85"/>'
            + ''.join(f'<circle cx="{(i * 37) % 196 + 4}" cy="{SY + 10 + (i * 23) % 130}" r="1" fill="{BAG}"/>' for i in range(18)))


def test_card(kind):
    out = card_open('soil')
    out.append(cloud(70, 24))
    out.append(surface())
    if kind in ('multi', 'one'):
        out.append(rocks())
    if kind in ('bento', 'high'):
        out.append(sand_band())
    if kind == 'bento':
        out.append(f'<path d="M86 {SY + 2} H114 L110 200 H90 Z" fill="{BENTO}"/>')
    if kind == 'multi':
        # Three electrodes in rocky ground, joined by a strip at the top.
        for x in (60, 100, 140):
            out.append(gi_pipe(x, SY - 6, 196, 8))
            out.append(nut(x, SY - 2))
        out.append(cu_lead(f'M60 {SY - 2} H140'))
        out.append(cu_lead(f'M140 {SY - 2} L170 {SY - 2} L178 {SY - 20}'))
    else:
        out.append(gi_pipe(100, SY - 6, 196))
        out.append(nut(100, SY - 2))
        out.append(cu_lead(f'M100 {SY - 2} L140 {SY - 2} L148 {SY - 18}'))
    out.append(sack(open_=(kind == 'bento')))
    if kind in ('ok', 'high'):
        # The tester's leads: to the electrode and to the two test spikes.
        out.append(f'<path d="M110 {SY - 26} Q104 {SY - 14} 100 {SY - 4} M130 {SY - 26} Q150 {SY - 12} 176 {SY - 2}" '
                   f'stroke="{WIRE}" stroke-width="1.2" fill="none"/>')
        out.append(f'<path d="M176 {SY - 4} V{SY + 12}" stroke="{WIRE}" stroke-width="2"/>')
        out.append(earth_tester(100, SY - 52, '3.2' if kind == 'ok' else '18'))
        out.append(sheet(150, SY - 56))
    elif kind == 'skip':
        out.append(earth_tester(108, SY - 26))
        out.append(sheet(152, SY - 52))
        out.append(f'<path d="M184 {SY - 46} l-12 18" stroke="{INK}" stroke-width="2.4" stroke-linecap="round"/>')
    return card_close(out)


CARDS = {}
for k in ('body', 'neutral', 'double', 'unearthed', 'cut', 'la'):
    CARDS[f'role_{k}'] = role_card(k)
for k in ('pipe', 'plate', 'rod', 'flat', 'stub'):
    CARDS[f'type_{k}'] = type_card(k)
for k in ('brass', 'weld', 'grease', 'iron', 'twist', 'torn'):
    CARDS[f'joint_{k}'] = joint_card(k)
for k in ('salt', 'water', 'lid', 'sand', 'broken', 'dry'):
    CARDS[f'pit_{k}'] = pit_card(k)
for k in ('ok', 'multi', 'bento', 'one', 'skip', 'high'):
    CARDS[f'test_{k}'] = test_card(k)

# Safe cards and traps per round (mirrors learn_board_pack611.dart).
ROUNDS = {
    'role': (['role_body', 'role_neutral', 'role_double'], ['role_unearthed', 'role_cut', 'role_la']),
    'type': (['type_pipe', 'type_plate'], ['type_rod', 'type_flat', 'type_stub']),
    'joint': (['joint_brass', 'joint_weld', 'joint_grease'], ['joint_iron', 'joint_twist', 'joint_torn']),
    'pit': (['pit_salt', 'pit_water', 'pit_lid'], ['pit_sand', 'pit_broken', 'pit_dry']),
    'test': (['test_ok', 'test_multi', 'test_bento'], ['test_one', 'test_skip', 'test_high']),
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
