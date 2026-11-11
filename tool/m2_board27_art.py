"""Picture cards for the Module 2 lesson 2.7 board ('মেগার' (Megger) কী ও কেন?).

python -I tool/m2_board27_art.py .

Writes assets/game/art/m2_board27/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the meter readings are drawn as segment glyphs (paths), never
<text>.

What the cards show comes from lesson 2.7 only:
  1. pick: the megger (a high DC test voltage, e.g. 500V) shows the real
     health of insulation; a multimeter (low voltage, usually 9V) cannot;
     daily check: battery level and the test leads' insulation intact;
  2. prep: disconnect the cable from the supply and discharge it well (live
     or undischarged = strictly forbidden); dry (moisture gives a false, low
     reading); clean (dirt / carbon makes a leakage path);
  3. connect: the 'Line' lead on the conductor, the 'Earth' lead on the
     armour; the megger is itself a high-voltage source — don't touch exposed
     parts while testing;
  4. read: higher IR = better; new, dry kit: hundreds or thousands of MΩ, or
     GΩ; usually 1 MΩ is the minimum safe value; below 1 MΩ = weak, damp or
     damaged, not safe to use;
  5. after: discharge again after the test — the test voltage can stay
     stored as charge.

Fairness (the playbook, section 4): every card in a round shares one
backdrop, one bench, one cable, one megger and one discharge stick; only the
act tells the safe card from a trap. The script checks every hand the dealer
can make (one safe card + any three traps): each colour or gradient the safe
card draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board27_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board27')
W, H = 200, 220

GLOVE = '#2A2D33'
SLEEVE = '#1F5F8F'
SHEATH = '#2B3138'
INSUL = '#8C949B'
LEAD_R = '#D7372E'
LEAD_B = '#1C1F24'
LCD_INK = '#1E2A1E'
CASE_D = '#2A2F36'
EARTH_G = '#2F9E4A'
EARTH_Y = '#F2C230'
LAMP_OFF = '#5A2420'
LAMP_ON = '#FF5A3D'
DROP = '#9CC8E8'
SOOT = '#141414'
CRACK = '#0E1013'
DMM_Y = '#F2C230'
KNOB = '#6F777E'
BENCH_Y = 150

DEFS = """<defs>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3C4A57"/><stop offset="0.68" stop-color="#5D6E7C"/><stop offset="0.68" stop-color="#8A6E4C"/><stop offset="1" stop-color="#6E5638"/></linearGradient>
  <linearGradient id="case" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B64A"/><stop offset="1" stop-color="#C98622"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C7DEB2"/><stop offset="1" stop-color="#A9C795"/></linearGradient>
  <linearGradient id="armour" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E6EBEF"/><stop offset="0.5" stop-color="#A9B3BB"/><stop offset="1" stop-color="#6E7880"/></linearGradient>
  <linearGradient id="copper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2B07A"/><stop offset="0.5" stop-color="#C9783A"/><stop offset="1" stop-color="#8E4E22"/></linearGradient>
  <linearGradient id="sheath" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A535C"/><stop offset="0.5" stop-color="#2B3138"/><stop offset="1" stop-color="#1A1E23"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7D868E"/><stop offset="0.5" stop-color="#A9B3BB"/><stop offset="1" stop-color="#6E7880"/></linearGradient>
  <linearGradient id="stick" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E8B92C"/><stop offset="0.5" stop-color="#FFD866"/><stop offset="1" stop-color="#C99A1C"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FF8A6A" stop-opacity="0.9"/><stop offset="1" stop-color="#FF5A3D" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(back='wall'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# Segment glyphs for the meter displays (no <text> in the art).
# --------------------------------------------------------------------------

SEG = {  # a b c d e f g (top, top-right, bottom-right, bottom, bottom-left, top-left, middle)
    '0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
    '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg', '-': 'g',
}


