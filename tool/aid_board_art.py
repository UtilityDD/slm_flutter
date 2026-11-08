"""Picture cards for ladder step 19 (lesson 1.7 শেখা, "শক লাগলে ফার্স্ট এইড").

python -I tool/aid_board_art.py .

Writes assets/game/art/aid_board/*.svg in the same clean gradient style as
tool/rod_board_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art; the only writing is what a worker reads on the job: ON / OFF on
the MCB (and a "?" / "!" in a speech bubble). Non-graphic on purpose: no wounds, no burns, no gore — a shocked
colleague is shown stiff at the wire with a spark at his hand, a collapsed
one lying with closed eyes.

What the cards show comes from lesson 1.7 only:
  1. never touch the victim — his body is a live wire and you join the
     circuit; first switch the source off (a nearby switch / MCB, or phone
     the substation / control room); stay calm, panic ruins decisions;
  2. if the source cannot be switched off, separate him with a dry
     non-conductor — dry wood, bamboo, a plastic chair, a fibreglass hot
     stick (traps: a soaked stick dripping over a spilt bucket, an iron
     rod, an aluminium ladder);
  3. push on the arm or the leg, never the chest or the head (the arm is
     thrown straight out at shoulder height, so an arm push ends in the open
     air, well clear of the chest — asserted below);
  4. once the danger is gone: tap the shoulder and ask loudly "আপনি ঠিক
     আছেন?"; send someone to call the ambulance (traps: burying in mud — the
     lesson's myth; standing about waiting for the ambulance; leaving him
     alone). No CPR card: the lesson gives CPR only when he does not respond
     and is not breathing, and that order is step 21's job;
  5. no ice, water or ointment on a burn, and hospital even if he talks.

Fairness (the playbook, section 4, and the step-10/13 reviews): every card
in a round shares one sky, one victim, one helper and the same props; any
colour a safe card draws is drawn by the traps of every hand too, so only
the act (what the helper does, with what, where) tells them apart.
"""

import math
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'aid_board')
W, H = 200, 220
GY = 196  # ground line

SHIRT = '#1F5F8F'      # the helper (the player's worker)
VSHIRT = '#2E7D6E'     # the colleague in trouble
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
WIRE = '#2B3138'
INK = '#1B2430'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="wall" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E4D3B4"/><stop offset="1" stop-color="#CDB894"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9C5B3B"/><stop offset="1" stop-color="#7A432A"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB6BD"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="shirtV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#256A5D"/><stop offset="0.5" stop-color="#3A9483"/><stop offset="1" stop-color="#22604F"/></linearGradient>
  <linearGradient id="bamboo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E8D28A"/><stop offset="0.45" stop-color="#F4E3A6"/><stop offset="1" stop-color="#B89A4E"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B07A48"/><stop offset="0.5" stop-color="#C99460"/><stop offset="1" stop-color="#8A5A30"/></linearGradient>
  <linearGradient id="plastic" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E85A4A"/><stop offset="1" stop-color="#A8322A"/></linearGradient>
  <linearGradient id="fibre" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F7A15A"/><stop offset="0.35" stop-color="#FFC48A"/><stop offset="1" stop-color="#C9561A"/></linearGradient>
  <linearGradient id="iron" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6B6F73"/><stop offset="0.45" stop-color="#8E9296"/><stop offset="1" stop-color="#45484C"/></linearGradient>
  <linearGradient id="alu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#8A949C"/></linearGradient>
  <linearGradient id="van" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DCE2E7"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#BFDDF2"/><stop offset="1" stop-color="#6E9CC0"/></linearGradient>
  <linearGradient id="ice" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E6F6FF"/><stop offset="1" stop-color="#8CC8EE"/></linearGradient>
  <linearGradient id="tube" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#C9D3DB"/></linearGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF4B0"/><stop offset="1" stop-color="#FFD34E" stop-opacity="0"/></radialGradient>
  <radialGradient id="mud" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#6E5236"/><stop offset="1" stop-color="#4A3420"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def card_open(zoom=None):
    """[zoom] = (cx, cy, z): a camera closing in on the people; the sky
    stays the full-card backdrop."""
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#sky)"/>']
    cx, cy, z = zoom or (100, GY, 1.0)
    out.append(f'<g transform="translate({f(cx * (1 - z))} {f(cy * (1 - z))}) scale({f(z)})">')
    return out


def card_close(out):
    out.append('</g>')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def clouds(x, y, s=1.0):
    return (f'<g fill="#FFFFFF" opacity="0.9"><ellipse cx="{x}" cy="{y}" rx="{f(22 * s)}" ry="{f(8 * s)}"/>'
            f'<ellipse cx="{f(x + 15 * s)}" cy="{f(y - 6 * s)}" rx="{f(15 * s)}" ry="{f(9 * s)}"/></g>')


def trees(y):
    blobs = ''.join(f'<ellipse cx="{x}" cy="{f(y - r * 0.55)}" rx="{f(r * 1.3)}" ry="{r}"/>'
                    for x, r in [(8, 12), (30, 9), (52, 14), (96, 8), (198, 9)])
    return f'<g fill="#7FA36A" opacity="0.75">{blobs}</g>'


