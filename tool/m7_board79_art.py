"""Picture cards for lesson 7.9 শেখা ("গ্রাহকের অধিকার এবং লাইনম্যানের দায়িত্ব").

python -I tool/m7_board79_art.py .

Writes assets/game/art/m7_board79/*.svg in the clean gradient style of
tool/m7_board74_art.py (200 x 220 scene cards, drawn edge to edge). No words in
the art; the marks a worker reads (the meter's digits) are stroke glyphs with
English digits. Every card of a round draws the same set of props and figures
(one backdrop per round), so only the state of the scene tells the act.

What the cards show comes from lesson 7.9 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md) only. Five rounds (ruling X6:
the item spec's six rounds are trimmed to five; its ID round and its
explain-the-work round are one round, at the door):
  1. arrive: at the customer's door. Safe: the company ID held up before she
     speaks; the ID shown and the job told in plain words. Traps: walking in
     with the ID in the pocket; the card dug out only when asked; pointing at
     the uniform; opening the meter cover in silence; laughing the question off;
  2. entry: going in to test the meter. Safe: the notice was given and she
     waves him in; the notice handed across a closed gate. Traps: over the wall
     of a padlocked house; pushing in past a raised palm; already in the
     courtyard with no notice;
  3. zone: inside, where he may work. Safe: at the meter box; following the
     wiring route. Traps: pushing aside a bedroom curtain; opening the
     almirah; peering into a family room;
  4. talk: an angry customer wants the transformer changed. Safe: listening
     calmly; telling the office. Traps: arguing; a handshake and a promise;
     turning his back;
  5. finish: the meter is changed. Safe: sweeping the offcuts away; the
     customer signing the job sheet. Traps: walking out over scattered
     offcuts; a ladder on her crushed flower pot; leaving with the old meter
     and no signed sheet.

Fairness (the playbook, section 4): every hand the dealer can make (one safe
card + any three traps) is checked: each colour or gradient the safe card
draws is drawn by a trap in that hand, the safe card's backdrop is a trap's
backdrop too, and every prop or figure (tagged <!--prop:name-->) on the safe
card is on a trap in that hand, and none sits on every trap of the hand but
not on the safe card. It deletes only its own stale cards.
"""


import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board79_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board79')
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
    (here and in test/learn_board_79_test.dart) reads these: no prop may sit
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
# Lesson 7.9's own things: the customer, the house, the ID card, the notice.
# --------------------------------------------------------------------------

OUTFITS['cust'] = dict(torso='#C9B68A', sb='#A8946A', sf='#C9B68A', pants='#D9D2BF', pants_d='#BDB6A2', head='bare')
KIND_TAG['cust'] = 'customer'

ID_BLUE = '#2F6FB0'
ROOF = '#8A5A44'
DOORC = '#4F7C6A'
WALLC = '#C9BFA6'
WALLC_D = '#A89F88'
METER_BOX = '#6F7B86'
CURT = '#8A5FA8'
CURT_D = '#6C4688'
DARK_IN = '#2B2A33'
ALM = '#8C97A3'
ALM_D = '#6C7783'
POT = '#C0693A'
POT_D = '#9A4F28'
LEAF = '#4E8A4A'
SOIL = '#5A4030'
BROOM = '#C9A23A'
SCRATCH = '#F3F1EA'
TANK = '#8B96A0'
TANK_D = '#6A747D'
GATE_BAR = '#3F4A55'
CLIP = '#9A7B4A'
RAGE = '#D8402F'
SIGN = '#2346A0'
PANEL = '#7D8A94'
LOCK = '#C9A23A'
HAZARD = '#F2C230'
INSUL = '#B8653A'


def squiggle(x, y, w):
    """A hand signature across a sign box."""
    return (f'<path d="M{f(x)} {f(y)} q{f(w * 0.15)} -5 {f(w * 0.3)} 0 t{f(w * 0.3)} 0 t{f(w * 0.3)} -1" '
            f'stroke="{SIGN}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')