def glyph(ch, x, y, w, h, ink=LCD_INK):
    """One glyph in a w x h box at (x, y); returns (svg, advance)."""
    t = max(1.2, w * 0.2)
    if ch == '1':  # narrow: the two right segments only, no empty box
        return (f'<g fill="{ink}"><rect x="{f(x)}" y="{f(y)}" width="{f(t)}" height="{f(h / 2)}" rx="0.4"/>'
                f'<rect x="{f(x)}" y="{f(y + h / 2)}" width="{f(t)}" height="{f(h / 2)}" rx="0.4"/></g>', t * 2.8)
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
    if ch == 'G':
        return (f'<path d="M{f(x + w)} {f(y + h * 0.18)} Q{f(x + w * 0.6)} {f(y - h * 0.05)} {f(x + w * 0.3)} {f(y + h * 0.1)} '
                f'Q{f(x - w * 0.1)} {f(y + h * 0.5)} {f(x + w * 0.3)} {f(y + h * 0.92)} Q{f(x + w * 0.7)} {f(y + h * 1.05)} {f(x + w)} {f(y + h * 0.8)} '
                f'L{f(x + w)} {f(y + h * 0.55)} L{f(x + w * 0.55)} {f(y + h * 0.55)}" stroke="{ink}" stroke-width="{sw}" fill="none"/>', w + t * 1.8)
    if ch == 'V':
        return (f'<path d="M{f(x)} {f(y)} L{f(x + w / 2)} {f(y + h)} L{f(x + w)} {f(y)}" stroke="{ink}" stroke-width="{sw}" fill="none" stroke-linejoin="round"/>',
                w + t * 1.8)
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


def infinity(cx, cy, r, ink=LCD_INK, sw=2.2):
    return (f'<path d="M{f(cx)} {f(cy)} C{f(cx + r * 0.6)} {f(cy - r * 0.9)} {f(cx + r * 1.6)} {f(cy - r * 0.9)} {f(cx + r * 1.6)} {f(cy)} '
            f'C{f(cx + r * 1.6)} {f(cy + r * 0.9)} {f(cx + r * 0.6)} {f(cy + r * 0.9)} {f(cx)} {f(cy)} '
            f'C{f(cx - r * 0.6)} {f(cy - r * 0.9)} {f(cx - r * 1.6)} {f(cy - r * 0.9)} {f(cx - r * 1.6)} {f(cy)} '
            f'C{f(cx - r * 1.6)} {f(cy + r * 0.9)} {f(cx - r * 0.6)} {f(cy + r * 0.9)} {f(cx)} {f(cy)} Z" stroke="{ink}" stroke-width="{f(sw)}" fill="none"/>')


# --------------------------------------------------------------------------
# Props.
# --------------------------------------------------------------------------

def cable(ex, cy, s=1.0, crack=False, wet=False, soot=False):
    """An armoured cable from the left edge to a stripped end at ex:
    sheath, the armour band, the core insulation, the copper conductor.
    Returns (svg, conductor tip (x, y), armour point (x, y))."""
    r = 9 * s
    a0, a1 = ex - 34 * s, ex - 22 * s
    i1 = ex - 10 * s
    out = [f'<rect x="-10" y="{f(cy - r)}" width="{f(a0 + 10)}" height="{f(2 * r)}" fill="url(#sheath)"/>',
           f'<rect x="{f(a0)}" y="{f(cy - r * 0.92)}" width="{f(a1 - a0)}" height="{f(2 * r * 0.92)}" fill="url(#armour)"/>']
    for k in range(4):
        x = a0 + (k + 0.5) * (a1 - a0) / 4
        out.append(f'<path d="M{f(x - 1.5 * s)} {f(cy - r * 0.9)} L{f(x + 1.5 * s)} {f(cy + r * 0.9)}" stroke="#6E7880" stroke-width="{f(0.8 * s)}"/>')
    out.append(f'<rect x="{f(a1)}" y="{f(cy - r * 0.62)}" width="{f(i1 - a1)}" height="{f(2 * r * 0.62)}" rx="{f(2 * s)}" fill="{INSUL}"/>')
    out.append(f'<rect x="{f(i1)}" y="{f(cy - r * 0.34)}" width="{f(16 * s)}" height="{f(2 * r * 0.34)}" rx="{f(2 * s)}" fill="url(#copper)"/>')
    if crack:
        x = a0 - 34 * s
        out.append(f'<path d="M{f(x)} {f(cy - r)} L{f(x + 4 * s)} {f(cy - r * 0.3)} L{f(x - 2 * s)} {f(cy + r * 0.1)} L{f(x + 5 * s)} {f(cy + r * 0.7)} L{f(x + 1 * s)} {f(cy + r)}" '
                   f'stroke="{CRACK}" stroke-width="{f(2.2 * s)}" fill="none" stroke-linejoin="round"/>')
        out.append(f'<path d="M{f(x + 6 * s)} {f(cy - r)} L{f(x + 9 * s)} {f(cy - r * 0.2)} L{f(x + 6 * s)} {f(cy + r * 0.3)}" stroke="{CRACK}" stroke-width="{f(1.4 * s)}" fill="none"/>')
        out.append(f'<rect x="{f(x - 2 * s)}" y="{f(cy - r * 0.2)}" width="{f(9 * s)}" height="{f(r * 0.4)}" fill="{INSUL}" opacity="0.8"/>')
    if soot:
        # Dirt and a carbon crust over the core and the conductor end.
        out.append(f'<ellipse cx="{f(a1 + 5 * s)}" cy="{f(cy)}" rx="{f(12 * s)}" ry="{f(r * 0.85)}" fill="{SOOT}" opacity="0.85"/>')
        out.append(f'<ellipse cx="{f(i1 + 8 * s)}" cy="{f(cy + r * 0.1)}" rx="{f(9 * s)}" ry="{f(r * 0.6)}" fill="{SOOT}" opacity="0.8"/>')
        for k in range(9):
            out.append(f'<circle cx="{f(a1 - 6 * s + (k * 7 % 30) * s)}" cy="{f(cy - r - 2 * s - (k * 5 % 9) * s)}" r="{f(1.3 * s)}" fill="{SOOT}"/>')
    if wet:
        out.append(drops(a0 - 50 * s, cy - r - 4 * s, 80 * s))
    tip = (i1 + 9 * s, cy)
    arm = ((a0 + a1) / 2, cy)
    return ''.join(out), tip, arm


