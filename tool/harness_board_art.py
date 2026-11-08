"""Picture cards for ladder step 10 (lesson 1.4 শেখা, "হারনেস: লাইফলাইন").

python -I tool/harness_board_art.py .

Writes assets/game/art/harness_board/*.svg — the same clean gradient style as
tool/lakshman_art.py (200 x 220 scene cards, drawn edge to edge). No words in
the art; the only writing is what a worker reads on a real harness: the
label's made / expiry dates.

What the cards show comes from lesson 1.4 only:
  1. full body harness (shoulders, chest, thighs) vs the waist belt, which is
     for work positioning only and in a fall puts all the load on the belly
     and spine;
  2. the 3-minute check: webbing (cut, torn, burn, chemical), stitching,
     hardware (D-ring, buckle: crack, deformation, heavy rust), the label's
     expiry date;
  3. fit: no twisted strap, about four fingers under a strap, chest strap
     across mid-chest, back D-ring between the shoulders; loose = can slip out;
  4. the lanyard to a strong anchor — never a broken cross-arm or a weak
     insulator pin;
  5. suspension trauma: hanging long in a harness can make a worker faint
     within minutes, so a quick rescue must be ready.
"""

import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'harness_board')
W, H = 200, 220

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
THREAD = '#3B2A18'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="woodArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A7048"/><stop offset="1" stop-color="#5E4128"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="webO" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF9F45"/><stop offset="0.5" stop-color="#F7811F"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="webOv" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9640C"/><stop offset="0.5" stop-color="#FF9F45"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="webUnder" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6E3206"/><stop offset="1" stop-color="#8E450C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="pad" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3A3F46"/><stop offset="1" stop-color="#1F2328"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9965E"/><stop offset="1" stop-color="#9E6B38"/></linearGradient>
  <linearGradient id="tag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#E9EDF0"/></linearGradient>
  <radialGradient id="vignette" cx="0.5" cy="0.45" r="0.75"><stop offset="0.6" stop-color="#000000" stop-opacity="0"/><stop offset="1" stop-color="#000000" stop-opacity="0.28"/></radialGradient>
  <radialGradient id="burn" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1C120B"/><stop offset="0.55" stop-color="#3B2414"/><stop offset="0.85" stop-color="#7A4A22" stop-opacity="0.85"/><stop offset="1" stop-color="#A8601E" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def card_open(sky='sky'):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']


def card_close(out, vignette=False):
    if vignette:
        out.append(f'<rect width="{W}" height="{H}" fill="url(#vignette)"/>')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def clouds(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.9"><ellipse cx="{x}" cy="{y}" rx="{22 * s}" ry="{8 * s}"/>'
            f'<ellipse cx="{x + 15 * s}" cy="{y - 6 * s}" rx="{15 * s}" ry="{9 * s}"/></g>')


def trees(y, fill='#7FA36A'):
    """A soft far tree line sitting on the ground line [y]."""
    blobs = ''.join(f'<ellipse cx="{x}" cy="{y - r * 0.55}" rx="{r * 1.3}" ry="{r}"/>'
                    for x, r in [(8, 12), (30, 9), (52, 14), (150, 10), (176, 15), (198, 9)])
    return f'<g fill="{fill}" opacity="0.75">{blobs}</g>'


# --------------------------------------------------------------------------
# The worker seen from behind (he faces the pole), canonical 120 units tall.
# --------------------------------------------------------------------------

def back_worker(cx, top, s=1.0, harness='fbh', web='webO', arms='climb', legs='climb', dring_low=False):
    """Returns (svg, D-ring point in card coords)."""
    g = [f'<g transform="translate({cx} {top}) scale({s})">']
    # Legs (pants) and boots.
    if legs == 'climb':
        g.append(f'<path d="M-7 70 L-9 112" stroke="{PANTS}" stroke-width="10" stroke-linecap="round" fill="none"/>')
        g.append(f'<path d="M7 70 L11 92 L9 104" stroke="{PANTS}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="-15" y="111" width="12" height="6" rx="2.5" fill="{BOOT}"/><rect x="3" y="103" width="12" height="6" rx="2.5" fill="{BOOT}"/>')
    else:
        g.append(f'<path d="M-7 70 L-8 114 M7 70 L8 114" stroke="{PANTS}" stroke-width="10" stroke-linecap="round" fill="none"/>')
        g.append(f'<rect x="-14" y="112" width="12" height="6" rx="2.5" fill="{BOOT}"/><rect x="2" y="112" width="12" height="6" rx="2.5" fill="{BOOT}"/>')
    g.append(f'<path d="M-14 62 L14 62 L15 74 L-15 74 Z" fill="{PANTS}"/>')
    # Arms (behind the head).
    if arms == 'climb':
        g.append(f'<path d="M-13 33 L-11 14 L-5 -1" stroke="{SHIRT}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M13 33 L12 16 L5 3" stroke="{SHIRT}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<circle cx="-5" cy="-2" r="3.6" fill="{SKIN}"/><circle cx="5" cy="2" r="3.6" fill="{SKIN}"/>')
    elif arms == 'reach':
        g.append(f'<path d="M-13 33 L-11 14 L-5 -1" stroke="{SHIRT}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M13 33 L26 22 L36 12" stroke="{SHIRT}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<circle cx="-5" cy="-2" r="3.6" fill="{SKIN}"/><circle cx="37" cy="11" r="3.6" fill="{SKIN}"/>')
    else:
        g.append(f'<path d="M-15 33 L-18 62 M15 33 L18 62" stroke="{SHIRT}" stroke-width="7" stroke-linecap="round" fill="none"/>')
        g.append(f'<circle cx="-18" cy="64" r="3.6" fill="{SKIN}"/><circle cx="18" cy="64" r="3.6" fill="{SKIN}"/>')
    # Torso.
    g.append('<path d="M-16 30 Q0 25 16 30 L13 66 L-13 66 Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M0 32 L0 64" stroke="{SHIRT_D}" stroke-width="0.8" opacity="0.6"/>')
    # Neck, head (back of it), helmet.
    g.append(f'<rect x="-3.5" y="22" width="7" height="7" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="0" cy="17" r="8.5" fill="{HAIR}"/>')
    g.append(f'<path d="M-11 13 A11 11 0 0 1 11 13 Z" fill="{HELMET}"/><path d="M-3 3 Q0 1.5 3 3 L2 12 L-2 12 Z" fill="#FFE68C" opacity="0.7"/>')
    g.append(f'<rect x="-13" y="11.5" width="26" height="3.4" rx="1.6" fill="{HELMET_D}"/>')

    dy = 39
    if harness in ('fbh', 'fbh_none'):
        d = 62 if dring_low else 39
        dy = d
        # Every harness on the board is the same orange: colour must never
        # tell the safe card from a trap.
        strap = 'stroke="#F7811F" stroke-width="4.6" fill="none" stroke-linejoin="round"'
        edge = 'stroke="#00000033" stroke-width="5.8" fill="none" stroke-linejoin="round"'
        x_path = f'M-10 29 L0 {d} L11 66 L9 77 M10 29 L0 {d} L-11 66 L-9 77'
        face = 'stroke="#FFD3A1" stroke-width="0.7" fill="none" stroke-linejoin="round" stroke-dasharray="2.4 1.3"'
        g.append(f'<path d="{x_path}" {edge}/>')
        g.append(f'<path d="{x_path}" {strap}/>')
        g.append(f'<path d="{x_path}" {face}/>')
        # Sub-pelvic strap and leg loops.
        g.append(f'<path d="M-13 77 Q0 81 13 77" {edge}/><path d="M-13 77 Q0 81 13 77" {strap}/><path d="M-13 77 Q0 81 13 77" {face}/>')
        for lx in (-8, 8):
            leg = f'M{lx - 6} 84 Q{lx} 88 {lx + 6} 84'
            g.append(f'<path d="{leg}" {edge}/><path d="{leg}" {strap}/><path d="{leg}" {face}/>')
        # Back pad and D-ring.
        g.append(f'<rect x="-5.5" y="{d - 4}" width="11" height="10" rx="2.5" fill="url(#pad)"/>')
        g.append(f'<path d="M-4.2 {d - 3} L4.2 {d - 3} Q4.2 {d - 10} 0 {d - 11} Q-4.2 {d - 10} -4.2 {d - 3} Z" fill="none" stroke="url(#steel)" stroke-width="2"/>')
        g.append(f'<path d="M-3.6 {d + 3} L3.6 {d + 3}" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="0.6" stroke-dasharray="1 1"/>')
        dy = d - 10
    elif harness == 'belt':
        g.append('<rect x="-15.5" y="58" width="31" height="9" rx="2" fill="#6B4423"/>')
        g.append('<path d="M-14 60 L14 60 M-14 65 L14 65" stroke="#C9A06A" stroke-width="0.6" stroke-dasharray="1.4 1.2"/>')
        g.append('<rect x="-4" y="57.5" width="8" height="10" rx="1.5" fill="none" stroke="url(#steel)" stroke-width="1.6"/>')
        for sx in (-1, 1):
            g.append(f'<path d="M{16 * sx} 62.5 m-2.2 -3 a3 3 0 1 0 0.01 0" fill="none" stroke="url(#steel)" stroke-width="1.6"/>')
            # The pole strap runs from the hip rings forward round the pole.
            g.append(f'<path d="M{17 * sx} 62 Q{12 * sx} 54 {5 * sx} 50" stroke="#4A2E16" stroke-width="4" fill="none" stroke-linecap="round"/>')
        dy = 62
    g.append('</g>')
    return ''.join(g), (cx, top + dy * s)


