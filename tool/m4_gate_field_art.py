#!/usr/bin/env python3
"""Mistake-card art for the Module 4 rank gate (m4_gate_field.dart).

Each card is two panels: the wrong way (red, ✗) on the left and the right way
(green, ✓) on the right, drawn from simple shapes. No text except labels a
worker would read (MIN/MAX, Ω, MCB, R/Y/B/N).

Usage: python3 -I tool/m4_gate_field_art.py <repo root>
"""
import os
import sys

OUT = 'assets/game/art/m4_gate_field'

RED_BG, RED = '#fff4f2', '#c0392b'
GRN_BG, GRN = '#f1faf2', '#2e8b45'


def frame(left, right):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">'
        f'<rect x="4" y="4" width="152" height="192" rx="12" fill="{RED_BG}" stroke="{RED}" stroke-width="3"/>'
        f'<rect x="164" y="4" width="152" height="192" rx="12" fill="{GRN_BG}" stroke="{GRN}" stroke-width="3"/>'
        f'<g>{left}</g><g transform="translate(160 0)">{right}</g>'
        f'<circle cx="134" cy="174" r="14" fill="{RED}"/>'
        '<path d="M127 167 L141 181 M141 167 L127 181" stroke="#fff" stroke-width="3.5" stroke-linecap="round"/>'
        f'<circle cx="294" cy="174" r="14" fill="{GRN}"/>'
        '<path d="M286 174 L292 180 L302 166" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/>'
        '</svg>'
    )


def man(x, y, arm=None):
    """A lineman standing with feet at (x, y); helmet on. arm: (dx, dy) hand reach."""
    s = (
        f'<circle cx="{x}" cy="{y-66}" r="9" fill="#a86e48"/>'
        f'<path d="M{x-10} {y-72} Q{x} {y-84} {x+10} {y-72} Z" fill="#ffd34e"/>'
        f'<rect x="{x-9}" y="{y-56}" width="18" height="30" rx="5" fill="#1f5f8f"/>'
        f'<rect x="{x-8}" y="{y-26}" width="6" height="26" fill="#26303d"/>'
        f'<rect x="{x+2}" y="{y-26}" width="6" height="26" fill="#26303d"/>'
    )
    if arm:
        s += f'<line x1="{x+6}" y1="{y-48}" x2="{x+arm[0]}" y2="{y+arm[1]}" stroke="#1f5f8f" stroke-width="5" stroke-linecap="round"/>'
    return s


def txt(x, y, t, size=11, color='#26303d'):
    return f'<text x="{x}" y="{y}" font-family="sans-serif" font-size="{size}" font-weight="800" fill="{color}" text-anchor="middle">{t}</text>'


def tank(x, y, w=60, h=50):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="#7e8e78"/>'
    for i in range(x + 8, x + w - 4, 8):
        s += f'<line x1="{i}" y1="{y+8}" x2="{i}" y2="{y+h-6}" stroke="#55634f" stroke-width="2"/>'
    return s


def gauge(x, y, level):
    """Glass gauge 12×60 at (x, y); level 0 (bottom) .. 1 (top)."""
    top = y + 60 * (1 - level)
    return (
        f'<rect x="{x-2}" y="{y-2}" width="16" height="64" rx="3" fill="#3e4a3a"/>'
        f'<rect x="{x}" y="{y}" width="12" height="60" fill="#e8f1f4"/>'
        f'<rect x="{x}" y="{top}" width="12" height="{y+60-top}" fill="#c9962b"/>'
        f'<line x1="{x-5}" y1="{y+11}" x2="{x+17}" y2="{y+11}" stroke="#b71c1c" stroke-width="1.5"/>'
        f'<line x1="{x-5}" y1="{y+45}" x2="{x+17}" y2="{y+45}" stroke="#b71c1c" stroke-width="1.5"/>'
        + txt(x - 18, y + 14, 'MAX', 8) + txt(x - 18, y + 48, 'MIN', 8)
    )


def pole(x, top=16, bottom=160):
    return f'<rect x="{x-5}" y="{top}" width="10" height="{bottom-top}" fill="#9aa0a6"/>'


