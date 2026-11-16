"""Mistake pictures for m7_street_warn (lesson 7.3 কাজ 2 "পাড়ার পাহারা").

Each card is 320 x 200: the wrong way on the left (red cross), the right way
on the right (green tick). No words in the art. Writes only into
assets/game/art/m7_street_warn/ and removes its own stale files there.

    python -I tool/m7_street_warn_art.py .
"""
import os
import sys

OUT = 'assets/game/art/m7_street_warn'

HEAD = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
    '<defs>\n'
    '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7fb0dc"/><stop offset="1" stop-color="#e8dcbc"/></linearGradient>\n'
    '<linearGradient id="road" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6a6c70"/><stop offset="1" stop-color="#4a4c50"/></linearGradient>\n'
    '<linearGradient id="lane" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#c2a985"/><stop offset="1" stop-color="#a88e6c"/></linearGradient>\n'
    '<radialGradient id="zap"><stop offset="0" stop-color="#fffbe0"/><stop offset="0.5" stop-color="#ffc23c" stop-opacity="0.85"/><stop offset="1" stop-color="#ff9020" stop-opacity="0"/></radialGradient>\n'
    '</defs>\n'
    '<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>\n'
)
TAIL = '</svg>\n'

SKIN = '#9c6b4a'
HAIR = '#231c18'


def panel(x, ground='road'):
    """A 140 x 172 scene panel at x (sky, then road or lane)."""
    fill = 'url(#road)' if ground == 'road' else 'url(#lane)'
    return (f'<rect x="{x}" y="14" width="140" height="172" rx="8" fill="url(#sky)"/>'
            f'<rect x="{x}" y="150" width="140" height="36" fill="{fill}"/>')


def badge(x, ok):
    cx, cy = x + 124, 30
    if ok:
        return (f'<circle cx="{cx}" cy="{cy}" r="11" fill="#2e9d57"/>'
                f'<path d="M{cx-5} {cy} l4 4 l7 -8" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>')
    return (f'<circle cx="{cx}" cy="{cy}" r="11" fill="#d23c2e"/>'
            f'<path d="M{cx-5} {cy-5} l10 10 M{cx+5} {cy-5} l-10 10" stroke="#fff" stroke-width="3" stroke-linecap="round"/>')


def person(x, y, shirt='#8e6b4e', lungi='#3f4a5c', arm_up=False, face=1, s=1.0, sari=False):
    """A standing person with feet at (x, y)."""
    f = face
    p = [f'<g transform="translate({x} {y}) scale({s})">',
         '<ellipse cx="0" cy="1" rx="8" ry="2" fill="#000" opacity="0.25"/>',
         f'<line x1="-2" y1="-12" x2="-2" y2="0" stroke="{SKIN}" stroke-width="2.6" stroke-linecap="round"/>',
         f'<line x1="2" y1="-12" x2="2" y2="0" stroke="{SKIN}" stroke-width="2.6" stroke-linecap="round"/>']
    if sari:
        p.append(f'<path d="M-6 -26 L6 -26 L7 0 L-7 0 Z" fill="{shirt}"/>')
        p.append('<path d="M-5 -25 L6 -12" stroke="#b9483a" stroke-width="2"/>')
    else:
        p.append(f'<rect x="-5" y="-21" width="10" height="11" fill="{lungi}"/>')
        p.append(f'<rect x="-6" y="-35" width="12" height="15" rx="3" fill="{shirt}"/>')
    if arm_up:
        p.append(f'<line x1="{4*f}" y1="-32" x2="{9*f}" y2="-44" stroke="{SKIN}" stroke-width="2.2" stroke-linecap="round"/>')
    else:
        p.append(f'<line x1="{4*f}" y1="-32" x2="{6*f}" y2="-22" stroke="{SKIN}" stroke-width="2.2" stroke-linecap="round"/>')
    p.append(f'<line x1="{-4*f}" y1="-32" x2="{-4*f}" y2="-22" stroke="{SKIN}" stroke-width="2.2" stroke-linecap="round"/>')
    p.append(f'<circle cx="0" cy="-41" r="5" fill="{SKIN}"/>')
    p.append(f'<path d="M-5 -42 a5 5 0 0 1 10 0 z" fill="{HAIR}"/>')
    p.append('</g>')
    return ''.join(p)


