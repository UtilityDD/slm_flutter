"""Picture cards for the lesson 2.3 Learn board (ল্যাগস ক্রিম্পিং: সঠিক চাপ, নিরাপদ কানেকশন).

python -I tool/m2_board23_art.py .

Writes assets/game/art/m2_board23/*.svg in the same clean gradient style as
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art. Every card is a close-up on the work bench: the player's own hand
holds the cable on the left, the lug sits on the right.

What the cards show comes from lesson 2.3 only:
  1. match: wire size = lug size; aluminium wire -> aluminium lug, copper
     wire -> copper lug (two metals together -> galvanic corrosion); a wrong
     size is too loose or too tight;
  2. tool: hand crimper for small wire, hydraulic crimper for big cable, the
     die must match wire and lug; ordinary pliers cannot crimp (myth 2);
  3. prep (golden rules 1-2 + safety tip): strip to the right length so the
     conductor goes fully into the barrel and the insulation stays outside;
     brush the conductor clean; oil/dirt raises resistance; power off first;
  4. press (golden rule 3 + pro tip 2): die on the right place of the barrel,
     full cycle until the tool releases itself; half pressure is weak;
  5. check (golden rule 4 + good vs bad): smooth hexagonal crimp, pull test;
     under-crimp, over-crimp (cracked lug), wrong shape, strands outside.

Fairness (playbook section 4): one backdrop, one bench, one hand and one cable
on every card; every colour or gradient a safe card draws is drawn by a trap
in every hand the dealer can make (one safe + three traps). Checked below.
"""

import itertools
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board23_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board23')
W, H = 200, 220

SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
SLEEVE = '#1F5F8F'
INK = '#000000'
WHITE = '#FFFFFF'
LAMP_OFF = '#3A4048'
LAMP_ON = '#FF4A3D'
OIL = '#2B2216'

