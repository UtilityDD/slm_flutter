"""Mistake-card art for lesson 7.4 কাজ 1 "সইয়ের আগে" (m7_ptw_sign.dart).

Writes small gradient SVGs (320 x 200) into assets/game/art/m7_ptw_sign/,
one per mistake. No Bangla text inside the SVGs (flutter_svg text support is
thin): only 'PTW', digits and drawn marks.

Run:  python -I tool/m7_ptw_sign_art.py .
"""
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_ptw_sign')

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">'
        '<defs>'
        '<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fdf8ec"/><stop offset="1" stop-color="#f1e6cc"/></linearGradient>'
        '<linearGradient id="sh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fffdf6"/><stop offset="1" stop-color="#f3ecda"/></linearGradient>'
        '<linearGradient id="sp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#4a6a8a"/><stop offset="1" stop-color="#2f4a63"/></linearGradient>'
        '<radialGradient id="rd" cx="0.4" cy="0.4" r="0.7"><stop offset="0" stop-color="#ff8a80"/><stop offset="1" stop-color="#c62828"/></radialGradient>'
        '</defs>'
        '<rect x="4" y="4" width="312" height="192" rx="12" fill="url(#bg)" stroke="#c48a2e" stroke-width="3"/>')
TAIL = '</svg>'

INK = '#1a3a8a'
CARBON = '#3a4a9a'


def scribble(x, y, w, color=INK):
    """A quick signature scribble from (x, y), w wide."""
    d = f'M{x},{y}'
    step = w / 6
    for i in range(6):
        x0 = x + i * step
        d += f' C{x0 + step * 0.2:.1f},{y - 10:.1f} {x0 + step * 0.8:.1f},{y - 10:.1f} {x0 + step:.1f},{y + (2 if i % 2 else -1):.1f}'
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="1.8" stroke-linecap="round"/>'


def sheet(x, y, *, number='4817', date='14/11/2026', time='09:40', issuer=True, receiver=True,
          blank_date=False, smudge=False, receiver_color=INK, label_color='#8a2a16', scale=1.0):
    """A PTW sheet at (x, y), 130 x 170 (times scale)."""
    s = scale
    g = [f'<g transform="translate({x},{y}) scale({s})">',
         '<rect x="0" y="0" width="130" height="170" rx="3" fill="url(#sh)" stroke="#9c8a6a" stroke-width="1.5"/>',
         '<rect x="0" y="0" width="130" height="14" fill="url(#sp)"/>',
         f'<text x="8" y="28" font-family="sans-serif" font-size="10" font-weight="bold" fill="{label_color}">PTW</text>',
         '<rect x="6" y="34" width="56" height="18" fill="none" stroke="#9c8a6a"/>',
         f'<text x="34" y="47" font-family="sans-serif" font-size="10" font-weight="bold" text-anchor="middle" fill="{INK}">{number}</text>',
         '<rect x="68" y="34" width="56" height="18" fill="none" stroke="#9c8a6a"/>',
         '<rect x="6" y="56" width="56" height="18" fill="none" stroke="#9c8a6a"/>']
    if not blank_date:
        g.append(f'<text x="34" y="69" font-family="sans-serif" font-size="8" font-weight="bold" text-anchor="middle" fill="{INK}">{date}</text>')
    g += ['<rect x="68" y="56" width="56" height="18" fill="none" stroke="#9c8a6a"/>',
          f'<text x="96" y="69" font-family="sans-serif" font-size="9" font-weight="bold" text-anchor="middle" fill="{INK}">{time}</text>',
          '<rect x="6" y="78" width="118" height="22" fill="none" stroke="#9c8a6a"/>']
    if issuer:
        g.append(scribble(52, 94, 62))
    for i in range(2):
        yy = 112 + i * 14
        if smudge and i == 1:
            g.append(f'<ellipse cx="50" cy="{yy - 3}" rx="34" ry="6" fill="#505a70" opacity="0.55"/>')
            g.append(f'<ellipse cx="80" cy="{yy - 2}" rx="22" ry="5" fill="#505a70" opacity="0.45"/>')
        else:
            g.append(f'<line x1="10" y1="{yy - 3}" x2="{110 - i * 18}" y2="{yy - 3}" stroke="#2a2018" stroke-width="2.4" stroke-linecap="round" opacity="0.7"/>')
        g.append(f'<line x1="6" y1="{yy + 2}" x2="124" y2="{yy + 2}" stroke="#cbbe9e"/>')
    g += ['<rect x="6" y="138" width="104" height="26" fill="none" stroke="#9c8a6a"/>',
          '<line x1="40" y1="157" x2="106" y2="157" stroke="#7a6a50" stroke-dasharray="3 3"/>']
    if receiver:
        g.append(scribble(44, 156, 56, receiver_color))
    g.append('</g>')
    return ''.join(g)