def ground_open(cloud_at=((36, 64, 0.8), (124, 44, 0.7)), zoom=None):
    out = card_open(zoom)
    for cx, cy, s in cloud_at:
        out.append(clouds(cx, cy, s))
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append(trees(GY + 1))
    return out


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 11 * s)} {f(y + math.sin(a) * 11 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(10 * s)}" fill="url(#spark)"/>'
            f'<g stroke="#FFF4B0" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.4 * s)}" fill="#FFFFFF"/>')


def zig(x, y, h=10, d=1):
    """A small jolt mark beside a stiff body."""
    return (f'<path d="M{f(x)} {f(y)} l{f(3 * d)} {f(h / 3)} l{f(-3 * d)} {f(h / 3)} l{f(3 * d)} {f(h / 3)}" '
            f'stroke="#FFD34E" stroke-width="1.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')


def phone(x, y, ang=0):
    """A mobile phone held at (x, y)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({f(ang)})"><rect x="-2.6" y="-5" width="5.2" height="10" rx="1.2" fill="{BOOT}"/>'
            f'<rect x="-1.8" y="-3.8" width="3.6" height="6.4" rx="0.6" fill="{WIRE}"/>'
            f'<path d="M-1.2 -3 l1.6 0" stroke="#FFFFFF" stroke-width="0.6" stroke-linecap="round"/></g>')


# --------------------------------------------------------------------------
# People. Side view: local coords facing right, feet at (0, 0); hands are
# given in card coords and mapped in.
# --------------------------------------------------------------------------

def _arm(sx, sy, hx, hy, shirt, bend=1):
    mx, my = (sx + hx) / 2, (sy + hy) / 2
    dx, dy = hx - sx, hy - sy
    n = math.hypot(dx, dy) or 1
    ex, ey = mx + (-dy / n) * 4 * bend, my + (dx / n) * 4 * bend
    return (f'<path d="M{f(sx)} {f(sy)} L{f(ex)} {f(ey)} L{f(hx)} {f(hy)}" stroke="{shirt}" stroke-width="5.4" '
            f'stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
            f'<circle cx="{f(hx)}" cy="{f(hy)}" r="2.8" fill="{SKIN}"/>')


POSES = {
    'stand': dict(hip=(0, -30), sh=(1, -56), head=(3, -64)),
    'walk': dict(hip=(0, -30), sh=(2, -56), head=(4, -64)),
    'kneel': dict(hip=(-4, -22), sh=(5, -46), head=(10, -54)),
    'cpr': dict(hip=(-6, -22), sh=(7, -44), head=(12, -51)),
    'sit': dict(hip=(0, -7), sh=(-3, -32), head=(-1, -40)),
    'perch': dict(hip=(0, -7), sh=(-3, -32), head=(-1, -40)),
}


def person(fx, gy, hands, pose='stand', shirt='helper', facing=1, helmet=True, props='', s=1.0, eyes='open'):
    """A worker in side view. [hands] = (back hand, front hand) in card coords."""
    col, grad = (SHIRT, 'shirt') if shirt == 'helper' else (VSHIRT, 'shirtV')
    p = POSES[pose]
    hip, sh, head = p['hip'], p['sh'], p['head']

    def loc(pt):
        return ((pt[0] - fx) / (facing * s), (pt[1] - gy) / s)

    g = []
    if pose in ('stand', 'walk'):
        spread = 9 if pose == 'walk' else 6
        g.append(f'<path d="M{hip[0]} {hip[1]} L{-spread + 1} -15 L{-spread - 1} -2" stroke="{PANTS_D}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{spread - 1} -15 L{spread} -2" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{-spread - 7}" y="-4" width="11" height="5" rx="2" fill="{BOOT}"/><rect x="{spread - 5}" y="-4" width="11" height="5" rx="2" fill="{BOOT}"/>')
    elif pose in ('kneel', 'cpr'):
        g.append(f'<path d="M{hip[0]} {hip[1]} L{hip[0] + 2} -3 L{hip[0] - 14} -3" stroke="{PANTS_D}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L{hip[0] + 13} -19 L{hip[0] + 14} -2" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="{hip[0] - 22}" y="-6" width="9" height="5" rx="2" fill="{BOOT}"/><rect x="{hip[0] + 9}" y="-4" width="11" height="5" rx="2" fill="{BOOT}"/>')
    elif pose == 'perch':
        g.append(f'<path d="M{hip[0]} {hip[1]} L12 -8 L12 9" stroke="{PANTS_D}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L15 -6 L16 9" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="9" y="8" width="10" height="5" rx="2" fill="{BOOT}"/><rect x="13" y="9" width="10" height="5" rx="2" fill="{BOOT}"/>')
    elif pose == 'sit':
        g.append(f'<path d="M{hip[0]} {hip[1]} L14 -14 L24 -3" stroke="{PANTS_D}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<path d="M{hip[0]} {hip[1]} L18 -8 L29 -3" stroke="{PANTS}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
        g.append(f'<rect x="24" y="-6" width="6" height="10" rx="2" fill="{BOOT}"/><rect x="28" y="-6" width="6" height="10" rx="2" fill="{BOOT}"/>')
    (bx, by), (hx, hy) = loc(hands[0]), loc(hands[1])
    g.append(_arm(sh[0] - 2, sh[1] + 3, bx, by, col))
    if props:
        # [props] are in card coords: undo this figure's transform for them.
        g.append(f'<g transform="scale({f(1 / (facing * s))} {f(1 / s)}) translate({f(-fx)} {f(-gy)})">{props}</g>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy)
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#{grad})"/>')
    x0, y0 = head
    g.append(f'<rect x="{x0 - 3}" y="{y0 + 4}" width="6" height="6" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="{x0}" cy="{y0}" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M{x0 - 7} {y0 + 1} Q{x0 - 7} {y0 + 6} {x0 - 3} {y0 + 7} L{x0 - 3} {y0 + 1} Z" fill="{HAIR}"/>')
    if helmet:
        g.append(f'<path d="M{x0 - 8} {y0 - 1} A8 8 0 0 1 {x0 + 8} {y0 - 1} Z" fill="{HELMET}"/>'
                 f'<rect x="{x0 - 8}" y="{y0 - 2.4}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    else:
        g.append(f'<path d="M{x0 - 7} {y0 - 1} A7 7 0 0 1 {x0 + 7} {y0 - 2} Q{x0} {y0 - 4} {x0 - 7} {y0 - 1} Z" fill="{HAIR}"/>')
    if eyes == 'open':
        g.append(f'<circle cx="{x0 + 4}" cy="{y0 + 1}" r="1.1" fill="{INK}"/>')
    else:
        g.append(f'<path d="M{x0 + 2.6} {y0 + 1.4} l3 0" stroke="{INK}" stroke-width="0.9" stroke-linecap="round"/>')
    g.append(_arm(sh[0] + 1, sh[1] + 3, hx, hy, col, bend=-1))
    return f'<g transform="translate({f(fx)} {f(gy)}) scale({f(facing * s)} {f(s)})">{"".join(g)}</g>'


# The colleague stuck to the wire, front view: stiff, one hand up on the
# wire, the other arm thrown out to the side, a spark at his hand.
VX = 104                 # his centre
V_HAND = (116, 108)      # his hand on the live wire
V_ARM = (72, 141)        # his outflung hand, straight out at shoulder height
V_LEG = (99, 182)        # his near shin (the "leg" to push)
V_CHEST = (104, 154)     # centre of his chest
V_HEAD = (104, 129)      # his head


def stuck_victim():
    cx, hip, sh, hy = VX, GY - 30, GY - 56, GY - 66
    g = []
    g.append(f'<path d="M{cx - 5} {hip} L{cx - 6} {GY - 3}" stroke="{PANTS}" stroke-width="7.5" stroke-linecap="round"/>'
             f'<path d="M{cx + 5} {hip} L{cx + 6} {GY - 3}" stroke="{PANTS_D}" stroke-width="7.5" stroke-linecap="round"/>')
    g.append(f'<rect x="{cx - 12}" y="{GY - 5}" width="10" height="5" rx="2" fill="{BOOT}"/><rect x="{cx + 2}" y="{GY - 5}" width="10" height="5" rx="2" fill="{BOOT}"/>')
    g.append(f'<path d="M{cx - 11} {sh + 1} Q{cx} {sh - 3} {cx + 11} {sh + 1} L{cx + 9} {hip + 2} L{cx - 9} {hip + 2} Z" fill="url(#shirtV)"/>')
    g.append(f'<rect x="{cx - 9}" y="{hip - 1}" width="18" height="3" fill="{PANTS_D}"/>')
    # Arms: right (viewer's right) up to the wire, left thrown out.
    g.append(f'<path d="M{cx + 9} {sh + 3} L{cx + 15} {sh - 14} L{V_HAND[0]} {V_HAND[1] + 3}" stroke="{VSHIRT}" stroke-width="5.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<circle cx="{V_HAND[0]}" cy="{V_HAND[1] + 2}" r="3" fill="{SKIN}"/>')
    g.append(f'<path d="M{cx - 9} {sh + 3} L{cx - 20} {sh + 2} L{V_ARM[0]} {V_ARM[1]}" stroke="{VSHIRT}" stroke-width="5.4" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append(f'<circle cx="{V_ARM[0]}" cy="{V_ARM[1]}" r="2.8" fill="{SKIN}"/>')
    # Head, front view, helmet on, eyes squeezed.
    g.append(f'<rect x="{cx - 3}" y="{hy + 6}" width="6" height="5" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="{cx}" cy="{hy}" r="7.5" fill="{SKIN}"/>')
    g.append(f'<path d="M{cx - 8.5} {hy - 1} A8.5 8.5 0 0 1 {cx + 8.5} {hy - 1} Z" fill="{HELMET}"/>'
             f'<rect x="{cx - 10}" y="{hy - 2.4}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>')
    g.append(f'<path d="M{cx - 4.5} {hy + 2} l3 0.8 M{cx + 4.5} {hy + 2} l-3 0.8 M{cx - 2.5} {hy + 5} l5 0" stroke="{INK}" stroke-width="1" stroke-linecap="round"/>')
    g.append(zig(cx - 16, sh - 18, 10, -1) + zig(cx + 22, sh + 12, 12) + zig(cx - 18, hip + 4, 10, -1))
    g.append(spark(V_HAND[0], V_HAND[1], 0.9))
    return ''.join(g)


def lying(x0, gy, s=1.3):
    """The colleague lying on his back, head to the right, eyes closed.
    Returns (svg, points): chest centre (just below the collar), belly (just
    above the belt), shoulder, hand. The belt and collar make the two spots
    read apart."""
    g = []
    g.append(f'<path d="M28 -5 L4 -4" stroke="{PANTS_D}" stroke-width="7" stroke-linecap="round"/>'
             f'<path d="M28 -7 L6 -9" stroke="{PANTS}" stroke-width="7" stroke-linecap="round"/>')
    g.append(f'<rect x="-3" y="-13" width="6" height="10" rx="2" fill="{BOOT}"/><rect x="-1" y="-8" width="6" height="8" rx="2" fill="{BOOT}"/>')
    g.append('<path d="M27 -1 L27 -13 Q46 -17 64 -14 L64 -1 Z" fill="url(#shirtV)"/>')
    g.append(f'<rect x="26" y="-13" width="4" height="12" fill="{PANTS_D}"/><rect x="27" y="-9" width="2.4" height="3" fill="#B0B7BD"/>')
    g.append(f'<path d="M62 -14 L66 -10 L62 -6" stroke="{VSHIRT}" stroke-width="1.6" fill="none"/>'
             f'<rect x="51" y="-15.4" width="5" height="1.6" rx="0.6" fill="#22604F"/>')
    g.append(f'<rect x="63" y="-9" width="5" height="6" rx="2" fill="{SKIN_D}"/>')
    g.append(f'<circle cx="72" cy="-7" r="7" fill="{SKIN}"/>')
    g.append(f'<path d="M72 -14 A7 7 0 0 1 79 -7 L75 -7 Q74 -12 72 -14 Z" fill="{HAIR}"/>')
    g.append(f'<path d="M69 -11.5 l2.4 0" stroke="{INK}" stroke-width="0.9" stroke-linecap="round"/>')
    g.append(f'<path d="M60 -6 L46 -3 L33 -2" stroke="{VSHIRT}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
             f'<circle cx="32" cy="-2" r="2.6" fill="{SKIN}"/>')
    svg = f'<g transform="translate({f(x0)} {f(gy)}) scale({f(s)})">{"".join(g)}</g>'

    def at(x, y):
        return (x0 + x * s, gy + y * s)

    return svg, dict(chest=at(55, -15), belly=at(35, -14), shoulder=at(60, -11), hand=at(32, -2), head=at(72, -7), legs=at(16, -6))


def sitting_victim(fx, hand):
    """The colleague sitting up (awake, talking), facing right."""
    return person(fx, GY, ((fx - 6, GY - 8), hand), pose='sit', shirt='victim', helmet=False)


# --------------------------------------------------------------------------
# The places.
# --------------------------------------------------------------------------

def pole_scene(out):
    """Scene B: an LT pole on the right; one conductor snapped and hanging
    down to the colleague's hand."""
    px, pw = 170, 13
    out.append(f'<path d="M-4 22 Q90 40 192 18" stroke="{WIRE}" stroke-width="1.6" fill="none"/>')
    out.append(f'<rect x="{px - pw / 2}" y="0" width="{pw}" height="{GY + 3}" fill="url(#pole)"/>')
    out.append('<path d="M128 50 L204 30 L204 36 L128 56 Z" fill="url(#steelArm)"/>')
    out.append(f'<path d="M-4 6 Q80 18 {px} 8" stroke="{WIRE}" stroke-width="1.8" fill="none"/>')
    for x, y in ((px, 14), (142, 46)):
        out.append(insulator(x, y))
    # The snapped near phase: from its insulator down to his hand.
    out.append(f'<path d="M142 46 Q138 72 {V_HAND[0] + 1} {V_HAND[1] - 2}" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')
    out.append(f'<path d="M-4 42 Q30 52 54 50" stroke="{WIRE}" stroke-width="2.2" fill="none"/>'
               '<path d="M54 50 l3 -2 M54 50 l3 2 M54 50 l4 0" stroke="#7D868E" stroke-width="0.9"/>')


def insulator(x, y, s=0.85):
    return (f'<g transform="translate({x} {y}) scale({s})"><rect x="-1.6" y="-7" width="3.2" height="7" fill="#7D868E"/>'
            '<path d="M-7 -7 L7 -7 L4.5 -12 L7.5 -13 L4 -19 L-4 -19 L-7.5 -13 L-4.5 -12 Z" fill="url(#porcelain)" stroke="#9AA5AD" stroke-width="0.6"/></g>')


MCB_LEVER = (162, 116)


def wall_scene(out, lever='on'):
    """Scene A: a house wall on the right with the MCB box; a loose live
    wire from the box ends in the colleague's hand."""
    out.append('<rect x="140" y="66" width="64" height="134" fill="url(#wall)"/>')
    out.append('<rect x="136" y="58" width="70" height="9" fill="url(#roof)"/>')
    out.append('<rect x="186" y="150" width="20" height="46" fill="url(#roof)"/>')
    # MCB box with its lever.
    out.append('<rect x="148" y="96" width="30" height="40" rx="3" fill="url(#box)" stroke="#7D868E" stroke-width="0.8"/>')
    out.append(f'<rect x="158" y="104" width="8" height="24" rx="2" fill="{INK}"/>')
    out.append(f'<text x="168" y="108" font-family="sans-serif" font-size="5.4" font-weight="800" fill="{INK}">ON</text>'
               f'<text x="168" y="130" font-family="sans-serif" font-size="5.4" font-weight="800" fill="{INK}">OFF</text>')
    ly = 106 if lever == 'on' else 120
    out.append(f'<rect x="156" y="{ly}" width="12" height="7" rx="1.5" fill="#F4F6F7" stroke="#7D868E" stroke-width="0.6"/>')
    # The loose wire out of the box, up to his hand.
    out.append(f'<path d="M163 96 C 160 78, 130 80, {V_HAND[0] + 1} {V_HAND[1] - 1}" stroke="{WIRE}" stroke-width="2.2" fill="none"/>')


# --------------------------------------------------------------------------
# Things to push with (drawn along +x from the butt, then placed).
# --------------------------------------------------------------------------

def place(svg, butt, tip):
    ang = math.degrees(math.atan2(tip[1] - butt[1], tip[0] - butt[0]))
    return f'<g transform="translate({f(butt[0])} {f(butt[1])}) rotate({f(ang)})">{svg}</g>'


def length(butt, tip):
    return math.hypot(tip[0] - butt[0], tip[1] - butt[1])


def along(butt, tip, t):
    return (butt[0] + (tip[0] - butt[0]) * t, butt[1] + (tip[1] - butt[1]) * t)


def bamboo(L, w=4.4):
    nodes = ''.join(f'<rect x="{f(x)}" y="{f(-w / 2 - 0.3)}" width="1.6" height="{f(w + 0.6)}" rx="0.6" fill="#9C7E36"/>'
                    for x in [L * k / 6 for k in range(1, 6)])
    return f'<rect x="0" y="{f(-w / 2)}" width="{f(L)}" height="{f(w)}" rx="{f(w / 2)}" fill="url(#bamboo)"/>{nodes}'


def hot_stick(L, w=4):
    return (f'<rect x="0" y="{f(-w / 2)}" width="{f(L)}" height="{f(w)}" rx="1.5" fill="url(#fibre)"/>'
            f'<rect x="0" y="{f(-w / 2 - 0.5)}" width="{f(L * 0.22)}" height="{f(w + 1)}" rx="1.5" fill="#2A2D33"/>'
            f'<rect x="{f(L * 0.55)}" y="{f(-w / 2 - 0.4)}" width="2" height="{f(w + 0.8)}" fill="#C9561A"/>'
            f'<rect x="{f(L - 4)}" y="{f(-w / 2 - 0.6)}" width="4" height="{f(w + 1.2)}" rx="1" fill="#2A2D33"/>')


def wood(L, w=5.2, wet=False):
    s = (f'<path d="M0 {f(-w / 2)} L{f(L)} {f(-w / 2 + 0.6)} L{f(L)} {f(w / 2 - 0.4)} L0 {f(w / 2)} Z" fill="url(#wood)"/>'
         f'<path d="M{f(L * 0.2)} -0.6 L{f(L * 0.45)} -0.2 M{f(L * 0.6)} 0.8 L{f(L * 0.85)} 0.6" stroke="#8A5A30" stroke-width="0.7"/>'
         f'<ellipse cx="{f(L * 0.52)}" cy="0" rx="2" ry="1.2" fill="#8A5A30"/>')
    if wet:
        s += (f'<path d="M0 {f(-w / 2)} L{f(L)} {f(-w / 2 + 0.6)} L{f(L)} {f(w / 2 - 0.4)} L0 {f(w / 2)} Z" fill="#23384F" opacity="0.62"/>'
              + f'<path d="M{f(L * 0.08)} {f(-w / 2 + 1)} L{f(L * 0.92)} {f(-w / 2 + 1.3)}" stroke="#BFE3F7" stroke-width="1.1" opacity="0.95"/>'
              + f'<path d="M{f(L * 0.3)} {f(w / 2 - 1.2)} L{f(L * 0.7)} {f(w / 2 - 1)}" stroke="#7FC4F0" stroke-width="0.9"/>')
    return s


def drops(butt, tip, n=6, fall=(4, 11, 19)):
    """Big water drops falling straight down from a soaked stick."""
    out = []
    for k in range(n):
        # Past the hands, where nothing hides them.
        x, y = along(butt, tip, 0.52 + 0.44 * k / max(1, n - 1))
        dy = fall[k % len(fall)]
        out.append(f'<path d="M{f(x)} {f(y + dy - 3.2)} q-2.4 4 0 5.6 q2.4 -1.6 0 -5.6 Z" fill="#7FC4F0" stroke="#3A7BD5" stroke-width="0.4"/>')
    return ''.join(out)


def bucket(x, y):
    """A steel bucket tipped over on the ground, water spilling out."""
    return (f'<ellipse cx="{x + 4}" cy="{y + 0.6}" rx="26" ry="3.2" fill="#7FC4F0" opacity="0.85"/>'
            f'<ellipse cx="{x - 6}" cy="{y + 0.4}" rx="9" ry="1.6" fill="#BFE3F7"/>'
            f'<g transform="translate({x + 14} {y - 5}) rotate(-80)"><path d="M-6 -6 L6 -6 L4.6 6 L-4.6 6 Z" fill="url(#alu)" stroke="#8A949C" stroke-width="0.5"/>'
            '<ellipse cx="0" cy="-6" rx="6" ry="1.6" fill="#3A7BD5"/></g>')


def iron_rod(L, w=3.2):
    spots = ''.join(f'<circle cx="{f(L * k)}" cy="{f(r - 0.5)}" r="{f(r)}" fill="#A65A2A"/>' for k, r in ((0.3, 1), (0.5, 0.8), (0.72, 1.1)))
    return f'<rect x="0" y="{f(-w / 2)}" width="{f(L)}" height="{f(w)}" fill="url(#iron)"/>{spots}'


def ladder(L, w=12):
    rails = (f'<rect x="0" y="{f(-w / 2 - 1.4)}" width="{f(L)}" height="2.8" fill="url(#alu)" stroke="#8A949C" stroke-width="0.4"/>'
             f'<rect x="0" y="{f(w / 2 - 1.4)}" width="{f(L)}" height="2.8" fill="url(#alu)" stroke="#8A949C" stroke-width="0.4"/>')
    rungs = ''.join(f'<rect x="{f(x)}" y="{f(-w / 2)}" width="2" height="{f(w)}" fill="url(#alu)"/>' for x in range(6, int(L) - 2, 9))
    return rungs + rails


def plastic_chair(s=1.0, x=0.0, y=0.0, rot=0):
    """A moulded plastic chair in side view (facing right), feet at (0, 0)."""
    return (f'<g transform="translate({f(x)} {f(y)}) rotate({rot}) scale({s})">'
            '<path d="M-12 0 L-10 -20 M10 0 L8 -20" stroke="url(#plastic)" stroke-width="3" stroke-linecap="round"/>'
            '<path d="M-13 -22 L11 -22 Q13 -22 12 -19 L-12 -19 Z" fill="url(#plastic)"/>'
            '<path d="M-13 -21 L-16 -46 Q-15 -49 -11 -48 L-8 -22 Z" fill="url(#plastic)"/>'
            '<path d="M-13 -40 L-9 -40 M-12.5 -34 L-8.5 -34" stroke="#A8322A" stroke-width="1"/></g>')


def bench(x, y, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})"><rect x="-22" y="-14" width="44" height="4" rx="1" fill="url(#wood)"/>'
            '<rect x="-19" y="-10" width="3" height="10" fill="url(#wood)"/><rect x="16" y="-10" width="3" height="10" fill="url(#wood)"/></g>')


