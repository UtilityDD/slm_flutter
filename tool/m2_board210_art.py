"""Picture cards for the lesson 2.10 শেখা board ("হাতিয়ারের যত্ন ও রক্ষণাবেক্ষণ").

python -I tool/m2_board210_art.py .

Writes assets/game/art/m2_board210/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge; the pole
round reuses that script's worker, ladder and pole). No words in the art.

What the cards show comes from lesson 2.10 only:
  1. daily: the 5-minute end-of-day routine — wipe with a dry cloth, inspect
     (insulated handles above all), every tool back in its own place; never a
     wet tool in the box;
  2. rust: keep dry, a thin layer of light oil, brush off light rust (steel
     brush), no oil on the insulation; rust makes a spanner slip; the myth
     "a little grease on tools is good" (extra grease gathers dirt, kills grip);
  3. meter: switch off when not in use, battery out for long storage (a leak
     ruins the meter), probe leads coiled gently, never twisted or folded;
  4. retire: crack in an insulated handle, bent screwdriver tip, widened
     spanner jaw, leaking hydraulic tool -> retire, label it unusable, and
     make a thrown-out tool useless so nobody picks it up again;
  5. bag: on the pole a canvas / leather tool bag, not a toolbox — tools close
     at hand, less risk of a tool falling from above.

Fairness (the playbook, section 4): every card in a round shares one backdrop
and one stage; the script checks every hand the dealer can make (one safe card
+ any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand too, and on the pole round a safe card with its worker on
the ground meets a trap with a low figure too.
"""

import importlib.util
import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board210_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board210')
W, H = 200, 220

# The step-25 worker, ladder and pole (tool/storm_board_art.py).
_spec = importlib.util.spec_from_file_location('storm_board_art', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'storm_board_art.py'))
sb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(sb)

SKIN, SKIN_D, SHIRT = sb.SKIN, sb.SKIN_D, sb.SHIRT
INK = '#1C1F24'
CLOTH, CLOTH_D = '#ECE2C8', '#C9BB98'
WATER = '#8CC4EA'
RUST, RUST_D = '#C46A2E', '#8A3D18'
GREASE = '#3B2F22'
OIL = '#D9A441'
TAG = '#D2443A'
HARNESS = '#E8762B'
LEAD_R = '#C8332B'
TRAY = '#3A2A22'