def qmark(cx, cy, s=1.0):
    return (f'<path d="M{f(cx - 3 * s)} {f(cy - 3 * s)} a3 3 0 1 1 4 3 q-1 0.6 -1 2.4" stroke="{INK}" stroke-width="{f(1.6 * s)}" fill="none" stroke-linecap="round"/>'
            f'<circle cx="{f(cx)}" cy="{f(cy + 6 * s)}" r="{f(0.9 * s)}" fill="{INK}"/>')


def pen_in(x, y):
    return tag('pen') + f'<path d="M{f(x)} {f(y)} l6 6" stroke="{WIRE}" stroke-width="1.8" stroke-linecap="round"/>'


def hv_pole(x, top=14):
    """The line pole: an 11 kV cross-arm with pin insulators."""
    o = [tag('pole'), f'<rect x="{f(x - 4)}" y="{top}" width="8" height="{GY - top}" fill="url(#pole)"/>',
         f'<rect x="{f(x - 26)}" y="{top + 10}" width="52" height="5" rx="1" fill="{INK}"/>']
    for dx in (-22, 0, 22):
        o.append(f'<rect x="{f(x + dx - 2.5)}" y="{top + 2}" width="5" height="8" rx="1.5" fill="{INSUL}"/>')
        o.append(f'<path d="M{f(x + dx)} {top + 3} L{200 if dx >= 0 else 0} {top + 5 + abs(dx) / 11}" stroke="{WIRE}" stroke-width="1"/>')
    return ''.join(o)


def ladder(x0, y0, x1, y1):
    """A ladder from the foot (x0, y0) to the top (x1, y1)."""
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


def idcard(x, y, s=1.0):
    """The company ID card, top left at (x, y): blue head strip, photo, lines."""
    w, h = 14 * s, 9 * s
    return (tag('idcard') + f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(1 * s)}" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(2.4 * s)}" rx="{f(1 * s)}" fill="{ID_BLUE}"/>'
            f'<circle cx="{f(x + 3.6 * s)}" cy="{f(y + 5.6 * s)}" r="{f(1.8 * s)}" fill="{SKIN}"/>'
            f'<path d="M{f(x + 7 * s)} {f(y + 4.6 * s)} h{f(5 * s)} M{f(x + 7 * s)} {f(y + 6.6 * s)} h{f(4 * s)}" stroke="{INK}" stroke-width="{f(0.6 * s)}"/>')


def pocket_id(x, face=1):
    """The ID card left in the shirt pocket: only its blue head shows."""
    return (tag('idcard') + f'<rect x="{f(x + 2 * face - 3)}" y="127" width="8" height="4" rx="1" fill="{ID_BLUE}"/>'
            f'<rect x="{f(x + 2 * face - 3)}" y="130" width="8" height="3" fill="{PAPER}" stroke="{INK}" stroke-width="0.3"/>')