DEFS = """<defs>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#34414D"/><stop offset="0.62" stop-color="#26313B"/><stop offset="1" stop-color="#1C252D"/></linearGradient>
  <linearGradient id="mat" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3E6B5A"/><stop offset="1" stop-color="#2C5144"/></linearGradient>
  <linearGradient id="al" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F2F5F7"/><stop offset="0.45" stop-color="#C5CCD2"/><stop offset="1" stop-color="#8B949C"/></linearGradient>
  <linearGradient id="cu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F6C29A"/><stop offset="0.45" stop-color="#D9824B"/><stop offset="1" stop-color="#9A5228"/></linearGradient>
  <linearGradient id="ins" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4A5058"/><stop offset="0.4" stop-color="#2A2E34"/><stop offset="1" stop-color="#15181C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E4E9ED"/><stop offset="0.45" stop-color="#9AA4AC"/><stop offset="1" stop-color="#5D666E"/></linearGradient>
  <linearGradient id="grip" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#B8302A"/><stop offset="0.5" stop-color="#E5483E"/><stop offset="1" stop-color="#9E2722"/></linearGradient>
  <linearGradient id="skin" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C08058"/><stop offset="1" stop-color="#8C5A3A"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

CY = 104      # cable axis
LX = 92       # lug barrel start
LL = 46       # barrel length


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


ZOOM = '<g transform="translate(-32 -24) scale(1.25)">'


def card_open(pre=''):
    """The backdrop, the bench mat, then the close-up (drawn at 1.25x)."""
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#bench)"/>',
            # the rubber mat on the bench, the same on every card
            '<path d="M-10 150 L210 136 L210 230 L-10 230 Z" fill="url(#mat)"/>',
            f'<path d="M-10 150 L210 136" stroke="{WHITE}" stroke-opacity="0.18" stroke-width="1.5"/>',
            f'<ellipse cx="110" cy="{CY + 34}" rx="92" ry="8" fill="{INK}" opacity="0.22"/>', pre, ZOOM]


def card_close(out):
    out.append('</g>')  # the close-up
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# Pieces
# --------------------------------------------------------------------------

def strands(x0, x1, r, metal, cy=CY, oily=False):
    """The bare stranded conductor from x0 to x1, radius r."""
    out = [f'<rect x="{f(x0)}" y="{f(cy - r)}" width="{f(x1 - x0)}" height="{f(2 * r)}" rx="{f(min(r, 3))}" fill="url(#{metal})"/>']
    step = 4.5
    x = x0 + 2
    lines = []
    while x < x1 - 2:
        lines.append(f'M{f(x)} {f(cy - r + 0.8)} L{f(min(x + r * 0.9, x1 - 1))} {f(cy + r - 0.8)}')
        x += step
    if lines:
        out.append(f'<path d="{" ".join(lines)}" stroke="{INK}" stroke-opacity="0.22" stroke-width="0.9" fill="none"/>')
    if oily:
        out.append(f'<g fill="{OIL}" opacity="0.85"><ellipse cx="{f(x0 + (x1 - x0) * 0.35)}" cy="{f(cy - r * 0.2)}" rx="{f(r * 0.9)}" ry="{f(r * 0.7)}"/>'
                   f'<ellipse cx="{f(x0 + (x1 - x0) * 0.7)}" cy="{f(cy + r * 0.3)}" rx="{f(r * 0.7)}" ry="{f(r * 0.6)}"/>'
                   f'<path d="M{f(x0 + (x1 - x0) * 0.5)} {f(cy + r)} q2 7 0 11 q-2 -4 0 -11 Z"/></g>')
    return ''.join(out)


def cable(x_end, r, metal, strip=14, cy=CY, oily=False):
    """Insulated cable from the left edge; insulation ends at x_end, then
    `strip` px of bare conductor."""
    t = 3.2
    ins = (f'<rect x="-6" y="{f(cy - r - t)}" width="{f(x_end + 6)}" height="{f(2 * (r + t))}" rx="3" fill="url(#ins)"/>'
           f'<path d="M-6 {f(cy - r - t + 1.6)} L{f(x_end - 2)} {f(cy - r - t + 1.6)}" stroke="{WHITE}" stroke-opacity="0.16" stroke-width="1.4"/>')
    bare = strands(x_end - 1, x_end + strip, r, metal, cy, oily) if strip > 0 else ''
    return bare + ins


def hand(x=30, cy=CY, r=7):
    """The player's left hand gripping the cable, sleeve to the bottom-left."""
    t = r + 3.2
    return (f'<path d="M{f(x - 24)} 232 C{f(x - 22)} 190 {f(x - 12)} {f(cy + t + 16)} {f(x - 6)} {f(cy + t + 4)} L{f(x + 16)} {f(cy + t + 8)} '
            f'C{f(x + 12)} {f(cy + t + 30)} {f(x + 6)} 200 {f(x + 8)} 232 Z" fill="{SLEEVE}"/>'
            f'<rect x="{f(x - 9)}" y="{f(cy - t - 5)}" width="27" height="{f(2 * t + 14)}" rx="9" fill="url(#skin)"/>'
            f'<path d="M{f(x - 6)} {f(cy - t + 1)} h21 M{f(x - 6)} {f(cy - 1)} h21 M{f(x - 6)} {f(cy + t - 2)} h21" stroke="{INK}" stroke-opacity="0.22" stroke-width="1.1"/>'
            f'<ellipse cx="{f(x + 15)}" cy="{f(cy - t - 2)}" rx="8" ry="4.5" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.8"/>')


def lug(x0, br, metal, cy=CY, cut=None, band=None, length=LL):
    """A lug: barrel [x0, x0+length] of outer radius br, then the palm with
    its hole. `cut` = draw the barrel cut open (inner window) and return the
    inner radius; `band` = (x, w, kind) a crimp band on the barrel."""
    pr = max(br + 4, 11)
    px0 = x0 + length
    out = [
        # taper and palm
        f'<path d="M{f(px0 - 1)} {f(cy - br)} L{f(px0 + 8)} {f(cy - pr * 0.55)} L{f(px0 + 8)} {f(cy + pr * 0.55)} L{f(px0 - 1)} {f(cy + br)} Z" fill="url(#{metal})"/>',
        f'<rect x="{f(px0 + 6)}" y="{f(cy - pr)}" width="{f(2 * pr + 8)}" height="{f(2 * pr)}" rx="{f(pr)}" fill="url(#{metal})"/>',
        f'<circle cx="{f(px0 + 6 + pr + 4)}" cy="{f(cy)}" r="{f(pr * 0.45)}" fill="{INK}" fill-opacity="0.55"/>',
        f'<rect x="{f(x0)}" y="{f(cy - br)}" width="{f(length)}" height="{f(2 * br)}" rx="2.5" fill="url(#{metal})"/>',
        f'<path d="M{f(x0 + 2)} {f(cy - br + 1.6)} L{f(px0 - 2)} {f(cy - br + 1.6)}" stroke="{WHITE}" stroke-opacity="0.45" stroke-width="1.3"/>',
        # barrel mouth
        f'<ellipse cx="{f(x0)}" cy="{f(cy)}" rx="2.4" ry="{f(br)}" fill="url(#{metal})" stroke="{INK}" stroke-opacity="0.3" stroke-width="0.8"/>',
    ]
    if cut:
        ir = br - 2.4
        out.append(f'<rect x="{f(x0 + 2)}" y="{f(cy - ir)}" width="{f(length - 5)}" height="{f(2 * ir)}" rx="1.5" fill="{INK}" fill-opacity="0.55"/>')
    if band:
        bx, bw, kind = band
        out.append(crimp_band(bx, bw, br, cy, kind))
    return ''.join(out)


