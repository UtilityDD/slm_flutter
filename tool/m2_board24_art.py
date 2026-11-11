"""Picture cards for the lesson 2.4 শেখা board (কাম-অ্যালং ক্ল্যাম্প: নিয়ন্ত্রিত শক্তি).

python -I tool/m2_board24_art.py .

Writes assets/game/art/m2_board24/*.svg in the clean gradient style of
tool/storm_board_art.py (200 x 220 scene cards, drawn edge to edge, no words).

What the cards show comes from lesson 2.4 only:
  1. check: before use, check the ratchet, hook, safety latch and cable; the
     wire grip's jaws/teeth clean and sharp; oil or dirt on the teeth -> slip;
  2. rig: the fixed end on a very strong, reliable anchor (the pole strap or
     the cross-arm's root); the grip seated evenly and firmly on the
     conductor; the hook into the grip's eye-bolt;
  3. stand: never in front of or behind the line of pull — always beside it
     (a hook or grip failure is a sling-shot);
  4. pull: slow, controlled lever strokes, the ratchet locked after every
     stroke; no extra pipe on the handle for leverage; no jerks;
  5. release: the most dangerous step — slowly, controlled; never let the
     whole load go at once; know the release before the job.

Rounds 3-5 are drawn from above (the line of pull runs across the card) so
"beside the line" and "in line" can be told apart. Round 2 is a side view of
the rig on the pole, with no one on it. Round 1 is a close-up of the tools.

Fairness (playbook section 4): in every hand the dealer can make (one safe
card + any three traps) each colour or gradient on the safe card is drawn by a
trap too, and the safe card's backdrop is a trap's backdrop.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m2_board24_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm2_board24')
W, H = 200, 220

SHIRT_D = '#174A70'
SKIN = '#A86E48'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
CABLE = '#8E979E'
GRIPRED = '#C2412F'
OIL = '#2E261A'
DARK = '#3C444B'

DEFS = """<defs>
  <linearGradient id="tarp" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3E5A4A"/><stop offset="1" stop-color="#2C4236"/></linearGradient>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2D9"/><stop offset="1" stop-color="#CFE4F2"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B9A983"/><stop offset="1" stop-color="#9C8A64"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9DB07A"/><stop offset="1" stop-color="#7F9460"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E8B84"/><stop offset="0.5" stop-color="#C4C1B9"/><stop offset="1" stop-color="#86837C"/></linearGradient>
  <radialGradient id="poleTop" cx="0.4" cy="0.4" r="0.6"><stop offset="0" stop-color="#D6D3CB"/><stop offset="1" stop-color="#86837C"/></radialGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="body" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F0B43C"/><stop offset="1" stop-color="#C98A1E"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="strap" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E0702C"/><stop offset="1" stop-color="#B4521A"/></linearGradient>
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
# The tools. The puller is drawn with its anchor hook on the right and its
# cable running left to the grip; (ax, y) = the anchor hook's eye.
# --------------------------------------------------------------------------