def fence(x0, x1, y_top=150):
    posts = ''.join(f'<rect x="{x}" y="{y_top}" width="3.2" height="{GY - y_top}" rx="1.4" fill="url(#bamboo)"/>'
                    f'<rect x="{x - 0.2}" y="{y_top + 18}" width="3.6" height="1.2" fill="#9C7E36"/>' for x in range(x0, x1, 7))
    rails = (f'<rect x="{x0 - 2}" y="{y_top + 10}" width="{x1 - x0 + 2}" height="2.6" fill="url(#bamboo)"/>'
             f'<rect x="{x0 - 2}" y="{y_top + 28}" width="{x1 - x0 + 2}" height="2.6" fill="url(#bamboo)"/>')
    return f'<g opacity="0.9">{posts}{rails}</g>'


# --------------------------------------------------------------------------
# Round 1 — the first move: switch the source off / phone, never touch.
# --------------------------------------------------------------------------

ZOOM_LINE = (106, GY, 1.25)


def first_card(kind):
    out = ground_open(zoom=ZOOM_LINE)
    wall = kind in ('mcb', 'grab_hand', 'push_hands')
    if wall:
        wall_scene(out, 'off' if kind == 'mcb' else 'on')
    else:
        pole_scene(out)
    out.append(stuck_victim())
    if kind == 'mcb':
        out.append(person(136, GY, ((130, 168), (MCB_LEVER[0], MCB_LEVER[1] + 6))))
    elif kind == 'call':
        out.append(person(46, GY, ((54, 132), (62, 160))))
        out.append(phone(54, 130, 12))
    elif kind == 'grab_hand':
        out.append(person(56, GY, ((60, 160), (V_ARM[0] - 1, V_ARM[1] + 1))))
    elif kind == 'push_hands':
        out.append(person(72, GY, ((92, 148), (94, 142))))
    elif kind == 'pull_shirt':
        out.append(person(66, GY, ((70, 160), (94, 150))))
    elif kind == 'panic':
        out.append(person(46, GY, ((44, 128), (54, 126))))
        out.append(f'<path d="M60 112 l4 -8 M66 116 l7 -5 M68 124 l8 -1" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — what to separate him with (the source can't be switched off).
