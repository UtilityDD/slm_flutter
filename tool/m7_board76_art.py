"""Picture cards for lesson 7.6 শেখা ("ব্যক্তিগত সুরক্ষা সরঞ্জাম (PPE) সংক্রান্ত আইন").

python -I tool/m7_board76_art.py .

Writes assets/game/art/m7_board76/*.svg in the clean gradient style of
tool/m7_board74_art.py (200 x 220 scene cards, drawn edge to edge). No words in
the art; the marks a worker reads (the IS code on a plate, the cuff label
"4770" and the glove type digit, the docket's "11", a diary's date) are stroke
glyphs with English digits. The IS mark is a plain white roundel with a dark
rim (no colour of its own, so it never stands out as the safe colour).

What the cards show comes from lesson 7.6 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md) only. Five rounds:
  1. source: the store counter (issue register, helmet and gloves, no money);
     the supervisor at the van handing a boxed safety shoe. Traps: paying cash
     at a roadside stall, a shiny market helmet with no mark, an empty shelf
     with the lineman walking off to the pole;
  2. glove: the docket says 11 kV work (the card shows "11" and a cross-arm).
     The glove with the cuff label 4770 and type 4, in the lineman's hand and
     in the storekeeper's. Traps: plain gloves with no marking, the type 2
     cuff, a type 4 glove torn across the palm, an unlabelled pair in a shop
     bag (ruling X3 / O3: never "11 kV gloves");
  3. mark: the code plate beside the item: helmet 2925 with the IS mark, shoe
     15298 with the IS mark. Traps: the helmet plate with no mark, the helmet
     stamped 15298, the shoe plate with no mark, the shoe stamped 2925;
  4. duty: wiping the helmet and gloves into the kit bag, showing a torn glove
     to the supervisor, wearing the issued helmet and gloves at the pole.
     Traps: the helmet hung on the van mirror with the lineman bareheaded, a
     cracked helmet slipped into the bag, mud-caked gloves among spanners, a
     grey-haired senior at the pole with no helmet or gloves;
  5. size: snug gloves and boots; a trainer showing a new harness on the
     ground; a diary line with a date and a name. Traps: gloves too big,
     boots too small, a new harness climbed straight from the box, a diary
     line with no date and no name.

Fairness (the playbook, section 4): every hand the dealer can make (one safe
card + any three traps) is checked: each colour or gradient the safe card
draws is drawn by a trap in that hand, the safe card's backdrop is a trap's
backdrop too, and every prop or figure (tagged <!--prop:name-->: lineman,
giver, ppe, shelf, docket, plate, ismark...) on the safe card is on a trap in
that hand, and none sits on every trap of the hand but not on the safe card.
The one thing that differs by design (a diary's written date, a tear, a
missing mark) is drawn, not tagged. It deletes only its own stale cards.
"""


import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board76_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board76')
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
KIND_TAG = {'lineman': 'lineman', 'contract': 'giver', 'helper': 'giver', 'super': 'giver',
            'officer': 'giver', 'doctor': 'giver', 'wife': 'giver', 'guard': 'giver'}


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
    elif hk == 'grey':
        hd.append(f'<path d="M{f(hx - 7)} {f(hy - 1)} A7 7 0 0 1 {f(hx + 7)} {f(hy - 1)} Z" fill="#C9CCCF"/>')
        hd.append(f'<path d="M{f(hx - 7 * face)} {f(hy + 1)} Q{f(hx - 7 * face)} {f(hy + 6)} {f(hx - 3 * face)} {f(hy + 7)} L{f(hx - 3 * face)} {f(hy + 1)} Z" fill="#C9CCCF"/>')
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


