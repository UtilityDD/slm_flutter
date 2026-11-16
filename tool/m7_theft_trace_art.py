"""Mistake-card art for lesson 7.5 কাজ 1 "তারের পিছু পিছু" (m7_theft_trace.dart).

Writes small gradient SVGs (320 x 200) into assets/game/art/m7_theft_trace/,
one per mistake: left = what happened (red cross), right = the right way
(green tick). No Bangla text inside the SVGs (flutter_svg text support is
thin). It writes and removes only files in its own folder.

Run:  python -I tool/m7_theft_trace_art.py .
"""
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
out = os.path.join(ROOT, 'assets', 'game', 'art', 'm7_theft_trace')
DEFS = '''<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a4a7a"/><stop offset="1" stop-color="#f2a65e"/></linearGradient>
<linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#e2c9a0"/><stop offset="1" stop-color="#b9a07c"/></linearGradient>
<linearGradient id="meter" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#eef0f3"/><stop offset="1" stop-color="#c3c8ce"/></linearGradient>
<linearGradient id="board" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8a6a44"/><stop offset="1" stop-color="#6a4e30"/></linearGradient>
<linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fffdf4"/><stop offset="1" stop-color="#f1e8cf"/></linearGradient>
<radialGradient id="pin" cx="0.35" cy="0.35" r="0.7"><stop offset="0" stop-color="#ff6b6b"/><stop offset="1" stop-color="#b71c1c"/></radialGradient>
</defs>'''


def cross(x, y):
    return (f'<circle cx="{x+8}" cy="{y+8}" r="11" fill="#e53935"/>'
            f'<path d="M{x+3} {y+3} L{x+13} {y+13} M{x+13} {y+3} L{x+3} {y+13}" stroke="#fff" stroke-width="3" stroke-linecap="round"/>')


def tick(x, y):
    return (f'<circle cx="{x+8}" cy="{y+8}" r="11" fill="#2e7d32"/>'
            f'<path d="M{x+2} {y+8} L{x+6} {y+13} L{x+14} {y+3}" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>')


def frame(left, right):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">\n' + DEFS
            + '\n<rect x="4" y="4" width="312" height="192" rx="12" fill="#fdf8ec" stroke="#c48a2e" stroke-width="3"/>'
            + '<line x1="160" y1="16" x2="160" y2="184" stroke="#e1d4b8" stroke-width="2" stroke-dasharray="5 4"/>\n'
            + '<g>' + left + '</g>\n<g transform="translate(156,0)">' + right + '</g>\n'
            + cross(20, 22) + tick(176, 22) + '\n</svg>\n')


def sky():
    return '<rect x="12" y="14" width="142" height="172" rx="8" fill="url(#sky)"/>'


def line(y=44):
    return f'<line x1="12" y1="{y}" x2="154" y2="{y}" stroke="#15171a" stroke-width="5"/>'


def house(x=96, y=104, w=50, h=78):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#wall)" stroke="#8a6a44" stroke-width="1.5"/>'
            f'<rect x="{x-3}" y="{y-6}" width="{w+6}" height="6" fill="#8e7e70"/>'
            f'<rect x="{x+8}" y="{y+40}" width="12" height="11" fill="#ffd27a"/>')


def board(x, y, loop=False):
    s = (f'<rect x="{x}" y="{y}" width="20" height="26" fill="#dcd6c8" stroke="#6a6458"/>'
         f'<rect x="{x+4}" y="{y+5}" width="12" height="14" rx="2" fill="#3e4650"/>'
         f'<rect x="{x+6}" y="{y+7}" width="8" height="4" fill="#9fd3a8"/>')
    if loop:
        s += f'<path d="M{x+8} {y+1} C{x-12} {y-3} {x-12} {y+30} {x+8} {y+29}" stroke="#23262b" stroke-width="2.4" fill="none"/>'
    return s


def wire(d):
    return f'<path d="{d}" stroke="#23262b" stroke-width="2.4" fill="none"/>'


def clamp(x, y):
    return f'<rect x="{x-4}" y="{y-5}" width="8" height="9" rx="1.5" fill="#3b3f45"/>'


def hookfit(x, y):
    return f'<path d="M{x-3} {y+4} L{x-3} {y-6} Q{x+1} {y-11} {x+5} {y-5}" stroke="#3b3f45" stroke-width="3" fill="none"/>'


def patch(x, y):
    return f'<rect x="{x-5}" y="{y-4}" width="10" height="8" rx="2" fill="#101112"/>'


def pin(x, y):
    return (f'<line x1="{x}" y1="{y-14}" x2="{x}" y2="{y}" stroke="#555" stroke-width="2"/>'
            f'<circle cx="{x}" cy="{y-18}" r="7" fill="url(#pin)"/>')


def okstamp(x, y):
    return (f'<rect x="{x}" y="{y}" width="44" height="20" rx="5" fill="#1c2e4a" stroke="#e6c35c" stroke-width="1.5"/>'
            f'<path d="M{x+12} {y+10} L{x+19} {y+15} L{x+32} {y+5}" stroke="#fff" stroke-width="2.5" fill="none"/>')