# Every card has the same roadside: a bamboo fence, a wooden bench and a
# plastic chair, so no colour of a safe object is only on safe cards.
# --------------------------------------------------------------------------

def roadside(out):
    pole_scene(out)
    out.append(fence(122, 166, 156))
    out.append(bench(146, GY, 0.8))
    out.append(plastic_chair(0.62, 132, GY))


def held(out, obj, butt, tip, t_back=0.32, t_front=0.5, fx=38):
    back, front = along(butt, tip, t_back), along(butt, tip, t_front)
    stick = place(obj(length(butt, tip)), butt, tip)
    out.append(person(fx, GY, (back, front), props=stick))


def object_card(kind):
    out = ground_open(zoom=ZOOM_LINE)
    roadside(out)
    out.append(stuck_victim())
    tip = (V_ARM[0] - 2, V_ARM[1])
    butt = (16, 160)
    if kind == 'bamboo':
        held(out, bamboo, butt, tip, 0.3, 0.5)
    elif kind == 'wood':
        held(out, lambda L: wood(L), (20, 158), tip, 0.3, 0.52)
    elif kind == 'wet':
        out.append(bucket(64, GY))
        held(out, lambda L: wood(L, wet=True), (20, 158), tip, 0.3, 0.52)
        out.append(drops((20, 158), tip, n=5))
    elif kind == 'iron':
        held(out, iron_rod, butt, tip, 0.3, 0.5)
    elif kind == 'ladder':
        held(out, ladder, (8, 162), tip, 0.38, 0.56, fx=42)
    elif kind == 'chair':
        # Held by the back, its legs toward his arm.
        chair = plastic_chair(1.0, 80, 152, -90)
        out.append(person(34, GY, ((46, 163), (56, 166)), props=chair))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — where to push: the arm or the leg, never the chest or the head.