def crimp_band(bx, bw, br, cy, kind):
    """A hexagonal crimp band seen from the side: flat facets with clear die
    edges. kind: good / faint / crack / skew."""
    if kind == 'faint':
        return (f'<rect x="{f(bx)}" y="{f(cy - br + 0.6)}" width="{f(bw)}" height="{f(2 * br - 1.2)}" fill="{INK}" fill-opacity="0.07"/>'
                f'<path d="M{f(bx)} {f(cy - br + 1)} v{f(2 * br - 2)} M{f(bx + bw)} {f(cy - br + 1)} v{f(2 * br - 2)}" stroke="{INK}" stroke-opacity="0.12" stroke-width="0.8"/>')
    d = 1.6 if kind != 'crack' else 3.2
    top, bot = cy - br + d, cy + br - d
    face = (f'<rect x="{f(bx)}" y="{f(top)}" width="{f(bw)}" height="{f(bot - top)}" fill="{INK}" fill-opacity="0.1"/>'
            f'<rect x="{f(bx)}" y="{f(top)}" width="{f(bw)}" height="{f((bot - top) * 0.28)}" fill="{WHITE}" fill-opacity="0.32"/>'
            f'<rect x="{f(bx)}" y="{f(bot - (bot - top) * 0.28)}" width="{f(bw)}" height="{f((bot - top) * 0.28)}" fill="{INK}" fill-opacity="0.2"/>'
            f'<path d="M{f(bx)} {f(top)} v{f(bot - top)} M{f(bx + bw)} {f(top)} v{f(bot - top)}" stroke="{INK}" stroke-opacity="0.38" stroke-width="1"/>'
            f'<path d="M{f(bx + 3)} {f(cy)} h{f(bw - 6)}" stroke="{INK}" stroke-opacity="0.18" stroke-width="0.8"/>')
    if kind == 'crack':
        # squeezed too hard: flash ears and a split in the barrel wall
        face += (f'<path d="M{f(bx + 2)} {f(cy - br)} l{f(bw / 2 - 2)} -4 l{f(bw / 2 - 2)} 4 Z" fill="{INK}" fill-opacity="0.25"/>'
                 f'<path d="M{f(bx + bw * 0.3)} {f(top)} l4 5 l-3 4 l5 5 l-3 4 l4 5" stroke="{INK}" stroke-opacity="0.85" stroke-width="1.6" fill="none"/>')
    if kind == 'skew':
        face = (f'<path d="M{f(bx)} {f(top + 4)} L{f(bx + bw)} {f(top - 1)} L{f(bx + bw + 4)} {f(bot - 2)} L{f(bx + 3)} {f(bot + 2)} Z" fill="{INK}" fill-opacity="0.22"/>'
                f'<path d="M{f(bx)} {f(top + 4)} L{f(bx + bw)} {f(top - 1)}" stroke="{WHITE}" stroke-opacity="0.32" stroke-width="2"/>'
                f'<path d="M{f(bx + 6)} {f(top + 2)} L{f(bx + 10)} {f(bot)}" stroke="{INK}" stroke-opacity="0.38" stroke-width="1"/>')
    return face


