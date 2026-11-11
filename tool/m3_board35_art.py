"""Picture cards for lesson 3.5 শেখা ("লাইটনিং অ্যারেস্টার (LA): বজ্রপাতের কবচ").

python -I tool/m3_board35_art.py .

Writes assets/game/art/m3_board35/*.svg in the same clean gradient style as
tool/m2_board28_art.py (200 x 220 scene cards, drawn edge to edge). No words
in the art: the phases are told by their R / Y / B colours only.

What the cards show comes from lesson 3.5 and its film script only:
  1. fit: an LA sits right beside the transformer's HT bushing, as close as
     possible (further away it works less well); every phase R, Y, B gets its
     own LA; without a proper LA a lightning strike can burn the transformer.
     Porcelain and polymer housings are both drawn as right;
  2. work: at normal voltage the LA is an insulator (no current through it);
     on a lightning / switching surge the MOV inside conducts and sends the
     surge straight to earth, then it is an insulator again and the line runs
     on; it neither stops nor attracts lightning; with a weak earth the surge
     goes through the transformer instead;
  3. body: no crack, break or burn mark on the porcelain / polymer housing;
     a broken / blown LA means a big surge came — a damaged LA protects
     nothing;
  4. earth: the earth wire from the bottom terminal is firmly connected and
     not cut anywhere (even a small cut or loose joint raises the resistance
     many times); a disconnector that has fired leaves the earth wire hanging
     — proof the LA is bad;
  5. patrol: on line patrol look whether the LA beside the transformer is
     fitted and whole; look at the body and the earth rod regularly.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, and the safe card's backdrop is a trap's backdrop too.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m3_board35_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm3_board35')
W, H = 200, 220
GY = 198

SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
WIRE = '#2B3138'
COPPER = '#C9803A'
PH_R = '#D8402F'
PH_Y = '#F0C02E'
PH_B = '#2F6BCB'
PHASES = (PH_R, PH_Y, PH_B)
FACE = '#1E2329'
ARM = '#6F7880'
CLOUD = '#4A5560'
CLOUD_D = '#39424B'
BOLT = '#FFF2A8'
SURGE = '#FFE45C'
WINDOW = '#FFD966'
SOOT = '#1B1E22'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6F93B8"/><stop offset="1" stop-color="#C4D6E4"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DB07A"/><stop offset="1" stop-color="#7E9160"/></linearGradient>
  <linearGradient id="soil" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8E7A58"/><stop offset="1" stop-color="#6E5C40"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8F8A82"/><stop offset="0.5" stop-color="#C2BDB4"/><stop offset="1" stop-color="#85807A"/></linearGradient>
  <linearGradient id="tank" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6F8A6C"/><stop offset="0.5" stop-color="#93AE8F"/><stop offset="1" stop-color="#627C60"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#6A321C"/><stop offset="0.45" stop-color="#B5643C"/><stop offset="1" stop-color="#5E2C18"/></linearGradient>
  <linearGradient id="poly" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#535B62"/><stop offset="0.45" stop-color="#9AA3AB"/><stop offset="1" stop-color="#4C545B"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9C6A2"/><stop offset="1" stop-color="#BFA983"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
  <radialGradient id="spark" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.35" stop-color="#FFF6C9"/><stop offset="1" stop-color="#FFE45C" stop-opacity="0"/></radialGradient>
  <radialGradient id="blast" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF"/><stop offset="0.3" stop-color="#FFE38A"/><stop offset="0.7" stop-color="#FF7A2E" stop-opacity="0.7"/><stop offset="1" stop-color="#FF7A2E" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')




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


def _hand(p, bare=False, point=0):
    x, y = p
    c = SKIN if bare else GLOVE
    s = f'<circle cx="{f(x)}" cy="{f(y)}" r="3" fill="{c}"/>'
    if point:
        s += f'<path d="M{f(x)} {f(y)} l{f(6 * point)} -1.5" stroke="{c}" stroke-width="2" stroke-linecap="round"/>'
    return s


def figure(hip, sh, head, feet, hands, face=1, look=0, bare=False, point=(0, 0), props_front=''):
    """The lineman: blue shirt, dark trousers, yellow helmet, black rubber
    gloves (bare = no gloves)."""
    g = []
    fb, ff = feet
    kb = _joint(hip, fb, face)
    kf = _joint(hip, ff, face)
    g.append(_limb(hip, kb, fb, PANTS_D, 7))
    g.append(_boot(fb, face))
    g.append(_limb(hip, kf, ff, PANTS, 7))
    g.append(_boot(ff, face))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    eb = _joint(sb, hb, face, down=True)
    ef = _joint(sf, hf, face, down=True)
    g.append(_limb(sb, eb, hb, SHIRT_D, 5.4))
    g.append(_hand(hb, bare, point[0]))
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
             f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="url(#shirt)"/>')
    g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{HELMET}"/>',
          f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{HELMET_D}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    g.append(_limb(sf, ef, hf, SHIRT, 5.4))
    g.append(props_front)
    g.append(_hand(hf, bare, point[1]))
    return ''.join(g)


S = 1.32  # the worker's scale


def worker(x, hands_world, face=-1, look=0, bare=False, point=(0, 0)):
    """A standing worker at x (feet on GY), scaled S about his feet; the hands
    are given in card coordinates."""
    def local(p):
        return (x + (p[0] - x) / S, GY + (p[1] - GY) / S)
    gy = GY
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hands = (local(hands_world[0]), local(hands_world[1]))
    fig = figure(hip, sh, head, feet, hands, face, look, bare, point)
    return f'<g transform="translate({f(x)} {GY}) scale({S}) translate({f(-x)} -{GY})">{fig}</g>'




# --------------------------------------------------------------------------
# Things.
# --------------------------------------------------------------------------

ROOF = '#8A4B32'
FIN = '#5C7459'


def la(kind='porc', state='ok', disc='ok'):
    """A lightning arrester in local units: the housing stands on y = 0 (the
    bracket), the top stud at y = -37, the disconnector hangs below to y = 10.
    kind: porc (brown glazed porcelain) / poly (grey polymer sheds)."""
    fill = f'url(#{kind})'
    o = []
    top = -13 if state == 'blown' else -30
    o.append(f'<rect x="-3.4" y="{top}" width="6.8" height="{-top}" fill="{fill}"/>')
    if kind == 'porc':
        sheds, rx, ry = (-26, -19, -12, -5), 7, 2.4
    else:
        sheds, rx, ry = (-27, -22, -17, -12, -7, -2), 8, 1.5
    for sy in sheds:
        if sy > top + 1:
            o.append(f'<ellipse cx="0" cy="{sy}" rx="{rx}" ry="{ry}" fill="{fill}"/>')
    if state == 'blown':
        o.append(f'<path d="M-3.4 {top} l1.4 -3 l1.2 2.4 l1.6 -4 l1.4 3.4 l1.6 -2.6 l1.6 3.8 Z" fill="{fill}"/>')
        o.append(f'<ellipse cx="0" cy="{top - 1}" rx="6" ry="3.4" fill="{SOOT}" opacity="0.7"/>')
    else:
        o.append(f'<rect x="-3" y="-34" width="6" height="4" rx="1" fill="url(#steel)"/>')
        o.append('<path d="M0 -34 L0 -37" stroke="url(#steel)" stroke-width="1.6"/>')
    if state == 'crack':
        o.append(f'<path d="M-1.2 -29 l2.2 4 l-2.4 4.2 l2.6 5 l-1.8 4.4 l2.2 5.2" stroke="{SOOT}" stroke-width="0.8" fill="none"/>')
    if state == 'burnt':
        o.append(f'<ellipse cx="-1.6" cy="-21" rx="4.2" ry="5.4" fill="{SOOT}" opacity="0.75"/>')
        o.append(f'<ellipse cx="2" cy="-8" rx="3.4" ry="3.6" fill="{SOOT}" opacity="0.65"/>')
    o.append('<rect x="-5" y="0" width="10" height="3" rx="0.8" fill="url(#steel)"/>')
    if disc == 'ok':
        o.append(f'<rect x="-2.4" y="3" width="4.8" height="7" rx="1" fill="{FACE}"/>')
    else:
        o.append(f'<rect x="-2.4" y="3" width="4.8" height="3" rx="0.8" fill="{FACE}"/>')
        o.append(f'<ellipse cx="0" cy="7" rx="4" ry="2.6" fill="{SOOT}" opacity="0.6"/>')
    return ''.join(o)


def la_at(x, y, s, kind='porc', state='ok', disc='ok'):
    return f'<g transform="translate({f(x)} {f(y)}) scale({f(s)})">{la(kind, state, disc)}</g>'


def spark(x, y, s=1.0):
    rays = ''.join(
        f'<path d="M{f(x + math.cos(a) * 4 * s)} {f(y + math.sin(a) * 4 * s)} L{f(x + math.cos(a) * 12 * s)} {f(y + math.sin(a) * 12 * s)}"/>'
        for a in [i * math.pi / 4 + 0.3 for i in range(8)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(13 * s)}" fill="url(#spark)"/>'
            f'<g stroke="{BOLT}" stroke-width="{f(1.3 * s)}" stroke-linecap="round">{rays}</g>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(2.6 * s)}" fill="#FFFFFF"/>')


def blast(x, y, r=40):
    rays = ''.join(f'<path d="M{f(x + math.cos(a) * r * 0.3)} {f(y + math.sin(a) * r * 0.3)} L{f(x + math.cos(a) * r)} {f(y + math.sin(a) * r)}"/>'
                   for a in [i * math.pi / 6 + 0.2 for i in range(12)])
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="url(#blast)"/>'
            f'<g stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round" opacity="0.9">{rays}</g>')


def cloud(x=168, y=20):
    return (f'<ellipse cx="{x - 18}" cy="{y + 4}" rx="20" ry="11" fill="{CLOUD_D}"/>'
            f'<ellipse cx="{x}" cy="{y - 2}" rx="22" ry="14" fill="{CLOUD}"/>'
            f'<ellipse cx="{x + 20}" cy="{y + 5}" rx="18" ry="10" fill="{CLOUD_D}"/>')


def bolt(pts):
    d = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    x, y = pts[-1]
    return (f'<path d="{d}" stroke="{BOLT}" stroke-width="5" fill="none" stroke-linejoin="round" opacity="0.45"/>'
            f'<path d="{d}" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linejoin="round"/>'
            + spark(x, y, 0.8))


def chev(x, y, d='down', s=1.0):
    """A surge chevron pointing down / left / right."""
    k = 3.6 * s
    if d == 'down':
        p = f'M{f(x - k)} {f(y - k / 1.6)} L{f(x)} {f(y + k / 1.6)} L{f(x + k)} {f(y - k / 1.6)}'
    elif d == 'left':
        p = f'M{f(x + k / 1.6)} {f(y - k)} L{f(x - k / 1.6)} {f(y)} L{f(x + k / 1.6)} {f(y + k)}'
    else:
        p = f'M{f(x - k / 1.6)} {f(y - k)} L{f(x + k / 1.6)} {f(y)} L{f(x - k / 1.6)} {f(y + k)}'
    return f'<path d="{p}" stroke="{SURGE}" stroke-width="{f(2.2 * s)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# The yard: a two-pole transformer structure — the line comes in at the top
# right, each phase drops to its LA on the bracket, then on to the HT
# bushing; the LAs' earth leads join and run down the right pole to the
# earth rod.
# --------------------------------------------------------------------------

P1, P2 = 20, 136
LAX = (50, 78, 106)
BUSH = (56, 84, 112)
LA_Y = 82
EARTH_X = 141
ROD_X = 150


def yard(las=('porc', 'porc', 'porc'), states=('ok', 'ok', 'ok'), discs=('ok', 'ok', 'ok'), earth_cut=False, back='sky'):
    out = card_open(back)
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    for px in (P1, P2):
        out.append(f'<rect x="{px - 4}" y="10" width="8" height="{GY - 10}" fill="url(#pole)"/>')
    # The incoming line, the top crossarm and its pin insulators.
    for i, x in enumerate(LAX):
        out.append(f'<path d="M{x} 13 Q150 {8 + i * 2} 200 {4 + i * 4}" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
    out.append(f'<rect x="8" y="22" width="140" height="5" fill="{ARM}"/>')
    for x, col in zip(LAX, PHASES):
        out.append(f'<rect x="{x - 3}" y="15" width="6" height="7" rx="1" fill="url(#porcelain)"/>')
        out.append(f'<circle cx="{x}" cy="13" r="2.4" fill="{col}"/>')
    # The transformer on its platform.
    out.append(f'<rect x="14" y="176" width="128" height="6" fill="{ARM}"/>')
    out.append('<rect x="38" y="132" width="88" height="44" rx="3" fill="url(#tank)"/>')
    out += [f'<rect x="{44 + i * 11}" y="140" width="4" height="30" rx="1.5" fill="{FIN}"/>' for i in range(8)]
    for bx, col in zip(BUSH, PHASES):
        out.append(f'<path d="M{bx - 5} 132 L{bx + 5} 132 L{bx + 3} 114 L{bx - 3} 114 Z" fill="url(#porcelain)"/>')
        out.append(f'<rect x="{bx - 3}" y="110" width="6" height="4" rx="1" fill="{col}"/>')
    # The LA bracket.
    out.append(f'<rect x="8" y="{LA_Y}" width="140" height="4" fill="{ARM}"/>')
    # Earth: the bus under the bracket and the lead down the right pole.
    have = [i for i, k in enumerate(las) if k]
    if have:
        x0 = LAX[have[0]]
        out.append(f'<path d="M{x0} 98 L{EARTH_X} 98" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
        if earth_cut:
            out.append(f'<path d="M{EARTH_X} 98 L{EARTH_X} 138" stroke="{COPPER}" stroke-width="1.6" fill="none"/>'
                       f'<path d="M{EARTH_X} 150 L{EARTH_X} {GY} L{ROD_X} {GY + 3}" stroke="{COPPER}" stroke-width="1.6" fill="none"/>'
                       f'<path d="M{EARTH_X} 138 l-2 4 M{EARTH_X} 138 l2 3.4 M{EARTH_X} 150 l-2 -4 M{EARTH_X} 150 l2 -3" stroke="{COPPER}" stroke-width="0.8"/>')
        else:
            out.append(f'<path d="M{EARTH_X} 98 L{EARTH_X} {GY} L{ROD_X} {GY + 3}" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
    out.append(f'<rect x="{ROD_X - 1.5}" y="{GY + 1}" width="3" height="16" fill="url(#steel)"/>')
    out.append(f'<rect x="{ROD_X - 4}" y="{GY + 1}" width="8" height="4" rx="1" fill="{ARM}"/>')
    # Jumpers and the arresters.
    for i, (x, bx, col) in enumerate(zip(LAX, BUSH, PHASES)):
        k = las[i]
        if k:
            if states[i] != 'blown':
                out.append(f'<path d="M{x} 13 C{x - 11} 22 {x - 11} 38 {x} 45" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
                out.append(f'<path d="M{x} 46 Q{x + 11} 48 {x + 11} 62 L{x + 11} 102 Q{x + 11} 108 {bx} 110" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
            else:
                out.append(f'<path d="M{x} 13 C{x - 11} 22 {x - 11} 38 {x - 6} 52" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
                out.append(f'<path d="M{x + 4} 62 Q{x + 11} 62 {x + 11} 70 L{x + 11} 102 Q{x + 11} 108 {bx} 110" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
                out.append(f'<path d="M{x - 10} 179 l5 -3 l3 3 Z M{x + 18} 178 l4 -2 l2 3 Z" fill="url(#{k})"/>')
            out.append(la_at(x, LA_Y, 1.0, k, states[i], discs[i]))
            if discs[i] == 'ok':
                out.append(f'<path d="M{x} 92 L{x} 98" stroke="{COPPER}" stroke-width="1.6"/>')
            else:
                out.append(f'<path d="M{x} 98 Q{x - 2} 112 {x - 8} 124" stroke="{COPPER}" stroke-width="1.6" fill="none"/>')
        else:
            out.append(f'<path d="M{x} 13 C{x + 11} 20 {x + 11} 40 {x + 11} 62 L{x + 11} 102 Q{x + 11} 108 {bx} 110" stroke="{WIRE}" stroke-width="1.3" fill="none"/>')
    return out


def house(lit=True):
    return (f'<rect x="160" y="168" width="34" height="30" fill="url(#house)"/>'
            f'<path d="M156 170 L177 152 L198 170 Z" fill="{ROOF}"/>'
            f'<rect x="172" y="177" width="10" height="9" fill="{WINDOW if lit else CLOUD}"/>'
            + (f'<circle cx="177" cy="181" r="12" fill="url(#glow)" opacity="0.6"/>' if lit else ''))


def to_earth(la_i=1):
    """Surge chevrons down an LA, along the earth bus and down to the rod."""
    x = LAX[la_i]
    return (chev(x, 66) + chev(x, 96, 'down', 0.7) + chev(96, 98, 'right', 0.8) + chev(122, 98, 'right', 0.8)
            + chev(EARTH_X, 128) + chev(EARTH_X, 168) + spark(ROD_X, GY + 10, 0.7))


# --------------------------------------------------------------------------
# Round 1 — fit: beside the HT bushing, one LA for each phase.
# --------------------------------------------------------------------------

def fit_card(kind):
    if kind == 'porc':
        out = yard()
    elif kind == 'poly':
        out = yard(las=('poly', 'poly', 'poly'))
    elif kind == 'one':
        out = yard(las=('porc', None, None))
    elif kind == 'far':
        out = yard(las=(None, None, None))
        # The arresters on a far pole down the line, nowhere near the tank.
        out.append(f'<rect x="176" y="46" width="5" height="{GY - 46}" fill="url(#pole)"/>')
        out.append(f'<rect x="162" y="80" width="33" height="2.6" fill="{ARM}"/>')
        for x in (167, 178.5, 190):
            out.append(la_at(x, 80, 0.5, 'poly'))
    else:  # none, in a storm: the tank burns
        out = yard(las=(None, None, None))
        out.append(cloud())
        out.append(bolt([(170, 30), (162, 40), (172, 48), (160, 62), (126, 112)]))
        out.append(blast(84, 152, 40))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — work: an insulator at normal voltage; a surge goes to earth.
# --------------------------------------------------------------------------

STRIKE = [(176, 30), (170, 22), (180, 16), (174, 9)]


def work_card(kind):
    if kind == 'calm':
        out = yard()
        out.append(house(True))
    elif kind == 'surge':
        out = yard()
        out.append(house(True))
        out.append(cloud(150, 44))
        out.append(bolt([(150, 50), (160, 34), (152, 26), (172, 9)]))
        out.append(chev(150, 9.5, 'left', 0.8) + chev(122, 11.5, 'left', 0.8))
        out.append(to_earth(1))
    elif kind == 'leak':
        out = yard()
        out.append(house(True))
        out.append(to_earth(1))
    elif kind == 'burn':
        out = yard(earth_cut=True)
        out.append(house(False))
        out.append(cloud(150, 44))
        out.append(bolt([(150, 50), (160, 34), (152, 26), (172, 9)]))
        out.append(chev(150, 9.5, 'left', 0.8) + chev(122, 11.5, 'left', 0.8))
        out.append(chev(89, 74) + chev(89, 96))
        out.append(blast(84, 152, 38))
    else:  # attract: the LA pulling the bolt to itself
        out = yard()
        out.append(house(True))
        out.append(cloud(150, 44))
        out.append(bolt([(146, 52), (128, 58), (114, 46), (96, 52), (79, 42)]))
        out.append('<g stroke="#FFFFFF" stroke-width="1.4" fill="none" opacity="0.85" stroke-linecap="round">'
                   '<path d="M66 40 Q78 28 90 40"/><path d="M60 38 Q78 18 96 38"/></g>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — body: close-up of one LA's housing.
# --------------------------------------------------------------------------

def body_card(kind):
    out = card_open('sky')
    out.append(f'<rect y="{GY}" width="{W}" height="{H - GY}" fill="url(#ground)"/>')
    out.append('<rect x="-4" y="0" width="22" height="220" fill="url(#pole)"/>')
    out.append(f'<rect x="0" y="150" width="200" height="9" fill="{ARM}"/>')
    lk, st = {'porc': ('porc', 'ok'), 'poly': ('poly', 'ok'), 'crack': ('porc', 'crack'),
              'burnt': ('poly', 'burnt'), 'blown': ('porc', 'blown')}[kind]
    if st == 'blown':
        out.append(f'<path d="M0 10 Q50 20 74 70 L78 80" stroke="{WIRE}" stroke-width="3" fill="none"/>')
        out.append('<path d="M40 196 l10 -6 l6 6 Z M146 194 l8 -8 l7 7 Z M120 198 l5 -4 l4 4 Z" fill="url(#porc)"/>')
        out.append(f'<ellipse cx="100" cy="100" rx="34" ry="16" fill="{SOOT}" opacity="0.35"/>')
    else:
        out.append(f'<path d="M0 10 Q60 6 100 24" stroke="{WIRE}" stroke-width="3" fill="none"/>')
    out.append(la_at(100, 150, 3.4, lk, st))
    out.append(f'<path d="M100 184 L100 220" stroke="{COPPER}" stroke-width="3"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — earth: the lead from the LA's bottom terminal to the earth rod.
# --------------------------------------------------------------------------

EGY = 170


def earth_card(kind):
    out = card_open('sky')
    out.append(f'<rect y="{EGY}" width="{W}" height="{H - EGY}" fill="url(#soil)"/>')
    out.append(f'<rect y="{EGY}" width="{W}" height="5" fill="url(#ground)"/>')
    out.append('<rect x="150" y="0" width="12" height="220" fill="url(#pole)"/>')
    out.append(f'<rect x="0" y="40" width="162" height="6" fill="{ARM}"/>')
    lk = {'porc': 'porc', 'poly': 'poly', 'nick': 'porc', 'loose': 'poly', 'hang': 'porc'}[kind]
    out.append(f'<path d="M0 -4 Q50 -6 80 -2" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
    out.append(la_at(80, 40, 2.4, lk, 'ok', 'hang' if kind == 'hang' else 'ok'))
    cw = f'stroke="{COPPER}" stroke-width="2.6" fill="none" stroke-linecap="round"'
    # Top run: disconnector -> pole clip.
    if kind == 'hang':
        out.append(f'<path d="M146 100 Q128 104 118 126 Q114 134 108 136" {cw}/>')
        out.append(f'<path d="M108 136 l-3 2 M108 136 l-1 4 M108 136 l-4 -1" stroke="{COPPER}" stroke-width="1"/>')
    else:
        out.append(f'<path d="M80 64 Q80 82 100 82 L146 84 L146 100" {cw}/>')
    # Down the pole.
    if kind == 'nick':
        # Most of the strands cut through: two thin strands bridge a wide gap.
        out.append(f'<path d="M146 100 L146 112" {cw}/><path d="M146 132 L146 164" {cw}/>')
        out.append(f'<path d="M145.2 112 Q144 122 145.2 132 M146.8 112 Q148 122 146.8 132" stroke="{COPPER}" stroke-width="0.7" fill="none"/>')
        out.append(f'<path d="M146 112 l-6 5 M146 112 l6 5.4 M146 112 l-2 6.4 M146 132 l-6 -5 M146 132 l6 -5.4 M146 132 l2 -6.4" '
                   f'stroke="{COPPER}" stroke-width="1.3" stroke-linecap="round"/>')
    else:
        out.append(f'<path d="M146 100 L146 164" {cw}/>')
    # Into the soil to the rod clamp.
    if kind == 'loose':
        out.append(f'<path d="M146 164 Q146 172 132 174 L124 172" {cw}/>')
    else:
        out.append(f'<path d="M146 164 Q146 176 125 179" {cw}/>')
    for y in (98, 140):
        out.append(f'<rect x="141" y="{y}" width="10" height="4" rx="1" fill="{ARM}"/>')
    out.append('<rect x="116" y="172" width="4" height="44" fill="url(#steel)"/>')
    if kind == 'loose':
        out.append(f'<g transform="rotate(-18 118 182)"><rect x="110" y="176" width="16" height="8" rx="1.5" fill="{ARM}"/></g>')
        out.append('<circle cx="113" cy="181" r="1.8" fill="url(#steel)"/>')
    else:
        out.append(f'<rect x="110" y="176" width="16" height="8" rx="1.5" fill="{ARM}"/>')
        out.append('<circle cx="113" cy="180" r="1.8" fill="url(#steel)"/><circle cx="123" cy="180" r="1.8" fill="url(#steel)"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — patrol: the worker on the ground beside the transformer.
# --------------------------------------------------------------------------

def patrol_card(kind):
    if kind == 'hang':
        out = yard(discs=('ok', 'ok', 'hang'))
    elif kind == 'blown':
        out = yard(states=('ok', 'blown', 'ok'))
    else:
        out = yard()
    if kind == 'la':
        out.append(worker(172, ((162, 160), (150, 100)), face=-1, look=-16, point=(0, -1)))
    elif kind == 'rod':
        out.append(worker(172, ((162, 160), (157, 178)), face=-1, look=16, point=(0, -1)))
    else:  # walking on past, looking away
        out.append(worker(178, ((170, 160), (188, 160)), face=1, look=-4))
    return card_close(out)


CARDS = {
    'fit_porc': fit_card('porc'),
    'fit_poly': fit_card('poly'),
    'fit_one': fit_card('one'),
    'fit_far': fit_card('far'),
    'fit_none': fit_card('none'),
    'work_calm': work_card('calm'),
    'work_surge': work_card('surge'),
    'work_leak': work_card('leak'),
    'work_burn': work_card('burn'),
    'work_attract': work_card('attract'),
    'body_porc': body_card('porc'),
    'body_poly': body_card('poly'),
    'body_crack': body_card('crack'),
    'body_burnt': body_card('burnt'),
    'body_blown': body_card('blown'),
    'earth_porc': earth_card('porc'),
    'earth_poly': earth_card('poly'),
    'earth_nick': earth_card('nick'),
    'earth_loose': earth_card('loose'),
    'earth_hang': earth_card('hang'),
    'patrol_la': patrol_card('la'),
    'patrol_rod': patrol_card('rod'),
    'patrol_skip': patrol_card('skip'),
    'patrol_hang': patrol_card('hang'),
    'patrol_blown': patrol_card('blown'),
}

# Safe cards and traps per round (mirrors learn_board_pack35.dart).
ROUNDS = {
    'fit': (['fit_porc', 'fit_poly'], ['fit_one', 'fit_far', 'fit_none']),
    'work': (['work_calm', 'work_surge'], ['work_leak', 'work_burn', 'work_attract']),
    'body': (['body_porc', 'body_poly'], ['body_crack', 'body_burnt', 'body_blown']),
    'earth': (['earth_porc', 'earth_poly'], ['earth_nick', 'earth_loose', 'earth_hang']),
    'patrol': (['patrol_la', 'patrol_rod'], ['patrol_skip', 'patrol_hang', 'patrol_blown']),
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
