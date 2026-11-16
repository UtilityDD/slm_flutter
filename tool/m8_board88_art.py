"""Picture cards for lesson 8.8 শেখা (নেট মিটারিং (Net Metering) রেগুলেশন: সৌরশক্তির নিয়ম).

python -I tool/m8_board88_art.py .

Writes assets/game/art/m8_board88/*.svg (200 x 220 scene cards, drawn edge to
edge in the style of tool/m6_board63_art.py, whose people, DTR stage, switches
and English-digit glyphs are reused by import; that file is not changed). No
words are drawn; the figures a worker reads (an LCD reading, a kW bar against
its 100 % line) are English digits or bars.

What the cards show comes from lesson 8.8 (live text) and the Module 8
rulings (docs/module_specs/module8_rulings.md) only:
  1. meter: a solar house's meter. Safe: a bi-directional meter with Import and
     Export on separate pages; the same meter with the export arrow lit in the
     sun. Traps: an ordinary single-register meter under the panels, an old
     disc meter, an inverter on the house board with the meter box empty;
  2. shut: a solar area's shutdown (ruling M8-19: the WBSEDCL DTR drawn with
     its AB switch open, padlocked and tagged, and HG fuses). One scene for
     the round: the same DTR, the same service pole with two fuse holders (a
     plain house's upper, the solar house's lower) and the solar house's
     panels. Safe: a worker pulls the solar house's fuse at the pole; the
     solar house's fuse already out (empty holder, nobody at the pole). Traps:
     the DTR OFF with every fuse in and a worker up the ladder (the climb,
     ruling M8-2), the same climb with an arm waving at the roof, the plain
     house's fuse pulled while the solar house keeps its fuse;
  3. inv: after the line is OFF the solar inverter is dark (safe, two views);
     traps: the inverter lit with output, a fan turning on a grid-only house,
     the worker walking off without looking;
  4. load: the solar bar against the sanctioned bar's 100 % line (lesson
     section 3). Safe: 3 kW on 3 kW, 4 kW on 5 kW; traps: 5 kW on 3 kW,
     4 kW on 3 kW, 6 kW on 2 kW;
  5. bill: two readouts (Import, Export), the net result and the fixed-charge
     line. Safe: 300 and 120 give 180; 150 and 260 bank 110 (winter). Traps:
     zero bill with no fixed charge, Import billed with Export ignored,
     Export added to the units (420).

Fairness (the playbook, section 4): a round's hand is one safe card plus the
round's traps (every trap is in each hand, as the pool has three). The script
checks every hand the dealer can make: each colour or gradient the safe card
draws is drawn by a trap in that hand, and the safe card's backdrop is a
trap's backdrop too. It deletes only its own stale cards.
"""

import importlib.util
import itertools
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location('m6_board63_art', os.path.join(HERE, 'm6_board63_art.py'))
m6 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(m6)

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/m8_board88_art.py <repo root (the folder with pubspec.yaml)>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'm8_board88')
W, H, GY = m6.W, m6.H, m6.GY
f = m6.f
INK, GREEN, RED, SUN, PAPER = m6.INK, m6.GREEN, m6.RED, m6.SUN, m6.PAPER
WIN_OFF, WIN_LIT, LCD_ON, METER_Y, GLOVE = m6.WIN_OFF, m6.WIN_LIT, m6.LCD_ON, m6.METER_Y, m6.GLOVE
TIN, WIRE = m6.TIN, m6.WIRE

PANEL_LINE = '#8FB3D9'
BLUE_BAR = '#5E9BD6'
TRACK = '#E3E8EC'
SLOT_GREY = '#9AA5AE'

# The m6 gradients plus one for the solar panels.
DEFS = m6.DEFS.replace(
    '</defs>',
    '  <linearGradient id="solar" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#34609A"/>'
    '<stop offset="1" stop-color="#1E3F6B"/></linearGradient>\n</defs>')


def card_open(back):
    return [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
            '<g clip-path="url(#card)">', f'<rect width="{W}" height="{H}" fill="url(#{back})"/>']


def card_close(out):
    return m6.card_close(out)


def ground():
    return f'<rect x="0" y="{GY - 8}" width="{W}" height="{H - GY + 8}" fill="url(#ground)"/>'


