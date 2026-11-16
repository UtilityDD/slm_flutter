"""Picture cards for lesson 7.2 শেখা ("ওয়ার্কম্যান কম্পেনসেশন অ্যাক্ট: দুর্ঘটনার পর আপনার অধিকার").

python -I tool/m7_board72_art.py .

Writes assets/game/art/m7_board72/*.svg in the clean gradient style of
tool/m6_board63_art.py and tool/m6_board610_art.py (200 x 220 scene cards,
drawn edge to edge). No words in the art; the only mark a worker reads (the
zero on a pay slip) is a stroke glyph with an English digit. No amounts, no
day counts (the lesson gives none), no death scene.

What the cards show comes from lesson 7.2 (live text) and the Module 7
rulings (docs/module_specs/module7_rulings.md) only. Five rounds (ruling X6:
the item spec's six rounds trimmed — its paperwork round and its claim round
are one round here):
  1. who: an injured permanent lineman, a contract-crew worker (vest) and a
     temporary helper (cap, cross-arm) each hand a claim at the office
     window. Traps: the officer turning the contract worker away, the
     officer turning the temporary helper away, a notice board with the
     bolt crossed out ("electrical work is outside the law");
  2. partial: permanent partial disablement — a finger lost, now at the
     store counter; one eye lost, now at the office desk. Traps: back on the
     pole after some weeks (temporary), in bed with no work possible
     (permanent total), a burnt hand back at the same job after months
     (temporary);
  3. rights: the company officer pays the hospital bill; the allowance
     envelope at the hospital bed; a claim for a work illness (chemical
     drum, cough). Traps: the wife paying the bill, a pay slip at 0 for the
     hospital days, the officer waving the coughing worker away;
  4. steps: the supervisor phoned at once; a government hospital doctor
     (the red cross) and the company doctor (the bolt sign) writing the
     injury report. Traps: the injury hidden from the supervisor, the
     supervisor told only after many calendar pages, a medicine-shop man
     writing a note;
  5. claim: a written notice into the company letter box (copy kept), every
     paper in one file at home, the file handed at the Labour Commissioner's
     desk. Traps: only telling the gate guard, the bills into the dustbin, a
     silent signature on 'this is all you get'.

Fairness (the playbook, section 4): every card in a round shares one
backdrop; the script checks every hand the dealer can make (one safe card +
any three traps): each colour or gradient the safe card draws is drawn by a
trap in that hand, the safe card's backdrop is a trap's backdrop too, and
every prop or figure (tagged <!--prop:name-->: lineman, officer, paper,
bandage, phone, doctor...) on the safe card is on a trap in that hand, and
none sits on every trap of the hand but not on the safe card. It deletes
only its own stale cards.
"""

import itertools
import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m7_board72_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_board72')
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
    (here and in test/learn_board_72_test.dart) reads these: no prop may sit
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
# Things.
# --------------------------------------------------------------------------

def paper(x, y, ang=0, w=14, h=18, lines=3):
    o = [tag('paper'), f'<g transform="rotate({f(ang)} {f(x + w / 2)} {f(y + h / 2)})">',
         f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="{h}" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>']
    for i in range(lines):
        o.append(f'<path d="M{f(x + 2.5)} {f(y + 4 + i * 4)} h{f(w - 5)}" stroke="{INK}" stroke-width="0.7"/>')
    o.append('</g>')
    return ''.join(o)


def notes(x, y):
    """Bank notes in a hand (paying)."""
    return (tag('money') + f'<rect x="{f(x)}" y="{f(y)}" width="14" height="8" rx="1" fill="{GREEN_NOTE}" stroke="{INK}" stroke-width="0.5"/>'
            f'<rect x="{f(x + 2)}" y="{f(y - 2)}" width="14" height="8" rx="1" fill="{GREEN_NOTE}" stroke="{INK}" stroke-width="0.5"/>')


def envelope(x, y, ang=0):
    return (tag('money') + f'<g transform="rotate({f(ang)} {f(x + 8)} {f(y + 5)})"><rect x="{f(x)}" y="{f(y)}" width="16" height="10" rx="1" fill="{ENVELOPE}"/>'
            f'<path d="M{f(x)} {f(y)} L{f(x + 8)} {f(y + 6)} L{f(x + 16)} {f(y)}" stroke="{WOOD_D}" stroke-width="0.7" fill="none"/></g>')


def desk(x, y, w=60):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="5" rx="1" fill="{WOOD}"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 5)}" width="{w - 6}" height="{f(GY - y - 5)}" fill="{WOOD_D}"/>')


