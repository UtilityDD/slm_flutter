"""Mistake-card art for lesson 7.4 কাজ 2 "বৈধ PTW ছিল কি?" (m7_ptw_inquiry.dart).

Writes small gradient SVGs (320 x 200) into assets/game/art/m7_ptw_inquiry/,
one per mistake picture:
  stamp_gap.svg   'সব কাজ PTW-এর মধ্যে' on a breach (allInBefore / allInAfter)
  pin_valid.svg   a pin on a photo inside the permit window (pinValid)
  pin_nobody.svg  a pin on a photo with nobody up the pole (pinNobody)
  row_exists.svg  'লগবুকে নেই' while the row is in the book (rowExists)
  time_first.svg  a time verdict before the logbook row is found (timeFirst)
  listen.svg      the crew man's "PTW is only the supervisor's job" (listened)
No Bangla text inside the SVGs (flutter_svg text support is thin): only
'PTW', digits and drawn marks.

Run:  python -I tool/m7_ptw_inquiry_art.py .
"""
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
out = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_ptw_inquiry')
os.makedirs(out, exist_ok=True)
HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
DEFS = """<defs>
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2e3a4c"/><stop offset="1" stop-color="#4a5566"/></linearGradient>
<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6b4426"/><stop offset="1" stop-color="#4c2e18"/></linearGradient>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6fa8dc"/><stop offset="1" stop-color="#dce8ef"/></linearGradient>
<linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8c9a5b"/><stop offset="1" stop-color="#6a7444"/></linearGradient>
<linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9a9c98"/><stop offset="0.5" stop-color="#c9cac4"/><stop offset="1" stop-color="#8c8e8a"/></linearGradient>
<linearGradient id="page" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#f3eedf"/><stop offset="1" stop-color="#e9e1cb"/></linearGradient>
<linearGradient id="stamp" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1c2e4a"/><stop offset="1" stop-color="#0b1324"/></linearGradient>
<radialGradient id="pin" cx="0.4" cy="0.35" r="0.7"><stop offset="0" stop-color="#ff8a7a"/><stop offset="1" stop-color="#b8261b"/></radialGradient>
</defs>
<rect width="320" height="200" fill="url(#wall)"/>
<rect y="120" width="320" height="80" fill="url(#wood)"/>
"""


def photo(x, y, w, h, man=None, stamp=None):
    s = h / 100
    px = x + w * 0.45
    g = [
        f'<rect x="{x - 4}" y="{y - 4}" width="{w + 8}" height="{h + 8}" fill="#f4f1ea"/>',
        f'<rect x="{x}" y="{y}" width="{w}" height="{h * 0.72:.1f}" fill="url(#sky)"/>',
        f'<rect x="{x}" y="{y + h * 0.72:.1f}" width="{w}" height="{h * 0.28:.1f}" fill="url(#grass)"/>',
        f'<rect x="{px - 2.6 * s:.1f}" y="{y + 12 * s:.1f}" width="{5.2 * s:.1f}" height="{h * 0.72 - 6 * s:.1f}" fill="url(#pole)"/>',
        f'<line x1="{px - 22 * s:.1f}" y1="{y + 18 * s:.1f}" x2="{px + 22 * s:.1f}" y2="{y + 18 * s:.1f}" stroke="#4a4f57" stroke-width="{2.4 * s:.1f}"/>',
    ]
    for dx in (-19, 0, 19):
        ix = px + dx * s
        g.append(f'<path d="M{x} {y + 18 * s:.1f} Q{(x + ix) / 2:.1f} {y + 22 * s:.1f} {ix:.1f} {y + 13 * s:.1f} Q{(ix + x + w) / 2:.1f} {y + 22 * s:.1f} {x + w} {y + 18 * s:.1f}" fill="none" stroke="#2b2f35" stroke-width="1"/>')

    def figure(fx, fy, up=False):
        r = [
            f'<line x1="{fx - 2 * s:.1f}" y1="{fy:.1f}" x2="{fx - 1 * s:.1f}" y2="{fy - 7 * s:.1f}" stroke="#2f3a4f" stroke-width="{2.2 * s:.1f}" stroke-linecap="round"/>',
            f'<line x1="{fx + 2 * s:.1f}" y1="{fy:.1f}" x2="{fx + 1 * s:.1f}" y2="{fy - 7 * s:.1f}" stroke="#2f3a4f" stroke-width="{2.2 * s:.1f}" stroke-linecap="round"/>',
            f'<rect x="{fx - 3.25 * s:.1f}" y="{fy - 16 * s:.1f}" width="{6.5 * s:.1f}" height="{9 * s:.1f}" rx="{2 * s:.1f}" fill="#e07a1f"/>',
            f'<circle cx="{fx:.1f}" cy="{fy - 18 * s:.1f}" r="{2.6 * s:.1f}" fill="#8a5a3c"/>',
            f'<path d="M{fx - 3 * s:.1f} {fy - 19 * s:.1f} A{3 * s:.1f} {3 * s:.1f} 0 0 1 {fx + 3 * s:.1f} {fy - 19 * s:.1f} Z" fill="#f2c230"/>',
        ]
        if up:
            r.append(f'<line x1="{fx - 4 * s:.1f}" y1="{fy - 12 * s:.1f}" x2="{px + 3 * s:.1f}" y2="{fy - 13 * s:.1f}" stroke="#1c1c1c" stroke-width="{1.2 * s:.1f}"/>')
        return ''.join(r)

    gy = y + h * 0.86
    if man == 'up':
        g.append(figure(px - 5 * s, y + 42 * s, up=True))
        g.append(figure(px + 16 * s, gy))
    else:
        g.append(figure(px - 14 * s, gy))
        g.append(figure(px + 14 * s, gy))
    if stamp:
        g.append(f'<text x="{x + w - 5}" y="{y + h - 5}" text-anchor="end" font-family="sans-serif" font-weight="700" font-size="{max(9, 10 * s):.0f}" fill="#ff9a2e" stroke="#000" stroke-width="0.3">{stamp}</text>')
    return '\n'.join(g) + '\n'


