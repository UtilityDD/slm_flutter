#!/usr/bin/env python3
"""Mistake-card art for lesson 4.8 কাজ 2 (m4_tree_cut): each card shows the
wrong way (red frame, left) beside the right way (green frame, right).
No text in the art. Run: python3 -I tool/m4_tree_cut_art.py"""
import os

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'game', 'art', 'm4_tree_cut')

HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">'
        '<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cfe3f3"/>'
        '<stop offset="1" stop-color="#f3ecd8"/></linearGradient></defs>'
        '<rect x="4" y="4" width="152" height="192" rx="14" fill="url(#sky)" stroke="#c0392b" stroke-width="4"/>'
        '<rect x="164" y="4" width="152" height="192" rx="14" fill="url(#sky)" stroke="#27ae60" stroke-width="4"/>')
CROSS = '<g stroke="#c0392b" stroke-width="5" stroke-linecap="round"><line x1="128" y1="16" x2="146" y2="34"/><line x1="146" y1="16" x2="128" y2="34"/></g>'
TICK = '<path d="M290 26 l8 8 l14 -16" stroke="#27ae60" stroke-width="5" fill="none" stroke-linecap="round"/>'


def ground():
    return '<rect x="6" y="176" width="148" height="18" fill="#6e9e45"/>'


def trunk():
    return '<path d="M22 194 L28 40 L42 40 L48 194 Z" fill="#7a5634"/>'


def leaves(x, y, r=9):
    return (f'<circle cx="{x}" cy="{y}" r="{r}" fill="#3f7a3a"/><circle cx="{x + r * 0.7}" cy="{y - r * 0.4}" r="{r * 0.8}" fill="#5e9b4c"/>'
            f'<circle cx="{x - r * 0.6}" cy="{y + r * 0.3}" r="{r * 0.7}" fill="#5e9b4c"/>')


def limb(x2=140, y2=110):
    return f'<path d="M40 82 Q90 66 {x2} {y2}" stroke="#6b4a2e" stroke-width="9" fill="none" stroke-linecap="round"/>'


def line(y=150):
    return (f'<line x1="70" y1="{y}" x2="156" y2="{y - 4}" stroke="#2e3338" stroke-width="2.5"/>'
            f'<line x1="70" y1="{y + 8}" x2="156" y2="{y + 4}" stroke="#2e3338" stroke-width="2.5"/>'
            f'<rect x="66" y="{y - 6}" width="6" height="{194 - y + 6}" fill="#b9b5aa"/>')


def man(x, y, s=1.0):
    return (f'<g transform="translate({x},{y}) scale({s})"><circle cx="0" cy="0" r="7" fill="#c98b5e"/>'
            '<path d="M-8 -3 A8 8 0 0 1 8 -3 Z" fill="#ffd34e"/><rect x="-7" y="8" width="14" height="20" rx="4" fill="#ff851b"/>'
            '<rect x="-6" y="28" width="5" height="16" fill="#26303d"/><rect x="1" y="28" width="5" height="16" fill="#26303d"/></g>')


def panel(left, right):
    return HEAD + '<g>' + left + CROSS + '</g><g transform="translate(160,0)">' + right + '</g>' + TICK + '</svg>'


def falling(x, y, rot=30):
    return f'<g transform="translate({x},{y}) rotate({rot})"><line x1="-22" y1="0" x2="22" y2="0" stroke="#6b4a2e" stroke-width="7" stroke-linecap="round"/>{leaves(24, 0, 7)}</g>'


def arrow(x1, y1, x2, y2, c='#c0392b'):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="3" stroke-dasharray="5 4"/>'
            f'<circle cx="{x2}" cy="{y2}" r="4" fill="{c}"/>')


