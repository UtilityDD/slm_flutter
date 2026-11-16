"""Picture cards for lesson 7.8 শেখা ("পরিবেশগত আইন: আমাদের দায়িত্ব").

python -I tool/m7_board78_art.py .

Writes assets/game/art/m7_board78/*.svg in the clean gradient style of
tool/m6_board63_art.py and tool/m7_board74_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art. What the cards show comes from
lesson 7.8 (live text) and the Module 7 rulings
(docs/module_specs/module7_rulings.md); the DTR in the background is the
WBSEDCL DTR with its AB switch opened (blades up, padlocked, tagged), never a
DO (ruling M7-9). Five rounds, each with the same frame on every card (so the
frame never says which picture is right) and the act in front of it:
  1. oil: the old transformer oil. Frame: the DTR with its drain valve, a
     leak-proof drum, a drain grate, a bare patch of soil, a van with its
     driver. Safe: the oil piped into the drum; the drum handed over to the
     approved recycling agency's van (its board carries the recycling mark).
     Traps: oil poured on the soil, into the roadside drain, into an open
     bucket, the drum onto an unmarked stranger's van;
  2. spill: oil leaking from the DTR onto the ground. Safe: a spill-kit boom
     round the puddle; absorbent pads on it. Traps: left to soak in, hosed
     towards the drain, soil kicked over it;
  3. ewaste: an old battery and a bad circuit board. Frame: the collection
     centre with its crate, the municipal garbage vat. Safe: the battery in
     the crate; the board in the crate. Traps: both in the vat, both buried,
     a cracked battery with acid on the ground;
  4. lamp: old tube lights and CFLs. Frame: the dustbin, a van. Safe: lamps
     laid whole in a box; the sealed box to the approved disposal agency's
     van. Traps: tubes snapped to fit a sack, CFLs in the dustbin, lamps
     tossed loose on the van bed;
  5. sep: waste after the job. Frame: a red bin for hazardous waste and a
     green general bin. Safe: the oily rag in the red bin; each waste in its
     own bin. Traps: oily rag with tea cups in the general bin, oily pads in
     the general bin, a small crew dumping everything ('the law is for
     factories').

Fairness (the playbook, section 4): every hand the dealer can make (one safe
card + any three traps) is checked: the safe card's backdrop is a trap's
backdrop too, each colour or gradient the safe card draws is drawn by a trap
in that hand (a scatter of gravel on the ground carries every colour of the
round on every card), and every prop or figure (tagged <!--prop:name-->) on
the safe card is on a trap in that hand, and none sits on every trap of the
hand but not on the safe card. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board78_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board78')
W, H = 200, 220
GY = 198

SHIRT_D = '#174A70'
SHIRT = '#1F5F8F'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
WHITE_HAT = '#F1F1EC'
BOOT = '#1C1F24'
WIRE = '#2B3138'
INK = '#4A5560'
PAPER = '#F4F1E6'
BANDAGE = '#FBFAF6'
VEST = '#F08A24'        # the contract crew's vest
VEST_D = '#C96C14'
HELPER = '#6E7F5A'      # the temporary helper's shirt
HELPER_D = '#56653F'
CAP = '#8A3B2E'         # the helper's cap
OFFICE = '#E3E8EC'      # an officer's shirt
OFFICE_D = '#C3CBD2'
OFF_PANTS = '#4B4F57'
COAT = '#F7F8F8'        # a doctor's / chemist's white coat
COAT_D = '#D5DADD'
SAREE = '#9C2D4A'
SAREE_D = '#7A2038'
KHAKI = '#A8935E'       # the gate guard
KHAKI_D = '#8A7748'
WOOD = '#8A6440'
WOOD_D = '#6B4A2E'
RED = '#C8352B'         # letter box, red cross, calendar head, crossed bolt
GREEN_NOTE = '#6FA36A'  # a bank note
ENVELOPE = '#C9A46A'
DRUM = '#3F7D5A'        # a chemical drum
DRUM_D = '#2F5F44'
HAZARD = '#F2C230'
BLANKET = '#7C9CC0'
PILLOW = '#ECEFF1'
SHELF = '#B9A47E'
BOTTLE = '#5C9BC4'
BOTTLE_2 = '#D98C3A'
MOVE = '#FFFFFF'

DEFS = """<defs>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9CC3E0"/><stop offset="0.62" stop-color="#E4E8E0"/><stop offset="1" stop-color="#BDB7A2"/></linearGradient>
  <linearGradient id="room" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9D2C2"/><stop offset="0.7" stop-color="#E8E2D4"/><stop offset="0.7" stop-color="#A89A82"/><stop offset="1" stop-color="#94866E"/></linearGradient>
  <linearGradient id="ward" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CFE3DA"/><stop offset="0.7" stop-color="#E3EEE8"/><stop offset="0.7" stop-color="#B8C4C0"/><stop offset="1" stop-color="#A3B0AC"/></linearGradient>
  <linearGradient id="bldg" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E9E1CF"/><stop offset="1" stop-color="#CFC4AC"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E4C9A2"/><stop offset="1" stop-color="#C8A87E"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#BFD9E8"/><stop offset="1" stop-color="#8FB3C8"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def tag(name):
    """An XML comment naming a prop or figure on the card. The fairness check
    (here and in test/learn_board_74_test.dart) reads these: no prop may sit
    only on the safe card of a hand, or be missing only from it."""
    return f'<!--prop:{name}-->'


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


