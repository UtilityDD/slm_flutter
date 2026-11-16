"""Picture cards for lesson 8.2 শেখা ("সাপ্লাই কোড (Supply Code): গ্রাহক পরিষেবার নিয়মাবলী").

python -I tool/m8_board82_art.py .

Writes assets/game/art/m8_board82/*.svg (200 x 220 scene cards, drawn edge to
edge, the gradient style of tool/m6_board63_art.py). No words in the art; no
logos (ruling M8-11): the only marks a worker reads are a meter box's LCD, a
calendar's date cells, a notice's green stamp and a shop's sign plate, all
without writing.

What the cards show comes from lesson 8.2 (live text, tool/all_training_chapters_bn.json)
and the Module 8 rulings only:
  1. wayleave: written consent of the landowner (ওয়ে-লিভ, pro tip 1 of 8.2
     section 1); a route along a road edge, off private plots;
  2. meter: the meter box outside, read from the doorstep; the lineman's
     marking from a company order; traps: a bedroom meter, a roof meter room,
     a consumer's pointing, a meter unscrewed without an order;
  3. notice: a dated written notice beside a calendar (15 clear days, Sec 56);
     the reading and seal state noted first; traps: no notice, a shouted
     warning, a notice served days ago, the notebook shut;
  4. hook: evidence first (pro tip 1 of the lesson: a video with the pole and
     the hooking wire in frame); the seizure list (জব্দ তালিকা) at the site;
     traps: the wire pulled down first, a frame with only a house wall, a bare
     hand on the hook before the tester shows 0 V (deadly, N4 / X1), a notice
     form handed over and the hook left on;
  5. sec126: the গৃহস্থ meter card at a shop; the provisional bill with an
     objection written on it (Sec 126 provisional, then final after the
     hearing); traps: a police van for an FIR, a final bill on the spot, a
     shoving match (pro tip 2: no quarrel).

Round 4 of the spec (reconnection and dismantling) left the board (ruling
M8-21: five rounds); do_8_2_a plays it in full.

Fairness (GAME_LEVEL_PLAYBOOK §4, as tool/m6_board63_art.py): every card of a
round shares one stage (sky, ground, pole, house, meter box, the worker with
his kit), so every colour the safe card draws is drawn on every trap. The
script checks every card of a round draws the same colour tokens and the same
backdrop, and deletes only its own stale cards.
"""

import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board82_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board82')
W, H = 200, 220
GY = 180  # ground line

# Palette (every token here is drawn on every card of its round, by the stage).
SHIRT = '#1F5F8F'
SHIRT2 = '#8A5A2B'
SKIN = '#A86E48'
PANTS = '#2A3442'
HELMET = '#FFD34E'
BOOT = '#1C1F24'
GLOVE = '#2A2D33'
PAPER = '#F4F1E6'
INK = '#4A5560'
RED = '#D8402F'
GREEN = '#3E9B4F'
YELLOW = '#E8C830'
WIRE = '#2B3138'
WIN_LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
PHONE = '#15191E'