# --------------------------------------------------------------------------

PUSH = {
    # Along his outstretched arm to the hand: ends in the open air.
    'arm': ((8, 147), (V_ARM[0] - 3, V_ARM[1])),
    'leg': ((18, 140), (V_LEG[0] - 3, V_LEG[1])),
    # Up from low on the left into the middle of his chest, under the arm.
    'chest': ((14, 184), (V_CHEST[0] - 1, V_CHEST[1])),
    # Down from high on the left, over the arm, to the head.
    'head': ((10, 110), (V_HEAD[0] - 3, V_HEAD[1] + 1)),
}


def _seg_dist(p, a, b):
    ax, ay, bx, by = *a, *b
    t = max(0.0, min(1.0, ((p[0] - ax) * (bx - ax) + (p[1] - ay) * (by - ay)) / ((bx - ax) ** 2 + (by - ay) ** 2)))
    return math.hypot(p[0] - (ax + (bx - ax) * t), p[1] - (ay + (by - ay) * t))


# The review of step 19: the arm push and the chest push must not look alike
# at card size. Keep the tips far apart, and keep the chest and head sticks
# clear of the arm's tip on their way in.
for _bad in ('chest', 'head'):
    assert math.dist(PUSH['arm'][1], PUSH[_bad][1]) >= 25, _bad
    assert _seg_dist(PUSH['arm'][1], *PUSH[_bad]) >= 15, _bad
    assert _seg_dist(PUSH[_bad][1], *PUSH['arm']) >= 25, _bad