DEFS = """<defs>
  <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E6B78"/><stop offset="1" stop-color="#7F8B96"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9784A"/><stop offset="1" stop-color="#7C5531"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2D9"/><stop offset="1" stop-color="#CFE3EF"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="bag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A6A3E"/><stop offset="1" stop-color="#5E4626"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="insul" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E5533F"/><stop offset="1" stop-color="#A52A1F"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F6E9E"/><stop offset="1" stop-color="#1D4A6E"/></linearGradient>
  <linearGradient id="meter" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6CD43"/><stop offset="1" stop-color="#D9A81E"/></linearGradient>
  <linearGradient id="hyd" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E3892E"/><stop offset="1" stop-color="#B9661A"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

f = sb.f


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


card_close = sb.card_close


def g(x, y, ang=0, s=1.0, body=''):
    return f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)}) scale({s})">{body}</g>'


# --------------------------------------------------------------------------
# The tools, drawn big (they are the subject of the card).
# --------------------------------------------------------------------------

def spanner(x, y, ang=0, s=1.0, rust=False, wide=False, grease=False):
    j = 6.5 if wide else 3.6
    b = [f'<rect x="-30" y="-4" width="58" height="8" rx="3" fill="url(#steel)"/>',
         f'<path d="M26 -9 L40 -11 L45 -{f(j + 1)} L36 -{f(j)} L36 {f(j)} L45 {f(j + 1)} L40 11 L26 9 Z" fill="url(#steel)" stroke="#7D868E" stroke-width="0.6"/>',
         '<circle cx="-34" cy="0" r="7" fill="none" stroke="url(#steel)" stroke-width="5"/>',
         '<circle cx="-34" cy="0" r="9.4" fill="none" stroke="#7D868E" stroke-width="0.6"/>']
    if rust:
        b.append(f'<g fill="{RUST}" opacity="0.9"><ellipse cx="-12" cy="0" rx="7" ry="3"/><ellipse cx="32" cy="-6" rx="5" ry="3"/>'
                 f'<ellipse cx="-34" cy="6" rx="4" ry="2.4"/><ellipse cx="10" cy="1" rx="4" ry="2"/></g>'
                 f'<g fill="{RUST_D}"><circle cx="-14" cy="1" r="1.4"/><circle cx="31" cy="-5" r="1.2"/><circle cx="8" cy="0" r="1"/></g>')
    if grease:
        b.append(f'<g fill="{GREASE}"><ellipse cx="-6" cy="-1" rx="12" ry="5.5"/><ellipse cx="30" cy="3" rx="7" ry="5"/>'
                 f'<path d="M-2 4 q2 7 -1 10 q-3 -3 -1 -10 Z"/><ellipse cx="-34" cy="-5" rx="5" ry="3.4"/></g>'
                 '<g fill="#9C8A64"><circle cx="-10" cy="-2" r="1"/><circle cx="-3" cy="1" r="0.9"/><circle cx="28" cy="2" r="1"/><circle cx="2" cy="-3" r="0.8"/></g>')
    return g(x, y, ang, s, ''.join(b))


def pliers(x, y, ang=0, s=1.0, crack=False, tape=False, cut=False):
    """Insulated pliers pointing right: jaws, pivot, two red sleeved handles."""
    b = ['<path d="M0 -3 L24 -5 L26 -1 L2 1 Z" fill="url(#steel)" stroke="#7D868E" stroke-width="0.5"/>',
         '<path d="M0 3 L24 5 L26 1 L2 -1 Z" fill="url(#steel)" stroke="#7D868E" stroke-width="0.5"/>',
         '<path d="M-2 -2 L-12 -6 L-12 -1 Z M-2 2 L-12 6 L-12 1 Z" fill="#7D868E"/>']
    if cut:
        # Sawn through: the upper handle is gone at the cut, its stub left.
        b.append('<path d="M-11 -6 L-26 -11 L-28 -6 L-12 -1 Z" fill="url(#insul)"/>')
        b.append(g(-48, -22, -16, 1, '<path d="M8 4 L-10 -2 L-12 3 L6 9 Z" fill="url(#insul)"/>'))
    else:
        b.append('<path d="M-11 -6 L-50 -16 L-52 -10 L-12 -1 Z" fill="url(#insul)"/>')
    b.append('<path d="M-11 6 L-50 16 L-52 10 L-12 1 Z" fill="url(#insul)"/>')
    b.append('<circle cx="-2" cy="0" r="3.2" fill="#8A939B" stroke="#4F575F" stroke-width="0.8"/>')
    if crack:
        b.append(f'<path d="M-24 -9.6 L-27 -6 L-24.5 -5.2 L-28.5 -2.2" stroke="{INK}" stroke-width="1.6" fill="none" stroke-linejoin="round"/>'
                 '<path d="M-23.4 -9.4 L-26.4 -6" stroke="#FFFFFF" stroke-width="0.6" opacity="0.7" fill="none"/>')
    if tape:
        b.append(f'<path d="M-21 -11.6 L-17 -10.6 L-19 -2.4 L-23 -3.4 Z M-29 -13.6 L-25 -12.6 L-27 -4.4 L-31 -5.4 Z" fill="{INK}"/>')
    return g(x, y, ang, s, ''.join(b))


def screwdriver(x, y, ang=0, s=1.0, bent=False):
    b = ['<rect x="-44" y="-6" width="32" height="12" rx="5" fill="url(#insul)"/>',
         '<path d="M-38 -6 L-38 6 M-30 -6 L-30 6 M-22 -6 L-22 6" stroke="#A52A1F" stroke-width="1"/>']
    if bent:
        b.append('<path d="M-12 0 L16 0 Q24 0 27 -9" stroke="url(#steel)" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
                 '<path d="M-12 0 L16 0 Q24 0 27 -9" stroke="#7D868E" stroke-width="0.5" fill="none"/>')
    else:
        b.append('<rect x="-12" y="-1.7" width="34" height="3.4" fill="url(#steel)"/>'
                 '<path d="M22 -2.6 L30 -1 L30 1 L22 2.6 Z" fill="url(#steel)" stroke="#7D868E" stroke-width="0.5"/>')
    return g(x, y, ang, s, ''.join(b))


def hand(x, y, ang=0, s=1.0, grip=True):
    """A right hand coming in from the edge, sleeve and all (pointing right)."""
    b = ['<rect x="-60" y="-10" width="42" height="20" rx="4" fill="url(#shirt)"/>',
         f'<rect x="-20" y="-8" width="10" height="16" rx="3" fill="{SKIN_D}"/>',
         f'<ellipse cx="0" cy="0" rx="13" ry="10" fill="{SKIN}"/>']
    if grip:
        b.append(f'<g fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.6"><ellipse cx="8" cy="-7" rx="6" ry="3.4"/><ellipse cx="10" cy="-1" rx="6" ry="3.4"/>'
                 '<ellipse cx="9" cy="5" rx="5.6" ry="3.2"/><ellipse cx="2" cy="-11" rx="6" ry="3" transform="rotate(-30 2 -11)"/></g>')
    else:
        b.append(f'<g fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.6"><ellipse cx="16" cy="-6" rx="8" ry="3.2"/><ellipse cx="18" cy="0" rx="8" ry="3.2"/>'
                 '<ellipse cx="16" cy="6" rx="7" ry="3"/><ellipse cx="4" cy="-11" rx="6" ry="3" transform="rotate(-40 4 -11)"/></g>')
    return g(x, y, ang, s, ''.join(b))


def cloth(x, y, ang=0, s=1.0):
    return g(x, y, ang, s, f'<path d="M-18 -8 Q-4 -13 16 -9 L19 7 Q2 12 -17 8 Z" fill="{CLOTH}" stroke="{CLOTH_D}" stroke-width="0.8"/>'
                           f'<path d="M-12 -6 Q-2 0 -6 8 M4 -9 Q10 -1 6 9" stroke="{CLOTH_D}" stroke-width="1" fill="none"/>')


def drops(pts, s=1.0):
    return ''.join(f'<path d="M{f(x)} {f(y - 5 * s)} Q{f(x + 3.4 * s)} {f(y)} {f(x)} {f(y + 2 * s)} Q{f(x - 3.4 * s)} {f(y)} {f(x)} {f(y - 5 * s)} Z" fill="{WATER}"/>'
                   for x, y in pts)


def bench_stage(props=''):
    """The depot wall and the workbench every bench card shares."""
    out = card_open('wall')
    out.append('<g stroke="#4F5B67" stroke-width="0.8" opacity="0.6">' + ''.join(f'<path d="M0 {y} L200 {y}"/>' for y in (34, 74, 114)) + '</g>')
    out.append('<rect x="0" y="146" width="200" height="74" fill="url(#bench)"/>')
    out.append('<rect x="0" y="146" width="200" height="4" fill="#C79A66"/>')
    out.append('<g stroke="#6B4728" stroke-width="0.8" opacity="0.5"><path d="M0 172 L200 170"/><path d="M0 198 L200 200"/></g>')
    if props:
        out.append(props)
    return out


def toolbox(x, y, state='tidy', lid=True):
    """An open toolbox seen from the front: lid up, the tools' tops in it."""
    b = []
    if lid:
        b.append('<path d="M-40 -34 L40 -34 L36 -62 L-36 -62 Z" fill="url(#box)" opacity="0.85"/>')
    b.append(f'<rect x="-40" y="-36" width="80" height="8" fill="{TRAY}"/>')
    if state == 'tidy':
        for i, xx in enumerate((-30, -18, -6, 6, 18, 30)):
            b.append(f'<rect x="{xx - 2.5}" y="-50" width="5" height="18" rx="2" fill="{"url(#insul)" if i % 2 == 0 else "url(#steel)"}"/>')
        b.append('<g stroke="#163A57" stroke-width="1.4">' + ''.join(f'<path d="M{xx} -36 L{xx} -28"/>' for xx in (-24, -12, 0, 12, 24)) + '</g>')
    elif state == 'heap':
        b.append(spanner(-12, -44, -32, 0.5) + pliers(10, -40, 140, 0.5) + screwdriver(-2, -46, 18, 0.5) + spanner(22, -42, 70, 0.45)
                 + screwdriver(-26, -40, -70, 0.45))
    b.append('<rect x="-42" y="-30" width="84" height="40" rx="4" fill="url(#box)"/>')
    b.append('<rect x="-12" y="-20" width="24" height="5" rx="2" fill="#163A57"/>')
    return g(x, y, 0, 1, ''.join(b))