def arm(x1, x2, y):
    return f'<rect x="{x1}" y="{y-3}" width="{x2-x1}" height="6" fill="#4a5058"/>'


def ins(x, y, broken=False):
    s = (
        f'<rect x="{x-6}" y="{y-20}" width="12" height="16" fill="#d9cfc0"/>'
        f'<ellipse cx="{x}" cy="{y-6}" rx="11" ry="4" fill="#c8bca8"/>'
        f'<ellipse cx="{x}" cy="{y-20}" rx="7" ry="3" fill="#d9cfc0"/>'
    )
    if broken:
        s += f'<path d="M{x-4} {y-20} L{x+1} {y-13} L{x-2} {y-9} L{x+4} {y-4}" stroke="#3a2a20" stroke-width="1.6" fill="none"/>'
    return s


def wire(x1, y1, x2, y2, color='#2f343a', w=2):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{w}"/>'


def earth_set(x, top, ground=150):
    return wire(x, top, x, ground, '#2e7d32', 2.4) + f'<rect x="{x-2}" y="{ground}" width="4" height="12" fill="#6e757c"/>'


def flash(x, y, r=16):
    return (
        f'<circle cx="{x}" cy="{y}" r="{r}" fill="#ffe070" opacity="0.9"/>'
        f'<circle cx="{x}" cy="{y}" r="{r*0.45}" fill="#fff"/>'
    )


def meter(x, y, reading, color='#2f5fa8'):
    return (
        f'<rect x="{x}" y="{y}" width="44" height="58" rx="7" fill="{color}"/>'
        f'<rect x="{x+5}" y="{y+7}" width="34" height="20" rx="3" fill="#bfd8a8"/>'
        + txt(x + 22, y + 22, reading, 10, '#1b2a12')
    )


def tree(x, branch_to=None, topped=False):
    s = f'<path d="M{x-8} 160 L{x-4} 60 L{x+4} 60 L{x+8} 160 Z" fill="#6b4a2e"/>'
    if topped:
        s += f'<rect x="{x-14}" y="52" width="28" height="10" fill="#6b4a2e"/>'
        s += f'<line x1="{x-14}" y1="52" x2="{x+14}" y2="52" stroke="#f3e1b8" stroke-width="3"/>'
    else:
        s += f'<circle cx="{x}" cy="50" r="28" fill="#3e7d3a"/>'
    if branch_to:
        s += f'<line x1="{x}" y1="96" x2="{branch_to[0]}" y2="{branch_to[1]}" stroke="#6b4a2e" stroke-width="6"/>'
        s += f'<circle cx="{branch_to[0]}" cy="{branch_to[1]}" r="12" fill="#5c9a4c"/>'
    return s


def line_top(y=30):
    return wire(0, y, 156, y, '#2f343a', 1.6) + wire(0, y + 6, 156, y + 6, '#2f343a', 1.6)


ART = {}

# 4.5 — IR thermometer, not a hand on the tank.
ART['ir_not_hand'] = frame(
    tank(70, 70) + man(52, 160, (22, -78)) + '<path d="M68 80 l6 -6 m-2 12 l8 -4" stroke="#e53935" stroke-width="2"/>',
    tank(80, 70) + man(30, 160, (14, -52)) + '<rect x="40" y="96" width="18" height="10" rx="2" fill="#e5a21a"/>'
    + '<line x1="58" y1="100" x2="80" y2="92" stroke="#e53935" stroke-width="1.4" stroke-dasharray="3 3"/>',
)

# 4.5 — mineral oil only, not engine oil.
can = lambda x, c: f'<rect x="{x}" y="96" width="26" height="36" rx="4" fill="{c}"/><rect x="{x+18}" y="88" width="6" height="10" fill="{c}"/>'
ART['oil_mineral'] = frame(
    tank(80, 70) + can(40, '#212121') + flash(98, 66, 18),
    tank(80, 70) + can(40, '#c9962b') + '<path d="M50 136 h16" stroke="#2e8b45" stroke-width="3"/>' + txt(53, 150, 'MO', 10),
)