def logbook(x, y, w, rows, clip=None):
    g = [
        f'<rect x="{x - 4}" y="{y - 4}" width="{w + 8}" height="{22 * len(rows) + 30}" rx="5" fill="#6e1f1a"/>',
        f'<rect x="{x}" y="{y}" width="{w}" height="{22 * len(rows) + 22}" fill="url(#page)"/>',
        f'<line x1="{x + 4}" y1="{y + 18}" x2="{x + w - 4}" y2="{y + 18}" stroke="#6e1f1a" stroke-width="1.2"/>',
    ]
    for i, r in enumerate(rows):
        ry = y + 22 + i * 22
        if clip == i:
            g.append(f'<rect x="{x + 2}" y="{ry}" width="{w - 4}" height="21" fill="#f7d55a" fill-opacity="0.45"/>')
        g.append(f'<line x1="{x + 4}" y1="{ry + 21}" x2="{x + w - 4}" y2="{ry + 21}" stroke="#3a6ea8" stroke-opacity="0.35"/>')
        for j, t in enumerate(r):
            g.append(f'<text x="{x + 14 + j * (w - 20) / len(r):.0f}" y="{ry + 15}" font-family="sans-serif" font-weight="700" font-size="11" fill="#1e2a44">{t}</text>')
        if clip == i:
            g.append(f'<rect x="{x - 3}" y="{ry + 2}" width="9" height="18" rx="4.5" fill="none" stroke="#8e98a6" stroke-width="2.2"/>')
    return '\n'.join(g) + '\n'


def stamp_box(x, y, w, h, icon):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="url(#stamp)" stroke="#f2c14e" stroke-width="2"/>\n'
            f'<g transform="translate({x + w / 2 - 12},{y + h / 2 - 12})">{icon}</g>\n')


def cross_at(x, y):
    return (f'<g transform="translate({x},{y})"><g stroke="#e5483c" stroke-width="9" stroke-linecap="round">'
            '<line x1="0" y1="0" x2="34" y2="34"/><line x1="34" y1="0" x2="0" y2="34"/></g></g>\n')


TICK = '<path d="M3 13 L10 20 L22 5" fill="none" stroke="#f2c14e" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
BOOK = '<path d="M2 4 h9 a3 3 0 0 1 3 3 v15 a3 3 0 0 0 -3 -3 h-9 z M22 4 h-9 a3 3 0 0 0 -3 3 v15 a3 3 0 0 1 3 -3 h9 z" fill="#f2c14e"/>'