# --------------------------------------------------------------------------
# Round 1 — the day's end: 5 minutes of care (clean, inspect, store).
# --------------------------------------------------------------------------

def daily_card(kind):
    # A spare screwdriver on the bench, on every card of the round.
    out = bench_stage(screwdriver(160, 206, 4, 0.7))
    if kind == 'wipe':
        out.append(toolbox(150, 150, 'tidy'))
        out.append(spanner(66, 178, -8, 1.1))
        out.append(cloth(70, 168, -6, 1.1))
        out.append(hand(60, 158, 20, 1.0))
    elif kind == 'place':
        out.append(toolbox(100, 150, 'tidy'))
        out.append(cloth(36, 186, 4, 1.0))
        out.append(screwdriver(124, 112, 90, 0.8))
        out.append(hand(124, 70, 90, 0.95))
    elif kind == 'wet':
        out.append(toolbox(110, 150, 'tidy'))
        out.append(cloth(36, 192, 4, 1.0))
        out.append(spanner(112, 104, 80, 0.8))
        out.append(drops([(104, 132), (118, 136), (110, 70), (124, 90), (98, 92)], 1.1))
        out.append(hand(112, 64, 90, 0.9))
        out.append(f'<ellipse cx="150" cy="182" rx="26" ry="4" fill="{WATER}" opacity="0.6"/>')
        out.append(pliers(150, 176, 4, 0.9) + drops([(140, 168), (160, 170)], 0.9))
    elif kind == 'heap':
        out.append(toolbox(100, 150, 'heap'))
        out.append(cloth(36, 192, 4, 1.0))
        out.append(spanner(150, 104, 150, 0.7))
        out.append(hand(170, 72, 120, 0.9, grip=False))
        out.append('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.8"><path d="M130 92 l-6 6"/><path d="M138 100 l-7 5"/></g>')
    elif kind == 'greasy':
        out.append(toolbox(110, 150, 'tidy'))
        out.append(cloth(36, 192, 4, 1.0))
        out.append(spanner(112, 104, 80, 0.85, grease=True))
        out.append(hand(112, 62, 90, 0.9))
    elif kind == 'unchecked':
        out.append(toolbox(110, 150, 'tidy'))
        out.append(cloth(36, 192, 4, 1.0))
        out.append(pliers(112, 116, -90, 1.0, crack=True))
        out.append(hand(112, 62, 90, 0.9))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — rust, the silent enemy.