DEFS = """<defs>
  <linearGradient id="field" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9CC3DF"/><stop offset="1" stop-color="#E6EEDF"/></linearGradient>
  <linearGradient id="yard" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9D8E2"/><stop offset="1" stop-color="#E9E6DA"/></linearGradient>
  <linearGradient id="day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7FB2DA"/><stop offset="1" stop-color="#D6E7F0"/></linearGradient>
  <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B7A9C9"/><stop offset="1" stop-color="#EFE3D6"/></linearGradient>
  <linearGradient id="market" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#D9C9A8"/><stop offset="1" stop-color="#F3EBDB"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9DBB72"/><stop offset="1" stop-color="#7E9C55"/></linearGradient>
  <linearGradient id="house" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D9C3A0"/><stop offset="1" stop-color="#B9A07A"/></linearGradient>
  <linearGradient id="roof" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A4E35"/><stop offset="1" stop-color="#743A28"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8E979E"/><stop offset="0.5" stop-color="#C6CED4"/><stop offset="1" stop-color="#7C858C"/></linearGradient>
  <linearGradient id="box" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9EDF0"/><stop offset="1" stop-color="#AEB8C0"/></linearGradient>
  <linearGradient id="lcd" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9E2B8"/><stop offset="1" stop-color="#A9C997"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="panel" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9AA5AE"/><stop offset="1" stop-color="#7D8891"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""

# Every colour token the stage draws (the test compares tokens per round).
BACKS = {'wayleave': 'field', 'meter': 'yard', 'notice': 'day', 'hook': 'dusk', 'sec126': 'market'}


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def fill(c):
    return f'fill="{c}"'


def rect(x, y, w, h, c, extra=''):
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" {fill(c)} {extra}/>'


def line(x1, y1, x2, y2, c, w=2.0, extra=''):
    return f'<path d="M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}" stroke="{c}" stroke-width="{f(w)}" stroke-linecap="round" fill="none" {extra}/>'


def circ(x, y, r, c):
    return f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(r)}" {fill(c)}/>'


def person(x, hands, shirt=SHIRT, s=1.0, bare_hand=False, head_turn=0):
    """A trainee (or a consumer) standing on GY; [hands] = two hand points (left, right)."""
    h = 62 * s
    top = GY - h
    out = []
    out.append(rect(x - 6 * s, GY - 30 * s, 5 * s, 30 * s, PANTS))
    out.append(rect(x + 1 * s, GY - 30 * s, 5 * s, 30 * s, PANTS))
    out.append(rect(x - 8 * s, GY - 3 * s, 8 * s, 3 * s, BOOT))
    out.append(rect(x + 0 * s, GY - 3 * s, 8 * s, 3 * s, BOOT))
    sh_l = (x - 9 * s, top + 20 * s)
    sh_r = (x + 9 * s, top + 20 * s)
    out.append(rect(x - 9 * s, top + 16 * s, 18 * s, 24 * s, shirt))
    hl, hr = hands
    out.append(line(sh_l[0], sh_l[1], hl[0], hl[1], shirt, 5 * s))
    out.append(line(sh_r[0], sh_r[1], hr[0], hr[1], shirt, 5 * s))
    out.append(circ(hl[0], hl[1], 2.8 * s, GLOVE))
    out.append(circ(hr[0], hr[1], 2.8 * s, SKIN if bare_hand else GLOVE))
    out.append(circ(x + head_turn * s, top + 8 * s, 7 * s, SKIN))
    out.append(f'<path d="M{f(x - 8 * s + head_turn * s)} {f(top + 6 * s)} Q{f(x + head_turn * s)} {f(top - 8 * s)} {f(x + 8 * s + head_turn * s)} {f(top + 6 * s)} Z" {fill(HELMET)}/>')
    return ''.join(out), (sh_l, sh_r)


def hands_down(x, s=1.0):
    h = 62 * s
    top = GY - h
    return [(x - 11 * s, top + 42 * s), (x + 11 * s, top + 42 * s)]


def stage(back, worker_x=92):
    """The shared stage of a round: sky, ground, the pole with its hardware, the
    house wall with the meter box, the trainee with his kit (clipboard, gloves,
    helmet, the phone in the pocket)."""
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']
    out.append(rect(0, GY, W, H - GY, 'url(#ground)'))
    # house wall (right), roof, window, meter box with LCD and two lamps
    out.append(rect(150, 92, 48, GY - 92, 'url(#house)'))
    out.append(f'<path d="M146 94 L174 66 L202 94 Z" fill="url(#roof)"/>')
    out.append(rect(156, 104, 14, 12, WIN_LIT))
    out.append(rect(156, 124, 14, 12, WIN_OFF))
    out.append(rect(180, 104, 10, 22, PAPER))
    out.append(rect(178, 134, 14, 18, 'url(#box)', 'rx="2"'))
    out.append(rect(180, 138, 10, 5, 'url(#lcd)'))
    out.append(circ(181.5, 146, 1.6, RED))
    out.append(circ(187.5, 146, 1.6, GREEN))
    # pole (left): pole, cross arm with steel hardware, a yellow earth tag at its foot
    out.append(rect(36, 30, 6, GY - 30, 'url(#pole)'))
    out.append(rect(26, 36, 26, 4, 'url(#steel)'))
    out.append(line(29, 40, 27, 58, INK, 1.4))
    out.append(circ(29, 62, 2.6, 'url(#steel)'))
    out.append(rect(34, GY - 10, 10, 9, YELLOW, 'rx="1"'))
    # the trainee's kit: clipboard and phone (kept in the stage)
    body, _ = person(worker_x, hands_down(worker_x))
    out.append(body)
    out.append(rect(worker_x + 10, 110, 2.5, 10, PHONE, 'rx="0.6"'))
    # the service drop from the pole to the house, a cloth on the line, the kerb
    out.append(wire([(42, 40), (100, 52), (150, 70)]))
    out.append(rect(186, 96, 7, 9, SHIRT2, 'rx="1"'))
    out.append(rect(150, GY - 6, 48, 6, 'url(#panel)'))
    return out


def close(out):
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def paper(x, y, w, h, rot=0, lines=3, stamp=None):
    g = [f'<g transform="rotate({f(rot)} {f(x + w / 2)} {f(y + h / 2)})">', rect(x, y, w, h, PAPER, 'rx="1"')]
    for i in range(lines):
        yy = y + 6 + i * (h - 12) / max(1, lines - 1 if lines > 1 else 1)
        g.append(line(x + 4, yy, x + w - 4, yy, INK, 1.0))
    if stamp:
        g.append(circ(x + w - 9, y + h - 9, 4.5, stamp))
    g.append('</g>')
    return ''.join(g)


def calendar(x, y, marks):
    """A 5 x 4 date grid on the wall; [marks] = list of (cell, colour) — a green
    dated notice and the red 'today' cell (cells are numbered row by row)."""
    out = [rect(x, y, 46, 40, PAPER, 'rx="2"')]
    for i in range(20):
        cx = x + 5 + (i % 5) * 8.2
        cy = y + 6 + (i // 5) * 8.4
        out.append(rect(cx, cy, 5.4, 5.4, INK, 'opacity="0.35"'))
    for cell, col in marks:
        cx = x + 5 + (cell % 5) * 8.2 + 2.7
        cy = y + 6 + (cell // 5) * 8.4 + 2.7
        out.append(circ(cx, cy, 4.0, col))
    return ''.join(out)


def meter_box(x, y, w=16, h=20):
    return (rect(x, y, w, h, 'url(#box)', 'rx="2"') + rect(x + 3, y + 4, w - 6, 5, 'url(#lcd)')
            + circ(x + 4, y + h - 4, 1.5, RED) + circ(x + w - 4, y + h - 4, 1.5, GREEN))


def wire(points, c=WIRE, w=1.6):
    d = 'M' + ' L'.join(f'{f(px)} {f(py)}' for px, py in points)
    return f'<path d="{d}" stroke="{c}" stroke-width="{f(w)}" fill="none" stroke-linecap="round"/>'


def road(y=GY + 14):
    return rect(0, y, W, 18, 'url(#panel)') + line(0, y + 9, W, y + 9, INK, 1.2, 'stroke-dasharray="6 5"')


def cut_cutter(x, y):
    return line(x, y, x + 9, y + 6, 'url(#steel)', 2.4) + circ(x, y, 1.2, RED)


# ----------------------------------------------------------------------------
# Round 1: wayleave (ওয়ে-লিভ)
# ----------------------------------------------------------------------------

def wayleave_consent():
    o = stage(BACKS['wayleave'])
    o.append(paper(70, 86, 30, 38, rot=-6, lines=4, stamp=GREEN))
    o.append(line(58, 118, 146, 118, INK, 1.4))  # a gate line
    o.append(person(158, [(150, 126), (168, 136)], shirt=SHIRT2, s=0.92)[0])
    o.append(road())
    return close(o)


def wayleave_route():
    o = stage(BACKS['wayleave'])
    o.append(road(GY + 6))
    o.append(line(60, GY - 4, 128, GY - 4, INK, 1.0, 'stroke-dasharray="3 3"'))
    o.append(wire([(42, 50), (120, 62), (176, 70)]))
    o.append(paper(54, 96, 26, 32, rot=6, lines=3, stamp=GREEN))
    return close(o)


def wayleave_pit():
    o = stage(BACKS['wayleave'])
    o.append(f'<ellipse cx="60" cy="{GY - 1}" rx="13" ry="4" fill="{INK}"/>')
    o.append(line(72, 150, 84, 170, 'url(#steel)', 3.0))  # spade
    o.append(person(112, [(104, 118), (126, 118)], shirt=SHIRT2, s=0.92)[0])  # the owner shouting
    o.append(wire([(42, 60), (100, 70), (176, 92)]))
    return close(o)


def wayleave_nod():
    o = stage(BACKS['wayleave'])
    o.append(rect(64, GY - 28, 6, 28, 'url(#pole)'))  # a pole lying in the field
    o.append(wire([(72, 52), (120, 66), (176, 96)]))
    o.append(person(156, [(148, 120), (164, 120)], shirt=SHIRT2, s=0.92)[0])  # the owner nods
    return close(o)


def wayleave_shout():
    o = stage(BACKS['wayleave'])
    o.append(person(118, [(110, 118), (128, 110)], shirt=SHIRT2, s=0.94)[0])  # the neighbour
    o.append(line(124, 100, 128, 102, INK, 1))  # a raised palm
    o.append(rect(138, 124, 28, 2.4, INK))  # a fence
    o.append(wire([(42, 56), (176, 84)]))
    return close(o)


def wayleave_diag():
    o = stage(BACKS['wayleave'])
    o.append(line(44, 50, 170, 150, INK, 1.2, 'stroke-dasharray="4 3"'))
    o.append(rect(116, 118, 3, 60, INK))
    o.append(rect(86, 86, 3, 40, INK))
    o.append(wire([(42, 40), (176, 110)]))
    return close(o)


# ----------------------------------------------------------------------------
# Round 2: meter place (মিটার কোথায় বসবে)
# ----------------------------------------------------------------------------

def meter_outside():
    o = stage(BACKS['meter'])
    o.append(rect(152, 136, 22, 44, WIN_OFF, 'rx="2"'))  # the door
    o.append(meter_box(178, 128, 15, 18))
    o.append(person(120, hands_down(120), shirt=SHIRT2, s=0.9)[0])  # reads from the step
    return close(o)


def meter_slip():
    o = stage(BACKS['meter'])
    o.append(paper(64, 92, 30, 36, rot=-4, lines=4))  # the order slip
    o.append(meter_box(176, 124, 15, 18))
    o.append(person(104, [(100, 116), (118, 110)])[0])
    o.append(person(140, hands_down(140), shirt=SHIRT2, s=0.9)[0])  # the consumer watches
    return close(o)


def meter_bed():
    o = stage(BACKS['meter'])
    o.append(rect(118, 118, 60, 16, 'url(#panel)', 'rx="2"'))  # bed
    o.append(rect(118, 108, 4, 26, INK))
    o.append(meter_box(124, 96, 14, 18))
    o.append(person(72, hands_down(72), s=0.94)[0])
    return close(o)


def meter_roof():
    o = stage(BACKS['meter'])
    o.append(rect(70, 46, 56, 46, 'url(#house)'))  # a tall building's top
    o.append(rect(86, 26, 26, 22, 'url(#house)'))  # roof meter room
    o.append(meter_box(96, 34, 12, 14))
    o.append(person(44, hands_down(44), s=0.84)[0])
    return close(o)


def meter_point():
    o = stage(BACKS['meter'])
    o.append(person(120, [(104, 106), (144, 98)], shirt=SHIRT2, s=0.92)[0])  # consumer points
    o.append(meter_box(170, 118, 14, 18))
    o.append(line(78, 124, 98, 118, 'url(#steel)', 2.6))  # a drill
    o.append(person(70, [(78, 122), (92, 130)])[0])
    return close(o)


def meter_unscrew():
    o = stage(BACKS['meter'])
    o.append(meter_box(60, 150, 18, 22))  # the meter lying on the ground
    o.append(line(90, 118, 100, 124, 'url(#steel)', 2.4))
    o.append(person(118, [(104, 126), (126, 114)])[0])
    o.append(person(156, hands_down(156), shirt=SHIRT2, s=0.9)[0])  # consumer asked
    return close(o)


# ----------------------------------------------------------------------------
# Round 3: disconnection notice (বিল বাকি — লাইন কাটার আগে)
# ----------------------------------------------------------------------------

def notice_calendar():
    o = stage(BACKS['notice'])
    o.append(calendar(22, 44, [(2, GREEN), (19, RED)]))  # notice far back, today red
    o.append(paper(60, 110, 26, 30, rot=-6, lines=3))
    o.append(line(78, 116, 96, 112, INK, 1.2))
    return close(o)


def notice_read():
    o = stage(BACKS['notice'])
    o.append(paper(56, 100, 30, 36, rot=6, lines=5))  # the notebook open
    o.append(meter_box(172, 120, 14, 18))
    o.append(line(60, 136, 82, 130, INK, 1.2))
    return close(o)


def notice_none():
    o = stage(BACKS['notice'])
    o.append(wire([(120, 90), (150, 112)]))
    o.append(cut_cutter(106, 112))
    o.append(rect(110, 86, 6, 6, RED, 'rx="1"'))
    return close(o)


def notice_shout():
    o = stage(BACKS['notice'])
    o.append(person(118, [(106, 118), (128, 96)], shirt=SHIRT2, s=0.94)[0])  # shouting at the door
    o.append(rect(138, 120, 22, 40, WIN_OFF, 'rx="2"'))
    o.append(cut_cutter(112, 130))
    return close(o)


def notice_recent():
    o = stage(BACKS['notice'])
    o.append(calendar(22, 44, [(9, GREEN), (11, RED)]))  # notice a few days ago
    o.append(cut_cutter(84, 118))
    return close(o)


def notice_shut():
    o = stage(BACKS['notice'])
    o.append(rect(58, 110, 24, 32, PAPER, 'rx="2"'))  # notebook shut
    o.append(rect(58, 110, 24, 4, INK))
    o.append(meter_box(172, 120, 14, 18))
    o.append(cut_cutter(106, 118))
    return close(o)


# ----------------------------------------------------------------------------
# Round 4: hooking (হুকিং ধরা পড়েছে)
# ----------------------------------------------------------------------------

def hook_film():
    o = stage(BACKS['hook'])
    o.append(rect(64, 86, 18, 30, PHONE, 'rx="3"'))  # phone in hand, lens on pole
    o.append(circ(73, 90, 2.6, 'url(#steel)'))
    o.append(wire([(42, 64), (58, 60)], WIRE, 2))  # the hooking wire
    o.append(f'<path d="M44 66 Q52 74 60 66" stroke="url(#steel)" stroke-width="2" fill="none"/>')
    return close(o)


def hook_seize():
    o = stage(BACKS['hook'])
    o.append(paper(62, 96, 32, 40, rot=-4, lines=5))  # clipboard list at the site
    o.append(rect(60, 94, 36, 4, PHONE, 'rx="1"'))
    o.append(f'<path d="M44 64 Q54 74 60 64" stroke="url(#steel)" stroke-width="2" fill="none"/>')
    return close(o)


def hook_pull():
    o = stage(BACKS['hook'])
    o.append(wire([(42, 60), (62, 110), (72, 150)], WIRE, 2))  # pulled down, dangling
    o.append(rect(102, 124, 8, 14, PHONE, 'rx="1"'))  # phone in the pocket
    o.append(f'<path d="M44 64 Q52 74 60 64" stroke="url(#steel)" stroke-width="2" fill="none"/>')
    return close(o)


def hook_wall():
    o = stage(BACKS['hook'])
    o.append(f'<rect x="40" y="70" width="120" height="82" rx="6" fill="none" stroke="{INK}" stroke-width="3"/>')
    o.append(wire([(120, 104), (132, 130)], WIRE, 2))  # a loose wire end, no pole in frame
    return close(o)


def hook_hand():
    o = stage(BACKS['hook'])
    o.append(f'<path d="M44 64 Q52 74 60 64" stroke="url(#steel)" stroke-width="2" fill="none"/>')
    o.append(circ(58, 66, 3.6, SKIN))  # bare hand on the hook, no tester shown
    o.append(person(100, [(70, 80), (116, 114)], bare_hand=True, s=0.94)[0])
    return close(o)


def hook_walk():
    o = stage(BACKS['hook'])
    o.append(f'<path d="M44 64 Q52 74 60 64" stroke="url(#steel)" stroke-width="2" fill="none"/>')
    o.append(paper(132, 100, 24, 28, rot=8, lines=3))  # notice form held out
    o.append(person(92, [(86, 114), (118, 112)], head_turn=10)[0])  # walking off
    return close(o)


# ----------------------------------------------------------------------------
# Round 5: Sec 126 at a shop (দোকানে গৃহস্থের কানেকশন)
# ----------------------------------------------------------------------------

def sec_card():
    o = stage(BACKS['sec126'])
    o.append(rect(122, 66, 70, 26, YELLOW, 'rx="2"'))  # shop sign plate (no words)
    o.append(paper(70, 104, 26, 30, rot=-4, lines=3, stamp=GREEN))  # the meter card
    o.append(line(74, 98, 128, 74, INK, 1.2, 'stroke-dasharray="3 3"'))
    o.append(person(116, [(102, 104), (126, 90)], shirt=SHIRT2, s=0.92)[0])
    return close(o)


def sec_prov():
    o = stage(BACKS['sec126'])
    o.append(rect(122, 66, 70, 26, YELLOW, 'rx="2"'))
    o.append(paper(84, 100, 32, 36, rot=4, lines=5, stamp=GREEN))  # provisional bill
    o.append(line(124, 112, 140, 110, INK, 1.4))  # an objection written on it
    o.append(person(138, [(128, 118), (120, 110)], shirt=SHIRT2, s=0.92)[0])
    return close(o)


def sec_fir():
    o = stage(BACKS['sec126'])
    o.append(rect(124, 110, 64, 36, 'url(#panel)', 'rx="4"'))  # a van
    o.append(circ(152, 108, 3, RED))  # the van's lamp
    o.append(person(104, [(96, 120), (112, 120)], shirt=SHIRT2, s=0.92)[0])
    o.append(person(74, [(80, 116), (66, 110)], s=0.94)[0])
    return close(o)


def sec_final():
    o = stage(BACKS['sec126'])
    o.append(rect(122, 66, 70, 26, YELLOW, 'rx="2"'))
    o.append(paper(96, 106, 30, 32, rot=-10, lines=4, stamp=RED))  # a bill pushed on the spot
    o.append(person(138, [(124, 114), (110, 110)], shirt=SHIRT2, s=0.92)[0])
    return close(o)


def sec_shove():
    o = stage(BACKS['sec126'])
    o.append(person(106, [(94, 110), (116, 104)], shirt=SHIRT2, s=0.94)[0])
    o.append(person(144, [(132, 110), (120, 104)], s=0.94)[0])
    return close(o)


CARDS = {
    'wayleave_consent': wayleave_consent,
    'wayleave_route': wayleave_route,
    'wayleave_pit': wayleave_pit,
    'wayleave_nod': wayleave_nod,
    'wayleave_shout': wayleave_shout,
    'wayleave_diag': wayleave_diag,
    'meter_outside': meter_outside,
    'meter_slip': meter_slip,
    'meter_bed': meter_bed,
    'meter_roof': meter_roof,
    'meter_point': meter_point,
    'meter_unscrew': meter_unscrew,
    'notice_calendar': notice_calendar,
    'notice_read': notice_read,
    'notice_none': notice_none,
    'notice_shout': notice_shout,
    'notice_recent': notice_recent,
    'notice_shut': notice_shut,
    'hook_film': hook_film,
    'hook_seize': hook_seize,
    'hook_pull': hook_pull,
    'hook_wall': hook_wall,
    'hook_hand': hook_hand,
    'hook_walk': hook_walk,
    'sec126_card': sec_card,
    'sec126_prov': sec_prov,
    'sec126_fir': sec_fir,
    'sec126_final': sec_final,
    'sec126_shove': sec_shove,
}

TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')


def tokens(svg):
    return set(TOKEN.findall(svg.split('</defs>')[-1]))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in os.listdir(OUT):
        if name.endswith('.svg') and name.split('_')[0] in BACKS and name[:-4] not in CARDS:
            os.remove(os.path.join(OUT, name))
    by_round = {}
    for name, make in CARDS.items():
        svg = make()
        by_round.setdefault(name.split('_')[0], []).append((name, svg))
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg + '\n')
    # Fairness: every card of a round draws the same colour tokens and backdrop.
    for rnd, cards in by_round.items():
        union = set()
        for _, svg in cards:
            union |= tokens(svg)
        for name, svg in cards:
            missing = union - tokens(svg)
            if missing:
                raise SystemExit(f'{name}: colour tokens {sorted(missing)} not on every card of {rnd}')
    print(f'wrote {len(CARDS)} cards to {OUT}')


if __name__ == '__main__':
    main()