def pin(x, y):
    return f'<circle cx="{x}" cy="{y}" r="9" fill="url(#pin)"/><line x1="{x}" y1="{y + 8}" x2="{x + 5}" y2="{y + 22}" stroke="#8e98a6" stroke-width="2.4"/>\n'


FOLDER = ('<rect x="40" y="30" width="150" height="70" rx="6" fill="#e8c98a"/><rect x="52" y="24" width="60" height="10" rx="3" fill="#d9b26a"/>\n'
          '<text x="56" y="62" font-family="sans-serif" font-weight="800" font-size="16" fill="#2a1e10">14/03</text>\n')
SHRUG = """<g transform="translate(110,30)">
<path d="M10 150 Q10 92 50 86 Q90 92 90 150 Z" fill="#b8682c"/>
<circle cx="50" cy="62" r="24" fill="#8a5a3c"/>
<path d="M26 58 A24 24 0 0 1 74 58 Z" fill="#1e1a18"/>
<path d="M14 104 L-8 84 L-14 70" fill="none" stroke="#8a5a3c" stroke-width="9" stroke-linecap="round"/>
<path d="M86 104 L108 84 L114 70" fill="none" stroke="#8a5a3c" stroke-width="9" stroke-linecap="round"/>
<path d="M40 74 Q50 70 60 74" fill="none" stroke="#3a2010" stroke-width="2.4" stroke-linecap="round"/>
</g>
<g transform="translate(22,128)"><rect width="74" height="50" fill="#f7f1e1"/><rect width="74" height="11" fill="#c9483b"/><text x="37" y="38" text-anchor="middle" font-family="sans-serif" font-weight="900" font-size="15" fill="#14284a">PTW</text></g>
"""
CLOSED_BOOK = ('<g transform="translate(206,40)">'
               '<rect x="-4" y="-4" width="100" height="134" rx="6" fill="#4c1512"/>'
               '<rect width="92" height="126" rx="5" fill="#6e1f1a"/>'
               '<rect x="8" y="0" width="5" height="126" fill="#521512"/>'
               '<rect x="20" y="24" width="60" height="26" rx="4" fill="#f3eedf"/>'
               '<text x="50" y="43" text-anchor="middle" font-family="sans-serif" font-weight="900" font-size="16" fill="#6e1f1a">PTW</text>'
               '<circle cx="50" cy="90" r="20" fill="#f2c14e" stroke="#fff6d8" stroke-width="2"/>'
               '<text x="50" y="99" text-anchor="middle" font-family="sans-serif" font-weight="900" font-size="26" fill="#14284a">1</text>'
               '</g>')
files = {
    # The stamp 'all inside the permit' over a photo of a man up before the issue.
    'stamp_gap.svg': photo(18, 18, 170, 110, man='up', stamp='09:41') + logbook(200, 134, 108, [['10:05', '12:40']]) + stamp_box(214, 30, 86, 60, TICK) + cross_at(240, 42),
    # A pin on a photo inside the window (the clipped row's times round it).
    'pin_valid.svg': photo(18, 18, 170, 110, man='up', stamp='11:12') + pin(150, 26) + logbook(200, 134, 108, [['10:05', '12:40']], clip=0) + cross_at(232, 50),
    # A pin on a photo with nobody up the pole.
    'pin_nobody.svg': photo(18, 18, 170, 110, stamp='13:02') + pin(150, 26) + cross_at(232, 50),
    # 'Not in the logbook' while the row is on the page.
    'row_exists.svg': FOLDER + logbook(16, 128, 200, [['14/03', '4417'], ['15/03', '4147']], clip=0) + stamp_box(228, 30, 80, 60, BOOK) + cross_at(251, 43),
    # A time verdict before the row is found: the photo pinned, the logbook
    # still shut ('PTW' on its cover, a big 1: the book first).
    'time_first.svg': photo(18, 18, 170, 110, man='up', stamp='10:20') + pin(150, 26) + CLOSED_BOOK + cross_at(118, 56),
    # The crew man who says the PTW is only the supervisor's job: a shrug.
    'listen.svg': SHRUG + cross_at(250, 40),
}
for name, body in files.items():
    with open(os.path.join(out, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEAD + DEFS + body + '</svg>\n')
print(sorted(files))
