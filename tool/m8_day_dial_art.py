#!/usr/bin/env python3
"""Mistake pictures of lesson 8.7 "দিনভর নজর" (m8_day_dial.dart).

Eight SVG cards, 320 x 200, the mistake on the left and the right way on the
right (no text: shapes only). Run from the repo root:

    python -I tool/m8_day_dial_art.py

Writes assets/game/art/m8_day_dial/*.svg (UTF-8, LF).
"""
import os

OUT = os.path.join('assets', 'game', 'art', 'm8_day_dial')

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
        '<defs>\n'
        '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cfe6f5"/><stop offset="1" stop-color="#fff4d6"/></linearGradient>\n'
        '<linearGradient id="night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#111b3e"/><stop offset="1" stop-color="#34437a"/></linearGradient>\n'
        '<linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e9884e"/><stop offset="1" stop-color="#ffc27a"/></linearGradient>\n'
        '<linearGradient id="gnd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b9a887"/><stop offset="1" stop-color="#9c9488"/></linearGradient>\n'
        '</defs>\n'
        '<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>\n'
        '<line x1="160" y1="16" x2="160" y2="184" stroke="#e1d4b8" stroke-width="2" stroke-dasharray="5 4"/>\n')

CROSS = ('<circle cx="{x}" cy="{y}" r="13" fill="#c62828"/>'
         '<path d="M{a} {b} L{c} {d} M{c} {b} L{a} {d}" stroke="#fff" stroke-width="3.4" stroke-linecap="round"/>')
TICK = ('<circle cx="{x}" cy="{y}" r="13" fill="#2e8b57"/>'
        '<path d="M{a} {y} L{m} {d} L{c} {b}" stroke="#fff" stroke-width="3.4" stroke-linecap="round" fill="none"/>')


def cross(x, y):
    return CROSS.format(x=x, y=y, a=x - 5, b=y - 5, c=x + 5, d=y + 5)


def tick(x, y):
    return TICK.format(x=x, y=y, a=x - 6, m=x - 2, c=x + 6, b=y - 5, d=y + 5)


def panel(ox, sky='sky', ground=True):
    """A 136 x 150 picture window at x offset ox."""
    s = f'<rect x="{ox}" y="16" width="136" height="150" rx="6" fill="url(#{sky})"/>'
    if ground:
        s += f'<rect x="{ox}" y="140" width="136" height="26" fill="url(#gnd)"/>'
    return s


def house(ox, shop_fridge=False, lit=False):
    s = f'<rect x="{ox+22}" y="86" width="92" height="56" fill="#e8d9b8"/>'
    s += f'<path d="M{ox+16} 88 L{ox+68} 62 L{ox+120} 88 Z" fill="#a5503a"/>'
    # front room
    if shop_fridge:
        s += f'<rect x="{ox+30}" y="100" width="40" height="42" fill="#e9ddb8" stroke="#6a5a48" stroke-width="2"/>'
        s += f'<rect x="{ox+48}" y="106" width="16" height="30" rx="2" fill="#e9f6ff" stroke="#59626a" stroke-width="1.5"/>'
        for i, c in enumerate(['#d94b3d', '#3fa55b', '#e8a92a']):
            s += f'<rect x="{ox+50}" y="{109+i*9}" width="12" height="6" rx="1.5" fill="{c}"/>'
        s += f'<rect x="{ox+30}" y="128" width="20" height="8" fill="#8a5e34"/>'
    else:
        s += f'<rect x="{ox+30}" y="100" width="40" height="42" fill="#9a7b52" stroke="#6a5a48" stroke-width="2"/>'
    s += f'<rect x="{ox+80}" y="102" width="26" height="22" fill="{"#ffe8a8" if lit else "#8db4c9"}" stroke="#6a5a48" stroke-width="2"/>'
    return s


def meter(ox, y=96):
    return (f'<rect x="{ox+112}" y="{y}" width="14" height="22" rx="2" fill="#dde2e6" stroke="#5b6168" stroke-width="1.4"/>'
            f'<rect x="{ox+115}" y="{y+4}" width="8" height="7" fill="#1e2a33"/>')


def book(ox, y, mark, kind):
    """A reading-book line with a stamp mark (kind: 'a' blue, 'b' brown, 'c' green)."""
    col = {'a': '#2e6f9a', 'b': '#b5523a', 'c': '#3f8a4c'}[kind]
    s = f'<rect x="{ox+10}" y="{y}" width="116" height="26" rx="4" fill="#f7f1de" stroke="#8a6a3c" stroke-width="1.6"/>'
    s += f'<rect x="{ox+16}" y="{y+5}" width="40" height="16" rx="3" fill="none" stroke="{col}" stroke-width="2.4"/>'
    if mark == 'bad':
        s += f'<path d="M{ox+64} {y+13} L{ox+118} {y+13}" stroke="#c62828" stroke-width="3" stroke-linecap="round" stroke-dasharray="7 4"/>'
    else:
        s += f'<path d="M{ox+64} {y+13} L{ox+118} {y+13}" stroke="#3a2a16" stroke-opacity="0.35" stroke-width="2" stroke-linecap="round"/>'
    return s


