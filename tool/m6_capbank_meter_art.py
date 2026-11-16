"""Mistake-card art for lesson 6.7 কাজ 2 "মিটারে ব্যাংকের নাড়ি" (m6_capbank_meter).

Writes small gradient SVGs (320 x 200) into assets/game/art/m6_capbank_meter/:

  swollen.svg   a bulged can with an oil streak, its bank lever at ON
  weak.svg      a lever ON and two meters whose needles barely moved
  refit.svg     a fuse tube hanging open and a new fuse in a hand, crossed
  tag.svg       a sound bank (meters swung well) with a red tag on its lever
  reswitch.svg  a lever flicked OFF and ON again (the arrows), crossed
  touch.svg     a bare hand on a swollen can, a spark

Only labels a worker reads (ON / OFF, A, PF). Run:  python -I tool/m6_capbank_meter_art.py
"""
import math
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'game', 'art', 'm6_capbank_meter')

HEAD = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">
<defs>
<linearGradient id="can" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#d4dae2"/><stop offset="1" stop-color="#8e99a8"/></linearGradient>
<linearGradient id="pn" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#cdd3d9"/><stop offset="1" stop-color="#aeb6be"/></linearGradient>
<radialGradient id="fl" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#ffe28a"/><stop offset="1" stop-color="#ffe28a" stop-opacity="0"/></radialGradient>
</defs>
<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>
'''
TAIL = '</svg>\n'


def can(x, y, w, h, swollen=False):
    s = []
    if swollen:
        b = w * 0.22
        s.append(f'<path d="M{x},{y + 8} Q{x + w / 2},{y - 12} {x + w},{y + 8} Q{x + w + b},{y + h / 2} {x + w},{y + h} L{x},{y + h} Q{x - b},{y + h / 2} {x},{y + 8} Z" fill="url(#can)" stroke="#5a6474" stroke-width="1.5"/>')
        s.append(f'<path d="M{x + w * 0.62},{y + 12} Q{x + w * 0.78},{y + h / 2} {x + w * 0.7},{y + h} L{x + w * 0.58},{y + h} Q{x + w * 0.66},{y + h / 2} {x + w * 0.56},{y + 12} Z" fill="#5a3a12" opacity="0.8"/>')
        s.append(f'<ellipse cx="{x + w * 0.66}" cy="{y + h + 5}" rx="{w * 0.4}" ry="4" fill="#5a3a12" opacity="0.8"/>')
        top = y - 10
    else:
        s.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="5" fill="url(#can)" stroke="#5a6474" stroke-width="1.5"/>')
        top = y
    for f in (0.32, 0.68):
        bx = x + w * f
        s.append(f'<rect x="{bx - 5}" y="{top - 16}" width="10" height="16" rx="2" fill="#7a4a2a"/>')
    return '\n'.join(s)


def lever(cx, cy, on=True, tag=False):
    s = [f'<rect x="{cx - 18}" y="{cy - 28}" width="36" height="56" rx="5" fill="#2c3440"/>']
    ky = cy - 17 if on else cy + 17
    s.append(f'<line x1="{cx}" y1="{cy}" x2="{cx}" y2="{ky}" stroke="#d0d6dc" stroke-width="7" stroke-linecap="round"/>')
    s.append(f'<circle cx="{cx}" cy="{ky}" r="8" fill="#e8ecef"/>')
    s.append(f'<text x="{cx + 30}" y="{cy - 18}" font-family="sans-serif" font-size="10" font-weight="bold" text-anchor="middle" fill="#1b2230">ON</text>')
    s.append(f'<text x="{cx + 30}" y="{cy + 24}" font-family="sans-serif" font-size="10" font-weight="bold" text-anchor="middle" fill="#1b2230">OFF</text>')
    lamp = '#ff5a4e' if on else '#6a3a38'
    s.append(f'<circle cx="{cx}" cy="{cy - 40}" r="6" fill="{lamp}" stroke="#3a4048" stroke-width="2"/>')
    if tag:
        s.append(f'<line x1="{cx}" y1="{cy + 26}" x2="{cx}" y2="{cy + 34}" stroke="#3a3f48" stroke-width="1.5"/>')
        s.append(f'<rect x="{cx - 16}" y="{cy + 34}" width="32" height="34" rx="3" fill="#d7332a"/>')
        s.append(f'<rect x="{cx - 13}" y="{cy + 37}" width="26" height="28" rx="2" fill="none" stroke="#ffe0d8" stroke-width="1"/>')
    return '\n'.join(s)


def meter(cx, cy, r, label, f0, f1):
    s = [f'<rect x="{cx - r - 12}" y="{cy - r - 12}" width="{2 * r + 24}" height="{r + 30}" rx="6" fill="#26303d"/>',
         f'<rect x="{cx - r - 8}" y="{cy - r - 8}" width="{2 * r + 16}" height="{r + 22}" rx="4" fill="#f7f3e6"/>']
    a0, a1 = math.radians(200), math.radians(340)
    s.append(f'<path d="M{cx + r * math.cos(a0):.1f},{cy + r * math.sin(a0):.1f} A{r},{r} 0 0 1 {cx + r * math.cos(a1):.1f},{cy + r * math.sin(a1):.1f}" fill="none" stroke="#26303d" stroke-width="1.5"/>')
    for i in range(11):
        a = a0 + (a1 - a0) * i / 10
        l = 7 if i % 5 == 0 else 4
        s.append(f'<line x1="{cx + r * math.cos(a):.1f}" y1="{cy + r * math.sin(a):.1f}" x2="{cx + (r - l) * math.cos(a):.1f}" y2="{cy + (r - l) * math.sin(a):.1f}" stroke="#26303d" stroke-width="1.2"/>')
    for f, col, op in ((f0, '#c0392b', 0.35), (f1, '#c0392b', 1)):
        a = a0 + (a1 - a0) * f
        s.append(f'<line x1="{cx}" y1="{cy}" x2="{cx + (r - 4) * math.cos(a):.1f}" y2="{cy + (r - 4) * math.sin(a):.1f}" stroke="{col}" stroke-width="2.4" stroke-linecap="round" opacity="{op}"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="4" fill="#26303d"/>')
    s.append(f'<text x="{cx}" y="{cy - r * 0.35:.1f}" font-family="sans-serif" font-size="12" font-weight="bold" text-anchor="middle" fill="#8a2a16">{label}</text>')
    return '\n'.join(s)


def cross(x, y, r=16):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="#d7332a"/>'
            f'<line x1="{x - r * 0.45}" y1="{y - r * 0.45}" x2="{x + r * 0.45}" y2="{y + r * 0.45}" stroke="#fff" stroke-width="4" stroke-linecap="round"/>'
            f'<line x1="{x + r * 0.45}" y1="{y - r * 0.45}" x2="{x - r * 0.45}" y2="{y + r * 0.45}" stroke="#fff" stroke-width="4" stroke-linecap="round"/>')


def hand(x, y, s=1.0):
    return (f'<g transform="translate({x},{y}) scale({s})">'
            '<path d="M0,0 C-6,-10 -2,-26 6,-30 L10,-46 C11,-52 19,-52 19,-45 L18,-32 L22,-50 C23,-56 31,-55 30,-49 L27,-31 L32,-46 C34,-52 41,-50 40,-44 L35,-28 L40,-38 C43,-43 49,-40 47,-34 L38,-10 C34,0 24,8 12,8 Z" '
            'fill="#e7b48a" stroke="#9a6a44" stroke-width="1.5"/></g>')


def write(name, body):
    with open(os.path.join(OUT, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEAD + body + '\n' + TAIL)


def main():
    os.makedirs(OUT, exist_ok=True)
    # A swollen can, its bank switched ON.
    write('swollen.svg', '\n'.join([
        '<rect x="40" y="150" width="140" height="22" fill="#8c8a84"/>',
        can(56, 70, 40, 78, swollen=True), can(118, 70, 40, 78),
        lever(240, 96, on=True), cross(286, 40),
    ]))
    # The lever ON, the needles barely moved.
    write('weak.svg', '\n'.join([
        meter(80, 110, 50, 'A', 0.72, 0.69), meter(180, 110, 50, 'PF', 0.45, 0.49),
        lever(272, 104, on=True), cross(272, 40),
    ]))
    # A fuse tube hanging open; a new fuse in a hand, crossed.
    write('refit.svg', '\n'.join([
        '<line x1="40" y1="40" x2="150" y2="40" stroke="#c9a44a" stroke-width="3"/>',
        '<rect x="62" y="44" width="14" height="16" rx="3" fill="#7a4a2a"/>',
        '<rect x="62" y="130" width="14" height="16" rx="3" fill="#7a4a2a"/>',
        '<line x1="69" y1="130" x2="112" y2="86" stroke="#2c2f36" stroke-width="10" stroke-linecap="round"/>',
        '<line x1="112" y1="86" x2="124" y2="100" stroke="#b0b4ba" stroke-width="1.6"/>',
        '<rect x="196" y="78" width="12" height="54" rx="4" fill="#2c2f36"/>',
        hand(188, 150, 1.1), cross(270, 52),
    ]))
    # A bank whose meters swung well, tagged out.
    write('tag.svg', '\n'.join([
        meter(80, 110, 50, 'A', 0.72, 0.6), meter(180, 110, 50, 'PF', 0.45, 0.72),
        lever(272, 90, on=False, tag=True), cross(272, 30),
    ]))
    # OFF and ON again.
    write('reswitch.svg', '\n'.join([
        lever(110, 104, on=False), lever(200, 104, on=True),
        '<path d="M130,60 Q155,34 180,60" fill="none" stroke="#8a2a16" stroke-width="3"/>',
        '<path d="M180,60 l-10,-2 l6,-8 z" fill="#8a2a16"/>',
        '<path d="M180,150 Q155,176 130,150" fill="none" stroke="#8a2a16" stroke-width="3"/>',
        '<path d="M130,150 l10,2 l-6,8 z" fill="#8a2a16"/>',
        cross(280, 50),
    ]))
    # A bare hand on the swollen can, a spark.
    write('touch.svg', '\n'.join([
        '<rect x="70" y="160" width="140" height="22" fill="#8c8a84"/>',
        can(110, 70, 60, 88, swollen=True),
        '<circle cx="150" cy="104" r="34" fill="url(#fl)"/>',
        '<path d="M150,104 l-10,-14 l8,0 l-6,-14" fill="none" stroke="#3a8fd8" stroke-width="2.4"/>',
        '<path d="M150,104 l14,-8 l-2,8 l12,-6" fill="none" stroke="#3a8fd8" stroke-width="2.4"/>',
        hand(160, 132, 1.0), cross(270, 52),
    ]))


if __name__ == '__main__':
    main()