def office_window(x=0, w=86, top=58, sill=128):
    """A site-office wall with its counter window (the officer stands behind)."""
    return [f'<rect x="{x}" y="{top}" width="{w}" height="{GY - top}" fill="url(#bldg)"/>',
            f'<rect x="{x}" y="{top - 6}" width="{w + 6}" height="7" fill="{WOOD_D}"/>',
            f'<rect x="{x + 10}" y="{top + 18}" width="{w - 20}" height="{sill - top - 18}" fill="url(#glass)"/>']


def counter_front(x=0, w=86, sill=128):
    return (f'<rect x="{x + 6}" y="{sill}" width="{w - 6}" height="6" rx="1" fill="{WOOD}"/>'
            f'<rect x="{x}" y="{sill + 6}" width="{w}" height="{GY - sill - 6}" fill="url(#bldg)"/>')


def pole(x, top, bottom=GY, wdt=8):
    return (f'<rect x="{f(x - wdt / 2)}" y="{top}" width="{wdt}" height="{bottom - top}" fill="url(#pole)"/>'
            f'<rect x="{f(x - 18)}" y="{top + 10}" width="36" height="4" fill="{INK}"/>')


def crossarm(x, y):
    return tag('crossarm') + f'<rect x="{f(x)}" y="{f(y)}" width="40" height="5" rx="1" fill="{INK}"/>'


def palm_out(x, y):
    """A raised open palm (turning someone away) at (x, y)."""
    return (f'<rect x="{f(x - 3.5)}" y="{f(y - 6)}" width="7" height="9" rx="2.5" fill="{SKIN}"/>'
            f'<path d="M{f(x - 2)} {f(y - 6)} v-3 M{f(x)} {f(y - 6)} v-4 M{f(x + 2)} {f(y - 6)} v-3" stroke="{SKIN}" stroke-width="1.4" stroke-linecap="round"/>')


def notice_board(x, y):
    """A notice board: a bolt with a red cross over it (no words)."""
    return (tag('notice') + f'<rect x="{f(x)}" y="{f(y)}" width="34" height="28" rx="2" fill="{PAPER}" stroke="{WOOD_D}" stroke-width="2"/>'
            f'<path d="M{f(x + 19)} {f(y + 4)} L{f(x + 12)} {f(y + 15)} L{f(x + 17)} {f(y + 15)} L{f(x + 14)} {f(y + 24)} L{f(x + 22)} {f(y + 12)} L{f(x + 17)} {f(y + 12)} Z" fill="{HELMET}" stroke="{INK}" stroke-width="0.6"/>'
            f'<path d="M{f(x + 6)} {f(y + 4)} L{f(x + 28)} {f(y + 24)} M{f(x + 28)} {f(y + 4)} L{f(x + 6)} {f(y + 24)}" stroke="{RED}" stroke-width="2.4"/>')


def calendar(x, y, torn=0):
    """A wall calendar; [torn] pages flying off it (time passing)."""
    o = [tag('calendar'), f'<rect x="{f(x)}" y="{f(y)}" width="26" height="28" rx="1.5" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>',
         f'<rect x="{f(x)}" y="{f(y)}" width="26" height="7" rx="1.5" fill="{RED}"/>']
    for r in range(3):
        for c in range(4):
            o.append(f'<rect x="{f(x + 3 + c * 5.5)}" y="{f(y + 10 + r * 5.5)}" width="3.6" height="3.6" fill="{OFFICE_D}"/>')
    for i in range(torn):
        px, py = x + 30 + i * 9, y - 4 + (i % 2) * 10
        o.append(f'<g transform="rotate({15 + i * 18} {f(px + 6)} {f(py + 7)})"><rect x="{f(px)}" y="{f(py)}" width="12" height="13" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>'
                 f'<rect x="{f(px)}" y="{f(py)}" width="12" height="3.5" fill="{RED}"/></g>')
    return ''.join(o)


def bed(x, y, w=86):
    """A bed frame (the man is drawn with lying())."""
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{w}" height="8" rx="2" fill="{PILLOW}"/>'
            f'<rect x="{f(x)}" y="{f(y + 8)}" width="{w}" height="5" fill="{WOOD}"/>'
            f'<rect x="{f(x)}" y="{f(y - 14)}" width="5" height="{f(GY - y + 14)}" fill="{WOOD_D}"/>'
            f'<rect x="{f(x + w - 5)}" y="{f(y - 4)}" width="5" height="{f(GY - y + 4)}" fill="{WOOD_D}"/>')