def trainee(x, y, point=False, phone=False, face=1):
    """The trainee in orange with a yellow helmet."""
    f = face
    p = [f'<g transform="translate({x} {y})">',
         '<ellipse cx="0" cy="1" rx="9" ry="2.5" fill="#000" opacity="0.25"/>',
         '<rect x="-6" y="-18" width="5" height="18" fill="#2b3e5c"/><rect x="1" y="-18" width="5" height="18" fill="#2b3e5c"/>',
         '<rect x="-8" y="-40" width="16" height="24" rx="3" fill="#ff8a00"/>']
    if point:
        p.append(f'<path d="M{5*f} -36 l{14*f} -6" stroke="{SKIN}" stroke-width="3.4" stroke-linecap="round"/>')
        p.append(f'<path d="M{24*f} -48 q{6*f} 6 0 12 M{29*f} -52 q{8*f} 10 0 20" stroke="#ffffff" stroke-width="2" fill="none"/>')
    elif phone:
        p.append(f'<path d="M{5*f} -36 l{2*f} -10" stroke="{SKIN}" stroke-width="3.4" stroke-linecap="round"/>')
        p.append(f'<rect x="{5*f-3}" y="-54" width="6" height="10" rx="1.5" fill="#22303f"/>')
        p.append(f'<path d="M{12*f} -56 q{5*f} 5 0 10" stroke="#9be3b4" stroke-width="2" fill="none"/>')
    else:
        p.append(f'<path d="M{5*f} -34 l{2*f} 10" stroke="{SKIN}" stroke-width="3.4" stroke-linecap="round"/>')
    p.append(f'<circle cx="0" cy="-47" r="7" fill="{SKIN}"/>')
    p.append('<path d="M-8 -52 a8 7 0 0 1 16 0 z" fill="#e0a21e"/>')
    p.append('</g>')
    return ''.join(p)


def pole(x, top, base=150, w=5):
    return f'<rect x="{x-w/2}" y="{top}" width="{w}" height="{base-top}" fill="#9aa0a6"/>'


def wire(x0, x1, y, dip=4, color='#26282b', w=1.8):
    mx = (x0 + x1) / 2
    return f'<path d="M{x0} {y} Q {mx} {y + dip * 2} {x1} {y}" stroke="{color}" stroke-width="{w}" fill="none"/>'


def ht_line(x, y=50):
    """11 kV: two poles, a cross-arm, three conductors."""
    return (pole(x + 14, y - 8) + pole(x + 126, y - 8)
            + f'<rect x="{x+4}" y="{y-6}" width="20" height="3" fill="#55595e"/><rect x="{x+116}" y="{y-6}" width="20" height="3" fill="#55595e"/>'
            + wire(x + 4, x + 136, y) + wire(x + 4, x + 136, y + 5) + wire(x + 4, x + 136, y + 10))


def lt_line(x, y=78, dip=4):
    return (pole(x + 12, y - 6, base=150, w=4) + pole(x + 128, y - 6, base=150, w=4)
            + wire(x + 4, x + 136, y, dip=dip) + wire(x + 4, x + 136, y - 5, dip=dip))


def rod(x0, y0, x1, y1, bamboo=False):
    col = '#c9a55a' if bamboo else '#6e737a'
    w = 3.4 if bamboo else 2.4
    return f'<line x1="{x0}" y1="{y0}" x2="{x1}" y2="{y1}" stroke="{col}" stroke-width="{w}" stroke-linecap="round"/>'


def spark(x, y, r=18):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#zap)"/>'