# 4.5 — oil below MIN means report.
ART['oil_gauge'] = frame(
    tank(70, 90, 70, 50) + gauge(46, 30, 0.08) + '<path d="M120 140 q4 10 0 18" stroke="#5a3a12" stroke-width="3" fill="none"/>',
    tank(70, 90, 70, 50) + gauge(46, 30, 0.5),
)

# 4.6 — two spikes for the test.
spike = lambda x: f'<line x1="{x}" y1="132" x2="{x}" y2="152" stroke="#9aa4ae" stroke-width="3"/>'
ART['earth_spikes'] = frame(
    meter(20, 60, '? Ω', '#2e6b3a') + '<ellipse cx="120" cy="150" rx="18" ry="6" fill="#6b6f74"/>' + wire(42, 118, 120, 146, '#2a62c9', 1.6),
    meter(14, 50, '4.1 Ω', '#2e6b3a') + '<ellipse cx="130" cy="150" rx="16" ry="5" fill="#6b6f74"/>' + spike(90) + spike(56)
    + wire(36, 108, 130, 146, '#2a62c9', 1.6) + wire(36, 108, 90, 132, '#f2c40f', 1.6) + wire(36, 108, 56, 132, '#d7312b', 1.6),
)

# 4.6 — the line earth must read below 5-8 Ω.
ART['earth_ohm'] = frame(
    meter(56, 40, '16 Ω', '#2e6b3a') + '<ellipse cx="78" cy="140" rx="30" ry="9" fill="#a08a62"/>' + '<rect x="72" y="118" width="12" height="12" fill="#8b4a24"/>',
    meter(56, 40, '4 Ω', '#2e6b3a') + '<ellipse cx="78" cy="140" rx="30" ry="9" fill="#4a3a26"/>'
    + '<ellipse cx="78" cy="140" rx="36" ry="13" fill="#3f8fd8" opacity="0.35"/>' + '<rect x="72" y="118" width="12" height="12" fill="#d4af37"/>',
)

# 4.1 — earths on both sides of the work.
ART['earth_both_sides'] = frame(
    pole(78, 30) + arm(30, 126, 50) + line_top(36) + man(78, 110) + flash(20, 40, 12),
    pole(78, 30) + arm(30, 126, 50) + line_top(36) + man(78, 110) + earth_set(14, 42) + earth_set(142, 42),
)

# 4.1 — the conductor on a rope before the insulator comes off.
ART['ins_rope'] = frame(
    pole(78, 40) + arm(30, 126, 70) + ins(46, 70, True) + wire(0, 120, 46, 60) + wire(46, 60, 156, 120)
    + '<path d="M30 76 l-6 14" stroke="#e53935" stroke-width="2"/>',
    pole(78, 40) + arm(30, 126, 70) + ins(46, 70, True) + wire(0, 52, 156, 52)
    + '<line x1="46" y1="52" x2="82" y2="24" stroke="#d9b26a" stroke-width="2.4"/><line x1="82" y1="24" x2="82" y2="40" stroke="#d9b26a" stroke-width="2.4"/>',
)

# 4.2 — brush and paste before tightening.
clamp = lambda x, y, c: f'<rect x="{x-14}" y="{y-9}" width="28" height="18" rx="3" fill="{c}"/><circle cx="{x-6}" cy="{y}" r="3" fill="#3b3f45"/><circle cx="{x+6}" cy="{y}" r="3" fill="#3b3f45"/>'
ART['jumper_brush'] = frame(
    wire(10, 80, 146, 80, '#2f343a', 4) + clamp(78, 80, '#5b3a26') + '<circle cx="78" cy="80" r="26" fill="#ff5a1f" opacity="0.35"/>',
    wire(10, 80, 146, 80, '#2f343a', 4) + clamp(78, 80, '#a7afb7')
    + '<rect x="36" y="104" width="34" height="10" rx="2" fill="#8d6e63"/><path d="M38 114 v8 m6 -8 v8 m6 -8 v8 m6 -8 v8 m6 -8 v8" stroke="#555" stroke-width="2"/>'
    + '<rect x="96" y="104" width="22" height="16" rx="3" fill="#90a4ae"/>',
)

