"""Picture cards for lesson 7.4 শেখা ("পারমিট-টু-ওয়ার্ক (PTW): একটি আইনি চুক্তি").

python -I tool/m7_board74_art.py .

Writes assets/game/art/m7_board74/*.svg in the clean gradient style of
tool/m6_board63_art.py and tool/m7_board72_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art; the marks a worker reads (the PTW
number, the times on a form, in the logbook and on a chit) are stroke glyphs
with English digits. The DTR / feeder isolation is a padlocked, tagged switch
panel (no DO anywhere, ruling M7-9).

What the cards show comes from lesson 7.4 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md) only. Five rounds (ruling X6:
the item spec's round 6 is dropped):
  1. sign: the operator signs the issuer box with the switch panel OFF,
     padlocked and tagged behind him; the supervisor signs as receiver with
     his crew at the table; the return signed with every man down. Traps: the
     signature given with eyes on a phone, the receiver off to a tea stall
     while a man climbs, the issuer box blank, the return signed with a man
     still on the pole;
  2. copies: both copies, same number, all filled and both signed; the field
     copy with both signatures in the crew's hands. Traps: the field copy with
     the issuer box blank (the module's deadly act), two copies with two
     numbers, the control-room copy with its time box blank;
  3. log: the logbook row with the issue time; the row with the
     cancellation time. The issue cards (issue, notime, chit) show the wall
     clock at 10:30 and the supervisor taking the new permit; the return
     cards (cancel, nocancel) show the clock at 2:20, the crew back in the
     room and the permit handed back struck through (cancelled), so the
     empty cancellation cell reads as the miss it is. Traps: the issue time
     cell empty, the returned permit's cancellation cell empty, the time on
     a loose chit;
  4. talk: the receiver asking the issuer again (a question bubble); a crew
     man, pen held up, asking the supervisor before signing. Traps: 'I
     thought...' (a thought cloud with the switch handle down and a tick, no
     question, and he is already walking out, his back to the desk), signing
     while frowning at a condition, a half-heard 'yes' on a crackling phone;
  5. crew: a lineman reading the PTW number on the field copy while a mate
     works aloft; a lineman standing back, the ladder down (no permit).
     Traps: the climber, back to the permit the supervisor holds out, waving
     it off (a speech bubble with the permit struck out), holding the ladder
     for a climb with no permit, the ladder set up on an LT pole with no
     permit.

Fairness (the playbook, section 4): every hand the dealer can make (one safe
card + any three traps) is checked: each colour or gradient the safe card
draws is drawn by a trap in that hand, the safe card's backdrop is a trap's
backdrop too, and every prop or figure (tagged <!--prop:name-->: lineman,
supervisor, officer, form, panel, logbook, bubble...) on the safe card is on a
trap in that hand, and none sits on every trap of the hand but not on the safe
card. No trap may be a near-copy of a safe card of its round: the props and
the readable marks (tagged <!--mark:name-->: digits, signatures, the cancel
cross, the clock) of the two must differ. It deletes only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board74_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board74')
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


def mark(name):
    """An XML comment naming a readable mark on the card (the digits of a
    number or time, a signature, a cancel cross). The near-copy check (here and
    in the test) reads these with the prop tags: no trap may say exactly what
    a safe card of its round says."""
    return f'<!--mark:{name}-->'


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
    return mark('d' + text) + f'<path d="{" ".join(d)}" stroke="{color}" stroke-width="{f(1.5 * k)}" stroke-linecap="round" fill="none"/>'



# --------------------------------------------------------------------------
# Things of a permit: the PTW form, the switch panel, the logbook.
# --------------------------------------------------------------------------

FORM_HEAD = '#3C6E91'   # the PTW form's printed head band
SIGN = '#2346A0'        # a signature in blue ink
PANEL = '#7D8A94'
PANEL_D = '#5F6B74'
LOCK = '#C9A23A'
TAG_RED = RED
CUP = '#E9E4D8'
TEA = '#8A5A2E'
AWNING = '#3F7D5A'
INSUL = '#B8653A'       # porcelain pin insulators
LTSPOOL = '#E6E1D3'     # LT shackle spools


def squiggle(x, y, w):
    """A hand signature across a sign box."""
    return (mark('sig') + f'<path d="M{f(x)} {f(y)} q{f(w * 0.15)} -5 {f(w * 0.3)} 0 t{f(w * 0.3)} 0 t{f(w * 0.3)} -1" '
            f'stroke="{SIGN}" stroke-width="1.2" fill="none" stroke-linecap="round"/>')


def form(x, y, w=40, h=52, num='417', issuer=True, receiver=True, time=True, ang=0):
    """The PTW form: the head band, the PTW number (stroke digits), the job
    lines, the time line, and the two sign boxes at the foot (issuer left,
    receiver right)."""
    o = [tag('form'), f'<g transform="rotate({f(ang)} {f(x + w / 2)} {f(y + h / 2)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="1.2" fill="{PAPER}" stroke="{INK}" stroke-width="0.7"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{f(h * 0.12)}" rx="1.2" fill="{FORM_HEAD}"/>']
    k = h / 52
    o.append(glyphs(x + 3, y + h * 0.17, num, 6 * k))
    for i in range(3):
        o.append(f'<path d="M{f(x + 3)} {f(y + h * (0.38 + i * 0.09))} h{f(w - 6)}" stroke="{INK}" stroke-width="0.6"/>')
    # the time line: a short box, with the time in it when filled
    ty = y + h * 0.62
    o.append(f'<rect x="{f(x + 3)}" y="{f(ty)}" width="{f(w * 0.55)}" height="{f(h * 0.1)}" fill="none" stroke="{INK}" stroke-width="0.5"/>')
    if time:
        o.append(glyphs(x + 5, ty + h * 0.015, '1030', 4.4 * k))
    bw, bh, by = (w - 9) / 2, h * 0.16, y + h * 0.79
    for i, signed in enumerate((issuer, receiver)):
        bx = x + 3 + i * (bw + 3)
        o.append(f'<rect x="{f(bx)}" y="{f(by)}" width="{f(bw)}" height="{f(bh)}" fill="none" stroke="{INK}" stroke-width="0.6"/>')
        if signed:
            o.append(squiggle(bx + 1.5, by + bh * 0.6, bw - 3))
    o.append('</g>')
    return ''.join(o)


def switch_panel(x, y):
    """The feeder's switch panel: handle down (OFF), padlocked and tagged."""
    return (tag('panel') + tag('lock') +
            f'<rect x="{f(x)}" y="{f(y)}" width="40" height="66" rx="2" fill="{PANEL}"/>'
            f'<rect x="{f(x + 4)}" y="{f(y + 4)}" width="32" height="58" rx="1" fill="none" stroke="{PANEL_D}" stroke-width="1.2"/>'
            f'<rect x="{f(x + 16)}" y="{f(y + 14)}" width="8" height="22" rx="2" fill="{PANEL_D}"/>'
            f'<rect x="{f(x + 14)}" y="{f(y + 30)}" width="12" height="6" rx="1.5" fill="{WIRE}"/>'
            f'<path d="M{f(x + 17)} {f(y + 40)} a3 3 0 0 1 6 0" stroke="{INK}" stroke-width="1.3" fill="none"/>'
            f'<rect x="{f(x + 15.5)}" y="{f(y + 40)}" width="9" height="7" rx="1" fill="{LOCK}"/>'
            f'<path d="M{f(x + 24)} {f(y + 44)} l4 6" stroke="{INK}" stroke-width="0.6"/>'
            f'<rect x="{f(x + 25)}" y="{f(y + 50)}" width="8" height="11" rx="1" fill="{TAG_RED}"/>')


