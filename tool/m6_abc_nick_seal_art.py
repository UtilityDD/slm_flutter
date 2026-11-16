"""Mistake-card art for lesson 6.6 কাজ 2 "কাটা আবরণ সিল করো" (m6_abc_nick_seal).

Writes four 320 x 200 gradient SVG cards into assets/game/art/m6_abc_nick_seal/:
  wrong_spot.svg  - the chalk on a bird dropping, the real nick further along
  uncovered.svg   - tape turns that stop short; water creeping into the open end
  tube_off.svg    - a shrunk tube sitting to one side of the nick
  bare_hands.svg  - a bare hand on the AB bundle, a shock flash
No text in the art. Deletes only its own stale files.

Run:  python -I tool/m6_abc_nick_seal_art.py
"""
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm6_abc_nick_seal')
NAMES = ['wrong_spot.svg', 'uncovered.svg', 'tube_off.svg', 'bare_hands.svg']

HEAD = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
    '  <defs>\n'
    '    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cfe3f3"/>'
    '<stop offset="1" stop-color="#fdf8ec"/></linearGradient>\n'
    '    <linearGradient id="cab" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#454a52"/>'
    '<stop offset="0.5" stop-color="#26292e"/><stop offset="1" stop-color="#16181b"/></linearGradient>\n'
    '    <radialGradient id="zap" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/>'
    '<stop offset="0.45" stop-color="#9ccfff"/><stop offset="1" stop-color="#508cff" stop-opacity="0"/></radialGradient>\n'
    '  </defs>\n'
    '  <rect x="4" y="4" width="312" height="192" rx="12" fill="url(#sky)" stroke="#c48a2e" stroke-width="3"/>\n'
)
TAIL = '</svg>\n'


def bundle(y=100):
    """The AB bundle across the card, with its twist strands."""
    s = f'  <rect x="14" y="{y - 14}" width="292" height="28" rx="14" fill="url(#cab)"/>\n'
    for x in range(22, 300, 14):
        s += f'  <line x1="{x - 5}" y1="{y - 12}" x2="{x + 5}" y2="{y + 12}" stroke="#555b63" stroke-width="2"/>\n'
    return s


def nick(x, y=100, w=34):
    return (
        f'  <path d="M{x - w / 2} {y - 2} L{x - w / 4} {y - 7} L{x} {y - 4} L{x + w / 4} {y - 8} L{x + w / 2} {y - 1} '
        f'L{x + w / 4} {y + 5} L{x - w / 4} {y + 4} Z" fill="#0e0f11"/>\n'
        f'  <ellipse cx="{x}" cy="{y}" rx="{w * 0.3}" ry="3" fill="#c9d1d8"/>\n'
    )


def chalk(x, y=118):
    return (
        f'  <path d="M{x} {y} l-8 14 M{x} {y} l8 14" stroke="#f7f3e3" stroke-width="4" stroke-linecap="round"/>\n'
    )


def cross(x, y):
    return (
        f'  <path d="M{x - 12} {y - 12} l24 24 M{x + 12} {y - 12} l-24 24" stroke="#c0392b" stroke-width="5" '
        'stroke-linecap="round"/>\n'
    )


def tape(x):
    return (
        f'  <rect x="{x - 6}" y="82" width="12" height="36" rx="2" fill="#151515" transform="rotate(-10 {x} 100)"/>\n'
        f'  <line x1="{x - 4}" y1="84" x2="{x - 4}" y2="116" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5" '
        f'transform="rotate(-10 {x} 100)"/>\n'
    )


def drops(x, y):
    s = ''
    for i, (dx, dy) in enumerate([(0, 0), (-10, 12), (9, 20)]):
        s += f'  <path d="M{x + dx} {y + dy} q-5 8 0 12 q5 -4 0 -12 Z" fill="#4d8fd6" fill-opacity="{0.9 - i * 0.15}"/>\n'
    return s


def wrong_spot():
    s = bundle()
    s += nick(232)
    # A bird dropping with the chalk under it.
    s += '  <ellipse cx="96" cy="94" rx="14" ry="8" fill="#f1f0ea"/>\n  <circle cx="100" cy="91" r="3" fill="#8c8c80"/>\n'
    s += chalk(96)
    s += cross(96, 160)
    return s


def uncovered():
    s = bundle()
    s += nick(170, w=46)
    for x in (128, 140, 152, 164):
        s += tape(x)
    s += drops(188, 60)
    s += '  <circle cx="186" cy="100" r="9" fill="#468cdc" fill-opacity="0.55"/>\n'
    return s


def tube_off():
    s = bundle()
    s += nick(186)
    s += '  <rect x="88" y="84" width="84" height="32" rx="16" fill="#111214" stroke="#8a9099" stroke-width="1.5"/>\n'
    s += '  <line x1="96" y1="90" x2="164" y2="90" stroke="#ffffff" stroke-opacity="0.3" stroke-width="2"/>\n'
    s += cross(186, 150)
    return s


def bare_hands():
    s = bundle(110)
    # A bare hand gripping the bundle.
    s += ('  <path d="M118 140 q-6 -30 6 -44 q8 -6 14 2 l4 14 q10 -6 16 2 l2 30 Z" fill="#e8b98f" '
          'stroke="#b07d52" stroke-width="2"/>\n')
    for x in (126, 136, 146):
        s += f'  <rect x="{x}" y="96" width="8" height="22" rx="4" fill="#e8b98f" stroke="#b07d52" stroke-width="1.5"/>\n'
    s += '  <circle cx="138" cy="104" r="44" fill="url(#zap)"/>\n'
    s += '  <path d="M200 40 l-14 26 h12 l-16 28" fill="none" stroke="#f4d03f" stroke-width="5" stroke-linejoin="round"/>\n'
    # The gloves left on the side.
    s += '  <path d="M246 150 q-4 -22 6 -28 l18 0 q8 6 4 28 Z" fill="#c0392b"/>\n'
    s += cross(258, 168)
    return s


def main():
    os.makedirs(OUT, exist_ok=True)
    art = {
        'wrong_spot.svg': wrong_spot(),
        'uncovered.svg': uncovered(),
        'tube_off.svg': tube_off(),
        'bare_hands.svg': bare_hands(),
    }
    assert set(art) == set(NAMES)
    for name, body in art.items():
        with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(HEAD + body + TAIL)
    for f in os.listdir(OUT):
        if f.endswith('.svg') and f not in NAMES:
            os.remove(os.path.join(OUT, f))
    keep = os.path.join(OUT, '.gitkeep')
    if os.path.exists(keep):
        os.remove(keep)
    print(f'wrote {len(art)} cards to {OUT}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
