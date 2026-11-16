#!/usr/bin/env python3
"""Mistake-card pictures for lesson 8.6 "রাগ নয়, ঠিক রাস্তা" (m8_grievance_reply).

Each picture is a 320 x 200 card: the wrong way on the left (red cross), the
right way on the right (green tick). No text, no logos (M8-11). Run:

    python -I tool/m8_grievance_reply_art.py .

Deletes only the stale .svg files of its own folder.
"""
import os
import sys

OUT = 'assets/game/art/m8_grievance_reply'
INK = '#2a1c14'
WOOD = '#9c7448'
WOOD_D = '#6e4e2e'
PAPER = '#f7f1de'
FOLDER = '#e9c77e'


def frame(body):
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n'
        '<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>'
        '<line x1="160" y1="16" x2="160" y2="184" stroke="#e1d4b8" stroke-width="2" stroke-dasharray="5 4"/>'
        '<circle cx="132" cy="32" r="15" fill="#c0392b"/>'
        '<path d="M126 26 L138 38 M138 26 L126 38" stroke="#fff" stroke-width="4" stroke-linecap="round"/>'
        '<circle cx="292" cy="32" r="15" fill="#27ae60"/>'
        '<path d="M285 32 L290 38 L300 26" stroke="#fff" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
        '<rect x="10" y="168" width="140" height="3" rx="1.5" fill="#d6c7a4"/>'
        '<rect x="170" y="168" width="140" height="3" rx="1.5" fill="#d6c7a4"/>'
        + body + '\n</svg>\n')


def ladder(x, file_at=None, arrow=None, dim=()):
    """Three planks, lowest first; a folder on one; an optional arrow between."""
    s = ''
    for i in range(3):
        y = 140 - i * 38
        op = '0.45' if i in dim else '1'
        s += (f'<rect x="{x}" y="{y}" width="92" height="28" rx="5" fill="{WOOD}" stroke="{WOOD_D}" stroke-width="2" opacity="{op}"/>'
              f'<rect x="{x + 8}" y="{y + 12}" width="40" height="4" rx="2" fill="#fff4d8" opacity="0.8"/>')
    if file_at is not None:
        y = 140 - file_at * 38
        s += (f'<rect x="{x + 58}" y="{y - 4}" width="26" height="30" rx="3" fill="{FOLDER}" stroke="#8a6a3c" stroke-width="2"/>'
              f'<rect x="{x + 62}" y="{y + 6}" width="18" height="2" fill="#3a2a16" opacity="0.5"/>'
              f'<rect x="{x + 62}" y="{y + 12}" width="18" height="2" fill="#3a2a16" opacity="0.5"/>')
    if arrow is not None:
        a, b = arrow
        ya, yb = 140 - a * 38 + 14, 140 - b * 38 + 14
        s += (f'<path d="M{x - 10} {ya} L{x - 10} {yb}" stroke="#c0392b" stroke-width="4" fill="none" stroke-linecap="round"/>'
              f'<path d="M{x - 17} {yb + (8 if b < a else -8)} L{x - 10} {yb} L{x - 3} {yb + (8 if b < a else -8)}" stroke="#c0392b" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
    return s


def person(cx, shirt='#3f7f9e', mood='calm', skin='#c58b63', bottom=164):
    top = bottom - 104
    s = (f'<rect x="{cx - 14}" y="{bottom - 50}" width="12" height="46" rx="4" fill="#3b4252"/>'
         f'<rect x="{cx + 2}" y="{bottom - 50}" width="12" height="46" rx="4" fill="#3b4252"/>'
         f'<rect x="{cx - 17}" y="{top + 28}" width="34" height="36" rx="10" fill="{shirt}"/>'
         f'<circle cx="{cx}" cy="{top + 16}" r="14" fill="{skin}"/>'
         f'<path d="M{cx - 14} {top + 15} q14 -17 28 0 q-14 -6 -28 0z" fill="#1e1a18"/>'
         f'<circle cx="{cx - 5}" cy="{top + 17}" r="1.6" fill="#1a1210"/><circle cx="{cx + 5}" cy="{top + 17}" r="1.6" fill="#1a1210"/>')
    if mood == 'angry':
        s += (f'<path d="M{cx - 6} {top + 26} q6 -6 12 0" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
              f'<path d="M{cx - 9} {top + 11} L{cx - 2} {top + 14} M{cx + 9} {top + 11} L{cx + 2} {top + 14}" stroke="{INK}" stroke-width="1.8" stroke-linecap="round"/>'
              f'<path d="M{cx + 17} {top + 34} L{cx + 28} {top + 20}" stroke="{skin}" stroke-width="7" stroke-linecap="round"/>')
    else:
        s += f'<path d="M{cx - 5} {top + 22} q5 6 10 0" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linecap="round"/>'
    return s


def cloud(cx, cy, red=False):
    c = '#b8322a' if red else '#50505c'
    return (f'<circle cx="{cx - 14}" cy="{cy + 3}" r="10" fill="{c}"/><circle cx="{cx}" cy="{cy - 4}" r="13" fill="{c}"/>'
            f'<circle cx="{cx + 14}" cy="{cy + 3}" r="10" fill="{c}"/>'
            f'<path d="M{cx - 8} {cy - 2} L{cx - 2} {cy + 1} M{cx + 8} {cy - 2} L{cx + 2} {cy + 1}" stroke="#f5f0e6" stroke-width="2" stroke-linecap="round"/>')


def bubble(x, y, w=64, h=34, fill='#fffbf0', stroke='#8a6a3c'):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="9" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
            f'<path d="M{x + 12} {y + h - 1} l6 10 l6 -10" fill="{fill}" stroke="{stroke}" stroke-width="2"/>'
            f'<rect x="{x + 1.5}" y="{y + h - 3}" width="22" height="4" fill="{fill}"/>')