# 4.2 — two wrenches.
wrench = lambda x1, y1, x2, y2: f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#78909c" stroke-width="7" stroke-linecap="round"/>'
ART['jumper_wrench'] = frame(
    clamp(78, 80, '#a7afb7') + wrench(84, 80, 130, 120) + '<path d="M60 70 a18 18 0 1 0 0 20" stroke="#e53935" stroke-width="2" fill="none"/>',
    clamp(78, 80, '#a7afb7') + wrench(84, 80, 130, 120) + wrench(72, 80, 26, 120),
)

# 4.7 — dress top to bottom, nothing left loose.
messy = '<path d="M60 90 C110 130 20 140 80 170" stroke="#1b1e22" stroke-width="3" fill="none"/><path d="M70 90 C30 120 120 140 70 170" stroke="#1b1e22" stroke-width="3" fill="none"/>'
neat = '<path d="M64 90 V170 M70 90 V170 M76 90 V170" stroke="#1b1e22" stroke-width="3"/><rect x="60" y="110" width="20" height="4" fill="#e6e6e6"/><rect x="60" y="140" width="20" height="4" fill="#e6e6e6"/>'
ART['dp_top_down'] = frame(
    pole(30, 20) + pole(126, 20) + arm(20, 136, 40) + ins(60, 40) + '<path d="M60 20 q-14 -2 -22 -14" stroke="#b8bec4" stroke-width="1.6" fill="none"/>'
    + '<path d="M96 20 C120 30 110 40 96 60" stroke="#2f343a" stroke-width="2" fill="none"/>' + tank(54, 60, 50, 30) + messy,
    pole(30, 20) + pole(126, 20) + arm(20, 136, 40) + ins(60, 40)
    + '<path d="M96 20 C104 34 104 46 96 60" stroke="#2f343a" stroke-width="2" fill="none"/>' + tank(54, 60, 50, 30) + neat
    + '<path d="M140 30 v120" stroke="#2e8b45" stroke-width="3"/><path d="M134 142 l6 10 l6 -10" fill="#2e8b45"/>',
)

nut = lambda x, y, c: f'<polygon points="{x-7},{y} {x-3},{y-6} {x+4},{y-6} {x+8},{y} {x+4},{y+6} {x-3},{y+6}" fill="{c}"/>'
ART['dp_nuts'] = frame(
    pole(40, 20) + arm(20, 136, 60) + nut(40, 60, '#8b4a24') + nut(110, 60, '#8b4a24') + '<path d="M104 70 l10 8" stroke="#e53935" stroke-width="2"/>' + neat,
    pole(40, 20) + arm(20, 136, 60) + nut(40, 60, '#41c463') + nut(110, 60, '#41c463') + wrench(110, 60, 140, 92) + neat,
)

# 4.8 — no topping; trim only the branch toward the line.
ART['tree_topping'] = frame(line_top(40) + tree(110, topped=True), line_top(40) + tree(110) + '<line x1="66" y1="70" x2="86" y2="84" stroke="#f3e1b8" stroke-width="3"/>')

cone = lambda x: f'<path d="M{x-7} 160 L{x} 140 L{x+7} 160 Z" fill="#ff7a1a"/>'
ART['tree_cordon'] = frame(
    line_top(30) + tree(116, (50, 60)) + man(40, 160) + '<rect x="64" y="146" width="40" height="14" rx="4" fill="#546e7a"/>',
    line_top(30) + tree(116, (50, 60)) + cone(20) + cone(60) + cone(96) + wire(20, 146, 96, 146, '#ffd54f', 2),
)

ART['tree_rope'] = frame(
    line_top(40) + tree(120) + '<line x1="40" y1="50" x2="70" y2="64" stroke="#6b4a2e" stroke-width="6"/>' + flash(40, 44, 12),
    line_top(40) + tree(120, (50, 80)) + '<line x1="80" y1="88" x2="120" y2="40" stroke="#e2c27a" stroke-width="2"/><line x1="120" y1="40" x2="100" y2="160" stroke="#e2c27a" stroke-width="2"/>',
)