def lying(x, y, bandage=True):
    """The injured worker in a bed: head on the pillow, the blanket over him,
    a bandaged arm on the blanket. (x, y) = the pillow's left top."""
    o = [tag('lineman'), tag('bandage') if bandage else '']
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="20" height="10" rx="4" fill="{PILLOW}"/>')
    o.append(f'<circle cx="{f(x + 11)}" cy="{f(y + 1)}" r="7" fill="{SKIN}"/>')
    o.append(f'<path d="M{f(x + 4)} {f(y)} A7 7 0 0 1 {f(x + 18)} {f(y)} Z" fill="{HAIR}"/>')
    o.append(f'<rect x="{f(x + 16)}" y="{f(y + 2)}" width="62" height="14" rx="5" fill="{BLANKET}"/>')
    o.append(f'<path d="M{f(x + 22)} {f(y + 3)} L{f(x + 40)} {f(y + 6)}" stroke="url(#shirt)" stroke-width="5" stroke-linecap="round"/>')
    if bandage:
        o.append(f'<circle cx="{f(x + 34)}" cy="{f(y + 5)}" r="3.4" fill="{BANDAGE}" stroke="{INK}" stroke-width="0.5"/>')
        o.append(f'<path d="M{f(x + 4)} {f(y - 3)} L{f(x + 18)} {f(y - 3)}" stroke="{BANDAGE}" stroke-width="2.6"/>')
    o.append(f'<circle cx="{f(x + 42)}" cy="{f(y + 6)}" r="3" fill="{SKIN}"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Glyphs: English digits as seven-segment strokes.
# --------------------------------------------------------------------------

_SEG = {'a': (1, 0, 5, 0), 'b': (6, 1, 6, 4.5), 'c': (6, 5.5, 6, 9), 'd': (1, 10, 5, 10),
        'e': (0, 5.5, 0, 9), 'f': (0, 1, 0, 4.5), 'g': (1, 5, 5, 5)}
_DIG = {'0': 'abcdef', '1': 'bc', '2': 'abged', '3': 'abgcd', '4': 'fgbc', '5': 'afgcd',
        '6': 'afgedc', '7': 'abc', '8': 'abcdefg', '9': 'abcdfg'}


def glyphs(x, y, text, h=10.0, color=INK):
    k = h / 10
    d = []
    ox = x
    for ch in text:
        if ch in _DIG:
            sx = ox - 4 * k if ch == '1' else ox
            for s in _DIG[ch]:
                x0, y0, x1, y1 = _SEG[s]
                d.append(f'M{f(sx + x0 * k)} {f(y + y0 * k)} L{f(sx + x1 * k)} {f(y + y1 * k)}')
            ox += (5.4 if ch == '1' else 7.8) * k
    return f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" fill="none"/>'



# --------------------------------------------------------------------------


FORM_HEAD = '#3C6E91'
INSUL = '#B8653A'       # porcelain pin insulators
LTSPOOL = '#E6E1D3'
AWNING = '#3F7D5A'
WIRE_ = WIRE


def desk(x, y, w=60):
    """A desk seen from the front (the people behind it stand in its shadow)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="5" rx="1" fill="{WOOD}"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 5)}" width="{w - 6}" height="{f(GY - y - 5)}" fill="{WOOD_D}"/>')


def pen_in(x, y, capped=False):
    """A pen in a hand at (x, y); capped, it is held up, away from the paper."""
    if capped:
        return tag('pen') + f'<path d="M{f(x)} {f(y)} l2 -11" stroke="{WIRE}" stroke-width="2.4" stroke-linecap="round"/>'
    return tag('pen') + f'<path d="M{f(x)} {f(y)} l6 6" stroke="{WIRE}" stroke-width="1.8" stroke-linecap="round"/>'


def hv_pole(x, top=14, lt=False):
    """The line pole: an 11 kV cross-arm with pin insulators, or an LT rack
    of shackle spools ([lt])."""
    o = [tag('pole'), f'<rect x="{f(x - 4)}" y="{top}" width="8" height="{GY - top}" fill="url(#pole)"/>']
    if lt:
        o.append(tag('ltrack'))
        o.append(f'<rect x="{f(x + 4)}" y="{top + 8}" width="4" height="46" fill="{INK}"/>')
        for i in range(4):
            yy = top + 12 + i * 11
            o.append(f'<rect x="{f(x + 8)}" y="{f(yy)}" width="6" height="6" rx="2" fill="{LTSPOOL}" stroke="{INK}" stroke-width="0.5"/>')
            o.append(f'<path d="M{f(x + 14)} {f(yy + 3)} L200 {f(yy + 5)}" stroke="{WIRE}" stroke-width="1"/>')
    else:
        o.append(f'<rect x="{f(x - 26)}" y="{top + 10}" width="52" height="5" rx="1" fill="{INK}"/>')
        for dx in (-22, 0, 22):
            o.append(f'<rect x="{f(x + dx - 2.5)}" y="{top + 2}" width="5" height="8" rx="1.5" fill="{INSUL}"/>')
            o.append(f'<path d="M{f(x + dx)} {top + 3} L{200 if dx >= 0 else 0} {top + 5 + abs(dx) / 11}" stroke="{WIRE}" stroke-width="1"/>')
    return ''.join(o)


# --------------------------------------------------------------------------
# Things of a PPE kit: helmet, gloves, shoe, box, plate, shelf, bag, diary...
# --------------------------------------------------------------------------

OUTFITS['barehead'] = dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='bare')
OUTFITS['senior'] = dict(torso='url(#shirt)', sb=SHIRT_D, sf=SHIRT, pants=PANTS, pants_d=PANTS_D, head='grey')
KIND_TAG['barehead'] = 'lineman'
KIND_TAG['senior'] = 'lineman'

GLOVE = '#D9622B'       # rubber gloves, glove-on-hand and harness straps
GLOVE_D = '#B04A1C'
CUFF = '#EDE6D0'
SHOE = '#5A3F2A'
STEEL = '#9AA3AA'
MUD = '#6B4A2E'
STRAP = '#D9622B'


def badge(x, y, r=5.0):
    """The IS mark: a white roundel with a dark rim and a diamond."""
    return (tag('ismark') + f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" fill="{MOVE}" stroke="{INK}" stroke-width="1.1"/>'
            f'<path d="M{f(x - r * 0.55)} {f(y)} L{f(x)} {f(y - r * 0.55)} L{f(x + r * 0.55)} {f(y)} L{f(x)} {f(y + r * 0.55)} Z" fill="{INK}"/>')


def helmet_item(x, y, w=28.0, mark=False, crack=False, shiny=False):
    """A safety helmet standing on its rim; (x, y) = the rim's centre."""
    h = w * 0.46
    o = [tag('ppe'),
         f'<path d="M{f(x - w / 2)} {f(y)} A{f(w / 2)} {f(h)} 0 0 1 {f(x + w / 2)} {f(y)} Z" fill="{HELMET}"/>',
         f'<rect x="{f(x - w / 2 - 2)}" y="{f(y - 1)}" width="{f(w + 4)}" height="3.4" rx="1.6" fill="{HELMET_D}"/>',
         f'<path d="M{f(x)} {f(y - h)} L{f(x)} {f(y)}" stroke="{HELMET_D}" stroke-width="1.2"/>']
    if shiny:
        o.append(f'<path d="M{f(x - w * 0.34)} {f(y - h * 0.3)} Q{f(x - w * 0.26)} {f(y - h * 0.8)} {f(x - w * 0.06)} {f(y - h * 0.92)}" '
                 f'stroke="{MOVE}" stroke-width="2.4" fill="none" stroke-linecap="round" stroke-opacity="0.85"/>')
    if crack:
        o.append(f'<path d="M{f(x + w * 0.12)} {f(y - h)} l{f(-w * 0.08)} {f(h * 0.3)} l{f(w * 0.1)} {f(h * 0.25)} l{f(-w * 0.08)} {f(h * 0.3)}" '
                 f'stroke="{WIRE}" stroke-width="1.3" fill="none" stroke-linejoin="round"/>')
    if mark:
        o.append(badge(x + w * 0.22, y - h * 0.42, w * 0.11))
    return ''.join(o)


def glove_item(x, y, s=1.0, cuff=None, mark=False, tear=False, mud=False):
    """A rubber glove, fingers up; (x, y) = the wrist's centre. [cuff] =
    (code, type): the label on the cuff (stroke digits) and the type digit on
    the palm."""
    o = [tag('ppe'), f'<g transform="translate({f(x)} {f(y)}) scale({s})">']
    o.append(f'<path d="M-8 -7 L-15 -14" stroke="{GLOVE}" stroke-width="4.4" stroke-linecap="round"/>')
    o.append(f'<rect x="-8" y="-15" width="16" height="16" rx="4" fill="{GLOVE}"/>')
    for i, xx in enumerate((-8, -3.7, 0.6, 4.9)):
        top = -28 if i in (1, 2) else -26
        o.append(f'<rect x="{xx}" y="{top}" width="3.2" height="{-1 - top}" rx="1.6" fill="{GLOVE}" stroke="{GLOVE_D}" stroke-width="0.4"/>')
    o.append(f'<rect x="-10" y="0" width="20" height="9" rx="2" fill="{CUFF}" stroke="{INK}" stroke-width="0.6"/>')
    if cuff:
        code, typ = cuff
        o.append(tag('cuff'))
        o.append(glyphs(-8.6, 2.4, code, 4.4))
        o.append(f'<circle cx="0" cy="-7" r="5.2" fill="{CUFF}"/>')
        o.append(glyphs(-2.2, -11.4, typ, 8.6, GLOVE_D))
    if mark:
        o.append(badge(7.4, 4.5, 2.1))
    if tear:
        o.append(f'<path d="M-9 -10 l4 -3 l3 5 l4 -5 l4 4 l4 -4" stroke="{WIRE}" stroke-width="1.5" fill="none" stroke-linejoin="round"/>')
        o.append(f'<path d="M-9 -9 l4 -2.5 l3 4.5 l4 -4.5 l4 3.5 l4 -3.5" stroke="{SKIN}" stroke-width="0.8" fill="none"/>')
    if mud:
        for bx, by, br in ((-4, -9, 3.4), (3, -3, 3), (-1, -20, 2.4), (5, -16, 2.2)):
            o.append(f'<circle cx="{bx}" cy="{by}" r="{br}" fill="{MUD}"/>')
    o.append('</g>')
    return ''.join(o)


def glove_pair(x, y, s=1.0, **kw):
    return glove_item(x - 12 * s, y, s, **kw) + glove_item(x + 12 * s, y, s, **kw)


def hand_glove(x, y):
    """A gloved hand on the pole."""
    return (f'<circle cx="{f(x)}" cy="{f(y)}" r="4.6" fill="{GLOVE}" stroke="{GLOVE_D}" stroke-width="0.5"/>'
            f'<rect x="{f(x - 3.5)}" y="{f(y + 3.2)}" width="7" height="3.4" rx="1" fill="{CUFF}" stroke="{INK}" stroke-width="0.4"/>')


def shoe_item(x, y, s=1.0, mark=False):
    """A safety shoe from the side, toe to the right; (x, y) = the ground
    under it."""
    o = [tag('ppe'), f'<g transform="translate({f(x)} {f(y)}) scale({s})">',
         f'<rect x="-17" y="-4" width="38" height="5" rx="2" fill="{INK}"/>',
         f'<path d="M-15 -4 L-15 -22 Q-6 -24 0 -17 Q8 -11 18 -9 Q22 -8 22 -4 Z" fill="{SHOE}"/>',
         f'<ellipse cx="16" cy="-8" rx="7" ry="5" fill="{STEEL}"/>',
         f'<path d="M-3 -16 l7 5 M-1 -19 l7 5" stroke="{CUFF}" stroke-width="1"/>']
    if mark:
        o.append(badge(-8, -12, 3.2))
    o.append('</g>')
    return ''.join(o)


def box_item(x, y, w=32, h=22, mark=False):
    """A cardboard shoe box with the shoe peeking out; (x, y) = its centre."""
    o = [tag('ppe'), shoe_item(x - 2, y - h / 2 + 3, 0.9),
         f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2 + 4)}" width="{w}" height="{h - 4}" rx="1.5" fill="{ENVELOPE}" stroke="{WOOD_D}" stroke-width="0.7"/>',
         f'<rect x="{f(x - w / 2 - 1.5)}" y="{f(y - h / 2 + 2)}" width="{w + 3}" height="5" rx="1.2" fill="{ENVELOPE}" stroke="{WOOD_D}" stroke-width="0.7"/>']
    if mark:
        o.append(badge(x + w * 0.25, y + 3, 4.4))
    return ''.join(o)


