"""Picture cards for ladder step 4 (lesson 1.2 শেখা, "লক্ষ্মণ রেখা").

python -I tool/lakshman_art.py .

Writes assets/game/art/lakshman/*.svg — one clean gradient style, no text in
the art. Scale: the worker is about 1.7 m tall = 50 px, so 1 m ≈ 29 px; the
gap from the worker's highest point (hand or tool tip) to the live wire is
what the player judges ("compare with a person's height", lesson 1.2).
Distances follow the lesson: 11 kV ≥ 2.5 m dry (≈ 73 px), 10–12 ft in rain.
"""

import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'lakshman')
W, H = 200, 220
GROUND = 200
WIRE = 40
PX_PER_M = 50 / 1.7


def m(px):
    return px / PX_PER_M


DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="skyRain" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5E6E7E"/><stop offset="1" stop-color="#AEB9C2"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="vest" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E06D10"/><stop offset="0.5" stop-color="#FF8A2A"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#D99A1E"/><stop offset="0.5" stop-color="#FFD25A"/><stop offset="1" stop-color="#C98A12"/></linearGradient>
  <linearGradient id="bamboo" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E3C98A"/><stop offset="1" stop-color="#B8954E"/></linearGradient>
  <linearGradient id="pvc" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#F4F6F7"/><stop offset="1" stop-color="#C9CFD3"/></linearGradient>
  <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9A6B43"/><stop offset="1" stop-color="#6E4A2C"/></linearGradient>
  <linearGradient id="metal" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#E2E6EA"/><stop offset="1" stop-color="#8E979F"/></linearGradient>
  <radialGradient id="wireGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A" stop-opacity="0.55"/><stop offset="1" stop-color="#FFE38A" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def scene_open(rain=False):
    sky = 'skyRain' if rain else 'sky'
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS, '<g clip-path="url(#card)">',
           f'<rect width="{W}" height="{H}" fill="url(#{sky})"/>']
    if rain:
        out.append('<g fill="#7F8C97" opacity="0.9"><ellipse cx="50" cy="18" rx="46" ry="16"/><ellipse cx="120" cy="12" rx="52" ry="18"/><ellipse cx="180" cy="20" rx="40" ry="15"/></g>')
    else:
        out.append('<g fill="#FFFFFF" opacity="0.9"><ellipse cx="40" cy="78" rx="22" ry="8"/><ellipse cx="56" cy="72" rx="16" ry="9"/></g>')
    out.append(f'<rect y="{GROUND}" width="{W}" height="{H - GROUND}" fill="url(#ground)"/>')
    # Pole, cross-arm, insulator, the live wire (a faint hum glow).
    out.append(f'<rect x="168" y="14" width="9" height="{GROUND - 14}" fill="url(#pole)"/>')
    out.append('<rect x="118" y="30" width="74" height="5" rx="1.5" fill="#5F676F"/>')
    out.append('<rect x="128" y="22" width="7" height="10" rx="2.5" fill="#E8EDF0"/><rect x="181" y="22" width="7" height="10" rx="2.5" fill="#E8EDF0"/>')
    out.append(f'<ellipse cx="80" cy="{WIRE}" rx="110" ry="9" fill="url(#wireGlow)"/>')
    out.append(f'<path d="M-4 {WIRE + 2} Q 70 {WIRE + 6} 131 {WIRE - 8}" stroke="#2B3138" stroke-width="2.4" fill="none"/>')
    return out


def scene_close(out, rain=False):
    if rain:
        drops = ''.join(f'<line x1="{x}" y1="{y}" x2="{x - 5}" y2="{y + 13}"/>' for x in range(8, 210, 17) for y in range(36, 200, 34))
        out.append(f'<g stroke="#D8E6F0" stroke-width="1.4" opacity="0.75" stroke-linecap="round">{drops}</g>')
    out.append('</g>')
    out.append('<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>')
    out.append('</svg>')
    return '\n'.join(out)