def hook(x, y, s=1.0, latch=True, flip=False):
    """An open hook hanging off (x, y), mouth to the right (left if flip);
    latch = the spring safety latch closing its mouth."""
    k = -1 if flip else 1
    p = (f'<path d="M{f(x)} {f(y)} l0 {f(6 * s)} q0 {f(8 * s)} {f(7 * s * k)} {f(8 * s)} q{f(6 * s * k)} 0 {f(6 * s * k)} {f(-7 * s)}" '
         f'stroke="url(#steel)" stroke-width="{f(3.2 * s)}" fill="none" stroke-linecap="round"/>'
         f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(3 * s)}" fill="none" stroke="url(#steel)" stroke-width="{f(2 * s)}"/>')
    if latch is True:
        p += f'<path d="M{f(x + 1 * k * s)} {f(y + 3 * s)} L{f(x + 12.5 * s * k)} {f(y + 6.5 * s)}" stroke="{DARK}" stroke-width="{f(1.5 * s)}" stroke-linecap="round"/>'
    elif latch == 'broken':
        p += f'<path d="M{f(x + 1 * k * s)} {f(y + 3 * s)} l{f(3 * k * s)} {f(-3.4 * s)}" stroke="{DARK}" stroke-width="{f(1.5 * s)}" stroke-linecap="round"/>'
    return p


def puller(ax, y, gx, lever=-60, pipe=False, frayed=False, latch=True, s=1.0, cable_wave=0.0, release=False):
    """Come-along: anchor hook at ax, frame, ratchet wheel, lever, cable to gx."""
    g = []
    bx0, bx1 = ax - 40 * s, ax - 10 * s
    # Cable from the drum to the grip-end hook.
    cx0, cx1 = gx + 10 * s, bx0 + 4 * s
    if cable_wave:
        pts = []
        for i in range(21):
            t = i / 20
            pts.append((cx0 + (cx1 - cx0) * t, y + math.sin(t * math.pi * 3) * cable_wave * (1 - abs(0.5 - t))))
        d = 'M' + ' L'.join(f'{f(px)} {f(py)}' for px, py in pts)
        g.append(f'<path d="{d}" stroke="{CABLE}" stroke-width="{f(2.2 * s)}" fill="none" stroke-linejoin="round"/>')
    else:
        g.append(f'<path d="M{f(cx0)} {f(y)} L{f(cx1)} {f(y)}" stroke="{CABLE}" stroke-width="{f(2.2 * s)}"/>')
    if frayed:
        mx = (cx0 + cx1) / 2
        for dx, a, L in ((-4, -60, 7), (-1, -110, 8), (2, 55, 7), (5, 120, 6), (0, -80, 9)):
            r = math.radians(a)
            g.append(f'<path d="M{f(mx + dx * s)} {f(y)} l{f(math.cos(r) * L * s)} {f(math.sin(r) * L * s)}" stroke="{CABLE}" stroke-width="{f(0.9 * s)}" stroke-linecap="round"/>')
        g.append(f'<path d="M{f(mx - 6 * s)} {f(y)} L{f(mx + 7 * s)} {f(y)}" stroke="{DARK}" stroke-width="{f(1.2 * s)}"/>')
    # Hook at the grip end (into the grip's eye-bolt).
    g.append(f'<circle cx="{f(gx + 7 * s)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="none" stroke="url(#steel)" stroke-width="{f(2 * s)}"/>')
    # Frame.
    g.append(f'<rect x="{f(bx0)}" y="{f(y - 7 * s)}" width="{f(bx1 - bx0)}" height="{f(14 * s)}" rx="{f(3 * s)}" fill="url(#body)" stroke="{DARK}" stroke-width="{f(0.8 * s)}"/>')
    # Ratchet wheel + pawl.
    wx = bx0 + 15 * s
    teeth = ''.join(
        f'<path d="M{f(wx + math.cos(a) * 5 * s)} {f(y + math.sin(a) * 5 * s)} L{f(wx + math.cos(a + 0.25) * 7.4 * s)} {f(y + math.sin(a + 0.25) * 7.4 * s)}"/>'
        for a in [i * math.pi / 5 for i in range(10)])
    g.append(f'<circle cx="{f(wx)}" cy="{f(y)}" r="{f(5.4 * s)}" fill="url(#steel)"/><g stroke="{DARK}" stroke-width="{f(1.3 * s)}">{teeth}</g>')
    pawl_ang = 30 if release else -20
    g.append(f'<path d="M{f(wx + 9 * s)} {f(y - 5 * s)} l{f(-4 * s)} {f(4 * s)}" stroke="{DARK}" stroke-width="{f(1.8 * s)}" stroke-linecap="round" '
             f'transform="rotate({pawl_ang} {f(wx + 9 * s)} {f(y - 5 * s)})"/>')
    # Lever from the wheel's axle.
    r = math.radians(lever)
    L = 30 * s
    ex, ey = wx + math.cos(r) * L, y + math.sin(r) * L
    g.append(f'<path d="M{f(wx)} {f(y)} L{f(ex)} {f(ey)}" stroke="url(#steelArm)" stroke-width="{f(3.6 * s)}" stroke-linecap="round"/>')
    gx0, gy0 = wx + math.cos(r) * (L - 11 * s), y + math.sin(r) * (L - 11 * s)
    g.append(f'<path d="M{f(gx0)} {f(gy0)} L{f(ex)} {f(ey)}" stroke="{GRIPRED}" stroke-width="{f(5 * s)}" stroke-linecap="round"/>')
    if pipe:
        px, py = wx + math.cos(r) * (L + 34 * s), y + math.sin(r) * (L + 34 * s)
        g.append(f'<path d="M{f(gx0)} {f(gy0)} L{f(px)} {f(py)}" stroke="url(#steel)" stroke-width="{f(6.4 * s)}" stroke-linecap="round"/>'
                 f'<path d="M{f(gx0)} {f(gy0)} L{f(px)} {f(py)}" stroke="{DARK}" stroke-width="{f(0.7 * s)}" fill="none" opacity="0.6"/>')
    g.append(f'<circle cx="{f(wx)}" cy="{f(y)}" r="{f(1.8 * s)}" fill="{DARK}"/>')
    # Anchor hook: a short link off the frame's right end.
    g.append(f'<path d="M{f(bx1)} {f(y)} L{f(ax)} {f(y)}" stroke="url(#steel)" stroke-width="{f(2.6 * s)}"/>')
    g.append(f'<circle cx="{f(ax)}" cy="{f(y)}" r="{f(3.2 * s)}" fill="none" stroke="url(#steel)" stroke-width="{f(2.2 * s)}"/>')
    if latch is not True:
        g.append(f'<path d="M{f(ax + 2 * s)} {f(y - 4 * s)} l{f(2.6 * s)} {f(-2 * s)}" stroke="{DARK}" stroke-width="{f(1.4 * s)}" stroke-linecap="round"/>')
    else:
        g.append(f'<path d="M{f(ax + 2 * s)} {f(y - 4 * s)} l{f(1 * s)} {f(7 * s)}" stroke="{DARK}" stroke-width="{f(1.4 * s)}" stroke-linecap="round"/>')
    return ''.join(g)


def grip(x, y, s=1.0, teeth='sharp', ang=0, oily=False):
    """Wire grip (side view) clamped on a conductor along y; the eye-bolt is
    on its right end at about x + 7s. teeth: sharp | blunt."""
    g = []
    # Upper jaw + lower jaw plates.
    g.append(f'<path d="M{f(x - 26 * s)} {f(y - 2 * s)} L{f(x - 22 * s)} {f(y - 9 * s)} L{f(x + 2 * s)} {f(y - 9 * s)} L{f(x + 4 * s)} {f(y - 2 * s)} Z" fill="url(#steel)" stroke="{DARK}" stroke-width="{f(0.7 * s)}"/>')
    g.append(f'<path d="M{f(x - 22 * s)} {f(y + 2 * s)} L{f(x + 2 * s)} {f(y + 2 * s)} L{f(x - 2 * s)} {f(y + 12 * s)} L{f(x - 18 * s)} {f(y + 12 * s)} Z" fill="url(#steelArm)" stroke="{DARK}" stroke-width="{f(0.7 * s)}"/>')
    # Teeth biting the wire.
    for i in range(7):
        tx = x - 22 * s + i * 3.6 * s
        if teeth == 'sharp':
            g.append(f'<path d="M{f(tx)} {f(y - 2 * s)} l{f(1.6 * s)} {f(2.6 * s)} l{f(1.6 * s)} {f(-2.6 * s)} Z" fill="{DARK}"/>')
            g.append(f'<path d="M{f(tx)} {f(y + 2 * s)} l{f(1.6 * s)} {f(-2.6 * s)} l{f(1.6 * s)} {f(2.6 * s)} Z" fill="{DARK}"/>')
        else:
            g.append(f'<rect x="{f(tx)}" y="{f(y - 2.4 * s)}" width="{f(3 * s)}" height="{f(0.9 * s)}" rx="{f(0.4 * s)}" fill="{DARK}"/>')
            g.append(f'<rect x="{f(tx)}" y="{f(y + 1.5 * s)}" width="{f(3 * s)}" height="{f(0.9 * s)}" rx="{f(0.4 * s)}" fill="{DARK}"/>')
    if oily:
        for dx, dy, rx, ry in ((-18, -1, 6, 3.4), (-8, 1, 7, 3.8), (0, -2, 4, 2.6), (-12, 6, 5, 2.4)):
            g.append(f'<ellipse cx="{f(x + dx * s)}" cy="{f(y + dy * s)}" rx="{f(rx * s)}" ry="{f(ry * s)}" fill="{OIL}" opacity="0.9"/>')
        g.append(f'<path d="M{f(x - 14 * s)} {f(y + 4 * s)} q{f(1 * s)} {f(8 * s)} 0 {f(12 * s)}" stroke="{OIL}" stroke-width="{f(2.2 * s)}" fill="none" stroke-linecap="round"/>')
    # Link from the jaws to the eye-bolt.
    g.append(f'<path d="M{f(x + 2 * s)} {f(y + 6 * s)} L{f(x + 6 * s)} {f(y)}" stroke="url(#steelArm)" stroke-width="{f(2.6 * s)}"/>')
    g.append(f'<circle cx="{f(x + 7 * s)}" cy="{f(y)}" r="{f(3.4 * s)}" fill="none" stroke="url(#steelArm)" stroke-width="{f(2 * s)}"/>')
    body = ''.join(g)
    if ang:
        body = f'<g transform="rotate({f(ang)} {f(x)} {f(y)})">{body}</g>'
    return body


# --------------------------------------------------------------------------
# Round 1 — check the tools before use (close-up on the canvas tarp).
# --------------------------------------------------------------------------

def tarp_stage():
    out = card_open('tarp')
    out.append('<g stroke="#FFFFFF" stroke-opacity="0.06" stroke-width="1">'
               + ''.join(f'<path d="M{x} 0 L{x - 60} 220"/>' for x in range(20, 280, 18)) + '</g>')
    return out


def grip_open(x, y, s, teeth='sharp', oily=False):
    """The wire grip close up, jaws open: two rows of teeth facing each other."""
    g = []
    g.append(f'<path d="M{f(x - 70 * s)} {f(y - 10 * s)} L{f(x - 62 * s)} {f(y - 34 * s)} L{f(x + 20 * s)} {f(y - 34 * s)} L{f(x + 26 * s)} {f(y - 10 * s)} Z" fill="url(#steel)" stroke="{DARK}" stroke-width="1"/>')
    g.append(f'<path d="M{f(x - 62 * s)} {f(y + 10 * s)} L{f(x + 20 * s)} {f(y + 10 * s)} L{f(x + 10 * s)} {f(y + 38 * s)} L{f(x - 50 * s)} {f(y + 38 * s)} Z" fill="url(#steelArm)" stroke="{DARK}" stroke-width="1"/>')
    for i in range(10):
        tx = x - 62 * s + i * 8 * s
        if teeth == 'sharp':
            g.append(f'<path d="M{f(tx)} {f(y - 10 * s)} l{f(3.6 * s)} {f(7 * s)} l{f(3.6 * s)} {f(-7 * s)} Z" fill="url(#steel)" stroke="{DARK}" stroke-width="0.8"/>')
            g.append(f'<path d="M{f(tx)} {f(y + 10 * s)} l{f(3.6 * s)} {f(-7 * s)} l{f(3.6 * s)} {f(7 * s)} Z" fill="url(#steel)" stroke="{DARK}" stroke-width="0.8"/>')
        else:
            g.append(f'<rect x="{f(tx)}" y="{f(y - 10.5 * s)}" width="{f(7 * s)}" height="{f(2 * s)}" rx="{f(1 * s)}" fill="url(#steel)" stroke="{DARK}" stroke-width="0.8"/>')
            g.append(f'<rect x="{f(tx)}" y="{f(y + 8.5 * s)}" width="{f(7 * s)}" height="{f(2 * s)}" rx="{f(1 * s)}" fill="url(#steel)" stroke="{DARK}" stroke-width="0.8"/>')
    if oily:
        for dx, dy, rx, ry in ((-48, -8, 14, 6), (-22, 9, 16, 6), (4, -7, 12, 5), (-34, 0, 8, 4)):
            g.append(f'<ellipse cx="{f(x + dx * s)}" cy="{f(y + dy * s)}" rx="{f(rx * s)}" ry="{f(ry * s)}" fill="{OIL}" opacity="0.92"/>')
        g.append(f'<path d="M{f(x - 22 * s)} {f(y + 14 * s)} q{f(2 * s)} {f(14 * s)} 0 {f(24 * s)}" stroke="{OIL}" stroke-width="{f(4 * s)}" fill="none" stroke-linecap="round"/>')
    # Hinge link and the eye-bolt on the right.
    g.append(f'<path d="M{f(x + 22 * s)} {f(y - 22 * s)} L{f(x + 36 * s)} {f(y)} L{f(x + 16 * s)} {f(y + 24 * s)}" stroke="url(#steelArm)" stroke-width="{f(5 * s)}" fill="none" stroke-linejoin="round"/>')
    g.append(f'<circle cx="{f(x + 44 * s)}" cy="{f(y)}" r="{f(8 * s)}" fill="none" stroke="url(#steelArm)" stroke-width="{f(4.4 * s)}"/>')
    return ''.join(g)


def check_card(kind):
    out = tarp_stage()
    if kind in ('clean', 'oily', 'blunt'):
        out.append(grip_open(98, 110, 1.15, teeth='blunt' if kind == 'blunt' else 'sharp', oily=kind == 'oily'))
    else:
        out.append(grip(28, 96, 1.6))
        out.append(f'<path d="M-4 96 L30 96" stroke="{WIRE}" stroke-width="5"/>')
        out.append(puller(150, 96, 30, lever=-58, s=2.2, frayed=kind == 'frayed', latch=True))
        out.append(hook(152, 96, 2.8, latch='broken' if kind == 'no_latch' else True))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — rig it (side view of the dead-end pole; no one on it).
# --------------------------------------------------------------------------

GY = 196
PX = 160
ARM_Y = 52
CY = 80             # the conductor's height at the grip


def insulator(x, y, s=1.0):
    return (f'<g transform="translate({f(x)} {f(y)}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#steel)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


def rig_stage():
    out = card_open('sky')
    out.append('<g fill="#FFFFFF" opacity="0.8"><ellipse cx="40" cy="30" rx="22" ry="7"/><ellipse cx="54" cy="25" rx="14" ry="8"/></g>')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    # A dry roadside tree by the pole, one thin dead branch reaching over.
    out.append(f'<path d="M112 {GY} Q108 150 114 120 Q116 104 110 90" stroke="#6B5640" stroke-width="5" fill="none" stroke-linecap="round"/>'
               f'<path d="M113 106 Q124 96 130 {CY + 4}" stroke="#6B5640" stroke-width="2" fill="none" stroke-linecap="round"/>'
               f'<path d="M110 90 l-8 -12 M110 92 l6 -14" stroke="#6B5640" stroke-width="1.6" stroke-linecap="round"/>')
    # Pole, cross-arm, insulators.
    out.append(f'<rect x="{PX - 7}" y="0" width="14" height="{GY + 3}" fill="url(#pole)"/>')
    out.append(f'<path d="M104 {ARM_Y} L204 {ARM_Y - 4} L204 {ARM_Y + 2} L104 {ARM_Y + 6} Z" fill="url(#steelArm)"/>')
    out.append(insulator(184, ARM_Y - 3, 0.9))
    out.append(insulator(PX, 18, 0.85))
    out.append(f'<path d="M184 {ARM_Y - 20} Q194 {ARM_Y - 22} 204 {ARM_Y - 20}" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    return out


def rig_card(kind):
    out = rig_stage()
    gx = 52
    if kind == 'arm':
        anchor = (PX - 12, ARM_Y + 8)
        sling = (f'<path d="M{PX - 16} {ARM_Y - 1} q-3 6 2 12 q5 2 6 -10" stroke="url(#strap)" stroke-width="4" fill="none" stroke-linecap="round"/>')
    elif kind == 'branch':
        anchor = (128, CY + 6)
        sling = f'<path d="M124 {CY + 1} q2 8 7 6" stroke="url(#strap)" stroke-width="3.4" fill="none" stroke-linecap="round"/>'
    else:
        anchor = (PX - 11, CY + 6)
        sling = (f'<rect x="{PX - 8}" y="{CY}" width="16" height="7" rx="2" fill="url(#strap)"/>'
                 f'<path d="M{PX - 8} {CY + 4} L{anchor[0] + 2} {anchor[1]}" stroke="url(#strap)" stroke-width="3.4"/>')
    ax, ay = anchor
    # The conductor: taut from the span (left) to the grip, its slack end
    # hanging on toward the pole.
    out.append(f'<path d="M-4 {CY - 12} Q24 {CY - 4} {gx} {CY}" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    out.append(f'<path d="M{gx + 2} {CY} Q{gx + 40} {CY + 6} {gx + 52} {CY + 52} Q{gx + 58} {CY + 80} {gx + 70} {CY + 92}" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    out.append(sling)
    ang = math.degrees(math.atan2(ay - CY, ax - (gx + 7)))
    rig = puller(ax, CY, gx if kind != 'jaw' else gx - 18, lever=-62, s=0.9)
    out.append(f'<g transform="rotate({f(ang)} {f(ax)} {f(CY)}) translate(0 {f(ay - CY)})">{rig}</g>')
    if kind == 'skew':
        out.append(grip(gx, CY - 5, 0.95, ang=-28))
    else:
        out.append(grip(gx, CY, 0.95))
    if kind == 'jaw':
        # The hook hung on the jaw plate, not in the eye-bolt.
        out.append(f'<path d="M{gx - 11} {CY - 12} q6 -2 6 4 q0 5 -6 4" stroke="url(#steel)" stroke-width="2.6" fill="none"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Rounds 3-5 — from above: the line of pull runs across the card from the
# span (left) through the grip and the puller to the pole (right).
# --------------------------------------------------------------------------

LY = 100            # line of pull
PTX = 170           # pole (from above)
AX = PTX - 16       # the puller's anchor hook
GX = 66             # the grip
RS = 1.3            # rig scale
WS = 1.35           # worker scale


def top_worker(x, y, face=-90, hands=None, lean=0.0, s=WS):
    """A lineman seen from above: helmet, shoulders, arms to gloved hands.
    face = the direction he faces, degrees (0 = right, -90 = up)."""
    r = math.radians(face)
    fx, fy = math.cos(r), math.sin(r)
    px, py = -fy, fx
    cx, cy = x + fx * lean, y + fy * lean
    sl = (cx + px * 10 * s, cy + py * 10 * s)
    sr = (cx - px * 10 * s, cy - py * 10 * s)
    if hands is None:
        hands = ((sl[0] + fx * 8 * s, sl[1] + fy * 8 * s), (sr[0] + fx * 8 * s, sr[1] + fy * 8 * s))
    g = []
    # Boots peeking out in front.
    for k in (-1, 1):
        bx, by = x + fx * 9 * s + px * 5 * k * s, y + fy * 9 * s + py * 5 * k * s
        g.append(f'<ellipse cx="{f(bx)}" cy="{f(by)}" rx="{f(4 * s)}" ry="{f(2.6 * s)}" fill="{BOOT}" transform="rotate({f(face)} {f(bx)} {f(by)})"/>')
    for s_, h in ((sl, hands[0]), (sr, hands[1])):
        g.append(f'<path d="M{f(s_[0])} {f(s_[1])} L{f(h[0])} {f(h[1])}" stroke="{SHIRT_D}" stroke-width="{f(5.4 * s)}" stroke-linecap="round"/>')
        g.append(f'<circle cx="{f(h[0])}" cy="{f(h[1])}" r="{f(3.2 * s)}" fill="{GLOVE}"/>')
    g.append(f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(12 * s)}" ry="{f(6.5 * s)}" fill="url(#shirt)" transform="rotate({f(face + 90)} {f(cx)} {f(cy)})"/>')
    hx, hy = cx + fx * 1.5 * s, cy + fy * 1.5 * s
    g.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="{f(8 * s)}" fill="{HELMET_D}"/>')
    g.append(f'<circle cx="{f(hx)}" cy="{f(hy)}" r="{f(6.4 * s)}" fill="{HELMET}"/>')
    g.append(f'<path d="M{f(hx - px * 5 * s)} {f(hy - py * 5 * s)} L{f(hx + px * 5 * s)} {f(hy + py * 5 * s)}" stroke="{HELMET_D}" stroke-width="{f(1.4 * s)}"/>')
    return ''.join(g)


def top_stage(lever=90, pipe=False, cable_wave=0.0, release=False, rigged=True, slack=False):
    out = card_open('yard')
    out.append('<g fill="#6F8452" opacity="0.6">'
               + ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{r}" ry="{f(r * 0.6)}"/>' for x, y, r in
                         ((20, 30, 9), (176, 30, 7), (30, 190, 10), (178, 196, 8), (96, 204, 6), (110, 22, 6)))
               + '</g>')
    # The pole seen from above, with its strap.
    out.append(f'<circle cx="{PTX}" cy="{LY}" r="13" fill="url(#poleTop)" stroke="#77746D" stroke-width="0.8"/>')
    out.append(f'<circle cx="{PTX}" cy="{LY}" r="15.5" fill="none" stroke="url(#strap)" stroke-width="4"/>')
    out.append(f'<path d="M{PTX - 15} {LY} L{AX + 3} {LY}" stroke="url(#strap)" stroke-width="4"/>')
    if rigged:
        # Conductor from the span to the grip, the slack end to the pole.
        sag = 6 if slack else 0
        out.append(f'<path d="M-4 {LY} Q{GX / 2} {LY + sag} {GX} {LY}" stroke="{WIRE}" stroke-width="4" fill="none"/>')
        out.append(grip(GX, LY, RS))
        out.append(puller(AX, LY, GX, lever=lever, pipe=pipe, cable_wave=cable_wave, release=release, s=RS))
    else:
        out.append(f'<path d="M-4 {LY} L{PTX - 12} {LY + 4}" stroke="{WIRE}" stroke-width="3.4" fill="none"/>')
    return out


WX = AX - 25 * RS   # the ratchet wheel's axle


def lever_end(lever, L=34):
    wx = WX
    r = math.radians(lever)
    return (wx + math.cos(r) * L, LY + math.sin(r) * L)


def jerk_lines(x, y):
    return ('<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" fill="none" opacity="0.9">'
            f'<path d="M{f(x - 8)} {f(y - 10)} l4 4 l-4 4 l4 4"/><path d="M{f(x + 8)} {f(y - 10)} l4 4 l-4 4 l4 4"/></g>')


def arc_marks(cx, cy, r, a0, a1, op=0.9):
    """A soft arc showing the lever's stroke."""
    p0 = (cx + math.cos(math.radians(a0)) * r, cy + math.sin(math.radians(a0)) * r)
    p1 = (cx + math.cos(math.radians(a1)) * r, cy + math.sin(math.radians(a1)) * r)
    sweep = 1 if a1 > a0 else 0
    return (f'<path d="M{f(p0[0])} {f(p0[1])} A{r} {r} 0 0 {sweep} {f(p1[0])} {f(p1[1])}" stroke="#FFFFFF" stroke-width="1.6" '
            f'fill="none" stroke-dasharray="3 3" opacity="{op}"/>')


def stand_card(kind):
    lever = -90 if kind == 'side_far' else 90
    out = top_stage(lever=lever)
    hx, hy = lever_end(lever)
    if kind == 'side':
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'side_far':
        out.append(top_worker(hx + 2, hy - 24, face=90, hands=((hx - 2, hy - 2), (hx + 5, hy - 1))))
    elif kind == 'front':
        # In line beyond the grip, facing the rig.
        out.append(top_worker(14, LY, face=0))
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'behind':
        # Behind the pole, in line with the pull, looking over it.
        out.append(top_worker(193, LY, face=180))
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'astride':
        # Straddling the cable between the grip and the puller.
        out.append(top_worker(90, LY, face=0, hands=((100, LY - 11), (100, LY + 11))))
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    return card_close(out)


def pull_card(kind):
    lever = 90
    if kind == 'pipe':
        out = top_stage(lever=lever, pipe=True)
        hx, hy = lever_end(lever, 78)
        out.append(top_worker(hx + 2, hy + 18, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy - 8)), lean=4))
        return card_close(out)
    if kind == 'yank':
        lever = 120
        out = top_stage(lever=lever, cable_wave=4)
        hx, hy = lever_end(lever)
        out.append(top_worker(hx - 4, hy + 30, face=-70, hands=((hx - 3, hy + 2), (hx + 4, hy + 1)), lean=-6))
        out.append(jerk_lines(hx - 4, hy + 2))
        out.append(jerk_lines(GX + 40, LY - 16))
        return card_close(out)
    if kind == 'let_go':
        # Hands off mid-stroke: the lever flies back, the ratchet not locked.
        lever = 30
        out = top_stage(lever=lever, release=True)
        wx = WX
        out.append(arc_marks(wx, LY, 32, 95, 40))
        out.append(top_worker(wx + 4, LY + 66, face=-90, hands=((wx - 6, LY + 48), (wx + 14, LY + 48))))
        return card_close(out)
    out = top_stage(lever=lever)
    hx, hy = lever_end(lever)
    if kind == 'slow':
        out.append(arc_marks(WX, LY, 26, 70, 110, 0.7))
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'lock':
        # One hand holds the lever, the other on the ratchet: did it lock?
        out.append(top_worker(hx - 2, hy + 24, face=-90, hands=((hx - 2, hy + 1), (WX + 4, LY + 8))))
    return card_close(out)


def release_card(kind):
    if kind == 'ease':
        out = top_stage(lever=80, release=True, slack=True)
        hx, hy = lever_end(80)
        out.append(arc_marks(WX, LY, 26, 100, 80, 0.7))
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'learn':
        # Before the job, off the line: the puller in hand, finger on the release.
        out = top_stage(rigged=False)
        out.append(puller(150, 156, 66, lever=-70, s=RS, release=True))
        out.append(top_worker(118, 190, face=-90, hands=((112, 166), (126, 160))))
        out.append(grip(56, 156, RS))
    elif kind == 'snap':
        # The pawl knocked off: the whole load runs back at once.
        out = top_stage(lever=-40, release=True, cable_wave=6, slack=True)
        out.append(jerk_lines(GX + 46, LY - 18))
        out.append(jerk_lines(GX - 20, LY - 16))
        hx, hy = lever_end(90)
        out.append(top_worker(hx + 2, hy + 30, face=-90, hands=((hx - 6, hy + 8), (hx + 8, hy + 8)), lean=-4))
    elif kind == 'front':
        out = top_stage(lever=80, release=True)
        out.append(top_worker(14, LY, face=0))
        hx, hy = lever_end(80)
        out.append(top_worker(hx + 2, hy + 24, face=-90, hands=((hx - 2, hy + 2), (hx + 5, hy + 1))))
    elif kind == 'unhook':
        # Prying the hook off the grip with the line still under load.
        out = top_stage(lever=90, release=True)
        out.append(top_worker(GX + 12, LY + 30, face=-90, hands=((GX + 4, LY + 4), (GX + 14, LY + 2))))
        out.append(jerk_lines(GX + 10, LY - 16))
    return card_close(out)


CARDS = {
    # Round 1 — check the tools.
    'check_clean': check_card('clean'),
    'check_latch': check_card('latch'),
    'check_oily': check_card('oily'),
    'check_blunt': check_card('blunt'),
    'check_no_latch': check_card('no_latch'),
    'check_frayed': check_card('frayed'),
    # Round 2 — rig it.
    'rig_strap': rig_card('strap'),
    'rig_arm': rig_card('arm'),
    'rig_branch': rig_card('branch'),
    'rig_skew': rig_card('skew'),
    'rig_jaw': rig_card('jaw'),
    # Round 3 — where to stand.
    'stand_side': stand_card('side'),
    'stand_side_far': stand_card('side_far'),
    'stand_front': stand_card('front'),
    'stand_behind': stand_card('behind'),
    'stand_astride': stand_card('astride'),
    # Round 4 — tensioning.
    'pull_slow': pull_card('slow'),
    'pull_lock': pull_card('lock'),
    'pull_pipe': pull_card('pipe'),
    'pull_yank': pull_card('yank'),
    'pull_let_go': pull_card('let_go'),
    # Round 5 — releasing the load.
    'release_ease': release_card('ease'),
    'release_learn': release_card('learn'),
    'release_snap': release_card('snap'),
    'release_front': release_card('front'),
    'release_unhook': release_card('unhook'),
}

# Safe cards and traps per round (mirrors learn_board_pack24.dart).
ROUNDS = {
    'check': (['check_clean', 'check_latch'], ['check_oily', 'check_blunt', 'check_no_latch', 'check_frayed']),
    'rig': (['rig_strap', 'rig_arm'], ['rig_branch', 'rig_skew', 'rig_jaw']),
    'stand': (['stand_side', 'stand_side_far'], ['stand_front', 'stand_behind', 'stand_astride']),
    'pull': (['pull_slow', 'pull_lock'], ['pull_pipe', 'pull_yank', 'pull_let_go']),
    'release': (['release_ease', 'release_learn'], ['release_snap', 'release_front', 'release_unhook']),
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
