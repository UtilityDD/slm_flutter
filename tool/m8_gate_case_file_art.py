# -*- coding: utf-8 -*-
"""Draws the mistake pictures of the Module 8 gate (m8_gate_case_file.dart).

Run:  python -I tool/m8_gate_case_file_art.py
Writes plain SVGs (no logos, no real forms; M8-11) to assets/game/art/m8_gate_case_file/.
"""
import os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'game', 'art', 'm8_gate_case_file')

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">'
        '<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fdf8ec"/>'
        '<stop offset="1" stop-color="#f3e7cc"/></linearGradient>'
        '<radialGradient id="arc" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff"/>'
        '<stop offset="0.45" stop-color="#ffe066"/><stop offset="1" stop-color="#ff8a00" stop-opacity="0"/></radialGradient></defs>'
        '<rect x="4" y="4" width="312" height="192" rx="12" fill="url(#bg)" stroke="#c48a2e" stroke-width="3"/>')
CROSS = ('<g stroke="#d63a2f" stroke-width="6" stroke-linecap="round"><line x1="22" y1="22" x2="40" y2="40"/>'
         '<line x1="40" y1="22" x2="22" y2="40"/></g>')
TAIL = '</svg>'

POLE = ('<line x1="10" y1="48" x2="310" y2="48" stroke="#1c2126" stroke-width="2.5"/>'
        '<rect x="110" y="40" width="8" height="140" fill="#6e6a63"/>'
        '<rect x="79" y="52" width="70" height="7" fill="#4f4a42"/>')
WORKER = ('<circle cx="118" cy="90" r="7" fill="#ffffff" stroke="#333" stroke-width="1.5"/>'
          '<rect x="110" y="98" width="16" height="26" rx="4" fill="#f2b632"/>')


def card(x, y, w, h, label, fill='#f7f1e1'):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{fill}" stroke="#b08a4a" stroke-width="2"/>'
            f'<text x="{x + w / 2}" y="{y + h / 2 + 5}" font-size="14" text-anchor="middle" font-family="sans-serif" '
            f'font-weight="800" fill="#7a1f1f">{label}</text>')