# --------------------------------------------------------------------------
# People: the lineman of tool/m6_board63_art.py, plus the people of a claim
# (an officer, a doctor or chemist in a white coat, the wife, the gate
# guard, the supervisor in a white helmet).
# --------------------------------------------------------------------------

OUTFITS = {
    'lineman': dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='helmet'),
    'contract': dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='helmet', vest=True),
    'helper': dict(torso=HELPER, sb=HELPER_D, sf=HELPER, pants=PANTS, pants_d=PANTS_D, head='cap'),
    'super': dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='white'),
    'officer': dict(torso=OFFICE, sb=OFFICE_D, sf=OFFICE, pants=OFF_PANTS, pants_d=PANTS_D, head='bare'),
    'doctor': dict(torso=COAT, sb=COAT_D, sf=COAT, pants=OFF_PANTS, pants_d=PANTS_D, head='bare', coat=True),
    'wife': dict(torso=SAREE, sb=SAREE_D, sf=SAREE, pants=SAREE, pants_d=SAREE_D, head='bun', saree=True),
    'guard': dict(torso=KHAKI, sb=KHAKI_D, sf=KHAKI, pants=KHAKI_D, pants_d=KHAKI_D, head='beret'),
}

# The tag each kind of person carries (the props check).
KIND_TAG = {'lineman': 'lineman', 'contract': 'contract', 'helper': 'helper', 'super': 'supervisor',
            'officer': 'officer', 'doctor': 'medic', 'wife': 'wife', 'guard': 'guard'}


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


def _wrap(p, q, r=3.4):
    """A white bandage wrapped round a limb near p (towards q)."""
    t = 0.45
    x, y = p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{BANDAGE}" stroke="{INK}" stroke-width="0.5"/>'


def figure(hip, sh, head, feet, hands, face=1, look=0, kind='lineman', bandage=(), patch=False, phone=False, props_front=''):
    o = OUTFITS[kind]
    g = []
    fb, ff = feet
    if o.get('saree'):
        g.append(f'<path d="M{f(hip[0] - 9)} {f(hip[1] - 4)} L{f(hip[0] - 12)} {f(fb[1])} L{f(hip[0] + 12)} {f(fb[1])} L{f(hip[0] + 9)} {f(hip[1] - 4)} Z" fill="{SAREE_D}"/>')
    else:
        g.append(_limb(hip, _joint(hip, fb, face), fb, o['pants_d'], 7))
        g.append(_boot(fb, face))
        g.append(_limb(hip, _joint(hip, ff, face), ff, o['pants'], 7))
        g.append(_boot(ff, face))
        if 'leg' in bandage:
            g.append(_wrap(_joint(hip, ff, face), ff, 4))
    hb, hf = hands
    sb = (sh[0] - 2 * face, sh[1] + 3)
    sf = (sh[0] + 1 * face, sh[1] + 3)
    jb = _joint(sb, hb, face, down=True)
    g.append(_limb(sb, jb, hb, o['sb'], 5.4))
    g.append(f'<circle cx="{f(hb[0])}" cy="{f(hb[1])}" r="3" fill="{SKIN}"/>')
    dx, dy = sh[0] - hip[0], sh[1] - hip[1]
    n = math.hypot(dx, dy) or 1
    px, py = -dy / n * 7.5, dx / n * 7.5
    if o.get('coat'):
        g.append(f'<path d="M{f(hip[0] - px - 2)} {f(hip[1] + 14)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
                 f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px + 2)} {f(hip[1] + 14)} Z" fill="{o["torso"]}" stroke="{COAT_D}" stroke-width="0.6"/>')
        # stethoscope
        g.append(f'<path d="M{f(sh[0] - 3)} {f(sh[1] + 1)} Q{f(sh[0])} {f(sh[1] + 14)} {f(sh[0] + 3)} {f(sh[1] + 1)}" stroke="{WIRE}" stroke-width="1" fill="none"/>')
        g.append(f'<circle cx="{f(sh[0])}" cy="{f(sh[1] + 12)}" r="1.6" fill="{WIRE}"/>')
    else:
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py)} L{f(sh[0] - px)} {f(sh[1] - py - 1)} Q{f(sh[0])} {f(sh[1] - 4)} '
                 f'{f(sh[0] + px)} {f(sh[1] + py - 1)} L{f(hip[0] + px)} {f(hip[1] + py)} Z" fill="{o["torso"]}"/>')
        if not o.get('saree'):
            g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - py - 3)} L{f(hip[0] + px)} {f(hip[1] + py - 3)}" stroke="{PANTS_D}" stroke-width="2.4"/>')
    if o.get('vest'):
        g.append(f'<path d="M{f(hip[0] - px * 0.9)} {f(hip[1] - py - 2)} L{f(sh[0] - px * 0.9)} {f(sh[1] - py + 3)} L{f(sh[0] - px * 0.2)} {f(sh[1] + 2)} '
                 f'L{f(hip[0] - px * 0.2)} {f(hip[1] - 2)} Z" fill="{VEST}"/>')
        g.append(f'<path d="M{f(hip[0] + px * 0.2)} {f(hip[1] - 2)} L{f(sh[0] + px * 0.2)} {f(sh[1] + 2)} L{f(sh[0] + px * 0.9)} {f(sh[1] + py + 3)} '
                 f'L{f(hip[0] + px * 0.9)} {f(hip[1] + py - 2)} Z" fill="{VEST}"/>')
        g.append(f'<path d="M{f(hip[0] - px)} {f(hip[1] - 12)} L{f(hip[0] + px)} {f(hip[1] - 12)}" stroke="{VEST_D}" stroke-width="1.6"/>')
    hx, hy = head
    a = look * face
    hd = [f'<rect x="{f(hx - 3)}" y="{f(hy + 4)}" width="6" height="6" rx="2" fill="{SKIN_D}"/>',
          f'<circle cx="{f(hx)}" cy="{f(hy)}" r="7" fill="{SKIN}"/>',
          f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="{HAIR}"/>',
          f'<circle cx="{f(hx + 4 * face)}" cy="{f(hy + 1)}" r="1.1" fill="{HAIR}"/>']
    if patch:
        hd.append(f'<path d="M{f(hx - 7 * face)} {f(hy - 2)} L{f(hx + 6 * face)} {f(hy + 2)}" stroke="{WIRE}" stroke-width="0.9"/>')
        hd.append(f'<ellipse cx="{f(hx + 4 * face)}" cy="{f(hy + 0.5)}" rx="3.2" ry="2.8" fill="{WIRE}"/>')
    hk = o['head']
    if hk in ('helmet', 'white'):
        top, rim = (HELMET, HELMET_D) if hk == 'helmet' else (WHITE_HAT, OFFICE_D)
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 1)} A8 8 0 0 1 {f(hx + 8)} {f(hy - 1)} Z" fill="{top}"/>')
        hd.append(f'<rect x="{f(hx - 8 if face > 0 else hx - 12)}" y="{f(hy - 2.4)}" width="20" height="2.8" rx="1.3" fill="{rim}"/>')
    elif hk == 'cap':
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 6 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="{CAP}"/>')
        hd.append(f'<rect x="{f(hx if face > 0 else hx - 11)}" y="{f(hy - 2)}" width="11" height="2.2" rx="1" fill="{CAP}"/>')
    elif hk == 'beret':
        hd.append(f'<path d="M{f(hx - 8)} {f(hy - 2)} Q{f(hx)} {f(hy - 11)} {f(hx + 8)} {f(hy - 2)} Z" fill="{KHAKI_D}"/>')
    elif hk == 'bun':
        hd.append(f'<path d="M{f(hx - 7)} {f(hy)} A7 7 0 0 1 {f(hx + 7)} {f(hy)} Z" fill="{HAIR}"/>')
        hd.append(f'<circle cx="{f(hx - 7 * face)}" cy="{f(hy + 1)}" r="3.2" fill="{HAIR}"/>')
        hd.append(f'<path d="M{f(hx - 8)} {f(hy + 2)} Q{f(hx - 9 * face)} {f(hy - 7)} {f(hx + 2 * face)} {f(hy - 8)}" stroke="{SAREE}" stroke-width="2.4" fill="none"/>')
    else:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="{HAIR}"/>')
    if 'head' in bandage:
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 3)} L{f(hx + 7)} {f(hy - 3)}" stroke="{BANDAGE}" stroke-width="2.6"/>')
    g.append(f'<g transform="rotate({f(a)} {f(hx)} {f(hy + 5)})">' + ''.join(hd) + '</g>')
    jf = _joint(sf, hf, face, down=True)
    g.append(_limb(sf, jf, hf, o['sf'], 5.4))
    if 'arm' in bandage:
        g.append(_wrap(jf, hf))
    g.append(props_front)
    if phone:
        g.append(f'<rect x="{f(hf[0] - 2.5)}" y="{f(hf[1] - 6)}" width="5" height="9" rx="1" fill="{WIRE}"/>'
                 f'<rect x="{f(hf[0] - 1.6)}" y="{f(hf[1] - 5)}" width="3.2" height="6" fill="url(#lcd)"/>')
    g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3" fill="{SKIN}"/>')
    if 'hand' in bandage:
        g.append(f'<circle cx="{f(hf[0])}" cy="{f(hf[1])}" r="3.4" fill="{BANDAGE}" stroke="{INK}" stroke-width="0.5"/>')
    return ''.join(g)