def house(x, y, w=80, h=44, wall='#e2c79a'):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{wall}"/>'
            f'<rect x="{x-2}" y="{y-3}" width="{w+4}" height="4" fill="#9d917f"/>'
            f'<rect x="{x+w*0.16}" y="{y+12}" width="{w*0.2}" height="13" fill="#51606b"/>'
            f'<rect x="{x+w*0.62}" y="{y+12}" width="{w*0.2}" height="13" fill="#51606b"/>'
            f'<rect x="{x+w*0.42}" y="{y+h-22}" width="{w*0.15}" height="22" fill="#6b4a2e"/>')


def clothes(x, y, h=24, wet=True):
    cols = ['#d0453a', '#3c7fc2', '#e2b13c', '#6ba35a']
    s = [f'<line x1="{x}" y1="{y}" x2="{x}" y2="{y-h}" stroke="#7a5a3c" stroke-width="1.8"/>',
         f'<line x1="{x+38}" y1="{y}" x2="{x+38}" y2="{y-h}" stroke="#7a5a3c" stroke-width="1.8"/>',
         f'<line x1="{x}" y1="{y-h}" x2="{x+38}" y2="{y-h}" stroke="#333" stroke-width="1"/>']
    for i, c in enumerate(cols):
        hh = 10 + (i % 2) * 4
        s.append(f'<rect x="{x+3+i*9}" y="{y-h+1}" width="7.5" height="{hh}" fill="{c}"/>')
        if wet:
            s.append(f'<circle cx="{x+6.7+i*9}" cy="{y-h+hh+4}" r="1.2" fill="#5aa0d8"/>')
    return ''.join(s)


def phone_bubble(x, y):
    return (f'<rect x="{x}" y="{y}" width="34" height="22" rx="6" fill="#1f4a33"/>'
            f'<path d="M{x+10} {y+16} q-2 -8 4 -10 l3 3 l-3 3 q2 3 5 5 l3 -3 l3 3 q-2 6 -10 4 z" fill="#9be3b4"/>')


def shout(x, y):
    return f'<path d="M{x} {y} q6 6 0 12 M{x+5} {y-4} q8 10 0 20" stroke="#d23c2e" stroke-width="2.2" fill="none"/>'


def card(left, right):
    return HEAD + f'<g>{panel(12)}{left}{badge(12, False)}</g><g>{panel(168)}{right}{badge(168, True)}</g>' + TAIL


def carrier_scene(x, lifted, warned=False):
    """A man with a long rod under the 11 kV line."""
    s = ht_line(x)
    if lifted:
        s += person(x + 64, 172, shirt='#5f7488') + rod(x + 58, 158, x + 72, 62) + spark(x + 72, 62)
    elif warned:
        s += person(x + 84, 172, shirt='#5f7488', face=-1) + rod(x + 96, 152, x + 50, 146)
        s += trainee(x + 26, 176, point=True)
    return s


def build_contact():
    return card(carrier_scene(12, True), carrier_scene(168, False, warned=True))


def build_late():
    left = ht_line(12) + person(76, 172, shirt='#5f7488') + rod(70, 158, 82, 70) + trainee(36, 176, point=True) + shout(54, 120)
    right = carrier_scene(168, False, warned=True)
    return card(left, right)


def build_carrier_report():
    left = ht_line(12) + person(86, 172, shirt='#5f7488') + rod(80, 158, 104, 98) + trainee(36, 176, phone=True)
    right = carrier_scene(168, False, warned=True)
    return card(left, right)


def roof_scene(x, item, cleared=False, act=None):
    s = house(x + 20, 104, w=96, h=46) + lt_line(x, y=78)
    if not cleared:
        if item == 'clothes':
            s += clothes(x + 46, 102)
        else:
            s += rod(x + 52, 102, x + 70, 84, bamboo=True)
        s += person(x + 96, 103, shirt='#7a5f5f', arm_up=True, face=-1, s=0.7, sari=item == 'clothes')
    if act == 'phone':
        s += trainee(x + 24, 182, phone=True)
    elif act == 'shout':
        s += trainee(x + 24, 182, point=True) + shout(x + 44, 130)
    return s