def logbook(x, y, rows):
    """The bound PTW logbook lying open: per row the PTW number, the issue
    time and the cancellation time (None = an empty cell)."""
    w, h = 124, 64
    o = [tag('logbook'),
         f'<rect x="{f(x - 3)}" y="{f(y - 2)}" width="{w + 6}" height="{h + 5}" rx="2" fill="{WOOD_D}"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w / 2 - 1}" height="{h}" fill="{PAPER}"/>',
         f'<rect x="{f(x + w / 2 + 1)}" y="{f(y)}" width="{w / 2 - 1}" height="{h}" fill="{PAPER}"/>',
         f'<path d="M{f(x + w / 2)} {f(y)} v{h}" stroke="{INK}" stroke-width="1"/>']
    cols = [x + 2, x + 44, x + 84]
    for cx in cols[1:]:
        o.append(f'<path d="M{f(cx - 2)} {f(y + 3)} v{h - 6}" stroke="{INK}" stroke-width="0.5"/>')
    for i, (num, t_in, t_out) in enumerate(rows):
        ry = y + 5 + i * 14
        o.append(f'<path d="M{f(x + 2)} {f(ry + 12)} h{w - 4}" stroke="{INK}" stroke-width="0.4"/>')
        o.append(glyphs(cols[0] + 4, ry + 2, num, 8))
        if t_in:
            o.append(glyphs(cols[1] + 4, ry + 2, t_in, 8))
        if t_out:
            o.append(glyphs(cols[2] + 4, ry + 2, t_out, 8))
    return ''.join(o)