def shop(ox, open_=True):
    s = f'<rect x="{ox+16}" y="82" width="104" height="60" fill="#d9c9a8"/><rect x="{ox+12}" y="76" width="112" height="9" fill="#8d7b68"/>'
    for i in range(6):
        s += f'<rect x="{ox+20+i*16}" y="86" width="16" height="10" fill="{"#c0392b" if i % 2 == 0 else "#f1e8da"}"/>'
    s += f'<rect x="{ox+26}" y="100" width="84" height="42" fill="{"#eadfc0" if open_ else "#9aa3aa"}" stroke="#6a5a48" stroke-width="2"/>'
    if open_:
        s += f'<rect x="{ox+78}" y="104" width="22" height="34" rx="2" fill="#e9f6ff" stroke="#59626a" stroke-width="1.5"/>'
        s += f'<rect x="{ox+30}" y="124" width="40" height="10" fill="#8a5e34"/>'
    return s


def pump(ox, car=False, wet=True):
    s = f'<rect x="{ox+66}" y="118" width="64" height="22" fill="{"#6b7e3e" if wet else "#a99b5a"}"/>'
    s += f'<rect x="{ox+14}" y="104" width="50" height="38" fill="#b5603f"/>'
    s += f'<path d="M{ox+8} 106 L{ox+39} 88 L{ox+70} 106 Z" fill="#8e959b"/>'
    s += f'<rect x="{ox+24}" y="116" width="26" height="26" fill="#2c2f34"/><rect x="{ox+28}" y="126" width="18" height="12" rx="3" fill="#2e6f9a"/>'
    if wet and not car:
        for i in range(3):
            s += f'<path d="M{ox+78+i*18} 116 Q{ox+86+i*18} 102 {ox+92+i*18} 118" stroke="#8fd0ff" stroke-width="2.4" fill="none"/>'
    if car:
        s += f'<rect x="{ox+70}" y="112" width="56" height="22" rx="6" fill="#b03a48"/><rect x="{ox+82}" y="102" width="32" height="14" rx="5" fill="#9e2f3c"/>'
        s += f'<circle cx="{ox+84}" cy="136" r="7" fill="#22262b"/><circle cx="{ox+114}" cy="136" r="7" fill="#22262b"/>'
        for x, y in [(88, 108), (100, 104), (110, 110)]:
            s += f'<circle cx="{ox+x}" cy="{y}" r="5" fill="#fff" fill-opacity="0.9"/>'
        s += f'<path d="M{ox+60} 134 C{ox+66} 150 {ox+68} 118 {ox+78} 116" stroke="#2f8f57" stroke-width="3" fill="none"/>'
    return s


def card(ox, mark_ok, bad=False):
    return ''


def write(name, body):
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEAD + body + '</svg>\n')