def meter_close(case='intact', sticker=False, pinned=None):
    s = '<rect x="12" y="14" width="142" height="172" rx="8" fill="#d9c29a"/>'
    s += '<rect x="34" y="40" width="98" height="120" rx="4" fill="url(#board)"/>'
    s += '<rect x="52" y="50" width="62" height="70" rx="7" fill="url(#meter)" stroke="#8a9096"/>'
    s += '<rect x="60" y="58" width="46" height="14" rx="2" fill="#2e3b2e"/>'
    s += '<rect x="56" y="118" width="54" height="14" rx="2" fill="#5e646c"/>'
    s += '<path d="M42 20 L42 146 L66 146 L66 132" stroke="#23262b" stroke-width="4" fill="none"/>'
    s += '<path d="M100 132 L100 146 L142 146 L142 178" stroke="#23262b" stroke-width="4" fill="none"/>'
    if case == 'sealCut':
        s += '<path d="M76 128 L80 134 M86 136 L90 128" stroke="#9aa0a6" stroke-width="1.5"/><circle cx="87" cy="142" r="4" fill="#7e848a"/>'
    else:
        s += '<path d="M76 128 L83 136 L90 128" stroke="#9aa0a6" stroke-width="1.5" fill="none"/><circle cx="83" cy="139" r="4" fill="#7e848a"/>'
    if case == 'magnet':
        s += '<rect x="70" y="92" width="26" height="16" rx="3" fill="#3a3d42"/><rect x="70" y="92" width="6" height="16" fill="#55595f"/>'
    elif sticker:
        s += '<rect x="70" y="92" width="26" height="16" fill="#f4f0d8" stroke="#a89c70"/>'
    if case == 'bypass':
        s += '<path d="M42 146 L60 166 L108 166 L142 146" stroke="#23262b" stroke-width="3.4" fill="none"/>'
        s += '<circle cx="42" cy="146" r="4.5" fill="#101112"/><circle cx="142" cy="146" r="4.5" fill="#101112"/>'
    if pinned:
        s += pin(*pinned)
    return s


def person(x, y, color='#2a4a7a', cap='#e6c35c'):
    return (f'<circle cx="{x}" cy="{y}" r="9" fill="#e0b38a"/><rect x="{x-10}" y="{y-14}" width="20" height="6" rx="3" fill="{cap}"/>'
            f'<rect x="{x-11}" y="{y+10}" width="22" height="30" rx="6" fill="{color}"/>')


def paper(x, y):
    lines = ''.join(f'<line x1="{x+6}" y1="{y+10+i*9}" x2="{x+34-i*3}" y2="{y+10+i*9}" stroke="#8a6a3c" stroke-width="1.5"/>' for i in range(4))
    return f'<rect x="{x}" y="{y}" width="40" height="52" rx="3" fill="url(#paper)" stroke="#8a6a3c"/>' + lines


def arrow(x1, y1, x2, y2, col='#2e7d32'):
    return (f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{col}" stroke-width="3" stroke-linecap="round"/>'
            f'<circle cx="{x2}" cy="{y2}" r="4" fill="{col}"/>')


LEGAL = wire('M40 46 C40 80 120 80 132 120') + clamp(40, 44)
HOOKW = wire('M70 46 C76 80 96 98 100 116') + hookfit(70, 44)
base = sky() + line() + house() + board(122, 120)

arts = {}
# A pin on a legal (patched) wire | the pin on the real theft (a hook), ঠিক আছে on the legal one.
arts['false_pin'] = frame(base + LEGAL + patch(84, 74) + pin(84, 74),
                          base + LEGAL + patch(84, 74) + HOOKW + pin(70, 40) + okstamp(20, 150))
# A pin on an intact meter | intact meter: ঠিক আছে.
arts['false_meter'] = frame(meter_close('intact', sticker=True, pinned=(83, 100)), meter_close('intact', sticker=True) + okstamp(96, 22))
hook_lane = base + LEGAL + HOOKW
arts['ok_hook'] = frame(hook_lane + okstamp(20, 150), hook_lane + pin(70, 40))
up_lane = base + LEGAL + wire('M112 92 L104 116') + patch(112, 92) + '<circle cx="104" cy="116" r="3" fill="#2a2420"/>'
arts['ok_upstream'] = frame(up_lane + okstamp(20, 150), up_lane + pin(112, 92))
loop_lane = sky() + line() + house() + board(122, 120, loop=True) + LEGAL
arts['ok_loop'] = frame(loop_lane + okstamp(20, 150), loop_lane + pin(118, 132))
arts['miss_seal'] = frame(meter_close('sealCut') + okstamp(96, 22), meter_close('sealCut', pinned=(87, 140)))
arts['miss_magnet'] = frame(meter_close('magnet') + okstamp(96, 22), meter_close('magnet', pinned=(83, 100)))
arts['miss_bypass'] = frame(meter_close('bypass') + okstamp(96, 22), meter_close('bypass', pinned=(84, 166)))
# The report to one only | to both (supervisor and vigilance).
rep_l = (paper(20, 70) + arrow(62, 96, 100, 80, '#e53935') + person(118, 66)
         + '<circle cx="118" cy="146" r="16" fill="none" stroke="#bbb" stroke-width="2" stroke-dasharray="4 3"/>')
rep_r = paper(20, 70) + arrow(62, 92, 100, 72) + arrow(62, 100, 100, 140) + person(118, 60) + person(118, 128, color='#5a2a7a', cap='#c0392b')
arts['send_both'] = frame(rep_l, rep_r)
# Walking away ('the police's job') | the theft pinned and the report written.
pol_l = base + HOOKW + person(40, 136, color='#6a6a6a') + arrow(54, 160, 20, 176, '#e53935')
pol_r = base + HOOKW + pin(70, 40) + person(40, 136) + paper(18, 70)
arts['push_listen'] = frame(pol_l, pol_r)

os.makedirs(out, exist_ok=True)
# Clean only this folder's old SVGs (a renamed card leaves none behind).
for name in os.listdir(out):
    if name.endswith('.svg') and name[:-4] not in arts:
        os.remove(os.path.join(out, name))
for k, v in arts.items():
    with open(os.path.join(out, k + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(v)
keep = os.path.join(out, '.gitkeep')
if os.path.exists(keep):
    os.remove(keep)
print(f'wrote {len(arts)} SVGs to {out}')