def house(x, w, top, win=WIN_OFF):
    """A house wall with its roof and one window (x, width, wall top)."""
    return (f'<rect x="{x}" y="{top}" width="{w}" height="{GY - top}" fill="url(#house)"/>'
            f'<path d="M{x - 6} {top + 1} L{f(x + w / 2)} {top - 30} L{x + w + 6} {top + 1} Z" fill="url(#roof)"/>'
            f'<rect x="{x + w - 24}" y="{top + 14}" width="14" height="16" fill="{win}"/>')


def panels(x, top, w):
    """Solar panels on the roof (a blue grid)."""
    o = [f'<rect x="{x + 10}" y="{top - 20}" width="{w - 20}" height="12" rx="1.5" fill="url(#solar)" '
         f'stroke="#1B3557" stroke-width="0.6"/>']
    for i in range(1, 4):
        xx = x + 10 + (w - 20) * i / 4
        o.append(f'<path d="M{f(xx)} {top - 20} V{top - 8}" stroke="{PANEL_LINE}" stroke-width="0.6"/>')
    return ''.join(o)


def arrow(x, y, d, color):
    """A flow arrow: from x to x + 10 * d (d = +1 right, -1 left)."""
    return (f'<path d="M{x} {y} h{10 * d} M{x + 6 * d} {y - 3} l{4 * d} 3 l{-4 * d} 3" stroke="{color}" '
            f'stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')


def readout(x, y, w, text, color=LCD_ON, h=7):
    """Digits right-aligned in an LCD window (x, y, width w), English digits."""
    tw = m6.glyph_width(text, h)
    return m6.glyphs(x + w - 3 - tw, y, text, h, color)


def meter_box(x, y, w=40, h=50):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="3" fill="url(#box)" '
            f'stroke="{INK}" stroke-width="0.8"/>')


def lcd(x, y, w, h):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="1.5" fill="url(#lcd)"/>'


def sun_day():
    return m6.sun(168, 30)


# --------------------------------------------------------------------------
# 1. meter
# --------------------------------------------------------------------------

def _meter_base(out):
    out.append(ground())
    out.append(sun_day())
    out.append(house(96, 92, 100))
    out.append(panels(96, 100, 92))


def meter_pages():
    """Safe: a bi-directional meter, Import (arrow in) and Export (arrow out) on separate lines."""
    out = card_open('day')
    _meter_base(out)
    out.append(meter_box(112, 116))
    out.append(lcd(116, 120, 32, 30))
    out.append(arrow(119, 128, 1, LCD_ON))
    out.append(readout(116, 122, 32, '300'))
    out.append(arrow(129, 142, -1, LCD_ON))
    out.append(readout(116, 136, 32, '120'))
    return card_close(out)


def meter_arrow():
    """Safe: the same meter; in the sun its export arrow is lit."""
    out = card_open('day')
    _meter_base(out)
    out.append(meter_box(112, 116))
    out.append(lcd(116, 120, 32, 22))
    out.append(f'<circle cx="124" cy="152" r="14" fill="url(#glow)"/>')
    out.append(f'<path d="M146 152 H124 M130 146 L124 152 L130 158" stroke="{INK}" stroke-width="5.4" fill="none" '
               'stroke-linecap="round" stroke-linejoin="round"/>')
    out.append(f'<path d="M146 152 H124 M130 146 L124 152 L130 158" stroke="{SUN}" stroke-width="2.8" fill="none" '
               'stroke-linecap="round" stroke-linejoin="round"/>')
    out.append(readout(116, 124, 32, '120'))
    return card_close(out)


def meter_single():
    """Trap: an ordinary single-register meter, one reading, under the panels."""
    out = card_open('day')
    _meter_base(out)
    out.append(meter_box(112, 116))
    out.append(lcd(116, 120, 32, 22))
    out.append(readout(116, 124, 32, '1450'))
    return card_close(out)


def meter_disc():
    """Trap: an old disc-type meter (a dial in a glass dome)."""
    out = card_open('day')
    _meter_base(out)
    out.append(f'<rect x="112" y="150" width="40" height="16" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<circle cx="132" cy="132" r="18" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<circle cx="132" cy="132" r="11" fill="{WIN_OFF}"/>')
    out.append(f'<path d="M132 132 L132 124 M132 132 L139 136" stroke="{SUN}" stroke-width="1.6" stroke-linecap="round"/>')
    return card_close(out)