def main():
    L, R = 12, 172
    # --- needless note on an honest premises ---------------------------------
    for name, draw, kind_ok in [('needless_house.svg', lambda ox: house(ox, lit=True), 'a'),
                                ('needless_shop.svg', lambda ox: shop(ox, True), 'b'),
                                ('needless_pump.svg', lambda ox: pump(ox, wet=True), 'c')]:
        b = panel(L) + draw(L) + meter(L) + book(L, 140, 'bad', kind_ok if kind_ok != 'a' else 'b') + cross(L + 118, 40)
        b += panel(R) + draw(R) + meter(R) + book(R, 140, 'ok', kind_ok) + tick(R + 118, 40)
        write(name, b)
    # --- the card's category stamped on a misuse -----------------------------
    b = panel(L) + house(L, shop_fridge=True, lit=True) + meter(L) + book(L, 140, 'ok', 'a') + cross(L + 118, 40)
    b += panel(R) + house(R, shop_fridge=True, lit=True) + meter(R) + book(R, 140, 'bad', 'b') + tick(R + 118, 40)
    write('missed_fridge.svg', b)
    b = panel(L) + pump(L, car=True) + meter(L) + book(L, 140, 'ok', 'c') + cross(L + 118, 40)
    b += panel(R) + pump(R, car=True) + meter(R) + book(R, 140, 'bad', 'b') + tick(R + 118, 40)
    write('missed_car.svg', b)

    # --- the factory's bracket: evening (wrong) vs midnight (right) ----------
    def dial(ox, sky, machine_x):
        s = panel(ox, sky=sky, ground=False)
        s += f'<path d="M{ox+10} 100 A58 70 0 0 1 {ox+126} 100" stroke="#ffffff" stroke-opacity="0.75" stroke-width="2" stroke-dasharray="3 5" fill="none"/>'
        # the bracket
        s += f'<path d="M{machine_x-20} 62 A58 70 0 0 1 {machine_x+14} 90" stroke="#1a2438" stroke-width="11" stroke-linecap="round" fill="none"/>'
        s += f'<path d="M{machine_x-20} 62 A58 70 0 0 1 {machine_x+14} 90" stroke="#f2b431" stroke-width="7" stroke-linecap="round" fill="none"/>'
        # shed and machine
        s += f'<rect x="{ox+16}" y="118" width="104" height="38" fill="#a7afb5"/><rect x="{ox+26}" y="126" width="84" height="30" fill="#2a2e33"/>'
        s += f'<circle cx="{ox+84}" cy="141" r="12" fill="#8c969e" stroke="#1b1f23" stroke-width="2"/>'
        return s
    b = dial(L, 'dusk', L + 96) + f'<circle cx="{L+98}" cy="88" r="9" fill="#ffd84a"/>' + cross(L + 118, 40)
    b += dial(R, 'night', R + 88) + f'<circle cx="{R+112}" cy="94" r="8" fill="#f1f1e4"/><circle cx="{R+116}" cy="92" r="7" fill="#34437a"/>' + tick(R + 118, 40)
    write('bracket_evening.svg', b)

    # --- PF penalty: a wrong piece of advice vs the capacitor bank -----------
    def bill(ox):
        s = f'<rect x="{ox+24}" y="24" width="88" height="86" rx="5" fill="#f7f1de" stroke="#8a6a3c" stroke-width="2"/>'
        for i in range(2):
            s += f'<rect x="{ox+32}" y="{36+i*16}" width="50" height="5" rx="2" fill="#3a2a16" fill-opacity="0.45"/><rect x="{ox+90}" y="{36+i*16}" width="14" height="5" rx="2" fill="#3a2a16" fill-opacity="0.35"/>'
        s += f'<rect x="{ox+32}" y="70" width="50" height="6" rx="2" fill="#c62828"/><rect x="{ox+90}" y="70" width="14" height="6" rx="2" fill="#c62828"/>'
        return s
    b = panel(L, ground=False) + bill(L)
    # a meter being swapped (wrong advice)
    b += f'<rect x="{L+42}" y="116" width="52" height="38" rx="5" fill="#dde2e6" stroke="#5b6168" stroke-width="2"/><rect x="{L+50}" y="124" width="36" height="14" fill="#1e2a33"/>'
    b += f'<path d="M{L+100} 122 l10 0 l-5 -8 M{L+110} 122 l-5 8" stroke="#c62828" stroke-width="3" fill="none"/>' + cross(L + 118, 40)
    b += panel(R, ground=False) + bill(R)
    # the capacitor bank: three cans with a tick
    for i in range(3):
        b += f'<rect x="{R+30+i*28}" y="118" width="20" height="36" rx="4" fill="#2e6f9a" stroke="#1b4764" stroke-width="2"/><rect x="{R+36+i*28}" y="112" width="8" height="6" fill="#8c969e"/>'
    b += tick(R + 118, 40)
    write('pf_wrong.svg', b)

    # --- the coworker: skipping the code vs checking it -----------------------
    b = panel(L) + house(L) + meter(L)
    b += f'<circle cx="{L+30}" cy="86" r="9" fill="#c98e62"/><rect x="{L+22}" y="94" width="16" height="30" rx="5" fill="#c0583a"/><path d="M{L+38} 100 l22 -16" stroke="#c98e62" stroke-width="5" stroke-linecap="round"/>' + cross(L + 118, 40)
    b += panel(R) + house(R) + meter(R)
    # a card under a magnifier
    b += f'<rect x="{R+84}" y="64" width="40" height="26" rx="4" fill="#f7f1de" stroke="#6a5232" stroke-width="2"/><rect x="{R+90}" y="72" width="28" height="4" fill="#2a2018" fill-opacity="0.6"/><rect x="{R+90}" y="80" width="20" height="4" fill="#2a2018" fill-opacity="0.6"/>'
    b += f'<circle cx="{R+104}" cy="78" r="16" fill="#cfe6f5" fill-opacity="0.55" stroke="#3a4660" stroke-width="3"/><path d="M{R+116} 90 l12 12" stroke="#3a4660" stroke-width="4" stroke-linecap="round"/>' + tick(R + 118, 40)
    write('push_listen.svg', b)


if __name__ == '__main__':
    main()