S = 1.3  # people's scale


def person(x, hands_world, face=-1, look=0, gy=GY, s=S, kind='lineman', bandage=(), patch=False, phone=False):
    """A standing person at x (feet on gy), scaled [s] about the feet; the
    hands are given in card coordinates. With [phone], the front hand goes to
    his ear."""
    def local(p):
        return (x + (p[0] - x) / s, gy + (p[1] - gy) / s)
    hip = (x, gy - 30)
    sh = (x + 1 * face, gy - 56)
    head = (x + 3 * face, gy - 64)
    feet = ((x - 7 * face, gy - 1), (x + 6 * face, gy - 1))
    hb = local(hands_world[0])
    hf = (head[0] - 5 * face, head[1] + 2) if phone else local(hands_world[1])
    fig = figure(hip, sh, head, feet, (hb, hf), face, look, kind, bandage, patch, phone)
    tags = tag(KIND_TAG[kind]) + (tag('phone') if phone else '') + (tag('bandage') if bandage or patch else '')
    return tags + f'<g transform="translate({f(x)} {f(gy)}) scale({s}) translate({f(-x)} {f(-gy)})">{fig}</g>'



# --------------------------------------------------------------------------
# Things of lesson 7.8: oil, spill kit, e-waste, lamps, bins.
# --------------------------------------------------------------------------