# --------------------------------------------------------------------------

def oilcan(x, y, ang=0, s=1.0, drip=True):
    b = ['<path d="M-14 -4 L14 -4 L16 22 L-16 22 Z" fill="#3F7F4A"/>',
         '<ellipse cx="0" cy="-4" rx="14" ry="4" fill="#5FA06A"/>',
         '<path d="M4 -6 L30 -26" stroke="url(#steel)" stroke-width="3.2" stroke-linecap="round"/>']
    if drip:
        b.append(f'<path d="M31 -24 Q34 -18 31 -16 Q28 -18 31 -24 Z" fill="{OIL}"/>')
    return g(x, y, ang, s, ''.join(b))


def brush(x, y, ang=0, s=1.0):
    return g(x, y, ang, s, '<rect x="-34" y="-4" width="34" height="8" rx="3" fill="#8A5A32"/>'
                           '<rect x="0" y="-7" width="24" height="9" rx="2" fill="#8A5A32"/>'
                           '<g stroke="#6F777E" stroke-width="1.4">' + ''.join(f'<path d="M{x0} 2 L{x0} 9"/>' for x0 in range(2, 24, 3)) + '</g>')


def rust_stage(rain=False):
    out = bench_stage()
    # A window on the wall: the monsoon outside, on every card of the round.
    out.append('<rect x="14" y="16" width="56" height="60" rx="3" fill="#9FB2C2" stroke="#3F4A55" stroke-width="3"/>'
               '<path d="M42 16 L42 76 M14 46 L70 46" stroke="#3F4A55" stroke-width="2"/>'
               '<g stroke="#DCE6EE" stroke-width="1" opacity="0.8">' + ''.join(f'<path d="M{18 + (i * 13) % 50} {20 + (i * 17) % 50} l-3 8"/>' for i in range(14)) + '</g>')
    out.append(oilcan(172, 166, 0, 0.9))
    out.append(brush(176, 206, 0, 0.6))
    if rain:
        out.append('<path d="M14 76 Q12 110 20 146" stroke="#8CC4EA" stroke-width="3" fill="none" opacity="0.8"/>')
    return out