def handles(px, py, spread, length=86, tip=None):
    """Two crimper/pliers handles from the pivot (px, py) towards the bottom;
    spread = half-angle offset in px at the far end."""
    ex = px + 14
    out = []
    for s in (-1, 1):
        x1, y1 = ex + s * spread, py + length
        out.append(f'<path d="M{f(px + s * 2.5)} {f(py)} L{f(x1)} {f(y1)}" stroke="url(#steel)" stroke-width="5" stroke-linecap="round"/>')
        gx0, gy0 = px + (x1 - px) * 0.38, py + length * 0.38
        out.append(f'<path d="M{f(gx0)} {f(gy0)} L{f(x1)} {f(y1)}" stroke="url(#grip)" stroke-width="9" stroke-linecap="round"/>')
    out.append(f'<circle cx="{f(px)}" cy="{f(py)}" r="4" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>')
    return ''.join(out)


def crimper(cx, br, gap=0.0, die_w=20, die_off=0.0, spread=6, cy=CY):
    """A hand ratchet crimper from below: frame behind the barrel, upper and
    lower die blocks on the barrel at cx; gap = how far the dies stand off the
    barrel (half pressure), die_off = extra die opening (die too big)."""
    top = cy - br - 14 - gap - die_off
    bot = cy + br + gap + die_off
    piv = (cx, cy + br + 30)
    frame = (f'<path d="M{f(cx + die_w / 2 - 2)} {f(top + 2)} C{f(cx + die_w / 2 + 16)} {f(top + 6)} {f(cx + die_w / 2 + 16)} {f(piv[1] - 8)} {f(piv[0] + 4)} {f(piv[1])}" '
             f'stroke="url(#steel)" stroke-width="9" fill="none" stroke-linecap="round"/>')
    return frame, (
        f'<rect x="{f(cx - die_w / 2)}" y="{f(top)}" width="{f(die_w)}" height="14" rx="2" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>'
        f'<rect x="{f(cx - die_w / 2)}" y="{f(bot)}" width="{f(die_w)}" height="12" rx="2" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>'
        f'<path d="M{f(cx)} {f(bot + 12)} L{f(piv[0])} {f(piv[1])}" stroke="url(#steel)" stroke-width="7"/>'
        + handles(piv[0], piv[1], spread, length=82))


def hydraulic(cx, br, gap=0.0, die_w=26, cy=CY, pinch=0.0):
    """A hydraulic crimper: a C-head over the barrel, the ram die from below,
    the cylinder body down to the bench and a red pump handle."""
    head_top = cy - br - 16
    ram = cy + br + gap - pinch
    back = (f'<path d="M{f(cx - die_w / 2 - 6)} {f(head_top)} h{f(die_w + 12)} v16 h-6 v-6 h{f(-die_w)} v6 h-6 Z" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>'
            f'<path d="M{f(cx + die_w / 2 + 6)} {f(head_top + 6)} C{f(cx + die_w / 2 + 22)} {f(head_top + 10)} {f(cx + die_w / 2 + 22)} {f(cy + br + 30)} {f(cx + 8)} {f(cy + br + 34)}" stroke="url(#steel)" stroke-width="10" fill="none"/>')
    front = (f'<rect x="{f(cx - die_w / 2)}" y="{f(ram)}" width="{f(die_w)}" height="10" rx="2" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>'
             f'<rect x="{f(cx - 5)}" y="{f(ram + 10)}" width="10" height="{f(cy + br + 34 - ram - 10 + 4)}" fill="url(#steel)"/>'
             f'<rect x="{f(cx - 15)}" y="{f(cy + br + 34)}" width="30" height="70" rx="6" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.3" stroke-width="0.8"/>'
             f'<rect x="{f(cx - 15)}" y="{f(cy + br + 58)}" width="30" height="9" fill="url(#grip)"/>'
             f'<path d="M{f(cx + 13)} {f(cy + br + 44)} L{f(cx + 58)} {f(cy + br + 102)}" stroke="url(#steel)" stroke-width="5" stroke-linecap="round"/>'
             f'<path d="M{f(cx + 32)} {f(cy + br + 68)} L{f(cx + 58)} {f(cy + br + 102)}" stroke="url(#grip)" stroke-width="9" stroke-linecap="round"/>')
    return back, front