def pole_full(x=100, w=16, top=0, bottom=220):
    return f'<rect x="{x - w / 2}" y="{top}" width="{w}" height="{bottom - top}" fill="url(#pole)"/>'


def step_bolts(x, ys, w=16):
    return ''.join(f'<rect x="{x - w / 2 - 7}" y="{y}" width="7" height="2.6" rx="1" fill="#6F777E"/>'
                   f'<rect x="{x + w / 2}" y="{y + 14}" width="7" height="2.6" rx="1" fill="#6F777E"/>' for y in ys)


def cross_arm(y, x0=26, x1=174, kind='steel'):
    s = []
    if kind == 'steel':
        s.append(f'<rect x="{x0}" y="{y}" width="{x1 - x0}" height="7" rx="1.5" fill="url(#steelArm)"/>')
        s.append(f'<path d="M100 {y + 7} L84 {y + 26} M100 {y + 7} L116 {y + 26}" stroke="#5F676F" stroke-width="2.6"/>')
    return ''.join(s)


def insulator(x, y):
    """A pin insulator sitting on the cross-arm top at [y]; returns svg."""
    return (f'<rect x="{x - 1.6}" y="{y - 7}" width="3.2" height="7" fill="#7D868E"/>'
            f'<path d="M{x - 7} {y - 7} L{x + 7} {y - 7} L{x + 4.5} {y - 12} L{x + 7.5} {y - 13} L{x + 4} {y - 19} L{x - 4} {y - 19} L{x - 7.5} {y - 13} L{x - 4.5} {y - 12} Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/>')


def wires(y, glow=False):
    return (f'<path d="M-4 {y + 3} Q 30 {y + 7} 44 {y}" stroke="#2B3138" stroke-width="2" fill="none"/>'
            f'<path d="M156 {y} Q 172 {y + 7} 204 {y + 3}" stroke="#2B3138" stroke-width="2" fill="none"/>')


def sling(x, y, w=16):
    """An anchor sling wrapped round the pole at [y] with its steel ring."""
    return (f'<rect x="{x - w / 2 - 1}" y="{y}" width="{w + 2}" height="6" rx="2" fill="#222830"/>'
            f'<path d="M{x - w / 2} {y + 1.5} L{x + w / 2} {y + 4.5}" stroke="#F7811F" stroke-width="1.4"/>'
            f'<circle cx="{x + w / 2 + 3}" cy="{y + 9}" r="4" fill="none" stroke="url(#steel)" stroke-width="2.2"/>')


def snap_hook(x, y, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot})">'
            f'<path d="M-2.6 8 L-2.6 -2 Q-2.6 -6.5 0.8 -6.5 Q4.2 -6.5 4.2 -2 L4.2 1" fill="none" stroke="url(#steel)" stroke-width="2.4" stroke-linecap="round"/>'
            f'<path d="M4.2 1 L2 7" stroke="#8E979F" stroke-width="1.6"/><rect x="-4" y="7" width="5.4" height="4" rx="1" fill="#8E979F"/></g>')


def lanyard(path, absorber_at=None):
    s = [f'<path d="{path}" stroke="#1E2A36" stroke-width="3.2" fill="none" stroke-linecap="round"/>',
         f'<path d="{path}" stroke="#4E7FB0" stroke-width="1.6" fill="none" stroke-dasharray="2.4 2" stroke-linecap="round"/>']
    if absorber_at:
        ax, ay, rot = absorber_at
        s.append(f'<g transform="translate({ax} {ay}) rotate({rot})"><rect x="-4" y="-7" width="8" height="14" rx="2.5" fill="#2F3A45"/>'
                 f'<rect x="-4" y="-2" width="8" height="2.4" fill="#F2BE22"/></g>')
    return ''.join(s)


# --------------------------------------------------------------------------
# Side view: a worker hanging in his harness after a fall (D-ring at 0,0).
# --------------------------------------------------------------------------

def hang_worker(x, y, s=1.0, web='#F7811F', limp=False, hold=True):
    g = [f'<g transform="translate({x} {y}) scale({s})">']
    # Legs hang down from the hips, knees a little bent.
    g.append(f'<path d="M7 36 L13 58 L9 80" stroke="{PANTS}" stroke-width="8.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<path d="M4 36 L8 59 L3 81" stroke="#222B37" stroke-width="8.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<path d="M0 79 L9 79 L11 84 L-1 84 Z" fill="{BOOT}"/><path d="M6 78 L15 78 L17 83 L5 83 Z" fill="{BOOT}"/>')
    # Torso, a little forward.
    g.append('<path d="M-3 -4 Q6 -9 14 -3 L15 33 L1 36 Z" fill="url(#shirt)"/>')
    # Head and helmet.
    hx, hy = (12, -13) if not limp else (16, -9)
    g.append(f'<circle cx="{hx}" cy="{hy}" r="7.5" fill="{SKIN}"/>')
    g.append(f'<path d="M{hx - 8.5} {hy - 2} A8.5 8.5 0 0 1 {hx + 8.5} {hy - 2} Z" fill="{HELMET}"/><rect x="{hx - 4}" y="{hy - 3.2}" width="15" height="2.6" rx="1.2" fill="{HELMET_D}"/>')
    if limp:
        g.append(f'<path d="M{hx + 2} {hy + 1} l3 0.6" stroke="#3A2A1E" stroke-width="1.2" stroke-linecap="round"/>')
    else:
        g.append(f'<circle cx="{hx + 3.5}" cy="{hy}" r="1.1" fill="#2A1E16"/>')
    # Arms.
    if hold and not limp:
        g.append(f'<path d="M7 0 L3 -14 L1 -26" stroke="{SHIRT}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/><circle cx="1" cy="-27" r="3" fill="{SKIN}"/>')
    else:
        g.append(f'<path d="M8 1 L14 18 L15 30" stroke="{SHIRT}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/><circle cx="15" cy="31" r="3" fill="{SKIN}"/>')
    # Harness: shoulder strap from the back D-ring over the shoulder, down the
    # chest to the leg loop; chest strap stub; leg loop round the thigh.
    strap = f'stroke="{web}" stroke-width="3.8" fill="none" stroke-linejoin="round" stroke-linecap="round"'
    g.append(f'<path d="M0 0 L6 -6 L12 -3 L13 30 L9 40" {strap}/>')
    g.append(f'<path d="M1 2 L2 32 L7 40" {strap}/>')
    g.append(f'<path d="M3 43 Q9 47 15 42" {strap}/>')
    g.append(f'<path d="M12 8 L16 8" stroke="{web}" stroke-width="3.4"/>')
    g.append('<path d="M-3 1 L3 1 Q3 -5 0 -6 Q-3 -5 -3 1 Z" fill="none" stroke="url(#steel)" stroke-width="1.8"/>')
    g.append('</g>')
    return ''.join(g)