OIL = '#2B2420'
OIL_HI = '#5A4A3E'
SOIL = '#7A5A3A'
SOIL_D = '#5E4429'
PADG = '#C9CFD4'
PADG_D = '#8E979E'
ORANGE = '#F08A24'
ORANGE_D = '#C96C14'
WATER = '#5C9BC4'
WATER_D = '#3C7FA8'
VANW = '#EDEFF0'
VAN_D = '#C3CBD2'
GRASS = '#6FA36A'
CARDB = '#C9A46A'
CARDB_D = '#A8844A'
FOAM = '#E9E4D8'
ACID = '#B8D43A'
PCB = '#2F7D4F'
CHIP = '#1F2A30'
BATT = '#3A4048'
CRATE = '#3C6E91'
CRATE_D = '#2B5270'
TANK = '#7D8A94'
TANK_D = '#5F6B74'
LOCKC = '#C9A23A'
BIN_RED = '#C8352B'
BIN_RED_D = '#9A2820'
RAG = '#B9B3A6'
TUBE = '#F4F1E6'
VATC = '#8A8F78'
INSUL = '#B8653A'       # porcelain pin insulators
CUP = '#E9E4D8'


def gravel(rnd, colors):
    """A scatter of gravel on the ground, in every colour of the round, the
    same on every card (so no colour belongs to one picture only)."""
    seed = sum(ord(c) for c in rnd) * 7919 + 13
    o = []
    for i, c in enumerate(colors):
        for k in range(2):
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            x = 6 + (seed >> 8) % 188
            seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
            y = 201 + (seed >> 8) % 15
            o.append(f'<circle cx="{x}" cy="{y}" r="{1.5 + (i + k) % 3 * 0.3:.1f}" fill="{c}"/>')
    return ''.join(o)


def dtr():
    """The WBSEDCL DTR on its double pole, its AB switch opened (blades up),
    padlocked and tagged (ruling M7-9); the oil drain valve at the tank's
    right foot, (52, 114)."""
    x = 4
    o = [tag('dtr')]
    for px in (x + 12, x + 30):
        o.append(f'<rect x="{px}" y="38" width="6" height="{GY - 38}" fill="url(#pole)"/>')
    o.append(f'<rect x="{x}" y="42" width="46" height="4" rx="1" fill="{INK}"/>')
    for i in range(3):
        bx = x + 8 + i * 15
        o.append(f'<rect x="{bx - 2}" y="40" width="4" height="4" rx="1.5" fill="{INSUL}"/>')
        o.append(f'<path d="M{bx} 40 L{bx + 5} 26" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>')
    o.append(f'<rect x="{x + 20}" y="48" width="7" height="6" rx="1" fill="{LOCKC}"/>')
    o.append(f'<rect x="{x + 29}" y="49" width="5" height="8" rx="1" fill="{RED}"/>')
    o.append(f'<rect x="{x + 4}" y="86" width="42" height="34" rx="3" fill="{TANK}"/>')
    for i in range(5):
        o.append(f'<path d="M{x + 10 + i * 8} 90 v26" stroke="{TANK_D}" stroke-width="1.4"/>')
    for bx in (x + 10, x + 24, x + 38):
        o.append(f'<rect x="{bx - 2}" y="81" width="4" height="6" rx="1.5" fill="{INSUL}"/>')
    o.append(f'<circle cx="52" cy="114" r="3" fill="{INK}"/>')
    return ''.join(o)


def leak(x1, y1):
    """Oil seeping from the valve at (52, 114) down to (x1, y1)."""
    return (f'<path d="M52 117 Q{f(52 + (x1 - 52) * 0.2)} {f((117 + y1) / 2)} {f(x1)} {f(y1)}" stroke="{OIL}" stroke-width="2.4" '
            'fill="none" stroke-linecap="round"/>')


def van(x=140, base=170, board=False):
    """The van behind the yard; [board] = the approved agency's green board
    with its recycling mark (three arrows round a ring)."""
    o = [tag('van'),
         f'<rect x="{x}" y="{base - 38}" width="42" height="30" rx="3" fill="{VANW}" stroke="{VAN_D}" stroke-width="1"/>',
         f'<path d="M{x + 42} {base - 30} h8 l9 12 v10 h-17 Z" fill="{VANW}" stroke="{VAN_D}" stroke-width="1"/>',
         f'<path d="M{x + 45} {base - 27} h4 l5 8 h-9 Z" fill="url(#glass)"/>']
    for wx in (x + 10, x + 49):
        o.append(f'<circle cx="{wx}" cy="{base - 6}" r="6" fill="{WIRE}"/><circle cx="{wx}" cy="{base - 6}" r="2.2" fill="{VAN_D}"/>')
    if board:
        o.append(f'<rect x="{x + 5}" y="{base - 34}" width="32" height="20" rx="2" fill="{DRUM}"/>')
        cx, cy, r = x + 21, base - 24, 6.5
        for k in range(3):
            a0 = math.radians(k * 120 + 15)
            a1 = math.radians(k * 120 + 100)
            p0 = (cx + r * math.cos(a0), cy + r * math.sin(a0))
            p1 = (cx + r * math.cos(a1), cy + r * math.sin(a1))
            o.append(f'<path d="M{f(p0[0])} {f(p0[1])} A{r} {r} 0 0 1 {f(p1[0])} {f(p1[1])}" stroke="{MOVE}" stroke-width="1.8" fill="none"/>')
            o.append(f'<circle cx="{f(p1[0])}" cy="{f(p1[1])}" r="1.9" fill="{MOVE}"/>')
    return ''.join(o)


