"""Picture cards for lesson 8.4 ("গ্রিড কোড (Grid Code): সিস্টেম শৃঙ্খলার নিয়ম").

python -I tool/m8_board84_art.py .

Writes assets/game/art/m8_board84/*.svg (200 x 220 scene cards, drawn edge to
edge, the same gradient style as tool/m6_board63_art.py). No words in the art:
the readings a worker reads (a meter's Hz, a bus voltmeter's kV, an OLTC tap
number) are drawn as stroke glyphs with English digits.

What the cards show comes from the live lesson 8.4 text and the Module 8
rulings (docs/module_specs/module8_rulings.md: M8-4, M8-12, X3) only:
  1. freq: the wall frequency meter; the target band 49.90-50.05 Hz; 49.0 is
     the alarm. Safe: 50.00, 49.95, 50.03 Hz. Traps: 49.70, 50.20, 48.90 Hz;
  2. hotline: an SLDC order on the hotline. Safe: the red hotline lifted while
     the black phone waits; the hotline at the ear and the 11 kV feeder put
     OFF at once; the feeder lamp OFF with the hotline still in hand. Traps:
     the black phone chatted on while the hotline rings; arguing into the
     hotline with the feeder ON; finishing tea with the order slip on the desk
     and the feeder ON;
  3. register: rotational load shedding. Safe: the register where a different
     area is dark each day; the area map where today's dark area stayed lit
     on earlier days. Traps: the same area dark three days running; one
     village dark again while the rest were never cut; the register with no
     feeder cut though the slip is pinned and the frequency is falling;
  4. bus: the 11 kV and 33 kV bus voltmeters against the band (+6 % / -9 %,
     ruling M8-12 and the live lesson). Safe: 11.0 and 11.3 kV (OLTC tap
     indicator beside it), 32.0 kV. Traps: 12.1 kV with a lightning arrester
     on the structure, 9.9 kV at a village pump, 36.5 kV;
  5. drawal: the drawal gauge (the 'ভাগ' line and the 'টানা' bar, words not
     drawn) and a low 11 kV voltmeter with the capacitor bank. Safe: the bar at
     or under the line at 49.85 Hz; the capacitor breaker switched ON. Traps:
     the bar well above the line at 49.80 Hz; the capacitor OFF with a pump
     smoking; an operator shouting at a consumer at the gate.

Fairness (the playbook, section 4): every card in a round shares one backdrop
and draws the same colour set (its furniture); only the readings, needle,
lever and figure positions differ. The script checks every hand the dealer can
make (one safe card + any three traps): each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a trap's
backdrop too. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board84_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board84')
W, H = 200, 220

INK = '#4A5560'
PAPER = '#F4F1E6'
RED = '#D8402F'
GREEN = '#3E9B4F'
METER_Y = '#F2B630'
METER_D = '#B9851A'
SKIN = '#A86E48'
SHIRT = '#1F5F8F'
PHONE = '#1C1F24'
DESK = '#6B5B3E'
BRASS = '#C9A43A'
SMOKE = '#7A848C'

DEFS = """<defs>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="1" stop-color="#9FB3C0"/></linearGradient>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#EFE3CC"/><stop offset="1" stop-color="#D2BE9C"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E9EDEF"/><stop offset="1" stop-color="#C5CED4"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="0.62" stop-color="#E2E6DE"/><stop offset="1" stop-color="#B9B39E"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#7D8891"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3A22"/><stop offset="0.45" stop-color="#A65E3A"/><stop offset="1" stop-color="#5E301C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

# Glyphs: strokes on a 6 x 10 grid (the Module 6 board's digit style).
_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}
_LET = {
    'k': 'M0 0 L0 10 M5 4.5 L0.6 8 M2.4 6.6 L5.6 10',
    'V': 'M0 0 L3 10 L6 0',
    'H': 'M0 0 L0 10 M6 0 L6 10 M0 5 L6 5',
    'z': 'M0 0 L6 0 L0 10 L6 10',
}


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def _shift(d, ox, oy, k):
    parts = re.split(r'([MLQ])', d)
    out = []
    for part in parts:
        if part in ('M', 'L', 'Q') or not part.strip():
            out.append(part)
            continue
        vals = [float(v) for v in part.split()]
        pts = [f'{f(ox + vals[i] * k)} {f(oy + vals[i + 1] * k)}' for i in range(0, len(vals), 2)]
        out.append(' '.join(pts) + ' ')
    return ''.join(out).strip()