def belt_fall_worker(x, y):
    """Jack-knifed over a waist belt: the lanyard holds him by the belly."""
    g = [f'<g transform="translate({x} {y})">']
    # Legs hang one way…
    g.append(f'<path d="M-3 3 L-12 26 L-9 52" stroke="#222B37" stroke-width="8.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<path d="M1 3 L-6 28 L-2 54" stroke="{PANTS}" stroke-width="8.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<path d="M-14 51 L-5 51 L-3 56 L-15 56 Z" fill="{BOOT}"/><path d="M-7 53 L2 53 L4 58 L-8 58 Z" fill="{BOOT}"/>')
    # …the body folds the other way.
    g.append('<path d="M-4 -1 L7 -6 L23 22 L12 30 Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M18 26 L16 46 M14 28 L8 46" stroke="{SHIRT}" stroke-width="5.5" stroke-linecap="round" fill="none"/>')
    g.append(f'<circle cx="16" cy="47" r="2.8" fill="{SKIN}"/><circle cx="8" cy="47" r="2.8" fill="{SKIN}"/>')
    g.append(f'<circle cx="22" cy="36" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M14 40 A8.5 8.5 0 0 0 30 34 Z" fill="{HELMET}"/>')
    g.append('<path d="M18 37 l2.4 -1.4 M18.6 39.6 l2.6 -0.4" stroke="#3A2A1E" stroke-width="1.1" stroke-linecap="round"/>')
    # The belt, crushing the belly.
    g.append('<path d="M-7 -1 L8 -8 L11 -2 L-4 5 Z" fill="#6B4423"/>')
    g.append('<path d="M-1 -4 m-2.6 0 a2.6 2.6 0 1 0 5.2 0 a2.6 2.6 0 1 0 -5.2 0" fill="none" stroke="url(#steel)" stroke-width="1.6"/>')
    # Strain marks at the belly and the spine.
    for cx, cy in ((12, 6), (-7, -6)):
        g.append(f'<path d="M{cx} {cy - 6} l1.6 4 l4 -1 l-2.6 3.2 l3.4 2.6 l-4.2 0.4 l0.6 4.2 l-2.8 -3.2 l-2.8 3.2 l0.6 -4.2 l-4.2 -0.4 l3.4 -2.6 l-2.6 -3.2 l4 1 Z" fill="#E53935" opacity="0.9"/>')
    g.append('</g>')
    return ''.join(g)


# --------------------------------------------------------------------------
# Front view: a worker standing in his harness (fit check), 170 px tall.
# --------------------------------------------------------------------------