def paper(x, y, w=34, h=44, lines=3, tick=False):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="{PAPER}" stroke="#8a6a3c" stroke-width="2"/>'
    for i in range(lines):
        s += f'<rect x="{x + 6}" y="{y + 10 + i * 8}" width="{w - 12}" height="2.5" fill="#3a2a16" opacity="0.5"/>'
    if tick:
        s += f'<path d="M{x + 8} {y + h - 10} l5 5 l10 -11" stroke="#27ae60" stroke-width="3.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    return s


def scale(cx, cy, tilt):
    """A balance: tilt > 0 lowers the right pan."""
    ly, ry = cy + tilt, cy - tilt
    return (f'<rect x="{cx - 2}" y="{cy - 6}" width="4" height="60" fill="#5b5b60"/><rect x="{cx - 16}" y="{cy + 52}" width="32" height="5" rx="2" fill="#5b5b60"/>'
            f'<path d="M{cx - 38} {ly} L{cx + 38} {ry}" stroke="#5b5b60" stroke-width="4" stroke-linecap="round"/>'
            f'<path d="M{cx - 38} {ly} l-12 24 h24 z" fill="#d9a441" stroke="#8a6a3c" stroke-width="2"/>'
            f'<path d="M{cx + 38} {ry} l-12 24 h24 z" fill="#d9a441" stroke="#8a6a3c" stroke-width="2"/>')


def hand_stop(x, y):
    return (f'<rect x="{x}" y="{y}" width="30" height="36" rx="8" fill="#c58b63" stroke="{INK}" stroke-width="1.5"/>'
            f'<rect x="{x + 3}" y="{y - 16}" width="5" height="22" rx="2.5" fill="#c58b63" stroke="{INK}" stroke-width="1.2"/>'
            f'<rect x="{x + 10}" y="{y - 22}" width="5" height="28" rx="2.5" fill="#c58b63" stroke="{INK}" stroke-width="1.2"/>'
            f'<rect x="{x + 17}" y="{y - 20}" width="5" height="26" rx="2.5" fill="#c58b63" stroke="{INK}" stroke-width="1.2"/>'
            f'<rect x="{x + 24}" y="{y - 14}" width="5" height="20" rx="2.5" fill="#c58b63" stroke="{INK}" stroke-width="1.2"/>')


def cal(x, y):
    return (f'<rect x="{x}" y="{y}" width="40" height="40" rx="5" fill="#fff" stroke="#8a6a3c" stroke-width="2"/>'
            f'<rect x="{x}" y="{y}" width="40" height="11" rx="5" fill="#c0392b"/>'
            f'<rect x="{x + 8}" y="{y + 18}" width="8" height="7" fill="#3a2a16" opacity="0.5"/><rect x="{x + 22}" y="{y + 18}" width="8" height="7" fill="#3a2a16" opacity="0.5"/>'
            f'<rect x="{x + 8}" y="{y + 28}" width="8" height="7" fill="#3a2a16" opacity="0.5"/>')