def push_card(stick, where):
    out = ground_open(zoom=ZOOM_LINE)
    pole_scene(out)
    out.append(stuck_victim())
    butt, tip = PUSH[where]
    held(out, bamboo if stick == 'bamboo' else hot_stick, butt, tip, 0.3, 0.46)
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — the golden minute: response, call, CPR (not mud, not alone).
# --------------------------------------------------------------------------

def golden_open():
    out = ground_open(((40, 46, 0.8), (150, 70, 0.7)), zoom=(100, GY, 1.3))
    # Far away, the pole where it happened, and its line overhead.
    out.append('<rect x="182" y="40" width="7" height="160" fill="url(#pole)"/>'
               '<path d="M168 56 L204 46 L204 49 L168 59 Z" fill="url(#steelArm)"/>'
               f'<path d="M-4 52 Q90 66 204 48" stroke="{WIRE}" stroke-width="1.4" fill="none"/>')
    return out


def bubble(x, y, mark='?'):
    return (f'<path d="M{x - 13} {y - 10} h26 a5 5 0 0 1 5 5 v10 a5 5 0 0 1 -5 5 h-14 l-7 6 l1 -6 h-5 a5 5 0 0 1 -5 -5 v-10 a5 5 0 0 1 5 -5 Z" '
            f'fill="#FFFFFF" stroke="{INK}" stroke-width="0.8"/>'
            f'<text x="{x}" y="{y + 4}" font-family="sans-serif" font-size="12" font-weight="800" text-anchor="middle" fill="{INK}">{mark}</text>')