def cards():
    base = ground() + trunk()
    # order: the thick limb cut first (with its twigs) vs a small twig first.
    yield 'order', panel(
        base + line() + falling(100, 120, 20) + leaves(124, 116) + leaves(110, 104) + '<path d="M40 82 L52 80" stroke="#6b4a2e" stroke-width="9"/>'
        + '<line x1="56" y1="70" x2="56" y2="92" stroke="#fff" stroke-width="3"/>',
        base + line() + limb() + leaves(142, 112) + '<line x1="126" y1="96" x2="134" y2="112" stroke="#fff" stroke-width="3"/>' + falling(140, 168, 10),
    )
    # rope: no rope, the limb drops onto the conductors vs roped and lowered.
    yield 'rope', panel(
        base + line() + falling(110, 142, 15) + arrow(110, 96, 110, 136),
        base + line() + limb() + leaves(142, 112) + '<path d="M110 84 Q70 40 36 34 Q20 100 30 160" stroke="#e0c068" stroke-width="2.5" fill="none"/>'
        + man(20, 140, 0.8),
    )
    # fall: standing below the limb as it comes down vs beside the trunk, above.
    yield 'fall', panel(
        base + limb(130, 100) + man(60, 104) + arrow(100, 90, 64, 110),
        base + limb(130, 100) + man(16, 30) + '<line x1="70" y1="70" x2="70" y2="96" stroke="#fff" stroke-width="3"/>',
    )
    # cuts: one top cut, the bark tears down the trunk side vs under, top, collar.
    yield 'cuts', panel(
        base + limb() + '<line x1="78" y1="64" x2="80" y2="76" stroke="#fff" stroke-width="3"/>'
        + '<path d="M62 84 Q66 100 58 118" stroke="#e2c79a" stroke-width="5" fill="none"/>',
        base + limb() + '<line x1="70" y1="80" x2="70" y2="86" stroke="#fff" stroke-width="3"/>'
        + '<line x1="86" y1="68" x2="86" y2="76" stroke="#fff" stroke-width="3"/><line x1="50" y1="72" x2="50" y2="90" stroke="#fff" stroke-width="3"/>'
        + '<text x="0" y="0"/>',
    )
    # lower: the rope let go, the limb drops onto the line vs lowered in to the trunk.
    yield 'lower', panel(
        base + line() + '<path d="M36 34 Q20 100 30 150" stroke="#e0c068" stroke-width="2.5" fill="none"/>' + falling(104, 140, 25)
        + arrow(104, 70, 104, 130),
        base + line() + '<path d="M36 34 L60 40 L60 100" stroke="#e0c068" stroke-width="2.5" fill="none"/>'
        + '<g transform="translate(60,130) rotate(90)"><line x1="-30" y1="0" x2="30" y2="0" stroke="#6b4a2e" stroke-width="7"/></g>' + man(16, 140, 0.8),
    )
    # clear: a shoot left touching the conductors vs cut back, a clear gap.
    yield 'clear', panel(
        base + line() + '<path d="M44 120 Q70 130 84 142" stroke="#6b4a2e" stroke-width="4" fill="none"/>' + leaves(86, 142, 8)
        + '<circle cx="84" cy="146" r="14" fill="none" stroke="#c0392b" stroke-width="3"/>',
        base + line() + '<line x1="44" y1="120" x2="50" y2="122" stroke="#6b4a2e" stroke-width="4"/>'
        + '<line x1="54" y1="140" x2="96" y2="140" stroke="#27ae60" stroke-width="3" stroke-dasharray="4 3"/>',
    )
    # prune: a shoot growing away from the line cut vs left; only the one at the line cut.
    yield 'prune', panel(
        base + line() + '<path d="M28 60 L12 34" stroke="#6b4a2e" stroke-width="4"/>' + falling(20, 168, 0)
        + '<line x1="20" y1="44" x2="26" y2="52" stroke="#fff" stroke-width="3"/>',
        base + line() + '<path d="M28 60 Q20 40 12 30" stroke="#6b4a2e" stroke-width="4" fill="none"/>' + leaves(12, 28, 8)
        + '<line x1="44" y1="120" x2="50" y2="122" stroke="#6b4a2e" stroke-width="4"/>',
    )


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, svg in cards():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8') as f:
            f.write(svg.replace('<text x="0" y="0"/>', ''))


if __name__ == '__main__':
    main()
