"""Mistake pictures of m7_report_note (lesson 7.7 do 2, 'সৎ রিপোর্ট').

Each is 320 x 200: the wrong way on the left, the right way on the right, no
Bangla text (only digits and shapes). Deletes only its own stale files.

    python -I tool/m7_report_note_art.py .
"""
import os
import sys

OUT = 'assets/game/art/m7_report_note'

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">'
FRAME = ('<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>'
         '<line x1="160" y1="16" x2="160" y2="184" stroke="#e1d4b8" stroke-width="2" stroke-dasharray="5 4"/>')
BAD = '<g transform="translate(116 14)"><circle r="10" fill="#d9503a"/><path d="M-5 -5 L5 5 M5 -5 L-5 5" stroke="#fff" stroke-width="3"/></g>'
GOOD = '<g transform="translate(276 14)"><circle r="10" fill="#2e8b57"/><path d="M-5 0 L-1 5 L6 -5" stroke="#fff" stroke-width="3" fill="none"/></g>'


def text(x, y, s, size=14, fill='#2a2018', anchor='middle'):
    return ('<text x="%s" y="%s" font-family="sans-serif" font-size="%s" font-weight="bold" '
            'text-anchor="%s" fill="%s">%s</text>' % (x, y, size, anchor, fill, s))


def clock(cx, cy, r, h, m, hand='#b02a1e'):
    import math
    ha = (h % 12 + m / 60) / 12 * 2 * math.pi
    ma = m / 60 * 2 * math.pi
    return ('<circle cx="%s" cy="%s" r="%s" fill="#fffbef" stroke="#3a2a16" stroke-width="4"/>' % (cx, cy, r)
            + '<line x1="%s" y1="%s" x2="%.1f" y2="%.1f" stroke="#1b1b1b" stroke-width="5" stroke-linecap="round"/>'
            % (cx, cy, cx + math.sin(ha) * r * 0.5, cy - math.cos(ha) * r * 0.5)
            + '<line x1="%s" y1="%s" x2="%.1f" y2="%.1f" stroke="%s" stroke-width="3.5" stroke-linecap="round"/>'
            % (cx, cy, cx + math.sin(ma) * r * 0.78, cy - math.cos(ma) * r * 0.78, hand))


def person(x, y, vest='#ff7a1a'):
    return ('<circle cx="%s" cy="%s" r="9" fill="#e0a87c"/>' % (x, y - 30)
            + '<path d="M%s %s a10 10 0 0 1 20 0z" fill="#ffd21e"/>' % (x - 10, y - 32)
            + '<rect x="%s" y="%s" width="20" height="26" rx="5" fill="%s"/>' % (x - 10, y - 21, vest)
            + '<rect x="%s" y="%s" width="7" height="22" fill="#2f3e5c"/><rect x="%s" y="%s" width="7" height="22" fill="#2f3e5c"/>'
            % (x - 9, y + 5, x + 2, y + 5))


def card(x, y, ok):
    c = '#1f3f8f' if ok else '#8a7a5a'
    return ('<rect x="%s" y="%s" width="52" height="64" rx="5" fill="#fffcf2" stroke="%s" stroke-width="3"/>' % (x, y, c)
            + '<rect x="%s" y="%s" width="14" height="12" rx="2" fill="#e6b891"/>' % (x + 6, y + 6)
            + '<rect x="%s" y="%s" width="36" height="4" fill="#9a8a6a"/><rect x="%s" y="%s" width="28" height="4" fill="#9a8a6a"/>' % (x + 6, y + 26, x + 6, y + 36)
            + '<rect x="%s" y="%s" width="32" height="4" fill="#bdae8c"/>' % (x + 6, y + 46))