def hand_on(pt, frm, both=False):
    """The helper's hand (and forearm) drawn over the lying body."""
    mx, my = pt[0] + (frm[0] - pt[0]) * 0.35, pt[1] + (frm[1] - pt[1]) * 0.35
    s = (f'<path d="M{f(mx)} {f(my)} L{f(pt[0])} {f(pt[1] - 1)}" stroke="{SHIRT}" stroke-width="5.4" stroke-linecap="round"/>'
         f'<circle cx="{f(pt[0])}" cy="{f(pt[1])}" r="3" fill="{SKIN}"/>')
    if both:
        s += f'<circle cx="{f(pt[0] + 1.6)}" cy="{f(pt[1] - 1)}" r="2.8" fill="{SKIN}" stroke="{SKIN_D}" stroke-width="0.5"/>'
    return s


CALLER_X = 158  # right of the victim's head, clear of his body


def caller(fx=CALLER_X):
    """A second worker phoning the ambulance, facing the scene."""
    return person(fx, GY, ((fx - 8, GY - 64), (fx - 12, GY - 34)), facing=-1) + phone(fx - 8, GY - 66, -12)


def golden_card(kind):
    out = golden_open()
    body, pt = lying(34, GY - 1)
    if kind in ('ask', 'ask_call'):
        if kind == 'ask_call':
            out.append(caller())
        out.append(person(110, GY - 4, ((104, 176), pt['shoulder']), pose='kneel'))
        out.append(body)
        out.append(hand_on(pt['shoulder'], (116, 150)))
        out.append(bubble(128, 112))
    elif kind == 'wait':
        # Both stand off to the side, arms folded, looking up the road for
        # the ambulance; nobody goes to him.
        out.append(body)
        for fx, face in ((145, -1), (164, 1)):
            out.append(person(fx, GY, ((fx + 7 * face, GY - 42), (fx + 9 * face, GY - 44)), facing=face))
    elif kind == 'mud':
        out.append(body)
        out.append('<path d="M30 197 Q34 178 52 180 Q70 176 84 184 Q90 190 88 197 Z" fill="url(#mud)"/>'
                   '<ellipse cx="44" cy="183" rx="4" ry="1.6" fill="#4A3420"/><ellipse cx="70" cy="181" rx="5" ry="1.8" fill="#4A3420"/>')
        # The shovel digs at the mound, well clear of his face.
        shovel = (f'<path d="M146 150 L102 186" stroke="url(#wood)" stroke-width="3" stroke-linecap="round"/>'
                  f'<path d="M98 182 L106 190 L100 196 L92 188 Z" fill="url(#iron)"/>'
                  f'<path d="M92 190 q4 -3 9 2" fill="url(#mud)"/>')
        out.append(person(146, GY, ((136, 158), (126, 166)), props=shovel, facing=-1))
        # He shouts the myth ("মাটিতে পুঁতে দাও!"): a bubble on a trap too.
        out.append(bubble(150, 106, '!'))
    elif kind == 'leave':
        out.append(body)
        out.append(person(146, GY, ((138, 170), (154, 168)), pose='walk'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — he has come round and talks: hospital, and nothing on a burn.
# The ambulance has come on every card.
# --------------------------------------------------------------------------

def ambulance(out):
    x, y = 118, 122
    out.append(f'<g transform="translate({x} {y})">'
               '<path d="M0 6 Q0 0 6 0 L66 0 L66 66 L0 66 Z" fill="url(#van)" stroke="#AEB6BD" stroke-width="0.8"/>'
               '<path d="M66 14 L82 14 Q90 16 92 30 L92 66 L66 66 Z" fill="url(#van)" stroke="#AEB6BD" stroke-width="0.8"/>'
               '<path d="M70 18 L82 18 Q87 20 88 32 L70 32 Z" fill="url(#glass)"/>'
               '<rect x="0" y="40" width="92" height="5" fill="#D8343A"/>'
               '<rect x="28" y="12" width="14" height="4.4" fill="#D8343A"/><rect x="32.8" y="7.2" width="4.4" height="14" fill="#D8343A"/>'
               '<rect x="44" y="-5" width="10" height="5" rx="1.5" fill="#3A7BD5"/>'
               '<rect x="2" y="8" width="2" height="54" fill="#AEB6BD"/>'
               '<rect x="-8" y="60" width="14" height="5" rx="1.5" fill="#7D868E"/>'
               '</g>')
    for wx in (x + 16, x + 74):
        out.append(f'<circle cx="{wx}" cy="{y + 66}" r="8" fill="{BOOT}"/><circle cx="{wx}" cy="{y + 66}" r="3.4" fill="#AEB6BD"/>')


def care_card(kind):
    out = ground_open(((40, 50, 0.8), (110, 34, 0.6)), zoom=(100, GY, 1.15))
    ambulance(out)
    hand = (100, GY - 22)
    if kind == 'walk':
        out.append(person(96, GY, ((92, 164), (110, 158)), pose='walk', shirt='victim', helmet=False))
        out.append(person(78, GY, ((72, 168), (96, 146)), pose='walk'))
    elif kind == 'seat':
        out.append(person(118, 183, ((124, 176), (106, 172)), pose='perch', shirt='victim', helmet=False, facing=-1))
        out.append(person(76, GY, ((70, 168), (100, 150))))
    elif kind == 'ice':
        out.append(sitting_victim(70, hand))
        out.append(person(126, GY, ((hand[0] + 2, hand[1] - 3), (hand[0] + 4, hand[1] + 1)), pose='kneel', facing=-1))
        out.append(f'<rect x="{hand[0] - 6}" y="{hand[1] - 7}" width="13" height="8" rx="2.5" fill="url(#ice)" stroke="#8CC8EE" stroke-width="0.5"/>'
                   f'<path d="M{hand[0] - 3} {hand[1] - 5} l3 0 M{hand[0] + 1} {hand[1] - 3} l3 0" stroke="#FFFFFF" stroke-width="0.8"/>')
    elif kind == 'water':
        out.append(sitting_victim(70, hand))
        bottle = (f'<g transform="translate({hand[0] + 12} {hand[1] - 26}) rotate(-120)">'
                  '<rect x="-3.4" y="-9" width="6.8" height="16" rx="2" fill="url(#ice)" stroke="#3A7BD5" stroke-width="0.8"/>'
                  '<rect x="-1.8" y="-12" width="3.6" height="3.2" fill="#3A7BD5"/></g>')
        out.append(person(128, GY, ((122, 168), (hand[0] + 14, hand[1] - 26)), props='', facing=-1))
        out.append(bottle)
        out.append(f'<path d="M{hand[0] + 6} {hand[1] - 22} Q{hand[0] + 2} {hand[1] - 12} {hand[0] + 1} {hand[1] - 2}" stroke="#7FC4F0" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                   f'<circle cx="{hand[0] - 3}" cy="{hand[1] + 6}" r="1.2" fill="#7FC4F0"/><circle cx="{hand[0] + 4}" cy="{hand[1] + 8}" r="1" fill="#7FC4F0"/>')
    elif kind == 'cream':
        out.append(sitting_victim(70, hand))
        out.append(person(126, GY, ((hand[0] + 2, hand[1] - 1), (hand[0] + 8, hand[1] - 6)), pose='kneel', facing=-1))
        out.append(f'<g transform="translate({hand[0] + 8} {hand[1] - 7}) rotate(-30)"><rect x="-1" y="-3" width="13" height="6" rx="1.6" fill="url(#tube)" stroke="#AEB6BD" stroke-width="0.5"/>'
                   '<rect x="-4" y="-1.6" width="3" height="3.2" fill="#3A7BD5"/><rect x="5" y="-3" width="3" height="6" fill="#3A7BD5" opacity="0.8"/></g>'
                   f'<ellipse cx="{hand[0]}" cy="{hand[1] - 2}" rx="2.6" ry="1.4" fill="#FFFFFF"/>')
    elif kind == 'home':
        out.append(person(34, GY, ((26, 168), (42, 168)), pose='walk', shirt='victim', helmet=False, facing=-1))
        out.append(person(96, GY, ((90, 168), (88, 128))))
    return card_close(out)


CARDS = {
    # Round 1 — the first move.
    'first_mcb': first_card('mcb'),
    'first_call': first_card('call'),
    'first_grab_hand': first_card('grab_hand'),
    'first_push_hands': first_card('push_hands'),
    'first_pull_shirt': first_card('pull_shirt'),
    'first_panic': first_card('panic'),
    # Round 2 — what to separate him with.
    'obj_bamboo': object_card('bamboo'),
    'obj_wood': object_card('wood'),
    'obj_chair': object_card('chair'),
    'obj_wet': object_card('wet'),
    'obj_iron': object_card('iron'),
    'obj_ladder': object_card('ladder'),
    # Round 3 — where to push.
    'push_bamboo_arm': push_card('bamboo', 'arm'),
    'push_stick_leg': push_card('stick', 'leg'),
    'push_bamboo_chest': push_card('bamboo', 'chest'),
    'push_bamboo_head': push_card('bamboo', 'head'),
    'push_stick_head': push_card('stick', 'head'),
    'push_stick_chest': push_card('stick', 'chest'),
    # Round 4 — the golden minute.
    'gold_ask': golden_card('ask'),
    'gold_ask_call': golden_card('ask_call'),
    'gold_mud': golden_card('mud'),
    'gold_wait': golden_card('wait'),
    'gold_leave': golden_card('leave'),
    # Round 5 — after: hospital, nothing on a burn.
    'care_walk': care_card('walk'),
    'care_seat': care_card('seat'),
    'care_ice': care_card('ice'),
    'care_water': care_card('water'),
    'care_cream': care_card('cream'),
    'care_home': care_card('home'),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
