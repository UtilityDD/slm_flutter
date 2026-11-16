"""Mistake-card art for lesson 6.9 কাজ 2 "নতুন লাইন জুড়ুন" (m6_pillar_newway).

Writes nine 320 x 200 gradient SVG cards into assets/game/art/m6_pillar_newway/:
  live_hands.svg    - a bare hand at a live dropper, the LT handle at ON, an arc flash
  lock_prove.svg    - the LT handle OFF with padlock and tag; the tester live-dead-live
  no_ppe.svg        - a bare hand and a gloved hand at a terminal (the bare one crossed)
  sfu_on.svg        - the spare way's SFU handle still at ON as a lug goes on (crossed)
  wrong_phase.svg   - crossed droppers: an R lug on the fuse unit fed from Y (crossed)
  neutral_wrong.svg - the N lug on a fuse unit (crossed), the neutral link beside it
  armour.svg        - the armour braid hanging / on the neutral link, the earth terminal
  loose_lug.svg     - a lug on its stud with a gap under the nut, glowing red-white hot
  door_open.svg     - a pillar left with its door open and a child near it
Only labels a worker reads (R, Y, B, N, LT, ON, OFF, 0 V); the tester's live reading is its lit lamp. Deletes only its own stale files.

Run:  python -I tool/m6_pillar_newway_art.py
"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_pillar_newway')

HEAD = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
    '  <defs>\n'
    '    <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#dfeaf2"/>'
    '<stop offset="1" stop-color="#fdf8ec"/></linearGradient>\n'
    '    <linearGradient id="box" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3b4640"/>'
    '<stop offset="1" stop-color="#28302c"/></linearGradient>\n'
    '    <linearGradient id="cu" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f2b27a"/>'
    '<stop offset="0.5" stop-color="#c77a3a"/><stop offset="1" stop-color="#8e5226"/></linearGradient>\n'
    '    <linearGradient id="grey" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#cbd2d8"/>'
    '<stop offset="1" stop-color="#9ea7af"/></linearGradient>\n'
    '    <radialGradient id="zap" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/>'
    '<stop offset="0.45" stop-color="#9ccfff"/><stop offset="1" stop-color="#508cff" stop-opacity="0"/></radialGradient>\n'
    '    <radialGradient id="hot" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/>'
    '<stop offset="0.4" stop-color="#ff5a3c"/><stop offset="1" stop-color="#ff2a00" stop-opacity="0"/></radialGradient>\n'
    '  </defs>\n'
    '  <rect x="4" y="4" width="312" height="192" rx="12" fill="url(#bg)" stroke="#c48a2e" stroke-width="3"/>\n'
)
TAIL = '</svg>\n'
MARK = {'R': '#d7332a', 'Y': '#e8b21c', 'B': '#2f66c8'}


def text(x, y, s, size=12, fill='#26303d'):
    return (f'  <text x="{x}" y="{y}" font-family="sans-serif" font-size="{size}" font-weight="bold" '
            f'text-anchor="middle" fill="{fill}">{s}</text>\n')


def cross(x, y, r=14):
    return (f'  <path d="M{x - r} {y - r} l{2 * r} {2 * r} M{x + r} {y - r} l{-2 * r} {2 * r}" stroke="#c0392b" '
            'stroke-width="6" stroke-linecap="round"/>\n')


def tick(x, y):
    return f'  <path d="M{x - 12} {y} l8 9 l16 -18" fill="none" stroke="#2e9e4f" stroke-width="6" stroke-linecap="round"/>\n'


def bars(x0=40, x1=290, y0=34, gap=18):
    s = ''
    for k, m in enumerate('RYB'):
        y = y0 + k * gap
        s += f'  <rect x="{x0}" y="{y - 4}" width="{x1 - x0}" height="8" rx="2" fill="url(#cu)"/>\n'
        s += f'  <rect x="{x0 - 24}" y="{y - 7}" width="18" height="14" rx="3" fill="#e3e0d6"/>\n'
        s += text(x0 - 15, y + 4, m, 10, MARK[m])
    return s


def stud(x, y):
    return (f'  <rect x="{x - 10}" y="{y - 7}" width="20" height="14" fill="#2a2f35"/>\n'
            f'  <circle cx="{x}" cy="{y}" r="5" fill="#bfc6cc"/>\n')


def lug(x, y, tag='', armour=False):
    s = ''
    if armour:
        s += f'  <rect x="{x - 4}" y="{y + 6}" width="8" height="40" rx="3" fill="#8c939a"/>\n'
        for k in range(6):
            s += f'  <line x1="{x - 4}" y1="{y + 10 + k * 6}" x2="{x + 4}" y2="{y + 13 + k * 6}" stroke="#5e656c" stroke-width="1.2"/>\n'
    else:
        s += f'  <rect x="{x - 5}" y="{y + 6}" width="10" height="40" rx="3" fill="#1e2126"/>\n'
        if tag:
            s += f'  <rect x="{x - 8}" y="{y + 12}" width="16" height="11" rx="2" fill="#f4f1e8"/>\n'
            s += text(x, y + 21, tag, 9, '#15181c')
    s += f'  <circle cx="{x}" cy="{y}" r="8" fill="url(#grey)"/>\n  <circle cx="{x}" cy="{y}" r="3" fill="#3a4048"/>\n'
    return s


def hand(x, y, glove=False, flip=False):
    """A hand reaching up-left (or up-right when flipped) from below."""
    col = '#e8b21c' if glove else '#e0a67a'
    edge = '#a97b10' if glove else '#b07a52'
    d = -1 if flip else 1
    return (f'  <path d="M{x} {y} q{-6 * d} -26 {4 * d} -40 l{8 * d} -12 q{6 * d} -4 {8 * d} 4 l{-4 * d} 14 '
            f'l{14 * d} -10 q{6 * d} -2 {6 * d} 6 l{-10 * d} 20 q{-2 * d} 18 {-6 * d} 30 z" fill="{col}" stroke="{edge}" stroke-width="2"/>\n'
            f'  <rect x="{x - 16 if not flip else x - 4}" y="{y}" width="22" height="30" rx="4" fill="{"#c99a1a" if glove else "#3b5b8c"}"/>\n')


def lt_box(x, y, on=True, locked=False):
    s = (f'  <rect x="{x}" y="{y}" width="70" height="86" rx="6" fill="url(#grey)" stroke="#59626b" stroke-width="2"/>\n'
         + text(x + 20, y + 20, 'LT', 12)
         + f'  <rect x="{x + 44}" y="{y + 26}" width="10" height="40" rx="4" fill="#2a2f35"/>\n'
         + text(x + 49, y + 20, 'ON', 8) + text(x + 49, y + 80, 'OFF', 8))
    ty = y + 32 if on else y + 60
    s += f'  <line x1="{x + 49}" y1="{y + 46}" x2="{x + 49}" y2="{ty}" stroke="#1b1e22" stroke-width="7" stroke-linecap="round"/>\n'
    s += f'  <circle cx="{x + 49}" cy="{ty}" r="7" fill="{"#d7332a" if on else "#2e9e4f"}"/>\n'
    if locked:
        s += (f'  <path d="M{x + 14} {y + 52} a6 6 0 0 1 12 0" fill="none" stroke="#6e757c" stroke-width="3"/>\n'
              f'  <rect x="{x + 11}" y="{y + 52}" width="18" height="14" rx="3" fill="#c0392b"/>\n'
              f'  <rect x="{x + 14}" y="{y + 66}" width="16" height="18" fill="#ffd34d" stroke="#c0392b" stroke-width="2"/>\n')
    return s


def write(name, body):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEAD + body + TAIL)


def main():
    os.makedirs(OUT, exist_ok=True)
    cards = {}

    # A bare hand at a live dropper; the LT handle still ON; the flash.
    b = bars()
    b += '  <path d="M150 56 L150 110 L176 150" fill="none" stroke="#c77a3a" stroke-width="5"/>\n'
    b += hand(196, 196)
    b += '  <circle cx="176" cy="146" r="34" fill="url(#zap)"/>\n'
    b += lt_box(236, 104, on=True)
    cards['live_hands.svg'] = b

    # The LT OFF, locked and tagged; the tester: live, 0 V, live.
    b = lt_box(24, 40, on=False, locked=True)
    for k, live in enumerate([True, False, True]):
        x = 140 + k * 58
        b += f'  <rect x="{x - 22}" y="70" width="44" height="66" rx="8" fill="#e8b21c" stroke="#a97b10" stroke-width="2"/>\n'
        b += f'  <rect x="{x - 16}" y="80" width="32" height="20" rx="3" fill="#1b232c"/>\n'
        if live:
            b += f'  <circle cx="{x}" cy="90" r="12" fill="#ff3b30" opacity="0.3"/>\n  <circle cx="{x}" cy="90" r="7" fill="#ff3b30"/>\n'
        else:
            b += text(x, 95, '0 V', 10, '#ffffff')
        b += f'  <line x1="{x}" y1="136" x2="{x}" y2="160" stroke="#26303d" stroke-width="3"/>\n'
        if k < 2:
            b += f'  <path d="M{x + 25} 104 l10 0 m-5 -5 l5 5 l-5 5" fill="none" stroke="#26303d" stroke-width="3"/>\n'
    cards['lock_prove.svg'] = b

    # A bare hand (crossed) and a gloved hand (ticked) at a terminal.
    b = '  <rect x="40" y="40" width="240" height="60" rx="6" fill="url(#box)"/>\n'
    b += stud(100, 70) + stud(220, 70)
    b += hand(116, 190) + cross(96, 140)
    b += hand(206, 190, glove=True, flip=True) + tick(232, 140)
    b += '  <rect x="196" y="112" width="46" height="14" rx="7" fill="#79b8d6" stroke="#26303d" stroke-width="2"/>\n'
    cards['no_ppe.svg'] = b

    # The SFU handle still ON as a lug goes on.
    b = '  <rect x="40" y="36" width="160" height="80" rx="6" fill="#1f2327"/>\n'
    for k in range(3):
        x = 70 + k * 50
        b += f'  <rect x="{x - 14}" y="46" width="28" height="56" rx="4" fill="#3a4048"/>\n' + stud(x, 120)
    b += '  <rect x="228" y="40" width="36" height="72" rx="5" fill="#2a2f35"/>\n'
    b += text(246, 56, 'ON', 10, '#e3e0d6') + text(246, 108, 'OFF', 10, '#e3e0d6')
    b += '  <line x1="246" y1="76" x2="246" y2="62" stroke="#d7332a" stroke-width="9" stroke-linecap="round"/>\n'
    b += lug(120, 146, 'Y') + cross(246, 140)
    cards['sfu_on.svg'] = b

    # Crossed droppers: the R lug on the fuse unit fed from Y.
    b = bars()
    b += '  <path d="M90 52 L90 84 L190 120 L190 136" fill="none" stroke="#c77a3a" stroke-width="5"/>\n'
    b += '  <path d="M190 70 L190 84 L90 120 L90 136" fill="none" stroke="#c77a3a" stroke-width="5"/>\n'
    b += '  <rect x="50" y="92" width="190" height="20" rx="3" fill="#2a3035" opacity="0.55"/>\n'
    b += stud(90, 146) + stud(190, 146)
    b += lug(90, 146, 'R') + cross(132, 168, 12)
    cards['wrong_phase.svg'] = b

    # The N lug on a fuse unit (crossed); the neutral link waiting.
    b = '  <rect x="30" y="40" width="120" height="60" rx="6" fill="#1f2327"/>\n'
    b += '  <rect x="72" y="48" width="36" height="44" rx="4" fill="#3a4048"/>\n' + stud(90, 108)
    b += lug(90, 108, 'N') + cross(90, 70)
    b += '  <rect x="180" y="96" width="110" height="18" rx="4" fill="#d6b552" stroke="#8a6a1e" stroke-width="2"/>\n'
    b += text(194, 110, 'N', 12) + stud(260, 105)
    b += '  <path d="M150 150 q60 30 104 -30" fill="none" stroke="#2e9e4f" stroke-width="4" stroke-dasharray="7 5"/>\n'
    cards['neutral_wrong.svg'] = b

    # The armour braid hanging free, or on the neutral link; the earth terminal.
    b = '  <rect x="30" y="50" width="110" height="18" rx="4" fill="#d6b552" stroke="#8a6a1e" stroke-width="2"/>\n'
    b += text(44, 64, 'N', 12) + stud(110, 59) + lug(110, 59, armour=True) + cross(110, 112)
    b += '  <rect x="180" y="46" width="110" height="26" rx="4" fill="#8c939a"/>\n'
    b += ('  <path d="M276 50 l0 8 M268 58 l16 0 M271 63 l10 0 M274 68 l4 0" stroke="#26303d" stroke-width="2.4" '
          'stroke-linecap="round"/>\n')
    b += stud(220, 59)
    b += lug(236, 128, armour=True)
    b += '  <path d="M236 120 q0 -30 -14 -50" fill="none" stroke="#2e9e4f" stroke-width="4" stroke-dasharray="7 5"/>\n'
    cards['armour.svg'] = b

    # A lug with a gap under its nut, glowing red-white hot.
    b = '  <rect x="60" y="60" width="200" height="90" rx="6" fill="url(#box)"/>\n'
    b += '  <circle cx="160" cy="104" r="62" fill="url(#hot)"/>\n'
    b += '  <rect x="146" y="98" width="28" height="18" fill="#2a2f35"/>\n'
    b += '  <circle cx="160" cy="104" r="12" fill="url(#grey)"/>\n'
    b += '  <path d="M150 84 l7 -4 h8 l7 4 v8 l-7 4 h-8 l-7 -4 z" fill="#d5dadf"/>\n'
    b += '  <line x1="160" y1="80" x2="160" y2="104" stroke="#59626b" stroke-width="3"/>\n'
    b += '  <rect x="155" y="116" width="10" height="40" rx="3" fill="#1e2126"/>\n'
    for x, y in [(118, 70), (204, 72), (120, 134), (206, 136)]:
        b += f'  <path d="M{x} {y} l6 -6 m-2 10 l8 -2" stroke="#ffd34d" stroke-width="2.5" stroke-linecap="round"/>\n'
    cards['loose_lug.svg'] = b

    # A pillar left open by a lane, a child near it.
    b = '  <rect x="4" y="150" width="312" height="46" fill="#9b9488"/>\n'
    b += '  <rect x="70" y="40" width="110" height="116" rx="6" fill="#55705f"/>\n'
    b += '  <rect x="80" y="50" width="90" height="96" fill="url(#box)"/>\n'
    for k in range(3):
        b += f'  <rect x="86" y="{58 + k * 12}" width="78" height="6" rx="2" fill="url(#cu)"/>\n'
    b += '  <path d="M70 44 L36 56 L36 150 L70 154 z" fill="#6f8a78" stroke="#3e5446" stroke-width="2"/>\n'
    b += ('  <circle cx="236" cy="96" r="12" fill="#e0a67a"/>\n'
          '  <rect x="224" y="108" width="24" height="30" rx="8" fill="#d7332a"/>\n'
          '  <line x1="230" y1="138" x2="228" y2="160" stroke="#3b5b8c" stroke-width="6" stroke-linecap="round"/>\n'
          '  <line x1="242" y1="138" x2="244" y2="160" stroke="#3b5b8c" stroke-width="6" stroke-linecap="round"/>\n'
          '  <line x1="224" y1="116" x2="198" y2="104" stroke="#e0a67a" stroke-width="6" stroke-linecap="round"/>\n')
    b += cross(282, 60)
    cards['door_open.svg'] = b

    for name, body in cards.items():
        write(name, body)
    for f in os.listdir(OUT):
        if f.endswith('.svg') and f not in cards:
            os.remove(os.path.join(OUT, f))
    print('wrote', len(cards), 'cards to', OUT)


if __name__ == '__main__':
    main()