def drum(cx, base, w=24, h=38, funnel=False):
    x = cx - w / 2
    o = [tag('container'), f'<rect x="{f(x)}" y="{base - h}" width="{w}" height="{h}" rx="3" fill="{DRUM}"/>',
         f'<ellipse cx="{cx}" cy="{base - h}" rx="{w / 2}" ry="3" fill="{DRUM_D}"/>',
         f'<circle cx="{f(cx + w * 0.22)}" cy="{base - h}" r="1.6" fill="{INK}"/>']
    for k in (0.33, 0.66):
        o.append(f'<path d="M{f(x)} {f(base - h * k)} h{w}" stroke="{DRUM_D}" stroke-width="1.6"/>')
    if funnel:
        o.append(f'<path d="M{f(cx - 6)} {base - h - 8} h12 l-4 8 h-4 Z" fill="{PADG_D}"/>')
    return ''.join(o)


def bucket(cx, base):
    return (tag('container') +
            f'<path d="M{cx - 11} {base - 20} h22 l-3 20 h-16 Z" fill="{PADG_D}"/>'
            f'<ellipse cx="{cx}" cy="{base - 20}" rx="11" ry="3" fill="{OIL}"/>'
            f'<path d="M{cx - 11} {base - 20} Q{cx} {base - 38} {cx + 11} {base - 20}" stroke="{INK}" stroke-width="1.2" fill="none"/>')


def jerrycan(cx, cy, ang):
    return (tag('container') + f'<g transform="rotate({ang} {cx} {cy})">'
            f'<rect x="{cx - 8}" y="{cy - 10}" width="16" height="20" rx="2.5" fill="{ORANGE}"/>'
            f'<rect x="{cx - 5}" y="{cy - 15}" width="8" height="6" rx="1.5" fill="{ORANGE_D}"/>'
            f'<path d="M{cx + 3} {cy - 12} l6 -3" stroke="{ORANGE_D}" stroke-width="2.4" stroke-linecap="round"/></g>')


def stream(x0, y0, x1, y1, w=2.6, color=OIL):
    return (f'<path d="M{f(x0)} {f(y0)} Q{f((x0 + x1) / 2 + 3)} {f((y0 + y1) / 2 - 4)} {f(x1)} {f(y1)}" stroke="{color}" '
            f'stroke-width="{w}" fill="none" stroke-linecap="round"/>')


def puddle(cx, cy, rx, ry):
    return (tag('puddle') + f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{OIL}"/>'
            f'<ellipse cx="{f(cx - rx * 0.3)}" cy="{f(cy - ry * 0.25)}" rx="{f(rx * 0.3)}" ry="{f(ry * 0.3)}" fill="{OIL_HI}"/>')