def worker(cx, top, arm='up', holding=None):
    """A 50 px worker whose highest point (a raised hand) is at [top]."""
    y = top
    s = []
    head = (cx, y + 12)
    # legs
    s.append(f'<path d="M{cx - 4} {y + 33} L{cx - 6} {y + 49} M{cx + 4} {y + 33} L{cx + 6} {y + 49}" stroke="#26303D" stroke-width="5" stroke-linecap="round"/>')
    s.append(f'<rect x="{cx - 9}" y="{y + 47}" width="8" height="3.5" rx="1.5" fill="#1C1F24"/><rect x="{cx + 2}" y="{y + 47}" width="8" height="3.5" rx="1.5" fill="#1C1F24"/>')
    # torso: shirt + vest with bands
    s.append(f'<rect x="{cx - 7}" y="{y + 18}" width="14" height="17" rx="4" fill="#1F5F8F"/>')
    s.append(f'<rect x="{cx - 6}" y="{y + 19}" width="12" height="15" rx="3" fill="url(#vest)"/>')
    s.append(f'<rect x="{cx - 6}" y="{y + 26}" width="12" height="1.8" fill="#E3E8EC"/><rect x="{cx - 6}" y="{y + 30}" width="12" height="1.8" fill="#E3E8EC"/>')
    # arms
    if arm == 'up':
        s.append(f'<path d="M{cx + 5} {y + 21} L{cx + 8} {y + 10} L{cx + 8} {y + 1.5}" stroke="#1F5F8F" stroke-width="3.6" fill="none" stroke-linecap="round"/>')
        s.append(f'<circle cx="{cx + 8}" cy="{y + 1.6}" r="2.2" fill="#6B4A33"/>')
    elif arm == 'hold':
        s.append(f'<path d="M{cx + 5} {y + 21} L{cx + 10} {y + 26}" stroke="#1F5F8F" stroke-width="3.6" fill="none" stroke-linecap="round"/>')
        s.append(f'<circle cx="{cx + 11}" cy="{y + 27}" r="2.2" fill="#6B4A33"/>')
    s.append(f'<path d="M{cx - 5} {y + 21} L{cx - 8} {y + 32}" stroke="#1F5F8F" stroke-width="3.6" fill="none" stroke-linecap="round"/>')
    # head + yellow helmet
    s.append(f'<circle cx="{head[0]}" cy="{head[1]}" r="5.4" fill="#A86E48"/>')
    s.append(f'<path d="M{cx - 6.5} {y + 10} A6.5 6.5 0 0 1 {cx + 6.5} {y + 10} Z" fill="#FFD34E"/><rect x="{cx - 8}" y="{y + 9.2}" width="16" height="2" rx="1" fill="#E5B92E"/>')
    return ''.join(s)


def ladder(cx, top, base=GROUND):
    """An A-frame ladder whose top step is at [top]."""
    s = [f'<path d="M{cx - 6} {top} L{cx - 16} {base} M{cx + 6} {top} L{cx + 16} {base}" stroke="#B0B7BD" stroke-width="2.6"/>']
    y = top + 10
    while y < base - 4:
        f = (y - top) / max(1, base - top)
        s.append(f'<line x1="{cx - 6 - 10 * f}" y1="{y}" x2="{cx + 6 + 10 * f}" y2="{y}" stroke="#B0B7BD" stroke-width="2"/>')
        y += 12
    s.append(f'<rect x="{cx - 9}" y="{top - 2}" width="18" height="3" rx="1" fill="#8D959C"/>')
    return ''.join(s)


def stand_at_gap(gap_px, cx=78):
    """Worker on a ladder (or the ground) with his raised hand [gap_px] below the wire."""
    top = WIRE + gap_px
    feet = top + 50
    parts = []
    if feet < GROUND - 2:
        parts.append(ladder(cx, feet + 1))
    parts.append(worker(cx, top))
    return parts


def distance_card(gap_px, rain=False):
    out = scene_open(rain)
    out += stand_at_gap(gap_px)
    return scene_close(out, rain)


def tool_card(kind):
    out = scene_open()
    if kind == 'tip_out':
        out.append(worker(70, 150, arm='hold'))
        out.append('<line x1="80" y1="177" x2="132" y2="118" stroke="url(#glass)" stroke-width="4" stroke-linecap="round"/>')
    elif kind == 'carry_low':
        out.append(worker(70, 150, arm='hold'))
        out.append('<line x1="34" y1="178" x2="132" y2="171" stroke="url(#glass)" stroke-width="4" stroke-linecap="round"/>')
    elif kind == 'tip_in':
        out.append(worker(52, 150, arm='hold'))
        out.append('<line x1="62" y1="177" x2="112" y2="49" stroke="#B8954E" stroke-width="4" stroke-linecap="round"/>')
    elif kind == 'ladder_top':
        out.append(worker(46, 150, arm='hold'))
        out.append('<path d="M90 200 L118 50 M102 200 L130 52" stroke="#B0B7BD" stroke-width="2.6"/>')
        out.append(''.join(f'<line x1="{90 + 28 * f}" y1="{200 - 150 * f}" x2="{102 + 28 * f}" y2="{200 - 148 * f}" stroke="#B0B7BD" stroke-width="2"/>' for f in [i / 10 for i in range(1, 10)]))
    elif kind == 'branch':
        out.append(worker(54, 150, arm='hold'))
        out.append('<path d="M64 177 L96 92 L104 52" stroke="#6E4A2C" stroke-width="4" fill="none" stroke-linecap="round"/>')
        out.append('<g fill="#4E7A3E"><ellipse cx="104" cy="54" rx="11" ry="6"/><ellipse cx="96" cy="66" rx="9" ry="5"/><ellipse cx="110" cy="66" rx="8" ry="5"/></g>')
    return scene_close(out)