def chit(x, y, ang=-12):
    """A loose torn chit with a time scribbled on it."""
    return (tag('chit') + f'<g transform="rotate({f(ang)} {f(x + 12)} {f(y + 8)})">'
            f'<path d="M{f(x)} {f(y)} h24 l-1 3 l2 3 l-1 3 l1 3 l-1 4 h-24 Z" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
            + glyphs(x + 3, y + 4, '1030', 7) + '</g>')


def pen_in(x, y, capped=False):
    """A pen in a hand at (x, y); capped, it is held up, away from the paper."""
    if capped:
        return tag('pen') + f'<path d="M{f(x)} {f(y)} l2 -11" stroke="{WIRE}" stroke-width="2.4" stroke-linecap="round"/>'
    return tag('pen') + f'<path d="M{f(x)} {f(y)} l6 6" stroke="{WIRE}" stroke-width="1.8" stroke-linecap="round"/>'


def phone_in(x, y):
    return (tag('phone') + f'<rect x="{f(x - 3)}" y="{f(y - 8)}" width="6" height="10" rx="1" fill="{WIRE}"/>'
            f'<rect x="{f(x - 2)}" y="{f(y - 7)}" width="4" height="7" fill="url(#lcd)"/>')


def qmark(cx, cy, s=1.0):
    return (f'<path d="M{f(cx - 3 * s)} {f(cy - 3 * s)} a3 3 0 1 1 4 3 q-1 0.6 -1 2.4" stroke="{INK}" stroke-width="{f(1.6 * s)}" fill="none" stroke-linecap="round"/>'
            f'<circle cx="{f(cx)}" cy="{f(cy + 6 * s)}" r="{f(0.9 * s)}" fill="{INK}"/>')