def drum(x, y):
    """A chemical drum with a hazard diamond (no words)."""
    return (tag('drum') + f'<rect x="{f(x)}" y="{f(y)}" width="22" height="30" rx="2" fill="{DRUM}"/>'
            f'<path d="M{f(x)} {f(y + 9)} h22 M{f(x)} {f(y + 21)} h22" stroke="{DRUM_D}" stroke-width="1.4"/>'
            f'<path d="M{f(x + 11)} {f(y + 9)} L{f(x + 17)} {f(y + 15)} L{f(x + 11)} {f(y + 21)} L{f(x + 5)} {f(y + 15)} Z" fill="{HAZARD}" stroke="{INK}" stroke-width="0.5"/>')


def cough(x, y, face=-1):
    return tag('cough') + ''.join(
        f'<path d="M{f(x + face * (3 + i * 4))} {f(y - 3 - i)} q{f(face * 2)} {f(3 + i)} 0 {f(6 + 2 * i)}" stroke="{MOVE}" stroke-width="1.2" fill="none" stroke-linecap="round"/>'
        for i in range(3))


def sign_board(x, y, mark):
    """A building's sign board: a red cross (a government hospital) or the
    bolt (the company's own dispensary) — no words."""
    o = [f'<rect x="{f(x)}" y="{f(y)}" width="30" height="20" rx="2" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>']
    if mark == 'cross':
        o.append(f'<path d="M{f(x + 15)} {f(y + 4)} v12 M{f(x + 9)} {f(y + 10)} h12" stroke="{RED}" stroke-width="3.4"/>')
    elif mark == 'bolt':
        o.append(f'<path d="M{f(x + 17)} {f(y + 3)} L{f(x + 11)} {f(y + 11)} L{f(x + 15)} {f(y + 11)} L{f(x + 13)} {f(y + 17)} L{f(x + 20)} {f(y + 9)} L{f(x + 16)} {f(y + 9)} Z" fill="{HELMET}" stroke="{INK}" stroke-width="0.6"/>')
    else:  # a shop: bottles on the board
        o.append(f'<rect x="{f(x + 7)}" y="{f(y + 6)}" width="5" height="10" rx="1" fill="{BOTTLE}"/><rect x="{f(x + 17)}" y="{f(y + 6)}" width="5" height="10" rx="1" fill="{BOTTLE_2}"/>')
    return ''.join(o)


def building(x, w, top, mark):
    return (f'<rect x="{x}" y="{top}" width="{w}" height="{GY - top}" fill="url(#bldg)"/>'
            f'<rect x="{x}" y="{top - 5}" width="{w + 4}" height="6" fill="{WOOD_D}"/>'
            f'<rect x="{x + w - 30}" y="{top + 34}" width="22" height="{GY - top - 34}" fill="{WOOD}"/>'
            + sign_board(x + 8, top + 8, mark))


def shelf(x, y):
    """A chemist's shelf of bottles."""
    o = []
    for r in range(2):
        o.append(f'<rect x="{f(x)}" y="{f(y + 16 + r * 18)}" width="50" height="3" fill="{WOOD_D}"/>')
        for c in range(5):
            o.append(f'<rect x="{f(x + 3 + c * 9.5)}" y="{f(y + 5 + r * 18)}" width="6" height="11" rx="1" fill="{BOTTLE if (r + c) % 2 else BOTTLE_2}"/>')
    return ''.join(o)


def letterbox(x, y):
    return (tag('letterbox') + f'<rect x="{f(x)}" y="{f(y)}" width="18" height="24" rx="3" fill="{RED}"/>'
            f'<rect x="{f(x + 3)}" y="{f(y + 6)}" width="12" height="2.4" fill="{WIRE}"/>')


def folder(x, y, ang=0, spill=False):
    o = [tag('folder'), f'<g transform="rotate({f(ang)} {f(x + 13)} {f(y + 9)})">',
         f'<rect x="{f(x + 2)}" y="{f(y - 3)}" width="20" height="16" fill="{PAPER}" stroke="{INK}" stroke-width="0.5"/>',
         f'<path d="M{f(x)} {f(y)} h10 l3 -3 h13 v20 h-26 Z" fill="{ENVELOPE}" stroke="{WOOD_D}" stroke-width="0.6"/>', '</g>']
    return ''.join(o)