def glyph_width(text, h=10.0):
    k = h / 10
    wd = 0.0
    for ch in text:
        if ch == ' ':
            wd += 4.5 * k
        elif ch == '.':
            wd += 3.6 * k
        elif ch == '1':
            wd += 5.4 * k
        elif ch in _DIG:
            wd += 7.8 * k
        else:
            wd += 7.8 * k
    return wd - 1.8 * k


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


def rect(x, y, w, h, fill, rx=0, stroke=None, sw=1.0):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(rx)}" fill="{fill}"{s}/>'


def circle(cx, cy, r, fill='none', stroke=None, sw=1.0):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    return f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}"{s}/>'


def path(d, stroke, sw=1.5):
    return f'<path d="{d}" stroke="{stroke}" stroke-width="{f(sw)}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'


def line(x1, y1, x2, y2, stroke, sw=1.5):
    return path(f'M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}', stroke, sw)


def card(back, body):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']
    out.extend(body)
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def person(hx, hy, body_top=None):
    """A worker: head and shirt (the same figure on every card of a round)."""
    bt = hy + 18 if body_top is None else body_top
    return [circle(hx, hy, 12, SKIN), rect(hx - 20, bt, 40, 64, SHIRT, rx=12)]


# --------------------------------------------------------------------------
# Round 1 — the wall frequency meter.
# --------------------------------------------------------------------------

def freq_card(reading):
    f_hz = float(reading)
    mx = 34 + min(max((f_hz - 48.0) / 4.0, 0.0), 1.0) * 132
    body = [
        rect(18, 30, 164, 150, 'url(#panel)', rx=12),
        rect(30, 46, 140, 64, PAPER, rx=8, stroke=INK, sw=2),
        glyphs(42, 60, reading, h=26, color=INK),
        glyphs(134, 88, 'Hz', h=12, color=INK),
        line(34, 130, 166, 130, INK, 2),
        line(34, 124, 34, 136, INK, 1.5),
        line(100, 124, 100, 136, INK, 1.5),
        line(166, 124, 166, 136, INK, 1.5),
        circle(mx, 130, 5, RED),
        circle(64, 160, 8, PAPER, stroke=GREEN, sw=2.5),
        circle(100, 160, 8, PAPER, stroke=RED, sw=2.5),
    ]
    return card('wall', body)


# --------------------------------------------------------------------------
# Round 2 — the SLDC hotline and the feeder switch.
# --------------------------------------------------------------------------

def hot_card(handset, black, lever, ring=False, hand=False, steam=False, burst=False):
    """handset: 'ear' | 'chest' | 'desk' (the red hotline); black: 'base' | 'ear'."""
    body = [rect(0, 150, 200, 70, DESK)]
    # feeder panel on the wall: both windows always drawn, the lit one filled
    body.append(rect(118, 24, 68, 74, 'url(#panel)', rx=6))
    on = lever == 'ON'
    body.append(circle(136, 46, 7, RED if on else PAPER, stroke=RED, sw=2.5))
    body.append(circle(166, 46, 7, PAPER if on else GREEN, stroke=GREEN, sw=2.5))
    ly = 64 if on else 96
    body.append(line(152, 80, 152, ly, INK, 4))
    body.extend(person(74, 80))
    if hand:
        body.append(circle(146, 84, 6, SKIN))
    hl = {'ear': (84, 62), 'chest': (56, 112), 'desk': (40, 160)}[handset]
    body.append(rect(hl[0], hl[1], 30, 9, RED, rx=4))
    if black == 'ear':
        body.append(rect(92, 56, 30, 8, PHONE, rx=4))
    body.append(rect(20, 132, 36, 16, PHONE, rx=4))
    if black == 'base':
        body.append(rect(20, 122, 36, 8, PHONE, rx=4))
    if ring:
        body.append(path('M70 150 Q76 142 70 134 M78 152 Q88 140 78 128', INK, 2))
    body.append(rect(150, 160, 36, 26, PAPER, stroke=INK, sw=1))
    body.append(line(156, 168, 180, 168, INK, 1.2))
    body.append(line(156, 175, 176, 175, INK, 1.2))
    body.append(line(156, 181, 180, 181, INK, 1.2))
    body.append(rect(124, 166, 16, 16, PAPER, rx=3, stroke=INK, sw=1))
    if steam:
        body.append(path('M130 162 Q126 156 130 150 M136 162 Q140 156 136 150', INK, 1.5))
    if burst:
        body.append(path('M58 66 L50 72 L58 78 L50 84 L58 90', INK, 2))
    return card('room', body)


