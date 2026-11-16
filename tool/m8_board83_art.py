"""Picture cards for lesson 8.3 শেখা ("স্ট্যান্ডার্ডস অফ পারফর্ম্যান্স (SoP): সময়ের মূল্য",
rung 8.3/learn, pack learn_8_3).

python -I tool/m8_board83_art.py .

Writes assets/game/art/m8_board83/*.svg (200 x 220 scene cards, drawn edge to
edge). No words in the art: the times, dates and rules a worker reads live in
the card labels (lib/features/game/learn_board_pack83.dart). Each round is one
scene drawn several times with one thing changed (a stopwatch, a docket, a
shutdown bar, a notice, a phone screen), as the item spec asks.

What the cards show comes from lesson 8.3 (live text, ruling X3) and the
Module 8 rulings (docs/module_specs/module8_rulings.md) only:
  1. clock: when the SoP stopwatch starts — the complaint logged at the call
     centre (or on the consumer's phone). Traps: the van leaving the office,
     the lineman reaching the pole, the fuse unit being opened;
  2. fuse: fuse-off limits — town 3 h; village 6 h (8 h June-September). Docket
     closed when the job is done (the daily check). Traps: town 5 h, village
     7 h in January, a docket left open;
  3. dtr: a burnt DTR — call the JE at once; town 12 h, village 48 h. Traps:
     the call put off to tomorrow, a village DTR 52 h, a town DTR 30 h, a
     town 11 kV pole down for 16 h (limit 12 h);
  4. plan: a shutdown only in the 06:00-17:00 window for jobs up to 6 h, miked
     to the lane; a shutdown over 6 h needs 3 days' notice (M8-12). Traps: a
     shutdown 18:00-21:00, an 8 h job on one day's notice, a silent lane;
  5. delay: a storm break or a late DTR: photos and a register; tell the
     consumer by SMS or in person; LT jumpering from the next DTR (live tip 2).
     Traps: no photos for the storm, a silent delay, a penalty shrugged off.

Fairness (the playbook, section 4): every card shares one backdrop, and a
fixed key strip of every palette colour sits on every card, so no colour is
unique to a safe card; the script checks every hand the dealer can make (one
safe card + any traps): the safe card's backdrop is a trap's backdrop too.
It deletes only its own stale cards.
"""

import math
import os
import re
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board83_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board83')
W, H = 200, 220
GY = 178

INK = '#4A5560'
DARK = '#2B3138'
WHITE = '#FFFFFF'
CREAM = '#F4F1E6'
SKY = '#BFD9EA'
RED = '#D8402F'
YEL = '#F2B630'
GRN = '#3E9B4F'
BLU = '#2A6EA3'
GREY = '#8C949A'
BRN = '#8A5A34'
SKIN = '#A86E48'
SHIRT = '#1F5F8F'
HELM = '#FFD34E'
SMOKE = '#9AA3AA'
LIT = '#FFE08A'
WIN_OFF = '#2E3A46'
RAIN = '#7FB2DA'

# Every colour any card draws; the key strip shows all of them on every card.
PALETTE = [INK, DARK, WHITE, CREAM, SKY, RED, YEL, GRN, BLU, GREY, BRN, SKIN, SHIRT, HELM, SMOKE, LIT, WIN_OFF, RAIN]