def bubble(x, y, kind='ask'):
    """A speech bubble (ask: a question mark; noise: a crackle; nope: a
    permit struck out) or a thought cloud (assume: the switch handle down and
    a tick, no question: he took the line as off and went on)."""
    o = [tag('bubble')]
    if kind == 'assume':
        o.append(f'<ellipse cx="{f(x)}" cy="{f(y)}" rx="19" ry="14" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
        o.append(f'<circle cx="{f(x + 13)}" cy="{f(y + 18)}" r="3.2" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
        o.append(f'<circle cx="{f(x + 18)}" cy="{f(y + 25)}" r="1.9" fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
        # a little switch panel, handle down (OFF, he thinks) ...
        o.append(f'<rect x="{f(x - 13)}" y="{f(y - 9)}" width="12" height="18" rx="1" fill="{PANEL}"/>'
                 f'<rect x="{f(x - 9)}" y="{f(y - 6)}" width="4" height="9" rx="1" fill="{PANEL_D}"/>'
                 f'<rect x="{f(x - 10.5)}" y="{f(y + 1)}" width="7" height="3.4" rx="1" fill="{WIRE}"/>')
        # ... and a tick: settled, nothing asked
        o.append(f'<path d="M{f(x + 2)} {f(y)} l4 5 l8 -11" stroke="{INK}" stroke-width="2.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    elif kind == 'nope':
        o.append(f'<path d="M{f(x - 14)} {f(y - 12)} h28 a3 3 0 0 1 3 3 v18 a3 3 0 0 1 -3 3 h-6 l6 8 l-12 -8 h-16 a3 3 0 0 1 -3 -3 v-18 a3 3 0 0 1 3 -3 Z" '
                 f'fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
        # a small permit, waved off with a stroke through it
        o.append(f'<rect x="{f(x - 7)}" y="{f(y - 9)}" width="14" height="18" rx="0.8" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
                 f'<rect x="{f(x - 7)}" y="{f(y - 9)}" width="14" height="2.6" fill="{FORM_HEAD}"/>'
                 f'<path d="M{f(x - 4)} {f(y - 2)} h8 M{f(x - 4)} {f(y + 1)} h8 M{f(x - 4)} {f(y + 4)} h6" stroke="{INK}" stroke-width="0.5"/>'
                 f'<path d="M{f(x - 11)} {f(y + 9)} L{f(x + 11)} {f(y - 9)}" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>')
    else:
        o.append(f'<path d="M{f(x - 14)} {f(y - 10)} h28 a3 3 0 0 1 3 3 v14 a3 3 0 0 1 -3 3 h-14 l-6 7 l0 -7 h-8 a3 3 0 0 1 -3 -3 v-14 a3 3 0 0 1 3 -3 Z" '
                 f'fill="{MOVE}" stroke="{INK}" stroke-width="0.6"/>')
        if kind == 'ask':
            o.append(qmark(x, y - 2))
        else:
            o.append(f'<path d="M{f(x - 9)} {f(y)} l3 -4 l3 6 l3 -6 l3 6 l3 -6 l3 4" stroke="{INK}" stroke-width="1.2" fill="none" stroke-linejoin="round"/>')
    return ''.join(o)


def desk(x, y, w=60):
    """A desk seen from the front (the people behind it stand in its shadow)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="5" rx="1" fill="{WOOD}"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 5)}" width="{w - 6}" height="{f(GY - y - 5)}" fill="{WOOD_D}"/>')


def table(x, y, w=56):
    """A site table (legs, no front)."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="4" rx="1" fill="{WOOD}"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 4)}" width="3" height="{f(GY - y - 4)}" fill="{WOOD_D}"/>'
            f'<rect x="{f(x + w - 6)}" y="{f(y + 4)}" width="3" height="{f(GY - y - 4)}" fill="{WOOD_D}"/>')


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


def tea_stall(x):
    return (tag('stall') + f'<path d="M{x} 92 h{200 - x} v12 h-{200 - x} Z" fill="{AWNING}"/>'
            f'<rect x="{x + 4}" y="104" width="3" height="{GY - 104}" fill="{WOOD_D}"/>'
            f'<rect x="{x}" y="150" width="{200 - x}" height="{GY - 150}" fill="{WOOD}"/>')


def cup(x, y):
    return (tag('cup') + f'<path d="M{f(x - 3)} {f(y - 4)} h6 l-1 6 h-4 Z" fill="{CUP}" stroke="{INK}" stroke-width="0.5"/>'
            f'<path d="M{f(x - 2)} {f(y - 3)} h4" stroke="{TEA}" stroke-width="1"/>')


def control_room():
    """A control room's back wall: a window strip (the yard outside)."""
    return f'<rect x="96" y="30" width="96" height="40" fill="url(#glass)" stroke="{WOOD_D}" stroke-width="2"/>'


def climber(x, gy, face=-1, wave=False):
    """A lineman up the pole (feet on the step bolts), hands on the pole."""
    hands = ((x + 10 * face, gy - 60), (x + 6 * face, gy - 70)) if not wave else ((x + 10 * face, gy - 60), (x - 16 * face, gy - 78))
    return tag('aloft') + person(x, hands, face=face, look=-20, gy=gy, s=1.0)


def wall_clock(x, y, hh, mm):
    """A round wall clock reading hh:mm (the log round: the issue cards at
    10:30, the return cards at 2:20 in the afternoon)."""
    a_h = math.radians((hh % 12 + mm / 60) * 30)
    a_m = math.radians(mm * 6)
    ticks = ' '.join(f'M{f(x + 10.5 * math.sin(math.radians(i * 30)))} {f(y - 10.5 * math.cos(math.radians(i * 30)))} '
                     f'L{f(x + 12.5 * math.sin(math.radians(i * 30)))} {f(y - 12.5 * math.cos(math.radians(i * 30)))}' for i in range(12))
    return (tag('clock') + mark(f'clock{hh:02d}{mm:02d}') +
            f'<circle cx="{f(x)}" cy="{f(y)}" r="15" fill="{WOOD_D}"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="13.4" fill="{PAPER}"/>'
            f'<path d="{ticks}" stroke="{INK}" stroke-width="1.1"/>'
            f'<path d="M{f(x)} {f(y)} L{f(x + 7 * math.sin(a_h))} {f(y - 7 * math.cos(a_h))}" stroke="{WIRE}" stroke-width="2.4" stroke-linecap="round"/>'
            f'<path d="M{f(x)} {f(y)} L{f(x + 11 * math.sin(a_m))} {f(y - 11 * math.cos(a_m))}" stroke="{WIRE}" stroke-width="1.4" stroke-linecap="round"/>'
            f'<circle cx="{f(x)}" cy="{f(y)}" r="1.4" fill="{WIRE}"/>')


def cancel_cross(x, y, w, h):
    """The big cancel cross over a returned permit (the work is over)."""
    return (tag('returned') + mark('cancelled') +
            f'<path d="M{f(x + 2)} {f(y + 3)} L{f(x + w - 2)} {f(y + h - 3)} M{f(x + w - 2)} {f(y + 3)} L{f(x + 2)} {f(y + h - 3)}" '
            f'stroke="{RED}" stroke-width="3.2" stroke-linecap="round" stroke-opacity="0.85"/>')


# --------------------------------------------------------------------------
# Round 1 — sign: the issuer's and the receiver's signatures.
# --------------------------------------------------------------------------

def sign_card(kind):
    if kind in ('issuer', 'phone', 'blank'):
        out = card_open('room')
        out.append(control_room())
        out.append(switch_panel(10, 64))
        issuer = kind != 'blank'
        # the operator behind the desk; in blank he stands at the panel
        if kind == 'blank':
            out.append(person(64, ((52, 128), (44, 104)), face=-1, look=0, gy=182, kind='officer'))
        else:
            out.append(person(76, ((64, 130), (106, 126)), face=1, look=8, gy=182, kind='officer'))
        out.append(desk(56, 136, 96))
        out.append(form(100, 98, 36, 46, issuer=issuer, receiver=True))
        if kind == 'issuer':
            out.append(pen_in(104, 126))
            out.append(person(170, ((164, 156), (146, 132)), face=-1, look=-6, kind='super'))
        elif kind == 'phone':
            out.append(person(166, ((162, 132), (134, 134)), face=-1, look=14, kind='super'))
            out.append(pen_in(128, 128))
            out.append(phone_in(161, 134))
        else:
            out.append(person(166, ((162, 156), (130, 134)), face=-1, look=-6, kind='super'))
            out.append(pen_in(124, 128))
        return card_close(out)
    out = card_open('yard')
    out.append(hv_pole(162))
    up = kind in ('tea', 'early')
    if up:
        out.append(climber(152, 112, face=1))
    out.append(table(34, 146, 66))
    out.append(form(52, 112, 34, 34, issuer=True, receiver=True))
    if kind == 'tea':
        out.append(tea_stall(176))
        out.append(person(116, ((110, 156), (126, 146)), face=1, look=4, kind='super'))
        out.append(cup(128, 146))
        out.append(person(24, ((20, 156), (34, 150)), face=1, look=-16, kind='lineman'))
    else:
        out.append(person(110, ((104, 156), (84, 140)), face=-1, look=-8, kind='super'))
        out.append(pen_in(80, 136))
        if kind == 'receiver':
            out.append(person(24, ((20, 156), (50, 140)), face=1, look=8, kind='lineman'))
        elif kind == 'ret':
            out.append(person(24, ((18, 158), (40, 162)), face=1, look=6, kind='lineman'))
            out.append(person(140, ((134, 160), (148, 160)), face=-1, look=-4, kind='lineman'))
        else:
            out.append(person(24, ((20, 156), (34, 150)), face=1, look=-16, kind='lineman'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — copies: the control-room copy and the field copy.
# --------------------------------------------------------------------------

def copies_card(kind):
    if kind in ('both', 'twonum', 'blank'):
        out = card_open('room')
        out.append(control_room())
        out.append(person(40, ((30, 130), (66, 128)), face=1, look=8, gy=182, kind='officer'))
        out.append(desk(20, 140, 160))
        out.append(form(56, 84, 44, 56, num='417', time=kind != 'blank'))
        out.append(form(106, 84, 44, 56, num='418' if kind == 'twonum' else '417'))
        out.append(person(172, ((168, 156), (146, 132)), face=-1, look=-8, kind='super'))
        return card_close(out)
    out = card_open('yard')
    out.append(hv_pole(170))
    out.append(person(112, ((92, 120), (118, 122)), face=-1, look=8, kind='super'))
    out.append(form(70, 94, 48, 62, issuer=kind == 'field'))
    out.append(person(40, ((34, 156), (66, 114)), face=1, look=10, kind='lineman'))
    out.append(person(150, ((144, 160), (156, 162)), face=-1, look=-6, kind='lineman'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — log: the formal logbook.
# --------------------------------------------------------------------------

def log_card(kind):
    out = card_open('room')
    out.append(control_room())
    back = kind in ('cancel', 'nocancel')
    # The wall clock: 10:30 when the permit goes out, 2:20 when it comes back.
    out.append(wall_clock(30, 40, 2, 20) if back else wall_clock(30, 40, 10, 30))
    out.append(person(52, ((40, 120), (78, 132)), face=1, look=12, gy=170, kind='officer'))
    if back:
        # the crew is back in the room: the job is over
        out.append(person(118, ((112, 150), (126, 150)), face=-1, look=-6, gy=176, kind='lineman'))
    out.append(desk(10, 138, 150))
    t_in = None if kind == 'notime' else '1030'
    t_out = '1420' if kind == 'cancel' else None
    num = '418'
    out.append(logbook(28, 100 + 38, [('416', '0930', '1240'), ('417', '0950', '1310'), (num, t_in if kind != 'chit' else None, t_out)]))
    if kind in ('issue', 'notime'):
        # the operator hands the new permit across the desk
        out.append(form(150, 96, 30, 40, num=num, ang=8))
        out.append(person(182, ((176, 156), (160, 118)), face=-1, look=-6, kind='super'))
        out.append(pen_in(80, 130))
    elif back:
        # the receiver hands the permit back, struck through: cancelled
        out.append(person(184, ((178, 156), (162, 128)), face=-1, look=-10, kind='super'))
        out.append(form(134, 98, 30, 40, num=num, ang=-4))
        out.append(cancel_cross(134, 98, 30, 40))
        out.append(pen_in(80, 130))
    else:
        out.append(form(150, 96, 30, 40, num=num, ang=8))
        out.append(person(182, ((176, 156), (160, 118)), face=-1, look=-6, kind='super'))
        out.append(chit(64, 112))
        out.append(pen_in(84, 120))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — talk: at issue and return.
# --------------------------------------------------------------------------

def talk_card(kind):
    out = card_open('room')
    out.append(control_room())
    officer = kind in ('ask', 'blind')
    if officer:
        out.append(person(34, ((24, 128), (60, 128)), face=1, look=4, gy=176, kind='officer'))
    elif kind == 'thought':
        # the supervisor behind the desk, the form still waiting there
        out.append(person(40, ((30, 128), (64, 124)), face=1, look=6, gy=176, kind='super'))
    out.append(desk(14, 140, 110))
    out.append(form(62, 108, 30, 30))
    if kind == 'ask':
        out.append(person(126, ((120, 156), (84, 122)), face=-1, look=-4, kind='super'))
        out.append(bubble(124, 52, 'ask'))
        out.append(person(172, ((166, 160), (176, 160)), face=-1, look=-4, kind='lineman'))
    elif kind == 'learn':
        out.append(person(134, ((128, 156), (110, 122)), face=-1, look=-6, kind='lineman'))
        out.append(pen_in(110, 122, capped=True))
        out.append(bubble(132, 52, 'ask'))
        out.append(person(176, ((170, 156), (156, 120)), face=-1, look=-10, kind='super'))
    elif kind == 'thought':
        # 'I thought the line was off': no question, he took it as settled
        # and is already walking out, his back to the desk and the form.
        out.append(person(150, ((140, 160), (162, 150)), face=1, look=4, kind='lineman'))
        out.append(bubble(122, 54, 'assume'))
    elif kind == 'blind':
        out.append(person(126, ((120, 156), (84, 128)), face=-1, look=14, kind='lineman'))
        out.append(pen_in(80, 122))
        out.append(person(174, ((168, 156), (176, 140)), face=-1, look=-6, kind='super'))
    else:  # noisy
        out.append(person(132, ((126, 156), (0, 0)), face=-1, look=10, kind='super', phone=True))
        out.append(bubble(108, 52, 'noise'))
        out.append(person(176, ((170, 160), (180, 160)), face=-1, look=-4, kind='lineman'))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — crew: a team member before the climb.
# --------------------------------------------------------------------------

def crew_card(kind):
    out = card_open('yard')
    out.append(hv_pole(150, lt=kind == 'lt'))
    if kind == 'stand':
        out.append(ladder(70, GY - 2, 150, GY - 10))
        out.append(person(112, ((104, 136), (120, 138)), face=-1, look=0, kind='lineman'))
        out.append(person(40, ((34, 156), (46, 156)), face=1, look=6, kind='super'))
    elif kind != 'lt':
        out.append(ladder(122, GY - 2, 146, 46))
        if kind == 'read':
            # the work runs under a valid permit: a mate is up, and the man at
            # the foot reads the PTW number on the field copy
            out.append(climber(134, 140, face=1))
            out.append(person(96, ((84, 126), (104, 128)), face=1, look=12, kind='lineman'))
            out.append(form(82, 104, 30, 38))
            out.append(person(40, ((34, 156), (60, 140)), face=1, look=6, kind='super'))
        elif kind == 'dontknow':
            # the supervisor holds the permit out; the climber has his back
            # to it and waves it off ('the supervisor's business')
            out.append(climber(134, 150, face=1, wave=True))
            out.append(person(56, ((48, 156), (78, 120)), face=1, look=-14, kind='super'))
            out.append(form(72, 100, 26, 32, ang=-10))
            out.append(bubble(112, 54, 'nope'))
        elif kind == 'ladder':
            out.append(climber(134, 140, face=1))
            out.append(person(104, ((118, 150), (124, 128)), face=1, look=-12, kind='lineman'))
            out.append(person(40, ((34, 156), (46, 156)), face=1, look=-8, kind='super'))
    if kind == 'lt':
        # the LT pole, no permit: he sets the ladder up to start the job
        out.append(ladder(104, GY - 2, 146, 50))
        out.append(person(112, ((118, 120), (128, 104)), face=1, look=-16, kind='lineman'))
        out.append(person(40, ((34, 156), (58, 128)), face=1, look=-8, kind='super'))
    return card_close(out)


CARDS = {}
for k in ('issuer', 'receiver', 'ret', 'phone', 'tea', 'blank', 'early'):
    CARDS[f'sign_{k}'] = sign_card(k)
for k in ('both', 'field', 'nosign', 'twonum', 'blank'):
    CARDS[f'copies_{k}'] = copies_card(k)
for k in ('issue', 'cancel', 'notime', 'nocancel', 'chit'):
    CARDS[f'log_{k}'] = log_card(k)
for k in ('ask', 'learn', 'thought', 'blind', 'noisy'):
    CARDS[f'talk_{k}'] = talk_card(k)
for k in ('read', 'stand', 'dontknow', 'ladder', 'lt'):
    CARDS[f'crew_{k}'] = crew_card(k)

# Safe cards and traps per round (mirrors learn_board_pack74.dart).
ROUNDS = {
    'sign': (['sign_issuer', 'sign_receiver', 'sign_ret'], ['sign_phone', 'sign_tea', 'sign_blank', 'sign_early']),
    'copies': (['copies_both', 'copies_field'], ['copies_nosign', 'copies_twonum', 'copies_blank']),
    'log': (['log_issue', 'log_cancel'], ['log_notime', 'log_nocancel', 'log_chit']),
    'talk': (['talk_ask', 'talk_learn'], ['talk_thought', 'talk_blind', 'talk_noisy']),
    'crew': (['crew_read', 'crew_stand'], ['crew_dontknow', 'crew_ladder', 'crew_lt']),
}
HAND = 4

_PROP = re.compile(r'<!--prop:(\w+)-->')
_MARK = re.compile(r'<!--mark:(\w+)-->')


def content(svg):
    """What a card says, ignoring where things sit: every tagged prop or
    figure and every readable mark (digits, signatures, the cancel cross, the
    clock), counted."""
    return sorted(_PROP.findall(svg) + _MARK.findall(svg))
_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    props = {k: set(_PROP.findall(v)) for k, v in CARDS.items()}
    said = {k: content(v) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for t in traps:
                # A near-copy: the trap says exactly what the safe card says,
                # only moved or turned (the old log_issue / log_nocancel pair).
                if said[t] == said[s]:
                    problems.append(f'{rnd}: {t} says just what {s} says (a near-copy)')
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