def dustbin(x, y):
    return (tag('dustbin') + f'<path d="M{f(x)} {f(y)} L{f(x + 4)} {f(GY)} L{f(x + 22)} {f(GY)} L{f(x + 26)} {f(y)} Z" fill="{INK}"/>'
            f'<rect x="{f(x - 2)}" y="{f(y - 3)}" width="30" height="4" rx="1" fill="{WIRE}"/>')


def pen(x, y):
    return f'<path d="M{f(x)} {f(y)} l7 -7" stroke="{WIRE}" stroke-width="1.8" stroke-linecap="round"/>'


def gate(x):
    """The company gate: a pillar and the bars."""
    return (f'<rect x="{x}" y="70" width="16" height="{GY - 70}" fill="url(#bldg)"/>'
            + ''.join(f'<rect x="{x + 18 + i * 9}" y="96" width="2.6" height="{GY - 96}" fill="{INK}"/>' for i in range(5))
            + f'<rect x="{x + 16}" y="96" width="46" height="3" fill="{INK}"/><rect x="{x + 16}" y="150" width="46" height="3" fill="{INK}"/>')


def house_wall(x=0, w=200, top=40):
    return (f'<rect x="{x}" y="{top}" width="{w}" height="{GY - top}" fill="url(#house)"/>'
            f'<rect x="{x + 18}" y="{top + 18}" width="34" height="30" fill="url(#glass)" stroke="{WOOD_D}" stroke-width="2"/>')


# --------------------------------------------------------------------------
# Round 1 — who: at the site office window.
# --------------------------------------------------------------------------