cut = lambda x, y, c: f'<line x1="{x}" y1="{y-8}" x2="{x}" y2="{y+8}" stroke="{c}" stroke-width="3"/>'
ART['tree_three_cut'] = frame(
    '<line x1="140" y1="90" x2="20" y2="90" stroke="#6b4a2e" stroke-width="12"/><path d="M60 96 L48 112 L36 98" fill="#6b4a2e"/>'
    + '<path d="M60 84 l0 20" stroke="#e53935" stroke-width="2"/>',
    '<line x1="140" y1="90" x2="20" y2="90" stroke="#6b4a2e" stroke-width="12"/>'
    + txt(70, 120, '1', 12, '#2e8b45') + cut(70, 96, '#2e8b45') + txt(58, 70, '2', 12, '#2e8b45') + cut(58, 86, '#2e8b45')
    + txt(124, 70, '3', 12, '#2e8b45') + cut(124, 90, '#2e8b45'),
)

# 4.9 — MCB off and tested before the lamp.
mcb = lambda x, y, on: (
    f'<rect x="{x}" y="{y}" width="26" height="34" rx="3" fill="#9aa4ae"/>'
    f'<rect x="{x+7}" y="{y+8}" width="12" height="18" fill="#26303d"/>'
    f'<rect x="{x+9}" y="{y+ (10 if on else 18)}" width="8" height="6" fill="{"#c62828" if on else "#2e7d32"}"/>'
    + txt(x + 13, y + 46, 'ON' if on else 'OFF', 9, '#c62828' if on else '#1b5e20')
)
lamp = '<rect x="24" y="30" width="60" height="14" rx="7" fill="#5a6068"/>'
ART['lamp_mcb'] = frame(
    pole(120, 20) + lamp + mcb(108, 96, True) + man(50, 160, (2, -114)) + flash(54, 46, 14),
    pole(120, 20) + lamp + mcb(108, 96, False) + man(50, 160, (2, -114)),
)
ART['lamp_test'] = frame(
    pole(120, 20) + lamp + mcb(108, 96, False) + man(50, 160, (2, -114)) + meter(14, 64, '?'),
    pole(120, 20) + lamp + mcb(108, 96, False) + man(50, 160) + meter(14, 64, '0 V'),
)

# 4.10 — shutdown for the shift; heavy to light; measure again.
bus = lambda: ''.join(
    f'<line x1="{30 + i*30}" y1="40" x2="{30 + i*30}" y2="150" stroke="{c}" stroke-width="7"/>' + txt(30 + i * 30, 34, n, 11)
    for i, (n, c) in enumerate(zip('RYBN', ['#d7312b', '#f2c40f', '#2a62c9', '#1b1e22']))
)
ART['bal_shutdown'] = frame(
    bus() + flash(60, 100, 18) + man(140, 170, (-30, -70)),
    bus() + '<rect x="10" y="56" width="136" height="16" rx="4" fill="#2e7d32"/>' + txt(78, 68, 'PTW', 11, '#fff'),
)
ART['bal_shift'] = frame(
    bus() + txt(30, 168, '120', 10) + txt(90, 168, '50', 10) + '<path d="M86 110 Q60 90 34 110" stroke="#e53935" stroke-width="2.4" fill="none"/>',
    bus() + txt(30, 168, '120', 10) + txt(90, 168, '50', 10) + txt(120, 168, 'N≈0', 10, '#2e8b45')
    + '<path d="M34 110 Q60 90 86 110" stroke="#2e8b45" stroke-width="2.4" fill="none"/><path d="M80 104 l8 6 l-9 4" fill="#2e8b45"/>',
)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else '.'
    out = os.path.join(root, OUT)
    os.makedirs(out, exist_ok=True)
    for name, svg in ART.items():
        with open(os.path.join(out, name + '.svg'), 'w', encoding='utf-8') as f:
            f.write(svg)
    print(f'{len(ART)} cards → {out}')


if __name__ == '__main__':
    main()