def drops(x, y, span):
    out = []
    for k in range(7):
        dx = x + (k * 37 % 97) / 97 * span
        dy = y - (k * 23 % 31)
        out.append(f'<path d="M{f(dx)} {f(dy)} q2.6 4.4 0 6.2 q-2.6 -1.8 0 -6.2 Z" fill="{DROP}"/>')
    return ''.join(out)


def puddle(cx, cy, rx):
    return f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(rx)}" ry="{f(rx * 0.14)}" fill="{DROP}" opacity="0.55"/>'


def battery(x, y, bars, empty=False):
    s = [f'<rect x="{f(x)}" y="{f(y)}" width="13" height="7" rx="1" fill="none" stroke="{LCD_INK}" stroke-width="1"/>',
         f'<rect x="{f(x + 13)}" y="{f(y + 2)}" width="1.6" height="3" fill="{LCD_INK}"/>']
    for k in range(bars):
        s.append(f'<rect x="{f(x + 1.6 + k * 3.8)}" y="{f(y + 1.6)}" width="2.8" height="3.8" fill="{LCD_INK}"/>')
    if empty:
        s.append(f'<rect x="{f(x + 1.6)}" y="{f(y + 1.6)}" width="1.6" height="3.8" fill="{LEAD_R}"/>')
    return ''.join(s)