def pliers(cx, br, cy=CY):
    """Ordinary combination pliers biting the barrel with their tips."""
    piv = (cx + 4, cy + br + 18)
    jaws = (f'<path d="M{f(piv[0] - 3)} {f(piv[1])} L{f(cx - 6)} {f(cy - br - 2)} L{f(cx + 2)} {f(cy - br - 6)} L{f(piv[0] + 3)} {f(piv[1] - 4)} Z" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>'
            f'<path d="M{f(piv[0] - 4)} {f(piv[1] - 2)} L{f(cx + 8)} {f(cy + br - 1)} L{f(cx + 14)} {f(cy + br + 4)} L{f(piv[0] + 4)} {f(piv[1] + 2)} Z" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="0.8"/>')
    return jaws + handles(piv[0], piv[1], 13, length=84)


def brush(x, cy, r):
    """A wire brush scrubbing the bare conductor."""
    return (f'<g transform="rotate(-8 {f(x)} {f(cy - r - 8)})">'
            f'<rect x="{f(x - 14)}" y="{f(cy - r - 13)}" width="28" height="9" rx="2" fill="url(#steel)"/>'
            f'<path d="{" ".join(f"M{f(x - 12 + i * 3)} {f(cy - r - 4)} v4" for i in range(9))}" stroke="url(#steel)" stroke-width="1.2"/>'
            f'<path d="M{f(x + 12)} {f(cy - r - 10)} L{f(x + 52)} {f(cy - r - 26)}" stroke="url(#grip)" stroke-width="8" stroke-linecap="round"/></g>'
            f'<path d="M{f(x - 22)} {f(cy - r - 20)} l-6 0 M{f(x + 4)} {f(cy - r - 26)} l6 -2" stroke="{WHITE}" stroke-opacity="0.6" stroke-width="1.4" stroke-linecap="round"/>')


def panel(live=False):
    """The distribution box this cable belongs to, top right: switch down and
    lamp dark (power off), or switch up and lamp lit (live)."""
    lamp = LAMP_ON if live else LAMP_OFF
    lever_y = 20 if live else 36
    glow = (f'<circle cx="178" cy="22" r="12" fill="{LAMP_ON}" opacity="0.35"/>' if live else '')
    return (f'<rect x="150" y="8" width="44" height="54" rx="4" fill="url(#steel)" stroke="{INK}" stroke-opacity="0.35" stroke-width="1"/>'
            f'<rect x="156" y="16" width="14" height="34" rx="2" fill="{INK}" fill-opacity="0.45"/>'
            f'<rect x="157.5" y="{lever_y}" width="11" height="12" rx="2" fill="url(#grip)"/>'
            + glow + f'<circle cx="178" cy="22" r="4.5" fill="{lamp}"/>'
            f'<path d="M172 62 C172 80 150 76 146 90" stroke="url(#ins)" stroke-width="5" fill="none"/>')


def arrows(x, y, d):
    """Two white pull arrows pointing apart (d = +1 out to the right)."""
    return (f'<path d="M{f(x)} {f(y)} h{f(16 * d)} m{f(-5 * d)} -5 l{f(5 * d)} 5 l{f(-5 * d)} 5" stroke="{WHITE}" stroke-opacity="0.85" '
            f'stroke-width="2.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')


def hand_right(x, cy, pr):
    """The other hand pinching the lug's palm for the pull test."""
    return (f'<path d="M{f(x + 30)} 232 C{f(x + 30)} 190 {f(x + 18)} {f(cy + pr + 20)} {f(x + 10)} {f(cy + pr + 6)} L{f(x - 10)} {f(cy + pr + 10)} '
            f'C{f(x - 8)} {f(cy + pr + 30)} {f(x)} 200 {f(x - 4)} 232 Z" fill="{SLEEVE}"/>'
            f'<rect x="{f(x - 12)}" y="{f(cy - pr - 6)}" width="24" height="{f(2 * pr + 16)}" rx="9" fill="url(#skin)"/>'
            f'<path d="M{f(x - 9)} {f(cy - pr + 2)} h18 M{f(x - 9)} {f(cy)} h18 M{f(x - 9)} {f(cy + pr - 2)} h18" stroke="{INK}" stroke-opacity="0.22" stroke-width="1.1"/>'
            f'<ellipse cx="{f(x - 12)}" cy="{f(cy - pr - 3)}" rx="7" ry="4.5" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.8"/>')