def meter_empty():
    """Trap: the inverter wired straight to the house board; the meter box is empty."""
    out = card_open('day')
    _meter_base(out)
    out.append(f'<rect x="112" y="116" width="40" height="46" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
    out.append(f'<rect x="116" y="120" width="32" height="18" rx="1.5" fill="{WIN_OFF}"/>')
    out.append(f'<path d="M132 162 L132 176 L150 176" stroke="{INK}" stroke-width="1.2" fill="none"/>')
    out.append(f'<rect x="150" y="150" width="30" height="34" rx="2" fill="url(#panel)" stroke="{INK}" stroke-width="0.6"/>')
    for i in range(3):
        out.append(f'<rect x="155" y="{156 + i * 9}" width="20" height="5" rx="1" fill="url(#ceramic)"/>')
    out.append(f'<rect x="150" y="122" width="34" height="18" rx="2" fill="none" stroke="{INK}" '
               f'stroke-width="0.8" stroke-dasharray="3 2"/>')
    return card_close(out)


# --------------------------------------------------------------------------
# 2. shut (the WBSEDCL DTR: AB switch + HG fuses, ruling M8-19)
#
# One scene for the round, so the cards differ only where the cue is: the
# DTR's AB switch (open, padlocked, with the red tag) and its HG fuses on the
# left; one service pole in the middle with two fuse holders (the upper one
# is a plain house's, the lower one is the solar house's); the solar house on
# the right with its panels on the roof. Every card draws the same parts.
# --------------------------------------------------------------------------

SV_X = 100    # the service pole
UP_Y = 84     # the plain house's fuse holder (upper)
LO_Y = 124    # the solar house's fuse holder (lower)


def _holder(out, y, intact):
    """A fuse holder on the service pole: its carrier (intact) or an empty gap."""
    x = SV_X
    out.append(f'<rect x="{x - 10}" y="{y - 9}" width="20" height="26" rx="2" fill="url(#box)" stroke="{INK}" stroke-width="0.7"/>')
    out.append(f'<rect x="{x - 9}" y="{y - 2}" width="3" height="14" fill="url(#porc)"/>')
    out.append(f'<rect x="{x + 6}" y="{y - 2}" width="3" height="14" fill="url(#porc)"/>')
    if intact:
        out.append(f'<rect x="{x - 5}" y="{y - 2}" width="10" height="14" rx="2" fill="url(#ceramic)"/>')
        out.append(f'<path d="M{x - 3} {y + 5} L{x + 3} {y + 5}" stroke="{TIN}" stroke-width="1.6"/>')


def _shut_base(plain_fuse=True, solar_fuse=True):
    out = card_open('day')
    out.append(ground())
    out.append(sun_day())
    # the plain house (no panels) and the solar house (panels on its roof)
    out.append(house(56, 36, 124))
    out.append(house(124, 66, 112))
    out.append(f'<rect x="144" y="96" width="26" height="10" rx="1" fill="url(#solar)" stroke="#1B3557" stroke-width="0.6"/>')
    for xx in (152, 161):
        out.append(f'<path d="M{xx} 96 V106" stroke="{PANEL_LINE}" stroke-width="0.6"/>')
    # the DTR: a double pole, the AB switch open (blades up) with its
    # insulators, the HG fuses, and the AB padlocked with its red tag
    for px in (12, 44):
        out.append(m6.pole(px, 36, GY, 7))
    out.append(f'<rect x="4" y="40" width="48" height="5" rx="1" fill="url(#chan)"/>')
    for x in (12, 28, 44):
        out.append(f'<rect x="{x - 3}" y="34" width="6" height="6" fill="url(#porc)"/>')
        out.append(f'<path d="M{x - 6} 41 L{x - 2} 18" stroke="url(#steel)" stroke-width="3" stroke-linecap="round"/>')
        out.append(f'<rect x="{x - 4}" y="70" width="8" height="5" rx="1" fill="url(#porc)"/>')
        out.append(f'<path d="M{x - 3} 72 L{x + 3} 72" stroke="{TIN}" stroke-width="1.6"/>')
    out.append(m6.padlock(26, 52))
    # the service pole to the solar house, with its two fuse holders
    out.append(f'<path d="M{SV_X + 3} 112 Q114 104 124 110" stroke="{WIRE}" stroke-width="1" fill="none"/>')
    out.append(m6.pole(SV_X, 64, GY, 6))
    _holder(out, UP_Y, intact=plain_fuse)
    _holder(out, LO_Y, intact=solar_fuse)
    return out


def _ladder(out):
    """A ladder leaning on the service pole, on the house side."""
    foot_l, foot_r, top_l, top_r, top = 116, 126, 108, 118, 90

    def xl(y):
        return foot_l + (top_l - foot_l) * (GY - y) / (GY - top)

    def xr(y):
        return foot_r + (top_r - foot_r) * (GY - y) / (GY - top)

    out.append(f'<path d="M{foot_l} {GY} L{top_l} {top} M{foot_r} {GY} L{top_r} {top}" stroke="{m6.PANTS_D}" '
               'stroke-width="1.8" stroke-linecap="round"/>')
    for y in (176, 158, 140, 122, 104):
        out.append(f'<path d="M{f(xl(y))} {y} L{f(xr(y))} {y}" stroke="{INK}" stroke-width="1.4"/>')


def shut_pull():
    """Safe: the DTR's AB open and tagged; the worker at the pole pulls the solar house's fuse (lower holder)."""
    out = _shut_base(solar_fuse=False)
    out.append(m6.person(84, ((SV_X - 6, LO_Y + 6), (SV_X - 4, LO_Y + 14)), face=1, look=8))
    out.append(m6.puller(SV_X - 2, LO_Y + 2, ang=-30))
    return m6.card_close(out)


def shut_fuse():
    """Safe: the DTR's AB open and tagged; the solar house's fuse is already out (its holder empty); nobody at the pole."""
    return m6.card_close(_shut_base(solar_fuse=False))


def shut_dtr():
    """Trap (deadly class, ruling M8-2): the DTR OFF only; up the ladder with the solar house's fuse still in."""
    out = _shut_base()
    _ladder(out)
    out.append(m6.person(114, ((104, 100), (120, 96)), face=-1, look=-10, gy=112))
    return m6.card_close(out)


def shut_wave():
    """Trap: up the ladder, one arm waving at the solar roof; the solar house's fuse still in."""
    out = _shut_base()
    _ladder(out)
    out.append(m6.person(114, ((100, 64), (120, 100)), face=-1, look=-20, gy=112))
    return m6.card_close(out)


def shut_wrong():
    """Trap: the plain house's fuse pulled (upper holder); the solar house's fuse stays in."""
    out = _shut_base(plain_fuse=False)
    out.append(m6.person(84, ((SV_X - 6, UP_Y + 4), (SV_X - 4, UP_Y + 14)), face=1, look=8))
    out.append(m6.puller(SV_X - 2, UP_Y + 2, ang=-30))
    return m6.card_close(out)


# --------------------------------------------------------------------------
# 3. inv (the solar inverter after the line is OFF)
# --------------------------------------------------------------------------

def _inv_base(screen=WIN_OFF, bars=False, mccb_on=False, inverter=True, win=WIN_OFF):
    out = card_open('day')
    out.append(ground())
    out.append(sun_day())
    out.append(house(86, 110, 92, win=win))
    out.append(f'<rect x="84" y="140" width="114" height="4" fill="{INK}"/>')
    if inverter:
        out.append(f'<rect x="98" y="118" width="40" height="50" rx="3" fill="url(#box)" stroke="{INK}" stroke-width="0.8"/>')
        out.append(f'<rect x="102" y="122" width="32" height="20" rx="1.5" fill="{screen}"/>')
        if bars:
            for i, h in enumerate((10, 14, 8)):
                out.append(f'<rect x="{106 + i * 9}" y="{136 - h + 6}" width="5" height="{h}" fill="{GREEN}"/>')
    out.append(m6.mccb(150, 150, on=mccb_on))
    return out


def inv_dark():
    """Safe: the line OFF and the verandah inverter dark too."""
    return m6.card_close(_inv_base())


def inv_wall():
    """Safe: the line OFF; a worker at the wall checks the dark inverter."""
    out = _inv_base()
    out.append(m6.person(64, ((74, 150), (78, 156)), face=1, look=10))
    return m6.card_close(out)


def inv_lit():
    """Trap: the line OFF, yet the inverter's screen lit and its output running."""
    return m6.card_close(_inv_base(screen='url(#lcd)', bars=True))


def inv_fan():
    """Trap: a grid-only house with no inverter; the fan still turns in a power cut."""
    out = _inv_base(inverter=False, win=WIN_LIT)
    out.append(f'<circle cx="122" cy="118" r="4" fill="url(#ceramic)" stroke="{INK}" stroke-width="0.6"/>')
    out.append(f'<path d="M122 118 L122 104 M122 118 L134 122 M122 118 L110 122" stroke="{INK}" stroke-width="2.2" stroke-linecap="round"/>')
    out.append(m6.motion(132, 104, 1, 0, 3, 8))
    return m6.card_close(out)


def inv_walk():
    """Trap: the line OFF; the worker walks off towards the pole without looking at the inverter."""
    out = _inv_base(screen='url(#lcd)', bars=True)
    out.append(m6.person(64, ((58, 150), (54, 156)), face=-1, look=-30))
    return m6.card_close(out)


# --------------------------------------------------------------------------
# 4. load (the solar bar against the sanctioned bar's 100 % line)
# --------------------------------------------------------------------------

_BAR = 56  # the sanctioned load (100 %) in px; the solar bar is pct times this


def _load(pct, sanc, solar):
    out = card_open('yard')
    out.append(sun_day())
    out.append(f'<rect x="22" y="46" width="156" height="134" rx="8" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>')
    out.append(f'<rect x="34" y="58" width="132" height="10" rx="2" fill="url(#steel)"/>')
    out.append(f'<rect x="38" y="84" width="140" height="14" rx="3" fill="{TRACK}"/>')
    out.append(f'<rect x="38" y="84" width="{_BAR}" height="14" rx="3" fill="{BLUE_BAR}"/>')
    out.append(f'<rect x="38" y="118" width="140" height="14" rx="3" fill="{TRACK}"/>')
    solar = pct * _BAR
    if solar > 132:
        out.append(f'<rect x="38" y="118" width="132" height="14" rx="3" fill="{METER_Y}"/>')
        out.append(f'<path d="M172 125 l6 0 M175 122 l3 3 l-3 3" stroke="{RED}" stroke-width="1.6" fill="none"/>')
    else:
        out.append(f'<rect x="38" y="118" width="{f(solar)}" height="14" rx="3" fill="{METER_Y}"/>')
    out.append(f'<path d="M{38 + _BAR} 76 V140" stroke="{INK}" stroke-width="1.2" stroke-dasharray="3 2"/>')
    # the two figures in kW, English digits (the bars are drawn to scale)
    out.append(m6.glyphs(27, 84, str(sanc), 8, INK))
    out.append(m6.glyphs(27, 118, str(solar), 8, INK))
    return out


def load_eq3():
    return card_close(_load(1.0, 3, 3))


def load_lt5():
    return card_close(_load(0.8, 5, 4))


def load_over5():
    return card_close(_load(5 / 3, 3, 5))


def load_over4():
    return card_close(_load(4 / 3, 3, 4))


def load_two6():
    return card_close(_load(3.0, 2, 6))


# --------------------------------------------------------------------------
# 5. bill (Import, Export, the net units, the fixed charge)
# --------------------------------------------------------------------------

def _bill(imp, exp, result, fixed=True, exp_lit=True, plus=False, bank=False):
    out = card_open('yard')
    out.append(sun_day())
    out.append(f'<rect x="40" y="46" width="120" height="140" rx="4" fill="{PAPER}" stroke="{INK}" stroke-width="1"/>')
    out.append(arrow(50, 66, 1, INK))
    out.append(lcd(64, 56, 88, 22))
    out.append(readout(64, 61, 88, imp, h=9))
    out.append(arrow(50, 96, -1, INK))
    if exp_lit:
        out.append(lcd(64, 86, 88, 22))
        out.append(readout(64, 91, 88, exp, h=9))
    else:
        out.append(f'<rect x="64" y="86" width="88" height="22" rx="1.5" fill="{WIN_OFF}"/>')
    if plus:
        out.append(f'<path d="M57 122 h6 M60 119 v6" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>')
    out.append(f'<rect x="64" y="116" width="88" height="22" rx="1.5" fill="{TRACK}" stroke="{INK}" stroke-width="0.6"/>')
    out.append(readout(64, 121, 88, result, color=INK, h=9))
    if bank:
        out.append(f'<rect x="50" y="118" width="7" height="16" rx="1" fill="{SLOT_GREY}"/>')
    if fixed:
        out.append(f'<rect x="64" y="150" width="88" height="8" rx="2" fill="{SLOT_GREY}"/>')
    return out


def bill_net():
    return card_close(_bill('300', '120', '180'))


def bill_winter():
    return card_close(_bill('150', '260', '110', bank=True, exp_lit=True))


def bill_zero():
    return card_close(_bill('300', '120', '0', fixed=False))


def bill_full():
    return card_close(_bill('300', '120', '300', exp_lit=False))


def bill_add():
    return card_close(_bill('300', '120', '420', plus=True))


# --------------------------------------------------------------------------
# The cards, by round (safe ones and traps, as learn_board_pack88.dart).
# --------------------------------------------------------------------------

CARDS = {
    'meter_pages': meter_pages(),
    'meter_arrow': meter_arrow(),
    'meter_single': meter_single(),
    'meter_disc': meter_disc(),
    'meter_empty': meter_empty(),
    'shut_pull': shut_pull(),
    'shut_fuse': shut_fuse(),
    'shut_dtr': shut_dtr(),
    'shut_wave': shut_wave(),
    'shut_wrong': shut_wrong(),
    'inv_dark': inv_dark(),
    'inv_wall': inv_wall(),
    'inv_lit': inv_lit(),
    'inv_fan': inv_fan(),
    'inv_walk': inv_walk(),
    'load_eq3': load_eq3(),
    'load_lt5': load_lt5(),
    'load_over5': load_over5(),
    'load_over4': load_over4(),
    'load_two6': load_two6(),
    'bill_net': bill_net(),
    'bill_winter': bill_winter(),
    'bill_zero': bill_zero(),
    'bill_full': bill_full(),
    'bill_add': bill_add(),
}

ROUNDS = {
    'meter': (['meter_pages', 'meter_arrow'], ['meter_single', 'meter_disc', 'meter_empty']),
    'shut': (['shut_pull', 'shut_fuse'], ['shut_dtr', 'shut_wave', 'shut_wrong']),
    'inv': (['inv_dark', 'inv_wall'], ['inv_lit', 'inv_fan', 'inv_walk']),
    'load': (['load_eq3', 'load_lt5'], ['load_over5', 'load_over4', 'load_two6']),
    'bill': (['bill_net', 'bill_winter'], ['bill_zero', 'bill_full', 'bill_add']),
}
HAND = 4  # one safe card and three traps (learn_board_pack88.dart: cards 4)

_TOKEN = re.compile(r'url\(#\w+\)|#[0-9A-Fa-f]{6}\b')
_BACK = re.compile(r'<g clip-path="url\(#card\)">\s*<rect width="200" height="220" fill="(url\(#\w+\))"')


def fairness_problems():
    problems = []
    tok = {k: set(_TOKEN.findall(v.split('</defs>')[-1])) for k, v in CARDS.items()}
    back = {k: _BACK.search(v).group(1) for k, v in CARDS.items()}
    for rnd, (safes, traps) in ROUNDS.items():
        for s in safes:
            for hand in itertools.combinations(traps, HAND - 1):
                if back[s] not in {back[t] for t in hand}:
                    problems.append(f'{rnd}: {s} alone on its backdrop with {hand}')
                only = tok[s] - set().union(*(tok[t] for t in hand))
                if only:
                    problems.append(f'{rnd}: {s} with {hand} draws {sorted(only)} alone')
    return problems


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old[:-4] not in CARDS:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    bad = fairness_problems()
    for p in bad:
        print('UNFAIR', p)
    sys.exit(1 if bad else 0)