def cross(x, y, r=13):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#rd)" stroke="#fff" stroke-width="2"/>'
            f'<path d="M{x - 5},{y - 5} L{x + 5},{y + 5} M{x + 5},{y - 5} L{x - 5},{y + 5}" stroke="#fff" stroke-width="3" stroke-linecap="round"/>')


def ring(x, y, w, h):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="5" fill="none" stroke="#c62828" stroke-width="3"/>'


def pole_bolt(x, y):
    """A small pole with a lineman and a bolt (the deadly picture)."""
    return (f'<g transform="translate({x},{y})">'
            '<rect x="-4" y="0" width="8" height="120" fill="#8a8f94"/>'
            '<rect x="-36" y="10" width="72" height="5" fill="#5b6168"/>'
            '<line x1="-60" y1="6" x2="60" y2="6" stroke="#2a2a2a" stroke-width="2"/>'
            '<rect x="10" y="22" width="12" height="24" rx="4" fill="#2e6fb0"/>'
            '<circle cx="16" cy="16" r="6" fill="#c98e62"/>'
            '<path d="M10,13 a6,6 0 0 1 12,0 z" fill="#f2c230"/>'
            '<path d="M2,2 L12,14 L5,15 L15,28" fill="none" stroke="#ffd600" stroke-width="3"/>'
            '</g>')


def tear_line(x, y, w):
    return f'<line x1="{x}" y1="{y}" x2="{x + w}" y2="{y}" stroke="#7a6a50" stroke-width="2" stroke-dasharray="2 4"/>'


ART = {
    # Field copy taken with no issuer signature: the sheet, the empty box, a
    # crew on the line.
    'field_no_issuer.svg': sheet(26, 16, issuer=False) + ring(30, 94, 126, 30) + pole_bolt(240, 40),
    # Control-room copy with no issuer signature (two sheets, the back one
    # unsigned).
    'control_no_issuer.svg': sheet(30, 16, issuer=False, label_color='#5a3a16') + ring(34, 94, 126, 30) + sheet(170, 16) + cross(292, 34),
    # Two copies, two numbers.
    'copies_differ.svg': sheet(30, 16, number='4817') + sheet(170, 16, number='4871') + ring(34, 48, 64, 26) + ring(174, 48, 64, 26) + cross(160, 60),
    # A blank date box.
    'blank_box.svg': sheet(30, 16) + sheet(170, 16, blank_date=True) + ring(174, 70, 64, 26) + cross(292, 34),
    # A smudged condition signed anyway.
    'not_understood.svg': sheet(95, 16, smudge=True) + ring(99, 128, 126, 22) + cross(250, 140),
    # The signature did not come through on the lower copy.
    'carbon_missed.svg': sheet(30, 16) + sheet(170, 16, receiver=False) + ring(174, 152, 108, 32) + cross(292, 34),
    # The control-room copy torn off (it stays in the room).
    'wrong_tear.svg': sheet(60, 24) + tear_line(52, 20, 150) + cross(240, 60) + '<path d="M220,150 l30,-30 l8,8 l-30,30 z" fill="#d9c9a0" stroke="#9c8a6a"/>',
    # A sound permit sent back.
    'needless_back.svg': sheet(95, 30) + '<path d="M160,24 l0,-12 m-8,8 l8,-8 l8,8" fill="none" stroke="#2f4a63" stroke-width="4" stroke-linecap="round"/>' + cross(250, 60),
    # A correct box shown as faulty.
    'wrong_box.svg': sheet(95, 16) + ring(166, 48, 64, 26) + cross(250, 60),
    # Signing in a hurry for the coworker.
    'listened.svg': sheet(30, 16) + '<path d="M210,120 q30,-40 70,-20" fill="none" stroke="#c62828" stroke-width="4" stroke-dasharray="6 5"/>'
                    '<circle cx="250" cy="70" r="16" fill="#c98e62"/><rect x="236" y="88" width="28" height="44" rx="8" fill="#7a5a3a"/>' + cross(292, 34),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, body in ART.items():
        with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(HEAD + body + TAIL + '\n')
    keep = os.path.join(OUT, '.gitkeep')
    if os.path.exists(keep):
        os.remove(keep)
    print(f'wrote {len(ART)} SVGs to {OUT}')


if __name__ == '__main__':
    main()