# --------------------------------------------------------------------------
# Round 1 — match the wire, the lug and the metal.
# --------------------------------------------------------------------------

def match_card(wire, lugm, r=6.5, br=8.5):
    """The stripped wire about to go into the lug's barrel."""
    out = card_open()
    out.append(lug(LX - 2, br, lugm))
    out.append(cable(66, r, wire, strip=26))
    out.append(hand(30, r=r))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — the crimping tool and its die.
# --------------------------------------------------------------------------

SMALL = (6.0, 8.0)     # conductor radius, barrel radius
BIG = (11.0, 13.5)


def tool_card(kind):
    out = card_open()
    size = BIG if kind in ('hydraulic', 'hand_big', 'die_small') else SMALL
    r, br = size
    cx = LX + 22
    front = ''
    if kind in ('hand', 'die_big', 'hand_big'):
        die_w = 20
        gap, off, spread = 0.0, 0.0, 6
        if kind == 'die_big':
            off = 5.0          # the die bigger than the lug: it never grips
        if kind == 'hand_big':
            die_w, gap, spread = 14, 4.0, 22    # small jaws can't close round a big cable
        back, front = crimper(cx, br, gap=gap, die_w=die_w, die_off=off, spread=spread)
        out.append(back)
    elif kind in ('hydraulic', 'die_small'):
        back, front = hydraulic(cx, br, die_w=16 if kind == 'die_small' else 26, pinch=4.5 if kind == 'die_small' else 0.0)
        out.append(back)
    out.append(lug(LX, br, 'al'))
    out.append(cable(LX - 2, r, 'al', strip=3))
    out.append(hand(30, r=r))
    if kind == 'pliers':
        out.append(pliers(cx, br))
    else:
        out.append(front)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — preparing the end: strip, clean, power off, insert.
# --------------------------------------------------------------------------

def prep_card(kind):
    out = card_open(panel(live=(kind == 'live')))
    r, br = SMALL
    if kind == 'brush':
        # stripped and being brushed, the lug waits beside
        out.append(lug(LX + 18, br, 'cu', cut=True))
        out.append(cable(56, r, 'cu', strip=28))
        out.append(brush(72, CY, r))
        out.append(hand(30, r=r))
        return card_close(out)
    out.append(lug(LX, br, 'cu', cut=True))
    ir = br - 2.4
    if kind in ('ok', 'live', 'oily'):
        # insulation stops at the mouth, the conductor fills the barrel
        out.append(strands(LX - 3, LX + LL - 5, ir, 'cu', oily=(kind == 'oily')))
        out.append(cable(LX - 3, r, 'cu', strip=0))
    elif kind == 'half':
        out.append(strands(LX - 6, LX + 18, ir, 'cu'))
        out.append(cable(LX - 6, r, 'cu', strip=0))
    elif kind == 'ins_in':
        # stripped too short: the insulation goes into the barrel
        out.append(strands(LX + 12, LX + LL - 5, ir, 'cu'))
        out.append(f'<rect x="{f(LX - 2)}" y="{f(CY - ir)}" width="16" height="{f(2 * ir)}" rx="1.5" fill="url(#ins)"/>')
        out.append(cable(LX - 1, r, 'cu', strip=0))
    out.append(hand(30, r=r))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — the press: die on the barrel, full cycle.
# --------------------------------------------------------------------------

def press_card(kind):
    out = card_open()
    r, br = SMALL if kind in ('full', 'half', 'palm') else BIG
    cx = LX + 22
    if kind == 'palm':
        cx = LX + LL + 22      # dies on the flat palm, not the barrel
    if kind == 'edge':
        cx = LX + 2            # dies half off the barrel's mouth
    if kind in ('full', 'half', 'palm'):
        gap = 5.0 if kind == 'half' else 0.0
        back, front = crimper(cx, br, gap=gap, spread=24 if kind == 'half' else 5)
    else:
        gap = 6.0 if kind == 'hyd_half' else 0.0
        back, front = hydraulic(cx, br, gap=gap)
    out.append(back)
    out.append(lug(LX, br, 'al'))
    out.append(cable(LX - 2, r, 'al', strip=3))
    out.append(hand(30, r=r))
    out.append(front)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — the finished crimp: inspect and pull.