def rust_card(kind):
    if kind == 'oil':
        out = rust_stage()
        out.append(spanner(84, 184, -4, 1.1, rust=False))
        out.append(f'<path d="M66 180 Q84 176 104 180" stroke="{OIL}" stroke-width="1.4" fill="none" opacity="0.8"/>')
        out.append(oilcan(70, 140, 30, 1.0))
        out.append(hand(52, 132, 30, 0.9))
    elif kind == 'brush':
        out = rust_stage()
        out.append(spanner(90, 184, -4, 1.1, rust=True))
        out.append(brush(110, 170, -10, 0.9))
        out.append(hand(120, 166, 170, 0.9))
        out.append('<g fill="#C46A2E" opacity="0.8"><circle cx="102" cy="194" r="1"/><circle cx="108" cy="198" r="0.8"/><circle cx="96" cy="199" r="0.9"/></g>')
    elif kind == 'oil_handle':
        out = rust_stage()
        out.append(pliers(110, 184, 180, 1.0))
        out.append(f'<g fill="{OIL}"><ellipse cx="136" cy="186" rx="12" ry="5" opacity="0.8"/><path d="M134 150 Q137 156 134 158 Q131 156 134 150 Z"/>'
                   '<path d="M138 164 Q141 170 138 172 Q135 170 138 164 Z"/></g>')
        out.append(oilcan(118, 126, 40, 1.0))
        out.append(hand(98, 116, 40, 0.9))
    elif kind == 'damp':
        out = rust_stage(rain=True)
        out.append(f'<ellipse cx="80" cy="186" rx="52" ry="9" fill="{WATER}" opacity="0.65"/>')
        out.append(spanner(70, 184, -6, 1.0, rust=True))
        out.append(pliers(110, 194, 170, 0.8))
        out.append(drops([(30, 150), (24, 162)], 1.0))
    elif kind == 'slip':
        out = rust_stage()
        # A rusted spanner skids off the nut on a bench vice bracket.
        out.append('<rect x="92" y="120" width="40" height="30" rx="3" fill="#4F575F"/>'
                   '<path d="M112 114 l7 4 l0 8 l-7 4 l-7 -4 l0 -8 Z" fill="#8A939B" stroke="#4F575F" stroke-width="0.8"/>')
        out.append(spanner(80, 110, -28, 1.0, rust=True))
        out.append(hand(44, 130, -28, 0.9))
        out.append('<g stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" opacity="0.9"><path d="M124 98 l8 -6"/><path d="M128 106 l10 -3"/><path d="M120 92 l4 -8"/></g>')
    elif kind == 'grease':
        out = rust_stage()
        out.append(spanner(84, 182, -4, 1.1, grease=True))
        out.append(f'<g fill="{GREASE}"><ellipse cx="120" cy="196" rx="10" ry="3"/></g>')
        out.append(hand(70, 140, 60, 0.9, grip=False))
        out.append(f'<g fill="{GREASE}"><ellipse cx="80" cy="152" rx="5" ry="3"/><ellipse cx="76" cy="146" rx="3" ry="2"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — the meter (multimeter / megger) put away for a long while.
# --------------------------------------------------------------------------

def meter(x, y, on=False, open_back=False, leak=False):
    b = ['<rect x="-28" y="-44" width="56" height="88" rx="9" fill="url(#meter)"/>',
         f'<rect x="-22" y="-38" width="44" height="76" rx="6" fill="{INK}" opacity="0.9"/>']
    if open_back:
        b.append('<rect x="-16" y="-30" width="32" height="44" rx="3" fill="#3F4A55"/>')
        if leak:
            b.append('<rect x="-10" y="-26" width="20" height="30" rx="2" fill="#2E3A46"/><rect x="-7" y="-29" width="5" height="3" fill="#C0C6CC"/><rect x="2" y="-29" width="5" height="3" fill="#C0C6CC"/>'
                     '<g fill="#E8F0C8"><ellipse cx="-6" cy="4" rx="6" ry="3.4"/><ellipse cx="6" cy="-4" rx="5" ry="3"/><ellipse cx="0" cy="10" rx="9" ry="3"/></g>'
                     '<g fill="#9CC27A"><circle cx="-4" cy="3" r="1.6"/><circle cx="7" cy="-3" r="1.4"/><circle cx="2" cy="10" r="1.6"/></g>')
        b.append('<rect x="-12" y="20" width="24" height="10" rx="2" fill="#5E6B78"/>')
    else:
        b.append(f'<rect x="-16" y="-32" width="32" height="18" rx="2" fill="{"#BDF5C2" if on else "#6E7C78"}"/>')
        if on:
            b.append('<g stroke="#1E5B2A" stroke-width="2" stroke-linecap="round"><path d="M-10 -28 L-10 -18"/><path d="M-4 -28 L2 -28 L2 -23 L-4 -23 L-4 -18 L2 -18"/><path d="M6 -28 L12 -28 L12 -18"/></g>'
                     '<rect x="-22" y="-38" width="44" height="30" rx="6" fill="#BDF5C2" opacity="0.18"/>')
        b.append('<circle cx="0" cy="8" r="12" fill="#2A2D33" stroke="#5E6B78" stroke-width="2"/>')
        knob = -60 if on else 0
        b.append(f'<path d="M0 8 L0 -2" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" transform="rotate({knob} 0 8)"/>')
        b.append('<circle cx="-11" cy="30" r="3" fill="#C8332B"/><circle cx="11" cy="30" r="3" fill="#5E6B78"/>')
    return g(x, y, 0, 1, ''.join(b))


def coil_leads(x, y, tight=False):
    if tight:
        # Wound hard round and round, folded sharp, a kink in each lead.
        loops = ''.join(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="{f(10 - i * 0.3)}" ry="{f(5 - i * 0.2)}" fill="none" stroke="{c}" stroke-width="2"/>'
                        for i, c in enumerate([INK, LEAD_R] * 4))
        return (loops + f'<path d="M{f(x + 10)} {f(y)} L{f(x + 26)} {f(y - 8)} L{f(x + 18)} {f(y - 16)} L{f(x + 34)} {f(y - 24)}" stroke="{LEAD_R}" stroke-width="2" fill="none" stroke-linejoin="miter"/>'
                f'<path d="M{f(x - 10)} {f(y)} L{f(x - 22)} {f(y - 12)} L{f(x - 14)} {f(y - 18)} L{f(x - 28)} {f(y - 26)}" stroke="{INK}" stroke-width="2" fill="none" stroke-linejoin="miter"/>')
    return (f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="22" ry="9" fill="none" stroke="{LEAD_R}" stroke-width="2"/>'
            f'<ellipse cx="{f(x + 3)}" cy="{f(y + 1)}" rx="17" ry="7" fill="none" stroke="{INK}" stroke-width="2"/>'
            f'<rect x="{f(x - 30)}" y="{f(y - 2)}" width="14" height="3.4" rx="1.4" fill="{LEAD_R}"/><rect x="{f(x + 18)}" y="{f(y + 3)}" width="14" height="3.4" rx="1.4" fill="{INK}"/>')


def meter_card(kind):
    out = bench_stage()
    if kind == 'coil':
        out.append(meter(70, 140))
        out.append(coil_leads(144, 184))
    elif kind == 'battery':
        out.append(meter(70, 140, open_back=True))
        out.append('<g transform="translate(140 182) rotate(-8)"><rect x="-10" y="-14" width="20" height="28" rx="2" fill="#2E3A46"/>'
                   '<rect x="-7" y="-17" width="5" height="3" fill="#C0C6CC"/><rect x="2" y="-17" width="5" height="3" fill="#C0C6CC"/></g>')
        out.append(hand(150, 150, 150, 0.8, grip=False))
        out.append(coil_leads(150, 204))
    elif kind == 'on':
        out.append(meter(70, 140, on=True))
        out.append(coil_leads(144, 184))
        out.append(hand(150, 130, 160, 0.8, grip=False))
    elif kind == 'tight':
        out.append(meter(70, 140))
        out.append(coil_leads(150, 180, tight=True))
        out.append(hand(176, 150, 130, 0.8))
    elif kind == 'leak':
        out.append(meter(70, 140, open_back=True, leak=True))
        out.append(coil_leads(144, 184))
        out.append(hand(150, 140, 160, 0.8, grip=False))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — when a tool must retire.
# --------------------------------------------------------------------------

def red_tag(x, y, s=1.0):
    return g(x, y, -14, s, '<path d="M-14 0 L-30 -6" stroke="#6F777E" stroke-width="1.2" fill="none"/>'
                           f'<path d="M-14 -10 L18 -10 L24 0 L18 10 L-14 10 Z" fill="{TAG}"/><circle cx="-9" cy="0" r="2" fill="#FFFFFF"/>'
                           '<path d="M0 -5 L12 5 M12 -5 L0 5" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"/>')


def hacksaw(x, y, ang=0, s=1.0):
    return g(x, y, ang, s, '<path d="M-40 -12 L36 -12 L36 4 M-40 -12 L-40 4" stroke="#3F4A55" stroke-width="3" fill="none"/>'
                           '<rect x="-42" y="2" width="80" height="4" fill="url(#steel)"/>'
                           '<path d="M-56 -14 Q-44 -12 -40 -2 L-46 6 Q-56 0 -56 -14 Z" fill="#3F4A55"/>')


def crimper(x, y, ang=0, s=1.0, leak=False):
    b = ['<rect x="-36" y="-9" width="44" height="18" rx="7" fill="url(#hyd)"/>',
         '<rect x="8" y="-6" width="18" height="12" fill="url(#steel)"/>',
         '<path d="M26 -14 L44 -14 L44 14 L26 14 L26 6 L36 6 L36 -6 L26 -6 Z" fill="url(#steel)" stroke="#7D868E" stroke-width="0.6"/>',
         '<rect x="-62" y="-4" width="28" height="8" rx="3" fill="#3F4A55"/>']
    if leak:
        b.append(f'<g fill="{OIL}"><path d="M6 8 Q10 16 6 19 Q2 16 6 8 Z"/><path d="M14 10 Q17 16 14 18 Q11 16 14 10 Z"/></g>')
    return g(x, y, ang, s, ''.join(b))


def retire_card(kind):
    # The scrap bin and a pad of red tags on the wall hook, on every card.
    out = bench_stage(f'<circle cx="34" cy="22" r="3" fill="{INK}"/>' + g(30, 40, 90, 0.7, red_tag(0, 0, 1.0)))
    nut = ('<rect x="120" y="106" width="44" height="40" rx="3" fill="#4F575F"/>'
           '<path d="M142 100 l7 4 l0 8 l-7 4 l-7 -4 l0 -8 Z" fill="#8A939B" stroke="#2A2D33" stroke-width="0.8"/>')
    bin_ = '<path d="M150 150 L192 150 L188 206 L154 206 Z" fill="#3F4A55"/><rect x="146" y="146" width="50" height="6" rx="2" fill="#5E6B78"/>'
    out.append(bin_)
    if kind == 'tag':
        out.append(pliers(86, 182, 0, 1.15, crack=True))
        out.append(red_tag(58, 160, 1.0))
        out.append(hand(30, 140, 40, 0.8))
    elif kind == 'unusable':
        out.append(pliers(96, 186, 0, 1.15, crack=True, cut=True))
        out.append(hacksaw(70, 156, 16, 0.9))
        out.append(hand(28, 140, 20, 0.8))
        out.append(red_tag(170, 170, 0.7))
    elif kind == 'tape':
        out.append(pliers(110, 170, 10, 1.3, crack=True, tape=True))
        out.append(hand(52, 152, 20, 0.9, grip=False))
        out.append(f'<circle cx="160" cy="194" r="11" fill="{INK}"/><circle cx="160" cy="194" r="5" fill="#7C5531"/>')
    elif kind == 'wide_jaw':
        out.append(nut)
        out.append(spanner(106, 116, 0, 1.0, wide=True))
        out.append(hand(64, 116, 0, 0.9))
        out.append('<g stroke="#FFFFFF" stroke-width="1.8" stroke-linecap="round" opacity="0.9"><path d="M156 92 l8 -6"/><path d="M160 100 l10 -3"/></g>')
    elif kind == 'bent_tip':
        out.append(nut)
        out.append(screwdriver(104, 110, -4, 1.1, bent=True))
        out.append(hand(52, 112, -4, 0.9))
    elif kind == 'hyd_leak':
        out.append(crimper(110, 150, -10, 1.2, leak=True))
        out.append(f'<ellipse cx="120" cy="196" rx="22" ry="4" fill="{OIL}" opacity="0.8"/>')
        out.append(hand(40, 160, -10, 0.85))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — up the pole: a tool bag, not a toolbox.
# --------------------------------------------------------------------------

GY = sb.GY


def pole_stage():
    out = card_open('sky')
    out.append(sb.cloud(40, 30, 0.9, '#FFFFFF', 0.85))
    out.append(f'<rect x="0" y="{GY}" width="200" height="{H - GY}" fill="url(#ground)"/>')
    out.append(sb.pole_and_line())
    out.append(sb.ladder_svg(sb.LAD_FOOT, sb.LAD_TOP))
    return out


def harness_on(hip, sh):
    """Full-body harness straps over the torso and a lanyard round the pole."""
    hx, hy = hip
    sx, sy = sh
    return (f'<path d="M{f(sx - 4)} {f(sy)} L{f(hx - 4)} {f(hy - 2)} M{f(sx + 3)} {f(sy)} L{f(hx + 4)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2" fill="none"/>'
            f'<path d="M{f(hx - 7)} {f(hy - 2)} L{f(hx + 7)} {f(hy - 2)}" stroke="{HARNESS}" stroke-width="2.4"/>'
            f'<path d="M{f((sx + hx) / 2 - 5)} {f((sy + hy) / 2)} L{f((sx + hx) / 2 + 5)} {f((sy + hy) / 2)}" stroke="{HARNESS}" stroke-width="1.6"/>')


def lanyard(hip):
    hx, hy = hip
    px = sb.PX - sb.PW / 2
    return (f'<path d="M{f(hx + 4)} {f(hy - 2)} Q{f((hx + px) / 2)} {f(hy + 6)} {f(px)} {f(hy - 6)}" stroke="{HARNESS}" stroke-width="1.6" fill="none"/>'
            f'<path d="M{f(px)} {f(hy - 6)} L{f(px + sb.PW)} {f(hy - 6)}" stroke="{HARNESS}" stroke-width="1.6"/>')


def climber(t, props_front='', hands=None, hands_t=(0.24, 0.3), up=False, look=0, belt_bag=False, tucked=False):
    fa = sb.lad(t)
    hip = (fa[0] + 4 - 9, fa[1] - 1 - 26)
    sh = (hip[0] + 5, hip[1] - 25)
    s = sb.on_ladder(t, hands_t=hands_t, hands=hands, up=up, look=look, props_front=props_front)
    s += harness_on(hip, sh)
    if t > 0.3:
        s += lanyard(hip)
    if belt_bag:
        s += sb.bag(hip[0] - 4, hip[1] + 6, 0.8)
    if tucked:
        s += spanner(hip[0] - 6, hip[1] - 1, 70, 0.32) + screwdriver(hip[0] + 2, hip[1] - 2, 100, 0.3)
    return s, hip


def ground_bag():
    return sb.bag(70, GY + 6, 0.9)


def falling(x, y):
    return (spanner(x, y, 50, 0.32)
            + f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9"><path d="M{f(x - 4)} {f(y - 18)} l0 9"/><path d="M{f(x + 3)} {f(y - 22)} l0 11"/></g>')


def bag_card(kind):
    out = pole_stage()
    if kind == 'belt':
        s, _ = climber(0.45, belt_bag=True)
        out.append(s)
    elif kind == 'ground':
        x = 74
        out.append(sb.standing(x, face=1, hands=((x - 2, GY - 28), (x + 8, GY - 30)), look=14))
        out.append(harness_on((x, GY - 30), (x + 1, GY - 56)))
        out.append(sb.bag(x + 6, GY - 22, 0.8))
    elif kind == 'toolbox':
        out.append(ground_bag())
        fa = sb.lad(0.18)
        hip = (fa[0] - 5, fa[1] - 27)
        box = g(hip[0] - 12, hip[1] + 18, 0, 0.32, '<rect x="-42" y="-30" width="84" height="40" rx="4" fill="url(#box)"/><rect x="-12" y="-20" width="24" height="5" rx="2" fill="#163A57"/>'
                '<path d="M-14 -30 Q0 -44 14 -30" stroke="#163A57" stroke-width="4" fill="none"/>')
        s, _ = climber(0.18, hands=((sb.lad(0.42)[0] + 1, sb.lad(0.42)[1]), (hip[0] - 12, hip[1] + 8)), up=True, look=-10)
        out.append(s + box)
    elif kind == 'in_hand':
        out.append(ground_bag())
        s, _ = climber(0.2, props_front=spanner(sb.lad(0.5)[0] + 3, sb.lad(0.5)[1], -60, 0.5), hands_t=(0.24, 0.3), up=True)
        out.append(s)
    elif kind == 'loose_arm':
        out.append(ground_bag())
        s, hip = climber(0.6, hands=((sb.lad(0.85)[0] + 2, sb.lad(0.85)[1]), (sb.INS_NEAR[0] + 2, sb.INS_NEAR[1] - 10)))
        out.append(s)
        out.append(spanner(124, sb.ARM_Y - 1, 0, 0.32) + pliers(176, sb.ARM_Y - 4, 180, 0.3))
        out.append(falling(118, 120))
    elif kind == 'tucked':
        out.append(ground_bag())
        s, hip = climber(0.6, hands=((sb.lad(0.85)[0] + 2, sb.lad(0.85)[1]), (sb.INS_NEAR[0] + 2, sb.INS_NEAR[1] - 10)), tucked=True)
        out.append(s)
        out.append(falling(hip[0] - 14, hip[1] + 46))
    return card_close(out)


CARDS = {
    'daily_wipe': daily_card('wipe'),
    'daily_place': daily_card('place'),
    'daily_wet': daily_card('wet'),
    'daily_heap': daily_card('heap'),
    'daily_greasy': daily_card('greasy'),
    'daily_unchecked': daily_card('unchecked'),
    'rust_oil': rust_card('oil'),
    'rust_brush': rust_card('brush'),
    'rust_oil_handle': rust_card('oil_handle'),
    'rust_damp': rust_card('damp'),
    'rust_slip': rust_card('slip'),
    'rust_grease': rust_card('grease'),
    'meter_coil': meter_card('coil'),
    'meter_battery': meter_card('battery'),
    'meter_on': meter_card('on'),
    'meter_tight': meter_card('tight'),
    'meter_leak': meter_card('leak'),
    'retire_tag': retire_card('tag'),
    'retire_unusable': retire_card('unusable'),
    'retire_tape': retire_card('tape'),
    'retire_wide_jaw': retire_card('wide_jaw'),
    'retire_bent_tip': retire_card('bent_tip'),
    'retire_hyd_leak': retire_card('hyd_leak'),
    'bag_belt': bag_card('belt'),
    'bag_ground': bag_card('ground'),
    'bag_toolbox': bag_card('toolbox'),
    'bag_in_hand': bag_card('in_hand'),
    'bag_loose_arm': bag_card('loose_arm'),
    'bag_tucked': bag_card('tucked'),
}

# Safe cards and traps per round (mirrors learn_board_pack210.dart).
ROUNDS = {
    'daily': (['daily_wipe', 'daily_place'], ['daily_wet', 'daily_heap', 'daily_greasy', 'daily_unchecked']),
    'rust': (['rust_oil', 'rust_brush'], ['rust_oil_handle', 'rust_damp', 'rust_slip', 'rust_grease']),
    'meter': (['meter_coil', 'meter_battery'], ['meter_on', 'meter_tight', 'meter_leak']),
    'retire': (['retire_tag', 'retire_unusable'], ['retire_tape', 'retire_wide_jaw', 'retire_bent_tip', 'retire_hyd_leak']),
    'bag': (['bag_belt', 'bag_ground'], ['bag_toolbox', 'bag_in_hand', 'bag_loose_arm', 'bag_tucked']),
}
HAND = 4
LOW = {'bag_ground', 'bag_toolbox', 'bag_in_hand'}

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand_ in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand_}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand_}')
                only = tok[s] - set().union(*(tok[t] for t in hand_))
                if only:
                    problems.append(f'{rnd}: {s} with {hand_} draws {sorted(only)} alone')
                if s in LOW and not any(t in LOW for t in hand_):
                    problems.append(f'{rnd}: {s} is the only low figure with {hand_}')
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