def draft(x, y, struck):
    s = ''.join('<rect x="%s" y="%s" width="%s" height="5" fill="#8a7a5a"/>' % (x + 10, y + 16 + i * 14, 80 - (i % 2) * 14) for i in range(4))
    out = '<rect x="%s" y="%s" width="100" height="84" rx="6" fill="#fffcf2" stroke="#b59a6c" stroke-width="2.5"/>' % (x, y) + s
    if struck:
        out += ''.join('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#b02a1e" stroke-width="3.5"/>' % (x + 8, y + 18 + i * 14, x + 92, y + 18 + i * 14) for i in range(4))
    return out


def still(x, y, k, ok):
    c = '#3a2a16'
    out = '<rect x="%s" y="%s" width="34" height="48" rx="3" fill="#cfe6f2" stroke="%s" stroke-width="2.5"/>' % (x, y, c)
    out += '<rect x="%s" y="%s" width="34" height="8" fill="#7c8b5c"/>' % (x, y + 40)
    if k == 0:
        out += '<rect x="%s" y="%s" width="3" height="40" fill="#9da1a5"/><path d="M%s %s l5 -6 l-3 -2 l6 -7" stroke="#f2c21e" stroke-width="3" fill="none"/>' % (x + 20, y + 4, x + 14, y + 22)
    elif k == 1:
        out += '<rect x="%s" y="%s" width="9" height="16" fill="#5e7c5a"/><circle cx="%s" cy="%s" r="8" fill="#ffd36a"/>' % (x + 20, y + 26, x + 14, y + 26)
    else:
        out += '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#c98a33" stroke-width="3"/><circle cx="%s" cy="%s" r="5" fill="#ff7a1a"/>' % (x + 6, y + 40, x + 28, y + 14, x + 12, y + 32)
    return out


def body(cx, cy, marks):
    out = ('<circle cx="%s" cy="%s" r="9" fill="#e6b891"/>' % (cx, cy - 34)
           + '<rect x="%s" y="%s" width="26" height="36" rx="6" fill="#ff9a3c"/>' % (cx - 13, cy - 24)
           + '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#3b4c6e" stroke-width="9"/>' % (cx - 6, cy + 12, cx - 10, cy + 44)
           + '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#3b4c6e" stroke-width="9"/>' % (cx + 6, cy + 12, cx + 10, cy + 44)
           + '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#ff9a3c" stroke-width="7"/>' % (cx - 13, cy - 20, cx - 28, cy + 8)
           + '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#ff9a3c" stroke-width="7"/>' % (cx + 13, cy - 20, cx + 28, cy + 8))
    for (mx, my, col) in marks:
        out += '<circle cx="%s" cy="%s" r="7" fill="%s" opacity="0.8" stroke="#3a2a16" stroke-width="1.5"/>' % (cx + mx, cy + my, col)
    return out


def wrap(inner):
    return HEAD + FRAME + inner + '</svg>'


def phone_svg():
    bad = ('<rect x="46" y="40" width="64" height="112" rx="10" fill="#2c353b"/><rect x="52" y="52" width="52" height="76" rx="4" fill="#0e1a14"/>'
           + '<path d="M66 90 q12 -14 24 0" stroke="#8cffb0" stroke-width="4" fill="none"/>'
           + '<path d="M40 160 L120 36" stroke="#d9503a" stroke-width="6"/>')
    good = ('<g transform="translate(160 0)"><rect x="46" y="40" width="64" height="112" rx="10" fill="#2c353b"/>'
            '<rect x="52" y="52" width="52" height="76" rx="4" fill="#0e1a14"/>'
            '<circle cx="78" cy="90" r="16" fill="#2e8b57"/><path d="M70 90 q8 -10 16 0" stroke="#fff" stroke-width="4" fill="none"/>'
            '<path d="M120 64 q10 10 0 22 M128 56 q16 18 0 38" stroke="#2e8b57" stroke-width="3" fill="none"/></g>')
    return wrap(bad + good + BAD + GOOD)