PICS = {
    # a climb without the written PTW (the paper is not in the hand)
    'ptw': POLE + WORKER + card(230, 70, 62, 82, 'PTW') +
    '<line x1="230" y1="70" x2="292" y2="152" stroke="#d63a2f" stroke-width="4"/>' +
    '<rect x="60" y="80" width="40" height="70" rx="6" fill="#3b4250"/><rect x="68" y="90" width="24" height="14" fill="#7fe07a"/>',
    # the tester must read 0 V before anyone climbs
    'tester': POLE + WORKER + '<rect x="200" y="84" width="84" height="56" rx="8" fill="#2e353d"/>'
    '<rect x="212" y="94" width="60" height="22" rx="3" fill="#cfe9b0"/>'
    '<text x="242" y="111" font-size="15" text-anchor="middle" font-family="sans-serif" font-weight="800" fill="#1c2126">0 V</text>'
    '<circle cx="222" cy="128" r="5" fill="#d63a2f"/><circle cx="242" cy="128" r="5" fill="#3fa34d"/>',
    # rods at both ends: before the span and after it
    'earth': '<line x1="10" y1="60" x2="310" y2="60" stroke="#1c2126" stroke-width="2.5"/>'
    '<rect x="60" y="52" width="8" height="128" fill="#6e6a63"/><rect x="250" y="52" width="8" height="128" fill="#6e6a63"/>'
    '<g stroke="#3fa34d" stroke-width="3"><line x1="64" y1="62" x2="78" y2="168"/><line x1="254" y1="62" x2="268" y2="168"/></g>'
    '<rect x="72" y="164" width="16" height="8" fill="#3fa34d"/><rect x="262" y="164" width="16" height="8" fill="#3fa34d"/>'
    '<text x="160" y="120" font-size="13" text-anchor="middle" font-family="sans-serif" font-weight="800" fill="#7a1f1f">1 + 4</text>',
    # a house with panels, its fuse at the pole
    'solar': '<line x1="10" y1="50" x2="310" y2="50" stroke="#1c2126" stroke-width="2.5"/>'
    '<rect x="60" y="42" width="8" height="138" fill="#6e6a63"/><rect x="62" y="96" width="6" height="14" fill="#e0a21b"/>'
    '<path d="M64 52 Q140 90 200 110" fill="none" stroke="#111" stroke-width="2.5"/>'
    '<rect x="170" y="110" width="110" height="70" fill="#8a6b4f"/><polygon points="160,110 225,78 290,110" fill="#5a4635"/>'
    '<polygon points="190,106 222,86 240,98 208,112" fill="#274a7a"/>'
    '<rect x="206" y="146" width="22" height="20" fill="#dad6cc"/><rect x="230" y="150" width="9" height="9" fill="#3fa34d"/>',
    # a branch that touches the line, the pruner, the trunk
    'trim': '<line x1="10" y1="70" x2="310" y2="70" stroke="#1c2126" stroke-width="2.5"/>'
    '<rect x="210" y="96" width="14" height="84" fill="#4e3a28"/>'
    '<path d="M217 100 L150 66" stroke="#4e3a28" stroke-width="7" stroke-linecap="round"/>'
    '<path d="M217 100 L270 64" stroke="#4e3a28" stroke-width="7" stroke-linecap="round"/>'
    '<circle cx="150" cy="62" r="18" fill="#2f5a34"/><circle cx="272" cy="58" r="18" fill="#2f5a34"/>'
    '<line x1="60" y1="170" x2="150" y2="76" stroke="#8d949b" stroke-width="4"/>',
    # a hooking wire: the video from the pole, then the list and the complaint
    'hook': POLE + '<path d="M120 52 Q170 100 232 112" fill="none" stroke="#111" stroke-width="2.5"/>'
    '<rect x="220" y="112" width="70" height="68" fill="#8a6b4f"/><rect x="236" y="144" width="22" height="18" fill="#dad6cc"/>'
    '<rect x="40" y="110" width="58" height="46" rx="6" fill="#2e353d"/><circle cx="69" cy="133" r="12" fill="#7fb2d6"/>'
    '<circle cx="69" cy="133" r="5" fill="#1c2126"/>',
    # the docket: the clock and the report
    'docket': card(100, 52, 120, 96, '') +
    '<circle cx="160" cy="100" r="30" fill="#fff" stroke="#1c2126" stroke-width="3"/>'
    '<line x1="160" y1="100" x2="160" y2="78" stroke="#1c2126" stroke-width="3"/>'
    '<line x1="160" y1="100" x2="176" y2="108" stroke="#d63a2f" stroke-width="3"/>'
    '<rect x="112" y="64" width="96" height="8" rx="2" fill="#b08a4a"/>',
    # a photo of a lit house, kept as proof
    'photo': '<rect x="70" y="50" width="180" height="110" rx="8" fill="#2e353d"/>'
    '<rect x="80" y="60" width="160" height="90" rx="4" fill="#9fc3df"/>'
    '<rect x="150" y="96" width="70" height="54" fill="#8a6b4f"/><polygon points="144,96 185,70 226,96" fill="#5a4635"/>'
    '<rect x="162" y="110" width="14" height="14" fill="#ffd36b"/><rect x="190" y="110" width="14" height="14" fill="#ffd36b"/>'
    '<circle cx="110" cy="84" r="9" fill="#ffe066"/>',
    # the right paper for the right question
    'record': card(40, 56, 70, 90, 'A') + card(125, 56, 70, 90, 'B', '#fff8dd') + card(210, 56, 70, 90, 'C') +
    '<line x1="125" y1="56" x2="195" y2="146" stroke="#3fa34d" stroke-width="5"/>',
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, body in PICS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(HEAD + CROSS + body + TAIL)
    gk = os.path.join(OUT, '.gitkeep')
    if os.path.exists(gk):
        os.remove(gk)
    print('wrote', len(PICS), 'pictures to', os.path.normpath(OUT))


if __name__ == '__main__':
    main()