def megger(x, y, s=1.0, show='500V', bars=3, empty_batt=False):
    """The insulation tester: case, LCD, voltage knob, red test button and
    the two terminals (red L, black E) on top. Returns (svg, L, E, button)."""
    w, h = 76, 58
    g = [f'<rect x="0" y="0" width="{w}" height="{h}" rx="7" fill="url(#case)"/>',
         f'<rect x="5" y="5" width="{w - 10}" height="{h - 10}" rx="4" fill="{CASE_D}"/>',
         '<rect x="9" y="8" width="42" height="26" rx="2" fill="url(#lcd)"/>']
    if show == 'blank':
        g.append(readout('---', 13, 11, 10)[0])
    elif show:
        txt, wid = readout(show, 0, 0, 10)
        sc = min(1.0, 34 / wid)
        g.append(f'<g transform="translate(13 {f(11 + (10 - 10 * sc) / 2)}) scale({f(sc)})">{txt}</g>')
    # Battery mark sits under the readout, right end of the LCD.
    g.append(f'<g transform="translate(34 24.5) scale(0.9)">{battery(0, 0, bars, empty_batt)}</g>')
    g.append(f'<circle cx="62" cy="19" r="7.5" fill="{KNOB}"/><path d="M62 19 L66 13" stroke="#E6EBEF" stroke-width="1.6" stroke-linecap="round"/>')
    g.append(f'<circle cx="22" cy="41" r="5.6" fill="{LEAD_R}"/><circle cx="22" cy="41" r="3.4" fill="none" stroke="{CASE_D}" stroke-width="0.8"/>')
    for k in range(3):
        g.append(f'<rect x="{36 + k * 9}" y="38" width="6" height="6" rx="1.2" fill="{KNOB}"/>')
    g.append(f'<rect x="12" y="-5" width="7" height="6" rx="1.5" fill="{LEAD_R}"/><rect x="56" y="-5" width="7" height="6" rx="1.5" fill="{LEAD_B}"/>')
    svg = f'<g transform="translate({f(x)} {f(y)}) scale({s})">' + ''.join(g) + '</g>'
    L = (x + 15.5 * s, y - 4 * s)
    E = (x + 59.5 * s, y - 4 * s)
    btn = (x + 22 * s, y + 41 * s)
    return svg, L, E, btn