def soil_patch(cx, cy, rx, ry):
    o = [tag('soil'), f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{SOIL}"/>']
    for dx, dy in ((-0.5, -0.2), (0.1, 0.3), (0.5, -0.1), (-0.1, -0.4)):
        o.append(f'<circle cx="{f(cx + dx * rx)}" cy="{f(cy + dy * ry)}" r="1.4" fill="{SOIL_D}"/>')
    return ''.join(o)


def drain_grate(x, y, w=44, h=10):
    o = [tag('drain'), f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="{PADG_D}"/>']
    for i in range(1, 7):
        o.append(f'<path d="M{f(x + i * w / 7)} {y + 1} v{h - 2}" stroke="{INK}" stroke-width="1.3"/>')
    return ''.join(o)


def pad(x, y, ang=0, dirty=False):
    o = (f'<g transform="rotate({ang} {x + 10} {y + 6})"><rect x="{x}" y="{y}" width="20" height="12" rx="1.5" fill="{PADG}" '
         f'stroke="{PADG_D}" stroke-width="0.8"/>')
    if dirty:
        o += f'<circle cx="{x + 6}" cy="{y + 5}" r="2.6" fill="{OIL}"/><circle cx="{x + 14}" cy="{y + 7}" r="2" fill="{OIL}"/>'
    return o + '</g>'


def shovel(x0, y0, x1, y1):
    return (tag('gear') + f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{WOOD_D}" stroke-width="2.4" stroke-linecap="round"/>'
            f'<path d="M{f(x1 - 5)} {f(y1 - 1)} h10 l-1 8 q-4 3 -8 0 Z" fill="{INK}"/>')


def battery(x, y, cracked=False):
    o = [tag('ewaste'), f'<rect x="{x}" y="{y}" width="22" height="14" rx="1.5" fill="{BATT}"/>',
         f'<rect x="{x + 3}" y="{y - 3}" width="4" height="3" fill="{RED}"/><rect x="{x + 15}" y="{y - 3}" width="4" height="3" fill="{PADG_D}"/>',
         f'<rect x="{x + 6}" y="{y + 4}" width="10" height="5" fill="{HAZARD}"/>']
    if cracked:
        o.append(f'<path d="M{x + 12} {y} l-3 5 l4 3 l-3 6" stroke="{PADG}" stroke-width="1.2" fill="none"/>')
    return ''.join(o)


def pcb(x, y):
    return (tag('ewaste') + f'<rect x="{x}" y="{y}" width="24" height="16" rx="1.5" fill="{PCB}"/>'
            f'<rect x="{x + 3}" y="{y + 3}" width="7" height="6" fill="{CHIP}"/><rect x="{x + 13}" y="{y + 7}" width="8" height="6" fill="{CHIP}"/>'
            f'<path d="M{x + 10} {y + 6} h6 v-3 M{x + 3} {y + 13} h9" stroke="{HAZARD}" stroke-width="0.9" fill="none"/>')


def crate(x, y, w=38, h=24):
    return (tag('crate') + f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="2" fill="{CRATE}"/>'
            f'<path d="M{x + 3} {y + 8} h{w - 6} M{x + 3} {y + 16} h{w - 6}" stroke="{CRATE_D}" stroke-width="1.6"/>')


def centre():
    """The company's collection centre: a small block with its crate out front."""
    return (tag('centre') + '<rect x="132" y="108" width="66" height="62" fill="url(#bldg)"/>'
            f'<rect x="128" y="102" width="74" height="9" rx="1.5" fill="{WIRE}"/>'
            f'<rect x="150" y="130" width="20" height="40" fill="{WOOD_D}"/>'
            '<rect x="178" y="122" width="14" height="14" fill="url(#glass)"/>' + crate(140, 166))


def vat():
    """The municipal garbage vat at the road edge, heaped with refuse."""
    return (tag('vat') + f'<rect x="4" y="138" width="46" height="34" rx="2" fill="{VATC}"/>'
            f'<path d="M2 138 q10 -14 22 -6 q10 -10 24 -2 l2 8 Z" fill="{GRASS}"/>'
            f'<rect x="12" y="130" width="10" height="7" fill="{CARDB}"/><rect x="32" y="128" width="9" height="6" fill="{PAPER}"/>')


def tube(x1, y1, x2, y2):
    return (tag('lamp') + f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{TUBE}" stroke-width="3.6" stroke-linecap="round"/>'
            f'<path d="M{f(x1)} {f(y1)} l1 0 M{f(x2)} {f(y2)} l1 0" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>')


def cfl(x, y):
    return (tag('lamp') + f'<path d="M{x - 4} {y} q4 -4 8 0 q-4 4 -8 0 M{x - 4} {y - 5} q4 -4 8 0 q-4 4 -8 0" stroke="{TUBE}" stroke-width="2.4" fill="none"/>'
            f'<rect x="{x - 4}" y="{y + 1}" width="8" height="5" rx="1" fill="{INK}"/>')


def lampbox(x, y, w=44, h=22, open_=True, sealed=False):
    o = [tag('lampbox'), f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="{CARDB}" stroke="{CARDB_D}" stroke-width="1"/>']
    if open_:
        o.append(f'<rect x="{x + 3}" y="{y + 3}" width="{w - 6}" height="{h - 8}" fill="{FOAM}"/>')
    if sealed:
        o.append(tag('lamp'))  # the lamps are inside
        o.append(f'<rect x="{f(x + w / 2 - 3)}" y="{y}" width="6" height="{h}" fill="{PAPER}"/>')
    return ''.join(o)


def dustbin(x, y):
    return (tag('dustbin') + f'<path d="M{x} {y} h24 l-3 30 h-18 Z" fill="{PADG_D}"/>'
            f'<rect x="{x - 2}" y="{y - 4}" width="28" height="5" rx="1.5" fill="{INK}"/>')


def hazbin(x, y):
    """The red bin for hazardous waste."""
    return (tag('hazbin') + f'<path d="M{x} {y} h24 l-2 34 h-20 Z" fill="{BIN_RED}"/>'
            f'<rect x="{x - 2}" y="{y - 4}" width="28" height="5" rx="1.5" fill="{BIN_RED_D}"/>'
            f'<path d="M{x + 12} {y + 8} l6 11 h-12 Z" fill="{HAZARD}"/>')


def genbin(x, y):
    """The green bin for general waste."""
    return (tag('genbin') + f'<path d="M{x} {y} h24 l-2 34 h-20 Z" fill="{DRUM}"/>'
            f'<rect x="{x - 2}" y="{y - 4}" width="28" height="5" rx="1.5" fill="{DRUM_D}"/>')


def rag(x, y, ang=0):
    return (tag('waste') + f'<g transform="rotate({ang} {x} {y})"><path d="M{x - 9} {y} q3 -7 9 -4 q8 -4 9 4 q-2 6 -9 5 q-8 2 -9 -5 Z" fill="{RAG}"/>'
            f'<circle cx="{x - 3}" cy="{y}" r="2.4" fill="{OIL}"/><circle cx="{x + 4}" cy="{y + 1}" r="1.8" fill="{OIL}"/></g>')


def cupw(x, y):
    return (tag('waste') + f'<path d="M{x - 3} {y - 5} h6 l-1 7 h-4 Z" fill="{CUP}" stroke="{INK}" stroke-width="0.5"/>')


def paperw(x, y, ang=0):
    return tag('waste') + f'<rect x="{x - 5}" y="{y - 3}" width="10" height="7" fill="{PAPER}" stroke="{INK}" stroke-width="0.4" transform="rotate({ang} {x} {y})"/>'


def thought_factory(x, y):
    return (tag('bubble') + f'<ellipse cx="{x}" cy="{y}" rx="19" ry="14" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>'
            f'<circle cx="{x + 12}" cy="{y + 18}" r="3" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>'
            f'<circle cx="{x + 17}" cy="{y + 24}" r="1.8" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>'
            f'<rect x="{x - 11}" y="{y - 2}" width="20" height="10" fill="{INK}"/>'
            f'<rect x="{x - 8}" y="{y - 9}" width="4" height="8" fill="{INK}"/><rect x="{x}" y="{y - 7}" width="4" height="6" fill="{INK}"/>'
            f'<path d="M{x - 6} {y - 11} q-3 -3 0 -5" stroke="{PADG_D}" stroke-width="1.2" fill="none"/>')


# --------------------------------------------------------------------------
# Round 1 — oil.
# --------------------------------------------------------------------------

def oil_card(kind, U):
    out = card_open('yard')
    out.append(gravel('oil', U))
    out.append(dtr())
    out.append(soil_patch(64, 208, 26, 6))
    out.append(drain_grate(104, 204))
    out.append(van(140, 170, board=kind == 'agency'))
    out.append(person(186, ((180, 164), (192, 166)), face=-1, look=0, gy=194, s=1.0,
                      kind='helper' if kind == 'stranger' else 'contract'))
    if kind in ('agency', 'stranger'):
        out.append(f'<path d="M110 186 L142 160" stroke="{WOOD}" stroke-width="4" stroke-linecap="round"/>')
    out.append(drum(122, 186, funnel=kind == 'drum'))
    if kind == 'drum':
        out.append(stream(52, 116, 118, 144, 3))
        out.append(person(72, ((60, 160), (100, 128)), face=1, look=6))
    elif kind == 'bucket':
        out.append(bucket(98, 198))
        out.append(stream(52, 116, 98, 176, 3))
        out.append(person(60, ((50, 160), (86, 142)), face=1, look=8))
    elif kind == 'soil':
        out.append(stream(68, 164, 64, 204, 2.6))
        out.append(jerrycan(76, 154, -62))
        out.append(person(104, ((100, 164), (80, 152)), face=-1, look=8))
    elif kind == 'drain':
        out.append(stream(110, 164, 114, 205, 2.6))
        out.append(jerrycan(98, 152, 62))
        out.append(person(72, ((64, 164), (94, 152)), face=1, look=8))
    else:  # agency / stranger: the drum pushed up to the van
        out.append(person(80, ((70, 160), (112, 152)), face=1, look=-4))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — spill.
# --------------------------------------------------------------------------

def spill_card(kind, U):
    out = card_open('yard')
    out.append(gravel('spill', U))
    out.append(dtr())
    out.append(drain_grate(150, 206, 42, 9))
    big = kind == 'leave'
    out.append(leak(58, 198))
    out.append(puddle(88, 205, 58 if big else 42, 10 if big else 8))
    if kind == 'boom':
        out.append(tag('gear') + f'<ellipse cx="88" cy="205" rx="54" ry="13" fill="none" stroke="{ORANGE}" stroke-width="7"/>'
                   f'<ellipse cx="88" cy="205" rx="54" ry="13" fill="none" stroke="{ORANGE_D}" stroke-width="7" stroke-dasharray="3 6"/>')
        out.append(person(150, ((142, 168), (128, 196)), face=-1, look=10))
    elif kind == 'pads':
        out.append(tag('gear') + pad(66, 198, -8) + pad(88, 202, 6) + pad(106, 197, -4))
        out.append(person(150, ((142, 168), (126, 172)), face=-1, look=12))
        out.append(pad(114, 164, -10))
    elif kind == 'leave':
        out.append(person(150, ((144, 168), (156, 168)), face=1, look=-6))
    elif kind == 'wash':
        out.append(tag('gear') + f'<path d="M200 168 Q178 150 150 176 T118 170" stroke="{WATER_D}" stroke-width="3" fill="none" stroke-linecap="round"/>')
        out.append(f'<path d="M116 171 L96 196 M118 172 L110 198 M114 170 L84 192" stroke="{WATER}" stroke-width="1.6" stroke-linecap="round"/>')
        out.append(f'<path d="M128 208 Q150 214 156 210" stroke="{OIL}" stroke-width="3" fill="none" stroke-linecap="round"/>')
        out.append(person(150, ((144, 168), (120, 170)), face=-1, look=10))
    else:  # cover
        out.append(f'<ellipse cx="72" cy="206" rx="30" ry="8" fill="{SOIL}"/>')
        out.append(f'<circle cx="62" cy="204" r="1.6" fill="{SOIL_D}"/><circle cx="80" cy="207" r="1.6" fill="{SOIL_D}"/>')
        out.append(shovel(150, 150, 110, 186))
        out.append(f'<circle cx="104" cy="178" r="2.2" fill="{SOIL}"/><circle cx="98" cy="184" r="1.8" fill="{SOIL}"/>')
        out.append(person(150, ((142, 168), (124, 170)), face=-1, look=10))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — ewaste.
# --------------------------------------------------------------------------

def ewaste_card(kind, U):
    out = card_open('yard')
    out.append(gravel('ewaste', U))
    out.append(vat())
    out.append(centre())
    if kind == 'battery':
        out.append(person(112, ((106, 164), (128, 150)), face=1, look=8))
        out.append(battery(132, 148))
    elif kind == 'board':
        out.append(person(112, ((106, 164), (128, 150)), face=1, look=8))
        out.append(pcb(130, 146))
    elif kind == 'vat':
        out.append(person(76, ((82, 164), (50, 148)), face=-1, look=8))
        out.append(battery(36, 124) + pcb(22, 112))
    elif kind == 'bury':
        out.append(f'<ellipse cx="94" cy="208" rx="24" ry="6" fill="{OIL}"/>')
        out.append(battery(84, 200) + pcb(98, 203))
        out.append(f'<ellipse cx="124" cy="208" rx="16" ry="5" fill="{SOIL}"/>')
        out.append(shovel(130, 150, 108, 198))
        out.append(person(80, ((72, 168), (100, 164)), face=1, look=10))
    else:  # acid
        # left cracked on the ground, away from the crate; he walks off
        out.append(f'<ellipse cx="108" cy="210" rx="22" ry="5" fill="{ACID}"/>')
        out.append(battery(96, 198, cracked=True))
        out.append(f'<path d="M104 212 q-6 3 -12 2" stroke="{ACID}" stroke-width="2" stroke-linecap="round" fill="none"/>')
        out.append(person(62, ((56, 164), (70, 166)), face=-1, look=-6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — lamp.
# --------------------------------------------------------------------------

def lamp_card(kind, U):
    out = card_open('yard')
    out.append(gravel('lamp', U))
    out.append(dustbin(8, 136))
    out.append(van(140, 170, board=kind == 'agency'))
    if kind == 'box':
        out.append(lampbox(80, 168, 50, 24))
        out.append(tube(86, 176, 124, 176) + tube(88, 182, 122, 182) + cfl(94, 188))
        out.append(person(60, ((52, 160), (88, 164)), face=1, look=10))
    elif kind == 'agency':
        out.append(lampbox(104, 160, 40, 28, open_=False, sealed=True))
        out.append(person(80, ((74, 166), (108, 164)), face=1, look=-2))
    elif kind == 'snap':
        out.append(lampbox(130, 176, 44, 20, open_=False))
        out.append(f'<path d="M64 162 l-8 -4 M64 162 l-3 -9 M66 164 l-9 3" stroke="{HAZARD}" stroke-width="1.6" stroke-linecap="round"/>')
        out.append(tube(48, 176, 62, 164) + tube(66, 164, 80, 176))
        out.append(f'<path d="M56 190 l5 4 M70 188 l-2 6 M76 192 l7 2" stroke="{TUBE}" stroke-width="2" stroke-linecap="round"/>')
        out.append(person(70, ((62, 164), (62, 164)), face=1, look=10))
    elif kind == 'bin':
        out.append(lampbox(130, 176, 44, 20, open_=False))
        out.append(cfl(30, 130) + cfl(22, 124))
        out.append(person(60, ((52, 160), (40, 140)), face=-1, look=10))
    else:  # toss
        out.append(lampbox(130, 176, 44, 20, open_=False))
        out.append(tube(120, 140, 150, 132) + tube(112, 150, 140, 158))
        out.append(f'<path d="M144 150 l6 -2 M142 160 l4 4" stroke="{TUBE}" stroke-width="2" stroke-linecap="round"/>')
        out.append(person(90, ((80, 164), (112, 144)), face=1, look=-6))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — sep.
# --------------------------------------------------------------------------

def sep_card(kind, U):
    out = card_open('yard')
    out.append(gravel('sep', U))
    out.append(hazbin(128, 150))
    out.append(genbin(160, 150))
    if kind == 'rag':
        out.append(rag(136, 144, 20))
        out.append('<!--held:136-->')
        out.append(person(88, ((80, 164), (120, 148)), face=1, look=8))
        out.append(rag(122, 150))
    elif kind == 'two':
        out.append(rag(140, 150, 10) + cupw(168, 146) + paperw(172, 150, 14))
        out.append(person(88, ((80, 164), (170, 144)), face=1, look=8))
        out.append(cupw(170, 138))
        out.append('<!--held:170-->')
    elif kind == 'mixed':
        out.append(rag(166, 148, 14) + cupw(158, 146) + paperw(174, 148, -12))
        out.append(person(88, ((80, 164), (170, 144)), face=1, look=8))
        out.append(rag(172, 138))
        out.append('<!--held:172-->')
    elif kind == 'pads':
        out.append(pad(158, 144, -14, dirty=True) + cupw(174, 146))
        out.append(person(88, ((80, 164), (170, 144)), face=1, look=8))
        out.append(pad(162, 136, -10, dirty=True))
        out.append('<!--held:172-->')
    else:  # smallcrew
        out.append(rag(166, 148, 14) + cupw(158, 146))
        out.append(person(58, ((50, 164), (62, 160)), face=1, look=-4, kind='contract'))
        out.append(person(88, ((80, 164), (170, 144)), face=1, look=8))
        out.append(person(36, ((28, 164), (40, 160)), face=1, look=4, kind='helper'))
        out.append(thought_factory(76, 46))
        out.append(rag(172, 138))
        out.append('<!--held:172-->')
    return card_close(out)


ROUNDS = {
    'oil': (['drum', 'agency'], ['soil', 'drain', 'bucket', 'stranger'], oil_card),
    'spill': (['boom', 'pads'], ['leave', 'wash', 'cover'], spill_card),
    'ewaste': (['battery', 'board'], ['vat', 'bury', 'acid'], ewaste_card),
    'lamp': (['box', 'agency'], ['snap', 'bin', 'toss'], lamp_card),
    'sep': (['rag', 'two'], ['mixed', 'pads', 'smallcrew'], sep_card),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_HEX = re.compile(r'#[0-9A-Fa-f]{6}\b')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')

CARDS = {}
for _rnd, (_safes, _traps, _fn) in ROUNDS.items():
    _kinds = _safes + _traps
    # pass 1: the round's colours; pass 2: the same gravel on every card.
    _colors = sorted({t for k in _kinds for t in _HEX.findall(_fn(k, []).split('</defs>')[-1])})
    for _k in _kinds:
        CARDS[f'{_rnd}_{_k}'] = _fn(_k, _colors)


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    for rnd, (safes, traps, _fn) in ROUNDS.items():
        for s in safes:
            s = f'{rnd}_{s}'
            for hand in itertools.combinations([f'{rnd}_{t}' for t in traps], HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
                trap_props = [props[t] for t in hand]
                alone = props[s] - set().union(*trap_props)
                missing = set.intersection(*trap_props) - props[s]
                if alone:
                    problems.append(f'{rnd}: {s} with {hand} has props {sorted(alone)} alone')
                if missing:
                    problems.append(f'{rnd}: {s} with {hand} alone lacks props {sorted(missing)}')
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