# --------------------------------------------------------------------------

def check_card(kind):
    out = card_open()
    r, br = 7.5, 10.0
    x0 = LX - 6
    band = (x0 + 14, 18, {'under': 'faint', 'crack': 'crack', 'shape': 'skew'}.get(kind, 'good'))
    out.append(lug(x0, br, 'cu', band=band))
    if kind == 'under':
        # it slides out on the pull: a gap of bare strands at the mouth
        out.append(cable(x0 - 14, r, 'cu', strip=13))
        out.append(arrows(44, CY - 26, -1))
    elif kind == 'strands':
        out.append(cable(x0 - 2, r, 'cu', strip=2))
        out.append(f'<path d="M{f(x0 - 1)} {f(CY - r + 1)} q-8 -10 -6 -18 M{f(x0 - 1)} {f(CY - r + 3)} q-12 -4 -16 -12 '
                   f'M{f(x0 - 1)} {f(CY + r - 1)} q-9 8 -8 16 M{f(x0)} {f(CY - r + 2)} q2 -12 8 -16" stroke="url(#cu)" stroke-width="2.2" fill="none" stroke-linecap="round"/>')
    else:
        out.append(cable(x0 - 2, r, 'cu', strip=2))
    if kind == 'pull':
        out.append(hand_right(x0 + LL + 30, CY, br + 4))
        out.append(arrows(44, CY - 26, -1))
        out.append(arrows(x0 + LL + 16, CY - 30, 1))
    out.append(hand(30, r=r))
    return card_close(out)


CARDS = {
    # Round 1 — the perfect match.
    'match_al_al': match_card('al', 'al'),
    'match_cu_cu': match_card('cu', 'cu'),
    'match_al_cu': match_card('al', 'cu'),
    'match_cu_al': match_card('cu', 'al'),
    'match_thin': match_card('cu', 'cu', r=3.2, br=11.5),
    'match_fat': match_card('al', 'al', r=11.0, br=7.0),
    # Round 2 — the tool and the die.
    'tool_hand': tool_card('hand'),
    'tool_hydraulic': tool_card('hydraulic'),
    'tool_pliers': tool_card('pliers'),
    'tool_hand_big': tool_card('hand_big'),
    'tool_die_big': tool_card('die_big'),
    'tool_die_small': tool_card('die_small'),
    # Round 3 — preparing the end.
    'prep_ok': prep_card('ok'),
    'prep_brush': prep_card('brush'),
    'prep_half': prep_card('half'),
    'prep_ins_in': prep_card('ins_in'),
    'prep_oily': prep_card('oily'),
    'prep_live': prep_card('live'),
    # Round 4 — the press.
    'press_full': press_card('full'),
    'press_hyd_full': press_card('hyd_full'),
    'press_half': press_card('half'),
    'press_hyd_half': press_card('hyd_half'),
    'press_palm': press_card('palm'),
    'press_edge': press_card('edge'),
    # Round 5 — inspect the finished crimp.
    'check_hex': check_card('hex'),
    'check_pull': check_card('pull'),
    'check_under': check_card('under'),
    'check_crack': check_card('crack'),
    'check_shape': check_card('shape'),
    'check_strands': check_card('strands'),
}

# Safe cards and traps per round (mirrors learn_board_pack23.dart).
ROUNDS = {
    'match': (['match_al_al', 'match_cu_cu'], ['match_al_cu', 'match_cu_al', 'match_thin', 'match_fat']),
    'tool': (['tool_hand', 'tool_hydraulic'], ['tool_pliers', 'tool_hand_big', 'tool_die_big', 'tool_die_small']),
    'prep': (['prep_ok', 'prep_brush'], ['prep_half', 'prep_ins_in', 'prep_oily', 'prep_live']),
    'press': (['press_full', 'press_hyd_full'], ['press_half', 'press_hyd_half', 'press_palm', 'press_edge']),
    'check': (['check_hex', 'check_pull'], ['check_under', 'check_crack', 'check_shape', 'check_strands']),
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
            for hand_ in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand_}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand_}')
                only = tok[s] - set().union(*(tok[t] for t in hand_))
                if only:
                    problems.append(f'{rnd}: {s} with {hand_} draws {sorted(only)} alone')
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