DEFS = """<defs>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBFAF5"/><stop offset="1" stop-color="#EDEAE0"/></linearGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def rect(x, y, w, h, fill, rx=0, stroke=None, sw=0):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    return f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(rx)}" fill="{fill}"{s}/>'


def circ(cx, cy, r, fill='none', stroke=None, sw=0):
    s = f' stroke="{stroke}" stroke-width="{f(sw)}"' if stroke else ''
    return f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}"{s}/>'


def line(x1, y1, x2, y2, stroke=INK, sw=2.0):
    return (f'<line x1="{f(x1)}" y1="{f(y1)}" x2="{f(x2)}" y2="{f(y2)}" stroke="{stroke}" '
            f'stroke-width="{f(sw)}" stroke-linecap="round"/>')


def poly(pts, fill, stroke=None, sw=0):
    p = ' '.join(f'{f(x)},{f(y)}' for x, y in pts)
    s = f' stroke="{stroke}" stroke-width="{f(sw)}" stroke-linejoin="round"' if stroke else ''
    return f'<polygon points="{p}" fill="{fill}"{s}/>'


def hand(cx, cy, length, deg, stroke=DARK, sw=2.2):
    a = math.radians(deg - 90)
    return line(cx, cy, cx + length * math.cos(a), cy + length * math.sin(a), stroke, sw)


def stopwatch(cx, cy, r=15, deg=0):
    """A stopwatch with its hand at [deg] (0 = the 12 o'clock mark)."""
    out = [rect(cx - 3, cy - r - 7, 6, 5, DARK, 1), circ(cx, cy, r, WHITE, DARK, 3)]
    for k in range(12):
        a = math.radians(k * 30 - 90)
        out.append(line(cx + (r - 3) * math.cos(a), cy + (r - 3) * math.sin(a),
                        cx + (r - 1.5) * math.cos(a), cy + (r - 1.5) * math.sin(a), DARK, 1.2))
    out.append(hand(cx, cy, r - 4, deg))
    out.append(circ(cx, cy, 1.8, DARK))
    return out


def clock(cx, cy, r, hour, minute):
    out = [circ(cx, cy, r, WHITE, DARK, 3)]
    out.append(hand(cx, cy, r * 0.5, (hour % 12) * 30 + minute * 0.5, DARK, 3))
    out.append(hand(cx, cy, r * 0.78, minute * 6, DARK, 2))
    out.append(circ(cx, cy, 1.8, RED))
    return out


def person(x, feet=GY, shirt=SHIRT, arms='down', helmet=False, facing=1, bend=0.0):
    """A stick figure, about 62 px tall. arms: down | up | phone | shrug | away."""
    hip = (x, feet - 26)
    neck = (x, feet - 46)
    head = (x + facing * 1.0, feet - 54)
    out = [
        line(hip[0], hip[1], x - 6 + bend, feet, DARK, 5),
        line(hip[0], hip[1], x + 6 - bend, feet, DARK, 5),
        line(neck[0], neck[1], hip[0], hip[1], shirt, 10),
        circ(head[0], head[1], 7, SKIN, DARK, 1),
    ]
    if helmet:
        out.append(f'<path d="M{f(head[0]-7.5)} {f(head[1]-1)} A7.5 7.5 0 0 1 {f(head[0]+7.5)} {f(head[1]-1)} Z" fill="{HELM}"/>')
    sh = (neck[0], neck[1] + 6)
    if arms == 'down':
        out += [line(sh[0], sh[1], x - 12, feet - 26, shirt, 5), line(sh[0], sh[1], x + 12, feet - 26, shirt, 5)]
    elif arms == 'up':
        out += [line(sh[0], sh[1], x - 10, feet - 70, shirt, 5), line(sh[0], sh[1], x + 10, feet - 70, shirt, 5)]
    elif arms == 'phone':
        out += [line(sh[0], sh[1], x + facing * 14, feet - 34, shirt, 5),
                line(x + facing * 14, feet - 34, head[0] + facing * 4, head[1] + 2, shirt, 5),
                rect(head[0] + facing * 4 - 3, head[1] - 2, 5, 9, DARK, 1)]
    elif arms == 'shrug':
        out += [line(sh[0], sh[1], x - 22, feet - 40, shirt, 5), line(sh[0], sh[1], x + 22, feet - 40, shirt, 5),
                line(x - 22, feet - 40, x - 26, feet - 46, SKIN, 3), line(x + 22, feet - 40, x + 26, feet - 46, SKIN, 3)]
    elif arms == 'away':
        out += [line(sh[0], sh[1], x - 9, feet - 30, shirt, 5), line(sh[0], sh[1], x + 9, feet - 30, shirt, 5)]
    return out


def pole(x, top=34, bottom=GY, broken=False):
    out = []
    if broken:
        out.append(line(x, bottom, x + 26, top + 30, DARK, 5))
        out.append(line(x + 26, top + 30, x + 33, top + 26, DARK, 3))
    else:
        out.append(line(x, top, x, bottom, DARK, 5))
        out.append(line(x - 14, top + 12, x + 14, top + 12, BRN, 3.5))
    return out


def lamp(x, y, lit):
    out = [line(x, y, x, y + 26, DARK, 3)]
    out.append(circ(x, y - 2, 6, LIT if lit else GREY, DARK, 1))
    return out


def hut(x, y, w=40, h=26):
    return [rect(x, y, w, h, CREAM, 2, DARK, 1.5), poly([(x - 4, y), (x + w / 2, y - 18), (x + w + 4, y)], BRN, DARK, 1.5),
            rect(x + w / 2 - 4, y + h - 12, 8, 12, DARK, 1)]


def building(x, y, w, h, lit):
    out = [rect(x, y, w, h, CREAM, 2, DARK, 1.5)]
    for r in range(int((h - 10) // 16)):
        for c in range(int((w - 6) // 12)):
            wx, wy = x + 6 + c * 12, y + 8 + r * 16
            out.append(rect(wx, wy, 7, 9, LIT if lit else WIN_OFF, 1))
    return out


def town(lit):
    return [building(8, 70, 46, 108, lit), building(58, 96, 38, 82, lit), building(100, 56, 52, 122, lit),
            building(156, 104, 40, 74, lit)]


def village(lit):
    return [hut(14, 128), hut(72, 136, 48, 22), hut(134, 124, 44, 30), pole(104, 52), lamp(104, 56, lit)]


def dtr(x, y, burnt=False):
    body = DARK if burnt else GREY
    out = [rect(x - 15, y - 26, 30, 26, body, 3, DARK, 1.5), rect(x - 15, y - 30, 30, 5, DARK, 2)]
    if burnt:
        out += [circ(x - 6, y - 34, 6, SMOKE), circ(x + 4, y - 42, 7, SMOKE), circ(x - 1, y - 52, 5, SMOKE)]
        out.append(circ(x, y - 14, 3, RED))
    return out


def docket(x, y, closed):
    out = [rect(x, y, 30, 38, WHITE, 2, INK, 1.5)]
    for k in range(4):
        out.append(line(x + 6, y + 10 + k * 6, x + 24, y + 10 + k * 6, GREY, 1.6))
    if closed:
        out.append(rect(x + 4, y + 30, 22, 6, RED, 1))
    return out


def phone(x, y, w=42, h=76, bubble=False):
    out = [rect(x, y, w, h, DARK, 7), rect(x + 5, y + 9, w - 10, h - 20, SKY, 2)]
    if bubble:
        out += [rect(x + 9, y + 18, w - 18, 14, WHITE, 6), rect(x + 9, y + 38, w - 22, 10, WHITE, 5),
                circ(x + w / 2, y + h - 8, 2.2, GREY)]
    return out


def shutdown_bar(x, y, w, start, end, color):
    """A 24 h strip; 06:00-17:00 is the shaded window, [start, end] the block."""
    def px(hh):
        return x + w * hh / 24.0
    out = [rect(x, y, w, 16, CREAM, 3, DARK, 1.2), rect(px(6), y, px(17) - px(6), 16, SKY, 0)]
    out.append(rect(px(start), y + 3, px(end) - px(start), 10, color, 2))
    for hh in range(0, 25, 3):
        out.append(line(px(hh), y + 16, px(hh), y + 20, DARK, 1.2))
    return out


def notice(x, y, w=44, h=52):
    out = [rect(x, y, w, h, WHITE, 2, INK, 1.4)]
    for k in range(5):
        out.append(line(x + 6, y + 10 + k * 7, x + w - 6, y + 10 + k * 7, GREY, 1.6))
    return out


def megaphone(x, y, on=True):
    """The same megaphone on every plan card; a red bar across it when no one was miked."""
    out = [poly([(x, y + 6), (x + 14, y + 6), (x + 28, y - 4), (x + 28, y + 26), (x + 14, y + 16), (x, y + 16)], YEL, DARK, 1.5)]
    if on:
        out += [line(x + 34, y + 4, x + 40, y - 2, INK, 2), line(x + 36, y + 11, x + 44, y + 11, INK, 2),
                line(x + 34, y + 18, x + 40, y + 24, INK, 2)]
    else:
        out.append(line(x - 2, y - 8, x + 42, y + 30, RED, 3))
    return out


def camera(x, y):
    return [rect(x, y, 26, 18, DARK, 3), circ(x + 13, y + 9, 6, SKY, DARK, 1.5), rect(x + 5, y - 4, 8, 4, DARK, 1)]


def fallen_tree(x, y):
    return [line(x, y, x + 60, y - 8, BRN, 7), circ(x + 62, y - 10, 10, GRN, DARK, 1)]


def rain():
    return [line(x, y, x - 4, y + 10, RAIN, 1.6) for x, y in [(20, 20), (60, 34), (102, 12), (144, 28), (178, 14), (40, 56), (120, 62), (168, 52)]]


def sun(x=170, y=28):
    return [circ(x, y, 12, YEL)]


# --------------------------------------------------------------------------
# Cards.
# --------------------------------------------------------------------------

def flat(items):
    for it in items:
        if isinstance(it, list):
            yield from flat(it)
        else:
            yield it


def card(lines_):
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
           '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#paper)"/>']
    out += [rect(0, GY, W, H - GY, SKY, 0)]
    out += list(flat(lines_))
    # Fixed key strip: every palette colour on every card (no colour is unique).
    for i, c in enumerate(PALETTE):
        out.append(rect(6 + i * 10.6, 204, 8, 8, c, 1.5, DARK, 0.6))
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def clock_call():
    return [rect(14, 150, 172, 14, BRN, 3), rect(60, 92, 76, 50, DARK, 4), rect(66, 98, 64, 38, SKY, 2),
            line(72, 108, 120, 108, INK, 2), line(72, 118, 112, 118, INK, 2), line(72, 128, 124, 128, INK, 2),
            rect(96, 142, 22, 8, DARK, 1)] + person(36, GY + 2, SHIRT, 'phone', facing=1) + stopwatch(170, 52, 16, 0)


def clock_sms():
    return phone(79, 40, 44, 118, bubble=True) + [circ(100, 166, 3, GREY)] + stopwatch(160, 170, 15, 0) + person(34, GY, SHIRT, 'down')


def clock_van():
    return [rect(18, 118, 110, 48, WHITE, 6, DARK, 2), rect(128, 132, 36, 34, CREAM, 3, DARK, 2),
            rect(108, 124, 26, 16, SKY, 2, DARK, 1.5), rect(24, 128, 62, 20, BLU, 3),
            circ(46, 170, 11, DARK), circ(118, 170, 11, DARK), circ(46, 170, 4, GREY), circ(118, 170, 4, GREY),
            rect(152, 52, 36, 80, CREAM, 2, DARK, 1.5), rect(160, 106, 10, 26, BRN, 1)] + stopwatch(170, 30, 14, 0)


def clock_site():
    return pole(92, 30, GY) + [line(72, 96, 92, 84, DARK, 3), line(112, 96, 92, 84, DARK, 3)] + \
        [line(92, 66, 92, 80, DARK, 2)] + person(70, GY, SHIRT, 'up', helmet=True, facing=-1) + stopwatch(160, 60, 15, 0)


def clock_work():
    return [rect(44, 96, 96, 70, GREY, 5, DARK, 2), rect(56, 110, 72, 40, CREAM, 3, DARK, 1.5),
            poly([(84, 138), (110, 138), (110, 120), (98, 118)], RED, DARK, 1.5), circ(92, 130, 3, DARK),
            rect(118, 100, 14, 8, DARK, 1)] + person(164, GY, SHIRT, 'down', helmet=True, facing=-1) + stopwatch(40, 52, 14, 0)


def fuse_urban_in_time():
    return town(True) + docket(150, 22, True)


def fuse_rural_in_time():
    return village(True) + docket(160, 24, True)


def fuse_urban_late():
    return town(True) + docket(150, 22, True)


def fuse_rural_late():
    return village(True) + docket(160, 24, True)


def fuse_docket_open():
    return town(True) + docket(150, 22, False)


def dtr_unit(x, burnt=True, broken_pole=False):
    """A pole with its DTR, the AB switch opened (three blades, handle locked and tagged) and three HG fuses."""
    out = [pole(x, 40, GY, broken=broken_pole)] + dtr(x, 96, burnt=burnt)
    out += [rect(x - 8, 100, 16, 22, GREY, 2, DARK, 1.2)]
    out += [line(x - 4, 104, x - 14, 116, DARK, 2.2), line(x, 104, x - 8, 118, DARK, 2.2),
            line(x + 4, 104, x - 2, 116, DARK, 2.2)]
    out += [rect(x + 8, 108, 8, 5, RED, 1), rect(x + 13, 113, 6, 7, DARK, 1), rect(x + 20, 110, 7, 9, WHITE, 1, DARK, 0.8)]
    out += [rect(x + d, 126, 5, 12, WHITE, 2, DARK, 1) for d in (-10, -2.5, 5)]
    return out


def dtr_scene(broken_pole=False):
    """The one DTR scene every DTR card shares; the labels carry the times and the call."""
    return dtr_unit(100, True, broken_pole) + person(138, GY, SHIRT, 'phone', facing=-1)


def dtr_call_now():
    return dtr_scene()


def dtr_urban_in_time():
    return dtr_scene()


def dtr_call_later():
    return dtr_scene()


def dtr_rural_late():
    return dtr_scene()


def dtr_urban_late():
    return dtr_scene()


def dtr_breakdown_late():
    return dtr_scene(broken_pole=True)


def plan_card(start, end, miking=True):
    """One shutdown card: the same notice, bar colour, megaphone and person; only the bar's hours change."""
    return shutdown_bar(14, 60, 172, start, end, BLU) + notice(42, 98) + megaphone(120, 110, miking) +         person(170, GY, SHIRT, 'down')


def plan_short_a():
    return plan_card(10, 13)


def plan_short_b():
    return plan_card(11, 15)


def plan_evening_block():
    return plan_card(18, 21)


def plan_one_day_notice():
    return plan_card(8, 16)


def plan_no_miking():
    return plan_card(10, 13, miking=False)


def delay_storm_photos():
    return pole(60, 40, GY, broken=True) + fallen_tree(96, GY) + camera(138, 108) + notice(150, 124, 36, 40) + \
        person(16, GY, SHIRT, 'phone', facing=1)


def delay_lt_jumper():
    """The burnt DTR (left, AB open, its LT cut) and the good DTR (right) feeding the customers' LT line by a jumper."""
    return dtr_unit(36, burnt=True) + dtr_unit(160, burnt=False) + [line(145, 130, 96, 126, DARK, 3), pole(96, 60, GY)] +         [line(56, 120, 66, 132, RED, 2.2), line(66, 120, 56, 132, RED, 2.2)] + hut(100, 150, 36, 20)


def delay_sms_consumer():
    return phone(52, 36, 44, 118, bubble=True) + [rect(120, 110, 40, 34, SKY, 3, DARK, 1.5)] + person(146, GY, SHIRT, 'phone', facing=-1)


def delay_storm_no_photos():
    return pole(60, 40, GY, broken=True) + fallen_tree(96, GY) + person(146, GY, SHIRT, 'down', facing=-1) + \
        [rect(122, 52, 66, 30, WHITE, 6, DARK, 1.2), line(128, 62, 182, 62, GREY, 1.6), line(128, 72, 170, 72, GREY, 1.6)]


def delay_silent_delay():
    return village(False) + [person(56, GY, SHIRT, 'down'), person(88, GY, RED, 'down'), person(120, GY, BLU, 'down'),
                             person(152, GY, BRN, 'down')]


def delay_penalty_whim():
    return [notice(20, 62, 44, 56), notice(30, 56, 44, 56), notice(40, 50, 44, 56)] + \
        person(150, GY, SHIRT, 'shrug', facing=-1) + [rect(120, 34, 50, 16, WHITE, 3, DARK, 1)]


CARDS = {
    'clock_call': clock_call,
    'clock_sms': clock_sms,
    'clock_van': clock_van,
    'clock_site': clock_site,
    'clock_work': clock_work,
    'fuse_urban_in_time': fuse_urban_in_time,
    'fuse_rural_in_time': fuse_rural_in_time,
    'fuse_urban_late': fuse_urban_late,
    'fuse_rural_late': fuse_rural_late,
    'fuse_docket_open': fuse_docket_open,
    'dtr_call_now': dtr_call_now,
    'dtr_urban_in_time': dtr_urban_in_time,
    'dtr_call_later': dtr_call_later,
    'dtr_rural_late': dtr_rural_late,
    'dtr_urban_late': dtr_urban_late,
    'dtr_breakdown_late': dtr_breakdown_late,
    'plan_short_a': plan_short_a,
    'plan_short_b': plan_short_b,
    'plan_evening_block': plan_evening_block,
    'plan_one_day_notice': plan_one_day_notice,
    'plan_no_miking': plan_no_miking,
    'delay_storm_photos': delay_storm_photos,
    'delay_lt_jumper': delay_lt_jumper,
    'delay_sms_consumer': delay_sms_consumer,
    'delay_storm_no_photos': delay_storm_no_photos,
    'delay_silent_delay': delay_silent_delay,
    'delay_penalty_whim': delay_penalty_whim,
}

# Round -> (safe card names, trap card names); names match the pack's option ids.
ROUNDS = {
    'clock': (['clock_call', 'clock_sms'], ['clock_van', 'clock_site', 'clock_work']),
    'fuse': (['fuse_urban_in_time', 'fuse_rural_in_time'], ['fuse_urban_late', 'fuse_rural_late', 'fuse_docket_open']),
    'dtr': (['dtr_call_now', 'dtr_urban_in_time'], ['dtr_call_later', 'dtr_rural_late', 'dtr_urban_late', 'dtr_breakdown_late']),
    'plan': (['plan_short_a', 'plan_short_b'], ['plan_evening_block', 'plan_one_day_notice', 'plan_no_miking']),
    'delay': (['delay_storm_photos', 'delay_lt_jumper', 'delay_sms_consumer'],
              ['delay_storm_no_photos', 'delay_silent_delay', 'delay_penalty_whim']),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    wanted = set(CARDS)
    for name, fn in CARDS.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(card(fn()) + '\n')
    for name in os.listdir(OUT):
        if name.endswith('.svg') and name[:-4] not in wanted:
            os.remove(os.path.join(OUT, name))
    # Every card is named <round>_<option>.svg; the pack's options use the same names.
    for rnd, (safe, traps) in ROUNDS.items():
        for n in safe + traps:
            assert n.startswith(rnd + '_'), n
    print(f'wrote {len(CARDS)} cards to {OUT}')


if __name__ == '__main__':
    main()