def clock_svg():
    bad = clock(80, 104, 52, 11, 50)
    good = clock(240, 104, 52, 11, 35)
    arrow = '<path d="M130 160 q30 18 60 0" stroke="#2e8b57" stroke-width="3" fill="none"/><path d="M128 154 l-4 10 l10 -1" fill="#2e8b57"/>'
    return wrap(bad + good + BAD + GOOD)


def plate_svg():
    def pole(x, no, ok):
        return ('<rect x="%s" y="30" width="8" height="150" fill="#9da1a5"/>' % x
                + '<rect x="%s" y="64" width="40" height="22" rx="3" fill="#2d6a74" stroke="%s" stroke-width="2"/>' % (x - 16, '#2e8b57' if ok else '#8a7a5a')
                + text(x + 4, 80, no, 13, '#f7f7f7'))
    bad = pole(34, '217', False) + pole(78, '218', False) + pole(122, '219', False)
    bad += '<circle cx="78" cy="75" r="34" fill="none" stroke="#d9503a" stroke-width="4"/>'
    good = '<g transform="translate(160 0)">' + pole(34, '217', False) + pole(78, '218', False) + pole(122, '219', False)
    good += '<circle cx="122" cy="75" r="34" fill="none" stroke="#2e8b57" stroke-width="4"/></g>'
    return wrap(bad + good + BAD + GOOD)


def cards_svg():
    bad = card(30, 70, False) + card(90, 70, True)
    bad += '<path d="M56 62 l0 -14 M116 62 l0 -14" stroke="#d9503a" stroke-width="3"/>'
    good = '<g transform="translate(160 0)">' + card(30, 70, False) + card(90, 70, True) + '<path d="M116 62 l0 -14" stroke="#2e8b57" stroke-width="3"/></g>'
    return wrap(bad + good + BAD + GOOD)


def draft_svg():
    return wrap(draft(30, 56, False) + '<g transform="translate(160 0)">' + draft(30, 56, True) + '</g>' + BAD + GOOD)


def stills_svg():
    bad = still(24, 70, 2, False) + still(66, 70, 0, False) + still(108, 70, 1, False)
    good = '<g transform="translate(160 0)">' + still(24, 70, 0, True) + still(66, 70, 1, True) + still(108, 70, 2, True) + '</g>'
    return wrap(bad + good + BAD + GOOD)


def body_svg():
    bad = body(80, 110, [])
    good = '<g transform="translate(160 0)">' + body(80, 110, [(-28, 8, '#f2c21e'), (-28, -10, '#e5502a'), (10, 46, '#3e7bd6')]) + '</g>'
    return wrap(bad + good + BAD + GOOD)


def witness_svg():
    bad = person(50, 140, '#3f8f5a') + person(100, 140, '#e9e1cf')
    good = '<g transform="translate(160 0)">' + person(50, 140, '#3f8f5a') + person(100, 140, '#e9e1cf')
    good += '<circle cx="50" cy="60" r="7" fill="#2e8b57"/><circle cx="100" cy="60" r="7" fill="#2e8b57"/></g>'
    return wrap(bad + good + BAD + GOOD)


FILES = {
    'phone.svg': phone_svg,
    'clock.svg': clock_svg,
    'plate.svg': plate_svg,
    'cards.svg': cards_svg,
    'draft.svg': draft_svg,
    'stills.svg': stills_svg,
    'body.svg': body_svg,
    'witness.svg': witness_svg,
}


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    d = os.path.join(root, OUT)
    os.makedirs(d, exist_ok=True)
    for name, fn in FILES.items():
        with open(os.path.join(d, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(fn() + '\n')
    for name in os.listdir(d):
        if name not in FILES and name != '.gitkeep':
            os.remove(os.path.join(d, name))
    # The folder's own .gitkeep is deleted once there is art.
    keep = os.path.join(d, '.gitkeep')
    if os.path.exists(keep):
        os.remove(keep)
    print('wrote', len(FILES), 'files to', d)


if __name__ == '__main__':
    main()