def plate(x, y, code, mark, w=62, h=22):
    """The code plate (the stamp read close up): the IS code in stroke digits,
    and the roundel when the item has the IS mark."""
    o = [tag('plate'),
         f'<rect x="{f(x - w / 2)}" y="{f(y - h / 2)}" width="{w}" height="{h}" rx="3" fill="{PAPER}" stroke="{INK}" stroke-width="0.9"/>',
         glyphs(x - w / 2 + 5, y - 5, code, 10)]
    if mark:
        o.append(badge(x + w / 2 - 9, y, 5.4))
    return ''.join(o)


def shelf(x, y, w, empty=False, shiny=False):
    """A store shelf: two planks, boxes, helmets and gloves (none if empty)."""
    o = [tag('shelf'),
         f'<rect x="{f(x)}" y="{f(y + 22)}" width="{w}" height="4" rx="1" fill="{WOOD_D}"/>',
         f'<rect x="{f(x)}" y="{f(y + 56)}" width="{w}" height="4" rx="1" fill="{WOOD_D}"/>',
         f'<rect x="{f(x + 3)}" y="{f(y + 26)}" width="3" height="30" fill="{WOOD_D}"/>',
         f'<rect x="{f(x + w - 6)}" y="{f(y + 26)}" width="3" height="30" fill="{WOOD_D}"/>']
    if not empty:
        n = max(2, int(w // 46))
        for i in range(n):
            bx = x + 10 + i * (w - 20) / n
            o.append(f'<rect x="{f(bx)}" y="{f(y + 8)}" width="22" height="14" rx="1.5" fill="{ENVELOPE}" stroke="{WOOD_D}" stroke-width="0.6"/>')
            o.append(helmet_item(bx + 11, y + 56, 20, shiny=shiny))
            o.append(glove_item(bx + 12 + (w - 20) / n * 0.5, y + 46, 0.5))
    return ''.join(o)


def register(x, y):
    """The issue register lying on the counter (a signed line)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="32" height="8" rx="1" fill="{CUFF}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 4)} {f(y + 2.5)} h14 M{f(x + 4)} {f(y + 5.5)} h10" stroke="{INK}" stroke-width="0.5"/>'
            f'<path d="M{f(x + 20)} {f(y + 5)} q2 -4 4 0 t4 -1" stroke="{INK}" stroke-width="0.9" fill="none"/>')


def pen_plain(x, y):
    """A pen held in a hand (untagged: every writing scene has one)."""
    return f'<path d="M{f(x)} {f(y)} l6 6" stroke="{INK}" stroke-width="1.8" stroke-linecap="round"/>'


def van(x, y=100, w=84):
    """A site van (side view): green body, a window, two wheels, a mirror."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{GY - y - 12}" rx="6" fill="{DRUM}"/>'
            f'<rect x="{f(x + w * 0.55)}" y="{f(y + 8)}" width="{f(w * 0.38)}" height="24" rx="3" fill="{MOVE}" fill-opacity="0.6"/>'
            f'<rect x="{f(x)}" y="{f(y + 46)}" width="{w}" height="4" fill="{WOOD_D}"/>'
            f'<circle cx="{f(x + 20)}" cy="{GY - 8}" r="11" fill="{BOOT}"/><circle cx="{f(x + w - 20)}" cy="{GY - 8}" r="11" fill="{BOOT}"/>'
            f'<circle cx="{f(x + 20)}" cy="{GY - 8}" r="4.5" fill="{STEEL}"/><circle cx="{f(x + w - 20)}" cy="{GY - 8}" r="4.5" fill="{STEEL}"/>')


def stall(x):
    """A roadside stall: an awning, a counter, helmets and gloves on show."""
    o = [f'<path d="M{x} 86 h{200 - x} v14 h-{200 - x} Z" fill="{AWNING}"/>',
         f'<rect x="{x + 3}" y="100" width="3" height="{GY - 100}" fill="{WOOD_D}"/>',
         f'<rect x="{x}" y="118" width="{200 - x}" height="3" fill="{WOOD_D}"/>']
    for i in range(2):
        o.append(helmet_item(x + 18 + i * 28, 118, 18))
    o.append(glove_item(x + 74, 112, 0.5))
    o.append(shoe_item(x + 88, 150, 0.6))
    o.append(f'<rect x="{x}" y="150" width="{200 - x}" height="{GY - 150}" fill="{WOOD}"/>')
    return ''.join(o)


def kit_bag(x, y, w=44, content='gloves'):
    """An open kit bag on the floor; (x, y) = its top-left."""
    o = [f'<path d="M{f(x + 8)} {f(y)} q{f(w / 2 - 8)} -12 {f(w - 16)} 0" stroke="{WIRE}" stroke-width="2" fill="none"/>']
    if content == 'gloves':
        o.append(glove_item(x + w * 0.35, y + 4, 0.7))
        o.append(helmet_item(x + w * 0.72, y + 2, 14))
    o.append(f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="24" rx="5" fill="{WIRE}"/>'
             f'<rect x="{f(x + 4)}" y="{f(y + 8)}" width="{w - 8}" height="3" rx="1" fill="{INK}"/>')
    return ''.join(o)


def spanner(x, y, ang=0):
    return (f'<g transform="rotate({f(ang)} {f(x)} {f(y)})"><rect x="{f(x - 12)}" y="{f(y - 1.6)}" width="24" height="3.2" rx="1.4" fill="{STEEL}"/>'
            f'<circle cx="{f(x + 12)}" cy="{f(y)}" r="3.4" fill="{STEEL}"/><circle cx="{f(x - 12)}" cy="{f(y)}" r="3.4" fill="{STEEL}"/></g>')


def rag(x, y):
    return (f'<path d="M{f(x)} {f(y)} l10 -3 l3 8 l-10 3 Z" fill="{CUFF}" stroke="{INK}" stroke-width="0.5"/>'
            f'<path d="M{f(x + 3)} {f(y + 1)} l7 -2" stroke="{INK}" stroke-width="0.4"/>')


def docket(x, y):
    """The job docket pinned on a board: the number 11 and an HT cross-arm."""
    o = [tag('docket'),
         f'<rect x="{x}" y="{y}" width="42" height="34" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.8"/>',
         f'<rect x="{x}" y="{y}" width="42" height="6" rx="2" fill="{FORM_HEAD}"/>',
         glyphs(x + 5, y + 12, '11', 13)]
    px = x + 32
    o.append(f'<path d="M{px} {y + 10} v18 M{px - 6} {y + 14} h12" stroke="{INK}" stroke-width="1.4"/>')
    for dx in (-5, 0, 5):
        o.append(f'<circle cx="{px + dx}" cy="{y + 12.5}" r="1.1" fill="{INSUL}"/>')
    return ''.join(o)


def lineman_at(x, hands, face=1, look=0, gy=GY, kind='lineman', **kw):
    return person(x, hands, face=face, look=look, gy=gy, kind=kind, **kw)


def door_view(x, y, w, h):
    """An open door onto the yard with a pole in it."""
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#yard)" stroke="{WOOD_D}" stroke-width="2.4"/>'
            f'<rect x="{x + w * 0.55}" y="{y + 4}" width="5" height="{h - 4}" fill="url(#pole)"/>'
            f'<rect x="{x + w * 0.55 - 9}" y="{y + 12}" width="23" height="3" fill="{INK}"/>')