def pad(x, y):
    return (f'<rect x="{x}" y="{y}" width="38" height="46" rx="3" fill="#fff" stroke="#8a6a3c" stroke-width="2"/>'
            f'<rect x="{x + 6}" y="{y + 10}" width="26" height="3" fill="#3a2a16" opacity="0.5"/>'
            f'<rect x="{x + 6}" y="{y + 18}" width="26" height="3" fill="#3a2a16" opacity="0.5"/>'
            f'<path d="M{x + 30} {y + 36} l14 -14 l5 5 l-14 14 l-8 3 z" fill="#d9a441" stroke="{INK}" stroke-width="1.4"/>')


def wall(x, y):
    return (f'<rect x="{x}" y="{y}" width="26" height="70" fill="#8c5a44" stroke="#5e3c2e" stroke-width="2"/>'
            f'<path d="M{x} {y + 18} h26 M{x} {y + 36} h26 M{x} {y + 54} h26" stroke="#5e3c2e" stroke-width="1.5"/>')


CARDS = {
    # The file leaps to the top plank while the consumer is at the lowest step.
    'skip_ahead': lambda: ladder(18, file_at=2, arrow=(0, 2), dim=(1,)) + ladder(178, file_at=1),
    # The file goes back down to a step he has already passed.
    'step_behind': lambda: ladder(18, file_at=0, arrow=(1, 0)) + ladder(178, file_at=2),
    # A promise said aloud with nothing written / a docket slip with a number.
    'verbal': lambda: person(60, '#b4533c', 'angry') + bubble(84, 44, 60, 32) + '<path d="M96 60 q8 -8 16 0 q8 8 16 0" stroke="#8a6a3c" stroke-width="2.4" fill="none"/>'
                      + person(214, '#3f7f9e') + paper(246, 76, 40, 52, 4, tick=True),
    # "কালই হয়ে যাবে": a calendar with a hasty tick vs a note and a question mark.
    'false_promise': lambda: person(54, '#3f7f9e') + bubble(82, 48, 60, 40) + cal(92, 52)
                            + '<path d="M100 76 l5 5 l12 -12" stroke="#c0392b" stroke-width="3.4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
                            + person(214, '#3f7f9e') + pad(252, 90),
    # Shouting back vs a calm hand over a form.
    'arguing': lambda: person(52, '#b4533c', 'angry') + person(112, '#3f7f9e', 'angry') + cloud(82, 40, red=True)
                      + person(212, '#b4533c', 'angry') + paper(250, 86, 40, 52, 3) + '<path d="M240 112 h14" stroke="#27ae60" stroke-width="3" stroke-linecap="round"/>',
    # "কেস করে কিছু হবে না" (a wall) vs the scales tipping toward the consumer.
    'case_myth': lambda: person(48, '#b4533c', 'angry') + wall(96, 94) + scale(224, 78, 14),
    # CGRF is not the end: a stair that stops at a wall vs one that goes on.
    'final_word': lambda: ladder(18, file_at=1, dim=(2,)) + wall(116, 72) + ladder(178, file_at=2),
    # A hand that stops a complaint vs a form handed over.
    'no_complain': lambda: paper(36, 96, 38, 50, 3) + hand_stop(92, 92)
                          + paper(206, 96, 40, 52, 3) + '<path d="M250 122 h26" stroke="#27ae60" stroke-width="4" stroke-linecap="round"/>'
                          + '<path d="M268 114 l10 8 l-10 8" stroke="#27ae60" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    # Another step's line for this consumer: the file on the wrong plank, then the matching one.
    'wrong_forum': lambda: ladder(18, file_at=2, dim=(0, 1)) + ladder(178, file_at=0),
    # The coworker's myth 1: "he cannot do anything" (a shut door) vs the scales.
    'listen_case': lambda: person(48, '#c2457e', 'calm', skin='#9a6a48') + wall(96, 94) + scale(224, 78, 14),
    # The coworker's myth 2: a complaint slip with a red "job gone" cross vs a steady worker.
    'listen_job': lambda: paper(40, 92, 40, 52, 3) + '<path d="M84 100 l30 30 M114 100 l-30 30" stroke="#c0392b" stroke-width="5" stroke-linecap="round"/>'
                         + person(212, '#3f7f9e') + paper(248, 94, 34, 44, 3, tick=True),
}


def main(root):
    out = os.path.join(root, OUT)
    os.makedirs(out, exist_ok=True)
    want = {k + '.svg' for k in CARDS}
    for f in os.listdir(out):
        if f.endswith('.svg') and f not in want:
            os.remove(os.path.join(out, f))
    for name, draw in CARDS.items():
        with open(os.path.join(out, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(frame(draw()))
    print(f'wrote {len(CARDS)} pictures to {out}')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