def front_worker(cx, top, fit='ok', web='#F7811F', s=1.0):
    """Front view, canonical 170 units tall. The fit cards draw him waist-up
    (s ~ 1.65) so the harness fills the card."""
    g = [f'<g transform="translate({cx} {top}) scale({s})">']
    # Legs, boots.
    g.append(f'<path d="M-9 104 L-10 158 M9 104 L10 158" stroke="{PANTS}" stroke-width="13" stroke-linecap="round" fill="none"/>')
    g.append(f'<rect x="-21" y="156" width="17" height="9" rx="3.5" fill="{BOOT}"/><rect x="4" y="156" width="17" height="9" rx="3.5" fill="{BOOT}"/>')
    g.append(f'<path d="M-19 92 L19 92 L20 108 L-20 108 Z" fill="{PANTS}"/>')
    # Arms. Two cards have a hand at a strap (the right fit: four fingers
    # under it; the loose fit: a fist pulls it far off the chest), so a hand
    # at the chest is never the answer by itself.
    if fit == 'ok':
        g.append(f'<path d="M-20 42 L-27 64 L-19 66" stroke="{SHIRT}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    elif fit == 'loose':
        g.append(f'<path d="M-20 42 L-26 54 L-31 62" stroke="{SHIRT}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    else:
        g.append(f'<path d="M-20 42 L-27 90" stroke="{SHIRT}" stroke-width="9" stroke-linecap="round" fill="none"/>')
        g.append(f'<circle cx="-27" cy="93" r="4.6" fill="{SKIN}"/>')
    g.append(f'<path d="M20 42 L27 90" stroke="{SHIRT}" stroke-width="9" stroke-linecap="round" fill="none"/>')
    g.append(f'<circle cx="27" cy="93" r="4.6" fill="{SKIN}"/>')
    # Torso.
    g.append('<path d="M-21 39 Q0 34 21 39 L18 96 L-18 96 Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M-6 37 L0 46 L6 37" fill="none" stroke="{SHIRT_D}" stroke-width="1.6"/>')
    g.append(f'<path d="M0 46 L0 92" stroke="{SHIRT_D}" stroke-width="0.9" opacity="0.6"/>')
    # Neck, face, helmet with chin strap.
    g.append(f'<rect x="-4.5" y="31" width="9" height="8" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="0" cy="24" r="11" fill="{SKIN}"/>')
    g.append('<circle cx="-4" cy="24" r="1.4" fill="#2A1E16"/><circle cx="4" cy="24" r="1.4" fill="#2A1E16"/>')
    g.append('<path d="M-3.5 29 Q0 31.5 3.5 29" stroke="#5A3A26" stroke-width="1.3" fill="none" stroke-linecap="round"/>')
    g.append(f'<path d="M-15 18 A15 15 0 0 1 15 18 Z" fill="{HELMET}"/><path d="M-4 6 Q0 4 4 6 L3 17 L-3 17 Z" fill="#FFE68C" opacity="0.7"/>')
    g.append(f'<rect x="-17" y="16.5" width="34" height="4" rx="2" fill="{HELMET_D}"/>')
    g.append('<path d="M-11 20 Q-10 33 0 35 Q10 33 11 20" stroke="#3B3A36" stroke-width="1.2" fill="none"/>')

    # Webbing: 6 wide, with a pale centre line on its face so a strap that
    # turns over (twisted) shows its dark, line-less back.
    strap = f'stroke="{web}" stroke-width="6" fill="none" stroke-linejoin="round" stroke-linecap="round"'
    edge = 'stroke="#00000030" stroke-width="7.4" fill="none" stroke-linejoin="round" stroke-linecap="round"'
    face = 'stroke="#FFD3A1" stroke-width="0.9" fill="none" stroke-linejoin="round" stroke-dasharray="3 1.6"'

    def both(d, line=True):
        g.append(f'<path d="{d}" {edge}/><path d="{d}" {strap}/>')
        if line:
            g.append(f'<path d="{d}" {face}/>')

    def buckle(x, y):
        g.append(f'<rect x="{x - 5}" y="{y - 4.5}" width="10" height="9" rx="1.8" fill="none" stroke="url(#steel)" stroke-width="2.2"/>')

    def legs_ok():
        both('M-16 108 Q-9 115 -2 110')
        both('M2 110 Q9 115 16 108')

    if fit in ('ok', 'neck'):
        both('M-11 38 L-12 96 L-5 110')
        both('M11 38 L12 96 L5 110')
        legs_ok()
        cy = 62 if fit == 'ok' else 42
        both(f'M-12 {cy} L12 {cy}')
        buckle(0, cy)
        if fit == 'ok':
            # Four fingers slid under the left strap; the strap passes over them.
            g.append(f'<rect x="-22" y="63" width="9" height="11" rx="3.2" fill="{SKIN}"/>')
            for fy in (64.6, 67.2, 69.8, 72.4):
                g.append(f'<path d="M-15 {fy} L-6 {fy}" stroke="{SKIN}" stroke-width="2.3" stroke-linecap="round"/>')
                g.append(f'<path d="M-15 {fy + 1.15} L-7 {fy + 1.15}" stroke="{SKIN_D}" stroke-width="0.5"/>')
            g.append(f'<path d="M-11.6 61 L-11.8 78" stroke="{web}" stroke-width="6"/>')
            g.append(f'<path d="M-11.6 61 L-11.8 78" {face}/>')
            g.append('<path d="M-14.7 61 L-14.9 78 M-8.6 61 L-8.8 78" stroke="#00000030" stroke-width="0.8"/>')
    elif fit == 'twisted':
        both('M11 38 L12 96 L5 110')
        legs_ok()
        # The left strap turns over twice: face (with its centre line), a twist,
        # the dark back, a twist, face again.
        hw = 3.2
        x0, x1 = -11.0, -12.0

        def xat(y):
            return x0 + (x1 - x0) * (y - 38) / 58

        segs = [(38, 50, 'face'), (50, 60, 'twist'), (60, 74, 'back'), (74, 84, 'twist2'), (84, 96, 'face')]
        g.append(f'<path d="M{x0} 38 L{x1} 96" stroke="#00000030" stroke-width="{hw * 2 + 1.4}"/>')
        for ya, yb, kind in segs:
            xa, xb = xat(ya), xat(yb)
            if kind in ('face', 'back'):
                fill = web if kind == 'face' else 'url(#webUnder)'
                g.append(f'<path d="M{xa - hw} {ya} L{xa + hw} {ya} L{xb + hw} {yb} L{xb - hw} {yb} Z" fill="{fill}"/>')
                if kind == 'face':
                    g.append(f'<path d="M{xa} {ya} L{xb} {yb}" {face}/>')
            else:
                mid, xm = (ya + yb) / 2, (xa + xb) / 2
                top_fill, bot_fill = (web, 'url(#webUnder)') if kind == 'twist' else ('url(#webUnder)', web)
                g.append(f'<path d="M{xa - hw} {ya} L{xa + hw} {ya} L{xm} {mid} Z" fill="{top_fill}"/>')
                g.append(f'<path d="M{xm} {mid} L{xb + hw} {yb} L{xb - hw} {yb} Z" fill="{bot_fill}"/>')
                g.append(f'<path d="M{xa - hw} {ya} L{xb + hw} {yb} M{xa + hw} {ya} L{xb - hw} {yb}" stroke="#5A2804" stroke-width="0.8"/>')
                g.append(f'<path d="M{xm - 1.4} {mid} L{xm + 1.4} {mid}" stroke="#FFFFFF" stroke-opacity="0.7" stroke-width="0.8"/>')
        both('M-12 96 L-5 110')
        both('M-12 62 L12 62')
        buckle(0, 62)
    elif fit == 'loose':
        # Straps bow off the body, the chest strap droops low, the leg loops
        # sag; his fist pulls the left strap a hand's width off his chest.
        both('M-17 40 Q-46 64 -15 96 L-8 124')
        both('M17 40 Q26 66 15 96 L8 124')
        both('M-19 122 Q-10 134 -2 124')
        both('M2 124 Q10 134 19 122')
        both('M-22 70 Q0 90 22 70')
        buckle(0, 80)
        g.append(f'<circle cx="-31" cy="65" r="5.6" fill="{SKIN}"/><path d="M-34.5 62.5 L-27.5 62.5 M-35 65 L-27 65 M-34.5 67.5 L-27.5 67.5" stroke="{SKIN_D}" stroke-width="0.7"/>')
    g.append('</g>')
    return ''.join(g)


# --------------------------------------------------------------------------
# Workbench close-ups: the 3-minute check, strap in two hands.
# --------------------------------------------------------------------------

def bench_open():
    out = card_open('bench')
    out.append(''.join(f'<path d="M0 {y} L200 {y}" stroke="#7E5229" stroke-width="1.4" opacity="0.55"/>' for y in (44, 98, 152, 206)))
    out.append('<g stroke="#8A5A2E" stroke-width="0.8" fill="none" opacity="0.35">'
               '<path d="M10 20 Q60 14 120 22 T200 18"/><path d="M0 70 Q50 64 110 74 T200 66"/>'
               '<path d="M6 126 Q70 118 130 128 T200 122"/><path d="M0 180 Q60 174 120 184 T200 178"/></g>')
    return out


def hands_on_strap(y0, y1):
    """Two fists grip the strap ends and pull it taut (sleeves at the edges)."""
    mid = (y0 + y1) / 2
    s = []
    for side in (-1, 1):
        hx = 18 if side < 0 else 182
        cuff_x = -12 if side < 0 else 192
        s.append(f'<rect x="{cuff_x}" y="{mid - 22}" width="20" height="44" rx="7" fill="url(#shirt)"/>')
        s.append(f'<rect x="{hx - 13}" y="{y0 - 8}" width="26" height="{y1 - y0 + 16}" rx="11" fill="{SKIN}"/>')
        kx = hx - 13 if side > 0 else hx + 13
        for k in range(4):
            fy = y0 - 4 + (k + 0.5) * (y1 - y0 + 8) / 4
            s.append(f'<path d="M{hx - 8} {fy} L{hx + 8} {fy}" stroke="{SKIN_D}" stroke-width="1.2" opacity="0.8"/>')
            s.append(f'<circle cx="{kx}" cy="{fy}" r="1.6" fill="{SKIN_D}" opacity="0.5"/>')
        s.append(f'<ellipse cx="{hx + 4 * side}" cy="{y0 - 5}" rx="9" ry="5" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.8"/>')
    return ''.join(s)


def strap_band(y0, y1, fill='url(#webO)', edge='#B5540A'):
    return (f'<rect x="-4" y="{y0 + 3}" width="208" height="{y1 - y0}" fill="#000000" opacity="0.18"/>'
            f'<rect x="-4" y="{y0}" width="208" height="{y1 - y0}" fill="{fill}"/>'
            f'<path d="M-4 {y0 + 2} L204 {y0 + 2} M-4 {y1 - 2} L204 {y1 - 2}" stroke="{edge}" stroke-width="1.2"/>'
            + ''.join(f'<path d="M-4 {y} L204 {y}" stroke="#FFFFFF" stroke-opacity="0.12" stroke-width="0.7"/>'
                      for y in range(int(y0) + 6, int(y1) - 4, 4)))


def overlap(x0, x1, y0, y1, fill='url(#webO)'):
    return (f'<rect x="{x0 + 2}" y="{y0 + 3}" width="{x1 - x0}" height="{y1 - y0}" fill="#000000" opacity="0.2"/>'
            f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="{fill}"/>')


def box_x(x0, x1, y0, y1, broken=False):
    """The box-and-cross stitch that joins two layers of webbing."""
    st = f'stroke="{THREAD}" stroke-width="1.5" stroke-dasharray="2.6 1.6" fill="none" stroke-linecap="round"'
    if not broken:
        return (f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" {st}/>'
                f'<path d="M{x0} {y0} L{x1} {y1} M{x1} {y0} L{x0} {y1}" {st}/>')
    s = [f'<path d="M{x0} {y1} L{x0} {y0} L{x0 + (x1 - x0) * 0.42} {y0}" {st}/>',
         f'<path d="M{x0} {y1} L{x0 + (x1 - x0) * 0.35} {y1}" {st}/>',
         f'<path d="M{x0} {y0} L{x0 + (x1 - x0) * 0.4} {y0 + (y1 - y0) * 0.4}" {st}/>',
         f'<path d="M{x0} {y1} L{x0 + (x1 - x0) * 0.3} {y1 - (y1 - y0) * 0.3}" {st}/>']
    # Broken thread ends curl out where the stitch has let go.
    for ex, ey, dx, dy in ((x0 + (x1 - x0) * 0.42, y0, 7, -9), (x0 + (x1 - x0) * 0.35, y1, 8, 8),
                           (x0 + (x1 - x0) * 0.4, y0 + (y1 - y0) * 0.4, 9, -3), (x1, y0 + 3, 6, -10), (x1 - 3, y1 - 2, 9, 6)):
        s.append(f'<path d="M{ex} {ey} q{dx * 0.6} {dy * 0.2} {dx} {dy}" stroke="{THREAD}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')
    return ''.join(s)


def web_card(kind):
    out = bench_open()
    y0, y1 = 80, 142
    fill, edge = 'url(#webO)', '#B5540A'
    out.append(strap_band(y0, y1, fill, edge))
    ox0, ox1 = 42, 104
    if kind == 'stitch':
        # The stitch has let go: the top layer lifts away and a dark gap opens.
        out.append(f'<path d="M{ox1 - 18} {y0 - 2} L{ox1 + 12} {y0 - 16} L{ox1 + 14} {y1 - 20} L{ox1 - 18} {y1 + 2} Z" fill="#000000" opacity="0.32"/>')
        out.append(f'<path d="M{ox0} {y0 - 2} L{ox1 - 20} {y0 - 2} L{ox1 + 8} {y0 - 18} L{ox1 + 10} {y1 - 22} L{ox1 - 20} {y1 + 2} L{ox0} {y1 + 2} Z" fill="{fill}"/>')
        out.append(f'<path d="M{ox1 + 8} {y0 - 18} L{ox1 + 10} {y1 - 22}" stroke="{edge}" stroke-width="1.4"/>')
        out.append(box_x(ox0 + 6, ox1 - 6, y0 + 5, y1 - 5, broken=True))
    else:
        out.append(overlap(ox0, ox1, y0 - 2, y1 + 2, fill))
        out.append(box_x(ox0 + 6, ox1 - 6, y0 + 5, y1 - 5))
    if kind in ('ok2', 'stitch'):
        # A buckle on the strap (intact). It is on a trap too, so a buckle
        # never marks the safe card.
        out.append(f'<rect x="126" y="{y0 - 8}" width="30" height="{y1 - y0 + 16}" rx="5" fill="none" stroke="#00000040" stroke-width="7" transform="translate(2 3)"/>')
        out.append(f'<rect x="126" y="{y0 - 8}" width="30" height="{y1 - y0 + 16}" rx="5" fill="none" stroke="url(#steel)" stroke-width="6"/>')
        out.append(f'<rect x="138" y="{y0 - 6}" width="6" height="{y1 - y0 + 12}" rx="2" fill="url(#steel)"/>')
    elif kind == 'cut':
        out.append(f'<path d="M132 {y0 - 0.5} L145 {y0 + 26} L158 {y0 - 0.5} Z" fill="url(#bench)"/>')
        out.append(f'<path d="M132 {y0} L145 {y0 + 26} L158 {y0}" stroke="#9C4A0A" stroke-width="1.2" fill="none"/>')
        out.append(''.join(f'<path d="M{x} {y0 + d} l{dx} {-5 - d * 0.15}" stroke="#FFD2A0" stroke-width="1.1" stroke-linecap="round"/>'
                           for x, d, dx in ((134, 4, -3), (137, 10, -2.6), (140, 16, -2.2), (143, 22, -1.6), (147, 22, 1.6), (150, 16, 2.2), (153, 10, 2.6), (156, 4, 3))))
        out.append(f'<path d="M150 {y1 + 0.5} L156 {y1 - 12} L162 {y1 + 0.5} Z" fill="url(#bench)"/>')
        out.append(''.join(f'<path d="M{x} {y1 - d} l{dx} 4" stroke="#FFD2A0" stroke-width="1" stroke-linecap="round"/>' for x, d, dx in ((152, 4, -2), (154, 8, -1.4), (158, 8, 1.4), (160, 4, 2))))
    elif kind == 'burn':
        out.append('<ellipse cx="146" cy="111" rx="26" ry="21" fill="url(#burn)"/>')
        out.append('<path d="M132 104 Q142 94 156 101 Q163 112 153 121 Q140 125 134 116 Z" fill="#1C120B"/>')
        out.append('<path d="M138 103 Q145 99 152 103" stroke="#FFFFFF" stroke-opacity="0.35" stroke-width="1.3" fill="none"/>')
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#2A1A10" opacity="0.8"/>' for x, y, r in ((120, 96, 1.8), (170, 124, 1.5), (166, 94, 1.2), (124, 128, 1.1))))
    elif kind == 'chem':
        out.append('<path d="M124 90 Q140 84 158 92 Q174 100 170 116 Q166 134 146 134 Q126 133 120 118 Q114 100 124 90 Z" fill="#C9B04A" opacity="0.92"/>')
        out.append('<path d="M132 98 Q146 93 158 100 Q163 112 154 122 Q140 126 133 118 Z" fill="#E6DA94" opacity="0.88"/>')
        out.append('<path d="M140 134 L141 150 M156 132 L158 146" stroke="#B9A540" stroke-width="2.4" stroke-linecap="round" opacity="0.85"/>')
        # The tipped bottle and its puddle on the bench.
        out.append('<ellipse cx="130" cy="186" rx="34" ry="8" fill="#C9D88A" opacity="0.55"/>')
        out.append('<g transform="translate(116 182) rotate(-72)"><rect x="-10" y="-34" width="20" height="34" rx="4" fill="#6E4A2C"/>'
                   '<rect x="-4.5" y="-43" width="9" height="10" rx="1.5" fill="#2F3A45"/>'
                   '<path d="M0 -27 L7 -17 L0 -7 L-7 -17 Z" fill="#FFFFFF"/><path d="M0 -23 L3.6 -17 L0 -11 L-3.6 -17 Z" fill="#E53935"/></g>')
    out.append(hands_on_strap(y0, y1))
    return card_close(out, vignette=True)


def dring_card(kind):
    out = bench_open()
    # Webbing straps run into the back pad from above and below.
    out.append('<path d="M40 214 L86 150 M160 214 L114 150" stroke="#00000030" stroke-width="20"/>')
    out.append('<path d="M40 214 L86 150 M160 214 L114 150" stroke="#F7811F" stroke-width="17"/>')
    out.append('<path d="M60 -4 L88 110 M140 -4 L112 110" stroke="#00000030" stroke-width="20"/>')
    out.append('<path d="M60 -4 L88 110 M140 -4 L112 110" stroke="#F7811F" stroke-width="17"/>')
    out.append('<rect x="62" y="108" width="76" height="58" rx="12" fill="url(#pad)"/>')
    out.append('<rect x="67" y="113" width="66" height="48" rx="9" fill="none" stroke="#5A616A" stroke-width="1.2" stroke-dasharray="2.4 1.6"/>')
    # The D-ring.
    ring = 'M74 120 L126 120 Q126 70 100 62 Q74 70 74 120 Z'
    out.append(f'<path d="{ring}" fill="none" stroke="#00000040" stroke-width="12" transform="translate(2 3)"/>')
    out.append(f'<path d="{ring}" fill="none" stroke="url(#steel)" stroke-width="10"/>')
    out.append('<path d="M80 74 Q90 66 100 65" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.8"/>')
    if kind == 'crack':
        out.append('<path d="M117 86 L123 90 L120 94 L127 96 L124 100 L133 103" stroke="#1E2328" stroke-width="4.4" fill="none" stroke-linejoin="round"/>')
        out.append('<path d="M120 94 L114 99 M127 96 L131 91" stroke="#1E2328" stroke-width="2" fill="none"/>')
        out.append('<path d="M119 91 L124 94 L122 97 L128 99" stroke="#FFFFFF" stroke-width="0.9" fill="none" opacity="0.6"/>')
        out.append('<path d="M84 72 L88 76 L86 79" stroke="#1E2328" stroke-width="2" fill="none"/>')
    elif kind == 'rust':
        for x, y, rx, ry in ((88, 66, 9, 5), (118, 82, 6, 9), (124, 108, 5, 8), (78, 104, 6, 8), (104, 120, 9, 4), (76, 82, 4, 6)):
            out.append(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="#9C4A1A" opacity="0.88"/>')
            out.append(f'<ellipse cx="{x + 1}" cy="{y - 1}" rx="{rx * 0.5}" ry="{ry * 0.5}" fill="#C8662A" opacity="0.9"/>')
        out.append(''.join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#A0522D"/>' for x, y, r in ((140, 132, 1.6), (146, 140, 1.1), (58, 126, 1.3), (150, 124, 0.9))))
    return card_close(out, vignette=True)


def buckle_card():
    out = bench_open()
    out.append(strap_band(92, 132))
    out.append(overlap(36, 80, 90, 134))
    out.append(box_x(42, 74, 95, 129))
    # A buckle bent out of shape: one side kinked in, the bar bowed.
    frame = 'M92 80 L138 84 Q150 104 132 112 Q148 124 138 142 L92 144 Q84 112 92 80 Z'
    out.append(f'<path d="{frame}" fill="none" stroke="#00000040" stroke-width="8" transform="translate(2 3)"/>')
    out.append(f'<path d="{frame}" fill="none" stroke="url(#steel)" stroke-width="7" stroke-linejoin="round"/>')
    out.append('<path d="M114 82 Q128 112 110 143" stroke="url(#steel)" stroke-width="5" fill="none"/>')
    out.append('<path d="M96 86 Q100 84 106 85" stroke="#FFFFFF" stroke-width="1.6" fill="none" opacity="0.7"/>')
    out.append('<path d="M132 112 l-5 -2 M131 118 l-4 1" stroke="#3A4148" stroke-width="1.2"/>')
    return card_close(out, vignette=True)


def label_card(expired=False):
    out = bench_open()
    out.append(strap_band(52, 168))
    # Both labels look equally new: an expired harness can still look strong
    # (lesson 1.4 myth 2), so only the printed date tells them apart.
    fill = 'url(#tag)'
    out.append('<rect x="44" y="64" width="112" height="92" rx="4" fill="#000000" opacity="0.18" transform="translate(2 3)"/>')
    out.append(f'<rect x="44" y="64" width="112" height="92" rx="4" fill="{fill}"/>')
    out.append('<rect x="47" y="67" width="106" height="86" rx="3" fill="none" stroke="#5A616A" stroke-width="1" stroke-dasharray="2.2 1.6"/>')
    # Maker's mark and the rest of the label (pictogram, small print bars).
    out.append('<rect x="54" y="74" width="26" height="18" rx="3" fill="#1F2A36"/>')
    out.append('<path d="M62 78 a2.4 2.4 0 1 0 0.01 0 M62 81 L62 88 M58 82 L66 82 M62 88 L59 91 M62 88 L65 91" stroke="#F2BE22" stroke-width="1.4" fill="none"/>')
    out.append(''.join(f'<rect x="86" y="{y}" width="{w}" height="3" rx="1.5" fill="#9AA5AD"/>' for y, w in ((76, 60), (82, 48), (88, 54))))
    made, exp = ('01/2014', '01/2024') if expired else ('03/2025', '03/2035')
    ink = '#1F2A36'
    out.append(f'<text x="54" y="112" font-family="sans-serif" font-size="12" font-weight="700" letter-spacing="-0.3" fill="{ink}">MFD {made}</text>')
    out.append(f'<text x="54" y="136" font-family="sans-serif" font-size="14" font-weight="800" letter-spacing="-0.3" fill="{ink}">EXP {exp}</text>')
    out.append(''.join(f'<rect x="54" y="{y}" width="{w}" height="2.4" rx="1.2" fill="#B9C2C9"/>' for y, w in ((142, 92), (147, 70))))
    return card_close(out, vignette=True)


# --------------------------------------------------------------------------
# Scenes on the pole.
# --------------------------------------------------------------------------

def pole_scene_type(kind):
    """Round 1: a worker climbing a pole — what keeps him if he slips?

    Every card in a round shares one sky and one harness colour, so only the
    gear itself tells the safe card from a trap."""
    reach = kind == 'fbh2'
    out = card_open('sky')
    out.append(clouds(150, 52, 0.9) + clouds(30, 118, 0.7) if reach else clouds(34, 64) + clouds(150, 96, 0.8))
    out.append(f'<rect y="196" width="{W}" height="24" fill="url(#ground)"/>')
    out.append(trees(197))
    out.append(pole_full(100, 16, 0, 200))
    out.append(cross_arm(26))
    out.append(insulator(36, 26) + insulator(164, 26))
    out.append(wires(8))
    out.append(step_bolts(100, (150, 178)))
    if kind in ('fbh', 'fbh2'):
        out.append(sling(100, 46))
        worker, (dx, dy) = back_worker(100, 80, 0.92, harness='fbh', arms='reach' if reach else 'climb')
        out.append(worker)
        out.append(lanyard(f'M{dx} {dy} Q{dx + 22} {dy - 22} 111 59', absorber_at=(dx + 13, dy - 18, 40)))
        out.append(snap_hook(111, 58, 10))
    elif kind == 'belt':
        worker, _ = back_worker(100, 80, 0.92, harness='belt')
        out.append(worker)
    elif kind == 'none':
        worker, _ = back_worker(100, 80, 0.92, harness='none', arms='reach')
        out.append(worker)
    return card_close(out)


def fall_scene(kind):
    """Round 1: he slipped high on the pole and the lanyard caught him.

    No ground in the frame: his boots dangle over open air, his dropped
    spanner is still falling and his legs swing — a fall, not a man standing."""
    out = card_open('sky')
    out.append(clouds(156, 204, 1.2) + clouds(30, 178, 0.8) + clouds(176, 92, 0.6))
    px = 134
    out.append(pole_full(px, 16, 0, 224))
    out.append(step_bolts(px, (96, 136, 176)))
    out.append(f'<rect x="60" y="14" width="148" height="7" rx="1.5" fill="url(#steelArm)"/>')
    out.append(f'<path d="M{px} 21 L{px - 16} 40 M{px} 21 L{px + 16} 40" stroke="#5F676F" stroke-width="2.6"/>')
    out.append(insulator(74, 14) + insulator(196, 14))
    out.append(f'<path d="M-4 0 Q 30 6 74 -1" stroke="#2B3138" stroke-width="2" fill="none"/>')
    out.append(sling(px, 34))
    hx, hy = px + 8 + 3, 34 + 9
    out.append(snap_hook(hx, hy + 4, -20))
    if kind == 'fbh':
        # Caught upright by the back D-ring, legs swinging.
        out.append(lanyard(f'M{hx} {hy + 6} Q{hx - 14} {hy + 22} 98 70', absorber_at=(122, 57, 52)))
        out.append(hang_worker(96, 72, 1.2))
        out.append('<g stroke="#FFFFFF" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.9">'
                   '<path d="M84 150 q-7 11 -1 22"/><path d="M78 154 q-5 8 0 15"/><path d="M128 152 q6 10 0 20"/></g>')
    else:
        # Jack-knifed over the waist belt: the same lanyard, the belly takes it all.
        out.append(lanyard(f'M{hx} {hy + 6} Q{hx - 6} {hy + 30} 104 90', absorber_at=(130, 66, 30)))
        out.append(belt_fall_worker(104, 94))
        out.append('<g stroke="#FFFFFF" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.9">'
                   '<path d="M82 128 q-7 11 -1 22"/><path d="M76 132 q-5 8 0 15"/></g>')
    # The dropped spanner, still falling, with speed lines above it.
    out.append('<g transform="translate(64 196) rotate(-30)"><rect x="-11" y="-2" width="22" height="4" rx="2" fill="#7D868E"/>'
               '<circle cx="-11" cy="0" r="3.8" fill="none" stroke="#7D868E" stroke-width="2.4"/></g>')
    out.append('<path d="M58 168 L58 182 M66 164 L66 180 M72 170 L72 184" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.85"/>')
    return card_close(out)


def anchor_scene(kind):
    """Round 5: at the pole top — where does the lanyard's hook go?"""
    reach = kind == 'sling2'
    out = card_open('sky')
    out.append(clouds(160, 128, 0.8) if reach else clouds(30, 110, 0.8))
    out.append(pole_full(100, 18, 0, 224))
    arm_y = 42
    if kind == 'broken':
        # A wooden cross-arm split near the pole; its far half sags.
        out.append(f'<rect x="20" y="{arm_y}" width="72" height="8" rx="1.5" fill="url(#woodArm)"/>')
        out.append(f'<path d="M108 {arm_y} L134 {arm_y + 1} L178 {arm_y + 16} L176 {arm_y + 24} L132 {arm_y + 9} L108 {arm_y + 8} Z" fill="url(#woodArm)"/>')
        out.append(f'<path d="M110 {arm_y + 1} L116 {arm_y + 5} L113 {arm_y + 7} L122 {arm_y + 6} L120 {arm_y + 9}" stroke="#2A1A0E" stroke-width="1.8" fill="none"/>')
        out.append(f'<path d="M126 {arm_y + 1} L132 {arm_y + 4} L129 {arm_y + 8}" stroke="#2A1A0E" stroke-width="1.6" fill="none"/>')
        out.append(''.join(f'<path d="M{x} {y} l{dx} 3" stroke="#3A2614" stroke-width="0.9"/>' for x, y, dx in ((40, arm_y + 3, 10), (60, arm_y + 5, 12), (150, arm_y + 12, 10))))
        out.append(insulator(32, arm_y))
        out.append(f'<g transform="rotate(19 166 {arm_y + 14})">{insulator(166, arm_y + 14)}</g>')
        out.append(f'<path d="M-4 {arm_y - 14} Q14 {arm_y - 10} 32 {arm_y - 17}" stroke="#2B3138" stroke-width="2" fill="none"/>')
        out.append(f'<path d="M160 {arm_y - 2} Q180 {arm_y + 4} 204 {arm_y - 6}" stroke="#2B3138" stroke-width="2" fill="none"/>')
    else:
        out.append(f'<rect x="18" y="{arm_y}" width="164" height="8" rx="1.5" fill="url(#steelArm)"/>')
        out.append(f'<path d="M100 {arm_y + 8} L82 {arm_y + 30} M100 {arm_y + 8} L118 {arm_y + 30}" stroke="#5F676F" stroke-width="2.8"/>')
        out.append(insulator(32, arm_y) + insulator(168, arm_y))
        out.append(f'<path d="M-4 {arm_y - 14} Q14 {arm_y - 10} 32 {arm_y - 17}" stroke="#2B3138" stroke-width="2" fill="none"/>')
        out.append(f'<path d="M168 {arm_y - 17} Q186 {arm_y - 10} 204 {arm_y - 14}" stroke="#2B3138" stroke-width="2" fill="none"/>')
    out.append(step_bolts(100, (184, 210), 18))
    worker, (dx, dy) = back_worker(100, 98, 1.12, harness='fbh', arms='reach' if reach else 'climb')
    if kind in ('sling', 'sling2'):
        out.append(sling(100, 62, 18))
        out.append(worker)
        out.append(lanyard(f'M{dx} {dy} Q{dx + 22} {dy - 30} 112 78', absorber_at=(dx + 13, dy - 22, 30)))
        out.append(snap_hook(112, 77, 8))
    elif kind == 'broken':
        out.append(worker)
        out.append(lanyard(f'M{dx} {dy} Q{dx + 40} {dy - 40} 150 {arm_y + 22}', absorber_at=(dx + 16, dy - 20, 48)))
        out.append(snap_hook(152, arm_y + 18, -20))
    elif kind == 'pin':
        out.append(worker)
        out.append(lanyard(f'M{dx} {dy} Q{dx + 54} {dy - 30} 166 {arm_y - 2}', absorber_at=(dx + 18, dy - 16, 60)))
        out.append(snap_hook(166, arm_y - 7, -30))
    elif kind == 'none':
        out.append(worker)
        out.append(lanyard(f'M{dx} {dy} Q{dx + 18} {dy + 30} {dx + 14} {dy + 68}', absorber_at=(dx + 10, dy + 16, -10)))
        out.append(snap_hook(dx + 14, dy + 70, 180))
    return card_close(out)


def rescue_scene(kind):
    """Round 6: a mate hangs in his harness after a fall — what now?"""
    out = card_open('sky')
    out.append(clouds(40, 40, 0.8))
    gy = 194
    out.append(f'<rect y="{gy}" width="{W}" height="{H - gy}" fill="url(#ground)"/>')
    out.append(trees(gy + 1))
    out.append(pole_full(150, 15, 0, gy + 3))
    out.append(cross_arm(18, 96, 204))
    out.append(insulator(110, 18) + insulator(196, 18))
    out.append(sling(150, 34, 15))
    out.append(lanyard('M160 43 Q148 62 118 70', absorber_at=(142, 62, 62)))
    out.append(snap_hook(160, 42, -20))
    out.append(hang_worker(116, 72, 1.05, limp=True, hold=False))

    def mate(x, y, pose='stand', s=0.9, face=1):
        g = [f'<g transform="translate({x} {y}) scale({s * face} {s})">']
        if pose == 'run':
            g.append(f'<path d="M-2 30 L-12 42 L-18 52 M2 30 L10 40 L18 46" stroke="{PANTS}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append(f'<path d="M-4 8 L4 30" stroke="{SHIRT}" stroke-width="10" stroke-linecap="round"/>')
            g.append(f'<path d="M0 12 L12 18 L18 10" stroke="{SHIRT}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append(f'<circle cx="-4" cy="0" r="6" fill="{SKIN}"/><path d="M-11 -1 A7 7 0 0 1 3 -1 Z" fill="{HELMET}"/>')
        elif pose == 'sit':
            g.append(f'<path d="M-2 28 L12 28 L12 44" stroke="{PANTS}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append(f'<rect x="-6" y="6" width="11" height="24" rx="4" fill="{SHIRT}"/>')
            g.append(f'<path d="M2 12 L10 18 L12 12" stroke="{SHIRT}" stroke-width="4.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append('<rect x="10" y="7" width="5" height="6" rx="1" fill="#FFFFFF"/><path d="M12 5 q2 -3 0 -6 M14 5 q2 -3 0 -6" stroke="#FFFFFF" stroke-width="0.9" fill="none" opacity="0.8"/>')
            g.append(f'<circle cx="0" cy="0" r="6" fill="{SKIN}"/>')
        elif pose == 'arms':
            g.append(f'<path d="M-3 30 L-4 52 M3 30 L4 52" stroke="{PANTS}" stroke-width="6.5" stroke-linecap="round" fill="none"/>')
            g.append(f'<rect x="-7" y="6" width="14" height="26" rx="4" fill="{SHIRT}"/>')
            g.append(f'<path d="M-7 14 L6 18 M7 14 L-6 18" stroke="{SHIRT_D}" stroke-width="4.4" stroke-linecap="round"/>')
            g.append(f'<circle cx="0" cy="0" r="6" fill="{SKIN}"/><path d="M-7 -1 A7 7 0 0 1 7 -1 Z" fill="{HELMET}"/>')
        elif pose == 'phone':
            # Standing still, a phone at his ear: he only calls and waits.
            g.append(f'<path d="M-3 30 L-4 52 M3 30 L4 52" stroke="{PANTS}" stroke-width="6.5" stroke-linecap="round" fill="none"/>')
            g.append(f'<rect x="-7" y="6" width="14" height="26" rx="4" fill="{SHIRT}"/>')
            g.append(f'<path d="M-6 10 L-8 30" stroke="{SHIRT_D}" stroke-width="4.4" stroke-linecap="round"/>')
            g.append(f'<path d="M6 10 L11 18 L7 2" stroke="{SHIRT_D}" stroke-width="4.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append(f'<circle cx="0" cy="0" r="6" fill="{SKIN}"/><path d="M-7 -1 A7 7 0 0 1 7 -1 Z" fill="{HELMET}"/>')
            g.append('<rect x="4.5" y="-3" width="4" height="8" rx="1" fill="#1C1F24"/>')
            g.append('<path d="M11 -6 q3 3 0 6 M14 -8 q5 5 0 10" stroke="#FFFFFF" stroke-width="1.1" fill="none" stroke-linecap="round" opacity="0.9"/>')
        elif pose == 'climb':
            g.append(f'<path d="M-2 30 L4 40 L0 50 M2 30 L-4 38 L-8 46" stroke="{PANTS}" stroke-width="6.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
            g.append(f'<rect x="-6" y="6" width="12" height="26" rx="4" fill="{SHIRT}" transform="rotate(14 0 18)"/>')
            g.append(f'<path d="M4 10 L12 -2 L16 -14" stroke="{SHIRT}" stroke-width="4.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/><circle cx="16" cy="-15" r="2.6" fill="{SKIN}"/>')
            g.append(f'<circle cx="2" cy="0" r="6" fill="{SKIN}"/><path d="M-5 -1 A7 7 0 0 1 9 -1 Z" fill="{HELMET}"/>')
        g.append('</g>')
        return ''.join(g)

    if kind == 'ladder':
        out.append('<path d="M62 196 L134 104 M74 198 L144 108" stroke="#B0B7BD" stroke-width="3"/>')
        out.append(''.join(f'<line x1="{62 + 72 * f}" y1="{196 - 92 * f}" x2="{74 + 70 * f}" y2="{198 - 90 * f}" stroke="#B0B7BD" stroke-width="2.2"/>' for f in [i / 10 for i in range(1, 10)]))
        out.append(mate(92, 138, 'climb', 0.95))
    elif kind == 'run':
        out.append('<g transform="rotate(-4 60 170)"><path d="M14 166 L104 166 M14 176 L104 176" stroke="#B0B7BD" stroke-width="3"/>'
                   + ''.join(f'<line x1="{x}" y1="166" x2="{x}" y2="176" stroke="#B0B7BD" stroke-width="2.2"/>' for x in range(22, 104, 11)) + '</g>')
        out.append(mate(36, 146, 'run', 0.95) + mate(88, 142, 'run', 0.95))
        out.append('<path d="M2 150 L14 150 M0 160 L10 160 M54 146 L64 146" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.8"/>')
    elif kind == 'tea':
        # A tea stall at the edge of the frame: awning, bench, two mates with cups.
        out.append('<rect x="-4" y="120" width="70" height="76" fill="#8A6440"/>')
        out.append('<path d="M-6 112 L72 112 L80 128 L-6 128 Z" fill="#D94F3A"/>')
        out.append(''.join(f'<path d="M{x} 112 L{x + 9} 112 L{x + 18} 128 L{x + 9} 128 Z" fill="#F5E6C8"/>' for x in (0, 18, 36, 54)))
        out.append('<rect x="4" y="136" width="22" height="14" rx="2" fill="#C9965E"/><rect x="34" y="140" width="10" height="10" rx="2" fill="#5E4128"/>')
        out.append('<rect x="56" y="178" width="66" height="5" rx="2" fill="#6E4A2C"/><path d="M62 183 L62 194 M116 183 L116 194" stroke="#6E4A2C" stroke-width="3"/>')
        out.append(mate(70, 150, 'sit', 0.9) + mate(98, 150, 'sit', 0.9))
    elif kind == 'phone':
        out.append(mate(74, 140, 'phone', 1.0))
    elif kind == 'watch':
        # The ladder lies right there on the ground; they only stand and watch.
        out.append(mate(70, 140, 'arms', 0.95) + mate(104, 142, 'arms', 0.9))
        out.append('<path d="M8 200 L98 203 M6 209 L96 212" stroke="#00000030" stroke-width="4"/>'
                   '<path d="M8 199 L98 202 M6 208 L96 211" stroke="#B0B7BD" stroke-width="3"/>'
                   + ''.join(f'<line x1="{x}" y1="{199 + (x - 8) * 3 / 90}" x2="{x - 2}" y2="{208 + (x - 8) * 3 / 90}" stroke="#B0B7BD" stroke-width="2.2"/>' for x in range(16, 98, 11)))
    return card_close(out)


def fit_scene(kind):
    """Round 4: harness on, checked in the yard — whose fit is right?

    Drawn waist-up so the harness fills the card at phone size."""
    out = card_open('sky')
    out.append(clouds(30, 30, 0.8) + clouds(172, 58, 0.7))
    out.append('<rect x="172" y="0" width="10" height="220" fill="url(#pole)" opacity="0.8"/>')
    if kind in ('back', 'dring_low'):
        worker, _ = back_worker(100, 6, 2.15, harness='fbh', arms='down', legs='stand', dring_low=kind == 'dring_low')
        out.append(worker)
    else:
        out.append(front_worker(100, 2, kind, s=1.65))
    return card_close(out)


CARDS = {
    # Round 1 — which kit stops a fall (waist belt = work positioning only).
    'type_fbh': pole_scene_type('fbh'),
    'type_fbh_reach': pole_scene_type('fbh2'),
    'type_fall_fbh': fall_scene('fbh'),
    'type_belt': pole_scene_type('belt'),
    'type_fall_belt': fall_scene('belt'),
    'type_none': pole_scene_type('none'),
    # Round 2 — the 3-minute check: webbing and stitching.
    'web_ok': web_card('ok'),
    'web_ok_buckle': web_card('ok2'),
    'web_cut': web_card('cut'),
    'web_burn': web_card('burn'),
    'web_chem': web_card('chem'),
    'web_stitch': web_card('stitch'),
    # Round 3 — the 3-minute check: hardware and label.
    'hw_dring_ok': dring_card('ok'),
    'hw_label_ok': label_card(False),
    'hw_dring_crack': dring_card('crack'),
    'hw_dring_rust': dring_card('rust'),
    'hw_buckle_bent': buckle_card(),
    'hw_label_expired': label_card(True),
    # Round 4 — fit (waist-up).
    'fit_ok': fit_scene('ok'),
    'fit_back_ok': fit_scene('back'),
    'fit_neck': fit_scene('neck'),
    'fit_twisted': fit_scene('twisted'),
    'fit_loose': fit_scene('loose'),
    'fit_dring_low': fit_scene('dring_low'),
    # Round 5 — the anchor.
    'anc_sling': anchor_scene('sling'),
    'anc_sling_reach': anchor_scene('sling2'),
    'anc_broken_arm': anchor_scene('broken'),
    'anc_pin': anchor_scene('pin'),
    'anc_none': anchor_scene('none'),
    # Round 6 — suspension trauma: rescue at once.
    'rescue_ladder': rescue_scene('ladder'),
    'rescue_run': rescue_scene('run'),
    'rescue_tea': rescue_scene('tea'),
    'rescue_phone': rescue_scene('phone'),
    'rescue_watch': rescue_scene('watch'),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