# --------------------------------------------------------------------------
# Round 3 — the load-shedding register and the area map.
# --------------------------------------------------------------------------

def reg_card(dark):
    # rows are days 1-4, columns are areas 1-3; the English digits are headers
    body = [rect(8, 26, 134, 170, PAPER, rx=6, stroke=INK, sw=1.5)]
    for c in range(3):
        body.append(glyphs(26 + c * 34 + 12, 30, str(c + 1), h=7, color=INK))
    for r in range(4):
        body.append(glyphs(12, 40 + r * 34 + 9, str(r + 1), h=8, color=INK))
        for c in range(3):
            x = 26 + c * 34
            y = 40 + r * 34
            fill = INK if (r, c) in dark else PAPER
            body.append(rect(x, y, 30, 26, fill, stroke=INK, sw=1))
    # the slip pinned on the wall, the pin and a stamp: the same on every card
    body.append(rect(146, 30, 44, 60, PAPER, stroke=INK, sw=1))
    body.append(line(152, 42, 184, 42, INK, 1.2))
    body.append(line(152, 50, 180, 50, INK, 1.2))
    body.append(line(152, 58, 184, 58, INK, 1.2))
    body.append(circle(168, 30, 4, RED))
    body.append(circle(164, 112, 9, PAPER, stroke=GREEN, sw=2.5))
    body.append(circle(164, 150, 9, PAPER, stroke=RED, sw=2.5))
    body.append(line(146, 182, 186, 182, INK, 1.2))
    return card('paper', body)


# --------------------------------------------------------------------------
# Round 4 — the bus voltmeters against the band (+6 % / -9 %).
# --------------------------------------------------------------------------

def bus_card(reading, ratio):
    import math as m
    ang = max(-130.0, min(130.0, (ratio - 1.0) / 0.15 * 110.0))
    cx, cy, r = 64, 68, 30
    a = m.radians(ang)
    body = [
        circle(cx, cy, r + 4, 'url(#steel)', stroke=INK, sw=1.2),
        circle(cx, cy, r, PAPER, stroke=INK, sw=1.5),
    ]
    for t in range(-120, 121, 30):
        ta = m.radians(t)
        body.append(line(cx + (r - 6) * m.sin(ta), cy - (r - 6) * m.cos(ta),
                         cx + (r - 2) * m.sin(ta), cy - (r - 2) * m.cos(ta), INK, 1.2))
    body.append(line(cx, cy, cx + (r - 6) * m.sin(a), cy - (r - 6) * m.cos(a), RED, 2.5))
    body.append(circle(cx, cy, 3, INK))
    body.append(glyphs(22, 106, reading, h=12, color=INK))
    body.append(glyphs(62, 106, 'kV', h=12, color=INK))
    body.append(rect(118, 46, 62, 50, METER_Y, rx=6, stroke=METER_D, sw=1.2))
    body.append(glyphs(137, 58, '5', h=24, color=INK))
    body.append(line(126, 86, 172, 86, INK, 1.2))
    body.append(rect(8, 20, 9, 42, 'url(#porc)', rx=4))
    body.append(rect(18, 126, 164, 12, 'url(#steel)', stroke=INK, sw=1))
    body.append(rect(18, 144, 164, 6, BRASS))
    body.append(rect(18, 156, 164, 6, BRASS))
    body.append(rect(96, 170, 8, 36, INK))
    return card('yard', body)


# --------------------------------------------------------------------------
# Round 5 — the drawal gauge and the capacitor bank at low voltage.
# --------------------------------------------------------------------------