def clip(x, y, color, ang=0, s=1.0):
    """A crocodile clip, jaws at (x, y), body trailing along ang (deg)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({f(s)})">'
            f'<path d="M0 -2 L14 -4.6 L16 -1 L16 1 L14 4.6 L0 2 Z" fill="{color}"/>'
            f'<path d="M-3 -2.6 L2 -2.6 L2 2.6 L-3 2.6 Z" fill="url(#armour)"/>'
            '</g>')


def lead(a, b, color, sag=24, w=2.4, cut=False):
    """A test lead from terminal a to clip b, sagging below the straight line."""
    (x0, y0), (x1, y1) = a, b
    cx, cy = (x0 + x1) / 2, max(y0, y1) + sag
    s = f'<path d="M{f(x0)} {f(y0)} Q{f(cx)} {f(cy)} {f(x1)} {f(y1)}" stroke="{color}" stroke-width="{w}" fill="none" stroke-linecap="round"/>'
    if cut:
        # A split in the lead's insulation, the copper inside showing.
        t = 0.5
        px = (1 - t) ** 2 * x0 + 2 * t * (1 - t) * cx + t * t * x1
        py = (1 - t) ** 2 * y0 + 2 * t * (1 - t) * cy + t * t * y1
        s += (f'<rect x="{f(px - 9)}" y="{f(py - 3.4)}" width="18" height="6.8" rx="1.4" fill="url(#copper)"/>'
              f'<path d="M{f(px - 9)} {f(py - 4.4)} l3 9 M{f(px + 9)} {f(py - 4.4)} l-3 9 M{f(px - 3)} {f(py - 3)} l1 6 M{f(px + 3)} {f(py - 3)} l-1 6" stroke="{CRACK}" stroke-width="1.2"/>')
    return s


def arm(tip, frm, finger=True, grip=False):
    """A gloved hand in a blue sleeve reaching from frm (off the card) to tip."""
    (x0, y0), (x1, y1) = frm, tip
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy) or 1
    ux, uy = dx / n, dy / n
    wx, wy = x1 - ux * 18, y1 - uy * 18
    hx, hy = x1 - ux * 9, y1 - uy * 9
    s = [f'<path d="M{f(x0)} {f(y0)} L{f(wx)} {f(wy)}" stroke="{SLEEVE}" stroke-width="15" stroke-linecap="round"/>',
         f'<circle cx="{f(hx)}" cy="{f(hy)}" r="8.5" fill="{GLOVE}"/>']
    if grip:
        s.append(f'<path d="M{f(hx)} {f(hy)} L{f(x1 + uy * 4)} {f(y1 - ux * 4)} M{f(hx)} {f(hy)} L{f(x1 - uy * 4)} {f(y1 + ux * 4)}" '
                 f'stroke="{GLOVE}" stroke-width="5" stroke-linecap="round"/>')
    elif finger:
        s.append(f'<path d="M{f(hx)} {f(hy)} L{f(x1)} {f(y1)}" stroke="{GLOVE}" stroke-width="4.6" stroke-linecap="round"/>')
    return ''.join(s)


def dmm(x, y, s=1.0):
    """A handheld multimeter showing infinity (open) on its display."""
    g = [f'<rect x="0" y="0" width="40" height="64" rx="6" fill="{DMM_Y}"/>',
         f'<rect x="4" y="4" width="32" height="56" rx="4" fill="{CASE_D}"/>',
         '<rect x="7" y="8" width="26" height="15" rx="2" fill="url(#lcd)"/>',
         infinity(20, 15.5, 4.6, sw=1.6),
         f'<circle cx="20" cy="38" r="8" fill="{KNOB}"/><path d="M20 38 L24 32" stroke="#E6EBEF" stroke-width="1.4"/>',
         f'<circle cx="12" cy="54" r="2.4" fill="{LEAD_R}"/><circle cx="28" cy="54" r="2.4" fill="{LEAD_B}"/>']
    svg = f'<g transform="translate({f(x)} {f(y)}) scale({s})">' + ''.join(g) + '</g>'
    return svg, (x + 12 * s, y + 54 * s), (x + 28 * s, y + 54 * s)


def probe(tip, ang, color):
    return (f'<g transform="translate({f(tip[0])} {f(tip[1])}) rotate({f(ang)})">'
            f'<path d="M0 0 L5 -1.2 L5 1.2 Z" fill="url(#armour)"/><rect x="5" y="-2.6" width="22" height="5.2" rx="2" fill="{color}"/></g>')


def stick_leaning(x=18):
    """The insulated discharge stick, unused, leaning on the wall, with its
    earth lead (green/yellow) coiled at its foot."""
    return (f'<path d="M{x} {BENCH_Y - 4} L{x + 8} 26" stroke="url(#stick)" stroke-width="5" stroke-linecap="round"/>'
            f'<path d="M{x + 8} 26 l1 -9 q4 -3 6 2" stroke="#A9B3BB" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
            f'<ellipse cx="{x + 2}" cy="{BENCH_Y + 4}" rx="10" ry="3.4" fill="none" stroke="{EARTH_G}" stroke-width="2.4"/>'
            f'<ellipse cx="{x + 2}" cy="{BENCH_Y + 4}" rx="10" ry="3.4" fill="none" stroke="{EARTH_Y}" stroke-width="2.4" stroke-dasharray="3 4"/>')


def earth_point(x, y):
    """An earth bar on the wall with its ground mark."""
    return (f'<rect x="{f(x - 12)}" y="{f(y - 3)}" width="24" height="6" rx="1.5" fill="url(#armour)"/>'
            f'<path d="M{f(x)} {f(y + 3)} L{f(x)} {f(y + 9)} M{f(x - 8)} {f(y + 9)} L{f(x + 8)} {f(y + 9)} M{f(x - 5)} {f(y + 12)} L{f(x + 5)} {f(y + 12)} '
            f'M{f(x - 2)} {f(y + 15)} L{f(x + 2)} {f(y + 15)}" stroke="#E6EBEF" stroke-width="1.6"/>')


def earth_lead(a, b, sag=18):
    (x0, y0), (x1, y1) = a, b
    cx, cy = (x0 + x1) / 2, max(y0, y1) + sag
    d = f'M{f(x0)} {f(y0)} Q{f(cx)} {f(cy)} {f(x1)} {f(y1)}'
    return (f'<path d="{d}" stroke="{EARTH_G}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{EARTH_Y}" stroke-width="2.6" fill="none" stroke-dasharray="3 4"/>')


def stick_on(tip, butt):
    """The discharge stick in use: its hook on tip, held at butt."""
    (x0, y0), (x1, y1) = butt, tip
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy)
    ux, uy = dx / n, dy / n
    hx, hy = x1 - ux * 10, y1 - uy * 10
    return (f'<path d="M{f(x0)} {f(y0)} L{f(hx)} {f(hy)}" stroke="url(#stick)" stroke-width="5" stroke-linecap="round"/>'
            f'<path d="M{f(hx)} {f(hy)} L{f(x1)} {f(y1)} q{f(-uy * 6)} {f(ux * 6)} {f(-ux * 4 - uy * 6)} {f(-uy * 4 + ux * 6)}" stroke="#A9B3BB" stroke-width="2.4" fill="none" stroke-linecap="round"/>')


def bench():
    return f'<path d="M0 {BENCH_Y} L200 {BENCH_Y}" stroke="#5A4630" stroke-width="2"/>'


# --------------------------------------------------------------------------
# Round 1 — pick the tool for the insulation's real health.
# --------------------------------------------------------------------------

def pick_card(kind):
    out = card_open()
    out.append(bench())
    out.append(stick_leaning())
    cab, tip, armp = cable(150, 188)
    out.append(cab)
    if kind == 'dmm':
        # The megger left aside at the back; the multimeter's probes on the cable.
        m, L, E, btn = megger(118, 52, 0.85)
        out.append(m)
        d, pr, pb = dmm(50, 70, 1.0)
        out.append(d)
        out.append(lead(pr, (tip[0] - 4, tip[1] - 12), LEAD_R, 20))
        out.append(lead(pb, (armp[0] - 4, armp[1] - 14), LEAD_B, 30))
        out.append(probe((tip[0] - 4, tip[1] - 2), -80, LEAD_R))
        out.append(probe((armp[0] - 4, armp[1] - 4), -80, LEAD_B))
        out.append(arm((70, 104), (-10, 170)))
        return card_close(out)
    show, bars, empty = '500V', 3, False
    if kind == 'battery':
        show, bars, empty = 'blank', 0, True
    m, L, E, btn = megger(50, 70, 1.15, show=show, bars=bars, empty_batt=empty)
    out.append(m)
    if kind == 'check':
        # Both leads held up and looked over — insulation whole.
        out.append(lead(L, (150, 112), LEAD_R, 30))
        out.append(lead(E, (160, 120), LEAD_B, 18))
        out.append(clip(150, 112, LEAD_R, -60))
        out.append(clip(160, 120, LEAD_B, -60))
        out.append(arm((156, 118), (210, 190), grip=True))
        return card_close(out)
    out.append(lead(L, tip, LEAD_R, 40, cut=(kind == 'lead')))
    out.append(lead(E, armp, LEAD_B, 30))
    out.append(clip(tip[0], tip[1], LEAD_R, -90))
    out.append(clip(armp[0], armp[1], LEAD_B, -90))
    out.append(arm(btn, (-10, 200)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — before the test: disconnect, discharge, dry, clean.
# --------------------------------------------------------------------------

def supply_box(on):
    """The feeder box on the wall: an indicator lamp, a lever (up = on) and
    the outgoing terminal."""
    s = ['<rect x="128" y="22" width="62" height="96" rx="5" fill="url(#panel)"/>',
         f'<rect x="134" y="28" width="50" height="84" rx="3" fill="none" stroke="{KNOB}" stroke-width="1.4"/>']
    if on:
        s.append('<circle cx="146" cy="42" r="14" fill="url(#glow)"/>')
    s.append(f'<circle cx="146" cy="42" r="5" fill="{LAMP_ON if on else LAMP_OFF}"/>')
    s.append(f'<circle cx="170" cy="66" r="5" fill="{CASE_D}"/>')
    s.append(f'<path d="M170 66 L170 {44 if on else 88}" stroke="{LEAD_B}" stroke-width="5" stroke-linecap="round"/>')
    s.append(f'<rect x="{163}" y="{38 if on else 86}" width="14" height="7" rx="2" fill="{LEAD_R}"/>')
    s.append('<rect x="152" y="104" width="12" height="8" rx="1.5" fill="url(#armour)"/>')
    return ''.join(s)


def prep_card(kind):
    out = card_open()
    out.append(bench())
    on = kind == 'live'
    out.append(supply_box(on))
    out.append(earth_point(100, 34))
    wet, soot = kind == 'wet', kind == 'dirty'
    if kind == 'live':
        # Still bolted to the box: the cable rises from the bench to the terminal.
        out.append(f'<path d="M150 186 Q170 186 158 112" stroke="{SHEATH}" stroke-width="8" fill="none"/>')
    cab, tip, armp = cable(150, 186, wet=wet, soot=soot)
    out.append(cab)
    if wet:
        out.append(puddle(80, 200, 70))
    if kind == 'discharge':
        out.append(earth_lead((30, 110), (100, 37), 8))
        out.append(stick_on((tip[0] - 2, tip[1] - 4), (34, 104)))
        out.append(arm((40, 116), (-10, 150), grip=True))
    else:
        out.append(stick_leaning())
        out.append(earth_lead((20, BENCH_Y + 4), (100, 37), -40))
    m, L, E, btn = megger(48, 82, 0.8)
    if kind == 'isolate':
        # Lever down, the lamp dark; the freed cable end pulled away from the box.
        out.append(arm((tip[0] + 6, tip[1] - 4), (210, 214), grip=True))
    elif kind in ('live', 'wet', 'dirty'):
        out.append(m)
        out.append(lead(L, tip, LEAD_R, 34))
        out.append(clip(tip[0], tip[1], LEAD_R, -90))
        out.append(arm((tip[0] + 3, tip[1] - 6), (210, 214), grip=True))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — the two leads: Line on the conductor, Earth on the armour.
# --------------------------------------------------------------------------

def connect_card(kind):
    out = card_open()
    out.append(bench())
    cab, tip, armp = cable(170, 178, 1.6)
    out.append(cab)
    m, L, E, btn = megger(22, 64, 1.05)
    out.append(m)
    red_at, black_at = tip, armp
    if kind == 'same':
        black_at = (tip[0] - 9, tip[1])
    elif kind == 'armour':
        red_at = (armp[0] - 9, armp[1])
    elif kind == 'loose':
        black_at = (armp[0] - 22, 212)
    out.append(lead(L, red_at, LEAD_R, 34))
    out.append(lead(E, black_at, LEAD_B, 18))
    out.append(clip(red_at[0], red_at[1], LEAD_R, -90, 1.6))
    out.append(clip(black_at[0], black_at[1], LEAD_B, -90 if kind != 'loose' else 20, 1.6))
    if kind == 'touch':
        out.append(arm((tip[0] + 8, tip[1]), (210, 120), grip=True))
        out.append(arm(btn, (-10, 200)))
    elif kind == 'set':
        out.append(arm((black_at[0] + 2, black_at[1] - 8), (210, 110), grip=True))
    else:
        out.append(arm(btn, (-10, 200)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — read the display after a 1-minute test.
# --------------------------------------------------------------------------

READS = {'high': '850MO', 'giga': '2.5GO', 'low': '0.5MO', 'damp': '0.3MO', 'crack': '0.1MO'}


def read_card(kind):
    out = card_open()
    out.append(bench())
    cab, tip, armp = cable(176, 192, 1.0, wet=(kind == 'damp'), crack=(kind == 'crack'))
    out.append(cab)
    if kind == 'damp':
        out.append(puddle(90, 206, 60))
    # A big megger: the reading is the card.
    w, h = 150, 96
    x, y = 25, 26
    g = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="url(#case)"/>',
         f'<rect x="{x + 7}" y="{y + 7}" width="{w - 14}" height="{h - 14}" rx="6" fill="{CASE_D}"/>',
         f'<rect x="{x + 13}" y="{y + 13}" width="{w - 50}" height="44" rx="3" fill="url(#lcd)"/>']
    txt, wid = readout(READS[kind], 0, 0, 22)
    sc = min(1.0, (w - 62) / wid)
    g.append(f'<g transform="translate({f(x + 19)} {f(y + 24)}) scale({f(sc)})">{txt}</g>')
    g.append(f'<circle cx="{x + w - 22}" cy="{y + 32}" r="11" fill="{KNOB}"/><path d="M{x + w - 22} {y + 32} L{x + w - 16} {y + 23}" stroke="#E6EBEF" stroke-width="2" stroke-linecap="round"/>')
    g.append(f'<circle cx="{x + 26}" cy="{y + 72}" r="7" fill="{LEAD_R}"/>')
    g.append(f'<rect x="{x + 18}" y="{y - 6}" width="9" height="7" rx="1.5" fill="{LEAD_R}"/><rect x="{x + w - 30}" y="{y - 6}" width="9" height="7" rx="1.5" fill="{LEAD_B}"/>')
    out.append(''.join(g))
    out.append(lead((x + 22, y + h - 2), tip, LEAD_R, 30))
    out.append(lead((x + w - 26, y + h - 2), armp, LEAD_B, 16))
    out.append(clip(tip[0], tip[1], LEAD_R, -90))
    out.append(clip(armp[0], armp[1], LEAD_B, -90))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — the test is over: discharge again before anyone touches it.
# --------------------------------------------------------------------------

def after_card(kind):
    out = card_open()
    out.append(bench())
    out.append(earth_point(110, 34))
    cab, tip, armp = cable(160, 180, 1.4)
    m, L, E, btn = megger(20, 62, 0.9)
    out.append(m)
    if kind == 'coil':
        # The end lifted off the bench and swung onto a shoulder at once.
        out.append(f'<ellipse cx="60" cy="196" rx="34" ry="9" fill="none" stroke="{SHEATH}" stroke-width="8"/>')
    out.append(cab)
    pulled = kind == 'pull'
    red_at = (tip[0] + 20, tip[1] - 34) if pulled else tip
    out.append(lead(L, red_at, LEAD_R, 30))
    out.append(lead(E, armp, LEAD_B, 18))
    out.append(clip(red_at[0], red_at[1], LEAD_R, -60 if pulled else -90))
    out.append(clip(armp[0], armp[1], LEAD_B, -90))
    if kind == 'discharge':
        out.append(earth_lead((150, 40), (110, 37), 20))
        out.append(stick_on((tip[0] + 6, tip[1] - 4), (176, 40)))
        out.append(arm((172, 56), (214, 90), grip=True))
    elif kind == 'earth':
        out.append(earth_lead((tip[0] + 8, tip[1] - 2), (110, 37), -10))
        out.append(clip(tip[0] + 8, tip[1] - 2, EARTH_G, -60))
        out.append(stick_leaning(178))
    else:
        out.append(stick_leaning(178))
        out.append(earth_lead((180, BENCH_Y + 4), (110, 37), -40))
        if kind == 'touch':
            out.append(arm((tip[0] + 8, tip[1]), (210, 130), grip=True))
        elif kind == 'pull':
            out.append(arm((red_at[0] + 4, red_at[1] - 3), (214, 100), grip=True))
        elif kind == 'coil':
            out.append(arm((tip[0] - 4, tip[1] - 4), (210, 120), grip=True))
    return card_close(out)


CARDS = {
    'pick_megger': pick_card('megger'),
    'pick_check': pick_card('check'),
    'pick_dmm': pick_card('dmm'),
    'pick_lead': pick_card('lead'),
    'pick_battery': pick_card('battery'),
    'prep_isolate': prep_card('isolate'),
    'prep_discharge': prep_card('discharge'),
    'prep_live': prep_card('live'),
    'prep_wet': prep_card('wet'),
    'prep_dirty': prep_card('dirty'),
    'connect_right': connect_card('right'),
    'connect_set': connect_card('set'),
    'connect_same': connect_card('same'),
    'connect_loose': connect_card('loose'),
    'connect_touch': connect_card('touch'),
    'connect_armour': connect_card('armour'),
    'read_high': read_card('high'),
    'read_giga': read_card('giga'),
    'read_low': read_card('low'),
    'read_damp': read_card('damp'),
    'read_crack': read_card('crack'),
    'after_discharge': after_card('discharge'),
    'after_earth': after_card('earth'),
    'after_touch': after_card('touch'),
    'after_pull': after_card('pull'),
    'after_coil': after_card('coil'),
}

# Safe cards and traps per round (mirrors learn_board_pack27.dart).
ROUNDS = {
    'pick': (['pick_megger', 'pick_check'], ['pick_dmm', 'pick_lead', 'pick_battery']),
    'prep': (['prep_isolate', 'prep_discharge'], ['prep_live', 'prep_wet', 'prep_dirty']),
    'connect': (['connect_right', 'connect_set'], ['connect_same', 'connect_loose', 'connect_touch', 'connect_armour']),
    'read': (['read_high', 'read_giga'], ['read_low', 'read_damp', 'read_crack']),
    'after': (['after_discharge', 'after_earth'], ['after_touch', 'after_pull', 'after_coil']),
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
    for k, v in CARDS.items():
        if '<text' in v:
            problems.append(f'{k}: words in the art')
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