def stick_card(kind):
    """An object on its own (the board's pedestal shows it)."""
    s = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', DEFS,
         '<g transform="rotate(-38 100 120)">']
    if kind == 'hot_stick':
        s.append('<rect x="14" y="112" width="172" height="12" rx="6" fill="url(#glass)"/>')
        s += [f'<rect x="{x}" y="111" width="5" height="14" rx="1.5" fill="#B1760E"/>' for x in (62, 112)]
        s.append('<rect x="14" y="110" width="34" height="16" rx="6" fill="#2B2F35"/>')
        s.append('<rect x="44" y="110" width="7" height="16" rx="2" fill="#D7261E"/>')
        s.append('<path d="M186 118 q14 0 14 -12 q0 -10 -9 -10" stroke="#8E979F" stroke-width="4" fill="none" stroke-linecap="round"/>')
    elif kind == 'hot_stick_tele':
        s.append('<rect x="14" y="112" width="96" height="13" rx="6" fill="url(#glass)"/>')
        s.append('<rect x="108" y="113.5" width="80" height="10" rx="5" fill="url(#glass)"/>')
        s.append('<rect x="106" y="110" width="7" height="17" rx="2" fill="#6B4A1A"/>')
        s.append('<rect x="14" y="110" width="34" height="17" rx="6" fill="#2B2F35"/>')
        s.append('<path d="M188 118 l10 -8 m-10 8 l10 8" stroke="#8E979F" stroke-width="4" stroke-linecap="round"/>')
    elif kind == 'bamboo':
        s.append('<rect x="12" y="111" width="178" height="14" rx="7" fill="url(#bamboo)"/>')
        s += [f'<rect x="{x}" y="109" width="4" height="18" rx="1.5" fill="#9C7A3A"/>' for x in (46, 84, 122, 160)]
        s.append('<path d="M150 112 l6 -7 M70 124 l-5 6" stroke="#9C7A3A" stroke-width="2"/>')
    elif kind == 'pvc':
        s.append('<rect x="12" y="112" width="176" height="12" rx="6" fill="url(#pvc)"/>')
        s.append('<rect x="88" y="110" width="16" height="16" rx="2" fill="#2F3A45"/>')
        s.append('<path d="M188 118 q14 0 14 -12 q0 -10 -9 -10" stroke="#8E979F" stroke-width="4" fill="none" stroke-linecap="round"/>')
        s.append('<path d="M14 120 q-10 30 10 50 q16 14 6 30" stroke="#B98B54" stroke-width="1.6" fill="none"/>')
    elif kind == 'wood':
        s.append('<path d="M12 120 Q 60 112 100 118 T 190 116" stroke="url(#wood)" stroke-width="12" fill="none" stroke-linecap="round"/>')
        s.append('<path d="M120 116 l10 -12 M60 116 l-6 -10" stroke="#6E4A2C" stroke-width="4" stroke-linecap="round"/>')
    elif kind == 'metal':
        s.append('<rect x="12" y="112" width="178" height="11" rx="5.5" fill="url(#metal)"/>')
        s.append('<rect x="12" y="114" width="178" height="2.5" fill="#FFFFFF" opacity="0.6"/>')
    s.append('</g></svg>')
    return '\n'.join(s)


CARDS = {
    # Round 1 — 11 kV, dry: ≥ 2.5 m (≈ 73 px).
    'd11_safe_far': distance_card(96),      # ≈ 3.3 m
    'd11_safe_ok': distance_card(80),       # ≈ 2.7 m
    'd11_trap_lt': distance_card(36),       # ≈ 1.2 m (the LT rule — not enough for 11 kV)
    'd11_trap_half': distance_card(17),     # ≈ 0.6 m
    'd11_trap_arm': distance_card(9),       # ≈ 0.3 m
    'd11_trap_touch': distance_card(3),     # at the wire
    # Round 2 — the tool is part of you.
    'tool_tip_out': tool_card('tip_out'),
    'tool_carry_low': tool_card('carry_low'),
    'tool_tip_in': tool_card('tip_in'),
    'tool_ladder_top': tool_card('ladder_top'),
    'tool_branch': tool_card('branch'),
    # Round 3 — rain, 11 kV: 10–12 ft (≈ 3.0–3.7 m ≈ 90–108 px).
    'rain_safe_12ft': distance_card(106, rain=True),
    'rain_safe_10ft': distance_card(92, rain=True),
    'rain_trap_dry': distance_card(73, rain=True),   # the dry-day 2.5 m
    'rain_trap_close': distance_card(40, rain=True),
    'rain_trap_near': distance_card(14, rain=True),
    # Round 4 — which stick near a live wire.
    'stick_hot': stick_card('hot_stick'),
    'stick_hot_tele': stick_card('hot_stick_tele'),
    'stick_bamboo': stick_card('bamboo'),
    'stick_pvc': stick_card('pvc'),
    'stick_wood': stick_card('wood'),
    'stick_metal': stick_card('metal'),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as f:
            f.write(svg)
    print(f'wrote {len(CARDS)} cards to {OUT}')
    for g in (96, 80, 73, 36, 17, 9, 3, 106, 92, 40, 14):
        print(f'  gap {g:3d} px = {m(g):.2f} m')