def paper_in(x, y, ang=-10):
    """A paper in a hand at (x, y): the notice, the docket."""
    return (tag('paper') + f'<g transform="rotate({f(ang)} {f(x)} {f(y)})">'
            f'<rect x="{f(x - 6)}" y="{f(y - 8)}" width="12" height="15" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            f'<path d="M{f(x - 4)} {f(y - 4.5)} h8 M{f(x - 4)} {f(y - 1.5)} h8 M{f(x - 4)} {f(y + 1.5)} h5" stroke="{INK}" stroke-width="0.5"/></g>')


def bubble79(x, y, kind='ask'):
    """A speech bubble: ask (?), dots (listening), talk (lines), excl (!), or a
    red burst for rage."""
    o = [tag('bubble')]
    if kind == 'rage':
        pts = []
        for i in range(16):
            ang = i * math.pi / 8
            r = 17 if i % 2 == 0 else 10
            pts.append(f'{f(x + r * math.cos(ang))},{f(y + r * 0.78 * math.sin(ang))}')
        o.append(f'<polygon points="{" ".join(pts)}" fill="{RAGE}" stroke="{INK}" stroke-width="0.6" stroke-linejoin="round"/>')
        o.append(f'<path d="M{f(x - 5)} {f(y - 4)} l3 8 M{f(x)} {f(y - 5)} l0 9 M{f(x + 5)} {f(y - 4)} l-3 8" stroke="{MOVE}" stroke-width="1.6" stroke-linecap="round"/>')
        return ''.join(o)
    o.append(f'<path d="M{f(x - 14)} {f(y - 10)} h28 a3 3 0 0 1 3 3 v14 a3 3 0 0 1 -3 3 h-14 l-6 7 l0 -7 h-8 a3 3 0 0 1 -3 -3 v-14 a3 3 0 0 1 3 -3 Z" '
             f'fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
    if kind == 'ask':
        o.append(qmark(x, y - 2))
    elif kind == 'dots':
        for dx in (-7, 0, 7):
            o.append(f'<circle cx="{f(x + dx)}" cy="{f(y)}" r="1.9" fill="{INK}"/>')
    elif kind == 'excl':
        o.append(f'<path d="M{f(x - 5)} {f(y - 6)} l0 8 M{f(x + 5)} {f(y - 6)} l0 8" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
                 f'<circle cx="{f(x - 5)}" cy="{f(y + 5)}" r="1.2" fill="{INK}"/><circle cx="{f(x + 5)}" cy="{f(y + 5)}" r="1.2" fill="{INK}"/>')
    else:  # talk
        o.append(f'<path d="M{f(x - 9)} {f(y - 4)} h18 M{f(x - 9)} {f(y)} h18 M{f(x - 9)} {f(y + 4)} h11" stroke="{INK}" stroke-width="1.3" stroke-linecap="round"/>')
    return ''.join(o)


def house_front(x0, door_x=None):
    """A house front from x0 to the card's right edge: roof band, wall, a door."""
    dx = door_x if door_x is not None else x0 + 32
    return (tag('house') + f'<rect x="{x0 - 4}" y="50" width="{204 - x0}" height="10" fill="{ROOF}"/>'
            f'<rect x="{x0}" y="60" width="{200 - x0}" height="{GY - 60}" fill="url(#house)"/>'
            f'<rect x="{dx}" y="108" width="34" height="{GY - 108}" rx="2" fill="{DOORC}"/>'
            f'<circle cx="{dx + 28}" cy="{(108 + GY) // 2 + 6}" r="1.8" fill="{HAZARD}"/>')


def meter_box(x, y, reading='0482'):
    """The energy meter in its box on the wall, digits in stroke glyphs."""
    return (tag('meter') + f'<rect x="{x}" y="{y}" width="24" height="30" rx="2" fill="{METER_BOX}"/>'
            f'<rect x="{x + 3}" y="{y + 4}" width="18" height="9" fill="url(#lcd)"/>'
            + glyphs(x + 4, y + 5.4, reading, 6) +
            f'<circle cx="{x + 12}" cy="{y + 22}" r="4" fill="{WHITE_HAT}" stroke="{INK}" stroke-width="0.6"/>')


def pocket_phone(x, face=1):
    return (tag('phone') + f'<rect x="{f(x + 4 * face - 2)}" y="150" width="5" height="9" rx="1" fill="{WIRE}"/>'
            f'<rect x="{f(x + 4 * face - 1)}" y="151" width="3" height="5" fill="url(#lcd)"/>')


def broom(x0, y0, x1, y1):
    """A broom from the head (x0, y0) up to the handle top (x1, y1)."""
    return (tag('broom') + f'<path d="M{f(x0)} {f(y0)} L{f(x1)} {f(y1)}" stroke="{WOOD_D}" stroke-width="2" stroke-linecap="round"/>'
            f'<path d="M{f(x0 - 6)} {f(y0 + 1)} L{f(x0 + 6)} {f(y0 + 1)} L{f(x0 + 4)} {f(y0 - 6)} L{f(x0 - 4)} {f(y0 - 6)} Z" fill="{BROOM}"/>')


def offcuts(points):
    """Little cut pieces of wire at the given spots."""
    return tag('offcuts') + ''.join(
        f'<path d="M{f(px - 4)} {f(py)} q2 -4 4 0 t4 -1" stroke="{WIRE}" stroke-width="1.3" fill="none" stroke-linecap="round"/>' for px, py in points)


def clipboard(x, y, signed, w=18, h=24, ang=0):
    o = [tag('sheet'), f'<g transform="rotate({f(ang)} {f(x + w / 2)} {f(y + h / 2)})">',
         f'<rect x="{f(x - 1)}" y="{f(y - 1)}" width="{w + 2}" height="{h + 2}" rx="1.5" fill="{CLIP}"/>',
         f'<rect x="{f(x + 1)}" y="{f(y + 2)}" width="{w - 2}" height="{h - 4}" fill="{PAPER}"/>',
         f'<path d="M{f(x + 3)} {f(y + 6)} h{w - 6} M{f(x + 3)} {f(y + 10)} h{w - 6} M{f(x + 3)} {f(y + 14)} h{w - 10}" stroke="{INK}" stroke-width="0.6"/>',
         f'<path d="M{f(x + 3)} {f(y + h - 5)} h{w - 6}" stroke="{INK}" stroke-width="0.7"/>']
    if signed:
        o.append(squiggle(x + 4, y + h - 6, w - 8))
    o.append('</g>')
    return ''.join(o)


def pot_plant(x, crushed=False):
    """A flower pot standing at x, or crushed flat with soil and shards."""
    if not crushed:
        return (tag('pot') + f'<path d="M{x - 8} {GY - 15} h16 l-3 15 h-10 Z" fill="{POT}"/>'
                f'<rect x="{x - 9}" y="{GY - 18}" width="18" height="4" rx="1" fill="{POT_D}"/>'
                f'<path d="M{x} {GY - 18} q-9 -10 -12 -4 M{x} {GY - 18} q9 -12 12 -5 M{x} {GY - 18} q0 -12 0 -14" stroke="{LEAF}" stroke-width="2" fill="none" stroke-linecap="round"/>')
    return (tag('pot') + f'<ellipse cx="{x}" cy="{GY - 2}" rx="15" ry="3.5" fill="{SOIL}"/>'
            f'<path d="M{x - 13} {GY - 3} l5 -6 l4 6 Z M{x + 3} {GY - 3} l6 -8 l4 8 Z" fill="{POT}"/>'
            f'<path d="M{x - 3} {GY - 3} l3 -3 l3 3 Z" fill="{POT_D}"/>'
            f'<path d="M{x - 2} {GY - 5} q-6 -4 -9 0 M{x + 4} {GY - 5} q6 -6 9 -1" stroke="{LEAF}" stroke-width="1.6" fill="none"/>')


def pocket_pen(x, face=1):
    return tag('pen') + f'<path d="M{f(x + 6 * face)} 134 v7" stroke="{WIRE}" stroke-width="1.4" stroke-linecap="round"/>'


def old_meter(x, y):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="14" height="18" rx="2" fill="{METER_BOX}"/>'
            f'<rect x="{f(x + 2)}" y="{f(y + 3)}" width="10" height="6" fill="url(#lcd)"/>'
            f'<circle cx="{f(x + 7)}" cy="{f(y + 13)}" r="2.6" fill="{WHITE_HAT}"/>')


# --------------------------------------------------------------------------
# Round 1 — arrive: at the customer's door.
# --------------------------------------------------------------------------

def arrive_card(kind):
    out = card_open('yard')
    out.append(house_front(118))
    out.append(meter_box(122, 106))
    lx, look = 66, 0
    lh = ((60, 158), (84, 158))
    ch = ((172, 158), (160, 158))
    bub = None
    if kind == 'id':
        lh, look = ((60, 158), (96, 122)), 4
        bub = (140, 48, 'dots')
    elif kind == 'say':
        lh, look = ((80, 128), (112, 110)), 6
        bub = (72, 46, 'talk')
    elif kind == 'walk':
        lx, lh = 98, ((92, 158), (112, 160))
        ch, bub = ((172, 158), (158, 152)), (140, 48, 'ask')
    elif kind == 'demand':
        lh, look = ((60, 158), (78, 132)), 6
        ch, bub = ((172, 158), (136, 126)), (140, 48, 'ask')
    elif kind == 'uniform':
        lh = ((48, 140), (86, 140))
        ch, bub = ((172, 158), (138, 128)), (140, 48, 'ask')
    elif kind == 'silent':
        lx, lh, look = 104, ((96, 152), (126, 118)), 8
        ch, bub = ((172, 158), (160, 128)), (140, 48, 'ask')
    else:  # laugh
        lh, look = ((46, 138), (88, 138)), -14
        bub = (72, 46, 'excl')
    out.append(person(167, ch, face=-1, look=0, kind='wife'))
    out.append(person(lx, lh, face=1, look=look, kind='lineman'))
    if kind == 'id':
        out.append(idcard(86, 108, 2.0))
        out.append(paper_in(54, 150, 8))
    elif kind == 'say':
        out.append(idcard(73, 118, 1.0))
        out.append(paper_in(54, 150, 8))
    else:
        out.append(pocket_id(lx))
        out.append(paper_in(lx - 12, 150, 8))
    out.append(bubble79(*bub))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — entry: going in to test the meter.
# --------------------------------------------------------------------------

def entry_card(kind):
    out = card_open('yard')
    out.append(tag('house') + f'<rect x="146" y="52" width="58" height="8" fill="{ROOF}"/>'
               f'<rect x="150" y="60" width="50" height="92" fill="url(#house)"/>'
               f'<rect x="168" y="100" width="22" height="52" rx="2" fill="{DOORC}"/>')
    if kind == 'unannounced':
        out.append(person(156, ((148, 160), (170, 120)), face=1, look=-6, gy=164, s=1.15, kind='lineman'))
    ch, cface, bub = ((126, 162), (110, 140)), -1, (112, 52, 'dots')
    if kind == 'invited':
        ch, bub = ((126, 160), (102, 126)), (112, 52, 'talk')
    elif kind == 'slip':
        ch, bub = ((126, 162), (104, 140)), (112, 52, 'dots')
    elif kind == 'climb':
        ch, cface, bub = ((112, 150), (128, 150)), 1, (108, 52, 'excl')
    elif kind == 'push':
        ch, bub = ((126, 160), (100, 132)), (112, 52, 'excl')
    else:
        ch, cface, bub = ((122, 128), (132, 126)), 1, (112, 52, 'ask')
    out.append(person(120, ch, face=cface, look=0, gy=192, s=1.2, kind='wife'))
    # the compound wall, gate posts, the leaf
    out.append(f'<rect x="84" y="148" width="20" height="{GY - 148}" fill="{WALLC}"/>'
               f'<rect x="136" y="148" width="64" height="{GY - 148}" fill="{WALLC}"/>'
               f'<rect x="84" y="146" width="20" height="4" fill="{WALLC_D}"/><rect x="136" y="146" width="64" height="4" fill="{WALLC_D}"/>'
               f'<rect x="100" y="112" width="8" height="{GY - 112}" fill="{WALLC_D}"/>'
               f'<rect x="132" y="112" width="8" height="{GY - 112}" fill="{WALLC_D}"/>')
    out.append(tag('wall') + tag('gate'))
    bars = ''.join(f'<path d="M{108 + i * 5} 126 V{GY}" stroke="{GATE_BAR}" stroke-width="1.6"/>' for i in range(6))
    closed = f'<rect x="108" y="124" width="24" height="{GY - 124}" fill="none" stroke="{GATE_BAR}" stroke-width="2.4"/>' + bars
    lock_shut = (f'<path d="M116 158 a3 3 0 0 1 6 0" stroke="{INK}" stroke-width="1.3" fill="none"/>'
                 f'<rect x="114.5" y="158" width="9" height="7" rx="1" fill="{LOCK}"/>')
    lock_open = (f'<path d="M138 150 a3 3 0 0 1 6 0 l0 4" stroke="{INK}" stroke-width="1.3" fill="none"/>'
                 f'<rect x="136.5" y="154" width="9" height="7" rx="1" fill="{LOCK}"/>')
    side_leaf = (f'<rect x="140" y="126" width="6" height="{GY - 126}" fill="none" stroke="{GATE_BAR}" stroke-width="2"/>'
                 f'<path d="M142 130 V{GY - 4} M144 130 V{GY - 4}" stroke="{GATE_BAR}" stroke-width="1.2"/>')
    swung = (f'<polygon points="132,124 112,134 112,{GY - 2} 132,{GY}" fill="none" stroke="{GATE_BAR}" stroke-width="2.4" stroke-linejoin="round"/>'
             f'<path d="M123 130 V{GY - 2} M118 132 V{GY - 2}" stroke="{GATE_BAR}" stroke-width="1.4"/>')
    if kind in ('slip', 'climb'):
        out.append(closed + lock_shut)
    elif kind == 'push':
        out.append(swung + lock_open)
    else:
        out.append(side_leaf + lock_open)
    lm = {
        'invited': (54, ((48, 158), (70, 150)), 1, 2, 198, 1.3),
        'slip': (58, ((52, 158), (104, 140)), 1, 4, 198, 1.3),
        'climb': (168, ((160, 130), (150, 122)), -1, -6, 150, 1.1),
        'push': (84, ((78, 158), (112, 136)), 1, 8, 198, 1.3),
        'unannounced': None,
    }[kind]
    paper = {'invited': (72, 148), 'slip': (106, 138), 'climb': (178, 138), 'push': (74, 156), 'unannounced': (166, 126)}[kind]
    if lm:
        x, hands, fc, lk, gy, sc = lm
        out.append(person(x, hands, face=fc, look=lk, gy=gy, s=sc, kind='lineman'))
    out.append(paper_in(*paper, 8))
    out.append(bubble79(*bub))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — zone: inside, where he may work.
# --------------------------------------------------------------------------

def zone_card(kind):
    out = card_open('room')
    # the wall fittings, left to right: meter box, conduit, window, almirah, curtain
    out.append(meter_box(10, 76, '0482'))
    out.append(tag('conduit') + f'<path d="M34 98 H60 V168" stroke="{INK}" stroke-width="3.4" fill="none" stroke-linejoin="round"/>'
               f'<path d="M34 98 H60 V168" stroke="{PANEL}" stroke-width="1.6" fill="none" stroke-linejoin="round"/>')
    out.append(tag('window') + f'<rect x="78" y="78" width="36" height="48" fill="url(#glass)" stroke="{WOOD_D}" stroke-width="2.4"/>'
               f'<path d="M96 78 V126 M78 102 H114" stroke="{WOOD_D}" stroke-width="1.4"/>')
    out.append(tag('almirah') + f'<rect x="126" y="72" width="30" height="{GY - 72}" rx="2" fill="{ALM}"/>')
    if kind == 'almirah':
        out.append(f'<rect x="129" y="76" width="24" height="{GY - 80}" fill="{DARK_IN}"/>'
                   f'<rect x="131" y="96" width="20" height="5" fill="{CURT}"/><rect x="131" y="116" width="20" height="5" fill="{PAPER}"/>'
                   f'<rect x="131" y="138" width="20" height="5" fill="{HELPER}"/>'
                   f'<polygon points="126,72 116,78 116,{GY - 8} 126,{GY - 2}" fill="{ALM_D}"/>')
    else:
        out.append(f'<path d="M141 76 V{GY - 6}" stroke="{ALM_D}" stroke-width="1.6"/>'
                   f'<rect x="136" y="124" width="3" height="10" rx="1" fill="{ALM_D}"/><rect x="143" y="124" width="3" height="10" rx="1" fill="{ALM_D}"/>')
    out.append(tag('curtain') + f'<rect x="166" y="54" width="34" height="{GY - 54}" fill="{WOOD_D}"/>'
               f'<rect x="170" y="58" width="30" height="{GY - 58}" fill="{DARK_IN}"/>')
    if kind == 'bedroom':
        out.append(f'<path d="M170 58 h10 q-4 60 0 {GY - 62} h-10 Z" fill="{CURT}"/>'
                   f'<path d="M174 60 V{GY - 6} M178 60 V{GY - 6}" stroke="{CURT_D}" stroke-width="1.2"/>'
                   f'<path d="M180 120 q10 6 16 -2 v22 q-8 4 -16 0 Z" fill="{BLANKET}"/>')
    else:
        out.append(f'<rect x="170" y="58" width="30" height="{GY - 58}" fill="{CURT}"/>'
                   f'<path d="M176 60 V{GY - 4} M183 60 V{GY - 4} M190 60 V{GY - 4} M197 60 V{GY - 4}" stroke="{CURT_D}" stroke-width="1.4"/>')
    lx, lh, lface, look = {
        'meter': (52, ((54, 150), (36, 104)), -1, 2),
        'route': (80, ((84, 150), (62, 126)), -1, -6),
        'bedroom': (152, ((146, 150), (172, 104)), 1, 4),
        'almirah': (110, ((104, 150), (128, 118)), 1, 4),
        'peek': (100, ((104, 150), (96, 126)), -1, -18),
    }[kind]
    cx, cface = {'meter': (96, -1), 'route': (112, -1), 'bedroom': (112, 1), 'almirah': (82, 1), 'peek': (140, -1)}[kind]
    out.append(person(cx, ((cx - 6, 158), (cx + 8 * cface, 156)), face=cface, look=0, kind='wife'))
    out.append(person(lx, lh, face=lface, look=look, kind='lineman'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — talk: an angry customer wants the transformer changed.
# --------------------------------------------------------------------------

def transformer(x):
    return (hv_pole(x, top=20) + tag('transformer') +
            f'<rect x="{x - 15}" y="66" width="30" height="38" rx="3" fill="{TANK}" stroke="{TANK_D}" stroke-width="1.4"/>'
            f'<path d="M{x - 11} 74 H{x + 11} M{x - 11} 82 H{x + 11} M{x - 11} 90 H{x + 11}" stroke="{TANK_D}" stroke-width="1.2"/>'
            f'<rect x="{x - 3}" y="104" width="6" height="12" fill="{TANK_D}"/>')


def talk_card(kind):
    out = card_open('yard')
    out.append(transformer(172))
    out.append(person(128, ((136, 150), (110, 124)), face=-1, look=0, kind='cust'))
    out.append(bubble79(124, 42, 'rage'))
    if kind == 'listen':
        out.append(person(70, ((56, 142), (88, 142)), face=1, look=6, kind='lineman'))
        out.append(pocket_phone(70))
    elif kind == 'report':
        out.append(person(70, ((62, 158), (0, 0)), face=1, look=4, kind='lineman', phone=True))
    elif kind == 'argue':
        out.append(person(84, ((76, 158), (108, 124)), face=1, look=-6, kind='lineman'))
        out.append(pocket_phone(84))
    elif kind == 'promise':
        out.append(person(80, ((94, 104), (112, 130)), face=1, look=0, kind='lineman'))
        out.append(pocket_phone(80))
    else:  # wave
        out.append(person(68, ((52, 152), (38, 128)), face=-1, look=10, kind='lineman'))
        out.append(pocket_phone(68, -1))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — finish: the meter is changed.
# --------------------------------------------------------------------------

def finish_card(kind):
    out = card_open('yard')
    out.append(house_front(112, door_x=300))
    out.append(meter_box(130, 88, '0000'))
    crushed = kind == 'pot'
    foot = 96 if crushed else 112
    out.append(pot_plant(96 if crushed else 86, crushed))
    out.append(ladder(foot, GY - 2, 132, 96))
    if crushed:
        out.append(f'<path d="M126 100 l8 6 l-6 4 l8 5" stroke="{SCRATCH}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    if kind != 'sheet':
        out.append(clipboard(114, 150, kind in ('sweep', 'mess', 'pot'), 14, 18, ang=-14))
    # the customer
    if kind == 'sheet':
        out.append(person(104, ((110, 158), (88, 132)), face=-1, look=4, kind='wife'))
    else:
        out.append(person(160, ((166, 158), (152, 156)), face=-1, look=0, kind='wife'))
    # offcuts
    if kind == 'mess':
        out.append(offcuts([(30, 190), (52, 184), (70, 192), (86, 186), (104, 194), (120, 190), (24, 176)]))
    else:
        out.append(offcuts([(180, 194), (188, 196), (176, 197)]))
    # the broom: in his hands while he sweeps, else against the wall
    if kind != 'sheet':
        out.append(pocket_pen({'sweep': 56, 'mess': 60, 'pot': 58, 'nosheet': 62}[kind], -1 if kind in ('mess', 'nosheet') else 1))
    if kind == 'sweep':
        out.append(person(56, ((62, 150), (86, 168)), face=1, look=8, kind='lineman'))
        out.append(broom(92, 190, 74, 140))
    elif kind == 'sheet':
        out.append(person(52, ((46, 156), (82, 130)), face=1, look=-4, kind='lineman'))
        out.append(clipboard(78, 112, True, 16, 22))
        out.append(pen_in(86, 126))
        out.append(broom(192, 196, 186, 108))
    elif kind == 'mess':
        out.append(person(60, ((48, 152), (38, 134)), face=-1, look=10, kind='lineman'))
        out.append(broom(192, 196, 186, 108))
    elif kind == 'pot':
        out.append(person(58, ((52, 158), (74, 160)), face=1, look=-4, kind='lineman'))
        out.append(broom(192, 196, 186, 108))
    else:  # nosheet
        out.append(person(62, ((50, 156), (36, 150)), face=-1, look=8, kind='lineman'))
        out.append(old_meter(26, 148))
        out.append(broom(192, 196, 186, 108))
    return card_close(out)


CARDS = {}
for k in ('id', 'say', 'walk', 'demand', 'uniform', 'silent', 'laugh'):
    CARDS[f'arrive_{k}'] = arrive_card(k)
for k in ('invited', 'slip', 'climb', 'push', 'unannounced'):
    CARDS[f'entry_{k}'] = entry_card(k)
for k in ('meter', 'route', 'bedroom', 'almirah', 'peek'):
    CARDS[f'zone_{k}'] = zone_card(k)
for k in ('listen', 'report', 'argue', 'promise', 'wave'):
    CARDS[f'talk_{k}'] = talk_card(k)
for k in ('sweep', 'sheet', 'mess', 'pot', 'nosheet'):
    CARDS[f'finish_{k}'] = finish_card(k)

# Safe cards and traps per round (mirrors learn_board_pack79.dart).
ROUNDS = {
    'arrive': (['arrive_id', 'arrive_say'], ['arrive_walk', 'arrive_demand', 'arrive_uniform', 'arrive_silent', 'arrive_laugh']),
    'entry': (['entry_invited', 'entry_slip'], ['entry_climb', 'entry_push', 'entry_unannounced']),
    'zone': (['zone_meter', 'zone_route'], ['zone_bedroom', 'zone_almirah', 'zone_peek']),
    'talk': (['talk_listen', 'talk_report'], ['talk_argue', 'talk_promise', 'talk_wave']),
    'finish': (['finish_sweep', 'finish_sheet'], ['finish_mess', 'finish_pot', 'finish_nosheet']),
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