def drawal_card(bar, freq, cap_on, low, shout=False, smoke=False):
    """bar: the 'টানা' bar's length against the 'ভাগ' line at x = 100 (1.0 = on the line)."""
    bar_end = 20 + 80 * bar
    body = [
        rect(18, 40, 164, 24, PAPER, rx=4, stroke=INK, sw=1.5),
        rect(20, 44, bar_end - 20, 16, METER_Y, rx=2),
        line(100, 34, 100, 70, INK, 2.5),
        glyphs(20, 80, freq, h=14, color=INK),
        glyphs(112, 80, 'Hz', h=14, color=INK),
        rect(18, 120, 62, 60, 'url(#panel)', rx=6),
        circle(38, 150, 7, RED if cap_on else PAPER, stroke=RED, sw=2.5),
        circle(60, 150, 7, PAPER if cap_on else GREEN, stroke=GREEN, sw=2.5),
        circle(138, 150, 22, PAPER, stroke=INK, sw=2),
    ]
    a = math.radians(-100 if low else 0)
    body.append(line(138, 150, 138 + 16 * math.sin(a), 150 - 16 * math.cos(a), RED, 2.5))
    body.append(circle(138, 150, 3, INK))
    body.extend(person(176, 120))
    if shout:
        body.append(path('M150 96 L158 102 L150 108 L158 114 L150 120', INK, 2))
    if smoke:
        body.append(rect(84, 190, 34, 12, 'url(#steel)', rx=2, stroke=INK, sw=1))
        body.append(circle(96, 180, 6, SMOKE))
        body.append(circle(102, 170, 8, SMOKE))
        body.append(circle(110, 158, 10, SMOKE))
    return card('sky', body)


# --------------------------------------------------------------------------
# Cards: round -> option id -> SVG. Safe cards first in each round.
# --------------------------------------------------------------------------

CARDS = {}
for name, reading in [('ok50', '50.00'), ('ok4995', '49.95'), ('ok5003', '50.03'),
                      ('low4970', '49.70'), ('high5020', '50.20'), ('low4890', '48.90')]:
    CARDS[f'freq_{name}'] = freq_card(reading)

CARDS['hotline_lift'] = hot_card('ear', 'base', 'ON')
CARDS['hotline_feeder'] = hot_card('ear', 'base', 'OFF', hand=True)
CARDS['hotline_lamp'] = hot_card('chest', 'base', 'OFF')
CARDS['hotline_chat'] = hot_card('desk', 'ear', 'ON', ring=True)
CARDS['hotline_argue'] = hot_card('ear', 'base', 'ON', burst=True)
CARDS['hotline_tea'] = hot_card('desk', 'base', 'ON', steam=True)

CARDS['register_rot'] = reg_card({(0, 0), (2, 1), (3, 2)})
CARDS['register_map'] = reg_card({(3, 0), (1, 2)})
CARDS['register_same'] = reg_card({(0, 0), (1, 0), (2, 0)})
CARDS['register_village'] = reg_card({(0, 0), (2, 0)})
CARDS['register_nocut'] = reg_card(set())

CARDS['bus_b11'] = bus_card('11.0', 11.0 / 11.0)
CARDS['bus_b113'] = bus_card('11.3', 11.3 / 11.0)
CARDS['bus_b32'] = bus_card('32.0', 32.0 / 33.0)
CARDS['bus_b121'] = bus_card('12.1', 12.1 / 11.0)
CARDS['bus_b99'] = bus_card('9.9', 9.9 / 11.0)
CARDS['bus_b365'] = bus_card('36.5', 36.5 / 33.0)

CARDS['drawal_ok'] = drawal_card(0.9, '49.85', cap_on=False, low=False)
CARDS['drawal_cap'] = drawal_card(0.8, '49.90', cap_on=True, low=True)
CARDS['drawal_over'] = drawal_card(1.5, '49.80', cap_on=False, low=False)
CARDS['drawal_capoff'] = drawal_card(0.8, '49.90', cap_on=False, low=True, smoke=True)
CARDS['drawal_shout'] = drawal_card(0.8, '49.90', cap_on=False, low=False, shout=True)

# Safe cards and traps per round (mirrors learn_board_pack84.dart).
ROUNDS = {
    'freq': (['freq_ok50', 'freq_ok4995', 'freq_ok5003'], ['freq_low4970', 'freq_high5020', 'freq_low4890']),
    'hotline': (['hotline_lift', 'hotline_feeder', 'hotline_lamp'], ['hotline_chat', 'hotline_argue', 'hotline_tea']),
    'register': (['register_rot', 'register_map'], ['register_same', 'register_village', 'register_nocut']),
    'bus': (['bus_b11', 'bus_b113', 'bus_b32'], ['bus_b121', 'bus_b99', 'bus_b365']),
    'drawal': (['drawal_ok', 'drawal_cap'], ['drawal_over', 'drawal_capoff', 'drawal_shout']),
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
