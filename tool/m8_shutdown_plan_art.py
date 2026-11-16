"""Mistake pictures of lesson 8.3 kaj 2 (m8_shutdown_plan): wrong way on the left,
right way on the right. Shapes only (no text: flutter_svg draws none).

Run: python -I tool/m8_shutdown_plan_art.py   (writes assets/game/art/m8_shutdown_plan/*.svg)
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'game', 'art', 'm8_shutdown_plan')
W, H = 320, 200

HEAD = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">\n'
BASE = (
    '<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>\n'
    '<rect x="10" y="10" width="146" height="180" rx="8" fill="#fde8e6"/>\n'
    '<rect x="164" y="10" width="146" height="180" rx="8" fill="#e3f6e6"/>\n'
    '<circle cx="24" cy="24" r="11" fill="#d63a32"/><path d="M19 19 L29 29 M29 19 L19 29" stroke="#fff" stroke-width="3" stroke-linecap="round"/>\n'
    '<circle cx="178" cy="24" r="11" fill="#2e9e5b"/><path d="M172 24 L177 29 L185 19" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>\n'
)


def strip(x, y, w=130, h=22, hours=24):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="#f7f4ea" stroke="#b9b4a3"/>\n'
    for k in range(0, hours + 1, 3):
        px = x + w * k / hours
        s += f'<path d="M{px:.1f} {y} L{px:.1f} {y + 6}" stroke="#8a8f99" stroke-width="1"/>\n'
    return s


def block(x, y, h0, h1, w=130, h=22, col='#2f5d9e'):
    px0 = x + w * h0 / 24
    px1 = x + w * h1 / 24
    return f'<rect x="{px0:.1f}" y="{y + 3}" width="{px1 - px0:.1f}" height="{h - 6}" rx="3" fill="{col}" stroke="#d9e4f7"/>\n'


def sun(cx, cy):
    s = f'<circle cx="{cx}" cy="{cy}" r="9" fill="#f5b52e"/>'
    for a in range(0, 360, 45):
        import math
        dx, dy = math.cos(math.radians(a)), math.sin(math.radians(a))
        s += f'<path d="M{cx + dx * 12:.1f} {cy + dy * 12:.1f} L{cx + dx * 17:.1f} {cy + dy * 17:.1f}" stroke="#f5b52e" stroke-width="2"/>'
    return s + '\n'


def moon(cx, cy):
    return f'<circle cx="{cx}" cy="{cy}" r="10" fill="#dfe6f5"/><circle cx="{cx + 5}" cy="{cy - 3}" r="9" fill="#fde8e6"/>\n'


def night():
    s = HEAD + BASE
    s += moon(80, 70) + strip(18, 100) + block(18, 100, 18, 21, col='#2f5d9e')
    s += sun(235, 70) + strip(172, 100) + block(172, 100, 10, 13, col='#2f5d9e')
    s += strip(18, 134) + strip(172, 134)
    return s + '</svg>\n'


def day_box(x, y, filled=False):
    return f'<rect x="{x}" y="{y}" width="26" height="26" rx="4" fill="{"#2f5d9e" if filled else "#f7f4ea"}" stroke="#8a8f99"/>\n'


def notice():
    s = HEAD + BASE
    # wrong: notice and the shutdown a day apart
    s += day_box(22, 80, True) + day_box(52, 80) + day_box(82, 80, False)
    s += '<rect x="52" y="80" width="26" height="26" rx="4" fill="#d63a32"/>\n'
    s += '<path d="M35 112 L65 112" stroke="#d63a32" stroke-width="3"/>\n'
    # right: three clear days
    for i in range(5):
        s += day_box(172 + i * 28, 80, i == 0)
    s += '<rect x="256" y="80" width="26" height="26" rx="4" fill="#2e9e5b"/>\n'
    s += '<path d="M185 112 L269 112" stroke="#2e9e5b" stroke-width="3"/>\n'
    return s + '</svg>\n'


def late():
    s = HEAD + BASE
    s += strip(18, 80, hours=8) + block(18, 80, 5.2, 7.6, w=130)
    s += '<path d="M83 70 L83 112" stroke="#d63a32" stroke-width="3" stroke-dasharray="4 3"/>\n'
    s += strip(172, 80, hours=8) + block(172, 80, 1, 3.2, w=130)
    s += '<path d="M237 70 L237 112" stroke="#2e9e5b" stroke-width="3" stroke-dasharray="4 3"/>\n'
    s += '<circle cx="172" cy="130" r="5" fill="#d63a32"/><circle cx="18" cy="130" r="5" fill="#d63a32"/>\n'
    return s + '</svg>\n'


def wheel(x, y, col):
    return (f'<rect x="{x}" y="{y}" width="38" height="70" rx="7" fill="#1c2638"/>'
            f'<rect x="{x + 3}" y="{y + 24}" width="32" height="22" rx="5" fill="{col}"/>\n')


def wheels():
    s = HEAD + BASE
    s += strip(18, 70) + block(18, 70, 9, 12)
    for i, c in enumerate(['#2d4670', '#d63a32', '#d63a32']):
        s += wheel(18 + i * 44, 104, c)
    s += strip(172, 70) + block(172, 70, 9, 12)
    for i in range(3):
        s += wheel(172 + i * 44, 104, '#2e9e5b')
    return s + '</svg>\n'


def porch(x, y, q=False, tick=False, lit=True):
    s = f'<rect x="{x}" y="{y}" width="38" height="34" rx="3" fill="#d9c9a4" stroke="#8a7458"/>'
    s += f'<path d="M{x - 3} {y + 3} L{x + 19} {y - 12} L{x + 41} {y + 3} Z" fill="#7a3b2a"/>'
    s += f'<rect x="{x + 6}" y="{y + 8}" width="12" height="10" fill="{"#ffe9a8" if lit else "#232a3c"}"/>'
    if q:
        s += f'<circle cx="{x + 19}" cy="{y - 24}" r="9" fill="#fff" stroke="#d63a32" stroke-width="2"/><path d="M{x + 15} {y - 27} q4 -5 8 0 q0 4 -4 5 M{x + 19} {y - 18} l0 0.1" stroke="#d63a32" stroke-width="2" fill="none"/>'
    if tick:
        s += f'<circle cx="{x + 19}" cy="{y - 24}" r="9" fill="#fff" stroke="#2e9e5b" stroke-width="2"/><path d="M{x + 14} {y - 24} l4 4 l7 -8" fill="none" stroke="#2e9e5b" stroke-width="2.4"/>'
    return s + '\n'


def lane():
    s = HEAD + BASE
    # wrong: the lever pulled, one porch still did not hear
    s += porch(16, 100, q=True) + porch(62, 100, tick=True) + porch(108, 100, tick=True)
    s += '<rect x="48" y="150" width="60" height="26" rx="6" fill="#1c2638"/><path d="M78 152 L90 138" stroke="#ff8a80" stroke-width="4" stroke-linecap="round"/>\n'
    # right: the crew tells the porch first
    s += porch(170, 100, tick=True) + porch(216, 100, tick=True) + porch(262, 100, tick=True)
    s += '<circle cx="190" cy="160" r="6" fill="#e0b48a"/><rect x="184" y="166" width="12" height="16" rx="3" fill="#2f5d9e"/>\n'
    s += '<path d="M200 160 L214 150" stroke="#2e9e5b" stroke-width="2.4" stroke-dasharray="3 3"/>\n'
    return s + '</svg>\n'


def wait():
    s = HEAD + BASE
    s += porch(16, 80, tick=True) + porch(62, 80, tick=True) + porch(108, 80, tick=True)
    # wrong: an hourglass, a needless wait
    s += '<path d="M62 130 L98 130 L80 152 Z M62 176 L98 176 L80 154 Z" fill="#d6a53a" stroke="#8a6a1a"/>\n'
    s += porch(170, 80, tick=True) + porch(216, 80, tick=True) + porch(262, 80, tick=True)
    s += '<rect x="196" y="140" width="60" height="30" rx="6" fill="#1c2638"/><path d="M226 142 L238 156" stroke="#7ee08f" stroke-width="4" stroke-linecap="round"/>\n'
    return s + '</svg>\n'


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [('night', night), ('notice', notice), ('late', late), ('wheels', wheels), ('lane', lane), ('wait', wait)]:
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(fn())
    gk = os.path.join(OUT, '.gitkeep')
    if os.path.exists(gk):
        os.remove(gk)
    print('ok')