def who_card(kind):
    out = card_open('yard')
    out.append(pole(184, 20))
    out += office_window()
    accept = kind in ('perm', 'contract', 'temp')
    worker = {'perm': 'lineman', 'contract': 'contract', 'temp': 'helper',
              'clerk': 'contract', 'tempno': 'helper', 'notice': 'lineman'}[kind]
    # the officer behind the counter
    if accept:
        out.append(person(44, ((34, 120), (74, 124)), face=1, look=4, gy=170, kind='officer', s=1.2))
    elif kind == 'notice':
        out.append(person(44, ((34, 120), (60, 84)), face=1, look=-6, gy=170, kind='officer', s=1.2))
    else:
        out.append(person(44, ((34, 120), (64, 98)), face=1, look=0, gy=170, kind='officer', s=1.2))
        out.append(palm_out(64, 98))
    out.append(counter_front())
    if kind == 'notice':
        out.append(notice_board(48, 66))
    # the claim paper: taken across the counter, pushed back, or in his hand
    if accept:
        out.append(paper(72, 114, -8))
    elif kind == 'notice':
        out.append(paper(108, 128, 6))
    else:
        out.append(paper(66, 116, 14))
    if kind in ('temp', 'tempno'):
        out.append(crossarm(130, GY - 6))
    hand = (88, 120) if accept else (104, 132)
    out.append(person(118, ((112, 150), hand), face=-1, look=-4, kind=worker, bandage=('arm',)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 2 — partial: where the injured man works now.
# --------------------------------------------------------------------------

def partial_card(kind):
    out = card_open('room')
    out.append(calendar(150, 22, torn=2 if kind in ('plaster', 'burn') else 0))
    if kind == 'finger':
        # The store counter: parts on the shelf, the man without a finger
        # (bandaged hand) handing out a part.
        out.append(shelf(20, 40))
        out.append(person(62, ((52, 128), (88, 118)), face=1, look=4, gy=178, kind='lineman', bandage=('hand',)))
        out.append(desk(40, 132, 80))
        out.append(f'<rect x="88" y="122" width="16" height="10" rx="1" fill="{INK}"/>')
    elif kind == 'eye':
        out.append(person(100, ((86, 128), (116, 128)), face=1, look=8, gy=178, kind='lineman', patch=True))
        out.append(desk(66, 132, 90))
        out.append(paper(110, 116, 70, 12, 16))
    elif kind in ('plaster', 'burn'):
        # Back on the pole with his belt: the same job again.
        out.append(pole(110, 18))
        band = ('leg',) if kind == 'plaster' else ('hand',)
        out.append(person(92, ((106, 112), (112, 104)), face=1, look=-30, gy=176, kind='lineman', bandage=band))
        out.append(f'<path d="M99 150 Q110 156 121 150" stroke="{WIRE}" stroke-width="2.4" fill="none"/>')
        out.append(desk(10, 160, 34))
    elif kind == 'bed':
        # The bedside table: his medicines and the doctor's paper.
        out.append(f'<rect x="14" y="128" width="28" height="{GY - 128}" rx="2" fill="{SHELF}"/>')
        out.append(f'<rect x="17" y="117" width="6" height="11" rx="1" fill="{BOTTLE}"/><rect x="25" y="119" width="6" height="9" rx="1" fill="{BOTTLE_2}"/>')
        out.append(paper(20, 140, -6, 12, 14, 2))
        out.append(bed(46, 150, 110))
        out.append(lying(52, 136))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 3 — rights: the hospital and the office.
# --------------------------------------------------------------------------

def rights_card(kind):
    out = card_open('ward')
    if kind in ('pay', 'wife'):
        # The hospital's bill counter (its clerk behind), the man in bed
        # behind; the company officer pays, or the wife pays herself.
        out += office_window(0, 70, 64, 128)
        out.append(person(34, ((26, 120), (56, 124)), face=1, gy=170, kind='officer', s=1.15))
        out.append(counter_front(0, 70, 128))
        out.append(bed(110, 150, 86))
        out.append(lying(116, 136))
        out.append(paper(52, 112, -10))
        if kind == 'pay':
            out.append(person(92, ((84, 150), (70, 124)), face=-1, look=-4, kind='officer'))
            out.append(notes(62, 120))
        else:
            out.append(person(92, ((84, 150), (70, 124)), face=-1, look=-4, kind='wife'))
            out.append(notes(62, 120))
    elif kind in ('allow', 'payslip'):
        out.append(bed(20, 150, 100))
        out.append(lying(26, 136))
        out.append(person(146, ((140, 156), (112, 132)), face=-1, look=-10, kind='officer'))
        if kind == 'allow':
            out.append(envelope(98, 126, -10))
            out.append(paper(150, 166, 4, 12, 14, 2))
        else:
            # The pay slip: the hospital days at 0 (in its envelope).
            out.append(envelope(150, 166, 4))
            out.append(tag('paper') + f'<g transform="rotate(-8 108 132)"><rect x="96" y="118" width="24" height="28" rx="1" fill="{PAPER}" stroke="{INK}" stroke-width="0.6"/>'
                       f'<path d="M99 123 h18 M99 127 h12" stroke="{INK}" stroke-width="0.7"/>'
                       + glyphs(104, 131, '0', 10, RED) + '</g>')
    else:  # disease / wave
        out.append(drum(14, 160))
        out.append(person(140, ((132, 156), (104, 130) if kind == 'disease' else (116, 140)), face=-1, look=-6, kind='lineman'))
        out.append(cough(130, 134, -1))
        if kind == 'disease':
            out.append(person(62, ((50, 132), (92, 130)), face=1, look=4, gy=180, kind='officer'))
            out.append(paper(92, 122, -6))
        else:
            out.append(person(62, ((50, 132), (80, 106)), face=1, look=0, gy=180, kind='officer'))
            out.append(palm_out(80, 106))
            out.append(paper(110, 136, 8))
        out.append(desk(40, 140, 64))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 4 — steps: the first things after an accident.
# --------------------------------------------------------------------------

def steps_card(kind):
    out = card_open('yard')
    if kind in ('call', 'hide', 'late'):
        out.append(pole(32, 16))
        out.append(f'<path d="M0 30 L200 26" stroke="{WIRE}" stroke-width="1.2"/>')
    if kind == 'call':
        out.append(person(104, ((96, 150), (0, 0)), face=-1, look=-6, kind='lineman', bandage=('arm',), phone=True))
        out.append(f'<path d="M84 104 q-6 -6 0 -12 M78 106 q-10 -10 0 -20" stroke="{MOVE}" stroke-width="1.4" fill="none" stroke-linecap="round"/>')
    elif kind == 'late':
        out.append(calendar(124, 54, torn=4))
        out.append(person(100, ((92, 150), (0, 0)), face=-1, look=-6, kind='lineman', bandage=('arm',), phone=True))
    elif kind == 'hide':
        # The bandaged hand behind his back, the supervisor asking.
        out.append(person(116, ((128, 168), (108, 150)), face=-1, look=-4, kind='lineman', bandage=('hand',)))
        out.append(person(64, ((58, 150), (82, 132)), face=1, look=4, kind='super'))
    else:
        mark = {'govdoc': 'cross', 'codoc': 'bolt', 'shop': 'shop'}[kind]
        out.append(building(0, 112, 40, mark))
        if kind == 'shop':
            out.append(shelf(8, 72))
            out.append(desk(4, 140, 70))
        out.append(person(60 if kind != 'shop' else 40, ((50 if kind != 'shop' else 30, 150), (82 if kind != 'shop' else 62, 128)), face=1, look=6, kind='doctor'))
        out.append(paper(82 if kind != 'shop' else 62, 118, -8))
        out.append(person(140, ((132, 150), (118, 136)), face=-1, look=-4, kind='lineman', bandage=('arm',)))
    return card_close(out)


# --------------------------------------------------------------------------
# Round 5 — claim: the written notice, the papers, the commissioner.
# --------------------------------------------------------------------------

def claim_card(kind):
    out = card_open('yard')
    if kind in ('notice', 'guard'):
        out.append(gate(110))
        out.append(f'<rect x="0" y="70" width="110" height="{GY - 70}" fill="url(#bldg)"/>')
        out.append(letterbox(52, 104))
        if kind == 'notice':
            out.append(paper(56, 96, 0, 10, 12, 2))
            out.append(person(100, ((70, 112), (112, 140)), face=-1, look=-6, kind='lineman'))
            out.append(paper(108, 134, 10, 12, 15))
        else:
            out.append(person(150, ((144, 156), (130, 140)), face=-1, look=0, kind='guard'))
            out.append(person(96, ((88, 156), (116, 136)), face=1, look=4, kind='lineman'))
            out.append(f'<path d="M112 108 q6 -4 12 0 M110 102 q8 -7 16 0" stroke="{MOVE}" stroke-width="1.3" fill="none" stroke-linecap="round"/>')
    elif kind in ('file', 'bin'):
        out.append(house_wall())
        out.append(desk(60, 140, 80))
        out.append(paper(112, 124, 6, 12, 15))
        if kind == 'file':
            out.append(folder(90, 124))
            out.append(person(54, ((44, 150), (96, 128)), face=1, look=8, kind='lineman'))
        else:
            out.append(folder(90, 124, 0))
            out.append(dustbin(162, 168))
            out.append(paper(168, 150, 30, 12, 14, 2))
            out.append(person(140, ((132, 150), (166, 156)), face=1, look=12, kind='lineman'))
    else:  # labour / sign — an officer's desk
        out.append(f'<rect x="0" y="40" width="200" height="{GY - 40}" fill="url(#bldg)"/>')
        out.append(f'<rect x="20" y="58" width="40" height="34" fill="url(#glass)" stroke="{WOOD_D}" stroke-width="2"/>')
        out.append(person(60, ((50, 132), (92, 130)), face=1, look=4, gy=180, kind='officer'))
        out.append(desk(40, 140, 80))
        if kind == 'labour':
            out.append(folder(92, 122, -6))
            out.append(person(150, ((142, 156), (112, 132)), face=-1, look=-6, kind='lineman'))
        else:
            out.append(paper(96, 126, 80, 12, 16))
            out.append(pen(104, 134))
            out.append(person(150, ((142, 156), (108, 134)), face=-1, look=-20, kind='lineman'))
    return card_close(out)


CARDS = {}
for k in ('perm', 'contract', 'temp', 'clerk', 'tempno', 'notice'):
    CARDS[f'who_{k}'] = who_card(k)
for k in ('finger', 'eye', 'plaster', 'bed', 'burn'):
    CARDS[f'partial_{k}'] = partial_card(k)
for k in ('pay', 'allow', 'disease', 'wife', 'payslip', 'wave'):
    CARDS[f'rights_{k}'] = rights_card(k)
for k in ('call', 'govdoc', 'codoc', 'hide', 'late', 'shop'):
    CARDS[f'steps_{k}'] = steps_card(k)
for k in ('notice', 'file', 'labour', 'guard', 'bin', 'sign'):
    CARDS[f'claim_{k}'] = claim_card(k)

# Safe cards and traps per round (mirrors learn_board_pack72.dart).
ROUNDS = {
    'who': (['who_perm', 'who_contract', 'who_temp'], ['who_clerk', 'who_tempno', 'who_notice']),
    'partial': (['partial_finger', 'partial_eye'], ['partial_plaster', 'partial_bed', 'partial_burn']),
    'rights': (['rights_pay', 'rights_allow', 'rights_disease'], ['rights_wife', 'rights_payslip', 'rights_wave']),
    'steps': (['steps_call', 'steps_govdoc', 'steps_codoc'], ['steps_hide', 'steps_late', 'steps_shop']),
    'claim': (['claim_notice', 'claim_file', 'claim_labour'], ['claim_guard', 'claim_bin', 'claim_sign']),
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