def build_roof_clothes():
    return card(roof_scene(12, 'clothes'), roof_scene(168, 'clothes', cleared=True, act='shout'))


def build_roof_bamboo():
    return card(roof_scene(12, 'bamboo'), roof_scene(168, 'bamboo', cleared=True, act='shout'))


def build_roof_report():
    return card(roof_scene(12, 'clothes', act='phone'), roof_scene(168, 'clothes', cleared=True, act='shout'))


def plot_scene(x, masons_up=True, act=None):
    s = (f'<rect x="{x+44}" y="{112}" width="70" height="38" fill="#b4593c"/>'
         f'<line x1="{x+40}" y1="150" x2="{x+40}" y2="80" stroke="#c9a55a" stroke-width="2.2"/>'
         f'<line x1="{x+80}" y1="150" x2="{x+80}" y2="80" stroke="#c9a55a" stroke-width="2.2"/>'
         f'<line x1="{x+38}" y1="84" x2="{x+82}" y2="84" stroke="#c9a55a" stroke-width="2.2"/>')
    s += ht_line(x, y=46)
    if masons_up:
        s += person(x + 52, 84, shirt='#6e805f', arm_up=True, s=0.7) + person(x + 70, 84, shirt='#9a7b4f', face=-1, s=0.7)
    else:
        s += person(x + 100, 172, shirt='#6e805f', s=0.8) + person(x + 116, 172, shirt='#9a7b4f', face=-1, s=0.8)
    if act == 'shout':
        s += trainee(x + 22, 182, point=True) + shout(x + 40, 130)
    elif act == 'phone':
        s += trainee(x + 22, 182, phone=True) + phone_bubble(x + 6, 100)
    return s


def build_build_warn():
    return card(plot_scene(12), plot_scene(168, masons_up=False, act='shout'))


def build_build_report():
    return card(plot_scene(12, masons_up=False), plot_scene(168, masons_up=False, act='phone'))


def sag_scene(x, act=None):
    s = house(x + 20, 112, w=96, h=38) + lt_line(x, y=74, dip=22)
    if act == 'phone':
        s += trainee(x + 26, 182, phone=True) + phone_bubble(x + 8, 120)
    elif act == 'none':
        s += trainee(x + 26, 182)
    return s


def build_sag():
    return card(sag_scene(12, act='none'), sag_scene(168, act='phone'))


def build_needless():
    # Left: the trainee stops a vendor walking a lane with no line overhead.
    left = (house(30, 100, w=60, h=50) + person(104, 172, shirt='#7d6a7f', face=-1)
            + '<ellipse cx="104" cy="122" rx="9" ry="3.5" fill="#b98a4a"/>'
            + trainee(48, 182, point=True) + shout(66, 126))
    # Right: the same vendor walks on; the trainee watches the line.
    right = (house(186, 100, w=60, h=50) + person(286, 172, shirt='#7d6a7f')
             + '<ellipse cx="286" cy="122" rx="9" ry="3.5" fill="#b98a4a"/>' + trainee(204, 182))
    return card(left, right)


CARDS = {
    'contact.svg': build_contact,
    'late.svg': build_late,
    'carrier_report.svg': build_carrier_report,
    'roof_report.svg': build_roof_report,
    'roof_clothes.svg': build_roof_clothes,
    'roof_bamboo.svg': build_roof_bamboo,
    'build_warn.svg': build_build_warn,
    'build_report.svg': build_build_report,
    'sag.svg': build_sag,
    'needless.svg': build_needless,
}


def main(root):
    out = os.path.join(root, OUT)
    os.makedirs(out, exist_ok=True)
    for name in os.listdir(out):
        if name.endswith('.svg') and name not in CARDS:
            os.remove(os.path.join(out, name))
    for name, make in CARDS.items():
        with open(os.path.join(out, name), 'w', encoding='utf-8', newline='\n') as f:
            f.write(make())
    keep = os.path.join(out, '.gitkeep')
    if os.path.exists(keep):
        os.remove(keep)
    print(f'wrote {len(CARDS)} cards to {OUT}')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