# --------------------------------------------------------------------------
# Round 1 — source: where the PPE comes from.
# --------------------------------------------------------------------------

def source_card(kind):
    if kind == 'store':
        out = card_open('room')
        out.append(shelf(8, 30, 184))
        out.append(person(64, ((52, 142), (98, 138)), face=1, look=6, gy=184, kind='officer'))
        out.append(desk(16, 148, 126))
        out.append(helmet_item(34, 148, 26, mark=True))
        out.append(glove_pair(70, 139, 0.78))
        out.append(register(106, 140))
        out.append(person(172, ((166, 160), (140, 138)), face=-1, look=8, kind='lineman'))
        out.append(pen_plain(138, 134))
        return card_close(out)
    if kind == 'van':
        out = card_open('yard')
        out.append(van(-14, 96, 92))
        out.append(person(104, ((96, 160), (130, 134)), face=1, look=4, kind='officer'))
        out.append(box_item(140, 128, 30, 22, mark=True))
        out.append(person(176, ((170, 160), (152, 136)), face=-1, look=6, kind='lineman'))
        return card_close(out)
    if kind == 'cash':
        out = card_open('yard')
        out.append(person(160, ((152, 168), (128, 144)), face=-1, look=-4, gy=190, kind='guard'))
        out.append(stall(96))
        out.append(helmet_item(150, 150, 26, mark=True))
        out.append(person(46, ((40, 160), (84, 138)), face=1, look=6, kind='lineman'))
        out.append(f'<rect x="85" y="132" width="14" height="7" rx="1" fill="{GREEN_NOTE}" stroke="{INK}" stroke-width="0.5" transform="rotate(-10 92 135)"/>')
        out.append(f'<circle cx="92" cy="135.5" r="1.6" fill="none" stroke="{INK}" stroke-width="0.5"/>')
        return card_close(out)
    if kind == 'market':
        out = card_open('room')
        out.append(f'<path d="M0 22 h200 v10 h-200 Z" fill="{AWNING}"/>')
        out.append(shelf(8, 34, 184, shiny=True))
        out.append(person(60, ((50, 160), (96, 134)), face=1, look=8, kind='lineman'))
        out.append(helmet_item(104, 134, 30, shiny=True))
        out.append(person(172, ((166, 180), (144, 150)), face=-1, look=-4, gy=188, kind='guard'))
        out.append(desk(122, 152, 78))
        out.append(glove_pair(146, 143, 0.7))
        out.append(shoe_item(184, 152, 0.7))
        return card_close(out)
    out = card_open('room')  # empty
    out.append(shelf(8, 30, 140, empty=True))
    out.append(door_view(152, 62, 40, 96))
    out.append(person(62, ((48, 138), (88, 138)), face=1, look=-4, gy=184, kind='officer'))
    out.append(desk(16, 148, 100))
    out.append(person(150, ((144, 160), (160, 164)), face=1, look=16, kind='lineman'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — glove: the glove for an 11 kV job (IS 4770 type 4).
# --------------------------------------------------------------------------

def glove_card(kind):
    rated = ('4770', '4')
    if kind in ('type4', 'plain', 'torn'):
        out = card_open('yard')
        out.append(docket(10, 22))
        out.append(person(64, ((54, 160), (104, 138)), face=1, look=8, kind='lineman'))
        if kind == 'type4':
            out.append(glove_pair(124, 146, 1.3, cuff=rated, mark=True))
        elif kind == 'plain':
            out.append(glove_pair(124, 146, 1.3))
        else:
            out.append(glove_item(108, 146, 1.3, cuff=rated, mark=True, tear=True))
            out.append(glove_item(140, 146, 1.3, cuff=rated, mark=True))
        out.append(person(164, ((158, 190), (170, 192)), face=-1, look=-6, kind='lineman'))
        return card_close(out)
    out = card_open('room')
    out.append(docket(10, 22))
    out.append(person(54, ((46, 160), (86, 142)), face=1, look=6, kind='lineman'))
    if kind in ('store4', 'type2'):
        out.append(person(166, ((160, 160), (136, 138)), face=-1, look=-6, kind='guard'))
        out.append(glove_pair(118, 146, 1.3, cuff=('4770', '4' if kind == 'store4' else '2'), mark=True))
    else:
        out.append(person(166, ((160, 160), (136, 138)), face=-1, look=-6, kind='guard'))
        out.append(f'<path d="M96 150 l4 -22 h32 l4 22 Z" fill="{ENVELOPE}" stroke="{WOOD_D}" stroke-width="0.8"/>')
        out.append(f'<path d="M104 128 q12 -12 24 0" stroke="{WOOD_D}" stroke-width="1.6" fill="none"/>')
        out.append(glove_pair(118, 136, 1.0))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — mark: the IS code and mark on the item.
# --------------------------------------------------------------------------

def mark_card(kind):
    helmet = kind in ('helmet', 'nomark', 'wrongcode')
    out = card_open('yard' if helmet else 'room')
    out.append(person(62, ((54, 164), (96, 132)), face=1, look=8, kind='lineman'))
    mk = kind not in ('nomark', 'noshoe')
    code = {'helmet': '2925', 'nomark': '2925', 'wrongcode': '15298', 'shoe': '15298', 'noshoe': '15298', 'shoecode': '2925'}[kind]
    if helmet:
        out.append(helmet_item(104, 134, 32))
    else:
        out.append(shoe_item(102, 136, 1.15))
    out.append(f'<path d="M122 116 L140 94" stroke="{INK}" stroke-width="0.9" stroke-dasharray="2 2"/>')
    out.append(plate(146, 78, code, mk))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — duty: the worker's part once the PPE is issued.
# --------------------------------------------------------------------------

def duty_card(kind):
    if kind == 'clean':
        out = card_open('room')
        out.append(person(50, ((42, 162), (92, 142)), face=1, look=8, kind='lineman'))
        out.append(desk(70, 150, 124))
        out.append(rag(88, 144))
        out.append(helmet_item(128, 150, 28))
        out.append(glove_pair(166, 141, 0.7))
        out.append(kit_bag(150, 176, 40))
        return card_close(out)
    if kind == 'crack':
        out = card_open('room')
        out.append(person(56, ((48, 162), (96, 150)), face=1, look=12, kind='lineman'))
        out.append(desk(120, 150, 70))
        out.append(rag(150, 144))
        out.append(helmet_item(98, 154, 26, crack=True))
        out.append(kit_bag(96, 168, 50))
        out.append(person(190, ((184, 166), (196, 168)), face=1, look=14, kind='super'))
        return card_close(out)
    if kind == 'mud':
        out = card_open('room')
        out.append(person(56, ((48, 162), (96, 150)), face=1, look=10, kind='lineman'))
        out.append(desk(150, 150, 50))
        out.append(rag(160, 144))
        out.append(kit_bag(96, 170, 70, content=None))
        out.append(glove_pair(124, 172, 0.9, mud=True))
        out.append(spanner(112, 176, 8))
        out.append(spanner(148, 178, -10))
        out.append(f'<rect x="96" y="170" width="70" height="24" rx="5" fill="{WIRE}"/>')
        return card_close(out)
    out = card_open('yard')
    if kind == 'report':
        out.append(hv_pole(176))
        out.append(person(56, ((48, 162), (100, 130)), face=1, look=8, kind='lineman'))
        out.append(glove_item(106, 134, 1.0, tear=True))
        out.append(person(150, ((144, 162), (120, 138)), face=-1, look=-6, kind='super'))
    elif kind == 'wear':
        out.append(hv_pole(150))
        out.append(person(104, ((124, 120), (138, 98)), face=1, look=-14, kind='lineman'))
        out.append(hand_glove(124, 120))
        out.append(hand_glove(138, 98))
        out.append(tag('ppe'))
    elif kind == 'mirror':
        out.append(van(-10, 100, 80))
        out.append(f'<path d="M72 120 l6 0" stroke="{INK}" stroke-width="2"/>')
        out.append(f'<path d="M80 120 v8" stroke="{INK}" stroke-width="0.9"/>')
        out.append(helmet_item(80, 142, 20))
        out.append(person(112, ((106, 164), (118, 166)), face=-1, look=-6, kind='super'))
        out.append(hv_pole(176))
        out.append(person(152, ((140, 112), (162, 98)), face=-1, look=14, kind='barehead'))
    else:  # senior
        out.append(hv_pole(150))
        out.append(person(96, ((124, 124), (136, 104)), face=1, look=-14, kind='senior'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — size: fit, training and the record.
# --------------------------------------------------------------------------

def glove_closeup(x, y, slack=False):
    """A hand in a glove, fingers up, big. [slack]: the glove two sizes too
    big - empty finger ends flop over."""
    o = []
    s = 1.0
    o.append(f'<g transform="translate({f(x)} {f(y)}) scale(1.5)">')
    for i, xx in enumerate((-8, -3.7, 0.6, 4.9)):
        top = -28 if i in (1, 2) else -26
        o.append(f'<rect x="{xx + 0.4}" y="{top}" width="2.4" height="{-1 - top}" rx="1.2" fill="{SKIN}"/>')
    o.append(f'<rect x="-8" y="-15" width="16" height="16" rx="4" fill="{SKIN}"/>')
    if slack:
        o.append(f'<path d="M-10 -2 L-12 -22 Q-12 -34 -7 -36 L-5 -38 L-1 -40 L3 -38 L8 -36 Q13 -34 12 -22 L10 -2 Z" fill="{GLOVE}" opacity="0.95"/>')
        for xx in (-7, -2, 3, 8):
            o.append(f'<path d="M{xx} -30 q4 5 2 10" stroke="{GLOVE_D}" stroke-width="1" fill="none"/>')
        o.append(f'<path d="M-10 -36 q-6 4 -3 10 M10 -36 q6 4 3 10" stroke="{GLOVE}" stroke-width="3.4" fill="none" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M-9 -1 L-9 -16 Q-8.5 -17 -8.5 -27 Q-6 -29 -4.6 -29 L-4.4 -29 Q-2 -31 0.8 -29 Q3 -30 5.4 -28 Q8 -27 8.2 -26 Q9.6 -17 9.4 -1 Z" '
                 f'fill="{GLOVE}" fill-opacity="0.92" stroke="{GLOVE_D}" stroke-width="0.6"/>')
        o.append(f'<path d="M-8 -7 L-15 -14" stroke="{GLOVE}" stroke-width="4.4" stroke-linecap="round"/>')
    o.append(f'<rect x="-10" y="0" width="20" height="9" rx="2" fill="{CUFF}" stroke="{INK}" stroke-width="0.6"/>')
    o.append('</g>')
    return tag('ppe') + ''.join(o)


def boot_closeup(x, y, fit='snug'):
    """A boot from the side, big, with the foot inside; fit = snug, tight
    (toes poking out the front) ."""
    o = [tag('ppe'), f'<g transform="translate({f(x)} {f(y)}) scale(1.7)">']
    o.append(f'<rect x="-17" y="-4" width="40" height="5" rx="2" fill="{INK}"/>')
    foot_end = 21 if fit == 'snug' else 27
    o.append(f'<path d="M-8 -26 L-8 -5 L{foot_end} -5 Q{foot_end + 1} -9 {foot_end - 4} -11 Q8 -13 4 -20 L4 -26 Z" fill="{SKIN}"/>')
    o.append(f'<path d="M-15 -4 L-15 -24 L-8 -26 L-8 -12 Q8 -12 18 -9 Q22 -8 22 -4 Z" fill="{SHOE}" fill-opacity="0.94"/>')
    if fit == 'tight':
        o.append(f'<path d="M20 -5 q6 -1 7 -5 M22 -9 q4 -3 4 -6" stroke="{SKIN_D}" stroke-width="1" fill="none"/>')
        o.append(f'<path d="M17 -4 L23 -4 L22 -12 L17 -10 Z" fill="{SHOE}"/>')
    else:
        o.append(f'<ellipse cx="16" cy="-8" rx="7" ry="5" fill="{STEEL}"/>')
    o.append('</g>')
    return ''.join(o)


def harness_item(x, y, s=1.0):
    """A full-body harness held up by its back ring; (x, y) = the ring."""
    o = [tag('ppe'), f'<g transform="translate({f(x)} {f(y)}) scale({s})">',
         f'<path d="M0 0 L-10 22 L-8 44 M0 0 L10 22 L8 44 M-10 22 L10 22" stroke="{STRAP}" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
         f'<path d="M-8 44 L-14 56 M8 44 L14 56 M-8 44 L8 44" stroke="{STRAP}" stroke-width="3" fill="none" stroke-linecap="round"/>',
         f'<circle cx="0" cy="0" r="3" fill="none" stroke="{INK}" stroke-width="1.5"/>',
         f'<rect x="-4" y="19" width="8" height="6" rx="1" fill="{INK}"/>',
         '</g>']
    return ''.join(o)


def diary_open(x, y, written=True):
    """A diary page, big: the report line. [written]: the date (14 / 11) and
    the name's signature on it; otherwise only the scribbled line."""
    o = [f'<rect x="{f(x - 30)}" y="{f(y - 22)}" width="60" height="44" rx="2.4" fill="{CUFF}" stroke="{INK}" stroke-width="0.9"/>',
         f'<path d="M{f(x)} {f(y - 22)} v44" stroke="{INK}" stroke-width="0.6"/>',
         f'<path d="M{f(x - 26)} {f(y - 4)} h22 M{f(x - 26)} {f(y + 4)} h18 M{f(x - 26)} {f(y + 12)} h20" stroke="{INK}" stroke-width="0.8"/>']
    if written:
        o.append(glyphs(x + 5, y - 18, '14', 7))
        o.append(f'<path d="M{f(x + 20)} {f(y - 16)} l-3 8" stroke="{INK}" stroke-width="1"/>')
        o.append(glyphs(x + 22, y - 18, '11', 7))
        o.append(f'<path d="M{f(x + 6)} {f(y + 10)} q3 -7 6 0 t6 0 t6 -1" stroke="{INK}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')
    return ''.join(o)


def size_card(kind):
    if kind in ('fit', 'big', 'tight'):
        out = card_open('yard' if kind == 'tight' else 'room')
        out.append(person(40, ((32, 164), (72, 130)), face=1, look=8, kind='lineman'))
        out.append(glove_closeup(122, 100, slack=kind == 'big'))
        out.append(boot_closeup(122, 168, fit='tight' if kind == 'tight' else 'snug'))
        return card_close(out)
    if kind == 'train':
        out = card_open('yard')
        out.append(person(112, ((104, 164), (96, 110)), face=-1, look=-4, kind='super'))
        out.append(harness_item(96, 112, 1.2))
        out.append(person(36, ((30, 166), (50, 160)), face=1, look=6, kind='lineman'))
        out.append(person(166, ((160, 166), (172, 160)), face=-1, look=-6, kind='lineman'))
        return card_close(out)
    if kind == 'newbox':
        out = card_open('yard')
        out.append(hv_pole(160))
        out.append(ladder(120, GY - 2, 154, 50))
        out.append(climber(138, 146, face=1))
        out.append(harness_item(124, 100, 0.9))
        out.append(box_item(70, 182, 40, 22))
        out.append(person(26, ((20, 166), (6, 130)), face=1, look=-8, kind='super', phone=True))
        return card_close(out)
    out = card_open('room')  # diary / blank
    out.append(person(46, ((38, 164), (72, 146)), face=1, look=8, kind='lineman'))
    out.append(person(166, ((160, 164), (170, 166)), face=-1, look=-6, kind='super'))
    out.append(desk(88, 160, 40))
    out.append(helmet_item(100, 160, 20))
    out.append(diary_open(104, 84, written=kind == 'diary'))
    out.append(pen_plain(70, 146))
    return card_close(out)


def climber(x, gy, face=-1, wave=False):
    """A lineman up the pole (feet on the step bolts), hands on the pole."""
    hands = ((x + 10 * face, gy - 60), (x + 6 * face, gy - 70))
    return person(x, hands, face=face, look=-20, gy=gy, s=1.0)


def ladder(x0, y0, x1, y1):
    o = [tag('ladder')]
    dx, dy = x1 - x0, y1 - y0
    n = math.hypot(dx, dy)
    px, py = -dy / n * 5, dx / n * 5
    for s in (-1, 1):
        o.append(f'<path d="M{f(x0 + px * s)} {f(y0 + py * s)} L{f(x1 + px * s)} {f(y1 + py * s)}" stroke="{WOOD_D}" stroke-width="2.2"/>')
    steps = int(n // 12)
    for i in range(1, steps + 1):
        t = i / (steps + 1)
        cx, cy = x0 + dx * t, y0 + dy * t
        o.append(f'<path d="M{f(cx - px)} {f(cy - py)} L{f(cx + px)} {f(cy + py)}" stroke="{WOOD}" stroke-width="1.6"/>')
    return ''.join(o)


CARDS = {}
for k in ('store', 'van', 'cash', 'market', 'empty'):
    CARDS[f'source_{k}'] = source_card(k)
for k in ('type4', 'store4', 'plain', 'type2', 'torn', 'shop'):
    CARDS[f'glove_{k}'] = glove_card(k)
for k in ('helmet', 'shoe', 'nomark', 'wrongcode', 'noshoe', 'shoecode'):
    CARDS[f'mark_{k}'] = mark_card(k)
for k in ('clean', 'report', 'wear', 'mirror', 'crack', 'mud', 'senior'):
    CARDS[f'duty_{k}'] = duty_card(k)
for k in ('fit', 'train', 'diary', 'big', 'tight', 'newbox', 'blank'):
    CARDS[f'size_{k}'] = size_card(k)

# Safe cards and traps per round (mirrors learn_board_pack76.dart).
ROUNDS = {
    'source': (['source_store', 'source_van'], ['source_cash', 'source_market', 'source_empty']),
    'glove': (['glove_type4', 'glove_store4'], ['glove_plain', 'glove_type2', 'glove_torn', 'glove_shop']),
    'mark': (['mark_helmet', 'mark_shoe'], ['mark_nomark', 'mark_wrongcode', 'mark_noshoe', 'mark_shoecode']),
    'duty': (['duty_clean', 'duty_report', 'duty_wear'], ['duty_mirror', 'duty_crack', 'duty_mud', 'duty_senior']),
    'size': (['size_fit', 'size_train', 'size_diary'], ['size_big', 'size_tight', 'size_newbox', 'size_blank']),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    for k, p in props.items():
        if not p & {'lineman', 'giver'}:
            problems.append(f'{k}: no worker on the card')
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
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
